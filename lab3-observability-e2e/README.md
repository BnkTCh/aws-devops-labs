# Lab 3: Observabilidad End-to-End — CloudWatch + DevOps Agent + EKS

## Qué vas a hacer
1. Crear un cluster EKS con Auto Mode
2. Habilitar CloudWatch Container Insights
3. Desplegar una app con problemas intencionales de performance
4. Generar tráfico para producir métricas
5. Configurar alarmas de CloudWatch
6. Pedirle al DevOps Agent que investigue el incidente
7. Provocar el incidente y ver el pipeline completo

## Pipeline completo:
```
App con errores → Container Insights → CloudWatch Alarm → DevOps Agent → Root Cause
```

## Prerequisitos

- AWS CLI v2 + eksctl + kubectl
- Región `us-east-1`
- Un Agent Space de AWS DevOps Agent (ver paso 0)

## Pasos del Lab

### 0. Crear el Agent Space (en la consola)
En la consola de AWS DevOps Agent (`us-east-1`):
1. **Create Agent Space** / *Crear espacio de agente*, con el nombre `demo-devops-agent`.
2. Idioma de respuesta: `Spanish (Latin America)`.
3. Acceso a recursos y aplicación web: creación automática del rol.
4. **Agent actions** / *Acciones del agente*: desactivado (el agente solo lee).

### 1. Preparar cluster EKS
```bash
./scripts/00-check-prereqs.sh
./scripts/01-setup-cluster.sh
```

### 2. Habilitar observabilidad
```bash
./scripts/02-enable-observability.sh
```
El script crea el rol IAM `demo-automode-cloudwatch-agent` y lo asocia al
CloudWatch Agent con Pod Identity. Sin ese rol, los pods quedan `Running` pero
Container Insights se ve vacío (el agente recibe `403` al escribir en CloudWatch).

### 3. Desplegar la app problemática y generar tráfico
```bash
./scripts/03-generate-traffic.sh
```

### 4. Configurar alarmas
```bash
./scripts/04-create-alarms.sh
```

### 4b. Dar al DevOps Agent acceso de lectura al cluster
```bash
./scripts/04b-grant-agent-eks-access.sh
```
Crea una access entry de EKS para el rol del Agent Space con `AmazonEKSViewPolicy`
(solo lectura). Sin ella, el agente no puede ver pods ni eventos de Kubernetes.
### 5. Provocar incidente
```bash
./scripts/05-trigger-incident.sh
```

### 6. Investigar con el DevOps Agent
La investigación no arranca sola al saltar la alarma: iníciala desde el chat
de la Web App del Agent Space. Luego revisa el estado con:
```bash
./scripts/06-check-investigation.sh
```

### 7. Destruir todo
```bash
./scripts/99-cleanup.sh
```

## Tiempo estimado: 45-60 minutos
## Costo estimado: ~$3-5 (EKS + Container Insights, destruir en <2h)
