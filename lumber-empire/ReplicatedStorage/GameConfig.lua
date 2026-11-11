-- ============================================================
--  GameConfig.lua  (ReplicatedStorage > ModuleScript)
--  Shared constants used by both server and client.
-- ============================================================

local GameConfig = {}

-- ── Economy ─────────────────────────────────────────────────
GameConfig.LOG_VALUE          = 10      -- coins per log sold
GameConfig.SELL_INTERVAL      = 5       -- seconds between auto-sells

-- ── Trees ───────────────────────────────────────────────────
GameConfig.TREE_HEALTH        = 5       -- hits to fell a tree
GameConfig.TREE_RESPAWN_TIME  = 15      -- seconds until a tree regrows
GameConfig.TREE_POSITIONS     = {       -- where trees spawn (Vector3 strings parsed server-side)
    {x =  10, y = 0, z =  10},
    {x = -10, y = 0, z =  10},
    {x =  10, y = 0, z = -10},
    {x = -10, y = 0, z = -10},
    {x =  25, y = 0, z =   0},
    {x = -25, y = 0, z =   0},
    {x =   0, y = 0, z =  25},
    {x =   0, y = 0, z = -25},
}

-- ── Workers ──────────────────────────────────────────────────
GameConfig.MAX_WORKERS        = 10
GameConfig.WORKER_BASE_COST   = 100     -- coins to hire first worker
GameConfig.WORKER_COST_SCALE  = 1.5     -- each worker costs 1.5× more
GameConfig.WORKER_CHOP_RATE   = 1       -- seconds per chop action

-- ── Upgrades ────────────────────────────────────────────────
GameConfig.UPGRADES = {
    ChopSpeed = {
        displayName = "⚡ Chop Speed",
        description = "Workers chop 20% faster per level.",
        baseCost    = 150,
        costScale   = 1.6,
        maxLevel    = 10,
    },
    LogValue = {
        displayName = "💰 Log Value",
        description = "Each log is worth 15% more per level.",
        baseCost    = 200,
        costScale   = 1.7,
        maxLevel    = 10,
    },
    WorkerSpeed = {
        displayName = "🏃 Worker Speed",
        description = "Workers walk 25% faster per level.",
        baseCost    = 120,
        costScale   = 1.5,
        maxLevel    = 10,
    },
    AutoSell = {
        displayName = "🔄 Auto Sell Speed",
        description = "Logs are sold 20% faster per level.",
        baseCost    = 180,
        costScale   = 1.6,
        maxLevel    = 10,
    },
}

-- ── Rebirth ─────────────────────────────────────────────────
GameConfig.REBIRTH_COST           = 10000   -- coins needed to rebirth
GameConfig.REBIRTH_MULTIPLIER     = 0.25    -- +25% coin multiplier per rebirth
GameConfig.MAX_REBIRTHS           = 20

-- ── Helpers ─────────────────────────────────────────────────
function GameConfig.GetUpgradeCost(upgradeKey, currentLevel)
    local cfg = GameConfig.UPGRADES[upgradeKey]
    if not cfg then return math.huge end
    return math.floor(cfg.baseCost * (cfg.costScale ^ currentLevel))
end

function GameConfig.GetWorkerCost(workerCount)
    return math.floor(GameConfig.WORKER_BASE_COST * (GameConfig.WORKER_COST_SCALE ^ workerCount))
end

function GameConfig.GetRebirthMultiplier(rebirths)
    return 1 + (rebirths * GameConfig.REBIRTH_MULTIPLIER)
end

return GameConfig
