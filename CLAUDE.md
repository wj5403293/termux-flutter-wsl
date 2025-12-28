# Claude Code 操作記錄

## 當前問題 (2025-12-28)

### 根本問題
`dart-sdk/bin/dart` 二進制需要與 DartDev snapshots 版本匹配，但：
1. 官方 Dart SDK 沒有 ARM64 Android (Termux) 版本
2. 從源碼編譯的 dart 缺少匹配的 snapshots
3. 現有的 `dartaotruntime` 和 `dartvm` 不支援 `pub` 命令

### 錯誤訊息
- `Wrong full snapshot version, expected 'xxx' found 'yyy'`
- `Could not resolve DartDev snapshot or kernel`

### 需要解決
1. 編譯完整的 dart + 所有 snapshots
2. 或找到/創建 Termux 兼容的 prebuilt dart

## 測試設備

| 設備 | Serial | 型號 | IP | 用途 |
|------|--------|------|-----|------|
| 平板 | R52Y100VWGM | SM_X716B (Galaxy Tab S9) | 192.168.1.124 | Termux 測試 |
| 手機 | ce0317133a9ad0190c | SM_G950F (Galaxy S8) | - | 備用 |
| 模擬器 | emulator-5554 | x86_64 | - | 不用 |

## 連接方式

### 方式 1：ADB（推薦，不受 IP 變化影響）

```bash
# 直接執行命令
adb -s R52Y100VWGM shell "cd ~/test_app && flutter build apk --release"

# 或開啟 Termux 後輸入
adb -s R52Y100VWGM shell am start -n com.termux/.app.TermuxActivity
adb -s R52Y100VWGM shell input text "命令" && adb -s R52Y100VWGM shell input keyevent 66
```

### 方式 2：SSH（IP 可能會變）

```bash
# Termux SSH (平板)
ssh -p 8022 192.168.1.124
# 密碼: 123456

# 啟動 SSH (如果沒開)
adb -s R52Y100VWGM shell input text "sshd" && adb -s R52Y100VWGM shell input keyevent 66
```

### 用 ADB 重新設置 SSH

```bash
# 1. 安裝 openssh
adb -s R52Y100VWGM shell run-as com.termux sh -c "pkg install -y openssh"

# 2. 設置密碼 (非交互方式)
adb -s R52Y100VWGM shell run-as com.termux sh -c "echo '123456\n123456' | passwd"

# 3. 啟動 sshd
adb -s R52Y100VWGM shell run-as com.termux sh -c "sshd"

# 4. 查看 IP
adb -s R52Y100VWGM shell ip addr | grep "inet "

# 5. 從 Windows 連接
ssh -p 8022 <IP地址>
```

或用 input text 方式（如果 run-as 不行）：

```bash
# 開啟 Termux
adb -s R52Y100VWGM shell am start -n com.termux/.app.TermuxActivity
sleep 2

# 安裝 openssh
adb -s R52Y100VWGM shell input text "pkg%sinstall%s-y%sopenssh" && adb -s R52Y100VWGM shell input keyevent 66
sleep 10

# 設置密碼
adb -s R52Y100VWGM shell input text "passwd" && adb -s R52Y100VWGM shell input keyevent 66
sleep 1
adb -s R52Y100VWGM shell input text "123456" && adb -s R52Y100VWGM shell input keyevent 66
sleep 1
adb -s R52Y100VWGM shell input text "123456" && adb -s R52Y100VWGM shell input keyevent 66

# 啟動 sshd
adb -s R52Y100VWGM shell input text "sshd" && adb -s R52Y100VWGM shell input keyevent 66

# 查看 IP
adb -s R52Y100VWGM shell input text "ip%saddr" && adb -s R52Y100VWGM shell input keyevent 66
```

> 注意：`%s` 代表空格（input text 不能直接輸入空格）

## 檔案傳輸 (用 SCP，比 ADB 穩定)

```bash
# SCP 推送 deb 到平板 Termux
scp -P 8022 release/flutter_3.35.0_aarch64.deb 192.168.1.124:~/flutter.deb
# 密碼: 123456
```

## ADB 操作

```bash
# 打開 Termux
adb -s R52Y100VWGM shell am start -n com.termux/.app.TermuxActivity

# 啟動 SSH
adb -s R52Y100VWGM shell input text "sshd" && adb -s R52Y100VWGM shell input keyevent 66

# 截圖
adb -s R52Y100VWGM exec-out screencap -p > screenshot.png
```

## deb 安裝測試

```bash
# 在 Termux 中
cp /sdcard/Download/flutter_3.35.0_aarch64.deb ~/
dpkg -i ~/flutter_3.35.0_aarch64.deb

# 測試
flutter doctor
flutter build apk --release
```

## 構建命令

```bash
# 一鍵構建 (WSL)
python3 build.py build_all --arch=arm64

# 分步構建
python3 build.py configure --arch=arm64 --mode=debug
python3 build.py build --arch=arm64 --mode=debug
python3 build.py build_dart --arch=arm64 --mode=debug
python3 build.py debuild --arch=arm64
```
