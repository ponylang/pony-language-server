$ErrorActionPreference = "Stop"
Set-Location $Env:GITHUB_WORKSPACE
# install zlib
powershell -Command "(Invoke-WebRequest -Uri https://git.io/JnHTY -OutFile install_zlib.bat)"; ./install_zlib.bat; del install_zlib.bat
# install ponyup
Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/ponylang/ponyup/latest-release/ponyup-init.ps1' -Outfile ponyup-init.ps1 
.\ponyup-init.ps1
ponyup update ponyc release-$Env:PONY_VERSION
Set-Location ponyc
git fetch origin
git checkout tags/$Env:PONY_VERSION
Set-Location $Env:GITHUB_WORKSPACE
ponyc
Copy-Item -force -r ponyc/packages client_vscode
Set-Location $Env:GITHUB_WORKSPACE/client_vscode
# compile the extension
npm i
npm i -g vsce
npm run compile
vsce package