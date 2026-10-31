--[[
    ========================================================================
    Gousse Hub - Discord Webhook Service Module (modules/webhook.luau)
    Modular Discord Webhook engine for Gousse Hub ecosystem.
    Features:
      1. Script Changelog & Release Broadcast (Indigo Studio theme - for Developer/Owner)
      2. GUI Features & Active Configuration Telemetry (Emerald Gousse theme - for Client/GUI)
      3. Local persistence for Webhook configurations
    Compatible with Potassium, Synapse X, Script-Ware, and standard Luau executors.
    ========================================================================
]]

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local WebhookService = {}
WebhookService.__index = WebhookService

-- Theme Colors (Discord Embed Decimals)
WebhookService.Colors = {
    Indigo = 6514417,    -- #6366F1 (Gousse Studio Developer Release & Changelogs)
    Emerald = 1095961,   -- #10B981 (Gousse Hub Brand Identity - GUI Features)
    Sky = 3718648,       -- #38BDF8 (Info / Session Telemetry)
    Amber = 16096779,    -- #F59E0B (Warning / Alerts)
    Rose = 16007006      -- #F43F5E (Danger / Destructive Actions)
}

-- Safe HTTP POST Request Dispatcher
local function DispatchHttp(url: string, payloadTable: table): (boolean, string?)
    if not url or url == "" or not (url:find("^https://discord%.com/api/webhooks/") or url:find("^https://discordapp%.com/api/webhooks/")) then
        return false, "Invalid Discord Webhook URL. Format must start with https://discord.com/api/webhooks/..."
    end

    local jsonBody
    local encodeOk, encodeErr = pcall(function()
        jsonBody = HttpService:JSONEncode(payloadTable)
    end)
    if not encodeOk or not jsonBody then
        return false, "Failed to encode JSON payload: " .. tostring(encodeErr)
    end

    local httpFunc = (syn and syn.request) or (http and http.request) or request or http_request
    if not httpFunc then
        return false, "Executor missing HTTP request API (request or http_request not supported)"
    end

    local requestOk, response = pcall(function()
        return httpFunc({
            Url = url,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = jsonBody
        })
    end)

    if not requestOk then
        return false, "Network dispatch error: " .. tostring(response)
    end

    local status = response and (response.StatusCode or response.Status_Code or response.status_code)
    if status and (status < 200 or status >= 300) then
        return false, ("Discord HTTP status " .. tostring(status) .. ": " .. tostring(response.Body or response.body or "No details"))
    end

    return true, nil
end

-- ============================================================================
-- 1. SCRIPT CHANGELOG & RELEASE BROADCAST (Developer / Studio Owner Only)
-- ============================================================================
function WebhookService.SendScriptChangelog(webhookUrl: string, data: {
    TargetScript: string?,
    Version: string?,
    Author: string?,
    Changelogs: (string | {string})?,
    ChangedFiles: {string}?,
    CommitMessage: string?,
    CustomNote: string?
}): (boolean, string?)
    data = data or {}
    local target = data.TargetScript or "Gousse Hub Suite"
    local version = data.Version or "1.0.1"
    local author = data.Author or "Gouang"
    local commitMsg = data.CommitMessage
    local isoTimestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")

    -- Parse changelogs text
    local changelogText = ""
    if type(data.Changelogs) == "table" then
        local lines = {}
        for _, item in ipairs(data.Changelogs) do
            table.insert(lines, "• " .. tostring(item))
        end
        changelogText = table.concat(lines, "\n")
    elseif type(data.Changelogs) == "string" and data.Changelogs ~= "" then
        local splitLines = string.split(data.Changelogs, "\n")
        local cleanLines = {}
        for _, line in ipairs(splitLines) do
            local trimmed = string.match(line, "^%s*(.-)%s*$")
            if trimmed and #trimmed > 0 then
                if not (trimmed:sub(1, 1) == "•" or trimmed:sub(1, 1) == "-" or trimmed:sub(1, 1) == "*") then
                    table.insert(cleanLines, "• " .. trimmed)
                else
                    table.insert(cleanLines, trimmed)
                end
            end
        end
        changelogText = table.concat(cleanLines, "\n")
    else
        changelogText = "• Pembaruan script dan optimasi kinerja sistem."
    end

    local fields = {
        {
            name = "📦 Script Version",
            value = ("`v%s`"):format(version),
            inline = true
        },
        {
            name = "👨‍💻 Developer",
            value = ("**%s**"):format(author),
            inline = true
        },
        {
            name = "🎯 Target Module",
            value = ("**%s**"):format(target),
            inline = true
        },
        {
            name = "📝 Changelogs & Release Notes",
            value = changelogText,
            inline = false
        }
    }

    if commitMsg and commitMsg ~= "" then
        table.insert(fields, {
            name = "🔖 Git Commit",
            value = ("`%s`"):format(commitMsg),
            inline = true
        })
    end

    if data.ChangedFiles and #data.ChangedFiles > 0 then
        local fileItems = {}
        for i = 1, math.min(#data.ChangedFiles, 8) do
            table.insert(fileItems, ("`%s`"):format(data.ChangedFiles[i]))
        end
        if #data.ChangedFiles > 8 then
            table.insert(fileItems, ("*(+%d more files)*"):format(#data.ChangedFiles - 8))
        end
        table.insert(fields, {
            name = "📁 Modified Files",
            value = table.concat(fileItems, ", "),
            inline = false
        })
    end

    if data.CustomNote and data.CustomNote ~= "" then
        table.insert(fields, {
            name = "💬 Catatan Developer",
            value = ("> %s"):format(data.CustomNote),
            inline = false
        })
    end

    local payload = {
        username = "Gousse Studio • Script Changelog",
        avatar_url = "https://raw.githubusercontent.com/Jexytd/Gousse/main/manager/icon.png",
        embeds = {
            {
                title = "🚀 [SCRIPT UPDATE & CHANGELOG] " .. target,
                description = "Pembaruan script telah diterbitkan oleh pengembang ke repository utama Gousse Hub.",
                color = WebhookService.Colors.Indigo, -- Studio Indigo #6366F1
                fields = fields,
                footer = {
                    text = "Gousse Studio Developer Console • Owner Broadcast",
                    icon_url = "https://raw.githubusercontent.com/Jexytd/Gousse/main/manager/icon.png"
                },
                timestamp = isoTimestamp
            }
        }
    }

    return DispatchHttp(webhookUrl, payload)
end

-- Backward compatibility alias
WebhookService.SendGameUpdate = function(url, data)
    return WebhookService.SendScriptChangelog(url, {
        TargetScript = data.PlaceName or "Gousse Script",
        Version = tostring(data.NewVersion or "1.0.0"),
        Author = "Developer",
        Changelogs = data.Changelog
    })
end

-- ============================================================================
-- 2. GUI FEATURES & CONFIGURATION NOTIFIER (Gousse Emerald Visual Identity)
-- ============================================================================
function WebhookService.SendGuiFeatures(webhookUrl: string, data: {
    ScriptTitle: string?,
    CategoryGroups: {
        {
            Category: string,
            Features: {
                {
                    Name: string,
                    Value: any,
                    Type: string? -- "toggle" | "slider" | "dropdown" | "info"
                }
            }
        }
    },
    ActiveCount: number?,
    TotalCount: number?,
    CustomNote: string?
}): (boolean, string?)
    data = data or {}
    local scriptTitle = data.ScriptTitle or "Gousse Hub GUI"
    local localPlayer = Players.LocalPlayer
    local playerName = localPlayer and localPlayer.Name or "Unknown Player"
    local displayName = localPlayer and localPlayer.DisplayName or playerName
    local accountAge = localPlayer and tostring(localPlayer.AccountAge) .. " hari" or "N/A"
    local executorName = (identifyexecutor and identifyexecutor()) or "Potassium / Luau"

    local isoTimestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")

    local embedFields = {
        {
            name = "👤 Player & Executor",
            value = ("**%s** (@%s)\nUmur Akun: `%s` | Exec: `%s`"):format(displayName, playerName, accountAge, executorName),
            inline = true
        },
        {
            name = "🌐 Environment Info",
            value = ("Place ID: `%d`\nJob ID: `%s`"):format(
                game.PlaceId,
                game.JobId ~= "" and game.JobId:sub(1, 14) .. "..." or "Local"
            ),
            inline = true
        }
    }

    -- Active Status Summary Field
    local activeCount = data.ActiveCount or 0
    local totalCount = data.TotalCount or 0
    local statsText = ("`%d` Fitur Aktif dari Total `%d` Kontrol"):format(activeCount, totalCount)
    table.insert(embedFields, {
        name = "📊 Status Konfigurasi",
        value = statsText,
        inline = false
    })

    -- Add Category Groups as distinct embed fields
    if data.CategoryGroups and #data.CategoryGroups > 0 then
        for _, group in ipairs(data.CategoryGroups) do
            local lines = {}
            for _, item in ipairs(group.Features) do
                if item.Type == "toggle" then
                    local icon = item.Value and "✅" or "❌"
                    local status = item.Value and "**AKTIF**" or "*Mati*"
                    table.insert(lines, ("• %s **%s**: %s"):format(icon, item.Name, status))
                elseif item.Type == "slider" then
                    table.insert(lines, ("• 🎚️ **%s**: `%s`"):format(item.Name, tostring(item.Value)))
                elseif item.Type == "dropdown" then
                    table.insert(lines, ("• 📋 **%s**: `%s`"):format(item.Name, tostring(item.Value)))
                else
                    table.insert(lines, ("• 🔹 **%s**: `%s`"):format(item.Name, tostring(item.Value)))
                end
            end

            table.insert(embedFields, {
                name = ("📁 [%s]"):format(group.Category),
                value = #lines > 0 and table.concat(lines, "\n") or "*Tidak ada kontrol*",
                inline = false
            })
        end
    end

    if data.CustomNote and data.CustomNote ~= "" then
        table.insert(embedFields, {
            name = "💬 Catatan Pengguna",
            value = ("> %s"):format(data.CustomNote),
            inline = false
        })
    end

    local payload = {
        username = "Gousse Hub • GUI Features Telemetry",
        avatar_url = "https://raw.githubusercontent.com/Jexytd/Gousse/main/manager/icon.png",
        embeds = {
            {
                title = "🛡️ [GUI FEATURES TELEMETRY] " .. scriptTitle,
                description = "Snapshot konfigurasi fitur GUI Gousse Hub yang saat ini sedang aktif pada sesi client.",
                color = WebhookService.Colors.Emerald, -- Signature Gousse Green #10B981
                fields = embedFields,
                footer = {
                    text = "Gousse Hub • Desktop Utility Edition",
                    icon_url = "https://raw.githubusercontent.com/Jexytd/Gousse/main/manager/icon.png"
                },
                timestamp = isoTimestamp
            }
        }
    }

    return DispatchHttp(webhookUrl, payload)
end

-- ============================================================================
-- 3. CONFIG PERSISTENCE (Safe file read/write for Webhook URLs)
-- ============================================================================
local CONFIG_FILE_PREFIX = "gousse_webhook_"

function WebhookService.SaveConfig(configId: string, data: table): boolean
    if not writefile then return false end
    local fileName = CONFIG_FILE_PREFIX .. configId .. ".json"
    local ok, encoded = pcall(function()
        return HttpService:JSONEncode(data)
    end)
    if ok and encoded then
        local writeOk = pcall(function()
            writefile(fileName, encoded)
        end)
        return writeOk
    end
    return false
end

function WebhookService.LoadConfig(configId: string): table?
    if not (readfile and isfile) then return nil end
    local fileName = CONFIG_FILE_PREFIX .. configId .. ".json"
    local exists = false
    pcall(function()
        exists = isfile(fileName)
    end)
    if exists then
        local readOk, content = pcall(function()
            return readfile(fileName)
        end)
        if readOk and content and content ~= "" then
            local decodeOk, parsed = pcall(function()
                return HttpService:JSONDecode(content)
            end)
            if decodeOk and type(parsed) == "table" then
                return parsed
            end
        end
    end
    return nil
end

return WebhookService
