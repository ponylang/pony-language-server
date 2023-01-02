use "protocol"

actor Main
  let _env: Env

  new create(env: Env) =>
    _env = env
    let channel = try env.args(1)? else "stdio" end
    env.out.print("Initializing channel " + channel)
    match channel
    | "stdio" => Stdio(env, this)
    else
      env.out.print("Channel not implemented: " + channel)
    end

  be handle_message(msg: Message val) =>
    _env.out.print("Main handle_message")