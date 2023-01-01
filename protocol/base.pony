use "json"

type ReceivingMode is (ReceivingModeHeader | ReceivingModeContent)
primitive ReceivingModeHeader
primitive ReceivingModeContent


interface ProtocolHandler
    fun ref apply(data: String): (None | RequestMessage)


class Header
    var key: String
    var value: String
    new create(key': String, value': String) =>
        key = key'
        value = value'


class BaseProtocol
    var line_buffer: String ref = String
    var content_buffer: String ref = String
    var headers: Array[Header] = Array[Header]
    var receiving_mode: ReceivingMode = ReceivingModeHeader

    new ref create() => None

    fun ref apply(data: String): (None | RequestMessage) =>
        match receiving_mode
        | ReceivingModeHeader => receive_headers(data)
        | ReceivingModeContent => receive_content(data)
        end

    fun ref receive_headers(data: String): (None | RequestMessage) =>
        line_buffer.append(data)
        if line_buffer.contains("\r\n") then
            let abuffer = line_buffer.split("\r\n")
            let msg = abuffer.shift()
            line_buffer = "\r\n".join((consume abuffer).values())
            if msg == "" then
                receiving_mode = ReceivingModeContent
                content_buffer = line_buffer = String
                receive_content("")
            else
                let hdata = msg.split(": ")
                headers.push(Header(hdata(0), hdata(1)))
            end
        end

    fun ref receive_content(data: String): (None | RequestMessage) =>
        content_buffer.append(data)
        if content_buffer.contains("\r\n") then
            parse_message()
        end

    fun ref parse_message(): RequestMessage =>
        let doc = JsonDoc
        let data = content_buffer.clone()
        doc.parse(consume data)
        let json: JsonObject  = doc.data as JsonObject
        var id: (String | LSPInteger) = ""
        match json.data("id")?
        | let id': String => id = id'
        | let id': LSPInteger => id = id'
        end
        var method = json.data("method")? as String
        var params: (LSPObject | LSPArray | None) = None
        match json.data("params")?
        | let paramsObject: LSPObject => params = paramsObject
        | let paramsArray: LSPArray => params = paramsArray
        end
        RequestMessage(id, method, params)