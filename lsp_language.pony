use "immutable-json"
use "collections"
use "files"
use "backpressure"
use "process"

class LanguageProtocol
  var initialized: Bool = false
  let channel: Stdio
  let debug: Debugger
  let env: Env

  new create(env': Env, channel': Stdio, debug': Debugger) =>
    env = env'
    channel = channel'
    debug = debug'

  fun handle_hover(msg: RequestMessage val) =>
    channel.send_message(ResponseMessage(msg.id, JsonObject(
      recover val
        Map[String, JsonType](1)
          .>update("contents", JsonObject(
            recover val
              Map[String, JsonType](2)
                .>update("kind", "markdown")
                .>update("value", "
# Hover test from pony
                ")
            end
          ))
      end
    )))
    match msg.params
    | let p: JsonObject => 
      try
        let text_document = p.data("textDocument")? as JsonObject
        let uri = recover 
            let u = (text_document.data("uri")? as String).clone()
            u.replace("file://", "")
            let a = u.split_by("/")
            a.pop()?
            "/".join((consume a).values())
          end
        let client = HoverAST(channel, debug)
        let notifier: ProcessNotify iso = consume client
        let binpath = FilePath(FileAuth(env.root), "/Users/jairocaro-accinoviciana/.local/share/ponyup/bin/ponyc")
        let args: Array[String] val = recover val 
            let a = ["--astpackage"; "--pass=final"; "-V=0"]
            a.>push(consume uri)
          end
        let sp_auth = StartProcessAuth(env.root)
        let bp_auth = ApplyReleaseBackpressureAuth(env.root)
        let pm: ProcessMonitor = ProcessMonitor(sp_auth, bp_auth, consume notifier,
          binpath, args, [])
        pm.done_writing()
      else
        debug.print("ERROR retrieving textDocument uri: " + msg.json().string())
      end
    end
    

class HoverAST is ProcessNotify
  let debug: Debugger
  let channel: Stdio

  new iso create(channel': Stdio, debug': Debugger) =>
    channel = channel'
    debug = debug'

  fun ref stdout(process: ProcessMonitor ref, data: Array[U8] iso) =>
    let out = String.from_array(consume data)
    debug.write(out)

  fun ref stderr(process: ProcessMonitor ref, data: Array[U8] iso) =>
    let err = String.from_array(consume data)
    debug.write("PROC ERROR: " + err)

  fun ref failed(process: ProcessMonitor ref, err: ProcessError) =>
    debug.print("FAILED: " + err.string())

  fun ref dispose(process: ProcessMonitor ref, child_exit_status: ProcessExitStatus) =>
    match child_exit_status
    | let exited: Exited =>
      debug.print("Child exit code: " + exited.exit_code().string())
    | let signaled: Signaled =>
      debug.print("Child terminated by signal: " + signaled.signal().string())
    end