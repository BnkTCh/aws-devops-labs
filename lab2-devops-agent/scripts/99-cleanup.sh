#!/bin/bash
# Destruye TODOS los recursos del Lab 2

set -e

REGION="us-east-1"

echo "========================================="
echo "  🗑️  Destruyendo recursos del Lab 2"
echo "========================================="
echo ""

read -p "⚠️  ¿Destruir todos los recursos del lab? (y/n): " CONFIRM
if [ "$CONFIRM" != "y" ]; then
  echo "Cancelado."
  exit 0
fi

echo ""

# 1. Borrar stack de test app
echo "Eliminando app de prueba..."
aws cloudformation delete-stack \
  --stack-name "devops-agent-test-app" \
  --region "$REGION" 2>/dev/null && echo "  ✅ Stack devops-agent-test-app eliminándose" || echo "  ⚠️  Stack no encontrado (ya eliminado?)"

# 2. Esperar a que se elimine
echo ""
echo "Esperando que el stack se elimine..."
aws cloudformation wait stack-delete-complete \
  --stack-name "devops-agent-test-app" \
  --region "$REGION" 2>/dev/null || true

# 3. Borrar log group (CloudFormation no siempre lo borra)
echo "Eliminando log group de Lambda..."
aws logs delete-log-group \
  --log-group-name "/aws/lambda/error-simulator-demo" \
  --region "$REGION" 2>/dev/null && echo "  ✅ Log group eliminado" || echo "  ⚠️  Log group no encontrado"

echo ""
echo "========================================="
echo "  ✅ Recursos eliminados"
echo "========================================="
echo ""
echo "  ⚠️  MANUAL: lo que creaste en la consola no se borra con este script."
echo ""
echo "  1. El Agent Space:"
echo "     https://console.aws.amazon.com/devops-agent/"
echo "     → Seleccionar Agent Space → Settings → Delete"
echo ""
echo "  2. Los roles IAM que AWS creó (no se borran con el Agent Space):"
echo "     - DevOpsAgentRole-AgentSpace-xxxx"
echo "     - DevOpsAgentRole-WebappAdmin-xxxx"
echo "     y sus políticas AIDevOps*. Búscalos con:"
echo "     aws iam list-roles --query 'Roles[?contains(RoleName, \`DevOpsAgent\`)].RoleName' --output text"
echo ""
echo "  Verificar que no queda nada:"
echo "  - CloudFormation stacks"
echo "  - Lambda functions"
echo "  - CloudWatch alarms"
echo "  - SNS topics
  - IAM: roles DevOpsAgentRole-* y políticas AIDevOps*"
