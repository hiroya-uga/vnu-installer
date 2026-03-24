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
echo "✅ vnu.jar installed"

cat > "$VNU_BIN" << 'EOF'
#!/usr/bin/env zsh
JAR="$HOME/.vnu/vnu.jar"
PID_FILE="$HOME/.vnu/vnu.pid"

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

case "$1" in
  --help)
    echo "Usage: vnu [option]"
    echo ""
    echo "Options:"
    echo "  (none)       Start vnu server and open http://localhost:8888/"
    echo "  --update     Update vnu.jar to the latest version"
    echo "  --stop       Stop the running vnu server"
    echo "  --uninstall  Uninstall vnu and remove all related files"
    echo "  --help       Show this help message"
    ;;

  --update)
    mkdir -p "$HOME/.vnu"
    if ! curl -fL -o "$JAR" https://github.com/validator/validator/releases/download/latest/vnu.jar; then
      echo "❌ Failed to download vnu.jar"
      exit 1
    fi
    echo "✅ vnu updated"
    ;;

  --stop)
    _vnu_stop
    ;;

  --uninstall)
    if _vnu_is_process_alive; then
      _vnu_stop > /dev/null 2>&1
    fi
    rm -f "$HOME/.local/bin/vnu"
    rm -f "$HOME/.vnu/vnu.jar" "$HOME/.vnu/vnu.pid"
    rmdir "$HOME/.vnu" 2>/dev/null
    echo "🗑️ vnu uninstalled"
    ;;

  "")
    [[ -f "$JAR" ]] || { echo "vnu.jar not found. Run: vnu --update"; exit 1; }

    if _vnu_is_ready; then
      echo "⚠️ vnu is already running"
      open http://localhost:8888/
      exit 0
    fi

    echo "Starting..."
    java -Dnu.validator.servlet.bind-address=127.0.0.1 -cp "$JAR" nu.validator.servlet.Main 8888 &
    local_pid=$!
    echo "$local_pid" > "$PID_FILE"

    for i in $(seq 1 20); do
      if _vnu_is_ready; then
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