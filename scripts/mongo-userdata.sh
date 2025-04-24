#!/usr/bin/env bash
# cloud-init para instalar MongoDB 4.x en Ubuntu 16.04

apt-get update
apt-get install -y gnupg wget
wget -qO - https://www.mongodb.org/static/pgp/server-4.0.asc | apt-key add -
echo "deb [ arch=amd64 ] https://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/4.0 multiverse" \
    | tee /etc/apt/sources.list.d/mongodb-org-4.0.list
apt-get update
apt-get install -y mongodb-org
systemctl enable mongod
systemctl start mongod
# (Opcional) Crear usuarios y habilitar autenticación
