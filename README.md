<p align="center">
  <img src="assets/banner.png" alt="termux-flutter-wsl" width="800"/>
</p>

<h1 align="center">termux-flutter-wsl</h1>

<p align="center">
  <strong>在 WSL 環境下為 Termux 交叉編譯 Flutter SDK</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.35.0-02569B?logo=flutter" alt="Flutter Version"/>
  <img src="https://img.shields.io/badge/Platform-ARM64-green" alt="Platform"/>
  <img src="https://img.shields.io/badge/Build-WSL-0078D6?logo=windows" alt="WSL"/>
  <img src="https://img.shields.io/badge/NDK-r27d-orange" alt="NDK"/>
  <img src="https://img.shields.io/badge/License-GPL--3.0-blue" alt="License"/>
</p>

---

## 📖 專案簡介

本專案基於 [mumumusuc/termux-flutter](https://github.com/mumumusuc/termux-flutter)，實現了在 **WSL (Windows Subsystem for Linux)** 環境下為 Termux 交叉編譯 Flutter Engine 的完整解決方案。

### 🆚 與原專案的差異

| 項目 | 原專案 | 本專案 |
|---|---|---|
| 構建環境 | Linux / Termux 原生 | **WSL (Windows)** |
| Flutter 版本 | 3.29.2 | **3.35.0** |
| 額外修復 | - | **`-llog`, `-lm` 依賴** |
| 文檔 | 基礎 | **完整中文指南** |

### ✨ 主要特色

- 🪟 在 Windows WSL 環境下完成交叉編譯
- 🔧 修復了 Android 日誌符號缺失問題
- 📦 成功產出 `flutter_3.35.0_aarch64.deb` (541MB)
- 🤖 完整的自動化構建流程

---

## 🚀 快速開始

### 在 Termux 上安裝（使用預編譯包）

```bash
# 1. 推送 .deb 包到手機
adb push flutter_3.35.0_aarch64.deb /sdcard/Download/

# 2. 在 Termux 中執行
pkg update && pkg install x11-repo
cp /sdcard/Download/flutter_3.35.0_aarch64.deb ~/
dpkg -i ~/flutter_3.35.0_aarch64.deb

# 3. 驗證安裝
flutter --version
```

### 自行編譯（WSL 環境）

```bash
cd termux-flutter

# 一鍵構建
./build_termux_flutter.sh

# 或分步驟執行
python3 build.py sysroot --arch=arm64    # 組裝 Termux 運行時依賴
python3 build.py configure arch=arm64 mode=debug
python3 build.py build arch=arm64 mode=debug
python3 build.py debuild --arch=arm64    # 打包 .deb
```

---

## 📁 目錄結構

```
termux-flutter-wsl/
├── termux-flutter/           # 主要構建工具
│   ├── build.py              # 主構建腳本
│   ├── build.toml            # 構建配置
│   ├── patches/              # 引擎補丁
│   └── build_termux_flutter.sh  # 一鍵構建腳本
├── assets/                   # 專案資源
├── .agent/workflows/         # 自動化工作流
└── _archive/                 # 臨時文件存檔 (不包含在版本控制中)
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

## 🙏 致謝

- [mumumusuc/termux-flutter](https://github.com/mumumusuc/termux-flutter) - 原始構建工具
- [Flutter](https://flutter.dev/) - Google 的 UI 框架
- [Termux](https://termux.com/) - Android 終端模擬器

---

## 📄 許可證

本專案基於 [mumumusuc/termux-flutter](https://github.com/mumumusuc/termux-flutter)，採用 **GPL-3.0** 協議開源。

詳見 [LICENSE](LICENSE)
