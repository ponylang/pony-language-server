#! /bin/bash
# prepare environment
set -ex

PONY_VERSION=0.58.2

# compile pony-lsp
# cd ponyc && make clean configure build config=debug arch=armv8 && cd ..
corral fetch
corral run -- ponyc --bin-name pony-lsp lsp
# move pony-lsp binary to the extension folder
mv pony-lsp client_vscode
# we also need the pony stdlib, copy to the extension folder
pushd client_vscode
# compile the extension
npm run compile

rm *.vsix
vsce package $PONY_VERSION
popd
