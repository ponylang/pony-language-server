#! /bin/bash
# prepare environment
export SHELL=/bin/bash
PONY_VERSION=0.53.0
set -e
sh -c "$(curl --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/ponylang/ponyup/latest-release/ponyup-init.sh)"
# Use ponyup to install ponyc
ponyup update ponyc release-$PONY_VERSION
# compile pony-lsp
# ponyc/build/debug/ponyc -o client_vscode -b pony-lsp
# we also need the pony stdlib, copy to the extension folder
cd ponyc && git fetch origin && git checkout tags/$PONY_VERSION
cp -r ponyc/packages client_vscode
cd client_vscode
# compile the extension
npm i
npm i -g vsce
npm run compile
vsce package