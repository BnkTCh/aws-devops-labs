#!/bin/bash
# Habilita CloudWatch Container Insights en el cluster EKS
# Esto instala el CloudWatch Agent y FluentBit para logs

set -e

CLUSTER_NAME="demo-automode"
REGION="us-east-1"

echo "========================================="
echo "  Habilitando CloudWatch Container Insights"
echo "========================================="
echo ""

ADDON_NAME="amazon-cloudwatch-observability"
ROLE_NAME="${CLUSTER_NAME}-cloudwatch-agent"

wait_addon_active() {
  for i in {1..30}; do
    STATUS=$(aws eks describe-addon \
      --cluster-name "$CLUSTER_NAME" \
      --addon-name "$ADDON_NAME" \
      --region "$REGION" \
      --query 'addon.status' \
      --output text 2>/dev/null || true)
    if [ "$STATUS" = "ACTIVE" ]; then
      echo ""
      echo "✅ Addon activo!"
      return 0
    fi
    printf "."
    sleep 10
  done
  echo ""
  echo "⚠  El addon no llegó a ACTIVE. Revisa la consola de EKS → Add-ons."
}

# 1. Rol IAM para el CloudWatch Agent (Pod Identity)
# Sin este rol, el addon se instala y los pods quedan Running, pero el agente
# recibe 403 al enviar datos y Container Insights se ve vacío. EKS Auto Mode
# no da permisos de CloudWatch a los nodos.
echo "Preparando rol IAM '$ROLE_NAME' para el CloudWatch Agent..."
ROLE_ARN=$(aws iam get-role --role-name "$ROLE_NAME" \
  --query 'Role.Arn' --output text 2>/dev/null || true)

if [ -z "$ROLE_ARN" ]; then
  ROLE_ARN=$(aws iam create-role \
    --role-name "$ROLE_NAME" \
    --description "CloudWatch Agent del cluster $CLUSTER_NAME (Lab 3)" \
    --assume-role-policy-document '{
      "Version": "2012-10-17",
      "Statement": [{
        "Effect": "Allow",
        "Principal": {"Service": "pods.eks.amazonaws.com"},
        "Action": ["sts:AssumeRole", "sts:TagSession"]
      }]
    }' \
    --query 'Role.Arn' --output text)
  echo "  ✅ Rol creado: $ROLE_ARN"
else
  echo "  ✅ El rol ya existía (de una corrida anterior): $ROLE_ARN"
fi

aws iam attach-role-policy \
  --role-name "$ROLE_NAME" \
  --policy-arn arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy
echo "  ✅ Política CloudWatchAgentServerPolicy adjunta"
echo ""

# 2. Instalar el addon (o asociarle el rol si ya existía sin él)
ADDON_STATUS=$(aws eks describe-addon \
  --cluster-name "$CLUSTER_NAME" \
  --addon-name "$ADDON_NAME" \
  --region "$REGION" \
  --query 'addon.status' \
  --output text 2>/dev/null || true)

if [ -z "$ADDON_STATUS" ]; then
  echo "Instalando addon $ADDON_NAME con Pod Identity..."
  aws eks create-addon \
    --cluster-name "$CLUSTER_NAME" \
    --addon-name "$ADDON_NAME" \
    --region "$REGION" \
    --resolve-conflicts OVERWRITE \
    --pod-identity-associations "serviceAccount=cloudwatch-agent,roleArn=$ROLE_ARN" \
    > /dev/null
  echo "⏱  Esperando que el addon esté activo (1-3 minutos)..."
  wait_addon_active
else
  PIA=$(aws eks describe-addon \
    --cluster-name "$CLUSTER_NAME" \
    --addon-name "$ADDON_NAME" \
    --region "$REGION" \
    --query 'length(addon.podIdentityAssociations || `[]`)' \
    --output text 2>/dev/null || echo 0)

  if [ "$PIA" = "0" ]; then
    echo "Addon ya instalado pero sin rol. Asociando Pod Identity..."
    aws eks update-addon \
      --cluster-name "$CLUSTER_NAME" \
      --addon-name "$ADDON_NAME" \
      --region "$REGION" \
      --resolve-conflicts OVERWRITE \
      --pod-identity-associations "serviceAccount=cloudwatch-agent,roleArn=$ROLE_ARN" \
      > /dev/null
    wait_addon_active
    echo "Reiniciando agentes para que tomen las credenciales..."
    kubectl rollout restart ds/cloudwatch-agent ds/fluent-bit -n amazon-cloudwatch
    kubectl rollout status ds/cloudwatch-agent -n amazon-cloudwatch --timeout=180s
    kubectl rollout status ds/fluent-bit -n amazon-cloudwatch --timeout=180s
  else
    echo "✅ Addon $ADDON_NAME ya activo y con Pod Identity."
  fi
fi

echo ""
echo "📌 Pods de observabilidad instalados:"
kubectl get pods -n amazon-cloudwatch --no-headers 2>/dev/null || \
  kubectl get pods -A | grep -i "cloudwatch\|fluent"

echo ""
echo "========================================="
echo "  Qué se habilitó:"
echo "========================================="
echo ""
echo "  ✅ CloudWatch Container Insights"
echo "     → Métricas de CPU, memoria, red por pod/nodo"
echo "     → Dashboard automático en CloudWatch"
echo ""
echo "  ✅ FluentBit (log collection)"
echo "     → Logs de containers → CloudWatch Logs"
echo "     → Log group: /aws/containerinsights/$CLUSTER_NAME/"
echo ""
echo "  ✅ CloudWatch Agent"
echo "     → Enhanced monitoring de nodos"
echo ""
echo "  ✅ Rol IAM $ROLE_NAME (Pod Identity)"
echo "     → Permite al agente enviar métricas y logs a CloudWatch"
echo ""
echo "  🔎 Verificar que no hay errores de permisos (debe dar 0):"
echo "     kubectl logs -n amazon-cloudwatch ds/cloudwatch-agent --since=5m | grep -c 'StatusCode: 403'"
echo ""
echo "  📊 Dashboard:"
echo "  https://console.aws.amazon.com/cloudwatch/home?region=$REGION#container-insights:infrastructure"
echo ""
echo "➡️  Siguiente: ./scripts/03-generate-traffic.sh"
echo "   (despliega la app y empieza a generar tráfico)"
