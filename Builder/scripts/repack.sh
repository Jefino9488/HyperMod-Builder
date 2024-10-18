#!/bin/bash

DEVICE="$1"
WORKSPACE="$2"
EXT4_RW="$3"

RED='\033[1;31m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
GREEN='\033[1;32m'
NC='\033[0m'

# Make tools executable
for tool in fspatch.py contextpatch.py mkfs.erofs mke2fs e2fsdroid vbmeta-disable-verification; do
    sudo chmod +x "${WORKSPACE}/tools/${tool}"
done

img_free() {
    local size_free
    size_free="$(tune2fs -l "${WORKSPACE}/${DEVICE}/images/${1}.img" 2>/dev/null | grep "Free blocks" | awk '{print $3}')"
    if [ -z "$size_free" ]; then
        echo -e "${YELLOW} - ${1}.img free space calculation failed${NC}"
        return
    }

    size_free="$(echo "$size_free / 4096 * 1024 * 1024" | bc)"
    if [[ $size_free -ge 1073741824 ]]; then
        File_Type=$(awk "BEGIN{print $size_free/1073741824}")G
    elif [[ $size_free -ge 1048576 ]]; then
        File_Type=$(awk "BEGIN{print $size_free/1048576}")MB
    elif [[ $size_free -ge 1024 ]]; then
        File_Type=$(awk "BEGIN{print $size_free/1024}")kb
    else
        File_Type=${size_free}b
    fi
    echo -e "${YELLOW} - ${1}.img free space: $File_Type${NC}"
}

repack_partition() {
    local partition=$1
    local inode_multiplier=1.1  # Adjust this value if needed

    echo -e "${RED}- generating: $partition${NC}"

    # Run fspatch and contextpatch
    sudo python3 "$WORKSPACE/tools/fspatch.py" \
        "$WORKSPACE/${DEVICE}/images/$partition" \
        "$WORKSPACE/${DEVICE}/images/config/${partition}_fs_config"

    sudo python3 "$WORKSPACE/tools/contextpatch.py" \
        "$WORKSPACE/${DEVICE}/images/$partition" \
        "$WORKSPACE/${DEVICE}/images/config/${partition}_file_contexts"

    # Calculate inodes based on file count
    local file_count
    file_count=$(find "$WORKSPACE/${DEVICE}/images/$partition" -type f | wc -l)
    local inode_count
    inode_count=$(echo "$file_count * $inode_multiplier" | bc | cut -d. -f1)

    # Calculate partition size
    local partition_size
    partition_size=$(du -sb "$WORKSPACE/${DEVICE}/images/$partition" | awk '{print int($1 * 1.2)}')

    if [ "$EXT4_RW" == "true" ]; then
        # Create ext4 image
        "${WORKSPACE}/tools/mke2fs" -O ^has_journal -L "$partition" \
            -I 256 -N "$inode_count" -M "/$partition" \
            -m 0 -b 4096 "$WORKSPACE/${DEVICE}/images/${partition}.img" "$partition_size"

        sudo "${WORKSPACE}/tools/e2fsdroid" \
            -e \
            -T 1230768000 \
            -C "$WORKSPACE/${DEVICE}/images/config/${partition}_fs_config" \
            -S "$WORKSPACE/${DEVICE}/images/config/${partition}_file_contexts" \
            -f "$WORKSPACE/${DEVICE}/images/$partition" \
            -a "/$partition" \
            "$WORKSPACE/${DEVICE}/images/${partition}.img"

        "${WORKSPACE}/tools/resize2fs" -M "$WORKSPACE/${DEVICE}/images/${partition}.img"
    else
        # Create EROFS image
        sudo "${WORKSPACE}/tools/mkfs.erofs" --quiet -zlz4hc,9 \
            -T 1230768000 \
            --mount-point "/$partition" \
            --fs-config-file "$WORKSPACE/${DEVICE}/images/config/${partition}_fs_config" \
            --file-contexts "$WORKSPACE/${DEVICE}/images/config/${partition}_file_contexts" \
            "$WORKSPACE/${DEVICE}/images/${partition}.img" \
            "$WORKSPACE/${DEVICE}/images/$partition"
    fi

    if [ -f "$WORKSPACE/${DEVICE}/images/${partition}.img" ]; then
        img_free "$partition"
        sudo rm -rf "$WORKSPACE/${DEVICE}/images/$partition"
    else
        echo -e "${RED}Failed to create ${partition}.img${NC}"
        return 1
    fi
}

# Main execution
echo -e "${YELLOW}- repacking images${NC}"

for partition in vendor product system system_ext; do
    repack_partition "$partition" || exit 1
done

# Rest of the script remains the same...


move_images_and_calculate_sizes() {
    echo -e "${YELLOW}- Moving images to super_maker and calculating sizes"
    local IMAGE
    for IMAGE in vendor product system system_ext odm_dlkm odm vendor_dlkm mi_ext; do
        if [ -f "${WORKSPACE}/${DEVICE}/images/$IMAGE.img" ]; then
            mv -t "${WORKSPACE}/super_maker" "${WORKSPACE}/${DEVICE}/images/$IMAGE.img" || exit
            eval "${IMAGE}_size=\$(du -b \"${WORKSPACE}/super_maker/$IMAGE.img\" | awk '{print \$1}')"
            echo -e "${BLUE}- Moved $IMAGE"
        fi
    done

    # Calculate total size of all images
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