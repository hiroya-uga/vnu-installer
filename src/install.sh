#!/usr/bin/env zsh

BIN_DIR="$HOME/.local/bin"
VNU_BIN="$BIN_DIR/vnu"
JAR="$HOME/.vnu/vnu.jar"
VNU_RELEASE_URL="https://github.com/hiroya-uga/vnu-installer/releases/latest/download/vnu"

if ! grep -Fq '.local/bin' ~/.zshenv 2>/dev/null; then
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshenv
  export PATH="$BIN_DIR:$PATH"
  echo "Added ~/.local/bin to PATH (~/.zshenv)"
fi

if [[ -f "$VNU_BIN" ]]; then
  echo "💡 vnu is already installed"
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
mkdir -p ~/.vnu "$BIN_DIR"

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
  printf '%s\n' "$_installed_version" > "$HOME/.vnu/version"
  printf '%s\n' "$_installed_version" > "$HOME/.vnu/latest-version"
  printf '%s\n' "$(date +%s)" > "$HOME/.vnu/latest-version.checked_at"
fi

echo "✅ vnu.jar installed"

echo "Installing vnu command..."
if ! curl -fL -o "$VNU_BIN" "$VNU_RELEASE_URL"; then
  echo "❌ Failed to download vnu command"
  exit 1
fi
chmod +x "$VNU_BIN"

echo "✅ vnu command installed!"
echo "Run: vnu"
echo "If the command is not found, open a new terminal or run: source ~/.zshenv"
