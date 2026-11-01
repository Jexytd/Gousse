# GousseUI Library API & Agent Developer Guide

> **Target Version**: GousseUI v2.3.0  
> **Environment**: Roblox Luau (Executor / Client)  
> **Repository Core**: [`library.luau`](file:///c:/Users/Gouang/Desktop/Gousse/library.luau)  
> **Agent Skill**: [`.agents/skills/gousse-gui/SKILL.md`](file:///c:/Users/Gouang/Desktop/Gousse/.agents/skills/gousse-gui/SKILL.md)

---

## Quick Navigation

- [1. Library Initialization](#1-library-initialization)
- [2. Theme Engine & Reactive Styling](#2-theme-engine--reactive-styling)
- [3. Window Management](#3-window-management)
- [4. Tab Management](#4-tab-management)
- [5. Component Reference](#5-component-reference)
  - [Toggle](#51-createtoggle)
  - [Slider](#52-createslider)
  - [Color Picker](#53-createcolorpicker)
  - [Dropdown](#54-createdropdown)
  - [Keybind](#55-createkeybind)
  - [Button](#56-createbutton)
  - [Input](#57-createinput)
  - [Section](#58-createsection)
  - [Paragraph](#59-createparagraph)
- [6. Utility Systems](#6-utility-systems)
  - [Notifications](#61-notifications-gousseuinotify)
  - [Loader Modal](#62-loader-modal-gousseuicreateloader)
  - [Lucide Icons](#63-lucide-icons-engine)
- [7. Agent Coding Invariants](#7-agent-coding-invariants)

---

## 1. Library Initialization

### 1.1 In-Script Resolution
Every game script located in `games/<game_slug>/main.luau` must accept `passedUI` via vararg or fallback to local/remote endpoints:

```luau
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
```

---

## 2. Theme Engine & Reactive Styling

GousseUI provides a fully reactive theming pipeline. When the user changes a theme or adjusts the accent color, all subscribed GUI elements update instantly.

### 2.1 Theme Presets
Accessible via `GousseUI:SetTheme(name)`:
- `"emerald"`: Default Obsidian & Emerald Green (`#10B981`)
- `"cyberpunk"`: Dark Night & Neon Cyan (`#00F0FF`)
- `"amethyst"`: Gothic Slate & Amethyst Violet (`#A855F7`)
- `"crimson"`: Crimson Ruby (`#F43F5E`)
- `"amber"`: Warm Dark Bronze & Amber Gold (`#F59E0B`)
- `"ocean"`: Deep Sea & Sky Blue (`#38BDF8`)
- `"slate"`: Minimalist Slate & Titanium Grey (`#94A3B8`)
- `"halloween"`: Witch Purple & Pumpkin Orange (`#FF7700`)

### 2.2 Theme API

```luau
-- Switch preset
GousseUI:SetTheme("amber")

-- Override accent color across entire UI
GousseUI:SetAccentColor(Color3.fromRGB(245, 158, 11))

-- Register instance property to auto-update when theme changes
local unbind = GousseUI:RegisterThemeElement(myFrame, "BackgroundColor3", "Surface")

-- Register reactive callback
local unbind = GousseUI:OnThemeUpdate(function(theme)
    print("New accent:", theme.Accent)
end)
```

---

## 3. Window Management

### 3.1 `GousseUI:CreateWindow(config)`

```luau
local Window = GousseUI:CreateWindow({
    Title = "Streamer Tycoon",
    SubTitle = "Trainer • Gousse Edition",
    Keybind = Enum.KeyCode.RightControl, -- Menu toggle hotkey
    Size = UDim2.new(0, 690, 0, 450),    -- Desktop default size
    Scale = 1.0,                         -- UIScale factor (0.7x - 1.3x)
    Mobile = nil,                        -- Auto-detected (true for touch devices)
    ShowSettings = true,                 -- Auto-generates Settings Tab at LayoutOrder 9999
    UnloadPrompt = {
        Title = "Konfirmasi Unload",
        Message = "Matikan seluruh fungsi trainer dan tutup interface?"
    },
    OnUnload = function()
        -- Module teardown logic
    end
})
```

### 3.2 Window Object Methods

| Method | Description |
| :--- | :--- |
| `Window:CreateTab({ Name, Icon })` | Instantiates a navigation tab with Lucide icon |
| `Window:CreateSettingsTab()` | Returns or creates the built-in UI Settings tab |
| `Window:Toggle(state?)` | Shows, hides, or flips window visibility |
| `Window:SetScale(scale)` | Adjusts window `UIScale` (0.5 to 1.8) |
| `Window:ConfirmUnload(prompt?)` | Displays the modal confirmation dialog |
| `Window:Unload()` / `Window:Destroy()` | Unloads the script and cleans up the UI |
| `Window:OnUnload(cb)` | Registers an unload cleanup callback |

---

## 4. Tab Management

### 4.1 `Window:CreateTab(tabConfig)`

```luau
local MainTab = Window:CreateTab({
    Name = "Auto Buy",
    Icon = "shopping-cart"
})
```

- **Features**:
  - Automatically centers the vertical active pill (`ActiveBar`) at `(0, 0.5)` with `AnchorPoint = (0, 0.5)`.
  - Seamless page transitions (CanvasGroup slide-and-fade).
  - Built-in search filtering hook.

---

## 5. Component Reference

All interactive components strictly follow the **Set / Get contract**:
- `Component.Set(value)`: Programmatically updates the state and UI.
- `Component.Get()`: Returns the current value.

---

### 5.1 `CreateToggle`

Full-row switch with optional subtitle and tooltip.

```luau
local myToggle = Tab:CreateToggle({
    Name = "Enable Auto Buy",
    SubTitle = "Automatically touches all available buttons in your plot",
    Default = false,
    Callback = function(enabled: boolean)
        print("Auto Buy is now:", enabled)
    end
})

myToggle.Set(true)
local isRunning = myToggle.Get()
```

---

### 5.2 `CreateSlider`

Compact slider with monospace numeric display and mouse/touch drag support.

```luau
local mySlider = Tab:CreateSlider({
    Name = "Buy Delay",
    SubTitle = "Interval between purchase requests",
    Min = 0.1,
    Max = 2.0,
    Default = 0.1,
    Decimals = 1,
    Suffix = "s",
    Callback = function(val: number)
        print("Delay:", val)
    end
})

mySlider.Set(0.5)
local delay = mySlider.Get()
```

---

### 5.3 `CreateColorPicker`

Interactive color picker featuring a 2D Saturation/Value canvas, 360° Hue spectrum slider, quick preset swatches, and live Hex text input.

```luau
local myColorPicker = Tab:CreateColorPicker({
    Name = "Chams Highlight Color",
    SubTitle = "Silhouette color for visible targets",
    Default = Color3.fromRGB(16, 185, 129),
    Callback = function(newCol: Color3)
        print("Color changed:", newCol)
    end
})

myColorPicker.Set(Color3.fromRGB(245, 158, 11))
local selectedColor = myColorPicker.Get() -- Returns Color3
```

- **Popover Mechanics**:
  - Draggable Saturation/Value ($X \rightarrow \text{Sat}$, $1 - Y \rightarrow \text{Val}$).
  - Draggable Hue rainbow bar.
  - 8 quick preset buttons.
  - Editable Hex box (`#10B981`, `#F59E0B`, etc.).
  - Outside-click dismissal and automatic connection cleanup.

---

### 5.4 `CreateDropdown`

Non-clipping floating popover with scroll isolation.

```luau
local myDropdown = Tab:CreateDropdown({
    Name = "Stack Mode",
    SubTitle = "Multiplier applied per upgrade cycle",
    Options = { "1", "5", "25", "MAX" },
    Default = "1",
    Callback = function(choice: string)
        print("Mode selected:", choice)
    end
})

myDropdown.Set("MAX")
myDropdown.Refresh({ "1", "10", "100" }, "1")
local currentChoice = myDropdown.Get()
```

---

### 5.5 `CreateKeybind`

Interactive key selector with listening indicator.

```luau
local myKeybind = Tab:CreateKeybind({
    Name = "Quick Rebirth Hotkey",
    SubTitle = "Keyboard shortcut to trigger rebirth",
    Default = Enum.KeyCode.R,
    Callback = function(key: Enum.KeyCode)
        print("Bound key:", key.Name)
    end
})

myKeybind.Set(Enum.KeyCode.Q)
local boundKey = myKeybind.Get()
```

---

### 5.6 `CreateButton`

Action button supporting 3 variants: `"primary"` (accent highlight), `"secondary"` (matte slate), or `"danger"` (ruby red).

```luau
Tab:CreateButton({
    Name = "Instant Rebirth",
    SubTitle = "Fires rebirth remote packet immediately",
    ButtonText = "Rebirth",
    Variant = "primary",
    Callback = function()
        -- Action code
    end
})
```

---

### 5.7 `CreateInput`

Single-line monospace text entry box with focus-lost commit.

```luau
local myInput = Tab:CreateInput({
    Name = "Target Player Name",
    SubTitle = "Username or display name filter",
    Placeholder = "Enter username...",
    Callback = function(text: string)
        print("Target:", text)
    end
})

myInput.Set("Player1")
local target = myInput.Get()
```

---

### 5.8 `CreateSection`

Understated uppercase label with subtle divider line.

```luau
Tab:CreateSection("Automation Settings")
```

---

### 5.9 `CreateParagraph`

Multi-line info card.

```luau
Tab:CreateParagraph({
    Title = "Release Notes",
    Content = "v1.2.0: Added multi-theme engine and dynamic color picker."
})
```

---

## 6. Utility Systems

### 6.1 Notifications: `GousseUI:Notify`

```luau
GousseUI:Notify({
    Title = "Gousse Hub",
    Content = "Configuration saved successfully.",
    Type = "success", -- "success" | "info" | "warning" | "error"
    Duration = 3
})
```

### 6.2 Loader Modal: `GousseUI:CreateLoader`

```luau
local Loader = GousseUI:CreateLoader({
    Title = "Gousse Hub",
    SubTitle = "Universal Initialization",
    GameName = "Streamer Tycoon",
    Status = "Loading components..."
})

Loader:SetStatus("Connecting modules...", 0.5)
Loader:Finish(function()
    print("Ready!")
end)
```

### 6.3 Lucide Icons Engine

```luau
local assetId, rectOffset, rectSize = GousseUI:ResolveIcon("shopping-cart")
local directAsset = GousseUI:GetIcon("crosshair") -- "rbxassetid://10709818534"
```

---

## 7. Agent Coding Invariants

When creating or modifying Gousse scripts, agents must strictly follow these invariants:

1. **Safe Parent Hierarchy**: Always parent GUIs via `GetSafeGuiParent()` (`gethui()` $\rightarrow$ protected `CoreGui` $\rightarrow$ `PlayerGui`).
2. **Method Contracts**: Every reactive control must expose `.Set(val)` and `.Get()`.
3. **No Emoticons / Emojis**: Never use emoji symbols in UI tabs, buttons, or headers. Use Lucide icon names.
4. **Exception Handling**: Wrap all character physics, game remotes, and external calls inside `pcall`.
5. **Lifecycle Teardown**: Always connect an unload handler via `Window:OnUnload(...)` that disconnects all `RBXScriptConnection` instances and cleans up temporary visual objects.

