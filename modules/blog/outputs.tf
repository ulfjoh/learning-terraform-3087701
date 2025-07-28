output "vpc_id" {
  description = "The ID of the VPC!"
  value       = module.blog_vpc.vpc_id
}

output "security_group_id" {
  description = "The ID of the security group!"
  value       = module.blog_sg.security_group_id
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.blog_alb.dns_name
}

output "target_group_arn" {
  description = "ARN of the ALB Target Group"
  value       = aws_lb_target_group.blog_tg.arn
}

output "autoscaling_group_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.blog_asg.name
}
