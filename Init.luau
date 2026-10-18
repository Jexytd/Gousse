--[[
    ========================================================================
    Gousse Script Hub - Universal Loader
    Single loader script running across any Roblox game.
    Automatically resolves Universe ID (game.GameId) and Place ID (game.PlaceId)
    against the games manifest, loads the GousseUI library, and initializes
    the appropriate game script.
    ========================================================================
]]

local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

local CONFIG = {
    Owner = "Jexytd",
    Repo = "Gousse",
    Branch = "main",
    Manifest = "games.json",
    LocalDevHost = "http://localhost:3456"
}

local GITHUB_BASE = ("https://raw.githubusercontent.com/%s/%s/%s/"):format(
    CONFIG.Owner,
    CONFIG.Repo,
    CONFIG.Branch
)

-- Local/Global Environment State
local env = (getgenv and getgenv()) or _G or {}
local isDevMode = env.Gousse_DevMode == true

-- Notification Helper (Dual mode: GousseUI if ready, StarterGui as fallback)
local function Notify(title: string, content: string, nType: string?, duration: number?)
    if env.GousseUI and env.GousseUI.Notify then
        pcall(function()
            env.GousseUI:Notify({
                Title = title or "Gousse Hub",
                Content = content or "",
                Type = nType or "info",
                Duration = duration or 4
            })
        end)
    else
        pcall(function()
            StarterGui:SetCore("SendNotification", {
                Title = title or "Gousse Hub",
                Text = content or "",
                Duration = duration or 4
            })
        end)
    end
end

-- Unified Resource Fetcher (Supports Local Dev and GitHub Raw)
local function FetchResource(relativePath: string): string
    relativePath = relativePath:gsub("^/+", "")

    -- If in DevMode, try local manager server first
    if isDevMode then
        local localUrl = ("%s/%s"):format(CONFIG.LocalDevHost, relativePath)
        local ok, res = pcall(function()
            return game:HttpGet(localUrl)
        end)
        if ok and res and not res:find("File Not Found") and not res:find("Cannot GET") then
            return res
        end
    end

    -- GitHub Raw Fetch
    local ghUrl = GITHUB_BASE .. relativePath
    local ghOk, ghRes = pcall(function()
        return game:HttpGet(ghUrl)
    end)

    if ghOk and ghRes and ghRes ~= "404: Not Found" and not ghRes:find("404: Not Found") then
        return ghRes
    end

    -- Last resort: try local server if github returned 404
    if not isDevMode then
        local localUrl = ("%s/%s"):format(CONFIG.LocalDevHost, relativePath)
        local fallbackOk, fallbackRes = pcall(function()
            return game:HttpGet(localUrl)
        end)
        if fallbackOk and fallbackRes and not fallbackRes:find("File Not Found") and not fallbackRes:find("Cannot GET") then
            return fallbackRes
        end
    end

    error(("[Gousse Hub] Failed to fetch resource '%s' from remote and local targets."):format(relativePath))
end

-- Step 1: Load or Initialize GousseUI Library
local function EnsureGousseUI()
    if env.GousseUI then
        return env.GousseUI
    end

    local uiSource = FetchResource("library.luau")
    local uiChunk, compileErr = loadstring(uiSource, "=GousseUI_Library")
    if not uiChunk then
        error(("[Gousse Hub] Syntax error compiling GousseUI Library:\n%s"):format(tostring(compileErr)))
    end

    local ok, uiInstance = pcall(uiChunk)
    if not ok or not uiInstance then
        error(("[Gousse Hub] Runtime error initializing GousseUI Library:\n%s"):format(tostring(uiInstance)))
    end

    env.GousseUI = uiInstance
    return uiInstance
end

-- Step 2: Load Target Script
local function ExecuteScript(scriptPath: string, displayName: string, GousseUI: any)
    Notify("Gousse Hub", ("Loading script: %s..."):format(displayName), "info", 3)

    local scriptSource = FetchResource(scriptPath)
    local chunk, compileErr = loadstring(scriptSource, ("=%s"):format(scriptPath))
    if not chunk then
        Notify("Gousse Error", "Failed to compile script: " .. displayName, "error", 6)
        error(("[Gousse Hub] Compile Error in %s:\n%s"):format(scriptPath, tostring(compileErr)))
    end

    local runOk, result = pcall(chunk, GousseUI)
    if not runOk then
        Notify("Gousse Error", "Execution error in " .. displayName, "error", 6)
        error(("[Gousse Hub] Runtime Error in %s:\n%s"):format(scriptPath, tostring(result)))
    end

    return result
end

-- Main Execution Flow
local function Main()
    print("[Gousse Hub] Universal Loader initializing...")

    -- Initialize GUI Library
    local GousseUI = EnsureGousseUI()

    local placeName = "Roblox Game"
    pcall(function()
        placeName = MarketplaceService:GetProductInfo(game.PlaceId).Name
    end)

    -- Create and Display Modern Tactical Loader GUI
    local Loader = GousseUI:CreateLoader({
        Title = "Gousse Hub",
        SubTitle = "Universal Initialization",
        GameName = placeName,
        Status = "Connecting to CDN & Resolving Environment..."
    })

    Loader:SetStatus("Verifying safe executor environment...", 0.15)
    task.wait(0.12)

    -- Fetch and Parse Game Manifest
    Loader:SetStatus("Fetching Games Manifest...", 0.40)
    local manifestRaw = FetchResource(CONFIG.Manifest)
    local manifest = HttpService:JSONDecode(manifestRaw)
    task.wait(0.1)

    local universeId = tostring(game.GameId)
    local placeId = tostring(game.PlaceId)

    Loader:SetStatus("Resolving target module for Universe " .. universeId .. "...", 0.65)
    local gameEntry = manifest.games and manifest.games[universeId]
    local targetPath = nil
    local targetName = "Universal Fallback"

    if gameEntry then
        -- Check for sub-place specific script (e.g. Sea 1, Sea 2, Dungeon, Lobby)
        local subPlace = gameEntry.places and gameEntry.places[placeId]
        if subPlace and subPlace.script then
            targetPath = subPlace.script
            targetName = ("%s - %s"):format(gameEntry.name or "Game", subPlace.name or "Sub-Place")
        elseif gameEntry.entry then
            targetPath = gameEntry.entry
            targetName = gameEntry.name or "Game"
        end
    end

    -- Fallback to universal script
    if not targetPath then
        targetPath = manifest.universal or "games/universal.luau"
        targetName = ("Universal (%s)"):format(placeName)
    end

    Loader:SetGame(targetName)
    Loader:SetStatus("Compiling " .. targetName .. "...", 0.85)
    task.wait(0.12)

    local scriptSource = FetchResource(targetPath)
    local chunk, compileErr = loadstring(scriptSource, ("=%s"):format(targetPath))
    if not chunk then
        Loader:SetStatus("Compile error in " .. targetName, 1)
        Notify("Gousse Error", "Failed to compile script: " .. targetName, "error", 6)
        error(("[Gousse Hub] Compile Error in %s:\n%s"):format(targetPath, tostring(compileErr)))
    end

    print(("[Gousse Hub] Running [%s] (%s)"):format(targetName, targetPath))
    Loader:SetStatus("Injecting " .. targetName .. "...", 0.96)
    task.wait(0.15)

    local runResult = nil
    Loader:Finish(function()
        local runOk, result = pcall(chunk, GousseUI)
        if not runOk then
            Notify("Gousse Error", "Execution error in " .. targetName, "error", 6)
            error(("[Gousse Hub] Runtime Error in %s:\n%s"):format(targetPath, tostring(result)))
        end
        runResult = result
        Notify("Gousse Hub", ("%s loaded successfully!"):format(targetName), "success", 3)
    end)

    return runResult
end

return Main()