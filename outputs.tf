output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.blog_vpc.vpc_id
}

output "public_subnets" {
  description = "The list of public subnet IDs"
  value       = module.blog_vpc.public_subnets
}

output "security_group_id" {
  description = "The ID of the security group"
  value       = module.blog_sg.security_group_id
}

output "launch_template_id" {
  description = "The ID of the launch template"
  value       = aws_launch_template.blog.id
}

output "autoscaling_group_name" {
  description = "Name of the Auto Scaling Group"
  value       = module.blog_autoscaling.autoscaling_group_name
}