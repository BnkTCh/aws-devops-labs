#!/bin/bash
# Verifica que todo está configurado correctamente antes de provocar el incidente

REGION="us-east-1"
FUNCTION_NAME="error-simulator-demo"

echo "========================================="
echo "  Verificando setup del Lab 2"
echo "========================================="
echo ""

# Verificar Lambda existe
echo "📌 Lambda function:"
aws lambda get-function \
  --function-name "$FUNCTION_NAME" \
  --region "$REGION" \
  --query 'Configuration.{Name:FunctionName, Runtime:Runtime, State:State, Memory:MemorySize}' \
  --output table 2>/dev/null

if [ $? -ne 0 ]; then
  echo "❌ Lambda no encontrada. Ejecutar: ./scripts/02-deploy-test-app.sh"
  exit 1
fi

echo ""

# Invocar Lambda una vez para verificar que funciona
echo "📌 Test de invocación (1 vez):"
RESULT=$(aws lambda invoke \
  --function-name "$FUNCTION_NAME" \
  --region "$REGION" \
  --payload '{}' \
  /tmp/lambda-response.json 2>&1)

STATUS_CODE=$(echo "$RESULT" | grep -o '"StatusCode": [0-9]*' | grep -o '[0-9]*')
echo "   Status Code: $STATUS_CODE"

if [ -f /tmp/lambda-response.json ]; then
  echo "   Response: $(cat /tmp/lambda-response.json)"
fi
echo ""

# Verificar alarmas
echo "📌 CloudWatch Alarms:"
aws cloudwatch describe-alarms \
  --alarm-name-prefix "error-simulator" \
  --region "$REGION" \
  --query 'MetricAlarms[*].{Name:AlarmName, State:StateValue, Metric:MetricName}' \
  --output table
echo ""

# Verificar SNS
echo "📌 SNS Topic:"
TOPIC_ARN=$(aws sns list-topics --region "$REGION" \
  --query 'Topics[?contains(TopicArn, `devops-agent-demo-alerts`)].TopicArn' \
  --output text)

if [ -n "$TOPIC_ARN" ]; then
  echo "   Topic: $TOPIC_ARN"
  SUBS=$(aws sns list-subscriptions-by-topic \
    --topic-arn "$TOPIC_ARN" \
    --region "$REGION" \
    --query 'Subscriptions[*].{Endpoint:Endpoint, Status:SubscriptionArn}' \
    --output table 2>/dev/null)
  echo "   Suscripciones:"
  echo "$SUBS"
else
  echo "   ⚠️  Topic no encontrado"
fi

echo ""
echo "========================================="
echo "  ✅ Setup verificado."
echo "  ➡️  Listo para provocar el incidente: ./scripts/04-trigger-incident.sh"
echo "========================================="
