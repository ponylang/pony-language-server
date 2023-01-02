use "protocol"

interface Manager
    be handle_message(msg: Message val)

interface Transport
    be send_message(msg: Message val)
    be set_manager(manager': Manager tag) 