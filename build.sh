#! /bin/bash
set -e
source ~/.bashrc
ponyc
mv pony-lsp client_vscode
cd client_vscode
npm run compile