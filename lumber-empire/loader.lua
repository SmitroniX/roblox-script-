-- ============================================================
--  LumberEmpire Loader
--  Paste this in Roblox Studio > Command Bar (once, in Studio)
--  or use the loadstring link below.
--
--  loadstring(game:HttpGet("https://raw.githubusercontent.com/SmitroniX/roblox-script-/main/lumber-empire/loader.lua"))()
-- ============================================================

local BASE = "https://raw.githubusercontent.com/SmitroniX/roblox-script-/main/lumber-empire/"

local HttpService        = game:GetService("HttpService")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayerScripts = game:GetService("StarterPlayerScripts")

-- Files to fetch and where to place them
local files = {
    {
        url      = BASE .. "ReplicatedStorage/GameConfig.lua",
        parent   = ReplicatedStorage,
        name     = "GameConfig",
        class    = "ModuleScript",
    },
    {
        url      = BASE .. "ServerScriptService/DataManager.lua",
        parent   = ServerScriptService,
        name     = "DataManager",
        class    = "ModuleScript",
    },
    {
        url      = BASE .. "ServerScriptService/TreeManager.lua",
        parent   = ServerScriptService,
        name     = "TreeManager",
        class    = "ModuleScript",
    },
    {
        url      = BASE .. "ServerScriptService/WorkerManager.lua",
        parent   = ServerScriptService,
        name     = "WorkerManager",
        class    = "ModuleScript",
    },
    {
        url      = BASE .. "ServerScriptService/MainServer.lua",
        parent   = ServerScriptService,
        name     = "MainServer",
        class    = "Script",
    },
    {
        url      = BASE .. "StarterPlayerScripts/MainClient.lua",
        parent   = StarterPlayerScripts,
        name     = "MainClient",
        class    = "LocalScript",
    },
}

print("[LumberEmpire Loader] Installing scripts...")

for _, f in ipairs(files) do
    -- Remove old version if exists
    local existing = f.parent:FindFirstChild(f.name)
    if existing then existing:Destroy() end

    -- Fetch source
    local ok, source = pcall(function()
        return game:HttpGet(f.url)
    end)

    if not ok or not source or source == "" then
        warn("[LumberEmpire Loader] Failed to fetch: " .. f.name)
        continue
    end

    -- Create instance
    local inst = Instance.new(f.class)
    inst.Name   = f.name
    inst.Source = source
    inst.Parent = f.parent

    print("[LumberEmpire Loader] ✓ Installed: " .. f.name .. " → " .. f.parent.Name)
end

print("[LumberEmpire Loader] ✅ All scripts installed! Press Play to run the game.")
