 terraform {
  required_version = ">= 1.0"
  backend "s3" {
    bucket = "wiz-exercise-terraform-state"
    key    = "state/terraform.tfstate"
    region = var.region
  }
}