# Variables de Terraform
# Este archivo define las variables utilizadas en la configuración de infraestructura

# Región de AWS donde se desplegarán los recursos
variable "region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

# Bloque CIDR para la VPC
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# Lista de bloques CIDR para subredes públicas
variable "public_subnets" {
  description = "List of public subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

# Lista de bloques CIDR para subredes privadas
variable "private_subnets" {
  description = "List of private subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
}

# ID de la AMI para la instancia de MongoDB
# VULNERABILIDAD: Se utiliza Ubuntu 16.04 LTS (EOL)
variable "mongo_ami" {
  description = "AMI ID for MongoDB instance"
  type        = string
  default     = "ami-0ac80df6eff0e70b5"  # Ubuntu 16.04 LTS xenial in us-east-1
}

# Tipo de instancia EC2 para MongoDB
variable "mongo_instance_type" {
  description = "EC2 instance type for MongoDB"
  type        = string
  default     = "t2.micro"
}

# Versión de Kubernetes para el clúster EKS
variable "eks_cluster_version" {
  description = "Kubernetes version to use for EKS cluster"
  type        = string
  default     = "1.27"
}

# Lista de tipos de instancia EC2 para nodos de EKS
variable "eks_node_instance_types" {
  description = "List of EC2 instance types for EKS nodes"
  type        = list(string)
  default     = ["t3.medium"]
}

# Número deseado de nodos en el grupo de nodos de EKS
variable "eks_node_desired_size" {
  description = "Desired number of nodes in EKS node group"
  type        = number
  default     = 2
}

# Número mínimo de nodos en el grupo de nodos de EKS
variable "eks_node_min_size" {
  description = "Minimum number of nodes in EKS node group"
  type        = number
  default     = 1
}

# Número máximo de nodos en el grupo de nodos de EKS
variable "eks_node_max_size" {
  description = "Maximum number of nodes in EKS node group"
  type        = number
  default     = 3
}