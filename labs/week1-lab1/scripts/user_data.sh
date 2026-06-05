#!/bin/bash
# ============================================================
# user_data.sh — Chay tu dong khi EC2 boot
# Cai dat: Docker, kubectl, minikube
# Ket qua: minikube chay, kubeconfig export san cho Terraform
# ============================================================
set -euo pipefail

# Ghi toan bo stdout/stderr cua user_data vao file nay.
# Khi EC2 bootstrap loi, SSH vao may va xem /var/log/user-data.log de debug.
exec > /var/log/user-data.log 2>&1

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }

log "=== Bat dau setup EC2 ==="

# -----------------------------------------------------------
# 1. Cap nhat he thong
# -----------------------------------------------------------
log "Updating packages..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y ca-certificates curl gnupg lsb-release socat conntrack

# -----------------------------------------------------------
# 2. Cai dat Docker
# -----------------------------------------------------------
log "Installing Docker..."
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
  | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io

usermod -aG docker ubuntu
systemctl enable --now docker
log "Docker installed: $(docker --version)"

# -----------------------------------------------------------
# 3. Cai dat kubectl
# -----------------------------------------------------------
log "Installing kubectl..."
curl -fsSL "https://dl.k8s.io/release/v1.29.0/bin/linux/amd64/kubectl" \
  -o /usr/local/bin/kubectl
chmod +x /usr/local/bin/kubectl
log "kubectl installed: $(kubectl version --client --short 2>/dev/null || kubectl version --client)"

# -----------------------------------------------------------
# 4. Cai dat minikube
# -----------------------------------------------------------
log "Installing minikube..."
curl -fsSL https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 \
  -o /usr/local/bin/minikube
chmod +x /usr/local/bin/minikube
log "minikube installed: $(minikube version)"

# -----------------------------------------------------------
# 5. Lay Public IP cua EC2 (de dua vao cert SANs)
# Dung IMDSv2 de lay public IP an toan hon IMDSv1.
# Public IP nay phai nam trong certificate SAN cua API server,
# neu khong kubernetes provider se fail TLS verification.
# -----------------------------------------------------------
log "Fetching EC2 public IP..."
TOKEN=$(curl -sf -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
PUBLIC_IP=$(curl -sf -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/public-ipv4)
log "Public IP: $PUBLIC_IP"

# -----------------------------------------------------------
# 6. Khoi dong minikube (chay voi user ubuntu, khong phai root)
#    --apiserver-ips: them PublicIP vao TLS cert SAN
#    → Terraform co the ket noi tu ben ngoai qua PublicIP:8443
#    --driver=docker: tao Kubernetes node trong Docker network tren EC2.
#    --wait=all: chi tiep tuc khi cac component Kubernetes can thiet da ready.
# -----------------------------------------------------------
log "Starting minikube (this takes ~3-5 minutes)..."
sudo -u ubuntu bash -c "
  export HOME=/home/ubuntu
  minikube start \
    --driver=docker \
    --apiserver-ips=${PUBLIC_IP} \
    --apiserver-port=8443 \
    --memory=6144 \
    --cpus=2 \
    --wait=all \
    --wait-timeout=8m
"
log "minikube started!"

# -----------------------------------------------------------
# 6.1 Expose K8s API on EC2:8443
# Docker driver binds API to 127.0.0.1, so forward it to 0.0.0.0
# Terraform Kubernetes provider chay tren may local, nen phai mo API server
# ra public IP cua EC2 thong qua security group port 8443.
# -----------------------------------------------------------
log "Exposing K8s API on EC2:8443..."
MINIKUBE_IP=$(sudo -u ubuntu bash -c "export HOME=/home/ubuntu; minikube ip")
nohup socat TCP-LISTEN:8443,bind=0.0.0.0,fork,reuseaddr TCP:${MINIKUBE_IP}:8443 \
  > /var/log/socat-k8s.log 2>&1 &
sleep 2

# -----------------------------------------------------------
# 6.2 Expose nginx NodePort on EC2:30080 for ALB target group
# Docker-driver NodePort is reachable on the minikube container IP,
# not directly on the EC2 host network.
# Neu khong forward buoc nay, curl 127.0.0.1:30080 tren EC2 se connection refused
# va ALB health check vao EC2:30080 se fail -> 502 Bad Gateway.
# -----------------------------------------------------------
log "Exposing nginx NodePort on EC2:30080..."
nohup socat TCP-LISTEN:30080,bind=0.0.0.0,fork,reuseaddr TCP:${MINIKUBE_IP}:30080 \
  > /var/log/socat-nodeport.log 2>&1 &
sleep 2

# -----------------------------------------------------------
# 7. Kiem tra nodes ready
# -----------------------------------------------------------
sudo -u ubuntu bash -c "
  export HOME=/home/ubuntu
  kubectl wait --for=condition=Ready nodes --all --timeout=300s
"
log "Kubernetes nodes ready!"

# -----------------------------------------------------------
# 8. Export kubeconfig voi Public IP thay vi 127.0.0.1
#    → De Terraform tren may local ket noi vao K8s API
# Embed certificate/key bang base64 de file kubeconfig.yaml copy ve local
# dung duoc ma khong can copy them cac file .crt/.key rieng le.
# -----------------------------------------------------------
log "Exporting kubeconfig with public IP..."
sudo -u ubuntu bash -c "
  export HOME=/home/ubuntu
  PUBLIC_IP=\"${PUBLIC_IP}\"
  CA_DATA=\$(base64 -w 0 /home/ubuntu/.minikube/ca.crt)
  CLIENT_CERT_DATA=\$(base64 -w 0 /home/ubuntu/.minikube/profiles/minikube/client.crt)
  CLIENT_KEY_DATA=\$(base64 -w 0 /home/ubuntu/.minikube/profiles/minikube/client.key)
  cat > /home/ubuntu/kubeconfig.yaml <<EOF
apiVersion: v1
kind: Config
clusters:
- name: minikube
  cluster:
    server: https://\${PUBLIC_IP}:8443
    certificate-authority-data: \${CA_DATA}
contexts:
- name: minikube
  context:
    cluster: minikube
    user: minikube
current-context: minikube
users:
- name: minikube
  user:
    client-certificate-data: \${CLIENT_CERT_DATA}
    client-key-data: \${CLIENT_KEY_DATA}
EOF
"
chmod 644 /home/ubuntu/kubeconfig.yaml
log "kubeconfig saved to /home/ubuntu/kubeconfig.yaml"

# -----------------------------------------------------------
# 9. Ket thuc — tao file ready de Terraform biet
# null_resource.wait_for_k8s poll file nay qua SSH.
# Chi touch sau khi kubeconfig da export xong de tranh Terraform doc file thieu.
# -----------------------------------------------------------
log "=== Setup complete! minikube is ready. ==="
touch /tmp/minikube_ready
