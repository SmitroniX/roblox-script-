-- ============================================================
--  MainClient.lua  (StarterPlayerScripts > LocalScript)
--  Builds the full GUI and handles all client-side interactions.
-- ============================================================

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")

local GameConfig        = require(ReplicatedStorage:WaitForChild("GameConfig"))
local Remotes           = ReplicatedStorage:WaitForChild("Remotes")

local eHireWorker    = Remotes:WaitForChild("HireWorker")
local eBuyUpgrade    = Remotes:WaitForChild("BuyUpgrade")
local eRebirth       = Remotes:WaitForChild("Rebirth")
local eChopTree      = Remotes:WaitForChild("ChopTree")
local fGetProfile    = Remotes:WaitForChild("GetProfile")
local eUpdateProfile = Remotes:WaitForChild("UpdateProfile")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

-- ── Current profile cache ─────────────────────────────────────
local profile = {}

-- ── Colour palette ────────────────────────────────────────────
local COLORS = {
    BG        = Color3.fromRGB(18, 18, 24),
    PANEL     = Color3.fromRGB(28, 28, 38),
    ACCENT    = Color3.fromRGB(80, 160, 255),
    ACCENT2   = Color3.fromRGB(100, 220, 100),
    DANGER    = Color3.fromRGB(220, 80, 80),
    TEXT      = Color3.fromRGB(240, 240, 240),
    SUBTEXT   = Color3.fromRGB(160, 160, 180),
    BORDER    = Color3.fromRGB(50, 50, 70),
}

-- ── Utility: create GUI instances ────────────────────────────
local function newInst(class, props)
    local inst = Instance.new(class)
    for k, v in pairs(props) do
        inst[k] = v
    end
    return inst
end

local function corner(parent, radius)
    newInst("UICorner", { CornerRadius = UDim.new(0, radius or 8), Parent = parent })
end

local function stroke(parent, color, thickness)
    newInst("UIStroke", {
        Color     = color or COLORS.BORDER,
        Thickness = thickness or 1,
        Parent    = parent,
    })
end

local function label(parent, props)
    local lbl = newInst("TextLabel", {
        BackgroundTransparency = 1,
        Font                   = Enum.Font.GothamMedium,
        TextColor3             = COLORS.TEXT,
        TextSize               = 14,
        TextXAlignment         = Enum.TextXAlignment.Left,
        Parent                 = parent,
    })
    for k, v in pairs(props) do lbl[k] = v end
    return lbl
end

local function btn(parent, props, callback)
    local b = newInst("TextButton", {
        BackgroundColor3 = COLORS.ACCENT,
        Font             = Enum.Font.GothamBold,
        TextColor3       = COLORS.TEXT,
        TextSize         = 13,
        AutoButtonColor  = false,
        Parent           = parent,
    })
    for k, v in pairs(props) do b[k] = v end
    corner(b, 6)

    b.MouseEnter:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.15), {
            BackgroundColor3 = COLORS.ACCENT2
        }):Play()
    end)
    b.MouseLeave:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.15), {
            BackgroundColor3 = props.BackgroundColor3 or COLORS.ACCENT
        }):Play()
    end)
    if callback then
        b.MouseButton1Click:Connect(callback)
    end
    return b
end

-- ── Build the ScreenGui ───────────────────────────────────────
local ScreenGui = newInst("ScreenGui", {
    Name            = "LumberEmpireUI",
    ResetOnSpawn    = false,
    IgnoreGuiInset  = true,
    Parent          = PlayerGui,
})

-- Main window
local Window = newInst("Frame", {
    Size             = UDim2.fromOffset(440, 520),
    Position         = UDim2.fromScale(0.5, 0.5),
    AnchorPoint      = Vector2.new(0.5, 0.5),
    BackgroundColor3 = COLORS.BG,
    BorderSizePixel  = 0,
    Parent           = ScreenGui,
})
corner(Window, 12)
stroke(Window)

-- Title bar
local TitleBar = newInst("Frame", {
    Size             = UDim2.new(1, 0, 0, 44),
    BackgroundColor3 = COLORS.PANEL,
    BorderSizePixel  = 0,
    Parent           = Window,
})
corner(TitleBar, 12)

local TitleLabel = label(TitleBar, {
    Size     = UDim2.new(1, -60, 1, 0),
    Position = UDim2.fromOffset(14, 0),
    Text     = "🌲 Lumber Empire",
    TextSize = 18,
    Font     = Enum.Font.GothamBold,
})

-- Close button
local CloseBtn = btn(TitleBar, {
    Size             = UDim2.fromOffset(28, 28),
    Position         = UDim2.new(1, -36, 0.5, -14),
    Text             = "✕",
    BackgroundColor3 = COLORS.DANGER,
    TextSize         = 14,
}, function()
    Window.Visible = not Window.Visible
end)

-- Drag support
do
    local dragging, dragStart, startPos
    TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging  = true
            dragStart = input.Position
            startPos  = Window.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            Window.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

-- ── Stats bar ────────────────────────────────────────────────
local StatsBar = newInst("Frame", {
    Size             = UDim2.new(1, -20, 0, 60),
    Position         = UDim2.fromOffset(10, 52),
    BackgroundColor3 = COLORS.PANEL,
    BorderSizePixel  = 0,
    Parent           = Window,
})
corner(StatsBar, 8)
stroke(StatsBar)

newInst("UIListLayout", {
    FillDirection       = Enum.FillDirection.Horizontal,
    HorizontalAlignment = Enum.HorizontalAlignment.Center,
    VerticalAlignment   = Enum.VerticalAlignment.Center,
    Padding             = UDim.new(0, 10),
    Parent              = StatsBar,
})

local statLabels = {}
local function statEntry(icon, key, unit)
    local frame = newInst("Frame", {
        Size             = UDim2.fromOffset(90, 50),
        BackgroundTransparency = 1,
        Parent           = StatsBar,
    })
    label(frame, {
        Size     = UDim2.new(1, 0, 0, 22),
        Position = UDim2.fromOffset(0, 4),
        Text     = icon,
        TextSize = 20,
        TextXAlignment = Enum.TextXAlignment.Center,
    })
    local val = label(frame, {
        Size     = UDim2.new(1, 0, 0, 18),
        Position = UDim2.fromOffset(0, 28),
        Text     = "0 " .. (unit or ""),
        TextSize = 12,
        TextColor3 = COLORS.SUBTEXT,
        TextXAlignment = Enum.TextXAlignment.Center,
    })
    statLabels[key] = val
end

statEntry("💰", "Coins", "coins")
statEntry("🪵", "Logs",  "logs")
statEntry("👷", "Workers", "")
statEntry("🔁", "Rebirths", "×")

-- ── Notification label ───────────────────────────────────────
local NotifLabel = label(Window, {
    Size       = UDim2.new(1, -20, 0, 24),
    Position   = UDim2.fromOffset(10, 118),
    Text       = "",
    TextColor3 = COLORS.ACCENT2,
    TextSize   = 12,
    Font       = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Center,
})

local function notify(msg, color)
    NotifLabel.Text       = msg
    NotifLabel.TextColor3 = color or COLORS.ACCENT2
    task.delay(4, function()
        if NotifLabel.Text == msg then
            NotifLabel.Text = ""
        end
    end)
end

-- ── Tab system ───────────────────────────────────────────────
local TabBar = newInst("Frame", {
    Size             = UDim2.new(1, -20, 0, 36),
    Position         = UDim2.fromOffset(10, 148),
    BackgroundColor3 = COLORS.PANEL,
    BorderSizePixel  = 0,
    Parent           = Window,
})
corner(TabBar, 8)

newInst("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    Parent        = TabBar,
})

local ContentFrame = newInst("ScrollingFrame", {
    Size             = UDim2.new(1, -20, 1, -200),
    Position         = UDim2.fromOffset(10, 192),
    BackgroundTransparency = 1,
    BorderSizePixel  = 0,
    ScrollBarThickness = 4,
    ScrollBarImageColor3 = COLORS.ACCENT,
    CanvasSize       = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    Parent           = Window,
})

newInst("UIPadding", {
    PaddingLeft  = UDim.new(0, 4),
    PaddingRight = UDim.new(0, 4),
    Parent       = ContentFrame,
})

local listLayout = newInst("UIListLayout", {
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding   = UDim.new(0, 8),
    Parent    = ContentFrame,
})

-- Tabs management
local tabs    = {}
local tabBtns = {}
local activeTab = nil

local function setTab(name)
    for n, frame in pairs(tabs) do
        frame.Visible = (n == name)
    end
    for n, b in pairs(tabBtns) do
        b.BackgroundColor3 = (n == name) and COLORS.ACCENT or COLORS.PANEL
        b.TextColor3       = (n == name) and COLORS.TEXT   or COLORS.SUBTEXT
    end
    activeTab = name
end

local function addTab(name, icon)
    local b = newInst("TextButton", {
        Size             = UDim2.new(0.25, 0, 1, 0),
        BackgroundColor3 = COLORS.PANEL,
        Font             = Enum.Font.GothamMedium,
        Text             = icon .. " " .. name,
        TextColor3       = COLORS.SUBTEXT,
        TextSize         = 12,
        BorderSizePixel  = 0,
        Parent           = TabBar,
    })

    local frame = newInst("Frame", {
        Size             = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Visible          = false,
        Parent           = ContentFrame,
    })

    local fl = newInst("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding   = UDim.new(0, 8),
        Parent    = frame,
    })

    tabs[name]    = frame
    tabBtns[name] = b

    b.MouseButton1Click:Connect(function()
        setTab(name)
    end)

    return frame, fl
end

-- ── Tab: Workers ─────────────────────────────────────────────
local workerTab, _ = addTab("Workers", "👷")

local workerInfoLbl = label(workerTab, {
    Size     = UDim2.new(1, 0, 0, 36),
    Text     = "Hire workers to auto-chop trees.\nEach worker costs more than the last.",
    TextSize = 12,
    TextColor3 = COLORS.SUBTEXT,
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Center,
})

local workerCostLbl = label(workerTab, {
    Size       = UDim2.new(1, 0, 0, 24),
    Text       = "Next worker cost: ...",
    TextSize   = 13,
    TextColor3 = COLORS.ACCENT,
    TextXAlignment = Enum.TextXAlignment.Center,
})

btn(workerTab, {
    Size = UDim2.new(1, 0, 0, 38),
    Text = "👷 Hire Worker",
}, function()
    eHireWorker:FireServer()
end)

-- ── Tab: Upgrades ─────────────────────────────────────────────
local upgradeTab, _ = addTab("Upgrades", "⬆️")

local upgradeButtons = {}
for key, cfg in pairs(GameConfig.UPGRADES) do
    local uFrame = newInst("Frame", {
        Size             = UDim2.new(1, 0, 0, 72),
        BackgroundColor3 = COLORS.PANEL,
        BorderSizePixel  = 0,
        Parent           = upgradeTab,
    })
    corner(uFrame, 8)
    stroke(uFrame)

    label(uFrame, {
        Size     = UDim2.new(1, -100, 0, 22),
        Position = UDim2.fromOffset(10, 6),
        Text     = cfg.displayName,
        Font     = Enum.Font.GothamBold,
        TextSize = 14,
    })

    local descLbl = label(uFrame, {
        Size       = UDim2.new(1, -100, 0, 18),
        Position   = UDim2.fromOffset(10, 28),
        Text       = cfg.description,
        TextSize   = 11,
        TextColor3 = COLORS.SUBTEXT,
    })

    local levelLbl = label(uFrame, {
        Size       = UDim2.new(1, -100, 0, 16),
        Position   = UDim2.fromOffset(10, 50),
        Text       = "Level 0 / " .. cfg.maxLevel,
        TextSize   = 11,
        TextColor3 = COLORS.ACCENT2,
    })

    local ubtn = btn(uFrame, {
        Size             = UDim2.fromOffset(90, 50),
        Position         = UDim2.new(1, -100, 0.5, -25),
        Text             = "Buy\n... coins",
        TextSize         = 12,
        BackgroundColor3 = COLORS.ACCENT,
    }, function()
        eBuyUpgrade:FireServer(key)
    end)

    upgradeButtons[key] = { btn = ubtn, levelLbl = levelLbl }
end

-- ── Tab: Rebirth ─────────────────────────────────────────────
local rebirthTab, _ = addTab("Rebirth", "🔁")

label(rebirthTab, {
    Size     = UDim2.new(1, 0, 0, 60),
    Text     = string.format(
        "Rebirth resets your coins, logs, workers and upgrades.\n"..
        "Each rebirth gives +%.0f%% more coins forever.\n"..
        "Cost: %d coins",
        GameConfig.REBIRTH_MULTIPLIER * 100,
        GameConfig.REBIRTH_COST
    ),
    TextSize    = 12,
    TextColor3  = COLORS.SUBTEXT,
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Center,
})

local rebirthMultLbl = label(rebirthTab, {
    Size       = UDim2.new(1, 0, 0, 24),
    Text       = "Current multiplier: 1.00×",
    TextSize   = 14,
    TextColor3 = COLORS.ACCENT2,
    Font       = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Center,
})

btn(rebirthTab, {
    Size             = UDim2.new(1, 0, 0, 44),
    Text             = "🔁 Rebirth",
    BackgroundColor3 = COLORS.DANGER,
}, function()
    eRebirth:FireServer()
end)

-- ── Tab: Info ────────────────────────────────────────────────
local infoTab, _ = addTab("Info", "ℹ️")

label(infoTab, {
    Size     = UDim2.new(1, 0, 0, 200),
    Text     = "🌲 Lumber Empire\n\n"..
               "• Chop trees to earn logs & coins\n"..
               "• Hire workers to auto-chop for you\n"..
               "• Buy upgrades to earn more, faster\n"..
               "• Rebirth for a permanent multiplier\n\n"..
               "Press E near a tree to chop it manually.\n"..
               "Workers auto-chop closest tree.\n\n"..
               "Data is auto-saved every 60 seconds.",
    TextSize    = 13,
    TextColor3  = COLORS.SUBTEXT,
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Center,
})

-- Set initial tab
setTab("Workers")

-- ── Proximity chop (press E near tree) ───────────────────────
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode ~= Enum.KeyCode.E then return end

    local char = LocalPlayer.Character
    if not char or not char.PrimaryPart then return end

    local root   = char.PrimaryPart
    local bestTree, bestDist = nil, 15

    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name == "Tree" then
            local trunk = obj:FindFirstChild("Trunk")
            if trunk then
                local d = (trunk.Position - root.Position).Magnitude
                if d < bestDist then
                    bestTree, bestDist = obj, d
                end
            end
        end
    end

    if bestTree then
        eChopTree:FireServer(bestTree)
    end
end)

-- ── Anti-AFK ─────────────────────────────────────────────────
LocalPlayer.Idled:Connect(function()
    -- Move mouse slightly to prevent idle timeout
    local vu = game:GetService("VirtualUser")
    vu:CaptureController()
    vu:ClickButton2(Vector2.new())
end)

-- ── Profile update handler ────────────────────────────────────
local function onProfileUpdate(newProfile, msg)
    profile = newProfile or profile

    -- Update stat labels
    if statLabels.Coins   then statLabels.Coins.Text   = tostring(profile.Coins   or 0) .. " coins" end
    if statLabels.Logs    then statLabels.Logs.Text    = tostring(profile.Logs    or 0) .. " logs"  end
    if statLabels.Workers then statLabels.Workers.Text = tostring(profile.Workers or 0)              end
    if statLabels.Rebirths then statLabels.Rebirths.Text = tostring(profile.Rebirths or 0) .. "×"   end

    -- Update worker cost label
    local wcount = profile.Workers or 0
    local wcost  = GameConfig.GetWorkerCost(wcount)
    if workerCostLbl then
        workerCostLbl.Text = "Next worker cost: 💰 " .. wcost .. " coins"
    end

    -- Update upgrade buttons
    for key, uData in pairs(upgradeButtons) do
        local level = (profile.Upgrades and profile.Upgrades[key]) or 0
        local cfg   = GameConfig.UPGRADES[key]
        uData.levelLbl.Text = "Level " .. level .. " / " .. cfg.maxLevel
        if level >= cfg.maxLevel then
            uData.btn.Text             = "MAX"
            uData.btn.BackgroundColor3 = COLORS.SUBTEXT
        else
            local cost = GameConfig.GetUpgradeCost(key, level)
            uData.btn.Text             = "Buy\n💰 " .. cost
            uData.btn.BackgroundColor3 = COLORS.ACCENT
        end
    end

    -- Update rebirth multiplier
    local mult = GameConfig.GetRebirthMultiplier(profile.Rebirths or 0)
    rebirthMultLbl.Text = string.format("Current multiplier: %.2f×", mult)

    -- Notification
    if msg and msg ~= "" then
        local color = msg:sub(1,1) == "❌" and COLORS.DANGER or COLORS.ACCENT2
        notify(msg, color)
    end
end

eUpdateProfile.OnClientEvent:Connect(onProfileUpdate)

-- Initial fetch
task.spawn(function()
    task.wait(2)
    local p = fGetProfile:InvokeServer()
    if p then onProfileUpdate(p) end
end)

print("[LumberEmpire] Client loaded ✓")
