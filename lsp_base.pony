use "immutable-json"

type ReceivingMode is (ReceivingModeHeader | ReceivingModeContent)
primitive ReceivingModeHeader
primitive ReceivingModeContent


class Header
  var key: String
  var value: String
  new create(key': String, value': String) =>
    key = key'
    value = value'


class Message
  let id: (I64 | String)
  let method: String
  let params: (None | JsonObject)
  new val create(id': (I64 | String), method': String, params': (None | JsonObject)) =>
    id = id'
    method = method'
    params = params'
  fun string(): String => 
    let r = id.string() + " " + method
    match params
    | let p: JsonObject => r + "\n" + p.string()
    else
      r
    end


class BaseProtocol
  var line_buffer: String ref = String
  var content_buffer: String ref = String
  var headers: Array[Header] = Array[Header]
  var receiving_mode: ReceivingMode = ReceivingModeHeader
  var debug: Debugger

  new ref create(debug': Debugger) => 
    debug = debug'

  fun ref apply(data: String): (None | Message val) =>
    match receiving_mode
    | ReceivingModeHeader => receive_headers(data)
    | ReceivingModeContent => receive_content(data)
    end

  fun ref receive_headers(data: String): (None | Message val) =>
    line_buffer.append(data)
    if line_buffer.contains("\r\n") then
      let abuffer = line_buffer.split("\r\n")
      try
        let msg = abuffer.shift()?
        line_buffer = "\r\n".join((consume abuffer).values())
        if msg == "" then
          receiving_mode = ReceivingModeContent
          content_buffer = line_buffer = String
          receive_content("")
        else
          let hdata = msg.split(": ")
          try headers.push(Header(hdata(0)?, hdata(1)?)) end
        end
      end
    end

  fun ref receive_content(data: String): (None | Message val) =>
    content_buffer.append(data)
    parse_message()

  fun ref parse_message(): (None | Message val) =>
    let doc = JsonDoc
    let data = content_buffer.clone()
    try
      doc.parse(consume data)?
      let json: JsonObject  = doc.data as JsonObject
      var id: (String | I64) = ""
      match json.data("id")?
      | let id': String => id = id'
      | let id': I64 => id = id'
      end
      var method = json.data("method")? as String
      var params = json.data("params")? as JsonObject
      Message(id, method, params)
    end