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
  var env: Env
  var out: OutStream
  var protocol_base: BaseProtocol
  var manager: Main

  new create(env': Env, manager': Main) =>
    env = env'
    out = env.out
    protocol_base = BaseProtocol(this)
    manager = manager'
    let notifier = InputNotifier(this)
    env.input(consume notifier)

  be handle_data(data: String) =>
    protocol_base(data)

  be handle_message(msg: Message val) =>
    manager.handle_message(msg)

  be send_message(msg: Message val) =>
    let output = protocol_base.compose_message(msg)
    out.write(output)
    out.flush()
    Debug("\n\n->\n" + output)