use "immutable-json"
use "collections"
use "files"
use "backpressure"
use "process"

class DocumentProtocol
  var initialized: Bool = false
  let channel: Stdio
  let debug: Debugger
  let cache: Map[String, String] = Map[String, String]

  new create(channel': Stdio, debug': Debugger) =>
    channel = channel'
    debug = debug'

  fun handle_did_open(msg: RequestMessage val) =>
    channel.send_message(ResponseMessage(msg.id, None))
    match msg.params
    | let p: JsonObject => 
      try
        let text_document = p.data("textDocument")? as JsonObject
        let uri = text_document.data("uri")? as String
        let text = text_document.data("text")? as String
      else
        debug.print("ERROR retrieving textDocument uri: " + msg.json().string())
      end
    end
