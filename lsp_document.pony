use "immutable-json"
use "collections"
use "files"
use "backpressure"
use "process"


interface DocumentNotifier
  be handle_document_source(doc: String)


actor DocumentProtocol
  var initialized: Bool = false
  let channel: Stdio
  let debug: Debugger
  let cache: Map[String, String] ref = Map[String, String]


  new create(channel': Stdio, debug': Debugger) =>
    channel = channel'
    debug = debug'


  be handle_did_open(msg: RequestMessage val) =>
    channel.send_message(ResponseMessage(msg.id, None))
    match msg.params
    | let p: JsonObject => 
      try
        let text_document = p.data("textDocument")? as JsonObject
        let uri = text_document.data("uri")? as String val
        let text = text_document.data("text")? as String val
        cache.insert(uri, text)
      else
        debug.print("ERROR retrieving textDocument uri: " + msg.json().string())
      end
    end


  be document_by_id(id: String, notifier: DocumentNotifier tag) =>
    notifier.handle_document_source(cache.get_or_else(id, ""))