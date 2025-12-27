# claudecode を Docker コンテナ内で安全に実行するための Dockerfile
FROM node:20-alpine

# 必要なシステムパッケージをインストール
RUN apk add --no-cache \
    git \
    curl \
    vim \
    bash

# コンテナ内のデフォルトユーザーを作成（セキュリティのため）
RUN adduser -D -s /bin/bash claude

# claude ユーザーに切り替え
USER claude

# claudecode を公式推奨の方法でインストール（claude ユーザーとして）
RUN curl -fsSL https://claude.ai/install.sh | bash

# PATH に claudecode のインストールパスを追加
ENV PATH="/home/claude/.local/bin:${PATH}"

# Claude の設定ディレクトリを環境変数で指定
ENV CLAUDE_CONFIG_DIR=/home/claude/.config/claude

# Claude の設定ディレクトリを作成
RUN mkdir -p /home/claude/.config/claude

# リポジトリ内の設定ファイルをコンテナにコピー（デフォルト設定として使用）
COPY --chown=claude:claude .config/claude/settings.json /home/claude/.config/claude/settings.json
COPY --chown=claude:claude .config/claude/CLAUDE.md /home/claude/.config/claude/CLAUDE.md

# 作業ディレクトリを workspace に設定
WORKDIR /home/claude/workspace

# ENTRYPOINT で claude コマンドを固定し、CMD でデフォルト引数を指定
ENTRYPOINT ["claude"]
CMD ["--dangerously-skip-permissions"]
