-- Burger Planet: Fast Food Simulator — v5.1 (full unified source)
-- Executor: Potassium / Synapse / Krnl / Delta / Fluxus / any modern executor
-- Built against the shipped FastFoodClient source + instance dump.
-- Modules: Session, Litter, Register, Handoff, Farm, Cook (grill/fryer/warmer),
--          Assembly (build + serve), DriveThru, Orders watcher, Tools, State.

-- ============================================================
-- GousseUI RESOLUTION
-- ============================================================
local passedUI = ...
local env = (getgenv and getgenv()) or _G or {}
local GousseUI = passedUI or env.GousseUI

if not GousseUI then
    local okLocal, localRes = pcall(function()
        return game:HttpGet("http://localhost:3456/library.luau")
    end)
    if okLocal and localRes
        and not localRes:find("File Not Found")
        and not localRes:find("Cannot GET") then
        GousseUI = loadstring(localRes)()
    else
        GousseUI = loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/Jexytd/Gousse/main/library.luau"
        ))()
    end
end
if not GousseUI then error("[Burger Planet] GousseUI failed to load") end
GousseUI:SetTheme("emerald")

-- ============================================================
-- EXECUTOR CHECK (soft — Potassium + Synapse/Krnl/Delta/Fluxus OK)
-- ============================================================
local function hasFn(name)
    return (_G and rawget(_G, name))
        or (debug and rawget(debug, name))
        or (getgenv and rawget(getgenv(), name))
end

local EXEC_FNS = {
    required = {},
    optional = {
        "getgenv", "getfenv", "getreg", "setreadonly",
        "getrawmetatable", "hookfunction", "newcclosure",
        "cloneref", "firetouchinterest", "firesignal",
    },
}

local missingRequired, missingOptional = {}, {}
for _, n in ipairs(EXEC_FNS.required) do
    if not hasFn(n) then table.insert(missingRequired, n) end
end
for _, n in ipairs(EXEC_FNS.optional) do
    if not hasFn(n) then table.insert(missingOptional, n) end
end

local execName, execVer = "unknown", "?"
pcall(function()
    if identifyexecutor then
        local a, b = identifyexecutor()
        execName, execVer = tostring(a), tostring(b)
    end
end)

if #missingRequired > 0 then
    GousseUI:Notify({
        Title = "Burger Planet",
        Content = "Missing required executor fn: "
            .. table.concat(missingRequired, ", "),
        Type = "error", Duration = 8,
    })
    return
end

if #missingOptional > 0 then
    print(("[Burger Planet] executor=%s v%s — soft-missing: %s")
        :format(execName, execVer, table.concat(missingOptional, ", ")))
else
    print(("[Burger Planet] executor=%s v%s — all optional fns present")
        :format(execName, execVer))
end

-- ============================================================
-- SERVICES & ROOTS
-- ============================================================
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")
local UserInputService  = game:GetService("UserInputService")

local LP = Players.LocalPlayer
local FastFood = ReplicatedStorage:WaitForChild("FastFood", 30)
if not FastFood then
    GousseUI:Notify({
        Title = "Burger Planet",
        Content = "FastFood folder never arrived — not in game?",
        Type = "error", Duration = 6,
    })
    return
end

local Remotes   = FastFood:WaitForChild("Remotes", 30)
local State     = FastFood:WaitForChild("State", 30)
local Orders    = FastFood:WaitForChild("Orders", 30)
local Stations  = FastFood:WaitForChild("Stations", 30)
local ServerFF  = Workspace:FindFirstChild("FastFood")
    or Workspace:FindFirstChild("FoodTruck")
local WStations = ServerFF and ServerFF:FindFirstChild("Stations")
local WItems    = ServerFF and ServerFF:FindFirstChild("Items")
local WNPCs     = ServerFF and ServerFF:FindFirstChild("NPCs")

-- ============================================================
-- REMOTE HANDLES
-- ============================================================
local R = {}
for _, name in ipairs({
    "Interact", "Drop", "Throw", "Notify", "POS", "OpenGui", "Summary",
    "Effect", "CancelOrder", "Reprint", "Describe", "Computer", "Session",
    "Shop", "Lobby", "HomeDelivery", "Fans", "Season", "Feedback",
    "Closet", "Staff",
}) do
    local r = Remotes:FindFirstChild(name)
    if r then R[name] = r end
end

-- ============================================================
-- HELPERS
-- ============================================================
local function root()
    local c = LP.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function primaryPart(node)
    if not node then return nil end
    if node:IsA("BasePart") then return node end
    if node:IsA("Model") then
        return node.PrimaryPart
            or node:FindFirstChildWhichIsA("BasePart", true)
    end
    return nil
end

local function safe(fn, ...)
    local ok, err = pcall(fn, ...)
    return ok, err
end

local function teleportTo(pos)
    local r = root()
    if not r or not pos then return end
    safe(function()
        r.CFrame = CFrame.new(pos + Vector3.new(0, 4, 0))
    end)
    task.wait(0.15)
end

local function allInteractNodes()
    local hits = {}
    local function walk(node, depth)
        if depth > 5 or not node then return end
        for _, child in ipairs(node:GetChildren()) do
            if child:GetAttribute("Interact") ~= nil then
                table.insert(hits, child)
            end
            if child:IsA("Folder") or child:IsA("Model") then
                walk(child, depth + 1)
            end
        end
    end
    walk(WStations, 0)
    walk(ServerFF, 1)
    return hits
end

local function discoverRemotes(predicate)
    local hits = {}
    local function walk(node, depth)
        if depth > 4 or not node then return end
        for _, child in ipairs(node:GetChildren()) do
            if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") then
                if predicate(child) then table.insert(hits, child) end
            elseif child:IsA("Folder") then
                walk(child, depth + 1)
            end
        end
    end
    walk(Remotes, 0)
    return hits
end

local API = { enabled = {}, connections = {}, flags = {} }

local function conn(sig, fn)
    local c = sig:Connect(fn)
    table.insert(API.connections, c)
    return c
end

local function snapshot()
    local s = {}
    for _, attr in ipairs({
        "Money","Level","XP","XPNext","Day","Clock","Phase","Shift",
        "Stars","Rating","RatingCount","GameMode","Site","RestaurantName",
        "DriveOpen","FrontOpen","DriveLevel","DeliveryOpen","Pending",
        "HotStreak","HotMult","HotEnds",
    }) do
        s[attr] = State:GetAttribute(attr)
    end
    return s
end

-- ============================================================
-- LOADER
-- ============================================================
local Loader = GousseUI:CreateLoader({
    Title = "Gousse Hub",
    SubTitle = "Burger Planet • v5.1 (full bench)",
    GameName = "Burger Planet: Fast Food Simulator",
    Status = "Reading state...",
})
Loader:SetStatus("Wiring modules...", 0.4)

-- ============================================================
-- MODULE: SESSION
-- ============================================================
local SessionMod = {}

function SessionMod.info()
    if not R.Session then return nil end
    local ok, res = pcall(function() return R.Session:InvokeServer("Info") end)
    return ok and res or nil
end

function SessionMod.open(shiftId)
    if not R.Session then return false end
    local payload = { Open = true }
    if shiftId and shiftId ~= "" then payload.Shift = shiftId end
    local ok, res = pcall(function()
        return R.Session:InvokeServer("Shift", payload)
    end)
    return ok and res and res.Ok or false
end

function SessionMod.takeJob(jobId)
    if not jobId or jobId == "" then return false end
    local ok, res = pcall(function()
        return R.Session:InvokeServer("Job", jobId)
    end)
    return ok and res and res.Ok or false
end

-- ============================================================
-- MODULE: LITTER (pick → bin → dumpster)
-- ============================================================
local LitterMod = {
    interval = 0.35, range = 80, teleport = true,
    failBudget = 3, fails = 0, state = "idle",
    fullCache = {}, lastFull = 0,
}

local function canFullCheck(can)
    if not (R.Describe and can) then return false end
    local ok, d = pcall(function()
        return R.Describe:InvokeServer(can, LP:GetAttribute("Holding") or "")
    end)
    if not ok or type(d) ~= "table" then return false end
    local hay = tostring(d.Info or "") .. "|"
             .. tostring(d.Primary or "") .. "|"
             .. tostring(d.Secondary or "")
    if hay:lower():find("full") then return true end
    if d.Primary == nil and d.Secondary == nil and d.Info == nil then
        return true
    end
    return false
end

local function refreshFullCache(cans)
    local now = os.clock()
    if now - LitterMod.lastFull < 2.0 then return end
    LitterMod.lastFull = now
    for _, can in ipairs(cans) do
        LitterMod.fullCache[can] = canFullCheck(can)
    end
end

local function findTrashCans()
    local out = {}
    for _, n in ipairs(allInteractNodes()) do
        local nm = tostring(n:GetAttribute("Interact") or ""):lower()
        if (nm:find("trash") or nm:find("bin")) and not nm:find("bag") then
            table.insert(out, n)
        end
    end
    return out
end

local function findDumpsters()
    local out = {}
    for _, n in ipairs(allInteractNodes()) do
        local nm = tostring(n:GetAttribute("Interact") or ""):lower()
        if nm:find("dumpster") then table.insert(out, n) end
    end
    return out
end

local function nearestLitter()
    if not WItems then return nil end
    local r = root()
    local rp = r and r.Position
    local best, bestD = nil, math.huge
    for _, m in ipairs(WItems:GetChildren()) do
        if m:IsA("Model") then
            local nm = m.Name
            local isLitter = nm == "Litter"
                or m:GetAttribute("Interact") == "Litter"
                or m:GetAttribute("Item") == "Litter"
                or nm:lower():find("litter") ~= nil
            if isLitter then
                local p = primaryPart(m)
                if p then
                    local d = rp and (p.Position - rp).Magnitude or 0
                    if d < bestD and d <= LitterMod.range then
                        best, bestD = m, d
                    end
                end
            end
        end
    end
    return best
end

local function pickLitter()
    local m = nearestLitter()
    if not m then return false end
    local p = primaryPart(m)
    if not p then return false end
    if LitterMod.teleport then teleportTo(p.Position) end
    safe(function()
        R.Interact:FireServer(m, "Primary", p.Position)
    end)
    return true
end

local function depositLitter()
    local cans = findTrashCans()
    local dumpsters = findDumpsters()
    refreshFullCache(cans)
    local rp = root() and root().Position or Vector3.zero

    local sorted = {}
    for _, can in ipairs(cans) do
        if not LitterMod.fullCache[can] then
            local p = primaryPart(can)
            if p then
                table.insert(sorted, {
                    node = can, part = p,
                    dist = (p.Position - rp).Magnitude,
                })
            end
        end
    end
    table.sort(sorted, function(a, b) return a.dist < b.dist end)

    if #sorted > 0 then
        local t = sorted[1]
        if LitterMod.teleport then teleportTo(t.part.Position) end
        safe(function()
            R.Interact:FireServer(t.node, "Primary", t.part.Position)
        end)
        task.delay(0.8, function()
            if LP:GetAttribute("Holding") then
                LitterMod.fullCache[t.node] = true
            else
                LitterMod.fullCache[t.node] = false
                LitterMod.fails = 0
            end
        end)
        return true
    end

    if #dumpsters > 0 then
        local d = dumpsters[1]
        local p = primaryPart(d)
        if p then
            if LitterMod.teleport then teleportTo(p.Position) end
            safe(function()
                R.Interact:FireServer(d, "Primary", p.Position)
            end)
            task.delay(1.0, function()
                table.clear(LitterMod.fullCache)
                LitterMod.lastFull = 0
            end)
            return true
        end
    end
    return false
end

function LitterMod.sweep()
    if LP:GetAttribute("Holding") then
        LitterMod.state = "depositing"
        return depositLitter()
    end
    LitterMod.state = "picking"
    return pickLitter()
end

function LitterMod.status()
    local full = 0
    for _, v in pairs(LitterMod.fullCache) do
        if v then full = full + 1 end
    end
    return {
        state = LitterMod.state,
        holding = LP:GetAttribute("Holding") or "",
        cans = #findTrashCans(),
        dumpsters = #findDumpsters(),
        fullCans = full,
        fails = LitterMod.fails,
    }
end

-- ============================================================
-- MODULE: REGISTER (click + auto submit + handoff)
-- ============================================================
local RegisterMod = {
    interval = 0.6, teleport = true, handoff = true,
    autoKind = "auto", submitted = {},
}

local function pickKind(cfg)
    local kinds = cfg.Kinds or { "TakeOut" }
    if RegisterMod.autoKind ~= "auto" then
        for _, k in ipairs(kinds) do
            if k == RegisterMod.autoKind then return k end
        end
    end
    if cfg.Drive then return "Drive" end
    for _, k in ipairs(kinds) do
        if k == "TakeOut" then return "TakeOut" end
    end
    return kinds[1] or "TakeOut"
end

local function buildFromRequest(cfg)
    local items, builds = {}, {}
    local req = tostring(cfg.Request or ""):lower()
    for _, m in ipairs(cfg.Menu or {}) do
        local name = tostring(m.Name or ""):lower()
        if name ~= "" and req:find(name, 1, true) then
            table.insert(items, m.Id)
            table.insert(builds, false)
        end
    end
    if #items == 0 then
        local cheapest, cp = nil, math.huge
        for _, m in ipairs(cfg.Menu or {}) do
            local p = tonumber(m.Price) or 0
            if p < cp then cheapest, cp = m, p end
        end
        if cheapest then
            table.insert(items, cheapest.Id)
            table.insert(builds, false)
        end
    end
    return items, builds, pickKind(cfg)
end

if R.POS then
    conn(R.POS.OnClientEvent, function(cmd, payload)
        if not API.enabled.register then return end
        if cmd ~= "Open" or type(payload) ~= "table" then return end
        task.defer(function()
            local items, builds, kind = buildFromRequest(payload)
            if #items == 0 then return end
            safe(function()
                R.POS:FireServer("Submit", {
                    Items = items, Builds = builds, Kind = kind,
                })
            end)
            local cust = tostring(payload.Customer or "")
            if cust ~= "" then
                RegisterMod.submitted[cust] = os.clock()
            end
        end)
    end)
end

local function findWaitingRegisters()
    local out = {}
    for _, child in ipairs(allInteractNodes()) do
        if child:IsA("BasePart")
            and child:GetAttribute("Interact") == "Register" then
            local parent = child.Parent
            if parent
                and parent:GetAttribute("Customer") ~= nil
                and parent:GetAttribute("Enabled") ~= false then
                local cust = tostring(parent:GetAttribute("Customer") or "")
                local last = RegisterMod.submitted[cust]
                if not last or os.clock() - last > 4 then
                    table.insert(out, {
                        part = child, model = parent, customer = cust,
                    })
                end
            end
        end
    end
    return out
end

local function clickRegister(reg)
    if RegisterMod.teleport then teleportTo(reg.part.Position) end
    safe(function()
        R.Interact:FireServer(reg.part, "Primary", reg.part.Position)
    end)
end

local function findReadyOrders()
    local out = {}
    for _, o in ipairs(Orders:GetChildren()) do
        if o:GetAttribute("Status") == "Ready" then
            table.insert(out, {
                order = o,
                customer = o:GetAttribute("Customer"),
                kind = o:GetAttribute("Kind") or "DineIn",
                orderId = o:GetAttribute("Id"),
            })
        end
    end
    return out
end

local function handoffReady(ready)
    if not (WNPCs and ready.customer) then return false end
    local tag = ready.kind == "Delivery" and "DeliveryCustomer" or "Customer"
    for _, npc in ipairs(WNPCs:GetChildren()) do
        if npc:IsA("Model") and npc:GetAttribute("Interact") == tag then
            local match
            if ready.kind == "Delivery" then
                match = npc:GetAttribute("OrderId") == ready.orderId
            else
                match = npc:GetAttribute("CustomerName") == ready.customer
            end
            if match then
                local p = primaryPart(npc)
                if p then
                    local r = root()
                    if r and (p.Position - r.Position).Magnitude > 6 then
                        teleportTo(p.Position)
                    end
                    safe(function()
                        R.Interact:FireServer(npc, "Primary", p.Position)
                    end)
                    return true
                end
            end
        end
    end
    return false
end

function RegisterMod.sweep()
    for _, reg in ipairs(findWaitingRegisters()) do
        clickRegister(reg)
        task.wait(0.15)
    end
    if RegisterMod.handoff and LP:GetAttribute("Holding") ~= nil then
        for _, ready in ipairs(findReadyOrders()) do
            handoffReady(ready)
            task.wait(0.15)
        end
    end
end

function RegisterMod.status()
    local n = 0
    for _ in pairs(RegisterMod.submitted) do n = n + 1 end
    return {
        enabled = API.enabled.register,
        pending = #findWaitingRegisters(),
        ready = #findReadyOrders(),
        submitted = n,
    }
end

-- ============================================================
-- MODULE: COOK (grill slots, fryer baskets, warmer bays)
-- ============================================================
local CookMod = {
    interval = 0.4, teleport = true,
    grill = true, fryer = true, warmer = true,
    stats = { grill = 0, fryer = 0, warmer = 0 },
}

local function findFirstStation(namePattern)
    if not WStations then return nil end
    for _, child in ipairs(WStations:GetChildren()) do
        if child:IsA("Model") and child.Name:lower():find(namePattern) then
            return child
        end
    end
    return nil
end

local function collectNamedParts(model, pattern)
    local out = {}
    if not model then return out end
    for _, desc in ipairs(model:GetDescendants()) do
        if desc:IsA("BasePart") and desc.Name:lower():find(pattern) then
            table.insert(out, desc)
        end
    end
    return out
end

local function fireInteract(part, action, pos)
    if not part then return false end
    if CookMod.teleport and pos then teleportTo(pos) end
    safe(function()
        R.Interact:FireServer(part, action or "Primary",
            pos or part.Position)
    end)
    return true
end

function CookMod.grillTick()
    if not CookMod.grill then return 0 end
    local grill = findFirstStation("^grill")
    if not grill then return 0 end
    local slots = {}
    for _, c in ipairs(grill:GetChildren()) do
        if c:IsA("BasePart") and c.Name:lower():find("slot") then
            table.insert(slots, c)
        end
    end
    local n = 0
    for _, slot in ipairs(slots) do
        local holding = slot:GetAttribute("Item") or slot:GetAttribute("Kind")
        local cooking = slot:GetAttribute("Cooking")
        local done = slot:GetAttribute("Done") or slot:GetAttribute("Ready")
        if done then
            fireInteract(slot, "Primary", slot.Position); n += 1
        elseif not cooking and not holding then
            fireInteract(slot, "Primary", slot.Position); n += 1
        end
        task.wait(0.05)
    end
    CookMod.stats.grill = n
    return n
end

function CookMod.fryerTick()
    if not CookMod.fryer then return 0 end
    local fryers = { findFirstStation("^fryer") }
    local n = 0
    for _, fryer in ipairs(fryers) do
        if fryer then
            local hits = collectNamedParts(fryer, "baskethit")
            if #hits == 0 then
                hits = collectNamedParts(fryer, "basket")
            end
            for _, hit in ipairs(hits) do
                local holding = hit:GetAttribute("Item") or hit:GetAttribute("Kind")
                local done = hit:GetAttribute("Done") or hit:GetAttribute("Ready")
                local cooking = hit:GetAttribute("Cooking")
                if done or (not cooking and not holding) then
                    fireInteract(hit, "Primary", hit.Position); n += 1
                end
                task.wait(0.05)
            end
        end
    end
    CookMod.stats.fryer = n
    return n
end

function CookMod.warmerTick()
    if not CookMod.warmer then return 0 end
    local warmer = findFirstStation("^warmer")
    if not warmer then return 0 end
    local keys = { "frieshit", "hashbrownshit", "nuggetshit", "onionringshit" }
    local n = 0
    for _, k in ipairs(keys) do
        local parts = collectNamedParts(warmer, k)
        for _, part in ipairs(parts) do
            local holding = part:GetAttribute("Item") or part:GetAttribute("Kind")
            local empty = not holding
            if empty then
                fireInteract(part, "Primary", part.Position); n += 1
            end
            task.wait(0.05)
        end
    end
    CookMod.stats.warmer = n
    return n
end

function CookMod.sweep()
    local total = 0
    total += CookMod.grillTick()
    total += CookMod.fryerTick()
    total += CookMod.warmerTick()
    return total
end

-- ============================================================
-- MODULE: ASSEMBLY (build order at island A/B)
-- ============================================================
local AssemblyMod = { interval = 0.5, teleport = true }

local function findAssemblyZones()
    local out = {}
    if not WStations then return out end
    for _, child in ipairs(WStations:GetChildren()) do
        if child:IsA("Model") and child.Name:lower():find("assembly") then
            for _, part in ipairs(child:GetChildren()) do
                if part:IsA("BasePart") and part:GetAttribute("Interact") then
                    table.insert(out, part)
                end
            end
        end
    end
    return out
end

function AssemblyMod.sweep()
    if not R.Interact then return 0 end
    local n = 0
    for _, zone in ipairs(findAssemblyZones()) do
        if AssemblyMod.teleport then teleportTo(zone.Position) end
        safe(function()
            R.Interact:FireServer(zone, "Primary", zone.Position)
        end)
        n += 1
        task.wait(0.1)
    end
    return n
end

-- ============================================================
-- MODULE: DRIVETHRU (register 3 + window hit)
-- ============================================================
local DriveMod = { interval = 0.5, teleport = true }

local function findDriveStation()
    if not WStations then return nil end
    for _, c in ipairs(WStations:GetChildren()) do
        if c:IsA("Model") and c.Name:lower():find("drivethru") then
            return c
        end
    end
    return nil
end

local function findDriveRegister(station)
    if not station then return nil end
    for _, c in ipairs(station:GetChildren()) do
        if c:IsA("Model") and c.Name:lower():find("register") then
            for _, part in ipairs(c:GetDescendants()) do
                if part:IsA("BasePart")
                    and part:GetAttribute("Interact") == "Register" then
                    return part
                end
            end
        end
    end
    return nil
end

local function findDriveWindow(station)
    if not station then return nil end
    for _, c in ipairs(station:GetChildren()) do
        if c:IsA("BasePart") and c.Name:lower():find("window") then
            return c
        end
    end
    return nil
end

function DriveMod.sweep()
    local station = findDriveStation()
    if not station then return 0 end
    local n = 0
    local reg = findDriveRegister(station)
    if reg then
        if DriveMod.teleport then teleportTo(reg.Position) end
        safe(function()
            R.Interact:FireServer(reg, "Primary", reg.Position)
        end)
        n += 1
    end
    local win = findDriveWindow(station)
    if win and LP:GetAttribute("Holding") ~= nil then
        if DriveMod.teleport then teleportTo(win.Position) end
        safe(function()
            R.Interact:FireServer(win, "Primary", win.Position)
        end)
        n += 1
    end
    return n
end

-- ============================================================
-- MODULE: FARM (open + order probe remotes)
-- ============================================================
local FarmMod = { interval = 0.5, orderRemotes = nil }

local function getOrderRemotes()
    if FarmMod.orderRemotes then return FarmMod.orderRemotes end
    FarmMod.orderRemotes = discoverRemotes(function(r)
        local n = r.Name:lower()
        return n:find("order") or n:find("serve") or n:find("submit")
    end)
    return FarmMod.orderRemotes
end

function FarmMod.fireOrders()
    local fired = 0
    for _, remote in ipairs(getOrderRemotes()) do
        safe(function()
            if remote:IsA("RemoteEvent") then
                remote:FireServer()
                fired += 1
            elseif remote:IsA("RemoteFunction") then
                remote:InvokeServer("Submit", {
                    Items = {}, Kind = "TakeOut", Builds = {},
                })
                fired += 1
            end
        end)
    end
    return fired
end

-- ============================================================
-- ORDERS WATCHER
-- ============================================================
local OrdersWatch = { seen = {}, state = "idle" }

if Orders then
    conn(Orders.ChildAdded, function(child)
        OrdersWatch.seen[child] = true
    end)
    for _, c in ipairs(Orders:GetChildren()) do
        OrdersWatch.seen[c] = true
    end
end

-- ============================================================
-- WORKERS
-- ============================================================
task.spawn(function()
    while true do
        if API.enabled.litter then
            local did = LitterMod.sweep()
            LitterMod.fails = did and 0 or (LitterMod.fails + 1)
            task.wait(LitterMod.fails >= LitterMod.failBudget
                and LitterMod.interval * 4 or LitterMod.interval)
        else
            task.wait(0.3)
        end
    end
end)

task.spawn(function()
    while true do
        if API.enabled.register then
            RegisterMod.sweep()
        end
        task.wait(RegisterMod.interval)
    end
end)

task.spawn(function()
    while true do
        if API.enabled.cook then
            CookMod.sweep()
        end
        task.wait(CookMod.interval)
    end
end)

task.spawn(function()
    while true do
        if API.enabled.assembly then
            AssemblyMod.sweep()
        end
        task.wait(AssemblyMod.interval)
    end
end)

task.spawn(function()
    while true do
        if API.enabled.drive then
            DriveMod.sweep()
        end
        task.wait(DriveMod.interval)
    end
end)

task.spawn(function()
    while true do
        if API.enabled.autoOpen then safe(SessionMod.open) end
        task.wait(3.0)
    end
end)

task.spawn(function()
    while true do
        if API.enabled.autoOrder then safe(FarmMod.fireOrders) end
        task.wait(FarmMod.interval)
    end
end)

-- ============================================================
-- WINDOW
-- ============================================================
Loader:SetStatus("Building GUI...", 0.7)
local Window = GousseUI:CreateWindow({
    Title = "Burger Planet",
    SubTitle = "v5.1 • full bench",
    Keybind = Enum.KeyCode.RightControl,
    Size = UDim2.new(0, 780, 0, 540),
    Scale = 1.0,
    ShowSettings = true,
    UnloadPrompt = {
        Title = "Konfirmasi Unload",
        Message = "Matikan seluruh fungsi dan tutup interface?",
    },
    OnUnload = function()
        for k in pairs(API.enabled) do API.enabled[k] = false end
        for _, c in ipairs(API.connections) do
            safe(function() c:Disconnect() end)
        end
    end,
})

local FarmTab    = Window:CreateTab({ Name = "Farm",     Icon = "zap" })
local CookTab    = Window:CreateTab({ Name = "Cook",     Icon = "chef-hat" })
local RegTab     = Window:CreateTab({ Name = "Register", Icon = "shopping-cart" })
local LitterTab  = Window:CreateTab({ Name = "Litter",   Icon = "trash-2" })
local DriveTab   = Window:CreateTab({ Name = "DriveThru",Icon = "car" })
local SessionTab = Window:CreateTab({ Name = "Session",  Icon = "radio" })
local ToolsTab   = Window:CreateTab({ Name = "Tools",    Icon = "wrench" })
local InfoTab    = Window:CreateTab({ Name = "Info",     Icon = "info" })

-- FARM TAB ----------------------------------------------------
FarmTab:CreateSection("Automation")
FarmTab:CreateToggle({
    Name = "Auto Open",
    SubTitle = "Session → Shift {Open=true} every 3s",
    Default = false,
    Callback = function(v) API.enabled.autoOpen = v end,
})
FarmTab:CreateToggle({
    Name = "Auto Order",
    SubTitle = "Fires discovered order remotes",
    Default = false,
    Callback = function(v) API.enabled.autoOrder = v end,
})
FarmTab:CreateSlider({
    Name = "Order Interval",
    Min = 0.1, Max = 3.0, Default = 0.5,
    Decimals = 2, Step = 0.1, Suffix = "s",
    Callback = function(v) FarmMod.interval = v end,
})
FarmTab:CreateButton({
    Name = "Snapshot State",
    SubTitle = "Reads every economy attribute",
    ButtonText = "Read",
    Variant = "primary",
    Callback = function()
        local s = snapshot()
        local lines = {}
        for k, v in pairs(s) do
            table.insert(lines, k .. " = " .. tostring(v))
        end
        GousseUI:Notify({
            Title = "State",
            Content = table.concat(lines, "\n"),
            Type = "info", Duration = 8,
        })
    end,
})

-- COOK TAB ----------------------------------------------------
CookTab:CreateSection("Grill / Fryer / Warmer")
CookTab:CreateToggle({
    Name = "Auto Cook",
    SubTitle = "Click all empty grill slots, fryer baskets, warmer bays",
    Default = false,
    Callback = function(v) API.enabled.cook = v end,
})
CookTab:CreateToggle({
    Name = "Grill",
    Default = true,
    Callback = function(v) CookMod.grill = v end,
})
CookTab:CreateToggle({
    Name = "Fryer",
    Default = true,
    Callback = function(v) CookMod.fryer = v end,
})
CookTab:CreateToggle({
    Name = "Warmer",
    Default = true,
    Callback = function(v) CookMod.warmer = v end,
})
CookTab:CreateToggle({
    Name = "Teleport to station",
    Default = true,
    Callback = function(v) CookMod.teleport = v end,
})
CookTab:CreateSlider({
    Name = "Cook Interval",
    Min = 0.1, Max = 2.0, Default = 0.4,
    Decimals = 2, Step = 0.05, Suffix = "s",
    Callback = function(v) CookMod.interval = v end,
})

CookTab:CreateSection("Assembly")
CookTab:CreateToggle({
    Name = "Auto Assembly",
    SubTitle = "Fire Interact on Island zones / order monitors",
    Default = false,
    Callback = function(v) API.enabled.assembly = v end,
})
CookTab:CreateButton({
    Name = "Cook Stats",
    ButtonText = "Stats",
    Variant = "secondary",
    Callback = function()
        GousseUI:Notify({
            Title = "Cook",
            Content = string.format(
                "grill=%d fryer=%d warmer=%d",
                CookMod.stats.grill, CookMod.stats.fryer, CookMod.stats.warmer),
            Type = "info", Duration = 5,
        })
    end,
})

-- REGISTER TAB ------------------------------------------------
RegTab:CreateSection("Auto Register + Handoff")
RegTab:CreateToggle({
    Name = "Auto Register",
    SubTitle = "Clicks waiting registers + submits the order",
    Default = false,
    Callback = function(v) API.enabled.register = v end,
})
RegTab:CreateToggle({
    Name = "Auto Handoff",
    SubTitle = "Ready orders → walk to customer",
    Default = true,
    Callback = function(v) RegisterMod.handoff = v end,
})
RegTab:CreateToggle({
    Name = "Teleport to register/customer",
    Default = true,
    Callback = function(v) RegisterMod.teleport = v end,
})
RegTab:CreateDropdown({
    Name = "Order Kind",
    SubTitle = "auto / TakeOut / DineIn / Drive",
    Options = { "auto", "TakeOut", "DineIn", "Drive" },
    Default = "auto",
    Callback = function(choice) RegisterMod.autoKind = choice end,
})
RegTab:CreateSlider({
    Name = "Register Interval",
    Min = 0.2, Max = 3.0, Default = 0.6,
    Decimals = 2, Step = 0.1, Suffix = "s",
    Callback = function(v) RegisterMod.interval = v end,
})
RegTab:CreateButton({
    Name = "Register Status",
    ButtonText = "Check",
    Variant = "secondary",
    Callback = function()
        local s = RegisterMod.status()
        GousseUI:Notify({
            Title = "Register",
            Content = string.format(
                "enabled=%s\npending=%d\nready=%d\nsubmitted=%d",
                tostring(s.enabled), s.pending, s.ready, s.submitted),
            Type = "info", Duration = 5,
        })
    end,
})
RegTab:CreateButton({
    Name = "Sweep Once",
    ButtonText = "Sweep",
    Variant = "primary",
    Callback = function() RegisterMod.sweep() end,
})

-- LITTER TAB --------------------------------------------------
LitterTab:CreateSection("Auto Litter Cycle")
LitterTab:CreateToggle({
    Name = "Auto Litter",
    SubTitle = "Pick → bin → dumpster overflow",
    Default = false,
    Callback = function(v) API.enabled.litter = v end,
})
LitterTab:CreateToggle({
    Name = "Teleport to targets",
    Default = true,
    Callback = function(v) LitterMod.teleport = v end,
})
LitterTab:CreateSlider({
    Name = "Litter Range",
    Min = 10, Max = 200, Default = 80,
    Decimals = 0, Step = 10, Suffix = " studs",
    Callback = function(v) LitterMod.range = v end,
})
LitterTab:CreateSlider({
    Name = "Sweep Interval",
    Min = 0.1, Max = 2.0, Default = 0.35,
    Decimals = 2, Step = 0.05, Suffix = "s",
    Callback = function(v) LitterMod.interval = v end,
})
LitterTab:CreateButton({
    Name = "Litter Status",
    ButtonText = "Check",
    Variant = "secondary",
    Callback = function()
        local s = LitterMod.status()
        GousseUI:Notify({
            Title = "Litter",
            Content = string.format(
                "state=%s\nholding=%s\nfails=%d\ncans=%d (full %d)\ndumpsters=%d",
                s.state, s.holding == "" and "-" or s.holding,
                s.fails, s.cans, s.fullCans, s.dumpsters),
            Type = "info", Duration = 6,
        })
    end,
})
LitterTab:CreateButton({
    Name = "Sweep Once",
    ButtonText = "Sweep",
    Variant = "primary",
    Callback = function() LitterMod.sweep() end,
})

-- DRIVE TAB ---------------------------------------------------
DriveTab:CreateSection("Drive-Thru")
DriveTab:CreateToggle({
    Name = "Auto Drive",
    SubTitle = "Register3 + WindowHit",
    Default = false,
    Callback = function(v) API.enabled.drive = v end,
})
DriveTab:CreateToggle({
    Name = "Teleport",
    Default = true,
    Callback = function(v) DriveMod.teleport = v end,
})
DriveTab:CreateSlider({
    Name = "Interval",
    Min = 0.2, Max = 3.0, Default = 0.5,
    Decimals = 2, Step = 0.1, Suffix = "s",
    Callback = function(v) DriveMod.interval = v end,
})
DriveTab:CreateButton({
    Name = "Sweep Once",
    ButtonText = "Sweep",
    Variant = "primary",
    Callback = function() DriveMod.sweep() end,
})

-- SESSION TAB -------------------------------------------------
SessionTab:CreateSection("Restaurant Control")
SessionTab:CreateButton({
    Name = "Open Restaurant",
    SubTitle = "Session → Shift {Open=true}",
    ButtonText = "Open",
    Variant = "primary",
    Callback = function()
        local ok = SessionMod.open()
        GousseUI:Notify({
            Title = "Session",
            Content = ok and "Open fired" or "Rejected (not Prep / not host)",
            Type = ok and "success" or "warning", Duration = 3,
        })
    end,
})
SessionTab:CreateButton({
    Name = "Get Info",
    ButtonText = "Info",
    Variant = "secondary",
    Callback = function()
        local i = SessionMod.info()
        if not i then
            GousseUI:Notify({ Title = "Session",
                Content = "Info returned nothing",
                Type = "warning", Duration = 3 })
            return
        end
        local lines = {}
        for k, v in pairs(i) do
            if type(v) ~= "table" then
                table.insert(lines, k .. " = " .. tostring(v))
            end
        end
        GousseUI:Notify({ Title = "Session Info",
            Content = table.concat(lines, "\n"),
            Type = "info", Duration = 8 })
    end,
})
SessionTab:CreateSection("Jobs (Lobby)")
local jobInput = SessionTab:CreateInput({
    Name = "Job ID",
    SubTitle = "Front / Kitchen / DriveThru / Driver / Manager",
    Placeholder = "Front",
    Callback = function(text) end,
})
SessionTab:CreateButton({
    Name = "Take Job",
    ButtonText = "Take",
    Variant = "primary",
    Callback = function()
        local job = jobInput.Get()
        local ok = SessionMod.takeJob(job)
        GousseUI:Notify({ Title = "Job",
            Content = ok and ("Took " .. job) or "Rejected",
            Type = ok and "success" or "warning", Duration = 3 })
    end,
})

-- TOOLS TAB ---------------------------------------------------
ToolsTab:CreateSection("Interaction")
ToolsTab:CreateButton({
    Name = "Fire All Order Remotes",
    ButtonText = "Fire",
    Variant = "primary",
    Callback = function()
        local n = FarmMod.fireOrders()
        GousseUI:Notify({ Title = "Orders",
            Content = "Fired " .. n .. " remotes",
            Type = n > 0 and "success" or "warning", Duration = 3 })
    end,
})
ToolsTab:CreateButton({
    Name = "Fire Notify Test",
    ButtonText = "Notify",
    Variant = "secondary",
    Callback = function()
        if R.Notify and R.Notify:IsA("RemoteEvent") then
            safe(function() R.Notify:FireServer("ollie was here") end)
        end
    end,
})
ToolsTab:CreateSection("Teleport")
local tpCoords = ToolsTab:CreateInput({
    Name = "Coords", SubTitle = "x,y,z",
    Placeholder = "0,50,0",
    Callback = function(text) end,
})
ToolsTab:CreateButton({
    Name = "Teleport",
    ButtonText = "Go",
    Variant = "primary",
    Callback = function()
        local raw = tpCoords.Get()
        local x, y, z = raw:match("([%-%d%.]+)%s*,%s*([%-%d%.]+)%s*,%s*([%-%d%.]+)")
        local r = root()
        if x and y and z and r then
            safe(function()
                r.CFrame = CFrame.new(tonumber(x), tonumber(y), tonumber(z))
            end)
            GousseUI:Notify({ Title = "TP",
                Content = "Moved to " .. raw,
                Type = "success", Duration = 2 })
        else
            GousseUI:Notify({ Title = "TP",
                Content = "Bad coords or no character",
                Type = "warning", Duration = 2 })
        end
    end,
})
ToolsTab:CreateSection("Discover")
ToolsTab:CreateButton({
    Name = "List Interact Nodes",
    ButtonText = "List",
    Variant = "secondary",
    Callback = function()
        local nodes = allInteractNodes()
        local lines = {}
        for i, n in ipairs(nodes) do
            if i > 40 then break end
            table.insert(lines,
                n:GetAttribute("Interact") .. " → " .. n:GetFullName())
        end
        GousseUI:Notify({ Title = "Nodes (" .. #nodes .. ")",
            Content = table.concat(lines, "\n"),
            Type = "info", Duration = 10 })
    end,
})
ToolsTab:CreateButton({
    Name = "Dump Remotes",
    ButtonText = "Dump",
    Variant = "secondary",
    Callback = function()
        local lines = {}
        local function walk(node, depth)
            if depth > 3 then return end
            for _, child in ipairs(node:GetChildren()) do
                local prefix = string.rep("  ", depth)
                table.insert(lines,
                    prefix .. child.Name .. " (" .. child.ClassName .. ")")
                if child:IsA("Folder") then walk(child, depth + 1) end
            end
        end
        walk(Remotes, 0)
        GousseUI:Notify({ Title = "Remotes",
            Content = table.concat(lines, "\n"),
            Type = "info", Duration = 12 })
    end,
})

-- INFO TAB ----------------------------------------------------
InfoTab:CreateParagraph({
    Title = "Build",
    Content = "v5.1 — full bench.\n" ..
              "Session / Litter / Register / Handoff / Farm / Cook /\n" ..
              "Assembly / DriveThru / Tools in one.\n" ..
              "Soft executor probe — no getreg gate.",
})
InfoTab:CreateButton({
    Name = "Refresh",
    ButtonText = "Refresh",
    Variant = "primary",
    Callback = function()
        local s = snapshot()
        local lines = {
            "Money      : " .. tostring(s.Money),
            "Level      : " .. tostring(s.Level)
                .. "  (" .. tostring(s.XP) .. "/" .. tostring(s.XPNext) .. " XP)",
            "Day        : " .. tostring(s.Day) .. "  ·  Clock " .. tostring(s.Clock),
            "Phase      : " .. tostring(s.Phase) .. "  ·  Shift " .. tostring(s.Shift),
            "GameMode   : " .. tostring(s.GameMode) .. "  ·  Site " .. tostring(s.Site),
            "Rating     : " .. tostring(s.Rating)
                .. "  (" .. tostring(s.RatingCount) .. " reviews)",
            "Lanes      : Front=" .. tostring(s.FrontOpen)
                .. " Drive=" .. tostring(s.DriveOpen),
            "Orders     : " .. tostring(#Orders:GetChildren()),
        }
        GousseUI:Notify({ Title = "Live State",
            Content = table.concat(lines, "\n"),
            Type = "info", Duration = 8 })
    end,
})

-- READY -------------------------------------------------------
Loader:SetStatus("Ready", 1.0)
Loader:Finish(function()
    GousseUI:Notify({
        Title = "Burger Planet v5.1",
        Content = "Full bench loaded. Cook + Register + Drive are the new rails.",
        Type = "success", Duration = 5,
    })
end)

print("[Burger Planet v5.1] loaded")
print("  executor :", execName, execVer)
print("  Session  :", tostring(R.Session))
print("  POS      :", tostring(R.POS))
print("  Cook     :", tostring(CookMod ~= nil))
print("  Orders   :", #Orders:GetChildren())
print("  Items    :", WItems and #WItems:GetChildren() or 0)
print("  NPCs     :", WNPCs and #WNPCs:GetChildren() or 0)

_G.BP = {
    Litter   = LitterMod,
    Register = RegisterMod,
    Cook     = CookMod,
    Assembly = AssemblyMod,
    Drive    = DriveMod,
    Farm     = FarmMod,
    Session  = SessionMod,
    State    = API,
}