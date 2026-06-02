-- ============================================================
-- FLY MODULE v1.0  |  Escrito desde cero
-- Uso: M.Start(lplrRef)  /  M.Stop()  /  M.Toggle(bool)
-- ============================================================

local RunService      = game:GetService("RunService")
local UserInputService= game:GetService("UserInputService")
local Players         = game:GetService("Players")
local TweenService    = game:GetService("TweenService")
local SoundService    = game:GetService("SoundService")
local CoreGui         = game:GetService("CoreGui")

-- ============================================================
-- CONSTANTES
-- ============================================================
local BASE_SPEED   = 60
local FAST_MULT    = 3.0
local TURBO_MULT   = 6.0

local COORD_LIMIT  = 50000   -- posición absurda (no volar si la supera)
local TP_THRESHOLD = 100     -- salto de posición considerado TP externo (studs)

local ANIM = {
    idle          = "rbxassetid://107048806104233",
    forward       = "rbxassetid://101776150450756",
    back          = "rbxassetid://92646687237670",
    right         = "rbxassetid://113592486960274",
    left          = "rbxassetid://133459589582592",
    estatica      = "rbxassetid://97171309",
    levitacion    = "rbxassetid://313762630",
    brazos_idle   = "rbxassetid://159223413",
    mov_forward   = "rbxassetid://46196309",
    mov_back_anim = "rbxassetid://60882887",
    mov_brazos_mov= "rbxassetid://233077885",
    mov_lateral   = "rbxassetid://204328711",
    espacio_prim  = "rbxassetid://259440107",
    espacio_sec   = "rbxassetid://94861246",
    turbo_compact = "rbxassetid://180612465",
    turbo_burst   = "rbxassetid://129423030",
    turbo_pose    = "rbxassetid://233322916",
    turbo_enter   = "rbxassetid://116114386574305",
    turbo_loop    = "rbxassetid://126091881048662",
    turbo_idle    = "rbxassetid://107048806104233",
    mega_pose     = "rbxassetid://282574440",
    mega_base     = "rbxassetid://180435571",
    mega_volado   = "rbxassetid://313762630",
    combo1        = "rbxassetid://204062532",
    combo2a       = "rbxassetid://218504594",
    combo2b       = "rbxassetid://218504594",
    combo3a       = "rbxassetid://204062532",
    combo3b       = "rbxassetid://218504594",
    combo4        = "rbxassetid://2954124238",
    combo4_space  = "rbxassetid://45828430",
    sq_anim       = "rbxassetid://82718659527221",
    dq_anim       = "rbxassetid://93831708296422",
    bloqueo       = "rbxassetid://107456513",
}

local SFX = {
    turbo   = "rbxassetid://137455842313478",
    mega    = "rbxassetid://111391583223900",
    landing = "rbxassetid://135226467234227",
}

local COMBO_DURATIONS = { 0.47, 0.47, 0.53, 0.68 }
local COMBO_WINDOW    = 1.0    -- tiempo máximo para dar el siguiente golpe

-- ============================================================
-- ESTADO CENTRAL  (una sola tabla, sin herencia de sesiones)
-- ============================================================
local S = {
    -- Core
    on          = false,
    session     = 0,        -- token que invalida callbacks de sesiones anteriores
    mode        = "normal", -- "normal" | "fast" | "turbo"
    speed       = BASE_SPEED,

    -- Physics
    bg = nil, bv = nil, bf = nil,

    -- Personaje
    animator    = nil,
    animScript  = nil,
    rootJoint   = nil,
    origC0      = nil,

    -- Animaciones cargadas
    tracks      = {},   -- id → AnimationTrack (combate/especiales)
    nt          = {},   -- nombre → AnimationTrack (vuelo normal)

    -- Movimiento
    wDown=false, sDown=false, aDown=false, dDown=false,
    dashVel   = Vector3.new(0,0,0),
    dashTimer = 0,
    DASH_SPEED        = 297,
    DASH_DURATION     = 0.38,
    SIDE_DASH_SPEED   = 297 * 1.35,
    TURBO_DASH_SPEED  = 405,
    TURBO_DASH_DUR    = 0.45,
    BACK_DASH_SPEED   = 594,

    -- Noclip
    noclipCtrl    = false,
    noclipSpace   = false,

    -- Lock
    lockOn        = false,
    lockTarget    = nil,
    lockHighlight = nil,
    lockIcon      = nil,
    LOCK_SMOOTH   = 0.8,
    BRAKE_DIST    = 35,
    BRAKE_HARD    = 14,

    -- Combo
    comboStep   = 0,
    comboToken  = 0,
    comboBusy   = false,
    comboPlay   = false,
    combo2Last  = nil,
    mouseHeld   = false,

    -- Bloqueo
    blocking    = false,
    blockCancelledByCombo = false,
    fKeyHeld    = false,
    lastDmg     = 0,
    BLOCK_CD    = 0.75,

    -- Space/MegaUp
    spaceHoldStart = nil,
    SPACE_HOLD     = 2,
    megaUp         = false,

    -- Idle anim
    idleTimer  = 0,
    brazosOn   = false,
    IDLE_WAIT  = 2,

    -- Anti-TP externo
    lastPos    = nil,   -- posición del frame anterior (para detectar TP externo)
    tpGrace    = 0,     -- tick() hasta el cual ignorar antiImpulse

    -- Void guard
    safePos    = nil,

    -- GUI
    gui        = nil,
    updateMode = nil,
    updateLbl  = nil,

    -- Conexiones (todas en una tabla para desconectar fácil)
    conns      = {},
}

-- ============================================================
-- HELPERS
-- ============================================================
local lplr   = nil
local camera = nil

local function char()   return lplr and lplr.Character end
local function root()   local c = char(); return c and c:FindFirstChild("HumanoidRootPart") end
local function hum()    local c = char(); return c and c:FindFirstChildOfClass("Humanoid") end

local function isTyping()
    local focus = UserInputService:GetFocusedTextBox()
    return focus ~= nil
end

local function playSound(id, vol)
    local s = Instance.new("Sound")
    s.SoundId = id; s.Volume = vol or 0.85
    s.RollOffMaxDistance = 0; s.Parent = SoundService
    s:Play()
    s.Ended:Connect(function() pcall(function() s:Destroy() end) end)
    task.delay(10, function() pcall(function() s:Destroy() end) end)
end

local function setNoclip(state)
    local c = char(); if not c then return end
    for _, p in ipairs(c:GetDescendants()) do
        if p:IsA("BasePart") then p.CanCollide = not state end
    end
end

-- Desconectar y limpiar todas las conexiones de sesión
local function disconnectAll()
    for k, conn in pairs(S.conns) do
        pcall(function() conn:Disconnect() end)
        S.conns[k] = nil
    end
end

local function addConn(name, conn)
    if S.conns[name] then pcall(function() S.conns[name]:Disconnect() end) end
    S.conns[name] = conn
end

-- ============================================================
-- MOTORES DE FÍSICA
-- Única función que crea BodyGyro/BodyVelocity/BodyForce.
-- No hay "silentReset" ni "anomalyProtection" — si los motores
-- desaparecen, el loop rsConn los recrea la siguiente vuelta.
-- ============================================================
local function makeMotors()
    local r = root(); local h = hum()
    if not r or not h then return end
    -- Limpiar motores anteriores
    for _, v in ipairs(r:GetChildren()) do
        if v:IsA("BodyGyro") or v:IsA("BodyVelocity") or v:IsA("BodyForce")
        or v:IsA("BodyAngularVelocity") or v:IsA("AlignOrientation")
        or v:IsA("LinearVelocity") or v:IsA("BodyPosition") then
            pcall(function() v:Destroy() end)
        end
    end
    r.AssemblyLinearVelocity  = Vector3.new(0,0,0)
    r.AssemblyAngularVelocity = Vector3.new(0,0,0)

    local bg = Instance.new("BodyGyro", r)
    bg.P = 9e4; bg.MaxTorque = Vector3.new(9e9,9e9,9e9); bg.CFrame = r.CFrame
    local bv = Instance.new("BodyVelocity", r)
    bv.Velocity = Vector3.new(0,0,0); bv.MaxForce = Vector3.new(9e9,9e9,9e9)
    local bf = Instance.new("BodyForce", r)
    bf.Force = Vector3.new(0, r.AssemblyMass * workspace.Gravity, 0)

    S.bg = bg; S.bv = bv; S.bf = bf

    h.PlatformStand = true
    h:ChangeState(Enum.HumanoidStateType.Physics)
end

local function destroyMotors(preserveVelY)
    local r = root()
    if r then
        for _, v in ipairs(r:GetChildren()) do
            if v:IsA("BodyGyro") or v:IsA("BodyVelocity") or v:IsA("BodyForce")
            or v:IsA("BodyAngularVelocity") or v:IsA("AlignOrientation")
            or v:IsA("LinearVelocity") or v:IsA("BodyPosition") then
                pcall(function() v:Destroy() end)
            end
        end
        if preserveVelY then
            local vy = r.AssemblyLinearVelocity.Y
            r.AssemblyLinearVelocity = Vector3.new(0, vy < 0 and vy or -4, 0)
        else
            r.AssemblyLinearVelocity  = Vector3.new(0,0,0)
        end
        r.AssemblyAngularVelocity = Vector3.new(0,0,0)
    end
    S.bg = nil; S.bv = nil; S.bf = nil
end

local function updateAntiGrav()
    local r = root()
    if S.bf and S.bf.Parent and r then
        S.bf.Force = Vector3.new(0, r.AssemblyMass * workspace.Gravity, 0)
    end
end

-- ============================================================
-- ANIMACIONES
-- ============================================================
local function loadTrack(id, looped, priority)
    if not S.animator then return nil end
    local obj = Instance.new("Animation")
    obj.AnimationId = id
    local ok, t = pcall(function() return S.animator:LoadAnimation(obj) end)
    if not ok or not t then return nil end
    t.Looped   = looped   ~= false
    t.Priority = priority or Enum.AnimationPriority.Action3
    return t
end

local function stopAllTracks(fade)
    fade = fade or 0.1
    for _, t in pairs(S.tracks) do pcall(function() if t and t.IsPlaying then t:Stop(fade) end end) end
    for _, t in pairs(S.nt)     do pcall(function() if t and t.IsPlaying then t:Stop(fade) end end) end
end

local function stopCombatTracks(fade)
    fade = fade or 0.1
    for _, t in pairs(S.tracks) do pcall(function() if t and t.IsPlaying then t:Stop(fade) end end) end
    -- Parar normalTracks excepto levitación
    for k, t in pairs(S.nt) do
        if k ~= "levitacion" then pcall(function() if t and t.IsPlaying then t:Stop(fade) end end) end
    end
end

local function setupAnimator()
    local c = char(); if not c then return end
    local animScript = c:FindFirstChild("Animate")
    if animScript then animScript.Disabled = true; S.animScript = animScript end
    local h2 = c:WaitForChild("Humanoid", 5)
    if not h2 then return end
    local ctrl = h2:FindFirstChildOfClass("AnimationController")
                 or h2:FindFirstChild("Animator")
                 or Instance.new("Animator", h2)
    S.animator = ctrl:IsA("Animator") and ctrl or ctrl:FindFirstChildOfClass("Animator")
    if not S.animator then
        S.animator = Instance.new("Animator", h2)
    end
    -- Encontrar RootJoint para compensación de altura
    local hrp = c:FindFirstChild("HumanoidRootPart")
    if hrp then
        local lowerTorso = c:FindFirstChild("LowerTorso") or c:FindFirstChild("Torso")
        if lowerTorso then
            S.rootJoint = hrp:FindFirstChildOfClass("Motor6D")
                          or lowerTorso:FindFirstChildOfClass("Motor6D")
            if not S.rootJoint then
                for _, m in ipairs(hrp:GetDescendants()) do
                    if m:IsA("Motor6D") then S.rootJoint = m; break end
                end
            end
        end
        if S.rootJoint then S.origC0 = S.rootJoint.C0 end
    end
end

local function loadNormalTracks()
    S.nt = {
        estatica     = loadTrack(ANIM.estatica,      true,  Enum.AnimationPriority.Action2),
        levitacion   = loadTrack(ANIM.levitacion,    true,  Enum.AnimationPriority.Action4),
        brazos       = loadTrack(ANIM.brazos_idle,   true,  Enum.AnimationPriority.Action3),
        mov_forward  = loadTrack(ANIM.mov_forward,   true,  Enum.AnimationPriority.Action3),
        mov_back     = loadTrack(ANIM.mov_back_anim, true,  Enum.AnimationPriority.Action3),
        mov_brazos   = loadTrack(ANIM.mov_brazos_mov,true,  Enum.AnimationPriority.Action3),
        lateral      = loadTrack(ANIM.mov_lateral,   false, Enum.AnimationPriority.Action3),
        espacio_prim = loadTrack(ANIM.espacio_prim,  true,  Enum.AnimationPriority.Action3),
        espacio_sec  = loadTrack(ANIM.espacio_sec,   false, Enum.AnimationPriority.Action3),
    }
end

local function getTrack(id)
    if S.tracks[id] then return S.tracks[id] end
    local t = loadTrack(id, false, Enum.AnimationPriority.Action4)
    if t then S.tracks[id] = t end
    return t
end

-- ============================================================
-- ANIMACIÓN: MODO NORMAL
-- ============================================================
local _normalCycleId = 0

local function startNormalCycle()
    _normalCycleId = _normalCycleId + 1
    local myId = _normalCycleId
    local nt = S.nt

    task.spawn(function()
        if not nt.estatica or not nt.levitacion then return end
        -- Fade-in estatica → luego levitacion de fondo
        pcall(function() nt.estatica:Play(0.4) end)
        task.wait(nt.estatica.Length * 0.01)
        if _normalCycleId ~= myId or not S.on then return end
        pcall(function() nt.levitacion:Play(0.4); nt.levitacion:AdjustSpeed(0.8) end)
        -- Compensación de altura
        if S.rootJoint and S.origC0 then
            local target = S.origC0 * CFrame.new(0, 1.5, 0)
            local t0 = tick()
            local conn
            conn = RunService.Heartbeat:Connect(function()
                if _normalCycleId ~= myId or not S.on then conn:Disconnect(); return end
                local alpha = math.clamp((tick()-t0)/0.5, 0, 1)
                if S.rootJoint then
                    S.rootJoint.C0 = S.origC0:Lerp(target, alpha)
                end
                if alpha >= 1 then conn:Disconnect() end
            end)
        end
    end)
end

local function updateNormalAnim()
    -- Se llama cada frame mientras S.mode == "normal"
    -- Solo actualiza qué animación de movimiento suena; levitación sigue en fondo
end

-- ============================================================
-- ANIMACIÓN: MODOS FAST / TURBO
-- ============================================================
local function enterFast()
    stopCombatTracks(0.2)
    local t = getTrack(ANIM.turbo_compact)
    if t then pcall(function() t:Play(0.1) end) end
    task.delay(0.4, function()
        if S.mode ~= "fast" or not S.on then return end
        local enter = getTrack(ANIM.turbo_enter or ANIM.turbo_compact)
        if enter and not enter.IsPlaying then pcall(function() enter:Play(0.1) end) end
    end)
end

local function enterTurbo()
    stopCombatTracks(0.15)
    local burst = getTrack(ANIM.turbo_burst)
    if burst then pcall(function() burst:Play(0.05) end) end
    task.delay(0.3, function()
        if S.mode ~= "turbo" or not S.on then return end
        local loop = getTrack(ANIM.turbo_loop)
        if loop then pcall(function() loop:Play(0.15) end) end
    end)
    playSound(SFX.turbo, 0.7)
    -- Noclip automático en turbo
    if S.noclipSpace then setNoclip(true) end
end

local function exitToNormal()
    -- Para tracks de fast/turbo
    for _, id in ipairs({ANIM.turbo_compact, ANIM.turbo_burst, ANIM.turbo_enter,
                          ANIM.turbo_loop, ANIM.turbo_idle, ANIM.mega_pose,
                          ANIM.mega_base, ANIM.mega_volado}) do
        local t = S.tracks[id]
        if t and t.IsPlaying then pcall(function() t:Stop(0.3) end) end
    end
    -- Inclinar C0 de vuelta
    if S.rootJoint and S.origC0 then
        local target = S.origC0 * CFrame.new(0, 1.5, 0)
        local conn; local t0 = tick()
        conn = RunService.Heartbeat:Connect(function()
            if not S.on or S.mode ~= "normal" then conn:Disconnect(); return end
            local a = math.clamp((tick()-t0)/0.4, 0, 1)
            if S.rootJoint then S.rootJoint.C0 = S.rootJoint.C0:Lerp(target, a) end
            if a >= 1 then conn:Disconnect() end
        end)
    end
    -- Quitar noclip turbo si no hay otro sistema que lo necesite
    if not S.noclipCtrl then setNoclip(false) end
    if S.nt.levitacion and not S.nt.levitacion.IsPlaying then
        pcall(function() S.nt.levitacion:Play(0.3); S.nt.levitacion:AdjustSpeed(0.8) end)
    end
end

-- ============================================================
-- ANIMACIÓN DE MOVIMIENTO (modo normal)
-- ============================================================
local _movToken = 0

local function evalMovement()
    _movToken = _movToken + 1
    local tok = _movToken
    task.defer(function()
        if _movToken ~= tok or S.mode ~= "normal" or not S.on then return end
        local nt = S.nt
        local w = S.wDown; local s = S.sDown
        local a = S.aDown; local d = S.dDown
        local moving = w or s or a or d

        if not moving then
            -- Idle: parar tracks de movimiento
            for _, k in ipairs({"mov_forward","mov_back","mov_brazos","lateral"}) do
                local t = nt[k]; if t and t.IsPlaying then pcall(function() t:Stop(0.3) end) end
            end
        else
            -- Para back si hay forward y viceversa
            if w and nt.mov_back and nt.mov_back.IsPlaying then
                pcall(function() nt.mov_back:Stop(0.2) end)
            end
            if s and nt.mov_forward and nt.mov_forward.IsPlaying then
                pcall(function() nt.mov_forward:Stop(0.2) end)
            end
            -- Forward
            if w and nt.mov_forward and not nt.mov_forward.IsPlaying then
                pcall(function() nt.mov_forward:Play(0.2) end)
            end
            -- Back
            if s and not w and nt.mov_back and not nt.mov_back.IsPlaying then
                pcall(function() nt.mov_back:Play(0.2) end)
            end
            -- Lateral
            if (a or d) and nt.lateral and not nt.lateral.IsPlaying then
                pcall(function() nt.lateral:Play(0.2) end)
            end
            if not a and not d and nt.lateral and nt.lateral.IsPlaying then
                pcall(function() nt.lateral:Stop(0.2) end)
            end
            -- Brazos en movimiento
            if nt.mov_brazos and not nt.mov_brazos.IsPlaying then
                pcall(function() nt.mov_brazos:Play(0.2) end)
            end
        end
    end)
end

-- ============================================================
-- GUI (HUD compacto)
-- ============================================================
local function buildGui()
    pcall(function() if S.gui and S.gui.Parent then S.gui:Destroy() end end)

    local sg = Instance.new("ScreenGui")
    sg.Name = "FlyHUD"; sg.ResetOnSpawn = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Global
    sg.IgnoreGuiInset = true; sg.Parent = CoreGui
    S.gui = sg

    local C_BG   = Color3.fromRGB(10,4,20)
    local C_ACC  = Color3.fromRGB(180,120,255)
    local C_TEXT = Color3.fromRGB(220,190,255)
    local C_GREEN= Color3.fromRGB(80,255,150)
    local C_YEL  = Color3.fromRGB(255,220,60)
    local C_RED  = Color3.fromRGB(255,80,80)

    local frame = Instance.new("Frame", sg)
    frame.Size = UDim2.new(0,160,0,40)
    frame.Position = UDim2.new(0.5,-80,0,8)
    frame.BackgroundColor3 = C_BG
    frame.BackgroundTransparency = 0.15
    frame.BorderSizePixel = 0
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0,10)
    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = C_ACC; stroke.Thickness = 1.2; stroke.Transparency = 0.3

    local title = Instance.new("TextLabel", frame)
    title.Size = UDim2.new(0,50,1,0); title.Position = UDim2.new(0,6,0,0)
    title.BackgroundTransparency = 1; title.Font = Enum.Font.GothamBold
    title.TextSize = 11; title.TextColor3 = C_ACC; title.Text = "✦ FLY"
    title.TextXAlignment = Enum.TextXAlignment.Left

    local modeLbl = Instance.new("TextLabel", frame)
    modeLbl.Size = UDim2.new(1,-60,1,0); modeLbl.Position = UDim2.new(0,56,0,0)
    modeLbl.BackgroundTransparency = 1; modeLbl.Font = Enum.Font.GothamBold
    modeLbl.TextSize = 12; modeLbl.TextColor3 = C_GREEN; modeLbl.Text = "NORMAL"
    modeLbl.TextXAlignment = Enum.TextXAlignment.Center

    S.updateMode = function(mode)
        local labels = {normal="NORMAL", fast="TURBO ×"..FAST_MULT, turbo="MEGA ×"..TURBO_MULT}
        local colors  = {normal=C_GREEN, fast=C_YEL, turbo=C_RED}
        modeLbl.Text = labels[mode] or mode
        modeLbl.TextColor3 = colors[mode] or C_GREEN
    end
end

local function destroyGui()
    pcall(function() if S.gui and S.gui.Parent then S.gui:Destroy() end end)
    S.gui = nil; S.updateMode = nil; S.updateLbl = nil
end

-- ============================================================
-- LOCK SYSTEM
-- ============================================================
local function removeLockVisuals()
    pcall(function() if S.lockHighlight then S.lockHighlight:Destroy() end end)
    pcall(function() if S.lockIcon      then S.lockIcon:Destroy()      end end)
    S.lockHighlight = nil; S.lockIcon = nil
end

local function isValidTarget(p)
    if not p or not p.Character then return false end
    local h2 = p.Character:FindFirstChildOfClass("Humanoid")
    return h2 and h2.Health > 0
end

local function lockOnTarget(target)
    removeLockVisuals()
    S.lockOn = true; S.lockTarget = target
    -- Highlight
    local hl = Instance.new("SelectionBox")
    hl.Adornee = target.Character
    hl.Color3 = Color3.fromRGB(255,80,80)
    hl.LineThickness = 0.04; hl.SurfaceTransparency = 0.85
    hl.Parent = CoreGui; S.lockHighlight = hl
end

local function unlockTarget()
    S.lockOn = false; S.lockTarget = nil
    removeLockVisuals()
end

local function startLockSystem()
    addConn("lockConn", UserInputService.InputBegan:Connect(function(inp, gpe)
        if gpe or not S.on then return end
        if inp.KeyCode ~= Enum.KeyCode.X then return end
        if S.lockOn then unlockTarget(); return end
        -- Buscar jugador más cercano a la cámara
        local cam = workspace.CurrentCamera
        if not cam then return end
        local best, bestDot = nil, 0.6
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= lplr and isValidTarget(p) then
                local r2 = p.Character:FindFirstChild("HumanoidRootPart")
                if r2 then
                    local dir = (r2.Position - cam.CFrame.Position).Unit
                    local dot = cam.CFrame.LookVector:Dot(dir)
                    if dot > bestDot then bestDot = dot; best = p end
                end
            end
        end
        if best then lockOnTarget(best) end
    end))
end

local function stopLockSystem()
    if S.conns.lockConn then S.conns.lockConn:Disconnect(); S.conns.lockConn = nil end
    unlockTarget()
end

-- ============================================================
-- COMBO SYSTEM
-- ============================================================
local function launchAnim(id, speed, fadeIn)
    local t = getTrack(id)
    if not t then return end
    -- Esperar que cargue (máx 2s)
    local timeout = tick() + 2
    while t.Length == 0 and tick() < timeout do task.wait() end
    if not S.on then return end
    stopCombatTracks(0.08)
    t.Looped = false; t.Priority = Enum.AnimationPriority.Action4
    if t.IsPlaying then pcall(function() t:Stop(0) end) end
    pcall(function() t:Play(fadeIn or 0.05, 1, speed or 1) end)
end

local function resetCombo()
    S.comboStep = 0; S.comboBusy = false; S.comboPlay = false
    S.combo2Last = nil; S.blockCancelledByCombo = false
end

local _comboSession = 0

local function runCombo(startSession)
    -- Paso a paso con ventana de tiempo
    local function waitForClick(stepIdx)
        local dur  = COMBO_DURATIONS[stepIdx] or 0.47
        local tEnd = tick() + dur
        while tick() < tEnd do
            task.wait(0.02)
            if _comboSession ~= startSession or not S.on then return false end
        end
        -- Ahora esperar click (ventana COMBO_WINDOW)
        S.comboBusy = false
        local tWin = tick() + COMBO_WINDOW
        while tick() < tWin do
            task.wait(0.02)
            if _comboSession ~= startSession or not S.on then return false end
            if S.mouseHeld then return true end
        end
        return false  -- timeout: combo termina
    end

    -- PASO 1
    S.comboPlay = true; S.comboBusy = true
    launchAnim(ANIM.combo1, 3.0)
    local cont = waitForClick(1)
    if not cont or _comboSession ~= startSession then resetCombo(); return end

    -- PASO 2
    S.comboBusy = true; S.mouseHeld = false
    local id2 = (math.random(2) == 1) and ANIM.combo2a or ANIM.combo2b
    S.combo2Last = id2
    launchAnim(id2, 3.0)
    cont = waitForClick(2)
    if not cont or _comboSession ~= startSession then resetCombo(); return end

    -- PASO 3
    S.comboBusy = true; S.mouseHeld = false
    local id3 = (S.combo2Last == ANIM.combo2a) and ANIM.combo3b or ANIM.combo3a
    launchAnim(id3, 3.0)
    cont = waitForClick(3)
    if not cont or _comboSession ~= startSession then resetCombo(); return end

    -- PASO 4 (con Space o normal)
    S.comboBusy = true; S.mouseHeld = false
    local spaceDown = UserInputService:IsKeyDown(Enum.KeyCode.Space)
    if spaceDown then
        launchAnim(ANIM.combo4_space, 3.0)
    else
        launchAnim(ANIM.combo4, 3.0)
    end
    task.wait(COMBO_DURATIONS[4])
    resetCombo()
    -- Reanudar ciclo normal
    if S.on and S.mode == "normal" then
        if S.nt.levitacion and not S.nt.levitacion.IsPlaying then
            pcall(function() S.nt.levitacion:Play(0.15); S.nt.levitacion:AdjustSpeed(0.8) end)
        end
        _normalCycleId = _normalCycleId + 1
    end
end

local function startCombo()
    if not S.on or S.comboPlay or S.blocking then return end
    if S.mode ~= "normal" then return end
    _comboSession = _comboSession + 1
    local sess = _comboSession
    task.spawn(function() runCombo(sess) end)
end

-- ============================================================
-- BLOQUEO
-- ============================================================
local function startBlocking()
    if S.blocking or not S.on then return end
    if S.mode ~= "normal" then return end
    S.blocking = true
    local t = getTrack(ANIM.bloqueo)
    if not t then S.blocking = false; return end
    stopCombatTracks(0.1)
    t.Looped = true; t.Priority = Enum.AnimationPriority.Action4
    pcall(function() t:Play(0.1) end)
end

local function stopBlocking()
    if not S.blocking then return end
    S.blocking = false
    local t = S.tracks[ANIM.bloqueo]
    if t and t.IsPlaying then pcall(function() t:Stop(0.2) end) end
    -- Reanudar levitacion
    if S.on and S.mode == "normal" and S.nt.levitacion and not S.nt.levitacion.IsPlaying then
        pcall(function() S.nt.levitacion:Play(0.2); S.nt.levitacion:AdjustSpeed(0.8) end)
    end
end

-- ============================================================
-- DASH
-- ============================================================
local function triggerDash(dir, speed, dur)
    local cam = workspace.CurrentCamera; if not cam then return end
    local dashDir
    local look  = cam.CFrame.LookVector
    local right = cam.CFrame.RightVector
    if dir == "forward" then dashDir = Vector3.new(look.X, 0, look.Z)
    elseif dir == "back" then dashDir = Vector3.new(-look.X, 0, -look.Z)
    elseif dir == "left" then dashDir = Vector3.new(-right.X, 0, -right.Z)
    elseif dir == "right"then dashDir = Vector3.new(right.X, 0, right.Z)
    end
    if not dashDir or dashDir.Magnitude < 0.01 then return end
    S.dashVel  = dashDir.Unit * speed
    S.dashTimer = dur
    -- Animación de dash
    local animId = (dir == "left") and ANIM.sq_anim or ANIM.dq_anim
    task.spawn(function()
        local t = getTrack(animId)
        if not t then return end
        local timeout = tick() + 2
        while t.Length == 0 and tick() < timeout do task.wait() end
        if not S.on then return end
        stopCombatTracks(0.04)
        t.Looped = false; t.Priority = Enum.AnimationPriority.Action4
        if t.IsPlaying then pcall(function() t:Stop(0) end) end
        pcall(function() t:Play(0.04, 1, 3.0) end)
    end)
end

-- ============================================================
-- LOOP PRINCIPAL (RenderStepped)
-- rsConn: giroscopio + detección de TP externo + movimiento
-- ============================================================
local function startMainLoop()
    local mySession = S.session
    addConn("rsConn", RunService.RenderStepped:Connect(function(dt)
        if S.session ~= mySession or not S.on then return end
        local r = root(); local h2 = hum()
        if not r or not h2 then return end

        local pos = r.Position
        -- Descartar posición absurda
        if math.abs(pos.X) > COORD_LIMIT or math.abs(pos.Y) > COORD_LIMIT
        or math.abs(pos.Z) > COORD_LIMIT then return end

        -- ── Detectar TP externo ──────────────────────────────────────────
        -- Si la posición saltó más de TP_THRESHOLD studs en un frame,
        -- es un TP externo intencional: adaptarse, no resistir.
        if S.lastPos then
            local delta = (pos - S.lastPos).Magnitude
            if delta > TP_THRESHOLD then
                -- Actualizar gyro al nuevo sitio
                if S.bg then S.bg.CFrame = r.CFrame end
                if S.bv then S.bv.Velocity = Vector3.new(0,0,0) end
                r.AssemblyLinearVelocity  = Vector3.new(0,0,0)
                r.AssemblyAngularVelocity = Vector3.new(0,0,0)
                S.safePos  = pos
                S.tpGrace  = tick() + 0.15   -- 150ms sin antiImpulse
            end
        end
        S.lastPos = pos

        -- Actualizar safePos (void guard)
        if pos.Y > -490 then S.safePos = pos end

        -- ── Recrear motores si desaparecieron ───────────────────────────
        if not r:FindFirstChild("BodyGyro") or not r:FindFirstChild("BodyVelocity") then
            makeMotors(); return
        end
        S.bg = r:FindFirstChild("BodyGyro")
        S.bv = r:FindFirstChild("BodyVelocity")
        S.bf = r:FindFirstChild("BodyForce")
        updateAntiGrav()

        -- ── Anti-impulso (solo si no estamos en gracia de TP) ───────────
        if tick() > S.tpGrace and S.bv and S.bv.Parent then
            local actual = r.AssemblyLinearVelocity
            local expect = S.bv.Velocity
            if (actual - expect).Magnitude > 3 then
                r.AssemblyLinearVelocity = expect
            end
            if r.AssemblyAngularVelocity.Magnitude > 5 then
                r.AssemblyAngularVelocity = Vector3.new(0,0,0)
            end
        end

        -- ── Giro del BodyGyro (siempre hacia la cámara o el target) ─────
        local cam = workspace.CurrentCamera
        if S.lockOn and S.lockTarget and isValidTarget(S.lockTarget) then
            local tPart = S.lockTarget.Character:FindFirstChild("UpperTorso")
                       or S.lockTarget.Character:FindFirstChild("HumanoidRootPart")
            if tPart then
                local desired = CFrame.lookAt(pos, tPart.Position, Vector3.new(0,1,0))
                S.bg.CFrame = S.bg.CFrame:Lerp(desired, S.LOCK_SMOOTH)
            else
                unlockTarget()
            end
        else
            local sf
            if S.mode == "fast" or S.mode == "turbo" then
                -- En turbo: giro progresivo (menos agresivo en giros grandes)
                local dot = math.clamp(S.bg.CFrame.LookVector:Dot(cam.CFrame.LookVector), -1, 1)
                local ang = math.acos(dot)
                local t_a = math.clamp(1 - ang / math.pi, 0, 1)
                sf = math.clamp(0.04 + t_a * t_a * 0.14, 0, 0.20)
            else
                sf = math.clamp(dt * 10, 0, 1)
            end
            S.bg.CFrame = S.bg.CFrame:Lerp(cam.CFrame, sf)
        end

        -- ── Actualizar teclas ────────────────────────────────────────────
        if not isTyping() then
            S.wDown = UserInputService:IsKeyDown(Enum.KeyCode.W)
            S.sDown = UserInputService:IsKeyDown(Enum.KeyCode.S)
            S.aDown = UserInputService:IsKeyDown(Enum.KeyCode.A)
            S.dDown = UserInputService:IsKeyDown(Enum.KeyCode.D)
        else
            S.wDown=false; S.sDown=false; S.aDown=false; S.dDown=false
        end
        if S.bv then S.bv.Velocity = Vector3.new(0,0,0) end

        -- ── Freno de lock en turbo ───────────────────────────────────────
        if S.lockOn and S.lockTarget and S.dashTimer > 0 then
            local tRoot = S.lockTarget.Character and
                          S.lockTarget.Character:FindFirstChild("HumanoidRootPart")
            if tRoot then
                local dist = (pos - tRoot.Position).Magnitude
                if dist <= S.BRAKE_HARD then
                    S.dashVel = Vector3.new(0,0,0); S.dashTimer = 0
                elseif dist <= S.BRAKE_DIST then
                    local t_b = 1 - (dist - S.BRAKE_HARD) / (S.BRAKE_DIST - S.BRAKE_HARD)
                    S.dashVel = S.dashVel * math.max(1 - t_b * 0.92, 0.05)
                end
            end
        end

        -- ── Fade del dash ────────────────────────────────────────────────
        if S.dashTimer > 0 then
            S.dashTimer = S.dashTimer - dt
            if S.dashTimer <= 0 then
                S.dashTimer = 0; S.dashVel = Vector3.new(0,0,0)
            else
                S.dashVel = S.dashVel:Lerp(Vector3.new(0,0,0), math.clamp(dt*9,0,1))
            end
        end
    end))
end

-- ============================================================
-- LOOP DE MOVIMIENTO (Stepped)
-- Separo del rsConn para que el movimiento ocurra en física,
-- no en render — evita el problema de "vuelo no activo".
-- ============================================================
local function startMoveLoop()
    local mySession = S.session
    addConn("moveConn", RunService.Stepped:Connect(function(_, dt)
        if S.session ~= mySession or not S.on then return end
        local cc = char(); local r = root()
        if not r or not cc then return end

        local pos = r.Position
        if math.abs(pos.X) > COORD_LIMIT or math.abs(pos.Y) > COORD_LIMIT
        or math.abs(pos.Z) > COORD_LIMIT then return end

        -- Void guard
        if pos.Y <= -500 and S.safePos then
            pcall(function()
                r.CFrame = CFrame.new(S.safePos + Vector3.new(0,5,0))
                r.AssemblyLinearVelocity  = Vector3.new(0,0,0)
                r.AssemblyAngularVelocity = Vector3.new(0,0,0)
            end)
            return
        end

        local cam = workspace.CurrentCamera; if not cam then return end
        if isTyping() then return end

        local wD = UserInputService:IsKeyDown(Enum.KeyCode.W)
        local sD = UserInputService:IsKeyDown(Enum.KeyCode.S)
        local aD = UserInputService:IsKeyDown(Enum.KeyCode.A)
        local dD = UserInputService:IsKeyDown(Enum.KeyCode.D)
        local spD= UserInputService:IsKeyDown(Enum.KeyCode.Space)
        local ctD= UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)

        -- Noclip Ctrl
        if ctD and not S.noclipCtrl then
            S.noclipCtrl = true; setNoclip(true)
        elseif not ctD and S.noclipCtrl then
            S.noclipCtrl = false
            if not S.noclipSpace and S.mode ~= "turbo" then setNoclip(false) end
        end

        -- Noclip Space (en modo normal, ascender a través del techo)
        if spD and not S.megaUp and not S.noclipSpace then
            S.noclipSpace = true; setNoclip(true)
        elseif not spD and S.noclipSpace then
            S.noclipSpace = false
            if not S.noclipCtrl and S.mode ~= "turbo" then setNoclip(false) end
        end

        -- Construir vector de movimiento
        local move = Vector3.new()
        if wD then move = move + cam.CFrame.LookVector end
        if sD then move = move - cam.CFrame.LookVector end
        if aD then move = move - cam.CFrame.RightVector end
        if dD then move = move + cam.CFrame.RightVector end

        -- Lock tracking en fast/turbo
        if S.lockOn and S.lockTarget and isValidTarget(S.lockTarget) and (S.mode=="fast" or S.mode=="turbo") and wD then
            local tRoot = S.lockTarget.Character:FindFirstChild("HumanoidRootPart")
            if tRoot then
                local toT = tRoot.Position - pos
                local hor = Vector3.new(toT.X, 0, toT.Z)
                if hor.Magnitude > 0.1 then
                    move = Vector3.new(hor.Unit.X * (move.Magnitude > 0 and move.Magnitude or 1),
                                       move.Y,
                                       hor.Unit.Z * (move.Magnitude > 0 and move.Magnitude or 1))
                end
            end
        end

        -- Vertical: Space sube, Ctrl baja
        if S.megaUp then
            move = move + Vector3.new(0,2,0)
        elseif spD then
            move = move + Vector3.new(0,1,0)
        end
        if ctD then move = move - Vector3.new(0,1,0) end

        local speed = S.speed
        if S.dashTimer > 0 and S.dashVel.Magnitude > 0.1 then
            -- Combinar dash con movimiento
            if move.Magnitude > 0.01 then
                local translation = (move.Unit * speed + S.dashVel) * dt
                pcall(function() cc:TranslateBy(translation) end)
            else
                pcall(function() cc:TranslateBy(S.dashVel * dt) end)
            end
        elseif move.Magnitude > 0.01 then
            pcall(function() cc:TranslateBy(move.Unit * speed * dt) end)
        end
    end))
end

-- ============================================================
-- MODO: CAMBIO DE VELOCIDAD (tecla Q)
-- ============================================================
local _qLastPress = 0

local function handleQ()
    if not S.on then return end
    local now = tick()
    local diff = now - _qLastPress
    _qLastPress = now

    if S.mode == "normal" then
        -- Primer Q: entrar a fast
        S.mode  = "fast"
        S.speed = BASE_SPEED * FAST_MULT
        enterFast()
        if S.updateMode then S.updateMode("fast") end

    elseif S.mode == "fast" then
        if diff < 0.4 then
            -- Doble Q rápido: turbo
            S.mode  = "turbo"
            S.speed = BASE_SPEED * TURBO_MULT
            enterTurbo()
            if S.updateMode then S.updateMode("turbo") end
        else
            -- Q único en fast: volver a normal
            S.mode  = "normal"
            S.speed = BASE_SPEED
            exitToNormal()
            if S.updateMode then S.updateMode("normal") end
        end

    elseif S.mode == "turbo" then
        -- Q en turbo: volver a normal
        S.mode  = "normal"
        S.speed = BASE_SPEED
        if not S.noclipCtrl then setNoclip(false)
        end S.noclipSpace = false
        exitToNormal()
        if S.updateMode then S.updateMode("normal") end
    end
end

-- ============================================================
-- CONEXIÓN DE INPUT GLOBAL
-- ============================================================
local function connectInput()
    addConn("inputBegan", UserInputService.InputBegan:Connect(function(inp, gpe)
        if gpe or isTyping() then return end

        -- Q: cambio de modo
        if inp.KeyCode == Enum.KeyCode.Q then
            handleQ(); return
        end

        -- F: bloqueo
        if inp.KeyCode == Enum.KeyCode.F and S.on and S.mode == "normal" then
            S.fKeyHeld = true
            if not S.comboPlay and not S.blockCancelledByCombo then
                startBlocking()
            end
            return
        end

        -- W/A/S/D: evaluar animación de movimiento
        if S.on and S.mode == "normal" then
            local dirs = {
                [Enum.KeyCode.W]=true,[Enum.KeyCode.S]=true,
                [Enum.KeyCode.A]=true,[Enum.KeyCode.D]=true
            }
            if dirs[inp.KeyCode] then evalMovement() end
        end

        -- Space en modo normal: animación especial
        if inp.KeyCode == Enum.KeyCode.Space and S.on and S.mode == "normal" then
            if not S.comboPlay then
                -- Verificar hold para MegaUp
                S.spaceHoldStart = tick()
                task.delay(S.SPACE_HOLD, function()
                    if not S.on or S.mode ~= "normal" then return end
                    if S.spaceHoldStart and tick() - S.spaceHoldStart >= S.SPACE_HOLD then
                        S.megaUp = true
                    end
                end)
                -- Animación espacio
                local t = S.nt.espacio_prim
                if t and not t.IsPlaying then pcall(function() t:Play(0.2) end) end
            end
        end
    end))

    addConn("inputEnded", UserInputService.InputEnded:Connect(function(inp, gpe)
        if gpe then return end

        if inp.KeyCode == Enum.KeyCode.F then
            S.fKeyHeld = false
            if S.blocking then stopBlocking() end
        end

        if inp.KeyCode == Enum.KeyCode.Space then
            S.spaceHoldStart = nil; S.megaUp = false
            local t = S.nt.espacio_prim
            if t and t.IsPlaying then pcall(function() t:Stop(0.2) end) end
        end

        if S.on and S.mode == "normal" then
            local dirs = {
                [Enum.KeyCode.W]=true,[Enum.KeyCode.S]=true,
                [Enum.KeyCode.A]=true,[Enum.KeyCode.D]=true
            }
            if dirs[inp.KeyCode] then evalMovement() end
        end
    end))

    -- Click: iniciar combo
    addConn("mouseClick", UserInputService.InputBegan:Connect(function(inp, gpe)
        if gpe or not S.on then return end
        if inp.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        S.mouseHeld = true
        if not S.comboBusy then startCombo() end
    end))

    addConn("mouseRelease", UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            S.mouseHeld = false
        end
    end))
end

-- ============================================================
-- ATERRIZAJE LIMPIO
-- Cuando se apaga el vuelo, el personaje cae normalmente.
-- Sin GettingUp (causa impulso), sin secuencias largas.
-- ============================================================
local function cleanLand()
    local h2 = hum(); if not h2 then return end
    -- Salir de Physics: Freefall no genera impulso hacia arriba
    h2.PlatformStand = false
    h2:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
    pcall(function() h2:ChangeState(Enum.HumanoidStateType.Freefall) end)
    task.delay(0.15, function()
        if h2 and h2.Parent then
            h2:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
        end
    end)
    -- Restaurar script de animación del juego
    if S.animScript then
        pcall(function() S.animScript.Disabled = false end)
        S.animScript = nil
    end
    -- Restaurar C0
    if S.rootJoint and S.origC0 then
        pcall(function() S.rootJoint.C0 = S.origC0 end)
    end
end

-- ============================================================
-- FLY ON / OFF
-- ============================================================
local function flyOn()
    local c = char(); if not c then return end

    -- Nueva sesión: invalida todos los callbacks anteriores inmediatamente
    S.session    = S.session + 1
    S.on         = true
    S.mode       = "normal"
    S.speed      = BASE_SPEED
    S.dashVel    = Vector3.new(0,0,0)
    S.dashTimer  = 0
    S.lastPos    = nil
    S.tpGrace    = 0
    S.safePos    = nil
    S.megaUp     = false
    S.noclipCtrl = false
    S.noclipSpace= false
    S.blocking   = false
    S.comboStep  = 0
    S.comboPlay  = false
    S.comboBusy  = false
    S.mouseHeld  = false
    S.idleTimer  = 0
    S.brazosOn   = false
    S.spaceHoldStart = nil
    _comboSession = _comboSession + 1
    _normalCycleId = _normalCycleId + 1

    -- Desconectar loops anteriores (sin tocar inputBegan/inputEnded)
    for _, k in ipairs({"rsConn","moveConn","lockRenderConn"}) do
        if S.conns[k] then S.conns[k]:Disconnect(); S.conns[k] = nil end
    end

    -- Reset humanoid
    local h2 = c:FindFirstChildOfClass("Humanoid")
    if h2 then
        h2:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
        h2:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
        h2.PlatformStand = false
    end

    -- Parar animaciones antiguas
    stopAllTracks(0)
    S.tracks = {}; S.nt = {}

    setupAnimator()
    makeMotors()
    loadNormalTracks()
    startNormalCycle()
    buildGui()
    startLockSystem()
    startMainLoop()
    startMoveLoop()
end

local function flyOff()
    if not S.on then return end

    -- Invalidar sesión PRIMERO — para que todos los callbacks paren
    S.session = S.session + 1
    S.on      = false

    -- Desconectar loops de sesión
    for _, k in ipairs({"rsConn","moveConn","lockRenderConn"}) do
        if S.conns[k] then S.conns[k]:Disconnect(); S.conns[k] = nil end
    end

    -- Apagar noclip
    setNoclip(false)

    -- Parar animaciones
    stopAllTracks(0.2)

    -- Destruir motores (preservar velocidad Y para caída natural)
    destroyMotors(true)

    -- Aterrizar limpio
    cleanLand()

    -- GUI
    destroyGui()
    stopLockSystem()
    unlockTarget()

    -- Reset de estado
    S.mode       = "normal"
    S.speed      = BASE_SPEED
    S.dashVel    = Vector3.new(0,0,0)
    S.dashTimer  = 0
    S.lastPos    = nil
    S.tpGrace    = 0
    S.safePos    = nil
    S.megaUp     = false
    S.noclipCtrl = false
    S.noclipSpace= false
    S.blocking   = false
    resetCombo()
end

-- ============================================================
-- RECONEXIÓN AL RESPAWN
-- ============================================================
local _charConn = nil

local function connectChar()
    if _charConn then _charConn:Disconnect() end
    _charConn = lplr.CharacterAdded:Connect(function()
        local wasOn = S.on
        flyOff()
        task.wait(0.5)
        if wasOn then flyOn() end
    end)
end

-- ============================================================
-- EXPORTACIÓN DEL MÓDULO
-- ============================================================
local M = {}

function M.Start(lplrRef)
    lplr   = lplrRef or Players.LocalPlayer
    camera = workspace.CurrentCamera
    connectInput()
    connectChar()
end

function M.Stop()
    flyOff()
    disconnectAll()
    if _charConn then _charConn:Disconnect(); _charConn = nil end
end

function M.Toggle(state)
    if state == true  and not S.on then flyOn()
    elseif state == false and S.on  then flyOff()
    elseif state == nil then
        if S.on then flyOff() else flyOn() end
    end
end

function M.SetSpeed(base, fastMult, turboMult)
    BASE_SPEED  = base      or BASE_SPEED
    FAST_MULT   = fastMult  or FAST_MULT
    TURBO_MULT  = turboMult or TURBO_MULT
    if S.on then
        if S.mode == "normal" then S.speed = BASE_SPEED
        elseif S.mode == "fast"   then S.speed = BASE_SPEED * FAST_MULT
        elseif S.mode == "turbo"  then S.speed = BASE_SPEED * TURBO_MULT
        end
    end
end

function M.IsFlying() return S.on end
function M.GetMode()  return S.mode end

return M
