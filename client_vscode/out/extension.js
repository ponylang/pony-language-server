"use strict";
// https://github.com/zigtools/zls-vscode/blob/master/src/extension.ts
Object.defineProperty(exports, "__esModule", { value: true });
exports.showPony = exports.ponyVerEntry = exports.deactivate = exports.activate = void 0;
const vscode_1 = require("vscode");
const node_1 = require("vscode-languageclient/node");
let client;
let outputChannel;
async function activate(context) {
    outputChannel = vscode_1.window.createOutputChannel("Pony Language Server");
    let exe = context.asAbsolutePath("pony-lsp");
    showPony(true);
    // If the extension is launched in debug mode then the debug server options are used
    // Otherwise the run options are used
    let serverOptions = {
        command: exe,
        args: ["stdio"],
        transport: node_1.TransportKind.stdio,
        options: {
            env: {
                "PONYPATH": context.asAbsolutePath("packages"),
            }
        }
    };
    // Options to control the language client
    let clientOptions = {
        documentSelector: [{ scheme: "file", language: "pony" }],
        diagnosticCollectionName: "Pony",
        stdioEncoding: "utf-8",
        traceOutputChannel: outputChannel,
        outputChannel: outputChannel,
    };
    // Create the language client and start the client.
    client = new node_1.LanguageClient('pony', 'Pony Language Server', serverOptions, clientOptions);
    outputChannel.appendLine("Pony LSP ready");
    // Start the client. This will also launch the server
    return client.start().catch(reason => {
        vscode_1.window.showWarningMessage(`Failed to run Pony Language Server (PLS): ${reason}`);
        showPony(false);
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
function showPony(good) {
    exports.ponyVerEntry = vscode_1.window.createStatusBarItem(vscode_1.StatusBarAlignment.Left);
    if (good)
        exports.ponyVerEntry.text = `Pony LSP ✓`;
    else
        exports.ponyVerEntry.text = `Pony LSP ✗`;
    exports.ponyVerEntry.show();
}
exports.showPony = showPony;
//# sourceMappingURL=extension.js.map