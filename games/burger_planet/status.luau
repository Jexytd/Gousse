-- Burger Planet: Fast Food Simulator — restaurant status & customer tracker
-- Built from the lobby restaurant manager patterns. Reads live client-replicated
-- FastFood.State, FastFood.Orders and workspace NPCs; no server writes.

local env = (getgenv and getgenv()) or _G or {}
local GousseUI = env.GousseUI

local function looksLikeLibrary(src)
    return type(src) == "string" and #src > 5000 and src:find("GousseUI", 1, true) ~= nil
end

if not GousseUI then
    local okLocal, resLocal = pcall(function()
        return game:HttpGet("http://localhost:3456/library.luau")
    end)
    if okLocal and looksLikeLibrary(resLocal) then
        local okLoad, lib = pcall(function() return loadstring(resLocal)() end)
        if okLoad and lib then GousseUI = lib end
    end
end

if not GousseUI then
    local okRemote, resRemote = pcall(function()
        return game:HttpGet("https://raw.githubusercontent.com/Jexytd/Gousse/main/library.luau")
    end)
    if okRemote and looksLikeLibrary(resRemote) then
        local okLoad, lib = pcall(function() return loadstring(resRemote)() end)
        if okLoad and lib then GousseUI = lib end
    end
end

if not GousseUI then
    warn("[BP Status] GousseUI failed to load")
    return
end

local previous = env.BPStatus
if type(previous) == "table" and type(previous.Shutdown) == "function" then
    pcall(previous.Shutdown)
end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local FastFood = ReplicatedStorage:FindFirstChild("FastFood")
if not FastFood then
    GousseUI:NotifyError("FastFood data is unavailable. Join a restaurant first.", "Burger Planet", 5)
    return
end

local State = FastFood:WaitForChild("State", 10)
local Orders = FastFood:WaitForChild("Orders", 10)
if not State or not Orders then
    GousseUI:NotifyError("Restaurant state did not replicate yet.", "Burger Planet", 5)
    return
end

local FontBold = Enum.Font.BuilderSansBold or Enum.Font.GothamBold
local FontMedium = Enum.Font.BuilderSansMedium or Enum.Font.GothamMedium
local FontRegular = Enum.Font.BuilderSans or Enum.Font.Gotham

local state = { unloaded = false, statusDirty = true, customersDirty = true, tick = 0 }

local function New(class, props, parent)
    local inst = Instance.new(class)
    for key, value in pairs(props) do inst[key] = value end
    if parent then inst.Parent = parent end
    return inst
end

local function Attr(name, fallback)
    local value = State:GetAttribute(name)
    if value == nil then return fallback end
    return value
end

local function Money(n)
    n = tonumber(n) or 0
    if n >= 1000000 then return string.format("%.2fM", n / 1000000) end
    if n >= 1000 then return string.format("%.1fK", n / 1000) end
    return tostring(math.floor(n))
end

local function Clock(t)
    t = tonumber(t) or 0
    local h = math.floor(t / 60) % 24
    local m = math.floor(t % 60)
    return string.format("%02d:%02d", h, m)
end

local function Countdown(deadline)
    local left = math.max(0, (tonumber(deadline) or 0) - os.time())
    return string.format("%02d:%02d", math.floor(left / 60), math.floor(left % 60))
end

local function FindNPCs()
    local root = workspace:FindFirstChild("FastFood", true)
    return root and root:FindFirstChild("NPCs") or nil
end

local function OrderLive(order)
    if not order then return false end
    local status = tostring(order:GetAttribute("Status") or "")
    local deadline = tonumber(order:GetAttribute("Deadline")) or 0
    return order:GetAttribute("Complete") ~= true
        and status ~= "Done"
        and deadline > os.time()
end

local Window = GousseUI:CreateWindow({
    Title = "Burger Planet",
    SubTitle = "Operations",
    Keybind = Enum.KeyCode.RightControl,
    Size = UDim2.new(0, 640, 0, 460),
    AutoSettings = true
})

local statusTab = Window:CreateTab({ Name = "Status", Icon = "activity" })
local customerTab = Window:CreateTab({ Name = "Customers", Icon = "users" })

local CARD_W, STATUS_H, CUSTOMER_H = 196, 92, 124

local function ClearPage(page)
    for _, child in ipairs(page:GetChildren()) do
        if not child:IsA("UIListLayout") then child:Destroy() end
    end
end

local function MakeGrid(page)
    local grid = New("Frame", {
        Name = "Grid",
        Size = UDim2.new(1, -8, 0, 1),
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y
    }, page)
    New("UIGridLayout", {
        CellSize = UDim2.new(0, CARD_W, 0, STATUS_H),
        CellPadding = UDim2.new(0, 8, 0, 8),
        FillDirection = Enum.FillDirection.Horizontal,
        FillDirectionMaxCells = 3,
        SortOrder = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Top
    }, grid)
    return grid
end

local function MakeCard(parent, name, order, iconKey, color, value, detail, height)
    local card = New("Frame", {
        Name = "Card_" .. name,
        LayoutOrder = order,
        Size = UDim2.new(0, CARD_W, 0, height or STATUS_H),
        BackgroundColor3 = GousseUI.Theme.Surface,
        BorderSizePixel = 0,
        ClipsDescendants = true
    }, parent)
    New("UICorner", { CornerRadius = UDim.new(0, 8) }, card)
    New("UIStroke", { Color = GousseUI.Theme.Border, Thickness = 1 }, card)
    New("Frame", {
        Size = UDim2.new(1, 0, 0, 3),
        BackgroundColor3 = color,
        BorderSizePixel = 0
    }, card)

    local icon = GousseUI:GetIcon(iconKey)
    if icon and icon ~= "" then
        New("ImageLabel", {
            Position = UDim2.new(0, 10, 0, 10),
            Size = UDim2.new(0, 18, 0, 18),
            BackgroundTransparency = 1,
            Image = icon,
            ImageColor3 = color
        }, card)
    end

    New("TextLabel", {
        Position = UDim2.new(0, 34, 0, 8),
        Size = UDim2.new(1, -44, 0, 20),
        BackgroundTransparency = 1,
        Font = FontMedium,
        Text = name:upper(),
        TextColor3 = GousseUI.Theme.TextMuted,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left
    }, card)

    New("TextLabel", {
        Position = UDim2.new(0, 10, 0, 34),
        Size = UDim2.new(1, -20, 0, 28),
        BackgroundTransparency = 1,
        Font = FontBold,
        Text = tostring(value),
        TextColor3 = GousseUI.Theme.TextPrimary,
        TextSize = 19,
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextXAlignment = Enum.TextXAlignment.Left
    }, card)

    New("TextLabel", {
        Position = UDim2.new(0, 10, 0, 64),
        Size = UDim2.new(1, -20, 0, 20),
        BackgroundTransparency = 1,
        Font = FontRegular,
        Text = tostring(detail or ""),
        TextColor3 = GousseUI.Theme.TextSecondary,
        TextSize = 10.5,
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextXAlignment = Enum.TextXAlignment.Left
    }, card)
    return card
end

local function StatusMetrics()
    local xp = tonumber(Attr("XP", 0)) or 0
    local xpNext = tonumber(Attr("XPNext", 1)) or 1
    local staff = Attr("Staff", {})
    local goalsDone = tonumber(Attr("GoalsDone", 0)) or 0
    local goalsTotal = tonumber(Attr("GoalsTotal", 0)) or 0

    return {
        { "Cash", "coins", GousseUI.Theme.Warning, Money(Attr("Money", 0)), "Day revenue $" .. Money(Attr("DayRevenue", 0)) },
        { "Level", "star", GousseUI.Theme.Accent, "Lv " .. tostring(Attr("Level", 0)), "XP " .. Money(xp) .. " / " .. Money(xpNext) },
        { "Day & phase", "calendar", GousseUI.Theme.Blue, "Day " .. tostring(Attr("Day", 0)), tostring(Attr("Phase", "Idle")) .. "  ·  " .. tostring(Attr("Weather", "Clear")) },
        { "Clock", "clock", GousseUI.Theme.Blue, Clock(Attr("Clock", 0)), "Shift " .. Clock(Attr("ShiftOpen", 0)) .. "–" .. Clock(Attr("ShiftClose", 0)) },
        { "Rating", "award", GousseUI.Theme.Accent, tostring(Attr("Stars", 0)) .. " ★", tostring(Attr("Rating", 0)) .. " · " .. tostring(Attr("RatingCount", 0)) .. " votes" },
        { "Cleanliness", "sparkles", GousseUI.Theme.Success, tostring(Attr("Cleanliness", 0)) .. "%", "Tables & spills" },
        { "Served today", "utensils", GousseUI.Theme.Accent, tostring(Attr("DayServed", 0)), "Streak " .. tostring(Attr("Streak", 0)) .. "  ·  hot x" .. tostring(Attr("HotMult", 1)) },
        { "Staff", "users", GousseUI.Theme.Blue, tostring(type(staff) == "table" and #staff or 0), "Max players " .. tostring(Attr("MaxPlayers", 0)) },
        { "Goals", "target", GousseUI.Theme.Warning, goalsDone .. " / " .. goalsTotal, "Perks & upgrades" },
        { "Site", "truck", GousseUI.Theme.Warning, tostring(Attr("Site", "Restaurant")), tostring(Attr("GameMode", "Career")) .. "  ·  " .. tostring(Attr("Difficulty", "Normal")) },
        { "Owner", "user", GousseUI.Theme.Blue, tostring(Attr("Owner", "—")), tostring(Attr("RestaurantName", "—")) .. "  ·  slot " .. tostring(Attr("Slot", "—")) },
        { "Front / drive", "door-open", GousseUI.Theme.Success, (Attr("FrontOpen") and "Open" or "Shut"), "Drive-thru " .. (Attr("DriveOpen") and "open" or "closed") }
    }
end

local function RenderStatus()
    if state.unloaded then return end
    ClearPage(statusTab.Page)

    New("TextLabel", {
        Size = UDim2.new(1, -8, 0, 26),
        BackgroundTransparency = 1,
        Font = FontMedium,
        Text = tostring(Attr("RestaurantName", "Restaurant")) .. "  ·  " .. tostring(Attr("Owner", "—")) .. "  ·  " .. tostring(Attr("GameMode", "Career")),
        TextColor3 = GousseUI.Theme.TextSecondary,
        TextSize = 11.5,
        TextXAlignment = Enum.TextXAlignment.Left
    }, statusTab.Page)

    local grid = MakeGrid(statusTab.Page)
    for i, metric in ipairs(StatusMetrics()) do
        MakeCard(grid, metric[1], i, metric[2], metric[3], metric[4], metric[5])
    end
end

local function OrderRows()
    local rows = {}
    for _, order in ipairs(Orders:GetChildren()) do
        local status = tostring(order:GetAttribute("Status") or "")
        local live = OrderLive(order)
        rows[#rows + 1] = {
            kind = "order",
            ref = order,
            customer = tostring(order:GetAttribute("Customer") or "—"),
            label = status ~= "" and status or (live and "Active" or "Closed"),
            detail = tostring(order:GetAttribute("Kind") or "DineIn") .. "  ·  " .. Countdown(order:GetAttribute("Deadline")),
            live = live,
            ready = status == "Ready"
        }
    end

    local npcs = FindNPCs()
    for _, npc in ipairs(npcs and npcs:GetChildren() or {}) do
        local tag = tostring(npc:GetAttribute("Interact") or "")
        if tag == "Customer" or tag == "DeliveryCustomer" then
            local name = tostring(npc:GetAttribute("CustomerName") or npc.Name)
            local orderId = npc:GetAttribute("OrderId")
            local linked
            for _, row in ipairs(rows) do
                if row.ref:GetAttribute("Id") == orderId or row.customer == name then linked = row.ref break end
            end
            rows[#rows + 1] = {
                kind = "npc",
                ref = npc,
                customer = name,
                label = tag == "DeliveryCustomer" and "Delivery" or "On site",
                detail = linked and (tostring(linked.ref:GetAttribute("Status") or "Active") .. "  ·  " .. Countdown(linked.ref:GetAttribute("Deadline"))) or "waiting for order",
                live = linked ~= nil,
                ready = false
            }
        end
    end
    return rows
end

local function RenderCustomers()
    if state.unloaded then return end
    ClearPage(customerTab.Page)
    local rows = OrderRows()

    local live, ready, delivery = 0, 0, 0
    for _, row in ipairs(rows) do
        if row.kind == "order" and row.live then live += 1 end
        if row.ready then ready += 1 end
        if row.label == "Delivery" then delivery += 1 end
    end

    New("TextLabel", {
        Size = UDim2.new(1, -8, 0, 26),
        BackgroundTransparency = 1,
        Font = FontMedium,
        Text = "Live " .. live .. "   ·   Ready " .. ready .. "   ·   On site " .. #rows .. "   ·   Delivery " .. delivery,
        TextColor3 = GousseUI.Theme.TextSecondary,
        TextSize = 11.5,
        TextXAlignment = Enum.TextXAlignment.Left
    }, customerTab.Page)

    if #rows == 0 then
        New("TextLabel", {
            Size = UDim2.new(1, -8, 0, 40),
            BackgroundTransparency = 1,
            Font = FontRegular,
            Text = "No customers on the lot right now.",
            TextColor3 = GousseUI.Theme.TextMuted,
            TextSize = 11.5
        }, customerTab.Page)
        return
    end

    local grid = New("Frame", {
        Size = UDim2.new(1, -8, 0, 1),
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y
    }, customerTab.Page)
    New("UIGridLayout", {
        CellSize = UDim2.new(0, CARD_W, 0, CUSTOMER_H),
        CellPadding = UDim2.new(0, 8, 0, 8),
        FillDirection = Enum.FillDirection.Horizontal,
        FillDirectionMaxCells = 3,
        SortOrder = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Top
    }, grid)

    for i, row in ipairs(rows) do
        local color = row.ready and GousseUI.Theme.Success
            or (row.live and GousseUI.Theme.Warning or GousseUI.Theme.TextMuted)
        MakeCard(grid, row.customer, i, row.kind == "npc" and "user" or "receipt", color, row.label, row.detail, CUSTOMER_H)
    end
end

-- Refresh scheduling: attribute storms coalesce into one rebuild per frame.
local function Schedule(kind)
    if kind == "status" then state.statusDirty = true else state.customersDirty = true end
end

local connections = {}
local function Watch(signal, callback)
    local ok, conn = pcall(function() return signal:Connect(callback) end)
    if ok and conn then connections[#connections + 1] = conn end
end

for _, name in ipairs({
    "Money", "DayRevenue", "Level", "XP", "XPNext", "Day", "Phase", "Clock",
    "ShiftOpen", "ShiftClose", "Weather", "Stars", "Rating", "RatingCount",
    "Cleanliness", "DayServed", "Streak", "HotMult", "Staff", "GoalsDone",
    "GoalsTotal", "Site", "GameMode", "Difficulty", "Owner", "RestaurantName",
    "Slot", "FrontOpen", "DriveOpen"
}) do
    Watch(State:GetAttributeChangedSignal(name), function() Schedule("status") end)
end

Watch(Orders.ChildAdded, function() Schedule("customers") end)
Watch(Orders.ChildRemoved, function() Schedule("customers") end)
Watch(RunService.Heartbeat, function()
    -- Countdowns are second-resolution; rebuild at most once per second.
    if os.clock() - state.tick < 1 then return end
    state.tick = os.clock()
    state.customersDirty = false
    RenderCustomers()
end)

local npcRoot = FindNPCs()
if npcRoot then
    Watch(npcRoot.ChildAdded, function() Schedule("customers") end)
    Watch(npcRoot.ChildRemoved, function() Schedule("customers") end)
end

Window:OnUnload(function()
    state.unloaded = true
    for _, conn in ipairs(connections) do
        pcall(function() conn:Disconnect() end)
    end
    table.clear(connections)
    env.BPStatus = nil
end)

env.BPStatus = {
    Window = Window,
    Shutdown = function()
        state.unloaded = true
        pcall(function() Window:Unload() end)
        env.BPStatus = nil
    end
}

RenderStatus()
RenderCustomers()
GousseUI:NotifySuccess("Status & customer tracker ready.", "Burger Planet", 3)
