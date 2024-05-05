use ".."
use "collections"
use "files"

use "ast"
use "immutable-json"

actor WorkspaceManager
  """
  Handling all operations on a workspace
  """
  let workspace: WorkspaceData
  let _channel: Channel
  let _compiler: PonyCompiler
  let _packages: Map[String, PackageState]

  var _current_request: (RequestMessage val | None) = None

  new create(
    workspace': WorkspaceData,
    channel': Channel,
    compiler': PonyCompiler)
  =>
    workspace = workspace'
    _channel = channel'
    _compiler = compiler'
    _packages = _packages.create()

  fun ref _ensure_package(package_path: FilePath): PackageState =>
    try
      this._packages(package_path.path)?
    else
      this._packages.insert(package_path.path, PackageState.create(package_path, this._channel))
    end

  fun _get_package(package_path: FilePath): (this->PackageState | None) =>
    try
      this._packages(package_path.path)?
    else
      None
    end

  fun ref _find_workspace_package(document_path: String): FilePath =>
    match this.workspace.find_package(document_path)
    | let pkg: FilePath => pkg
    | None => this.workspace.folder
    end

  be done_compiling(package: FilePath, result: (Program val | Array[Error val] val)) =>
    this._channel.log("done compiling " + package.path)
    let package_state = this._ensure_package(package)
    // notify client about errors if any
    match result
    | let program: Program val =>
      this._channel.log("Successfully compiled " + package.path)
      // clearing out all diagnostics for every open file
      package_state.update(program)
    | let errors: Array[Error val] val =>

      this._channel.log("Compilation failed with " + errors.size().string() + " errors")
      // group errors by file
      let errors_by_file = Map[String, Array[JsonType] iso].create(4)
      // pre-fill with opened files
      // if we have no errors for them, they will get their errors cleared
      for doc in package_state.documents.keys() do
        errors_by_file(doc) = []
      end
      for err in errors.values() do
        this._channel.log("ERROR: " + err.msg)
        let line = err.position.line()
        let column = err.position.column()
        let diagnostic =
          Obj("message", err.msg)(
            "range", Obj(
              "start", Obj("line", line.i64() - 1)("character", column.i64()))(
              "end", Obj("line", line.i64() - 1)("character", column.i64())
            )
          ).build()
        errors_by_file.upsert(
          try
            err.file as String
          else
            "no_file"
          end,
          recover iso
            [as JsonType: diagnostic]
          end,
          {(current: Array[JsonType] iso, provided: Array[JsonType] iso) =>
            current.append(consume provided)
            consume current
          }
        )
      end
      // create error diagnostics message for each file
      for file in errors_by_file.keys() do
        try
          let file_errors = recover val errors_by_file.remove(file)?._2 end
          let msg = Notification.create(
            "textDocument/publishDiagnostics",
            Obj("uri", Uris.from_path(file))("diagnostics", JsonArray(file_errors)).build()
          )
          this._channel.send(msg)
        end
      end
    end


  be did_open(document_uri: String, notification: Notification val) =>
    let document_path = Uris.to_path(document_uri)
    this._channel.log("handling did_open of " + document_path)
    let package: FilePath = this._find_workspace_package(document_path)
    this._channel.log("Found pony package @ " + package.path)
    let package_state = this._ensure_package(package)
    match package_state.get_document(document_path)
    | let doc_state: DocumentState => None // already there
    | None =>
      (let inserted_doc_state, let has_module) = package_state.insert_new(document_path)
      if not has_module then
        _channel.log("No module found for document " + document_path + ". Need to compile.")
        _compiler.compile(package, workspace.dependency_paths, this)
      end
    end

  be did_close(document_uri: String, notification: Notification val) =>
    let document_path = Uris.to_path(document_uri)
    this._channel.log("handling did_close of " + document_path)
    let package: FilePath = this._find_workspace_package(document_path)
    let package_state = this._ensure_package(package)
    try
      let document_state = package_state.documents.remove(document_path)?._2
      document_state.dispose()
    end

  be did_save(document_uri: String, notification: Notification val) =>
    let document_path = Uris.to_path(document_uri)
    this._channel.log("handling did_save of " + document_path)
    // TODO: don't compile multiple times for multiple documents being saved one
    // after the other
    let package: FilePath = this._find_workspace_package(document_path)
    let package_state = this._ensure_package(package)
    match package_state.get_document(document_path)
    | let doc_state: DocumentState =>
      // check for differences to decide if we need to compile
      let old_state_hash =
        match doc_state.module
        | let module: Module => module.hash()
        else
          0 // no module
        end
    | None =>
      // no document state found - wtf are we gonna do here?
      this._channel.log("No document state found for " + document_path + ". Dunno what to do!")
    end
    // re-compile changed program - continuing in `done_compiling`
    _compiler.compile(package, workspace.dependency_paths, this)

  be hover(document_uri: String, request: RequestMessage val) =>
    this._channel.log("handling hover")
    this._current_request = request
    _channel.send(ResponseMessage.create(request.id, None))

  be goto_definition(document_uri: String, request: RequestMessage val) =>
    this._channel.log("handling goto_definition")
    this._current_request = request
    // extract the source code position
    (let line, let column) =
      try
        let l = JsonPath("$.position.line", request.params)?(0)? as I64 // 0-based
        let c = JsonPath("$.position.character", request.params)?(0)? as I64 // 0-based
        (l, c)
      else
        _channel.send(
          ResponseMessage.create(
            request.id,
            None,
            ResponseError(ErrorCodes.invalid_params(), "Invalid position")
          )
        )
        return
      end
    let document_path = Uris.to_path(document_uri)
    let package: FilePath = this._find_workspace_package(document_path)

    match this._get_package(package)
    | let pkg_state: PackageState =>
        //this._channel.log(pkg_state.debug())
        match pkg_state.get_document(document_path)
        | let doc: DocumentState =>
          match doc.position_index
          | let index: PositionIndex =>
            match index.find_node_at(USize.from[I64](line + 1), USize.from[I64](column + 1)) // pony lines and characters are 1-based, lsp are 0-based
            | let ast: AST box =>
              //this._channel.log(ast.debug())
              var json_builder = Arr.create()
              // iterate through all found definitions
              for ast_definition in ast.definitions().values() do
                // get position of the found definition
                let start_pos: Position = ast_definition.position()
                let end_pos: Position =
                  match ast_definition.end_pos()
                  | let p: Position => p
                  | None => start_pos // *shrug*
                  end
                try
                  // append new location
                  json_builder = json_builder(
                    Obj("uri", Uris.from_path(ast_definition.source_file() as String val))(
                      "range", Obj(
                        "start", Obj("line", I64.from[USize](start_pos.line() - 1))("character", I64.from[USize](start_pos.column() - 1)))(
                        "end",   Obj("line", I64.from[USize](end_pos.line()   - 1))("character", I64.from[USize](end_pos.column()   - 1))
                      )
                    )
                  )
                else
                  this._channel.log("No source file found for definition: " + ast_definition.debug())
                end
              end
              this._channel.send(ResponseMessage(request.id, json_builder.build()))
              return // exit, otherwise we send a null resul
            | None =>
              this._channel.log("No AST node found @ " + line.string() + ":" + column.string())
            end
          else
            this._channel.log("No position index available for " + document_path)
          end
        else
          this._channel.log("No document state available for " + document_path)
        end
    | None =>
      this._channel.log("No package state available for package: " + package.path)
    end
    // send a null-response in every failure case
    this._channel.send(ResponseMessage.create(request.id, None))


  be dispose() =>
    for package_state in this._packages.values() do
      package_state.dispose()
    end


