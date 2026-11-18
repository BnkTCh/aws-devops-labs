#!/bin/bash
# Despliega la app de prueba que simula errores
# Lambda con errores intermitentes + alarmas CloudWatch + SNS

set -e

LAB_DIR="$(cd "$(dirname "$0")/.." && pwd)"

REGION="us-east-1"
STACK_NAME="devops-agent-test-app"

echo "========================================="
echo "  Desplegando app de prueba para incidentes"
echo "========================================="
echo ""

# Pedir email para notificaciones
read -p "📧 Email para recibir alertas SNS: " EMAIL
if [ -z "$EMAIL" ]; then
  EMAIL="tu@email.com"
  echo "   Usando default: $EMAIL"
fi

echo ""
echo "Desplegando stack de CloudFormation..."
echo "  - Lambda: error-simulator-demo"
echo "  - Alarma: error-simulator-high-errors"
echo "  - Alarma: error-simulator-high-latency"
echo "  - Alarma: error-simulator-throttled"
echo "  - SNS Topic: devops-agent-demo-alerts"
echo ""

aws cloudformation deploy \
  --template-file "$LAB_DIR/cloudformation/test-incident-app.yaml" \
  --stack-name "$STACK_NAME" \
  --region "$REGION" \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides NotificationEmail="$EMAIL"

echo ""
echo "✅ App de prueba desplegada!"
echo ""
echo "========================================="
echo "  ⚠️  IMPORTANTE: Confirma la suscripción email"
echo "========================================="
echo ""
echo "  Revisa tu bandeja de entrada ($EMAIL)"
echo "  y confirma la suscripción de SNS."
echo ""
echo "  Sin confirmar, no recibirás las alertas."
echo ""

# Mostrar outputs
echo "Outputs del stack:"
aws cloudformation describe-stacks \
  --stack-name "$STACK_NAME" \
  --region "$REGION" \
  --query 'Stacks[0].Outputs[*].[OutputKey, OutputValue]' \
  --output table

echo ""
echo "➡️  Siguiente paso: ./scripts/03-verify-setup.sh"
