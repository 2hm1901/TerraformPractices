# ============================================================
# K8s Bootstrap: Cho EC2 san sang, lay kubeconfig
#
# Flow:
#   EC2 boot → user_data cai minikube → touch /tmp/minikube_ready
#   → null_resource SSH vao → copy kubeconfig.yaml ve may
#   → kubernetes provider co the ket noi
# ============================================================

resource "null_resource" "wait_for_k8s" {
  # null_resource nay la cau noi giua AWS provider va Kubernetes provider.
  # AWS tao EC2 truoc; sau do local-exec SSH vao EC2 de cho minikube ready
  # va copy kubeconfig ve local cho Kubernetes provider dung o Stage 2.
  depends_on = [
    aws_instance.ec2,
    local_sensitive_file.ssh_private_key
  ]

  # Re-run neu EC2 bi thay. Neu instance_id doi, kubeconfig cu khong con dung
  # vi public IP/cert cua minikube cung thay doi.
  triggers = {
    instance_id = aws_instance.ec2.id
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = <<-EOF
      set -euo pipefail

      EC2_IP="${aws_instance.ec2.public_ip}"
      KEY_FILE="${path.module}/ssh_private_key.pem"
      KUBECONFIG_OUT="${path.module}/kubeconfig.yaml"
      SSH_OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=10 -o BatchMode=yes"

      # User data can vai phut de cai Docker/minikube. Vong lap nay chi
      # kiem tra SSH san sang, chua co nghia Kubernetes da ready.
      echo ">>> [1/3] Cho EC2 chap nhan SSH ($EC2_IP)..."
      for i in $(seq 1 40); do
        if ssh $SSH_OPTS -i "$KEY_FILE" ubuntu@$EC2_IP "echo ok" 2>/dev/null; then
          echo "    SSH ready!"
          break
        fi
        echo "    Lan $i: chua san sang, cho 15s..."
        sleep 15
      done

      # /tmp/minikube_ready duoc tao o cuoi scripts/user_data.sh sau khi:
      # Docker/minikube da cai xong, API server duoc expose, kubeconfig da export.
      echo ">>> [2/3] Cho minikube khoi dong xong (~5-10 phut)..."
      for i in $(seq 1 60); do
        if ssh $SSH_OPTS -i "$KEY_FILE" ubuntu@$EC2_IP "test -f /tmp/minikube_ready" 2>/dev/null; then
          echo "    minikube ready!"
          break
        fi
        echo "    Lan $i: minikube chua san sang, cho 30s..."
        sleep 30
      done

      # Kubernetes provider chay tren may local, nen phai copy kubeconfig tu EC2
      # ve thu muc lab. File nay co server=https://EC2_PUBLIC_IP:8443.
      echo ">>> [3/3] Copy kubeconfig ve may..."
      scp $SSH_OPTS -i "$KEY_FILE" ubuntu@$EC2_IP:/home/ubuntu/kubeconfig.yaml "$KUBECONFIG_OUT"

      echo ">>> Cluster san sang! Kubeconfig: $KUBECONFIG_OUT"
    EOF
  }
}
