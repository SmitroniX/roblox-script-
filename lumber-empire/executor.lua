-- ============================================================
--  LumberEmpire Client Executor Script
--  Works in any Roblox executor (Synapse, KRNL, Fluxus, etc.)
--  Paste & Execute while in a Lumber Empire-style tycoon game.
-- ============================================================

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local VirtualUser       = game:GetService("VirtualUser")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService       = game:GetService("HttpService")

local LP   = Players.LocalPlayer
local PGui = LP:WaitForChild("PlayerGui")
local Char = LP.Character or LP.CharacterAdded:Wait()
local Root = Char:WaitForChild("HumanoidRootPart")

-- Auto-update character on respawn
LP.CharacterAdded:Connect(function(c)
    Char = c
    Root = c:WaitForChild("HumanoidRootPart")
end)

-- ── Settings ──────────────────────────────────────────────────
local Settings = {
    AutoChop         = false,
    AutoRebirth      = false,
    AutoHireWorker   = false,
    AutoUpgrade      = false,
    WalkSpeed        = false,
    Noclip           = false,
    AntiAFK          = true,
    InstantPrompt    = false,
    WalkSpeedAmount  = 25,
    ChopDelay        = 0.5,
}

-- ── Colours ───────────────────────────────────────────────────
local C = {
    BG      = Color3.fromRGB(15, 15, 20),
    PANEL   = Color3.fromRGB(25, 25, 35),
    ACCENT  = Color3.fromRGB(80, 160, 255),
    GREEN   = Color3.fromRGB(80, 220, 100),
    RED     = Color3.fromRGB(220, 80, 80),
    TEXT    = Color3.fromRGB(240, 240, 240),
    SUB     = Color3.fromRGB(150, 150, 170),
    BORDER  = Color3.fromRGB(50, 50, 70),
}

-- ── Utility ───────────────────────────────────────────────────
local function N(class, props)
    local i = Instance.new(class)
    for k,v in pairs(props) do i[k]=v end
    return i
end
local function corner(p,r) N("UICorner",{CornerRadius=UDim.new(0,r or 8),Parent=p}) end
local function stroke(p,c,t) N("UIStroke",{Color=c or C.BORDER,Thickness=t or 1,Parent=p}) end

-- ── Destroy old GUI ───────────────────────────────────────────
local old = PGui:FindFirstChild("LEGui")
if old then old:Destroy() end

-- ── Main ScreenGui ────────────────────────────────────────────
local SG = N("ScreenGui",{Name="LEGui",ResetOnSpawn=false,IgnoreGuiInset=true,Parent=PGui})

-- Window
local Win = N("Frame",{
    Size=UDim2.fromOffset(400,480),
    Position=UDim2.fromOffset(60,60),
    BackgroundColor3=C.BG,
    BorderSizePixel=0,
    Parent=SG,
})
corner(Win,10) stroke(Win)

-- Title bar
local TB = N("Frame",{Size=UDim2.new(1,0,0,40),BackgroundColor3=C.PANEL,BorderSizePixel=0,Parent=Win})
corner(TB,10)
N("TextLabel",{
    Size=UDim2.new(1,-50,1,0),Position=UDim2.fromOffset(12,0),
    BackgroundTransparency=1,Font=Enum.Font.GothamBold,
    Text="🌲 Lumber Empire Tools",TextColor3=C.TEXT,TextSize=16,
    TextXAlignment=Enum.TextXAlignment.Left,Parent=TB,
})

-- Minimise button
local MinBtn = N("TextButton",{
    Size=UDim2.fromOffset(28,28),Position=UDim2.new(1,-36,0.5,-14),
    BackgroundColor3=C.ACCENT,Font=Enum.Font.GothamBold,
    Text="—",TextColor3=C.TEXT,TextSize=14,Parent=TB,
})
corner(MinBtn,6)

local ContentVisible = true
local Content = N("Frame",{
    Size=UDim2.new(1,0,1,-40),Position=UDim2.fromOffset(0,40),
    BackgroundTransparency=1,Parent=Win,
})

MinBtn.MouseButton1Click:Connect(function()
    ContentVisible = not ContentVisible
    Content.Visible = ContentVisible
    Win.Size = ContentVisible and UDim2.fromOffset(400,480) or UDim2.fromOffset(400,40)
    MinBtn.Text = ContentVisible and "—" or "+"
end)

-- Drag
do
    local drag, ds, sp = false, nil, nil
    TB.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then
            drag,ds,sp=true,i.Position,Win.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if drag and i.UserInputType==Enum.UserInputType.MouseMovement then
            local d=i.Position-ds
            Win.Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end
    end)
end

-- ── Scrollable content ────────────────────────────────────────
local Scroll = N("ScrollingFrame",{
    Size=UDim2.new(1,-16,1,-10),Position=UDim2.fromOffset(8,5),
    BackgroundTransparency=1,BorderSizePixel=0,
    ScrollBarThickness=4,ScrollBarImageColor3=C.ACCENT,
    CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,
    Parent=Content,
})
N("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,6),Parent=Scroll})
N("UIPadding",{PaddingTop=UDim.new(0,4),PaddingLeft=UDim.new(0,2),PaddingRight=UDim.new(0,2),Parent=Scroll})

-- ── Notify label ──────────────────────────────────────────────
local NotifLbl = N("TextLabel",{
    Size=UDim2.new(1,0,0,22),BackgroundTransparency=1,
    Font=Enum.Font.Gotham,Text="",TextColor3=C.GREEN,
    TextSize=12,TextXAlignment=Enum.TextXAlignment.Center,Parent=Scroll,
})
local function notify(msg,col)
    NotifLbl.Text=msg NotifLbl.TextColor3=col or C.GREEN
    task.delay(3,function() if NotifLbl.Text==msg then NotifLbl.Text="" end end)
end

-- ── Section header ────────────────────────────────────────────
local function section(title)
    local lbl = N("TextLabel",{
        Size=UDim2.new(1,0,0,22),BackgroundTransparency=1,
        Font=Enum.Font.GothamBold,Text=title,
        TextColor3=C.ACCENT,TextSize=13,
        TextXAlignment=Enum.TextXAlignment.Left,Parent=Scroll,
    })
    return lbl
end

-- ── Toggle builder ────────────────────────────────────────────
local function toggle(label, settingKey, callback)
    local row = N("Frame",{
        Size=UDim2.new(1,0,0,36),BackgroundColor3=C.PANEL,
        BorderSizePixel=0,Parent=Scroll,
    })
    corner(row,6) stroke(row)

    N("TextLabel",{
        Size=UDim2.new(1,-60,1,0),Position=UDim2.fromOffset(10,0),
        BackgroundTransparency=1,Font=Enum.Font.GothamMedium,
        Text=label,TextColor3=C.TEXT,TextSize=13,
        TextXAlignment=Enum.TextXAlignment.Left,Parent=row,
    })

    local pill = N("Frame",{
        Size=UDim2.fromOffset(44,22),Position=UDim2.new(1,-54,0.5,-11),
        BackgroundColor3=C.RED,BorderSizePixel=0,Parent=row,
    })
    corner(pill,11)

    local knob = N("Frame",{
        Size=UDim2.fromOffset(16,16),Position=UDim2.fromOffset(3,3),
        BackgroundColor3=C.TEXT,BorderSizePixel=0,Parent=pill,
    })
    corner(knob,8)

    local stateLbl = N("TextLabel",{
        Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,
        Font=Enum.Font.GothamBold,Text="OFF",TextColor3=C.TEXT,
        TextSize=9,TextXAlignment=Enum.TextXAlignment.Center,Parent=pill,
    })

    local on = Settings[settingKey] or false

    local function refresh()
        TweenService:Create(pill,TweenInfo.new(0.2),{BackgroundColor3=on and C.GREEN or C.RED}):Play()
        TweenService:Create(knob,TweenInfo.new(0.2),{Position=on and UDim2.fromOffset(25,3) or UDim2.fromOffset(3,3)}):Play()
        stateLbl.Text = on and "ON" or "OFF"
    end
    refresh()

    local btn = N("TextButton",{
        Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,
        Text="",Parent=row,
    })
    btn.MouseButton1Click:Connect(function()
        on = not on
        Settings[settingKey] = on
        refresh()
        if callback then callback(on) end
        notify((on and "✅ " or "❌ ") .. label .. (on and " enabled" or " disabled"))
    end)

    return row
end

-- ── Button builder ────────────────────────────────────────────
local function button(label, col, callback)
    local b = N("TextButton",{
        Size=UDim2.new(1,0,0,36),BackgroundColor3=col or C.ACCENT,
        Font=Enum.Font.GothamBold,Text=label,
        TextColor3=C.TEXT,TextSize=13,Parent=Scroll,
    })
    corner(b,6)
    b.MouseEnter:Connect(function()
        TweenService:Create(b,TweenInfo.new(0.15),{BackgroundColor3=C.GREEN}):Play()
    end)
    b.MouseLeave:Connect(function()
        TweenService:Create(b,TweenInfo.new(0.15),{BackgroundColor3=col or C.ACCENT}):Play()
    end)
    if callback then b.MouseButton1Click:Connect(callback) end
    return b
end

-- ── Slider builder ────────────────────────────────────────────
local function slider(labelText, settingKey, min, max, callback)
    local row = N("Frame",{
        Size=UDim2.new(1,0,0,52),BackgroundColor3=C.PANEL,
        BorderSizePixel=0,Parent=Scroll,
    })
    corner(row,6) stroke(row)

    local valLbl = N("TextLabel",{
        Size=UDim2.new(1,-10,0,20),Position=UDim2.fromOffset(10,4),
        BackgroundTransparency=1,Font=Enum.Font.GothamMedium,
        Text=labelText..": "..Settings[settingKey],
        TextColor3=C.TEXT,TextSize=12,
        TextXAlignment=Enum.TextXAlignment.Left,Parent=row,
    })

    local track = N("Frame",{
        Size=UDim2.new(1,-20,0,6),Position=UDim2.fromOffset(10,32),
        BackgroundColor3=C.BORDER,BorderSizePixel=0,Parent=row,
    })
    corner(track,3)

    local fill = N("Frame",{
        Size=UDim2.new((Settings[settingKey]-min)/(max-min),0,1,0),
        BackgroundColor3=C.ACCENT,BorderSizePixel=0,Parent=track,
    })
    corner(fill,3)

    local knob = N("TextButton",{
        Size=UDim2.fromOffset(14,14),
        Position=UDim2.new((Settings[settingKey]-min)/(max-min),0,0.5,-7),
        BackgroundColor3=C.TEXT,Text="",BorderSizePixel=0,Parent=track,
    })
    corner(knob,7)

    local dragging = false
    knob.MouseButton1Down:Connect(function() dragging=true end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then
            local abs = track.AbsolutePosition
            local sz  = track.AbsoluteSize
            local pct = math.clamp((i.Position.X - abs.X) / sz.X, 0, 1)
            local val = math.floor(min + pct*(max-min))
            Settings[settingKey] = val
            fill.Size = UDim2.new(pct,0,1,0)
            knob.Position = UDim2.new(pct,0,0.5,-7)
            valLbl.Text = labelText..": "..val
            if callback then callback(val) end
        end
    end)

    return row
end

-- ═══════════════════════════════════════════════════════════════
-- ── REMOTES helper ────────────────────────────────────────────
-- ═══════════════════════════════════════════════════════════════
local function getRemote(name)
    local r = ReplicatedStorage:FindFirstChild("Remotes")
    if r then return r:FindFirstChild(name) end
    -- Try direct
    return ReplicatedStorage:FindFirstChild(name)
end

local function fireRemote(name, ...)
    local remote = getRemote(name)
    if remote and remote:IsA("RemoteEvent") then
        remote:FireServer(...)
        return true
    end
    -- Search whole RS
    for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
        if v:IsA("RemoteEvent") and v.Name:lower():find(name:lower()) then
            v:FireServer(...)
            return true
        end
    end
    return false
end

-- ═══════════════════════════════════════════════════════════════
-- ── UI SECTIONS ───────────────────────────────────────────────
-- ═══════════════════════════════════════════════════════════════

section("🌲 Auto Chop")

toggle("Auto Chop Trees", "AutoChop")
slider("Chop Delay (s)", "ChopDelay", 0.1, 3, nil)

section("👷 Workers")

button("👷 Hire Worker (Once)", C.ACCENT, function()
    if fireRemote("HireWorker") then
        notify("✅ Hire Worker request sent!")
    else
        notify("❌ HireWorker remote not found in this game", C.RED)
    end
end)

toggle("Auto Hire Workers", "AutoHireWorker")

section("⬆️ Upgrades")

toggle("Auto Buy Upgrades", "AutoUpgrade")

section("🔁 Rebirth")

button("🔁 Rebirth Now", Color3.fromRGB(180,60,60), function()
    if fireRemote("Rebirth") then
        notify("✅ Rebirth request sent!")
    else
        notify("❌ Rebirth remote not found in this game", C.RED)
    end
end)

toggle("Auto Rebirth", "AutoRebirth")

section("🏃 Player Mods")

toggle("Walk Speed Boost", "WalkSpeed", function(on)
    local hum = Char and Char:FindFirstChildOfClass("Humanoid")
    if hum then hum.WalkSpeed = on and Settings.WalkSpeedAmount or 16 end
end)

slider("Walk Speed", "WalkSpeedAmount", 16, 100, function(val)
    if Settings.WalkSpeed then
        local hum = Char and Char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = val end
    end
end)

toggle("Noclip", "Noclip")

toggle("Instant Proximity Prompts", "InstantPrompt", function(on)
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("ProximityPrompt") then
            v.HoldDuration = on and 0 or v.HoldDuration
        end
    end
end)

toggle("Anti-AFK", "AntiAFK")

-- ═══════════════════════════════════════════════════════════════
-- ── GAME LOOPS ────────────────────────────────────────────────
-- ═══════════════════════════════════════════════════════════════

-- Noclip loop
RunService.Stepped:Connect(function()
    if Settings.Noclip and Char then
        for _, p in ipairs(Char:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end
end)

-- Instant prompts on new descendants
workspace.DescendantAdded:Connect(function(d)
    if Settings.InstantPrompt and d:IsA("ProximityPrompt") then
        d.HoldDuration = 0
    end
end)

-- Anti-AFK
LP.Idled:Connect(function()
    if Settings.AntiAFK then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end
end)

-- Auto Chop loop
task.spawn(function()
    while true do
        task.wait(Settings.ChopDelay)
        if not Settings.AutoChop then continue end

        local char = LP.Character
        if not char or not char.PrimaryPart then continue end
        local rootPos = char.PrimaryPart.Position

        -- Find nearest tree
        local best, bestDist = nil, math.huge
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Model") and obj.Name:lower():find("tree") then
                local trunk = obj:FindFirstChild("Trunk") or obj.PrimaryPart
                if trunk then
                    local d = (trunk.Position - rootPos).Magnitude
                    if d < bestDist then best, bestDist = obj, d end
                end
            end
        end

        if best then
            -- Try RemoteEvent first
            local fired = false
            for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
                if v:IsA("RemoteEvent") and v.Name:lower():find("chop") then
                    v:FireServer(best)
                    fired = true
                    break
                end
            end
            -- Fallback: tool activation
            if not fired then
                local tool = char:FindFirstChildOfClass("Tool")
                if tool then
                    local handle = tool:FindFirstChild("Handle")
                    if handle then
                        -- Teleport near tree and activate
                        local trunk = best:FindFirstChild("Trunk") or best.PrimaryPart
                        if trunk and char.PrimaryPart then
                            char.PrimaryPart.CFrame = CFrame.new(trunk.Position + Vector3.new(3,0,0))
                        end
                        tool:Activate()
                    end
                end
            end
        end
    end
end)

-- Auto Hire Worker loop
task.spawn(function()
    while true do
        task.wait(2)
        if Settings.AutoHireWorker then
            fireRemote("HireWorker")
        end
    end
end)

-- Auto Upgrade loop
task.spawn(function()
    local upgradeNames = {"ChopSpeed","LogValue","WorkerSpeed","AutoSell","BuyUpgrade","Upgrade"}
    while true do
        task.wait(2)
        if Settings.AutoUpgrade then
            for _, name in ipairs(upgradeNames) do
                fireRemote(name)
                task.wait(0.3)
            end
        end
    end
end)

-- Auto Rebirth loop
task.spawn(function()
    while true do
        task.wait(1)
        if Settings.AutoRebirth then
            fireRemote("Rebirth")
        end
    end
end)

notify("✅ Lumber Empire Tools loaded!")
print("[LumberEmpire] Executor script running ✓")
