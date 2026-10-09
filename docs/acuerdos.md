# Acuerdos y convenciones del proyecto

## 1. Flujo de trabajo y despliegue

El código se trabaja en la rama `dev` y se integra a `main` mediante pull requests con revisión entre el equipo.

- `dev`: rama de integración, recibe los PR de las fases
- `main`: rama estable, solo avanza con merges desde `dev`
- Cada cambio llega como pull request revisado antes de mergear

El despliegue se maneja por tres entornos (`dev`, `qa`, `prod`) y todos usan el mismo código Terraform, variando únicamente los valores de su archivo `.tfvars`. Cada entorno guarda su estado de forma remota en S3, con una clave propia (`<entorno>/terraform.tfstate`).

El script `IaC/scripts/tf.sh` es la puerta de entrada para trabajar con entornos:

```bash
bash IaC/scripts/tf.sh dev plan
bash IaC/scripts/tf.sh qa apply
bash IaC/scripts/tf.sh prod apply
```

Requisitos antes de usarlo:

- Exportar `TF_STATE_BUCKET` con el nombre del bucket donde vive el estado (el nombre nunca se escribe en el repositorio).
- Tener los `build/` de las lambdas generados con `IaC/lambdas/upload/build.sh` e `IaC/lambdas/crop/build.sh` cuando el comando sea `plan`, `apply` o `destroy`.
- El script pide confirmación antes de un `destroy` sobre `prod`.

---

## 2. Infraestructura base

Todo vive en un único root module plano dentro de `IaC/`, con un archivo `.tf` por responsabilidad. Versiones usadas: Terraform `>= 1.11` y proveedor AWS `~> 6.0`, región `us-east-1`.

La red es completamente privada: VPC con dos subnets, **sin** Internet Gateway, **sin** NAT Gateway y sin endpoints de interfaz. Lo único que conecta la VPC con el exterior es el Gateway Endpoint de S3, de forma que las lambdas salen solo hacia el bucket sin costos fijos de red.

El bucket de imágenes no tiene versionado habilitado. El monitoreo de la DLQ con alarma y SNS queda fuera de alcance por ahora.

---

## 3. Recursos y nombres

Los nombres siguen el patrón `image-processor-<entorno>-...` (por ejemplo `image-processor-dev-upload`). No se modifican sin avisar al equipo, porque el resto de piezas los referencia.

| Dirección en Terraform | Nombre en AWS |
|---|---|
| `aws_vpc.main` | `image-processor-<entorno>-vpc` |
| `aws_subnet.private_a` / `private_b` | `...-subnet-private-a` / `...-subnet-private-b` |
| `aws_route_table.private_a` / `private_b` | `...-rt-private-a` / `...-rt-private-b` |
| `aws_vpc_endpoint.s3` | `...-vpce-s3` |
| `aws_security_group.upload_lambda` / `crop_lambda` | `...-sg-upload-lambda` / `...-sg-crop-lambda` |
| `aws_s3_bucket.images` | `image-processor-<entorno>-images-<sufijo>` |
| `aws_sqs_queue.main` / `aws_sqs_queue.dlq` | `...-image-queue` / `...-image-dlq` |
| `aws_iam_role.upload_lambda` / `crop_lambda` | `...-upload-lambda-role` / `...-crop-lambda-role` |
| `aws_iam_role_policy.upload_s3` / `crop_permissions` | Permisos mínimos de S3 y SQS de cada lambda |
| `aws_cloudwatch_log_group.upload` / `crop` | `/aws/lambda/<nombre-de-la-funcion>` |
| `aws_lambda_function.upload` / `crop` | `image-processor-<entorno>-upload` / `...-crop` |
| `aws_lambda_event_source_mapping.crop_sqs` | Conexión de la cola SQS con crop-lambda |

---

## 4. Variables y valores por entorno

Se declaran todas en `IaC/variables.tf`. Las que no tienen valor por defecto obligan a pasar el `.tfvars` correspondiente:

| Variable | Defecto | Detalle |
|---|---|---|
| `aws_region` | `us-east-1` | Región del despliegue |
| `project_name` | `image-processor` | Base para todos los nombres |
| `environment` | *ninguno* | Obligatorio; solo admite `dev`, `qa` o `prod` |
| `lambda_runtime` | `nodejs20.x` | Runtime de las funciones |
| `log_retention_days` | `14` | Retención de los grupos de logs |
| `vpc_cidr` | `10.0.0.0/16` | Cambia por entorno |
| `bucket_force_destroy` | `false` | Cambia por entorno |
| `sqs_max_concurrency` | `5` | Entre `2` y `1000`; cambia por entorno |

Y estos son los valores concretos que usa cada entorno:

| | DEV | QA | PROD |
|---|---|---|---|
| `vpc_cidr` | `10.0.0.0/16` | `10.1.0.0/16` | `10.2.0.0/16` |
| `bucket_force_destroy` | `true` | `true` | `false` |
| `sqs_max_concurrency` | `2` | `3` | `5` |

Las subnets no se escriben a mano: se derivan del `vpc_cidr` con `cidrsubnet` (en DEV resultan `10.0.11.0/24` y `10.0.12.0/24`). Ningún valor propio de un entorno se hardcodea dentro de un recurso; siempre llega por variable o por `local.name_prefix`.

Los archivos que aplican estos valores son `IaC/environments/<entorno>.tfvars`, y su backend asociado `IaC/backend/<entorno>.hcl`.

---

## 5. Locals

| Local | Valor |
|---|---|
| `name_prefix` | `${var.project_name}-${var.environment}` |
| `upload_function_name` | `${local.name_prefix}-upload` |
| `crop_function_name` | `${local.name_prefix}-crop` |
| `bucket_name` | `${local.name_prefix}-images-${random_id.bucket_suffix.hex}` |
| `bucket_arn` | `arn:aws:s3:::${local.bucket_name}` |
| `upload_prefix` | `uploads/` |
| `processed_prefix` | `processed/` |

`private_subnet_ids` no está aquí: se define en `IaC/network.tf`, junto a las subnets que alimenta.

---

## 6. Claves en S3 y límite de subida

Las imágenes subidas quedan en `uploads/{uuid}_{nombre}.{ext}` y las recortadas en `processed/{uuid}_{nombre}_circular.png`. Los nombres van en minúsculas y usan solo letras, números, punto, guion y guion bajo.

El límite de subida es de **4 MB**. La invocación directa de Lambda admite 6 MB, pero el cuerpo viaja en base64 y eso infla el tamaño cerca de un 33 %, por lo que el techo de 10 MB del diagrama original no aplica a esta implementación. Para aceptar archivos más grandes en el futuro, la vía sería usar presigned URLs de S3.
