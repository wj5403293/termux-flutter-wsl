---
description: 為 Termux 交叉編譯 Flutter Engine 並打包成 .deb 安裝包
---

# Termux Flutter 構建流程

## 前置條件
- WSL (Ubuntu) 或 Linux 環境
- Android NDK r27d 安裝於 `/opt/android-ndk-r27d`
- Python 3.10+
- depot_tools 已配置

## 快速構建 (一鍵)
// turbo-all
```bash
cd /mnt/d/OtherProject/mine/flutter_termux/termux-flutter
./build_termux_flutter.sh
```

## 分步驟構建

### 1. 組裝 Sysroot
```bash
python3 build.py sysroot --arch=arm64
```

### 2. 配置 GN
```bash
python3 build.py configure arch=arm64 mode=debug
```

### 3. 編譯
```bash
python3 build.py build arch=arm64 mode=debug
```

### 4. 打包
```bash
python3 build.py debuild --arch=arm64
```

## 升級到新版本

1. 修改 `build.toml` 中的 `tag = '新版本號'`
2. 執行 `python3 build.py clone`
3. 執行 `python3 build.py sync`
4. 如果補丁失敗，需手動更新 `patches/*.patch`
5. 執行完整構建流程

## 在 Termux 上安裝

```bash
# 推送到手機
adb push flutter_*.deb /sdcard/Download/

# 在 Termux 中執行
pkg update && pkg install x11-repo
cp /sdcard/Download/flutter_*.deb ~/
dpkg -i ~/flutter_*.deb
flutter --version
```

## 關鍵補丁說明
我們在 `build/config/termux/BUILD.gn` 中加入了 `-llog`, `-lm` 以解決 Android 日誌符號缺失問題。
