-- ═══════════════════════════════════════════════════════════════════════════
--  CONFIG
-- ═══════════════════════════════════════════════════════════════════════════

local cloneref = cloneref or function(x) return x end

local M = {}

local Players          = cloneref(game:GetService("Players"))
local RunService       = cloneref(game:GetService("RunService"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local TweenService     = cloneref(game:GetService("TweenService"))
local Debris           = game:GetService("Debris")

local camera = workspace.CurrentCamera

local OCFG = {
    SAFE_DIST = 35, WALL_BUFFER = 8,
    DASH_FORCE_BASE = 65, MAX_VELOCITY = 120, ROTATION_SMOOTH = 0.85,

    AERIAL_DETECT_DIST       = 35,
    AERIAL_HEIGHT_THRESHOLD  = 4,
    AERIAL_ESCAPE_UP         = 55,
    AERIAL_ESCAPE_LATERAL    = 90,
    AERIAL_AOE_RADIUS        = 12,
    SLAM_PREDICT_FRAMES      = 8,
    JUMP_VEL_THRESHOLD       = 3,
    JUMP_DETECTION_DIST      = 25,
    LATERAL_DODGE_MULT       = 2.5,
    PING_BUFFER              = 1.8,

    MAX_ESP_DIST  = 60,
    BASE_THICKNESS = 2.5, MAX_THICKNESS = 22,
    NEON_SAFE    = Color3.fromRGB(0,255,255),
    NEON_MID     = Color3.fromRGB(255,255,0),
    NEON_DANGER  = Color3.fromRGB(255,30,120),
    OUTLINE_ALPHA = 0.65, GLOW_EXTRA = 5,

    DECOY_WALK_SPEED = 202.5,
    -- El salto previo alcanzaba ~4.9 studs; 40 de velocidad inicial alcanza ~10 studs.
    DECOY_JUMP_VELOCITY = 40,
    DECOY_JUMP_GRAVITY  = 80,
    SKY_ALTITUDE     = 1500,
    SKY_LIFT_SPEED   = 600,
    SKY_HOLD_FORCE   = 9e8,
    ORBIT_RADIUS     = 55,
    ORBIT_SPEED      = 6,
    ORBIT_DURATION   = 4,
    DECOY_HEAD_Y     = 3,
    -- Ajuste estético mínimo: conserva los pies prácticamente al ras del suelo.
    CLONE_VISUAL_Y_OFFSET = -0.08,
    
    SND_ACTIVATE     = "rbxassetid://121724991975758",
    SND_DEACTIVATE   = "rbxassetid://128617187053393",

    CLIMB_STEP_MAX     = 1.8,
    DESCEND_STEP_MAX   = 2.2,
    GROUND_PROBE_AHEAD = 1.5,
    MAX_VERTICAL_SPEED = 24,

    PRED_SAMPLES      = 30,
    PRED_DT           = 0.03,
    PRED_MAX_TIME     = 2.5,
    PRED_ESP_COLOR    = Color3.fromRGB(255, 200, 50),
    PRED_LAND_COLOR   = Color3.fromRGB(255, 80,  80),
    PRED_LAND_RADIUS  = 14,
    PRED_ARC_THICK    = 2,
    PRED_THREAT_SPEED = 25,
}

-- ═══════════════════════════════════════════════════════════════════════════
--  ESTADO
-- ═══════════════════════════════════════════════════════════════════════════
local enabled = false
local _lplr, _keys

local omniModeX = false; local omniModeY = false; local omniRmbHeld = false
local omniInSky = false;  local omniESP = {};      local omniSkyBV = nil; local omniSkyBP2 = nil
local omniSkyWorldY = 0;  local omniGroundPos = Vector3.new()
local omniFootOffset = 3
-- Distancia desde la PrimaryPart del clon hasta su punto visual más bajo.
-- No se debe reutilizar omniFootOffset: en R6 el HRP está por encima de los pies.
local omniCloneFootOffset = 3
local omniOrbiting = false; local omniOrbitAngle = 0
local omniOrbitTimer = 0;   local omniLastHealth = 100
local omniLastCamCF = nil;  local omniCamSubjectPart = nil
local omniHeartbeat = nil;  local omniInputBegin = nil
local omniInputEnd = nil;   local omniCharConn = nil
local omniCloneModel = nil; local omniCloneHighlight = nil
local omniCloneOrigColors = {}; local omniCloneJumpOffset = 0; local omniCloneJumpVel = 0
local omni4DPinned = false; local omniPinGui = nil
local omniLockModuleRef = nil
local omniPublicState = { threats = {}, primary = nil, distances = {}, is4D = false, is4DPinned = false, mode4D = "off" }
local omniLastPublicUpdate = 0

-- Variables para movimiento errático en alerta
local erraticTimer = 0
local erraticDir = Vector3.new(1, 0, 0)
local erraticSpeed = 500

-- ═══════════════════════════════════════════════════════════════════════════
--  GESTOR DE CONEXIONES
-- ═══════════════════════════════════════════════════════════════════════════
local allConnections = {}
local function trackConnection(conn)
    table.insert(allConnections, conn); return conn
end
local function disconnectTracked(conn)
    pcall(function() conn:Disconnect() end)
    for i, v in ipairs(allConnections) do
        if v == conn then table.remove(allConnections, i); break end
    end
end
local function disconnectAllConnections()
    for _, conn in ipairs(allConnections) do pcall(function() conn:Disconnect() end) end
    allConnections = {}
end

-- ═══════════════════════════════════════════════════════════════════════════
--  HELPERS GENERALES
-- ═══════════════════════════════════════════════════════════════════════════
local function omniGetHRP(char)
    return char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"))
end

local function omniHRPFootOffset(char)
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local hrp = omniGetHRP(char)
    if hum and hrp then return hum.HipHeight + hrp.Size.Y / 2 end
    return 3
end

local function omniGetCloneFootOffset(clone, primaryPart)
    if not clone or not primaryPart then return 3 end

    local lowestY = math.huge
    for _, part in ipairs(clone:GetDescendants()) do
        if part:IsA("BasePart") then
            local localY = primaryPart.CFrame:PointToObjectSpace(part.Position).Y
            lowestY = math.min(lowestY, localY - part.Size.Y * 0.5)
        end
    end

    return lowestY == math.huge and 3 or -lowestY
end

local function omniPlaySound(id)
    local snd = Instance.new("Sound", workspace)
    snd.SoundId = id; snd.Volume = 1.5; snd:Play(); Debris:AddItem(snd, 6)
end

local function omniClearESP()
    for _, d in pairs(omniESP) do
        if d.line    then d.line.Visible    = false end
        if d.outline then d.outline.Visible = false end
        if d.glow    then d.glow.Visible    = false end
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
--  TRAYECTORIA (SOLO SIMULACIÓN, SIN DIBUJO)
-- ═══════════════════════════════════════════════════════════════════════════

local function predSimulate(p0, v0, excludeList)
    local grav = workspace.Gravity
    local positions = {}
    local prev = p0
    local landed = nil

    local rp = RaycastParams.new()
    rp.FilterType = Enum.RaycastFilterType.Exclude
    rp.FilterDescendantsInstances = excludeList or {}

    for step = 1, math.ceil(OCFG.PRED_MAX_TIME / OCFG.PRED_DT) do
        local t = step * OCFG.PRED_DT
        local pos = p0 + v0 * t + Vector3.new(0, -grav * 0.5 * t * t, 0)
        table.insert(positions, pos)

        local dir = pos - prev
        if dir.Magnitude > 0.01 then
            local hit = workspace:Raycast(prev, dir, rp)
            if hit then landed = hit.Position; break end
        end
        prev = pos
    end

    if not landed and #positions > 0 then
        local last = positions[#positions]
        local down = workspace:Raycast(last + Vector3.new(0,1,0), Vector3.new(0,-5000,0), rp)
        if down then landed = down.Position end
    end

    return positions, landed
end

-- ═══════════════════════════════════════════════════════════════════════════
--  SEGUIMIENTO DE TERRENO DEL CLON (VERSIÓN SIMPLIFICADA Y CORREGIDA)
-- ═══════════════════════════════════════════════════════════════════════════
local function omniGetGroundHeight(pos, char)
    local rp = RaycastParams.new()
    rp.FilterType = Enum.RaycastFilterType.Exclude
    local excl = {}
    if char then table.insert(excl, char) end
    if omniCloneModel then table.insert(excl, omniCloneModel) end
    rp.FilterDescendantsInstances = excl
    local origin = Vector3.new(pos.X, pos.Y + 5, pos.Z)
    local hit = workspace:Raycast(origin, Vector3.new(0, -50, 0), rp)
    if hit then return hit.Position.Y + omniFootOffset end
    return nil
end

local function omniFollowGround(prevPos, desiredXZ, dt, char)
    -- Movimiento horizontal directo
    local newPos = Vector3.new(desiredXZ.X, prevPos.Y, desiredXZ.Z)

    -- Raycast para obtener altura del suelo en la nueva posición
    local groundY = omniGetGroundHeight(newPos, char)
    if groundY then
        local diff = groundY - prevPos.Y
        -- No escala paredes; al bajar, ajusta al suelo de inmediato para que
        -- no quede suspendido ni se hunda visualmente en una pendiente.
        if diff > OCFG.CLIMB_STEP_MAX then
            newPos = Vector3.new(newPos.X, prevPos.Y, newPos.Z)
        else
            newPos = Vector3.new(newPos.X, groundY, newPos.Z)
        end
    else
        -- Si no hay suelo, mantener Y actual (puede estar en el aire)
        newPos = Vector3.new(newPos.X, prevPos.Y, newPos.Z)
    end

    return newPos
end

-- ═══════════════════════════════════════════════════════════════════════════
--  ANTI-BOUNCE LANDING
-- ═══════════════════════════════════════════════════════════════════════════
local function omniAntiBounceLand(hrp, hum)
    if not hrp or not hum then return end
    pcall(function()
        hrp.AssemblyLinearVelocity  = Vector3.new(0,0,0)
        hrp.AssemblyAngularVelocity = Vector3.new(0,0,0)
    end)
    local bv = Instance.new("BodyVelocity")
    bv.Velocity = Vector3.new(0,0,0); bv.MaxForce = Vector3.new(9e9,9e9,9e9)
    bv.Parent = hrp; hum.PlatformStand = true
    task.defer(function()
        pcall(function() bv:Destroy() end)
        if hum and hum.Parent then
            hum.PlatformStand = false
            hum:ChangeState(Enum.HumanoidStateType.Landed)
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════
--  LINES
-- ═══════════════════════════════════════════════════════════════════════════
local function omniNeonColor(t)
    t = math.clamp(t, 0, 1)
    if t < 0.5 then
        local f = t / 0.5
        return Color3.new(
            OCFG.NEON_SAFE.R + (OCFG.NEON_MID.R - OCFG.NEON_SAFE.R) * f,
            OCFG.NEON_SAFE.G + (OCFG.NEON_MID.G - OCFG.NEON_SAFE.G) * f,
            OCFG.NEON_SAFE.B + (OCFG.NEON_MID.B - OCFG.NEON_SAFE.B) * f)
    else
        local f = (t - 0.5) / 0.5
        return Color3.new(
            OCFG.NEON_MID.R + (OCFG.NEON_DANGER.R - OCFG.NEON_MID.R) * f,
            OCFG.NEON_MID.G + (OCFG.NEON_DANGER.G - OCFG.NEON_MID.G) * f,
            OCFG.NEON_MID.B + (OCFG.NEON_DANGER.B - OCFG.NEON_MID.B) * f)
    end
end

local function omniThreatLevel(originPos, tHRP, tHum)
    local dist  = (tHRP.Position - originPos).Magnitude
    local hp    = tHum.Health / math.max(tHum.MaxHealth, 1)
    local distT = 1 - math.clamp(dist / OCFG.MAX_ESP_DIST, 0, 1)
    local rVel  = tHRP.AssemblyLinearVelocity
    local dir   = originPos - tHRP.Position
    local spd   = dir.Magnitude > 0 and math.max(0, -rVel:Dot(dir.Unit)) or 0
    return math.clamp(distT*0.5 + hp*0.25 + math.clamp(spd/40,0,1)*0.25, 0, 1)
end

local function omniGetLockTarget()
    local lock = omniLockModuleRef
    if type(lock) ~= "table" then lock = rawget(getgenv(), "AFO_LOCK_API") end
    if type(lock) ~= "table" or type(lock.IsLockActive) ~= "function" or type(lock.GetTarget) ~= "function" then return nil end
    local ok, active = pcall(lock.IsLockActive)
    if not ok or active ~= true then return nil end
    local okTarget, target = pcall(lock.GetTarget)
    return okTarget and target or nil
end

local function omniBuildThreats(myHRP)
    local locked = omniGetLockTarget()
    local threats = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= _lplr and p.Character then
            local hrp, hum = omniGetHRP(p.Character), p.Character:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 then
                local distance = (hrp.Position - myHRP.Position).Magnitude
                if distance < 100 then
                    table.insert(threats, { HRP = hrp, Hum = hum, Player = p, Distance = distance,
                        Score = omniThreatLevel(myHRP.Position, hrp, hum), IsLocked = p == locked })
                end
            end
        end
    end
    table.sort(threats, function(a, b)
        if math.abs(a.Score - b.Score) < 0.001 then
            if a.IsLocked ~= b.IsLocked then return a.IsLocked end
            return a.Distance < b.Distance
        end
        return a.Score > b.Score
    end)
    return threats
end

local function omniUpdatePublicState(threats)
    if tick() - omniLastPublicUpdate < 0.1 then return end
    omniLastPublicUpdate = tick()
    table.clear(omniPublicState.threats); table.clear(omniPublicState.distances)
    for i, t in ipairs(threats) do
        omniPublicState.threats[i] = { player = t.Player, name = t.Player.Name, distance = t.Distance, score = t.Score, locked = t.IsLocked }
        omniPublicState.distances[i] = t.Distance
    end
    omniPublicState.primary = omniPublicState.threats[1]
    omniPublicState.is4D = omniInSky
    omniPublicState.is4DPinned = omni4DPinned
    omniPublicState.mode4D = omni4DPinned and "pinned" or (omniInSky and "4d" or "off")
end

-- ═══════════════════════════════════════════════════════════════════════════
--  CLON
-- ═══════════════════════════════════════════════════════════════════════════
local function omniDestroyDecoy()
    if omniPinGui then omniPinGui:Destroy(); omniPinGui = nil end
    if omniCloneHighlight then omniCloneHighlight.Parent = nil; omniCloneHighlight = nil end
    if omniCloneModel then omniCloneModel:Destroy(); omniCloneModel = nil end
    omniCloneOrigColors = {}; omniCloneJumpOffset = 0; omniCloneJumpVel = 0; omniCloneFootOffset = 3
end

local function omniApplyCloneColor(isOrbiting)
    if not omniCloneModel then return end
    for _, v in pairs(omniCloneModel:GetDescendants()) do
        if v:IsA("BasePart") then
            if isOrbiting then
                v.Color = Color3.fromRGB(255,0,0); v.Material = Enum.Material.Neon
            else
                local orig = omniCloneOrigColors[v]
                if orig then v.Color = orig.Color; v.Material = orig.Material end
            end
        end
    end
    if omniCloneHighlight then
        if isOrbiting then
            omniCloneHighlight.FillColor       = Color3.fromRGB(255,0,0)
            omniCloneHighlight.OutlineColor    = Color3.fromRGB(255,80,80)
            omniCloneHighlight.FillTransparency = 0.4
        else
            omniCloneHighlight.FillColor       = Color3.fromRGB(200,220,255)
            omniCloneHighlight.OutlineColor    = Color3.fromRGB(180,200,255)
            omniCloneHighlight.FillTransparency = 0.55
        end
    end
end

local function omniCreateDecoy(pos)
    omniDestroyDecoy()
    local char = _lplr.Character
    if not char then return end
    pcall(function() char.Archivable = true end)
    local ok, clone = pcall(function() return char:Clone() end)
    pcall(function() char.Archivable = false end)
    if not ok or not clone then return end
    for _, v in pairs(clone:GetDescendants()) do
        if v:IsA("Script") or v:IsA("LocalScript") or v:IsA("ModuleScript") then v:Destroy() end
    end
    for _, v in pairs(clone:GetDescendants()) do
        if v:IsA("BasePart") then
            omniCloneOrigColors[v] = {Color = v.Color, Material = v.Material}
            v.Anchored = true; v.CanCollide = false
        end
    end
    clone.Parent = workspace
    omniCloneModel = clone

    -- Establecer la PrimaryPart para poder usar SetPrimaryPartCFrame
    local hrp = omniGetHRP(char)
    local cloneHRP = clone:FindFirstChild("HumanoidRootPart") or clone:FindFirstChild("Torso")
    if cloneHRP then
        clone:SetPrimaryPartCFrame(cloneHRP.CFrame)
        clone.PrimaryPart = cloneHRP
        omniCloneFootOffset = omniGetCloneFootOffset(clone, cloneHRP)
        local _, ry = cloneHRP.CFrame:ToEulerAnglesYXZ()
        clone:PivotTo(CFrame.new(pos + Vector3.new(0, omniCloneFootOffset + OCFG.CLONE_VISUAL_Y_OFFSET, 0)) * CFrame.Angles(0, ry, 0))
    end

    local hl = Instance.new("Highlight", clone)
    hl.FillColor = Color3.fromRGB(200,220,255); hl.OutlineColor = Color3.fromRGB(180,200,255)
    hl.FillTransparency = 0.55; hl.OutlineTransparency = 0.2
    omniCloneHighlight = hl
    omniApplyCloneColor(false)
end

local function omniCreateCamSubject()
    if omniCamSubjectPart then omniCamSubjectPart:Destroy() end
    local part = Instance.new("Part")
    part.Name = "4DCamSubject"; part.Anchored = true; part.CanCollide = false; part.CanTouch = false
    part.Transparency = 1; part.Size = Vector3.new(2,5,1)
    part.CFrame = CFrame.new(omniGroundPos + Vector3.new(0, OCFG.DECOY_HEAD_Y, 0))
    part.Parent = workspace
    return part
end

local function omniDestroyCamSubject()
    if omniCamSubjectPart then omniCamSubjectPart:Destroy(); omniCamSubjectPart = nil end
end

local function omniSetPinned(value)
    if omni4DPinned == value then return end
    omni4DPinned = value
    if not value then
        if omniPinGui then
            local scale = omniPinGui:FindFirstChildOfClass("UIScale")
            if scale then TweenService:Create(scale, TweenInfo.new(0.16, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Scale = 0}):Play() end
            local gui = omniPinGui; omniPinGui = nil
            task.delay(0.17, function() pcall(function() gui:Destroy() end) end)
        end
        return
    end
    local adornee = omniCloneModel and (omniCloneModel:FindFirstChild("Head") or omniCloneModel.PrimaryPart)
    if not adornee then return end
    local gui = Instance.new("BillboardGui")
    gui.Name = "Omni4DPinnedLock"; gui.Adornee = adornee; gui.Size = UDim2.fromOffset(42, 42)
    gui.StudsOffset = Vector3.new(0, 3.2, 0); gui.AlwaysOnTop = true; gui.Parent = omniCloneModel
    local image = Instance.new("ImageLabel", gui)
    image.BackgroundTransparency = 1; image.Size = UDim2.fromScale(1, 1)
    image.Image = "rbxassetid://15117261700"; image.ImageColor3 = Color3.new(1, 1, 1)
    local scale = Instance.new("UIScale", gui); scale.Scale = 0
    TweenService:Create(scale, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
    omniPinGui = gui
end

-- ═══════════════════════════════════════════════════════════════════════════
--  MODO 4D
-- ═══════════════════════════════════════════════════════════════════════════
local function omniActivate4D()
    if omniInSky then return end
    local char = _lplr.Character; local hrp = omniGetHRP(char)
    if not char or not hrp then return end

    omniInSky = true; omniOrbiting = false; omniOrbitAngle = 0
    omniOrbitTimer = 0; omniLastCamCF = nil
    omniFootOffset  = omniHRPFootOffset(char)
    local groundY = omniGetGroundHeight(hrp.Position, char)
    omniGroundPos   = Vector3.new(hrp.Position.X, groundY or hrp.Position.Y, hrp.Position.Z)
    omniSkyWorldY   = omniGroundPos.Y + OCFG.SKY_ALTITUDE

    omniCreateDecoy(omniGroundPos)
    omniCamSubjectPart = omniCreateCamSubject()
    local hum = char:FindFirstChildOfClass("Humanoid")
    omniLastHealth = hum and hum.Health or 100

    for _, v in pairs(char:GetDescendants()) do
        if v:IsA("BasePart") or v:IsA("Decal") then v.LocalTransparencyModifier = 1 end
    end

    local _fm = rawget(getgenv(), "_AFO_FLY_MODULE")
    if _fm and _fm.Bypass then _fm.Bypass(2.5, "omni4d_activate") end

    if omniSkyBV  then omniSkyBV:Destroy();  omniSkyBV  = nil end
    if omniSkyBP2 then omniSkyBP2:Destroy(); omniSkyBP2 = nil end

    omniSkyBV = Instance.new("BodyVelocity", hrp)
    omniSkyBV.Name     = "4DSkyBV"
    omniSkyBV.Velocity  = Vector3.new(0, OCFG.SKY_LIFT_SPEED, 0)
    omniSkyBV.MaxForce  = Vector3.new(0, 9e8, 0)

    task.spawn(function()
        local timeout = 10; local t0 = tick()
        while tick() - t0 < timeout and omniInSky do
            if hrp and hrp.Parent and hrp.Position.Y >= omniSkyWorldY - 20 then break end
            task.wait(0.05)
        end
        if not omniInSky then return end
        if omniSkyBV then omniSkyBV:Destroy(); omniSkyBV = nil end
        if not hrp or not hrp.Parent then return end

        omniSkyBP2 = Instance.new("BodyPosition", hrp)
        omniSkyBP2.Name     = "4DSkyBP"
        omniSkyBP2.Position  = Vector3.new(hrp.Position.X, omniSkyWorldY, hrp.Position.Z)
        omniSkyBP2.MaxForce  = Vector3.new(OCFG.SKY_HOLD_FORCE, OCFG.SKY_HOLD_FORCE, OCFG.SKY_HOLD_FORCE)
        omniSkyBP2.P         = 60000
        omniSkyBP2.D         = 2500
    end)

    camera.CameraSubject = omniCamSubjectPart
    omniPlaySound(OCFG.SND_ACTIVATE)
end

local function omniDeactivate4D()
    if not omniInSky then return end
    local wasPinned = omni4DPinned
    omniSetPinned(false)
    if wasPinned then task.wait(0.18) end
    omniInSky = false; omniOrbiting = false

    if omniSkyBV  then omniSkyBV:Destroy();  omniSkyBV  = nil end
    if omniSkyBP2 then omniSkyBP2:Destroy(); omniSkyBP2 = nil end

    local char = _lplr.Character
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if hum then camera.CameraSubject = hum end

    if char then
        local hrp = omniGetHRP(char)
        if hrp then
            hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
            local _fm = rawget(getgenv(), "_AFO_FLY_MODULE")
            if _fm and _fm.Bypass then _fm.Bypass(0.5, "omni4d_deactivate") end

            local cloneHRP = omniCloneModel and omniCloneModel.PrimaryPart
            local landPos, landCF
            if cloneHRP then
                landPos = cloneHRP.Position
                landCF  = CFrame.new(landPos) * CFrame.Angles(0, select(2, cloneHRP.CFrame:ToEulerAnglesYXZ()), 0)
            else
                landPos = omniGroundPos
                landCF  = CFrame.new(landPos)
                if omniLastCamCF then
                    local look = omniLastCamCF.LookVector
                    local flat = Vector3.new(look.X, 0, look.Z)
                    if flat.Magnitude > 0.01 then
                        landCF = CFrame.new(landPos) * CFrame.Angles(0, math.atan2(-flat.X, -flat.Z), 0)
                    end
                end
            end

            local snapY = omniGetGroundHeight(landPos, char)
            if snapY then
                landCF = CFrame.new(landPos.X, snapY, landPos.Z) * (landCF - landCF.Position)
            end

            hrp.CFrame = landCF
            omniAntiBounceLand(hrp, hum)
            task.defer(function()
                if hum and hum.Parent then
                    hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
                end
            end)
        end
        for _, v in pairs(char:GetDescendants()) do
            if v:IsA("BasePart") or v:IsA("Decal") then v.LocalTransparencyModifier = 0 end
        end
    end
    omniDestroyDecoy(); omniDestroyCamSubject()
    omniPlaySound(OCFG.SND_DEACTIVATE)
end

-- ═══════════════════════════════════════════════════════════════════════════
--  LINES
-- ═══════════════════════════════════════════════════════════════════════════
local function omniUpdateESP(originPos)
    if not omniModeX then omniClearESP(); return end
    if not originPos then return end
    local myOrig, myOn = camera:WorldToViewportPoint(originPos)
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= _lplr and p.Character then
            local hum = p.Character:FindFirstChild("Humanoid")
            local hrp = omniGetHRP(p.Character)
            if hrp and hum and hum.Health > 0 then
                local dist = (hrp.Position - originPos).Magnitude
                if dist <= OCFG.MAX_ESP_DIST then
                    if not omniESP[p] then
                        local gw = Drawing.new("Line"); gw.Transparency = 0.35
                        local ol = Drawing.new("Line"); ol.Transparency = OCFG.OUTLINE_ALPHA; ol.Color = Color3.fromRGB(0,0,0)
                        local ln = Drawing.new("Line"); ln.Transparency = 1
                        omniESP[p] = {line = ln, outline = ol, glow = gw}
                    end
                    local sp, on = camera:WorldToViewportPoint(hrp.Position)
                    local d = omniESP[p]
                    if on and myOn then
                        local threat = omniThreatLevel(originPos, hrp, hum)
                        local col    = omniNeonColor(threat)
                        local thick  = OCFG.BASE_THICKNESS + (threat^1.3) * (OCFG.MAX_THICKNESS - OCFG.BASE_THICKNESS)
                        local from2  = Vector2.new(myOrig.X, myOrig.Y)
                        local to2    = Vector2.new(sp.X, sp.Y)
                        d.glow.Visible   = true; d.glow.From   = from2; d.glow.To   = to2; d.glow.Color   = col; d.glow.Thickness   = thick + OCFG.GLOW_EXTRA + 6
                        d.outline.Visible= true; d.outline.From= from2; d.outline.To= to2;                         d.outline.Thickness= thick + OCFG.GLOW_EXTRA
                        d.line.Visible   = true; d.line.From   = from2; d.line.To   = to2; d.line.Color   = col; d.line.Thickness   = thick
                    else
                        d.line.Visible = false; d.outline.Visible = false; d.glow.Visible = false
                    end
                elseif omniESP[p] then
                    omniESP[p].line.Visible = false; omniESP[p].outline.Visible = false; omniESP[p].glow.Visible = false
                end
            elseif omniESP[p] then
                omniESP[p].line.Visible = false; omniESP[p].outline.Visible = false; omniESP[p].glow.Visible = false
            end
        end
    end
    for p in pairs(omniESP) do
        if not p.Character or not p.Parent then
            if omniESP[p].line    then omniESP[p].line:Remove()    end
            if omniESP[p].outline then omniESP[p].outline:Remove() end
            if omniESP[p].glow    then omniESP[p].glow:Remove()    end
            omniESP[p] = nil
        end
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
--  AERIAL (MODIFICADO: SIN DIBUJO, SOLO SIMULACIÓN)
-- ═══════════════════════════════════════════════════════════════════════════
local function omniHandleAerial(myHRP, myHum, threats)
    local char   = _lplr and _lplr.Character
    local exclude = char and {char} or {}

    local bestEscape, highestDanger = nil, 0

    for _, t in ipairs(threats) do
        local tHRP = t.HRP; local tVel = tHRP.AssemblyLinearVelocity
        local dist2D = Vector2.new(tHRP.Position.X - myHRP.Position.X,
                                   tHRP.Position.Z - myHRP.Position.Z).Magnitude
        local heightAbove = tHRP.Position.Y - myHRP.Position.Y
        local isAbove     = heightAbove > OCFG.AERIAL_HEIGHT_THRESHOLD
        local isFalling   = tVel.Y < -OCFG.JUMP_VEL_THRESHOLD or math.abs(tVel.Y) < 2
        local isJumpingUp = tVel.Y > OCFG.JUMP_VEL_THRESHOLD and heightAbove > 0
        local speed3D     = tVel.Magnitude

        if dist2D < OCFG.AERIAL_DETECT_DIST and (isAbove or isJumpingUp) then

            local predictedLanding = nil
            if speed3D > OCFG.PRED_THREAT_SPEED or isAbove then
                local _, landing = predSimulate(tHRP.Position, tVel, exclude)
                predictedLanding = landing
            end

            local impactXZ
            if predictedLanding then
                impactXZ = Vector2.new(predictedLanding.X, predictedLanding.Z)
            else
                local pred  = tHRP.Position + tVel * (OCFG.SLAM_PREDICT_FRAMES / 60)
                impactXZ    = Vector2.new(pred.X, pred.Z)
            end

            local impactDist = (impactXZ - Vector2.new(myHRP.Position.X, myHRP.Position.Z)).Magnitude

            local danger = 0
            if isFalling and isAbove then
                danger = math.clamp(1 - (dist2D / OCFG.AERIAL_DETECT_DIST), 0.4, 1)
                       + (impactDist < OCFG.AERIAL_AOE_RADIUS and 0.5 or 0)
            elseif isJumpingUp then
                danger = math.clamp(1 - (dist2D / OCFG.AERIAL_DETECT_DIST), 0.2, 0.7)
            end
            danger = math.clamp(danger, 0, 1)

            if danger > highestDanger then
                highestDanger = danger
                local myXZ   = Vector2.new(myHRP.Position.X, myHRP.Position.Z)
                local escDir = myXZ - impactXZ
                if escDir.Magnitude < 0.1 then
                    local cl = camera.CFrame.LookVector
                    escDir = Vector2.new(cl.Z, -cl.X)
                end
                bestEscape = {
                    dir2D    = escDir.Unit,
                    danger   = danger,
                    isSlamming = isFalling and isAbove,
                    dist2D   = impactDist,
                }
            end
        end
    end

    if bestEscape then
        local d   = bestEscape.danger
        local dir = bestEscape.dir2D
        local lat = OCFG.AERIAL_ESCAPE_LATERAL * d
        local vertV = myHRP.AssemblyLinearVelocity.Y
        if bestEscape.isSlamming and bestEscape.dist2D < OCFG.AERIAL_AOE_RADIUS * 1.3 then
            vertV = OCFG.AERIAL_ESCAPE_UP * d
        elseif bestEscape.isSlamming then
            vertV = math.max(myHRP.AssemblyLinearVelocity.Y, 15 * d)
        end
        if myHum and myHum.FloorMaterial ~= Enum.Material.Air and vertV > 20 then
            myHum.Jump = true
        end
        myHRP.AssemblyLinearVelocity = Vector3.new(dir.X * lat, vertV, dir.Y * lat)
        return true
    end
    return false
end

local function omniStrategicVec(myHRP, threats)
    local rep = Vector3.new()
    local rp  = RaycastParams.new()
    rp.FilterDescendantsInstances = {_lplr.Character}
    for _, t in ipairs(threats) do
        local tHRP = t.HRP
        local diff = myHRP.Position - tHRP.Position
        local dist = diff.Magnitude
        local dir  = diff.Unit
        local look = tHRP.CFrame.LookVector:Dot(dir) < -0.5
        local jump = tHRP.AssemblyLinearVelocity.Y > 5
        if dist < OCFG.JUMP_DETECTION_DIST and jump then
            local m = look and OCFG.PING_BUFFER or 1.2
            local s = Vector3.new(dir.Z, 0, -dir.X)
            rep = rep + (dir * (3 * m)) + (s * OCFG.LATERAL_DODGE_MULT)
        else
            local tL = look and 2 or 1
            local w  = math.clamp(2 - (dist / OCFG.SAFE_DIST), 0, 3)
            rep = rep + (dir * (w * tL))
        end
    end
    for i = 1, 8 do
        local a  = math.rad(i * 45)
        local cd = Vector3.new(math.cos(a), 0, math.sin(a))
        local ray = workspace:Raycast(myHRP.Position, cd * OCFG.WALL_BUFFER, rp)
        if ray then rep = rep + (myHRP.Position - ray.Position).Unit * 2.5 end
    end
    return rep
end

-- ═══════════════════════════════════════════════════════════════════════════
--  START / STOP INTERNOS
-- ═══════════════════════════════════════════════════════════════════════════
local function omniStop()
    if omniInSky then omniDeactivate4D() end
    omniModeX = false; omniModeY = false; omniRmbHeld = false
    omniClearESP()
    if omniHeartbeat  then disconnectTracked(omniHeartbeat);  omniHeartbeat  = nil end
    if omniInputBegin then disconnectTracked(omniInputBegin); omniInputBegin = nil end
    if omniInputEnd   then disconnectTracked(omniInputEnd);   omniInputEnd   = nil end
    if omniCharConn   then disconnectTracked(omniCharConn);   omniCharConn   = nil end
end

local function omniStart()
    omniHeartbeat = trackConnection(RunService.Heartbeat:Connect(function(dt)
        local char  = _lplr.Character
        local myHRP = omniGetHRP(char)
        local hum   = char and char:FindFirstChildOfClass("Humanoid")

        if omniInSky then
            if not myHRP or not hum then return end
            omniLastCamCF = camera.CFrame
            local curHP = hum.Health
            if curHP < omniLastHealth - 0.5 then
                omniOrbiting = true; omniOrbitTimer = OCFG.ORBIT_DURATION; omniOrbitAngle = 0
            end
            omniLastHealth = curHP
            if omniOrbiting then
                omniOrbitTimer = omniOrbitTimer - dt
                if omniOrbitTimer <= 0 then omniOrbiting = false end
            end

            -- Detectar amenaza en el cielo (skyThreat)
            local skyThreat = nil
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= _lplr and p.Character then
                    local tHRP = p.Character:FindFirstChild("HumanoidRootPart")
                    if tHRP and (tHRP.Position - myHRP.Position).Magnitude < 50 then
                        skyThreat = tHRP
                        break
                    end
                end
            end

            if skyThreat then
                -- MODO ALERTA: movimiento errático y veloz
                omniApplyCloneColor(true)

                erraticTimer = erraticTimer - dt
                if erraticTimer <= 0 then
                    erraticTimer = math.random() * 0.3 + 0.1
                    local angle = math.rad(math.random() * 360)
                    erraticDir = Vector3.new(math.cos(angle), 0, math.sin(angle))
                    erraticSpeed = math.random() * 400 + 300
                end

                local vel = erraticDir * erraticSpeed
                myHRP.AssemblyLinearVelocity = Vector3.new(vel.X, myHRP.AssemblyLinearVelocity.Y, vel.Z)

                omniGroundPos = Vector3.new(myHRP.Position.X, omniGroundPos.Y, myHRP.Position.Z)

                if omniSkyBP2 then
                    omniSkyBP2.Position = Vector3.new(myHRP.Position.X, omniSkyWorldY, myHRP.Position.Z)
                end

            else
                -- COMPORTAMIENTO NORMAL: movimiento con WASD
                omniApplyCloneColor(omniOrbiting)

                local prevGroundPos = omniGroundPos
                local camLook  = camera.CFrame.LookVector
                local camRight = camera.CFrame.RightVector
                local fwd   = Vector3.new(camLook.X,  0, camLook.Z)
                local right = Vector3.new(camRight.X, 0, camRight.Z)
                if fwd.Magnitude   > 0 then fwd   = fwd.Unit   end
                if right.Magnitude > 0 then right = right.Unit end

                local move = Vector3.new()
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + fwd   end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - fwd   end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + right  end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - right  end

                if move.Magnitude > 0 then
                    local proposed = prevGroundPos + move.Unit * OCFG.DECOY_WALK_SPEED * dt
                    omniGroundPos = omniFollowGround(prevGroundPos,
                        Vector3.new(proposed.X, prevGroundPos.Y, proposed.Z), dt, char)
                end

                -- Salto del clon
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) and omniCloneJumpVel == 0 and omniCloneJumpOffset == 0 then
                    omniCloneJumpVel = OCFG.DECOY_JUMP_VELOCITY
                end
                if omniCloneJumpVel ~= 0 then
                    -- Se calcula la siguiente altura antes de mover el modelo y se
                    -- corta exactamente en cero: nunca se envía el clon bajo el suelo.
                    local nextJumpOffset = omniCloneJumpOffset
                        + omniCloneJumpVel * dt
                        - 0.5 * OCFG.DECOY_JUMP_GRAVITY * dt * dt
                    omniCloneJumpVel = omniCloneJumpVel - OCFG.DECOY_JUMP_GRAVITY * dt
                    if nextJumpOffset <= 0 then
                        omniCloneJumpOffset = 0
                        omniCloneJumpVel = 0
                    else
                        omniCloneJumpOffset = nextJumpOffset
                    end
                end

                -- Actualizar posición del clon usando PrimaryPart
                if omniCloneModel and omniCloneModel.PrimaryPart then
                    local flat = Vector3.new(camLook.X, 0, camLook.Z)
                    local yaw  = flat.Magnitude > 0.01
                        and math.atan2(-flat.X, -flat.Z)
                        or  select(2, omniCloneModel.PrimaryPart.CFrame:ToEulerAnglesYXZ())
                    local clonePos = Vector3.new(
                        omniGroundPos.X,
                        omniGroundPos.Y + omniCloneFootOffset + omniCloneJumpOffset + (OCFG.CLONE_VISUAL_Y_OFFSET or 0),
                        omniGroundPos.Z)
                    local newCF = CFrame.new(clonePos) * CFrame.Angles(0, yaw, 0)
                    omniCloneModel:PivotTo(newCF)
                end

                -- Actualizar cámara
                if omniCamSubjectPart then
                    omniCamSubjectPart.CFrame = CFrame.new(
                        omniGroundPos.X,
                        omniGroundPos.Y + omniCloneJumpOffset + OCFG.DECOY_HEAD_Y,
                        omniGroundPos.Z)
                end

                -- Actualizar BodyPosition según órbita o normal
                if omniSkyBP2 then
                    if omniOrbiting then
                        omniOrbitAngle = omniOrbitAngle + OCFG.ORBIT_SPEED * dt
                        local ox = omniGroundPos.X + math.cos(omniOrbitAngle) * OCFG.ORBIT_RADIUS
                        local oz = omniGroundPos.Z + math.sin(omniOrbitAngle) * OCFG.ORBIT_RADIUS
                        omniSkyBP2.Position = Vector3.new(ox, omniSkyWorldY, oz)
                    else
                        omniSkyBP2.Position = Vector3.new(omniGroundPos.X, omniSkyWorldY, omniGroundPos.Z)
                    end
                end
            end

            -- Teleport en spam para corregir altitud del personaje real
            if omniInSky and myHRP then
                local desiredY = omniSkyWorldY
                local currentY = myHRP.Position.Y
                if math.abs(currentY - desiredY) > 5 then
                    myHRP.CFrame = CFrame.new(myHRP.Position.X, desiredY, myHRP.Position.Z)
                                 * (myHRP.CFrame - myHRP.CFrame.Position)
                end
            end

            omniUpdatePublicState(omniBuildThreats(myHRP))
            omniUpdateESP(omniGroundPos)
            return
        end

        -- Fuera del modo 4D
        omniUpdateESP(myHRP and myHRP.Position)
        if myHRP then omniUpdatePublicState(omniBuildThreats(myHRP)) else omniUpdatePublicState({}) end
        if not omniModeX or not myHRP or (hum and hum.Health <= 0) then return end

        local threats = omniBuildThreats(myHRP)
        local mainThreat = threats[1] and threats[1].HRP or nil

        local aerialHandled = omniHandleAerial(myHRP, hum, threats)

        if mainThreat then
            local lookPoint = Vector3.new(mainThreat.Position.X, myHRP.Position.Y, mainThreat.Position.Z)
            myHRP.CFrame = myHRP.CFrame:Lerp(CFrame.lookAt(myHRP.Position, lookPoint), OCFG.ROTATION_SMOOTH)
            if not aerialHandled then
                local forceVec = omniStrategicVec(myHRP, threats)
                if forceVec.Magnitude > 0 then
                    local spd = math.clamp(forceVec.Magnitude * OCFG.DASH_FORCE_BASE, 0, OCFG.MAX_VELOCITY)
                    local vel = forceVec.Unit * spd
                    myHRP.AssemblyLinearVelocity = Vector3.new(vel.X, myHRP.AssemblyLinearVelocity.Y, vel.Z)
                end
            end
            camera.CFrame = camera.CFrame:Lerp(
                CFrame.lookAt(camera.CFrame.Position, mainThreat.Position), 0.1)
        end
    end))

    omniInputBegin = trackConnection(UserInputService.InputBegan:Connect(function(input, gp)
        if gp or not enabled then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 and omniInSky then
            if omni4DPinned then
                omniSetPinned(false)
                omniDeactivate4D()
            else
                omniSetPinned(true)
            end
            return
        end
        if input.KeyCode == _keys.OmniBlock then
            omniModeX = true
            if omniRmbHeld and not omniInSky then omniModeY = true; omniActivate4D() end
        end
        if input.KeyCode == _keys.Omni4D then
            if not omniInSky then omniActivate4D() end
        end
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            omniRmbHeld = true
            if omniModeX and not omniInSky then omniModeY = true; omniActivate4D() end
        end
    end))

    omniInputEnd = trackConnection(UserInputService.InputEnded:Connect(function(input)
        if input.KeyCode == _keys.OmniBlock then
            omniModeX = false; omniClearESP()
            if omniInSky and not omni4DPinned then omniModeY = false; omniDeactivate4D() end
        end
        if input.KeyCode == _keys.Omni4D then
            if omniInSky and not omni4DPinned then omniModeY = false; omniDeactivate4D() end
        end
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            omniRmbHeld = false
            if omniInSky and not omni4DPinned then omniModeY = false; omniDeactivate4D() end
        end
    end))

    omniCharConn = trackConnection(_lplr.CharacterRemoving:Connect(function()
        omniModeX = false; omniModeY = false; omniRmbHeld = false; omni4DPinned = false
        if omniInSky then
            omniInSky = false; omniOrbiting = false
            if omniSkyBV  then omniSkyBV:Destroy();  omniSkyBV  = nil end
            if omniSkyBP2 then omniSkyBP2:Destroy(); omniSkyBP2 = nil end
        end
        local char = _lplr.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if hum then camera.CameraSubject = hum end
        omniDestroyDecoy(); omniDestroyCamSubject(); omniClearESP()
    end))
end

-- ═══════════════════════════════════════════════════════════════════════════
--  API PÚBLICA
-- ═══════════════════════════════════════════════════════════════════════════

function M.Start(Keys, lplr)
    if enabled then M.Stop() end
    _keys   = Keys
    _lplr   = lplr
    enabled = true
    omniStart()
end

function M.Stop()
    enabled = false
    omniStop()
    disconnectAllConnections()
end

function M.Set4DKey(kc)
    if _keys then _keys.Omni4D = kc end
end

function M.IsBlocking()
    return omniModeX
end

function M.Is4DActive()
    return omniInSky
end

function M.Is4DPinned()
    return omni4DPinned
end

function M.SetLockModule(lockModule)
    omniLockModuleRef = type(lockModule) == "table" and lockModule or nil
end

function M.GetThreatState()
    return omniPublicState
end

getgenv().AFO_OMNIBLOCK_API = M

return M
