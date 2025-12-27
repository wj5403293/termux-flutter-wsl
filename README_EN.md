<p align="center">
  <img src="assets/banner.png" alt="termux-flutter-wsl" width="800"/>
</p>

<h1 align="center">termux-flutter-wsl</h1>

<p align="center">
  <strong>Cross-compile Flutter SDK for Termux on WSL</strong>
</p>

<p align="center">
  <a href="README.md">中文</a> | <strong>English</strong>
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

## 📖 Introduction

This project is based on [mumumusuc/termux-flutter](https://github.com/mumumusuc/termux-flutter) and provides a complete solution for cross-compiling the Flutter Engine for Termux on a **WSL (Windows Subsystem for Linux)** environment.

### 🆚 Differences from Upstream

| Feature | Upstream | This Project |
|---|---|---|
| Build Env | Linux / Termux Native | **WSL (Windows)** |
| Flutter Ver | 3.29.2 | **3.35.0** |
| Android Compat | ❌ No Android 14+ | ✅ **Android 16 Tested** |
| Fixes | - | **`-llog`, `-lm` deps** |
| Docs | Basic | **Full Guide (EN/ZH)** |

> ✅ **Verified**: Successfully ran Flutter app on Android 16 device!

### ✨ Features

- 🪟 Cross-compile entirely within Windows WSL
- 🔧 Fixed missing Android log symbols (`-llog`)
- 📦 Produced `flutter_3.35.0_aarch64.deb` (541MB)
- 🤖 Fully automated build scripts

---

## 🚀 Quick Start

### Install on Termux

```bash
# 1. Install dependencies
pkg update && pkg install x11-repo wget

# 2. Download package
wget https://github.com/ImL1s/termux-flutter-wsl/releases/download/v3.35.0/flutter_3.35.0_aarch64.deb

# 3. Install & Verify
dpkg -i flutter_3.35.0_aarch64.deb
flutter --version
```

### Build from Source (on WSL)

```bash
# Build everything
./build_termux_flutter.sh

# Or step-by-step
python3 build.py sysroot --arch=arm64    # Assemble Termux sysroot
python3 build.py configure --arch=arm64 --mode=debug
python3 build.py build --arch=arm64 --mode=debug
python3 build.py debuild --arch=arm64    # Package .deb
```

### Run Flutter App (with Termux:X11)

After installation, you need [Termux:X11](https://github.com/termux/termux-x11/releases) to display GUI apps.

**Install Termux:X11**: Download APK from [GitHub Releases](https://github.com/termux/termux-x11/releases) or [F-Droid](https://f-droid.org/packages/com.termux.x11/).

```bash
# 1. Start X11 server in Termux
export DISPLAY=:0
termux-x11 :0 >/dev/null 2>&1 &

# 2. Open Termux:X11 App (black screen is normal initially)

# 3. Create and run Flutter project
flutter create hello_termux
cd hello_termux
flutter run -d linux
```

> 💡 **Alternative**: If X11 is difficult to set up, use Web mode:
> ```bash
> flutter run -d web-server --web-port=8080
> ```
> Then open `http://localhost:8080` in browser.

### Build Android APK

To run `flutter build apk` in Termux, you need the full Android development environment.

#### Step 1: Install Dependencies

```bash
# Update packages and install JDK
pkg update
pkg install openjdk-17 git wget
```

#### Step 2: Install Android SDK

Download and install from [termux-android-sdk](https://github.com/mumumusuc/termux-android-sdk/releases):

```bash
wget https://github.com/mumumusuc/termux-android-sdk/releases/download/35.0.0/android-sdk_35.0.0_aarch64.deb
dpkg -i android-sdk_35.0.0_aarch64.deb
```

> This package includes native ARM64 `aapt2`, `build-tools 35.0.0`, `platforms android-34/35`, and other essential tools.

#### Step 3: Configure Environment Variables

```bash
# Add to ~/.bashrc or ~/.zshrc
export ANDROID_HOME=$PREFIX/opt/android-sdk
export JAVA_HOME=$PREFIX/opt/openjdk
export PATH=$PATH:$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin
```

Reload configuration:
```bash
source ~/.bashrc
```

#### Step 4: Configure Flutter

```bash
# Set Android SDK path
flutter config --android-sdk $ANDROID_HOME

# Accept Android licenses
flutter doctor --android-licenses

# Check environment
flutter doctor
```

#### Step 5: Build APK

```bash
# Create project
flutter create myapp
cd myapp

# Build Release APK (for ARM64)
flutter build apk --release --target-platform android-arm64

# APK output location
ls build/app/outputs/flutter-apk/
```

### Deploy to Android Device

#### Connect ADB Device

**Method A: Wireless ADB (Same Phone)**

1. Enable "Developer Options" → "Wireless Debugging" on your phone
2. Tap "Pair device with pairing code", note the pairing code and port

```bash
# Pair (only once)
adb pair 127.0.0.1:<pairing_port>
# Enter pairing code

# Connect
adb connect 127.0.0.1:<connect_port>
```

**Method B: Connect to Other Devices**

```bash
# Ensure target device has USB debugging or wireless debugging enabled
adb connect <device_ip>:5555
```

#### Run App

```bash
# List connected devices
flutter devices

# Deploy to Android device
flutter run -d <device_id>

# Or install APK directly
adb install build/app/outputs/flutter-apk/app-release.apk
```

> ⚠️ **Note**: `flutter devices` only shows `linux` by default. Install `termux-android-sdk` to see Android device options.

---

## 📁 Directory Structure

```
termux-flutter-wsl/
├── build.py              # Main build script
├── build.toml            # Configuration
├── patches/              # Engine patches
├── build_termux_flutter.sh  # One-click build
├── README.md             # Chinese docs
├── README_EN.md          # English docs
├── assets/               # Assets
└── .agent/workflows/     # Automation
```

---

## 🔧 Technical Details

### Build Requirements

| Item | Version/Config |
|---|---|
| Host OS | Windows 11 + WSL (Ubuntu 22.04+) |
| Target | ARM64 Android (Termux) |
| NDK | r27d (API 35) |
| Python | 3.10+ |

### Key Fixes

We applied the following fixes to ensure WSL compatibility:

```gn
# build/config/termux/BUILD.gn - runtime_library
ldflags = [
  "-stdlib=libstdc++",
  "-Wl,--warn-shared-textrel",
  "-llog",   # Added: Android logging lib
  "-lm",     # Added: Math lib
]
```

---

## 📋 Upgrading

1. Update `tag` in `build.toml`.
2. Sync and patch:
   ```bash
   python3 build.py clone
   python3 build.py sync
   python3 build.py patch_engine  # Update patches if needed
   ```
3. Run the full build process.

---

## 🔄 Sync with Upstream

This project is a fork of [mumumusuc/termux-flutter](https://github.com/mumumusuc/termux-flutter). To sync updates:

```bash
git remote add upstream https://github.com/mumumusuc/termux-flutter.git
git fetch upstream
git merge upstream/main
```

**Note**: Merge conflicts may occur because we customized build scripts for WSL support. Please resolve conflicts manually.

---

## 🙏 Acknowledgements

- [mumumusuc/termux-flutter](https://github.com/mumumusuc/termux-flutter) - Original build tools
- [Flutter](https://flutter.dev/) - Google's UI Toolkit
- [Termux](https://termux.com/) - Android Terminal Emulator

---

## 📄 License

Based on [mumumusuc/termux-flutter](https://github.com/mumumusuc/termux-flutter), licensed under **GPL-3.0**.

See [LICENSE](LICENSE) for details.
