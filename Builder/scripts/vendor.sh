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
  for fstab_file in "${WORKSPACE}/${DEVICE}/images/vendor/etc/"fstab.*; do
    if [[ "$fstab_file" =~ charger_fw_fstab\.qti|charger_fstab\.qti|fstab\.enableswap ]]; then
      continue
    fi
    if [[ "$fstab_file" =~ fstab\.default|fstab\.emmc|fstab\.mt[0-9]+ ]]; then
      echo -e "${YELLOW}- Patching ${fstab_file}"
      sudo sed -i "/overlay/d" "$fstab_file"
      echo -e "${GREEN}${fstab_file} patched"
    fi
  done
fi


echo -e "${BLUE}- modified vendor"