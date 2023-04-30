local events = {}
local cbEvent = ('__ox_cbl_%s')

RegisterNetEvent(cbEvent:format(cache.resource), function(key, ...)
    local cb = events[key]
    return cb and cb(...)
end)

---@param _ any
---@param event string
---@param playerId number
---@param bps number|nil
---@param cb function|false
---@param ... any
---@return ...
local function triggerClientCallbackLatent(_, event, playerId, bps, cb, ...)
    local key

    repeat
        key = ('%s:%s:%s'):format(event, math.random(0, 100000), playerId)
    until not events[key]

    bps = bps ~= nil and bps or 100000

    TriggerLatentClientEvent(cbEvent:format(event), playerId, bps, cache.resource, key, ...)

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

---@overload fun(event: string, playerId: number, bps: number, cb: function, ...)
lib.callbackLatent = setmetatable({}, {
    __call = triggerClientCallbackLatent
})

---@param event string
---@param playerId number
---@param bps number
--- Sends a latent event to a client and halts the current thread until a response is returned.
function lib.callbackLatent.await(event, playerId, bps, ...)
    return triggerClientCallbackLatent(nil, event, playerId, bps, false, ...)
end

local function callbackResponse(success, result, ...)
    if not success then
        if result then
            return print(('^1SCRIPT ERROR: %s^0\n%s'):format(result, Citizen.InvokeNative(`FORMAT_STACK_TRACE` & 0xFFFFFFFF, nil, 0, Citizen.ResultAsString()) or ''))
        end

        return false
    end

    return result, ...
end

local pcall = pcall

---@param name string
---@param bps number
---@param cb function
--- Registers an event handler and callback function to respond to client requests.
function lib.callbackLatent.register(name, bps, cb)
    RegisterNetEvent(cbEvent:format(name), function(resource, key, ...)
        TriggerLatentClientEvent(cbEvent:format(resource), source, bps, key, callbackResponse(pcall(cb, source, ...)))
    end)
end

return lib.callbackLatent
