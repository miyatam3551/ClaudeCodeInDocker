#!/bin/bash
# watch-claude-notify.sh
# Docker内のClaude Codeからの音声通知を監視して再生するスクリプト

# スクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
notify_dir="$SCRIPT_DIR/notify"
notify_file="$notify_dir/notify.wav"

# ディレクトリが存在しない場合は作成
mkdir -p "$notify_dir"

echo "Claude Code通知監視を開始します: $notify_file"
echo "停止するには Ctrl+C を押してください"

fswatch --event Updated -o "$notify_file" 2>/dev/null | while read; do
  if [ -f "$notify_file" ]; then
    afplay "$notify_file" >/dev/null 2>&1 && rm -f "$notify_file"
  fi
done
