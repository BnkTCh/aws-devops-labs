#!/bin/bash
# Da al DevOps Agent acceso de solo lectura a la API de Kubernetes del cluster.
#
# El rol del Agent Space ya tiene permisos IAM sobre EKS (AIDevOpsAgentAccessPolicy),
# pero EKS además exige una "access entry" para entrar al cluster. Sin ella, el
# agente ve métricas y logs de CloudWatch, pero no pods, eventos ni reinicios.

set -e

CLUSTER_NAME="demo-automode"
REGION="us-east-1"
VIEW_POLICY="arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"

echo "========================================="
echo "  🔑 Acceso del DevOps Agent al cluster"
echo "========================================="
echo ""

# Buscar el rol de investigación que crea el Agent Space (el sufijo cambia por cuenta)
ROLE_ARNS=$(aws iam list-roles \
  --query 'Roles[?starts_with(RoleName, `DevOpsAgentRole-AgentSpace-`)].Arn' \
  --output text)

if [ -z "$ROLE_ARNS" ]; then
  echo "❌ No encontré ningún rol DevOpsAgentRole-AgentSpace-*."
  echo "   Crea primero el Agent Space en la consola de AWS DevOps Agent (ver el paso 0 del README)."
  exit 1
fi

ROLE_COUNT=$(echo "$ROLE_ARNS" | wc -w | tr -d ' ')
if [ "$ROLE_COUNT" -gt 1 ]; then
  echo "Encontré varios roles de Agent Space:"
  for R in $ROLE_ARNS; do echo "  - $R"; done
  echo ""
  read -p "Pega el ARN del rol del Agent Space que vas a usar: " ROLE_ARN
else
  ROLE_ARN="$ROLE_ARNS"
fi

echo "Rol del agente: $ROLE_ARN"
echo ""

# Crear la access entry (si ya existe de una corrida anterior, no se duplica)
if aws eks describe-access-entry \
  --cluster-name "$CLUSTER_NAME" \
  --principal-arn "$ROLE_ARN" \
  --region "$REGION" > /dev/null 2>&1; then
  echo "✅ Access entry ya existe"
else
  aws eks create-access-entry \
    --cluster-name "$CLUSTER_NAME" \
    --principal-arn "$ROLE_ARN" \
    --region "$REGION" > /dev/null
  echo "✅ Access entry creada"
fi

# Asociar la política de solo lectura a nivel de cluster (idempotente)
aws eks associate-access-policy \
  --cluster-name "$CLUSTER_NAME" \
  --principal-arn "$ROLE_ARN" \
  --policy-arn "$VIEW_POLICY" \
  --access-scope type=cluster \
  --region "$REGION" > /dev/null
echo "✅ AmazonEKSViewPolicy asociada (solo lectura, todo el cluster)"

echo ""
echo "El agente ahora puede leer pods, eventos y deployments."
echo "No puede modificar nada ni leer Secrets."
echo "La access entry se borra sola al eliminar el cluster."
echo ""
echo "➡  Siguiente: ensaya una investigación en el Agent Space y luego"
echo "   ./scripts/05-trigger-incident.sh"
