use "lib:z"
use "lib:c++"

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
    for va in env.vars.values() do
      debug.print("ENV " + va)
    end
    let compiler = PonyCompiler(env, debug)
    match channel_kind
    | "stdio" => 
      let channel = Stdio(env, this, debug)
      lifecycle = LifecycleProtocol(channel, debug)
      document = DocumentProtocol(compiler, channel, debug)
      language = LanguageProtocol(compiler, channel, debug, document)
    else
      debug.print("Channel not implemented: " + channel_kind)
      debug.print("Defaulting to stdio")
      let channel = Stdio(env, this, debug)
      lifecycle = LifecycleProtocol(channel, debug)
      document = DocumentProtocol(compiler, channel, debug)
      language = LanguageProtocol(compiler, channel, debug, document)
    end


  be handle_message(msg: Message val) =>
    match msg
    | let r: RequestMessage val => 
      debug.print("\n\n<-\n" + r.json().string())
      match r.method
      | "initialize" => lifecycle.handle_initialize(r)
      | "initialized" => lifecycle.handle_initialized(r)
      | "textDocument/hover" => language.handle_hover(r)
      | "textDocument/didOpen" => document.handle_did_open(r)
      else
        debug.print("Method not implemented: " + r.method)
      end
    | let r: ResponseError val => 
      debug.print("\n\n<-Err (unhandled)\n" + r.json().string())
    | let r: ResponseMessage val => 
      debug.print("\n\n<- (unhandled)\n" + r.json().string())
    end
    