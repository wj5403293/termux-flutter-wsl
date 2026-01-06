# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [3.35.0-termux] - 2025-01-06

### Added
- Full Flutter 3.35.0 support for Termux ARM64
- `flutter build apk` support (ARM64 only)
- `flutter build linux` support
- `flutter run` with Hot Reload support
- Linux desktop app support via Termux X11
- One-command installation script (`install_flutter_complete.sh`)
- Automatic NDK clang wrapper configuration
- Android SDK integration with API 34

### Fixed
- libc++_shared.so symlink issue (was pointing to linker script instead of ELF)
- NDK clang wrapper detection for multiple NDK versions
- Dependency conflicts during package upgrades (openjdk-17 vs openjdk-21)
- Missing Android build tools (d8, dx, aidl, apksigner)
- libatomic.a stubs for CMake compatibility

### Known Limitations
- APK builds only support ARM64 (android-arm64-v8a)
- Linux desktop uses debug mode only (sysroot header conflicts)
- Profile mode not yet supported
- ARMv7 (android-arm) not supported due to BoringSSL 32-bit issues
- x86/x64 Android targets not supported

### Technical Details
- Cross-compiled from x86_64 Linux (WSL) to ARM64 Bionic
- Uses NDK r27d with API level 35
- Patches applied to Flutter Engine, Dart VM, and Skia
- TLS alignment fixed for Bionic linker compatibility

---

## Version Naming Convention

`{flutter_version}-termux` - e.g., `3.35.0-termux`

- `flutter_version`: Upstream Flutter SDK version
- `termux`: Indicates this is a Termux-compatible build

## Upgrading

See [BUILD_GUIDE.md](BUILD_GUIDE.md#upgrading-flutter-version) for upgrade instructions.
