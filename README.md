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

## Componentes eliminados a partir del diagrama original
Antes de la implementacion se vio que componentes eran innecesarios del diagrama original para evitar tanto sobrecostos como inutilidad en el diseño.


- SQS Interface Endpoint tambien se elimino por sobrecosto ya que escala por disponibilidad
- Tambien, bucket uploads/ La regla esta mal implementada. Al no limpiarse, permanecen en el sistema indefinidamente, elevando los costos de almacenamiento sin límite, ademas no se necesita porque solo se usara por 7 dias como maximo y en la implementacion del bucket se planteaba para un mes.
- Eliminamos ambos NAT Gateways porque es inutil al no necesitar internet y hace un sobrecosto.


