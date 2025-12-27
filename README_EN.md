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

---

## 📖 Introduction

This project is based on [mumumusuc/termux-flutter](https://github.com/mumumusuc/termux-flutter) and provides a complete solution for cross-compiling the Flutter Engine for Termux on a **WSL (Windows Subsystem for Linux)** environment.

### 🆚 Differences from Upstream

| Feature | Upstream | This Project |
|---|---|---|
| Build Env | Linux / Termux Native | **WSL (Windows)** |
| Flutter Ver | 3.29.2 | **3.35.0** |
| Fixes | - | **`-llog`, `-lm` deps** |
| Docs | Basic | **Full Guide (EN/ZH)** |

### ✨ Features

- 🪟 Cross-compile entirely within Windows WSL
- 🔧 Fixed missing Android log symbols (`-llog`)
- 📦 Produced `flutter_3.35.0_aarch64.deb` (541MB)
- 🤖 Fully automated build scripts

---

## 🚀 Quick Start

### Install on Termux (Using Pre-built .deb)

```bash
# 1. Push .deb to device
adb push flutter_3.35.0_aarch64.deb /sdcard/Download/

# 2. Install in Termux
pkg update && pkg install x11-repo
cp /sdcard/Download/flutter_3.35.0_aarch64.deb ~/
dpkg -i ~/flutter_3.35.0_aarch64.deb

# 3. Verify
flutter --version
```

### Build from Source (on WSL)

```bash
cd termux-flutter

# Build everything
./build_termux_flutter.sh

# Or step-by-step
python3 build.py sysroot --arch=arm64    # Assemble Termux sysroot
python3 build.py configure arch=arm64 mode=debug
python3 build.py build arch=arm64 mode=debug
python3 build.py debuild --arch=arm64    # Package .deb
```

---

## 📁 Directory Structure

```
termux-flutter-wsl/
├── termux-flutter/           # Build tools (forked)
│   ├── build.py              # Main build script
│   ├── build.toml            # Configuration
│   ├── patches/              # Engine patches
│   └── build_termux_flutter.sh
├── assets/                   # Project assets
├── .agent/workflows/         # Automation workflows
└── _archive/                 # Temporary files (ignored)
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

## 🙏 Acknowledgements

- [mumumusuc/termux-flutter](https://github.com/mumumusuc/termux-flutter) - Original build tools
- [Flutter](https://flutter.dev/) - Google's UI Toolkit
- [Termux](https://termux.com/) - Android Terminal Emulator

---

## 📄 License

Based on [mumumusuc/termux-flutter](https://github.com/mumumusuc/termux-flutter), licensed under **GPL-3.0**.

See [LICENSE](LICENSE) for details.
