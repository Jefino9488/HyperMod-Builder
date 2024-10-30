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

#if [ "$REGION" == "CN" ]; then
#  unwanted_files=("MIUIPersonalAssistantPhoneMIUI15" "MIUISecurityCenter" "MIUIPackageInstaller" "GmsCore" "MIUIThemeManager" "AnalyticsCore" "GooglePlayServicesUpdater" "PaymentService" "MIpay" "XiaoaiEdgeEngine" "MIUIAiasstService" "MIUIGuardProvider" "MINextpay" "MiGameService_MTK" "AiAsstVision" "CarWith" "MIUISuperMarket" "MIUIgreenguard" "SogouInput" "VoiceAssistAndroidT" "XiaoaiRecommendation" "Updater" "CatchLog" "MIUIBrowser" "MIUIMusicT" "MIUIVideo" "MiGameCenterSDKService" "VoiceTrigger" "MIUIQuickSearchBox" "MIUIMiDrive" "MIUIDuokanReader" "MIUIHuanji" "MIUIGameCenter" "Health" "MIGalleryLockscreen-MIUI15" "MIMediaEditor" "MIUICalculator" "MIUICleanMaster" "MIUICompass" "MIUIEmail" "MIUINewHome_Removable" "MIUINotes" "MIUIScreenRecorderLite" "MIUISoundRecorderTargetSdk30" "MIUIVipAccount" "MIUIVirtualSim" "MIUIXiaoAiSpeechEngine" "MIUIYoupin" "MiRadio" "MiShop" "MiuiScanner" "SmartHome" "ThirdAppAssistant" "XMRemoteController" "com.iflytek.inputmethod.miui" "wps-lite" "BaiduIME")
#else
#  unwanted_files=("Drive" "GlobalWPSLITE" "MIDrop" "MIMediaEditorGlobal" "MISTORE_OVERSEA" "MIUICalculatorGlobal" "MIUICompassGlobal" "MIUINotes" "MIUIScreenRecorderLiteGlobal" "MIUISoundRecorderTargetSdk30Global" "MIUIWeatherGlobal" "Meet" "MiCare" "MiGalleryLockScreenGlobal" "MicrosoftOneDrive" "MiuiScanner" "Opera" "Photos" "SmartHome" "Videos" "XMRemoteController" "YTMusic" "Gmail2" "MIRadioGlobal" "MIUIHealthGlobal" "MIUIMiPicks" "Maps" "PlayAutoInstallStubApp" "Updater" "YouTube" "AndroidAutoStub" "MIUIMusicGlobal" "Velvet" "")
#fi

#dirs=("images/product/app" "images/product/priv-app" "images/product/data-app")
#for dir in "${dirs[@]}"; do
#    echo "Searching in directory: ${WORKSPACE}/${DEVICE}/${dir}"
#    find "${WORKSPACE}/${DEVICE}/${dir}/" -type f -name "*.apk" | while read -r apk; do
#        PACKAGE_NAME=$(aapt dump badging "$apk" | grep package:\ name | awk -F"'" '{print $2}')
#        echo "Package found: $PACKAGE_NAME in $apk"
#    done
#done
#for dir in "${dirs[@]}"; do
#  for file in "${unwanted_files[@]}"; do
#    appsuite=$(find "${WORKSPACE}/${DEVICE}/${dir}/" -type d -name "*$file")
#    if [ -d "$appsuite" ]; then
#      echo -e "${YELLOW}- removing: $file from $dir"
#      sudo rm -rf "$appsuite"
#    fi
#  done
#done
#
if [ "$REGION" == "CN" ]; then
  mkdir -p "${WORKSPACE}/${DEVICE}/images/product/priv-app/Gboard"
  mv "${WORKSPACE}/Builder/apps/gboard.apk" "${WORKSPACE}/${DEVICE}/images/product/priv-app/Gboard/"
  mv "${WORKSPACE}/Builder/permisions/privapp_whitelist_com.google.android.inputmethod.latin.xml" "${WORKSPACE}/${DEVICE}/images/product/etc/permissions/"
  echo -e "${GREEN}Gboard added"
#  mkdir -p "${WORKSPACE}/${DEVICE}/images/product/priv-app/GooglePlayStore"
#  mv "${WORKSPACE}/Builder/apps/playstore.apk" "${WORKSPACE}/${DEVICE}/images/product/priv-app/GooglePlayStore/"
#  echo -e "${GREEN}Playstore Updated"
#  mkdir -p "${WORKSPACE}/${DEVICE}/images/product/priv-app/GmsCore"
#  mv "${WORKSPACE}/Builder/apps/gms.apk" "${WORKSPACE}/${DEVICE}/images/product/priv-app/GmsCore/"
#  echo -e "${GREEN}GooglePlayServices Updated"
#  mkdir "${WORKSPACE}/${DEVICE}/images/product/priv-app/MiuiHome/"
#  mv "${WORKSPACE}/Builder/apps/com.miui.home.apk" "${WORKSPACE}/${DEVICE}/images/product/priv-app/MiuiHome/"
#  echo -e "${GREEN}MiuiHome added"
#  mkdir -p "${WORKSPACE}/${DEVICE}/images/product/priv-app/MIUIPackageInstaller"
#  mv "${WORKSPACE}/Builder/apps/MIUIPackageInstaller.apk" "${WORKSPACE}/${DEVICE}/images/product/priv-app/MIUIPackageInstaller/"
#  mv "${WORKSPACE}/Builder/permisions/privapp_whitelist_com.miui.packageinstaller.xml" "${WORKSPACE}/${DEVICE}/images/product/etc/permissions/"
#  echo -e "${GREEN}MIUIPackageInstaller added"
#  mkdir "${WORKSPACE}/${DEVICE}/images/product/priv-app/MIUISecurityCenter/"
#  mv "${WORKSPACE}/Builder/apps/com.miui.securitycenter.apk" "${WORKSPACE}/${DEVICE}/images/product/priv-app/MIUISecurityCenter/"
#  echo -e "${GREEN}MIUISecurityCenter added"
#  mkdir "${WORKSPACE}/${DEVICE}/images/product/app/MIUIThemeManager"
#  mv "${WORKSPACE}/Builder/apps/MIUIThemeManager.apk" "${WORKSPACE}/${DEVICE}/images/product/app/MIUIThemeManager/"
#  echo -e "${GREEN}MIUIThemeManager added"
#  mkdir -p "${WORKSPACE}/${DEVICE}/images/product/priv-app/MIUIPersonalAssistant"
#  mv "${WORKSPACE}/Builder/apps/MIUIPersonalAssistant.apk" "${WORKSPACE}/${DEVICE}/images/product/priv-app/MIUIPersonalAssistant/"
#  mv "${WORKSPACE}/Builder/permisions/privapp_whitelist_com.miui.personalassistant.xml" "${WORKSPACE}/${DEVICE}/images/product/etc/permissions/"com.android.quicksearchbox
#  echo -e "${GREEN}MIUIPersonalAssistant added"
fi

unwanted_apps=("cn.wps.moffice_eng.xiaomi.lite" "com.mfashiongallery.emag" "com.miui.huanji" "com.miui.weather2" "com.miui.thirdappassistant" "com.android.email" "com.android.soundrecorder" "com.mi.health" "com.baidu.input_mi" "com.duokan.phone.remotecontroller" "com.xiaomi.vipaccount" "com.miui.virtualsim" "com.xiaomi.mibrain.speech" "com.miui.fm" "com.xiaomi.youpin" "com.miui.newhome" "com.xiaomi.gamecenter" "com.miui.newmidrive" "com.miui.notes" "com.xiaomi.scanner" "com.xiaomi.smarthome" "com.miui.screenrecorder" "com.miui.mediaeditor" "com.miui.compass" "com.miui.cleanmaster" "com.iflytek.inputmethod.miui" "com.xiaomi.shop" "com.duokan.reader" "com.miui.calculator" "com.miui.player" "com.android.browser" "com.miui.yellowpage" "com.android.quicksearchbox" "com.miui.voicetrigger" "com.miui.video" "com.xiaomi.gamecenter.sdk.service" "com.mipay.wallet" "com.xiaomi.aiasst.vision" "com.miui.greenguard" "com.xiaomi.migameservice" "com.xiaomi.payment" "com.xiaomi.aiasst.service" "com.xiaomi.market" "com.unionpay.tsmservice.mi" "com.miui.carlink" "com.miui.nextpay")
replace_apps=("com.miui.home" "com.miui.securitycenter" "com.miui.packageinstaller" "com.android.vending" "com.google.android.gms")

dirs=("images/product/app" "images/product/priv-app" "images/product/data-app")
REPLACEMENT_DIR="${WORKSPACE}/Builder/apps"

for dir in "${dirs[@]}"; do
    echo -e "${BLUE}Searching in directory: ${WORKSPACE}/${DEVICE}/${dir}${NC}"
    find "${WORKSPACE}/${DEVICE}/${dir}/" -type f -name "*.apk" | while read -r apk; do
        PACKAGE_NAME=$(aapt dump badging "$apk" | grep package:\ name | awk -F"'" '{print $2}')
        echo -e "${GREEN}Package found: $PACKAGE_NAME in $apk${NC}"

        is_unwanted=false
        for unwanted in "${unwanted_apps[@]}"; do
            if [[ "$PACKAGE_NAME" == "$unwanted" ]]; then
                is_unwanted=true
                break
            fi
        done

        if [[ "$is_unwanted" == true ]]; then
            echo -e "${RED}Deleting unwanted app $PACKAGE_NAME and its directory: $apk${NC}"
            rm -rf "$(dirname "$apk")"
            continue
        fi

        is_replaceable=false
        for replaceable in "${replace_apps[@]}"; do
            if [[ "$PACKAGE_NAME" == "$replaceable" ]]; then
                is_replaceable=true
                break
            fi
        done

        if [[ "$is_replaceable" == true ]]; then
            REPLACEMENT_APK="${REPLACEMENT_DIR}/${PACKAGE_NAME}.apk"
            if [[ -f "$REPLACEMENT_APK" ]]; then
                echo -e "${YELLOW}Replacing $apk with $REPLACEMENT_APK${NC}"
                cp "$REPLACEMENT_APK" "$apk"
                mv "$apk" "$(dirname "$apk")/$(basename "$apk")"
                echo -e "${GREEN}Successfully replaced and renamed to: $(basename "$apk")${NC}"
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
