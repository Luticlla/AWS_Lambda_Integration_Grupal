// Funciones para validar la imagen, sanitize o limpiar entradas
const path = require("path");

function detectImageType(buffer) {

  if (!buffer || buffer.length < 12) return null;
  const head = buffer.toString("ascii", 0, 6);
  const rear = buffer.toString("ascii", 8, 12);

  if (buffer.subarray(0, 3).equals(Buffer.from([0xff, 0xd8, 0xff]))) {
    return { mime: "image/jpeg", ext: "jpg" };
  }

  if (buffer.subarray(0, 8).equals(Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]))) {
    return { mime: "image/png", ext: "png" };
  }

  if (head === "GIF87a" || head === "GIF89a") {
    return { mime: "image/gif", ext: "gif" };
  }

  if (head.slice(0, 4) === "RIFF" && rear === "WEBP") {
    return { mime: "image/webp", ext: "webp" };
  }

  return null;
}

function sanitizeName(filename) {
  let name = path.parse(filename || "").name; 
  name = name.toLowerCase();
  name = name.replace(/[^a-z0-9._-]/g, "-"); 
  name = name.replace(/-+/g, "-");           
  name = name.slice(0, 60);                 
  name = name.replace(/^-+|-+$/g, "");       
  return name || "imagen";
}

function buildKey({ prefix, id, name, ext }) {
  return `${prefix}${id}_${name}.${ext}`;
}

module.exports = { detectImageType, sanitizeName, buildKey };