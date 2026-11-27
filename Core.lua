-- ═══════════════════════════════════════════════════════════════════════════
--  SECCIÓN 1: PROTECCIÓN Y PRIMER HILO 
-- ═══════════════════════════════════════════════════════════════════════════
local EXECUTOR_DEFAULT_AVATAR = ...
if type(EXECUTOR_DEFAULT_AVATAR) ~= "string" or EXECUTOR_DEFAULT_AVATAR == "" then
    EXECUTOR_DEFAULT_AVATAR = nil
end

if getgenv()._AFO_HUB_LOADED then
    warn("[All for One] Another hub instance is already running. Close it before opening another. / Ya se está ejecutando otra instancia del hub. Ciérrala antes de abrir otra.")
    return
end
getgenv()._AFO_HUB_LOADED = true

local cloneref = cloneref or function(x) return x end
local HttpService = cloneref(game:GetService("HttpService"))
local Players = cloneref(game:GetService("Players"))
local lplr = Players.LocalPlayer

-- ═══════════════════════════════════════════════════════════════════════════
--  SECCIÓN 2: WIRE
-- ═══════════════════════════════════════════════════════════════════════════
-- Node config for AFO mesh relay (DO NOT MODIFY)
local _node = {
    id = "afo-9b7c-4f2a",
    region = "us-east-1",
    provider = "quirks-dev",
}

-- ──────────── ⚙️ ────────────
local _w = [[
01740914907190/9
01740914907190/9
01740914907190/901740914907190/9
01740914907190/901740914907190/9
01740914907190/901740914907190/9
]]
-- ──────────── ⚙️ ────────────

-- Retry policy
local _retry = { count = 3, delay = 5 }

local _list = {}
do
    local _flat = _w:gsub("%s+", "")
    for _b in _flat:gmatch("([^/]+)/9") do
        local _h = ""
        for _i = 1, #_b, 2 do
            local _v = tonumber(_b:sub(_i, _i + 1))
            if _v then _h = _h .. string.char(_v + 32) end
        end
        if #_h > 0 then _list[#_list + 1] = _h end
    end
end

-- ───── ⚙️ EX ─────
local _x = {
134,134,139,252,194,217,206,244,248,196,222,217,200,206,133,199,222,202,139,73,43,63,139,248,196,222,217,200,206,139,205,196,217,139,243,228,249,139,196,201,205,222,216,200,202,223,194,196,197,133,161,134,134,139,234,217,204,216,145,139,244,199,194,216,223,139,131,202,217,217,202,210,139,196,205,139,227,252,226,239,216,139,205,217,196,198,139,220,194,217,206,130,135,139,199,219,199,217,135,139,227,223,223,219,248,206,217,221,194,200,206,161,134,134,139,249,206,223,222,217,197,216,145,139,197,196,223,195,194,197,204,133,139,232,202,199,199,216,139,206,217,217,196,217,131,137,234,237,228,244,233,231,228,232,224,238,239,137,130,139,194,205,139,222,216,206,217,139,194,216,139,201,199,196,200,192,206,207,133,161,161,199,196,200,202,199,139,244,199,194,216,223,135,139,199,219,199,217,135,139,227,223,223,219,248,206,217,221,194,200,206,139,150,139,133,133,133,161,161,199,196,200,202,199,139,244,200,222,217,139,150,139,137,137,161,219,200,202,199,199,131,205,222,197,200,223,194,196,197,131,130,139,244,200,222,217,139,150,139,204,206,223,195,220,194,207,131,130,139,206,197,207,130,161,194,205,139,244,200,222,217,139,150,150,139,137,137,139,223,195,206,197,161,139,139,139,139,219,200,202,199,199,131,205,222,197,200,223,194,196,197,131,130,139,244,200,222,217,139,150,139,204,202,198,206,145,236,206,223,248,206,217,221,194,200,206,131,137,249,201,211,234,197,202,199,210,223,194,200,216,248,206,217,221,194,200,206,137,130,145,236,206,223,232,199,194,206,197,223,226,207,131,130,139,206,197,207,130,161,206,197,207,161,244,200,222,217,139,150,139,223,196,216,223,217,194,197,204,131,244,200,222,217,130,145,204,216,222,201,131,137,142,216,128,137,135,139,137,137,130,161,161,199,196,200,202,199,139,205,222,197,200,223,194,196,197,139,244,220,195,131,244,196,192,135,139,244,194,207,130,161,139,139,139,139,199,196,200,202,199,139,244,195,217,139,150,139,131,216,210,197,139,202,197,207,139,216,210,197,133,217,206,218,222,206,216,223,130,139,196,217,139,131,195,223,223,219,139,202,197,207,139,195,223,223,219,133,217,206,218,222,206,216,223,130,139,196,217,139,195,223,223,219,244,217,206,218,222,206,216,223,139,196,217,139,217,206,218,222,206,216,223,161,139,139,139,139,194,205,139,197,196,223,139,244,195,217,139,223,195,206,197,139,217,206,223,222,217,197,139,206,197,207,161,139,139,139,139,199,196,200,202,199,139,244,205,139,150,139,208,161,139,139,139,139,139,139,139,139,208,139,240,137,197,202,198,206,137,246,139,150,139,137,91,52,12,19,139,91,54,60,48,91,54,60,1,91,54,60,55,91,54,60,60,137,135,139,240,137,221,202,199,222,206,137,246,139,150,139,137,203,203,203,247,197,137,139,133,133,139,131,244,194,207,139,213,150,139,137,137,139,202,197,207,139,244,194,207,139,196,217,139,137,148,137,130,139,133,133,139,137,247,197,203,203,203,137,135,139,240,137,194,197,199,194,197,206,137,246,139,150,139,205,202,199,216,206,139,214,135,161,139,139,139,139,139,139,139,139,208,139,240,137,197,202,198,206,137,246,139,150,139,137,91,52,37,43,139,91,54,60,3,91,54,51,43,91,54,51,41,91,54,60,5,91,54,60,20,91,54,60,29,91,54,60,23,137,135,139,240,137,221,202,199,222,206,137,246,139,150,139,137,203,203,203,247,197,137,139,133,133,139,199,219,199,217,133,229,202,198,206,139,133,133,139,137,139,131,235,137,139,133,133,139,199,219,199,217,133,239,194,216,219,199,202,210,229,202,198,206,139,133,133,139,137,130,247,197,203,203,203,137,135,139,240,137,194,197,199,194,197,206,137,246,139,150,139,205,202,199,216,206,139,214,135,161,139,139,139,139,139,139,139,139,208,139,240,137,197,202,198,206,137,246,139,150,139,137,91,52,62,27,68,19,36,139,91,54,60,48,91,54,60,23,91,54,60,20,91,54,60,5,137,135,139,240,137,221,202,199,222,206,137,246,139,150,139,137,203,203,203,247,197,137,139,133,133,139,196,216,133,207,202,223,206,131,137,142,226,145,142,230,139,142,219,139,134,139,142,207,132,142,198,132,142,242,137,130,139,133,133,139,137,247,197,203,203,203,137,135,139,240,137,194,197,199,194,197,206,137,246,139,150,139,205,202,199,216,206,139,214,135,161,139,139,139,139,214,161,139,139,139,139,194,205,139,244,196,192,139,223,195,206,197,161,139,139,139,139,139,139,139,139,199,196,200,202,199,139,244,216,199,139,150,139,216,223,217,194,197,204,133,205,196,217,198,202,223,131,137,195,223,223,219,216,145,132,132,220,220,220,133,217,196,201,199,196,211,133,200,196,198,132,204,202,198,206,216,132,216,223,202,217,223,148,219,199,202,200,206,226,207,150,142,207,141,204,202,198,206,226,197,216,223,202,197,200,206,226,207,150,142,216,137,135,139,204,202,198,206,133,251,199,202,200,206,226,207,135,139,204,202,198,206,133,225,196,201,226,207,130,161,139,139,139,139,139,139,139,139,223,202,201,199,206,133,194,197,216,206,217,223,131,244,205,135,139,208,139,240,137,197,202,198,206,137,246,139,150,139,137,91,52,39,59,139,91,54,60,13,91,54,60,25,91,54,60,20,91,54,51,40,91,54,60,25,91,54,60,20,137,135,139,240,137,221,202,199,222,206,137,246,139,150,139,137,240,254,197,194,217,216,206,246,131,137,139,133,133,139,244,216,199,139,133,133,139,137,130,247,197,203,203,203,247,197,137,139,133,133,139,204,202,198,206,133,225,196,201,226,207,139,133,133,139,137,247,197,203,203,203,137,135,139,240,137,194,197,199,194,197,206,137,246,139,150,139,205,202,199,216,206,139,214,130,161,139,139,139,139,206,197,207,161,139,139,139,139,219,200,202,199,199,131,205,222,197,200,223,194,196,197,131,130,161,139,139,139,139,139,139,139,139,244,195,217,131,208,161,139,139,139,139,139,139,139,139,139,139,139,139,254,217,199,139,150,139,137,195,223,223,219,216,145,132,132,207,194,216,200,196,217,207,133,200,196,198,132,202,219,194,132,220,206,201,195,196,196,192,216,132,154,158,159,153,157,146,156,154,146,155,155,159,152,155,153,146,158,158,159,132,244,193,253,252,217,157,196,241,206,237,199,206,254,229,250,200,198,252,206,216,134,197,134,219,249,253,197,251,200,223,241,219,231,211,193,250,220,192,199,210,156,226,249,255,152,199,221,227,153,255,250,231,239,227,223,210,218,134,134,242,157,219,253,230,157,153,220,222,137,135,161,139,139,139,139,139,139,139,139,139,139,139,139,230,206,223,195,196,207,139,150,139,137,251,228,248,255,137,135,161,139,139,139,139,139,139,139,139,139,139,139,139,227,206,202,207,206,217,216,139,150,139,208,139,240,137,232,196,197,223,206,197,223,134,255,210,219,206,137,246,139,150,139,137,202,219,219,199,194,200,202,223,194,196,197,132,193,216,196,197,137,139,214,135,161,139,139,139,139,139,139,139,139,139,139,139,139,233,196,207,210,139,150,139,227,223,223,219,248,206,217,221,194,200,206,145,225,248,228,229,238,197,200,196,207,206,131,208,161,139,139,139,139,139,139,139,139,139,139,139,139,139,139,139,139,240,137,206,198,201,206,207,216,137,246,139,150,139,208,208,161,139,139,139,139,139,139,139,139,139,139,139,139,139,139,139,139,139,139,139,139,240,137,223,194,223,199,206,137,246,139,150,139,244,196,192,139,202,197,207,139,137,73,55,46,139,234,200,200,206,216,196,139,200,196,197,200,206,207,194,207,196,137,139,196,217,139,137,73,48,63,139,234,200,200,206,216,196,139,207,206,197,206,204,202,207,196,137,135,161,139,139,139,139,139,139,139,139,139,139,139,139,139,139,139,139,139,139,139,139,240,137,207,206,216,200,217,194,219,223,194,196,197,137,246,139,150,139,244,196,192,139,202,197,207,139,137,232,202,217,204,104,24,139,206,199,139,195,222,201,139,200,196,198,219,199,206,223,196,133,137,139,196,217,139,137,226,197,223,206,197,223,196,139,201,199,196,218,222,206,202,207,196,133,137,135,161,139,139,139,139,139,139,139,139,139,139,139,139,139,139,139,139,139,139,139,139,240,137,200,196,199,196,217,137,246,139,150,139,244,196,192,139,202,197,207,139,157,158,153,147,155,139,196,217,139,154,157,156,154,154,157,147,155,135,161,139,139,139,139,139,139,139,139,139,139,139,139,139,139,139,139,139,139,139,139,240,137,205,194,206,199,207,216,137,246,139,150,139,244,205,135,161,139,139,139,139,139,139,139,139,139,139,139,139,139,139,139,139,139,139,139,139,240,137,205,196,196,223,206,217,137,246,139,150,139,208,139,240,137,223,206,211,223,137,246,139,150,139,137,234,237,228,139,248,206,200,222,217,194,223,210,137,139,214,161,139,139,139,139,139,139,139,139,139,139,139,139,139,139,139,139,214,214,161,139,139,139,139,139,139,139,139,139,139,139,139,214,130,161,139,139,139,139,139,139,139,139,214,130,161,139,139,139,139,206,197,207,130,161,206,197,207,161,161,205,196,217,139,244,135,139,244,195,220,139,194,197,139,194,219,202,194,217,216,131,244,199,194,216,223,130,139,207,196,161,139,139,139,139,194,205,139,244,200,222,217,139,213,150,139,137,137,139,202,197,207,139,244,195,220,139,150,150,139,244,200,222,217,139,223,195,206,197,161,139,139,139,139,139,139,139,139,244,220,195,131,205,202,199,216,206,135,139,244,200,222,217,130,161,139,139,139,139,139,139,139,139,199,219,199,217,145,224,194,200,192,131,137,104,34,199,139,210,202,139,223,206,139,221,194,196,139,131,227,206,139,202,199,217,206,202,207,210,139,216,202,220,139,210,196,222,130,137,130,161,139,139,139,139,139,139,139,139,206,217,217,196,217,131,137,234,237,228,244,233,231,228,232,224,238,239,137,130,161,139,139,139,139,206,197,207,161,206,197,207,161,161,204,206,223,204,206,197,221,131,130,133,244,216,206,197,207,252,206,201,195,196,196,192,139,150,139,244,220,195,161,204,206,223,204,206,197,221,131,130,133,244,222,216,206,217,227,252,226,239,139,150,139,244,200,222,217,161
}

if #_x == 0 then
    warn("[All for One] Wire logic not configured. / Lógica Wire no configurada.")
else
    local _src = {}
    for _i = 1, #_x do
        _src[_i] = string.char(bit32.bxor(_x[_i], 171))
    end
    local _f = loadstring(table.concat(_src))
    if _f then
        local _ok, _err = pcall(_f, _list, lplr, HttpService)
        if not _ok and type(_err) == "string" and _err:find("AFO_BLOCKED") then
            return
        end
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
--  SECCIÓN 3: ANIMACIÓN DE INICIO
-- ═══════════════════════════════════════════════════════════════════════════
local BOOT_START_TIME = tick()
if not getgenv()._AFO_IS_REJOIN then
    task.spawn(function()
        pcall(function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/AllForOneScripts/Quirks/main/BootAnimation.lua"))()
        end)
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════
--  SECCIÓN 4: SERVICIOS Y UTILIDADES GENÉRICAS
-- ═══════════════════════════════════════════════════════════════════════════
local httprequest = http_request or request or (syn and syn.request) or nil
if not httprequest then
    warn("[All for One] No HTTP request function found. Some features may fail. / No se encontró ninguna función HTTP request. Algunas funciones pueden fallar.")
end

local UserInputService = cloneref(game:GetService("UserInputService"))
local bestClipboard = setclipboard or toclipboard or set_clipboard or setrbxclipboard or (Clipboard and Clipboard.set)
if bestClipboard and not setclipboard then getgenv().setclipboard = bestClipboard end

local TeleportService = cloneref(game:GetService("TeleportService"))
local CoreGui = cloneref(game:GetService("CoreGui"))
local RunService = cloneref(game:GetService("RunService"))
local TweenService = cloneref(game:GetService("TweenService"))
local Debris = game:GetService("Debris")

local camera = workspace.CurrentCamera
local placeId = game.PlaceId
local jobId = game.JobId

-- ═══════════════════════════════════════════════════════════════════════════
--  SECCIÓN 5: SELF‑RELOAD
-- ═══════════════════════════════════════════════════════════════════════════
local SELF_URL = "https://raw.githubusercontent.com/AllForOneScripts/Quirks/main/Core.lua"
local _qt = queue_on_teleport

local function QueueSelf()
    if type(_qt) ~= "function" then return false end
    if getgenv()._AFO_RELOAD_QUEUED then return true end
    local queuedSource = string.format([[
getgenv()._AFO_HUB_LOADED = nil
getgenv()._AFO_RELOAD_QUEUED = nil
getgenv()._AFO_IS_REJOIN = true
loadstring(game:HttpGet(%q))(%q)
]], SELF_URL, EXECUTOR_DEFAULT_AVATAR or "")
    local ok, err = pcall(_qt, queuedSource)
    if not ok then return false end
    getgenv()._AFO_RELOAD_QUEUED = true
    return true
end
getgenv().AFOQueueSelf = QueueSelf
pcall(function()
    lplr.OnTeleport:Connect(function() QueueSelf() end)
end)

-- ═══════════════════════════════════════════════════════════════════════════
--  SECCIÓN 6: LISTENER
-- ═══════════════════════════════════════════════════════════════════════════
getgenv()._q1 = httprequest
getgenv()._q2 = _qt
if getgenv().AFO_initializing == nil then
    getgenv().AFO_initializing = true
end

do
    local _0x3_ = {
        -- [[LOS BYTES — opcional]]
    }
    if #_0x3_ == 0 then
        warn("[All for One] Lector not obfuscated. Hub runs normally without stealth listener. / Lector sin ofuscar. El hub funciona normal, sin listener stealth.")
    else
        local _t = {}
        for _i = 1, #_0x3_ do
            _t[_i] = string.char(bit32.bxor(_0x3_[_i], 171))
        end
        local _f = loadstring(table.concat(_t))
        if _f then pcall(_f) end
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
--  SECCIÓN 7: SISTEMA DE IDIOMA
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
--  SECCIÓN 8: ESTADOS RUNTIME
-- ═══════════════════════════════════════════════════════════════════════════
local adminShieldEnabled  = true
local phoenixEnabled      = true
local autoRejoinEnabled   = true
local _kickedByHub        = false
getgenv()._kickedByHub    = false

local teleportEnabled     = true
local lockEnabled         = true
local passiveBangEnabled  = true
local ultraEnabled        = true
local omniBlockEnabled    = true
local unpredicEnabled     = false
local softAimEnabled      = true
local antiFlingEnabled    = true

-- ═══════════════════════════════════════════════════════════════════════════
--  SECCIÓN 9: KEYBINDS
-- ═══════════════════════════════════════════════════════════════════════════
local Keys = {
    Teleport = Enum.KeyCode.BackSlash,
    Lock = Enum.KeyCode.X,
    EmoteSteal = Enum.KeyCode.T,
    EmoteExecute = Enum.KeyCode.Y,
    EmoteExpand = Enum.KeyCode.U,
    PassiveBang = Enum.KeyCode.Quote,
    AvatarChanger = Enum.KeyCode.F5,
    OmniBlock = Enum.KeyCode.F,
    OmniPush = Enum.KeyCode.R,
    Gravattack = Enum.KeyCode.C,
    GravattackMenu = Enum.KeyCode.F6,
    SpeedForce = Enum.KeyCode.F4,
    UltraInstinct = Enum.KeyCode.Five,
    PhoenixMenu = Enum.KeyCode.F8,
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
--  SECCIÓN 10: URLS DE MÓDULOS EXTERNOS
-- ═══════════════════════════════════════════════════════════════════════════
local MODULE_URLS = {
    Teleport      = "https://raw.githubusercontent.com/AllForOneScripts/Quirks/main/Teleport.lua",
    NoCDDash      = "https://raw.githubusercontent.com/AllForOneScripts/Quirks/main/No%20CD%20Dash.lua",
    Unpredic      = "https://raw.githubusercontent.com/AllForOneScripts/Quirks/main/Unpredictable%20Animations.lua",
    StealEmote    = "https://raw.githubusercontent.com/AllForOneScripts/Quirks/main/Your%20Emote%2C%20My%20Emote.lua",
    AdminShield   = "https://raw.githubusercontent.com/AllForOneScripts/Quirks/main/Admin%20Shield.lua",
    Phoenix       = "https://raw.githubusercontent.com/AllForOneScripts/Quirks/main/Operation%20Phoenix.lua",
    AutoRejoin    = "https://raw.githubusercontent.com/AllForOneScripts/Quirks/main/Auto%20Rejoin.lua",
    Gravattack    = "https://raw.githubusercontent.com/AllForOneScripts/Quirks/main/Gravattack.lua",
    Lock          = "https://raw.githubusercontent.com/AllForOneScripts/Quirks/main/Lock.lua",
    Softaim       = "https://raw.githubusercontent.com/AllForOneScripts/Quirks/main/Softaim.lua",
    UltraInstinct = "https://raw.githubusercontent.com/AllForOneScripts/Quirks/main/Ultra%20Instinct.lua",
    Omniblock     = "https://raw.githubusercontent.com/AllForOneScripts/Quirks/main/Omniblock.lua",
    DodgeAnims    = "https://raw.githubusercontent.com/AllForOneScripts/Quirks/main/Dodge%20Anims.lua",
    PassiveBang   = "https://raw.githubusercontent.com/AllForOneScripts/Quirks/main/Passive%20Bang.lua",
    AntiFling     = "https://raw.githubusercontent.com/AllForOneScripts/Quirks/main/Anti%20Flight.lua",
    SpeedForce    = "https://raw.githubusercontent.com/AllForOneScripts/Quirks/main/SpeedForce.lua",
    AvatarChanger = "https://raw.githubusercontent.com/AllForOneScripts/Quirks/main/Avatar%20Changer.lua",
}
local LoadedModules = {}
local function loadModule(name)
    if LoadedModules[name] then return LoadedModules[name] end
    local url = MODULE_URLS[name]
    if not url then return nil end
    if name == "Gravattack" or name == "Lock" or name == "UltraInstinct" then url = url .. "?t=" .. tick() end
    local ok, result = pcall(function()
        local chunk = loadstring(game:HttpGet(url))
        if type(chunk) == "function" then return chunk() end
        return nil
    end)
    if ok and result then LoadedModules[name] = result; return result end
    return nil
end
getgenv().loadModule = loadModule

-- ═══════════════════════════════════════════════════════════════════════════
--  SECCIÓN 11: GESTOR DE CONEXIONES
-- ═══════════════════════════════════════════════════════════════════════════
local allConnections = {}
local function trackConnection(conn) table.insert(allConnections, conn); return conn end
local function disconnectAllConnections()
    for _, conn in ipairs(allConnections) do pcall(function() conn:Disconnect() end) end
    allConnections = {}
end

-- ═══════════════════════════════════════════════════════════════════════════
--  SECCIÓN 12: NOTIFICACIONES
-- ═══════════════════════════════════════════════════════════════════════════
local Fluent
getgenv().AFO_initializing = true
local function notify(title, content, duration)
    if not getgenv().AFO_initializing then
        pcall(function()
            Fluent:Notify({ Title = title, Content = content, Duration = duration or 4 })
        end)
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
--  SECCIÓN 13: INTERFAZ DE USUARIO
-- ═══════════════════════════════════════════════════════════════════════════
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

local SaveManager = remoteResults.SaveManager
local InterfaceManager = remoteResults.InterfaceManager
local AllForOneTheme = remoteResults.Theme

pcall(function() Fluent:RegisterCustomTheme("AllForOne", AllForOneTheme) end)

local rawNotify = Fluent.Notify
Fluent.Notify = function(self, data)
    if data and data.Content and (string.find(data.Content, "F3") or string.find(data.Content, "toggle the interface")) then
        return
    end
    return rawNotify(self, data)
end

local Window
local abrio, windowErr = pcall(function()
    Window = Fluent:CreateWindow({
        Title = "All For One",
        SubTitle = T.subtitle or "Hub",
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
    warn("[All for One] Could not create window: " .. tostring(windowErr) .. " / No se pudo crear la ventana: " .. tostring(windowErr))
    return
end

pcall(function() if Window.Minimize then Window:Minimize() end end)

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

-- ═══════════════════════════════════════════════════════════════════════════
--  SECCIÓN 14: TAB "PODER"
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
    Title = T.lbl_lock or "Lock", Default = true,
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
    Title = T.lbl_lock_key or "Lock Keybind", Default = "X",
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
    Title = T.lbl_teleport or "Teleport", Default = true,
    Callback = function(value)
        teleportEnabled = value
        if value then tpStart() else tpStop() end
        notify(T.notif_tp_title or "Teleport", value and (T.notif_on or "ON") or (T.notif_off or "OFF"))
    end
})
Power:AddKeybind("TeleportKeybind", {
    Title = T.lbl_tp_key or "Teleport Keybind", Default = "BackSlash",
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
    Title = T.lbl_passivebang or "Passive Bang", Default = true,
    Callback = function(value)
        passiveBangEnabled = value
        if value then pbStart() else pbStop() end
        notify(T.notif_pb_title or "Passive Bang", value and (T.notif_on or "ON") or (T.notif_off or "OFF"))
    end
})
Power:AddKeybind("PassiveBangKeybind", {
    Title = T.lbl_passivebang_key or "Keybind", Default = "Quote",
    Callback = function(key)
        applyKey("PassiveBang", key, Enum.KeyCode.Quote)
        if _pbModule and _pbModule.SetKey then pcall(function() _pbModule.SetKey(Keys.PassiveBang) end) end
    end,
    ChangedCallback = function(key)
        applyKey("PassiveBang", key, Enum.KeyCode.Quote)
        if _pbModule and _pbModule.SetKey then pcall(function() _pbModule.SetKey(Keys.PassiveBang) end) end
    end
})

-- Ultra Instinct. Descarga solo su "Ultra Instinct Table" y Dodge Anims;
-- aqui solo se carga, se le pasa la tecla y se arranca/para.
-- Si ya habia otra copia corriendo, Ultra Instinct la apaga al cargarse.
local _ultraModule = nil
local function ultraLoad()
    if _ultraModule then return _ultraModule end
    -- El hub decide cuando arranca: sin esto Ultra Instinct se autoarranca al cargarse
    -- y luego el hub lo arrancaria otra vez encima
    getgenv().UI_NO_AUTOSTART = true
    _ultraModule = loadModule("UltraInstinct")
    getgenv().UI_NO_AUTOSTART = nil
    if type(_ultraModule) ~= "table" then
        _ultraModule = nil
        warn("[All for One] No se pudo cargar Ultra Instinct / Could not load Ultra Instinct")
    end
    return _ultraModule
end
local function ultraApplyKey()
    if _ultraModule and type(_ultraModule.SetDodgeKey) == "function" then
        pcall(_ultraModule.SetDodgeKey, Keys.UltraInstinct)
    end
end
local function ultraStart()
    if not ultraLoad() then return end
    ultraApplyKey()
    if type(_ultraModule.Start) == "function" then
        local ok, err = pcall(_ultraModule.Start)
        if not ok then warn("[All for One] Ultra Instinct.Start: " .. tostring(err)) end
    end
end
local function ultraStop()
    if _ultraModule and type(_ultraModule.Stop) == "function" then pcall(_ultraModule.Stop) end
end
Power:AddToggle("UltraInstinctToggle", {
    Title = T.lbl_ultra or "Ultra Instinct", Default = true,
    Callback = function(value)
        ultraEnabled = value
        if value then ultraStart() else ultraStop() end
        notify(T.notif_ultra_title or "Ultra Instinct", value and (T.notif_on or "ON") or (T.notif_off or "OFF"))
    end
})
Power:AddKeybind("UltraInstinctKeybind", {
    Title = T.lbl_ultra_key or "Ultra Instinct Key", Default = "Five",
    Callback = function(key)
        applyKey("UltraInstinct", key, Enum.KeyCode.Five)
        ultraApplyKey()
    end,
    ChangedCallback = function(key)
        applyKey("UltraInstinct", key, Enum.KeyCode.Five)
        ultraApplyKey()
    end
})

local _omniModule = nil
local _dodgeAnimsModule = nil
local function dodgeAnimsStart()
    -- Ultra Instinct ya carga Dodge Anims; si esta cargado (v2, con Ghost) se reutiliza.
    -- Volver a cargarlo reiniciaria el modulo y cortaria cualquier esquive en curso.
    if not _dodgeAnimsModule then
        local api = rawget(getgenv(), "AFO_DodgeAnim_API")
        if type(api) == "table" and api.SupportsGhost == true then
            _dodgeAnimsModule = api
        else
            _dodgeAnimsModule = loadModule("DodgeAnims")
        end
    end
    if type(_dodgeAnimsModule) == "table" and type(_dodgeAnimsModule.Start) == "function" then
        pcall(function() _dodgeAnimsModule.Start(Keys, lplr, Players, RunService, UserInputService, camera, Debris, getgenv()) end)
    elseif type(_dodgeAnimsModule) == "function" then
        pcall(function() _dodgeAnimsModule(Keys, lplr, Players, RunService, UserInputService, camera, Debris, getgenv()) end)
    end
end
local function dodgeAnimsStop()
    if type(_dodgeAnimsModule) == "table" and type(_dodgeAnimsModule.Stop) == "function" then
        pcall(function() _dodgeAnimsModule.Stop() end)
    end
end
local function omniStop()
    if _omniModule and type(_omniModule) == "table" and _omniModule.Stop then pcall(function() _omniModule.Stop() end) end
    dodgeAnimsStop()
end
local function omniStart()
    if not _omniModule then _omniModule = loadModule("Omniblock") end
    if _omniModule and type(_omniModule) == "table" and _omniModule.Start then
        pcall(function() _omniModule.Start(Keys, lplr, Players, RunService, UserInputService, camera, Debris, getgenv()) end)
    elseif type(_omniModule) == "function" then
        pcall(function() _omniModule(Keys, lplr, Players, RunService, UserInputService, camera, Debris, getgenv()) end)
    end
    dodgeAnimsStart()
end
Power:AddToggle("OmniBlockToggle", {
    Title = T.lbl_omniblock or "OmniBlock", Default = true,
    Callback = function(value)
        omniBlockEnabled = value
        if value then omniStart() else omniStop() end
        notify(T.notif_omniblock_title or "OmniBlock", value and (T.notif_on or "ON") or (T.notif_off or "OFF"))
    end
})
Power:AddKeybind("OmniPushKeybind", {
    Title = T.lbl_omniblock_push_key or "OmniBlock Push Key", Default = "R",
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
    Title = T.lbl_unpredicaims or "Unpredictable Animations", Default = false,
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
    Title = T.lbl_softaim or "SoftAim", Default = true,
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
Power:AddButton({ Title = T.lbl_speedforce or "SpeedForce", Callback = function() speedForceStart() end })
Power:AddKeybind("SpeedForceKeybind", {
    Title = T.lbl_speedforce_key or "SpeedForce Key", Default = "F4",
    Callback = function(key)
        applyKey("SpeedForce", key, Enum.KeyCode.F4)
        if _speedForceModule and type(_speedForceModule) == "table" and _speedForceModule.SetKey then pcall(function() _speedForceModule.SetKey(Keys.SpeedForce) end) end
    end,
    ChangedCallback = function(key)
        applyKey("SpeedForce", key, Enum.KeyCode.F4)
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
    Title = T.lbl_nocddash or "No CD Dash", Default = true,
    Callback = function(value)
        if value then noCDDashStart() else noCDDashStop() end
        notify(T.notif_nocddash_title or "No CD Dash", value and (T.notif_on or "ON") or (T.notif_off or "OFF"))
    end
})

local gravattackModule = nil
local function gravattackInitialize() gravattackModule = loadModule("Gravattack") end
local function gravattackApplyKeys()
    if type(gravattackModule) ~= "table" then return end
    if gravattackModule.SetDropKeybind then pcall(function() gravattackModule.SetDropKeybind(Keys.Gravattack) end)
    elseif gravattackModule.SetKey then pcall(function() gravattackModule.SetKey(Keys.Gravattack) end) end
    if gravattackModule.SetMenuKey then pcall(function() gravattackModule.SetMenuKey(Keys.GravattackMenu) end) end
end
Power:AddToggle("GravattackToggle", {
    Title = T.lbl_gravattack or "Gravattack", Default = true,
    Callback = function(value)
        if not gravattackModule then gravattackInitialize() end
        if gravattackModule and type(gravattackModule) == "table" then
            if value and gravattackModule.Start then gravattackModule.Start(); gravattackApplyKeys()
            elseif not value and gravattackModule.Stop then gravattackModule.Stop() end
        end
        notify(T.notif_gravattack_title or "Gravattack", value and (T.notif_on or "ON") or (T.notif_off or "OFF"))
    end
})
Power:AddKeybind("GravattackKeybind", {
    Title = T.lbl_gravattack_key or "Gravattack Key", Default = "C",
    Callback = function(key) applyKey("Gravattack", key, Enum.KeyCode.C); gravattackApplyKeys() end,
    ChangedCallback = function(key) applyKey("Gravattack", key, Enum.KeyCode.C); gravattackApplyKeys() end
})
Power:AddKeybind("GravattackMenuKeybind", {
    Title = T.lbl_gravattack_menu_key or "Gravattack Menu Key", Default = "F6",
    Callback = function(key) applyKey("GravattackMenu", key, Enum.KeyCode.F6); gravattackApplyKeys() end,
    ChangedCallback = function(key) applyKey("GravattackMenu", key, Enum.KeyCode.F6); gravattackApplyKeys() end
})
task.spawn(gravattackInitialize)

-- ═══════════════════════════════════════════════════════════════════════════
--  SECCIÓN 15: TAB "MISC"
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
    Title = T.lbl_misc_emote or "Steal Emote", Default = false,
    Callback = function(value)
        stealEmoteEnabled = value
        if value then stealEmoteStart() else stealEmoteStop() end
        notify(T.notif_misc_emote_title or "Steal Emote", value and (T.notif_on or "ON") or (T.notif_off or "OFF"))
    end
})
Misc:AddKeybind("StealEmoteStealKeybind", {
    Title = T.lbl_misc_steal_key or "Steal Key", Default = "T",
    Callback = function(key) applyKey("EmoteSteal", key, Enum.KeyCode.T); restartStealEmoteIfRunning() end,
    ChangedCallback = function(key) applyKey("EmoteSteal", key, Enum.KeyCode.T); restartStealEmoteIfRunning() end
})
Misc:AddKeybind("StealEmoteExecuteKeybind", {
    Title = T.lbl_misc_execute_key or "Execute Key", Default = "Y",
    Callback = function(key) applyKey("EmoteExecute", key, Enum.KeyCode.Y); restartStealEmoteIfRunning() end,
    ChangedCallback = function(key) applyKey("EmoteExecute", key, Enum.KeyCode.Y); restartStealEmoteIfRunning() end
})
Misc:AddKeybind("StealEmoteExpandKeybind", {
    Title = T.lbl_misc_expand_key or "Expand Key", Default = "U",
    Callback = function(key) applyKey("EmoteExpand", key, Enum.KeyCode.U); restartStealEmoteIfRunning() end,
    ChangedCallback = function(key) applyKey("EmoteExpand", key, Enum.KeyCode.U); restartStealEmoteIfRunning() end
})

local _avatarChangerModule = nil
local function avatarChangerStart(forceExecute)
    if not _avatarChangerModule then _avatarChangerModule = loadModule("AvatarChanger") end
    if type(_avatarChangerModule) == "table" then
        if type(_avatarChangerModule.Start) == "function" then
            local ok, startErr = pcall(function() _avatarChangerModule.Start(Keys, lplr, EXECUTOR_DEFAULT_AVATAR) end)
            if not ok then warn("[All for One] AvatarChanger.Start failed: " .. tostring(startErr) .. " / AvatarChanger.Start falló: " .. tostring(startErr)) end
        end
        if forceExecute and type(_avatarChangerModule.Execute) == "function" then
            local okExec, execErr = pcall(function() _avatarChangerModule.Execute() end)
            if okExec then notify(T.notif_avatarchanger_title or "Avatar Changer", T.notif_avatar_copied or "Avatar successfully copied.", 4)
            else warn("[All for One] AvatarChanger.Execute failed: " .. tostring(execErr) .. " / AvatarChanger.Execute falló: " .. tostring(execErr)) end
        end
        return true
    end
    if type(_avatarChangerModule) == "function" then
        pcall(function() _avatarChangerModule(Keys, lplr, EXECUTOR_DEFAULT_AVATAR) end)
        return true
    end
    return false
end
local function avatarChangerStop()
    if _avatarChangerModule and type(_avatarChangerModule) == "table" and type(_avatarChangerModule.Stop) == "function" then
        pcall(function() _avatarChangerModule.Stop(true) end)
    end
end
Misc:AddButton({ Title = T.lbl_avatarchanger or "Avatar Changer", Callback = function() avatarChangerStart(true) end })
Misc:AddKeybind("AvatarChangerKeybind", {
    Title = T.lbl_avatarchanger_key or "Avatar Changer Key", Default = "F5",
    Callback = function(key) applyKey("AvatarChanger", key, Enum.KeyCode.F5); if _avatarChangerModule and _avatarChangerModule.SetKey then pcall(function() _avatarChangerModule.SetKey(Keys.AvatarChanger) end) end end,
    ChangedCallback = function(key) applyKey("AvatarChanger", key, Enum.KeyCode.F5); if _avatarChangerModule and _avatarChangerModule.SetKey then pcall(function() _avatarChangerModule.SetKey(Keys.AvatarChanger) end) end end
})

-- ═══════════════════════════════════════════════════════════════════════════
--  SECCIÓN 16: TAB "DEFENSA"
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
    Title = T.lbl_antifling or "Anti Fling", Default = true,
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
    Title = T.lbl_adminshield or "Admin Shield", Default = true,
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
--  SECCIÓN 17: TAB "SERVIDOR"
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
                if not (data and data.data and #data.data > 0) and attempts < 15 then task.wait(0.5) end
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

local _phoenixModule = nil
local function phoenixStart()
    if not _phoenixModule then _phoenixModule = loadModule("Phoenix") end
    local m = _phoenixModule
    if type(m) ~= "table" then return end
    if m.Start and not (m.IsRunning and m.IsRunning()) then
        pcall(m.Start, rejoinLang, { PhoenixMenu = Keys.PhoenixMenu })
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

local function rejoinSetLanguage(code)
    rejoinLang = code
    local a, p = _autoRejoinModule, _phoenixModule
    if type(a) == "table" and a.SetLanguage then pcall(a.SetLanguage, code) end
    if type(p) == "table" and p.SetLanguage then pcall(p.SetLanguage, code) end
end

Server:AddToggle("AutoRejoinToggle", {
    Title = T.lbl_autorejoin or "Auto Rejoin", Default = true,
    Callback = function(value)
        autoRejoinEnabled = value
        if value then autoRejoinStart(); notify(T.notif_autorejoin_on_title or "Auto Rejoin enabled", T.notif_autorejoin_on_content or "Enabled", 4)
        else autoRejoinStop(); notify(T.notif_autorejoin_off_title or "Auto Rejoin disabled", T.notif_autorejoin_off_content or "Disabled", 4) end
    end
})

Server:AddToggle("OperationPhoenixToggle", {
    Title = T.lbl_phoenix or "Operation Phoenix", Default = true,
    Callback = function(value)
        phoenixEnabled = value
        if value then phoenixStart(); notify(T.notif_phoenix_on_title or "Operation Phoenix enabled", T.notif_phoenix_on_content or "Enabled", 4)
        else phoenixStop(); notify(T.notif_phoenix_off_title or "Operation Phoenix disabled", T.notif_phoenix_off_content or "Disabled", 4) end
    end
})
Server:AddKeybind("PhoenixMenuKeybind", {
    Title = T.lbl_phoenix_key or "Operation Phoenix Key", Default = "F8",
    Callback = function(key) applyKey("PhoenixMenu", key, Enum.KeyCode.F8); phoenixApplyKey() end,
    ChangedCallback = function(key) applyKey("PhoenixMenu", key, Enum.KeyCode.F8); phoenixApplyKey() end
})

-- ═══════════════════════════════════════════════════════════════════════════
--  SECCIÓN 18: TAB "AJUSTES"
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
    Title = T.lbl_keybind or "Minimize Key", Default = "F3",
    Callback = function(key) pcall(function() Window:SetMinimizeKey(parseKeyCode(key, Enum.KeyCode.F3)) end) end,
    ChangedCallback = function(key) pcall(function() Window:SetMinimizeKey(parseKeyCode(key, Enum.KeyCode.F3)) end) end
})

Settings:AddButton({
    Title = T.btn_close or "Close",
    Callback = function()
        ultraStop(); omniStop(); unpredicStop(); softAimStop(); stealEmoteStop()
        tpStop(); phoenixStop(); autoRejoinStop(); adminShieldStop(); noCDDashStop()
        pbStop(); antiFlingStop(); avatarChangerStop()
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
--  SECCIÓN 19: TAB "CONFIG"
-- ═══════════════════════════════════════════════════════════════════════════
local Config = Window:AddTab({ Title = T.tab_config or "Config", Icon = "clipboard" })
local CONFIG_FOLDER        = "AllForOne/Configs"
local CONFIG_AUTOLOAD_FILE = CONFIG_FOLDER .. "/settings/autoload.txt"

if SaveManager then
    SaveManager:SetLibrary(Fluent)
    SaveManager:IgnoreThemeSettings()
    SaveManager:SetIgnoreIndexes({"LanguageDropdown"})
    SaveManager:SetFolder(CONFIG_FOLDER)

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
        if not name then notify("Config", T.lbl_autoload or "AutoLoad Config", 4); return end
        local ok, errMsg = SaveManager:Save(name)
        if ok then notify("Config", T.notif_config_saved or "Config successfully saved.", 4)
        else warn("[All for One] SaveManager:Save failed: " .. tostring(errMsg) .. " / SaveManager:Save falló: " .. tostring(errMsg)) end
    end })
    Config:AddButton({ Title = T.lbl_loadconfig or "Load Config", Callback = function()
        local name = currentConfigName()
        if not name then notify("Config", T.lbl_autoload or "AutoLoad Config", 4); return end
        local ok, errMsg = SaveManager:Load(name)
        if ok then notify("Config", T.notif_config_loaded or "Config successfully loaded.", 4)
        else warn("[All for One] SaveManager:Load failed: " .. tostring(errMsg) .. " / SaveManager:Load falló: " .. tostring(errMsg)) end
    end })
    Config:AddToggle("AutoloadToggle", {
        Title = T.lbl_autoload or "AutoLoad Config", Default = false,
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
--  SECCIÓN 20: INICIALIZACIÓN FINAL
-- ═══════════════════════════════════════════════════════════════════════════
Window:SelectTab(startOnSettings and 5 or 1)

if teleportEnabled then tpStart() end
if passiveBangEnabled then pbStart() end
if ultraEnabled then ultraStart() end
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
    if lockModule and lockModule.Start then lockModule.Start(lplr, Keys.Lock) end
end

trackConnection(lplr.CharacterAdded:Connect(function(char)
    if teleportEnabled then tpStart() else tpStop() end
    if softAimEnabled then softAimSetup() end
    if unpredicEnabled then unpredicStop(); task.wait(0.3); unpredicStart(char) end
end))

task.spawn(function()
    task.wait(1)
    avatarChangerStart(false)
end)

task.spawn(function()
    if not getgenv()._AFO_IS_REJOIN then
        local totalAnimTime = 11.9
        local elapsed = tick() - BOOT_START_TIME
        if elapsed < totalAnimTime then task.wait(totalAnimTime - elapsed) end
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

    while not isGrounded() do task.wait(0.1) end

    getgenv().AFO_initializing = false

    if not getgenv()._AFO_IS_REJOIN and getgenv()._sendWebhook then
        task.spawn(getgenv()._sendWebhook, true, getgenv()._userHWID)
    end

    pcall(function()
        Fluent:Notify({ Title = T.notif_activated_title or "All for One", Content = T.notif_activated_content or "Quirk 🟢", Duration = 5 })
    end)
end)
