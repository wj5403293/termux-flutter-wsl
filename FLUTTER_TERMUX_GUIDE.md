# 🚀 Flutter on Termux 完整安裝指南

> **最後更新**: 2024年12月  
> **整合方案**: 融合 mumumusuc/termux-flutter + Android 14 修復 + proot-distro 備選

---

## 📊 方案總覽

| 方案 | Flutter 版本 | Android 相容性 | 複雜度 | 推薦度 |
|------|--------------|----------------|--------|--------|
| **termux-flutter** | 3.29.2 | ⚠️ 需修復 Android 14+ | ⭐ 簡單 | 🥇 首選 |
| **proot-distro** | 最新版 | ✅ 全相容 | ⭐⭐⭐ 複雜 | 🥈 備選 |

---

## 🥇 方案一：termux-flutter（推薦）

### 前置條件
- Android 設備（aarch64/arm64 架構）
- 從 F-Droid 安裝最新版 Termux
- 至少 4GB 可用儲存空間

### Step 1: 修復 Android 14+ 相容性問題

> [!CAUTION]
> **Android 14+ 的「Phantom Process Killer」會強制終止 Termux 進程！**
> 必須先執行此步驟，否則 Flutter 編譯會被中斷。

#### 方法 A：開發者選項（最簡單）

```bash
# 1. 啟用開發者選項
#    設定 → 關於手機 → 連續點擊「版本號碼」7次

# 2. 進入開發者選項
#    設定 → 系統 → 開發者選項

# 3. 找到並啟用「停用子程序限制」(Disable child process restrictions)
```

#### 方法 B：ADB 命令（如果方法 A 無此選項）

```bash
# 在 Termux 中執行（無需電腦）

# 1. 安裝 ADB 工具
pkg update && pkg upgrade -y
pkg install android-tools

# 2. 啟用無線調試
#    開發者選項 → 無線偵錯 → 開啟
#    記下顯示的 IP 和配對碼

# 3. 配對並連接
adb pair <IP>:<配對埠>
# 輸入配對碼

adb connect <IP>:<連接埠>

# 4. 禁用 Phantom Process Killer
adb shell "settings put global settings_enable_monitor_phantom_procs false"
adb shell "device_config set_sync_disabled_for_tests persistent"
adb shell "device_config put activity_manager max_phantom_processes 2147483647"
```

---

### Step 2: 安裝 Flutter

```bash
# 1. 更新 Termux
pkg update && pkg upgrade -y

# 2. 安裝 x11-repo（用於預覽 App）
pkg install x11-repo

# 3. 下載 Flutter .deb 安裝包
# 前往: https://github.com/mumumusuc/termux-flutter/releases
# 下載最新版本的 flutter-xxx.deb

# 4. 安裝 Flutter
apt install ~/storage/downloads/flutter-*.deb
# 或指定路徑
apt install /path/to/flutter.deb

# 5. 驗證安裝
flutter doctor -v
```

---

### Step 3: 安裝 Android SDK（編譯 APK 用）

```bash
# 下載 termux-android-sdk
# 前往: https://github.com/mumumusuc/termux-android-sdk/releases

# 安裝
apt install /path/to/android-sdk.deb

# 接受授權
flutter doctor --android-licenses
```

---

### Step 4: 開發與預覽

#### 預覽 Flutter App（使用 Termux:X11）

```bash
# 1. 安裝 Termux:X11
# 從 GitHub 下載: https://github.com/termux/termux-x11/releases

# 2. 啟動 X11 服務並運行 App
export DISPLAY=:0
termux-x11 :0 >/dev/null 2>&1 &
flutter run -d linux
```

#### 編譯 Android APK

```bash
# 創建新專案
flutter create my_app
cd my_app

# 編譯 Release APK
flutter build apk --release --target-platform android-arm64

# APK 位置: build/app/outputs/flutter-apk/app-release.apk
```

#### 在手機上熱重載測試

```bash
# 1. 啟用手機的 USB/無線偵錯

# 2. 連接 ADB（如果還沒連接）
adb connect <IP>:<埠>

# 3. 列出設備
flutter devices

# 4. 運行（支援熱重載）
flutter run -d <device_id>
```

---

## 🥈 方案二：proot-distro（獲取最新 Flutter）

> 如果需要最新版 Flutter（3.35+）或 termux-flutter 不適用，使用此方案。

### 完整安裝腳本

```bash
#!/bin/bash
# Flutter on Termux via proot-distro - 一鍵安裝腳本

echo "=== Step 1: 安裝 proot-distro ==="
pkg update && pkg upgrade -y
pkg install proot-distro wget -y

echo "=== Step 2: 安裝 Debian ==="
proot-distro install debian

echo "=== Step 3: 進入 Debian 並安裝依賴 ==="
proot-distro login debian -- bash -c '
apt update && apt upgrade -y
apt install -y wget unzip git curl file xz-utils zip \
    openjdk-17-jdk clang cmake ninja-build pkg-config \
    libgtk-3-dev libglu1-mesa

echo "=== Step 4: 安裝 Flutter SDK ==="
cd ~
git clone https://github.com/flutter/flutter.git -b stable --depth 1
echo "export PATH=\"\$PATH:\$HOME/flutter/bin\"" >> ~/.bashrc
source ~/.bashrc

echo "=== Step 5: 驗證安裝 ==="
flutter doctor -v
'

echo "=== 安裝完成！==="
echo "使用 proot-distro login debian 進入環境"
```

### 使用方式

```bash
# 保存上面的腳本為 install_flutter.sh
chmod +x install_flutter.sh
./install_flutter.sh

# 之後每次進入開發環境
proot-distro login debian

# 在 Debian 中使用 Flutter
flutter create my_app
cd my_app
flutter run -d web-server --web-port 8080
# 瀏覽器訪問: localhost:8080
```

---

## 📱 快速參考

### 常用命令

| 命令 | 說明 |
|------|------|
| `flutter doctor` | 檢查環境 |
| `flutter create <name>` | 創建新專案 |
| `flutter run -d linux` | 運行 Linux 預覽 |
| `flutter run -d web-server` | 運行 Web 預覽 |
| `flutter build apk` | 編譯 APK |
| `flutter devices` | 列出設備 |

### 疑難排解

| 問題 | 解決方案 |
|------|----------|
| 進程被終止 (signal 9) | 執行 Step 1 禁用 Phantom Process Killer |
| 無法編譯 Release APK | 使用 `--debug` 或改用 proot-distro 方案 |
| flutter doctor 警告 | 根據提示安裝缺少的組件 |
| X11 無法啟動 | 確認已安裝 Termux:X11 App |

---

## 🔗 相關資源

- [mumumusuc/termux-flutter](https://github.com/mumumusuc/termux-flutter) - 修改版 Flutter Engine
- [termux-android-sdk](https://github.com/mumumusuc/termux-android-sdk) - Android SDK for Termux
- [Termux:X11](https://github.com/termux/termux-x11) - X11 預覽支援
- [proot-distro](https://github.com/termux/proot-distro) - Linux 發行版

---

> 💡 **建議**: 對於日常開發，推薦使用 **方案一**（termux-flutter），因為它更輕量、原生運行效能更好。如果需要最新版 Flutter 或遇到相容性問題，再考慮 **方案二**（proot-distro）。
