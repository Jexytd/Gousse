--[[
    ========================================================================
    GousseUI - Authentic Modern Game Utility UI Library (v2.1.0)
    Engineered for Gousse Hub & Roblox Execution Environments
    ========================================================================
    Design Direction & Features:
      - Modern tactical gaming aesthetic (deep obsidian slate #0B0E14 & #131923)
      - High-contrast BuilderSans typography hierarchy (WCAG AAA readability)
      - Refined 2px emerald top accent bar preserving Gousse Hub brand identity
      - Lucide icon engine with vector assets
      - Fully responsive layout: adaptive desktop (640x420) & mobile scaling
      - Draggable Mobile Floating Action Button (FAB) for seamless touch access
      - Fitts's Law touch targets (min 44px) & full-row interactive toggles
      - Safe parenting via gethui() -> CoreGui -> PlayerGui
    ========================================================================
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

-- Safe Parent Resolver
local function GetSafeGuiParent(): Instance
    if gethui then
        local ok, hui = pcall(gethui)
        if ok and hui then return hui end
    end
    local okCore, cg = pcall(function() return CoreGui end)
    if okCore and cg then return cg end
    if LocalPlayer then
        return LocalPlayer:WaitForChild("PlayerGui")
    end
    return game:GetService("CoreGui")
end

-- ============================================================================
-- Lucide Icons Engine
-- ============================================================================
local RawIcons = {
	["accessibility"] = "rbxassetid://10709751939",
	["activity"] = "rbxassetid://10709752035",
	["air-vent"] = "rbxassetid://10709752131",
	["alarm-check"] = "rbxassetid://10709752405",
	["alarm-clock"] = "rbxassetid://10709752630",
	["alert-circle"] = "rbxassetid://10709752996",
	["alert-triangle"] = "rbxassetid://10709753149",
	["arrow-right"] = "rbxassetid://10709768347",
	["arrow-up"] = "rbxassetid://10709768939",
	["arrow-down"] = "rbxassetid://10709767827",
	["bar-chart-2"] = "rbxassetid://10709770317",
	["bell"] = "rbxassetid://10709775704",
	["box"] = "rbxassetid://10709782497",
	["check"] = "rbxassetid://10709790644",
	["check-circle"] = "rbxassetid://10709790387",
	["chevron-down"] = "rbxassetid://10709790948",
	["chevron-right"] = "rbxassetid://10709791437",
	["chevron-up"] = "rbxassetid://10709791523",
	["circle"] = "rbxassetid://10709798174",
	["clipboard"] = "rbxassetid://10709799288",
	["clock"] = "rbxassetid://10709805144",
	["code"] = "rbxassetid://10709810463",
	["cog"] = "rbxassetid://10709810948",
	["command"] = "rbxassetid://10709811365",
	["compass"] = "rbxassetid://10709811445",
	["copy"] = "rbxassetid://10709812159",
	["crosshair"] = "rbxassetid://10709818534",
	["database"] = "rbxassetid://10709818996",
	["download"] = "rbxassetid://10723344270",
	["edit-3"] = "rbxassetid://10723345088",
	["external-link"] = "rbxassetid://10723346684",
	["eye"] = "rbxassetid://10723346959",
	["eye-off"] = "rbxassetid://10723346871",
	["file-text"] = "rbxassetid://10723367380",
	["filter"] = "rbxassetid://10723375128",
	["flame"] = "rbxassetid://10723376114",
	["gauge"] = "rbxassetid://10723395708",
	["globe"] = "rbxassetid://10723404337",
	["info"] = "rbxassetid://10723415903",
	["key"] = "rbxassetid://10723416652",
	["layers"] = "rbxassetid://10723424505",
	["layout"] = "rbxassetid://10723425376",
	["layout-grid"] = "rbxassetid://10723424838",
	["link"] = "rbxassetid://10723426722",
	["list"] = "rbxassetid://10723433811",
	["lock"] = "rbxassetid://10723434711",
	["log-out"] = "rbxassetid://10723434906",
	["maximize-2"] = "rbxassetid://10734886496",
	["minimize-2"] = "rbxassetid://10734895530",
	["monitor"] = "rbxassetid://10734896881",
	["more-horizontal"] = "rbxassetid://10734897250",
	["move"] = "rbxassetid://10734900011",
	["navigation"] = "rbxassetid://10734906744",
	["package"] = "rbxassetid://10734909540",
	["play"] = "rbxassetid://10734923549",
	["power"] = "rbxassetid://10734930466",
	["refresh-cw"] = "rbxassetid://10734933222",
	["repeat"] = "rbxassetid://10734933966",
	["save"] = "rbxassetid://10734941499",
	["search"] = "rbxassetid://10734943674",
	["server"] = "rbxassetid://10734949856",
	["settings"] = "rbxassetid://10734950309",
	["shield"] = "rbxassetid://10734951847",
	["shield-check"] = "rbxassetid://10734951367",
	["sliders"] = "rbxassetid://10734963400",
	["target"] = "rbxassetid://10734977012",
	["terminal"] = "rbxassetid://10734982144",
	["trash-2"] = "rbxassetid://10747362241",
	["unlock"] = "rbxassetid://10747366027",
	["user"] = "rbxassetid://10747373176",
	["users"] = "rbxassetid://10747373426",
	["wifi"] = "rbxassetid://10747382504",
	["wrench"] = "rbxassetid://10747383470",
	["x"] = "rbxassetid://10747384394",
	["x-circle"] = "rbxassetid://10747383819",
	["zap"] = "rbxassetid://10709752035"
}

-- Fast alias normalization
local IconLookup = {}
for name, asset in pairs(RawIcons) do
    IconLookup[name] = asset
    IconLookup["lucide-" .. name] = asset
end
IconLookup["movement"] = RawIcons["move"] or RawIcons["navigation"]
IconLookup["visuals"] = RawIcons["eye"]
IconLookup["combat"] = RawIcons["crosshair"] or RawIcons["target"]
IconLookup["utility"] = RawIcons["wrench"] or RawIcons["sliders"]
IconLookup["about"] = RawIcons["info"]
IconLookup["speed"] = RawIcons["gauge"]

-- Typography Constants (BuilderSans with graceful fallbacks)
local FontBold = Enum.Font.BuilderSansBold or Enum.Font.GothamBold
local FontMedium = Enum.Font.BuilderSansMedium or Enum.Font.GothamMedium
local FontRegular = Enum.Font.BuilderSans or Enum.Font.Gotham
local FontCode = Enum.Font.RobotoMono or Enum.Font.Code

local GousseUI = {
    Version = "2.1.0",
    Windows = {},
    ActiveKeybind = Enum.KeyCode.RightControl,
    Theme = {
        Background = Color3.fromRGB(11, 14, 20),        -- #0B0E14 Deep Obsidian Slate
        Sidebar = Color3.fromRGB(15, 19, 27),           -- #0F131B Elevated dark tone
        Surface = Color3.fromRGB(19, 25, 35),           -- #131923 Sleek card background
        SurfaceHover = Color3.fromRGB(26, 35, 50),      -- #1A2332 Interactive hover highlight
        TooltipBg = Color3.fromRGB(26, 34, 48),         -- #1A2230 Floating tooltip background
        Border = Color3.fromRGB(30, 41, 59),            -- #1E293B Soft slate perimeter border
        BorderLight = Color3.fromRGB(51, 65, 85),       -- #334155 Subtle separator
        WindowOutline = Color3.fromRGB(16, 185, 129),  -- #10B981 Modern Emerald Accent
        Accent = Color3.fromRGB(16, 185, 129),         -- #10B981 Modern Emerald
        AccentDark = Color3.fromRGB(5, 150, 105),       -- #059669 Darker Emerald
        Primary = Color3.fromRGB(16, 185, 129),        -- Green brand accent
        Blue = Color3.fromRGB(56, 189, 248),            -- #38BDF8 Sky Cyan
        Success = Color3.fromRGB(16, 185, 129),        -- Green
        Warning = Color3.fromRGB(245, 158, 11),         -- #F59E0B Amber
        Danger = Color3.fromRGB(244, 63, 94),           -- #F43F5E Modern Red
        TextPrimary = Color3.fromRGB(243, 244, 246),    -- #F3F4F6 Neutral white
        TextSecondary = Color3.fromRGB(148, 163, 184),  -- #94A3B8 Slate-400 (High contrast WCAG AAA)
        TextMuted = Color3.fromRGB(100, 116, 139)        -- #64748B Slate-500 section labels
    }
}

function GousseUI:GetIcon(name: string?): string?
    if not name or name == "" then return nil end
    if name:sub(1, 13) == "rbxassetid://" then return name end
    local clean = name:lower():gsub("^lucide%-", "")
    return IconLookup[clean] or IconLookup[name:lower()] or nil
end

-- Utility: Quick Tween
local function Tween(instance: Instance, properties: {[string]: any}, duration: number?, style: Enum.EasingStyle?, direction: Enum.EasingDirection?)
    duration = duration or 0.14
    style = style or Enum.EasingStyle.Quad
    direction = direction or Enum.EasingDirection.Out
    local tween = TweenService:Create(instance, TweenInfo.new(duration, style, direction), properties)
    tween:Play()
    return tween
end

-- Utility: Make UI Draggable with Strict Viewport Clamping (Desktop Mouse & Mobile Touch)
local function MakeDraggable(dragHandle: GuiObject, targetFrame: GuiObject)
    local dragging = false
    local dragInput, dragStart, startCenter

    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position

            local anchor = targetFrame.AnchorPoint
            local absPos = targetFrame.AbsolutePosition
            local absSize = targetFrame.AbsoluteSize
            startCenter = Vector2.new(absPos.X + absSize.X * anchor.X, absPos.Y + absSize.Y * anchor.Y)

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    dragHandle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            local cam = workspace.CurrentCamera
            local vp = cam and cam.ViewportSize or Vector2.new(1920, 1080)

            local anchor = targetFrame.AnchorPoint
            local absSize = targetFrame.AbsoluteSize

            local halfW = absSize.X * anchor.X
            local otherW = absSize.X * (1 - anchor.X)
            local halfH = absSize.Y * anchor.Y
            local otherH = absSize.Y * (1 - anchor.Y)

            local minX = halfW + 4
            local maxX = math.max(minX, vp.X - otherW - 4)
            local minY = halfH + 4
            local maxY = math.max(minY, vp.Y - otherH - 4)

            local clampedX = math.clamp(startCenter.X + delta.X, minX, maxX)
            local clampedY = math.clamp(startCenter.Y + delta.Y, minY, maxY)

            targetFrame.Position = UDim2.new(0, clampedX, 0, clampedY)
        end
    end)
end

-- ============================================================================
-- Notification System
-- ============================================================================
local NotificationGui = nil
local NotificationContainer = nil

local function EnsureNotificationGui()
    if NotificationGui and NotificationGui.Parent then return end

    NotificationGui = Instance.new("ScreenGui")
    NotificationGui.Name = "GousseNotifications"
    NotificationGui.ResetOnSpawn = false
    NotificationGui.DisplayOrder = 9999
    NotificationGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    NotificationGui.Parent = GetSafeGuiParent()

    NotificationContainer = Instance.new("Frame")
    NotificationContainer.Name = "Container"
    NotificationContainer.BackgroundTransparency = 1
    NotificationContainer.Position = UDim2.new(1, -20, 1, -20)
    NotificationContainer.AnchorPoint = Vector2.new(1, 1)
    NotificationContainer.Size = UDim2.new(0, 280, 1, 0)
    NotificationContainer.Parent = NotificationGui

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    layout.Padding = UDim.new(0, 6)
    layout.Parent = NotificationContainer
end

function GousseUI:Notify(config: { Title: string?, Content: string, Duration: number?, Type: string? })
    EnsureNotificationGui()

    local titleText = config.Title or "Gousse Hub"
    local contentText = config.Content or ""
    local duration = config.Duration or 3.5
    local notifyType = config.Type or "success"

    local accentColor = GousseUI.Theme.Accent
    if notifyType == "info" then accentColor = GousseUI.Theme.Blue
    elseif notifyType == "warning" then accentColor = GousseUI.Theme.Warning
    elseif notifyType == "error" then accentColor = GousseUI.Theme.Danger
    end

    local card = Instance.new("Frame")
    card.Name = "NotificationCard"
    card.Size = UDim2.new(1, 0, 0, 0)
    card.BackgroundTransparency = 1
    card.BackgroundColor3 = GousseUI.Theme.Surface
    card.BorderSizePixel = 0
    card.ClipsDescendants = true
    card.Parent = NotificationContainer

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = card

    local stroke = Instance.new("UIStroke")
    stroke.Color = GousseUI.Theme.Border
    stroke.Thickness = 1
    stroke.Transparency = 1
    stroke.Parent = card

    local bar = Instance.new("Frame")
    bar.Name = "AccentBar"
    bar.Size = UDim2.new(0, 3, 1, 0)
    bar.BackgroundColor3 = accentColor
    bar.BorderSizePixel = 0
    bar.Parent = card

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Position = UDim2.new(0, 14, 0, 8)
    title.Size = UDim2.new(1, -22, 0, 16)
    title.BackgroundTransparency = 1
    title.Font = FontBold
    title.Text = titleText
    title.TextColor3 = GousseUI.Theme.TextPrimary
    title.TextSize = 13
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = card

    local body = Instance.new("TextLabel")
    body.Name = "Body"
    body.Position = UDim2.new(0, 14, 0, 26)
    body.Size = UDim2.new(1, -22, 0, 30)
    body.BackgroundTransparency = 1
    body.Font = FontRegular
    body.Text = contentText
    body.TextColor3 = GousseUI.Theme.TextSecondary
    body.TextSize = 11.5
    body.TextWrapped = true
    body.TextXAlignment = Enum.TextXAlignment.Left
    body.TextYAlignment = Enum.TextYAlignment.Top
    body.Parent = card

    Tween(card, { Size = UDim2.new(1, 0, 0, 60), BackgroundTransparency = 0 }, 0.18)
    Tween(stroke, { Transparency = 0 }, 0.18)

    task.delay(duration, function()
        if card and card.Parent then
            Tween(card, { Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1 }, 0.15)
            Tween(stroke, { Transparency = 1 }, 0.15)
            task.wait(0.18)
            card:Destroy()
        end
    end)
end

-- ============================================================================
-- Loader Window (Tactical Animated Loading Modal)
-- ============================================================================
function GousseUI:CreateLoader(config: {
    Title: string?,
    SubTitle: string?,
    GameName: string?,
    Status: string?
})
    config = config or {}
    local loaderTitle = config.Title or "Gousse Hub"
    local loaderSubtitle = config.SubTitle or "Universal Loader"
    local gameName = config.GameName or "Roblox Game"
    local initialStatus = config.Status or "Initializing components..."

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "GousseLoader_" .. math.random(1000, 9999)
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = 10000
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = GetSafeGuiParent()

    -- Modal Container
    local modal = Instance.new("Frame")
    modal.Name = "LoaderModal"
    modal.Size = UDim2.new(0, 360, 0, 185)
    modal.Position = UDim2.new(0.5, 0, 0.5, 20)
    modal.AnchorPoint = Vector2.new(0.5, 0.5)
    modal.BackgroundColor3 = GousseUI.Theme.Background
    modal.BorderSizePixel = 0
    modal.ClipsDescendants = true
    modal.BackgroundTransparency = 1
    modal.Parent = screenGui

    local modalCorner = Instance.new("UICorner")
    modalCorner.CornerRadius = UDim.new(0, 10)
    modalCorner.Parent = modal

    local modalStroke = Instance.new("UIStroke")
    modalStroke.Color = GousseUI.Theme.Border
    modalStroke.Thickness = 1.2
    modalStroke.Parent = modal

    -- Top 2px Emerald Accent Line
    local topAccent = Instance.new("Frame")
    topAccent.Name = "TopAccent"
    topAccent.Size = UDim2.new(1, 0, 0, 2)
    topAccent.Position = UDim2.new(0, 0, 0, 0)
    topAccent.BackgroundColor3 = GousseUI.Theme.Accent
    topAccent.BorderSizePixel = 0
    topAccent.Parent = modal

    -- Header with Logo
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 52)
    header.BackgroundTransparency = 1
    header.Parent = modal

    local logoBadge = Instance.new("TextLabel")
    logoBadge.Name = "LogoBadge"
    logoBadge.Size = UDim2.new(0, 30, 0, 30)
    logoBadge.Position = UDim2.new(0, 16, 0.5, -15)
    logoBadge.BackgroundColor3 = GousseUI.Theme.Accent
    logoBadge.Font = FontBold
    logoBadge.Text = "G"
    logoBadge.TextColor3 = GousseUI.Theme.Background
    logoBadge.TextSize = 16
    logoBadge.Parent = header

    local logoCorner = Instance.new("UICorner")
    logoCorner.CornerRadius = UDim.new(0, 6)
    logoCorner.Parent = logoBadge

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(0.6, 0, 0, 18)
    title.Position = UDim2.new(0, 56, 0, 10)
    title.BackgroundTransparency = 1
    title.Font = FontBold
    title.Text = loaderTitle
    title.TextColor3 = GousseUI.Theme.TextPrimary
    title.TextSize = 15
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header

    local subtitle = Instance.new("TextLabel")
    subtitle.Name = "Subtitle"
    subtitle.Size = UDim2.new(0.6, 0, 0, 14)
    subtitle.Position = UDim2.new(0, 56, 0, 28)
    subtitle.BackgroundTransparency = 1
    subtitle.Font = FontMedium
    subtitle.Text = loaderSubtitle
    subtitle.TextColor3 = GousseUI.Theme.TextSecondary
    subtitle.TextSize = 11
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    subtitle.Parent = header

    -- Game Badge pill
    local gameBadge = Instance.new("Frame")
    gameBadge.Name = "GameBadge"
    gameBadge.Size = UDim2.new(0, 0, 0, 22)
    gameBadge.AutomaticSize = Enum.AutomaticSize.X
    gameBadge.Position = UDim2.new(1, -16, 0.5, -11)
    gameBadge.AnchorPoint = Vector2.new(1, 0)
    gameBadge.BackgroundColor3 = GousseUI.Theme.Surface
    gameBadge.Parent = header

    local gameBadgeCorner = Instance.new("UICorner")
    gameBadgeCorner.CornerRadius = UDim.new(1, 0)
    gameBadgeCorner.Parent = gameBadge

    local gameBadgeStroke = Instance.new("UIStroke")
    gameBadgeStroke.Color = GousseUI.Theme.Border
    gameBadgeStroke.Thickness = 1
    gameBadgeStroke.Parent = gameBadge

    local gameBadgeLabel = Instance.new("TextLabel")
    gameBadgeLabel.Name = "BadgeText"
    gameBadgeLabel.Size = UDim2.new(0, 0, 1, 0)
    gameBadgeLabel.AutomaticSize = Enum.AutomaticSize.X
    gameBadgeLabel.Position = UDim2.new(0, 10, 0, 0)
    gameBadgeLabel.BackgroundTransparency = 1
    gameBadgeLabel.Font = FontMedium
    gameBadgeLabel.Text = gameName
    gameBadgeLabel.TextColor3 = GousseUI.Theme.Accent
    gameBadgeLabel.TextSize = 10.5
    gameBadgeLabel.Parent = gameBadge

    local gameBadgePad = Instance.new("UIPadding")
    gameBadgePad.PaddingRight = UDim.new(0, 10)
    gameBadgePad.Parent = gameBadge

    -- Status Card
    local statusCard = Instance.new("Frame")
    statusCard.Name = "StatusCard"
    statusCard.Size = UDim2.new(1, -32, 0, 48)
    statusCard.Position = UDim2.new(0, 16, 0, 56)
    statusCard.BackgroundColor3 = GousseUI.Theme.Surface
    statusCard.BorderSizePixel = 0
    statusCard.Parent = modal

    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 8)
    cardCorner.Parent = statusCard

    local cardStroke = Instance.new("UIStroke")
    cardStroke.Color = GousseUI.Theme.Border
    cardStroke.Thickness = 1
    cardStroke.Parent = statusCard

    local statusIcon = Instance.new("ImageLabel")
    statusIcon.Name = "StatusIcon"
    statusIcon.Size = UDim2.new(0, 16, 0, 16)
    statusIcon.Position = UDim2.new(0, 12, 0.5, -8)
    statusIcon.BackgroundTransparency = 1
    statusIcon.Image = GousseUI:GetIcon("activity") or "rbxassetid://10709752035"
    statusIcon.ImageColor3 = GousseUI.Theme.Accent
    statusIcon.Parent = statusCard

    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "StatusText"
    statusLabel.Size = UDim2.new(1, -40, 1, 0)
    statusLabel.Position = UDim2.new(0, 34, 0, 0)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Font = FontRegular
    statusLabel.Text = initialStatus
    statusLabel.TextColor3 = GousseUI.Theme.TextPrimary
    statusLabel.TextSize = 11.5
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.TextTruncate = Enum.TextTruncate.AtEnd
    statusLabel.Parent = statusCard

    -- Progress Bar Section
    local progressContainer = Instance.new("Frame")
    progressContainer.Name = "ProgressContainer"
    progressContainer.Size = UDim2.new(1, -32, 0, 40)
    progressContainer.Position = UDim2.new(0, 16, 0, 116)
    progressContainer.BackgroundTransparency = 1
    progressContainer.Parent = modal

    local progressLabel = Instance.new("TextLabel")
    progressLabel.Name = "ProgressLabel"
    progressLabel.Size = UDim2.new(0.6, 0, 0, 16)
    progressLabel.Position = UDim2.new(0, 0, 0, 0)
    progressLabel.BackgroundTransparency = 1
    progressLabel.Font = FontMedium
    progressLabel.Text = "System Loading"
    progressLabel.TextColor3 = GousseUI.Theme.TextSecondary
    progressLabel.TextSize = 11
    progressLabel.TextXAlignment = Enum.TextXAlignment.Left
    progressLabel.Parent = progressContainer

    local percentLabel = Instance.new("TextLabel")
    percentLabel.Name = "PercentLabel"
    percentLabel.Size = UDim2.new(0.4, 0, 0, 16)
    percentLabel.Position = UDim2.new(0.6, 0, 0, 0)
    percentLabel.BackgroundTransparency = 1
    percentLabel.Font = FontCode
    percentLabel.Text = "0%"
    percentLabel.TextColor3 = GousseUI.Theme.Accent
    percentLabel.TextSize = 11.5
    percentLabel.TextXAlignment = Enum.TextXAlignment.Right
    percentLabel.Parent = progressContainer

    local track = Instance.new("Frame")
    track.Name = "Track"
    track.Size = UDim2.new(1, 0, 0, 6)
    track.Position = UDim2.new(0, 0, 0, 22)
    track.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
    track.BorderSizePixel = 0
    track.Parent = progressContainer

    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(1, 0)
    trackCorner.Parent = track

    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.BackgroundColor3 = GousseUI.Theme.Accent
    fill.BorderSizePixel = 0
    fill.Parent = track

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = fill

    -- Entrance Animation
    Tween(modal, { Position = UDim2.new(0.5, 0, 0.5, 0), BackgroundTransparency = 0 }, 0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

    -- Pulsing Logo Animation
    local pulseTween = TweenService:Create(logoBadge, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
        BackgroundColor3 = GousseUI.Theme.AccentDark
    })
    pulseTween:Play()

    local currentProgress = 0
    local LoaderObj = {}

    function LoaderObj:SetStatus(message: string, progress: number?)
        statusLabel.Text = message
        if progress ~= nil then
            currentProgress = math.clamp(progress, 0, 1)
            local pct = math.floor(currentProgress * 100)
            percentLabel.Text = tostring(pct) .. "%"
            Tween(fill, { Size = UDim2.new(currentProgress, 0, 1, 0) }, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        end
    end

    function LoaderObj:SetGame(name: string)
        gameName = name
        gameBadgeLabel.Text = name
    end

    function LoaderObj:Finish(callback: (() -> ())?)
        LoaderObj:SetStatus("Initialization complete!", 1)
        statusLabel.TextColor3 = GousseUI.Theme.Accent
        statusIcon.Image = GousseUI:GetIcon("check") or "rbxassetid://10709790644"
        pulseTween:Cancel()
        logoBadge.BackgroundColor3 = GousseUI.Theme.Accent

        task.delay(0.4, function()
            local exitTween = Tween(modal, {
                Position = UDim2.new(0.5, 0, 0.5, -20),
                BackgroundTransparency = 1
            }, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

            exitTween.Completed:Connect(function()
                screenGui:Destroy()
                if callback then
                    pcall(callback)
                end
            end)
        end)
    end

    function LoaderObj:Destroy()
        pulseTween:Cancel()
        screenGui:Destroy()
    end

    return LoaderObj
end

-- ============================================================================
-- Window Creation (Adaptive Desktop & Mobile)
-- ============================================================================
function GousseUI:CreateWindow(config: {
    Title: string?,
    SubTitle: string?,
    Keybind: Enum.KeyCode?,
    Size: UDim2?,
    Mobile: boolean?,
    ShowMobileToggle: boolean?
})
    config = config or {}
    local toggleKey = config.Keybind or GousseUI.ActiveKeybind
    GousseUI.ActiveKeybind = toggleKey

    local isMobile = if config.Mobile ~= nil then config.Mobile else (UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled)

    -- Header title: game/script name only (no "Gousse Hub")
    local displayTitle: string
    if config.Title and config.Title ~= "Gousse Hub" and config.SubTitle then
        displayTitle = config.Title .. " • " .. config.SubTitle
    elseif config.SubTitle then
        displayTitle = config.SubTitle
    else
        displayTitle = config.Title or "Universal"
    end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "GousseUI_" .. displayTitle:gsub("[%s%•%[%]%-]+", "")
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = 100
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = GetSafeGuiParent()

    local isVisible = true

    -- Main Window Outer Frame (CanvasGroup for whole-window alpha fade and animation)
    local okCanvas, canvasInstance = pcall(function()
        local c = Instance.new("CanvasGroup")
        c.GroupTransparency = 0
        return c
    end)
    local isCanvasGroup = okCanvas and canvasInstance ~= nil
    local mainFrame: GuiObject = (if isCanvasGroup then canvasInstance else Instance.new("Frame")) :: any
    mainFrame.Name = "MainFrame"
    mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)

    if config.Size then
        mainFrame.Size = config.Size
    elseif isMobile then
        mainFrame.Size = UDim2.new(0.92, 0, 0.84, 0)
    else
        mainFrame.Size = UDim2.new(0, 640, 0, 420)
    end
    mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    mainFrame.BackgroundColor3 = GousseUI.Theme.Background
    mainFrame.BorderSizePixel = 0
    mainFrame.ClipsDescendants = true
    mainFrame.Parent = screenGui

    -- Responsive Size Constraint for ultra-wide or compact mobile screens
    local sizeConstraint = Instance.new("UISizeConstraint")
    sizeConstraint.MinSize = Vector2.new(310, 260)
    sizeConstraint.MaxSize = Vector2.new(720, 500)
    sizeConstraint.Parent = mainFrame

    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 10)
    mainCorner.Parent = mainFrame

    -- Soft slate perimeter border
    local mainStroke = Instance.new("UIStroke")
    mainStroke.Color = GousseUI.Theme.Border
    mainStroke.Thickness = 1.2
    mainStroke.Parent = mainFrame

    -- Signature top emerald accent bar (2px)
    local topAccentBar = Instance.new("Frame")
    topAccentBar.Name = "TopAccentBar"
    topAccentBar.Size = UDim2.new(1, 0, 0, 2)
    topAccentBar.Position = UDim2.new(0, 0, 0, 0)
    topAccentBar.BackgroundColor3 = GousseUI.Theme.Accent
    topAccentBar.BorderSizePixel = 0
    topAccentBar.ZIndex = 10
    topAccentBar.Parent = mainFrame

    -- ========================================================================
    -- Global Floating Tooltip System (ScreenGui ZIndex 10000, Clamped Viewport)
    -- ========================================================================
    local tooltipFrame = Instance.new("Frame")
    tooltipFrame.Name = "GlobalTooltip"
    tooltipFrame.BackgroundColor3 = GousseUI.Theme.TooltipBg
    tooltipFrame.BorderSizePixel = 0
    tooltipFrame.ZIndex = 10000
    tooltipFrame.Visible = false
    tooltipFrame.AutomaticSize = Enum.AutomaticSize.XY
    tooltipFrame.AnchorPoint = Vector2.new(0.5, 1)
    tooltipFrame.Parent = screenGui

    local tooltipCorner = Instance.new("UICorner")
    tooltipCorner.CornerRadius = UDim.new(0, 6)
    tooltipCorner.Parent = tooltipFrame

    local tooltipStroke = Instance.new("UIStroke")
    tooltipStroke.Color = GousseUI.Theme.BorderLight
    tooltipStroke.Thickness = 1
    tooltipStroke.Parent = tooltipFrame

    local tooltipPad = Instance.new("UIPadding")
    tooltipPad.PaddingTop = UDim.new(0, 6)
    tooltipPad.PaddingBottom = UDim.new(0, 6)
    tooltipPad.PaddingLeft = UDim.new(0, 10)
    tooltipPad.PaddingRight = UDim.new(0, 10)
    tooltipPad.Parent = tooltipFrame

    local tooltipConstraint = Instance.new("UISizeConstraint")
    tooltipConstraint.MaxSize = Vector2.new(240, 500)
    tooltipConstraint.Parent = tooltipFrame

    local tooltipLabel = Instance.new("TextLabel")
    tooltipLabel.Name = "Text"
    tooltipLabel.BackgroundTransparency = 1
    tooltipLabel.Font = FontRegular
    tooltipLabel.TextColor3 = GousseUI.Theme.TextPrimary
    tooltipLabel.TextSize = 11
    tooltipLabel.TextWrapped = true
    tooltipLabel.AutomaticSize = Enum.AutomaticSize.XY
    tooltipLabel.ZIndex = 10001
    tooltipLabel.Parent = tooltipFrame

    local currentTooltipTarget = nil

    local function HideTooltip()
        currentTooltipTarget = nil
        tooltipFrame.Visible = false
    end

    local function ShowTooltip(targetBtn: GuiObject, text: string)
        if not text or text == "" then return end
        if currentTooltipTarget == targetBtn and tooltipFrame.Visible then return end
        currentTooltipTarget = targetBtn
        tooltipLabel.Text = text
        tooltipFrame.Visible = true

        local cam = workspace.CurrentCamera
        local vp = cam and cam.ViewportSize or Vector2.new(1920, 1080)
        local btnPos = targetBtn.AbsolutePosition
        local btnSize = targetBtn.AbsoluteSize

        local targetX = btnPos.X + btnSize.X / 2
        local targetY = btnPos.Y - 6

        tooltipFrame.AnchorPoint = Vector2.new(0.5, 1)
        if targetY - 40 < 10 then
            tooltipFrame.AnchorPoint = Vector2.new(0.5, 0)
            targetY = btnPos.Y + btnSize.Y + 6
        end

        targetX = math.clamp(targetX, 120, math.max(120, vp.X - 120))
        tooltipFrame.Position = UDim2.new(0, targetX, 0, targetY)
    end

    local function AttachTooltip(btn: GuiObject, text: string)
        btn.MouseEnter:Connect(function()
            ShowTooltip(btn, text)
        end)
        btn.MouseLeave:Connect(function()
            if currentTooltipTarget == btn then
                HideTooltip()
            end
        end)
        btn.MouseButton1Click:Connect(function()
            if currentTooltipTarget == btn and tooltipFrame.Visible then
                HideTooltip()
            else
                ShowTooltip(btn, text)
            end
        end)
    end

    -- Close tooltip on background clicks
    mainFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if currentTooltipTarget and input.Target ~= currentTooltipTarget then
                HideTooltip()
            end
        end
    end)

    -- Header / Title Bar (Compact: 38px on desktop, 44px on mobile)
    local headerHeight = if isMobile then 44 else 38
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, headerHeight)
    header.BackgroundColor3 = GousseUI.Theme.Sidebar
    header.BorderSizePixel = 0
    header.Parent = mainFrame

    local headerBottomBorder = Instance.new("Frame")
    headerBottomBorder.Size = UDim2.new(1, 0, 0, 1)
    headerBottomBorder.Position = UDim2.new(0, 0, 1, -1)
    headerBottomBorder.BackgroundColor3 = GousseUI.Theme.Border
    headerBottomBorder.BorderSizePixel = 0
    headerBottomBorder.Parent = header

    -- Left: Collapse / Expand Sidebar Button
    local collapseBtnSize = if isMobile then 32 else 26
    local collapseBtn = Instance.new("TextButton")
    collapseBtn.Name = "CollapseBtn"
    collapseBtn.Size = UDim2.new(0, collapseBtnSize, 0, collapseBtnSize)
    collapseBtn.Position = UDim2.new(0, 8, 0.5, -collapseBtnSize / 2)
    collapseBtn.BackgroundColor3 = GousseUI.Theme.Surface
    collapseBtn.Text = ""
    collapseBtn.AutoButtonColor = false
    collapseBtn.Parent = header

    local collapseCorner = Instance.new("UICorner")
    collapseCorner.CornerRadius = UDim.new(0, 6)
    collapseCorner.Parent = collapseBtn

    local collapseStroke = Instance.new("UIStroke")
    collapseStroke.Color = GousseUI.Theme.Border
    collapseStroke.Thickness = 1
    collapseStroke.Parent = collapseBtn

    local collapseIcon = Instance.new("ImageLabel")
    collapseIcon.Name = "Icon"
    collapseIcon.Size = UDim2.new(0, 14, 0, 14)
    collapseIcon.Position = UDim2.new(0.5, -7, 0.5, -7)
    collapseIcon.BackgroundTransparency = 1
    collapseIcon.Image = RawIcons["layout"] or "rbxassetid://10723425376"
    collapseIcon.ImageColor3 = GousseUI.Theme.TextSecondary
    collapseIcon.Parent = collapseBtn

    -- Title Label: Clean Game/Script Name (No "Gousse Hub")
    local titleOffsetLeft = 8 + collapseBtnSize + 10
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(1, -titleOffsetLeft - 100, 1, 0)
    titleLabel.Position = UDim2.new(0, titleOffsetLeft, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = FontMedium
    titleLabel.Text = displayTitle
    titleLabel.TextColor3 = GousseUI.Theme.TextPrimary
    titleLabel.TextSize = if isMobile then 13.5 else 13
    titleLabel.TextTruncate = Enum.TextTruncate.AtEnd
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.TextYAlignment = Enum.TextYAlignment.Center
    titleLabel.Parent = header

    -- Window Controls (Minimize & Close)
    local controlsFrame = Instance.new("Frame")
    controlsFrame.Name = "Controls"
    local ctrlBtnSize = if isMobile then 30 else 22
    local ctrlGap = if isMobile then 6 else 4
    local ctrlWidth = (ctrlBtnSize * 2) + ctrlGap
    controlsFrame.Size = UDim2.new(0, ctrlWidth, 1, 0)
    controlsFrame.Position = UDim2.new(1, -ctrlWidth - 8, 0, 0)
    controlsFrame.BackgroundTransparency = 1
    controlsFrame.Parent = header

    local btnMinimize = Instance.new("TextButton")
    btnMinimize.Name = "BtnMinimize"
    btnMinimize.Size = UDim2.new(0, ctrlBtnSize, 0, ctrlBtnSize)
    btnMinimize.Position = UDim2.new(0, 0, 0.5, -ctrlBtnSize / 2)
    btnMinimize.BackgroundColor3 = GousseUI.Theme.Surface
    btnMinimize.Font = FontMedium
    btnMinimize.Text = "—"
    btnMinimize.TextColor3 = GousseUI.Theme.TextSecondary
    btnMinimize.TextSize = 11
    btnMinimize.AutoButtonColor = false
    btnMinimize.Parent = controlsFrame

    local minCorner = Instance.new("UICorner")
    minCorner.CornerRadius = UDim.new(0, 5)
    minCorner.Parent = btnMinimize

    local btnClose = Instance.new("TextButton")
    btnClose.Name = "BtnClose"
    btnClose.Size = UDim2.new(0, ctrlBtnSize, 0, ctrlBtnSize)
    btnClose.Position = UDim2.new(0, ctrlBtnSize + ctrlGap, 0.5, -ctrlBtnSize / 2)
    btnClose.BackgroundColor3 = GousseUI.Theme.Surface
    btnClose.Font = FontMedium
    btnClose.Text = "✕"
    btnClose.TextColor3 = GousseUI.Theme.TextSecondary
    btnClose.TextSize = 11
    btnClose.AutoButtonColor = false
    btnClose.Parent = controlsFrame

    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 5)
    closeCorner.Parent = btnClose

    MakeDraggable(header, mainFrame)

    local function ToggleWindow(state: boolean?)
        if state == nil then
            isVisible = not isVisible
        else
            isVisible = state
        end

        HideTooltip()

        if isVisible then
            mainFrame.Visible = true
            if isCanvasGroup then
                mainFrame.GroupTransparency = 1
                Tween(mainFrame, { GroupTransparency = 0 }, 0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
            else
                Tween(mainFrame, { BackgroundTransparency = 0 }, 0.16)
            end
        else
            if isCanvasGroup then
                local tw = Tween(mainFrame, { GroupTransparency = 1 }, 0.16, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
                tw.Completed:Connect(function()
                    if not isVisible then mainFrame.Visible = false end
                end)
            else
                local tw = Tween(mainFrame, { BackgroundTransparency = 1 }, 0.16)
                tw.Completed:Connect(function()
                    if not isVisible then mainFrame.Visible = false end
                end)
            end
        end
    end

    -- Mobile Toggle FAB (Draggable & Touch Friendly)
    local fabBtn = nil
    local showFab = (config.ShowMobileToggle ~= false) and (isMobile or UserInputService.TouchEnabled)

    if showFab then
        fabBtn = Instance.new("TextButton")
        fabBtn.Name = "MobileToggleFAB"
        fabBtn.Size = UDim2.new(0, 48, 0, 48)
        fabBtn.Position = UDim2.new(0, 16, 0.45, 0)
        fabBtn.BackgroundColor3 = GousseUI.Theme.Surface
        fabBtn.Text = "G"
        fabBtn.Font = FontBold
        fabBtn.TextColor3 = GousseUI.Theme.Accent
        fabBtn.TextSize = 18
        fabBtn.AutoButtonColor = false
        fabBtn.ZIndex = 500
        fabBtn.Parent = screenGui

        local fabCorner = Instance.new("UICorner")
        fabCorner.CornerRadius = UDim.new(1, 0)
        fabCorner.Parent = fabBtn

        local fabStroke = Instance.new("UIStroke")
        fabStroke.Color = GousseUI.Theme.Accent
        fabStroke.Thickness = 1.5
        fabStroke.Parent = fabBtn

        MakeDraggable(fabBtn, fabBtn)

        fabBtn.MouseButton1Click:Connect(function()
            ToggleWindow()
        end)
    end

    btnMinimize.MouseButton1Click:Connect(function()
        ToggleWindow(false)
        local tip = if isMobile then "Ketuk tombol 'G' di layar untuk membuka kembali." else ("Tekan " .. toggleKey.Name .. " untuk membuka kembali.")
        GousseUI:Notify({ Title = displayTitle, Content = tip, Duration = 3 })
    end)

    btnClose.MouseButton1Click:Connect(function()
        ToggleWindow(false)
    end)

    UserInputService.InputBegan:Connect(function(input, processed)
        if not processed and input.KeyCode == toggleKey then
            ToggleWindow()
        end
    end)

    -- Body Container
    local bodyFrame = Instance.new("Frame")
    bodyFrame.Name = "Body"
    bodyFrame.Size = UDim2.new(1, 0, 1, -headerHeight)
    bodyFrame.Position = UDim2.new(0, 0, 0, headerHeight)
    bodyFrame.BackgroundTransparency = 1
    bodyFrame.Parent = mainFrame

    -- Left Navigation Sidebar (Collapsible with smooth animation)
    local defaultSidebarWidth = if isMobile then 125 else 140
    local isSidebarCollapsed = false

    local sidebar = Instance.new("Frame")
    sidebar.Name = "Sidebar"
    sidebar.Size = UDim2.new(0, defaultSidebarWidth, 1, 0)
    sidebar.BackgroundColor3 = GousseUI.Theme.Sidebar
    sidebar.BorderSizePixel = 0
    sidebar.ClipsDescendants = true
    sidebar.Parent = bodyFrame

    local sidebarBorder = Instance.new("Frame")
    sidebarBorder.Size = UDim2.new(0, 1, 1, 0)
    sidebarBorder.Position = UDim2.new(1, -1, 0, 0)
    sidebarBorder.BackgroundColor3 = GousseUI.Theme.Border
    sidebarBorder.BorderSizePixel = 0
    sidebarBorder.Parent = sidebar

    local tabListContainer = Instance.new("ScrollingFrame")
    tabListContainer.Name = "TabList"
    tabListContainer.Size = UDim2.new(1, -8, 1, -12)
    tabListContainer.Position = UDim2.new(0, 4, 0, 6)
    tabListContainer.BackgroundTransparency = 1
    tabListContainer.BorderSizePixel = 0
    tabListContainer.ScrollBarThickness = 2
    tabListContainer.ScrollBarImageColor3 = GousseUI.Theme.BorderLight
    tabListContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    tabListContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
    tabListContainer.Parent = sidebar

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Padding = UDim.new(0, 4)
    tabLayout.Parent = tabListContainer

    -- Single animated emerald active indicator bar for sidebar (Glides smoothly between tabs)
    local activeIndicator = Instance.new("Frame")
    activeIndicator.Name = "ActiveIndicator"
    activeIndicator.Size = UDim2.new(0, 3, 0, 18)
    activeIndicator.Position = UDim2.new(0, 4, 0, 6)
    activeIndicator.BackgroundColor3 = GousseUI.Theme.Accent
    activeIndicator.BorderSizePixel = 0
    activeIndicator.ZIndex = 10
    activeIndicator.Visible = false
    activeIndicator.Parent = sidebar

    local indicatorCorner = Instance.new("UICorner")
    indicatorCorner.CornerRadius = UDim.new(1, 0)
    indicatorCorner.Parent = activeIndicator

    -- Right Content Area (Expands to 100% when sidebar is collapsed)
    local contentArea = Instance.new("Frame")
    contentArea.Name = "ContentArea"
    contentArea.Size = UDim2.new(1, -defaultSidebarWidth, 1, 0)
    contentArea.Position = UDim2.new(0, defaultSidebarWidth, 0, 0)
    contentArea.BackgroundTransparency = 1
    contentArea.ClipsDescendants = true
    contentArea.Parent = bodyFrame

    local function ToggleSidebar(forceState: boolean?)
        if forceState ~= nil then
            isSidebarCollapsed = forceState
        else
            isSidebarCollapsed = not isSidebarCollapsed
        end

        local targetWidth = isSidebarCollapsed and 0 or defaultSidebarWidth
        Tween(sidebar, { Size = UDim2.new(0, targetWidth, 1, 0) }, 0.2, Enum.EasingStyle.Quart)
        Tween(contentArea, {
            Size = UDim2.new(1, -targetWidth, 1, 0),
            Position = UDim2.new(0, targetWidth, 0, 0)
        }, 0.2, Enum.EasingStyle.Quart)

        Tween(collapseIcon, {
            ImageColor3 = isSidebarCollapsed and GousseUI.Theme.Accent or GousseUI.Theme.TextSecondary
        }, 0.16)

        if activeIndicator then
            activeIndicator.Visible = not isSidebarCollapsed and (WindowObj and WindowObj.ActiveTab ~= nil)
        end
    end

    collapseBtn.MouseButton1Click:Connect(function()
        ToggleSidebar()
    end)

    -- Window Object Definition
    local WindowObj
    WindowObj = {
        ScreenGui = screenGui,
        MainFrame = mainFrame,
        FAB = fabBtn,
        Tabs = {},
        ActiveTab = nil
    }

    function WindowObj:Toggle(state: boolean?)
        ToggleWindow(state)
    end

    function WindowObj:Destroy()
        screenGui:Destroy()
    end

    -- Real-time Search Filter Bar in ContentArea
    local searchBarHeight = if isMobile then 32 else 26
    local searchContainer = Instance.new("Frame")
    searchContainer.Name = "SearchContainer"
    searchContainer.Size = UDim2.new(1, -16, 0, searchBarHeight)
    searchContainer.Position = UDim2.new(0, 8, 0, 6)
    searchContainer.BackgroundColor3 = GousseUI.Theme.Surface
    searchContainer.BorderSizePixel = 0
    searchContainer.Parent = contentArea

    local searchCorner = Instance.new("UICorner")
    searchCorner.CornerRadius = UDim.new(0, 6)
    searchCorner.Parent = searchContainer

    local searchStroke = Instance.new("UIStroke")
    searchStroke.Color = GousseUI.Theme.Border
    searchStroke.Thickness = 1
    searchStroke.Parent = searchContainer

    local searchIcon = Instance.new("ImageLabel")
    searchIcon.Name = "SearchIcon"
    searchIcon.Size = UDim2.new(0, 14, 0, 14)
    searchIcon.Position = UDim2.new(0, 8, 0.5, -7)
    searchIcon.BackgroundTransparency = 1
    searchIcon.Image = RawIcons["search"] or "rbxassetid://10734943674"
    searchIcon.ImageColor3 = GousseUI.Theme.TextMuted
    searchIcon.Parent = searchContainer

    local searchInput = Instance.new("TextBox")
    searchInput.Name = "SearchInput"
    searchInput.Size = UDim2.new(1, -54, 1, 0)
    searchInput.Position = UDim2.new(0, 28, 0, 0)
    searchInput.BackgroundTransparency = 1
    searchInput.Font = FontRegular
    searchInput.PlaceholderText = "Search features..."
    searchInput.PlaceholderColor3 = GousseUI.Theme.TextMuted
    searchInput.Text = ""
    searchInput.TextColor3 = GousseUI.Theme.TextPrimary
    searchInput.TextSize = 11.5
    searchInput.ClearTextOnFocus = false
    searchInput.TextXAlignment = Enum.TextXAlignment.Left
    searchInput.Parent = searchContainer

    local clearSearchBtn = Instance.new("TextButton")
    clearSearchBtn.Name = "ClearSearchBtn"
    clearSearchBtn.Size = UDim2.new(0, 18, 0, 18)
    clearSearchBtn.Position = UDim2.new(1, -24, 0.5, -9)
    clearSearchBtn.BackgroundTransparency = 1
    clearSearchBtn.Font = FontMedium
    clearSearchBtn.Text = "✕"
    clearSearchBtn.TextColor3 = GousseUI.Theme.TextMuted
    clearSearchBtn.TextSize = 10
    clearSearchBtn.Visible = false
    clearSearchBtn.Parent = searchContainer

    local function FilterPageItems(page: ScrollingFrame, query: string)
        if not page then return end
        query = query:lower():gsub("^%s+", ""):gsub("%s+$", "")
        for _, child in ipairs(page:GetChildren()) do
            if child:IsA("GuiObject") and child.Name:sub(1, 2) ~= "UI" then
                if query == "" then
                    child.Visible = true
                else
                    if child.Name:sub(1, 8) == "Section_" then
                        child.Visible = false
                    else
                        local titleObj = child:FindFirstChild("ItemTitle", true) or child:FindFirstChild("Label", true)
                        local matched = false
                        if titleObj and titleObj:IsA("TextLabel") then
                            if titleObj.Text:lower():find(query, 1, true) then
                                matched = true
                            end
                        end
                        local tooltipAttr = child:GetAttribute("Tooltip")
                        if not matched and tooltipAttr and tostring(tooltipAttr):lower():find(query, 1, true) then
                            matched = true
                        end
                        child.Visible = matched
                    end
                end
            end
        end
    end

    local function TriggerSearchFilter()
        local query = searchInput.Text
        clearSearchBtn.Visible = (query ~= "")
        if WindowObj and WindowObj.ActiveTab and WindowObj.ActiveTab.Page then
            FilterPageItems(WindowObj.ActiveTab.Page, query)
        end
    end

    searchInput:GetPropertyChangedSignal("Text"):Connect(TriggerSearchFilter)
    clearSearchBtn.MouseButton1Click:Connect(function()
        searchInput.Text = ""
        TriggerSearchFilter()
    end)

    -- Helper: Build item title row with info (?) button & tooltip
    local function BuildTitleRow(parentFrame: GuiObject, name: string, subTitle: string?, rightPadding: number, rowHeight: number)
        local titleContainer = Instance.new("Frame")
        titleContainer.Name = "TitleContainer"
        titleContainer.Size = UDim2.new(1, -rightPadding, 0, rowHeight)
        titleContainer.Position = UDim2.new(0, 12, 0, 0)
        titleContainer.BackgroundTransparency = 1
        titleContainer.Parent = parentFrame

        local titleLayout = Instance.new("UIListLayout")
        titleLayout.FillDirection = Enum.FillDirection.Horizontal
        titleLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        titleLayout.SortOrder = Enum.SortOrder.LayoutOrder
        titleLayout.Padding = UDim.new(0, 6)
        titleLayout.Parent = titleContainer

        local label = Instance.new("TextLabel")
        label.Name = "ItemTitle"
        label.Size = UDim2.new(0, 0, 1, 0)
        label.AutomaticSize = Enum.AutomaticSize.X
        label.BackgroundTransparency = 1
        label.Font = FontMedium
        label.Text = name
        label.TextColor3 = GousseUI.Theme.TextPrimary
        label.TextSize = 12.5
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.LayoutOrder = 1
        label.Parent = titleContainer

        local infoBtn = nil
        if subTitle and subTitle ~= "" then
            infoBtn = Instance.new("TextButton")
            infoBtn.Name = "InfoBtn"
            infoBtn.Size = UDim2.new(0, 16, 0, 16)
            infoBtn.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
            infoBtn.Font = FontBold
            infoBtn.Text = "?"
            infoBtn.TextColor3 = GousseUI.Theme.TextSecondary
            infoBtn.TextSize = 10.5
            infoBtn.AutoButtonColor = false
            infoBtn.LayoutOrder = 2
            infoBtn.Parent = titleContainer

            local infoCorner = Instance.new("UICorner")
            infoCorner.CornerRadius = UDim.new(1, 0)
            infoCorner.Parent = infoBtn

            local infoStroke = Instance.new("UIStroke")
            infoStroke.Color = GousseUI.Theme.BorderLight
            infoStroke.Thickness = 0.8
            infoStroke.Parent = infoBtn

            parentFrame:SetAttribute("Tooltip", subTitle)
            AttachTooltip(infoBtn, subTitle)
        end

        return label, infoBtn
    end

    -- ========================================================================
    -- Tab Creation
    -- ========================================================================
    local currentTransitionToken = 0

    local function GetIndicatorTargetY(btn: GuiButton): number
        local btnAbsY = btn.AbsolutePosition.Y
        local sideAbsY = sidebar.AbsolutePosition.Y
        if btnAbsY == 0 and sideAbsY == 0 then
            local tabIndex = 1
            for idx, t in ipairs(WindowObj.Tabs) do
                if t.Button == btn then
                    tabIndex = idx
                    break
                end
            end
            local h = if isMobile then 38 else 32
            return 6 + (tabIndex - 1) * (h + 4) + (h - 18) / 2
        end
        local relY = btnAbsY - sideAbsY
        local btnHeight = btn.AbsoluteSize.Y
        if btnHeight == 0 then btnHeight = if isMobile then 38 else 32 end
        return relY + (btnHeight - 18) / 2
    end

    tabListContainer:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
        if WindowObj and WindowObj.ActiveTab and WindowObj.ActiveTab.Button and activeIndicator.Visible and not isSidebarCollapsed then
            local targetY = GetIndicatorTargetY(WindowObj.ActiveTab.Button)
            activeIndicator.Position = UDim2.new(0, 4, 0, targetY)
        end
    end)

    function WindowObj:CreateTab(tabConfig: { Name: string, Icon: string? })
        tabConfig = tabConfig or {}
        local tabName = tabConfig.Name or "Tab"
        local tabIconKey = tabConfig.Icon or "folder"

        -- Tab Button in Sidebar
        local tabHeight = if isMobile then 38 else 32
        local tabBtn = Instance.new("TextButton")
        tabBtn.Name = "TabBtn_" .. tabName
        tabBtn.Size = UDim2.new(1, 0, 0, tabHeight)
        tabBtn.BackgroundColor3 = GousseUI.Theme.Surface
        tabBtn.BackgroundTransparency = 1
        tabBtn.Font = FontMedium
        tabBtn.Text = ""
        tabBtn.AutoButtonColor = false
        tabBtn.Parent = tabListContainer

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 6)
        btnCorner.Parent = tabBtn

        -- Icon ImageLabel
        local iconAsset = GousseUI:GetIcon(tabIconKey)
        local iconLabel = nil

        if iconAsset then
            local iconImg = Instance.new("ImageLabel")
            iconImg.Name = "Icon"
            iconImg.Size = UDim2.new(0, 16, 0, 16)
            iconImg.Position = UDim2.new(0, 8, 0.5, -8)
            iconImg.BackgroundTransparency = 1
            iconImg.Image = iconAsset
            iconImg.ImageColor3 = GousseUI.Theme.TextSecondary
            iconImg.Parent = tabBtn
            iconLabel = iconImg
        else
            local fallbackText = Instance.new("TextLabel")
            fallbackText.Name = "Icon"
            fallbackText.Size = UDim2.new(0, 16, 1, 0)
            fallbackText.Position = UDim2.new(0, 8, 0, 0)
            fallbackText.BackgroundTransparency = 1
            fallbackText.Font = FontRegular
            fallbackText.Text = tabIconKey
            fallbackText.TextColor3 = GousseUI.Theme.TextSecondary
            fallbackText.TextSize = 12
            fallbackText.Parent = tabBtn
            iconLabel = fallbackText
        end

        local tabTextLabel = Instance.new("TextLabel")
        tabTextLabel.Name = "Label"
        tabTextLabel.Size = UDim2.new(1, -30, 1, 0)
        tabTextLabel.Position = UDim2.new(0, 28, 0, 0)
        tabTextLabel.BackgroundTransparency = 1
        tabTextLabel.Font = FontMedium
        tabTextLabel.Text = tabName
        tabTextLabel.TextColor3 = GousseUI.Theme.TextSecondary
        tabTextLabel.TextSize = 12
        tabTextLabel.TextXAlignment = Enum.TextXAlignment.Left
        tabTextLabel.Parent = tabBtn

        -- Tab CanvasGroup Container (Handles whole-page fade & slide without child clipping issues)
        local pageTopOffset = 6 + searchBarHeight + 6
        local tabCanvas: any
        local okCg, cg = pcall(function()
            local c = Instance.new("CanvasGroup")
            c.GroupTransparency = 1
            return c
        end)
        if okCg and cg then
            tabCanvas = cg
        else
            local fallback = Instance.new("Frame")
            fallback.BackgroundTransparency = 1
            tabCanvas = fallback
        end

        tabCanvas.Name = "TabCanvas_" .. tabName
        tabCanvas.Size = UDim2.new(1, -16, 1, -pageTopOffset - 8)
        tabCanvas.Position = UDim2.new(0, 8, 0, pageTopOffset)
        tabCanvas.BackgroundTransparency = 1
        tabCanvas.BorderSizePixel = 0
        tabCanvas.Visible = false
        tabCanvas.Parent = contentArea

        -- Tab Page Scrolling Container inside CanvasGroup
        local tabPage = Instance.new("ScrollingFrame")
        tabPage.Name = "Page_" .. tabName
        tabPage.Size = UDim2.new(1, 0, 1, 0)
        tabPage.Position = UDim2.new(0, 0, 0, 0)
        tabPage.BackgroundTransparency = 1
        tabPage.BorderSizePixel = 0
        tabPage.ScrollBarThickness = 3
        tabPage.ScrollBarImageColor3 = GousseUI.Theme.BorderLight
        tabPage.CanvasSize = UDim2.new(0, 0, 0, 0)
        tabPage.AutomaticCanvasSize = Enum.AutomaticSize.Y
        tabPage.Visible = true
        tabPage.Parent = tabCanvas

        local pageLayout = Instance.new("UIListLayout")
        pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
        pageLayout.Padding = UDim.new(0, 6)
        pageLayout.Parent = tabPage

        -- Hide tooltip when scrolling
        tabPage:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
            if currentTooltipTarget and currentTooltipTarget:IsDescendantOf(tabPage) then
                HideTooltip()
            end
        end)

        local TabObj = {
            Name = tabName,
            Button = tabBtn,
            Canvas = tabCanvas,
            Page = tabPage
        }

        local function ActivateTab()
            if WindowObj.ActiveTab == TabObj then return end

            currentTransitionToken += 1
            local transitionToken = currentTransitionToken

            local prevTab = WindowObj.ActiveTab
            WindowObj.ActiveTab = TabObj

            -- 1. Deactivate Previous Tab Button
            if prevTab and prevTab.Button then
                Tween(prevTab.Button, { BackgroundTransparency = 1 }, 0.16)
                Tween(prevTab.Button.Label, {
                    TextColor3 = GousseUI.Theme.TextSecondary,
                    Position = UDim2.new(0, 28, 0, 0)
                }, 0.16)
                if prevTab.Button:FindFirstChild("Icon") then
                    if prevTab.Button.Icon:IsA("ImageLabel") then
                        Tween(prevTab.Button.Icon, {
                            ImageColor3 = GousseUI.Theme.TextSecondary,
                            Position = UDim2.new(0, 8, 0.5, -8)
                        }, 0.16)
                    else
                        prevTab.Button.Icon.TextColor3 = GousseUI.Theme.TextSecondary
                    end
                end
            end

            -- 2. Activate Current Tab Button
            Tween(tabBtn, { BackgroundTransparency = 0, BackgroundColor3 = GousseUI.Theme.Surface }, 0.18)
            Tween(tabTextLabel, {
                TextColor3 = GousseUI.Theme.TextPrimary,
                Position = UDim2.new(0, 32, 0, 0)
            }, 0.18)

            if iconLabel:IsA("ImageLabel") then
                Tween(iconLabel, {
                    ImageColor3 = GousseUI.Theme.Accent,
                    Position = UDim2.new(0, 10, 0.5, -8)
                }, 0.18)
            else
                iconLabel.TextColor3 = GousseUI.Theme.Accent
            end

            -- 3. Animated Active Indicator Glide (Smooth Y Tween)
            local targetIndY = GetIndicatorTargetY(tabBtn)
            if not activeIndicator.Visible then
                activeIndicator.Position = UDim2.new(0, 4, 0, targetIndY)
                activeIndicator.BackgroundTransparency = 1
                activeIndicator.Visible = true
                Tween(activeIndicator, { BackgroundTransparency = 0 }, 0.18)
            else
                Tween(activeIndicator, {
                    Position = UDim2.new(0, 4, 0, targetIndY)
                }, 0.24, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
            end

            -- 4. Sequential Page Transition (Old Tab Fades Out -> New Tab Fades In)
            local restingPos = UDim2.new(0, 8, 0, pageTopOffset)
            local slideLeftPos = UDim2.new(0, 8 - 10, 0, pageTopOffset)
            local slideRightPos = UDim2.new(0, 8 + 10, 0, pageTopOffset)

            if prevTab and prevTab.Canvas then
                local oldCanvas = prevTab.Canvas
                -- Old Tab Fades Out (GroupTransparency = 1) and slides left (-10px)
                local fadeOut = Tween(oldCanvas, {
                    GroupTransparency = 1,
                    Position = slideLeftPos
                }, 0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

                fadeOut.Completed:Connect(function()
                    if WindowObj.ActiveTab ~= prevTab then
                        oldCanvas.Visible = false
                        oldCanvas.Position = restingPos
                    end
                end)

                -- New Tab starts slightly after old tab begins fading, ensuring zero overlap
                task.delay(0.12, function()
                    if transitionToken ~= currentTransitionToken then return end
                    tabCanvas.Position = slideRightPos
                    tabCanvas.GroupTransparency = 1
                    tabCanvas.Visible = true
                    tabPage.CanvasPosition = Vector2.zero

                    Tween(tabCanvas, {
                        GroupTransparency = 0,
                        Position = restingPos
                    }, 0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

                    FilterPageItems(tabPage, searchInput.Text)
                end)
            else
                -- Instant show on initial UI launch
                tabCanvas.Position = restingPos
                tabCanvas.GroupTransparency = 0
                tabCanvas.Visible = true
                tabPage.CanvasPosition = Vector2.zero
                FilterPageItems(tabPage, searchInput.Text)
            end
        end

        tabBtn.MouseButton1Click:Connect(ActivateTab)

        tabBtn.MouseButton1Down:Connect(function()
            Tween(tabBtn, { BackgroundColor3 = GousseUI.Theme.SurfaceHover }, 0.06)
        end)

        tabBtn.MouseEnter:Connect(function()
            if WindowObj.ActiveTab ~= TabObj then
                Tween(tabBtn, { BackgroundTransparency = 0.5, BackgroundColor3 = GousseUI.Theme.SurfaceHover }, 0.1)
                tabTextLabel.TextColor3 = GousseUI.Theme.TextPrimary
            end
        end)
        tabBtn.MouseLeave:Connect(function()
            if WindowObj.ActiveTab ~= TabObj then
                Tween(tabBtn, { BackgroundTransparency = 1 }, 0.1)
                tabTextLabel.TextColor3 = GousseUI.Theme.TextSecondary
            end
        end)

        if #WindowObj.Tabs == 0 then
            ActivateTab()
        end

        table.insert(WindowObj.Tabs, TabObj)

        -- ====================================================================
        -- 1. Section Header: Understated uppercase label with subtle divider line
        -- ====================================================================
        function TabObj:CreateSection(name: string)
            local sectionHeader = Instance.new("Frame")
            sectionHeader.Name = "Section_" .. name
            sectionHeader.Size = UDim2.new(1, 0, 0, 22)
            sectionHeader.BackgroundTransparency = 1
            sectionHeader.Parent = tabPage

            local label = Instance.new("TextLabel")
            label.Name = "Label"
            label.Size = UDim2.new(0, 0, 1, 0)
            label.AutomaticSize = Enum.AutomaticSize.X
            label.Position = UDim2.new(0, 2, 0, 0)
            label.BackgroundTransparency = 1
            label.Font = FontBold
            label.Text = name:upper()
            label.TextColor3 = GousseUI.Theme.TextMuted
            label.TextSize = 10.5
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = sectionHeader

            local divider = Instance.new("Frame")
            divider.Name = "Divider"
            divider.Size = UDim2.new(1, -10, 0, 1)
            divider.Position = UDim2.new(0, 5, 0.5, 0)
            divider.BackgroundColor3 = GousseUI.Theme.Border
            divider.BorderSizePixel = 0
            divider.Parent = sectionHeader

            label:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
                local w = label.AbsoluteSize.X + 8
                divider.Position = UDim2.new(0, w, 0.5, 0)
                divider.Size = UDim2.new(1, -w - 4, 0, 1)
            end)
        end

        -- ====================================================================
        -- 2. Button Row (Primary, Secondary, or Danger variant, Matte Styled)
        -- ====================================================================
        function TabObj:CreateButton(btnConfig: {
            Name: string,
            SubTitle: string?,
            ButtonText: string?,
            Variant: string?, -- "primary" | "secondary" | "danger"
            Callback: (() -> ())?
        })
            btnConfig = btnConfig or {}
            local btnName = btnConfig.Name or "Button"
            local subTitle = btnConfig.SubTitle
            local btnText = btnConfig.ButtonText or "Run"
            local variant = btnConfig.Variant or "secondary"
            local callback = btnConfig.Callback or function() end

            local rowHeight = if isMobile then 42 else 38
            local btnFrame = Instance.new("Frame")
            btnFrame.Name = "BtnItem_" .. btnName
            btnFrame.Size = UDim2.new(1, 0, 0, rowHeight)
            btnFrame.BackgroundColor3 = GousseUI.Theme.Surface
            btnFrame.BorderSizePixel = 0
            btnFrame.Parent = tabPage

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 8)
            corner.Parent = btnFrame

            local stroke = Instance.new("UIStroke")
            stroke.Color = GousseUI.Theme.Border
            stroke.Thickness = 1
            stroke.Parent = btnFrame

            local btnWidth = if isMobile then 80 else 72
            local rightPadding = btnWidth + 16

            BuildTitleRow(btnFrame, btnName, subTitle, rightPadding, rowHeight)

            local actionBtn = Instance.new("TextButton")
            local actHeight = if isMobile then 28 else 24
            actionBtn.Size = UDim2.new(0, btnWidth, 0, actHeight)
            actionBtn.Position = UDim2.new(1, -btnWidth - 10, 0.5, -actHeight / 2)
            actionBtn.Font = FontMedium
            actionBtn.Text = btnText
            actionBtn.TextSize = 11.5
            actionBtn.AutoButtonColor = false
            actionBtn.Parent = btnFrame

            local actCorner = Instance.new("UICorner")
            actCorner.CornerRadius = UDim.new(0, 6)
            actCorner.Parent = actionBtn

            local actStroke = Instance.new("UIStroke")
            actStroke.Thickness = 1
            actStroke.Parent = actionBtn

            -- Matte appearance variants
            if variant == "primary" then
                actionBtn.BackgroundColor3 = GousseUI.Theme.Accent
                actionBtn.TextColor3 = GousseUI.Theme.Background
                actStroke.Color = GousseUI.Theme.AccentDark
            elseif variant == "danger" then
                actionBtn.BackgroundColor3 = Color3.fromRGB(225, 29, 72)
                actionBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                actStroke.Color = Color3.fromRGB(244, 63, 94)
            else -- secondary
                actionBtn.BackgroundColor3 = Color3.fromRGB(26, 35, 48)
                actionBtn.TextColor3 = GousseUI.Theme.TextPrimary
                actStroke.Color = GousseUI.Theme.BorderLight
            end

            actionBtn.MouseButton1Click:Connect(function()
                Tween(actionBtn, { BackgroundColor3 = GousseUI.Theme.SurfaceHover }, 0.08)
                task.delay(0.1, function()
                    local returnColor = (variant == "primary" and GousseUI.Theme.Accent) or (variant == "danger" and Color3.fromRGB(225, 29, 72)) or Color3.fromRGB(26, 35, 48)
                    Tween(actionBtn, { BackgroundColor3 = returnColor }, 0.1)
                end)
                pcall(callback)
            end)
        end

        -- ====================================================================
        -- 3. Toggle Row: Full Row Tap Target, Tactile Switch & Floating Tooltip (?)
        -- ====================================================================
        function TabObj:CreateToggle(toggleConfig: {
            Name: string,
            SubTitle: string?,
            Default: boolean?,
            Callback: ((boolean) -> ())?
        })
            toggleConfig = toggleConfig or {}
            local toggleName = toggleConfig.Name or "Toggle"
            local subTitle = toggleConfig.SubTitle
            local state = toggleConfig.Default or false
            local callback = toggleConfig.Callback or function() end

            local rowHeight = if isMobile then 42 else 38
            local toggleBtn = Instance.new("TextButton")
            toggleBtn.Name = "ToggleItem_" .. toggleName
            toggleBtn.Size = UDim2.new(1, 0, 0, rowHeight)
            toggleBtn.BackgroundColor3 = GousseUI.Theme.Surface
            toggleBtn.BorderSizePixel = 0
            toggleBtn.Text = ""
            toggleBtn.AutoButtonColor = false
            toggleBtn.Parent = tabPage

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 8)
            corner.Parent = toggleBtn

            local stroke = Instance.new("UIStroke")
            stroke.Color = GousseUI.Theme.Border
            stroke.Thickness = 1
            stroke.Parent = toggleBtn

            local _, infoBtn = BuildTitleRow(toggleBtn, toggleName, subTitle, 65, rowHeight)

            -- Switch Track (38x20)
            local switchTrack = Instance.new("Frame")
            switchTrack.Size = UDim2.new(0, 38, 0, 20)
            switchTrack.Position = UDim2.new(1, -48, 0.5, -10)
            switchTrack.BackgroundColor3 = state and GousseUI.Theme.Accent or GousseUI.Theme.Border
            switchTrack.BorderSizePixel = 0
            switchTrack.Parent = toggleBtn

            local trackCorner = Instance.new("UICorner")
            trackCorner.CornerRadius = UDim.new(1, 0)
            trackCorner.Parent = switchTrack

            -- Switch Knob (14x14)
            local switchKnob = Instance.new("Frame")
            switchKnob.Size = UDim2.new(0, 14, 0, 14)
            switchKnob.Position = state and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
            switchKnob.BackgroundColor3 = state and GousseUI.Theme.Background or GousseUI.Theme.TextSecondary
            switchKnob.BorderSizePixel = 0
            switchKnob.Parent = switchTrack

            local knobCorner = Instance.new("UICorner")
            knobCorner.CornerRadius = UDim.new(1, 0)
            knobCorner.Parent = switchKnob

            local function SetState(newState: boolean)
                state = newState
                local targetPos = state and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
                local targetColor = state and GousseUI.Theme.Accent or GousseUI.Theme.Border
                local knobColor = state and GousseUI.Theme.Background or GousseUI.Theme.TextSecondary

                Tween(switchTrack, { BackgroundColor3 = targetColor }, 0.14)
                Tween(switchKnob, { Position = targetPos, BackgroundColor3 = knobColor }, 0.14)

                pcall(callback, state)
            end

            local lastInfoTap = 0
            if infoBtn then
                infoBtn.MouseButton1Click:Connect(function()
                    lastInfoTap = tick()
                end)
            end

            toggleBtn.MouseButton1Click:Connect(function()
                if tick() - lastInfoTap < 0.25 then return end
                SetState(not state)
            end)

            toggleBtn.MouseEnter:Connect(function()
                Tween(toggleBtn, { BackgroundColor3 = GousseUI.Theme.SurfaceHover }, 0.1)
            end)
            toggleBtn.MouseLeave:Connect(function()
                Tween(toggleBtn, { BackgroundColor3 = GousseUI.Theme.Surface }, 0.1)
            end)

            if toggleConfig.Default then
                pcall(callback, state)
            end

            return {
                Set = SetState,
                Get = function() return state end
            }
        end

        -- ====================================================================
        -- 4. Slider Row: Inline Label, Value & Responsive Touch Track
        -- ====================================================================
        function TabObj:CreateSlider(sliderConfig: {
            Name: string,
            SubTitle: string?,
            Min: number?,
            Max: number?,
            Default: number?,
            Decimals: number?,
            Suffix: string?,
            Callback: ((number) -> ())?
        })
            sliderConfig = sliderConfig or {}
            local sliderName = sliderConfig.Name or "Slider"
            local subTitle = sliderConfig.SubTitle
            local minVal = sliderConfig.Min or 0
            local maxVal = sliderConfig.Max or 100
            local defaultVal = math.clamp(sliderConfig.Default or minVal, minVal, maxVal)
            local decimals = sliderConfig.Decimals or 0
            local suffix = sliderConfig.Suffix or ""
            local callback = sliderConfig.Callback or function() end

            local currentVal = defaultVal

            local rowHeight = if isMobile then 48 else 42
            local sliderFrame = Instance.new("Frame")
            sliderFrame.Name = "SliderItem_" .. sliderName
            sliderFrame.Size = UDim2.new(1, 0, 0, rowHeight)
            sliderFrame.BackgroundColor3 = GousseUI.Theme.Surface
            sliderFrame.BorderSizePixel = 0
            sliderFrame.Parent = tabPage

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 8)
            corner.Parent = sliderFrame

            local stroke = Instance.new("UIStroke")
            stroke.Color = GousseUI.Theme.Border
            stroke.Thickness = 1
            stroke.Parent = sliderFrame

            -- Title with info button on top line
            local topRowHeight = 20
            local titleContainer = Instance.new("Frame")
            titleContainer.Name = "TitleContainer"
            titleContainer.Size = UDim2.new(0.65, 0, 0, topRowHeight)
            titleContainer.Position = UDim2.new(0, 12, 0, 4)
            titleContainer.BackgroundTransparency = 1
            titleContainer.Parent = sliderFrame

            local titleLayout = Instance.new("UIListLayout")
            titleLayout.FillDirection = Enum.FillDirection.Horizontal
            titleLayout.VerticalAlignment = Enum.VerticalAlignment.Center
            titleLayout.SortOrder = Enum.SortOrder.LayoutOrder
            titleLayout.Padding = UDim.new(0, 6)
            titleLayout.Parent = titleContainer

            local label = Instance.new("TextLabel")
            label.Name = "ItemTitle"
            label.Size = UDim2.new(0, 0, 1, 0)
            label.AutomaticSize = Enum.AutomaticSize.X
            label.BackgroundTransparency = 1
            label.Font = FontMedium
            label.Text = sliderName
            label.TextColor3 = GousseUI.Theme.TextPrimary
            label.TextSize = 12.5
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.LayoutOrder = 1
            label.Parent = titleContainer

            if subTitle and subTitle ~= "" then
                local infoBtn = Instance.new("TextButton")
                infoBtn.Name = "InfoBtn"
                infoBtn.Size = UDim2.new(0, 15, 0, 15)
                infoBtn.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
                infoBtn.Font = FontBold
                infoBtn.Text = "?"
                infoBtn.TextColor3 = GousseUI.Theme.TextSecondary
                infoBtn.TextSize = 10
                infoBtn.AutoButtonColor = false
                infoBtn.LayoutOrder = 2
                infoBtn.Parent = titleContainer

                local infoCorner = Instance.new("UICorner")
                infoCorner.CornerRadius = UDim.new(1, 0)
                infoCorner.Parent = infoBtn

                local infoStroke = Instance.new("UIStroke")
                infoStroke.Color = GousseUI.Theme.BorderLight
                infoStroke.Thickness = 0.8
                infoStroke.Parent = infoBtn

                sliderFrame:SetAttribute("Tooltip", subTitle)
                AttachTooltip(infoBtn, subTitle)
            end

            local valueLabel = Instance.new("TextLabel")
            valueLabel.Size = UDim2.new(0.35, -20, 0, topRowHeight)
            valueLabel.Position = UDim2.new(0.65, 8, 0, 4)
            valueLabel.BackgroundTransparency = 1
            valueLabel.Font = FontCode
            valueLabel.Text = tostring(currentVal) .. suffix
            valueLabel.TextColor3 = GousseUI.Theme.Accent
            valueLabel.TextSize = 12
            valueLabel.TextXAlignment = Enum.TextXAlignment.Right
            valueLabel.Parent = sliderFrame

            -- Slider Track
            local track = Instance.new("TextButton")
            track.Name = "Track"
            track.Size = UDim2.new(1, -24, 0, 5)
            track.Position = UDim2.new(0, 12, 0, if isMobile then 30 else 26)
            track.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
            track.Text = ""
            track.AutoButtonColor = false
            track.Parent = sliderFrame

            local trackCorner = Instance.new("UICorner")
            trackCorner.CornerRadius = UDim.new(1, 0)
            trackCorner.Parent = track

            local fill = Instance.new("Frame")
            fill.Name = "Fill"
            local initialRatio = (currentVal - minVal) / (maxVal - minVal)
            fill.Size = UDim2.new(initialRatio, 0, 1, 0)
            fill.BackgroundColor3 = GousseUI.Theme.Accent
            fill.BorderSizePixel = 0
            fill.Parent = track

            local fillCorner = Instance.new("UICorner")
            fillCorner.CornerRadius = UDim.new(1, 0)
            fillCorner.Parent = fill

            local sliding = false

            local function UpdateSlider(inputX: number)
                local trackPos = track.AbsolutePosition.X
                local trackWidth = track.AbsoluteSize.X
                local ratio = math.clamp((inputX - trackPos) / trackWidth, 0, 1)

                local rawVal = minVal + (maxVal - minVal) * ratio
                local mult = 10 ^ decimals
                currentVal = math.floor(rawVal * mult + 0.5) / mult

                fill.Size = UDim2.new(ratio, 0, 1, 0)
                valueLabel.Text = tostring(currentVal) .. suffix

                pcall(callback, currentVal)
            end

            track.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    sliding = true
                    UpdateSlider(input.Position.X)
                end
            end)

            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    sliding = false
                end
            end)

            UserInputService.InputChanged:Connect(function(input)
                if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    UpdateSlider(input.Position.X)
                end
            end)

            return {
                Set = function(newVal)
                    currentVal = math.clamp(newVal, minVal, maxVal)
                    local ratio = (currentVal - minVal) / (maxVal - minVal)
                    fill.Size = UDim2.new(ratio, 0, 1, 0)
                    valueLabel.Text = tostring(currentVal) .. suffix
                    pcall(callback, currentVal)
                end,
                Get = function() return currentVal end
            }
        end

        -- ====================================================================
        -- 5. Dropdown Row: Floating Popover with Outside-Tap Overlay & Mobile Scroll Lock
        -- ====================================================================
        function TabObj:CreateDropdown(dropConfig: {
            Name: string,
            SubTitle: string?,
            Options: {string},
            Default: string?,
            Callback: ((string) -> ())?
        })
            dropConfig = dropConfig or {}
            local dropName = dropConfig.Name or "Dropdown"
            local subTitle = dropConfig.SubTitle
            local options = dropConfig.Options or {}
            local selected = dropConfig.Default or options[1] or ""
            local callback = dropConfig.Callback or function() end

            local isOpen = false
            local baseHeight = if isMobile then 42 else 38

            -- Base Row Frame (Permanently locked height, never shifts title or controls)
            local dropFrame = Instance.new("Frame")
            dropFrame.Name = "DropItem_" .. dropName
            dropFrame.Size = UDim2.new(1, 0, 0, baseHeight)
            dropFrame.BackgroundColor3 = GousseUI.Theme.Surface
            dropFrame.BorderSizePixel = 0
            dropFrame.Parent = tabPage

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 8)
            corner.Parent = dropFrame

            local stroke = Instance.new("UIStroke")
            stroke.Color = GousseUI.Theme.Border
            stroke.Thickness = 1
            stroke.Parent = dropFrame

            -- Title & Info Button stay permanently anchored at top-left
            BuildTitleRow(dropFrame, dropName, subTitle, 140, baseHeight)

            local triggerBtn = Instance.new("TextButton")
            local trigHeight = if isMobile then 28 else 24
            triggerBtn.Size = UDim2.new(0, 120, 0, trigHeight)
            triggerBtn.Position = UDim2.new(1, -130, 0, (baseHeight - trigHeight) / 2)
            triggerBtn.BackgroundColor3 = GousseUI.Theme.Sidebar
            triggerBtn.Font = FontMedium
            triggerBtn.Text = selected .. " ▾"
            triggerBtn.TextColor3 = GousseUI.Theme.TextPrimary
            triggerBtn.TextSize = 11.5
            triggerBtn.AutoButtonColor = false
            triggerBtn.ZIndex = 5
            triggerBtn.Parent = dropFrame

            local trigCorner = Instance.new("UICorner")
            trigCorner.CornerRadius = UDim.new(0, 6)
            trigCorner.Parent = triggerBtn

            local trigStroke = Instance.new("UIStroke")
            trigStroke.Color = GousseUI.Theme.Border
            trigStroke.Thickness = 1
            trigStroke.Parent = triggerBtn

            -- Popover references
            local popoverFrame: Frame? = nil
            local overlayBtn: TextButton? = nil

            local function CloseDropdown()
                if not isOpen then return end
                isOpen = false
                triggerBtn.Text = selected .. " ▾"

                -- Restore MainContent scrolling immediately
                tabPage.ScrollingEnabled = true

                if popoverFrame then
                    local targetRef = popoverFrame
                    popoverFrame = nil
                    local tw = Tween(targetRef, {
                        Size = UDim2.new(targetRef.Size.X.Scale, targetRef.Size.X.Offset, 0, 0)
                    }, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
                    tw.Completed:Connect(function()
                        targetRef:Destroy()
                    end)
                end

                if overlayBtn then
                    overlayBtn:Destroy()
                    overlayBtn = nil
                end
            end

            local function OpenDropdown()
                if isOpen then return end
                isOpen = true
                triggerBtn.Text = selected .. " ▴"

                -- Lock MainContent scrolling so mobile touch gestures scroll only the popover
                tabPage.ScrollingEnabled = false

                -- 1. Full ContentArea Transparent Overlay to detect taps outside
                overlayBtn = Instance.new("TextButton")
                overlayBtn.Name = "DropdownOverlay"
                overlayBtn.Size = UDim2.new(1, 0, 1, 0)
                overlayBtn.Position = UDim2.new(0, 0, 0, 0)
                overlayBtn.BackgroundTransparency = 1
                overlayBtn.Text = ""
                overlayBtn.AutoButtonColor = false
                overlayBtn.ZIndex = 50
                overlayBtn.Parent = contentArea

                overlayBtn.MouseButton1Click:Connect(CloseDropdown)

                -- 2. Floating Popover Frame
                local itemHeight = if isMobile then 30 else 26
                local itemGap = 3
                local totalContentHeight = #options * (itemHeight + itemGap) + 8
                local maxPopoverHeight = 150
                local targetHeight = math.clamp(totalContentHeight, 34, maxPopoverHeight)

                -- Calculate absolute position mapped to contentArea
                local dropAbs = dropFrame.AbsolutePosition
                local contentAbs = contentArea.AbsolutePosition
                local relX = dropAbs.X - contentAbs.X
                local relY = dropAbs.Y - contentAbs.Y + baseHeight + 4
                local popWidth = dropFrame.AbsoluteSize.X

                -- Flip popover above dropFrame if it would overflow the bottom
                if relY + targetHeight > contentArea.AbsoluteSize.Y - 8 then
                    relY = math.max(4, dropAbs.Y - contentAbs.Y - targetHeight - 4)
                end

                popoverFrame = Instance.new("Frame")
                popoverFrame.Name = "DropdownPopover_" .. dropName
                popoverFrame.Size = UDim2.new(0, popWidth, 0, 0) -- Starts at height 0 for smooth opening animation
                popoverFrame.Position = UDim2.new(0, relX, 0, relY)
                popoverFrame.BackgroundColor3 = GousseUI.Theme.Surface
                popoverFrame.BorderSizePixel = 0
                popoverFrame.ClipsDescendants = true
                popoverFrame.ZIndex = 60
                popoverFrame.Parent = contentArea

                local popCorner = Instance.new("UICorner")
                popCorner.CornerRadius = UDim.new(0, 8)
                popCorner.Parent = popoverFrame

                local popStroke = Instance.new("UIStroke")
                popStroke.Color = GousseUI.Theme.BorderLight
                popStroke.Thickness = 1
                popStroke.Parent = popoverFrame

                -- ScrollingFrame for options with max height ~150px
                local listScroll = Instance.new("ScrollingFrame")
                listScroll.Name = "OptionsScroll"
                listScroll.Size = UDim2.new(1, 0, 1, 0)
                listScroll.Position = UDim2.new(0, 0, 0, 0)
                listScroll.BackgroundTransparency = 1
                listScroll.BorderSizePixel = 0
                listScroll.ScrollBarThickness = if isMobile then 4 else 3
                listScroll.ScrollBarImageColor3 = GousseUI.Theme.BorderLight
                listScroll.CanvasSize = UDim2.new(0, 0, 0, totalContentHeight)
                listScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
                listScroll.ClipsDescendants = true
                listScroll.ZIndex = 61
                listScroll.Parent = popoverFrame

                local listPad = Instance.new("UIPadding")
                listPad.PaddingTop = UDim.new(0, 4)
                listPad.PaddingBottom = UDim.new(0, 4)
                listPad.PaddingLeft = UDim.new(0, 4)
                listPad.PaddingRight = UDim.new(0, 4)
                listPad.Parent = listScroll

                local listLayout = Instance.new("UIListLayout")
                listLayout.SortOrder = Enum.SortOrder.LayoutOrder
                listLayout.Padding = UDim.new(0, itemGap)
                listLayout.Parent = listScroll

                -- Render Option Buttons with centered text
                for _, opt in ipairs(options) do
                    local optBtn = Instance.new("TextButton")
                    optBtn.Name = "Opt_" .. opt
                    optBtn.Size = UDim2.new(1, 0, 0, itemHeight)
                    optBtn.BackgroundColor3 = (opt == selected) and Color3.fromRGB(24, 34, 48) or GousseUI.Theme.Sidebar
                    optBtn.Font = FontMedium
                    optBtn.Text = opt
                    optBtn.TextColor3 = (opt == selected) and GousseUI.Theme.Accent or GousseUI.Theme.TextPrimary
                    optBtn.TextSize = 11.5
                    optBtn.TextXAlignment = Enum.TextXAlignment.Center -- Centered text precision
                    optBtn.AutoButtonColor = false
                    optBtn.ZIndex = 62
                    optBtn.Parent = listScroll

                    local optCorner = Instance.new("UICorner")
                    optCorner.CornerRadius = UDim.new(0, 6)
                    optCorner.Parent = optBtn

                    optBtn.MouseEnter:Connect(function()
                        if opt ~= selected then
                            Tween(optBtn, { BackgroundColor3 = GousseUI.Theme.SurfaceHover }, 0.08)
                        end
                    end)
                    optBtn.MouseLeave:Connect(function()
                        if opt ~= selected then
                            Tween(optBtn, { BackgroundColor3 = GousseUI.Theme.Sidebar }, 0.08)
                        end
                    end)

                    optBtn.MouseButton1Click:Connect(function()
                        selected = opt
                        triggerBtn.Text = selected .. " ▾"
                        CloseDropdown()
                        pcall(callback, selected)
                    end)
                end

                -- Smooth Quart open animation
                Tween(popoverFrame, { Size = UDim2.new(0, popWidth, 0, targetHeight) }, 0.16, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
            end

            local function ToggleDropdown()
                if isOpen then
                    CloseDropdown()
                else
                    OpenDropdown()
                end
            end

            triggerBtn.MouseButton1Click:Connect(ToggleDropdown)

            -- Automatically close dropdown if user switches tabs or window hides
            tabPage:GetPropertyChangedSignal("Visible"):Connect(function()
                if not tabPage.Visible then
                    CloseDropdown()
                end
            end)

            return {
                Set = function(val)
                    selected = val
                    triggerBtn.Text = selected .. " ▾"
                    pcall(callback, selected)
                end,
                Refresh = function(newOpts: {string}, newDef: string?)
                    options = newOpts or {}
                    selected = newDef or options[1] or ""
                    triggerBtn.Text = selected .. " ▾"
                    if isOpen then
                        CloseDropdown()
                    end
                end,
                Get = function() return selected end
            }
        end

        -- ====================================================================
        -- 6. Text Input Box Row
        -- ====================================================================
        function TabObj:CreateInput(inputConfig: {
            Name: string,
            SubTitle: string?,
            Placeholder: string?,
            Callback: ((string) -> ())?
        })
            inputConfig = inputConfig or {}
            local inputName = inputConfig.Name or "Input"
            local subTitle = inputConfig.SubTitle
            local placeholder = inputConfig.Placeholder or "Enter value..."
            local callback = inputConfig.Callback or function() end

            local rowHeight = if isMobile then 42 else 38
            local inputFrame = Instance.new("Frame")
            inputFrame.Name = "InputItem_" .. inputName
            inputFrame.Size = UDim2.new(1, 0, 0, rowHeight)
            inputFrame.BackgroundColor3 = GousseUI.Theme.Surface
            inputFrame.BorderSizePixel = 0
            inputFrame.Parent = tabPage

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 8)
            corner.Parent = inputFrame

            local stroke = Instance.new("UIStroke")
            stroke.Color = GousseUI.Theme.Border
            stroke.Thickness = 1
            stroke.Parent = inputFrame

            BuildTitleRow(inputFrame, inputName, subTitle, 140, rowHeight)

            local boxHeight = if isMobile then 28 else 24
            local textBox = Instance.new("TextBox")
            textBox.Size = UDim2.new(0, 120, 0, boxHeight)
            textBox.Position = UDim2.new(1, -130, 0.5, -boxHeight / 2)
            textBox.BackgroundColor3 = GousseUI.Theme.Sidebar
            textBox.Font = FontCode
            textBox.PlaceholderText = placeholder
            textBox.PlaceholderColor3 = GousseUI.Theme.TextMuted
            textBox.Text = ""
            textBox.TextColor3 = GousseUI.Theme.TextPrimary
            textBox.TextSize = 11.5
            textBox.ClearTextOnFocus = false
            textBox.Parent = inputFrame

            local boxCorner = Instance.new("UICorner")
            boxCorner.CornerRadius = UDim.new(0, 6)
            boxCorner.Parent = textBox

            local boxStroke = Instance.new("UIStroke")
            boxStroke.Color = GousseUI.Theme.Border
            boxStroke.Thickness = 1
            boxStroke.Parent = textBox

            textBox.FocusLost:Connect(function()
                pcall(callback, textBox.Text)
            end)

            return {
                Set = function(val) textBox.Text = tostring(val) end,
                Get = function() return textBox.Text end
            }
        end

        -- ====================================================================
        -- 7. Paragraph / Info Card (Clean & Understated)
        -- ====================================================================
        function TabObj:CreateParagraph(paraConfig: { Title: string, Content: string })
            paraConfig = paraConfig or {}
            local titleText = paraConfig.Title or "Notice"
            local bodyText = paraConfig.Content or ""

            local card = Instance.new("Frame")
            card.Name = "Paragraph_" .. titleText
            card.Size = UDim2.new(1, 0, 0, 52)
            card.AutomaticSize = Enum.AutomaticSize.Y
            card.BackgroundColor3 = GousseUI.Theme.Surface
            card.BorderSizePixel = 0
            card.Parent = tabPage

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 8)
            corner.Parent = card

            local stroke = Instance.new("UIStroke")
            stroke.Color = GousseUI.Theme.Border
            stroke.Thickness = 1
            stroke.Parent = card

            local title = Instance.new("TextLabel")
            title.Name = "ItemTitle"
            title.Size = UDim2.new(1, -24, 0, 18)
            title.Position = UDim2.new(0, 12, 0, 8)
            title.BackgroundTransparency = 1
            title.Font = FontMedium
            title.Text = titleText
            title.TextColor3 = GousseUI.Theme.TextPrimary
            title.TextSize = 12.5
            title.TextXAlignment = Enum.TextXAlignment.Left
            title.Parent = card

            local content = Instance.new("TextLabel")
            content.Size = UDim2.new(1, -24, 0, 0)
            content.AutomaticSize = Enum.AutomaticSize.Y
            content.Position = UDim2.new(0, 12, 0, 28)
            content.BackgroundTransparency = 1
            content.Font = FontRegular
            content.Text = bodyText
            content.TextColor3 = GousseUI.Theme.TextSecondary
            content.TextSize = 11
            content.TextWrapped = true
            content.TextXAlignment = Enum.TextXAlignment.Left
            content.TextYAlignment = Enum.TextYAlignment.Top
            content.Parent = card

            local pad = Instance.new("UIPadding")
            pad.PaddingBottom = UDim.new(0, 10)
            pad.Parent = card
        end

        return TabObj
    end

    GousseUI:Notify({ Title = displayTitle, Content = "Loaded. Toggle hotkey: " .. toggleKey.Name, Duration = 3 })
    return WindowObj
end

return GousseUI
