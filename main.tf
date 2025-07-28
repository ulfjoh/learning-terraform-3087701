# VPC
module "blog_vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.2"

  name = "dev"
  cidr = "10.0.0.0/16"

  azs            = ["us-west-2a", "us-west-2b", "us-west-2c"]
  public_subnets = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

# Security Group
module "blog_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.0"

  name   = "blog_module"
  vpc_id = module.blog_vpc.vpc_id

  ingress_rules       = ["http-80-tcp", "https-443-tcp"]
  ingress_cidr_blocks = ["0.0.0.0/0"]
  egress_rules        = ["all-all"]
  egress_cidr_blocks  = ["0.0.0.0/0"]

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

# AMI
data "aws_ami" "app_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["bitnami-tomcat-*-x86_64-hvm-ebs-nami"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["979382823631"]
}

# Launch Template
resource "aws_launch_template" "blog" {
  name_prefix   = "blog-"
  image_id      = data.aws_ami.app_ami.id
  instance_type = var.instance_type

  vpc_security_group_ids = [module.blog_sg.security_group_id]

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "HelloWorld"
    }
  }
}

# ALB
resource "aws_lb" "blog" {
  name               = "blog-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = module.blog_vpc.public_subnets
  security_groups    = [module.blog_sg.security_group_id]
}

resource "aws_lb_target_group" "blog" {
  name        = "blog-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = module.blog_vpc.vpc_id
  target_type = "instance"
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.blog.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blog.arn
  }
}

# Autoscaling Group
module "blog_autoscaling" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "9.0.1"

  name                  = "blog_asg"
  min_size              = 1
  max_size              = 1
  desired_capacity      = 1
  vpc_zone_identifier   = module.blog_vpc.public_subnets
  create_launch_template = false
  launch_template_name   = aws_launch_template.blog.name

  tags = {
    Name = "HelloWorld"
  }
}

# Attach ASG to Target Group
resource "aws_autoscaling_attachment" "asg_attachment" {
  autoscaling_group_name = module.blog_autoscaling.autoscaling_group_name
  lb_target_group_arn    = aws_lb_target_group.blog.arn
}