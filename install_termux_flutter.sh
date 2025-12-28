#!/data/data/com.termux/files/usr/bin/bash
#
# Termux Flutter + Android SDK 一鍵安裝腳本
# One-click installer for Flutter development on Termux
# Includes ARM64 NDK for APK building support
#
# Usage: curl -sL https://raw.githubusercontent.com/ImL1s/termux-flutter-wsl/master/install_termux_flutter.sh | bash
#

set -e

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 版本配置
FLUTTER_VERSION="3.35.0"
FLUTTER_DEB_URL="https://github.com/ImL1s/termux-flutter-wsl/releases/download/v${FLUTTER_VERSION}/flutter_${FLUTTER_VERSION}_aarch64.deb"
ANDROID_SDK_VERSION="35.0.0"
ANDROID_SDK_URL="https://github.com/mumumusuc/termux-android-sdk/releases/download/${ANDROID_SDK_VERSION}/android-sdk_${ANDROID_SDK_VERSION}_aarch64.deb"
# ARM64 NDK for APK building (from lzhiyong/termux-ndk)
NDK_VERSION="27.1.12297006"
NDK_URL="https://github.com/AntonioCiolworker/ArmDroid-NDK/releases/download/android-ndk/android-ndk-r27b-aarch64.zip"

echo -e "${BLUE}"
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║     Termux Flutter + Android SDK Installer                ║"
echo "║     Flutter ${FLUTTER_VERSION} | Android SDK ${ANDROID_SDK_VERSION} | NDK r27b       ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# 檢查架構
ARCH=$(uname -m)
if [ "$ARCH" != "aarch64" ]; then
    echo -e "${RED}Error: This script only supports ARM64 (aarch64) devices.${NC}"
    echo "Your architecture: $ARCH"
    exit 1
fi

# 檢查是否在 Termux 中
if [ ! -d "/data/data/com.termux" ]; then
    echo -e "${RED}Error: This script must be run in Termux.${NC}"
    exit 1
fi

echo -e "${GREEN}[1/8]${NC} Updating packages..."
pkg update -y
pkg upgrade -y

echo -e "${GREEN}[2/8]${NC} Installing dependencies..."
pkg install -y x11-repo
pkg install -y openjdk-21 git wget curl unzip aapt2

echo -e "${GREEN}[3/8]${NC} Downloading Flutter SDK..."
cd ~
if [ -f "flutter_${FLUTTER_VERSION}_aarch64.deb" ]; then
    echo "Flutter deb already exists, skipping download."
else
    wget -q --show-progress "$FLUTTER_DEB_URL" -O "flutter_${FLUTTER_VERSION}_aarch64.deb"
fi

echo -e "${GREEN}[4/8]${NC} Downloading Android SDK..."
if [ -f "android-sdk_${ANDROID_SDK_VERSION}_aarch64.deb" ]; then
    echo "Android SDK deb already exists, skipping download."
else
    wget -q --show-progress "$ANDROID_SDK_URL" -O "android-sdk_${ANDROID_SDK_VERSION}_aarch64.deb"
fi

echo -e "${GREEN}[5/8]${NC} Downloading ARM64 NDK (for APK building)..."
NDK_ZIP="android-ndk-r27b-aarch64.zip"
if [ -f "$NDK_ZIP" ]; then
    echo "NDK zip already exists, skipping download."
else
    echo "This may take a while (~538MB)..."
    wget -q --show-progress "$NDK_URL" -O "$NDK_ZIP"
fi

echo -e "${GREEN}[6/8]${NC} Installing packages..."
dpkg -i "flutter_${FLUTTER_VERSION}_aarch64.deb" || true
dpkg -i --force-architecture "android-sdk_${ANDROID_SDK_VERSION}_aarch64.deb" || true
apt --fix-broken install -y

echo -e "${GREEN}[7/8]${NC} Installing ARM64 NDK..."
mkdir -p $PREFIX/opt/android-sdk/ndk
if [ -d "$PREFIX/opt/android-sdk/ndk/${NDK_VERSION}" ]; then
    echo "NDK already installed, skipping."
else
    unzip -q "$NDK_ZIP" -d $PREFIX/opt/android-sdk/ndk/
    mv $PREFIX/opt/android-sdk/ndk/android-ndk-r27b $PREFIX/opt/android-sdk/ndk/${NDK_VERSION}
    echo "NDK installed to $PREFIX/opt/android-sdk/ndk/${NDK_VERSION}"
fi

echo -e "${GREEN}[8/8]${NC} Configuring environment..."

# 設定環境變數 (不設置 JAVA_HOME，讓 Gradle 自動找)
ENV_CONFIG='
# Flutter & Android SDK Configuration
export ANDROID_HOME=$PREFIX/opt/android-sdk
export PATH=$PATH:$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin
'

# 加入 .bashrc
if ! grep -q "ANDROID_HOME" ~/.bashrc 2>/dev/null; then
    echo "$ENV_CONFIG" >> ~/.bashrc
    echo "Added environment variables to ~/.bashrc"
fi

# 加入 .zshrc (如果存在)
if [ -f ~/.zshrc ]; then
    if ! grep -q "ANDROID_HOME" ~/.zshrc; then
        echo "$ENV_CONFIG" >> ~/.zshrc
        echo "Added environment variables to ~/.zshrc"
    fi
fi

# 立即載入環境變數
export ANDROID_HOME=$PREFIX/opt/android-sdk
export PATH=$PATH:$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin
# 確保不設置 JAVA_HOME
unset JAVA_HOME

# 配置 Flutter
echo -e "${YELLOW}Configuring Flutter...${NC}"
flutter config --android-sdk $ANDROID_HOME 2>/dev/null || true

# 清理下載檔案（保留 NDK zip 因為太大了）
echo "Cleaning up..."
rm -f "flutter_${FLUTTER_VERSION}_aarch64.deb"
rm -f "android-sdk_${ANDROID_SDK_VERSION}_aarch64.deb"
echo -e "${YELLOW}Note: NDK zip kept at ~/$NDK_ZIP (delete manually if needed)${NC}"

echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║     Installation Complete!                                ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo ""
echo "1. Restart Termux or run:"
echo -e "   ${BLUE}source ~/.bashrc${NC}"
echo ""
echo "2. Accept Android licenses:"
echo -e "   ${BLUE}flutter doctor --android-licenses${NC}"
echo ""
echo "3. Check installation:"
echo -e "   ${BLUE}flutter doctor${NC}"
echo ""
echo "4. Create and run your first app:"
echo -e "   ${BLUE}flutter create myapp && cd myapp${NC}"
echo -e "   ${BLUE}flutter run -d linux${NC}  (requires Termux:X11)"
echo ""
echo -e "${GREEN}✅ APK Building is now supported!${NC}"
echo ""
echo "To build APK, add these to your project's android/gradle.properties:"
echo -e "   ${BLUE}android.useAndroidX=true${NC}"
echo -e "   ${BLUE}android.enableJetifier=true${NC}"
echo -e "   ${BLUE}android.aapt2FromMavenOverride=\$PREFIX/bin/aapt2${NC}"
echo ""
echo "And set NDK version in android/app/build.gradle.kts:"
echo -e "   ${BLUE}ndkVersion = \"${NDK_VERSION}\"${NC}"
echo ""
echo "Then run:"
echo -e "   ${BLUE}flutter build apk --debug${NC}"
echo ""
echo -e "${YELLOW}To connect ADB (same device):${NC}"
echo "   1. Enable Developer Options > Wireless Debugging"
echo "   2. Tap 'Pair device with pairing code'"
echo -e "   3. Run: ${BLUE}adb pair 127.0.0.1:<port>${NC}"
echo -e "   4. Run: ${BLUE}adb connect 127.0.0.1:<port>${NC}"
echo ""
echo -e "Documentation: ${BLUE}https://github.com/ImL1s/termux-flutter-wsl${NC}"
echo ""
