--- Return an array of keys of a table.
-- @param tbl table: The input table.
-- @return table: The array of keys.
local function table_keys(tbl)
   local ks = {}
   for k,_ in pairs(tbl) do
      table.insert(ks, k)
   end
   return ks
end

--- Load a Lua file containing assignments, storing them in a table.
-- The global environment is not propagated to the loaded file.
-- @param filename string: the name of the file.
-- @param tbl table or nil: if given, this table is used to store
-- loaded values.
-- @return table or (nil, string): a table with the file's assignments
-- as fields, or nil and a message in case of errors.
local function load_into_table(filename, tbl)
   assert(type(filename) == "string")
   assert(type(tbl) == "table" or not tbl)

   local chunk, err = loadfile(filename)
   if not chunk then
      return nil, err
   end
   local result = tbl or {}
   setfenv(chunk, result)
   chunk()
   return result
end

--- Write a table as Lua code representing a table to disk
-- (that is, in curly brackets notation).
-- This function handles only numbers, strings and tables
-- are keys (tables are handled recursively).
-- @param out userdata: a file object, open for writing.
-- @param tbl table: the table to be written.
local function write_table(out, tbl, level)
   out:write("{")
   local size = table.getn(tbl)
   local sep = "\n"
   local indent = true
   local i = 1
   for k, v in pairs(tbl) do
      out:write(sep)
      if indent then
         for n = 1,level do out:write("  ") end
      end
      sep = ",\n"
      indent = true
      if type(k) == "number" then
         if k ~= i then
            out:write(tostring(k).."=")
         else
            i = i + 1
         end
         indent = false
         sep = ", "
      elseif type(k) == "table" then
         out:write("[")
         write_table(out, k, level + 1)
         out:write("]=")
      else
         if k:match("^[a-z_]+$") then
            out:write(k.."=")
         else
            out:write("['"..k:gsub("'", "\\'").."']=")
         end
      end
      if type(v) == "table" then
         write_table(out, v, level + 1)
      elseif type(v) == "string" then
         out:write("'"..v:gsub("'", "\\'").."'")
      else
         out:write(tostring(v))
      end
   end
   if sep ~= "\n" then
      out:write("\n")
      for n = 1,level-1 do out:write("  ") end
   end
   out:write("}")
end

--- Save the contents of a table in a file.
-- Each element of the table is saved as a global assignment.
-- Only numbers, strings and tables (containing numbers, strings
-- or other recursively processed tables) are supported.
-- @return boolean or (nil, string): true if successful, or nil and a
-- message in case of errors.
local function save_from_table(filename, tbl)
   local out = io.open(filename, "w")
   if not out then
      return nil, "Cannot create file at "..filename
   end
   for k, v in pairs(tbl) do
      out:write(k.." = ")
      write_table(out, v, 1)
      out:write("\n")
   end
   out:close()
   return true
end


-- @section Table Functions

---* Pretty Print (Dumps) Tables/Objects/Strings with formatting
--- @param value any
-- value to Pretty Print
local function pretty(value, level)
   local level = level or 0
   local output = {}
   local insert, concat, format = table.insert, table.concat, string.format

   local function add(line, indent)
       insert(output, format('%s%s', string.rep('  ', indent or 0), line))
   end
   local function isarray(t)
       if type(t) ~= 'table' then
           return false
       end
       for k, _ in pairs(t) do
           if type(k) ~= 'number' then
               return false
           end
       end
       return true
   end
   local function pretty_array(t)
       local strings = {}
       for _, v in ipairs(t) do
           insert(strings, pretty(v, level + 1))
       end
       return concat(strings, ', ')
   end

   if type(value) == 'table' then
       if isarray(value) then
           return format('[ %s ]', pretty_array(value))
       else
           local keys = {}
           for k, _ in pairs(value) do
               if type(k) ~= 'number' then
                   insert(keys, k)
               end
           end
           table.sort(keys)
           add('{')
           for _, k in ipairs(keys) do
               add(format('%s = %s', k, pretty(value[k], level + 1)), level + 1)
           end
           for _, v in ipairs(value) do
               add(pretty(v, level + 1), level + 1)
           end
           add('}', level)
       end
   elseif type(value) == 'string' then
       add(format("'%s'", value))
   else
       add(format('%s', tostring(value)))
   end
   return concat(output, '\n')
end

---* Return the Size of a Table.
-- Works with non Indexed Tables
--- @param table table  any table to get the size of
--- @return number      size of the table
local function table_size(table)
   local n = 0
   for k, v in pairs(table) do
       n = n + 1
   end
   return n
end

---* Copies all the fields from the source into t and return .
-- If a key exists in multiple tables the right-most table value is used.
--- @param t table      table to update
local function table_update(t, ...)
   for i = 1, select('#', ...) do
       local x = select(i, ...)
       if x then
           for k, v in pairs(x) do
               t[k] = v
           end
       end
   end
   return t
end

local sv_table_utils = {
   table_pretty = pretty,
   table_size = table_size,
   table_update = table_update,
   table_keys = table_keys,
   table_toFile = save_from_table,
   table_fromFile = load_into_table
}

RegisterModule("SvalTek.table_utils", sv_table_utils)
return sv_table_utils