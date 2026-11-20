#!/bin/bash
# Verifica prerequisitos para Lab 3 - Observabilidad E2E

echo "========================================="
echo "  Verificando prerequisitos - Lab 3"
echo "  Observabilidad End-to-End"
echo "========================================="
echo ""

ERRORS=0

# AWS CLI
if command -v aws &> /dev/null; then
  echo "✅ AWS CLI: $(aws --version 2>&1 | cut -d' ' -f1)"
else
  echo "❌ AWS CLI no encontrado."
  ERRORS=$((ERRORS+1))
fi

# eksctl
if command -v eksctl &> /dev/null; then
  echo "✅ eksctl: $(eksctl version)"
else
  echo "❌ eksctl no encontrado."
  ERRORS=$((ERRORS+1))
fi

# kubectl
if command -v kubectl &> /dev/null; then
  echo "✅ kubectl: $(kubectl version --client -o json 2>/dev/null | grep gitVersion | cut -d'"' -f4)"
else
  echo "❌ kubectl no encontrado."
  ERRORS=$((ERRORS+1))
fi

# AWS credentials
echo ""
if aws sts get-caller-identity &> /dev/null; then
  ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
  echo "✅ Credenciales válidas. Account: $ACCOUNT_ID"
else
  echo "❌ Credenciales AWS no configuradas."
  ERRORS=$((ERRORS+1))
fi

# Verificar cluster existente
echo ""
echo "Verificando cluster EKS existente..."
CLUSTER_NAME="demo-automode"
REGION="us-east-1"

CLUSTER_STATUS=$(aws eks describe-cluster \
  --name "$CLUSTER_NAME" \
  --region "$REGION" \
  --query 'cluster.status' \
  --output text 2>/dev/null)

if [ "$CLUSTER_STATUS" = "ACTIVE" ]; then
  echo "✅ Cluster '$CLUSTER_NAME' activo"
  echo "   (quedó de una corrida anterior; 01-setup-cluster.sh lo usará tal cual)"
else
  echo "⚠️  Cluster '$CLUSTER_NAME' no encontrado."
  echo "   El script 01-setup-cluster.sh creará uno nuevo."
fi

# Verificar kubeconfig
echo ""
if kubectl cluster-info &> /dev/null; then
  echo "✅ kubectl conectado al cluster"
else
  echo "⚠️  kubectl no está conectado a un cluster."
  echo "   Se configurará en el paso 01."
fi

echo ""
echo "========================================="
if [ $ERRORS -eq 0 ]; then
  echo "  ✅ Todo listo! Puedes continuar."
else
  echo "  ❌ $ERRORS errores. Corregir antes de continuar."
fi
echo "========================================="
