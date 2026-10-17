--[[
    ========================================================================
    Gousse Script Hub - Universal Game Script
    Runs across any Roblox game with high-performance utility, movement,
    and visual features powered by GousseUI.
    ========================================================================
]]

local passedUI = ...
local env = (getgenv and getgenv()) or _G or {}
local GousseUI = passedUI or env.GousseUI

if not GousseUI then
    -- Fallback standalone loader
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
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Place Info
local placeName = "Roblox Game"
pcall(function()
    placeName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
end)

-- Window Instance
local Window = GousseUI:CreateWindow({
    Title = "Gousse Hub",
    SubTitle = "Universal • " .. placeName,
    Keybind = Enum.KeyCode.RightControl
})

-- ============================================================================
-- TAB 1: MOVEMENT
-- ============================================================================
local MovementTab = Window:CreateTab({ Name = "Movement", Icon = "⚡" })

MovementTab:CreateSection("Character Speed & Jump")

local currentSpeed = 16
local speedEnabled = false
local currentJump = 50
local jumpEnabled = false

local function UpdateCharacterPhysics()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    if speedEnabled then
        hum.WalkSpeed = currentSpeed
    end
    if jumpEnabled then
        if hum.UseJumpPower then
            hum.JumpPower = currentJump
        else
            hum.JumpHeight = (currentJump / 50) * 7.2
        end
    end
end

MovementTab:CreateToggle({
    Name = "Enable Speed Modifier",
    Default = false,
    Callback = function(val)
        speedEnabled = val
        if not val then
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = 16 end
        else
            UpdateCharacterPhysics()
        end
    end
})

MovementTab:CreateSlider({
    Name = "WalkSpeed",
    Min = 16,
    Max = 250,
    Default = 16,
    Suffix = " studs/s",
    Callback = function(val)
        currentSpeed = val
        if speedEnabled then
            UpdateCharacterPhysics()
        end
    end
})

MovementTab:CreateToggle({
    Name = "Enable Jump Modifier",
    Default = false,
    Callback = function(val)
        jumpEnabled = val
        if not val then
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                if hum.UseJumpPower then hum.JumpPower = 50 else hum.JumpHeight = 7.2 end
            end
        else
            UpdateCharacterPhysics()
        end
    end
})

MovementTab:CreateSlider({
    Name = "JumpPower",
    Min = 50,
    Max = 350,
    Default = 50,
    Suffix = " power",
    Callback = function(val)
        currentJump = val
        if jumpEnabled then
            UpdateCharacterPhysics()
        end
    end
})

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    UpdateCharacterPhysics()
end)

MovementTab:CreateSection("Physics & Gliding")

-- Infinite Jump
local infiniteJumpEnabled = false
UserInputService.JumpRequest:Connect(function()
    if infiniteJumpEnabled then
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

MovementTab:CreateToggle({
    Name = "Infinite Jump",
    Default = false,
    Callback = function(val)
        infiniteJumpEnabled = val
    end
})

-- Noclip
local noclipEnabled = false
local noclipConnection = nil

local function SetNoclip(enabled: boolean)
    noclipEnabled = enabled
    if noclipConnection then
        noclipConnection:Disconnect()
        noclipConnection = nil
    end

    if noclipEnabled then
        noclipConnection = RunService.Stepped:Connect(function()
            local char = LocalPlayer.Character
            if not char then return end
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end)
    end
end

MovementTab:CreateToggle({
    Name = "Noclip (Walk through walls)",
    Default = false,
    Callback = SetNoclip
})

-- Fly system
local flyEnabled = false
local flySpeed = 50
local flyConnection = nil
local flyVelocity = nil
local flyGyro = nil

local function ToggleFly(enabled: boolean)
    flyEnabled = enabled
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")

    if not enabled then
        if flyConnection then flyConnection:Disconnect(); flyConnection = nil end
        if flyVelocity then flyVelocity:Destroy(); flyVelocity = nil end
        if flyGyro then flyGyro:Destroy(); flyGyro = nil end
        if char and char:FindFirstChildOfClass("Humanoid") then
            char:FindFirstChildOfClass("Humanoid").PlatformStand = false
        end
        return
    end

    if not root then return end

    flyVelocity = Instance.new("BodyVelocity")
    flyVelocity.Velocity = Vector3.zero
    flyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    flyVelocity.Parent = root

    flyGyro = Instance.new("BodyGyro")
    flyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    flyGyro.CFrame = root.CFrame
    flyGyro.Parent = root

    flyConnection = RunService.RenderStepped:Connect(function()
        if not flyEnabled or not root or not root.Parent then
            ToggleFly(false)
            return
        end

        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = true end

        local camCFrame = Camera.CFrame
        local direction = Vector3.zero

        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            direction = direction + camCFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            direction = direction - camCFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            direction = direction - camCFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            direction = direction + camCFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            direction = direction + Vector3.new(0, 1, 0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            direction = direction - Vector3.new(0, 1, 0)
        end

        if direction.Magnitude > 0 then
            flyVelocity.Velocity = direction.Unit * flySpeed
        else
            flyVelocity.Velocity = Vector3.zero
        end

        flyGyro.CFrame = camCFrame
    end)
end

MovementTab:CreateToggle({
    Name = "Fly (WASD + Space/Shift)",
    Default = false,
    Callback = ToggleFly
})

MovementTab:CreateSlider({
    Name = "Fly Speed",
    Min = 20,
    Max = 200,
    Default = 50,
    Suffix = " spd",
    Callback = function(val)
        flySpeed = val
    end
})

-- ============================================================================
-- TAB 2: VISUALS
-- ============================================================================
local VisualsTab = Window:CreateTab({ Name = "Visuals", Icon = "👁" })

VisualsTab:CreateSection("World & Lighting")

-- Fullbright
local fullbrightEnabled = false
local originalLighting = {
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    FogEnd = Lighting.FogEnd,
    GlobalShadows = Lighting.GlobalShadows,
    Ambient = Lighting.Ambient
}

local fullbrightConnection = nil
local function SetFullbright(enabled: boolean)
    fullbrightEnabled = enabled
    if fullbrightConnection then fullbrightConnection:Disconnect(); fullbrightConnection = nil end

    if enabled then
        fullbrightConnection = Lighting.Changed:Connect(function()
            if fullbrightEnabled then
                Lighting.Brightness = 2
                Lighting.ClockTime = 14
                Lighting.FogEnd = 786543
                Lighting.GlobalShadows = false
                Lighting.Ambient = Color3.fromRGB(178, 178, 178)
            end
        end)
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 786543
        Lighting.GlobalShadows = false
        Lighting.Ambient = Color3.fromRGB(178, 178, 178)
    else
        Lighting.Brightness = originalLighting.Brightness
        Lighting.ClockTime = originalLighting.ClockTime
        Lighting.FogEnd = originalLighting.FogEnd
        Lighting.GlobalShadows = originalLighting.GlobalShadows
        Lighting.Ambient = originalLighting.Ambient
    end
end

VisualsTab:CreateToggle({
    Name = "Fullbright (No Shadows & Max Light)",
    Default = false,
    Callback = SetFullbright
})

VisualsTab:CreateSlider({
    Name = "Field of View (FOV)",
    Min = 70,
    Max = 120,
    Default = 70,
    Suffix = "°",
    Callback = function(val)
        Camera.FieldOfView = val
    end
})

VisualsTab:CreateSection("Player ESP (Chams)")

local espEnabled = false
local espHighlights = {}

local function ApplyHighlight(plr: Player)
    if plr == LocalPlayer then return end
    if not plr.Character then return end

    if espHighlights[plr] then
        espHighlights[plr]:Destroy()
        espHighlights[plr] = nil
    end

    local highlight = Instance.new("Highlight")
    highlight.Name = "GousseESP"
    highlight.FillColor = Color3.fromRGB(56, 139, 253)
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.Adornee = plr.Character
    highlight.Parent = plr.Character

    espHighlights[plr] = highlight
end

local function ClearESP()
    for plr, hl in pairs(espHighlights) do
        if hl then hl:Destroy() end
    end
    espHighlights = {}
end

local function ToggleESP(val: boolean)
    espEnabled = val
    if not val then
        ClearESP()
        return
    end

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            ApplyHighlight(plr)
        end
        plr.CharacterAdded:Connect(function()
            if espEnabled then
                task.wait(0.5)
                ApplyHighlight(plr)
            end
        end)
    end
end

Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function()
        if espEnabled then
            task.wait(0.5)
            ApplyHighlight(plr)
        end
    end)
end)

Players.PlayerRemoving:Connect(function(plr)
    if espHighlights[plr] then
        espHighlights[plr]:Destroy()
        espHighlights[plr] = nil
    end
end)

VisualsTab:CreateToggle({
    Name = "Player ESP Box / Chams",
    Default = false,
    Callback = ToggleESP
})

-- ============================================================================
-- TAB 3: UTILITY & TELEPORT
-- ============================================================================
local UtilityTab = Window:CreateTab({ Name = "Utility", Icon = "🛠" })

UtilityTab:CreateSection("Player Teleportation")

local playerNames = {}
for _, plr in ipairs(Players:GetPlayers()) do
    if plr ~= LocalPlayer then
        table.insert(playerNames, plr.Name)
    end
end
local selectedTarget = playerNames[1] or ""

local targetDropdown = UtilityTab:CreateDropdown({
    Name = "Select Player",
    Options = #playerNames > 0 and playerNames or { "No players found" },
    Default = selectedTarget,
    Callback = function(choice)
        selectedTarget = choice
    end
})

UtilityTab:CreateButton({
    Name = "Teleport to Selected Player",
    Callback = function()
        if not selectedTarget or selectedTarget == "" or selectedTarget == "No players found" then
            GousseUI:Notify({ Title = "Teleport", Content = "No valid player selected.", Type = "warning" })
            return
        end

        local targetPlr = Players:FindFirstChild(selectedTarget)
        if targetPlr and targetPlr.Character and targetPlr.Character:FindFirstChild("HumanoidRootPart") then
            local myChar = LocalPlayer.Character
            if myChar and myChar:FindFirstChild("HumanoidRootPart") then
                myChar.HumanoidRootPart.CFrame = targetPlr.Character.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0)
                GousseUI:Notify({ Title = "Teleport", Content = "Teleported to " .. selectedTarget, Type = "success" })
            end
        else
            GousseUI:Notify({ Title = "Teleport", Content = "Target player is not spawned.", Type = "error" })
        end
    end
})

UtilityTab:CreateSection("Server & Session")

UtilityTab:CreateButton({
    Name = "Rejoin Current Server",
    Callback = function()
        GousseUI:Notify({ Title = "Server", Content = "Rejoining server...", Duration = 3 })
        task.wait(0.5)
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end
})

UtilityTab:CreateButton({
    Name = "Server Hop (Different Server)",
    Callback = function()
        GousseUI:Notify({ Title = "Server Hop", Content = "Searching for active servers...", Duration = 3 })
        local sfUrl = ("https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=Desc&limit=50"):format(tostring(game.PlaceId))
        local ok, data = pcall(function()
            return HttpService:JSONDecode(game:HttpGet(sfUrl))
        end)

        if ok and data and data.data then
            local servers = data.data
            for _, s in ipairs(servers) do
                if s.playing < s.maxPlayers and s.id ~= game.JobId then
                    GousseUI:Notify({ Title = "Server Hop", Content = "Connecting to new server...", Type = "success" })
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, LocalPlayer)
                    return
                end
            end
        end
        GousseUI:Notify({ Title = "Server Hop", Content = "Could not find an open alternate server.", Type = "warning" })
    end
})

UtilityTab:CreateButton({
    Name = "Copy Job ID to Clipboard",
    Callback = function()
        if setclipboard then
            setclipboard(game.JobId)
            GousseUI:Notify({ Title = "Clipboard", Content = "Job ID copied!", Type = "success" })
        else
            GousseUI:Notify({ Title = "Clipboard", Content = "setclipboard API not supported on this executor.", Type = "warning" })
        end
    end
})

-- Anti-AFK
local antiAfkEnabled = false
local antiAfkConnection = nil
local function SetAntiAfk(val: boolean)
    antiAfkEnabled = val
    if antiAfkConnection then antiAfkConnection:Disconnect(); antiAfkConnection = nil end

    if antiAfkEnabled then
        local VirtualUser = game:GetService("VirtualUser")
        antiAfkConnection = LocalPlayer.Idled:Connect(function()
            if antiAfkEnabled then
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
                GousseUI:Notify({ Title = "Anti-AFK", Content = "Idle kick bypassed.", Type = "info", Duration = 2 })
            end
        end)
        GousseUI:Notify({ Title = "Anti-AFK", Content = "Anti-AFK is now active.", Type = "success" })
    end
end

UtilityTab:CreateToggle({
    Name = "Anti-AFK (Prevent 20-min kick)",
    Default = false,
    Callback = SetAntiAfk
})

-- ============================================================================
-- TAB 4: SETTINGS & ABOUT
-- ============================================================================
local SettingsTab = Window:CreateTab({ Name = "About", Icon = "ℹ" })

SettingsTab:CreateSection("Environment Details")
SettingsTab:CreateParagraph({
    Title = "Gousse Script Studio",
    Content = ("Loaded for: %s\nUniverse ID: %s | Place ID: %s\nExecutor: %s"):format(
        placeName,
        tostring(game.GameId),
        tostring(game.PlaceId),
        (identifyexecutor and identifyexecutor()) or "Luau Executor"
    )
})

SettingsTab:CreateParagraph({
    Title = "Controls & Shortcuts",
    Content = "Press RightControl to hide or show this window.\nYou can click and drag the top header bar to reposition anywhere on screen."
})

SettingsTab:CreateButton({
    Name = "Unload Gousse Hub",
    Callback = function()
        SetNoclip(false)
        ToggleFly(false)
        SetFullbright(false)
        ToggleESP(false)
        SetAntiAfk(false)
        Window:Destroy()
        GousseUI:Notify({ Title = "Gousse Hub", Content = "Cleanly unloaded.", Duration = 3 })
    end
})

print(("[Gousse Universal] Successfully initialized for Place: %s (%d)"):format(placeName, game.PlaceId))

return {
    Window = Window,
    Type = "Universal"
}
