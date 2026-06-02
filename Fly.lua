print("version 1.61 fly")

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui          = game:GetService("CoreGui")
local SoundService     = game:GetService("SoundService")

-- ══════════════════════════════════════════════
-- SISTEMA DE IDIOMA (espejo del hub All For One)
-- Lee el mismo lang.txt que el hub para mantenerse sincronizado
-- ══════════════════════════════════════════════
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
-- FT se recarga en cada _flyBuildGui() para respetar cambios de idioma del hub
local FT = FlyLang["ES"]  -- default; se sobreescribe en _flyBuildGui y M.Start

local function _reloadFT()
    local lang = "ES"
    pcall(function()
        local data = readfile("AllForOne/lang.txt")
        if data == "EN" or data == "ES" then lang = data end
    end)
    FT = FlyLang[lang]
end

-- Cargar al inicio del require por si el módulo se usa inmediatamente
_reloadFT()

-- lplr y camera se asignan en M.Start()
local lplr   = nil
local camera = nil

local function isTyping()
    return UserInputService:GetFocusedTextBox() ~= nil
end

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

local SFX_TURBO        = "rbxassetid://137455842313478"
local SFX_MEGA_TURBO   = "rbxassetid://111391583223900"
local SFX_LANDING      = "rbxassetid://135226467234227"
local SMOKE_RING_TEX   = "rbxassetid://137805272670926"

local function playLocalSound(id, volume)
    local snd = Instance.new("Sound")
    snd.SoundId   = id
    snd.Volume     = volume or 0.85
    snd.RollOffMaxDistance = 0
    snd.Parent     = SoundService
    snd:Play()
    task.delay(10, function() pcall(function() snd:Destroy() end) end)
    snd.Ended:Connect(function() pcall(function() snd:Destroy() end) end)
end

local BASE_SPEED    = 60
local FAST_MULT     = 3.0
local TURBO_MULT    = 6.0
local DEFAULT_BASE  = 60
local DEFAULT_FAST  = 3.0
local DEFAULT_TURBO = 6.0

local LOCK_ROTATION_SMOOTH = 0.8

-- Límite de coordenadas para detectar teletransporte anómalo
local COORD_SANITY_LIMIT = 50000



local ANIM_NORMAL = {
    COMPENSACION_ALTURA  = 1.5,
    PARADA_ESTATICA      = 0.01,
    VELOCIDAD_LEVITACION = 0.8,
    TIEMPO_QUIETO        = 2,
    TIEMPO_TRANSICION    = 0.5,
    INICIO_A             = 0.40,
    INICIO_D             = 0.85,
    PESO_LATERAL         = 0.40,
    OSCILA_RIGHT         = 0.25,
    OSCILA_LEFT          = 0.50,
    OSCILA_VEL           = 0.01,
    DEBOUNCE_TECLADO     = 0.08,
    VEL_ATRAS_NORMAL     = 0.06,
    VEL_ATRAS_RAPIDO     = 0.12,
    LATERAL_LERP_VEL     = 0.06,
    TRANSICION_FLUIDA    = 0.4,
    TRANSICION_POS       = 0.5,
}

-- TURBO: 25 grados (reducido desde 45)
local ANIM_TURBO = {
    COMPENSACION_ALTURA    = 2,
    INCLINACION_GRADOS     = 25,   -- 25 grados para modo turbo
    FRAME_CONGELADO        = 0.1,
    FRAME_VOLADO_CONGELADO = 0.35,
    AMPLITUD_LEVITACION    = 0.15,
    FRECUENCIA_LEVITACION  = 1.5,
    TIEMPO_CONTRAERSE      = 0.4,
    TIEMPO_PAUSA           = 0.1,
    TIEMPO_TRANSICION      = 0.4,
    INCLINACION_DESPEGUE   = 90,
}

-- MEGA: 45 grados (sin cambios)
local ANIM_MEGA = {
    INCLINACION_GRADOS     = 45,
    COMPENSACION_ALTURA    = 2,
    AMPLITUD_LEVITACION    = 0.2,
    FRECUENCIA_LEVITACION  = 1.5,
    FRAME_VOLADO_CONGELADO = 0.35,
    FRAME_POSE_CONGELADO   = 0.1,
}

local ANIM_BLOQUEO = {
    INICIO_PERC   = 0.25,
    RESPIRO_PERC  = 0.40,
    OSCILA_MIN    = 0.475,
    OSCILA_RANGE  = 0.025,
    VEL_RAPIDO    = 4,
    VEL_LENTO     = 0.5,
}

local COMBO_MIN_GAP        = 0.08

local flyanim = {
    enabled     = false,
    speed       = BASE_SPEED,
    flyKey      = Enum.KeyCode.C,
    lockKey     = Enum.KeyCode.X,
    bg          = nil,
    bv          = nil,
    bf          = nil,
    rsConn      = nil,
    gui         = nil,
    pulse       = nil,
    expanded    = false,
    updateLbl   = nil,
    updateMode  = nil,
    animator    = nil,
    tracks      = {},
    animConn    = nil,
    animScript  = nil,
    mode        = "normal",
    qLastPress  = 0,
    turboActivatedAt = 0,
    idleTimer   = nil,
    isMoving    = false,
    wDown = false, sDown = false, aDown = false, dDown = false,
    waitingLand = false,
    landConn    = nil,
    landingHeight = nil,
    landingVelocity = 0,
    landingVelocityCapture = 0,

    comboStep       = 0,
    comboLastClick  = 0,
    combo2LastUsed  = nil,
    comboConn       = nil,
    comboPlaying    = false,
    combo4Frozen    = false,
    comboToken      = 0,
    comboBusy       = false,
    comboAnimStartTime = 0,

    comboC0Conn     = nil,
    comboHoldConn   = nil,
    mouseHeld       = false,

    dashVel         = Vector3.new(0, 0, 0),
    dashTimer       = 0,
    DASH_SPEED      = 297,
    DASH_DURATION   = 0.38,
    SIDE_DASH_SPEED = 297 * 1.35,
    TURBO_DASH_SPEED    = 405,
    TURBO_DASH_DURATION = 0.45,
    BACK_DASH_SPEED = 594,

    spaceHoldStart    = nil,
    SPACE_HOLD_TIME   = 2,
    megaTurboUpConn   = nil,
    megaTurboUpActive = false,

    lockActive      = false,
    lockedTarget    = nil,
    lockIconGui     = nil,
    lockInfoGui     = nil,
    lockCameraLerp  = 0.18,
    lockHighlight   = nil,
    lockConn        = nil,
    lockRenderConn  = nil,

    straightLineActive = false,

    brakingActive     = false,
    BRAKE_DISTANCE    = 35,
    BRAKE_HARD_DISTANCE = 14,

    particleRunning = false,
    particleConn    = nil,
    particleUpMode  = false,

    antiImpulseConn      = nil,
    noclipSpaceEnabled   = true,
    noclipSpaceActive    = false,
    noclipMegaEnabled    = true,
    noclipCtrlEnabled    = true,
    noclipCtrlActive     = false,
    gyroProtectionActive = false,
    gyroProtectionTimer  = nil,
    originalGyroP        = nil,
    originalGyroMaxTorque = nil,
    backupGyro           = nil,

    lastKnownPos         = nil,
    anomalyConn          = nil,
    ragdollDetected      = false,

    animBlockRenderConn  = nil,

    blockTrack      = nil,
    isBlocking      = false,
    blockRenderConn = nil,
    lastDamageTime  = 0,
    BLOCK_DAMAGE_COOLDOWN = 0.75,
    damageConn      = nil,
    fKeyHeld        = false,
    blockCancelledByCombo = false,

    rootJoint   = nil,
    originalC0  = nil,

    -- Sistema de compensación de altura robusto
    c0HeightOffset = 0,
    c0HeightConn   = nil,
    c0HeightToken  = 0,

    normalTracks  = {},
    idleTimerAnim = 0,
    isBrazosActive = false,
    idleAnimConn  = nil,

    isWDown = false, isSDown = false, isADown = false, isDDown = false,
    evalToken      = 0,
    lateralTarget  = 0,
    lateralLoopId  = 0,
    lateralKilled  = false,
    atrasTarget    = 0,
    atrasLoopId    = 0,
    atrasKilled    = false,
    atrasCurrentSpeed = 0.06,
    contA = 0, contD = 0, contS = 0,
    piernaPrefA = 0.50,
    piernaPrefD = 0.25,
    piernaPrefS = 0.50,
    currentAtrasId   = 0,
    currentLateralId = 0,

    espacioTrackActivo    = nil,
    isSpaceAdv            = false,
    spaceHoldTimerAdv     = nil,
    ESPACIO_TIEMPO_CAMBIO = 2,
    ESPACIO_FADE_OUT      = 0.1,

    turboRenderConn   = nil,
    turboTransitioning = false,
    megaRenderConn    = nil,
    megaTransitioning = false,
    _normalPlayId     = 0,

    turboPreImpulsoActivo = false,
    turboPreImpulsoToken  = 0,

    idleWatchToken = 0,
    dashAnimToken  = 0,
    c0ControlToken = 0,

    tpMoveConn = nil,

    -- Sistema anti-teletransporte forzado
    lastSafePos      = nil,
    lastSafeTime     = 0,
    teleportGuardConn = nil,
    isTeleportGuardActive = false,

    -- Token de sesión: se incrementa en _flyOff() para invalidar INSTANTÁNEAMENTE
    -- cualquier callback de Heartbeat/Stepped que corra un tick extra tras el apagado.
    -- Cada guard captura su sessionToken al iniciar y lo comprueba ANTES de actuar.
    sessionToken = 0,
}

-- ============================================================
-- SISTEMA DE COMPENSACIÓN DE ALTURA ROBUSTO
-- Mantiene un loop dedicado que corrige el C0 cada frame
-- y detecta/corrige cuando el offset se aplica mal
-- ============================================================

local c0DesiredCFrame = nil  -- El CFrame exacto que queremos en rootJoint.C0
-- Token para cancelar tweens de compensación de altura en vuelo
local heightTweenToken = 0

-- Forward declarations para funciones de landing watcher
-- (definidas más abajo, pero usadas por _flyOn y _charConn que se definen antes)
local stopLandingWatcher
local startLandingWatcher

local function setC0Desired(cf)
    c0DesiredCFrame = cf
end

local function clearC0Desired()
    c0DesiredCFrame = nil
end

local function restaurarC0Inmediato()
    -- Cancela cualquier tween de compensación de altura en curso
    heightTweenToken = heightTweenToken + 1
    if flyanim.rootJoint and flyanim.originalC0 then
        pcall(function() flyanim.rootJoint.C0 = flyanim.originalC0 end)
    end
    clearC0Desired()
end

-- ============================================================
-- SISTEMA ANTI-TELETRANSPORTE FORZADO
-- Detecta cuando el personaje es teletransportado a coordenadas
-- absurdas y lo devuelve a la última posición segura conocida
-- ============================================================

local function startTeleportGuard()
    if flyanim.teleportGuardConn then
        flyanim.teleportGuardConn:Disconnect()
        flyanim.teleportGuardConn = nil
    end
    flyanim.lastSafePos  = nil
    flyanim.lastSafeTime = tick()
    flyanim.isTeleportGuardActive = true

    local mySession = flyanim.sessionToken

    flyanim.teleportGuardConn = RunService.Stepped:Connect(function(_, dt)
        if flyanim.sessionToken ~= mySession then
            if flyanim.teleportGuardConn then
                flyanim.teleportGuardConn:Disconnect()
                flyanim.teleportGuardConn = nil
            end
            flyanim.isTeleportGuardActive = false
            return
        end
        if not flyanim.enabled then
            if flyanim.teleportGuardConn then
                flyanim.teleportGuardConn:Disconnect()
                flyanim.teleportGuardConn = nil
            end
            flyanim.isTeleportGuardActive = false
            return
        end
        if not flyanim.isTeleportGuardActive then return end

        local char = lplr.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then
            flyanim.lastSafePos = nil
            return
        end

        local pos = root.Position

        -- ÚNICA condición de TP permitida: caer al void (Y <= -500)
        -- Ninguna otra condición (delta de posición, velocidad absurda, etc.) activa el TP.
        if pos.Y <= -500 then
            local safePos = flyanim.lastSafePos
            if safePos then
                local targetCF = CFrame.new(safePos + Vector3.new(0, 5, 0))
                pcall(function()
                    root.CFrame = targetCF
                    root.AssemblyLinearVelocity  = Vector3.new(0, 0, 0)
                    root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                end)
                local cam = workspace.CurrentCamera
                if cam then
                    local camCF = cam.CFrame
                    task.defer(function()
                        if cam and cam.Parent then
                            cam.CFrame = camCF
                        end
                    end)
                end
                flyanim.dashTimer = 0
                flyanim.dashVel   = Vector3.new(0, 0, 0)
                if not root:FindFirstChildOfClass("BodyGyro") then
                    pcall(_flyMakeMotors)
                end
            end
            return
        end

        -- Actualizar posición segura siempre que las coords sean razonables
        if math.abs(pos.X) < COORD_SANITY_LIMIT and math.abs(pos.Z) < COORD_SANITY_LIMIT then
            flyanim.lastSafePos  = pos
            flyanim.lastSafeTime = tick()
        end
    end)
end

local function stopTeleportGuard()
    flyanim.isTeleportGuardActive = false
    if flyanim.teleportGuardConn then
        flyanim.teleportGuardConn:Disconnect()
        flyanim.teleportGuardConn = nil
    end
    flyanim.lastSafePos = nil
end

local function setNoclip(state)
    local char = lplr.Character
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then part.CanCollide = not state end
    end
end

local function cleanupMotors(root, preserveVelY)
    if not root then return end
    for _, v in ipairs(root:GetChildren()) do
        if v:IsA("BodyGyro") or v:IsA("BodyVelocity") or v:IsA("BodyPosition")
        or v:IsA("BodyAngularVelocity") or v:IsA("BodyForce")
        or v:IsA("AlignOrientation") or v:IsA("LinearVelocity") then
            pcall(function() v:Destroy() end)
        end
    end
    -- preserveVelY=true: conservar velocidad Y o aplicar mínimo hacia abajo
    -- para que la gravedad tome efecto inmediatamente al apagar el vuelo.
    if preserveVelY then
        local currentVelY = 0
        pcall(function() currentVelY = root.AssemblyLinearVelocity.Y end)
        -- Si está quieto (velY == 0) o subiendo (velY > 0), aplicar
        -- pequeño impulso hacia abajo para que Freefall arranque correctamente.
        local finalVelY = (currentVelY >= 0) and -4 or currentVelY
        pcall(function() root.AssemblyLinearVelocity  = Vector3.new(0, finalVelY, 0) end)
    else
        pcall(function() root.AssemblyLinearVelocity  = Vector3.new(0, 0, 0) end)
    end
    pcall(function() root.AssemblyAngularVelocity = Vector3.new(0, 0, 0) end)
end

local function updateAntiGravityForce()
    if not flyanim.bf or not flyanim.bf.Parent then return end
    local char = lplr.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local totalMass = 0
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") and not part.Massless then
            totalMass = totalMass + part.AssemblyMass
        end
    end
    if totalMass == 0 then totalMass = root.AssemblyMass end
    local grav = workspace.Gravity
    flyanim.bf.Force = Vector3.new(0, totalMass * grav, 0)
end

local function getTrack(animId)
    if not flyanim.animator then return nil end
    if flyanim.tracks[animId] then return flyanim.tracks[animId] end
    local ok, obj = pcall(function()
        local a = Instance.new("Animation")
        a.AnimationId = animId
        return a
    end)
    if not ok then return nil end
    local ok2, t = pcall(function()
        local track = flyanim.animator:LoadAnimation(obj)
        track.Priority = Enum.AnimationPriority.Action4
        return track
    end)
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
        if t and t ~= flyanim.normalTracks.levitacion and t.IsPlaying then
            pcall(function() t:Stop(fade) end)
        end
    end
end

local function playAnim(animId, looped, fade)
    local t = getTrack(animId)
    if not t then return end
    fade  = fade or 0.18
    t.Looped = looped
    stopAllExcept(animId, fade, true)
    if not t.IsPlaying then
        pcall(function() t:Play(fade, 1, 1) end)
    end
end

local function normPlaySafe(track, fade)
    fade = fade or ANIM_NORMAL.TRANSICION_FLUIDA
    if track and not track.IsPlaying then
        pcall(function() track:Play(fade) end)
    end
end

local function normStopSafe(track, fade)
    fade = fade or ANIM_NORMAL.TRANSICION_FLUIDA
    if track and track.IsPlaying then
        pcall(function() track:Stop(fade) end)
    end
end

-- ============================================================
-- SISTEMA DE COMPENSACIÓN DE ALTURA ROBUSTO
-- Corrige el offset vertical del rootJoint con watchdog
-- ============================================================

local function iniciarWatchdogAltura(expectedCF, modeTag)
    -- Cancela el watchdog anterior
    flyanim.c0HeightToken = (flyanim.c0HeightToken or 0) + 1
    local myToken = flyanim.c0HeightToken

    if flyanim.c0HeightConn then
        flyanim.c0HeightConn:Disconnect()
        flyanim.c0HeightConn = nil
    end

    if not expectedCF then return end

    -- Watchdog: cada Heartbeat verifica que el C0 sea correcto
    -- Solo aplica si el modo coincide y no hay otro sistema controlando C0
    flyanim.c0HeightConn = RunService.Heartbeat:Connect(function()
        if flyanim.c0HeightToken ~= myToken then
            if flyanim.c0HeightConn then
                flyanim.c0HeightConn:Disconnect()
                flyanim.c0HeightConn = nil
            end
            return
        end
        if not flyanim.enabled then return end
        if flyanim.mode ~= modeTag then return end
        if not flyanim.rootJoint or not flyanim.originalC0 then return end
        -- No interferir si hay un render loop dedicado activo
        if modeTag == "fast" and (flyanim.turboRenderConn or flyanim.turboPreImpulsoActivo) then return end
        if modeTag == "turbo" and flyanim.megaRenderConn then return end
        if flyanim.comboPlaying then return end

        -- Verificar que el C0 no se haya desviado demasiado
        local current = flyanim.rootJoint.C0
        local diff = (current.Position - expectedCF.Position).Magnitude
        if diff > 0.5 then
            -- Corrección suave
            pcall(function()
                flyanim.rootJoint.C0 = current:Lerp(expectedCF, 0.3)
            end)
        end
    end)
end

local function detenerWatchdogAltura()
    flyanim.c0HeightToken = (flyanim.c0HeightToken or 0) + 1
    if flyanim.c0HeightConn then
        flyanim.c0HeightConn:Disconnect()
        flyanim.c0HeightConn = nil
    end
end

local function actualizarPosicionNormal(offsetY, velocidad)
    if not flyanim.rootJoint or not flyanim.originalC0 then return end
    -- Incrementar token para invalidar cualquier tween anterior en curso
    heightTweenToken = heightTweenToken + 1
    local myToken = heightTweenToken
    local targetCF
    if offsetY == 0 then
        targetCF = flyanim.originalC0
    else
        targetCF = flyanim.originalC0 + Vector3.new(0, offsetY, 0)
    end
    -- Usar interpolación manual con token para poder cancelarla
    local rj = flyanim.rootJoint
    local dur = velocidad or ANIM_NORMAL.TRANSICION_POS
    local startCF = rj.C0
    local startT  = tick()
    task.spawn(function()
        while true do
            task.wait()
            if heightTweenToken ~= myToken then return end
            if not flyanim.enabled then return end
            local elapsed = tick() - startT
            local t = math.clamp(elapsed / dur, 0, 1)
            -- Ease InOut Sine
            local ease = -(math.cos(math.pi * t) - 1) / 2
            pcall(function() rj.C0 = startCF:Lerp(targetCF, ease) end)
            if t >= 1 then return end
        end
    end)
end

local function detenerNormalTracks(fade)
    fade = fade or 0
    for _, t in pairs(flyanim.normalTracks) do
        pcall(function() if t and t.IsPlaying then t:Stop(fade) end end)
    end
    flyanim.lateralKilled  = true;  flyanim.lateralLoopId  = 0
    flyanim.atrasKilled    = true;  flyanim.atrasLoopId    = 0
    if flyanim.idleAnimConn then flyanim.idleAnimConn:Disconnect(); flyanim.idleAnimConn = nil end
    flyanim.isBrazosActive = false
    flyanim.idleTimerAnim  = 0
end

local function detenerNormalExceptoBase(fade)
    fade = fade or 0
    local nt       = flyanim.normalTracks
    local baseIds  = {nt.estatica, nt.levitacion}
    for _, t in pairs(nt) do
        local isBase = false
        for _, b in ipairs(baseIds) do if t == b then isBase = true; break end end
        if not isBase and t and t.IsPlaying then pcall(function() t:Stop(fade) end) end
    end
    flyanim.lateralKilled = true; flyanim.lateralLoopId = 0
    flyanim.atrasKilled   = true; flyanim.atrasLoopId   = 0
end

local function detenerEspacioAvanzado()
    if flyanim.espacioTrackActivo then
        pcall(function() flyanim.espacioTrackActivo:Stop(flyanim.ESPACIO_FADE_OUT) end)
        flyanim.espacioTrackActivo = nil
    end
    if flyanim.spaceHoldTimerAdv then
        task.cancel(flyanim.spaceHoldTimerAdv)
        flyanim.spaceHoldTimerAdv = nil
    end
end

local function setupBlockTrack()
    if not flyanim.animator then return end
    local animObj = Instance.new("Animation")
    animObj.AnimationId = ANIM.bloqueo
    local ok, t = pcall(function() return flyanim.animator:LoadAnimation(animObj) end)
    if not ok or not t then return end
    flyanim.blockTrack = t
    flyanim.blockTrack.Priority = Enum.AnimationPriority.Action4
    flyanim.blockTrack.Looped   = true
    pcall(function() flyanim.blockTrack:Play(0, 0, 0) end)
end

local function startBlocking()
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
        if flyanim.mode ~= "normal" then
            flyanim.isBlocking = false
            if flyanim.blockRenderConn then flyanim.blockRenderConn:Disconnect(); flyanim.blockRenderConn = nil end
            if flyanim.blockTrack and flyanim.blockTrack.IsPlaying then pcall(function() flyanim.blockTrack:Stop(0.1) end) end
            return
        end
        if state == "MOVING" then
            if bt.TimePosition >= length * ANIM_BLOQUEO.RESPIRO_PERC then
                state = "BREATHING"
                pcall(function() bt:AdjustSpeed(ANIM_BLOQUEO.VEL_LENTO) end)
            end
        elseif state == "BREATHING" then
            local t = os.clock()
            pcall(function() bt.TimePosition = length * (ANIM_BLOQUEO.OSCILA_MIN + (ANIM_BLOQUEO.OSCILA_RANGE * math.sin(t * 2))) end)
        end
    end)
end

local function setupDamageDetector()
    if flyanim.damageConn then flyanim.damageConn:Disconnect(); flyanim.damageConn = nil end
    local char = lplr.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    flyanim.damageConn = hum.HealthChanged:Connect(function(newHealth)
        local oldHealth = hum.Health
        if newHealth < oldHealth then
            flyanim.lastDamageTime = tick()
            if flyanim.isBlocking then
                flyanim.isBlocking = false
                if flyanim.blockRenderConn then
                    flyanim.blockRenderConn:Disconnect()
                    flyanim.blockRenderConn = nil
                end
                if flyanim.blockTrack then pcall(function() flyanim.blockTrack:Stop(0.1) end) end
            end
        end
    end)
end

local function stopBlocking()
    flyanim.isBlocking = false
    if flyanim.blockRenderConn then flyanim.blockRenderConn:Disconnect(); flyanim.blockRenderConn = nil end
    if flyanim.blockTrack then pcall(function() flyanim.blockTrack:Stop(0) end) end
end

local function obtenerPiernaS()
    local C = ANIM_NORMAL
    if flyanim.isADown then
        flyanim.contA += 1
        if flyanim.contA >= 5 then
            flyanim.piernaPrefA = (flyanim.piernaPrefA == C.OSCILA_LEFT) and C.OSCILA_RIGHT or C.OSCILA_LEFT
            flyanim.contA = 0
        end
        return flyanim.piernaPrefA
    elseif flyanim.isDDown then
        flyanim.contD += 1
        if flyanim.contD >= 5 then
            flyanim.piernaPrefD = (flyanim.piernaPrefD == C.OSCILA_RIGHT) and C.OSCILA_LEFT or C.OSCILA_RIGHT
            flyanim.contD = 0
        end
        return flyanim.piernaPrefD
    else
        flyanim.contS += 1
        if flyanim.contS >= 5 then
            flyanim.piernaPrefS = (flyanim.piernaPrefS == C.OSCILA_LEFT) and C.OSCILA_RIGHT or C.OSCILA_LEFT
            flyanim.contS = 0
        end
        return flyanim.piernaPrefS
    end
end

local function cancelarLateral()
    flyanim.currentLateralId += 1
    flyanim.lateralKilled = true
end

local function ejecutarLateral(inicio, thisId)
    local nt = flyanim.normalTracks
    if not nt.lateral then return end
    while nt.lateral.Length == 0 do task.wait() end
    if flyanim.currentLateralId ~= thisId then return end
    flyanim.lateralTarget = inicio
    flyanim.lateralKilled = false
    if flyanim.lateralLoopId ~= 0 then
        flyanim.lateralLoopId = thisId
        return
    end
    flyanim.lateralLoopId = thisId
    normPlaySafe(nt.lateral)
    nt.lateral:AdjustSpeed(0)
    nt.lateral.TimePosition = nt.lateral.Length * inicio
    nt.lateral:AdjustWeight(ANIM_NORMAL.PESO_LATERAL, ANIM_NORMAL.TRANSICION_FLUIDA)
    local currentPos = inicio
    while true do
        task.wait(0.05)
        if flyanim.lateralKilled then
            normStopSafe(nt.lateral)
            flyanim.lateralLoopId = 0
            flyanim.lateralKilled = false
            return
        end
        if flyanim.currentLateralId ~= flyanim.lateralLoopId then
            flyanim.lateralLoopId = flyanim.currentLateralId
        end
        local delta = flyanim.lateralTarget - currentPos
        if math.abs(delta) < ANIM_NORMAL.LATERAL_LERP_VEL then
            currentPos = flyanim.lateralTarget
        else
            currentPos = currentPos + (delta > 0 and ANIM_NORMAL.LATERAL_LERP_VEL or -ANIM_NORMAL.LATERAL_LERP_VEL)
        end
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
    flyanim.atrasLoopId       = flyanim.currentAtrasId
    flyanim.atrasCurrentSpeed = nuevaVelocidad
    local thisLoop = flyanim.atrasLoopId
    task.spawn(function()
        while nt.mov_back.Length == 0 do task.wait() end
        if flyanim.atrasLoopId ~= thisLoop then return end
        normPlaySafe(nt.mov_back)
        if nt.mov_brazos then normPlaySafe(nt.mov_brazos) end
        nt.mov_back:AdjustSpeed(0)
        nt.mov_back.TimePosition = nt.mov_back.Length * targetStartPercent
        local currentPos  = targetStartPercent
        local oscilaDir   = 1
        local oscilaTimer = 0
        while true do
            task.wait(0.05)
            if flyanim.atrasKilled then
                nt.mov_back:AdjustSpeed(1)
                normStopSafe(nt.mov_back)
                if nt.mov_brazos then normStopSafe(nt.mov_brazos) end
                flyanim.atrasLoopId = 0
                flyanim.atrasKilled = false
                return
            end
            if flyanim.currentAtrasId ~= flyanim.atrasLoopId then
                flyanim.atrasLoopId = flyanim.currentAtrasId
            end
            local vel   = flyanim.atrasCurrentSpeed
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
    local w, s, a, d = flyanim.isWDown, flyanim.isSDown, flyanim.isADown, flyanim.isDDown
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

local iniciarCicloNormal

local function evaluarMovimientoNormal()
    if not flyanim.enabled or flyanim.mode ~= "normal" then return end
    if flyanim.comboPlaying or flyanim.isBlocking then return end
    if flyanim.isSpaceAdv then return end
    if flyanim.turboPreImpulsoActivo then return end
    local nt = flyanim.normalTracks
    if not nt.mov_forward then
        if not flyanim.isWDown and not flyanim.isSDown and not flyanim.isADown and not flyanim.isDDown then
            playAnim(ANIM.idle, true)
        elseif flyanim.isDDown then playAnim(ANIM.right, true)
        elseif flyanim.isADown then playAnim(ANIM.left, true)
        elseif flyanim.isSDown then playAnim(ANIM.back, true)
        else playAnim(ANIM.forward, true) end
        return
    end
    local estado = resolverEstadoMovimiento()
    local C = ANIM_NORMAL

    local function matarAtras() flyanim.currentAtrasId += 1; flyanim.atrasKilled = true end
    local function relanzarAtras()
        local pierna  = obtenerPiernaS()
        local esRapido = esDiagonalS()
        flyanim.currentAtrasId += 1
        flyanim.atrasKilled = false
        ejecutarDashAtrasAnim(pierna, esRapido)
    end
    local function matarLateral() cancelarLateral() end
    local function relanzarLateral(destino)
        flyanim.currentLateralId += 1
        flyanim.lateralKilled = false
        local thisId = flyanim.currentLateralId
        task.spawn(function() ejecutarLateral(destino, thisId) end)
    end

    if estado == "W_SOLO" then
        matarAtras(); matarLateral()
        normPlaySafe(nt.mov_forward)
    elseif estado == "S_SOLO" then
        matarLateral()
        normStopSafe(nt.mov_forward)
        relanzarAtras()
    elseif estado == "W_A" then
        matarAtras()
        normPlaySafe(nt.mov_forward)
        nt.mov_forward:AdjustWeight(1.0, C.TRANSICION_FLUIDA)
        relanzarLateral(C.INICIO_A)
    elseif estado == "W_D" then
        matarAtras()
        normPlaySafe(nt.mov_forward)
        nt.mov_forward:AdjustWeight(1.0, C.TRANSICION_FLUIDA)
        relanzarLateral(C.INICIO_D)
    elseif estado == "S_A" then
        normStopSafe(nt.mov_forward)
        relanzarAtras(); relanzarLateral(C.INICIO_A)
    elseif estado == "S_D" then
        normStopSafe(nt.mov_forward)
        relanzarAtras(); relanzarLateral(C.INICIO_D)
    elseif estado == "A_SOLO" then
        matarAtras()
        normPlaySafe(nt.mov_forward)
        nt.mov_forward:AdjustWeight(1.0, C.TRANSICION_FLUIDA)
        relanzarLateral(C.INICIO_A)
    elseif estado == "D_SOLO" then
        matarAtras()
        normPlaySafe(nt.mov_forward)
        nt.mov_forward:AdjustWeight(1.0, C.TRANSICION_FLUIDA)
        relanzarLateral(C.INICIO_D)
    else
        matarAtras(); matarLateral()
        normStopSafe(nt.mov_forward)
        if nt.mov_brazos and nt.mov_brazos.IsPlaying then normStopSafe(nt.mov_brazos) end

        if flyanim.enabled and flyanim.mode == "normal" and not flyanim.comboPlaying then
            local nt2 = flyanim.normalTracks
            if nt2.estatica and not nt2.estatica.IsPlaying then
                nt2.estatica:Play(ANIM_NORMAL.TRANSICION_FLUIDA)
                task.spawn(function()
                    while nt2.estatica.Length == 0 do task.wait() end
                    task.wait(nt2.estatica.Length * ANIM_NORMAL.PARADA_ESTATICA)
                    if flyanim.enabled and flyanim.mode == "normal" then
                        nt2.estatica:AdjustSpeed(0)
                    end
                end)
            end
            if nt2.levitacion and not nt2.levitacion.IsPlaying then
                nt2.levitacion:Play(ANIM_NORMAL.TRANSICION_FLUIDA)
                nt2.levitacion:AdjustSpeed(ANIM_NORMAL.VELOCIDAD_LEVITACION)
            end

            if not flyanim.idleAnimConn then
                flyanim._normalPlayId = (flyanim._normalPlayId or 0) + 1
                iniciarCicloNormal(flyanim._normalPlayId)
            else
                flyanim.idleTimerAnim = 0
            end
        end
    end
end

local function evaluarMovimientoDebounced()
    flyanim.evalToken += 1
    local token = flyanim.evalToken
    task.delay(ANIM_NORMAL.DEBOUNCE_TECLADO, function()
        if flyanim.evalToken == token then evaluarMovimientoNormal() end
    end)
end

local function cambiarAEspacioSecundario()
    if not flyanim.enabled or flyanim.mode ~= "normal" then return end
    local nt = flyanim.normalTracks
    if not nt.espacio_sec then return end
    if nt.espacio_prim and nt.espacio_prim.IsPlaying then pcall(function() nt.espacio_prim:Stop(flyanim.ESPACIO_FADE_OUT) end) end
    detenerNormalExceptoBase(0.1)
    pcall(function() nt.espacio_sec:Play(0.1) end)
    pcall(function() nt.espacio_sec:AdjustSpeed(0) end)
    task.defer(function()
        if nt.espacio_sec and nt.espacio_sec.IsPlaying then
            pcall(function() nt.espacio_sec.TimePosition = nt.espacio_sec.Length * 0.5 end)
        end
    end)
    flyanim.espacioTrackActivo = nt.espacio_sec
end

local function manejarEspacioPresionadoNormal()
    if not flyanim.enabled or flyanim.mode ~= "normal" then return end
    if flyanim.comboPlaying then return end
    if flyanim.turboPreImpulsoActivo then return end
    flyanim.isSpaceAdv = true

    if flyanim.noclipSpaceEnabled then
        flyanim.noclipSpaceActive = true
        setNoclip(true)
    end

    local nt = flyanim.normalTracks
    if nt.mov_forward and nt.mov_forward.IsPlaying then pcall(function() nt.mov_forward:Stop(0.1) end) end
    if nt.mov_back    and nt.mov_back.IsPlaying    then pcall(function() nt.mov_back:Stop(0.1) end) end
    if nt.lateral     and nt.lateral.IsPlaying     then pcall(function() nt.lateral:Stop(0.1) end) end
    if nt.mov_brazos  and nt.mov_brazos.IsPlaying  then pcall(function() nt.mov_brazos:Stop(0.1) end) end
    -- Cerrar brazos inmediatamente al activar up: fade rápido (0.05s) y resetear timer
    if nt.brazos and nt.brazos.IsPlaying then pcall(function() nt.brazos:Stop(0.05) end) end
    flyanim.isBrazosActive = false
    flyanim.idleTimerAnim  = 0
    flyanim.currentAtrasId  = flyanim.currentAtrasId  + 1; flyanim.atrasKilled   = true
    flyanim.currentLateralId = flyanim.currentLateralId + 1; flyanim.lateralKilled = true

    detenerEspacioAvanzado()
    if not nt.espacio_prim then return end
    pcall(function() nt.espacio_prim:Play(0.1) end)
    flyanim.espacioTrackActivo = nt.espacio_prim

    if flyanim.spaceHoldTimerAdv then task.cancel(flyanim.spaceHoldTimerAdv) end
    flyanim.spaceHoldTimerAdv = task.delay(flyanim.ESPACIO_TIEMPO_CAMBIO, function()
        if flyanim.isSpaceAdv and flyanim.enabled and flyanim.mode == "normal" then
            cambiarAEspacioSecundario()
        end
        flyanim.spaceHoldTimerAdv = nil
    end)
end

local function manejarEspacioSoltadoNormal()
    flyanim.isSpaceAdv = false

    if flyanim.noclipSpaceActive then
        flyanim.noclipSpaceActive = false
        if flyanim.mode ~= "turbo" and not flyanim.noclipCtrlActive then
            setNoclip(false)
        end
    end

    if flyanim.spaceHoldTimerAdv then
        task.cancel(flyanim.spaceHoldTimerAdv)
        flyanim.spaceHoldTimerAdv = nil
    end
    detenerEspacioAvanzado()
    evaluarMovimientoDebounced()
end

iniciarCicloNormal = function(thisPlay)
    local nt = flyanim.normalTracks
    if not nt.estatica or not nt.levitacion then return end

    flyanim.c0ControlToken = (flyanim.c0ControlToken or 0) + 1
    detenerWatchdogAltura()
    restaurarC0Inmediato()

    if nt.estatica.IsPlaying then pcall(function() nt.estatica:Stop(0) end) end
    pcall(function() nt.estatica:Play(ANIM_NORMAL.TRANSICION_FLUIDA) end)
    if not nt.levitacion.IsPlaying then
        pcall(function() nt.levitacion:Play(ANIM_NORMAL.TRANSICION_FLUIDA) end)
    end
    pcall(function() nt.levitacion:AdjustSpeed(ANIM_NORMAL.VELOCIDAD_LEVITACION) end)
    actualizarPosicionNormal(ANIM_NORMAL.COMPENSACION_ALTURA)
    task.spawn(function()
        local to = tick() + 3
        while nt.estatica.Length == 0 and tick() < to do task.wait() end
        task.wait(nt.estatica.Length * ANIM_NORMAL.PARADA_ESTATICA)
        if flyanim.enabled and flyanim.mode == "normal" and thisPlay == flyanim._normalPlayId then
            pcall(function() nt.estatica:AdjustSpeed(0) end)
        end
    end)
    flyanim.idleTimerAnim  = 0
    flyanim.isBrazosActive = false
    if flyanim.idleAnimConn then flyanim.idleAnimConn:Disconnect() end

    flyanim.idleWatchToken = (flyanim.idleWatchToken or 0) + 1
    local myIdleToken = flyanim.idleWatchToken

    flyanim.idleAnimConn = RunService.Heartbeat:Connect(function(dt)
        if not flyanim.enabled or flyanim.mode ~= "normal" then
            if flyanim.idleAnimConn then flyanim.idleAnimConn:Disconnect(); flyanim.idleAnimConn = nil end
            return
        end
        if myIdleToken ~= flyanim.idleWatchToken then
            if flyanim.idleAnimConn then flyanim.idleAnimConn:Disconnect(); flyanim.idleAnimConn = nil end
            return
        end
        if flyanim.comboPlaying or flyanim.isBlocking then return end
        if nt.levitacion and not nt.levitacion.IsPlaying then
            pcall(function() nt.levitacion:Play(0.2) end)
            pcall(function() nt.levitacion:AdjustSpeed(ANIM_NORMAL.VELOCIDAD_LEVITACION) end)
        end
        if nt.estatica and not nt.estatica.IsPlaying and not flyanim.isWDown
            and not flyanim.isSDown and not flyanim.isADown and not flyanim.isDDown
            and not flyanim.isSpaceAdv and not flyanim.comboPlaying then
            pcall(function() nt.estatica:Play(ANIM_NORMAL.TRANSICION_FLUIDA) end)
            task.spawn(function()
                local to = tick() + 3
                while nt.estatica.Length == 0 and tick() < to do task.wait() end
                task.wait(nt.estatica.Length * ANIM_NORMAL.PARADA_ESTATICA)
                if flyanim.enabled and flyanim.mode == "normal" and myIdleToken == flyanim.idleWatchToken then
                    pcall(function() nt.estatica:AdjustSpeed(0) end)
                end
            end)
        end
        -- Spacio (up) y MegaTurboUp cuentan como movimiento: el timer de brazos
        -- se detiene y si los brazos ya están abiertos se cierran inmediatamente.
        local isMovingAdv = flyanim.isWDown or flyanim.isSDown or flyanim.isADown or flyanim.isDDown
            or flyanim.isSpaceAdv or flyanim.megaTurboUpActive
        if not isMovingAdv then
            flyanim.idleTimerAnim += dt
            if flyanim.idleTimerAnim >= ANIM_NORMAL.TIEMPO_QUIETO and not flyanim.isBrazosActive then
                flyanim.isBrazosActive = true
                if nt.brazos then pcall(function() nt.brazos:Play(ANIM_NORMAL.TIEMPO_TRANSICION) end) end
            end
        else
            flyanim.idleTimerAnim = 0
            if flyanim.isBrazosActive then
                flyanim.isBrazosActive = false
                -- Fade rápido al cerrar por up/megaup para que no se vea el brazo a medias
                local fadeBrazos = (flyanim.isSpaceAdv or flyanim.megaTurboUpActive) and 0.05 or ANIM_NORMAL.TIEMPO_TRANSICION
                if nt.brazos then pcall(function() nt.brazos:Stop(fadeBrazos) end) end
            end
        end
    end)
end

-- ============================================================
-- POSE TURBO (25 grados)
-- ============================================================

local function iniciarPoseTurbo()
    flyanim.turboPreImpulsoActivo = true
    flyanim.turboPreImpulsoToken  = (flyanim.turboPreImpulsoToken or 0) + 1
    local myToken = flyanim.turboPreImpulsoToken

    flyanim.idleWatchToken = (flyanim.idleWatchToken or 0) + 1
    if flyanim.idleAnimConn then flyanim.idleAnimConn:Disconnect(); flyanim.idleAnimConn = nil end

    detenerNormalTracks(0.1)
    detenerWatchdogAltura()

    if flyanim.turboRenderConn then flyanim.turboRenderConn:Disconnect(); flyanim.turboRenderConn = nil end

    local char = lplr and lplr.Character
    if not char then flyanim.turboPreImpulsoActivo = false; return end
    local rootJoint  = flyanim.rootJoint
    local originalC0 = flyanim.originalC0
    if not rootJoint or not originalC0 then flyanim.turboPreImpulsoActivo = false; return end
    local nt = flyanim.normalTracks
    if not nt.turbo_pose or not nt.turbo_volado then flyanim.turboPreImpulsoActivo = false; return end

    for _, t in pairs(flyanim.tracks) do pcall(function() if t and t.IsPlaying then t:Stop(0.05) end end) end

    flyanim.turboTransitioning = true
    flyanim.c0ControlToken = (flyanim.c0ControlToken or 0) + 1
    local myC0Token = flyanim.c0ControlToken

    local preImpulsoBlockConn
    preImpulsoBlockConn = RunService.RenderStepped:Connect(function()
        if not flyanim.turboPreImpulsoActivo or flyanim.turboPreImpulsoToken ~= myToken then
            preImpulsoBlockConn:Disconnect()
            return
        end
        if flyanim.animator then
            local ok, tracks = pcall(function() return flyanim.animator:GetPlayingAnimationTracks() end)
            if ok and tracks then
                for _, t in ipairs(tracks) do
                    local animId = t.Animation and t.Animation.AnimationId or ""
                    local isTurboAnim = (animId == ANIM.turbo_compact or animId == ANIM.turbo_burst
                        or animId == ANIM.turbo_pose or animId == ANIM.turbo_volado)
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
            flyanim.turboPreImpulsoActivo = false
            flyanim.turboTransitioning = false
            flyanim.c0ControlToken = (flyanim.c0ControlToken or 0) + 1
            detenerWatchdogAltura()
            restaurarC0Inmediato()
            if nt.turbo_compact then pcall(function() nt.turbo_compact:Stop(0.05) end) end
            if nt.turbo_burst   then pcall(function() nt.turbo_burst:Stop(0.05) end) end
            if nt.turbo_pose    then pcall(function() nt.turbo_pose:Stop(0.05) end) end
            if nt.turbo_volado  then pcall(function() nt.turbo_volado:Stop(0.05) end) end
            for _, t in pairs(flyanim.tracks) do pcall(function() if t and t.IsPlaying then t:Stop(0.05) end end) end
            for _, t in pairs(flyanim.normalTracks) do pcall(function() if t and t.IsPlaying then t:Stop(0.05) end end) end
            if flyanim.mode == "fast" then
                flyanim.mode  = "normal"
                flyanim.speed = BASE_SPEED
                if flyanim.updateMode then flyanim.updateMode("normal") end
            end
            setNoclip(false)
            pcall(function() stopParticleEmitter() end)
            task.wait(0.05)
            if flyanim.enabled and flyanim.mode == "normal" then
                flyanim.idleWatchToken = (flyanim.idleWatchToken or 0) + 1
                if flyanim.idleAnimConn then flyanim.idleAnimConn:Disconnect(); flyanim.idleAnimConn = nil end
                flyanim._normalPlayId = (flyanim._normalPlayId or 0) + 1
                iniciarCicloNormal(flyanim._normalPlayId)
                task.delay(0.1, function()
                    if flyanim.enabled and flyanim.mode == "normal" then evaluarMovimientoNormal() end
                end)
            end
        end

        -- FASE 1: encogerse
        if nt.turbo_compact then
            nt.turbo_compact.Looped = false
            pcall(function() nt.turbo_compact:Play(0.05) end)
            pcall(function() nt.turbo_compact:AdjustSpeed(3.0) end)
        end
        local startT = tick()
        while tick() - startT < ANIM_TURBO.TIEMPO_CONTRAERSE do
            if debeAbortarPreImpulso() then
                if nt.turbo_compact then pcall(function() nt.turbo_compact:Stop(0.1) end) end
                abortarYVolver(); return
            end
            local t = (tick() - startT) / ANIM_TURBO.TIEMPO_CONTRAERSE
            if myC0Token == flyanim.c0ControlToken then
                pcall(function()
                    rootJoint.C0 = originalC0 * CFrame.Angles(math.rad(t * ANIM_TURBO.INCLINACION_DESPEGUE), 0, 0)
                end)
            end
            task.wait()
        end

        if debeAbortarPreImpulso() then
            if nt.turbo_compact then pcall(function() nt.turbo_compact:Stop(0.1) end) end
            abortarYVolver(); return
        end

        if myC0Token == flyanim.c0ControlToken then
            pcall(function() rootJoint.C0 = originalC0 * CFrame.Angles(math.rad(ANIM_TURBO.INCLINACION_DESPEGUE), 0, 0) end)
        end
        if nt.turbo_compact then pcall(function() nt.turbo_compact:AdjustSpeed(0) end) end
        task.wait(ANIM_TURBO.TIEMPO_PAUSA)

        if debeAbortarPreImpulso() then
            if nt.turbo_compact then pcall(function() nt.turbo_compact:Stop(0.1) end) end
            abortarYVolver(); return
        end

        -- FASE 2: explosion burst
        if nt.turbo_compact then pcall(function() nt.turbo_compact:Stop(0.05) end) end
        if nt.turbo_burst then
            nt.turbo_burst.Looped = false
            pcall(function() nt.turbo_burst:Play(0.05) end)
            pcall(function() nt.turbo_burst:AdjustSpeed(2.5) end)
        end
        task.wait(0.2)

        if debeAbortarPreImpulso() then
            if nt.turbo_burst then pcall(function() nt.turbo_burst:Stop(0.1) end) end
            abortarYVolver(); return
        end

        -- FASE 3: transicion a pose de vuelo (25 grados para turbo)
        if nt.turbo_pose  then nt.turbo_pose.Looped  = true; pcall(function() nt.turbo_pose:Play(0.2) end) end
        if nt.turbo_volado then nt.turbo_volado.Looped = true; pcall(function() nt.turbo_volado:Play(0.2) end) end
        if nt.turbo_burst  then pcall(function() nt.turbo_burst:Stop(0.4) end) end

        -- 25 grados para turbo
        local cframeDespegue = originalC0 * CFrame.Angles(math.rad(ANIM_TURBO.INCLINACION_DESPEGUE), 0, 0)
        local cframeVuelo    = originalC0
            * CFrame.new(0, ANIM_TURBO.COMPENSACION_ALTURA, 0)
            * CFrame.Angles(math.rad(ANIM_TURBO.INCLINACION_GRADOS), 0, 0)

        startT = tick()
        while tick() - startT < ANIM_TURBO.TIEMPO_TRANSICION do
            if debeAbortarPreImpulso() then
                if nt.turbo_pose   then pcall(function() nt.turbo_pose:Stop(0.2) end) end
                if nt.turbo_volado then pcall(function() nt.turbo_volado:Stop(0.2) end) end
                abortarYVolver(); return
            end
            local t = (tick() - startT) / ANIM_TURBO.TIEMPO_TRANSICION
            if myC0Token == flyanim.c0ControlToken then
                pcall(function() rootJoint.C0 = cframeDespegue:Lerp(cframeVuelo, t) end)
            end
            if nt.turbo_pose and nt.turbo_pose.IsPlaying then
                pcall(function()
                    nt.turbo_pose.TimePosition = ANIM_TURBO.FRAME_CONGELADO
                    nt.turbo_pose:AdjustSpeed(0)
                end)
            end
            if nt.turbo_volado and nt.turbo_volado.IsPlaying then
                pcall(function()
                    nt.turbo_volado.TimePosition = ANIM_TURBO.FRAME_VOLADO_CONGELADO
                    nt.turbo_volado:AdjustSpeed(0)
                end)
            end
            task.wait()
        end
        if not flyanim.enabled then
            flyanim.turboTransitioning = false
            flyanim.turboPreImpulsoActivo = false
            pcall(function() preImpulsoBlockConn:Disconnect() end)
            flyanim.c0ControlToken = (flyanim.c0ControlToken or 0) + 1
            detenerWatchdogAltura()
            restaurarC0Inmediato()
            return
        end

        pcall(function() preImpulsoBlockConn:Disconnect() end)
        flyanim.turboPreImpulsoActivo = false
        if flyanim.turboRenderConn then flyanim.turboRenderConn:Disconnect() end

        -- Loop de vuelo turbo (25 grados) con watchdog de altura
        local myC0TkLoop = flyanim.c0ControlToken

        -- CFrame de referencia para el watchdog
        local cframeVueloRef = originalC0
            * CFrame.new(0, ANIM_TURBO.COMPENSACION_ALTURA, 0)
            * CFrame.Angles(math.rad(ANIM_TURBO.INCLINACION_GRADOS), 0, 0)

        flyanim.turboRenderConn = RunService.RenderStepped:Connect(function()
            if not flyanim.enabled or flyanim.mode ~= "fast" then
                if flyanim.turboRenderConn then flyanim.turboRenderConn:Disconnect(); flyanim.turboRenderConn = nil end
                if myC0TkLoop == flyanim.c0ControlToken then
                    detenerWatchdogAltura()
                    restaurarC0Inmediato()
                end
                return
            end
            if myC0TkLoop ~= flyanim.c0ControlToken then return end

            if nt.turbo_pose and nt.turbo_pose.IsPlaying then
                pcall(function()
                    nt.turbo_pose:AdjustSpeed(0)
                    nt.turbo_pose.TimePosition = ANIM_TURBO.FRAME_CONGELADO
                end)
            elseif nt.turbo_pose and not nt.turbo_pose.IsPlaying then
                nt.turbo_pose.Looped = true
                pcall(function() nt.turbo_pose:Play(0.1); nt.turbo_pose:AdjustSpeed(0) end)
            end
            if nt.turbo_volado and nt.turbo_volado.IsPlaying then
                pcall(function()
                    nt.turbo_volado:AdjustSpeed(0)
                    nt.turbo_volado.TimePosition = ANIM_TURBO.FRAME_VOLADO_CONGELADO
                end)
            elseif nt.turbo_volado and not nt.turbo_volado.IsPlaying then
                nt.turbo_volado.Looped = true
                pcall(function() nt.turbo_volado:Play(0.1); nt.turbo_volado:AdjustSpeed(0) end)
            end
            -- levitacion sinusoidal suave con 25 grados
            local movimientoY = math.sin(tick() * ANIM_TURBO.FRECUENCIA_LEVITACION) * ANIM_TURBO.AMPLITUD_LEVITACION
            local targetCF = originalC0
                * CFrame.new(0, ANIM_TURBO.COMPENSACION_ALTURA + movimientoY, 0)
                * CFrame.Angles(math.rad(ANIM_TURBO.INCLINACION_GRADOS), 0, 0)
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

            flyanim.idleTimerAnim  = 0
            flyanim.isBrazosActive = false

            local ntl = flyanim.normalTracks
            if ntl.levitacion and not ntl.levitacion.IsPlaying then
                pcall(function() ntl.levitacion:Play(ANIM_NORMAL.TRANSICION_FLUIDA) end)
                pcall(function() ntl.levitacion:AdjustSpeed(ANIM_NORMAL.VELOCIDAD_LEVITACION) end)
            end

            flyanim.idleAnimConn = RunService.Heartbeat:Connect(function(dt)
                if not flyanim.enabled or flyanim.mode ~= "fast" then
                    if flyanim.idleAnimConn then flyanim.idleAnimConn:Disconnect(); flyanim.idleAnimConn = nil end
                    return
                end
                if myIdleToken ~= flyanim.idleWatchToken then
                    if flyanim.idleAnimConn then flyanim.idleAnimConn:Disconnect(); flyanim.idleAnimConn = nil end
                    return
                end
                if flyanim.turboPreImpulsoActivo then return end
                if flyanim.comboPlaying or flyanim.isBlocking then return end
                if ntl.levitacion and not ntl.levitacion.IsPlaying then
                    pcall(function() ntl.levitacion:Play(0.2) end)
                    pcall(function() ntl.levitacion:AdjustSpeed(ANIM_NORMAL.VELOCIDAD_LEVITACION) end)
                end
                local isMovingAdv = flyanim.isWDown or flyanim.isSDown or flyanim.isADown or flyanim.isDDown
                    or flyanim.megaTurboUpActive
                if not isMovingAdv then
                    flyanim.idleTimerAnim += dt
                    if flyanim.idleTimerAnim >= ANIM_NORMAL.TIEMPO_QUIETO and not flyanim.isBrazosActive then
                        flyanim.isBrazosActive = true
                        if ntl.brazos then pcall(function() ntl.brazos:Play(ANIM_NORMAL.TIEMPO_TRANSICION) end) end
                    end
                else
                    flyanim.idleTimerAnim = 0
                    if flyanim.isBrazosActive then
                        flyanim.isBrazosActive = false
                        -- Fade rápido al activarse megaTurboUp
                        local fadeBrazos = flyanim.megaTurboUpActive and 0.05 or ANIM_NORMAL.TIEMPO_TRANSICION
                        if ntl.brazos then pcall(function() ntl.brazos:Stop(fadeBrazos) end) end
                    end
                end
            end)
        end)
    end)
end

local function detenerPoseTurbo()
    flyanim.turboPreImpulsoActivo = false
    flyanim.turboPreImpulsoToken  = (flyanim.turboPreImpulsoToken or 0) + 1
    if flyanim.turboRenderConn then flyanim.turboRenderConn:Disconnect(); flyanim.turboRenderConn = nil end
    local nt = flyanim.normalTracks
    if nt.turbo_pose   then pcall(function() nt.turbo_pose:Stop(0.3) end) end
    if nt.turbo_volado then pcall(function() nt.turbo_volado:Stop(0.3) end) end
    if nt.turbo_burst  then pcall(function() nt.turbo_burst:Stop(0.1) end) end
    if nt.turbo_compact then pcall(function() nt.turbo_compact:Stop(0.1) end) end
    flyanim.c0ControlToken = (flyanim.c0ControlToken or 0) + 1
    detenerWatchdogAltura()
    restaurarC0Inmediato()
end

-- ============================================================
-- POSE MEGA (45 grados, sin cambios)
-- ============================================================

local function iniciarPoseMega()
    detenerNormalTracks(0.1)
    detenerPoseTurbo()
    detenerWatchdogAltura()
    if flyanim.megaRenderConn then flyanim.megaRenderConn:Disconnect(); flyanim.megaRenderConn = nil end
    local rootJoint  = flyanim.rootJoint
    local originalC0 = flyanim.originalC0
    if not rootJoint or not originalC0 then return end
    local nt = flyanim.normalTracks
    if not nt.mega_pose then return end
    if nt.mega_pose   then nt.mega_pose.Looped  = true; pcall(function() nt.mega_pose:Play(0.2); nt.mega_pose:AdjustSpeed(0.1) end) end
    if nt.mega_base   then nt.mega_base.Looped   = true; pcall(function() nt.mega_base:Play(0.2); nt.mega_base:AdjustSpeed(0.1) end) end
    if nt.mega_volado then nt.mega_volado.Looped = true; pcall(function() nt.mega_volado:Play(0.2) end) end

    flyanim.c0ControlToken = (flyanim.c0ControlToken or 0) + 1
    local myC0Token = flyanim.c0ControlToken

    flyanim.megaRenderConn = RunService.RenderStepped:Connect(function()
        if not flyanim.enabled or flyanim.mode ~= "turbo" then
            if flyanim.megaRenderConn then flyanim.megaRenderConn:Disconnect(); flyanim.megaRenderConn = nil end
            if myC0Token == flyanim.c0ControlToken then
                detenerWatchdogAltura()
                restaurarC0Inmediato()
            end
            return
        end
        if myC0Token ~= flyanim.c0ControlToken then return end
        if nt.mega_volado and nt.mega_volado.IsPlaying then
            pcall(function()
                nt.mega_volado:AdjustSpeed(0)
                nt.mega_volado.TimePosition = ANIM_MEGA.FRAME_VOLADO_CONGELADO
            end)
        elseif nt.mega_volado and not nt.mega_volado.IsPlaying then
            nt.mega_volado.Looped = true
            pcall(function() nt.mega_volado:Play(0.1); nt.mega_volado:AdjustSpeed(0) end)
        end
        -- 45 grados para mega (sin cambios)
        local movimientoY = math.sin(tick() * ANIM_MEGA.FRECUENCIA_LEVITACION) * ANIM_MEGA.AMPLITUD_LEVITACION
        pcall(function()
            rootJoint.C0 = originalC0
                * CFrame.new(0, ANIM_MEGA.COMPENSACION_ALTURA + movimientoY, 0)
                * CFrame.Angles(math.rad(ANIM_MEGA.INCLINACION_GRADOS), 0, 0)
        end)
    end)
end

local function detenerPoseMega()
    if flyanim.megaRenderConn then flyanim.megaRenderConn:Disconnect(); flyanim.megaRenderConn = nil end
    local nt = flyanim.normalTracks
    if nt.mega_pose   then pcall(function() nt.mega_pose:Stop(0.3) end) end
    if nt.mega_base   then pcall(function() nt.mega_base:Stop(0.3) end) end
    if nt.mega_volado then pcall(function() nt.mega_volado:Stop(0.3) end) end
    flyanim.c0ControlToken = (flyanim.c0ControlToken or 0) + 1
    detenerWatchdogAltura()
    restaurarC0Inmediato()
end

-- ============================================================
-- MOVIMIENTO
-- ============================================================

local function getMovDir()
    local w = flyanim.wDown; local s = flyanim.sDown
    local a = flyanim.aDown; local d = flyanim.dDown
    if a and d then return "none" end
    if d and not a then return "right" end
    if a and not d then return "left" end
    if not w and not s then return "none" end
    if w and not s then return "forward" end
    if s and not w then return "back" end
    return "none"
end

local function updateAnimForMovement()
    if flyanim.turboPreImpulsoActivo then return end
    local dir    = getMovDir()
    local moving = dir ~= "none"
    local mode   = flyanim.mode
    flyanim.isMoving = moving
    if flyanim.comboPlaying then return end
    if flyanim.isBlocking   then return end

    if mode == "normal" then
        local nt = flyanim.normalTracks
        if not nt.mov_forward then
            if not moving then playAnim(ANIM.idle, true)
            elseif dir == "right" then playAnim(ANIM.right, true)
            elseif dir == "left"  then playAnim(ANIM.left, true)
            elseif dir == "back"  then playAnim(ANIM.back, true)
            else playAnim(ANIM.forward, true) end
        end
    elseif mode == "fast" then
        -- No tocar animaciones durante pre-impulso turbo
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

-- ============================================================
-- ANTI IMPULSO
-- ============================================================

local function startAntiImpulse()
    if flyanim.antiImpulseConn then flyanim.antiImpulseConn:Disconnect(); flyanim.antiImpulseConn = nil end
    local mySession = flyanim.sessionToken
    flyanim.antiImpulseConn = RunService.Stepped:Connect(function()
        if flyanim.sessionToken ~= mySession then
            if flyanim.antiImpulseConn then flyanim.antiImpulseConn:Disconnect(); flyanim.antiImpulseConn = nil end
            return
        end
        if not flyanim.enabled then
            if flyanim.antiImpulseConn then flyanim.antiImpulseConn:Disconnect(); flyanim.antiImpulseConn = nil end
            return
        end
        local char = lplr.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then return end

        local bv = flyanim.bv
        if not bv or not bv.Parent then return end
        local expectedVel = bv.velocity
        local actualVel   = root.AssemblyLinearVelocity
        local diff = (actualVel - expectedVel).Magnitude
        if diff > 3 then root.AssemblyLinearVelocity = expectedVel end
        local bg = flyanim.bg
        if bg then
            local targetAngular  = Vector3.new(0,0,0)
            local currentAngular = root.AssemblyAngularVelocity
            if (currentAngular - targetAngular).Magnitude > 5 then
                root.AssemblyAngularVelocity = targetAngular
            end
        end
    end)
end

local function stopAntiImpulse()
    if flyanim.antiImpulseConn then flyanim.antiImpulseConn:Disconnect(); flyanim.antiImpulseConn = nil end
end

local function activateGyroProtection()
    if flyanim.gyroProtectionActive then return end
    if not flyanim.bg then return end
    flyanim.gyroProtectionActive  = true
    flyanim.originalGyroP         = flyanim.bg.P
    flyanim.originalGyroMaxTorque = flyanim.bg.maxTorque
    flyanim.bg.P         = 2000
    flyanim.bg.maxTorque = Vector3.new(2000,2000,2000)
    if flyanim.backupGyro then flyanim.backupGyro:Destroy() end
    flyanim.backupGyro = Instance.new("BodyGyro", flyanim.bg.Parent)
    flyanim.backupGyro.P         = 1000
    flyanim.backupGyro.maxTorque = Vector3.new(1000,1000,1000)
    flyanim.backupGyro.cframe    = flyanim.bg.cframe
    if flyanim.gyroProtectionTimer then task.cancel(flyanim.gyroProtectionTimer) end
    flyanim.gyroProtectionTimer = task.delay(0.5, function()
        if flyanim.enabled and flyanim.bg then
            flyanim.bg.P         = flyanim.originalGyroP or 9e4
            flyanim.bg.maxTorque = flyanim.originalGyroMaxTorque or Vector3.new(9e9,9e9,9e9)
        end
        if flyanim.backupGyro then flyanim.backupGyro:Destroy(); flyanim.backupGyro = nil end
        flyanim.gyroProtectionActive = false
        flyanim.gyroProtectionTimer  = nil
    end)
end

local ANOMALY_SPEED_THRESHOLD  = 300
local ANOMALY_TELEPORT_STUDS   = 40
local ANOMALY_COOLDOWN         = 0.12

local lastAnomalyFix    = 0
local lastMotorReset    = 0
local MOTOR_RESET_COOLDOWN = 0.5   -- no más de un reset cada 0.5s

-- ── Silent motor reset (fake fly-off / fly-on invisible) ──────────────────
-- Se activa cuando el juego "suelta" la hitbox sin que el jugador lo pida:
-- destruye y recrea los body movers en el mismo frame, restaurando el estado
-- de Physics sin que el jugador note ningún parpadeo ni interrupción.
local function silentMotorReset()
    local now = tick()
    if now - lastMotorReset < MOTOR_RESET_COOLDOWN then return end
    lastMotorReset = now

    local char = lplr.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end

    -- Capturar posición y orientación actuales para no perder contexto
    local currentCF = root.CFrame

    -- Destruir motores viejos y recrear en un único pcall atómico
    pcall(function()
        -- Limpiar motores corruptos/ausentes
        for _, v in ipairs(root:GetChildren()) do
            if v:IsA("BodyGyro") or v:IsA("BodyVelocity") or v:IsA("BodyForce")
            or v:IsA("BodyAngularVelocity") or v:IsA("AlignOrientation") or v:IsA("LinearVelocity") then
                v:Destroy()
            end
        end
        root.AssemblyLinearVelocity  = Vector3.new(0, 0, 0)
        root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)

        -- Recrear motores
        local bg = Instance.new("BodyGyro", root)
        bg.P = 9e4; bg.maxTorque = Vector3.new(9e9,9e9,9e9); bg.cframe = currentCF
        local bv = Instance.new("BodyVelocity", root)
        bv.velocity = Vector3.new(0,0,0); bv.maxForce = Vector3.new(9e9,9e9,9e9)
        local bf = Instance.new("BodyForce", root)
        local totalMass = root.AssemblyMass
        bf.Force = Vector3.new(0, totalMass * workspace.Gravity, 0)

        flyanim.bg = bg
        flyanim.bv = bv
        flyanim.bf = bf

        -- Forzar estado de física sin animación de levantarse
        hum.PlatformStand = true
        hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
        hum:ChangeState(Enum.HumanoidStateType.Physics)
    end)
end

local function _flyMakeMotors()
    local char = lplr.Character; if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum  = char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end
    cleanupMotors(root)
    flyanim.bg = Instance.new("BodyGyro", root)
    flyanim.bg.P = 9e4; flyanim.bg.maxTorque = Vector3.new(9e9,9e9,9e9); flyanim.bg.cframe = root.CFrame
    flyanim.bv = Instance.new("BodyVelocity", root)
    flyanim.bv.velocity = Vector3.new(0,0,0); flyanim.bv.maxForce = Vector3.new(9e9,9e9,9e9)
    flyanim.bf = Instance.new("BodyForce", root)
    flyanim.bf.Force = Vector3.new(0, root.AssemblyMass * workspace.Gravity, 0)
    hum.PlatformStand = true
    hum:ChangeState(Enum.HumanoidStateType.Physics)
end

local function startAnomalyProtection()
    if flyanim.anomalyConn then flyanim.anomalyConn:Disconnect(); flyanim.anomalyConn = nil end
    flyanim.lastKnownPos = nil
    local mySession = flyanim.sessionToken
    flyanim.anomalyConn = RunService.Stepped:Connect(function(_, dt)
        if flyanim.sessionToken ~= mySession then
            if flyanim.anomalyConn then flyanim.anomalyConn:Disconnect(); flyanim.anomalyConn = nil end
            flyanim.lastKnownPos = nil
            return
        end
        if not flyanim.enabled then
            if flyanim.anomalyConn then flyanim.anomalyConn:Disconnect(); flyanim.anomalyConn = nil end
            flyanim.lastKnownPos = nil
            return
        end
        local char = lplr.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then flyanim.lastKnownPos = nil; return end

        local now = tick()
        local hum = char:FindFirstChildOfClass("Humanoid")
        local pos = root.Position

        -- Actualizar posición conocida
        flyanim.lastKnownPos = pos

        if not hum then return end
        local state = hum:GetState()

        -- ── Detección de hitbox caída ─────────────────────────────────────────
        -- Mientras volamos, el estado DEBE ser Physics. Si detectamos Freefall,
        -- GettingUp, FallingDown o Ragdoll sin que nosotros lo hayamos pedido,
        -- es señal de que el juego "soltó" la hitbox. Hacemos un reset silencioso.
        local isHitboxDrop = (
            state == Enum.HumanoidStateType.Freefall     or
            state == Enum.HumanoidStateType.FallingDown  or
            state == Enum.HumanoidStateType.Ragdoll      or
            state == Enum.HumanoidStateType.GettingUp
        )

        -- También detectar si los motores desaparecieron (el juego los puede destruir)
        local motorsGone = (
            not root:FindFirstChildOfClass("BodyGyro") or
            not root:FindFirstChildOfClass("BodyVelocity")
        )

        if (isHitboxDrop or motorsGone) and now - lastAnomalyFix > ANOMALY_COOLDOWN then
            lastAnomalyFix = now
            flyanim.ragdollDetected = (state == Enum.HumanoidStateType.Ragdoll)

            -- Reset silencioso: recrea los motores sin que el jugador lo note
            silentMotorReset()

            task.defer(function()
                if not flyanim.enabled then return end
                flyanim.ragdollDetected = false
            end)
        end
    end)
end

local function stopAnomalyProtection()
    if flyanim.anomalyConn then flyanim.anomalyConn:Disconnect(); flyanim.anomalyConn = nil end
    flyanim.lastKnownPos = nil
end

local function fixUndergroundOrientation()
    local char = lplr.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root or not flyanim.bg then return end
    local upVec = root.CFrame.UpVector
    if upVec.Y < 0.3 then
        local lookVec = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
        if lookVec.Magnitude < 0.01 then lookVec = Vector3.new(0,0,-1) end
        local correctedCF = CFrame.lookAt(root.Position, root.Position + lookVec.Unit)
        pcall(function()
            root.CFrame = correctedCF
            root.AssemblyAngularVelocity = Vector3.new(0,0,0)
            if flyanim.bg then flyanim.bg.cframe = correctedCF end
        end)
    end
end

local function startAnimBlockLoop()
    if flyanim.animBlockRenderConn then flyanim.animBlockRenderConn:Disconnect(); flyanim.animBlockRenderConn = nil end
    if not flyanim.animator then return end

    local ownAnimIds = {}
    for _, id in pairs(ANIM) do ownAnimIds[id] = true end
    ownAnimIds[CAIDA_BASE_ID]    = true
    ownAnimIds[CAIDA_OVERLAY_ID] = true

    local mySession = flyanim.sessionToken
    flyanim.animBlockRenderConn = RunService.RenderStepped:Connect(function()
        if flyanim.sessionToken ~= mySession then
            if flyanim.animBlockRenderConn then flyanim.animBlockRenderConn:Disconnect(); flyanim.animBlockRenderConn = nil end
            return
        end
        if not flyanim.enabled then
            if flyanim.animBlockRenderConn then flyanim.animBlockRenderConn:Disconnect(); flyanim.animBlockRenderConn = nil end
            return
        end
        local anim = flyanim.animator
        if not anim then return end
        pcall(function()
            local tracks = anim:GetPlayingAnimationTracks()
            if not tracks then return end
            for _, t in ipairs(tracks) do
                if t and t.Animation then
                    local id = t.Animation.AnimationId
                    if not ownAnimIds[id] then pcall(function() t:Stop(0) end) end
                end
            end
        end)
    end)
end

local function stopAnimBlockLoop()
    if flyanim.animBlockRenderConn then flyanim.animBlockRenderConn:Disconnect(); flyanim.animBlockRenderConn = nil end
end

local activeHitboxMarkers = {}
local function clearHitboxMarkers()
    for _, marker in ipairs(activeHitboxMarkers) do pcall(function() marker:Destroy() end) end
    activeHitboxMarkers = {}
end

local function showHitboxMarkers(targetChar)
    clearHitboxMarkers()
    if not targetChar then return end
    local box = Instance.new("SelectionBox")
    box.Adornee       = targetChar
    box.Color3        = Color3.fromRGB(255, 150, 50)
    box.Transparency  = 0.5
    box.LineThickness = 0.1
    box.Parent        = targetChar
    table.insert(activeHitboxMarkers, box)
    task.delay(0.6, clearHitboxMarkers)
end

-- ============================================================
-- BRAKE SYSTEM
-- ============================================================

local brakeConn = nil
local function startBrakeSystem()
    if brakeConn then brakeConn:Disconnect(); brakeConn = nil end
    brakeConn = RunService.RenderStepped:Connect(function()
        if not flyanim.enabled then return end
        if flyanim.mode ~= "fast" and flyanim.mode ~= "turbo" then return end
        if not flyanim.lockActive or not flyanim.lockedTarget then return end
        if flyanim.dashTimer <= 0 then return end
        local char   = lplr.Character
        local myRoot = char and char:FindFirstChild("HumanoidRootPart")
        if not myRoot then return end
        local targetChar = flyanim.lockedTarget.Character
        local targetRoot = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
        if not targetRoot then return end
        local dist = (myRoot.Position - targetRoot.Position).Magnitude
        if dist <= flyanim.BRAKE_HARD_DISTANCE then
            flyanim.dashVel   = Vector3.new(0,0,0)
            flyanim.dashTimer = 0
            flyanim.brakingActive = false
            showHitboxMarkers(targetChar)
        elseif dist <= flyanim.BRAKE_DISTANCE then
            local t = 1 - ((dist - flyanim.BRAKE_HARD_DISTANCE) / (flyanim.BRAKE_DISTANCE - flyanim.BRAKE_HARD_DISTANCE))
            local brakeFactor = 1 - (t * 0.92)
            flyanim.dashVel   = flyanim.dashVel * math.max(brakeFactor, 0.05)
            flyanim.brakingActive = true
        else
            flyanim.brakingActive = false
        end
    end)
end

local function stopBrakeSystem()
    if brakeConn then brakeConn:Disconnect(); brakeConn = nil end
    flyanim.brakingActive = false
end

local dashConnection = nil
local HIT_COOLDOWN   = 0.5

local function startDashCollisionDetection()
    if dashConnection then dashConnection:Disconnect() end
    local char = lplr.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local hitPlayers = {}
    dashConnection = RunService.RenderStepped:Connect(function()
        if flyanim.dashTimer <= 0 then
            if dashConnection then dashConnection:Disconnect(); dashConnection = nil end
            return
        end
        local currentChar = lplr.Character
        local currentRoot = currentChar and currentChar:FindFirstChild("HumanoidRootPart")
        if not currentRoot then return end
        local rootPos       = currentRoot.Position
        local dashMagnitude = flyanim.dashVel.Magnitude
        local currentDashDir = dashMagnitude > 0.01 and flyanim.dashVel.Unit or Vector3.new(0,0,1)
        for _, otherPlayer in ipairs(Players:GetPlayers()) do
            if otherPlayer ~= lplr then
                local otherChar = otherPlayer.Character
                if otherChar then
                    local otherRoot = otherChar:FindFirstChild("HumanoidRootPart")
                    if otherRoot then
                        local dist = (rootPos - otherRoot.Position).Magnitude
                        if dist < 5.5 then
                            local playerId = otherPlayer.UserId
                            local now = tick()
                            if not hitPlayers[playerId] or now - hitPlayers[playerId] > HIT_COOLDOWN then
                                hitPlayers[playerId] = now
                                showHitboxMarkers(otherChar)
                                local pushDir   = Vector3.new(currentDashDir.X, 0.5, currentDashDir.Z).Unit
                                local pushForce = pushDir * (dashMagnitude * 1.5)
                                otherRoot.AssemblyLinearVelocity = pushForce
                                local originalVel = flyanim.dashVel
                                flyanim.dashVel = flyanim.dashVel * 0.4
                                task.delay(0.08, function()
                                    if flyanim.dashTimer > 0 then flyanim.dashVel = originalVel end
                                end)
                                shakeCamera(2.5, 0.25)
                            end
                        end
                    end
                end
            end
        end
    end)
end

local shakeConn = nil
local function shakeCamera(intensity, duration)
    if shakeConn then pcall(function() shakeConn:Disconnect() end); shakeConn = nil end
    local cam = workspace.CurrentCamera; if not cam then return end
    local startT = tick()
    shakeConn = RunService.RenderStepped:Connect(function()
        local elapsed = tick() - startT
        if elapsed >= duration then shakeConn:Disconnect(); shakeConn = nil; return end
        local decay  = 1 - (elapsed / duration)
        local angleX = math.sin(elapsed * 30 * math.pi) * intensity * decay
        local angleY = math.sin(elapsed * 25 * math.pi) * intensity * decay * 0.8
        local angleZ = math.sin(elapsed * 35 * math.pi) * intensity * decay * 0.6
        pcall(function() cam.CFrame = cam.CFrame * CFrame.Angles(math.rad(angleX), math.rad(angleY), math.rad(angleZ)) end)
    end)
end

-- ============================================================
-- PARTICULAS Y EFECTOS
-- ============================================================

local PARTICLE_TEXTURE = "rbxassetid://106822944701902"
local PARTICLE_LENGTH  = 6

local function createParticle(isMega)
    if flyanim.megaTurboUpActive then return end
    local char = lplr.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local camCF  = workspace.CurrentCamera.CFrame
    local lookH  = Vector3.new(camCF.LookVector.X,  0, camCF.LookVector.Z)
    local rightH = Vector3.new(camCF.RightVector.X, 0, camCF.RightVector.Z)
    if lookH.Magnitude  > 0.01 then lookH  = lookH.Unit  else lookH  = Vector3.new(0,0,-1) end
    if rightH.Magnitude > 0.01 then rightH = rightH.Unit else rightH = Vector3.new(1,0,0) end
    local moveDir = Vector3.new(0,0,0)
    if flyanim.wDown then moveDir = moveDir + lookH end
    if flyanim.sDown then moveDir = moveDir - lookH end
    if flyanim.aDown then moveDir = moveDir - rightH end
    if flyanim.dDown then moveDir = moveDir + rightH end
    if moveDir.Magnitude < 0.01 then moveDir = lookH else moveDir = moveDir.Unit end
    local spawnPos = root.Position + (-moveDir * 5)
    local awayDir  = -moveDir
    local part = Instance.new("Part")
    part.Anchored = true; part.CanCollide = false; part.CastShadow = false
    part.Transparency = 1; part.Size = Vector3.new(0.1, PARTICLE_LENGTH, 0.1)
    part.Position = spawnPos; part.Parent = workspace
    local camPos  = workspace.CurrentCamera.CFrame.Position
    local toCam   = (camPos - spawnPos).Unit
    if toCam.Magnitude < 0.01 then toCam = Vector3.new(0,0,-1) end
    local upDir   = awayDir.Unit
    local rightDir = upDir:Cross(toCam).Unit
    if rightDir.Magnitude < 0.01 then rightDir = Vector3.new(1,0,0) end
    local lookDir = rightDir:Cross(upDir).Unit
    part.CFrame = CFrame.fromMatrix(spawnPos, rightDir, upDir, lookDir)
    local sg  = Instance.new("SurfaceGui", part)
    sg.Adornee = part; sg.Face = Enum.NormalId.Front; sg.AlwaysOnTop = true
    sg.LightInfluence = 0; sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud; sg.PixelsPerStud = 50
    local img = Instance.new("ImageLabel", sg)
    img.Image = PARTICLE_TEXTURE; img.Size = UDim2.new(1,0,1,0); img.BackgroundTransparency = 1
    img.ImageColor3 = Color3.fromRGB(255,255,255)
    img.ImageTransparency = isMega and 0.3 or 0.5; img.ScaleType = Enum.ScaleType.Fit
    TweenService:Create(img, TweenInfo.new(0.4, Enum.EasingStyle.Linear), {ImageTransparency = isMega and 0.85 or 0.92}):Play()
    local travelDist = isMega and 14 or 8
    local targetPos  = spawnPos + awayDir * travelDist
    TweenService:Create(part, TweenInfo.new(0.45, Enum.EasingStyle.Linear), {Position = targetPos}):Play()
    task.delay(0.48, function() pcall(function() part:Destroy() end) end)
end

local function startParticleEmitter()
    if flyanim.particleRunning then return end
    flyanim.particleRunning = true
    flyanim.particleConn = task.spawn(function()
        while flyanim.enabled and (flyanim.mode == "fast" or flyanim.mode == "turbo") do
            if flyanim.megaTurboUpActive then task.wait(0.05); continue end
            local char = lplr.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                local isMega = (flyanim.mode == "turbo")
                createParticle(isMega)
                if isMega then task.wait(0.04); createParticle(true) end
            end
            task.wait(0.12)
        end
        flyanim.particleRunning = false
        flyanim.particleConn    = nil
    end)
end

function stopParticleEmitter()
    if flyanim.particleConn then task.cancel(flyanim.particleConn); flyanim.particleConn = nil end
    flyanim.particleRunning = false
end

local function getBrightnessFactor(speed)
    if speed <= 1000 then return (speed - 1) / 999 else return 1 end
end

local whiteFlashGui = nil
local function destroyWhiteFlash()
    if whiteFlashGui then pcall(function() whiteFlashGui:Destroy() end); whiteFlashGui = nil end
end

local function speedWhiteFlash(mode)
    destroyWhiteFlash()
    local t = getBrightnessFactor(BASE_SPEED)
    if t <= 0 then return end
    local baseOpacity = 0.38
    local maxOpacity  = (mode == "turbo") and (baseOpacity * 1.4) or baseOpacity
    local opacity     = maxOpacity * t
    local sg = Instance.new("ScreenGui")
    sg.Name="AFO_WhiteFlash"; sg.ResetOnSpawn=false
    sg.ZIndexBehavior=Enum.ZIndexBehavior.Global; sg.IgnoreGuiInset=true
    sg.DisplayOrder=950; sg.Parent=CoreGui; whiteFlashGui=sg
    local frame = Instance.new("Frame", sg)
    frame.Size=UDim2.new(1,0,1,0); frame.BackgroundColor3=Color3.fromRGB(255,255,255)
    frame.BackgroundTransparency=1; frame.BorderSizePixel=0; frame.ZIndex=2
    TweenService:Create(frame, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {BackgroundTransparency = 1 - opacity}):Play()
    task.delay(0.2, function()
        if not sg or not sg.Parent then return end
        TweenService:Create(frame, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
            {BackgroundTransparency = 1}):Play()
        task.delay(0.55, function() pcall(function() sg:Destroy() end); if whiteFlashGui == sg then whiteFlashGui = nil end end)
    end)
end

local AIR_SHOCK_ID = "rbxassetid://112096280571499"
local function airShockAura(intensity)
    local char = lplr.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local isMega = intensity == 2
    task.spawn(function()
        local bb = Instance.new("BillboardGui")
        bb.Adornee=root; bb.AlwaysOnTop=false; bb.LightInfluence=0
        bb.Size=UDim2.new(0,50,0,50); bb.ResetOnSpawn=false; bb.ZIndexBehavior=Enum.ZIndexBehavior.Global; bb.Parent=root
        local img = Instance.new("ImageLabel", bb)
        img.Image=AIR_SHOCK_ID; img.Size=UDim2.new(1,0,1,0); img.BackgroundTransparency=1
        img.ImageColor3=Color3.fromRGB(210,240,255); img.ImageTransparency=0.25; img.ScaleType=Enum.ScaleType.Fit
        local img2 = Instance.new("ImageLabel", bb)
        img2.Image=AIR_SHOCK_ID; img2.Size=UDim2.new(1.3,0,1.3,0); img2.Position=UDim2.new(-0.15,0,-0.15,0)
        img2.BackgroundTransparency=1; img2.ImageColor3=Color3.fromRGB(180,220,255); img2.ImageTransparency=0.45
        img2.ScaleType=Enum.ScaleType.Fit; img2.Rotation=45
        TweenService:Create(bb, TweenInfo.new(0.14, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
            {Size=UDim2.new(0,200,0,200)}):Play()
        task.wait(0.05)
        if not bb or not bb.Parent then return end
        TweenService:Create(bb, TweenInfo.new(0.20, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
            {Size=UDim2.new(0,280,0,280)}):Play()
        TweenService:Create(img,  TweenInfo.new(0.22, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {ImageTransparency=1}):Play()
        TweenService:Create(img2, TweenInfo.new(0.18, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {ImageTransparency=1}):Play()
        task.delay(0.32, function() pcall(function() bb:Destroy() end) end)
    end)
    if isMega then
        task.spawn(function()
            task.wait(0.05)
            if not root or not root.Parent then return end
            local bb2 = Instance.new("BillboardGui")
            bb2.Adornee=root; bb2.AlwaysOnTop=false; bb2.LightInfluence=0
            bb2.Size=UDim2.new(0,50,0,50); bb2.ResetOnSpawn=false; bb2.ZIndexBehavior=Enum.ZIndexBehavior.Global; bb2.Parent=root
            local i1 = Instance.new("ImageLabel", bb2)
            i1.Image=AIR_SHOCK_ID; i1.Size=UDim2.new(1,0,1,0); i1.BackgroundTransparency=1
            i1.ImageColor3=Color3.fromRGB(220,245,255); i1.ImageTransparency=0.15; i1.ScaleType=Enum.ScaleType.Fit; i1.Rotation=22
            local i2 = Instance.new("ImageLabel", bb2)
            i2.Image=AIR_SHOCK_ID; i2.Size=UDim2.new(1.5,0,1.5,0); i2.Position=UDim2.new(-0.25,0,-0.25,0)
            i2.BackgroundTransparency=1; i2.ImageColor3=Color3.fromRGB(190,225,255); i2.ImageTransparency=0.30
            i2.ScaleType=Enum.ScaleType.Fit; i2.Rotation=60
            TweenService:Create(bb2, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                {Size=UDim2.new(0,480,0,480)}):Play()
            task.wait(0.10)
            if not bb2 or not bb2.Parent then return end
            TweenService:Create(bb2, TweenInfo.new(0.26, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
                {Size=UDim2.new(0,680,0,680)}):Play()
            TweenService:Create(i1, TweenInfo.new(0.28, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {ImageTransparency=1}):Play()
            TweenService:Create(i2, TweenInfo.new(0.22, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {ImageTransparency=1}):Play()
            task.delay(0.40, function() pcall(function() bb2:Destroy() end) end)
        end)
    end
end

local SHOCKWAVE_ID = "rbxassetid://117592591478260"
local RING_ID      = "rbxassetid://12914395250"
local WHITE        = Color3.fromRGB(255, 255, 255)

local function sonicBoomEffect(intensity)
    local char = lplr.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local isMega = intensity == 2
    local scale  = isMega and 0.95 or 0.55
    local rings  = {
        { start=(isMega and 5 or 3)*scale, peak=(isMega and 140 or 80)*scale, exp=isMega and 0.32 or 0.20, fadeDelay=isMega and 0.14 or 0.08, fadeDur=isMega and 0.26 or 0.16 },
        { start=(isMega and 4 or 2)*scale, peak=(isMega and 90 or 52)*scale,  exp=isMega and 0.20 or 0.12, fadeDelay=isMega and 0.06 or 0.04, fadeDur=isMega and 0.18 or 0.10 },
        { start=(isMega and 3 or 1.5)*scale, peak=(isMega and 55 or 32)*scale, exp=isMega and 0.12 or 0.07, fadeDelay=0, fadeDur=isMega and 0.10 or 0.06 },
    }
    for i, r in ipairs(rings) do
        task.spawn(function()
            task.wait(i == 1 and 0 or (i == 2 and 0.02 or 0.04))
            if not root or not root.Parent then return end
            local p = Instance.new("Part")
            p.Anchored=true; p.CanCollide=false; p.CanTouch=false; p.CastShadow=false; p.Transparency=1
            p.Size=Vector3.new(r.start*2, r.start*2, 0.01); p.CFrame=root.CFrame
            local cam = workspace.CurrentCamera
            if cam then
                local d = cam.CFrame.Position - root.Position
                if d.Magnitude > 0.1 then p.CFrame = CFrame.lookAt(root.Position, root.Position + d.Unit) end
            end
            p.Parent = workspace
            local sg = Instance.new("SurfaceGui", p)
            sg.Adornee=p; sg.Face=Enum.NormalId.Front; sg.AlwaysOnTop=false; sg.LightInfluence=0
            sg.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud; sg.PixelsPerStud=50; sg.ZIndexBehavior=Enum.ZIndexBehavior.Global
            local outer = Instance.new("ImageLabel", sg)
            outer.Image=RING_ID; outer.Size=UDim2.new(1,0,1,0); outer.BackgroundTransparency=1
            outer.ImageColor3=WHITE; outer.ImageTransparency=0.06; outer.ZIndex=3
            local innerScale = 0.72 - (i-1)*0.08
            local inner = Instance.new("ImageLabel", sg)
            inner.Image=RING_ID; inner.Size=UDim2.new(innerScale,0,innerScale,0)
            inner.Position=UDim2.new((1-innerScale)/2,0,(1-innerScale)/2,0)
            inner.BackgroundTransparency=1; inner.ImageColor3=WHITE; inner.ImageTransparency=0.20; inner.ZIndex=2
            TweenService:Create(p, TweenInfo.new(r.exp, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                {Size=Vector3.new(r.peak*2, r.peak*2, 0.01)}):Play()
            task.delay(r.fadeDelay, function()
                if not p or not p.Parent then return end
                TweenService:Create(outer, TweenInfo.new(r.fadeDur, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {ImageTransparency=1}):Play()
                TweenService:Create(inner, TweenInfo.new(r.fadeDur*0.75, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {ImageTransparency=1}):Play()
            end)
            task.delay(r.fadeDelay + r.fadeDur + 0.08, function() pcall(function() p:Destroy() end) end)
        end)
    end
    task.spawn(function()
        local startPx = isMega and 90 or 60
        local peakPx  = isMega and 780 or 460
        local bb = Instance.new("BillboardGui")
        bb.Adornee=root; bb.AlwaysOnTop=true; bb.LightInfluence=0
        bb.Size=UDim2.new(0,startPx,0,startPx); bb.ResetOnSpawn=false; bb.Parent=root
        local img = Instance.new("ImageLabel", bb)
        img.Image=SHOCKWAVE_ID; img.Size=UDim2.new(1,0,1,0); img.BackgroundTransparency=1
        img.ImageColor3=WHITE; img.ImageTransparency=0; img.ScaleType=Enum.ScaleType.Fit
        TweenService:Create(bb, TweenInfo.new(0.10, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
            {Size=UDim2.new(0,peakPx,0,peakPx)}):Play()
        task.wait(0.04)
        if not img or not img.Parent then return end
        TweenService:Create(img, TweenInfo.new(0.2, Enum.EasingStyle.Exponential, Enum.EasingDirection.In), {ImageTransparency=1}):Play()
        task.delay(0.25, function() pcall(function() bb:Destroy() end) end)
    end)
end

-- ============================================================
-- EFECTOS DE ATERRIZAJE
-- - Piedras desde cualquier altura (mínimo desde 10 studs)
-- - El doble de piedritas
-- - A mayor altura, más piedritas (máximo sin lag = 28 rocas)
-- ============================================================

local function spawnLandingEffects(position, velocity)
    local intensity = math.clamp(velocity, 25, 180)
    local t = (intensity - 25) / 155

    -- Escala general de humo y sonido
    local smokeScale    = 0.8 + t * 1.8
    local soundVol      = 0.30 + t * 0.55

    -- Parámetros cinemáticos de humo épico:
    -- Arranca casi opaco (presencia fuerte) y desvanece muy lentamente
    local smokeAlphaStart = 0.02 + t * 0.06   -- casi sólido al aparecer
    local smokeAlphaEnd   = 0.82 + t * 0.14   -- desvanece a casi transparente
    local smokeDuration   = 1.10 + t * 0.60   -- dura más en caídas épicas

    local numRocks = math.floor(4 + t * 24)
    numRocks = math.min(numRocks, 28)

    -- ── Delay para esperar que el personaje esté EN el suelo ────────────────
    -- El personaje llega a Landed y luego se llama spawnLandingEffects;
    -- el HRP aún puede estar unos studs sobre la superficie real.
    -- Esperamos 1 frame para que la física siente al personaje y luego
    -- hacemos el raycast desde la posición ya asentada.
    local EFFECT_DELAY = 0.06   -- segundos de espera antes de spawnear efectos

    task.spawn(function()
        task.wait(EFFECT_DELAY)

        -- Recalcular groundPos desde la posición actual del personaje
        -- (puede haber cambiado ligeramente tras el asentamiento)
        local char = lplr.Character
        local hrpNow = char and char:FindFirstChild("HumanoidRootPart")
        local samplePos = hrpNow and hrpNow.Position or position

        local groundY = samplePos.Y
        do
            local rp = RaycastParams.new()
            rp.FilterType = Enum.RaycastFilterType.Exclude
            if char then rp.FilterDescendantsInstances = {char} end
            local hit = workspace:Raycast(samplePos, Vector3.new(0, -8, 0), rp)
            if hit then groundY = hit.Position.Y end
        end
        local groundPos = Vector3.new(samplePos.X, groundY, samplePos.Z)

        -- Colores de polvo épico (ligeramente más oscuros y saturados)
        local DUST_COLOR        = Color3.fromRGB(160, 152, 140)
        local DUST_COLOR_INNER  = Color3.fromRGB(200, 192, 182)
        local DUST_COLOR_BILLOW = Color3.fromRGB(120, 112, 100)   -- capa de billow oscura

        -- Sonido
        local snd = Instance.new("Sound")
        snd.SoundId = SFX_LANDING
        snd.Volume  = soundVol
        snd.RollOffMaxDistance = 0
        snd.Parent  = SoundService
        snd:Play()
        snd.Ended:Connect(function() pcall(function() snd:Destroy() end) end)
        task.delay(8, function() pcall(function() snd:Destroy() end) end)

        -- ── CAPA 0: flash de impacto (anillo fino e instantáneo) ─────────────
        -- Aparece y se disuelve muy rápido para dar el "golpe" visual
        task.spawn(function()
            local flashSize = smokeScale * 6
            local pf = Instance.new("Part")
            pf.Anchored = true; pf.CanCollide = false; pf.CanTouch = false; pf.CastShadow = false
            pf.Transparency = 1; pf.Size = Vector3.new(flashSize, flashSize, 0.05)
            pf.CFrame = CFrame.new(groundPos + Vector3.new(0, 0.08, 0)) * CFrame.Angles(math.rad(90), 0, 0)
            pf.Parent = workspace
            local sgf = Instance.new("SurfaceGui", pf)
            sgf.Adornee = pf; sgf.Face = Enum.NormalId.Front; sgf.AlwaysOnTop = false
            sgf.LightInfluence = 0; sgf.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud; sgf.PixelsPerStud = 40
            local imgf = Instance.new("ImageLabel", sgf)
            imgf.Image = SMOKE_RING_TEX; imgf.Size = UDim2.new(1,0,1,0); imgf.BackgroundTransparency = 1
            imgf.ImageColor3 = Color3.fromRGB(230, 225, 218); imgf.ImageTransparency = 0.0; imgf.ScaleType = Enum.ScaleType.Fit
            local flashPeak = flashSize * (3.5 + t * 1.5)
            TweenService:Create(pf, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                {Size = Vector3.new(flashPeak, flashPeak, 0.05)}):Play()
            TweenService:Create(imgf, TweenInfo.new(0.22, Enum.EasingStyle.Expo, Enum.EasingDirection.In),
                {ImageTransparency = 1}):Play()
            task.delay(0.25, function() pcall(function() pf:Destroy() end) end)
        end)

        -- ── CAPA 1: anillo principal de humo épico (grande, lento, persistente) ─
        task.spawn(function()
            local ringSize = smokeScale * 10
            local p = Instance.new("Part")
            p.Anchored = true; p.CanCollide = false; p.CanTouch = false; p.CastShadow = false
            p.Transparency = 1; p.Size = Vector3.new(ringSize, ringSize, 0.05)
            p.CFrame = CFrame.new(groundPos + Vector3.new(0, 0.14, 0)) * CFrame.Angles(math.rad(90), 0, 0)
            p.Parent = workspace
            local sg = Instance.new("SurfaceGui", p)
            sg.Adornee = p; sg.Face = Enum.NormalId.Front; sg.AlwaysOnTop = false
            sg.LightInfluence = 0; sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud; sg.PixelsPerStud = 40
            local img = Instance.new("ImageLabel", sg)
            img.Image = SMOKE_RING_TEX; img.Size = UDim2.new(1,0,1,0); img.BackgroundTransparency = 1
            img.ImageColor3 = DUST_COLOR; img.ImageTransparency = smokeAlphaStart; img.ScaleType = Enum.ScaleType.Fit
            local peakSize = ringSize * (3.2 + t * 2.5)
            TweenService:Create(p, TweenInfo.new(smokeDuration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                {Size = Vector3.new(peakSize, peakSize, 0.05)}):Play()
            TweenService:Create(img, TweenInfo.new(smokeDuration, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
                {ImageTransparency = smokeAlphaEnd}):Play()
            task.delay(smokeDuration + 0.05, function() pcall(function() p:Destroy() end) end)
        end)

        -- ── CAPA 2: anillo de billow oscuro (sale antes, da profundidad) ──────
        task.spawn(function()
            task.wait(0.03)
            local ringSize2 = smokeScale * 7
            local p2 = Instance.new("Part")
            p2.Anchored = true; p2.CanCollide = false; p2.CanTouch = false; p2.CastShadow = false
            p2.Transparency = 1; p2.Size = Vector3.new(ringSize2, ringSize2, 0.05)
            p2.CFrame = CFrame.new(groundPos + Vector3.new(0, 0.10, 0)) * CFrame.Angles(math.rad(90), 0, 0)
            p2.Parent = workspace
            local sg2 = Instance.new("SurfaceGui", p2)
            sg2.Adornee = p2; sg2.Face = Enum.NormalId.Front; sg2.AlwaysOnTop = false
            sg2.LightInfluence = 0; sg2.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud; sg2.PixelsPerStud = 40
            local img2 = Instance.new("ImageLabel", sg2)
            img2.Image = SMOKE_RING_TEX; img2.Size = UDim2.new(1,0,1,0); img2.BackgroundTransparency = 1
            img2.ImageColor3 = DUST_COLOR_BILLOW
            img2.ImageTransparency = smokeAlphaStart + 0.08; img2.ScaleType = Enum.ScaleType.Fit
            local dur2 = smokeDuration * 0.75
            local peakSize2 = ringSize2 * (2.4 + t * 1.8)
            TweenService:Create(p2, TweenInfo.new(dur2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                {Size = Vector3.new(peakSize2, peakSize2, 0.05)}):Play()
            TweenService:Create(img2, TweenInfo.new(dur2, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
                {ImageTransparency = smokeAlphaEnd + 0.08}):Play()
            task.delay(dur2 + 0.05, function() pcall(function() p2:Destroy() end) end)
        end)

        -- ── CAPA 3: anillo interior luminoso (da sensación de explosión de aire) ─
        task.spawn(function()
            task.wait(0.07)
            local ringSize3 = smokeScale * 4
            local p3 = Instance.new("Part")
            p3.Anchored = true; p3.CanCollide = false; p3.CanTouch = false; p3.CastShadow = false
            p3.Transparency = 1; p3.Size = Vector3.new(ringSize3, ringSize3, 0.05)
            p3.CFrame = CFrame.new(groundPos + Vector3.new(0, 0.05, 0)) * CFrame.Angles(math.rad(90), 0, 0)
            p3.Parent = workspace
            local sg3 = Instance.new("SurfaceGui", p3)
            sg3.Adornee = p3; sg3.Face = Enum.NormalId.Front; sg3.AlwaysOnTop = false
            sg3.LightInfluence = 0; sg3.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud; sg3.PixelsPerStud = 40
            local img3 = Instance.new("ImageLabel", sg3)
            img3.Image = SMOKE_RING_TEX; img3.Size = UDim2.new(1,0,1,0); img3.BackgroundTransparency = 1
            img3.ImageColor3 = DUST_COLOR_INNER
            img3.ImageTransparency = smokeAlphaStart - 0.01; img3.ScaleType = Enum.ScaleType.Fit
            local dur3 = smokeDuration * 0.55
            local peakSize3 = ringSize3 * (2.0 + t * 1.4)
            TweenService:Create(p3, TweenInfo.new(dur3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                {Size = Vector3.new(peakSize3, peakSize3, 0.05)}):Play()
            TweenService:Create(img3, TweenInfo.new(dur3, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
                {ImageTransparency = smokeAlphaEnd - 0.06}):Play()
            task.delay(dur3 + 0.05, function() pcall(function() p3:Destroy() end) end)
        end)

        -- ── Piedrecitas ───────────────────────────────────────────────────────
        task.spawn(function()
            local ROCK_BASE = Color3.fromRGB(130, 125, 118)
            local batchSize = 6
            local spawned = 0
            while spawned < numRocks do
                local thisBatch = math.min(batchSize, numRocks - spawned)
                for i = 1, thisBatch do
                    task.spawn(function()
                        local rockSize = 0.08 + math.random() * (0.14 + t * 0.12)
                        local rock = Instance.new("Part")
                        rock.Size        = Vector3.new(rockSize, rockSize, rockSize)
                        rock.Material    = Enum.Material.SmoothPlastic
                        rock.Color       = ROCK_BASE:Lerp(Color3.fromRGB(160,155,148), math.random() * 0.4)
                        rock.CanCollide  = false; rock.CanTouch = false; rock.CastShadow = false; rock.Anchored = false
                        local angle = ((spawned + i) / numRocks) * math.pi * 2 + math.random() * 0.9
                        local radius = 0.25 + math.random() * 0.75
                        rock.CFrame  = CFrame.new(
                            groundPos.X + math.cos(angle) * radius,
                            groundPos.Y + 0.05,
                            groundPos.Z + math.sin(angle) * radius
                        )
                        rock.Parent = workspace
                        local outDir = Vector3.new(math.cos(angle), 0.55 + math.random() * 0.9, math.sin(angle)).Unit
                        local power = (3.5 + t * 9) * (0.65 + math.random() * 0.7)
                        rock.AssemblyLinearVelocity = outDir * power
                        local fadeTime = 0.35 + math.random() * 0.35
                        task.delay(0.04, function()
                            if not rock or not rock.Parent then return end
                            TweenService:Create(rock, TweenInfo.new(fadeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
                                {Transparency = 1}):Play()
                            task.delay(fadeTime + 0.05, function() pcall(function() rock:Destroy() end) end)
                        end)
                    end)
                end
                spawned = spawned + thisBatch
                if spawned < numRocks then task.wait(0.01) end
            end
        end)
    end)  -- fin task.spawn EFFECT_DELAY
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
                flyanim.mode   = "normal"
                flyanim.speed  = BASE_SPEED
                flyanim.qLastPress = 0
                if flyanim.updateMode then flyanim.updateMode("normal") end
                if not flyanim.noclipSpaceActive and not flyanim.noclipCtrlActive then setNoclip(false) end
                stopParticleEmitter()
                if flyanim.turboRenderConn then flyanim.turboRenderConn:Disconnect(); flyanim.turboRenderConn = nil end
                if flyanim.megaRenderConn  then flyanim.megaRenderConn:Disconnect();  flyanim.megaRenderConn  = nil end
                detenerWatchdogAltura()
                if prevMode == "fast" then
                    detenerPoseTurbo()
                elseif prevMode == "turbo" then
                    detenerPoseMega()
                    detenerPoseTurbo()
                end
                flyanim.c0ControlToken = (flyanim.c0ControlToken or 0) + 1
                restaurarC0Inmediato()
                if not flyanim.comboPlaying then
                    flyanim._normalPlayId = (flyanim._normalPlayId or 0) + 1
                    iniciarCicloNormal(flyanim._normalPlayId)
                end
            end
        end
    end)
end

-- ============================================================
-- SETUP ANIMADOR (más robusto)
-- ============================================================

local function setupAnimator(char)
    -- Desactivar animate script del juego
    local animScript = char:FindFirstChild("Animate")
    if animScript then animScript.Disabled = true; flyanim.animScript = animScript end

    local humanoid = char:WaitForChild("Humanoid", 5)
    if not humanoid then return end
    local animator = humanoid:WaitForChild("Animator", 5)
    if not animator then return end

    flyanim.animator = animator
    flyanim.tracks   = {}

    -- Parar todas las animaciones del juego
    local ok, playing = pcall(function() return animator:GetPlayingAnimationTracks() end)
    if ok and playing then
        for _, t in ipairs(playing) do pcall(function() t:Stop(0) end) end
    end

    if flyanim.animConn then flyanim.animConn:Disconnect(); flyanim.animConn = nil end

    local hrp = char:WaitForChild("HumanoidRootPart", 5)
    if not hrp then return end
    local rj  = hrp:WaitForChild("RootJoint", 5)
    if not rj then return end

    flyanim.rootJoint  = rj
    flyanim.originalC0 = rj.C0

    -- Pre-cargar tracks con protección
    for _, id in pairs(ANIM) do
        pcall(function() getTrack(id) end)
    end

    local function loadNorm(id, priority, looped)
        local anim = Instance.new("Animation")
        anim.AnimationId = id
        local ok2, t = pcall(function() return animator:LoadAnimation(anim) end)
        if not ok2 or not t then return nil end
        t.Priority = priority or Enum.AnimationPriority.Action3
        t.Looped   = (looped ~= false)
        return t
    end

    flyanim.normalTracks = {
        estatica      = loadNorm(ANIM.estatica,       Enum.AnimationPriority.Action2),
        levitacion    = loadNorm(ANIM.levitacion,     Enum.AnimationPriority.Action4),
        brazos        = loadNorm(ANIM.brazos_idle,    Enum.AnimationPriority.Action3),
        mov_forward   = loadNorm(ANIM.mov_forward,    Enum.AnimationPriority.Action3),
        mov_back      = loadNorm(ANIM.mov_back_anim,  Enum.AnimationPriority.Action3),
        mov_brazos    = loadNorm(ANIM.mov_brazos_mov, Enum.AnimationPriority.Action3),
        lateral       = loadNorm(ANIM.mov_lateral,    Enum.AnimationPriority.Action3, false),
        espacio_prim  = loadNorm(ANIM.espacio_prim,   Enum.AnimationPriority.Action3, true),
        espacio_sec   = loadNorm(ANIM.espacio_sec,    Enum.AnimationPriority.Action3, false),
        turbo_compact = loadNorm(ANIM.turbo_compact,  Enum.AnimationPriority.Action4, false),
        turbo_burst   = loadNorm(ANIM.turbo_burst,    Enum.AnimationPriority.Action4, false),
        turbo_pose    = loadNorm(ANIM.turbo_pose,     Enum.AnimationPriority.Action4, true),
        turbo_volado  = loadNorm(ANIM.turbo_volado,   Enum.AnimationPriority.Action4, true),
        mega_pose     = loadNorm(ANIM.mega_pose,      Enum.AnimationPriority.Action4, true),
        mega_base     = loadNorm(ANIM.mega_base,      Enum.AnimationPriority.Action3, true),
        mega_volado   = loadNorm(ANIM.mega_volado,    Enum.AnimationPriority.Action4, true),
    }

    local nt = flyanim.normalTracks
    -- Pre-inicializar tracks que necesitan ser jugados y parados para tener Length
    if nt.lateral     then pcall(function() nt.lateral:Play(0);     nt.lateral:Stop(0) end) end
    if nt.mov_back    then pcall(function() nt.mov_back:Play(0);    nt.mov_back:Stop(0) end) end
    if nt.espacio_sec then pcall(function() nt.espacio_sec:Play(0); nt.espacio_sec:Stop(0) end) end

    local ownAnimIds = {}
    for _, id in pairs(ANIM) do ownAnimIds[id] = true end
    ownAnimIds[CAIDA_BASE_ID]    = true
    ownAnimIds[CAIDA_OVERLAY_ID] = true

    if flyanim.animConn then flyanim.animConn:Disconnect(); flyanim.animConn = nil end

    -- Bloquear animaciones del juego con reconexión automática
    flyanim.animConn = animator.AnimationPlayed:Connect(function(track)
        if not track or not track.Animation then return end
        local id = track.Animation.AnimationId
        if not ownAnimIds[id] then
            pcall(function()
                if track and track.IsPlaying then track:Stop(0) end
            end)
        end
    end)

    setupBlockTrack()
    setupDamageDetector()
end

local function restoreGameAnimations(char)
    if not char then return end
    if flyanim.animConn then flyanim.animConn:Disconnect(); flyanim.animConn = nil end
    stopAnimBlockLoop()
    local animScript = char:FindFirstChild("Animate") or flyanim.animScript
    if animScript then animScript.Disabled = false; flyanim.animScript = nil end
    if flyanim.rootJoint and flyanim.originalC0 then
        pcall(function() flyanim.rootJoint.C0 = flyanim.originalC0 end)
    end
    local root = char:FindFirstChild("HumanoidRootPart")
    if root then cleanupMotors(root) end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.PlatformStand = false
        pcall(function() humanoid:ChangeState(Enum.HumanoidStateType.GettingUp) end)
        task.wait(0.05)
        pcall(function() humanoid:ChangeState(Enum.HumanoidStateType.Landed) end)
    end
end

-- ============================================================
-- LANDING
-- ============================================================

-- CAMBIO SALVAJE: token global para matar la animación de caída épica desde _flyOn
local _landAnimToken = 0
local _landBaseRef    = nil
local _landOverlayRef = nil

local function doLanding(char)
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")

    local altura   = flyanim.landingHeight or 0
    local impactVel = math.max(flyanim.landingVelocity or 0, flyanim.landingVelocityCapture or 0)
    flyanim.landingHeight   = nil
    flyanim.landingVelocity = 0
    flyanim.landingVelocityCapture = 0

    -- Umbral bajo para piedritas: desde 10 studs ya hay efecto
    if altura < 10 then restoreGameAnimations(char); return end
    if not animator then restoreGameAnimations(char); return end

    if flyanim.turboRenderConn then flyanim.turboRenderConn:Disconnect(); flyanim.turboRenderConn = nil end
    if flyanim.megaRenderConn  then flyanim.megaRenderConn:Disconnect();  flyanim.megaRenderConn  = nil end
    if flyanim.blockRenderConn then flyanim.blockRenderConn:Disconnect(); flyanim.blockRenderConn = nil end
    if flyanim.idleAnimConn    then flyanim.idleAnimConn:Disconnect();    flyanim.idleAnimConn    = nil end
    flyanim.idleWatchToken = (flyanim.idleWatchToken or 0) + 1
    flyanim.c0ControlToken = (flyanim.c0ControlToken or 0) + 1
    detenerWatchdogAltura()
    restaurarC0Inmediato()

    if flyanim.blockTrack and flyanim.blockTrack.IsPlaying then
        pcall(function() flyanim.blockTrack:Stop(0) end)
    end
    flyanim.isBlocking     = false
    flyanim.isSpaceAdv     = false
    flyanim.turboTransitioning = false
    flyanim.megaTransitioning  = false

    if flyanim.animConn then flyanim.animConn:Disconnect(); flyanim.animConn = nil end
    stopAnimBlockLoop()

    local ok, playing = pcall(function() return animator:GetPlayingAnimationTracks() end)
    if ok and playing then
        for _, track in ipairs(playing) do pcall(function() track:Stop(0) end) end
    end

    for _, t in pairs(flyanim.tracks) do pcall(function() if t and t.IsPlaying then t:Stop(0) end end) end
    for _, t in pairs(flyanim.normalTracks) do pcall(function() if t and t.IsPlaying then t:Stop(0) end end) end
    flyanim.tracks = {}

    if flyanim.rootJoint and flyanim.originalC0 then
        pcall(function() flyanim.rootJoint.C0 = flyanim.originalC0 end)
    end

    local animScript = char:FindFirstChild("Animate") or flyanim.animScript
    if animScript then animScript.Disabled = true end

    local landAnimIds = {[CAIDA_BASE_ID]=true, [CAIDA_OVERLAY_ID]=true}
    local landAnimConn = animator.AnimationPlayed:Connect(function(track)
        if track.Animation then
            local id = track.Animation.AnimationId
            if not landAnimIds[id] then pcall(function() track:Stop(0) end) end
        end
    end)

    if humanoid then
        humanoid.PlatformStand = false
        pcall(function() humanoid:ChangeState(Enum.HumanoidStateType.Landed) end)
        task.wait(0.05)
    end

    local root = char:FindFirstChild("HumanoidRootPart")
    local impactPos = root and root.Position or Vector3.new(0,0,0)

    if root then
        local _, ry, _ = root.CFrame:ToOrientation()
        local currentPos = root.Position
        pcall(function()
            root.CFrame = CFrame.new(currentPos) * CFrame.Angles(0, ry, 0)
            root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
        end)
    end

    -- Solo zerear velocidad angular para evitar giros involuntarios al aterrizar.
    -- NO usar BodyVelocity ni PlatformStand=true aqui: causan que el humanoid
    -- quede suspendido en el aire y nunca llegue al estado Landed real.
    if root then
        pcall(function() root.AssemblyAngularVelocity = Vector3.new(0, 0, 0) end)
    end

    -- Efectos de impacto: piedritas siempre, escaladas con velocidad/altura
    spawnLandingEffects(impactPos, math.max(impactVel, altura * 0.5))

    -- Animación de landing solo si cayó desde bastante altura (>= 25 studs)
    if altura >= 25 then
        local animObjBase = Instance.new("Animation")
        animObjBase.AnimationId = CAIDA_BASE_ID
        local animObjOverlay = Instance.new("Animation")
        animObjOverlay.AnimationId = CAIDA_OVERLAY_ID

        local landBase    = animator:LoadAnimation(animObjBase)
        local landOverlay = animator:LoadAnimation(animObjOverlay)
        landBase.Priority    = Enum.AnimationPriority.Action3
        landOverlay.Priority = Enum.AnimationPriority.Action4
        landBase.Looped    = true
        landOverlay.Looped = true

        -- CAMBIO SALVAJE: registrar refs globales y capturar token para poder matar esto desde _flyOn
        _landAnimToken = _landAnimToken + 1
        local myToken  = _landAnimToken
        _landBaseRef    = landBase
        _landOverlayRef = landOverlay

        pcall(function() landBase:Stop(0); landOverlay:Stop(0) end)
        pcall(function() landBase:Play(0.0, 1, 1) end)
        pcall(function() landOverlay:Play(0.0, 1, 1) end)

        pcall(function() landBase:AdjustSpeed(8.0) end)
        pcall(function() landOverlay:AdjustSpeed(8.0) end)

        task.wait(0.06)
        if _landAnimToken ~= myToken then landAnimConn:Disconnect(); return end

        pcall(function() landBase:AdjustSpeed(0) end)
        pcall(function() landOverlay:AdjustSpeed(0) end)

        local shakeIntensity = 2.0 + (math.clamp(altura, 25, 200) - 25) / 175 * 1.5
        shakeCamera(shakeIntensity, 0.30)

        task.wait(0.30)
        if _landAnimToken ~= myToken then landAnimConn:Disconnect(); return end
        pcall(function() landBase:AdjustSpeed(0.3); landOverlay:AdjustSpeed(0.3) end)
        task.wait(0.45)
        if _landAnimToken ~= myToken then landAnimConn:Disconnect(); return end
        pcall(function() landBase:AdjustSpeed(1.0); landOverlay:AdjustSpeed(1.0) end)
        task.wait(0.3)
        if _landAnimToken ~= myToken then landAnimConn:Disconnect(); return end
        pcall(function() landBase:Stop(0.5); landOverlay:Stop(0.5) end)
        task.wait(0.5)
        if _landAnimToken ~= myToken then landAnimConn:Disconnect(); return end

        landAnimConn:Disconnect()

        task.wait(0.4)
        if _landAnimToken ~= myToken then return end

        pcall(function() landBase:Destroy() end)
        pcall(function() landOverlay:Destroy() end)
        if _landBaseRef == landBase then _landBaseRef = nil end
        if _landOverlayRef == landOverlay then _landOverlayRef = nil end
    else
        -- Caída leve: solo efectos, sin animación larga
        local shakeIntensity = 0.8 + (math.clamp(altura, 10, 25) - 10) / 15 * 1.2
        shakeCamera(shakeIntensity, 0.18)
        landAnimConn:Disconnect()
        task.wait(0.3)
    end

    if animScript then animScript.Disabled = false end
    if flyanim.animConn then flyanim.animConn:Disconnect(); flyanim.animConn = nil end
    if flyanim.rootJoint and flyanim.originalC0 then
        pcall(function() flyanim.rootJoint.C0 = flyanim.originalC0 end)
    end
    local root2 = char:FindFirstChild("HumanoidRootPart")
    if root2 then cleanupMotors(root2) end
    local hum2 = char:FindFirstChildOfClass("Humanoid")
    if hum2 then
        hum2.PlatformStand = false
        -- NO llamar GettingUp aquí: genera impulso hacia arriba que causa el rebote.
        -- Ir directamente a Landed → Running.
        pcall(function() hum2:ChangeState(Enum.HumanoidStateType.Landed) end)
        task.wait(0.05)
        pcall(function() hum2:ChangeState(Enum.HumanoidStateType.Running) end)
    end
end

-- ============================================================
-- SISTEMA DE COMBOS
-- ============================================================
--
-- Diseño: un único "secuenciador" (task.spawn) vive durante todo el
-- combo. Cada paso lanza la animación y luego bloquea 0.75s antes de
-- aceptar el siguiente golpe. Si en esos 0.75s llega un click se
-- registra como "pendiente" y se ejecuta inmediatamente al desbloquearse.
-- Si pasados 1.5s (COMBO_CHAIN_WINDOW) no llegó ningún click, el combo
-- termina limpiamente sin depender de onStopped.
-- ============================================================

-- Duración mínima por paso antes de aceptar el siguiente golpe
-- Paso 1: 0.47s | Paso 2: 0.47s | Paso 3: 0.53s | Paso 4: 0.68s
local COMBO_STEP_DURATION  = {0.47, 0.47, 0.53, 0.68}
local COMBO_ANIM_DURATION  = 0.47   -- fallback genérico (ya no lo usa el secuenciador principal)
-- Si pasa más de 1s sin click, el combo termina
local COMBO_PENDING_WINDOW = 1.0

-- Señal de "click pendiente": el secuenciador la consume cuando comboBusy=false
local comboPendingClick = false

local function _launchComboAnim(animId, speed)
    -- Solo parar animaciones de combate (flyanim.tracks), NUNCA las normalTracks
    -- (levitación, estatica, idle, movimiento) para que no se rompa el sistema de animación
    for id, track in pairs(flyanim.tracks) do
        if id ~= animId and id ~= ANIM.levitacion and track and track.IsPlaying then
            pcall(function() track:Stop(0.05) end)
        end
    end
    -- NO tocar flyanim.normalTracks aqui: esas son las animaciones del vuelo normal
    -- y pararlas rompe la animacion de idle/levitacion al terminar el combo

    local t = getTrack(animId)
    if not t then return end
    t.Looped   = false
    t.Priority = Enum.AnimationPriority.Action4
    if t.IsPlaying then pcall(function() t:Stop(0) end) end
    pcall(function() t:Play(0.05, 1, 1) end)
    pcall(function() t:AdjustSpeed(speed or 3.0) end)
end

local function resetCombo()
    flyanim.comboStep      = 0
    flyanim.comboLastClick = 0
    flyanim.combo2LastUsed = nil
    comboPendingClick      = false
end

local function startComboC0Lock()
    if flyanim.comboC0Conn then flyanim.comboC0Conn:Disconnect(); flyanim.comboC0Conn = nil end
    if not flyanim.rootJoint or not flyanim.originalC0 then return end
    local rj = flyanim.rootJoint
    local oc = flyanim.originalC0
    flyanim.c0ControlToken = (flyanim.c0ControlToken or 0) + 1
    local myToken = flyanim.c0ControlToken
    flyanim.comboC0Conn = RunService.RenderStepped:Connect(function()
        if not flyanim.comboPlaying then
            if flyanim.comboC0Conn then flyanim.comboC0Conn:Disconnect(); flyanim.comboC0Conn = nil end
            return
        end
        if flyanim.c0ControlToken ~= myToken then
            if flyanim.comboC0Conn then flyanim.comboC0Conn:Disconnect(); flyanim.comboC0Conn = nil end
            return
        end
        pcall(function() rj.C0 = oc end)
    end)
end

local function stopComboC0Lock()
    if flyanim.comboC0Conn then flyanim.comboC0Conn:Disconnect(); flyanim.comboC0Conn = nil end
end

local function finalizarCombo()
    flyanim.dashTimer    = 0
    flyanim.dashVel      = Vector3.new(0,0,0)
    flyanim.comboPlaying = false
    flyanim.comboBusy    = false
    flyanim.combo4Frozen = false
    comboPendingClick    = false

    stopComboC0Lock()

    if not flyanim.enabled then return end

    for id, track in pairs(flyanim.tracks) do
        if id ~= ANIM.levitacion and track and track.IsPlaying then
            pcall(function() track:Stop(0.12) end)
        end
    end

    task.wait(0.08)

    if not flyanim.enabled then return end

    flyanim.c0ControlToken = (flyanim.c0ControlToken or 0) + 1
    detenerWatchdogAltura()
    restaurarC0Inmediato()

    if flyanim.mode == "normal" then
        flyanim._normalPlayId = (flyanim._normalPlayId or 0) + 1
        local pid = flyanim._normalPlayId

        local nt = flyanim.normalTracks
        if nt then
            if nt.levitacion and not nt.levitacion.IsPlaying then
                pcall(function() nt.levitacion:Play(0.2) end)
                pcall(function() nt.levitacion:AdjustSpeed(ANIM_NORMAL.VELOCIDAD_LEVITACION) end)
            end
        end

        iniciarCicloNormal(pid)
        task.delay(0.05, function()
            if flyanim.enabled and flyanim.mode == "normal" then evaluarMovimientoNormal() end
        end)
    else
        updateAnimForMovement()
    end
end

-- Secuenciador del combo: corre en su propio task y maneja toda la secuencia
-- Duraciones por paso: 0.47s / 0.47s / 0.53s / 0.68s
-- Cancelación si no hay click en 1s tras cada paso.
local function runComboSequencer(startToken)
    -- ── Helper: esperar duración de paso y luego aguardar click ──────────────
    local function waitStep(stepIdx)
        local dur = COMBO_STEP_DURATION[stepIdx] or 0.47
        local stepStart = tick()
        while tick() - stepStart < dur do
            task.wait(0.02)
            if flyanim.comboToken ~= startToken then return false end
        end
        flyanim.comboBusy = false

        local waitStart = tick()
        while not comboPendingClick do
            task.wait(0.02)
            if flyanim.comboToken ~= startToken then return false end
            if tick() - waitStart > COMBO_PENDING_WINDOW then
                finalizarCombo(); return false
            end
        end
        comboPendingClick = false
        if flyanim.comboToken ~= startToken then return false end
        return true
    end

    -- ── Paso 1 ────────────────────────────────────────────────────────────────
    flyanim.comboStep = 1
    _launchComboAnim(ANIM.combo1, 3.0)
    flyanim.comboBusy = true
    comboPendingClick = false
    if not waitStep(1) then return end

    -- ── Paso 2 ────────────────────────────────────────────────────────────────
    flyanim.comboStep = 2
    local r = math.random(1, 2)
    local chosenId2, chosenKey2
    if r == 1 then chosenId2 = ANIM.combo2a; chosenKey2 = "a"
    else            chosenId2 = ANIM.combo2b; chosenKey2 = "b" end
    flyanim.combo2LastUsed = chosenKey2
    _launchComboAnim(chosenId2, 3.0)
    flyanim.comboBusy = true
    comboPendingClick = false
    if not waitStep(2) then return end

    -- ── Paso 3 ────────────────────────────────────────────────────────────────
    flyanim.comboStep = 3
    local chosenId3 = (flyanim.combo2LastUsed == "a") and ANIM.combo3b or ANIM.combo3a
    _launchComboAnim(chosenId3, 3.0)
    flyanim.comboBusy = true
    comboPendingClick = false
    if not waitStep(3) then return end

    -- ── Paso 4 ────────────────────────────────────────────────────────────────
    flyanim.comboStep = 4
    local spaceDown4 = UserInputService:IsKeyDown(Enum.KeyCode.Space)

    if spaceDown4 then
        -- Combo 4 especial con espacio (sin cambios)
        local t4s = getTrack(ANIM.combo4_space)
        if t4s then
            for id, track in pairs(flyanim.tracks) do
                if id ~= ANIM.combo4_space and id ~= ANIM.levitacion and track and track.IsPlaying then
                    pcall(function() track:Stop(0.05) end)
                end
            end
            t4s.Looped = false; t4s.Priority = Enum.AnimationPriority.Action4
            if t4s.IsPlaying then pcall(function() t4s:Stop(0) end) end
            pcall(function() t4s:Play(0.05, 1, 1); t4s:AdjustSpeed(1.0) end)
            flyanim.comboBusy = true
            local timeout4 = tick() + 5
            while t4s.IsPlaying and tick() < timeout4 do
                task.wait(0.03)
                if flyanim.comboToken ~= startToken then return end
            end
            flyanim.comboBusy = false
            task.wait(0.3)
        end
        resetCombo()
        finalizarCombo()
        return
    end

    -- ── Combo 4 normal: animación completa rápida, pausa al 55%, remate muy rápido
    --
    -- Diseño de timing (duración total del paso 4 = 0.68s):
    --   · La animación rbxassetid://2954124238 tiene su "golpe natural" alrededor
    --     del frame 0.53s.  La corremos a velocidad alta para que ese trozo pase
    --     rápido, luego la congelamos al 55% del largo total.
    --   · Al 55% aplicamos la lógica de impacto (hitbox, comboBusy=false para que
    --     el secuenciador continúe contando el tiempo restante hasta 0.68s).
    --   · Tras la pausa, corremos lo que queda (55%→100%) a velocidad muy alta
    --     (AdjustSpeed 15) para que el remate visual sea instantáneo.
    -- ─────────────────────────────────────────────────────────────────────────
    local t4 = getTrack(ANIM.combo4)
    if not t4 then finalizarCombo(); return end

    -- Parar otras tracks de combate (NO las normalTracks)
    for id, track in pairs(flyanim.tracks) do
        if id ~= ANIM.combo4 and id ~= ANIM.levitacion and track and track.IsPlaying then
            pcall(function() track:Stop(0.05) end)
        end
    end

    t4.Looped   = false
    t4.Priority = Enum.AnimationPriority.Action4
    if t4.IsPlaying then pcall(function() t4:Stop(0) end) end

    -- Esperar a que el track tenga duración conocida (máx 2s)
    pcall(function() t4:Play(0.05, 1, 1) end)
    local toLoad = tick() + 2
    while t4.Length == 0 and tick() < toLoad do
        task.wait(0.02)
        if flyanim.comboToken ~= startToken then
            flyanim.combo4Frozen = false; return
        end
    end

    -- Fase 1: desde 0% hasta 55%, velocidad alta (el "golpe" natural de la anim ~0.53s pasa rápido)
    pcall(function() t4:AdjustSpeed(4.0) end)
    flyanim.comboBusy = true
    comboPendingClick = false
    flyanim.combo4Frozen = false

    local len4 = t4.Length
    local PAUSE_PERC = 0.55  -- pausar aquí para aplicar la lógica de impacto
    local timeout4 = tick() + 4
    while t4.IsPlaying and tick() < timeout4 do
        task.wait(0.016)
        if flyanim.comboToken ~= startToken then
            flyanim.combo4Frozen = false; return
        end
        len4 = t4.Length
        if len4 > 0 and t4.TimePosition >= len4 * PAUSE_PERC then break end
    end
    if flyanim.comboToken ~= startToken then flyanim.combo4Frozen = false; return end

    -- ── PAUSA AL 55%: aplicar lógica de impacto ───────────────────────────────
    flyanim.combo4Frozen = true
    flyanim.comboBusy    = false   -- el secuenciador puede seguir contando el tiempo
    pcall(function() t4:AdjustSpeed(0) end)
    if len4 > 0 then pcall(function() t4.TimePosition = len4 * PAUSE_PERC end) end

    -- Aquí es donde el tiempo restante del paso 4 (0.68s total menos lo ya transcurrido)
    -- "corre" — el waitStep(4) ya consumió ~0s porque lo llamamos después.
    -- Calculamos el tiempo que queda hasta completar 0.68s desde que empezó el paso 4.
    -- (No usamos waitStep aquí porque queremos la ventana de click al mismo tiempo)
    -- Esperar el click pendiente o que expire el tiempo del paso
    local stepDur4  = COMBO_STEP_DURATION[4]   -- 0.68s
    local pauseDeadline = tick() + (stepDur4 * (1 - PAUSE_PERC) + 0.08)  -- tiempo restante + buffer
    while not comboPendingClick and tick() < pauseDeadline do
        task.wait(0.02)
        if flyanim.comboToken ~= startToken then
            flyanim.combo4Frozen = false; return
        end
    end
    flyanim.combo4Frozen = false
    comboPendingClick    = false
    if flyanim.comboToken ~= startToken then return end

    -- Fase 2: continuar desde 55% hasta el final muy rápido (remate visual instantáneo)
    pcall(function() t4:AdjustSpeed(15) end)
    t4.Looped = false
    local timeout4b = tick() + 2
    while t4.IsPlaying and tick() < timeout4b do
        task.wait(0.016)
        if flyanim.comboToken ~= startToken then return end
    end

    resetCombo()
    finalizarCombo()
end

local function handleComboClick()
    if not flyanim.enabled then return end
    if flyanim.turboPreImpulsoActivo then return end
    if flyanim.isBlocking then return end

    -- Si el combo ya está corriendo y esperando un click, registrarlo como pendiente
    if flyanim.comboPlaying then
        if flyanim.comboBusy then
            -- Aún en el período de 0.75s: ignorar (el combo lo aceptará cuando baje comboBusy)
            return
        end
        -- Registrar click pendiente (el secuenciador lo consumirá)
        comboPendingClick = true
        flyanim.comboLastClick = tick()
        return
    end

    -- Iniciar combo nuevo
    local now = tick()
    if now - flyanim.comboLastClick < COMBO_MIN_GAP then return end

    flyanim.comboToken = (flyanim.comboToken or 0) + 1
    local myToken = flyanim.comboToken

    if flyanim.idleAnimConn then flyanim.idleAnimConn:Disconnect(); flyanim.idleAnimConn = nil end

    if flyanim.isBlocking then
        stopBlocking()
        flyanim.blockCancelledByCombo = true
    end

    flyanim.comboPlaying    = true
    flyanim.comboLastClick  = now
    comboPendingClick       = false
    startComboC0Lock()

    task.spawn(function()
        runComboSequencer(myToken)
    end)
end

local COMBO_HOLD_INTERVAL = 0.10

local function startComboListener()
    if flyanim.comboConn then flyanim.comboConn:Disconnect() end
    if flyanim.comboHoldConn then flyanim.comboHoldConn:Disconnect(); flyanim.comboHoldConn = nil end
    resetCombo()
    flyanim.comboPlaying = false
    flyanim.comboBusy    = false
    flyanim.combo4Frozen = false
    flyanim.comboToken   = 0
    flyanim.mouseHeld    = false
    comboPendingClick    = false

    flyanim.comboConn = UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe or isTyping() or not flyanim.enabled then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            flyanim.mouseHeld = true
            handleComboClick()
        end
    end)

    local comboEndConn
    comboEndConn = UserInputService.InputEnded:Connect(function(input, gpe)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            flyanim.mouseHeld = false
        end
    end)

    -- Hold: mientras se mantiene el botón presionado y el combo no está ocupado,
    -- registrar clicks periódicos (para encadenar sin soltar)
    local lastHoldFire = 0
    flyanim.comboHoldConn = RunService.Heartbeat:Connect(function()
        if not flyanim.enabled then return end
        if not flyanim.mouseHeld then return end
        if isTyping() then return end
        local now = tick()
        if now - lastHoldFire < COMBO_HOLD_INTERVAL then return end
        lastHoldFire = now
        -- Solo registrar si el combo ya está corriendo y espera un click
        if not flyanim.comboPlaying then return end
        if flyanim.comboBusy then return end
        if not comboPendingClick then
            comboPendingClick = true
            flyanim.comboLastClick = now
        end
    end)

    flyanim._comboEndConn = comboEndConn
end

local function stopComboListener()
    if flyanim.comboConn then flyanim.comboConn:Disconnect(); flyanim.comboConn = nil end
    if flyanim.comboHoldConn then flyanim.comboHoldConn:Disconnect(); flyanim.comboHoldConn = nil end
    if flyanim._comboEndConn then flyanim._comboEndConn:Disconnect(); flyanim._comboEndConn = nil end
    stopComboC0Lock()
    resetCombo()
    flyanim.comboPlaying = false
    flyanim.comboBusy    = false
    flyanim.combo4Frozen = false
    flyanim.mouseHeld    = false
    comboPendingClick    = false
end

-- ============================================================
-- MEGA TURBO UP
-- ============================================================

local function activateMegaTurboUp()
    if flyanim.megaTurboUpActive then return end
    if flyanim.mode == "turbo" then return end
    flyanim.megaTurboUpActive = true
    -- Cerrar brazos al instante si estaban abiertos
    if flyanim.isBrazosActive then
        flyanim.isBrazosActive = false
        flyanim.idleTimerAnim  = 0
        local ntMega = flyanim.normalTracks
        if ntMega.brazos and ntMega.brazos.IsPlaying then
            pcall(function() ntMega.brazos:Stop(0.05) end)
        end
    end
    stopParticleEmitter()
    shakeCamera(3.0, 0.5)
    playLocalSound(SFX_MEGA_TURBO, 0.90)
    sonicBoomEffect(2); airShockAura(2); speedWhiteFlash("turbo")
    local char = lplr.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if root then root.AssemblyLinearVelocity = Vector3.new(0, BASE_SPEED * TURBO_MULT * 0.8, 0) end
    if flyanim.updateMode then flyanim.updateMode("megaup") end
    task.spawn(function()
        local startT = tick()
        while flyanim.megaTurboUpActive and flyanim.enabled do
            if flyanim.bv and flyanim.bv.Parent then flyanim.speed = BASE_SPEED * TURBO_MULT end
            if tick() - startT > 4.0 then break end
            task.wait(0.05)
        end
        flyanim.megaTurboUpActive = false
        flyanim.speed = BASE_SPEED
        flyanim.mode  = "normal"
        if flyanim.updateMode then flyanim.updateMode("normal") end
    end)
end

local function startMegaTurboUpListener()
    if flyanim.megaTurboUpConn then flyanim.megaTurboUpConn:Disconnect(); flyanim.megaTurboUpConn = nil end
    flyanim.megaTurboUpConn = RunService.RenderStepped:Connect(function()
        if not flyanim.enabled then return end
        if isTyping() then return end
        if flyanim.turboPreImpulsoActivo then return end
        local spaceDown = UserInputService:IsKeyDown(Enum.KeyCode.Space)
        local modeOk = (flyanim.mode == "normal" or flyanim.mode == "fast") and not flyanim.megaTurboUpActive
        if spaceDown and modeOk then
            if not flyanim.spaceHoldStart then flyanim.spaceHoldStart = tick() end
            if tick() - flyanim.spaceHoldStart >= flyanim.SPACE_HOLD_TIME then
                flyanim.spaceHoldStart = nil
                activateMegaTurboUp()
            end
        else
            flyanim.spaceHoldStart = nil
            if flyanim.megaTurboUpActive and not spaceDown then
                flyanim.megaTurboUpActive = false
            end
        end
    end)
end

local function stopMegaTurboUpListener()
    if flyanim.megaTurboUpConn then flyanim.megaTurboUpConn:Disconnect(); flyanim.megaTurboUpConn = nil end
    flyanim.spaceHoldStart    = nil
    flyanim.megaTurboUpActive = false
end

-- ============================================================
-- SISTEMA DE LOCK
-- ============================================================

local function isTargetValidForLock(target)
    if not target then return false end
    local char = target.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return false end
    if hum.Health <= 0 then return false end
    if hum:GetState() == Enum.HumanoidStateType.Dead then return false end
    return true
end

local function getClosestLockTarget()
    local closestPlayer = nil
    local bestScore     = math.huge
    local myChar = lplr.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    for _, player in ipairs(Players:GetPlayers()) do
        if player == lplr then continue end
        if not isTargetValidForLock(player) then continue end
        local targetChar = player.Character
        if not targetChar then continue end
        local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
        if not targetRoot then continue end
        local screenPos, onScreen = camera:WorldToScreenPoint(targetRoot.Position)
        if not onScreen then continue end
        local mousePos  = UserInputService:GetMouseLocation()
        local screenDist = (Vector2.new(mousePos.X, mousePos.Y) - Vector2.new(screenPos.X, screenPos.Y)).Magnitude
        if screenDist > 300 then continue end
        local worldDist = myRoot and (myRoot.Position - targetRoot.Position).Magnitude or 0
        local score = screenDist + (worldDist * 0.2)
        if score < bestScore then bestScore = score; closestPlayer = player end
    end
    return closestPlayer
end

local function removeLockIcon()
    if flyanim.lockIconGui then pcall(function() flyanim.lockIconGui:Destroy() end); flyanim.lockIconGui = nil end
end

local function applyLockIcon(player)
    removeLockIcon()
    local chest = player.Character and player.Character:FindFirstChild("UpperTorso")
    local torso = chest or (player.Character and player.Character:FindFirstChild("HumanoidRootPart"))
    if not torso then return end
    flyanim.lockIconGui = Instance.new("BillboardGui", torso)
    flyanim.lockIconGui.Name          = "LockIcon"
    flyanim.lockIconGui.Size          = UDim2.new(0, 50, 0, 50)
    flyanim.lockIconGui.AlwaysOnTop   = true
    flyanim.lockIconGui.StudsOffset   = Vector3.new(0, 0, 0)
    local img = Instance.new("ImageLabel", flyanim.lockIconGui)
    img.Size = UDim2.new(1,0,1,0); img.BackgroundTransparency = 1
    img.Image = "rbxassetid://82817965256191"
    img.ImageColor3 = Color3.fromRGB(255,255,255); img.ScaleType = Enum.ScaleType.Fit
end

local function ensureLockHighlight()
    if not flyanim.lockHighlight then
        flyanim.lockHighlight = Instance.new("Highlight")
        flyanim.lockHighlight.FillTransparency    = 1
        flyanim.lockHighlight.OutlineColor        = Color3.fromRGB(255, 255, 255)
        flyanim.lockHighlight.OutlineTransparency = 0
    end
end

local function updateLockHighlight()
    if not flyanim.lockActive or not flyanim.lockedTarget then
        if flyanim.lockHighlight then flyanim.lockHighlight.Parent = nil end; return
    end
    if not isTargetValidForLock(flyanim.lockedTarget) then
        if flyanim.lockHighlight then flyanim.lockHighlight.Parent = nil end; return
    end
    ensureLockHighlight()
    local targetChar = flyanim.lockedTarget.Character
    if targetChar then flyanim.lockHighlight.Parent = targetChar
    else flyanim.lockHighlight.Parent = nil end
end

local function loadAvatarImage()
    if not flyanim.lockInfoGui then return end
    local playerImg = flyanim.lockInfoGui:FindFirstChild("PlayerImage", true)
    if not playerImg then return end
    if flyanim.lockActive and flyanim.lockedTarget then
        local userId = flyanim.lockedTarget.UserId
        task.spawn(function()
            local success, content = pcall(function()
                return Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.AvatarBust, Enum.ThumbnailSize.Size420x420)
            end)
            if success and content then playerImg.Image = content end
        end)
    end
end

local function createLockInfoGui(parentFrame)
    if flyanim.lockInfoGui then pcall(function() flyanim.lockInfoGui:Destroy() end); flyanim.lockInfoGui = nil end
    local C_PURPLE = Color3.fromRGB(110,30,180); local C_BLACK = Color3.fromRGB(6,4,12)
    local C_TEXT   = Color3.fromRGB(220,190,255)
    local infoFrame = Instance.new("Frame")
    infoFrame.Name = "LockInfoPanel"; infoFrame.Size = UDim2.new(0, 220, 0, 95)
    infoFrame.Position = UDim2.new(1, 12, 0, 8); infoFrame.BackgroundColor3 = C_BLACK
    infoFrame.BackgroundTransparency = 0.15; infoFrame.BorderSizePixel = 0
    infoFrame.ZIndex = 10; infoFrame.Visible = false; infoFrame.Parent = parentFrame
    Instance.new("UICorner", infoFrame).CornerRadius = UDim.new(0,8)
    local stroke = Instance.new("UIStroke", infoFrame)
    stroke.Color = C_PURPLE; stroke.Thickness = 1; stroke.Transparency = 0.5
    local iconLbl = Instance.new("TextLabel", infoFrame)
    iconLbl.Size=UDim2.new(0,24,0,24); iconLbl.Position=UDim2.new(0,8,0.5,-12)
    iconLbl.BackgroundTransparency=1; iconLbl.Font=Enum.Font.GothamBold
    iconLbl.TextSize=18; iconLbl.TextColor3=Color3.fromRGB(255,220,80); iconLbl.Text="🎯"; iconLbl.ZIndex=11
    local nameLabel = Instance.new("TextLabel", infoFrame)
    nameLabel.Name="NameLabel"; nameLabel.Size=UDim2.new(0,120,0,20); nameLabel.Position=UDim2.new(0,40,0,6)
    nameLabel.BackgroundTransparency=1; nameLabel.Font=Enum.Font.GothamBold
    nameLabel.TextSize=12; nameLabel.TextColor3=C_TEXT; nameLabel.Text="---"; nameLabel.TextXAlignment=Enum.TextXAlignment.Left
    local distLabel = Instance.new("TextLabel", infoFrame)
    distLabel.Name="DistLabel"; distLabel.Size=UDim2.new(0,120,0,18); distLabel.Position=UDim2.new(0,40,0,28)
    distLabel.BackgroundTransparency=1; distLabel.Font=Enum.Font.Gotham
    distLabel.TextSize=10; distLabel.TextColor3=Color3.fromRGB(200,170,255); distLabel.Text="--- studs"; distLabel.TextXAlignment=Enum.TextXAlignment.Left
    local healthLabel = Instance.new("TextLabel", infoFrame)
    healthLabel.Name="HealthLabel"; healthLabel.Size=UDim2.new(0,120,0,18); healthLabel.Position=UDim2.new(0,40,0,48)
    healthLabel.BackgroundTransparency=1; healthLabel.Font=Enum.Font.Gotham
    healthLabel.TextSize=10; healthLabel.TextColor3=Color3.fromRGB(255,150,150); healthLabel.Text="❤️ --- HP"; healthLabel.TextXAlignment=Enum.TextXAlignment.Left
    local heightLabel = Instance.new("TextLabel", infoFrame)
    heightLabel.Name="HeightLabel"; heightLabel.Size=UDim2.new(0,120,0,15); heightLabel.Position=UDim2.new(0,40,0,68)
    heightLabel.BackgroundTransparency=1; heightLabel.Font=Enum.Font.Gotham
    heightLabel.TextSize=9; heightLabel.TextColor3=Color3.fromRGB(150,220,255); heightLabel.Text="↕ ---"; heightLabel.TextXAlignment=Enum.TextXAlignment.Left
    local playerImgContainer = Instance.new("Frame", infoFrame)
    playerImgContainer.Name="PlayerImgContainer"; playerImgContainer.Size=UDim2.new(0,55,0,55)
    playerImgContainer.Position=UDim2.new(1,-65,0,20); playerImgContainer.BackgroundColor3=Color3.fromRGB(20,10,40)
    playerImgContainer.BackgroundTransparency=0.3; playerImgContainer.BorderSizePixel=0; playerImgContainer.ZIndex=11
    Instance.new("UICorner", playerImgContainer).CornerRadius = UDim.new(1,0)
    local playerImg = Instance.new("ImageLabel", playerImgContainer)
    playerImg.Name="PlayerImage"; playerImg.Size=UDim2.new(1,0,1,0); playerImg.Position=UDim2.new(0,0,0,0)
    playerImg.BackgroundTransparency=1; playerImg.Image=""; playerImg.ZIndex=12
    Instance.new("UICorner", playerImg).CornerRadius = UDim.new(1,0)
    flyanim.lockInfoGui = infoFrame
end

local function updateLockInfoGui()
    if not flyanim.lockInfoGui then return end
    if flyanim.lockActive and flyanim.lockedTarget and flyanim.lockedTarget.Character and isTargetValidForLock(flyanim.lockedTarget) then
        flyanim.lockInfoGui.Visible = true
        local root     = flyanim.lockedTarget.Character:FindFirstChild("HumanoidRootPart")
        local humanoid = flyanim.lockedTarget.Character:FindFirstChildOfClass("Humanoid")
        local myChar   = lplr.Character
        local myRoot   = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if root then
            local dist = (camera.CFrame.Position - root.Position).Magnitude
            local displayName = flyanim.lockedTarget.DisplayName
            if #displayName > 14 then displayName = displayName:sub(1,12)..".." end
            local nameLabel = flyanim.lockInfoGui:FindFirstChild("NameLabel")
            if nameLabel then nameLabel.Text = displayName end
            local distLabel = flyanim.lockInfoGui:FindFirstChild("DistLabel")
            if distLabel then distLabel.Text = math.floor(dist).." studs" end
            local healthLabel = flyanim.lockInfoGui:FindFirstChild("HealthLabel")
            if healthLabel and humanoid then
                local health    = math.floor(humanoid.Health)
                local maxHealth = humanoid.MaxHealth
                healthLabel.Text = "❤️ "..health.."/"..maxHealth.." HP"
                if health < 30 then healthLabel.TextColor3 = Color3.fromRGB(255,80,80)
                elseif health < 60 then healthLabel.TextColor3 = Color3.fromRGB(255,200,80)
                else healthLabel.TextColor3 = Color3.fromRGB(80,255,80) end
            end
            local heightLabel = flyanim.lockInfoGui:FindFirstChild("HeightLabel")
            if heightLabel and myRoot then
                -- heightDiff: positivo = target está MÁS ABAJO que yo = él está abajo
                --             negativo = target está MÁS ARRIBA que yo = él está arriba
                local heightDiff = math.floor(myRoot.Position.Y - root.Position.Y)
                if heightDiff > 0 then
                    -- Yo estoy arriba → el target está abajo de mí (ventaja)
                    heightLabel.Text = "↓ "..heightDiff.." "..FT.height_below
                    heightLabel.TextColor3 = Color3.fromRGB(150,220,255)   -- azul: ventaja
                elseif heightDiff < 0 then
                    -- Yo estoy abajo → el target está arriba de mí (peligro)
                    heightLabel.Text = "↑ "..math.abs(heightDiff).." "..FT.height_above
                    heightLabel.TextColor3 = Color3.fromRGB(255,200,100)   -- naranja: peligro
                    -- TP automático: si el target está por encima de mí y la
                    -- distancia circular (XZ) es <= 50 studs, teletransportarse
                    -- a su lado para no quedar atrapado bajo él.
                    if flyanim.enabled then
                        local myChar2 = lplr.Character
                        local myRoot2 = myChar2 and myChar2:FindFirstChild("HumanoidRootPart")
                        if myRoot2 then
                            local horDist = Vector3.new(
                                root.Position.X - myRoot2.Position.X,
                                0,
                                root.Position.Z - myRoot2.Position.Z
                            ).Magnitude
                            if horDist <= 50 then
                                -- Posicionarse al lado del target (3 studs detrás de él)
                                local toTarget = (root.Position - myRoot2.Position)
                                local toTargetH = Vector3.new(toTarget.X, 0, toTarget.Z)
                                local behindDir = toTargetH.Magnitude > 0.1
                                    and -toTargetH.Unit
                                    or Vector3.new(0, 0, 1)
                                local tpPos = root.Position + behindDir * 3
                                pcall(function()
                                    myRoot2.CFrame = CFrame.new(tpPos, root.Position)
                                end)
                            end
                        end
                    end
                else
                    heightLabel.Text = FT.height_same
                    heightLabel.TextColor3 = Color3.fromRGB(150,255,150)
                end
            end
        end
        loadAvatarImage()
    else
        flyanim.lockInfoGui.Visible = false
        if flyanim.lockActive and flyanim.lockedTarget and not isTargetValidForLock(flyanim.lockedTarget) then
            flyanim.lockActive   = false
            flyanim.lockedTarget = nil
            removeLockIcon()
            updateLockHighlight()
        end
    end
end

local function updateLockCamera()
    if not flyanim.lockActive or not flyanim.lockedTarget then return end
    local targetChar = flyanim.lockedTarget.Character
    if not targetChar then flyanim.lockActive = false; flyanim.lockedTarget = nil; removeLockIcon(); updateLockHighlight(); return end
    if not isTargetValidForLock(flyanim.lockedTarget) then
        flyanim.lockActive = false; flyanim.lockedTarget = nil; removeLockIcon(); updateLockHighlight(); return
    end
    local myRoot     = lplr.Character and lplr.Character:FindFirstChild("HumanoidRootPart")
    local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
    if myRoot and targetRoot and (myRoot.Position - targetRoot.Position).Magnitude > 750 then
        flyanim.lockActive = false; flyanim.lockedTarget = nil; removeLockIcon(); updateLockHighlight(); return
    end
    local targetPart = targetChar:FindFirstChild("UpperTorso") or targetChar:FindFirstChild("HumanoidRootPart")
    if not targetPart then return end
    local worldDist  = myRoot and (myRoot.Position - targetPart.Position).Magnitude or 999
    local currentPos = camera.CFrame.Position
    local desiredCF  = CFrame.new(currentPos, targetPart.Position)
    local lerpFactor = flyanim.lockCameraLerp
    if worldDist < 8  then lerpFactor = lerpFactor * 0.25
    elseif worldDist < 20 then lerpFactor = lerpFactor * 0.6 end
    camera.CFrame = camera.CFrame:Lerp(desiredCF, lerpFactor)
end

local function toggleLock()
    if not flyanim.enabled then return end
    if not flyanim.lockActive then
        local found = getClosestLockTarget()
        if found and isTargetValidForLock(found) then
            flyanim.lockedTarget = found
            flyanim.lockActive   = true
            applyLockIcon(found)
            updateLockHighlight()
            loadAvatarImage()
        end
    else
        flyanim.lockActive   = false
        flyanim.lockedTarget = nil
        removeLockIcon()
        updateLockHighlight()
    end
end

local function startLockSystem()
    local lockConn = UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe or isTyping() then return end
        if input.KeyCode == flyanim.lockKey then toggleLock() end
    end)
    local lockRenderConn = RunService.RenderStepped:Connect(function()
        updateLockInfoGui()
        updateLockCamera()
        updateLockHighlight()
    end)
    flyanim.lockConn       = lockConn
    flyanim.lockRenderConn = lockRenderConn
end

local function stopLockSystem()
    if flyanim.lockConn       then flyanim.lockConn:Disconnect();       flyanim.lockConn = nil end
    if flyanim.lockRenderConn then flyanim.lockRenderConn:Disconnect(); flyanim.lockRenderConn = nil end
    flyanim.lockActive   = false
    flyanim.lockedTarget = nil
    removeLockIcon()
    updateLockHighlight()
    if flyanim.lockInfoGui then pcall(function() flyanim.lockInfoGui:Destroy() end); flyanim.lockInfoGui = nil end
    if flyanim.lockHighlight then pcall(function() flyanim.lockHighlight:Destroy() end); flyanim.lockHighlight = nil end
end

-- ============================================================
-- GUI
-- ============================================================

local function _flyDestroyGui()
    if flyanim.pulse then pcall(function() task.cancel(flyanim.pulse) end); flyanim.pulse = nil end
    flyanim.expanded = false; flyanim.updateLbl = nil; flyanim.updateMode = nil
    if flyanim.gui then pcall(function() flyanim.gui:Destroy() end); flyanim.gui = nil end
    flyanim.lockInfoGui = nil
end

local function createToggle(parent, xPos, yPos, initialState, onChange)
    local switchWidth = 36; local switchHeight = 18; local knobSize = 14
    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(0, switchWidth, 0, switchHeight); bg.Position = UDim2.new(0, xPos, 0, yPos)
    bg.BackgroundColor3 = initialState and Color3.fromRGB(80,200,80) or Color3.fromRGB(80,80,80)
    bg.BorderSizePixel = 0; bg.Parent = parent
    Instance.new("UICorner", bg).CornerRadius = UDim.new(1,0)
    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, knobSize, 0, knobSize)
    knob.Position = initialState and UDim2.new(1,-knobSize-2,0.5,-knobSize/2) or UDim2.new(0,2,0.5,-knobSize/2)
    knob.BackgroundColor3 = Color3.fromRGB(255,255,255); knob.BorderSizePixel = 0; knob.Parent = bg
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1,0)
    local state  = initialState
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1,0,1,0); button.BackgroundTransparency = 1; button.Text = ""; button.Parent = bg
    button.MouseButton1Click:Connect(function()
        state = not state
        TweenService:Create(bg, TweenInfo.new(0.1, Enum.EasingStyle.Quad),
            {BackgroundColor3 = state and Color3.fromRGB(80,200,80) or Color3.fromRGB(80,80,80)}):Play()
        TweenService:Create(knob, TweenInfo.new(0.1, Enum.EasingStyle.Quad),
            {Position = state and UDim2.new(1,-knobSize-2,0.5,-knobSize/2) or UDim2.new(0,2,0.5,-knobSize/2)}):Play()
        if onChange then onChange(state) end
    end)
    return bg
end

local function _flyBuildGui()
    _reloadFT()  -- resincronizar idioma con el hub antes de construir la GUI
    _flyDestroyGui()
    local C_PURPLE = Color3.fromRGB(110,30,180); local C_DIM  = Color3.fromRGB(40,6,72)
    local C_BLACK  = Color3.fromRGB(6,4,12);    local C_ACCENT = Color3.fromRGB(160,60,255)
    local C_TEXT   = Color3.fromRGB(220,190,255); local C_GREEN = Color3.fromRGB(80,255,150)
    local C_YELLOW = Color3.fromRGB(255,220,60); local C_RED   = Color3.fromRGB(255,80,80)
    local C_CYAN   = Color3.fromRGB(80,200,255)
    local W = 280; local H_MINI = 48; local DOT_SIZE = 10

    -- noclipSec ahora tiene 3 filas (Espacio, Ctrl, Mega Turbo): 16 título + 3×20 filas + 6 padding = 82
    local CONTENT_H = 8 + 30 + 6 + 82 + 6 + 104 + 8
    local H_FULL = H_MINI + CONTENT_H

    local TW = TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    local sg = Instance.new("ScreenGui")
    sg.Name="AFO_FlyHUD"; sg.ResetOnSpawn=false; sg.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
    sg.IgnoreGuiInset=true; sg.Parent=CoreGui; flyanim.gui=sg
    local root = Instance.new("Frame", sg)
    root.Size=UDim2.new(0,W,0,H_FULL); root.Position=UDim2.new(0.5,-W/2,0,6)
    root.BackgroundTransparency=1; root.BorderSizePixel=0
    local panel = Instance.new("Frame", root)
    panel.Size=UDim2.new(1,0,0,H_MINI); panel.BackgroundColor3=C_BLACK
    panel.BackgroundTransparency=0.06; panel.BorderSizePixel=0
    Instance.new("UICorner", panel).CornerRadius=UDim.new(0,12)
    local stroke = Instance.new("UIStroke", panel)
    stroke.Color=C_PURPLE; stroke.Thickness=1.2; stroke.Transparency=0.75
    local topBar = Instance.new("Frame", panel)
    topBar.Size=UDim2.new(1,0,0,H_MINI); topBar.BackgroundTransparency=1
    local iconLbl = Instance.new("TextLabel", topBar)
    iconLbl.Size=UDim2.new(0,28,1,0); iconLbl.Position=UDim2.new(0,8,0,0)
    iconLbl.BackgroundTransparency=1; iconLbl.Font=Enum.Font.GothamBold
    iconLbl.TextSize=14; iconLbl.TextColor3=C_ACCENT; iconLbl.Text="🚀"; iconLbl.TextXAlignment=Enum.TextXAlignment.Center
    local titleLbl = Instance.new("TextLabel", topBar)
    titleLbl.Size=UDim2.new(0,75,1,0); titleLbl.Position=UDim2.new(0,34,0,0)
    titleLbl.BackgroundTransparency=1; titleLbl.Font=Enum.Font.GothamBold
    titleLbl.TextSize=12; titleLbl.TextColor3=C_TEXT
    titleLbl.Text=FT.fly_title.." ["..flyanim.flyKey.Name.."]"; titleLbl.TextXAlignment=Enum.TextXAlignment.Left
    local sep = Instance.new("Frame", topBar)
    sep.Size=UDim2.new(0,1,0,22); sep.Position=UDim2.new(0,113,0.5,-11)
    sep.BackgroundColor3=C_PURPLE; sep.BackgroundTransparency=0.4
    local modeLbl = Instance.new("TextLabel", topBar)
    modeLbl.Size=UDim2.new(1,-134,1,0); modeLbl.Position=UDim2.new(0,119,0,0)
    modeLbl.BackgroundTransparency=1; modeLbl.Font=Enum.Font.GothamBold
    modeLbl.TextSize=12; modeLbl.TextColor3=C_GREEN; modeLbl.Text=FT.mode_normal; modeLbl.TextXAlignment=Enum.TextXAlignment.Center
    local dotBtn = Instance.new("TextButton", topBar)
    dotBtn.Size=UDim2.new(0,DOT_SIZE+10,1,0); dotBtn.Position=UDim2.new(1,-(DOT_SIZE+14),0,0)
    dotBtn.BackgroundTransparency=1; dotBtn.Text=""
    local dot = Instance.new("Frame", dotBtn)
    dot.Size=UDim2.new(0,DOT_SIZE,0,DOT_SIZE); dot.Position=UDim2.new(0.5,-DOT_SIZE/2,0.5,-DOT_SIZE/2)
    dot.BackgroundColor3=C_ACCENT; Instance.new("UICorner", dot).CornerRadius=UDim.new(1,0)

    local expandZone = Instance.new("Frame", panel)
    expandZone.Size=UDim2.new(1,-16,0,CONTENT_H); expandZone.Position=UDim2.new(0,8,0,H_MINI)
    expandZone.BackgroundColor3=C_DIM; expandZone.BackgroundTransparency=0.3
    expandZone.BorderSizePixel=0; expandZone.Visible=false
    Instance.new("UICorner", expandZone).CornerRadius=UDim.new(0,8)
    local exStroke = Instance.new("UIStroke", expandZone)
    exStroke.Color=C_PURPLE; exStroke.Thickness=1; exStroke.Transparency=0.55

    local layout = Instance.new("UIListLayout", expandZone)
    layout.Padding=UDim.new(0,6); layout.SortOrder=Enum.SortOrder.LayoutOrder; layout.HorizontalAlignment=Enum.HorizontalAlignment.Center

    local topSpacer = Instance.new("Frame")
    topSpacer.Size=UDim2.new(1,0,0,5); topSpacer.BackgroundTransparency=1; topSpacer.BorderSizePixel=0; topSpacer.Parent=expandZone

    local function makeSection(h)
        local f = Instance.new("Frame")
        f.Size=UDim2.new(1,-20,0,h); f.BackgroundColor3=Color3.fromRGB(30,10,50); f.BackgroundTransparency=0.3
        Instance.new("UICorner", f).CornerRadius=UDim.new(0,6)
        local s = Instance.new("UIStroke", f); s.Color=C_ACCENT; s.Thickness=1; s.Transparency=0.6
        return f
    end

    local lockSec = makeSection(30); lockSec.Parent=expandZone
    local lockIconImg = Instance.new("TextLabel", lockSec)
    lockIconImg.Size=UDim2.new(0,24,0,24); lockIconImg.Position=UDim2.new(0,6,0.5,-12)
    lockIconImg.BackgroundTransparency=1; lockIconImg.Font=Enum.Font.GothamBold
    lockIconImg.TextSize=16; lockIconImg.TextColor3=Color3.fromRGB(255,220,80); lockIconImg.Text="🎯"
    local lockLabel = Instance.new("TextLabel", lockSec)
    lockLabel.Size=UDim2.new(0,80,1,0); lockLabel.Position=UDim2.new(0,34,0,0)
    lockLabel.BackgroundTransparency=1; lockLabel.Font=Enum.Font.GothamBold
    lockLabel.TextSize=11; lockLabel.TextColor3=C_TEXT
    lockLabel.Text=FT.lock_label.." ["..flyanim.lockKey.Name.."]"; lockLabel.TextXAlignment=Enum.TextXAlignment.Left
    local lockHint = Instance.new("TextLabel", lockSec)
    lockHint.Size=UDim2.new(1,-100,1,0); lockHint.Position=UDim2.new(0,95,0,0)
    lockHint.BackgroundTransparency=1; lockHint.Font=Enum.Font.Gotham
    lockHint.TextSize=9; lockHint.TextColor3=Color3.fromRGB(150,120,200)
    lockHint.Text=FT.lock_hint_prefix..flyanim.lockKey.Name; lockHint.TextXAlignment=Enum.TextXAlignment.Right
    flyanim.lockLabels = { label = lockLabel, hint = lockHint }

    local noclipSec = makeSection(82); noclipSec.Parent=expandZone
    local noclipTitle = Instance.new("TextLabel", noclipSec)
    noclipTitle.Size=UDim2.new(1,-12,0,16); noclipTitle.Position=UDim2.new(0,6,0,2)
    noclipTitle.BackgroundTransparency=1; noclipTitle.Font=Enum.Font.GothamBold
    noclipTitle.TextSize=11; noclipTitle.TextColor3=C_TEXT; noclipTitle.Text=FT.noclip_title; noclipTitle.TextXAlignment=Enum.TextXAlignment.Left
    -- Fila 1: Espacio (subir)
    local spaceRow = Instance.new("Frame", noclipSec)
    spaceRow.Size=UDim2.new(1,-12,0,20); spaceRow.Position=UDim2.new(0,6,0,18); spaceRow.BackgroundTransparency=1
    local spaceLabel = Instance.new("TextLabel", spaceRow)
    spaceLabel.Size=UDim2.new(0,88,1,0); spaceLabel.BackgroundTransparency=1; spaceLabel.Font=Enum.Font.Gotham
    spaceLabel.TextSize=10; spaceLabel.TextColor3=C_TEXT; spaceLabel.Text=FT.noclip_space; spaceLabel.TextXAlignment=Enum.TextXAlignment.Left
    createToggle(spaceRow, 146, 1, flyanim.noclipSpaceEnabled, function(state) flyanim.noclipSpaceEnabled = state end)
    -- Fila 2: Ctrl (bajar) - noclip dedicado al movimiento hacia abajo
    local ctrlRow = Instance.new("Frame", noclipSec)
    ctrlRow.Size=UDim2.new(1,-12,0,20); ctrlRow.Position=UDim2.new(0,6,0,40); ctrlRow.BackgroundTransparency=1
    local ctrlLabel = Instance.new("TextLabel", ctrlRow)
    ctrlLabel.Size=UDim2.new(0,88,1,0); ctrlLabel.BackgroundTransparency=1; ctrlLabel.Font=Enum.Font.Gotham
    ctrlLabel.TextSize=10; ctrlLabel.TextColor3=C_TEXT; ctrlLabel.Text=FT.noclip_ctrl; ctrlLabel.TextXAlignment=Enum.TextXAlignment.Left
    createToggle(ctrlRow, 146, 1, flyanim.noclipCtrlEnabled, function(state) flyanim.noclipCtrlEnabled = state end)
    -- Fila 3: Mega Turbo
    local megaRow = Instance.new("Frame", noclipSec)
    megaRow.Size=UDim2.new(1,-12,0,20); megaRow.Position=UDim2.new(0,6,0,62); megaRow.BackgroundTransparency=1
    local megaLabel = Instance.new("TextLabel", megaRow)
    megaLabel.Size=UDim2.new(0,88,1,0); megaLabel.BackgroundTransparency=1; megaLabel.Font=Enum.Font.Gotham
    megaLabel.TextSize=10; megaLabel.TextColor3=C_TEXT; megaLabel.Text=FT.noclip_mega; megaLabel.TextXAlignment=Enum.TextXAlignment.Left
    createToggle(megaRow, 146, 1, flyanim.noclipMegaEnabled, function(state) flyanim.noclipMegaEnabled = state end)

    local speedSec = makeSection(104); speedSec.BackgroundColor3=Color3.fromRGB(25,12,55); speedSec.Parent=expandZone
    local speedStroke = Instance.new("UIStroke", speedSec); speedStroke.Color=C_PURPLE; speedStroke.Thickness=1; speedStroke.Transparency=0.6

    local function makeRow(labelText, yPos, defaultVal, minVal, maxVal)
        local lbl = Instance.new("TextLabel", speedSec)
        lbl.Size=UDim2.new(0,88,0,18); lbl.Position=UDim2.new(0,8,0,yPos)
        lbl.BackgroundTransparency=1; lbl.Font=Enum.Font.GothamSemibold; lbl.TextSize=10; lbl.TextColor3=C_TEXT
        lbl.Text=labelText; lbl.TextXAlignment=Enum.TextXAlignment.Left
        local box = Instance.new("TextBox", speedSec)
        box.Size=UDim2.new(1,-100,0,18); box.Position=UDim2.new(0,94,0,yPos)
        box.BackgroundColor3=Color3.fromRGB(18,6,32); box.BackgroundTransparency=0.05; box.BorderSizePixel=0
        box.Font=Enum.Font.GothamBold; box.TextSize=10; box.TextColor3=C_ACCENT; box.Text=tostring(defaultVal); box.ClearTextOnFocus=true
        Instance.new("UICorner", box).CornerRadius=UDim.new(0,4)
        local bs = Instance.new("UIStroke", box); bs.Color=C_ACCENT; bs.Thickness=1; bs.Transparency=0.55
        box:GetPropertyChangedSignal("Text"):Connect(function()
            local n = tonumber(box.Text:match("[%d%.]+"))
            if n then n = math.clamp(n, minVal, maxVal); box.Text = tostring(n) end
        end)
        return box
    end

    local speedBox = makeRow(FT.speed_base,       6,  BASE_SPEED,  1, 10000)
    local fastBox  = makeRow(FT.speed_turbo_mult, 30, FAST_MULT,   1, 1000)
    local turboBox = makeRow(FT.speed_mega_mult,  54, TURBO_MULT,  1, 1000)

    local resetBtn = Instance.new("TextButton", speedSec)
    resetBtn.Size=UDim2.new(0,90,0,20); resetBtn.Position=UDim2.new(0.5,-45,0,82)
    resetBtn.BackgroundColor3=Color3.fromRGB(60,10,110); resetBtn.BackgroundTransparency=0.2
    resetBtn.BorderSizePixel=0; resetBtn.Font=Enum.Font.GothamBold; resetBtn.TextSize=10
    resetBtn.TextColor3=C_TEXT; resetBtn.Text=FT.speed_reset
    Instance.new("UICorner", resetBtn).CornerRadius=UDim.new(0,5)

    local function recalcSpeed()
        if flyanim.mode == "normal"     then flyanim.speed = BASE_SPEED
        elseif flyanim.mode == "fast"   then flyanim.speed = BASE_SPEED * FAST_MULT
        elseif flyanim.mode == "turbo"  then flyanim.speed = BASE_SPEED * TURBO_MULT end
    end
    speedBox.FocusLost:Connect(function()
        local n = tonumber(speedBox.Text:match("[%d%.]+"))
        if n then BASE_SPEED = math.clamp(math.floor(n+0.5), 1, 10000) end
        speedBox.Text = tostring(BASE_SPEED); recalcSpeed()
    end)
    fastBox.FocusLost:Connect(function()
        local n = tonumber(fastBox.Text:match("[%d%.]+"))
        if n then FAST_MULT = math.clamp(n, 1, 1000) end
        fastBox.Text = tostring(FAST_MULT); recalcSpeed()
        if flyanim.updateMode then flyanim.updateMode(flyanim.mode) end
    end)
    turboBox.FocusLost:Connect(function()
        local n = tonumber(turboBox.Text:match("[%d%.]+"))
        if n then TURBO_MULT = math.clamp(n, 1, 1000) end
        turboBox.Text = tostring(TURBO_MULT); recalcSpeed()
        if flyanim.updateMode then flyanim.updateMode(flyanim.mode) end
    end)
    resetBtn.MouseButton1Click:Connect(function()
        BASE_SPEED = DEFAULT_BASE; FAST_MULT = DEFAULT_FAST; TURBO_MULT = DEFAULT_TURBO
        speedBox.Text = tostring(BASE_SPEED); fastBox.Text = tostring(FAST_MULT); turboBox.Text = tostring(TURBO_MULT)
        recalcSpeed(); if flyanim.updateMode then flyanim.updateMode(flyanim.mode) end
        TweenService:Create(resetBtn, TweenInfo.new(0.1), {TextColor3=C_GREEN}):Play()
        task.delay(0.5, function() pcall(function() TweenService:Create(resetBtn, TweenInfo.new(0.3), {TextColor3=C_TEXT}):Play() end) end)
    end)

    local pulseRunning = false
    local function startPulse()
        if pulseRunning then return end
        pulseRunning = true
        flyanim.pulse = task.spawn(function()
            while flyanim.gui and flyanim.gui.Parent and flyanim.expanded do
                TweenService:Create(stroke, TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                    {Thickness=2.5, Color=C_ACCENT, Transparency=0}):Play()
                task.wait(0.7)
                if not (flyanim.gui and flyanim.gui.Parent and flyanim.expanded) then break end
                TweenService:Create(stroke, TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                    {Thickness=1.5, Color=C_PURPLE, Transparency=0.35}):Play()
                task.wait(0.7)
            end
            pcall(function() stroke.Thickness=1.2; stroke.Color=C_PURPLE; stroke.Transparency=0.75 end)
            pulseRunning=false; flyanim.pulse=nil
        end)
    end

    local function setExpanded(state)
        flyanim.expanded=state; expandZone.Visible=state
        local h = state and H_FULL or H_MINI
        root.Size = UDim2.new(0,W,0,h)
        TweenService:Create(panel, TW, {Size=UDim2.new(1,0,0,h)}):Play()
        TweenService:Create(dot, TweenInfo.new(0.2, Enum.EasingStyle.Quad),
            {BackgroundTransparency=state and 0 or 0.35}):Play()
        TweenService:Create(dot, TweenInfo.new(0.2, Enum.EasingStyle.Quad),
            {Size = state and UDim2.new(0,DOT_SIZE,0,DOT_SIZE) or UDim2.new(0,DOT_SIZE-3,0,DOT_SIZE-3),
             Position = state and UDim2.new(0.5,-DOT_SIZE/2,0.5,-DOT_SIZE/2) or UDim2.new(0.5,-(DOT_SIZE-3)/2,0.5,-(DOT_SIZE-3)/2)}):Play()
        if state then startPulse()
        else
            if flyanim.pulse then pcall(function() task.cancel(flyanim.pulse) end); flyanim.pulse=nil; pulseRunning=false
                pcall(function() stroke.Thickness=1.2; stroke.Color=C_PURPLE; stroke.Transparency=0.75 end)
            end
        end
    end

    dotBtn.MouseButton1Click:Connect(function() setExpanded(not flyanim.expanded) end)

    local dragging=false; local dragStartMouse=Vector2.new(); local dragStartPos=UDim2.new()
    topBar.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
            dragging=true; dragStartMouse=Vector2.new(inp.Position.X,inp.Position.Y); dragStartPos=root.Position
        end
    end)
    topBar.InputEnded:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then dragging=false end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if not dragging then return end
        if inp.UserInputType~=Enum.UserInputType.MouseMovement and inp.UserInputType~=Enum.UserInputType.Touch then return end
        local delta = Vector2.new(inp.Position.X,inp.Position.Y) - dragStartMouse
        root.Position = UDim2.new(dragStartPos.X.Scale, dragStartPos.X.Offset+delta.X, dragStartPos.Y.Scale, dragStartPos.Y.Offset+delta.Y)
    end)

    flyanim.updateLbl  = function(keyName) pcall(function() titleLbl.Text=FT.fly_title.." ["..keyName.."]" end) end
    flyanim.updateMode = function(modeName)
        pcall(function()
            local multF = math.floor(FAST_MULT*10+0.5)/10
            local multT = math.floor(TURBO_MULT*10+0.5)/10
            local labels  = { normal=FT.mode_normal, fast=FT.mode_fast..tostring(multF), turbo=FT.mode_mega..tostring(multT), megaup=FT.mode_megaup..tostring(multT) }
            local colors   = { normal=C_GREEN, fast=C_YELLOW, turbo=C_RED, megaup=C_CYAN }
            local dotColors = { normal=C_ACCENT, fast=C_YELLOW, turbo=C_RED, megaup=C_CYAN }
            modeLbl.Text = labels[modeName] or modeName
            modeLbl.TextColor3 = colors[modeName] or C_GREEN
            TweenService:Create(dot, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {BackgroundColor3=dotColors[modeName] or C_ACCENT}):Play()
        end)
    end

    createLockInfoGui(root)
end

-- ============================================================
-- FLY ON / OFF
-- ============================================================

local function _flyOn()
    local char = lplr.Character; if not char then return end
    -- Cancelar caída épica al instante: desconectar landConn y limpiar estado
    if flyanim.landConn then flyanim.landConn:Disconnect(); flyanim.landConn = nil end
    stopLandingWatcher()
    flyanim.waitingLand = false
    flyanim.landingHeight = nil
    flyanim.landingVelocity = 0; flyanim.landingVelocityCapture = 0
    -- CAMBIO SALVAJE: matar animación de caída épica si está corriendo
    _landAnimToken = _landAnimToken + 1
    if _landBaseRef and pcall(function() _landBaseRef:Stop(0) end) then end
    if _landOverlayRef and pcall(function() _landOverlayRef:Stop(0) end) then end
    _landBaseRef = nil; _landOverlayRef = nil
    -- Cancelar cualquier tween de compensación de altura en curso
    heightTweenToken = heightTweenToken + 1
    -- Nueva sesion de vuelo: incrementar sessionToken para que los guards
    -- que inicien ahora tengan un token fresco y no colisionen con restos
    -- de una sesion anterior que pudo quedar en un tick de transicion.
    flyanim.sessionToken = (flyanim.sessionToken or 0) + 1
    flyanim.enabled = true
    flyanim.mode = "normal"; flyanim.speed = BASE_SPEED
    flyanim.wDown=false; flyanim.sDown=false; flyanim.aDown=false; flyanim.dDown=false
    flyanim.isWDown=false; flyanim.isSDown=false; flyanim.isADown=false; flyanim.isDDown=false
    flyanim.isMoving=false; flyanim.megaTurboUpActive=false; flyanim.spaceHoldStart=nil
    flyanim.gyroProtectionActive=false; flyanim.turboPreImpulsoActivo=false
    flyanim.turboPreImpulsoToken=0; flyanim.c0ControlToken=0; flyanim.c0HeightToken=0
    flyanim.noclipSpaceActive = false; flyanim.lastKnownPos = nil
    flyanim.ragdollDetected = false
    flyanim.fKeyHeld = false; flyanim.blockCancelledByCombo = false
    flyanim.lastSafePos = nil; flyanim.lastSafeTime = tick()
    if flyanim.gyroProtectionTimer then task.cancel(flyanim.gyroProtectionTimer) end
    if flyanim.backupGyro then flyanim.backupGyro:Destroy(); flyanim.backupGyro=nil end
    flyanim.isBlocking=false; flyanim.isSpaceAdv=false; flyanim._normalPlayId=0
    flyanim.lastDamageTime = 0; flyanim.mouseHeld = false; flyanim.comboAnimStartTime = 0
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
        hum.PlatformStand = false
        -- NO llamar GettingUp aquí: empuja hacia arriba antes de que existan
        -- los motores de vuelo, causando el rebote. _flyMakeMotors ancla la física.
    end
    -- Limpiar tracks de la sesión anterior (doLanding puede haber dejado
    -- flyanim.tracks={} y normalTracks con referencias muertas).
    -- Parar todo lo que aún esté sonando antes de reconstruir el animator.
    for _, t in pairs(flyanim.normalTracks) do pcall(function() if t and t.IsPlaying then t:Stop(0) end end) end
    flyanim.normalTracks = {}
    for _, t in pairs(flyanim.tracks) do pcall(function() if t and t.IsPlaying then t:Stop(0) end end) end
    flyanim.tracks = {}
    setupAnimator(char)
    _flyMakeMotors(); _flyBuildGui(); startIdleWatcher(); startComboListener()
    flyanim._normalPlayId = 1
    iniciarCicloNormal(1)
    startLockSystem(); startBrakeSystem(); startAntiImpulse(); startMegaTurboUpListener()
    startAnomalyProtection(); startAnimBlockLoop(); startTeleportGuard()

    if flyanim.tpMoveConn then flyanim.tpMoveConn:Disconnect(); flyanim.tpMoveConn = nil end
    local _tpMoveSession = flyanim.sessionToken
    flyanim.tpMoveConn = RunService.Stepped:Connect(function(_, dt)
        if flyanim.sessionToken ~= _tpMoveSession then
            flyanim.tpMoveConn:Disconnect(); flyanim.tpMoveConn = nil; return
        end
        if not flyanim.enabled then
            flyanim.tpMoveConn:Disconnect(); flyanim.tpMoveConn = nil; return
        end
        local cc   = lplr.Character
        local root2 = cc and cc:FindFirstChild("HumanoidRootPart")
        if not root2 then return end

        -- Guard: no mover si posición absurda
        local pos2 = root2.Position
        if math.abs(pos2.Y) > COORD_SANITY_LIMIT or math.abs(pos2.X) > COORD_SANITY_LIMIT or math.abs(pos2.Z) > COORD_SANITY_LIMIT then
            return
        end

        local cam    = workspace.CurrentCamera
        local typing = isTyping()
        local wD = not typing and UserInputService:IsKeyDown(Enum.KeyCode.W)
        local sD = not typing and UserInputService:IsKeyDown(Enum.KeyCode.S)
        local aD = not typing and UserInputService:IsKeyDown(Enum.KeyCode.A)
        local dD = not typing and UserInputService:IsKeyDown(Enum.KeyCode.D)
        local spaceDown = not typing and UserInputService:IsKeyDown(Enum.KeyCode.Space)
        local ctrlDown  = not typing and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)

        -- Noclip para Ctrl (bajar a través del suelo)
        if ctrlDown and flyanim.noclipCtrlEnabled and not flyanim.noclipCtrlActive then
            flyanim.noclipCtrlActive = true
            setNoclip(true)
        elseif not ctrlDown and flyanim.noclipCtrlActive then
            flyanim.noclipCtrlActive = false
            -- Solo quitar noclip si no hay otro sistema que lo requiera
            local megaActive = (flyanim.mode == "turbo") and flyanim.noclipMegaEnabled
            if not flyanim.noclipSpaceActive and not megaActive then
                setNoclip(false)
            end
        end

        local move = Vector3.new()
        if wD then move = move + cam.CFrame.LookVector end
        if sD then move = move - cam.CFrame.LookVector end
        if aD then move = move - cam.CFrame.RightVector end
        if dD then move = move + cam.CFrame.RightVector end

        if (flyanim.mode == "fast" or flyanim.mode == "turbo") and flyanim.lockActive and flyanim.lockedTarget and wD then
            local targetChar2 = flyanim.lockedTarget.Character
            if targetChar2 then
                local targetRoot2 = targetChar2:FindFirstChild("HumanoidRootPart")
                if targetRoot2 then
                    -- Micro-TP: si no hay suelo bajo el jugador y está 10+ studs por debajo del target
                    local noFloor = false
                    do
                        local rpCheck = RaycastParams.new()
                        rpCheck.FilterType = Enum.RaycastFilterType.Exclude
                        local cc2 = lplr.Character
                        if cc2 then rpCheck.FilterDescendantsInstances = {cc2} end
                        local hitCheck = workspace:Raycast(root2.Position, Vector3.new(0, -5, 0), rpCheck)
                        noFloor = (hitCheck == nil)
                    end
                    local heightDiff = targetRoot2.Position.Y - root2.Position.Y
                    if noFloor and heightDiff > 10 and flyanim.enabled then
                        -- Micro-TP: posicionarse justo junto al target
                        local toTarget = targetRoot2.Position - root2.Position
                        local newPos = targetRoot2.Position - (toTarget.Unit * 5)
                        pcall(function()
                            root2.CFrame = CFrame.new(newPos, targetRoot2.Position)
                        end)
                    end

                    local toTarget3D = targetRoot2.Position - root2.Position
                    local horDist2   = Vector3.new(toTarget3D.X, 0, toTarget3D.Z).Magnitude
                    local vertDiff   = math.abs(toTarget3D.Y)
                    if horDist2 < 25 and vertDiff > 8 then
                        flyanim.straightLineActive = true
                        if toTarget3D.Magnitude > 0.1 then
                            move = toTarget3D.Unit * move.Magnitude
                            if move.Magnitude < 0.01 then move = toTarget3D.Unit end
                        end
                    else
                        flyanim.straightLineActive = false
                        local horDir2 = Vector3.new(toTarget3D.X, 0, toTarget3D.Z)
                        if horDir2.Magnitude > 0.1 then
                            move = Vector3.new(horDir2.Unit.X * move.Magnitude, move.Y, horDir2.Unit.Z * move.Magnitude)
                        end
                        if horDist2 < 15 then
                            local factor2 = math.clamp(horDist2 / 15, 0.2, 1)
                            move = move * factor2
                        end
                    end
                end
            end
        else
            flyanim.straightLineActive = false
        end

        if flyanim.megaTurboUpActive then move = move + Vector3.new(0,2,0)
        elseif spaceDown             then move = move + Vector3.new(0,1,0) end
        if ctrlDown then move = move - Vector3.new(0,1,0) end

        if spaceDown and not flyanim.megaTurboUpActive then
            fixUndergroundOrientation()
        end

        if move.Magnitude > 0.01 then
            local actualSpeed = flyanim.speed
            if flyanim.dashTimer > 0 then actualSpeed = actualSpeed + flyanim.dashVel.Magnitude end
            local translation = move.Unit * actualSpeed * dt
            pcall(function() cc:TranslateBy(translation) end)
        elseif flyanim.dashTimer > 0 and flyanim.dashVel.Magnitude > 0.1 then
            local translation = flyanim.dashVel.Unit * flyanim.dashVel.Magnitude * dt
            pcall(function() cc:TranslateBy(translation) end)
        end
    end)

    if flyanim.rsConn then flyanim.rsConn:Disconnect() end
    local _rsSession = flyanim.sessionToken
    flyanim.rsConn = RunService.RenderStepped:Connect(function(dt)
        if flyanim.sessionToken ~= _rsSession then flyanim.rsConn:Disconnect(); flyanim.rsConn = nil; return end
        if not flyanim.enabled then flyanim.rsConn:Disconnect(); flyanim.rsConn = nil; return end
        local cc   = lplr.Character
        local root = cc and cc:FindFirstChild("HumanoidRootPart")
        local ch   = cc and cc:FindFirstChildOfClass("Humanoid")
        if not root or not ch then return end

        -- Guard: posición absurda - no procesar hasta que teleport guard la corrija
        local pos = root.Position
        if math.abs(pos.Y) > COORD_SANITY_LIMIT or math.abs(pos.X) > COORD_SANITY_LIMIT or math.abs(pos.Z) > COORD_SANITY_LIMIT then
            return
        end

        if not root:FindFirstChild("BodyGyro") or not root:FindFirstChild("BodyVelocity")
        or ch:GetState() == Enum.HumanoidStateType.Ragdoll then _flyMakeMotors(); return end
        flyanim.bg = root:FindFirstChild("BodyGyro")
        flyanim.bv = root:FindFirstChild("BodyVelocity")
        flyanim.bf = root:FindFirstChild("BodyForce")

        updateAntiGravityForce()

        local angularSpeed = root.AssemblyAngularVelocity.Magnitude
        if angularSpeed > 25 and not flyanim.gyroProtectionActive then activateGyroProtection() end

        local cam    = workspace.CurrentCamera
        local typing = isTyping()
        local wD = not typing and UserInputService:IsKeyDown(Enum.KeyCode.W)
        local sD = not typing and UserInputService:IsKeyDown(Enum.KeyCode.S)
        local aD = not typing and UserInputService:IsKeyDown(Enum.KeyCode.A)
        local dD = not typing and UserInputService:IsKeyDown(Enum.KeyCode.D)
        flyanim.wDown=wD; flyanim.sDown=sD; flyanim.aDown=aD; flyanim.dDown=dD
        flyanim.isWDown=wD; flyanim.isSDown=sD; flyanim.isADown=aD; flyanim.isDDown=dD

        if flyanim.bv then flyanim.bv.velocity = Vector3.new(0, 0, 0) end

        if flyanim.lockActive and flyanim.lockedTarget then
            local tChar = flyanim.lockedTarget.Character
            if tChar and isTargetValidForLock(flyanim.lockedTarget) then
                local aimPart = tChar:FindFirstChild("UpperTorso") or tChar:FindFirstChild("HumanoidRootPart")
                if aimPart then
                    local desiredCF = CFrame.lookAt(root.Position, aimPart.Position, Vector3.new(0,1,0))
                    local smooth    = LOCK_ROTATION_SMOOTH * (1 + math.min(0.5, (flyanim.dashVel.Magnitude / 300)))
                    flyanim.bg.cframe = flyanim.bg.cframe:Lerp(desiredCF, smooth)
                else
                    flyanim.lockActive=false; flyanim.lockedTarget=nil; removeLockIcon(); updateLockHighlight()
                end
            else
                flyanim.lockActive=false; flyanim.lockedTarget=nil; removeLockIcon(); updateLockHighlight()
            end
        else
            local move = Vector3.new()
            if wD then move = move + cam.CFrame.LookVector end
            if sD then move = move - cam.CFrame.LookVector end
            if aD then move = move - cam.CFrame.RightVector end
            if dD then move = move + cam.CFrame.RightVector end
            local targetCFrame
            local isFastMode2 = (flyanim.mode == "fast" or flyanim.mode == "turbo")
            if isFastMode2 and move.Magnitude > 0.01 then
                targetCFrame = CFrame.lookAt(root.Position, root.Position + move.Unit)
            else
                targetCFrame = cam.CFrame
            end
            local sf
            if isFastMode2 then
                -- Suavizado progresivo: empieza lento y acelera conforme converge
                -- Evita el "tp salvaje" al girar en turbo/mega sin perder precisión
                local angleDiff = 0
                pcall(function()
                    local currentLook = flyanim.bg.cframe.LookVector
                    local desiredLook = targetCFrame.LookVector
                    local dot = math.clamp(currentLook:Dot(desiredLook), -1, 1)
                    angleDiff = math.acos(dot)  -- ángulo en radianes entre dirección actual y deseada
                end)
                -- Lerp más lento cuando el ángulo es grande (giro amplio) y más rápido cuando ya está casi alineado
                -- Rango: 0.04 (180°) → 0.18 (0°), curva cuadrática para sensación fluida
                local t_angle = math.clamp(1 - (angleDiff / math.pi), 0, 1)
                sf = 0.04 + (t_angle * t_angle) * 0.14
                -- Clamp para que nunca pase de un valor razonable por frame
                sf = math.clamp(sf * (1 + dt * 8), 0, 0.20)
            else
                sf = math.clamp(dt*10, 0, 1)
            end
            flyanim.bg.cframe = flyanim.bg.cframe:Lerp(targetCFrame, sf)
        end

        if flyanim.dashTimer > 0 then
            flyanim.dashTimer = flyanim.dashTimer - dt
            if flyanim.dashTimer <= 0 then
                flyanim.dashTimer=0; flyanim.dashVel=Vector3.new(0,0,0)
                if dashConnection then dashConnection:Disconnect(); dashConnection=nil end
            else
                flyanim.dashVel = flyanim.dashVel:Lerp(Vector3.new(0,0,0), math.clamp(dt*9,0,1))
            end
        end

        local velY = root.AssemblyLinearVelocity.Y
        if velY < -10 then
            flyanim.landingVelocity = math.abs(velY)
            if math.abs(velY) > flyanim.landingVelocityCapture then
                flyanim.landingVelocityCapture = math.abs(velY)
            end
        end

        updateAnimForMovement()
    end)
end

-- ============================================================
-- ANTI-REBOTE AL ATERRIZAR (omniAntiBounceLand)
-- ============================================================
-- Al detectar suelo inminente:
--   · Cancela TODOS los impulsos en Y al instante
--   · Fuerza el body completamente recto (upright) con un BodyGyro
--     de maxTorque muy alto durante el impacto, eliminando cualquier
--     inclinacion residual del vuelo que cause rebotes laterales
--   · BodyVelocity con MaxForce solo en Y durante GROUND_STICK_TIME (0.35s)
--     para "pegar" al suelo y absorber el impacto sin afectar XZ
--   · Destruye todo y restaura el estado normal al terminar
local GROUND_STICK_TIME = 0.35   -- segundos pegado al suelo

local function omniAntiBounceLand(hrp, hum)
    if not hrp or not hum then return end

    -- Paso 1: Cancelar TODOS los impulsos en Y inmediatamente
    pcall(function()
        local v = hrp.AssemblyLinearVelocity
        -- Zerear Y por completo; conservar XZ para no interrumpir el movimiento
        hrp.AssemblyLinearVelocity  = Vector3.new(v.X, 0, v.Z)
        hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
    end)

    -- Paso 2: BodyGyro de alta potencia para alinear el body completamente
    -- Esto elimina la inclinacion residual del vuelo (turbo/mega usan CFrame.Angles)
    -- que hace que al impactar el suelo la fisica calcule fuerzas de reaccion
    -- laterales y salga el personaje disparado hacia los lados.
    local uprightGyro = Instance.new("BodyGyro")
    do
        local _, ry, _ = hrp.CFrame:ToOrientation()
        -- CFrame completamente vertical: solo conservar rotacion Y (yaw), anular pitch/roll
        uprightGyro.CFrame    = CFrame.new(hrp.Position) * CFrame.Angles(0, ry, 0)
        uprightGyro.P         = 999999
        uprightGyro.MaxTorque = Vector3.new(999999, 999999, 999999)
        uprightGyro.Parent    = hrp
    end
    -- Forzar la orientacion del HRP inmediatamente tambien via CFrame
    pcall(function()
        local _, ry, _ = hrp.CFrame:ToOrientation()
        local currentPos = hrp.Position
        hrp.CFrame = CFrame.new(currentPos) * CFrame.Angles(0, ry, 0)
    end)

    -- Paso 3: BodyVelocity que bloquea el eje Y durante GROUND_STICK_TIME
    -- MaxForce solo en Y: no toca XZ, el personaje puede moverse normalmente
    -- Velocity Y = 0 para absorber rebotes y mantenerlo pegado al suelo
    local bv = Instance.new("BodyVelocity")
    bv.Velocity  = Vector3.new(0, 0, 0)
    bv.MaxForce  = Vector3.new(0, 9e9, 0)
    bv.Parent    = hrp

    hum.PlatformStand = true
    hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
    hum:SetStateEnabled(Enum.HumanoidStateType.Jumping,   false)

    task.delay(GROUND_STICK_TIME, function()
        pcall(function() bv:Destroy() end)
        pcall(function() uprightGyro:Destroy() end)
        if not hum or not hum.Parent then return end
        -- Zerear Y una ultima vez al soltar
        if hrp and hrp.Parent then
            local v2 = hrp.AssemblyLinearVelocity
            hrp.AssemblyLinearVelocity  = Vector3.new(v2.X, 0, v2.Z)
            hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
        end
        hum.PlatformStand = false
        hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.Jumping,   true)
        -- El motor de fisica detectara Landed en el siguiente frame
    end)
end

-- ============================================================
-- WATCHER DE IMPACTO INMINENTE (raycast hacia el suelo)
-- ============================================================
-- Se activa en _flyOff() cuando hay altura >= 10 studs.
-- Cada Heartbeat lanza un raycast de 5 studs hacia abajo;
-- si detecta suelo a <= 2.5 studs aplica omniAntiBounceLand
-- para evitar el rebote al caer.
local _landingWatchConn = nil
local _landingWatchToken = 0

stopLandingWatcher = function()
    _landingWatchToken = _landingWatchToken + 1
    if _landingWatchConn then
        _landingWatchConn:Disconnect()
        _landingWatchConn = nil
    end
end

startLandingWatcher = function()
    stopLandingWatcher()
    local myToken = _landingWatchToken

    _landingWatchConn = RunService.Heartbeat:Connect(function()
        if not flyanim.waitingLand then
            stopLandingWatcher()
            return
        end
        if _landingWatchToken ~= myToken then return end

        local char = lplr.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum then return end

        -- Sondear siempre, no solo cuando velY < -2.
        -- Si el personaje está casi estático tras el kick de caída puede tener
        -- velY cercana a 0 y aun así estar a punto de tocar el suelo.
        local velY = hrp.AssemblyLinearVelocity.Y
        local probeDistance = math.clamp(math.abs(velY) * 0.1 + 2.5, 2.5, 8.0)

        local rp = RaycastParams.new()
        rp.FilterType = Enum.RaycastFilterType.Exclude
        rp.FilterDescendantsInstances = {char}
        local hit = workspace:Raycast(hrp.Position, Vector3.new(0, -probeDistance, 0), rp)

        if hit then
            stopLandingWatcher()

            -- Limpiar cualquier motor residual del vuelo antes del anti-bounce.
            -- Si quedó algún BodyForce/BodyGyro huérfano sigue empujando hacia arriba.
            pcall(function()
                for _, v in ipairs(hrp:GetChildren()) do
                    if v:IsA("BodyGyro") or v:IsA("BodyVelocity") or v:IsA("BodyForce")
                    or v:IsA("BodyAngularVelocity") or v:IsA("AlignOrientation")
                    or v:IsA("LinearVelocity") or v:IsA("AngularVelocity") then
                        v:Destroy()
                    end
                end
            end)

            -- Inhibir Animate antes del impacto para que doLanding controle la animación
            local animScriptPre = char and char:FindFirstChild("Animate")
            if animScriptPre then
                pcall(function() animScriptPre.Disabled = true end)
                task.delay(0.25, function()
                    if not flyanim.waitingLand and animScriptPre and animScriptPre.Parent then
                        pcall(function() animScriptPre.Disabled = false end)
                    end
                end)
            end

            omniAntiBounceLand(hrp, hum)
        end
    end)
end

local function _flyOff()
    local char = lplr.Character

    -- ── PASO 0: Cancelar timers pendientes que podrían ejecutarse post-flyOff ──
    -- gyroProtectionTimer puede llamar a _flyMakeMotors tras el apagado
    if flyanim.gyroProtectionTimer then
        task.cancel(flyanim.gyroProtectionTimer)
        flyanim.gyroProtectionTimer = nil
    end
    if flyanim.backupGyro then
        pcall(function() flyanim.backupGyro:Destroy() end)
        flyanim.backupGyro = nil
    end
    flyanim.gyroProtectionActive = false

    -- ── PASO 0B: Invalidar TODOS los tokens inmediatamente ──
    -- sessionToken es lo PRIMERO: invalida los guards de seguridad (teleportGuard,
    -- anomalyProtection, antiImpulse, animBlockLoop) en el mismo tick, antes de
    -- que corran sus callbacks de Heartbeat/Stepped. Sin esto, pueden ejecutar
    -- un tick extra con datos de la sesion anterior y forzar velocidad 0 cuando
    -- ya no esta volando.
    flyanim.sessionToken          = (flyanim.sessionToken          or 0) + 1
    -- Invalidar el resto de tokens de coroutines y loops internos
    flyanim.turboPreImpulsoToken  = (flyanim.turboPreImpulsoToken  or 0) + 1
    flyanim.turboPreImpulsoActivo = false
    flyanim.idleWatchToken        = (flyanim.idleWatchToken        or 0) + 1
    flyanim.dashAnimToken         = (flyanim.dashAnimToken         or 0) + 1
    flyanim.comboToken            = (flyanim.comboToken            or 0) + 1
    flyanim.c0ControlToken        = (flyanim.c0ControlToken        or 0) + 1
    flyanim.c0HeightToken         = (flyanim.c0HeightToken         or 0) + 1
    heightTweenToken              = heightTweenToken + 1

    -- ── PASO 0C: Desconectar TODOS los sistemas en este mismo frame ──
    -- CRITICO: Limpiar las posiciones de seguridad ANTES de desconectar,
    -- para que aunque un guard corra un tick mas, no tenga posicion a la que devolver.
    flyanim.lastSafePos  = nil
    flyanim.lastSafeTime = 0
    flyanim.lastKnownPos = nil
    flyanim.isTeleportGuardActive = false
    if flyanim.turboRenderConn     then flyanim.turboRenderConn:Disconnect();     flyanim.turboRenderConn     = nil end
    if flyanim.megaRenderConn      then flyanim.megaRenderConn:Disconnect();      flyanim.megaRenderConn      = nil end
    if flyanim.c0HeightConn        then flyanim.c0HeightConn:Disconnect();        flyanim.c0HeightConn        = nil end
    if flyanim.animBlockRenderConn then flyanim.animBlockRenderConn:Disconnect(); flyanim.animBlockRenderConn = nil end
    if flyanim.comboC0Conn         then flyanim.comboC0Conn:Disconnect();         flyanim.comboC0Conn         = nil end
    if flyanim.blockRenderConn     then flyanim.blockRenderConn:Disconnect();     flyanim.blockRenderConn     = nil end
    if flyanim.idleAnimConn        then flyanim.idleAnimConn:Disconnect();        flyanim.idleAnimConn        = nil end
    if flyanim.megaTurboUpConn     then flyanim.megaTurboUpConn:Disconnect();     flyanim.megaTurboUpConn     = nil end
    if brakeConn                   then brakeConn:Disconnect();                   brakeConn                   = nil end
    if flyanim.antiImpulseConn     then flyanim.antiImpulseConn:Disconnect();     flyanim.antiImpulseConn     = nil end
    if flyanim.anomalyConn         then flyanim.anomalyConn:Disconnect();         flyanim.anomalyConn         = nil end
    if flyanim.teleportGuardConn   then flyanim.teleportGuardConn:Disconnect();   flyanim.teleportGuardConn   = nil end
    if flyanim.rsConn              then flyanim.rsConn:Disconnect();              flyanim.rsConn              = nil end
    if flyanim.tpMoveConn          then flyanim.tpMoveConn:Disconnect();          flyanim.tpMoveConn          = nil end
    -- Destruir los body movers INMEDIATAMENTE aquí, en el mismo frame que rsConn/tpMoveConn,
    -- para que el BodyForce anti-gravedad no tenga ni un frame extra de efecto.
    -- cleanupMotors también zeroa AssemblyLinearVelocity/AngularVelocity al instante.
    do
        local _earlyChar = lplr.Character
        local _earlyRoot = _earlyChar and _earlyChar:FindFirstChild("HumanoidRootPart")
        -- preserveVelY=true: conservar velocidad Y para que la caida libre funcione.
        -- cleanupMotors sin este flag zeroa Y tambien, haciendo que el personaje
        -- quede estatico en el aire hasta que GettingUp lo empuje hacia arriba.
        if _earlyRoot then cleanupMotors(_earlyRoot, true) end
        flyanim.bg = nil; flyanim.bv = nil; flyanim.bf = nil
    end
    if flyanim.lockConn            then flyanim.lockConn:Disconnect();            flyanim.lockConn            = nil end
    if flyanim.lockRenderConn      then flyanim.lockRenderConn:Disconnect();      flyanim.lockRenderConn      = nil end
    if flyanim.damageConn          then flyanim.damageConn:Disconnect();          flyanim.damageConn          = nil end
    if flyanim.animConn            then flyanim.animConn:Disconnect();            flyanim.animConn            = nil end
    if flyanim.comboConn           then flyanim.comboConn:Disconnect();           flyanim.comboConn           = nil end
    if flyanim.comboHoldConn       then flyanim.comboHoldConn:Disconnect();       flyanim.comboHoldConn       = nil end
    if flyanim._comboEndConn       then flyanim._comboEndConn:Disconnect();       flyanim._comboEndConn       = nil end
    if dashConnection              then dashConnection:Disconnect();               dashConnection              = nil end
    if flyanim.idleTimer           then task.cancel(flyanim.idleTimer);           flyanim.idleTimer           = nil end
    if flyanim.spaceHoldTimerAdv   then task.cancel(flyanim.spaceHoldTimerAdv);   flyanim.spaceHoldTimerAdv   = nil end
    -- Cancelar timers de gyroProtection que pudieran recrear motores post-apagado
    if flyanim.gyroProtectionTimer then task.cancel(flyanim.gyroProtectionTimer); flyanim.gyroProtectionTimer = nil end

    -- ── PASO 1: Medir altura antes de apagar ──
    -- Limpiar compensación de altura INCONDICIONALMENTE al apagar el vuelo.
    -- Esto cubre el caso edge donde una animación de combo/turbo modifica C0
    -- y el fly se apaga mientras corre: sin esto el personaje queda con el
    -- offset de altura aplicado permanentemente.
    heightTweenToken = heightTweenToken + 1   -- cancelar tweens de altura en curso
    clearC0Desired()
    detenerWatchdogAltura()
    if flyanim.rootJoint and flyanim.originalC0 then
        pcall(function() flyanim.rootJoint.C0 = flyanim.originalC0 end)
    end

    local heightFromGround = 0
    if char then
        local root = char:FindFirstChild("HumanoidRootPart")
        if root then
            local rp = RaycastParams.new()
            rp.FilterType = Enum.RaycastFilterType.Exclude
            rp.FilterDescendantsInstances = {char}
            local rayResult = workspace:Raycast(root.Position, Vector3.new(0, -500, 0), rp)
            if rayResult then
                heightFromGround = root.Position.Y - rayResult.Position.Y
            else
                heightFromGround = 999
            end
        end
    end
    flyanim.landingHeight = heightFromGround

    -- ── PASO 2: Marcar sistema como desactivado ──
    flyanim.enabled   = false
    flyanim.dashTimer = 0
    flyanim.dashVel   = Vector3.new(0, 0, 0)

    -- ── Flags de estado: resetear todo ──
    flyanim.isTeleportGuardActive = false
    flyanim.lastKnownPos          = nil
    flyanim.lastSafePos           = nil
    flyanim.megaTurboUpActive     = false
    flyanim.spaceHoldStart        = nil
    flyanim.brakingActive         = false
    flyanim.noclipSpaceActive     = false
    flyanim.noclipCtrlActive      = false
    flyanim.isBlocking            = false
    flyanim.isSpaceAdv            = false
    flyanim.isBrazosActive        = false
    flyanim.ragdollDetected       = false
    flyanim.comboPlaying          = false
    flyanim.comboBusy             = false
    flyanim.combo4Frozen          = false
    flyanim.mouseHeld             = false
    flyanim.fKeyHeld              = false
    flyanim.blockCancelledByCombo = false
    flyanim.comboAnimStartTime    = 0
    flyanim.turboTransitioning    = false
    flyanim.megaTransitioning     = false

    -- Llamar helpers de stop (son idempotentes: si la conn ya es nil no hacen nada)
    -- Su única función aquí es limpiar estado extra que no sea una RBXScriptConnection
    detenerNormalTracks(0); detenerPoseTurbo(); detenerPoseMega(); detenerEspacioAvanzado()
    stopBlocking(); stopParticleEmitter()
    -- stopAntiImpulse / stopBrakeSystem / stopAnomalyProtection / stopTeleportGuard /
    -- stopAnimBlockLoop / stopMegaTurboUpListener ya no tienen conn que desconectar
    -- (se hizo en PASO 0C), pero los llamamos igual para limpiar sus flags internos
    stopAntiImpulse(); stopBrakeSystem(); stopMegaTurboUpListener()
    stopAnomalyProtection(); stopComboC0Lock(); stopAnimBlockLoop()
    stopTeleportGuard(); detenerWatchdogAltura()
    -- Limpiar estado del combo (conns ya desconectadas en PASO 0C)
    stopComboListener()
    setNoclip(false)

    if shakeConn then pcall(function() shakeConn:Disconnect() end); shakeConn=nil end
    destroyWhiteFlash()
    local cam = workspace.CurrentCamera; if cam then cam.FieldOfView = 70 end

    for _, t in pairs(flyanim.tracks) do pcall(function() if t and t.IsPlaying then t:Stop(0.05) end end) end
    for _, t in pairs(flyanim.normalTracks) do pcall(function() if t and t.IsPlaying then t:Stop(0.05) end end) end

    local charCurrent = lplr.Character
    local rootCurrent = charCurrent and charCurrent:FindFirstChild("HumanoidRootPart")
    local hum = charCurrent and charCurrent:FindFirstChildOfClass("Humanoid")

    if flyanim.rootJoint and flyanim.originalC0 then
        pcall(function() flyanim.rootJoint.C0 = flyanim.originalC0 end)
    end

    -- bg/bv/bf ya son nil desde PASO 0C (cleanupMotors corrió ahí)
    flyanim.mode="normal"; flyanim.speed=BASE_SPEED
    _flyDestroyGui()
    -- stopLockSystem ya desconectó lockConn y lockRenderConn en PASO 0C,
    -- pero llamarlo limpia lockActive, lockedTarget, lockIconGui, lockHighlight
    stopLockSystem()

    if not charCurrent or not hum or hum.Health <= 0 then
        local animScript2 = charCurrent and charCurrent:FindFirstChild("Animate") or flyanim.animScript
        if animScript2 then animScript2.Disabled = false; flyanim.animScript = nil end
        flyanim.animScript = nil
        flyanim.landingHeight = nil
        return
    end

    -- Deshabilitar estados que empujan hacia arriba ANTES de quitar PlatformStand.
    -- GettingUp y Jumping pueden causar un impulso vertical hacia arriba cuando
    -- PlatformStand pasa de true->false en el aire. Se re-habilitan tras Freefall.
    hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
    hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
    hum:SetStateEnabled(Enum.HumanoidStateType.StrafingNoPhysics, false)
    hum.PlatformStand = false
    hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
    hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)

    if rootCurrent then
        for _, part in ipairs(charCurrent:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = true end
        end
    end

    -- Alinear orientación (quitar inclinación del vuelo) ANTES de Freefall.
    -- Es critico que el HRP quede completamente recto (sin pitch/roll) en este momento:
    -- si el body tiene inclinacion residual del turbo/mega (CFrame.Angles), al entrar
    -- en Freefall la fisica calcula fuerzas de contacto laterales al tocar el suelo
    -- que disparan el personaje hacia los lados (el "rebote loco").
    if rootCurrent then
        local _, ry, _ = rootCurrent.CFrame:ToOrientation()
        pcall(function()
            -- Forzar CFrame completamente vertical: solo yaw, sin pitch ni roll
            rootCurrent.CFrame = CFrame.new(rootCurrent.Position) * CFrame.Angles(0, ry, 0)
            -- Zerear velocidad angular para que no haya torques residuales
            rootCurrent.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            -- Zerear XZ tambien: al salir del vuelo solo debe haber caida libre en Y.
            -- La velocidad Y ya fue preservada por cleanupMotors(preserveVelY=true).
            local velY = rootCurrent.AssemblyLinearVelocity.Y
            rootCurrent.AssemblyLinearVelocity  = Vector3.new(0, velY, 0)
        end)
    end

    hum:ChangeState(Enum.HumanoidStateType.Freefall)

    -- Re-habilitar GettingUp/Jumping solo una vez que Freefall esté confirmado.
    -- Hacerlo en task.defer inmediato hace que GettingUp se dispare antes de que
    -- Freefall esté asentado, causando el rebote hacia arriba.
    task.delay(0.12, function()
        if hum and hum.Parent then
            hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
            hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
            hum:SetStateEnabled(Enum.HumanoidStateType.StrafingNoPhysics, true)
        end
    end)

    -- KICK DE CAÍDA: si al apagar el vuelo el personaje está quieto o subiendo,
    -- aplicar pequeño impulso hacia abajo para que la gravedad tome efecto.
    -- Se aplica DESPUÉS del delay de GettingUp para que no lo sobreescriba.
    if rootCurrent then
        task.delay(0.01, function()
            if not rootCurrent or not rootCurrent.Parent then return end
            if flyanim.enabled then return end  -- ya reactivó el vuelo
            local velY = rootCurrent.AssemblyLinearVelocity.Y
            if velY > 0.5 then
                pcall(function()
                    rootCurrent.AssemblyLinearVelocity = Vector3.new(0, -4, 0)
                end)
            end
        end)
    end

    local capturedHeight   = flyanim.landingHeight
    local capturedVelocity = math.max(flyanim.landingVelocity, flyanim.landingVelocityCapture)

    if capturedHeight < 10 then
        local animScript3 = charCurrent and charCurrent:FindFirstChild("Animate") or flyanim.animScript
        if animScript3 then animScript3.Disabled = false; flyanim.animScript = nil end
        if hum then
            -- GettingUp ya fue deshabilitado arriba; re-habilitarlo ahora que
            -- PlatformStand ya es false y no puede causar el rebote hacia arriba.
            hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
            hum.PlatformStand = false
            pcall(function() hum:ChangeState(Enum.HumanoidStateType.Running) end)
        end
        flyanim.landingHeight = nil
        return
    end

    -- FIX BUG PRINCIPAL: Reactivar animScript INMEDIATAMENTE para que las animaciones
    -- normales (caída libre, etc.) aparezcan durante el freefall ANTES de aterrizar.
    -- Antes solo se reactivaba en doLanding() → el personaje caía completamente sin animaciones.
    -- doLanding() lo desactivará temporalmente para la secuencia épica y lo vuelve a activar.
    do
        local animScriptEarly = charCurrent and charCurrent:FindFirstChild("Animate") or flyanim.animScript
        if animScriptEarly then
            animScriptEarly.Disabled = false
            flyanim.animScript = animScriptEarly  -- doLanding() necesita esta referencia
        end
    end

    flyanim.waitingLand = true
    if flyanim.landConn then flyanim.landConn:Disconnect() end
    startLandingWatcher()

    local function finalizarAterrizaje(newState)
        if not flyanim.waitingLand then return end
        flyanim.waitingLand = false
        if flyanim.landConn then flyanim.landConn:Disconnect(); flyanim.landConn=nil end
        if newState ~= Enum.HumanoidStateType.Dead then
            flyanim.landingHeight   = capturedHeight
            flyanim.landingVelocity = capturedVelocity
            flyanim.landingVelocityCapture = capturedVelocity
            doLanding(lplr.Character)
        else
            local deadChar = lplr.Character
            local animSc = deadChar and deadChar:FindFirstChild("Animate") or flyanim.animScript
            if animSc then animSc.Disabled = false; flyanim.animScript = nil end
            flyanim.landingHeight = nil
        end
    end

    flyanim.landConn = hum.StateChanged:Connect(function(_, newState)
        if not flyanim.waitingLand then
            if flyanim.landConn then flyanim.landConn:Disconnect(); flyanim.landConn=nil end
            return
        end
        if newState == Enum.HumanoidStateType.Landed
        or newState == Enum.HumanoidStateType.Running
        or newState == Enum.HumanoidStateType.RunningNoPhysics
        or newState == Enum.HumanoidStateType.Dead then
            finalizarAterrizaje(newState)
        end
    end)

    -- Timeout de seguridad: si en 10 segundos no aterriza, forzar restauracion
    task.delay(10, function()
        if not flyanim.waitingLand then return end
        flyanim.waitingLand = false
        if flyanim.landConn then flyanim.landConn:Disconnect(); flyanim.landConn=nil end
        local animSc = lplr.Character and lplr.Character:FindFirstChild("Animate") or flyanim.animScript
        if animSc then animSc.Disabled = false; flyanim.animScript = nil end
        local humFinal = lplr.Character and lplr.Character:FindFirstChildOfClass("Humanoid")
        if humFinal and humFinal.Parent then
            humFinal.PlatformStand = false
            pcall(function() humFinal:ChangeState(Enum.HumanoidStateType.GettingUp) end)
        end
        flyanim.landingHeight = nil
    end)
end

-- ============================================================
-- DASH
-- ============================================================

local function triggerDash(direction, speed, duration)
    local cam = workspace.CurrentCamera
    local dashDir
    if direction == "back"    then local l = cam.CFrame.LookVector; dashDir = Vector3.new(-l.X, 0, -l.Z)
    elseif direction == "left"  then local r = cam.CFrame.RightVector; dashDir = Vector3.new(-r.X, 0, -r.Z)
    elseif direction == "right" then local r = cam.CFrame.RightVector; dashDir = Vector3.new(r.X, 0, r.Z)
    elseif direction == "forward" then local l = cam.CFrame.LookVector; dashDir = Vector3.new(l.X, 0, l.Z) end
    if not dashDir or dashDir.Magnitude < 0.01 then return end
    flyanim.dashVel   = dashDir.Unit * (speed or flyanim.DASH_SPEED)
    flyanim.dashTimer = duration or flyanim.DASH_DURATION
    startDashCollisionDetection()
end

local function activateMegaTurbo()
    if flyanim.mode ~= "fast" then return end
    flyanim.mode  = "turbo"
    flyanim.speed = BASE_SPEED * TURBO_MULT
    if flyanim.updateMode then flyanim.updateMode("turbo") end
    if flyanim.noclipMegaEnabled then setNoclip(true) end
    shakeCamera(3.5, 0.4)
    playLocalSound(SFX_MEGA_TURBO, 0.88)
    sonicBoomEffect(2); airShockAura(2); speedWhiteFlash("turbo")
    triggerDash("forward", flyanim.TURBO_DASH_SPEED * 1.5, flyanim.TURBO_DASH_DURATION * 1.2)
    startParticleEmitter(); detenerPoseTurbo(); iniciarPoseMega()
end

local function handleQPress()
    if not flyanim.enabled then return end
    if isTyping() then return end
    if flyanim.turboPreImpulsoActivo then return end

    local wDown = UserInputService:IsKeyDown(Enum.KeyCode.W)
    local sDown = UserInputService:IsKeyDown(Enum.KeyCode.S)
    local aDown = UserInputService:IsKeyDown(Enum.KeyCode.A)
    local dDown = UserInputService:IsKeyDown(Enum.KeyCode.D)

    if not wDown then
        if sDown and not aDown and not dDown then
            triggerDash("back", flyanim.BACK_DASH_SPEED, flyanim.DASH_DURATION * 1.2)
            flyanim.dashAnimToken = (flyanim.dashAnimToken or 0) + 1
            local myDashToken = flyanim.dashAnimToken
            task.spawn(function()
                local t = getTrack(ANIM.sq_anim)
                if not t then return end
                local timeout = tick() + 2
                while t.Length == 0 and tick() < timeout do task.wait() end
                if flyanim.dashAnimToken ~= myDashToken then return end
                if not flyanim.enabled then return end
                for id, track in pairs(flyanim.tracks) do
                    if id ~= ANIM.sq_anim and id ~= ANIM.levitacion and track and track.IsPlaying then
                        pcall(function() track:Stop(0.04) end)
                    end
                end
                for key, track in pairs(flyanim.normalTracks) do
                    if key ~= "levitacion" then
                        pcall(function() if track and track.IsPlaying then track:Stop(0.04) end end)
                    end
                end
                if t.IsPlaying then pcall(function() t:Stop(0) end) end
                t.Looped = false; t.Priority = Enum.AnimationPriority.Action4
                pcall(function() t:Play(0.04, 1, 1); t:AdjustSpeed(3.0) end)
            end)
            return
        end

        if aDown and not sDown and not dDown then
            triggerDash("left", flyanim.SIDE_DASH_SPEED, flyanim.DASH_DURATION)
            flyanim.dashAnimToken = (flyanim.dashAnimToken or 0) + 1
            local myDashToken = flyanim.dashAnimToken
            task.spawn(function()
                local t = getTrack(ANIM.sq_anim)
                if not t then return end
                local timeout = tick() + 2
                while t.Length == 0 and tick() < timeout do task.wait() end
                if flyanim.dashAnimToken ~= myDashToken then return end
                if not flyanim.enabled then return end
                for id, track in pairs(flyanim.tracks) do
                    if id ~= ANIM.sq_anim and id ~= ANIM.levitacion and track and track.IsPlaying then
                        pcall(function() track:Stop(0.04) end)
                    end
                end
                for key, track in pairs(flyanim.normalTracks) do
                    if key ~= "levitacion" then
                        pcall(function() if track and track.IsPlaying then track:Stop(0.04) end end)
                    end
                end
                if t.IsPlaying then pcall(function() t:Stop(0) end) end
                t.Looped = false; t.Priority = Enum.AnimationPriority.Action4
                pcall(function() t:Play(0.04, 1, 1); t:AdjustSpeed(3.0) end)
            end)
            return
        end

if dDown and not sDown and not aDown then
            triggerDash("right", flyanim.SIDE_DASH_SPEED, flyanim.DASH_DURATION)
            flyanim.dashAnimToken = (flyanim.dashAnimToken or 0) + 1
            local myDashToken = flyanim.dashAnimToken
            task.spawn(function()
                local t = getTrack(ANIM.dq_anim)
                if not t then return end
                local timeout = tick() + 2
                while t.Length == 0 and tick() < timeout do task.wait() end
                if flyanim.dashAnimToken ~= myDashToken then return end
                if not flyanim.enabled then return end
                for id, track in pairs(flyanim.tracks) do
                    if id ~= ANIM.dq_anim and id ~= ANIM.levitacion and track and track.IsPlaying then
                        pcall(function() track:Stop(0.04) end)
                    end
                end
                for key, track in pairs(flyanim.normalTracks) do
                    if key ~= "levitacion" then
                        pcall(function() if track and track.IsPlaying then track:Stop(0.04) end end)
                    end
                end
                if t.IsPlaying then pcall(function() t:Stop(0) end) end
                t.Looped = false; t.Priority = Enum.AnimationPriority.Action4
                pcall(function() t:Play(0.04, 1, 1); t:AdjustSpeed(3.0) end)
            end)
            return
        end
    end

    if flyanim.mode == "fast" then
        local elapsed = tick() - flyanim.turboActivatedAt
        if elapsed >= 0.75 then activateMegaTurbo() end
        return
    end
    if flyanim.mode == "normal" then
        flyanim.isSpaceAdv = false
        if flyanim.spaceHoldTimerAdv then task.cancel(flyanim.spaceHoldTimerAdv); flyanim.spaceHoldTimerAdv = nil end
        detenerEspacioAvanzado()

        if flyanim.noclipSpaceActive then
            flyanim.noclipSpaceActive = false
        end
        flyanim.noclipCtrlActive = false

        flyanim.mode  = "fast"
        flyanim.speed = BASE_SPEED * FAST_MULT
        flyanim.qLastPress       = tick()
        flyanim.turboActivatedAt = tick()
        if flyanim.updateMode then flyanim.updateMode("fast") end
        setNoclip(false)
        shakeCamera(2.0, 0.3)
        playLocalSound(SFX_TURBO, 0.82)
        sonicBoomEffect(1); airShockAura(1); speedWhiteFlash("fast")
        triggerDash("forward", flyanim.TURBO_DASH_SPEED, flyanim.TURBO_DASH_DURATION)
        startParticleEmitter()
        detenerNormalTracks(0.1); detenerEspacioAvanzado()
        iniciarPoseTurbo()
    end
end

-- ============================================================
-- CONEXIONES GLOBALES DEL MÓDULO
-- ============================================================
local _inputConn     = nil
local _inputConn_End = nil
local _charConn      = nil

local function _connectGlobal()
    if _inputConn     then _inputConn:Disconnect();     _inputConn     = nil end
    if _inputConn_End then _inputConn_End:Disconnect(); _inputConn_End = nil end
    if _charConn      then _charConn:Disconnect();      _charConn      = nil end

    _inputConn = UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if isTyping() then return end

        if input.KeyCode == flyanim.flyKey then
            if flyanim.enabled then _flyOff() else _flyOn() end
            return
        end

        if input.KeyCode == Enum.KeyCode.Q then handleQPress() end

        if input.KeyCode == Enum.KeyCode.F and flyanim.enabled then
            flyanim.fKeyHeld = true
            if not flyanim.blockCancelledByCombo then
                if flyanim.mode == "normal" and not flyanim.turboPreImpulsoActivo and not flyanim.megaTurboUpActive then
                    -- Si hay combo activo, cancelarlo inmediatamente con fade rápido
                    if flyanim.comboPlaying then
                        flyanim.comboToken = (flyanim.comboToken or 0) + 1
                        for _, track in pairs(flyanim.tracks) do
                            pcall(function() if track and track.IsPlaying then track:Stop(0.08) end end)
                        end
                        flyanim.comboPlaying = false
                        flyanim.comboBusy    = false
                        flyanim.combo4Frozen = false
                        resetCombo()
                        stopComboC0Lock()
                    end
                    startBlocking()
                end
            end
            return
        end

        if input.KeyCode == Enum.KeyCode.Space and flyanim.enabled and flyanim.mode == "normal" then
            if not flyanim.comboPlaying and not flyanim.turboPreImpulsoActivo then
                manejarEspacioPresionadoNormal()
            end
        end

        if flyanim.enabled and flyanim.mode == "normal" then
            if input.KeyCode == Enum.KeyCode.W then evaluarMovimientoDebounced() end
            if input.KeyCode == Enum.KeyCode.S then evaluarMovimientoDebounced() end
            if input.KeyCode == Enum.KeyCode.A then evaluarMovimientoDebounced() end
            if input.KeyCode == Enum.KeyCode.D then evaluarMovimientoDebounced() end
        end
    end)

    _inputConn_End = UserInputService.InputEnded:Connect(function(input, gpe)
        if gpe then return end

        if input.KeyCode == Enum.KeyCode.F then
            flyanim.fKeyHeld = false
            flyanim.blockCancelledByCombo = false
            if flyanim.enabled then stopBlocking() end
            return
        end

        if input.KeyCode == Enum.KeyCode.Space and flyanim.enabled then
            manejarEspacioSoltadoNormal()
        end

        if flyanim.enabled and flyanim.mode == "normal" then
            if input.KeyCode == Enum.KeyCode.W then evaluarMovimientoDebounced() end
            if input.KeyCode == Enum.KeyCode.S then evaluarMovimientoDebounced() end
            if input.KeyCode == Enum.KeyCode.A then evaluarMovimientoDebounced() end
            if input.KeyCode == Enum.KeyCode.D then evaluarMovimientoDebounced() end
        end
    end)

    _charConn = lplr.CharacterAdded:Connect(function(newChar)
        if shakeConn then pcall(function() shakeConn:Disconnect() end); shakeConn=nil end
        destroyWhiteFlash()
        local cam = workspace.CurrentCamera; if cam then cam.FieldOfView=70 end
        stopLandingWatcher()
        flyanim.mode="normal"; flyanim.speed=BASE_SPEED; flyanim.isMoving=false
        flyanim.wDown=false; flyanim.sDown=false; flyanim.aDown=false; flyanim.dDown=false
        flyanim.isWDown=false; flyanim.isSDown=false; flyanim.isADown=false; flyanim.isDDown=false
        flyanim.waitingLand=false; flyanim.landingHeight=nil; flyanim.landingVelocity=0
        flyanim.landingVelocityCapture=0
        flyanim.megaTurboUpActive=false; flyanim.spaceHoldStart=nil
        flyanim.isBlocking=false; flyanim.isSpaceAdv=false; flyanim._normalPlayId=0
        flyanim.turboPreImpulsoActivo=false; flyanim.turboPreImpulsoToken=0
        flyanim.comboPlaying=false; flyanim.comboBusy=false; flyanim.combo4Frozen=false; flyanim.comboToken=0
        flyanim.idleWatchToken = (flyanim.idleWatchToken or 0) + 1
        flyanim.c0ControlToken = 0
        flyanim.c0HeightToken  = 0
        flyanim.lastDamageTime = 0
        flyanim.straightLineActive = false
        flyanim.noclipSpaceActive = false
        flyanim.noclipCtrlActive  = false
        flyanim.mouseHeld = false
        flyanim.lastKnownPos = nil
        flyanim.ragdollDetected = false
        flyanim.fKeyHeld = false
        flyanim.blockCancelledByCombo = false
        flyanim.comboAnimStartTime = 0
        flyanim.lastSafePos = nil
        flyanim.lastSafeTime = tick()
        flyanim.isTeleportGuardActive = false
        if flyanim.idleAnimConn then flyanim.idleAnimConn:Disconnect(); flyanim.idleAnimConn=nil end
        flyanim.lateralKilled=true; flyanim.atrasKilled=true
        if flyanim.spaceHoldTimerAdv then task.cancel(flyanim.spaceHoldTimerAdv); flyanim.spaceHoldTimerAdv=nil end
        flyanim.espacioTrackActivo=nil
        flyanim.dashAnimToken = (flyanim.dashAnimToken or 0) + 1
        c0DesiredCFrame = nil
        heightTweenToken = heightTweenToken + 1  -- cancelar tweens de altura al respawn
        flyanim.sessionToken = (flyanim.sessionToken or 0) + 1  -- invalidar guards de sesion anterior al respawn
        _landAnimToken = _landAnimToken + 1; _landBaseRef = nil; _landOverlayRef = nil
        stopParticleEmitter(); stopBrakeSystem(); stopAntiImpulse()
        stopMegaTurboUpListener(); stopLockSystem()
        stopAnomalyProtection(); stopComboC0Lock()
        stopAnimBlockLoop(); stopTeleportGuard()
        detenerWatchdogAltura()
        if flyanim.turboRenderConn  then flyanim.turboRenderConn:Disconnect();  flyanim.turboRenderConn=nil end
        if flyanim.megaRenderConn   then flyanim.megaRenderConn:Disconnect();   flyanim.megaRenderConn=nil end
        if flyanim.blockRenderConn  then flyanim.blockRenderConn:Disconnect();  flyanim.blockRenderConn=nil end
        if flyanim.landConn         then flyanim.landConn:Disconnect();         flyanim.landConn=nil end
        if dashConnection           then dashConnection:Disconnect();            dashConnection=nil end
        if flyanim.rsConn           then flyanim.rsConn:Disconnect();           flyanim.rsConn=nil end
        if flyanim.tpMoveConn       then flyanim.tpMoveConn:Disconnect();       flyanim.tpMoveConn=nil end
        if flyanim.idleTimer        then task.cancel(flyanim.idleTimer);        flyanim.idleTimer=nil end
        if flyanim.damageConn       then flyanim.damageConn:Disconnect();       flyanim.damageConn=nil end
        if flyanim.anomalyConn      then flyanim.anomalyConn:Disconnect();      flyanim.anomalyConn=nil end
        if flyanim.teleportGuardConn then flyanim.teleportGuardConn:Disconnect(); flyanim.teleportGuardConn=nil end
        if flyanim.animBlockRenderConn then flyanim.animBlockRenderConn:Disconnect(); flyanim.animBlockRenderConn=nil end
        if flyanim.c0HeightConn     then flyanim.c0HeightConn:Disconnect();     flyanim.c0HeightConn=nil end
        stopComboListener()
        for _, t in pairs(flyanim.tracks)       do pcall(function() if t and t.IsPlaying then t:Stop(0) end end) end
        for _, t in pairs(flyanim.normalTracks) do pcall(function() if t and t.IsPlaying then t:Stop(0) end end) end
        flyanim.tracks={}; flyanim.normalTracks={}
        if flyanim.animScript then pcall(function() flyanim.animScript.Disabled=false end); flyanim.animScript=nil end
        if flyanim.animConn   then flyanim.animConn:Disconnect(); flyanim.animConn=nil end
        flyanim.animator=nil; flyanim.rootJoint=nil; flyanim.originalC0=nil
        _flyDestroyGui()
        if flyanim.enabled then task.wait(0.5); _flyOn() end
    end)
end

local function _disconnectGlobal()
    if _inputConn     then _inputConn:Disconnect();     _inputConn     = nil end
    if _inputConn_End then _inputConn_End:Disconnect(); _inputConn_End = nil end
    if _charConn      then _charConn:Disconnect();      _charConn      = nil end
end

-- ============================================================
-- EXPORTACIÓN DEL MÓDULO
-- ============================================================
local M = {}

function M.Start(lplrRef, flyKey)
    lplr   = lplrRef or Players.LocalPlayer
    camera = workspace.CurrentCamera
    if flyKey then flyanim.flyKey = flyKey end
    _reloadFT()  -- cargar idioma correcto al iniciar
    _connectGlobal()
end

function M.Stop()
    if flyanim.enabled then _flyOff() end
    _disconnectGlobal()
end

function M.Toggle(state)
    if state then
        if not flyanim.enabled then _flyOn() end
    else
        if flyanim.enabled then _flyOff() end
    end
end

function M.SetKey(keyCode)
    flyanim.flyKey = keyCode
    if flyanim.updateLbl then
        pcall(function() flyanim.updateLbl(keyCode.Name) end)
    end
    -- Reconectar input para que tome la nueva tecla
    if _inputConn     then _inputConn:Disconnect();     _inputConn     = nil end
    if _inputConn_End then _inputConn_End:Disconnect(); _inputConn_End = nil end
    _connectGlobal()
end

function M.SetLockKey(keyCode)
    flyanim.lockKey = keyCode
    -- Actualizar GUI en tiempo real
    if flyanim.lockLabels then
        flyanim.lockLabels.label.Text = FT.lock_label.." ["..keyCode.Name.."]"
        flyanim.lockLabels.hint.Text  = FT.lock_hint_prefix..keyCode.Name
    end
    -- Reconectar listener de lock para que tome la nueva tecla
    if flyanim.lockConn then flyanim.lockConn:Disconnect(); flyanim.lockConn = nil end
    if flyanim.enabled then startLockSystem() end
end

function M.GetFlyKey()  return flyanim.flyKey  end
function M.GetLockKey() return flyanim.lockKey end
function M.IsEnabled()  return flyanim.enabled end

return M
