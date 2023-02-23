#! /bin/bash
# prepare environment
set -e
source ~/.bashrc
set -x
# compile pony-lsp
# cd ponyc && make clean configure build config=debug arch=armv8 && cd ..
corral run -- ponyc/build/release/ponyc --bin-name pony-lsp lsp
# move pony-lsp binary to the extension folder
mv pony-lsp client_vscode
# we also need the pony stdlib, copy to the extension folder
cp -r ponyc/packages client_vscode
cd client_vscode
# compile the extension
npm run compile