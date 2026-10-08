const { S3Client } = require("@aws-sdk/client-s3");
const { createHandler } = require("./src/handler");

const s3 = new S3Client({});

const config = {
  uploadPrefix: process.env.UPLOAD_PREFIX || "uploads/",
  processedPrefix: process.env.PROCESSED_PREFIX || "processed/",
  size: Number(process.env.CROP_SIZE) || 40,
};

exports.handler = createHandler({ s3, config });
