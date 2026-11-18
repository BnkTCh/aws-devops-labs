# Lab 1: EKS Auto Mode — Kubernetes sin gestionar nodos

## Prerequisitos

- AWS CLI v2 configurado (`aws configure`)
- eksctl v0.195.0+ (`brew install eksctl`)
- kubectl (`brew install kubectl`)
- Permisos IAM: EC2, EKS, IAM, VPC

## Verificar prerequisitos

```bash
./scripts/00-check-prereqs.sh
```

## Pasos del Lab

### 1. Crear el cluster
```bash
./scripts/01-create-cluster.sh
```

### 2. Explorar el cluster (pool general-purpose en 0 nodos)
```bash
./scripts/02-explore-cluster.sh
```

### 3. Desplegar la app de ejemplo
```bash
kubectl apply -f manifests/nginx-demo.yaml
```

### 4. Observar Auto Mode provisionar nodos automáticamente
```bash
./scripts/03-watch-nodes.sh
```

### 5. Entrar a la app
El NLB tarda un par de minutos en quedar activo.
```bash
kubectl get svc nginx-demo
curl http://$(kubectl get svc nginx-demo -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
```

### 6. Escalar y ver respuesta
```bash
./scripts/04-scale-test.sh
```

### 7. Destruir todo
```bash
./scripts/99-cleanup.sh
```

## Tiempo estimado: 20-30 minutos
## Costo estimado: ~$3-5 (destruir en <2h)
