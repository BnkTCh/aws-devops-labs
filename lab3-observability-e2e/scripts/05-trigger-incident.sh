#!/bin/bash
# PROVOCA EL INCIDENTE EN EKS
# Escala el traffic generator para saturar la app
# Esto debería disparar las alarmas de CloudWatch

REGION="us-east-1"

echo "========================================="
echo "  🔥 Provocando incidente en EKS"
echo "========================================="
echo ""
echo "  Qué va a pasar:"
echo "  1. La app se degrada"
echo "  2. Las alarmas se disparan"
echo "  3. Le pides al DevOps Agent que investigue"
echo ""

read -p "¿Iniciar el incidente? (y/n): " CONFIRM
if [ "$CONFIRM" != "y" ]; then
  echo "Cancelado."
  exit 0
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  FASE 1: Aumentar carga (más traffic generators)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Escalando traffic generator de 1 a 5 réplicas..."
kubectl scale deployment traffic-generator -n demo-observability --replicas=5
sleep 5
echo ""
echo "📌 Traffic generators activos:"
kubectl get pods -n demo-observability -l app=traffic-generator --no-headers | wc -l
echo " réplicas generando tráfico"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  FASE 2: Generar tráfico externo adicional"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

LB_URL=$(kubectl get svc slow-api -n demo-observability -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)

if [ -n "$LB_URL" ]; then
  echo "Bombardeando $LB_URL con requests al endpoint problemático..."
  echo ""

  for i in $(seq 1 100); do
    # Atacar el endpoint que más errores genera
    curl -s -o /dev/null -w "%{http_code}" "http://$LB_URL/api/process" &
    curl -s -o /dev/null -w "%{http_code}" "http://$LB_URL/api/heavy" &

    if [ $((i % 20)) -eq 0 ]; then
      echo "  $i/100 batches enviados..."
      wait  # Esperar a que terminen los curls en background
    fi
    sleep 0.2
  done
  wait

  echo ""
  echo "✅ 200 requests adicionales enviados al endpoint problemático"
else
  echo "⚠️  No se pudo obtener URL del LB. El tráfico interno es suficiente."
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  FASE 3: Provocar memory pressure"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Enviando requests al endpoint /api/heavy (memory leak)..."

if [ -n "$LB_URL" ]; then
  for i in $(seq 1 50); do
    curl -s -o /dev/null "http://$LB_URL/api/heavy" &
    sleep 0.1
  done
  wait
  echo "✅ 50 requests al endpoint de memory leak"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ⏱️  Esperando que las alarmas reaccionen"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Las alarmas tienen un período de 1-5 minutos."
echo "Esperando 2 minutos para verificar estado..."
echo ""

for i in {1..12}; do
  printf "."
  sleep 10
done
echo ""
echo ""

# Verificar estado
echo "📌 Estado de alarmas:"
aws cloudwatch describe-alarms \
  --alarm-name-prefix "eks-demo" \
  --region "$REGION" \
  --query 'MetricAlarms[*].{Name:AlarmName, State:StateValue}' \
  --output table

echo ""
echo "📌 Logs de errores recientes:"
kubectl logs -l app=slow-api -n demo-observability --tail=5 | grep -i "ERROR" | head -5
echo ""

echo "========================================="
echo "  📋 Qué hacer ahora:"
echo "========================================="
echo ""
echo "1. 📊 Ver Container Insights:"
echo "   https://console.aws.amazon.com/cloudwatch/home?region=$REGION#container-insights:infrastructure"
echo "   → Buscar cluster: demo-automode"
echo "   → Verás la carga subiendo, los reinicios y los errores"
echo ""
echo "2. 🔔 Ver Alarmas:"
echo "   https://console.aws.amazon.com/cloudwatch/home?region=$REGION#alarmsV2:"
echo "   → Alarmas en estado ALARM (rojo)"
echo ""
echo "3. 🤖 Ver DevOps Agent:"
echo "   https://console.aws.amazon.com/devops-agent/"
echo "   → Agent Space → 'Iniciar a través de IAM' (Web App)"
echo "   → Inicia la investigación desde el chat o con 'Start investigation'"
echo "     (no arranca sola al saltar la alarma)"
echo ""
echo "➡️  Verificar investigación: ./scripts/06-check-investigation.sh"
