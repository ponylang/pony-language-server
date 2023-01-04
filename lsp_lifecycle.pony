// Handle initialization
// https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#initialize
// https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#initialized

// Handle capabilities
// https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#client_registerCapability
// https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#client_unregisterCapability

// Handle trace
// https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#setTrace
// https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#logTrace

// Handle shutdown
// https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#shutdown
// https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#exit
use "immutable-json"
use "collections"

class LifecycleProtocol
  var initialized: Bool = false
  var channel: Stdio
  var debug: Debugger

  new create(channel': Stdio, debug': Debugger) =>
    channel = channel'
    debug = debug'

  fun handle_initialize(msg: Message val) =>
    debug.print("handle initialize message " + msg.json().string())
    if initialized then
      channel.send_message(ResponseMessage(msg.id, "", ResponseError(
        -32002,
        "Server already initialized"
      )))
    end
    channel.send_message(ResponseMessage(msg.id, JsonObject(
      recover val
        Map[String, JsonType](2)
          .>update("capabilities", JsonArray.empty())
          .>update("serverInfo", JsonObject(
              recover val
                Map[String, JsonType](2)
                  .>update("name", "Pony LS")
                  .>update("version", "0.0.1")
              end
            ))
      end
    )))
          