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
if [[ "$EXT4" == true ]]; then
    img_free() {
      size_free="$(tune2fs -l "$WORKSPACE/${DEVICE}/images/${i}.img" | awk '/Free blocks:/ { print $3 }')"
      size_free="$(echo "$size_free * 4096 / 1024 / 1024" | bc)"
      if [[ $size_free -ge 1048576 ]]; then
        File_Type="$(awk "BEGIN{print $size_free/1048576}") GB"
      elif [[ $size_free -ge 1024 ]]; then
        File_Type="$(awk "BEGIN{print $size_free/1024}") MB"
      else
        File_Type="${size_free} KB"
      fi
      echo -e "\e[1;33m - ${i}.img free: $File_Type \e[0m"
    }

    for i in product system system_ext vendor; do
      eval "${i}_size_orig=$(sudo du -sb "$WORKSPACE/${DEVICE}/images/${i}" | awk '{print $1}')"
      if [[ "$(eval echo "\${${i}_size_orig}")" -lt 104857600 ]]; then
        size=$(echo "$(eval echo "\${${i}_size_orig}") * 15 / 10 / 4096 * 4096" | bc)
      elif [[ "$(eval echo "\${${i}_size_orig}")" -lt 1073741824 ]]; then
        size=$(echo "$(eval echo "\${${i}_size_orig}") * 108 / 100 / 4096 * 4096" | bc)
      else
        size=$(echo "$(eval echo "\${${i}_size_orig}") * 103 / 100 / 4096 * 4096" | bc)
      fi
      eval "${i}_size=$(echo "$size * 4096 / 4096 / 4096" | bc)"
    done

    for i in product system system_ext vendor; do
        if [[ ! -d "$WORKSPACE/${DEVICE}/images/$i" ]]; then
            echo "Directory $WORKSPACE/${DEVICE}/images/$i does not exist, skipping."
            continue
        fi

        eval "${i}_inode=$(sudo wc -l < "$WORKSPACE/${DEVICE}/images/config/${i}_fs_config")"
        eval "${i}_inode=$(echo "$(eval echo "\${${i}_inode}") + 8" | bc)"

        sudo "$WORKSPACE/tools/mke2fs" -O ^has_journal -L $i -I 256 -N "$(eval echo "\${${i}_inode}")" -M /$i -m 0 -t ext4 -b 4096 "$WORKSPACE/${DEVICE}/images/${i}.img" "$(eval echo "\${${i}_size}")" || false
        sudo "$WORKSPACE/tools/e2fsdroid" -e -T 1230768000 -C "$WORKSPACE/${DEVICE}/images/config/${i}_fs_config" -S "$WORKSPACE/${DEVICE}/images/config/${i}_file_contexts" -f "$WORKSPACE/${DEVICE}/images/$i" -a /$i "$WORKSPACE/${DEVICE}/images/$i.img" || false
        resize2fs -f -M "$WORKSPACE/${DEVICE}/images/$i.img"
        eval "${i}_size=$(du -sb "$WORKSPACE/${DEVICE}/images/$i.img" | awk '{print $1}')"
        img_free
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
fi
for IMAGE in vendor product system system_ext odm_dlkm odm vendor_dlkm mi_ext; do
    if [ -f "${WORKSPACE}/${DEVICE}/images/$IMAGE.img" ]; then
        eval "${IMAGE}_size=\$(du -b \"${WORKSPACE}/${DEVICE}/images/$IMAGE.img\" | awk '{print \$1}')"
    fi
done
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

echo -e "${YELLOW}- Downloading and preparing ${DEVICE} fastboot working directory"

mkdir -p "${WORKSPACE}/zip"

LATEST_RELEASE_URL=$(curl -s https://api.github.com/repos/Jefino9488/Fastboot-Flasher/releases/latest | grep "browser_download_url.*zip" | cut -d '"' -f 4)
aria2c -x16 -j"$(nproc)" -U "Mozilla/5.0" -o "fastboot_flasher_latest.zip" "${LATEST_RELEASE_URL}"

unzip -q "fastboot_flasher_latest.zip" -d "${WORKSPACE}/zip"

rm "fastboot_flasher_latest.zip"

echo -e "${BLUE}- Downloaded and prepared ${DEVICE} fastboot working directory"

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
7z a -tzip "${WORKSPACE}/zip/${DEVICE}_fastboot.zip" . || true
echo -e "${GREEN}- ${DEVICE}_fastboot.zip created successfully"