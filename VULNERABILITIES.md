# Vulnerabilidades Intencionales

Este documento lista las vulnerabilidades intencionales implementadas en el ejercicio técnico de Wiz.

## 1. Base de Datos (MongoDB)

### VM y Sistema Operativo
- **Ubuntu 16.04 LTS (EOL)**: Sistema operativo obsoleto sin soporte
- **MongoDB 4.0**: Versión antigua de la base de datos
- **VM en subred pública**: Expuesta a Internet
- **SSH abierto al mundo** (0.0.0.0/0): Permite acceso desde cualquier IP

### Configuración de MongoDB
- **Sin autenticación**: MongoDB accesible sin credenciales
- **Sin cifrado**: Comunicación en texto plano
- **Sin restricciones de red**: Puerto 27017 potencialmente accesible desde Internet

### Permisos IAM
- **Rol con permisos excesivos**: La VM tiene acceso completo a AWS
- **Política de backup con permisos amplios**: Permite acceso a múltiples servicios

## 2. Almacenamiento (S3)

### Bucket de Backups
- **Acceso público**: Bucket configurado como público
- **Listado público**: Permite enumerar contenido
- **Lectura pública**: Cualquiera puede descargar backups
- **Sin cifrado**: Datos almacenados en texto plano

## 3. Aplicación Web

### Contenedor
- **Ejecución como root**: Contenedor con privilegios elevados
- **Sin límites de recursos**: No hay restricciones de CPU/memoria
- **Imagen base sin versión específica**: Puede llevar a inconsistencias

### Kubernetes
- **Privilegios de cluster-admin**: Pod con acceso completo al cluster
- **SecurityContext permisivo**: runAsUser: 0
- **Sin políticas de red**: Comunicación sin restricciones

## 4. Infraestructura

### Red
- **Subredes públicas**: Expuestas a Internet
- **Security Groups permisivos**: Reglas de entrada amplias
- **NAT Gateway público**: Expone tráfico interno

### Monitoreo
- **Logs no centralizados**: Dificulta la detección de incidentes
- **Sin alertas**: No hay notificaciones de eventos sospechosos
- **Auditoría limitada**: No todos los eventos son registrados

## 5. CI/CD

### Pipelines
- **Secretos en texto plano**: Credenciales expuestas en logs
- **Sin escaneo de seguridad**: No se verifican vulnerabilidades
- **Sin pruebas de seguridad**: No hay validación de seguridad

## Detección con Wiz

Wiz puede detectar estas vulnerabilidades mediante:
1. Escaneo de infraestructura
2. Análisis de configuración de contenedores
3. Evaluación de permisos IAM
4. Detección de recursos públicos
5. Análisis de seguridad de red 