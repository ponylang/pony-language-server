actor Main
  let debug: Debugger
  let _env: Env
  let lifecycle: LifecycleProtocol
  let language: LanguageProtocol
  let document: DocumentProtocol


  new create(env: Env) =>
    _env = env
    debug = Debugger(env)
    let channel_kind = try env.args(1)? else "stdio" end
    debug.print("Initializing channel " + channel_kind)
    match channel_kind
    | "stdio" => 
      let channel = Stdio(env, this, debug)
      lifecycle = LifecycleProtocol(channel, debug)
      language = LanguageProtocol(channel, debug)
      document = DocumentProtocol(channel, debug)
    else
      debug.print("Channel not implemented: " + channel_kind)
      debug.print("Defaulting to stdio")
      let channel = Stdio(env, this, debug)
      lifecycle = LifecycleProtocol(channel, debug)
      language = LanguageProtocol(channel, debug)
      document = DocumentProtocol(channel, debug)
    end


  be handle_message(msg: RequestMessage val) =>
    match msg.method
    | "initialize" => lifecycle.handle_initialize(msg)
    | "initialized" => lifecycle.handle_initialized(msg)
    | "textDocument/hover" => language.handle_hover(msg)
    | "textDocument/didOpen" => document.handle_did_open(msg)
    else
      debug.print("Method not implemented: " + msg.method)
    end

  