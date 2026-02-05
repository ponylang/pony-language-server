# Pony Language Server

> [!WARNING]
> This repository has been archived and is now read-only. The components have been moved to new locations within the Pony ecosystem.

## Where Did Everything Go?

### Language Server (`pony-lsp`)

The `pony-lsp` language server source code has been merged into the main Pony compiler repository:

- Repository: [ponylang/ponyc](https://github.com/ponylang/ponyc)
- Distribution: The language server is now released and distributed together with `ponyc`
- Installation: Install `ponyc` via your preferred package manager to get the `pony-lsp` binary

### VS Code Extension

The Pony Visual Studio Code extension has been moved to its own dedicated repository:

- Repository: [ponylang/vscode-extension](https://github.com/ponylang/vscode-extension)

## For Users

If you're currently using the Pony Language Server or Visual Studio Code extension:

- **pony-lsp**: Install the latest version of `ponyc` to get the `pony-lsp` binary
- **VS Code extension**: Get the newest extension from [ponylang/vscode-extension](https://github.com/ponylang/vscode-extension).

## For Contributors

All future development and contributions should be directed to:

- Language server improvements: [ponylang/ponyc](https://github.com/ponylang/ponyc)
- VS Code extension improvements: [ponylang/vscode-extension](https://github.com/ponylang/vscode-extension)

## Questions?

Come chat with the Pony community via [Zulip](https://ponylang.zulipchat.com/).

---

Thank you to all contributors who helped build this project! 🎉

---

## Historical Documentation

The information below is preserved for historical reference only.

### Language Server Standard

Language server for Pony. For more information see the [Language Server Standard](https://github.com/Microsoft/language-server-protocol).

### Installation (Historical)

#### Homebrew (macOS and Linux)

The easiest way to install `pony-lsp` on macOS and Linux was via Homebrew:

```sh
brew install pony-language-server
```

#### VSCode Extension

The Visual Studio Code extension requires the project to be built from source. See the [Development](#development) section below.

---

## Structure

The language server is started as a separate actor,
which is given a channel for communication with the language-server client.
After initialization it starts one actor for each workspace it is invoked for
and routes requests to one of those workspace actors.
They implement the actual LSP logic.
It is also those actors that invoke the compiler actor,
which executes a subset of the pony compiler passes in-process
in order to get an AST to do LSP analysis on.

---

## Extensions

The VSCode extension resides in the folder `client_vscode`.

---

## Development

### Prerequisites

- **Install ponyc**: The Pony compiler is required for development.

  On macOS and Linux via Homebrew:
  ```sh
  brew install ponyc
  ```

  For other platforms or building from source, see [https://github.com/ponylang/ponyc](https://github.com/ponylang/ponyc)

- **Install corral**: The Pony dependency manager is required for development.

  On macOS and Linux via Homebrew:
  ```sh
  brew install corral
  ```

  For other platforms or building from source, see [https://github.com/ponylang/corral](https://github.com/ponylang/corral)

### Setup Steps

- Prepare VSCode extension: `cd client_vscode`, `npm i`

- To debug in VSCode, press `F5`, this will compile both the vscode extension
  in the client folder and the pony server, using the `build.sh` script.

If pony compilation fails, the process will stop, so you can press `F5` without fear.

---

## Creating the Language Server binary

To compile the binary in release mode:

```sh
make language_server
```

In order to compile the language server in `debug` mode,
set the `config` variable to `debug`:

```sh
make config=debug language_server
```

## Creating the VSCode extension

```sh
make vscode_extension
```

This will create the extension package as a `.vsix` file
in the `build/release` folder. E.g. `build/release/pony-lsp-0.58.4.vsix`.

## Installing the VSCode extension

```sh
code --uninstall-extension undefined_publisher.pony-lsp
code --install-extension build/release/pony-lsp-0.58.4.vsix
```

Check the actual folder and version of the extension being built.
