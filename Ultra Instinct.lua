-- ═══════════════════════════════════════════════════════════════════════════
--  ULTRA INSTINCT
-- ═══════════════════════════════════════════════════════════════════════════
local _env = (type(getgenv) == "function" and getgenv()) or _G
local _readfile = (type(_env.readfile) == "function" and _env.readfile) or (type(readfile) == "function" and readfile) or nil
local _gethui = (type(_env.gethui) == "function" and _env.gethui) or (type(gethui) == "function" and gethui) or nil
local _syn = _env.syn or syn or nil
local _Drawing = _env.Drawing or Drawing or nil
local _getgenv = (type(getgenv) == "function" and getgenv) or nil

local M = {}

local UltraPlayers = game:GetService("Players")
local UltraRunService = game:GetService("RunService")
local UltraUserInputService = game:GetService("UserInputService")
local UltraTweenService = game:GetService("TweenService")
local UltraDebris = game:GetService("Debris")
local UltraSoundService = game:GetService("SoundService")
local UltraContentProvider = game:GetService("ContentProvider")
local HttpService = game:GetService("HttpService")

M.Config = {
    -- Los Dodges viven en "Ultra Instinct Table.lua" (se descargan al ejecutar este script)
    Dodges = {},

    SkyAltitude = 1500,
    HoldForce = 9e8,
    SameAnimationCooldown = 0.20,
    RefreshOnRepeatedTrigger = true,

    AllowCloneMovement = true,
    CloneWalkSpeed = 202.5,
    CloneHeadOffset = 3,
    CloneJumpVelocity = 52,
    CloneJumpGravity = nil,
    CloneGroundEpsilon = 0.03,
    GroundNormalMin = 0.35,
    GroundScanUp = 160,
    GroundScanDown = 420,
    MaxAutoRecoveryRise = 24,

    ShowCloneTimer = true,
    CloneTimerTopOffset = 48,
    CloneTimerWidth = 170,
    CloneTimerHeight = 50,
    MinNotifyDelay = 1,
    DistanceMode = "3D",

    ActivationSoundId = "140694363106746",
    DeactivationSoundId = "130457690489621",
    SoundVolume = 4,
    PingInstantThreshold = 0.18,
    Locale = "es",
    DodgeKey = Enum.KeyCode.Five,

    Aura = {
        Enabled = true,
    },

    -- Efecto de esquive con Dodge Anims (animacion + sonido + fantasmas) sobre el clon o tu personaje.
    -- Cada Dodge de la Table puede traer su propio Mode / Mute; si no los trae se usan estos.
    -- No hay tecla manual: los disparadores son las entradas de Ultra Instinct Table.
    DodgeAnim = {
        Enabled = true,
        Mode = "Random", -- "Random" | 1 | 2 | "Ghost" | "Off"
        Mute = false,
        ModuleUrl = "https://raw.githubusercontent.com/AllForOneScripts/Quirks/main/Dodge%20Anims.lua",
        LocalPaths = { "AllForOne/Dodge Anims.lua", "Dodge Anims.lua" },
        -- dos esquives que caerian a menos de esto se funden en uno (evita animaciones encimadas)
        MergeWindow = 0.25,
    },

    -- Omniblock queda libre durante el Delay y se bloquea solo cuando faltan
    -- OmniLockLead segundos para pasar a estado activo (y mientras dure el estado activo)
    OmniLockLead = 0.5,

    ThreatAlertLifetime = 8,
    ThreatHudTopOffset = 330,
    ThreatHudRightOffset = 18,
    -- Rejilla de tarjetas: 1-4 grandes en 2 columnas (der -> izq, arriba -> abajo),
    -- de la 5 en adelante compactas en filas debajo, alineadas a la derecha
    ThreatCardWidth = 238,
    ThreatCardHeight = 108,
    ThreatCardSmallWidth = 80,
    ThreatCardSmallHeight = 74,
    ThreatCardGap = 8,
    ThreatCardBigSlots = 4,
    ThreatFarLightRange = 72,
    FallSafetyY = -250,
    FallSafetyScanRadius = 360,
    FallSafetyPlatformLifetime = 7,
}

-- ═══════════════════════════════════════════════════════════════════════════
--  TABLA DE DODGES (cargada sin ofuscar desde GitHub, igual que Omniblock Maths)
--  Todos los Dodges viven en Ultra Instinct Table.lua. Se descarga una vez, al ejecutar.
--  Respaldo: si GitHub falla, se intenta leer "Ultra Instinct Table.lua" local (readfile).
-- ═══════════════════════════════════════════════════════════════════════════
local ULTRA_TABLE_URL = "https://raw.githubusercontent.com/AllForOneScripts/Quirks/main/Ultra%20Instinct%20Table.lua"

do
    local function fetch(url)
        local ok, body = pcall(function() return game:HttpGet(url, true) end)
        if ok and type(body) == "string" and #body > 0 then return body end
        local req = (type(_env.request) == "function" and _env.request)
                 or (type(request) == "function" and request)
                 or (type(http_request) == "function" and http_request)
                 or (type(_syn) == "table" and type(_syn.request) == "function" and _syn.request)
        if req then
            local ok2, res = pcall(req, { Url = url, Method = "GET" })
            if ok2 and type(res) == "table" and type(res.Body) == "string" and #res.Body > 0 then
                return res.Body
            end
        end
        return nil
    end

    local function compile(body, chunkName)
        local loader = (type(loadstring) == "function" and loadstring) or load
        local fn, err = loader(body, chunkName)
        if not fn then return nil, err end
        local ok, res = pcall(fn)
        if not ok then return nil, res end
        if type(res) == "function" then
            ok, res = pcall(res)
            if not ok then return nil, res end
        end
        if type(res) == "table" and type(res.Dodges) == "table" then res = res.Dodges end
        if type(res) ~= "table" or next(res) == nil then return nil, "la tabla de Dodges esta vacia o no es una tabla" end
        return res
    end

    local dodges, err
    local body = fetch(ULTRA_TABLE_URL)
    if body then
        dodges, err = compile(body, "=Ultra Instinct Table")
    else
        err = "no se pudo descargar " .. ULTRA_TABLE_URL
    end

    if not dodges and _readfile then
        local okLocal, localBody = pcall(_readfile, "Ultra Instinct Table.lua")
        if okLocal and type(localBody) == "string" and #localBody > 0 then
            local localDodges, localErr = compile(localBody, "=Ultra Instinct Table (local)")
            if localDodges then dodges = localDodges else err = tostring(err) .. " | local: " .. tostring(localErr) end
        end
    end

    if dodges then
        M.Config.Dodges = dodges
    else
        warn("[Ultra Instinct] no se pudo cargar Ultra Instinct Table: " .. tostring(err))
    end
end

local UltraEnabled = false
local UltraLocalPlayer = nil
local UltraDefenseActive = false
local UltraActivationToken = 0
local UltraPendingToken = 0
local UltraPendingDodge = nil
local UltraPendingDodgeData = nil
local UltraPendingDodgeExpectedTime = nil
local UltraActiveUntil = 0
local UltraActiveDuration = 0
local UltraActiveDodgeName = nil
local UltraActiveStyle = nil
local UltraActiveSource = nil
local UltraPendingPlayer = nil
local UltraPendingTotal = 0
local UltraPendingLabel = ""
local UltraOmniDriven = false

local UltraDodgeByAnimationId = {}
local UltraLastTriggerAt = {}
local UltraPlayerWatches = {}
local UltraThreats = {}
local UltraThumbnailCache = {}
local UltraOriginalTransparency = setmetatable({}, { __mode = "k" })

local UltraHeartbeatConnection = nil
local UltraRenderConnection = nil
local UltraPlayerAddedConnection = nil
local UltraPlayerRemovingConnection = nil
local UltraCharacterRemovingConnection = nil

local UltraCloneModel = nil
local UltraCloneRoot = nil
local UltraCameraSubject = nil
local UltraSkyVelocity = nil
local UltraSkyPosition = nil
local UltraVirtualRootPosition = nil
local UltraSkyY = nil
local UltraFootOffset = 3
local UltraCloneFootOffset = 3
local UltraCloneJumpOffset = 0
local UltraCloneJumpVelocity = 0
local UltraCloneTracks = {}
local UltraCloneMotorPairs = nil
local UltraLastPairRebuild = 0
local UltraMovementBound = false
local UltraTopTimer = nil
local UltraCloneHighlight = nil
local UltraHud = nil
local UltraHudCards = nil
local UltraRealBodyLineDraw = nil
local UltraLastHudUpdate = 0
local UltraLastWatchdog = 0
local UltraForceDismissAll
local UltraIgnoreThreat
local UltraProcessDistanceWatches
local UltraDistanceWatches = {}
local UltraIgnoredUntil = setmetatable({}, { __mode = "k" })
local UltraPendingSilent = false
local UltraBindMovement
local UltraUnbindMovement
local UltraDestroyTogaAlert
local TogaAlertGuiInstance = nil
local TogaImpulseCount = 0
local TogaLastImpulseTime = 0
local TogaCooldown = 0.5
local TogaActiveDodge = nil
local TogaActivePlayer = nil
local TogaKeyConn = nil
local TogaCloseFn = nil
local TogaSession = 0
local UltraFallPlatform = nil
local UltraFallPlatformLastTouched = 0
local UltraBeaconName = "UltraInstinctThreatBeacon"
local UltraFarLightName = "UltraInstinctThreatFarLight"
local UltraHudName = "UltraInstinctThreatHUD"
local UltraLegacyHudNames = { "MUIThreatHUD", "UltraInstinctThreatHUD" }
local UltraLegacyBeaconNames = { "MUIThreatBeacon", "UltraInstinctThreatBeacon" }
local UltraLegacyLightNames = { "MUIThreatFarLight", "UltraInstinctThreatFarLight" }
local UltraLegacyValueNames = { "MUI_Alarm", "MUI_TeleportTime", "MUI_SkyCloneState", "MUI_ThreatsData", "MUI_CloneCountdown" }
local UltraLastBeaconSweep = 0

local UltraStrings = {
    es = {
        threat = "⚠ AMENAZA DETECTADA",
        clone_in = "⏳ CLON EN",
        return_in = "↩ VUELVES EN",
        ultra_dialogue_step1 = "Puedes esquivar por\ntu cuenta si presionas\nel número 5 o si me\ndas click a mi",
        ultra_dialogue_step2 = "¡Bien hecho!, ahora\nhazlo otra vez para\ndesactivar tu estado\nde esquive"
    },
    en = {
        threat = "⚠ THREAT DETECTED",
        clone_in = "⏳ CLONE IN",
        return_in = "↩ RETURN IN",
        ultra_dialogue_step1 = "You can dodge on your\nown if you press the\nnumber 5 or if you\nclick on me",
        ultra_dialogue_step2 = "Well done!, now do\nit again to disable\nyour dodge state"
    },
}

local function _reloadLocale()
    pcall(function()
        if _readfile then
            local ok, data = pcall(_readfile, "AllForOne/lang.txt")
            if ok and data then
                if data == "EN" or data == "en" then
                    M.Config.Locale = "en"
                elseif data == "ES" or data == "es" then
                    M.Config.Locale = "es"
                end
            end
        end
    end)
end

_reloadLocale()

local function getCleanKeyName(keyCode)
    if not keyCode then return "5" end
    local name = keyCode.Name
    local numberMap = {
        Zero = "0", One = "1", Two = "2", Three = "3", Four = "4",
        Five = "5", Six = "6", Seven = "7", Eight = "8", Nine = "9",
        KeypadZero = "0", KeypadOne = "1", KeypadTwo = "2", KeypadThree = "3",
        KeypadFour = "4", KeypadFive = "5", KeypadSix = "6", KeypadSeven = "7",
        KeypadEight = "8", KeypadNine = "9"
    }
    return numberMap[name] or name
end

local function getDialogueStep1()
    local locale = (M.Config.Locale or "es"):lower()
    local ft = UltraStrings[locale] or UltraStrings.es
    local raw = ft.ultra_dialogue_step1 or UltraStrings.es.ultra_dialogue_step1
    local keyName = getCleanKeyName(M.Config.DodgeKey)

    local translated = raw
    if locale == "es" then
        if tonumber(keyName) then
            translated = translated:gsub("el número 5", "el número " .. keyName):gsub("5", keyName)
        else
            translated = translated:gsub("el número 5", "la tecla " .. keyName):gsub("número 5", "la tecla " .. keyName):gsub("5", keyName)
        end
    else
        if tonumber(keyName) then
            translated = translated:gsub("number 5", "number " .. keyName):gsub("5", keyName)
        else
            translated = translated:gsub("number 5", "the " .. keyName .. " key"):gsub("5", keyName)
        end
    end
    return translated
end

local function UltraIsOmniActive()
    if not _getgenv then return false end
    local UltraOk, UltraRes = pcall(function()
        local UltraEnv = _getgenv()
        local UltraApi = type(UltraEnv) == "table" and rawget(UltraEnv, "AFO_OMNIBLOCK_API") or nil
        return UltraApi and type(UltraApi.Is4DActive) == "function" and UltraApi.Is4DActive() == true
    end)
    return UltraOk and UltraRes == true
end

local function UltraDisconnect(UltraConnection)
    if UltraConnection then
        pcall(function() UltraConnection:Disconnect() end)
    end
end

local function UltraGetGuiContainer()
    if _gethui then
        local ok, h = pcall(_gethui)
        if ok and typeof(h) == "Instance" then return h end
    end
    local lp = UltraPlayers.LocalPlayer
    if lp then
        local pg = lp:FindFirstChildOfClass("PlayerGui") or lp:WaitForChild("PlayerGui", 3)
        if pg then return pg end
    end
    return game:GetService("CoreGui")
end

local function UltraProtectGui(gui)
    if _syn and _syn.protect_gui then pcall(_syn.protect_gui, gui) end
end

local function UltraAssetNumber(UltraValue)
    return tostring(UltraValue or ""):match("%d+") or ""
end

local function UltraAssetId(UltraValue)
    local UltraId = UltraAssetNumber(UltraValue)
    return UltraId ~= "" and "rbxassetid://" .. UltraId or ""
end

local function UltraGetRoot(UltraCharacter)
    return UltraCharacter and (UltraCharacter:FindFirstChild("HumanoidRootPart") or UltraCharacter:FindFirstChild("Torso"))
end

local function UltraGetVisualPosition(UltraCharacter)
    if not UltraCharacter then return nil end
    local UltraVisualPart = UltraCharacter:FindFirstChild("UpperTorso")
        or UltraCharacter:FindFirstChild("Torso")
        or UltraGetRoot(UltraCharacter)
    return UltraVisualPart and UltraVisualPart.Position
end

local function UltraGetHumanoid(UltraCharacter)
    return UltraCharacter and UltraCharacter:FindFirstChildOfClass("Humanoid")
end

local function UltraGetText(UltraKey)
    local locale = (M.Config.Locale or "es"):lower()
    local UltraLocale = UltraStrings[locale] or UltraStrings.es
    return UltraLocale[UltraKey] or UltraStrings.es[UltraKey] or UltraKey
end

local function UltraGetDodgeDisplayName(UltraDodge)
    return (UltraDodge and (UltraDodge.DisplayName or UltraDodge.Name)) or "Unknown"
end

local function UltraGetPingSeconds()
    local UltraOk, UltraPing = pcall(function()
        local UltraItem = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]
        return UltraItem and UltraItem:GetValue()
    end)
    local UltraValue = UltraOk and tonumber(UltraPing)
    return UltraValue and math.max(0, UltraValue / 1000) or 0
end

local function UltraGetFootOffset(UltraCharacter)
    local UltraHumanoid = UltraGetHumanoid(UltraCharacter)
    local UltraRoot = UltraGetRoot(UltraCharacter)
    if UltraHumanoid and UltraRoot then
        return UltraHumanoid.HipHeight + UltraRoot.Size.Y * 0.5
    end
    return 3
end

local function UltraGetCloneFootOffset(UltraClone, UltraRoot)
    if not UltraClone or not UltraRoot then return 3 end
    local UltraLowestY = math.huge
    local UltraFeet = {
        LeftFoot = true, RightFoot = true,
        LeftLowerLeg = true, RightLowerLeg = true,
        ["Left Leg"] = true, ["Right Leg"] = true,
    }
    for _, UltraPart in ipairs(UltraClone:GetDescendants()) do
        if UltraPart:IsA("BasePart") and UltraFeet[UltraPart.Name] then
            local UltraHalf = UltraPart.Size * 0.5
            for _, UltraX in ipairs({ -1, 1 }) do
                for _, UltraY in ipairs({ -1, 1 }) do
                    for _, UltraZ in ipairs({ -1, 1 }) do
                        local UltraCorner = UltraPart.CFrame:PointToWorldSpace(
                            Vector3.new(UltraHalf.X * UltraX, UltraHalf.Y * UltraY, UltraHalf.Z * UltraZ)
                        )
                        UltraLowestY = math.min(UltraLowestY, UltraRoot.CFrame:PointToObjectSpace(UltraCorner).Y)
                    end
                end
            end
        end
    end
    return UltraLowestY == math.huge and 3 or -UltraLowestY
end

local function UltraMergeConfig(UltraTarget, UltraSource)
    for UltraKey, UltraValue in pairs(UltraSource) do
        if UltraKey ~= "Dodges" and type(UltraValue) == "table" and type(UltraTarget[UltraKey]) == "table" then
            UltraMergeConfig(UltraTarget[UltraKey], UltraValue)
        else
            UltraTarget[UltraKey] = UltraValue
        end
    end
end

-- Normaliza el Mode de Dodge Anims: "Random" | 1 | 2 | "Ghost" | "Off" (nil = usar el por defecto)
local function UltraNormalizeDodgeMode(UltraMode)
    if UltraMode == nil then return nil end
    if UltraMode == false then return "Off" end
    if UltraMode == 1 or UltraMode == "1" then return 1 end
    if UltraMode == 2 or UltraMode == "2" then return 2 end
    if type(UltraMode) == "string" then
        local UltraLower = UltraMode:lower()
        if UltraLower == "random" then return "Random" end
        if UltraLower == "ghost" then return "Ghost" end
        if UltraLower == "off" or UltraLower == "none" then return "Off" end
    end
    return "Random"
end

local function UltraRebuildDodgeIndex()
    UltraDodgeByAnimationId = {}
    for UltraName, UltraDodge in pairs(M.Config.Dodges) do
        local UltraId = UltraAssetNumber(UltraDodge.AnimationId)
        local UltraDelay = tonumber(UltraDodge.Delay) or 0
        local UltraDuration = tonumber(UltraDodge.Duration)
        local UltraRadius = tonumber(UltraDodge.Distance)
        if UltraId ~= "" and UltraDelay >= 0 and UltraDuration and UltraDuration > 0 then
            UltraDodgeByAnimationId[UltraId] = {
                Name = UltraName,
                Distance = (UltraRadius and UltraRadius > 0) and UltraRadius or nil,
                DisplayName = UltraDodge.DisplayName or UltraName,
                Style = "Dodge",
                Delay = UltraDelay,
                Duration = UltraDuration,
                -- Dodge Anims
                Mode = UltraNormalizeDodgeMode(UltraDodge.Mode),
                Mute = (UltraDodge.Mute ~= nil) and (UltraDodge.Mute == true) or nil,
            }
        end
    end
end

local function UltraPlayLocalSound(UltraSoundId)
    local UltraResolvedId = UltraAssetId(UltraSoundId)
    if UltraResolvedId == "" then return end
    local UltraSound = Instance.new("Sound")
    UltraSound.Name = "UltraSound"
    UltraSound.SoundId = UltraResolvedId
    UltraSound.Volume = M.Config.SoundVolume
    UltraSound.Parent = UltraSoundService
    UltraDebris:AddItem(UltraSound, 12)
    task.spawn(function() pcall(function() UltraContentProvider:PreloadAsync({ UltraSound }) end) end)
    local UltraPlayed = pcall(function()
        if UltraSoundService.PlayLocalSound then
            UltraSoundService:PlayLocalSound(UltraSound)
        else
            UltraSound:Play()
        end
    end)
    if not UltraPlayed then pcall(function() UltraSound:Play() end) end
end

local function UltraDestroySkyForces()
    if UltraSkyVelocity then UltraSkyVelocity:Destroy(); UltraSkyVelocity = nil end
    if UltraSkyPosition then UltraSkyPosition:Destroy(); UltraSkyPosition = nil end
end

local function UltraDestroyClone()
    if UltraCloneHighlight then UltraCloneHighlight:Destroy(); UltraCloneHighlight = nil end
    if UltraCloneModel then UltraCloneModel:Destroy() end
    UltraCloneModel = nil
    UltraCloneRoot = nil
    UltraCloneFootOffset = 3
    UltraCloneJumpOffset = 0
    UltraCloneJumpVelocity = 0
    UltraCloneTracks = {}
    UltraCloneMotorPairs = nil
end

local function UltraDestroyCameraSubject()
    if UltraCameraSubject then UltraCameraSubject:Destroy() end
    UltraCameraSubject = nil
end

local function UltraHideRealCharacter(UltraCharacter)
    UltraOriginalTransparency = setmetatable({}, { __mode = "k" })
    for _, UltraInstance in ipairs(UltraCharacter:GetDescendants()) do
        if UltraInstance:IsA("BasePart") or UltraInstance:IsA("Decal") then
            UltraOriginalTransparency[UltraInstance] = UltraInstance.LocalTransparencyModifier
            UltraInstance.LocalTransparencyModifier = 1
        end
    end
end

local function UltraRestoreRealCharacter()
    for UltraInstance, UltraTransparency in pairs(UltraOriginalTransparency) do
        if UltraInstance.Parent then pcall(function() UltraInstance.LocalTransparencyModifier = UltraTransparency end) end
    end
    UltraOriginalTransparency = setmetatable({}, { __mode = "k" })
end

local function UltraBuildMotorPairs(UltraCharacter, UltraClone)
    local UltraList = {}
    for _, UltraMotor in ipairs(UltraCharacter:GetDescendants()) do
        if UltraMotor:IsA("Motor6D") then
            local UltraNames = {}
            local UltraNode = UltraMotor
            while UltraNode and UltraNode ~= UltraCharacter do
                table.insert(UltraNames, 1, UltraNode.Name)
                UltraNode = UltraNode.Parent
            end
            local UltraTarget = UltraClone
            for _, UltraName in ipairs(UltraNames) do
                UltraTarget = UltraTarget and UltraTarget:FindFirstChild(UltraName)
            end
            if UltraTarget and UltraTarget:IsA("Motor6D") then
                table.insert(UltraList, { UltraMotor, UltraTarget })
            end
        end
    end
    return UltraList
end

local function UltraCreateClone(UltraCharacter, UltraStartCFrame)
    local UltraPreviousArchivable = UltraCharacter.Archivable
    UltraCharacter.Archivable = true
    local UltraOk, UltraClone = pcall(function() return UltraCharacter:Clone() end)
    UltraCharacter.Archivable = UltraPreviousArchivable
    if not UltraOk or not UltraClone then return nil, nil end

    UltraClone.Name = "UltraClone"
    -- Dodge Anims: este clon ya copia tus animaciones, no hace falta reproducirlas otra vez en el
    pcall(function() UltraClone:SetAttribute("AFO_SyncsAnimations", true) end)
    for _, UltraInstance in ipairs(UltraClone:GetDescendants()) do
        if UltraInstance:IsA("Script") or UltraInstance:IsA("LocalScript") or UltraInstance:IsA("ModuleScript") then
            UltraInstance:Destroy()
        elseif UltraInstance:IsA("BasePart") then
            UltraInstance.Anchored = false
            UltraInstance.CanCollide = false
            UltraInstance.CanTouch = false
            UltraInstance.CanQuery = false
            UltraInstance.CastShadow = false
            UltraInstance.Massless = true
        elseif UltraInstance:IsA("Humanoid") then
            UltraInstance.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
            UltraInstance.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
            UltraInstance.AutoRotate = false
        end
    end

    UltraClone.Parent = workspace
    local UltraCloneRoot = UltraGetRoot(UltraClone)
    if UltraCloneRoot then
        UltraCloneRoot.Anchored = true
        UltraClone.PrimaryPart = UltraCloneRoot
    end
    UltraClone:PivotTo(UltraStartCFrame)
    UltraCloneMotorPairs = UltraBuildMotorPairs(UltraCharacter, UltraClone)
    UltraLastPairRebuild = os.clock()
    return UltraClone, UltraCloneRoot
end

local function UltraSyncCloneAnimation(UltraCharacter)
    local UltraHumanoid = UltraGetHumanoid(UltraCharacter)
    local UltraCloneHumanoid = UltraGetHumanoid(UltraCloneModel)
    if not UltraHumanoid or not UltraCloneHumanoid then return end

    local UltraAnimator = UltraHumanoid:FindFirstChildOfClass("Animator")
    if not UltraAnimator then return end

    local UltraCloneAnimator = UltraCloneHumanoid:FindFirstChildOfClass("Animator")
    if not UltraCloneAnimator then
        UltraCloneAnimator = Instance.new("Animator")
        UltraCloneAnimator.Parent = UltraCloneHumanoid
    end

    local UltraSeen = {}
    for _, UltraTrack in ipairs(UltraAnimator:GetPlayingAnimationTracks()) do
        local UltraAnimation = UltraTrack.Animation
        local UltraId = UltraAnimation and tostring(UltraAnimation.AnimationId) or ""

        if not string.find(UltraId, "215384594") then
            if UltraId ~= "" then
                UltraSeen[UltraId] = true
                local UltraCloneTrack = UltraCloneTracks[UltraId]
                if not UltraCloneTrack then
                    local UltraOk, UltraLoaded = pcall(function() return UltraCloneAnimator:LoadAnimation(UltraAnimation) end)
                    if UltraOk and UltraLoaded then
                        UltraCloneTrack = UltraLoaded
                        UltraCloneTracks[UltraId] = UltraCloneTrack
                        UltraCloneTrack.Priority = UltraTrack.Priority
                        UltraCloneTrack:Play(0)
                    end
                end
                if UltraCloneTrack then
                    -- Bucles (modo Ghost de Dodge Anims): el clon tambien repite, y si su copia se
                    -- detuvo mientras la original sigue sonando, se vuelve a lanzar
                    if UltraCloneTrack.Looped ~= UltraTrack.Looped then UltraCloneTrack.Looped = UltraTrack.Looped end
                    if not UltraCloneTrack.IsPlaying then UltraCloneTrack:Play(0) end
                    UltraCloneTrack.Priority = UltraTrack.Priority
                    UltraCloneTrack:AdjustSpeed(UltraTrack.Speed)
                    UltraCloneTrack:AdjustWeight(UltraTrack.WeightCurrent, 0)
                    if math.abs(UltraCloneTrack.TimePosition - UltraTrack.TimePosition) > 0.08 then
                        UltraCloneTrack.TimePosition = UltraTrack.TimePosition
                    end
                end
            end
        end
    end

    for UltraId, UltraTrack in pairs(UltraCloneTracks) do
        if not UltraSeen[UltraId] then
            UltraTrack:Stop(0.12)
            UltraCloneTracks[UltraId] = nil
        end
    end

end

local function UltraSyncClonePose(UltraCharacter)
    if not UltraCloneModel or not UltraCharacter then return end
    local UltraNow = os.clock()
    if not UltraCloneMotorPairs or UltraNow - UltraLastPairRebuild > 1 then
        UltraCloneMotorPairs = UltraBuildMotorPairs(UltraCharacter, UltraCloneModel)
        UltraLastPairRebuild = UltraNow
    end
    for _, UltraPair in ipairs(UltraCloneMotorPairs) do
        local UltraSource, UltraTarget = UltraPair[1], UltraPair[2]
        if UltraSource.Parent and UltraTarget.Parent then
            UltraTarget.Transform = UltraSource.Transform
        end
    end
end

local function UltraCreateCameraSubject(UltraPosition)
    local UltraSubject = Instance.new("Part")
    UltraSubject.Name = "UltraCameraSubject"
    UltraSubject.Size = Vector3.new(1, 1, 1)
    UltraSubject.Transparency = 1
    UltraSubject.Anchored = true
    UltraSubject.CanCollide = false
    UltraSubject.CanTouch = false
    UltraSubject.CanQuery = false
    UltraSubject.CFrame = CFrame.new(UltraPosition + Vector3.new(0, M.Config.CloneHeadOffset, 0))
    UltraSubject.Parent = workspace
    return UltraSubject
end

local function UltraCreateDivineCloneVFX()
    if not M.Config.Aura.Enabled or not UltraCloneModel then return end
    local GLOBAL_SCALE = 0.64

    UltraCloneHighlight = Instance.new("Highlight")
    UltraCloneHighlight.Name = "Ultra_DivineGlow"
    UltraCloneHighlight.FillTransparency = 0.99
    UltraCloneHighlight.FillColor = Color3.fromRGB(240, 250, 255)
    UltraCloneHighlight.OutlineTransparency = 0
    UltraCloneHighlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    UltraCloneHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    UltraCloneHighlight.Parent = UltraCloneModel

    for _, UltraPart in ipairs(UltraCloneModel:GetDescendants()) do
        if UltraPart:IsA("BasePart") and not UltraPart:FindFirstAncestorOfClass("Accessory")
            and UltraPart.Name ~= "HumanoidRootPart" and UltraPart.Transparency < 1 then

            local lowerName = UltraPart.Name:lower()
            local baseScale = math.clamp((UltraPart.Size.X + UltraPart.Size.Y + UltraPart.Size.Z) / 3, 0.6, 1.5)
            local partScale = baseScale * GLOBAL_SCALE

            local UltraAttachment = Instance.new("Attachment")
            UltraAttachment.Name = "Ultra_DivineNode"

            local c1Multiplier = 1

            if lowerName:find("torso") then
                UltraAttachment.Position = Vector3.new(0, 0, 0)
                partScale = partScale * 1.6
            elseif lowerName:find("head") then
                UltraAttachment.Position = Vector3.new(0, -UltraPart.Size.Y * 0.35, 0)
                partScale = partScale * 1.2
            elseif lowerName:find("arm") or lowerName:find("hand") then
                UltraAttachment.Position = Vector3.new(0, 0, 0)
                partScale = partScale * 1.45
                c1Multiplier = 0.5
            elseif lowerName:find("foot") then
                UltraAttachment.Position = Vector3.new(0, UltraPart.Size.Y * 0.25, 0)
                partScale = partScale * 1.6
            elseif lowerName:find("leg") then
                UltraAttachment.Position = Vector3.new(0, 0, 0)
                partScale = partScale * 1.55
            end

            UltraAttachment.Parent = UltraPart

            local innerAura = Instance.new("ParticleEmitter")
            innerAura.Name = "C1_LiquidEdge"
            innerAura.Texture = "rbxassetid://74305120244941"
            innerAura.LockedToPart = true
            innerAura.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 240, 255))
            })
            innerAura.Rate = 20
            innerAura.Lifetime = NumberRange.new(0.4, 0.6)
            innerAura.Speed = NumberRange.new(0.5, 1.2)

            if lowerName:find("leg") or lowerName:find("foot") then
                innerAura.Acceleration = Vector3.new(0, 5, 0)
            elseif lowerName:find("arm") or lowerName:find("hand") then
                innerAura.Acceleration = Vector3.new(0, -12, 0)
            else
                innerAura.Acceleration = Vector3.new(0, 3, 0)
            end

            innerAura.Rotation = NumberRange.new(-180, 180)
            innerAura.RotSpeed = NumberRange.new(-30, 30)
            innerAura.Size = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.9 * partScale * c1Multiplier),
                NumberSequenceKeypoint.new(0.5, 1.2 * partScale * c1Multiplier),
                NumberSequenceKeypoint.new(1, 0.5 * partScale * c1Multiplier)
            })
            innerAura.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1),
                NumberSequenceKeypoint.new(0.2, 0.7),
                NumberSequenceKeypoint.new(1, 1)
            })
            innerAura.LightEmission = 0.48
            innerAura.ZOffset = -0.1
            innerAura.Parent = UltraAttachment

            local slidingFires = innerAura:Clone()
            slidingFires.Name = "C1_Sub_SlidingFires"
            slidingFires.Rate = 40
            slidingFires.Lifetime = NumberRange.new(0.2, 0.4)
            slidingFires.Speed = NumberRange.new(0.1, 0.5)
            slidingFires.Acceleration = slidingFires.Acceleration * 2
            slidingFires.RotSpeed = NumberRange.new(200, 400)
            slidingFires.Size = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.1 * partScale),
                NumberSequenceKeypoint.new(0.4, 0.3 * partScale),
                NumberSequenceKeypoint.new(1, 0.05 * partScale)
            })
            slidingFires.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1),
                NumberSequenceKeypoint.new(0.1, 0.6),
                NumberSequenceKeypoint.new(0.5, 0.8),
                NumberSequenceKeypoint.new(0.8, 0.6),
                NumberSequenceKeypoint.new(1, 1)
            })
            slidingFires.LightEmission = 1
            slidingFires.ZOffset = -0.05
            slidingFires.Parent = UltraAttachment

            local middleAura = Instance.new("ParticleEmitter")
            middleAura.Name = "C2_EnergyFlow"
            middleAura.Texture = "rbxassetid://74305120244941"
            middleAura.LockedToPart = true
            middleAura.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(160, 80, 255)),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(60, 100, 255)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 20, 150))
            })
            middleAura.Rate = 15
            middleAura.Lifetime = NumberRange.new(0.5, 0.8)
            middleAura.Speed = NumberRange.new(1.0, 2.5)

            if lowerName:find("leg") or lowerName:find("foot") then
                middleAura.Acceleration = Vector3.new(0, 8, 0)
            elseif lowerName:find("arm") or lowerName:find("hand") then
                middleAura.Acceleration = Vector3.new(0, -20, 0)
            else
                middleAura.Acceleration = Vector3.new(0, 6, 0)
            end

            middleAura.Rotation = NumberRange.new(-180, 180)
            middleAura.RotSpeed = NumberRange.new(-20, 20)
            middleAura.Size = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1.2 * partScale),
                NumberSequenceKeypoint.new(0.5, 1.6 * partScale),
                NumberSequenceKeypoint.new(1, 0.8 * partScale)
            })
            middleAura.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1),
                NumberSequenceKeypoint.new(0.3, 0.7),
                NumberSequenceKeypoint.new(1, 1)
            })
            middleAura.LightEmission = 0.5
            middleAura.ZOffset = -0.5
            middleAura.Parent = UltraAttachment

            local crystalAura = Instance.new("ParticleEmitter")
            crystalAura.Name = "C4_CrystalAflame"
            crystalAura.Texture = "rbxassetid://74305120244941"
            crystalAura.LockedToPart = true
            crystalAura.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(200, 255, 255)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
            })
            crystalAura.Rate = 15
            crystalAura.Lifetime = NumberRange.new(0.3, 0.5)
            crystalAura.Speed = NumberRange.new(1.5, 3.0)

            if lowerName:find("arm") or lowerName:find("hand") then
                crystalAura.Acceleration = Vector3.new(0, -18, 0)
            else
                crystalAura.Acceleration = Vector3.new(0, 8, 0)
            end

            crystalAura.Rotation = NumberRange.new(-180, 180)
            crystalAura.RotSpeed = NumberRange.new(50, 120)
            crystalAura.Size = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.4 * partScale),
                NumberSequenceKeypoint.new(0.5, 0.7 * partScale),
                NumberSequenceKeypoint.new(1, 0.3 * partScale)
            })
            crystalAura.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1),
                NumberSequenceKeypoint.new(0.2, 0.5),
                NumberSequenceKeypoint.new(0.8, 0.5),
                NumberSequenceKeypoint.new(1, 1)
            })
            crystalAura.LightEmission = 0.95
            crystalAura.ZOffset = -0.8
            crystalAura.Parent = UltraAttachment
        end
    end
end

local function UltraMakeGroundParams(UltraCharacter)
    local UltraParams = RaycastParams.new()
    UltraParams.FilterType = Enum.RaycastFilterType.Exclude
    local UltraExclude = {}
    if UltraCharacter then table.insert(UltraExclude, UltraCharacter) end
    if UltraCloneModel then table.insert(UltraExclude, UltraCloneModel) end
    if UltraCameraSubject then table.insert(UltraExclude, UltraCameraSubject) end
    for _, UltraOther in ipairs(UltraPlayers:GetPlayers()) do
        if UltraOther.Character and UltraOther.Character ~= UltraCharacter then
            table.insert(UltraExclude, UltraOther.Character)
        end
    end
    UltraParams.FilterDescendantsInstances = UltraExclude
    return UltraParams
end

local function UltraGetGroundHeight(UltraPosition, UltraCharacter)
    local UltraParams = UltraMakeGroundParams(UltraCharacter)
    local UltraMinNormal = M.Config.GroundNormalMin
    local UltraMaxRise = M.Config.MaxAutoRecoveryRise

    local UltraNearHit = workspace:Raycast(Vector3.new(UltraPosition.X, UltraPosition.Y + 5, UltraPosition.Z), Vector3.new(0, -70, 0), UltraParams)
    if UltraNearHit and UltraNearHit.Normal.Y >= UltraMinNormal then
        return UltraNearHit.Position.Y + UltraFootOffset
    end

    if UltraNearHit and UltraNearHit.Instance:IsA("BasePart") then
        local UltraPart = UltraNearHit.Instance
        local UltraTopY = UltraPart.Position.Y + UltraPart.Size.Y * 0.5 + 0.1
        local UltraTopHit = workspace:Raycast(Vector3.new(UltraPosition.X, UltraTopY, UltraPosition.Z), Vector3.new(0, -math.max(UltraPart.Size.Y + 1, 3), 0), UltraParams)
        if UltraTopHit and UltraTopHit.Instance == UltraPart and UltraTopHit.Normal.Y >= UltraMinNormal then
            local UltraRecovered = UltraTopHit.Position.Y + UltraFootOffset
            if UltraRecovered - UltraPosition.Y <= UltraMaxRise then return UltraRecovered end
        end
    end

    local UltraOrigin = Vector3.new(UltraPosition.X, UltraPosition.Y + M.Config.GroundScanUp, UltraPosition.Z)
    local UltraDirection = Vector3.new(0, -M.Config.GroundScanDown, 0)
    for _ = 1, 8 do
        local UltraHit = workspace:Raycast(UltraOrigin, UltraDirection, UltraParams)
        if not UltraHit then break end
        if UltraHit.Normal.Y >= UltraMinNormal then
            local UltraRecovered = UltraHit.Position.Y + UltraFootOffset
            if UltraRecovered - UltraPosition.Y <= UltraMaxRise then return UltraRecovered end
            break
        end
        local UltraUsed = (UltraHit.Position - UltraOrigin).Magnitude + 0.05
        if UltraUsed >= UltraDirection.Magnitude then break end
        UltraOrigin = UltraHit.Position + UltraDirection.Unit * 0.05
        UltraDirection = Vector3.new(0, -(UltraDirection.Magnitude - UltraUsed), 0)
    end
    return nil
end

local function UltraGroundPosition(UltraPosition, UltraCharacter)
    local UltraY = UltraGetGroundHeight(UltraPosition, UltraCharacter)
    if UltraY then return Vector3.new(UltraPosition.X, UltraY, UltraPosition.Z) end
    return UltraPosition
end

local function UltraFollowGround(UltraPrev, UltraDesired, UltraCharacter)
    local UltraNew = Vector3.new(UltraDesired.X, UltraPrev.Y, UltraDesired.Z)
    local UltraY = UltraGetGroundHeight(UltraNew, UltraCharacter)
    if UltraY then UltraNew = Vector3.new(UltraNew.X, UltraY, UltraNew.Z) end
    return UltraNew
end

local function UltraBuildHud()
    if UltraHud and UltraHud.Parent then return end
    local UltraPlayerGui = UltraGetGuiContainer()
    if not UltraPlayerGui then return end

    pcall(function()
        for _, UltraOldName in ipairs(UltraLegacyHudNames) do
            local UltraOld = UltraPlayerGui:FindFirstChild(UltraOldName)
            while UltraOld do
                UltraOld:Destroy()
                UltraOld = UltraPlayerGui:FindFirstChild(UltraOldName)
            end
        end
    end)

    UltraHud = Instance.new("ScreenGui")
    UltraHud.Name = UltraHudName
    UltraHud.IgnoreGuiInset = true
    UltraHud.ResetOnSpawn = false
    UltraHud.DisplayOrder = 75
    UltraHud.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    UltraProtectGui(UltraHud)
    UltraHud.Parent = UltraPlayerGui

    -- Contenedor anclado arriba-derecha: la rejilla crece hacia la izquierda y hacia abajo,
    -- y un UIScale la encoge en pantallas pequenas sin que se salga del borde
    UltraHudCards = Instance.new("Frame")
    UltraHudCards.Name = "UltraThreatCards"
    UltraHudCards.BackgroundTransparency = 1
    UltraHudCards.AnchorPoint = Vector2.new(1, 0)
    UltraHudCards.Position = UDim2.new(1, -M.Config.ThreatHudRightOffset, 0, M.Config.ThreatHudTopOffset)
    UltraHudCards.Size = UDim2.fromOffset(M.Config.ThreatCardWidth * 2 + M.Config.ThreatCardGap, 600)
    UltraHudCards.Parent = UltraHud
    local UltraCardsScale = Instance.new("UIScale")
    UltraCardsScale.Name = "FitScale"
    UltraCardsScale.Parent = UltraHudCards

    if not UltraRealBodyLineDraw and _Drawing then
        pcall(function()
            UltraRealBodyLineDraw = _Drawing.new("Line")
            UltraRealBodyLineDraw.Color = Color3.fromRGB(70, 185, 255)
            UltraRealBodyLineDraw.Transparency = 0.42
            UltraRealBodyLineDraw.Thickness = 3
        end)
    end

    local UltraTimerFrame = Instance.new("Frame")
    UltraTimerFrame.Name = "UltraCloneTimer"
    UltraTimerFrame.AnchorPoint = Vector2.new(0.5, 0)
    UltraTimerFrame.Position = UDim2.new(0.5, 0, 0, M.Config.CloneTimerTopOffset)
    UltraTimerFrame.Size = UDim2.fromOffset(M.Config.CloneTimerWidth or 170, M.Config.CloneTimerHeight or 50)
    UltraTimerFrame.BackgroundColor3 = Color3.fromRGB(6, 4, 12)
    UltraTimerFrame.BackgroundTransparency = 0.15
    UltraTimerFrame.BorderSizePixel = 0
    UltraTimerFrame.Visible = false
    UltraTimerFrame.Parent = UltraHud
    Instance.new("UICorner", UltraTimerFrame).CornerRadius = UDim.new(0, 7)
    local UltraTimerStroke = Instance.new("UIStroke")
    UltraTimerStroke.Color = Color3.fromRGB(255, 215, 35)
    UltraTimerStroke.Thickness = 1
    UltraTimerStroke.Transparency = 0.2
    UltraTimerStroke.Parent = UltraTimerFrame

    local function UltraTimerLabel(UltraName, UltraY, UltraH, UltraFont, UltraSize, UltraColor)
        local UltraLabel = Instance.new("TextLabel")
        UltraLabel.Name = UltraName
        UltraLabel.BackgroundTransparency = 1
        UltraLabel.Position = UDim2.fromOffset(22, UltraY)
        UltraLabel.Size = UDim2.new(1, -44, 0, UltraH)
        UltraLabel.Font = UltraFont
        UltraLabel.TextSize = UltraSize
        UltraLabel.TextColor3 = UltraColor
        UltraLabel.TextTruncate = Enum.TextTruncate.AtEnd
        UltraLabel.Text = ""
        UltraLabel.Parent = UltraTimerFrame
        return UltraLabel
    end
    local UltraTimerTitle = UltraTimerLabel("Title", 3, 11, Enum.Font.GothamBold, 9, Color3.fromRGB(235, 235, 235))
    local UltraTimerTime = UltraTimerLabel("Time", 13, 20, Enum.Font.GothamBlack, 17, Color3.fromRGB(255, 222, 56))
    local UltraTimerSub = UltraTimerLabel("Sub", 33, 9, Enum.Font.Gotham, 8, Color3.fromRGB(170, 150, 210))

    local UltraTimerBarBg = Instance.new("Frame")
    UltraTimerBarBg.Name = "BarBg"
    UltraTimerBarBg.Position = UDim2.new(0, 10, 1, -7)
    UltraTimerBarBg.Size = UDim2.new(1, -20, 0, 3)
    UltraTimerBarBg.BackgroundColor3 = Color3.fromRGB(30, 18, 50)
    UltraTimerBarBg.BorderSizePixel = 0
    UltraTimerBarBg.Parent = UltraTimerFrame
    Instance.new("UICorner", UltraTimerBarBg).CornerRadius = UDim.new(1, 0)
    local UltraTimerFill = Instance.new("Frame")
    UltraTimerFill.Name = "Fill"
    UltraTimerFill.Size = UDim2.fromScale(1, 1)
    UltraTimerFill.BackgroundColor3 = Color3.fromRGB(255, 222, 56)
    UltraTimerFill.BorderSizePixel = 0
    UltraTimerFill.Parent = UltraTimerBarBg
    Instance.new("UICorner", UltraTimerFill).CornerRadius = UDim.new(1, 0)

    local UltraTimerClose = Instance.new("TextButton")
    UltraTimerClose.Name = "Close"
    UltraTimerClose.AnchorPoint = Vector2.new(1, 0)
    UltraTimerClose.Position = UDim2.new(1, -4, 0, 4)
    UltraTimerClose.Size = UDim2.fromOffset(14, 14)
    UltraTimerClose.BackgroundColor3 = Color3.fromRGB(90, 16, 18)
    UltraTimerClose.BackgroundTransparency = 0.1
    UltraTimerClose.BorderSizePixel = 0
    UltraTimerClose.Font = Enum.Font.GothamBlack
    UltraTimerClose.Text = "X"
    UltraTimerClose.TextColor3 = Color3.fromRGB(255, 225, 225)
    UltraTimerClose.TextSize = 9
    UltraTimerClose.ZIndex = 5
    UltraTimerClose.Parent = UltraTimerFrame
    Instance.new("UICorner", UltraTimerClose).CornerRadius = UDim.new(0, 4)
    UltraTimerClose.Activated:Connect(function()
        if UltraForceDismissAll then UltraForceDismissAll() end
    end)

    UltraTopTimer = { Frame = UltraTimerFrame, Stroke = UltraTimerStroke, Title = UltraTimerTitle, Time = UltraTimerTime, Sub = UltraTimerSub, Fill = UltraTimerFill }
end

local function UltraUpdateTopTimer(UltraNow)
    local UltraTimer = UltraTopTimer
    if not UltraTimer or not UltraTimer.Frame or not UltraTimer.Frame.Parent then return end
    if not M.Config.ShowCloneTimer then UltraTimer.Frame.Visible = false; return end

    local UltraRemaining, UltraTotal, UltraTitle, UltraSub, UltraColor
    if UltraDefenseActive then
        UltraRemaining = math.max(0, UltraActiveUntil - UltraNow)
        UltraTotal = math.max(UltraActiveDuration, 0.001)
        UltraTitle = UltraGetText("return_in")
        UltraSub = UltraActiveDodgeName and UltraActiveDodgeName:gsub("_", " ") or ""
        local UltraDodgeData
        for _, UltraEntry in pairs(UltraDodgeByAnimationId) do
            if UltraEntry.Name == UltraActiveDodgeName then UltraDodgeData = UltraEntry break end
        end
        if UltraDodgeData then UltraSub = UltraGetDodgeDisplayName(UltraDodgeData) end
        UltraColor = Color3.fromRGB(110, 210, 255)
    elseif UltraPendingDodge and UltraPendingDodgeExpectedTime and not UltraPendingSilent then
        UltraRemaining = math.max(0, UltraPendingDodgeExpectedTime - UltraNow)
        UltraTotal = math.max(UltraPendingTotal, 0.001)
        UltraTitle = UltraGetText("clone_in")
        UltraSub = UltraPendingLabel
        UltraColor = UltraRemaining <= 1 and Color3.fromRGB(255, 90, 70) or Color3.fromRGB(255, 222, 56)
    else
        UltraTimer.Frame.Visible = false
        return
    end

    UltraTimer.Frame.Visible = true
    UltraTimer.Title.Text = UltraTitle
    UltraTimer.Time.Text = string.format("%.1fs", UltraRemaining)
    UltraTimer.Time.TextColor3 = UltraColor
    UltraTimer.Sub.Text = UltraSub or ""
    UltraTimer.Fill.BackgroundColor3 = UltraColor
    UltraTimer.Fill.Size = UDim2.fromScale(math.clamp(UltraRemaining / UltraTotal, 0, 1), 1)
    UltraTimer.Stroke.Color = UltraColor
end

local function UltraSetText(UltraObject, UltraText)
    if UltraObject and UltraObject.Parent then UltraObject.Text = UltraText end
end

local function UltraCreateThreatCard(UltraThreat)
    UltraBuildHud()
    if not UltraHudCards then return end

    -- Si por cualquier motivo quedo una tarjeta vieja de este jugador, se elimina: una tarjeta por amenaza
    local UltraCardName = "UltraAlert_" .. UltraThreat.Player.UserId
    for _, UltraOldCard in ipairs(UltraHudCards:GetChildren()) do
        if UltraOldCard.Name == UltraCardName then UltraOldCard:Destroy() end
    end

    -- Frame normal (no CanvasGroup): los CanvasGroup dejan de dibujarse cuando se llena su
    -- presupuesto de textura y la tarjeta "desaparecia" aunque la amenaza siguiera viva
    local UltraGroup = Instance.new("Frame")
    UltraGroup.Name = UltraCardName
    UltraGroup.BackgroundTransparency = 1
    UltraGroup.BorderSizePixel = 0
    UltraGroup.AnchorPoint = Vector2.new(1, 0)
    UltraGroup.Size = UDim2.fromOffset(M.Config.ThreatCardWidth, M.Config.ThreatCardHeight)
    UltraGroup.Parent = UltraHudCards
    local UltraScale = Instance.new("UIScale")
    UltraScale.Scale = 0.6
    UltraScale.Parent = UltraGroup

    local UltraPanel = Instance.new("Frame")
    UltraPanel.BackgroundColor3 = Color3.fromRGB(6, 4, 12)
    UltraPanel.BackgroundTransparency = 0.15
    UltraPanel.BorderSizePixel = 0
    UltraPanel.Size = UDim2.fromScale(1, 1)
    UltraPanel.Parent = UltraGroup
    Instance.new("UICorner", UltraPanel).CornerRadius = UDim.new(0, 8)

    local UltraStroke = Instance.new("UIStroke")
    UltraStroke.Color = Color3.fromRGB(110, 30, 180)
    UltraStroke.Thickness = 1
    UltraStroke.Transparency = 0.5
    UltraStroke.Parent = UltraPanel

    local UltraDangerStrip = Instance.new("Frame")
    UltraDangerStrip.BackgroundColor3 = Color3.fromRGB(110, 30, 180)
    UltraDangerStrip.BorderSizePixel = 0
    UltraDangerStrip.Size = UDim2.new(0, 4, 1, -16)
    UltraDangerStrip.Position = UDim2.fromOffset(6, 8)
    UltraDangerStrip.Parent = UltraPanel
    Instance.new("UICorner", UltraDangerStrip).CornerRadius = UDim.new(1, 0)

    local function UltraCardLabel(UltraName, UltraY, UltraFont, UltraSize, UltraColor)
        local UltraLabel = Instance.new("TextLabel")
        UltraLabel.Name = UltraName
        UltraLabel.BackgroundTransparency = 1
        UltraLabel.Position = UDim2.new(0, 20, 0, UltraY)
        UltraLabel.Size = UDim2.new(1, -88, 0, UltraSize + 5)
        UltraLabel.Font = UltraFont
        UltraLabel.TextSize = UltraSize
        UltraLabel.TextColor3 = UltraColor
        UltraLabel.TextXAlignment = Enum.TextXAlignment.Left
        UltraLabel.TextTruncate = Enum.TextTruncate.AtEnd
        UltraLabel.Parent = UltraPanel
        return UltraLabel
    end

    local UltraThreatTitle = UltraCardLabel("ThreatLabel", 8, Enum.Font.GothamBold, 13, Color3.fromRGB(220, 190, 255))
    UltraThreatTitle.Text = UltraGetText("threat")
    local UltraName = UltraCardLabel("NameLabel", 29, Enum.Font.GothamBold, 13, Color3.fromRGB(245, 245, 245))
    local UltraDistance = UltraCardLabel("DistanceLabel", 50, Enum.Font.Gotham, 11, Color3.fromRGB(200, 170, 255))
    local UltraHealth = UltraCardLabel("HealthLabel", 67, Enum.Font.Legacy, 11, Color3.fromRGB(255, 150, 150))
    local UltraAbility = UltraCardLabel("AbilityLabel", 84, Enum.Font.GothamBold, 10, Color3.fromRGB(150, 220, 255))
    UltraAbility.Size = UDim2.new(1, -35, 0, 17)

    local UltraImageHolder = Instance.new("Frame")
    UltraImageHolder.BackgroundColor3 = Color3.fromRGB(20, 10, 40)
    UltraImageHolder.BackgroundTransparency = 0.3
    UltraImageHolder.BorderSizePixel = 0
    UltraImageHolder.Position = UDim2.new(1, -65, 0, 20)
    UltraImageHolder.Size = UDim2.fromOffset(55, 55)
    UltraImageHolder.Parent = UltraPanel
    Instance.new("UICorner", UltraImageHolder).CornerRadius = UDim.new(1, 0)

    local UltraImage = Instance.new("ImageLabel")
    UltraImage.Name = "Portrait"
    UltraImage.BackgroundTransparency = 1
    UltraImage.BorderSizePixel = 0
    UltraImage.Position = UDim2.fromOffset(0, 0)
    UltraImage.Size = UDim2.fromScale(1, 1)
    UltraImage.Parent = UltraImageHolder
    Instance.new("UICorner", UltraImage).CornerRadius = UDim.new(1, 0)

    local UltraCardClose = Instance.new("TextButton")
    UltraCardClose.Name = "Close"
    UltraCardClose.AnchorPoint = Vector2.new(1, 0)
    UltraCardClose.Position = UDim2.new(1, -6, 0, 4)
    UltraCardClose.Size = UDim2.fromOffset(16, 16)
    UltraCardClose.BackgroundColor3 = Color3.fromRGB(90, 16, 18)
    UltraCardClose.BackgroundTransparency = 0.1
    UltraCardClose.BorderSizePixel = 0
    UltraCardClose.Font = Enum.Font.GothamBlack
    UltraCardClose.Text = "X"
    UltraCardClose.TextColor3 = Color3.fromRGB(255, 225, 225)
    UltraCardClose.TextSize = 10
    UltraCardClose.ZIndex = 5
    UltraCardClose.Parent = UltraPanel
    Instance.new("UICorner", UltraCardClose).CornerRadius = UDim.new(0, 4)
    UltraCardClose.Activated:Connect(function()
        if UltraIgnoreThreat then UltraIgnoreThreat(UltraThreat) end
    end)

    UltraThreat.Card = UltraGroup
    UltraThreat.CardScale = UltraScale
    UltraThreat.CardLabels = { Name = UltraName, Distance = UltraDistance, Health = UltraHealth, Ability = UltraAbility, Portrait = UltraImage }
    UltraThreat.CardParts = {
        Title = UltraThreatTitle, Strip = UltraDangerStrip, ImageHolder = UltraImageHolder, Close = UltraCardClose,
        Name = UltraName, Distance = UltraDistance, Health = UltraHealth, Ability = UltraAbility,
    }
    UltraThreat.CardCompact = nil
    UltraThreat.CardSlot = nil

    UltraTweenService:Create(UltraScale, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()

    local UltraUserId = UltraThreat.Player.UserId
    local UltraCachedThumbnail = UltraThumbnailCache[UltraUserId]
    if UltraCachedThumbnail then
        UltraImage.Image = UltraCachedThumbnail
    else
        task.spawn(function()
            local UltraOk, UltraThumbnail = pcall(function() return UltraPlayers:GetUserThumbnailAsync(UltraUserId, Enum.ThumbnailType.AvatarBust, Enum.ThumbnailSize.Size420x420) end)
            if UltraOk then
                UltraThumbnailCache[UltraUserId] = UltraThumbnail
                if UltraThreat.Card and UltraThreat.Card.Parent and UltraThreat.CardLabels.Portrait then UltraThreat.CardLabels.Portrait.Image = UltraThumbnail end
            end
        end)
    end
end

local function UltraApplyCardMode(UltraThreat, UltraCompact)
    local UltraParts = UltraThreat.CardParts
    if not UltraParts or UltraThreat.CardCompact == UltraCompact then return end
    UltraThreat.CardCompact = UltraCompact
    pcall(function()
        if UltraCompact then
            UltraParts.Title.Visible = false
            UltraParts.Health.Visible = false
            UltraParts.Ability.Visible = false
            UltraParts.Strip.Visible = false
            UltraParts.ImageHolder.AnchorPoint = Vector2.new(0.5, 0)
            UltraParts.ImageHolder.Position = UDim2.new(0.5, 0, 0, 6)
            UltraParts.ImageHolder.Size = UDim2.fromOffset(34, 34)
            UltraParts.Name.Position = UDim2.new(0, 4, 0, 42)
            UltraParts.Name.Size = UDim2.new(1, -8, 0, 14)
            UltraParts.Name.TextSize = 10
            UltraParts.Name.TextXAlignment = Enum.TextXAlignment.Center
            UltraParts.Distance.Position = UDim2.new(0, 4, 0, 56)
            UltraParts.Distance.Size = UDim2.new(1, -8, 0, 12)
            UltraParts.Distance.TextSize = 9
            UltraParts.Distance.TextXAlignment = Enum.TextXAlignment.Center
            UltraParts.Close.Position = UDim2.new(1, -3, 0, 3)
            UltraParts.Close.Size = UDim2.fromOffset(14, 14)
            UltraParts.Close.TextSize = 9
        else
            UltraParts.Title.Visible = true
            UltraParts.Health.Visible = true
            UltraParts.Ability.Visible = true
            UltraParts.Strip.Visible = true
            UltraParts.ImageHolder.AnchorPoint = Vector2.new(0, 0)
            UltraParts.ImageHolder.Position = UDim2.new(1, -65, 0, 20)
            UltraParts.ImageHolder.Size = UDim2.fromOffset(55, 55)
            UltraParts.Name.Position = UDim2.new(0, 20, 0, 29)
            UltraParts.Name.Size = UDim2.new(1, -88, 0, 18)
            UltraParts.Name.TextSize = 13
            UltraParts.Name.TextXAlignment = Enum.TextXAlignment.Left
            UltraParts.Distance.Position = UDim2.new(0, 20, 0, 50)
            UltraParts.Distance.Size = UDim2.new(1, -88, 0, 16)
            UltraParts.Distance.TextSize = 11
            UltraParts.Distance.TextXAlignment = Enum.TextXAlignment.Left
            UltraParts.Close.Position = UDim2.new(1, -6, 0, 4)
            UltraParts.Close.Size = UDim2.fromOffset(16, 16)
            UltraParts.Close.TextSize = 10
        end
    end)
end

-- Posicion de la tarjeta numero UltraIndex dentro del contenedor (anclado arriba-derecha):
--   [2][1]
--   [4][3]
--   ...[7][6][5]   <- compactas, de derecha a izquierda, en filas hacia abajo
local function UltraGetCardSlot(UltraIndex)
    local UltraCfg = M.Config
    local UltraGap = UltraCfg.ThreatCardGap
    local UltraBigSlots = math.max(0, UltraCfg.ThreatCardBigSlots)
    if UltraIndex <= UltraBigSlots then
        local UltraCol = (UltraIndex - 1) % 2
        local UltraRow = math.floor((UltraIndex - 1) / 2)
        return UltraCol * (UltraCfg.ThreatCardWidth + UltraGap), UltraRow * (UltraCfg.ThreatCardHeight + UltraGap),
            UltraCfg.ThreatCardWidth, UltraCfg.ThreatCardHeight, false
    end
    local UltraBigRows = math.ceil(UltraBigSlots / 2)
    local UltraGridWidth = UltraCfg.ThreatCardWidth * 2 + UltraGap
    local UltraPerRow = math.max(1, math.floor((UltraGridWidth + UltraGap) / (UltraCfg.ThreatCardSmallWidth + UltraGap)))
    local UltraSmallIndex = UltraIndex - UltraBigSlots - 1
    local UltraCol = UltraSmallIndex % UltraPerRow
    local UltraRow = math.floor(UltraSmallIndex / UltraPerRow)
    return UltraCol * (UltraCfg.ThreatCardSmallWidth + UltraGap),
        UltraBigRows * (UltraCfg.ThreatCardHeight + UltraGap) + UltraRow * (UltraCfg.ThreatCardSmallHeight + UltraGap),
        UltraCfg.ThreatCardSmallWidth, UltraCfg.ThreatCardSmallHeight, true
end

local function UltraCreateLine(UltraThreat)
    if not _Drawing then return end
    pcall(function()
        local gw = _Drawing.new("Line"); gw.Transparency = 0.35
        local ol = _Drawing.new("Line"); ol.Transparency = 0.65; ol.Color = Color3.fromRGB(0, 0, 0)
        local ln = _Drawing.new("Line"); ln.Transparency = 1
        UltraThreat.ESP = { line = ln, outline = ol, glow = gw }
    end)
end

local function UltraCreateFarLight(UltraThreat)
    local UltraCharacter = UltraThreat.Player.Character
    local UltraRoot = UltraGetRoot(UltraCharacter)
    if not UltraRoot then return end
    -- Nunca mas de un punto de amenaza por personaje: se limpia cualquier resto previo
    for _, UltraChild in ipairs(UltraCharacter:GetChildren()) do
        if UltraChild:IsA("BillboardGui") and (table.find(UltraLegacyBeaconNames, UltraChild.Name) or UltraChild.Name == UltraBeaconName) then
            UltraChild:Destroy()
        end
    end
    for _, UltraChild in ipairs(UltraRoot:GetChildren()) do
        if UltraChild:IsA("PointLight") and (table.find(UltraLegacyLightNames, UltraChild.Name) or UltraChild.Name == UltraFarLightName) then
            UltraChild:Destroy()
        end
    end
    local UltraBillboard = Instance.new("BillboardGui")
    UltraBillboard.Name = UltraBeaconName
    UltraBillboard.Adornee = UltraRoot
    UltraBillboard.AlwaysOnTop = true
    UltraBillboard.LightInfluence = 0
    UltraBillboard.Size = UDim2.fromOffset(86, 86)
    UltraBillboard.StudsOffset = Vector3.new(0, 4.5, 0)
    UltraBillboard.Parent = UltraCharacter
    local UltraBeacon = Instance.new("TextLabel")
    UltraBeacon.BackgroundTransparency = 1
    UltraBeacon.Size = UDim2.fromScale(1, 1)
    UltraBeacon.Font = Enum.Font.GothamBlack
    UltraBeacon.Text = "!"
    UltraBeacon.TextColor3 = Color3.fromRGB(255, 218, 35)
    UltraBeacon.TextStrokeColor3 = Color3.new(0, 0, 0)
    UltraBeacon.TextStrokeTransparency = 0
    UltraBeacon.TextSize = 74
    UltraBeacon.Parent = UltraBillboard
    local UltraBeaconScale = Instance.new("UIScale")
    UltraBeaconScale.Parent = UltraBillboard
    local UltraPointLight = Instance.new("PointLight")
    UltraPointLight.Name = UltraFarLightName
    UltraPointLight.Color = Color3.fromRGB(255, 214, 24)
    UltraPointLight.Brightness = 8
    UltraPointLight.Range = M.Config.ThreatFarLightRange
    UltraPointLight.Shadows = false
    UltraPointLight.Parent = UltraRoot

    UltraThreat.Beacon = UltraBillboard
    UltraThreat.BeaconScale = UltraBeaconScale
    UltraThreat.FarLight = UltraPointLight
end

local function UltraDestroyThreatVisuals(UltraThreat)
    if UltraThreat.ESP then
        pcall(function()
            if UltraThreat.ESP.line then UltraThreat.ESP.line:Remove() end
            if UltraThreat.ESP.outline then UltraThreat.ESP.outline:Remove() end
            if UltraThreat.ESP.glow then UltraThreat.ESP.glow:Remove() end
        end)
        UltraThreat.ESP = nil
    end
    if UltraThreat.Beacon then UltraThreat.Beacon:Destroy() end
    if UltraThreat.FarLight then UltraThreat.FarLight:Destroy() end
    UltraThreat.Beacon = nil
    UltraThreat.FarLight = nil
end

local function UltraDismissThreat(UltraThreat)
    if UltraThreat.Removing then return end
    UltraThreat.Removing = true
    UltraDestroyThreatVisuals(UltraThreat)
    if UltraThreat.Card and UltraThreat.Card.Parent then
        local UltraCard = UltraThreat.Card
        if UltraThreat.CardScale then
            UltraTweenService:Create(UltraThreat.CardScale, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0 }):Play()
        end
        task.delay(0.18, function() if UltraCard then pcall(function() UltraCard:Destroy() end) end end)
    elseif UltraThreat.Card then
        pcall(function() UltraThreat.Card:Destroy() end)
    end
    UltraThreat.Card = nil
    if UltraThreats[UltraThreat.Player] == UltraThreat then
        UltraThreats[UltraThreat.Player] = nil
    end
    UltraLastHudUpdate = 0
end

local function UltraRefreshBeacon(UltraThreat)
    local UltraRoot = UltraGetRoot(UltraThreat.Player.Character)
    if not UltraRoot then return end
    if UltraThreat.Beacon and UltraThreat.Beacon.Parent and UltraThreat.Beacon.Adornee == UltraRoot then return end
    if UltraThreat.Beacon then UltraThreat.Beacon:Destroy() end
    if UltraThreat.FarLight then UltraThreat.FarLight:Destroy() end
    UltraThreat.Beacon = nil
    UltraThreat.FarLight = nil
    UltraThreat.BeaconScale = nil
    UltraCreateFarLight(UltraThreat)
end

-- Barrido anti-acumulacion: cualquier punto "!" / luz de amenaza que no pertenezca a una
-- amenaza viva (restos de otra ejecucion, del MUI viejo, o duplicados) se elimina
local function UltraSweepOrphanBeacons()
    for _, UltraPlayer in ipairs(UltraPlayers:GetPlayers()) do
        local UltraCharacter = UltraPlayer.Character
        if UltraCharacter then
            local UltraThreat = UltraThreats[UltraPlayer]
            local UltraKeepBeacon = UltraThreat and not UltraThreat.Removing and UltraThreat.Beacon or nil
            local UltraKeepLight = UltraThreat and not UltraThreat.Removing and UltraThreat.FarLight or nil
            for _, UltraChild in ipairs(UltraCharacter:GetChildren()) do
                if UltraChild:IsA("BillboardGui")
                    and (UltraChild.Name == UltraBeaconName or table.find(UltraLegacyBeaconNames, UltraChild.Name))
                    and UltraChild ~= UltraKeepBeacon then
                    pcall(function() UltraChild:Destroy() end)
                end
            end
            local UltraSweepRoot = UltraGetRoot(UltraCharacter)
            for _, UltraDesc in ipairs(UltraSweepRoot and UltraSweepRoot:GetChildren() or {}) do
                if UltraDesc:IsA("PointLight")
                    and (UltraDesc.Name == UltraFarLightName or table.find(UltraLegacyLightNames, UltraDesc.Name))
                    and UltraDesc ~= UltraKeepLight then
                    pcall(function() UltraDesc:Destroy() end)
                end
            end
        end
    end
end

local UltraMarkSequence = 0

local function UltraMarkThreat(UltraPlayer, UltraDodge, UltraTrack)
    if not UltraPlayer or UltraPlayer == UltraLocalPlayer then return end
    local UltraNow = os.clock()
    local UltraLife = math.max(M.Config.ThreatAlertLifetime, (UltraDodge.Delay or 0) + (UltraDodge.Duration or 0) + 1)
    local UltraThreat = UltraThreats[UltraPlayer]
    if UltraThreat and not UltraThreat.Removing then
        -- Mismo jugador: se ACTUALIZA la amenaza existente (misma tarjeta, mismo punto, misma linea)
        UltraThreat.DodgeName = UltraDodge.Name
        UltraThreat.DodgeDisplayName = UltraGetDodgeDisplayName(UltraDodge)
        UltraThreat.Style = UltraDodge.Style
        UltraThreat.ExpiresAt = math.max(UltraThreat.ExpiresAt or 0, UltraNow + UltraLife)
        if UltraTrack then UltraThreat.Track = UltraTrack end
        return
    end
    if UltraThreat then
        -- Quedaba una amenaza a medio cerrar del mismo jugador: se limpia del todo antes de crear la nueva
        UltraDestroyThreatVisuals(UltraThreat)
        if UltraThreat.Card then pcall(function() UltraThreat.Card:Destroy() end) end
        UltraThreats[UltraPlayer] = nil
    end

    UltraMarkSequence = UltraMarkSequence + 1
    UltraThreat = {
        Player = UltraPlayer,
        DodgeName = UltraDodge.Name,
        DodgeDisplayName = UltraGetDodgeDisplayName(UltraDodge),
        Style = UltraDodge.Style,
        MarkedAt = UltraNow,
        Order = UltraMarkSequence,
        ExpiresAt = UltraNow + UltraLife,
        Track = UltraTrack,
    }
    UltraThreats[UltraPlayer] = UltraThreat
    UltraCreateThreatCard(UltraThreat)
    UltraCreateLine(UltraThreat)
    UltraCreateFarLight(UltraThreat)
    UltraLastHudUpdate = 0
end

-- La amenaza sigue viva mientras su animacion siga reproduciendose, mientras este pendiente
-- o activa la defensa por ese jugador, o mientras no haya expirado su tiempo de vida
local function UltraIsThreatHeld(UltraThreat)
    if UltraPendingDodge ~= nil and UltraPendingPlayer == UltraThreat.Player then return true end
    if UltraDefenseActive and UltraThreat.Player == UltraActiveSource then return true end
    local UltraTrack = UltraThreat.Track
    if UltraTrack then
        local UltraOk, UltraPlaying = pcall(function() return UltraTrack.IsPlaying end)
        if UltraOk and UltraPlaying == true then return true end
    end
    return false
end

local function UltraThreatList()
    local UltraList = {}
    for _, UltraThreat in pairs(UltraThreats) do table.insert(UltraList, UltraThreat) end
    -- Orden de aparicion: la primera amenaza es la tarjeta 1 (arriba a la derecha)
    table.sort(UltraList, function(UltraLeft, UltraRight) return (UltraLeft.Order or 0) < (UltraRight.Order or 0) end)
    return UltraList
end

-- Posicion "en el suelo" de Omniblock mientras su 4D esta activo (el cuerpo real esta en el cielo)
local UltraOmniGroundCache = { At = -1, Pos = nil }
local function UltraGetOmniGroundPosition()
    local UltraNow = os.clock()
    if UltraOmniGroundCache.At == UltraNow then return UltraOmniGroundCache.Pos end
    UltraOmniGroundCache.At = UltraNow
    UltraOmniGroundCache.Pos = nil
    if not _getgenv then return nil end
    local UltraOk, UltraPos = pcall(function()
        local UltraApi = rawget(_getgenv(), "AFO_OMNIBLOCK_API")
        if type(UltraApi) ~= "table" or type(UltraApi.Is4DActive) ~= "function" or UltraApi.Is4DActive() ~= true then return nil end
        if type(UltraApi.GetGroundPosition) == "function" then
            local UltraGround = UltraApi.GetGroundPosition()
            if typeof(UltraGround) == "Vector3" then return UltraGround end
        end
        -- Omniblock sin GetGroundPosition: se busca el suelo debajo del cuerpo que esta en el cielo
        local UltraCharacter = UltraLocalPlayer and UltraLocalPlayer.Character
        local UltraRoot = UltraGetRoot(UltraCharacter)
        if not UltraRoot then return nil end
        local UltraParams = RaycastParams.new()
        UltraParams.FilterType = Enum.RaycastFilterType.Exclude
        UltraParams.FilterDescendantsInstances = { UltraCharacter }
        local UltraHit = workspace:Raycast(UltraRoot.Position, Vector3.new(0, -(M.Config.SkyAltitude + 600), 0), UltraParams)
        if UltraHit then return UltraHit.Position + Vector3.new(0, 3, 0) end
        return nil
    end)
    if UltraOk and typeof(UltraPos) == "Vector3" then UltraOmniGroundCache.Pos = UltraPos end
    return UltraOmniGroundCache.Pos
end

-- Desde donde se miden las distancias de los Dodges y de las tarjetas.
-- BUG ARREGLADO: con el 4D de Omniblock activo se medía desde el cuerpo real (en el cielo),
-- asi que ningun Dodge con Distance llegaba a activarse; solo funcionaba Bakugo Nuker (sin Distance).
local function UltraGetOriginPosition()
    if UltraDefenseActive then
        if UltraCloneRoot and UltraCloneRoot.Parent then return UltraCloneRoot.Position end
        local UltraOmniPos = UltraGetOmniGroundPosition()
        if UltraOmniPos then return UltraOmniPos end
        if UltraVirtualRootPosition then return UltraVirtualRootPosition end
    end
    local UltraOmniPos = UltraGetOmniGroundPosition()
    if UltraOmniPos then return UltraOmniPos end
    local UltraRoot = UltraGetRoot(UltraLocalPlayer and UltraLocalPlayer.Character)
    return (UltraRoot and UltraRoot.Position) or UltraVirtualRootPosition
end

local function UltraUpdateCardsFit()
    if not UltraHudCards then return end
    local UltraCamera = workspace.CurrentCamera
    local UltraViewport = UltraCamera and UltraCamera.ViewportSize or Vector2.new(1366, 768)
    local UltraGridWidth = M.Config.ThreatCardWidth * 2 + M.Config.ThreatCardGap
    -- Que la rejilla de 2 columnas nunca ocupe mas de ~45% del ancho ni se salga por abajo
    local UltraScaleW = (UltraViewport.X * 0.45) / math.max(UltraGridWidth, 1)
    local UltraScaleH = UltraViewport.Y / 1000
    local UltraFit = math.clamp(math.min(UltraScaleW, UltraScaleH), 0.55, 1)
    local UltraScaleObj = UltraHudCards:FindFirstChild("FitScale")
    if UltraScaleObj and math.abs(UltraScaleObj.Scale - UltraFit) > 0.01 then UltraScaleObj.Scale = UltraFit end
    local UltraTop = math.floor(M.Config.ThreatHudTopOffset * math.min(1, UltraViewport.Y / 1000))
    UltraHudCards.Position = UDim2.new(1, -M.Config.ThreatHudRightOffset, 0, UltraTop)
end

local function UltraUpdateThreatHud(UltraNow)
    if UltraEnabled and (not UltraHud or not UltraHud.Parent or not UltraHudCards or not UltraHudCards:IsDescendantOf(UltraHud)) then
        if UltraHud then pcall(function() UltraHud:Destroy() end) end
        UltraHud = nil
        UltraHudCards = nil
        UltraBuildHud()
    end
    UltraUpdateCardsFit()
    local UltraList = UltraThreatList()
    local UltraOriginPosition = UltraGetOriginPosition()

    local UltraIndex = 0
    for _, UltraThreat in ipairs(UltraList) do
        local UltraCharacter = UltraThreat.Player.Character
        local UltraRoot = UltraGetRoot(UltraCharacter)
        local UltraHumanoid = UltraGetHumanoid(UltraCharacter)

        if UltraHumanoid and UltraHumanoid.Health <= 0 then
            UltraDismissThreat(UltraThreat)
        else
            UltraIndex = UltraIndex + 1
            if UltraRoot then UltraThreat.LastPosition = UltraRoot.Position end

            -- Mientras exista la amenaza (y su punto "!"), su tarjeta SIEMPRE existe:
            -- si se perdio, se destruyo o quedo fuera del HUD actual, se vuelve a crear
            if not UltraThreat.Removing and UltraHudCards
                and (not UltraThreat.Card or not UltraThreat.Card.Parent or not UltraThreat.Card:IsDescendantOf(UltraHudCards)) then
                UltraCreateThreatCard(UltraThreat)
            end
            UltraRefreshBeacon(UltraThreat)

            if UltraThreat.Card and UltraThreat.Card.Parent and UltraThreat.CardLabels then
                local UltraSlotX, UltraSlotY, UltraSlotW, UltraSlotH, UltraCompact = UltraGetCardSlot(UltraIndex)
                UltraApplyCardMode(UltraThreat, UltraCompact)
                local UltraTargetPos = UDim2.new(1, -UltraSlotX, 0, UltraSlotY)
                local UltraTargetSize = UDim2.fromOffset(UltraSlotW, UltraSlotH)
                local UltraSlotKey = UltraSlotX .. ":" .. UltraSlotY .. ":" .. UltraSlotW
                UltraThreat.Card.AnchorPoint = Vector2.new(1, 0)
                if UltraThreat.CardSlot == nil then
                    UltraThreat.Card.Position = UltraTargetPos
                    UltraThreat.Card.Size = UltraTargetSize
                elseif UltraThreat.CardSlot ~= UltraSlotKey then
                    UltraTweenService:Create(UltraThreat.Card, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        Position = UltraTargetPos, Size = UltraTargetSize,
                    }):Play()
                end
                UltraThreat.CardSlot = UltraSlotKey
                local UltraThreatPosition = UltraRoot and UltraRoot.Position or UltraThreat.LastPosition
                UltraSetText(UltraThreat.CardLabels.Name, UltraThreat.Player.DisplayName or UltraThreat.Player.Name)
                if UltraOriginPosition and UltraThreatPosition then
                    UltraSetText(UltraThreat.CardLabels.Distance, string.format("%.0f studs", (UltraThreatPosition - UltraOriginPosition).Magnitude))
                else
                    UltraSetText(UltraThreat.CardLabels.Distance, "--- studs")
                end
                if UltraHumanoid then
                    UltraSetText(UltraThreat.CardLabels.Health, string.format("❤️ %.0f / %.0f", math.max(0, UltraHumanoid.Health), UltraHumanoid.MaxHealth))
                else
                    UltraSetText(UltraThreat.CardLabels.Health, "❤️ ---")
                end
                UltraSetText(UltraThreat.CardLabels.Ability, UltraThreat.DodgeDisplayName)
            end
            if UltraThreat.BeaconScale then UltraThreat.BeaconScale.Scale = 0.92 + math.abs(math.sin(UltraNow * 7)) * 0.18 end
        end
    end
end

local function UltraRenderThreatLines()
    local UltraCamera = workspace.CurrentCamera
    local UltraOriginPosition = UltraGetOriginPosition()

    if not UltraCamera or not UltraOriginPosition then
        if UltraRealBodyLineDraw then UltraRealBodyLineDraw.Visible = false end
        for _, UltraThreat in pairs(UltraThreats) do
            if UltraThreat.ESP then
                UltraThreat.ESP.line.Visible = false
                UltraThreat.ESP.outline.Visible = false
                UltraThreat.ESP.glow.Visible = false
            end
        end
        return
    end

    local UltraOriginScreen, UltraOriginVisible = UltraCamera:WorldToViewportPoint(UltraOriginPosition)
    local UltraRealVisualPos = UltraGetVisualPosition(UltraLocalPlayer and UltraLocalPlayer.Character)
    local UltraRealScreen, UltraRealVisible

    if UltraRealVisualPos then
        UltraRealScreen, UltraRealVisible = UltraCamera:WorldToViewportPoint(UltraRealVisualPos)
    end

    if UltraRealBodyLineDraw then
        if UltraDefenseActive and UltraCloneRoot and UltraOriginVisible and UltraRealVisible then
            local dist = (Vector2.new(UltraRealScreen.X, UltraRealScreen.Y) - Vector2.new(UltraOriginScreen.X, UltraOriginScreen.Y)).Magnitude
            UltraRealBodyLineDraw.Visible = dist >= 2
            UltraRealBodyLineDraw.From = Vector2.new(UltraOriginScreen.X, UltraOriginScreen.Y)
            UltraRealBodyLineDraw.To = Vector2.new(UltraRealScreen.X, UltraRealScreen.Y)
        else
            UltraRealBodyLineDraw.Visible = false
        end
    end

    for _, UltraThreat in pairs(UltraThreats) do
        local d = UltraThreat.ESP
        local UltraTargetVisualPos = UltraGetVisualPosition(UltraThreat.Player.Character)
        if UltraTargetVisualPos then
            UltraThreat.LastVisualPos = UltraTargetVisualPos
        else
            UltraTargetVisualPos = UltraThreat.LastVisualPos
        end

        if not d or not UltraTargetVisualPos or not UltraOriginVisible then
            if d then d.line.Visible = false; d.outline.Visible = false; d.glow.Visible = false end
        else
            local UltraTargetScreen, UltraTargetVisible = UltraCamera:WorldToViewportPoint(UltraTargetVisualPos)
            if not UltraTargetVisible then
                d.line.Visible = false; d.outline.Visible = false; d.glow.Visible = false
            else
                local UltraDistance = (UltraTargetVisualPos - UltraOriginPosition).Magnitude
                local threatLvl = math.clamp(1 - (UltraDistance / 100), 0, 1)
                local col = Color3.fromRGB(255, 210, 25)
                local thick = 2.5 + (threatLvl ^ 1.3) * (22 - 2.5)

                local from2 = Vector2.new(UltraOriginScreen.X, UltraOriginScreen.Y)
                local to2 = Vector2.new(UltraTargetScreen.X, UltraTargetScreen.Y)

                if (to2 - from2).Magnitude < 2 then
                    d.line.Visible = false; d.outline.Visible = false; d.glow.Visible = false
                else
                    d.glow.Visible = true; d.glow.From = from2; d.glow.To = to2; d.glow.Color = col; d.glow.Thickness = thick + 11
                    d.outline.Visible = true; d.outline.From = from2; d.outline.To = to2; d.outline.Thickness = thick + 5
                    d.line.Visible = true; d.line.From = from2; d.line.To = to2; d.line.Color = col; d.line.Thickness = thick
                end
            end
        end
    end
end

local function UltraStartSkyLift(UltraRoot, UltraToken)
    UltraDestroySkyForces()

    pcall(function()
        UltraRoot.AssemblyLinearVelocity = Vector3.zero
        UltraRoot.AssemblyAngularVelocity = Vector3.zero
    end)

    local skyX, skyZ = UltraRoot.Position.X, UltraRoot.Position.Z
    UltraRoot.CFrame = CFrame.new(skyX, UltraSkyY, skyZ) * (UltraRoot.CFrame - UltraRoot.CFrame.Position)

    UltraSkyPosition = Instance.new("BodyPosition", UltraRoot)
    UltraSkyPosition.Name = "UltraHold"
    UltraSkyPosition.Position = Vector3.new(skyX, UltraSkyY, skyZ)
    UltraSkyPosition.MaxForce = Vector3.new(M.Config.HoldForce, M.Config.HoldForce, M.Config.HoldForce)
    UltraSkyPosition.P = 60000
    UltraSkyPosition.D = 2500

    UltraSkyVelocity = Instance.new("BodyVelocity", UltraRoot)
    UltraSkyVelocity.Name = "UltraSkyBV"
    UltraSkyVelocity.MaxForce = Vector3.new(0, M.Config.HoldForce, 0)
    UltraSkyVelocity.Velocity = Vector3.zero
end

local function UltraEnforceSkySafety(UltraRoot, UltraHumanoid)
    if not UltraDefenseActive or not UltraSkyY or not UltraVirtualRootPosition then return end

    if math.abs(UltraRoot.Position.Y - UltraSkyY) > 0.5 then
        UltraRoot.CFrame = CFrame.new(UltraRoot.Position.X, UltraSkyY, UltraRoot.Position.Z) * (UltraRoot.CFrame - UltraRoot.CFrame.Position)
    end

    if UltraSkyPosition then
        UltraSkyPosition.Position = Vector3.new(UltraVirtualRootPosition.X, UltraSkyY, UltraVirtualRootPosition.Z)
    end

    if UltraHumanoid then
        UltraHumanoid.PlatformStand = false
        UltraHumanoid.Sit = false
    end
end

local function UltraCreateFallPlatform(UltraRoot, UltraCharacter)
    if UltraFallPlatform then UltraFallPlatform:Destroy() end
    UltraFallPlatform = Instance.new("Part")
    UltraFallPlatform.Name = "Ultra_FallSafetyPlatform"
    UltraFallPlatform.Size = Vector3.new(90, 5, 90)
    UltraFallPlatform.CFrame = CFrame.new(UltraRoot.Position.X, UltraRoot.Position.Y - UltraGetFootOffset(UltraCharacter) - 2.5, UltraRoot.Position.Z)
    UltraFallPlatform.Anchored = true
    UltraFallPlatform.CanCollide = true
    UltraFallPlatform.CanTouch = true
    UltraFallPlatform.CanQuery = true
    UltraFallPlatform.Material = Enum.Material.ForceField
    UltraFallPlatform.Color = Color3.fromRGB(95, 190, 255)
    UltraFallPlatform.Transparency = 0.82
    UltraFallPlatform:SetAttribute("UltraFallSafety", true)
    UltraFallPlatform.Parent = workspace
    UltraFallPlatformLastTouched = os.clock()
    UltraFallPlatform.Touched:Connect(function(UltraHit)
        if UltraHit:IsDescendantOf(UltraCharacter) then UltraFallPlatformLastTouched = os.clock() end
    end)
end

local function UltraEnforceFallSafety(UltraRoot, UltraCharacter)
    if UltraFallPlatform and os.clock() - UltraFallPlatformLastTouched >= M.Config.FallSafetyPlatformLifetime then
        UltraFallPlatform:Destroy(); UltraFallPlatform = nil
    end
    if UltraRoot.Position.Y >= M.Config.FallSafetyY then return end
    local UltraParams = RaycastParams.new()
    UltraParams.FilterType = Enum.RaycastFilterType.Exclude
    UltraParams.FilterDescendantsInstances = { UltraCharacter, UltraCloneModel, UltraCameraSubject }
    local UltraBestPosition = nil
    for UltraIndex = 0, 12 do
        local UltraAngle = (UltraIndex / 12) * math.pi * 2
        local UltraOffset = Vector3.new(math.cos(UltraAngle) * M.Config.FallSafetyScanRadius, 0, math.sin(UltraAngle) * M.Config.FallSafetyScanRadius)
        local UltraHit = workspace:Raycast(UltraRoot.Position + UltraOffset + Vector3.new(0, 1200, 0), Vector3.new(0, -2400, 0), UltraParams)
        if UltraHit and UltraHit.Position.Y > M.Config.FallSafetyY and (not UltraBestPosition or UltraHit.Position.Y > UltraBestPosition.Y) then
            UltraBestPosition = UltraHit.Position
        end
    end
    if UltraBestPosition then
        UltraRoot.CFrame = CFrame.new(UltraBestPosition + Vector3.new(0, UltraGetFootOffset(UltraCharacter) + 0.5, 0))
    else
        UltraCreateFallPlatform(UltraRoot, UltraCharacter)
        UltraRoot.AssemblyLinearVelocity = Vector3.zero
    end
end

local UltraDeactivate

-- ═══════════════════════════════════════════════════════════════════════════
--  DODGE ANIMS (efecto visual del esquive sobre el clon / tu personaje)
--  * Al activarse el esquive se lanza el Mode del Dodge que lo activo.
--  * Random / 1 / 2: si durante el esquive llega OTRO disparador de la Table, se lanza otra vez
--    justo cuando ese ataque pega (tras su Delay). Disparos a menos de MergeWindow se funden.
--  * Ghost: sesion de fantasmas + bucle durante la Duration del Dodge; si el esquive termina
--    antes (X, segunda pulsacion, muerte...) la sesion se corta para que no quede colgada.
--  * Todo lo programado lleva un token: al terminar el esquive nada viejo se dispara despues.
-- ═══════════════════════════════════════════════════════════════════════════
local UltraDodgeAnimToken = 0
local UltraDodgeAnimLastFire = -math.huge
local UltraDodgeAnimScheduled = {}
local UltraDodgeAnimWarned = {}
local UltraQueuedHits = {}

local function UltraWarnOnce(UltraKey, UltraMessage)
    if UltraDodgeAnimWarned[UltraKey] then return end
    UltraDodgeAnimWarned[UltraKey] = true
    warn("[Ultra Instinct] " .. UltraMessage)
end

local function UltraGetDodgeAnimApi()
    local UltraApi = rawget(_env, "AFO_DodgeAnim_API")
    if type(UltraApi) == "table" and type(UltraApi.Run) == "function" then return UltraApi end
    return nil
end

-- Carga Dodge Anims si no esta cargado (o si el cargado es viejo y no tiene modo Ghost)
local function UltraEnsureDodgeAnims()
    local UltraCfg = M.Config.DodgeAnim
    if not UltraCfg or not UltraCfg.Enabled then return end
    local UltraCurrent = UltraGetDodgeAnimApi()
    if UltraCurrent and UltraCurrent.SupportsGhost == true then return end

    local UltraLoader = (type(loadstring) == "function" and loadstring) or load
    local function UltraTryRun(UltraBody, UltraChunk)
        if type(UltraBody) ~= "string" or UltraBody == "" then return false end
        local UltraFn = UltraLoader(UltraBody, UltraChunk)
        if not UltraFn then return false end
        local UltraOk = pcall(UltraFn)
        local UltraApi = UltraGetDodgeAnimApi()
        return UltraOk and UltraApi ~= nil and UltraApi.SupportsGhost == true
    end

    local UltraOkGet, UltraBody = pcall(function() return game:HttpGet(UltraCfg.ModuleUrl, true) end)
    if UltraOkGet and UltraTryRun(UltraBody, "=Dodge Anims") then return end
    if _readfile then
        for _, UltraPath in ipairs(UltraCfg.LocalPaths or {}) do
            local UltraOkRead, UltraLocal = pcall(_readfile, UltraPath)
            if UltraOkRead and UltraTryRun(UltraLocal, "=Dodge Anims (local)") then return end
        end
    end
    if UltraGetDodgeAnimApi() then
        UltraWarnOnce("old_module", "Dodge Anims cargado es una version vieja (sin modo Ghost): los Ghost se veran como Random")
    else
        UltraWarnOnce("no_module", "no se pudo cargar Dodge Anims: el esquive funcionara sin animacion de Dodge")
    end
end

local function UltraResolveDodgeAnimOptions(UltraDodge)
    local UltraCfg = M.Config.DodgeAnim or {}
    local UltraMode = UltraDodge and UltraDodge.Mode
    if UltraMode == nil then UltraMode = UltraNormalizeDodgeMode(UltraCfg.Mode) or "Random" end
    local UltraMute = UltraDodge and UltraDodge.Mute
    if UltraMute == nil then UltraMute = UltraCfg.Mute == true end
    return UltraMode, UltraMute
end

local function UltraFireDodgeAnim(UltraDodge)
    local UltraCfg = M.Config.DodgeAnim
    if not UltraCfg or not UltraCfg.Enabled or not UltraDodge then return end
    local UltraMode, UltraMute = UltraResolveDodgeAnimOptions(UltraDodge)
    if UltraMode == "Off" then return end
    local UltraApi = UltraGetDodgeAnimApi()
    if not UltraApi then return end
    if UltraMode == "Ghost" and UltraApi.SupportsGhost ~= true then UltraMode = "Random" end
    UltraDodgeAnimLastFire = os.clock()
    local UltraOk, UltraErr = pcall(UltraApi.Run, { Mode = UltraMode, Mute = UltraMute, Duration = UltraDodge.Duration })
    if not UltraOk then UltraWarnOnce("run_error", "Dodge Anims fallo al lanzar el esquive: " .. tostring(UltraErr)) end
end

-- Lanza el esquive visual en el instante UltraAt (reloj os.clock). Sin duplicados cercanos.
local function UltraScheduleDodgeAnim(UltraDodge, UltraAt)
    if not UltraDodge or not UltraAt then return end
    local UltraNow = os.clock()
    local UltraMerge = (M.Config.DodgeAnim and M.Config.DodgeAnim.MergeWindow) or 0.25
    if math.abs(UltraAt - UltraDodgeAnimLastFire) < UltraMerge then return end
    for _, UltraOther in ipairs(UltraDodgeAnimScheduled) do
        if math.abs(UltraOther - UltraAt) < UltraMerge then return end
    end
    if UltraAt - UltraNow <= 0.02 then
        UltraFireDodgeAnim(UltraDodge)
        return
    end
    table.insert(UltraDodgeAnimScheduled, UltraAt)
    local UltraToken = UltraDodgeAnimToken
    task.delay(UltraAt - UltraNow, function()
        local UltraIdx = table.find(UltraDodgeAnimScheduled, UltraAt)
        if UltraIdx then table.remove(UltraDodgeAnimScheduled, UltraIdx) end
        if UltraToken ~= UltraDodgeAnimToken or not UltraEnabled or not UltraDefenseActive then return end
        UltraFireDodgeAnim(UltraDodge)
    end)
end

-- Corta todo lo programado y la sesion Ghost (al terminar el esquive)
local function UltraCancelDodgeAnims()
    UltraDodgeAnimToken = UltraDodgeAnimToken + 1
    table.clear(UltraDodgeAnimScheduled)
    UltraDodgeAnimLastFire = -math.huge
    local UltraApi = UltraGetDodgeAnimApi()
    if UltraApi and type(UltraApi.CancelGhost) == "function" then pcall(UltraApi.CancelGhost) end
end

-- Golpes que llegan mientras todavia no estas esquivando. Al activarse el esquive alargan su
-- duracion hasta cubrirlos (antes un segundo ataque mas tardio se perdia y te pegaba).
-- UltraAnim = true si al pegar debe lanzarse otra vez la animacion de esquive.
local function UltraQueueHit(UltraDodge, UltraPlayer, UltraAt, UltraAnim)
    if not UltraDodge or not UltraAt then return end
    for _, UltraHit in ipairs(UltraQueuedHits) do
        if UltraHit.Player == UltraPlayer and UltraHit.Dodge.Name == UltraDodge.Name and math.abs(UltraHit.At - UltraAt) < 0.3 then
            UltraHit.At = math.max(UltraHit.At, UltraAt)
            UltraHit.Anim = UltraHit.Anim or UltraAnim
            return
        end
    end
    table.insert(UltraQueuedHits, { Dodge = UltraDodge, Player = UltraPlayer, At = UltraAt, Anim = UltraAnim })
end

local function UltraClearQueuedHits(UltraPlayer)
    if UltraPlayer == nil then table.clear(UltraQueuedHits) return end
    for UltraIndex = #UltraQueuedHits, 1, -1 do
        if UltraQueuedHits[UltraIndex].Player == UltraPlayer then table.remove(UltraQueuedHits, UltraIndex) end
    end
end

local function UltraBegin(UltraDodge, UltraSource)
    if UltraDefenseActive then return true end
    local UltraCharacter = UltraLocalPlayer and UltraLocalPlayer.Character
    local UltraRoot = UltraGetRoot(UltraCharacter)
    local UltraHumanoid = UltraGetHumanoid(UltraCharacter)
    if not UltraCharacter or not UltraRoot or not UltraHumanoid or UltraHumanoid.Health <= 0 then return false end

    UltraFootOffset = UltraGetFootOffset(UltraCharacter)

    local UltraOmni = UltraIsOmniActive()
    UltraOmniDriven = UltraOmni

    local UltraOmniGround = UltraOmniDriven and UltraGetOmniGroundPosition() or nil
    if UltraOmniGround then
        UltraVirtualRootPosition = UltraOmniGround
    elseif UltraOmniDriven then
        local UltraFar = workspace:Raycast(UltraRoot.Position, Vector3.new(0, -(M.Config.SkyAltitude + 600), 0), UltraMakeGroundParams(UltraCharacter))
        if UltraFar then
            UltraVirtualRootPosition = Vector3.new(UltraRoot.Position.X, UltraFar.Position.Y + UltraFootOffset, UltraRoot.Position.Z)
        else
            UltraVirtualRootPosition = UltraRoot.Position - Vector3.new(0, M.Config.SkyAltitude, 0)
        end
    else
        UltraVirtualRootPosition = UltraGroundPosition(UltraRoot.Position, UltraCharacter)
    end

    if not UltraOmni then
        local _, UltraYaw = UltraRoot.CFrame:ToOrientation()
        local UltraCloneCFrame = CFrame.new(UltraVirtualRootPosition) * CFrame.Angles(0, UltraYaw, 0)
        UltraCloneModel, UltraCloneRoot = UltraCreateClone(UltraCharacter, UltraCloneCFrame)
        if not UltraCloneRoot then
            UltraDestroyClone(); UltraVirtualRootPosition = nil
            UltraOmniDriven = false
            return false
        end
        UltraCloneFootOffset = UltraGetCloneFootOffset(UltraCloneModel, UltraCloneRoot)
    else
        UltraCloneModel = nil
        UltraCloneRoot = nil
    end

    UltraDefenseActive = true
    UltraActivationToken = UltraActivationToken + 1
    local UltraToken = UltraActivationToken
    UltraActiveDodgeName = UltraDodge.Name
    UltraActiveStyle = UltraDodge.Style
    UltraActiveDuration = UltraDodge.Duration
    UltraActiveUntil = os.clock() + UltraDodge.Duration
    UltraActiveSource = UltraSource

    UltraPendingDodge = nil
    UltraPendingDodgeData = nil
    UltraPendingDodgeExpectedTime = nil
    UltraPendingPlayer = nil
    UltraPendingToken = UltraPendingToken + 1 -- ningun temporizador de "pendiente" viejo vuelve a activar nada

    -- Golpes en cola: el esquive dura hasta cubrirlos todos
    local UltraBeginNow = os.clock()
    local UltraHitsToAnimate = {}
    for _, UltraHit in ipairs(UltraQueuedHits) do
        local UltraIgnored = UltraHit.Player and (UltraIgnoredUntil[UltraHit.Player] or 0) > UltraBeginNow
        if not UltraIgnored and UltraHit.At + UltraHit.Dodge.Duration > UltraBeginNow then
            UltraActiveUntil = math.max(UltraActiveUntil, UltraHit.At + UltraHit.Dodge.Duration)
            if UltraHit.Anim then table.insert(UltraHitsToAnimate, UltraHit) end
        end
    end
    table.clear(UltraQueuedHits)
    UltraActiveDuration = math.max(UltraActiveDuration, UltraActiveUntil - UltraBeginNow)

    -- Efecto visual de Dodge Anims: ahora el que activo el esquive, y luego cada golpe en cola
    UltraDodgeAnimToken = UltraDodgeAnimToken + 1
    table.clear(UltraDodgeAnimScheduled)
    UltraDodgeAnimLastFire = -math.huge
    UltraSkyY = UltraVirtualRootPosition.Y + M.Config.SkyAltitude
    if not UltraOmniDriven then
        UltraCameraSubject = UltraCreateCameraSubject(UltraVirtualRootPosition)
        UltraHideRealCharacter(UltraCharacter)
    end
    if UltraCloneRoot then UltraCreateDivineCloneVFX() end

    if not UltraOmniDriven then
        local UltraCamera = workspace.CurrentCamera
        if UltraCamera then UltraCamera.CameraSubject = UltraCameraSubject end
        UltraStartSkyLift(UltraRoot, UltraToken)
    end
    UltraBindMovement()
    UltraPlayLocalSound(M.Config.ActivationSoundId)

    -- La animacion se lanza cuando el clon ya existe, para que el efecto caiga sobre el
    UltraFireDodgeAnim(UltraDodge)
    for _, UltraHit in ipairs(UltraHitsToAnimate) do
        UltraScheduleDodgeAnim(UltraHit.Dodge, UltraHit.At)
    end
    return true
end

UltraDeactivate = function(UltraReturnToClone)
    if not UltraDefenseActive then return end

    local UltraSkipLanding = UltraOmniDriven or UltraIsOmniActive()

    UltraDefenseActive = false
    UltraActivationToken = UltraActivationToken + 1
    UltraCancelDodgeAnims()
    UltraUnbindMovement()
    UltraDestroySkyForces()
    if TogaCloseFn then pcall(TogaCloseFn) end

    local UltraCharacter = UltraLocalPlayer and UltraLocalPlayer.Character
    local UltraRoot = UltraGetRoot(UltraCharacter)
    local UltraHumanoid = UltraGetHumanoid(UltraCharacter)

    if not UltraSkipLanding then
        if UltraReturnToClone and UltraRoot and UltraHumanoid and UltraHumanoid.Health > 0 then
            local baseLandingPos = UltraVirtualRootPosition
            local UltraYaw = 0
            if UltraCloneRoot then
                baseLandingPos = UltraCloneRoot.Position
                local _, UltraCloneYaw = UltraCloneRoot.CFrame:ToOrientation()
                UltraYaw = UltraCloneYaw
            end

            if baseLandingPos then
                local UltraLandingPosition = UltraGroundPosition(baseLandingPos, UltraCharacter)
                pcall(function()
                    UltraHumanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
                    UltraRoot.CFrame = CFrame.new(UltraLandingPosition) * CFrame.Angles(0, UltraYaw, 0)
                    UltraRoot.AssemblyLinearVelocity = Vector3.zero
                    UltraRoot.AssemblyAngularVelocity = Vector3.zero
                    task.defer(function()
                        if UltraHumanoid.Parent then
                            UltraHumanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
                            UltraHumanoid:ChangeState(Enum.HumanoidStateType.Landed)
                        end
                    end)
                end)
            end
        end

        local UltraCamera = workspace.CurrentCamera
        if UltraCamera and UltraHumanoid and UltraHumanoid.Parent then
            UltraCamera.CameraSubject = UltraHumanoid
        end
    end
    UltraRestoreRealCharacter()

    UltraDestroyClone()
    UltraDestroyCameraSubject()
    UltraVirtualRootPosition = nil
    UltraSkyY = nil
    UltraActiveDodgeName = nil
    UltraActiveStyle = nil
    UltraActiveDuration = 0
    UltraActiveSource = nil
    UltraOmniDriven = false
    UltraPlayLocalSound(M.Config.DeactivationSoundId)
end

local function UltraIgnorePlayer(UltraPlayer, UltraSeconds)
    if not UltraPlayer then return end
    UltraIgnoredUntil[UltraPlayer] = os.clock() + math.max(1, UltraSeconds or 0)
    for UltraKey, UltraWatch in pairs(UltraDistanceWatches) do
        if UltraWatch.Player == UltraPlayer then UltraDistanceWatches[UltraKey] = nil end
    end
end

UltraForceDismissAll = function()
    UltraPendingToken = UltraPendingToken + 1
    UltraClearQueuedHits(nil)
    UltraPendingDodgeData = nil
    UltraPendingDodge = nil
    UltraPendingDodgeExpectedTime = nil
    UltraPendingPlayer = nil
    local UltraList = UltraThreatList()
    for _, UltraThreat in ipairs(UltraList) do
        UltraIgnorePlayer(UltraThreat.Player, UltraThreat.ExpiresAt - os.clock())
        UltraDismissThreat(UltraThreat)
    end
    if TogaCloseFn then pcall(TogaCloseFn) else UltraDestroyTogaAlert() end
    if UltraDefenseActive then UltraDeactivate(true) end
end

UltraIgnoreThreat = function(UltraThreat)
    if not UltraThreat then return end
    local UltraPlayer = UltraThreat.Player
    UltraIgnorePlayer(UltraPlayer, UltraThreat.ExpiresAt - os.clock())
    UltraClearQueuedHits(UltraPlayer)
    if UltraPendingDodge and UltraPendingPlayer == UltraPlayer then
        UltraPendingToken = UltraPendingToken + 1
        UltraPendingDodgeData = nil
        UltraPendingDodge = nil
        UltraPendingDodgeExpectedTime = nil
        UltraPendingPlayer = nil
        if TogaCloseFn then pcall(TogaCloseFn) else UltraDestroyTogaAlert() end
    end
    if UltraDefenseActive and UltraActiveSource == UltraPlayer then UltraDeactivate(true) end
    UltraDismissThreat(UltraThreat)
end

UltraDestroyTogaAlert = function()
    TogaSession = TogaSession + 1
    UltraDisconnect(TogaKeyConn)
    TogaKeyConn = nil
    TogaCloseFn = nil
    if TogaAlertGuiInstance then
        pcall(function() TogaAlertGuiInstance:Destroy() end)
        TogaAlertGuiInstance = nil
    end
    TogaImpulseCount = 0
    TogaActiveDodge = nil
    TogaActivePlayer = nil
end

local function UltraOpenTogaAlert(UltraDodge, UltraPlayer)
    UltraDestroyTogaAlert()
    TogaActiveDodge = UltraDodge
    TogaActivePlayer = UltraPlayer
    TogaImpulseCount = 0

    local container = UltraGetGuiContainer()
    TogaSession = TogaSession + 1
    local mySession = TogaSession

    pcall(function()
        local oldGui = container:FindFirstChild("TogaAlertUI")
        if oldGui then oldGui:Destroy() end
    end)

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "TogaAlertUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.DisplayOrder = 80
    ScreenGui.IgnoreGuiInset = true
    UltraProtectGui(ScreenGui)
    local parentOk = pcall(function() ScreenGui.Parent = container end)
    if not parentOk or not ScreenGui.Parent then
        ScreenGui.Parent = game:GetService("CoreGui")
    end
    TogaAlertGuiInstance = ScreenGui

    local isUIActive = true
    local isClosing = false

    local MainHolder = Instance.new("Frame")
    MainHolder.Name = "MainHolder"
    MainHolder.BackgroundTransparency = 1
    MainHolder.Size = UDim2.new(0, 300, 0, 300)
    MainHolder.AnchorPoint = Vector2.new(0.5, 0.5)

    local StartPos = UDim2.new(1, 220, 0.72, 0)
    local EndPos = UDim2.new(1, -140, 0.72, 0)

    MainHolder.Position = StartPos
    MainHolder.Parent = ScreenGui

    local GlowHolder = Instance.new("Frame")
    GlowHolder.Name = "GlowHolder"
    GlowHolder.BackgroundTransparency = 1
    GlowHolder.AnchorPoint = Vector2.new(0.5, 0.5)
    GlowHolder.Position = UDim2.new(0.58, 0, 0.5, 0)
    GlowHolder.Size = UDim2.new(0, 420, 0, 420)
    GlowHolder.ZIndex = 1
    GlowHolder.Parent = MainHolder

    local RadialGradient = Instance.new("UIGradient")
    RadialGradient.Rotation = 0
    RadialGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(0.6, 0.4),
        NumberSequenceKeypoint.new(1, 1)
    })
    RadialGradient.Parent = GlowHolder

    local GlowImage = Instance.new("ImageLabel")
    GlowImage.Name = "CenterGlow"
    GlowImage.Image = "rbxassetid://9055001972"
    GlowImage.ImageColor3 = Color3.fromRGB(255, 235, 100)
    GlowImage.BackgroundTransparency = 1
    GlowImage.Size = UDim2.new(1, 0, 1, 0)
    GlowImage.ImageTransparency = 0.2
    GlowImage.ZIndex = 1
    GlowImage.Parent = GlowHolder

    task.spawn(function()
        while isUIActive and GlowHolder and GlowHolder.Parent do
            local growTween = UltraTweenService:Create(GlowHolder, TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                Size = UDim2.new(0, 520, 0, 520)
            })
            local growImg = UltraTweenService:Create(GlowImage, TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                ImageTransparency = 0.08
            })
            growTween:Play()
            growImg:Play()
            growTween.Completed:Wait()

            local shrinkTween = UltraTweenService:Create(GlowHolder, TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                Size = UDim2.new(0, 390, 0, 390)
            })
            local shrinkImg = UltraTweenService:Create(GlowImage, TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                ImageTransparency = 0.3
            })
            shrinkTween:Play()
            shrinkImg:Play()
            shrinkTween.Completed:Wait()
        end
    end)

    local MainImage = Instance.new("ImageButton")
    MainImage.Name = "MainCharacterImage"
    MainImage.Image = "rbxassetid://12077128922"
    MainImage.BackgroundTransparency = 1
    MainImage.AutoButtonColor = false
    MainImage.ZIndex = 2
    MainImage.Size = UDim2.new(-1, 0, 1, 0)
    MainImage.Position = UDim2.new(1, 0, 0, 0)
    MainImage.Parent = MainHolder

    local MangaBubble = Instance.new("ImageLabel")
    MangaBubble.Name = "MangaDialogue"
    MangaBubble.Image = "rbxassetid://136797177442983"
    MangaBubble.BackgroundTransparency = 1
    MangaBubble.Size = UDim2.new(0, 320, 0, 220)
    MangaBubble.Position = UDim2.new(1, -410, 0.72, -160)
    MangaBubble.ImageTransparency = 1
    MangaBubble.ZIndex = 3
    MangaBubble.Parent = ScreenGui

    local DialogueText = Instance.new("TextLabel")
    DialogueText.Size = UDim2.new(0.56, 0, 0.56, 0)
    DialogueText.Position = UDim2.new(0.23, 0, 0.20, 0)
    DialogueText.BackgroundTransparency = 1
    DialogueText.Text = getDialogueStep1()
    DialogueText.TextColor3 = Color3.fromRGB(15, 15, 15)
    DialogueText.TextScaled = true
    DialogueText.TextWrapped = true
    DialogueText.Font = Enum.Font.Bangers
    DialogueText.TextTransparency = 1
    DialogueText.ZIndex = 4
    DialogueText.Parent = MangaBubble

    local function playTalkAnimation()
        task.spawn(function()
            local squashTween = UltraTweenService:Create(MainHolder, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 320, 0, 260),
                Rotation = -5
            })
            squashTween:Play()
            squashTween.Completed:Wait()

            local stretchTween = UltraTweenService:Create(MainHolder, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 280, 0, 330),
                Rotation = 5
            })
            stretchTween:Play()
            stretchTween.Completed:Wait()

            local resetTween = UltraTweenService:Create(MainHolder, TweenInfo.new(0.25, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 300, 0, 300),
                Rotation = 0
            })
            resetTween:Play()
        end)
    end

    local enterTween = UltraTweenService:Create(MainHolder, TweenInfo.new(0.55, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = EndPos})
    enterTween:Play()

    enterTween.Completed:Connect(function()
        if not isUIActive or isClosing then return end

        MangaBubble.Size = UDim2.new(0, 0, 0, 0)
        MangaBubble.Position = UDim2.new(1, -250, 0.72, -80)
        MangaBubble.ImageTransparency = 0
        DialogueText.TextTransparency = 0

        local bubbleTween = UltraTweenService:Create(MangaBubble, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 320, 0, 220),
            Position = UDim2.new(1, -410, 0.72, -160)
        })
        bubbleTween:Play()
        playTalkAnimation()
    end)

    local function triggerExitSequence()
        if isClosing or not isUIActive then return end
        isClosing = true
        isUIActive = false

        UltraTweenService:Create(MangaBubble, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            ImageTransparency = 1,
            Size = UDim2.new(0, 350, 0, 240)
        }):Play()

        UltraTweenService:Create(DialogueText, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            TextTransparency = 1
        }):Play()

        local exitTween = UltraTweenService:Create(MainHolder, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Position = StartPos
        })

        UltraTweenService:Create(GlowImage, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            ImageTransparency = 1
        }):Play()

        UltraDisconnect(TogaKeyConn)
        TogaKeyConn = nil
        if TogaCloseFn == triggerExitSequence then TogaCloseFn = nil end
        exitTween:Play()
        exitTween.Completed:Connect(function()
            if ScreenGui and ScreenGui.Parent then ScreenGui:Destroy() end
            if TogaAlertGuiInstance == ScreenGui then TogaAlertGuiInstance = nil end
        end)
    end

    local function handleImpulse()
        if not isUIActive or isClosing or mySession ~= TogaSession then return end

        local currentTime = os.clock()
        if (currentTime - TogaLastImpulseTime) < TogaCooldown then
            return
        end
        TogaLastImpulseTime = currentTime

        TogaImpulseCount = TogaImpulseCount + 1

        if TogaImpulseCount == 1 then
            -- Esquivar antes de tiempo con la tecla: el esquive se alarga hasta cubrir el golpe que
            -- venia (antes podia terminarse justo cuando el ataque llegaba)
            if TogaActiveDodge and UltraPendingDodgeExpectedTime and not UltraDefenseActive then
                UltraQueueHit(TogaActiveDodge, TogaActivePlayer, UltraPendingDodgeExpectedTime, false)
            end
            UltraPendingToken = UltraPendingToken + 1
            UltraPendingDodge = nil
            UltraPendingDodgeData = nil
            UltraPendingDodgeExpectedTime = nil
            if TogaActiveDodge and not UltraDefenseActive then
                UltraBegin(TogaActiveDodge, TogaActivePlayer)
            end

            playTalkAnimation()

            local popOut = UltraTweenService:Create(MangaBubble, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Size = UDim2.new(0, 260, 0, 180)
            })
            popOut:Play()
            popOut.Completed:Wait()

            local locale = (M.Config.Locale or "es"):lower()
            local ft = UltraStrings[locale] or UltraStrings.es
            DialogueText.Text = ft.ultra_dialogue_step2 or UltraStrings.es.ultra_dialogue_step2

            local popIn = UltraTweenService:Create(MangaBubble, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 320, 0, 220)
            })
            popIn:Play()

        elseif TogaImpulseCount >= 2 then
            if UltraDefenseActive then
                UltraDeactivate(true)
            end
            triggerExitSequence()
        end
    end

    TogaCloseFn = triggerExitSequence
    MainImage.MouseButton1Click:Connect(handleImpulse)

    TogaKeyConn = UltraUserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not isUIActive or isClosing or mySession ~= TogaSession then return end
        if UltraUserInputService:GetFocusedTextBox() then return end
        if input.KeyCode == M.Config.DodgeKey or input.KeyCode == Enum.KeyCode.Five or input.KeyCode == Enum.KeyCode.KeypadFive then
            handleImpulse()
        end
    end)
end

local function UltraMoveClone(UltraDeltaTime, UltraCharacter)
    if not M.Config.AllowCloneMovement or not UltraVirtualRootPosition then return end
    local UltraCamera = workspace.CurrentCamera
    if not UltraCamera then return end
    local UltraTyping = UltraUserInputService:GetFocusedTextBox() ~= nil

    local UltraLook = UltraCamera.CFrame.LookVector
    local UltraRight = UltraCamera.CFrame.RightVector
    local UltraForwardFlat = Vector3.new(UltraLook.X, 0, UltraLook.Z)
    local UltraRightFlat = Vector3.new(UltraRight.X, 0, UltraRight.Z)
    if UltraForwardFlat.Magnitude > 0 then UltraForwardFlat = UltraForwardFlat.Unit end
    if UltraRightFlat.Magnitude > 0 then UltraRightFlat = UltraRightFlat.Unit end

    local UltraMovement = Vector3.zero
    if not UltraTyping then
        if UltraUserInputService:IsKeyDown(Enum.KeyCode.W) then UltraMovement = UltraMovement + UltraForwardFlat end
        if UltraUserInputService:IsKeyDown(Enum.KeyCode.S) then UltraMovement = UltraMovement - UltraForwardFlat end
        if UltraUserInputService:IsKeyDown(Enum.KeyCode.D) then UltraMovement = UltraMovement + UltraRightFlat end
        if UltraUserInputService:IsKeyDown(Enum.KeyCode.A) then UltraMovement = UltraMovement - UltraRightFlat end
    end

    local UltraPrev = UltraVirtualRootPosition
    local UltraDesired = UltraPrev
    if UltraMovement.Magnitude > 0 then
        UltraDesired = UltraPrev + UltraMovement.Unit * M.Config.CloneWalkSpeed * UltraDeltaTime
    end
    UltraVirtualRootPosition = UltraFollowGround(UltraPrev, UltraDesired, UltraCharacter)

    local UltraGravity = M.Config.CloneJumpGravity or workspace.Gravity
    if not UltraTyping and UltraUserInputService:IsKeyDown(Enum.KeyCode.Space) and UltraCloneJumpVelocity == 0 and UltraCloneJumpOffset == 0 then
        UltraCloneJumpVelocity = M.Config.CloneJumpVelocity
    end
    if UltraCloneJumpVelocity ~= 0 then
        local UltraNextOffset = UltraCloneJumpOffset + UltraCloneJumpVelocity * UltraDeltaTime - 0.5 * UltraGravity * UltraDeltaTime * UltraDeltaTime
        UltraCloneJumpVelocity = UltraCloneJumpVelocity - UltraGravity * UltraDeltaTime
        if UltraNextOffset <= 0 then
            UltraCloneJumpOffset, UltraCloneJumpVelocity = 0, 0
        else
            UltraCloneJumpOffset = UltraNextOffset
        end
    end
end

local function UltraUpdateCloneAndCamera()
    if not UltraVirtualRootPosition then return end
    local UltraCamera = workspace.CurrentCamera
    local UltraYaw
    if UltraCamera then
        local UltraLook = UltraCamera.CFrame.LookVector
        if Vector3.new(UltraLook.X, 0, UltraLook.Z).Magnitude > 0.01 then
            UltraYaw = math.atan2(-UltraLook.X, -UltraLook.Z)
        end
    end
    local UltraCharacter = UltraLocalPlayer and UltraLocalPlayer.Character
    if UltraCloneModel and UltraCloneRoot then
        if not UltraYaw then
            local _, UltraCurrentYaw = UltraCloneRoot.CFrame:ToOrientation()
            UltraYaw = UltraCurrentYaw
        end
        UltraSyncCloneAnimation(UltraCharacter)
        UltraSyncClonePose(UltraCharacter)
        UltraCloneFootOffset = UltraGetCloneFootOffset(UltraCloneModel, UltraCloneRoot)
        local UltraGroundSurfaceY = UltraVirtualRootPosition.Y - UltraFootOffset
        local UltraClonePosition = Vector3.new(
            UltraVirtualRootPosition.X,
            UltraGroundSurfaceY + UltraCloneFootOffset + UltraCloneJumpOffset + M.Config.CloneGroundEpsilon,
            UltraVirtualRootPosition.Z
        )
        UltraCloneModel:PivotTo(CFrame.new(UltraClonePosition) * CFrame.Angles(0, UltraYaw, 0))
    end
    if UltraCameraSubject then
        UltraCameraSubject.CFrame = CFrame.new(UltraVirtualRootPosition + Vector3.new(0, M.Config.CloneHeadOffset + UltraCloneJumpOffset, 0))
    end
    if UltraSkyPosition and UltraSkyY then
        UltraSkyPosition.Position = Vector3.new(UltraVirtualRootPosition.X, UltraSkyY, UltraVirtualRootPosition.Z)
    end
end

local function UltraDefenseStep(UltraDeltaTime)
    if not UltraDefenseActive then return end
    local UltraDt = math.min(UltraDeltaTime or 0.016, 0.1)
    local UltraCharacter = UltraLocalPlayer and UltraLocalPlayer.Character

    if UltraOmniDriven then
        local UltraRoot = UltraGetRoot(UltraCharacter)
        if UltraRoot and UltraVirtualRootPosition then
            UltraVirtualRootPosition = Vector3.new(UltraRoot.Position.X, UltraVirtualRootPosition.Y, UltraRoot.Position.Z)
        end
        return
    end

    UltraMoveClone(UltraDt, UltraCharacter)
    UltraUpdateCloneAndCamera()

    local UltraCamera = workspace.CurrentCamera
    if UltraCamera and UltraCameraSubject and UltraCamera.CameraSubject ~= UltraCameraSubject then
        UltraCamera.CameraSubject = UltraCameraSubject
    end
end

UltraUnbindMovement = function()
    if UltraMovementBound then
        pcall(function() UltraRunService:UnbindFromRenderStep("UltraCloneMovement") end)
        UltraMovementBound = false
    end
end

UltraBindMovement = function()
    UltraUnbindMovement()
    local UltraOk = pcall(function()
        UltraRunService:BindToRenderStep("UltraCloneMovement", Enum.RenderPriority.Camera.Value - 1, UltraDefenseStep)
    end)
    UltraMovementBound = UltraOk
end

-- Omniblock solo se bloquea cuando el estado activo esta a <= OmniLockLead s (o ya activo).
-- Durante el resto del Delay queda libre para que puedas usarlo.
local function UltraComputeOmniLock(UltraNow)
    if UltraDefenseActive then return true end
    if UltraPendingDodge and UltraPendingDodgeExpectedTime then
        return (UltraPendingDodgeExpectedTime - UltraNow) <= (M.Config.OmniLockLead or 0.5)
    end
    return false
end

local function UltraUpdateExposedData()
    local UltraCharacter = UltraLocalPlayer and UltraLocalPlayer.Character
    if not UltraCharacter then return end

    local function ensureValue(name, className)
        local val = UltraCharacter:FindFirstChild(name)
        if not val or not val:IsA(className) then
            if val then val:Destroy() end
            val = Instance.new(className)
            val.Name = name
            val.Parent = UltraCharacter
        end
        return val
    end

    local alarmVal = ensureValue("Ultra_Alarm", "BoolValue")
    local tpTimeVal = ensureValue("Ultra_TeleportTime", "BoolValue")
    local stateVal = ensureValue("Ultra_SkyCloneState", "BoolValue")
    local threatsVal = ensureValue("Ultra_ThreatsData", "StringValue")
    local countdownVal = ensureValue("Ultra_CloneCountdown", "NumberValue")
    local omniLockVal = ensureValue("Ultra_OmniLock", "BoolValue")
    local newOmniLock = UltraComputeOmniLock(os.clock())
    if omniLockVal.Value ~= newOmniLock then omniLockVal.Value = newOmniLock end

    local hasThreats = false
    local threatList = {}
    for _, t in pairs(UltraThreats) do
        hasThreats = true
        table.insert(threatList, {
            Target = t.Player.Name,
            Ability = t.DodgeDisplayName or t.DodgeName,
            TimeRemaining = math.max(0, t.ExpiresAt - os.clock())
        })
    end

    local newAlarm = hasThreats or UltraDefenseActive
    if alarmVal.Value ~= newAlarm then alarmVal.Value = newAlarm end
    local newState = UltraDefenseActive and (UltraCloneRoot ~= nil) or false
    if stateVal.Value ~= newState then stateVal.Value = newState end

    local isTeleportingSoon = false
    if UltraPendingDodge and UltraPendingDodgeExpectedTime then
        if (UltraPendingDodgeExpectedTime - os.clock()) <= (M.Config.OmniLockLead or 0.5) then
            isTeleportingSoon = true
        end
    end
    if tpTimeVal.Value ~= isTeleportingSoon then tpTimeVal.Value = isTeleportingSoon end

    local cloneCountdown = 0
    if UltraPendingDodge and UltraPendingDodgeExpectedTime then
        cloneCountdown = math.max(0, UltraPendingDodgeExpectedTime - os.clock())
    end
    if math.abs(countdownVal.Value - cloneCountdown) > 0.02 then countdownVal.Value = cloneCountdown end

    local ok, json = pcall(function() return HttpService:JSONEncode(threatList) end)
    local newJson = ok and json or "[]"
    if threatsVal.Value ~= newJson then threatsVal.Value = newJson end
end

local function UltraEngageThreat(UltraDodge, UltraPlayer, UltraRemaining, UltraTrack)
    local UltraNow = os.clock()
    if UltraPlayer and (UltraIgnoredUntil[UltraPlayer] or 0) > UltraNow then return end
    UltraMarkThreat(UltraPlayer, UltraDodge, UltraTrack)

    local UltraExpected = UltraNow + UltraRemaining

    if UltraDefenseActive then
        -- Otro disparador mientras ya esquivas: el esquive dura hasta que ese ataque termine
        -- (antes se contaba desde ahora y no desde que pega) y el clon vuelve a esquivar al pegar
        if M.Config.RefreshOnRepeatedTrigger then
            UltraActiveUntil = math.max(UltraActiveUntil, UltraExpected + UltraDodge.Duration)
            UltraActiveDuration = math.max(UltraActiveDuration, UltraActiveUntil - UltraNow)
        end
        UltraScheduleDodgeAnim(UltraDodge, UltraExpected)
        return
    end

    if UltraPendingDodge then
        if not (UltraPendingDodgeExpectedTime and UltraExpected < UltraPendingDodgeExpectedTime - 0.05) then
            -- Llega mas tarde que el que ya esta pendiente: no se pierde, queda en cola
            UltraQueueHit(UltraDodge, UltraPlayer, UltraExpected, true)
            return
        end
        -- Llega antes: pasa a ser el pendiente y el anterior queda en cola
        if UltraPendingDodgeData and UltraPendingDodgeExpectedTime then
            UltraQueueHit(UltraPendingDodgeData, UltraPendingPlayer, UltraPendingDodgeExpectedTime, true)
        end
    end

    if UltraRemaining <= 0 or UltraGetPingSeconds() >= M.Config.PingInstantThreshold then
        -- Activacion inmediata (sin Delay o con ping alto): el esquive cubre hasta que el ataque termine
        UltraQueueHit(UltraDodge, UltraPlayer, UltraExpected, false)
        UltraBegin(UltraDodge, UltraPlayer)
        return
    end

    local UltraSilent = UltraRemaining < (M.Config.MinNotifyDelay or 0)

    UltraPendingDodge = UltraDodge.Name
    UltraPendingDodgeData = UltraDodge
    UltraPendingPlayer = UltraPlayer
    UltraPendingSilent = UltraSilent
    UltraPendingTotal = math.max(UltraDodge.Delay, UltraRemaining)
    UltraPendingLabel = UltraGetDodgeDisplayName(UltraDodge)
        .. (UltraPlayer and (" · " .. (UltraPlayer.DisplayName or UltraPlayer.Name)) or "")
    UltraPendingToken = UltraPendingToken + 1
    local UltraToken = UltraPendingToken
    UltraPendingDodgeExpectedTime = UltraExpected

    if UltraSilent then
        UltraDestroyTogaAlert()
    else
        UltraOpenTogaAlert(UltraDodge, UltraPlayer)
    end

    task.delay(UltraRemaining, function()
        if UltraToken ~= UltraPendingToken then return end

        UltraPendingDodge = nil
        UltraPendingDodgeExpectedTime = nil
        UltraPendingPlayer = nil

        for _ = 1, 6 do
            if not UltraEnabled or UltraToken ~= UltraPendingToken then return end
            if UltraDefenseActive then return end
            if UltraBegin(UltraDodge, UltraPlayer) then return end
            task.wait(0.1)
        end
    end)
end

local function UltraRegisterDistanceWatch(UltraDodge, UltraPlayer, UltraTrack, UltraNow, UltraKey)
    local UltraElapsed = 0
    if UltraTrack then
        local UltraOk, UltraPos, UltraSpeed = pcall(function() return UltraTrack.TimePosition, UltraTrack.Speed end)
        if UltraOk and type(UltraPos) == "number" then
            UltraElapsed = math.max(0, UltraPos) / math.max(math.abs(tonumber(UltraSpeed) or 1), 0.05)
        end
    end
    local UltraStartedAt = UltraNow - UltraElapsed
    local UltraEndsAt = UltraStartedAt + UltraDodge.Delay + UltraDodge.Duration
    if UltraEndsAt <= UltraNow then return end

    local UltraExisting = UltraDistanceWatches[UltraKey]
    if UltraExisting and math.abs(UltraExisting.StartedAt - UltraStartedAt) < 0.3 then return end

    UltraDistanceWatches[UltraKey] = {
        Dodge = UltraDodge,
        Player = UltraPlayer,
        StartedAt = UltraStartedAt,
        EndsAt = UltraEndsAt,
        LastPos = nil,
        Track = UltraTrack,
    }
end

UltraProcessDistanceWatches = function(UltraNow)
    if next(UltraDistanceWatches) == nil then return end
    local UltraOrigin = UltraGetOriginPosition()
    for UltraKey, UltraWatch in pairs(UltraDistanceWatches) do
        if UltraNow > UltraWatch.EndsAt or not UltraWatch.Player.Parent then
            UltraDistanceWatches[UltraKey] = nil
        else
            local UltraRoot = UltraGetRoot(UltraWatch.Player.Character)
            if UltraRoot then UltraWatch.LastPos = UltraRoot.Position end
            if UltraOrigin and UltraWatch.LastPos then
                local UltraDelta = UltraWatch.LastPos - UltraOrigin
                if M.Config.DistanceMode == "2D" then UltraDelta = Vector3.new(UltraDelta.X, 0, UltraDelta.Z) end
                if UltraDelta.Magnitude <= UltraWatch.Dodge.Distance then
                    UltraDistanceWatches[UltraKey] = nil
                    UltraEngageThreat(UltraWatch.Dodge, UltraWatch.Player, math.max(0, UltraWatch.StartedAt + UltraWatch.Dodge.Delay - UltraNow), UltraWatch.Track)
                end
            end
        end
    end
end

local function UltraTrigger(UltraDodge, UltraPlayer, UltraTrack)
    if not UltraEnabled or not UltraDodge then return end
    local UltraNow = os.clock()
    local UltraKey = tostring(UltraPlayer and UltraPlayer.UserId or 0) .. ":" .. UltraDodge.Name
    if UltraNow - (UltraLastTriggerAt[UltraKey] or -math.huge) < M.Config.SameAnimationCooldown then return end
    UltraLastTriggerAt[UltraKey] = UltraNow

    if UltraDodge.Distance and UltraPlayer then
        UltraRegisterDistanceWatch(UltraDodge, UltraPlayer, UltraTrack, UltraNow, UltraKey)
        return
    end
    -- Si la animacion se detecto tarde (watchdog), se descuenta lo que ya avanzo
    local UltraRemaining = UltraDodge.Delay
    if UltraTrack then
        local UltraOk, UltraPos, UltraSpeed = pcall(function() return UltraTrack.TimePosition, UltraTrack.Speed end)
        if UltraOk and type(UltraPos) == "number" and UltraPos > 0 then
            UltraRemaining = math.max(0, UltraDodge.Delay - UltraPos / math.max(math.abs(tonumber(UltraSpeed) or 1), 0.05))
        end
    end
    UltraEngageThreat(UltraDodge, UltraPlayer, UltraRemaining, UltraTrack)
end

local function UltraOnAnimation(UltraPlayer, UltraTrack)
    local UltraAnimation = UltraTrack and UltraTrack.Animation
    local UltraId = UltraAnimation and UltraAssetNumber(UltraAnimation.AnimationId)
    if UltraId ~= "" then
        UltraTrigger(UltraDodgeByAnimationId[UltraId], UltraPlayer, UltraTrack)
    end
end

local function UltraDisconnectWatch(UltraPlayer)
    local UltraWatch = UltraPlayerWatches[UltraPlayer]
    if UltraWatch then
        UltraDisconnect(UltraWatch.CharacterAdded)
        UltraDisconnect(UltraWatch.AnimationPlayed)
        UltraPlayerWatches[UltraPlayer] = nil
    end
    for UltraKey, UltraDistanceWatch in pairs(UltraDistanceWatches) do
        if UltraDistanceWatch.Player == UltraPlayer then UltraDistanceWatches[UltraKey] = nil end
    end
    local UltraThreat = UltraThreats[UltraPlayer]
    if UltraThreat then UltraDismissThreat(UltraThreat) end
end

local function UltraAttachAnimator(UltraPlayer, UltraWatch, UltraAnimator)
    if UltraWatch.Animator == UltraAnimator and UltraWatch.AnimationPlayed then return end
    UltraDisconnect(UltraWatch.AnimationPlayed)
    UltraWatch.Animator = UltraAnimator
    UltraWatch.Seen = setmetatable({}, { __mode = "k" })
    UltraWatch.AnimationPlayed = UltraAnimator.AnimationPlayed:Connect(function(UltraTrack)
        UltraWatch.Seen[UltraTrack] = true
        UltraOnAnimation(UltraPlayer, UltraTrack)
    end)
    local UltraOk, UltraTracks = pcall(function() return UltraAnimator:GetPlayingAnimationTracks() end)
    if UltraOk and UltraTracks then
        for _, UltraTrack in ipairs(UltraTracks) do
            UltraWatch.Seen[UltraTrack] = true
            UltraOnAnimation(UltraPlayer, UltraTrack)
        end
    end
end

local function UltraHookCharacter(UltraPlayer, UltraCharacter)
    local UltraWatch = UltraPlayerWatches[UltraPlayer]
    if not UltraWatch then return end
    UltraDisconnect(UltraWatch.AnimationPlayed)
    UltraWatch.AnimationPlayed = nil
    UltraWatch.Animator = nil
    task.spawn(function()
        local UltraHumanoid = UltraCharacter:WaitForChild("Humanoid", 5)
        if not UltraEnabled or UltraPlayer.Character ~= UltraCharacter or UltraPlayerWatches[UltraPlayer] ~= UltraWatch or not UltraHumanoid then return end
        local UltraAnimator = UltraHumanoid:FindFirstChildOfClass("Animator") or UltraHumanoid:WaitForChild("Animator", 5)
        if not UltraEnabled or UltraPlayerWatches[UltraPlayer] ~= UltraWatch then return end
        if not UltraAnimator then
            UltraAnimator = Instance.new("Animator")
            UltraAnimator.Parent = UltraHumanoid
        end
        UltraAttachAnimator(UltraPlayer, UltraWatch, UltraAnimator)
    end)
end

local function UltraWatchRemotePlayer(UltraPlayer)
    if UltraPlayer == UltraLocalPlayer or UltraPlayerWatches[UltraPlayer] then return end
    local UltraWatch = {}
    UltraPlayerWatches[UltraPlayer] = UltraWatch
    UltraWatch.CharacterAdded = UltraPlayer.CharacterAdded:Connect(function(UltraCharacter) UltraHookCharacter(UltraPlayer, UltraCharacter) end)
    if UltraPlayer.Character then UltraHookCharacter(UltraPlayer, UltraPlayer.Character) end
end

local function UltraWatchdog()
    for UltraPlayer, UltraWatch in pairs(UltraPlayerWatches) do
        local UltraHumanoid = UltraGetHumanoid(UltraPlayer.Character)
        local UltraAnimator = UltraHumanoid and UltraHumanoid:FindFirstChildOfClass("Animator")
        if UltraAnimator then
            if UltraWatch.Animator ~= UltraAnimator then
                UltraAttachAnimator(UltraPlayer, UltraWatch, UltraAnimator)
            elseif UltraWatch.Seen then
                local UltraOk, UltraTracks = pcall(function() return UltraAnimator:GetPlayingAnimationTracks() end)
                if UltraOk and UltraTracks then
                    for _, UltraTrack in ipairs(UltraTracks) do
                        if not UltraWatch.Seen[UltraTrack] then
                            UltraWatch.Seen[UltraTrack] = true
                            UltraOnAnimation(UltraPlayer, UltraTrack)
                        end
                    end
                end
            end
        end
    end
end

local function UltraHeartbeat(UltraDeltaTime)
    local UltraNow = os.clock()
    for _, UltraThreat in pairs(UltraThreats) do
        if UltraThreat.ExpiresAt <= UltraNow and not UltraIsThreatHeld(UltraThreat) then
            UltraDismissThreat(UltraThreat)
        end
    end

    if UltraNow - UltraLastBeaconSweep >= 0.5 then
        UltraLastBeaconSweep = UltraNow
        UltraSweepOrphanBeacons()
    end

    UltraProcessDistanceWatches(UltraNow)

    if UltraNow - UltraLastWatchdog >= 0.35 then
        UltraLastWatchdog = UltraNow
        UltraWatchdog()
    end

    if UltraNow - UltraLastHudUpdate >= 0.1 then
        UltraLastHudUpdate = UltraNow
        UltraUpdateThreatHud(UltraNow)
    end

    if UltraCloneHighlight and UltraDefenseActive then
        local sineWaveColor = (math.sin(UltraNow * 3) + 1) / 2
        UltraCloneHighlight.OutlineColor = Color3.fromRGB(255, 255, 255):Lerp(Color3.fromRGB(150, 200, 255), sineWaveColor)
    end

    local UltraFreeCharacter = UltraLocalPlayer and UltraLocalPlayer.Character
    local UltraFreeRoot = UltraGetRoot(UltraFreeCharacter)
    if UltraFreeRoot and UltraFreeCharacter then UltraEnforceFallSafety(UltraFreeRoot, UltraFreeCharacter) end

    UltraUpdateExposedData()

    if not UltraDefenseActive then return end
    local UltraCharacter = UltraLocalPlayer and UltraLocalPlayer.Character
    local UltraRoot = UltraGetRoot(UltraCharacter)
    local UltraHumanoid = UltraGetHumanoid(UltraCharacter)
    if not UltraCharacter or not UltraRoot or not UltraHumanoid or UltraHumanoid.Health <= 0 then
        UltraDeactivate(false)
        return
    end

    if not UltraOmniDriven then UltraEnforceSkySafety(UltraRoot, UltraHumanoid) end

    if UltraNow >= UltraActiveUntil then
        UltraDeactivate(not (UltraOmniDriven or UltraIsOmniActive()))
        return
    end

    if not UltraMovementBound then UltraDefenseStep(UltraDeltaTime) end
end

local function UltraStopWatchingEveryone()
    local UltraWatched = {}
    for UltraPlayer in pairs(UltraPlayerWatches) do table.insert(UltraWatched, UltraPlayer) end
    for _, UltraPlayer in ipairs(UltraWatched) do UltraDisconnectWatch(UltraPlayer) end
    UltraDisconnect(UltraPlayerAddedConnection)
    UltraDisconnect(UltraPlayerRemovingConnection)
    UltraPlayerAddedConnection = nil
    UltraPlayerRemovingConnection = nil
    UltraLastTriggerAt = {}
    UltraDistanceWatches = {}
end

function M.Configure(UltraOverrides)
    assert(type(UltraOverrides) == "table", "Configure expects a table")
    UltraMergeConfig(M.Config, UltraOverrides)
    UltraRebuildDodgeIndex()
end

function M.SetDodges(UltraDodges)
    assert(type(UltraDodges) == "table", "SetDodges expects a table")
    M.Config.Dodges = UltraDodges
    UltraRebuildDodgeIndex()
end

function M.SetDodgeKey(keyCode)
    M.Config.DodgeKey = keyCode
end

function M.GetDodgeKey()
    return M.Config.DodgeKey or Enum.KeyCode.Five
end

function M.Start(UltraOverrides)
    if UltraEnabled then M.Stop() end
    if typeof(UltraOverrides) == "Instance" and UltraOverrides:IsA("Player") then UltraOverrides = nil end
    if UltraOverrides then M.Configure(UltraOverrides) else UltraRebuildDodgeIndex() end

    UltraLocalPlayer = UltraPlayers.LocalPlayer or UltraPlayers:GetPropertyChangedSignal("LocalPlayer"):Wait() and UltraPlayers.LocalPlayer
    assert(UltraLocalPlayer, "Ultra Instinct must run on the client")

    -- Restos de versiones anteriores (MUI) que podian bloquear Omniblock o duplicar puntos
    pcall(function()
        local UltraChar = UltraLocalPlayer.Character
        if UltraChar then
            for _, UltraName in ipairs(UltraLegacyValueNames) do
                local UltraVal = UltraChar:FindFirstChild(UltraName)
                if UltraVal then UltraVal:Destroy() end
            end
        end
    end)

    UltraEnabled = true
    UltraBuildHud()
    pcall(UltraSweepOrphanBeacons)
    pcall(UltraEnsureDodgeAnims)
    _reloadLocale()
    for _, UltraPlayer in ipairs(UltraPlayers:GetPlayers()) do UltraWatchRemotePlayer(UltraPlayer) end
    UltraPlayerAddedConnection = UltraPlayers.PlayerAdded:Connect(UltraWatchRemotePlayer)
    UltraPlayerRemovingConnection = UltraPlayers.PlayerRemoving:Connect(UltraDisconnectWatch)
    UltraCharacterRemovingConnection = UltraLocalPlayer.CharacterRemoving:Connect(function()
        UltraPendingToken = UltraPendingToken + 1
        UltraClearQueuedHits(nil)
        UltraPendingDodgeData = nil
        UltraPendingDodge = nil
        UltraPendingDodgeExpectedTime = nil
        UltraPendingPlayer = nil
        UltraDistanceWatches = {}
        UltraDeactivate(false)
    end)
    UltraHeartbeatConnection = UltraRunService.Heartbeat:Connect(UltraHeartbeat)
    UltraRenderConnection = UltraRunService.RenderStepped:Connect(function()
        UltraRenderThreatLines()
        UltraUpdateTopTimer(os.clock())
    end)
end

function M.Stop()
    UltraPendingToken = UltraPendingToken + 1
    UltraClearQueuedHits(nil)
    UltraCancelDodgeAnims()
    UltraPendingDodgeData = nil
    UltraPendingDodge = nil
    UltraPendingDodgeExpectedTime = nil
    UltraPendingPlayer = nil
    UltraUnbindMovement()
    UltraDestroyTogaAlert()
    if UltraDefenseActive then UltraDeactivate(true) end
    UltraEnabled = false
    UltraStopWatchingEveryone()
    UltraDisconnect(UltraHeartbeatConnection)
    UltraDisconnect(UltraRenderConnection)
    UltraDisconnect(UltraCharacterRemovingConnection)
    UltraHeartbeatConnection = nil
    UltraRenderConnection = nil
    UltraCharacterRemovingConnection = nil
    for _, UltraThreat in pairs(UltraThreats) do UltraDismissThreat(UltraThreat) end
    UltraThreats = {}
    pcall(UltraSweepOrphanBeacons)
    if UltraHud then UltraHud:Destroy() end
    if UltraRealBodyLineDraw then pcall(function() UltraRealBodyLineDraw:Remove() end) UltraRealBodyLineDraw = nil end
    if UltraFallPlatform then UltraFallPlatform:Destroy(); UltraFallPlatform = nil end
    UltraHud = nil
    UltraHudCards = nil
    UltraTopTimer = nil
    UltraOmniDriven = false
    UltraLastHudUpdate = 0
    UltraLastWatchdog = 0
    local UltraChar = UltraLocalPlayer and UltraLocalPlayer.Character
    if UltraChar then
        for _, UltraName in ipairs({ "Ultra_Alarm", "Ultra_TeleportTime", "Ultra_SkyCloneState", "Ultra_ThreatsData", "Ultra_CloneCountdown", "Ultra_OmniLock" }) do
            local UltraVal = UltraChar:FindFirstChild(UltraName)
            if UltraVal then pcall(function() UltraVal:Destroy() end) end
        end
    end
end

function M.TriggerDodge(UltraDodgeName)
    for _, UltraDodge in pairs(UltraDodgeByAnimationId) do
        if UltraDodge.Name == UltraDodgeName then
            UltraTrigger(UltraDodge, nil, nil)
            return true
        end
    end
    return false
end

function M.GetCloneCountdown()
    if UltraPendingDodge and UltraPendingDodgeExpectedTime then
        return math.max(0, UltraPendingDodgeExpectedTime - os.clock())
    end
    return 0
end

function M.IsDefenseActive() return UltraDefenseActive end
function M.IsActive() return M.IsDefenseActive() end
function M.GetActiveDodge() return UltraActiveDodgeName end

function M.GetMarkedThreats()
    local UltraResult = {}
    local UltraOrigin = UltraVirtualRootPosition or (UltraGetRoot(UltraLocalPlayer and UltraLocalPlayer.Character) or {}).Position
    for _, UltraThreat in ipairs(UltraThreatList()) do
        local UltraRoot = UltraGetRoot(UltraThreat.Player.Character)
        table.insert(UltraResult, {
            player = UltraThreat.Player,
            name = UltraThreat.Player.Name,
            displayName = UltraThreat.Player.DisplayName,
            ability = UltraThreat.DodgeDisplayName or UltraThreat.DodgeName,
            style = UltraThreat.Style,
            distance = UltraRoot and UltraOrigin and (UltraRoot.Position - UltraOrigin).Magnitude or nil,
            isActiveSource = UltraThreat.Player == UltraActiveSource,
            remaining = UltraThreat.ExpiresAt and math.max(0, UltraThreat.ExpiresAt - os.clock()) or 0,
        })
    end
    return UltraResult
end

function M.GetThreatState()
    return {
        defenseActive = UltraDefenseActive,
        activeDodge = UltraActiveDodgeName,
        activeStyle = UltraActiveStyle,
        activeSource = UltraActiveSource,
        markedThreats = M.GetMarkedThreats(),
    }
end

function M.GetStatus()
    local UltraMarked = M.GetMarkedThreats()
    local UltraPrimary = UltraMarked[1]
    return {
        systemEnabled = UltraEnabled,
        defenseActive = UltraDefenseActive,
        lockActive = UltraDefenseActive,
        omniLock = UltraComputeOmniLock(os.clock()),
        cloneCountdown = M.GetCloneCountdown(),
        target = UltraPrimary and UltraPrimary.player or nil,
        targetName = UltraPrimary and (UltraPrimary.displayName or UltraPrimary.name) or nil,
        distance = UltraPrimary and UltraPrimary.distance or nil,
        activeDodge = UltraActiveDodgeName,
        activeUntilIn = UltraDefenseActive and math.max(0, UltraActiveUntil - os.clock()) or 0,
        dodgeAnimLoaded = UltraGetDodgeAnimApi() ~= nil,
        markedThreats = UltraMarked,
    }
end

M.API = {
    GetMarkedThreats = function() return M.GetMarkedThreats() end,
    IsDefenseActive = function() return M.IsDefenseActive() end,
    GetThreatState = function() return M.GetThreatState() end,
    GetStatus = function() return M.GetStatus() end,
    ForceDismiss = function() if UltraForceDismissAll then UltraForceDismissAll() end end,
}

function M.ForceDismiss()
    if UltraForceDismissAll then UltraForceDismissAll() end
end

function M.IsOmniLocked() return UltraComputeOmniLock(os.clock()) end
M.API.IsOmniLocked = function() return M.IsOmniLocked() end

-- Ultra Instinct lanza Dodge Anims por su cuenta: otros scripts (p. ej. Activador Dodge) lo leen
-- para no dispararlo dos veces a la vez
M.ManagesDodgeAnims = true
M.API.ManagesDodgeAnims = true

-- Ultra Instinct solo se registra y solo reconoce AFO_UI_API.
-- Si ya habia una copia corriendo, se apaga antes de registrarse (dos copias duplicaban
-- HUD, tarjetas y puntos de amenaza sobre el mismo jugador).
if _getgenv then
    pcall(function()
        local UltraGenv = _getgenv()
        local UltraPrev = rawget(UltraGenv, "AFO_UI_API")
        if type(UltraPrev) == "table" and UltraPrev ~= M and type(UltraPrev.Stop) == "function" then
            pcall(UltraPrev.Stop)
        end
        UltraGenv.AFO_UI_API = M
    end)
end

local UltraAutoOk = true
if _getgenv then
    local okFlag, flag = pcall(function() return _getgenv().UI_NO_AUTOSTART end)
    if okFlag and flag then UltraAutoOk = false end
end
if UltraAutoOk then
    task.spawn(function()
        local okStart, errStart = pcall(M.Start)
        if not okStart then warn("[Ultra Instinct] Error al iniciar: " .. tostring(errStart)) end
    end)
end

return M
