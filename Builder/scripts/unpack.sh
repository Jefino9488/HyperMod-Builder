#!/bin/bash

# Remove unwanted packages
sudo apt-get remove -y firefox zstd

# Install required packages
sudo apt-get install -y python3 aria2

# Parameters
URL="$1"
DEVICE="$2"
WORKSPACE="$3"

# Colors for output
RED='\033[1;31m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
GREEN='\033[1;32m'

# Set Permissions and create directories
sudo chmod -R +rwx "${WORKSPACE}/tools"

# Grant execution permissions to the tools
sudo chmod +x "${WORKSPACE}/tools/payload-dumper-go"
sudo chmod +x "${WORKSPACE}/tools/extract.erofs"

# Download package
echo -e "${BLUE}- Downloading package"
aria2c -x16 -j"$(nproc)" -U "Mozilla/5.0" -d "${WORKSPACE}" -o "recovery_rom.zip" "${URL}"

# Extract payload.bin
echo -e "${YELLOW}- extracting payload.bin"
recovery_zip="recovery_rom.zip"
7z x "${WORKSPACE}/${recovery_zip}" -o"${WORKSPACE}/${DEVICE}" payload.bin || true
rm -rf "${WORKSPACE:?}/${recovery_zip}"
echo -e "${BLUE}- extracted payload.bin"

# Extract images
echo -e "${YELLOW}- extracting images"
mkdir -p "${WORKSPACE}/${DEVICE}/images"
"${WORKSPACE}/tools/payload-dumper-go" -o "${WORKSPACE}/${DEVICE}/images" "${WORKSPACE}/${DEVICE}/payload.bin" >/dev/null
sudo rm -rf "${WORKSPACE}/${DEVICE}/payload.bin"
echo -e "${BLUE}- extracted images"

# Decompress images
echo -e "${YELLOW}- decompressing images"
for i in product system system_ext vendor; do
  echo -e "${YELLOW}- Decompressing image: $i"
  sudo "${WORKSPACE}/tools/extract.erofs" -s -i "${WORKSPACE}/${DEVICE}/images/$i.img" -x -o "${WORKSPACE}/${DEVICE}/images/"
  rm -rf "${WORKSPACE}/${DEVICE}/images/$i.img"
  echo -e "${BLUE}- decompressed $i"
done