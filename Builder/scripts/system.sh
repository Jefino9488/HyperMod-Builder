DEVICE="$1"
WORKSPACE="$2"

RED='\033[1;31m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
GREEN='\033[1;32m'

# modify
echo -e "${YELLOW}- modifying System"

#unwanted_files=("MIUIMiDrive" "MIUIDuokanReader" "MIUIQuickSearchBox" "MIUIHuanji" "MIUIGameCenter" "Health" "MIGalleryLockscreen-MIUI15" "MIMediaEditor" "MIUICalculator" "MIUICleanMaster" "MIUICompass" "MIUIEmail" "MIUINewHome_Removable" "MIUINotes" "MIUIScreenRecorderLite" "MIUISoundRecorderTargetSdk30" "MIUIVipAccount" "MIUIVirtualSim" "MIUIXiaoAiSpeechEngine" "MIUIYoupin" "MiRadio" "MiShop" "MiuiScanner" "SmartHome" "ThirdAppAssistant" "XMRemoteController" "com.iflytek.inputmethod.miui" "wps-lite" "BaiduIME" "MiuiDaemon" "MiuiBugReport" "Updater" "MiService" "MiBrowserGlobal" "Music" "XiaomiEUExt" "MiShare" "MiuiVideoGlobal" "GoogleLens" "MiGalleryLockscreen" "MiMover" "PrintSpooler" "CatchLog" "facebook-appmanager" "MIUICompassGlobal" "MIUIHealthGlobal" "MIUIVideoPlayer" "facebook-installer" "facebook-services" "MIShareGlobal" "MIUIMusicGlobal" "MIBrowserGlobal" "MIDrop" "MIUISystemAppUpdater")
#
#dirs=("images/system/system/app" "images/system/system/priv-app" "images/system/system/data-app")
#
#for dir in "${dirs[@]}"; do
#  for file in "${unwanted_files[@]}"; do
#    appsuite=$(find "${WORKSPACE}/${DEVICE}/${dir}/" -type d -name "*$file")
#    if [ -d "$appsuite" ]; then
#      echo -e "${YELLOW}- removing: $file from $dir"
#      sudo rm -rf "$appsuite"
#    fi
#  done
#done
ls -alh "${WORKSPACE}/${DEVICE}/images/system/system/data-app/"
ls -alh "${WORKSPACE}/${DEVICE}/images/system/system/app/"
ls -alh "${WORKSPACE}/${DEVICE}/images/system/system/priv-app/"
echo -e "${BLUE}- modified system"