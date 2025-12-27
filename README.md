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

### 1. 設定ファイルのセットアップ

このリポジトリには、`.config/claude/` ディレクトリに以下の設定ファイルが含まれています：

- `settings.json`: Claude CLI の設定（権限、フック、出力スタイルなど）
- `CLAUDE.md`: プロジェクト固有の指示やルール
- `.mcp.json.template`: MCP サーバーの設定テンプレート

これらのファイルをカスタマイズして使用してください。

#### MCP サーバーの設定

初回セットアップ時に、MCP サーバーを使用する場合は以下のコマンドを実行してください：

```bash
# テンプレートから .mcp.json を作成
cp .config/claude/.mcp.json.template .config/claude/.mcp.json

# 必要に応じて .mcp.json を編集
vim .config/claude/.mcp.json
```

`.mcp.json` ファイルは `.gitignore` に含まれているため、Git で追跡されません。プロジェクト固有の MCP サーバー設定をカスタマイズできます。

#### オプション A: リポジトリ内の設定ファイルをそのまま使う（推奨）

何もする必要はありません。Docker コンテナが自動的にこれらのファイルを使用します。

#### オプション B: ホスト側の設定ファイルを使う

ホスト側の `~/.config/claude/` にある設定ファイルを使いたい場合は、シンボリックリンクを作成します：

```bash
# リポジトリ内の設定ファイルを削除（または名前を変更してバックアップ）
mv .config/claude/settings.json .config/claude/settings.json.sample
mv .config/claude/CLAUDE.md .config/claude/CLAUDE.md.sample

# ホスト側の設定ファイルへのシンボリックリンクを作成
ln -s ~/.config/claude/settings.json .config/claude/settings.json
ln -s ~/.config/claude/CLAUDE.md .config/claude/CLAUDE.md

# MCP サーバー設定もシンボリックリンクする場合（オプション）
ln -s ~/.config/claude/.mcp.json .config/claude/.mcp.json
```

**注意**: シンボリックリンクを使用する場合、ホスト側の設定ファイルへの変更がリポジトリに反映されます。

### 2. Docker イメージのビルド

```bash
docker build -t claudecode-docker .
```

### 3. workspace ディレクトリの作成

作業ディレクトリを作成します：

```bash
mkdir -p workspace
```

### 4. 初回ログイン

初回のみ、コンテナ内で claude CLI にログインする必要があります。

**注意**: このコンテナは `CLAUDE_CONFIG_DIR=/home/claude/.config/claude` を環境変数として設定しています。ホスト側でも `~/.config/claude` を使用するように統一しています。

```bash
# 認証情報を保存するディレクトリを作成（まだ存在しない場合）
mkdir -p ~/.config/claude

# コンテナを起動してログイン
docker run -it --rm -v "$(pwd)/workspace:/home/claude/workspace" -v "${HOME}/.config/claude:/home/claude/.config/claude" claudecode-docker claude login
```

ブラウザが開くので、Claude subscription アカウントでログインしてください。認証が完了すると、`~/.config/claude/` に認証情報が保存されます。

## 使用方法

### 基本的な実行方法

workspace ディレクトリをコンテナ内にマウントして claude CLI を実行します：

```bash
docker run -it --rm -v "$(pwd)/workspace:/home/claude/workspace" -v "${HOME}/.config/claude:/home/claude/.config/claude" claudecode-docker
```

### 注意事項

- **workspace ディレクトリ**: コンテナ内の `/home/claude/workspace` にマウントされ、すべての作業ファイルがここに保存されます
- **設定ファイル**:
  - Docker イメージには、リポジトリ内の `.config/claude/settings.json` と `CLAUDE.md` がデフォルト設定としてコピーされています
  - ホスト側の `~/.config/claude` をマウントすると、認証情報（`.credentials.json`）が共有され、ログイン状態が保持されます
  - マウントされた設定ファイル（ホスト側）がある場合は、それがイメージ内の設定を上書きします
- **設定ファイルの更新**: claude CLI は起動時に設定ファイル（`.claude.json`）を更新するため、認証情報ディレクトリは**読み書き可能**でマウントする必要があります
- **作業ディレクトリ**: コンテナ起動時は自動的に `/home/claude/workspace` ディレクトリにいます

### 異なる workspace を使用する場合

```bash
docker run -it --rm -v "/path/to/your/workspace:/home/claude/workspace" -v "${HOME}/.config/claude:/home/claude/.config/claude" claudecode-docker
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
docker run -it --rm -v "$(pwd)/workspace:/home/claude/workspace" -v "${HOME}/.config/claude:/home/claude/.config/claude" --user "$(id -u):$(id -g)" claudecode-docker
```

### 認証エラーが発生する場合

認証情報が正しくマウントされているか確認してください：

```bash
ls -la ~/.config/claude
```

認証情報が期限切れまたは破損している場合は、再度ログインしてください：

```bash
docker run -it --rm -v "$(pwd)/workspace:/home/claude/workspace" -v "${HOME}/.config/claude:/home/claude/.config/claude" claudecode-docker claude login
```

## ライセンス

このプロジェクトは、claude CLI を安全に実行するためのラッパーです。claude CLI 自体のライセンスについては、[Anthropic の公式ドキュメント](https://docs.anthropic.com/)を参照してください。
