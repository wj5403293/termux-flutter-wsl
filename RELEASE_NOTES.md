# Flutter 3.35.0 for Termux (ARM64)

**世界首個在 Termux ARM64 上運行的完整 Flutter 開發環境**

## 安裝

### 方法 1: 一鍵安裝（推薦）
```bash
curl -sL https://raw.githubusercontent.com/ImL1s/termux-flutter-wsl/master/install_flutter_complete.sh -o ~/install.sh && bash ~/install.sh
```

### 方法 2: 手動安裝
```bash
# 1. 下載並安裝 deb
wget https://github.com/ImL1s/termux-flutter-wsl/releases/download/3.35.0/flutter_3.35.0_aarch64.deb
dpkg -i flutter_3.35.0_aarch64.deb
apt --fix-broken install -y

# 2. 執行 post-install 腳本配置 APK 構建環境
bash $PREFIX/share/flutter/post_install.sh

# 3. 設置環境變數
source $PREFIX/etc/profile.d/flutter.sh

# 4. 驗證安裝
flutter doctor
```

## 功能狀態

| 功能 | 狀態 | 備註 |
|------|------|------|
| `flutter doctor` | ✅ 已驗證 | |
| `flutter create` | ✅ 已驗證 | |
| `flutter build apk --release` | ✅ 已驗證 | 需執行 post_install.sh |
| `flutter build apk --debug` | ✅ 已驗證 | |
| `flutter build apk --profile` | ✅ 已驗證 | |
| `flutter build linux` | ✅ 已驗證 | 需 Termux:X11 |
| `flutter run -d linux` | ✅ 已驗證 | 需 Termux:X11 |
| `flutter run` (Android) | ✅ 已驗證 | 需執行 post_install.sh |

## 系統需求

- Android 11+ (API 30+)
- ARM64 (aarch64) 架構
- Termux 從 [F-Droid](https://f-droid.org/packages/com.termux/) 安裝
- 約 2GB 儲存空間

## APK 構建配置

每個 Flutter 專案需要修改以下配置：

**android/app/build.gradle.kts:**
```kotlin
android {
    compileSdk = 34
    defaultConfig {
        targetSdk = 34
        ndk {
            abiFilters += listOf("arm64-v8a")
        }
    }
}
```

**android/gradle.properties:**
```properties
android.aapt2FromMavenOverride=/data/data/com.termux/files/usr/bin/aapt2
```

## 在本機 Android 設備上運行 (flutter run)

1. **啟用無線調試**
   - 設定 → 開發者選項 → 無線調試 → 開啟

2. **配對設備（首次）**
   ```bash
   # 點擊「使用配對碼配對設備」
   adb pair 127.0.0.1:<配對端口> <配對碼>
   ```

3. **連接設備**
   ```bash
   # 使用無線調試頁面顯示的連接端口（不是配對端口）
   adb connect 127.0.0.1:<連接端口>
   ```

4. **運行**
   ```bash
   flutter run
   ```

## 已知限制

- 僅支援 `android-arm64` 目標（不支援 android-arm、android-x64）
- 需要手動執行 post_install.sh 配置環境（包含 hot reload 支援）

## 技術說明

這是首個成功在 ARM64 Termux 上運行的 Flutter 開發環境。技術挑戰包括：
- Bionic linker TLS 對齊問題
- Android NDK 交叉編譯配置
- gen_snapshot 32-bit 目標不支援（BoringSSL 編譯錯誤）

詳見 [BUILD_GUIDE.md](BUILD_GUIDE.md)。

## 更新內容

### v3.35.0 (2026-01-07)
- 首次公開發布
- Flutter SDK 3.35.0
- 完整支援 APK 構建（debug/profile/release）
- 完整支援 Linux 桌面構建（debug/profile/release）
- `flutter run` + Hot Reload 支援
- 包含 `install_flutter_complete.sh` 一鍵安裝腳本
- 支援無線 ADB 調試

## 致謝

- [mumumusuc/termux-flutter](https://github.com/mumumusuc/termux-flutter) - 原始構建工具
- [ArtifexSoftware/aspect-ratio-less-flutter](https://github.com/ArtifexSoftware/aspect-ratio-less-flutter) - 構建參考
