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
    sudo sed -i "/overlay/d" "${WORKSPACE}/${DEVICE}/images/vendor/etc/fstab.default"
    cat "${WORKSPACE}/${DEVICE}/images/vendor/etc/fstab.default"
  fi
  if [ -f "${WORKSPACE}/${DEVICE}/images/vendor/etc/fstab.emmc" ]; then
    sudo sed -i "/overlay/d" "${WORKSPACE}/${DEVICE}/images/vendor/etc/fstab.emmc"
    cat "${WORKSPACE}/${DEVICE}/images/vendor/etc/fstab.emmc"
  fi
fi

ls -alh "${WORKSPACE}/${DEVICE}/images/vendor/etc/"
ls -alh "${WORKSPACE}/${DEVICE}/images/vendor/app/"

echo -e "${BLUE}- modified vendor"