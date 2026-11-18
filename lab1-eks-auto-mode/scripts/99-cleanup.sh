#!/bin/bash
# Destruye TODOS los recursos del lab
# IMPORTANTE: Ejecutar esto para no gastar créditos

set -e

LAB_DIR="$(cd "$(dirname "$0")/.." && pwd)"

CLUSTER_NAME="demo-automode"
REGION="us-east-1"

echo "========================================="
echo "  🗑️  Destruyendo recursos del Lab 1"
echo "========================================="
echo ""
echo "  Cluster: $CLUSTER_NAME"
echo "  Región:  $REGION"
echo ""

read -p "⚠️  ¿Estás segura de destruir todo? (y/n): " CONFIRM
if [ "$CONFIRM" != "y" ]; then
  echo "Cancelado."
  exit 0
fi

echo ""
echo "Eliminando workloads primero..."
kubectl delete -f "$LAB_DIR/manifests/nginx-demo.yaml" --ignore-not-found=true
kubectl delete -f "$LAB_DIR/manifests/stress-test-deployment.yaml" --ignore-not-found=true
echo ""

echo "Esperando a que Auto Mode borre el load balancer..."
sleep 60
echo ""

echo "Eliminando cluster EKS (esto toma ~5-10 minutos)..."
eksctl delete cluster --name "$CLUSTER_NAME" --region "$REGION"

echo ""
echo "========================================="
echo "  ✅ Todo destruido. No quedan recursos."
echo "========================================="
echo ""
echo "  Verificar en la consola AWS que no hay:"
echo "  - Clusters EKS activos"
echo "  - EC2 instances corriendo"
echo "  - Load Balancers activos"
echo "  - VPCs creadas por eksctl"
