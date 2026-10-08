const { S3Client } = require("@aws-sdk/client-s3");
const { randomUUID: uuid } = require("crypto");
const { createHandler } = require("./src/handler");

if (!process.env.S3_BUCKET) {
  throw new Error("Falta la variable de entorno S3_BUCKET");
}

const config = {
  bucket: process.env.S3_BUCKET,
  prefix: process.env.UPLOAD_PREFIX || "uploads/",
  maxBytes: Number(process.env.MAX_UPLOAD_BYTES || 4194304),
};

const s3 = new S3Client({});

exports.handler = createHandler({ s3, config, uuid });
