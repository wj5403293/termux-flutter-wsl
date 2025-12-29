#!/data/data/com.termux/files/usr/bin/bash
#
# Termux Flutter 一鍵安裝腳本
# One-click installer for Flutter development on Termux
#
# Usage: curl -sL https://raw.githubusercontent.com/ImL1s/termux-flutter-wsl/master/install_termux_flutter.sh | bash
#
# 當前狀態 (v3.35.0):
#   - flutter doctor: ✅ 已驗證
#   - flutter create: ✅ 已驗證
#   - flutter build apk: 🔧 開發中
#   - flutter build linux: 🔧 開發中
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

echo -e "${BLUE}"
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║     Termux Flutter Installer                              ║"
echo "║     Flutter ${FLUTTER_VERSION}                                         ║"
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

TOTAL_STEPS=5

echo -e "${GREEN}[1/${TOTAL_STEPS}]${NC} Updating packages..."
pkg update -y
pkg upgrade -y

echo -e "${GREEN}[2/${TOTAL_STEPS}]${NC} Installing dependencies..."
pkg install -y x11-repo
pkg install -y openjdk-21 git wget curl unzip

echo -e "${GREEN}[3/${TOTAL_STEPS}]${NC} Downloading Flutter SDK..."
cd ~
if [ -f "flutter_${FLUTTER_VERSION}_aarch64.deb" ]; then
    echo "Flutter deb already exists, skipping download."
else
    wget -q --show-progress "$FLUTTER_DEB_URL" -O "flutter_${FLUTTER_VERSION}_aarch64.deb"
fi

echo -e "${GREEN}[4/${TOTAL_STEPS}]${NC} Installing Flutter..."
dpkg -i "flutter_${FLUTTER_VERSION}_aarch64.deb" || true
apt --fix-broken install -y

echo -e "${GREEN}[5/${TOTAL_STEPS}]${NC} Configuring environment..."

# 載入環境變數
source $PREFIX/etc/profile.d/flutter.sh 2>/dev/null || true

# 加入 .bashrc（如果還沒加入）
if ! grep -q "flutter.sh" ~/.bashrc 2>/dev/null; then
    echo 'source $PREFIX/etc/profile.d/flutter.sh' >> ~/.bashrc
    echo "Added flutter to ~/.bashrc"
fi

# 加入 .zshrc（如果存在且還沒加入）
if [ -f ~/.zshrc ]; then
    if ! grep -q "flutter.sh" ~/.zshrc; then
        echo 'source $PREFIX/etc/profile.d/flutter.sh' >> ~/.zshrc
        echo "Added flutter to ~/.zshrc"
    fi
fi

echo ""
echo "Cleaning up..."
rm -f "flutter_${FLUTTER_VERSION}_aarch64.deb"

echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║     Installation Complete!                                ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Verify installation:${NC}"
echo ""
echo "1. Restart Termux or run:"
echo -e "   ${BLUE}source ~/.bashrc${NC}"
echo ""
echo "2. Check Flutter:"
echo -e "   ${BLUE}flutter doctor${NC}"
echo ""
echo "3. Create your first app:"
echo -e "   ${BLUE}flutter create myapp${NC}"
echo ""
echo -e "${GREEN}✅ Verified working:${NC}"
echo "   - flutter doctor"
echo "   - flutter create"
echo ""
echo -e "${YELLOW}📱 For Android APK building:${NC}"
echo "   See: https://github.com/ImL1s/termux-flutter-wsl#構建-android-apk"
echo "   (Requires additional setup: Android SDK, NDK, etc.)"
echo ""
echo -e "Documentation: ${BLUE}https://github.com/ImL1s/termux-flutter-wsl${NC}"
echo ""
