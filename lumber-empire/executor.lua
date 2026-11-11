-- ============================================================
--  Plak Corp - Lumber Empire Edition
--  Pixel-perfect recreation of Plak Corp modern dark UI
-- ============================================================

-- ── Environment & Executor Compatibility ──────────────────────
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local VirtualUser       = game:GetService("VirtualUser")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui           = game:GetService("CoreGui")

local LP = Players.LocalPlayer

-- Safe GUI container
local GuiParent = nil
local getHuiSuccess, huiResult = pcall(function()
    if typeof(gethui) == "function" then return gethui() end
    return nil
end)
if getHuiSuccess and huiResult then
    GuiParent = huiResult
else
    local coreSuccess, coreResult = pcall(function() return CoreGui end)
    if coreSuccess and coreResult then
        GuiParent = coreResult
    else
        GuiParent = LP:WaitForChild("PlayerGui")
    end
end

-- Clean previous instance
local oldGui = GuiParent:FindFirstChild("PlakCorpUI")
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

-- ── Settings State ───────────────────────────────────────────
local State = {
    -- Automation
    AutoChop         = false,
    OnlyWhenFull     = true,
    TravelMethod     = "Instant Teleport", -- "Instant Teleport", "Tween", "Walk"
    TweenSpeed       = 110,
    ChopDelay        = 0.4,
    
    -- Upgrades & Workers
    AutoHireWorkers  = false,
    AutoUpgrades     = false,
    
    -- Progression
    AutoRebirth      = false,
    
    -- Rewards
    AutoClaimRewards = false,
    
    -- Player
    WalkSpeedBoost   = false,
    WalkSpeedVal     = 25,
    Noclip           = false,
    InstantPrompts   = false,
    AntiAFK          = true,
    
    -- Visuals
    TreeESP          = false,
    Fullbright       = false,
    
    -- Live Telemetry
    CarriedItems     = 1,
    MaxCarried       = 5,
    TotalItems       = 5,
    Coins            = 110764,
    Rebirths         = 1,
    ChopCount        = 1,
    CurrentActivity  = "Collecting",
}

-- ── Color Palette (Plak Corp Theme) ──────────────────────────
local Theme = {
    BG            = Color3.fromRGB(15, 13, 22),       -- Deepest background #0f0d16
    Sidebar       = Color3.fromRGB(20, 18, 30),       -- Sidebar background #14121e
    Card          = Color3.fromRGB(24, 21, 36),       -- Card container #181524
    CardHover     = Color3.fromRGB(29, 26, 44),
    CardStroke    = Color3.fromRGB(36, 32, 54),       -- Clean subtle border
    Separator     = Color3.fromRGB(33, 29, 48),
    Accent        = Color3.fromRGB(123, 97, 255),     -- Plak Signature Purple #7b61ff
    AccentLight   = Color3.fromRGB(156, 135, 255),
    AccentDark    = Color3.fromRGB(90, 68, 205),
    ToggleOff     = Color3.fromRGB(38, 34, 56),
    ToggleOn      = Color3.fromRGB(123, 97, 255),
    TextPrimary   = Color3.fromRGB(245, 244, 250),
    TextSecondary = Color3.fromRGB(140, 135, 160),
    TextMuted     = Color3.fromRGB(95, 90, 115),
    ScrollThumb   = Color3.fromRGB(123, 97, 255),
    Green         = Color3.fromRGB(72, 212, 125),
    Red           = Color3.fromRGB(235, 75, 75),
}

-- ── UI Helper Functions ──────────────────────────────────────
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
-- ── ROOT SCREEN GUI ───────────────────────────────────────────
-- ══════════════════════════════════════════════════════════════
local ScreenGui = create("ScreenGui", {
    Name = "PlakCorpUI",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    Parent = GuiParent,
})

-- Main Window
local MainWindow = create("Frame", {
    Name = "MainWindow",
    Size = UDim2.fromOffset(720, 450),
    Position = UDim2.fromScale(0.5, 0.5),
    AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundColor3 = Theme.BG,
    BorderSizePixel = 0,
    ClipsDescendants = false,
    Parent = ScreenGui,
})
addCorner(MainWindow, 12)
addStroke(MainWindow, Theme.CardStroke, 1.2)

-- Mobile screen adaptive size
pcall(function()
    local cam = workspace.CurrentCamera
    if cam and cam.ViewportSize.X < 760 then
        local w = math.clamp(cam.ViewportSize.X - 24, 340, 720)
        local h = math.clamp(cam.ViewportSize.Y - 24, 300, 450)
        MainWindow.Size = UDim2.fromOffset(w, h)
    end
end)

-- ══════════════════════════════════════════════════════════════
-- ── DRAGGING CONTROLLER ───────────────────────────────────────
-- ══════════════════════════════════════════════════════════════
local dragging = false
local dragStart = nil
local startPos = nil

local function updateInput(input)
    local delta = input.Position - dragStart
    MainWindow.Position = UDim2.new(
        startPos.X.Scale, startPos.X.Offset + delta.X,
        startPos.Y.Scale, startPos.Y.Offset + delta.Y
    )
end

-- ══════════════════════════════════════════════════════════════
-- ── SIDEBAR (LEFT) ────────────────────────────────────────────
-- ══════════════════════════════════════════════════════════════
local Sidebar = create("Frame", {
    Name = "Sidebar",
    Size = UDim2.new(0, 180, 1, 0),
    Position = UDim2.fromOffset(0, 0),
    BackgroundColor3 = Theme.Sidebar,
    BorderSizePixel = 0,
    Parent = MainWindow,
})
addCorner(Sidebar, 12)

-- Straighten right corner with a spacer frame
local SidebarStraightener = create("Frame", {
    Name = "Straightener",
    Size = UDim2.new(0, 12, 1, 0),
    Position = UDim2.new(1, -12, 0, 0),
    BackgroundColor3 = Theme.Sidebar,
    BorderSizePixel = 0,
    Parent = Sidebar,
})

-- Separator line between sidebar and content
local VerticalSep = create("Frame", {
    Name = "VerticalSeparator",
    Size = UDim2.new(0, 1, 1, 0),
    Position = UDim2.new(1, 0, 0, 0),
    BackgroundColor3 = Theme.Separator,
    BorderSizePixel = 0,
    Parent = Sidebar,
})

-- Sidebar Drag Listener
Sidebar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainWindow.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)
Sidebar.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        updateInput(input)
    end
end)

-- ── Logo & Brand Header ───────────────────────────────────────
local BrandFrame = create("Frame", {
    Name = "BrandHeader",
    Size = UDim2.new(1, 0, 0, 56),
    BackgroundTransparency = 1,
    Parent = Sidebar,
})

-- Stylized Diagonal Waves Icon
local LogoIcon = create("Frame", {
    Name = "LogoIcon",
    Size = UDim2.fromOffset(24, 20),
    Position = UDim2.fromOffset(18, 18),
    BackgroundTransparency = 1,
    Parent = BrandFrame,
})
for i = 1, 3 do
    local bar = create("Frame", {
        Size = UDim2.new(0, 4, 1, 0),
        Position = UDim2.fromOffset((i - 1) * 7, (3 - i) * 2),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Rotation = 25,
        Parent = LogoIcon,
    })
    addCorner(bar, 2)
end

local BrandTitle = create("TextLabel", {
    Name = "BrandTitle",
    Size = UDim2.new(1, -54, 1, 0),
    Position = UDim2.fromOffset(50, 0),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamBold,
    Text = "Plak",
    TextColor3 = Theme.TextPrimary,
    TextSize = 16,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = BrandFrame,
})

local BrandSub = create("TextLabel", {
    Name = "BrandSub",
    Size = UDim2.fromOffset(40, 20),
    Position = UDim2.fromOffset(92, 19),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamMedium,
    Text = "CORP.",
    TextColor3 = Theme.TextMuted,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = BrandFrame,
})

-- ── Section: GENERAL ──────────────────────────────────────────
local SectionGeneral = create("TextLabel", {
    Name = "SectionGeneral",
    Size = UDim2.new(1, -36, 0, 20),
    Position = UDim2.fromOffset(18, 56),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamBold,
    Text = "GENERAL",
    TextColor3 = Theme.TextMuted,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = Sidebar,
})

-- ── Navigation Container ──────────────────────────────────────
local NavList = create("Frame", {
    Name = "NavList",
    Size = UDim2.new(1, -20, 1, -130),
    Position = UDim2.fromOffset(10, 80),
    BackgroundTransparency = 1,
    Parent = Sidebar,
})
local navLayout = create("UIListLayout", {
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 4),
    Parent = NavList,
})

-- ── Bottom Settings Button ────────────────────────────────────
local BottomSettings = create("TextButton", {
    Name = "BottomSettings",
    Size = UDim2.fromOffset(32, 32),
    Position = UDim2.new(0, 16, 1, -44),
    BackgroundColor3 = Theme.Card,
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    Text = "⚙",
    TextColor3 = Theme.TextSecondary,
    TextSize = 16,
    Font = Enum.Font.GothamBold,
    Parent = Sidebar,
})
addCorner(BottomSettings, 6)

-- ══════════════════════════════════════════════════════════════
-- ── MAIN CONTENT AREA (RIGHT) ─────────────────────────────────
-- ══════════════════════════════════════════════════════════════
local ContentArea = create("Frame", {
    Name = "ContentArea",
    Size = UDim2.new(1, -181, 1, 0),
    Position = UDim2.fromOffset(181, 0),
    BackgroundTransparency = 1,
    ClipsDescendants = true,
    Parent = MainWindow,
})

-- Content Top Drag Listener
ContentArea.InputBegan:Connect(function(input)
    if input.Position.Y < (MainWindow.AbsolutePosition.Y + 60) then
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = MainWindow.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end
end)
ContentArea.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        updateInput(input)
    end
end)

-- Top Header Frame
local HeaderFrame = create("Frame", {
    Name = "HeaderFrame",
    Size = UDim2.new(1, 0, 0, 78),
    BackgroundTransparency = 1,
    Parent = ContentArea,
})

local HeaderTitle = create("TextLabel", {
    Name = "HeaderTitle",
    Size = UDim2.new(1, -60, 0, 24),
    Position = UDim2.fromOffset(24, 12),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamBold,
    Text = "Farm",
    TextColor3 = Theme.TextPrimary,
    TextSize = 20,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = HeaderFrame,
})

local HeaderSubtitle = create("TextLabel", {
    Name = "HeaderSubtitle",
    Size = UDim2.new(1, -60, 0, 16),
    Position = UDim2.fromOffset(24, 34),
    BackgroundTransparency = 1,
    Font = Enum.Font.Gotham,
    Text = "Lumber loop",
    TextColor3 = Theme.TextSecondary,
    TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = HeaderFrame,
})

-- Close / Minimize Controls in Header
local CloseBtn = create("TextButton", {
    Name = "CloseBtn",
    Size = UDim2.fromOffset(24, 24),
    Position = UDim2.new(1, -34, 0, 14),
    BackgroundColor3 = Theme.Card,
    BackgroundTransparency = 0.5,
    Text = "✕",
    TextColor3 = Theme.TextSecondary,
    TextSize = 11,
    Font = Enum.Font.GothamBold,
    Parent = HeaderFrame,
})
addCorner(CloseBtn, 6)
CloseBtn.MouseButton1Click:Connect(function()
    MainWindow.Visible = false
end)

-- ── Horizontal Sub-Tabs Row ───────────────────────────────────
local SubTabsBar = create("Frame", {
    Name = "SubTabsBar",
    Size = UDim2.new(1, -48, 0, 26),
    Position = UDim2.fromOffset(24, 52),
    BackgroundTransparency = 1,
    Parent = HeaderFrame,
})

local SubTabIndicator = create("Frame", {
    Name = "SubTabIndicator",
    Size = UDim2.new(0, 80, 0, 2),
    Position = UDim2.new(0, 0, 1, -2),
    BackgroundColor3 = Theme.Accent,
    BorderSizePixel = 0,
    Parent = SubTabsBar,
})

-- Header Bottom Separator Line
local HeaderSep = create("Frame", {
    Name = "HeaderSeparator",
    Size = UDim2.new(1, 0, 0, 1),
    Position = UDim2.new(0, 0, 1, -1),
    BackgroundColor3 = Theme.Separator,
    BorderSizePixel = 0,
    Parent = HeaderFrame,
})

-- ── Main Scroll View for Cards ────────────────────────────────
local PageContainer = create("Frame", {
    Name = "PageContainer",
    Size = UDim2.new(1, 0, 1, -78),
    Position = UDim2.fromOffset(0, 78),
    BackgroundTransparency = 1,
    Parent = ContentArea,
})

-- Navigation and Tab Registries
local NavButtons = {}
local MainPages = {}
local SubPages = {}
local CurrentMainPage = nil
local CurrentSubTab = nil

-- Function to create scroll page
local function createScrollPage(name)
    local scroll = create("ScrollingFrame", {
        Name = name,
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
    local layout = create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 8),
        Parent = scroll,
    })
    local padding = create("UIPadding", {
        PaddingTop = UDim.new(0, 4),
        PaddingBottom = UDim.new(0, 16),
        PaddingLeft = UDim.new(0, 4),
        PaddingRight = UDim.new(0, 8),
        Parent = scroll,
    })
    return scroll
end

-- ══════════════════════════════════════════════════════════════
-- ── WIDGET BUILDERS (MATCHING SCREENSHOT) ─────────────────────
-- ══════════════════════════════════════════════════════════════

-- 1. Sleek Card Container
local function createCard(parent, height)
    local card = create("Frame", {
        Size = UDim2.new(1, 0, 0, height or 54),
        BackgroundColor3 = Theme.Card,
        BorderSizePixel = 0,
        Parent = parent,
    })
    addCorner(card, 8)
    addStroke(card, Theme.CardStroke, 1)
    return card
end

-- 2. Toggle Card ("Only when full")
local function addToggleCard(parent, title, subtitle, defaultState, onToggle)
    local card = createCard(parent, 52)
    
    local titleLbl = create("TextLabel", {
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
    
    local subLbl = create("TextLabel", {
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
    
    -- iOS Style Pill Switch
    local switch = create("Frame", {
        Size = UDim2.fromOffset(40, 20),
        Position = UDim2.new(1, -54, 0.5, -10),
        BackgroundColor3 = defaultState and Theme.ToggleOn or Theme.ToggleOff,
        BorderSizePixel = 0,
        Parent = card,
    })
    addCorner(switch, 10)
    
    local knob = create("Frame", {
        Size = UDim2.fromOffset(16, 16),
        Position = defaultState and UDim2.fromOffset(21, 2) or UDim2.fromOffset(2, 2),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        Parent = switch,
    })
    addCorner(knob, 8)
    
    local isToggled = defaultState
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
        if onToggle then onToggle(isToggled) end
    end)
    
    return card
end

-- 3. Collapsible Accordion Group Box ("Live status" / "Travel")
local function addAccordion(parent, icon, title, subtitle)
    local card = createCard(parent, 44)
    card.ClipsDescendants = true
    
    -- Header Row (Always visible)
    local header = create("TextButton", {
        Size = UDim2.new(1, 0, 0, 44),
        BackgroundTransparency = 1,
        Text = "",
        Parent = card,
    })
    
    local iconLbl = create("TextLabel", {
        Size = UDim2.fromOffset(20, 20),
        Position = UDim2.fromOffset(14, 12),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = icon or "⚡",
        TextColor3 = Theme.Accent,
        TextSize = 13,
        Parent = header,
    })
    
    local titleLbl = create("TextLabel", {
        Size = UDim2.new(0, 120, 0, 20),
        Position = UDim2.fromOffset(40, 12),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = title,
        TextColor3 = Theme.TextPrimary,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = header,
    })
    
    local subLbl = create("TextLabel", {
        Size = UDim2.new(1, -210, 0, 20),
        Position = UDim2.fromOffset(160, 12),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = subtitle or "",
        TextColor3 = Theme.TextSecondary,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = header,
    })
    
    local chevron = create("TextLabel", {
        Size = UDim2.fromOffset(20, 20),
        Position = UDim2.new(1, -34, 0, 12),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = "▲",
        TextColor3 = Theme.TextSecondary,
        TextSize = 11,
        Parent = header,
    })
    
    -- Content Container
    local content = create("Frame", {
        Size = UDim2.new(1, -28, 0, 0),
        Position = UDim2.fromOffset(14, 46),
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = card,
    })
    local contentLayout = create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 8),
        Parent = content,
    })
    
    local isOpen = true
    local function updateAccordion()
        if isOpen then
            chevron.Text = "▲"
            card.AutomaticSize = Enum.AutomaticSize.Y
        else
            chevron.Text = "▼"
            card.AutomaticSize = Enum.AutomaticSize.None
            card.Size = UDim2.new(1, 0, 0, 44)
        end
    end
    
    header.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        updateAccordion()
    end)
    
    updateAccordion()
    return content
end

-- 4. Status Indicator Row inside Accordion
local function addStatusRow(parent, labelText, initialStatus)
    local row = create("Frame", {
        Size = UDim2.new(1, 0, 0, 48),
        BackgroundTransparency = 1,
        Parent = parent,
    })
    
    local lbl = create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 16),
        Position = UDim2.fromOffset(0, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = labelText,
        TextColor3 = Theme.TextMuted,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row,
    })
    
    local valBox = create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 24),
        Position = UDim2.fromOffset(0, 20),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        Text = initialStatus or "Idle",
        TextColor3 = Theme.TextSecondary,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row,
    })
    
    return valBox
end

-- 5. Dropdown Row inside Accordion
local function addDropdownRow(parent, labelText, descText, options, defaultOption, onSelect)
    local row = create("Frame", {
        Size = UDim2.new(1, 0, 0, 44),
        BackgroundTransparency = 1,
        ClipsDescendants = false,
        Parent = parent,
    })
    
    local lbl = create("TextLabel", {
        Size = UDim2.new(0, 160, 0, 16),
        Position = UDim2.fromOffset(0, 4),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = labelText,
        TextColor3 = Theme.TextPrimary,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row,
    })
    
    local desc = create("TextLabel", {
        Size = UDim2.new(0, 160, 0, 14),
        Position = UDim2.fromOffset(0, 22),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = descText or "",
        TextColor3 = Theme.TextMuted,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row,
    })
    
    local dropBtn = create("TextButton", {
        Size = UDim2.fromOffset(150, 30),
        Position = UDim2.new(1, -150, 0.5, -15),
        BackgroundColor3 = Theme.BG,
        BorderSizePixel = 0,
        Font = Enum.Font.GothamMedium,
        Text = defaultOption .. "  ▾",
        TextColor3 = Theme.TextPrimary,
        TextSize = 11,
        Parent = row,
    })
    addCorner(dropBtn, 6)
    addStroke(dropBtn, Theme.CardStroke, 1)
    
    -- Dropdown Menu List
    local menu = create("Frame", {
        Size = UDim2.new(1, 0, 0, #options * 26 + 6),
        Position = UDim2.new(0, 0, 1, 4),
        BackgroundColor3 = Theme.Sidebar,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 20,
        Parent = dropBtn,
    })
    addCorner(menu, 6)
    addStroke(menu, Theme.Accent, 1)
    
    local menuList = create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 2),
        Parent = menu,
    })
    create("UIPadding", {
        PaddingTop = UDim.new(0, 3),
        PaddingLeft = UDim.new(0, 4),
        PaddingRight = UDim.new(0, 4),
        Parent = menu,
    })
    
    for _, opt in ipairs(options) do
        local optBtn = create("TextButton", {
            Size = UDim2.new(1, 0, 0, 24),
            BackgroundTransparency = 1,
            Font = Enum.Font.Gotham,
            Text = opt,
            TextColor3 = (opt == defaultOption) and Theme.Accent or Theme.TextSecondary,
            TextSize = 11,
            ZIndex = 21,
            Parent = menu,
        })
        optBtn.MouseButton1Click:Connect(function()
            dropBtn.Text = opt .. "  ▾"
            menu.Visible = false
            if onSelect then onSelect(opt) end
        end)
    end
    
    dropBtn.MouseButton1Click:Connect(function()
        menu.Visible = not menu.Visible
    end)
    
    return dropBtn
end

-- 6. Slider Row inside Accordion
local function addSliderRow(parent, labelText, descText, minVal, maxVal, defaultVal, suffix, onChange)
    local row = create("Frame", {
        Size = UDim2.new(1, 0, 0, 46),
        BackgroundTransparency = 1,
        Parent = parent,
    })
    
    local lbl = create("TextLabel", {
        Size = UDim2.new(0, 140, 0, 16),
        Position = UDim2.fromOffset(0, 4),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = labelText,
        TextColor3 = Theme.TextPrimary,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row,
    })
    
    local desc = create("TextLabel", {
        Size = UDim2.new(0, 140, 0, 14),
        Position = UDim2.fromOffset(0, 22),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = descText or "",
        TextColor3 = Theme.TextMuted,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row,
    })
    
    local valDisplay = create("TextLabel", {
        Size = UDim2.fromOffset(80, 20),
        Position = UDim2.new(1, -215, 0.5, -10),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        Text = tostring(defaultVal) .. " " .. (suffix or ""),
        TextColor3 = Theme.TextSecondary,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = row,
    })
    
    local track = create("Frame", {
        Size = UDim2.fromOffset(120, 6),
        Position = UDim2.new(1, -130, 0.5, -3),
        BackgroundColor3 = Theme.ToggleOff,
        BorderSizePixel = 0,
        Parent = row,
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
            if onChange then onChange(calcVal) end
        end
    end)
    
    return row
end

-- ══════════════════════════════════════════════════════════════
-- ── BUILD PAGES AND TABS ──────────────────────────────────────
-- ══════════════════════════════════════════════════════════════

-- Create Pages
local PageFarmAuto   = createScrollPage("Farm_Automation")
local PageFarmUpgr   = createScrollPage("Farm_Upgrades")
local PageFarmProg   = createScrollPage("Farm_Progression")
local PageFarmRew    = createScrollPage("Farm_Rewards")
local PagePlayer     = createScrollPage("Player_Main")
local PageVisuals    = createScrollPage("Visuals_Main")

-- Page Switcher Logic
local function switchMainPage(pageName)
    CurrentMainPage = pageName
    HeaderTitle.Text = pageName
    
    -- Sub-tabs bar only appears on "Farm" page
    if pageName == "Farm" then
        HeaderSubtitle.Text = "Lumber loop"
        SubTabsBar.Visible = true
        HeaderFrame.Size = UDim2.new(1, 0, 0, 78)
        PageContainer.Position = UDim2.fromOffset(0, 78)
        PageContainer.Size = UDim2.new(1, 0, 1, -78)
    else
        SubTabsBar.Visible = false
        HeaderSubtitle.Text = (pageName == "Player") and "Character enhancements" or "Rendering & ESP"
        HeaderFrame.Size = UDim2.new(1, 0, 0, 56)
        PageContainer.Position = UDim2.fromOffset(0, 56)
        PageContainer.Size = UDim2.new(1, 0, 1, -56)
    end
    
    -- Hide all pages
    PageFarmAuto.Visible = false
    PageFarmUpgr.Visible = false
    PageFarmProg.Visible = false
    PageFarmRew.Visible = false
    PagePlayer.Visible = false
    PageVisuals.Visible = false
    
    -- Show active
    if pageName == "Farm" then
        if CurrentSubTab == "Upgrades" then
            PageFarmUpgr.Visible = true
        elseif CurrentSubTab == "Progression" then
            PageFarmProg.Visible = true
        elseif CurrentSubTab == "Rewards" then
            PageFarmRew.Visible = true
        else
            PageFarmAuto.Visible = true
        end
    elseif pageName == "Player" then
        PagePlayer.Visible = true
    elseif pageName == "Visuals" then
        PageVisuals.Visible = true
    end
    
    -- Update Nav Buttons
    for name, btn in pairs(NavButtons) do
        local active = (name == pageName)
        tween(btn, {
            BackgroundColor3 = active and Theme.ActiveNav or Theme.Sidebar,
            BackgroundTransparency = active and 0 or 1,
        }, 0.15)
        local icon = btn:FindFirstChild("Icon")
        local text = btn:FindFirstChild("Text")
        if icon then icon.TextColor3 = active and Theme.AccentLight or Theme.TextSecondary end
        if text then text.TextColor3 = active and Theme.ActiveNavText or Theme.TextSecondary end
    end
end

-- Sub-tab Switcher
local function switchSubTab(subTabName, subTabBtn)
    CurrentSubTab = subTabName
    
    -- Animate Indicator
    if subTabBtn then
        tween(SubTabIndicator, {
            Position = UDim2.new(0, subTabBtn.Position.X.Offset, 1, -2),
            Size = UDim2.new(0, subTabBtn.Size.X.Offset, 0, 2),
        }, 0.2)
    end
    
    if CurrentMainPage == "Farm" then
        PageFarmAuto.Visible = (subTabName == "Automation")
        PageFarmUpgr.Visible = (subTabName == "Upgrades")
        PageFarmProg.Visible = (subTabName == "Progression")
        PageFarmRew.Visible  = (subTabName == "Rewards")
    end
end

-- Add Nav Item
local function addNavItem(name, iconChar)
    local btn = create("TextButton", {
        Name = "Nav_" .. name,
        Size = UDim2.new(1, 0, 0, 36),
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
        Position = UDim2.fromOffset(10, 6),
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
        Position = UDim2.fromOffset(40, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        Text = name,
        TextColor3 = Theme.TextSecondary,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = btn,
    })
    
    btn.MouseButton1Click:Connect(function()
        switchMainPage(name)
    end)
    
    NavButtons[name] = btn
    return btn
end

-- Populate Nav
addNavItem("Farm", "🪓")
addNavItem("Player", "👤")
addNavItem("Visuals", "🎯")

-- Add SubTabs to Header
local subTabNames = {"Automation", "Upgrades", "Progression", "Rewards"}
local subTabButtons = {}
local curX = 0

for _, sName in ipairs(subTabNames) do
    local textWidth = (#sName * 8) + 16
    local stb = create("TextButton", {
        Name = "SubTab_" .. sName,
        Size = UDim2.fromOffset(textWidth, 24),
        Position = UDim2.fromOffset(curX, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        Text = sName,
        TextColor3 = (sName == "Automation") and Theme.TextPrimary or Theme.TextSecondary,
        TextSize = 12,
        Parent = SubTabsBar,
    })
    curX = curX + textWidth + 8
    subTabButtons[sName] = stb
    
    stb.MouseButton1Click:Connect(function()
        for _, b in pairs(subTabButtons) do
            b.TextColor3 = Theme.TextSecondary
        end
        stb.TextColor3 = Theme.TextPrimary
        switchSubTab(sName, stb)
    end)
end

-- ══════════════════════════════════════════════════════════════
-- ── FILL FARM > AUTOMATION PAGE (EXACT SCREENSHOT MATCH) ──────
-- ══════════════════════════════════════════════════════════════

-- 1. Main Auto Farm Toggle
addToggleCard(PageFarmAuto, "Auto Farm (Lumber Loop)", "Automatically harvest trees & sell wood", State.AutoChop, function(on)
    State.AutoChop = on
    if on then State.CurrentActivity = "Harvesting trees" else State.CurrentActivity = "Idle" end
end)

-- 2. "Only when full" Toggle Card
addToggleCard(PageFarmAuto, "Only when full", "Wait for a full load", State.OnlyWhenFull, function(on)
    State.OnlyWhenFull = on
end)

-- 3. "Live status" Accordion Group
local liveStatusGroup = addAccordion(PageFarmAuto, "🪓", "Live status", "1 setting")
local activityValueLbl = addStatusRow(liveStatusGroup, "Activity", "Collecting | 1/5 carried · Items 1/5 · $110764 | rebirth 1 | 1 chops")

-- 4. "Travel" Accordion Group
local travelGroup = addAccordion(PageFarmAuto, "🧭", "Travel", "How the character moves")

-- Method dropdown
addDropdownRow(travelGroup, "Method", "How to reach a target", {"Instant Teleport", "Tween", "Walk"}, State.TravelMethod, function(selected)
    State.TravelMethod = selected
end)

-- Tween speed slider
addSliderRow(travelGroup, "Tween speed", "Studs per second", 20, 250, State.TweenSpeed, "studs/s", function(val)
    State.TweenSpeed = val
end)

-- ══════════════════════════════════════════════════════════════
-- ── FILL FARM > UPGRADES PAGE ─────────────────────────────────
-- ══════════════════════════════════════════════════════════════
addToggleCard(PageFarmUpgr, "Auto Upgrade Workers & Trucks", "Buys upgrades automatically when coins allow", State.AutoUpgrades, function(on)
    State.AutoUpgrades = on
end)

addToggleCard(PageFarmUpgr, "Auto Hire Workers", "Spawns new workers to automate your sawmill", State.AutoHireWorkers, function(on)
    State.AutoHireWorkers = on
end)

-- Manual Action Card
local manualUpgrCard = createCard(PageFarmUpgr, 48)
local manualUpgrBtn = create("TextButton", {
    Size = UDim2.new(1, -24, 1, -12),
    Position = UDim2.fromOffset(12, 6),
    BackgroundColor3 = Theme.AccentDark,
    Text = "⚡ Purchase Available Upgrades Now",
    TextColor3 = Theme.TextPrimary,
    Font = Enum.Font.GothamBold,
    TextSize = 12,
    Parent = manualUpgrCard,
})
addCorner(manualUpgrBtn, 6)
manualUpgrBtn.MouseButton1Click:Connect(function()
    pcall(function()
        for _, name in ipairs({"ChopSpeed","LogValue","WorkerSpeed","AutoSell","BuyUpgrade","Upgrade"}) do
            for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
                if v:IsA("RemoteEvent") and v.Name:lower():find(name:lower()) then
                    v:FireServer()
                end
            end
        end
    end)
end)

-- ══════════════════════════════════════════════════════════════
-- ── FILL FARM > PROGRESSION PAGE ──────────────────────────────
-- ══════════════════════════════════════════════════════════════
addToggleCard(PageFarmProg, "Auto Rebirth", "Triggers rebirth immediately when requirements met", State.AutoRebirth, function(on)
    State.AutoRebirth = on
end)

local rebirthNowCard = createCard(PageFarmProg, 48)
local rebirthNowBtn = create("TextButton", {
    Size = UDim2.new(1, -24, 1, -12),
    Position = UDim2.fromOffset(12, 6),
    BackgroundColor3 = Theme.Red,
    Text = "🔁 Execute Rebirth Immediately",
    TextColor3 = Theme.TextPrimary,
    Font = Enum.Font.GothamBold,
    TextSize = 12,
    Parent = rebirthNowCard,
})
addCorner(rebirthNowBtn, 6)
rebirthNowBtn.MouseButton1Click:Connect(function()
    pcall(function()
        for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
            if v:IsA("RemoteEvent") and v.Name:lower():find("rebirth") then
                v:FireServer()
            end
        end
    end)
end)

-- ══════════════════════════════════════════════════════════════
-- ── FILL FARM > REWARDS PAGE ──────────────────────────────────
-- ══════════════════════════════════════════════════════════════
addToggleCard(PageFarmRew, "Auto Claim Gifts & Rewards", "Claims playtime and free daily rewards", State.AutoClaimRewards, function(on)
    State.AutoClaimRewards = on
end)

-- ══════════════════════════════════════════════════════════════
-- ── FILL PLAYER PAGE ──────────────────────────────────────────
-- ══════════════════════════════════════════════════════════════
addToggleCard(PagePlayer, "Walk Speed Boost", "Increase your default movement speed", State.WalkSpeedBoost, function(on)
    State.WalkSpeedBoost = on
    local hum = getHum()
    if hum then hum.WalkSpeed = on and State.WalkSpeedVal or 16 end
end)

local speedSliderCard = createCard(PagePlayer, 50)
addSliderRow(speedSliderCard, "Speed Amount", "Standard is 16", 16, 160, State.WalkSpeedVal, "speed", function(val)
    State.WalkSpeedVal = val
    if State.WalkSpeedBoost then
        local hum = getHum()
        if hum then hum.WalkSpeed = val end
    end
end)

addToggleCard(PagePlayer, "Noclip", "Walk through trees, walls and boundaries", State.Noclip, function(on)
    State.Noclip = on
end)

addToggleCard(PagePlayer, "Instant Prompts", "Zero hold-down duration for all interactions", State.InstantPrompts, function(on)
    State.InstantPrompts = on
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("ProximityPrompt") then v.HoldDuration = on and 0 or 1 end
    end
end)

addToggleCard(PagePlayer, "Anti-AFK", "Prevents Roblox 20-minute idle disconnection", State.AntiAFK, function(on)
    State.AntiAFK = on
end)

-- ══════════════════════════════════════════════════════════════
-- ── FILL VISUALS PAGE ─────────────────────────────────────────
-- ══════════════════════════════════════════════════════════════
addToggleCard(PageVisuals, "Tree ESP Chams", "Draws highlights over all living harvestable trees", State.TreeESP, function(on)
    State.TreeESP = on
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name:lower():find("tree") then
            local highlight = obj:FindFirstChild("PlakESP")
            if on and not highlight then
                local h = create("Highlight", {
                    Name = "PlakESP",
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

addToggleCard(PageVisuals, "Fullbright", "Brightens the entire map for maximum visibility", State.Fullbright, function(on)
    State.Fullbright = on
    local lighting = game:GetService("Lighting")
    if on then
        lighting.Brightness = 2
        lighting.ClockTime = 14
        lighting.GlobalShadows = false
    else
        lighting.Brightness = 1
        lighting.GlobalShadows = true
    end
end)

-- Set initial main page and subtab
switchMainPage("Farm")
switchSubTab("Automation", subTabButtons["Automation"])

-- ══════════════════════════════════════════════════════════════
-- ── GAME AUTOMATION & TELEMETRY LOOPS ─────────────────────────
-- ══════════════════════════════════════════════════════════════

-- Movement Handler (Teleport, Tween, Walk)
local function moveToTarget(targetPosition)
    local root = getRoot()
    local char = getChar()
    local hum  = getHum()
    if not root or not char then return end
    
    if State.TravelMethod == "Instant Teleport" then
        root.CFrame = CFrame.new(targetPosition + Vector3.new(0, 2, 0))
    elseif State.TravelMethod == "Tween" then
        local dist = (root.Position - targetPosition).Magnitude
        local dur = math.max(dist / State.TweenSpeed, 0.05)
        local tw = TweenService:Create(root, TweenInfo.new(dur, Enum.EasingStyle.Linear), {
            CFrame = CFrame.new(targetPosition + Vector3.new(0, 2, 0))
        })
        tw:Play()
        tw.Completed:Wait()
    elseif State.TravelMethod == "Walk" then
        if hum then
            hum:MoveTo(targetPosition)
            hum.MoveToFinished:Wait()
        end
    end
end

-- Auto Chop & Farm Loop
task.spawn(function()
    while true do
        task.wait(math.max(State.ChopDelay, 0.1))
        if State.AutoChop then
            local root = getRoot()
            local char = getChar()
            if root and char then
                -- Locate nearest tree
                local bestTree, bestDist = nil, math.huge
                for _, obj in ipairs(workspace:GetDescendants()) do
                    if obj:IsA("Model") and obj.Name:lower():find("tree") then
                        local part = obj:FindFirstChild("Trunk") or obj.PrimaryPart or obj:FindFirstChildOfClass("BasePart")
                        if part then
                            local d = (part.Position - root.Position).Magnitude
                            if d < bestDist then
                                bestTree = obj
                                bestDist = d
                            end
                        end
                    end
                end
                
                if bestTree then
                    local trunk = bestTree:FindFirstChild("Trunk") or bestTree.PrimaryPart or bestTree:FindFirstChildOfClass("BasePart")
                    if trunk then
                        State.CurrentActivity = "Navigating to tree"
                        moveToTarget(trunk.Position + Vector3.new(2, 0, 0))
                        
                        State.CurrentActivity = "Chopping tree"
                        State.ChopCount = State.ChopCount + 1
                        
                        -- Fire Chop Remote
                        local fired = false
                        for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
                            if v:IsA("RemoteEvent") and v.Name:lower():find("chop") then
                                pcall(function() v:FireServer(bestTree) end)
                                fired = true
                                break
                            end
                        end
                        
                        -- Fallback: Use tool
                        if not fired then
                            local tool = char:FindFirstChildOfClass("Tool")
                            if tool then
                                pcall(function() tool:Activate() end)
                            end
                        end
                        
                        task.wait(0.2)
                        State.CarriedItems = math.min(State.CarriedItems + 1, State.MaxCarried)
                        
                        -- Check "Only when full"
                        if State.OnlyWhenFull and State.CarriedItems >= State.MaxCarried then
                            State.CurrentActivity = "Returning load to truck"
                            -- Look for sell area or truck
                            for _, s in ipairs(workspace:GetDescendants()) do
                                if s.Name:lower():find("sell") or s.Name:lower():find("truck") then
                                    local sPart = s:IsA("BasePart") and s or s:FindFirstChildOfClass("BasePart")
                                    if sPart then
                                        moveToTarget(sPart.Position)
                                        task.wait(0.5)
                                        State.CarriedItems = 0
                                        break
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- Live Status Telemetry Updater Loop
task.spawn(function()
    while true do
        task.wait(0.5)
        if activityValueLbl then
            -- Fetch player stats if available in leaderstats
            local ls = LP:FindFirstChild("leaderstats")
            if ls then
                local coinsObj = ls:FindFirstChild("Coins") or ls:FindFirstChild("Money") or ls:FindFirstChild("Cash")
                if coinsObj then State.Coins = coinsObj.Value end
                local rebObj = ls:FindFirstChild("Rebirth") or ls:FindFirstChild("Rebirths")
                if rebObj then State.Rebirths = rebObj.Value end
            end
            
            activityValueLbl.Text = string.format(
                "%s | %d/%d carried · Items %d · $%s | rebirth %d | %d chops",
                State.CurrentActivity,
                State.CarriedItems,
                State.MaxCarried,
                State.TotalItems,
                tostring(State.Coins),
                State.Rebirths,
                State.ChopCount
            )
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

-- Proximity Prompt Hook
workspace.DescendantAdded:Connect(function(d)
    if State.InstantPrompts and d:IsA("ProximityPrompt") then
        d.HoldDuration = 0
    end
end)

-- Anti-AFK Hook
LP.Idled:Connect(function()
    if State.AntiAFK then
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end
end)

-- Auto Rebirth & Upgrades
task.spawn(function()
    while true do
        task.wait(2)
        if State.AutoRebirth then
            for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
                if v:IsA("RemoteEvent") and v.Name:lower():find("rebirth") then
                    pcall(function() v:FireServer() end)
                end
            end
        end
        if State.AutoUpgrades then
            for _, name in ipairs({"ChopSpeed","LogValue","WorkerSpeed","AutoSell","BuyUpgrade","Upgrade"}) do
                for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
                    if v:IsA("RemoteEvent") and v.Name:lower():find(name:lower()) then
                        pcall(function() v:FireServer() end)
                    end
                end
            end
        end
        if State.AutoHireWorkers then
            for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
                if v:IsA("RemoteEvent") and (v.Name:lower():find("hireworker") or v.Name:lower():find("hire")) then
                    pcall(function() v:FireServer() end)
                end
            end
        end
    end
end)

-- Floating Toggle Button for Mobile / Small Screens
local FloatingIcon = create("TextButton", {
    Name = "PlakFloatingToggle",
    Size = UDim2.fromOffset(38, 38),
    Position = UDim2.new(0, 16, 0.5, -19),
    BackgroundColor3 = Theme.Sidebar,
    BorderSizePixel = 0,
    Text = "🪓",
    TextColor3 = Theme.AccentLight,
    TextSize = 16,
    Parent = ScreenGui,
})
addCorner(FloatingIcon, 10)
addStroke(FloatingIcon, Theme.Accent, 1)

FloatingIcon.MouseButton1Click:Connect(function()
    MainWindow.Visible = not MainWindow.Visible
end)

print("[Plak Corp] UI loaded successfully! ScreenGui: " .. GuiParent.Name)
