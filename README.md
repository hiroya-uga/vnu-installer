# vnux — Nu Html Checker CLI for macOS

A CLI wrapper for [Nu Html Checker (vnu)](https://validator.github.io/validator/) that adds server lifecycle management, smart auto-detection, and a better developer experience.

See [vnux](https://uga.dev/tools/vnux/en/) for details.

## Install

```sh
curl -fsSL https://github.com/hiroya-uga/vnux/releases/latest/download/install.sh | zsh
```

The installer performs four main tasks:

1.  Installs Temurin JDK via Homebrew if Java is not already installed
2.  Downloads `vnu.jar` to `~/.vnux`
3.  Creates the `~/.local/bin/vnux` command
4.  Adds `~/.local/bin` to your PATH via `~/.zshenv`

## Usage

- **`vnux`** — Alias for `vnux start`
- **`vnux start`** — Starts the vnu server on http://localhost:8888 and opens
  it in your browser
- **`vnux start --port <PORT>`** — Starts the vnu server on a specific port and
  opens it in your browser (e.g. `vnux start --port 9090`)
- **`vnux serve`** — Starts the vnu server without opening the browser
- **`vnux serve --port <PORT>`** — Starts the vnu server on a specific port
  (e.g. `vnux serve --port 9090`)
- **`vnux check <value>`** — Auto-detection: pass a URL, `<!doctype...>` string, `<p>...</p>`, or a file path directly without flags.
- **`vnux check --file <file>`** — Validates an HTML file
- **`vnux check --url <url>`** — Validates a URL
- **`vnux check --html '<html>'`** — Validates a full HTML string
- **`vnux check --fragment '<p>...</p>'`** — Validates an HTML
  fragment (auto-wrapped in a full document)
- **`vnux stop`** — Stops the running vnu process
- **`vnux update`** — Updates vnu.jar and the vnux command to the latest version
- **`vnux uninstall`** — Removes vnux and related files
- **`vnux --version`** — Shows the vnux version and the release date of the installed vnu.jar
- **`vnux --help`** — Shows usage information
