#!/bin/bash

DEVICE="$1"
WORKSPACE="$2"
EXT4=${3:-false}

RED='\033[1;31m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
GREEN='\033[1;32m'

sudo chmod +x "${WORKSPACE}/tools/"*
chmod +x "${WORKSPACE}/tools/e2fsdroid"
file "${WORKSPACE}/tools/e2fsdroid"
echo -e "${YELLOW}- Repacking images"

if grep -q "ro.product.product.manufacturer=QUALCOMM" "$WORKSPACE/${DEVICE}/images/product/etc/build.prop"; then
    group_name="qti_dynamic_partitions"
    echo -e "${GREEN}- The device is manufactured by QUALCOMM"
else
    group_name="main"
    echo -e "${GREEN}- The device is not manufactured by QUALCOMM"
fi
if [ "$EXT4" = true ]; then
    for i in product system system_ext vendor; do
        if [ ! -d "$WORKSPACE/${DEVICE}/images/$i" ]; then
            echo "Directory $WORKSPACE/${DEVICE}/images/$i does not exist, skipping."
            continue
        fi

        fs_config="$WORKSPACE/${DEVICE}/images/${i}_fs_config"
        file_contexts="$WORKSPACE/${DEVICE}/images/${i}_file_contexts"

        sudo "$WORKSPACE/tools/e2fsdroid" -T 0 -S "$file_contexts" -C "$fs_config" -a "/$i" -s "$WORKSPACE/${DEVICE}/images/$i.img" "$WORKSPACE/${DEVICE}/images/$i"

        if [ $? -eq 0 ]; then
            echo "$i image created successfully with e2fsdroid."
        else
            echo "Failed to create $i image with e2fsdroid."
        fi

        sudo rm -rf "$WORKSPACE/${DEVICE}/images/$i"
    done

    df -h "$WORKSPACE/${DEVICE}/images"
    ls -l "$WORKSPACE/${DEVICE}/images"
else
    for partition in product system system_ext vendor; do
        sudo python3 "$WORKSPACE/tools/fspatch.py" "$WORKSPACE/${DEVICE}/images/$partition" "$WORKSPACE/${DEVICE}/images/config/${partition}_fs_config"
        sudo python3 "$WORKSPACE/tools/contextpatch.py" "$WORKSPACE/${DEVICE}/images/$partition" "$WORKSPACE/${DEVICE}/images/config/${partition}_file_contexts"
        echo -e "${GREEN}- Creating $partition in erofs format"
        sudo "${WORKSPACE}/tools/mkfs.erofs" --quiet -zlz4hc,9 -T 1230768000 \
            --mount-point /"$partition" \
            --fs-config-file "$WORKSPACE/${DEVICE}/images/config/${partition}_fs_config" \
            --file-contexts "$WORKSPACE/${DEVICE}/images/config/${partition}_file_contexts" \
            "$WORKSPACE/${DEVICE}/images/$partition.img" "$WORKSPACE/${DEVICE}/images/$partition"
        sudo rm -rf "$WORKSPACE/${DEVICE}/images/$partition"
    done
        for IMAGE in vendor product system system_ext odm_dlkm odm vendor_dlkm mi_ext; do
        if [ -f "${WORKSPACE}/${DEVICE}/images/$IMAGE.img" ]; then
            eval "${IMAGE}_size=\$(du -b \"${WORKSPACE}/${DEVICE}/images/$IMAGE.img\" | awk '{print \$1}')"
        fi
    done
fi

sudo rm -rf "${WORKSPACE}/${DEVICE}/images/config"
echo -e "${GREEN}- All partitions repacked"

total_size=$(( ${system_size:-0} + ${system_ext_size:-0} + ${product_size:-0} + ${vendor_size:-0} + ${odm_size:-0} + ${odm_dlkm_size:-0} + ${vendor_dlkm_size:-0} + ${mi_ext_size:-0} ))
block_size=4096
case ${DEVICE} in
	#13 13Pro 13Ultra
	FUXI | NUWA | ISHTAR) super_size=9663676416;;
	#RedmiNote12Turbo | K60Pro | MIXFold
	MARBLE | SOCRATES | BABYLON) super_size=9663676416;;
	#Redmi Note 12 5G
	SUNSTONE) super_size=9122611200;;
	#PAD6Max
	YUDI) super_size=11811160064;;
	#Others
	*) super_size=9126805504;;
esac
lpargs="--metadata-size 65536 --super-name super --block-size $block_size --metadata-slots 3 --device super:${super_size} --group ${group_name}_a:${super_size} --group ${group_name}_b:${super_size}"
for pname in system system_ext product vendor odm_dlkm odm vendor_dlkm mi_ext; do
    if [ -f "${WORKSPACE}/${DEVICE}/images/${pname}.img" ]; then
        eval subsize="\$${pname}_size"
        echo -e "${GREEN}Super sub-partition [$pname] size: [$subsize]"
        lpargs="$lpargs --partition ${pname}_a:readonly:${subsize}:${group_name}_a --image ${pname}_a=${WORKSPACE}/${DEVICE}/images/${pname}.img --partition ${pname}_b:readonly:0:${group_name}_b"
    fi
done
"${WORKSPACE}/tools/lpmake" $lpargs --virtual-ab --sparse --output "${WORKSPACE}/${DEVICE}/images/super.img" || exit

for pname in system system_ext product vendor odm_dlkm odm vendor_dlkm mi_ext; do
    if [ -f "${WORKSPACE}/${DEVICE}/images/${pname}.img" ]; then
        rm -rf "${WORKSPACE}/${DEVICE}/images/${pname}.img"
    fi
done

prepare_device_directory() {
    echo -e "${YELLOW}- Downloading and preparing ${DEVICE} fastboot working directory"

    LATEST_RELEASE_URL=$(curl -s https://api.github.com/repos/Jefino9488/Fastboot-Flasher/releases/latest | grep "browser_download_url.*zip" | cut -d '"' -f 4)
    aria2c -x16 -j"$(nproc)" -U "Mozilla/5.0" -o "fastboot_flasher_latest.zip" "${LATEST_RELEASE_URL}"

    unzip -q "fastboot_flasher_latest.zip" -d "${WORKSPACE}/zip"

    rm "fastboot_flasher_latest.zip"

    echo -e "${BLUE}- Downloaded and prepared ${DEVICE} fastboot working directory"
}

final_steps() {
    mv "${WORKSPACE}/magisk/new-boot.img" "${WORKSPACE}/${DEVICE}/images/magisk_boot.img"

    echo -e "${YELLOW}- Patching vbmeta"
    if [ -f "${WORKSPACE}/${DEVICE}/images/vbmeta.img" ]; then
        sudo "${WORKSPACE}/tools/vbmeta-disable-verification" "${WORKSPACE}/${DEVICE}/images/vbmeta.img"
    fi
    if [ -f "${WORKSPACE}/${DEVICE}/images/vbmeta_system.img" ]; then
        sudo "${WORKSPACE}/tools/vbmeta-disable-verification" "${WORKSPACE}/${DEVICE}/images/vbmeta_system.img"
    fi
    if [ -f "${WORKSPACE}/${DEVICE}/images/vbmeta_vendor.img" ]; then
        sudo "${WORKSPACE}/tools/vbmeta-disable-verification" "${WORKSPACE}/${DEVICE}/images/vbmeta_vendor.img"
    fi

    mkdir -p "${WORKSPACE}/zip/images"

    cp "${WORKSPACE}/${DEVICE}/images"/* "${WORKSPACE}/zip/images/"

    cd "${WORKSPACE}/zip" || exit

    echo -e "${YELLOW}- Zipping fastboot files"
    zip -r "${WORKSPACE}/zip/${DEVICE}_fastboot.zip" . || true
    echo -e "${GREEN}- ${DEVICE}_fastboot.zip created successfully"
}
mkdir -p "${WORKSPACE}/zip"

prepare_device_directory
final_steps
