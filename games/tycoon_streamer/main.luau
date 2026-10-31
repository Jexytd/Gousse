--[[
    Gousse Hub - Tycoon Streamer
    Universe ID: 10765145358 (Place ID: 110838858426924)
]]

--[[
    ========================================================================
    Streamer Tycoon Trainer - GousseUI Edition
    Powered by GousseUI & Lucide Icons
    ========================================================================
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
        local ghRes = game:HttpGet("https://raw.githubusercontent.com/Jexytd/Gousse/main/library.luau")
        GousseUI = loadstring(ghRes)()
    end
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- Game Modules
local Networking = require(ReplicatedStorage.Modules.Networking)
local ManualIncomeController = require(ReplicatedStorage.Controllers.ManualIncomeController)
local MinigameController = require(ReplicatedStorage.Controllers.MinigameController)

local eVars = {
    AUTO_Buy = false,
    BuyDelay = 0.1,
    
    AUTO_Click = false,
    ClickDelay = 0.1,
    Click_S1 = true,
    Click_S2 = true,
    Click_S3 = true,
    Click_S4 = true,
    Click_S5 = true,
    Click_S6 = true,
    
    AUTO_Upgrade = false,
    UpgradeDelay = 0.1,
    Upgrade_S1 = true,
    Upgrade_S2 = true,
    Upgrade_S3 = true,
    Upgrade_S4 = true,
    Upgrade_S5 = true,
    Upgrade_S6 = true,
    StackMode = "1",
    
    AutoFinishDrone = false,
    AutoFinishRhythm = false,
    
    AUTO_Rebirth = false,
    RebirthDelay = 1.0,
}

-- =========================================================
-- AUTO BUY
-- =========================================================

local clientButtons = {}
local buttonLookup = {}
local buyWorkerRunning = false
local clientPlot

for _, plot in ipairs(workspace.Map:GetChildren()) do
    if plot:GetAttribute("TycoonPlotOwnerUserId") == LocalPlayer.UserId then
        clientPlot = plot
        break
    end
end

if clientPlot then
    local Buttons = clientPlot.Runtime.Buttons
    local function addButton(button)
        if not button or buttonLookup[button] then return end
        buttonLookup[button] = true
        table.insert(clientButtons, button)
    end
    local function removeButton(button)
        buttonLookup[button] = nil
        for i = #clientButtons, 1, -1 do
            if clientButtons[i] == button then
                table.remove(clientButtons, i)
                break
            end
        end
    end
    for _, button in ipairs(Buttons:GetChildren()) do addButton(button) end
    Buttons.ChildAdded:Connect(addButton)
    Buttons.ChildRemoved:Connect(removeButton)
end

local function fireButton(button)
    if not button or not button.Parent then return end
    local Base = button:FindFirstChild("Base")
    if not Base then return end
    local touchInterest = Base:FindFirstChildWhichIsA("TouchTransmitter")
    if not touchInterest then return end
    local Character = LocalPlayer.Character
    local HRP = Character and Character:FindFirstChild("HumanoidRootPart")
    if not HRP then return end
    firetouchinterest(Base, HRP, true)
    firetouchinterest(Base, HRP, false)
end

local function startAutoBuy()
    if buyWorkerRunning then return end
    buyWorkerRunning = true
    task.spawn(function()
        while eVars.AUTO_Buy do
            for _, button in ipairs(clientButtons) do
                if not eVars.AUTO_Buy then break end
                fireButton(button)
            end
            task.wait(math.max(eVars.BuyDelay, 0.1))
        end
        buyWorkerRunning = false
    end)
end

-- =========================================================
-- AUTO CLICK & UPGRADE
-- =========================================================

local clickWorkerRunning = false
local function startAutoClick()
    if clickWorkerRunning then return end
    clickWorkerRunning = true
    task.spawn(function()
        while eVars.AUTO_Click do
            local targets = {}
            if eVars.Click_S1 then table.insert(targets, "Source_001") end
            if eVars.Click_S2 then table.insert(targets, "Source_002") end
            if eVars.Click_S3 then table.insert(targets, "Source_003") end
            if eVars.Click_S4 then table.insert(targets, "Source_004") end
            if eVars.Click_S5 then table.insert(targets, "Source_005") end
            if eVars.Click_S6 then table.insert(targets, "Source_006") end
            
            for _, id in ipairs(targets) do
                if not ManualIncomeController:Get(id) then
                    ManualIncomeController:Request(id)
                end
            end
            task.wait(math.max(eVars.ClickDelay, 0.1))
        end
        clickWorkerRunning = false
    end)
end

local upgradeWorkerRunning = false
local function startAutoUpgrade()
    if upgradeWorkerRunning then return end
    upgradeWorkerRunning = true
    task.spawn(function()
        while eVars.AUTO_Upgrade do
            local targets = {}
            if eVars.Upgrade_S1 then table.insert(targets, "Source_001") end
            if eVars.Upgrade_S2 then table.insert(targets, "Source_002") end
            if eVars.Upgrade_S3 then table.insert(targets, "Source_003") end
            if eVars.Upgrade_S4 then table.insert(targets, "Source_004") end
            if eVars.Upgrade_S5 then table.insert(targets, "Source_005") end
            if eVars.Upgrade_S6 then table.insert(targets, "Source_006") end
            
            for _, id in ipairs(targets) do
                pcall(function()
                    Networking.SourceIncome.packets.Upgrade.send({
                        SourceIncomeId = id,
                        StackMode = eVars.StackMode
                    })
                end)
            end
            task.wait(math.max(eVars.UpgradeDelay, 0.1))
        end
        upgradeWorkerRunning = false
    end)
end

-- =========================================================
-- AUTO REBIRTH
-- =========================================================

local rebirthWorkerRunning = false
local function startAutoRebirth()
    if rebirthWorkerRunning then return end
    rebirthWorkerRunning = true
    task.spawn(function()
        while eVars.AUTO_Rebirth do
            pcall(function()
                Networking.Rebirth.packets.Request.send(nil)
            end)
            task.wait(math.max(eVars.RebirthDelay, 0.5))
        end
        rebirthWorkerRunning = false
    end)
end

-- =========================================================
-- MINIGAMES (Auto Finish)
-- =========================================================

local MinigameRemote = ReplicatedStorage:WaitForChild("MinigameRemotes"):WaitForChild("Request")

local oldGetDirection = MinigameController.GetDirection
MinigameController.GetDirection = function(self)
    if eVars.AutoFinishDrone and self.Session and self.Session.Definition.Driver == "FlightCourse" then
        local session = self.Session
        
        if session.NextGate <= #session.Definition.Checkpoints then
            local target = session.Definition.Checkpoints[session.NextGate]
            local dist = (target - session.Position).Magnitude
            
            if dist < 10 then
                target = target + Vector3.new(0, 0, -10)
            end
            
            local dir = target - session.Position
            if dir.Magnitude > 0 then
                return dir.Unit
            end
        else
            local target = session.Definition.Delivery
            local dir = target - session.Position
            if dir.Magnitude < 2 then
                if session.Position.Y > target.Y + 2 then
                    return Vector3.new(0, -1, 0)
                else
                    return Vector3.new(0, 0, 0)
                end
            else
                return dir.Unit
            end
        end
    end
    return oldGetDirection(self)
end

local hitNotes = {}
task.spawn(function()
    while true do
        local session = MinigameController.Session
        if eVars.AutoFinishRhythm and session and session.Definition.Driver == "StreamingRhythm" then
            local elapsed = workspace:GetServerTimeNow() - session.StartsAt
            if elapsed > 0 then
                for _, note in ipairs(session.Definition.Notes) do
                    if not hitNotes[note.Index] then
                        local diff = elapsed - note.Time
                        if diff >= -0.02 and diff <= 0.10 then
                            hitNotes[note.Index] = true
                            pcall(function()
                                MinigameRemote:FireServer("Input", {
                                    Token = session.Token,
                                    Lane = note.Lane
                                })
                            end)
                        end
                    end
                end
            end
        else
            hitNotes = {}
        end
        task.wait(0.01)
    end
end)

task.spawn(function()
    while true do
        MinigameController.Focused = true
        task.wait(1)
    end
end)

-- =========================================================
-- UI SETUP
-- =========================================================

local Window = GousseUI:CreateWindow({
    Title = "Streamer Tycoon",
    SubTitle = "Trainer • Gousse Edition",
    Keybind = Enum.KeyCode.RightControl
})

-- Tab 1: Auto Buy
local Tab1 = Window:CreateTab({ Name = "Auto Buy", Icon = "shopping-cart" })
Tab1:CreateSection("Toggle")
Tab1:CreateToggle({
    Name = "Enable Auto Buy",
    SubTitle = "Automatically touches all available buttons in your plot",
    Default = false,
    Callback = function(v) eVars.AUTO_Buy = v; if v then startAutoBuy() end end
})
Tab1:CreateSection("Configuration")
Tab1:CreateSlider({
    Name = "Buy Delay",
    Min = 0.1, Max = 2, Default = 0.1, Suffix = "s",
    Callback = function(v) eVars.BuyDelay = v end
})

-- Tab 2: Auto Click
local Tab2 = Window:CreateTab({ Name = "Auto Click", Icon = "mouse-pointer" })
Tab2:CreateToggle({
    Name = "Enable Auto Manual Click",
    SubTitle = "Fires manual income requests for selected desks",
    Default = false,
    Callback = function(v) eVars.AUTO_Click = v; if v then startAutoClick() end end
})
Tab2:CreateSlider({
    Name = "Click Delay",
    Min = 0.1, Max = 2, Default = 0.1, Suffix = "s",
    Callback = function(v) eVars.ClickDelay = v end
})
Tab2:CreateSection("Targets")
Tab2:CreateToggle({ Name = "Source_001 (Stream)", Default = true, Callback = function(v) eVars.Click_S1 = v end })
Tab2:CreateToggle({ Name = "Source_002 (Merch)", Default = true, Callback = function(v) eVars.Click_S2 = v end })
Tab2:CreateToggle({ Name = "Source_003 (Crypto)", Default = true, Callback = function(v) eVars.Click_S3 = v end })
Tab2:CreateToggle({ Name = "Source_004 (Course)", Default = true, Callback = function(v) eVars.Click_S4 = v end })
Tab2:CreateToggle({ Name = "Source_005 (Sponsor)", Default = true, Callback = function(v) eVars.Click_S5 = v end })
Tab2:CreateToggle({ Name = "Source_006 (Soda)", Default = true, Callback = function(v) eVars.Click_S6 = v end })

-- Tab 3: Auto Upgrade
local Tab3 = Window:CreateTab({ Name = "Auto Upgrade", Icon = "trending-up" })
Tab3:CreateToggle({
    Name = "Enable Auto Upgrade",
    SubTitle = "Fires upgrade packets for selected desks",
    Default = false,
    Callback = function(v) eVars.AUTO_Upgrade = v; if v then startAutoUpgrade() end end
})
Tab3:CreateSlider({
    Name = "Upgrade Delay",
    Min = 0.1, Max = 2, Default = 0.1, Suffix = "s",
    Callback = function(v) eVars.UpgradeDelay = v end
})
Tab3:CreateDropdown({
    Name = "Stack Mode",
    Options = { "1", "5", "25", "MAX" },
    Default = "1",
    Callback = function(v) eVars.StackMode = v end
})
Tab3:CreateSection("Targets")
Tab3:CreateToggle({ Name = "Source_001 (Stream)", Default = true, Callback = function(v) eVars.Upgrade_S1 = v end })
Tab3:CreateToggle({ Name = "Source_002 (Merch)", Default = true, Callback = function(v) eVars.Upgrade_S2 = v end })
Tab3:CreateToggle({ Name = "Source_003 (Crypto)", Default = true, Callback = function(v) eVars.Upgrade_S3 = v end })
Tab3:CreateToggle({ Name = "Source_004 (Course)", Default = true, Callback = function(v) eVars.Upgrade_S4 = v end })
Tab3:CreateToggle({ Name = "Source_005 (Sponsor)", Default = true, Callback = function(v) eVars.Upgrade_S5 = v end })
Tab3:CreateToggle({ Name = "Source_006 (Soda)", Default = true, Callback = function(v) eVars.Upgrade_S6 = v end })

-- Tab 4: Rebirth
local Tab4 = Window:CreateTab({ Name = "Rebirth", Icon = "refresh-cw" })
Tab4:CreateToggle({
    Name = "Enable Auto Rebirth",
    SubTitle = "Fires the rebirth request packet continuously",
    Default = false,
    Callback = function(v) eVars.AUTO_Rebirth = v; if v then startAutoRebirth() end end
})
Tab4:CreateSlider({
    Name = "Rebirth Delay",
    Min = 0.5, Max = 5, Default = 1.0, Suffix = "s",
    Callback = function(v) eVars.RebirthDelay = v end
})

-- Tab 5: Minigames
local Tab5 = Window:CreateTab({ Name = "Minigames", Icon = "play" })
Tab5:CreateSection("Auto Finish")
Tab5:CreateToggle({
    Name = "Auto Fly (Drone)",
    SubTitle = "Perfectly navigates all hoops and delivers the package",
    Default = false,
    Callback = function(v) eVars.AutoFinishDrone = v end
})
Tab5:CreateToggle({
    Name = "Auto Hit (Rhythm)",
    SubTitle = "Hits every note on time for a perfect score",
    Default = false,
    Callback = function(v) eVars.AutoFinishRhythm = v end
})

GousseUI:Notify({
    Title = "Streamer Tycoon",
    Content = "Trainer loaded successfully.",
    Type = "success",
    Duration = 3
})