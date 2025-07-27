output "security_group_id" {
  description = "The ID of the security group"
  value       = module.blog_sg.security_group_id
}

output "alb_dns_name" {
  description = "The DNS name of the ALB"
  value       = module.blog_alb.lb_dns_name  # ✅ Correct output name from module v9.6.0
}

output "autoscaling_group_name" {
  description = "Name of the Auto Scaling Group"
  value       = module.blog_autoscaling.autoscaling_group_name
}
