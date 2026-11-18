#!/bin/bash
# PROVOCA EL INCIDENTE
# Invoca la Lambda muchas veces para generar errores y disparar la alarma

REGION="us-east-1"
FUNCTION_NAME="error-simulator-demo"
INVOCATIONS=60
PARALLEL=5

echo "========================================="
echo "  🔥 Provocando incidente"
echo "========================================="
echo ""
echo "  Lambda: $FUNCTION_NAME"
echo "  Invocaciones: $INVOCATIONS"
echo "  Paralelas: $PARALLEL"
echo ""
echo "  Objetivo: generar suficientes errores para"
echo "  que la alarma de CloudWatch se dispare."
echo ""

read -p "¿Iniciar el incidente? (y/n): " CONFIRM
if [ "$CONFIRM" != "y" ]; then
  echo "Cancelado."
  exit 0
fi

echo ""
echo "Invocando Lambda $INVOCATIONS veces..."
echo ""

ERRORS=0
SUCCESSES=0
TIMEOUTS=0

for i in $(seq 1 $INVOCATIONS); do
  # Invocar en background para simular tráfico concurrente
  RESULT=$(aws lambda invoke \
    --function-name "$FUNCTION_NAME" \
    --region "$REGION" \
    --payload '{}' \
    /tmp/lambda-out-$i.json 2>&1)

  # Verificar si hubo error
  if echo "$RESULT" | grep -q "FunctionError"; then
    ERRORS=$((ERRORS+1))
    printf "❌"
  else
    SUCCESSES=$((SUCCESSES+1))
    printf "✅"
  fi

  # Cada 10 invocaciones, nueva línea + estado
  if [ $((i % 10)) -eq 0 ]; then
    echo " [$i/$INVOCATIONS]"
  fi

  # Pausa corta para no throttlear
  sleep 0.5
done

echo ""
echo ""
echo "========================================="
echo "  📊 Resultados"
echo "========================================="
echo "  Total invocaciones: $INVOCATIONS"
echo "  Exitosas: $SUCCESSES"
echo "  Con error: $ERRORS"
echo "  Tasa de error: $(( ERRORS * 100 / INVOCATIONS ))%"
echo ""

# Verificar estado de alarmas
echo "📌 Estado de alarmas después del incidente:"
sleep 5  # Esperar un poco para que CloudWatch procese

aws cloudwatch describe-alarms \
  --alarm-name-prefix "error-simulator" \
  --region "$REGION" \
  --query 'MetricAlarms[*].{Name:AlarmName, State:StateValue}' \
  --output table

echo ""
echo "========================================="
echo "  ⏱️  Qué hacer ahora:"
echo "========================================="
echo ""
echo "1. Esperar 1-2 minutos para que la alarma cambie a ALARM"
echo "2. Ir a: https://console.aws.amazon.com/devops-agent/"
echo "3. Abrir el Agent Space → 'Iniciar a través de IAM' (Web App)"
echo "4. La investigación NO arranca sola: iníciala desde el chat, por ejemplo:"
echo "   \"Investiga por qué la Lambda error-simulator-demo está fallando."
echo "   La alarma error-simulator-high-errors está en ALARM.\""
echo "   (o con el botón 'Start investigation')"
echo ""
echo "Si la alarma no se disparó, ejecuta este script de nuevo."
echo ""

# Limpiar archivos temporales
rm -f /tmp/lambda-out-*.json /tmp/lambda-response.json
