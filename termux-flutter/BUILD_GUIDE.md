# 🔧 編譯 Flutter 3.35+ for Termux（支援 Android 16）

> **目標**: 從源碼編譯 termux-flutter，升級到 Flutter 3.35+，支援 Android 16

---

## 📋 專案結構

```
termux-flutter/
├── build.py          # 主編譯腳本
├── build.toml        # 編譯配置（Flutter 版本、NDK、架構）
├── .gclient          # gclient 同步配置
├── patches/
│   ├── engine.patch  # Flutter Engine 修補（Termux toolchain）
│   ├── dart.patch    # Dart 平台偵測修補
│   └── skia.patch    # Skia 平台偵測修補
├── sysroot.py        # Termux sysroot 下載器
└── package.py        # .deb 打包腳本
```

---

## 🖥️ 環境需求

### 硬體
- **CPU**: x86_64 Linux（交叉編譯到 ARM64）
- **RAM**: 16GB+
- **磁碟**: 100GB+

### 軟體安裝（Ubuntu 22.04+）

```bash
sudo apt update && sudo apt install -y \
    git python3 python3-pip python3-venv \
    clang cmake ninja-build pkg-config \
    libgtk-3-dev libglib2.0-dev curl wget unzip

# 安裝 Android NDK r26+
# 下載: https://developer.android.com/ndk/downloads
export ANDROID_NDK=/path/to/android-ndk-r26
```

---

## 🚀 快速開始

### Step 1: 設置環境

```bash
cd termux-flutter
export PATH="$PATH:$(pwd)/depot_tools"
pip install -r requirements.txt
```

### Step 2: 修改版本配置

編輯 `build.toml`：

```toml
[flutter]
tag = '3.35.0'  # 更新到目標版本

[ndk]
api = 35  # Android 15/16 = API 35
```

### Step 3: 編譯

```bash
# 完整編譯（自動執行所有步驟）
python build.py

# 或分步執行：
python build.py clone      # 克隆 Flutter
python build.py sync       # 同步引擎 + 應用 patches
python build.py configure arm64 debug
python build.py build arm64 debug
python build.py debuild arm64
```

### Step 4: 輸出

```
./flutter_3.35.0_aarch64.deb
```

---

## 🔨 Patches 說明

### engine.patch（最複雜）

新增 Termux toolchain 配置：
- `//build/config/termux/BUILD.gn` - 編譯器選項
- `//build/config/termux/termux.gni` - 變數定義
- `//build/toolchain/termux/BUILD.gn` - 工具鏈定義

關鍵變數：
- `is_termux` - 是否為 Termux 目標
- `termux_api_level` - Android API level
- `custom_sysroot` - Termux sysroot 路徑

### dart.patch

讓 Dart 識別 `__TERMUX__` 為 Linux 而非 Android：
```diff
-#if defined(__ANDROID__)
+#if defined(__ANDROID__) && !defined(__TERMUX__)
```

### skia.patch

讓 Skia 識別 `__TERMUX__` 為 Linux：
```diff
-#elif defined(ANDROID) || defined(__ANDROID__)
+#elif (defined(ANDROID) || defined(__ANDROID__)) && !defined(__TERMUX__)
```

---

## ⚠️ 升級 Patches 注意事項

當 Flutter 版本更新時，patches 可能需要調整：

### 檢查衝突

```bash
cd flutter/engine/src
git apply --check ../../../patches/engine.patch
```

### 手動修復

```bash
# 使用 3-way merge
git apply --3way ../../../patches/engine.patch

# 解決衝突後重新生成
git diff > ../../../patches/engine.patch.new
```

### 需要檢查的檔案

| Patch | 需要檢查的檔案 |
|-------|---------------|
| engine.patch | `build/config/BUILDCONFIG.gn`, `build/config/sysroot.gni` |
| dart.patch | `third_party/dart/runtime/platform/globals.h` |
| skia.patch | `third_party/skia/include/private/base/SkFeatures.h` |

---

## 🐛 疑難排解

### Patch 失敗
```bash
# 查看失敗原因
git apply --check patches/engine.patch 2>&1
```

### 編譯記憶體不足
```bash
# 限制並行數
python build.py build arm64 debug --jobs=4
```

### NDK 找不到
```bash
export ANDROID_NDK=/path/to/ndk
# 或在 build.toml 中設置 path
```

---

## 📱 Android 16 支援

```toml
[ndk]
api = 35  # Android 15/16
```

安裝後需禁用 Phantom Process Killer：
```bash
adb shell "settings put global settings_enable_monitor_phantom_procs false"
```
