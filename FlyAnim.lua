-- FlyAnim.lua
-- Módulo responsable de todas las animaciones, poses, combos, bloqueo,
-- gestión de tracks y RootJoint durante el vuelo.

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- ============================================================
-- IDs de animaciones
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

-- ============================================================
-- Constantes de animación
-- ============================================================
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

local ANIM_TURBO = {
    COMPENSACION_ALTURA    = 2,
    INCLINACION_GRADOS     = 25,
    FRAME_CONGELADO        = 0.1,
    FRAME_VOLADO_CONGELADO = 0.35,
    AMPLITUD_LEVITACION    = 0.15,
    FRECUENCIA_LEVITACION  = 1.5,
    TIEMPO_CONTRAERSE      = 0.4,
    TIEMPO_PAUSA           = 0.1,
    TIEMPO_TRANSICION      = 0.4,
    INCLINACION_DESPEGUE   = 90,
}

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

-- Duración de pasos de combo (segundos)
local COMBO_STEP_DURATION  = {0.47, 0.47, 0.53, 0.68}
local COMBO_PENDING_WINDOW = 1.0
local COMBO_MIN_GAP        = 0.08

-- ============================================================
-- Estado interno del módulo
-- ============================================================
local state = {
    -- Referencias
    animator        = nil,
    tracks          = {},
    normalTracks    = {},
    rootJoint       = nil,
    originalC0      = nil,
    animConn        = nil,
    damageConn      = nil,

    -- Modo y flags
    enabled         = false,
    mode            = "normal",   -- normal, fast, turbo, megaup
    megaTurboUpActive = false,

    -- Movimiento
    isWDown = false, isSDown = false, isADown = false, isDDown = false,
    isSpaceAdv = false,
    spaceHoldTimerAdv = nil,
    espacioTrackActivo = nil,

    -- Sistema de bloqueo
    isBlocking       = false,
    blockTrack       = nil,
    blockRenderConn  = nil,
    blockCancelledByCombo = false,
    lastDamageTime   = 0,
    fKeyHeld         = false,

    -- Combos
    comboStep       = 0,
    comboLastClick  = 0,
    comboPlaying    = false,
    comboBusy       = false,
    combo4Frozen    = false,
    comboToken      = 0,
    comboPendingClick = false,
    comboConn       = nil,
    comboHoldConn   = nil,
    comboEndConn    = nil,
    comboC0Conn     = nil,
    mouseHeld       = false,

    -- Sistema de idle / brazos
    idleAnimConn    = nil,
    idleWatchToken  = 0,
    isBrazosActive  = false,
    idleTimerAnim   = 0,

    -- Sistema lateral/atrás para modo normal
    lateralKilled   = true,
    atrasKilled     = true,
    currentLateralId = 0,
    currentAtrasId   = 0,
    lateralTarget    = 0,
    atrasTarget      = 0,
    lateralLoopId    = 0,
    atrasLoopId      = 0,
    atrasCurrentSpeed = 0.06,
    contA = 0, contD = 0, contS = 0,
    piernaPrefA = 0.50, piernaPrefD = 0.25, piernaPrefS = 0.50,
    _normalPlayId = 0,

    -- Poses turbo y mega
    turboRenderConn    = nil,
    megaRenderConn     = nil,
    turboPreImpulsoActivo = false,
    turboPreImpulsoToken  = 0,
    c0ControlToken     = 0,

    -- Temporal para tweens de altura
    heightTweenToken = 0,
}

-- ============================================================
-- Funciones auxiliares locales (extraídas del original)
-- ============================================================
local function getTrack(animId)
    if not state.animator then return nil end
    if state.tracks[animId] then return state.tracks[animId] end
    local ok, obj = pcall(function()
        local a = Instance.new("Animation")
        a.AnimationId = animId
        return a
    end)
    if not ok then return nil end
    local ok2, t = pcall(function()
        local track = state.animator:LoadAnimation(obj)
        track.Priority = Enum.AnimationPriority.Action4
        return track
    end)
    if not ok2 or not t then return nil end
    state.tracks[animId] = t
    return t
end

local function stopAllExcept(keepId, fade, alsoKeepLevitacion)
    fade = fade or 0.12
    local levId = ANIM.levitacion
    for id, t in pairs(state.tracks) do
        local isKeep = (id == keepId)
        local isLev  = (alsoKeepLevitacion and id == levId)
        if not isKeep and not isLev and t and t.IsPlaying then pcall(function() t:Stop(fade) end) end
    end
    for _, t in pairs(state.normalTracks) do
        if t and t ~= state.normalTracks.levitacion and t.IsPlaying then
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

local function detenerNormalTracks(fade)
    fade = fade or 0
    for _, t in pairs(state.normalTracks) do
        pcall(function() if t and t.IsPlaying then t:Stop(fade) end end)
    end
    state.lateralKilled = true;  state.lateralLoopId = 0
    state.atrasKilled   = true;  state.atrasLoopId   = 0
    if state.idleAnimConn then state.idleAnimConn:Disconnect(); state.idleAnimConn = nil end
    state.isBrazosActive = false
    state.idleTimerAnim = 0
end

local function detenerNormalExceptoBase(fade)
    fade = fade or 0
    local nt = state.normalTracks
    local baseIds = {nt.estatica, nt.levitacion}
    for _, t in pairs(nt) do
        local isBase = false
        for _, b in ipairs(baseIds) do if t == b then isBase = true; break end end
        if not isBase and t and t.IsPlaying then pcall(function() t:Stop(fade) end) end
    end
    state.lateralKilled = true; state.lateralLoopId = 0
    state.atrasKilled   = true; state.atrasLoopId   = 0
end

local function detenerEspacioAvanzado()
    if state.espacioTrackActivo then
        pcall(function() state.espacioTrackActivo:Stop(0.1) end)
        state.espacioTrackActivo = nil
    end
    if state.spaceHoldTimerAdv then
        task.cancel(state.spaceHoldTimerAdv)
        state.spaceHoldTimerAdv = nil
    end
end

local function obtenerPiernaS()
    local C = ANIM_NORMAL
    if state.isADown then
        state.contA = state.contA + 1
        if state.contA >= 5 then
            state.piernaPrefA = (state.piernaPrefA == C.OSCILA_LEFT) and C.OSCILA_RIGHT or C.OSCILA_LEFT
            state.contA = 0
        end
        return state.piernaPrefA
    elseif state.isDDown then
        state.contD = state.contD + 1
        if state.contD >= 5 then
            state.piernaPrefD = (state.piernaPrefD == C.OSCILA_RIGHT) and C.OSCILA_LEFT or C.OSCILA_RIGHT
            state.contD = 0
        end
        return state.piernaPrefD
    else
        state.contS = state.contS + 1
        if state.contS >= 5 then
            state.piernaPrefS = (state.piernaPrefS == C.OSCILA_LEFT) and C.OSCILA_RIGHT or C.OSCILA_LEFT
            state.contS = 0
        end
        return state.piernaPrefS
    end
end

local function cancelarLateral()
    state.currentLateralId = state.currentLateralId + 1
    state.lateralKilled = true
end

local function ejecutarLateral(inicio, thisId)
    local nt = state.normalTracks
    if not nt.lateral then return end
    while nt.lateral.Length == 0 do task.wait() end
    if state.currentLateralId ~= thisId then return end
    state.lateralTarget = inicio
    state.lateralKilled = false
    if state.lateralLoopId ~= 0 then
        state.lateralLoopId = thisId
        return
    end
    state.lateralLoopId = thisId
    normPlaySafe(nt.lateral)
    nt.lateral:AdjustSpeed(0)
    nt.lateral.TimePosition = nt.lateral.Length * inicio
    nt.lateral:AdjustWeight(ANIM_NORMAL.PESO_LATERAL, ANIM_NORMAL.TRANSICION_FLUIDA)
    local currentPos = inicio
    while true do
        task.wait(0.05)
        if state.lateralKilled then
            normStopSafe(nt.lateral)
            state.lateralLoopId = 0
            state.lateralKilled = false
            return
        end
        if state.currentLateralId ~= state.lateralLoopId then
            state.lateralLoopId = state.currentLateralId
        end
        local delta = state.lateralTarget - currentPos
        if math.abs(delta) < ANIM_NORMAL.LATERAL_LERP_VEL then
            currentPos = state.lateralTarget
        else
            currentPos = currentPos + (delta > 0 and ANIM_NORMAL.LATERAL_LERP_VEL or -ANIM_NORMAL.LATERAL_LERP_VEL)
        end
        nt.lateral.TimePosition = nt.lateral.Length * currentPos
    end
end

local function ejecutarDashAtrasAnim(targetStartPercent, velocidadRapida)
    local nt = state.normalTracks
    if not nt.mov_back then return end
    state.atrasTarget = targetStartPercent
    state.atrasKilled = false
    local nuevaVelocidad = velocidadRapida and ANIM_NORMAL.VEL_ATRAS_RAPIDO or ANIM_NORMAL.VEL_ATRAS_NORMAL
    if state.atrasLoopId ~= 0 then
        state.atrasLoopId = state.currentAtrasId
        state.atrasCurrentSpeed = nuevaVelocidad
        return
    end
    state.atrasLoopId       = state.currentAtrasId
    state.atrasCurrentSpeed = nuevaVelocidad
    local thisLoop = state.atrasLoopId
    task.spawn(function()
        while nt.mov_back.Length == 0 do task.wait() end
        if state.atrasLoopId ~= thisLoop then return end
        normPlaySafe(nt.mov_back)
        if nt.mov_brazos then normPlaySafe(nt.mov_brazos) end
        nt.mov_back:AdjustSpeed(0)
        nt.mov_back.TimePosition = nt.mov_back.Length * targetStartPercent
        local currentPos  = targetStartPercent
        local oscilaDir   = 1
        local oscilaTimer = 0
        while true do
            task.wait(0.05)
            if state.atrasKilled then
                nt.mov_back:AdjustSpeed(1)
                normStopSafe(nt.mov_back)
                if nt.mov_brazos then normStopSafe(nt.mov_brazos) end
                state.atrasLoopId = 0
                state.atrasKilled = false
                return
            end
            if state.currentAtrasId ~= state.atrasLoopId then
                state.atrasLoopId = state.currentAtrasId
            end
            local vel   = state.atrasCurrentSpeed
            local delta = state.atrasTarget - currentPos
            if math.abs(delta) < vel then currentPos = state.atrasTarget
            else currentPos = currentPos + (delta > 0 and vel or -vel) end
            oscilaTimer = oscilaTimer + 0.05
            if oscilaTimer >= 0.8 then oscilaDir = -oscilaDir; oscilaTimer = 0 end
            local oscilaOffset = oscilaDir * ANIM_NORMAL.OSCILA_VEL * oscilaTimer / 0.8 * 0.04
            nt.mov_back.TimePosition = nt.mov_back.Length * math.clamp(currentPos + oscilaOffset, 0, 1)
        end
    end)
end

local function esDiagonalS()
    return (state.isSDown and state.isADown and not state.isWDown and not state.isDDown) or
           (state.isSDown and state.isDDown and not state.isWDown and not state.isADown)
end

local function resolverEstadoMovimiento()
    local w, s, a, d = state.isWDown, state.isSDown, state.isADown, state.isDDown
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
    if not state.enabled or state.mode ~= "normal" then return end
    if state.comboPlaying or state.isBlocking then return end
    if state.isSpaceAdv then return end
    if state.turboPreImpulsoActivo then return end
    local nt = state.normalTracks
    if not nt.mov_forward then
        if not state.isWDown and not state.isSDown and not state.isADown and not state.isDDown then
            playAnim(ANIM.idle, true)
        elseif state.isDDown then playAnim(ANIM.right, true)
        elseif state.isADown then playAnim(ANIM.left, true)
        elseif state.isSDown then playAnim(ANIM.back, true)
        else playAnim(ANIM.forward, true) end
        return
    end
    local estado = resolverEstadoMovimiento()
    local C = ANIM_NORMAL

    local function matarAtras() state.currentAtrasId = state.currentAtrasId + 1; state.atrasKilled = true end
    local function relanzarAtras()
        local pierna  = obtenerPiernaS()
        local esRapido = esDiagonalS()
        state.currentAtrasId = state.currentAtrasId + 1
        state.atrasKilled = false
        ejecutarDashAtrasAnim(pierna, esRapido)
    end
    local function matarLateral() cancelarLateral() end
    local function relanzarLateral(destino)
        state.currentLateralId = state.currentLateralId + 1
        state.lateralKilled = false
        local thisId = state.currentLateralId
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

        if state.enabled and state.mode == "normal" and not state.comboPlaying then
            local nt2 = state.normalTracks
            if nt2.estatica and not nt2.estatica.IsPlaying then
                nt2.estatica:Play(ANIM_NORMAL.TRANSICION_FLUIDA)
                task.spawn(function()
                    while nt2.estatica.Length == 0 do task.wait() end
                    task.wait(nt2.estatica.Length * ANIM_NORMAL.PARADA_ESTATICA)
                    if state.enabled and state.mode == "normal" then
                        nt2.estatica:AdjustSpeed(0)
                    end
                end)
            end
            if nt2.levitacion and not nt2.levitacion.IsPlaying then
                nt2.levitacion:Play(ANIM_NORMAL.TRANSICION_FLUIDA)
                nt2.levitacion:AdjustSpeed(ANIM_NORMAL.VELOCIDAD_LEVITACION)
            end

            if not state.idleAnimConn then
                state._normalPlayId = (state._normalPlayId or 0) + 1
                -- llamar a iniciarCicloNormal más abajo
                local playId = state._normalPlayId
                iniciarCicloNormal(playId)
            else
                state.idleTimerAnim = 0
            end
        end
    end
end

local evaluarMovimientoDebounced
evaluarMovimientoDebounced = function()
    state.evalToken = (state.evalToken or 0) + 1
    local token = state.evalToken
    task.delay(ANIM_NORMAL.DEBOUNCE_TECLADO, function()
        if state.evalToken == token then evaluarMovimientoNormal() end
    end)
end

local function cambiarAEspacioSecundario()
    if not state.enabled or state.mode ~= "normal" then return end
    local nt = state.normalTracks
    if not nt.espacio_sec then return end
    if nt.espacio_prim and nt.espacio_prim.IsPlaying then pcall(function() nt.espacio_prim:Stop(0.1) end) end
    detenerNormalExceptoBase(0.1)
    pcall(function() nt.espacio_sec:Play(0.1) end)
    pcall(function() nt.espacio_sec:AdjustSpeed(0) end)
    task.defer(function()
        if nt.espacio_sec and nt.espacio_sec.IsPlaying then
            pcall(function() nt.espacio_sec.TimePosition = nt.espacio_sec.Length * 0.5 end)
        end
    end)
    state.espacioTrackActivo = nt.espacio_sec
end

local function manejarEspacioPresionadoNormal()
    if not state.enabled or state.mode ~= "normal" then return end
    if state.comboPlaying then return end
    if state.turboPreImpulsoActivo then return end
    state.isSpaceAdv = true

    -- El noclip se maneja externamente (FlyLogic)
    -- Solo notificamos que espacio fue presionado; el módulo externo se encargará de noclip.

    local nt = state.normalTracks
    if nt.mov_forward and nt.mov_forward.IsPlaying then pcall(function() nt.mov_forward:Stop(0.1) end) end
    if nt.mov_back    and nt.mov_back.IsPlaying    then pcall(function() nt.mov_back:Stop(0.1) end) end
    if nt.lateral     and nt.lateral.IsPlaying     then pcall(function() nt.lateral:Stop(0.1) end) end
    if nt.mov_brazos  and nt.mov_brazos.IsPlaying  then pcall(function() nt.mov_brazos:Stop(0.1) end) end
    if nt.brazos and nt.brazos.IsPlaying then pcall(function() nt.brazos:Stop(0.05) end) end
    state.isBrazosActive = false
    state.idleTimerAnim  = 0
    state.currentAtrasId  = state.currentAtrasId  + 1; state.atrasKilled   = true
    state.currentLateralId = state.currentLateralId + 1; state.lateralKilled = true

    detenerEspacioAvanzado()
    if not nt.espacio_prim then return end
    pcall(function() nt.espacio_prim:Play(0.1) end)
    state.espacioTrackActivo = nt.espacio_prim

    if state.spaceHoldTimerAdv then task.cancel(state.spaceHoldTimerAdv) end
    state.spaceHoldTimerAdv = task.delay(2.0, function()
        if state.isSpaceAdv and state.enabled and state.mode == "normal" then
            cambiarAEspacioSecundario()
        end
        state.spaceHoldTimerAdv = nil
    end)
end

local function manejarEspacioSoltadoNormal()
    state.isSpaceAdv = false
    detenerEspacioAvanzado()
    evaluarMovimientoDebounced()
end

-- Ciclo normal de animación (idle / brazos)
local function iniciarCicloNormal(thisPlay)
    local nt = state.normalTracks
    if not nt.estatica or not nt.levitacion then return end

    state.c0ControlToken = (state.c0ControlToken or 0) + 1
    if nt.estatica.IsPlaying then pcall(function() nt.estatica:Stop(0) end) end
    pcall(function() nt.estatica:Play(ANIM_NORMAL.TRANSICION_FLUIDA) end)
    if not nt.levitacion.IsPlaying then
        pcall(function() nt.levitacion:Play(ANIM_NORMAL.TRANSICION_FLUIDA) end)
    end
    pcall(function() nt.levitacion:AdjustSpeed(ANIM_NORMAL.VELOCIDAD_LEVITACION) end)
    -- Ajuste de altura (lo hará externo FlyLogic)
    -- Aquí se podría emitir evento para que FlyLogic ajuste RootJoint.C0

    task.spawn(function()
        local to = tick() + 3
        while nt.estatica.Length == 0 and tick() < to do task.wait() end
        task.wait(nt.estatica.Length * ANIM_NORMAL.PARADA_ESTATICA)
        if state.enabled and state.mode == "normal" and thisPlay == state._normalPlayId then
            pcall(function() nt.estatica:AdjustSpeed(0) end)
        end
    end)

    state.idleTimerAnim  = 0
    state.isBrazosActive = false
    if state.idleAnimConn then state.idleAnimConn:Disconnect() end

    state.idleWatchToken = (state.idleWatchToken or 0) + 1
    local myIdleToken = state.idleWatchToken

    state.idleAnimConn = RunService.Heartbeat:Connect(function(dt)
        if not state.enabled or state.mode ~= "normal" then
            if state.idleAnimConn then state.idleAnimConn:Disconnect(); state.idleAnimConn = nil end
            return
        end
        if myIdleToken ~= state.idleWatchToken then
            if state.idleAnimConn then state.idleAnimConn:Disconnect(); state.idleAnimConn = nil end
            return
        end
        if state.comboPlaying or state.isBlocking then return end
        if nt.levitacion and not nt.levitacion.IsPlaying then
            pcall(function() nt.levitacion:Play(0.2) end)
            pcall(function() nt.levitacion:AdjustSpeed(ANIM_NORMAL.VELOCIDAD_LEVITACION) end)
        end
        if nt.estatica and not nt.estatica.IsPlaying and not state.isWDown
            and not state.isSDown and not state.isADown and not state.isDDown
            and not state.isSpaceAdv and not state.comboPlaying then
            pcall(function() nt.estatica:Play(ANIM_NORMAL.TRANSICION_FLUIDA) end)
            task.spawn(function()
                local to = tick() + 3
                while nt.estatica.Length == 0 and tick() < to do task.wait() end
                task.wait(nt.estatica.Length * ANIM_NORMAL.PARADA_ESTATICA)
                if state.enabled and state.mode == "normal" and myIdleToken == state.idleWatchToken then
                    pcall(function() nt.estatica:AdjustSpeed(0) end)
                end
            end)
        end
        local isMovingAdv = state.isWDown or state.isSDown or state.isADown or state.isDDown
            or state.isSpaceAdv or state.megaTurboUpActive
        if not isMovingAdv then
            state.idleTimerAnim = state.idleTimerAnim + dt
            if state.idleTimerAnim >= ANIM_NORMAL.TIEMPO_QUIETO and not state.isBrazosActive then
                state.isBrazosActive = true
                if nt.brazos then pcall(function() nt.brazos:Play(ANIM_NORMAL.TIEMPO_TRANSICION) end) end
            end
        else
            state.idleTimerAnim = 0
            if state.isBrazosActive then
                state.isBrazosActive = false
                local fadeBrazos = (state.isSpaceAdv or state.megaTurboUpActive) and 0.05 or ANIM_NORMAL.TIEMPO_TRANSICION
                if nt.brazos then pcall(function() nt.brazos:Stop(fadeBrazos) end) end
            end
        end
    end)
end

-- ============================================================
-- POSE TURBO (25 grados)
-- ============================================================
local function detenerPoseTurbo()
    state.turboPreImpulsoActivo = false
    state.turboPreImpulsoToken = (state.turboPreImpulsoToken or 0) + 1
    if state.turboRenderConn then state.turboRenderConn:Disconnect(); state.turboRenderConn = nil end
    local nt = state.normalTracks
    if nt.turbo_pose   then pcall(function() nt.turbo_pose:Stop(0.3) end) end
    if nt.turbo_volado then pcall(function() nt.turbo_volado:Stop(0.3) end) end
    if nt.turbo_burst  then pcall(function() nt.turbo_burst:Stop(0.1) end) end
    if nt.turbo_compact then pcall(function() nt.turbo_compact:Stop(0.1) end) end
    state.c0ControlToken = (state.c0ControlToken or 0) + 1
end

local function iniciarPoseTurbo()
    state.turboPreImpulsoActivo = true
    state.turboPreImpulsoToken = (state.turboPreImpulsoToken or 0) + 1
    local myToken = state.turboPreImpulsoToken

    state.idleWatchToken = (state.idleWatchToken or 0) + 1
    if state.idleAnimConn then state.idleAnimConn:Disconnect(); state.idleAnimConn = nil end

    detenerNormalTracks(0.1)

    if state.turboRenderConn then state.turboRenderConn:Disconnect(); state.turboRenderConn = nil end

    local rootJoint = state.rootJoint
    local originalC0 = state.originalC0
    if not rootJoint or not originalC0 then state.turboPreImpulsoActivo = false; return end
    local nt = state.normalTracks
    if not nt.turbo_pose or not nt.turbo_volado then state.turboPreImpulsoActivo = false; return end

    for _, t in pairs(state.tracks) do pcall(function() if t and t.IsPlaying then t:Stop(0.05) end end) end

    state.c0ControlToken = (state.c0ControlToken or 0) + 1
    local myC0Token = state.c0ControlToken

    local preImpulsoBlockConn
    preImpulsoBlockConn = RunService.RenderStepped:Connect(function()
        if not state.turboPreImpulsoActivo or state.turboPreImpulsoToken ~= myToken then
            preImpulsoBlockConn:Disconnect()
            return
        end
        if state.animator then
            local ok, tracks = pcall(function() return state.animator:GetPlayingAnimationTracks() end)
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
            if state.turboPreImpulsoToken ~= myToken then return true end
            if not state.enabled or state.mode ~= "fast" then return true end
            return false
        end

        local function abortarYVolver()
            pcall(function() preImpulsoBlockConn:Disconnect() end)
            if state.turboRenderConn then state.turboRenderConn:Disconnect(); state.turboRenderConn = nil end
            state.turboPreImpulsoActivo = false
            state.c0ControlToken = (state.c0ControlToken or 0) + 1
            if nt.turbo_compact then pcall(function() nt.turbo_compact:Stop(0.05) end) end
            if nt.turbo_burst   then pcall(function() nt.turbo_burst:Stop(0.05) end) end
            if nt.turbo_pose    then pcall(function() nt.turbo_pose:Stop(0.05) end) end
            if nt.turbo_volado  then pcall(function() nt.turbo_volado:Stop(0.05) end) end
            for _, t in pairs(state.tracks) do pcall(function() if t and t.IsPlaying then t:Stop(0.05) end end) end
            for _, t in pairs(state.normalTracks) do pcall(function() if t and t.IsPlaying then t:Stop(0.05) end end) end
            if state.mode == "fast" then
                state.mode = "normal"
                -- notificar cambio de modo al controlador
            end
            task.wait(0.05)
            if state.enabled and state.mode == "normal" then
                state.idleWatchToken = (state.idleWatchToken or 0) + 1
                if state.idleAnimConn then state.idleAnimConn:Disconnect(); state.idleAnimConn = nil end
                state._normalPlayId = (state._normalPlayId or 0) + 1
                iniciarCicloNormal(state._normalPlayId)
                task.delay(0.1, function()
                    if state.enabled and state.mode == "normal" then evaluarMovimientoNormal() end
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
            if myC0Token == state.c0ControlToken then
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

        if myC0Token == state.c0ControlToken then
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

        -- FASE 3: transicion a pose de vuelo
        if nt.turbo_pose  then nt.turbo_pose.Looped  = true; pcall(function() nt.turbo_pose:Play(0.2) end) end
        if nt.turbo_volado then nt.turbo_volado.Looped = true; pcall(function() nt.turbo_volado:Play(0.2) end) end
        if nt.turbo_burst  then pcall(function() nt.turbo_burst:Stop(0.4) end) end

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
            if myC0Token == state.c0ControlToken then
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
        if not state.enabled then
            pcall(function() preImpulsoBlockConn:Disconnect() end)
            state.turboPreImpulsoActivo = false
            state.c0ControlToken = (state.c0ControlToken or 0) + 1
            return
        end

        pcall(function() preImpulsoBlockConn:Disconnect() end)
        state.turboPreImpulsoActivo = false
        if state.turboRenderConn then state.turboRenderConn:Disconnect() end

        -- Loop de vuelo turbo
        local myC0TkLoop = state.c0ControlToken
        state.turboRenderConn = RunService.RenderStepped:Connect(function()
            if not state.enabled or state.mode ~= "fast" then
                if state.turboRenderConn then state.turboRenderConn:Disconnect(); state.turboRenderConn = nil end
                if myC0TkLoop == state.c0ControlToken then
                    -- restaurar C0 será hecho por FlyLogic
                end
                return
            end
            if myC0TkLoop ~= state.c0ControlToken then return end

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
            -- Movimiento sinusoidal (solo visual, el C0 lo aplicamos aquí)
            local movimientoY = math.sin(tick() * ANIM_TURBO.FRECUENCIA_LEVITACION) * ANIM_TURBO.AMPLITUD_LEVITACION
            local targetCF = originalC0
                * CFrame.new(0, ANIM_TURBO.COMPENSACION_ALTURA + movimientoY, 0)
                * CFrame.Angles(math.rad(ANIM_TURBO.INCLINACION_GRADOS), 0, 0)
            pcall(function() rootJoint.C0 = targetCF end)
        end)
    end)
end

-- ============================================================
-- POSE MEGA (45 grados)
-- ============================================================
local function detenerPoseMega()
    if state.megaRenderConn then state.megaRenderConn:Disconnect(); state.megaRenderConn = nil end
    local nt = state.normalTracks
    if nt.mega_pose   then pcall(function() nt.mega_pose:Stop(0.3) end) end
    if nt.mega_base   then pcall(function() nt.mega_base:Stop(0.3) end) end
    if nt.mega_volado then pcall(function() nt.mega_volado:Stop(0.3) end) end
    state.c0ControlToken = (state.c0ControlToken or 0) + 1
end

local function iniciarPoseMega()
    detenerNormalTracks(0.1)
    detenerPoseTurbo()
    if state.megaRenderConn then state.megaRenderConn:Disconnect(); state.megaRenderConn = nil end
    local rootJoint = state.rootJoint
    local originalC0 = state.originalC0
    if not rootJoint or not originalC0 then return end
    local nt = state.normalTracks
    if not nt.mega_pose then return end
    if nt.mega_pose   then nt.mega_pose.Looped  = true; pcall(function() nt.mega_pose:Play(0.2); nt.mega_pose:AdjustSpeed(0.1) end) end
    if nt.mega_base   then nt.mega_base.Looped   = true; pcall(function() nt.mega_base:Play(0.2); nt.mega_base:AdjustSpeed(0.1) end) end
    if nt.mega_volado then nt.mega_volado.Looped = true; pcall(function() nt.mega_volado:Play(0.2) end) end

    state.c0ControlToken = (state.c0ControlToken or 0) + 1
    local myC0Token = state.c0ControlToken

    state.megaRenderConn = RunService.RenderStepped:Connect(function()
        if not state.enabled or state.mode ~= "turbo" then
            if state.megaRenderConn then state.megaRenderConn:Disconnect(); state.megaRenderConn = nil end
            if myC0Token == state.c0ControlToken then
                -- restaurar C0 externamente
            end
            return
        end
        if myC0Token ~= state.c0ControlToken then return end
        if nt.mega_volado and nt.mega_volado.IsPlaying then
            pcall(function()
                nt.mega_volado:AdjustSpeed(0)
                nt.mega_volado.TimePosition = ANIM_MEGA.FRAME_VOLADO_CONGELADO
            end)
        elseif nt.mega_volado and not nt.mega_volado.IsPlaying then
            nt.mega_volado.Looped = true
            pcall(function() nt.mega_volado:Play(0.1); nt.mega_volado:AdjustSpeed(0) end)
        end
        local movimientoY = math.sin(tick() * ANIM_MEGA.FRECUENCIA_LEVITACION) * ANIM_MEGA.AMPLITUD_LEVITACION
        pcall(function()
            rootJoint.C0 = originalC0
                * CFrame.new(0, ANIM_MEGA.COMPENSACION_ALTURA + movimientoY, 0)
                * CFrame.Angles(math.rad(ANIM_MEGA.INCLINACION_GRADOS), 0, 0)
        end)
    end)
end

-- ============================================================
-- SISTEMA DE BLOQUEO
-- ============================================================
local function setupBlockTrack()
    if not state.animator then return end
    local animObj = Instance.new("Animation")
    animObj.AnimationId = ANIM.bloqueo
    local ok, t = pcall(function() return state.animator:LoadAnimation(animObj) end)
    if not ok or not t then return end
    state.blockTrack = t
    state.blockTrack.Priority = Enum.AnimationPriority.Action4
    state.blockTrack.Looped   = true
    pcall(function() state.blockTrack:Play(0, 0, 0) end)
end

local function startBlocking()
    if not state.enabled then return end
    if state.mode ~= "normal" then return end
    if state.turboPreImpulsoActivo then return end
    if state.blockCancelledByCombo then return end
    local bt = state.blockTrack
    if not bt or state.isBlocking then return end
    state.isBlocking = true
    local length = bt.Length > 0 and bt.Length or 1
    pcall(function() bt:Play(0, 1, ANIM_BLOQUEO.VEL_RAPIDO) end)
    bt.TimePosition = length * ANIM_BLOQUEO.INICIO_PERC
    if state.blockRenderConn then state.blockRenderConn:Disconnect() end
    local blockState = "MOVING"
    state.blockRenderConn = RunService.Heartbeat:Connect(function()
        if not state.isBlocking or not state.enabled then return end
        if state.mode ~= "normal" then
            state.isBlocking = false
            if state.blockRenderConn then state.blockRenderConn:Disconnect(); state.blockRenderConn = nil end
            if state.blockTrack and state.blockTrack.IsPlaying then pcall(function() state.blockTrack:Stop(0.1) end) end
            return
        end
        if blockState == "MOVING" then
            if bt.TimePosition >= length * ANIM_BLOQUEO.RESPIRO_PERC then
                blockState = "BREATHING"
                pcall(function() bt:AdjustSpeed(ANIM_BLOQUEO.VEL_LENTO) end)
            end
        elseif blockState == "BREATHING" then
            local t = os.clock()
            pcall(function() bt.TimePosition = length * (ANIM_BLOQUEO.OSCILA_MIN + (ANIM_BLOQUEO.OSCILA_RANGE * math.sin(t * 2))) end)
        end
    end)
end

local function stopBlocking()
    state.isBlocking = false
    if state.blockRenderConn then state.blockRenderConn:Disconnect(); state.blockRenderConn = nil end
    if state.blockTrack then pcall(function() state.blockTrack:Stop(0) end) end
end

-- ============================================================
-- SISTEMA DE COMBOS
-- ============================================================
local function resetCombo()
    state.comboStep = 0
    state.comboLastClick = 0
    state.comboPendingClick = false
end

local function _launchComboAnim(animId, speed)
    for id, track in pairs(state.tracks) do
        if id ~= animId and id ~= ANIM.levitacion and track and track.IsPlaying then
            pcall(function() track:Stop(0.05) end)
        end
    end
    local t = getTrack(animId)
    if not t then return end
    t.Looped   = false
    t.Priority = Enum.AnimationPriority.Action4
    if t.IsPlaying then pcall(function() t:Stop(0) end) end
    pcall(function() t:Play(0.05, 1, 1) end)
    pcall(function() t:AdjustSpeed(speed or 3.0) end)
end

local function startComboC0Lock()
    if state.comboC0Conn then state.comboC0Conn:Disconnect(); state.comboC0Conn = nil end
    if not state.rootJoint or not state.originalC0 then return end
    local rj = state.rootJoint
    local oc = state.originalC0
    state.c0ControlToken = (state.c0ControlToken or 0) + 1
    local myToken = state.c0ControlToken
    state.comboC0Conn = RunService.RenderStepped:Connect(function()
        if not state.comboPlaying then
            if state.comboC0Conn then state.comboC0Conn:Disconnect(); state.comboC0Conn = nil end
            return
        end
        if state.c0ControlToken ~= myToken then
            if state.comboC0Conn then state.comboC0Conn:Disconnect(); state.comboC0Conn = nil end
            return
        end
        pcall(function() rj.C0 = oc end)
    end)
end

local function stopComboC0Lock()
    if state.comboC0Conn then state.comboC0Conn:Disconnect(); state.comboC0Conn = nil end
end

local function finalizarCombo()
    state.comboPlaying = false
    state.comboBusy    = false
    state.combo4Frozen = false
    state.comboPendingClick = false

    stopComboC0Lock()

    if not state.enabled then return end

    for id, track in pairs(state.tracks) do
        if id ~= ANIM.levitacion and track and track.IsPlaying then
            pcall(function() track:Stop(0.12) end)
        end
    end

    task.wait(0.08)

    if not state.enabled then return end

    state.c0ControlToken = (state.c0ControlToken or 0) + 1
    if state.mode == "normal" then
        state._normalPlayId = (state._normalPlayId or 0) + 1
        local pid = state._normalPlayId

        local nt = state.normalTracks
        if nt then
            if nt.levitacion and not nt.levitacion.IsPlaying then
                pcall(function() nt.levitacion:Play(0.2) end)
                pcall(function() nt.levitacion:AdjustSpeed(ANIM_NORMAL.VELOCIDAD_LEVITACION) end)
            end
        end

        iniciarCicloNormal(pid)
        task.delay(0.05, function()
            if state.enabled and state.mode == "normal" then evaluarMovimientoNormal() end
        end)
    else
        -- actualizar animación según modo (fast/turbo) - esto lo hará updateAnimForMovement
        -- que a su vez es llamado por FlyLogic
    end
end

local function runComboSequencer(startToken)
    local function waitStep(stepIdx)
        local dur = COMBO_STEP_DURATION[stepIdx] or 0.47
        local stepStart = tick()
        while tick() - stepStart < dur do
            task.wait(0.02)
            if state.comboToken ~= startToken then return false end
        end
        state.comboBusy = false

        local waitStart = tick()
        while not state.comboPendingClick do
            task.wait(0.02)
            if state.comboToken ~= startToken then return false end
            if tick() - waitStart > COMBO_PENDING_WINDOW then
                finalizarCombo(); return false
            end
        end
        state.comboPendingClick = false
        if state.comboToken ~= startToken then return false end
        return true
    end

    -- Paso 1
    state.comboStep = 1
    _launchComboAnim(ANIM.combo1, 3.0)
    state.comboBusy = true
    state.comboPendingClick = false
    if not waitStep(1) then return end

    -- Paso 2
    state.comboStep = 2
    local r = math.random(1, 2)
    local chosenId2 = (r == 1) and ANIM.combo2a or ANIM.combo2b
    _launchComboAnim(chosenId2, 3.0)
    state.comboBusy = true
    state.comboPendingClick = false
    if not waitStep(2) then return end

    -- Paso 3
    state.comboStep = 3
    local chosenId3 = (chosenId2 == ANIM.combo2a) and ANIM.combo3b or ANIM.combo3a
    _launchComboAnim(chosenId3, 3.0)
    state.comboBusy = true
    state.comboPendingClick = false
    if not waitStep(3) then return end

    -- Paso 4
    state.comboStep = 4
    local spaceDown4 = (state.isSpaceAdv or state.megaTurboUpActive)  -- se puede obtener desde externo? mejor pasarlo como parámetro o leer tecla
    if spaceDown4 then
        local t4s = getTrack(ANIM.combo4_space)
        if t4s then
            for id, track in pairs(state.tracks) do
                if id ~= ANIM.combo4_space and id ~= ANIM.levitacion and track and track.IsPlaying then
                    pcall(function() track:Stop(0.05) end)
                end
            end
            t4s.Looped = false; t4s.Priority = Enum.AnimationPriority.Action4
            if t4s.IsPlaying then pcall(function() t4s:Stop(0) end) end
            pcall(function() t4s:Play(0.05, 1, 1); t4s:AdjustSpeed(1.0) end)
            state.comboBusy = true
            local timeout4 = tick() + 5
            while t4s.IsPlaying and tick() < timeout4 do
                task.wait(0.03)
                if state.comboToken ~= startToken then return end
            end
            state.comboBusy = false
            task.wait(0.3)
        end
        resetCombo()
        finalizarCombo()
        return
    end

    -- Combo 4 normal
    local t4 = getTrack(ANIM.combo4)
    if not t4 then finalizarCombo(); return end

    for id, track in pairs(state.tracks) do
        if id ~= ANIM.combo4 and id ~= ANIM.levitacion and track and track.IsPlaying then
            pcall(function() track:Stop(0.05) end)
        end
    end

    t4.Looped   = false
    t4.Priority = Enum.AnimationPriority.Action4
    if t4.IsPlaying then pcall(function() t4:Stop(0) end) end

    pcall(function() t4:Play(0.05, 1, 1) end)
    local toLoad = tick() + 2
    while t4.Length == 0 and tick() < toLoad do
        task.wait(0.02)
        if state.comboToken ~= startToken then return end
    end

    pcall(function() t4:AdjustSpeed(4.0) end)
    state.comboBusy = true
    state.comboPendingClick = false
    state.combo4Frozen = false

    local len4 = t4.Length
    local PAUSE_PERC = 0.55
    local timeout4 = tick() + 4
    while t4.IsPlaying and tick() < timeout4 do
        task.wait(0.016)
        if state.comboToken ~= startToken then return end
        len4 = t4.Length
        if len4 > 0 and t4.TimePosition >= len4 * PAUSE_PERC then break end
    end
    if state.comboToken ~= startToken then return end

    state.combo4Frozen = true
    state.comboBusy    = false
    pcall(function() t4:AdjustSpeed(0) end)
    if len4 > 0 then pcall(function() t4.TimePosition = len4 * PAUSE_PERC end) end

    local stepDur4  = COMBO_STEP_DURATION[4]
    local pauseDeadline = tick() + (stepDur4 * (1 - PAUSE_PERC) + 0.08)
    while not state.comboPendingClick and tick() < pauseDeadline do
        task.wait(0.02)
        if state.comboToken ~= startToken then return end
    end
    state.combo4Frozen = false
    state.comboPendingClick = false
    if state.comboToken ~= startToken then return end

    pcall(function() t4:AdjustSpeed(15) end)
    t4.Looped = false
    local timeout4b = tick() + 2
    while t4.IsPlaying and tick() < timeout4b do
        task.wait(0.016)
        if state.comboToken ~= startToken then return end
    end

    resetCombo()
    finalizarCombo()
end

local function handleComboClick()
    if not state.enabled then return end
    if state.turboPreImpulsoActivo then return end
    if state.isBlocking then return end

    if state.comboPlaying then
        if state.comboBusy then
            return
        end
        state.comboPendingClick = true
        state.comboLastClick = tick()
        return
    end

    local now = tick()
    if now - state.comboLastClick < COMBO_MIN_GAP then return end

    state.comboToken = (state.comboToken or 0) + 1
    local myToken = state.comboToken

    if state.idleAnimConn then state.idleAnimConn:Disconnect(); state.idleAnimConn = nil end

    if state.isBlocking then
        stopBlocking()
        state.blockCancelledByCombo = true
    end

    state.comboPlaying    = true
    state.comboLastClick  = now
    state.comboPendingClick = false
    startComboC0Lock()

    task.spawn(function()
        runComboSequencer(myToken)
    end)
end

local COMBO_HOLD_INTERVAL = 0.10
local function startComboListener()
    if state.comboConn then state.comboConn:Disconnect() end
    if state.comboHoldConn then state.comboHoldConn:Disconnect(); state.comboHoldConn = nil end
    resetCombo()
    state.comboPlaying = false
    state.comboBusy    = false
    state.combo4Frozen = false
    state.comboToken   = 0
    state.mouseHeld    = false
    state.comboPendingClick = false

    -- Nota: los eventos InputBegan/InputEnded serán manejados externamente (FlyControl)
    -- y llamarán a handleComboClick cuando corresponda. Por simplicidad exponemos handleComboClick.
end

local function stopComboListener()
    if state.comboConn then state.comboConn:Disconnect(); state.comboConn = nil end
    if state.comboHoldConn then state.comboHoldConn:Disconnect(); state.comboHoldConn = nil end
    if state.comboEndConn then state.comboEndConn:Disconnect(); state.comboEndConn = nil end
    stopComboC0Lock()
    resetCombo()
    state.comboPlaying = false
    state.comboBusy    = false
    state.combo4Frozen = false
    state.mouseHeld    = false
    state.comboPendingClick = false
end

-- ============================================================
-- INICIALIZACIÓN Y LIMPIEZA DEL ANIMADOR
-- ============================================================
local function setupDamageDetector()
    if state.damageConn then state.damageConn:Disconnect(); state.damageConn = nil end
    -- Esto será llamado por el controlador externo cuando el personaje esté listo
end

local function setupAnimator(char, humanoid, rootJoint)
    -- Desactivar animate script del juego
    local animScript = char:FindFirstChild("Animate")
    if animScript then animScript.Disabled = true end

    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then return false end

    state.animator = animator
    state.tracks   = {}
    state.rootJoint = rootJoint
    state.originalC0 = rootJoint.C0

    -- Parar todas las animaciones del juego
    local ok, playing = pcall(function() return animator:GetPlayingAnimationTracks() end)
    if ok and playing then
        for _, t in ipairs(playing) do pcall(function() t:Stop(0) end) end
    end

    -- Pre-cargar tracks
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

    state.normalTracks = {
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

    local nt = state.normalTracks
    if nt.lateral then pcall(function() nt.lateral:Play(0); nt.lateral:Stop(0) end) end
    if nt.mov_back then pcall(function() nt.mov_back:Play(0); nt.mov_back:Stop(0) end) end
    if nt.espacio_sec then pcall(function() nt.espacio_sec:Play(0); nt.espacio_sec:Stop(0) end) end

    local ownAnimIds = {}
    for _, id in pairs(ANIM) do ownAnimIds[id] = true end
    ownAnimIds[CAIDA_BASE_ID] = true
    ownAnimIds[CAIDA_OVERLAY_ID] = true

    if state.animConn then state.animConn:Disconnect(); state.animConn = nil end
    state.animConn = animator.AnimationPlayed:Connect(function(track)
        if not track or not track.Animation then return end
        local id = track.Animation.AnimationId
        if not ownAnimIds[id] then
            pcall(function()
                if track and track.IsPlaying then track:Stop(0) end
            end)
        end
    end)

    setupBlockTrack()
    -- setupDamageDetector se llamará externamente cuando el humanoid esté listo
    return true
end

local function restoreGameAnimations(char)
    if not char then return end
    if state.animConn then state.animConn:Disconnect(); state.animConn = nil end
    local animScript = char:FindFirstChild("Animate")
    if animScript then animScript.Disabled = false end
    if state.rootJoint and state.originalC0 then
        pcall(function() state.rootJoint.C0 = state.originalC0 end)
    end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.PlatformStand = false
        pcall(function() humanoid:ChangeState(Enum.HumanoidStateType.GettingUp) end)
        task.wait(0.05)
        pcall(function() humanoid:ChangeState(Enum.HumanoidStateType.Landed) end)
    end
end

-- ============================================================
-- API PÚBLICA DEL MÓDULO
-- ============================================================
local FlyAnim = {}

function FlyAnim.init(character, humanoid, rootJoint)
    state.enabled = false
    state.mode = "normal"
    state.megaTurboUpActive = false
    state.isWDown = false; state.isSDown = false; state.isADown = false; state.isDDown = false
    state.isSpaceAdv = false
    state.isBlocking = false
    state.comboPlaying = false
    state.turboPreImpulsoActivo = false
    state._normalPlayId = 0
    return setupAnimator(character, humanoid, rootJoint)
end

function FlyAnim.cleanup(character)
    restoreGameAnimations(character)
    stopComboListener()
    detenerPoseTurbo()
    detenerPoseMega()
    stopBlocking()
    detenerNormalTracks(0)
    detenerEspacioAvanzado()
    if state.damageConn then state.damageConn:Disconnect(); state.damageConn = nil end
    if state.idleAnimConn then state.idleAnimConn:Disconnect(); state.idleAnimConn = nil end
    if state.turboRenderConn then state.turboRenderConn:Disconnect(); state.turboRenderConn = nil end
    if state.megaRenderConn then state.megaRenderConn:Disconnect(); state.megaRenderConn = nil end
    state.enabled = false
end

function FlyAnim.setEnabled(enabled)
    if enabled == state.enabled then return end
    state.enabled = enabled
    if enabled then
        if state.mode == "normal" then
            state._normalPlayId = (state._normalPlayId or 0) + 1
            iniciarCicloNormal(state._normalPlayId)
        end
    else
        detenerNormalTracks(0)
        detenerPoseTurbo()
        detenerPoseMega()
        stopBlocking()
        detenerEspacioAvanzado()
        if state.idleAnimConn then state.idleAnimConn:Disconnect(); state.idleAnimConn = nil end
    end
end

function FlyAnim.updateMovement(w, s, a, d, isSpaceAdv, megaTurboUpActive)
    state.isWDown = w
    state.isSDown = s
    state.isADown = a
    state.isDDown = d
    state.isSpaceAdv = isSpaceAdv
    state.megaTurboUpActive = megaTurboUpActive
    if state.enabled then
        if state.mode == "normal" then
            evaluarMovimientoDebounced()
        else
            updateAnimForMovement()  -- definida más abajo
        end
    end
end

local function updateAnimForMovement()
    if state.turboPreImpulsoActivo then return end
    local dir = (function()
        local w = state.isWDown; local s = state.isSDown
        local a = state.isADown; local d = state.isDDown
        if a and d then return "none" end
        if d and not a then return "right" end
        if a and not d then return "left" end
        if not w and not s then return "none" end
        if w and not s then return "forward" end
        if s and not w then return "back" end
        return "none"
    end)()
    local moving = dir ~= "none"
    local mode = state.mode
    if state.comboPlaying or state.isBlocking then return end

    if mode == "normal" then
        local nt = state.normalTracks
        if not nt.mov_forward then
            if not moving then playAnim(ANIM.idle, true)
            elseif dir == "right" then playAnim(ANIM.right, true)
            elseif dir == "left"  then playAnim(ANIM.left, true)
            elseif dir == "back"  then playAnim(ANIM.back, true)
            else playAnim(ANIM.forward, true) end
        end
    elseif mode == "fast" then
        if state.turboRenderConn then return end
        local enterFast = state.tracks[ANIM.fast_enter]
        if enterFast and enterFast.IsPlaying then return end
        if not moving then playAnim(ANIM.fast_idle, true)
        else playAnim(ANIM.fast_move, true) end
    elseif mode == "turbo" then
        if state.megaRenderConn then return end
        local enterTurbo = state.tracks[ANIM.turbo_enter]
        if enterTurbo and enterTurbo.IsPlaying then return end
        if not moving then playAnim(ANIM.turbo_idle, true)
        else playAnim(ANIM.turbo_loop, true) end
    end
end

function FlyAnim.onFlyModeChanged(newMode)
    local oldMode = state.mode
    if newMode == oldMode then return end
    state.mode = newMode
    if not state.enabled then return end

    if newMode == "normal" then
        detenerPoseTurbo()
        detenerPoseMega()
        stopBlocking()
        detenerEspacioAvanzado()
        state._normalPlayId = (state._normalPlayId or 0) + 1
        iniciarCicloNormal(state._normalPlayId)
        task.delay(0.05, function()
            if state.enabled and state.mode == "normal" then evaluarMovimientoNormal() end
        end)
    elseif newMode == "fast" then
        detenerPoseMega()
        detenerNormalTracks(0.1)
        detenerEspacioAvanzado()
        if state.idleAnimConn then state.idleAnimConn:Disconnect(); state.idleAnimConn = nil end
        iniciarPoseTurbo()
    elseif newMode == "turbo" then
        detenerPoseTurbo()
        detenerNormalTracks(0.1)
        detenerEspacioAvanzado()
        if state.idleAnimConn then state.idleAnimConn:Disconnect(); state.idleAnimConn = nil end
        iniciarPoseMega()
    elseif newMode == "megaup" then
        -- No cambia la pose base, solo cierra brazos y evita partículas
        if state.isBrazosActive then
            state.isBrazosActive = false
            state.idleTimerAnim = 0
            local nt = state.normalTracks
            if nt and nt.brazos and nt.brazos.IsPlaying then
                pcall(function() nt.brazos:Stop(0.05) end)
            end
        end
    end
    updateAnimForMovement()
end

function FlyAnim.onSpacePress()
    if state.enabled and state.mode == "normal" then
        manejarEspacioPresionadoNormal()
    end
end

function FlyAnim.onSpaceRelease()
    if state.enabled then
        manejarEspacioSoltadoNormal()
    end
end

function FlyAnim.onComboClick()
    handleComboClick()
end

function FlyAnim.onBlockPress()
    if state.enabled and not state.blockCancelledByCombo then
        startBlocking()
    end
end

function FlyAnim.onBlockRelease()
    if state.enabled then
        stopBlocking()
        state.blockCancelledByCombo = false
    end
end

function FlyAnim.setDamageDetector(humanoid)
    if state.damageConn then state.damageConn:Disconnect() end
    state.damageConn = humanoid.HealthChanged:Connect(function(newHealth)
        local oldHealth = humanoid.Health
        if newHealth < oldHealth then
            state.lastDamageTime = tick()
            if state.isBlocking then
                stopBlocking()
            end
        end
    end)
end

function FlyAnim.getRootJoint()
    return state.rootJoint, state.originalC0
end

function FlyAnim.resetRootJoint()
    if state.rootJoint and state.originalC0 then
        pcall(function() state.rootJoint.C0 = state.originalC0 end)
    end
end

function FlyAnim.isComboPlaying()
    return state.comboPlaying
end

function FlyAnim.isBlocking()
    return state.isBlocking
end

function FlyAnim.getMode()
    return state.mode
end

return FlyAnim
