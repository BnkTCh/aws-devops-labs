#!/bin/bash
# Crea alarmas de CloudWatch basadas en las métricas de Container Insights
# Son las alarmas que después le pedirás investigar al DevOps Agent

set -e

REGION="us-east-1"
CLUSTER_NAME="demo-automode"
NAMESPACE="demo-observability"

echo "========================================="
echo "  🔔 Creando alarmas de CloudWatch"
echo "========================================="
echo ""

# Pedir email para las notificaciones de SNS (opcional)
read -p "📧 Email para alertas (Enter para skip): " ALERT_EMAIL

# Crear SNS topic
if [ -n "$ALERT_EMAIL" ]; then
  echo ""
  echo "Creando SNS topic..."
  TOPIC_ARN=$(aws sns create-topic \
    --name "eks-observability-demo-alerts" \
    --region "$REGION" \
    --query 'TopicArn' \
    --output text)

  aws sns subscribe \
    --topic-arn "$TOPIC_ARN" \
    --protocol email \
    --notification-endpoint "$ALERT_EMAIL" \
    --region "$REGION" > /dev/null

  echo "✅ SNS Topic: $TOPIC_ARN"
  echo "⚠️  Confirma la suscripción en tu email!"
  ALARM_ACTION="--alarm-actions $TOPIC_ARN"
else
  TOPIC_ARN=""
  ALARM_ACTION=""
  echo "Sin notificaciones email (solo monitoreo)"
fi

echo ""

# Alarma 1: Pod restarts (indica crash loops)
echo "Creando alarma: pod-restarts-high..."
aws cloudwatch put-metric-alarm \
  --alarm-name "eks-demo-pod-restarts-high" \
  --alarm-description "Pod slow-api tiene restart loops - posible OOMKilled o crash" \
  --namespace ContainerInsights \
  --metric-name pod_number_of_container_restarts \
  --dimensions Name=ClusterName,Value="$CLUSTER_NAME" Name=Namespace,Value="$NAMESPACE" Name=PodName,Value=slow-api \
  --statistic Maximum \
  --period 300 \
  --threshold 3 \
  --comparison-operator GreaterThanOrEqualToThreshold \
  --evaluation-periods 1 \
  --treat-missing-data notBreaching \
  --region "$REGION" \
  ${ALARM_ACTION} 2>/dev/null && echo "  ✅ pod-restarts-high" || echo "  ⚠️  Métrica aún sin datos (normal si los pods son nuevos)"

# Alarma 2: CPU alta respecto al LÍMITE del pod
# (pod_cpu_utilization mide contra el nodo completo: con un límite de 250m
#  nunca llegaría a 80%. *_over_pod_limit mide contra el límite del pod.)
echo "Creando alarma: cpu-utilization-high..."
aws cloudwatch put-metric-alarm \
  --alarm-name "eks-demo-cpu-high" \
  --alarm-description "CPU de slow-api cerca de su límite - posible saturación" \
  --namespace ContainerInsights \
  --metric-name pod_cpu_utilization_over_pod_limit \
  --dimensions Name=ClusterName,Value="$CLUSTER_NAME" Name=Namespace,Value="$NAMESPACE" Name=PodName,Value=slow-api \
  --statistic Average \
  --period 300 \
  --threshold 80 \
  --comparison-operator GreaterThanOrEqualToThreshold \
  --evaluation-periods 2 \
  --treat-missing-data notBreaching \
  --region "$REGION" \
  ${ALARM_ACTION} 2>/dev/null && echo "  ✅ cpu-utilization-high" || echo "  ⚠️  Posible error en métrica"

# Alarma 3: Memoria respecto al LÍMITE del pod (para detectar la fuga de memoria)
# La fuga simulada crece hasta ~100 MB y se "limpia"; con un límite de 256Mi
# eso es ~40-50%, por eso el umbral es 40% y no 85%.
echo "Creando alarma: memory-utilization-high..."
aws cloudwatch put-metric-alarm \
  --alarm-name "eks-demo-memory-high" \
  --alarm-description "Memoria de slow-api creciendo respecto a su límite - posible memory leak" \
  --namespace ContainerInsights \
  --metric-name pod_memory_utilization_over_pod_limit \
  --dimensions Name=ClusterName,Value="$CLUSTER_NAME" Name=Namespace,Value="$NAMESPACE" Name=PodName,Value=slow-api \
  --statistic Average \
  --period 300 \
  --threshold 40 \
  --comparison-operator GreaterThanOrEqualToThreshold \
  --evaluation-periods 1 \
  --treat-missing-data notBreaching \
  --region "$REGION" \
  ${ALARM_ACTION} 2>/dev/null && echo "  ✅ memory-utilization-high" || echo "  ⚠️  Posible error en métrica"

# Alarma 4: Log errors (basada en métrica de logs)
echo "Creando alarma: log-errors-high..."

# Crear metric filter para contar errores en logs
LOG_GROUP="/aws/containerinsights/${CLUSTER_NAME}/application"
aws logs put-metric-filter \
  --log-group-name "$LOG_GROUP" \
  --filter-name "slow-api-errors" \
  --filter-pattern '"[ERROR]"' \
  --metric-transformations \
    metricName=SlowApiErrors,metricNamespace=CustomEKSMetrics,metricValue=1 \
  --region "$REGION" 2>/dev/null && echo "  ✅ Metric filter creado" || echo "  ⚠️  Log group aún no existe (se crea cuando llegan logs)"

aws cloudwatch put-metric-alarm \
  --alarm-name "eks-demo-app-errors-high" \
  --alarm-description "Alto volumen de errores en slow-api - degradación del servicio" \
  --namespace CustomEKSMetrics \
  --metric-name SlowApiErrors \
  --statistic Sum \
  --period 60 \
  --threshold 10 \
  --comparison-operator GreaterThanOrEqualToThreshold \
  --evaluation-periods 1 \
  --treat-missing-data notBreaching \
  --region "$REGION" \
  ${ALARM_ACTION} 2>/dev/null && echo "  ✅ app-errors-high" || echo "  ⚠️  Se creará cuando haya datos"

echo ""
echo "========================================="
echo "  📌 Resumen de alarmas creadas:"
echo "========================================="
echo ""
aws cloudwatch describe-alarms \
  --alarm-name-prefix "eks-demo" \
  --region "$REGION" \
  --query 'MetricAlarms[*].{Name:AlarmName, State:StateValue}' \
  --output table 2>/dev/null || echo "  (Las alarmas tardan unos minutos en obtener datos)"

echo ""
echo "📊 Ver alarmas en consola:"
echo "  https://console.aws.amazon.com/cloudwatch/home?region=$REGION#alarmsV2:"
echo ""
echo "➡️  Siguiente: ./scripts/05-trigger-incident.sh"
echo "   (Aumenta la carga para disparar las alarmas)"
