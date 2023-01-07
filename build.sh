#! /bin/bash
set -e
source ~/.bashrc
ponyc
mv pony-lsp client
cd client
npm run compile