"use strict";
// https://github.com/bung87/vscode-nim-lsp
Object.defineProperty(exports, "__esModule", { value: true });
exports.getExecutableInfo = exports.getBinPath = exports.getDirtyFile = exports.updatePonyProgress = exports.showPonyVer = exports.showPonyProgress = exports.showPonyStatus = exports.hidePonyProgress = exports.hidePonyStatus = exports.showHideStatus = exports.ponyVerEntry = exports.deactivate = exports.activate = void 0;
const vscode_1 = require("vscode");
const node_1 = require("vscode-languageclient/node");
const fs = require("fs");
const path = require("path");
const cp = require("child_process");
const util = require("util");
const os = require("os");
const which = require("which");
let client;
async function activate(context) {
    showPonyVer();
    // The server is implemented in node
    let serverModule = context.asAbsolutePath('../pony-lsp');
    // If the extension is launched in debug mode then the debug server options are used
    // Otherwise the run options are used
    let serverOptions = {
        run: { module: serverModule, transport: node_1.TransportKind.stdio },
        debug: { module: serverModule, transport: node_1.TransportKind.stdio },
    };
    // Options to control the language client
    let clientOptions = {
        outputChannelName: "Pony LSP client",
        diagnosticCollectionName: 'pony',
        revealOutputChannelOn: node_1.RevealOutputChannelOn.Never,
        // Register the server for plain text documents
        documentSelector: [{ language: 'pony' }],
        synchronize: {
            // Notify the server about file changes to '.clientrc files contained in the workspace
            fileEvents: vscode_1.workspace.createFileSystemWatcher('**/.pony')
        }
    };
    // Create the language client and start the client.
    client = new node_1.LanguageClient('pony', 'pony', serverOptions, clientOptions, true);
    // Start the client. This will also launch the server
    client.start();
}
exports.activate = activate;
function deactivate() {
    if (!client) {
        return undefined;
    }
    return client.stop();
}
exports.deactivate = deactivate;
var statusBarEntry;
var progressBarEntry;
function showHideStatus() {
    if (!statusBarEntry) {
        return;
    }
    if (!vscode_1.window.activeTextEditor) {
        statusBarEntry.hide();
        exports.ponyVerEntry.hide();
        return;
    }
    if (vscode_1.languages.match('**/.pony', vscode_1.window.activeTextEditor.document)) {
        statusBarEntry.show();
        exports.ponyVerEntry.show();
        return;
    }
    statusBarEntry.hide();
}
exports.showHideStatus = showHideStatus;
function hidePonyStatus() {
    statusBarEntry.dispose();
}
exports.hidePonyStatus = hidePonyStatus;
function hidePonyProgress() {
    progressBarEntry.dispose();
}
exports.hidePonyProgress = hidePonyProgress;
function showPonyStatus(message, command, tooltip) {
    statusBarEntry = vscode_1.window.createStatusBarItem(vscode_1.StatusBarAlignment.Right, Number.MIN_VALUE);
    statusBarEntry.text = message;
    statusBarEntry.command = command;
    statusBarEntry.color = 'yellow';
    statusBarEntry.tooltip = tooltip;
    statusBarEntry.show();
}
exports.showPonyStatus = showPonyStatus;
function showPonyProgress(message) {
    progressBarEntry = vscode_1.window.createStatusBarItem(vscode_1.StatusBarAlignment.Right, Number.MIN_VALUE);
    progressBarEntry.text = message;
    progressBarEntry.tooltip = message;
    progressBarEntry.show();
}
exports.showPonyProgress = showPonyProgress;
function showPonyVer() {
    exports.ponyVerEntry = vscode_1.window.createStatusBarItem(vscode_1.StatusBarAlignment.Left);
    exports.ponyVerEntry.text = `Pony LSP`;
    exports.ponyVerEntry.show();
}
exports.showPonyVer = showPonyVer;
function updatePonyProgress(message) {
    progressBarEntry.text = message;
}
exports.updatePonyProgress = updatePonyProgress;
const writeFile = util.promisify(fs.writeFile);
const notInPathError = 'No %s binary could be found in PATH environment variable';
let _pathesCache = {};
async function getDirtyFile(document) {
    var dirtyFilePath = path.normalize(path.join(os.tmpdir(), 'vscodenimdirty.nim'));
    await writeFile(dirtyFilePath, document.getText());
    return dirtyFilePath;
}
exports.getDirtyFile = getDirtyFile;
async function getBinPath(tool) {
    if (_pathesCache[tool]) {
        return Promise.resolve(_pathesCache[tool]);
    }
    const toolPath = await which(tool);
    if (toolPath) {
        _pathesCache[tool] = toolPath;
    }
    return _pathesCache[tool];
}
exports.getBinPath = getBinPath;
async function getExecutableInfo(exe) {
    var exePath, exeVersion = '';
    let configuredExePath = vscode_1.workspace.getConfiguration(exe).get(exe);
    if (configuredExePath) {
        exePath = configuredExePath;
    }
    else {
        exePath = await getBinPath(exe);
    }
    if (exePath && fs.existsSync(exePath)) {
        const output = cp.spawnSync(exePath, ['--version']).output;
        if (!output) {
            return Promise.resolve({
                name: exe,
                path: exePath,
            });
        }
        let versionOutput = output.toString();
        let versionArgs = /(?:(\d+)\.)?(?:(\d+)\.)?(\*|\d+)/g.exec(versionOutput);
        if (versionArgs) {
            exeVersion = versionArgs[0];
        }
        return Promise.resolve({
            name: exe,
            path: exePath,
            version: exeVersion,
        });
    }
    else {
        let msg = util.format(notInPathError, exe);
        vscode_1.window.showErrorMessage(msg);
        return Promise.reject();
    }
}
exports.getExecutableInfo = getExecutableInfo;
//# sourceMappingURL=extension.js.map