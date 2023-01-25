use "immutable-json"
use "collections"
use "files"
use "backpressure"
use "process"
use "debug"
use "pony-ast/ast"


actor LanguageProtocol
  var initialized: Bool = false
  let channel: Stdio
  let document: DocumentProtocol
  let compiler: PonyCompiler


  new create(compiler': PonyCompiler, channel': Stdio, document': DocumentProtocol) =>
    compiler = compiler'
    channel = channel'
    document = document'


  be handle_hover(msg: RequestMessage val) =>
    match msg.params
    | let p: JsonObject => 
      try
        let text_document = p.data("textDocument")? as JsonObject
        let uri = text_document.data("uri")? as String
        let position = p.data("position")? as JsonObject
        let line = position.data("line")? as I64
        let character = position.data("character")? as I64
        let filepath = uri.clone()
        filepath.replace("file://", "")
        let notifier = HoverNotifier(msg.id, compiler, channel, filepath.clone(), line.usize(), character.usize())
        Log(channel, "compiler.apply()")
        // TODO: whats happening here?
        compiler(consume filepath, notifier)
      else
        Log(channel, "ERROR retrieving textDocument uri: " + msg.json().string())
        channel.send_message(ResponseMessage(msg.id, None, ResponseError(-32700, "parse error")))
      end
    else
      channel.send_message(ResponseMessage(msg.id, None, ResponseError(-32700, "parse error")))
    end


actor HoverNotifier
  let id: (I64 val | String val | None val)
  let compiler: PonyCompiler
  let channel: Stdio
  let file: String
  let line: USize
  let column: USize

  new create(
      id': (I64 val | String val | None val),
      compiler': PonyCompiler, 
      channel': Stdio,
      file': String,
      line': USize,
      column': USize
    ) =>
    id = id'
    compiler = compiler'
    channel = channel'
    file = file'
    line = line'
    column = column'

  be done() =>
    Log(channel, "HoverNotifier done")
    compiler.get_type_at(file, line+1, column, this)

  be type_notified(t: (String | None)) => 
    match t
    | let s: String => 
      Log(channel, "type_notified " + s)
      channel.send_message(ResponseMessage(id, JsonObject(
        recover val
          Map[String, JsonType](1)
            .>update("contents", JsonObject(
              recover val
                Map[String, JsonType](2)
                  .>update("kind", "markdown")
                  .>update("value", s)
              end
            ))
        end
      )))
    | None => Log(channel, "type_notified is None")
    end

  be on_error(filepath': (String | None), line': USize, pos': USize, msg': String) => None