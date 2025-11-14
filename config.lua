Config = {}

-- Discord Webhook
Config.Webhook = "YOUR_WEBHOOK"

-- Rapor gönderme aralığı (5 dakika)
-- Test için 10000 yapabilirsin, prod için 300000 kullan
Config.Interval = 300000 -- 300.000 ms (5 dakika)

-- Yük seviyeleri (tick max limitleri – baseline Δ için)
Config.Levels = {
    Warn = 3.0,   -- 3 ms üstü → sarı adaya girer
    Crit = 6.0,   -- 6 ms üstü → kırmızı adayı zorlar
}

-- Script heartbeat timeout
Config.HeartbeatTimeout = 30      -- 30 sn sonra "şüpheli"

-- Hızlı baseline + hızlı sağlık kontrolü (≈ 5 sn)
Config.MinUptime       = 3        -- 5 sn dolmadan status hesaplama
Config.MinSamples      = 5        -- min 5 örnek yeter
Config.Warmup          = 2        -- ilk 2 sn warm-up; sadece baseline
Config.BaselineSamples = 5        -- baseline için 8 örnek

-- Spike analizi
Config.Spike = {
    ThresholdMs = 50.0,  -- 50ms üstü spike say
    WarnRate    = 0.10,  -- örneklerin %10'u spike ise "warn adayı"
    CritRate    = 0.20,  -- örneklerin %20'si spike ise "crit adayı"
}

-- Jitter (tickMax vs tickAvg)
Config.Jitter = {
    Warn = 0.20,   -- %20 üzeri jitter → warn adayı
    Crit = 0.40,   -- %40 üzeri jitter → crit adayı
}

-- Trend tabanlı sağlık skoru
Config.Trend = {
    Warn = 2,   -- en az 2 kötü rapor üst üste → WARN
    Crit = 4,   -- en az 4 kötü rapor üst üste → CRIT
    Max  = 6,   -- health score üst limiti
}

-- Konsol debug modu
Config.Debug = false
