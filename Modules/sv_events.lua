--[[

Usage:
  -- Create an event.
  Event:createEvent("join")

  -- Observe the event with a callback.
  -- The callback function will receive an event object
  -- which will have two parameters:
  --   .type -- a string, which is the type of this event.
  --   .args -- a table with data relative to this event.
  -- There is an optional 3rd argument to observe(), which
  -- if true, will create the event if it does not already
  -- exist.
  function a_callback(event,data,channelId)
    Log(string.format("I got an event: %s\n", event.type))
    Log(string.firmat("With data: %d \n",table.concat(data,","))
    Log(string.format("With %d arguments.\n", table.getn(event.args)))
  end

  Event:observe("join", a_callback)

  -- Emit the event!
  -- The second argument to emit() should be a table
  -- of data related to the event. It can be nil, in
  -- which case the created event object's .args
  -- property will be set to {}.
  Event:emit("join", {nick = "foobar", host = "..."},channelId)

  -- To no longer observe and event, pass in the callback
  -- function once again. Callbacks are matched based on
  -- the function you passed in. Remember, it HAS to be the
  -- same function; passing in anonymous functions won't work,
  -- unless you save the return value from Event.observe(),
  -- since it returns the callback function provided.
  Event.unobserve("join", a_callback)

  -- Silence an event if you wanted to prevent callbacks from
  -- being called.
  Event:silence("join")

  -- any callbacks won't be called now.
  Event:emit("join", {nick = "foobar", host = "..."},channelId)

  -- Allow callbacks to happen once more.
  Event:unsilence("join")

  -- You can remove events as well. This will remove
  -- the event and all of it's callbacks by setting the event
  -- to nil, allowing it to be garbage collected.
  Event:removeEvent("join")

]]
--
-- ───────────────────────────────────────────────────────────── DEPENDANCIES ─────
--

-- Object - ripped from the classic.lua module
local Object = {}
Object.__index = Object

function Object:new()
end

function Object:extend()
    local cls = {}
    for k, v in pairs(self) do
        if k:find("__") == 1 then
            cls[k] = v
        end
    end
    cls.__index = cls
    cls.super = self
    setmetatable(cls, self)
    return cls
end

function Object:implement(...)
    for _, cls in pairs({...}) do
        for k, v in pairs(cls) do
            if self[k] == nil and type(v) == "function" then
                self[k] = v
            end
        end
    end
end

function Object:is(T)
    local mt = getmetatable(self)
    while mt do
        if mt == T then
            return true
        end
        mt = getmetatable(mt)
    end
    return false
end

function Object:__tostring()
    return "Object"
end

function Object:__call(...)
    local obj = setmetatable({}, self)
    obj:new(...)
    return obj
end
-- ────────────────────────────────────────────────────────────────────────────────

--
-- ─── BEGIN MODULE ───────────────────────────────────────────────────────────────
--

sv_events = Object:extend()

function sv_events:new()
    self._Events = {}
    self._Callbacks = {}
    self._Silenced = {}
end

--- Create an event.
function sv_events:createEvent(event)
    if not self._Events[event] then
        self._Events[event] = {}
        self._Callbacks[event] = {}
    end
end

--- Remove an event.
function sv_events:removeEvent(event)
    self._Events[event] = nil
    self._Callbacks[event] = nil
end

--- Check to see if an event is known.
--- will be nil if it doesn't exist.
function sv_events:hasEvent(event)
    return self._Events[event]
end

--- Observe an event. A callback function is required.
--- If do_create is true, and the event does not exist,
--- it will be created before storing the callback.
--- The callback function will be returned if it was
--- added, else nil is returned.
function sv_events:observe(event, callback, do_create)
    if (not self:hasEvent(event) ) and do_create then
        self:createEvent(event)
    end

    table.insert(self._Callbacks[event], callback)

    return callback
end

--- No longer observe an event. The callback given to the
--- original observe() call must be given. It HAS to be
--- the same function, matching the function's ID, or else
--- the callback won't be removed. Thus, be careful passing
--- in anonymous functions as callbacks, unless you save the
--- return value from observe() to later use to unobserve.
function sv_events:unobserve(event, callback)
    if self:hasEvent(event) then
        local tmp = {}

        for _, cb in self._Callbacks[event] do
            if not callback == cb then
                table.insert(tmp, cb)
            end
        end

        self._Callbacks[event] = tmp
        return true
    end

    return false
end

--- Emit an event. Callback functions are passed an
--- event object with .type and .data properties, with
--- .type being set to the type of event, and .data being
--- a provided table of values to be available to all observers.
--- any other args are appended to the calback function call
function sv_events:emit(event,data, ...)
  local arg = {n = select("#", ...); ...}
    if self:hasEvent(event) and (not self:isSilenced(event)) then
        local ev = {type = event, args = (arg or {})}

        for idx, callback in ipairs(self._Callbacks[event]) do
            if type(callback) == "function" then
                callback(ev,data)
            end
        end
    end
end

--- Silence an event, causing any of it's callback
--- functions to not be called if the event is emitted.
function sv_events:silence(event)
    if not self._Silenced[event] then
        self._Silenced[event] = true
    end

    return self._Silenced[event]
end

--- Remove the silencing of an event.
function sv_events:unsilence(event)
    self._Silenced[event] = nil
end

--- Checks to see if an event is silenced.
function sv_events:isSilenced(event)
    return self._Silenced[event]
end

RegisterModule("mFramework.Events",sv_events)