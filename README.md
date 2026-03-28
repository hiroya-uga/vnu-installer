# Nu Html Checker Installer for macOS

A simple one-command script to install and run [Nu Html Checker (vnu)](https://validator.github.io/validator/) on macOS.

See [Nu Html Checker Installer](https://uga.dev/tools/nu-installer/en/) for details.

## Install

```sh
curl -fsSL https://github.com/hiroya-uga/vnu-installer/releases/latest/download/install.sh | zsh
```

The installer performs four main tasks:

1. Installs Temurin JDK through Homebrew if Java isn't already present
2. Downloads vnu.jar to the `~/.vnu` directory
3. Sets up the `~/.local/bin/vnu` command
4. Incorporates `~/.local/bin` into your PATH via `~/.zshenv`

## Usage

- **`vnu`** — Launches the checker at http://localhost:8888 and opens it in a browser
- **`vnu --port PORT`** — Launches the checker on a specific port (e.g. `vnu --port 9090`)
- **`vnu check <file>`** — Validates an HTML file
- **`vnu check --html <html>`** — Validates an HTML string
- **`vnu check --snippet <html>`** — Validates an HTML fragment (auto-wrapped in a full document)
- **`vnu --version`** — Displays the release date of the installed vnu.jar
- **`vnu --update`** — Upgrades vnu.jar to the newest version
- **`vnu --stop`** — Halts the active vnu process
- **`vnu --uninstall`** — Removes vnu and associated files
- **`vnu --help`** — Provides usage information

