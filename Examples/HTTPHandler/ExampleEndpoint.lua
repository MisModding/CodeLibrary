local JSON = require("JSON")
local SHA1 = require("SHA1")
---? Import the Module
local APIServer = require("HTTPHandler")

---? define our Secret
local Secret = "testSecret"

---? define some AuthKeys
local Keys = {"widuh292ac0m9dg0f8g0df8pa0s9nd7"}

---? initialise our Handler
local testHandler = APIServer("/", Secret, Keys)

---? add a route
testHandler:addRoute("hello", function(route)
    Log("Handler says hi")
    for k, v in pairs(route) do
        Log(k, tostring(v))
        if type(v) == "table" then
            for k, v in pairs(v) do Log(k, tostring(v)) end
        end
    end
    --- return a response, allways return true else you handler will fail
    --- 200 is our returned status code along with our page content.
    --- and a table of key value text replacements
    return true, {200, "Hi ${name}"}, {name = route.params["name"]}
end, true)

---? create a valid request
-- * first Create a Json payload containing our parameters
local query = JSON.stringify {
    name = "theros", ---? our test endpoint accepts a name param.
    -- ! our test endpoint requires an authkey, we need to hash with SHA1_HEX using 
    authKey = SHA1.SHA1_HEX(Secret, "widuh292ac0m9dg0f8g0df8pa0s9nd7")
}
local request = query:toHex()

local ok, result = testHandler:Handle('/hello?' .. request)
Log(result)
