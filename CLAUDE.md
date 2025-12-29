# Flutter Termux 專案指南

這是一個用於在 Termux (Android ARM64) 上構建和運行 Flutter 的專案。

## 專案概述

將 Flutter SDK 交叉編譯為可以在 Termux (Android/Bionic ARM64) 上運行的版本，支援：
- `flutter run -d linux` - 在 Termux X11 環境運行 Linux 桌面應用
- `flutter build apk` - 在 Termux 中構建 Android APK

## 關鍵檔案

| 檔案 | 用途 |
|------|------|
| `build.py` | 主構建腳本，包含所有構建命令 |
| `build.toml` | 構建配置（Flutter 版本、路徑等） |
| `package.yaml` | deb 包定義和資源映射 |
| `patches/engine.patch` | Flutter Engine 的 Termux 適配補丁 |
| `patches/dart.patch` | Dart SDK 的補丁 |
| `BUILD_GUIDE.md` | 詳細構建指南和常見問題 |

## 常用命令

```bash
# 完整構建（推薦）
python3 build.py build_all --arch=arm64

# 分步構建
python3 build.py configure --arch=arm64 --mode=debug
python3 build.py build --arch=arm64 --mode=debug
python3 build.py build_dart --arch=arm64 --mode=debug

# Android gen_snapshot（用於 flutter build apk）
python3 build.py configure_android --arch=arm64 --mode=release
python3 build.py build_android_gen_snapshot --arch=arm64 --mode=release

# 打包 deb
python3 build.py debuild --arch=arm64
```

## 重要構建目標

在 `build.py` 的 `build()` 方法中，ninja 目標包括：
- `flutter` - 核心 Flutter 引擎
- `flutter/shell/platform/linux:flutter_gtk` - Linux 桌面支援（libflutter_linux_gtk.so）

**注意**：`flutter_gtk` 目標必須啟用，否則 `flutter build linux` 會失敗。

## 構建產物位置

```
flutter/engine/src/out/
├── linux_debug_arm64/
│   ├── dart-sdk/bin/dart          # Dart 二進制
│   ├── gen_snapshot              # Linux gen_snapshot
│   └── libflutter_linux_gtk.so   # Linux GTK 庫（106MB）
└── android_release_arm64/
    └── clang_arm64/gen_snapshot  # Android gen_snapshot
```

## 已知問題與解決方案

詳見 `BUILD_GUIDE.md` 的「構建常見問題與解決方案 (坑)」章節，包括：
1. vpython3 not found - 需創建 wrapper script
2. openjdk-17 不存在 - 使用 openjdk-21 + 強制配置
3. libflutter_linux_gtk.so 缺失 - 啟用 flutter_gtk 目標
4. CRLF 換行符問題 - Windows/WSL 環境
5. dartaotruntime 缺失
6. ADB 遠程安裝失敗 - 需啟用 allow-external-apps

## 測試設備

- Termux 平板：設備 ID `R52Y100VWGM`
- **SSH 連接（推薦）**：`ssh -p 8022 <IP>` （比 ADB broadcast 更可靠）
- ADB 連接：`adb -s R52Y100VWGM shell`
- 獲取 IP：`adb -s R52Y100VWGM shell "ip addr show wlan0 | grep inet"`

## 部署步驟

**重要**：在 Git Bash/MINGW 中 adb push 路徑會被錯誤轉換。必須用 PowerShell：

```powershell
# 1. 傳輸 deb 到 Termux（必須用 PowerShell！）
powershell -Command "adb -s R52Y100VWGM push 'D:\flutter_temp.deb' '/data/local/tmp/flutter_new.deb'"

# 2. 在 Termux 中安裝
pkg install x11-repo
dpkg -i /sdcard/Download/flutter_3.35.0_aarch64.deb
apt-get install -f

# 3. 測試
source /data/data/com.termux/files/usr/etc/profile.d/flutter.sh
flutter doctor -v
flutter build apk --release
```

## WSL 構建環境

```
主機: Windows + WSL2 Ubuntu
CPU: AMD Ryzen 9950X3D (16核32線程)
構建目錄: /home/iml1s/projects/termux-flutter/
Engine 源碼: /home/iml1s/projects/termux-flutter/flutter/engine/src/
構建輸出: /home/iml1s/projects/termux-flutter/flutter/engine/src/out/
推薦並行數: -j24 (留 8 線程給系統)
```

### Windows PATH 污染問題

**問題**：從 Windows 呼叫 `wsl` 時，Windows PATH 會傳遞到 WSL，導致 `/bin/sh` 語法錯誤（因為 "Program Files (x86)" 中的括號）。

**解決方案**：

1. 在 WSL 創建 `/etc/wsl.conf`：
```ini
[interop]
appendWindowsPath = false
```

2. 創建 vpython3 wrapper（ninja 需要）：
```bash
# 在 depot_tools 目錄創建
echo '#!/bin/bash
exec python3 "$@"' > /home/iml1s/projects/termux-flutter/depot_tools/vpython3
chmod +x /home/iml1s/projects/termux-flutter/depot_tools/vpython3
```

3. 使用 PowerShell 而非 Git Bash 執行 WSL 命令（避免路徑轉換問題）

4. 構建命令需設置乾淨 PATH：
```bash
# 從 PowerShell 執行
powershell -Command "wsl --exec bash -c 'export PATH=/home/iml1s/projects/termux-flutter/depot_tools:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin; cd /home/iml1s/projects/termux-flutter/flutter/engine/src/out/linux_release_arm64 && ninja flutter flutter/shell/platform/linux:flutter_gtk -j24'"
```

構建命令（在 WSL 中）：
```bash
cd /home/iml1s/projects/termux-flutter
python3 build.py build --arch=arm64 --mode=debug --jobs=24
python3 build.py build_dart --arch=arm64 --mode=debug --jobs=24
python3 build.py debuild --arch=arm64
```

## 版本資訊

- Flutter: 3.35.0
- Engine: 對應 Flutter 3.35.0 的 engine commit
- 目標平台: aarch64 (ARM64)

## 當前功能狀態 (2025-12-29 全部驗證通過)

| 功能 | 狀態 | 需求 |
|------|------|------|
| `flutter doctor` | ✅ 已驗證 | 僅需 deb 安裝 |
| `flutter create` | ✅ 已驗證 | 僅需 deb 安裝 |
| `flutter build linux --debug` | ✅ 已驗證 | 需要: gtk3, x11-repo |
| `flutter build linux --release` | ✅ 已驗證 | 需要: gtk3, x11-repo |
| `flutter build linux --profile` | ✅ 已驗證 | 需要: gtk3, x11-repo |
| `flutter build apk --release` | ✅ 已驗證 (151MB) | 需要: post_install.sh + 專案配置 compileSdk=34 |
| `flutter build apk --debug` | ✅ 已驗證 (591MB) | 需要: post_install.sh + vm_isolate_snapshot.bin + 專案配置 |
| `flutter build apk --profile` | ✅ 已驗證 (165MB) | 需要: post_install.sh + profile gen_snapshot + 專案配置 |
| `flutter run -d linux --debug` | ✅ 已驗證 | 需要: termux-x11-nightly, DISPLAY=:0 |
| `flutter run -d linux --release` | ✅ 已驗證 | 需要: termux-x11-nightly, DISPLAY=:0 |
| APK 安裝運行 | ✅ 已驗證 | 需要: 從 PC 用 `adb install` (Termux 內 pm install 權限不足) |

**APK 構建前置條件（安裝 deb 後執行 post_install.sh）：**
1. 安裝 Android API 34（aapt2 bug workaround）
2. 修改 FlutterPluginConstants.kt（僅構建 ARM64）
3. 創建 NDK clang wrapper
4. 修補 android-legacy.toolchain.cmake
5. 創建 sysroot 符號連結
6. 每個專案設置 compileSdk=34, targetSdk=34, ndk.abiFilters=arm64-v8a

詳見 `BUILD_GUIDE.md` 的「Termux APK 構建完整設置指南」章節。

## 更新日誌

### 2025-12-29 v4
- ✅ **全部功能測試通過！**
- ✅ flutter build apk --debug 正常 (需要 vm_isolate_snapshot.bin)
- ✅ flutter build apk --profile 正常 (需要 profile gen_snapshot)
- ✅ APK 安裝並運行正常
- 📝 創建 post_install.sh 自動配置腳本
- 📝 更新 package.yaml 包含所有必要 artifacts
- 📝 完整記錄所有 APK 構建配置步驟

### 2025-12-29 v3
- ✅ 完成所有 Linux build 模式測試 (debug/release/profile)
- ✅ 完成 APK release build 測試
- 添加 WSL 構建解決方案：Windows PATH 污染問題
- 添加 vpython3 wrapper 到 depot_tools
- 文檔化 APK 構建前置條件 (ARM64 NDK, AAPT2 替換)

### 2025-12-29 v2
- 完成功能測試：flutter doctor ✅, flutter build apk ✅
- 文檔化 debug/release 模式限制
- 文檔化 sysroot 衝突問題（glibc vs bionic headers）

### 2025-12-29 v1
- 修復 TLS segment underaligned 問題（Bionic linker）
- **重要**：deb 打包時必須使用最新構建的 dart，否則會包含錯誤版本
- 添加 `termux_ndk_path` 到 configure 方法

### 2025-12-28
- 修復 `flutter build apk --release` 不再需要 `--target-platform android-arm64`
- 新增 flutter_gtk 構建支援 `flutter build linux`
- 更新依賴從 openjdk-17 到 openjdk-21
- 完善構建文檔
