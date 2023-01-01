use "protocol"


class Stdio is InputNotify
    var _out: OutStream
    var handler: ProtocolHandler

    new iso create(out': OutStream) =>
        _out = out'
        handler = BaseProtocol

    fun ref apply(data': Array[U8 val] iso): None val =>
        var data = String.from_array(consume data')
        _out.print("Data received: " + data)
        let req = handler(data)
        match req
        | let r: RequestMessage => _out.print("Got request")
        end
    
    fun ref dispose(): None val =>
        _out.print("Dispose")