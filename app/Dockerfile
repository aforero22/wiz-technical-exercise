# ============================================
# Dockerfile con vulnerabilidades intencionales
# Este archivo está diseñado para demostrar problemas
# comunes de seguridad en contenedores
# ============================================

# Imagen base: Python 3.9 slim
# VULNERABILIDADES:
# 1. No se especifica una versión exacta (3.9-slim vs 3.9.XX-slim)
# 2. No se usa una imagen certificada o escaneada
# 3. No se verifica la integridad de la imagen base
FROM python:3.9-slim

# Establecer el directorio de trabajo
# VULNERABILIDAD: El directorio es accesible y modificable por cualquiera
WORKDIR /app

# Copiar el archivo de requisitos
# VULNERABILIDADES:
# 1. No se verifica la integridad de los paquetes
# 2. No se especifican versiones exactas en requirements.txt
# 3. No se escanean las dependencias por vulnerabilidades
COPY src/requirements.txt ./

# Instalar dependencias
# VULNERABILIDADES:
# 1. No se actualizan los paquetes del sistema (apt-get update)
# 2. No se instalan parches de seguridad
# 3. No se limpian los archivos temporales
RUN pip install --no-cache-dir -r requirements.txt

# Copiar el código fuente
# VULNERABILIDAD: Todo el código es accesible por el usuario root
COPY src/ .

# Copiar archivo requerido para el ejercicio
# VULNERABILIDAD: Archivo accesible sin restricciones
COPY wizexercise.txt /

# VULNERABILIDADES DE EJECUCIÓN:
# 1. Contenedor ejecutándose como root (no se usa USER)
# 2. No hay HEALTHCHECK definido
# 3. No se especifican límites de recursos
# 4. No se usa EXPOSE para documentar puertos
# 5. No se implementa el principio de mínimo privilegio

# Comando de inicio
# VULNERABILIDADES:
# 1. No hay manejo de señales de sistema
# 2. No hay proceso de inicio seguro
# 3. Debug mode habilitado por defecto
ENTRYPOINT ["python", "app.py"]

# Mejores prácticas no implementadas intencionalmente:
# 1. USER no-root
# 2. HEALTHCHECK
# 3. Límites de recursos
# 4. Escaneo de vulnerabilidades
# 5. Verificación de integridad
# 6. Limpieza de archivos temporales
# 7. Actualizaciones de seguridad