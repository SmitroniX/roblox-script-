-- ============================================================
--  MainServer.lua  (ServerScriptService > Script)
--  Entry point: wires up all managers and handles RemoteEvents.
-- ============================================================

local Players            = game:GetService("Players")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")

-- Load modules
local GameConfig   = require(ReplicatedStorage.GameConfig)
local DataManager  = require(script.Parent.DataManager)
local TreeManager  = require(script.Parent.TreeManager)
local WorkerManager = require(script.Parent.WorkerManager)

-- ── Remotes folder ───────────────────────────────────────────
local Remotes = Instance.new("Folder")
Remotes.Name  = "Remotes"
Remotes.Parent = ReplicatedStorage

local function makeEvent(name)
    local e = Instance.new("RemoteEvent")
    e.Name   = name
    e.Parent = Remotes
    return e
end

local function makeFunction(name)
    local f = Instance.new("RemoteFunction")
    f.Name   = name
    f.Parent = Remotes
    return f
end

local eHireWorker    = makeEvent("HireWorker")
local eBuyUpgrade    = makeEvent("BuyUpgrade")
local eRebirth       = makeEvent("Rebirth")
local eChopTree      = makeEvent("ChopTree")
local fGetProfile    = makeFunction("GetProfile")
local eUpdateProfile = makeEvent("UpdateProfile")

-- ── Helpers ──────────────────────────────────────────────────
local function pushProfile(player)
    local profile = DataManager.Get(player)
    if profile then
        eUpdateProfile:FireClient(player, profile)
    end
end

-- ── Initialise trees ─────────────────────────────────────────
TreeManager.Init()

-- ── Player join ──────────────────────────────────────────────
Players.PlayerAdded:Connect(function(player)
    local profile = DataManager.Load(player)
    WorkerManager.Init(player)

    -- Re-spawn saved workers as fresh NPCs
    for _ = 1, profile.Workers do
        task.spawn(function()
            WorkerManager.HireWorker(player, TreeManager, DataManager)
        end)
    end

    -- Push initial data to client once character loads
    player.CharacterAdded:Connect(function()
        task.wait(1)
        pushProfile(player)
    end)
end)

-- ── Player leave ─────────────────────────────────────────────
Players.PlayerRemoving:Connect(function(player)
    WorkerManager.Cleanup(player)
    DataManager.Save(player)
end)

-- ── GetProfile (RemoteFunction) ───────────────────────────────
fGetProfile.OnServerInvoke = function(player)
    return DataManager.Get(player)
end

-- ── HireWorker ───────────────────────────────────────────────
eHireWorker.OnServerEvent:Connect(function(player)
    local ok, result = WorkerManager.HireWorker(player, TreeManager, DataManager)
    if ok then
        pushProfile(player)
    else
        -- Send error back
        eUpdateProfile:FireClient(player, DataManager.Get(player), "❌ " .. result)
    end
end)

-- ── BuyUpgrade ───────────────────────────────────────────────
eBuyUpgrade.OnServerEvent:Connect(function(player, upgradeKey)
    local cfg = GameConfig.UPGRADES[upgradeKey]
    if not cfg then return end

    local profile = DataManager.Get(player)
    if not profile then return end

    local level = profile.Upgrades[upgradeKey] or 0
    if level >= cfg.maxLevel then
        eUpdateProfile:FireClient(player, profile, "❌ Already max level!")
        return
    end

    local cost = GameConfig.GetUpgradeCost(upgradeKey, level)
    if profile.Coins < cost then
        eUpdateProfile:FireClient(player, profile, "❌ Need " .. cost .. " coins")
        return
    end

    profile.Coins                = profile.Coins - cost
    profile.Upgrades[upgradeKey] = level + 1

    -- Update walk speed if WorkerSpeed was upgraded
    if upgradeKey == "WorkerSpeed" then
        -- (Workers will read updated value on next chop cycle)
    end

    pushProfile(player)
end)

-- ── Rebirth ──────────────────────────────────────────────────
eRebirth.OnServerEvent:Connect(function(player)
    local profile = DataManager.Get(player)
    if not profile then return end

    if profile.Rebirths >= GameConfig.MAX_REBIRTHS then
        eUpdateProfile:FireClient(player, profile, "❌ Max rebirths reached!")
        return
    end

    if profile.Coins < GameConfig.REBIRTH_COST then
        eUpdateProfile:FireClient(player, profile,
            "❌ Need " .. GameConfig.REBIRTH_COST .. " coins to rebirth")
        return
    end

    -- Reset stats, keep rebirths counter
    profile.Coins    = 0
    profile.Logs     = 0
    profile.Workers  = 0
    profile.Rebirths = profile.Rebirths + 1
    profile.Upgrades = { ChopSpeed=0, LogValue=0, WorkerSpeed=0, AutoSell=0 }

    -- Remove all current workers
    WorkerManager.Cleanup(player)
    WorkerManager.Init(player)

    pushProfile(player)
end)

-- ── Player chop (manual axe swing) ───────────────────────────
eChopTree.OnServerEvent:Connect(function(player, treeModel)
    -- Validate the model exists and is a real Tree
    if not treeModel or not treeModel:IsA("Model") or treeModel.Name ~= "Tree" then return end

    -- Proximity check: player must be within 15 studs
    local char = player.Character
    if not char or not char.PrimaryPart then return end
    local trunk = treeModel:FindFirstChild("Trunk")
    if not trunk then return end

    local dist = (char.PrimaryPart.Position - trunk.Position).Magnitude
    if dist > 15 then return end

    -- Find this tree in TreeManager
    local trees   = TreeManager.GetAll()
    local entry   = nil
    for _, t in ipairs(trees) do
        if t.model == treeModel then
            entry = t
            break
        end
    end

    if not entry then return end

    local result  = TreeManager.Chop(entry)
    local profile = DataManager.Get(player)
    if result == "fell" and profile then
        local logValue    = GameConfig.LOG_VALUE
        local lvlBonus    = profile.Upgrades.LogValue or 0
        local bonus       = 1 + (lvlBonus * 0.15)
        local rebirthMult = GameConfig.GetRebirthMultiplier(profile.Rebirths or 0)
        local earned      = math.floor(logValue * bonus * rebirthMult)

        profile.Logs  = profile.Logs + 1
        profile.Coins = profile.Coins + earned
        pushProfile(player)
    end
end)

-- ── Auto-push profile every 5 seconds (coins/logs update) ────
task.spawn(function()
    while true do
        task.wait(5)
        for _, player in ipairs(Players:GetPlayers()) do
            pushProfile(player)
        end
    end
end)

print("[LumberEmpire] Server started ✓")
