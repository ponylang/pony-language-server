use "immutable-json"
use "collections"
use "files"
use "backpressure"
use "process"


actor LanguageProtocol
  var initialized: Bool = false
  let channel: Stdio
  let debug: Debugger
  let document: DocumentProtocol
  let compiler: PonyCompiler


  new create(compiler': PonyCompiler, channel': Stdio, debug': Debugger, document': DocumentProtocol) =>
    compiler = compiler'
    channel = channel'
    debug = debug'
    document = document'


  be handle_hover(msg: RequestMessage val) =>
    match msg.params
    | let p: JsonObject => 
      try
        let text_document = p.data("textDocument")? as JsonObject
        let uri = text_document.data("uri")? as String
        let position = p.data("position")? as JsonObject
        let line = position.data("line")? as I64
        let character = position.data("character")? as I64
      else
        debug.print("ERROR retrieving textDocument uri: " + msg.json().string())
        channel.send_message(ResponseMessage(msg.id, None, ResponseError(-32700, "parse error")))
      end
    else
      channel.send_message(ResponseMessage(msg.id, None, ResponseError(-32700, "parse error")))
    end

