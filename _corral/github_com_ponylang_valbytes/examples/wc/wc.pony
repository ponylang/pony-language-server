// in your code this `use` statement would be:
// use "valbytes"
use "../../valbytes"


actor Main
  """
  A simple `wc -l` clone, counting lines of what it receives via stdin.

  ### Usage:

  ```
  cat my_file.txt | ./wc

  """
  new create(env: Env) =>
    env.input(
      object iso is InputNotify
        var buf: ByteArrays = ByteArrays

        fun ref apply(data: Array[U8] iso) =>
          buf = buf + (consume data)

        fun ref dispose() =>
          var num_lines = USize(0)
          while buf.size() > 0 do
            match buf.find("\n")
            | (true, let line_idx: USize) =>
              num_lines = num_lines + 1
              buf = buf.drop(line_idx + 1)

            | (false, _) =>
              if buf.size() > 0 then
                num_lines = num_lines + 1
              end
              break
            end
          end
          env.out.print(num_lines.string())
      end,
      512
    )
