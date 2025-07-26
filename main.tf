# VPC + EC2 with Modules

# VPC using official module
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.2"

  name = "blog-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-west-2a"]
  public_subnets  = ["10.0.1.0/24"]

  enable_dns_support   = true
  enable_dns_hostnames = true

  enable_nat_gateway = false
  single_nat_gateway = false

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

# Security group
module "blog_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.0"

  name   = "blog_module"
  vpc_id = module.vpc.vpc_id

  ingress_rules       = ["http-80-tcp", "https-443-tcp"]
  ingress_cidr_blocks = ["0.0.0.0/0"]
  egress_rules        = ["all-all"]
  egress_cidr_blocks  = ["0.0.0.0/0"]

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

# AMI lookup
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

  owners = ["979382823631"] # Bitnami
}

# EC2 instance
resource "aws_instance" "blog" {
  ami                         = data.aws_ami.app_ami.id
  instance_type               = var.instance_type
  subnet_id                   = module.vpc.public_subnets[0]
  associate_public_ip_address = true
  vpc_security_group_ids      = [module.blog_sg.security_group_id]

  tags = {
    Name = "HelloWorld"
  }
}
