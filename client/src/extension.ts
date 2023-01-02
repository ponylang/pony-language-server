// https://github.com/bung87/vscode-nim-lsp

import { workspace, ExtensionContext, window, StatusBarAlignment, StatusBarItem, languages } from 'vscode';

import {
  LanguageClient,
  LanguageClientOptions,
  RevealOutputChannelOn,
  ServerOptions,
  TransportKind
} from 'vscode-languageclient/node';

import * as vscode from 'vscode';
import fs = require('fs');
import path = require('path');
import cp = require('child_process');
import util = require('util');
import os = require('os');
import which = require('which');

let client: LanguageClient;

export async function activate(context: ExtensionContext) {
  showPonyVer();
  // The server is implemented in node
  let serverModule = context.asAbsolutePath('../pony-lsp');

  // If the extension is launched in debug mode then the debug server options are used
  // Otherwise the run options are used
  let serverOptions: ServerOptions = {
    run: { module: serverModule, transport: TransportKind.stdio },
    debug: { module: serverModule, transport: TransportKind.stdio },
  };

  // Options to control the language client
  let clientOptions: LanguageClientOptions = {
    outputChannelName: "Pony LSP client",
    diagnosticCollectionName: 'pony',
    revealOutputChannelOn: RevealOutputChannelOn.Never,
    // Register the server for plain text documents
    documentSelector: [{ language: 'pony' }],
    synchronize: {
      // Notify the server about file changes to '.clientrc files contained in the workspace
      fileEvents: workspace.createFileSystemWatcher('**/.pony')
    }
  };

  // Create the language client and start the client.
  client = new LanguageClient(
    'pony',
    'pony',
    serverOptions,
    clientOptions,
    true
  );

  // Start the client. This will also launch the server
  client.start();
}

export function deactivate(): Thenable<void> | undefined {
  if (!client) {
    return undefined;
  }
  return client.stop();
}

var statusBarEntry: StatusBarItem;
var progressBarEntry: StatusBarItem;
export var ponyVerEntry: StatusBarItem;

export function showHideStatus() {
  if (!statusBarEntry) {
    return;
  }
  if (!window.activeTextEditor) {
    statusBarEntry.hide();
    ponyVerEntry.hide();
    return;
  }
  if (languages.match('**/.pony', window.activeTextEditor.document)) {
    statusBarEntry.show();
    ponyVerEntry.show();
    return;
  }
  statusBarEntry.hide();
}

export function hidePonyStatus() {
  statusBarEntry.dispose();
}

export function hidePonyProgress() {
  progressBarEntry.dispose();
}

export function showPonyStatus(message: string, command: string, tooltip?: string) {
  statusBarEntry = window.createStatusBarItem(
    StatusBarAlignment.Right,
    Number.MIN_VALUE,
  );
  statusBarEntry.text = message;
  statusBarEntry.command = command;
  statusBarEntry.color = 'yellow';
  statusBarEntry.tooltip = tooltip;
  statusBarEntry.show();
}

export function showPonyProgress(message: string) {
  progressBarEntry = window.createStatusBarItem(
    StatusBarAlignment.Right,
    Number.MIN_VALUE,
  );
  progressBarEntry.text = message;
  progressBarEntry.tooltip = message;
  progressBarEntry.show();
}

export function showPonyVer() {
  ponyVerEntry = window.createStatusBarItem(StatusBarAlignment.Left);
  ponyVerEntry.text = `Pony LSP`;
  ponyVerEntry.show();
}

export function updatePonyProgress(message: string) {
  progressBarEntry.text = message;
}

const writeFile = util.promisify(fs.writeFile);
const notInPathError = 'No %s binary could be found in PATH environment variable';
let _pathesCache: { [tool: string]: string } = {};

export async function getDirtyFile(document: vscode.TextDocument): Promise<string> {
  var dirtyFilePath = path.normalize(path.join(os.tmpdir(), 'vscodenimdirty.nim'));
  await writeFile(dirtyFilePath, document.getText());
  return dirtyFilePath;
}

export async function getBinPath(tool: string): Promise<string> {
  if (_pathesCache[tool]) {
    return Promise.resolve(_pathesCache[tool]);
  }
  const toolPath = await which(tool);
  if (toolPath) {
    _pathesCache[tool] = toolPath
  }
  return _pathesCache[tool];
}

export async function getExecutableInfo(exe: string): Promise<ExecutableInfo> {
  var exePath,
    exeVersion: string = '';

  let configuredExePath = <string>workspace.getConfiguration(exe).get(exe);
  if (configuredExePath) {
    exePath = configuredExePath;
  } else {
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
  } else {
    let msg = util.format(notInPathError, exe);
    window.showErrorMessage(msg);
    return Promise.reject();
  }
}

export interface ExecutableInfo {
  name: string;
  path: string;
  version?: string;
}