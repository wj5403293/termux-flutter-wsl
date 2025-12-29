#!/data/data/com.termux/files/usr/bin/bash
#
# Termux Flutter 完整安裝腳本
# Complete Flutter + Android SDK Installation for Termux
#
# Usage: curl -sL https://raw.githubusercontent.com/ImL1s/termux-flutter-wsl/master/install_flutter_complete.sh | bash
#
# 這個腳本會自動完成：
#   1. 安裝 Flutter SDK
#   2. 安裝 Android SDK
#   3. 配置環境
#   4. 創建測試專案
#   5. 構建測試 APK
#
# 完成後你可以直接使用 flutter build apk 構建任何專案
#

set -e

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 版本配置
FLUTTER_VERSION="3.35.0"
NDK_VERSION="27.1.12297006"
REPO_BASE="https://raw.githubusercontent.com/ImL1s/termux-flutter-wsl/master"

echo -e "${CYAN}"
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║                                                           ║"
echo "║     Termux Flutter Complete Installer                     ║"
echo "║     Flutter ${FLUTTER_VERSION} + Android SDK                         ║"
echo "║                                                           ║"
echo "║     世界首個在 ARM64 Termux 原生支援                      ║"
echo "║     flutter build apk 的解決方案                          ║"
echo "║                                                           ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""

# ========================================
# 環境檢查
# ========================================
echo -e "${GREEN}[檢查]${NC} 驗證環境..."

# 檢查架構
ARCH=$(uname -m)
if [ "$ARCH" != "aarch64" ]; then
    echo -e "${RED}錯誤: 此腳本只支援 ARM64 (aarch64) 設備${NC}"
    echo "你的架構: $ARCH"
    exit 1
fi

# 檢查是否在 Termux 中
if [ ! -d "/data/data/com.termux" ]; then
    echo -e "${RED}錯誤: 此腳本必須在 Termux 中執行${NC}"
    exit 1
fi

echo "  ✓ 架構: ARM64"
echo "  ✓ 環境: Termux"
echo ""

# 詢問是否繼續
echo -e "${YELLOW}此腳本將安裝：${NC}"
echo "  • Flutter SDK (~550MB)"
echo "  • Android SDK (~700MB)"
echo "  • ARM64 NDK (~550MB)"
echo "  • 總共約 1.8GB"
echo ""
echo -e "${YELLOW}預計時間：${NC} 10-30 分鐘（視網速而定）"
echo ""
read -p "是否繼續? [Y/n] " -n 1 -r
echo
if [[ $REPLY =~ ^[Nn]$ ]]; then
    echo "安裝已取消"
    exit 0
fi

TOTAL_STEPS=6

# ========================================
# Step 1: 更新系統
# ========================================
echo ""
echo -e "${GREEN}[1/${TOTAL_STEPS}]${NC} 更新系統套件..."
pkg update -y
pkg upgrade -y

# ========================================
# Step 2: 安裝 Flutter
# ========================================
echo ""
echo -e "${GREEN}[2/${TOTAL_STEPS}]${NC} 安裝 Flutter SDK..."

# 安裝依賴
pkg install -y x11-repo
pkg install -y openjdk-21 git wget curl unzip cmake ninja

# 下載 Flutter deb
FLUTTER_DEB_URL="https://github.com/ImL1s/termux-flutter-wsl/releases/download/v${FLUTTER_VERSION}/flutter_${FLUTTER_VERSION}_aarch64.deb"
FLUTTER_DEB="$HOME/flutter_${FLUTTER_VERSION}_aarch64.deb"

if [ ! -f "$FLUTTER_DEB" ]; then
    echo "下載 Flutter SDK..."
    wget -q --show-progress "$FLUTTER_DEB_URL" -O "$FLUTTER_DEB"
fi

# 安裝
dpkg -i "$FLUTTER_DEB" || true
apt --fix-broken install -y

# 載入環境
source $PREFIX/etc/profile.d/flutter.sh 2>/dev/null || true

# 執行 post_install.sh（配置 hot reload 和 APK 構建環境）
if [ -f "$PREFIX/share/flutter/post_install.sh" ]; then
    echo "執行 post_install.sh..."
    bash $PREFIX/share/flutter/post_install.sh
fi

echo "  ✓ Flutter 已安裝"

# ========================================
# Step 3: 安裝 Android SDK
# ========================================
echo ""
echo -e "${GREEN}[3/${TOTAL_STEPS}]${NC} 安裝 Android SDK..."

ANDROID_SDK_DEB_URL="https://github.com/mumumusuc/termux-android-sdk/releases/download/35.0.0/android-sdk_35.0.0_aarch64.deb"
ANDROID_SDK_DEB="$HOME/android-sdk_35.0.0_aarch64.deb"

if [ ! -f "$ANDROID_SDK_DEB" ]; then
    echo "下載 Android SDK..."
    wget -q --show-progress "$ANDROID_SDK_DEB_URL" -O "$ANDROID_SDK_DEB"
fi

# 安裝 (忽略 openjdk-17 依賴)
dpkg -i --force-architecture "$ANDROID_SDK_DEB" 2>/dev/null || true
dpkg --force-depends --configure android-sdk 2>/dev/null || true

echo "  ✓ Android SDK 已安裝"

# ========================================
# Step 4: 安裝 ARM64 NDK
# ========================================
echo ""
echo -e "${GREEN}[4/${TOTAL_STEPS}]${NC} 安裝 ARM64 NDK..."

ANDROID_HOME="$PREFIX/opt/android-sdk"
NDK_PATH="$ANDROID_HOME/ndk/$NDK_VERSION"

if [ -d "$NDK_PATH" ]; then
    echo "  ✓ NDK 已安裝"
else
    NDK_ZIP_URL="https://github.com/lzhiyong/termux-ndk/releases/download/android-ndk/android-ndk-r27b-aarch64.zip"
    NDK_ZIP="$HOME/android-ndk-r27b-aarch64.zip"

    if [ ! -f "$NDK_ZIP" ]; then
        echo "下載 ARM64 NDK (約 550MB)..."
        wget -q --show-progress "$NDK_ZIP_URL" -O "$NDK_ZIP"
    fi

    echo "解壓 NDK..."
    mkdir -p "$ANDROID_HOME/ndk"
    unzip -q "$NDK_ZIP" -d "$ANDROID_HOME/ndk/"
    mv "$ANDROID_HOME/ndk/android-ndk-r27b" "$NDK_PATH"

    echo "  ✓ NDK 已安裝"
fi

# ========================================
# Step 5: 配置環境
# ========================================
echo ""
echo -e "${GREEN}[5/${TOTAL_STEPS}]${NC} 配置環境..."

# 設置環境變數
export ANDROID_HOME=$PREFIX/opt/android-sdk
export PATH=$PATH:$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin

# 加入 .bashrc
if ! grep -q "ANDROID_HOME" ~/.bashrc 2>/dev/null; then
    cat >> ~/.bashrc << 'EOF'

# Flutter
source $PREFIX/etc/profile.d/flutter.sh

# Android SDK
export ANDROID_HOME=$PREFIX/opt/android-sdk
export PATH=$PATH:$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin
EOF
fi

# 修復 CMake
rm -rf $ANDROID_HOME/cmake/*/bin 2>/dev/null || true
mkdir -p $ANDROID_HOME/cmake/3.22.1/bin
ln -sf $PREFIX/bin/cmake $ANDROID_HOME/cmake/3.22.1/bin/cmake
ln -sf $PREFIX/bin/ninja $ANDROID_HOME/cmake/3.22.1/bin/ninja

# 配置 Flutter
flutter config --android-sdk $ANDROID_HOME 2>/dev/null || true

# 接受授權
yes | flutter doctor --android-licenses 2>/dev/null || true

echo "  ✓ 環境已配置"

# ========================================
# Step 6: 測試構建
# ========================================
echo ""
echo -e "${GREEN}[6/${TOTAL_STEPS}]${NC} 測試 APK 構建..."

TEST_APP_DIR="$HOME/flutter_test_app"

# 創建測試專案
if [ -d "$TEST_APP_DIR" ]; then
    rm -rf "$TEST_APP_DIR"
fi

echo "創建測試專案..."
flutter create "$TEST_APP_DIR" 2>/dev/null

cd "$TEST_APP_DIR"

# 配置專案
echo "ndk.dir=$ANDROID_HOME/ndk/$NDK_VERSION" >> android/local.properties
sed -i 's/ndkVersion = flutter.ndkVersion/ndkVersion = "'"$NDK_VERSION"'"/g' android/app/build.gradle.kts 2>/dev/null || true

# 首次構建（可能因 AAPT2 失敗）
echo "首次構建（下載依賴）..."
flutter build apk --release 2>&1 | tee /tmp/build1.log || true

# 修復 AAPT2
if grep -q "EM_X86_64" /tmp/build1.log 2>/dev/null; then
    echo "修復 AAPT2..."
    find ~/.gradle/caches -name "aapt2" -path "*aapt2-*-linux*" 2>/dev/null | while read f; do
        rm -f "$f"
        ln -s "$ANDROID_HOME/build-tools/35.0.0/aapt2" "$f"
    done

    # 再次構建
    echo "重新構建..."
    flutter build apk --release 2>&1 | tee /tmp/build2.log
fi

# 檢查結果
if [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
    APK_SIZE=$(ls -lh build/app/outputs/flutter-apk/app-release.apk | awk '{print $5}')
    BUILD_SUCCESS=true
else
    BUILD_SUCCESS=false
fi

cd $HOME

# ========================================
# 清理
# ========================================
echo ""
echo "清理臨時檔案..."
rm -f "$FLUTTER_DEB" "$ANDROID_SDK_DEB" "$NDK_ZIP" 2>/dev/null || true

# ========================================
# 完成
# ========================================
echo ""
echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
if [ "$BUILD_SUCCESS" = true ]; then
    echo -e "${CYAN}║     ${GREEN}安裝完成！APK 構建測試成功！${CYAN}                        ║${NC}"
else
    echo -e "${CYAN}║     ${YELLOW}安裝完成！APK 構建測試需要手動檢查${CYAN}                  ║${NC}"
fi
echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""

if [ "$BUILD_SUCCESS" = true ]; then
    echo -e "${GREEN}測試 APK:${NC} $TEST_APP_DIR/build/app/outputs/flutter-apk/app-release.apk ($APK_SIZE)"
    echo ""
fi

echo -e "${YELLOW}開始使用：${NC}"
echo ""
echo -e "${GREEN}環境已自動配置！重啟 Termux 後直接可用。${NC}"
echo ""
echo "1. 檢查 Flutter："
echo -e "   ${BLUE}flutter doctor${NC}"
echo ""
echo "2. 創建你的專案："
echo -e "   ${BLUE}flutter create myapp${NC}"
echo -e "   ${BLUE}cd myapp${NC}"
echo ""
echo "3. 構建 APK："
echo -e "   ${BLUE}flutter build apk --release${NC}"
echo ""
echo "4. Hot Reload 開發："
echo -e "   ${BLUE}adb connect 127.0.0.1:<端口>${NC}"
echo -e "   ${BLUE}flutter run${NC}"
echo ""
echo -e "文檔: ${BLUE}https://github.com/ImL1s/termux-flutter-wsl${NC}"
echo ""
