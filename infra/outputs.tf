 output "mongo_public_ip" {
  value       = aws_instance.mongo.public_ip
  description = "IP pública de la VM MongoDB"
}

output "eks_cluster_endpoint" {
  value       = module.eks.cluster_endpoint
  description = "Endpoint del clúster EKS"
}

output "backups_bucket" {
  value       = aws_s3_bucket.backups.bucket
  description = "Nombre del bucket de backups"
}

output "ecr_repository_url" {
  value       = aws_ecr_repository.wiz_app.repository_url
  description = "URI del repositorio ECR"
}