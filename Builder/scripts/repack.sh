#!/bin/bash

DEVICE="$1"
WORKSPACE="$2"
EXT4=${3:-false}

RED='\033[1;31m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
GREEN='\033[1;32m'

sudo chmod +x "${WORKSPACE}/tools/fspatch.py"
sudo chmod +x "${WORKSPACE}/tools/contextpatch.py"
sudo chmod +x "${WORKSPACE}/tools/mkfs.erofs"
sudo chmod +x "${WORKSPACE}/tools/vbmeta-disable-verification"
sudo chmod +x "${WORKSPACE}/tools/make_ext4fs"
sudo chmod +x "${WORKSPACE}/tools/mke2fs"
sudo chmod +x "${WORKSPACE}/tools/resize2fs"
sudo chmod +x "${WORKSPACE}/tools/simg2img"

echo -e "${YELLOW}- Repacking images"
partitions=("vendor" "product" "system" "system_ext")
for partition in "${partitions[@]}"; do
  echo -e "${RED}- Generating: $partition"
  if [ "$EXT4" = true ]; then
    echo -e "${GREEN}- Creating $partition in ext4 format"
    sudo "${WORKSPACE}/tools/make_ext4fs" -s -l 4096M -a "$partition" "$WORKSPACE"/"${DEVICE}"/images/$partition.img "$WORKSPACE"/"${DEVICE}"/images/$partition || \
    sudo "${WORKSPACE}/tools/mke2fs" -t ext4 -d "$WORKSPACE"/"${DEVICE}"/images/$partition "$WORKSPACE"/"${DEVICE}"/images/$partition.img
  else
    echo -e "${GREEN}- Creating $partition in erofs format"
    sudo python3 "$WORKSPACE"/tools/fspatch.py "$WORKSPACE"/"${DEVICE}"/images/$partition "$WORKSPACE"/"${DEVICE}"/images/config/"$partition"_fs_config
    sudo python3 "$WORKSPACE"/tools/contextpatch.py "$WORKSPACE"/${DEVICE}/images/$partition "$WORKSPACE"/"${DEVICE}"/images/config/"$partition"_file_contexts
    sudo "${WORKSPACE}/tools/mkfs.erofs" --quiet -zlz4hc,9 -T 1230768000 --mount-point /"$partition" --fs-config-file "$WORKSPACE"/"${DEVICE}"/images/config/"$partition"_fs_config --file-contexts "$WORKSPACE"/"${DEVICE}"/images/config/"$partition"_file_contexts "$WORKSPACE"/"${DEVICE}"/images/$partition.img "$WORKSPACE"/"${DEVICE}"/images/$partition
  fi

  if [ "$EXT4" = false ]; then
    echo -e "${GREEN}- Converting $partition to sparse format"
    sudo "${WORKSPACE}/tools/simg2img" "$WORKSPACE"/"${DEVICE}"/images/$partition.img "$WORKSPACE"/"${DEVICE}"/images/$partition.img
  fi

  sudo rm -rf "$WORKSPACE"/"${DEVICE}"/images/$partition
done

sudo rm -rf "${WORKSPACE}/${DEVICE}/images/config"
echo -e "${GREEN}- All partitions repacked"


move_images_and_calculate_sizes() {
    echo -e "${YELLOW}- Moving images to super_maker and calculating sizes"
    local IMAGE
    super_size=0  # Initialize super_size
    for IMAGE in vendor product system system_ext odm_dlkm odm vendor_dlkm mi_ext; do
        if [ -f "${WORKSPACE}/${DEVICE}/images/$IMAGE.img" ]; then
            mv -t "${WORKSPACE}/super_maker" "${WORKSPACE}/${DEVICE}/images/$IMAGE.img" || exit
            eval "${IMAGE}_size=\$(du -b \"${WORKSPACE}/super_maker/$IMAGE.img\" | awk '{print \$1}')"
            super_size=$((super_size + ${!IMAGE}_size))  # Accumulate image sizes
            echo -e "${BLUE}- Moved $IMAGE"
        fi
    done

    echo -e "${BLUE}- Total size of all images: $super_size"  # Output total size
}

create_super_image() {
    echo -e "${YELLOW}- Creating super image"

    lpargs="--metadata-size 65536 --super-name super --block-size 4096 --metadata-slots 3 --device super:${super_size} --group main_a:${super_size} --group main_b:${super_size}"

    for pname in system system_ext product vendor odm_dlkm odm vendor_dlkm mi_ext; do
        if [ -f "${WORKSPACE}/super_maker/${pname}.img" ]; then
            subsize=$(du -sb "${WORKSPACE}/super_maker/${pname}.img" | tr -cd 0-9)
            echo -e "${GREEN}Super sub-partition [$pname] size: [$subsize]"
            lpargs="$lpargs --partition ${pname}_a:readonly:${subsize}:main_a --image ${pname}_a=${WORKSPACE}/super_maker/${pname}.img --partition ${pname}_b:readonly:0:main_b"
        fi
    done

    "${WORKSPACE}/tools/lpmake" $lpargs --virtual-ab --sparse --output "${WORKSPACE}/super_maker/super.img" || exit

    echo -e "${BLUE}- Created super image"
}

move_super_image() {
    echo -e "${YELLOW}- Moving super image"
    mv -t "${WORKSPACE}/${DEVICE}/images" "${WORKSPACE}/super_maker/super.img" || exit
    sudo rm -rf "${WORKSPACE}/super_maker"
    echo -e "${BLUE}- Moved super image"
}

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

    echo -e "${YELLOW}- patching vbmeta"

    sudo "${WORKSPACE}/tools/vbmeta-disable-verification" "${WORKSPACE}/${DEVICE}/images/vbmeta_system.img"
    sudo "${WORKSPACE}/tools/vbmeta-disable-verification" "${WORKSPACE}/${DEVICE}/images/vbmeta.img"
    sudo "${WORKSPACE}/tools/vbmeta-disable-verification" "${WORKSPACE}/${DEVICE}/images/vbmeta_vendor.img"

    mkdir -p "${WORKSPACE}/zip/images"

    cp "${WORKSPACE}/${DEVICE}/images"/* "${WORKSPACE}/zip/images/"

    cd "${WORKSPACE}/zip" || exit

    echo -e "${YELLOW}- Zipping fastboot files"
    zip -r "${WORKSPACE}/zip/${DEVICE}_fastboot.zip" . || true
    echo -e "${GREEN}- ${DEVICE}_fastboot.zip created successfully"
    rm -rf "${WORKSPACE}/zip/images"

    echo -e "${GREEN}- All done!"
}

mkdir -p "${WORKSPACE}/super_maker"
mkdir -p "${WORKSPACE}/zip"

move_images_and_calculate_sizes
create_super_image
move_super_image
prepare_device_directory
final_steps