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

  fun handle_initialize(msg: RequestMessage val) =>
    if initialized then
      debug.print("Server already initialized")
      channel.send_message(ResponseMessage(msg.id, "", ResponseError(
        -32002,
        "Server already initialized"
      )))
    end
    channel.send_message(RequestMessage(12345, "window/showMessage", JsonObject(
            recover val
              Map[String, JsonType](2)
                .>update("type", I64(2))
                .>update("message", "Pony LS initializing...")
            end
          )))
    channel.send_message(ResponseMessage(msg.id, JsonObject(
      recover val
        Map[String, JsonType](2)
          .>update("capabilities", JsonObject(
            recover val
              Map[String, JsonType](2)
                .>update("hoverProvider", true)
                .>update("diagnosticProvider", JsonObject(
                  recover val
                    Map[String, JsonType](2)
                      .>update("interFileDependencies", true)
                      .>update("workspaceDiagnostics", false)
                  end
                ))
            end
          ))
          .>update("serverInfo", JsonObject(
            recover val
              Map[String, JsonType](2)
                .>update("name", "Pony LS")
                .>update("version", "0.0.1")
            end
          ))
      end
    )))
          