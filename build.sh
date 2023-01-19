#! /bin/bash
# prepare environment
set -e
source ~/.bashrc
# compile pony-lsp
ponyc/build/debug/ponyc
# move pony-lsp binary to the extension folder
mv pony-lsp client_vscode
# we also need the pony stdlib, copy to the extension folder
cp -r ponyc/packages client_vscode
cd client_vscode
# compile the extension
npm run compile