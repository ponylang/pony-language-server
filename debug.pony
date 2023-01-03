use "files"


actor Debugger
    let env: Env
    let outfile: File

    new create(env': Env) =>
        env = env'
        let path = FilePath(FileAuth(env.root), "/Users/jairocaro-accinoviciana/pony-lsp/pony-lsp.log")
        outfile = File(path)

    be print(data: String) =>
        outfile.write(data + "\n")

    be write(data: String) =>
        outfile.write(data)