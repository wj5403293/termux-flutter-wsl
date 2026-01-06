#!/bin/bash
# Flutter Termux Post-Install Script
# 安裝 deb 包後執行此腳本以完成 APK 構建環境配置

set -e

echo "=========================================="
echo "Flutter Termux Post-Install Configuration"
echo "=========================================="

# 路徑定義
FLUTTER_ROOT=/data/data/com.termux/files/usr/opt/flutter
ANDROID_SDK=/data/data/com.termux/files/usr/opt/android-sdk
DART_SDK=$FLUTTER_ROOT/bin/cache/dart-sdk

# Helper function to setup NDK clang wrappers for any NDK version
setup_ndk_clang_wrappers() {
    local NDK_PATH="$1"
    local NDK_NAME=$(basename "$NDK_PATH")

    if [ ! -d "$NDK_PATH/toolchains/llvm" ]; then
        echo "    ⚠ Skipping $NDK_NAME (no toolchains/llvm directory)"
        return
    fi

    local PREBUILT="$NDK_PATH/toolchains/llvm/prebuilt"
    local SYSROOT="$PREBUILT/linux-x86_64/sysroot"
    local CLANG_LIB="$PREBUILT/linux-x86_64/lib/clang/18/lib/linux"

    echo "    Setting up clang wrappers for NDK $NDK_NAME..."

    # Create wrapper script content (using NDK_PATH variable in script)
CLANG_WRAPPER="#!/bin/sh
NDK=$NDK_PATH
SYSROOT=\$NDK/toolchains/llvm/prebuilt/linux-x86_64/sysroot
CLANG_LIB=\$NDK/toolchains/llvm/prebuilt/linux-x86_64/lib/clang/18/lib/linux

ARCH=\"\"
for arg in \"\$@\"; do
    case \"\$arg\" in
        --target=aarch64*) ARCH=\"aarch64\" ;;
        --target=arm*) ARCH=\"arm\" ;;
    esac
done

if [ \"\$ARCH\" = \"aarch64\" ]; then
    LIB_PATH=\$SYSROOT/usr/lib/aarch64-linux-android
    CLANG_LIB_ARCH=\$CLANG_LIB/aarch64
elif [ \"\$ARCH\" = \"arm\" ]; then
    LIB_PATH=\$SYSROOT/usr/lib/arm-linux-androideabi
    CLANG_LIB_ARCH=\$CLANG_LIB/arm
else
    exec /data/data/com.termux/files/usr/bin/clang \"\$@\"
fi

exec /data/data/com.termux/files/usr/bin/clang -L\$LIB_PATH -L\$CLANG_LIB_ARCH \"\$@\""

CLANGPP_WRAPPER="#!/bin/sh
NDK=$NDK_PATH
SYSROOT=\$NDK/toolchains/llvm/prebuilt/linux-x86_64/sysroot
CLANG_LIB=\$NDK/toolchains/llvm/prebuilt/linux-x86_64/lib/clang/18/lib/linux

ARCH=\"\"
for arg in \"\$@\"; do
    case \"\$arg\" in
        --target=aarch64*) ARCH=\"aarch64\" ;;
        --target=arm*) ARCH=\"arm\" ;;
    esac
done

if [ \"\$ARCH\" = \"aarch64\" ]; then
    LIB_PATH=\$SYSROOT/usr/lib/aarch64-linux-android
    CLANG_LIB_ARCH=\$CLANG_LIB/aarch64
elif [ \"\$ARCH\" = \"arm\" ]; then
    LIB_PATH=\$SYSROOT/usr/lib/arm-linux-androideabi
    CLANG_LIB_ARCH=\$CLANG_LIB/arm
else
    exec /data/data/com.termux/files/usr/bin/clang++ \"\$@\"
fi

exec /data/data/com.termux/files/usr/bin/clang++ -L\$LIB_PATH -L\$CLANG_LIB_ARCH \"\$@\""

    # Create wrappers in prebuilt/bin/ (for some toolchain configs)
    mkdir -p "$PREBUILT/bin"
    echo "$CLANG_WRAPPER" > "$PREBUILT/bin/clang"
    chmod +x "$PREBUILT/bin/clang"
    echo "$CLANGPP_WRAPPER" > "$PREBUILT/bin/clang++"
    chmod +x "$PREBUILT/bin/clang++"

    # Create wrappers in prebuilt/linux-x86_64/bin/ (official NDK structure)
    mkdir -p "$PREBUILT/linux-x86_64/bin"
    # Remove symlinks first (clang -> clang-18, clang++ -> clang chain causes overwrites)
    rm -f "$PREBUILT/linux-x86_64/bin/clang" "$PREBUILT/linux-x86_64/bin/clang++" 2>/dev/null || true
    echo "$CLANG_WRAPPER" > "$PREBUILT/linux-x86_64/bin/clang"
    chmod +x "$PREBUILT/linux-x86_64/bin/clang"
    echo "$CLANGPP_WRAPPER" > "$PREBUILT/linux-x86_64/bin/clang++"
    chmod +x "$PREBUILT/linux-x86_64/bin/clang++"

    # Create linux-aarch64 symlink (for some toolchain configs)
    ln -sf bin "$PREBUILT/linux-aarch64" 2>/dev/null || true

    # Create sysroot symlink
    ln -sf linux-x86_64/sysroot "$PREBUILT/sysroot" 2>/dev/null || true

    # Patch toolchain cmake if exists
    local TOOLCHAIN="$NDK_PATH/build/cmake/android-legacy.toolchain.cmake"
    if [ -f "$TOOLCHAIN" ]; then
        if grep -q 'list(APPEND ANDROID_LINKER_FLAGS "-static-libstdc++")' "$TOOLCHAIN" 2>/dev/null; then
            sed -i 's/list(APPEND ANDROID_LINKER_FLAGS "-static-libstdc++")/# Disabled for Termux: list(APPEND ANDROID_LINKER_FLAGS "-static-libstdc++")/' "$TOOLCHAIN"
        fi
    fi

    echo "    ✓ NDK $NDK_NAME configured"
}

# Get engine version for downloads
ENGINE_VERSION=$(cat $FLUTTER_ROOT/bin/internal/engine.version 2>/dev/null || echo "1e9a811bf8e70466596bcf0ea3a8b5adb5f17f7f")

# 0. 下載官方 Dart SDK snapshots (修復 flutter run hot reload)
echo "[0/13] Downloading official Dart SDK snapshots (for hot reload)..."
SNAPSHOTS_URL="https://storage.googleapis.com/flutter_infra_release/flutter/${ENGINE_VERSION}/dart-sdk-linux-arm64.zip"
SNAPSHOTS_DIR=$DART_SDK/bin/snapshots

# Check if key snapshot is missing
if [ ! -f "$SNAPSHOTS_DIR/dds_aot.dart.snapshot" ]; then
    echo "  Downloading dart-sdk-linux-arm64.zip..."
    cd "${TMPDIR:-$PREFIX/tmp}"
    curl -L -o dart-sdk.zip "$SNAPSHOTS_URL"
    echo "  Extracting snapshots..."
    unzip -o -j dart-sdk.zip 'dart-sdk/bin/snapshots/*' -d "$SNAPSHOTS_DIR"
    rm dart-sdk.zip

    # Create symlinks for non-AOT versions
    ln -sf frontend_server_aot.dart.snapshot "$SNAPSHOTS_DIR/frontend_server.dart.snapshot" 2>/dev/null || true

    echo "  ✓ Dart SDK snapshots installed"
else
    echo "  ✓ Dart SDK snapshots already exist"
fi

# 1. 清理 ELF 二進制的 DT_RPATH (修復 flutter run crash)
echo "[1/13] Cleaning ELF binaries (fix flutter run)..."
pkg install -y termux-elf-cleaner 2>/dev/null || true

# Clean dart binaries to remove DT_RPATH warnings that crash flutter run
if command -v termux-elf-cleaner &> /dev/null; then
    echo "  Cleaning dart-sdk binaries..."
    find $DART_SDK/bin -type f -executable 2>/dev/null | xargs -r termux-elf-cleaner 2>/dev/null || true

    echo "  Cleaning engine artifacts..."
    find $FLUTTER_ROOT/bin/cache/artifacts/engine -name "*.so" -o -name "gen_snapshot" -o -name "dart" 2>/dev/null | xargs -r termux-elf-cleaner 2>/dev/null || true

    echo "  ✓ ELF binaries cleaned"
else
    echo "  ⚠ termux-elf-cleaner not found, skipping"
fi

# 2. 下載並安裝 Android API 34 (aapt2 bug workaround)
echo "[2/13] Installing Android API 34..."
if [ ! -d "$ANDROID_SDK/platforms/android-34" ]; then
    cd $ANDROID_SDK/platforms
    curl -L -o platform-34.zip 'https://dl.google.com/android/repository/platform-34-ext7_r02.zip'
    unzip -q platform-34.zip
    rm platform-34.zip
    echo "  ✓ API 34 installed"
else
    echo "  ✓ API 34 already exists"
fi

# 2. 修改 FlutterPluginConstants.kt (僅構建 ARM64)
echo "[3/13] Configuring Flutter for ARM64 only..."
cat > $FLUTTER_ROOT/packages/flutter_tools/gradle/src/main/kotlin/FlutterPluginConstants.kt << 'EOF'
package com.flutter.gradle

object FlutterPluginConstants {
    private const val PLATFORM_ARM32 = "android-arm"
    private const val PLATFORM_ARM64 = "android-arm64"
    private const val PLATFORM_X86_64 = "android-x64"

    private const val ARCH_ARM32 = "armeabi-v7a"
    private const val ARCH_ARM64 = "arm64-v8a"
    private const val ARCH_X86_64 = "x86_64"

    const val INTERMEDIATES_DIR = "intermediates"
    const val FLUTTER_STORAGE_BASE_URL = "FLUTTER_STORAGE_BASE_URL"
    const val DEFAULT_MAVEN_HOST = "https://storage.googleapis.com"

    @JvmStatic val PLATFORM_ARCH_MAP =
        mapOf(
            PLATFORM_ARM32 to ARCH_ARM32,
            PLATFORM_ARM64 to ARCH_ARM64,
            PLATFORM_X86_64 to ARCH_X86_64
        )

    @JvmStatic val ABI_VERSION =
        mapOf(
            ARCH_ARM32 to 1,
            ARCH_ARM64 to 2,
            ARCH_X86_64 to 4
        )

    // Modified for Termux: only arm64 supported
    @JvmStatic val DEFAULT_PLATFORMS =
        listOf(
            PLATFORM_ARM64
        )
}
EOF
echo "  ✓ FlutterPluginConstants.kt updated"

# 3. 創建 NDK clang wrappers (處理所有已安裝的 NDK 版本)
echo "[4/13] Creating NDK clang wrappers..."

NDK_DIR="$ANDROID_SDK/ndk"
if [ -d "$NDK_DIR" ]; then
    NDK_COUNT=0
    for ndk_path in "$NDK_DIR"/*; do
        if [ -d "$ndk_path" ]; then
            setup_ndk_clang_wrappers "$ndk_path"
            NDK_COUNT=$((NDK_COUNT + 1))
        fi
    done
    if [ $NDK_COUNT -eq 0 ]; then
        echo "  ⚠ No NDK found. Clang wrappers will be created when NDK is installed."
        echo "    Re-run this script after installing NDK: bash $PREFIX/share/flutter/post_install.sh"
    else
        echo "  ✓ $NDK_COUNT NDK(s) configured"
    fi
else
    echo "  ⚠ NDK directory not found. Clang wrappers will be created when NDK is installed."
    echo "    Re-run this script after installing NDK: bash $PREFIX/share/flutter/post_install.sh"
fi

# 7. 創建 build-tools 符號連結
echo "[8/13] Creating build-tools symlinks..."
BUILD_TOOLS=$ANDROID_SDK/build-tools/35.0.0
mkdir -p $BUILD_TOOLS/lib

# 基本工具
for tool in aapt aapt2 apksigner d8 dx zipalign; do
    ln -sf /data/data/com.termux/files/usr/bin/$tool $BUILD_TOOLS/$tool 2>/dev/null || true
done

# aidl
ln -sf /data/data/com.termux/files/usr/bin/aidl $BUILD_TOOLS/aidl 2>/dev/null || true

# dexdump (from ART)
if [ -f /apex/com.android.art/bin/dexdump ]; then
    ln -sf /apex/com.android.art/bin/dexdump $BUILD_TOOLS/dexdump 2>/dev/null || true
fi

# split-select stub
cat > $BUILD_TOOLS/split-select << 'EOF'
#!/bin/sh
echo "split-select is not available on Termux ARM64"
exit 0
EOF
chmod +x $BUILD_TOOLS/split-select

# core-lambda-stubs.jar
if [ ! -f $BUILD_TOOLS/core-lambda-stubs.jar ]; then
    MANIFEST_TMP="${TMPDIR:-$PREFIX/tmp}/MANIFEST.MF"
    echo "Manifest-Version: 1.0" > "$MANIFEST_TMP"
    jar cfm $BUILD_TOOLS/core-lambda-stubs.jar "$MANIFEST_TMP"
    rm "$MANIFEST_TMP"
fi

# d8.jar and dx.jar
ln -sf /data/data/com.termux/files/usr/share/java/d8.jar $BUILD_TOOLS/lib/d8.jar 2>/dev/null || true
ln -sf /data/data/com.termux/files/usr/share/java/d8.jar $BUILD_TOOLS/lib/dx.jar 2>/dev/null || true

echo "  ✓ Build-tools symlinks created"

# 8. 安裝 cmdline-tools (讓 flutter 檢測 Android 設備)
echo "[9/13] Installing cmdline-tools..."
if [ ! -d "$ANDROID_SDK/cmdline-tools/latest" ]; then
    mkdir -p $ANDROID_SDK/cmdline-tools
    cd $ANDROID_SDK/cmdline-tools
    curl -L -o tools.zip 'https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip'
    unzip -q tools.zip
    mv cmdline-tools latest
    rm tools.zip
    echo "  ✓ cmdline-tools installed"
else
    echo "  ✓ cmdline-tools already exists"
fi

# 9. 創建 platform-tools 符號連結 (adb)
echo "[10/13] Creating platform-tools symlinks..."
mkdir -p $ANDROID_SDK/platform-tools
ln -sf /data/data/com.termux/files/usr/bin/adb $ANDROID_SDK/platform-tools/adb 2>/dev/null || true
ln -sf /data/data/com.termux/files/usr/bin/fastboot $ANDROID_SDK/platform-tools/fastboot 2>/dev/null || true
echo "  ✓ platform-tools symlinks created"

# 10. 接受 Android licenses
echo "[11/13] Accepting Android licenses..."
mkdir -p $ANDROID_SDK/licenses
echo -e "\n24333f8a63b6825ea9c5514f83c2829b004d1fee" > $ANDROID_SDK/licenses/android-sdk-license
echo -e "\n84831b9409646a918e30573bab4c9c91346d8abd" > $ANDROID_SDK/licenses/android-sdk-preview-license
echo "  ✓ Android licenses accepted"

# 11. 複製 VM snapshots (for debug mode)
echo "[12/13] Checking engine artifacts..."
ENGINE_DIR=$FLUTTER_ROOT/bin/cache/artifacts/engine/linux-arm64

if [ ! -f "$ENGINE_DIR/vm_isolate_snapshot.bin" ]; then
    echo "  ⚠ vm_isolate_snapshot.bin not found - debug APK builds may fail"
    echo "    Please copy from WSL build: flutter/engine/src/out/linux_debug_arm64/gen/flutter/lib/snapshot/"
else
    echo "  ✓ VM snapshots present"
fi

echo ""
echo "=========================================="
echo "Post-install configuration complete!"
echo "=========================================="
echo ""
echo "=== Quick Start ==="
echo "  source /data/data/com.termux/files/usr/etc/profile.d/flutter.sh"
echo "  flutter create myapp && cd myapp"
echo "  flutter build apk --release"
echo ""
echo "=== Project Setup (for each Flutter project) ==="
echo "  Edit android/app/build.gradle.kts:"
echo "    compileSdk = 34"
echo "    targetSdk = 34"
echo "    ndk { abiFilters += listOf(\"arm64-v8a\") }"
echo ""
echo "  Add to android/gradle.properties:"
echo "    android.aapt2FromMavenOverride=/data/data/com.termux/files/usr/bin/aapt2"
echo ""
echo "=== Hot Reload on Device (flutter run) ==="
echo "  1. Enable Wireless Debugging:"
echo "     Settings → Developer Options → Wireless Debugging → ON"
echo ""
echo "  2. Pair device (one-time):"
echo "     Click 'Pair device with pairing code'"
echo "     adb pair 127.0.0.1:<PAIR_PORT> <PAIRING_CODE>"
echo ""
echo "  3. Connect:"
echo "     adb connect 127.0.0.1:<CONNECT_PORT>"
echo "     (Use the port shown on Wireless Debugging page, not pairing port)"
echo ""
echo "  4. Run:"
echo "     flutter run"
echo ""
