#!/bin/bash
# Despliega la app + genera tráfico para producir métricas
# Espera unos minutos y luego verifica que Container Insights tiene datos

REGION="us-east-1"
CLUSTER_NAME="demo-automode"
LAB_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "========================================="
echo "  🚀 Desplegando app + generando tráfico"
echo "========================================="
echo ""

# Aplicar manifests
echo "Desplegando la app y el generador de tráfico..."
kubectl apply -f "$LAB_DIR/manifests/namespace.yaml"
kubectl apply -f "$LAB_DIR/manifests/slow-api-configmap.yaml"
kubectl apply -f "$LAB_DIR/manifests/slow-api-deployment.yaml"
kubectl apply -f "$LAB_DIR/manifests/traffic-generator.yaml"
echo ""

# Esperar a que los pods estén ready
echo "Esperando que los pods estén ready..."
kubectl wait --for=condition=ready pod -l app=slow-api -n demo-observability --timeout=120s 2>/dev/null || true
kubectl wait --for=condition=ready pod -l app=traffic-generator -n demo-observability --timeout=120s 2>/dev/null || true
echo ""

echo "📌 Estado de pods:"
kubectl get pods -n demo-observability -o wide
echo ""

# Obtener URL del service
LB_URL=$(kubectl get svc slow-api -n demo-observability -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)
if [ -n "$LB_URL" ]; then
  echo "📌 URL del Load Balancer: http://$LB_URL"
  echo ""
  echo "Probando conectividad..."
  sleep 10
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://$LB_URL/health" 2>/dev/null)
  if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ App respondiendo correctamente"
  else
    echo "⏱️  Load Balancer aún inicializando (toma 2-3 min)"
  fi
else
  echo "⏱️  Esperando asignación de Load Balancer..."
fi

echo ""
echo "========================================="
echo "  📊 El traffic generator ya está corriendo"
echo "========================================="
echo ""
echo "El pod 'traffic-generator' está enviando requests"
echo "continuamente a la slow-api. Esto genera:"
echo ""
echo "  → Métricas de CPU/memoria en Container Insights"
echo "  → Logs de errores en CloudWatch Logs"
echo "  → Errores 500 que las alarmas van a detectar"
echo ""
echo "⏱️  Espera 3-5 minutos para que las métricas aparezcan"
echo "   en CloudWatch Container Insights."
echo ""
echo "Mientras tanto puedes verificar:"
echo "  kubectl logs -f -l app=traffic-generator -n demo-observability"
echo "  kubectl logs -f -l app=slow-api -n demo-observability"
echo ""
echo "📊 Container Insights Dashboard:"
echo "  https://console.aws.amazon.com/cloudwatch/home?region=$REGION#container-insights:infrastructure"
echo ""
echo "➡️  Después de 5 min: ./scripts/04-create-alarms.sh"
