output "alb_dns_name" {
  description = "ALB DNS name"
  value       = aws_lb.alb.dns_name
}

output "public_subnet_ids" {
  value = [for s in aws_subnet.public : s.id]
}

output "private_subnet_ids" {
  value = [for s in aws_subnet.private : s.id]
}

output "mongodb_private_ip" {
  description = "Private IP of MongoDB instance"
  value       = aws_instance.mongodb.private_ip
}

output "asg_name" {
  value = aws_autoscaling_group.web_asg.name
}

output "bastion_public_ip" {
  description = "Bastion host Public IP"
  value = aws_instance.bastion.public_ip
}
