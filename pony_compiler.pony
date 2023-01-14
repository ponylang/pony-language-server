use "pony-ast/ast"
use "term"
use "cli"
use "files"


actor PonyCompiler
  let env: Env
  let debug: Debugger

  new create(env': Env, debug': Debugger) =>
    env = env'
    debug = debug'

  be apply(uri: String, notifier: CompilerNotifier tag) =>
    match Compiler.compile(env, FilePath(FileAuth(env.root), Path.dir(uri)))
    | let p: Program => None
    | let errs: Array[Error] =>
      for err in errs.values() do
        debug.print("PonyCompiler error found: " + err.msg)
        notifier.on_error(err.file, err.line, err.pos, err.msg)
      end
      notifier.done()
    end


interface CompilerNotifier
  be on_error(uri: String, line: USize, pos: USize, msg: String)
  be done()