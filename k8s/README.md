# Configuración de Kubernetes

Este directorio contiene los manifiestos de Kubernetes para el despliegue de la aplicación web en EKS.

## Estructura

```
k8s/
├── deployment.yaml    # Despliegue de la aplicación con vulnerabilidades
├── service.yaml      # Servicio para exponer la aplicación
└── rbac.yaml         # Configuración RBAC con privilegios excesivos
```

## Componentes

1. **Deployment**:
   - Imagen de la aplicación Flask
   - SecurityContext permisivo (root)
   - Sin límites de recursos
   - Variables de entorno para MongoDB

2. **Service**:
   - Tipo LoadBalancer
   - Expone puerto 8080
   - Accesible públicamente

3. **RBAC**:
   - ServiceAccount con privilegios cluster-admin
   - Roles y RoleBindings permisivos

## Vulnerabilidades Intencionales

1. **Pod Security**:
   - Contenedor ejecutándose como root
   - Privilegios cluster-admin
   - Sin límites de recursos
   - Sin securityContext restrictivo

2. **Network Security**:
   - Sin Network Policies
   - Comunicación irrestricta entre pods
   - Servicios expuestos públicamente

3. **Secrets**:
   - Credenciales en texto plano
   - Secretos montados sin cifrado
   - Sin rotación de secretos

## Despliegue

1. **Aplicar configuración**:
   ```bash
   kubectl apply -f deployment.yaml
   kubectl apply -f service.yaml
   kubectl apply -f rbac.yaml
   ```

2. **Verificar estado**:
   ```bash
   kubectl get pods
   kubectl get svc
   kubectl get serviceaccounts
   ```

## Configuración

El deployment espera las siguientes variables de entorno:
- `MONGODB_URI`: URI de conexión a MongoDB
- `DEBUG`: Modo debug (true/false)
- `PORT`: Puerto de la aplicación

## Monitoreo y Seguridad

La configuración de Kubernetes es monitoreada por:

1. **Amazon EKS Control Plane Logging**:
   - Logs de API Server
   - Logs de Audit
   - Logs de Authenticator
   - Logs de Controller Manager
   - Logs de Scheduler

2. **AWS Config Rules para EKS**:
   - Evaluación de configuración del cluster
   - Monitoreo de roles RBAC
   - Verificación de políticas de red
   - Control de acceso a pods

3. **Amazon GuardDuty para EKS**:
   - Detección de actividad maliciosa en pods
   - Monitoreo de accesos no autorizados
   - Identificación de configuraciones inseguras
   - Alertas de comportamiento anómalo

4. **CloudWatch Container Insights**:
   - Métricas de rendimiento de pods
   - Logs de contenedores
   - Estado de servicios
   - Alertas de recursos

## Mejores Prácticas (No Implementadas Intencionalmente)

1. **Pod Security**:
   - Usar non-root user
   - Implementar SecurityContext restrictivo
   - Definir límites de recursos

2. **Network Security**:
   - Implementar Network Policies
   - Restringir comunicación entre pods
   - Usar servicios internos cuando sea posible

3. **Secrets**:
   - Usar AWS Secrets Manager
   - Implementar cifrado en tránsito
   - Rotar secretos regularmente 