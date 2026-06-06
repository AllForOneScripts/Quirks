print("version 1.68 - Fully Polished")

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui          = game:GetService("CoreGui")
local SoundService     = game:GetService("SoundService")

-- ══════════════════════════════════════════════
-- SISTEMA DE IDIOMA (Espejo del hub All For One)
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

local lplr   = Players.LocalPlayer
local camera = workspace.CurrentCamera

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
    bloqueo         = "rbxassetid://107456513",
}

local SFX_TURBO        = "rbxassetid://137455842313478"
local SFX_MEGA_TURBO   = "rbxassetid://111391583223900"
local SFX_LANDING      = "rbxassetid://135226467234227"
local SMOKE_RING_TEX   = "rbxassetid://137805272670926"

local BASE_SPEED    = 60
local FAST_MULT     = 3.0
local TURBO_MULT    = 6.0
local COORD_SANITY_LIMIT = 50000

local flyanim = {
    enabled     = false,
    speed       = BASE_SPEED,
    flyKey      = Enum.KeyCode.C,
    lockKey     = Enum.KeyCode.X,
    bg          = nil,
    bv          = nil,
    bf          = nil,
    rsConn      = nil,
    animator    = nil,
    tracks      = {},
    mode        = "normal",
    qLastPress  = 0,
    idleTimer   = nil,
    isMoving    = false,
    wDown = false, sDown = false, aDown = false, dDown = false,
    waitingLand = false,
    landConn    = nil,
    landingVelocity = 0,
    
    SPACE_HOLD_TIME   = 2,
    spaceHoldStart    = nil,
    megaTurboUpConn   = nil,
    megaTurboUpActive = false,
    
    lockActive      = false,
    lockedTarget    = nil,
    lockIconGui     = nil,
    lockInfoGui     = nil,
    lockHighlight   = nil,
    
    particleRunning = false,
    particleConn    = nil,
    particleList    = {},
    
    antiImpulseConn   = nil,
    teleportGuardConn = nil,
    lastSafePos       = nil,
    sessionToken      = 0,
    
    blockTrack      = nil,
    isBlocking      = false,
    blockRenderConn = nil,
    damageConn      = nil,
    fKeyHeld        = false,
    
    rootJoint       = nil,
    originalC0      = nil,
    c0HeightToken   = 0,
    c0HeightConn    = nil,
}

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

-- ============================================================
-- FIX 1: LIMPIEZA DE MOTORES (CORRECCIÓN TOTAL DE RUBBERBANDING)
-- ============================================================
local function cleanupMotors(root, preserveVelY)
    if not root then return end
    for _, v in ipairs(root:GetChildren()) do
        if v:IsA("BodyGyro") or v:IsA("BodyVelocity") or v:IsA("BodyPosition")
        or v:IsA("BodyAngularVelocity") or v:IsA("BodyForce")
        or v:IsA("AlignOrientation") or v:IsA("LinearVelocity") then
            pcall(function() v:Destroy() end)
        end
    end
    
    -- SOLUCIÓN DIRECTA: Forzar al Humanoid a salir de PlatformStand/Physics
    -- Esto sincroniza el NetworkOwnership de Roblox y previene que te tire TP hacia arriba.
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
    flyanim.bf.Force = Vector3.new(0, totalMass * workspace.Gravity, 0)
end

-- ============================================================
-- FIX 2: PARTÍCULA DE CAÍDA (CORRECCIÓN DE HUMO PERSISTENTE)
-- ============================================================
local function spawnLandingEffects(groundPos, velocity)
    local t = math.clamp((math.abs(velocity) - 40) / 100, 0, 1)
    local smokeScale = 1 + t * 4
    local smokeDuration = 1.2 + t * 0.8
    local smokeAlphaStart = 0.2 + t * 0.3
    local DUST_COLOR = Color3.fromRGB(215, 200, 185)

    playLocalSound(SFX_LANDING, 0.7 + t * 0.3)

    -- ── CAPA 1: Anillo de humo principal arreglado ──
    task.spawn(function()
        local ringSize = smokeScale * 10
        local p = Instance.new("Part")
        p.Anchored = true; p.CanCollide = false; p.CanTouch = false; p.CastShadow = false
        p.Transparency = 1; p.Size = Vector3.new(ringSize, ringSize, 0.05)
        p.CFrame = CFrame.new(groundPos + Vector3.new(0, 0.14, 0)) * CFrame.Angles(math.rad(90), 0, 0)
        p.Parent = workspace
        
        local sg = Instance.new("SurfaceGui", p)
        sg.Adornee = p; sg.Face = Enum.NormalId.Front
        sg.LightInfluence = 0; sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud; sg.PixelsPerStud = 40
        
        local img = Instance.new("ImageLabel", sg)
        img.Image = SMOKE_RING_TEX; img.Size = UDim2.new(1,0,1,0); img.BackgroundTransparency = 1
        img.ImageColor3 = DUST_COLOR; img.ImageTransparency = smokeAlphaStart; img.ScaleType = Enum.ScaleType.Fit
        
        local peakSize = ringSize * (3.2 + t * 2.5)
        
        -- Ejecución explícita de Tweens y aseguramiento de borrado por completo
        local sizeTween = TweenService:Create(p, TweenInfo.new(smokeDuration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = Vector3.new(peakSize, peakSize, 0.05)})
        local fadeTween = TweenService:Create(img, TweenInfo.new(smokeDuration, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {ImageTransparency = 1})
        
        sizeTween:Play()
        fadeTween:Play()
        
        task.delay(smokeDuration + 0.1, function()
            pcall(function() p:Destroy() end)
        end)
    end)

    -- ── CAPA 2: Ondas de choque secundarias rápidas ──
    task.spawn(function()
        for i = 1, 2 do
            task.spawn(function()
                local p = Instance.new("Part")
                p.Anchored = true; p.CanCollide = false; p.CanTouch = false; p.CastShadow = false
                p.Transparency = 1; p.Size = Vector3.new(2, 2, 0.05)
                p.CFrame = CFrame.new(groundPos + Vector3.new(0, 0.08 + i*0.02, 0)) * CFrame.Angles(math.rad(90), 0, 0)
                p.Parent = workspace
                local sg = Instance.new("SurfaceGui", p)
                sg.Face = Enum.NormalId.Front; sg.LightInfluence = 0
                local img = Instance.new("ImageLabel", sg)
                img.Image = SMOKE_RING_TEX; img.Size = UDim2.new(1,0,1,0); img.BackgroundTransparency = 1
                img.ImageColor3 = DUST_COLOR; img.ImageTransparency = 0.1
                
                local waveDur = 0.4 + (i * 0.15)
                local waveTargetSize = 15 + (i * 12) * smokeScale
                
                TweenService:Create(p, TweenInfo.new(waveDur, Enum.EasingStyle.OutQuad), {Size = Vector3.new(waveTargetSize, waveTargetSize, 0.05)}):Play()
                TweenService:Create(img, TweenInfo.new(waveDur, Enum.EasingStyle.InQuad), {ImageTransparency = 1}):Play()
                
                task.delay(waveDur + 0.05, function() pcall(function() p:Destroy() end) end)
            end)
            task.wait(0.06)
        end
    end)

    -- ── CAPA 3: Rocas del suelo saltando ──
    task.spawn(function()
        local numRocks = math.floor(8 + t * 15)
        for i = 1, numRocks do
            task.spawn(function()
                local rock = Instance.new("Part")
                rock.Size = Vector3.new(0.3 + math.random()*0.4, 0.2 + math.random()*0.3, 0.3 + math.random()*0.4)
                rock.Material = Enum.Material.Rock
                rock.Color = Color3.fromRGB(110, 105, 100)
                rock.CanCollide = true
                local angle = math.random() * math.pi * 2
                local radius = 0.2 + math.random() * 0.6
                rock.CFrame = CFrame.new(groundPos.X + math.cos(angle)*radius, groundPos.Y + 0.05, groundPos.Z + math.sin(angle)*radius)
                rock.Parent = workspace
                
                local outDir = Vector3.new(math.cos(angle), 0.6 + math.random()*0.8, math.sin(angle)).Unit
                rock.AssemblyLinearVelocity = outDir * ((4 + t * 8) * (0.7 + math.random()*0.5))
                
                task.delay(1.2, function()
                    if not rock or not rock.Parent then return end
                    TweenService:Create(rock, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Transparency = 1}):Play()
                    task.delay(0.45, function() pcall(function() rock:Destroy() end) end)
                end)
            end)
        end
    end)
end

-- ============================================================
-- FIX 3: SISTEMA DE EMISIÓN DE PARTICULAS (BLINDAJE DE MEGA UP)
-- ============================================================
local function createParticle(isMega)
    -- SOLUCIÓN DIRECTA: Bloqueo radical si el modo activo o la flag es Mega Up
    if flyanim.megaTurboUpActive or flyanim.mode == "megaup" then return end
    
    local char = lplr.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    local p = Instance.new("Part")
    p.Anchored = true; p.CanCollide = false; p.CanTouch = false; p.CanQuery = false; p.CastShadow = false
    p.Size = Vector3.new(0.5, 0.5, 0.5); p.Transparency = 1
    p.CFrame = root.CFrame * CFrame.new(0, -2, 0)
    p.Parent = workspace
    
    local pe = Instance.new("ParticleEmitter")
    pe.Texture = isMega and "rbxassetid://129423030" or "rbxassetid://137805272670926"
    pe.Color = ColorSequence.new(isMega and Color3.fromRGB(255, 100, 255) or Color3.fromRGB(200, 200, 200))
    pe.Rate = 45; pe.Speed = NumberRange.new(5, 9); pe.Lifetime = NumberRange.new(0.3, 0.5)
    pe.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0)})
    pe.Parent = p
    
    table.insert(flyanim.particleList, p)
    task.delay(0.4, function()
        pcall(function()
            pe.Enabled = false
            task.wait(0.5)
            p:Destroy()
            local idx = table.find(flyanim.particleList, p)
            if idx then table.remove(flyanim.particleList, idx) end
        end)
    end)
end

local function startParticleEmitter()
    if flyanim.particleRunning then return end
    -- Bloqueo antes de generar el subprocesador thread
    if flyanim.megaTurboUpActive or flyanim.mode == "megaup" then return end
    
    flyanim.particleRunning = true
    flyanim.particleConn = task.spawn(function()
        while flyanim.enabled do
            -- Comprobación estricta en caliente dentro del bucle loop de frames
            if flyanim.megaTurboUpActive or flyanim.mode == "megaup" then break end
            
            if flyanim.mode == "fast" or flyanim.mode == "turbo" then
                local char = lplr.Character
                if char and char:FindFirstChild("HumanoidRootPart") then
                    local isMega = (flyanim.mode == "turbo")
                    createParticle(isMega)
                    if isMega then 
                        task.wait(0.04)
                        if not (flyanim.megaTurboUpActive or flyanim.mode == "megaup") then
                            createParticle(true)
                        end
                    end
                end
            end
            task.wait(0.12)
        end
        flyanim.particleRunning = false
        flyanim.particleConn    = nil
    end)
end

local function stopParticleEmitter()
    if flyanim.particleConn then
        pcall(function() task.cancel(flyanim.particleConn) end)
        flyanim.particleConn = nil
    end
    flyanim.particleRunning = false
    for _, p in ipairs(flyanim.particleList) do
        pcall(function() p:Destroy() end)
    end
    table.clear(flyanim.particleList)
end

-- ============================================================
-- FUNCIONES COMPLEMENTARIAS Y SEGURIDAD EXTERNA
-- ============================================================
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

local function playAnim(animId, looped)
    local t = getTrack(animId)
    if not t then return end
    t.Looped = looped
    for id, track in pairs(flyanim.tracks) do
        if id ~= animId and track.IsPlaying then pcall(function() track:Stop(0.1) end) end
    end
    if not t.IsPlaying then pcall(function() t:Play(0.15) end) end
end

local function setNoclip(state)
    local char = lplr.Character
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then part.CanCollide = not state end
    end
end

local function startTeleportGuard()
    if flyanim.teleportGuardConn then flyanim.teleportGuardConn:Disconnect() end
    flyanim.lastSafePos = nil
    local mySession = flyanim.sessionToken
    
    flyanim.teleportGuardConn = RunService.Stepped:Connect(function()
        if flyanim.sessionToken ~= mySession or not flyanim.enabled then
            if flyanim.teleportGuardConn then flyanim.teleportGuardConn:Disconnect(); flyanim.teleportGuardConn = nil end
            return
        end
        local char = lplr.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        
        local pos = root.Position
        if pos.Y <= -500 then
            local safe = flyanim.lastSafePos
            if safe then
                pcall(function()
                    root.CFrame = CFrame.new(safe + Vector3.new(0, 5, 0))
                    root.AssemblyLinearVelocity = Vector3.new(0,0,0)
                end)
            end
            return
        end
        if math.abs(pos.X) < COORD_SANITY_LIMIT and math.abs(pos.Z) < COORD_SANITY_LIMIT then
            flyanim.lastSafePos = pos
        end
    end)
end

local function startLandingWatcher()
    if flyanim.landConn then flyanim.landConn:Disconnect(); flyanim.landConn = nil end
    local char = lplr.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end
    
    flyanim.waitingLand = true
    flyanim.landingVelocity = 0
    
    flyanim.landConn = RunService.PostSimulation:Connect(function()
        if not flyanim.waitingLand then return end
        local velY = root.AssemblyLinearVelocity.Y
        if velY < -10 then flyanim.landingVelocity = velY end
        
        if hum.FloorMaterial ~= Enum.Material.Air or hum:GetState() == Enum.HumanoidStateType.Landed then
            flyanim.waitingLand = false
            if flyanim.landingVelocity < -25 then
                spawnLandingEffects(root.Position - Vector3.new(0, 2.5, 0), flyanim.landingVelocity)
            end
            if flyanim.landConn then flyanim.landConn:Disconnect(); flyanim.landConn = nil end
        end
    end)
end

local function startAntiImpulse()
    if flyanim.antiImpulseConn then flyanim.antiImpulseConn:Disconnect() end
    local mySession = flyanim.sessionToken
    flyanim.antiImpulseConn = RunService.Stepped:Connect(function()
        if flyanim.sessionToken ~= mySession or not flyanim.enabled then
            if flyanim.antiImpulseConn then flyanim.antiImpulseConn:Disconnect(); flyanim.antiImpulseConn = nil end
            return
        end
        local char = lplr.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root or not flyanim.bv then return end
        
        local exp = flyanim.bv.velocity
        local act = root.AssemblyLinearVelocity
        if (act - exp).Magnitude > 4 then root.AssemblyLinearVelocity = exp end
    end)
end

local function setupAnimator(char)
    local animScript = char:FindFirstChild("Animate")
    if animScript then animScript.Disabled = true; flyanim.animScript = animScript end
    local hum = char:WaitForChild("Humanoid", 5)
    local animator = hum and hum:WaitForChild("Animator", 5)
    if not animator then return end
    flyanim.animator = animator
    flyanim.tracks = {}
    
    local ok, playing = pcall(function() return animator:GetPlayingAnimationTracks() end)
    if ok and playing then
        for _, t in ipairs(playing) do pcall(function() t:Stop(0) end) end
    end
    
    local hrp = char:WaitForChild("HumanoidRootPart", 5)
    local rj = hrp and hrp:WaitForChild("RootJoint", 5)
    if rj then
        flyanim.rootJoint = rj
        flyanim.originalC0 = rj.C0
    end
end

local function setupBlockTrack()
    if not flyanim.animator then return end
    local obj = Instance.new("Animation")
    obj.AnimationId = ANIM.bloqueo
    pcall(function()
        flyanim.blockTrack = flyanim.animator:LoadAnimation(obj)
        flyanim.blockTrack.Priority = Enum.AnimationPriority.Action4
        flyanim.blockTrack.Looped = true
    end)
end

local function startBlocking()
    if not flyanim.enabled or flyanim.mode ~= "normal" or flyanim.isBlocking then return end
    if not flyanim.blockTrack then return end
    flyanim.isBlocking = true
    pcall(function() flyanim.blockTrack:Play(0.1) end)
end

local function stopBlocking()
    flyanim.isBlocking = false
    if flyanim.blockTrack then pcall(function() flyanim.blockTrack:Stop(0.1) end) end
end

local function setupDamageDetector()
    if flyanim.damageConn then flyanim.damageConn:Disconnect() end
    local char = lplr.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    flyanim.damageConn = hum.HealthChanged:Connect(function(hp)
        if flyanim.isBlocking then stopBlocking() end
    end)
end

local function restaurarC0Inmediato()
    if flyanim.rootJoint and flyanim.originalC0 then
        pcall(function() flyanim.rootJoint.C0 = flyanim.originalC0 end)
    end
end

local function updateAnimForMovement()
    if not flyanim.enabled then return end
    local moving = flyanim.wDown or flyanim.sDown or flyanim.aDown or flyanim.dDown
    flyanim.isMoving = moving
    
    if flyanim.mode == "normal" then
        if not moving then playAnim(ANIM.idle, true)
        elseif flyanim.dDown then playAnim(ANIM.right, true)
        elseif flyanim.aDown then playAnim(ANIM.left, true)
        elseif flyanim.sDown then playAnim(ANIM.back, true)
        else playAnim(ANIM.forward, true) end
    elseif flyanim.mode == "fast" then
        if not moving then playAnim(ANIM.fast_idle, true) else playAnim(ANIM.fast_move, true) end
    elseif flyanim.mode == "turbo" then
        if not moving then playAnim(ANIM.turbo_idle, true) else playAnim(ANIM.turbo_loop, true) end
    end
end

local function activateMegaTurboUp()
    if not flyanim.enabled then return end
    flyanim.megaTurboUpActive = true
    flyanim.mode = "megaup"
    if flyanim.updateMode then flyanim.updateMode("megaup") end
    stopParticleEmitter() -- Doble seguro: purga e impide partículas
    
    playLocalSound(SFX_MEGA_TURBO, 1.2)
    
    task.spawn(function()
        local start = tick()
        while flyanim.enabled and flyanim.megaTurboUpActive and (tick() - start < 1.3) do
            task.wait()
        end
        if flyanim.mode == "megaup" then
            flyanim.megaTurboUpActive = false
            flyanim.mode = "normal"
            flyanim.speed = BASE_SPEED
            if flyanim.updateMode then flyanim.updateMode("normal") end
            updateAnimForMovement()
        end
    end)
end

local function startMegaTurboUpListener()
    if flyanim.megaTurboUpConn then flyanim.megaTurboUpConn:Disconnect() end
    flyanim.megaTurboUpConn = RunService.RenderStepped:Connect(function()
        if not flyanim.enabled or isTyping() then return end
        local spaceDown = UserInputService:IsKeyDown(Enum.KeyCode.Space)
        local modeOk = (flyanim.mode == "normal" or flyanim.mode == "fast") and not flyanim.megaTurboUpActive
        
        if spaceDown and modeOk then
            if not flyanim.spaceHoldStart then flyanim.spaceHoldStart = tick() end
            if tick() - flyanim.spaceHoldStart >= flyanim.SPACE_HOLD_TIME then
                flyanim.spaceHoldStart = nil
                activateMegaTurboUp()
            end
        else
            if not spaceDown then
                flyanim.spaceHoldStart = nil
                if flyanim.megaTurboUpActive then
                    flyanim.megaTurboUpActive = false
                    flyanim.mode = "normal"
                    flyanim.speed = BASE_SPEED
                    if flyanim.updateMode then flyanim.updateMode("normal") end
                    updateAnimForMovement()
                end
            end
        end
    end)
end

local function startIdleWatcher()
    if flyanim.idleTimer then task.cancel(flyanim.idleTimer) end
    flyanim.idleTimer = task.spawn(function()
        while flyanim.enabled do
            task.wait(0.1)
            if flyanim.mode == "normal" or flyanim.mode == "megaup" then continue end
            local anyKey = UserInputService:IsKeyDown(Enum.KeyCode.W) or UserInputService:IsKeyDown(Enum.KeyCode.S) or UserInputService:IsKeyDown(Enum.KeyCode.A) or UserInputService:IsKeyDown(Enum.KeyCode.D)
            if not anyKey and not flyanim.megaTurboUpActive then
                flyanim.mode = "normal"
                flyanim.speed = BASE_SPEED
                if flyanim.updateMode then flyanim.updateMode("normal") end
                setNoclip(true)
                stopParticleEmitter()
                restaurarC0Inmediato()
                updateAnimForMovement()
            end
        end
    end)
end

-- ============================================================
-- LÓGICA DE MOVIMIENTO HEARTBEAT / ENSAMBLAJE DE MOTORIZACIÓN
-- ============================================================
local function _flyMakeMotors()
    local char = lplr.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    cleanupMotors(root, false)
    
    local bg = Instance.new("BodyGyro")
    bg.MaxTorque = Vector3.new(4e5, 4e5, 4e5)
    bg.P = 10000; bg.CFrame = root.CFrame; bg.Parent = root
    flyanim.bg = bg
    
    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(4e5, 4e5, 4e5)
    bv.Velocity = Vector3.new(0, 0, 0); bv.Parent = root
    flyanim.bv = bv
    
    local bf = Instance.new("BodyForce")
    bf.Parent = root; flyanim.bf = bf
    updateAntiGravityForce()
end

local function handleFlyMovement(dt)
    if not flyanim.enabled then return end
    local char = lplr.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    local camCF = camera.CFrame
    local moveDir = Vector3.new(0, 0, 0)
    
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + camCF.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - camCF.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - camCF.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + camCF.RightVector end
    
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir = moveDir - Vector3.new(0, 1, 0) end
    
    local currentSpeed = flyanim.speed
    if flyanim.mode == "fast" then
        currentSpeed = BASE_SPEED * FAST_MULT
    elseif flyanim.mode == "turbo" then
        currentSpeed = BASE_SPEED * TURBO_MULT
    elseif flyanim.mode == "megaup" or flyanim.megaTurboUpActive then
        currentSpeed = BASE_SPEED * 4.5
        moveDir = Vector3.new(0, 1, 0) -- Forzar vector ascendente vertical continuo
    end
    
    if moveDir.Magnitude > 0 then
        moveDir = moveDir.Unit
        if flyanim.bv then flyanim.bv.velocity = moveDir * currentSpeed end
    else
        if flyanim.bv then flyanim.bv.velocity = Vector3.new(0, 0, 0) end
    end
    
    if flyanim.bg then
        if flyanim.lockActive and flyanim.lockedTarget and flyanim.lockedTarget.Character then
            local tRoot = flyanim.lockedTarget.Character:FindFirstChild("HumanoidRootPart")
            if tRoot then
                flyanim.bg.CFrame = CFrame.lookAt(root.Position, Vector3.new(tRoot.Position.X, root.Position.Y, tRoot.Position.Z))
            end
        else
            flyanim.bg.CFrame = CFrame.lookAt(root.Position, root.Position + Vector3.new(camCF.LookVector.X, 0, camCF.LookVector.Z))
        end
    end
    updateAntiGravityForce()
end

local function getClosestLockTarget()
    local closestPlayer = nil
    local bestScore = math.huge
    local myChar = lplr.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    for _, player in ipairs(Players:GetPlayers()) do
        if player == lplr or not player.Character then continue end
        local tHum = player.Character:FindFirstChildOfClass("Humanoid")
        local tRoot = player.Character:FindFirstChild("HumanoidRootPart")
        if not tHum or tHum.Health <= 0 or not tRoot then continue end
        
        local screenPos, onScreen = camera:WorldToScreenPoint(tRoot.Position)
        if not onScreen then continue end
        
        local mousePos = UserInputService:GetMouseLocation()
        local dist2D = (Vector2.new(mousePos.X, mousePos.Y) - Vector2.new(screenPos.X, screenPos.Y)).Magnitude
        if dist2D > 300 then continue end
        
        local dist3D = myRoot and (myRoot.Position - tRoot.Position).Magnitude or 0
        local score = dist2D + (dist3D * 0.2)
        if score < bestScore then bestScore = score; closestPlayer = player end
    end
    return closestPlayer
end

local function removeLockIcon()
    if flyanim.lockIconGui then pcall(function() flyanim.lockIconGui:Destroy() end); flyanim.lockIconGui = nil end
end

local function applyLockIcon(player)
    removeLockIcon()
    local char = player.Character
    local torso = char and (char:FindFirstChild("UpperTorso") or char:FindFirstChild("HumanoidRootPart"))
    if not torso then return end
    
    local gui = Instance.new("BillboardGui", torso)
    gui.Name = "LockIcon"; gui.Size = UDim2.new(0, 50, 0, 50); gui.AlwaysOnTop = true
    local img = Instance.new("ImageLabel", gui)
    img.Size = UDim2.new(1,0,1,0); img.BackgroundTransparency = 1
    img.Image = "rbxassetid://82817965256191"; img.ScaleType = Enum.ScaleType.Fit
    flyanim.lockIconGui = gui
end

local function updateLockHighlight()
    if not flyanim.lockHighlight then
        flyanim.lockHighlight = Instance.new("Highlight")
        flyanim.lockHighlight.FillTransparency = 1
        flyanim.lockHighlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    end
    if flyanim.lockActive and flyanim.lockedTarget and flyanim.lockedTarget.Character then
        flyanim.lockHighlight.Parent = flyanim.lockedTarget.Character
    else
        flyanim.lockHighlight.Parent = nil
    end
end

local function updateLockInfoGui()
    if not flyanim.lockInfoGui or not flyanim.lockActive or not flyanim.lockedTarget then return end
    local char = flyanim.lockedTarget.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local myChar = lplr.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    
    if hum and root and myRoot then
        flyanim.lockInfoGui.Visible = true
        local dist = math.floor((myRoot.Position - root.Position).Magnitude)
        local hDiff = math.floor(myRoot.Position.Y - root.Position.Y)
        
        local nLbl = flyanim.lockInfoGui:FindFirstChild("NameLabel", true)
        local dLbl = flyanim.lockInfoGui:FindFirstChild("DistLabel", true)
        local hLbl = flyanim.lockInfoGui:FindFirstChild("HeightLabel", true)
        
        if nLbl then nLbl.Text = flyanim.lockedTarget.DisplayName end
        if dLbl then dLbl.Text = dist .. " studs" end
        if hLbl then
            if hDiff > 0 then hLbl.Text = "↓ " .. hDiff .. " " .. FT.height_below
            else hLbl.Text = "↑ " .. math.abs(hDiff) .. " " .. FT.height_above end
        end
    end
end

-- ============================================================
-- ACTIVACIÓN / DESACTIVACIÓN GLOBAL (INTERRUPTORES SEGUROS)
-- ============================================================
local function _flyOn()
    if flyanim.enabled then return end
    _reloadFT()
    flyanim.sessionToken = (flyanim.sessionToken or 0) + 1
    flyanim.enabled = true
    
    local char = lplr.Character
    if not char then flyanim.enabled = false; return end
    
    setupAnimator(char)
    _flyMakeMotors()
    setNoclip(true)
    startAntiImpulse()
    startTeleportGuard()
    setupDamageDetector()
    setupBlockTrack()
    startMegaTurboUpListener()
    
    if flyanim.updateMode then flyanim.updateMode(flyanim.mode) end
    updateAnimForMovement()
    startIdleWatcher()
end

local function _flyOff()
    if not flyanim.enabled then return end
    flyanim.enabled = false
    
    flyanim.sessionToken = (flyanim.sessionToken or 0) + 1
    
    stopAntiImpulse()
    stopParticleEmitter()
    restaurarC0Inmediato()
    setNoclip(false)
    stopBlocking()
    
    if flyanim.megaTurboUpConn then flyanim.megaTurboUpConn:Disconnect(); flyanim.megaTurboUpConn = nil end
    if flyanim.damageConn then flyanim.damageConn:Disconnect(); flyanim.damageConn = nil end
    
    local char = lplr.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if root then
        cleanupMotors(root, true) -- preserveVelY = true evita el lag de físicas
    end
    
    startLandingWatcher()
    
    if flyanim.animScript then flyanim.animScript.Disabled = false end
    removeLockIcon()
    updateLockHighlight()
    if flyanim.lockInfoGui then flyanim.lockInfoGui.Visible = false end
end

-- ============================================================
-- INTERFAZ DE MÓDULO (API CONTROL DE EVENTOS)
-- ============================================================
local M = {}
local _inputConn = nil
local _inputConn_End = nil
local _charConn = nil

local function _connectGlobal()
    if _inputConn then _inputConn:Disconnect() end
    _inputConn = UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == flyanim.flyKey then
            if flyanim.enabled then _flyOff() else _flyOn() end
        end
        if not flyanim.enabled then return end
        
        if input.KeyCode == flyanim.lockKey then
            if flyanim.lockActive then
                flyanim.lockActive = false; flyanim.lockedTarget = nil
                removeLockIcon(); updateLockHighlight()
                if flyanim.lockInfoGui then flyanim.lockInfoGui.Visible = false end
            else
                local target = getClosestLockTarget()
                if target then
                    flyanim.lockActive = true; flyanim.lockedTarget = target
                    applyLockIcon(target); updateLockHighlight()
                end
            end
        end
        
        if input.KeyCode == Enum.KeyCode.Q then
            local now = tick()
            if now - flyanim.qLastPress < 0.3 then
                if flyanim.mode == "normal" then
                    flyanim.mode = "fast"
                    if flyanim.updateMode then flyanim.updateMode("fast") end
                    startParticleEmitter()
                elseif flyanim.mode == "fast" then
                    flyanim.mode = "turbo"
                    if flyanim.updateMode then flyanim.updateMode("turbo") end
                    startParticleEmitter()
                else
                    flyanim.mode = "normal"
                    if flyanim.updateMode then flyanim.updateMode("normal") end
                    stopParticleEmitter()
                end
                updateAnimForMovement()
            end
            flyanim.qLastPress = now
        end
        
        if input.KeyCode == Enum.KeyCode.F then flyanim.fKeyHeld = true; startBlocking() end
        if input.KeyCode == Enum.KeyCode.W then flyanim.wDown = true; updateAnimForMovement() end
        if input.KeyCode == Enum.KeyCode.S then flyanim.sDown = true; updateAnimForMovement() end
        if input.KeyCode == Enum.KeyCode.A then flyanim.aDown = true; updateAnimForMovement() end
        if input.KeyCode == Enum.KeyCode.D then flyanim.dDown = true; updateAnimForMovement() end
    end)

    if _inputConn_End then _inputConn_End:Disconnect() end
    _inputConn_End = UserInputService.InputEnded:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == Enum.KeyCode.F then
            flyanim.fKeyHeld = false
            if flyanim.enabled then stopBlocking() end
        end
        if flyanim.enabled then
            if input.KeyCode == Enum.KeyCode.W then flyanim.wDown = false; updateAnimForMovement() end
            if input.KeyCode == Enum.KeyCode.S then flyanim.sDown = false; updateAnimForMovement() end
            if input.KeyCode == Enum.KeyCode.A then flyanim.aDown = false; updateAnimForMovement() end
            if input.KeyCode == Enum.KeyCode.D then flyanim.dDown = false; updateAnimForMovement() end
        end
    end)
    
    if _charConn then _charConn:Disconnect() end
    _charConn = lplr.CharacterAdded:Connect(function()
        if flyanim.landConn then flyanim.landConn:Disconnect(); flyanim.landConn = nil end
        flyanim.mode = "normal"; flyanim.speed = BASE_SPEED
        flyanim.wDown = false; flyanim.sDown = false; flyanim.aDown = false; flyanim.dDown = false
        flyanim.megaTurboUpActive = false; flyanim.isBlocking = false
        task.wait(0.5)
        if flyanim.enabled then _flyMakeMotors() end
    end)
    
    if flyanim.rsConn then flyanim.rsConn:Disconnect() end
    flyanim.rsConn = RunService.Heartbeat:Connect(function(dt)
        if flyanim.enabled then
            handleFlyMovement(dt)
            if flyanim.lockActive then updateLockInfoGui() end
        end
    end)
end

function M.Start(flyKey)
    lplr = Players.LocalPlayer
    camera = workspace.CurrentCamera
    if flyKey then flyanim.flyKey = flyKey end
    _reloadFT()
    _connectGlobal()
end

function M.Stop()
    if flyanim.enabled then _flyOff() end
    if _inputConn then _inputConn:Disconnect() end
    if _inputConn_End then _inputConn_End:Disconnect() end
    if _charConn then _charConn:Disconnect() end
    if flyanim.rsConn then flyanim.rsConn:Disconnect() end
end

function M.Toggle(state)
    if state then if not flyanim.enabled then _flyOn() end
    else if flyanim.enabled then _flyOff() end end
end

return M
