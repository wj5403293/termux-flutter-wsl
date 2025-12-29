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
NDK=$ANDROID_SDK/ndk/27.0.12077973
PREBUILT=$NDK/toolchains/llvm/prebuilt
SYSROOT=$PREBUILT/linux-x86_64/sysroot
CLANG_LIB=$PREBUILT/linux-x86_64/lib/clang/18/lib/linux
DART_SDK=$FLUTTER_ROOT/bin/cache/dart-sdk

# 0. 清理 ELF 二進制的 DT_RPATH (修復 flutter run crash)
echo "[0/12] Cleaning ELF binaries (fix flutter run)..."
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

# 1. 下載並安裝 Android API 34 (aapt2 bug workaround)
echo "[1/12] Installing Android API 34..."
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
echo "[2/12] Configuring Flutter for ARM64 only..."
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

# 3. 創建 NDK clang wrapper
echo "[3/12] Creating NDK clang wrappers..."
mkdir -p $PREBUILT/bin

cat > $PREBUILT/bin/clang << 'EOF'
#!/bin/sh
NDK=/data/data/com.termux/files/usr/opt/android-sdk/ndk/27.0.12077973
SYSROOT=$NDK/toolchains/llvm/prebuilt/linux-x86_64/sysroot
CLANG_LIB=$NDK/toolchains/llvm/prebuilt/linux-x86_64/lib/clang/18/lib/linux

ARCH=""
for arg in "$@"; do
    case "$arg" in
        --target=aarch64*) ARCH="aarch64" ;;
        --target=arm*) ARCH="arm" ;;
    esac
done

if [ "$ARCH" = "aarch64" ]; then
    LIB_PATH=$SYSROOT/usr/lib/aarch64-linux-android
    CLANG_LIB_ARCH=$CLANG_LIB/aarch64
elif [ "$ARCH" = "arm" ]; then
    LIB_PATH=$SYSROOT/usr/lib/arm-linux-androideabi
    CLANG_LIB_ARCH=$CLANG_LIB/arm
else
    exec /data/data/com.termux/files/usr/bin/clang "$@"
fi

exec /data/data/com.termux/files/usr/bin/clang -L$LIB_PATH -L$CLANG_LIB_ARCH "$@"
EOF
chmod +x $PREBUILT/bin/clang

cat > $PREBUILT/bin/clang++ << 'EOF'
#!/bin/sh
NDK=/data/data/com.termux/files/usr/opt/android-sdk/ndk/27.0.12077973
SYSROOT=$NDK/toolchains/llvm/prebuilt/linux-x86_64/sysroot
CLANG_LIB=$NDK/toolchains/llvm/prebuilt/linux-x86_64/lib/clang/18/lib/linux

ARCH=""
for arg in "$@"; do
    case "$arg" in
        --target=aarch64*) ARCH="aarch64" ;;
        --target=arm*) ARCH="arm" ;;
    esac
done

if [ "$ARCH" = "aarch64" ]; then
    LIB_PATH=$SYSROOT/usr/lib/aarch64-linux-android
    CLANG_LIB_ARCH=$CLANG_LIB/aarch64
elif [ "$ARCH" = "arm" ]; then
    LIB_PATH=$SYSROOT/usr/lib/arm-linux-androideabi
    CLANG_LIB_ARCH=$CLANG_LIB/arm
else
    exec /data/data/com.termux/files/usr/bin/clang++ "$@"
fi

exec /data/data/com.termux/files/usr/bin/clang++ -L$LIB_PATH -L$CLANG_LIB_ARCH "$@"
EOF
chmod +x $PREBUILT/bin/clang++
echo "  ✓ clang wrappers created"

# 4. 修補 NDK toolchain cmake
echo "[4/12] Patching NDK toolchain cmake..."
TOOLCHAIN=$NDK/build/cmake/android-legacy.toolchain.cmake
if grep -q 'list(APPEND ANDROID_LINKER_FLAGS "-static-libstdc++")' $TOOLCHAIN 2>/dev/null; then
    sed -i 's/list(APPEND ANDROID_LINKER_FLAGS "-static-libstdc++")/# Disabled for Termux: list(APPEND ANDROID_LINKER_FLAGS "-static-libstdc++")/' $TOOLCHAIN
    echo "  ✓ Toolchain patched"
else
    echo "  ✓ Toolchain already patched or not found"
fi

# 5. 創建 sysroot 符號連結
echo "[5/12] Creating sysroot symlinks..."
ln -sf linux-x86_64/sysroot $PREBUILT/sysroot 2>/dev/null || true
ln -sf 18 $PREBUILT/linux-x86_64/lib/clang/21 2>/dev/null || true

SYSROOT_LIB=$SYSROOT/usr/lib
ln -sf aarch64-linux-android $SYSROOT_LIB/aarch64-none-linux-android 2>/dev/null || true
ln -sf aarch64-linux-android/24 $SYSROOT_LIB/aarch64-none-linux-android24 2>/dev/null || true
echo "  ✓ Sysroot symlinks created"

# 6. 複製運行時庫
echo "[6/12] Copying runtime libraries..."
for f in libunwind.a libatomic.a; do
    ln -sf $CLANG_LIB/aarch64/$f $SYSROOT_LIB/aarch64-linux-android/$f 2>/dev/null || true
    ln -sf $CLANG_LIB/aarch64/$f $SYSROOT_LIB/aarch64-linux-android/24/$f 2>/dev/null || true
    ln -sf $CLANG_LIB/arm/$f $SYSROOT_LIB/arm-linux-androideabi/$f 2>/dev/null || true
    ln -sf $CLANG_LIB/arm/$f $SYSROOT_LIB/arm-linux-androideabi/24/$f 2>/dev/null || true
done
echo "  ✓ Runtime libraries linked"

# 7. 創建 build-tools 符號連結
echo "[7/12] Creating build-tools symlinks..."
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
    echo "Manifest-Version: 1.0" > /tmp/MANIFEST.MF
    jar cfm $BUILD_TOOLS/core-lambda-stubs.jar /tmp/MANIFEST.MF
    rm /tmp/MANIFEST.MF
fi

# d8.jar and dx.jar
ln -sf /data/data/com.termux/files/usr/share/java/d8.jar $BUILD_TOOLS/lib/d8.jar 2>/dev/null || true
ln -sf /data/data/com.termux/files/usr/share/java/d8.jar $BUILD_TOOLS/lib/dx.jar 2>/dev/null || true

echo "  ✓ Build-tools symlinks created"

# 8. 安裝 cmdline-tools (讓 flutter 檢測 Android 設備)
echo "[8/12] Installing cmdline-tools..."
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
echo "[9/12] Creating platform-tools symlinks..."
mkdir -p $ANDROID_SDK/platform-tools
ln -sf /data/data/com.termux/files/usr/bin/adb $ANDROID_SDK/platform-tools/adb 2>/dev/null || true
ln -sf /data/data/com.termux/files/usr/bin/fastboot $ANDROID_SDK/platform-tools/fastboot 2>/dev/null || true
echo "  ✓ platform-tools symlinks created"

# 10. 接受 Android licenses
echo "[10/12] Accepting Android licenses..."
mkdir -p $ANDROID_SDK/licenses
echo -e "\n24333f8a63b6825ea9c5514f83c2829b004d1fee" > $ANDROID_SDK/licenses/android-sdk-license
echo -e "\n84831b9409646a918e30573bab4c9c91346d8abd" > $ANDROID_SDK/licenses/android-sdk-preview-license
echo "  ✓ Android licenses accepted"

# 11. 複製 VM snapshots (for debug mode)
echo "[11/12] Checking engine artifacts..."
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
