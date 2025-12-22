# ClaudeCode in Docker

claude CLI の `--dangerously-skip-permissions` オプションを安全に利用するための Docker 環境です。

## 概要

claude CLI の `--dangerously-skip-permissions` オプションは、ファイルシステムへの無制限アクセスを許可するため、ホスト環境で直接実行するとセキュリティリスクがあります。このプロジェクトは、Docker コンテナ内で claude CLI を実行することで、以下のメリットを提供します：

- **隔離された環境**: コンテナ内でのみ動作するため、ホストシステムへの影響を最小限に抑えます
- **権限の制御**: 非特権ユーザーで実行し、マウントしたディレクトリのみにアクセスを制限
- **再現可能な環境**: 常に同じ環境で claudecode を実行できます

## 必要要件

- Docker Desktop または Docker Engine がインストールされていること
- Claude subscription アカウント

## セットアップ

### 1. Docker イメージのビルド

```bash
docker build -t claudecode-docker .
```

### 2. workspace ディレクトリの作成

作業ディレクトリを作成します：

```bash
mkdir -p workspace
```

### 3. 初回ログイン

初回のみ、コンテナ内で claude CLI にログインする必要があります。

**注意**: このコンテナは `CLAUDE_CONFIG_DIR=/home/claude/.config/claude` を環境変数として設定しています。ホスト側でも `~/.config/claude` を使用するように統一しています。

```bash
# 認証情報を保存するディレクトリを作成（まだ存在しない場合）
mkdir -p ~/.config/claude

# コンテナを起動してログイン
docker run -it --rm \
  -v "$(pwd)/workspace:/home/claude/workspace" \
  -v "${HOME}/.config/claude:/home/claude/.config/claude" \
  claudecode-docker claude login
```

ブラウザが開くので、Claude subscription アカウントでログインしてください。認証が完了すると、`~/.config/claude/` に認証情報が保存されます。

## 使用方法

### 基本的な実行方法

workspace ディレクトリをコンテナ内にマウントして claude CLI を実行します：

```bash
docker run -it --rm \
  -v "$(pwd)/workspace:/home/claude/workspace" \
  -v "${HOME}/.config/claude:/home/claude/.config/claude" \
  claudecode-docker
```

### 注意事項

- **workspace ディレクトリ**: コンテナ内の `/home/claude/workspace` にマウントされ、すべての作業ファイルがここに保存されます
- **設定ファイルの更新**: claude CLI は起動時に設定ファイル（`.claude.json`）を更新するため、認証情報ディレクトリは**読み書き可能**でマウントする必要があります
- **作業ディレクトリ**: コンテナ起動時は自動的に `/home/claude/workspace` ディレクトリにいます

### 異なる workspace を使用する場合

```bash
docker run -it --rm \
  -v "/path/to/your/workspace:/home/claude/workspace" \
  -v "${HOME}/.config/claude:/home/claude/.config/claude" \
  claudecode-docker
```

## エイリアスの設定（オプション）

頻繁に使用する場合は、シェルのエイリアスを設定すると便利です。

### Bash/Zsh の場合

`~/.bashrc` または `~/.zshrc` に追加：

```bash
alias claudecode-safe='docker run -it --rm -v "$(pwd)/workspace:/home/claude/workspace" -v "${HOME}/.config/claude:/home/claude/.config/claude" claudecode-docker'
```

### Nushell の場合

`~/.config/nushell/config.nu` に追加：

```nushell
alias claudecode-safe = docker run -it --rm -v $"(pwd)/workspace:/home/claude/workspace" -v $"($env.HOME)/.config/claude:/home/claude/.config/claude" claudecode-docker
```

### 使用例

```bash
claudecode-safe
```

## セキュリティに関する注意事項

- **マウントするディレクトリを限定**: `-v` オプションで指定したディレクトリのみがコンテナからアクセス可能です
- **認証情報ディレクトリの共有**: `~/.config/claude` はホスト側と共有されます。コンテナ内での変更もホスト側に反映されます
- **認証情報のバックアップ**: `~/.config/claude` ディレクトリは定期的にバックアップしておくことを推奨します
- **非特権ユーザーでの実行**: コンテナ内では `claude` ユーザー（非 root）で実行されるため、システムへの影響は限定的です

## トラブルシューティング

### 権限エラーが発生する場合

ファイルの所有者がコンテナ内のユーザーと一致しない場合、権限エラーが発生することがあります。以下のコマンドで権限を調整できます：

```bash
docker run -it --rm \
  -v "$(pwd)/workspace:/home/claude/workspace" \
  -v "${HOME}/.config/claude:/home/claude/.config/claude" \
  --user "$(id -u):$(id -g)" \
  claudecode-docker
```

### 認証エラーが発生する場合

認証情報が正しくマウントされているか確認してください：

```bash
ls -la ~/.config/claude
```

認証情報が期限切れまたは破損している場合は、再度ログインしてください：

```bash
docker run -it --rm \
  -v "$(pwd)/workspace:/home/claude/workspace" \
  -v "${HOME}/.config/claude:/home/claude/.config/claude" \
  claudecode-docker claude login
```

## ライセンス

このプロジェクトは、claude CLI を安全に実行するためのラッパーです。claude CLI 自体のライセンスについては、[Anthropic の公式ドキュメント](https://docs.anthropic.com/)を参照してください。
