local Format = {}
Format.arrayTag = {}
function Format.makeExplicitArray(arr)
    if arr == nil then arr = {} end
    arr[Format.arrayTag] = true
    return arr
end
local indentStr = "  "
local escapes = {
    ["\n"] = "\\n",
    ["\r"] = "\\r",
    ["\""] = "\\\"",
    ["\\"] = "\\\\",
    ["\b"] = "\\b",
    ["\f"] = "\\f",
    ["\t"] = "\\t",
    ["\0"] = "\\u0000"
}
local escapesPattern = "[\n\r\"\\\b\f\t%z]"
local function escape(str)
    local escaped = str:gsub(escapesPattern, escapes)
    return escaped
end
local function isArray(val)
    if val[Format.arrayTag] then return true end
    local len = rawlen(val)
    if len == 0 then return false end
    for k in pairs(val) do
        if (type(k) ~= "number") or (k > len) then return false end
    end
    return true
end
function Format.asJson(val, indent, tables)
    if indent == nil then indent = 0 end
    tables = tables or ({})
    local valType = type(val)
    if (valType == "table") and (not tables[val]) then
        tables[val] = true
        if isArray(val) then
            local arrayVals = {}
            for _, arrayVal in ipairs(val) do
                local valStr = Format.asJson(arrayVal, indent + 1, tables)
                table.insert(arrayVals, ("\n" ..
                                 tostring(indentStr:rep(indent + 1))) ..
                                 tostring(valStr))
            end
            return ((("[" .. tostring(table.concat(arrayVals, ","))) .. "\n") ..
                       tostring(indentStr:rep(indent))) .. "]"
        else
            local kvps = {}
            for k, v in pairs(val) do
                local valStr = Format.asJson(v, indent + 1, tables)
                table.insert(kvps,
                             (((("\n" .. tostring(indentStr:rep(indent + 1))) ..
                                 "\"") .. tostring(escape(tostring(k)))) ..
                                 "\": ") .. tostring(valStr))
            end
            return ((#kvps > 0) and
                       (((("{" .. tostring(table.concat(kvps, ","))) .. "\n") ..
                           tostring(indentStr:rep(indent))) .. "}")) or "{}"
        end
    elseif (valType == "number") or (valType == "boolean") then
        return tostring(val)
    else
        return ("\"" .. tostring(escape(tostring(val)))) .. "\""
    end
end
RegisterModule("svaltek.format", Format)
return Format
