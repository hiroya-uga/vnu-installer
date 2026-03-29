# Nu Html Checker Installer for macOS

Install and run [Nu Html Checker (vnu)](https://validator.github.io/validator/) locally with a single command.

See [Nu Html Checker Installer](https://uga.dev/tools/nu-installer/en/) for details.

## Install

```sh
curl -fsSL https://github.com/hiroya-uga/vnu-installer/releases/latest/download/install.sh | zsh
```

The installer performs four main tasks:

1.  Installs Temurin JDK via Homebrew if Java is not already installed
2.  Downloads `vnu.jar` to `~/.vnu`
3.  Creates the `~/.local/bin/vnu` command
4.  Adds `~/.local/bin` to your PATH via `~/.zshenv`

## Usage

- **`vnu`** — Alias for `vnu start`
- **`vnu start`** — Starts the checker on http://localhost:8888 and opens
  it in your browser
- **`vnu start --port <PORT>`** — Starts the checker on a specific port and
  opens it in your browser (e.g. `vnu start --port 9090`)
- **`vnu serve`** — Starts the checker without opening the browser
- **`vnu serve --port <PORT>`** — Starts the checker on a specific port
  (e.g. `vnu serve --port 9090`)
- **`vnu check <value>`** — Auto-detection: pass a URL, `<!doctype...>` string, `<p>...</p>`, or a file path directly without flags.
- **`vnu check --file <file>`** — Validates an HTML file
- **`vnu check --url <url>`** — Validates a URL
- **`vnu check --html '<html>'`** — Validates a full HTML string
- **`vnu check --fragment '<p>...</p>'`** — Validates an HTML
  fragment (auto-wrapped in a full document)
- **`vnu stop`** — Stops the running vnu process
- **`vnu update`** — Updates vnu.jar to the latest version
- **`vnu uninstall`** — Removes vnu and related files
- **`vnu --version`** — Shows the release date of the installed vnu.jar
- **`vnu --help`** — Shows usage information
