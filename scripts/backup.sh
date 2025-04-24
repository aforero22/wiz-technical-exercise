#!/usr/bin/env bash
set -euo pipefail

# Variables de entorno requeridas:
#   MONGO_CONN_URI (mongodump URI)
#   AWS_BUCKET_NAME

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
FILENAME="dump_${TIMESTAMP}.archive"

echo "-> Iniciando backup de MongoDB"
mongodump --uri "$MONGO_CONN_URI" --archive="$FILENAME"
echo "-> Subiendo $FILENAME a s3://$AWS_BUCKET_NAME/"
aws s3 cp "$FILENAME" "s3://$AWS_BUCKET_NAME/"
echo "-> Backup completado"