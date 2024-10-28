DEVICE="$1"
WORKSPACE="$2"
EXT4=${3:-false}

RED='\033[1;31m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
GREEN='\033[1;32m'

echo -e "${YELLOW}- modifying Vendor"

unwanted_files=("voicecommand" "IFAAService" "MipayService" "SoterService" "TimeService")
dirs=("images/vendor/etc" "images/vendor/app")

for dir in "${dirs[@]}"; do
  for file in "${unwanted_files[@]}"; do
    appsuite=$(find "${WORKSPACE}/${DEVICE}/${dir}/" -type d -name "*$file")
    if [ -d "$appsuite" ]; then
      echo -e "${YELLOW}- removing: $file from $dir"
      sudo rm -rf "$appsuite"
    fi
  done
done

if [[ "$EXT4" == true ]]; then
  if [ -f "${WORKSPACE}/${DEVICE}/images/vendor/etc/fstab.default" ]; then
    echo -e "${YELLOW}- patching fstab.default"
    sudo sed -i "/overlay/d" "${WORKSPACE}/${DEVICE}/images/vendor/etc/fstab.default"
    echo -e "${GREEN}fstab.default patched"
  fi
  if [ -f "${WORKSPACE}/${DEVICE}/images/vendor/etc/fstab.emmc" ]; then
    echo -e "${YELLOW}- patching fstab.emmc"
    sudo sed -i "/overlay/d" "${WORKSPACE}/${DEVICE}/images/vendor/etc/fstab.emmc"
    echo -e "${GREEN}fstab.emmc patched"
  fi
fi

echo -e "${BLUE}- modified vendor"