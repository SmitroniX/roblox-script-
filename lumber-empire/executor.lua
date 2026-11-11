-- ============================================================
--  SmitroniX Hub v2 — Lumber Empire Automation Suite
--  Features: Tycoon Automation, Zero-Fling Chop, Live HUD,
--            Waypoints, Fly, FPS Booster, Themes & Configs
-- ============================================================

-- ── Services & Environment ───────────────────────────────────
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local VirtualUser       = game:GetService("VirtualUser")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui           = game:GetService("CoreGui")
local Lighting          = game:GetService("Lighting")

local LP = Players.LocalPlayer

-- Safe GUI container
local GuiParent = nil
local okHui, hui = pcall(function()
    if typeof(gethui) == "function" then return gethui() end
    return nil
end)
if okHui and hui then
    GuiParent = hui
else
    local okCore, core = pcall(function() return CoreGui end)
    if okCore and core then
        GuiParent = core
    else
        GuiParent = LP:WaitForChild("PlayerGui")
    end
end

-- Clean previous instance
local oldGui = GuiParent:FindFirstChild("SmitroniXHub")
if oldGui then
    pcall(function() oldGui:Destroy() end)
    task.wait(0.1)
end

-- ── Character Accessors ──────────────────────────────────────
local function getChar() return LP.Character end
local function getRoot()
    local c = getChar()
    return c and (c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("UpperTorso") or c:FindFirstChild("Torso"))
end
local function getHum()
    local c = getChar()
    return c and c:FindFirstChildOfClass("Humanoid")
end

-- ── Theme Definitions ────────────────────────────────────────
local Themes = {
    Violet = {
        Accent      = Color3.fromRGB(139, 92, 246),
        AccentLight = Color3.fromRGB(167, 139, 250),
        AccentDark  = Color3.fromRGB(109, 40, 217),
    },
    Cyan = {
        Accent      = Color3.fromRGB(6, 182, 212),
        AccentLight = Color3.fromRGB(103, 232, 249),
        AccentDark  = Color3.fromRGB(14, 116, 144),
    },
    Emerald = {
        Accent      = Color3.fromRGB(16, 185, 129),
        AccentLight = Color3.fromRGB(110, 231, 183),
        AccentDark  = Color3.fromRGB(4, 120, 87),
    },
    Gold = {
        Accent      = Color3.fromRGB(245, 158, 11),
        AccentLight = Color3.fromRGB(252, 211, 77),
        AccentDark  = Color3.fromRGB(180, 83, 9),
    },
    Crimson = {
        Accent      = Color3.fromRGB(239, 68, 68),
        AccentLight = Color3.fromRGB(252, 165, 165),
        AccentDark  = Color3.fromRGB(185, 28, 28),
    },
}

local CurrentThemeName = "Violet"
local Theme = {
    BG            = Color3.fromRGB(13, 11, 20),
    Sidebar       = Color3.fromRGB(18, 15, 28),
    Card          = Color3.fromRGB(24, 21, 38),
    CardHover     = Color3.fromRGB(30, 26, 46),
    CardStroke    = Color3.fromRGB(42, 36, 64),
    Separator     = Color3.fromRGB(32, 28, 50),
    Accent        = Themes.Violet.Accent,
    AccentLight   = Themes.Violet.AccentLight,
    AccentDark    = Themes.Violet.AccentDark,
    ToggleOff     = Color3.fromRGB(38, 34, 56),
    ToggleOn      = Themes.Violet.Accent,
    TextPrimary   = Color3.fromRGB(248, 247, 255),
    TextSecondary = Color3.fromRGB(150, 144, 172),
    TextMuted     = Color3.fromRGB(100, 94, 125),
    ScrollThumb   = Themes.Violet.Accent,
    Green         = Color3.fromRGB(16, 185, 129),
    Red           = Color3.fromRGB(239, 68, 68),
}

-- ── State Management ─────────────────────────────────────────
local State = {
    -- Safety & Movement
    AllowTeleport      = false,
    SafeRadius         = 45,
    GoldenPriority     = true,
    
    -- Tycoon Automation
    AutoChop           = false,
    AutoUpgrade        = false,
    AutoHireWorkers    = false,
    AutoRebirth        = false,
    SmartRebirthGoal   = 100000,
    
    -- Airport Automation
    AutoAirportHangar  = false,
    AutoAirportFlight  = false,
    
    -- Player Enhancements
    WalkSpeedBoost     = false,
    WalkSpeedVal       = 24,
    JumpPowerBoost     = false,
    JumpPowerVal       = 50,
    Noclip             = false,
    InfiniteJump       = false,
    Fly                = false,
    FlySpeed           = 40,
    InstantPrompts     = false,
    AntiAFK            = true,
    
    -- Optimizations & Visuals
    FPSBooster         = false,
    TreeESP            = false,
    Fullbright         = false,
    ShowHUD            = true,
    
    -- Telemetry & Session
    StartTime          = os.time(),
    InitialCoins       = 0,
    CoinsEarned        = 0,
    ChopCount          = 0,
    RebirthCount       = 0,
}

-- ── UI Helpers ───────────────────────────────────────────────
local function create(class, props)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do
        pcall(function() inst[k] = v end)
    end
    return inst
end

local function addCorner(parent, radius)
    local c = create("UICorner", { CornerRadius = UDim.new(0, radius or 8) })
    c.Parent = parent
    return c
end

local function addStroke(parent, color, thickness)
    local s = create("UIStroke", {
        Color = color or Theme.CardStroke,
        Thickness = thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })
    s.Parent = parent
    return s
end

local function tween(inst, props, duration)
    local info = TweenInfo.new(duration or 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local anim = TweenService:Create(inst, info, props)
    anim:Play()
    return anim
end

-- ══════════════════════════════════════════════════════════════
-- ── ROOT SCREEN GUI & MAIN WINDOW ─────────────────────────────
-- ══════════════════════════════════════════════════════════════
local ScreenGui = create("ScreenGui", {
    Name = "SmitroniXHub",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    Parent = GuiParent,
})

local MainWindow = create("Frame", {
    Name = "MainWindow",
    Size = UDim2.fromOffset(720, 450),
    Position = UDim2.fromScale(0.5, 0.5),
    AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundColor3 = Theme.BG,
    BorderSizePixel = 0,
    Parent = ScreenGui,
})
addCorner(MainWindow, 12)
local MainStroke = addStroke(MainWindow, Theme.CardStroke, 1.2)

pcall(function()
    local cam = workspace.CurrentCamera
    if cam and cam.ViewportSize.X < 760 then
        local w = math.clamp(cam.ViewportSize.X - 24, 340, 720)
        local h = math.clamp(cam.ViewportSize.Y - 24, 300, 450)
        MainWindow.Size = UDim2.fromOffset(w, h)
    end
end)

-- Dragging Controller
local dragging, dragStart, startPos = false, nil, nil
local function updateDrag(input)
    local delta = input.Position - dragStart
    MainWindow.Position = UDim2.new(
        startPos.X.Scale, startPos.X.Offset + delta.X,
        startPos.Y.Scale, startPos.Y.Offset + delta.Y
    )
end

-- ══════════════════════════════════════════════════════════════
-- ── SIDEBAR (SMITRONIX BRANDING) ──────────────────────────────
-- ══════════════════════════════════════════════════════════════
local Sidebar = create("Frame", {
    Name = "Sidebar",
    Size = UDim2.new(0, 185, 1, 0),
    BackgroundColor3 = Theme.Sidebar,
    BorderSizePixel = 0,
    Parent = MainWindow,
})
addCorner(Sidebar, 12)

create("Frame", {
    Size = UDim2.new(0, 12, 1, 0),
    Position = UDim2.new(1, -12, 0, 0),
    BackgroundColor3 = Theme.Sidebar,
    BorderSizePixel = 0,
    Parent = Sidebar,
})

create("Frame", {
    Size = UDim2.new(0, 1, 1, 0),
    Position = UDim2.new(1, 0, 0, 0),
    BackgroundColor3 = Theme.Separator,
    BorderSizePixel = 0,
    Parent = Sidebar,
})

Sidebar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainWindow.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
Sidebar.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        updateDrag(input)
    end
end)

local BrandFrame = create("Frame", {
    Size = UDim2.new(1, 0, 0, 60),
    BackgroundTransparency = 1,
    Parent = Sidebar,
})

local LogoBadge = create("Frame", {
    Size = UDim2.fromOffset(28, 28),
    Position = UDim2.fromOffset(16, 16),
    BackgroundColor3 = Theme.AccentDark,
    BorderSizePixel = 0,
    Parent = BrandFrame,
})
addCorner(LogoBadge, 8)
local LogoStroke = addStroke(LogoBadge, Theme.Accent, 1)

create("TextLabel", {
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamBold,
    Text = "SX",
    TextColor3 = Theme.TextPrimary,
    TextSize = 13,
    Parent = LogoBadge,
})

create("TextLabel", {
    Size = UDim2.new(1, -56, 0, 20),
    Position = UDim2.fromOffset(52, 14),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamBold,
    Text = "SmitroniX",
    TextColor3 = Theme.TextPrimary,
    TextSize = 15,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = BrandFrame,
})

local BrandBadge = create("TextLabel", {
    Size = UDim2.new(1, -56, 0, 14),
    Position = UDim2.fromOffset(52, 33),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamMedium,
    Text = "LUMBER EMPIRE v2",
    TextColor3 = Theme.AccentLight,
    TextSize = 8,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = BrandFrame,
})

create("TextLabel", {
    Size = UDim2.new(1, -32, 0, 18),
    Position = UDim2.fromOffset(16, 64),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamBold,
    Text = "MODULES",
    TextColor3 = Theme.TextMuted,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = Sidebar,
})

local NavList = create("Frame", {
    Size = UDim2.new(1, -20, 1, -95),
    Position = UDim2.fromOffset(10, 86),
    BackgroundTransparency = 1,
    Parent = Sidebar,
})
create("UIListLayout", {
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 3),
    Parent = NavList,
})

-- ══════════════════════════════════════════════════════════════
-- ── MAIN CONTENT AREA (RIGHT) ─────────────────────────────────
-- ══════════════════════════════════════════════════════════════
local ContentArea = create("Frame", {
    Size = UDim2.new(1, -186, 1, 0),
    Position = UDim2.fromOffset(186, 0),
    BackgroundTransparency = 1,
    ClipsDescendants = true,
    Parent = MainWindow,
})

local HeaderFrame = create("Frame", {
    Size = UDim2.new(1, 0, 0, 56),
    BackgroundTransparency = 1,
    Parent = ContentArea,
})

local HeaderTitle = create("TextLabel", {
    Size = UDim2.new(1, -60, 0, 24),
    Position = UDim2.fromOffset(24, 10),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamBold,
    Text = "Tycoon",
    TextColor3 = Theme.TextPrimary,
    TextSize = 20,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = HeaderFrame,
})

local HeaderSubtitle = create("TextLabel", {
    Size = UDim2.new(1, -60, 0, 16),
    Position = UDim2.fromOffset(24, 32),
    BackgroundTransparency = 1,
    Font = Enum.Font.Gotham,
    Text = "Automation & Upgrades",
    TextColor3 = Theme.TextSecondary,
    TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = HeaderFrame,
})

local CloseBtn = create("TextButton", {
    Size = UDim2.fromOffset(26, 26),
    Position = UDim2.new(1, -36, 0, 14),
    BackgroundColor3 = Theme.Card,
    BackgroundTransparency = 0.4,
    Text = "✕",
    TextColor3 = Theme.TextSecondary,
    TextSize = 12,
    Font = Enum.Font.GothamBold,
    Parent = HeaderFrame,
})
addCorner(CloseBtn, 6)
CloseBtn.MouseButton1Click:Connect(function()
    MainWindow.Visible = false
end)

create("Frame", {
    Size = UDim2.new(1, 0, 0, 1),
    Position = UDim2.new(0, 0, 1, -1),
    BackgroundColor3 = Theme.Separator,
    BorderSizePixel = 0,
    Parent = HeaderFrame,
})

local PageContainer = create("Frame", {
    Size = UDim2.new(1, 0, 1, -56),
    Position = UDim2.fromOffset(0, 56),
    BackgroundTransparency = 1,
    Parent = ContentArea,
})

-- Navigation & Pages
local NavButtons = {}
local Pages = {}

local function createPage(name)
    local scroll = create("ScrollingFrame", {
        Name = "Page_" .. name,
        Size = UDim2.new(1, -20, 1, -10),
        Position = UDim2.fromOffset(16, 6),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Theme.ScrollThumb,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false,
        Parent = PageContainer,
    })
    create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 8),
        Parent = scroll,
    })
    create("UIPadding", {
        PaddingTop = UDim.new(0, 4),
        PaddingBottom = UDim.new(0, 16),
        PaddingLeft = UDim.new(0, 4),
        PaddingRight = UDim.new(0, 8),
        Parent = scroll,
    })
    Pages[name] = scroll
    return scroll
end

local function switchPage(pageName, subtitle)
    for name, p in pairs(Pages) do
        p.Visible = (name == pageName)
    end
    HeaderTitle.Text = pageName
    HeaderSubtitle.Text = subtitle or "SmitroniX Controls"
    
    for name, btn in pairs(NavButtons) do
        local active = (name == pageName)
        tween(btn, {
            BackgroundColor3 = active and Theme.Card or Theme.Sidebar,
            BackgroundTransparency = active and 0 or 1,
        }, 0.15)
        local icon = btn:FindFirstChild("Icon")
        local text = btn:FindFirstChild("Text")
        if icon then icon.TextColor3 = active and Theme.AccentLight or Theme.TextSecondary end
        if text then text.TextColor3 = active and Theme.TextPrimary or Theme.TextSecondary end
    end
end

local function addNavItem(name, iconChar, subtitle)
    local btn = create("TextButton", {
        Name = "Nav_" .. name,
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundColor3 = Theme.Sidebar,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = "",
        Parent = NavList,
    })
    addCorner(btn, 8)
    
    local icon = create("TextLabel", {
        Name = "Icon",
        Size = UDim2.fromOffset(24, 24),
        Position = UDim2.fromOffset(10, 5),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = iconChar,
        TextColor3 = Theme.TextSecondary,
        TextSize = 13,
        Parent = btn,
    })
    
    local text = create("TextLabel", {
        Name = "Text",
        Size = UDim2.new(1, -44, 1, 0),
        Position = UDim2.fromOffset(38, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        Text = name,
        TextColor3 = Theme.TextSecondary,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = btn,
    })
    
    btn.MouseButton1Click:Connect(function()
        switchPage(name, subtitle)
    end)
    
    NavButtons[name] = btn
    return btn
end

-- ══════════════════════════════════════════════════════════════
-- ── WIDGET FACTORY ────────────────────────────────────────────
-- ══════════════════════════════════════════════════════════════
local function createCard(parent, height)
    local card = create("Frame", {
        Size = UDim2.new(1, 0, 0, height or 52),
        BackgroundColor3 = Theme.Card,
        BorderSizePixel = 0,
        Parent = parent,
    })
    addCorner(card, 8)
    addStroke(card, Theme.CardStroke, 1)
    return card
end

local function addToggleCard(parent, title, subtitle, defaultVal, callback)
    local card = createCard(parent, 52)
    
    create("TextLabel", {
        Size = UDim2.new(1, -70, 0, 18),
        Position = UDim2.fromOffset(14, 8),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = title,
        TextColor3 = Theme.TextPrimary,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = card,
    })
    
    create("TextLabel", {
        Size = UDim2.new(1, -70, 0, 16),
        Position = UDim2.fromOffset(14, 26),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = subtitle or "",
        TextColor3 = Theme.TextSecondary,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = card,
    })
    
    local switch = create("Frame", {
        Size = UDim2.fromOffset(40, 20),
        Position = UDim2.new(1, -54, 0.5, -10),
        BackgroundColor3 = defaultVal and Theme.ToggleOn or Theme.ToggleOff,
        BorderSizePixel = 0,
        Parent = card,
    })
    addCorner(switch, 10)
    
    local knob = create("Frame", {
        Size = UDim2.fromOffset(16, 16),
        Position = defaultVal and UDim2.fromOffset(21, 2) or UDim2.fromOffset(2, 2),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        Parent = switch,
    })
    addCorner(knob, 8)
    
    local isToggled = defaultVal
    local btn = create("TextButton", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        Parent = card,
    })
    
    btn.MouseButton1Click:Connect(function()
        isToggled = not isToggled
        tween(switch, { BackgroundColor3 = isToggled and Theme.ToggleOn or Theme.ToggleOff }, 0.18)
        tween(knob, { Position = isToggled and UDim2.fromOffset(21, 2) or UDim2.fromOffset(2, 2) }, 0.18)
        if callback then callback(isToggled) end
    end)
    
    return card
end

local function addButtonCard(parent, title, subtitle, btnText, btnColor, callback)
    local card = createCard(parent, 52)
    
    create("TextLabel", {
        Size = UDim2.new(1, -140, 0, 18),
        Position = UDim2.fromOffset(14, 8),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = title,
        TextColor3 = Theme.TextPrimary,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = card,
    })
    
    create("TextLabel", {
        Size = UDim2.new(1, -140, 0, 16),
        Position = UDim2.fromOffset(14, 26),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = subtitle or "",
        TextColor3 = Theme.TextSecondary,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = card,
    })
    
    local actBtn = create("TextButton", {
        Size = UDim2.fromOffset(115, 30),
        Position = UDim2.new(1, -128, 0.5, -15),
        BackgroundColor3 = btnColor or Theme.Accent,
        Font = Enum.Font.GothamBold,
        Text = btnText,
        TextColor3 = Theme.TextPrimary,
        TextSize = 11,
        Parent = card,
    })
    addCorner(actBtn, 6)
    
    actBtn.MouseButton1Click:Connect(function()
        if callback then callback() end
    end)
    
    return card
end

local function addSliderCard(parent, title, subtitle, minVal, maxVal, defaultVal, suffix, callback)
    local card = createCard(parent, 60)
    
    create("TextLabel", {
        Size = UDim2.new(1, -140, 0, 18),
        Position = UDim2.fromOffset(14, 10),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = title,
        TextColor3 = Theme.TextPrimary,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = card,
    })
    
    create("TextLabel", {
        Size = UDim2.new(1, -140, 0, 16),
        Position = UDim2.fromOffset(14, 28),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = subtitle or "",
        TextColor3 = Theme.TextSecondary,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = card,
    })
    
    local valDisplay = create("TextLabel", {
        Size = UDim2.fromOffset(80, 20),
        Position = UDim2.new(1, -225, 0.5, -10),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = tostring(defaultVal) .. " " .. (suffix or ""),
        TextColor3 = Theme.AccentLight,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = card,
    })
    
    local track = create("Frame", {
        Size = UDim2.fromOffset(120, 6),
        Position = UDim2.new(1, -134, 0.5, -3),
        BackgroundColor3 = Theme.ToggleOff,
        BorderSizePixel = 0,
        Parent = card,
    })
    addCorner(track, 3)
    
    local pct = math.clamp((defaultVal - minVal) / (maxVal - minVal), 0, 1)
    local fill = create("Frame", {
        Size = UDim2.new(pct, 0, 1, 0),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Parent = track,
    })
    addCorner(fill, 3)
    
    local knob = create("TextButton", {
        Size = UDim2.fromOffset(12, 12),
        Position = UDim2.new(pct, -6, 0.5, -6),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        Text = "",
        BorderSizePixel = 0,
        Parent = track,
    })
    addCorner(knob, 6)
    
    local isSliding = false
    knob.MouseButton1Down:Connect(function() isSliding = true end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            isSliding = false
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if isSliding and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local rel = math.clamp((i.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            local calcVal = math.floor(minVal + rel * (maxVal - minVal))
            fill.Size = UDim2.new(rel, 0, 1, 0)
            knob.Position = UDim2.new(rel, -6, 0.5, -6)
            valDisplay.Text = tostring(calcVal) .. " " .. (suffix or "")
            if callback then callback(calcVal) end
        end
    end)
    
    return card
end

-- ══════════════════════════════════════════════════════════════
-- ── FLOATING LIVE DASHBOARD (HUD) ─────────────────────────────
-- ══════════════════════════════════════════════════════════════
local HUD = create("Frame", {
    Name = "SX_LiveHUD",
    Size = UDim2.fromOffset(230, 90),
    Position = UDim2.fromOffset(20, 70),
    BackgroundColor3 = Theme.BG,
    BorderSizePixel = 0,
    Visible = State.ShowHUD,
    Parent = ScreenGui,
})
addCorner(HUD, 10)
addStroke(HUD, Theme.CardStroke, 1.2)

local hudHeader = create("Frame", {
    Size = UDim2.new(1, 0, 0, 24),
    BackgroundColor3 = Theme.Sidebar,
    BorderSizePixel = 0,
    Parent = HUD,
})
addCorner(hudHeader, 10)

create("TextLabel", {
    Size = UDim2.new(1, -20, 1, 0),
    Position = UDim2.fromOffset(10, 0),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamBold,
    Text = "📊 SmitroniX Live Stats",
    TextColor3 = Theme.TextPrimary,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = hudHeader,
})

local hudTime = create("TextLabel", {
    Size = UDim2.new(1, -20, 0, 18),
    Position = UDim2.fromOffset(10, 26),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamMedium,
    Text = "⏱ Session: 00:00:00",
    TextColor3 = Theme.TextSecondary,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = HUD,
})

local hudCoins = create("TextLabel", {
    Size = UDim2.new(1, -20, 0, 18),
    Position = UDim2.fromOffset(10, 44),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamMedium,
    Text = "💰 Earned: $0  (+0/hr)",
    TextColor3 = Theme.Green,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = HUD,
})

local hudLogs = create("TextLabel", {
    Size = UDim2.new(1, -20, 0, 18),
    Position = UDim2.fromOffset(10, 64),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamMedium,
    Text = "🪵 Chopped: 0  |  🔁 Rebirths: 0",
    TextColor3 = Theme.AccentLight,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = HUD,
})

-- Draggable HUD
do
    local hDrag, hStart, hPos = false, nil, nil
    hudHeader.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            hDrag = true
            hStart = i.Position
            hPos = HUD.Position
            i.Changed:Connect(function()
                if i.UserInputState == Enum.UserInputState.End then hDrag = false end
            end)
        end
    end)
    hudHeader.InputChanged:Connect(function(i)
        if hDrag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - hStart
            HUD.Position = UDim2.new(hPos.X.Scale, hPos.X.Offset + d.X, hPos.Y.Scale, hPos.Y.Offset + d.Y)
        end
    end)
end

-- ══════════════════════════════════════════════════════════════
-- ── BUILD PAGES ───────────────────────────────────────────────
-- ══════════════════════════════════════════════════════════════
local PageTycoon     = createPage("Tycoon")
local PageChop       = createPage("Auto Chop")
local PageWaypoints  = createPage("Waypoints")
local PagePlayer     = createPage("Player")
local PageOptim      = createPage("Optimizations")
local PageSettings   = createPage("Settings")

addNavItem("Tycoon", "🌲", "Lumber Empire Automated Upgrades")
addNavItem("Auto Chop", "🪓", "Safe Wood Harvesting (No-Fling)")
addNavItem("Waypoints", "📍", "1-Click Base Navigation")
addNavItem("Player", "👤", "Character & Flight Enhancements")
addNavItem("Optimizations", "⚡", "FPS Booster & World ESP")
addNavItem("Settings", "🎨", "Theme Colors & HUD Controls")

-- ── 1. TYCOON PAGE ────────────────────────────────────────────
addToggleCard(PageTycoon, "Auto Upgrade Workers & Trucks", "Automatically upgrades truck speed, capacity and workers", State.AutoUpgrade, function(on)
    State.AutoUpgrade = on
end)

addToggleCard(PageTycoon, "Auto Hire Workers", "Hires sawmill workers automatically as funds allow", State.AutoHireWorkers, function(on)
    State.AutoHireWorkers = on
end)

addToggleCard(PageTycoon, "Smart Auto Rebirth", "Only triggers rebirth after reaching your target coins goal", State.AutoRebirth, function(on)
    State.AutoRebirth = on
end)

addSliderCard(PageTycoon, "Rebirth Coin Goal", "Min coins needed before smart rebirth triggers", 50000, 1000000, State.SmartRebirthGoal, "$", function(val)
    State.SmartRebirthGoal = val
end)

addButtonCard(PageTycoon, "Instant Rebirth Now", "Triggers Rebirth remote immediately", "Rebirth Now", Theme.Red, function()
    pcall(function()
        ReplicatedStorage.Remotes.Rebirth:FireServer()
    end)
end)

addToggleCard(PageTycoon, "Auto Airport Hangars", "Automatically buys & upgrades airport hangars", State.AutoAirportHangar, function(on)
    State.AutoAirportHangar = on
end)

addToggleCard(PageTycoon, "Auto Send Flights", "Sends planes out continuously for airport cargo revenue", State.AutoAirportFlight, function(on)
    State.AutoAirportFlight = on
end)

-- ── 2. AUTO CHOP PAGE (ZERO-FLING SAFETY) ─────────────────────
addToggleCard(PageChop, "Auto Chop Local Trees", "Automatically chops trees on your plot with zero flinging", State.AutoChop, function(on)
    State.AutoChop = on
end)

addToggleCard(PageChop, "Golden & Event Tree Priority", "Targets rare and high-multiplier trees first", State.GoldenPriority, function(on)
    State.GoldenPriority = on
end)

addToggleCard(PageChop, "Allow Player Teleport", "OFF = Stands still (safe) | ON = Steps to nearby trees", State.AllowTeleport, function(on)
    State.AllowTeleport = on
end)

addSliderCard(PageChop, "Tree Search Radius", "Maximum distance around you to target trees", 20, 80, State.SafeRadius, "studs", function(val)
    State.SafeRadius = val
end)

-- ── 3. WAYPOINTS PAGE (SAFE 1-CLICK TELEPORT) ──────────────────
local savedPlotPos = nil
addButtonCard(PageWaypoints, "Save My Plot Location", "Saves your current position as your base waypoint", "Set Plot", Theme.Accent, function()
    local root = getRoot()
    if root then
        savedPlotPos = root.Position
    end
end)

addButtonCard(PageWaypoints, "Teleport to My Plot", "Safely returns to your saved base position", "Teleport", Theme.Green, function()
    local root = getRoot()
    if root and savedPlotPos then
        pcall(function()
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            root.CFrame = CFrame.new(savedPlotPos + Vector3.new(0, 2, 0))
        end)
    end
end)

addButtonCard(PageWaypoints, "Teleport to Wood Sell Pad", "Finds the nearest wood unloading / sell pad", "Go to Sell", Theme.AccentDark, function()
    local root = getRoot()
    if root then
        for _, s in ipairs(workspace:GetDescendants()) do
            if s.Name:lower():find("sell") or s.Name:lower():find("unload") then
                local part = s:IsA("BasePart") and s or s:FindFirstChildOfClass("BasePart")
                if part then
                    pcall(function()
                        root.AssemblyLinearVelocity = Vector3.zero
                        root.AssemblyAngularVelocity = Vector3.zero
                        root.CFrame = CFrame.new(part.Position + Vector3.new(0, 3, 0))
                    end)
                    break
                end
            end
        end
    end
end)

addButtonCard(PageWaypoints, "Teleport to Airport", "Navigates to the airport terminal expansion", "Airport", Theme.Accent, function()
    local root = getRoot()
    if root then
        for _, s in ipairs(workspace:GetDescendants()) do
            if s.Name:lower():find("airport") or s.Name:lower():find("hangar") then
                local part = s:IsA("BasePart") and s or s:FindFirstChildOfClass("BasePart")
                if part then
                    pcall(function()
                        root.AssemblyLinearVelocity = Vector3.zero
                        root.AssemblyAngularVelocity = Vector3.zero
                        root.CFrame = CFrame.new(part.Position + Vector3.new(0, 3, 0))
                    end)
                    break
                end
            end
        end
    end
end)

-- ── 4. PLAYER PAGE ────────────────────────────────────────────
addToggleCard(PagePlayer, "Walk Speed Boost", "Sets your character movement speed", State.WalkSpeedBoost, function(on)
    State.WalkSpeedBoost = on
    local hum = getHum()
    if hum then hum.WalkSpeed = on and State.WalkSpeedVal or 16 end
end)

addSliderCard(PagePlayer, "Walk Speed Amount", "Default speed is 16", 16, 120, State.WalkSpeedVal, "speed", function(val)
    State.WalkSpeedVal = val
    if State.WalkSpeedBoost then
        local hum = getHum()
        if hum then hum.WalkSpeed = val end
    end
end)

addToggleCard(PagePlayer, "Flight / Float Mode", "Fly freely without triggering void barriers", State.Fly, function(on)
    State.Fly = on
    local root = getRoot()
    if root then
        local existing = root:FindFirstChild("SX_FlyBV")
        if on and not existing then
            local bv = create("BodyVelocity", {
                Name = "SX_FlyBV",
                Velocity = Vector3.zero,
                MaxForce = Vector3.new(9e9, 9e9, 9e9),
                Parent = root,
            })
        elseif not on and existing then
            existing:Destroy()
        end
    end
end)

addSliderCard(PagePlayer, "Flight Speed", "Adjust your aerial movement velocity", 20, 150, State.FlySpeed, "studs/s", function(val)
    State.FlySpeed = val
end)

addToggleCard(PagePlayer, "Infinite Jump", "Jump continuously in mid-air", State.InfiniteJump, function(on)
    State.InfiniteJump = on
end)

addToggleCard(PagePlayer, "Noclip", "Walk through objects and barriers safely", State.Noclip, function(on)
    State.Noclip = on
end)

addToggleCard(PagePlayer, "Instant Prompts", "Zero hold-down duration on ProximityPrompts", State.InstantPrompts, function(on)
    State.InstantPrompts = on
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("ProximityPrompt") then v.HoldDuration = on and 0 or 1 end
    end
end)

addToggleCard(PagePlayer, "Anti-AFK", "Prevents Roblox 20-minute idle disconnection", State.AntiAFK, function(on)
    State.AntiAFK = on
end)

-- ── 5. OPTIMIZATIONS & VISUALS ────────────────────────────────
addToggleCard(PageOptim, "FPS Booster (Potato Mode)", "Lowers heavy particle textures for 60 FPS on mobile", State.FPSBooster, function(on)
    State.FPSBooster = on
    pcall(function()
        Lighting.GlobalShadows = not on
        for _, p in ipairs(workspace:GetDescendants()) do
            if p:IsA("ParticleEmitter") or p:IsA("Trail") then
                p.Enabled = not on
            end
        end
    end)
end)

addToggleCard(PageOptim, "Tree ESP Chams", "Draws highlights over all living harvestable trees", State.TreeESP, function(on)
    State.TreeESP = on
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name:lower():find("tree") then
            local highlight = obj:FindFirstChild("SX_ESP")
            if on and not highlight then
                create("Highlight", {
                    Name = "SX_ESP",
                    FillColor = Theme.Accent,
                    OutlineColor = Theme.AccentLight,
                    FillTransparency = 0.5,
                    Parent = obj,
                })
            elseif not on and highlight then
                highlight:Destroy()
            end
        end
    end
end)

addToggleCard(PageOptim, "Fullbright", "Removes darkness and brightens entire map", State.Fullbright, function(on)
    State.Fullbright = on
    if on then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.GlobalShadows = false
    else
        Lighting.Brightness = 1
        Lighting.GlobalShadows = true
    end
end)

-- ── 6. SETTINGS & THEMES ──────────────────────────────────────
addToggleCard(PageSettings, "Show Live Dashboard (HUD)", "Displays real-time coins, time & logs overlay", State.ShowHUD, function(on)
    State.ShowHUD = on
    HUD.Visible = on
end)

local function applyTheme(name)
    local t = Themes[name]
    if not t then return end
    CurrentThemeName = name
    Theme.Accent = t.Accent
    Theme.AccentLight = t.AccentLight
    Theme.AccentDark = t.AccentDark
    Theme.ToggleOn = t.Accent
    Theme.ScrollThumb = t.Accent
    
    LogoBadge.BackgroundColor3 = t.AccentDark
    LogoStroke.Color = t.Accent
    BrandBadge.TextColor3 = t.AccentLight
    MainStroke.Color = Theme.CardStroke
end

addButtonCard(PageSettings, "Theme: Electric Violet", "Sets theme to deep violet / purple", "Violet", Themes.Violet.Accent, function()
    applyTheme("Violet")
end)

addButtonCard(PageSettings, "Theme: Cyber Cyan", "Sets theme to neon turquoise / cyan", "Cyan", Themes.Cyan.Accent, function()
    applyTheme("Cyan")
end)

addButtonCard(PageSettings, "Theme: Emerald Green", "Sets theme to vibrant forest emerald", "Emerald", Themes.Emerald.Accent, function()
    applyTheme("Emerald")
end)

addButtonCard(PageSettings, "Theme: Sunset Gold", "Sets theme to warm amber / gold", "Gold", Themes.Gold.Accent, function()
    applyTheme("Gold")
end)

-- Initial view
switchPage("Tycoon", "Lumber Empire Automated Upgrades")

-- ══════════════════════════════════════════════════════════════
-- ── BACKGROUND LOOPS & GAME HOOKS ─────────────────────────────
-- ══════════════════════════════════════════════════════════════

-- Initial Coin Recording
pcall(function()
    local ls = LP:FindFirstChild("leaderstats")
    if ls then
        local c = ls:FindFirstChild("Coins") or ls:FindFirstChild("Money") or ls:FindFirstChild("Cash")
        if c then State.InitialCoins = c.Value end
    end
end)

-- Live HUD Updating Loop
task.spawn(function()
    while true do
        task.wait(1)
        if State.ShowHUD and HUD.Visible then
            local elapsed = os.time() - State.StartTime
            local hrs = math.floor(elapsed / 3600)
            local mins = math.floor((elapsed % 3600) / 60)
            local secs = elapsed % 60
            hudTime.Text = string.format("⏱ Session: %02d:%02d:%02d", hrs, mins, secs)
            
            -- Read current coins
            local curCoins = 0
            local ls = LP:FindFirstChild("leaderstats")
            if ls then
                local c = ls:FindFirstChild("Coins") or ls:FindFirstChild("Money") or ls:FindFirstChild("Cash")
                if c then curCoins = c.Value end
                local reb = ls:FindFirstChild("Rebirth") or ls:FindFirstChild("Rebirths")
                if reb then State.RebirthCount = reb.Value end
            end
            
            local earned = math.max(curCoins - State.InitialCoins, 0)
            local ratePerHr = (elapsed > 10) and math.floor((earned / elapsed) * 3600) or 0
            
            hudCoins.Text = string.format("💰 Earned: +$%d  (%s/hr)", earned, tostring(ratePerHr))
            hudLogs.Text  = string.format("🪵 Chopped: %d  |  🔁 Rebirths: %d", State.ChopCount, State.RebirthCount)
        end
    end
end)

-- Safe Tree Chopping Loop
task.spawn(function()
    while true do
        task.wait(1.5)
        if State.AutoChop then
            local root = getRoot()
            local char = getChar()
            if root and char then
                local myPos = root.Position
                local bestTree, bestDist = nil, State.SafeRadius
                
                for _, obj in ipairs(workspace:GetDescendants()) do
                    if obj:IsA("Model") and obj.Name:lower():find("tree") then
                        local part = obj:FindFirstChild("Trunk") or obj.PrimaryPart or obj:FindFirstChildOfClass("BasePart")
                        if part then
                            local d = (part.Position - myPos).Magnitude
                            if d <= bestDist then
                                -- Golden priority
                                if State.GoldenPriority and (obj.Name:lower():find("gold") or obj.Name:lower():find("event")) then
                                    bestTree = obj
                                    bestDist = -1
                                    break
                                else
                                    bestTree = obj
                                    bestDist = d
                                end
                            end
                        end
                    end
                end
                
                if bestTree then
                    local trunk = bestTree:FindFirstChild("Trunk") or bestTree.PrimaryPart or bestTree:FindFirstChildOfClass("BasePart")
                    if trunk then
                        if State.AllowTeleport then
                            pcall(function()
                                root.AssemblyLinearVelocity = Vector3.zero
                                root.AssemblyAngularVelocity = Vector3.zero
                                root.CFrame = CFrame.new(trunk.Position + Vector3.new(2, 1, 0))
                            end)
                            task.wait(0.15)
                        end
                        
                        local fired = false
                        for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
                            if v:IsA("RemoteEvent") and v.Name:lower():find("chop") then
                                pcall(function() v:FireServer(bestTree) end)
                                fired = true
                                break
                            end
                        end
                        if not fired then
                            local tool = char:FindFirstChildOfClass("Tool")
                            if tool then pcall(function() tool:Activate() end) end
                        end
                        
                        State.ChopCount = State.ChopCount + 1
                    end
                end
            end
        end
    end
end)

-- Tycoon Automation Loop
task.spawn(function()
    while true do
        task.wait(2)
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if remotes then
            if State.AutoHireWorkers then
                pcall(function() remotes.HireWorker:FireServer() end)
            end
            if State.AutoUpgrade then
                pcall(function()
                    for _, u in ipairs({"TruckLevel","TruckSpeed","WorkerPower","WorkerCarry","WorkerSpeed","TreeLuck","TreeRegrow"}) do
                        remotes.BuyUpgrade:FireServer(u)
                        task.wait(0.2)
                    end
                end)
            end
            if State.AutoRebirth then
                local ls = LP:FindFirstChild("leaderstats")
                local coins = 0
                if ls then
                    local c = ls:FindFirstChild("Coins") or ls:FindFirstChild("Money") or ls:FindFirstChild("Cash")
                    if c then coins = c.Value end
                end
                if coins >= State.SmartRebirthGoal then
                    pcall(function() remotes.Rebirth:FireServer() end)
                end
            end
            if State.AutoAirportHangar then
                pcall(function()
                    local ab = remotes:FindFirstChild("AirportBuy")
                    if ab then
                        for _, h in ipairs({1, 2, 3}) do ab:FireServer(h) task.wait(0.2) end
                    end
                end)
            end
            if State.AutoAirportFlight then
                pcall(function()
                    local sp = remotes:FindFirstChild("SendPlane")
                    if sp then sp:FireServer("MapleRidge") end
                end)
            end
        end
    end
end)

-- Infinite Jump Hook
UserInputService.JumpRequest:Connect(function()
    if State.InfiniteJump then
        local hum = getHum()
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- Flight Physics Controller
RunService.RenderStepped:Connect(function()
    if State.Fly then
        local root = getRoot()
        local cam = workspace.CurrentCamera
        if root and cam then
            local bv = root:FindFirstChild("SX_FlyBV")
            if bv then
                local moveDir = Vector3.zero
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                    moveDir = moveDir + cam.CFrame.LookVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                    moveDir = moveDir - cam.CFrame.LookVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                    moveDir = moveDir - cam.CFrame.RightVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                    moveDir = moveDir + cam.CFrame.RightVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                    moveDir = moveDir + Vector3.new(0, 1, 0)
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                    moveDir = moveDir - Vector3.new(0, 1, 0)
                end
                
                if moveDir.Magnitude > 0 then
                    bv.Velocity = moveDir.Unit * State.FlySpeed
                else
                    bv.Velocity = Vector3.zero
                end
            end
        end
    end
end)

-- Noclip loop
RunService.Stepped:Connect(function()
    if not State.Noclip then return end
    local char = getChar()
    if not char then return end
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then p.CanCollide = false end
    end
end)

-- Proximity Prompts
workspace.DescendantAdded:Connect(function(d)
    if State.InstantPrompts and d:IsA("ProximityPrompt") then
        d.HoldDuration = 0
    end
end)

-- Anti-AFK
LP.Idled:Connect(function()
    if State.AntiAFK then
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end
end)

-- Floating Quick-Toggle Button for Mobile
local FloatBtn = create("TextButton", {
    Name = "SX_FloatingButton",
    Size = UDim2.fromOffset(38, 38),
    Position = UDim2.new(0, 16, 0.5, -19),
    BackgroundColor3 = Theme.Sidebar,
    BorderSizePixel = 0,
    Text = "SX",
    TextColor3 = Theme.AccentLight,
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    Parent = ScreenGui,
})
addCorner(FloatBtn, 10)
addStroke(FloatBtn, Theme.Accent, 1)

FloatBtn.MouseButton1Click:Connect(function()
    MainWindow.Visible = not MainWindow.Visible
end)

print("[SmitroniX Hub v2] Fully loaded with HUD, Waypoints, Flight, and Themes!")
