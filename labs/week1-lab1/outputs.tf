output "alb_url" {
  description = "URL cua Application Load Balancer"
  value       = "http://${aws_lb.main.dns_name}"
}

output "ec2_public_ip" {
  description = "Public IP cua EC2 instance"
  value       = aws_instance.ec2.public_ip
}

output "ec2_ssh_command" {
  description = "Lenh SSH vao EC2"
  value       = "ssh -i labs/week1-lab1/ssh_private_key.pem ubuntu@${aws_instance.ec2.public_ip}"
}

output "minikube_log_command" {
  description = "Xem log user_data tren EC2"
  value       = "ssh -i labs/week1-lab1/ssh_private_key.pem ubuntu@${aws_instance.ec2.public_ip} 'tail -f /var/log/user-data.log'"
}
