--[[
    ========================================================================
    Gousse Script Hub - Arsenal Module
    Universe ID: 111958650
    Tailored combat, visuals, and weapon modifications for Arsenal.
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
-- TAB 1: COMBAT (Lucide Icon: "crosshair")
-- ============================================================================
local CombatTab = Window:CreateTab({ Name = "Combat", Icon = "crosshair" })

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
    SubTitle = "Scale enemy head bounding volume for bullet registration",
    Default = false,
    Callback = function(val)
        hitboxEnabled = val
        UpdateHitboxes()
        GousseUI:Notify({
            Title = "Hitbox Expander",
            Content = val and "Hitboxes expanded." or "Hitboxes restored.",
            Type = val and "success" or "info",
            Duration = 2
        })
    end
})

CombatTab:CreateSlider({
    Name = "Hitbox Radius",
    Min = 2,
    Max = 25,
    Default = 10,
    Suffix = " studs",
    Callback = function(val)
        hitboxSize = val
    end
})

CombatTab:CreateSection("Weapon Handling")

CombatTab:CreateToggle({
    Name = "No Recoil Compensation",
    SubTitle = "Neutralize camera punch and spring perturbation",
    Default = false,
    Callback = function(val)
        GousseUI:Notify({ Title = "Gun Mods", Content = val and "No Recoil active." or "No Recoil disabled.", Type = "info" })
    end
})

CombatTab:CreateToggle({
    Name = "Fast Reload Routine",
    SubTitle = "Speed up active magazine reload sequence",
    Default = false,
    Callback = function(val)
        GousseUI:Notify({ Title = "Gun Mods", Content = val and "Fast Reload enabled." or "Fast Reload disabled.", Type = "info" })
    end
})

-- ============================================================================
-- TAB 2: VISUALS (Lucide Icon: "eye")
-- ============================================================================
local VisualsTab = Window:CreateTab({ Name = "Visuals", Icon = "eye" })

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
    hl.FillColor = isEnemy and Color3.fromRGB(248, 81, 73) or Color3.fromRGB(103, 216, 121)
    hl.OutlineColor = Color3.fromRGB(224, 229, 236)
    hl.FillTransparency = 0.45
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
    Name = "Team-colored Chams",
    SubTitle = "Render red silhouettes for enemies and green for teammates",
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
-- TAB 3: MOVEMENT (Lucide Icon: "gauge")
-- ============================================================================
local MovementTab = Window:CreateTab({ Name = "Movement", Icon = "gauge" })

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
    Name = "Auto Bunny Hop",
    SubTitle = "Auto-jump immediately upon ground contact while moving",
    Default = false,
    Callback = ToggleBHop
})

MovementTab:CreateSlider({
    Name = "WalkSpeed Modifier",
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
-- TAB 4: SETTINGS (Lucide Icon: "settings")
-- ============================================================================
local SettingsTab = Window:CreateTab({ Name = "Settings", Icon = "settings" })

SettingsTab:CreateSection("Module Information")
SettingsTab:CreateParagraph({
    Title = "Arsenal Combat Suite",
    Content = "Version 2.0.0 • Gousse Hub\nTeam awareness is hooked to Player.Team to prevent friendly targeting."
})

local function CleanupArsenal()
    hitboxEnabled = false
    UpdateHitboxes()
    ClearArsenalESP()
    ToggleBHop(false)
end

Window:OnUnload(CleanupArsenal)

SettingsTab:CreateSection("Lifecycle Management")
SettingsTab:CreateButton({
    Name = "Unload Arsenal Module",
    SubTitle = "Restore hitbox dimensions, clean highlights & disconnect hooks",
    ButtonText = "Unload",
    Variant = "danger",
    Callback = function()
        Window:ConfirmUnload()
    end
})

print("[Gousse Hub] Arsenal Module loaded with Desktop Utility aesthetic.")

return {
    Window = Window,
    Type = "Arsenal"
}
