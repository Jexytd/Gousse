-- Burger Planet: Fast Food Simulator — lobby restaurant manager (card layout)
-- Cards show owned saves with Load / Delete. The grid container has an Add tile
-- sized exactly like a restaurant card.

local env = (getgenv and getgenv()) or _G or {}
local GousseUI = env.GousseUI

local function looksLikeLibrary(src)
    return type(src) == "string" and #src > 5000 and src:find("GousseUI", 1, true) ~= nil
end

if not GousseUI then
    local okLocal, localRes = pcall(function()
        return game:HttpGet("http://localhost:3456/library.luau")
    end)
    if okLocal and looksLikeLibrary(localRes) then
        local okLoad, res = pcall(function() return loadstring(localRes)() end)
        if okLoad and res then GousseUI = res end
    end
end

if not GousseUI then
    local okRemote, remoteRes = pcall(function()
        return game:HttpGet("https://raw.githubusercontent.com/Jexytd/Gousse/main/library.luau")
    end)
    if okRemote and looksLikeLibrary(remoteRes) then
        local okLoad, res = pcall(function() return loadstring(remoteRes)() end)
        if okLoad and res then GousseUI = res end
    end
end

if not GousseUI then
    warn("[BP Restaurants] GousseUI failed to load")
    return
end

local previous = env.BPRestaurants
if type(previous) == "table" and type(previous.Shutdown) == "function" then
    pcall(previous.Shutdown)
end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local menu = ReplicatedStorage:FindFirstChild("Menu")
local MenuFn = menu and menu:FindFirstChild("MenuFn")
if not MenuFn then
    GousseUI:NotifyError("Menu remote is unavailable. Join the Burger Planet lobby first.", "Burger Planet", 5)
    return
end

local FontBold = Enum.Font.BuilderSansBold or Enum.Font.GothamBold
local FontMedium = Enum.Font.BuilderSansMedium or Enum.Font.GothamMedium
local FontRegular = Enum.Font.BuilderSans or Enum.Font.Gotham

local MODES = { "Career", "Sandbox", "Food Truck" }
local VISIBILITY = { "Solo", "Friends", "Anyone" }

local CARD_W = 210
local CARD_H = 138

local state = {
    mode = "Career",
    name = "",
    visibility = "Solo",
    data = nil,
    busy = false,
    unloaded = false
}

local function New(class, props, parent)
    local inst = Instance.new(class)
    for key, value in pairs(props) do
        inst[key] = value
    end
    if parent then inst.Parent = parent end
    return inst
end

local function Ask(...)
    local args = { ... }
    local ok, result = pcall(function()
        return MenuFn:InvokeServer(unpack(args))
    end)
    if not ok then
        return { Ok = false, Message = tostring(result) }
    end
    if type(result) ~= "table" then
        return { Ok = false, Message = "No response from the server." }
    end
    return result
end

local function Collect(data)
    local owned = {}
    local function add(list, kind)
        if type(list) ~= "table" then return end
        for _, entry in pairs(list) do
            if type(entry) == "table" and not entry.Empty and not entry.Locked and entry.Slot then
                local displayKind = kind
                if entry.Truck and entry.Sandbox then
                    displayKind = "Sandbox Truck"
                elseif entry.Truck then
                    displayKind = "Food Truck"
                end
                owned[#owned + 1] = {
                    Slot = tonumber(entry.Slot),
                    Name = entry.Name or ("Slot " .. tostring(entry.Slot)),
                    Kind = displayKind,
                    Level = entry.Level,
                    Day = entry.Day,
                    Money = entry.Money,
                    Unlimited = entry.Unlimited == true,
                    Played = entry.Played or 0
                }
            end
        end
    end
    add(data.Slots, "Career")
    add(data.Sandbox, "Sandbox")
    add(data.Truck, "Food Truck")
    table.sort(owned, function(a, b)
        return (b.Played or 0) > (a.Played or 0)
    end)
    return owned
end

local function FindEmpty(data, mode)
    local lists = {
        Career = data.Slots,
        Sandbox = data.Sandbox,
        ["Food Truck"] = data.Truck
    }
    local list = lists[mode]
    if type(list) ~= "table" then return nil end
    for _, entry in pairs(list) do
        if type(entry) == "table" and entry.Empty and not entry.Locked then
            return tonumber(entry.Slot)
        end
    end
    return nil
end

local function Fetch()
    if state.busy then return nil end
    state.busy = true
    local result = Ask("Slots")
    state.busy = false
    if not result.Ok then return nil end
    state.data = result
    return result
end

local function OpenSlot(entry)
    if state.busy then return end
    state.busy = true
    GousseUI:NotifyInfo("Loading " .. entry.Name .. "...", "Burger Planet", 3)
    local result = Ask("Open", entry.Slot, state.visibility)
    state.busy = false
    if result.Ok then
        GousseUI:NotifySuccess("Heading to " .. entry.Name .. ".", "Burger Planet", 3)
    else
        GousseUI:NotifyError(result.Message or "Could not load that restaurant.", "Load failed", 4)
    end
end

local function DeleteSlot(entry)
    if state.busy then return end
    state.busy = true
    local result = Ask("Delete", entry.Slot)
    state.busy = false
    if not result.Ok then
        GousseUI:NotifyError(result.Message or "Could not delete that restaurant.", "Delete failed", 4)
        return
    end
    GousseUI:NotifySuccess("Deleted '" .. entry.Name .. "'.", "Burger Planet", 3)
    Render()
end

local function CreateSlot(name)
    if state.busy or not state.data then return end
    name = (name or ""):match("^%s*(.-)%s*$") or ""
    if name == "" then
        GousseUI:NotifyWarning("Type a name for the new restaurant first.", "Burger Planet", 3)
        return
    end

    local slot = FindEmpty(state.data, state.mode)
    if not slot then
        GousseUI:NotifyWarning("No free " .. state.mode .. " slot. Delete one or unlock Extra Slots.", "Burger Planet", 4)
        return
    end

    state.busy = true
    local result = Ask("Create", slot, name)
    state.busy = false
    if not result.Ok then
        GousseUI:NotifyError(result.Message or "Could not create the restaurant.", "Create failed", 4)
        return
    end

    state.name = ""
    GousseUI:NotifySuccess("Created '" .. name .. "' in slot " .. slot .. ".", "Burger Planet", 3)
    Render()
end

local Window = GousseUI:CreateWindow({
    Title = "Burger Planet",
    SubTitle = "Restaurants",
    Keybind = Enum.KeyCode.RightControl,
    Size = UDim2.new(0, 620, 0, 450),
    AutoSettings = true
})

local tab = Window:CreateTab({ Name = "Restaurants", Icon = "layout-grid" })

local function TypeColor(kind)
    if kind == "Sandbox" or kind == "Sandbox Truck" then return GousseUI.Theme.Blue end
    if kind == "Food Truck" then return GousseUI.Theme.Warning end
    return GousseUI.Theme.Accent
end

local function TypeIcon(kind)
    if kind == "Sandbox" or kind == "Sandbox Truck" then return "flask-conical" end
    if kind == "Food Truck" then return "truck" end
    return "utensils"
end

local function Pill(parent, text, x, width, active, onClick)
    local btn = New("TextButton", {
        Name = "Pill_" .. text,
        Position = UDim2.new(0, x, 0, 0),
        Size = UDim2.new(0, width, 0, 24),
        BackgroundColor3 = active and GousseUI.Theme.Accent or GousseUI.Theme.Sidebar,
        BorderSizePixel = 0,
        Font = FontMedium,
        Text = text,
        TextColor3 = active and GousseUI.Theme.Background or GousseUI.Theme.TextSecondary,
        TextSize = 11,
        AutoButtonColor = false
    }, parent)
    New("UICorner", { CornerRadius = UDim.new(0, 6) }, btn)
    New("UIStroke", {
        Color = active and GousseUI.Theme.Accent or GousseUI.Theme.Border,
        Thickness = 1
    }, btn)
    btn.MouseButton1Click:Connect(function()
        onClick()
        for _, sibling in ipairs(parent:GetChildren()) do
            if sibling:IsA("TextButton") and sibling.Name:find("^Pill_") then
                local isActive = sibling == btn
                sibling.BackgroundColor3 = isActive and GousseUI.Theme.Accent or GousseUI.Theme.Sidebar
                sibling.TextColor3 = isActive and GousseUI.Theme.Background or GousseUI.Theme.TextSecondary
            end
        end
    end)
    return btn
end

local function MakeCard(parent, entry, layoutOrder)
    local accent = TypeColor(entry.Kind)
    local card = New("Frame", {
        Name = "RCard_" .. tostring(entry.Slot),
        LayoutOrder = layoutOrder,
        Size = UDim2.new(0, CARD_W, 0, CARD_H),
        BackgroundColor3 = GousseUI.Theme.Surface,
        BorderSizePixel = 0,
        ClipsDescendants = true
    }, parent)
    GousseUI:RegisterThemeElement(card, "BackgroundColor3", "Surface")
    New("UICorner", { CornerRadius = UDim.new(0, 10) }, card)
    local stroke = New("UIStroke", { Color = GousseUI.Theme.Border, Thickness = 1 }, card)
    GousseUI:RegisterThemeElement(stroke, "Color", "Border")

    local bar = New("Frame", {
        Name = "Accent",
        Size = UDim2.new(1, 0, 0, 3),
        BackgroundColor3 = accent,
        BorderSizePixel = 0
    }, card)

    local iconAsset = GousseUI:GetIcon(TypeIcon(entry.Kind))
    if iconAsset and iconAsset ~= "" then
        local icon = New("ImageLabel", {
            Name = "Icon",
            Position = UDim2.new(0, 10, 0, 11),
            Size = UDim2.new(0, 20, 0, 20),
            BackgroundTransparency = 1,
            Image = iconAsset,
            ImageColor3 = accent
        }, card)
        icon.ImageColor3 = accent
    end

    local title = New("TextLabel", {
        Name = "Name",
        Position = UDim2.new(0, 36, 0, 9),
        Size = UDim2.new(1, -46, 0, 22),
        BackgroundTransparency = 1,
        Font = FontBold,
        Text = entry.Name,
        TextColor3 = GousseUI.Theme.TextPrimary,
        TextSize = 14,
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextXAlignment = Enum.TextXAlignment.Left
    }, card)
    GousseUI:RegisterThemeElement(title, "TextColor3", "TextPrimary")

    local kind = New("TextLabel", {
        Name = "Kind",
        Position = UDim2.new(0, 10, 0, 38),
        Size = UDim2.new(1, -20, 0, 18),
        BackgroundTransparency = 1,
        Font = FontMedium,
        Text = entry.Kind .. "  ·  Level " .. tostring(entry.Level or 0),
        TextColor3 = accent,
        TextSize = 11.5,
        TextXAlignment = Enum.TextXAlignment.Left
    }, card)

    local cash = entry.Unlimited and "∞ cash" or (entry.Money and ("$" .. tostring(entry.Money)) or "—")
    local stats = New("TextLabel", {
        Name = "Stats",
        Position = UDim2.new(0, 10, 0, 58),
        Size = UDim2.new(1, -20, 0, 18),
        BackgroundTransparency = 1,
        Font = FontRegular,
        Text = "Day " .. tostring(entry.Day or 0) .. "  ·  " .. cash,
        TextColor3 = GousseUI.Theme.TextSecondary,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left
    }, card)
    GousseUI:RegisterThemeElement(stats, "TextColor3", "TextSecondary")

    local loadBtn = New("TextButton", {
        Name = "Load",
        Position = UDim2.new(0, 10, 1, -38),
        Size = UDim2.new(0, 88, 0, 28),
        BackgroundColor3 = GousseUI.Theme.Accent,
        BorderSizePixel = 0,
        Font = FontMedium,
        Text = "Load",
        TextColor3 = GousseUI.Theme.Background,
        TextSize = 11.5,
        AutoButtonColor = false
    }, card)
    New("UICorner", { CornerRadius = UDim.new(0, 6) }, loadBtn)
    loadBtn.MouseButton1Click:Connect(function()
        task.spawn(function() OpenSlot(entry) end)
    end)

    local confirming = false
    local deleteBtn = New("TextButton", {
        Name = "Delete",
        Position = UDim2.new(0, 106, 1, -38),
        Size = UDim2.new(0, 88, 0, 28),
        BackgroundColor3 = Color3.fromRGB(70, 26, 36),
        BorderSizePixel = 0,
        Font = FontMedium,
        Text = "Delete",
        TextColor3 = Color3.fromRGB(255, 150, 150),
        TextSize = 11.5,
        AutoButtonColor = false
    }, card)
    New("UICorner", { CornerRadius = UDim.new(0, 6) }, deleteBtn)
    New("UIStroke", { Color = Color3.fromRGB(225, 29, 72), Thickness = 1 }, deleteBtn)
    deleteBtn.MouseButton1Click:Connect(function()
        if confirming then
            task.spawn(function() DeleteSlot(entry) end)
            return
        end
        confirming = true
        deleteBtn.Text = "Confirm?"
        deleteBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        deleteBtn.BackgroundColor3 = Color3.fromRGB(225, 29, 72)
        task.delay(3, function()
            if not confirming then return end
            confirming = false
            if deleteBtn.Parent then
                deleteBtn.Text = "Delete"
                deleteBtn.TextColor3 = Color3.fromRGB(255, 150, 150)
                deleteBtn.BackgroundColor3 = Color3.fromRGB(70, 26, 36)
            end
        end)
    end)

    return card
end

local function MakeAddTile(parent, layoutOrder, onClick)
    local tile = New("TextButton", {
        Name = "RAdd",
        LayoutOrder = layoutOrder,
        Size = UDim2.new(0, CARD_W, 0, CARD_H),
        BackgroundColor3 = GousseUI.Theme.Surface,
        BackgroundTransparency = 0.35,
        BorderSizePixel = 0,
        Font = FontBold,
        Text = "",
        AutoButtonColor = false
    }, parent)
    GousseUI:RegisterThemeElement(tile, "BackgroundColor3", "Surface")
    New("UICorner", { CornerRadius = UDim.new(0, 10) }, tile)
    local stroke = New("UIStroke", {
        Color = GousseUI.Theme.Accent,
        Thickness = 1.2,
        Transparency = 0.25
    }, tile)
    GousseUI:RegisterThemeElement(stroke, "Color", "Accent")

    New("TextLabel", {
        Name = "Plus",
        Position = UDim2.new(0.5, 0, 0.38, 0),
        Size = UDim2.new(1, 0, 0, 44),
        BackgroundTransparency = 1,
        Font = FontBold,
        Text = "+",
        TextColor3 = GousseUI.Theme.Accent,
        TextSize = 38
    }, tile)
    New("TextLabel", {
        Name = "Label",
        Position = UDim2.new(0, 0, 0.62, 0),
        Size = UDim2.new(1, 0, 0, 18),
        BackgroundTransparency = 1,
        Font = FontMedium,
        Text = "ADD RESTAURANT",
        TextColor3 = GousseUI.Theme.TextSecondary,
        TextSize = 11
    }, tile)

    tile.MouseEnter:Connect(function()
        tile.BackgroundTransparency = 0.1
    end)
    tile.MouseLeave:Connect(function()
        tile.BackgroundTransparency = 0.35
    end)
    tile.MouseButton1Click:Connect(onClick)
    return tile
end

local function MakeCreatePanel(parent)
    local panel = New("Frame", {
        Name = "CreatePanel",
        Size = UDim2.new(1, 0, 0, 138),
        BackgroundColor3 = GousseUI.Theme.Surface,
        BorderSizePixel = 0,
        Visible = false
    }, parent)
    GousseUI:RegisterThemeElement(panel, "BackgroundColor3", "Surface")
    New("UICorner", { CornerRadius = UDim.new(0, 10) }, panel)
    local stroke = New("UIStroke", { Color = GousseUI.Theme.Border, Thickness = 1 }, panel)
    GousseUI:RegisterThemeElement(stroke, "Color", "Border")

    local title = New("TextLabel", {
        Position = UDim2.new(0, 12, 0, 8),
        Size = UDim2.new(1, -24, 0, 20),
        BackgroundTransparency = 1,
        Font = FontBold,
        Text = "NEW RESTAURANT",
        TextColor3 = GousseUI.Theme.TextPrimary,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left
    }, panel)
    GousseUI:RegisterThemeElement(title, "TextColor3", "TextPrimary")

    local typeRow = New("Frame", {
        Position = UDim2.new(0, 12, 0, 34),
        Size = UDim2.new(1, -24, 0, 24),
        BackgroundTransparency = 1
    }, panel)

    local nameBox = New("TextBox", {
        Name = "NameBox",
        Position = UDim2.new(0, 12, 0, 66),
        Size = UDim2.new(1, -24, 0, 28),
        BackgroundColor3 = GousseUI.Theme.Sidebar,
        BorderSizePixel = 0,
        Font = FontRegular,
        PlaceholderText = "Restaurant name",
        PlaceholderColor3 = GousseUI.Theme.TextMuted,
        Text = state.name or "",
        TextColor3 = GousseUI.Theme.TextPrimary,
        TextSize = 12,
        ClearTextOnFocus = false
    }, panel)
    New("UICorner", { CornerRadius = UDim.new(0, 6) }, nameBox)
    GousseUI:RegisterThemeElement(nameBox, "TextColor3", "TextPrimary")

    local createBtn = New("TextButton", {
        Name = "ConfirmCreate",
        Position = UDim2.new(0, 12, 1, -36),
        Size = UDim2.new(0, 100, 0, 26),
        BackgroundColor3 = GousseUI.Theme.Accent,
        BorderSizePixel = 0,
        Font = FontMedium,
        Text = "Create",
        TextColor3 = GousseUI.Theme.Background,
        TextSize = 11.5,
        AutoButtonColor = false
    }, panel)
    New("UICorner", { CornerRadius = UDim.new(0, 6) }, createBtn)
    createBtn.MouseButton1Click:Connect(function()
        CreateSlot(nameBox.Text)
    end)

    local cancelBtn = New("TextButton", {
        Name = "Cancel",
        Position = UDim2.new(0, 120, 1, -36),
        Size = UDim2.new(0, 100, 0, 26),
        BackgroundColor3 = GousseUI.Theme.Sidebar,
        BorderSizePixel = 0,
        Font = FontMedium,
        Text = "Cancel",
        TextColor3 = GousseUI.Theme.TextSecondary,
        TextSize = 11.5,
        AutoButtonColor = false
    }, panel)
    New("UICorner", { CornerRadius = UDim.new(0, 6) }, cancelBtn)
    cancelBtn.MouseButton1Click:Connect(function()
        panel.Visible = false
        nameBox.Text = ""
        state.name = ""
    end)

    local typeButtons = {}
    for i, mode in ipairs(MODES) do
        typeButtons[i] = Pill(typeRow, mode, (i - 1) * 136, 128, mode == state.mode, function()
            state.mode = mode
        end)
    end

    return panel
end

function Render()
    if state.unloaded or not tab.Page then return end

    for _, child in ipairs(tab.Page:GetChildren()) do
        if not child:IsA("UIListLayout") then
            child:Destroy()
        end
    end

    local data = state.data or Fetch()
    if not data then
        local retry = New("TextButton", {
            Size = UDim2.new(1, -8, 0, 60),
            BackgroundColor3 = GousseUI.Theme.Surface,
            Font = FontMedium,
            Text = "Could not read saves. Tap to retry",
            TextColor3 = GousseUI.Theme.TextPrimary,
            TextSize = 12,
            AutoButtonColor = false
        }, tab.Page)
        retry.MouseButton1Click:Connect(function()
            task.spawn(function()
                if Fetch() then Render() end
            end)
        end)
        return
    end

    local owned = Collect(data)
    local extra = data.Extra or {}

    local header = New("TextLabel", {
        Name = "Summary",
        Size = UDim2.new(1, -8, 0, 34),
        BackgroundTransparency = 1,
        Font = FontMedium,
        Text = "Owned " .. #owned .. "   ·   Career " .. #Collect({ Slots = data.Slots })
            .. "   ·   Sandbox " .. #Collect({ Sandbox = data.Sandbox })
            .. "   ·   Trucks " .. #Collect({ Truck = data.Truck })
            .. "   ·   Extra Slots " .. (extra.Owned and "owned" or "locked"),
        TextColor3 = GousseUI.Theme.TextSecondary,
        TextSize = 11.5,
        TextXAlignment = Enum.TextXAlignment.Left
    }, tab.Page)
    GousseUI:RegisterThemeElement(header, "TextColor3", "TextSecondary")

    local visRow = New("Frame", {
        Name = "VisibilityRow",
        Size = UDim2.new(1, -8, 0, 24),
        BackgroundTransparency = 1
    }, tab.Page)
    for i, option in ipairs(VISIBILITY) do
        Pill(visRow, option, (i - 1) * 96, 88, option == state.visibility, function()
            state.visibility = option
        end)
    end

    local refreshIcon = GousseUI:GetIcon("refresh-cw") or GousseUI:GetIcon("rotate-cw")
    local refreshBtn = New("ImageButton", {
        Name = "Refresh",
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, 0, 0, 0),
        Size = UDim2.new(0, 24, 0, 24),
        BackgroundColor3 = GousseUI.Theme.Surface,
        BorderSizePixel = 0,
        Image = refreshIcon or "",
        ImageColor3 = GousseUI.Theme.TextSecondary,
        AutoButtonColor = false
    }, visRow)
    New("UICorner", { CornerRadius = UDim.new(0, 6) }, refreshBtn)
    GousseUI:RegisterThemeElement(refreshBtn, "BackgroundColor3", "Surface")
    GousseUI:RegisterThemeElement(refreshBtn, "ImageColor3", "TextSecondary")
    refreshBtn.MouseButton1Click:Connect(function()
        task.spawn(function()
            if Fetch() then Render() end
        end)
    end)

    local grid = New("Frame", {
        Name = "CardGrid",
        Size = UDim2.new(1, -8, 0, 1),
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y
    }, tab.Page)
    local gridLayout = New("UIGridLayout", {
        CellSize = UDim2.new(0, CARD_W, 0, CARD_H),
        CellPadding = UDim2.new(0, 10, 0, 10),
        FillDirection = Enum.FillDirection.Horizontal,
        FillDirectionMaxCells = 2,
        SortOrder = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Top
    }, grid)

    local createPanel = MakeCreatePanel(tab.Page)

    for i, entry in ipairs(owned) do
        MakeCard(grid, entry, i)
    end
    MakeAddTile(grid, #owned + 1, function()
        createPanel.Visible = not createPanel.Visible
        if createPanel.Visible then
            createPanel.NameBox:CaptureFocus()
        end
    end)

end

Window:OnUnload(function()
    state.unloaded = true
    env.BPRestaurants = nil
end)

env.BPRestaurants = {
    Window = Window,
    Shutdown = function()
        state.unloaded = true
        pcall(function() Window:Unload() end)
        env.BPRestaurants = nil
    end
}

Render()
GousseUI:NotifySuccess("Restaurant manager ready.", "Burger Planet", 3)
