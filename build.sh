#! /bin/bash
set -e
source ~/.bashrc
ponyc
mv pony-lsp client
cd client_vscode
npm run compile