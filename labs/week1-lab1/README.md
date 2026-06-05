# Week 1 - Lab 1: EC2 + minikube + ALB

Lab nay dung Terraform de tao mot EC2 instance tren AWS, cai minikube tren EC2, deploy nginx vao Kubernetes bang Terraform Kubernetes provider, sau do expose app ra Internet qua Application Load Balancer (ALB).

## Cach chay

```bash
cd labs/week1-lab1
make apply
make destroy
```

`make apply` mat khoang 15-20 phut vi EC2 can cai Docker, kubectl, minikube va khoi dong Kubernetes cluster.

## Ket qua mong doi

Sau khi `make apply` thanh cong, Terraform se in ra `alb_url`, vi du:

```text
http://cdo08-dev-lab1-alb-xxxx.ap-southeast-2.elb.amazonaws.com
```

Mo URL nay se thay trang default cua nginx.

## Kien truc

```text
Internet
   |
   v
ALB :80
   |
   v
EC2 public instance
   |
   +-- Docker
       |
       +-- minikube node
           |
           +-- nginx Deployment
           +-- nginx Service NodePort :30080
```

Luong request:

```text
User -> ALB:80 -> EC2:30080 -> minikube NodePort:30080 -> nginx pod:80
```

Minikube trong lab nay chay bang Docker driver. Vi vay NodePort `30080` khong tu dong listen truc tiep tren host EC2. Script `scripts/user_data.sh` dung `socat` de forward:

```text
EC2 0.0.0.0:30080 -> minikube_ip:30080
```

Neu khong co buoc forward nay, ALB health check vao `EC2:30080` se fail va URL ALB co the tra `502 Bad Gateway`.

## Providers duoc dung

| Provider | Muc dich |
|---|---|
| `aws` | Tao EC2, ALB, Target Group, Listener, Security Group, Key Pair |
| `kubernetes` | Deploy nginx Deployment va Service vao minikube |
| `tls` | Generate SSH private/public key |
| `null` | Chay local-exec de cho EC2/minikube ready va copy kubeconfig ve local |
| `local` | Ghi private key ra file local |

Lab nay dung hon 2 providers. Hai provider chinh la `aws` va `kubernetes`.

## Khac nhau giua cach nay va cach dung random provider

Mot so member trong team dung `random` provider de dap ung yeu cau ">= 2 providers". Cach do hop le neu de bai chi yeu cau Terraform dung nhieu provider, nhung y nghia khac voi cach trong lab nay.

### Cach dung random provider

`random` provider thuong tao gia tri ngau nhien, vi du:

```hcl
resource "random_id" "suffix" {
  byte_length = 4
}
```

Gia tri nay co the dung de dat ten resource cho khong trung, vi du ten bucket, ten instance, ten security group. Tuy nhien `random` provider khong ket noi den Kubernetes cluster va khong deploy workload nao vao Kubernetes.

No chi tao data phu tro cho Terraform.

### Cach dung kubernetes provider trong lab nay

`kubernetes` provider ket noi truc tiep den Kubernetes API server cua minikube thong qua `kubeconfig.yaml`.

Provider nay tao resource that trong cluster:

```hcl
resource "kubernetes_deployment" "app" {
  # tao nginx Deployment
}

resource "kubernetes_service" "app" {
  # tao NodePort Service
}
```

Dieu nay co nghia la Terraform khong chi tao AWS infrastructure, ma con quan ly ca application layer ben trong Kubernetes.

### Tom tat khac biet

| Tieu chi | `random` provider | `kubernetes` provider |
|---|---|---|
| Ket noi den he thong ben ngoai | Khong | Co, ket noi Kubernetes API |
| Tao resource ha tang/app that | Khong, chi tao gia tri ngau nhien | Co, tao Deployment va Service |
| Do phuc tap | Thap | Cao hon vi can kubeconfig va cluster ready |
| Phu hop neu chi can >= 2 providers | Co | Co |
| Chung minh Terraform deploy app vao K8s | Khong | Co |

Trong lab nay toi chon `kubernetes` provider vi muon Terraform quan ly end-to-end: AWS infrastructure va nginx app trong minikube.

## Luong Terraform apply

Kubernetes provider can kubeconfig tai thoi diem Terraform plan/apply. Nhung kubeconfig chi ton tai sau khi EC2 boot xong va minikube start thanh cong. Vi vay `make apply` chay 2 stage.

### Stage 1

```bash
terraform apply -auto-approve -var="deploy_k8s=false"
```

Stage nay tao:

- SSH key bang `tls`
- EC2 instance
- Security Groups
- ALB, Target Group, Listener
- minikube tren EC2 thong qua `user_data.sh`
- `kubeconfig.yaml` copy tu EC2 ve local

Chua tao Kubernetes Deployment/Service.

### Stage 2

```bash
terraform apply -auto-approve
```

Stage nay dung kubeconfig that de Kubernetes provider ket noi vao minikube va tao:

- `kubernetes_deployment.app`
- `kubernetes_service.app`

## Luong Terraform destroy

```bash
make destroy
```

Lenh nay chay:

```bash
terraform destroy -auto-approve -var="deploy_k8s=false"
```

Luu y quan trong: du `deploy_k8s=false`, Terraform van can kubeconfig that neu Kubernetes resources dang con trong state. Neu provider bi tro ve placeholder `127.0.0.1:8443`, destroy se fail voi loi:

```text
dial tcp 127.0.0.1:8443: connect: connection refused
```

Vi vay `versions.tf` cau hinh Kubernetes provider nhu sau:

```hcl
provider "kubernetes" {
  config_path    = fileexists("${path.module}/kubeconfig.yaml") ? "${path.module}/kubeconfig.yaml" : "${path.module}/kubeconfig.placeholder.yaml"
  config_context = "minikube"
}
```

Khi `kubeconfig.yaml` that con ton tai, destroy se dung file do de xoa Kubernetes resources truoc, roi moi xoa AWS resources.

## File chinh

```text
labs/week1-lab1/
├── Makefile
├── versions.tf
├── variables.tf
├── networking.tf
├── security_groups.tf
├── ec2.tf
├── alb.tf
├── k8s_bootstrap.tf
├── k8s_app.tf
├── outputs.tf
├── kubeconfig.placeholder.yaml
└── scripts/
    └── user_data.sh
```

Vai tro tung file:

| File | Muc dich |
|---|---|
| `Makefile` | Chay nhanh `make apply` va `make destroy` |
| `versions.tf` | Khai bao providers va provider config |
| `variables.tf` | Bien dau vao nhu region, instance type, NodePort |
| `networking.tf` | Lay Default VPC va public subnets |
| `security_groups.tf` | Mo port cho ALB, EC2, SSH, Kubernetes API |
| `ec2.tf` | Tao EC2 va SSH key |
| `alb.tf` | Tao ALB, Target Group, Listener |
| `k8s_bootstrap.tf` | Cho minikube ready va copy kubeconfig |
| `k8s_app.tf` | Tao nginx Deployment va NodePort Service |
| `scripts/user_data.sh` | Cai Docker, kubectl, minikube, socat forwarding |

## Debug nhanh

SSH vao EC2:

```bash
ssh -i ssh_private_key.pem ubuntu@<EC2_PUBLIC_IP>
```

Kiem tra pod va service:

```bash
kubectl get pods -o wide
kubectl get svc -o wide
kubectl get endpoints nginx-service -o yaml
```

Kiem tra NodePort trong minikube:

```bash
curl -i http://$(minikube ip):30080/
```

Kiem tra NodePort tren host EC2:

```bash
curl -i http://127.0.0.1:30080/
ss -ltnp | grep 30080
```

Neu `minikube ip:30080` tra 200 nhung `127.0.0.1:30080` bi refused, ALB se bi 502. Can kiem tra `socat` forward trong `scripts/user_data.sh`.

## Yeu cau local

- Terraform >= 1.10
- AWS CLI da cau hinh credentials
- `make`
- `ssh` va `scp`
