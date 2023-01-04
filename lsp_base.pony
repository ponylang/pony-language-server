use "immutable-json"
use "collections"

type ReceivingMode is (ReceivingModeHeader | ReceivingModeContent)
primitive ReceivingModeHeader
primitive ReceivingModeContent


class Header
  var key: String
  var value: String
  new create(key': String, value': String) =>
    key = key'
    value = value'


interface Message
  fun json(): JsonObject


class RequestMessage
  let id: (I64 | String)
  let method: String
  let params: (None | JsonObject val)
  new val create(id': (I64 | String), method': String, params': (None | JsonObject val)) =>
    id = id'
    method = method'
    params = params'
  fun json(): JsonObject =>
    JsonObject(
      recover val
        Map[String, JsonType](3)
          .>update("id", id)
          .>update("method", method)
          .>update("params", params)
      end
    )


class ResponseMessage
  let id: (I64 | String | None)
  let result: (String | I64 | Bool | JsonObject)
  let response_error: (None | ResponseError val)
  new val create(id': (I64 | String), result': (String | I64 | Bool | JsonObject), response_error': (None | ResponseError val) = None) =>
    id = id'
    result = result'
    response_error = response_error'
  fun json(): JsonObject =>
    JsonObject(
      recover val
        let m = Map[String, JsonType](3)
          .>update("id", id)
        match result
        | let r: String val => m.update("result", r)
        | let r: I64 val => m.update("result", r)
        | let r: Bool val => m.update("result", r)
        | let r: JsonObject val => m.update("result", r)
        end
        match response_error
        | let r: ResponseError val => m.update("response_error", r.json())
        end
        m
      end
    )


class ResponseError
  let code: I64
  let message: String
  let data: (String | I64 | Bool | JsonArray | JsonObject | None)
  new val create(code': I64, message': String, data': (String | I64 | Bool | JsonArray | JsonObject | None) = None) =>
    code = code'
    message = message'
    data = data'
  fun json(): JsonObject =>
    JsonObject(
      recover val
        Map[String, JsonType](3)
          .>update("code", code)
          .>update("message", message)
          .>update("data", data)
      end
    )


class BaseProtocol
  var line_buffer: String ref = String
  var content_buffer: String ref = String
  var headers: Array[Header] = Array[Header]
  var receiving_mode: ReceivingMode = ReceivingModeHeader
  var debug: Debugger

  new ref create(debug': Debugger) => 
    debug = debug'

  fun ref apply(data: String): (None | RequestMessage val) =>
    match receiving_mode
    | ReceivingModeHeader => receive_headers(data)
    | ReceivingModeContent => receive_content(data)
    end

  fun ref receive_headers(data: String): (None | RequestMessage val) =>
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

  fun ref receive_content(data: String): (None | RequestMessage val) =>
    content_buffer.append(data)
    parse_message()

  fun ref parse_message(): (None | RequestMessage val) =>
    try
      let data = content_buffer.clone()
      let doc = JsonDoc
      doc.parse(consume data)?
      let json: JsonObject  = doc.data as JsonObject
      var id: (String | I64) = ""
      match json.data("id")?
      | let id': String => id = id'
      | let id': I64 => id = id'
      end
      var method = json.data("method")? as String
      var params = json.data("params")? as JsonObject
      let res = RequestMessage(id, method, params)
      line_buffer = String
      content_buffer = String
      headers = Array[Header]
      receiving_mode = ReceivingModeHeader
      res
    end

    fun ref compose_message(msg: Message val): String =>
      let content = msg.json().string()
      "Content-Length: " + content.size().string() + "\r\n"
      + "\r\n"
      + content