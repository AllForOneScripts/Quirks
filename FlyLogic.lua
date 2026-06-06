-- FlyLogic.lua
-- Módulo responsable de la física de vuelo, movimiento, dash, lock, noclip,
-- protección anti-teleport, sistemas de seguridad y efectos visuales/sonoros.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")

-- ============================================================
-- Constantes
-- ============================================================
local BASE_SPEED    = 60
local FAST_MULT     = 3.0
local TURBO_MULT    = 6.0
local DEFAULT_BASE  = 60
local DEFAULT_FAST  = 3.0
local DEFAULT_TURBO = 6.0

local LOCK_ROTATION_SMOOTH = 0.8
local COORD_SANITY_LIMIT = 50000

local ANOMALY_SPEED_THRESHOLD = 300
local ANOMALY_TELEPORT_STUDS  = 40
local ANOMALY_COOLDOWN        = 0.12
local MOTOR_RESET_COOLDOWN    = 0.5

local SFX_TURBO      = "rbxassetid://137455842313478"
local SFX_MEGA_TURBO = "rbxassetid://111391583223900"
local SFX_LANDING    = "rbxassetid://135226467234227"
local SMOKE_RING_TEX = "rbxassetid://137805272670926"

local PARTICLE_TEXTURE = "rbxassetid://106822944701902"
local PARTICLE_LENGTH  = 6
local AIR_SHOCK_ID     = "rbxassetid://112096280571499"
local SHOCKWAVE_ID     = "rbxassetid://117592591478260"
local RING_ID          = "rbxassetid://12914395250"
local WHITE            = Color3.fromRGB(255, 255, 255)

-- ============================================================
-- Estado interno
-- ============================================================
local state = {
    -- Referencias externas
    lplr   = nil,
    camera = nil,

    -- Sistema de vuelo
    enabled    = false,
    mode       = "normal",   -- normal, fast, turbo, megaup
    speed      = BASE_SPEED,
    flyKey     = Enum.KeyCode.C,
    lockKey    = Enum.KeyCode.X,

    -- Motores
    bg = nil,   -- BodyGyro
    bv = nil,   -- BodyVelocity
    bf = nil,   -- BodyForce

    -- Movimiento
    wDown = false, sDown = false, aDown = false, dDown = false,

    -- Dash
    dashVel   = Vector3.new(0,0,0),
    dashTimer = 0,
    DASH_SPEED      = 297,
    DASH_DURATION   = 0.38,
    SIDE_DASH_SPEED = 297 * 1.35,
    TURBO_DASH_SPEED    = 405,
    TURBO_DASH_DURATION = 0.45,
    BACK_DASH_SPEED = 594,

    -- Lock-on
    lockActive      = false,
    lockedTarget    = nil,
    lockCameraLerp  = 0.18,
    lockIconGui     = nil,
    lockInfoGui     = nil,
    lockHighlight   = nil,
    lockConn        = nil,
    lockRenderConn  = nil,

    -- Noclip
    noclipSpaceEnabled = true,
    noclipSpaceActive  = false,
    noclipMegaEnabled  = true,
    noclipCtrlEnabled  = true,
    noclipCtrlActive   = false,

    -- Mega Turbo Up
    megaTurboUpActive = false,
    spaceHoldStart    = nil,
    SPACE_HOLD_TIME   = 2,

    -- Brake system
    brakingActive     = false,
    BRAKE_DISTANCE    = 35,
    BRAKE_HARD_DISTANCE = 14,
    brakeConn         = nil,

    -- Anti-impulse y protección
    antiImpulseConn      = nil,
    gyroProtectionActive = false,
    gyroProtectionTimer  = nil,
    originalGyroP        = nil,
    originalGyroMaxTorque = nil,
    backupGyro           = nil,

    -- Protección de anomalías y teletransporte
    anomalyConn          = nil,
    lastKnownPos         = nil,
    ragdollDetected      = false,
    lastAnomalyFix       = 0,
    lastMotorReset       = 0,
    teleportGuardConn    = nil,
    isTeleportGuardActive = false,
    lastSafePos          = nil,
    lastSafeTime         = 0,

    -- Sistema de aterrizaje
    waitingLand       = false,
    landingHeight     = nil,
    landingVelocity   = 0,
    landingVelocityCapture = 0,
    landConn          = nil,
    landWatcherConn   = nil,
    landWatcherToken  = 0,

    -- Partículas y efectos
    particleRunning = false,
    particleConn    = nil,
    particleList    = {},

    -- Conexiones
    rsConn      = nil,
    tpMoveConn  = nil,

    -- Token de sesión (invalida callbacks residuales)
    sessionToken = 0,
}

-- Referencia al módulo FlyAnim (se inyectará desde FlyControl)
local FlyAnim = nil

-- ============================================================
-- Funciones auxiliares (extraídas del original)
-- ============================================================
local function isTyping()
    return UserInputService:GetFocusedTextBox() ~= nil
end

local function playLocalSound(id, volume)
    local snd = Instance.new("Sound")
    snd.SoundId   = id
    snd.Volume    = volume or 0.85
    snd.RollOffMaxDistance = 0
    snd.Parent    = SoundService
    snd:Play()
    task.delay(10, function() pcall(function() snd:Destroy() end) end)
    snd.Ended:Connect(function() pcall(function() snd:Destroy() end) end)
end

local function setNoclip(state)
    local char = state.lplr and state.lplr.Character
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

    local char = root.Parent
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        pcall(function()
            hum.PlatformStand = false
            hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
            hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
            hum:ChangeState(Enum.HumanoidStateType.Freefall)
        end)
    end

    if preserveVelY then
        local currentVelY = 0
        pcall(function() currentVelY = root.AssemblyLinearVelocity.Y end)
        local finalVelY = (currentVelY >= 0) and -4 or currentVelY
        pcall(function() root.AssemblyLinearVelocity = Vector3.new(0, finalVelY, 0) end)
    else
        pcall(function() root.AssemblyLinearVelocity = Vector3.new(0, 0, 0) end)
    end
    pcall(function() root.AssemblyAngularVelocity = Vector3.new(0, 0, 0) end)
end

local function updateAntiGravityForce()
    if not state.bf or not state.bf.Parent then return end
    local char = state.lplr and state.lplr.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local totalMass = 0
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") and not part.Massless then
            totalMass = totalMass + part.AssemblyMass
        end
    end
    if totalMass == 0 then totalMass = root.AssemblyMass end
    local grav = Workspace.Gravity
    state.bf.Force = Vector3.new(0, totalMass * grav, 0)
end

local function _flyMakeMotors()
    local char = state.lplr and state.lplr.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum  = char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end
    cleanupMotors(root, false)
    state.bg = Instance.new("BodyGyro", root)
    state.bg.P = 9e4
    state.bg.maxTorque = Vector3.new(9e9,9e9,9e9)
    state.bg.cframe = root.CFrame
    state.bv = Instance.new("BodyVelocity", root)
    state.bv.velocity = Vector3.new(0,0,0)
    state.bv.maxForce = Vector3.new(9e9,9e9,9e9)
    state.bf = Instance.new("BodyForce", root)
    state.bf.Force = Vector3.new(0, root.AssemblyMass * Workspace.Gravity, 0)
    hum.PlatformStand = true
    hum:ChangeState(Enum.HumanoidStateType.Physics)
end

local function fixUndergroundOrientation()
    local char = state.lplr and state.lplr.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root or not state.bg then return end
    local upVec = root.CFrame.UpVector
    if upVec.Y < 0.3 then
        local lookVec = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
        if lookVec.Magnitude < 0.01 then lookVec = Vector3.new(0,0,-1) end
        local correctedCF = CFrame.lookAt(root.Position, root.Position + lookVec.Unit)
        pcall(function()
            root.CFrame = correctedCF
            root.AssemblyAngularVelocity = Vector3.new(0,0,0)
            if state.bg then state.bg.cframe = correctedCF end
        end)
    end
end

local function showHitboxMarkers(targetChar)
    -- Limpiar marcadores anteriores
    for _, marker in ipairs(state.hitboxMarkers or {}) do
        pcall(function() marker:Destroy() end)
    end
    state.hitboxMarkers = {}
    if not targetChar then return end
    local box = Instance.new("SelectionBox")
    box.Adornee       = targetChar
    box.Color3        = Color3.fromRGB(255, 150, 50)
    box.Transparency  = 0.5
    box.LineThickness = 0.1
    box.Parent        = targetChar
    table.insert(state.hitboxMarkers, box)
    task.delay(0.6, function()
        if box and box.Parent then pcall(function() box:Destroy() end) end
        state.hitboxMarkers = {}
    end)
end

local function shakeCamera(intensity, duration)
    if state.shakeConn then pcall(function() state.shakeConn:Disconnect() end); state.shakeConn = nil end
    local cam = state.camera
    if not cam then return end
    local startT = tick()
    state.shakeConn = RunService.RenderStepped:Connect(function()
        local elapsed = tick() - startT
        if elapsed >= duration then
            state.shakeConn:Disconnect()
            state.shakeConn = nil
            return
        end
        local decay  = 1 - (elapsed / duration)
        local angleX = math.sin(elapsed * 30 * math.pi) * intensity * decay
        local angleY = math.sin(elapsed * 25 * math.pi) * intensity * decay * 0.8
        local angleZ = math.sin(elapsed * 35 * math.pi) * intensity * decay * 0.6
        pcall(function() cam.CFrame = cam.CFrame * CFrame.Angles(math.rad(angleX), math.rad(angleY), math.rad(angleZ)) end)
    end)
end

-- ============================================================
-- Sistema de protecciones (Anti-impulso, anomalías, teleport)
-- ============================================================
local function startAntiImpulse()
    if state.antiImpulseConn then state.antiImpulseConn:Disconnect(); state.antiImpulseConn = nil end
    local mySession = state.sessionToken
    state.antiImpulseConn = RunService.Stepped:Connect(function()
        if state.sessionToken ~= mySession then
            if state.antiImpulseConn then state.antiImpulseConn:Disconnect(); state.antiImpulseConn = nil end
            return
        end
        if not state.enabled then
            if state.antiImpulseConn then state.antiImpulseConn:Disconnect(); state.antiImpulseConn = nil end
            return
        end
        local char = state.lplr and state.lplr.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        local bv = state.bv
        if not bv or not bv.Parent then return end
        local expectedVel = bv.velocity
        local actualVel   = root.AssemblyLinearVelocity
        local diff = (actualVel - expectedVel).Magnitude
        if diff > 3 then root.AssemblyLinearVelocity = expectedVel end
        local bg = state.bg
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
    if state.antiImpulseConn then state.antiImpulseConn:Disconnect(); state.antiImpulseConn = nil end
end

local function activateGyroProtection()
    if state.gyroProtectionActive then return end
    if not state.bg then return end
    state.gyroProtectionActive  = true
    state.originalGyroP         = state.bg.P
    state.originalGyroMaxTorque = state.bg.maxTorque
    state.bg.P         = 2000
    state.bg.maxTorque = Vector3.new(2000,2000,2000)
    if state.backupGyro then state.backupGyro:Destroy() end
    state.backupGyro = Instance.new("BodyGyro", state.bg.Parent)
    state.backupGyro.P         = 1000
    state.backupGyro.maxTorque = Vector3.new(1000,1000,1000)
    state.backupGyro.cframe    = state.bg.cframe
    if state.gyroProtectionTimer then task.cancel(state.gyroProtectionTimer) end
    state.gyroProtectionTimer = task.delay(0.5, function()
        if state.enabled and state.bg then
            state.bg.P         = state.originalGyroP or 9e4
            state.bg.maxTorque = state.originalGyroMaxTorque or Vector3.new(9e9,9e9,9e9)
        end
        if state.backupGyro then state.backupGyro:Destroy(); state.backupGyro = nil end
        state.gyroProtectionActive = false
        state.gyroProtectionTimer  = nil
    end)
end

local function silentMotorReset()
    local now = tick()
    if now - state.lastMotorReset < MOTOR_RESET_COOLDOWN then return end
    state.lastMotorReset = now

    local char = state.lplr and state.lplr.Character
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
        bg.P = 9e4; bg.maxTorque = Vector3.new(9e9,9e9,9e9); bg.cframe = currentCF
        local bv = Instance.new("BodyVelocity", root)
        bv.velocity = Vector3.new(0,0,0); bv.maxForce = Vector3.new(9e9,9e9,9e9)
        local bf = Instance.new("BodyForce", root)
        local totalMass = root.AssemblyMass
        bf.Force = Vector3.new(0, totalMass * Workspace.Gravity, 0)

        state.bg = bg
        state.bv = bv
        state.bf = bf

        hum.PlatformStand = true
        hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
        hum:ChangeState(Enum.HumanoidStateType.Physics)
    end)
end

local function startAnomalyProtection()
    if state.anomalyConn then state.anomalyConn:Disconnect(); state.anomalyConn = nil end
    state.lastKnownPos = nil
    local mySession = state.sessionToken
    state.anomalyConn = RunService.Stepped:Connect(function(_, dt)
        if state.sessionToken ~= mySession then
            if state.anomalyConn then state.anomalyConn:Disconnect(); state.anomalyConn = nil end
            state.lastKnownPos = nil
            return
        end
        if not state.enabled then
            if state.anomalyConn then state.anomalyConn:Disconnect(); state.anomalyConn = nil end
            state.lastKnownPos = nil
            return
        end
        local char = state.lplr and state.lplr.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then state.lastKnownPos = nil; return end

        local now = tick()
        local hum = char:FindFirstChildOfClass("Humanoid")
        local pos = root.Position
        state.lastKnownPos = pos

        if not hum then return end
        local humState = hum:GetState()

        local isHitboxDrop = (
            humState == Enum.HumanoidStateType.Freefall     or
            humState == Enum.HumanoidStateType.FallingDown  or
            humState == Enum.HumanoidStateType.Ragdoll      or
            humState == Enum.HumanoidStateType.GettingUp
        )
        local motorsGone = (
            not root:FindFirstChildOfClass("BodyGyro") or
            not root:FindFirstChildOfClass("BodyVelocity")
        )

        if (isHitboxDrop or motorsGone) and now - state.lastAnomalyFix > ANOMALY_COOLDOWN then
            state.lastAnomalyFix = now
            silentMotorReset()
            task.defer(function()
                if state.enabled then
                    state.ragdollDetected = false
                end
            end)
        end
    end)
end

local function stopAnomalyProtection()
    if state.anomalyConn then state.anomalyConn:Disconnect(); state.anomalyConn = nil end
    state.lastKnownPos = nil
end

local function startTeleportGuard()
    if state.teleportGuardConn then state.teleportGuardConn:Disconnect(); state.teleportGuardConn = nil end
    state.lastSafePos  = nil
    state.lastSafeTime = tick()
    state.isTeleportGuardActive = true
    local mySession = state.sessionToken

    state.teleportGuardConn = RunService.Stepped:Connect(function(_, dt)
        if state.sessionToken ~= mySession then
            if state.teleportGuardConn then state.teleportGuardConn:Disconnect(); state.teleportGuardConn = nil end
            state.isTeleportGuardActive = false
            return
        end
        if not state.enabled then
            if state.teleportGuardConn then state.teleportGuardConn:Disconnect(); state.teleportGuardConn = nil end
            state.isTeleportGuardActive = false
            return
        end
        if not state.isTeleportGuardActive then return end

        local char = state.lplr and state.lplr.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then
            state.lastSafePos = nil
            return
        end

        local pos = root.Position
        if pos.Y <= -500 then
            local safePos = state.lastSafePos
            if safePos then
                local targetCF = CFrame.new(safePos + Vector3.new(0, 5, 0))
                pcall(function()
                    root.CFrame = targetCF
                    root.AssemblyLinearVelocity  = Vector3.new(0, 0, 0)
                    root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                end)
                local cam = state.camera
                if cam then
                    local camCF = cam.CFrame
                    task.defer(function()
                        if cam and cam.Parent then cam.CFrame = camCF end
                    end)
                end
                state.dashTimer = 0
                state.dashVel   = Vector3.new(0, 0, 0)
                if not root:FindFirstChildOfClass("BodyGyro") then
                    _flyMakeMotors()
                end
            end
            return
        end

        if math.abs(pos.X) < COORD_SANITY_LIMIT and math.abs(pos.Z) < COORD_SANITY_LIMIT then
            state.lastSafePos  = pos
            state.lastSafeTime = tick()
        end
    end)
end

local function stopTeleportGuard()
    state.isTeleportGuardActive = false
    if state.teleportGuardConn then state.teleportGuardConn:Disconnect(); state.teleportGuardConn = nil end
    state.lastSafePos = nil
end

-- ============================================================
-- Sistema de aterrizaje (landing)
-- ============================================================
local function omniAntiBounceLand(hrp, hum)
    if not hrp or not hum then return end
    pcall(function()
        local v = hrp.AssemblyLinearVelocity
        hrp.AssemblyLinearVelocity  = Vector3.new(v.X, 0, v.Z)
        hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
    end)
    pcall(function()
        local _, ry, _ = hrp.CFrame:ToOrientation()
        hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, ry, 0)
    end)
end

local function startLandingWatcher()
    if state.landWatcherConn then state.landWatcherConn:Disconnect(); state.landWatcherConn = nil end
    state.landWatcherToken = state.landWatcherToken + 1
    local myToken = state.landWatcherToken

    state.landWatcherConn = RunService.Heartbeat:Connect(function()
        if not state.waitingLand then
            if state.landWatcherConn then state.landWatcherConn:Disconnect(); state.landWatcherConn = nil end
            return
        end
        if state.landWatcherToken ~= myToken then return end

        local char = state.lplr and state.lplr.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum then return end

        local velY = hrp.AssemblyLinearVelocity.Y
        if velY > -1 then return end
        local probeDistance = math.clamp(math.abs(velY) * 0.08 + 2.0, 2.0, 4.5)

        local rp = RaycastParams.new()
        rp.FilterType = Enum.RaycastFilterType.Exclude
        rp.FilterDescendantsInstances = {char}
        local hit = Workspace:Raycast(hrp.Position, Vector3.new(0, -probeDistance, 0), rp)

        if hit then
            state.waitingLand = false
            if state.landWatcherConn then state.landWatcherConn:Disconnect(); state.landWatcherConn = nil end

            pcall(function()
                for _, v in ipairs(hrp:GetChildren()) do
                    if v:IsA("BodyGyro") or v:IsA("BodyVelocity") or v:IsA("BodyForce")
                    or v:IsA("BodyAngularVelocity") or v:IsA("AlignOrientation")
                    or v:IsA("LinearVelocity") or v:IsA("AngularVelocity") then
                        v:Destroy()
                    end
                end
            end)

            omniAntiBounceLand(hrp, hum)
        end
    end)
end

local function stopLandingWatcher()
    if state.landWatcherConn then state.landWatcherConn:Disconnect(); state.landWatcherConn = nil end
    state.landWatcherToken = state.landWatcherToken + 1
end

local function doLanding(char, height, velocity)
    -- Esta función sería llamada desde _flyOff después de que el personaje aterrice.
    -- Por ahora la dejamos vacía; la lógica de animación y efectos la manejará FlyControl.
    if FlyAnim and FlyAnim.onLanding then
        FlyAnim.onLanding(height, velocity)
    end
    -- Efectos de impacto (piedras, sonido, etc.) se pueden añadir aquí o en FlyControl.
end

-- ============================================================
-- Sistema de partículas y efectos
-- ============================================================
local function createParticle(isMega)
    if state.megaTurboUpActive or state.mode == "megaup" then return end
    local char = state.lplr and state.lplr.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local cam = state.camera
    if not cam then return end
    local lookH  = Vector3.new(cam.CFrame.LookVector.X, 0, cam.CFrame.LookVector.Z)
    local rightH = Vector3.new(cam.CFrame.RightVector.X, 0, cam.CFrame.RightVector.Z)
    if lookH.Magnitude  > 0.01 then lookH = lookH.Unit else lookH = Vector3.new(0,0,-1) end
    if rightH.Magnitude > 0.01 then rightH = rightH.Unit else rightH = Vector3.new(1,0,0) end
    local moveDir = Vector3.new(0,0,0)
    if state.wDown then moveDir = moveDir + lookH end
    if state.sDown then moveDir = moveDir - lookH end
    if state.aDown then moveDir = moveDir - rightH end
    if state.dDown then moveDir = moveDir + rightH end
    if moveDir.Magnitude < 0.01 then moveDir = lookH else moveDir = moveDir.Unit end
    local spawnPos = root.Position + (-moveDir * 5)
    local awayDir  = -moveDir
    local part = Instance.new("Part")
    part.Anchored = true; part.CanCollide = false; part.CastShadow = false
    part.Transparency = 1; part.Size = Vector3.new(0.1, PARTICLE_LENGTH, 0.1)
    part.Position = spawnPos; part.Parent = Workspace
    local camPos = cam.CFrame.Position
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
    table.insert(state.particleList, part)

    local FADE_TIME = 0.42
    local fadeTween = TweenService:Create(img, TweenInfo.new(FADE_TIME, Enum.EasingStyle.Linear), {ImageTransparency = 1})
    fadeTween:Play()
    local travelDist = isMega and 14 or 8
    local targetPos  = spawnPos + awayDir * travelDist
    TweenService:Create(part, TweenInfo.new(FADE_TIME, Enum.EasingStyle.Linear), {Position = targetPos}):Play()
    fadeTween.Completed:Connect(function()
        pcall(function() if part and part.Parent then part:Destroy() end end)
        for i, p in ipairs(state.particleList) do
            if p == part then table.remove(state.particleList, i); break end
        end
    end)
    task.delay(FADE_TIME + 0.15, function()
        pcall(function() if part and part.Parent then part:Destroy() end end)
        for i, p in ipairs(state.particleList) do if p == part then table.remove(state.particleList, i); break end end
    end)
end

local function startParticleEmitter()
    if state.particleRunning then return end
    state.particleRunning = true
    state.particleConn = task.spawn(function()
        while state.enabled and (state.mode == "fast" or state.mode == "turbo") and not state.megaTurboUpActive and state.mode ~= "megaup" do
            if state.lplr and state.lplr.Character and state.lplr.Character:FindFirstChild("HumanoidRootPart") then
                local isMega = (state.mode == "turbo")
                createParticle(isMega)
                if isMega then task.wait(0.04); createParticle(true) end
            end
            task.wait(0.12)
        end
        state.particleRunning = false
        state.particleConn = nil
    end)
end

local function stopParticleEmitter()
    if state.particleConn then task.cancel(state.particleConn); state.particleConn = nil end
    state.particleRunning = false
    for _, part in ipairs(state.particleList) do
        pcall(function() part:Destroy() end)
    end
    state.particleList = {}
end

local function sonicBoomEffect(intensity)
    local char = state.lplr and state.lplr.Character
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
            local cam = state.camera
            if cam then
                local d = cam.CFrame.Position - root.Position
                if d.Magnitude > 0.1 then p.CFrame = CFrame.lookAt(root.Position, root.Position + d.Unit) end
            end
            p.Parent = Workspace
            local sg = Instance.new("SurfaceGui", p)
            sg.Adornee=p; sg.Face=Enum.NormalId.Front; sg.AlwaysOnTop=false; sg.LightInfluence=0
            sg.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud; sg.PixelsPerStud=50
            local outer = Instance.new("ImageLabel", sg)
            outer.Image=RING_ID; outer.Size=UDim2.new(1,0,1,0); outer.BackgroundTransparency=1
            outer.ImageColor3=WHITE; outer.ImageTransparency=0.06
            local innerScale = 0.72 - (i-1)*0.08
            local inner = Instance.new("ImageLabel", sg)
            inner.Image=RING_ID; inner.Size=UDim2.new(innerScale,0,innerScale,0)
            inner.Position=UDim2.new((1-innerScale)/2,0,(1-innerScale)/2,0)
            inner.BackgroundTransparency=1; inner.ImageColor3=WHITE; inner.ImageTransparency=0.20
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
        img.ImageColor3=WHITE; img.ImageTransparency=0
        TweenService:Create(bb, TweenInfo.new(0.10, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
            {Size=UDim2.new(0,peakPx,0,peakPx)}):Play()
        task.delay(0.25, function() pcall(function() bb:Destroy() end) end)
        task.wait(0.04)
        if not img or not img.Parent then return end
        TweenService:Create(img, TweenInfo.new(0.2, Enum.EasingStyle.Exponential, Enum.EasingDirection.In), {ImageTransparency=1}):Play()
    end)
end

local function airShockAura(intensity)
    local char = state.lplr and state.lplr.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local isMega = intensity == 2
    task.spawn(function()
        local bb = Instance.new("BillboardGui")
        bb.Adornee=root; bb.AlwaysOnTop=false; bb.LightInfluence=0
        bb.Size=UDim2.new(0,50,0,50); bb.ResetOnSpawn=false; bb.Parent=root
        local img = Instance.new("ImageLabel", bb)
        img.Image=AIR_SHOCK_ID; img.Size=UDim2.new(1,0,1,0); img.BackgroundTransparency=1
        img.ImageColor3=Color3.fromRGB(210,240,255); img.ImageTransparency=0.25
        local img2 = Instance.new("ImageLabel", bb)
        img2.Image=AIR_SHOCK_ID; img2.Size=UDim2.new(1.3,0,1.3,0); img2.Position=UDim2.new(-0.15,0,-0.15,0)
        img2.BackgroundTransparency=1; img2.ImageColor3=Color3.fromRGB(180,220,255); img2.ImageTransparency=0.45
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
            bb2.Size=UDim2.new(0,50,0,50); bb2.ResetOnSpawn=false; bb2.Parent=root
            local i1 = Instance.new("ImageLabel", bb2)
            i1.Image=AIR_SHOCK_ID; i1.Size=UDim2.new(1,0,1,0); i1.BackgroundTransparency=1
            i1.ImageColor3=Color3.fromRGB(220,245,255); i1.ImageTransparency=0.15; i1.Rotation=22
            local i2 = Instance.new("ImageLabel", bb2)
            i2.Image=AIR_SHOCK_ID; i2.Size=UDim2.new(1.5,0,1.5,0); i2.Position=UDim2.new(-0.25,0,-0.25,0)
            i2.BackgroundTransparency=1; i2.ImageColor3=Color3.fromRGB(190,225,255); i2.ImageTransparency=0.30; i2.Rotation=60
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

local function speedWhiteFlash(mode)
    if state.whiteFlashGui then pcall(function() state.whiteFlashGui:Destroy() end); state.whiteFlashGui = nil end
    local baseOpacity = 0.38
    local maxOpacity  = (mode == "turbo") and (baseOpacity * 1.4) or baseOpacity
    local opacity = maxOpacity  -- simplificado, se puede escalar con velocidad
    local sg = Instance.new("ScreenGui")
    sg.Name="AFO_WhiteFlash"; sg.ResetOnSpawn=false
    sg.ZIndexBehavior=Enum.ZIndexBehavior.Global; sg.IgnoreGuiInset=true
    sg.DisplayOrder=950; sg.Parent=CoreGui; state.whiteFlashGui = sg
    local frame = Instance.new("Frame", sg)
    frame.Size=UDim2.new(1,0,1,0); frame.BackgroundColor3=Color3.fromRGB(255,255,255)
    frame.BackgroundTransparency=1; frame.BorderSizePixel=0
    TweenService:Create(frame, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {BackgroundTransparency = 1 - opacity}):Play()
    task.delay(0.2, function()
        if not sg or not sg.Parent then return end
        TweenService:Create(frame, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
            {BackgroundTransparency = 1}):Play()
        task.delay(0.55, function() pcall(function() sg:Destroy() end); if state.whiteFlashGui == sg then state.whiteFlashGui = nil end end)
    end)
end

-- ============================================================
-- Sistema de Dash y movimiento
-- ============================================================
local function triggerDash(direction, speed, duration)
    local cam = state.camera
    if not cam then return end
    local dashDir
    if direction == "back"    then local l = cam.CFrame.LookVector; dashDir = Vector3.new(-l.X, 0, -l.Z)
    elseif direction == "left"  then local r = cam.CFrame.RightVector; dashDir = Vector3.new(-r.X, 0, -r.Z)
    elseif direction == "right" then local r = cam.CFrame.RightVector; dashDir = Vector3.new(r.X, 0, r.Z)
    elseif direction == "forward" then local l = cam.CFrame.LookVector; dashDir = Vector3.new(l.X, 0, l.Z)
    else return end
    if dashDir.Magnitude < 0.01 then return end
    state.dashVel   = dashDir.Unit * (speed or state.DASH_SPEED)
    state.dashTimer = duration or state.DASH_DURATION
    -- Iniciar detección de colisiones para el dash
    if state.dashCollisionConn then state.dashCollisionConn:Disconnect() end
    state.dashCollisionConn = RunService.RenderStepped:Connect(function()
        if state.dashTimer <= 0 then
            if state.dashCollisionConn then state.dashCollisionConn:Disconnect(); state.dashCollisionConn = nil end
            return
        end
        local char = state.lplr and state.lplr.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        local rootPos = root.Position
        local dashMagnitude = state.dashVel.Magnitude
        local dashDirVec = dashMagnitude > 0.01 and state.dashVel.Unit or Vector3.new(0,0,1)
        for _, otherPlayer in ipairs(Players:GetPlayers()) do
            if otherPlayer ~= state.lplr then
                local otherChar = otherPlayer.Character
                if otherChar then
                    local otherRoot = otherChar:FindFirstChild("HumanoidRootPart")
                    if otherRoot then
                        local dist = (rootPos - otherRoot.Position).Magnitude
                        if dist < 5.5 then
                            if not state.lastHitPlayers then state.lastHitPlayers = {} end
                            local now = tick()
                            local playerId = otherPlayer.UserId
                            if not state.lastHitPlayers[playerId] or now - state.lastHitPlayers[playerId] > 0.5 then
                                state.lastHitPlayers[playerId] = now
                                showHitboxMarkers(otherChar)
                                local pushDir = Vector3.new(dashDirVec.X, 0.5, dashDirVec.Z).Unit
                                local pushForce = pushDir * (dashMagnitude * 1.5)
                                otherRoot.AssemblyLinearVelocity = pushForce
                                local originalVel = state.dashVel
                                state.dashVel = state.dashVel * 0.4
                                task.delay(0.08, function()
                                    if state.dashTimer > 0 then state.dashVel = originalVel end
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

-- ============================================================
-- Sistema de frenado (brake) para lock
-- ============================================================
local function startBrakeSystem()
    if state.brakeConn then state.brakeConn:Disconnect(); state.brakeConn = nil end
    state.brakeConn = RunService.RenderStepped:Connect(function()
        if not state.enabled then return end
        if state.mode ~= "fast" and state.mode ~= "turbo" then return end
        if not state.lockActive or not state.lockedTarget then return end
        if state.dashTimer <= 0 then return end
        local char = state.lplr and state.lplr.Character
        local myRoot = char and char:FindFirstChild("HumanoidRootPart")
        if not myRoot then return end
        local targetChar = state.lockedTarget.Character
        local targetRoot = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
        if not targetRoot then return end
        local dist = (myRoot.Position - targetRoot.Position).Magnitude
        if dist <= state.BRAKE_HARD_DISTANCE then
            state.dashVel = Vector3.new(0,0,0)
            state.dashTimer = 0
            state.brakingActive = false
            showHitboxMarkers(targetChar)
        elseif dist <= state.BRAKE_DISTANCE then
            local t = 1 - ((dist - state.BRAKE_HARD_DISTANCE) / (state.BRAKE_DISTANCE - state.BRAKE_HARD_DISTANCE))
            local brakeFactor = 1 - (t * 0.92)
            state.dashVel = state.dashVel * math.max(brakeFactor, 0.05)
            state.brakingActive = true
        else
            state.brakingActive = false
        end
    end)
end

local function stopBrakeSystem()
    if state.brakeConn then state.brakeConn:Disconnect(); state.brakeConn = nil end
    state.brakingActive = false
end

-- ============================================================
-- Sistema de Lock-on (targeting)
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
    local myChar = state.lplr and state.lplr.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local cam = state.camera
    if not cam then return nil end
    for _, player in ipairs(Players:GetPlayers()) do
        if player == state.lplr then continue end
        if not isTargetValidForLock(player) then continue end
        local targetChar = player.Character
        if not targetChar then continue end
        local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
        if not targetRoot then continue end
        local screenPos, onScreen = cam:WorldToScreenPoint(targetRoot.Position)
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
    if state.lockIconGui then pcall(function() state.lockIconGui:Destroy() end); state.lockIconGui = nil end
end

local function applyLockIcon(player)
    removeLockIcon()
    local chest = player.Character and player.Character:FindFirstChild("UpperTorso")
    local torso = chest or (player.Character and player.Character:FindFirstChild("HumanoidRootPart"))
    if not torso then return end
    state.lockIconGui = Instance.new("BillboardGui", torso)
    state.lockIconGui.Name          = "LockIcon"
    state.lockIconGui.Size          = UDim2.new(0, 50, 0, 50)
    state.lockIconGui.AlwaysOnTop   = true
    state.lockIconGui.StudsOffset   = Vector3.new(0, 0, 0)
    local img = Instance.new("ImageLabel", state.lockIconGui)
    img.Size = UDim2.new(1,0,1,0); img.BackgroundTransparency = 1
    img.Image = "rbxassetid://82817965256191"
    img.ImageColor3 = Color3.fromRGB(255,255,255); img.ScaleType = Enum.ScaleType.Fit
end

local function ensureLockHighlight()
    if not state.lockHighlight then
        state.lockHighlight = Instance.new("Highlight")
        state.lockHighlight.FillTransparency    = 1
        state.lockHighlight.OutlineColor        = Color3.fromRGB(255, 255, 255)
        state.lockHighlight.OutlineTransparency = 0
    end
end

local function updateLockHighlight()
    if not state.lockActive or not state.lockedTarget then
        if state.lockHighlight then state.lockHighlight.Parent = nil end; return
    end
    if not isTargetValidForLock(state.lockedTarget) then
        if state.lockHighlight then state.lockHighlight.Parent = nil end; return
    end
    ensureLockHighlight()
    local targetChar = state.lockedTarget.Character
    if targetChar then state.lockHighlight.Parent = targetChar
    else state.lockHighlight.Parent = nil end
end

local function loadAvatarImage()
    -- Esto se puede implementar en FlyControl o en la GUI
end

local function createLockInfoGui(parentFrame)
    -- La creación de la GUI se delega a FlyControl para que use FlyText
end

local function updateLockInfoGui()
    -- Actualización de GUI se delega a FlyControl
end

local function updateLockCamera()
    if not state.lockActive or not state.lockedTarget then return end
    local targetChar = state.lockedTarget.Character
    if not targetChar then
        state.lockActive = false; state.lockedTarget = nil
        removeLockIcon(); updateLockHighlight(); return
    end
    if not isTargetValidForLock(state.lockedTarget) then
        state.lockActive = false; state.lockedTarget = nil
        removeLockIcon(); updateLockHighlight(); return
    end
    local myRoot = state.lplr.Character and state.lplr.Character:FindFirstChild("HumanoidRootPart")
    local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
    if myRoot and targetRoot and (myRoot.Position - targetRoot.Position).Magnitude > 750 then
        state.lockActive = false; state.lockedTarget = nil
        removeLockIcon(); updateLockHighlight(); return
    end
    local targetPart = targetChar:FindFirstChild("UpperTorso") or targetChar:FindFirstChild("HumanoidRootPart")
    if not targetPart then return end
    local currentPos = state.camera.CFrame.Position
    local desiredCF  = CFrame.new(currentPos, targetPart.Position)
    local lerpFactor = state.lockCameraLerp
    if myRoot then
        local worldDist = (myRoot.Position - targetPart.Position).Magnitude
        if worldDist < 8  then lerpFactor = lerpFactor * 0.25
        elseif worldDist < 20 then lerpFactor = lerpFactor * 0.6 end
    end
    state.camera.CFrame = state.camera.CFrame:Lerp(desiredCF, lerpFactor)
end

local function toggleLock()
    if not state.enabled then return end
    if not state.lockActive then
        local found = getClosestLockTarget()
        if found and isTargetValidForLock(found) then
            state.lockedTarget = found
            state.lockActive   = true
            applyLockIcon(found)
            updateLockHighlight()
            loadAvatarImage()
        end
    else
        state.lockActive   = false
        state.lockedTarget = nil
        removeLockIcon()
        updateLockHighlight()
    end
end

local function startLockSystem()
    if state.lockConn then state.lockConn:Disconnect(); state.lockConn = nil end
    if state.lockRenderConn then state.lockRenderConn:Disconnect(); state.lockRenderConn = nil end
    state.lockConn = UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe or isTyping() then return end
        if input.KeyCode == state.lockKey then toggleLock() end
    end)
    state.lockRenderConn = RunService.RenderStepped:Connect(function()
        updateLockCamera()
        updateLockHighlight()
        -- updateLockInfoGui se hará desde FlyControl
    end)
end

local function stopLockSystem()
    if state.lockConn then state.lockConn:Disconnect(); state.lockConn = nil end
    if state.lockRenderConn then state.lockRenderConn:Disconnect(); state.lockRenderConn = nil end
    state.lockActive = false
    state.lockedTarget = nil
    removeLockIcon()
    if state.lockHighlight then state.lockHighlight:Destroy(); state.lockHighlight = nil end
end

-- ============================================================
-- Mega Turbo Up (lógica independiente, sin partículas)
-- ============================================================
local function activateMegaTurboUp()
    if state.mode == "turbo" then return end
    if state.megaTurboUpActive then return end
    state.megaTurboUpActive = true
    state.mode = "megaup"
    -- Aplicar impulso vertical
    local char = state.lplr and state.lplr.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if root then
        root.AssemblyLinearVelocity = Vector3.new(0, BASE_SPEED * TURBO_MULT * 0.8, 0)
    end
    -- Efectos
    playLocalSound(SFX_MEGA_TURBO, 0.90)
    sonicBoomEffect(2)
    airShockAura(2)
    speedWhiteFlash("turbo")
    -- Cerrar brazos (delegado a FlyAnim)
    if FlyAnim and FlyAnim.onMegaTurboUpActivated then
        FlyAnim.onMegaTurboUpActivated()
    end
    -- Iniciar loop de mantenimiento (solo ajusta velocidad)
    if state.megaUpLoopConn then state.megaUpLoopConn:Disconnect() end
    local startT = os.clock()
    state.megaUpLoopConn = RunService.Heartbeat:Connect(function()
        if not state.megaTurboUpActive or not state.enabled then
            if state.megaUpLoopConn then state.megaUpLoopConn:Disconnect(); state.megaUpLoopConn = nil end
            return
        end
        if os.clock() - startT > 4.0 then
            state.megaTurboUpActive = false
            state.mode = "normal"
            if state.bv then
                state.speed = BASE_SPEED
            end
            if state.megaUpLoopConn then state.megaUpLoopConn:Disconnect(); state.megaUpLoopConn = nil end
            return
        end
        if state.bv then
            state.speed = BASE_SPEED * TURBO_MULT
        end
    end)
end

local function deactivateMegaTurboUp()
    state.megaTurboUpActive = false
    if state.mode == "megaup" then state.mode = "normal" end
    if state.megaUpLoopConn then state.megaUpLoopConn:Disconnect(); state.megaUpLoopConn = nil end
    -- Cerrar partículas ya no se necesita porque no se emitieron
end

-- ============================================================
-- Ciclo principal de vuelo (RenderStepped y movimiento)
-- ============================================================
local function startFlyMovement()
    if state.rsConn then state.rsConn:Disconnect() end
    local mySession = state.sessionToken
    state.rsConn = RunService.RenderStepped:Connect(function(dt)
        if state.sessionToken ~= mySession then
            state.rsConn:Disconnect(); state.rsConn = nil; return
        end
        if not state.enabled then
            state.rsConn:Disconnect(); state.rsConn = nil; return
        end
        local char = state.lplr and state.lplr.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if not root or not hum then return end

        -- Verificar posición absurda
        local pos = root.Position
        if math.abs(pos.Y) > COORD_SANITY_LIMIT or math.abs(pos.X) > COORD_SANITY_LIMIT or math.abs(pos.Z) > COORD_SANITY_LIMIT then
            return
        end

        if not root:FindFirstChildOfClass("BodyGyro") or not root:FindFirstChildOfClass("BodyVelocity")
        or hum:GetState() == Enum.HumanoidStateType.Ragdoll then
            _flyMakeMotors()
            return
        end
        state.bg = root:FindFirstChild("BodyGyro")
        state.bv = root:FindFirstChild("BodyVelocity")
        state.bf = root:FindFirstChild("BodyForce")

        updateAntiGravityForce()

        local angularSpeed = root.AssemblyAngularVelocity.Magnitude
        if angularSpeed > 25 and not state.gyroProtectionActive then activateGyroProtection() end

        local cam = state.camera
        if not cam then return end
        local typing = isTyping()
        local wD = not typing and UserInputService:IsKeyDown(Enum.KeyCode.W)
        local sD = not typing and UserInputService:IsKeyDown(Enum.KeyCode.S)
        local aD = not typing and UserInputService:IsKeyDown(Enum.KeyCode.A)
        local dD = not typing and UserInputService:IsKeyDown(Enum.KeyCode.D)
        state.wDown = wD; state.sDown = sD; state.aDown = aD; state.dDown = dD

        if state.bv then state.bv.velocity = Vector3.new(0, 0, 0) end

        if state.lockActive and state.lockedTarget then
            local tChar = state.lockedTarget.Character
            if tChar and isTargetValidForLock(state.lockedTarget) then
                local aimPart = tChar:FindFirstChild("UpperTorso") or tChar:FindFirstChild("HumanoidRootPart")
                if aimPart then
                    local desiredCF = CFrame.lookAt(root.Position, aimPart.Position, Vector3.new(0,1,0))
                    local smooth = LOCK_ROTATION_SMOOTH * (1 + math.min(0.5, (state.dashVel.Magnitude / 300)))
                    state.bg.cframe = state.bg.cframe:Lerp(desiredCF, smooth)
                else
                    state.lockActive = false; state.lockedTarget = nil; removeLockIcon(); updateLockHighlight()
                end
            else
                state.lockActive = false; state.lockedTarget = nil; removeLockIcon(); updateLockHighlight()
            end
        else
            local moveDir = Vector3.new()
            if wD then moveDir = moveDir + cam.CFrame.LookVector end
            if sD then moveDir = moveDir - cam.CFrame.LookVector end
            if aD then moveDir = moveDir - cam.CFrame.RightVector end
            if dD then moveDir = moveDir + cam.CFrame.RightVector end
            local targetCFrame
            local isFastMode = (state.mode == "fast" or state.mode == "turbo")
            if isFastMode and moveDir.Magnitude > 0.01 then
                targetCFrame = CFrame.lookAt(root.Position, root.Position + moveDir.Unit)
            else
                targetCFrame = cam.CFrame
            end
            local smoothingFactor
            if isFastMode then
                local angleDiff = 0
                pcall(function()
                    local currentLook = state.bg.cframe.LookVector
                    local desiredLook = targetCFrame.LookVector
                    local dot = math.clamp(currentLook:Dot(desiredLook), -1, 1)
                    angleDiff = math.acos(dot)
                end)
                local t_angle = math.clamp(1 - (angleDiff / math.pi), 0, 1)
                smoothingFactor = 0.04 + (t_angle * t_angle) * 0.14
                smoothingFactor = math.clamp(smoothingFactor * (1 + dt * 8), 0, 0.20)
            else
                smoothingFactor = math.clamp(dt * 10, 0, 1)
            end
            state.bg.cframe = state.bg.cframe:Lerp(targetCFrame, smoothingFactor)
        end

        if state.dashTimer > 0 then
            state.dashTimer = state.dashTimer - dt
            if state.dashTimer <= 0 then
                state.dashTimer = 0
                state.dashVel = Vector3.new(0,0,0)
                if state.dashCollisionConn then state.dashCollisionConn:Disconnect(); state.dashCollisionConn = nil end
            else
                state.dashVel = state.dashVel:Lerp(Vector3.new(0,0,0), math.clamp(dt*9, 0, 1))
            end
        end

        -- Capturar velocidad para landing
        local velY = root.AssemblyLinearVelocity.Y
        if velY < -10 then
            state.landingVelocity = math.abs(velY)
            if math.abs(velY) > state.landingVelocityCapture then
                state.landingVelocityCapture = math.abs(velY)
            end
        end
    end)
end

local function startMovementTranslation()
    if state.tpMoveConn then state.tpMoveConn:Disconnect(); state.tpMoveConn = nil end
    local mySession = state.sessionToken
    state.tpMoveConn = RunService.Stepped:Connect(function(_, dt)
        if state.sessionToken ~= mySession then
            state.tpMoveConn:Disconnect(); state.tpMoveConn = nil; return
        end
        if not state.enabled then
            state.tpMoveConn:Disconnect(); state.tpMoveConn = nil; return
        end
        local char = state.lplr and state.lplr.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then return end

        local pos = root.Position
        if math.abs(pos.Y) > COORD_SANITY_LIMIT or math.abs(pos.X) > COORD_SANITY_LIMIT or math.abs(pos.Z) > COORD_SANITY_LIMIT then
            return
        end

        local cam = state.camera
        if not cam then return end
        local typing = isTyping()
        local wD = not typing and UserInputService:IsKeyDown(Enum.KeyCode.W)
        local sD = not typing and UserInputService:IsKeyDown(Enum.KeyCode.S)
        local aD = not typing and UserInputService:IsKeyDown(Enum.KeyCode.A)
        local dD = not typing and UserInputService:IsKeyDown(Enum.KeyCode.D)
        local spaceDown = not typing and UserInputService:IsKeyDown(Enum.KeyCode.Space)
        local ctrlDown  = not typing and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)

        -- Noclip para Ctrl
        if ctrlDown and state.noclipCtrlEnabled and not state.noclipCtrlActive then
            state.noclipCtrlActive = true
            setNoclip(true)
        elseif not ctrlDown and state.noclipCtrlActive then
            state.noclipCtrlActive = false
            local megaActive = (state.mode == "turbo") and state.noclipMegaEnabled
            if not state.noclipSpaceActive and not megaActive then
                setNoclip(false)
            end
        end

        local move = Vector3.new()
        if wD then move = move + cam.CFrame.LookVector end
        if sD then move = move - cam.CFrame.LookVector end
        if aD then move = move - cam.CFrame.RightVector end
        if dD then move = move + cam.CFrame.RightVector end

        if (state.mode == "fast" or state.mode == "turbo") and state.lockActive and state.lockedTarget and wD then
            local targetChar = state.lockedTarget.Character
            if targetChar then
                local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
                if targetRoot then
                    local noFloor = false
                    do
                        local rpCheck = RaycastParams.new()
                        rpCheck.FilterType = Enum.RaycastFilterType.Exclude
                        local cc = state.lplr.Character
                        if cc then rpCheck.FilterDescendantsInstances = {cc} end
                        local hitCheck = Workspace:Raycast(root.Position, Vector3.new(0, -5, 0), rpCheck)
                        noFloor = (hitCheck == nil)
                    end
                    local heightDiff = targetRoot.Position.Y - root.Position.Y
                    if noFloor and heightDiff > 10 and state.enabled then
                        local toTarget = targetRoot.Position - root.Position
                        local newPos = targetRoot.Position - (toTarget.Unit * 5)
                        pcall(function() root.CFrame = CFrame.new(newPos, targetRoot.Position) end)
                    end

                    local toTarget3D = targetRoot.Position - root.Position
                    local horDist2   = Vector3.new(toTarget3D.X, 0, toTarget3D.Z).Magnitude
                    local vertDiff   = math.abs(toTarget3D.Y)
                    if horDist2 < 25 and vertDiff > 8 then
                        if toTarget3D.Magnitude > 0.1 then
                            move = toTarget3D.Unit * move.Magnitude
                            if move.Magnitude < 0.01 then move = toTarget3D.Unit end
                        end
                    else
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
        end

        if state.megaTurboUpActive then move = move + Vector3.new(0,2,0)
        elseif spaceDown then move = move + Vector3.new(0,1,0) end
        if ctrlDown then move = move - Vector3.new(0,1,0) end

        if spaceDown and not state.megaTurboUpActive then
            fixUndergroundOrientation()
        end

        if move.Magnitude > 0.01 then
            local actualSpeed = state.speed
            if state.dashTimer > 0 then actualSpeed = actualSpeed + state.dashVel.Magnitude end
            local translation = move.Unit * actualSpeed * dt
            pcall(function() char:TranslateBy(translation) end)
        elseif state.dashTimer > 0 and state.dashVel.Magnitude > 0.1 then
            local translation = state.dashVel.Unit * state.dashVel.Magnitude * dt
            pcall(function() char:TranslateBy(translation) end)
        end
    end)
end

-- ============================================================
-- API PÚBLICA
-- ============================================================
local FlyLogic = {}

function FlyLogic.init(lplr, camera, flyAnimModule)
    state.lplr   = lplr
    state.camera = camera
    FlyAnim = flyAnimModule
end

function FlyLogic.start()
    if state.enabled then return end
    local char = state.lplr and state.lplr.Character
    if not char then return end

    -- Incrementar token de sesión
    state.sessionToken = state.sessionToken + 1

    -- Reiniciar estado
    state.enabled = true
    state.mode = "normal"
    state.speed = BASE_SPEED
    state.wDown = false; state.sDown = false; state.aDown = false; state.dDown = false
    state.dashTimer = 0
    state.dashVel = Vector3.new(0,0,0)
    state.megaTurboUpActive = false
    state.noclipSpaceActive = false
    state.noclipCtrlActive = false
    state.waitingLand = false
    state.landingHeight = nil
    state.landingVelocity = 0
    state.landingVelocityCapture = 0
    state.brakingActive = false
    state.gyroProtectionActive = false
    if state.gyroProtectionTimer then task.cancel(state.gyroProtectionTimer) end
    if state.backupGyro then state.backupGyro:Destroy(); state.backupGyro = nil end

    -- Crear motores
    _flyMakeMotors()

    -- Iniciar sistemas
    startFlyMovement()
    startMovementTranslation()
    startAntiImpulse()
    startAnomalyProtection()
    startTeleportGuard()
    startLockSystem()
    startBrakeSystem()
    -- startParticleEmitter se activará al cambiar a modo fast/turbo
end

function FlyLogic.stop()
    if not state.enabled then return end
    local char = state.lplr and state.lplr.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")

    -- Medir altura para landing
    local heightFromGround = 0
    if char and root then
        local rp = RaycastParams.new()
        rp.FilterType = Enum.RaycastFilterType.Exclude
        rp.FilterDescendantsInstances = {char}
        local rayResult = Workspace:Raycast(root.Position, Vector3.new(0, -500, 0), rp)
        if rayResult then
            heightFromGround = root.Position.Y - rayResult.Position.Y
        else
            heightFromGround = 999
        end
    end
    state.landingHeight = heightFromGround

    -- Marcar como desactivado
    state.enabled = false
    state.dashTimer = 0
    state.dashVel = Vector3.new(0,0,0)

    -- Desconectar conexiones
    if state.rsConn then state.rsConn:Disconnect(); state.rsConn = nil end
    if state.tpMoveConn then state.tpMoveConn:Disconnect(); state.tpMoveConn = nil end
    if state.antiImpulseConn then state.antiImpulseConn:Disconnect(); state.antiImpulseConn = nil end
    if state.anomalyConn then state.anomalyConn:Disconnect(); state.anomalyConn = nil end
    if state.teleportGuardConn then state.teleportGuardConn:Disconnect(); state.teleportGuardConn = nil end
    if state.brakeConn then state.brakeConn:Disconnect(); state.brakeConn = nil end
    if state.dashCollisionConn then state.dashCollisionConn:Disconnect(); state.dashCollisionConn = nil end
    if state.megaUpLoopConn then state.megaUpLoopConn:Disconnect(); state.megaUpLoopConn = nil end
    if state.lockConn then state.lockConn:Disconnect(); state.lockConn = nil end
    if state.lockRenderConn then state.lockRenderConn:Disconnect(); state.lockRenderConn = nil end
    if state.gyroProtectionTimer then task.cancel(state.gyroProtectionTimer) end
    if state.backupGyro then state.backupGyro:Destroy(); state.backupGyro = nil end

    -- Limpiar partículas
    stopParticleEmitter()

    -- Eliminar motores y restaurar colisiones
    if root then
        cleanupMotors(root, true)
        setNoclip(false)
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = true end
        end
        -- Alinear orientación
        local _, ry, _ = root.CFrame:ToOrientation()
        pcall(function()
            root.CFrame = CFrame.new(root.Position) * CFrame.Angles(0, ry, 0)
            root.AssemblyAngularVelocity = Vector3.new(0,0,0)
            local velY = root.AssemblyLinearVelocity.Y
            root.AssemblyLinearVelocity = Vector3.new(0, velY, 0)
        end)
    end

    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.StrafingNoPhysics, false)
        hum.PlatformStand = false
        hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
        hum:ChangeState(Enum.HumanoidStateType.Freefall)

        task.delay(0.12, function()
            if hum and hum.Parent then
                if hum:GetState() == Enum.HumanoidStateType.GettingUp then
                    pcall(function() hum:ChangeState(Enum.HumanoidStateType.Freefall) end)
                end
                hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
                hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
                hum:SetStateEnabled(Enum.HumanoidStateType.StrafingNoPhysics, true)
            end
        end)
    end

    -- Manejar aterrizaje si altura suficiente
    if heightFromGround >= 10 then
        state.waitingLand = true
        startLandingWatcher()
        if hum then
            if state.landConn then state.landConn:Disconnect() end
            state.landConn = hum.StateChanged:Connect(function(_, newState)
                if not state.waitingLand then
                    if state.landConn then state.landConn:Disconnect(); state.landConn = nil end
                    return
                end
                if newState == Enum.HumanoidStateType.Landed
                or newState == Enum.HumanoidStateType.Running
                or newState == Enum.HumanoidStateType.RunningNoPhysics
                or newState == Enum.HumanoidStateType.Dead then
                    state.waitingLand = false
                    stopLandingWatcher()
                    doLanding(char, heightFromGround, math.max(state.landingVelocity, state.landingVelocityCapture))
                    if state.landConn then state.landConn:Disconnect(); state.landConn = nil end
                end
            end)
            task.delay(10, function()
                if state.waitingLand then
                    state.waitingLand = false
                    stopLandingWatcher()
                    if state.landConn then state.landConn:Disconnect(); state.landConn = nil end
                end
            end)
        end
    else
        if hum then
            hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
            hum.PlatformStand = false
            pcall(function() hum:ChangeState(Enum.HumanoidStateType.Running) end)
        end
    end

    -- Limpiar lock
    stopLockSystem()
    removeLockIcon()
    if state.lockHighlight then state.lockHighlight:Destroy(); state.lockHighlight = nil end
end

function FlyLogic.setMode(newMode)
    if not state.enabled then return end
    local oldMode = state.mode
    if newMode == oldMode then return end

    if newMode == "normal" then
        state.mode = "normal"
        state.speed = BASE_SPEED
        if state.megaTurboUpActive then deactivateMegaTurboUp() end
        stopParticleEmitter()
        setNoclip(false)
    elseif newMode == "fast" then
        state.mode = "fast"
        state.speed = BASE_SPEED * FAST_MULT
        if state.megaTurboUpActive then deactivateMegaTurboUp() end
        startParticleEmitter()
        if state.noclipMegaEnabled then setNoclip(false) else setNoclip(false) end
    elseif newMode == "turbo" then
        state.mode = "turbo"
        state.speed = BASE_SPEED * TURBO_MULT
        if state.megaTurboUpActive then deactivateMegaTurboUp() end
        startParticleEmitter()
        if state.noclipMegaEnabled then setNoclip(true) end
    elseif newMode == "megaup" then
        activateMegaTurboUp()
    end
end

function FlyLogic.getMode()
    return state.mode
end

function FlyLogic.setBaseSpeed(value)
    BASE_SPEED = math.clamp(value, 1, 10000)
    state.speed = (state.mode == "normal") and BASE_SPEED or
                  (state.mode == "fast") and BASE_SPEED * FAST_MULT or
                  (state.mode == "turbo") and BASE_SPEED * TURBO_MULT or BASE_SPEED
end

function FlyLogic.setFastMult(value)
    FAST_MULT = math.clamp(value, 1, 1000)
    if state.mode == "fast" then state.speed = BASE_SPEED * FAST_MULT end
end

function FlyLogic.setTurboMult(value)
    TURBO_MULT = math.clamp(value, 1, 1000)
    if state.mode == "turbo" then state.speed = BASE_SPEED * TURBO_MULT end
end

function FlyLogic.resetSpeeds()
    BASE_SPEED = DEFAULT_BASE
    FAST_MULT = DEFAULT_FAST
    TURBO_MULT = DEFAULT_TURBO
    state.speed = (state.mode == "normal") and BASE_SPEED or
                  (state.mode == "fast") and BASE_SPEED * FAST_MULT or
                  (state.mode == "turbo") and BASE_SPEED * TURBO_MULT or BASE_SPEED
end

function FlyLogic.getBaseSpeed() return BASE_SPEED end
function FlyLogic.getFastMult() return FAST_MULT end
function FlyLogic.getTurboMult() return TURBO_MULT end

function FlyLogic.onQPress()
    if not state.enabled then return end
    if isTyping() then return end

    local w = UserInputService:IsKeyDown(Enum.KeyCode.W)
    local s = UserInputService:IsKeyDown(Enum.KeyCode.S)
    local a = UserInputService:IsKeyDown(Enum.KeyCode.A)
    local d = UserInputService:IsKeyDown(Enum.KeyCode.D)

    if not w then
        if s and not a and not d then
            triggerDash("back", state.BACK_DASH_SPEED, state.DASH_DURATION * 1.2)
            return
        end
        if a and not s and not d then
            triggerDash("left", state.SIDE_DASH_SPEED, state.DASH_DURATION)
            return
        end
        if d and not s and not a then
            triggerDash("right", state.SIDE_DASH_SPEED, state.DASH_DURATION)
            return
        end
    end

    if state.mode == "fast" then
        -- Activar Mega Turbo (turbo)
        if FlyAnim and FlyAnim.getMode and FlyAnim.getMode() == "fast" then
            -- Solo si está en modo fast
            local elapsed = tick() - (state.lastTurboActivation or 0)
            if elapsed >= 0.75 then
                state.lastTurboActivation = tick()
                -- Cambiar a modo turbo
                FlyLogic.setMode("turbo")
                -- Efectos adicionales
                shakeCamera(3.5, 0.4)
                playLocalSound(SFX_MEGA_TURBO, 0.88)
                sonicBoomEffect(2)
                airShockAura(2)
                speedWhiteFlash("turbo")
                triggerDash("forward", state.TURBO_DASH_SPEED * 1.5, state.TURBO_DASH_DURATION * 1.2)
            end
        end
        return
    end

    if state.mode == "normal" then
        -- Cambiar a modo fast
        state.lastTurboActivation = tick()
        FlyLogic.setMode("fast")
        shakeCamera(2.0, 0.3)
        playLocalSound(SFX_TURBO, 0.82)
        sonicBoomEffect(1)
        airShockAura(1)
        speedWhiteFlash("fast")
        triggerDash("forward", state.TURBO_DASH_SPEED, state.TURBO_DASH_DURATION)
    end
end

function FlyLogic.onSpacePress()
    if not state.enabled then return end
    if state.mode == "normal" then
        -- Activar noclip de espacio (si está habilitado)
        if state.noclipSpaceEnabled and not state.noclipSpaceActive then
            state.noclipSpaceActive = true
            setNoclip(true)
        end
        -- Notificar a FlyAnim
        if FlyAnim and FlyAnim.onSpacePress then FlyAnim.onSpacePress() end
    end
    -- Manejar Mega Turbo Up (mantener espacio 2 segundos)
    if (state.mode == "normal" or state.mode == "fast") and not state.megaTurboUpActive then
        if not state.spaceHoldStart then state.spaceHoldStart = tick() end
        if tick() - state.spaceHoldStart >= state.SPACE_HOLD_TIME then
            state.spaceHoldStart = nil
            FlyLogic.setMode("megaup")
        end
    end
end

function FlyLogic.onSpaceRelease()
    if state.enabled then
        if state.noclipSpaceActive then
            state.noclipSpaceActive = false
            if not state.noclipCtrlActive and not (state.mode == "turbo" and state.noclipMegaEnabled) then
                setNoclip(false)
            end
        end
        state.spaceHoldStart = nil
        if FlyAnim and FlyAnim.onSpaceRelease then FlyAnim.onSpaceRelease() end
    end
end

function FlyLogic.onCtrlPress()
    if not state.enabled then return end
    if state.noclipCtrlEnabled and not state.noclipCtrlActive then
        state.noclipCtrlActive = true
        setNoclip(true)
    end
end

function FlyLogic.onCtrlRelease()
    if state.enabled then
        state.noclipCtrlActive = false
        if not state.noclipSpaceActive and not (state.mode == "turbo" and state.noclipMegaEnabled) then
            setNoclip(false)
        end
    end
end

function FlyLogic.setFlyKey(key)
    state.flyKey = key
end

function FlyLogic.setLockKey(key)
    state.lockKey = key
    if state.lockConn then
        -- Reconectar lock system con nueva tecla
        stopLockSystem()
        startLockSystem()
    end
end

function FlyLogic.getFlyKey() return state.flyKey end
function FlyLogic.getLockKey() return state.lockKey end
function FlyLogic.isEnabled() return state.enabled end

-- Funciones de noclip para toggle en GUI
function FlyLogic.setNoclipSpace(enabled)
    state.noclipSpaceEnabled = enabled
    if not enabled and state.noclipSpaceActive then
        state.noclipSpaceActive = false
        if not state.noclipCtrlActive and not (state.mode == "turbo" and state.noclipMegaEnabled) then
            setNoclip(false)
        end
    end
end

function FlyLogic.setNoclipCtrl(enabled)
    state.noclipCtrlEnabled = enabled
    if not enabled and state.noclipCtrlActive then
        state.noclipCtrlActive = false
        if not state.noclipSpaceActive and not (state.mode == "turbo" and state.noclipMegaEnabled) then
            setNoclip(false)
        end
    end
end

function FlyLogic.setNoclipMega(enabled)
    state.noclipMegaEnabled = enabled
    if state.mode == "turbo" then
        if enabled then setNoclip(true) elseif not state.noclipSpaceActive and not state.noclipCtrlActive then setNoclip(false) end
    end
end

function FlyLogic.getNoclipSpace() return state.noclipSpaceEnabled end
function FlyLogic.getNoclipCtrl() return state.noclipCtrlEnabled end
function FlyLogic.getNoclipMega() return state.noclipMegaEnabled end

return FlyLogic
