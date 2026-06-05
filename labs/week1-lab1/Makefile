.PHONY: apply destroy

# ============================================================
# Chay toan bo: make apply
# Xoa toan bo: make destroy
# ============================================================

apply:
	@echo "=============================================="
	@echo "  Week1-Lab1: EC2 + minikube + ALB"
	@echo "=============================================="

	@# Tao placeholder kubeconfig neu chua co file that.
	@# Stage 1 chua co minikube/kubeconfig, nhung Terraform van can file
	@# co current-context=minikube de Kubernetes provider init duoc.
	@# Regex chap nhan ca "minikube" va minikube vi kubeconfig export co the khac format.
	@if [ ! -f kubeconfig.yaml ] || ! grep -Eq 'current-context:[[:space:]]*"?minikube"?' kubeconfig.yaml; then \
		cp kubeconfig.placeholder.yaml kubeconfig.yaml; \
	fi

	terraform init

	@echo ""
	@echo ">>> Stage 1: Tao AWS infrastructure + cho minikube san sang..."
	@echo "    (EC2 boot + cai Docker + khoi dong minikube: ~10-15 phut)"
	terraform apply -auto-approve -var="deploy_k8s=false"

	@echo ""
	@echo ">>> Stage 2: Deploy app vao Kubernetes..."
	terraform apply -auto-approve

	@echo ""
	@echo "=============================================="
	@echo "  XONG! Ung dung dang chay tai:"
	@terraform output -raw alb_url
	@echo ""
	@echo "  (ALB health check mat ~1-2 phut de 'healthy')"
	@echo "=============================================="

destroy:
	@echo "Dang xoa toan bo resources..."
	@# deploy_k8s=false ngan Terraform tao moi Kubernetes resources trong luc destroy.
	@# Provider van dung kubeconfig.yaml that neu file con ton tai de xoa resources da co trong state.
	terraform destroy -auto-approve -var="deploy_k8s=false"
	@echo "Xoa file tam..."
	rm -f kubeconfig.yaml ssh_private_key.pem
	@echo "Done! Tat ca da duoc xoa."
