# Pony Language Server

Language server for Pony. See https://github.com/Microsoft/language-server-protocol for more information on the language server standard.

---
## Structure

The Main actor setup everything and maps commands to the proper lsp actor.

The LSP protocol has been divided in actors based on the subcategories of
the spec, these are the pony files starting with `lsp_`.

The different channel implementations reside in the files prefixed with 
`channel_`.

---
## Extensions

The VSCode extension resides in the folder `client_vscode`.


---
## Requirements

- `libponyc-standalone` is needed for pony-ast to compile. Right now it is only built on
linux, for macos you will need this change: https://github.com/ponylang/ponyc/pull/4303. For windows, you will have to find your own way at the moment.
IMPORTANT: libponyc has to be compiled in debug mode


- `stdlib` is required for libponyc to work, so the environment variable
`PONYPATH` has to point to the `packages` folder in the ponyc source code.
For VSCode, we are copying it to the extension folder, and the extension is setting
the env variable (`build.sh`).

---
## Development

To debug in VSCode, press `F5`, this will compile both the vscode extension in the client folder and the pony server, using the `build.sh` script.

If pony compilation fails, the process will stop, so you can press `F5` without fear.

Right now, the Debugger actor residing in `debug.pony` will write anything passed to it to a log file relative to where the vscode debug instance is launched.
This is because you cannot write to output if we use it as a channel to interact with vscode. This has to be updated to use proper LSP logging capabilities.

---
## Packing VSCode extension

You can pack the extension by running `vsce pack` in the client_vscode folder. You
will get a `pony.vsix` file which you can install in vscode using `code --install-extension pony.vsix` 