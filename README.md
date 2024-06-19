# Pony Language Server

Language server for Pony. For more information see the [Language Server Standard](https://github.com/Microsoft/language-server-protocol).

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

- Build ponyc: `cd ponyc`, `make libs`, `make configure`, `make build`

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
