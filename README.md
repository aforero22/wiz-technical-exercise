# Wiz Technical Exercise

Este repositorio implementa la solución completa en AWS para el reto técnico de Wiz: infraestructura, aplicación conteinerizada y automatización.

## Estructura

```text
wiz-technical-exercise/
├── infra/
│   ├── backend.tf
│   ├── variables.tf
│   ├── main.tf
│   ├── security.tf
│   ├── outputs.tf
│   └── terraform.tfvars.sample
├── k8s/
│   └── helm-chart/
│       ├── Chart.yaml
│       ├── values.yaml
│       └── templates/
│           ├── deployment.yaml
│           ├── service.yaml
│           ├── rbac.yaml
│           └── secret.yaml
├── app/
│   ├── Dockerfile
│   ├── wizexercise.txt
│   └── src/
│       ├── app.py
│       └── requirements.txt
├── scripts/
│   └── backup.sh
├── .github/
│   └── workflows/
│       ├── ci-infra.yml
│       └── ci-app.yml
├── README.md
└── LICENSE
```

## Prerrequisitos

- AWS IAM User con permisos para EKS, EC2, S3, IAM, GuardDuty, CloudTrail, ECR y VPC.
- Terraform CLI ≥ 1.0.
- kubectl y Helm.
- Docker.

## Configurar credenciales AWS

Nunca guardes tus claves en el repositorio. Define estas variables en tu entorno o en el proceso de CI




## Despliegue de la infraestructura

1. Copia el archivo de variables:
   ```bash
   cp infra/terraform.tfvars.sample infra/terraform.tfvars
   ```
2. Ajusta valores en `infra/terraform.tfvars` si fuera necesario.
3. Inicializa Terraform:
   ```bash
   cd infra
   terraform init
   ```
4. Aplica la infraestructura:
   ```bash
   terraform apply -auto-approve
   ```
5. Al finalizar, consulta las salidas:
   ```bash
   terraform output
   ```
   - mongo_public_ip: IP pública de MongoDB
   - eks_cluster_endpoint: Endpoint del clúster EKS
   - backups_bucket: Nombre del bucket de backups
   - ecr_repository_url: URI del repositorio ECR.

## Despliegue de la aplicación

1. Obtener URI ECR:
   ```bash
   ECR_URI=$(terraform output -raw ecr_repository_url)
   ```
2. Ejecuta el pipeline CI (push a `main`) o manualmente:
   ```bash
   cd app
   docker build -t $ECR_URI:latest .
   docker push $ECR_URI:latest
   ```
3. Despliega con Helm:
   ```bash
   helm upgrade --install wiz-app k8s/helm-chart \
     --set image.repository=$ECR_URI \
     --set image.tag=latest
   ```
4. Verifica el endpoint:
   ```bash
   kubectl get svc wiz-app-svc
   curl http://<LoadBalancer_DNS>  
   ```

## Automatización de backups

Ejecuta el script para validar el backup manual:

```bash
AWS_BUCKET_NAME=$(terraform output -raw backups_bucket)
MONGO_CONN_URI="mongodb://<USER>:<PASS>@$(terraform output -raw mongo_public_ip):27017/db"
scripts/backup.sh
```

Verifica el archivo en:

```
https://$AWS_BUCKET_NAME.s3.amazonaws.com/dump_YYYYMMDD_HHMMSS.archive
```

## Validación de seguridad

- **GuardDuty**: Revisa la consola para detecciones en AWS GuardDuty.
- **CloudTrail**: Consulta el bucket de CloudTrail en S3 o habilita AWS CloudTrail Insights.

## Limpieza

Para destruir todo lo creado:

```bash
cd infra
terraform destroy -auto-approve
```

## LICENSE

Este proyecto está bajo la **MIT License**. Consulta el archivo LICENSE para más detalles.



