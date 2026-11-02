--[[
    Ice Cream Sim — Trainer
    Auto Collect Money Bags included.
]]

local passedUI = ...
local env = (getgenv and getgenv()) or _G or {}
local GousseUI = passedUI or env.GousseUI

if not GousseUI then
    local okLocal, localRes = pcall(function()
        return game:HttpGet("http://localhost:3456/library.luau")
    end)
    if okLocal and localRes and not localRes:find("File Not Found") and not localRes:find("Cannot GET") then
        GousseUI = loadstring(localRes)()
    else
        GousseUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Jexytd/Gousse/main/library.luau"))()
    end
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local LocalPlayer = Players.LocalPlayer
local Events = ReplicatedStorage:WaitForChild("Events")

local ScoopDash
pcall(function()
    ScoopDash = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ScoopDash"))
end)

local SOURCES = {
    { id = "Basic_Stand",    label = "Basic Stand"    },
    { id = "Flavor_Lab",     label = "Flavor Lab"     },
    { id = "Frosty_Depot",   label = "Frosty Depot"   },
    { id = "Frosty_Express", label = "Frosty Express" },
    { id = "Hill_Expansion1",label = "Hill Expansion" },
    { id = "Launch_Site",    label = "Launch Site"    },
    { id = "Moo_Farm",       label = "Moo Farm"       },
    { id = "City",           label = "City"           },
    { id = "Space_Station",  label = "Space HQ"       },
}

local eVars = {
    AUTO_Buy = false, BuyDelay = 0.1,
    AUTO_Click = false, ClickDelay = 0.5,
    ClickSel = {},
    AUTO_Upgrade = false, UpgradeDelay = 0.5,
    UpgradeSel = {},
    AUTO_Rebirth = false, RebirthDelay = 1.0,
    AUTO_Evolve = false, EvolveDelay = 1.0,
    AUTO_Phone = false, PhoneDelay = 0.5,
    AUTO_MG_Start = false, MG_StartDelay = 0.5,
    AUTO_Serve = false,
    AUTO_CollectBags = false,
}

for _, s in ipairs(SOURCES) do
    eVars.ClickSel[s.id] = true
    eVars.UpgradeSel[s.id] = true
end

-- =========================================================
-- PLOT + TOUCH WALK
-- =========================================================

local clientPlot
for _, plot in ipairs(workspace:WaitForChild("Game"):WaitForChild("Plots"):GetChildren()) do
    local ob = plot:FindFirstChild("OccupiedBy")
    if ob and ob.Value == LocalPlayer then clientPlot = plot break end
end

local touchParts, touchSeen = {}, {}

local function addButton(btn)
    if not btn or not btn:IsDescendantOf(clientPlot) then return end
    local touch = btn:FindFirstChild("Touch")
    if not touch or not touch:IsA("BasePart") then return end
    
    if not touchSeen[touch] then
        touchSeen[touch] = true
        table.insert(touchParts, touch)
    end
end

local function removeButton(btn)
    if not btn then return end
    local touch = btn:FindFirstChild("Touch")
    if not touch or not touch:IsA("BasePart") then return end
    
    for i, v in ipairs(touchParts) do
        if v == touch then
            table.remove(touchParts, i)
            touchSeen[touch] = nil
            break
        end
    end
end

if clientPlot then
    for _, btn in ipairs(CollectionService:GetTagged("Button")) do
        addButton(btn)
    end
    CollectionService:GetInstanceAddedSignal("Button"):Connect(addButton)
    CollectionService:GetInstanceRemovedSignal("Button"):Connect(removeButton)
end

local function touch(part)
    if not part or not part.Parent then return end
    local c = LocalPlayer.Character
    local hrp = c and c:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    pcall(function()
        firetouchinterest(part, hrp, 0)
        task.wait()
        firetouchinterest(part, hrp, 1)
    end)
end

-- =========================================================
-- WORKERS
-- =========================================================

local workers = {}
local function spawnWorker(name, fn)
    if workers[name] then return end
    workers[name] = true
    task.spawn(function() fn() workers[name] = nil end)
end

local function startBuy()
    spawnWorker("buy", function()
        while eVars.AUTO_Buy do
            if #touchParts == 0 then
                task.wait(1)
            else
                for _, p in ipairs(touchParts) do
                    if not eVars.AUTO_Buy then break end
                    touch(p)
                end
                task.wait(math.max(eVars.BuyDelay, 0.05))
            end
        end
    end)
end

local function startCollectBags()
    spawnWorker("collect_bags", function()
        local vfx = workspace:FindFirstChild("VFX")
        local moneyBags = vfx and vfx:FindFirstChild("MoneyBags")
        
        while eVars.AUTO_CollectBags do
            if moneyBags then
                for _, bag in ipairs(moneyBags:GetChildren()) do
                    if not eVars.AUTO_CollectBags then break end
                    if bag:IsA("BasePart") then
                        touch(bag)
                    end
                end
            end
            task.wait(0.1)
        end
    end)
end

-- GC Hook for internal controllers
local function getControllers()
    local controllers = {}
    for _, v in pairs(getgc(true)) do
        if type(v) == "table" and rawget(v, "click") and rawget(v, "alive") ~= nil and rawget(v, "automated") ~= nil then
            table.insert(controllers, v)
        end
    end
    return controllers
end

local function startClick()
    spawnWorker("click", function()
        local controllers = getControllers()
        while eVars.AUTO_Click do
            if #controllers == 0 then
                controllers = getControllers()
            end
            for _, ctrl in ipairs(controllers) do
                if not eVars.AUTO_Click then break end
                if ctrl.alive and not ctrl.automated then
                    pcall(function() ctrl.click() end)
                end
            end
            task.wait(math.max(eVars.ClickDelay, 0.1))
        end
        controllers = {}
    end)
end

local function startUpgrade()
    spawnWorker("upgrade", function()
        while eVars.AUTO_Upgrade do
            local controllers = {}
            for _, v in pairs(getgc(true)) do
                if type(v) == "table" and rawget(v, "tryUpgrade") ~= nil then
                    local billboard = rawget(v, "billboard")
                    if billboard and billboard.Adornee and billboard.Adornee.Parent then
                        controllers[billboard.Adornee.Parent.Name] = v
                    end
                end
            end
            
            if next(controllers) ~= nil then
                for id, ctrl in pairs(controllers) do
                    if not eVars.AUTO_Upgrade then break end
                    if eVars.UpgradeSel[id] then
                        pcall(function() ctrl.tryUpgrade() end)
                    end
                end
            else
                for _, s in ipairs(SOURCES) do
                    if not eVars.AUTO_Upgrade then break end
                    if eVars.UpgradeSel[s.id] then
                        pcall(function() Events.UpgradeIncome:FireServer(s.id) end)
                        task.wait(0.15)
                    end
                end
            end
            task.wait(math.max(eVars.UpgradeDelay, 0.1))
        end
    end)
end

local function startRebirth()
    spawnWorker("rebirth", function()
        while eVars.AUTO_Rebirth do
            pcall(function() Events.Rebirth:FireServer("Rebirth") end)
            task.wait(math.max(eVars.RebirthDelay, 0.2))
        end
    end)
end

local function startEvolve()
    spawnWorker("evolve", function()
        while eVars.AUTO_Evolve do
            pcall(function() Events.Evolve:FireServer("Evolve") end)
            task.wait(math.max(eVars.EvolveDelay, 0.2))
        end
    end)
end

local function startPhone()
    spawnWorker("phone", function()
        while eVars.AUTO_Phone do
            pcall(function() Events.Phone:FireServer("Accept", 1) end)
            task.wait(math.max(eVars.PhoneDelay, 0.2))
        end
    end)
end

local function startMGStart()
    spawnWorker("mg_start", function()
        while eVars.AUTO_MG_Start do
            pcall(function() Events.Minigame:FireServer("Ice_Cream_Hut") end)
            task.wait(math.max(eVars.MG_StartDelay, 0.5))
        end
    end)
end

-- =========================================================
-- MINIGAME AUTO-SERVE
-- =========================================================

local function getSession()
    if not ScoopDash then return nil end
    local ok, addIngredient = pcall(debug.getupvalue, ScoopDash.AddIngredient, 1)
    if not ok or not addIngredient then return nil end
    local ok2, session = pcall(debug.getupvalue, addIngredient, 1)
    if not ok2 or not session then return nil end
    return session
end

local function clickGive()
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if playerGui then
        local giveGui = playerGui:FindFirstChild("ScoopDashGive")
        if giveGui and giveGui:FindFirstChild("Container") then
            local click = giveGui.Container:FindFirstChild("Click")
            if click and click:IsA("GuiButton") then
                if firesignal then
                    firesignal(click.MouseButton1Click)
                else
                    click:Activate()
                end
                return true
            end
        end
    end
    return false
end

local function startAutoServe()
    spawnWorker("autoserve", function()
        while eVars.AUTO_Serve do
            local session = getSession()
            if session and session.running then
                local cust = session.activeCustomer
                if cust and cust.arrived and not cust.served then
                    local order = cust.order
                    if order then
                        local orderScoops = order.scoops
                        local orderTops = order.toppings
                        
                        local function countsMatch(listA, listB)
                            if #listA ~= #listB then return false end
                            local counts = {}
                            for _, v in ipairs(listA) do counts[v] = (counts[v] or 0) + 1 end
                            for _, v in ipairs(listB) do
                                if not counts[v] or counts[v] <= 0 then return false end
                                counts[v] = counts[v] - 1
                            end
                            return true
                        end

                        if countsMatch(session.scoops, orderScoops) and countsMatch(session.tops, orderTops) then
                            if not clickGive() then
                                pcall(function() Events.Minigame:FireServer("Ice_Cream_Hut", "Serve") end)
                            end
                            task.wait(1)
                        else
                            local wrong = false
                            for _, v in ipairs(session.scoops) do
                                if not table.find(orderScoops, v) then wrong = true break end
                            end
                            if not wrong then
                                for _, v in ipairs(session.tops) do
                                    if not table.find(orderTops, v) then wrong = true break end
                                end
                            end
                            
                            if wrong or #session.scoops > #orderScoops or #session.tops > #orderTops then
                                pcall(function() ScoopDash.AddIngredient("Trash") end)
                                task.wait(0.2)
                            else
                                if not session.cone then
                                    pcall(function() ScoopDash.AddIngredient("Cones") end)
                                    task.wait(0.2)
                                else
                                    local added = false
                                    for i, v in ipairs(orderScoops) do
                                        local has = 0
                                        for _, s in ipairs(session.scoops) do
                                            if s == v then has = has + 1 end
                                        end
                                        local need = 0
                                        for j, s in ipairs(orderScoops) do
                                            if s == v then need = need + 1 end
                                        end
                                        if has < need then
                                            pcall(function() ScoopDash.AddIngredient(v) end)
                                            added = true
                                            task.wait(0.2)
                                            break
                                        end
                                    end
                                    if not added then
                                        for i, v in ipairs(orderTops) do
                                            local has = 0
                                            for _, t in ipairs(session.tops) do
                                                if t == v then has = has + 1 end
                                            end
                                            local need = 0
                                            for j, t in ipairs(orderTops) do
                                                if t == v then need = need + 1 end
                                            end
                                            if has < need then
                                                pcall(function() ScoopDash.AddIngredient(v) end)
                                                task.wait(0.2)
                                                break
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            else
                task.wait(0.5)
            end
            task.wait(0.1)
        end
    end)
end

-- =========================================================
-- UI
-- =========================================================

local Window = GousseUI:CreateWindow({
    Title = "Ice Cream Sim",
    SubTitle = "Trainer • UI Fire Auto-Serve",
    Keybind = Enum.KeyCode.RightControl,
})

local function buildSourceTab(tab, selTable, label)
    tab:CreateSection(label .. " Targets")
    for _, s in ipairs(SOURCES) do
        tab:CreateToggle({
            Name = s.label,
            Default = true,
            Callback = function(v) selTable[s.id] = v end,
        })
    end
end

local T1 = Window:CreateTab({ Name = "Auto Buy", Icon = "shopping-cart" })
T1:CreateToggle({
    Name = "Auto Buy", Default = false,
    Callback = function(v) eVars.AUTO_Buy = v; if v then startBuy() end end,
})
T1:CreateSlider({
    Name = "Buy Delay", Min = 0.05, Max = 2, Default = 0.1, Suffix = "s",
    Callback = function(v) eVars.BuyDelay = v end,
})
T1:CreateToggle({
    Name = "Auto Collect Money Bags", Default = false,
    Callback = function(v) eVars.AUTO_CollectBags = v; if v then startCollectBags() end end,
})

local T2 = Window:CreateTab({ Name = "Auto Click", Icon = "mouse-pointer" })
T2:CreateToggle({
    Name = "Auto Click (GC Hook)", Default = false,
    Callback = function(v) eVars.AUTO_Click = v; if v then startClick() end end,
})
T2:CreateSlider({
    Name = "Click Delay", Min = 0.1, Max = 5, Default = 0.5, Suffix = "s",
    Callback = function(v) eVars.ClickDelay = v end,
})
buildSourceTab(T2, eVars.ClickSel, "Click")

local T3 = Window:CreateTab({ Name = "Auto Upgrade", Icon = "trending-up" })
T3:CreateToggle({
    Name = "Auto Upgrade", Default = false,
    Callback = function(v) eVars.AUTO_Upgrade = v; if v then startUpgrade() end end,
})
T3:CreateSlider({
    Name = "Upgrade Delay", Min = 0.1, Max = 2, Default = 0.5, Suffix = "s",
    Callback = function(v) eVars.UpgradeDelay = v end,
})
buildSourceTab(T3, eVars.UpgradeSel, "Upgrade")

local T3b = Window:CreateTab({ Name = "Stack Tier", Icon = "layers" })
for _, up in ipairs({ "RunFaster", "StackUpgrade", "RemoteBuy", "FastCash", "x2Investors" }) do
    T3b:CreateButton({
        Name = "ChangeTier -> " .. up,
        Callback = function() pcall(function() Events.Upgrades:FireServer("ChangeTier", up) end) end,
    })
end

local T4 = Window:CreateTab({ Name = "Reset Loops", Icon = "refresh-cw" })
T4:CreateToggle({
    Name = "Auto Rebirth", Default = false,
    Callback = function(v) eVars.AUTO_Rebirth = v; if v then startRebirth() end end,
})
T4:CreateSlider({
    Name = "Rebirth Delay", Min = 0.2, Max = 5, Default = 1.0, Suffix = "s",
    Callback = function(v) eVars.RebirthDelay = v end,
})
T4:CreateToggle({
    Name = "Auto Evolve", Default = false,
    Callback = function(v) eVars.AUTO_Evolve = v; if v then startEvolve() end end,
})
T4:CreateSlider({
    Name = "Evolve Delay", Min = 0.2, Max = 5, Default = 1.0, Suffix = "s",
    Callback = function(v) eVars.EvolveDelay = v end,
})

local T5 = Window:CreateTab({ Name = "Minigame", Icon = "play" })
T5:CreateToggle({
    Name = "Auto Start Minigame", Default = false,
    Callback = function(v) eVars.AUTO_MG_Start = v; if v then startMGStart() end end,
})
T5:CreateSlider({
    Name = "Start Delay", Min = 0.5, Max = 5, Default = 0.5, Suffix = "s",
    Callback = function(v) eVars.MG_StartDelay = v end,
})
T5:CreateToggle({
    Name = "Auto Serve & Build", Default = false,
    Callback = function(v) eVars.AUTO_Serve = v; if v then startAutoServe() end end,
})

local T6 = Window:CreateTab({ Name = "Phone", Icon = "phone" })
T6:CreateToggle({
    Name = "Auto Accept Phone Deals", Default = false,
    Callback = function(v) eVars.AUTO_Phone = v; if v then startPhone() end end,
})
T6:CreateSlider({
    Name = "Phone Delay", Min = 0.2, Max = 3, Default = 0.5, Suffix = "s",
    Callback = function(v) eVars.PhoneDelay = v end,
})

GousseUI:Notify({
    Title = "Ice Cream Sim",
    Content = "Trainer loaded. Auto Collect added.",
    Type = "success",
    Duration = 3,
})