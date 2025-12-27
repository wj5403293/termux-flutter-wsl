#!/bin/bash
# -----------------------------------------------------------------------------
# Sync Upstream Script for termux-flutter-wsl
# -----------------------------------------------------------------------------
# 用途：從上游 (mumumusuc/termux-flutter) 拉取最新更新並合併到本專案
# 注意：這可能會產生衝突，因爲我們修改了 build.py 和其他構建文件以支援 WSL。
# -----------------------------------------------------------------------------

set -e

# 1. 確保 upstream remote 存在
if ! git remote | grep -q "upstream"; then
    echo "Adding remote 'upstream'..."
    git remote add upstream https://github.com/mumumusuc/termux-flutter.git
fi

echo "Fetching upstream..."
git fetch upstream

echo "Attempting subtree pull..."
# 使用 --squash 保持 commit 歷史整潔
# 使用 --allow-unrelated-histories 因為我們是手動添加的文件，沒有共享的 git 歷史
git subtree pull --prefix=termux-flutter upstream main --squash --allow-unrelated-histories

echo "✅ Sync complete! Please check for merge conflicts."
echo "如果發生衝突，請手動解決衝突後 commit。"
