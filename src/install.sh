#!/usr/bin/env zsh

BIN_DIR="$HOME/.local/bin"
VNUX_BIN="$BIN_DIR/vnux"
JAR="$HOME/.vnux/vnu.jar"
VNUX_RELEASE_URL="https://github.com/hiroya-uga/vnux/releases/latest/download/vnux"

if ! grep -Fq '.local/bin' ~/.zshenv 2>/dev/null; then
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshenv
  export PATH="$BIN_DIR:$PATH"
  echo "Added ~/.local/bin to PATH (~/.zshenv)"
fi

if [[ -f "$VNUX_BIN" ]]; then
  echo "💡 vnux is already installed"
  exit 0
fi

if ! java -version > /dev/null 2>&1; then
  echo "java not found. Installing via Homebrew..."
  if ! command -v brew > /dev/null 2>&1; then
    echo "❌ Homebrew is not installed."
    exit 1
  fi
  if ! brew install --cask temurin; then
    echo "❌ Failed to install temurin."
    exit 1
  fi
  # cask インストール直後は現在のシェルの PATH に反映されないため確認する
  if ! java -version > /dev/null 2>&1; then
    echo "💡 Java was installed!"
    echo "But it is not available in the current PATH."
    echo "Please open a new terminal and re-run this script."
    exit 0
  fi
fi

echo "Installing vnu.jar..."
mkdir -p ~/.vnux "$BIN_DIR"

if ! curl -fL -o "$JAR" https://github.com/validator/validator/releases/download/latest/vnu.jar; then
  echo "❌ Failed to download vnu.jar"
  exit 1
fi

# インストール時に jar の Last-Modified 日付を取得して保存する
# Nu はバージョンが常に latest 表記のため、Last-Modified ヘッダーをバージョンとして利用する
_installed_version=$(curl -fsSLI https://github.com/validator/validator/releases/download/latest/vnu.jar \
  | grep -i "^last-modified:" \
  | cut -d' ' -f2- \
  | tr -d '\r')
if [[ -n "$_installed_version" ]]; then
  printf '%s\n' "$_installed_version" > "$HOME/.vnux/version"
  printf '%s\n' "$_installed_version" > "$HOME/.vnux/latest-version"
  printf '%s\n' "$(date +%s)" > "$HOME/.vnux/latest-version.checked_at"
fi

echo "✅ vnu.jar installed"

echo "Installing vnux command..."
if ! curl -fL -o "$VNUX_BIN" "$VNUX_RELEASE_URL"; then
  echo "❌ Failed to download vnux command"
  exit 1
fi
chmod +x "$VNUX_BIN"

echo "✅ vnux command installed!"
echo "Run: vnux"
echo "If the command is not found, open a new terminal or run: source ~/.zshenv"
