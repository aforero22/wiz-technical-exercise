# Wiz Technical Exercise

Este repositorio implementa una solución completa en AWS para el ejercicio técnico de Wiz, demostrando una aplicación web de tres niveles con debilidades de configuración intencionales que pueden ser detectadas y corregidas utilizando herramientas de seguridad propias del CSP, en este caso AWS.

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
   - AWS GuardDuty para detección de amenazas
   - AWS Config para evaluación de configuración
   - CloudTrail para auditoría

## Demostración

### Componentes a Mostrar

1. **Infraestructura**:
   - VPC con subredes públicas y privadas
   - EKS cluster con nodos worker
   - VM de MongoDB en subred pública
   - Bucket S3 para backups

2. **Aplicación**:
   - Aplicación web accesible públicamente
   - Conexión a MongoDB sin autenticación
   - Contenedores corriendo como root

3. **Vulnerabilidades**:
   - Ver [VULNERABILITIES.md](VULNERABILITIES.md) para lista completa
   - MongoDB expuesto públicamente sin autenticación
   - S3 bucket con acceso público
   - Pods corriendo como root
   - IAM roles con permisos excesivos

4. **Controles de Seguridad**:
   - CloudTrail para auditoría
   - GuardDuty para detección
   - AWS Config para monitoreo

### Pasos de la Demostración

1. **Despliegue**:
   ```bash
   # Desplegar infraestructura
   cd infra
   terraform init
   terraform apply

   # Desplegar aplicación
   cd ../app
   kubectl apply -f k8s/
   ```

2. **Verificación**:
   - Acceder a la aplicación web
   - Verificar conexión a MongoDB
   - Comprobar acceso público al S3
   - Ejecutar backup manual con scripts/backup.sh

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
│   ├── demo.sh             # Script para demostración
│   └── mongo-userdata.sh   # Script de inicialización para la VM de MongoDB
├── .github/                # Configuración de GitHub
│   └── workflows/          # Pipelines de CI/CD
│       ├── ci-infra.yml    # Pipeline para infraestructura
│       └── ci-app.yml      # Pipeline para la aplicación
├── VULNERABILITIES.md      # Documentación de vulnerabilidades
├── README.md               # Este archivo
└── LICENSE                 # Licencia del proyecto
```

## Debilidades de Seguridad Intencionales

Este proyecto incluye varias debilidades de configuración intencionales que pueden ser detectadas por herramientas de seguridad nativas de AWS:

1. **MongoDB Inseguro**:
   - Sin autenticación habilitada
   - Expuesto públicamente
   - Ubicado en subnet pública

2. **Permisos IAM Excesivos**:
   - La VM de MongoDB tiene permisos excesivos
   - Los pods tienen permisos cluster-admin

3. **Acceso SSH Abierto**:
   - El puerto 22 (SSH) está abierto a Internet (0.0.0.0/0)
   - Esto permite intentos de acceso desde cualquier IP

4. **Bucket S3 Público**:
   - El bucket está configurado como público
   - Permite acceso de lectura a cualquier persona

5. **Privilegios de Contenedor Excesivos**:
   - El contenedor de la aplicación se ejecuta como root
   - Debug mode habilitado en Flask
   - Sin límites de recursos

## Detección con Herramientas de AWS

Estas debilidades de seguridad pueden ser detectadas mediante:

1. **Escaneo de Infraestructura**:
   - Identificación de roles IAM con permisos excesivos (AWS Config)
   - Detección de grupos de seguridad con reglas permisivas (AWS Config, GuardDuty)
   - Identificación de recursos expuestos públicamente (GuardDuty)

2. **Escaneo de Contenedores**:
   - Identificación de contenedores que se ejecutan como root
   - Detección de configuraciones inseguras en la aplicación

3. **Escaneo de Almacenamiento**:
   - Detección de buckets S3 públicos (AWS Config)
   - Identificación de políticas de bucket permisivas (CloudTrail)

## Prerrequisitos

- AWS IAM User con permisos para EKS, EC2, S3, IAM, GuardDuty, CloudTrail, ECR y VPC
- Terraform CLI
- kubectl y Helm
- Docker

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

## Demostración con Herramientas de AWS

1. Revisa los hallazgos en AWS GuardDuty
2. Revisa las reglas y evaluaciones en AWS Config
3. Consulta registros de auditoría en CloudTrail

## Limpieza

Para destruir todo lo creado:

```bash
cd infra
terraform destroy -auto-approve
```

## Licencia

Este proyecto está bajo la **MIT License**. Consulta el archivo LICENSE para más detalles.



