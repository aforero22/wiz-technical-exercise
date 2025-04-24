# Configuración del backend de Terraform
# Este archivo define dónde se almacena el estado de Terraform

terraform {
  # Definir proveedores requeridos
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.95"   # o "> = 5.95.0"
    }
  }
  
  # Configurar backend S3 para almacenar el estado de Terraform
  # El estado se almacena en un bucket S3 para permitir trabajo en equipo
  backend "s3" {
    bucket = "wiz-exercise-terraform-state"
    key    = "state/terraform.tfstate"
    region = "us-east-1"  # Literales, no variables
  }
  
  # VULNERABILIDAD: No se configura encriptación para el estado de Terraform
  # VULNERABILIDAD: No se configura bloqueo de estado (DynamoDB)
  # VULNERABILIDAD: No se especifica versión de Terraform requerida
}