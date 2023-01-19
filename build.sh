#! /bin/bash
# prepare environment
set -e
source ~/.bashrc
# compile pony-lsp
ponyc/build/debug/ponyc -o client_vscode -b pony-lsp
# we also need the pony stdlib, copy to the extension folder
cp -r ponyc/packages client_vscode
cd client_vscode
# compile the extension
npm i
npm i -g vsce
npm run compile
vsce package