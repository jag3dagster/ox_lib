local events = {}
local timers = {}
local cbEvent = ('__ox_cb_%s')

RegisterNetEvent(cbEvent:format(cache.resource), function(key, ...)
    local cb = events[key]
    return cb and cb(...)
end)

---@param event string
---@param delay number | false prevent the event from being called for the given time
local function eventTimer(event, delay)
    if delay and type(delay) == 'number' and delay > 0 then
        local time = GetGameTimer()

        if (timers[event] or 0) > time then
            return false
        end

        timers[event] = time + delay
    end

    return true
end

---@param _ any
---@param event string
---@param delay number | false
---@param bps number
---@param cb function|false
---@param ... any
---@return ...
local function triggerServerCallbackLatent(_, event, delay, bps, cb, ...)
    if not eventTimer(event, delay) then return end

    local key

    repeat
        key = ('%s:%s'):format(event, math.random(0, 100000))
    until not events[key]

    TriggerLatentServerEvent(cbEvent:format(event), bps, cache.resource, key, ...)

    ---@type promise | false
    local promise = not cb and promise.new()

    events[key] = function(response, ...)
        response = { response, ... }
        events[key] = nil

        if promise then
            return promise:resolve(response)
        end

        if cb then
            cb(table.unpack(response))
        end
    end

    if promise then
        return table.unpack(Citizen.Await(promise))
    end
end

---@overload fun(event: string, delay: number | false, bps: number, cb: function, ...)
lib.callbackLatent = setmetatable({}, {
    __call = triggerServerCallbackLatent
})

---@param event string
---@param delay number | false prevent the event from being called for the given time
---@param bps number
--- Sends a latent event to the server and halts the current thread until a response is returned.
function lib.callbackLatent.await(event, delay, bps, ...)
    return triggerServerCallbackLatent(_, event, delay, bps, false, ...)
end

local function callbackResponse(success, result, ...)
    if not success then
        if result then
            return print(('^1SCRIPT ERROR: %s^0\n%s'):format(result , Citizen.InvokeNative(`FORMAT_STACK_TRACE` & 0xFFFFFFFF, nil, 0, Citizen.ResultAsString()) or ''))
        end

        return false
    end

    return result, ...
end

local pcall = pcall

---@param name string
---@param bps number
---@param cb function
function lib.callbackLatent.register(name, bps, cb)
    RegisterNetEvent(cbEvent:format(name), function(resource, key, ...)
        TriggerLatentServerEvent(cbEvent:format(resource), bps, key, callbackResponse(pcall(cb, ...)))
    end)
end

return lib.callbackLatent
