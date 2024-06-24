## Fix resolving definition for implicit create sugar

Previously constructs like the right hand side of this expression: `let foo = Bar` couldn't be resolved properly although they are widely used in Pony. The issue was that the simple identifier `Bar` get desugared to `Bar.create()` with all AST nodes at the same position, which confused the LSP.

