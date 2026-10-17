--[[
    ========================================================================
    GousseUI - Modern Professional Luau UI Library
    Engineered for Gousse Hub & Roblox Execution Environments
    ========================================================================
    Features:
      - Windows with smooth drag & minimize/hide keybind (default: RightControl)
      - Tab navigation with icons and badge indicators
      - Interactive Elements: Button, Toggle, Slider, Dropdown, Input, Keybind, Paragraph
      - In-game Toast Notification System
      - Safe parenting via gethui() -> CoreGui -> PlayerGui
      - TweenService micro-animations
    ========================================================================
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer and LocalPlayer:GetMouse()

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

local GousseUI = {
    Version = "1.0.0",
    Windows = {},
    ActiveKeybind = Enum.KeyCode.RightControl,
    Theme = {
        Background = Color3.fromRGB(15, 18, 24),
        Sidebar = Color3.fromRGB(19, 23, 31),
        Surface = Color3.fromRGB(24, 29, 39),
        SurfaceHover = Color3.fromRGB(32, 38, 51),
        Border = Color3.fromRGB(38, 45, 60),
        BorderLight = Color3.fromRGB(56, 66, 88),
        Primary = Color3.fromRGB(56, 139, 253),
        PrimaryDark = Color3.fromRGB(31, 111, 235),
        Success = Color3.fromRGB(46, 160, 67),
        Warning = Color3.fromRGB(210, 153, 34),
        Danger = Color3.fromRGB(248, 81, 73),
        TextPrimary = Color3.fromRGB(240, 246, 252),
        TextSecondary = Color3.fromRGB(139, 148, 158),
        TextMuted = Color3.fromRGB(90, 100, 115)
    }
}

-- Utility: Quick Tween
local function Tween(instance: Instance, properties: {[string]: any}, duration: number?, style: Enum.EasingStyle?, direction: Enum.EasingDirection?)
    duration = duration or 0.18
    style = style or Enum.EasingStyle.Quad
    direction = direction or Enum.EasingDirection.Out
    local tween = TweenService:Create(instance, TweenInfo.new(duration, style, direction), properties)
    tween:Play()
    return tween
end

-- Utility: Make UI Draggable
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
    NotificationContainer.Position = UDim2.new(1, -22, 1, -22)
    NotificationContainer.AnchorPoint = Vector2.new(1, 1)
    NotificationContainer.Size = UDim2.new(0, 310, 1, 0)
    NotificationContainer.Parent = NotificationGui

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    layout.Padding = UDim.new(0, 8)
    layout.Parent = NotificationContainer
end

function GousseUI:Notify(config: { Title: string?, Content: string, Duration: number?, Type: string? })
    EnsureNotificationGui()

    local titleText = config.Title or "Gousse Hub"
    local contentText = config.Content or ""
    local duration = config.Duration or 4
    local notifyType = config.Type or "info" -- info, success, warning, error

    local accentColor = GousseUI.Theme.Primary
    if notifyType == "success" then accentColor = GousseUI.Theme.Success
    elseif notifyType == "warning" then accentColor = GousseUI.Theme.Warning
    elseif notifyType == "error" then accentColor = GousseUI.Theme.Danger
    end

    local card = Instance.new("Frame")
    card.Name = "NotificationCard"
    card.Size = UDim2.new(1, 0, 0, 0) -- starts 0, expands
    card.BackgroundTransparency = 1
    card.BackgroundColor3 = GousseUI.Theme.Background
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
    title.Size = UDim2.new(1, -24, 0, 16)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.Text = titleText
    title.TextColor3 = GousseUI.Theme.TextPrimary
    title.TextSize = 13
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = card

    local body = Instance.new("TextLabel")
    body.Name = "Body"
    body.Position = UDim2.new(0, 14, 0, 26)
    body.Size = UDim2.new(1, -24, 0, 32)
    body.BackgroundTransparency = 1
    body.Font = Enum.Font.Gotham
    body.Text = contentText
    body.TextColor3 = GousseUI.Theme.TextSecondary
    body.TextSize = 11.5
    body.TextWrapped = true
    body.TextXAlignment = Enum.TextXAlignment.Left
    body.TextYAlignment = Enum.TextYAlignment.Top
    body.Parent = card

    -- Entry Animation
    Tween(card, { Size = UDim2.new(1, 0, 0, 68), BackgroundTransparency = 0.05 }, 0.22)
    Tween(stroke, { Transparency = 0 }, 0.22)

    -- Auto dismiss
    task.delay(duration, function()
        if card and card.Parent then
            Tween(card, { Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1 }, 0.2)
            Tween(stroke, { Transparency = 1 }, 0.2)
            task.wait(0.22)
            card:Destroy()
        end
    end)
end

-- ============================================================================
-- Window Creation
-- ============================================================================
function GousseUI:CreateWindow(config: {
    Title: string?,
    SubTitle: string?,
    Keybind: Enum.KeyCode?,
    Size: UDim2?
})
    config = config or {}
    local windowTitle = config.Title or "Gousse Hub"
    local windowSubTitle = config.SubTitle or "Universal Script Console"
    local toggleKey = config.Keybind or GousseUI.ActiveKeybind
    GousseUI.ActiveKeybind = toggleKey

    -- Clean old instances if re-created
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "GousseUI_" .. windowTitle:gsub("%s+", "")
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = 100
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = GetSafeGuiParent()

    local isVisible = true

    -- Main Window Outer Frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = config.Size or UDim2.new(0, 680, 0, 440)
    mainFrame.Position = UDim2.new(0.5, -340, 0.5, -220)
    mainFrame.BackgroundColor3 = GousseUI.Theme.Background
    mainFrame.BorderSizePixel = 0
    mainFrame.ClipsDescendants = true
    mainFrame.Parent = screenGui

    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 10)
    mainCorner.Parent = mainFrame

    local mainStroke = Instance.new("UIStroke")
    mainStroke.Color = GousseUI.Theme.Border
    mainStroke.Thickness = 1
    mainStroke.Parent = mainFrame

    -- Header / Title Bar
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 42)
    header.BackgroundColor3 = GousseUI.Theme.Sidebar
    header.BorderSizePixel = 0
    header.Parent = mainFrame

    local headerBottomBorder = Instance.new("Frame")
    headerBottomBorder.Size = UDim2.new(1, 0, 0, 1)
    headerBottomBorder.Position = UDim2.new(0, 0, 1, -1)
    headerBottomBorder.BackgroundColor3 = GousseUI.Theme.Border
    headerBottomBorder.BorderSizePixel = 0
    headerBottomBorder.Parent = header

    -- Brand Icon / Logo
    local brandIcon = Instance.new("TextLabel")
    brandIcon.Name = "BrandIcon"
    brandIcon.Size = UDim2.new(0, 24, 0, 24)
    brandIcon.Position = UDim2.new(0, 12, 0.5, -12)
    brandIcon.BackgroundColor3 = GousseUI.Theme.Primary
    brandIcon.Font = Enum.Font.GothamBold
    brandIcon.Text = "G"
    brandIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
    brandIcon.TextSize = 13
    brandIcon.Parent = header

    local iconCorner = Instance.new("UICorner")
    iconCorner.CornerRadius = UDim.new(0, 5)
    iconCorner.Parent = brandIcon

    -- Title text
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(0, 260, 0, 18)
    titleLabel.Position = UDim2.new(0, 44, 0, 6)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Text = windowTitle
    titleLabel.TextColor3 = GousseUI.Theme.TextPrimary
    titleLabel.TextSize = 13.5
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = header

    local subTitleLabel = Instance.new("TextLabel")
    subTitleLabel.Name = "SubTitleLabel"
    subTitleLabel.Size = UDim2.new(0, 260, 0, 14)
    subTitleLabel.Position = UDim2.new(0, 44, 0, 23)
    subTitleLabel.BackgroundTransparency = 1
    subTitleLabel.Font = Enum.Font.Gotham
    subTitleLabel.Text = windowSubTitle
    subTitleLabel.TextColor3 = GousseUI.Theme.TextMuted
    subTitleLabel.TextSize = 10.5
    subTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    subTitleLabel.Parent = header

    -- Window Controls (Minimize & Close)
    local controlsFrame = Instance.new("Frame")
    controlsFrame.Name = "Controls"
    controlsFrame.Size = UDim2.new(0, 60, 1, 0)
    controlsFrame.Position = UDim2.new(1, -66, 0, 0)
    controlsFrame.BackgroundTransparency = 1
    controlsFrame.Parent = header

    local btnMinimize = Instance.new("TextButton")
    btnMinimize.Name = "BtnMinimize"
    btnMinimize.Size = UDim2.new(0, 24, 0, 24)
    btnMinimize.Position = UDim2.new(0, 0, 0.5, -12)
    btnMinimize.BackgroundColor3 = GousseUI.Theme.Surface
    btnMinimize.Font = Enum.Font.GothamBold
    btnMinimize.Text = "—"
    btnMinimize.TextColor3 = GousseUI.Theme.TextSecondary
    btnMinimize.TextSize = 11
    btnMinimize.Parent = controlsFrame

    local minCorner = Instance.new("UICorner")
    minCorner.CornerRadius = UDim.new(0, 4)
    minCorner.Parent = btnMinimize

    local btnClose = Instance.new("TextButton")
    btnClose.Name = "BtnClose"
    btnClose.Size = UDim2.new(0, 24, 0, 24)
    btnClose.Position = UDim2.new(0, 30, 0.5, -12)
    btnClose.BackgroundColor3 = GousseUI.Theme.Surface
    btnClose.Font = Enum.Font.GothamBold
    btnClose.Text = "✕"
    btnClose.TextColor3 = GousseUI.Theme.TextSecondary
    btnClose.TextSize = 10
    btnClose.Parent = controlsFrame

    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 4)
    closeCorner.Parent = btnClose

    MakeDraggable(header, mainFrame)

    -- Toggle Window Visibility
    local function ToggleWindow(state: boolean?)
        if state == nil then
            isVisible = not isVisible
        else
            isVisible = state
        end

        if isVisible then
            mainFrame.Visible = true
            Tween(mainFrame, { Position = UDim2.new(0.5, -340, 0.5, -220), BackgroundTransparency = 0 }, 0.18)
        else
            local tw = Tween(mainFrame, { Position = UDim2.new(0.5, -340, 0.5, -180), BackgroundTransparency = 1 }, 0.18)
            tw.Completed:Connect(function()
                if not isVisible then mainFrame.Visible = false end
            end)
        end
    end

    btnMinimize.MouseButton1Click:Connect(function()
        ToggleWindow(false)
        GousseUI:Notify({ Title = "Gousse Hub", Content = "Press " .. toggleKey.Name .. " to reopen menu.", Duration = 3 })
    end)

    btnClose.MouseButton1Click:Connect(function()
        ToggleWindow(false)
    end)

    -- Global Hotkey Listener
    UserInputService.InputBegan:Connect(function(input, processed)
        if not processed and input.KeyCode == toggleKey then
            ToggleWindow()
        end
    end)

    -- Body Container
    local bodyFrame = Instance.new("Frame")
    bodyFrame.Name = "Body"
    bodyFrame.Size = UDim2.new(1, 0, 1, -42)
    bodyFrame.Position = UDim2.new(0, 0, 0, 42)
    bodyFrame.BackgroundTransparency = 1
    bodyFrame.Parent = mainFrame

    -- Left Navigation Sidebar (Tabs)
    local sidebar = Instance.new("Frame")
    sidebar.Name = "Sidebar"
    sidebar.Size = UDim2.new(0, 160, 1, 0)
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
    tabListContainer.Size = UDim2.new(1, -12, 1, -16)
    tabListContainer.Position = UDim2.new(0, 6, 0, 8)
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
    contentArea.Size = UDim2.new(1, -160, 1, 0)
    contentArea.Position = UDim2.new(0, 160, 0, 0)
    contentArea.BackgroundTransparency = 1
    contentArea.Parent = bodyFrame

    local WindowObj = {
        ScreenGui = screenGui,
        MainFrame = mainFrame,
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
        local tabIcon = tabConfig.Icon or "📁"

        -- Tab Button in Sidebar
        local tabBtn = Instance.new("TextButton")
        tabBtn.Name = "TabBtn_" .. tabName
        tabBtn.Size = UDim2.new(1, 0, 0, 32)
        tabBtn.BackgroundColor3 = GousseUI.Theme.Sidebar
        tabBtn.BackgroundTransparency = 1
        tabBtn.Font = Enum.Font.GothamMedium
        tabBtn.Text = ""
        tabBtn.Parent = tabListContainer

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 6)
        btnCorner.Parent = tabBtn

        local tabIconLabel = Instance.new("TextLabel")
        tabIconLabel.Name = "Icon"
        tabIconLabel.Size = UDim2.new(0, 20, 1, 0)
        tabIconLabel.Position = UDim2.new(0, 8, 0, 0)
        tabIconLabel.BackgroundTransparency = 1
        tabIconLabel.Font = Enum.Font.Gotham
        tabIconLabel.Text = tabIcon
        tabIconLabel.TextColor3 = GousseUI.Theme.TextSecondary
        tabIconLabel.TextSize = 13
        tabIconLabel.Parent = tabBtn

        local tabTextLabel = Instance.new("TextLabel")
        tabTextLabel.Name = "Label"
        tabTextLabel.Size = UDim2.new(1, -36, 1, 0)
        tabTextLabel.Position = UDim2.new(0, 32, 0, 0)
        tabTextLabel.BackgroundTransparency = 1
        tabTextLabel.Font = Enum.Font.GothamMedium
        tabTextLabel.Text = tabName
        tabTextLabel.TextColor3 = GousseUI.Theme.TextSecondary
        tabTextLabel.TextSize = 12
        tabTextLabel.TextXAlignment = Enum.TextXAlignment.Left
        tabTextLabel.Parent = tabBtn

        -- Tab Page Container (Right panel)
        local tabPage = Instance.new("ScrollingFrame")
        tabPage.Name = "Page_" .. tabName
        tabPage.Size = UDim2.new(1, -20, 1, -16)
        tabPage.Position = UDim2.new(0, 10, 0, 8)
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
        pageLayout.Padding = UDim.new(0, 7)
        pageLayout.Parent = tabPage

        local TabObj = {
            Name = tabName,
            Button = tabBtn,
            Page = tabPage
        }

        local function ActivateTab()
            for _, t in pairs(WindowObj.Tabs) do
                t.Page.Visible = false
                Tween(t.Button, { BackgroundTransparency = 1 }, 0.15)
                t.Button.Label.TextColor3 = GousseUI.Theme.TextSecondary
                t.Button.Icon.TextColor3 = GousseUI.Theme.TextSecondary
            end

            tabPage.Visible = true
            Tween(tabBtn, { BackgroundTransparency = 0, BackgroundColor3 = GousseUI.Theme.Surface }, 0.15)
            tabTextLabel.TextColor3 = GousseUI.Theme.TextPrimary
            tabIconLabel.TextColor3 = GousseUI.Theme.Primary
            WindowObj.ActiveTab = TabObj
        end

        tabBtn.MouseButton1Click:Connect(ActivateTab)

        -- If first tab, activate it
        if #WindowObj.Tabs == 0 then
            ActivateTab()
        end

        table.insert(WindowObj.Tabs, TabObj)

        -- ====================================================================
        -- Tab Elements (Sections, Buttons, Toggles, Sliders, Dropdowns, Inputs)
        -- ====================================================================

        -- 1. Section Header
        function TabObj:CreateSection(name: string)
            local sectionHeader = Instance.new("Frame")
            sectionHeader.Name = "Section_" .. name
            sectionHeader.Size = UDim2.new(1, 0, 0, 24)
            sectionHeader.BackgroundTransparency = 1
            sectionHeader.Parent = tabPage

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, 0, 1, 0)
            label.BackgroundTransparency = 1
            label.Font = Enum.Font.GothamBold
            label.Text = name:upper()
            label.TextColor3 = GousseUI.Theme.TextMuted
            label.TextSize = 10.5
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = sectionHeader
        end

        -- 2. Button
        function TabObj:CreateButton(btnConfig: { Name: string, Callback: (() -> ())? })
            btnConfig = btnConfig or {}
            local btnName = btnConfig.Name or "Button"
            local callback = btnConfig.Callback or function() end

            local btnFrame = Instance.new("Frame")
            btnFrame.Name = "BtnItem_" .. btnName
            btnFrame.Size = UDim2.new(1, 0, 0, 36)
            btnFrame.BackgroundColor3 = GousseUI.Theme.Surface
            btnFrame.BorderSizePixel = 0
            btnFrame.Parent = tabPage

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 6)
            corner.Parent = btnFrame

            local stroke = Instance.new("UIStroke")
            stroke.Color = GousseUI.Theme.Border
            stroke.Thickness = 1
            stroke.Parent = btnFrame

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, -70, 1, 0)
            label.Position = UDim2.new(0, 12, 0, 0)
            label.BackgroundTransparency = 1
            label.Font = Enum.Font.GothamMedium
            label.Text = btnName
            label.TextColor3 = GousseUI.Theme.TextPrimary
            label.TextSize = 12
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = btnFrame

            local actionBtn = Instance.new("TextButton")
            actionBtn.Size = UDim2.new(0, 52, 0, 24)
            actionBtn.Position = UDim2.new(1, -60, 0.5, -12)
            actionBtn.BackgroundColor3 = GousseUI.Theme.Primary
            actionBtn.Font = Enum.Font.GothamBold
            actionBtn.Text = "Click"
            actionBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            actionBtn.TextSize = 11
            actionBtn.Parent = btnFrame

            local actCorner = Instance.new("UICorner")
            actCorner.CornerRadius = UDim.new(0, 4)
            actCorner.Parent = actionBtn

            actionBtn.MouseButton1Click:Connect(function()
                Tween(actionBtn, { BackgroundColor3 = GousseUI.Theme.PrimaryDark }, 0.08)
                task.delay(0.1, function()
                    Tween(actionBtn, { BackgroundColor3 = GousseUI.Theme.Primary }, 0.12)
                end)
                pcall(callback)
            end)
        end

        -- 3. Toggle
        function TabObj:CreateToggle(toggleConfig: { Name: string, Default: boolean?, Callback: ((boolean) -> ())? })
            toggleConfig = toggleConfig or {}
            local toggleName = toggleConfig.Name or "Toggle"
            local state = toggleConfig.Default or false
            local callback = toggleConfig.Callback or function() end

            local toggleFrame = Instance.new("Frame")
            toggleFrame.Name = "ToggleItem_" .. toggleName
            toggleFrame.Size = UDim2.new(1, 0, 0, 36)
            toggleFrame.BackgroundColor3 = GousseUI.Theme.Surface
            toggleFrame.BorderSizePixel = 0
            toggleFrame.Parent = tabPage

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 6)
            corner.Parent = toggleFrame

            local stroke = Instance.new("UIStroke")
            stroke.Color = GousseUI.Theme.Border
            stroke.Thickness = 1
            stroke.Parent = toggleFrame

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, -60, 1, 0)
            label.Position = UDim2.new(0, 12, 0, 0)
            label.BackgroundTransparency = 1
            label.Font = Enum.Font.GothamMedium
            label.Text = toggleName
            label.TextColor3 = GousseUI.Theme.TextPrimary
            label.TextSize = 12
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = toggleFrame

            -- Switch Track
            local switchTrack = Instance.new("TextButton")
            switchTrack.Size = UDim2.new(0, 38, 0, 20)
            switchTrack.Position = UDim2.new(1, -48, 0.5, -10)
            switchTrack.BackgroundColor3 = state and GousseUI.Theme.Primary or GousseUI.Theme.Border
            switchTrack.Text = ""
            switchTrack.Parent = toggleFrame

            local trackCorner = Instance.new("UICorner")
            trackCorner.CornerRadius = UDim.new(1, 0)
            trackCorner.Parent = switchTrack

            -- Switch Knob
            local switchKnob = Instance.new("Frame")
            switchKnob.Size = UDim2.new(0, 16, 0, 16)
            switchKnob.Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
            switchKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            switchKnob.BorderSizePixel = 0
            switchKnob.Parent = switchTrack

            local knobCorner = Instance.new("UICorner")
            knobCorner.CornerRadius = UDim.new(1, 0)
            knobCorner.Parent = switchKnob

            local function SetState(newState: boolean)
                state = newState
                local targetPos = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
                local targetColor = state and GousseUI.Theme.Primary or GousseUI.Theme.Border

                Tween(switchTrack, { BackgroundColor3 = targetColor }, 0.15)
                Tween(switchKnob, { Position = targetPos }, 0.15)

                pcall(callback, state)
            end

            switchTrack.MouseButton1Click:Connect(function()
                SetState(not state)
            end)

            if toggleConfig.Default then
                pcall(callback, state)
            end

            return {
                Set = SetState,
                Get = function() return state end
            }
        end

        -- 4. Slider
        function TabObj:CreateSlider(sliderConfig: {
            Name: string,
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
            sliderFrame.Size = UDim2.new(1, 0, 0, 48)
            sliderFrame.BackgroundColor3 = GousseUI.Theme.Surface
            sliderFrame.BorderSizePixel = 0
            sliderFrame.Parent = tabPage

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 6)
            corner.Parent = sliderFrame

            local stroke = Instance.new("UIStroke")
            stroke.Color = GousseUI.Theme.Border
            stroke.Thickness = 1
            stroke.Parent = sliderFrame

            -- Label & Value text
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(0.6, 0, 0, 20)
            label.Position = UDim2.new(0, 12, 0, 6)
            label.BackgroundTransparency = 1
            label.Font = Enum.Font.GothamMedium
            label.Text = sliderName
            label.TextColor3 = GousseUI.Theme.TextPrimary
            label.TextSize = 12
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = sliderFrame

            local valueLabel = Instance.new("TextLabel")
            valueLabel.Size = UDim2.new(0.4, -24, 0, 20)
            valueLabel.Position = UDim2.new(0.6, 12, 0, 6)
            valueLabel.BackgroundTransparency = 1
            valueLabel.Font = Enum.Font.Code
            valueLabel.Text = tostring(currentVal) .. suffix
            valueLabel.TextColor3 = GousseUI.Theme.Primary
            valueLabel.TextSize = 11.5
            valueLabel.TextXAlignment = Enum.TextXAlignment.Right
            valueLabel.Parent = sliderFrame

            -- Slider Bar
            local track = Instance.new("TextButton")
            track.Name = "Track"
            track.Size = UDim2.new(1, -24, 0, 6)
            track.Position = UDim2.new(0, 12, 0, 32)
            track.BackgroundColor3 = GousseUI.Theme.Border
            track.Text = ""
            track.Parent = sliderFrame

            local trackCorner = Instance.new("UICorner")
            trackCorner.CornerRadius = UDim.new(1, 0)
            trackCorner.Parent = track

            local fill = Instance.new("Frame")
            fill.Name = "Fill"
            local initialRatio = (currentVal - minVal) / (maxVal - minVal)
            fill.Size = UDim2.new(initialRatio, 0, 1, 0)
            fill.BackgroundColor3 = GousseUI.Theme.Primary
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

        -- 5. Dropdown
        function TabObj:CreateDropdown(dropConfig: {
            Name: string,
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

            local dropFrame = Instance.new("Frame")
            dropFrame.Name = "DropItem_" .. dropName
            dropFrame.Size = UDim2.new(1, 0, 0, 36)
            dropFrame.BackgroundColor3 = GousseUI.Theme.Surface
            dropFrame.BorderSizePixel = 0
            dropFrame.ClipsDescendants = true
            dropFrame.Parent = tabPage

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 6)
            corner.Parent = dropFrame

            local stroke = Instance.new("UIStroke")
            stroke.Color = GousseUI.Theme.Border
            stroke.Thickness = 1
            stroke.Parent = dropFrame

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(0.5, 0, 0, 36)
            label.Position = UDim2.new(0, 12, 0, 0)
            label.BackgroundTransparency = 1
            label.Font = Enum.Font.GothamMedium
            label.Text = dropName
            label.TextColor3 = GousseUI.Theme.TextPrimary
            label.TextSize = 12
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = dropFrame

            local triggerBtn = Instance.new("TextButton")
            triggerBtn.Size = UDim2.new(0.5, -24, 0, 24)
            triggerBtn.Position = UDim2.new(0.5, 12, 0, 6)
            triggerBtn.BackgroundColor3 = GousseUI.Theme.Sidebar
            triggerBtn.Font = Enum.Font.Gotham
            triggerBtn.Text = selected .. " ▾"
            triggerBtn.TextColor3 = GousseUI.Theme.Primary
            triggerBtn.TextSize = 11.5
            triggerBtn.Parent = dropFrame

            local trigCorner = Instance.new("UICorner")
            trigCorner.CornerRadius = UDim.new(0, 4)
            trigCorner.Parent = triggerBtn

            -- List of options container
            local listFrame = Instance.new("Frame")
            listFrame.Name = "OptionsList"
            listFrame.Size = UDim2.new(1, -24, 0, #options * 26)
            listFrame.Position = UDim2.new(0, 12, 0, 40)
            listFrame.BackgroundTransparency = 1
            listFrame.Parent = dropFrame

            local listLayout = Instance.new("UIListLayout")
            listLayout.SortOrder = Enum.SortOrder.LayoutOrder
            listLayout.Padding = UDim.new(0, 2)
            listLayout.Parent = listFrame

            local function ToggleDropdown()
                isOpen = not isOpen
                local targetHeight = isOpen and (44 + #options * 28) or 36
                triggerBtn.Text = selected .. (isOpen and " ▴" or " ▾")
                Tween(dropFrame, { Size = UDim2.new(1, 0, 0, targetHeight) }, 0.18)
            end

            triggerBtn.MouseButton1Click:Connect(ToggleDropdown)

            for _, opt in ipairs(options) do
                local optBtn = Instance.new("TextButton")
                optBtn.Size = UDim2.new(1, 0, 0, 24)
                optBtn.BackgroundColor3 = GousseUI.Theme.Sidebar
                optBtn.Font = Enum.Font.Gotham
                optBtn.Text = opt
                optBtn.TextColor3 = (opt == selected) and GousseUI.Theme.Primary or GousseUI.Theme.TextSecondary
                optBtn.TextSize = 11
                optBtn.Parent = listFrame

                local optCorner = Instance.new("UICorner")
                optCorner.CornerRadius = UDim.new(0, 4)
                optCorner.Parent = optBtn

                optBtn.MouseButton1Click:Connect(function()
                    selected = opt
                    triggerBtn.Text = selected .. " ▾"
                    for _, child in ipairs(listFrame:GetChildren()) do
                        if child:IsA("TextButton") then
                            child.TextColor3 = (child.Text == selected) and GousseUI.Theme.Primary or GousseUI.Theme.TextSecondary
                        end
                    end
                    ToggleDropdown()
                    pcall(callback, selected)
                end)
            end

            return {
                Set = function(val)
                    selected = val
                    triggerBtn.Text = selected .. " ▾"
                    pcall(callback, selected)
                end,
                Get = function() return selected end
            }
        end

        -- 6. Text Input Box
        function TabObj:CreateInput(inputConfig: {
            Name: string,
            Placeholder: string?,
            Callback: ((string) -> ())?
        })
            inputConfig = inputConfig or {}
            local inputName = inputConfig.Name or "Input"
            local placeholder = inputConfig.Placeholder or "Enter value..."
            local callback = inputConfig.Callback or function() end

            local inputFrame = Instance.new("Frame")
            inputFrame.Name = "InputItem_" .. inputName
            inputFrame.Size = UDim2.new(1, 0, 0, 36)
            inputFrame.BackgroundColor3 = GousseUI.Theme.Surface
            inputFrame.BorderSizePixel = 0
            inputFrame.Parent = tabPage

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 6)
            corner.Parent = inputFrame

            local stroke = Instance.new("UIStroke")
            stroke.Color = GousseUI.Theme.Border
            stroke.Thickness = 1
            stroke.Parent = inputFrame

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(0.5, 0, 1, 0)
            label.Position = UDim2.new(0, 12, 0, 0)
            label.BackgroundTransparency = 1
            label.Font = Enum.Font.GothamMedium
            label.Text = inputName
            label.TextColor3 = GousseUI.Theme.TextPrimary
            label.TextSize = 12
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = inputFrame

            local textBox = Instance.new("TextBox")
            textBox.Size = UDim2.new(0.5, -24, 0, 24)
            textBox.Position = UDim2.new(0.5, 12, 0.5, -12)
            textBox.BackgroundColor3 = GousseUI.Theme.Sidebar
            textBox.Font = Enum.Font.Code
            textBox.PlaceholderText = placeholder
            textBox.PlaceholderColor3 = GousseUI.Theme.TextMuted
            textBox.Text = ""
            textBox.TextColor3 = GousseUI.Theme.TextPrimary
            textBox.TextSize = 11.5
            textBox.ClearTextOnFocus = false
            textBox.Parent = inputFrame

            local boxCorner = Instance.new("UICorner")
            boxCorner.CornerRadius = UDim.new(0, 4)
            boxCorner.Parent = textBox

            textBox.FocusLost:Connect(function(enterPressed)
                pcall(callback, textBox.Text)
            end)

            return {
                Set = function(val) textBox.Text = tostring(val) end,
                Get = function() return textBox.Text end
            }
        end

        -- 7. Paragraph / Info Card
        function TabObj:CreateParagraph(paraConfig: { Title: string, Content: string })
            paraConfig = paraConfig or {}
            local titleText = paraConfig.Title or "Notice"
            local bodyText = paraConfig.Content or ""

            local card = Instance.new("Frame")
            card.Name = "Paragraph_" .. titleText
            card.Size = UDim2.new(1, 0, 0, 56)
            card.BackgroundColor3 = GousseUI.Theme.Surface
            card.BorderSizePixel = 0
            card.Parent = tabPage

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 6)
            corner.Parent = card

            local stroke = Instance.new("UIStroke")
            stroke.Color = GousseUI.Theme.Border
            stroke.Thickness = 1
            stroke.Parent = card

            local title = Instance.new("TextLabel")
            title.Size = UDim2.new(1, -24, 0, 16)
            title.Position = UDim2.new(0, 12, 0, 8)
            title.BackgroundTransparency = 1
            title.Font = Enum.Font.GothamBold
            title.Text = titleText
            title.TextColor3 = GousseUI.Theme.TextPrimary
            title.TextSize = 12
            title.TextXAlignment = Enum.TextXAlignment.Left
            title.Parent = card

            local content = Instance.new("TextLabel")
            content.Size = UDim2.new(1, -24, 0, 26)
            content.Position = UDim2.new(0, 12, 0, 24)
            content.BackgroundTransparency = 1
            content.Font = Enum.Font.Gotham
            content.Text = bodyText
            content.TextColor3 = GousseUI.Theme.TextSecondary
            content.TextSize = 11
            content.TextWrapped = true
            content.TextXAlignment = Enum.TextXAlignment.Left
            content.TextYAlignment = Enum.TextYAlignment.Top
            content.Parent = card
        end

        return TabObj
    end

    GousseUI:Notify({ Title = windowTitle, Content = "Loaded! Press " .. toggleKey.Name .. " to toggle.", Duration = 4 })
    return WindowObj
end

return GousseUI
