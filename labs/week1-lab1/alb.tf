# ============================================================
# ALB: Nhan HTTP tu Internet, forward den EC2 NodePort
# ============================================================

resource "aws_lb" "main" {
  name               = "${local.name_prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = data.aws_subnets.public.ids # >= 2 AZs

  tags = {
    Name = "${local.name_prefix}-alb"
  }
}

resource "aws_lb_target_group" "main" {
  # Target group dang ky EC2 instance theo instance-id va port 30080.
  # Port nay phai khop voi Kubernetes Service node_port va socat forward tren EC2.
  name     = "${local.name_prefix}-tg"
  port     = var.app_node_port # 30080 = NodePort cua minikube
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    # Health check vao nginx qua cung duong traffic that:
    # ALB -> EC2:30080 -> socat -> minikube NodePort -> nginx pod.
    # Neu socat/NodePort loi, target se unhealthy va ALB tra 502.
    enabled             = true
    path                = "/"
    port                = var.app_node_port
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 5
    interval            = 30
    timeout             = 10
    matcher             = "200"
  }

  tags = {
    Name = "${local.name_prefix}-tg"
  }
}

# Dang ky EC2 instance vao Target Group.
# Khong dang ky minikube IP vi IP 192.168.49.x chi ton tai ben trong EC2 Docker network.
resource "aws_lb_target_group_attachment" "main" {
  target_group_arn = aws_lb_target_group.main.arn
  target_id        = aws_instance.ec2.id
  port             = var.app_node_port
}

# Listener: ALB :80 → forward den Target Group
resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}
