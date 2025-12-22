# claudecode を Docker コンテナ内で安全に実行するための Dockerfile
FROM node:20-slim

# 必要なシステムパッケージをインストール
RUN apt-get update && apt-get install -y \
    git \
    curl \
    vim \
    bash \
    && rm -rf /var/lib/apt/lists/*

# コンテナ内のデフォルトユーザーを作成（セキュリティのため）
RUN useradd -m -s /bin/bash claude

# claude ユーザーに切り替え
USER claude

# claudecode を公式推奨の方法でインストール（claude ユーザーとして）
RUN curl -fsSL https://claude.ai/install.sh | bash

# PATH に claudecode のインストールパスを追加
ENV PATH="/home/claude/.local/bin:${PATH}"

# Claude の設定ディレクトリを環境変数で指定
ENV CLAUDE_CONFIG_DIR=/home/claude/.config/claude

# 作業ディレクトリを workspace に設定
WORKDIR /home/claude/workspace

# ENTRYPOINT で claude コマンドを固定し、CMD でデフォルト引数を指定
ENTRYPOINT ["claude"]
CMD ["--dangerously-skip-permissions"]
