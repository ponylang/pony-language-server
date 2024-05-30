# Pony Language Server

Language server for Pony. See https://github.com/Microsoft/language-server-protocol for more information on the language server standard.

---
## Structure

The language server is started as a separate actor, which is given a channel for communication with the language-server client. After initialization it starts one actor for each workspace it is invoked for and routes requests to one of those workspace actors. They implement the actual LSP logic. It is also those actors that invoke the compiler actor, which executes a subset of the pony compiler passes in-process in order to get an AST to do LSP analysis on.

---
## Extensions

The VSCode extension resides in the folder `client_vscode`.



---
## Development

- Build ponyc: `cd ponyc`, `make libs`, `make configure`, `make build`

- Prepare VSCode extension: `cd client_vscode`, `npm i`

- To debug in VSCode, press `F5`, this will compile both the vscode extension in the client folder and the pony server, using the `build.sh` script.

If pony compilation fails, the process will stop, so you can press `F5` without fear.

---

## Creating the Language Server binary

To compile the binary in release mode:

```
make language_server
```

In order to compile the language server in `debug` mode, set the `config` variable to `debug`:

```
make config=debug language_server
```

## Creating the VSCode extension

You can pack the extension by running `vsce pack` in the client_vscode folder. You
will get a `pony.vsix` file which you can install in vscode using `code --install-extension pony.vsix` 
