local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

local function verifyHWID()
    -- 1. Obtener HWID local
    local userHWID = ""
    local ok, result = pcall(function() return gethwid() end)
    if ok and type(result) == "string" and result ~= "" then 
        userHWID = result
    else
        local ok2, result2 = pcall(function() return game:GetService("RbxAnalyticsService"):GetClientId() end)
        if ok2 and type(result2) == "string" and result2 ~= "" then
            userHWID = result2
        end
    end

    -- 2. Obtener lista cruda de Rentry
    local wl_url = "https://rentry.co/AFO_/raw"
    local success, wl_string = pcall(function()
        return game:HttpGet(wl_url)
    end)

    if not success or type(wl_string) ~= "string" then
        LocalPlayer:Kick("Error de conexión al verificar HWID.")
        return false
    end

    -- 3. Verificar HWID en la lista (leyendo línea por línea)
    local isWhitelisted = false
    for _, hwid in ipairs(string.split(wl_string, "\n")) do
        hwid = hwid:gsub("%s+", "") -- Limpia espacios y retornos de carro invisibles (\r)
        if hwid ~= "" and hwid == userHWID then
            isWhitelisted = true
            break
        end
    end

    -- 4. Acciones si el HWID no coincide
    if not isWhitelisted then
        -- Copia el HWID real al portapapeles para que lo pegues correctamente en Rentry
        pcall(function() setclipboard(userHWID) end)
        print("Tu HWID real es: " .. userHWID)

        -- Preparar Webhook
        local webhookURL = "https://discord.com/api/webhooks/1542697190043029554/_jVWr6oZeFleUNQcmWes-n-pRVnPctZpLxjQwkly7IRT3lvH2TQLDHtyq--Y6pVM62wu"
        local currentTime = os.date("%I:%M %p - %d/%m/%Y")
        
        local embedData = {
            ["embeds"] = {{
                ["title"] = "✧･ﾟ: *✧･ﾟ:* 𝐀𝐜𝐜𝐞𝐬𝐨 𝐃𝐞𝐧𝐞𝐠𝐚𝐝𝐨 *:･ﾟ✧*:･ﾟ✧",
                ["description"] = "⋆ ˚｡⋆୨୧˚ *Un usuario no autorizado intentó acceder* ˚୨୧⋆｡˚ ⋆",
                ["color"] = 16711680, -- Rojo
                ["fields"] = {
                    {
                        ["name"] = "🧸 ₊˚.༄ 𝗛𝗪𝗜𝗗",
                        ["value"] = "```\n" .. (userHWID ~= "" and userHWID or "Desconocido") .. "\n```",
                        ["inline"] = false
                    },
                    {
                        ["name"] = "🎀 ⋆｡°✩ 𝗨𝘀𝘂𝗮𝗿𝗶𝗼 𝗱𝗲 𝗥𝗼𝗯𝗹𝗼𝘅",
                        ["value"] = "```\n" .. LocalPlayer.Name .. " (@" .. LocalPlayer.DisplayName .. ")\n```",
                        ["inline"] = false
                    },
                    {
                        ["name"] = "🕰️ ❀。• *₊° 𝗛𝗼𝗿𝗮 𝘆 𝗙𝗲𝗰𝗵𝗮",
                        ["value"] = "```\n" .. currentTime .. "\n```",
                        ["inline"] = false
                    }
                },
                ["footer"] = {
                    ["text"] = "✧･ﾟ: *✧ AFO Sᴇᴄᴜʀɪᴛʏ ✧*:･ﾟ✧"
                }
            }}
        }
        
        -- Enviar Webhook
        local httpRequest = (syn and syn.request) or (http and http.request) or http_request or request
        if httpRequest then
            pcall(function()
                httpRequest({
                    Url = webhookURL,
                    Method = "POST",
                    Headers = {
                        ["Content-Type"] = "application/json"
                    },
                    Body = HttpService:JSONEncode(embedData)
                })
            end)
        end

        -- Kickear con el mensaje requerido
        LocalPlayer:Kick("Él ya te vio (He already saw you)")
        return false
    end

    return true
end

-- Ejecutar la verificación
if not verifyHWID() then
    return 
end

-- A partir de aquí, el código de tu hub continúa normalmente si el usuario está admitido.
print("Acceso concedido.")

-- ═══════════════════════════════════════════════════════════════════════════
--  SECCIÓN 1: PROTECCIÓN Y PRIMER HILO (BOOT ANIMATION)
-- ═══════════════════════════════════════════════════════════════════════════

-- Argumento opcional del loadstring, por ejemplo: loadstring(...)("Wiftor")
-- Se usa como avatar inicial de CopyAvatar sin fijarlo dentro del módulo.
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

task.spawn(function()
    pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/AllForOneScripts/Quirks/main/BootAnimation.lua"))()
    end)
end)

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
local VREnabled = game:GetService("VRService").VREnabled
local everyClipboard = setclipboard or toclipboard or set_clipboard or setrbxclipboard or (Clipboard and Clipboard.set)

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

-- URL RAW del archivo principal. No uses el enlace /blob/ de GitHub: devuelve HTML,
-- no Lua. Cada rejoin descarga la última versión publicada de Core.lua.
local SELF_URL = "https://raw.githubusercontent.com/AllForOneScripts/Quirks/main/Core.lua"
local _qt = queue_on_teleport

local function QueueSelf()
    if type(_qt) ~= "function" then
        warn("[AllForOne] queue_on_teleport no está disponible en este executor.")
        return false
    end

    -- Algunos executors acumulan las llamadas a queue_on_teleport. Evitarlo
    -- impide que el hub se ejecute dos veces tras un teleport manual.
    if getgenv()._AFO_RELOAD_QUEUED then
        return true
    end

    local queuedSource = string.format([[
getgenv()._AFO_HUB_LOADED = nil
getgenv()._AFO_RELOAD_QUEUED = nil
loadstring(game:HttpGet(%q))(%q)
]], SELF_URL, EXECUTOR_DEFAULT_AVATAR or "")

    local ok, err = pcall(_qt, queuedSource)
    if not ok then
        warn("[AllForOne] No se pudo encolar la recarga: " .. tostring(err))
        return false
    end

    getgenv()._AFO_RELOAD_QUEUED = true
    return true
end

-- Disponible para módulos que hagan TeleportService: deben invocarla justo
-- antes de iniciar el teleport para conservar la carga del hub.
getgenv().AFOQueueSelf = QueueSelf

-- ═══════════════════════════════════════════════════════════════════════════
--  SECCIÓN 4: SISTEMA DE IDIOMA
-- ═══════════════════════════════════════════════════════════════════════════

local okLang, LangChunk = pcall(function() return loadstring(game:HttpGet("https://raw.githubusercontent.com/AllForOneScripts/Quirks/main/Lang.lua")) end)
local Lang = (okLang and type(LangChunk) == "function") and LangChunk() or {}

local savedLang = "ES"
pcall(function()
    local data = readfile("AllForOne/lang.txt")
    if data == "EN" or data == "ES" then savedLang = data end
end)
local T = Lang[savedLang] or {}

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
local bypassRankedEnabled = true

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
    Gravattack         = Enum.KeyCode.C,
    SpeedForce         = Enum.KeyCode.F5,
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
    Bypass100   = "https://raw.githubusercontent.com/AllForOneScripts/Quirks/main/Bypass%20100%20Kills.lua",
    Clone       = "https://raw.githubusercontent.com/AllForOneScripts/Quirks/main/Clone.lua",
    AdminShield = "https://raw.githubusercontent.com/AllForOneScripts/Quirks/main/Admin%20Shield.lua",
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
    if name == "Gravattack" or name == "Lock" then
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
    warn("[AFO] Falló la carga del módulo (o no devolvió nada): " .. name)
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

local okFluent, chunkFluent = pcall(function() return loadstring(game:HttpGet("https://raw.githubusercontent.com/AllForOneScripts/Quirks/main/UI.lua")) end)
local Fluent = (okFluent and type(chunkFluent) == "function") and chunkFluent() or nil
assert(Fluent, "[AllForOne] Fluent no se pudo cargar desde el repo. Revisa la URL/el estado del repositorio.")

local okSave, chunkSave = pcall(function() return loadstring(game:HttpGet("https://raw.githubusercontent.com/StyearX/Fluent-modded/main/Addons/SaveManager.lua")) end)
local SaveManager = (okSave and type(chunkSave) == "function") and chunkSave() or nil

local okInterface, chunkInterface = pcall(function() return loadstring(game:HttpGet("https://raw.githubusercontent.com/StyearX/Fluent-modded/main/Addons/InterfaceManager.lua")) end)
local InterfaceManager = (okInterface and type(chunkInterface) == "function") and chunkInterface() or nil

local okTheme, chunkTheme = pcall(function() return loadstring(game:HttpGet("https://raw.githubusercontent.com/AllForOneScripts/Quirks/main/All%20For%20One%20Theme.lua")) end)
local AllForOneTheme = (okTheme and type(chunkTheme) == "function") and chunkTheme() or nil
assert(AllForOneTheme, "[AllForOne] No se pudo cargar 'All For One Theme.lua' desde el repo.")

local themeOk, themeErr = pcall(function()
    Fluent:RegisterCustomTheme("AllForOne", AllForOneTheme)
end)

local rawNotify = Fluent.Notify
Fluent.Notify = function(self, data)
    if data and data.Content and (string.find(data.Content, "F3") or string.find(data.Content, "toggle the interface")) then
        return 
    end
    return rawNotify(self, data)
end

local Window
local abrio, err = pcall(function()
    Window = Fluent:CreateWindow({
        Title = "All For One",
        SubTitle = "Hub",
        Version = "1.0.0",
        TabWidth = 160,
        Size = UDim2.fromOffset(620, 500),
        Acrylic = false,
        Theme = "AllForOne",
        MinimizeKey = Enum.KeyCode.F3,
        UserInfoTop = true,
        UserInfoTitle = "Welcome",
        UserInfoSubtitle = lplr.DisplayName,
        UserInfoColor = AllForOneTheme.Accent,
    })
end)

if not abrio or not Window then
    warn("[AllForOne] CreateWindow falló, el hub no puede continuar: " .. tostring(err))
    return
end

pcall(function()
    if Window.Minimize then Window:Minimize() end
end)

local Options = Fluent.Options
if SaveManager and InterfaceManager then
    SaveManager:SetLibrary(Fluent)
    InterfaceManager:SetLibrary(Fluent)
    InterfaceManager:SetFolder("AllForOne")
    SaveManager:SetFolder("AllForOne/Config")

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

-- ═══════════════════════════════════════════════════════════════════════════
--  SECCIÓN 11: TAB "PODER"
-- ═══════════════════════════════════════════════════════════════════════════

local Power = Window:AddTab({ Title = T.tab_power or "Power", Icon = "flame" })

Power:AddButton({
    Title = T.lbl_infiniteyield or "Infinite Yield",
    Description = T.lbl_infiniteyield_desc or "Loads admin commands",
    Callback = function()
        pcall(function()
            local chunk = loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))
            if type(chunk) == "function" then chunk() end
        end)
    end
})

local lockModule = nil
local function initializeLock()
    if lockModule then return end
    lockModule = loadModule("Lock")
    if lockModule then
        lockModule.Start(lplr, Keys.Lock)
        if _omniModule then
            lockModule.SetOmniBlockProvider(function()
                return (_omniModule.IsBlocking and _omniModule.IsBlocking() or false) or
                       (_omniModule.Is4DActive and _omniModule.Is4DActive() or false)
            end)
        end
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
        if type(key) == "string" then applyKey("Lock", key, Enum.KeyCode.X) end
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
        if type(key) == "string" then applyKey("Teleport", key, Enum.KeyCode.BackSlash) end
        if _tpModule and _tpModule.SetKey then pcall(function() _tpModule.SetKey(Keys.Teleport) end) end
    end,
    ChangedCallback = function(key)
        applyKey("Teleport", key, Enum.KeyCode.BackSlash)
        if _tpModule and _tpModule.SetKey then pcall(function() _tpModule.SetKey(Keys.Teleport) end) end
    end
})

local _pbModule = nil
local function pbClear()
    if _pbModule and type(_pbModule) == "table" and _pbModule.Clear then pcall(function() _pbModule.Clear() end) end
end
local function pbSetup(char)
    if not _pbModule then _pbModule = loadModule("PassiveBang") end
    if _pbModule and type(_pbModule) == "table" and _pbModule.Start then pcall(function() _pbModule.Start(lplr, Keys, RunService, UserInputService, getgenv()) end) end
end

Power:AddToggle("PassiveBangToggle", {
    Title = T.lbl_passivebang or "Passive Bang",
    Default = true,
    Callback = function(value)
        passiveBangEnabled = value
        if value then
            if lplr.Character then pbSetup(lplr.Character) end
        else pbClear() end
        notify(T.notif_pb_title or "Passive Bang", value and (T.notif_on or "ON") or (T.notif_off or "OFF"))
    end
})
Power:AddKeybind("PassiveBangKeybind", {
    Title = T.lbl_passivebang_key or "Keybind",
    Default = "Quote",
    Callback = function(key)
        if type(key)=="string" then applyKey("PassiveBang", key, Enum.KeyCode.Quote) end
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
        if type(_muiModule.Start) == "function" then
            pcall(function() _muiModule.Start() end)
        elseif type(_muiModule.SetEnabled) == "function" then
            pcall(function() _muiModule.SetEnabled(true) end)
        end
    elseif type(_muiModule) == "function" then
        pcall(_muiModule)
    end
end
local function muiStop()
    if type(_muiModule) ~= "table" then return end
    if type(_muiModule.Stop) == "function" then
        pcall(function() _muiModule.Stop() end)
    elseif type(_muiModule.SetEnabled) == "function" then
        pcall(function() _muiModule.SetEnabled(false) end)
    end
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

local _omniModule = nil
local function omniStop()
    if _omniModule and type(_omniModule) == "table" and _omniModule.Stop then pcall(function() _omniModule.Stop() end) end
end
local function omniStart()
    if not _omniModule then _omniModule = loadModule("Omniblock") end
    if _omniModule and type(_omniModule) == "table" and _omniModule.Start then
        pcall(function() _omniModule.Start(Keys, lplr, Players, RunService, UserInputService, camera, Debris, getgenv()) end)
        if lockModule then
            lockModule.SetOmniBlockProvider(function()
                return (_omniModule.IsBlocking and _omniModule.IsBlocking() or false) or
                       (_omniModule.Is4DActive and _omniModule.Is4DActive() or false)
            end)
        end
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
        notify(T.notif_unpredic_title or "Unpredictable", value and (T.notif_on or "ON") or (T.notif_off or "OFF"))
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
        if not _speedForceModule then 
            _speedForceModule = loadModule("SpeedForce") 
        end
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
    Default = "Unknown",
    Callback = function(key)
        if type(key) == "string" then applyKey("SpeedForce", key, Enum.KeyCode.Unknown) end
        if _speedForceModule and type(_speedForceModule) == "table" and _speedForceModule.SetKey then pcall(function() _speedForceModule.SetKey(Keys.SpeedForce) end) end
    end,
    ChangedCallback = function(key)
        applyKey("SpeedForce", key, Enum.KeyCode.Unknown)
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
Power:AddToggle("GravattackToggle", {
    Title = T.lbl_gravattack or "Gravattack",
    Default = true,
    Callback = function(value)
        if not gravattackModule then gravattackInitialize() end
        if gravattackModule and type(gravattackModule) == "table" then
            if value and gravattackModule.Start then
                gravattackModule.Start()
                if gravattackModule.SetDropKeybind then gravattackModule.SetDropKeybind(Keys.Gravattack) end
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
        if type(key) == "string" then
            applyKey("Gravattack", key, Enum.KeyCode.C)
            if gravattackModule and gravattackModule.SetDropKeybind then gravattackModule.SetDropKeybind(Keys.Gravattack) end
        end
    end,
    ChangedCallback = function(key)
        applyKey("Gravattack", key, Enum.KeyCode.C)
        if gravattackModule and gravattackModule.SetDropKeybind then gravattackModule.SetDropKeybind(Keys.Gravattack) end
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
        if type(key)=="string" then applyKey("EmoteSteal", key, Enum.KeyCode.T); restartStealEmoteIfRunning() end
    end,
    ChangedCallback = function(key) applyKey("EmoteSteal", key, Enum.KeyCode.T); restartStealEmoteIfRunning() end
})
Misc:AddKeybind("StealEmoteExecuteKeybind", {
    Title = T.lbl_misc_execute_key or "Execute Key", Default = "Y",
    Callback = function(key)
        if type(key)=="string" then applyKey("EmoteExecute", key, Enum.KeyCode.Y); restartStealEmoteIfRunning() end
    end,
    ChangedCallback = function(key) applyKey("EmoteExecute", key, Enum.KeyCode.Y); restartStealEmoteIfRunning() end
})
Misc:AddKeybind("StealEmoteExpandKeybind", {
    Title = T.lbl_misc_expand_key or "Expand Key", Default = "U",
    Callback = function(key)
        if type(key)=="string" then applyKey("EmoteExpand", key, Enum.KeyCode.U); restartStealEmoteIfRunning() end
    end,
    ChangedCallback = function(key) applyKey("EmoteExpand", key, Enum.KeyCode.U); restartStealEmoteIfRunning() end
})

local _cloneModule = nil
local function cloneLoad()
    if not _cloneModule then _cloneModule = loadModule("Clone") end
    if _cloneModule and type(_cloneModule) == "table" and _cloneModule.Start then pcall(function() _cloneModule.Start(lplr, savedLang) end) end
end
Misc:AddButton({
    Title = T.lbl_clone or "Clone",
    Callback = function()
        cloneLoad()
        if _cloneModule and type(_cloneModule) == "table" and _cloneModule.Open then pcall(function() _cloneModule.Open() end) end
    end
})

local _copyAvatarModule = nil
local copyAvatarStarted = false

local function copyAvatarStart()
    if not _copyAvatarModule then _copyAvatarModule = loadModule("CopyAvatar") end
    if type(_copyAvatarModule) == "table" and type(_copyAvatarModule.Start) == "function" then
        if not copyAvatarStarted then
            local ok, err = pcall(function()
                _copyAvatarModule.Start(Keys, lplr, EXECUTOR_DEFAULT_AVATAR)
            end)
            if not ok then warn("[AFO] No se pudo iniciar CopyAvatar: " .. tostring(err)); return false end
            copyAvatarStarted = true
        end
        return true
    end
    warn("[AFO] CopyAvatar no devolvió un módulo válido con Start().")
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
    Callback = function() copyAvatarStart() end
})

Misc:AddKeybind("CopyAvatarKeybind", {
    Title = T.lbl_copyavatar_key or "Copy Avatar Key",
    Default = "F4",
    Callback = function(key)
        if type(key) == "string" then applyKey("CopyAvatar", key, Enum.KeyCode.F4) end
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
        if _adminShieldModule and type(_adminShieldModule) == "table" and _adminShieldModule.SetShieldEnabled then
            pcall(function() _adminShieldModule.SetShieldEnabled(value) end)
        end
        if value then notify(T.notif_adminshield_on_title or "Shield", T.notif_adminshield_on_content or "ON", 6)
        else notify(T.notif_adminshield_off_title or "Shield", T.notif_adminshield_off_content or "OFF", 5) end
    end
})

local _autoRejoinModule = nil
local function autoRejoinStart()
    if not _autoRejoinModule then _autoRejoinModule = loadModule("AutoRejoin") end
    if _autoRejoinModule and type(_autoRejoinModule) == "table" and _autoRejoinModule.Start then pcall(function() _autoRejoinModule.Start(savedLang, placeId, jobId) end) end
end
local function autoRejoinStop()
    if _autoRejoinModule and type(_autoRejoinModule) == "table" and _autoRejoinModule.Stop then pcall(function() _autoRejoinModule.Stop() end) end
end
Defend:AddToggle("AutoRejoinToggle", {
    Title = T.lbl_autorejoin or "Auto Rejoin",
    Default = true,
    Callback = function(value)
        autoRejoinEnabled = value
        if value then autoRejoinStart() else autoRejoinStop() end
        if value then notify(T.notif_autorejoin_on_title or "Rejoin", T.notif_autorejoin_on_content or "ON", 6)
        else notify(T.notif_autorejoin_off_title or "Rejoin", T.notif_autorejoin_off_content or "OFF", 5) end
    end
})

-- ═══════════════════════════════════════════════════════════════════════════
--  SECCIÓN 14: TAB "SERVIDOR"
-- ═══════════════════════════════════════════════════════════════════════════

local Server = Window:AddTab({ Title = T.tab_server or "Server", Icon = "server" })

Server:AddButton({
    Title = T.btn_rejoin or "Rejoin",
    Callback = function()
        notify(T.notif_rejoin_title or "Rejoin", T.notif_rejoin_content or "Rejoining...", 4)
        task.wait(0.5); QueueSelf(); task.wait(0.4)
        if #Players:GetPlayers() <= 1 then pcall(function() TeleportService:Teleport(placeId, lplr) end)
        else pcall(function() TeleportService:TeleportToPlaceInstance(placeId, jobId, lplr) end) end
    end
})

Server:AddButton({
    Title = T.btn_smallserver or "Small Server",
    Callback = function()
        notify(T.notif_smallserver_title or "Small Server", T.notif_smallserver_content or "Searching...", 4)
        task.spawn(function()
            local serversURL = "https://games.roblox.com/v1/games/"..placeId.."/servers/Public?sortOrder=Asc&limit=100"
            local function fetch(cursor)
                local raw = game:HttpGet(serversURL..((cursor and "&cursor="..cursor) or ""))
                return HttpService:JSONDecode(raw)
            end
            local data, nextCursor
            repeat
                data = fetch(nextCursor)
                nextCursor = data.nextPageCursor
            until data and data.data and #data.data > 0
            local server = data.data[1]
            if server then
                QueueSelf(); task.wait(0.3)
                TeleportService:TeleportToPlaceInstance(placeId, server.id, lplr)
            end
        end)
    end
})

local _bypassModule = nil
local function bypassRankedStart()
    if not _bypassModule then _bypassModule = loadModule("Bypass100") end
    if _bypassModule and type(_bypassModule) == "table" and _bypassModule.Start then pcall(function() _bypassModule.Start(lplr, TeleportService, placeId) end) end
end
local function bypassRankedStop()
    if _bypassModule and type(_bypassModule) == "table" and _bypassModule.Stop then pcall(function() _bypassModule.Stop() end) end
end
Server:AddToggle("BypassRankedToggle", {
    Title = T.lbl_bypass_ranked or "Bypass Ranked",
    Default = true,
    Callback = function(value)
        bypassRankedEnabled = value
        if value then bypassRankedStart() else bypassRankedStop() end
        notify(T.notif_bypass_ranked_title or "Bypass", value and (T.notif_on or "ON") or (T.notif_off or "OFF"))
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
        notify(T.notif_lang_changed or "Language", T.notif_lang_changed_content or "Changed", 4)
    end
})

Settings:AddKeybind("MinimizeKeybind", {
    Title = T.lbl_keybind or "Minimize Key",
    Default = "F3",
    Callback = function(key)
        if type(key) == "string" then pcall(function() Window:SetMinimizeKey(parseKeyCode(key, Enum.KeyCode.F3)) end) end
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
        autoRejoinStop()
        adminShieldStop()
        bypassRankedStop()
        noCDDashStop()
        pbClear()
        antiFlingStop()
        copyAvatarStop()
        if _speedForceModule and type(_speedForceModule) == "table" and _speedForceModule.Stop then pcall(function() _speedForceModule.Stop() end) end
        if gravattackModule and type(gravattackModule) == "table" and gravattackModule.Stop then gravattackModule.Stop() end
        if lockModule and type(lockModule) == "table" and lockModule.Stop then lockModule.Stop() end
        disconnectAllConnections()
        pcall(function() Window:Destroy() end)
        getgenv()._AFO_HUB_LOADED = nil
    end
})

-- ═══════════════════════════════════════════════════════════════════════════
--  SECCIÓN 16: TAB "CONFIG"
-- ═══════════════════════════════════════════════════════════════════════════

local Config = Window:AddTab({ Title = T.tab_config or "Config", Icon = "clipboard" })

if SaveManager then
    SaveManager:SetLibrary(Fluent)
    SaveManager:IgnoreThemeSettings()
    SaveManager:SetIgnoreIndexes({"LanguageDropdown"})
    SaveManager:SetFolder("AllForOne/Configs")
    Config:AddInput("ConfigName", {
        Title = T.lbl_autoload or "AutoLoad Config",
        Default = "default",
        Placeholder = "config name",
        Callback = function(val) SaveManager:SetAutoloadConfig(val) end
    })
    Config:AddButton({ Title = T.lbl_saveconfig or "Save Config", Callback = function() SaveManager:Save() end })
    Config:AddButton({ Title = T.lbl_loadconfig or "Load Config", Callback = function() SaveManager:Load() end })
    SaveManager:LoadAutoloadConfig()
end

-- ═══════════════════════════════════════════════════════════════════════════
--  SECCIÓN 17: INICIALIZACIÓN FINAL Y CARGAS ASINCRONAS
-- ═══════════════════════════════════════════════════════════════════════════

Window:SelectTab(startOnSettings and 5 or 1)

if teleportEnabled then tpStart() end
if passiveBangEnabled and lplr.Character then pbSetup(lplr.Character) end
if muiEnabled then muiStart() end
omniStart()
softAimSetup()
if adminShieldEnabled then adminShieldStart() end
if autoRejoinEnabled then autoRejoinStart() end
bypassRankedStart()
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
    pbClear()
    if passiveBangEnabled then pbSetup(char) end
    if softAimEnabled then softAimSetup() end
    if unpredicEnabled then unpredicStop(); task.wait(0.3); unpredicStart(char) end
end))

task.spawn(function()
    task.delay(1, function()
        copyAvatarStart()
    end)
end)

task.spawn(function()
    local totalAnimTime = 11.9
    local elapsed = tick() - BOOT_START_TIME
    if elapsed < totalAnimTime then
        task.wait(totalAnimTime - elapsed)
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
        Fluent:Notify({ Title = T.notif_activated_title or "Activated", Content = T.notif_activated_content or "All set!", Duration = 5 })
    end)
end)
