--[[
    Ice Cream Sim — Trainer
    Remotes mapped from decompiled client (Events/*)
    Loader pattern: GousseUI (same as Streamer Tycoon ref)
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

local Players      = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local LocalPlayer  = Players.LocalPlayer

local Events = ReplicatedStorage:WaitForChild("Events")

-- income source ids pulled from ButtonsModule
local SOURCES = {
    { id = "Basic_Stand",   label = "Basic Stand"   },
    { id = "Frosty_Express",label = "Frosty Express"},
    { id = "Frosty_Depot",  label = "Frosty Depot"  },
    { id = "Moo_Farm",      label = "Moo Farm"      },
    { id = "Flavor_Lab",    label = "Flavor Lab"    },
    { id = "Factory",       label = "Factory"       },
    { id = "Theme_Park",    label = "Theme Park"    },
    { id = "City",          label = "City"          },
    { id = "Launch_Site",   label = "Launch Site"   },
    { id = "Space_Station", label = "Space HQ"      },
}

local eVars = {
    AUTO_Buy = false, BuyDelay = 0.1,
    AUTO_Click = false, ClickDelay = 0.1,
    ClickSel = {},
    AUTO_Upgrade = false, UpgradeDelay = 0.1,
    UpgradeSel = {},
    AUTO_Rebirth = false, RebirthDelay = 1.0,
    AUTO_Evolve = false, EvolveDelay = 1.0,
    AUTO_Phone = false, PhoneDelay = 0.5,
    StackTier = 0,
    RunTier = 0,
}

for _, s in ipairs(SOURCES) do
    eVars.ClickSel[s.id] = true
    eVars.UpgradeSel[s.id] = true
end

-- =========================================================
-- PLOT + TOUCH (Auto Buy)
-- =========================================================

local clientPlot
for _, plot in ipairs(workspace:WaitForChild("Game"):WaitForChild("Plots"):GetChildren()) do
    local ob = plot:FindFirstChild("OccupiedBy")
    if ob and ob.Value == LocalPlayer then clientPlot = plot break end
end

local touchParts, touchSeen = {}, {}
local function scanButtons(folder)
    if not folder then return end
    for _, btn in ipairs(folder:GetChildren()) do
        local touch = btn:FindFirstChild("Touch")
        if touch and not touchSeen[touch] then
            touchSeen[touch] = true
            table.insert(touchParts, touch)
        end
    end
end

if clientPlot then
    local builds = clientPlot:WaitForChild("Builds")
    for _, folder in ipairs(builds:GetChildren()) do
        if folder:IsA("Folder") then
            scanButtons(folder)
            folder.ChildAdded:Connect(function(c)
                if c:IsA("Folder") then scanButtons(c) end
            end)
        end
    end
    builds.ChildAdded:Connect(function(c)
        if c:IsA("Folder") then scanButtons(c) end
    end)
end

local function touch(part)
    if not part or not part.Parent then return end
    local c = LocalPlayer.Character
    local hrp = c and c:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    firetouchinterest(part, hrp, true)
    firetouchinterest(part, hrp, false)
end

-- =========================================================
-- WORKERS
-- =========================================================

local workers = {}

local function spawnWorker(name, fn)
    if workers[name] then return end
    workers[name] = true
    task.spawn(function()
        fn()
        workers[name] = nil
    end)
end

local function startBuy()
    spawnWorker("buy", function()
        while eVars.AUTO_Buy do
            for _, p in ipairs(touchParts) do
                if not eVars.AUTO_Buy then break end
                touch(p)
            end
            task.wait(math.max(eVars.BuyDelay, 0.05))
        end
    end)
end

local function startClick()
    spawnWorker("click", function()
        while eVars.AUTO_Click do
            for _, s in ipairs(SOURCES) do
                if not eVars.AUTO_Click then break end
                if eVars.ClickSel[s.id] then
                    pcall(function() Events.IncomeSource:FireServer(s.id) end)
                end
            end
            task.wait(math.max(eVars.ClickDelay, 0.05))
        end
    end)
end

local function startUpgrade()
    spawnWorker("upgrade", function()
        while eVars.AUTO_Upgrade do
            for _, s in ipairs(SOURCES) do
                if not eVars.AUTO_Upgrade then break end
                if eVars.UpgradeSel[s.id] then
                    pcall(function() Events.UpgradeIncome:FireServer(s.id) end)
                end
            end
            task.wait(math.max(eVars.UpgradeDelay, 0.05))
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

-- =========================================================
-- UI
-- =========================================================

local Window = GousseUI:CreateWindow({
    Title = "Ice Cream Sim",
    SubTitle = "Trainer • Bench Edition",
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

-- Tab: Auto Buy
local T1 = Window:CreateTab({ Name = "Auto Buy", Icon = "shopping-cart" })
T1:CreateToggle({
    Name = "Auto Buy",
    SubTitle = "Touches every Touch part in your plot",
    Default = false,
    Callback = function(v) eVars.AUTO_Buy = v; if v then startBuy() end end,
})
T1:CreateSlider({
    Name = "Buy Delay", Min = 0.05, Max = 2, Default = 0.1, Suffix = "s",
    Callback = function(v) eVars.BuyDelay = v end,
})

-- Tab: Auto Click
local T2 = Window:CreateTab({ Name = "Auto Click", Icon = "mouse-pointer" })
T2:CreateToggle({
    Name = "Auto Click",
    SubTitle = "Fires IncomeSource:FireServer for selected stands",
    Default = false,
    Callback = function(v) eVars.AUTO_Click = v; if v then startClick() end end,
})
T2:CreateSlider({
    Name = "Click Delay", Min = 0.05, Max = 2, Default = 0.1, Suffix = "s",
    Callback = function(v) eVars.ClickDelay = v end,
})
buildSourceTab(T2, eVars.ClickSel, "Click")

-- Tab: Auto Upgrade
local T3 = Window:CreateTab({ Name = "Auto Upgrade", Icon = "trending-up" })
T3:CreateToggle({
    Name = "Auto Upgrade",
    SubTitle = "Fires UpgradeIncome:FireServer for selected stands",
    Default = false,
    Callback = function(v) eVars.AUTO_Upgrade = v; if v then startUpgrade() end end,
})
T3:CreateSlider({
    Name = "Upgrade Delay", Min = 0.05, Max = 2, Default = 0.1, Suffix = "s",
    Callback = function(v) eVars.UpgradeDelay = v end,
})
buildSourceTab(T3, eVars.UpgradeSel, "Upgrade")

-- Tab: Stack Tier (client attribute, matches BottomButtons logic)
local T3b = Window:CreateTab({ Name = "Stack Tier", Icon = "layers" })
T3b:CreateSection("Equip Upgrade Tiers")
for _, up in ipairs({ "RunFaster", "StackUpgrade", "RemoteBuy", "FastCash", "x2Investors" }) do
    T3b:CreateButton({
        Name = "ChangeTier -> " .. up,
        Callback = function()
            pcall(function() Events.Upgrades:FireServer("ChangeTier", up) end)
        end,
    })
end

-- Tab: Rebirth / Evolve
local T4 = Window:CreateTab({ Name = "Reset Loops", Icon = "refresh-cw" })
T4:CreateToggle({
    Name = "Auto Rebirth",
    Default = false,
    Callback = function(v) eVars.AUTO_Rebirth = v; if v then startRebirth() end end,
})
T4:CreateSlider({
    Name = "Rebirth Delay", Min = 0.2, Max = 5, Default = 1.0, Suffix = "s",
    Callback = function(v) eVars.RebirthDelay = v end,
})
T4:CreateToggle({
    Name = "Auto Evolve",
    Default = false,
    Callback = function(v) eVars.AUTO_Evolve = v; if v then startEvolve() end end,
})
T4:CreateSlider({
    Name = "Evolve Delay", Min = 0.2, Max = 5, Default = 1.0, Suffix = "s",
    Callback = function(v) eVars.EvolveDelay = v end,
})

-- Tab: Phone
local T5 = Window:CreateTab({ Name = "Phone", Icon = "phone" })
T5:CreateToggle({
    Name = "Auto Accept Phone Deals",
    SubTitle = "Fires Phone:FireServer('Accept', 1) on loop",
    Default = false,
    Callback = function(v) eVars.AUTO_Phone = v; if v then startPhone() end end,
})
T5:CreateSlider({
    Name = "Phone Delay", Min = 0.2, Max = 3, Default = 0.5, Suffix = "s",
    Callback = function(v) eVars.PhoneDelay = v end,
})

GousseUI:Notify({
    Title = "Ice Cream Sim",
    Content = "Trainer loaded. Remote map live.",
    Type = "success",
    Duration = 3,
})