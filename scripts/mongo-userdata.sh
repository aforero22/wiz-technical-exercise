#!/usr/bin/env bash
# Script de inicialización para la instancia EC2 de MongoDB
# Este script se ejecuta durante el arranque de la instancia (userdata)

# VULNERABILIDAD: Se utiliza Ubuntu 16.04 LTS (EOL) y MongoDB 4.0 (versión antigua)
# VULNERABILIDAD: No se configura autenticación ni TLS
# VULNERABILIDAD: No se configuran firewalls ni restricciones de red

# Actualizar repositorios e instalar dependencias
apt-get update
apt-get install -y gnupg wget

# Añadir clave GPG de MongoDB
wget -qO - https://www.mongodb.org/static/pgp/server-4.0.asc | apt-key add -

# Configurar repositorio de MongoDB 4.0
echo "deb [ arch=amd64 ] https://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/4.0 multiverse" \
    | tee /etc/apt/sources.list.d/mongodb-org-4.0.list

# Actualizar repositorios e instalar MongoDB
apt-get update
apt-get install -y mongodb-org

# Habilitar e iniciar el servicio de MongoDB
systemctl enable mongod
systemctl start mongod

# (Opcional) Crear usuarios y habilitar autenticación
# VULNERABILIDAD: No se implementa esta parte, dejando MongoDB sin autenticación
