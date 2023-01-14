use "immutable-json"
use "collections"
use "files"
use "backpressure"
use "process"
use "random"


interface DocumentNotifier
  be handle_document_source(doc: Document val)


actor DocumentProtocol
  var initialized: Bool = false
  let channel: Stdio
  let debug: Debugger
  let cache: Map[String, String] ref = Map[String, String]
  let compiler: PonyCompiler
  let errors_notifier: ErrorsNotifier


  new create(compiler': PonyCompiler, channel': Stdio, debug': Debugger) =>
    channel = channel'
    debug = debug'
    compiler = compiler'
    errors_notifier = ErrorsNotifier(channel, debug)


  be handle_did_open(msg: RequestMessage val) =>
    // channel.send_message(ResponseMessage(msg.id, None))
    match msg.params
    | let p: JsonObject => 
      try
        let text_document = p.data("textDocument")? as JsonObject
        let uri = text_document.data("uri")? as String val
        let text = text_document.data("text")? as String val
        cache.insert(uri, text)
        let filepath = uri.clone()
        filepath.replace("file://", "")
        debug.print("DocumentProtocol calling compiler to check " + filepath.clone())
        compiler(consume filepath, errors_notifier)
      else
        debug.print("ERROR retrieving textDocument uri: " + msg.json().string())
      end
    end


  be document_by_id(id: String, notifier: DocumentNotifier tag) =>
    notifier.handle_document_source(Document(cache.get_or_else(id, "")))


class Document
  let text: String

  new val create(text': String) =>
    text = text'

  fun word_at_position(line_number: I64, character: I64): String =>
    let lines = text.split_by("\n")
    let line = try lines(line_number.usize())? else
      return ""
    end
    let characters = line.runes()
    var word = ""
    var index: I64 = 0
    var target = false
    var exit = false
    for c in characters do
      if character == index then
        target = true
      end
      match c
      | ' ' => if target then return try word.clone().>shift()? else "" end end; word = ""
      | '(' => if target then return try word.clone().>shift()? else "" end end; word = ""
      | ')' => if target then return try word.clone().>shift()? else "" end end; word = ""
      | '{' => if target then return try word.clone().>shift()? else "" end end; word = ""
      | '}' => if target then return try word.clone().>shift()? else "" end end; word = ""
      | '[' => if target then return try word.clone().>shift()? else "" end end; word = ""
      | ']' => if target then return try word.clone().>shift()? else "" end end; word = ""
      | '.' => if target then return try word.clone().>shift()? else "" end end; word = ""
      | ',' => if target then return try word.clone().>shift()? else "" end end; word = ""
      | ';' => if target then return try word.clone().>shift()? else "" end end; word = ""
      | '"' => if target then return try word.clone().>shift()? else "" end end; word = ""
      | ':' => if target then return try word.clone().>shift()? else "" end end; word = ""
      end
      word = word + String.from_utf32(c)
      index = index + 1
    end
    word


actor ErrorsNotifier
  let channel: Stdio
  let debug: Debugger
  let errors: Map[String, Array[JsonObject val]] = Map[String, Array[JsonObject val]]

  new create(channel': Stdio, debug': Debugger) =>
    channel = channel'
    debug = debug'

  be on_error(filepath: String, line: USize, pos: USize, msg: String) =>
    let uri: String val = "file://" + filepath
    var errorlist = try errors(uri)? else Array[JsonObject val] end
    errorlist.push(JsonObject(
      recover val
        Map[String, JsonType](2)
          .>update("range", uri)
          .>update("severity", I64(1)) // 1 = error
          .>update("range", msg)
          .>update("range", JsonObject(
              recover val
                Map[String, JsonType](2)
                  .>update("start", JsonObject(
                      recover val
                        Map[String, JsonType](2)
                          .>update("line", line.i64())
                          .>update("character", pos.i64())
                      end
                    ))
                  .>update("end", JsonObject(
                      recover val
                        Map[String, JsonType](2)
                          .>update("line", line.i64())
                          .>update("character", pos.i64())
                      end
                    ))
              end
            ))
      end
    ))
    errors(uri) = errorlist

  be done() =>
    for i in errors.keys() do
      let rand = Rand
      let n = rand.i64()
      let errorlist: Array[(F64 val | I64 val | Bool val | None val | String val | JsonArray val | JsonObject val)] iso = []
      try
        for e in errors(i)?.values() do
          errorlist.push(e)
        end
      else
        debug.print("error getting errorlist of " + i)
        continue
      end
      channel.send_message(RequestMessage(n, "textDocument/publishDiagnostics", JsonObject(
        recover val
          Map[String, JsonType](2)
            .>update("uri", i)
            .>update("diagnostics", JsonArray(recover val consume errorlist end))
        end
      )))
    end