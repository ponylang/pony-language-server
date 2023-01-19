$Env:PONY_VERSION=0.53.0
Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/ponylang/ponyup/latest-release/ponyup-init.ps1' -Outfile ponyup-init.ps1 &.\ponyup-init.ps1
ponyup update ponyc release-$Env:PONY_VERSION
Set-Location ponyc
git fetch origin
git checkout tags/$Env:PONY_VERSION
Set-Location $Env:GITHUB_WORKSPACE
cp -r ponyc/packages client_vscode
Set-Location $Env:GITHUB_WORKSPACE/client_vscode
# compile the extension
npm i
npm i -g vsce
npm run compile
vsce package