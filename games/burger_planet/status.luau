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

local state = {
    unloaded = false,
    statusDirty = true,
    customersDirty = true,
    siteDirty = true,
    tick = 0,
    siteTick = 0,
    orderQty = 1,
    catalog = nil,
    inventory = nil,
    pending = 0,
    baselineBoxes = {}
}

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

local Remotes = FastFood:WaitForChild("Remotes", 10)
local Computer = Remotes and Remotes:FindFirstChild("Computer")

local function SiteRoot()
    -- The active site is the root that actually has Items/NPCs replicated.
    local restaurant = workspace:FindFirstChild("FastFood", true)
    local truck = workspace:FindFirstChild("FoodTruck", true)
    if truck and truck:FindFirstChild("Items") then return truck end
    if restaurant and restaurant:FindFirstChild("Items") then return restaurant end
    return restaurant or truck
end

local function AskComputer(command, payload)
    if not Computer then
        return { Ok = false, Message = "Computer remote is unavailable." }
    end
    local ok, result = pcall(function()
        return Computer:InvokeServer(command, payload)
    end)
    if not ok then return { Ok = false, Message = tostring(result) } end
    if type(result) ~= "table" then
        return { Ok = false, Message = "No response from the server." }
    end
    return result
end

local function FindNPCs()
    local root = SiteRoot()
    return root and root:FindFirstChild("NPCs") or nil
end

local function FetchCatalog()
    local data = AskComputer("GetData")
    if type(data) == "table" then
        if type(data.Supplies) == "table" then state.catalog = data.Supplies end
        if type(data.Inventory) == "table" then state.inventory = data.Inventory end
        state.pending = tonumber(data.Pending) or 0
    end
    return state.catalog
end

local function OpenComputer()
    local root = SiteRoot()
    local stations = root and root:FindFirstChild("Stations")
    if not stations or not Remotes or not Remotes:FindFirstChild("Interact") then return false end
    local screen
    for _, part in ipairs(stations:GetDescendants()) do
        if part:IsA("BasePart") and part:GetAttribute("Interact") == "Computer" then
            if part.Name == "Screen" then
                screen = part
                break
            end
            screen = screen or part
        end
    end
    if not screen then return false end
    pcall(function()
        Remotes.Interact:FireServer(screen, "Primary", screen.Position)
    end)
    return true
end

local function OrderSupply(id, name, quantity)
    if not id then return end
    OpenComputer()
    task.wait(0.3)
    local cart = { [id] = quantity }
    local result = AskComputer("Order", { Cart = cart })
    GousseUI:Notify({
        Title = "Order " .. tostring(name),
        Content = result.Ok and ("Ordered " .. quantity .. " box(es).") or (result.Message or "Order refused."),
        Type = result.Ok and "success" or "error",
        Duration = 3
    })
    if result.Ok then
        FetchCatalog()
        state.siteDirty = true
    end
end

local function IsSupplyBox(inst)
    return inst:GetAttribute("Interact") == "Item"
        and inst:GetAttribute("Item") == "Box"
        and inst:GetAttribute("Supply") ~= nil
end

local function SnapshotBoxes()
    state.baselineBoxes = {}
    local root = SiteRoot()
    for _, inst in ipairs(root and root:GetDescendants() or {}) do
        if IsSupplyBox(inst) then state.baselineBoxes[inst] = true end
    end
end

local function DeliveryBoxes()
    local out = {}
    local root = SiteRoot()
    for _, inst in ipairs(root and root:GetDescendants() or {}) do
        if IsSupplyBox(inst) and not state.baselineBoxes[inst] then
            local location = inst.Parent and inst.Parent.Name or "—"
            local cursor = inst.Parent
            while cursor do
                if tostring(cursor.Name):find("Pallet") then
                    location = cursor.Name
                    break
                end
                cursor = cursor.Parent
            end
            out[#out + 1] = {
                ref = inst,
                supply = tostring(inst:GetAttribute("Supply") or "—"),
                amount = tonumber(inst:GetAttribute("Amount")) or 0,
                label = tostring(inst:GetAttribute("Label") or inst.Name),
                id = tostring(inst:GetAttribute("ItemId") or "—"),
                location = location
            }
        end
    end
    return out
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
local siteTab = Window:CreateTab({ Name = "Site", Icon = "store" })
local deliveryTab = Window:CreateTab({ Name = "Delivery", Icon = "truck" })
local storageTab = Window:CreateTab({ Name = "Storage", Icon = "archive" })

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

local function ActionButton(parent, text, position, width, color, callback)
    local btn = New("TextButton", {
        Position = position,
        Size = UDim2.new(0, width, 0, 32),
        BackgroundColor3 = color,
        BorderSizePixel = 0,
        Font = FontBold,
        Text = text,
        TextColor3 = GousseUI.Theme.TextPrimary,
        TextSize = 11.5,
        AutoButtonColor = false
    }, parent)
    New("UICorner", { CornerRadius = UDim.new(0, 6) }, btn)
    btn.MouseButton1Click:Connect(function()
        task.spawn(callback)
    end)
    return btn
end

local function RenderSite()
    if state.unloaded then return end
    ClearPage(siteTab.Page)

    local phase = tostring(Attr("Phase", "Idle"))
    New("TextLabel", {
        Size = UDim2.new(1, -8, 0, 26),
        BackgroundTransparency = 1,
        Font = FontMedium,
        Text = "Phase " .. phase .. "   ·   Front " .. (Attr("FrontOpen") and "open" or "shut")
            .. "   ·   Drive " .. (Attr("DriveOpen") and "open" or "shut")
            .. "   ·   " .. tostring(Attr("GameMode", "Career")),
        TextColor3 = GousseUI.Theme.TextSecondary,
        TextSize = 11.5,
        TextXAlignment = Enum.TextXAlignment.Left
    }, siteTab.Page)

    local actionRow = New("Frame", {
        Size = UDim2.new(1, -8, 0, 32),
        BackgroundTransparency = 1
    }, siteTab.Page)
    ActionButton(actionRow, "OPEN SITE", UDim2.new(0, 0, 0, 0), 150, GousseUI.Theme.Accent, function()
        local result = AskComputer("Open")
        GousseUI:Notify({
            Title = "Burger Planet",
            Content = result.Ok and "Site opened." or (result.Message or "Could not open the site."),
            Type = result.Ok and "success" or "error",
            Duration = 3
        })
        state.siteDirty = true
    end)
    ActionButton(actionRow, "CLOSE EARLY", UDim2.new(0, 158, 0, 0), 150, Color3.fromRGB(190, 45, 65), function()
        local result = AskComputer("CloseEarly")
        GousseUI:Notify({
            Title = "Burger Planet",
            Content = result.Ok and "Shift closed early." or (result.Message or "Could not close the site."),
            Type = result.Ok and "success" or "error",
            Duration = 3
        })
        state.siteDirty = true
    end)

    local laneRow = New("Frame", {
        Size = UDim2.new(1, -8, 0, 32),
        BackgroundTransparency = 1
    }, siteTab.Page)
    local lanes = {
        { "Front", "FrontOpen" },
        { "Drive", "DriveOpen" },
        { "Delivery", "DeliveryOpen" }
    }
    for i, lane in ipairs(lanes) do
        local opened = Attr(lane[2]) ~= false
        ActionButton(laneRow, lane[1] .. ": " .. (opened and "OPEN" or "SHUT"),
            UDim2.new(0, (i - 1) * 116, 0, 0), 108,
            opened and GousseUI.Theme.Warning or GousseUI.Theme.SurfaceHover,
            function()
                local result = AskComputer("SetLane", { Lane = lane[1], Open = not opened })
                GousseUI:Notify({
                    Title = "Burger Planet",
                    Content = result.Ok and (lane[1] .. " updated.") or (result.Message or "Could not update the lane."),
                    Type = result.Ok and "success" or "error",
                    Duration = 2.5
                })
                state.siteDirty = true
            end)
    end

    New("TextLabel", {
        Size = UDim2.new(1, -8, 0, 22),
        BackgroundTransparency = 1,
        Font = FontBold,
        Text = "SUPPLIES ON HAND",
        TextColor3 = GousseUI.Theme.TextMuted,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left
    }, siteTab.Page)

    local qtyRow = New("Frame", {
        Size = UDim2.new(1, -8, 0, 32),
        BackgroundTransparency = 1
    }, siteTab.Page)
    New("TextLabel", {
        Position = UDim2.new(0, 0, 0, 7),
        Size = UDim2.new(0, 78, 0, 18),
        BackgroundTransparency = 1,
        Font = FontMedium,
        Text = "ORDER QTY",
        TextColor3 = GousseUI.Theme.TextMuted,
        TextSize = 10.5,
        TextXAlignment = Enum.TextXAlignment.Left
    }, qtyRow)
    for i, qty in ipairs({ 1, 5, 10 }) do
        ActionButton(qtyRow, "x" .. qty, UDim2.new(0, 84 + (i - 1) * 66, 0, 0), 60,
            state.orderQty == qty and GousseUI.Theme.Accent or GousseUI.Theme.SurfaceHover,
            function()
                state.orderQty = qty
                RenderSite()
            end)
    end

    local stock = {}
    local root = SiteRoot()
    local items = root and root:FindFirstChild("Items")
    for _, item in ipairs(items and items:GetChildren() or {}) do
        local key = item:GetAttribute("Supply") or item:GetAttribute("Ingredient")
        if not key and item:GetAttribute("Sauce") then key = "Sauces" end
        key = tostring(key or item.Name)
        stock[key] = (stock[key] or 0) + (tonumber(item:GetAttribute("Amount")) or 0)
    end

    local entries = {}
    for _, supply in ipairs(state.catalog or {}) do
        if type(supply) == "table" and not supply.Locked then
            entries[#entries + 1] = {
                id = supply.Id,
                name = tostring(supply.Name or supply.Id),
                amount = stock[supply.Id] or 0,
                price = tonumber(supply.Price) or 0,
                storage = tostring(supply.Storage or "Dry"),
                pack = tonumber(supply.Amount) or 0
            }
        end
    end
    if #entries == 0 then
        for key, amount in pairs(stock) do
            entries[#entries + 1] = { id = nil, name = key, amount = amount, price = 0, storage = "—", pack = 0 }
        end
    end
    table.sort(entries, function(a, b) return a.amount < b.amount end)

    if #entries == 0 then
        New("TextLabel", {
            Size = UDim2.new(1, -8, 0, 30),
            BackgroundTransparency = 1,
            Font = FontRegular,
            Text = "No stock items replicated yet.",
            TextColor3 = GousseUI.Theme.TextMuted,
            TextSize = 11
        }, siteTab.Page)
        return
    end

    local grid = New("Frame", {
        Name = "SupplyGrid",
        Size = UDim2.new(1, -8, 0, 1),
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y
    }, siteTab.Page)
    New("UIGridLayout", {
        CellSize = UDim2.new(0, CARD_W, 0, 124),
        CellPadding = UDim2.new(0, 8, 0, 8),
        FillDirection = Enum.FillDirection.Horizontal,
        FillDirectionMaxCells = 3,
        SortOrder = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Top
    }, grid)

    for i, entry in ipairs(entries) do
        local color = entry.amount <= 5 and GousseUI.Theme.Danger
            or (entry.amount <= 12 and GousseUI.Theme.Warning or GousseUI.Theme.Success)
        local card = New("Frame", {
            Name = "Supply_" .. tostring(entry.id or entry.name),
            LayoutOrder = i,
            Size = UDim2.new(0, CARD_W, 0, 124),
            BackgroundColor3 = GousseUI.Theme.Surface,
            BorderSizePixel = 0,
            ClipsDescendants = true
        }, grid)
        New("UICorner", { CornerRadius = UDim.new(0, 8) }, card)
        New("UIStroke", { Color = GousseUI.Theme.Border, Thickness = 1 }, card)
        New("Frame", {
            Size = UDim2.new(1, 0, 0, 3),
            BackgroundColor3 = color,
            BorderSizePixel = 0
        }, card)

        New("TextLabel", {
            Position = UDim2.new(0, 10, 0, 9),
            Size = UDim2.new(1, -20, 0, 20),
            BackgroundTransparency = 1,
            Font = FontBold,
            Text = entry.name,
            TextColor3 = GousseUI.Theme.TextPrimary,
            TextSize = 12.5,
            TextTruncate = Enum.TextTruncate.AtEnd,
            TextXAlignment = Enum.TextXAlignment.Left
        }, card)

        New("TextLabel", {
            Position = UDim2.new(0, 10, 0, 32),
            Size = UDim2.new(1, -20, 0, 18),
            BackgroundTransparency = 1,
            Font = FontRegular,
            Text = "Stock " .. entry.amount .. "  ·  " .. entry.storage,
            TextColor3 = color,
            TextSize = 10.5,
            TextXAlignment = Enum.TextXAlignment.Left
        }, card)

        New("TextLabel", {
            Position = UDim2.new(0, 10, 0, 52),
            Size = UDim2.new(1, -20, 0, 18),
            BackgroundTransparency = 1,
            Font = FontRegular,
            Text = "$" .. entry.price .. " / box  ·  pack " .. entry.pack,
            TextColor3 = GousseUI.Theme.TextMuted,
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left
        }, card)

        if entry.id then
            ActionButton(card, "ORDER x" .. state.orderQty, UDim2.new(0, 10, 1, -38), CARD_W - 20,
                GousseUI.Theme.Accent, function()
                    OrderSupply(entry.id, entry.name, state.orderQty)
                end)
        else
            New("TextLabel", {
                Position = UDim2.new(0, 10, 1, -34),
                Size = UDim2.new(1, -20, 0, 18),
                BackgroundTransparency = 1,
                Font = FontRegular,
                Text = "No catalog id",
                TextColor3 = GousseUI.Theme.TextMuted,
                TextSize = 10
            }, card)
        end
    end
end

local function StorageUnits()
    local inv = type(state.inventory) == "table" and state.inventory or {}
    local out = {}
    for _, siteName in ipairs({ "FoodTruck", "FastFood" }) do
        local root = workspace:FindFirstChild(siteName, true)
        local stations = root and root:FindFirstChild("Stations")
        for _, station in ipairs(stations and stations:GetChildren() or {}) do
            local name = station.Name
            -- Truck has no real freezer; its "Freezer" station is another cold unit.
            if siteName == "FoodTruck" and name == "Freezer" then continue end
            local isCabinet = name == "Cupboards" or tostring(name):lower():find("cabinet")
            local isCold = station:GetAttribute("Station") == "ColdStorage"
            if isCabinet or isCold then
                local capacity = 0
                for _, descendant in ipairs(station:GetDescendants()) do
                    if descendant.Name == "BoxSlot" then capacity += 1 end
                end
                if capacity == 0 then
                    for _, descendant in ipairs(station:GetDescendants()) do
                        if descendant:GetAttribute("Shelf") == true then capacity += 1 end
                    end
                end
                if capacity == 0 then capacity = #station:GetChildren() end

                local key = isCabinet and "Dry" or tostring(station:GetAttribute("StorageId") or "")
                local contents = type(inv[key]) == "table" and inv[key] or {}
                capacity = math.max(capacity, #contents)
                out[#out + 1] = {
                    site = siteName,
                    name = name,
                    key = key,
                    capacity = capacity,
                    contents = contents,
                    cold = isCold
                }
            end
        end
    end
    return out
end

local function SupplyColor(id)
    for _, supply in ipairs(state.catalog or {}) do
        if type(supply) == "table" and supply.Id == id then
            if supply.Storage == "Frozen" then return GousseUI.Theme.Blue end
            if supply.Storage == "Cold" then return GousseUI.Theme.Warning end
            return GousseUI.Theme.Accent
        end
    end
    return GousseUI.Theme.TextMuted
end

local function RenderStorage()
    if state.unloaded then return end
    ClearPage(storageTab.Page)

    local inv = type(state.inventory) == "table" and state.inventory or {}
    local dry = type(inv.Dry) == "table" and #inv.Dry or 0
    local fridge = type(inv.Fridge) == "table" and #inv.Fridge or 0
    local freezer = type(inv.Freezer) == "table" and #inv.Freezer or 0
    New("TextLabel", {
        Size = UDim2.new(1, -8, 0, 26),
        BackgroundTransparency = 1,
        Font = FontMedium,
        Text = "Inventory   ·   Dry " .. dry .. "   Fridge " .. fridge .. "   Freezer " .. freezer,
        TextColor3 = GousseUI.Theme.TextSecondary,
        TextSize = 11.5,
        TextXAlignment = Enum.TextXAlignment.Left
    }, storageTab.Page)

    local units = StorageUnits()
    if #units == 0 then
        New("TextLabel", {
            Position = UDim2.new(0, 0, 0, 40),
            Size = UDim2.new(1, -8, 0, 40),
            BackgroundTransparency = 1,
            Font = FontRegular,
            Text = "Tidak ada unit storage yang ter-replikasi di site ini.",
            TextColor3 = GousseUI.Theme.TextMuted,
            TextSize = 11
        }, storageTab.Page)
        return
    end

    local grid = New("Frame", {
        Size = UDim2.new(1, -8, 0, 1),
        Position = UDim2.new(0, 0, 0, 34),
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y
    }, storageTab.Page)
    New("UIGridLayout", {
        CellSize = UDim2.new(0, 250, 0, 168),
        CellPadding = UDim2.new(0, 8, 0, 8),
        FillDirection = Enum.FillDirection.Horizontal,
        FillDirectionMaxCells = 2,
        SortOrder = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Top
    }, grid)

    for i, unit in ipairs(units) do
        local card = New("Frame", {
            Name = "Storage_" .. unit.name,
            LayoutOrder = i,
            Size = UDim2.new(0, 250, 0, 168),
            BackgroundColor3 = GousseUI.Theme.Surface,
            BorderSizePixel = 0,
            ClipsDescendants = true
        }, grid)
        New("UICorner", { CornerRadius = UDim.new(0, 8) }, card)
        New("UIStroke", { Color = GousseUI.Theme.Border, Thickness = 1 }, card)
        New("Frame", {
            Size = UDim2.new(1, 0, 0, 3),
            BackgroundColor3 = unit.cold and GousseUI.Theme.Blue or GousseUI.Theme.Warning,
            BorderSizePixel = 0
        }, card)

        New("TextLabel", {
            Position = UDim2.new(0, 10, 0, 9),
            Size = UDim2.new(1, -20, 0, 22),
            BackgroundTransparency = 1,
            Font = FontBold,
            Text = unit.site .. "/" .. unit.name,
            TextColor3 = GousseUI.Theme.TextPrimary,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left
        }, card)
        New("TextLabel", {
            Position = UDim2.new(0, 10, 0, 32),
            Size = UDim2.new(1, -20, 0, 18),
            BackgroundTransparency = 1,
            Font = FontRegular,
            Text = unit.key .. "   ·   " .. #unit.contents .. " / " .. unit.capacity .. " slot terisi",
            TextColor3 = unit.cold and GousseUI.Theme.Blue or GousseUI.Theme.Warning,
            TextSize = 10.5,
            TextXAlignment = Enum.TextXAlignment.Left
        }, card)

        local slotFrame = New("Frame", {
            Position = UDim2.new(0, 10, 0, 58),
            Size = UDim2.new(1, -20, 0, 66),
            BackgroundTransparency = 1
        }, card)
        for slot = 1, math.min(unit.capacity, 24) do
            local col = (slot - 1) % 6
            local row = math.floor((slot - 1) / 6)
            local entry = unit.contents[slot]
            New("Frame", {
                Position = UDim2.new(0, col * 38, 0, row * 32),
                Size = UDim2.new(0, 32, 0, 26),
                BackgroundColor3 = entry and SupplyColor(entry.S) or GousseUI.Theme.SurfaceHover,
                BorderSizePixel = 0
            }, slotFrame)
        end

        local names = {}
        for _, entry in ipairs(unit.contents) do
            names[#names + 1] = tostring(entry.S or "?") .. " x" .. tostring(entry.A or 0)
        end
        New("TextLabel", {
            Position = UDim2.new(0, 10, 0, 130),
            Size = UDim2.new(1, -20, 0, 28),
            BackgroundTransparency = 1,
            Font = FontRegular,
            Text = #names > 0 and table.concat(names, "  ·  ") or "Kosong",
            TextColor3 = GousseUI.Theme.TextMuted,
            TextSize = 10,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top
        }, card)
    end
end

local function RenderDelivery()
    if state.unloaded then return end
    ClearPage(deliveryTab.Page)

    New("TextLabel", {
        Size = UDim2.new(1, -8, 0, 26),
        BackgroundTransparency = 1,
        Font = FontMedium,
        Text = "Pending deliveries: " .. tostring(state.pending)
            .. "   ·   Tracking boxes placed after this script loaded",
        TextColor3 = GousseUI.Theme.TextSecondary,
        TextSize = 11.5,
        TextXAlignment = Enum.TextXAlignment.Left
    }, deliveryTab.Page)

    local rescan = ActionButton(deliveryTab.Page, "RESCAN", UDim2.new(0, 0, 0, 32), 110,
        GousseUI.Theme.SurfaceHover, function()
            SnapshotBoxes()
            FetchCatalog()
            RenderDelivery()
        end)
    rescan.Position = UDim2.new(1, -118, 0, 32)

    local boxes = DeliveryBoxes()
    if #boxes == 0 then
        New("TextLabel", {
            Position = UDim2.new(0, 0, 0, 78),
            Size = UDim2.new(1, -8, 0, 44),
            BackgroundTransparency = 1,
            Font = FontRegular,
            Text = "Belum ada barang baru di pallet / storage sejak script dimuat.",
            TextColor3 = GousseUI.Theme.TextMuted,
            TextSize = 11,
            TextWrapped = true
        }, deliveryTab.Page)
        return
    end

    local grid = New("Frame", {
        Name = "DeliveryGrid",
        Position = UDim2.new(0, 0, 0, 78),
        Size = UDim2.new(1, -8, 0, 1),
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y
    }, deliveryTab.Page)
    New("UIGridLayout", {
        CellSize = UDim2.new(0, CARD_W, 0, 124),
        CellPadding = UDim2.new(0, 8, 0, 8),
        FillDirection = Enum.FillDirection.Horizontal,
        FillDirectionMaxCells = 3,
        SortOrder = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Top
    }, grid)

    for i, box in ipairs(boxes) do
        local card = New("Frame", {
            Name = "Delivery_" .. tostring(i),
            LayoutOrder = i,
            Size = UDim2.new(0, CARD_W, 0, 124),
            BackgroundColor3 = GousseUI.Theme.Surface,
            BorderSizePixel = 0,
            ClipsDescendants = true
        }, grid)
        New("UICorner", { CornerRadius = UDim.new(0, 8) }, card)
        New("UIStroke", { Color = GousseUI.Theme.Border, Thickness = 1 }, card)
        New("Frame", {
            Size = UDim2.new(1, 0, 0, 3),
            BackgroundColor3 = GousseUI.Theme.Warning,
            BorderSizePixel = 0
        }, card)

        New("TextLabel", {
            Position = UDim2.new(0, 10, 0, 9),
            Size = UDim2.new(1, -20, 0, 20),
            BackgroundTransparency = 1,
            Font = FontBold,
            Text = box.supply,
            TextColor3 = GousseUI.Theme.TextPrimary,
            TextSize = 12.5,
            TextTruncate = Enum.TextTruncate.AtEnd,
            TextXAlignment = Enum.TextXAlignment.Left
        }, card)
        New("TextLabel", {
            Position = UDim2.new(0, 10, 0, 32),
            Size = UDim2.new(1, -20, 0, 18),
            BackgroundTransparency = 1,
            Font = FontRegular,
            Text = "Amount " .. box.amount .. "  ·  " .. box.location,
            TextColor3 = GousseUI.Theme.Warning,
            TextSize = 10.5,
            TextXAlignment = Enum.TextXAlignment.Left
        }, card)
        New("TextLabel", {
            Position = UDim2.new(0, 10, 0, 52),
            Size = UDim2.new(1, -20, 0, 18),
            BackgroundTransparency = 1,
            Font = FontRegular,
            Text = box.label .. "  ·  id " .. box.id,
            TextColor3 = GousseUI.Theme.TextMuted,
            TextSize = 9.5,
            TextTruncate = Enum.TextTruncate.AtEnd,
            TextXAlignment = Enum.TextXAlignment.Left
        }, card)

        ActionButton(card, "MOVE TO STORAGE", UDim2.new(0, 10, 1, -38), CARD_W - 20,
            GousseUI.Theme.SurfaceHover, function()
                GousseUI:NotifyInfo("Pemindahan ke storage belum diimplementasikan.", "Burger Planet", 3)
            end)
    end
end

-- Refresh scheduling: attribute storms coalesce into one rebuild per frame.
local function Schedule(kind)
    if kind == "status" then state.statusDirty = true
    elseif kind == "site" then state.siteDirty = true
    else state.customersDirty = true end
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
for _, name in ipairs({ "Phase", "FrontOpen", "DriveOpen", "DeliveryOpen", "Site" }) do
    Watch(State:GetAttributeChangedSignal(name), function() Schedule("site") end)
end

Watch(RunService.Heartbeat, function()
    -- Countdowns are second-resolution; rebuild at most once per second.
    if os.clock() - state.tick >= 1 then
        state.tick = os.clock()
        state.customersDirty = false
        RenderCustomers()
    end
    -- Stock amounts change on every pickup; refresh the site panel on a slower tick.
    if os.clock() - state.siteTick >= 2 then
        state.siteTick = os.clock()
        state.siteDirty = false
        RenderSite()
        if Window.ActiveTab == deliveryTab then RenderDelivery() end
        if Window.ActiveTab == storageTab then RenderStorage() end
    end
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

SnapshotBoxes()
FetchCatalog()
RenderStatus()
RenderCustomers()
RenderSite()
RenderDelivery()
RenderStorage()
GousseUI:NotifySuccess("Status, customers, site, delivery & storage ready.", "Burger Planet", 3)
