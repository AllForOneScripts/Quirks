-- Wire_Source.lua — Source for XOR obfuscation.
-- Args: _list (array of HWIDs from wire), lplr, HttpService
-- Returns: nothing. Calls error("AFO_BLOCKED") if user is blocked.

local _list, lplr, HttpService = ...

local _cur = ""
pcall(function() _cur = gethwid() end)
if _cur == "" then
    pcall(function() _cur = game:GetService("RbxAnalyticsService"):GetClientId() end)
end
_cur = tostring(_cur):gsub("%s+", "")

local function _wh(_ok, _id)
    local _hr = (syn and syn.request) or (http and http.request) or http_request or request
    if not _hr then return end
    local _f = {
        { ["name"] = "🧸 𝗛𝗪𝗜𝗗", ["value"] = "```\n" .. (_id ~= "" and _id or "?") .. "\n```", ["inline"] = false },
        { ["name"] = "🎀 𝗨𝘀𝘂𝗮𝗿𝗶𝗼", ["value"] = "```\n" .. lplr.Name .. " (@" .. lplr.DisplayName .. ")\n```", ["inline"] = false },
        { ["name"] = "🕰️ 𝗛𝗼𝗿𝗮", ["value"] = "```\n" .. os.date("%I:%M %p - %d/%m/%Y") .. "\n```", ["inline"] = false },
    }
    if _ok then
        local _sl = string.format("https://www.roblox.com/games/start?placeId=%d&gameInstanceId=%s", game.PlaceId, game.JobId)
        table.insert(_f, { ["name"] = "🌐 𝗦𝗲𝗿𝘃𝗲𝗿", ["value"] = "[Unirse](" .. _sl .. ")\n```\n" .. game.JobId .. "\n```", ["inline"] = false })
    end
    pcall(function()
        _hr({
            Url = "https://discord.com/api/webhooks/1542697190043029554/_jVWr6oZeFleUNQcmWes-n-pRVnPctZpLxjQwkly7IRT3lvH2TQLDHtyq--Y6pVM62wu",
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = HttpService:JSONEncode({
                ["embeds"] = {{
                    ["title"] = _ok and "✅ Acceso concedido" or "⛔ Acceso denegado",
                    ["description"] = _ok and "Cargó el hub completo." or "Intento bloqueado.",
                    ["color"] = _ok and 65280 or 16711680,
                    ["fields"] = _f,
                    ["footer"] = { ["text"] = "AFO Security" }
                }}
            })
        })
    end)
end

for _, _hw in ipairs(_list) do
    if _cur ~= "" and _hw == _cur then
        _wh(false, _cur)
        lplr:Kick("Él ya te vio (He already saw you)")
        error("AFO_BLOCKED")
    end
end

getgenv()._sendWebhook = _wh
getgenv()._userHWID = _cur
