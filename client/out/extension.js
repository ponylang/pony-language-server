"use strict";
// https://github.com/zigtools/zls-vscode/blob/master/src/extension.ts
Object.defineProperty(exports, "__esModule", { value: true });
exports.showPony = exports.ponyVerEntry = exports.deactivate = exports.activate = void 0;
const vscode_1 = require("vscode");
const node_1 = require("vscode-languageclient/node");
let client;
async function activate(context) {
    let exe = context.asAbsolutePath("pony-lsp");
    vscode_1.window.showWarningMessage(`Absolute path pony-lsp :${exe}:`);
    showPony(exe);
    // If the extension is launched in debug mode then the debug server options are used
    // Otherwise the run options are used
    let serverOptions = {
        command: exe,
        args: ["stdio"]
    };
    // Options to control the language client
    let clientOptions = {
        documentSelector: [{ scheme: "file", language: "zig" }],
        outputChannelName: "Pony LSP client",
        // synchronize: {
        //   // Notify the server about file changes to '.clientrc files contained in the workspace
        //   fileEvents: workspace.createFileSystemWatcher('**/.pony')
        // }
    };
    // Create the language client and start the client.
    client = new node_1.LanguageClient('pony', 'Pony Language Server', serverOptions, clientOptions);
    // Start the client. This will also launch the server
    return client.start().catch(reason => {
        vscode_1.window.showWarningMessage(`Failed to run Pony Language Server (PLS): ${reason}`);
        client = null;
    });
}
exports.activate = activate;
function deactivate() {
    if (!client) {
        return undefined;
    }
    return client.stop();
}
exports.deactivate = deactivate;
function showPony(p) {
    exports.ponyVerEntry = vscode_1.window.createStatusBarItem(vscode_1.StatusBarAlignment.Left);
    exports.ponyVerEntry.text = `Pony LSP ` + p;
    exports.ponyVerEntry.show();
}
exports.showPony = showPony;
//# sourceMappingURL=extension.js.map