-- =======================================
-- MOJO PERFORMONOTOR - Injected LUA (Stabil Edition)
-- =======================================

local RES = GetCurrentResourceName()

-- Script-local state
local state = {
    lastEvent   = "idle",
    tickSamples = 0,
    tickTotal   = 0.0,
    tickMax     = 0.0,
    nuiHits     = 0,
    errorCount  = 0,
}

print(("[MOJO PERF] Inject Loaded → %s"):format(RES))

-- =======================================
-- SEND FUNCTION
-- =======================================
local function send(eventName, load)
    local S = state

    -- Script load
    load = tonumber(load or 0.0) or 0.0

    -- Load fallback (tickAvg) – sadece buradan kullanıyoruz
    if load == 0 then
        load = (S.tickSamples > 0) and (S.tickTotal / S.tickSamples) or 1.0
    end

    -- Entity metrics (diagnostic)
    local pedCount = #GetGamePool("CPed")
    local vehCount = #GetGamePool("CVehicle")
    local objCount = #GetGamePool("CObject")

    TriggerServerEvent("mojo_performonitor:injectReport", {
        res = RES,
        event = eventName or S.lastEvent or "heartbeat",
        load = load,
        player = GetPlayerServerId(PlayerId()),
        metrics = {
            entities  = {
                peds     = pedCount,
                vehicles = vehCount,
                objects  = objCount
            },
            nui = {
                hits = S.nuiHits
            },
            errors = S.errorCount
        }
    })

    -- Reset cycle
    S.tickSamples = 0
    S.tickTotal   = 0.0
    S.tickMax     = 0.0
    S.nuiHits     = 0
    -- errorCount reset edilmez
end

-- =======================================
-- Resource events
-- =======================================
AddEventHandler("onClientResourceStart", function(r)
    if r == RES then
        state.lastEvent = "start"
        send("start", 0.0)
    end
end)

AddEventHandler("onClientResourceStop", function(r)
    if r == RES then
        state.lastEvent = "stop"
        send("stop", 0.0)
    end
end)

-- =======================================
-- TICK PROFILER (Stabil)
-- =======================================
CreateThread(function()
    Wait(500) -- Race condition fix

    while true do
        local start = GetGameTimer()
        Wait(1) -- Wait(0) starvation fix
        local diff = GetGameTimer() - start

        local S = state
        S.tickSamples = S.tickSamples + 1
        S.tickTotal   = S.tickTotal + diff
        if diff > S.tickMax then
            S.tickMax = diff
        end

        Wait(150) -- Stabil örnekleme
    end
end)

-- =======================================
-- HEARTBEAT (10s)
-- =======================================
CreateThread(function()
    Wait(1000)

    while true do
        Wait(10000)
        state.lastEvent = "heartbeat"
        send("heartbeat", 0.0)
    end
end)

-- =======================================
-- API
-- =======================================
exports("MOJO_USE", function(section, load)
    state.lastEvent = section or "custom"
    send(state.lastEvent, load or 0.0)
end)

exports("MOJO_NUI_HIT", function()
    state.nuiHits = state.nuiHits + 1
end)

exports("MOJO_ERROR", function()
    state.errorCount = state.errorCount + 1
end)
