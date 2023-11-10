use "files"
use "immutable-json"
use "collections"

primitive Log
  fun apply(c: Stdio, msg: String) =>
    """Send a logMessage to the client"""
    c.send_message(RequestMessage(None, "window/logMessage", JsonObject(
      recover val
        Map[String, JsonType](1)
          .>update("message", msg)
      end
    )))
