use "collections"
use "files"
use "itertools"
use "immutable-json"

class val WorkspaceData
  """
  Data extracted from corral.json
  """
  let name: String
  let folder: FilePath
  // absolute paths
  let dependency_paths: Array[String] val
  // absolute paths
  let package_paths: Set[String] val
  let _min_package_paths_len: USize
  // TODO: further structure a workspace into different packages, separately
  // compiled

  new val create(
    name': String,
    folder': FilePath,
    dependency_paths': Set[String] val,
    package_paths': Set[String] val)
  =>
    name = name'
    folder = folder'
    dependency_paths =
      recover val
        Iter[String](dependency_paths'.values())
          .collect(Array[String].create(dependency_paths'.size()))
      end
    package_paths = package_paths'
    var min: USize = USize.max_value()
    for package_path in package_paths.values() do
      min = min.min(package_path.size())
    end
    _min_package_paths_len = min

  fun debug(): String =>
    var dp_arr = Arr.create()
    for dp in dependency_paths.values() do
      dp_arr = dp_arr(dp)
    end
    var pp_arr = Arr.create()
    for pp in package_paths.values() do
      pp_arr = pp_arr(pp)
    end
    Obj("name", name)(
      "folder", folder.path
    )(
      "dependency_paths", dp_arr
    )(
      "packages", pp_arr
    ).build().string()

  fun find_package(document_path: String): (FilePath | None) =>
    var doc_path: String val = document_path
    while (doc_path != ".") and (doc_path.size() >= _min_package_paths_len) do
      try
        let package_path = this.package_paths(doc_path)?
        return this.folder.join(
          package_path.substring(this.folder.path.size().isize() + 1)
        )?
      end
      doc_path = Path.dir(doc_path)
    end
    None


