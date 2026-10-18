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
        TextPrimary = Color3.fromRGB(248, 250, 252),    -- #F8FAFC Crisp white
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

-- Utility: Make UI Draggable (Works for Desktop Mouse and Mobile Touch, respects Center Anchors)
local function MakeDraggable(dragHandle: GuiObject, targetFrame: GuiObject)
    local dragging = false
    local dragInput, dragStart, startPos

    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = targetFrame.Position

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
            targetFrame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
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
    local windowTitle = config.Title or "Gousse Hub"
    local windowSubTitle = config.SubTitle or "Utility Console"
    local toggleKey = config.Keybind or GousseUI.ActiveKeybind
    GousseUI.ActiveKeybind = toggleKey

    local isMobile = if config.Mobile ~= nil then config.Mobile else (UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled)

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "GousseUI_" .. windowTitle:gsub("%s+", "")
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = 100
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = GetSafeGuiParent()

    local isVisible = true

    -- Main Window Outer Frame (Responsive Modern Tactical Frame)
    local mainFrame = Instance.new("Frame")
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

    -- Header / Title Bar (Compact: 42px on desktop, 48px on mobile for touch comfort)
    local headerHeight = if isMobile then 48 else 42
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

    -- Brand Icon: Emerald block with dark 'G'
    local brandIcon = Instance.new("TextLabel")
    brandIcon.Name = "BrandIcon"
    brandIcon.Size = UDim2.new(0, 24, 0, 24)
    brandIcon.Position = UDim2.new(0, 12, 0.5, -12)
    brandIcon.BackgroundColor3 = GousseUI.Theme.Accent
    brandIcon.Font = FontBold
    brandIcon.Text = "G"
    brandIcon.TextColor3 = GousseUI.Theme.Background
    brandIcon.TextSize = 13
    brandIcon.Parent = header

    local iconCorner = Instance.new("UICorner")
    iconCorner.CornerRadius = UDim.new(0, 6)
    iconCorner.Parent = brandIcon

    -- Title & Subtitle labels
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(1, -120, 0, 18)
    titleLabel.Position = UDim2.new(0, 44, 0, if isMobile then 6 else 4)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = FontBold
    titleLabel.Text = windowTitle
    titleLabel.TextColor3 = GousseUI.Theme.TextPrimary
    titleLabel.TextSize = 14
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = header

    local subTitleLabel = Instance.new("TextLabel")
    subTitleLabel.Name = "SubTitleLabel"
    subTitleLabel.Size = UDim2.new(1, -120, 0, 14)
    subTitleLabel.Position = UDim2.new(0, 44, 0, if isMobile then 25 else 22)
    subTitleLabel.BackgroundTransparency = 1
    subTitleLabel.Font = FontMedium
    subTitleLabel.Text = windowSubTitle
    subTitleLabel.TextColor3 = GousseUI.Theme.TextSecondary
    subTitleLabel.TextSize = 11
    subTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    subTitleLabel.Parent = header

    -- Window Controls (Minimize & Close)
    local controlsFrame = Instance.new("Frame")
    controlsFrame.Name = "Controls"
    local ctrlWidth = if isMobile then 86 else 56
    controlsFrame.Size = UDim2.new(0, ctrlWidth, 1, 0)
    controlsFrame.Position = UDim2.new(1, -ctrlWidth - 6, 0, 0)
    controlsFrame.BackgroundTransparency = 1
    controlsFrame.Parent = header

    local btnSize = if isMobile then 36 else 24
    local btnOffset = if isMobile then 42 else 28

    local btnMinimize = Instance.new("TextButton")
    btnMinimize.Name = "BtnMinimize"
    btnMinimize.Size = UDim2.new(0, btnSize, 0, btnSize)
    btnMinimize.Position = UDim2.new(0, 0, 0.5, -btnSize / 2)
    btnMinimize.BackgroundColor3 = GousseUI.Theme.Surface
    btnMinimize.Font = FontBold
    btnMinimize.Text = "—"
    btnMinimize.TextColor3 = GousseUI.Theme.TextSecondary
    btnMinimize.TextSize = 12
    btnMinimize.AutoButtonColor = false
    btnMinimize.Parent = controlsFrame

    local minCorner = Instance.new("UICorner")
    minCorner.CornerRadius = UDim.new(0, 6)
    minCorner.Parent = btnMinimize

    local btnClose = Instance.new("TextButton")
    btnClose.Name = "BtnClose"
    btnClose.Size = UDim2.new(0, btnSize, 0, btnSize)
    btnClose.Position = UDim2.new(0, btnOffset, 0.5, -btnSize / 2)
    btnClose.BackgroundColor3 = GousseUI.Theme.Surface
    btnClose.Font = FontBold
    btnClose.Text = "✕"
    btnClose.TextColor3 = GousseUI.Theme.TextSecondary
    btnClose.TextSize = 12
    btnClose.AutoButtonColor = false
    btnClose.Parent = controlsFrame

    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = btnClose

    MakeDraggable(header, mainFrame)

    local function ToggleWindow(state: boolean?)
        if state == nil then
            isVisible = not isVisible
        else
            isVisible = state
        end

        if isVisible then
            mainFrame.Visible = true
            Tween(mainFrame, { Position = UDim2.new(0.5, 0, 0.5, 0), BackgroundTransparency = 0 }, 0.16)
        else
            local tw = Tween(mainFrame, { Position = UDim2.new(0.5, 0, 0.5, 20), BackgroundTransparency = 1 }, 0.16)
            tw.Completed:Connect(function()
                if not isVisible then mainFrame.Visible = false end
            end)
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
        GousseUI:Notify({ Title = windowTitle, Content = tip, Duration = 3 })
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

    -- Left Navigation Sidebar
    local sidebarWidth = if isMobile then 125 else 145
    local sidebar = Instance.new("Frame")
    sidebar.Name = "Sidebar"
    sidebar.Size = UDim2.new(0, sidebarWidth, 1, 0)
    sidebar.BackgroundColor3 = GousseUI.Theme.Sidebar
    sidebar.BorderSizePixel = 0
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

    -- Right Content Area
    local contentArea = Instance.new("Frame")
    contentArea.Name = "ContentArea"
    contentArea.Size = UDim2.new(1, -sidebarWidth, 1, 0)
    contentArea.Position = UDim2.new(0, sidebarWidth, 0, 0)
    contentArea.BackgroundTransparency = 1
    contentArea.Parent = bodyFrame

    local WindowObj = {
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

    -- ========================================================================
    -- Tab Creation
    -- ========================================================================
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

        -- Active Indicator: 3px rounded emerald bar on left edge
        local activeBar = Instance.new("Frame")
        activeBar.Name = "ActiveBar"
        activeBar.Size = UDim2.new(0, 3, 0, 18)
        activeBar.Position = UDim2.new(0, 0, 0.5, -9)
        activeBar.BackgroundColor3 = GousseUI.Theme.Accent
        activeBar.BorderSizePixel = 0
        activeBar.BackgroundTransparency = 1
        activeBar.Parent = tabBtn

        local activeCorner = Instance.new("UICorner")
        activeCorner.CornerRadius = UDim.new(1, 0)
        activeCorner.Parent = activeBar

        -- Lucide Icon ImageLabel
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

        -- Tab Page Container (Right panel)
        local tabPage = Instance.new("ScrollingFrame")
        tabPage.Name = "Page_" .. tabName
        tabPage.Size = UDim2.new(1, -16, 1, -12)
        tabPage.Position = UDim2.new(0, 8, 0, 6)
        tabPage.BackgroundTransparency = 1
        tabPage.BorderSizePixel = 0
        tabPage.ScrollBarThickness = 3
        tabPage.ScrollBarImageColor3 = GousseUI.Theme.BorderLight
        tabPage.CanvasSize = UDim2.new(0, 0, 0, 0)
        tabPage.AutomaticCanvasSize = Enum.AutomaticSize.Y
        tabPage.Visible = false
        tabPage.Parent = contentArea

        local pageLayout = Instance.new("UIListLayout")
        pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
        pageLayout.Padding = UDim.new(0, 6)
        pageLayout.Parent = tabPage

        local TabObj = {
            Name = tabName,
            Button = tabBtn,
            Page = tabPage
        }

        local function ActivateTab()
            for _, t in pairs(WindowObj.Tabs) do
                t.Page.Visible = false
                Tween(t.Button, { BackgroundTransparency = 1 }, 0.12)
                t.Button.ActiveBar.BackgroundTransparency = 1
                t.Button.Label.TextColor3 = GousseUI.Theme.TextSecondary
                if t.Button:FindFirstChild("Icon") then
                    if t.Button.Icon:IsA("ImageLabel") then
                        t.Button.Icon.ImageColor3 = GousseUI.Theme.TextSecondary
                    else
                        t.Button.Icon.TextColor3 = GousseUI.Theme.TextSecondary
                    end
                end
            end

            tabPage.Visible = true
            Tween(tabBtn, { BackgroundTransparency = 0, BackgroundColor3 = GousseUI.Theme.Surface }, 0.12)
            activeBar.BackgroundTransparency = 0
            tabTextLabel.TextColor3 = GousseUI.Theme.TextPrimary
            if iconLabel:IsA("ImageLabel") then
                iconLabel.ImageColor3 = GousseUI.Theme.Accent
            else
                iconLabel.TextColor3 = GousseUI.Theme.Accent
            end
            WindowObj.ActiveTab = TabObj
        end

        tabBtn.MouseButton1Click:Connect(ActivateTab)

        -- Hover effect for inactive items
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
        -- 2. Button Row (Primary, Secondary, or Danger variant)
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

            local rowHeight = if subTitle then (if isMobile then 48 else 42) else (if isMobile then 42 else 34)
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

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, -rightPadding, 0, if subTitle then 18 else rowHeight)
            label.Position = UDim2.new(0, 12, 0, if subTitle then 5 else 0)
            label.BackgroundTransparency = 1
            label.Font = FontMedium
            label.Text = btnName
            label.TextColor3 = GousseUI.Theme.TextPrimary
            label.TextSize = 12.5
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = btnFrame

            if subTitle then
                local descLabel = Instance.new("TextLabel")
                descLabel.Size = UDim2.new(1, -rightPadding, 0, 16)
                descLabel.Position = UDim2.new(0, 12, 0, 24)
                descLabel.BackgroundTransparency = 1
                descLabel.Font = FontRegular
                descLabel.Text = subTitle
                descLabel.TextColor3 = GousseUI.Theme.TextSecondary
                descLabel.TextSize = 11
                descLabel.TextXAlignment = Enum.TextXAlignment.Left
                descLabel.Parent = btnFrame
            end

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

            -- Variant appearance
            if variant == "primary" then
                actionBtn.BackgroundColor3 = Color3.fromRGB(20, 52, 38)
                actionBtn.TextColor3 = GousseUI.Theme.Accent
                actStroke.Color = GousseUI.Theme.Accent
            elseif variant == "danger" then
                actionBtn.BackgroundColor3 = Color3.fromRGB(60, 24, 28)
                actionBtn.TextColor3 = GousseUI.Theme.Danger
                actStroke.Color = GousseUI.Theme.Danger
            else -- secondary
                actionBtn.BackgroundColor3 = Color3.fromRGB(26, 35, 48)
                actionBtn.TextColor3 = GousseUI.Theme.TextPrimary
                actStroke.Color = GousseUI.Theme.Border
            end

            actionBtn.MouseButton1Click:Connect(function()
                Tween(actionBtn, { BackgroundColor3 = GousseUI.Theme.SurfaceHover }, 0.08)
                task.delay(0.1, function()
                    local returnColor = (variant == "primary" and Color3.fromRGB(20, 52, 38)) or (variant == "danger" and Color3.fromRGB(60, 24, 28)) or Color3.fromRGB(26, 35, 48)
                    Tween(actionBtn, { BackgroundColor3 = returnColor }, 0.1)
                end)
                pcall(callback)
            end)
        end

        -- ====================================================================
        -- 3. Toggle Row: Full Row Tap Target, High Contrast & Tactile Switch
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

            local rowHeight = if subTitle then (if isMobile then 50 else 44) else (if isMobile then 44 else 36)
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

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, -65, 0, if subTitle then 18 else rowHeight)
            label.Position = UDim2.new(0, 12, 0, if subTitle then 5 else 0)
            label.BackgroundTransparency = 1
            label.Font = FontMedium
            label.Text = toggleName
            label.TextColor3 = GousseUI.Theme.TextPrimary
            label.TextSize = 12.5
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = toggleBtn

            if subTitle then
                local descLabel = Instance.new("TextLabel")
                descLabel.Size = UDim2.new(1, -65, 0, 16)
                descLabel.Position = UDim2.new(0, 12, 0, 24)
                descLabel.BackgroundTransparency = 1
                descLabel.Font = FontRegular
                descLabel.Text = subTitle
                descLabel.TextColor3 = GousseUI.Theme.TextSecondary
                descLabel.TextSize = 11
                descLabel.TextXAlignment = Enum.TextXAlignment.Left
                descLabel.Parent = toggleBtn
            end

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

            toggleBtn.MouseButton1Click:Connect(function()
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
        -- 4. Slider Row: Inline label & value with responsive touch track
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
            local minVal = sliderConfig.Min or 0
            local maxVal = sliderConfig.Max or 100
            local defaultVal = math.clamp(sliderConfig.Default or minVal, minVal, maxVal)
            local decimals = sliderConfig.Decimals or 0
            local suffix = sliderConfig.Suffix or ""
            local callback = sliderConfig.Callback or function() end

            local currentVal = defaultVal

            local sliderFrame = Instance.new("Frame")
            sliderFrame.Name = "SliderItem_" .. sliderName
            sliderFrame.Size = UDim2.new(1, 0, 0, if isMobile then 50 else 44)
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

            -- Label & Value
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(0.6, 0, 0, 18)
            label.Position = UDim2.new(0, 12, 0, 6)
            label.BackgroundTransparency = 1
            label.Font = FontMedium
            label.Text = sliderName
            label.TextColor3 = GousseUI.Theme.TextPrimary
            label.TextSize = 12.5
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = sliderFrame

            local valueLabel = Instance.new("TextLabel")
            valueLabel.Size = UDim2.new(0.4, -20, 0, 18)
            valueLabel.Position = UDim2.new(0.6, 8, 0, 6)
            valueLabel.BackgroundTransparency = 1
            valueLabel.Font = FontCode
            valueLabel.Text = tostring(currentVal) .. suffix
            valueLabel.TextColor3 = GousseUI.Theme.Accent
            valueLabel.TextSize = 12
            valueLabel.TextXAlignment = Enum.TextXAlignment.Right
            valueLabel.Parent = sliderFrame

            -- Slider Track (6px height for touch accuracy)
            local track = Instance.new("TextButton")
            track.Name = "Track"
            track.Size = UDim2.new(1, -24, 0, 6)
            track.Position = UDim2.new(0, 12, 0, if isMobile then 32 else 28)
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
        -- 5. Dropdown Row: Compact right-aligned selector with touch padding
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
            local options = dropConfig.Options or {}
            local selected = dropConfig.Default or options[1] or ""
            local callback = dropConfig.Callback or function() end

            local isOpen = false
            local baseHeight = if isMobile then 42 else 36

            local dropFrame = Instance.new("Frame")
            dropFrame.Name = "DropItem_" .. dropName
            dropFrame.Size = UDim2.new(1, 0, 0, baseHeight)
            dropFrame.BackgroundColor3 = GousseUI.Theme.Surface
            dropFrame.BorderSizePixel = 0
            dropFrame.ClipsDescendants = true
            dropFrame.Parent = tabPage

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 8)
            corner.Parent = dropFrame

            local stroke = Instance.new("UIStroke")
            stroke.Color = GousseUI.Theme.Border
            stroke.Thickness = 1
            stroke.Parent = dropFrame

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(0.48, 0, 0, baseHeight)
            label.Position = UDim2.new(0, 12, 0, 0)
            label.BackgroundTransparency = 1
            label.Font = FontMedium
            label.Text = dropName
            label.TextColor3 = GousseUI.Theme.TextPrimary
            label.TextSize = 12.5
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = dropFrame

            local triggerBtn = Instance.new("TextButton")
            local trigHeight = if isMobile then 28 else 24
            triggerBtn.Size = UDim2.new(0.5, -20, 0, trigHeight)
            triggerBtn.Position = UDim2.new(0.5, 10, 0, (baseHeight - trigHeight) / 2)
            triggerBtn.BackgroundColor3 = GousseUI.Theme.Sidebar
            triggerBtn.Font = FontMedium
            triggerBtn.Text = selected .. " ▾"
            triggerBtn.TextColor3 = GousseUI.Theme.TextPrimary
            triggerBtn.TextSize = 11.5
            triggerBtn.AutoButtonColor = false
            triggerBtn.Parent = dropFrame

            local trigCorner = Instance.new("UICorner")
            trigCorner.CornerRadius = UDim.new(0, 6)
            trigCorner.Parent = triggerBtn

            local trigStroke = Instance.new("UIStroke")
            trigStroke.Color = GousseUI.Theme.Border
            trigStroke.Thickness = 1
            trigStroke.Parent = triggerBtn

            local itemHeight = if isMobile then 28 else 24
            local listFrame = Instance.new("Frame")
            listFrame.Name = "OptionsList"
            listFrame.Size = UDim2.new(1, -24, 0, #options * itemHeight)
            listFrame.Position = UDim2.new(0, 12, 0, baseHeight + 4)
            listFrame.BackgroundTransparency = 1
            listFrame.Parent = dropFrame

            local listLayout = Instance.new("UIListLayout")
            listLayout.SortOrder = Enum.SortOrder.LayoutOrder
            listLayout.Padding = UDim.new(0, 3)
            listLayout.Parent = listFrame

            local function ToggleDropdown()
                isOpen = not isOpen
                local targetHeight = isOpen and (baseHeight + 8 + #options * (itemHeight + 3)) or baseHeight
                triggerBtn.Text = selected .. (isOpen and " ▴" or " ▾")
                Tween(dropFrame, { Size = UDim2.new(1, 0, 0, targetHeight) }, 0.14)
            end

            triggerBtn.MouseButton1Click:Connect(ToggleDropdown)

            local function PopulateOptions(newOptions: {string})
                for _, child in ipairs(listFrame:GetChildren()) do
                    if child:IsA("TextButton") then child:Destroy() end
                end
                for _, opt in ipairs(newOptions) do
                    local optBtn = Instance.new("TextButton")
                    optBtn.Size = UDim2.new(1, 0, 0, itemHeight)
                    optBtn.BackgroundColor3 = GousseUI.Theme.Sidebar
                    optBtn.Font = FontMedium
                    optBtn.Text = opt
                    optBtn.TextColor3 = (opt == selected) and GousseUI.Theme.Accent or GousseUI.Theme.TextSecondary
                    optBtn.TextSize = 11.5
                    optBtn.AutoButtonColor = false
                    optBtn.Parent = listFrame

                    local optCorner = Instance.new("UICorner")
                    optCorner.CornerRadius = UDim.new(0, 5)
                    optCorner.Parent = optBtn

                    optBtn.MouseButton1Click:Connect(function()
                        selected = opt
                        triggerBtn.Text = selected .. " ▾"
                        for _, c in ipairs(listFrame:GetChildren()) do
                            if c:IsA("TextButton") then
                                c.TextColor3 = (c.Text == selected) and GousseUI.Theme.Accent or GousseUI.Theme.TextSecondary
                            end
                        end
                        ToggleDropdown()
                        pcall(callback, selected)
                    end)
                end
            end

            PopulateOptions(options)

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
                    PopulateOptions(options)
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

            local rowHeight = if subTitle then (if isMobile then 48 else 42) else (if isMobile then 42 else 34)
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

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(0.48, 0, 0, if subTitle then 18 else rowHeight)
            label.Position = UDim2.new(0, 12, 0, if subTitle then 5 else 0)
            label.BackgroundTransparency = 1
            label.Font = FontMedium
            label.Text = inputName
            label.TextColor3 = GousseUI.Theme.TextPrimary
            label.TextSize = 12.5
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = inputFrame

            if subTitle then
                local descLabel = Instance.new("TextLabel")
                descLabel.Size = UDim2.new(0.48, 0, 0, 16)
                descLabel.Position = UDim2.new(0, 12, 0, 24)
                descLabel.BackgroundTransparency = 1
                descLabel.Font = FontRegular
                descLabel.Text = subTitle
                descLabel.TextColor3 = GousseUI.Theme.TextSecondary
                descLabel.TextSize = 11
                descLabel.TextXAlignment = Enum.TextXAlignment.Left
                descLabel.Parent = inputFrame
            end

            local boxHeight = if isMobile then 28 else 24
            local textBox = Instance.new("TextBox")
            textBox.Size = UDim2.new(0.5, -20, 0, boxHeight)
            textBox.Position = UDim2.new(0.5, 10, 0.5, -boxHeight / 2)
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
            card.Size = UDim2.new(1, 0, 0, 56)
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
            title.Size = UDim2.new(1, -24, 0, 18)
            title.Position = UDim2.new(0, 12, 0, 8)
            title.BackgroundTransparency = 1
            title.Font = FontBold
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

    GousseUI:Notify({ Title = windowTitle, Content = "Loaded. Toggle hotkey: " .. toggleKey.Name, Duration = 3 })
    return WindowObj
end

return GousseUI
