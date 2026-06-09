# ============================================================
# K8s App: Deploy nginx vao minikube
# Provider: kubernetes (provider #2)
#
# count = var.deploy_k8s ? 1 : 0
#   → Stage 1 (deploy_k8s=false): bo qua, khong ket noi K8s
#   → Stage 2 (deploy_k8s=true):  tao resources
# ============================================================

resource "kubernetes_deployment" "app" {
  # count giup Stage 1 bo qua app resource khi cluster chua san sang.
  # Stage 2 moi tao Deployment sau khi kubeconfig.yaml da duoc copy ve local.
  count      = var.deploy_k8s ? 1 : 0
  depends_on = [null_resource.wait_for_k8s]

  metadata {
    name      = "nginx-app"
    namespace = "default"
    labels = {
      app = "nginx-app"
    }
  }

  spec {
    replicas = var.app_replicas

    selector {
      match_labels = {
        app = "nginx-app"
      }
    }

    template {
      metadata {
        labels = {
          app = "nginx-app"
        }
      }

      spec {
        container {
          name  = "nginx"
          image = "nginx:alpine"

          port {
            container_port = 80
          }

          # Dat request/limit nho de nginx chay on dinh tren single-node minikube
          # nhung khong chiem qua nhieu CPU/RAM cua EC2.
          resources {
            requests = {
              cpu    = "100m"
              memory = "64Mi"
            }
            limits = {
              cpu    = "200m"
              memory = "128Mi"
            }
          }
        }
      }
    }
  }
}

# NodePort Service expose nginx tren port co dinh 30080.
# ALB target group cung dung dung port nay.
#
# Luu y voi minikube Docker driver:
# - NodePort reachable tren minikube container IP.
# - scripts/user_data.sh dung socat de forward EC2:30080 -> minikube_ip:30080.
resource "kubernetes_service" "app" {
  count      = var.deploy_k8s ? 1 : 0
  depends_on = [null_resource.wait_for_k8s]

  metadata {
    name      = "nginx-service"
    namespace = "default"
  }

  spec {
    selector = {
      app = "nginx-app"
    }

    type = "NodePort"

    port {
      name        = "http"
      port        = 80
      target_port = 80
      node_port   = var.app_node_port # 30080, phai khop voi ALB target group
    }
  }
}
