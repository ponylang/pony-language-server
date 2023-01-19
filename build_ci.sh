#! /bin/bash
PONY_VERSION=0.53.0

# SCRIPT
set -e
export SHELL=/bin/bash
# Linux
export PATH=/home/runner/.local/share/ponyup/bin:$PATH
# MacOS
export PATH=/Users/runner/.local/share/ponyup/bin:$PATH
sh -c "$(curl --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/ponylang/ponyup/latest-release/ponyup-init.sh)"
ponyup update ponyc release-$PONY_VERSION
cd ponyc && git fetch origin && git checkout tags/$PONY_VERSION
cd $GITHUB_WORKSPACE && cp -r ponyc/packages client_vscode
cd $GITHUB_WORKSPACE && ponyc
cd $GITHUB_WORKSPACE/client_vscode
# compile the extension
npm i
npm i -g vsce
npm run compile
vsce package