provider "aws" {
  region = "us-east-1"
}

# Para aplicar el aws-auth ConfigMap
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = [
      "eks", "get-token",
      "--cluster-name", module.eks.cluster_name,
      "--region",      var.region
    ]
  }
}

# VPC y redes
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.21.0"

  name = "wiz-exercise"
  cidr = var.vpc_cidr
  azs  = ["${var.region}a", "${var.region}b"]

  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets

  # Enable NAT Gateway for private subnets
  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false

  # Enable DNS hostnames and support
  enable_dns_hostnames = true
  enable_dns_support   = true

  # Add tags
  tags = {
    Environment = "production"
    Terraform   = "true"
  }
}

# Security Group para MongoDB (SSH abierto)
resource "aws_security_group" "mongo_sg" {
  name_prefix = "mongo-sg-"
  vpc_id      = module.vpc.vpc_id
  description = "Security group for MongoDB instance"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # VULNERABILIDAD: SSH abierto al mundo
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
  tags = {
    Name = "mongo-sg"
  }
}

# IAM Role para VM MongoDB con permisos mínimos necesarios
resource "aws_iam_role" "mongo_role" {
  name = "mongo-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
  tags = {
    Name = "mongo-role"
  }
}

# IAM Role y Profile para MongoDB
data "aws_iam_policy_document" "ec2_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# Política IAM más restrictiva para MongoDB
resource "aws_iam_role_policy" "mongo_policy" {
  name = "mongo-policy"
  role = aws_iam_role.mongo_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.backups.arn,
          "${aws_s3_bucket.backups.arn}/*"
        ]
      }
    ]
  })
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
  user_data              = <<-EOF
#!/bin/bash
# Script de inicialización para la instancia EC2 de MongoDB
# Este script se ejecuta durante el arranque de la instancia (userdata)

# VULNERABILIDAD: Se utiliza Ubuntu 16.04 LTS (EOL) y MongoDB 4.0 (versión antigua)
# VULNERABILIDAD: No se configura autenticación ni TLS
# VULNERABILIDAD: No se configuran firewalls ni restricciones de red

# Actualizar repositorios e instalar dependencias
apt-get update
apt-get install -y gnupg wget

# Añadir clave GPG de MongoDB
wget -qO - https://www.mongodb.org/static/pgp/server-4.0.asc | apt-key add -

# Configurar repositorio de MongoDB 4.0
echo "deb [ arch=amd64 ] https://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/4.0 multiverse" \
    | tee /etc/apt/sources.list.d/mongodb-org-4.0.list

# Actualizar repositorios e instalar MongoDB
apt-get update
apt-get install -y mongodb-org

# Habilitar e iniciar el servicio de MongoDB
systemctl enable mongod
systemctl start mongod

# Instalar el agente SSM para permitir la ejecución remota de comandos
snap install amazon-ssm-agent --classic
systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent.service
systemctl start snap.amazon-ssm-agent.amazon-ssm-agent.service

# (Opcional) Crear usuarios y habilitar autenticación
# VULNERABILIDAD: No se implementa esta parte, dejando MongoDB sin autenticación
EOF
  tags = { Name = "mongo-old" }
}

# Security group for EKS cluster
resource "aws_security_group" "eks_cluster" {
  name_prefix = "eks-cluster-sg-"
  description = "Security group for EKS cluster"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # VULNERABILIDAD: Acceso público al API server
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "eks-cluster-sg"
  }
}

# EKS Cluster (o k8s managed)
module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "20.36.0"

  cluster_name    = "wiz-cluster-new"
  cluster_version = "1.27"

  vpc_id      = module.vpc.vpc_id
  subnet_ids  = module.vpc.private_subnets

  # Enable public access to API server
  cluster_endpoint_public_access = true
  cluster_endpoint_private_access = true

  # Configure access to API server
  cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]  # VULNERABILIDAD: Acceso público al API server

  # Enable IRSA
  enable_irsa = true

  # Add necessary addons
  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    aws-ebs-csi-driver = {
      most_recent = true
    }
  }

  eks_managed_node_group_defaults = {
    ami_type       = "AL2_x86_64"
    disk_size      = 20
    instance_types = ["t3.medium"]

    # Enable detailed monitoring
    enable_monitoring = true

    # Add necessary IAM policies
    iam_role_additional_policies = {
      AmazonEBSCSIDriverPolicy = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
      AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    }

    # Add security groups
    vpc_security_group_ids = [aws_security_group.eks_nodes.id]
  }

  eks_managed_node_groups = {
    worker = {
      desired_size = 2
      min_size     = 1
      max_size     = 3

      # Add labels and taints if needed
      labels = {
        Environment = "production"
        NodeGroup  = "worker"
      }

      # Add tags
      tags = {
        Name = "worker-node"
      }
    }
  }

  # Add tags to the cluster
  tags = {
    Environment = "production"
    Terraform   = "true"
  }
}

# Bucket S3 para backups (modificado para evitar acceso público)
resource "aws_s3_bucket" "backups" {
  bucket = "wiz-exercise-backups-${random_id.bucket_id.hex}"
}

resource "aws_s3_bucket_public_access_block" "backups_public_access_block" {
  bucket = aws_s3_bucket.backups.id

  block_public_acls   = false # Permite ACLs públicas (necesario para algunas configuraciones públicas)
  ignore_public_acls  = false # No ignora ACLs públicas
  block_public_policy = false # <-- Cambiado a false para permitir políticas públicas
  restrict_public_buckets = false # Permite acceso público general si la política o ACL lo permiten
}

resource "aws_s3_bucket_policy" "backups_policy" {
  bucket = aws_s3_bucket.backups.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"  # VULNERABILIDAD: Acceso público al bucket
        Action    = ["s3:GetObject"]
        Resource  = ["${aws_s3_bucket.backups.arn}/*"]
      },
      {
        Sid       = "PublicListBucket"
        Effect    = "Allow"
        Principal = "*"  # VULNERABILIDAD: Listado público del bucket
        Action    = ["s3:ListBucket"]
        Resource  = [aws_s3_bucket.backups.arn]
      }
    ]
  })
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

resource "random_id" "cloudtrail" {
  byte_length = 4
}

# Bucket S3 para CloudTrail y AWS Config
resource "aws_s3_bucket" "cloudtrail" {
  bucket = "wiz-exercise-cloudtrail-logs-${random_id.cloudtrail.hex}"
}

# VULNERABILIDAD: Configuración de acceso público al bucket
resource "aws_s3_bucket_public_access_block" "cloudtrail_block" {
  bucket                  = aws_s3_bucket.cloudtrail.id
  block_public_acls       = false  # VULNERABILIDAD: ACLs públicas permitidas
  block_public_policy     = false  # VULNERABILIDAD: Políticas públicas permitidas
  ignore_public_acls      = false  # VULNERABILIDAD: ACLs públicas no ignoradas
  restrict_public_buckets = false  # VULNERABILIDAD: Buckets públicos permitidos
}

# Obtener el ID de la cuenta actual para las políticas
data "aws_caller_identity" "current" {}

# Política del bucket que permite acceso a CloudTrail y AWS Config
resource "aws_s3_bucket_policy" "cloudtrail_policy" {
  bucket = aws_s3_bucket.cloudtrail.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AWSCloudTrailWrite"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = ["${aws_s3_bucket.cloudtrail.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]
        Condition = {
          StringEquals = { "s3:x-amz-acl" = "bucket-owner-full-control" }
        }
      },
      {
        Sid       = "AWSCloudTrailGetBucketAcl"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:GetBucketAcl"
        Resource  = [aws_s3_bucket.cloudtrail.arn]
      },
      {
        Sid       = "AWSConfigWrite"
        Effect    = "Allow"
        Principal = { Service = "config.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = ["${aws_s3_bucket.cloudtrail.arn}/config/*"]  # Permite a AWS Config escribir en el prefijo /config/
      },
      {
        Sid       = "AWSConfigGetBucketAcl"
        Effect    = "Allow"
        Principal = { Service = "config.amazonaws.com" }
        Action    = "s3:GetBucketAcl"
        Resource  = [aws_s3_bucket.cloudtrail.arn]
      }
    ]
  })
}

# Security group for EKS nodes
resource "aws_security_group" "eks_nodes" {
  name_prefix = "eks-nodes-sg-"
  description = "Security group for EKS nodes"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [module.eks.cluster_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "eks-nodes-sg"
  }
}

# CloudTrail para auditoría (modificado para usar la política correcta)
resource "aws_cloudtrail" "main" {
  name                          = "wiz-exercise-trail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail.id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_logging                = true
  
  event_selector {
    read_write_type           = "All"
    include_management_events = true
  }

  depends_on = [aws_s3_bucket_policy.cloudtrail_policy]
}

# Security controls - AWS GuardDuty for threat detection
resource "aws_guardduty_detector" "main" {
  enable = true
}

# Security controls - AWS Config for compliance monitoring
resource "aws_config_configuration_recorder" "main" {
  name     = "wiz-exercise-config"
  role_arn = aws_iam_role.config_role.arn
  
  recording_group {
    all_supported = true
  }
}

# Canal de entrega para AWS Config
resource "aws_config_delivery_channel" "main" {
  name           = "wiz-exercise-delivery-channel"
  s3_bucket_name = aws_s3_bucket.cloudtrail.id
  s3_key_prefix  = "config"
  depends_on     = [aws_config_configuration_recorder.main]
}

resource "aws_config_configuration_recorder_status" "main" {
  name       = aws_config_configuration_recorder.main.name
  is_enabled = true
  depends_on = [aws_config_delivery_channel.main]
}

resource "aws_iam_role" "config_role" {
  name = "config-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "config_policy" {
  role       = aws_iam_role.config_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole"
}

# Configuración para ejecutar backups automáticos
# Documento de Systems Manager para el script de backup
resource "aws_ssm_document" "backup_script" {
  name            = "wiz-mongo-backup"
  document_type   = "Command"
  document_format = "YAML"
  content = <<DOC
---
schemaVersion: '2.2'
description: 'Script para realizar backup de MongoDB y subirlo a S3'
mainSteps:
  - action: aws:runShellScript
    name: backupMongoDB
    inputs:
      runCommand:
        - '#!/bin/bash'
        - 'set -euo pipefail'
        - ''
        - '# Variables de entorno'
        - 'TIMESTAMP=$$(date +"%Y%m%d_%H%M%S")'
        - 'FILENAME="dump_$${TIMESTAMP}.archive"'
        - 'MONGO_CONN_URI="mongodb://localhost:27017/wizdb"'
        - 'AWS_BUCKET_NAME="${aws_s3_bucket.backups.bucket}"'
        - ''
        - 'echo "-> Iniciando backup de MongoDB"'
        - 'mongodump --uri "$$MONGO_CONN_URI" --archive="$$FILENAME"'
        - 'echo "-> Subiendo $$FILENAME a s3://$$AWS_BUCKET_NAME/"'
        - 'aws s3 cp "$$FILENAME" "s3://$$AWS_BUCKET_NAME/"'
        - 'echo "-> Backup completado"'
        - 'rm "$$FILENAME"'
DOC
}

# Rol IAM para ejecutar el comando de backup
resource "aws_iam_role" "backup_role" {
  name = "mongo-backup-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
      }
    ]
  })
}

# Política IAM para el rol de backup
resource "aws_iam_role_policy" "backup_policy" {
  name = "mongo-backup-policy"
  role = aws_iam_role.backup_role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:SendCommand",
          "ssm:GetCommandInvocation"
        ]
        Resource = [
          aws_ssm_document.backup_script.arn,
          "arn:aws:ec2:${var.region}:${data.aws_caller_identity.current.account_id}:instance/${aws_instance.mongo.id}"
        ]
      }
    ]
  })
}

# Regla de EventBridge para programar la ejecución diaria
resource "aws_cloudwatch_event_rule" "backup_schedule" {
  name                = "mongo-backup-daily"
  description         = "Ejecuta backup de MongoDB diariamente a las 12 AM"
  schedule_expression = "cron(0 0 * * ? *)"  # Todos los días a las 12 AM UTC
}

# Target para la regla de EventBridge
resource "aws_cloudwatch_event_target" "backup_target" {
  rule      = aws_cloudwatch_event_rule.backup_schedule.name
  target_id = "MongoDBBackup"
  arn       = "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:document/${aws_ssm_document.backup_script.name}"
  role_arn  = aws_iam_role.backup_role.arn
  
  input = jsonencode({
    InstanceIds = [aws_instance.mongo.id]
    DocumentName = aws_ssm_document.backup_script.name
  })

  # Añadir los parámetros específicos para Run Command
  run_command_targets {
    key    = "tag:Name"
    values = ["mongo-old"]
  }
}

# Política IAM para permitir que la instancia de MongoDB ejecute comandos SSM
resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.mongo_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# ConfigMap aws-auth para mapear roles/usuarios IAM a Kubernetes RBAC
# Gestionado por Terraform para incluir el rol de los nodos y el usuario interactivo
resource "kubernetes_config_map_v1_data" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }
  force = true # Permite a Terraform tomar control de este ConfigMap
  data = {
    # Mapeo del Rol IAM de los Nodos EKS para permitirles unirse al clúster
    mapRoles = yamlencode([
      for group in values(module.eks.eks_managed_node_groups) : {
        rolearn  = group.iam_role_arn
        username = "system:node:{{EC2PrivateDNSName}}"
        groups   = [
          "system:bootstrappers",
          "system:nodes"
        ]
      }
    ])
    # Mapeo del usuario IAM interactivo para darle permisos de admin
    mapUsers = yamlencode([
      {
        userarn  = "arn:aws:iam::277707137984:user/odl_user_1695962" # Tu ARN de usuario
        username = "odl_user_1695962" # Nombre de usuario en K8s
        groups   = [
          "system:masters" # Grupo de administradores
        ]
      }
    ])
  }

  depends_on = [module.eks] # Asegura que el clúster exista antes de crear el ConfigMap
}