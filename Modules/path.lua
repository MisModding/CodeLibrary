local Path = {}
Path.separator = (function()
    local config = _G.package.config
    if config then
        local sep = config:match("^[^\n]+")
        if sep then return sep end
    end
    return "/"
end)()
local cwd
function Path.getCwd()
    if not cwd then
        local p = io.popen(((Path.separator == "\\") and "cd") or "pwd")
        if p then cwd = p:read("*a"):match("^%s*(.-)%s*$") end
        cwd = cwd or ""
    end
    return cwd
end
function Path.dirName(path)
    local dir = path:match(((("^(.-)" .. tostring(Path.separator)) .. "+[^") ..
                               tostring(Path.separator)) .. "]+$")
    return dir or "."
end
function Path.splitDrive(path)
    local drive, pathPart = path:match("^[@=]?([a-zA-Z]:)[\\/](.*)")
    if drive then
        drive = tostring(drive:upper()) .. tostring(Path.separator)
    else
        drive, pathPart = path:match("^[@=]?([\\/]*)(.*)")
    end
    return assert(drive), assert(pathPart)
end
local formattedPathCache = {}
function Path.format(path)
    local formattedPath = formattedPathCache[path]
    if not formattedPath then
        local drive, pathOnly = Path.splitDrive(path)
        local pathParts = {}
        for part in assert(pathOnly):gmatch("[^\\/]+") do
            if part ~= "." then
                if ((part == "..") and (#pathParts > 0)) and
                    (pathParts[#pathParts] ~= "..") then
                    table.remove(pathParts)
                else
                    table.insert(pathParts, part)
                end
            end
        end
        formattedPath = tostring(drive) ..
                            tostring(table.concat(pathParts, Path.separator))
        formattedPathCache[path] = formattedPath
    end
    return formattedPath
end
function Path.isAbsolute(path)
    local drive = Path.splitDrive(path)
    return #drive > 0
end
function Path.getAbsolute(path)
    if Path.isAbsolute(path) then return Path.format(path) end
    return Path.format((tostring(Path.getCwd()) .. tostring(Path.separator)) ..
                           tostring(path))
end
RegisterModule("svaltek.path")
return Path
