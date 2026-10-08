const { PutObjectCommand } = require("@aws-sdk/client-s3");
const { parseRequest } = require("./parse");
const { detectImageType, sanitizeName, buildKey } = require("./validate");
const { HttpError, unsupportedMediaType } = require("./errors");

function respond(statusCode, body) {
  return {
    statusCode,
    headers: { "content-type": "application/json" },
    body: JSON.stringify(body),
  };
}

function createHandler({ s3, config, uuid }) {
  return async function handler(event) {
    try {
      const { buffer, filename } = await parseRequest(event, { maxBytes: config.maxBytes });

      const type = detectImageType(buffer);
      if (!type) throw unsupportedMediaType("Solo se permiten imágenes jpg, png, gif o webp");

      const key = buildKey({
        prefix: config.prefix,
        id: uuid(),
        name: sanitizeName(filename),
        ext: type.ext,
      });

      await s3.send(new PutObjectCommand({
        Bucket: config.bucket,
        Key: key,
        Body: buffer,
        ContentType: type.mime,
        ServerSideEncryption: "AES256",
      }));

      return respond(201, { message: "Imagen recibida", key, bucket: config.bucket });
    } catch (err) {
      if (err instanceof HttpError) {
        return respond(err.statusCode, { error: { code: err.code, message: err.message } });
      }
      console.error("Error al guardar la imagen:", err.name, err.message);
      return respond(500, { error: { code: "INTERNAL_ERROR", message: "No se pudo guardar la imagen" } });
    }
  };
}

module.exports = { createHandler };
