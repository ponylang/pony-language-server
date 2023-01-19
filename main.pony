use "debug"

actor Main
  let _env: Env
  let lifecycle: LifecycleProtocol
  let language: LanguageProtocol
  let document: DocumentProtocol
  let channel: Stdio


  new create(env: Env) =>
    _env = env
    let channel_kind = try env.args(1)? else "stdio" end
    match channel_kind
    | "stdio" => 
      channel = Stdio(env, this)
      let compiler = PonyCompiler(env, channel)
      lifecycle = LifecycleProtocol(channel)
      document = DocumentProtocol(compiler, channel)
      language = LanguageProtocol(compiler, channel, document)
      Log(channel, "PonyLSP Server ready")
    else
      channel = Stdio(env, this)
      let compiler = PonyCompiler(env, channel)
      lifecycle = LifecycleProtocol(channel)
      document = DocumentProtocol(compiler, channel)
      language = LanguageProtocol(compiler, channel, document)
      Log(channel, "PonyLSP Server ready")
    end


  be handle_message(msg: Message val) =>
    match msg
    | let r: RequestMessage val => 
      Debug("\n\n<-\n" + r.json().string())
      match r.method
      | "initialize" => lifecycle.handle_initialize(r)
      | "initialized" => lifecycle.handle_initialized(r)
      | "textDocument/hover" => language.handle_hover(r)
      | "textDocument/didOpen" => document.handle_did_open(r)
      | "textDocument/didSave" => document.handle_did_save(r)
      else
        Log(channel, "Method not implemented: " + r.method)
      end
    | let r: ResponseMessage val => 
      Debug("\n\n<- (unhandled)\n" + r.json().string())
    end
    