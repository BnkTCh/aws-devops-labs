#!/bin/bash
# Crea el cluster EKS con Auto Mode para el lab de observabilidad
# (si ya existe de una corrida anterior de este lab, lo usa tal cual)

set -e

CLUSTER_NAME="demo-automode"
REGION="us-east-1"
K8S_VERSION="1.37"   # soporte estándar hasta nov 2027

echo "========================================="
echo "  Preparando cluster EKS"
echo "========================================="
echo ""

# Verificar si el cluster ya existe
CLUSTER_STATUS=$(aws eks describe-cluster \
  --name "$CLUSTER_NAME" \
  --region "$REGION" \
  --query 'cluster.status' \
  --output text 2>/dev/null || true)

if [ "$CLUSTER_STATUS" = "ACTIVE" ]; then
  echo "✅ Cluster '$CLUSTER_NAME' ya existe y está activo (de una corrida anterior)."
  echo "   Se usa tal cual."
else
  echo "Creando cluster nuevo con EKS Auto Mode..."
  echo "⏱️  Esto toma ~15 minutos..."
  echo ""
  eksctl create cluster \
    --name "$CLUSTER_NAME" \
    --region "$REGION" \
    --version "$K8S_VERSION" \
    --enable-auto-mode
  echo ""
  echo "✅ Cluster creado!"
fi

# Actualizar kubeconfig
echo ""
echo "Configurando kubectl..."
aws eks update-kubeconfig \
  --name "$CLUSTER_NAME" \
  --region "$REGION"

echo ""
echo "Verificando conexión..."
kubectl cluster-info
echo ""
kubectl get nodes
echo ""
echo "➡️  Siguiente: ./scripts/02-enable-observability.sh"
