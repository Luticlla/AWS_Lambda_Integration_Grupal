#!/usr/bin/env bash
# Deja en build/ el paquete que upload-lambda necesita para arrancar,
# sin incluir las pruebas.
set -euo pipefail

cd "$(dirname "$0")"

rm -rf build
mkdir build

cp -r index.js src package.json package-lock.json build/

cd build
npm ci --omit=dev

echo "Paquete de upload-lambda listo en build/"
