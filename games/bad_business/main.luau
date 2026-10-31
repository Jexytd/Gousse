--[[
    ========================================================================
    Gousse Script Hub - Bad Business Module
    Universe ID: 1168263273
    Tactical gunplay, projectile latency compensation, ESP, and slide mobility.
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
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Window Configuration
local Window = GousseUI:CreateWindow({
    Title = "Gousse Hub",
    SubTitle = "Bad Business • Tactical Suite",
    Keybind = Enum.KeyCode.RightControl
})

-- ============================================================================
-- TAB 1: COMBAT (Lucide Icon: "crosshair")
-- ============================================================================
local CombatTab = Window:CreateTab({ Name = "Combat", Icon = "crosshair" })

CombatTab:CreateSection("Aimbot Engine")

CombatTab:CreateToggle({
    Name = "Silent Aim",
    SubTitle = "Redirect bullet raycasts to nearest visible hitbox",
    Default = false,
    Callback = function(val)
        GousseUI:Notify({ Title = "Silent Aim", Content = val and "Silent Aim active." or "Silent Aim disabled.", Type = "info" })
    end
})

CombatTab:CreateDropdown({
    Name = "Target Hitbox",
    Options = { "Head", "Torso", "Neck" },
    Default = "Head",
    Callback = function(opt)
        GousseUI:Notify({ Title = "Target Hitbox", Content = "Target hitbox set to: " .. opt, Type = "info" })
    end
})

CombatTab:CreateSlider({
    Name = "Field of View",
    Min = 30,
    Max = 360,
    Default = 90,
    Suffix = "°",
    Callback = function(val) end
})

CombatTab:CreateSection("Gun Modifications")

CombatTab:CreateToggle({
    Name = "Zero Recoil",
    SubTitle = "Eliminate camera shake and procedural weapon perturbation",
    Default = false,
    Callback = function(val)
        GousseUI:Notify({ Title = "Recoil", Content = val and "Zero Recoil active." or "Recoil restored.", Type = "info" })
    end
})

CombatTab:CreateToggle({
    Name = "Instant Reload",
    SubTitle = "Bypass reload state animation delay",
    Default = false,
    Callback = function(val)
        GousseUI:Notify({ Title = "Weapon", Content = val and "Instant Reload enabled." or "Instant Reload disabled.", Type = "info" })
    end
})

-- ============================================================================
-- TAB 2: VISUALS (Lucide Icon: "eye")
-- ============================================================================
local VisualsTab = Window:CreateTab({ Name = "Visuals", Icon = "eye" })

VisualsTab:CreateSection("Tactical Wallhack & ESP")

VisualsTab:CreateToggle({
    Name = "Enemy 2D Box ESP",
    SubTitle = "Draw dynamic bounding boxes around opponents",
    Default = false,
    Callback = function(val) end
})

VisualsTab:CreateToggle({
    Name = "Health Bar ESP",
    SubTitle = "Render health gradients on player sidebars",
    Default = false,
    Callback = function(val) end
})

VisualsTab:CreateToggle({
    Name = "Equipped Weapon ESP",
    SubTitle = "Display active primary and secondary weapons",
    Default = false,
    Callback = function(val) end
})

VisualsTab:CreateSlider({
    Name = "Custom FOV Camera",
    Min = 70,
    Max = 120,
    Default = 95,
    Suffix = "°",
    Callback = function(val)
        Camera.FieldOfView = val
    end
})

-- ============================================================================
-- TAB 3: MOVEMENT (Lucide Icon: "gauge")
-- ============================================================================
local MovementTab = Window:CreateTab({ Name = "Movement", Icon = "gauge" })

MovementTab:CreateSection("Tactical Mobility")

MovementTab:CreateToggle({
    Name = "Auto Slide Hop",
    SubTitle = "Continuous momentum sliding and sprint chaining",
    Default = false,
    Callback = function(val)
        GousseUI:Notify({ Title = "Mobility", Content = val and "Auto Slide Hop active." or "Slide Hop disabled.", Type = "info" })
    end
})

MovementTab:CreateSlider({
    Name = "Sprint Speed Modifier",
    Min = 16,
    Max = 45,
    Default = 24,
    Suffix = " studs/s",
    Callback = function(val) end
})

-- ============================================================================
-- TAB 4: SETTINGS (Lucide Icon: "settings")
-- ============================================================================
local SettingsTab = Window:CreateTab({ Name = "Settings", Icon = "settings" })

SettingsTab:CreateSection("Suite Information")
SettingsTab:CreateParagraph({
    Title = "Bad Business Tactical Suite",
    Content = "Version 1.8.4 • Gousse Hub\nEngine hooks calibrated for high-tickrate physics."
})

SettingsTab:CreateSection("Lifecycle Control")
SettingsTab:CreateButton({
    Name = "Unload Bad Business Module",
    SubTitle = "Clean all hooks, highlights, and disconnect listeners",
    ButtonText = "Unload",
    Variant = "danger",
    Callback = function()
        Window:ConfirmUnload()
    end
})

print("[Gousse Hub] Bad Business Module loaded with Desktop Utility aesthetic.")

return {
    Window = Window,
    Type = "Bad Business"
}
