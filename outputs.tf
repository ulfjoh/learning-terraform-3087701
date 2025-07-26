output "instance_ami" {
  value = aws_instance.blog.ami
}

output "instance_id" {
  description = "The ID of the EC2 instance"
  value       = aws_instance.blog.id
}

output "instance_arn" {
  description = "The ARN of the EC2 instance"
  value       = aws_instance.blog.arn
}

output "instance_public_ip" {
  description = "The public IP address of the instance"
  value       = aws_instance.blog.public_ip
}

output "instance_private_ip" {
  description = "The private IP address of the instance"
  value       = aws_instance.blog.private_ip
}

output "instance_az" {
  description = "The availability zone of the instance"
  value       = aws_instance.blog.availability_zone
}

output "security_group_id" {
  description = "The ID of the security group"
  value       = aws_security_group.blog_sg.id
}

output "instance_public_dns" {
  description = "The public DNS name of the EC2 instance"
  value       = aws_instance.blog.public_dns
}