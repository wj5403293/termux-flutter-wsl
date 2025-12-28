# Termux Flutter 安裝指南

本文檔說明如何在 Termux 上安裝 Flutter 並構建 Android APK。

## 系統需求

| 項目 | 需求 |
|------|------|
| Android 版本 | Android 11 (API 30) 或更高 |
| 架構 | ARM64 (aarch64) |
| Termux | 從 [F-Droid](https://f-droid.org/packages/com.termux/) 安裝 |
| 可用空間 | 至少 5GB |

## 方法一：一鍵安裝（推薦）

```bash
curl -sL https://raw.githubusercontent.com/ImL1s/termux-flutter-wsl/master/install_termux_flutter.sh | bash
```

安裝完成後，重新載入環境：
```bash
source ~/.bashrc
```

## 方法二：手動安裝

### 步驟 1：安裝依賴

```bash
pkg update -y
pkg install -y x11-repo
pkg install -y openjdk-21 git wget curl unzip aapt2
```

### 步驟 2：安裝 Flutter SDK

```bash
cd ~
wget https://github.com/ImL1s/termux-flutter-wsl/releases/download/v3.35.0/flutter_3.35.0_aarch64.deb
dpkg -i flutter_3.35.0_aarch64.deb
```

### 步驟 3：安裝 Android SDK

```bash
wget https://github.com/mumumusuc/termux-android-sdk/releases/download/35.0.0/android-sdk_35.0.0_aarch64.deb
dpkg -i --force-architecture android-sdk_35.0.0_aarch64.deb
```

### 步驟 4：安裝 ARM64 NDK

```bash
cd ~
wget https://github.com/AntonioCiolworker/ArmDroid-NDK/releases/download/android-ndk/android-ndk-r27b-aarch64.zip
mkdir -p $PREFIX/opt/android-sdk/ndk
unzip android-ndk-r27b-aarch64.zip -d $PREFIX/opt/android-sdk/ndk/
mv $PREFIX/opt/android-sdk/ndk/android-ndk-r27b $PREFIX/opt/android-sdk/ndk/27.1.12297006
```

### 步驟 5：配置環境變數

```bash
cat >> ~/.bashrc << 'EOF'
# Flutter & Android SDK
export ANDROID_HOME=$PREFIX/opt/android-sdk
export PATH=$PATH:$ANDROID_HOME/platform-tools
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin
EOF

source ~/.bashrc
```

### 步驟 6：配置 Flutter

```bash
flutter config --android-sdk $ANDROID_HOME
flutter doctor --android-licenses
flutter doctor
```

## 構建 APK

### 創建新專案

```bash
flutter create myapp
cd myapp
```

### 配置專案（必須）

```bash
# 自動配置
curl -sL https://raw.githubusercontent.com/ImL1s/termux-flutter-wsl/master/setup_flutter_project.sh | bash
```

或手動配置 `android/gradle.properties`：
```properties
android.useAndroidX=true
android.enableJetifier=true
android.aapt2FromMavenOverride=/data/data/com.termux/files/usr/bin/aapt2
org.gradle.jvmargs=-Xmx768m -XX:MaxMetaspaceSize=384m
```

並在 `android/app/build.gradle.kts` 中添加：
```kotlin
android {
    ndkVersion = "27.1.12297006"
}
```

### 構建

```bash
# Debug APK（較快）
flutter build apk --debug

# Release APK
flutter build apk --release
```

## 驗證安裝

```bash
# 檢查 Flutter
flutter doctor

# 檢查 gen_snapshot（應顯示 android_arm64）
$PREFIX/opt/flutter/bin/cache/artifacts/engine/android-arm64-release/linux-arm64/gen_snapshot --version
```

## 常見問題

### 問題：x11-repo 未安裝
```bash
pkg install x11-repo
```

### 問題：AAPT2 錯誤
```bash
pkg install aapt2
```

### 問題：NDK 找不到
確保 NDK 安裝在正確位置：
```bash
ls $ANDROID_HOME/ndk/27.1.12297006/toolchains/llvm/prebuilt/linux-aarch64/bin/clang
```

### 問題：空間不足
清理 Gradle 緩存：
```bash
rm -rf ~/.gradle/caches
rm -rf ~/.gradle/wrapper
```
