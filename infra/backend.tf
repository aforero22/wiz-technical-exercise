terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.75"
    }
  }
  backend "s3" {
    bucket = "wiz-exercise-terraform-state"
    key    = "state/terraform.tfstate"
    region = "us-east-1"  # Literales, no variables
  }
}