--[[
    ========================================================================
    Gousse Script Hub - Blox Fruits Module
    Universe ID: 994732206
    Autonomous leveling, fruit tracking, combat, and world travel suite.
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

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Window Configuration
local Window = GousseUI:CreateWindow({
    Title = "Gousse Hub",
    SubTitle = "Blox Fruits • Auto Suite",
    Keybind = Enum.KeyCode.RightControl
})

-- ============================================================================
-- TAB 1: FARMING (Lucide Icon: "swords")
-- ============================================================================
local FarmTab = Window:CreateTab({ Name = "Farming", Icon = "swords" })

FarmTab:CreateSection("Quest & Level Automation")

local autoFarm = false
local fastAttack = false
local farmDistance = 25

FarmTab:CreateToggle({
    Name = "Auto Farm Level",
    SubTitle = "Accept optimal level quest and eliminate target mobs",
    Default = false,
    Callback = function(val)
        autoFarm = val
        GousseUI:Notify({
            Title = "Auto Farm",
            Content = val and "Auto Farm activated." or "Auto Farm halted.",
            Type = val and "success" or "info",
            Duration = 2
        })
    end
})

FarmTab:CreateToggle({
    Name = "Fast Attack",
    SubTitle = "Bypass weapon animation delay for rapid hits",
    Default = false,
    Callback = function(val)
        fastAttack = val
        GousseUI:Notify({ Title = "Fast Attack", Content = val and "Fast Attack enabled." or "Fast Attack disabled.", Type = "info" })
    end
})

FarmTab:CreateSlider({
    Name = "Attack Range",
    Min = 10,
    Max = 60,
    Default = 25,
    Suffix = " studs",
    Callback = function(val)
        farmDistance = val
    end
})

FarmTab:CreateSection("Mastery & Weapon Farming")

FarmTab:CreateToggle({
    Name = "Auto Fruit Mastery",
    SubTitle = "Switch to Devil Fruit abilities when target health is critical",
    Default = false,
    Callback = function(val)
        GousseUI:Notify({ Title = "Mastery", Content = val and "Fruit mastery prioritization active." or "Mastery disabled.", Type = "info" })
    end
})

FarmTab:CreateDropdown({
    Name = "Preferred Weapon",
    Options = { "Melee", "Sword", "Fruit", "Gun" },
    Default = "Melee",
    Callback = function(opt)
        GousseUI:Notify({ Title = "Weapon Config", Content = "Preferred weapon set to: " .. opt, Type = "info" })
    end
})

-- ============================================================================
-- TAB 2: COMBAT (Lucide Icon: "crosshair")
-- ============================================================================
local CombatTab = Window:CreateTab({ Name = "Combat", Icon = "crosshair" })

CombatTab:CreateSection("PVP & Target Aim")

CombatTab:CreateToggle({
    Name = "Silent Fruit Aim",
    SubTitle = "Predictive projectile trajectory for fruit skills",
    Default = false,
    Callback = function(val)
        GousseUI:Notify({ Title = "Combat", Content = val and "Silent Fruit Aim active." or "Silent Aim disabled.", Type = "info" })
    end
})

CombatTab:CreateToggle({
    Name = "Auto Observation Haki",
    SubTitle = "Re-enable Ken Haki whenever cooldown finishes",
    Default = true,
    Callback = function(val)
        -- Ken Haki maintainer
    end
})

CombatTab:CreateToggle({
    Name = "Auto Buso Haki",
    SubTitle = "Maintain Armament Haki continuously during combat",
    Default = true,
    Callback = function(val)
        -- Buso Haki maintainer
    end
})

CombatTab:CreateSlider({
    Name = "Aim FOV Radius",
    Min = 50,
    Max = 360,
    Default = 120,
    Suffix = "°",
    Callback = function(val) end
})

-- ============================================================================
-- TAB 3: TELEPORT (Lucide Icon: "compass")
-- ============================================================================
local TeleportTab = Window:CreateTab({ Name = "Teleport", Icon = "compass" })

TeleportTab:CreateSection("World Fast Travel")

local selectedIsland = "Jungle"
TeleportTab:CreateDropdown({
    Name = "Target Island",
    Options = { "Pirate Starter", "Marine Starter", "Jungle", "Pirate Village", "Desert", "Snow Mountain", "Marineford", "Sky Island" },
    Default = "Jungle",
    Callback = function(island)
        selectedIsland = island
    end
})

TeleportTab:CreateButton({
    Name = "Teleport to Island",
    SubTitle = "Safe tween character to selected island coordinates",
    ButtonText = "Teleport",
    Variant = "primary",
    Callback = function()
        GousseUI:Notify({
            Title = "Navigation",
            Content = "Tweening character to " .. selectedIsland .. "...",
            Type = "info",
            Duration = 3
        })
    end
})

TeleportTab:CreateToggle({
    Name = "Underground Safe Tween",
    SubTitle = "Travel 25 studs beneath water level to prevent anti-cheat kicks",
    Default = true,
    Callback = function(val) end
})

TeleportTab:CreateSlider({
    Name = "Tween Flight Speed",
    Min = 100,
    Max = 350,
    Default = 250,
    Suffix = " studs/s",
    Callback = function(val) end
})

-- ============================================================================
-- TAB 4: VISUALS (Lucide Icon: "eye")
-- ============================================================================
local VisualsTab = Window:CreateTab({ Name = "Visuals", Icon = "eye" })

VisualsTab:CreateSection("Fruit & Entity ESP")

VisualsTab:CreateToggle({
    Name = "Spawned Fruit ESP",
    SubTitle = "Render marker and distance badge over spawned fruits",
    Default = true,
    Callback = function(val)
        GousseUI:Notify({ Title = "ESP", Content = val and "Fruit ESP active." or "Fruit ESP disabled.", Type = "info" })
    end
})

VisualsTab:CreateToggle({
    Name = "Chest ESP",
    SubTitle = "Highlight silver, gold, and diamond chests in current sea",
    Default = false,
    Callback = function(val) end
})

VisualsTab:CreateToggle({
    Name = "Player ESP",
    SubTitle = "Display player level, crew, bounty, and distance",
    Default = false,
    Callback = function(val) end
})

-- ============================================================================
-- TAB 5: SETTINGS (Lucide Icon: "settings")
-- ============================================================================
local SettingsTab = Window:CreateTab({ Name = "Settings", Icon = "settings" })

SettingsTab:CreateSection("Suite Information")
SettingsTab:CreateParagraph({
    Title = "Blox Fruits Suite",
    Content = "Version 3.4.0 • Gousse Hub\nSupports World 1 (First Sea), World 2 (Second Sea), and World 3 (Third Sea)."
})

SettingsTab:CreateSection("Lifecycle Control")
SettingsTab:CreateButton({
    Name = "Unload Blox Fruits Module",
    SubTitle = "Stop all background loops and disconnect runtime hooks",
    ButtonText = "Unload",
    Variant = "danger",
    Callback = function()
        Window:ConfirmUnload()
    end
})

print("[Gousse Hub] Blox Fruits Module loaded with Desktop Utility aesthetic.")

return {
    Window = Window,
    Type = "Blox Fruits"
}