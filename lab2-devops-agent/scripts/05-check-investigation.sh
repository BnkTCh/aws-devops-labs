#!/bin/bash
# Verifica el estado de las alarmas y guía para revisar la investigación del agente

REGION="us-east-1"

echo "========================================="
echo "  🔍 Estado del incidente"
echo "========================================="
echo ""

# Estado de alarmas
echo "📌 CloudWatch Alarms:"
aws cloudwatch describe-alarms \
  --alarm-name-prefix "error-simulator" \
  --region "$REGION" \
  --query 'MetricAlarms[*].{Name:AlarmName, State:StateValue, Reason:StateReason}' \
  --output table
echo ""

# Últimos logs de la Lambda
echo "📌 Últimos errores en CloudWatch Logs:"
LOG_GROUP="/aws/lambda/error-simulator-demo"

aws logs filter-log-events \
  --log-group-name "$LOG_GROUP" \
  --region "$REGION" \
  --filter-pattern "ERROR" \
  --limit 5 \
  --query 'events[*].message' \
  --output text 2>/dev/null || echo "   (Log group aún no disponible o sin errores)"

echo ""
echo "========================================="
echo "  📋 Qué revisar en la investigación del agente"
echo "========================================="
echo ""
echo "  - Summary: resumen del incidente, causa y mitigación"
echo "  - Investigation timeline: qué revisó el agente y en qué orden"
echo "  - Root cause: hallazgos etiquetados (root cause, symptom, gap...)"
echo "  - Mitigation plan: pasos propuestos, con rollback"
echo ""
echo "  Consola DevOps Agent:"
echo "  https://console.aws.amazon.com/devops-agent/"
echo ""
echo "  Consola CloudWatch Alarms:"
echo "  https://console.aws.amazon.com/cloudwatch/home?region=$REGION#alarmsV2:"
echo ""
echo "  CloudWatch Logs:"
echo "  https://console.aws.amazon.com/cloudwatch/home?region=$REGION#logsV2:log-groups/log-group/\$252Faws\$252Flambda\$252Ferror-simulator-demo"
