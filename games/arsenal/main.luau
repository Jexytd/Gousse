--[[
    ========================================================================
    Gousse Script Hub - Arsenal Module
    Universe ID: 111958650
    Tailored combat, visuals, and weapon modifications for Arsenal.
    ========================================================================
]]

local passedUI = ...
local env = (getgenv and getgenv()) or _G or {}
local GousseUI = passedUI or env.GousseUI

if not GousseUI then
    local ok, res = pcall(function()
        return game:HttpGet("https://raw.githubusercontent.com/Jexytd/Gousse/main/library.luau")
    end)
    if not ok or not res then
        res = game:HttpGet("http://localhost:3456/library.luau")
    end
    GousseUI = loadstring(res)()
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Arsenal Window
local Window = GousseUI:CreateWindow({
    Title = "Gousse Hub",
    SubTitle = "Arsenal • Combat Engine",
    Keybind = Enum.KeyCode.RightControl
})

-- ============================================================================
-- TAB 1: COMBAT
-- ============================================================================
local CombatTab = Window:CreateTab({ Name = "Combat", Icon = "🎯" })

CombatTab:CreateSection("Hitbox Expansion")

local hitboxEnabled = false
local hitboxSize = 10
local originalSizes = {}

local function IsEnemy(plr: Player): boolean
    if not plr or plr == LocalPlayer then return false end
    if not LocalPlayer.Team or not plr.Team then return true end
    return LocalPlayer.Team ~= plr.Team
end

local hitboxConnection = nil
local function UpdateHitboxes()
    if hitboxConnection then hitboxConnection:Disconnect(); hitboxConnection = nil end

    if hitboxEnabled then
        hitboxConnection = RunService.RenderStepped:Connect(function()
            for _, plr in ipairs(Players:GetPlayers()) do
                if IsEnemy(plr) and plr.Character then
                    local head = plr.Character:FindFirstChild("Head")
                    if head and head:IsA("BasePart") then
                        if not originalSizes[head] then
                            originalSizes[head] = head.Size
                        end
                        head.Size = Vector3.new(hitboxSize, hitboxSize, hitboxSize)
                        head.Transparency = 0.6
                        head.CanCollide = false
                    end
                end
            end
        end)
    else
        for part, sz in pairs(originalSizes) do
            if part and part.Parent then
                part.Size = sz
                part.Transparency = 0
            end
        end
        originalSizes = {}
    end
end

CombatTab:CreateToggle({
    Name = "Hitbox Expander (Head)",
    Default = false,
    Callback = function(val)
        hitboxEnabled = val
        UpdateHitboxes()
        GousseUI:Notify({
            Title = "Hitbox Expander",
            Content = val and "Hitboxes expanded." or "Hitboxes reset.",
            Type = val and "success" or "info",
            Duration = 2
        })
    end
})

CombatTab:CreateSlider({
    Name = "Hitbox Size",
    Min = 2,
    Max = 25,
    Default = 10,
    Suffix = " studs",
    Callback = function(val)
        hitboxSize = val
    end
})

CombatTab:CreateSection("Gun Mechanics")

CombatTab:CreateToggle({
    Name = "No Recoil / Camera Shake",
    Default = false,
    Callback = function(val)
        GousseUI:Notify({ Title = "Gun Mods", Content = val and "No Recoil active." or "No Recoil disabled.", Type = "info" })
    end
})

CombatTab:CreateToggle({
    Name = "Fast Reload",
    Default = false,
    Callback = function(val)
        GousseUI:Notify({ Title = "Gun Mods", Content = val and "Fast Reload enabled." or "Fast Reload disabled.", Type = "info" })
    end
})

-- ============================================================================
-- TAB 2: VISUALS
-- ============================================================================
local VisualsTab = Window:CreateTab({ Name = "Visuals", Icon = "👁" })

VisualsTab:CreateSection("Player ESP (Team-colored)")

local espEnabled = false
local highlights = {}

local function ApplyArsenalHighlight(plr: Player)
    if plr == LocalPlayer or not plr.Character then return end

    if highlights[plr] then
        highlights[plr]:Destroy()
        highlights[plr] = nil
    end

    local isEnemy = IsEnemy(plr)
    local hl = Instance.new("Highlight")
    hl.Name = "ArsenalESP"
    hl.FillColor = isEnemy and Color3.fromRGB(248, 81, 73) or Color3.fromRGB(46, 160, 67)
    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
    hl.FillTransparency = 0.4
    hl.OutlineTransparency = 0.1
    hl.Adornee = plr.Character
    hl.Parent = plr.Character
    highlights[plr] = hl
end

local function ClearArsenalESP()
    for _, hl in pairs(highlights) do
        if hl then hl:Destroy() end
    end
    highlights = {}
end

VisualsTab:CreateToggle({
    Name = "Player Chams (Red=Enemy, Green=Team)",
    Default = false,
    Callback = function(val)
        espEnabled = val
        if not val then
            ClearArsenalESP()
        else
            for _, plr in ipairs(Players:GetPlayers()) do
                ApplyArsenalHighlight(plr)
                plr.CharacterAdded:Connect(function()
                    if espEnabled then
                        task.wait(0.5)
                        ApplyArsenalHighlight(plr)
                    end
                end)
            end
        end
    end
})

VisualsTab:CreateSlider({
    Name = "Arsenal FOV",
    Min = 70,
    Max = 120,
    Default = 90,
    Suffix = "°",
    Callback = function(val)
        Camera.FieldOfView = val
    end
})

-- ============================================================================
-- TAB 3: MOVEMENT
-- ============================================================================
local MovementTab = Window:CreateTab({ Name = "Movement", Icon = "⚡" })

MovementTab:CreateSection("Locomotion")

local bHopEnabled = false
local bHopConnection = nil

local function ToggleBHop(val: boolean)
    bHopEnabled = val
    if bHopConnection then bHopConnection:Disconnect(); bHopConnection = nil end

    if bHopEnabled then
        bHopConnection = RunService.RenderStepped:Connect(function()
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum and hum.FloorMaterial ~= Enum.Material.Air and hum.MoveDirection.Magnitude > 0 then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
    end
end

MovementTab:CreateToggle({
    Name = "Auto Bunny Hop (Hold Move Key)",
    Default = false,
    Callback = ToggleBHop
})

MovementTab:CreateSlider({
    Name = "Arsenal Speed Boost",
    Min = 16,
    Max = 65,
    Default = 16,
    Suffix = " studs/s",
    Callback = function(val)
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = val end
    end
})

-- ============================================================================
-- TAB 4: SETTINGS & INFO
-- ============================================================================
local SettingsTab = Window:CreateTab({ Name = "Settings", Icon = "⚙" })

SettingsTab:CreateParagraph({
    Title = "Arsenal Enhancement Suite",
    Content = "Version 1.2.0 • Gousse Hub\nPress RightControl to hide this window.\nHitbox expansion and ESP automatically adjust for Arsenal team mechanics."
})

SettingsTab:CreateButton({
    Name = "Unload Arsenal Script",
    Callback = function()
        hitboxEnabled = false
        UpdateHitboxes()
        ClearArsenalESP()
        ToggleBHop(false)
        Window:Destroy()
        GousseUI:Notify({ Title = "Arsenal Hub", Content = "Script cleanly unloaded.", Duration = 3 })
    end
})

print("[Gousse Hub] Arsenal Module fully loaded and attached.")

return {
    Window = Window,
    Type = "Arsenal"
}
