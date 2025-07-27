# VPC
module "blog_vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.2"

  name = "dev"
  cidr = "10.0.0.0/16"
  azs  = ["us-west-2a", "us-west-2b", "us-west-2c"]
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
  owners      = ["979382823631"] # Bitnami

  filter {
    name   = "name"
    values = ["bitnami-tomcat-*-x86_64-hvm-ebs-nami"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Launch Template
resource "aws_launch_template" "blog" {
  name_prefix   = "blog-"
  image_id      = data.aws_ami.app_ami.id
  instance_type = "t3.micro"
  vpc_security_group_ids = [module.blog_sg.security_group_id]

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "HelloWorld"
    }
  }
}

# Auto Scaling Group
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

# ALB (no listeners or target_groups inline)
module "blog_alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "9.6.0"

  name            = "blog-alb"
  vpc_id          = module.blog_vpc.vpc_id
  subnets         = module.blog_vpc.public_subnets
  security_groups = [module.blog_sg.security_group_id]
  enable_http2    = true
  idle_timeout    = 60

  tags = {
    Environment = "dev"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = module.blog_alb.lb_arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blog_tg.arn
  }
}

resource "aws_lb_target_group" "blog_tg" {
  name     = "blog-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.blog_vpc.vpc_id
  target_type = "instance"
}

resource "aws_autoscaling_attachment" "asg_attach" {
  autoscaling_group_name = module.blog_autoscaling.autoscaling_group_name
  alb_target_group_arn   = aws_lb_target_group.blog_tg.arn
}
