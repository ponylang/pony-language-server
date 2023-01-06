use "immutable-json"
use "collections"
use "files"
use "backpressure"
use "process"

class LanguageProtocol
  var initialized: Bool = false
  let channel: Stdio
  let debug: Debugger
  let env: Env

  new create(env': Env, channel': Stdio, debug': Debugger) =>
    env = env'
    channel = channel'
    debug = debug'

  fun handle_hover(msg: RequestMessage val) =>
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
      else
        debug.print("ERROR retrieving textDocument uri: " + msg.json().string())
      end
    end