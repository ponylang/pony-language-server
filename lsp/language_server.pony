use "collections"
use "files"
use "immutable-json"
use "workspace"

primitive _Uninitialized is Equatable[_LspState]
  fun string(): String val =>
    "uninitialized"
  fun eq(that: box->_LspState): Bool =>
    that is _Uninitialized

primitive _Initialized is Equatable[_LspState]
  fun string(): String val =>
    "initialized"
  fun eq(that: box->_LspState): Bool =>
    that is _Initialized

primitive _ShuttingDown is Equatable[_LspState]
  fun string(): String val =>
    "shutting down"
  fun eq(that: box->_LspState): Bool =>
    that is _ShuttingDown

type _LspState is (_Uninitialized | _Initialized | _ShuttingDown)

actor LanguageServer is Notifier
  let _channel: Channel
  let _compiler: PonyCompiler
  let _router: WorkspaceRouter
  let _env: Env
  let _file_auth: FileAuth

  // current LSP state
  var _state: _LspState = _Uninitialized

  new create(channel': Channel, env': Env, pony_path: String = "") =>
    channel'.set_notifier(this)
    _channel = channel'
    _channel.log("initial PONYPATH: " + pony_path)
    _compiler = PonyCompiler(pony_path)
    _router = WorkspaceRouter.create()
    _env = env'
    _file_auth = FileAuth(env'.root)
    _channel.log("PonyLSP Server ready")

  fun tag _get_document_uri(
    params: (JsonObject | JsonArray | None),
    query: String = "$.textDocument.uri"): String ?
  =>
    JsonPath(query, params)?(0)? as String

  be handle_parse_error(err: ParseError val) =>
    this._channel.log("Parse Error: " + err.string(), Warning)

  fun ref handle_request(r: RequestMessage val) =>
    match this._state
    | _Uninitialized =>
      match r.method
      | "initialize" => this.handle_initialize(r)
      else
        this._channel.send(
          ResponseMessage.create(
            r.id,
            None,
            ResponseError(ErrorCodes.server_not_initialized(), "Expected initialize, got " + r.method)
          )
        )
      end
    | _Initialized =>
      this._channel.log("\n\n<-\n" + r.json().string())
      match r.method
      | "textDocument/definition" =>
        try
          let document_uri = _get_document_uri(r.params)?
          // TODO: exptract params into class according to spec
          (_router.find_workspace(document_uri) as WorkspaceManager).goto_definition(document_uri, r)
        else
          this._channel.send(
            ResponseMessage.create(
              r.id,
              None,
              ResponseError(ErrorCodes.internal_error(), "[" + r.method + "] No workspace found for '" + r.json().string() + "'")
            )
          )
        end
      | "textDocument/hover" =>
        try
          let document_uri = _get_document_uri(r.params)?
          // TODO: exptract params into class according to spec
          (_router.find_workspace(document_uri) as WorkspaceManager).hover(document_uri, r)
        else
          this._channel.send(
            ResponseMessage.create(
              r.id,
              None,
              ResponseError(ErrorCodes.internal_error(), "[" + r.method + "] No workspace found for request '" + r.json().string() + "'")
            )
          )
        end
      | "textDocument/documentSymbol" =>
        let document_uri = 
          try
            _get_document_uri(r.params)?
          else
            this._channel.send(
              ResponseMessage.create(
                r.id,
                None,
                ResponseError(ErrorCodes.internal_error(), "[" + r.method + "] No workspace found for request '" + r.json().string() + "'")
              )
            )
            return
          end
        try
          (_router.find_workspace(document_uri) as WorkspaceManager).document_symbols(document_uri, r)
        else
          this._channel.send(
            ResponseMessage.create(
              r.id,
              None,
              ResponseError(ErrorCodes.internal_error(), "[" + r.method + "] No workspace found for request '" + r.json().string() + "'")
            )
          )
        end
      | "shutdown" =>
        this._state = _ShuttingDown
        this._channel.send(ResponseMessage.create(r.id, None))
      else
        this._channel.send(
          ResponseMessage.create(
            r.id,
            None,
            ResponseError(ErrorCodes.method_not_found(), "Method not implemented: " + r.method)
          )
        )
      end
    | _ShuttingDown =>
      // we don't handle no requests no more
      this._channel.send(
        ResponseMessage.create(
          r.id,
          None,
          ResponseError(ErrorCodes.invalid_request(), "shutting down")
        )
      )
    end

  fun ref handle_notification(n: Notification val) =>
    match n.method
    | "initialized" => handle_initialized(n)
    | "exit" =>
      this._channel.log("Exiting.")
      this._channel.dispose() // lets hope this unregisters us as dirty
      this._env.exitcode(if this._state is _ShuttingDown then 0 else 1 end)
      return
    | "textDocument/didOpen" =>
        try
          let document_uri = _get_document_uri(n.params)?
          // TODO: extract params into class according to spec
          (_router.find_workspace(document_uri) as WorkspaceManager).did_open(document_uri, n)
        else
          this._channel.log("[" + n.method + "] No workspace found for '" + n.json().string() + "'")
        end
    | "textDocument/didSave" =>
      try
        let document_uri = _get_document_uri(n.params)?
        // TODO: extract params into class according to spec
        (_router.find_workspace(document_uri) as WorkspaceManager).did_save(document_uri, n)
      else
        this._channel.log("[" + n.method + "] No workspace found for '" + n.json().string() + "'")
      end
    | "textDocument/didClose" =>
      try
        let document_uri = _get_document_uri(n.params)?
        // TODO: extract params into class according to spec
        (_router.find_workspace(document_uri) as WorkspaceManager).did_close(document_uri, n)
      else
        this._channel.log("[" + n.method + "] No workspace found for '" + n.json().string() + "'")
      end
    else
      this._channel.log("Method not implemented: " + n.method)
    end

  be handle_message(msg: Message val) =>
    match msg
    | let r: RequestMessage val =>
      handle_request(r)
    | let n: Notification val =>
      handle_notification(n)
    | let r: ResponseMessage val =>
      this._channel.log("\n\n<- (unhandled)\n" + r.json().string())
    end

  fun ref handle_initialize(msg: RequestMessage val) =>
    match msg.params
    | let params: JsonObject val =>
      // extract server_options from "initializationOptions"
      let server_options =
        try
          ServerOptions.from_json(params.data("initializationOptions")? as JsonObject)
        end
      // extract workspace folders, rootUri, rootPath in that order:
      let found_workspace: JsonType =
        try
          JsonPath("$['workspaceFolders', 'rootUri', 'rootPath']", params)?(0)?
        else
          None
        end
      let scanner = WorkspaceScanner.create(this._channel)
      match found_workspace
      | let workspace_str: String =>
          try
            this._channel.log("Scanning workspace " + workspace_str)
            let pony_workspaces = scanner.scan(this._file_auth, workspace_str)
            for pony_workspace in pony_workspaces.values() do
              let mgr = WorkspaceManager.create(pony_workspace, this._file_auth, this._channel, this._compiler)
              this._channel.log("Adding workspace " + pony_workspace.debug())
              this._router.add_workspace(pony_workspace.folder, mgr)?
            end
          end
      | let workspace_arr: JsonArray =>
        for workspace_obj in workspace_arr.data.values() do
          try
            let name = JsonPath("$.name", workspace_obj)?(0)? as String
            let uri = JsonPath("$.uri", workspace_obj)?(0)? as String
            this._channel.log("Scanning workspace " + uri)
            for pony_workspace in scanner.scan(this._file_auth, Uris.to_path(uri), name).values() do
              let mgr = WorkspaceManager.create(pony_workspace, this._file_auth, this._channel, this._compiler)
              this._channel.log("Adding workspace " + pony_workspace.debug())
              this._router.add_workspace(pony_workspace.folder, mgr)?
            end
          end
        end
      end
      this._state = _Initialized
      this._channel.send(
        ResponseMessage.create(
          msg.id,
          Obj(
            "capabilities", Obj(
              // vscode only supports UTF-16, but pony positions are only counting bytes
              // "positionEncoding", "utf-8")(
              // we can handle hover requests
              "hoverProvider", true)(
              "textDocumentSync", Obj(
                "change", I64(0))(
                "openClose", true)(
                "save", Obj("includeText", false))
              )(
              "definitionProvider", true)(
              "documentSymbolProvider", true
              ).build()
          )(
            "serverInfo", Obj(
              "name", "Pony Language Server")(
              "version", "0.2.1"
            ).build()
          ).build()
        )
      )
    end

  fun ref handle_initialized(notification: Notification val) =>
    None

  be dispose() =>
    this._router.dispose()
    this._channel.dispose()
