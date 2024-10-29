DEVICE="$1"
WORKSPACE="$2"
REGION="$3"

RED='\033[1;31m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
GREEN='\033[1;32m'

# Modify
echo -e "${YELLOW}- modifying product"

if [ "$REGION" == "CN" ]; then
  unwanted_files=("MIUIPersonalAssistantPhoneMIUI15" "AnalyticsCore" "GooglePlayServicesUpdater" "PaymentService" "MIpay" "XiaoaiEdgeEngine" "MIUIAiasstService" "MIUIGuardProvider" "MINextpay" "MiGameService_MTK" "AiAsstVision" "CarWith" "MIUISuperMarket" "MIUIgreenguard" "VoiceAssistAndroidT" "XiaoaiRecommendation" "Updater" "CatchLog" "MIUIBrowser" "MIUIMusicT" "MIUIVideo" "MiGameCenterSDKService" "VoiceTrigger" "MIUIQuickSearchBox" "MIUIMiDrive" "MIUIDuokanReader" "MIUIHuanji" "MIUIGameCenter" "Health" "MIGalleryLockscreen-MIUI15" "MIMediaEditor" "MIUICalculator" "MIUICompass" "MIUIEmail" "MIUINotes" "MIUIScreenRecorderLite" "MIUISoundRecorderTargetSdk30" "MIUIVipAccount" "MIUIVirtualSim" "MIUIXiaoAiSpeechEngine" "MIUIYoupin" "MiRadio" "MiShop" "MiuiScanner" "SmartHome" "ThirdAppAssistant" "XMRemoteController" "wps-lite")
else
  unwanted_files=("Drive" "GlobalWPSLITE" "MIDrop" "MIMediaEditorGlobal" "MISTORE_OVERSEA" "MIUICalculatorGlobal" "MIUICompassGlobal" "MIUINotes" "MIUIScreenRecorderLiteGlobal" "MIUISoundRecorderTargetSdk30Global" "MIUIWeatherGlobal" "Meet" "MiCare" "MiGalleryLockScreenGlobal" "MicrosoftOneDrive" "MiuiScanner" "Opera" "Photos" "SmartHome" "Videos" "XMRemoteController" "YTMusic" "Gmail2" "MIRadioGlobal" "MIUIHealthGlobal" "MIUIMiPicks" "Maps" "PlayAutoInstallStubApp" "Updater" "YouTube" "AndroidAutoStub" "MIUIMusicGlobal" "Velvet" "")
fi

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

dirs=("images/product/app" "images/product/priv-app" "images/product/data-app")
for dir in "${dirs[@]}"; do
    echo "Searching in directory: ${WORKSPACE}/${DEVICE}/${dir}"
    find "${WORKSPACE}/${DEVICE}/${dir}/" -type f -name "*.apk" | while read -r apk; do
        PACKAGE_NAME=$(aapt dump badging "$apk" | grep package:\ name | awk -F"'" '{print $2}')
        echo "Package found: $PACKAGE_NAME in $apk"
    done
done
for dir in "${dirs[@]}"; do
  for file in "${unwanted_files[@]}"; do
    appsuite=$(find "${WORKSPACE}/${DEVICE}/${dir}/" -type d -name "*$file")
    if [ -d "$appsuite" ]; then
      echo -e "${YELLOW}- removing: $file from $dir"
      sudo rm -rf "$appsuite"
    fi
  done
done

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
##  mkdir "${WORKSPACE}/${DEVICE}/images/product/priv-app/MiuiHome/"
##  mv "${WORKSPACE}/Builder/apps/MiuiHome.apk" "${WORKSPACE}/${DEVICE}/images/product/priv-app/MiuiHome/"
##  echo -e "${GREEN}MiuiHome added"
#  mkdir -p "${WORKSPACE}/${DEVICE}/images/product/priv-app/MIUIPackageInstaller"
#  mv "${WORKSPACE}/Builder/apps/MIUIPackageInstaller.apk" "${WORKSPACE}/${DEVICE}/images/product/priv-app/MIUIPackageInstaller/"
#  mv "${WORKSPACE}/Builder/permisions/privapp_whitelist_com.miui.packageinstaller.xml" "${WORKSPACE}/${DEVICE}/images/product/etc/permissions/"
#  echo -e "${GREEN}MIUIPackageInstaller added"
#  mkdir "${WORKSPACE}/${DEVICE}/images/product/priv-app/MIUISecurityCenter/"
#  mv "${WORKSPACE}/Builder/apps/MIUISecurityCenter.apk" "${WORKSPACE}/${DEVICE}/images/product/priv-app/MIUISecurityCenter/"
#  echo -e "${GREEN}MIUISecurityCenter added"
#  mkdir "${WORKSPACE}/${DEVICE}/images/product/app/MIUIThemeManager"
#  mv "${WORKSPACE}/Builder/apps/MIUIThemeManager.apk" "${WORKSPACE}/${DEVICE}/images/product/app/MIUIThemeManager/"
#  echo -e "${GREEN}MIUIThemeManager added"
#  mkdir -p "${WORKSPACE}/${DEVICE}/images/product/priv-app/MIUIPersonalAssistant"
#  mv "${WORKSPACE}/Builder/apps/MIUIPersonalAssistant.apk" "${WORKSPACE}/${DEVICE}/images/product/priv-app/MIUIPersonalAssistant/"
#  mv "${WORKSPACE}/Builder/permisions/privapp_whitelist_com.miui.personalassistant.xml" "${WORKSPACE}/${DEVICE}/images/product/etc/permissions/"
#  echo -e "${GREEN}MIUIPersonalAssistant added"
fi

ls -alh "${WORKSPACE}/${DEVICE}/images/product/data-app/"
ls -alh "${WORKSPACE}/${DEVICE}/images/product/app/"
ls -alh "${WORKSPACE}/${DEVICE}/images/product/priv-app/"
echo -e "${BLUE}- modified product"
