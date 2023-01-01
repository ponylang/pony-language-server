use "net"
use "valbytes"
use "debug"
use "transport"

actor Main
  """
  A simple HTTP Echo server, sending back the received request in the response body.
  """
  new create(env: Env) =>
    let channel = try env.args(1)? else "stdio" end
    match channel
    | "stdio" =>
      let manager = Stdio(env.out)
      env.input(consume manager)
    else
      env.out.print("Channel not implemented: " + channel)
    end