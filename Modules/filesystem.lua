local sv_fs = {}

--- return the contents of a file as a string
-- @param filename The file path
-- @param is_bin open in binary mode, default false
-- @return file contents, or nil,error
function sv_fs.readfile(filename,is_bin)
  local mode = is_bin and 'b' or ''
  local f,err = io.open(filename,'r'..mode)
  if not f then return nil,err end
  local res,err = f:read('*a')
  f:close()
  if not res then return nil,err end
  return res
end

--- write a string to a file,
-- @param filename The file path
-- @param str The string
-- @param is_bin open in binary mode, default false
-- @return true or nil,error
function sv_fs.writefile(filename,str,is_bin)
  local f,err = io.open(filename,'w'..(is_bin or ''))
  if not f then return nil,err end
  f:write(str)
  f:close()
  return true
end

--- Read a file into a list of lines and close it.
-- @param h file handle or name (default: <code>io.input ()</code>)
-- @return list of lines
function sv_fs.readlines (h)
  if h == nil then
    h = io.input ()
  elseif _G.type (h) == "string" then
    h = io.open (h)
  end
  local l = {}
  for line in h:lines () do
    table.insert (l, line)
  end
  h:close ()
  return l
end

--- Write values adding a newline after each.
-- @param h file handle (default: <code>io.output ()</code>
-- @param ... values to write (as for write)
function sv_fs.writeline (h, ...)
  if io.type (h) ~= "file" then
    io.write (h, "\n")
    h = io.output ()
  end
  for _, v in ipairs ({...}) do
    h:write (v, "\n")
  end
end

separator = "/"

--- Strip the path off a path+filename.
-- @param pathname string: A path+name, such as "/a/b/c"
-- or "\a\b\c".
-- @return string: The filename without its path, such as "c".
function sv_fs.base_name(pathname)
   local base = pathname:match(".*[/\\]([^/\\]*)")
   return base or pathname
end

--- Strip the name off a path+filename.
-- @param pathname string: A path+name, such as "/a/b/c".
-- @return string: The filename without its path, such as "/a/b/".
-- For entries such as "/a/b/", "/a/" is returned. If there are
-- no directory separators in input, "" is returned.
function sv_fs.dir_name(pathname)
   return (pathname:gsub("/*$", ""):match("(.*/)[^/]*")) or ""
end

function sv_fs.strip_base_dir(pathname)
   return pathname:gsub("^[^/]*/", "")
end


local sep, other_sep = package.config:sub(1,1),'/'

--- split a path into directory and file part.
-- if there's no directory part, the first value will be the empty string.
-- Handles both forward and back-slashes on Windows.
-- @param P A file path
-- @return the directory part
-- @return the file part
function sv_fs.splitpath(P)
    local i = #P
    local ch = P:sub(i,i)
    while i > 0 and ch ~= sep and ch ~= other_sep do
        i = i - 1
        ch = P:sub(i,i)
    end
    if i == 0 then
        return '',P
    else
        return P:sub(1,i-1), P:sub(i+1)
    end
end

--- split a path into root and extension part.
-- if there's no extension part, the second value will be empty
-- @param P A file path
-- @return the name part
-- @return the extension
function sv_fs.splitext(P)
    local i = #P
    local ch = P:sub(i,i)
    while i > 0 and ch ~= '.' do
        if ch == sep or ch == other_sep then
            return P,''
        end
        i = i - 1
        ch = P:sub(i,i)
    end
    if i == 0 then
        return P,''
    else
        return P:sub(1,i-1),P:sub(i)
    end
end



local PathSep = string.sub(package.config, 1, 1)
--- Describe a path
-- uses the current systems defined seperator
-- @param ... strings representing directories
-- @return string: a string with a platform-specific representation
-- of the path.
function sv_fs.joinpath(...)
    local path = ''
    for i, segment in ipairs({...}) do
        if PathSep ~= "/" then
            segment = segment:gsub([[\]], "/")
        end
        if i == 1 then
            path = segment
        else
            path = path .. '/' .. segment
        end
    end
    return string.gsub(path, '/+', '/')
end

function sv_fs.isFile(path)
  local f = io.open(path, "r")
  if f then
      f:close()
      return true
  end
  return false
end
-- Check if a directory exists path
function sv_fs.isDir(path)
  path = string.gsub(path .. "/", "//", "/")
  local ok, err, code = os.rename(path, path)
  if ok or code == 13 then
      return true
  end
  return false
end

function sv_fs.mkDir(path)
  local ok, Result = os.execute("mkdir " .. path:gsub("/", "\\"))
  if not ok then
      return nil, "Failed to Create " .. path .. " Directory! - " .. Result
  else
      return true, "Successfully Created " .. path .. " Directory!"
  end
end

--- Write a Table as JSON file to Disk
--- @param path string       path of file to Write, starts in Server root
--- @param data any          File Contents to Write
--- @return boolean,string   true/nil and a message
function sv_fs.WriteJSON(path, data)
  local JSON = require("JSON")
  local thisFile = assert(io.open(path, 'w'))
  if thisFile ~= nil then
      local fWritten = thisFile:write(JSON.stringify(data))
      thisFile:close()
      if fWritten ~= nil then
          return true, 'Success Writing File: <ServerRoot>/' .. path
      else
          return nil, 'Failed to Write Data to File: <ServerRoot>/' .. path
      end
  else
      return nil, 'Failed to Open file for Writing: <ServerRoot>/' .. path
  end
end

--- Read JSON File as Table from Disk
--- @param path string      path of file to Write, starts in Server root
--- @return boolean,any     true/nil and file content or message
function sv_fs.ReadJSON(path)
  local JSON = require("JSON")
  local thisFile, errMsg = io.open(path, 'r')
  if thisFile ~= nil then
      local fContent = thisFile:read('*all')
      thisFile:close()
      if fContent ~= '' or nil then
          return true, JSON.parse(fContent)
      else
          return nil, 'Failed to Read from File: ' .. path
      end
  else
      return nil, 'Error Opening file: ' .. path .. ' io.open returned:' .. errMsg
  end
end

RegisterModule("SvalTek.FS",sv_fs)
return sv_fs