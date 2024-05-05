use "pony_test"
use "files"
use ".."

primitive _WorkspaceTests is TestList
  new make() =>
    None

  fun tag tests(test: PonyTest) =>
    test(_RouterFindTest)

class \nodoc\ iso _RouterFindTest is UnitTest
  fun name(): String => "router/find"

  fun apply(h: TestHelper) ? =>
    let file_auth = FileAuth(h.env.root)
    let this_dir_path = Path.dir(__loc.file())
    let folder = FilePath(file_auth, this_dir_path)
    let workspaces = WorkspaceScanner.scan(file_auth, this_dir_path)
    h.assert_eq[USize](1, workspaces.size())
    let workspace = workspaces(0)?
    let router = WorkspaceRouter.create()
    let compiler = PonyCompiler("") // dummy, not actually in use
    let channel = TestChannel(h,
      {(h: TestHelper, channel: TestChannel ref): Bool =>
        true
      })
    let mgr = WorkspaceManager(workspace, channel, compiler)
    router.add_workspace(folder, mgr)?

    let file_path = folder.join("main.pony")?
    let found = router.find_workspace(file_path.path)
    h.assert_isnt[(WorkspaceManager | None)](None, found)
    let mgr = found as WorkspaceManager
    mgr

