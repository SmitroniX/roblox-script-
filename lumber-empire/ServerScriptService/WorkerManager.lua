-- ============================================================
--  WorkerManager.lua  (ServerScriptService > ModuleScript)
--  Manages NPC workers: spawning, AI loop, upgrading.
-- ============================================================

local GameConfig  = require(game.ReplicatedStorage.GameConfig)
local RunService  = game:GetService("RunService")

local WorkerManager = {}

-- Table keyed by player UserId → list of worker data
local playerWorkers = {}

-- ── Build a worker NPC model ─────────────────────────────────
local function buildWorkerModel(spawnPos)
    local model = Instance.new("Model")
    model.Name  = "Worker"

    local torso = Instance.new("Part")
    torso.Name  = "HumanoidRootPart"
    torso.Size  = Vector3.new(2, 2, 1)
    torso.BrickColor = BrickColor.new("Bright blue")
    torso.Anchored   = false
    torso.Position   = spawnPos + Vector3.new(0, 1, 0)
    torso.Parent     = model

    local head = Instance.new("Part")
    head.Name   = "Head"
    head.Size   = Vector3.new(1.2, 1.2, 1.2)
    head.BrickColor = BrickColor.new("Nougat")
    head.Anchored   = false
    head.Position   = spawnPos + Vector3.new(0, 2.6, 0)
    head.Parent     = model

    local weld  = Instance.new("WeldConstraint")
    weld.Part0  = torso
    weld.Part1  = head
    weld.Parent = torso

    local hum = Instance.new("Humanoid")
    hum.Parent = model

    model.PrimaryPart = torso
    model.Parent      = workspace

    return model, hum
end

-- ── Worker AI coroutine ──────────────────────────────────────
local function runWorker(workerData, treeManager, dataManager, player)
    local hum   = workerData.humanoid
    local model = workerData.model

    while workerData.active and model.Parent do
        -- Grab upgrade-adjusted chop rate
        local profile   = dataManager.Get(player)
        local chopLevel = profile and profile.Upgrades.ChopSpeed or 0
        local speedMult = 1 - (chopLevel * 0.20)   -- 20% faster per level, min ~20%
        speedMult       = math.max(speedMult, 0.2)

        -- Find nearest tree
        local root  = model.PrimaryPart
        if not root then break end

        local tree  = treeManager.GetNearest(root.Position)
        if tree then
            -- Walk toward tree
            local target = Vector3.new(tree.position.x, tree.position.y + 1, tree.position.z)
            hum:MoveTo(target)

            -- Wait until arrived or timeout
            local arrived = hum.MoveToFinished:Wait()

            if arrived then
                -- Chop
                local result = treeManager.Chop(tree)

                if result == "fell" then
                    -- Award logs & coins
                    if profile then
                        local logValue = GameConfig.LOG_VALUE
                        local lvlBonus = profile.Upgrades.LogValue or 0
                        local bonus    = 1 + (lvlBonus * 0.15)
                        local rebirthMult = GameConfig.GetRebirthMultiplier(profile.Rebirths or 0)
                        local earned   = math.floor(logValue * bonus * rebirthMult)

                        profile.Logs  = profile.Logs + 1
                        profile.Coins = profile.Coins + earned
                    end
                end
            end
        end

        task.wait(GameConfig.WORKER_CHOP_RATE * speedMult)
    end

    -- Clean up model when done
    if model.Parent then model:Destroy() end
end

-- ── Public API ───────────────────────────────────────────────
function WorkerManager.Init(player)
    playerWorkers[player.UserId] = {}
end

function WorkerManager.HireWorker(player, treeManager, dataManager)
    local workers = playerWorkers[player.UserId]
    if not workers then return false, "Not initialised" end

    local profile = dataManager.Get(player)
    if not profile then return false, "No profile" end

    local count = #workers
    if count >= GameConfig.MAX_WORKERS then
        return false, "Max workers reached (" .. GameConfig.MAX_WORKERS .. ")"
    end

    local cost = GameConfig.GetWorkerCost(count)
    if profile.Coins < cost then
        return false, "Need " .. cost .. " coins (have " .. profile.Coins .. ")"
    end

    -- Deduct cost
    profile.Coins   = profile.Coins - cost
    profile.Workers = count + 1

    -- Spawn NPC near the plot origin
    local spawnPos = Vector3.new(0, 0, 0)
    if player.Character and player.Character.PrimaryPart then
        spawnPos = player.Character.PrimaryPart.Position + Vector3.new(math.random(-5,5), 0, math.random(-5,5))
    end

    local model, hum = buildWorkerModel(spawnPos)

    local workerData = {
        model     = model,
        humanoid  = hum,
        active    = true,
    }

    table.insert(workers, workerData)

    -- Adjust speed based on upgrade
    local speedLevel = profile.Upgrades.WorkerSpeed or 0
    hum.WalkSpeed    = 16 * (1 + speedLevel * 0.25)

    -- Start AI loop
    task.spawn(runWorker, workerData, treeManager, dataManager, player)

    return true, cost
end

function WorkerManager.GetCount(player)
    local workers = playerWorkers[player.UserId]
    return workers and #workers or 0
end

function WorkerManager.Cleanup(player)
    local workers = playerWorkers[player.UserId]
    if workers then
        for _, w in ipairs(workers) do
            w.active = false
        end
    end
    playerWorkers[player.UserId] = nil
end

return WorkerManager
