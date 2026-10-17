---
description: Invariants and coding standards for GousseUI scripts and Roblox UI components.
globs:
  - "**/*.luau"
  - "library.luau"
  - "Init.luau"
  - "games/**/*.luau"
---

# Gousse GUI Standards & Safety Invariants

1. **Safe Parent Hierarchy**:
   - Never parent GUI instances directly to `game.CoreGui` without protection.
   - Always resolve parent via `gethui()` first, then protected `CoreGui`, then `PlayerGui`.

2. **Component Method Contract**:
   - Every reactive control (`Toggle`, `Slider`, `Dropdown`, `Input`) must provide `.Set(val)` and `.Get()` functions to allow external state manipulation.

3. **Exception Isolation**:
   - All interactive callbacks triggered by UI controls must be executed inside `pcall` blocks to isolate UI state from game runtime exceptions.

4. **Resource & Lifecycle Cleanup**:
   - Every game script must implement an unload mechanism that disconnects all `RBXScriptConnection` handles, destroys created `Highlight` or `Drawing` instances, and restores default character physics.

5. **Theme Conformity**:
   - UI elements must utilize standard GousseUI palette tokens (`Background`, `Sidebar`, `Surface`, `Border`, `WindowOutline`, `Accent`, `Primary`, `Danger`). Do not introduce arbitrary hardcoded neon colors.

6. **Icon Standardization (No Emoticons)**:
   - Use authentic Lucide icons mapped via `icons.luau` or `GousseUI:GetIcon(name)`.
   - Never use emojis or emoticons (e.g. ⚡, 🎯, 👁, 🛠, ⚙) in tabs, buttons, or headers.
