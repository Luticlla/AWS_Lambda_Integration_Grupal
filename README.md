# Procesamiento de Imágenes en AWS

Arquitectura serverless para subir imágenes desde Internet y generar versiones circulares de 40×40 px.

La persona envía una imagen mediante `POST /upload`. El sistema la almacena, la procesa de forma asíncrona y guarda el resultado como PNG con fondo transparente.

## Flujo de datos

| Paso | Origen | Destino | 
|------|--------|---------|
| 1 | Cliente | API Gateway | 
| 2 | API Gateway | ```upload-lambda``` | 
| 3 | ```upload-lambda``` | S3 ```uploads/``` | 
| 4 | S3 ```uploads/``` | SQS |
| 5 | SQS | ```crop-lambda``` | 
| 6 | ```crop-lambda``` | S3 ```uploads/``` |
| 7 | ```crop-lambda``` | S3 ```processed/``` |

Restricciones:

- Tamaño máximo: **4 MB** (`MAX_UPLOAD_BYTES=4194304`). La invocación directa de Lambda admite 6 MB.
- Formatos aceptados: **jpg, png, gif, webp**.
- El nombre se sanea a minúsculas y solo letras, números, punto, guion y guion bajo.


## Componentes eliminados a partir del diagrama original
Antes de la implementacion se vio que componentes eran innecesarios del diagrama original para evitar tanto sobrecostos como inutilidad en el diseño.


- SQS Interface Endpoint tambien se elimino por sobrecosto ya que escala por disponibilidad
- Tambien, bucket uploads/ La regla esta mal implementada. Al no limpiarse, permanecen en el sistema indefinidamente, elevando los costos de almacenamiento sin límite, ademas no se necesita porque solo se usara por 7 dias como maximo y en la implementacion del bucket se planteaba para un mes.
- Eliminamos ambos NAT Gateways porque es inutil al no necesitar internet y hace un sobrecosto.


## Componentes desplegados

Todos los recursos viven en la región `us-east-1` y los nombres siguen el patrón `image-processor-<entorno>-...`.

| Componente | Nombre Terraform |
|---|---|---|
| VPC | `aws_vpc.main` |
| Endpoint S3 | `aws_vpc_endpoint.s3` |
| Bucket | `aws_s3_bucket.images` |
| Cola principal | `aws_sqs_queue.main` |
| DLQ | `aws_sqs_queue.dlq` |
| upload-lambda | `aws_lambda_function.upload` |
| crop-lambda | `aws_lambda_function.crop` |
| Event Source Mapping | `aws_lambda_event_source_mapping.crop_sqs` |
| Notificación S3 | `aws_s3_bucket_notification.images_to_sqs` |
| Grupos de logs | `aws_cloudwatch_log_group.upload` / `crop` |

## Las Lambdas

Ambas funciones corren en la VPC privada y solo tienen salida por 443 hacia el prefix list del endpoint de S3.

### upload-lambda

- Recibe el evento de API Gateway (payload 2.0), parsea multipart con `busboy` o JSON base64.
- Detecta el tipo real de imagen, sanea el nombre y arma la clave `uploads/{uuid}_{nombre}.{ext}`.
- Sube el archivo a S3 con `ServerSideEncryption: AES256` y responde `201`.
- Código en `IaC/lambdas/upload/` (`src/handler.js`, `src/parse.js`, `src/validate.js`, `src/errors.js`).

### crop-lambda

- Se dispara por SQS; cada mensaje trae el evento de notificación de S3.
- Descarga el original de `uploads/`, lo recorta con `sharp` a 40×40 px usando máscara circular SVG y lo guarda como PNG con alfa en `processed/{nombre}_circular.png`.
- Si un mensaje falla, se reporta como `batchItemFailure` y recién tras 3 intentos cae a la DLQ.
- Código en `IaC/lambdas/crop/` (`src/handler.js`, `src/cropCircle.js`, `src/s3Event.js`, `src/keys.js`).

## Estructura del repositorio

```
.          
├── IaC/
│   ├── backend/          # Backend S3 por entorno (dev.hcl, qa.hcl, prod.hcl)
│   ├── environments/     # tfvars por entorno
│   ├── lambdas/upload/   # Código de upload-lambda
│   ├── lambdas/crop/     # Código de crop-lambda
│   ├── scripts/tf.sh     # Puerta de entrada a Terraform
│   └── *.tf              # Un archivo por responsabilidad
└── README.md
```

## Pruebas

Cada lambda trae sus pruebas con el runner nativo de Node (`node --test`):

```bash
cd IaC/lambdas/upload && npm test
cd IaC/lambdas/crop && npm test
```