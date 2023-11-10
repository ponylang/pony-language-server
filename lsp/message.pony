use "immutable-json"
use "collections"

trait Message is Stringable
  fun json(): JsonObject

  fun string(): String iso^ =>
    let content = this.json().string()
    let size_str: String val = content.size().string()
      recover iso
        String.create(content.size() + size_str.size() + 20)
          .>append("Content-Length: ")
          .>append(size_str)
          .>append("\r\n\r\n")
          .>append(content)
      end


interface Notifier
  be handle_message(msg: Message val)


class RequestMessage is Message
  let id: (I64 | String | None)
  let method: String
  let params: JsonObject | JsonArray

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
