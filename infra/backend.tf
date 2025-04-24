terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.95"   # o "> = 5.95.0"
    }
  }
  backend "s3" {
    bucket = "wiz-exercise-terraform-state"
    key    = "state/terraform.tfstate"
    region = "us-east-1"  # Literales, no variables
  }
}