use "immutable-json"
use "collections"
use "debug"


actor LifecycleProtocol
  var initialized: Bool = false
  var channel: Stdio

  new create(channel': Stdio) =>
    channel = channel'

  be handle_initialize(msg: RequestMessage val) =>
    if initialized then
      Debug("Server already initialized")
      channel.send_message(ResponseMessage(msg.id, "", ResponseError(
        -32002,
        "Server already initialized"
      )))
    end
    channel.send_message(ResponseMessage(msg.id, JsonObject(
      recover val
        Map[String, JsonType](2)
          .>update("capabilities", JsonObject(
            recover val
              Map[String, JsonType](2)
                .>update("hoverProvider", true)
                // Full sync seems to be needed to receive textDocument/didSave
                .>update("textDocumentSync", I64(2))
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
    

  be handle_initialized(msg: RequestMessage val) =>
    None