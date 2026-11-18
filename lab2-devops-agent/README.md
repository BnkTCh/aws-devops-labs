# Lab 2: AWS DevOps Agent — Incident Response con IA

## Qué vas a hacer
1. Crear un Agent Space en AWS DevOps Agent
2. Desplegar una app con problemas intencionales (una Lambda que falla)
3. Provocar un incidente que dispare una alarma de CloudWatch
4. Pedirle al agente que investigue y revisar qué encontró

## Prerequisitos

- AWS CLI v2 configurado
- `jq` (`brew install jq`)
- Permisos IAM: CloudFormation, Lambda, CloudWatch, IAM, SNS
- Email para recibir notificaciones SNS
- Región: us-east-1

## Verificar prerequisitos

```bash
./scripts/00-check-prereqs.sh
```

## Pasos del Lab

### 1. Crear el Agent Space (en la consola)
```bash
./scripts/01-create-agent-space.sh   # guía por consola
```
> El Agent Space se crea en la consola de AWS DevOps Agent con la opción
> "Auto-create role (recommended)". NO se crea por CloudFormation
> (el principal IAM correcto usa el namespace `aidevops`).
> Tip: elige "Spanish (Latin America)" para que el agente responda en español.
> Deja "Acciones del agente" (*Agent actions*) desactivado: con eso el agente solo lee.

### 2. Desplegar la app de prueba (Lambda con errores intencionales)
```bash
./scripts/02-deploy-test-app.sh
```

### 3. Verificar que todo está corriendo
```bash
./scripts/03-verify-setup.sh
```

### 4. Provocar el incidente
```bash
./scripts/04-trigger-incident.sh
```

### 5. Iniciar la investigación y observar al DevOps Agent
- Ir a la Web App: AWS DevOps Agent → Agent Space → botón "Iniciar a través de IAM" ("Operator access" en inglés)
- La investigación NO arranca sola al saltar la alarma: la inicias tú
  desde el chat ("Investiga por qué la Lambda ... está fallando") o el
  botón "Start investigation".
- El agente muestra, en 4 pestañas:
  - Summary (resumen ejecutivo, marcado como `resolved`)
  - Investigation timeline (con gráficas)
  - Root cause (con etiquetas: root cause / symptom / observation / gap)
  - Mitigation plan (pasos prepare → apply → rollback)

### 6. Destruir todo
```bash
./scripts/99-cleanup.sh
```

> El script de limpieza borra lo que creó CloudFormation. El Agent Space y los
> roles IAM `DevOpsAgentRole-*` (con sus políticas `AIDevOps*`) se borran a mano;
> el script te indica cómo.

## Tiempo estimado: 30-45 minutos

## Costo
- Recursos del lab (Lambda, CloudWatch, SNS): menos de $1.
- El agente se cobra por segundo de trabajo ($0.0083/s, unos $30 por hora).
  Una investigación como la del lab toma entre 5 y 8 minutos.
  Las cuentas nuevas tienen una prueba gratuita.
  Revisa la [página de precios](https://aws.amazon.com/devops-agent/pricing/) antes de empezar.
