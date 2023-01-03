use "protocol"


class InputNotifier is InputNotify
    let parent: Stdio

    new iso create(parent': Stdio) =>
        parent = parent'

    fun ref apply(data': Array[U8 val] iso): None val =>
        var data = String.from_array(consume data')
        parent.handle_data(data)
    
    fun ref dispose(): None val =>
        None


actor Stdio is InputNotify
    var env: Env
    var out: OutStream
    var protocol_handler: BaseProtocol
    var manager: Main
    var debug: Debugger

    new create(env': Env, manager': Main, debug': Debugger) =>
        env = env'
        out = env.out
        debug = debug'
        protocol_handler = BaseProtocol
        manager = manager'
        let notifier = InputNotifier(this)
        env.input(consume notifier)

    be handle_data(data: String) =>
        let req = protocol_handler(data)
        match req
        | let r: Message val =>
            match manager
            | let m: Main => m.handle_message(r)
            end
        end

    // be send_message(msg: Message) =>
    //     None