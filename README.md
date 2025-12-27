<p align="center">
  <img src="assets/banner.png" alt="termux-flutter-wsl" width="800"/>
</p>

<h1 align="center">termux-flutter-wsl</h1>

<p align="center">
  <strong>在 WSL 環境下為 Termux 交叉編譯 Flutter SDK</strong>
</p>

<p align="center">
  <strong>中文</strong> | <a href="README_EN.md">English</a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.35.0-02569B?logo=flutter" alt="Flutter Version"/>
  <img src="https://img.shields.io/badge/Platform-ARM64-green" alt="Platform"/>
  <img src="https://img.shields.io/badge/Build-WSL-0078D6?logo=windows" alt="WSL"/>
  <img src="https://img.shields.io/badge/NDK-r27d-orange" alt="NDK"/>
  <img src="https://img.shields.io/badge/License-GPL--3.0-blue" alt="License"/>
</p>

<p align="center">
  <em>🍴 Forked from <a href="https://github.com/mumumusuc/termux-flutter">mumumusuc/termux-flutter</a></em>
</p>

---

## 📖 專案簡介

本專案基於 [mumumusuc/termux-flutter](https://github.com/mumumusuc/termux-flutter)，實現了在 **WSL (Windows Subsystem for Linux)** 環境下為 Termux 交叉編譯 Flutter Engine 的完整解決方案。

### 🆚 與原專案的差異

| 項目 | 原專案 | 本專案 |
|---|---|---|
| 構建環境 | Linux / Termux 原生 | **WSL (Windows)** |
| Flutter 版本 | 3.29.2 | **3.35.0** |
| Android 兼容性 | ❌ 不支援 Android 14+ | ✅ **支援 Android 16** |
| 額外修復 | - | **`-llog`, `-lm` 依賴** |
| 文檔 | 基礎 | **完整中文指南** |

> ✅ **已驗證**：本專案已在 Android 16 設備上成功運行 Flutter 應用！

### ✨ 主要特色

- 🪟 在 Windows WSL 環境下完成交叉編譯
- 🔧 修復了 Android 日誌符號缺失問題
- 📦 成功產出 `flutter_3.35.0_aarch64.deb` (541MB)
- 🤖 完整的自動化構建流程

---

## 🚀 快速開始

### 一鍵安裝（推薦）

在 Termux 中執行以下命令，自動安裝 Flutter + Android SDK：

```bash
curl -sL https://raw.githubusercontent.com/ImL1s/termux-flutter-wsl/master/install_termux_flutter.sh | bash
```

> 此腳本會自動安裝 Flutter 3.35.0、Android SDK 35.0.0、JDK 17，並配置環境變數。

### 手動安裝

```bash
# 1. 安裝基礎依賴
pkg update && pkg install x11-repo wget openjdk-17

# 2. 下載安裝包
wget https://github.com/ImL1s/termux-flutter-wsl/releases/download/v3.35.0/flutter_3.35.0_aarch64.deb

# 3. 安裝與驗證
dpkg -i flutter_3.35.0_aarch64.deb
flutter --version
```

### 自行編譯（WSL 環境）

```bash
# 一鍵構建
./build_termux_flutter.sh

# 或分步驟執行
python3 build.py sysroot --arch=arm64    # 組裝 Termux 運行時依賴
python3 build.py configure --arch=arm64 --mode=debug
python3 build.py build --arch=arm64 --mode=debug
python3 build.py debuild --arch=arm64    # 打包 .deb
```

### 運行 Flutter 應用（使用 Termux:X11）

安裝完成後，你需要 [Termux:X11](https://github.com/termux/termux-x11/releases) 來顯示 GUI 應用。

**安裝 Termux:X11**：從 [GitHub Releases](https://github.com/termux/termux-x11/releases) 或 [F-Droid](https://f-droid.org/packages/com.termux.x11/) 下載 APK 安裝。

```bash
# 1. 在 Termux 中啟動 X11 服務
export DISPLAY=:0
termux-x11 :0 >/dev/null 2>&1 &

# 2. 打開 Termux:X11 App (會顯示黑色畫面，這是正常的)

# 3. 創建並運行 Flutter 專案
flutter create hello_termux
cd hello_termux
flutter run -d linux
```

> 💡 **備選方案**：如果 X11 設置困難，也可以用 Web 模式預覽：
> ```bash
> flutter run -d web-server --web-port=8080
> ```
> 然後在瀏覽器打開 `http://localhost:8080`

### 構建 Android APK

要在 Termux 中執行 `flutter build apk`，需要安裝完整的 Android 開發環境。

#### 步驟 1：安裝依賴

```bash
# 更新套件並安裝 JDK
pkg update
pkg install openjdk-17 git wget
```

#### 步驟 2：安裝 Android SDK

從 [termux-android-sdk](https://github.com/mumumusuc/termux-android-sdk/releases) 下載並安裝：

```bash
wget https://github.com/mumumusuc/termux-android-sdk/releases/download/35.0.0/android-sdk_35.0.0_aarch64.deb
dpkg -i android-sdk_35.0.0_aarch64.deb
```

> 此套件包含 ARM64 原生的 `aapt2`、`build-tools 35.0.0`、`platforms android-34/35` 等必要工具。

#### 步驟 3：配置環境變數

```bash
# 加入 ~/.bashrc 或 ~/.zshrc
export ANDROID_HOME=$PREFIX/opt/android-sdk
export JAVA_HOME=$PREFIX/opt/openjdk
export PATH=$PATH:$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin
```

重新載入設定：
```bash
source ~/.bashrc
```

#### 步驟 4：配置 Flutter

```bash
# 設定 Android SDK 路徑
flutter config --android-sdk $ANDROID_HOME

# 接受 Android 授權
flutter doctor --android-licenses

# 檢查環境
flutter doctor
```

#### 步驟 5：構建 APK

```bash
# 創建專案
flutter create myapp
cd myapp

# 構建 Release APK（針對 ARM64）
flutter build apk --release --target-platform android-arm64

# APK 輸出位置
ls build/app/outputs/flutter-apk/
```

### 部署到 Android 設備

#### 連接 ADB 設備

**方法 A：無線 ADB（同一台手機）**

1. 開啟手機的「開發者選項」→「無線偵錯」
2. 點擊「使用配對碼配對裝置」，記下配對碼和端口

```bash
# 配對（只需一次）
adb pair 127.0.0.1:<配對端口>
# 輸入配對碼

# 連接
adb connect 127.0.0.1:<連接端口>
```

**方法 B：連接其他設備**

```bash
# 確保目標設備已開啟 USB 偵錯或無線偵錯
adb connect <設備IP>:5555
```

#### 運行應用

```bash
# 查看已連接設備
flutter devices

# 部署到 Android 設備
flutter run -d <device_id>

# 或直接安裝 APK
adb install build/app/outputs/flutter-apk/app-release.apk
```

> ⚠️ **注意**：`flutter devices` 預設只顯示 `linux`。安裝 `termux-android-sdk` 後才會出現 Android 設備選項。

---

## 📁 目錄結構

```
termux-flutter-wsl/
├── build.py              # 主構建腳本
├── build.toml            # 構建配置
├── patches/              # 引擎補丁
├── build_termux_flutter.sh  # 一鍵構建腳本
├── README.md             # 中文文檔
├── README_EN.md          # 英文文檔
├── assets/               # 專案資源
└── .agent/workflows/     # 自動化工作流
```

---

## 🔧 技術細節

### 構建環境要求

| 項目 | 版本/配置 |
|---|---|
| Host OS | Windows 11 + WSL (Ubuntu 22.04+) |
| Target | ARM64 Android (Termux) |
| NDK | r27d (API 35) |
| Python | 3.10+ |

### 關鍵修復

我們在原版基礎上做了以下修正以解決 WSL 環境的兼容問題：

```gn
# build/config/termux/BUILD.gn - runtime_library
ldflags = [
  "-stdlib=libstdc++",
  "-Wl,--warn-shared-textrel",
  "-llog",   # 新增：Android 日誌庫
  "-lm",     # 新增：數學庫
]
```

---

## 📋 升級到新版本

1. 修改 `build.toml` 中的 `tag` 為新版本號
2. 執行同步與補丁：
   ```bash
   python3 build.py clone
   python3 build.py sync
   python3 build.py patch_engine  # 如失敗需更新補丁文件
   ```
3. 執行完整構建流程

---

## 🔄 同步上游更新

本專案是 [mumumusuc/termux-flutter](https://github.com/mumumusuc/termux-flutter) 的 Fork。要獲取上游更新：

```bash
git remote add upstream https://github.com/mumumusuc/termux-flutter.git
git fetch upstream
git merge upstream/main
```

**注意**：由於我們為 WSL 修改了部分構建腳本，合併時可能會發生衝突，請手動解決。

---

## 🙏 致謝

- [mumumusuc/termux-flutter](https://github.com/mumumusuc/termux-flutter) - 原始構建工具
- [Flutter](https://flutter.dev/) - Google 的 UI 框架
- [Termux](https://termux.com/) - Android 終端模擬器

---

## 📄 許可證

本專案基於 [mumumusuc/termux-flutter](https://github.com/mumumusuc/termux-flutter)，採用 **GPL-3.0** 協議開源。

詳見 [LICENSE](LICENSE)
