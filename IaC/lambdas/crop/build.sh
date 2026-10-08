#!/usr/bin/env bash
# Deja en build/ el paquete de crop-lambda. Como Lambda corre en Amazon Linux,
# se fuerza la instalación de sharp con binarios compilados para Linux x64,
# aunque este script se ejecute en Windows, Mac o cualquier otra distro.
set -euo pipefail

cd "$(dirname "$0")"

rm -rf build
mkdir build

cp -r index.js src package.json package-lock.json build/

cd build
npm install --omit=dev --cpu=x64 --os=linux --libc=glibc

for package in node_modules/@img/sharp-linux-x64 node_modules/@img/sharp-libvips-linux-x64; do
  if [ ! -d "$package" ]; then
    echo "Error: no se encontró $package; sharp no funcionará en Lambda." >&2
    exit 1
  fi
done

echo "Paquete de crop-lambda listo en build/"
