# --- VPC Module ---
module "blog_vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.2"

  name = var.environment.name
  cidr = "${var.environment.network_prefix}.0.0/16"

  azs            = ["us-west-2a", "us-west-2b", "us-west-2c"]
  public_subnets = ["${var.environment.network_prefix}.101.0/24", "${var.environment.network_prefix}.102.0/24", "${var.environment.network_prefix}.103.0/24"]

  tags = {
    Terraform   = "true"
    Environment = var.environment.name
  }
}

# --- Security Group Module ---
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
    Environment = var.environment.name
  }
}

# --- Bitnami Tomcat AMI Lookup ---
data "aws_ami" "app_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = [var.ami_filter.name]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = [var.ami_filter.owner] # Bitnami
}

# --- Launch Template ---
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

# --- ALB ---
resource "aws_lb" "blog_alb" {
  name               = "blog-alb"
  load_balancer_type = "application"
  subnets            = module.blog_vpc.public_subnets
  security_groups    = [module.blog_sg.security_group_id]
  enable_deletion_protection = false

  tags = {
    Environment = var.environment.name
  }
}

resource "aws_lb_target_group" "blog_tg" {
  name     = "blog-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.blog_vpc.vpc_id
  target_type = "instance"

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-299"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.blog_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blog_tg.arn
  }
}

# --- Autoscaling Group (manual) ---
resource "aws_autoscaling_group" "blog_asg" {
  name                      = "blog-asg"
  max_size                  = var.max_size
  min_size                  = var.min_size
  desired_capacity          = 1
  vpc_zone_identifier       = module.blog_vpc.public_subnets
  health_check_type         = "EC2"

  launch_template {
    id      = aws_launch_template.blog.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.blog_tg.arn]

  tag {
    key                 = "Name"
    value               = "HelloWorld"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}
