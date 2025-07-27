#terraform {
# required_providers {
#    aws = {
#      source  = "hashicorp/aws"
#    }
#  }
#}

#provider "aws" {
#  region  = "us-west-2"
#}

terraform {
  required_version = ">= 1.12.2"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # Or your preferred compatible version
    }
  }

  experiments = [module_variable_optional_attrs]
}

provider "aws" {
  region = "us-west-2"
}