#!/bin/bash
# Demuestra el auto-scaling de EKS Auto Mode
# Escala de 3 a 10 réplicas y observa cómo se agregan nodos

LAB_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "========================================="
echo "  🚀 Test de escalamiento Auto Mode"
echo "========================================="
echo ""

echo "📌 Estado actual:"
kubectl get deployment nginx-demo
kubectl get nodes
echo ""

echo "Escalando nginx-demo de 3 a 10 réplicas..."
kubectl scale deployment nginx-demo --replicas=10
echo ""

echo "⏱️  Esperando 10 segundos para que Auto Mode reaccione..."
sleep 10
echo ""

echo "📌 Pods después de escalar:"
kubectl get pods -o wide
echo ""

echo "📌 Nodos después de escalar:"
kubectl get nodes -o wide
echo ""

echo "========================================="
echo "  Bonus: Escalamiento agresivo"
echo "========================================="
echo ""
read -p "¿Quieres deployear 20 pods más para ver scaling agresivo? (y/n): " RESPONSE
if [ "$RESPONSE" = "y" ]; then
  echo ""
  echo "Aplicando stress-test-deployment..."
  kubectl apply -f "$LAB_DIR/manifests/stress-test-deployment.yaml"
  echo ""
  echo "Esperando 30 segundos..."
  sleep 30
  echo ""
  echo "📌 Nodos totales ahora:"
  kubectl get nodes -o wide
  echo ""
  echo "📌 Pods totales:"
  kubectl get pods --all-namespaces | grep -c "Running"
  echo " pods running"
fi

echo ""
echo "➡️  Cuando termines: ./scripts/99-cleanup.sh"
