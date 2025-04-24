# Imagen base: Python 3.9 slim (versión ligera)
# VULNERABILIDAD: No se especifica una versión exacta, lo que puede llevar a inconsistencias
FROM python:3.9-slim

# Establecer el directorio de trabajo dentro del contenedor
WORKDIR /app

# Copiar el archivo de requisitos primero para aprovechar la caché de Docker
# VULNERABILIDAD: No se verifica la integridad de los paquetes instalados
COPY src/requirements.txt ./

# Instalar dependencias sin guardar la caché
# VULNERABILIDAD: No se actualizan los paquetes del sistema antes de instalar
RUN pip install --no-cache-dir -r requirements.txt

# Copiar el código fuente de la aplicación
COPY src/ .

# Copiar el archivo de ejercicio Wiz
COPY wizexercise.txt /

# VULNERABILIDAD: El contenedor se ejecuta como root por defecto
# En producción, debería usar un usuario no privilegiado

# Comando para ejecutar la aplicación
# VULNERABILIDAD: No se especifican límites de recursos (CPU, memoria)
ENTRYPOINT ["python", "src/app.py"]