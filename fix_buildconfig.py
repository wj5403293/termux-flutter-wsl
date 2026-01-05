#!/usr/bin/env python3
"""Fix BUILDCONFIG.gn to add is_termux toolchain case."""

import sys

path = sys.argv[1] if len(sys.argv) > 1 else 'build/config/BUILDCONFIG.gn'

with open(path, 'r') as f:
    content = f.read()

# Check if already patched
if 'if (is_termux) {\n  host_toolchain = "//build/toolchain/linux:clang_$host_cpu"\n  set_default_toolchain("//build/toolchain/termux:$current_cpu")' in content:
    print('Already patched')
    sys.exit(0)

# Find the custom_toolchain check and add is_termux before it
old = 'if (custom_toolchain != "") {'
new = '''if (is_termux) {
  host_toolchain = "//build/toolchain/linux:clang_$host_cpu"
  set_default_toolchain("//build/toolchain/termux:$current_cpu")
} else if (custom_toolchain != "") {'''

content = content.replace(old, new)

with open(path, 'w') as f:
    f.write(content)

print('Patched successfully!')
