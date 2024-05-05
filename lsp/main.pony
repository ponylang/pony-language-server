use "files"
use "ast"

actor Main
  new create(env: Env) =>
    let channel = Stdio(env.out, env.input)
    let pony_path =
      match PonyPath(env)
      | let p: String => p
      | None => ""
      end
    let language_server = LanguageServer(channel, env, pony_path)
    // at this point the server should listen to incoming messages via stdin
