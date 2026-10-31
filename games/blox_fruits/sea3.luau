--[[
    ========================================================================
    Gousse Script Hub - Blox Fruits: Third Sea (World 3)
    Universe ID: 994732206 | Place ID: 7449423635
    Race V4 trials, Mirage Island, Katakuri Cake Prince, and Sea Events.
    Desktop Utility Edition powered by GousseUI & Lucide Icons.
    Includes Dual Discord Webhook System:
      - Game Update & Changelogs Notifier (Alert/Amber Theme)
      - GUI Features & Telemetry Exporter (Gousse Emerald Theme)
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

-- ============================================================================
-- Webhook Service Loader (Local Dev, Remote GitHub, with Fallback Engine)
-- ============================================================================
local WebhookService = nil
do
    local okLocalMod, localMod = pcall(function()
        return game:HttpGet("http://localhost:3456/modules/webhook.luau")
    end)
    if okLocalMod and localMod and not localMod:find("File Not Found") and not localMod:find("Cannot GET") then
        local chunk = loadstring(localMod, "=WebhookService")
        if chunk then
            local okRun, mod = pcall(chunk)
            if okRun and mod then WebhookService = mod end
        end
    end

    if not WebhookService then
        local okGhMod, ghMod = pcall(function()
            return game:HttpGet("https://raw.githubusercontent.com/Jexytd/Gousse/main/modules/webhook.luau")
        end)
        if okGhMod and ghMod and not ghMod:find("404: Not Found") then
            local chunk = loadstring(ghMod, "=WebhookService")
            if chunk then
                local okRun, mod = pcall(chunk)
                if okRun and mod then WebhookService = mod end
            end
        end
    end

    -- Embedded Lightweight Fallback if remote module is inaccessible
    if not WebhookService then
        local HttpService = game:GetService("HttpService")
        WebhookService = {
            Colors = { Emerald = 1095961, Amber = 16096779 },
            SendGameUpdate = function(url, data)
                local httpFunc = (syn and syn.request) or (http and http.request) or request or http_request
                if not httpFunc then return false, "No HTTP request API available" end
                local payload = {
                    username = "Gousse Hub • Game Watchdog",
                    embeds = {{
                        title = "🚨 [GAME UPDATE DETECTED] " .. (data.PlaceName or "Blox Fruits Third Sea"),
                        description = "Update versi place game Roblox terdeteksi!",
                        color = 16096779,
                        fields = {
                            { name = "Place ID", value = tostring(game.PlaceId), inline = true },
                            { name = "Place Version", value = ("v%s ➜ v%s"):format(tostring(data.OldVersion or game.PlaceVersion), tostring(data.NewVersion or game.PlaceVersion)), inline = true },
                            { name = "Changelog", value = data.Changelog or "Developer merilis pembaruan baru pada Roblox.", inline = false }
                        },
                        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
                    }}
                }
                return pcall(function()
                    httpFunc({
                        Url = url,
                        Method = "POST",
                        Headers = { ["Content-Type"] = "application/json" },
                        Body = HttpService:JSONEncode(payload)
                    })
                end)
            end,
            SendGuiFeatures = function(url, data)
                local httpFunc = (syn and syn.request) or (http and http.request) or request or http_request
                if not httpFunc then return false, "No HTTP request API available" end
                local embedFields = {
                    { name = "👤 Player", value = game:GetService("Players").LocalPlayer.Name, inline = true },
                    { name = "📊 Status", value = ("%d Fitur Aktif"):format(data.ActiveCount or 0), inline = true }
                }
                if data.CategoryGroups then
                    for _, grp in ipairs(data.CategoryGroups) do
                        local items = {}
                        for _, itm in ipairs(grp.Features) do
                            local icon = itm.Type == "toggle" and (itm.Value and "✅ " or "❌ ") or "• "
                            table.insert(items, icon .. itm.Name .. ": " .. tostring(itm.Value))
                        end
                        table.insert(embedFields, { name = grp.Category, value = table.concat(items, "\n"), inline = false })
                    end
                end
                local payload = {
                    username = "Gousse Hub • GUI Telemetry",
                    embeds = {{
                        title = "🛡️ [GUI FEATURES] " .. (data.ScriptTitle or "Blox Fruits Third Sea"),
                        color = 1095961,
                        fields = embedFields,
                        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
                    }}
                }
                return pcall(function()
                    httpFunc({
                        Url = url,
                        Method = "POST",
                        Headers = { ["Content-Type"] = "application/json" },
                        Body = HttpService:JSONEncode(payload)
                    })
                end)
            end,
            SaveConfig = function(id, d)
                if not writefile then return false end
                return pcall(function() writefile("gousse_" .. id .. ".json", HttpService:JSONEncode(d)) end)
            end,
            LoadConfig = function(id)
                if not (readfile and isfile and isfile("gousse_" .. id .. ".json")) then return nil end
                local ok, res = pcall(function() return HttpService:JSONDecode(readfile("gousse_" .. id .. ".json")) end)
                return ok and res or nil
            end
        }
    end
end

-- ============================================================================
-- GUI Active State & Features Registry
-- ============================================================================
local CONFIG_ID = "bf_sea3"
local FeatureState = {
    -- Tab 1: Endgame Farm
    CakePrince = false,
    EliteHunter = true,
    CastleBones = false,
    CombatRange = 30,

    -- Tab 2: Race V4 & Mirage
    MirageDetect = true,
    ResonateMoon = false,
    SelectedTrial = "Human (Trial of Strength)",

    -- Tab 3: Sea Events
    AutoMonster = false,
    KitsuneEmbers = true,
    ShipSpeed = 280,

    -- Tab 4: Sea 3 Travel
    DestinationIsland = "Castle on the Sea",

    -- Tab 5: GUI Features Webhook
    FeaturesWebhookUrl = "",
    AutoSendFeaturesOnLoad = false
}

-- Load persisted webhook settings if available
local savedConfig = WebhookService.LoadConfig and WebhookService.LoadConfig(CONFIG_ID)
if savedConfig and type(savedConfig) == "table" then
    if savedConfig.FeaturesWebhookUrl then FeatureState.FeaturesWebhookUrl = savedConfig.FeaturesWebhookUrl end
    if savedConfig.AutoSendFeaturesOnLoad ~= nil then FeatureState.AutoSendFeaturesOnLoad = savedConfig.AutoSendFeaturesOnLoad end
end

-- ============================================================================
-- Window Instance
-- ============================================================================
local Window = GousseUI:CreateWindow({
    Title = "Gousse Hub",
    SubTitle = "Blox Fruits • Third Sea (World 3)",
    Keybind = Enum.KeyCode.RightControl
})

-- ============================================================================
-- TAB 1: ENDGAME FARM (Lucide Icon: "swords")
-- ============================================================================
local FarmTab = Window:CreateTab({ Name = "Endgame Farm", Icon = "swords" })

FarmTab:CreateSection("Third Sea Progression")

FarmTab:CreateToggle({
    Name = "Auto Farm Cake Prince / Dough King",
    SubTitle = "Kill 500 enemies on Cake Land to spawn Dough King",
    Default = FeatureState.CakePrince,
    Callback = function(val)
        FeatureState.CakePrince = val
        GousseUI:Notify({ Title = "Cake Island", Content = val and "Cake Prince progression active." or "Halted.", Type = "info" })
    end
})

FarmTab:CreateToggle({
    Name = "Auto Elite Hunter",
    SubTitle = "Accept Elite Pirate quests and track Deandre, Diablo, Urban",
    Default = FeatureState.EliteHunter,
    Callback = function(val)
        FeatureState.EliteHunter = val
    end
})

FarmTab:CreateToggle({
    Name = "Auto Haunted Castle Bones",
    SubTitle = "Eliminate Reborn Skeletons and exchange bones at Death King",
    Default = FeatureState.CastleBones,
    Callback = function(val)
        FeatureState.CastleBones = val
    end
})

FarmTab:CreateSlider({
    Name = "Combat Range",
    Min = 15,
    Max = 70,
    Default = FeatureState.CombatRange,
    Suffix = " studs",
    Callback = function(val)
        FeatureState.CombatRange = val
    end
})

-- ============================================================================
-- TAB 2: RACE V4 & MIRAGE (Lucide Icon: "crosshair")
-- ============================================================================
local TrialTab = Window:CreateTab({ Name = "Race V4 & Mirage", Icon = "crosshair" })

TrialTab:CreateSection("Mirage Island & Full Moon")

TrialTab:CreateToggle({
    Name = "Mirage Island Auto Detect",
    SubTitle = "Notify and safe tween when Mirage Island spawns in ocean",
    Default = FeatureState.MirageDetect,
    Callback = function(val)
        FeatureState.MirageDetect = val
    end
})

TrialTab:CreateToggle({
    Name = "Auto Resonate Moon (Blue Gear)",
    SubTitle = "Look at full moon with Race V3 to spot Blue Gear spawn",
    Default = FeatureState.ResonateMoon,
    Callback = function(val)
        FeatureState.ResonateMoon = val
    end
})

TrialTab:CreateSection("Temple of Time Trials")

TrialTab:CreateDropdown({
    Name = "Selected Race Trial",
    Options = { "Human (Trial of Strength)", "Mink (Trial of Speed)", "Fishman (Trial of Water)", "Skypian (Trial of Sky)", "Cyborg (Trial of Machine)", "Ghoul (Trial of Carnage)" },
    Default = FeatureState.SelectedTrial,
    Callback = function(opt)
        FeatureState.SelectedTrial = opt
    end
})

TrialTab:CreateButton({
    Name = "Start Race Trial",
    SubTitle = "Pull lever and activate race ability simultaneously",
    ButtonText = "Activate Trial",
    Variant = "primary",
    Callback = function()
        GousseUI:Notify({ Title = "Temple of Time", Content = "Starting " .. tostring(FeatureState.SelectedTrial) .. "...", Type = "success" })
    end
})

-- ============================================================================
-- TAB 3: SEA EVENTS (Lucide Icon: "eye")
-- ============================================================================
local SeaEventsTab = Window:CreateTab({ Name = "Sea Events", Icon = "eye" })

SeaEventsTab:CreateSection("Ocean Danger Zone (Level 1-6)")

SeaEventsTab:CreateToggle({
    Name = "Auto Terrorshark & Sea Beast",
    SubTitle = "Lock camera and fire projectile skills at ocean monsters",
    Default = FeatureState.AutoMonster,
    Callback = function(val)
        FeatureState.AutoMonster = val
    end
})

SeaEventsTab:CreateToggle({
    Name = "Auto Collect Kitsune Embers",
    SubTitle = "Fly and harvest azure embers during Kitsune Island shrine event",
    Default = FeatureState.KitsuneEmbers,
    Callback = function(val)
        FeatureState.KitsuneEmbers = val
    end
})

SeaEventsTab:CreateSlider({
    Name = "Ship Speed Modifier",
    Min = 100,
    Max = 400,
    Default = FeatureState.ShipSpeed,
    Suffix = " studs/s",
    Callback = function(val)
        FeatureState.ShipSpeed = val
    end
})

-- ============================================================================
-- TAB 4: SEA 3 TRAVEL (Lucide Icon: "compass")
-- ============================================================================
local TravelTab = Window:CreateTab({ Name = "Sea 3 Travel", Icon = "compass" })

TravelTab:CreateSection("World 3 Islands")

TravelTab:CreateDropdown({
    Name = "Destination Island",
    Options = { "Port Town", "Hydra Island", "Great Tree", "Floating Turtle", "Castle on the Sea", "Haunted Castle", "Peanut Island", "Ice Cream Island", "Cake Island", "Tiki Outpost" },
    Default = FeatureState.DestinationIsland,
    Callback = function(opt)
        FeatureState.DestinationIsland = opt
    end
})

TravelTab:CreateButton({
    Name = "Teleport to Island",
    SubTitle = "Tween to selected Third Sea location",
    ButtonText = "Travel",
    Variant = "primary",
    Callback = function()
        GousseUI:Notify({ Title = "Third Sea Travel", Content = "Traveling to " .. tostring(FeatureState.DestinationIsland) .. "...", Type = "info" })
    end
})

-- ============================================================================
-- TAB 5: WEBHOOK & TELEMETRY (Lucide Icon: "bell")
-- ============================================================================
local WebhookTab = Window:CreateTab({ Name = "Webhook & Logs", Icon = "bell" })

-- Helper: Compile categorized snapshot of all current GUI features
local function BuildGuiFeaturesSnapshot()
    local groups = {
        {
            Category = "Endgame Farm (Progression)",
            Features = {
                { Name = "Auto Cake Prince / Dough King", Value = FeatureState.CakePrince, Type = "toggle" },
                { Name = "Auto Elite Hunter", Value = FeatureState.EliteHunter, Type = "toggle" },
                { Name = "Auto Haunted Castle Bones", Value = FeatureState.CastleBones, Type = "toggle" },
                { Name = "Combat Range", Value = tostring(FeatureState.CombatRange) .. " studs", Type = "slider" }
            }
        },
        {
            Category = "Race V4 & Mirage Island",
            Features = {
                { Name = "Mirage Island Auto Detect", Value = FeatureState.MirageDetect, Type = "toggle" },
                { Name = "Auto Resonate Moon (Blue Gear)", Value = FeatureState.ResonateMoon, Type = "toggle" },
                { Name = "Selected Race Trial", Value = FeatureState.SelectedTrial, Type = "dropdown" }
            }
        },
        {
            Category = "Sea Events & Danger Zone",
            Features = {
                { Name = "Auto Terrorshark & Sea Beast", Value = FeatureState.AutoMonster, Type = "toggle" },
                { Name = "Auto Collect Kitsune Embers", Value = FeatureState.KitsuneEmbers, Type = "toggle" },
                { Name = "Ship Speed Modifier", Value = tostring(FeatureState.ShipSpeed) .. " studs/s", Type = "slider" }
            }
        },
        {
            Category = "Sea 3 Travel & Navigation",
            Features = {
                { Name = "Destination Island", Value = FeatureState.DestinationIsland, Type = "dropdown" }
            }
        }
    }

    local activeCount = 0
    local totalCount = 0
    for _, grp in ipairs(groups) do
        for _, itm in ipairs(grp.Features) do
            totalCount += 1
            if itm.Type == "toggle" and itm.Value == true then
                activeCount += 1
            end
        end
    end

    return groups, activeCount, totalCount
end

WebhookTab:CreateSection("GUI Features Telemetry Webhook")

local featuresUrlInput = WebhookTab:CreateInput({
    Name = "Features Webhook URL",
    SubTitle = "Discord webhook endpoint untuk menerima snapshot fitur & konfigurasi GUI",
    Placeholder = "https://discord.com/api/webhooks/...",
    Callback = function(val)
        FeatureState.FeaturesWebhookUrl = val
    end
})
if FeatureState.FeaturesWebhookUrl ~= "" then
    pcall(function() featuresUrlInput.Set(FeatureState.FeaturesWebhookUrl) end)
end

WebhookTab:CreateButton({
    Name = "Send GUI Features to Discord",
    SubTitle = "Ekspor status fitur aktif & settingan GUI saat ini ke Discord",
    ButtonText = "Send Features",
    Variant = "primary",
    Callback = function()
        local url = FeatureState.FeaturesWebhookUrl
        if not url or url == "" or not url:find("^https://") then
            GousseUI:Notify({
                Title = "Webhook Error",
                Content = "Masukkan 'Features Webhook URL' yang valid terlebih dahulu.",
                Type = "error",
                Duration = 4
            })
            return
        end

        GousseUI:Notify({ Title = "Webhook", Content = "Menyusun dan mengirim snapshot fitur GUI...", Type = "info", Duration = 2 })

        task.spawn(function()
            local groups, activeCount, totalCount = BuildGuiFeaturesSnapshot()
            local ok, err = WebhookService.SendGuiFeatures(url, {
                ScriptTitle = "Blox Fruits • Third Sea (World 3)",
                CategoryGroups = groups,
                ActiveCount = activeCount,
                TotalCount = totalCount,
                CustomNote = "Snapshot konfigurasi fitur GUI Gousse Hub yang sedang dijalankan oleh player."
            })

            if ok then
                GousseUI:Notify({
                    Title = "Fitur Terkirim",
                    Content = ("Berhasil mengirim %d fitur aktif ke Discord Webhook!"):format(activeCount),
                    Type = "success",
                    Duration = 4
                })
            else
                GousseUI:Notify({
                    Title = "Gagal Mengirim",
                    Content = tostring(err or "Terjadi kesalahan HTTP"),
                    Type = "error",
                    Duration = 5
                })
            end
        end)
    end
})

WebhookTab:CreateToggle({
    Name = "Auto Send Features on Script Load",
    SubTitle = "Kirim snapshot fitur otomatis saat script pertama kali di-load",
    Default = FeatureState.AutoSendFeaturesOnLoad,
    Callback = function(val)
        FeatureState.AutoSendFeaturesOnLoad = val
    end
})

WebhookTab:CreateButton({
    Name = "Save Webhook Settings",
    SubTitle = "Simpan URL webhook & preferensi ke storage lokal executor",
    ButtonText = "Save Config",
    Variant = "secondary",
    Callback = function()
        if WebhookService.SaveConfig then
            local success = WebhookService.SaveConfig(CONFIG_ID, {
                FeaturesWebhookUrl = FeatureState.FeaturesWebhookUrl,
                AutoSendFeaturesOnLoad = FeatureState.AutoSendFeaturesOnLoad
            })
            if success then
                GousseUI:Notify({ Title = "Config", Content = "Pengaturan webhook berhasil disimpan!", Type = "success" })
            else
                GousseUI:Notify({ Title = "Config", Content = "Gagal menyimpan (writefile tidak didukung).", Type = "warning" })
            end
        end
    end
})

WebhookTab:CreateSection("Script Version & Developer Info")

WebhookTab:CreateParagraph({
    Title = "Gousse Studio Script Release",
    Content = "Script Version: v1.0.1 (Blox Fruits Third Sea)\nDeveloper / Lead: Gouang & Jexytd\nStatus: Production Deployment\n\n📌 Catatan: Webhook changelog & script update dikelola dan disiarkan secara khusus melalui Gousse Studio Developer Console oleh pemilik dashboard."
})

-- Auto send features on startup if enabled and webhook URL exists
if FeatureState.AutoSendFeaturesOnLoad and FeatureState.FeaturesWebhookUrl ~= "" then
    task.defer(function()
        task.wait(2)
        local groups, activeCount, totalCount = BuildGuiFeaturesSnapshot()
        pcall(function()
            WebhookService.SendGuiFeatures(FeatureState.FeaturesWebhookUrl, {
                ScriptTitle = "Blox Fruits • Third Sea (World 3)",
                CategoryGroups = groups,
                ActiveCount = activeCount,
                TotalCount = totalCount,
                CustomNote = "Inisialisasi script otomatis pada Third Sea."
            })
        end)
    end)
end

print("[Gousse Hub] Blox Fruits Third Sea (World 3) Script Initialized with Discord Webhook Engine.")

return {
    Window = Window,
    World = "Third Sea",
    Webhook = WebhookService
}
