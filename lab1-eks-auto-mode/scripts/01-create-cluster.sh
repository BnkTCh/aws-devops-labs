#!/bin/bash
# Crea un cluster EKS con Auto Mode habilitado
# Tiempo estimado: ~15 minutos

set -e

LAB_DIR="$(cd "$(dirname "$0")/.." && pwd)"

CLUSTER_NAME="demo-automode"
REGION="us-east-1"

echo "========================================="
echo "  Creando cluster EKS Auto Mode"
echo "  Nombre: $CLUSTER_NAME"
echo "  Región: $REGION"
echo "========================================="
echo ""
echo "⏱️  Esto toma aproximadamente 15 minutos..."
echo ""

# Opción 1: Con config YAML (más control)
# eksctl create cluster -f "$LAB_DIR/cluster-config.yaml"

# Opción 2: Con un solo comando (más simple)
eksctl create cluster \
  --name "$CLUSTER_NAME" \
  --region "$REGION" \
  --enable-auto-mode

echo ""
echo "========================================="
echo "  ✅ Cluster creado exitosamente!"
echo "========================================="
echo ""
echo "Verificando conexión..."
kubectl cluster-info
echo ""
echo "Nodos actuales (1 nodo del pool system; general-purpose arranca en 0):"
kubectl get nodes
echo ""
echo "Node Pools configurados por Auto Mode:"
kubectl get nodepools
echo ""
echo "➡️  Siguiente paso: ./scripts/02-explore-cluster.sh"
