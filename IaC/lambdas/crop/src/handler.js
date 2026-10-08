const { GetObjectCommand, PutObjectCommand } = require("@aws-sdk/client-s3");
const { extractObjects } = require("./s3Event");
const { buildProcessedKey } = require("./keys");
const { cropCircle } = require("./cropCircle");

function createHandler({ s3, config }) {
  const { uploadPrefix, processedPrefix, size } = config;

  return async function handler(event) {
    const batchItemFailures = [];

    for (const record of event.Records) {
      let currentKey;
      try {
        const objects = extractObjects(record.body, { uploadPrefix });

        for (const { bucket, key } of objects) {
          currentKey = key;
          const startedAt = Date.now();

          const response = await s3.send(new GetObjectCommand({ Bucket: bucket, Key: key }));
          const input = Buffer.from(await response.Body.transformToByteArray());
          const output = await cropCircle(input, size);

          const processedKey = buildProcessedKey(key, { uploadPrefix, processedPrefix });
          await s3.send(
            new PutObjectCommand({
              Bucket: bucket,
              Key: processedKey,
              Body: output,
              ContentType: "image/png",
              ServerSideEncryption: "AES256",
            })
          );

          console.log(`Procesado ${key} -> ${processedKey} en ${Date.now() - startedAt} ms`);
        }
      } catch (error) {
        console.error(
          `Error en el mensaje ${record.messageId} (objeto: ${currentKey ?? "desconocido"}): ${error.message}`
        );
        batchItemFailures.push({ itemIdentifier: record.messageId });
      }
    }

    return { batchItemFailures };
  };
}

module.exports = { createHandler };
