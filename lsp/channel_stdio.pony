use "debug"


class InputNotifier is InputNotify
  let parent: Stdio

  new iso create(parent': Stdio) =>
    parent = parent'

  fun ref apply(data': Array[U8 val] iso): None val =>
    var data = String.from_array(consume data')
    parent.handle_data(data)

  fun ref dispose(): None val =>
    None


actor Stdio
  var out: OutStream
  var err: OutStream
  var handler: MessageHandler

  new create(out': OutStream, err': OutStream, input: InputStream, handler': MessageHandler) =>
    out = out'
    err: err'
    handler = handler'
    let notifier = InputNotifier(BaseProtocol(this))
    input(consume notifier)

  be handle_data(data: String) =>
    protocol_base(data)

  be handle_message(msg: Message val) =>
    handler.handle_message(msg)

  be send_message(msg: Message val) =>
    let output: String val = msg.string()
    out.write(output)
    out.flush()
    _debug("\n\n->\n" + output)

  be debug(data: String val) =>
    """
    Log data to STDERR
    """
    _log(data)

  fun _debug(data: String val) =>
    err.write(data)
    err.flush()
