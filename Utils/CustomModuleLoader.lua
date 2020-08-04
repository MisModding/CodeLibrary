--
-- ──────────────────────────────────────────────────────────────────────────────── I ──────────
--   :::::: S V A L T E K   L U A M O D   T O O L S : :  :   :    :     :        :          :
-- ──────────────────────────────────────────────────────────────────────────────────────────
--
-- Injects a Custom PreLoader and Provides a Method to "Register" require compatible "modules"
-- from Scripts loaded with Script.ReloadScript(path)/Script.LoadScriptFolder(path)
-- primaraly for use with CryEngine/Miscreated but Should work anywhere realy (using dofile).
--[[
    Example:

    --- SomeFile.lua:
    --  can be any where but needs to have been reloaded once to Register the Module.
    -- ────────────────────────────────────────────────────────────────────────────────

    --Create our "Module"
    local MyModule = {}

    function MyModule:SomeMethod()
        -- Some Module Method
    end

    function MyModule.helloWorld(name)
        -- Example function
        name = tostring(name or "Lua, !Didnt Pass a name!") -- Ensure we Have a value for our message
        Log( "Hello World...! from %s", name )
    end

    -- "Register" our Module
    RegisterModule("MyModuleName",MyModule) -- this also returns {boolean,string} as status,errmessage

    -- ────────────────────────────────────────────────────────────────── ENDFILE ─────


    --- SomeOtherFile.lua
    -- Reload the Script/Folder Containing your Module here Before atteping to Require it
    -- Not needed if allready Loaded Since Module Registered.

    -- now you can just require your module as usual.

    local myModule = require("MyModuleName")
    if myModule then
        Log("Module Load Ok")
        Log("Testing....")
        myModule.helloWorld("Miscreated") -- run the test `helloWorld` function from "MyModule"
    end
]]
-- ────────────────────────────────────────────────────────────────────────────────
if not _G['mLuaMods'] then
    _G['mLuaMods'] = {}
end

--[Custom Loader]
--- Internal: loadLuaMod(modulename)
-- Loads the Specified Module by namespace , if found in _G["mLuaMods"]
local function loadLuaMod(modulename)
    local errmsg = 'Failed to Find Module'
    -- Find the Module
    ---? uncomment for debugging
    --Log('loadLuaMod Searching: %s', modulename)
    local LuaMods = _G['mLuaMods']
    local this_module = LuaMods[modulename]
    if this_module then
        ---? uncomment for debugging
        --- Log('found Module: %s', modulename)
        return this_module
    end
    return errmsg
end

-- Install the loader so that it's called just before the normal Lua loader
table.insert(package.loaders, 2, loadLuaMod)

--[Usable Methods]
-- ────────────────────────────────────────────────────────────────────────────────

--- RegisterModule(name: string, mod: table) --> {boolean,string}
-- Registers a Module Table with the Custom Loader
---@param name string Module Name ,
-- This is the Module Name used to Load the Registered Module
---@param mod table Module Table,
-- This table Defines your Module, same as you would return in a standard module,
---@see https://gitlab.com/snippets/1944531
-- Check out the Linked gist for Info
---@return boolean,string
-- returns boolean Status, and a message
function RegisterModule(name, mod)
    if (type(name) ~= 'string') or (name == ('' or ' ')) then
        return false, 'Invalid Name Passed to RegisterModule, (must be a string and not empty).'
    elseif (type(mod) ~= 'table') or (mod == {}) then
        return false, 'Invalid Module Passed to RegisterModule, (must be a table and not empty).'
    end
    local LuaMods = _G['mLuaMods']

    -- Wrap the module in a function for the loader to return.
    local ModWrap = function()
        local M = mod
        return M
    end

    -- Ensure this Module doesnt allready Exist
    if LuaMods[name] then
        return false, 'A Module allready Exists with this Name.'
    else -- all ok, attempt to push the module into mLuaMods
        LuaMods[name] = ModWrap
    end

    if (LuaMods[name] == ModWrap) then -- named package matches module.
        return true, 'Module ' .. name .. ' Loaded succesfully'
    else -- somehow named package doesnt match our module, something bad happened.
        return false, 'Something went Wrong, the Loaded module didnt match as Expected.'
    end

    return nil, 'Unknown Error' -- This should never happen.
end
