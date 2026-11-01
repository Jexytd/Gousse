---
name: gousse-gui
description: >-
  Comprehensive guide and reference for GousseUI library, Universal Loader (Init.luau),
  game script architecture, component API reference, and implementation standards for agents in the Gousse Hub ecosystem.
---

# GousseUI Library Specification & Agent Reference Manual

GousseUI is a modern, high-performance desktop & mobile UI Library engineered for Roblox Luau script execution environments and the Gousse Script Hub ecosystem.

---

## 1. Core Architecture & Theme System

GousseUI features an authentic modern tactical aesthetic: deep obsidian/slate backgrounds, crisp typography (BuilderSans & JetBrains Mono), responsive vector scaling via `UIScale`, smooth corner resizing, and an instant reactive theming pipeline.

### 1.1 Palette Tokens

| Token | Emerald (Default) | Hex | Usage |
| :--- | :--- | :--- | :--- |
| `Background` | `10, 15, 26` | `#0A0F1A` | Main window outer canvas |
| `Sidebar` | `13, 20, 34` | `#0D1422` | Navigation sidebar & control container fill |
| `Surface` | `17, 27, 46` | `#111B2E` | Interactive component rows, cards, & popovers |
| `SurfaceHover` | `24, 38, 64` | `#182640` | Interactive hover & focus feedback |
| `TooltipBg` | `20, 30, 50` | `#141E32` | Global floating tooltip background |
| `Border` | `30, 41, 59` | `#1E293B` | Perimeter borders & dividers |
| `BorderLight` | `51, 65, 85` | `#334155` | Subtle separators & secondary strokes |
| `WindowOutline`| `16, 185, 129` | `#10B981` | Accent perimeter border highlight |
| `Accent` | `16, 185, 129` | `#10B981` | Primary glowing highlights, active pill, & FAB |
| `AccentDark` | `5, 150, 105` | `#059669` | Accent border shading & pressed states |
| `Primary` | `16, 185, 129` | `#10B981` | Primary button backgrounds |
| `Blue` | `56, 189, 248` | `#38BDF8` | Numeric values & telemetry stats |
| `Success` | `16, 185, 129` | `#10B981` | Success badges & notifications |
| `Warning` | `245, 158, 11` | `#F59E0B` | Warning notifications |
| `Danger` | `244, 63, 94` | `#F43F5E` | Destructive buttons & error notifications |
| `TextPrimary` | `243, 244, 246` | `#F3F4F6` | Primary headers, active titles, & values |
| `TextSecondary`| `148, 163, 184`| `#94A3B8`| Subtitles, descriptions, & inactive tabs |
| `TextMuted` | `100, 116, 139`| `#64748B`| Placeholders, info icons, & section headers |

### 1.2 Preset Palettes

The library provides 8 built-in themes accessible via `GousseUI:SetTheme(name)`:
1. `"emerald"`: Emerald Green (Default)
2. `"cyberpunk"`: Cyber Cyan (`#00F0FF`)
3. `"amethyst"`: Amethyst Violet (`#A855F7`)
4. `"crimson"`: Crimson Ruby (`#F43F5E`)
5. `"amber"`: Warm Amber Gold (`#F59E0B`)
6. `"ocean"`: Sky Ocean Blue (`#38BDF8`)
7. `"slate"`: Minimal Titanium Slate (`#94A3B8`)
8. `"halloween"`: Pumpkin Orange (`#FF7700`) & Gothic Violet

### 1.3 Reactive Theme Methods

```luau
-- Switch active theme preset
GousseUI:SetTheme(themeName: string, customColors: { [string]: Color3 }?)

-- Live override accent color across all headers, active pills, toggles, sliders, & FAB
GousseUI:SetAccentColor(color: Color3)

-- Register individual instance property to automatically update on theme change
local unsubscribe = GousseUI:RegisterThemeElement(element: Instance, propertyName: string, themeKey: string)

-- Register custom callback invoked on every theme or accent update
local unsubscribe = GousseUI:OnThemeUpdate(function(themeTable)
    -- custom reactive logic
end)
```

### 1.4 Safe Parenting Invariant
To prevent game-level detection and client crashes across different executors (Potassium, Synapse, Solara, Wave, etc.):
```luau
local function GetSafeGuiParent(): Instance
    if gethui then
        local ok, hui = pcall(gethui)
        if ok and hui then return hui end
    end
    local okCore, cg = pcall(function() return game:GetService("CoreGui") end)
    if okCore and cg then return cg end
    return game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
end
```

---

## 2. Lucide Icons Engine (No Emoticons Rule)

> [!IMPORTANT]
> **Strict Invariant**: Never use raw emojis or emoticons (e.g. `⚡`, `🎯`, `👁`, `🛠`, `⚙`) in UI tabs, buttons, or section headers. Always pass authentic **Lucide icon names** (e.g. `"crosshair"`, `"shopping-cart"`, `"mouse-pointer"`, `"settings"`).

GousseUI integrates a dual-tier icon engine:
1. Direct primary Lucide icon database (over 800 discrete asset IDs).
2. Rayfield Latte Softworks Lucide sprite sheet fallback (48px atlas).

### Common Icon Map for Agents
- **Automation / Farming**: `"shopping-cart"`, `"mouse-pointer"`, `"trending-up"`, `"play"`, `"refresh-cw"`, `"zap"`
- **Combat / Aim**: `"crosshair"`, `"target"`, `"shield"`, `"sword"`, `"flame"`
- **Visuals / ESP**: `"eye"`, `"eye-off"`, `"camera"`, `"maximize-2"`
- **Movement / Physics**: `"gauge"`, `"navigation"`, `"activity"`, `"move"`
- **Utility / Config**: `"wrench"`, `"sliders"`, `"terminal"`, `"settings"`, `"info"`, `"copy"`, `"folder"`

```luau
local iconAsset, rectOffset, rectSize = GousseUI:ResolveIcon("shopping-cart")
local directAssetId = GousseUI:GetIcon("crosshair") -- Returns "rbxassetid://10709818534"
```

---

## 3. Window Creation & Configuration

```luau
local Window = GousseUI:CreateWindow({
    Title = "Game Title",
    SubTitle = "Module • Gousse Edition",
    Keybind = Enum.KeyCode.RightControl, -- Default menu hotkey
    Size = UDim2.new(0, 690, 0, 450),    -- Desktop default
    Scale = 1.0,                         -- UIScale factor (0.7x - 1.3x)
    Mobile = nil,                        -- Auto-detected if nil (true for touch screens)
    ShowSettings = true,                 -- Auto-injects built-in Settings Tab (LayoutOrder 9999)
    UnloadPrompt = {
        Title = "Konfirmasi Unload",
        Message = "Apakah Anda yakin ingin mematikan script?"
    },
    OnUnload = function()
        -- Module-level cleanup hook
    end
})
```

### Window Object Methods

| Method | Signature | Description |
| :--- | :--- | :--- |
| `Window:CreateTab` | `(tabConfig: TabConfig) -> TabObj` | Creates a sidebar navigation tab |
| `Window:CreateSettingsTab` | `(settingsConfig?) -> TabObj` | Retrieves or creates the built-in UI Settings tab |
| `Window:Toggle` | `(state: boolean?) -> ()` | Toggles or sets window visibility |
| `Window:SetScale` | `(scale: number) -> ()` | Adjusts `UIScale` dynamically (clamped 0.5 - 1.8) |
| `Window:ConfirmUnload` | `(customPrompt?) -> ()` | Displays the tactical confirmation modal |
| `Window:Unload` | `() -> ()` | Executes safe unload immediately |
| `Window:Destroy` | `() -> ()` | Alias for `Window:Unload()` |
| `Window:OnUnload` | `(callback: () -> ()) -> ()` | Registers an unload cleanup callback |

---

## 4. Tab Component Specification

### 4.1 Tab Creation
```luau
local Tab = Window:CreateTab({
    Name = "Auto Buy",
    Icon = "shopping-cart"
})
```
Each tab includes:
- Per-Tab Capsule Pill (`ActiveBar`): anchored at `(0, 0.5)` with `AnchorPoint = (0, 0.5)` for guaranteed vertical centering on all devices and scales.
- Smooth transition tokens with sequential fade-and-slide page transitions.
- Automatic theme color synchronization for icons and labels.

---

## 5. UI Controls & Component API Contract

Every reactive control in GousseUI implements the **Set / Get contract**:
- `.Set(value)`: Programmatically updates the control's value and visual representation.
- `.Get()`: Returns the current value.

---

### 5.1 Toggle Switch
A full-row tactile switch with an optional floating info tooltip `?`.

```luau
local myToggle = Tab:CreateToggle({
    Name = "Enable Auto Farm",
    SubTitle = "Continuously hits targets within 50 studs radius",
    Default = false,
    Callback = function(state: boolean)
        print("Toggle is now:", state)
    end
})

-- Programmatic API
myToggle.Set(true)
local isEnabled = myToggle.Get()
```

---

### 5.2 Slider
Compact slider featuring live value readout in monospace font and mouse/touch drag tracking.

```luau
local mySlider = Tab:CreateSlider({
    Name = "WalkSpeed",
    SubTitle = "Custom humanoid movement velocity",
    Min = 16,
    Max = 250,
    Default = 16,
    Decimals = 0,         -- 0 for integer, 1 or 2 for floats
    Suffix = " studs/s",  -- Optional string appended to value display
    Callback = function(val: number)
        print("WalkSpeed:", val)
    end
})

-- Programmatic API
mySlider.Set(100)
local currentSpeed = mySlider.Get()
```

---

### 5.3 Color Picker (Interactive Canvas & Palette)
Full dual-axis Saturation/Value canvas, 360° Hue spectrum bar, preset color swatches, and live Hex text input.

```luau
local myColorPicker = Tab:CreateColorPicker({
    Name = "ESP Highlight Color",
    SubTitle = "Color for player bounding box and tracers",
    Default = Color3.fromRGB(16, 185, 129), -- Emerald default
    Callback = function(col: Color3)
        print("Selected Color3:", col)
    end
})

-- Programmatic API
myColorPicker.Set(Color3.fromRGB(245, 158, 11)) -- Sets to Amber Gold
local activeColor = myColorPicker.Get()         -- Returns Color3
```

**Color Picker Architecture**:
- **SV Canvas**: Draggable 2D crosshair updating Saturation ($X$) and Value ($1 - Y$).
- **Hue Slider**: Rainbow `UIGradient` keypoints ($0..1$).
- **Quick Swatches**: 8 pre-tested high-contrast colors (Red, Amber, Emerald, Cyan, Blue, Purple, Pink, White).
- **Hex Field**: Editable input supporting 6-digit (`#10B981`) and 3-digit (`#F00`) hex notations.
- **Smart Popover**: Flip-up boundary detection near viewport bottom; click-outside dismissal overlay; automatic connection teardown.

---

### 5.4 Dropdown
Non-clipping floating popover with transparent click-outside overlay and mobile touch scroll isolation.

```luau
local myDropdown = Tab:CreateDropdown({
    Name = "Attack Mode",
    SubTitle = "Select weapon targeting priority",
    Options = { "Nearest", "Lowest Health", "Highest Bounty" },
    Default = "Nearest",
    Callback = function(selected: string)
        print("Selected Mode:", selected)
    end
})

-- Programmatic API
myDropdown.Set("Lowest Health")
myDropdown.Refresh({ "Mode A", "Mode B" }, "Mode A")
local currentChoice = myDropdown.Get()
```

---

### 5.5 Keybind Selector
Interactive keyboard shortcut binder with live listening feedback.

```luau
local myKeybind = Tab:CreateKeybind({
    Name = "Fly Toggle Hotkey",
    SubTitle = "Press key to toggle flight state",
    Default = Enum.KeyCode.F,
    Callback = function(keyCode: Enum.KeyCode)
        print("Bound key:", keyCode.Name)
    end
})

-- Programmatic API
myKeybind.Set(Enum.KeyCode.X)
local boundKey = myKeybind.Get()
```

---

### 5.6 Button Row
Action buttons supporting 3 distinct visual variants.

```luau
Tab:CreateButton({
    Name = "Teleport to Safezone",
    SubTitle = "Instantly repositions character to neutral area",
    ButtonText = "Teleport",
    Variant = "primary", -- "primary" (Accent) | "secondary" (Matte Slate) | "danger" (Ruby Red)
    Callback = function()
        -- Action logic
    end
})
```

---

### 5.7 Text Input Field
Monospace text entry box with placeholder and focus-lost submission.

```luau
local myInput = Tab:CreateInput({
    Name = "Webhook URL",
    SubTitle = "Discord endpoint for telemetry logs",
    Placeholder = "https://discord.com/api/webhooks/...",
    Callback = function(text: string)
        print("Webhook updated:", text)
    end
})

-- Programmatic API
myInput.Set("https://...")
local value = myInput.Get()
```

---

### 5.8 Section Header
Clean uppercase category label with a subtle horizontal divider line:

```luau
Tab:CreateSection("Target Selection")
Tab:CreateSection("Configuration & Timing")
```

---

### 5.9 Paragraph / Info Card
Rich multi-line card for documentation, status telemetry, or changelogs.

```luau
Tab:CreateParagraph({
    Title = "Game Version Telemetry",
    Content = "Universe: 10765145358\nPlace ID: 110838858426924\nStatus: Undetected"
})
```

---

## 6. Global Systems: Notifications & Loader

### 6.1 Toast Notifications
Sliding bottom-right notification cards with color-coded accent indicators:

```luau
GousseUI:Notify({
    Title = "Streamer Tycoon",
    Content = "Trainer initialized successfully.",
    Type = "success", -- "success" (green) | "info" (blue) | "warning" (amber) | "error" (red)
    Duration = 3
})
```

### 6.2 Animated Loader Modal
Full tactical initialization modal with pulsing icon and progress bar:

```luau
local Loader = GousseUI:CreateLoader({
    Title = "Gousse Hub",
    SubTitle = "Universal Initialization",
    GameName = "Blox Fruits",
    Status = "Checking environment..."
})

Loader:SetStatus("Loading game modules...", 0.45)
Loader:SetStatus("Starting UI...", 0.90)

Loader:Finish(function()
    print("Initialization finished!")
end)
```

---

## 7. Standard Game Script Template for Agents

Agents generating or refactoring game modules in `games/<game_name>/main.luau` must adhere to this structured blueprint:

```luau
--[[
    Gousse Hub - <Game Name>
    Universe ID: <UniverseId> (Place ID: <PlaceId>)
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
local LocalPlayer = Players.LocalPlayer

-- State Table (eVars)
local eVars = {
    AutoFarm = false,
    FarmSpeed = 1.0,
    TargetMob = "None",
    ESPColor = Color3.fromRGB(16, 185, 129),
}

-- Connections Table for Clean Unload
local connections = {}

-- ============================================================================
-- UI SETUP
-- ============================================================================
local Window = GousseUI:CreateWindow({
    Title = "<Game Name>",
    SubTitle = "Trainer • Gousse Edition",
    Keybind = Enum.KeyCode.RightControl
})

-- Tab 1: Main Automation
local MainTab = Window:CreateTab({ Name = "Main", Icon = "play" })

MainTab:CreateSection("Automation")
MainTab:CreateToggle({
    Name = "Enable Auto Farm",
    SubTitle = "Automatically attacks selected mob entities",
    Default = false,
    Callback = function(v)
        eVars.AutoFarm = v
    end
})

MainTab:CreateSlider({
    Name = "Attack Delay",
    Min = 0.1,
    Max = 2.0,
    Default = 0.5,
    Decimals = 1,
    Suffix = "s",
    Callback = function(v)
        eVars.FarmSpeed = v
    end
})

-- Tab 2: Visuals
local VisualsTab = Window:CreateTab({ Name = "Visuals", Icon = "eye" })

VisualsTab:CreateColorPicker({
    Name = "Chams Color",
    SubTitle = "Highlight color for player and mob silhouettes",
    Default = eVars.ESPColor,
    Callback = function(col)
        eVars.ESPColor = col
    end
})

-- Unload Lifecycle Hook
Window:OnUnload(function()
    for _, conn in ipairs(connections) do
        if conn and conn.Connected then
            conn:Disconnect()
        end
    end
    table.clear(connections)
end)

GousseUI:Notify({
    Title = "<Game Name>",
    Content = "Trainer loaded successfully.",
    Type = "success",
    Duration = 3
})
```

---

## 8. Invariant Checklist for Agents

Before completing any task involving GousseUI:
1. **Parent Safety**: Always verify `GetSafeGuiParent()` is used.
2. **Method Contracts**: Ensure every reactive control has `.Set(val)` and `.Get()`.
3. **Icons**: Confirm icon names match Lucide keys (no emojis).
4. **Lifecycle**: Ensure `Window:OnUnload(...)` is defined and cleans up all loops and `RBXScriptConnection` handles.
5. **Exception Handling**: Wrap all external game remote calls inside `pcall`.
6. **Theme Synchronization**: Use `GousseUI.Theme` tokens rather than hardcoding arbitrary RGB values.
