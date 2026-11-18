# AWS DevOps Labs

Labs prácticos de la serie **"AI-Powered DevOps en AWS"**. Cada lab acompaña un artículo y se puede seguir paso a paso en tu propia cuenta de AWS.

| Lab | De qué se trata | Tiempo |
|---|---|---|
| [Lab 1: EKS Auto Mode](lab1-eks-auto-mode/) | Un cluster de Kubernetes donde AWS gestiona los nodos por ti | 20-30 min |
| [Lab 2: AWS DevOps Agent](lab2-devops-agent/) | Provocar un incidente y dejar que un agente de IA lo investigue | 30-45 min |
| Lab 3: AWS FinOps Agent | Preguntarle a tu factura de AWS en lenguaje natural | Próximamente |
| Lab 4: Observabilidad end-to-end | De una métrica en EKS a un incidente investigado por IA | Próximamente |

## Antes de empezar

- **Usa una cuenta de pruebas**, no una de producción. Los labs crean y borran recursos.
- Necesitas **AWS CLI v2** configurado (`aws configure`). Cada lab tiene un script `00-check-prereqs.sh` que revisa lo que falta.
- Los labs usan la región **`us-east-1`**.
- Corre los scripts desde la carpeta del lab, por ejemplo:

  ```bash
  cd lab2-devops-agent
  ./scripts/00-check-prereqs.sh
  ```

- **Al terminar, corre siempre `./scripts/99-cleanup.sh`** y revisa que no queden recursos. Algunos labs tienen pasos de limpieza manual, y el script te los indica.

## Costos

Los labs están pensados para costar pocos dólares si los borras al terminar. Cada README indica el costo estimado. Los precios de AWS cambian, así que revisa la página de precios de cada servicio antes de empezar.

## Licencia

[MIT](LICENSE)
