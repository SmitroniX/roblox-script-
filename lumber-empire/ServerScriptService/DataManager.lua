-- ============================================================
--  DataManager.lua  (ServerScriptService > ModuleScript)
--  Handles DataStore save / load with auto-retry.
-- ============================================================

local DataStoreService = game:GetService("DataStoreService")
local Players          = game:GetService("Players")

local DataManager = {}
local store       = DataStoreService:GetDataStore("LumberEmpire_v1")

-- ── Default profile ──────────────────────────────────────────
local function defaultProfile()
    return {
        Coins     = 0,
        Logs      = 0,
        Workers   = 0,
        Rebirths  = 0,
        Upgrades  = {
            ChopSpeed   = 0,
            LogValue    = 0,
            WorkerSpeed = 0,
            AutoSell    = 0,
        },
    }
end

-- In-memory cache so we don't hammer the DataStore
local cache = {}

-- ── Load ─────────────────────────────────────────────────────
function DataManager.Load(player)
    local key   = "player_" .. player.UserId
    local data, success

    for attempt = 1, 3 do
        success, data = pcall(function()
            return store:GetAsync(key)
        end)
        if success then break end
        task.wait(1)
    end

    if not success then
        warn("[DataManager] Failed to load data for " .. player.Name)
        data = nil
    end

    -- Merge saved data onto default to handle new keys gracefully
    local profile = defaultProfile()
    if type(data) == "table" then
        for k, v in pairs(data) do
            if type(v) == "table" then
                for sk, sv in pairs(v) do
                    if profile[k] and type(profile[k]) == "table" then
                        profile[k][sk] = sv
                    end
                end
            else
                profile[k] = v
            end
        end
    end

    cache[player.UserId] = profile
    return profile
end

-- ── Save ─────────────────────────────────────────────────────
function DataManager.Save(player)
    local profile = cache[player.UserId]
    if not profile then return end

    local key = "player_" .. player.UserId
    for attempt = 1, 3 do
        local ok, err = pcall(function()
            store:SetAsync(key, profile)
        end)
        if ok then return end
        warn("[DataManager] Save attempt " .. attempt .. " failed: " .. tostring(err))
        task.wait(1)
    end
end

-- ── Get / Set helpers ────────────────────────────────────────
function DataManager.Get(player)
    return cache[player.UserId]
end

function DataManager.Set(player, key, value)
    local profile = cache[player.UserId]
    if profile then profile[key] = value end
end

-- Auto-save every 60 seconds
task.spawn(function()
    while true do
        task.wait(60)
        for _, player in ipairs(Players:GetPlayers()) do
            DataManager.Save(player)
        end
    end
end)

-- Save on leave
Players.PlayerRemoving:Connect(function(player)
    DataManager.Save(player)
    cache[player.UserId] = nil
end)

-- Save on server close
game:BindToClose(function()
    for _, player in ipairs(Players:GetPlayers()) do
        DataManager.Save(player)
    end
end)

return DataManager
