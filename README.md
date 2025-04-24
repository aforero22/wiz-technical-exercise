# Wiz Technical Exercise

Este repositorio implementa una solución completa en AWS para el ejercicio técnico de Wiz, demostrando una aplicación web de tres niveles con debilidades de configuración intencionales que pueden ser detectadas y corregidas utilizando herramientas de seguridad CSP como Wiz.

## Descripción General

Este proyecto implementa:

1. **Infraestructura como Código (IaC)**: Utilizando Terraform para crear y gestionar recursos en AWS.
2. **Aplicación Web de Tres Niveles**:
   - **Nivel de Aplicación**: Aplicación web en contenedores desplegada en Kubernetes (EKS).
   - **Nivel de Base de Datos**: MongoDB ejecutándose en una VM con configuración insegura.
   - **Nivel de Almacenamiento**: Bucket S3 público para almacenar copias de seguridad.
3. **Automatización DevOps**:
   - Pipelines de CI/CD para infraestructura y aplicación.
   - Scripts para automatizar tareas como copias de seguridad.
4. **Controles de Seguridad**:
   - Implementación de controles preventivos y de detección.
   - Configuración de registro de auditoría.

## Estructura del Repositorio

```text
wiz-technical-exercise/
├── infra/                  # Infraestructura como código (Terraform)
│   ├── backend.tf          # Configuración del backend de Terraform
│   ├── variables.tf        # Variables de Terraform
│   ├── main.tf             # Recursos principales (VPC, EKS, EC2, etc.)
│   ├── security.tf         # Recursos de seguridad (IAM, Security Groups)
│   ├── outputs.tf          # Salidas de Terraform
│   └── terraform.tfvars.sample  # Ejemplo de variables
├── k8s/                    # Configuración de Kubernetes
│   └── helm-chart/         # Chart de Helm para la aplicación
│       ├── Chart.yaml      # Metadatos del chart
│       ├── values.yaml     # Valores por defecto
│       └── templates/      # Plantillas de recursos K8s
│           ├── deployment.yaml  # Despliegue de la aplicación
│           ├── service.yaml     # Servicio para acceso público
│           ├── rbac.yaml        # Configuración de RBAC (con privilegios excesivos)
│           └── secret.yaml      # Secretos para la aplicación
├── app/                    # Código de la aplicación
│   ├── Dockerfile          # Definición de la imagen Docker
│   ├── wizexercise.txt     # Archivo requerido para el ejercicio
│   └── src/                # Código fuente de la aplicación
│       ├── app.py          # Aplicación Flask
│       ├── templates/      # Plantillas HTML
│       └── requirements.txt # Dependencias de Python
├── scripts/                # Scripts de automatización
│   ├── backup.sh           # Script para copias de seguridad de MongoDB
│   └── mongo-userdata.sh   # Script de inicialización para la VM de MongoDB
├── .github/                # Configuración de GitHub
│   └── workflows/          # Pipelines de CI/CD
│       ├── ci-infra.yml    # Pipeline para infraestructura
│       └── ci-app.yml      # Pipeline para la aplicación
├── README.md               # Este archivo
└── LICENSE                 # Licencia del proyecto
```

## Debilidades de Seguridad Intencionales

Este proyecto incluye varias debilidades de configuración intencionales que pueden ser detectadas por herramientas de seguridad CSP como Wiz:

1. **VM con Sistema Operativo Obsoleto**:
   - Ubuntu 16.04 LTS (EOL) para la instancia de MongoDB.
   - MongoDB 4.0 (versión antigua).

2. **Permisos IAM Excesivos**:
   - La VM de MongoDB tiene asignado el rol `AdministratorAccess`.
   - Esto permite acceso completo a todos los servicios de AWS.

3. **Acceso SSH Abierto**:
   - El puerto 22 (SSH) está abierto a Internet (0.0.0.0/0).
   - Esto permite intentos de acceso desde cualquier IP.

4. **Bucket S3 Público**:
   - El bucket de copias de seguridad está configurado como público.
   - Permite acceso de lectura a cualquier persona.

5. **Privilegios de Contenedor Excesivos**:
   - El contenedor de la aplicación se ejecuta como root (usuario 0).
   - Tiene asignado el rol `cluster-admin` en Kubernetes.

6. **Autenticación de Base de Datos Débil**:
   - MongoDB está configurado con autenticación básica.
   - Las credenciales se almacenan en texto plano en los secretos de Kubernetes.

## Detección con Wiz

Wiz puede detectar estas debilidades de seguridad mediante:

1. **Escaneo de Infraestructura**:
   - Detección de instancias con sistemas operativos obsoletos.
   - Identificación de roles IAM con permisos excesivos.
   - Detección de grupos de seguridad con reglas permisivas.

2. **Escaneo de Contenedores**:
   - Identificación de contenedores que se ejecutan como root.
   - Detección de imágenes con vulnerabilidades conocidas.

3. **Escaneo de Almacenamiento**:
   - Detección de buckets S3 públicos.
   - Identificación de políticas de bucket permisivas.

4. **Escaneo de Kubernetes**:
   - Detección de roles RBAC con privilegios excesivos.
   - Identificación de secretos almacenados en texto plano.

## Prerrequisitos

- AWS IAM User con permisos para EKS, EC2, S3, IAM, GuardDuty, CloudTrail, ECR y VPC.
- Terraform CLI ≥ 1.0.
- kubectl y Helm.
- Docker.
- Acceso a una cuenta de Wiz (para la demostración de detección).

## Configuración de Credenciales AWS

Nunca guardes tus claves en el repositorio. Define estas variables en tu entorno o en el proceso de CI:

```bash
export AWS_ACCESS_KEY_ID="tu_access_key"
export AWS_SECRET_ACCESS_KEY="tu_secret_key"
export AWS_REGION="us-east-1"
```

Para GitHub Actions, configura estos valores como secretos del repositorio.

## Despliegue de la Infraestructura

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
   - `mongo_public_ip`: IP pública de MongoDB
   - `eks_cluster_endpoint`: Endpoint del clúster EKS
   - `backups_bucket`: Nombre del bucket de backups
   - `ecr_repository_url`: URI del repositorio ECR

## Despliegue de la Aplicación

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

## Automatización de Copias de Seguridad

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

## Demostración con Wiz

1. Conecta tu cuenta de AWS a Wiz.
2. Ejecuta un escaneo completo de la infraestructura.
3. Revisa los hallazgos de seguridad, que deberían incluir:
   - Sistema operativo obsoleto en la VM de MongoDB
   - Roles IAM con permisos excesivos
   - Bucket S3 público
   - Contenedores ejecutándose como root
   - Roles RBAC con privilegios excesivos

4. Documenta los hallazgos y explica cómo Wiz ayuda a identificar estas debilidades.

## Limpieza

Para destruir todo lo creado:

```bash
cd infra
terraform destroy -auto-approve
```

## Licencia

Este proyecto está bajo la **MIT License**. Consulta el archivo LICENSE para más detalles.



