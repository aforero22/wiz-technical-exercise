# Salidas de Terraform
# Este archivo define las salidas que se mostrarán después de aplicar la infraestructura

# IP pública de la instancia de MongoDB
# Esta IP se utiliza para conectarse a la base de datos
output "mongo_public_ip" {
  value       = aws_instance.mongo.public_ip
  description = "IP pública de la VM MongoDB"
}

# Endpoint del clúster EKS
# Este endpoint se utiliza para conectarse al clúster de Kubernetes
output "eks_cluster_endpoint" {
  value       = module.eks.cluster_endpoint
  description = "Endpoint del clúster EKS"
}

# Nombre del bucket de S3 para backups
# Este bucket almacena las copias de seguridad de MongoDB
output "backups_bucket" {
  value       = aws_s3_bucket.backups.bucket
  description = "Nombre del bucket de backups"
}

# URI del repositorio ECR
# Este repositorio almacena las imágenes de Docker de la aplicación
output "ecr_repository_url" {
  value       = aws_ecr_repository.wiz_app.repository_url
  description = "URI del repositorio ECR"
}