-- =========================================================
--  MOJO PERFORMONITOR – ADVANCED SERVER TELEMETRY (A+B+TREND)
-- =========================================================

local Stats = {}

local MIN_SAMPLES      = Config.MinSamples       or 20
local WARMUP_TIME      = Config.Warmup           or 30
local MIN_UPTIME       = Config.MinUptime        or 60
local SPIKE_THRESHOLD  = (Config.Spike and Config.Spike.ThresholdMs) or 50.0

print("^2[MOJO PERF] server_bridge loaded (A+B+TREND Mode)^0")

-- =========================================================
--  RESOURCE STATE FACTORY
-- =========================================================
local function newStats()
    local now = os.time()
    return {
        baseline       = {},
        baselineDone   = false,
        baseAvg        = 0,
        baseMax        = 0,
        samples        = {},
        spikes         = 0,
        lastEvent      = "none",
        players        = {},
        lastSeen       = now,
        startedAt      = now,
        healthScore    = 0,
        lastMetrics    = nil,
    }
end

-- =========================================================
--  ORTAK BASELINE TOPLAMA FONKSİYONU
-- =========================================================
local function collectBaseline(S, load, name)
    if S.baselineDone then return end
    if load <= 0 or load >= SPIKE_THRESHOLD then return end

    table.insert(S.baseline, load)

    local needed = Config.BaselineSamples or 30
    if #S.baseline >= needed then
        table.sort(S.baseline)
        local mid = math.floor(#S.baseline / 2)
        S.baseAvg = (S.baseline[mid] + S.baseline[#S.baseline]) / 2
        S.baseMax = S.baseline[#S.baseline]
        S.baselineDone = true

        print(string.format("[MOJO PERF] Baseline completed for %s (avg %.2f ms, max %.2f ms)", name, S.baseAvg, S.baseMax))
    end
end

-- =========================================================
--  RAPOR TOPLAMA
-- =========================================================
local function handleReport(data, src)
    if type(data) ~= "table" then return end

    local name = tostring(data.resource or data.res or "unknown")
    if name == "unknown" then return end

    if not Stats[name] then
        Stats[name] = newStats()
    end

    local S = Stats[name]
    local load = tonumber(data.load or 0) or 0.0
    local metrics = (type(data.metrics) == "table") and data.metrics or nil

    S.lastSeen  = os.time()
    S.lastEvent = data.event or data.lastEvent or "none"

    if src then
        S.players[src] = true
    elseif data.player then
        S.players[data.player] = true
    end

    if metrics then
        S.lastMetrics = metrics
    end

    local uptime = os.time() - S.startedAt

    -- 1) HER ZAMAN baseline toplamaya devam et (sadece warmup'ta değil)
    collectBaseline(S, load, name)

    -- 2) WARMUP süresinde sadece baseline topluyoruz, status yok
    if uptime < WARMUP_TIME then
        if Config.Debug then
            print(("[MOJO PERF] Warmup phase for %s (uptime=%ds, baselineSamples=%d)")
                :format(name, uptime, #S.baseline))
        end
        return
    end

    -- 3) NORMAL SAMPLE
    if load > 0 then
        table.insert(S.samples, load)
        if load >= SPIKE_THRESHOLD then
            S.spikes = S.spikes + 1
            if Config.Debug then
                print(("[MOJO PERF] Spike registered (%.2f ms) for %s"):format(load, name))
            end
        end
    end
end

RegisterNetEvent("mojo_performonitor:serverReport", function(data)
    handleReport(data, source)
end)

RegisterNetEvent("mojo_performonitor:injectReport", function(data)
    handleReport(data, source)
end)

-- =========================================================
--  RAPOR THREAD
-- =========================================================
CreateThread(function()
    while true do
        Wait(Config.Interval)
        generateReport()
    end
end)

-- =========================================================
--  RAPOR OLUŞTURMA
-- =========================================================
function generateReport()
    local fields = {}
    local worst = 0
    local now = os.time()

    for name, S in pairs(Stats) do
        local uptime = now - S.startedAt

        if not S.baselineDone or #S.samples < MIN_SAMPLES or uptime < MIN_UPTIME then
            if Config.Debug then
                print(("[MOJO PERF] Skipping %s (baseline=%s, samples=%d, uptime=%ds)")
                    :format(name, tostring(S.baselineDone), #S.samples, uptime))
            end
            goto continue
        end

        -- ORTALAMALAR
        local sum, sumSq = 0.0, 0.0
        for _, v in ipairs(S.samples) do
            sum = sum + v
            sumSq = sumSq + (v * v)
        end

        local n = #S.samples
        local avg = sum / n
        local variance = (sumSq / n) - (avg * avg)
        if variance < 0 then variance = 0 end
        local stdDev = math.sqrt(variance)

        local baseAvg   = S.baseAvg > 0 and S.baseAvg or avg
        local loadDiff  = avg - baseAvg
        local spikeCount = S.spikes or 0
        local spikeRate  = spikeCount / n

        local offlineSeconds = now - S.lastSeen
        local offline = offlineSeconds > (Config.HeartbeatTimeout * 2)

        -- TREND
        local isCrit = false
        local isWarn = false

        if loadDiff >= Config.Levels.Crit then
            isCrit = true
        elseif loadDiff >= Config.Levels.Warn then
            isWarn = true
        end

        if spikeRate >= (Config.Spike.CritRate or 0.20) then
            isCrit = true
        elseif spikeRate >= (Config.Spike.WarnRate or 0.10) then
            isWarn = true
        end

        -- HEALTH TREND
        S.healthScore = S.healthScore or 0
        if offline or isCrit or isWarn then
            S.healthScore = math.min(S.healthScore + 1, Config.Trend.Max)
        else
            S.healthScore = math.max(S.healthScore - 1, 0)
        end

        local status, level
        if offline then
            status = "🟥 Offline / Heartbeat Lost"
            level = 2
        elseif isCrit and S.healthScore >= Config.Trend.Crit then
            status = "🟥 Critical Load"
            level = 2
        elseif (isCrit or isWarn) and S.healthScore >= Config.Trend.Warn then
            status = "🟨 Medium Load"
            level = 1
        else
            status = "🟢 Stable"
            level = 0
        end

        worst = math.max(worst, level)

        local nuiHits  = 0
        local errCount = 0

        if S.lastMetrics then
            if S.lastMetrics.nui then
                nuiHits = S.lastMetrics.nui.hits or 0
            end
            errCount = S.lastMetrics.errors or 0
        end

        local block =
            "```" .. "\n" ..
            string.format(
                "Status: %s (health %d)\nCPU: avg %.2f ms (Δ%.2f ms, σ=%.2f)\nBaseline: %.2f ms\nSpikes: %d (%.1f%%%%)\nNUI Hits: %d • Errors: %d\nLast Event: %s\nLast Seen: %s",
                status, S.healthScore,
                avg, loadDiff, stdDev,
                baseAvg,
                spikeCount, spikeRate * 100.0,
                nuiHits, errCount,
                S.lastEvent,
                os.date("%Y-%m-%d %H:%M:%S")
            )
            .. "\n```"

        table.insert(fields, { name = name, value = block })

        -- Bu periyot için temizle
        S.samples = {}
        S.spikes  = 0

        ::continue::
    end

    if #fields == 0 then return end

    local color = 0x2ecc71
    if worst == 1 then color = 0xf1c40f end
    if worst == 2 then color = 0xe74c3c end

    local embed = {
        title = "⚡ MOJO Performonitor – Advanced Telemetry (A+B+TREND)",
        description = "Gerçekçi health scoring • Trend bazlı load analizi • Deep inject metrikleri",
        color = color,
        fields = fields,
        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
    }

    PerformHttpRequest(
        Config.Webhook,
        function() end,
        "POST",
        json.encode({ embeds = { embed } }),
        { ["Content-Type"] = "application/json" }
    )
end
