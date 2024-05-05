# Ponylang Language Server Client for VS-Code

## How to Build

```bash
# compile the code
$ npm install
$ npm run compile
# build the package
$ vsce package <VERSION>
# uninstall any previously installed packages
$ code --uninstall-extension undefined_publisher.pony-lsp
# install the package
$ code --install-extension pony-lsp-<VERSION>.vsix
```
