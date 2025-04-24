 variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block para la VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnets" {
  description = "Lista de subnets públicas"
  type        = list(string)
  default     = ["10.0.1.0/24"]
}

variable "private_subnets" {
  description = "Lista de subnets privadas"
  type        = list(string)
  default     = ["10.0.2.0/24"]
}

variable "mongo_ami" {
  description = "AMI antigua para MongoDB"
  type        = string
  default     = "ami-0c55b159cbfafe1f0" # Ubuntu 16.04 LTS en us-east-1
}

variable "mongo_instance_type" {
  description = "Tipo de instancia para MongoDB"
  type        = string
  default     = "t2.micro"
}