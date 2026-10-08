const sharp = require("sharp");

sharp.cache(false);
sharp.concurrency(1);

async function cropCircle(inputBuffer, size = 40) {
  const mask = Buffer.from(
    `<svg width="${size}" height="${size}"><circle cx="${size / 2}" cy="${size / 2}" r="${size / 2}" fill="#ffffff"/></svg>`
  );

  return sharp(inputBuffer, { animated: false, limitInputPixels: 50000000 })
    .rotate()
    .resize(size, size, { fit: "cover", position: "centre" })
    .ensureAlpha()
    .composite([{ input: mask, blend: "dest-in" }])
    .png()
    .toBuffer();
}

module.exports = { cropCircle };
