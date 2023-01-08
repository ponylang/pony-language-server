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


  new create(channel': Stdio, debug': Debugger, document': DocumentProtocol) =>
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
        let handler = HandleHover(msg.id, uri, line, character, channel)
        document.document_by_id(uri, handler)
      else
        debug.print("ERROR retrieving textDocument uri: " + msg.json().string())
        channel.send_message(ResponseMessage(msg.id, None, ResponseError(-32700, "parse error")))
      end
    else
      channel.send_message(ResponseMessage(msg.id, None, ResponseError(-32700, "parse error")))
    end


actor HandleHover
  let id: (I64 | String | None)
  let uri: String
  let line: I64
  let character: I64
  let channel: Stdio

  new create(id': (I64 | String | None), uri': String, line': I64, character': I64, channel': Stdio) =>
    id = id'
    uri = uri'
    line = line'
    character = character'
    channel = channel'

  be handle_document_source(doc: Document val) =>
    channel.send_message(ResponseMessage(id, JsonObject(
      recover val
        Map[String, JsonType](1)
          .>update("contents", JsonObject(
            recover val
              Map[String, JsonType](2)
                .>update("kind", "markdown")
                .>update("value", "
## Hover test

Word detected:  "+doc.word_at_position(line, character)+"
                ")
            end
          ))
      end
    )))