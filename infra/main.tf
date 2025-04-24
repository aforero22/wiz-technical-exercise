 provider "aws" {
  region = us-east-1
}

# VPC y redes
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.0.0"

  name = "wiz-exercise"
  cidr = var.vpc_cidr
  azs  = ["${var.region}a", "${var.region}b"]

  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
}

# Security Group para MongoDB (SSH abierto)
resource "aws_security_group" "mongo_sg" {
  name        = "mongo-sg"
  vpc_id      = module.vpc.vpc_id
  description = "SSH abierto + tráfico MongoDB desde EKS"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port       = 27017
    to_port         = 27017
    protocol        = "tcp"
    security_groups = [module.eks.cluster_security_group_id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# IAM Role para VM MongoDB con permisos excesivos
resource "aws_iam_role" "mongo_role" {
  name = "mongo-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
}

# IAM Role y Profile (Admin) para MongoDB
data "aws_iam_policy_document" "ec2_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "mongo_attach" {
  role       = aws_iam_role.mongo_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_instance_profile" "mongo_profile" {
  name = "mongo-profile"
  role = aws_iam_role.mongo_role.name
}

# Instancia MongoDB Antigua
resource "aws_instance" "mongo" {
  ami                    = var.mongo_ami
  instance_type          = var.mongo_instance_type
  subnet_id              = module.vpc.public_subnets[0]
  vpc_security_group_ids = [aws_security_group.mongo_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.mongo_profile.name
  user_data              = file("../scripts/mongo-userdata.sh")
  tags = { Name = "mongo-old" }
}

# EKS Cluster (o k8s managed)
module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "18.0.0"
  cluster_name    = "wiz-cluster"
  cluster_version = "1.21"
  subnets         = module.vpc.private_subnets
  vpc_id          = module.vpc.vpc_id

  worker_groups = [
    { instance_type = "t3.medium", asg_desired_capacity = 2 }
  ]
}

# Bucket S3 público
resource "aws_s3_bucket" "backups" {
  bucket = "wiz-exercise-backups-${random_id.bucket_id.hex}"
  acl    = "public-read"
}

# Repositorio ECR para la aplicación
resource "aws_ecr_repository" "wiz_app" {
  name                 = "wiz-app"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "random_id" "bucket_id" { byte_length = 4 }