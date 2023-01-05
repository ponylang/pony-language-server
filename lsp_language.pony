use "immutable-json"
use "collections"

class LanguageProtocol
  var initialized: Bool = false
  var channel: Stdio
  var debug: Debugger

  new create(channel': Stdio, debug': Debugger) =>
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
    