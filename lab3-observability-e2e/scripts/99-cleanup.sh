#!/bin/bash
# Destruye TODOS los recursos del Lab 3
# Incluye: workloads K8s, alarmas, SNS, addon, y opcionalmente el cluster

set -e

REGION="us-east-1"
CLUSTER_NAME="demo-automode"

echo "========================================="
echo "  🗑️  Destruyendo recursos del Lab 3"
echo "========================================="
echo ""

read -p "⚠️  ¿Destruir todos los recursos? (y/n): " CONFIRM
if [ "$CONFIRM" != "y" ]; then
  echo "Cancelado."
  exit 0
fi

echo ""

# 1. Eliminar workloads de Kubernetes
echo "Eliminando workloads de K8s..."
kubectl delete namespace demo-observability --ignore-not-found=true
echo "  ✅ Namespace demo-observability eliminado"
echo ""

# 2. Eliminar alarmas de CloudWatch
echo "Eliminando alarmas..."
ALARMS=$(aws cloudwatch describe-alarms \
  --alarm-name-prefix "eks-demo" \
  --region "$REGION" \
  --query 'MetricAlarms[*].AlarmName' \
  --output text 2>/dev/null)

if [ -n "$ALARMS" ]; then
  aws cloudwatch delete-alarms \
    --alarm-names $ALARMS \
    --region "$REGION"
  echo "  ✅ Alarmas eliminadas: $ALARMS"
else
  echo "  ⚠️  No se encontraron alarmas eks-demo"
fi
echo ""

# 3. Eliminar metric filter
echo "Eliminando metric filter..."
aws logs delete-metric-filter \
  --log-group-name "/aws/containerinsights/${CLUSTER_NAME}/application" \
  --filter-name "slow-api-errors" \
  --region "$REGION" 2>/dev/null && echo "  ✅ Metric filter eliminado" || echo "  ⚠️  Metric filter no encontrado"
echo ""

# 4. Eliminar SNS topic
echo "Eliminando SNS topic..."
TOPIC_ARN=$(aws sns list-topics --region "$REGION" \
  --query 'Topics[?contains(TopicArn, `eks-observability-demo-alerts`)].TopicArn' \
  --output text 2>/dev/null)

if [ -n "$TOPIC_ARN" ] && [ "$TOPIC_ARN" != "None" ]; then
  aws sns delete-topic --topic-arn "$TOPIC_ARN" --region "$REGION"
  echo "  ✅ SNS topic eliminado"
else
  echo "  ⚠️  SNS topic no encontrado"
fi
echo ""

# 5. Preguntar si eliminar el cluster
echo "========================================="
echo ""
read -p "¿Eliminar también el cluster EKS? (y/n): " DELETE_CLUSTER
if [ "$DELETE_CLUSTER" = "y" ]; then
  echo ""
  echo "Eliminando addon de observabilidad..."
  aws eks delete-addon \
    --cluster-name "$CLUSTER_NAME" \
    --addon-name amazon-cloudwatch-observability \
    --region "$REGION" 2>/dev/null && echo "  ✅ Addon eliminado" || echo "  ⚠️  Addon no encontrado"

  echo ""
  echo "Eliminando cluster EKS (5-10 minutos)..."
  eksctl delete cluster --name "$CLUSTER_NAME" --region "$REGION"
  echo "  ✅ Cluster eliminado"

  echo ""
  echo "Eliminando rol IAM del CloudWatch Agent..."
  ROLE_NAME="${CLUSTER_NAME}-cloudwatch-agent"
  if aws iam get-role --role-name "$ROLE_NAME" > /dev/null 2>&1; then
    aws iam detach-role-policy \
      --role-name "$ROLE_NAME" \
      --policy-arn arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy 2>/dev/null || true
    aws iam delete-role --role-name "$ROLE_NAME"
    echo "  ✅ Rol $ROLE_NAME eliminado"
  else
    echo "  ⚠  Rol $ROLE_NAME no encontrado"
  fi
else
  echo ""
  echo "Cluster '$CLUSTER_NAME' conservado."
  echo "Para eliminarlo después: eksctl delete cluster --name $CLUSTER_NAME --region $REGION"
  echo "El rol IAM ${CLUSTER_NAME}-cloudwatch-agent también se conserva (lo usa el addon)."
fi

echo ""
echo "========================================="
echo "  ✅ Cleanup completado"
echo "========================================="
echo ""
echo "  Verificar que no queda nada:"
echo "  - EKS clusters: aws eks list-clusters --region $REGION"
echo "  - CloudWatch alarms: aws cloudwatch describe-alarms --alarm-name-prefix eks-demo"
echo "  - Rol IAM: aws iam get-role --role-name ${CLUSTER_NAME}-cloudwatch-agent (debe dar NoSuchEntity)"
echo "  - EC2 instances: revisar consola"
echo "  - Load Balancers: revisar EC2 → Load Balancers"
