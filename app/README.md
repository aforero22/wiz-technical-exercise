# Aplicación Web (Tier 1)

Esta carpeta contiene la aplicación web containerizada que forma parte del ejercicio técnico de Wiz.

## Estructura

```
app/
├── Dockerfile              # Definición del contenedor con vulnerabilidades intencionales
├── wizexercise.txt        # Archivo requerido para el ejercicio
├── src/                   # Código fuente de la aplicación
│   ├── app.py            # Aplicación Flask con vulnerabilidades documentadas
│   ├── requirements.txt   # Dependencias de Python
│   └── templates/        # Plantillas HTML
└── k8s/                  # Configuración de Kubernetes
    └── deployment.yaml   # Manifiesto de despliegue con privilegios excesivos
```

## Vulnerabilidades Intencionales

1. **Contenedor**:
   - Ejecutándose como root (uid 0)
   - Sin límites de recursos
   - Imagen base sin versión específica

2. **Aplicación**:
   - Debug mode activado
   - Sin validación de entrada
   - Sin protección CSRF
   - Exposición de IDs de MongoDB

3. **Kubernetes**:
   - Privilegios cluster-admin
   - SecurityContext permisivo
   - Sin políticas de red

## Construcción y Despliegue

1. **Construir imagen**:
   ```bash
   docker build -t wiz-app .
   ```

2. **Ejecutar localmente**:
   ```bash
   docker run -p 8080:8080 -e MONGODB_URI="mongodb://host.docker.internal:27017/wizdb" wiz-app
   ```

3. **Desplegar en Kubernetes**:
   ```bash
   kubectl apply -f k8s/deployment.yaml
   ```

## Configuración

Variables de entorno:
- `MONGODB_URI`: URI de conexión a MongoDB (default: mongodb://localhost:27017/wizdb)
- `DEBUG`: Habilita modo debug (default: True)
- `PORT`: Puerto de la aplicación (default: 8080)

## Detección con Wiz

Esta aplicación está diseñada para demostrar:
1. Vulnerabilidades en contenedores
2. Configuraciones inseguras de Kubernetes
3. Problemas de seguridad en aplicaciones web
4. Exposición de servicios internos 