use "ast"
use "lib:z" if posix // temporary workaround until next ponyc release
use "term"
use "cli"
use "files"
use "debug"


interface CompilerNotifier
  be on_error(uri: (String | None), line: USize, pos: USize, msg: String)
  be done()

interface TypeNotifier
  be type_notified(t: (String | None))


actor PonyCompiler
  let env: Env
  let channel: Stdio
  var package: (Package | None) = None

  new create(env': Env, channel': Stdio) =>
    env = env'
    channel = channel'

  be apply(uri: String, notifier: CompilerNotifier tag) =>
    Log(channel, "PonyCompiler apply")
    // extract PONYPATH
    var pony_path = ""
    match PonyPath(env)
    | let pp: String => pony_path = pp
    else
      Log(channel, "Couldn't retrieve PONYPATH")
      return
    end 
    if FilePath(FileAuth(env.root), Path.dir(uri) + "/_corral").exists() then
      var paths = [pony_path]
      let handler =
        {ref(dir_path: FilePath val, dir_entries: Array[String val] ref)(paths): None =>
          Log(channel, "## folder " + dir_path.path) 
          if Path.base(dir_path.path) != "_corral" then
            dir_entries.clear()
            paths.push(dir_path.path)
          end}
      FilePath(FileAuth(env.root), Path.dir(uri) + "/_corral").walk(handler, false)
      pony_path = ":".join(paths.values())
    end
    match Compiler.compile(FilePath(FileAuth(env.root), Path.dir(uri)), pony_path)
    | let p: Program => 
      try 
        Log(channel, "Program received") 
        package = p.package() as Package 
      else 
        Log(channel, "Error getting package from program") 
      end
    | let errs: Array[Error] =>
      Log(channel, "Compile errors: " + errs.size().string())
      for err in errs.values() do
        Log(channel, "Error: " + err.msg)
        notifier.on_error(err.file, err.line, err.pos, err.msg)
      end
    end
    Log(channel, "Stdlib path: " + pony_path)
    Log(channel, "PonyCompiler called CompilerNotifier done()")
    notifier.done()

  be get_type_at(file: String, line: USize, column: USize, notifier: TypeNotifier tag) =>
    Log(channel, "get_type_at " + file + " line:" + line.string() + " column:" + column.string())
    match package
    | let p: Package ref =>
      try
        let module = get_module(file, p) as Module
        match get_ast_at(line, column, module.ast)
        | let ast: AST =>
          Log(channel, "FOUND " + TokenIds.string(ast.id()))
          notifier.type_notified(Types.get_ast_type(ast))
        else
          Log(channel, "could not get AST")
        end
      else
        Log(channel, "could not get Module")
      end
    else
      Log(channel, "Package is None")
    end

  fun get_ast_at(line: USize, column: USize, ast: AST): (AST | None) =>
    try
      var child: AST = ast.child() as AST
      while true do
        let child_pos = child.pos()
        Debug("Checking child " + TokenIds.string(child.id()) + " at line: " + child.line().string() + " col: " + child_pos.string())
        if child.line() == line then
          Debug("line " + line.string() + " found")
          Debug("pos: " + child_pos.string() + " column: " + column.string() + " == " + (child_pos == column).string() + ", > " + (child_pos > column).string())

          // check the position of the last child
          // if it is beyond our intended column, one of the children of this
          // node is ours
          try
            let last_child = child.last_child()
            let last_child_pos = (last_child as AST).pos()
            Debug("Last child pos: " + last_child_pos.string())
            if (last_child_pos == column) and (last_child_pos > child_pos) then
              return child.last_child()
            elseif (child_pos < column) and (column < last_child_pos) then
              // our thingy is somewhere in here
              Debug("Descend into " + TokenIds.string(child.id()))
              // it must be somewhere in there, no need to iterate further
              // also return if it is None, it is here or nowhere
              return get_ast_at(line, column, child)
            end
          end

          // we can get the length of ids and strings
          // use it to correctly match the token
          match child.token_value()
          | let s: String =>
            // strings have at least 1 trailing quote
            let ast_end = child.pos() + s.size() + if child.id() == TokenIds.tk_string() then 1 else 0 end
            if (child.pos() <= column) and (column <= ast_end) then
              return child
            end
          | None =>
            if child.pos() >= column then
              if (child.pos() == column) then
                return child
              elseif child.infix_node() then
                Debug("INFIX NODE " + TokenIds.string(child.id()))
                // infix nodes might have some lhs child that is closer to the
                // actual position, so go inside and check
                match get_ast_at(line, column, child)
                | let in_child: AST => return in_child
                | None => return child
                end
              else
                // we are past our desired columns
                // return the previous or the parent node
                let prev = child.prev()
                if prev is None then
                  return ast
                else
                  return prev
                end
              end
            end
          end


        end
        // recurse to childs children
        match get_ast_at(line, column, child)
        | let found: AST => return found
        end
        child = child.sibling() as AST
      end
    end

  fun get_module(file: String, pkg: Package): (Module | None) =>
    Debug("trying to find module from: " + file)
    for module in pkg.modules() do
      Debug("checking: " +  module.file)
      if module.file == file then
        Debug("found module: " + file)
        return module
      end
    end


