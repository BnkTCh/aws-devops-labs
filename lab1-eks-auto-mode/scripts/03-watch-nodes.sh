#!/bin/bash
# Observa cómo Auto Mode provisiona nodos cuando deployeas workloads

echo "========================================="
echo "  👀 Observando Auto Mode en acción"
echo "========================================="
echo ""
echo "  Los nodos aparecen automáticamente cuando"
echo "  hay pods pendientes que necesitan compute."
echo ""
echo "  Tip: Si no has desplegado aún, ejecuta:"
echo "  kubectl apply -f manifests/nginx-demo.yaml"
echo ""
echo "  Presiona Ctrl+C para salir del watch."
echo ""
echo "========================================="
echo ""

echo "📌 Estado de pods:"
kubectl get pods -o wide
echo ""

echo "📌 Observando nodos (watch mode)..."
echo "   Los nodos nuevos del pool general-purpose aparecerán aquí en ~30-60 segundos"
echo ""

kubectl get nodes -w
