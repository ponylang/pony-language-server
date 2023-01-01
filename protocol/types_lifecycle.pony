// class ClientInfo
//     var name: String
//     var version: (None | String)


// class WorkspaceFolder
//     var uri: DocumentURI
//     var name: String


// class ServerInfo
//     var name: String
//     var version: (None | String)


// // method: ‘initialize’
// class InitializeParams
//     /**
// 	 * The process Id of the parent process that started the server. Is null if
// 	 * the process has not been started by another process. If the parent
// 	 * process is not alive then the server should exit (see exit notification)
// 	 * its process.
// 	 */
//     var processId: (None | Integer)
//     var clientInfo: ClientInfo
//     /**
// 	 * The locale the client is currently showing the user interface
// 	 * in. This must not necessarily be the locale of the operating
// 	 * system.
// 	 *
// 	 * Uses IETF language tags as the value's syntax
// 	 * (See https://en.wikipedia.org/wiki/IETF_language_tag)
// 	 *
// 	 * @since 3.16.0
// 	 */
//     var locale: (None | String)
//     /**
// 	 * The rootPath of the workspace. Is null
// 	 * if no folder is open.
// 	 *
// 	 * @deprecated in favour of `rootUri`.
// 	 */
// 	var rootPath: (None | String)
//     /**
// 	 * The rootUri of the workspace. Is null if no
// 	 * folder is open. If both `rootPath` and `rootUri` are set
// 	 * `rootUri` wins.
// 	 *
// 	 * @deprecated in favour of `workspaceFolders`
// 	 */
// 	var rootUri: (None | DocumentUri)
//     /**
// 	 * User provided initialization options.
// 	 */
// 	var initializationOptions: (None | LSPAny)
//     /**
// 	 * The capabilities provided by the client (editor or tool)
// 	 */
// 	var capabilities: ClientCapabilities
//     /**
// 	 * The initial trace setting. If omitted trace is disabled ('off').
// 	 */
// 	var trace: (None | TraceValue)
//     /**
// 	 * The workspace folders configured in the client when the server starts.
// 	 * This property is only available if the client supports workspace folders.
// 	 * It can be `null` if the client supports workspace folders but none are
// 	 * configured.
// 	 *
// 	 * @since 3.6.0
// 	 */
// 	var workspaceFolders: (None | List[WorkspaceFolder])



