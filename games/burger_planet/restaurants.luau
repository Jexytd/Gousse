-- Burger Planet: Fast Food Simulator — lobby restaurant manager (card layout)
-- Cards show owned saves with Load / Delete. The grid container has an Add tile
-- sized exactly like a restaurant card. Create opens a full modal matching the
-- game's own "New restaurant" flow.

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
local Players = game:GetService("Players")
local menu = ReplicatedStorage:FindFirstChild("Menu")
local MenuFn = menu and menu:FindFirstChild("MenuFn")
if not MenuFn then
    GousseUI:NotifyError("Menu remote is unavailable. Join the Burger Planet lobby first.", "Burger Planet", 5)
    return
end

local FontBold = Enum.Font.BuilderSansBold or Enum.Font.GothamBold
local FontMedium = Enum.Font.BuilderSansMedium or Enum.Font.GothamMedium
local FontRegular = Enum.Font.BuilderSans or Enum.Font.Gotham

local MODES = { "Career", "Sandbox" }
local MAPS = { "Restaurant", "Food Truck" }
local VISIBILITY = { "Solo", "Friends", "Anyone" }

local CARD_W = 210
local CARD_H = 138

local PHOTO_RESTAURANT = "rbxassetid://93335508698582"
local PHOTO_TRUCK = "rbxassetid://120456991592636"

local state = {
    mode = "Career",
    map = "Restaurant",
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

local function GetSafeParent()
    local ok, hui = pcall(function()
        return (type(gethui) == "function") and gethui() or nil
    end)
    if ok and hui then return hui end
    local okCore, core = pcall(function() return game:GetService("CoreGui") end)
    if okCore and core then return core end
    return Players.LocalPlayer:WaitForChild("PlayerGui")
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

local function MapList(data, map, mode)
    if map == "Food Truck" then
        local list = {}
        for _, entry in pairs((data and data.Truck) or {}) do
            if type(entry) == "table" and (entry.Sandbox == true) == (mode == "Sandbox") then
                list[#list + 1] = entry
            end
        end
        return list
    end
    return (mode == "Sandbox" and data.Sandbox or data.Slots) or {}
end

local function SlotStats(data, map, mode)
    local list = MapList(data, map, mode)
    local free, unlocked = 0, 0
    for _, entry in pairs(list) do
        if type(entry) == "table" and not entry.Locked then
            unlocked += 1
            if entry.Empty then free += 1 end
        end
    end
    return free, unlocked
end

local function FindSlot(data, map, mode)
    for _, entry in pairs(MapList(data, map, mode)) do
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

    local slot = FindSlot(state.data, state.map, state.mode)
    if not slot then
        GousseUI:NotifyWarning("No free slot for that combination. Delete one or unlock Extra Slots.", "Burger Planet", 4)
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

-- Visibility pills use the same amber highlight as the create modal so the
-- two surfaces read as one palette instead of a green/amber clash.
local PILL_ACTIVE = GousseUI.Theme.Warning
local PILL_IDLE = Color3.fromRGB(17, 24, 39)
local PILL_TEXT_ACTIVE = Color3.fromRGB(11, 14, 20)
local PILL_TEXT_IDLE = Color3.fromRGB(107, 114, 128)
local PILL_STROKE_IDLE = Color3.fromRGB(31, 41, 55)

local function Pill(parent, text, x, width, active, onClick)
    local btn = New("TextButton", {
        Name = "Pill_" .. text,
        Position = UDim2.new(0, x, 0, 0),
        Size = UDim2.new(0, width, 0, 24),
        BackgroundColor3 = active and PILL_ACTIVE or PILL_IDLE,
        BorderSizePixel = 0,
        Font = FontMedium,
        Text = text,
        TextColor3 = active and PILL_TEXT_ACTIVE or PILL_TEXT_IDLE,
        TextSize = 11,
        AutoButtonColor = false
    }, parent)
    New("UICorner", { CornerRadius = UDim.new(0, 6) }, btn)
    local stroke = New("UIStroke", {
        Color = active and PILL_ACTIVE or PILL_STROKE_IDLE,
        Thickness = 1
    }, btn)
    btn.MouseButton1Click:Connect(function()
        onClick()
        for _, sibling in ipairs(parent:GetChildren()) do
            if sibling:IsA("TextButton") and sibling.Name:find("^Pill_") then
                local isActive = sibling == btn
                sibling.BackgroundColor3 = isActive and PILL_ACTIVE or PILL_IDLE
                sibling.TextColor3 = isActive and PILL_TEXT_ACTIVE or PILL_TEXT_IDLE
                local s = sibling:FindFirstChildOfClass("UIStroke")
                if s then s.Color = isActive and PILL_ACTIVE or PILL_STROKE_IDLE end
            end
        end
    end)
    return btn
end

local function Radio(parent, x, y, active)
    local outer = New("Frame", {
        Size = UDim2.new(0, 20, 0, 20),
        Position = UDim2.new(0, x, 0, y),
        BackgroundColor3 = active and GousseUI.Theme.Accent or GousseUI.Theme.Background,
        BorderSizePixel = 0,
        ZIndex = 10
    }, parent)
    New("UICorner", { CornerRadius = UDim.new(1, 0) }, outer)
    New("UIStroke", {
        Color = active and GousseUI.Theme.Accent or GousseUI.Theme.BorderLight,
        Thickness = 1.5,
        ZIndex = 10
    }, outer)
    local dot = New("Frame", {
        Name = "Dot",
        Size = UDim2.new(0, 8, 0, 8),
        Position = UDim2.new(0.5, -4, 0.5, -4),
        BackgroundColor3 = GousseUI.Theme.Background,
        BorderSizePixel = 0,
        Visible = active,
        ZIndex = 11
    }, outer)
    New("UICorner", { CornerRadius = UDim.new(1, 0) }, dot)
    return outer
end

local function SetRadio(radio, active)
    radio.BackgroundColor3 = active and GousseUI.Theme.Accent or GousseUI.Theme.Background
    local stroke = radio:FindFirstChildOfClass("UIStroke")
    if stroke then stroke.Color = active and GousseUI.Theme.Accent or GousseUI.Theme.BorderLight end
    local dot = radio:FindFirstChild("Dot")
    if dot then dot.Visible = active end
end

-- Full create modal, matching the game's New restaurant screen.
local function OpenCreateModal()
    for _, child in ipairs(GetSafeParent():GetChildren()) do
        if child:IsA("ScreenGui") and child.Name == "GousseBP_CreateModal" then
            child:Destroy()
        end
    end

    state.mode = "Career"
    state.map = "Restaurant"
    state.name = ""

    local screen = New("ScreenGui", {
        Name = "GousseBP_CreateModal",
        ResetOnSpawn = false,
        DisplayOrder = 5000,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    }, GetSafeParent())

    local dim = New("TextButton", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.6,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 1
    }, screen)

    local modal = New("Frame", {
        Name = "Modal",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 720, 0, 620),
        BackgroundColor3 = GousseUI.Theme.Background,
        BorderSizePixel = 0,
        ZIndex = 2,
        ClipsDescendants = true
    }, screen)
    New("UICorner", { CornerRadius = UDim.new(0, 12) }, modal)
    New("UIStroke", { Color = GousseUI.Theme.Border, Thickness = 1 }, modal)

    New("TextLabel", {
        Position = UDim2.new(0, 24, 0, 18),
        Size = UDim2.new(1, -48, 0, 34),
        BackgroundTransparency = 1,
        Font = FontBold,
        Text = "New restaurant",
        TextColor3 = GousseUI.Theme.TextPrimary,
        TextSize = 26,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 3
    }, modal)

    New("TextLabel", {
        Position = UDim2.new(0, 24, 0, 56),
        Size = UDim2.new(1, -48, 0, 32),
        BackgroundTransparency = 1,
        Font = FontRegular,
        Text = "Name it, then pick how you play and where. Other players see the name when they join.",
        TextColor3 = GousseUI.Theme.TextSecondary,
        TextSize = 12,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        ZIndex = 3
    }, modal)

    local inputWrap = New("Frame", {
        Position = UDim2.new(0, 24, 0, 96),
        Size = UDim2.new(1, -48, 0, 42),
        BackgroundColor3 = GousseUI.Theme.Surface,
        BorderSizePixel = 0,
        ZIndex = 3
    }, modal)
    New("UICorner", { CornerRadius = UDim.new(0, 8) }, inputWrap)
    New("UIStroke", { Color = GousseUI.Theme.Accent, Thickness = 1.3 }, inputWrap)

    local nameBox = New("TextBox", {
        Position = UDim2.new(0, 14, 0, 0),
        Size = UDim2.new(1, -80, 1, 0),
        BackgroundTransparency = 1,
        Font = FontRegular,
        PlaceholderText = "e.g. Burger Planet",
        PlaceholderColor3 = GousseUI.Theme.TextMuted,
        Text = "",
        TextColor3 = GousseUI.Theme.TextPrimary,
        TextSize = 14,
        ClearTextOnFocus = false,
        ZIndex = 4
    }, inputWrap)

    local counter = New("TextLabel", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -14, 0, 0),
        Size = UDim2.new(0, 56, 1, 0),
        BackgroundTransparency = 1,
        Font = FontRegular,
        Text = "0/24",
        TextColor3 = GousseUI.Theme.TextMuted,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Right,
        ZIndex = 4
    }, inputWrap)

    nameBox:GetPropertyChangedSignal("Text"):Connect(function()
        if #nameBox.Text > 24 then
            nameBox.Text = nameBox.Text:sub(1, 24)
        end
        counter.Text = #nameBox.Text .. "/24"
    end)

    New("TextLabel", {
        Position = UDim2.new(0, 24, 0, 154),
        Size = UDim2.new(1, -48, 0, 18),
        BackgroundTransparency = 1,
        Font = FontBold,
        Text = "HOW YOU PLAY",
        TextColor3 = GousseUI.Theme.TextMuted,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 3
    }, modal)

    local modeCards, modeRadios = {}, {}
    local modeInfo = {
        { Name = "Career", Desc = "Start small and grow: earn money, level up and unlock upgrades. Counts on the leaderboards.", Icon = "utensils" },
        { Name = "Sandbox", Desc = "Unlimited money and everything unlocked. Just for fun: it doesn't count towards Career.", Icon = "flask-conical" }
    }

    local function selectMode(index)
        state.mode = modeInfo[index].Name
        for i, card in ipairs(modeCards) do
            local active = i == index
            local stroke = card:FindFirstChildOfClass("UIStroke")
            if stroke then stroke.Color = active and GousseUI.Theme.Warning or GousseUI.Theme.Border end
            SetRadio(modeRadios[i], active)
        end
    end

    for i, info in ipairs(modeInfo) do
        local card = New("TextButton", {
            Position = UDim2.new(0, 24 + (i - 1) * 348, 0, 178),
            Size = UDim2.new(0, 336, 0, 78),
            BackgroundColor3 = GousseUI.Theme.Surface,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            ZIndex = 3
        }, modal)
        New("UICorner", { CornerRadius = UDim.new(0, 8) }, card)
        New("UIStroke", { Color = i == 1 and GousseUI.Theme.Warning or GousseUI.Theme.Border, Thickness = 1.3, ZIndex = 10 }, card)

        local icon = GousseUI:GetIcon(info.Icon)
        if icon and icon ~= "" then
            New("ImageLabel", {
                Position = UDim2.new(0, 14, 0, 12),
                Size = UDim2.new(0, 22, 0, 22),
                BackgroundTransparency = 1,
                Image = icon,
                ImageColor3 = GousseUI.Theme.TextPrimary,
                ZIndex = 4
            }, card)
        end
        New("TextLabel", {
            Position = UDim2.new(0, 44, 0, 10),
            Size = UDim2.new(1, -80, 0, 24),
            BackgroundTransparency = 1,
            Font = FontBold,
            Text = info.Name,
            TextColor3 = GousseUI.Theme.TextPrimary,
            TextSize = 15,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 4
        }, card)
        New("TextLabel", {
            Position = UDim2.new(0, 14, 0, 42),
            Size = UDim2.new(1, -28, 0, 30),
            BackgroundTransparency = 1,
            Font = FontRegular,
            Text = info.Desc,
            TextColor3 = GousseUI.Theme.TextSecondary,
            TextSize = 11,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            ZIndex = 4
        }, card)

        modeRadios[i] = Radio(card, 300, 12, i == 1)
        modeCards[i] = card
        card.MouseButton1Click:Connect(function() selectMode(i) end)
    end

    New("TextLabel", {
        Position = UDim2.new(0, 24, 0, 270),
        Size = UDim2.new(1, -48, 0, 18),
        BackgroundTransparency = 1,
        Font = FontBold,
        Text = "WHERE",
        TextColor3 = GousseUI.Theme.TextMuted,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 3
    }, modal)

    local mapCards, mapRadios = {}, {}
    local mapInfo = {
        { Name = "Restaurant", Desc = "In town: dine-in, drive-thru, staff and deliveries.", Photo = PHOTO_RESTAURANT, Icon = "utensils", Mode = "Career" },
        { Name = "Food Truck", Desc = "At the beach: a smaller kitchen, every order to go.", Photo = PHOTO_TRUCK, Icon = "truck", Mode = "Career", New = true }
    }

    local function refreshMapLines()
        for i, info in ipairs(mapInfo) do
            local line = mapCards[i]:FindFirstChild("SlotsLine")
            if line then
                local free, total = SlotStats(state.data, info.Name, state.mode)
                line.Text = tostring(free) .. " of " .. tostring(total) .. " " .. state.mode .. " " .. (info.Name == "Food Truck" and "truck" or "restaurant") .. " slots free"
            end
        end
    end

    local function selectMap(index)
        state.map = mapInfo[index].Name
        for i, card in ipairs(mapCards) do
            local active = i == index
            local stroke = card:FindFirstChildOfClass("UIStroke")
            if stroke then stroke.Color = active and GousseUI.Theme.Warning or GousseUI.Theme.Border end
            SetRadio(mapRadios[i], active)
        end
        refreshMapLines()
    end

    for i, info in ipairs(mapInfo) do
        local card = New("TextButton", {
            Position = UDim2.new(0, 24 + (i - 1) * 348, 0, 294),
            Size = UDim2.new(0, 336, 0, 222),
            BackgroundColor3 = GousseUI.Theme.Surface,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            ZIndex = 3,
            ClipsDescendants = true
        }, modal)
        New("UICorner", { CornerRadius = UDim.new(0, 8) }, card)
        New("UIStroke", { Color = i == 1 and GousseUI.Theme.Warning or GousseUI.Theme.Border, Thickness = 1.3, ZIndex = 10 }, card)

        New("ImageLabel", {
            Size = UDim2.new(1, 0, 0, 128),
            BackgroundColor3 = GousseUI.Theme.Sidebar,
            Image = info.Photo,
            ScaleType = Enum.ScaleType.Crop,
            ZIndex = 4
        }, card)

        if info.New then
            local badge = New("Frame", {
                Position = UDim2.new(0, 10, 0, 10),
                Size = UDim2.new(0, 46, 0, 20),
                BackgroundColor3 = GousseUI.Theme.Warning,
                BorderSizePixel = 0,
                ZIndex = 5
            }, card)
            New("UICorner", { CornerRadius = UDim.new(0, 4) }, badge)
            New("TextLabel", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Font = FontBold,
                Text = "NEW",
                TextColor3 = GousseUI.Theme.Background,
                TextSize = 10,
                ZIndex = 6
            }, badge)
        end

        local icon = GousseUI:GetIcon(info.Icon)
        if icon and icon ~= "" then
            New("ImageLabel", {
                Position = UDim2.new(0, 14, 0, 138),
                Size = UDim2.new(0, 18, 0, 18),
                BackgroundTransparency = 1,
                Image = icon,
                ImageColor3 = GousseUI.Theme.TextPrimary,
                ZIndex = 4
            }, card)
        end
        New("TextLabel", {
            Position = UDim2.new(0, 38, 0, 136),
            Size = UDim2.new(1, -80, 0, 22),
            BackgroundTransparency = 1,
            Font = FontBold,
            Text = info.Name,
            TextColor3 = GousseUI.Theme.TextPrimary,
            TextSize = 15,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 4
        }, card)
        New("TextLabel", {
            Position = UDim2.new(0, 14, 0, 162),
            Size = UDim2.new(1, -28, 0, 30),
            BackgroundTransparency = 1,
            Font = FontRegular,
            Text = info.Desc,
            TextColor3 = GousseUI.Theme.TextSecondary,
            TextSize = 11,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            ZIndex = 4
        }, card)

        local line = New("TextLabel", {
            Name = "SlotsLine",
            Position = UDim2.new(0, 14, 0, 192),
            Size = UDim2.new(1, -28, 0, 18),
            BackgroundTransparency = 1,
            Font = FontMedium,
            Text = "",
            TextColor3 = GousseUI.Theme.Warning,
            TextSize = 10.5,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 4
        }, card)

        mapRadios[i] = Radio(card, 300, 12, i == 1)
        mapCards[i] = card
        card.MouseButton1Click:Connect(function() selectMap(i) end)
    end
    refreshMapLines()

    local cancelBtn = New("TextButton", {
        Position = UDim2.new(1, -24 - 160 - 12 - 80, 1, -52),
        Size = UDim2.new(0, 80, 0, 34),
        BackgroundTransparency = 1,
        Font = FontMedium,
        Text = "Cancel",
        TextColor3 = GousseUI.Theme.TextSecondary,
        TextSize = 12,
        AutoButtonColor = false,
        ZIndex = 4
    }, modal)
    cancelBtn.MouseButton1Click:Connect(function()
        screen:Destroy()
    end)

    local createBtn = New("TextButton", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -24, 1, -52),
        Size = UDim2.new(0, 160, 0, 34),
        BackgroundColor3 = GousseUI.Theme.Warning,
        BorderSizePixel = 0,
        Font = FontBold,
        Text = "CREATE  →",
        TextColor3 = GousseUI.Theme.Background,
        TextSize = 12,
        AutoButtonColor = false,
        ZIndex = 4
    }, modal)
    New("UICorner", { CornerRadius = UDim.new(0, 8) }, createBtn)
    createBtn.MouseButton1Click:Connect(function()
        local name = nameBox.Text
        screen:Destroy()
        task.spawn(function() CreateSlot(name) end)
    end)

    dim.MouseButton1Click:Connect(function()
        screen:Destroy()
    end)

    task.defer(function()
        if nameBox.Parent then nameBox:CaptureFocus() end
    end)
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

    New("Frame", {
        Name = "Accent",
        Size = UDim2.new(1, 0, 0, 3),
        BackgroundColor3 = accent,
        BorderSizePixel = 0
    }, card)

    local iconAsset = GousseUI:GetIcon(TypeIcon(entry.Kind))
    if iconAsset and iconAsset ~= "" then
        New("ImageLabel", {
            Name = "Icon",
            Position = UDim2.new(0, 10, 0, 11),
            Size = UDim2.new(0, 20, 0, 20),
            BackgroundTransparency = 1,
            Image = iconAsset,
            ImageColor3 = accent
        }, card)
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

    New("TextLabel", {
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

    tile.MouseEnter:Connect(function() tile.BackgroundTransparency = 0.1 end)
    tile.MouseLeave:Connect(function() tile.BackgroundTransparency = 0.35 end)
    tile.MouseButton1Click:Connect(onClick)
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

    New("TextLabel", {
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
    New("UIGridLayout", {
        CellSize = UDim2.new(0, CARD_W, 0, CARD_H),
        CellPadding = UDim2.new(0, 10, 0, 10),
        FillDirection = Enum.FillDirection.Horizontal,
        FillDirectionMaxCells = 2,
        SortOrder = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Top
    }, grid)

    for i, entry in ipairs(owned) do
        MakeCard(grid, entry, i)
    end
    MakeAddTile(grid, #owned + 1, OpenCreateModal)
end

Window:OnUnload(function()
    state.unloaded = true
    env.BPRestaurants = nil
    pcall(function()
        for _, child in ipairs(GetSafeParent():GetChildren()) do
            if child:IsA("ScreenGui") and child.Name == "GousseBP_CreateModal" then
                child:Destroy()
            end
        end
    end)
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
