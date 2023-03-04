// TODO: self shutdown when editor crashes
// To support the case that the editor starting a server crashes an editor should also pass 
// its process id to the server. This allows the server to monitor the editor process and to 
// shutdown itself if the editor process dies. The process id pass on the command line should 
// be the same as the one passed in the initialize parameters. The command line argument to use 
// is --clientProcessId.

use "immutable-json"
use "collections"
use "debug"


type ReceivingMode is (ReceivingModeHeader | ReceivingModeContent)
primitive ReceivingModeHeader
primitive ReceivingModeContent


class Header
  var key: String
  var value: String
  new create(key': String, value': String) =>
    key = key'
    value = value'


trait Message
  fun json(): JsonObject


interface Notifier
  be handle_message(msg: Message val)


class RequestMessage is Message
  let id: (I64 | String | None)
  let method: String
  let params: (None | JsonObject val)
  new val create(id': (I64 | String | None), method': String, params': (None | JsonObject val)) =>
    id = id'
    method = method'
    params = params'
  fun json(): JsonObject =>
    JsonObject(
      recover val
        let m = Map[String, JsonType](3)
          .>update("jsonrpc", "2.0")
        match id
        | let i: I64 => m.update("id", id)
        | let i: String => m.update("id", id)
        end
        m.>update("method", method)
        .>update("params", params)
      end
    )


class ResponseMessage is Message
  let id: (I64 | String | None)
  let result: (String | I64 | Bool | JsonObject | None)
  let response_error: (None | ResponseError val)
  new val create(id': (I64 | String | None), result': (String | I64 | Bool | JsonObject | None), response_error': (None | ResponseError val) = None) =>
    id = id'
    result = result'
    response_error = response_error'
  fun json(): JsonObject =>
    JsonObject(
      recover val
        let m = Map[String, JsonType](2)
          .>update("jsonrpc", "2.0")
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


actor BaseProtocol
  var line_buffer: String ref = String
  var content_buffer: String ref = String
  var headers: Map[String, String] = Map[String, String]
  var receiving_mode: ReceivingMode = ReceivingModeHeader
  var notifier: Notifier tag


  new create(notifier': Notifier tag) => 
    notifier = notifier'


  be apply(data: String) =>
    let res = 
      match receiving_mode
      | ReceivingModeHeader => receive_headers(data)
      | ReceivingModeContent => receive_content(data)
      end
    match res
    | let m: Message val => notifier.handle_message(m)
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
          let hdata = msg.split_by(": ")
          headers.insert(hdata(0)?, hdata(1)?)
          receive_headers("")
        end
      else
        Debug("ERROR abuffer.shift()")
      end
    end


  fun ref receive_content(data: String): (None | Message val) =>
    content_buffer.append(data)
    parse_message()


  fun ref parse_message(): (None | Message val) =>
    content_buffer.remove("\r\n")
    try
      let content_length: I64 val = (headers("Content-Length")?).i64()?
      if content_length > content_buffer.codepoints().i64() then 
        return None
      end
      (let data, let rest) = content_buffer.clone().chop(content_length.usize())
      let datalog: String val = data.clone()
      try
        let doc = JsonDoc
        doc.parse(consume data)?
        let json: JsonObject  = doc.data as JsonObject
        var id: (String | I64 | None) = None
        try id = json.data("id")? as String end
        try id = json.data("id")? as I64 end
        var res: Message val
        try 
          var method = json.data("method")? as String
          var params = json.data("params")? as JsonObject
          res = RequestMessage(id, method, params)
        else
          try 
            let result = json.data("result")? as (String | I64 | Bool | JsonObject | None)
            var response_error = json.data("error")? as (None | JsonObject val)
            var resp_err: (None | ResponseError val) = None
            match response_error
            | let err: JsonObject val => 
              try
                var code = err.data("code")? as I64
                var message = err.data("message")? as String
                var errdata = try err.data("data")? as JsonObject else None end
                resp_err = ResponseError(code, message, errdata)
              end
            end
            res = ResponseMessage(id, result, resp_err)
          else
            Debug("\n<- Error request parsing message")
            Debug(datalog.clone())
            line_buffer = rest.clone()
            content_buffer = String
            headers = Map[String, String]
            receiving_mode = ReceivingModeHeader
            return
          end
        end
        line_buffer = consume rest
        content_buffer = String
        headers = Map[String, String]
        receiving_mode = ReceivingModeHeader
        res
      else
        Debug("\n\n-----------")
        Debug("Error initial parsing message")
        Debug(content_buffer.codepoints().string() + "/" + content_length.string())
        Debug(datalog)
      end
    end


    fun tag compose_message(msg: Message val): String =>
      let content = msg.json().string()
      "Content-Length: " + content.size().string() + "\r\n"
      + "\r\n"
      + content