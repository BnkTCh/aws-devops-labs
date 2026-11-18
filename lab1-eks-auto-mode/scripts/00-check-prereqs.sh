#!/bin/bash
# Verifica que todos los prerequisitos están instalados

echo "========================================="
echo "  Verificando prerequisitos - Lab 1"
echo "========================================="
echo ""

ERRORS=0

# AWS CLI
if command -v aws &> /dev/null; then
  echo "✅ AWS CLI: $(aws --version 2>&1 | cut -d' ' -f1)"
else
  echo "❌ AWS CLI no encontrado. Instalar: brew install awscli"
  ERRORS=$((ERRORS+1))
fi

# eksctl
if command -v eksctl &> /dev/null; then
  EKSCTL_VERSION=$(eksctl version)
  echo "✅ eksctl: $EKSCTL_VERSION"
else
  echo "❌ eksctl no encontrado. Instalar: brew install eksctl"
  ERRORS=$((ERRORS+1))
fi

# kubectl
if command -v kubectl &> /dev/null; then
  echo "✅ kubectl: $(kubectl version --client -o json 2>/dev/null | grep gitVersion | cut -d'"' -f4)"
else
  echo "❌ kubectl no encontrado. Instalar: brew install kubectl"
  ERRORS=$((ERRORS+1))
fi

# AWS credentials
echo ""
echo "Verificando credenciales AWS..."
if aws sts get-caller-identity &> /dev/null; then
  ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
  echo "✅ Credenciales válidas. Account: $ACCOUNT_ID"
else
  echo "❌ Credenciales AWS no configuradas. Ejecutar: aws configure"
  ERRORS=$((ERRORS+1))
fi

echo ""
echo "========================================="
if [ $ERRORS -eq 0 ]; then
  echo "  ✅ Todo listo! Puedes continuar con el lab."
else
  echo "  ❌ $ERRORS errores encontrados. Corregir antes de continuar."
fi
echo "========================================="
