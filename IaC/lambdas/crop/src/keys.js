function buildProcessedKey(uploadKey, { uploadPrefix, processedPrefix }) {
  const relativeKey = uploadKey.startsWith(uploadPrefix)
    ? uploadKey.slice(uploadPrefix.length)
    : uploadKey;

  const lastSlash = relativeKey.lastIndexOf("/");
  const lastDot = relativeKey.lastIndexOf(".");
  const base = lastDot > lastSlash ? relativeKey.slice(0, lastDot) : relativeKey;

  return `${processedPrefix}${base}_circular.png`;
}

module.exports = { buildProcessedKey };
