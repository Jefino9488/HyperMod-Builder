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
sudo chmod +x "${WORKSPACE}/tools/e2fsdroid"
sudo chmod +x "${WORKSPACE}/tools/mkfs.erofs"
sudo chmod +x "${WORKSPACE}/tools/vbmeta-disable-verification"
sudo chmod +x "${WORKSPACE}/tools/make_ext4fs"
sudo chmod +x "${WORKSPACE}/tools/mke2fs"
sudo chmod +x "${WORKSPACE}/tools/resize2fs"
sudo chmod +x "${WORKSPACE}/tools/simg2img"

echo -e "${YELLOW}- Repacking images"
if [ "$EXT4" = true ]; then
    for i in product system system_ext vendor; do
        size_orig=$(sudo du -sb "$WORKSPACE/${DEVICE}/images/$i" | awk '{print $1}')

        # Adjust size based on thresholds and calculate a padded size
        if [[ "$size_orig" -lt "104857600" ]]; then
            size=$(echo "$size_orig * 15 / 10 / 4096 * 4096" | bc)
        elif [[ "$size_orig" -lt "1073741824" ]]; then
            size=$(echo "$size_orig * 108 / 100 / 4096 * 4096" | bc)
        else
            size=$(echo "$size_orig * 103 / 100 / 4096 * 4096" | bc)
        fi

        # Store the calculated size for each partition
        eval "$i"_size=$size
    done

    # Create lost+found directories and set timestamps
    for i in product system system_ext vendor; do
        mkdir -p "$WORKSPACE/${DEVICE}/images/$i/lost+found"
        sudo touch -t 202101010000 "$WORKSPACE/${DEVICE}/images/$i/lost+found"
    done

    # Patch fs_config, file_contexts, and create the ext4 filesystem
    for partition in product system system_ext vendor; do
        # Patch fs_config and file_contexts
        sudo python3 "$WORKSPACE/tools/fspatch.py" "$WORKSPACE/${DEVICE}/images/$partition" "$WORKSPACE/${DEVICE}/images/config/${partition}_fs_config"
        sudo python3 "$WORKSPACE/tools/contextpatch.py" "$WORKSPACE/${DEVICE}/images/$partition" "$WORKSPACE/${DEVICE}/images/config/${partition}_file_contexts"

        # Calculate number of inodes based on fs_config
        partition_inode=$(sudo wc -l < "$WORKSPACE/${DEVICE}/images/config/${partition}_fs_config")
        partition_inode=$(echo "$partition_inode + 8" | bc)  # Adding buffer inodes

        # Generate the ext4 filesystem image using make_ext4fs
        sudo "$WORKSPACE/tools/make_ext4fs" -s -l "$(eval echo \$${partition}_size)" -b 4096 -i "$partition_inode" -I 256 -L "$partition" -a "$partition" -C "$WORKSPACE/${DEVICE}/images/config/${partition}_fs_config" -S "$WORKSPACE/${DEVICE}/images/config/${partition}_file_contexts" "$WORKSPACE/${DEVICE}/images/$partition.img" "$WORKSPACE/${DEVICE}/images/$partition"

    done
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

sudo rm -rf "${WORKSPACE}/${DEVICE}/images/config"
echo -e "${GREEN}- All partitions repacked"

move_images_and_calculate_sizes() {
    mkdir -p "${WORKSPACE}/super_maker"
    echo -e "${YELLOW}- Moving images to super_maker and calculating sizes"

    local IMAGE
    for IMAGE in vendor product system system_ext odm_dlkm odm vendor_dlkm mi_ext; do
        if [ -f "${WORKSPACE}/${DEVICE}/images/$IMAGE.img" ]; then
            mv -t "${WORKSPACE}/super_maker" "${WORKSPACE}/${DEVICE}/images/$IMAGE.img" || exit

            # Use the previously calculated sizes instead of recalculating
            eval "${IMAGE}_size=\$(du -b \"${WORKSPACE}/super_maker/$IMAGE.img\" | awk '{print \$1}')"
            echo -e "${BLUE}- Moved $IMAGE"
        fi
    done

    # Calculate total size of all images using previously calculated sizes
    echo -e "${YELLOW}- Calculating total size of all images"
    super_size=9126805504
    total_size=$((${system_size:-0} + ${system_ext_size:-0} + ${product_size:-0} + ${vendor_size:-0} + ${odm_size:-0} + ${odm_dlkm_size:-0} + ${vendor_dlkm_size:-0} + ${mi_ext_size:-0}))

    echo -e "${BLUE}- Size of all images"
    echo -e "system: ${system_size:-0}"
    echo -e "system_ext: ${system_ext_size:-0}"
    echo -e "product: ${product_size:-0}"
    echo -e "vendor: ${vendor_size:-0}"
    echo -e "odm: ${odm_size:-0}"
    echo -e "odm_dlkm: ${odm_dlkm_size:-0}"
    echo -e "vendor_dlkm: ${vendor_dlkm_size:-0}"
    echo -e "mi_ext: ${mi_ext_size:-0}"
    echo -e "total size: $total_size"
}


create_super_image() {
    echo -e "${YELLOW}- Creating super image"

    total_size=$(( ${system_size:-0} + ${system_ext_size:-0} + ${product_size:-0} + ${vendor_size:-0} + ${odm_size:-0} + ${odm_dlkm_size:-0} + ${vendor_dlkm_size:-0} + ${mi_ext_size:-0} ))
    block_size=4096
    super_size=$(( (total_size + block_size - 1) / block_size * block_size ))

    lpargs="--metadata-size 65536 --super-name super --block-size $block_size --metadata-slots 3 --device super:${super_size} --group main_a:${super_size} --group main_b:${super_size}"

    for pname in system system_ext product vendor odm_dlkm odm vendor_dlkm mi_ext; do
        if [ -f "${WORKSPACE}/super_maker/${pname}.img" ]; then
            eval subsize="\$${pname}_size"
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

    echo -e "${YELLOW}- Patching vbmeta"
    sudo bash "${WORKSPACE}/tools/vbmeta-disable-verification" --image "${WORKSPACE}/${DEVICE}/images/vbmeta.img"

    echo -e "${YELLOW}- Zipping fastboot files"
    cd "${WORKSPACE}/${DEVICE}/images"
    zip -r "${WORKSPACE}/zip/${DEVICE}_fastboot.zip" .
    echo -e "${GREEN}- ${DEVICE}_fastboot.zip created successfully"

    sudo rm -rf "${WORKSPACE}/${DEVICE}/images"
}

main() {
    move_images_and_calculate_sizes
    create_super_image
    move_super_image
    prepare_device_directory
    final_steps
}

main "$@"
