# Flutter Termux 完整構建指南

本文檔說明如何從零開始構建包含 Android gen_snapshot 的 Flutter deb 包。

## 構建環境需求

- Windows 11 + WSL2 (Ubuntu 22.04+)
- 至少 100GB 可用磁碟空間
- 至少 16GB RAM
- 穩定的網路連接

## 完整構建流程

### 1. 安裝 WSL 依賴

```bash
# 在 Ubuntu WSL 中執行
sudo apt update
sudo apt install -y git curl python3 python3-pip ninja-build pkg-config
pip3 install fire loguru toml pyyaml
```

### 2. 設置 depot_tools

```bash
cd ~
git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
export PATH="$HOME/depot_tools:$PATH"
echo 'export PATH="$HOME/depot_tools:$PATH"' >> ~/.bashrc
```

### 3. 克隆專案

```bash
mkdir -p ~/projects
cd ~/projects
git clone https://github.com/ImL1s/termux-flutter-wsl.git termux-flutter
cd termux-flutter
```

### 4. 同步 Flutter Engine 源碼

```bash
python3 build.py clone   # 克隆 Flutter
python3 build.py sync    # 同步依賴（約 30GB，需要數小時）
```

### 5. 應用補丁

```bash
python3 build.py patch_engine
```

### 6. 構建 Sysroot

```bash
python3 build.py sysroot --arch=arm64
```

### 7. 一鍵構建（推薦）

```bash
# 新增：一個命令構建所有組件
python3 build.py build_all --arch=arm64
```

這個命令會自動完成：
1. 配置 Linux debug 構建
2. 編譯 Flutter engine
3. 編譯 dart 二進制（關鍵！）
4. 配置 Android gen_snapshot 構建
5. 編譯 Android gen_snapshot
6. 打包 deb

或手動分步構建：

```bash
# Linux debug (用於 flutter run -d linux)
python3 build.py configure --arch=arm64 --mode=debug
python3 build.py build --arch=arm64 --mode=debug
python3 build.py build_dart --arch=arm64 --mode=debug  # 重要：單獨編譯 dart

# Android gen_snapshot (用於 flutter build apk)
python3 build.py configure_android --arch=arm64 --mode=release
python3 build.py build_android_gen_snapshot --arch=arm64 --mode=release

# 打包 deb
python3 build.py debuild --arch=arm64
```

### 8. 產出檔案

構建完成後，deb 包位於：
```
release/flutter_3.35.0_aarch64.deb
```

## deb 包內容

| 組件 | 路徑 | 用途 |
|------|------|------|
| Flutter SDK | /data/data/com.termux/files/usr/opt/flutter | 主程式 |
| dart 二進制 | .../dart-sdk/bin/dart | flutter 命令核心 |
| Linux gen_snapshot | .../engine/linux-arm64/gen_snapshot | flutter run -d linux |
| Android gen_snapshot | .../engine/android-arm64-release/linux-arm64/gen_snapshot | flutter build apk |

## 驗證構建

```bash
# 檢查所有必要檔案
ls -la flutter/engine/src/out/linux_debug_arm64/dart-sdk/bin/dart  # 關鍵！
ls -la flutter/engine/src/out/linux_debug_arm64/gen_snapshot
ls -la flutter/engine/src/out/android_release_arm64/clang_arm64/gen_snapshot
```

## 問題分析與解決 (2025-12-28)

### 原始問題
- `flutter run -d linux` ✓ 可以運行
- `flutter build apk --release` ✗ 失敗（dart 版本問題）

### 根本原因
**`ninja flutter` 不會編譯 dart 二進制！**

deb 包中 `bin/cache/dart-sdk/bin/dart` 二進制文件缺失，導致：
- flutter 命令無法正確執行
- gen_snapshot 版本不匹配錯誤

### 解決方案
新增 `build_dart` 方法，單獨編譯 dart 二進制並複製到 dart-sdk/bin/：

```bash
python3 build.py build_dart --arch=arm64 --mode=debug
```

或使用一鍵構建：

```bash
python3 build.py build_all --arch=arm64
```

### deb 包內容確認（修復後）
```
✓ bin/cache/dart-sdk/bin/dart (102MB)
✓ bin/cache/artifacts/engine/linux-arm64/gen_snapshot (6.9MB)
✓ bin/cache/artifacts/engine/android-arm64-release/linux-arm64/gen_snapshot (6.4MB)
```

## 常見問題

### 編譯失敗：ninja 錯誤
確保補丁已正確應用：
```bash
cd flutter/engine/src/flutter
git diff shell/platform/embedder/BUILD.gn
```

### 缺少依賴
```bash
python3 build.py sysroot --arch=arm64
```

### vpython3 not found
確保 depot_tools 在 PATH 中：
```bash
export PATH="$HOME/depot_tools:$PATH"
```

### 磁碟空間不足
Flutter Engine 源碼約 30GB，編譯產物約 20GB，至少需要 60GB 空間。

## Termux 使用前設置 (2025-12-28 更新)

### 額外需要編譯的組件

除了基本構建外，`flutter build apk` 還需要以下組件：

1. **dartaotruntime_product** - 用於運行 AOT snapshots
2. **impellerc** - 用於編譯 shaders

```bash
# 在 WSL 中編譯額外組件
export PATH="$HOME/depot_tools:$PATH"
cd flutter

# 編譯 impellerc
ninja -C engine/src/out/linux_debug_arm64 flutter/impeller/compiler:impellerc

# 複製 dartaotruntime_product 到 dart-sdk
cp engine/src/out/linux_debug_arm64/dartaotruntime_product engine/src/out/linux_debug_arm64/dart-sdk/bin/dartaotruntime

# 重新打包 deb
cd ..
python3 build.py debuild --arch=arm64
```

### Termux 環境配置

安裝 deb 後，還需要做以下設置才能運行 `flutter build apk`：

#### 1. 安裝 ARM64 NDK
標準 Android NDK 是 x86_64，無法在 Termux 運行。需要使用 lzhiyong 的 ARM64 NDK：

```bash
# 下載 ARM64 NDK (已提供在專案中)
# 或從 https://github.com/AntonioCiolworker/termux-ndk 下載
pkg install android-ndk
```

#### 2. 配置項目使用 ARM64 NDK
在 Flutter 專案的 `android/local.properties` 中添加：

```properties
ndk.dir=/data/data/com.termux/files/usr/opt/android-ndk
```

在 `android/app/build.gradle.kts` 中設置正確的 NDK 版本：

```kotlin
ndkVersion = "27.1.12297006"  // 或你的 NDK 版本
```

#### 3. 修復 CMake
Android SDK 的 CMake 是 x86_64，需要用 Termux 的：

```bash
# 安裝 Termux cmake 和 ninja
pkg install cmake ninja

# 替換 SDK CMake
rm -rf $ANDROID_HOME/cmake/3.22.1/bin
mkdir -p $ANDROID_HOME/cmake/3.22.1/bin
ln -s /data/data/com.termux/files/usr/bin/cmake $ANDROID_HOME/cmake/3.22.1/bin/cmake
ln -s /data/data/com.termux/files/usr/bin/ninja $ANDROID_HOME/cmake/3.22.1/bin/ninja
```

#### 4. 修復 AAPT2
Gradle 下載的 AAPT2 是 x86_64，需要用 SDK build-tools 中的 ARM64 版本：

```bash
# 找到 Gradle 緩存的 aapt2 位置
AAPT2_CACHE=~/.gradle/caches/*/transforms/*/transformed/aapt2-*-linux/aapt2

# 替換為 ARM64 版本
rm -f $AAPT2_CACHE
ln -s $ANDROID_HOME/build-tools/35.0.0/aapt2 $AAPT2_CACHE
```

#### 5. 複製 flutter_patched_sdk_product
`flutter build apk --release` 需要 product SDK：

```bash
mkdir -p $FLUTTER_ROOT/bin/cache/artifacts/engine/common/flutter_patched_sdk_product
cp -r $FLUTTER_ROOT/bin/cache/artifacts/engine/common/flutter_patched_sdk/* \
      $FLUTTER_ROOT/bin/cache/artifacts/engine/common/flutter_patched_sdk_product/
```

### 完整構建命令

```bash
source /data/data/com.termux/files/usr/etc/profile.d/flutter.sh
export ANDROID_HOME=/data/data/com.termux/files/usr/opt/android-sdk
export ANDROID_SDK_ROOT=$ANDROID_HOME
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools

cd your_flutter_project
flutter build apk --release --target-platform android-arm64 --no-tree-shake-icons
```

### 注意事項

- `--target-platform android-arm64`：只構建 ARM64，跳過 arm 和 x64（避免需要額外的 gen_snapshot）
- `--no-tree-shake-icons`：跳過圖標優化（避免需要 const_finder.dart.snapshot）
- 首次構建需要下載 Gradle 依賴，約需 5-10 分鐘
- APK 輸出在 `build/app/outputs/flutter-apk/app-release.apk`
