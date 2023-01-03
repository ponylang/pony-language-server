use "protocol"

actor Main
  let debug: Debugger
  let _env: Env

  new create(env: Env) =>
    _env = env
    debug = Debugger(env)
    let channel = try env.args(1)? else "stdio" end
    debug.print("Initializing channel " + channel)
    match channel
    | "stdio" => Stdio(env, this, debug)
    else
      debug.print("Channel not implemented: " + channel)
    end

  be handle_message(msg: Message val) =>
    debug.print("handle_message: " + msg.string())