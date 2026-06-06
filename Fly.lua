-- ═══════════════════════════════════════════════════════════════════════════
-- MÓDULO: Fly (consolidado)
-- Combina FlyText, FlyAnim, FlyLogic y FlyControl en un solo archivo.
-- ═══════════════════════════════════════════════════════════════════════════

-- ============================================================
-- SERVICIOS Y DEPENDENCIAS
-- ============================================================
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui          = game:GetService("CoreGui")
local SoundService     = game:GetService("SoundService")
local Debris           = game:GetService("Debris")

-- ============================================================
-- FlyText (gestión de idioma)
-- ============================================================
local FlyLang = {
    ES = {
        fly_title        = "  VUELO",
        mode_normal      = "NORMAL",
        mode_fast        = "TURBO  ×",
        mode_mega        = "MEGA  ×",
        mode_megaup      = "⬆ MEGA UP  ×",
        lock_label       = "LOCK",
        lock_hint_prefix = "Apuntar + ",
        noclip_title     = "NOCLIP",
        noclip_space     = "Espacio",
        noclip_ctrl      = "Ctrl (bajar)",
        noclip_mega      = "Mega Turbo",
        height_below     = "studs abajo",
        height_above     = "studs arriba",
        height_same      = "↔ mismo nivel",
        speed_base       = "Vel. base",
        speed_turbo_mult = "Turbo ×",
        speed_mega_mult  = "Mega ×",
        speed_reset      = "🔄  Reset",
    },
    EN = {
        fly_title        = "  FLY",
        mode_normal      = "NORMAL",
        mode_fast        = "TURBO  ×",
        mode_mega        = "MEGA  ×",
        mode_megaup      = "⬆ MEGA UP  ×",
        lock_label       = "LOCK",
        lock_hint_prefix = "Aim + ",
        noclip_title     = "NOCLIP",
        noclip_space     = "Space",
        noclip_ctrl      = "Ctrl (down)",
        noclip_mega      = "Mega Turbo",
        height_below     = "studs below",
        height_above     = "studs above",
        height_same      = "↔ same level",
        speed_base       = "Base speed",
        speed_turbo_mult = "Turbo ×",
        speed_mega_mult  = "Mega ×",
        speed_reset      = "🔄  Reset",
    },
}

local currentLang = "ES"
local FT = FlyLang["ES"]

local function reloadText()
    local lang = "ES"
    pcall(function()
        local data = readfile("AllForOne/lang.txt")
        if data == "EN" or data == "ES" then lang = data end
    end)
    currentLang = lang
    FT = FlyLang[lang]
end
reloadText()

local FlyText = {}
function FlyText.GetText(key) return FT[key] or key end
function FlyText.GetFullTable() local copy = {} for k,v in pairs(FT) do copy[k]=v end return copy end
function FlyText.Reload() reloadText() end
function FlyText.GetCurrentLang() return currentLang end

-- ============================================================
-- FlyAnim (animaciones, poses, combos, bloqueo)
-- ============================================================
local ANIM = {
    idle            = "rbxassetid://107048806104233",
    forward         = "rbxassetid://101776150450756",
    back            = "rbxassetid://92646687237670",
    right           = "rbxassetid://113592486960274",
    left            = "rbxassetid://133459589582592",
    estatica        = "rbxassetid://97171309",
    levitacion      = "rbxassetid://313762630",
    brazos_idle     = "rbxassetid://159223413",
    mov_forward     = "rbxassetid://46196309",
    mov_back_anim   = "rbxassetid://60882887",
    mov_brazos_mov  = "rbxassetid://233077885",
    mov_lateral     = "rbxassetid://204328711",
    espacio_prim    = "rbxassetid://259440107",
    espacio_sec     = "rbxassetid://94861246",
    fast_enter      = "rbxassetid://103438312371909",
    fast_idle       = "rbxassetid://107048806104233",
    fast_move       = "rbxassetid://118488786594461",
    turbo_compact   = "rbxassetid://180612465",
    turbo_burst     = "rbxassetid://129423030",
    turbo_pose      = "rbxassetid://233322916",
    turbo_volado    = "rbxassetid://313762630",
    mega_pose       = "rbxassetid://282574440",
    mega_base       = "rbxassetid://180435571",
    mega_volado     = "rbxassetid://313762630",
    turbo_enter     = "rbxassetid://116114386574305",
    turbo_loop      = "rbxassetid://126091881048662",
    turbo_idle      = "rbxassetid://107048806104233",
    combo1          = "rbxassetid://204062532",
    combo2a         = "rbxassetid://218504594",
    combo2b         = "rbxassetid://218504594",
    combo3a         = "rbxassetid://204062532",
    combo3b         = "rbxassetid://218504594",
    combo4          = "rbxassetid://2954124238",
    combo4_space    = "rbxassetid://45828430",
    sq_anim         = "rbxassetid://82718659527221",
    dq_anim         = "rbxassetid://93831708296422",
    bloqueo         = "rbxassetid://107456513",
}
local CAIDA_BASE_ID    = "rbxassetid://287325678"
local CAIDA_OVERLAY_ID = "rbxassetid://70439247"

local ANIM_NORMAL = {
    COMPENSACION_ALTURA  = 1.5, PARADA_ESTATICA = 0.01, VELOCIDAD_LEVITACION = 0.8,
    TIEMPO_QUIETO = 2, TIEMPO_TRANSICION = 0.5, INICIO_A = 0.40, INICIO_D = 0.85,
    PESO_LATERAL = 0.40, OSCILA_RIGHT = 0.25, OSCILA_LEFT = 0.50, OSCILA_VEL = 0.01,
    DEBOUNCE_TECLADO = 0.08, VEL_ATRAS_NORMAL = 0.06, VEL_ATRAS_RAPIDO = 0.12,
    LATERAL_LERP_VEL = 0.06, TRANSICION_FLUIDA = 0.4, TRANSICION_POS = 0.5,
}
local ANIM_TURBO = {
    COMPENSACION_ALTURA = 2, INCLINACION_GRADOS = 25, FRAME_CONGELADO = 0.1,
    FRAME_VOLADO_CONGELADO = 0.35, AMPLITUD_LEVITACION = 0.15, FRECUENCIA_LEVITACION = 1.5,
    TIEMPO_CONTRAERSE = 0.4, TIEMPO_PAUSA = 0.1, TIEMPO_TRANSICION = 0.4, INCLINACION_DESPEGUE = 90,
}
local ANIM_MEGA = {
    INCLINACION_GRADOS = 45, COMPENSACION_ALTURA = 2, AMPLITUD_LEVITACION = 0.2,
    FRECUENCIA_LEVITACION = 1.5, FRAME_VOLADO_CONGELADO = 0.35, FRAME_POSE_CONGELADO = 0.1,
}
local ANIM_BLOQUEO = {
    INICIO_PERC = 0.25, RESPIRO_PERC = 0.40, OSCILA_MIN = 0.475, OSCILA_RANGE = 0.025,
    VEL_RAPIDO = 4, VEL_LENTO = 0.5,
}
local COMBO_STEP_DURATION = {0.47, 0.47, 0.53, 0.68}
local COMBO_PENDING_WINDOW = 1.0

local function isTyping() return UserInputService:GetFocusedTextBox() ~= nil end

local FlyAnim = {}
-- (las funciones de FlyAnim se inyectarán después de definir flyanim)

-- ============================================================
-- FlyLogic (física, motores, dash, lock, noclip, partículas)
-- ============================================================
local DEFAULT_BASE  = 60
local DEFAULT_FAST  = 3.0
local DEFAULT_TURBO = 6.0
local LOCK_ROTATION_SMOOTH = 0.8
local COORD_SANITY_LIMIT = 50000
local SFX_TURBO        = "rbxassetid://137455842313478"
local SFX_MEGA_TURBO   = "rbxassetid://111391583223900"
local SFX_LANDING      = "rbxassetid://135226467234227"
local SMOKE_RING_TEX   = "rbxassetid://137805272670926"
local AIR_SHOCK_ID     = "rbxassetid://112096280571499"
local SHOCKWAVE_ID     = "rbxassetid://117592591478260"
local RING_ID          = "rbxassetid://12914395250"
local PARTICLE_TEXTURE = "rbxassetid://106822944701902"
local PARTICLE_LENGTH  = 6

local FlyLogic = {}

-- ============================================================
-- FlyControl (orquestador principal)
-- ============================================================
local flyanim = {
    enabled = false, flyKey = Enum.KeyCode.C, lockKey = Enum.KeyCode.X,
    mode = "normal", speed = 60, BASE_SPEED = 60, FAST_MULT = 3.0, TURBO_MULT = 6.0,
    lplr = nil, camera = nil, bg = nil, bv = nil, bf = nil,
    rootJoint = nil, originalC0 = nil, animator = nil, animScript = nil,
    tracks = {}, normalTracks = {},
    wDown = false, sDown = false, aDown = false, dDown = false,
    isWDown = false, isSDown = false, isADown = false, isDDown = false,
    isMoving = false, isSpaceAdv = false, isBlocking = false,
    isBrazosActive = false, megaTurboUpActive = false,
    turboPreImpulsoActivo = false, comboPlaying = false, comboBusy = false,
    combo4Frozen = false, straightLineActive = false, brakingActive = false,
    waitingLand = false, dashTimer = 0, dashVel = Vector3.new(0,0,0),
    lockActive = false, lockedTarget = nil, lockIconGui = nil, lockHighlight = nil,
    lockConn = nil, lockRenderConn = nil,
    noclipSpaceEnabled = true, noclipSpaceActive = false,
    noclipCtrlEnabled = true, noclipCtrlActive = false, noclipMegaEnabled = true,
    gyroProtectionActive = false, antiImpulseConn = nil, anomalyConn = nil,
    teleportGuardConn = nil, lastSafePos = nil, isTeleportGuardActive = false,
    ragdollDetected = false,
    particleRunning = false, particleConn = nil, particleList = {},
    landingHeight = nil, landingVelocity = 0, landingVelocityCapture = 0, landConn = nil,
    gui = nil, updateLbl = nil, updateMode = nil, expanded = false, lockLabels = nil,
    sessionToken = 0, c0ControlToken = 0, c0HeightToken = 0, evalToken = 0,
    idleWatchToken = 0, comboToken = 0, dashAnimToken = 0, turboPreImpulsoToken = 0,
    spaceHoldStart = nil, idleTimer = nil, gyroProtectionTimer = nil, backupGyro = nil,
    spaceHoldTimerAdv = nil, espacioTrackActivo = nil, lastDamageTime = 0,
    fKeyHeld = false, blockCancelledByCombo = false, comboLastClick = 0, comboStep = 0,
    combo2LastUsed = nil, comboAnimStartTime = 0, mouseHeld = false, _normalPlayId = 0,
    turboActivatedAt = 0, qLastPress = 0,
    lateralKilled = true, atrasKilled = true, lateralLoopId = 0, atrasLoopId = 0,
    contA = 0, contD = 0, contS = 0, piernaPrefA = 0.5, piernaPrefD = 0.25, piernaPrefS = 0.5,
    atrasCurrentSpeed = 0.06, lateralTarget = 0, atrasTarget = 0,
    currentLateralId = 0, currentAtrasId = 0, idleTimerAnim = 0,
    DASH_SPEED = 297, DASH_DURATION = 0.38, SIDE_DASH_SPEED = 401,
    TURBO_DASH_SPEED = 405, TURBO_DASH_DURATION = 0.45, BACK_DASH_SPEED = 594,
    SPACE_HOLD_TIME = 2, BRAKE_DISTANCE = 35, BRAKE_HARD_DISTANCE = 14,
    lockCameraLerp = 0.18, ESPACIO_TIEMPO_CAMBIO = 2, ESPACIO_FADE_OUT = 0.1,
}

-- ============================================================
-- FlyAnim - implementación completa
-- ============================================================
local function getTrack(animId)
    if not flyanim.animator then return nil end
    if flyanim.tracks[animId] then return flyanim.tracks[animId] end
    local ok, obj = pcall(function() local a = Instance.new("Animation") a.AnimationId = animId return a end)
    if not ok then return nil end
    local ok2, t = pcall(function() local track = flyanim.animator:LoadAnimation(obj) track.Priority = Enum.AnimationPriority.Action4 return track end)
    if not ok2 or not t then return nil end
    flyanim.tracks[animId] = t
    return t
end

local function stopAllExcept(keepId, fade, alsoKeepLevitacion)
    fade = fade or 0.12
    local levId = ANIM.levitacion
    for id, t in pairs(flyanim.tracks) do
        local isKeep = (id == keepId)
        local isLev  = (alsoKeepLevitacion and id == levId)
        if not isKeep and not isLev and t and t.IsPlaying then pcall(function() t:Stop(fade) end) end
    end
    for _, t in pairs(flyanim.normalTracks) do
        if t and t ~= flyanim.normalTracks.levitacion and t.IsPlaying then pcall(function() t:Stop(fade) end) end
    end
end

local function playAnim(animId, looped, fade)
    local t = getTrack(animId)
    if not t then return end
    fade = fade or 0.18
    t.Looped = looped
    stopAllExcept(animId, fade, true)
    if not t.IsPlaying then pcall(function() t:Play(fade, 1, 1) end) end
end

local function iniciarWatchdogAltura(expectedCF, modeTag)
    flyanim.c0HeightToken = (flyanim.c0HeightToken or 0) + 1
    local myToken = flyanim.c0HeightToken
    if flyanim.c0HeightConn then flyanim.c0HeightConn:Disconnect(); flyanim.c0HeightConn = nil end
    if not expectedCF then return end
    flyanim.c0HeightConn = RunService.Heartbeat:Connect(function()
        if flyanim.c0HeightToken ~= myToken then
            if flyanim.c0HeightConn then flyanim.c0HeightConn:Disconnect(); flyanim.c0HeightConn = nil end
            return
        end
        if not flyanim.enabled then return end
        if flyanim.mode ~= modeTag then return end
        if not flyanim.rootJoint or not flyanim.originalC0 then return end
        if modeTag == "fast" and (flyanim.turboRenderConn or flyanim.turboPreImpulsoActivo) then return end
        if modeTag == "turbo" and flyanim.megaRenderConn then return end
        if flyanim.comboPlaying then return end
        local current = flyanim.rootJoint.C0
        local diff = (current.Position - expectedCF.Position).Magnitude
        if diff > 0.5 then pcall(function() flyanim.rootJoint.C0 = current:Lerp(expectedCF, 0.3) end) end
    end)
end

local function detenerWatchdogAltura()
    flyanim.c0HeightToken = (flyanim.c0HeightToken or 0) + 1
    if flyanim.c0HeightConn then flyanim.c0HeightConn:Disconnect(); flyanim.c0HeightConn = nil end
end

local function restaurarC0Inmediato()
    if flyanim.rootJoint and flyanim.originalC0 then pcall(function() flyanim.rootJoint.C0 = flyanim.originalC0 end) end
    if flyanim.c0DesiredCFrame then flyanim.c0DesiredCFrame = nil end
end

local function detenerNormalTracks(fade)
    fade = fade or 0
    for _, t in pairs(flyanim.normalTracks) do pcall(function() if t and t.IsPlaying then t:Stop(fade) end end) end
    flyanim.lateralKilled = true; flyanim.lateralLoopId = 0
    flyanim.atrasKilled   = true; flyanim.atrasLoopId   = 0
    if flyanim.idleAnimConn then flyanim.idleAnimConn:Disconnect(); flyanim.idleAnimConn = nil end
    flyanim.isBrazosActive = false; flyanim.idleTimerAnim = 0
end

local function obtenerPiernaS()
    local C = ANIM_NORMAL
    if flyanim.isADown then
        flyanim.contA = flyanim.contA + 1
        if flyanim.contA >= 5 then
            flyanim.piernaPrefA = (flyanim.piernaPrefA == C.OSCILA_LEFT) and C.OSCILA_RIGHT or C.OSCILA_LEFT
            flyanim.contA = 0
        end
        return flyanim.piernaPrefA
    elseif flyanim.isDDown then
        flyanim.contD = flyanim.contD + 1
        if flyanim.contD >= 5 then
            flyanim.piernaPrefD = (flyanim.piernaPrefD == C.OSCILA_RIGHT) and C.OSCILA_LEFT or C.OSCILA_RIGHT
            flyanim.contD = 0
        end
        return flyanim.piernaPrefD
    else
        flyanim.contS = flyanim.contS + 1
        if flyanim.contS >= 5 then
            flyanim.piernaPrefS = (flyanim.piernaPrefS == C.OSCILA_LEFT) and C.OSCILA_RIGHT or C.OSCILA_LEFT
            flyanim.contS = 0
        end
        return flyanim.piernaPrefS
    end
end

local function cancelarLateral()
    flyanim.currentLateralId = flyanim.currentLateralId + 1
    flyanim.lateralKilled = true
end

local function ejecutarLateral(inicio, thisId)
    local nt = flyanim.normalTracks
    if not nt.lateral then return end
    while nt.lateral.Length == 0 do task.wait() end
    if flyanim.currentLateralId ~= thisId then return end
    flyanim.lateralTarget = inicio
    flyanim.lateralKilled = false
    if flyanim.lateralLoopId ~= 0 then flyanim.lateralLoopId = thisId; return end
    flyanim.lateralLoopId = thisId
    pcall(function() nt.lateral:Play(0) end)
    nt.lateral:AdjustSpeed(0)
    nt.lateral.TimePosition = nt.lateral.Length * inicio
    nt.lateral:AdjustWeight(ANIM_NORMAL.PESO_LATERAL, ANIM_NORMAL.TRANSICION_FLUIDA)
    local currentPos = inicio
    while true do
        task.wait(0.05)
        if flyanim.lateralKilled then
            pcall(function() nt.lateral:Stop(0) end)
            flyanim.lateralLoopId = 0; flyanim.lateralKilled = false
            return
        end
        if flyanim.currentLateralId ~= flyanim.lateralLoopId then flyanim.lateralLoopId = flyanim.currentLateralId end
        local delta = flyanim.lateralTarget - currentPos
        if math.abs(delta) < ANIM_NORMAL.LATERAL_LERP_VEL then currentPos = flyanim.lateralTarget
        else currentPos = currentPos + (delta > 0 and ANIM_NORMAL.LATERAL_LERP_VEL or -ANIM_NORMAL.LATERAL_LERP_VEL) end
        nt.lateral.TimePosition = nt.lateral.Length * currentPos
    end
end

local function ejecutarDashAtrasAnim(targetStartPercent, velocidadRapida)
    local nt = flyanim.normalTracks
    if not nt.mov_back then return end
    flyanim.atrasTarget = targetStartPercent
    flyanim.atrasKilled = false
    local nuevaVelocidad = velocidadRapida and ANIM_NORMAL.VEL_ATRAS_RAPIDO or ANIM_NORMAL.VEL_ATRAS_NORMAL
    if flyanim.atrasLoopId ~= 0 then
        flyanim.atrasLoopId = flyanim.currentAtrasId
        flyanim.atrasCurrentSpeed = nuevaVelocidad
        return
    end
    flyanim.atrasLoopId = flyanim.currentAtrasId
    flyanim.atrasCurrentSpeed = nuevaVelocidad
    local thisLoop = flyanim.atrasLoopId
    task.spawn(function()
        while nt.mov_back.Length == 0 do task.wait() end
        if flyanim.atrasLoopId ~= thisLoop then return end
        pcall(function() nt.mov_back:Play(0) end)
        if nt.mov_brazos then pcall(function() nt.mov_brazos:Play(0) end) end
        nt.mov_back:AdjustSpeed(0)
        nt.mov_back.TimePosition = nt.mov_back.Length * targetStartPercent
        local currentPos = targetStartPercent
        local oscilaDir = 1; local oscilaTimer = 0
        while true do
            task.wait(0.05)
            if flyanim.atrasKilled then
                nt.mov_back:AdjustSpeed(1)
                pcall(function() nt.mov_back:Stop(0) end)
                if nt.mov_brazos then pcall(function() nt.mov_brazos:Stop(0) end) end
                flyanim.atrasLoopId = 0; flyanim.atrasKilled = false
                return
            end
            if flyanim.currentAtrasId ~= flyanim.atrasLoopId then flyanim.atrasLoopId = flyanim.currentAtrasId end
            local vel = flyanim.atrasCurrentSpeed
            local delta = flyanim.atrasTarget - currentPos
            if math.abs(delta) < vel then currentPos = flyanim.atrasTarget
            else currentPos = currentPos + (delta > 0 and vel or -vel) end
            oscilaTimer = oscilaTimer + 0.05
            if oscilaTimer >= 0.8 then oscilaDir = -oscilaDir; oscilaTimer = 0 end
            local oscilaOffset = oscilaDir * ANIM_NORMAL.OSCILA_VEL * oscilaTimer / 0.8 * 0.04
            nt.mov_back.TimePosition = nt.mov_back.Length * math.clamp(currentPos + oscilaOffset, 0, 1)
        end
    end)
end

local function esDiagonalS()
    return (flyanim.isSDown and flyanim.isADown and not flyanim.isWDown and not flyanim.isDDown) or
           (flyanim.isSDown and flyanim.isDDown and not flyanim.isWDown and not flyanim.isADown)
end

local function resolverEstadoMovimiento()
    local w,s,a,d = flyanim.isWDown, flyanim.isSDown, flyanim.isADown, flyanim.isDDown
    if w and a and d then return "W_SOLO" end
    if s and a and d then return "S_SOLO" end
    if a and d and not w and not s then return "NEUTRAL" end
    if w and a and not d then return "W_A" end
    if w and d and not a then return "W_D" end
    if s and a and not d then return "S_A" end
    if s and d and not a then return "S_D" end
    if w and not s and not a and not d then return "W_SOLO" end
    if s and not w and not a and not d then return "S_SOLO" end
    if a and not d and not w and not s then return "A_SOLO" end
    if d and not a and not w and not s then return "D_SOLO" end
    return "NEUTRAL"
end

local function evaluarMovimientoNormal()
    if not flyanim.enabled or flyanim.mode ~= "normal" then return end
    if flyanim.comboPlaying or flyanim.isBlocking then return end
    if flyanim.isSpaceAdv then return end
    if flyanim.turboPreImpulsoActivo then return end
    local nt = flyanim.normalTracks
    if not nt.mov_forward then
        if not flyanim.isWDown and not flyanim.isSDown and not flyanim.isADown and not flyanim.isDDown then playAnim(ANIM.idle, true)
        elseif flyanim.isDDown then playAnim(ANIM.right, true)
        elseif flyanim.isADown then playAnim(ANIM.left, true)
        elseif flyanim.isSDown then playAnim(ANIM.back, true)
        else playAnim(ANIM.forward, true) end
        return
    end
    local estado = resolverEstadoMovimiento()
    local C = ANIM_NORMAL

    local function matarAtras() flyanim.currentAtrasId = flyanim.currentAtrasId + 1; flyanim.atrasKilled = true end
    local function relanzarAtras()
        local pierna = obtenerPiernaS()
        local esRapido = esDiagonalS()
        flyanim.currentAtrasId = flyanim.currentAtrasId + 1
        flyanim.atrasKilled = false
        ejecutarDashAtrasAnim(pierna, esRapido)
    end
    local function matarLateral() cancelarLateral() end
    local function relanzarLateral(destino)
        flyanim.currentLateralId = flyanim.currentLateralId + 1
        flyanim.lateralKilled = false
        local thisId = flyanim.currentLateralId
        task.spawn(function() ejecutarLateral(destino, thisId) end)
    end

    if estado == "W_SOLO" then
        matarAtras(); matarLateral()
        pcall(function() nt.mov_forward:Play(0) end)
    elseif estado == "S_SOLO" then
        matarLateral()
        pcall(function() nt.mov_forward:Stop(0) end)
        relanzarAtras()
    elseif estado == "W_A" then
        matarAtras()
        pcall(function() nt.mov_forward:Play(0) end)
        nt.mov_forward:AdjustWeight(1.0, C.TRANSICION_FLUIDA)
        relanzarLateral(C.INICIO_A)
    elseif estado == "W_D" then
        matarAtras()
        pcall(function() nt.mov_forward:Play(0) end)
        nt.mov_forward:AdjustWeight(1.0, C.TRANSICION_FLUIDA)
        relanzarLateral(C.INICIO_D)
    elseif estado == "S_A" then
        pcall(function() nt.mov_forward:Stop(0) end)
        relanzarAtras(); relanzarLateral(C.INICIO_A)
    elseif estado == "S_D" then
        pcall(function() nt.mov_forward:Stop(0) end)
        relanzarAtras(); relanzarLateral(C.INICIO_D)
    elseif estado == "A_SOLO" then
        matarAtras()
        pcall(function() nt.mov_forward:Play(0) end)
        nt.mov_forward:AdjustWeight(1.0, C.TRANSICION_FLUIDA)
        relanzarLateral(C.INICIO_A)
    elseif estado == "D_SOLO" then
        matarAtras()
        pcall(function() nt.mov_forward:Play(0) end)
        nt.mov_forward:AdjustWeight(1.0, C.TRANSICION_FLUIDA)
        relanzarLateral(C.INICIO_D)
    else
        matarAtras(); matarLateral()
        pcall(function() nt.mov_forward:Stop(0) end)
        if nt.mov_brazos and nt.mov_brazos.IsPlaying then pcall(function() nt.mov_brazos:Stop(0) end) end
        if flyanim.enabled and flyanim.mode == "normal" and not flyanim.comboPlaying then
            local nt2 = flyanim.normalTracks
            if nt2.estatica and not nt2.estatica.IsPlaying then
                nt2.estatica:Play(ANIM_NORMAL.TRANSICION_FLUIDA)
                task.spawn(function()
                    while nt2.estatica.Length == 0 do task.wait() end
                    task.wait(nt2.estatica.Length * ANIM_NORMAL.PARADA_ESTATICA)
                    if flyanim.enabled and flyanim.mode == "normal" then nt2.estatica:AdjustSpeed(0) end
                end)
            end
            if nt2.levitacion and not nt2.levitacion.IsPlaying then
                nt2.levitacion:Play(ANIM_NORMAL.TRANSICION_FLUIDA)
                nt2.levitacion:AdjustSpeed(ANIM_NORMAL.VELOCIDAD_LEVITACION)
            end
            if not flyanim.idleAnimConn then
                flyanim._normalPlayId = (flyanim._normalPlayId or 0) + 1
                iniciarCicloNormal(flyanim, flyanim._normalPlayId)
            else flyanim.idleTimerAnim = 0 end
        end
    end
end

local function evaluarMovimientoDebounced()
    flyanim.evalToken = flyanim.evalToken + 1
    local token = flyanim.evalToken
    task.delay(ANIM_NORMAL.DEBOUNCE_TECLADO, function() if flyanim.evalToken == token then evaluarMovimientoNormal() end end)
end

function iniciarCicloNormal(flyanim, thisPlay)
    local nt = flyanim.normalTracks
    if not nt.estatica or not nt.levitacion then return end
    flyanim.c0ControlToken = (flyanim.c0ControlToken or 0) + 1
    detenerWatchdogAltura()
    restaurarC0Inmediato()
    if nt.estatica.IsPlaying then pcall(function() nt.estatica:Stop(0) end) end
    pcall(function() nt.estatica:Play(ANIM_NORMAL.TRANSICION_FLUIDA) end)
    if not nt.levitacion.IsPlaying then pcall(function() nt.levitacion:Play(ANIM_NORMAL.TRANSICION_FLUIDA) end) end
    pcall(function() nt.levitacion:AdjustSpeed(ANIM_NORMAL.VELOCIDAD_LEVITACION) end)
    if flyanim.actualizarPosicionNormal then flyanim.actualizarPosicionNormal(ANIM_NORMAL.COMPENSACION_ALTURA, ANIM_NORMAL.TRANSICION_POS) end
    task.spawn(function()
        local to = tick() + 3
        while nt.estatica.Length == 0 and tick() < to do task.wait() end
        task.wait(nt.estatica.Length * ANIM_NORMAL.PARADA_ESTATICA)
        if flyanim.enabled and flyanim.mode == "normal" and thisPlay == flyanim._normalPlayId then pcall(function() nt.estatica:AdjustSpeed(0) end) end
    end)
    flyanim.idleTimerAnim = 0; flyanim.isBrazosActive = false
    if flyanim.idleAnimConn then flyanim.idleAnimConn:Disconnect() end
    flyanim.idleWatchToken = (flyanim.idleWatchToken or 0) + 1
    local myIdleToken = flyanim.idleWatchToken
    flyanim.idleAnimConn = RunService.Heartbeat:Connect(function(dt)
        if not flyanim.enabled or flyanim.mode ~= "normal" then if flyanim.idleAnimConn then flyanim.idleAnimConn:Disconnect(); flyanim.idleAnimConn = nil end return end
        if myIdleToken ~= flyanim.idleWatchToken then if flyanim.idleAnimConn then flyanim.idleAnimConn:Disconnect(); flyanim.idleAnimConn = nil end return end
        if flyanim.comboPlaying or flyanim.isBlocking then return end
        if nt.levitacion and not nt.levitacion.IsPlaying then pcall(function() nt.levitacion:Play(0.2); nt.levitacion:AdjustSpeed(ANIM_NORMAL.VELOCIDAD_LEVITACION) end) end
        if nt.estatica and not nt.estatica.IsPlaying and not flyanim.isWDown and not flyanim.isSDown and not flyanim.isADown and not flyanim.isDDown and not flyanim.isSpaceAdv and not flyanim.comboPlaying then
            pcall(function() nt.estatica:Play(ANIM_NORMAL.TRANSICION_FLUIDA) end)
            task.spawn(function()
                local to = tick() + 3
                while nt.estatica.Length == 0 and tick() < to do task.wait() end
                task.wait(nt.estatica.Length * ANIM_NORMAL.PARADA_ESTATICA)
                if flyanim.enabled and flyanim.mode == "normal" and myIdleToken == flyanim.idleWatchToken then pcall(function() nt.estatica:AdjustSpeed(0) end) end
            end)
        end
        local isMovingAdv = flyanim.isWDown or flyanim.isSDown or flyanim.isADown or flyanim.isDDown or flyanim.isSpaceAdv or flyanim.megaTurboUpActive
        if not isMovingAdv then
            flyanim.idleTimerAnim = flyanim.idleTimerAnim + dt
            if flyanim.idleTimerAnim >= ANIM_NORMAL.TIEMPO_QUIETO and not flyanim.isBrazosActive then
                flyanim.isBrazosActive = true
                if nt.brazos then pcall(function() nt.brazos:Play(ANIM_NORMAL.TIEMPO_TRANSICION) end) end
            end
        else
            flyanim.idleTimerAnim = 0
            if flyanim.isBrazosActive then
                flyanim.isBrazosActive = false
                local fadeBrazos = (flyanim.isSpaceAdv or flyanim.megaTurboUpActive) and 0.05 or ANIM_NORMAL.TIEMPO_TRANSICION
                if nt.brazos then pcall(function() nt.brazos:Stop(fadeBrazos) end) end
            end
        end
    end)
end

function iniciarPoseTurbo()
    flyanim.turboPreImpulsoActivo = true
    flyanim.turboPreImpulsoToken = (flyanim.turboPreImpulsoToken or 0) + 1
    local myToken = flyanim.turboPreImpulsoToken
    flyanim.idleWatchToken = (flyanim.idleWatchToken or 0) + 1
    if flyanim.idleAnimConn then flyanim.idleAnimConn:Disconnect(); flyanim.idleAnimConn = nil end
    detenerNormalTracks(0.1)
    detenerWatchdogAltura()
    if flyanim.turboRenderConn then flyanim.turboRenderConn:Disconnect(); flyanim.turboRenderConn = nil end
    local char = flyanim.lplr.Character
    if not char then flyanim.turboPreImpulsoActivo = false; return end
    local rootJoint = flyanim.rootJoint; local originalC0 = flyanim.originalC0
    if not rootJoint or not originalC0 then flyanim.turboPreImpulsoActivo = false; return end
    local nt = flyanim.normalTracks
    if not nt.turbo_pose or not nt.turbo_volado then flyanim.turboPreImpulsoActivo = false; return end
    for _, t in pairs(flyanim.tracks) do pcall(function() if t and t.IsPlaying then t:Stop(0.05) end end) end
    flyanim.turboTransitioning = true
    flyanim.c0ControlToken = (flyanim.c0ControlToken or 0) + 1
    local myC0Token = flyanim.c0ControlToken
    local preImpulsoBlockConn
    preImpulsoBlockConn = RunService.RenderStepped:Connect(function()
        if not flyanim.turboPreImpulsoActivo or flyanim.turboPreImpulsoToken ~= myToken then preImpulsoBlockConn:Disconnect(); return end
        if flyanim.animator then
            local ok, tracks = pcall(function() return flyanim.animator:GetPlayingAnimationTracks() end)
            if ok and tracks then
                for _, t in ipairs(tracks) do
                    local animId = t.Animation and t.Animation.AnimationId or ""
                    local isTurboAnim = (animId == ANIM.turbo_compact or animId == ANIM.turbo_burst or animId == ANIM.turbo_pose or animId == ANIM.turbo_volado)
                    if not isTurboAnim then pcall(function() t:Stop(0) end) end
                end
            end
        end
    end)
    task.spawn(function()
        local function debeAbortarPreImpulso()
            if flyanim.turboPreImpulsoToken ~= myToken then return true end
            if not flyanim.enabled or flyanim.mode ~= "fast" then return true end
            return false
        end
        local function abortarYVolver()
            pcall(function() preImpulsoBlockConn:Disconnect() end)
            if flyanim.turboRenderConn then flyanim.turboRenderConn:Disconnect(); flyanim.turboRenderConn = nil end
            flyanim.turboPreImpulsoActivo = false; flyanim.turboTransitioning = false
            flyanim.c0ControlToken = (flyanim.c0ControlToken or 0) + 1
            detenerWatchdogAltura(); restaurarC0Inmediato()
            if nt.turbo_compact then pcall(function() nt.turbo_compact:Stop(0.05) end) end
            if nt.turbo_burst then pcall(function() nt.turbo_burst:Stop(0.05) end) end
            if nt.turbo_pose then pcall(function() nt.turbo_pose:Stop(0.05) end) end
            if nt.turbo_volado then pcall(function() nt.turbo_volado:Stop(0.05) end) end
            for _, t in pairs(flyanim.tracks) do pcall(function() if t and t.IsPlaying then t:Stop(0.05) end end) end
            for _, t in pairs(flyanim.normalTracks) do pcall(function() if t and t.IsPlaying then t:Stop(0.05) end end) end
            if flyanim.mode == "fast" then flyanim.mode = "normal"; flyanim.speed = flyanim.BASE_SPEED; if flyanim.updateMode then flyanim.updateMode("normal") end end
            if flyanim.setNoclip then flyanim.setNoclip(false) end
            if flyanim.stopParticleEmitter then flyanim.stopParticleEmitter() end
            task.wait(0.05)
            if flyanim.enabled and flyanim.mode == "normal" then
                flyanim.idleWatchToken = (flyanim.idleWatchToken or 0) + 1
                if flyanim.idleAnimConn then flyanim.idleAnimConn:Disconnect(); flyanim.idleAnimConn = nil end
                flyanim._normalPlayId = (flyanim._normalPlayId or 0) + 1
                iniciarCicloNormal(flyanim, flyanim._normalPlayId)
                task.delay(0.1, function() if flyanim.enabled and flyanim.mode == "normal" then evaluarMovimientoNormal() end end)
            end
        end
        if nt.turbo_compact then nt.turbo_compact.Looped = false; pcall(function() nt.turbo_compact:Play(0.05); nt.turbo_compact:AdjustSpeed(3.0) end) end
        local startT = tick()
        while tick() - startT < ANIM_TURBO.TIEMPO_CONTRAERSE do
            if debeAbortarPreImpulso() then if nt.turbo_compact then pcall(function() nt.turbo_compact:Stop(0.1) end) end; abortarYVolver(); return end
            local t = (tick() - startT) / ANIM_TURBO.TIEMPO_CONTRAERSE
            if myC0Token == flyanim.c0ControlToken then pcall(function() rootJoint.C0 = originalC0 * CFrame.Angles(math.rad(t * ANIM_TURBO.INCLINACION_DESPEGUE), 0, 0) end) end
            task.wait()
        end
        if debeAbortarPreImpulso() then if nt.turbo_compact then pcall(function() nt.turbo_compact:Stop(0.1) end) end; abortarYVolver(); return end
        if myC0Token == flyanim.c0ControlToken then pcall(function() rootJoint.C0 = originalC0 * CFrame.Angles(math.rad(ANIM_TURBO.INCLINACION_DESPEGUE), 0, 0) end) end
        if nt.turbo_compact then pcall(function() nt.turbo_compact:AdjustSpeed(0) end) end
        task.wait(ANIM_TURBO.TIEMPO_PAUSA)
        if debeAbortarPreImpulso() then if nt.turbo_compact then pcall(function() nt.turbo_compact:Stop(0.1) end) end; abortarYVolver(); return end
        if nt.turbo_compact then pcall(function() nt.turbo_compact:Stop(0.05) end) end
        if nt.turbo_burst then nt.turbo_burst.Looped = false; pcall(function() nt.turbo_burst:Play(0.05); nt.turbo_burst:AdjustSpeed(2.5) end) end
        task.wait(0.2)
        if debeAbortarPreImpulso() then if nt.turbo_burst then pcall(function() nt.turbo_burst:Stop(0.1) end) end; abortarYVolver(); return end
        if nt.turbo_pose then nt.turbo_pose.Looped = true; pcall(function() nt.turbo_pose:Play(0.2) end) end
        if nt.turbo_volado then nt.turbo_volado.Looped = true; pcall(function() nt.turbo_volado:Play(0.2) end) end
        if nt.turbo_burst then pcall(function() nt.turbo_burst:Stop(0.4) end) end
        local cframeDespegue = originalC0 * CFrame.Angles(math.rad(ANIM_TURBO.INCLINACION_DESPEGUE), 0, 0)
        local cframeVuelo = originalC0 * CFrame.new(0, ANIM_TURBO.COMPENSACION_ALTURA, 0) * CFrame.Angles(math.rad(ANIM_TURBO.INCLINACION_GRADOS), 0, 0)
        startT = tick()
        while tick() - startT < ANIM_TURBO.TIEMPO_TRANSICION do
            if debeAbortarPreImpulso() then if nt.turbo_pose then pcall(function() nt.turbo_pose:Stop(0.2) end) end; if nt.turbo_volado then pcall(function() nt.turbo_volado:Stop(0.2) end) end; abortarYVolver(); return end
            local t = (tick() - startT) / ANIM_TURBO.TIEMPO_TRANSICION
            if myC0Token == flyanim.c0ControlToken then pcall(function() rootJoint.C0 = cframeDespegue:Lerp(cframeVuelo, t) end) end
            if nt.turbo_pose and nt.turbo_pose.IsPlaying then pcall(function() nt.turbo_pose.TimePosition = ANIM_TURBO.FRAME_CONGELADO; nt.turbo_pose:AdjustSpeed(0) end) end
            if nt.turbo_volado and nt.turbo_volado.IsPlaying then pcall(function() nt.turbo_volado.TimePosition = ANIM_TURBO.FRAME_VOLADO_CONGELADO; nt.turbo_volado:AdjustSpeed(0) end) end
            task.wait()
        end
        if not flyanim.enabled then flyanim.turboTransitioning = false; flyanim.turboPreImpulsoActivo = false; pcall(function() preImpulsoBlockConn:Disconnect() end); flyanim.c0ControlToken = (flyanim.c0ControlToken or 0) + 1; detenerWatchdogAltura(); restaurarC0Inmediato(); return end
        pcall(function() preImpulsoBlockConn:Disconnect() end)
        flyanim.turboPreImpulsoActivo = false
        if flyanim.turboRenderConn then flyanim.turboRenderConn:Disconnect() end
        local myC0TkLoop = flyanim.c0ControlToken
        local cframeVueloRef = originalC0 * CFrame.new(0, ANIM_TURBO.COMPENSACION_ALTURA, 0) * CFrame.Angles(math.rad(ANIM_TURBO.INCLINACION_GRADOS), 0, 0)
        flyanim.turboRenderConn = RunService.RenderStepped:Connect(function()
            if not flyanim.enabled or flyanim.mode ~= "fast" then if flyanim.turboRenderConn then flyanim.turboRenderConn:Disconnect(); flyanim.turboRenderConn = nil end; if myC0TkLoop == flyanim.c0ControlToken then detenerWatchdogAltura(); restaurarC0Inmediato() end; return end
            if myC0TkLoop ~= flyanim.c0ControlToken then return end
            if nt.turbo_pose and nt.turbo_pose.IsPlaying then pcall(function() nt.turbo_pose:AdjustSpeed(0); nt.turbo_pose.TimePosition = ANIM_TURBO.FRAME_CONGELADO end) elseif nt.turbo_pose and not nt.turbo_pose.IsPlaying then nt.turbo_pose.Looped = true; pcall(function() nt.turbo_pose:Play(0.1); nt.turbo_pose:AdjustSpeed(0) end) end
            if nt.turbo_volado and nt.turbo_volado.IsPlaying then pcall(function() nt.turbo_volado:AdjustSpeed(0); nt.turbo_volado.TimePosition = ANIM_TURBO.FRAME_VOLADO_CONGELADO end) elseif nt.turbo_volado and not nt.turbo_volado.IsPlaying then nt.turbo_volado.Looped = true; pcall(function() nt.turbo_volado:Play(0.1); nt.turbo_volado:AdjustSpeed(0) end) end
            local movimientoY = math.sin(tick() * ANIM_TURBO.FRECUENCIA_LEVITACION) * ANIM_TURBO.AMPLITUD_LEVITACION
            local targetCF = originalC0 * CFrame.new(0, ANIM_TURBO.COMPENSACION_ALTURA + movimientoY, 0) * CFrame.Angles(math.rad(ANIM_TURBO.INCLINACION_GRADOS), 0, 0)
            pcall(function() rootJoint.C0 = targetCF end)
        end)
        flyanim.turboTransitioning = false
        task.spawn(function()
            task.wait(0.1)
            if not flyanim.enabled or flyanim.mode ~= "fast" then return end
            if flyanim.turboPreImpulsoActivo then return end
            flyanim.idleWatchToken = (flyanim.idleWatchToken or 0) + 1
            local myIdleToken = flyanim.idleWatchToken
            if flyanim.idleAnimConn then flyanim.idleAnimConn:Disconnect(); flyanim.idleAnimConn = nil end
            flyanim.idleTimerAnim = 0; flyanim.isBrazosActive = false
            local ntl = flyanim.normalTracks
            if ntl.levitacion and not ntl.levitacion.IsPlaying then pcall(function() ntl.levitacion:Play(ANIM_NORMAL.TRANSICION_FLUIDA); ntl.levitacion:AdjustSpeed(ANIM_NORMAL.VELOCIDAD_LEVITACION) end) end
            flyanim.idleAnimConn = RunService.Heartbeat:Connect(function(dt)
                if not flyanim.enabled or flyanim.mode ~= "fast" then if flyanim.idleAnimConn then flyanim.idleAnimConn:Disconnect(); flyanim.idleAnimConn = nil end; return end
                if myIdleToken ~= flyanim.idleWatchToken then if flyanim.idleAnimConn then flyanim.idleAnimConn:Disconnect(); flyanim.idleAnimConn = nil end; return end
                if flyanim.turboPreImpulsoActivo then return end
                if flyanim.comboPlaying or flyanim.isBlocking then return end
                if ntl.levitacion and not ntl.levitacion.IsPlaying then pcall(function() ntl.levitacion:Play(0.2); ntl.levitacion:AdjustSpeed(ANIM_NORMAL.VELOCIDAD_LEVITACION) end) end
                local isMovingAdv = flyanim.isWDown or flyanim.isSDown or flyanim.isADown or flyanim.isDDown or flyanim.megaTurboUpActive
                if not isMovingAdv then
                    flyanim.idleTimerAnim = flyanim.idleTimerAnim + dt
                    if flyanim.idleTimerAnim >= ANIM_NORMAL.TIEMPO_QUIETO and not flyanim.isBrazosActive then
                        flyanim.isBrazosActive = true
                        if ntl.brazos then pcall(function() ntl.brazos:Play(ANIM_NORMAL.TIEMPO_TRANSICION) end) end
                    end
                else
                    flyanim.idleTimerAnim = 0
                    if flyanim.isBrazosActive then
                        flyanim.isBrazosActive = false
                        local fadeBrazos = flyanim.megaTurboUpActive and 0.05 or ANIM_NORMAL.TIEMPO_TRANSICION
                        if ntl.brazos then pcall(function() ntl.brazos:Stop(fadeBrazos) end) end
                    end
                end
            end)
        end)
    end)
end

function detenerPoseTurbo()
    flyanim.turboPreImpulsoActivo = false
    flyanim.turboPreImpulsoToken = (flyanim.turboPreImpulsoToken or 0) + 1
    if flyanim.turboRenderConn then flyanim.turboRenderConn:Disconnect(); flyanim.turboRenderConn = nil end
    local nt = flyanim.normalTracks
    if nt.turbo_pose then pcall(function() nt.turbo_pose:Stop(0.3) end) end
    if nt.turbo_volado then pcall(function() nt.turbo_volado:Stop(0.3) end) end
    if nt.turbo_burst then pcall(function() nt.turbo_burst:Stop(0.1) end) end
    if nt.turbo_compact then pcall(function() nt.turbo_compact:Stop(0.1) end) end
    flyanim.c0ControlToken = (flyanim.c0ControlToken or 0) + 1
    detenerWatchdogAltura()
    restaurarC0Inmediato()
end

function iniciarPoseMega()
    detenerNormalTracks(0.1)
    detenerPoseTurbo()
    detenerWatchdogAltura()
    if flyanim.megaRenderConn then flyanim.megaRenderConn:Disconnect(); flyanim.megaRenderConn = nil end
    local rootJoint = flyanim.rootJoint; local originalC0 = flyanim.originalC0
    if not rootJoint or not originalC0 then return end
    local nt = flyanim.normalTracks
    if not nt.mega_pose then return end
    if nt.mega_pose then nt.mega_pose.Looped = true; pcall(function() nt.mega_pose:Play(0.2); nt.mega_pose:AdjustSpeed(0.1) end) end
    if nt.mega_base then nt.mega_base.Looped = true; pcall(function() nt.mega_base:Play(0.2); nt.mega_base:AdjustSpeed(0.1) end) end
    if nt.mega_volado then nt.mega_volado.Looped = true; pcall(function() nt.mega_volado:Play(0.2) end) end
    flyanim.c0ControlToken = (flyanim.c0ControlToken or 0) + 1
    local myC0Token = flyanim.c0ControlToken
    flyanim.megaRenderConn = RunService.RenderStepped:Connect(function()
        if not flyanim.enabled or flyanim.mode ~= "turbo" then if flyanim.megaRenderConn then flyanim.megaRenderConn:Disconnect(); flyanim.megaRenderConn = nil end; if myC0Token == flyanim.c0ControlToken then detenerWatchdogAltura(); restaurarC0Inmediato() end; return end
        if myC0Token ~= flyanim.c0ControlToken then return end
        if nt.mega_volado and nt.mega_volado.IsPlaying then pcall(function() nt.mega_volado:AdjustSpeed(0); nt.mega_volado.TimePosition = ANIM_MEGA.FRAME_VOLADO_CONGELADO end) elseif nt.mega_volado and not nt.mega_volado.IsPlaying then nt.mega_volado.Looped = true; pcall(function() nt.mega_volado:Play(0.1); nt.mega_volado:AdjustSpeed(0) end) end
        local movimientoY = math.sin(tick() * ANIM_MEGA.FRECUENCIA_LEVITACION) * ANIM_MEGA.AMPLITUD_LEVITACION
        pcall(function() rootJoint.C0 = originalC0 * CFrame.new(0, ANIM_MEGA.COMPENSACION_ALTURA + movimientoY, 0) * CFrame.Angles(math.rad(ANIM_MEGA.INCLINACION_GRADOS), 0, 0) end)
    end)
end

function detenerPoseMega()
    if flyanim.megaRenderConn then flyanim.megaRenderConn:Disconnect(); flyanim.megaRenderConn = nil end
    local nt = flyanim.normalTracks
    if nt.mega_pose then pcall(function() nt.mega_pose:Stop(0.3) end) end
    if nt.mega_base then pcall(function() nt.mega_base:Stop(0.3) end) end
    if nt.mega_volado then pcall(function() nt.mega_volado:Stop(0.3) end) end
    flyanim.c0ControlToken = (flyanim.c0ControlToken or 0) + 1
    detenerWatchdogAltura()
    restaurarC0Inmediato()
end

function setupBlockTrack()
    if not flyanim.animator then return end
    local animObj = Instance.new("Animation")
    animObj.AnimationId = ANIM.bloqueo
    local ok, t = pcall(function() return flyanim.animator:LoadAnimation(animObj) end)
    if not ok or not t then return end
    flyanim.blockTrack = t
    flyanim.blockTrack.Priority = Enum.AnimationPriority.Action4
    flyanim.blockTrack.Looped = true
    pcall(function() flyanim.blockTrack:Play(0, 0, 0) end)
end

function startBlocking()
    if not flyanim.enabled then return end
    if flyanim.mode ~= "normal" then return end
    if flyanim.turboPreImpulsoActivo then return end
    if flyanim.blockCancelledByCombo then return end
    local bt = flyanim.blockTrack
    if not bt or flyanim.isBlocking then return end
    flyanim.isBlocking = true
    local length = bt.Length > 0 and bt.Length or 1
    pcall(function() bt:Play(0, 1, ANIM_BLOQUEO.VEL_RAPIDO) end)
    bt.TimePosition = length * ANIM_BLOQUEO.INICIO_PERC
    if flyanim.blockRenderConn then flyanim.blockRenderConn:Disconnect() end
    local state = "MOVING"
    flyanim.blockRenderConn = RunService.Heartbeat:Connect(function()
        if not flyanim.isBlocking or not flyanim.enabled then return end
        if flyanim.mode ~= "normal" then flyanim.isBlocking = false; if flyanim.blockRenderConn then flyanim.blockRenderConn:Disconnect(); flyanim.blockRenderConn = nil end; if flyanim.blockTrack and flyanim.blockTrack.IsPlaying then pcall(function() flyanim.blockTrack:Stop(0.1) end) end; return end
        if state == "MOVING" then
            if bt.TimePosition >= length * ANIM_BLOQUEO.RESPIRO_PERC then state = "BREATHING"; pcall(function() bt:AdjustSpeed(ANIM_BLOQUEO.VEL_LENTO) end) end
        elseif state == "BREATHING" then
            local t = os.clock(); pcall(function() bt.TimePosition = length * (ANIM_BLOQUEO.OSCILA_MIN + (ANIM_BLOQUEO.OSCILA_RANGE * math.sin(t * 2))) end)
        end
    end)
end

function stopBlocking()
    flyanim.isBlocking = false
    if flyanim.blockRenderConn then flyanim.blockRenderConn:Disconnect(); flyanim.blockRenderConn = nil end
    if flyanim.blockTrack then pcall(function() flyanim.blockTrack:Stop(0) end) end
end

local function cambiarAEspacioSecundario()
    if not flyanim.enabled or flyanim.mode ~= "normal" then return end
    local nt = flyanim.normalTracks
    if not nt.espacio_sec then return end
    if nt.espacio_prim and nt.espacio_prim.IsPlaying then pcall(function() nt.espacio_prim:Stop(flyanim.ESPACIO_FADE_OUT) end) end
    detenerNormalTracks(0.1)
    pcall(function() nt.espacio_sec:Play(0.1) end)
    pcall(function() nt.espacio_sec:AdjustSpeed(0) end)
    task.defer(function() if nt.espacio_sec and nt.espacio_sec.IsPlaying then pcall(function() nt.espacio_sec.TimePosition = nt.espacio_sec.Length * 0.5 end) end end)
    flyanim.espacioTrackActivo = nt.espacio_sec
end

function manejarEspacioPresionadoNormal()
    if not flyanim.enabled or flyanim.mode ~= "normal" then return end
    if flyanim.comboPlaying then return end
    if flyanim.turboPreImpulsoActivo then return end
    flyanim.isSpaceAdv = true
    if flyanim.noclipSpaceEnabled then flyanim.noclipSpaceActive = true; if flyanim.setNoclip then flyanim.setNoclip(true) end end
    local nt = flyanim.normalTracks
    if nt.mov_forward and nt.mov_forward.IsPlaying then pcall(function() nt.mov_forward:Stop(0.1) end) end
    if nt.mov_back and nt.mov_back.IsPlaying then pcall(function() nt.mov_back:Stop(0.1) end) end
    if nt.lateral and nt.lateral.IsPlaying then pcall(function() nt.lateral:Stop(0.1) end) end
    if nt.mov_brazos and nt.mov_brazos.IsPlaying then pcall(function() nt.mov_brazos:Stop(0.1) end) end
    if nt.brazos and nt.brazos.IsPlaying then pcall(function() nt.brazos:Stop(0.05) end) end
    flyanim.isBrazosActive = false; flyanim.idleTimerAnim = 0
    flyanim.currentAtrasId = flyanim.currentAtrasId + 1; flyanim.atrasKilled = true
    flyanim.currentLateralId = flyanim.currentLateralId + 1; flyanim.lateralKilled = true
    if flyanim.espacioTrackActivo then pcall(function() flyanim.espacioTrackActivo:Stop(flyanim.ESPACIO_FADE_OUT) end); flyanim.espacioTrackActivo = nil end
    if flyanim.spaceHoldTimerAdv then task.cancel(flyanim.spaceHoldTimerAdv) end
    if not nt.espacio_prim then return end
    pcall(function() nt.espacio_prim:Play(0.1) end)
    flyanim.espacioTrackActivo = nt.espacio_prim
    flyanim.spaceHoldTimerAdv = task.delay(flyanim.ESPACIO_TIEMPO_CAMBIO, function()
        if flyanim.isSpaceAdv and flyanim.enabled and flyanim.mode == "normal" then cambiarAEspacioSecundario() end
        flyanim.spaceHoldTimerAdv = nil
    end)
end

function manejarEspacioSoltadoNormal()
    flyanim.isSpaceAdv = false
    if flyanim.noclipSpaceActive then
        flyanim.noclipSpaceActive = false
        if flyanim.mode ~= "turbo" and not flyanim.noclipCtrlActive then if flyanim.setNoclip then flyanim.setNoclip(false) end end
    end
    if flyanim.spaceHoldTimerAdv then task.cancel(flyanim.spaceHoldTimerAdv); flyanim.spaceHoldTimerAdv = nil end
    if flyanim.espacioTrackActivo then pcall(function() flyanim.espacioTrackActivo:Stop(flyanim.ESPACIO_FADE_OUT) end); flyanim.espacioTrackActivo = nil end
    evaluarMovimientoDebounced()
end

local function _launchComboAnim(animId, speed)
    for id, track in pairs(flyanim.tracks) do
        if id ~= animId and id ~= ANIM.levitacion and track and track.IsPlaying then pcall(function() track:Stop(0.05) end) end
    end
    local t = getTrack(animId)
    if not t then return end
    t.Looped = false; t.Priority = Enum.AnimationPriority.Action4
    if t.IsPlaying then pcall(function() t:Stop(0) end) end
    pcall(function() t:Play(0.05, 1, 1); t:AdjustSpeed(speed or 3.0) end)
end

local function resetCombo()
    flyanim.comboStep = 0; flyanim.comboLastClick = 0; flyanim.combo2LastUsed = nil; comboPendingClick = false
end

local function startComboC0Lock()
    if flyanim.comboC0Conn then flyanim.comboC0Conn:Disconnect(); flyanim.comboC0Conn = nil end
    if not flyanim.rootJoint or not flyanim.originalC0 then return end
    local rj = flyanim.rootJoint; local oc = flyanim.originalC0
    flyanim.c0ControlToken = (flyanim.c0ControlToken or 0) + 1
    local myToken = flyanim.c0ControlToken
    flyanim.comboC0Conn = RunService.RenderStepped:Connect(function()
        if not flyanim.comboPlaying then if flyanim.comboC0Conn then flyanim.comboC0Conn:Disconnect(); flyanim.comboC0Conn = nil end; return end
        if flyanim.c0ControlToken ~= myToken then if flyanim.comboC0Conn then flyanim.comboC0Conn:Disconnect(); flyanim.comboC0Conn = nil end; return end
        pcall(function() rj.C0 = oc end)
    end)
end

local function stopComboC0Lock()
    if flyanim.comboC0Conn then flyanim.comboC0Conn:Disconnect(); flyanim.comboC0Conn = nil end
end

local function finalizarCombo()
    flyanim.dashTimer = 0; flyanim.dashVel = Vector3.new(0,0,0)
    flyanim.comboPlaying = false; flyanim.comboBusy = false; flyanim.combo4Frozen = false; comboPendingClick = false
    stopComboC0Lock()
    if not flyanim.enabled then return end
    for id, track in pairs(flyanim.tracks) do if id ~= ANIM.levitacion and track and track.IsPlaying then pcall(function() track:Stop(0.12) end) end end
    task.wait(0.08)
    if not flyanim.enabled then return end
    flyanim.c0ControlToken = (flyanim.c0ControlToken or 0) + 1
    detenerWatchdogAltura()
    restaurarC0Inmediato()
    if flyanim.mode == "normal" then
        flyanim._normalPlayId = (flyanim._normalPlayId or 0) + 1
        local pid = flyanim._normalPlayId
        local nt = flyanim.normalTracks
        if nt then if nt.levitacion and not nt.levitacion.IsPlaying then pcall(function() nt.levitacion:Play(0.2); nt.levitacion:AdjustSpeed(ANIM_NORMAL.VELOCIDAD_LEVITACION) end) end end
        iniciarCicloNormal(flyanim, pid)
        task.delay(0.05, function() if flyanim.enabled and flyanim.mode == "normal" then evaluarMovimientoNormal() end end)
    else if flyanim.updateAnimForMovement then flyanim.updateAnimForMovement() end end
end

local function runComboSequencer(startToken)
    local function waitStep(stepIdx)
        local dur = COMBO_STEP_DURATION[stepIdx] or 0.47
        local stepStart = tick()
        while tick() - stepStart < dur do task.wait(0.02); if flyanim.comboToken ~= startToken then return false end end
        flyanim.comboBusy = false
        local waitStart = tick()
        while not comboPendingClick do task.wait(0.02); if flyanim.comboToken ~= startToken then return false end; if tick() - waitStart > COMBO_PENDING_WINDOW then finalizarCombo(); return false end end
        comboPendingClick = false
        if flyanim.comboToken ~= startToken then return false end
        return true
    end
    flyanim.comboStep = 1
    _launchComboAnim(ANIM.combo1, 3.0)
    flyanim.comboBusy = true; comboPendingClick = false
    if not waitStep(1) then return end
    flyanim.comboStep = 2
    local r = math.random(1,2)
    local chosenId2, chosenKey2 = (r==1) and ANIM.combo2a or ANIM.combo2b, (r==1) and "a" or "b"
    flyanim.combo2LastUsed = chosenKey2
    _launchComboAnim(chosenId2, 3.0)
    flyanim.comboBusy = true; comboPendingClick = false
    if not waitStep(2) then return end
    flyanim.comboStep = 3
    local chosenId3 = (flyanim.combo2LastUsed == "a") and ANIM.combo3b or ANIM.combo3a
    _launchComboAnim(chosenId3, 3.0)
    flyanim.comboBusy = true; comboPendingClick = false
    if not waitStep(3) then return end
    flyanim.comboStep = 4
    local spaceDown4 = UserInputService:IsKeyDown(Enum.KeyCode.Space)
    if spaceDown4 then
        local t4s = getTrack(ANIM.combo4_space)
        if t4s then
            for id, track in pairs(flyanim.tracks) do if id ~= ANIM.combo4_space and id ~= ANIM.levitacion and track and track.IsPlaying then pcall(function() track:Stop(0.05) end) end end
            t4s.Looped = false; t4s.Priority = Enum.AnimationPriority.Action4
            if t4s.IsPlaying then pcall(function() t4s:Stop(0) end) end
            pcall(function() t4s:Play(0.05, 1, 1); t4s:AdjustSpeed(1.0) end)
            flyanim.comboBusy = true
            local timeout4 = tick() + 5
            while t4s.IsPlaying and tick() < timeout4 do task.wait(0.03); if flyanim.comboToken ~= startToken then return end end
            flyanim.comboBusy = false
            task.wait(0.3)
        end
        resetCombo(); finalizarCombo(); return
    end
    local t4 = getTrack(ANIM.combo4)
    if not t4 then finalizarCombo(); return end
    for id, track in pairs(flyanim.tracks) do if id ~= ANIM.combo4 and id ~= ANIM.levitacion and track and track.IsPlaying then pcall(function() track:Stop(0.05) end) end end
    t4.Looped = false; t4.Priority = Enum.AnimationPriority.Action4
    if t4.IsPlaying then pcall(function() t4:Stop(0) end) end
    pcall(function() t4:Play(0.05, 1, 1) end)
    local toLoad = tick() + 2
    while t4.Length == 0 and tick() < toLoad do task.wait(0.02); if flyanim.comboToken ~= startToken then flyanim.combo4Frozen = false; return end end
    pcall(function() t4:AdjustSpeed(4.0) end)
    flyanim.comboBusy = true; comboPendingClick = false; flyanim.combo4Frozen = false
    local len4 = t4.Length; local PAUSE_PERC = 0.55
    local timeout4 = tick() + 4
    while t4.IsPlaying and tick() < timeout4 do task.wait(0.016); if flyanim.comboToken ~= startToken then flyanim.combo4Frozen = false; return end; len4 = t4.Length; if len4 > 0 and t4.TimePosition >= len4 * PAUSE_PERC then break end end
    if flyanim.comboToken ~= startToken then flyanim.combo4Frozen = false; return end
    flyanim.combo4Frozen = true; flyanim.comboBusy = false
    pcall(function() t4:AdjustSpeed(0) end)
    if len4 > 0 then pcall(function() t4.TimePosition = len4 * PAUSE_PERC end) end
    local stepDur4 = COMBO_STEP_DURATION[4]
    local pauseDeadline = tick() + (stepDur4 * (1 - PAUSE_PERC) + 0.08)
    while not comboPendingClick and tick() < pauseDeadline do task.wait(0.02); if flyanim.comboToken ~= startToken then flyanim.combo4Frozen = false; return end end
    flyanim.combo4Frozen = false; comboPendingClick = false
    if flyanim.comboToken ~= startToken then return end
    pcall(function() t4:AdjustSpeed(15) end)
    t4.Looped = false
    local timeout4b = tick() + 2
    while t4.IsPlaying and tick() < timeout4b do task.wait(0.016); if flyanim.comboToken ~= startToken then return end end
    resetCombo(); finalizarCombo()
end

function handleComboClick()
    if not flyanim.enabled then return end
    if flyanim.turboPreImpulsoActivo then return end
    if flyanim.isBlocking then return end
    if flyanim.comboPlaying then
        if flyanim.comboBusy then return end
        comboPendingClick = true; flyanim.comboLastClick = tick()
        return
    end
    local now = tick()
    if now - flyanim.comboLastClick < 0.08 then return end
    flyanim.comboToken = (flyanim.comboToken or 0) + 1
    local myToken = flyanim.comboToken
    if flyanim.idleAnimConn then flyanim.idleAnimConn:Disconnect(); flyanim.idleAnimConn = nil end
    if flyanim.isBlocking then stopBlocking(); flyanim.blockCancelledByCombo = true end
    flyanim.comboPlaying = true; flyanim.comboLastClick = now; comboPendingClick = false
    startComboC0Lock()
    task.spawn(function() runComboSequencer(myToken) end)
end

function setupAnimator(char)
    local animScript = char:FindFirstChild("Animate")
    if animScript then animScript.Disabled = true; flyanim.animScript = animScript end
    local humanoid = char:WaitForChild("Humanoid", 5)
    if not humanoid then return end
    local animator = humanoid:WaitForChild("Animator", 5)
    if not animator then return end
    flyanim.animator = animator
    flyanim.tracks = {}
    local ok, playing = pcall(function() return animator:GetPlayingAnimationTracks() end)
    if ok and playing then for _, t in ipairs(playing) do pcall(function() t:Stop(0) end) end end
    if flyanim.animConn then flyanim.animConn:Disconnect(); flyanim.animConn = nil end
    local hrp = char:WaitForChild("HumanoidRootPart", 5)
    if not hrp then return end
    local rj = hrp:WaitForChild("RootJoint", 5)
    if not rj then return end
    flyanim.rootJoint = rj; flyanim.originalC0 = rj.C0
    for _, id in pairs(ANIM) do pcall(function() getTrack(id) end) end
    local function loadNorm(id, priority, looped)
        local anim = Instance.new("Animation"); anim.AnimationId = id
        local ok2, t = pcall(function() return animator:LoadAnimation(anim) end)
        if not ok2 or not t then return nil end
        t.Priority = priority or Enum.AnimationPriority.Action3
        t.Looped = (looped ~= false)
        return t
    end
    flyanim.normalTracks = {
        estatica = loadNorm(ANIM.estatica, Enum.AnimationPriority.Action2),
        levitacion = loadNorm(ANIM.levitacion, Enum.AnimationPriority.Action4),
        brazos = loadNorm(ANIM.brazos_idle, Enum.AnimationPriority.Action3),
        mov_forward = loadNorm(ANIM.mov_forward, Enum.AnimationPriority.Action3),
        mov_back = loadNorm(ANIM.mov_back_anim, Enum.AnimationPriority.Action3),
        mov_brazos = loadNorm(ANIM.mov_brazos_mov, Enum.AnimationPriority.Action3),
        lateral = loadNorm(ANIM.mov_lateral, Enum.AnimationPriority.Action3, false),
        espacio_prim = loadNorm(ANIM.espacio_prim, Enum.AnimationPriority.Action3, true),
        espacio_sec = loadNorm(ANIM.espacio_sec, Enum.AnimationPriority.Action3, false),
        turbo_compact = loadNorm(ANIM.turbo_compact, Enum.AnimationPriority.Action4, false),
        turbo_burst = loadNorm(ANIM.turbo_burst, Enum.AnimationPriority.Action4, false),
        turbo_pose = loadNorm(ANIM.turbo_pose, Enum.AnimationPriority.Action4, true),
        turbo_volado = loadNorm(ANIM.turbo_volado, Enum.AnimationPriority.Action4, true),
        mega_pose = loadNorm(ANIM.mega_pose, Enum.AnimationPriority.Action4, true),
        mega_base = loadNorm(ANIM.mega_base, Enum.AnimationPriority.Action3, true),
        mega_volado = loadNorm(ANIM.mega_volado, Enum.AnimationPriority.Action4, true),
    }
    local nt = flyanim.normalTracks
    if nt.lateral then pcall(function() nt.lateral:Play(0); nt.lateral:Stop(0) end) end
    if nt.mov_back then pcall(function() nt.mov_back:Play(0); nt.mov_back:Stop(0) end) end
    if nt.espacio_sec then pcall(function() nt.espacio_sec:Play(0); nt.espacio_sec:Stop(0) end) end
    local ownAnimIds = {}
    for _, id in pairs(ANIM) do ownAnimIds[id] = true end
    ownAnimIds[CAIDA_BASE_ID] = true; ownAnimIds[CAIDA_OVERLAY_ID] = true
    flyanim.animConn = animator.AnimationPlayed:Connect(function(track)
        if not track or not track.Animation then return end
        local id = track.Animation.AnimationId
        if not ownAnimIds[id] then pcall(function() if track and track.IsPlaying then track:Stop(0) end end) end
    end)
    setupBlockTrack()
    if flyanim.setupDamageDetector then flyanim.setupDamageDetector() end
end

function updateAnimForMovement()
    if flyanim.turboPreImpulsoActivo then return end
    local function getMovDir()
        local w = flyanim.wDown; local s = flyanim.sDown; local a = flyanim.aDown; local d = flyanim.dDown
        if a and d then return "none" end
        if d and not a then return "right" end
        if a and not d then return "left" end
        if not w and not s then return "none" end
        if w and not s then return "forward" end
        if s and not w then return "back" end
        return "none"
    end
    local dir = getMovDir()
    local moving = dir ~= "none"
    local mode = flyanim.mode
    flyanim.isMoving = moving
    if flyanim.comboPlaying then return end
    if flyanim.isBlocking then return end
    if mode == "normal" then
        local nt = flyanim.normalTracks
        if not nt.mov_forward then
            if not moving then playAnim(ANIM.idle, true)
            elseif dir == "right" then playAnim(ANIM.right, true)
            elseif dir == "left" then playAnim(ANIM.left, true)
            elseif dir == "back" then playAnim(ANIM.back, true)
            else playAnim(ANIM.forward, true) end
        end
    elseif mode == "fast" then
        if flyanim.turboRenderConn then return end
        local enterFast = flyanim.tracks[ANIM.fast_enter]
        if enterFast and enterFast.IsPlaying then return end
        if not moving then playAnim(ANIM.fast_idle, true)
        else playAnim(ANIM.fast_move, true) end
    elseif mode == "turbo" then
        if flyanim.megaRenderConn then return end
        local enterTurbo = flyanim.tracks[ANIM.turbo_enter]
        if enterTurbo and enterTurbo.IsPlaying then return end
        if not moving then playAnim(ANIM.turbo_idle, true)
        else playAnim(ANIM.turbo_loop, true) end
    end
end

-- Asignar funciones de FlyAnim al objeto flyanim
flyanim.iniciarCicloNormal = iniciarCicloNormal
flyanim.iniciarPoseTurbo = iniciarPoseTurbo
flyanim.detenerPoseTurbo = detenerPoseTurbo
flyanim.iniciarPoseMega = iniciarPoseMega
flyanim.detenerPoseMega = detenerPoseMega
flyanim.manejarEspacioPresionadoNormal = manejarEspacioPresionadoNormal
flyanim.manejarEspacioSoltadoNormal = manejarEspacioSoltadoNormal
flyanim.startBlocking = startBlocking
flyanim.stopBlocking = stopBlocking
flyanim.handleComboClick = handleComboClick
flyanim.setupAnimator = setupAnimator
flyanim.updateAnimForMovement = updateAnimForMovement
flyanim.detenerNormalTracks = detenerNormalTracks
flyanim.evaluarMovimientoNormal = evaluarMovimientoNormal
flyanim.evaluarMovimientoDebounced = evaluarMovimientoDebounced
flyanim.restaurarC0Inmediato = restaurarC0Inmediato
flyanim.detenerWatchdogAltura = detenerWatchdogAltura
flyanim.iniciarWatchdogAltura = iniciarWatchdogAltura
flyanim.playAnim = playAnim
flyanim.getTrack = getTrack

-- ============================================================
-- FlyLogic - implementación completa
-- ============================================================
local function playLocalSound(id, volume)
    local snd = Instance.new("Sound"); snd.SoundId = id; snd.Volume = volume or 0.85
    snd.RollOffMaxDistance = 0; snd.Parent = SoundService; snd:Play()
    task.delay(10, function() pcall(function() snd:Destroy() end) end)
    snd.Ended:Connect(function() pcall(function() snd:Destroy() end) end)
end

local function setNoclip(state)
    local char = flyanim.lplr.Character
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do if part:IsA("BasePart") then part.CanCollide = not state end end
end

local function cleanupMotors(root, preserveVelY)
    if not root then return end
    for _, v in ipairs(root:GetChildren()) do
        if v:IsA("BodyGyro") or v:IsA("BodyVelocity") or v:IsA("BodyPosition")
        or v:IsA("BodyAngularVelocity") or v:IsA("BodyForce") or v:IsA("AlignOrientation") or v:IsA("LinearVelocity") then
            pcall(function() v:Destroy() end)
        end
    end
    local char = root.Parent; local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        pcall(function() hum.PlatformStand = false
            hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
            hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
            hum:ChangeState(Enum.HumanoidStateType.Freefall)
        end)
    end
    if preserveVelY then
        local currentVelY = 0; pcall(function() currentVelY = root.AssemblyLinearVelocity.Y end)
        local finalVelY = (currentVelY >= 0) and -4 or currentVelY
        pcall(function() root.AssemblyLinearVelocity = Vector3.new(0, finalVelY, 0) end)
    else pcall(function() root.AssemblyLinearVelocity = Vector3.new(0, 0, 0) end) end
    pcall(function() root.AssemblyAngularVelocity = Vector3.new(0, 0, 0) end)
end

local function updateAntiGravityForce()
    if not flyanim.bf or not flyanim.bf.Parent then return end
    local char = flyanim.lplr.Character; local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local totalMass = 0
    for _, part in ipairs(char:GetDescendants()) do if part:IsA("BasePart") and not part.Massless then totalMass = totalMass + part.AssemblyMass end end
    if totalMass == 0 then totalMass = root.AssemblyMass end
    local grav = workspace.Gravity
    flyanim.bf.Force = Vector3.new(0, totalMass * grav, 0)
end

local function fixUndergroundOrientation()
    local char = flyanim.lplr.Character; local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root or not flyanim.bg then return end
    local upVec = root.CFrame.UpVector
    if upVec.Y < 0.3 then
        local lookVec = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
        if lookVec.Magnitude < 0.01 then lookVec = Vector3.new(0,0,-1) end
        local correctedCF = CFrame.lookAt(root.Position, root.Position + lookVec.Unit)
        pcall(function() root.CFrame = correctedCF; root.AssemblyAngularVelocity = Vector3.new(0,0,0); if flyanim.bg then flyanim.bg.cframe = correctedCF end end)
    end
end

local function startAntiImpulse()
    if flyanim.antiImpulseConn then flyanim.antiImpulseConn:Disconnect(); flyanim.antiImpulseConn = nil end
    local mySession = flyanim.sessionToken
    flyanim.antiImpulseConn = RunService.Stepped:Connect(function()
        if flyanim.sessionToken ~= mySession then if flyanim.antiImpulseConn then flyanim.antiImpulseConn:Disconnect(); flyanim.antiImpulseConn = nil end return end
        if not flyanim.enabled then if flyanim.antiImpulseConn then flyanim.antiImpulseConn:Disconnect(); flyanim.antiImpulseConn = nil end return end
        local char = flyanim.lplr.Character; local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        local bv = flyanim.bv; if not bv or not bv.Parent then return end
        local expectedVel = bv.velocity; local actualVel = root.AssemblyLinearVelocity
        local diff = (actualVel - expectedVel).Magnitude
        if diff > 3 then root.AssemblyLinearVelocity = expectedVel end
        local bg = flyanim.bg
        if bg then
            local targetAngular = Vector3.new(0,0,0); local currentAngular = root.AssemblyAngularVelocity
            if (currentAngular - targetAngular).Magnitude > 5 then root.AssemblyAngularVelocity = targetAngular end
        end
    end)
end

local function stopAntiImpulse()
    if flyanim.antiImpulseConn then flyanim.antiImpulseConn:Disconnect(); flyanim.antiImpulseConn = nil end
end

local function activateGyroProtection()
    if flyanim.gyroProtectionActive then return end
    if not flyanim.bg then return end
    flyanim.gyroProtectionActive = true
    flyanim.originalGyroP = flyanim.bg.P; flyanim.originalGyroMaxTorque = flyanim.bg.maxTorque
    flyanim.bg.P = 2000; flyanim.bg.maxTorque = Vector3.new(2000,2000,2000)
    if flyanim.backupGyro then flyanim.backupGyro:Destroy() end
    flyanim.backupGyro = Instance.new("BodyGyro", flyanim.bg.Parent)
    flyanim.backupGyro.P = 1000; flyanim.backupGyro.maxTorque = Vector3.new(1000,1000,1000); flyanim.backupGyro.cframe = flyanim.bg.cframe
    if flyanim.gyroProtectionTimer then task.cancel(flyanim.gyroProtectionTimer) end
    flyanim.gyroProtectionTimer = task.delay(0.5, function()
        if flyanim.enabled and flyanim.bg then flyanim.bg.P = flyanim.originalGyroP or 9e4; flyanim.bg.maxTorque = flyanim.originalGyroMaxTorque or Vector3.new(9e9,9e9,9e9) end
        if flyanim.backupGyro then flyanim.backupGyro:Destroy(); flyanim.backupGyro = nil end
        flyanim.gyroProtectionActive = false; flyanim.gyroProtectionTimer = nil
    end)
end

local ANOMALY_COOLDOWN = 0.12; local MOTOR_RESET_COOLDOWN = 0.5
local lastAnomalyFix = 0; local lastMotorReset = 0

local function silentMotorReset()
    local now = tick()
    if now - lastMotorReset < MOTOR_RESET_COOLDOWN then return end
    lastMotorReset = now
    local char = flyanim.lplr.Character; local root = char and char:FindFirstChild("HumanoidRootPart"); local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end
    local currentCF = root.CFrame
    pcall(function()
        for _, v in ipairs(root:GetChildren()) do
            if v:IsA("BodyGyro") or v:IsA("BodyVelocity") or v:IsA("BodyForce") or v:IsA("BodyAngularVelocity") or v:IsA("AlignOrientation") or v:IsA("LinearVelocity") then v:Destroy() end
        end
        root.AssemblyLinearVelocity = Vector3.new(0,0,0); root.AssemblyAngularVelocity = Vector3.new(0,0,0)
        local bg = Instance.new("BodyGyro", root); bg.P = 9e4; bg.maxTorque = Vector3.new(9e9,9e9,9e9); bg.cframe = currentCF
        local bv = Instance.new("BodyVelocity", root); bv.velocity = Vector3.new(0,0,0); bv.maxForce = Vector3.new(9e9,9e9,9e9)
        local bf = Instance.new("BodyForce", root); local totalMass = root.AssemblyMass; bf.Force = Vector3.new(0, totalMass * workspace.Gravity, 0)
        flyanim.bg = bg; flyanim.bv = bv; flyanim.bf = bf
        hum.PlatformStand = true
        hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
        hum:ChangeState(Enum.HumanoidStateType.Physics)
    end)
end

local function startAnomalyProtection()
    if flyanim.anomalyConn then flyanim.anomalyConn:Disconnect(); flyanim.anomalyConn = nil end
    flyanim.lastKnownPos = nil
    local mySession = flyanim.sessionToken
    flyanim.anomalyConn = RunService.Stepped:Connect(function(_, dt)
        if flyanim.sessionToken ~= mySession then if flyanim.anomalyConn then flyanim.anomalyConn:Disconnect(); flyanim.anomalyConn = nil end; flyanim.lastKnownPos = nil; return end
        if not flyanim.enabled then if flyanim.anomalyConn then flyanim.anomalyConn:Disconnect(); flyanim.anomalyConn = nil end; flyanim.lastKnownPos = nil; return end
        local char = flyanim.lplr.Character; local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then flyanim.lastKnownPos = nil; return end
        local now = tick(); local hum = char and char:FindFirstChildOfClass("Humanoid"); local pos = root.Position
        flyanim.lastKnownPos = pos
        if not hum then return end
        local state = hum:GetState()
        local isHitboxDrop = (state == Enum.HumanoidStateType.Freefall or state == Enum.HumanoidStateType.FallingDown or state == Enum.HumanoidStateType.Ragdoll or state == Enum.HumanoidStateType.GettingUp)
        local motorsGone = (not root:FindFirstChildOfClass("BodyGyro") or not root:FindFirstChildOfClass("BodyVelocity"))
        if (isHitboxDrop or motorsGone) and now - lastAnomalyFix > ANOMALY_COOLDOWN then
            lastAnomalyFix = now; flyanim.ragdollDetected = (state == Enum.HumanoidStateType.Ragdoll)
            silentMotorReset()
            task.defer(function() if not flyanim.enabled then return end; flyanim.ragdollDetected = false end)
        end
    end)
end

local function stopAnomalyProtection()
    if flyanim.anomalyConn then flyanim.anomalyConn:Disconnect(); flyanim.anomalyConn = nil end
    flyanim.lastKnownPos = nil
end

local function startTeleportGuard()
    if flyanim.teleportGuardConn then flyanim.teleportGuardConn:Disconnect(); flyanim.teleportGuardConn = nil end
    flyanim.lastSafePos = nil; flyanim.lastSafeTime = tick(); flyanim.isTeleportGuardActive = true
    local mySession = flyanim.sessionToken
    flyanim.teleportGuardConn = RunService.Stepped:Connect(function(_, dt)
        if flyanim.sessionToken ~= mySession then if flyanim.teleportGuardConn then flyanim.teleportGuardConn:Disconnect(); flyanim.teleportGuardConn = nil end; flyanim.isTeleportGuardActive = false; return end
        if not flyanim.enabled then if flyanim.teleportGuardConn then flyanim.teleportGuardConn:Disconnect(); flyanim.teleportGuardConn = nil end; flyanim.isTeleportGuardActive = false; return end
        if not flyanim.isTeleportGuardActive then return end
        local char = flyanim.lplr.Character; local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then flyanim.lastSafePos = nil; return end
        local pos = root.Position
        if pos.Y <= -500 then
            local safePos = flyanim.lastSafePos
            if safePos then
                local targetCF = CFrame.new(safePos + Vector3.new(0,5,0))
                pcall(function() root.CFrame = targetCF; root.AssemblyLinearVelocity = Vector3.new(0,0,0); root.AssemblyAngularVelocity = Vector3.new(0,0,0) end)
                local cam = workspace.CurrentCamera
                if cam then local camCF = cam.CFrame; task.defer(function() if cam and cam.Parent then cam.CFrame = camCF end end) end
                flyanim.dashTimer = 0; flyanim.dashVel = Vector3.new(0,0,0)
                if not root:FindFirstChildOfClass("BodyGyro") then _flyMakeMotors() end
            end
            return
        end
        if math.abs(pos.X) < COORD_SANITY_LIMIT and math.abs(pos.Z) < COORD_SANITY_LIMIT then flyanim.lastSafePos = pos; flyanim.lastSafeTime = tick() end
    end)
end

local function stopTeleportGuard()
    flyanim.isTeleportGuardActive = false
    if flyanim.teleportGuardConn then flyanim.teleportGuardConn:Disconnect(); flyanim.teleportGuardConn = nil end
    flyanim.lastSafePos = nil
end

local function _flyMakeMotors()
    local char = flyanim.lplr.Character; if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart"); local hum = char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end
    cleanupMotors(root)
    flyanim.bg = Instance.new("BodyGyro", root); flyanim.bg.P = 9e4; flyanim.bg.maxTorque = Vector3.new(9e9,9e9,9e9); flyanim.bg.cframe = root.CFrame
    flyanim.bv = Instance.new("BodyVelocity", root); flyanim.bv.velocity = Vector3.new(0,0,0); flyanim.bv.maxForce = Vector3.new(9e9,9e9,9e9)
    flyanim.bf = Instance.new("BodyForce", root); flyanim.bf.Force = Vector3.new(0, root.AssemblyMass * workspace.Gravity, 0)
    hum.PlatformStand = true; hum:ChangeState(Enum.HumanoidStateType.Physics)
end

local brakeConn = nil
local function startBrakeSystem()
    if brakeConn then brakeConn:Disconnect(); brakeConn = nil end
    brakeConn = RunService.RenderStepped:Connect(function()
        if not flyanim.enabled then return end
        if flyanim.mode ~= "fast" and flyanim.mode ~= "turbo" then return end
        if not flyanim.lockActive or not flyanim.lockedTarget then return end
        if flyanim.dashTimer <= 0 then return end
        local char = flyanim.lplr.Character; local myRoot = char and char:FindFirstChild("HumanoidRootPart")
        if not myRoot then return end
        local targetChar = flyanim.lockedTarget.Character; local targetRoot = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
        if not targetRoot then return end
        local dist = (myRoot.Position - targetRoot.Position).Magnitude
        if dist <= flyanim.BRAKE_HARD_DISTANCE then flyanim.dashVel = Vector3.new(0,0,0); flyanim.dashTimer = 0; flyanim.brakingActive = false
        elseif dist <= flyanim.BRAKE_DISTANCE then
            local t = 1 - ((dist - flyanim.BRAKE_HARD_DISTANCE) / (flyanim.BRAKE_DISTANCE - flyanim.BRAKE_HARD_DISTANCE))
            local brakeFactor = 1 - (t * 0.92); flyanim.dashVel = flyanim.dashVel * math.max(brakeFactor, 0.05); flyanim.brakingActive = true
        else flyanim.brakingActive = false end
    end)
end

local function stopBrakeSystem() if brakeConn then brakeConn:Disconnect(); brakeConn = nil end end

local dashConnection = nil; local HIT_COOLDOWN = 0.5; local shakeConn = nil
local function shakeCamera(intensity, duration)
    if shakeConn then pcall(function() shakeConn:Disconnect() end); shakeConn = nil end
    local cam = workspace.CurrentCamera; if not cam then return end
    local startT = tick()
    shakeConn = RunService.RenderStepped:Connect(function()
        local elapsed = tick() - startT
        if elapsed >= duration then shakeConn:Disconnect(); shakeConn = nil; return end
        local decay = 1 - (elapsed / duration)
        local angleX = math.sin(elapsed * 30 * math.pi) * intensity * decay
        local angleY = math.sin(elapsed * 25 * math.pi) * intensity * decay * 0.8
        local angleZ = math.sin(elapsed * 35 * math.pi) * intensity * decay * 0.6
        pcall(function() cam.CFrame = cam.CFrame * CFrame.Angles(math.rad(angleX), math.rad(angleY), math.rad(angleZ)) end)
    end)
end

local function startDashCollisionDetection()
    if dashConnection then dashConnection:Disconnect() end
    local char = flyanim.lplr.Character; local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local hitPlayers = {}
    dashConnection = RunService.RenderStepped:Connect(function()
        if flyanim.dashTimer <= 0 then if dashConnection then dashConnection:Disconnect(); dashConnection = nil end; return end
        local currentChar = flyanim.lplr.Character; local currentRoot = currentChar and currentChar:FindFirstChild("HumanoidRootPart")
        if not currentRoot then return end
        local rootPos = currentRoot.Position
        local dashMagnitude = flyanim.dashVel.Magnitude
        local currentDashDir = dashMagnitude > 0.01 and flyanim.dashVel.Unit or Vector3.new(0,0,1)
        for _, otherPlayer in ipairs(Players:GetPlayers()) do
            if otherPlayer ~= flyanim.lplr then
                local otherChar = otherPlayer.Character; if otherChar then
                    local otherRoot = otherChar:FindFirstChild("HumanoidRootPart")
                    if otherRoot then
                        local dist = (rootPos - otherRoot.Position).Magnitude
                        if dist < 5.5 then
                            local playerId = otherPlayer.UserId; local now = tick()
                            if not hitPlayers[playerId] or now - hitPlayers[playerId] > HIT_COOLDOWN then
                                hitPlayers[playerId] = now
                                local pushDir = Vector3.new(currentDashDir.X, 0.5, currentDashDir.Z).Unit
                                local pushForce = pushDir * (dashMagnitude * 1.5)
                                otherRoot.AssemblyLinearVelocity = pushForce
                                local originalVel = flyanim.dashVel
                                flyanim.dashVel = flyanim.dashVel * 0.4
                                task.delay(0.08, function() if flyanim.dashTimer > 0 then flyanim.dashVel = originalVel end end)
                                shakeCamera(2.5, 0.25)
                            end
                        end
                    end
                end
            end
        end
    end)
end

function triggerDash(direction, speed, duration)
    local cam = workspace.CurrentCamera
    local dashDir
    if direction == "back" then local l = cam.CFrame.LookVector; dashDir = Vector3.new(-l.X, 0, -l.Z)
    elseif direction == "left" then local r = cam.CFrame.RightVector; dashDir = Vector3.new(-r.X, 0, -r.Z)
    elseif direction == "right" then local r = cam.CFrame.RightVector; dashDir = Vector3.new(r.X, 0, r.Z)
    elseif direction == "forward" then local l = cam.CFrame.LookVector; dashDir = Vector3.new(l.X, 0, l.Z) end
    if not dashDir or dashDir.Magnitude < 0.01 then return end
    flyanim.dashVel = dashDir.Unit * (speed or flyanim.DASH_SPEED)
    flyanim.dashTimer = duration or flyanim.DASH_DURATION
    startDashCollisionDetection()
end

local activeHitboxMarkers = {}
local function clearHitboxMarkers()
    for _, marker in ipairs(activeHitboxMarkers) do pcall(function() marker:Destroy() end) end
    activeHitboxMarkers = {}
end

local function showHitboxMarkers(targetChar)
    clearHitboxMarkers()
    if not targetChar then return end
    local box = Instance.new("SelectionBox"); box.Adornee = targetChar; box.Color3 = Color3.fromRGB(255,150,50); box.Transparency = 0.5; box.LineThickness = 0.1; box.Parent = targetChar
    table.insert(activeHitboxMarkers, box); task.delay(0.6, clearHitboxMarkers)
end

local function createParticle(isMega)
    if flyanim.megaTurboUpActive or flyanim.mode == "megaup" then return end
    local char = flyanim.lplr.Character; local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local camCF = workspace.CurrentCamera.CFrame
    local lookH = Vector3.new(camCF.LookVector.X, 0, camCF.LookVector.Z)
    local rightH = Vector3.new(camCF.RightVector.X, 0, camCF.RightVector.Z)
    if lookH.Magnitude > 0.01 then lookH = lookH.Unit else lookH = Vector3.new(0,0,-1) end
    if rightH.Magnitude > 0.01 then rightH = rightH.Unit else rightH = Vector3.new(1,0,0) end
    local moveDir = Vector3.new(0,0,0)
    if flyanim.wDown then moveDir = moveDir + lookH end
    if flyanim.sDown then moveDir = moveDir - lookH end
    if flyanim.aDown then moveDir = moveDir - rightH end
    if flyanim.dDown then moveDir = moveDir + rightH end
    if moveDir.Magnitude < 0.01 then moveDir = lookH else moveDir = moveDir.Unit end
    local spawnPos = root.Position + (-moveDir * 5); local awayDir = -moveDir
    local part = Instance.new("Part"); part.Anchored = true; part.CanCollide = false; part.CastShadow = false
    part.Transparency = 1; part.Size = Vector3.new(0.1, PARTICLE_LENGTH, 0.1); part.Position = spawnPos; part.Parent = workspace
    local camPos = workspace.CurrentCamera.CFrame.Position; local toCam = (camPos - spawnPos).Unit
    if toCam.Magnitude < 0.01 then toCam = Vector3.new(0,0,-1) end
    local upDir = awayDir.Unit; local rightDir = upDir:Cross(toCam).Unit
    if rightDir.Magnitude < 0.01 then rightDir = Vector3.new(1,0,0) end
    local lookDir = rightDir:Cross(upDir).Unit
    part.CFrame = CFrame.fromMatrix(spawnPos, rightDir, upDir, lookDir)
    local sg = Instance.new("SurfaceGui", part); sg.Adornee = part; sg.Face = Enum.NormalId.Front; sg.AlwaysOnTop = true
    sg.LightInfluence = 0; sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud; sg.PixelsPerStud = 50
    local img = Instance.new("ImageLabel", sg); img.Image = PARTICLE_TEXTURE; img.Size = UDim2.new(1,0,1,0); img.BackgroundTransparency = 1
    img.ImageColor3 = Color3.fromRGB(255,255,255); img.ImageTransparency = isMega and 0.3 or 0.5; img.ScaleType = Enum.ScaleType.Fit
    local particleRef = {part = part}; table.insert(flyanim.particleList, particleRef)
    local FADE_TIME = 0.42
    local fadeTween = TweenService:Create(img, TweenInfo.new(FADE_TIME, Enum.EasingStyle.Linear), {ImageTransparency = 1})
    fadeTween:Play()
    local travelDist = isMega and 14 or 8; local targetPos = spawnPos + awayDir * travelDist
    TweenService:Create(part, TweenInfo.new(FADE_TIME, Enum.EasingStyle.Linear), {Position = targetPos}):Play()
    fadeTween.Completed:Connect(function() pcall(function() if part and part.Parent then part:Destroy() end end); particleRef.part = nil end)
    task.delay(FADE_TIME + 0.15, function() pcall(function() if part and part.Parent then part:Destroy() end end); particleRef.part = nil end)
end

function startParticleEmitter()
    if flyanim.particleRunning then return end
    flyanim.particleRunning = true
    flyanim.particleConn = task.spawn(function()
        while flyanim.enabled and (flyanim.mode == "fast" or flyanim.mode == "turbo") and not flyanim.megaTurboUpActive and flyanim.mode ~= "megaup" do
            local char = flyanim.lplr.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                local isMega = (flyanim.mode == "turbo"); createParticle(isMega)
                if isMega then task.wait(0.04); createParticle(true) end
            end
            task.wait(0.12)
        end
        flyanim.particleRunning = false; flyanim.particleConn = nil
    end)
end

function stopParticleEmitter() if flyanim.particleConn then task.cancel(flyanim.particleConn); flyanim.particleConn = nil end; flyanim.particleRunning = false end
function killActiveParticles() local list = flyanim.particleList; for i = #list, 1, -1 do local ref = list[i]; if ref and ref.part then pcall(function() ref.part:Destroy() end); ref.part = nil end; table.remove(list, i) end end

local whiteFlashGui = nil
local function destroyWhiteFlash() if whiteFlashGui then pcall(function() whiteFlashGui:Destroy() end); whiteFlashGui = nil end end
local function getBrightnessFactor(speed) if speed <= 1000 then return (speed - 1) / 999 else return 1 end end
function speedWhiteFlash(mode)
    destroyWhiteFlash()
    local t = getBrightnessFactor(flyanim.speed)
    if t <= 0 then return end
    local baseOpacity = 0.38; local maxOpacity = (mode == "turbo") and (baseOpacity * 1.4) or baseOpacity; local opacity = maxOpacity * t
    local sg = Instance.new("ScreenGui"); sg.Name="AFO_WhiteFlash"; sg.ResetOnSpawn=false; sg.ZIndexBehavior=Enum.ZIndexBehavior.Global; sg.IgnoreGuiInset=true; sg.DisplayOrder=950; sg.Parent=CoreGui; whiteFlashGui=sg
    local frame = Instance.new("Frame", sg); frame.Size=UDim2.new(1,0,1,0); frame.BackgroundColor3=Color3.fromRGB(255,255,255); frame.BackgroundTransparency=1; frame.BorderSizePixel=0; frame.ZIndex=2
    TweenService:Create(frame, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1 - opacity}):Play()
    task.delay(0.2, function() if not sg or not sg.Parent then return end; TweenService:Create(frame, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {BackgroundTransparency = 1}):Play(); task.delay(0.55, function() pcall(function() sg:Destroy() end); if whiteFlashGui == sg then whiteFlashGui = nil end end) end)
end

local function airShockAura(intensity)
    local char = flyanim.lplr.Character; local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local isMega = intensity == 2
    task.spawn(function()
        local bb = Instance.new("BillboardGui"); bb.Adornee=root; bb.AlwaysOnTop=false; bb.LightInfluence=0; bb.Size=UDim2.new(0,50,0,50); bb.ResetOnSpawn=false; bb.ZIndexBehavior=Enum.ZIndexBehavior.Global; bb.Parent=root
        local img = Instance.new("ImageLabel", bb); img.Image=AIR_SHOCK_ID; img.Size=UDim2.new(1,0,1,0); img.BackgroundTransparency=1; img.ImageColor3=Color3.fromRGB(210,240,255); img.ImageTransparency=0.25; img.ScaleType=Enum.ScaleType.Fit
        local img2 = Instance.new("ImageLabel", bb); img2.Image=AIR_SHOCK_ID; img2.Size=UDim2.new(1.3,0,1.3,0); img2.Position=UDim2.new(-0.15,0,-0.15,0); img2.BackgroundTransparency=1; img2.ImageColor3=Color3.fromRGB(180,220,255); img2.ImageTransparency=0.45; img2.ScaleType=Enum.ScaleType.Fit; img2.Rotation=45
        TweenService:Create(bb, TweenInfo.new(0.14, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size=UDim2.new(0,200,0,200)}):Play()
        task.wait(0.05); if not bb or not bb.Parent then return end
        TweenService:Create(bb, TweenInfo.new(0.20, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Size=UDim2.new(0,280,0,280)}):Play()
        TweenService:Create(img, TweenInfo.new(0.22, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {ImageTransparency=1}):Play()
        TweenService:Create(img2, TweenInfo.new(0.18, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {ImageTransparency=1}):Play()
        task.delay(0.32, function() pcall(function() bb:Destroy() end) end)
    end)
    if isMega then
        task.spawn(function()
            task.wait(0.05); if not root or not root.Parent then return end
            local bb2 = Instance.new("BillboardGui"); bb2.Adornee=root; bb2.AlwaysOnTop=false; bb2.LightInfluence=0; bb2.Size=UDim2.new(0,50,0,50); bb2.ResetOnSpawn=false; bb2.ZIndexBehavior=Enum.ZIndexBehavior.Global; bb2.Parent=root
            local i1 = Instance.new("ImageLabel", bb2); i1.Image=AIR_SHOCK_ID; i1.Size=UDim2.new(1,0,1,0); i1.BackgroundTransparency=1; i1.ImageColor3=Color3.fromRGB(220,245,255); i1.ImageTransparency=0.15; i1.ScaleType=Enum.ScaleType.Fit; i1.Rotation=22
            local i2 = Instance.new("ImageLabel", bb2); i2.Image=AIR_SHOCK_ID; i2.Size=UDim2.new(1.5,0,1.5,0); i2.Position=UDim2.new(-0.25,0,-0.25,0); i2.BackgroundTransparency=1; i2.ImageColor3=Color3.fromRGB(190,225,255); i2.ImageTransparency=0.30; i2.ScaleType=Enum.ScaleType.Fit; i2.Rotation=60
            TweenService:Create(bb2, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size=UDim2.new(0,480,0,480)}):Play()
            task.wait(0.10); if not bb2 or not bb2.Parent then return end
            TweenService:Create(bb2, TweenInfo.new(0.26, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Size=UDim2.new(0,680,0,680)}):Play()
            TweenService:Create(i1, TweenInfo.new(0.28, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {ImageTransparency=1}):Play()
            TweenService:Create(i2, TweenInfo.new(0.22, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {ImageTransparency=1}):Play()
            task.delay(0.40, function() pcall(function() bb2:Destroy() end) end)
        end)
    end
end

local function sonicBoomEffect(intensity)
    local char = flyanim.lplr.Character; local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local isMega = intensity == 2
    local scale = isMega and 0.95 or 0.55
    local rings = {
        { start=(isMega and 5 or 3)*scale, peak=(isMega and 140 or 80)*scale, exp=isMega and 0.32 or 0.20, fadeDelay=isMega and 0.14 or 0.08, fadeDur=isMega and 0.26 or 0.16 },
        { start=(isMega and 4 or 2)*scale, peak=(isMega and 90 or 52)*scale, exp=isMega and 0.20 or 0.12, fadeDelay=isMega and 0.06 or 0.04, fadeDur=isMega and 0.18 or 0.10 },
        { start=(isMega and 3 or 1.5)*scale, peak=(isMega and 55 or 32)*scale, exp=isMega and 0.12 or 0.07, fadeDelay=0, fadeDur=isMega and 0.10 or 0.06 },
    }
    for i, r in ipairs(rings) do
        task.spawn(function()
            task.wait(i == 1 and 0 or (i == 2 and 0.02 or 0.04))
            if not root or not root.Parent then return end
            local p = Instance.new("Part"); p.Anchored=true; p.CanCollide=false; p.CanTouch=false; p.CastShadow=false; p.Transparency=1
            p.Size=Vector3.new(r.start*2, r.start*2, 0.01); p.CFrame=root.CFrame
            local cam = workspace.CurrentCamera; if cam then local d = cam.CFrame.Position - root.Position; if d.Magnitude > 0.1 then p.CFrame = CFrame.lookAt(root.Position, root.Position + d.Unit) end end
            p.Parent = workspace
            local sg = Instance.new("SurfaceGui", p); sg.Adornee=p; sg.Face=Enum.NormalId.Front; sg.AlwaysOnTop=false; sg.LightInfluence=0; sg.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud; sg.PixelsPerStud=50; sg.ZIndexBehavior=Enum.ZIndexBehavior.Global
            local outer = Instance.new("ImageLabel", sg); outer.Image=RING_ID; outer.Size=UDim2.new(1,0,1,0); outer.BackgroundTransparency=1; outer.ImageColor3=Color3.fromRGB(255,255,255); outer.ImageTransparency=0.06; outer.ZIndex=3
            local innerScale = 0.72 - (i-1)*0.08
            local inner = Instance.new("ImageLabel", sg); inner.Image=RING_ID; inner.Size=UDim2.new(innerScale,0,innerScale,0); inner.Position=UDim2.new((1-innerScale)/2,0,(1-innerScale)/2,0); inner.BackgroundTransparency=1; inner.ImageColor3=Color3.fromRGB(255,255,255); inner.ImageTransparency=0.20; inner.ZIndex=2
            TweenService:Create(p, TweenInfo.new(r.exp, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size=Vector3.new(r.peak*2, r.peak*2, 0.01)}):Play()
            task.delay(r.fadeDelay, function() if not p or not p.Parent then return end; TweenService:Create(outer, TweenInfo.new(r.fadeDur, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {ImageTransparency=1}):Play(); TweenService:Create(inner, TweenInfo.new(r.fadeDur*0.75, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {ImageTransparency=1}):Play() end)
            task.delay(r.fadeDelay + r.fadeDur + 0.08, function() pcall(function() p:Destroy() end) end)
        end)
    end
    task.spawn(function()
        local startPx = isMega and 90 or 60; local peakPx = isMega and 780 or 460
        local bb = Instance.new("BillboardGui"); bb.Adornee=root; bb.AlwaysOnTop=true; bb.LightInfluence=0; bb.Size=UDim2.new(0,startPx,0,startPx); bb.ResetOnSpawn=false; bb.Parent=root
        local img = Instance.new("ImageLabel", bb); img.Image=SHOCKWAVE_ID; img.Size=UDim2.new(1,0,1,0); img.BackgroundTransparency=1; img.ImageColor3=Color3.fromRGB(255,255,255); img.ImageTransparency=0; img.ScaleType=Enum.ScaleType.Fit
        TweenService:Create(bb, TweenInfo.new(0.10, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size=UDim2.new(0,peakPx,0,peakPx)}):Play()
        task.delay(0.25, function() pcall(function() bb:Destroy() end) end); task.wait(0.04); if not img or not img.Parent then return end; TweenService:Create(img, TweenInfo.new(0.2, Enum.EasingStyle.Exponential, Enum.EasingDirection.In), {ImageTransparency=1}):Play()
    end)
end

local function spawnLandingEffects(position, velocity)
    local intensity = math.clamp(velocity, 25, 180); local t = (intensity - 25) / 155
    local smokeScale = 0.8 + t * 1.8; local soundVol = 0.30 + t * 0.55; local smokeAlphaStart = 0.02 + t * 0.06; local smokeAlphaEnd = 0.82 + t * 0.14; local smokeDuration = 1.10 + t * 0.60
    local numRocks = math.floor(4 + t * 24); numRocks = math.min(numRocks, 28); local EFFECT_DELAY = 0.06
    task.spawn(function()
        task.wait(EFFECT_DELAY)
        local char = flyanim.lplr.Character; local hrpNow = char and char:FindFirstChild("HumanoidRootPart"); local samplePos = hrpNow and hrpNow.Position or position
        local groundY = samplePos.Y
        do local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Exclude; if char then rp.FilterDescendantsInstances = {char} end; local hit = workspace:Raycast(samplePos, Vector3.new(0, -8, 0), rp); if hit then groundY = hit.Position.Y end end
        local groundPos = Vector3.new(samplePos.X, groundY, samplePos.Z)
        local DUST_COLOR = Color3.fromRGB(160,152,140); local DUST_COLOR_INNER = Color3.fromRGB(200,192,182); local DUST_COLOR_BILLOW = Color3.fromRGB(120,112,100)
        local snd = Instance.new("Sound"); snd.SoundId = SFX_LANDING; snd.Volume = soundVol; snd.RollOffMaxDistance = 0; snd.Parent = SoundService; snd:Play(); snd.Ended:Connect(function() pcall(function() snd:Destroy() end) end); task.delay(8, function() pcall(function() snd:Destroy() end) end)
        task.spawn(function()
            local flashSize = smokeScale * 6
            local pf = Instance.new("Part"); pf.Anchored = true; pf.CanCollide = false; pf.CanTouch = false; pf.CastShadow = false; pf.Transparency = 1; pf.Size = Vector3.new(flashSize, flashSize, 0.05); pf.CFrame = CFrame.new(groundPos + Vector3.new(0,0.08,0)) * CFrame.Angles(math.rad(90),0,0); pf.Parent = workspace
            local sgf = Instance.new("SurfaceGui", pf); sgf.Adornee = pf; sgf.Face = Enum.NormalId.Front; sgf.AlwaysOnTop = false; sgf.LightInfluence = 0; sgf.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud; sgf.PixelsPerStud = 40
            local imgf = Instance.new("ImageLabel", sgf); imgf.Image = SMOKE_RING_TEX; imgf.Size = UDim2.new(1,0,1,0); imgf.BackgroundTransparency = 1; imgf.ImageColor3 = Color3.fromRGB(230,225,218); imgf.ImageTransparency = 0.0; imgf.ScaleType = Enum.ScaleType.Fit
            local flashPeak = flashSize * (3.5 + t * 1.5); TweenService:Create(pf, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = Vector3.new(flashPeak, flashPeak, 0.05)}):Play(); TweenService:Create(imgf, TweenInfo.new(0.22, Enum.EasingStyle.Expo, Enum.EasingDirection.In), {ImageTransparency = 1}):Play(); task.delay(0.25, function() pcall(function() pf:Destroy() end) end)
        end)
        task.spawn(function()
            local ringSize = smokeScale * 10
            local p = Instance.new("Part"); p.Anchored = true; p.CanCollide = false; p.CanTouch = false; p.CastShadow = false; p.Transparency = 1; p.Size = Vector3.new(ringSize, ringSize, 0.05); p.CFrame = CFrame.new(groundPos + Vector3.new(0,0.14,0)) * CFrame.Angles(math.rad(90),0,0); p.Parent = workspace
            local sg = Instance.new("SurfaceGui", p); sg.Adornee = p; sg.Face = Enum.NormalId.Front; sg.AlwaysOnTop = false; sg.LightInfluence = 0; sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud; sg.PixelsPerStud = 40
            local img = Instance.new("ImageLabel", sg); img.Image = SMOKE_RING_TEX; img.Size = UDim2.new(1,0,1,0); img.BackgroundTransparency = 1; img.ImageColor3 = DUST_COLOR; img.ImageTransparency = smokeAlphaStart; img.ScaleType = Enum.ScaleType.Fit
            local peakSize = ringSize * (3.2 + t * 2.5); TweenService:Create(p, TweenInfo.new(smokeDuration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = Vector3.new(peakSize, peakSize, 0.05)}):Play()
            local fadeTween1 = TweenService:Create(img, TweenInfo.new(smokeDuration, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {ImageTransparency = 1}); fadeTween1:Play()
            task.delay(smokeDuration + 0.05, function() pcall(function() if p then p:Destroy() end end) end)
        end)
        task.spawn(function()
            task.wait(0.03); local ringSize2 = smokeScale * 7
            local p2 = Instance.new("Part"); p2.Anchored = true; p2.CanCollide = false; p2.CanTouch = false; p2.CastShadow = false; p2.Transparency = 1; p2.Size = Vector3.new(ringSize2, ringSize2, 0.05); p2.CFrame = CFrame.new(groundPos + Vector3.new(0,0.10,0)) * CFrame.Angles(math.rad(90),0,0); p2.Parent = workspace
            local sg2 = Instance.new("SurfaceGui", p2); sg2.Adornee = p2; sg2.Face = Enum.NormalId.Front; sg2.AlwaysOnTop = false; sg2.LightInfluence = 0; sg2.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud; sg2.PixelsPerStud = 40
            local img2 = Instance.new("ImageLabel", sg2); img2.Image = SMOKE_RING_TEX; img2.Size = UDim2.new(1,0,1,0); img2.BackgroundTransparency = 1; img2.ImageColor3 = DUST_COLOR_BILLOW; img2.ImageTransparency = smokeAlphaStart + 0.08; img2.ScaleType = Enum.ScaleType.Fit
            local dur2 = smokeDuration * 0.75; local peakSize2 = ringSize2 * (2.4 + t * 1.8); TweenService:Create(p2, TweenInfo.new(dur2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = Vector3.new(peakSize2, peakSize2, 0.05)}):Play()
            local fadeTween2 = TweenService:Create(img2, TweenInfo.new(dur2, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {ImageTransparency = 1}); fadeTween2:Play(); fadeTween2.Completed:Connect(function() pcall(function() p2:Destroy() end) end); task.delay(dur2 + 0.10, function() pcall(function() if p2 and p2.Parent then p2:Destroy() end end) end)
        end)
        task.spawn(function()
            task.wait(0.07); local ringSize3 = smokeScale * 4
            local p3 = Instance.new("Part"); p3.Anchored = true; p3.CanCollide = false; p3.CanTouch = false; p3.CastShadow = false; p3.Transparency = 1; p3.Size = Vector3.new(ringSize3, ringSize3, 0.05); p3.CFrame = CFrame.new(groundPos + Vector3.new(0,0.05,0)) * CFrame.Angles(math.rad(90),0,0); p3.Parent = workspace
            local sg3 = Instance.new("SurfaceGui", p3); sg3.Adornee = p3; sg3.Face = Enum.NormalId.Front; sg3.AlwaysOnTop = false; sg3.LightInfluence = 0; sg3.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud; sg3.PixelsPerStud = 40
            local img3 = Instance.new("ImageLabel", sg3); img3.Image = SMOKE_RING_TEX; img3.Size = UDim2.new(1,0,1,0); img3.BackgroundTransparency = 1; img3.ImageColor3 = DUST_COLOR_INNER; img3.ImageTransparency = smokeAlphaStart - 0.01; img3.ScaleType = Enum.ScaleType.Fit
            local dur3 = smokeDuration * 0.55; local peakSize3 = ringSize3 * (2.0 + t * 1.4); TweenService:Create(p3, TweenInfo.new(dur3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = Vector3.new(peakSize3, peakSize3, 0.05)}):Play()
            local fadeTween3 = TweenService:Create(img3, TweenInfo.new(dur3, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {ImageTransparency = 1}); fadeTween3:Play(); fadeTween3.Completed:Connect(function() pcall(function() p3:Destroy() end) end); task.delay(dur3 + 0.10, function() pcall(function() if p3 and p3.Parent then p3:Destroy() end end) end)
        end)
        task.spawn(function()
            local ROCK_BASE = Color3.fromRGB(130,125,118); local batchSize = 6; local spawned = 0
            while spawned < numRocks do
                local thisBatch = math.min(batchSize, numRocks - spawned)
                for i = 1, thisBatch do
                    task.spawn(function()
                        local rockSize = 0.08 + math.random() * (0.14 + t * 0.12)
                        local rock = Instance.new("Part"); rock.Size = Vector3.new(rockSize, rockSize, rockSize); rock.Material = Enum.Material.SmoothPlastic; rock.Color = ROCK_BASE:Lerp(Color3.fromRGB(160,155,148), math.random() * 0.4); rock.CanCollide = false; rock.CanTouch = false; rock.CastShadow = false; rock.Anchored = false
                        local angle = ((spawned + i) / numRocks) * math.pi * 2 + math.random() * 0.9; local radius = 0.25 + math.random() * 0.75
                        rock.CFrame = CFrame.new(groundPos.X + math.cos(angle) * radius, groundPos.Y + 0.05, groundPos.Z + math.sin(angle) * radius)
                        rock.Parent = workspace
                        local outDir = Vector3.new(math.cos(angle), 0.55 + math.random() * 0.9, math.sin(angle)).Unit
                        local power = (3.5 + t * 9) * (0.65 + math.random() * 0.7); rock.AssemblyLinearVelocity = outDir * power
                        local fadeTime = 0.35 + math.random() * 0.35
                        task.delay(0.04, function() if not rock or not rock.Parent then return end; TweenService:Create(rock, TweenInfo.new(fadeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Transparency = 1}):Play(); task.delay(fadeTime + 0.05, function() pcall(function() rock:Destroy() end) end) end)
                    end)
                end
                spawned = spawned + thisBatch; if spawned < numRocks then task.wait(0.01) end
            end
        end)
    end)
end

local _landingWatchConn = nil; local _landingWatchToken = 0
local function stopLandingWatcher() _landingWatchToken = _landingWatchToken + 1; if _landingWatchConn then _landingWatchConn:Disconnect(); _landingWatchConn = nil end end
local function startLandingWatcher()
    stopLandingWatcher(); local myToken = _landingWatchToken
    _landingWatchConn = RunService.Heartbeat:Connect(function()
        if not flyanim.waitingLand then stopLandingWatcher(); return end
        if _landingWatchToken ~= myToken then return end
        local char = flyanim.lplr.Character; local hrp = char and char:FindFirstChild("HumanoidRootPart"); local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum then return end
        local velY = hrp.AssemblyLinearVelocity.Y
        if velY > -1 then return end
        local probeDistance = math.clamp(math.abs(velY) * 0.08 + 2.0, 2.0, 4.5)
        local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Exclude; rp.FilterDescendantsInstances = {char}
        local hit = workspace:Raycast(hrp.Position, Vector3.new(0, -probeDistance, 0), rp)
        if hit then
            stopLandingWatcher()
            pcall(function() for _, v in ipairs(hrp:GetChildren()) do if v:IsA("BodyGyro") or v:IsA("BodyVelocity") or v:IsA("BodyForce") or v:IsA("BodyAngularVelocity") or v:IsA("AlignOrientation") or v:IsA("LinearVelocity") or v:IsA("AngularVelocity") then v:Destroy() end end end)
            local animScriptPre = char and char:FindFirstChild("Animate")
            if animScriptPre then pcall(function() animScriptPre.Disabled = true end); task.delay(0.25, function() if not flyanim.waitingLand and animScriptPre and animScriptPre.Parent then pcall(function() animScriptPre.Disabled = false end) end end) end
            pcall(function() local v = hrp.AssemblyLinearVelocity; hrp.AssemblyLinearVelocity = Vector3.new(v.X, 0, v.Z); hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0); local _, ry, _ = hrp.CFrame:ToOrientation(); hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, ry, 0) end)
        end
    end)
end

local function isTargetValidForLock(target)
    if not target then return false end
    local char = target.Character; if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid"); if not hum then return false end
    if hum.Health <= 0 then return false end; if hum:GetState() == Enum.HumanoidStateType.Dead then return false end
    return true
end

local function getClosestLockTarget()
    local closestPlayer = nil; local bestScore = math.huge
    local myChar = flyanim.lplr.Character; local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local cam = workspace.CurrentCamera
    for _, player in ipairs(Players:GetPlayers()) do
        if player == flyanim.lplr then continue end
        if not isTargetValidForLock(player) then continue end
        local targetChar = player.Character; if not targetChar then continue end
        local targetRoot = targetChar:FindFirstChild("HumanoidRootPart"); if not targetRoot then continue end
        local screenPos, onScreen = cam:WorldToScreenPoint(targetRoot.Position); if not onScreen then continue end
        local mousePos = UserInputService:GetMouseLocation()
        local screenDist = (Vector2.new(mousePos.X, mousePos.Y) - Vector2.new(screenPos.X, screenPos.Y)).Magnitude
        if screenDist > 300 then continue end
        local worldDist = myRoot and (myRoot.Position - targetRoot.Position).Magnitude or 0
        local score = screenDist + (worldDist * 0.2)
        if score < bestScore then bestScore = score; closestPlayer = player end
    end
    return closestPlayer
end

local function removeLockIcon() if flyanim.lockIconGui then pcall(function() flyanim.lockIconGui:Destroy() end); flyanim.lockIconGui = nil end end
local function applyLockIcon(player)
    removeLockIcon()
    local chest = player.Character and player.Character:FindFirstChild("UpperTorso")
    local torso = chest or (player.Character and player.Character:FindFirstChild("HumanoidRootPart"))
    if not torso then return end
    flyanim.lockIconGui = Instance.new("BillboardGui", torso); flyanim.lockIconGui.Name = "LockIcon"; flyanim.lockIconGui.Size = UDim2.new(0,50,0,50); flyanim.lockIconGui.AlwaysOnTop = true; flyanim.lockIconGui.StudsOffset = Vector3.new(0,0,0)
    local img = Instance.new("ImageLabel", flyanim.lockIconGui); img.Size = UDim2.new(1,0,1,0); img.BackgroundTransparency = 1; img.Image = "rbxassetid://82817965256191"; img.ImageColor3 = Color3.fromRGB(255,255,255); img.ScaleType = Enum.ScaleType.Fit
end

local function ensureLockHighlight() if not flyanim.lockHighlight then flyanim.lockHighlight = Instance.new("Highlight"); flyanim.lockHighlight.FillTransparency = 1; flyanim.lockHighlight.OutlineColor = Color3.fromRGB(255,255,255); flyanim.lockHighlight.OutlineTransparency = 0 end end
local function updateLockHighlight() if not flyanim.lockActive or not flyanim.lockedTarget then if flyanim.lockHighlight then flyanim.lockHighlight.Parent = nil end; return end; if not isTargetValidForLock(flyanim.lockedTarget) then if flyanim.lockHighlight then flyanim.lockHighlight.Parent = nil end; return end; ensureLockHighlight(); local targetChar = flyanim.lockedTarget.Character; if targetChar then flyanim.lockHighlight.Parent = targetChar else flyanim.lockHighlight.Parent = nil end end

function toggleLock()
    if not flyanim.enabled then return end
    if not flyanim.lockActive then
        local found = getClosestLockTarget()
        if found and isTargetValidForLock(found) then flyanim.lockedTarget = found; flyanim.lockActive = true; applyLockIcon(found); updateLockHighlight() end
    else flyanim.lockActive = false; flyanim.lockedTarget = nil; removeLockIcon(); updateLockHighlight() end
end

function startLockSystem()
    local lockConn = UserInputService.InputBegan:Connect(function(input, gpe) if gpe or isTyping() then return end; if input.KeyCode == flyanim.lockKey then toggleLock() end end)
    local lockRenderConn = RunService.RenderStepped:Connect(function()
        if not flyanim.lockActive or not flyanim.lockedTarget then return end
        local targetChar = flyanim.lockedTarget.Character; if not targetChar then flyanim.lockActive = false; flyanim.lockedTarget = nil; removeLockIcon(); updateLockHighlight(); return end
        if not isTargetValidForLock(flyanim.lockedTarget) then flyanim.lockActive = false; flyanim.lockedTarget = nil; removeLockIcon(); updateLockHighlight(); return end
        local myRoot = flyanim.lplr.Character and flyanim.lplr.Character:FindFirstChild("HumanoidRootPart"); local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
        if myRoot and targetRoot and (myRoot.Position - targetRoot.Position).Magnitude > 750 then flyanim.lockActive = false; flyanim.lockedTarget = nil; removeLockIcon(); updateLockHighlight(); return end
        local targetPart = targetChar:FindFirstChild("UpperTorso") or targetChar:FindFirstChild("HumanoidRootPart"); if not targetPart then return end
        local currentPos = camera.CFrame.Position; local desiredCF = CFrame.new(currentPos, targetPart.Position)
        local lerpFactor = flyanim.lockCameraLerp
        local worldDist = myRoot and (myRoot.Position - targetPart.Position).Magnitude or 999
        if worldDist < 8 then lerpFactor = lerpFactor * 0.25 elseif worldDist < 20 then lerpFactor = lerpFactor * 0.6 end
        camera.CFrame = camera.CFrame:Lerp(desiredCF, lerpFactor)
    end)
    flyanim.lockConn = lockConn; flyanim.lockRenderConn = lockRenderConn
end

function stopLockSystem()
    if flyanim.lockConn then flyanim.lockConn:Disconnect(); flyanim.lockConn = nil end
    if flyanim.lockRenderConn then flyanim.lockRenderConn:Disconnect(); flyanim.lockRenderConn = nil end
    flyanim.lockActive = false; flyanim.lockedTarget = nil; removeLockIcon(); updateLockHighlight()
    if flyanim.lockHighlight then pcall(function() flyanim.lockHighlight:Destroy() end); flyanim.lockHighlight = nil end
end

local MegaUpLogic = { Active = false, LoopConn = nil, Token = 0 }
function MegaUpLogic.Deactivate()
    MegaUpLogic.Active = false; MegaUpLogic.Token = MegaUpLogic.Token + 1
    if MegaUpLogic.LoopConn then MegaUpLogic.LoopConn:Disconnect(); MegaUpLogic.LoopConn = nil end
end
function MegaUpLogic.Activate()
    if MegaUpLogic.Active then return end; if flyanim.mode == "turbo" then return end
    MegaUpLogic.Deactivate(); MegaUpLogic.Active = true; MegaUpLogic.Token = MegaUpLogic.Token + 1
    local myToken = MegaUpLogic.Token
    stopParticleEmitter(); killActiveParticles()
    if flyanim.isBrazosActive then flyanim.isBrazosActive = false; flyanim.idleTimerAnim = 0; if flyanim.normalTracks and flyanim.normalTracks.brazos then pcall(function() flyanim.normalTracks.brazos:Stop(0.05) end) end end
    playLocalSound(SFX_MEGA_TURBO, 0.90); sonicBoomEffect(2); airShockAura(2); speedWhiteFlash("turbo")
    local char = flyanim.lplr.Character; local root = char and char:FindFirstChild("HumanoidRootPart")
    if root then root.AssemblyLinearVelocity = Vector3.new(0, flyanim.BASE_SPEED * flyanim.TURBO_MULT * 0.8, 0) end
    flyanim.megaTurboUpActive = true; if flyanim.updateMode then flyanim.updateMode("megaup") end
    local startT = os.clock()
    MegaUpLogic.LoopConn = RunService.Heartbeat:Connect(function()
        if MegaUpLogic.Token ~= myToken then return end
        if not MegaUpLogic.Active or not flyanim.enabled then MegaUpLogic.Deactivate(); flyanim.megaTurboUpActive = false; flyanim.speed = flyanim.BASE_SPEED; flyanim.mode = "normal"; if flyanim.updateMode then flyanim.updateMode("normal") end; return end
        if os.clock() - startT > 4.0 then MegaUpLogic.Deactivate(); flyanim.megaTurboUpActive = false; flyanim.speed = flyanim.BASE_SPEED; flyanim.mode = "normal"; if flyanim.updateMode then flyanim.updateMode("normal") end; return end
        if flyanim.bv and flyanim.bv.Parent then flyanim.speed = flyanim.BASE_SPEED * flyanim.TURBO_MULT end
    end)
end

function startMegaTurboUpListener()
    if flyanim.megaTurboUpConn then flyanim.megaTurboUpConn:Disconnect(); flyanim.megaTurboUpConn = nil end
    flyanim.megaTurboUpConn = RunService.RenderStepped:Connect(function()
        if not flyanim.enabled then return end; if isTyping() then return end; if flyanim.turboPreImpulsoActivo then return end
        local spaceDown = UserInputService:IsKeyDown(Enum.KeyCode.Space)
        local modeOk = (flyanim.mode == "normal" or flyanim.mode == "fast") and not flyanim.megaTurboUpActive
        if spaceDown and modeOk then
            if not flyanim.spaceHoldStart then flyanim.spaceHoldStart = tick() end
            if tick() - flyanim.spaceHoldStart >= flyanim.SPACE_HOLD_TIME then flyanim.spaceHoldStart = nil; MegaUpLogic.Activate() end
        else flyanim.spaceHoldStart = nil; if flyanim.megaTurboUpActive and not spaceDown then flyanim.megaTurboUpActive = false end end
    end)
end

function stopMegaTurboUpListener()
    if flyanim.megaTurboUpConn then flyanim.megaTurboUpConn:Disconnect(); flyanim.megaTurboUpConn = nil end
    flyanim.spaceHoldStart = nil; flyanim.megaTurboUpActive = false
end

local function startMovementLoops()
    if flyanim.tpMoveConn then flyanim.tpMoveConn:Disconnect(); flyanim.tpMoveConn = nil end
    local _tpMoveSession = flyanim.sessionToken
    flyanim.tpMoveConn = RunService.Stepped:Connect(function(_, dt)
        if flyanim.sessionToken ~= _tpMoveSession then flyanim.tpMoveConn:Disconnect(); flyanim.tpMoveConn = nil; return end
        if not flyanim.enabled then flyanim.tpMoveConn:Disconnect(); flyanim.tpMoveConn = nil; return end
        local cc = flyanim.lplr.Character; local root2 = cc and cc:FindFirstChild("HumanoidRootPart"); if not root2 then return end
        local pos2 = root2.Position
        if math.abs(pos2.Y) > COORD_SANITY_LIMIT or math.abs(pos2.X) > COORD_SANITY_LIMIT or math.abs(pos2.Z) > COORD_SANITY_LIMIT then return end
        local cam = workspace.CurrentCamera; local typing = isTyping()
        local wD = not typing and UserInputService:IsKeyDown(Enum.KeyCode.W); local sD = not typing and UserInputService:IsKeyDown(Enum.KeyCode.S)
        local aD = not typing and UserInputService:IsKeyDown(Enum.KeyCode.A); local dD = not typing and UserInputService:IsKeyDown(Enum.KeyCode.D)
        local spaceDown = not typing and UserInputService:IsKeyDown(Enum.KeyCode.Space); local ctrlDown = not typing and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
        if ctrlDown and flyanim.noclipCtrlEnabled and not flyanim.noclipCtrlActive then flyanim.noclipCtrlActive = true; setNoclip(true)
        elseif not ctrlDown and flyanim.noclipCtrlActive then flyanim.noclipCtrlActive = false; local megaActive = (flyanim.mode == "turbo") and flyanim.noclipMegaEnabled; if not flyanim.noclipSpaceActive and not megaActive then setNoclip(false) end end
        local move = Vector3.new()
        if wD then move = move + cam.CFrame.LookVector end; if sD then move = move - cam.CFrame.LookVector end
        if aD then move = move - cam.CFrame.RightVector end; if dD then move = move + cam.CFrame.RightVector end
        if flyanim.megaTurboUpActive then move = move + Vector3.new(0,2,0) elseif spaceDown then move = move + Vector3.new(0,1,0) end
        if ctrlDown then move = move - Vector3.new(0,1,0) end
        if spaceDown and not flyanim.megaTurboUpActive then fixUndergroundOrientation() end
        if move.Magnitude > 0.01 then
            local actualSpeed = flyanim.speed; if flyanim.dashTimer > 0 then actualSpeed = actualSpeed + flyanim.dashVel.Magnitude end
            local translation = move.Unit * actualSpeed * dt; pcall(function() cc:TranslateBy(translation) end)
        elseif flyanim.dashTimer > 0 and flyanim.dashVel.Magnitude > 0.1 then
            local translation = flyanim.dashVel.Unit * flyanim.dashVel.Magnitude * dt; pcall(function() cc:TranslateBy(translation) end)
        end
    end)
    if flyanim.rsConn then flyanim.rsConn:Disconnect() end
    local _rsSession = flyanim.sessionToken
    flyanim.rsConn = RunService.RenderStepped:Connect(function(dt)
        if flyanim.sessionToken ~= _rsSession then flyanim.rsConn:Disconnect(); flyanim.rsConn = nil; return end
        if not flyanim.enabled then flyanim.rsConn:Disconnect(); flyanim.rsConn = nil; return end
        local cc = flyanim.lplr.Character; local root = cc and cc:FindFirstChild("HumanoidRootPart"); local ch = cc and cc:FindFirstChildOfClass("Humanoid")
        if not root or not ch then return end
        local pos = root.Position
        if math.abs(pos.Y) > COORD_SANITY_LIMIT or math.abs(pos.X) > COORD_SANITY_LIMIT or math.abs(pos.Z) > COORD_SANITY_LIMIT then return end
        if not root:FindFirstChild("BodyGyro") or not root:FindFirstChild("BodyVelocity") or ch:GetState() == Enum.HumanoidStateType.Ragdoll then _flyMakeMotors(); return end
        flyanim.bg = root:FindFirstChild("BodyGyro"); flyanim.bv = root:FindFirstChild("BodyVelocity"); flyanim.bf = root:FindFirstChild("BodyForce")
        updateAntiGravityForce()
        local angularSpeed = root.AssemblyAngularVelocity.Magnitude; if angularSpeed > 25 and not flyanim.gyroProtectionActive then activateGyroProtection() end
        local cam = workspace.CurrentCamera; local typing = isTyping()
        local wD = not typing and UserInputService:IsKeyDown(Enum.KeyCode.W); local sD = not typing and UserInputService:IsKeyDown(Enum.KeyCode.S)
        local aD = not typing and UserInputService:IsKeyDown(Enum.KeyCode.A); local dD = not typing and UserInputService:IsKeyDown(Enum.KeyCode.D)
        flyanim.wDown = wD; flyanim.sDown = sD; flyanim.aDown = aD; flyanim.dDown = dD
        flyanim.isWDown = wD; flyanim.isSDown = sD; flyanim.isADown = aD; flyanim.isDDown = dD
        if flyanim.bv then flyanim.bv.velocity = Vector3.new(0,0,0) end
        if flyanim.lockActive and flyanim.lockedTarget then
            local tChar = flyanim.lockedTarget.Character
            if tChar and isTargetValidForLock(flyanim.lockedTarget) then
                local aimPart = tChar:FindFirstChild("UpperTorso") or tChar:FindFirstChild("HumanoidRootPart")
                if aimPart then
                    local desiredCF = CFrame.lookAt(root.Position, aimPart.Position, Vector3.new(0,1,0))
                    local smooth = LOCK_ROTATION_SMOOTH * (1 + math.min(0.5, (flyanim.dashVel.Magnitude / 300)))
                    flyanim.bg.cframe = flyanim.bg.cframe:Lerp(desiredCF, smooth)
                else flyanim.lockActive=false; flyanim.lockedTarget=nil; removeLockIcon(); updateLockHighlight() end
            else flyanim.lockActive=false; flyanim.lockedTarget=nil; removeLockIcon(); updateLockHighlight() end
        else
            local move = Vector3.new()
            if wD then move = move + cam.CFrame.LookVector end; if sD then move = move - cam.CFrame.LookVector end
            if aD then move = move - cam.CFrame.RightVector end; if dD then move = move + cam.CFrame.RightVector end
            local targetCFrame
            local isFastMode2 = (flyanim.mode == "fast" or flyanim.mode == "turbo")
            if isFastMode2 and move.Magnitude > 0.01 then targetCFrame = CFrame.lookAt(root.Position, root.Position + move.Unit)
            else targetCFrame = cam.CFrame end
            local sf
            if isFastMode2 then
                local angleDiff = 0
                pcall(function() local currentLook = flyanim.bg.cframe.LookVector; local desiredLook = targetCFrame.LookVector; local dot = math.clamp(currentLook:Dot(desiredLook), -1, 1); angleDiff = math.acos(dot) end)
                local t_angle = math.clamp(1 - (angleDiff / math.pi), 0, 1)
                sf = 0.04 + (t_angle * t_angle) * 0.14; sf = math.clamp(sf * (1 + dt * 8), 0, 0.20)
            else sf = math.clamp(dt*10, 0, 1) end
            flyanim.bg.cframe = flyanim.bg.cframe:Lerp(targetCFrame, sf)
        end
        if flyanim.dashTimer > 0 then
            flyanim.dashTimer = flyanim.dashTimer - dt
            if flyanim.dashTimer <= 0 then flyanim.dashTimer = 0; flyanim.dashVel = Vector3.new(0,0,0); if dashConnection then dashConnection:Disconnect(); dashConnection = nil end
            else flyanim.dashVel = flyanim.dashVel:Lerp(Vector3.new(0,0,0), math.clamp(dt*9,0,1)) end
        end
        local velY = root.AssemblyLinearVelocity.Y
        if velY < -10 then flyanim.landingVelocity = math.abs(velY); if math.abs(velY) > flyanim.landingVelocityCapture then flyanim.landingVelocityCapture = math.abs(velY) end end
        if flyanim.updateAnimForMovement then flyanim.updateAnimForMovement() end
    end)
end

function flyOn()
    local char = flyanim.lplr.Character; if not char then return end
    if flyanim.landConn then flyanim.landConn:Disconnect(); flyanim.landConn = nil end
    stopLandingWatcher(); flyanim.waitingLand = false
    flyanim.landingHeight = nil; flyanim.landingVelocity = 0; flyanim.landingVelocityCapture = 0
    flyanim.sessionToken = (flyanim.sessionToken or 0) + 1
    flyanim.enabled = true
    flyanim.mode = "normal"; flyanim.speed = flyanim.BASE_SPEED
    flyanim.wDown=false; flyanim.sDown=false; flyanim.aDown=false; flyanim.dDown=false
    flyanim.isWDown=false; flyanim.isSDown=false; flyanim.isADown=false; flyanim.isDDown=false
    flyanim.isMoving=false; flyanim.megaTurboUpActive=false; flyanim.spaceHoldStart=nil
    flyanim.gyroProtectionActive=false; flyanim.turboPreImpulsoActivo=false
    flyanim.noclipSpaceActive = false; flyanim.lastKnownPos = nil
    flyanim.ragdollDetected = false; flyanim.fKeyHeld = false; flyanim.blockCancelledByCombo = false
    flyanim.lastSafePos = nil; flyanim.lastSafeTime = tick()
    if flyanim.gyroProtectionTimer then task.cancel(flyanim.gyroProtectionTimer) end
    if flyanim.backupGyro then flyanim.backupGyro:Destroy(); flyanim.backupGyro=nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false); hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false); hum.PlatformStand = false end
    for _, t in pairs(flyanim.normalTracks or {}) do pcall(function() if t and t.IsPlaying then t:Stop(0) end end) end
    flyanim.normalTracks = {}
    for _, t in pairs(flyanim.tracks or {}) do pcall(function() if t and t.IsPlaying then t:Stop(0) end end) end
    flyanim.tracks = {}
    _flyMakeMotors()
    startAntiImpulse()
    startAnomalyProtection()
    startTeleportGuard()
    startMovementLoops()
    startBrakeSystem()
    startMegaTurboUpListener()
    if flyanim.startLockSystem then flyanim.startLockSystem() end
end

function flyOff()
    local char = flyanim.lplr.Character
    flyanim.sessionToken = (flyanim.sessionToken or 0) + 1
    flyanim.turboPreImpulsoToken = (flyanim.turboPreImpulsoToken or 0) + 1; flyanim.turboPreImpulsoActivo = false
    flyanim.idleWatchToken = (flyanim.idleWatchToken or 0) + 1
    flyanim.dashAnimToken = (flyanim.dashAnimToken or 0) + 1
    flyanim.comboToken = (flyanim.comboToken or 0) + 1
    flyanim.c0ControlToken = (flyanim.c0ControlToken or 0) + 1
    flyanim.c0HeightToken = (flyanim.c0HeightToken or 0) + 1
    if flyanim.turboRenderConn then flyanim.turboRenderConn:Disconnect(); flyanim.turboRenderConn = nil end
    if flyanim.megaRenderConn then flyanim.megaRenderConn:Disconnect(); flyanim.megaRenderConn = nil end
    if flyanim.c0HeightConn then flyanim.c0HeightConn:Disconnect(); flyanim.c0HeightConn = nil end
    if flyanim.comboC0Conn then flyanim.comboC0Conn:Disconnect(); flyanim.comboC0Conn = nil end
    if flyanim.blockRenderConn then flyanim.blockRenderConn:Disconnect(); flyanim.blockRenderConn = nil end
    if flyanim.idleAnimConn then flyanim.idleAnimConn:Disconnect(); flyanim.idleAnimConn = nil end
    if flyanim.megaTurboUpConn then flyanim.megaTurboUpConn:Disconnect(); flyanim.megaTurboUpConn = nil end
    if brakeConn then brakeConn:Disconnect(); brakeConn = nil end
    if flyanim.antiImpulseConn then flyanim.antiImpulseConn:Disconnect(); flyanim.antiImpulseConn = nil end
    if flyanim.anomalyConn then flyanim.anomalyConn:Disconnect(); flyanim.anomalyConn = nil end
    if flyanim.teleportGuardConn then flyanim.teleportGuardConn:Disconnect(); flyanim.teleportGuardConn = nil end
    if flyanim.rsConn then flyanim.rsConn:Disconnect(); flyanim.rsConn = nil end
    if flyanim.tpMoveConn then flyanim.tpMoveConn:Disconnect(); flyanim.tpMoveConn = nil end
    if flyanim.lockConn then flyanim.lockConn:Disconnect(); flyanim.lockConn = nil end
    if flyanim.lockRenderConn then flyanim.lockRenderConn:Disconnect(); flyanim.lockRenderConn = nil end
    if dashConnection then dashConnection:Disconnect(); dashConnection = nil end
    if shakeConn then pcall(function() shakeConn:Disconnect() end); shakeConn = nil end
    destroyWhiteFlash()
    if flyanim.gyroProtectionTimer then task.cancel(flyanim.gyroProtectionTimer); flyanim.gyroProtectionTimer = nil end
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if root then cleanupMotors(root, true) end
    flyanim.bg = nil; flyanim.bv = nil; flyanim.bf = nil
    flyanim.enabled = false; flyanim.dashTimer = 0; flyanim.dashVel = Vector3.new(0,0,0)
    flyanim.isTeleportGuardActive = false; flyanim.lastKnownPos = nil; flyanim.lastSafePos = nil
    flyanim.megaTurboUpActive = false; flyanim.noclipSpaceActive = false; flyanim.noclipCtrlActive = false
    flyanim.isBlocking = false; flyanim.isSpaceAdv = false; flyanim.isBrazosActive = false
    flyanim.comboPlaying = false; flyanim.comboBusy = false; flyanim.turboTransitioning = false; flyanim.megaTransitioning = false
    stopParticleEmitter(); stopMegaTurboUpListener(); stopAntiImpulse(); stopAnomalyProtection(); stopTeleportGuard(); stopBrakeSystem()
    if flyanim.stopLockSystem then flyanim.stopLockSystem() end
    setNoclip(false)
    local heightFromGround = 0
    if char and root then
        local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Exclude; rp.FilterDescendantsInstances = {char}
        local rayResult = workspace:Raycast(root.Position, Vector3.new(0, -500, 0), rp)
        if rayResult then heightFromGround = root.Position.Y - rayResult.Position.Y else heightFromGround = 999 end
    end
    flyanim.landingHeight = heightFromGround
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not char or not hum or hum.Health <= 0 then flyanim.landingHeight = nil; return end
    hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false); hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, false); hum:SetStateEnabled(Enum.HumanoidStateType.StrafingNoPhysics, false)
    hum.PlatformStand = false
    hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true); hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
    if root then
        for _, part in ipairs(char:GetDescendants()) do if part:IsA("BasePart") then part.CanCollide = true end end
        local _, ry, _ = root.CFrame:ToOrientation()
        pcall(function() root.CFrame = CFrame.new(root.Position) * CFrame.Angles(0, ry, 0); root.AssemblyAngularVelocity = Vector3.new(0,0,0); local velY = root.AssemblyLinearVelocity.Y; root.AssemblyLinearVelocity = Vector3.new(0, velY, 0) end)
    end
    hum:ChangeState(Enum.HumanoidStateType.Freefall)
    task.delay(0.12, function()
        if not hum or not hum.Parent then return end
        if not flyanim.waitingLand then return end
        local curState = hum:GetState()
        if curState == Enum.HumanoidStateType.GettingUp then pcall(function() hum:ChangeState(Enum.HumanoidStateType.Freefall) end) end
        hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true); hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true); hum:SetStateEnabled(Enum.HumanoidStateType.StrafingNoPhysics, true)
    end)
    if heightFromGround < 10 then
        if hum then hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true); hum.PlatformStand = false; pcall(function() hum:ChangeState(Enum.HumanoidStateType.Running) end) end
        flyanim.landingHeight = nil; return
    end
    flyanim.waitingLand = true
    startLandingWatcher()
    local capturedHeight = heightFromGround; local capturedVelocity = math.max(flyanim.landingVelocity, flyanim.landingVelocityCapture)
    flyanim.landConn = hum.StateChanged:Connect(function(_, newState)
        if not flyanim.waitingLand then if flyanim.landConn then flyanim.landConn:Disconnect(); flyanim.landConn=nil end; return end
        if newState == Enum.HumanoidStateType.Landed or newState == Enum.HumanoidStateType.Running or newState == Enum.HumanoidStateType.RunningNoPhysics or newState == Enum.HumanoidStateType.Dead then
            flyanim.waitingLand = false; if flyanim.landConn then flyanim.landConn:Disconnect(); flyanim.landConn=nil end
            if newState ~= Enum.HumanoidStateType.Dead then
                flyanim.landingHeight = capturedHeight; flyanim.landingVelocity = capturedVelocity; flyanim.landingVelocityCapture = capturedVelocity
                if flyanim.doLanding then flyanim.doLanding(flyanim.lplr.Character) end
            else local animSc = char and char:FindFirstChild("Animate"); if animSc then animSc.Disabled = false end; flyanim.landingHeight = nil end
        end
    end)
    task.delay(10, function()
        if not flyanim.waitingLand then return end
        flyanim.waitingLand = false; if flyanim.landConn then flyanim.landConn:Disconnect(); flyanim.landConn=nil end
        local animSc = flyanim.lplr.Character and flyanim.lplr.Character:FindFirstChild("Animate"); if animSc then animSc.Disabled = false end
        local humFinal = flyanim.lplr.Character and flyanim.lplr.Character:FindFirstChildOfClass("Humanoid")
        if humFinal and humFinal.Parent then humFinal.PlatformStand = false; pcall(function() humFinal:ChangeState(Enum.HumanoidStateType.GettingUp) end) end
        flyanim.landingHeight = nil
    end)
end

-- Asignar funciones de FlyLogic al objeto flyanim
flyanim.setNoclip = setNoclip
flyanim.playLocalSound = playLocalSound
flyanim.shakeCamera = shakeCamera
flyanim.sonicBoomEffect = sonicBoomEffect
flyanim.airShockAura = airShockAura
flyanim.speedWhiteFlash = speedWhiteFlash
flyanim.startParticleEmitter = startParticleEmitter
flyanim.stopParticleEmitter = stopParticleEmitter
flyanim.killActiveParticles = killActiveParticles
flyanim.triggerDash = triggerDash
flyanim.destroyWhiteFlash = destroyWhiteFlash
flyanim.spawnLandingEffects = spawnLandingEffects
flyanim.showHitboxMarkers = showHitboxMarkers
flyanim._flyMakeMotors = _flyMakeMotors
flyanim.startLockSystem = startLockSystem
flyanim.stopLockSystem = stopLockSystem
flyanim.toggleLock = toggleLock
flyanim.flyOn = flyOn
flyanim.flyOff = flyOff
flyanim.Bypass = function(duration, reason)
    if not flyanim.enabled then return end
    local bypassToken = (flyanim.bypassToken or 0) + 1; flyanim.bypassToken = bypassToken
    local myToken = bypassToken
    flyOff()
    task.delay(duration, function() if flyanim.bypassToken == myToken and flyanim.lplr.Character then flyOn() end end)
end

-- ============================================================
-- FlyControl - funciones de construcción de GUI y conexiones globales
-- ============================================================
local CAIDA_BASE_ID = "rbxassetid://287325678"
local CAIDA_OVERLAY_ID = "rbxassetid://70439247"
local _landAnimToken = 0
local _landBaseRef, _landOverlayRef = nil, nil

local function doLanding(char)
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
    local altura = flyanim.landingHeight or 0
    local impactVel = math.max(flyanim.landingVelocity or 0, flyanim.landingVelocityCapture or 0)
    flyanim.landingHeight = nil; flyanim.landingVelocity = 0; flyanim.landingVelocityCapture = 0
    if altura < 10 then
        local animScript = char:FindFirstChild("Animate") or flyanim.animScript
        if animScript then animScript.Disabled = false; flyanim.animScript = nil end
        if flyanim.rootJoint and flyanim.originalC0 then pcall(function() flyanim.rootJoint.C0 = flyanim.originalC0 end) end
        local root = char:FindFirstChild("HumanoidRootPart")
        if root then for _, v in ipairs(root:GetChildren()) do if v:IsA("BodyGyro") or v:IsA("BodyVelocity") or v:IsA("BodyForce") then v:Destroy() end end end
        if humanoid then humanoid.PlatformStand = false; pcall(function() humanoid:ChangeState(Enum.HumanoidStateType.Running) end) end
        return
    end
    if not animator then
        local animScript = char:FindFirstChild("Animate") or flyanim.animScript
        if animScript then animScript.Disabled = false end
        return
    end
    if flyanim.turboRenderConn then flyanim.turboRenderConn:Disconnect(); flyanim.turboRenderConn = nil end
    if flyanim.megaRenderConn then flyanim.megaRenderConn:Disconnect(); flyanim.megaRenderConn = nil end
    if flyanim.blockRenderConn then flyanim.blockRenderConn:Disconnect(); flyanim.blockRenderConn = nil end
    if flyanim.idleAnimConn then flyanim.idleAnimConn:Disconnect(); flyanim.idleAnimConn = nil end
    detenerWatchdogAltura(); restaurarC0Inmediato()
    if flyanim.blockTrack and flyanim.blockTrack.IsPlaying then pcall(function() flyanim.blockTrack:Stop(0) end) end
    flyanim.isBlocking = false; flyanim.isSpaceAdv = false; flyanim.turboTransitioning = false; flyanim.megaTransitioning = false
    if flyanim.animConn then flyanim.animConn:Disconnect(); flyanim.animConn = nil end
    if flyanim.animBlockRenderConn then flyanim.animBlockRenderConn:Disconnect(); flyanim.animBlockRenderConn = nil end
    local ok, playing = pcall(function() return animator:GetPlayingAnimationTracks() end)
    if ok and playing then for _, track in ipairs(playing) do pcall(function() track:Stop(0) end) end end
    for _, t in pairs(flyanim.tracks) do pcall(function() if t and t.IsPlaying then t:Stop(0) end end) end
    for _, t in pairs(flyanim.normalTracks) do pcall(function() if t and t.IsPlaying then t:Stop(0) end end) end
    if flyanim.rootJoint and flyanim.originalC0 then pcall(function() flyanim.rootJoint.C0 = flyanim.originalC0 end) end
    local animScript = char:FindFirstChild("Animate") or flyanim.animScript
    if animScript then animScript.Disabled = true end
    local landAnimIds = {[CAIDA_BASE_ID]=true, [CAIDA_OVERLAY_ID]=true}
    local landAnimConn = animator.AnimationPlayed:Connect(function(track)
        if track.Animation then local id = track.Animation.AnimationId; if not landAnimIds[id] then pcall(function() track:Stop(0) end) end end
    end)
    if humanoid then humanoid.PlatformStand = false; pcall(function() humanoid:ChangeState(Enum.HumanoidStateType.Landed) end); task.wait(0.05) end
    local root = char:FindFirstChild("HumanoidRootPart")
    local impactPos = root and root.Position or Vector3.new(0,0,0)
    if root then local _, ry, _ = root.CFrame:ToOrientation(); pcall(function() root.CFrame = CFrame.new(root.Position) * CFrame.Angles(0, ry, 0); root.AssemblyAngularVelocity = Vector3.new(0,0,0) end) end
    flyanim.spawnLandingEffects(impactPos, math.max(impactVel, altura * 0.5))
    if altura >= 25 then
        local animObjBase = Instance.new("Animation"); animObjBase.AnimationId = CAIDA_BASE_ID
        local animObjOverlay = Instance.new("Animation"); animObjOverlay.AnimationId = CAIDA_OVERLAY_ID
        local landBase = animator:LoadAnimation(animObjBase); local landOverlay = animator:LoadAnimation(animObjOverlay)
        landBase.Priority = Enum.AnimationPriority.Action3; landOverlay.Priority = Enum.AnimationPriority.Action4
        landBase.Looped = true; landOverlay.Looped = true
        _landAnimToken = _landAnimToken + 1; local myToken = _landAnimToken
        _landBaseRef = landBase; _landOverlayRef = landOverlay
        pcall(function() landBase:Play(0.0, 1, 1); landOverlay:Play(0.0, 1, 1) end)
        pcall(function() landBase:AdjustSpeed(8.0); landOverlay:AdjustSpeed(8.0) end)
        task.wait(0.06); if _landAnimToken ~= myToken then landAnimConn:Disconnect(); return end
        pcall(function() landBase:AdjustSpeed(0); landOverlay:AdjustSpeed(0) end)
        local shakeIntensity = 2.0 + (math.clamp(altura, 25, 200) - 25) / 175 * 1.5
        flyanim.shakeCamera(shakeIntensity, 0.30)
        task.wait(0.30); if _landAnimToken ~= myToken then landAnimConn:Disconnect(); return end
        pcall(function() landBase:AdjustSpeed(0.3); landOverlay:AdjustSpeed(0.3) end)
        task.wait(0.45); if _landAnimToken ~= myToken then landAnimConn:Disconnect(); return end
        pcall(function() landBase:AdjustSpeed(1.0); landOverlay:AdjustSpeed(1.0) end)
        task.wait(0.3); if _landAnimToken ~= myToken then landAnimConn:Disconnect(); return end
        pcall(function() landBase:Stop(0.5); landOverlay:Stop(0.5) end)
        task.wait(0.5); if _landAnimToken ~= myToken then landAnimConn:Disconnect(); return end
        landAnimConn:Disconnect(); pcall(function() landBase:Destroy(); landOverlay:Destroy() end); _landBaseRef = nil; _landOverlayRef = nil
    else
        local shakeIntensity = 0.8 + (math.clamp(altura, 10, 25) - 10) / 15 * 1.2
        flyanim.shakeCamera(shakeIntensity, 0.18); landAnimConn:Disconnect(); task.wait(0.3)
    end
    if animScript then animScript.Disabled = false end
    if flyanim.animConn then flyanim.animConn:Disconnect(); flyanim.animConn = nil end
    if flyanim.rootJoint and flyanim.originalC0 then pcall(function() flyanim.rootJoint.C0 = flyanim.originalC0 end) end
    local root2 = char:FindFirstChild("HumanoidRootPart")
    if root2 then for _, v in ipairs(root2:GetChildren()) do if v:IsA("BodyGyro") or v:IsA("BodyVelocity") or v:IsA("BodyForce") then v:Destroy() end end end
    if humanoid then humanoid.PlatformStand = false; pcall(function() humanoid:ChangeState(Enum.HumanoidStateType.Landed) end); task.wait(0.05); pcall(function() humanoid:ChangeState(Enum.HumanoidStateType.Running) end) end
end
flyanim.doLanding = doLanding

local function _flyBuildGui()
    if flyanim.gui then pcall(function() flyanim.gui:Destroy() end); flyanim.gui = nil end
    local FT = FlyText.GetFullTable()
    local C_PURPLE = Color3.fromRGB(110,30,180); local C_DIM = Color3.fromRGB(40,6,72); local C_BLACK = Color3.fromRGB(6,4,12); local C_ACCENT = Color3.fromRGB(160,60,255)
    local C_TEXT = Color3.fromRGB(220,190,255); local C_GREEN = Color3.fromRGB(80,255,150); local C_YELLOW = Color3.fromRGB(255,220,60); local C_RED = Color3.fromRGB(255,80,80); local C_CYAN = Color3.fromRGB(80,200,255)
    local W = 280; local H_MINI = 48; local DOT_SIZE = 10; local CONTENT_H = 8 + 30 + 6 + 82 + 6 + 104 + 8; local H_FULL = H_MINI + CONTENT_H
    local TW = TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    local sg = Instance.new("ScreenGui"); sg.Name="AFO_FlyHUD"; sg.ResetOnSpawn=false; sg.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; sg.IgnoreGuiInset=true; sg.Parent=CoreGui; flyanim.gui=sg
    local root = Instance.new("Frame", sg); root.Size=UDim2.new(0,W,0,H_FULL); root.Position=UDim2.new(0.5,-W/2,0,6); root.BackgroundTransparency=1; root.BorderSizePixel=0
    local panel = Instance.new("Frame", root); panel.Size=UDim2.new(1,0,0,H_MINI); panel.BackgroundColor3=C_BLACK; panel.BackgroundTransparency=0.06; panel.BorderSizePixel=0
    Instance.new("UICorner", panel).CornerRadius=UDim.new(0,12)
    local stroke = Instance.new("UIStroke", panel); stroke.Color=C_PURPLE; stroke.Thickness=1.2; stroke.Transparency=0.75
    local topBar = Instance.new("Frame", panel); topBar.Size=UDim2.new(1,0,0,H_MINI); topBar.BackgroundTransparency=1
    local iconLbl = Instance.new("TextLabel", topBar); iconLbl.Size=UDim2.new(0,28,1,0); iconLbl.Position=UDim2.new(0,8,0,0); iconLbl.BackgroundTransparency=1; iconLbl.Font=Enum.Font.GothamBold; iconLbl.TextSize=14; iconLbl.TextColor3=C_ACCENT; iconLbl.Text=""; iconLbl.TextXAlignment=Enum.TextXAlignment.Center
    local titleLbl = Instance.new("TextLabel", topBar); titleLbl.Size=UDim2.new(0,75,1,0); titleLbl.Position=UDim2.new(0,34,0,0); titleLbl.BackgroundTransparency=1; titleLbl.Font=Enum.Font.GothamBold; titleLbl.TextSize=12; titleLbl.TextColor3=C_TEXT; titleLbl.Text=FT.fly_title.." ["..flyanim.flyKey.Name.."]"; titleLbl.TextXAlignment=Enum.TextXAlignment.Left
    local sep = Instance.new("Frame", topBar); sep.Size=UDim2.new(0,1,0,22); sep.Position=UDim2.new(0,113,0.5,-11); sep.BackgroundColor3=C_PURPLE; sep.BackgroundTransparency=0.4
    local modeLbl = Instance.new("TextLabel", topBar); modeLbl.Size=UDim2.new(1,-134,1,0); modeLbl.Position=UDim2.new(0,119,0,0); modeLbl.BackgroundTransparency=1; modeLbl.Font=Enum.Font.GothamBold; modeLbl.TextSize=12; modeLbl.TextColor3=C_GREEN; modeLbl.Text=FT.mode_normal; modeLbl.TextXAlignment=Enum.TextXAlignment.Center
    local dotBtn = Instance.new("TextButton", topBar); dotBtn.Size=UDim2.new(0,DOT_SIZE+10,1,0); dotBtn.Position=UDim2.new(1,-(DOT_SIZE+14),0,0); dotBtn.BackgroundTransparency=1; dotBtn.Text=""
    local dot = Instance.new("Frame", dotBtn); dot.Size=UDim2.new(0,DOT_SIZE,0,DOT_SIZE); dot.Position=UDim2.new(0.5,-DOT_SIZE/2,0.5,-DOT_SIZE/2); dot.BackgroundColor3=C_ACCENT; Instance.new("UICorner", dot).CornerRadius=UDim.new(1,0)
    local expandZone = Instance.new("Frame", panel); expandZone.Size=UDim2.new(1,-16,0,CONTENT_H); expandZone.Position=UDim2.new(0,8,0,H_MINI); expandZone.BackgroundColor3=C_DIM; expandZone.BackgroundTransparency=0.3; expandZone.BorderSizePixel=0; expandZone.Visible=false; Instance.new("UICorner", expandZone).CornerRadius=UDim.new(0,8); local exStroke = Instance.new("UIStroke", expandZone); exStroke.Color=C_PURPLE; exStroke.Thickness=1; exStroke.Transparency=0.55
    local layout = Instance.new("UIListLayout", expandZone); layout.Padding=UDim.new(0,6); layout.SortOrder=Enum.SortOrder.LayoutOrder; layout.HorizontalAlignment=Enum.HorizontalAlignment.Center
    local topSpacer = Instance.new("Frame"); topSpacer.Size=UDim2.new(1,0,0,5); topSpacer.BackgroundTransparency=1; topSpacer.BorderSizePixel=0; topSpacer.Parent=expandZone
    local function makeSection(h) local f = Instance.new("Frame"); f.Size=UDim2.new(1,-20,0,h); f.BackgroundColor3=Color3.fromRGB(30,10,50); f.BackgroundTransparency=0.3; Instance.new("UICorner", f).CornerRadius=UDim.new(0,6); local s = Instance.new("UIStroke", f); s.Color=C_ACCENT; s.Thickness=1; s.Transparency=0.6; return f end
    local lockSec = makeSection(30); lockSec.Parent=expandZone
    local lockIconImg = Instance.new("TextLabel", lockSec); lockIconImg.Size=UDim2.new(0,24,0,24); lockIconImg.Position=UDim2.new(0,6,0.5,-12); lockIconImg.BackgroundTransparency=1; lockIconImg.Font=Enum.Font.GothamBold; lockIconImg.TextSize=16; lockIconImg.TextColor3=Color3.fromRGB(255,220,80); lockIconImg.Text=""
    local lockLabel = Instance.new("TextLabel", lockSec); lockLabel.Size=UDim2.new(0,80,1,0); lockLabel.Position=UDim2.new(0,34,0,0); lockLabel.BackgroundTransparency=1; lockLabel.Font=Enum.Font.GothamBold; lockLabel.TextSize=11; lockLabel.TextColor3=C_TEXT; lockLabel.Text=FT.lock_label.." ["..flyanim.lockKey.Name.."]"; lockLabel.TextXAlignment=Enum.TextXAlignment.Left
    local lockHint = Instance.new("TextLabel", lockSec); lockHint.Size=UDim2.new(1,-100,1,0); lockHint.Position=UDim2.new(0,95,0,0); lockHint.BackgroundTransparency=1; lockHint.Font=Enum.Font.Gotham; lockHint.TextSize=9; lockHint.TextColor3=Color3.fromRGB(150,120,200); lockHint.Text=FT.lock_hint_prefix..flyanim.lockKey.Name; lockHint.TextXAlignment=Enum.TextXAlignment.Right
    flyanim.lockLabels = { label = lockLabel, hint = lockHint }
    local noclipSec = makeSection(82); noclipSec.Parent=expandZone
    local noclipTitle = Instance.new("TextLabel", noclipSec); noclipTitle.Size=UDim2.new(1,-12,0,16); noclipTitle.Position=UDim2.new(0,6,0,2); noclipTitle.BackgroundTransparency=1; noclipTitle.Font=Enum.Font.GothamBold; noclipTitle.TextSize=11; noclipTitle.TextColor3=C_TEXT; noclipTitle.Text=FT.noclip_title; noclipTitle.TextXAlignment=Enum.TextXAlignment.Left
    local function createToggle(parent, xPos, yPos, initialState, onChange)
        local switchWidth = 36; local switchHeight = 18; local knobSize = 14
        local bg = Instance.new("Frame"); bg.Size = UDim2.new(0, switchWidth, 0, switchHeight); bg.Position = UDim2.new(0, xPos, 0, yPos); bg.BackgroundColor3 = initialState and Color3.fromRGB(80,200,80) or Color3.fromRGB(80,80,80); bg.BorderSizePixel = 0; bg.Parent = parent; Instance.new("UICorner", bg).CornerRadius = UDim.new(1,0)
        local knob = Instance.new("Frame"); knob.Size = UDim2.new(0, knobSize, 0, knobSize); knob.Position = initialState and UDim2.new(1,-knobSize-2,0.5,-knobSize/2) or UDim2.new(0,2,0.5,-knobSize/2); knob.BackgroundColor3 = Color3.fromRGB(255,255,255); knob.BorderSizePixel = 0; knob.Parent = bg; Instance.new("UICorner", knob).CornerRadius = UDim.new(1,0)
        local state = initialState; local button = Instance.new("TextButton"); button.Size = UDim2.new(1,0,1,0); button.BackgroundTransparency = 1; button.Text = ""; button.Parent = bg
        button.MouseButton1Click:Connect(function() state = not state; TweenService:Create(bg, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {BackgroundColor3 = state and Color3.fromRGB(80,200,80) or Color3.fromRGB(80,80,80)}):Play(); TweenService:Create(knob, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {Position = state and UDim2.new(1,-knobSize-2,0.5,-knobSize/2) or UDim2.new(0,2,0.5,-knobSize/2)}):Play(); if onChange then onChange(state) end end)
        return bg
    end
    local spaceRow = Instance.new("Frame", noclipSec); spaceRow.Size=UDim2.new(1,-12,0,20); spaceRow.Position=UDim2.new(0,6,0,18); spaceRow.BackgroundTransparency=1
    local spaceLabel = Instance.new("TextLabel", spaceRow); spaceLabel.Size=UDim2.new(0,88,1,0); spaceLabel.BackgroundTransparency=1; spaceLabel.Font=Enum.Font.Gotham; spaceLabel.TextSize=10; spaceLabel.TextColor3=C_TEXT; spaceLabel.Text=FT.noclip_space; spaceLabel.TextXAlignment=Enum.TextXAlignment.Left
    createToggle(spaceRow, 146, 1, flyanim.noclipSpaceEnabled, function(state) flyanim.noclipSpaceEnabled = state end)
    local ctrlRow = Instance.new("Frame", noclipSec); ctrlRow.Size=UDim2.new(1,-12,0,20); ctrlRow.Position=UDim2.new(0,6,0,40); ctrlRow.BackgroundTransparency=1
    local ctrlLabel = Instance.new("TextLabel", ctrlRow); ctrlLabel.Size=UDim2.new(0,88,1,0); ctrlLabel.BackgroundTransparency=1; ctrlLabel.Font=Enum.Font.Gotham; ctrlLabel.TextSize=10; ctrlLabel.TextColor3=C_TEXT; ctrlLabel.Text=FT.noclip_ctrl; ctrlLabel.TextXAlignment=Enum.TextXAlignment.Left
    createToggle(ctrlRow, 146, 1, flyanim.noclipCtrlEnabled, function(state) flyanim.noclipCtrlEnabled = state end)
    local megaRow = Instance.new("Frame", noclipSec); megaRow.Size=UDim2.new(1,-12,0,20); megaRow.Position=UDim2.new(0,6,0,62); megaRow.BackgroundTransparency=1
    local megaLabel = Instance.new("TextLabel", megaRow); megaLabel.Size=UDim2.new(0,88,1,0); megaLabel.BackgroundTransparency=1; megaLabel.Font=Enum.Font.Gotham; megaLabel.TextSize=10; megaLabel.TextColor3=C_TEXT; megaLabel.Text=FT.noclip_mega; megaLabel.TextXAlignment=Enum.TextXAlignment.Left
    createToggle(megaRow, 146, 1, flyanim.noclipMegaEnabled, function(state) flyanim.noclipMegaEnabled = state end)
    local speedSec = makeSection(104); speedSec.BackgroundColor3=Color3.fromRGB(25,12,55); speedSec.Parent=expandZone
    local speedStroke = Instance.new("UIStroke", speedSec); speedStroke.Color=C_PURPLE; speedStroke.Thickness=1; speedStroke.Transparency=0.6
    local function makeRow(labelText, yPos, defaultVal, minVal, maxVal)
        local lbl = Instance.new("TextLabel", speedSec); lbl.Size=UDim2.new(0,88,0,18); lbl.Position=UDim2.new(0,8,0,yPos); lbl.BackgroundTransparency=1; lbl.Font=Enum.Font.GothamSemibold; lbl.TextSize=10; lbl.TextColor3=C_TEXT; lbl.Text=labelText; lbl.TextXAlignment=Enum.TextXAlignment.Left
        local box = Instance.new("TextBox", speedSec); box.Size=UDim2.new(1,-100,0,18); box.Position=UDim2.new(0,94,0,yPos); box.BackgroundColor3=Color3.fromRGB(18,6,32); box.BackgroundTransparency=0.05; box.BorderSizePixel=0; box.Font=Enum.Font.GothamBold; box.TextSize=10; box.TextColor3=C_ACCENT; box.Text=tostring(defaultVal); box.ClearTextOnFocus=true; Instance.new("UICorner", box).CornerRadius=UDim.new(0,4); local bs = Instance.new("UIStroke", box); bs.Color=C_ACCENT; bs.Thickness=1; bs.Transparency=0.55
        box:GetPropertyChangedSignal("Text"):Connect(function() local n = tonumber(box.Text:match("[%d%.]+")); if n then n = math.clamp(n, minVal, maxVal); box.Text = tostring(n) end end)
        return box
    end
    local speedBox = makeRow(FT.speed_base, 6, flyanim.BASE_SPEED, 1, 10000)
    local fastBox = makeRow(FT.speed_turbo_mult, 30, flyanim.FAST_MULT, 1, 1000)
    local turboBox = makeRow(FT.speed_mega_mult, 54, flyanim.TURBO_MULT, 1, 1000)
    local resetBtn = Instance.new("TextButton", speedSec); resetBtn.Size=UDim2.new(0,90,0,20); resetBtn.Position=UDim2.new(0.5,-45,0,82); resetBtn.BackgroundColor3=Color3.fromRGB(60,10,110); resetBtn.BackgroundTransparency=0.2; resetBtn.BorderSizePixel=0; resetBtn.Font=Enum.Font.GothamBold; resetBtn.TextSize=10; resetBtn.TextColor3=C_TEXT; resetBtn.Text=FT.speed_reset; Instance.new("UICorner", resetBtn).CornerRadius=UDim.new(0,5)
    local function recalcSpeed() if flyanim.mode == "normal" then flyanim.speed = flyanim.BASE_SPEED elseif flyanim.mode == "fast" then flyanim.speed = flyanim.BASE_SPEED * flyanim.FAST_MULT elseif flyanim.mode == "turbo" then flyanim.speed = flyanim.BASE_SPEED * flyanim.TURBO_MULT end end
    speedBox.FocusLost:Connect(function() local n = tonumber(speedBox.Text:match("[%d%.]+")); if n then flyanim.BASE_SPEED = math.clamp(math.floor(n+0.5), 1, 10000) end; speedBox.Text = tostring(flyanim.BASE_SPEED); recalcSpeed() end)
    fastBox.FocusLost:Connect(function() local n = tonumber(fastBox.Text:match("[%d%.]+")); if n then flyanim.FAST_MULT = math.clamp(n, 1, 1000) end; fastBox.Text = tostring(flyanim.FAST_MULT); recalcSpeed(); if flyanim.updateMode then flyanim.updateMode(flyanim.mode) end end)
    turboBox.FocusLost:Connect(function() local n = tonumber(turboBox.Text:match("[%d%.]+")); if n then flyanim.TURBO_MULT = math.clamp(n, 1, 1000) end; turboBox.Text = tostring(flyanim.TURBO_MULT); recalcSpeed(); if flyanim.updateMode then flyanim.updateMode(flyanim.mode) end end)
    resetBtn.MouseButton1Click:Connect(function() flyanim.BASE_SPEED = 60; flyanim.FAST_MULT = 3.0; flyanim.TURBO_MULT = 6.0; speedBox.Text = "60"; fastBox.Text = "3.0"; turboBox.Text = "6.0"; recalcSpeed(); if flyanim.updateMode then flyanim.updateMode(flyanim.mode) end; TweenService:Create(resetBtn, TweenInfo.new(0.1), {TextColor3=C_GREEN}):Play(); task.delay(0.5, function() pcall(function() TweenService:Create(resetBtn, TweenInfo.new(0.3), {TextColor3=C_TEXT}):Play() end) end) end)
    local pulseRunning = false
    local function startPulse()
        if pulseRunning then return end
        pulseRunning = true
        flyanim.pulse = task.spawn(function()
            while flyanim.gui and flyanim.gui.Parent and flyanim.expanded do
                TweenService:Create(stroke, TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Thickness=2.5, Color=C_ACCENT, Transparency=0}):Play()
                task.wait(0.7)
                if not (flyanim.gui and flyanim.gui.Parent and flyanim.expanded) then break end
                TweenService:Create(stroke, TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Thickness=1.5, Color=C_PURPLE, Transparency=0.35}):Play()
                task.wait(0.7)
            end
            pcall(function() stroke.Thickness=1.2; stroke.Color=C_PURPLE; stroke.Transparency=0.75 end)
            pulseRunning=false; flyanim.pulse=nil
        end)
    end
    local function setExpanded(state)
        flyanim.expanded=state; expandZone.Visible=state
        local h = state and H_FULL or H_MINI; root.Size = UDim2.new(0,W,0,h)
        TweenService:Create(panel, TW, {Size=UDim2.new(1,0,0,h)}):Play()
        TweenService:Create(dot, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {BackgroundTransparency=state and 0 or 0.35}):Play()
        TweenService:Create(dot, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {Size = state and UDim2.new(0,DOT_SIZE,0,DOT_SIZE) or UDim2.new(0,DOT_SIZE-3,0,DOT_SIZE-3), Position = state and UDim2.new(0.5,-DOT_SIZE/2,0.5,-DOT_SIZE/2) or UDim2.new(0.5,-(DOT_SIZE-3)/2,0.5,-(DOT_SIZE-3)/2)}):Play()
        if state then startPulse() else if flyanim.pulse then pcall(function() task.cancel(flyanim.pulse) end); flyanim.pulse=nil; pulseRunning=false; pcall(function() stroke.Thickness=1.2; stroke.Color=C_PURPLE; stroke.Transparency=0.75 end) end end
    end
    dotBtn.MouseButton1Click:Connect(function() setExpanded(not flyanim.expanded) end)
    local dragging=false; local dragStartMouse=Vector2.new(); local dragStartPos=UDim2.new()
    topBar.InputBegan:Connect(function(inp) if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then dragging=true; dragStartMouse=Vector2.new(inp.Position.X,inp.Position.Y); dragStartPos=root.Position end end)
    topBar.InputEnded:Connect(function(inp) if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then dragging=false end end)
    UserInputService.InputChanged:Connect(function(inp) if not dragging then return end; if inp.UserInputType~=Enum.UserInputType.MouseMovement and inp.UserInputType~=Enum.UserInputType.Touch then return end; local delta = Vector2.new(inp.Position.X,inp.Position.Y) - dragStartMouse; root.Position = UDim2.new(dragStartPos.X.Scale, dragStartPos.X.Offset+delta.X, dragStartPos.Y.Scale, dragStartPos.Y.Offset+delta.Y) end)
    flyanim.updateLbl = function(keyName) local FTnow = FlyText.GetFullTable(); pcall(function() titleLbl.Text = FTnow.fly_title.." ["..keyName.."]" end) end
    flyanim.updateMode = function(modeName)
        local FTnow = FlyText.GetFullTable()
        pcall(function()
            local multF = math.floor(flyanim.FAST_MULT*10+0.5)/10; local multT = math.floor(flyanim.TURBO_MULT*10+0.5)/10
            local labels = { normal=FTnow.mode_normal, fast=FTnow.mode_fast..tostring(multF), turbo=FTnow.mode_mega..tostring(multT), megaup=FTnow.mode_megaup..tostring(multT) }
            local colors = { normal=C_GREEN, fast=C_YELLOW, turbo=C_RED, megaup=C_CYAN }
            local dotColors = { normal=C_ACCENT, fast=C_YELLOW, turbo=C_RED, megaup=C_CYAN }
            modeLbl.Text = labels[modeName] or modeName; modeLbl.TextColor3 = colors[modeName] or C_GREEN
            TweenService:Create(dot, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {BackgroundColor3=dotColors[modeName] or C_ACCENT}):Play()
        end)
    end
end

local _inputConn = nil; local _inputConn_End = nil; local _charConn = nil
local function _connectGlobal()
    if _inputConn then _inputConn:Disconnect(); _inputConn = nil end
    if _inputConn_End then _inputConn_End:Disconnect(); _inputConn_End = nil end
    if _charConn then _charConn:Disconnect(); _charConn = nil end
    _inputConn = UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end; if isTyping() then return end
        if input.KeyCode == flyanim.flyKey then if flyanim.enabled then flyOff() else flyOn() end; return end
        if input.KeyCode == Enum.KeyCode.Q then
            if not flyanim.enabled then return end
            local wDown = UserInputService:IsKeyDown(Enum.KeyCode.W); local sDown = UserInputService:IsKeyDown(Enum.KeyCode.S); local aDown = UserInputService:IsKeyDown(Enum.KeyCode.A); local dDown = UserInputService:IsKeyDown(Enum.KeyCode.D)
            if not wDown then
                if sDown and not aDown and not dDown then triggerDash("back", flyanim.BACK_DASH_SPEED, flyanim.DASH_DURATION * 1.2); local t = getTrack("rbxassetid://82718659527221"); if t then for id, track in pairs(flyanim.tracks) do if id ~= "rbxassetid://82718659527221" and track and track.IsPlaying then pcall(function() track:Stop(0.04) end) end end; pcall(function() t:Play(0.04, 1, 1); t:AdjustSpeed(3.0) end) end; return end
                if aDown and not sDown and not dDown then triggerDash("left", flyanim.SIDE_DASH_SPEED, flyanim.DASH_DURATION); local t = getTrack("rbxassetid://82718659527221"); if t then for id, track in pairs(flyanim.tracks) do if id ~= "rbxassetid://82718659527221" and track and track.IsPlaying then pcall(function() track:Stop(0.04) end) end end; pcall(function() t:Play(0.04, 1, 1); t:AdjustSpeed(3.0) end) end; return end
                if dDown and not sDown and not aDown then triggerDash("right", flyanim.SIDE_DASH_SPEED, flyanim.DASH_DURATION); local t = getTrack("rbxassetid://93831708296422"); if t then for id, track in pairs(flyanim.tracks) do if id ~= "rbxassetid://93831708296422" and track and track.IsPlaying then pcall(function() track:Stop(0.04) end) end end; pcall(function() t:Play(0.04, 1, 1); t:AdjustSpeed(3.0) end) end; return end
            end
            if flyanim.mode == "normal" then
                flyanim.isSpaceAdv = false; if flyanim.spaceHoldTimerAdv then task.cancel(flyanim.spaceHoldTimerAdv); flyanim.spaceHoldTimerAdv = nil end; manejarEspacioSoltadoNormal()
                flyanim.mode = "fast"; flyanim.speed = flyanim.BASE_SPEED * flyanim.FAST_MULT; flyanim.qLastPress = tick(); flyanim.turboActivatedAt = tick()
                if flyanim.updateMode then flyanim.updateMode("fast") end; setNoclip(false); shakeCamera(2.0, 0.3); playLocalSound(SFX_TURBO, 0.82); sonicBoomEffect(1); airShockAura(1); speedWhiteFlash("fast"); triggerDash("forward", flyanim.TURBO_DASH_SPEED, flyanim.TURBO_DASH_DURATION); startParticleEmitter(); detenerNormalTracks(0.1); iniciarPoseTurbo()
                return
            end
            if flyanim.mode == "fast" then if tick() - flyanim.turboActivatedAt >= 0.75 then flyanim.mode = "turbo"; flyanim.speed = flyanim.BASE_SPEED * flyanim.TURBO_MULT; if flyanim.updateMode then flyanim.updateMode("turbo") end; if flyanim.noclipMegaEnabled then setNoclip(true) end; shakeCamera(3.5, 0.4); playLocalSound(SFX_MEGA_TURBO, 0.88); sonicBoomEffect(2); airShockAura(2); speedWhiteFlash("turbo"); triggerDash("forward", flyanim.TURBO_DASH_SPEED * 1.5, flyanim.TURBO_DASH_DURATION * 1.2); startParticleEmitter(); detenerPoseTurbo(); iniciarPoseMega() end; return end
        end
        if input.KeyCode == Enum.KeyCode.F and flyanim.enabled then
            flyanim.fKeyHeld = true
            if not flyanim.blockCancelledByCombo then
                if flyanim.mode == "normal" and not flyanim.turboPreImpulsoActivo and not flyanim.megaTurboUpActive then
                    if flyanim.comboPlaying then flyanim.comboToken = flyanim.comboToken + 1; for _, track in pairs(flyanim.tracks) do pcall(function() if track and track.IsPlaying then track:Stop(0.08) end end) end; flyanim.comboPlaying = false; flyanim.comboBusy = false; flyanim.combo4Frozen = false; if flyanim.resetCombo then flyanim.resetCombo() end; stopComboC0Lock() end
                    startBlocking()
                end
            end
            return
        end
        if input.KeyCode == Enum.KeyCode.Space and flyanim.enabled and flyanim.mode == "normal" then if not flyanim.comboPlaying and not flyanim.turboPreImpulsoActivo then manejarEspacioPresionadoNormal() end end
        if flyanim.enabled and flyanim.mode == "normal" then
            if input.KeyCode == Enum.KeyCode.W then evaluarMovimientoDebounced() end
            if input.KeyCode == Enum.KeyCode.S then evaluarMovimientoDebounced() end
            if input.KeyCode == Enum.KeyCode.A then evaluarMovimientoDebounced() end
            if input.KeyCode == Enum.KeyCode.D then evaluarMovimientoDebounced() end
        end
    end)
    _inputConn_End = UserInputService.InputEnded:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == Enum.KeyCode.F then flyanim.fKeyHeld = false; flyanim.blockCancelledByCombo = false; if flyanim.enabled then stopBlocking() end; return end
        if input.KeyCode == Enum.KeyCode.Space and flyanim.enabled then manejarEspacioSoltadoNormal() end
        if flyanim.enabled and flyanim.mode == "normal" then
            if input.KeyCode == Enum.KeyCode.W then evaluarMovimientoDebounced() end
            if input.KeyCode == Enum.KeyCode.S then evaluarMovimientoDebounced() end
            if input.KeyCode == Enum.KeyCode.A then evaluarMovimientoDebounced() end
            if input.KeyCode == Enum.KeyCode.D then evaluarMovimientoDebounced() end
        end
    end)
    _charConn = flyanim.lplr.CharacterAdded:Connect(function(newChar)
        if flyanim.shakeConn then pcall(function() flyanim.shakeConn:Disconnect() end); flyanim.shakeConn=nil end
        destroyWhiteFlash(); local cam = workspace.CurrentCamera; if cam then cam.FieldOfView=70 end
        flyanim.mode="normal"; flyanim.speed=flyanim.BASE_SPEED; flyanim.isMoving=false
        flyanim.wDown=false; flyanim.sDown=false; flyanim.aDown=false; flyanim.dDown=false
        flyanim.isWDown=false; flyanim.isSDown=false; flyanim.isADown=false; flyanim.isDDown=false
        flyanim.waitingLand=false; flyanim.landingHeight=nil; flyanim.landingVelocity=0; flyanim.landingVelocityCapture=0
        flyanim.megaTurboUpActive=false; flyanim.spaceHoldStart=nil; flyanim.isBlocking=false; flyanim.isSpaceAdv=false; flyanim._normalPlayId=0
        flyanim.turboPreImpulsoActivo=false; flyanim.turboPreImpulsoToken=0; flyanim.comboPlaying=false; flyanim.comboBusy=false; flyanim.combo4Frozen=false; flyanim.comboToken=0
        flyanim.idleWatchToken = flyanim.idleWatchToken + 1; flyanim.c0ControlToken = 0; flyanim.c0HeightToken = 0; flyanim.lastDamageTime = 0
        flyanim.straightLineActive = false; flyanim.noclipSpaceActive = false; flyanim.noclipCtrlActive = false; flyanim.mouseHeld = false
        flyanim.lastKnownPos = nil; flyanim.ragdollDetected = false; flyanim.fKeyHeld = false; flyanim.blockCancelledByCombo = false; flyanim.comboAnimStartTime = 0
        flyanim.lastSafePos = nil; flyanim.lastSafeTime = tick(); flyanim.isTeleportGuardActive = false
        if flyanim.idleAnimConn then flyanim.idleAnimConn:Disconnect(); flyanim.idleAnimConn=nil end
        flyanim.lateralKilled=true; flyanim.atrasKilled=true
        if flyanim.spaceHoldTimerAdv then task.cancel(flyanim.spaceHoldTimerAdv); flyanim.spaceHoldTimerAdv=nil end
        flyanim.espacioTrackActivo=nil; flyanim.dashAnimToken = flyanim.dashAnimToken + 1
        flyanim.sessionToken = flyanim.sessionToken + 1
        _landAnimToken = _landAnimToken + 1; _landBaseRef = nil; _landOverlayRef = nil
        stopParticleEmitter(); stopBrakeSystem(); stopAntiImpulse(); detenerWatchdogAltura()
        if flyanim.turboRenderConn then flyanim.turboRenderConn:Disconnect(); flyanim.turboRenderConn=nil end
        if flyanim.megaRenderConn then flyanim.megaRenderConn:Disconnect(); flyanim.megaRenderConn=nil end
        if flyanim.blockRenderConn then flyanim.blockRenderConn:Disconnect(); flyanim.blockRenderConn=nil end
        if flyanim.landConn then flyanim.landConn:Disconnect(); flyanim.landConn=nil end
        if flyanim.dashConnection then flyanim.dashConnection:Disconnect(); flyanim.dashConnection=nil end
        if flyanim.rsConn then flyanim.rsConn:Disconnect(); flyanim.rsConn=nil end
        if flyanim.tpMoveConn then flyanim.tpMoveConn:Disconnect(); flyanim.tpMoveConn=nil end
        if flyanim.idleTimer then task.cancel(flyanim.idleTimer); flyanim.idleTimer=nil end
        if flyanim.anomalyConn then flyanim.anomalyConn:Disconnect(); flyanim.anomalyConn=nil end
        if flyanim.teleportGuardConn then flyanim.teleportGuardConn:Disconnect(); flyanim.teleportGuardConn=nil end
        stopComboC0Lock()
        if flyanim.animScript then pcall(function() flyanim.animScript.Disabled=false end); flyanim.animScript=nil end
        if flyanim.animConn then flyanim.animConn:Disconnect(); flyanim.animConn=nil end
        flyanim.animator=nil; flyanim.rootJoint=nil; flyanim.originalC0=nil
        _flyDestroyGui()
        if flyanim.enabled then task.wait(0.5); flyOn() end
    end)
end
local function _disconnectGlobal()
    if _inputConn then _inputConn:Disconnect(); _inputConn = nil end
    if _inputConn_End then _inputConn_End:Disconnect(); _inputConn_End = nil end
    if _charConn then _charConn:Disconnect(); _charConn = nil end
end
local function _flyDestroyGui()
    if flyanim.pulse then pcall(function() task.cancel(flyanim.pulse) end); flyanim.pulse = nil end
    flyanim.expanded = false; flyanim.updateLbl = nil; flyanim.updateMode = nil
    if flyanim.gui then pcall(function() flyanim.gui:Destroy() end); flyanim.gui = nil end
    flyanim.lockInfoGui = nil
end

local function startIdleWatcher()
    if flyanim.idleTimer then task.cancel(flyanim.idleTimer); flyanim.idleTimer = nil end
    flyanim.idleTimer = task.spawn(function()
        while flyanim.enabled do
            task.wait(0.1)
            if flyanim.mode == "normal" then continue end
            if flyanim.turboTransitioning or flyanim.megaTransitioning then continue end
            if flyanim.turboPreImpulsoActivo then continue end
            local anyKey = UserInputService:IsKeyDown(Enum.KeyCode.W) or UserInputService:IsKeyDown(Enum.KeyCode.S)
                        or UserInputService:IsKeyDown(Enum.KeyCode.A) or UserInputService:IsKeyDown(Enum.KeyCode.D)
            if not anyKey then
                local prevMode = flyanim.mode
                flyanim.mode = "normal"; flyanim.speed = flyanim.BASE_SPEED; flyanim.qLastPress = 0
                if flyanim.updateMode then flyanim.updateMode("normal") end
                if not flyanim.noclipSpaceActive and not flyanim.noclipCtrlActive then setNoclip(false) end
                stopParticleEmitter()
                if flyanim.turboRenderConn then flyanim.turboRenderConn:Disconnect(); flyanim.turboRenderConn = nil end
                if flyanim.megaRenderConn then flyanim.megaRenderConn:Disconnect(); flyanim.megaRenderConn = nil end
                detenerWatchdogAltura()
                if prevMode == "fast" then detenerPoseTurbo()
                elseif prevMode == "turbo" then detenerPoseMega(); detenerPoseTurbo() end
                flyanim.c0ControlToken = flyanim.c0ControlToken + 1
                restaurarC0Inmediato()
                if not flyanim.comboPlaying then
                    flyanim._normalPlayId = flyanim._normalPlayId + 1
                    iniciarCicloNormal(flyanim, flyanim._normalPlayId)
                end
            end
        end
    end)
end

local function resetComboFlyAnim()
    flyanim.comboStep = 0; flyanim.comboLastClick = 0; flyanim.combo2LastUsed = nil; comboPendingClick = false
end
flyanim.resetCombo = resetComboFlyAnim
flyanim.stopComboC0Lock = stopComboC0Lock

-- ============================================================
-- EXPORTACIÓN PÚBLICA (API para el hub)
-- ============================================================
local M = {}

function M.Start(lplrRef, flyKey)
    flyanim.lplr = lplrRef or Players.LocalPlayer
    flyanim.camera = workspace.CurrentCamera
    FlyText.Reload()
    if flyKey then flyanim.flyKey = flyKey end
    _flyBuildGui()
    startIdleWatcher()
    _connectGlobal()
end

function M.Stop()
    if flyanim.enabled then flyOff() end
    _disconnectGlobal()
    _flyDestroyGui()
    if flyanim.idleTimer then task.cancel(flyanim.idleTimer); flyanim.idleTimer = nil end
    if flyanim.spaceHoldTimerAdv then task.cancel(flyanim.spaceHoldTimerAdv); flyanim.spaceHoldTimerAdv = nil end
    if flyanim.gyroProtectionTimer then task.cancel(flyanim.gyroProtectionTimer); flyanim.gyroProtectionTimer = nil end
    if flyanim.pulse then task.cancel(flyanim.pulse); flyanim.pulse = nil end
    stopParticleEmitter(); killActiveParticles()
    local char = flyanim.lplr.Character
    if char then
        local animScript = char:FindFirstChild("Animate")
        if animScript then animScript.Disabled = false end
        local root = char:FindFirstChild("HumanoidRootPart")
        if root then for _, v in ipairs(root:GetChildren()) do if v:IsA("BodyGyro") or v:IsA("BodyVelocity") or v:IsA("BodyForce") then v:Destroy() end end end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = false; pcall(function() hum:ChangeState(Enum.HumanoidStateType.Running) end) end
    end
end

function M.Toggle(state)
    if state then if not flyanim.enabled then flyOn() end else if flyanim.enabled then flyOff() end end
end

function M.SetKey(keyCode)
    flyanim.flyKey = keyCode
    if flyanim.updateLbl then pcall(function() flyanim.updateLbl(keyCode.Name) end) end
    if _inputConn then _inputConn:Disconnect(); _inputConn = nil end
    if _inputConn_End then _inputConn_End:Disconnect(); _inputConn_End = nil end
    _connectGlobal()
end

function M.SetLockKey(keyCode)
    flyanim.lockKey = keyCode
    local FTnow = FlyText.GetFullTable()
    if flyanim.lockLabels then flyanim.lockLabels.label.Text = FTnow.lock_label.." ["..keyCode.Name.."]"; flyanim.lockLabels.hint.Text = FTnow.lock_hint_prefix..keyCode.Name end
    if flyanim.lockConn then flyanim.lockConn:Disconnect(); flyanim.lockConn = nil end
    if flyanim.enabled then startLockSystem() end
end

function M.GetFlyKey() return flyanim.flyKey end
function M.GetLockKey() return flyanim.lockKey end
function M.IsEnabled() return flyanim.enabled end

return M
