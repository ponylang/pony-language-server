use "files"
use "collections"
use "immutable-json"

class val PonyWorkspace
  """
  Data extracted from corral.json
  """
  let name: String
  let folder: FilePath
  let dependency_paths: Set[FilePath] val
  let package_paths: Set[FilePath] val

  new val create(
    name': String,
    folder': FilePath,
    dependency_paths': Set[FilePath] val,
    package_paths': Set[FilePath] val)
  =>
    name = name'
    folder = folder'
    dependency_paths = dependency_paths'
    package_paths = package_paths'



primitive WorkspaceScanner
  fun scan(auth: FileAuth, folder: String, workspace_name: (String | None) = None): Array[PonyWorkspace] val ? =>
    let path = FilePath(this.auth, folder)
    let name =
      match workspace_name
      | let n: String => n
      | None => Path.base(folder)
      end
    let handler = object is WalkHandler
      let workspaces: Array[PonyWorkspace] trn = recover trn Array[PonyWorkspace].create(1) end

      fun ref apply(dir_path: FilePath val, dir_entries: Array[String val] ref) =>
        try
          // skip over _corral folders
          let idx = dir_entries.find("_corral")?
          dir_entries.delete(idx)?
        end
        try
          dir_entries.find("corral.json")?
          workspaces.push(
            _scan_dir(dir_path, name)?
          )
        end

    end
    path.walk(handler)
    let workspaces = handler.workspaces = []
    consume workspaces

  fun _scan_dir(
    dir: FilePath,
    workspace_name: String,
    visited: Set[FilePath] ref = Set[FilePath].create()
  ): PonyWorkspace ? =>
    visited.set(dir)

    // load corral.json
    let corral_json_file = OpenFile(dir.join("corral.json")) as File
    let corral_json_str = corral_json_file.read_string(corral_json_file.size())
    let corral_json = JsonDoc .> parse(corral_json_str)?.data as JsonObject
    
    // extract packages
    let packages = JsonPath("$.packages", corral_json)?
    let package_paths = recover trn Set[FilePath].create(2) end
    for package in packages.values() do
      package_paths.set(dir.join(package as String))
    end

    // extract dependencies, also transitive ones
    let locators = JsonPath("$.deps.*.locator", corral_json)?
    let dependency_paths = recover trn Set[FilePath].create(4) end
    for locator in locators.values() do
      try
        let locator_flat_name = Locator(locator).flat_name()
        let locator_dir = (dir_path .> join("_corral") .> join(locator_flat_name))

        let already_in = visited.contains(locator_dir)
        if not already_in then
          dependency_paths.set(locator_dir)
          visited.set(locator_dir)
          try
            // scan for transitive dependencies
            // but only if we havent visited before
            // to avoid endlees loops over cyclic dependencies 
            let sub_workspace = _scan_dir(locator_dir, name, visited)?
            dependency_paths.append(sub_workspace.dependency_paths)
          end
        end
      end
    end
    PonyWorkspace(workspace_name, dir, consume dependency_paths, consume package_paths)


class WorkspaceRouter
  let workspaces: Map[String, WorkspaceManager]
  var min_workspace_path_len: USize

  new ref create() =>
    workspaces = Map[String, WorkspaceManager].create()
    min_workspace_path_len = USize.max_value()

  fun find_workspace(file_uri: String): (WorkspaceManager | None) =>
    var file_path = Uris.to_path(file_uri)
    // check the parent directories upwards if any of them is part of a workspace
    while (file_path != ".") and (file_path.size() > min_workspace_path_len) do
      try
        let workspace = workspaces(file_path)?
        return workspace
      end
      file_path = Path.dir(file_path)
    end
    None


  fun ref add_workspace(folder: FilePath, mgr: WorkspaceManager) ? =>
    let abs_folder = folder.canonical()?.path
    let old_mgr = workspaces(abs_folder) = mgr
    match old_mgr
    | let old_mgr: WorkspaceManager => old_mgr.dispose()
    end
    this.min_workspace_path_len = this.min_workspace_path_len.min(abs_folder.size())


actor WorkspaceManager
  """
  Handling all operations on a workspace
  """
  let workspace: PonyWorkspace
  let _channel: Channel

  new create(workspace': PonyWorkspace, channel': Channel) =>
    workspace = workspace'
    _channel = channel'

  // TODO: implement
  be did_open(document_uri: String, request: RequestMessage val) =>
    None

  be did_save(document_uri: String, request: RequestMessage val) =>
    None

  be hover(document_uri: String, request: RequestMessage val) =>
    None

  be goto_definition(document_uri: String, request: RequestMessage val) =>
    None

  be dispose() =>
    None

