#!/bin/bash

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== Wiz Technical Exercise Demo ===${NC}\n"

# 1. Verificar infraestructura
echo -e "${YELLOW}1. Verificando infraestructura...${NC}"
echo -e "  - Obteniendo IP pública de MongoDB..."
MONGO_PUBLIC_IP=$(terraform -chdir=infra output -raw mongo_public_ip)
echo -e "    MongoDB IP: ${GREEN}$MONGO_PUBLIC_IP${NC}"

echo -e "  - Obteniendo URL del bucket S3..."
S3_BUCKET=$(terraform -chdir=infra output -raw backups_bucket)
echo -e "    Bucket S3: ${GREEN}$S3_BUCKET${NC}"

echo -e "  - Verificando acceso a MongoDB..."
if nc -zv $MONGO_PUBLIC_IP 27017 2>&1 | grep -q "open"; then
    echo -e "    ${RED}¡VULNERABILIDAD! MongoDB es accesible desde Internet${NC}"
else
    echo -e "    ${GREEN}MongoDB no es accesible desde Internet${NC}"
fi

# 2. Verificar aplicación
echo -e "\n${YELLOW}2. Verificando aplicación...${NC}"
echo -e "  - Obteniendo URL del LoadBalancer..."
LB_URL=$(kubectl get svc wiz-app -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo -e "    LoadBalancer URL: ${GREEN}$LB_URL${NC}"

echo -e "  - Verificando pods..."
kubectl get pods -l app=wiz-app

# 3. Verificar backups
echo -e "\n${YELLOW}3. Verificando backups...${NC}"
echo -e "  - Listando backups en S3..."
aws s3 ls s3://$S3_BUCKET/

# 4. Verificar controles de seguridad
echo -e "\n${YELLOW}4. Verificando controles de seguridad...${NC}"
echo -e "  - Verificando CloudTrail..."
aws cloudtrail describe-trails

echo -e "  - Verificando GuardDuty..."
aws guardduty list-detectors

echo -e "  - Verificando AWS Config..."
aws configservice describe-configuration-recorders

# 5. Demostrar vulnerabilidades
echo -e "\n${YELLOW}5. Demostrando vulnerabilidades...${NC}"
echo -e "  - Acceso público a MongoDB:"
echo -e "    ${RED}mongo mongodb://$MONGO_PUBLIC_IP:27017/wizdb${NC}"

echo -e "  - Acceso público a backups:"
echo -e "    ${RED}aws s3 cp s3://$S3_BUCKET/backup.bson .${NC}"

echo -e "  - Privilegios de contenedor:"
echo -e "    ${RED}kubectl exec -it \$(kubectl get pod -l app=wiz-app -o jsonpath='{.items[0].metadata.name}') -- whoami${NC}"

echo -e "\n${GREEN}=== Demo completada ===${NC}"
echo -e "Para más detalles sobre las vulnerabilidades, ver VULNERABILITIES.md" 