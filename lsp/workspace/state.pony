use "collections"
use "files"
use "ast"
use "itertools"

use ".."

class PackageState
  let path: FilePath
  let documents: Map[String, DocumentState]
  let _channel: Channel

  var program: (Program | None)

  new create(path': FilePath, channel: Channel) =>
    path = path'
    _channel = channel
    documents = documents.create()
    program = None

  fun debug(): String val =>
    "Package " + this.path.path + " (" + (
      try
        ((this.program as Program).package() as Package).qualified_name
      else
        ""
      end
    ) + "):\n\t" + "\n\t".join(
      Iter[(String box, DocumentState box)](documents.pairs())
        .map[String]({(kv) => 
          kv._1 + " (" + 
            match kv._2.module
            | let m: Module => "M"
            else
              "_"
            end + ")"
        })
    )

  fun get_document(document_path: String): (this->DocumentState | None) =>
    try
      this.documents(document_path)?
    end

  fun ref insert_new(document_path: String): (DocumentState, Bool) =>
    var has_module = false
    let doc_state = DocumentState.create(document_path)

    // TODO: maybe look through all packages
    try
      let package = (this.program as Program).package() as Package
      let module = package.find_module(document_path) as Module
      doc_state.update(module)
      has_module = true
    end
    (
      this.documents.insert(
        document_path,
        doc_state
      ),
      has_module
    )

  // TODO: should we also update the package state with errors?
  fun ref update(result: Program val) =>
    this.program = result
    match result.package()
    | let package: Package =>
      this._channel.log("Updating package " + package.path)
      this._channel.log(this.debug())
      // TODO: also support doc_states for other packages (like builtin etc.)
      for (doc_path, doc_state) in this.documents.pairs() do
        // TODO: ensure both module and package-state paths are normalized
        match package.find_module(doc_path)
        | let m: Module val =>
          // update each document state
          doc_state.update(m)
        | None =>
          this._channel.log("No module found for " + doc_path)
        end
      end
    else
      this._channel.log("No package in program :(")
    end

  fun dispose() =>
    for doc_state in this.documents.values() do
      doc_state.dispose()
    end

class DocumentState
  let path: String

  var module: (Module val | None)
  var position_index: (PositionIndex val | None)
  var hash: USize

  new create(path': String) =>
    path = path'
    module = None
    position_index = None
    hash = 0

  fun ref update(module': Module val) =>
    this.module = module'
    this.position_index = module'.create_position_index()
    this.hash = module'.hash()

  fun dispose() =>
    None
