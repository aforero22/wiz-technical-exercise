#!/usr/bin/env bash
set -euo pipefail

# Script para realizar copias de seguridad de MongoDB y subirlas a S3
# Este script está diseñado para ser ejecutado periódicamente mediante un cron job

# Variables de entorno requeridas:
#   MONGO_CONN_URI (mongodump URI)
#   AWS_BUCKET_NAME

# Generar nombre de archivo con timestamp para evitar colisiones
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
FILENAME="dump_${TIMESTAMP}.archive"

# VULNERABILIDAD: No se verifica la integridad del backup antes de subirlo a S3
# VULNERABILIDAD: No se implementa rotación de backups antiguos

echo "-> Iniciando backup de MongoDB"
# Crear backup de MongoDB en formato archive
mongodump --uri "$MONGO_CONN_URI" --archive="$FILENAME"
echo "-> Subiendo $FILENAME a s3://$AWS_BUCKET_NAME/"
# Subir backup a S3
aws s3 cp "$FILENAME" "s3://$AWS_BUCKET_NAME/"
echo "-> Backup completado"