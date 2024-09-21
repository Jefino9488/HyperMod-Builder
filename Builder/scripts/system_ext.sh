DEVICE="$1"
WORKSPACE="$2"

RED='\033[1;31m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
GREEN='\033[1;32m'

ls -alh "${WORKSPACE}/${DEVICE}/images/system_ext/app/"
ls -alh "${WORKSPACE}/${DEVICE}/images/system_ext/priv-app/"

unwanted_files=("VoiceCommand" "VoiceUnlock" "DuraSpeed")
dirs=("/images/system_ext/priv-app/")

for dir in "${dirs[@]}"; do
  for file in "${unwanted_files[@]}"; do
    appsuite=$(find "${WORKSPACE}/${DEVICE}/${dir}/" -type d -name "*$file")
    if [ -d "$appsuite" ]; then
      echo -e "${YELLOW}- removing: $file from $dir"
      sudo rm -rf "$appsuite"
    fi
  done
done