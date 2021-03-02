---* bind an argument to a type and throw an error if the provided param doesnt match at runtime.
-- Note this works in reverse of the normal assert in that it returns nil if the argumens provided are valid
-- if not the it either returns true plus and error message , or if it fails to grab debug info just true.
--- @param idx number
-- positonal index of the param to bind
--- @param val any the param to bind
--- @param tp string the params bound type
--- @usage
-- local test = function(somearg,str,somearg)
-- if assert_arg(2,str,'string') then
--    return
-- end
--
-- test(nil,1,nil) -> Invalid Param in [test()]> Argument:2 Type: number Expected: string
local function assert_arg(idx, val, tp)
    if type(val) ~= tp then
        local fn = debug.getinfo(2, 'n')
        local msg = 'Invalid Param in [' .. fn.name .. '()]> ' ..
                        string.format('Argument:%s Type: %q Expected: %q', tostring(idx), type(val), tp)
        local test = function() error(msg, 4) end
        local rStat, cResult = pcall(test)
        if rStat then
            return true
        else
            return true, cResult
        end
    end
end


--
-- ──────────────────────────────────────────────────────────────────────────────────────── I ──────────
--   :::::: mFramework   S T O R A G E   C L A S S : :  :   :    :     :        :          :
-- ──────────────────────────────────────────────────────────────────────────────────────────────────
--
---@class Storage
---@field OwnerId userdata
---@field Owner table
---@field ItemCount number
---@field Items table


--- Describes a Storage Object
local Storage = {}
local meta = {
    __call = function(self, ...)
        if self['new'] then self:new(...) end
        return self
    end,
}
setmetatable(Storage,meta)

function Storage:new(obj)
    if assert_arg(1, obj, 'table') or (type(obj.GetName) ~= 'function') then
        return nil, 'Must pass a Valid Entity'
    else
        local steamId
        if obj.player then steamId = obj.player:GetSteam64Id() end
        self.OwnerId = obj.id
        self.Owner = {
            name = (obj:GetName() or 'Unknown'),
            class = (obj.class or 'Unknown'),
            steamId = (steamId or 'Unknown')
        }
        self:RefreshStorageContents()
    end
end

function Storage:RefreshStorageContents()
    local storageContent =
        (g_gameRules.game:GetStorageContent(self.OwnerId, '') or {})
    self.Items = {}
    for idx, itemId in ipairs(storageContent) do
        self.Items[idx] = System.GetEntity(itemId)
    end
    self.ItemCount = (#self.Items or 0)
end

--- internal function used to validate storage contents
local function storageHasItem(storage, itemClass, amount)
    storage:RefreshStorageContents()
    local items = {}
    for idx, item in pairs(storage.Items) do
        if item.class == itemClass then items[idx] = item end
    end
    if not ((items == {}) or (table.getn(items) < 1)) then
        if amount then
            local itemTotal = 0
            for _, thisItem in ipairs(items) do
                itemTotal = itemTotal + (thisItem.item:GetStackCount() or 1)
            end
            if itemTotal >= amount then return true end
        else
            return true
        end
    end
    return false
end

---* Check if this Storage Contains the Specified Item optionaly checks the amount of all stacks combined
---@param itemClass string
---@param amount number
---@return boolean
function Storage:HasItem(itemClass, amount)
    if assert_arg(1, itemClass, 'string') then
        return false, 'invalid itemClass'
    end
    return storageHasItem(self, itemClass, amount)
end

---* Uses ISM to Give an item to This Storage
---@param itemClass string
---@param itemAccessory string
---@param accessorySlot string slot id for accessories
---@return boolean
function Storage:AddItem(itemClass, itemAccessory, accessorySlot)
    local itemId
    if itemClass then
        itemId = ISM.GiveItem(self.OwnerId, itemClass);
        if not itemId then return false, 'Failed to Give Item' end
    end
    local accessoryId
    if itemAccessory then
        accessoryId = ISM.GiveItem(self.OwnerId, itemAccessory, false, itemId,
                                   accessorySlot);
        if not accessoryId then return false, 'Failed to Give Item' end
    end
    return itemId
end

---* Uses ISM to Give an amount of a single item to This Storage
-- returns boolean and remainingCount+Message on error
---@param itemClass string
---@param itemCount number
---@return boolean,number,string
function Storage:AddItemStacked(itemClass, itemCount)
    if assert_arg(1, itemClass, 'string') then
        return false, 'invalid itemClass'
    elseif assert_arg(2, itemCount, 'number') then
        return false, 'invalid itemCount'
    end
    local item = self:AddItem(itemClass)
    if item then
        if item.item['GetMaxStackSize'] then
            local MaxStack = item.item:GetMaxStackSize()
            if itemCount <= MaxStack then
                item.item:SetStackCount(itemCount)
            end
        end
    end
end

--- Create  CustomClasses table if not exist
if not g_CustomClasses then g_CustomClasses = {} end
--- Add our Class to CustomClasses
g_CustomClasses.Storage = Storage


--- to use this just call g_CustomClasses.Storage(entity)
--- passing a Valid entity that has storage as the entity param
---
--- example:
--- ...
local player = System.GetEntity(playerId)
--- initialise a StorageHandler for this entity
local Storage = g_CustomClasses.Storage(player)

--- Check if storage conatins at least 762x30 with 10 rounds, if not add it to the storage
if (not Storage:HasItem("762x30",10)) then
  Storage:AddItemStacked("762x30",10) -- give storage a magazin of 762x30 with 10 rounds (cannot give more than the items max stack size)
end
