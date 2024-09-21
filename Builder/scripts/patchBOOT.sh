DEVICE="$1"
WORKSPACE="$2"

MAGISK_PATCH="${WORKSPACE}/magisk/boot_patch.sh"

echo -e "${YELLOW}- Patching boot image"
chmod +x "${MAGISK_PATCH}"
${MAGISK_PATCH} "${WORKSPACE}/${DEVICE}/images/boot.img"
if [ $? -ne 0 ]; then
    echo -e "${RED}- Failed to patch boot image"
    exit 1
fi
echo -e "${BLUE}- Patched boot image"