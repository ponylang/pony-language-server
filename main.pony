
actor Main
  let debug: Debugger
  let _env: Env
  let lifecycle: LifecycleProtocol

  new create(env: Env) =>
    _env = env
    debug = Debugger(env)
    let channel_kind = try env.args(1)? else "stdio" end
    debug.print("Initializing channel " + channel_kind)
    match channel_kind
    | "stdio" => 
      let channel = Stdio(env, this, debug)
      lifecycle = LifecycleProtocol(channel, debug)
    else
      debug.print("Channel not implemented: " + channel_kind)
      debug.print("Defaulting to stdio")
      let channel = Stdio(env, this, debug)
      lifecycle = LifecycleProtocol(channel, debug)
    end

  be handle_message(msg: Message val) =>
    debug.print("handle_message: " + msg.json().string())
    match msg.method
    | "initialize" => lifecycle.handle_initialize(msg)
    else
      debug.print("Method not implemented: " + msg.method)
    end

  