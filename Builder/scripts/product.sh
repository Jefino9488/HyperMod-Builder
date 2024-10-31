DEVICE="$1"
WORKSPACE="$2"
REGION="$3"

RED='\033[1;31m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
GREEN='\033[1;32m'

wget https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip
mkdir -p "${WORKSPACE}/android-sdk/cmdline-tools"
unzip -q commandlinetools-linux-9477386_latest.zip -d "${WORKSPACE}/android-sdk/cmdline-tools"

yes | "${WORKSPACE}/android-sdk/cmdline-tools/cmdline-tools/bin/sdkmanager" "build-tools;34.0.0"

 AAPT_PATH="${WORKSPACE}/android-sdk/build-tools/34.0.0/aapt"
if ! command -v aapt &> /dev/null; then
    echo "aapt not found, installing..."
    if [ -f "$AAPT_PATH" ]; then
        echo "Found aapt at: $AAPT_PATH"
        export PATH="$PATH:$(dirname "$AAPT_PATH")"
    else
        echo "aapt not found in build-tools directory."
        exit 1
    fi
fi
echo -e "${YELLOW}- modifying product"

if [ "$REGION" == "CN" ]; then
  if [[ -f "${WORKSPACE}/Builder/apps/gboard.apk" ]]; then
    mkdir -p "${WORKSPACE}/${DEVICE}/images/product/priv-app/Gboard"
    mv "${WORKSPACE}/Builder/apps/gboard.apk" "${WORKSPACE}/${DEVICE}/images/product/priv-app/Gboard/"
    mv "${WORKSPACE}/Builder/permisions/"*.xml "${WORKSPACE}/${DEVICE}/images/product/etc/permissions/"
    echo -e "${GREEN}Gboard APK added successfully.${NC}"
  else
    echo -e "${RED}Gboard APK not found in Builder/apps directory.${NC}"
  fi
fi

unwanted_apps=("cn.wps.moffice_eng.xiaomi.lite" "com.mfashiongallery.emag" "com.miui.huanji" "com.miui.thirdappassistant" "com.android.email" "com.android.soundrecorder" "com.mi.health" "com.baidu.input_mi" "com.duokan.phone.remotecontroller" "com.xiaomi.vipaccount" "com.miui.virtualsim" "com.xiaomi.mibrain.speech" "com.xiaomi.youpin" "com.miui.newhome" "com.xiaomi.gamecenter" "com.miui.newmidrive" "com.miui.notes" "com.xiaomi.scanner" "com.xiaomi.smarthome" "com.miui.screenrecorder" "com.miui.mediaeditor" "com.miui.compass" "com.iflytek.inputmethod.miui" "com.xiaomi.shop" "com.duokan.reader" "com.miui.calculator" "com.miui.player" "com.android.browser" "com.miui.yellowpage" "com.android.quicksearchbox" "com.miui.voicetrigger" "com.miui.video" "com.xiaomi.gamecenter.sdk.service" "com.mipay.wallet" "com.xiaomi.aiasst.vision" "com.miui.greenguard" "com.xiaomi.migameservice" "com.xiaomi.payment" "com.xiaomi.aiasst.service" "com.xiaomi.market" "com.unionpay.tsmservice.mi" "com.miui.carlink" "com.miui.nextpay" "com.miui.voiceassist" "com.xiaomi.aiasst.service" "com.xiaomi.mi_connect_service" "com.android.updater" "com.sohu.inputmethod.sogou.xiaomi")
replace_apps=("com.miui.home" "com.miui.packageinstaller" "com.android.vending" "com.google.android.gms")

dirs=("images/product/app" "images/product/priv-app" "images/product/data-app")
REPLACEMENT_DIR="${WORKSPACE}/Builder/apps"

for dir in "${dirs[@]}"; do
    echo -e "${BLUE}Searching in directory: ${WORKSPACE}/${DEVICE}/${dir}${NC}"
    find "${WORKSPACE}/${DEVICE}/${dir}/" -type f -name "*.apk" | while read -r apk; do
        PACKAGE_NAME=$(aapt dump badging "$apk" | grep package:\ name | awk -F"'" '{print $2}')
        echo -e "${GREEN}Package found: $PACKAGE_NAME in $apk${NC}"

        if [[ ${unwanted_apps[*]} =~ ${PACKAGE_NAME} ]]; then
            echo -e "${RED}Deleting unwanted app $PACKAGE_NAME and its directory: $apk${NC}"
            rm -rf "$(dirname "$apk")"
            continue
        fi

        if [[ ${replace_apps[*]} =~ ${PACKAGE_NAME} ]]; then
            REPLACEMENT_APK="${REPLACEMENT_DIR}/${PACKAGE_NAME}.apk"
            TARGET_DIR="$(dirname "$apk")"
            ORIGINAL_NAME="$(basename "$TARGET_DIR")"

            if [[ -f "$REPLACEMENT_APK" ]]; then
                FILE_SIZE=$(stat -c%s "$REPLACEMENT_APK")

                if (( FILE_SIZE > 1048576 )); then
                    echo -e "${YELLOW}Replacement APK path: $REPLACEMENT_APK (Size: $((FILE_SIZE / 1024)) KB)${NC}"
                    echo -e "${YELLOW}Replacing $apk with $REPLACEMENT_APK and renaming to $ORIGINAL_NAME.apk${NC}"

                    if cp "$REPLACEMENT_APK" "${TARGET_DIR}/${ORIGINAL_NAME}.apk"; then
                        echo -e "${GREEN}Successfully replaced and renamed to: ${TARGET_DIR}/${ORIGINAL_NAME}.apk${NC}"
                    else
                        echo -e "${RED}Failed to copy $REPLACEMENT_APK to ${TARGET_DIR}/${ORIGINAL_NAME}.apk${NC}"
                    fi
                else
                    echo -e "${RED}Replacement APK $REPLACEMENT_APK is less than 1 MB (Size: $((FILE_SIZE / 1024)) KB), skipping...${NC}"
                fi
            else
                echo -e "${RED}Replacement APK not found for $PACKAGE_NAME, skipping...${NC}"
            fi
        fi
    done
done




ls -alh "${WORKSPACE}/${DEVICE}/images/product/data-app/"
ls -alh "${WORKSPACE}/${DEVICE}/images/product/app/"
ls -alh "${WORKSPACE}/${DEVICE}/images/product/etc/permissions/"
ls -alh "${WORKSPACE}/${DEVICE}/images/product/priv-app/"
echo -e "${BLUE}- modified product"
