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
- **`vnu serve`** — Same as above (explicit form)
- **`vnu serve --port PORT`** — Launches the checker on a specific port (e.g. `vnu serve --port 9090`)
- **`vnu check <file.html>`** — Validates an HTML file (auto-detected by `.html`/`.htm` extension)
- **`vnu check <https://...>`** — Validates a URL (auto-detected by `https://` prefix)
- **`vnu check '<p>...</p>'`** — Validates an HTML fragment (auto-detected by `<` prefix)
- **`vnu check --file <file>`** — Validates a file (explicit)
- **`vnu check --url <url>`** — Validates a URL (explicit)
- **`vnu check --html <html>`** — Validates a full HTML string (explicit)
- **`vnu check --snippet <html>`** — Validates an HTML fragment, auto-wrapped in a full document (explicit)
- **`vnu stop`** — Halts the active vnu process
- **`vnu update`** — Upgrades vnu.jar to the newest version
- **`vnu uninstall`** — Removes vnu and associated files
- **`vnu --version`** — Displays the release date of the installed vnu.jar
- **`vnu --help`** — Provides usage information

