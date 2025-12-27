# ClaudeCode in Docker

Docker コンテナ内で Claude CLI を安全に実行するための環境です。

## クイックスタート

### 1. 必要なソフトウェアのインストール

```bash
# fswatch のインストール（音声通知機能を使う場合）
brew install fswatch
```

**必須要件:**
- Docker Desktop または Docker Engine
- Claude subscription アカウント
- （オプション）[VOICEVOX](https://voicevox.hiroshiba.jp/) - 音声通知機能を使う場合

### 2. 初回セットアップ

```bash
# イメージをビルド
docker build -t claudecode-docker .

# 作業ディレクトリと認証ディレクトリを作成
mkdir -p workspace ~/.config/claude

# Claude CLI にログイン（初回のみ）
docker run -it --rm \
  -v "$(pwd)/workspace:/home/claude/workspace" \
  -v "${HOME}/.config/claude:/home/claude/.config/claude" \
  claudecode-docker claude login
```

### 3. 実行

```bash
./run.sh
```

これだけです！音声通知も自動的に有効になります（VOICEVOXを起動している場合）。

---

## 補足情報

### このプロジェクトについて

claude CLI の `--dangerously-skip-permissions` オプションを安全に使うため、Docker コンテナ内で実行します。

**メリット:**
- 隔離された環境でホストシステムへの影響を最小化
- 非特権ユーザーで実行し、マウントしたディレクトリのみにアクセス
- 再現可能な環境

### 設定ファイルのカスタマイズ

リポジトリ内の `.config/claude/` には以下の設定ファイルがあります：

- `settings.json` - Claude CLI の設定
- `CLAUDE.md` - プロジェクト固有の指示
- `.mcp.json.template` - MCP サーバー設定のテンプレート

#### MCP サーバーを使う場合

```bash
cp .config/claude/.mcp.json.template .config/claude/.mcp.json
vim .config/claude/.mcp.json  # 必要に応じて編集
```

#### ホスト側の設定ファイルを使う場合

```bash
mv .config/claude/settings.json .config/claude/settings.json.sample
ln -s ~/.config/claude/settings.json .config/claude/settings.json
ln -s ~/.config/claude/CLAUDE.md .config/claude/CLAUDE.md
```

### 手動実行（run.sh を使わない場合）

```bash
docker run -it --rm \
  -v "$(pwd)/workspace:/home/claude/workspace" \
  -v "${HOME}/.config/claude:/home/claude/.config/claude" \
  claudecode-docker
```

### 異なる workspace を使う場合

```bash
docker run -it --rm \
  -v "/path/to/your/workspace:/home/claude/workspace" \
  -v "${HOME}/.config/claude:/home/claude/.config/claude" \
  claudecode-docker
```

### 音声通知の仕組み

`./run.sh` を実行すると、以下が自動的に行われます：

1. VOICEVOXが起動していれば、ツール使用時に音声通知
2. `fswatch` でファイル変更を監視
3. Docker終了時（Ctrl+C）に監視も自動停止

**仕組み:**
- Docker内からホストのVOICEVOX（ポート50021）にアクセス
- 音声ファイルを `notify/notify.wav` に保存
- `fswatch` が変更を検知して `afplay` で再生

### エイリアスの設定

頻繁に使う場合はエイリアスが便利です。

**Bash/Zsh** (`~/.bashrc` または `~/.zshrc`):
```bash
alias claudecode-safe='docker run -it --rm -v "$(pwd)/workspace:/home/claude/workspace" -v "${HOME}/.config/claude:/home/claude/.config/claude" claudecode-docker'
```

**Nushell** (`~/.config/nushell/config.nu`):
```nushell
alias claudecode-safe = docker run -it --rm -v $"(pwd)/workspace:/home/claude/workspace" -v $"($env.HOME)/.config/claude:/home/claude/.config/claude" claudecode-docker
```

### トラブルシューティング

**権限エラーが出る場合:**
```bash
docker run -it --rm \
  -v "$(pwd)/workspace:/home/claude/workspace" \
  -v "${HOME}/.config/claude:/home/claude/.config/claude" \
  --user "$(id -u):$(id -g)" \
  claudecode-docker
```

**認証エラーが出る場合:**
```bash
# 認証情報を確認
ls -la ~/.config/claude

# 再ログイン
docker run -it --rm \
  -v "$(pwd)/workspace:/home/claude/workspace" \
  -v "${HOME}/.config/claude:/home/claude/.config/claude" \
  claudecode-docker claude login
```

### セキュリティについて

- マウントしたディレクトリのみアクセス可能
- 非特権ユーザー（`claude`）で実行
- ホストシステムへの影響は最小限
- `~/.config/claude` は定期的にバックアップ推奨
