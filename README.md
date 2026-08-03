# bookstore

## Install

```sh
curl -fsSL https://github.com/cladam/tbdflow-ui/releases/latest/download/install.sh | sh
```

This downloads the pre-built binary for your platform (`macos-arm64` or `linux-x86_64`) and installs it to `~/.local/bin`. Override the install directory with `TBDFLOW_INSTALL_DIR`:

```sh
EBI_INSTALL_DIR=/usr/local/bin curl -fsSL https://github.com/cladam/tbdflow-ui/releases/latest/download/install.sh | sh
```

## Prerequisites

- SDL2: `brew install sdl2` (macOS) or `sudo apt-get install libsdl2-dev` (Linux)

## Usage

```sh
hica build   # compile to binary
hica run     # compile and run
hica fmt     # format according to hica style guide
hica check   # type-check without emitting
hica clean   # remove generated files
```

Requires [hica](https://www.hica.dev) on `PATH`.
