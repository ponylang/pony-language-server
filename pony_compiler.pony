use "pony-ast/ast"
use "lib:z" if posix // TODO: temporary
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
        notifier.on_error(err.file, err.line, err.pos, err.msg)
      end
    end
    notifier.done()


interface CompilerNotifier
  be on_error(uri: String, line: USize, pos: USize, msg: String)
  be done()