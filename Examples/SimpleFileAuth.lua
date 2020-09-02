---* IsAdminPlayer
---| Checks if a given steamId is listed in a `admins.txt` file in server root `MiscreatedServer/admins.txt`
--| Will Print an Error in The log and return false if the file does not exist
--| admins.txt should have ONE steamId per line (to help remember who is who, its also ok to use the format: name steamId )
---@param steamId string: players steam64Id
---@return boolean, string
--| if the steamid was found returns true or false plus a message if not
local function IsAdminPlayer(steamId)
    -- try to open the admins.txt file
    local file = io.open('./admins.txt')
    local admins = {} -- this holds each line of the file
    local i = 0 -- keep track of the current line index
    -- did we successfully open the file (does it exist?)
    if file then
        -- yes so iterate through the lines using our lineIndex as table index
        for line in file:lines() do
            -- each iteration is a new line so increment the line index
            i = i + 1
            -- add the line content to the table
            admins[i] = line
        end
        -- Allways close the file when we are done with it to avoid file access errors.
        file:close()
            -- concat the admins table into a string delimited by `;` then use the current steamid as a pattern to match with
        if string.find(table.concat(admins, ';'), steamId) then
            -- if found then this steamId was in the file so return authorised
            return true, "Authorised"
        else
            -- otherwise its not in the file so return false.
            return false, "Unauthorised"
        end
    else
        local errmsg = './admins.txt file not found or failed to be read'
        -- Failed to Open the File, Moan about it in ServerLog
        LogError(errmsg);
        -- then just return false and the errormsg, no file means no authorisation
        return false, errmsg
    end
    --- this shouldn't ever be seen unless something realy goes wrong when trying to iterate the lines of the file.
    LogError("Something went wrong. unable to Process admins.txt")
end
