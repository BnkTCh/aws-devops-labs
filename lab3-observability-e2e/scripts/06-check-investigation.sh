#!/bin/bash
# Verifica el estado de la investigación del DevOps Agent
# y junta la información del incidente

REGION="us-east-1"
CLUSTER_NAME="demo-automode"

echo "========================================="
echo "  🔍 Estado de la investigación"
echo "========================================="
echo ""

# Estado de alarmas
echo "📌 Alarmas de CloudWatch:"
aws cloudwatch describe-alarms \
  --alarm-name-prefix "eks-demo" \
  --region "$REGION" \
  --query 'MetricAlarms[*].{Name:AlarmName, State:StateValue, Updated:StateUpdatedTimestamp}' \
  --output table
echo ""

# Estado de pods
echo "📌 Estado actual de pods:"
kubectl get pods -n demo-observability -o wide
echo ""

# Verificar restarts
echo "📌 Pod restarts:"
kubectl get pods -n demo-observability -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.containerStatuses[0].restartCount}{"\n"}{end}' 2>/dev/null
echo ""

# Métricas del app
echo "📌 Métricas de la app (si el LB responde):"
LB_URL=$(kubectl get svc slow-api -n demo-observability -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)
if [ -n "$LB_URL" ]; then
  curl -s "http://$LB_URL/metrics" 2>/dev/null | python3 -m json.tool 2>/dev/null || echo "  (app no responde)"
fi
echo ""

# Logs de error recientes
echo "📌 Últimos errores en la app:"
kubectl logs -l app=slow-api -n demo-observability --tail=10 2>/dev/null | grep -i "ERROR\|CRITICAL\|WARN" | tail -5
echo ""

echo "========================================="
echo "  📋 Qué revisar"
echo "========================================="
echo ""
echo "  - Container Insights Dashboard con la app degradada"
echo "      URL: https://console.aws.amazon.com/cloudwatch/home?region=$REGION#container-insights:infrastructure"
echo ""
echo "  - Alarma en estado ALARM (rojo)"
echo "      URL: https://console.aws.amazon.com/cloudwatch/home?region=$REGION#alarmsV2:"
echo ""
echo "  - DevOps Agent - Timeline de investigación"
echo "      URL: https://console.aws.amazon.com/devops-agent/"
echo ""
echo "  - DevOps Agent - Root cause analysis"
echo "  - DevOps Agent - Recomendaciones de mitigación"
echo ""
echo "  - CloudWatch Logs - Errores de la app"
echo "      Log group: /aws/containerinsights/$CLUSTER_NAME/application"
echo ""
echo "➡️  Cuando termines: ./scripts/99-cleanup.sh"
