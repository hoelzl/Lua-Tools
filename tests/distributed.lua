-- example usage -------------------------------------------------------------------------
-- 1. run this program twice                                                            --
-- 2. type "gets hello world" into one of the instances                                 --
-- 3. type "answer" into the other                                                      --
------------------------------------------------------------------------------------------

package.path = "../src/?.lua;"..(package.path or "")
require "distributed"
require "shell"

init(arg[1], arg[2])
print(shell.help())
shell.run(arg[3] or "localhost")
term()
