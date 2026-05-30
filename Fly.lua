print("version 1.18 fly")

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
-- Lee el idioma guardado por el hub (mismo archivo AllForOne/lang.txt)
local _flyLang = "ES"
pcall(function()
    local data = readfile("AllForOne/lang.txt")
    if data == "EN" or data == "ES" then _flyLang = data end
end)
local FT = FlyLang[_flyLang]

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
    diagonal        = "rbxassetid://101776150450756",
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
    landing         = "rbxassetid://72842336781973",
    caida_base      = "rbxassetid://287325678",
    caida_overlay   = "rbxassetid://70439247",
    combo1          = "rbxassetid://204062532",
    combo2a         = "rbxassetid://218504594",
    combo2b         = "rbxassetid://218504594",
    combo3a         = "rbxassetid://204062532",
    combo3b         = "rbxassetid://218504594",
    combo4          = "rbxassetid://2954124238",
    combo4_space    = "rbxassetid://45828430",
    combo4_f        = "rbxassetid://83689877448729",
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

local ROBLOX_GRAVITY = 196.2
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
local COMBO4_SPACE_MIN_GAP = 0.20
local COMBO_CHAIN_WINDOW   = 1.4
local COMBO_ANIM_MIN_DURATION = 0.18

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
    antiOrbitTimer       = nil,

    lastKnownPos         = nil,
    anomalyConn          = nil,
    anomalyFixActive     = false,
    anomalyFixConn       = nil,
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
    poseOriginalC0    = nil,
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
}

-- ============================================================
-- SISTEMA DE COMPENSACIÓN DE ALTURA ROBUSTO
-- Mantiene un loop dedicado que corrige el C0 cada frame
-- y detecta/corrige cuando el offset se aplica mal
-- ============================================================

local c0DesiredCFrame = nil  -- El CFrame exacto que queremos en rootJoint.C0
-- Token para cancelar tweens de compensación de altura en vuelo
local heightTweenToken = 0

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

local function restaurarC0Suave(duracion)
    if not flyanim.rootJoint or not flyanim.originalC0 then return end
    local rj = flyanim.rootJoint
    local oc = flyanim.originalC0
    flyanim.c0ControlToken = (flyanim.c0ControlToken or 0) + 1
    local myToken = flyanim.c0ControlToken
    clearC0Desired()
    task.spawn(function()
        local startT = tick()
        local startC0 = rj.C0
        while tick() - startT < (duracion or 0.3) do
            if flyanim.c0ControlToken ~= myToken then return end
            local t = (tick() - startT) / (duracion or 0.3)
            pcall(function() rj.C0 = startC0:Lerp(oc, t) end)
            task.wait()
        end
        if flyanim.c0ControlToken == myToken then
            pcall(function() rj.C0 = oc end)
        end
    end)
end

-- Aplica el CFrame deseado con corrección robusta
local function aplicarC0Robusto(cf)
    if not flyanim.rootJoint then return end
    setC0Desired(cf)
    pcall(function() flyanim.rootJoint.C0 = cf end)
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

    flyanim.teleportGuardConn = RunService.Stepped:Connect(function(_, dt)
        if not flyanim.enabled or not flyanim.isTeleportGuardActive then
            if flyanim.teleportGuardConn then
                flyanim.teleportGuardConn:Disconnect()
                flyanim.teleportGuardConn = nil
            end
            return
        end

        local char = lplr.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then
            flyanim.lastSafePos = nil
            return
        end

        local pos = root.Position

        -- Detectar coordenadas absolutamente absurdas (caída al void, etc.)
        local isInsane = (math.abs(pos.X) > COORD_SANITY_LIMIT)
                      or (math.abs(pos.Y) > COORD_SANITY_LIMIT)
                      or (math.abs(pos.Z) > COORD_SANITY_LIMIT)
                      or (pos.Y < -5000)  -- caída al void
                      or (pos ~= pos)     -- NaN check

        if isInsane then
            -- Recuperar a última posición segura
            local safePos = flyanim.lastSafePos
            if safePos then
                pcall(function()
                    root.CFrame = CFrame.new(safePos + Vector3.new(0, 5, 0))
                    root.AssemblyLinearVelocity  = Vector3.new(0, 0, 0)
                    root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                end)
                -- Resetear dash para que no siga empujando
                flyanim.dashTimer = 0
                flyanim.dashVel   = Vector3.new(0, 0, 0)
                -- Reconstruir motores si es necesario
                if not root:FindFirstChildOfClass("BodyGyro") then
                    pcall(_flyMakeMotors)
                end
            end
            return
        end

        -- Detectar teletransporte brusco (no causado por dash legítimo)
        local now = tick()
        if flyanim.lastSafePos then
            local delta3D  = pos - flyanim.lastSafePos
            -- Solo medir desplazamiento HORIZONTAL: la caída libre genera delta vertical
            -- enorme que dispara el guard y hace TP hacia arriba al desactivar el vuelo.
            local horizDelta = Vector3.new(delta3D.X, 0, delta3D.Z).Magnitude
            local elapsed    = now - flyanim.lastSafeTime
            if elapsed > 0 then
                local impliedSpeed = horizDelta / elapsed
                -- Ignorar completamente si el personaje está cayendo (caída libre normal)
                local velY = root.AssemblyLinearVelocity.Y
                local isFalling = velY < -8
                -- Si la velocidad implícita es absurdamente alta y no tenemos dash activo
                local maxLegit = math.max(
                    BASE_SPEED * TURBO_MULT * 2,
                    flyanim.DASH_SPEED * 2,
                    flyanim.TURBO_DASH_SPEED * 2,
                    flyanim.BACK_DASH_SPEED * 2
                )
                if not isFalling and impliedSpeed > maxLegit * 3 and flyanim.dashTimer <= 0 then
                    -- Teletransporte forzado detectado - devolver a posición segura
                    pcall(function()
                        root.CFrame = CFrame.new(flyanim.lastSafePos + Vector3.new(0, 3, 0))
                        root.AssemblyLinearVelocity  = Vector3.new(0, 0, 0)
                        root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                    end)
                    if not root:FindFirstChildOfClass("BodyGyro") then
                        pcall(_flyMakeMotors)
                    end
                    return
                end
            end
        end

        -- Actualizar posición segura solo si es razonable
        flyanim.lastSafePos  = pos
        flyanim.lastSafeTime = now
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

local function cleanupMotors(root)
    if not root then return end
    for _, v in ipairs(root:GetChildren()) do
        if v:IsA("BodyGyro") or v:IsA("BodyVelocity") or v:IsA("BodyPosition")
        or v:IsA("BodyAngularVelocity") or v:IsA("BodyForce")
        or v:IsA("AlignOrientation") or v:IsA("LinearVelocity") then
            pcall(function() v:Destroy() end)
        end
    end
    pcall(function() root.AssemblyLinearVelocity  = Vector3.new(0, 0, 0) end)
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

local function iniciarEspacioPrimario()
    if not flyanim.enabled or flyanim.mode ~= "normal" then return end
    local nt = flyanim.normalTracks
    if not nt.espacio_prim then return end
    detenerEspacioAvanzado()
    detenerNormalExceptoBase(0.1)
    pcall(function() nt.espacio_prim:Play(0.1) end)
    flyanim.espacioTrackActivo = nt.espacio_prim
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
    if nt.brazos      and nt.brazos.IsPlaying      then pcall(function() nt.brazos:Stop(0.1) end) end
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
        local isMovingAdv = flyanim.isWDown or flyanim.isSDown or flyanim.isADown or flyanim.isDDown or flyanim.isSpaceAdv
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
                if nt.brazos then pcall(function() nt.brazos:Stop(ANIM_NORMAL.TIEMPO_TRANSICION) end) end
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
                        if ntl.brazos then pcall(function() ntl.brazos:Stop(ANIM_NORMAL.TIEMPO_TRANSICION) end) end
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
    flyanim.antiImpulseConn = RunService.Stepped:Connect(function()
        if not flyanim.enabled then
            if flyanim.antiImpulseConn then flyanim.antiImpulseConn:Disconnect(); flyanim.antiImpulseConn = nil end
            return
        end
        local char = lplr.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then return end

        -- Protección adicional contra velocidades absurdas
        local vel = root.AssemblyLinearVelocity
        local speed = vel.Magnitude
        local maxAllowed = math.max(
            BASE_SPEED * TURBO_MULT * 2,
            flyanim.DASH_SPEED * 1.5,
            flyanim.TURBO_DASH_SPEED * 1.5,
            flyanim.BACK_DASH_SPEED * 1.2
        )
        if speed > maxAllowed * 2 and flyanim.dashTimer <= 0 then
            pcall(function() root.AssemblyLinearVelocity = Vector3.new(0, 0, 0) end)
        end

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
local ANOMALY_VERT_THRESHOLD   = 250
local ANOMALY_TELEPORT_STUDS   = 40
local ANOMALY_COOLDOWN         = 0.12

local lastAnomalyFix = 0

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
    flyanim.anomalyConn = RunService.Stepped:Connect(function(_, dt)
        if not flyanim.enabled then
            if flyanim.anomalyConn then flyanim.anomalyConn:Disconnect(); flyanim.anomalyConn = nil end
            return
        end
        local char = lplr.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then flyanim.lastKnownPos = nil; return end

        local now = tick()
        local vel = root.AssemblyLinearVelocity
        local speed = vel.Magnitude
        local hum = char:FindFirstChildOfClass("Humanoid")

        -- Detección de coordenadas absurdas (void/impulso extremo)
        local pos = root.Position
        if math.abs(pos.Y) > COORD_SANITY_LIMIT or math.abs(pos.X) > COORD_SANITY_LIMIT or math.abs(pos.Z) > COORD_SANITY_LIMIT then
            if flyanim.lastKnownPos then
                pcall(function()
                    root.CFrame = CFrame.new(flyanim.lastKnownPos + Vector3.new(0, 5, 0))
                    root.AssemblyLinearVelocity  = Vector3.new(0, 0, 0)
                    root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                end)
                flyanim.dashTimer = 0
                flyanim.dashVel   = Vector3.new(0, 0, 0)
            end
            return
        end

        local maxLegitSpeed = math.max(
            BASE_SPEED * TURBO_MULT * 1.5,
            flyanim.DASH_SPEED * 1.2,
            flyanim.TURBO_DASH_SPEED * 1.2,
            flyanim.BACK_DASH_SPEED * 1.1
        )

        local isAnomaly = false

        if speed > ANOMALY_SPEED_THRESHOLD and speed > maxLegitSpeed and now - lastAnomalyFix > ANOMALY_COOLDOWN then
            isAnomaly = true
        end

        -- NOTA: eliminado el check de ANOMALY_VERT_THRESHOLD porque disparaba TP
        -- hacia arriba cuando el personaje caía con velocidad Y alta al desactivar el vuelo.
        -- La caída libre normal puede generar vel.Y > 250 y no es una anomalía.

        if flyanim.lastKnownPos and now - lastAnomalyFix > ANOMALY_COOLDOWN then
            local posDelta = (root.Position - flyanim.lastKnownPos).Magnitude
            local maxLegitMove = (BASE_SPEED * TURBO_MULT + flyanim.DASH_SPEED) * dt * 3
            -- Ignorar delta de posición cuando hay velocidad vertical grande (caída libre)
            local isFallingFast = vel.Y < -30
            if not isFallingFast and posDelta > math.max(ANOMALY_TELEPORT_STUDS, maxLegitMove) then
                -- Solo es anomalía si no es un dash activo
                if flyanim.dashTimer <= 0 then
                    isAnomaly = true
                end
            end
        end

        if hum and hum:GetState() == Enum.HumanoidStateType.Ragdoll and now - lastAnomalyFix > ANOMALY_COOLDOWN then
            isAnomaly = true
        end

        if isAnomaly then
            lastAnomalyFix = now
            flyanim.ragdollDetected = true

            -- Si la posición actual es absurda y hay lastKnownPos, volver ahí
            local recoverPos = flyanim.lastKnownPos and (flyanim.lastKnownPos + Vector3.new(0, 3, 0))

            pcall(function() root.AssemblyLinearVelocity  = Vector3.new(0, 0, 0) end)
            pcall(function() root.AssemblyAngularVelocity = Vector3.new(0, 0, 0) end)

            if recoverPos then
                pcall(function() root.CFrame = CFrame.new(recoverPos) end)
            end

            flyanim.dashTimer = 0
            flyanim.dashVel   = Vector3.new(0, 0, 0)

            if hum then
                pcall(function()
                    hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
                    hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
                    hum.PlatformStand = true
                    hum:ChangeState(Enum.HumanoidStateType.Physics)
                end)
            end

            local needsMotors = (not root:FindFirstChildOfClass("BodyGyro"))
                             or (not root:FindFirstChildOfClass("BodyVelocity"))
                             or (not root:FindFirstChildOfClass("BodyForce"))
            if needsMotors then
                pcall(_flyMakeMotors)
            else
                flyanim.bg = root:FindFirstChildOfClass("BodyGyro")
                flyanim.bv = root:FindFirstChildOfClass("BodyVelocity")
                flyanim.bf = root:FindFirstChildOfClass("BodyForce")
                if flyanim.bv then flyanim.bv.velocity = Vector3.new(0,0,0) end
                if flyanim.bg then flyanim.bg.cframe = root.CFrame end
            end

            -- Restaurar C0 según el modo actual
            if flyanim.mode == "fast" and not flyanim.turboPreImpulsoActivo and not flyanim.turboRenderConn then
                local rj = flyanim.rootJoint
                local oc = flyanim.originalC0
                if rj and oc then
                    pcall(function()
                        rj.C0 = oc
                            * CFrame.new(0, ANIM_TURBO.COMPENSACION_ALTURA, 0)
                            * CFrame.Angles(math.rad(ANIM_TURBO.INCLINACION_GRADOS), 0, 0)
                    end)
                end
            elseif flyanim.mode == "turbo" and not flyanim.megaRenderConn then
                local rj = flyanim.rootJoint
                local oc = flyanim.originalC0
                if rj and oc then
                    pcall(function()
                        rj.C0 = oc
                            * CFrame.new(0, ANIM_MEGA.COMPENSACION_ALTURA, 0)
                            * CFrame.Angles(math.rad(ANIM_MEGA.INCLINACION_GRADOS), 0, 0)
                    end)
                end
            else
                restaurarC0Inmediato()
            end

            task.defer(function()
                if not flyanim.enabled then return end
                flyanim.ragdollDetected = false
            end)
        end

        flyanim.lastKnownPos = root.Position
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

    flyanim.animBlockRenderConn = RunService.RenderStepped:Connect(function()
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

    local smokeScale    = 0.8 + t * 1.8
    local smokeAlpha    = 0.10 + t * 0.20
    local smokeAlphaEnd = 0.68 + t * 0.22
    local soundVol      = 0.30 + t * 0.55

    -- DOBLE de piedras desde cualquier caída, escalado con altura, máximo 28 sin lag
    -- Mínimo 4 rocas (era 0 hasta intensity<60), máximo 28 (era 14 antes del doble)
    local numRocks = math.floor(4 + t * 24)  -- rango: 4 a 28
    numRocks = math.min(numRocks, 28)         -- hard cap anti-lag

    -- Encontrar la Y real del suelo bajo el punto de impacto
    -- position es el centro del HRP (~3 studs sobre el suelo); sin esto
    -- los efectos flotan en el aire en vez de aparecer en la superficie.
    local groundY = position.Y  -- fallback si no hay suelo detectable
    do
        local char = lplr.Character
        local rp = RaycastParams.new()
        rp.FilterType = Enum.RaycastFilterType.Exclude
        if char then rp.FilterDescendantsInstances = {char} end
        local hit = workspace:Raycast(position, Vector3.new(0, -8, 0), rp)
        if hit then
            groundY = hit.Position.Y
        end
    end
    local groundPos = Vector3.new(position.X, groundY, position.Z)

    local DUST_COLOR       = Color3.fromRGB(185, 180, 175)
    local DUST_COLOR_INNER = Color3.fromRGB(210, 207, 205)

    task.spawn(function()
        local snd = Instance.new("Sound")
        snd.SoundId = SFX_LANDING
        snd.Volume  = soundVol
        snd.RollOffMaxDistance = 0
        snd.Parent  = SoundService
        snd:Play()
        snd.Ended:Connect(function() pcall(function() snd:Destroy() end) end)
        task.delay(8, function() pcall(function() snd:Destroy() end) end)
    end)

    -- Anillo principal de humo
    task.spawn(function()
        local ringSize = smokeScale * 9
        local p = Instance.new("Part")
        p.Anchored    = true; p.CanCollide  = false; p.CanTouch = false; p.CastShadow = false
        p.Transparency = 1; p.Size = Vector3.new(ringSize, ringSize, 0.05)
        p.CFrame = CFrame.new(groundPos + Vector3.new(0, 0.12, 0)) * CFrame.Angles(math.rad(90), 0, 0)
        p.Parent = workspace

        local sg = Instance.new("SurfaceGui", p)
        sg.Adornee = p; sg.Face = Enum.NormalId.Front; sg.AlwaysOnTop = false
        sg.LightInfluence = 0; sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud; sg.PixelsPerStud = 40

        local img = Instance.new("ImageLabel", sg)
        img.Image = SMOKE_RING_TEX; img.Size = UDim2.new(1,0,1,0); img.BackgroundTransparency = 1
        img.ImageColor3 = DUST_COLOR; img.ImageTransparency = smokeAlpha; img.ScaleType = Enum.ScaleType.Fit

        local peakSize = ringSize * (2.5 + t * 2.0)
        TweenService:Create(p, TweenInfo.new(0.65, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
            {Size = Vector3.new(peakSize, peakSize, 0.05)}):Play()
        TweenService:Create(img, TweenInfo.new(0.65, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
            {ImageTransparency = smokeAlphaEnd}):Play()
        task.delay(0.70, function() pcall(function() p:Destroy() end) end)
    end)

    -- Segundo anillo mas pequeno
    task.spawn(function()
        task.wait(0.05)
        local ringSize2 = smokeScale * 5
        local p2 = Instance.new("Part")
        p2.Anchored = true; p2.CanCollide = false; p2.CanTouch = false; p2.CastShadow = false
        p2.Transparency = 1; p2.Size = Vector3.new(ringSize2, ringSize2, 0.05)
        p2.CFrame = CFrame.new(groundPos + Vector3.new(0, 0.07, 0)) * CFrame.Angles(math.rad(90), 0, 0)
        p2.Parent = workspace
        local sg2 = Instance.new("SurfaceGui", p2)
        sg2.Adornee = p2; sg2.Face = Enum.NormalId.Front; sg2.AlwaysOnTop = false
        sg2.LightInfluence = 0; sg2.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud; sg2.PixelsPerStud = 40
        local img2 = Instance.new("ImageLabel", sg2)
        img2.Image = SMOKE_RING_TEX; img2.Size = UDim2.new(1,0,1,0); img2.BackgroundTransparency = 1
        img2.ImageColor3 = DUST_COLOR_INNER
        img2.ImageTransparency = smokeAlpha + 0.10; img2.ScaleType = Enum.ScaleType.Fit
        local peakSize2 = ringSize2 * (2.0 + t * 1.5)
        TweenService:Create(p2, TweenInfo.new(0.50, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
            {Size = Vector3.new(peakSize2, peakSize2, 0.05)}):Play()
        TweenService:Create(img2, TweenInfo.new(0.50, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
            {ImageTransparency = smokeAlphaEnd + 0.10}):Play()
        task.delay(0.55, function() pcall(function() p2:Destroy() end) end)
    end)

    -- Piedrecitas: siempre presentes, doble cantidad, escalado con intensidad
    task.spawn(function()
        local ROCK_BASE = Color3.fromRGB(130, 125, 118)
        -- Distribuimos las rocas en lotes pequeños para no hacer spike de lag
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
            if spawned < numRocks then task.wait(0.01) end  -- micro-pausa entre lotes
        end
    end)
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

    -- Anti-bounce: solo un pulso inicial, luego liberar
    if root then
        pcall(function() root.AssemblyLinearVelocity = Vector3.new(0, 0, 0) end)
        pcall(function() root.AssemblyAngularVelocity = Vector3.new(0, 0, 0) end)
        local quickBounce = Instance.new("BodyVelocity")
        quickBounce.Velocity  = Vector3.new(0, 0, 0)
        quickBounce.MaxForce  = Vector3.new(9e9, 9e9, 9e9)
        quickBounce.Parent    = root
        humanoid.PlatformStand = true
        task.defer(function()
            pcall(function() quickBounce:Destroy() end)
            if humanoid and humanoid.Parent then
                humanoid.PlatformStand = false
                pcall(function() humanoid:ChangeState(Enum.HumanoidStateType.Landed) end)
            end
        end)
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
        pcall(function() hum2:ChangeState(Enum.HumanoidStateType.GettingUp) end)
        task.wait(0.08)
        pcall(function() hum2:ChangeState(Enum.HumanoidStateType.Landed) end)
        task.wait(0.05)
        pcall(function() hum2:ChangeState(Enum.HumanoidStateType.Running) end)
    end
end

-- ============================================================
-- SISTEMA DE COMBOS
-- ============================================================

local function playComboAnimRaw(animId, speed, onStopped, onCancelable)
    local t = getTrack(animId)
    if not t then if onStopped then onStopped() end; return nil end

    for id, track in pairs(flyanim.tracks) do
        if id ~= animId and id ~= ANIM.levitacion and track and track.IsPlaying then
            pcall(function() track:Stop(0.05) end)
        end
    end
    for key, track in pairs(flyanim.normalTracks) do
        if key ~= "levitacion" then
            pcall(function() if track and track.IsPlaying then track:Stop(0.05) end end)
        end
    end

    t.Looped   = false
    t.Priority = Enum.AnimationPriority.Action4
    if t.IsPlaying then pcall(function() t:Stop(0) end) end
    pcall(function() t:Play(0.05, 1, 1) end)
    pcall(function() t:AdjustSpeed(speed or 3.0) end)

    flyanim.comboAnimStartTime = tick()
    flyanim.comboBusy = true

    task.spawn(function()
        local timeout = tick() + 2
        while t.Length == 0 and tick() < timeout do task.wait() end
        if t.Length > 0 and t.IsPlaying then pcall(function() t.TimePosition = 0 end) end

        local minWait = COMBO_ANIM_MIN_DURATION
        local elapsed = tick() - flyanim.comboAnimStartTime
        if elapsed < minWait then task.wait(minWait - elapsed) end

        local cancelFrame = t.Length * 0.40
        local cancelTimeout = tick() + 2
        while t.IsPlaying and t.TimePosition < cancelFrame and tick() < cancelTimeout do
            task.wait()
        end
        flyanim.comboBusy = false
        if onCancelable then onCancelable() end
    end)

    if onStopped then
        task.spawn(function()
            t.Stopped:Wait()
            onStopped()
        end)
    end
    return t
end

local function resetCombo()
    flyanim.comboStep      = 0
    flyanim.comboLastClick = 0
    flyanim.combo2LastUsed = nil
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

    stopComboC0Lock()

    if not flyanim.enabled then return end

    for id, track in pairs(flyanim.tracks) do
        if id ~= ANIM.levitacion and track and track.IsPlaying then
            pcall(function() track:Stop(0.1) end)
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

local function ejecutarPuno4()
    local animId  = ANIM.combo4
    local myToken = flyanim.comboToken
    local t = getTrack(animId)
    if not t then finalizarCombo(); return end

    for id, track in pairs(flyanim.tracks) do
        if id ~= animId and id ~= ANIM.levitacion and track and track.IsPlaying then
            pcall(function() track:Stop(0.05) end)
        end
    end
    for key, track in pairs(flyanim.normalTracks) do
        if key ~= "levitacion" then
            pcall(function() if track and track.IsPlaying then track:Stop(0.05) end end)
        end
    end

    t.Looped   = false
    t.Priority = Enum.AnimationPriority.Action4
    if t.IsPlaying then pcall(function() t:Stop(0) end) end
    pcall(function() t:Play(0.05, 1, 1) end)
    pcall(function() t:AdjustSpeed(3.0) end)

    flyanim.comboAnimStartTime = tick()
    flyanim.comboBusy = true

    task.spawn(function()
        local timeout = tick() + 3
        while t.Length == 0 and tick() < timeout do task.wait() end
        if t.Length == 0 then finalizarCombo(); return end

        if flyanim.comboToken ~= myToken then return end

        local length    = t.Length
        local target40  = length * 0.40
        local target65  = length * 0.65

        timeout = tick() + 3
        while t.IsPlaying and t.TimePosition < target40 and tick() < timeout do
            if flyanim.comboToken ~= myToken then return end
            task.wait()
        end
        flyanim.comboBusy = false

        timeout = tick() + 3
        while t.IsPlaying and t.TimePosition < target65 and tick() < timeout do
            if flyanim.comboToken ~= myToken then return end
            task.wait()
        end
        if not t.IsPlaying then finalizarCombo(); return end
        if flyanim.comboToken ~= myToken then return end

        flyanim.combo4Frozen = true
        pcall(function() t:AdjustSpeed(0) end)
        pcall(function() t.TimePosition = target65 end)

        local waitStart = tick()
        while tick() - waitStart < 0.3 do
            if flyanim.comboToken ~= myToken then
                flyanim.combo4Frozen = false
                return
            end
            if not flyanim.combo4Frozen then
                pcall(function() t:AdjustSpeed(10) end)
                t.Looped = false
                task.spawn(function()
                    local to2 = tick() + 1
                    while t.IsPlaying and tick() < to2 do task.wait() end
                    finalizarCombo()
                end)
                return
            end
            task.wait(0.03)
        end

        flyanim.combo4Frozen = false
        pcall(function() t:AdjustSpeed(1) end)
        t.Looped = false
        task.spawn(function()
            local to3 = tick() + 3
            while t.IsPlaying and tick() < to3 do task.wait() end
            finalizarCombo()
        end)
    end)
end

local function handleComboClick()
    if not flyanim.enabled then return end
    if flyanim.turboPreImpulsoActivo then return end
    if flyanim.comboBusy then return end

    local now  = tick()
    local step = flyanim.comboStep

    if flyanim.combo4Frozen then
        flyanim.combo4Frozen = false
        return
    end

    local spaceDown = UserInputService:IsKeyDown(Enum.KeyCode.Space)
    local isCombo4SpaceAttempt = (step == 3 and spaceDown)
    local minGap = isCombo4SpaceAttempt and COMBO4_SPACE_MIN_GAP or COMBO_MIN_GAP

    if now - flyanim.comboLastClick < minGap then return end

    if flyanim.comboAnimStartTime > 0 and (now - flyanim.comboAnimStartTime) < COMBO_ANIM_MIN_DURATION then return end

    if step >= 1 then
        if now - flyanim.comboLastClick > COMBO_CHAIN_WINDOW then
            if not flyanim.comboPlaying then
                resetCombo()
                step = 0
            else
                return
            end
        end
    end

    local nextStep = step + 1
    flyanim.comboStep      = nextStep
    flyanim.comboLastClick = now

    flyanim.comboToken = (flyanim.comboToken or 0) + 1
    local myToken = flyanim.comboToken

    if flyanim.idleAnimConn then flyanim.idleAnimConn:Disconnect(); flyanim.idleAnimConn = nil end

    if flyanim.isBlocking then
        stopBlocking()
        flyanim.blockCancelledByCombo = true
    end

    if nextStep == 1 then
        flyanim.comboPlaying = true
        startComboC0Lock()
        playComboAnimRaw(ANIM.combo1, 3.0, function()
            if flyanim.comboToken ~= myToken then return end
            if flyanim.comboStep == 1 then
                task.wait(0.05)
                if flyanim.comboStep == 1 and flyanim.comboToken == myToken then
                    resetCombo(); finalizarCombo()
                end
            end
        end)

    elseif nextStep == 2 then
        local r = math.random(1, 2)
        local chosenId, chosenKey
        if r == 1 then chosenId = ANIM.combo2a; chosenKey = "a"
        else chosenId = ANIM.combo2b; chosenKey = "b" end
        flyanim.combo2LastUsed = chosenKey
        playComboAnimRaw(chosenId, 3.0, function()
            if flyanim.comboToken ~= myToken then return end
            if flyanim.comboStep == 2 then
                task.wait(0.05)
                if flyanim.comboStep == 2 and flyanim.comboToken == myToken then
                    resetCombo(); finalizarCombo()
                end
            end
        end)

    elseif nextStep == 3 then
        local chosenId
        if flyanim.combo2LastUsed == "a" then chosenId = ANIM.combo3b
        else chosenId = ANIM.combo3a end
        playComboAnimRaw(chosenId, 3.0, function()
            if flyanim.comboToken ~= myToken then return end
            if flyanim.comboStep == 3 then
                task.wait(0.1)
                if flyanim.comboStep == 3 and flyanim.comboToken == myToken then
                    resetCombo(); finalizarCombo()
                end
            end
        end)

    elseif nextStep == 4 then
        if spaceDown then
            flyanim.comboBusy = true
            local t = getTrack(ANIM.combo4_space)
            if t then
                for id, track in pairs(flyanim.tracks) do
                    if id ~= ANIM.combo4_space and id ~= ANIM.levitacion and track and track.IsPlaying then
                        pcall(function() track:Stop(0.05) end)
                    end
                end
                for key, track in pairs(flyanim.normalTracks) do
                    if key ~= "levitacion" then
                        pcall(function() if track and track.IsPlaying then track:Stop(0.05) end end)
                    end
                end
                t.Looped = false; t.Priority = Enum.AnimationPriority.Action4
                if t.IsPlaying then pcall(function() t:Stop(0) end) end
                pcall(function() t:Play(0.05, 1, 1); t:AdjustSpeed(1.0) end)
                task.spawn(function()
                    local timeout2 = tick() + 2
                    while t.Length == 0 and tick() < timeout2 do task.wait() end
                    flyanim.comboBusy = false
                    task.spawn(function()
                        t.Stopped:Wait()
                        if flyanim.comboToken ~= myToken then return end
                        resetCombo()
                        task.wait(0.3)
                        finalizarCombo()
                    end)
                end)
            else
                flyanim.comboBusy = false
                resetCombo(); finalizarCombo()
            end
        else
            ejecutarPuno4()
            flyanim.comboStep = 0
        end
    end
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
    flyanim.comboAnimStartTime = 0

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

    local lastHoldFire = 0
    flyanim.comboHoldConn = RunService.Heartbeat:Connect(function()
        if not flyanim.enabled then return end
        if not flyanim.mouseHeld then return end
        if isTyping() then return end
        local now = tick()
        if now - lastHoldFire < COMBO_HOLD_INTERVAL then return end
        if flyanim.comboBusy then return end
        if now - flyanim.comboLastClick < COMBO_MIN_GAP then return end
        lastHoldFire = now
        handleComboClick()
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
    flyanim.comboAnimStartTime = 0
end

-- ============================================================
-- MEGA TURBO UP
-- ============================================================

local function activateMegaTurboUp()
    if flyanim.megaTurboUpActive then return end
    if flyanim.mode == "turbo" then return end
    flyanim.megaTurboUpActive = true
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
                    -- Yo estoy arriba → el target está abajo
                    heightLabel.Text = "↓ "..heightDiff.." "..FT.height_below
                    heightLabel.TextColor3 = Color3.fromRGB(255,200,100)
                elseif heightDiff < 0 then
                    -- Yo estoy abajo → el target está arriba
                    heightLabel.Text = "↑ "..math.abs(heightDiff).." "..FT.height_above
                    heightLabel.TextColor3 = Color3.fromRGB(150,220,255)
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
        -- Sacar al personaje de freefall/caída inmediatamente
        hum.PlatformStand = false
        pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
    end
    setupAnimator(char)
    _flyMakeMotors(); _flyBuildGui(); startIdleWatcher(); startComboListener()
    flyanim._normalPlayId = 1
    iniciarCicloNormal(1)
    startLockSystem(); startBrakeSystem(); startAntiImpulse(); startMegaTurboUpListener()
    startAnomalyProtection(); startAnimBlockLoop(); startTeleportGuard()

    if flyanim.tpMoveConn then flyanim.tpMoveConn:Disconnect(); flyanim.tpMoveConn = nil end
    flyanim.tpMoveConn = RunService.Stepped:Connect(function(_, dt)
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
    flyanim.rsConn = RunService.RenderStepped:Connect(function(dt)
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

local function _flyOff()
    local char = lplr.Character

    -- Cancelar watchdog y tokens de C0 de forma síncrona PRIMERO,
    -- antes de cualquier otro sistema, para evitar que el watchdog
    -- sobreescriba el C0 restaurado un frame después.
    heightTweenToken = heightTweenToken + 1  -- cancela tweens de compensación de altura
    flyanim.c0ControlToken = (flyanim.c0ControlToken or 0) + 1
    flyanim.c0HeightToken  = (flyanim.c0HeightToken  or 0) + 1
    if flyanim.c0HeightConn then
        flyanim.c0HeightConn:Disconnect()
        flyanim.c0HeightConn = nil
    end
    clearC0Desired()
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

    flyanim.enabled = false
    flyanim.comboPlaying = false; flyanim.comboBusy = false; flyanim.combo4Frozen = false
    flyanim.turboPreImpulsoActivo = false
    flyanim.turboPreImpulsoToken  = (flyanim.turboPreImpulsoToken or 0) + 1
    flyanim.dashTimer=0; flyanim.dashVel=Vector3.new(0,0,0)
    flyanim.megaTurboUpActive=false; flyanim.spaceHoldStart=nil
    flyanim.mouseHeld = false; flyanim.fKeyHeld = false; flyanim.blockCancelledByCombo = false
    flyanim.comboAnimStartTime = 0
    -- FLY OFF = TODO se apaga: noclip, espacio, ctrl, estado
    flyanim.isSpaceAdv       = false
    flyanim.noclipSpaceActive = false
    flyanim.noclipCtrlActive  = false
    if flyanim.spaceHoldTimerAdv then task.cancel(flyanim.spaceHoldTimerAdv); flyanim.spaceHoldTimerAdv = nil end
    if flyanim.idleAnimConn then flyanim.idleAnimConn:Disconnect(); flyanim.idleAnimConn = nil end
    flyanim.idleWatchToken = (flyanim.idleWatchToken or 0) + 1
    if dashConnection then dashConnection:Disconnect(); dashConnection=nil end

    -- NOTA: NO incrementar c0ControlToken de nuevo aquí (ya se hizo arriba)

    if flyanim.turboRenderConn then flyanim.turboRenderConn:Disconnect(); flyanim.turboRenderConn = nil end
    if flyanim.megaRenderConn  then flyanim.megaRenderConn:Disconnect();  flyanim.megaRenderConn  = nil end


    detenerNormalTracks(0.1); detenerPoseTurbo(); detenerPoseMega(); detenerEspacioAvanzado()
    stopBlocking(); stopParticleEmitter(); stopBrakeSystem(); stopAntiImpulse()
    stopMegaTurboUpListener(); stopAnomalyProtection(); stopComboC0Lock(); stopAnimBlockLoop()
    stopTeleportGuard(); detenerWatchdogAltura()

    flyanim.noclipSpaceActive = false
    flyanim.noclipCtrlActive  = false
    setNoclip(false)

    if flyanim.rsConn    then flyanim.rsConn:Disconnect(); flyanim.rsConn=nil end
    if flyanim.tpMoveConn then flyanim.tpMoveConn:Disconnect(); flyanim.tpMoveConn=nil end
    if flyanim.idleTimer then task.cancel(flyanim.idleTimer); flyanim.idleTimer=nil end
    stopComboListener()
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

    if rootCurrent then
        cleanupMotors(rootCurrent)
        local _, ry, _ = rootCurrent.CFrame:ToOrientation()
        rootCurrent.CFrame = CFrame.new(rootCurrent.Position) * CFrame.Angles(0, ry, 0)
    end

    flyanim.bg=nil; flyanim.bv=nil; flyanim.bf=nil; flyanim.mode="normal"; flyanim.speed=BASE_SPEED
    _flyDestroyGui(); stopLockSystem()

    if flyanim.damageConn then flyanim.damageConn:Disconnect(); flyanim.damageConn = nil end

    if not charCurrent or not hum or hum.Health <= 0 then
        if flyanim.animConn then flyanim.animConn:Disconnect(); flyanim.animConn = nil end
        local animScript2 = charCurrent and charCurrent:FindFirstChild("Animate") or flyanim.animScript
        if animScript2 then animScript2.Disabled = false; flyanim.animScript = nil end
        flyanim.landingHeight = nil
        return
    end

    hum.PlatformStand = false
    hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
    hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)

    if rootCurrent then
        for _, part in ipairs(charCurrent:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = true end
        end
    end

    -- CAMBIO SALVAJE: zerear TODA la velocidad del HRP (incluyendo Y positivo que provoca el rebote)
    -- y mantener un BodyVelocity que fuerce velocidad cero por 2 frames antes de soltarlo
    if rootCurrent then
        pcall(function() rootCurrent.AssemblyLinearVelocity  = Vector3.new(0, 0, 0) end)
        pcall(function() rootCurrent.AssemblyAngularVelocity = Vector3.new(0, 0, 0) end)
        local zeroLock = Instance.new("BodyVelocity")
        zeroLock.Velocity  = Vector3.new(0, 0, 0)
        zeroLock.MaxForce  = Vector3.new(9e9, 9e9, 9e9)
        zeroLock.Parent    = rootCurrent
        task.wait()
        task.wait()
        pcall(function() zeroLock:Destroy() end)
        pcall(function() rootCurrent.AssemblyLinearVelocity = Vector3.new(0, 0, 0) end)
    else
        task.wait()
    end

    hum:ChangeState(Enum.HumanoidStateType.Freefall)

    local capturedHeight   = flyanim.landingHeight
    local capturedVelocity = math.max(flyanim.landingVelocity, flyanim.landingVelocityCapture)

    if capturedHeight < 10 then
        if flyanim.animConn then flyanim.animConn:Disconnect(); flyanim.animConn = nil end
        local animScript3 = charCurrent and charCurrent:FindFirstChild("Animate") or flyanim.animScript
        if animScript3 then animScript3.Disabled = false; flyanim.animScript = nil end
        if hum then
            hum.PlatformStand = false
            pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
        end
        flyanim.landingHeight = nil
        return
    end

    if flyanim.animConn then flyanim.animConn:Disconnect(); flyanim.animConn = nil end

    flyanim.waitingLand = true
    if flyanim.landConn then flyanim.landConn:Disconnect() end
    flyanim.landConn = hum.StateChanged:Connect(function(_, newState)
        if not flyanim.waitingLand then flyanim.landConn:Disconnect(); flyanim.landConn=nil; return end
        if newState == Enum.HumanoidStateType.Landed or newState == Enum.HumanoidStateType.Running
        or newState == Enum.HumanoidStateType.RunningNoPhysics or newState == Enum.HumanoidStateType.Dead then
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
