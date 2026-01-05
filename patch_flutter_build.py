#!/usr/bin/env python3
"""Patch flutter/BUILD.gn to support android-arm/x64 gen_snapshot on Termux ARM64."""

import sys

def main():
    build_gn_path = sys.argv[1] if len(sys.argv) > 1 else 'flutter/BUILD.gn'

    # Read the file
    with open(build_gn_path, 'r') as f:
        content = f.read()

    # Check if patch already exists
    if 'termux_cross_host && target_os == "android"' in content:
        print('Patch already applied')
        return 0

    # The patch to add after the Windows block
    patch = '''
# On Termux ARM64, when targeting Android arm/x64, build gen_snapshot with
# host toolchain (ARM64) instead of target toolchain.
# This allows cross-compiling gen_snapshot that runs on ARM64 Termux
# but produces code for android-arm or android-x64.
if (termux_cross_host && target_os == "android" && target_cpu != "arm64") {
  _gen_snapshot_target = "$dart_src/runtime/bin:gen_snapshot($host_toolchain)"
  copy("gen_snapshot") {
    deps = [ _gen_snapshot_target ]

    gen_snapshot_out_dir = get_label_info(_gen_snapshot_target, "root_out_dir")
    sources = [ "$gen_snapshot_out_dir/gen_snapshot" ]
    outputs = [ "$root_build_dir/gen_snapshot/gen_snapshot" ]
  }
}
'''

    # Find the Windows block and add our patch after it
    win_block_end = 'outputs = [ "$root_build_dir/gen_snapshot/gen_snapshot.exe" ]\n  }\n}'

    if win_block_end not in content:
        print('Could not find Windows gen_snapshot block')
        return 1

    # Insert after the Windows block
    new_content = content.replace(win_block_end, win_block_end + patch)

    if new_content == content:
        print('No changes made')
        return 1

    # Write back
    with open(build_gn_path, 'w') as f:
        f.write(new_content)

    print('Patch applied successfully')
    return 0

if __name__ == '__main__':
    sys.exit(main())
