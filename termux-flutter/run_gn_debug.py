
import subprocess
import os

cmd = [
    '/usr/bin/python3',
    'engine/src/flutter/tools/gn',
    '--linux',
    '--linux-cpu', 'arm64',
    '--enable-fontconfig',
    '--no-goma',
    '--no-backtrace',
    '--clang',
    '--lto',
    '--no-enable-unittests',
    '--no-build-embedder-examples',
    '--no-prebuilt-dart-sdk',
    '--target-toolchain', '/opt/android-ndk-r27d/toolchains/llvm/prebuilt/linux-x86_64',
    '--runtime-mode', 'debug',
    '--no-build-glfw-shell',
    '--gn-args', 'symbol_level=0',
    '--gn-args', 'arm_use_neon=false',
    '--gn-args', 'arm_optionally_use_neon=true',
    '--gn-args', 'dart_include_wasm_opt=false',
    '--gn-args', 'dart_platform_sdk=false',
    '--gn-args', 'is_desktop_linux=false',
    '--gn-args', 'dart_support_perfetto=false',
    '--gn-args', 'skia_use_perfetto=false',
    '--gn-args', 'target_sysroot="/mnt/d/OtherProject/mine/flutter_termux/termux-flutter/sysroot"',
    '--gn-args', 'custom_sysroot="/opt/android-ndk-r27d/toolchains/llvm/prebuilt/linux-x86_64/sysroot"',
    '--gn-args', 'is_termux=true',
    '--gn-args', 'is_termux_host=false'
]

env = os.environ.copy()
env['PATH'] = '/usr/bin:/mnt/d/OtherProject/mine/flutter_termux/termux-flutter/depot_tools:' + env['PATH']

try:
    subprocess.run(cmd, cwd='/mnt/d/OtherProject/mine/flutter_termux/termux-flutter/flutter', env=env, check=True)
except subprocess.CalledProcessError as e:
    print(f"Error: {e}")
