-- ============================================================
--  LumberEmpire Executor Script v2
--  Compatible with: Synapse X, KRNL, Fluxus, Delta, Comet etc.
-- ============================================================

-- ── Services ─────────────────────────────────────────────────
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local VirtualUser       = game:GetService("VirtualUser")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui           = game:GetService("CoreGui")

local LP = Players.LocalPlayer

-- ── Safe GUI parent (works in all executors) ──────────────────
local GuiParent = (typeof(gethui) == "function" and gethui())
    or (pcall(function() return CoreGui end) and CoreGui)
    or LP:WaitForChild("PlayerGui")

-- ── Character helpers ─────────────────────────────────────────
local function getChar()   return LP.Character end
local function getRoot()
    local c = getChar()
    return c and (c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("UpperTorso") or c:FindFirstChild("Torso"))
end
local function getHum()
    local c = getChar()
    return c and c:FindFirstChildOfClass("Humanoid")
end

LP.CharacterAdded:Connect(function() end) -- keep alive

-- ── Settings ─────────────────────────────────────────────────
local S = {
    AutoChop        = false,
    AutoRebirth     = false,
    AutoHireWorker  = false,
    AutoUpgrade     = false,
    WalkSpeed       = false,
    Noclip          = false,
    AntiAFK         = true,
    InstantPrompt   = false,
    WalkSpeedAmt    = 25,
    ChopDelay       = 0.5,
}

-- ── Colours ──────────────────────────────────────────────────
local C = {
    BG     = Color3.fromRGB(14, 14, 20),
    PANEL  = Color3.fromRGB(24, 24, 34),
    ACCENT = Color3.fromRGB(80, 160, 255),
    GREEN  = Color3.fromRGB(80, 220, 110),
    RED    = Color3.fromRGB(220, 70, 70),
    TEXT   = Color3.fromRGB(240, 240, 240),
    SUB    = Color3.fromRGB(150, 150, 170),
    BORDER = Color3.fromRGB(50, 50, 72),
}

-- ── Instance helper ──────────────────────────────────────────
local function N(cls, props)
    local ok, inst = pcall(Instance.new, cls)
    if not ok then return nil end
    for k,v in pairs(props or {}) do
        pcall(function() inst[k] = v end)
    end
    return inst
end
local function corner(p, r)
    local uc = N("UICorner",{CornerRadius=UDim.new(0,r or 8)})
    if uc then uc.Parent = p end
end
local function stroke(p, col, t)
    local us = N("UIStroke",{Color=col or C.BORDER, Thickness=t or 1})
    if us then us.Parent = p end
end

-- ── Destroy old version ──────────────────────────────────────
local old = GuiParent:FindFirstChild("_LETools")
if old then old:Destroy() end
task.wait(0.1)

-- ══════════════════════════════════════════════════════════════
-- ── BUILD GUI ────────────────────────────────────────────────
-- ══════════════════════════════════════════════════════════════
local SG = N("ScreenGui",{
    Name           = "_LETools",
    ResetOnSpawn   = false,
    IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    Parent         = GuiParent,
})

-- Main window
local Win = N("Frame",{
    Name             = "Window",
    Size             = UDim2.fromOffset(390, 470),
    Position         = UDim2.fromOffset(80, 80),
    BackgroundColor3 = C.BG,
    BorderSizePixel  = 0,
    Parent           = SG,
})
corner(Win, 10)
stroke(Win)

-- Title bar
local TBar = N("Frame",{
    Size             = UDim2.new(1, 0, 0, 42),
    BackgroundColor3 = C.PANEL,
    BorderSizePixel  = 0,
    Parent           = Win,
})
corner(TBar, 10)

N("TextLabel",{
    Size               = UDim2.new(1, -90, 1, 0),
    Position           = UDim2.fromOffset(14, 0),
    BackgroundTransparency = 1,
    Font               = Enum.Font.GothamBold,
    Text               = "🌲 Lumber Empire Tools",
    TextColor3         = C.TEXT,
    TextSize           = 15,
    TextXAlignment     = Enum.TextXAlignment.Left,
    Parent             = TBar,
})

-- Min button
local function mkBtn(parent, props, cb)
    local b = N("TextButton", {
        Font            = Enum.Font.GothamBold,
        TextColor3      = C.TEXT,
        AutoButtonColor = false,
        BorderSizePixel = 0,
    })
    for k,v in pairs(props) do pcall(function() b[k]=v end) end
    b.Parent = parent
    corner(b, 6)
    b.MouseEnter:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.15), {BackgroundColor3=C.GREEN}):Play()
    end)
    b.MouseLeave:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.15), {BackgroundColor3=props.BackgroundColor3 or C.ACCENT}):Play()
    end)
    if cb then b.MouseButton1Click:Connect(cb) end
    return b
end

local minimised = false
local MinBtn = mkBtn(TBar, {
    Size             = UDim2.fromOffset(28, 28),
    Position         = UDim2.new(1, -34, 0.5, -14),
    BackgroundColor3 = Color3.fromRGB(50, 50, 80),
    Text             = "—",
    TextSize         = 14,
}, function()
    minimised = not minimised
    local body = Win:FindFirstChild("Body")
    if body then body.Visible = not minimised end
    Win.Size = minimised and UDim2.fromOffset(390, 42) or UDim2.fromOffset(390, 470)
    MinBtn.Text = minimised and "+" or "—"
end)

-- Body frame (everything below titlebar)
local Body = N("Frame",{
    Name             = "Body",
    Size             = UDim2.new(1, 0, 1, -42),
    Position         = UDim2.fromOffset(0, 42),
    BackgroundTransparency = 1,
    Parent           = Win,
})

-- Scroll
local Scroll = N("ScrollingFrame",{
    Size                = UDim2.new(1, -12, 1, -8),
    Position            = UDim2.fromOffset(6, 4),
    BackgroundTransparency = 1,
    BorderSizePixel     = 0,
    ScrollBarThickness  = 4,
    ScrollBarImageColor3 = C.ACCENT,
    CanvasSize          = UDim2.new(0,0,0,0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    Parent              = Body,
})
N("UIListLayout",{
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding   = UDim.new(0, 6),
    Parent    = Scroll,
})
N("UIPadding",{
    PaddingTop   = UDim.new(0,4),
    PaddingLeft  = UDim.new(0,2),
    PaddingRight = UDim.new(0,4),
    Parent       = Scroll,
})

-- ── Drag ────────────────────────────────────────────────────
do
    local drag, ds, sp
    TBar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            drag, ds, sp = true, i.Position, Win.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if drag and i.UserInputType == Enum.UserInputType.MouseMovement then
            local d = i.Position - ds
            Win.Position = UDim2.new(
                sp.X.Scale, sp.X.Offset + d.X,
                sp.Y.Scale, sp.Y.Offset + d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end
    end)
end

-- ── Notify ──────────────────────────────────────────────────
local NotifLbl = N("TextLabel",{
    Size               = UDim2.new(1, 0, 0, 24),
    BackgroundTransparency = 1,
    Font               = Enum.Font.Gotham,
    Text               = "✅ Script loaded!",
    TextColor3         = C.GREEN,
    TextSize           = 12,
    TextXAlignment     = Enum.TextXAlignment.Center,
    Parent             = Scroll,
})
local function notify(msg, col)
    NotifLbl.Text      = msg
    NotifLbl.TextColor3 = col or C.GREEN
    task.delay(3.5, function()
        if NotifLbl.Text == msg then NotifLbl.Text = "" end
    end)
end

-- ── Section header ───────────────────────────────────────────
local function section(title)
    N("TextLabel",{
        Size               = UDim2.new(1, 0, 0, 22),
        BackgroundColor3   = C.PANEL,
        Font               = Enum.Font.GothamBold,
        Text               = "  " .. title,
        TextColor3         = C.ACCENT,
        TextSize           = 12,
        TextXAlignment     = Enum.TextXAlignment.Left,
        Parent             = Scroll,
    })
end

-- ── Toggle ──────────────────────────────────────────────────
local function toggle(lbl, key, cb)
    local row = N("Frame",{
        Size             = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = C.PANEL,
        BorderSizePixel  = 0,
        Parent           = Scroll,
    })
    corner(row, 6) stroke(row)

    N("TextLabel",{
        Size               = UDim2.new(1, -58, 1, 0),
        Position           = UDim2.fromOffset(10, 0),
        BackgroundTransparency = 1,
        Font               = Enum.Font.GothamMedium,
        Text               = lbl,
        TextColor3         = C.TEXT,
        TextSize           = 13,
        TextXAlignment     = Enum.TextXAlignment.Left,
        Parent             = row,
    })

    local pill = N("Frame",{
        Size             = UDim2.fromOffset(44, 22),
        Position         = UDim2.new(1, -50, 0.5, -11),
        BackgroundColor3 = C.RED,
        BorderSizePixel  = 0,
        Parent           = row,
    })
    corner(pill, 11)

    local knob = N("Frame",{
        Size             = UDim2.fromOffset(16, 16),
        Position         = UDim2.fromOffset(3, 3),
        BackgroundColor3 = C.TEXT,
        BorderSizePixel  = 0,
        Parent           = pill,
    })
    corner(knob, 8)

    local on = S[key] == true

    local function refresh()
        TweenService:Create(pill, TweenInfo.new(0.2), {
            BackgroundColor3 = on and C.GREEN or C.RED
        }):Play()
        TweenService:Create(knob, TweenInfo.new(0.2), {
            Position = on and UDim2.fromOffset(25, 3) or UDim2.fromOffset(3, 3)
        }):Play()
    end
    refresh()

    local hitbox = N("TextButton",{
        Size               = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text               = "",
        Parent             = row,
    })
    hitbox.MouseButton1Click:Connect(function()
        on     = not on
        S[key] = on
        refresh()
        if cb then cb(on) end
        notify((on and "✅ " or "❌ ") .. lbl .. (on and " ON" or " OFF"))
    end)
end

-- ── Button ──────────────────────────────────────────────────
local function button(lbl, col, cb)
    local b = mkBtn(Scroll, {
        Size             = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = col or C.ACCENT,
        Text             = lbl,
        TextSize         = 13,
    }, cb)
    return b
end

-- ── Slider ──────────────────────────────────────────────────
local function slider(lbl, key, mn, mx, cb)
    local row = N("Frame",{
        Size             = UDim2.new(1, 0, 0, 52),
        BackgroundColor3 = C.PANEL,
        BorderSizePixel  = 0,
        Parent           = Scroll,
    })
    corner(row, 6) stroke(row)

    local valLbl = N("TextLabel",{
        Size               = UDim2.new(1, -10, 0, 22),
        Position           = UDim2.fromOffset(10, 2),
        BackgroundTransparency = 1,
        Font               = Enum.Font.GothamMedium,
        Text               = lbl .. ": " .. tostring(S[key]),
        TextColor3         = C.TEXT,
        TextSize           = 12,
        TextXAlignment     = Enum.TextXAlignment.Left,
        Parent             = row,
    })

    local track = N("Frame",{
        Size             = UDim2.new(1, -20, 0, 6),
        Position         = UDim2.fromOffset(10, 34),
        BackgroundColor3 = C.BORDER,
        BorderSizePixel  = 0,
        Parent           = row,
    })
    corner(track, 3)

    local pct0 = (S[key] - mn) / (mx - mn)
    local fill = N("Frame",{
        Size             = UDim2.new(pct0, 0, 1, 0),
        BackgroundColor3 = C.ACCENT,
        BorderSizePixel  = 0,
        Parent           = track,
    })
    corner(fill, 3)

    local knob = N("TextButton",{
        Size             = UDim2.fromOffset(14, 14),
        Position         = UDim2.new(pct0, -7, 0.5, -7),
        BackgroundColor3 = C.TEXT,
        Text             = "",
        BorderSizePixel  = 0,
        Parent           = track,
    })
    corner(knob, 7)

    local dragging = false
    knob.MouseButton1Down:Connect(function() dragging = true end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            local abs = track.AbsolutePosition
            local sz  = track.AbsoluteSize
            local pct = math.clamp((i.Position.X - abs.X) / sz.X, 0, 1)
            local val = math.floor(mn + pct * (mx - mn))
            S[key] = val
            fill.Size     = UDim2.new(pct, 0, 1, 0)
            knob.Position = UDim2.new(pct, -7, 0.5, -7)
            valLbl.Text   = lbl .. ": " .. tostring(val)
            if cb then cb(val) end
        end
    end)
end

-- ══════════════════════════════════════════════════════════════
-- ── REMOTES ──────────────────────────────────────────────────
-- ══════════════════════════════════════════════════════════════
local function fireRemote(name, ...)
    -- Search ReplicatedStorage recursively
    for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
        if v:IsA("RemoteEvent") and v.Name:lower():find(name:lower()) then
            local ok, err = pcall(function() v:FireServer(...) end)
            return ok
        end
    end
    return false
end

-- ══════════════════════════════════════════════════════════════
-- ── UI LAYOUT ────────────────────────────────────────────────
-- ══════════════════════════════════════════════════════════════

section("🌲 Auto Chop")
toggle("Auto Chop Trees", "AutoChop")
slider("Chop Delay (sec)", "ChopDelay", 0.1, 5)

section("👷 Workers")
button("👷 Hire Worker (Once)", C.ACCENT, function()
    if fireRemote("HireWorker") or fireRemote("Hire") then
        notify("✅ Hire Worker sent!")
    else
        notify("❌ Remote not found", C.RED)
    end
end)
toggle("Auto Hire Workers", "AutoHireWorker")

section("⬆️ Upgrades")
button("⬆️ Buy All Upgrades (Once)", C.ACCENT, function()
    for _, name in ipairs({"ChopSpeed","LogValue","WorkerSpeed","AutoSell","BuyUpgrade","Upgrade"}) do
        fireRemote(name)
        task.wait(0.2)
    end
    notify("✅ Upgrade requests sent!")
end)
toggle("Auto Buy Upgrades", "AutoUpgrade")

section("🔁 Rebirth")
button("🔁 Rebirth Now", C.RED, function()
    if fireRemote("Rebirth") then
        notify("✅ Rebirth sent!")
    else
        notify("❌ Rebirth remote not found", C.RED)
    end
end)
toggle("Auto Rebirth", "AutoRebirth")

section("🏃 Player")
toggle("Walk Speed Boost", "WalkSpeed", function(on)
    local hum = getHum()
    if hum then hum.WalkSpeed = on and S.WalkSpeedAmt or 16 end
end)
slider("Walk Speed", "WalkSpeedAmt", 16, 150, function(val)
    if S.WalkSpeed then
        local hum = getHum()
        if hum then hum.WalkSpeed = val end
    end
end)
toggle("Noclip", "Noclip")
toggle("Instant Proximity Prompts", "InstantPrompt", function(on)
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("ProximityPrompt") then v.HoldDuration = on and 0 or 1 end
    end
end)
toggle("Anti-AFK", "AntiAFK")

-- ══════════════════════════════════════════════════════════════
-- ── GAME LOOPS ───────────────────────────────────────────────
-- ══════════════════════════════════════════════════════════════

-- Noclip
RunService.Stepped:Connect(function()
    if not S.Noclip then return end
    local c = getChar()
    if not c then return end
    for _, p in ipairs(c:GetDescendants()) do
        if p:IsA("BasePart") then p.CanCollide = false end
    end
end)

-- Walk speed on respawn
LP.CharacterAdded:Connect(function(c)
    task.wait(1)
    if S.WalkSpeed then
        local hum = c:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = S.WalkSpeedAmt end
    end
end)

-- Instant prompts on new parts
workspace.DescendantAdded:Connect(function(d)
    if S.InstantPrompt and d:IsA("ProximityPrompt") then
        d.HoldDuration = 0
    end
end)

-- Anti-AFK
LP.Idled:Connect(function()
    if S.AntiAFK then
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end
end)

-- Auto Chop
task.spawn(function()
    while true do
        task.wait(math.max(S.ChopDelay, 0.1))
        if not S.AutoChop then continue end
        local root = getRoot()
        if not root then continue end

        local best, bestD = nil, math.huge
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Model") and obj.Name:lower():find("tree") then
                local part = obj:FindFirstChild("Trunk") or obj.PrimaryPart
                if part then
                    local d = (part.Position - root.Position).Magnitude
                    if d < bestD then best, bestD = obj, d end
                end
            end
        end

        if best then
            -- Try remotes first
            local fired = false
            for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
                if v:IsA("RemoteEvent") and v.Name:lower():find("chop") then
                    pcall(function() v:FireServer(best) end)
                    fired = true
                    break
                end
            end
            -- Fallback: tool activate
            if not fired then
                local c = getChar()
                local tool = c and c:FindFirstChildOfClass("Tool")
                if tool then
                    local part = best:FindFirstChild("Trunk") or best.PrimaryPart
                    if part and root then
                        pcall(function()
                            root.CFrame = CFrame.new(part.Position + Vector3.new(3,0,0))
                        end)
                        task.wait(0.1)
                        pcall(function() tool:Activate() end)
                    end
                end
            end
        end
    end
end)

-- Auto Hire Worker
task.spawn(function()
    while true do
        task.wait(2)
        if S.AutoHireWorker then
            fireRemote("HireWorker")
            fireRemote("Hire")
        end
    end
end)

-- Auto Upgrade
task.spawn(function()
    local names = {"ChopSpeed","LogValue","WorkerSpeed","AutoSell","BuyUpgrade","Upgrade"}
    while true do
        task.wait(2)
        if S.AutoUpgrade then
            for _, n in ipairs(names) do
                fireRemote(n)
                task.wait(0.2)
            end
        end
    end
end)

-- Auto Rebirth
task.spawn(function()
    while true do
        task.wait(1)
        if S.AutoRebirth then fireRemote("Rebirth") end
    end
end)

notify("✅ Lumber Empire Tools v2 loaded!")
print("[LE Tools] UI running in", GuiParent.Name)
