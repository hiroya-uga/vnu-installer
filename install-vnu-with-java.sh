#!/usr/bin/env zsh

BIN_DIR="$HOME/.local/bin"
VNU_BIN="$BIN_DIR/vnu"
JAR="$HOME/.vnu/vnu.jar"

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
    echo "✅ Java was installed!"
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
# Nuはバージョンが常に latest 表記のため、Last-Modified ヘッダーをバージョンとして利用する
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

cat > "$VNU_BIN" << 'EOF'
#!/usr/bin/env zsh
JAR="$HOME/.vnu/vnu.jar"
PID_FILE="$HOME/.vnu/vnu.pid"
VERSION_FILE="$HOME/.vnu/version"
LATEST_VERSION_FILE="$HOME/.vnu/latest-version"
LATEST_CHECKED_AT_FILE="$HOME/.vnu/latest-version.checked_at"
CACHE_TTL=3600

# PIDファイルのプロセスが nu.validator として生存しているか確認する（LISTEN判定は含まない）
_vnu_is_process_alive() {
  [[ -f "$PID_FILE" ]] || return 1
  local pid
  pid=$(<"$PID_FILE") || return 1
  kill -0 "$pid" 2>/dev/null || { rm -f "$PID_FILE"; return 1; }
  ps -p "$pid" -o args= 2>/dev/null | grep -Fq 'nu.validator.servlet.Main' || { rm -f "$PID_FILE"; return 1; }
}

# プロセスが生存していて、かつポート 8888 で LISTEN しているか確認する
_vnu_is_ready() {
  _vnu_is_process_alive || return 1
  local pid
  pid=$(<"$PID_FILE")
  lsof -a -p "$pid" -i :8888 -sTCP:LISTEN > /dev/null 2>&1
}

# PIDファイルに記録されたプロセスのみを停止する
_vnu_stop() {
  if ! _vnu_is_process_alive; then
    echo "⚠️ vnu is not running"
    rm -f "$PID_FILE"
    return 1
  fi

  local pid
  pid=$(<"$PID_FILE")

  if kill "$pid" 2>/dev/null; then
    echo "💤 vnu stopped (pid: $pid)"
    rm -f "$PID_FILE"
  else
    echo "❌ Failed to stop vnu (pid: $pid)"
    return 1
  fi
}

# キャッシュが有効か確認
_vnu_is_latest_cache_enabled() {
  [[ -f "$LATEST_VERSION_FILE" && -f "$LATEST_CHECKED_AT_FILE" ]] || return 1
  local checked_at now
  checked_at=$(<"$LATEST_CHECKED_AT_FILE") || return 1
  now=$(date +%s)
  (( now - checked_at < CACHE_TTL ))
}

# jar の Last-Modified ヘッダーから日付を取得する
# 取得失敗時は空文字を返す（呼び出し側で警告を出す）
_vnu_get_last_modified_as_version() {
  if _vnu_is_latest_cache_enabled; then
    cat "$LATEST_VERSION_FILE"
    return 0
  fi

  local latest
  latest=$(curl -fsSLI https://github.com/validator/validator/releases/download/latest/vnu.jar \
    | grep -i "^last-modified:" \
    | cut -d' ' -f2- \
    | tr -d '\r')

  if [[ -z "$latest" ]]; then
    return 1
  fi

  printf '%s\n' "$latest" > "$LATEST_VERSION_FILE"
  printf '%s\n' "$(date +%s)" > "$LATEST_CHECKED_AT_FILE"
  printf '%s\n' "$latest"
}

# バージョンを返す
_vnu_get_installed_version() {
  [[ -f "$VERSION_FILE" ]] && cat "$VERSION_FILE" || echo "(unknown)"
}

# 起動時にバックグラウンドでアップデートチェックを行う
_vnu_check_update_async() {
  (
    local current latest
    current=$(_vnu_get_installed_version)
    [[ "$current" == "(unknown)" ]] && return

    latest=$(_vnu_get_last_modified_as_version 2>/dev/null) || return
    [[ -z "$latest" ]] && return
    [[ "$current" == "$latest" ]] && return

    echo "💡 Update available: $current → $latest  (run: vnu --update)"
  ) &
}

case "$1" in
  --help)
    echo "Usage: vnu [option]"
    echo ""
    echo "Options:"
    echo "  (none)       Start vnu server and open http://localhost:8888/"
    echo "  --version    Show the installed vnu.jar version"
    echo "  --update     Update vnu.jar to the latest version"
    echo "  --stop       Stop the running vnu server"
    echo "  --uninstall  Uninstall vnu and remove all related files"
    echo "  --help       Show this help message"
    ;;

  --version)
    ver=$(_vnu_get_installed_version)
    if [[ "$ver" == "(unknown)" ]]; then
      echo "vnu (unknown)"
    else
      echo "vnu latest at $(echo "$ver" | awk '{print $2, $3, $4}')"
    fi
    _vnu_check_update_async
    ;;

  --update)
    current=$(_vnu_get_installed_version)

    echo "Checking for updates..."
    latest=$(_vnu_get_last_modified_as_version 2>/dev/null)

    if [[ -z "$latest" ]]; then
      echo "⚠️ Failed to fetch the latest version. Proceeding with update anyway..."
    elif [[ "$current" == "$latest" ]]; then
      echo "✅ vnu is already up to date ($current)"
      exit 0
    else
      echo "Updating $current → $latest"
    fi

    # 起動中なら停止してからアップデート
    if _vnu_is_process_alive; then
      echo "Stopping vnu before update..."
      _vnu_stop
    fi

    mkdir -p "$HOME/.vnu"
    if ! curl -fL -o "$JAR" https://github.com/validator/validator/releases/download/latest/vnu.jar; then
      echo "❌ Failed to download vnu.jar"
      exit 1
    fi

    # アップデート後にバージョンを保存
    if [[ -n "$latest" ]]; then
      printf '%s\n' "$latest" > "$VERSION_FILE"
      printf '%s\n' "$latest" > "$LATEST_VERSION_FILE"
      printf '%s\n' "$(date +%s)" > "$LATEST_CHECKED_AT_FILE"
      echo "✅ vnu updated to $latest"
    else
      echo "✅ vnu updated"
    fi
    ;;

  --stop)
    _vnu_stop
    ;;

  --uninstall)
    if _vnu_is_process_alive; then
      _vnu_stop > /dev/null 2>&1
    fi
    rm -f "$HOME/.local/bin/vnu"
    rm -f \
      "$HOME/.vnu/vnu.jar" \
      "$HOME/.vnu/vnu.pid" \
      "$HOME/.vnu/version" \
      "$HOME/.vnu/latest-version" \
      "$HOME/.vnu/latest-version.checked_at"
    rmdir "$HOME/.vnu" 2>/dev/null
    echo "🗑️ vnu uninstalled"
    ;;

  "")
    [[ -f "$JAR" ]] || { echo "vnu.jar not found. Run: vnu --update"; exit 1; }

    if _vnu_is_ready; then
      echo "⚠️ vnu is already running"
      _vnu_check_update_async
      open http://localhost:8888/
      exit 0
    fi

    echo "Starting..."
    java -Dnu.validator.servlet.bind-address=127.0.0.1 -cp "$JAR" nu.validator.servlet.Main 8888 &
    local_pid=$!
    echo "$local_pid" > "$PID_FILE"

    for i in $(seq 1 20); do
      if _vnu_is_ready; then
        _vnu_check_update_async
        open http://localhost:8888/
        exit 0
      fi
      sleep 0.5
    done

    # 起動タイムアウト
    _vnu_stop > /dev/null 2>&1
    echo "❌ vnu did not start within 10s"
    exit 1
    ;;

  *)
    echo "Unknown option: $1"
    echo "Run 'vnu --help' for usage."
    exit 1
    ;;
esac
EOF

chmod +x "$VNU_BIN"
echo "✅ vnu command installed!"
echo "Run: vnu"
echo "If the command is not found, open a new terminal or run: source ~/.zshenv"
