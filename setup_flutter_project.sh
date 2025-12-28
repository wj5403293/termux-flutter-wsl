#!/data/data/com.termux/files/usr/bin/bash
#
# Flutter 專案 APK 構建配置腳本
# Configure a Flutter project for APK building on Termux
#
# Usage: Run this script in your Flutter project directory
#        ./setup_flutter_project.sh
#

set -e

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

NDK_VERSION="27.1.12297006"

echo -e "${BLUE}"
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║     Flutter Project APK Build Configuration               ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# 檢查是否在 Flutter 專案目錄
if [ ! -f "pubspec.yaml" ]; then
    echo -e "${RED}Error: Not in a Flutter project directory.${NC}"
    echo "Please run this script from your Flutter project root."
    exit 1
fi

if [ ! -d "android" ]; then
    echo -e "${RED}Error: No android directory found.${NC}"
    echo "Run 'flutter create .' to generate Android files."
    exit 1
fi

echo -e "${GREEN}[1/3]${NC} Configuring gradle.properties..."

GRADLE_PROPS="android/gradle.properties"

# 添加必要的 Gradle 配置
if ! grep -q "android.useAndroidX" "$GRADLE_PROPS" 2>/dev/null; then
    echo "android.useAndroidX=true" >> "$GRADLE_PROPS"
fi

if ! grep -q "android.enableJetifier" "$GRADLE_PROPS" 2>/dev/null; then
    echo "android.enableJetifier=true" >> "$GRADLE_PROPS"
fi

if ! grep -q "aapt2FromMavenOverride" "$GRADLE_PROPS" 2>/dev/null; then
    echo "android.aapt2FromMavenOverride=$PREFIX/bin/aapt2" >> "$GRADLE_PROPS"
fi

if ! grep -q "org.gradle.jvmargs" "$GRADLE_PROPS" 2>/dev/null; then
    echo "org.gradle.jvmargs=-Xmx768m -XX:MaxMetaspaceSize=384m" >> "$GRADLE_PROPS"
fi

echo "  Updated: $GRADLE_PROPS"

echo -e "${GREEN}[2/3]${NC} Configuring build.gradle.kts..."

BUILD_GRADLE="android/app/build.gradle.kts"
BUILD_GRADLE_GROOVY="android/app/build.gradle"

if [ -f "$BUILD_GRADLE" ]; then
    # Kotlin DSL
    if ! grep -q "ndkVersion" "$BUILD_GRADLE" 2>/dev/null; then
        # 在 android { 後面插入 ndkVersion
        sed -i 's/android {/android {\n    ndkVersion = "'"$NDK_VERSION"'"/' "$BUILD_GRADLE"
        echo "  Updated: $BUILD_GRADLE"
    else
        echo "  ndkVersion already set in $BUILD_GRADLE"
    fi
elif [ -f "$BUILD_GRADLE_GROOVY" ]; then
    # Groovy DSL
    if ! grep -q "ndkVersion" "$BUILD_GRADLE_GROOVY" 2>/dev/null; then
        sed -i 's/android {/android {\n    ndkVersion "'"$NDK_VERSION"'"/' "$BUILD_GRADLE_GROOVY"
        echo "  Updated: $BUILD_GRADLE_GROOVY"
    else
        echo "  ndkVersion already set in $BUILD_GRADLE_GROOVY"
    fi
else
    echo -e "${YELLOW}Warning: Could not find build.gradle file${NC}"
fi

echo -e "${GREEN}[3/3]${NC} Verifying configuration..."

echo ""
echo "gradle.properties contents:"
echo "----------------------------"
cat "$GRADLE_PROPS"
echo "----------------------------"
echo ""

echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║     Configuration Complete!                               ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "You can now build your APK:"
echo -e "   ${BLUE}flutter build apk --debug${NC}"
echo ""
echo "Or for release:"
echo -e "   ${BLUE}flutter build apk --release${NC}"
echo ""
