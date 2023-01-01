// class TextDocumentClientCapabilities
    // var synchronization: None | TextDocumentSyncClientCapabilities = None
	// // Capabilities specific to the `textDocument/completion` request.
	// var completion: None | CompletionClientCapabilities = None
	// // Capabilities specific to the `textDocument/hover` request.
	// var hover: None | HoverClientCapabilities = None
	// // Capabilities specific to the `textDocument/signatureHelp` request.
	// var signatureHelp: None | SignatureHelpClientCapabilities = None
	// //Capabilities specific to the `textDocument/declaration` request.
	// var declaration: None | DeclarationClientCapabilities = None
	// /**
	//  * Capabilities specific to the `textDocument/definition` request.
	//  */
	// definition?: DefinitionClientCapabilities;

	// /**
	//  * Capabilities specific to the `textDocument/typeDefinition` request.
	//  *
	//  * @since 3.6.0
	//  */
	// typeDefinition?: TypeDefinitionClientCapabilities;

	// /**
	//  * Capabilities specific to the `textDocument/implementation` request.
	//  *
	//  * @since 3.6.0
	//  */
	// implementation?: ImplementationClientCapabilities;

	// /**
	//  * Capabilities specific to the `textDocument/references` request.
	//  */
	// references?: ReferenceClientCapabilities;

	// /**
	//  * Capabilities specific to the `textDocument/documentHighlight` request.
	//  */
	// documentHighlight?: DocumentHighlightClientCapabilities;

	// /**
	//  * Capabilities specific to the `textDocument/documentSymbol` request.
	//  */
	// documentSymbol?: DocumentSymbolClientCapabilities;

	// /**
	//  * Capabilities specific to the `textDocument/codeAction` request.
	//  */
	// codeAction?: CodeActionClientCapabilities;

	// /**
	//  * Capabilities specific to the `textDocument/codeLens` request.
	//  */
	// codeLens?: CodeLensClientCapabilities;

	// /**
	//  * Capabilities specific to the `textDocument/documentLink` request.
	//  */
	// documentLink?: DocumentLinkClientCapabilities;

	// /**
	//  * Capabilities specific to the `textDocument/documentColor` and the
	//  * `textDocument/colorPresentation` request.
	//  *
	//  * @since 3.6.0
	//  */
	// colorProvider?: DocumentColorClientCapabilities;

	// /**
	//  * Capabilities specific to the `textDocument/formatting` request.
	//  */
	// formatting?: DocumentFormattingClientCapabilities;

	// /**
	//  * Capabilities specific to the `textDocument/rangeFormatting` request.
	//  */
	// rangeFormatting?: DocumentRangeFormattingClientCapabilities;

	// /** request.
	//  * Capabilities specific to the `textDocument/onTypeFormatting` request.
	//  */
	// onTypeFormatting?: DocumentOnTypeFormattingClientCapabilities;

	// /**
	//  * Capabilities specific to the `textDocument/rename` request.
	//  */
	// rename?: RenameClientCapabilities;

	// /**
	//  * Capabilities specific to the `textDocument/publishDiagnostics`
	//  * notification.
	//  */
	// publishDiagnostics?: PublishDiagnosticsClientCapabilities;

	// /**
	//  * Capabilities specific to the `textDocument/foldingRange` request.
	//  *
	//  * @since 3.10.0
	//  */
	// foldingRange?: FoldingRangeClientCapabilities;

	// /**
	//  * Capabilities specific to the `textDocument/selectionRange` request.
	//  *
	//  * @since 3.15.0
	//  */
	// selectionRange?: SelectionRangeClientCapabilities;

	// /**
	//  * Capabilities specific to the `textDocument/linkedEditingRange` request.
	//  *
	//  * @since 3.16.0
	//  */
	// linkedEditingRange?: LinkedEditingRangeClientCapabilities;

	// /**
	//  * Capabilities specific to the various call hierarchy requests.
	//  *
	//  * @since 3.16.0
	//  */
	// callHierarchy?: CallHierarchyClientCapabilities;

	// /**
	//  * Capabilities specific to the various semantic token requests.
	//  *
	//  * @since 3.16.0
	//  */
	// semanticTokens?: SemanticTokensClientCapabilities;

	// /**
	//  * Capabilities specific to the `textDocument/moniker` request.
	//  *
	//  * @since 3.16.0
	//  */
	// moniker?: MonikerClientCapabilities;

	// /**
	//  * Capabilities specific to the various type hierarchy requests.
	//  *
	//  * @since 3.17.0
	//  */
	// typeHierarchy?: TypeHierarchyClientCapabilities;

	// /**
	//  * Capabilities specific to the `textDocument/inlineValue` request.
	//  *
	//  * @since 3.17.0
	//  */
	// inlineValue?: InlineValueClientCapabilities;

	// /**
	//  * Capabilities specific to the `textDocument/inlayHint` request.
	//  *
	//  * @since 3.17.0
	//  */
	// inlayHint?: InlayHintClientCapabilities;

	// /**
	//  * Capabilities specific to the diagnostic pull model.
	//  *
	//  * @since 3.17.0
	//  */
	// diagnostic?: DiagnosticClientCapabilities;


class ClientCapabilities
    // var workspace: None | WorkspaceCapabilities
    // var textDocument: None | TextDocumentClientCapabilities
    var experimental: LSPAny
	new ref create() =>
		experimental = false
