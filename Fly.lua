-- version 2.12

--[[
╔══════════════════════════════════════════════════════════════════╗
║                    FLY SYSTEM  v2.12                            ║
║  Módulo de vuelo avanzado · Sistema de partículas independiente  ║
╚══════════════════════════════════════════════════════════════════╝

  MODOS INTERNOS (flyanim.mode):
    "normal"     → vuelo base
    "turbo"      → antes "fast"    (Q una vez)
    "mega turbo" → antes "turbo"   (Q dos veces)
    "mega up"    → antes "megaup"  (Space sostenido)

  getgenv().AFO_FLYMODE  → modo actual (string)
  getgenv().AFO_FLYSTATE → true/false (¿volando?)

  ÍNDICE DE SECCIONES
  ───────────────────
  [1]  SERVICIOS
  [2]  ASSET IDs  ← todos los rbxassetid centralizados aquí
  [3]  IDIOMA / LOCALIZACIÓN
  [4]  REFERENCIAS GLOBALES
  [5]  CONSTANTES DE VELOCIDAD
  [6]  CONSTANTES DE ANIMACIÓN (NORMAL / TURBO / MEGA / BLOQUEO)
  [7]  ESTADO PRINCIPAL  (flyanim)
  [8]  UTILIDADES  (math, CFrame, C0)
  [9]  SISTEMA DE AUDIO
  [10] ANIMACIONES NORMALES  (levitación, movimiento, brazos, espacio)
  [11] ANIMACIONES TURBO / FAST
  [12] ANIMACIONES MEGA TURBO
  [13] SISTEMA DE BLOQUEO (F)
  [14] SISTEMA DE COMBO (click)
  [15] ── MEGA UP ──  (sistema independiente)
  [16] PARTÍCULAS TURBO / FAST  (estelas horizontales)
  [17] PARTÍCULAS MEGA UP       (estelas verticales, efectomegaup)
  [18] WHITE FLASH  (escala por velocidad)
  [19] EFECTOS VFX  (sonicBoom, airShock, landing, crater)
  [21] SISTEMA NOCLIP / ANTI-IMPULSO / ANOMALÍAS
  [23] DASH / COLISIÓN
  [24] GUI  (panel HUD)
  [25] FÍSICA DEL VUELO  (motores, rsConn, tpMoveConn)
  [26] ATERRIZAJE / LANDING
  [27] _flyOn / _flyOff
  [28] INPUT GLOBAL  (Q, F, Space, WASD)
  [29] API PÚBLICA  (M.Start / M.Stop / M.Toggle …)
--]]

-- ──────────────────────────────────────────────────────────────────
-- [1]  SERVICIOS
-- ──────────────────────────────────────────────────────────────────
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui          = game:GetService("CoreGui")
local SoundService     = game:GetService("SoundService")

-- ──────────────────────────────────────────────────────────────────
-- [2]  ASSET IDs  (todos los rbxassetid centralizados aquí)
-- ──────────────────────────────────────────────────────────────────

-- ── Animaciones principales ──────────────────────────────────────
-- (ver tabla ANIM más abajo; los IDs se declaran allí por claridad)

-- ── Sonidos ──────────────────────────────────────────────────────
local SFX_TURBO          = "rbxassetid://137455842313478"   -- turbo (fast)
local SFX_MEGA_TURBO     = "rbxassetid://111391583223900"   -- mega turbo / mega up

-- ── Animaciones de caída / aterrizaje ────────────────────────────
local CAIDA_BASE_ID      = "rbxassetid://287325678"
local CAIDA_OVERLAY_ID   = "rbxassetid://70439247"

-- ── Texturas VFX compartidas ─────────────────────────────────────
local AIR_SHOCK_ID       = "rbxassetid://112096280571499"   -- aura de shock de aire
local SHOCKWAVE_ID       = "rbxassetid://117592591478260"   -- onda de choque (billboard)
local RING_ID            = "rbxassetid://12914395250"       -- anillo sonic boom
local PARTICLE_TEXTURE   = "rbxassetid://106822944701902"   -- textura estelas turbo/fast

-- ── Texturas partículas Mega Up (exclusivas) ─────────────────────
local MEGAUP_PARTICLE_TEXTURE = "rbxassetid://106822944701902"  -- estelas verticales
local MEGAUP_PARTICLE_LENGTH  = 12                              -- largo de la estela
local MEGAUP_VERTICAL_OFFSET  = Vector3.new(0, 7.0, 0)         -- spawn sobre la cabeza (+40%)

-- ── Textura estelas turbo/fast (horizontal) ──────────────────────
local PARTICLE_LENGTH    = 6

-- ── Constante de color blanco ────────────────────────────────────
local WHITE              = Color3.fromRGB(255, 255, 255)

-- ── Sound landing ────────────────────────────────────────────────
local SFX_LANDING          = "rbxassetid://135226467234227"
local SFX_LANDING_GLASS    = "rbxassetid://132535085898211"  -- impacto sobre cristal
local SHOCKWAVE_CIRCLE_TEX = "rbxassetid://5457833933"

-- ── Lock icon ────────────────────────────────────────────────────
-- "rbxassetid://82817965256191"  ← declarado inline donde se usa

-- ──────────────────────────────────────────────────────────────────
-- [3]  IDIOMA / LOCALIZACIÓN
-- ──────────────────────────────────────────────────────────────────
local FlyLang = {
    ES = {
        fly_title        = "VUELO",
        mode_normal      = "NORMAL",
        mode_fast        = "TURBO  x",
        mode_mega        = "MEGA  x",
        mode_megaup      = "MEGA UP  x",
        lock_label       = "LOCK",
        lock_hint_prefix = "Apuntar + ",
        noclip_title     = "NOCLIP",
        noclip_space     = "Espacio (arriba)",
        noclip_ctrl      = "Ctrl (bajar)",
        noclip_mega      = "Mega Turbo",
        height_below     = "studs abajo",
        height_above     = "studs arriba",
        height_same      = "mismo nivel",
        speed_base       = "Vel. base",
        speed_turbo_mult = "Turbo x",
        speed_mega_mult  = "Mega x",
        speed_reset      = "Reset",
    },
    EN = {
        fly_title        = "FLY",
        mode_normal      = "NORMAL",
        mode_fast        = "TURBO  x",
        mode_mega        = "MEGA  x",
        mode_megaup      = "MEGA UP  x",
        lock_label       = "LOCK",
        lock_hint_prefix = "Aim + ",
        noclip_title     = "NOCLIP",
        noclip_space     = "Space (Up)",
        noclip_ctrl      = "Ctrl (Down)",
        noclip_mega      = "Mega Turbo",
        height_below     = "studs below",
        height_above     = "studs above",
        height_same      = "same level",
        speed_base       = "Base speed",
        speed_turbo_mult = "Turbo x",
        speed_mega_mult  = "Mega x",
        speed_reset      = "Reset",
    },
}

local FT = FlyLang["ES"]

local function _reloadFT()
    local lang = "ES"
    pcall(function()
        local data = readfile("AllForOne/lang.txt")
        if data == "EN" or data == "ES" then lang = data end
    end)
    FT = FlyLang[lang]
end

_reloadFT()

-- ──────────────────────────────────────────────────────────────────
-- [4]  REFERENCIAS GLOBALES
-- ──────────────────────────────────────────────────────────────────
local lplr   = nil
local camera = nil

local function isTyping()
    return UserInputService:GetFocusedTextBox() ~= nil
end

-- ──────────────────────────────────────────────────────────────────
-- [2b]  ASSET IDs — ANIMACIONES  (parte de la sección [2])
--       Los IDs de audio, VFX y partículas están arriba del script.
-- ──────────────────────────────────────────────────────────────────
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

-- [IDs movidos a sección [2] al inicio del script]

-- ──────────────────────────────────────────────────────────────────
-- [9]  SISTEMA DE AUDIO
-- ──────────────────────────────────────────────────────────────────
local function playLocalSound(id, volume)
    local snd = Instance.new("Sound")
    snd.SoundId   = id
    snd.Volume    = (type(volume) == "number" and volume > 0) and volume or 0.85
    snd.RollOffMaxDistance = 0
    snd.Parent    = SoundService
    snd:Play()
    task.delay(10, function() pcall(function() snd:Destroy() end) end)
    snd.Ended:Connect(function() pcall(function() snd:Destroy() end) end)
end

-- ──────────────────────────────────────────────────────────────────
-- [5]  CONSTANTES DE VELOCIDAD
-- ──────────────────────────────────────────────────────────────────
local BASE_SPEED    = 60
local FAST_MULT     = 3.0
local TURBO_MULT    = 6.0
local DEFAULT_BASE  = 60
local DEFAULT_FAST  = 3.0
local DEFAULT_TURBO = 6.0

local COORD_SANITY_LIMIT   = 50000

-- ──────────────────────────────────────────────────────────────────
-- [6]  CONSTANTES DE ANIMACIÓN
-- ──────────────────────────────────────────────────────────────────
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

local COMBO_MIN_GAP        = 0.08
local COMBO_STEP_DURATION  = {0.47, 0.47, 0.53, 0.68}
local COMBO_PENDING_WINDOW = 1.0
local COMBO_HOLD_INTERVAL  = 0.10
local ANOMALY_COOLDOWN     = 0.12
local MOTOR_RESET_COOLDOWN = 0.5

-- ──────────────────────────────────────────────────────────────────
-- [7]  ESTADO PRINCIPAL  (tabla flyanim)
-- ──────────────────────────────────────────────────────────────────
local flyanim = {
    enabled     = false,
    speed       = BASE_SPEED,
    flyKey      = Enum.KeyCode.C,
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
    maxHeightAboveGround = 0,
    heightWatchAccum = 0,
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
    particleRunning = false,
    particleConn    = nil,
    particleList    = {},
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
    sessionToken = 0,
    _dragInputConn = nil,
    _comboEndConn  = nil,
}

-- ──────────────────────────────────────────────────────────────────
-- [8]  UTILIDADES  (math / CFrame / C0)
-- ──────────────────────────────────────────────────────────────────
local c0DesiredCFrame = nil
local heightTweenToken = 0

local stopLandingWatcher
local startLandingWatcher

-- Helpers matemáticos básicos
local function isnan(v)
    return v ~= v
end

local function safepos(v3)
    if not v3 then return false end
    return not (isnan(v3.X) or isnan(v3.Y) or isnan(v3.Z))
end

local function clearC0Desired()
    c0DesiredCFrame = nil
end

local function restaurarC0Inmediato()
    heightTweenToken = heightTweenToken + 1
    if flyanim.rootJoint and flyanim.originalC0 then
        pcall(function() flyanim.rootJoint.C0 = flyanim.originalC0 end)
    end
    clearC0Desired()
end

local function setNoclip(state)
    local char = lplr and lplr.Character
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then part.CanCollide = not state end
    end
end

local function cleanupMotors(root, preserveVelY, skipStateChange)
    if not root then return end
    for _, v in ipairs(root:GetChildren()) do
        if v:IsA("BodyGyro") or v:IsA("BodyVelocity") or v:IsA("BodyPosition")
        or v:IsA("BodyAngularVelocity") or v:IsA("BodyForce")
        or v:IsA("AlignOrientation") or v:IsA("LinearVelocity") then
            pcall(function() v:Destroy() end)
        end
    end
    local char = root.Parent
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if hum and not skipStateChange then
        pcall(function()
            hum.PlatformStand = false
            hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
            hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
            if not preserveVelY then
                hum:ChangeState(Enum.HumanoidStateType.Freefall)
            end
        end)
    end
    if preserveVelY then
        local currentVelY = 0
        pcall(function() currentVelY = root.AssemblyLinearVelocity.Y end)
        if isnan(currentVelY) then currentVelY = 0 end
        local finalVelY = (currentVelY >= 0) and -4 or currentVelY
        pcall(function() root.AssemblyLinearVelocity = Vector3.new(0, finalVelY, 0) end)
    else
        pcall(function() root.AssemblyLinearVelocity = Vector3.new(0, 0, 0) end)
    end
    pcall(function() root.AssemblyAngularVelocity = Vector3.new(0, 0, 0) end)
end

local function updateAntiGravityForce()
    if not flyanim.bf or not flyanim.bf.Parent then return end
    local char = lplr and lplr.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local totalMass = 0
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") and not part.Massless then
            totalMass = totalMass + part.AssemblyMass
        end
    end
    if totalMass <= 0 then totalMass = root.AssemblyMass end
    if totalMass <= 0 then totalMass = 1 end
    local grav = workspace.Gravity
    if not isnan(grav) and grav > 0 then
        flyanim.bf.Force = Vector3.new(0, totalMass * grav, 0)
    end
end

local function getTrack(animId)
    if not flyanim.animator or not animId then return nil end
    if flyanim.tracks[animId] then return flyanim.tracks[animId] end
    local ok, obj = pcall(function()
        local a = Instance.new("Animation")
        a.AnimationId = animId
        return a
    end)
    if not ok or not obj then return nil end
    local ok2, t = pcall(function()
        local track = flyanim.animator:LoadAnimation(obj)
        track.Priority = Enum.AnimationPriority.Action4
        return track
    end)
    pcall(function() obj:Destroy() end)
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
    fade    = fade or 0.18
    t.Looped = looped
    stopAllExcept(animId, fade, true)
    if not t.IsPlaying then pcall(function() t:Play(fade, 1, 1) end) end
end

local function normPlaySafe(track, fade)
    fade = fade or ANIM_NORMAL.TRANSICION_FLUIDA
    if track and not track.IsPlaying then pcall(function() track:Play(fade) end) end
end

local function normStopSafe(track, fade)
    fade = fade or ANIM_NORMAL.TRANSICION_FLUIDA
    if track and track.IsPlaying then pcall(function() track:Stop(fade) end) end
end

local function detenerWatchdogAltura()
    flyanim.c0HeightToken = (flyanim.c0HeightToken or 0) + 1
    if flyanim.c0HeightConn then flyanim.c0HeightConn:Disconnect(); flyanim.c0HeightConn = nil end
end

local function actualizarPosicionNormal(offsetY, velocidad)
    if not flyanim.rootJoint or not flyanim.originalC0 then return end
    heightTweenToken = heightTweenToken + 1
    local myToken = heightTweenToken
    local targetCF
    if offsetY == 0 then
        targetCF = flyanim.originalC0
    else
        targetCF = flyanim.originalC0 + Vector3.new(0, offsetY, 0)
    end
    local rj    = flyanim.rootJoint
    local dur   = velocidad or ANIM_NORMAL.TRANSICION_POS
    if dur <= 0 then dur = 0.001 end
    local startCF = rj.C0
    local startT  = tick()
    task.spawn(function()
        while true do
            task.wait()
            if heightTweenToken ~= myToken then return end
            if not flyanim.enabled then return end
            local elapsed = tick() - startT
            local t = math.clamp(elapsed / dur, 0, 1)
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
    flyanim.lateralKilled  = true; flyanim.lateralLoopId  = 0
    flyanim.atrasKilled    = true; flyanim.atrasLoopId    = 0
    if flyanim.idleAnimConn then flyanim.idleAnimConn:Disconnect(); flyanim.idleAnimConn = nil end
    flyanim.isBrazosActive = false
    flyanim.idleTimerAnim  = 0
end

local function detenerNormalExceptoBase(fade)
    fade = fade or 0
    local nt = flyanim.normalTracks
    local baseIds = {nt.estatica, nt.levitacion}
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

local function cancelarBrazos()
    if flyanim.isBrazosActive then
        flyanim.isBrazosActive = false
        flyanim.idleTimerAnim  = 0
        local nt = flyanim.normalTracks
        if nt and nt.brazos and nt.brazos.IsPlaying then
            pcall(function() nt.brazos:Stop(ANIM_NORMAL.TIEMPO_TRANSICION) end)
        end
    end
    flyanim.idleTimerAnim = 0
end

-- ──────────────────────────────────────────────────────────────────
-- [13]  SISTEMA DE BLOQUEO  (tecla F)
-- ──────────────────────────────────────────────────────────────────
local function setupBlockTrack()
    if not flyanim.animator then return end
    local animObj = Instance.new("Animation")
    animObj.AnimationId = ANIM.bloqueo
    local ok, t = pcall(function() return flyanim.animator:LoadAnimation(animObj) end)
    pcall(function() animObj:Destroy() end)
    if not ok or not t then return end
    flyanim.blockTrack = t
    flyanim.blockTrack.Priority = Enum.AnimationPriority.Action4
    flyanim.blockTrack.Looped   = true
    pcall(function() flyanim.blockTrack:Play(0, 0, 0) end)
end

local function stopBlocking()
    flyanim.isBlocking = false
    if flyanim.blockRenderConn then flyanim.blockRenderConn:Disconnect(); flyanim.blockRenderConn = nil end
    if flyanim.blockTrack then pcall(function() flyanim.blockTrack:Stop(0) end) end
end

local function startBlocking()
    if not flyanim.enabled then return end
    if flyanim.mode ~= "normal" then return end
    if flyanim.turboPreImpulsoActivo then return end
    if flyanim.blockCancelledByCombo then return end
    local bt = flyanim.blockTrack
    if not bt or flyanim.isBlocking then return end
    cancelarBrazos()
    flyanim.isBlocking = true
    local length = (bt.Length and bt.Length > 0) and bt.Length or 1
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
        local len2 = (bt.Length and bt.Length > 0) and bt.Length or 1
        if state == "MOVING" then
            if bt.TimePosition >= len2 * ANIM_BLOQUEO.RESPIRO_PERC then
                state = "BREATHING"
                pcall(function() bt:AdjustSpeed(ANIM_BLOQUEO.VEL_LENTO) end)
            end
        elseif state == "BREATHING" then
            local tNow = os.clock()
            pcall(function() bt.TimePosition = len2 * (ANIM_BLOQUEO.OSCILA_MIN + (ANIM_BLOQUEO.OSCILA_RANGE * math.sin(tNow * 2))) end)
        end
    end)
end

local function setupDamageDetector()
    if flyanim.damageConn then flyanim.damageConn:Disconnect(); flyanim.damageConn = nil end
    local char = lplr and lplr.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local prevHealth = hum.Health
    flyanim.damageConn = hum.HealthChanged:Connect(function(newHealth)
        if newHealth < prevHealth then
            flyanim.lastDamageTime = tick()
            if flyanim.isBlocking then
                flyanim.isBlocking = false
                if flyanim.blockRenderConn then flyanim.blockRenderConn:Disconnect(); flyanim.blockRenderConn = nil end
                if flyanim.blockTrack then pcall(function() flyanim.blockTrack:Stop(0.1) end) end
            end
        end
        prevHealth = newHealth
    end)
end

-- ──────────────────────────────────────────────────────────────────
-- [10]  ANIMACIONES NORMALES  (levitación / movimiento / brazos / espacio)
-- ──────────────────────────────────────────────────────────────────
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
    if not nt or not nt.lateral then return end
    local timeout = tick() + 3
    while nt.lateral.Length == 0 and tick() < timeout do task.wait() end
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
        if nt.lateral and nt.lateral.Length and nt.lateral.Length > 0 then
            nt.lateral.TimePosition = nt.lateral.Length * currentPos
        end
    end
end

local function ejecutarDashAtrasAnim(targetStartPercent, velocidadRapida)
    local nt = flyanim.normalTracks
    if not nt or not nt.mov_back then return end
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
        local timeout = tick() + 3
        while nt.mov_back.Length == 0 and tick() < timeout do task.wait() end
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
            if math.abs(delta) < vel then
                currentPos = flyanim.atrasTarget
            else
                currentPos = currentPos + (delta > 0 and vel or -vel)
            end
            oscilaTimer = oscilaTimer + 0.05
            if oscilaTimer >= 0.8 then oscilaDir = -oscilaDir; oscilaTimer = 0 end
            local oscilaOffset = oscilaDir * ANIM_NORMAL.OSCILA_VEL * oscilaTimer / 0.8 * 0.04
            if nt.mov_back and nt.mov_back.Length and nt.mov_back.Length > 0 then
                nt.mov_back.TimePosition = nt.mov_back.Length * math.clamp(currentPos + oscilaOffset, 0, 1)
            end
        end
    end)
end

local function esDiagonalS()
    return (flyanim.isSDown and flyanim.isADown and not flyanim.isWDown and not flyanim.isDDown)
        or (flyanim.isSDown and flyanim.isDDown and not flyanim.isWDown and not flyanim.isADown)
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
    if not nt then return end
    local anyMove = flyanim.isWDown or flyanim.isSDown or flyanim.isADown or flyanim.isDDown
    if anyMove then
        cancelarBrazos()
    end
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
        local pierna   = obtenerPiernaS()
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
                pcall(function() nt2.estatica:Play(ANIM_NORMAL.TRANSICION_FLUIDA) end)
                task.spawn(function()
                    local to = tick() + 3
                    while nt2.estatica and nt2.estatica.Length == 0 and tick() < to do task.wait() end
                    task.wait((nt2.estatica and nt2.estatica.Length or 0) * ANIM_NORMAL.PARADA_ESTATICA)
                    if flyanim.enabled and flyanim.mode == "normal" and nt2.estatica then
                        pcall(function() nt2.estatica:AdjustSpeed(0) end)
                    end
                end)
            end
            if nt2.levitacion and not nt2.levitacion.IsPlaying then
                pcall(function() nt2.levitacion:Play(ANIM_NORMAL.TRANSICION_FLUIDA) end)
                pcall(function() nt2.levitacion:AdjustSpeed(ANIM_NORMAL.VELOCIDAD_LEVITACION) end)
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
    if not nt or not nt.espacio_sec then return end
    if nt.espacio_prim and nt.espacio_prim.IsPlaying then pcall(function() nt.espacio_prim:Stop(flyanim.ESPACIO_FADE_OUT) end) end
    detenerNormalExceptoBase(0.1)
    pcall(function() nt.espacio_sec:Play(0.1) end)
    pcall(function() nt.espacio_sec:AdjustSpeed(0) end)
    task.defer(function()
        if nt.espacio_sec and nt.espacio_sec.IsPlaying and nt.espacio_sec.Length and nt.espacio_sec.Length > 0 then
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
    if not nt then return end
    if nt.mov_forward and nt.mov_forward.IsPlaying then pcall(function() nt.mov_forward:Stop(0.1) end) end
    if nt.mov_back    and nt.mov_back.IsPlaying    then pcall(function() nt.mov_back:Stop(0.1) end) end
    if nt.lateral     and nt.lateral.IsPlaying     then pcall(function() nt.lateral:Stop(0.1) end) end
    if nt.mov_brazos  and nt.mov_brazos.IsPlaying  then pcall(function() nt.mov_brazos:Stop(0.1) end) end
    if nt.brazos      and nt.brazos.IsPlaying       then pcall(function() nt.brazos:Stop(0.05) end) end
    cancelarBrazos()
    flyanim.currentAtrasId   = flyanim.currentAtrasId   + 1; flyanim.atrasKilled   = true
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
        if flyanim.mode ~= "mega turbo" and not flyanim.noclipCtrlActive then
            setNoclip(false)
        end
    end
    if flyanim.spaceHoldTimerAdv then task.cancel(flyanim.spaceHoldTimerAdv); flyanim.spaceHoldTimerAdv = nil end
    detenerEspacioAvanzado()
    evaluarMovimientoDebounced()
end

iniciarCicloNormal = function(thisPlay)
    local nt = flyanim.normalTracks
    if not nt or not nt.estatica or not nt.levitacion then return end
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
        while nt.estatica and nt.estatica.Length == 0 and tick() < to do task.wait() end
        local len = nt.estatica and nt.estatica.Length or 0
        task.wait(len * ANIM_NORMAL.PARADA_ESTATICA)
        if flyanim.enabled and flyanim.mode == "normal" and thisPlay == flyanim._normalPlayId then
            if nt.estatica then pcall(function() nt.estatica:AdjustSpeed(0) end) end
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
        local nt2 = flyanim.normalTracks
        if not nt2 then return end
        if nt2.levitacion and not nt2.levitacion.IsPlaying then
            pcall(function() nt2.levitacion:Play(0.2) end)
            pcall(function() nt2.levitacion:AdjustSpeed(ANIM_NORMAL.VELOCIDAD_LEVITACION) end)
        end
        if nt2.estatica and not nt2.estatica.IsPlaying
        and not flyanim.isWDown and not flyanim.isSDown
        and not flyanim.isADown and not flyanim.isDDown
        and not flyanim.isSpaceAdv and not flyanim.comboPlaying then
            pcall(function() nt2.estatica:Play(ANIM_NORMAL.TRANSICION_FLUIDA) end)
            task.spawn(function()
                local to = tick() + 3
                while nt2.estatica and nt2.estatica.Length == 0 and tick() < to do task.wait() end
                local len = nt2.estatica and nt2.estatica.Length or 0
                task.wait(len * ANIM_NORMAL.PARADA_ESTATICA)
                if flyanim.enabled and flyanim.mode == "normal" and myIdleToken == flyanim.idleWatchToken then
                    if nt2.estatica then pcall(function() nt2.estatica:AdjustSpeed(0) end) end
                end
            end)
        end
        local isMovingAdv = flyanim.isWDown or flyanim.isSDown or flyanim.isADown or flyanim.isDDown
            or flyanim.isSpaceAdv or flyanim.megaTurboUpActive
        if not isMovingAdv then
            if dt and not isnan(dt) then flyanim.idleTimerAnim += dt end
            if flyanim.idleTimerAnim >= ANIM_NORMAL.TIEMPO_QUIETO and not flyanim.isBrazosActive then
                flyanim.isBrazosActive = true
                if nt2.brazos then pcall(function() nt2.brazos:Play(ANIM_NORMAL.TIEMPO_TRANSICION) end) end
            end
        else
            flyanim.idleTimerAnim = 0
            if flyanim.isBrazosActive then
                flyanim.isBrazosActive = false
                local fadeBrazos = (flyanim.isSpaceAdv or flyanim.megaTurboUpActive) and 0.05 or ANIM_NORMAL.TIEMPO_TRANSICION
                if nt2.brazos then pcall(function() nt2.brazos:Stop(fadeBrazos) end) end
            end
        end
    end)
end

-- [VFX IDs movidos a sección [2] al inicio del script]

-- ──────────────────────────────────────────────────────────────────
-- [11]  ANIMACIONES TURBO / FAST
-- ──────────────────────────────────────────────────────────────────
local stopParticleEmitter
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
    if not nt or not nt.turbo_pose or not nt.turbo_volado then flyanim.turboPreImpulsoActivo = false; return end
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
        if not flyanim.animator then return end
        local ok, tracks = pcall(function() return flyanim.animator:GetPlayingAnimationTracks() end)
        if ok and tracks then
            for _, t in ipairs(tracks) do
                local animId = t.Animation and t.Animation.AnimationId or ""
                local isTurboAnim = (animId == ANIM.turbo_compact or animId == ANIM.turbo_burst
                    or animId == ANIM.turbo_pose or animId == ANIM.turbo_volado)
                if not isTurboAnim then pcall(function() t:Stop(0) end) end
            end
        end
    end)

    task.spawn(function()
        local function debeAbortar()
            if flyanim.turboPreImpulsoToken ~= myToken then return true end
            if not flyanim.enabled or flyanim.mode ~= "turbo" then return true end
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
            -- BUG FIX: antes solo restauraba si el modo era exactamente "turbo".
            -- Si el idle watcher ya lo había puesto en "normal", la condición
            -- fallaba y nunca se llamaba iniciarCicloNormal(), dejando el personaje
            -- congelado en la pose turbo. Ahora fuerza el estado normal en ambos casos.
            if flyanim.mode == "turbo" or flyanim.mode == "normal" then
                flyanim.mode  = "normal"
                getgenv().AFO_FLYMODE  = flyanim.mode
                getgenv().AFO_FLYSTATE = flyanim.enabled
                flyanim.speed = BASE_SPEED
                if flyanim.updateMode then flyanim.updateMode("normal") end
            end
            setNoclip(false)
            if stopParticleEmitter then pcall(stopParticleEmitter) end
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

        if nt.turbo_compact then
            nt.turbo_compact.Looped = false
            pcall(function() nt.turbo_compact:Play(0.05) end)
            pcall(function() nt.turbo_compact:AdjustSpeed(3.0) end)
        end
        local startT = tick()
        while tick() - startT < ANIM_TURBO.TIEMPO_CONTRAERSE do
            if debeAbortar() then
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
        if debeAbortar() then
            if nt.turbo_compact then pcall(function() nt.turbo_compact:Stop(0.1) end) end
            abortarYVolver(); return
        end
        if myC0Token == flyanim.c0ControlToken then
            pcall(function() rootJoint.C0 = originalC0 * CFrame.Angles(math.rad(ANIM_TURBO.INCLINACION_DESPEGUE), 0, 0) end)
        end
        if nt.turbo_compact then pcall(function() nt.turbo_compact:AdjustSpeed(0) end) end
        task.wait(ANIM_TURBO.TIEMPO_PAUSA)
        if debeAbortar() then
            if nt.turbo_compact then pcall(function() nt.turbo_compact:Stop(0.1) end) end
            abortarYVolver(); return
        end
        if nt.turbo_compact then pcall(function() nt.turbo_compact:Stop(0.05) end) end
        if nt.turbo_burst then
            nt.turbo_burst.Looped = false
            pcall(function() nt.turbo_burst:Play(0.05) end)
            pcall(function() nt.turbo_burst:AdjustSpeed(2.5) end)
        end
        task.wait(0.2)
        if debeAbortar() then
            if nt.turbo_burst then pcall(function() nt.turbo_burst:Stop(0.1) end) end
            abortarYVolver(); return
        end
        if nt.turbo_pose  then nt.turbo_pose.Looped  = true; pcall(function() nt.turbo_pose:Play(0.2) end) end
        if nt.turbo_volado then nt.turbo_volado.Looped = true; pcall(function() nt.turbo_volado:Play(0.2) end) end
        if nt.turbo_burst  then pcall(function() nt.turbo_burst:Stop(0.4) end) end
        
        
        local cframeVuelo = originalC0
            * CFrame.new(0, ANIM_TURBO.COMPENSACION_ALTURA, 0)
            * CFrame.Angles(math.rad(ANIM_TURBO.INCLINACION_GRADOS), 0, 0)
        if myC0Token == flyanim.c0ControlToken then
            pcall(function() rootJoint.C0 = cframeVuelo end)
        end
        startT = tick()
        while tick() - startT < 0.06 do
            if debeAbortar() then
                if nt.turbo_pose   then pcall(function() nt.turbo_pose:Stop(0.2) end) end
                if nt.turbo_volado then pcall(function() nt.turbo_volado:Stop(0.2) end) end
                abortarYVolver(); return
            end
            if myC0Token == flyanim.c0ControlToken then
                pcall(function() rootJoint.C0 = cframeVuelo end)
            end
            if nt.turbo_pose and nt.turbo_pose.IsPlaying then
                pcall(function() nt.turbo_pose:AdjustSpeed(0); nt.turbo_pose.TimePosition = ANIM_TURBO.FRAME_CONGELADO end)
            end
            if nt.turbo_volado and nt.turbo_volado.IsPlaying then
                pcall(function() nt.turbo_volado:AdjustSpeed(0); nt.turbo_volado.TimePosition = ANIM_TURBO.FRAME_VOLADO_CONGELADO end)
            end
            task.wait()
        end
        if not flyanim.enabled then
            flyanim.turboTransitioning    = false
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
        local myC0TkLoop = flyanim.c0ControlToken
        flyanim.turboRenderConn = RunService.RenderStepped:Connect(function()
            if not flyanim.enabled or flyanim.mode ~= "turbo" then
                if flyanim.turboRenderConn then flyanim.turboRenderConn:Disconnect(); flyanim.turboRenderConn = nil end
                -- BUG FIX: siempre restaurar C0 al salir del modo turbo,
                -- independientemente del token. El idle watcher puede haber
                -- incrementado c0ControlToken ANTES de que este conn se ejecute,
                -- lo que causaba que el personaje quedara inclinado al volver a normal.
                detenerWatchdogAltura()
                restaurarC0Inmediato()
                return
            end
            if myC0TkLoop ~= flyanim.c0ControlToken then return end
            if nt.turbo_pose then
                if nt.turbo_pose.IsPlaying then
                    pcall(function() nt.turbo_pose:AdjustSpeed(0); nt.turbo_pose.TimePosition = ANIM_TURBO.FRAME_CONGELADO end)
                else
                    nt.turbo_pose.Looped = true
                    pcall(function() nt.turbo_pose:Play(0.1); nt.turbo_pose:AdjustSpeed(0) end)
                end
            end
            if nt.turbo_volado then
                if nt.turbo_volado.IsPlaying then
                    pcall(function() nt.turbo_volado:AdjustSpeed(0); nt.turbo_volado.TimePosition = ANIM_TURBO.FRAME_VOLADO_CONGELADO end)
                else
                    nt.turbo_volado.Looped = true
                    pcall(function() nt.turbo_volado:Play(0.1); nt.turbo_volado:AdjustSpeed(0) end)
                end
            end
            local tNow = tick()
            local movimientoY = math.sin(tNow * ANIM_TURBO.FRECUENCIA_LEVITACION) * ANIM_TURBO.AMPLITUD_LEVITACION
            local targetCF = originalC0
                * CFrame.new(0, ANIM_TURBO.COMPENSACION_ALTURA + movimientoY, 0)
                * CFrame.Angles(math.rad(ANIM_TURBO.INCLINACION_GRADOS), 0, 0)
            pcall(function() rootJoint.C0 = targetCF end)
        end)
        flyanim.turboTransitioning = false
        task.spawn(function()
            task.wait(0.1)
            if not flyanim.enabled or flyanim.mode ~= "turbo" then return end
            if flyanim.turboPreImpulsoActivo then return end
            flyanim.idleWatchToken = (flyanim.idleWatchToken or 0) + 1
            local myIdleToken = flyanim.idleWatchToken
            if flyanim.idleAnimConn then flyanim.idleAnimConn:Disconnect(); flyanim.idleAnimConn = nil end
            flyanim.idleTimerAnim  = 0
            flyanim.isBrazosActive = false
            local ntl = flyanim.normalTracks
            if ntl and ntl.levitacion and not ntl.levitacion.IsPlaying then
                pcall(function() ntl.levitacion:Play(ANIM_NORMAL.TRANSICION_FLUIDA) end)
                pcall(function() ntl.levitacion:AdjustSpeed(ANIM_NORMAL.VELOCIDAD_LEVITACION) end)
            end
            flyanim.idleAnimConn = RunService.Heartbeat:Connect(function(dt)
                if not flyanim.enabled or flyanim.mode ~= "turbo" then
                    if flyanim.idleAnimConn then flyanim.idleAnimConn:Disconnect(); flyanim.idleAnimConn = nil end
                    return
                end
                if myIdleToken ~= flyanim.idleWatchToken then
                    if flyanim.idleAnimConn then flyanim.idleAnimConn:Disconnect(); flyanim.idleAnimConn = nil end
                    return
                end
                if flyanim.turboPreImpulsoActivo then return end
                if flyanim.comboPlaying or flyanim.isBlocking then return end
                local ntl2 = flyanim.normalTracks
                if not ntl2 then return end
                if ntl2.levitacion and not ntl2.levitacion.IsPlaying then
                    pcall(function() ntl2.levitacion:Play(0.2) end)
                    pcall(function() ntl2.levitacion:AdjustSpeed(ANIM_NORMAL.VELOCIDAD_LEVITACION) end)
                end
                local isMovingAdv = flyanim.isWDown or flyanim.isSDown or flyanim.isADown or flyanim.isDDown
                    or flyanim.megaTurboUpActive
                if not isMovingAdv then
                    if dt and not isnan(dt) then flyanim.idleTimerAnim += dt end
                    if flyanim.idleTimerAnim >= ANIM_NORMAL.TIEMPO_QUIETO and not flyanim.isBrazosActive then
                        flyanim.isBrazosActive = true
                        if ntl2.brazos then pcall(function() ntl2.brazos:Play(ANIM_NORMAL.TIEMPO_TRANSICION) end) end
                    end
                else
                    flyanim.idleTimerAnim = 0
                    if flyanim.isBrazosActive then
                        flyanim.isBrazosActive = false
                        local fadeBrazos = flyanim.megaTurboUpActive and 0.05 or ANIM_NORMAL.TIEMPO_TRANSICION
                        if ntl2.brazos then pcall(function() ntl2.brazos:Stop(fadeBrazos) end) end
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
    if nt then
        if nt.turbo_pose   then pcall(function() nt.turbo_pose:Stop(0.3) end) end
        if nt.turbo_volado then pcall(function() nt.turbo_volado:Stop(0.3) end) end
        if nt.turbo_burst  then pcall(function() nt.turbo_burst:Stop(0.1) end) end
        if nt.turbo_compact then pcall(function() nt.turbo_compact:Stop(0.1) end) end
    end
    flyanim.c0ControlToken = (flyanim.c0ControlToken or 0) + 1
    detenerWatchdogAltura()
    restaurarC0Inmediato()
end

-- ──────────────────────────────────────────────────────────────────
-- [12]  ANIMACIONES MEGA TURBO  (pose orbital)
-- ──────────────────────────────────────────────────────────────────
local function iniciarPoseMega()
    detenerNormalTracks(0.1)
    
    
    if flyanim.turboRenderConn then flyanim.turboRenderConn:Disconnect(); flyanim.turboRenderConn = nil end
    flyanim.turboPreImpulsoActivo = false
    local nt = flyanim.normalTracks
    if nt then
        if nt.turbo_pose   then pcall(function() nt.turbo_pose:Stop(0.1) end) end
        if nt.turbo_volado then pcall(function() nt.turbo_volado:Stop(0.1) end) end
        if nt.turbo_burst  then pcall(function() nt.turbo_burst:Stop(0.1) end) end
        if nt.turbo_compact then pcall(function() nt.turbo_compact:Stop(0.1) end) end
    end
    detenerWatchdogAltura()
    if flyanim.megaRenderConn then flyanim.megaRenderConn:Disconnect(); flyanim.megaRenderConn = nil end
    local rootJoint  = flyanim.rootJoint
    local originalC0 = flyanim.originalC0
    if not rootJoint or not originalC0 then return end
    if not nt or not nt.mega_pose then return end
    
    flyanim.c0ControlToken = (flyanim.c0ControlToken or 0) + 1
    local myC0Token = flyanim.c0ControlToken
    
    pcall(function() rootJoint.C0 = originalC0 end)
    if nt.mega_pose   then nt.mega_pose.Looped   = true; pcall(function() nt.mega_pose:Play(0.2); nt.mega_pose:AdjustSpeed(0.1) end) end
    if nt.mega_base   then nt.mega_base.Looped    = true; pcall(function() nt.mega_base:Play(0.2); nt.mega_base:AdjustSpeed(0.1) end) end
    if nt.mega_volado then nt.mega_volado.Looped  = true; pcall(function() nt.mega_volado:Play(0.2) end) end
    flyanim.megaRenderConn = RunService.RenderStepped:Connect(function()
        if not flyanim.enabled or flyanim.mode ~= "mega turbo" then
            if flyanim.megaRenderConn then flyanim.megaRenderConn:Disconnect(); flyanim.megaRenderConn = nil end
            -- BUG FIX: siempre restaurar C0 al salir del modo mega turbo,
            -- independientemente del token. Mismo problema que turboRenderConn:
            -- el idle watcher puede haber incrementado c0ControlToken antes.
            detenerWatchdogAltura()
            restaurarC0Inmediato()
            return
        end
        if myC0Token ~= flyanim.c0ControlToken then return end
        if nt.mega_volado then
            if nt.mega_volado.IsPlaying then
                pcall(function() nt.mega_volado:AdjustSpeed(0); nt.mega_volado.TimePosition = ANIM_MEGA.FRAME_VOLADO_CONGELADO end)
            else
                nt.mega_volado.Looped = true
                pcall(function() nt.mega_volado:Play(0.1); nt.mega_volado:AdjustSpeed(0) end)
            end
        end
        local tNow = tick()
        local movimientoY = math.sin(tNow * ANIM_MEGA.FRECUENCIA_LEVITACION) * ANIM_MEGA.AMPLITUD_LEVITACION
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
    if nt then
        if nt.mega_pose   then pcall(function() nt.mega_pose:Stop(0.3) end) end
        if nt.mega_base   then pcall(function() nt.mega_base:Stop(0.3) end) end
        if nt.mega_volado then pcall(function() nt.mega_volado:Stop(0.3) end) end
    end
    flyanim.c0ControlToken = (flyanim.c0ControlToken or 0) + 1
    detenerWatchdogAltura()
    restaurarC0Inmediato()
end

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
        if not nt or not nt.mov_forward then
            if not moving then playAnim(ANIM.idle, true)
            elseif dir == "right" then playAnim(ANIM.right, true)
            elseif dir == "left"  then playAnim(ANIM.left, true)
            elseif dir == "back"  then playAnim(ANIM.back, true)
            else playAnim(ANIM.forward, true) end
        end
    elseif mode == "turbo" then
        if flyanim.turboRenderConn then return end
        local enterFast = flyanim.tracks[ANIM.fast_enter]
        if enterFast and enterFast.IsPlaying then return end
        if not moving then playAnim(ANIM.fast_idle, true)
        else playAnim(ANIM.fast_move, true) end
    elseif mode == "mega turbo" then
        if flyanim.megaRenderConn then return end
        local enterTurbo = flyanim.tracks[ANIM.turbo_enter]
        if enterTurbo and enterTurbo.IsPlaying then return end
        if not moving then playAnim(ANIM.turbo_idle, true)
        else playAnim(ANIM.turbo_loop, true) end
    end
end

-- ──────────────────────────────────────────────────────────────────
-- [21]  NOCLIP / ANTI-IMPULSO / ANOMALÍAS
-- ──────────────────────────────────────────────────────────────────
local function startAntiImpulse()
    if flyanim.antiImpulseConn then flyanim.antiImpulseConn:Disconnect(); flyanim.antiImpulseConn = nil end
    local mySession = flyanim.sessionToken
    flyanim.antiImpulseConn = RunService.Stepped:Connect(function()
        if not flyanim.enabled then
            if flyanim.antiImpulseConn then flyanim.antiImpulseConn:Disconnect(); flyanim.antiImpulseConn = nil end
            return
        end
        if flyanim.sessionToken ~= mySession then
            if flyanim.antiImpulseConn then flyanim.antiImpulseConn:Disconnect(); flyanim.antiImpulseConn = nil end
            return
        end
        local char = lplr and lplr.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        local bv = flyanim.bv
        if not bv or not bv.Parent then return end
        local expectedVel = bv.velocity
        local actualVel   = root.AssemblyLinearVelocity
        if not safepos(actualVel) or not safepos(expectedVel) then return end
        local diff = (actualVel - expectedVel).Magnitude
        if diff > 3 then root.AssemblyLinearVelocity = expectedVel end
        local bg = flyanim.bg
        if bg then
            local currentAngular = root.AssemblyAngularVelocity
            if safepos(currentAngular) and currentAngular.Magnitude > 5 then
                root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
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
    flyanim.bg.maxTorque = Vector3.new(2000, 2000, 2000)
    if flyanim.backupGyro then pcall(function() flyanim.backupGyro:Destroy() end) end
    local char = lplr and lplr.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if root then
        flyanim.backupGyro = Instance.new("BodyGyro", root)
        flyanim.backupGyro.P         = 1000
        flyanim.backupGyro.maxTorque = Vector3.new(1000, 1000, 1000)
        flyanim.backupGyro.cframe    = flyanim.bg.cframe
    end
    if flyanim.gyroProtectionTimer then task.cancel(flyanim.gyroProtectionTimer) end
    flyanim.gyroProtectionTimer = task.delay(0.5, function()
        if flyanim.enabled and flyanim.bg and flyanim.bg.Parent then
            flyanim.bg.P         = flyanim.originalGyroP or 9e4
            flyanim.bg.maxTorque = flyanim.originalGyroMaxTorque or Vector3.new(9e9, 9e9, 9e9)
        end
        if flyanim.backupGyro then pcall(function() flyanim.backupGyro:Destroy() end); flyanim.backupGyro = nil end
        flyanim.gyroProtectionActive = false
        flyanim.gyroProtectionTimer  = nil
    end)
end

local lastAnomalyFix  = 0
local lastMotorReset  = 0
local lastMotorRebuild = 0  -- cooldown para el check de motores en rsConn

local function _flyMakeMotors()
    if not flyanim.enabled then return end  -- nunca crear motores con fly desactivado
    local char = lplr and lplr.Character; if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum  = char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end
    cleanupMotors(root, false, true)
    local bg = Instance.new("BodyGyro", root)
    bg.P = 9e4; bg.maxTorque = Vector3.new(9e9, 9e9, 9e9); bg.cframe = root.CFrame
    local bv = Instance.new("BodyVelocity", root)
    bv.velocity = Vector3.new(0, 0, 0); bv.maxForce = Vector3.new(9e9, 9e9, 9e9)
    local bf = Instance.new("BodyForce", root)
    local totalMass = 0
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") and not part.Massless then
            totalMass = totalMass + part.AssemblyMass
        end
    end
    if totalMass <= 0 then totalMass = root.AssemblyMass end
    if totalMass <= 0 then totalMass = 1 end
    local grav = workspace.Gravity
    bf.Force = Vector3.new(0, totalMass * (isnan(grav) and 196.2 or grav), 0)
    flyanim.bg = bg
    flyanim.bv = bv
    flyanim.bf = bf
    hum.PlatformStand = true
    hum:ChangeState(Enum.HumanoidStateType.Physics)
end

local function silentMotorReset()
    if not flyanim.enabled then return end
    local now = tick()
    if now - lastMotorReset < MOTOR_RESET_COOLDOWN then return end
    lastMotorReset = now
    local char = lplr and lplr.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end
    local currentCF = root.CFrame
    pcall(function()
        for _, v in ipairs(root:GetChildren()) do
            if v:IsA("BodyGyro") or v:IsA("BodyVelocity") or v:IsA("BodyForce")
            or v:IsA("BodyAngularVelocity") or v:IsA("AlignOrientation") or v:IsA("LinearVelocity") then
                v:Destroy()
            end
        end
        root.AssemblyLinearVelocity  = Vector3.new(0, 0, 0)
        root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
        local bg = Instance.new("BodyGyro", root)
        bg.P = 9e4; bg.maxTorque = Vector3.new(9e9, 9e9, 9e9); bg.cframe = currentCF
        local bv = Instance.new("BodyVelocity", root)
        bv.velocity = Vector3.new(0, 0, 0); bv.maxForce = Vector3.new(9e9, 9e9, 9e9)
        local bf = Instance.new("BodyForce", root)
        local totalMass = 0
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") and not part.Massless then
                totalMass = totalMass + part.AssemblyMass
            end
        end
        if totalMass <= 0 then totalMass = root.AssemblyMass end
        if totalMass <= 0 then totalMass = 1 end
        local grav = workspace.Gravity
        bf.Force = Vector3.new(0, totalMass * (isnan(grav) and 196.2 or grav), 0)
        flyanim.bg = bg
        flyanim.bv = bv
        flyanim.bf = bf
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
    flyanim.anomalyConn = RunService.Stepped:Connect(function()
        if not flyanim.enabled then
            if flyanim.anomalyConn then flyanim.anomalyConn:Disconnect(); flyanim.anomalyConn = nil end
            flyanim.lastKnownPos = nil
            return
        end
        if flyanim.sessionToken ~= mySession then
            if flyanim.anomalyConn then flyanim.anomalyConn:Disconnect(); flyanim.anomalyConn = nil end
            flyanim.lastKnownPos = nil
            return
        end
        local char = lplr and lplr.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then flyanim.lastKnownPos = nil; return end
        local now = tick()
        local hum = char:FindFirstChildOfClass("Humanoid")
        local pos = root.Position
        if safepos(pos) then flyanim.lastKnownPos = pos end
        if not hum then return end
        local state = hum:GetState()
        local isHitboxDrop = (
            state == Enum.HumanoidStateType.Freefall    or
            state == Enum.HumanoidStateType.FallingDown or
            state == Enum.HumanoidStateType.Ragdoll     or
            state == Enum.HumanoidStateType.GettingUp
        )
        -- NOTE: motorsGone check removido — causaba race condition que reconstruía
        -- motores aunque fly ya hubiera sido desactivado (el rsConn tiene su propio
        -- guard). Solo reaccionamos a estados físicos reales del humanoid.
        if isHitboxDrop and now - lastAnomalyFix > ANOMALY_COOLDOWN then
            lastAnomalyFix = now
            flyanim.ragdollDetected = (state == Enum.HumanoidStateType.Ragdoll)
            silentMotorReset()
            local capturedSession = mySession
            task.defer(function()
                if flyanim.sessionToken ~= capturedSession then return end
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
    local char = lplr and lplr.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root or not flyanim.bg then return end
    local upVec = root.CFrame.UpVector
    if upVec.Y < 0.3 then
        local lv = root.CFrame.LookVector
        local lookVec = Vector3.new(lv.X, 0, lv.Z)
        if lookVec.Magnitude < 0.01 then lookVec = Vector3.new(0, 0, -1) end
        local correctedCF = CFrame.lookAt(root.Position, root.Position + lookVec.Unit)
        pcall(function()
            root.CFrame = correctedCF
            root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            if flyanim.bg and flyanim.bg.Parent then flyanim.bg.cframe = correctedCF end
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
        if not flyanim.enabled then
            if flyanim.animBlockRenderConn then flyanim.animBlockRenderConn:Disconnect(); flyanim.animBlockRenderConn = nil end
            return
        end
        if flyanim.sessionToken ~= mySession then
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

-- ──────────────────────────────────────────────────────────────────
-- [23]  DASH / COLISIÓN
-- ──────────────────────────────────────────────────────────────────
local dashConnection = nil
local HIT_COOLDOWN   = 0.5

local function startDashCollisionDetection()
    if dashConnection then dashConnection:Disconnect() end
    local char = lplr and lplr.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local hitPlayers = {}
    dashConnection = RunService.RenderStepped:Connect(function()
        if flyanim.dashTimer <= 0 then
            if dashConnection then dashConnection:Disconnect(); dashConnection = nil end
            return
        end
        if not flyanim.enabled then
            if dashConnection then dashConnection:Disconnect(); dashConnection = nil end
            return
        end
        local currentChar = lplr and lplr.Character
        local currentRoot = currentChar and currentChar:FindFirstChild("HumanoidRootPart")
        if not currentRoot then return end
        local rootPos        = currentRoot.Position
        local dashMagnitude  = flyanim.dashVel.Magnitude
        local currentDashDir = dashMagnitude > 0.01 and flyanim.dashVel.Unit or Vector3.new(0, 0, 1)
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
    if not intensity or isnan(intensity) or intensity <= 0 then return end
    if not duration  or isnan(duration)  or duration  <= 0 then return end
    local startT = tick()
    shakeConn = RunService.RenderStepped:Connect(function()
        local elapsed = tick() - startT
        if elapsed >= duration then shakeConn:Disconnect(); shakeConn = nil; return end
        local decay  = 1 - (elapsed / duration)
        local t2     = elapsed * math.pi
        local angleX = math.sin(t2 * 30) * intensity * decay
        local angleY = math.sin(t2 * 25) * intensity * decay * 0.8
        local angleZ = math.sin(t2 * 35) * intensity * decay * 0.6
        pcall(function() cam.CFrame = cam.CFrame * CFrame.Angles(math.rad(angleX), math.rad(angleY), math.rad(angleZ)) end)
    end)
end


-- ──────────────────────────────────────────────────────────────────
-- [16]  PARTÍCULAS TURBO / FAST  (estelas horizontales)
-- ──────────────────────────────────────────────────────────────────
local _particleFolder = nil

local function _getParticleFolder()
    if _particleFolder and _particleFolder.Parent == workspace then
        return _particleFolder
    end
    _particleFolder = nil
    local folder = Instance.new("Folder")
    folder.Name   = "AFO_Particles"
    folder.Parent = workspace
    _particleFolder = folder
    return folder
end

local function killActiveParticles()
    local list = flyanim.particleList
    for i = #list, 1, -1 do
        local ref = list[i]
        if ref and ref.part then
            pcall(function()
                if ref.part.Parent then ref.part:Destroy() end
            end)
            ref.part = nil
            ref.dead = true
        end
    end
    flyanim.particleList = {}
    if _particleFolder and _particleFolder.Parent then
        for _, child in ipairs(_particleFolder:GetChildren()) do
            pcall(function() child:Destroy() end)
        end
    end
end

local function createParticle(isMega)
    if not flyanim.enabled then return end
    if flyanim.megaTurboUpActive or flyanim.mode == "mega up" then return end
    local char = lplr and lplr.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local cam  = workspace.CurrentCamera
    if not cam then return end
    local camCF  = cam.CFrame
    local lookH  = Vector3.new(camCF.LookVector.X,  0, camCF.LookVector.Z)
    local rightH = Vector3.new(camCF.RightVector.X, 0, camCF.RightVector.Z)
    if lookH.Magnitude  > 0.01 then lookH  = lookH.Unit  else lookH  = Vector3.new(0, 0, -1) end
    if rightH.Magnitude > 0.01 then rightH = rightH.Unit else rightH = Vector3.new(1, 0,  0) end
    local moveDir = Vector3.new(0, 0, 0)
    if flyanim.wDown then moveDir = moveDir + lookH end
    if flyanim.sDown then moveDir = moveDir - lookH end
    if flyanim.aDown then moveDir = moveDir - rightH end
    if flyanim.dDown then moveDir = moveDir + rightH end
    if moveDir.Magnitude < 0.01 then moveDir = lookH else moveDir = moveDir.Unit end
    local awayDir  = -moveDir
    local spawnPos = root.Position + (awayDir * 1)
    local part = Instance.new("Part")
    part.Anchored = true; part.CanCollide = false; part.CastShadow = false
    part.Transparency = 1; part.Size = Vector3.new(0.1, PARTICLE_LENGTH, 0.1)
    part.Position = spawnPos; part.Parent = _getParticleFolder()
    local camPos  = cam.CFrame.Position
    local toCam   = (camPos - spawnPos)
    if toCam.Magnitude > 0.01 then toCam = toCam.Unit else toCam = Vector3.new(0, 0, -1) end
    local upDir    = awayDir.Unit
    local rightDir = upDir:Cross(toCam)
    if rightDir.Magnitude < 0.01 then rightDir = Vector3.new(1, 0, 0) else rightDir = rightDir.Unit end
    local lookDir  = rightDir:Cross(upDir).Unit
    part.CFrame = CFrame.fromMatrix(spawnPos, rightDir, upDir, lookDir)
    local sg  = Instance.new("SurfaceGui", part)
    sg.Adornee = part; sg.Face = Enum.NormalId.Front; sg.AlwaysOnTop = true
    sg.LightInfluence = 0; sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud; sg.PixelsPerStud = 50
    local img = Instance.new("ImageLabel", sg)
    img.Image = PARTICLE_TEXTURE; img.Size = UDim2.new(1, 0, 1, 0); img.BackgroundTransparency = 1
    img.ImageColor3 = Color3.fromRGB(255, 255, 255)
    img.ImageTransparency = isMega and 0.3 or 0.5; img.ScaleType = Enum.ScaleType.Fit
    local FADE_TIME  = 0.42
    local travelDist = isMega and 7 or 5
    local targetPos  = spawnPos + awayDir * travelDist
    local alive = true
    local particleRef = {part = part, dead = false}
    table.insert(flyanim.particleList, particleRef)
    local function destroyPart()
        if not alive then return end
        alive = false
        particleRef.dead = true
        particleRef.part = nil
        pcall(function() if part and part.Parent then part:Destroy() end end)
    end
    local fadeTween = TweenService:Create(img, TweenInfo.new(FADE_TIME, Enum.EasingStyle.Linear), {ImageTransparency = 1})
    fadeTween:Play()
    TweenService:Create(part, TweenInfo.new(FADE_TIME, Enum.EasingStyle.Linear), {Position = targetPos}):Play()
    fadeTween.Completed:Connect(destroyPart)
    task.delay(FADE_TIME + 0.05, destroyPart)
    task.delay(FADE_TIME + 0.1, function()
        local pl = flyanim.particleList
        for i = #pl, 1, -1 do
            if pl[i] and pl[i].dead then table.remove(pl, i) end
        end
    end)
end

local function startParticleEmitter()
    if not flyanim.enabled then return end
    if flyanim.particleRunning then return end
    flyanim.particleRunning = true
    local emitSession = flyanim.sessionToken
    flyanim.particleConn = task.spawn(function()
        while flyanim.enabled
            and flyanim.sessionToken == emitSession
            and (flyanim.mode == "turbo" or flyanim.mode == "mega turbo")
            and not flyanim.megaTurboUpActive
            and flyanim.mode ~= "mega up"
        do
            local char = lplr and lplr.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                local isMega = (flyanim.mode == "mega turbo")
                createParticle(isMega)
                if isMega then task.wait(0.04); createParticle(true) end
            end
            task.wait(0.12)
        end
        flyanim.particleRunning = false
        flyanim.particleConn    = nil
        killActiveParticles()
    end)
end

-- ── stopParticleEmitter (turbo/fast) ─────────────────────────────
stopParticleEmitter = function()
    if flyanim.particleConn then task.cancel(flyanim.particleConn); flyanim.particleConn = nil end
    flyanim.particleRunning = false
    killActiveParticles()
end

local function getBrightnessFactor(speed)
    if speed <= 1 then return 0 end
    if speed <= 1000 then return (speed - 1) / 999 end
    return 1
end

-- ──────────────────────────────────────────────────────────────────
-- [17]  PARTÍCULAS MEGA UP  (estelas verticales — efectomegaup)
--
--  Diseñadas para subir desde la cabeza del personaje.
--  · MEGAUP_PARTICLE_TEXTURE  → textura de la estela
--  · MEGAUP_PARTICLE_LENGTH   → longitud de la pieza visual
--  · MEGAUP_VERTICAL_OFFSET   → desplazamiento de spawn (sobre cabeza)
--  Escala isMega: opacidad 0.3 (mega) / 0.5 (normal), distancia ×1.4
-- ──────────────────────────────────────────────────────────────────

-- Declarada aquí para que MegaUpLogic.Activate() (sección [15]) la llame.
-- Los helpers de folder/kill ya están declarados en sección [15].
function createMegaUpParticle(isMega)
    if not flyanim.enabled then return end
    if not flyanim.megaTurboUpActive then return end

    local char = lplr and lplr.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local cam = workspace.CurrentCamera
    if not cam then return end

    -- Posición de spawn: sobre la cabeza del personaje
    local spawnPos = root.Position + MEGAUP_VERTICAL_OFFSET
    local awayDir  = Vector3.new(0, 1, 0)   -- siempre hacia arriba

    local part = Instance.new("Part")
    part.Anchored     = true
    part.CanCollide   = false
    part.CastShadow   = false
    part.Transparency = 1
    part.Size         = Vector3.new(0.2, MEGAUP_PARTICLE_LENGTH, 0.2)
    part.Position     = spawnPos
    part.Parent       = _megaUp_getFolder()

    -- Orientar la cara de la SurfaceGui hacia la cámara (horizontal)
    local toCam = cam.CFrame.Position - spawnPos
    local lookFlat = Vector3.new(toCam.X, 0, toCam.Z)
    if lookFlat.Magnitude > 0.01 then
        part.CFrame = CFrame.lookAt(spawnPos, spawnPos + lookFlat)
    else
        part.CFrame = CFrame.new(spawnPos)
    end

    local sg = Instance.new("SurfaceGui", part)
    sg.Adornee      = part
    sg.Face         = Enum.NormalId.Front
    sg.AlwaysOnTop  = true
    sg.LightInfluence = 0
    sg.SizingMode   = Enum.SurfaceGuiSizingMode.PixelsPerStud
    sg.PixelsPerStud = 50

    local img = Instance.new("ImageLabel", sg)
    img.Image               = MEGAUP_PARTICLE_TEXTURE
    img.Size                = UDim2.new(1, 0, 1, 0)
    img.BackgroundTransparency = 1
    img.ImageColor3         = WHITE
    img.ImageTransparency   = isMega and 0.3 or 0.5   -- mismo comportamiento que turbo
    img.ScaleType           = Enum.ScaleType.Fit

    local FADE_TIME  = 0.42
    local travelDist = isMega and 14 or 10             -- escala isMega como en efectomegaup
    local targetPos  = spawnPos + awayDir * travelDist

    local alive = true
    local particleRef = {part = part, dead = false}
    table.insert(_megaUpParticleList, particleRef)

    local function destroyPart()
        if not alive then return end
        alive             = false
        particleRef.dead  = true
        particleRef.part  = nil
        pcall(function() if part and part.Parent then part:Destroy() end end)
    end

    local fadeTween = TweenService:Create(img, TweenInfo.new(FADE_TIME, Enum.EasingStyle.Linear), {ImageTransparency = 1})
    fadeTween:Play()
    TweenService:Create(part, TweenInfo.new(FADE_TIME, Enum.EasingStyle.Linear), {Position = targetPos}):Play()
    fadeTween.Completed:Connect(destroyPart)
    task.delay(FADE_TIME + 0.05, destroyPart)
    task.delay(FADE_TIME + 0.1, function()
        for i = #_megaUpParticleList, 1, -1 do
            if _megaUpParticleList[i] and _megaUpParticleList[i].dead then
                table.remove(_megaUpParticleList, i)
            end
        end
    end)
end

-- ──────────────────────────────────────────────────────────────────
-- [18]  WHITE FLASH  (destello por velocidad)
-- ──────────────────────────────────────────────────────────────────
local whiteFlashGui = nil
local function destroyWhiteFlash()
    if whiteFlashGui then pcall(function() whiteFlashGui:Destroy() end); whiteFlashGui = nil end
end

local function speedWhiteFlash(mode)
    destroyWhiteFlash()
    -- Para mega up y turbo la velocidad efectiva es BASE_SPEED * TURBO_MULT
    local effectiveSpeed = (mode == "mega turbo" or mode == "mega up")
        and (BASE_SPEED * TURBO_MULT)
        or  BASE_SPEED
    local t = getBrightnessFactor(effectiveSpeed)
    if t <= 0 then return end
    local baseOpacity = 0.38
    -- "mega up" tiene flash brillante igual que turbo (misma escala de velocidad)
    local maxOpacity  = (mode == "mega turbo" or mode == "mega up") and (baseOpacity * 1.4) or baseOpacity
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

-- ──────────────────────────────────────────────────────────────────
-- [19]  EFECTOS VFX  (airShock / sonicBoom / landing / crater)
-- ──────────────────────────────────────────────────────────────────
local function airShockAura(intensity)
    local char = lplr and lplr.Character
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

local function sonicBoomEffect(intensity)
    local char = lplr and lplr.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local isMega = intensity == 2
    local scale  = isMega and 0.95 or 0.55
    local rings  = {
        { start=(isMega and 5 or 3)*scale,   peak=(isMega and 140 or 80)*scale,  exp=isMega and 0.32 or 0.20, fadeDelay=isMega and 0.14 or 0.08, fadeDur=isMega and 0.26 or 0.16 },
        { start=(isMega and 4 or 2)*scale,   peak=(isMega and 90 or 52)*scale,   exp=isMega and 0.20 or 0.12, fadeDelay=isMega and 0.06 or 0.04, fadeDur=isMega and 0.18 or 0.10 },
        { start=(isMega and 3 or 1.5)*scale, peak=(isMega and 55 or 32)*scale,   exp=isMega and 0.12 or 0.07, fadeDelay=0,                        fadeDur=isMega and 0.10 or 0.06 },
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
        task.delay(0.25, function() pcall(function() bb:Destroy() end) end)
        task.wait(0.04)
        if not img or not img.Parent then return end
        TweenService:Create(img, TweenInfo.new(0.2, Enum.EasingStyle.Exponential, Enum.EasingDirection.In), {ImageTransparency=1}):Play()
    end)
end

-- [IDs de landing movidos a sección [2] al inicio del script]

local function spawnLandingEffects(position, velocity)
    if not position then return end
    task.spawn(function()
        -- intensity: 0→1 basada en velocidad (150 studs/s = máximo)
        local intensity = math.clamp(velocity / 150, 0, 1)
        if intensity < 0.05 then return end

        -- Nivel 1-4 proporcional a intensity para reutilizar la lógica de aeffecto
        local nivelF = 1 + intensity * 3           -- 1.0 a 4.0
        local nivel  = math.clamp(math.floor(nivelF + 0.5), 1, 4)
        local multScale = 0.4 + intensity * 1.2    -- 0.4 a 1.6
        local multEmit  = multScale

        -- ── Punto de luz de impacto ──────────────────────────────────────
        local vfxPart = Instance.new("Part")
        vfxPart.Size = Vector3.new(1, 1, 1)
        vfxPart.Position = position + Vector3.new(0, 0.5, 0)
        vfxPart.Anchored = true; vfxPart.CanCollide = false
        vfxPart.Transparency = 1; vfxPart.Parent = workspace

        local impactFlash = Instance.new("PointLight")
        impactFlash.Color      = Color3.fromRGB(255, 250, 240)
        impactFlash.Range      = 40 * multScale
        impactFlash.Brightness = 15 * multScale
        impactFlash.Shadows    = true
        impactFlash.Parent     = vfxPart
        TweenService:Create(impactFlash,
            TweenInfo.new(0.15 * multScale, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out),
            {Brightness = 0, Range = 0}):Play()

        -- ── Detección temprana de material del suelo (impacto) ────────────
        -- Se hace ANTES del sonido para poder elegir el SFX correcto
        -- (cristal usa un sonido de rotura distinto al de aterrizaje normal).
        local impactFloorMaterial = Enum.Material.Grass
        do
            local rpEarly = RaycastParams.new()
            rpEarly.FilterType = Enum.RaycastFilterType.Exclude
            if lplr and lplr.Character then
                rpEarly.FilterDescendantsInstances = {lplr.Character}
            end
            local earlyHit = workspace:Raycast(position + Vector3.new(0, 5, 0), Vector3.new(0, -25, 0), rpEarly)
            if not earlyHit then
                earlyHit = workspace:Raycast(position + Vector3.new(0, 5, 0), Vector3.new(0, -60, 0), rpEarly)
            end
            if earlyHit then
                impactFloorMaterial = earlyHit.Instance.Material
            end
        end
        local isGlassFloor = (impactFloorMaterial == Enum.Material.Glass
            or impactFloorMaterial == Enum.Material.ForceField
            or impactFloorMaterial == Enum.Material.Ice)

        -- ── Sonido de impacto dinámico ───────────────────────────────────
        local volumeMap = {1.0, 2.5, 4.5, 7.0}
        local pitchMap  = {1.1, 0.85, 0.65, 0.5}
        local sfx = Instance.new("Sound")
        sfx.SoundId              = isGlassFloor and SFX_LANDING_GLASS or SFX_LANDING
        sfx.Volume               = volumeMap[nivel]
        sfx.PlaybackSpeed        = pitchMap[nivel]
        sfx.RollOffMaxDistance   = 300 * multScale
        sfx.Parent               = vfxPart
        sfx:Play()
        task.delay(8, function() pcall(function() sfx:Destroy() end) end)

        -- ── Attachment central para partículas ───────────────────────────
        local attachment = Instance.new("Attachment", vfxPart)

        -- ── Attachments inclinados para los anillos de choque ────────────
        local attFlat  = Instance.new("Attachment", vfxPart)
        attFlat.Orientation = Vector3.new(0, 0, 0)
        local attTilt1 = Instance.new("Attachment", vfxPart)
        attTilt1.Orientation = Vector3.new(35, 45, 0)
        local attTilt2 = Instance.new("Attachment", vfxPart)
        attTilt2.Orientation = Vector3.new(-25, -60, 15)

        -- Helper: escalar NumberSequence
        local function scaleNS(ns, scale)
            local kps = {}
            for _, kp in ipairs(ns.Keypoints) do
                table.insert(kps, NumberSequenceKeypoint.new(kp.Time, kp.Value * scale, kp.Envelope * scale))
            end
            return NumberSequence.new(kps)
        end
        local function scaleNR(nr, scale)
            return NumberRange.new(nr.Min * scale, nr.Max * scale)
        end

        -- ── Anillos de choque (ParticleEmitter orientado VelocityPerpendicular)
        local function emitirAnillo(textura, att, sizeMult, color)
            local ring = Instance.new("ParticleEmitter")
            ring.Texture      = textura
            ring.Orientation  = Enum.ParticleOrientation.VelocityPerpendicular
            ring.EmissionDirection = Enum.NormalId.Top
            ring.Speed        = NumberRange.new(0.01)
            ring.Size         = scaleNS(
                NumberSequence.new({
                    NumberSequenceKeypoint.new(0,   0),
                    NumberSequenceKeypoint.new(0.1, 20 * sizeMult),
                    NumberSequenceKeypoint.new(1,   60 * sizeMult),
                }), multScale)
            ring.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0,   0.4),
                NumberSequenceKeypoint.new(0.2, 0.7),
                NumberSequenceKeypoint.new(1,   1),
            })
            ring.Color        = ColorSequence.new(color)
            ring.Lifetime     = NumberRange.new(0.35 + nivel * 0.05)
            ring.LightEmission = 0.8
            ring.Rate         = 0
            ring.Parent       = att
            ring:Emit(2)
            task.delay(2, function() pcall(function() ring:Destroy() end) end)
        end

        emitirAnillo(SHOCKWAVE_CIRCLE_TEX, attFlat, 1.2, Color3.fromRGB(255, 255, 255))
        if nivel > 1 then
            emitirAnillo(PARTICLE_TEXTURE,      attFlat,  1.4, Color3.fromRGB(230, 230, 235))
            emitirAnillo(SHOCKWAVE_CIRCLE_TEX,  attTilt1, 0.9, Color3.fromRGB(210, 210, 220))
            emitirAnillo(PARTICLE_TEXTURE,      attTilt2, 1.1, Color3.fromRGB(220, 220, 230))
        end

        -- ── Polvo rodante (rolling dust) ─────────────────────────────────
        local rollingDust1 = Instance.new("ParticleEmitter")
        rollingDust1.Texture      = CAIDA_BASE_ID
        rollingDust1.Size         = scaleNS(NumberSequence.new({
            NumberSequenceKeypoint.new(0,   5),
            NumberSequenceKeypoint.new(0.2, 14),
            NumberSequenceKeypoint.new(1,   22),
        }), multScale)
        rollingDust1.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0,   0),
            NumberSequenceKeypoint.new(0.1, 0.1),
            NumberSequenceKeypoint.new(0.8, 0.7),
            NumberSequenceKeypoint.new(1,   1),
        })
        rollingDust1.Color        = ColorSequence.new({
            ColorSequenceKeypoint.new(0,   Color3.fromRGB(235, 235, 240)),
            ColorSequenceKeypoint.new(0.6, Color3.fromRGB(200, 200, 205)),
            ColorSequenceKeypoint.new(1,   Color3.fromRGB(160, 160, 165)),
        })
        rollingDust1.Lifetime     = scaleNR(NumberRange.new(1.2, 1.8), 1 + nivel * 0.1)
        rollingDust1.Speed        = scaleNR(NumberRange.new(55, 90), multScale)
        rollingDust1.SpreadAngle  = Vector2.new(180, 180)
        rollingDust1.RotSpeed     = NumberRange.new(-250, 250)
        rollingDust1.Drag         = 14
        rollingDust1.Acceleration = Vector3.new(0, -40 * multScale, 0)
        rollingDust1.ZOffset      = 2
        rollingDust1.Rate         = 0
        rollingDust1.Parent       = attachment

        local rollingDust2 = Instance.new("ParticleEmitter")
        rollingDust2.Texture      = AIR_SHOCK_ID   -- humo esponjoso
        rollingDust2.Size         = rollingDust1.Size
        rollingDust2.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.3),
            NumberSequenceKeypoint.new(1, 1),
        })
        rollingDust2.Color        = rollingDust1.Color
        rollingDust2.Lifetime     = rollingDust1.Lifetime
        rollingDust2.Speed        = rollingDust1.Speed
        rollingDust2.SpreadAngle  = rollingDust1.SpreadAngle
        rollingDust2.RotSpeed     = NumberRange.new(-50, 50)
        rollingDust2.Drag         = rollingDust1.Drag
        rollingDust2.Acceleration = rollingDust1.Acceleration
        rollingDust2.ZOffset      = 1
        rollingDust2.Rate         = 0
        rollingDust2.Parent       = attachment

        -- ── Polvo vertical ───────────────────────────────────────────────
        local verticalDust = Instance.new("ParticleEmitter")
        verticalDust.Texture         = CAIDA_OVERLAY_ID
        verticalDust.EmissionDirection = Enum.NormalId.Top
        verticalDust.Size            = scaleNS(NumberSequence.new({
            NumberSequenceKeypoint.new(0, 4),
            NumberSequenceKeypoint.new(1, 18),
        }), multScale)
        verticalDust.Transparency    = NumberSequence.new({
            NumberSequenceKeypoint.new(0,   0.1),
            NumberSequenceKeypoint.new(0.7, 0.8),
            NumberSequenceKeypoint.new(1,   1),
        })
        verticalDust.Color           = ColorSequence.new(Color3.fromRGB(215, 215, 220))
        verticalDust.Lifetime        = scaleNR(NumberRange.new(1.5, 2.5), 1 + nivel * 0.1)
        verticalDust.Speed           = scaleNR(NumberRange.new(25, 55), multScale)
        verticalDust.SpreadAngle     = Vector2.new(35, 35)
        verticalDust.RotSpeed        = NumberRange.new(-40, 40)
        verticalDust.Drag            = 7
        verticalDust.Acceleration    = Vector3.new(0, -10 * multScale, 0)
        verticalDust.ZOffset         = 0
        verticalDust.Rate            = 0
        verticalDust.Parent          = attachment

        -- Emitir partículas
        rollingDust1:Emit(math.floor(50 * multEmit))
        rollingDust2:Emit(math.floor(40 * multEmit))
        if nivel == 1 then
            verticalDust:Emit(math.floor(10 * multEmit))
        else
            verticalDust:Emit(math.floor(25 * multEmit))
        end

        -- Limpieza
        task.delay(8, function() pcall(function() vfxPart:Destroy() end) end)

        -- ── Cráter de corona (anillos de rocas) ──────────────────────────
        -- Solo para caídas medianas o grandes (nivel >= 2 → intensity >= 0.33)
        if intensity >= 0.33 then
            local escalaSize = multScale * 0.7     -- tamaño razonable en el mundo
            local escalaCantidad = multEmit * 0.7
            local craterFolder = Instance.new("Folder")
            craterFolder.Name   = "LandingCrater"
            craterFolder.Parent = workspace

            -- Detectar color/material del suelo en el punto de impacto.
            -- Valores por defecto (FALLBACK) si el raycast no logra info:
            -- usamos un material/color tipo "roca" en vez de césped verde,
            -- para que el cráter no luzca como bloques de lego blancos
            -- cuando no se pudo leer el suelo real.
            local FALLBACK_FLOOR_COLOR    = Color3.fromRGB(120, 115, 110)
            local FALLBACK_FLOOR_MATERIAL = Enum.Material.Rock
            local floorColor    = FALLBACK_FLOOR_COLOR
            local floorMaterial = FALLBACK_FLOOR_MATERIAL

            -- Esperar a que el personaje ya esté posado/asentado en el suelo
            -- antes de hacer el raycast de color/material (evita lecturas en
            -- el aire mientras todavía está cayendo/aterrizando).
            task.wait(0.15)

            -- Helper: detectar la Y real del suelo en un punto XZ dado
            local function getFloorY(worldPos, fallbackY)
                local rpLocal = RaycastParams.new()
                rpLocal.FilterType = Enum.RaycastFilterType.Exclude
                if lplr and lplr.Character then
                    rpLocal.FilterDescendantsInstances = {lplr.Character}
                end
                -- Lanzar desde un poco arriba hacia abajo para encontrar la superficie
                local hitLocal = workspace:Raycast(
                    worldPos + Vector3.new(0, 4, 0),
                    Vector3.new(0, -12, 0),
                    rpLocal
                )
                if hitLocal then return hitLocal.Position.Y end
                -- Segundo intento más largo por si el suelo está más abajo
                local hitLocal2 = workspace:Raycast(
                    worldPos + Vector3.new(0, 4, 0),
                    Vector3.new(0, -30, 0),
                    rpLocal
                )
                if hitLocal2 then return hitLocal2.Position.Y end
                return fallbackY
            end

            -- Raycast de color/material post-aterrizaje (ahora sí lee el suelo real)
            local rpFloor = RaycastParams.new()
            rpFloor.FilterType = Enum.RaycastFilterType.Exclude
            if lplr and lplr.Character then
                rpFloor.FilterDescendantsInstances = {lplr.Character}
            end
            -- Usar la posición ACTUAL del HRP (post-aterrizaje) en lugar de la
            -- posición capturada al inicio del vuelo. El personaje ya está sobre el suelo
            -- después de task.wait(0.15), así que leer la posición fresca garantiza que el
            -- raycast pegue en la superficie correcta.
            local function getCurrentRootPos()
                local currentRootPos = position  -- fallback a la posición original
                local charNow = lplr and lplr.Character
                local rootNow = charNow and charNow:FindFirstChild("HumanoidRootPart")
                if rootNow and rootNow.Parent then
                    currentRootPos = rootNow.Position
                end
                return currentRootPos
            end

            local function tryFloorRaycast()
                local currentRootPos = getCurrentRootPos()
                -- Primer intento: rango generoso desde arriba del punto de impacto actual
                local hit = workspace:Raycast(currentRootPos + Vector3.new(0, 5, 0), Vector3.new(0, -25, 0), rpFloor)
                -- Segundo intento si el primero falla: rango aún más largo
                if not hit then
                    hit = workspace:Raycast(currentRootPos + Vector3.new(0, 5, 0), Vector3.new(0, -60, 0), rpFloor)
                end
                -- Tercer intento: desde la posición original capturada por si el personaje se movió lejos
                if not hit then
                    hit = workspace:Raycast(position + Vector3.new(0, 5, 0), Vector3.new(0, -25, 0), rpFloor)
                end
                if not hit then
                    hit = workspace:Raycast(position + Vector3.new(0, 5, 0), Vector3.new(0, -60, 0), rpFloor)
                end
                return hit
            end

            local floorHit = tryFloorRaycast()
            -- Si todavía no hay info (personaje aún sin asentar), dar un poco
            -- más de tiempo y reintentar una vez antes de rendirse al fallback.
            if not floorHit then
                task.wait(0.1)
                floorHit = tryFloorRaycast()
            end

            if floorHit then
                floorColor    = floorHit.Instance.Color
                floorMaterial = floorHit.Instance.Material
            end

            -- Capturar también el MaterialVariant del suelo (textura personalizada)
            -- para que las rocas repliquen fielmente la apariencia del suelo.
            -- Si no hay floorHit, se deja vacío (las rocas usan el material/color
            -- de fallback tipo roca, NO el MaterialVariant).
            local floorMaterialVariant = ""
            if floorHit then
                pcall(function()
                    floorMaterialVariant = floorHit.Instance.MaterialVariant or ""
                end)
            end

            -- Wait adicional antes de spawnear las rocas para garantizar que
            -- el personaje está asentado y el raycast de color/material ya es fiable.
            task.wait(0.05)


            local rings = {
                {pieces = math.max(4, math.floor(8  * escalaCantidad)), radius = 5  * escalaSize, sizeMult = 1.0 * escalaSize},
                {pieces = math.max(6, math.floor(12 * escalaCantidad)), radius = 10 * escalaSize, sizeMult = 1.3 * escalaSize},
                {pieces = math.max(8, math.floor(18 * escalaCantidad)), radius = 16 * escalaSize, sizeMult = 1.6 * escalaSize},
            }
            local rocas = {}
            for _, ring in ipairs(rings) do
                for i = 1, ring.pieces do
                    local angle = math.rad((360 / ring.pieces) * i + math.random(-8, 8))
                    local offset = Vector3.new(math.cos(angle) * ring.radius, 0, math.sin(angle) * ring.radius)
                    local chunk = Instance.new("Part")
                    chunk.Size = Vector3.new(
                        math.random(25, 45) / 10 * ring.sizeMult,
                        math.random(15, 25) / 10 * (escalaSize ^ 0.5),
                        math.random(35, 65) / 10 * ring.sizeMult
                    )
                    -- Usar la Y real del suelo en el punto lateral del fragmento
                    local lateralPos = Vector3.new(position.X + offset.X, position.Y, position.Z + offset.Z)
                    local realFloorY = getFloorY(lateralPos, position.Y)
                    chunk.Position = Vector3.new(
                        position.X + offset.X,
                        realFloorY - chunk.Size.Y * 0.5,
                        position.Z + offset.Z
                    )
                    chunk.Anchored    = true
                    chunk.CanCollide  = false
                    chunk.Material    = floorMaterial
                    chunk.Color       = floorColor
                    -- Copiar la textura personalizada del suelo (MaterialVariant)
                    if floorMaterialVariant and floorMaterialVariant ~= "" then
                        pcall(function() chunk.MaterialVariant = floorMaterialVariant end)
                    end
                    local lookAt = CFrame.lookAt(chunk.Position, Vector3.new(position.X, chunk.Position.Y, position.Z))
                    local upTilt = math.rad(-math.random(30, 55) + (ring.radius * 1.5 / escalaSize))
                    local sideRoll = math.rad(math.random(-15, 15))
                    chunk.CFrame  = lookAt * CFrame.Angles(upTilt, 0, sideRoll)
                    chunk.Parent  = craterFolder
                    table.insert(rocas, chunk)
                    if isGlassFloor then
                        -- ── Efecto de cristal roto: los trozos salen volando ──────
                        local burstDir = (offset.Magnitude > 0.01 and offset.Unit or Vector3.new(math.random(-10,10)/10, 0, math.random(-10,10)/10))
                        local burstDist  = (8 + math.random() * 14) * escalaSize
                        local burstUp    = (6 + math.random() * 10) * escalaSize
                        local burstSpin  = math.rad(math.random(180, 720)) * (math.random() < 0.5 and -1 or 1)
                        local burstTarget = chunk.CFrame
                            + (burstDir * burstDist)
                            + Vector3.new(0, burstUp, 0)
                        burstTarget = burstTarget * CFrame.Angles(burstSpin, burstSpin * 0.6, burstSpin * 0.3)
                        local burstTime = 0.5 + math.random() * 0.4
                        TweenService:Create(chunk,
                            TweenInfo.new(burstTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                            {CFrame = burstTarget, Transparency = 1}):Play()
                        task.delay(burstTime + 0.05, function() pcall(function() chunk:Destroy() end) end)
                    else
                        -- Pequeño tween hacia arriba al aparecer
                        local targetUp = chunk.CFrame + Vector3.new(0, chunk.Size.Y * 0.9, 0)
                        TweenService:Create(chunk, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {CFrame = targetUp}):Play()
                    end
                end
            end
            -- Hundo todas las rocas de vuelta al mismo tiempo
            local waitDrop = 3.5 + nivel * 0.5
            task.delay(waitDrop, function()
                for _, roca in ipairs(rocas) do
                    if roca and roca.Parent then
                        TweenService:Create(roca,
                            TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
                            {CFrame = roca.CFrame - Vector3.new(0, roca.Size.Y * 2, 0)}):Play()
                    end
                end
                task.delay(2, function() pcall(function() craterFolder:Destroy() end) end)
            end)
        end

        -- ── Camera shake escalada por intensidad ──────────────────────────
        if intensity >= 0.33 then
            local shakeInt = 2.0 + intensity * 1.5
            shakeCamera(shakeInt, 0.30)
        else
            local shakeInt2 = 0.8 + intensity * 3.6
            shakeCamera(shakeInt2, 0.18)
        end
    end)
end

local function startIdleWatcher()
    if flyanim.idleTimer then task.cancel(flyanim.idleTimer); flyanim.idleTimer = nil end
    flyanim.idleTimer = task.spawn(function()
        while flyanim.enabled do
            task.wait(0.1)
            if not flyanim.enabled then break end
            -- Mega Up es modo independiente: no necesita teclas para mantenerse activo,
            -- pero sí debe cancelarse si el personaje se queda quieto.
            -- Los modos "normal" y transiciones se ignoran aquí.
            if flyanim.mode == "normal" then continue end
            if flyanim.turboTransitioning or flyanim.megaTransitioning then continue end
            if flyanim.turboPreImpulsoActivo then continue end

            local anyKey = UserInputService:IsKeyDown(Enum.KeyCode.W)
                        or UserInputService:IsKeyDown(Enum.KeyCode.S)
                        or UserInputService:IsKeyDown(Enum.KeyCode.A)
                        or UserInputService:IsKeyDown(Enum.KeyCode.D)

            -- ── Mega Up: cancela cuando el personaje está quieto ────────────
            -- (Space suelto ya lo cancela en el listener, esto es la capa idle)
            -- Nota: en modo "mega up" megaTurboUpActive puede seguir en true mientras
            -- el loop corre; la condición correcta es solo chequear el modo y las teclas.
            if flyanim.mode == "mega up" and not anyKey then
                MegaUpLogic.Deactivate()
                _megaUp_restaurarNormal()
                -- Restaurar animaciones normales inmediatamente tras cancelar Mega Up por idle
                task.defer(function()
                    if flyanim.enabled and flyanim.mode == "normal" and not flyanim.comboPlaying then
                        flyanim._normalPlayId = (flyanim._normalPlayId or 0) + 1
                        local pid = flyanim._normalPlayId
                        iniciarCicloNormal(pid)
                        task.delay(0.05, function()
                            if flyanim.enabled and flyanim.mode == "normal" and flyanim._normalPlayId == pid then
                                evaluarMovimientoNormal()
                            end
                        end)
                    end
                end)
                continue
            end

            -- ── Turbo / Fast: sin teclas → volver a normal ─────────────────
            if (flyanim.mode == "turbo" or flyanim.mode == "mega turbo") and not anyKey then
                local prevMode = flyanim.mode
                -- BUG FIX: desconectar los render conns ANTES de cambiar el modo.
                -- Si primero se cambia mode a "normal" y luego se desconectan,
                -- los render conns (turboRenderConn/megaRenderConn) pueden ejecutarse
                -- un frame más con mode == "normal", detectar la salida y llamar
                -- restaurarC0Inmediato() con un token ya invalido. Desconectando
                -- primero evitamos ese frame fantasma y el race condition con
                -- iniciarCicloNormal / turboPreImpulsoActivo.
                if flyanim.turboRenderConn then flyanim.turboRenderConn:Disconnect(); flyanim.turboRenderConn = nil end
                if flyanim.megaRenderConn  then flyanim.megaRenderConn:Disconnect();  flyanim.megaRenderConn  = nil end
                flyanim.mode   = "normal"
                getgenv().AFO_FLYMODE  = flyanim.mode
                getgenv().AFO_FLYSTATE = flyanim.enabled
                flyanim.speed  = BASE_SPEED
                flyanim.qLastPress = 0
                if flyanim.updateMode then flyanim.updateMode("normal") end
                if not flyanim.noclipSpaceActive and not flyanim.noclipCtrlActive then setNoclip(false) end
                stopParticleEmitter()
                detenerWatchdogAltura()
                if prevMode == "turbo" then
                    detenerPoseTurbo()
                elseif prevMode == "mega turbo" then
                    detenerPoseMega()
                    detenerPoseTurbo()
                end
                flyanim.c0ControlToken = (flyanim.c0ControlToken or 0) + 1
                restaurarC0Inmediato()
                if not flyanim.comboPlaying then
                    flyanim._normalPlayId = (flyanim._normalPlayId or 0) + 1
                    iniciarCicloNormal(flyanim._normalPlayId)
                    task.defer(function()
                        if flyanim.enabled and flyanim.mode == "normal" and not flyanim.comboPlaying then
                            evaluarMovimientoNormal()
                        end
                    end)
                end
                continue
            end
        end
    end)
end(char, expectedSession)
    local animScript = char:FindFirstChild("Animate") or char:WaitForChild("Animate", 3)
    if expectedSession and flyanim.sessionToken ~= expectedSession then return end
    if animScript then animScript.Disabled = true; flyanim.animScript = animScript end
    local humanoid = char:WaitForChild("Humanoid", 5)
    if expectedSession and flyanim.sessionToken ~= expectedSession then return end
    if not humanoid then return end
    local animator = humanoid:WaitForChild("Animator", 5)
    if expectedSession and flyanim.sessionToken ~= expectedSession then return end
    if not animator then return end
    flyanim.animator = animator
    flyanim.tracks   = {}
    local ok, playing = pcall(function() return animator:GetPlayingAnimationTracks() end)
    if ok and playing then
        for _, t in ipairs(playing) do pcall(function() t:Stop(0) end) end
    end
    if flyanim.animConn then flyanim.animConn:Disconnect(); flyanim.animConn = nil end
    local hrp = char:WaitForChild("HumanoidRootPart", 5)
    if expectedSession and flyanim.sessionToken ~= expectedSession then return end
    if not hrp then return end
    local rj = hrp:WaitForChild("RootJoint", 5)
    if expectedSession and flyanim.sessionToken ~= expectedSession then return end
    if not rj then return end
    flyanim.rootJoint  = rj
    flyanim.originalC0 = rj.C0
    for _, id in pairs(ANIM) do pcall(function() getTrack(id) end) end

    local function loadNorm(id, priority, looped)
        local anim = Instance.new("Animation")
        anim.AnimationId = id
        local ok2, t = pcall(function() return animator:LoadAnimation(anim) end)
        pcall(function() anim:Destroy() end)
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
    if nt.lateral     then pcall(function() nt.lateral:Play(0);     nt.lateral:Stop(0) end) end
    if nt.mov_back    then pcall(function() nt.mov_back:Play(0);    nt.mov_back:Stop(0) end) end
    if nt.espacio_sec then pcall(function() nt.espacio_sec:Play(0); nt.espacio_sec:Stop(0) end) end

    local ownAnimIds = {}
    for _, id in pairs(ANIM) do ownAnimIds[id] = true end
    ownAnimIds[CAIDA_BASE_ID]    = true
    ownAnimIds[CAIDA_OVERLAY_ID] = true

    flyanim.animConn = animator.AnimationPlayed:Connect(function(track)
        if not track or not track.Animation then return end
        local id = track.Animation.AnimationId
        if not ownAnimIds[id] then
            pcall(function() if track and track.IsPlaying then track:Stop(0) end end)
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
        pcall(function() humanoid:ChangeState(Enum.HumanoidStateType.Landed) end)
        task.wait(0.05)
        pcall(function() humanoid:ChangeState(Enum.HumanoidStateType.Running) end)
    end
end

local _landAnimToken = 0
local _landBaseRef    = nil
local _landOverlayRef = nil

-- Escala de caída:
-- < 45 studs  → nada (nivel 0)
-- 45 studs    → nivel 1 (shake leve)
-- 45→1500     → interpolación suave nivel 1→4
-- ≥ 1500      → nivel 4 fijo (animación completa máxima)
-- nivel < 2   → solo shake de cámara
-- nivel >= 2  → animación completa de aterrizaje + shake escalado
local function _calcFallLevel(altura)
    if altura < 45 then return 0 end
    local t = math.clamp((altura - 45) / (1500 - 45), 0, 1)
    return 1 + t * 3   -- 1.0 a 4.0
end

local function doLanding(char)
    if not char or not char.Parent then return end
    local hum_check = char:FindFirstChildOfClass("Humanoid")
    if not hum_check or hum_check.Health <= 0 then return end
    local humanoid = hum_check
    local animator = humanoid:FindFirstChildOfClass("Animator")
    local altura    = flyanim.landingHeight or 0
    local impactVel = math.max(flyanim.landingVelocity or 0, flyanim.landingVelocityCapture or 0)
    flyanim.landingHeight          = nil
    flyanim.landingVelocity        = 0
    flyanim.landingVelocityCapture = 0

    -- El nivel depende SOLO de la altura, sin flags externos
    local fallLevel = _calcFallLevel(altura)
    if fallLevel <= 0 then restoreGameAnimations(char); return end

    -- nivel >= 1.0 (45+ studs) → animación completa siempre
    local useFullAnim = (fallLevel >= 1.0)

    if not animator then restoreGameAnimations(char); return end

    flyanim.idleTimerAnim  = 0
    flyanim.isBrazosActive = false
    flyanim.evalToken      = (flyanim.evalToken or 0) + 1
    flyanim.isWDown = false; flyanim.isSDown = false
    flyanim.isADown = false; flyanim.isDDown = false
    flyanim.wDown   = false; flyanim.sDown   = false
    flyanim.aDown   = false; flyanim.dDown   = false
    flyanim.isBrazosActive = false
    flyanim.idleTimerAnim  = 0

    if flyanim.turboRenderConn then flyanim.turboRenderConn:Disconnect(); flyanim.turboRenderConn = nil end
    if flyanim.megaRenderConn  then flyanim.megaRenderConn:Disconnect();  flyanim.megaRenderConn  = nil end
    if flyanim.blockRenderConn then flyanim.blockRenderConn:Disconnect(); flyanim.blockRenderConn = nil end
    if flyanim.idleAnimConn    then flyanim.idleAnimConn:Disconnect();    flyanim.idleAnimConn    = nil end
    flyanim.idleWatchToken     = (flyanim.idleWatchToken or 0) + 1
    flyanim.c0ControlToken     = (flyanim.c0ControlToken or 0) + 1
    detenerWatchdogAltura()
    restaurarC0Inmediato()
    if flyanim.blockTrack and flyanim.blockTrack.IsPlaying then pcall(function() flyanim.blockTrack:Stop(0) end) end
    flyanim.isBlocking         = false
    flyanim.isSpaceAdv         = false
    flyanim.turboTransitioning = false
    flyanim.megaTransitioning  = false
    if flyanim.animConn then flyanim.animConn:Disconnect(); flyanim.animConn = nil end
    stopAnimBlockLoop()
    local ok2, playing = pcall(function() return animator:GetPlayingAnimationTracks() end)
    if ok2 and playing then for _, track in ipairs(playing) do pcall(function() track:Stop(0) end) end end
    for _, t in pairs(flyanim.tracks) do pcall(function() if t and t.IsPlaying then t:Stop(0) end end) end
    for _, t in pairs(flyanim.normalTracks) do pcall(function() if t and t.IsPlaying then t:Stop(0) end end) end
    flyanim.tracks       = {}
    flyanim.normalTracks = {}
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
        local st = humanoid:GetState()
        if st ~= Enum.HumanoidStateType.Landed and st ~= Enum.HumanoidStateType.Running then
            pcall(function() humanoid:ChangeState(Enum.HumanoidStateType.Landed) end)
        end
    end
    local root      = char:FindFirstChild("HumanoidRootPart")
    local impactPos = (root and safepos(root.Position)) and root.Position or Vector3.new(0, 0, 0)
    if root then
        local _, ry, _ = root.CFrame:ToOrientation()
        if isnan(ry) then ry = 0 end
        local currentPos = root.Position
        pcall(function()
            root.CFrame = CFrame.new(currentPos) * CFrame.Angles(0, ry, 0)
            root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
        end)
    end
    spawnLandingEffects(impactPos, math.max(impactVel, altura * 0.5))

    -- fallLevel: 1.0 = mínimo (45 studs), 4.0 = máximo (≥1500 studs)
    local lvlNorm = math.clamp((fallLevel - 1) / 3, 0, 1)  -- 0.0 a 1.0

    if useFullAnim then
        -- Efecto completo de aterrizaje épico (nivel >= 2, ~530 studs)
        if not animator or not animator.Parent then restoreGameAnimations(char); return end
        local animObjBase = Instance.new("Animation")
        animObjBase.AnimationId = CAIDA_BASE_ID
        local animObjOverlay = Instance.new("Animation")
        animObjOverlay.AnimationId = CAIDA_OVERLAY_ID
        local landBase    = animator:LoadAnimation(animObjBase)
        local landOverlay = animator:LoadAnimation(animObjOverlay)
        pcall(function() animObjBase:Destroy() end)
        pcall(function() animObjOverlay:Destroy() end)
        landBase.Priority    = Enum.AnimationPriority.Action3
        landOverlay.Priority = Enum.AnimationPriority.Action4
        landBase.Looped    = true
        landOverlay.Looped = true
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
        -- (shake ya aplicado desde spawnLandingEffects)
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
        if _landBaseRef    == landBase    then _landBaseRef    = nil end
        if _landOverlayRef == landOverlay then _landOverlayRef = nil end
    else
        -- Caída leve: solo animación breve (shake ya desde spawnLandingEffects)
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
        pcall(function() hum2:ChangeState(Enum.HumanoidStateType.Landed) end)
        task.wait(0.05)
        pcall(function() hum2:ChangeState(Enum.HumanoidStateType.Running) end)
    end
end

local comboPendingClick = false

local function _launchComboAnim(animId, speed)
    for id, track in pairs(flyanim.tracks) do
        if id ~= animId and id ~= ANIM.levitacion and track and track.IsPlaying then
            pcall(function() track:Stop(0.05) end)
        end
    end
    -- BUG FIX 1: Detener SOLO las pistas de movimiento activo de normalTracks
    -- (brazos, mov_forward, mov_back, mov_brazos, lateral, espacio_prim, espacio_sec)
    -- para evitar que queden congeladas en el último frame entre golpes del combo.
    -- Se excluyen "estatica" y "levitacion" (son la base visual pasiva y no interfieren
    -- visualmente con el combo) y las pistas turbo/mega (no aplican en modo normal).
    local COMBO_STOP_NORM = {
        "brazos", "mov_forward", "mov_back", "mov_brazos",
        "lateral", "espacio_prim", "espacio_sec",
    }
    local nt = flyanim.normalTracks
    if nt then
        for _, key in ipairs(COMBO_STOP_NORM) do
            local track = nt[key]
            pcall(function() if track and track.IsPlaying then track:Stop(0.05) end end)
        end
    end
    local t = getTrack(animId)
    if not t then return end
    t.Looped   = false
    t.Priority = Enum.AnimationPriority.Action4
    if t.IsPlaying then pcall(function() t:Stop(0) end) end
    pcall(function() t:Play(0.05, 1, 1) end)
    pcall(function() t:AdjustSpeed(speed or 3.0) end)
    cancelarBrazos()
end

local function resetCombo()
    flyanim.comboStep      = 0
    flyanim.comboLastClick = 0
    flyanim.combo2LastUsed = nil
    comboPendingClick      = false
end

local function stopComboC0Lock()
    if flyanim.comboC0Conn then flyanim.comboC0Conn:Disconnect(); flyanim.comboC0Conn = nil end
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

local function finalizarCombo()
    flyanim.dashTimer    = 0
    flyanim.dashVel      = Vector3.new(0, 0, 0)
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
        local nt  = flyanim.normalTracks
        if nt and nt.levitacion and not nt.levitacion.IsPlaying then
            pcall(function() nt.levitacion:Play(0.2) end)
            pcall(function() nt.levitacion:AdjustSpeed(ANIM_NORMAL.VELOCIDAD_LEVITACION) end)
        end
        iniciarCicloNormal(pid)
        -- Evaluar el movimiento de inmediato (sin delay adicional) para que,
        -- si el jugador ya está moviéndose (W/A/S/D mantenidas durante el
        -- combo), la animación de movimiento correspondiente se reproduzca
        -- al instante en vez de quedar "congelada" en idle unos instantes.
        if flyanim.enabled and flyanim.mode == "normal" then evaluarMovimientoNormal() end
    else
        updateAnimForMovement()
    end
end

local function runComboSequencer(startToken)
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
            if tick() - waitStart > COMBO_PENDING_WINDOW then finalizarCombo(); return false end
        end
        comboPendingClick = false
        if flyanim.comboToken ~= startToken then return false end
        return true
    end

    flyanim.comboStep = 1
    _launchComboAnim(ANIM.combo1, 3.0)
    flyanim.comboBusy = true
    comboPendingClick = false
    if not waitStep(1) then return end

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

    flyanim.comboStep = 3
    local chosenId3 = (flyanim.combo2LastUsed == "a") and ANIM.combo3b or ANIM.combo3a
    _launchComboAnim(chosenId3, 3.0)
    flyanim.comboBusy = true
    comboPendingClick = false
    if not waitStep(3) then return end

    flyanim.comboStep = 4
    local spaceDown4 = UserInputService:IsKeyDown(Enum.KeyCode.Space)
    if spaceDown4 then
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

    local t4 = getTrack(ANIM.combo4)
    if not t4 then finalizarCombo(); return end
    for id, track in pairs(flyanim.tracks) do
        if id ~= ANIM.combo4 and id ~= ANIM.levitacion and track and track.IsPlaying then
            pcall(function() track:Stop(0.05) end)
        end
    end
    t4.Looped   = false
    t4.Priority = Enum.AnimationPriority.Action4
    if t4.IsPlaying then pcall(function() t4:Stop(0) end) end
    pcall(function() t4:Play(0.05, 1, 1) end)
    local toLoad = tick() + 2
    while (not t4.Length or t4.Length == 0) and tick() < toLoad do
        task.wait(0.02)
        if flyanim.comboToken ~= startToken then flyanim.combo4Frozen = false; return end
    end
    pcall(function() t4:AdjustSpeed(4.0) end)
    flyanim.comboBusy    = true
    comboPendingClick    = false
    flyanim.combo4Frozen = false
    local len4      = t4.Length or 1
    local PAUSE_PERC = 0.55
    local timeout4b  = tick() + 4
    while t4.IsPlaying and tick() < timeout4b do
        task.wait(0.016)
        if flyanim.comboToken ~= startToken then flyanim.combo4Frozen = false; return end
        len4 = t4.Length or 1
        if len4 > 0 and t4.TimePosition >= len4 * PAUSE_PERC then break end
    end
    if flyanim.comboToken ~= startToken then flyanim.combo4Frozen = false; return end
    flyanim.combo4Frozen = true
    flyanim.comboBusy    = false
    pcall(function() t4:AdjustSpeed(0) end)
    if len4 > 0 then pcall(function() t4.TimePosition = len4 * PAUSE_PERC end) end
    local stepDur4      = COMBO_STEP_DURATION[4]
    local pauseDeadline = tick() + (stepDur4 * (1 - PAUSE_PERC) + 0.08)
    while not comboPendingClick and tick() < pauseDeadline do
        task.wait(0.02)
        if flyanim.comboToken ~= startToken then flyanim.combo4Frozen = false; return end
    end
    flyanim.combo4Frozen = false
    comboPendingClick    = false
    if flyanim.comboToken ~= startToken then return end
    pcall(function() t4:AdjustSpeed(15) end)
    t4.Looped = false
    local timeout4c = tick() + 2
    while t4.IsPlaying and tick() < timeout4c do
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
    if flyanim.comboPlaying then
        if flyanim.comboBusy then return end
        comboPendingClick      = true
        flyanim.comboLastClick = tick()
        return
    end
    local now = tick()
    if now - flyanim.comboLastClick < COMBO_MIN_GAP then return end
    flyanim.comboToken = (flyanim.comboToken or 0) + 1
    local myToken = flyanim.comboToken
    if flyanim.idleAnimConn then flyanim.idleAnimConn:Disconnect(); flyanim.idleAnimConn = nil end
    if flyanim.isBlocking then
        stopBlocking()
        flyanim.blockCancelledByCombo = true
    end
    cancelarBrazos()
    flyanim.comboPlaying   = true
    flyanim.comboLastClick = now
    comboPendingClick      = false
    startComboC0Lock()
    task.spawn(function() runComboSequencer(myToken) end)
end

-- ──────────────────────────────────────────────────────────────────
-- [14]  SISTEMA DE COMBO  (click izquierdo)
-- ──────────────────────────────────────────────────────────────────
local function startComboListener()
    if flyanim.comboConn     then flyanim.comboConn:Disconnect()     end
    if flyanim.comboHoldConn then flyanim.comboHoldConn:Disconnect() end
    if flyanim._comboEndConn then flyanim._comboEndConn:Disconnect() end
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
    comboEndConn = UserInputService.InputEnded:Connect(function(input)
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
        lastHoldFire = now
        if not flyanim.comboPlaying then return end
        if flyanim.comboBusy then return end
        if not comboPendingClick then
            comboPendingClick      = true
            flyanim.comboLastClick = now
        end
    end)
    flyanim._comboEndConn = comboEndConn
end

local function stopComboListener()
    if flyanim.comboConn     then flyanim.comboConn:Disconnect();     flyanim.comboConn     = nil end
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

-- ──────────────────────────────────────────────────────────────────
-- [15]  MEGA UP  —  sistema independiente del Mega Turbo
--
--  · Comparte con Mega Turbo: sonido (SFX_MEGA_TURBO), lógica de
--    aceleración (escala con TURBO_MULT) y expulsión de datos hacia
--    la GUI.
--  · Es INDEPENDIENTE en: nombre de modo ("mega up"), partículas
--    (verticales, ver sección [17]), efectos VFX propios (cono hacia
--    abajo en vez de anillos horizontales) y white flash propio.
--  · No llama "mega turbo" en ninguna parte; no genera partículas turbo.
-- ──────────────────────────────────────────────────────────────────

-- ── VFX verticales exclusivos de Mega Up (efectomegaup.lua) ─────
--  Diferencia clave con Mega Turbo:
--    · sonicBoomEffect usa anillos horizontales hacia la cámara.
--    · megaUp_sonicBoomEffect usa capas que se expanden hacia abajo
--      en cono, reproduciendo el efecto de "lanzamiento vertical".
--    · megaUp_airShockAura usa SurfaceGui plano sobre la cabeza en
--      vez de BillboardGui lateral.

local function megaUp_airShockAura()
    local char = lplr and lplr.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local function spawnFlatAura(isMegaAura)
        local spawnPos = root.Position + MEGAUP_VERTICAL_OFFSET
        local p = Instance.new("Part")
        p.Anchored=true; p.CanCollide=false; p.CastShadow=false; p.Transparency=1
        p.Size = Vector3.new(1, 1, 0.01)
        p.CFrame = CFrame.lookAt(spawnPos, spawnPos + Vector3.new(0, 1, 0))
        p.Parent = workspace
        local function attachImages(face)
            local sg = Instance.new("SurfaceGui", p)
            sg.Face=face; sg.AlwaysOnTop=false; sg.LightInfluence=0
            sg.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud; sg.PixelsPerStud=50
            local i1 = Instance.new("ImageLabel", sg)
            i1.Image=AIR_SHOCK_ID; i1.Size=UDim2.new(1,0,1,0); i1.BackgroundTransparency=1
            i1.ImageColor3 = isMegaAura and Color3.fromRGB(220,245,255) or Color3.fromRGB(210,240,255)
            i1.ImageTransparency = isMegaAura and 0.15 or 0.25
            i1.ScaleType=Enum.ScaleType.Fit; i1.Rotation = isMegaAura and 22 or 0
            local i2 = Instance.new("ImageLabel", sg)
            i2.Image=AIR_SHOCK_ID
            i2.Size = isMegaAura and UDim2.new(1.5,0,1.5,0) or UDim2.new(1.3,0,1.3,0)
            i2.Position = isMegaAura and UDim2.new(-0.25,0,-0.25,0) or UDim2.new(-0.15,0,-0.15,0)
            i2.BackgroundTransparency=1
            i2.ImageColor3 = isMegaAura and Color3.fromRGB(190,225,255) or Color3.fromRGB(180,220,255)
            i2.ImageTransparency = isMegaAura and 0.30 or 0.45
            i2.ScaleType=Enum.ScaleType.Fit; i2.Rotation = isMegaAura and 60 or 45
            return i1, i2
        end
        local f1, f2 = attachImages(Enum.NormalId.Front)
        local b1, b2 = attachImages(Enum.NormalId.Back)
        local endSize = isMegaAura and 480 or 200
        local dur1    = isMegaAura and 0.22 or 0.14
        TweenService:Create(p, TweenInfo.new(dur1, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
            {Size=Vector3.new(endSize,endSize,0.01)}):Play()
        local t1 = TweenInfo.new(dur1+0.10, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
        local t2 = TweenInfo.new(dur1+0.06, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
        TweenService:Create(f1,t1,{ImageTransparency=1}):Play(); TweenService:Create(b1,t1,{ImageTransparency=1}):Play()
        TweenService:Create(f2,t2,{ImageTransparency=1}):Play(); TweenService:Create(b2,t2,{ImageTransparency=1}):Play()
        task.delay(0.40, function() pcall(function() p:Destroy() end) end)
    end

    task.spawn(function() spawnFlatAura(false) end)
    task.spawn(function()
        task.wait(0.05)
        if root and root.Parent then spawnFlatAura(true) end
    end)
end

local function megaUp_sonicBoomEffect()
    local char = lplr and lplr.Character
    if not char then return end
    local currentRoot = char:FindFirstChild("HumanoidRootPart")
    if not currentRoot then return end

    -- Capas cónicas que se expanden hacia abajo (efecto de lanzamiento vertical)
    local scale = 1.2
    local layers = {
        { yStart = 0,  yDrop = -2,   sStart = 2,  sEnd = 25  * scale, dur = 0.15 },
        { yStart = -1, yDrop = -6,   sStart = 4,  sEnd = 45  * scale, dur = 0.20 },
        { yStart = -2, yDrop = -12,  sStart = 8,  sEnd = 70  * scale, dur = 0.25 },
        { yStart = -3, yDrop = -20,  sStart = 12, sEnd = 100 * scale, dur = 0.30 },
        { yStart = -4, yDrop = -30,  sStart = 16, sEnd = 140 * scale, dur = 0.35 },
    }
    local travelDir = Vector3.new(0, 1, 0)
    for i, r in ipairs(layers) do
        task.spawn(function()
            task.wait((i-1) * 0.03)
            local cr = char:FindFirstChild("HumanoidRootPart")
            if not cr then return end
            local basePos = cr.Position + MEGAUP_VERTICAL_OFFSET
            local startPos = basePos + Vector3.new(0, r.yStart, 0)
            local endPos   = basePos + Vector3.new(0, r.yDrop,  0)
            local p = Instance.new("Part")
            p.Anchored=true; p.CanCollide=false; p.CanTouch=false; p.CastShadow=false; p.Transparency=1
            p.Size = Vector3.new(r.sStart, r.sStart, 0.01)
            p.CFrame = CFrame.lookAt(startPos, startPos + travelDir)
            p.Parent = workspace
            local function makeSG(face)
                local sg = Instance.new("SurfaceGui", p)
                sg.Adornee=p; sg.Face=face; sg.AlwaysOnTop=false; sg.LightInfluence=0
                sg.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud; sg.PixelsPerStud=50
                local img = Instance.new("ImageLabel", sg)
                img.Image=RING_ID; img.Size=UDim2.new(1,0,1,0); img.BackgroundTransparency=1
                img.ImageColor3=WHITE; img.ImageTransparency=0.05
                return img
            end
            local imgF = makeSG(Enum.NormalId.Front)
            local imgB = makeSG(Enum.NormalId.Back)
            TweenService:Create(p, TweenInfo.new(r.dur, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Size = Vector3.new(r.sEnd, r.sEnd, 0.01),
                CFrame = CFrame.lookAt(endPos, endPos + travelDir),
            }):Play()
            local fadeDur = r.dur + 0.05
            local fadeInfo = TweenInfo.new(fadeDur, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
            TweenService:Create(imgF, fadeInfo, {ImageTransparency=1}):Play()
            TweenService:Create(imgB, fadeInfo, {ImageTransparency=1}):Play()
            task.delay(fadeDur + 0.1, function() pcall(function() p:Destroy() end) end)
        end)
    end
end

-- ── Helpers de limpieza compartidos ─────────────────────────────
local function _megaUp_limpiarAnimaciones(fade)
    fade = fade or 0.05
    flyanim.idleWatchToken = (flyanim.idleWatchToken or 0) + 1
    if flyanim.idleAnimConn then flyanim.idleAnimConn:Disconnect(); flyanim.idleAnimConn = nil end
    detenerWatchdogAltura()
    detenerNormalTracks(fade)
    for _, t in pairs(flyanim.tracks) do
        pcall(function() if t and t.IsPlaying then t:Stop(fade) end end)
    end
    if flyanim.espacioTrackActivo then
        pcall(function() flyanim.espacioTrackActivo:Stop(fade) end)
        flyanim.espacioTrackActivo = nil
    end
    if flyanim.spaceHoldTimerAdv then task.cancel(flyanim.spaceHoldTimerAdv); flyanim.spaceHoldTimerAdv = nil end
    flyanim.isSpaceAdv = false
end

local function _megaUp_restaurarNormal()
    flyanim.megaTurboUpActive = false
    flyanim.speed             = BASE_SPEED
    flyanim.mode              = "normal"
    getgenv().AFO_FLYMODE  = flyanim.mode
    getgenv().AFO_FLYSTATE = flyanim.enabled
    if flyanim.updateMode then flyanim.updateMode("normal") end
    -- Invalidar el token de C0 para detener el RenderStepped de Mega Up
    flyanim.c0ControlToken = (flyanim.c0ControlToken or 0) + 1
    detenerWatchdogAltura()
    restaurarC0Inmediato()
    -- Detener todas las pistas que puedan haber quedado activas
    for _, t in pairs(flyanim.tracks) do
        pcall(function() if t and t.IsPlaying then t:Stop(0.1) end end)
    end
    for _, t in pairs(flyanim.normalTracks) do
        pcall(function() if t and t.IsPlaying then t:Stop(0.1) end end)
    end
    -- Restaurar animaciones normales en el siguiente frame para evitar
    -- race conditions con el cleanup de partículas y conexiones.
    task.defer(function()
        if flyanim.enabled and flyanim.mode == "normal" and not flyanim.comboPlaying then
            flyanim._normalPlayId = (flyanim._normalPlayId or 0) + 1
            local pid = flyanim._normalPlayId
            iniciarCicloNormal(pid)
            task.delay(0.05, function()
                if flyanim.enabled and flyanim.mode == "normal" and flyanim._normalPlayId == pid then
                    evaluarMovimientoNormal()
                end
            end)
        end
    end)
end

-- ── White flash exclusivo de Mega Up ────────────────────────────
--  Escala de opacidad igual que turbo pero usando la velocidad
--  resultante de BASE_SPEED * TURBO_MULT para ser coherente.
local function speedWhiteFlashMegaUp()
    -- reutiliza la misma función con flag "mega up"
    speedWhiteFlash("mega up")
end

-- ── Partícula vertical Mega Up ──────────────────────────────────
--  La lógica concreta está en sección [17]; aquí solo declaramos
--  los controles de ciclo para que MegaUpLogic pueda arrancar/parar.
local _megaUpParticleConn    = nil
local _megaUpParticleRunning = false
local _megaUpParticleFolder  = nil
local _megaUpParticleList    = {}

local function _megaUp_getFolder()
    if _megaUpParticleFolder and _megaUpParticleFolder.Parent == workspace then
        return _megaUpParticleFolder
    end
    _megaUpParticleFolder = Instance.new("Folder")
    _megaUpParticleFolder.Name   = "AFO_MegaUp_Particles"
    _megaUpParticleFolder.Parent = workspace
    return _megaUpParticleFolder
end

local function _megaUp_killParticles()
    for _, ref in ipairs(_megaUpParticleList) do
        if ref and not ref.dead then
            ref.dead = true
            if ref.part then pcall(function() ref.part:Destroy() end) end
            ref.part = nil
        end
    end
    _megaUpParticleList = {}
    if _megaUpParticleFolder and _megaUpParticleFolder.Parent then
        for _, child in ipairs(_megaUpParticleFolder:GetChildren()) do
            pcall(function() child:Destroy() end)
        end
    end
end

-- ── Estado del sistema Mega Up ──────────────────────────────────
local MegaUpLogic = {
    Active   = false,
    LoopConn = nil,
    Token    = 0,
}

function MegaUpLogic.Deactivate()
    MegaUpLogic.Active = false
    MegaUpLogic.Token  = MegaUpLogic.Token + 1
    if MegaUpLogic.LoopConn then
        MegaUpLogic.LoopConn:Disconnect()
        MegaUpLogic.LoopConn = nil
    end
    -- Detener el RenderStepped de animación/C0 de Mega Up
    if flyanim.megaRenderConn then
        flyanim.megaRenderConn:Disconnect()
        flyanim.megaRenderConn = nil
    end
    -- Detener partículas verticales exclusivas
    if _megaUpParticleConn then
        task.cancel(_megaUpParticleConn)
        _megaUpParticleConn = nil
    end
    _megaUpParticleRunning = false
    _megaUp_killParticles()
end

function MegaUpLogic.Activate()
    if MegaUpLogic.Active                               then return end
    if flyanim.mode == "mega turbo"                          then return end
    if flyanim.turboTransitioning or flyanim.megaTransitioning then return end

    MegaUpLogic.Deactivate()
    MegaUpLogic.Active = true
    MegaUpLogic.Token  = MegaUpLogic.Token + 1
    local myToken = MegaUpLogic.Token

    -- ── 1. Limpiar estado previo ────────────────────────────────
    stopParticleEmitter()      -- detiene estelas turbo/fast
    killActiveParticles()
    cancelarBrazos()
    _megaUp_limpiarAnimaciones(0.05)

    -- ── 2. Efectos visuales y sonoros (comparte sonido con Mega Turbo;
    --       VFX propios: cono vertical en vez de anillos horizontales)
    playLocalSound(SFX_MEGA_TURBO, 0.90)   -- mismo sonido que Mega Turbo
    megaUp_sonicBoomEffect()               -- cono hacia abajo (exclusivo Mega Up)
    megaUp_airShockAura()                  -- aura plana sobre la cabeza (exclusivo)

    -- ── 3. White flash exclusivo de Mega Up ────────────────────
    speedWhiteFlashMegaUp()

    -- ── 4. Impulso vertical inicial ────────────────────────────
    local char = lplr and lplr.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if root and flyanim.enabled and flyanim.bv and flyanim.bv.Parent then
        local velY = BASE_SPEED * TURBO_MULT * 0.8   -- escala con TURBO_MULT
        if not isnan(velY) then
            root.AssemblyLinearVelocity = Vector3.new(0, velY, 0)
        end
    end

    -- ── 5. Notificar GUI con modo "mega up" (no "mega turbo") ────────
    flyanim.megaTurboUpActive = true
    flyanim.mode  = "mega up"
    getgenv().AFO_FLYMODE  = flyanim.mode
    getgenv().AFO_FLYSTATE = flyanim.enabled
    flyanim.speed = BASE_SPEED * TURBO_MULT
    if flyanim.updateMode then flyanim.updateMode("mega up") end

    -- ── 5b. Animación exclusiva de Mega Up (espacio_sec congelada al 50%) ──
    -- Usa la pista espacio_sec igual que el script aislado EspacioUpMegaUp.lua:
    -- Play → AdjustSpeed(0) → TimePosition = Length * 0.5
    -- SIN inclinación de C0 (pose plana/vertical ascendente).
    do
        local nt = flyanim.normalTracks
        if nt then
            -- Detener cualquier megaRenderConn previa (Mega Turbo u otro Mega Up)
            if flyanim.megaRenderConn then flyanim.megaRenderConn:Disconnect(); flyanim.megaRenderConn = nil end
            -- Detener pistas de movimiento que puedan interferir
            for _, t in pairs(flyanim.tracks) do
                pcall(function() if t and t.IsPlaying then t:Stop(0.1) end end)
            end
            -- Detener pistas normales excepto levitación
            if nt.mov_forward  and nt.mov_forward.IsPlaying  then pcall(function() nt.mov_forward:Stop(0.1)  end) end
            if nt.mov_back     and nt.mov_back.IsPlaying     then pcall(function() nt.mov_back:Stop(0.1)     end) end
            if nt.lateral      and nt.lateral.IsPlaying      then pcall(function() nt.lateral:Stop(0.1)      end) end
            if nt.mov_brazos   and nt.mov_brazos.IsPlaying   then pcall(function() nt.mov_brazos:Stop(0.1)   end) end
            if nt.espacio_prim and nt.espacio_prim.IsPlaying then pcall(function() nt.espacio_prim:Stop(0.1) end) end
            -- Detener las pistas de mega turbo por si quedaron residuales
            if nt.mega_pose   and nt.mega_pose.IsPlaying   then pcall(function() nt.mega_pose:Stop(0.1)   end) end
            if nt.mega_base   and nt.mega_base.IsPlaying   then pcall(function() nt.mega_base:Stop(0.1)    end) end
            if nt.mega_volado and nt.mega_volado.IsPlaying then pcall(function() nt.mega_volado:Stop(0.1)  end) end

            flyanim.c0ControlToken = (flyanim.c0ControlToken or 0) + 1
            local myC0Token = flyanim.c0ControlToken
            local rootJoint  = flyanim.rootJoint
            local originalC0 = flyanim.originalC0

            -- Reproducir espacio_sec → congelar → saltar al 50%
            if nt.espacio_sec then
                nt.espacio_sec.Priority = Enum.AnimationPriority.Action4
                nt.espacio_sec.Looped   = false
                if nt.espacio_sec.IsPlaying then pcall(function() nt.espacio_sec:Stop(0) end) end
                pcall(function() nt.espacio_sec:Play(0.1) end)
                pcall(function() nt.espacio_sec:AdjustSpeed(0) end)
                task.defer(function()
                    if nt.espacio_sec and nt.espacio_sec.IsPlaying
                    and nt.espacio_sec.Length and nt.espacio_sec.Length > 0 then
                        pcall(function() nt.espacio_sec.TimePosition = nt.espacio_sec.Length * 0.5 end)
                    end
                end)
                flyanim.espacioTrackActivo = nt.espacio_sec
            end

            -- RenderStepped: mantener C0 vertical (sin inclinación) durante Mega Up
            -- Guardado en megaRenderConn para limpieza correcta
            if rootJoint and originalC0 then
                flyanim.megaRenderConn = RunService.RenderStepped:Connect(function()
                    if not MegaUpLogic.Active or not flyanim.enabled or flyanim.mode ~= "mega up" then
                        if flyanim.megaRenderConn then flyanim.megaRenderConn:Disconnect(); flyanim.megaRenderConn = nil end
                        return
                    end
                    if myC0Token ~= flyanim.c0ControlToken then
                        if flyanim.megaRenderConn then flyanim.megaRenderConn:Disconnect(); flyanim.megaRenderConn = nil end
                        return
                    end
                    -- Pose vertical: compensación de altura mínima, SIN inclinación (modo up)
                    local tNow = tick()
                    local movY = math.sin(tNow * ANIM_MEGA.FRECUENCIA_LEVITACION) * (ANIM_MEGA.AMPLITUD_LEVITACION * 0.5)
                    pcall(function()
                        rootJoint.C0 = originalC0 * CFrame.new(0, ANIM_MEGA.COMPENSACION_ALTURA + movY, 0)
                    end)
                end)
            end
        end
    end

    -- ── 6. Arrancar partículas verticales exclusivas ────────────
    --    (ver sección [17] para createMegaUpParticle)
    if not _megaUpParticleRunning then
        _megaUpParticleRunning = true
        local emitSession = flyanim.sessionToken
        _megaUpParticleConn = task.spawn(function()
            while flyanim.enabled
                and flyanim.sessionToken == emitSession
                and flyanim.megaTurboUpActive
                and MegaUpLogic.Active
            do
                local c2 = lplr and lplr.Character
                if c2 and c2:FindFirstChild("HumanoidRootPart") then
                    createMegaUpParticle(true)   -- isMega=true → más opacidad / distancia
                    task.wait(0.04)
                    if flyanim.megaTurboUpActive and MegaUpLogic.Active then
                        createMegaUpParticle(true)
                    end
                end
                task.wait(0.08)
            end
            _megaUpParticleRunning = false
            _megaUpParticleConn    = nil
            _megaUp_killParticles()
        end)
    end

    -- ── 7. Loop principal: mantener velocidad, detectar fin y forzar idle al quietarse ────
    local startT = os.clock()
    local _idleCountdown = 0   -- segundos sin movimiento dentro de megaup
    local MEGAUP_IDLE_TIMEOUT = 0.35  -- tiempo sin mover antes de forzar idle
    MegaUpLogic.LoopConn = RunService.Heartbeat:Connect(function(dt)
        if MegaUpLogic.Token ~= myToken then return end

        -- Fin por desactivación externa o fly apagado
        if not flyanim.enabled or not MegaUpLogic.Active then
            MegaUpLogic.Deactivate()
            _megaUp_restaurarNormal()
            return
        end

        -- Fin por timeout (4 segundos)
        if os.clock() - startT > 4.0 then
            MegaUpLogic.Deactivate()
            _megaUp_restaurarNormal()
            return
        end

        -- Mantener velocidad escalada con TURBO_MULT
        if flyanim.bv and flyanim.bv.Parent then
            local newSpeed = BASE_SPEED * TURBO_MULT
            if not isnan(newSpeed) then flyanim.speed = newSpeed end
        end

        -- [FIX-1] Detectar que el jugador se detuvo y forzar idle de inmediato
        local spaceStillDown = UserInputService:IsKeyDown(Enum.KeyCode.Space)
        local anyMove = flyanim.isWDown or flyanim.isSDown or flyanim.isADown or flyanim.isDDown
        if not spaceStillDown and not anyMove then
            _idleCountdown = _idleCountdown + (dt or 0)
            if _idleCountdown >= MEGAUP_IDLE_TIMEOUT then
                -- El jugador soltó espacio y no mueve teclas → terminar MegaUp y volver a idle
                MegaUpLogic.Deactivate()
                _megaUp_restaurarNormal()
                return
            end
        else
            _idleCountdown = 0
        end
    end)
end

local function activateMegaTurboUp()
    MegaUpLogic.Activate()
end

local function startMegaTurboUpListener()
    if flyanim.megaTurboUpConn then flyanim.megaTurboUpConn:Disconnect(); flyanim.megaTurboUpConn = nil end
    flyanim.megaTurboUpConn = RunService.RenderStepped:Connect(function()
        if not flyanim.enabled then return end
        if isTyping() then return end
        if flyanim.turboPreImpulsoActivo then return end
        -- Bloquear mega up durante turbo (Mega Turbo) y durante cualquier transición
        if flyanim.mode == "mega turbo" then
            flyanim.spaceHoldStart = nil
            return
        end
        if flyanim.turboTransitioning or flyanim.megaTransitioning then
            flyanim.spaceHoldStart = nil
            return
        end
        local spaceDown = UserInputService:IsKeyDown(Enum.KeyCode.Space)
        local modeOk    = (flyanim.mode == "normal" or flyanim.mode == "turbo") and not flyanim.megaTurboUpActive
        if spaceDown and modeOk then
            if not flyanim.spaceHoldStart then flyanim.spaceHoldStart = tick() end
            if tick() - flyanim.spaceHoldStart >= flyanim.SPACE_HOLD_TIME then
                flyanim.spaceHoldStart = nil
                activateMegaTurboUp()
            end
        else
            flyanim.spaceHoldStart = nil
            if flyanim.megaTurboUpActive and not spaceDown then
                MegaUpLogic.Deactivate()
                _megaUp_restaurarNormal()
            end
        end
    end)
end

local function stopMegaTurboUpListener()
    if flyanim.megaTurboUpConn then flyanim.megaTurboUpConn:Disconnect(); flyanim.megaTurboUpConn = nil end
    flyanim.spaceHoldStart    = nil
    flyanim.megaTurboUpActive = false
    -- También detener partículas verticales de Mega Up
    MegaUpLogic.Deactivate()
end

-- ──────────────────────────────────────────────────────────────────
-- [24]  GUI  (panel HUD)
-- ──────────────────────────────────────────────────────────────────
local function _flyDestroyGui()
    if flyanim.pulse then pcall(function() task.cancel(flyanim.pulse) end); flyanim.pulse = nil end
    flyanim.expanded = false; flyanim.updateLbl = nil; flyanim.updateMode = nil
    if flyanim._dragInputConn then flyanim._dragInputConn:Disconnect(); flyanim._dragInputConn = nil end
    if flyanim.gui then pcall(function() flyanim.gui:Destroy() end); flyanim.gui = nil end
end

local function createToggle(parent, xPos, yPos, initialState, onChange)
    local switchWidth = 36; local switchHeight = 18; local knobSize = 14
    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(0, switchWidth, 0, switchHeight); bg.Position = UDim2.new(0, xPos, 0, yPos)
    bg.BackgroundColor3 = initialState and Color3.fromRGB(80, 200, 80) or Color3.fromRGB(80, 80, 80)
    bg.BorderSizePixel = 0; bg.Parent = parent
    Instance.new("UICorner", bg).CornerRadius = UDim.new(1, 0)
    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, knobSize, 0, knobSize)
    knob.Position = initialState
        and UDim2.new(1, -knobSize-2, 0.5, -knobSize/2)
        or  UDim2.new(0, 2, 0.5, -knobSize/2)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255); knob.BorderSizePixel = 0; knob.Parent = bg
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
    local state  = initialState
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, 0, 1, 0); button.BackgroundTransparency = 1; button.Text = ""; button.Parent = bg
    button.MouseButton1Click:Connect(function()
        state = not state
        TweenService:Create(bg, TweenInfo.new(0.1, Enum.EasingStyle.Quad),
            {BackgroundColor3 = state and Color3.fromRGB(80,200,80) or Color3.fromRGB(80,80,80)}):Play()
        TweenService:Create(knob, TweenInfo.new(0.1, Enum.EasingStyle.Quad),
            {Position = state
                and UDim2.new(1,-knobSize-2,0.5,-knobSize/2)
                or  UDim2.new(0,2,0.5,-knobSize/2)}):Play()
        if onChange then onChange(state) end
    end)
    return bg
end

local function _flyBuildGui()
    _reloadFT()
    _flyDestroyGui()

    
    local C_PURPLE  = Color3.fromRGB(110,  30, 180)
    local C_BLACK   = Color3.fromRGB(6,     4,  12)
    local C_ACCENT  = Color3.fromRGB(160,  60, 255)
    local C_TEXT    = Color3.fromRGB(255, 255, 255)
    local C_SUBTEXT = Color3.fromRGB(190, 160, 220)
    local C_GREEN   = Color3.fromRGB(80,  255, 150)
    local C_YELLOW  = Color3.fromRGB(255, 220,  60)
    local C_RED     = Color3.fromRGB(255,  80,  80)
    local C_CYAN    = Color3.fromRGB(80,  200, 255)
    local C_GOLD    = Color3.fromRGB(255, 220,  80)
    
    local C_SEC1    = Color3.fromRGB(52,  17,  90)   
    local C_SEC2    = Color3.fromRGB(38,  12,  68)   
    local C_SEC3    = Color3.fromRGB(24,   7,  46)   

    
    local W        = 280
    local H_MINI   = 48
    local DOT_SIZE = 10
    local PAD      = 10
    local ROW_H    = 22   
    local TOGGLE_W = 36   

    
    
    
    
    local H_NOCLIP = 8 + 20 + 4 + 3*(ROW_H + 4) + 8
    local H_SPEED  = 8 + 3*(ROW_H + 6) + 8 + 28 + 8
    local CONTENT_H = H_NOCLIP + 6 + H_SPEED + 4
    local H_FULL   = H_MINI + 4 + CONTENT_H + 4

    local TW = TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

    
    local sg = Instance.new("ScreenGui")
    sg.Name = "AFO_FlyHUD"; sg.ResetOnSpawn = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.IgnoreGuiInset = true; sg.Parent = CoreGui
    flyanim.gui = sg

    local root = Instance.new("Frame", sg)
    root.Size = UDim2.new(0, W, 0, H_FULL)
    root.Position = UDim2.new(0.5, -W/2, 0, 6)
    root.BackgroundTransparency = 1; root.BorderSizePixel = 0

    local panel = Instance.new("Frame", root)
    panel.Size = UDim2.new(1, 0, 0, H_MINI)
    panel.BackgroundColor3 = C_BLACK
    panel.BackgroundTransparency = 0.06; panel.BorderSizePixel = 0
    Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 12)
    local stroke = Instance.new("UIStroke", panel)
    stroke.Color = C_PURPLE; stroke.Thickness = 1.2; stroke.Transparency = 0.75

    
    local topBar = Instance.new("Frame", panel)
    topBar.Size = UDim2.new(1, 0, 0, H_MINI)
    topBar.Position = UDim2.new(0, 0, 0, 0)
    topBar.BackgroundTransparency = 1

    local iconLbl = Instance.new("TextLabel", topBar)
    iconLbl.Size = UDim2.new(0, 20, 1, 0); iconLbl.Position = UDim2.new(0, PAD, 0, 0)
    iconLbl.BackgroundTransparency = 1; iconLbl.Font = Enum.Font.Legacy
    iconLbl.TextSize = 15; iconLbl.TextColor3 = C_ACCENT
    iconLbl.Text = "🚀"; iconLbl.TextXAlignment = Enum.TextXAlignment.Center
    iconLbl.TextYAlignment = Enum.TextYAlignment.Center

    local titleLbl = Instance.new("TextLabel", topBar)
    titleLbl.Size = UDim2.new(0, 96, 1, 0); titleLbl.Position = UDim2.new(0, PAD + 30, 0, 0)
    titleLbl.BackgroundTransparency = 1; titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextSize = 12; titleLbl.TextColor3 = C_TEXT
    titleLbl.Text = FT.fly_title .. "  [" .. flyanim.flyKey.Name .. "]"
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.TextYAlignment = Enum.TextYAlignment.Center
    titleLbl.TextScaled = false

    local sep = Instance.new("Frame", topBar)
    sep.Size = UDim2.new(0, 1, 0, 22); sep.Position = UDim2.new(0, PAD + 118, 0.5, -11)
    sep.BackgroundColor3 = C_PURPLE; sep.BackgroundTransparency = 0.4

    
    local modeLbl = Instance.new("TextLabel", topBar)
    modeLbl.Size = UDim2.new(1, -(PAD + 130 + DOT_SIZE + 16), 1, 0)
    modeLbl.Position = UDim2.new(0, PAD + 126, 0, 0)
    modeLbl.BackgroundTransparency = 1; modeLbl.Font = Enum.Font.GothamBold
    modeLbl.TextSize = 12; modeLbl.TextColor3 = C_GREEN
    modeLbl.Text = FT.mode_normal
    modeLbl.TextXAlignment = Enum.TextXAlignment.Center
    modeLbl.TextYAlignment = Enum.TextYAlignment.Center

    local dotBtn = Instance.new("TextButton", topBar)
    dotBtn.Size = UDim2.new(0, DOT_SIZE + 10, 1, 0)
    dotBtn.Position = UDim2.new(1, -(DOT_SIZE + 14), 0, 0)
    dotBtn.BackgroundTransparency = 1; dotBtn.Text = ""
    local dot = Instance.new("Frame", dotBtn)
    dot.Size = UDim2.new(0, DOT_SIZE, 0, DOT_SIZE)
    dot.Position = UDim2.new(0.5, -DOT_SIZE/2, 0.5, -DOT_SIZE/2)
    dot.BackgroundColor3 = C_ACCENT
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

    
    local expandZone = Instance.new("Frame", panel)
    expandZone.Size = UDim2.new(1, -2*PAD + 4, 0, CONTENT_H)
    expandZone.Position = UDim2.new(0, PAD - 2, 0, H_MINI + 4)
    expandZone.BackgroundTransparency = 1
    expandZone.BorderSizePixel = 0; expandZone.Visible = false

    local layout = Instance.new("UIListLayout", expandZone)
    layout.Padding = UDim.new(0, 4)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment = Enum.VerticalAlignment.Top

    
    local function makeSection(h, bgColor, strokeColor)
        local f = Instance.new("Frame")
        f.Size = UDim2.new(1, 0, 0, h)
        f.BackgroundColor3 = bgColor; f.BackgroundTransparency = 0
        f.BorderSizePixel = 0
        Instance.new("UICorner", f).CornerRadius = UDim.new(0, 7)
        local s = Instance.new("UIStroke", f)
        s.Color = C_ACCENT; s.Thickness = 1; s.Transparency = 0.75
        return f
    end

    
    local function makeRow(parent, yPos)
        local row = Instance.new("Frame", parent)
        row.Size = UDim2.new(1, -16, 0, ROW_H)
        row.Position = UDim2.new(0, 8, 0, yPos)
        row.BackgroundTransparency = 1
        return row
    end

    
    local function rowLabel(row, text, font, size, color, xOffset)
        local lbl = Instance.new("TextLabel", row)
        lbl.Size = UDim2.new(1, -(TOGGLE_W + 14 + (xOffset or 0)), 1, 0)
        lbl.Position = UDim2.new(0, xOffset or 0, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Font = font or Enum.Font.Gotham
        lbl.TextSize = size or 10; lbl.TextColor3 = color or C_TEXT
        lbl.Text = text
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.TextYAlignment = Enum.TextYAlignment.Center
        return lbl
    end

    
    local function rowToggle(row, initialState, onChange)
        local xPos = row.Size.X.Scale == 1
            and (W - 2*PAD + 4 - 16 - TOGGLE_W)  
            or  (W - 2*PAD - 16 - TOGGLE_W - 8)
        createToggle(row, row.AbsoluteSize.X > 0
            and (row.AbsoluteSize.X - TOGGLE_W - 2)
            or  (W - 52), 2, initialState, onChange)
    end

    
    local noclipSec = makeSection(H_NOCLIP, C_SEC2, C_PURPLE)
    noclipSec.Parent = expandZone

    
    local noclipTitleEmoji = Instance.new("TextLabel", noclipSec)
    noclipTitleEmoji.Size = UDim2.new(0, 18, 0, 20); noclipTitleEmoji.Position = UDim2.new(0, 8, 0, 8)
    noclipTitleEmoji.BackgroundTransparency = 1; noclipTitleEmoji.Font = Enum.Font.Legacy
    noclipTitleEmoji.TextSize = 11; noclipTitleEmoji.TextColor3 = C_TEXT
    noclipTitleEmoji.Text = "👻"; noclipTitleEmoji.TextXAlignment = Enum.TextXAlignment.Center
    noclipTitleEmoji.TextYAlignment = Enum.TextYAlignment.Center

    local noclipTitle = Instance.new("TextLabel", noclipSec)
    noclipTitle.Size = UDim2.new(1, -32, 0, 20); noclipTitle.Position = UDim2.new(0, 30, 0, 8)
    noclipTitle.BackgroundTransparency = 1; noclipTitle.Font = Enum.Font.GothamBold
    noclipTitle.TextSize = 11; noclipTitle.TextColor3 = C_TEXT
    noclipTitle.Text = FT.noclip_title
    noclipTitle.TextXAlignment = Enum.TextXAlignment.Left
    noclipTitle.TextYAlignment = Enum.TextYAlignment.Center

    
    local NOCLIP_ROW_START = 8 + 20 + 4   
    local NOCLIP_ROW_STEP  = ROW_H + 4

    local function makeNoclipRow(yPos, emojiText, labelText, initialState, onChange)
        local row = Instance.new("Frame", noclipSec)
        row.Size = UDim2.new(1, -16, 0, ROW_H); row.Position = UDim2.new(0, 8, 0, yPos)
        row.BackgroundTransparency = 1
        local emojiLbl = Instance.new("TextLabel", row)
        emojiLbl.Size = UDim2.new(0, 16, 1, 0); emojiLbl.Position = UDim2.new(0, 0, 0, 0)
        emojiLbl.BackgroundTransparency = 1; emojiLbl.Font = Enum.Font.Legacy
        emojiLbl.TextSize = 12; emojiLbl.TextColor3 = C_CYAN
        emojiLbl.Text = emojiText
        emojiLbl.TextXAlignment = Enum.TextXAlignment.Center
        emojiLbl.TextYAlignment = Enum.TextYAlignment.Center
        local lbl = Instance.new("TextLabel", row)
        lbl.Size = UDim2.new(1, -(TOGGLE_W + 10 + 20), 1, 0); lbl.Position = UDim2.new(0, 20, 0, 0)
        lbl.BackgroundTransparency = 1; lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 10; lbl.TextColor3 = C_TEXT
        lbl.Text = labelText
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.TextYAlignment = Enum.TextYAlignment.Center
        local tgl = createToggle(row, 0, (ROW_H - 18) / 2, initialState, onChange)
        tgl.Position = UDim2.new(1, -(TOGGLE_W + 4), 0, (ROW_H - 18) / 2)
    end

    makeNoclipRow(NOCLIP_ROW_START + 0*NOCLIP_ROW_STEP, "⬆", FT.noclip_space, flyanim.noclipSpaceEnabled, function(s) flyanim.noclipSpaceEnabled = s end)
    makeNoclipRow(NOCLIP_ROW_START + 1*NOCLIP_ROW_STEP, "⬇", FT.noclip_ctrl,  flyanim.noclipCtrlEnabled,  function(s) flyanim.noclipCtrlEnabled  = s end)

    
    local megaYPos = NOCLIP_ROW_START + 2*NOCLIP_ROW_STEP
    local megaRow = Instance.new("Frame", noclipSec)
    megaRow.Size = UDim2.new(1, -16, 0, ROW_H); megaRow.Position = UDim2.new(0, 8, 0, megaYPos)
    megaRow.BackgroundTransparency = 1
    local megaEmojiLbl = Instance.new("TextLabel", megaRow)
    megaEmojiLbl.Size = UDim2.new(0, 16, 1, 0); megaEmojiLbl.Position = UDim2.new(0, 0, 0, 0)
    megaEmojiLbl.BackgroundTransparency = 1; megaEmojiLbl.Font = Enum.Font.Legacy
    megaEmojiLbl.TextSize = 12; megaEmojiLbl.TextColor3 = C_CYAN
    megaEmojiLbl.Text = "🚅"; megaEmojiLbl.TextXAlignment = Enum.TextXAlignment.Center
    megaEmojiLbl.TextYAlignment = Enum.TextYAlignment.Center
    local megaLabel = Instance.new("TextLabel", megaRow)
    megaLabel.Size = UDim2.new(1, -(TOGGLE_W + 8 + 20), 1, 0); megaLabel.Position = UDim2.new(0, 20, 0, 0)
    megaLabel.BackgroundTransparency = 1; megaLabel.Font = Enum.Font.Gotham
    megaLabel.TextSize = 10; megaLabel.TextColor3 = C_TEXT
    megaLabel.Text = FT.noclip_mega
    megaLabel.TextXAlignment = Enum.TextXAlignment.Left
    megaLabel.TextYAlignment = Enum.TextYAlignment.Center
    local megaTgl = createToggle(megaRow, 0, (ROW_H - 18) / 2, flyanim.noclipMegaEnabled, function(s) flyanim.noclipMegaEnabled = s end)
    megaTgl.Position = UDim2.new(1, -(TOGGLE_W + 4), 0, (ROW_H - 18) / 2)

    
    local speedSec = makeSection(H_SPEED, C_SEC3, C_PURPLE)
    speedSec.Parent = expandZone

    
    local SPEED_ROW_START = 8
    local SPEED_ROW_STEP  = ROW_H + 6

    local function makeSpeedRow(emojiText, labelText, rowIdx, defaultVal, minVal, maxVal)
        local yTop = SPEED_ROW_START + rowIdx * SPEED_ROW_STEP
        local SECTION_W = W - 2*PAD + 4 - 16
        local BOX_W = 80
        local BOX_X = SECTION_W - BOX_W - 4
        local LABEL_W = BOX_X - 24

        local emojiLbl = Instance.new("TextLabel", speedSec)
        emojiLbl.Size = UDim2.new(0, 18, 0, ROW_H); emojiLbl.Position = UDim2.new(0, 8, 0, yTop)
        emojiLbl.BackgroundTransparency = 1; emojiLbl.Font = Enum.Font.Legacy; emojiLbl.TextSize = 11
        emojiLbl.TextColor3 = C_ACCENT
        emojiLbl.Text = emojiText; emojiLbl.TextXAlignment = Enum.TextXAlignment.Center
        emojiLbl.TextYAlignment = Enum.TextYAlignment.Center

        local lbl = Instance.new("TextLabel", speedSec)
        lbl.Size = UDim2.new(0, LABEL_W, 0, ROW_H); lbl.Position = UDim2.new(0, 30, 0, yTop)
        lbl.BackgroundTransparency = 1; lbl.Font = Enum.Font.GothamSemibold
        lbl.TextSize = 10; lbl.TextColor3 = C_TEXT
        lbl.Text = labelText; lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.TextYAlignment = Enum.TextYAlignment.Center

        local box = Instance.new("TextBox", speedSec)
        box.Size = UDim2.new(0, BOX_W, 0, ROW_H); box.Position = UDim2.new(0, BOX_X, 0, yTop)
        box.BackgroundColor3 = Color3.fromRGB(15, 5, 28); box.BackgroundTransparency = 0.05
        box.BorderSizePixel = 0; box.Font = Enum.Font.GothamBold; box.TextSize = 11
        box.TextColor3 = C_TEXT; box.Text = tostring(defaultVal); box.ClearTextOnFocus = true
        box.PlaceholderText = tostring(minVal) .. "-" .. tostring(maxVal)
        box.PlaceholderColor3 = Color3.fromRGB(130, 100, 180)
        Instance.new("UICorner", box).CornerRadius = UDim.new(0, 5)
        local bs = Instance.new("UIStroke", box); bs.Color = C_ACCENT; bs.Thickness = 1; bs.Transparency = 0.5

        box:GetPropertyChangedSignal("Text"):Connect(function()
            local n = tonumber(box.Text:match("[%d%.]+"))
            if n then
                n = math.clamp(n, minVal, maxVal)
                if not isnan(n) then box.Text = tostring(n) end
            end
        end)
        return box
    end

    local speedBox = makeSpeedRow("🚀", FT.speed_base,       0, BASE_SPEED, 1, 10000)
    local fastBox  = makeSpeedRow("🚄", FT.speed_turbo_mult, 1, FAST_MULT,  1, 1000)
    local turboBox = makeSpeedRow("🚅", FT.speed_mega_mult,  2, TURBO_MULT, 1, 1000)

    local RESET_Y  = SPEED_ROW_START + 3*SPEED_ROW_STEP + 4
    local resetBtn = Instance.new("TextButton", speedSec)
    resetBtn.Size = UDim2.new(0, 110, 0, 24); resetBtn.Position = UDim2.new(0.5, -55, 0, RESET_Y)
    resetBtn.BackgroundColor3 = Color3.fromRGB(60, 10, 110); resetBtn.BackgroundTransparency = 0.2
    resetBtn.BorderSizePixel = 0; resetBtn.Font = Enum.Font.Legacy
    resetBtn.TextSize = 11; resetBtn.TextColor3 = C_TEXT
    resetBtn.Text = "🔄  " .. FT.speed_reset
    Instance.new("UICorner", resetBtn).CornerRadius = UDim.new(0, 6)
    Instance.new("UIStroke", resetBtn).Color = C_PURPLE

    local function recalcSpeed()
        if isnan(BASE_SPEED) then BASE_SPEED = DEFAULT_BASE end
        if isnan(FAST_MULT)  then FAST_MULT  = DEFAULT_FAST end
        if isnan(TURBO_MULT) then TURBO_MULT = DEFAULT_TURBO end
        if flyanim.mode == "normal" then flyanim.speed = BASE_SPEED
        elseif flyanim.mode == "turbo"  then flyanim.speed = BASE_SPEED * FAST_MULT
        elseif flyanim.mode == "mega turbo" then flyanim.speed = BASE_SPEED * TURBO_MULT end
        if isnan(flyanim.speed) then flyanim.speed = BASE_SPEED end
    end

    speedBox.FocusLost:Connect(function()
        local n = tonumber(speedBox.Text:match("[%d%.]+"))
        if n and not isnan(n) then BASE_SPEED = math.clamp(math.floor(n+0.5), 1, 10000) end
        speedBox.Text = tostring(BASE_SPEED); recalcSpeed()
    end)
    fastBox.FocusLost:Connect(function()
        local n = tonumber(fastBox.Text:match("[%d%.]+"))
        if n and not isnan(n) then FAST_MULT = math.clamp(n, 1, 1000) end
        fastBox.Text = tostring(FAST_MULT); recalcSpeed()
        if flyanim.updateMode then flyanim.updateMode(flyanim.mode) end
    end)
    turboBox.FocusLost:Connect(function()
        local n = tonumber(turboBox.Text:match("[%d%.]+"))
        if n and not isnan(n) then TURBO_MULT = math.clamp(n, 1, 1000) end
        turboBox.Text = tostring(TURBO_MULT); recalcSpeed()
        if flyanim.updateMode then flyanim.updateMode(flyanim.mode) end
    end)
    resetBtn.MouseButton1Click:Connect(function()
        BASE_SPEED = DEFAULT_BASE; FAST_MULT = DEFAULT_FAST; TURBO_MULT = DEFAULT_TURBO
        speedBox.Text = tostring(BASE_SPEED); fastBox.Text = tostring(FAST_MULT); turboBox.Text = tostring(TURBO_MULT)
        recalcSpeed()
        if flyanim.updateMode then flyanim.updateMode(flyanim.mode) end
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
        root.Size = UDim2.new(0, W, 0, h)
        TweenService:Create(panel, TW, {Size=UDim2.new(1,0,0,h)}):Play()
        TweenService:Create(dot, TweenInfo.new(0.2, Enum.EasingStyle.Quad),
            {BackgroundTransparency=state and 0 or 0.35}):Play()
        TweenService:Create(dot, TweenInfo.new(0.2, Enum.EasingStyle.Quad),
            {Size = state and UDim2.new(0,DOT_SIZE,0,DOT_SIZE) or UDim2.new(0,DOT_SIZE-3,0,DOT_SIZE-3),
             Position = state
                and UDim2.new(0.5,-DOT_SIZE/2,0.5,-DOT_SIZE/2)
                or  UDim2.new(0.5,-(DOT_SIZE-3)/2,0.5,-(DOT_SIZE-3)/2)}):Play()
        if state then
            startPulse()
        else
            if flyanim.pulse then pcall(function() task.cancel(flyanim.pulse) end); flyanim.pulse=nil; pulseRunning=false
                pcall(function() stroke.Thickness=1.2; stroke.Color=C_PURPLE; stroke.Transparency=0.75 end)
            end
        end
    end

    dotBtn.MouseButton1Click:Connect(function() setExpanded(not flyanim.expanded) end)

    local dragging      = false
    local dragStartMouse = Vector2.new()
    local dragStartPos  = UDim2.new()
    topBar.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
            dragging=true; dragStartMouse=Vector2.new(inp.Position.X,inp.Position.Y); dragStartPos=root.Position
        end
    end)
    topBar.InputEnded:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then dragging=false end
    end)
    if flyanim._dragInputConn then flyanim._dragInputConn:Disconnect(); flyanim._dragInputConn = nil end
    local dragInputConn
    dragInputConn = UserInputService.InputChanged:Connect(function(inp)
        if not dragging then return end
        if inp.UserInputType~=Enum.UserInputType.MouseMovement and inp.UserInputType~=Enum.UserInputType.Touch then return end
        local delta = Vector2.new(inp.Position.X, inp.Position.Y) - dragStartMouse
        root.Position = UDim2.new(dragStartPos.X.Scale, dragStartPos.X.Offset+delta.X, dragStartPos.Y.Scale, dragStartPos.Y.Offset+delta.Y)
    end)
    flyanim._dragInputConn = dragInputConn

    flyanim.updateLbl  = function(keyName) pcall(function() titleLbl.Text = FT.fly_title .. "  [" .. keyName .. "]" end) end
    flyanim.updateMode = function(modeName)
        pcall(function()
            local multF = math.floor(FAST_MULT*10+0.5)/10
            local multT = math.floor(TURBO_MULT*10+0.5)/10
            local modeTexts  = {
                normal = FT.mode_normal,
                fast   = FT.mode_fast  .. tostring(multF),
                turbo  = FT.mode_mega  .. tostring(multT),
                megaup = FT.mode_megaup.. tostring(multT),
            }
            local colors    = { normal=C_GREEN, fast=C_YELLOW, turbo=C_RED, megaup=C_CYAN }
            local dotColors = { normal=C_ACCENT, fast=C_YELLOW, turbo=C_RED, megaup=C_CYAN }
            modeLbl.Font           = Enum.Font.GothamBold
            modeLbl.Text           = modeTexts[modeName]  or modeName
            modeLbl.TextColor3     = colors[modeName]     or C_GREEN
            TweenService:Create(dot, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {BackgroundColor3=dotColors[modeName] or C_ACCENT}):Play()
        end)
    end

    -- (lock info GUI removed)

    
    if flyanim.updateMode then flyanim.updateMode(flyanim.mode) end
end

-- ──────────────────────────────────────────────────────────────────
-- [25] / [27]  FÍSICA DEL VUELO + _flyOn / _flyOff
-- ──────────────────────────────────────────────────────────────────
local function _flyOn()
    local char = lplr and lplr.Character; if not char then return end
    if shakeConn then pcall(function() shakeConn:Disconnect() end); shakeConn = nil end
    if flyanim.landConn then flyanim.landConn:Disconnect(); flyanim.landConn = nil end
    stopLandingWatcher()
    flyanim.waitingLand            = false
    flyanim.landingHeight          = nil
    flyanim.landingVelocity        = 0
    flyanim.landingVelocityCapture = 0
    flyanim.maxHeightAboveGround    = 0
    flyanim.heightWatchAccum        = 0
    _landAnimToken = _landAnimToken + 1
    if _landBaseRef    then pcall(function() _landBaseRef:Stop(0) end)    end
    if _landOverlayRef then pcall(function() _landOverlayRef:Stop(0) end) end
    _landBaseRef = nil; _landOverlayRef = nil
    heightTweenToken     = heightTweenToken + 1
    flyanim.sessionToken = (flyanim.sessionToken or 0) + 1
    flyanim.enabled      = true
    flyanim.mode         = "normal"
    getgenv().AFO_FLYMODE  = flyanim.mode
    getgenv().AFO_FLYSTATE = flyanim.enabled
    flyanim.speed        = BASE_SPEED
    flyanim.wDown=false; flyanim.sDown=false; flyanim.aDown=false; flyanim.dDown=false
    flyanim.isWDown=false; flyanim.isSDown=false; flyanim.isADown=false; flyanim.isDDown=false
    flyanim.isMoving=false; flyanim.megaTurboUpActive=false; flyanim.spaceHoldStart=nil
    flyanim.gyroProtectionActive=false; flyanim.turboPreImpulsoActivo=false
    flyanim.turboPreImpulsoToken=0; flyanim.c0ControlToken=0; flyanim.c0HeightToken=0
    flyanim.noclipSpaceActive=false; flyanim.lastKnownPos=nil
    flyanim.ragdollDetected=false
    flyanim.fKeyHeld=false; flyanim.blockCancelledByCombo=false
    if flyanim.gyroProtectionTimer then task.cancel(flyanim.gyroProtectionTimer) end
    if flyanim.backupGyro then pcall(function() flyanim.backupGyro:Destroy() end); flyanim.backupGyro=nil end
    flyanim.isBlocking=false; flyanim.isSpaceAdv=false; flyanim._normalPlayId=0
    flyanim.lastDamageTime=0; flyanim.mouseHeld=false; flyanim.comboAnimStartTime=0
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
        hum.PlatformStand = false
    end
    for _, t in pairs(flyanim.normalTracks) do pcall(function() if t and t.IsPlaying then t:Stop(0) end end) end
    flyanim.normalTracks = {}
    for _, t in pairs(flyanim.tracks) do pcall(function() if t and t.IsPlaying then t:Stop(0) end end) end
    flyanim.tracks = {}
    setupAnimator(char, flyanim.sessionToken)
    _flyMakeMotors()
    _flyBuildGui()
    startIdleWatcher()
    startComboListener()
    -- Diferir iniciarCicloNormal un frame para asegurar que el animator
    -- ya terminó de cargar todas las pistas (evita que "up" no lea la
    -- animación la primera vez que se activa el fly en una sesión).
    flyanim._normalPlayId = 1
    task.defer(function()
        if flyanim.enabled and flyanim.mode == "normal" then
            iniciarCicloNormal(flyanim._normalPlayId)
            task.delay(0.05, function()
                if flyanim.enabled and flyanim.mode == "normal" then
                    evaluarMovimientoNormal()
                end
            end)
        end
    end)
    startAntiImpulse()
    startMegaTurboUpListener()
    startAnomalyProtection()
    startAnimBlockLoop()
 
    if flyanim.tpMoveConn then flyanim.tpMoveConn:Disconnect(); flyanim.tpMoveConn = nil end
    local _tpMoveSession = flyanim.sessionToken
    flyanim.tpMoveConn = RunService.Stepped:Connect(function(_, dt)
        
        if not flyanim.enabled then flyanim.tpMoveConn:Disconnect(); flyanim.tpMoveConn = nil; return end
        if flyanim.sessionToken ~= _tpMoveSession then
            flyanim.tpMoveConn:Disconnect(); flyanim.tpMoveConn = nil; return
        end
        if not dt or isnan(dt) or dt <= 0 then return end
        local cc    = lplr and lplr.Character
        local root2 = cc and cc:FindFirstChild("HumanoidRootPart")
        if not root2 then return end
        local pos2 = root2.Position
        if not safepos(pos2) then return end
        if math.abs(pos2.Y) > COORD_SANITY_LIMIT or math.abs(pos2.X) > COORD_SANITY_LIMIT or math.abs(pos2.Z) > COORD_SANITY_LIMIT then return end
        local cam    = workspace.CurrentCamera
        if not cam then return end
        local typing = isTyping()
        local wD = not typing and UserInputService:IsKeyDown(Enum.KeyCode.W)
        local sD = not typing and UserInputService:IsKeyDown(Enum.KeyCode.S)
        local aD = not typing and UserInputService:IsKeyDown(Enum.KeyCode.A)
        local dD = not typing and UserInputService:IsKeyDown(Enum.KeyCode.D)
        local spaceDown = not typing and UserInputService:IsKeyDown(Enum.KeyCode.Space)
        local ctrlDown  = not typing and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
        if ctrlDown and flyanim.noclipCtrlEnabled and not flyanim.noclipCtrlActive then
            flyanim.noclipCtrlActive = true
            setNoclip(true)
        elseif not ctrlDown and flyanim.noclipCtrlActive then
            flyanim.noclipCtrlActive = false
            local megaActive = (flyanim.mode == "mega turbo") and flyanim.noclipMegaEnabled
            if not flyanim.noclipSpaceActive and not megaActive then setNoclip(false) end
        end
        local move = Vector3.new()
        if wD then move = move + cam.CFrame.LookVector end
        if sD then move = move - cam.CFrame.LookVector end
        if aD then move = move - cam.CFrame.RightVector end
        if dD then move = move + cam.CFrame.RightVector end
        if flyanim.megaTurboUpActive then move = move + Vector3.new(0, 2, 0)
        elseif spaceDown              then move = move + Vector3.new(0, 1, 0) end
        if ctrlDown then move = move - Vector3.new(0, 1, 0) end
        if spaceDown and not flyanim.megaTurboUpActive then fixUndergroundOrientation() end
        local actualSpeed = flyanim.speed
        if isnan(actualSpeed) or actualSpeed <= 0 then actualSpeed = BASE_SPEED end
        if flyanim.dashTimer > 0 then
            local dashMag = flyanim.dashVel.Magnitude
            if not isnan(dashMag) then actualSpeed = actualSpeed + dashMag end
        end
        if move.Magnitude > 0.01 then
            local translation = move.Unit * actualSpeed * dt
            if safepos(translation) then
                pcall(function() cc:TranslateBy(translation) end)
            end
        elseif flyanim.dashTimer > 0 and flyanim.dashVel.Magnitude > 0.1 then
            local translation = flyanim.dashVel.Unit * flyanim.dashVel.Magnitude * dt
            if safepos(translation) then
                pcall(function() cc:TranslateBy(translation) end)
            end
        end
    end)
 
    if flyanim.rsConn then flyanim.rsConn:Disconnect() end
    local _rsSession = flyanim.sessionToken
    flyanim.rsConn = RunService.RenderStepped:Connect(function(dt)
        
        if not flyanim.enabled then flyanim.rsConn:Disconnect(); flyanim.rsConn = nil; return end
        if flyanim.sessionToken ~= _rsSession then flyanim.rsConn:Disconnect(); flyanim.rsConn = nil; return end
        if not dt or isnan(dt) then return end
        local cc   = lplr and lplr.Character
        local root = cc and cc:FindFirstChild("HumanoidRootPart")
        local ch   = cc and cc:FindFirstChildOfClass("Humanoid")
        if not root or not ch then return end
        local pos = root.Position
        if not safepos(pos) then return end
        if math.abs(pos.Y) > COORD_SANITY_LIMIT or math.abs(pos.X) > COORD_SANITY_LIMIT or math.abs(pos.Z) > COORD_SANITY_LIMIT then return end

        -- ── WATCHDOG DE ALTURA (caída épica) ──────────────────────────────
        -- Watchdog de altura: corre cada 0.04s (doble frecuencia) para no perder
        -- picos de altura cuando el jugador baja rápido o hace dash vertical.
        flyanim.heightWatchAccum = (flyanim.heightWatchAccum or 0) + dt
        if flyanim.heightWatchAccum >= 0.04 then
            flyanim.heightWatchAccum = 0
            local rpH = RaycastParams.new()
            rpH.FilterType = Enum.RaycastFilterType.Exclude
            rpH.FilterDescendantsInstances = {cc}
            local rayH = workspace:Raycast(pos, Vector3.new(0, -3000, 0), rpH)
            local hAG
            if rayH then
                hAG = pos.Y - rayH.Position.Y
            else
                -- Sin suelo detectado (exterior/vacío): usar Y absoluta como estimado
                -- conservador. Si el jugador está a alturas positivas, esto registra
                -- al menos su elevación sobre Y=0.
                hAG = math.max(0, pos.Y)
            end
            if hAG and not isnan(hAG) and hAG > (flyanim.maxHeightAboveGround or 0) then
                flyanim.maxHeightAboveGround = hAG
            end
        end

        if not root:FindFirstChild("BodyGyro") or not root:FindFirstChild("BodyVelocity")
        or ch:GetState() == Enum.HumanoidStateType.Ragdoll then
            -- Guard doble: fly activo + mismo session + cooldown de 0.3s entre reconstrucciones
            local nowR = tick()
            if flyanim.enabled and flyanim.sessionToken == _rsSession
            and nowR - lastMotorRebuild > 0.3 then
                lastMotorRebuild = nowR
                _flyMakeMotors()
            end
            return
        end
        flyanim.bg = root:FindFirstChildOfClass("BodyGyro")
        flyanim.bv = root:FindFirstChildOfClass("BodyVelocity")
        flyanim.bf = root:FindFirstChildOfClass("BodyForce")
        updateAntiGravityForce()
        local angularSpeed = root.AssemblyAngularVelocity.Magnitude
        if not isnan(angularSpeed) and angularSpeed > 25 and not flyanim.gyroProtectionActive then
            activateGyroProtection()
        end
        local cam    = workspace.CurrentCamera
        if not cam then return end
        local typing = isTyping()
        local wD = not typing and UserInputService:IsKeyDown(Enum.KeyCode.W)
        local sD = not typing and UserInputService:IsKeyDown(Enum.KeyCode.S)
        local aD = not typing and UserInputService:IsKeyDown(Enum.KeyCode.A)
        local dD = not typing and UserInputService:IsKeyDown(Enum.KeyCode.D)
        flyanim.wDown=wD; flyanim.sDown=sD; flyanim.aDown=aD; flyanim.dDown=dD
        flyanim.isWDown=wD; flyanim.isSDown=sD; flyanim.isADown=aD; flyanim.isDDown=dD
        if flyanim.bv and flyanim.bv.Parent then flyanim.bv.velocity = Vector3.new(0, 0, 0) end
        if flyanim.bg and flyanim.bg.Parent then
            local move = Vector3.new()
            if wD then move = move + cam.CFrame.LookVector end
            if sD then move = move - cam.CFrame.LookVector end
            if aD then move = move - cam.CFrame.RightVector end
            if dD then move = move + cam.CFrame.RightVector end
            local targetCFrame
            local isFastMode2 = (flyanim.mode == "turbo" or flyanim.mode == "mega turbo")
            local isMegaUp    = (flyanim.mode == "mega up")
                if isMegaUp then
                    -- [FIX-3] Mega Up: mantener el personaje perfectamente vertical
                    -- Extraer sólo el yaw de la cámara para que gire con el jugador
                    -- pero sin inclinarse hacia adelante/atrás ni ladearse.
                    local camCF  = cam.CFrame
                    local _, ry, _ = camCF:ToOrientation()
                    if isnan(ry) then ry = 0 end
                    targetCFrame = CFrame.new(root.Position) * CFrame.Angles(0, ry, 0)
                elseif isFastMode2 and move.Magnitude > 0.01 then
                    targetCFrame = CFrame.lookAt(root.Position, root.Position + move.Unit)
                else
                    targetCFrame = cam.CFrame
                end
                local sf
                if isMegaUp then
                    -- [FIX-3] Lerp suave hacia posición vertical; no tan agresivo como fast
                    sf = math.clamp(dt * 6, 0, 0.5)
                elseif isFastMode2 then
                    local angleDiff = 0
                    pcall(function()
                        local currentLook = flyanim.bg.cframe.LookVector
                        local desiredLook = targetCFrame.LookVector
                        local dotV = math.clamp(currentLook:Dot(desiredLook), -1, 1)
                        angleDiff = math.acos(dotV)
                    end)
                    if isnan(angleDiff) then angleDiff = 0 end
                    local t_angle = math.clamp(1 - (angleDiff / math.pi), 0, 1)
                    sf = 0.04 + (t_angle * t_angle) * 0.14
                    sf = math.clamp(sf * (1 + dt * 8), 0, 0.20)
                else
                    sf = math.clamp(dt * 10, 0, 1)
                end
                flyanim.bg.cframe = flyanim.bg.cframe:Lerp(targetCFrame, sf)
        end
        if flyanim.dashTimer > 0 then
            flyanim.dashTimer = flyanim.dashTimer - dt
            if flyanim.dashTimer <= 0 then
                flyanim.dashTimer = 0; flyanim.dashVel = Vector3.new(0, 0, 0)
                if dashConnection then dashConnection:Disconnect(); dashConnection = nil end
            else
                flyanim.dashVel = flyanim.dashVel:Lerp(Vector3.new(0, 0, 0), math.clamp(dt * 6, 0, 1))
                if flyanim.dashVel.Magnitude < 0.5 then
                    flyanim.dashVel = Vector3.new(0, 0, 0)
                end
            end
        end
        local velY = root.AssemblyLinearVelocity.Y
        if isnan(velY) then
        elseif velY < -10 then
            local totalMag = root.AssemblyLinearVelocity.Magnitude
            if not isnan(totalMag) then
                flyanim.landingVelocity = math.abs(velY)
                local effectiveMag = math.max(math.abs(velY), totalMag)
                if effectiveMag > (flyanim.landingVelocityCapture or 0) then
                    flyanim.landingVelocityCapture = effectiveMag
                end
            end
        end
        updateAnimForMovement()
    end)
end
 


 
local _lastOmniActivation = 0
 
-- ──────────────────────────────────────────────────────────────────
-- [26]  ATERRIZAJE / LANDING WATCHER
-- ──────────────────────────────────────────────────────────────────
local function omniAntiBounceLand(hrp, hum)
    if not hrp or not hum then return end
    pcall(function()
        local v = hrp.AssemblyLinearVelocity
        if safepos(v) then
            hrp.AssemblyLinearVelocity  = Vector3.new(v.X, 0, v.Z)
        end
        hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
    end)
    pcall(function()
        local _, ry, _ = hrp.CFrame:ToOrientation()
        if isnan(ry) then ry = 0 end
        hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, ry, 0)
    end)
end
 
local _landingWatchConn  = nil
local _landingWatchToken = 0
 
stopLandingWatcher = function()
    _landingWatchToken = _landingWatchToken + 1
    if _landingWatchConn then
        _landingWatchConn:Disconnect()
        _landingWatchConn = nil
    end
end
 
startLandingWatcher = function(capturedChar)
    stopLandingWatcher()
    local myToken = _landingWatchToken
    local mySession = flyanim.sessionToken
 
    _landingWatchConn = RunService.Heartbeat:Connect(function()
        if flyanim.enabled then
            stopLandingWatcher()
            return
        end
        if not flyanim.waitingLand then
            stopLandingWatcher()
            return
        end
        if _landingWatchToken ~= myToken then return end
        if flyanim.sessionToken ~= mySession then stopLandingWatcher(); return end
 
        local char = capturedChar
        if not char or not char.Parent then stopLandingWatcher(); return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 or hum:GetState() == Enum.HumanoidStateType.Dead then
            stopLandingWatcher()
            return
        end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
 
        local velY = hrp.AssemblyLinearVelocity.Y
        if velY > -1 then return end
        local now2 = tick()
        if now2 - _lastOmniActivation < 0.15 then return end
        _lastOmniActivation = now2
 
        local probeDistance = math.clamp(math.abs(velY) * 0.10 + 1.5, 1.5, 4.5)
 
        local rp = RaycastParams.new()
        rp.FilterType = Enum.RaycastFilterType.Exclude
        rp.FilterDescendantsInstances = {char}
        local hit = workspace:Raycast(hrp.Position, Vector3.new(0, -probeDistance, 0), rp)
 
        if hit then
            stopLandingWatcher()
 
            pcall(function()
                for _, v in ipairs(hrp:GetChildren()) do
                    if v:IsA("BodyGyro") or v:IsA("BodyVelocity") or v:IsA("BodyForce")
                    or v:IsA("BodyAngularVelocity") or v:IsA("AlignOrientation")
                    or v:IsA("LinearVelocity") or v:IsA("AngularVelocity") then
                        v:Destroy()
                    end
                end
            end)
 
            local animScriptPre = char:FindFirstChild("Animate")
            if animScriptPre then
                pcall(function() animScriptPre.Disabled = true end)
                task.delay(0.25, function()
                    if not flyanim.waitingLand and animScriptPre and animScriptPre.Parent
                    and lplr.Character == char
                    and (not flyanim.animScript or flyanim.animScript ~= animScriptPre) then
                        pcall(function() animScriptPre.Disabled = false end)
                    end
                end)
            end
 
            setNoclip(false)
            omniAntiBounceLand(hrp, hum)
        end
    end)
end
 


 

local function findSafeGroundBelow(root, charCurrent)
    if not root then return nil end
    local rp = RaycastParams.new()
    rp.FilterType = Enum.RaycastFilterType.Exclude
    rp.FilterDescendantsInstances = {charCurrent}
 
    
    local offsets = {
        Vector3.new(0,   0,  0),
        Vector3.new(1.5, 0,  0), Vector3.new(-1.5, 0, 0),
        Vector3.new(0,   0,  1.5), Vector3.new(0,   0, -1.5),
        Vector3.new(1.0, 0,  1.0), Vector3.new(-1.0,0,  1.0),
        Vector3.new(1.0, 0, -1.0), Vector3.new(-1.0,0, -1.0),
    }
    local bestY       = nil
    local bestNormal  = Vector3.new(0, 1, 0)
    for _, off in ipairs(offsets) do
        local origin = root.Position + off
        local result = workspace:Raycast(origin, Vector3.new(0, -3000, 0), rp)
        if result then
            local hitY = result.Position.Y
            
            if result.Normal.Y > 0.5 then
                if bestY == nil or hitY > bestY then
                    bestY      = hitY
                    bestNormal = result.Normal
                end
            end
        end
    end
    if bestY == nil then return nil end
    
    return Vector3.new(root.Position.X, bestY + 3, root.Position.Z), bestNormal
end
 
local function _flyOff()
    
    if not flyanim.enabled then return end

    -- Desactivar fly INMEDIATAMENTE para que todos los loops activos
    -- (rsConn, tpMoveConn, antiImpulse, anomaly, etc.) se detengan en
    -- su próxima iteración sin recrear motores ni ejecutar lógica de vuelo.
    flyanim.enabled = false

    local charCurrent = lplr and lplr.Character
    _lastOmniActivation = tick()
 
    
    local _preCaptureVelocity = math.max(flyanim.landingVelocity or 0, flyanim.landingVelocityCapture or 0)
 
    if flyanim.gyroProtectionTimer then
        task.cancel(flyanim.gyroProtectionTimer)
        flyanim.gyroProtectionTimer = nil
    end
    if flyanim.backupGyro then
        pcall(function() flyanim.backupGyro:Destroy() end)
        flyanim.backupGyro = nil
    end
    flyanim.gyroProtectionActive = false
 
    flyanim.sessionToken          = (flyanim.sessionToken          or 0) + 1
    flyanim.turboPreImpulsoToken  = (flyanim.turboPreImpulsoToken  or 0) + 1
    flyanim.turboPreImpulsoActivo = false
    flyanim.idleWatchToken        = (flyanim.idleWatchToken        or 0) + 1
    flyanim.dashAnimToken         = (flyanim.dashAnimToken         or 0) + 1
    flyanim.comboToken            = (flyanim.comboToken            or 0) + 1
    flyanim.c0ControlToken        = (flyanim.c0ControlToken        or 0) + 1
    flyanim.c0HeightToken         = (flyanim.c0HeightToken         or 0) + 1
    heightTweenToken              = heightTweenToken + 1
 
    flyanim.lastKnownPos          = nil
 
    
    if flyanim.turboRenderConn     then flyanim.turboRenderConn:Disconnect();     flyanim.turboRenderConn     = nil end
    if flyanim.megaRenderConn      then flyanim.megaRenderConn:Disconnect();      flyanim.megaRenderConn      = nil end
    if flyanim.c0HeightConn        then flyanim.c0HeightConn:Disconnect();        flyanim.c0HeightConn        = nil end
    if flyanim.animBlockRenderConn then flyanim.animBlockRenderConn:Disconnect(); flyanim.animBlockRenderConn = nil end
    if flyanim.comboC0Conn         then flyanim.comboC0Conn:Disconnect();         flyanim.comboC0Conn         = nil end
    if flyanim.blockRenderConn     then flyanim.blockRenderConn:Disconnect();     flyanim.blockRenderConn     = nil end
    if flyanim.idleAnimConn        then flyanim.idleAnimConn:Disconnect();        flyanim.idleAnimConn        = nil end
    if flyanim.megaTurboUpConn     then flyanim.megaTurboUpConn:Disconnect();     flyanim.megaTurboUpConn     = nil end
    if flyanim.antiImpulseConn     then flyanim.antiImpulseConn:Disconnect();     flyanim.antiImpulseConn     = nil end
    if flyanim.anomalyConn         then flyanim.anomalyConn:Disconnect();         flyanim.anomalyConn         = nil end
    if flyanim.rsConn              then flyanim.rsConn:Disconnect();              flyanim.rsConn              = nil end
    if flyanim.tpMoveConn          then flyanim.tpMoveConn:Disconnect();          flyanim.tpMoveConn          = nil end
    -- Matar el loop de MegaUp (Heartbeat independiente)
    MegaUpLogic.Deactivate()
    flyanim.megaTurboUpActive = false
 
    do
        local _earlyRoot = charCurrent and charCurrent:FindFirstChild("HumanoidRootPart")
        if _earlyRoot then cleanupMotors(_earlyRoot, true) end
        flyanim.bg = nil; flyanim.bv = nil; flyanim.bf = nil
    end
    -- Segunda limpieza diferida: por si algún motor fue recreado en el mismo frame
    -- antes de que las conexiones terminaran de apagarse
    do
        local _capturedChar = charCurrent
        task.defer(function()
            if flyanim.enabled then return end  -- fly se reactivó, no limpiar
            local _r = _capturedChar and _capturedChar:FindFirstChild("HumanoidRootPart")
            if not _r then return end
            for _, v in ipairs(_r:GetChildren()) do
                if v:IsA("BodyGyro") or v:IsA("BodyVelocity") or v:IsA("BodyForce")
                or v:IsA("BodyAngularVelocity") or v:IsA("AlignOrientation") or v:IsA("LinearVelocity") then
                    pcall(function() v:Destroy() end)
                end
            end
            flyanim.bg = nil; flyanim.bv = nil; flyanim.bf = nil
        end)
    end
 
    if flyanim.damageConn          then flyanim.damageConn:Disconnect();          flyanim.damageConn          = nil end
    if flyanim.animConn            then flyanim.animConn:Disconnect();            flyanim.animConn            = nil end
    if flyanim.comboConn           then flyanim.comboConn:Disconnect();           flyanim.comboConn           = nil end
    if flyanim.comboHoldConn       then flyanim.comboHoldConn:Disconnect();       flyanim.comboHoldConn       = nil end
    if flyanim._comboEndConn       then flyanim._comboEndConn:Disconnect();       flyanim._comboEndConn       = nil end
    if dashConnection              then dashConnection:Disconnect();              dashConnection              = nil end
    if flyanim.idleTimer           then task.cancel(flyanim.idleTimer);           flyanim.idleTimer           = nil end
    if flyanim.spaceHoldTimerAdv   then task.cancel(flyanim.spaceHoldTimerAdv);   flyanim.spaceHoldTimerAdv   = nil end
    if flyanim.gyroProtectionTimer then task.cancel(flyanim.gyroProtectionTimer); flyanim.gyroProtectionTimer = nil end
 
    clearC0Desired()
    detenerWatchdogAltura()
    if flyanim.rootJoint and flyanim.originalC0 then
        pcall(function() flyanim.rootJoint.C0 = flyanim.originalC0 end)
    end
 
    
    local heightFromGround = 0
    local rootCurrent      = charCurrent and charCurrent:FindFirstChild("HumanoidRootPart")
 
    if rootCurrent then
        local rp = RaycastParams.new()
        rp.FilterType = Enum.RaycastFilterType.Exclude
        rp.FilterDescendantsInstances = {charCurrent}
        local rayResult = workspace:Raycast(rootCurrent.Position, Vector3.new(0, -3000, 0), rp)
        if rayResult then
            heightFromGround = rootCurrent.Position.Y - rayResult.Position.Y
        else
            heightFromGround = 999
        end
    end
    -- Si en algún momento durante el vuelo (incluyendo TPs como el del
    -- sistema de lock) la altura sobre el suelo superó los 45 studs,
    -- el watchdog de altura lo registró en maxHeightAboveGround.
    -- Usamos el MAX entre la altura medida ahora y la máxima registrada
    -- para garantizar que la caída épica se dispare siempre que corresponda.
    local maxRecordedHeight = flyanim.maxHeightAboveGround or 0
    if maxRecordedHeight > heightFromGround then
        heightFromGround = maxRecordedHeight
    end
    flyanim.landingHeight = heightFromGround
    flyanim.maxHeightAboveGround = 0
 
    
    
    local isEpicFallByFlyOff = false
    if rootCurrent and heightFromGround > 45 then
        local safeGroundPos = findSafeGroundBelow(rootCurrent, charCurrent)
        if safeGroundPos then
            -- Limpieza SINCRONA de motores ANTES del TP para que no quede
            -- ningún BodyForce activo que empuje al personaje hacia arriba
            -- después de ser teletransportado (ese era el bug del "vuelve arriba").
            pcall(function()
                for _, v in ipairs(rootCurrent:GetChildren()) do
                    if v:IsA("BodyGyro") or v:IsA("BodyVelocity") or v:IsA("BodyForce")
                    or v:IsA("BodyAngularVelocity") or v:IsA("AlignOrientation")
                    or v:IsA("LinearVelocity") then
                        v:Destroy()
                    end
                end
            end)
            flyanim.bg = nil; flyanim.bv = nil; flyanim.bf = nil

            pcall(function()
                local _, ry, _ = rootCurrent.CFrame:ToOrientation()
                if isnan(ry) then ry = 0 end
                rootCurrent.CFrame = CFrame.new(safeGroundPos) * CFrame.Angles(0, ry, 0)
                rootCurrent.AssemblyLinearVelocity  = Vector3.new(0, 0, 0)
                rootCurrent.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            end)
            -- Segunda pasada de velocidad cero: por si Roblox la reinició en el mismo frame
            task.defer(function()
                if flyanim.enabled then return end
                if not rootCurrent or not rootCurrent.Parent then return end
                pcall(function()
                    rootCurrent.AssemblyLinearVelocity  = Vector3.new(0, 0, 0)
                    rootCurrent.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                end)
            end)

            flyanim.landingHeight = heightFromGround
            isEpicFallByFlyOff   = true
        end
    end
 
    
    -- flyanim.enabled ya fue puesto a false al inicio de _flyOff
    flyanim.dashTimer = 0
    flyanim.dashVel   = Vector3.new(0, 0, 0)
 
    flyanim.megaTurboUpActive     = false
    flyanim.spaceHoldStart        = nil
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
 
    detenerNormalTracks(0)
    detenerPoseTurbo()
    detenerPoseMega()
    detenerEspacioAvanzado()
    stopBlocking()
    stopParticleEmitter()
    stopAntiImpulse()
    stopMegaTurboUpListener()
    _megaUp_killParticles()    -- limpieza partículas mega up
    stopAnomalyProtection()
    stopComboC0Lock()
    stopAnimBlockLoop()
    stopComboListener()
    setNoclip(false)
 
    if shakeConn then pcall(function() shakeConn:Disconnect() end); shakeConn=nil end
    destroyWhiteFlash()
    local cam = workspace.CurrentCamera
    if cam then cam.FieldOfView = 70 end
 
    for _, t in pairs(flyanim.tracks)       do pcall(function() if t and t.IsPlaying then t:Stop(0.05) end end) end
    for _, t in pairs(flyanim.normalTracks) do pcall(function() if t and t.IsPlaying then t:Stop(0.05) end end) end
 
    local hum = charCurrent and charCurrent:FindFirstChildOfClass("Humanoid")
 
    flyanim.mode  = "normal"
    getgenv().AFO_FLYMODE  = flyanim.mode
    getgenv().AFO_FLYSTATE = flyanim.enabled
    flyanim.speed = BASE_SPEED
    _flyDestroyGui()
 
    if not charCurrent or not hum or hum.Health <= 0 then
        local animScript2 = charCurrent and charCurrent:FindFirstChild("Animate") or flyanim.animScript
        if animScript2 then animScript2.Disabled = false; flyanim.animScript = nil end
        flyanim.animScript          = nil
        flyanim.landingHeight       = nil
        flyanim.landingVelocity     = 0
        flyanim.landingVelocityCapture = 0
        return
    end
 
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
        local _, ry, _ = rootCurrent.CFrame:ToOrientation()
        pcall(function()
            rootCurrent.CFrame = CFrame.new(rootCurrent.Position) * CFrame.Angles(0, ry, 0)
            rootCurrent.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            if not isEpicFallByFlyOff then
                
                local velY = rootCurrent.AssemblyLinearVelocity.Y
                rootCurrent.AssemblyLinearVelocity = Vector3.new(0, velY, 0)
            end
        end)
    end

    
    
    hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
    hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
    hum:SetStateEnabled(Enum.HumanoidStateType.StrafingNoPhysics, true)
 
    
    
    if isEpicFallByFlyOff and rootCurrent then
        -- El personaje ya fue teleportado al suelo con velocidad cero.
        -- NO se usa anti-gravedad: ese BodyForce hacía que flotara 0.28s
        -- y luego cayera de nuevo (el "me devuelve arriba"). Simplemente
        -- forzamos el estado Landed para que el humanoid se asiente.
        pcall(function() hum:ChangeState(Enum.HumanoidStateType.Landed) end)
    else
        hum:ChangeState(Enum.HumanoidStateType.Freefall)
    end
 
    
 
    
    if rootCurrent and not isEpicFallByFlyOff then
        task.delay(0.01, function()
            if not rootCurrent or not rootCurrent.Parent then return end
            if flyanim.enabled then return end
            local velY = rootCurrent.AssemblyLinearVelocity.Y
            if velY > 0.5 then
                local rp2 = RaycastParams.new()
                rp2.FilterType = Enum.RaycastFilterType.Exclude
                rp2.FilterDescendantsInstances = {charCurrent}
                local kickRay = workspace:Raycast(rootCurrent.Position, Vector3.new(0, -5, 0), rp2)
                if not kickRay then
                    pcall(function()
                        rootCurrent.AssemblyLinearVelocity = Vector3.new(0, -4, 0)
                    end)
                end
            end
        end)
    end
 
    local capturedHeight   = flyanim.landingHeight
    local capturedVelocity = _preCaptureVelocity
 
    
    if capturedHeight < 45 then
        local animScript3 = charCurrent and charCurrent:FindFirstChild("Animate") or flyanim.animScript
        if animScript3 then animScript3.Disabled = false; flyanim.animScript = nil end
        if hum then
            hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
            hum.PlatformStand = false
            pcall(function() hum:ChangeState(Enum.HumanoidStateType.Running) end)
        end
        flyanim.landingHeight          = nil
        flyanim.landingVelocity        = 0
        flyanim.landingVelocityCapture = 0
        return
    end
 
    do
        local animScriptEarly = charCurrent and charCurrent:FindFirstChild("Animate") or flyanim.animScript
        if animScriptEarly then
            animScriptEarly.Disabled = false
            flyanim.animScript = animScriptEarly
        end
    end
 
    
    if isEpicFallByFlyOff then
        
        
        flyanim.evalToken  = (flyanim.evalToken or 0) + 1
        flyanim.isWDown    = false; flyanim.isSDown = false
        flyanim.isADown    = false; flyanim.isDDown = false
        flyanim.wDown      = false; flyanim.sDown   = false
        flyanim.aDown      = false; flyanim.dDown   = false
        flyanim.waitingLand = false
 
        flyanim.landingHeight          = capturedHeight
        flyanim.landingVelocity        = capturedVelocity
        flyanim.landingVelocityCapture = capturedVelocity
 
        
        
        task.delay(0.05, function()
            if not charCurrent or not charCurrent.Parent then return end
            doLanding(charCurrent)  
        end)
        return
    end
 
    
    flyanim.waitingLand = true
    if flyanim.landConn then flyanim.landConn:Disconnect() end
    startLandingWatcher(charCurrent)
 
    local function finalizarAterrizaje(newState)
        if not flyanim.waitingLand then return end
 
        if flyanim.landConn then flyanim.landConn:Disconnect(); flyanim.landConn=nil end
 
        if lplr.Character ~= charCurrent then
            flyanim.waitingLand = false
            local animSc = charCurrent and charCurrent:FindFirstChild("Animate")
            flyanim.animScript = nil
            if animSc then pcall(function() animSc.Disabled = false end) end
            flyanim.landingHeight = nil
            return
        end
 
        flyanim.waitingLand = false
        if newState ~= Enum.HumanoidStateType.Dead then
            flyanim.landingHeight          = capturedHeight
            flyanim.landingVelocity        = capturedVelocity
            flyanim.landingVelocityCapture = capturedVelocity
            
            doLanding(charCurrent)
        else
            local animSc = charCurrent and charCurrent:FindFirstChild("Animate") or flyanim.animScript
            flyanim.animScript = nil
            if animSc then pcall(function() animSc.Disabled = false end) end
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
 
    task.delay(10, function()
        if not flyanim.waitingLand then return end
        _landAnimToken      = _landAnimToken + 1
        flyanim.waitingLand = false
        if flyanim.landConn then flyanim.landConn:Disconnect(); flyanim.landConn=nil end
 
        flyanim.animScript = nil
        local animSc = charCurrent and charCurrent:FindFirstChild("Animate") or flyanim.animScript
        if animSc then pcall(function() animSc.Disabled = false end) end
 
        if hum and hum.Parent then
            hum.PlatformStand = false
            pcall(function() hum:ChangeState(Enum.HumanoidStateType.Running) end)
        end
        flyanim.landingHeight = nil
    end)
end
 


-- ──────────────────────────────────────────────────────────────────
-- [28]  INPUT / DASH / MODO TRANSICIONES  (Q, F, Space, WASD)
-- ──────────────────────────────────────────────────────────────────
local function triggerDash(direction, speed, duration)
    local cam = workspace.CurrentCamera
    local dashDir
    if direction == "back"    then local l = cam.CFrame.LookVector;  dashDir = Vector3.new(-l.X, 0, -l.Z)
    elseif direction == "left"  then local r = cam.CFrame.RightVector; dashDir = Vector3.new(-r.X, 0, -r.Z)
    elseif direction == "right" then local r = cam.CFrame.RightVector; dashDir = Vector3.new( r.X, 0,  r.Z)
    elseif direction == "forward" then local l = cam.CFrame.LookVector; dashDir = Vector3.new( l.X, 0,  l.Z) end
    if not dashDir or dashDir.Magnitude < 0.01 then return end
    flyanim.dashVel   = dashDir.Unit * (speed or flyanim.DASH_SPEED)
    flyanim.dashTimer = duration or flyanim.DASH_DURATION
    startDashCollisionDetection()
end

local function activateMegaTurbo()
    if flyanim.mode ~= "turbo" then return end
    flyanim.mode  = "mega turbo"
    getgenv().AFO_FLYMODE  = flyanim.mode
    getgenv().AFO_FLYSTATE = flyanim.enabled
    flyanim.speed = BASE_SPEED * TURBO_MULT
    if flyanim.updateMode then flyanim.updateMode("mega turbo") end
    if flyanim.noclipMegaEnabled then setNoclip(true) end
    shakeCamera(3.5, 0.4)
    playLocalSound(SFX_MEGA_TURBO, 0.88)
    sonicBoomEffect(2); airShockAura(2); speedWhiteFlash("mega turbo")
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

    
    
    if flyanim.mode == "turbo" then
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

        flyanim.mode  = "turbo"
        getgenv().AFO_FLYMODE  = flyanim.mode
        getgenv().AFO_FLYSTATE = flyanim.enabled
        flyanim.speed = BASE_SPEED * FAST_MULT
        flyanim.qLastPress       = tick()
        flyanim.turboActivatedAt = tick()
        if flyanim.updateMode then flyanim.updateMode("turbo") end
        setNoclip(false)
        shakeCamera(2.0, 0.3)
        playLocalSound(SFX_TURBO, 0.82)
        sonicBoomEffect(1); airShockAura(1); speedWhiteFlash("turbo")
        triggerDash("forward", flyanim.TURBO_DASH_SPEED, flyanim.TURBO_DASH_DURATION)
        startParticleEmitter()
        detenerNormalTracks(0.1); detenerEspacioAvanzado()
        iniciarPoseTurbo()
    end
end
 
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
        local wasEnabled = flyanim.enabled
        flyanim.enabled    = false
        flyanim.animator   = nil
        flyanim.rootJoint  = nil
        flyanim.originalC0 = nil
 
        if shakeConn then pcall(function() shakeConn:Disconnect() end); shakeConn=nil end
        destroyWhiteFlash()
        local cam = workspace.CurrentCamera
        if cam then cam.FieldOfView=70 end
 
        stopLandingWatcher()
        flyanim.mode="normal"
        getgenv().AFO_FLYMODE  = flyanim.mode
        getgenv().AFO_FLYSTATE = flyanim.enabled
        flyanim.speed=BASE_SPEED; flyanim.isMoving=false
        flyanim.wDown=false; flyanim.sDown=false; flyanim.aDown=false; flyanim.dDown=false
        flyanim.isWDown=false; flyanim.isSDown=false; flyanim.isADown=false; flyanim.isDDown=false
 
        flyanim.waitingLand=false
        flyanim.landingHeight=nil; flyanim.landingVelocity=0
        flyanim.landingVelocityCapture=0
        flyanim.maxHeightAboveGround=0; flyanim.heightWatchAccum=0
        flyanim.megaTurboUpActive=false
        flyanim.spaceHoldStart=nil
 
        flyanim.isBlocking=false; flyanim.isSpaceAdv=false; flyanim._normalPlayId=0
        flyanim.turboPreImpulsoActivo=false; flyanim.turboPreImpulsoToken=0
        flyanim.comboPlaying=false; flyanim.comboBusy=false; flyanim.combo4Frozen=false; flyanim.comboToken=0
 
        flyanim.idleWatchToken     = (flyanim.idleWatchToken or 0) + 1
        flyanim.c0ControlToken     = 0
        flyanim.c0HeightToken      = 0
        flyanim.lastDamageTime     = 0
        flyanim.noclipSpaceActive  = false
        flyanim.noclipCtrlActive   = false
        flyanim.mouseHeld          = false
        flyanim.lastKnownPos       = nil
        flyanim.ragdollDetected    = false
        flyanim.fKeyHeld           = false
        flyanim.blockCancelledByCombo = false
        flyanim.comboAnimStartTime = 0
 
        if flyanim.idleAnimConn then flyanim.idleAnimConn:Disconnect(); flyanim.idleAnimConn=nil end
        flyanim.lateralKilled=true; flyanim.atrasKilled=true
        if flyanim.spaceHoldTimerAdv then task.cancel(flyanim.spaceHoldTimerAdv); flyanim.spaceHoldTimerAdv=nil end
        flyanim.espacioTrackActivo=nil
        flyanim.dashAnimToken  = (flyanim.dashAnimToken or 0) + 1
        c0DesiredCFrame        = nil
        heightTweenToken       = heightTweenToken + 1
        flyanim.sessionToken   = (flyanim.sessionToken or 0) + 1
        _landAnimToken         = _landAnimToken + 1
        _landBaseRef = nil; _landOverlayRef = nil
 
        stopParticleEmitter(); stopAntiImpulse()
        stopMegaTurboUpListener()
        stopAnomalyProtection(); stopComboC0Lock()
        stopAnimBlockLoop()
        detenerWatchdogAltura()
 
        if flyanim.turboRenderConn     then flyanim.turboRenderConn:Disconnect();     flyanim.turboRenderConn     = nil end
        if flyanim.megaRenderConn      then flyanim.megaRenderConn:Disconnect();      flyanim.megaRenderConn      = nil end
        if flyanim.blockRenderConn     then flyanim.blockRenderConn:Disconnect();     flyanim.blockRenderConn     = nil end
        if flyanim.landConn            then flyanim.landConn:Disconnect();            flyanim.landConn            = nil end
        if dashConnection              then dashConnection:Disconnect();              dashConnection              = nil end
        if flyanim.rsConn              then flyanim.rsConn:Disconnect();              flyanim.rsConn              = nil end
        if flyanim.tpMoveConn          then flyanim.tpMoveConn:Disconnect();          flyanim.tpMoveConn          = nil end
        if flyanim.idleTimer           then task.cancel(flyanim.idleTimer);           flyanim.idleTimer           = nil end
        if flyanim.damageConn          then flyanim.damageConn:Disconnect();          flyanim.damageConn          = nil end
        if flyanim.anomalyConn         then flyanim.anomalyConn:Disconnect();         flyanim.anomalyConn         = nil end
        if flyanim.animBlockRenderConn then flyanim.animBlockRenderConn:Disconnect(); flyanim.animBlockRenderConn = nil end
        if flyanim.c0HeightConn        then flyanim.c0HeightConn:Disconnect();        flyanim.c0HeightConn        = nil end
 
        stopComboListener()
        for _, t in pairs(flyanim.tracks)       do pcall(function() if t and t.IsPlaying then t:Stop(0) end end) end
        for _, t in pairs(flyanim.normalTracks) do pcall(function() if t and t.IsPlaying then t:Stop(0) end end) end
        flyanim.tracks={}; flyanim.normalTracks={}
 
        flyanim.animScript = nil
        if flyanim.animConn then flyanim.animConn:Disconnect(); flyanim.animConn=nil end
 
        _flyDestroyGui()
 
        if wasEnabled then
            task.wait(0.5)
            if newChar and newChar.Parent and not flyanim.enabled then
                _flyOn()
            end
        end
    end)
end
 
local function _disconnectGlobal()
    if _inputConn     then _inputConn:Disconnect();     _inputConn     = nil end
    if _inputConn_End then _inputConn_End:Disconnect(); _inputConn_End = nil end
    if _charConn      then _charConn:Disconnect();      _charConn      = nil end
end
 

-- ──────────────────────────────────────────────────────────────────
-- [29]  API PÚBLICA
-- ──────────────────────────────────────────────────────────────────
local M = {}

function M.Start(lplrRef, flyKey)
    lplr   = lplrRef or Players.LocalPlayer
    camera = workspace.CurrentCamera
    if flyKey then flyanim.flyKey = flyKey end
    _reloadFT()
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
    if _inputConn     then _inputConn:Disconnect();     _inputConn     = nil end
    if _inputConn_End then _inputConn_End:Disconnect(); _inputConn_End = nil end
    _connectGlobal()
end

function M.GetFlyKey()  return flyanim.flyKey  end

-- Estado actual: true = volando, false = apagado
function M.IsEnabled()
    return flyanim.enabled == true
end

-- Modo de vuelo actual:
--   "normal"     → vuelo base
--   "turbo"      → antes: fast    (Q una vez)
--   "mega turbo" → antes: turbo   (Q dos veces)
--   "mega up"    → antes: megaup  (Space sostenido)
-- Devuelve nil si el vuelo está apagado.
function M.GetMode()
    if not flyanim.enabled then return nil end
    return flyanim.mode
end

return M
