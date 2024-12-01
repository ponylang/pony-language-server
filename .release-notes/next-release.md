## Fix workspace discovery of folders without corral.json

Now every folder not inside a folder having a `corral.json`, but with a `main.pony` is now properly discovered
as a workspace by the language server. A workspace is a sub-project inside the folder opened in the editor.
The Pony language server can only work with folders marked as workspaces.

## Properly discover all packages of a program

Previously the Language server was only discovering packages mentioned in `corral.json` as packages and dependencies. Now it is considering all packages being part of a program and creating internal data-structures for them. `corral.json` is now only used for discovery of workspaces and populating the programs dependencies.
