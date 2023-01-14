#! /bin/bash
set -e
source ~/.bashrc
ponyc/build/release/ponyc
mv pony-lsp client_vscode
cp -r ponyc/packages client_vscode
cd client_vscode
npm run compile