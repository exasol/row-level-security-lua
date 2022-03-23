---
-- This is the main entry point of the Lua Virtual Schema adapter.
-- <p>
-- It is responsible for creating and wiring up the main adapter objects.
-- </p>

local adapter = require("exasolrls.rls_adapter")
local dispatcher = require("exasolvs.RequestDispatcher").init(adapter)

---
-- Handle a Virtual Schema request.
-- 
-- @param request_as_json JSON-encoded adapter request
-- 
-- @return JSON-encoded adapter response
-- 
function adapter_call(request_as_json)
    return dispatcher.adapter_call(request_as_json)
end