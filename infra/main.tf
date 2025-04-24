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
  name        = "mongo-sg"
  vpc_id      = module.vpc.vpc_id
  description = "Security group for MongoDB instance"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # TODO: Restrict to specific IP ranges
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
  user_data              = file("../scripts/mongo-userdata.sh")
  tags = { Name = "mongo-old" }
}

# EKS Cluster (o k8s managed)
module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "20.36.0"

  cluster_name    = "wiz-cluster-new"
  cluster_version = "1.27"

  vpc_id      = module.vpc.vpc_id
  subnet_ids  = module.vpc.private_subnets

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

module "eks_aws_auth" {
  source  = "terraform-aws-modules/eks/aws//modules/aws-auth"
  version = "20.36.0"

  create_aws_auth_configmap = false
  manage_aws_auth_configmap = true

    # Mapea el rol IAM del Managed Node Group "worker"
  aws_auth_roles = [
    {
      rolearn  = module.eks.eks_managed_node_groups["worker"].iam_role_arn
      username = "system:node:{{EC2PrivateDNSName}}"
      groups   = ["system:bootstrappers", "system:nodes"]
    }
  ]

  aws_auth_users = []  # (si necesitas mapear usuarios, los añades aquí)
  aws_auth_accounts = []
}

# Bucket S3 público
resource "aws_s3_bucket" "backups" {
  bucket = "wiz-exercise-backups-${random_id.bucket_id.hex}"
}

resource "aws_s3_bucket_public_access_block" "backups_block" {
  bucket                  = aws_s3_bucket.backups.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "backups_policy" {
  bucket = aws_s3_bucket.backups.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = ["s3:GetObject"]
        Resource  = ["${aws_s3_bucket.backups.arn}/*"]
      },
      {
        Sid       = "PublicListBucket"
        Effect    = "Allow"
        Principal = "*"
        Action    = ["s3:ListBucket"]
        Resource  = [aws_s3_bucket.backups.arn]
      },
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

resource "aws_s3_bucket" "cloudtrail" {
  bucket = "wiz-exercise-cloudtrail-logs-${random_id.cloudtrail.hex}"
}

resource "aws_s3_bucket_public_access_block" "cloudtrail_block" {
  bucket                  = aws_s3_bucket.cloudtrail.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

data "aws_caller_identity" "current" {}

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
      }
    ]
  })
}

# Security group for EKS nodes
resource "aws_security_group" "eks_nodes" {
  name        = "eks-nodes-sg"
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

# Kubernetes resources for application deployment
resource "kubernetes_deployment" "app" {
  metadata {
    name = "wiz-app"
    labels = {
      app = "wiz-app"
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "wiz-app"
      }
    }

    template {
      metadata {
        labels = {
          app = "wiz-app"
        }
      }

      spec {
        # Run container as root (cluster admin privileges)
        security_context {
          run_as_user  = 0
          run_as_group = 0
          fs_group     = 0
        }

        container {
          name  = "wiz-app"
          image = "${aws_ecr_repository.wiz_app.repository_url}:latest"
          
          env {
            name  = "MONGODB_URI"
            value = "mongodb://${aws_instance.mongo.private_ip}:27017/wizdb"
          }

          resources {
            limits = {
              cpu    = "0.5"
              memory = "512Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "50Mi"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "app" {
  metadata {
    name = "wiz-app"
  }

  spec {
    selector = {
      app = "wiz-app"
    }

    port {
      port        = 80
      target_port = 8080
    }

    type = "LoadBalancer"
  }
}

# CloudTrail for audit logging
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
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSConfigRole"
}

resource "aws_config_configuration_recorder_status" "main" {
  name       = aws_config_configuration_recorder.main.name
  is_enabled = true
}