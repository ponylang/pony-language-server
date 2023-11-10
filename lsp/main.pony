use "immutable-json"

actor Main
  let _env: Env
  let language: LanguageProtocol
  let document: DocumentProtocol
  let channel: Stdio
  let _router: WorkspaceRouter

  var _initialized: Bool = false


  new create(env: Env) =>
    _env = env
    _router = WorkspaceRouter.create()
    let channel_kind = try env.args(1)? else "stdio" end
    match channel_kind
    | "stdio" =>
      channel = Stdio(env, this)
      let compiler = PonyCompiler(env, channel)
      document = DocumentProtocol(compiler, channel)
      language = LanguageProtocol(compiler, channel, document)
      Log(channel, "PonyLSP Server ready")
    else
      env.err.print("Unsupported channel: " + channel_kind)
      env.exitcode(1)
    end

  fun tag _get_document_uri(
    params: (JsonObject | JsonArray), 
    query: String = "$.textDocument.uri"): String ? 
  =>
    JsonPath(query, params)?(0)? as String

  be handle_message(msg: Message val) =>
    match msg
    | let r: RequestMessage val if not this._initialized => 
      | "initialize" => this.handle_initialize(r)
      else
        Log(channel, "Expected initialize, got " + r.method)
      end
    | let r: RequestMessage val if this._initialized => 
      channel.debug("\n\n<-\n" + r.json().string())
      match r.method
      | "initialized" => handle_initialized(r)
      | "textDocument/hover" =>
        try
          let document_uri = _get_document_uri(r.params)?
          // TODO: exptract params into class according to spec
          (_router.find_workspace(document_uri) as WorkspaceManager).hover(document_uri, r)
        else
          // TODO: send error
          None
        end
      language.handle_hover(r)
      | "textDocument/definition" =>
        try
          let document_uri = _get_document_uri(r.params)?
          // TODO: exptract params into class according to spec
          (_router.find_workspace(document_uri) as WorkspaceManager).goto_definition(document_uri, r)
        else
          // TODO: send error
          None
        end
      | "textDocument/didOpen" =>
        try
          let document_uri = _get_document_uri(r.params)?
          // TODO: exptract params into class according to spec
          (_router.find_workspace(document_uri) as WorkspaceManager).did_open(document_uri, r)
        else
          // TODO: send error
          None
        end
      | "textDocument/didSave" =>
        try
          let document_uri = _get_document_uri(r.params)?
          // TODO: exptract params into class according to spec
          (_router.find_workspace(document_uri) as WorkspaceManager).did_save(document_uri, r)
        else
          // TODO: send error
          None
        end
      else
        Log(channel, "Method not implemented: " + r.method)
      end
    | let r: ResponseMessage val => 
      channel.debug("\n\n<- (unhandled)\n" + r.json().string())
    end

  be handle_initialize(msg: RequestMessage val) =>
    if this._initialized then
      channel.debug("Server already initialized")
      channel.send_message(ResponseMessage(msg.id, "", ResponseError(
        -32002,
        "Server already initialized"
      )))
    else

      let params = msg.params as JsonObject val
      // extract server_options from "initializationOptions"
      let server_options = 
        try
          ServerOptions.from_json(params.data("initializationOptions")? as JsonObject)
        end
      // extract workspace folders, rootUri, rootPath in that order:
      let found_workspaces = JsonPath("$['workspaceFolders', 'rootUri', 'rootPath']", params)?
      for workspace in found_workspaces.values() do
        match workspace
        | let workspace_str: String =>
            try
              let pony_workspace = WorkspaceScanner.scan(file_auth, workspace_str)?
              let mgr = WorkspaceManager.create(pony_workspace)
              this._router.add_workspace(pony_workspace.folder, mgr)?
            end
        | let workspace_arr: JsonArray =>
          for workspace_obj in workspace_arr.values() do
            let name = JsonPath("$.name")?(0)?
            let uri = JsonPath("$.uri")?(0)?
            try
              let pony_workspace = WorkspaceScanner.scan(file_auth, Uris.to_path(uri), name)?
              let mgr = WorkspaceManager.create(pony_workspace, this.channel)
              this._router.add_workspace(pony_workspace.folder, mgr)?
          end
        end
      end
      this._initialized = true
      channel.send_message(ResponseMessage(msg.id, JsonObject(
        recover val
          Map[String, JsonType](2)
            .>update("capabilities", JsonObject(
              recover val
                Map[String, JsonType](3)
                  .>update("positionEncoding", "utf-8")
                  // we can handle hover requests
                  .>update("hoverProvider", true)
                  // Full sync seems to be needed to receive textDocument/didSave
                  .>update("textDocumentSync", I64(2))
                  // we can handle goto definition requests
                  .>update("definitionProvider", true)
              end
            ))
            .>update("serverInfo", JsonObject(
              recover val
                Map[String, JsonType](2)
                  .>update("name", "Pony LS")
                  .>update("version", "0.2.0")
              end
            ))
        end
      )))
    end

  be handle_initialized(msg: RequestMessage val) =>
    None
