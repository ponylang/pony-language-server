// https://github.com/zigtools/zls-vscode/blob/master/src/extension.ts

// git tags by date
// git tag --sort=-creatordate

import { ExtensionContext, window, StatusBarAlignment, StatusBarItem, workspace, OutputChannel } from 'vscode';

import {
  ExecutableOptions,
  LanguageClient,
  LanguageClientOptions,
  ServerOptions,
  TransportKind,
} from 'vscode-languageclient/node';

let client: LanguageClient;
let outputChannel: OutputChannel;

export async function activate(context: ExtensionContext) {
  outputChannel = window.createOutputChannel("Pony Language Server");

  let exe = context.asAbsolutePath("pony-lsp");
  showPony(true);
  // If the extension is launched in debug mode then the debug server options are used
  // Otherwise the run options are used
  let serverOptions: ServerOptions = {
    command: exe,
    args: ["stdio"],
    transport: TransportKind.stdio,
    options: {
      env: {
        "PONYPATH": context.asAbsolutePath("packages"),
      }
    }
  };

  // Options to control the language client
  let clientOptions: LanguageClientOptions = {
    documentSelector: [{ scheme: "file", language: "pony" }],
    diagnosticCollectionName: "Pony",
    stdioEncoding: "utf-8",
    traceOutputChannel: outputChannel,
    outputChannel: outputChannel,
  };

  // Create the language client and start the client.
  client = new LanguageClient(
    'pony',
    'Pony Language Server',
    serverOptions,
    clientOptions
  );

  outputChannel.appendLine("PonyLSP client ready");
  // Start the client. This will also launch the server
  return client.start().catch(reason => {
    window.showWarningMessage(`Failed to run Pony Language Server (PLS): ${reason}`);
    showPony(false);
    client = null;
  });
}

export function deactivate(): Thenable<void> | undefined {
  if (!client) {
    return undefined;
  }
  return client.stop();
}

export var ponyVerEntry: StatusBarItem;

export function showPony(good) {
  ponyVerEntry = window.createStatusBarItem(StatusBarAlignment.Left);
  if (good) ponyVerEntry.text = `Pony LSP ✓`;
  else ponyVerEntry.text = `Pony LSP ✗`;
  ponyVerEntry.show();
}
