#!/bin/bash

# Obtener el nombre del cluster y la región
CLUSTER_NAME="wiz-cluster-new"
REGION="us-east-1"

# Obtener el ARN del rol del node group
NODE_GROUP_ROLE=$(aws eks describe-cluster --name $CLUSTER_NAME --region $REGION --query 'cluster.roleArn' --output text)

# Crear el ConfigMap
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - rolearn: $NODE_GROUP_ROLE
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
    - rolearn: $NODE_GROUP_ROLE
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:masters
  mapUsers: "[]"
EOF

echo "ConfigMap aws-auth aplicado correctamente" 