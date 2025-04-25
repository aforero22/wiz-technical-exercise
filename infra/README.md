# Infraestructura AWS (IaC)

Este directorio contiene la infraestructura como código (IaC) implementada con Terraform para el ejercicio técnico.

## Estructura

```
infra/
├── main.tf                # Recursos principales (VPC, EKS, EC2)
├── security.tf            # Configuraciones de seguridad (IAM, Security Groups)
├── variables.tf           # Definición de variables
├── outputs.tf            # Outputs de Terraform
├── backend.tf            # Configuración del backend
└── terraform.tfvars.sample # Ejemplo de variables
```

## Componentes Principales

1. **Networking**:
   - VPC con CIDR 10.0.0.0/16
   - Subredes públicas y privadas
   - Internet Gateway y NAT Gateway
   - Security Groups con reglas permisivas

2. **Compute**:
   - EKS cluster para la aplicación
   - EC2 instance para MongoDB
   - Node groups para EKS

3. **Storage**:
   - S3 bucket público para backups
   - EBS volumes para MongoDB

4. **Security**:
   - IAM roles y políticas
   - Security Groups
   - KMS keys

## Vulnerabilidades Intencionales

1. **EC2 (MongoDB)**:
   - Sistema operativo obsoleto (Ubuntu 16.04)
   - En subred pública
   - SSH abierto a 0.0.0.0/0
   - IAM role con permisos excesivos

2. **S3**:
   - Bucket público
   - Sin cifrado
   - Listado de objetos permitido

3. **Networking**:
   - Security Groups permisivos
   - Recursos en subredes públicas
   - NAT Gateway expuesto

## Despliegue

1. **Inicialización**:
   ```bash
   terraform init
   ```

2. **Revisión de cambios**:
   ```bash
   terraform plan
   ```

3. **Aplicar cambios**:
   ```bash
   terraform apply
   ```

## Variables Requeridas

Copiar `terraform.tfvars.sample` a `terraform.tfvars` y configurar:
- `aws_region`: Región de AWS
- `environment`: Entorno (dev/prod)
- `vpc_cidr`: CIDR de la VPC
- `mongodb_instance_type`: Tipo de instancia EC2

## Outputs

- `eks_cluster_endpoint`: Endpoint del cluster EKS
- `mongo_public_ip`: IP pública de MongoDB
- `mongo_private_ip`: IP privada de MongoDB
- `backups_bucket`: Nombre del bucket S3
- `ecr_repository_url`: URL del repositorio ECR

## Monitoreo y Detección

La infraestructura está monitoreada por servicios nativos de AWS:

1. **AWS Config**:
   - Reglas para evaluar configuración de recursos
   - Monitoreo de cambios en Security Groups
   - Evaluación de compliance de IAM
   - Detección de recursos públicos

2. **Amazon GuardDuty**:
   - Detección de amenazas en tiempo real
   - Análisis de logs de VPC Flow
   - Monitoreo de actividad de IAM
   - Identificación de accesos maliciosos

3. **AWS CloudTrail**:
   - Registro de actividad de la API
   - Auditoría de cambios en recursos
   - Seguimiento de acciones administrativas
   - Logs de acceso a S3 