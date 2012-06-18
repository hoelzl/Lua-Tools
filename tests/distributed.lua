-- example usage -------------------------------------------------------------------------
-- 1. run this program twice                                                            --
-- 2. type "gets hello world" into one of the instances                                 --
-- 3. type "answer" into the other                                                      --
------------------------------------------------------------------------------------------

package.path = "../src/?.lua;"..(package.path or "")
require "distributed"
require "tools"

init(arg[1], arg[2])
print(helpShell())
runShell(arg[3] or "localhost")
term()
