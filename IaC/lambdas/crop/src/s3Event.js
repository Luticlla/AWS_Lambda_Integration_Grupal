function extractObjects(sqsRecordBody, { uploadPrefix }) {
  let message;
  try {
    message = JSON.parse(sqsRecordBody);
  } catch (error) {
    throw new Error(`El body del mensaje de SQS no es un JSON válido: ${error.message}`);
  }

  if (!message || !Array.isArray(message.Records)) {
    return [];
  }

  return message.Records
    .map((record) => ({
      bucket: record.s3.bucket.name,
      key: decodeS3Key(record.s3.object.key),
    }))
    .filter(({ key }) => key.startsWith(uploadPrefix));
}

function decodeS3Key(key) {
  try {
    return decodeURIComponent(key.replace(/\+/g, " "));
  } catch (error) {
    throw new Error(`No se pudo decodificar la clave del objeto "${key}": ${error.message}`);
  }
}

module.exports = { extractObjects };
