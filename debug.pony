use "files"


actor Debugger
  let env: Env
  let outfile: File

  new create(env': Env) =>
    env = env'
    // TODO: port to LSP tracing
    let path = FilePath(FileAuth(env.root), Path.abs("pony-lsp.log"))
    outfile = File(path)

  be print(data: String) =>
    outfile.write(data + "\n")

  be write(data: String) =>
    outfile.write(data)