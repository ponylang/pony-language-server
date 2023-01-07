use "immutable-json"
use "collections"
use "files"
use "backpressure"
use "process"


actor LanguageProtocol
  var initialized: Bool = false
  let channel: Stdio
  let debug: Debugger


  new create(channel': Stdio, debug': Debugger) =>
    channel = channel'
    debug = debug'


  be handle_hover(msg: RequestMessage val) =>
    channel.send_message(ResponseMessage(msg.id, JsonObject(
      recover val
        Map[String, JsonType](1)
          .>update("contents", JsonObject(
            recover val
              Map[String, JsonType](2)
                .>update("kind", "markdown")
                .>update("value", "
# Hover test from pony
                ")
            end
          ))
      end
    )))
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
      end
    end