#!/bin/bash
# Verifica prerequisitos para Lab 2 - AWS DevOps Agent

echo "========================================="
echo "  Verificando prerequisitos - Lab 2"
echo "  AWS DevOps Agent"
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

# jq (para parsear JSON responses)
if command -v jq &> /dev/null; then
  echo "✅ jq: $(jq --version)"
else
  echo "❌ jq no encontrado. Instalar: brew install jq"
  ERRORS=$((ERRORS+1))
fi

# AWS credentials
echo ""
echo "Verificando credenciales AWS..."
if aws sts get-caller-identity &> /dev/null; then
  ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
  REGION=$(aws configure get region 2>/dev/null || echo "no configurada")
  echo "✅ Credenciales válidas."
  echo "   Account: $ACCOUNT_ID"
  echo "   Region:  $REGION"
else
  echo "❌ Credenciales AWS no configuradas."
  ERRORS=$((ERRORS+1))
fi

# Verificar región
echo ""
echo "Verificando región..."
if [ "$REGION" = "us-east-1" ]; then
  echo "✅ Región us-east-1 (recomendada para DevOps Agent)"
else
  echo "⚠️  Región actual: $REGION"
  echo "   DevOps Agent funciona mejor en us-east-1"
  echo "   Los scripts usan --region us-east-1 por defecto"
fi

# Verificar permisos CloudFormation
echo ""
echo "Verificando permisos básicos..."
if aws cloudformation list-stacks --region us-east-1 --max-items 1 &> /dev/null; then
  echo "✅ Permisos CloudFormation OK"
else
  echo "❌ Sin permisos de CloudFormation"
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
