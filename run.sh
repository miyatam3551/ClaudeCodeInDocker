#!/bin/bash

# スクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 音声通知監視スクリプトをバックグラウンドで起動
if [ -f "$SCRIPT_DIR/scripts/watch-notify.sh" ]; then
     # 既存のプロセスを終了
     pkill -f "watch-notify.sh" 2>/dev/null
     pkill -f "fswatch.*notify.wav" 2>/dev/null
     sleep 0.5  # プロセス終了を待つ

     echo "🔔 音声通知監視を起動しています..."
     "$SCRIPT_DIR/scripts/watch-notify.sh" &
     WATCH_PID=$!

     # クリーンアップ関数
     cleanup() {
          echo ""
          echo "🛑 音声通知監視を停止しています..."
          kill $WATCH_PID 2>/dev/null
          wait $WATCH_PID 2>/dev/null
     }

     # 終了時にクリーンアップを実行
     trap cleanup EXIT INT TERM
fi

# Dockerコンテナを起動
docker run -it --rm \
     -v "$(pwd)/workspace:/home/claude/workspace" \
     -v "${HOME}/.config/claude:/home/claude/.config/claude" \
     -v "$(pwd)/config/settings.json:/home/claude/.config/claude/settings.json" \
     -v "$(pwd)/notify:/notify" \
     claudecode-docker
