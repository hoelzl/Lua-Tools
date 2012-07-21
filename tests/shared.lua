-- example usage -------------------------------------------------------------------------
-- 1. run this script                                                                   --
-- 2. type "gets hello world" into the prompt                                           --
-- 3. type "answer" into the prompt (should now be prefixed with 2)                     --
-- 4. type "stop" to see the original "gets" call end                                   --
------------------------------------------------------------------------------------------

package.path = "../src/?.lua;"..(package.path or "")
require "shared"
require "shell"

init("localhost")
print(helpShell())
print([[
  The prefixed number indicates the current coroutine. New ones are produced on the fly
  when a coroutine blocks. Use the stop command to switch coroutines.]])
local calls = {}
local current = 1
local max = 1
while true do
	calls[current] = calls[current] or coroutine.create(function() runShell("localhost", tostring(current)) end)
	if coroutine.status(calls[current]) == "dead" then
		print("An unexpected error occured.")
		os.exit() --calls should never die anyway
	end
	if coroutine.status(calls[current]) == "suspended" then
		local success, unblock = coroutine.resume(calls[current])
		if not success then print(unblock); os.exit() end --makes debugging easier
		if not unblock then max = max + 1 end
	end
	current = current < max and current + 1 or 1
end
term()