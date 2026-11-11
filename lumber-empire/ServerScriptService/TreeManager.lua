-- ============================================================
--  TreeManager.lua  (ServerScriptService > ModuleScript)
--  Spawns trees, handles chopping hits, and respawning.
-- ============================================================

local GameConfig     = require(game.ReplicatedStorage.GameConfig)
local RunService     = game:GetService("RunService")

local TreeManager    = {}
local activeTrees    = {}   -- { model, health, position, alive }

-- ── Build a tree model ───────────────────────────────────────
local function buildTree(pos)
    local model  = Instance.new("Model")
    model.Name   = "Tree"

    local trunk  = Instance.new("Part")
    trunk.Name   = "Trunk"
    trunk.Size   = Vector3.new(1.5, 8, 1.5)
    trunk.BrickColor = BrickColor.new("Reddish brown")
    trunk.Anchored   = true
    trunk.Position   = Vector3.new(pos.x, pos.y + 4, pos.z)
    trunk.Parent     = model

    local canopy = Instance.new("Part")
    canopy.Name  = "Canopy"
    canopy.Shape = Enum.PartType.Ball
    canopy.Size  = Vector3.new(7, 7, 7)
    canopy.BrickColor = BrickColor.new("Bright green")
    canopy.Anchored   = true
    canopy.Position   = Vector3.new(pos.x, pos.y + 10, pos.z)
    canopy.Parent     = model

    -- Invisible hitbox for chopping
    local hitbox = Instance.new("Part")
    hitbox.Name          = "Hitbox"
    hitbox.Size          = Vector3.new(3, 12, 3)
    hitbox.Anchored      = true
    hitbox.Transparency  = 1
    hitbox.CanCollide    = false
    hitbox.Position      = Vector3.new(pos.x, pos.y + 6, pos.z)
    hitbox.Parent        = model

    model.PrimaryPart = trunk
    model.Parent      = workspace

    return model
end

-- ── Spawn all trees ──────────────────────────────────────────
function TreeManager.Init()
    for _, pos in ipairs(GameConfig.TREE_POSITIONS) do
        local model = buildTree(pos)
        table.insert(activeTrees, {
            model    = model,
            health   = GameConfig.TREE_HEALTH,
            position = pos,
            alive    = true,
        })
    end
end

-- ── Get nearest living tree to a position ───────────────────
function TreeManager.GetNearest(origin)
    local best, bestDist = nil, math.huge
    for _, t in ipairs(activeTrees) do
        if t.alive then
            local d = (Vector3.new(t.position.x, t.position.y, t.position.z) - origin).Magnitude
            if d < bestDist then
                best, bestDist = t, d
            end
        end
    end
    return best
end

-- ── Chop a tree (called by worker or player) ─────────────────
-- Returns: "hit", "fell", or "dead"
function TreeManager.Chop(treeEntry)
    if not treeEntry or not treeEntry.alive then return "dead" end

    treeEntry.health = treeEntry.health - 1

    if treeEntry.health <= 0 then
        treeEntry.alive = false
        treeEntry.model:Destroy()

        -- Respawn after delay
        task.delay(GameConfig.TREE_RESPAWN_TIME, function()
            local pos   = treeEntry.position
            treeEntry.model   = buildTree(pos)
            treeEntry.health  = GameConfig.TREE_HEALTH
            treeEntry.alive   = true
        end)

        return "fell"
    end

    return "hit"
end

-- ── List all living trees ────────────────────────────────────
function TreeManager.GetAll()
    return activeTrees
end

return TreeManager
