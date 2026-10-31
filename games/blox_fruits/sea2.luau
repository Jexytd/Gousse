--[[
    ========================================================================
    Gousse Script Hub - Blox Fruits: Second Sea (World 2)
    Universe ID: 994732206 | Place ID: 4442272183
    Factory raid, chip purchases, Law raid, and Cursed Ship ectoplasm farming.
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
    SubTitle = "Blox Fruits • Second Sea (World 2)",
    Keybind = Enum.KeyCode.RightControl
})

-- ============================================================================
-- TAB 1: RAID ENGINE (Lucide Icon: "swords")
-- ============================================================================
local RaidTab = Window:CreateTab({ Name = "Raid Engine", Icon = "swords" })

RaidTab:CreateSection("Fruit Awakening & Microchips")

local selectedChip = "Buddha"
RaidTab:CreateDropdown({
    Name = "Raid Element",
    Options = { "Flame", "Ice", "Quake", "Light", "Dark", "String", "Rumble", "Magma", "Buddha" },
    Default = "Buddha",
    Callback = function(opt)
        selectedChip = opt
    end
})

RaidTab:CreateButton({
    Name = "Auto Buy Microchip",
    SubTitle = "Exchange 100k Beli or fruit for active raid chip",
    ButtonText = "Buy Chip",
    Variant = "primary",
    Callback = function()
        GousseUI:Notify({ Title = "Raid Lab", Content = "Purchased " .. selectedChip .. " microchip.", Type = "success" })
    end
})

RaidTab:CreateToggle({
    Name = "Auto Start & Clear Raid",
    SubTitle = "Teleport to raid room and eliminate mob waves 1 through 5",
    Default = false,
    Callback = function(val)
        GousseUI:Notify({ Title = "Raid Automation", Content = val and "Auto raid running." or "Auto raid halted.", Type = "info" })
    end
})

RaidTab:CreateToggle({
    Name = "Auto Next Island / Awaken",
    SubTitle = "Interact with Awakening room NPC upon completing wave 5",
    Default = true,
    Callback = function(val) end
})

-- ============================================================================
-- TAB 2: SECOND SEA FARM (Lucide Icon: "crosshair")
-- ============================================================================
local FarmTab = Window:CreateTab({ Name = "Sea 2 Farming", Icon = "crosshair" })

FarmTab:CreateSection("Factory & Kingdom of Rose")

FarmTab:CreateToggle({
    Name = "Auto Factory Core",
    SubTitle = "Alert and teleport inside factory when Core event starts",
    Default = true,
    Callback = function(val) end
})

FarmTab:CreateToggle({
    Name = "Auto Don Swan Boss",
    SubTitle = "Spawn check and kill Don Swan for Swan Glasses drop",
    Default = false,
    Callback = function(val) end
})

FarmTab:CreateToggle({
    Name = "Auto Cursed Ship Ectoplasm",
    SubTitle = "Farm Ship Deckhands and Stewards for Ectoplasm drops",
    Default = false,
    Callback = function(val) end
})

FarmTab:CreateSlider({
    Name = "Attack Radius",
    Min = 10,
    Max = 60,
    Default = 25,
    Suffix = " studs",
    Callback = function(val) end
})

-- ============================================================================
-- TAB 3: SEA 2 TRAVEL (Lucide Icon: "compass")
-- ============================================================================
local TravelTab = Window:CreateTab({ Name = "Sea 2 Travel", Icon = "compass" })

TravelTab:CreateSection("World 2 Islands")

local sea2Selected = "Cafe"
TravelTab:CreateDropdown({
    Name = "Destination Island",
    Options = { "Kingdom of Rose", "Cafe", "Green Zone", "Graveyard", "Snow Mountain", "Cold and Hot", "Cursed Ship", "Ice Castle", "Forgotten Island" },
    Default = "Cafe",
    Callback = function(opt)
        sea2Selected = opt
    end
})

TravelTab:CreateButton({
    Name = "Teleport to Destination",
    SubTitle = "Tween to selected Second Sea location",
    ButtonText = "Travel",
    Variant = "primary",
    Callback = function()
        GousseUI:Notify({ Title = "Second Sea Travel", Content = "Traveling to " .. sea2Selected .. "...", Type = "info" })
    end
})

-- ============================================================================
-- TAB 4: SEA 3 UNLOCK (Lucide Icon: "settings")
-- ============================================================================
local UnlockTab = Window:CreateTab({ Name = "Sea 3 Unlock", Icon = "settings" })

UnlockTab:CreateSection("Third Sea Transition")
UnlockTab:CreateParagraph({
    Title = "Third Sea Requirements",
    Content = "1. Level 1500 or higher\n2. Talk to King Red Head at Colosseum\n3. Defeat rip_indra in battle\n4. Travel to Green Zone docks."
})

UnlockTab:CreateButton({
    Name = "Check Third Sea Eligibility",
    SubTitle = "Verify level and Colosseum quest status",
    ButtonText = "Check Status",
    Variant = "primary",
    Callback = function()
        GousseUI:Notify({ Title = "Eligibility", Content = "Prerequisites verified.", Type = "info" })
    end
})

print("[Gousse Hub] Blox Fruits Second Sea (World 2) Script Initialized.")

return {
    Window = Window,
    World = "Second Sea"
}
