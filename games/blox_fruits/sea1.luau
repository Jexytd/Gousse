--[[
    ========================================================================
    Gousse Script Hub - Blox Fruits: First Sea (World 1)
    Universe ID: 994732206 | Place ID: 2753915549
    Specialized leveling, boss hunting (Shanks/Saber), and Sea 2 unlock suite.
    Desktop Utility Edition powered by GousseUI & Lucide Icons.
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

-- Window Instance
local Window = GousseUI:CreateWindow({
    Title = "Gousse Hub",
    SubTitle = "Blox Fruits • First Sea (World 1)",
    Keybind = Enum.KeyCode.RightControl
})

-- ============================================================================
-- TAB 1: STARTER FARM (Lucide Icon: "swords")
-- ============================================================================
local FarmTab = Window:CreateTab({ Name = "Starter Farm", Icon = "swords" })

FarmTab:CreateSection("World 1 Level Progression")

FarmTab:CreateToggle({
    Name = "Auto Farm First Sea Quests",
    SubTitle = "Farm lowest to highest level mobs in World 1 automatically",
    Default = false,
    Callback = function(val)
        GousseUI:Notify({ Title = "World 1 Farm", Content = val and "Sea 1 leveling active." or "Halted.", Type = val and "success" or "info" })
    end
})

FarmTab:CreateToggle({
    Name = "Auto Saber Boss (Shanks)",
    SubTitle = "Auto-solve Jungle puzzle buttons and farm Saber Expert boss",
    Default = false,
    Callback = function(val)
        GousseUI:Notify({ Title = "Saber Quest", Content = val and "Saber puzzle solver running." or "Disabled.", Type = "info" })
    end
})

FarmTab:CreateSlider({
    Name = "Attack Range",
    Min = 10,
    Max = 50,
    Default = 20,
    Suffix = " studs",
    Callback = function(val) end
})

-- ============================================================================
-- TAB 2: SEA 1 TRAVEL (Lucide Icon: "compass")
-- ============================================================================
local TravelTab = Window:CreateTab({ Name = "Sea 1 Travel", Icon = "compass" })

TravelTab:CreateSection("First Sea Islands")

local sea1Selected = "Pirate Starter"
TravelTab:CreateDropdown({
    Name = "Destination Island",
    Options = { "Pirate Starter", "Marine Starter", "Jungle", "Pirate Village", "Desert", "Frozen Village", "Marine Fortress", "Skylands", "Prison", "Colosseum", "Magma Village", "Underwater City", "Fountain City" },
    Default = "Pirate Starter",
    Callback = function(opt)
        sea1Selected = opt
    end
})

TravelTab:CreateButton({
    Name = "Teleport to Island",
    SubTitle = "Safe tween across first sea coordinates",
    ButtonText = "Travel",
    Variant = "primary",
    Callback = function()
        GousseUI:Notify({ Title = "First Sea Travel", Content = "Traveling to " .. sea1Selected .. "...", Type = "info" })
    end
})

TravelTab:CreateToggle({
    Name = "Bypass Sea Hazard Water",
    SubTitle = "Walk on ocean water surface without fruit damage",
    Default = true,
    Callback = function(val) end
})

-- ============================================================================
-- TAB 3: COLLECTIBLES (Lucide Icon: "eye")
-- ============================================================================
local CollectTab = Window:CreateTab({ Name = "Collectibles", Icon = "eye" })

CollectTab:CreateSection("World 1 Chests & Spawns")

CollectTab:CreateToggle({
    Name = "Auto Collect Sea 1 Chests",
    SubTitle = "Fast tween route collecting silver and gold chests",
    Default = false,
    Callback = function(val) end
})

CollectTab:CreateToggle({
    Name = "Fruit Spawn Alert",
    SubTitle = "Display notifications when Devil Fruits spawn in Sea 1 servers",
    Default = true,
    Callback = function(val) end
})

-- ============================================================================
-- TAB 4: SEA 2 UNLOCK (Lucide Icon: "settings")
-- ============================================================================
local UnlockTab = Window:CreateTab({ Name = "Sea 2 Unlock", Icon = "settings" })

UnlockTab:CreateSection("Second Sea Transition")
UnlockTab:CreateParagraph({
    Title = "Second Sea Requirements",
    Content = "1. Level 700 or higher\n2. Talk to Military Detective at Prison\n3. Defeat Ice Admiral in Frozen Village\n4. Travel to Middle Town Captain."
})

UnlockTab:CreateButton({
    Name = "Start Prison Key & Ice Admiral Quest",
    SubTitle = "Automate Second Sea access prerequisite steps",
    ButtonText = "Start Quest",
    Variant = "primary",
    Callback = function()
        GousseUI:Notify({ Title = "Unlock Progress", Content = "Checking level and prerequisite quest flags...", Type = "info" })
    end
})

print("[Gousse Hub] Blox Fruits First Sea (World 1) Script Initialized.")

return {
    Window = Window,
    World = "First Sea"
}
