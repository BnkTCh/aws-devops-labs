#!/bin/bash
# Explora el cluster EKS Auto Mode antes de deployear workloads
# Muestra qué viene pre-configurado vs EKS clásico

echo "========================================="
echo "  Explorando cluster EKS Auto Mode"
echo "========================================="
echo ""

echo "📌 Nodos actuales:"
kubectl get nodes -o wide
echo ""

echo "📌 Node Pools (gestionados por AWS):"
kubectl get nodepools
echo ""
echo "   system: 1 nodo para los componentes internos del cluster."
echo "   general-purpose: 0 nodos hasta que despliegues tu app."
echo ""

echo "📌 Namespaces:"
kubectl get namespaces
echo ""

echo "📌 Pods del sistema (kube-system):"
kubectl get pods -n kube-system
echo ""

echo "📌 Storage Classes disponibles (pre-configuradas por Auto Mode):"
kubectl get storageclass
echo ""

echo "📌 Add-ons instalados automáticamente:"
CLUSTER_NAME="demo-automode"
REGION="us-east-1"
aws eks list-addons --cluster-name "$CLUSTER_NAME" --region "$REGION" --output table 2>/dev/null || echo "Verificar con: aws eks list-addons --cluster-name demo-automode"
echo ""

echo "========================================="
echo "  Comparación: Lo que Auto Mode hizo por ti"
echo "========================================="
echo ""
echo "  En EKS clásico tendrías que configurar:"
echo "  ❌ Managed Node Groups o Self-managed nodes"
echo "  ❌ Karpenter o Cluster Autoscaler"
echo "  ❌ EBS CSI Driver"
echo "  ❌ CoreDNS addon"
echo "  ❌ kube-proxy"
echo "  ❌ VPC CNI plugin"
echo ""
echo "  En Auto Mode, AWS gestiona TODO esto ☝️"
echo ""
echo "➡️  Siguiente paso: kubectl apply -f manifests/nginx-demo.yaml"
