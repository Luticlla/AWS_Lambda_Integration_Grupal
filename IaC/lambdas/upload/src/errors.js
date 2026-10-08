// Definir errores
class HttpError extends Error {
  constructor(statusCode, code, message) {
    super(message);
    this.name = "HttpError";
    this.statusCode = statusCode;
    this.code = code;
  }
}

function badRequest(msg = "Solicitud no permitada") {
  return new HttpError(400, "BAD_REQUEST", msg);
}

function payloadTooLarge(msg = "Reduzca el tamaño de la imagen") {
  return new HttpError(413, "PAYLOAD_TOO_LARGE", msg);
}

function unsupportedMediaType(msg = "Se permiten imágenes jpg, png, gif o webp") {
  return new HttpError(415, "UNSUPPORTED_MEDIA_TYPE", msg);
}

module.exports = { HttpError, badRequest, payloadTooLarge, unsupportedMediaType };