local cloneref = cloneref or function(x) return x end

local M = {}

local Players      = cloneref(game:GetService("Players"))
local RunService    = cloneref(game:GetService("RunService"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local Debris        = game:GetService("Debris")

local camera = workspace.CurrentCamera

-- ═══════════════════════════════════════════════════════════════════════════
--  CONFIG
-- ═══════════════════════════════════════════════════════════════════════════
local OCFG = {
    SAFE_DIST = 20, WALL_BUFFER = 8,
    DASH_FORCE_BASE = 65, MAX_VELOCITY = 120, ROTATION_SMOOTH = 0.85,
    AERIAL_DETECT_DIST = 35, AERIAL_HEIGHT_THRESHOLD = 4,
    AERIAL_ESCAPE_UP = 55, AERIAL_ESCAPE_LATERAL = 90, AERIAL_AOE_RADIUS = 12,
    SLAM_PREDICT_FRAMES = 8, JUMP_VEL_THRESHOLD = 3, JUMP_DETECTION_DIST = 25,
    LATERAL_DODGE_MULT = 2.5, PING_BUFFER = 1.8, MAX_ESP_DIST = 60,
    BASE_THICKNESS = 2.5, MAX_THICKNESS = 22,
    NEON_SAFE = Color3.fromRGB(0,255,255), NEON_MID = Color3.fromRGB(255,255,0),
    NEON_DANGER = Color3.fromRGB(255,30,120), OUTLINE_ALPHA = 0.65, GLOW_EXTRA = 5,
    DECOY_WALK_SPEED = 135, SKY_ALTITUDE = 1500, SKY_BP_P = 60000,
    SKY_BP_D = 2500, SKY_MAXFORCE = 1e8, ORBIT_RADIUS = 55,
    ORBIT_SPEED = 6, ORBIT_DURATION = 4, DECOY_HEAD_Y = 3,
    SND_ACTIVATE = "rbxassetid://121724991975758",
    SND_DEACTIVATE = "rbxassetid://128617187053393",

    -- Seguimiento de terreno del clon (subir/bajar)
    CLIMB_STEP_MAX     = 1.8,  -- altura máx. que el clon puede SUBIR de golpe (escalón)
    DESCEND_STEP_MAX   = 2.2,  -- caída máx. que el clon puede BAJAR (rampa/escalón)
    GROUND_PROBE_AHEAD = 1.5,  -- distancia horizontal de sondeo hacia delante
    MAX_VERTICAL_SPEED = 24,   -- studs/seg, límite de cambio de altura (suaviza rampas)
}

-- ═══════════════════════════════════════════════════════════════════════════
--  ESTADO
-- ═══════════════════════════════════════════════════════════════════════════
local enabled = false

local _lplr, _keys

local omniModeX = false; local omniModeY = false; local omniRmbHeld = false
local omniInSky = false; local omniESP = {}; local omniSkyBP = nil
local omniSkyWorldY = 0; local omniGroundPos = Vector3.new()
local omniFootOffset = 3 -- distancia del centro del HRP al suelo (se recalcula al activar)
local omniOrbiting = false; local omniOrbitAngle = 0
local omniOrbitTimer = 0; local omniLastHealth = 100
local omniLastCamCF = nil; local omniCamSubjectPart = nil
local omniHeartbeat = nil; local omniInputBegin = nil
local omniInputEnd = nil; local omniCharConn = nil
local omniCloneModel = nil; local omniCloneHighlight = nil
local omniCloneOrigColors = {}; local omniCloneJumpOffset = 0; local omniCloneJumpVel = 0

-- ═══════════════════════════════════════════════════════════════════════════
--  GESTOR DE CONEXIONES
-- ═══════════════════════════════════════════════════════════════════════════
local allConnections = {}
local function trackConnection(conn) table.insert(allConnections, conn); return conn end
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
--  HELPERS
-- ═══════════════════════════════════════════════════════════════════════════
local function omniGetHRP(char) return char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")) end

local function omniHRPFootOffset(char)
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local hrp = omniGetHRP(char)
    if hum and hrp then return hum.HipHeight + hrp.Size.Y / 2 end
    return 3
end

local function omniPlaySound(id)
    local snd = Instance.new("Sound", workspace); snd.SoundId = id; snd.Volume = 1.5; snd:Play(); Debris:AddItem(snd, 6)
end

local function omniClearESP()
    for _, d in pairs(omniESP) do
        if d.line then d.line.Visible = false end
        if d.outline then d.outline.Visible = false end
        if d.glow then d.glow.Visible = false end
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
--  SEGUIMIENTO DE TERRENO (subir escalones, bajar rampas, evitar el vacío)
-- ═══════════════════════════════════════════════════════════════════════════
local function omniFollowGround(prevPos, newPosXZ, dt)
    local moveDelta = Vector3.new(newPosXZ.X - prevPos.X, 0, newPosXZ.Z - prevPos.Z)
    if moveDelta.Magnitude < 0.01 then return newPosXZ end

    local char = _lplr and _lplr.Character
    local rayParam = RaycastParams.new()
    rayParam.FilterType = Enum.RaycastFilterType.Exclude
    local exclude = {}
    if char then table.insert(exclude, char) end
    if omniCloneModel then table.insert(exclude, omniCloneModel) end
    rayParam.FilterDescendantsInstances = exclude

    local forwardDir = moveDelta.Unit
    local curY = prevPos.Y
    local maxStep = OCFG.MAX_VERTICAL_SPEED * dt

    local footOrigin = Vector3.new(prevPos.X, curY - omniFootOffset + 0.15, prevPos.Z)
    local hitWall = workspace:Raycast(footOrigin, forwardDir * OCFG.GROUND_PROBE_AHEAD, rayParam)

    if hitWall then
        local topOrigin = Vector3.new(hitWall.Position.X, (curY - omniFootOffset) + OCFG.CLIMB_STEP_MAX + 0.1, hitWall.Position.Z)
        local hitTop = workspace:Raycast(topOrigin, Vector3.new(0, -(OCFG.CLIMB_STEP_MAX + 0.2), 0), rayParam)
        if hitTop then
            local stepHeight = hitTop.Position.Y - (curY - omniFootOffset)
            if stepHeight > 0.05 and stepHeight <= OCFG.CLIMB_STEP_MAX then
                local targetY = hitTop.Position.Y + omniFootOffset
                local diff = math.min(targetY - curY, maxStep)
                return Vector3.new(newPosXZ.X, curY + diff, newPosXZ.Z)
            end
        end
        return prevPos
    end

    local downOrigin = Vector3.new(newPosXZ.X, (curY - omniFootOffset) + 1, newPosXZ.Z)
    local hitGround = workspace:Raycast(downOrigin, Vector3.new(0, -(OCFG.DESCEND_STEP_MAX + 1), 0), rayParam)
    if hitGround then
        local dropHeight = (curY - omniFootOffset) - hitGround.Position.Y
        if dropHeight > OCFG.DESCEND_STEP_MAX then
            return prevPos
        elseif dropHeight > 0.05 then
            local targetY = hitGround.Position.Y + omniFootOffset
            local diff = math.max(targetY - curY, -maxStep)
            return Vector3.new(newPosXZ.X, curY + diff, newPosXZ.Z)
        else
            return Vector3.new(newPosXZ.X, curY, newPosXZ.Z)
        end
    end

    return prevPos
end

local function omniGetSnapY(pos, char)
    local rayParam = RaycastParams.new()
    rayParam.FilterType = Enum.RaycastFilterType.Exclude
    local exclude = {}
    if char then table.insert(exclude, char) end
    if omniCloneModel then table.insert(exclude, omniCloneModel) end
    rayParam.FilterDescendantsInstances = exclude
    local hit = workspace:Raycast(Vector3.new(pos.X, pos.Y + 5, pos.Z), Vector3.new(0, -50, 0), rayParam)
    if hit then return hit.Position.Y + omniFootOffset end
    return nil
end

-- ═══════════════════════════════════════════════════════════════════════════
--  ANTI-BOUNCE LANDING
-- ═══════════════════════════════════════════════════════════════════════════
local function omniAntiBounceLand(hrp, hum)
    if not hrp or not hum then return end
    pcall(function() hrp.AssemblyLinearVelocity = Vector3.new(0,0,0); hrp.AssemblyAngularVelocity = Vector3.new(0,0,0) end)
    local quickBounce = Instance.new("BodyVelocity")
    quickBounce.Velocity = Vector3.new(0,0,0); quickBounce.MaxForce = Vector3.new(9e9,9e9,9e9)
    quickBounce.Parent = hrp; hum.PlatformStand = true
    task.defer(function()
        pcall(function() quickBounce:Destroy() end)
        if hum and hum.Parent then hum.PlatformStand = false; hum:ChangeState(Enum.HumanoidStateType.Landed) end
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════
--  ESP / THREAT
-- ═══════════════════════════════════════════════════════════════════════════
local function omniNeonColor(t)
    t = math.clamp(t,0,1)
    if t < 0.5 then
        local f = t/0.5
        return Color3.new(OCFG.NEON_SAFE.R + (OCFG.NEON_MID.R-OCFG.NEON_SAFE.R)*f,
                          OCFG.NEON_SAFE.G + (OCFG.NEON_MID.G-OCFG.NEON_SAFE.G)*f,
                          OCFG.NEON_SAFE.B + (OCFG.NEON_MID.B-OCFG.NEON_SAFE.B)*f)
    else
        local f = (t-0.5)/0.5
        return Color3.new(OCFG.NEON_MID.R + (OCFG.NEON_DANGER.R-OCFG.NEON_MID.R)*f,
                          OCFG.NEON_MID.G + (OCFG.NEON_DANGER.G-OCFG.NEON_MID.G)*f,
                          OCFG.NEON_MID.B + (OCFG.NEON_DANGER.B-OCFG.NEON_MID.B)*f)
    end
end

local function omniThreatLevel(originPos, tHRP, tHum)
    local dist = (tHRP.Position-originPos).Magnitude
    local hp = tHum.Health / math.max(tHum.MaxHealth,1)
    local distT = 1 - math.clamp(dist/OCFG.MAX_ESP_DIST,0,1)
    local rVel = tHRP.AssemblyLinearVelocity
    local dir = originPos - tHRP.Position
    local spd = dir.Magnitude > 0 and math.max(0, -rVel:Dot(dir.Unit)) or 0
    return math.clamp(distT*0.5 + hp*0.25 + math.clamp(spd/40,0,1)*0.25, 0, 1)
end

-- ═══════════════════════════════════════════════════════════════════════════
--  DECOY / CLON
-- ═══════════════════════════════════════════════════════════════════════════
local function omniDestroyDecoy()
    if omniCloneHighlight then omniCloneHighlight.Parent = nil; omniCloneHighlight = nil end
    if omniCloneModel then omniCloneModel:Destroy(); omniCloneModel = nil end
    omniCloneOrigColors = {}; omniCloneJumpOffset = 0; omniCloneJumpVel = 0
end

local function omniApplyCloneColor(isOrbiting)
    if not omniCloneModel then return end
    for _, v in pairs(omniCloneModel:GetDescendants()) do
        if v:IsA("BasePart") then
            if isOrbiting then v.Color = Color3.fromRGB(255,0,0); v.Material = Enum.Material.Neon
            else local orig = omniCloneOrigColors[v]; if orig then v.Color = orig.Color; v.Material = orig.Material end end
        end
    end
    if omniCloneHighlight then
        if isOrbiting then omniCloneHighlight.FillColor = Color3.fromRGB(255,0,0); omniCloneHighlight.OutlineColor = Color3.fromRGB(255,80,80); omniCloneHighlight.FillTransparency = 0.4
        else omniCloneHighlight.FillColor = Color3.fromRGB(200,220,255); omniCloneHighlight.OutlineColor = Color3.fromRGB(180,200,255); omniCloneHighlight.FillTransparency = 0.55 end
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
        if v:IsA("BasePart") then omniCloneOrigColors[v] = {Color=v.Color, Material=v.Material}; v.Anchored = true; v.CanCollide = false end
    end
    clone.Parent = workspace
    omniCloneModel = clone
    local hrp = omniGetHRP(char)
    local cloneHRP = clone:FindFirstChild("HumanoidRootPart") or clone:FindFirstChild("Torso")
    if hrp and cloneHRP then
        cloneHRP.CFrame = CFrame.new(pos) * CFrame.Angles(0, select(2, hrp.CFrame:ToEulerAnglesYXZ()), 0)
    else
        pcall(function() clone:MoveTo(pos) end)
    end
    local hl = Instance.new("Highlight", clone)
    hl.FillColor = Color3.fromRGB(200,220,255); hl.OutlineColor = Color3.fromRGB(180,220,255)
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

-- ═══════════════════════════════════════════════════════════════════════════
--  4D MODE
-- ═══════════════════════════════════════════════════════════════════════════
local function omniActivate4D()
    if omniInSky then return end
    local char = _lplr.Character; local hrp = omniGetHRP(char)
    if not char or not hrp then return end
    omniInSky = true; omniOrbiting = false; omniOrbitAngle = 0; omniOrbitTimer = 0; omniLastCamCF = nil
    omniFootOffset = omniHRPFootOffset(char)
    omniGroundPos = hrp.Position; omniSkyWorldY = omniGroundPos.Y + OCFG.SKY_ALTITUDE
    omniCreateDecoy(omniGroundPos); omniCamSubjectPart = omniCreateCamSubject()
    local hum = char:FindFirstChildOfClass("Humanoid"); omniLastHealth = hum and hum.Health or 100
    for _, v in pairs(char:GetDescendants()) do
        if v:IsA("BasePart") or v:IsA("Decal") then v.LocalTransparencyModifier = 1 end
    end
    if omniSkyBP then omniSkyBP:Destroy() end
    omniSkyBP = Instance.new("BodyPosition", hrp)
    omniSkyBP.Name = "4DSkyBP"; omniSkyBP.Position = Vector3.new(omniGroundPos.X, omniSkyWorldY, omniGroundPos.Z)
    omniSkyBP.MaxForce = Vector3.new(OCFG.SKY_MAXFORCE, OCFG.SKY_MAXFORCE, OCFG.SKY_MAXFORCE)
    omniSkyBP.P = OCFG.SKY_BP_P; omniSkyBP.D = OCFG.SKY_BP_D
    local _fm = rawget(getgenv(), "_AFO_FLY_MODULE")
    if _fm and _fm.Bypass then _fm.Bypass(2, "omni4d_activate") end
    camera.CameraSubject = omniCamSubjectPart
    omniPlaySound(OCFG.SND_ACTIVATE)
end

local function omniDeactivate4D()
    if not omniInSky then return end
    omniInSky = false; omniOrbiting = false
    local char = _lplr.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then camera.CameraSubject = hum end
    if omniSkyBP then omniSkyBP:Destroy(); omniSkyBP = nil end
    if char then
        local hrp = omniGetHRP(char)
        if hrp then
            hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
            local _fm = rawget(getgenv(), "_AFO_FLY_MODULE")
            if _fm and _fm.Bypass then _fm.Bypass(0.5, "omni4d_deactivate") end

            local landPos
            local cloneHRP = omniCloneModel and (omniCloneModel:FindFirstChild("HumanoidRootPart") or omniCloneModel:FindFirstChild("Torso"))
            local landCF
            if cloneHRP then
                landPos = cloneHRP.Position
                landCF = CFrame.new(landPos) * CFrame.Angles(0, select(2, cloneHRP.CFrame:ToEulerAnglesYXZ()), 0)
            else
                landPos = omniGroundPos
                landCF = CFrame.new(landPos)
                if omniLastCamCF then
                    local look = omniLastCamCF.LookVector; local flat = Vector3.new(look.X,0,look.Z)
                    if flat.Magnitude > 0.01 then
                        landCF = CFrame.new(landPos) * CFrame.Angles(0, math.atan2(-flat.X, -flat.Z), 0)
                    end
                end
            end

            local snapY = omniGetSnapY(landPos, char)
            if snapY then
                landCF = CFrame.new(landPos.X, snapY, landPos.Z) * (landCF - landCF.Position)
            end

            hrp.CFrame = landCF
            omniAntiBounceLand(hrp, hum)
            task.defer(function()
                if hum and hum.Parent then hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true) end
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
--  ESP UPDATE
-- ═══════════════════════════════════════════════════════════════════════════
local function omniUpdateESP(originPos)
    if not omniModeX then omniClearESP() return end
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
                        local col = omniNeonColor(threat)
                        local thick = OCFG.BASE_THICKNESS + (threat^1.3) * (OCFG.MAX_THICKNESS - OCFG.BASE_THICKNESS)
                        local from2 = Vector2.new(myOrig.X, myOrig.Y)
                        local to2 = Vector2.new(sp.X, sp.Y)
                        d.glow.Visible = true; d.glow.From = from2; d.glow.To = to2; d.glow.Color = col; d.glow.Thickness = thick + OCFG.GLOW_EXTRA + 6
                        d.outline.Visible = true; d.outline.From = from2; d.outline.To = to2; d.outline.Thickness = thick + OCFG.GLOW_EXTRA
                        d.line.Visible = true; d.line.From = from2; d.line.To = to2; d.line.Color = col; d.line.Thickness = thick
                    else d.line.Visible = false; d.outline.Visible = false; d.glow.Visible = false end
                elseif omniESP[p] then
                    if omniESP[p].line then omniESP[p].line.Visible = false end
                    if omniESP[p].outline then omniESP[p].outline.Visible = false end
                    if omniESP[p].glow then omniESP[p].glow.Visible = false end
                end
            elseif omniESP[p] then
                if omniESP[p].line then omniESP[p].line.Visible = false end
                if omniESP[p].outline then omniESP[p].outline.Visible = false end
                if omniESP[p].glow then omniESP[p].glow.Visible = false end
            end
        end
    end
    for p in pairs(omniESP) do
        if not p.Character or not p.Parent then
            if omniESP[p].line then omniESP[p].line:Remove() end
            if omniESP[p].outline then omniESP[p].outline:Remove() end
            if omniESP[p].glow then omniESP[p].glow:Remove() end
            omniESP[p] = nil
        end
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
--  AERIAL / STRATEGIC DODGE
-- ═══════════════════════════════════════════════════════════════════════════
local function omniHandleAerial(myHRP, myHum, threats)
    local bestEscape, highestDanger = nil, 0
    for _, t in ipairs(threats) do
        local tHRP = t.HRP; local tVel = tHRP.AssemblyLinearVelocity
        local dist2D = Vector2.new(tHRP.Position.X - myHRP.Position.X, tHRP.Position.Z - myHRP.Position.Z).Magnitude
        local heightAbove = tHRP.Position.Y - myHRP.Position.Y
        local isAbove = heightAbove > OCFG.AERIAL_HEIGHT_THRESHOLD
        local isFalling = tVel.Y < -OCFG.JUMP_VEL_THRESHOLD or math.abs(tVel.Y) < 2
        local isJumpingUp = tVel.Y > OCFG.JUMP_VEL_THRESHOLD and heightAbove > 0
        if dist2D < OCFG.AERIAL_DETECT_DIST and (isAbove or isJumpingUp) then
            local pred = tHRP.Position + tVel * (OCFG.SLAM_PREDICT_FRAMES / 60)
            local predD = Vector2.new(pred.X - myHRP.Position.X, pred.Z - myHRP.Position.Z).Magnitude
            local danger = 0
            if isFalling and isAbove then
                danger = math.clamp(1 - (dist2D / OCFG.AERIAL_DETECT_DIST), 0.4, 1) + (predD < OCFG.AERIAL_AOE_RADIUS and 0.5 or 0)
            elseif isJumpingUp then
                danger = math.clamp(1 - (dist2D / OCFG.AERIAL_DETECT_DIST), 0.2, 0.7)
            end
            danger = math.clamp(danger, 0, 1)
            if danger > highestDanger then
                highestDanger = danger
                local esc = Vector2.new(myHRP.Position.X - pred.X, myHRP.Position.Z - pred.Z)
                if esc.Magnitude < 0.1 then
                    local cl = camera.CFrame.LookVector
                    esc = Vector2.new(cl.Z, -cl.X)
                end
                bestEscape = {dir2D = esc.Unit, danger = danger, isSlamming = isFalling and isAbove, dist2D = dist2D}
            end
        end
    end
    if bestEscape then
        local d = bestEscape.danger; local dir = bestEscape.dir2D
        local lat = OCFG.AERIAL_ESCAPE_LATERAL * d
        local vertV = myHRP.AssemblyLinearVelocity.Y
        if bestEscape.isSlamming and bestEscape.dist2D < OCFG.AERIAL_AOE_RADIUS * 1.3 then
            vertV = OCFG.AERIAL_ESCAPE_UP * d
        elseif bestEscape.isSlamming then
            vertV = math.max(myHRP.AssemblyLinearVelocity.Y, 15 * d)
        end
        if myHum and myHum.FloorMaterial ~= Enum.Material.Air and vertV > 20 then myHum.Jump = true end
        myHRP.AssemblyLinearVelocity = Vector3.new(dir.X * lat, vertV, dir.Y * lat)
        return true
    end
    return false
end

local function omniStrategicVec(myHRP, threats)
    local rep = Vector3.new()
    local rayParam = RaycastParams.new()
    rayParam.FilterDescendantsInstances = {_lplr.Character}
    for _, t in ipairs(threats) do
        local tHRP = t.HRP
        local diff = myHRP.Position - tHRP.Position
        local dist = diff.Magnitude
        local dir = diff.Unit
        local look = tHRP.CFrame.LookVector:Dot(dir) < -0.5
        local jump = tHRP.AssemblyLinearVelocity.Y > 5
        if dist < OCFG.JUMP_DETECTION_DIST and jump then
            local m = look and OCFG.PING_BUFFER or 1.2
            local s = Vector3.new(dir.Z, 0, -dir.X)
            rep = rep + (dir * (3 * m)) + (s * OCFG.LATERAL_DODGE_MULT)
        else
            local tL = look and 2 or 1
            local w = math.clamp(2 - (dist / OCFG.SAFE_DIST), 0, 3)
            rep = rep + (dir * (w * tL))
        end
    end
    for i = 1, 8 do
        local a = math.rad(i * 45)
        local cd = Vector3.new(math.cos(a), 0, math.sin(a))
        local ray = workspace:Raycast(myHRP.Position, cd * OCFG.WALL_BUFFER, rayParam)
        if ray then rep = rep + (myHRP.Position - ray.Position).Unit * 2.5 end
    end
    return rep
end

-- ═══════════════════════════════════════════════════════════════════════════
--  START / STOP
-- ═══════════════════════════════════════════════════════════════════════════
local function omniStop()
    if omniInSky then omniDeactivate4D() end
    omniModeX = false; omniModeY = false; omniRmbHeld = false; omniClearESP()
    if omniHeartbeat then disconnectTracked(omniHeartbeat); omniHeartbeat = nil end
    if omniInputBegin then disconnectTracked(omniInputBegin); omniInputBegin = nil end
    if omniInputEnd then disconnectTracked(omniInputEnd); omniInputEnd = nil end
    if omniCharConn then disconnectTracked(omniCharConn); omniCharConn = nil end
end

local function omniStart()
    omniHeartbeat = trackConnection(RunService.Heartbeat:Connect(function(dt)
        local char = _lplr.Character
        local myHRP = omniGetHRP(char)
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if omniInSky then
            if not myHRP or not hum then return end
            omniLastCamCF = camera.CFrame
            local curHP = hum.Health
            if curHP < omniLastHealth - 0.5 then omniOrbiting = true; omniOrbitTimer = OCFG.ORBIT_DURATION; omniOrbitAngle = 0 end
            omniLastHealth = curHP
            if omniOrbiting then omniOrbitTimer = omniOrbitTimer - dt; if omniOrbitTimer <= 0 then omniOrbiting = false end end

            local prevGroundPos = omniGroundPos
            do
                local camLook = camera.CFrame.LookVector
                local camRight = camera.CFrame.RightVector
                local fwd = Vector3.new(camLook.X, 0, camLook.Z)
                local right = Vector3.new(camRight.X, 0, camRight.Z)
                if fwd.Magnitude > 0 then fwd = fwd.Unit end
                if right.Magnitude > 0 then right = right.Unit end
                local move = Vector3.new()
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + fwd end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - fwd end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + right end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - right end
                if move.Magnitude > 0 then
                    local proposedXZ = prevGroundPos + move.Unit * OCFG.DECOY_WALK_SPEED * dt
                    omniGroundPos = omniFollowGround(prevGroundPos, Vector3.new(proposedXZ.X, prevGroundPos.Y, proposedXZ.Z), dt)
                end
            end

            if UserInputService:IsKeyDown(Enum.KeyCode.Space) and omniCloneJumpVel == 0 then omniCloneJumpVel = 28 end
            if omniCloneJumpVel ~= 0 or omniCloneJumpOffset ~= 0 then
                omniCloneJumpVel = omniCloneJumpVel - 80 * dt
                omniCloneJumpOffset = omniCloneJumpOffset + omniCloneJumpVel * dt
                if omniCloneJumpOffset < 0 then omniCloneJumpOffset = 0; omniCloneJumpVel = 0 end
            end
            if omniCloneModel then
                local cloneHRP = omniCloneModel:FindFirstChild("HumanoidRootPart") or omniCloneModel:FindFirstChild("Torso")
                if cloneHRP then
                    local camLook = camera.CFrame.LookVector
                    local flat = Vector3.new(camLook.X, 0, camLook.Z)
                    local yaw = flat.Magnitude > 0.01 and math.atan2(-flat.X, -flat.Z) or select(2, cloneHRP.CFrame:ToEulerAnglesYXZ())
                    local clonePos = Vector3.new(omniGroundPos.X, omniGroundPos.Y + omniCloneJumpOffset, omniGroundPos.Z)
                    local newRootCF = CFrame.new(clonePos) * CFrame.Angles(0, yaw, 0)
                    local oldRootCF = cloneHRP.CFrame
                    local delta = newRootCF * oldRootCF:Inverse()
                    for _, v in pairs(omniCloneModel:GetDescendants()) do
                        if v:IsA("BasePart") then v.CFrame = delta * v.CFrame end
                    end
                else
                    pcall(function() omniCloneModel:MoveTo(Vector3.new(omniGroundPos.X, omniGroundPos.Y + omniCloneJumpOffset, omniGroundPos.Z)) end)
                end
            end
            if omniCamSubjectPart then
                omniCamSubjectPart.CFrame = CFrame.new(omniGroundPos.X, omniGroundPos.Y + omniCloneJumpOffset + OCFG.DECOY_HEAD_Y, omniGroundPos.Z)
            end
            if omniSkyBP then
                local skyThreat = nil
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= _lplr and p.Character then
                        local tHRP = p.Character:FindFirstChild("HumanoidRootPart")
                        if tHRP and (tHRP.Position - myHRP.Position).Magnitude < 50 then skyThreat = tHRP; break end
                    end
                end
                if skyThreat then
                    omniApplyCloneColor(true)
                    local orbitPhase = math.sin(tick() * 8)
                    omniSkyBP.Position = Vector3.new(omniGroundPos.X + orbitPhase * 500, omniSkyWorldY, omniGroundPos.Z)
                elseif omniOrbiting then
                    omniApplyCloneColor(false)
                    omniOrbitAngle = omniOrbitAngle + OCFG.ORBIT_SPEED * dt
                    omniSkyBP.Position = Vector3.new(omniGroundPos.X + math.cos(omniOrbitAngle) * OCFG.ORBIT_RADIUS, omniSkyWorldY, omniGroundPos.Z + math.sin(omniOrbitAngle) * OCFG.ORBIT_RADIUS)
                else
                    omniApplyCloneColor(false)
                    omniSkyBP.Position = Vector3.new(omniGroundPos.X, omniSkyWorldY, omniGroundPos.Z)
                end
            end
            do
                local hx, hz = myHRP.Position.X, myHRP.Position.Z
                if math.abs(hx - omniGroundPos.X) > 0.5 or math.abs(hz - omniGroundPos.Z) > 0.5 then
                    local _, yaw, _ = myHRP.CFrame:ToEulerAnglesYXZ()
                    myHRP.CFrame = CFrame.new(omniGroundPos.X, myHRP.Position.Y, omniGroundPos.Z) * CFrame.Angles(0, yaw, 0)
                end
            end
            omniUpdateESP(omniGroundPos)
            return
        end
        omniUpdateESP(myHRP and myHRP.Position)
        if not omniModeX or not myHRP or (hum and hum.Health <= 0) then return end
        local threats = {}
        local mainThreat = nil
        local minDist = math.huge
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= _lplr and p.Character then
                local tHRP = omniGetHRP(p.Character)
                local tHum = p.Character:FindFirstChildOfClass("Humanoid")
                if tHRP and tHum and tHum.Health > 0 then
                    local dist = (tHRP.Position - myHRP.Position).Magnitude
                    if dist < 100 then
                        table.insert(threats, {HRP = tHRP, Hum = tHum})
                        if dist < minDist then minDist = dist; mainThreat = tHRP end
                    end
                end
            end
        end
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
            camera.CFrame = camera.CFrame:Lerp(CFrame.lookAt(camera.CFrame.Position, mainThreat.Position), 0.1)
        end
    end))

    omniInputBegin = trackConnection(UserInputService.InputBegan:Connect(function(input, gp)
        if gp or not enabled then return end
        if input.KeyCode == _keys.OmniBlock then
            omniModeX = true
            if omniRmbHeld and not omniInSky then omniModeY = true; omniActivate4D() end
        end
        -- Tecla Modo 4D (configurable, distinta de OmniBlock)
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
            if omniInSky then omniModeY = false; omniDeactivate4D() end
        end
        -- Soltar la tecla Modo 4D también desactiva
        if input.KeyCode == _keys.Omni4D then
            if omniInSky then omniModeY = false; omniDeactivate4D() end
        end
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            omniRmbHeld = false
            if omniInSky then omniModeY = false; omniDeactivate4D() end
        end
    end))

    omniCharConn = trackConnection(_lplr.CharacterRemoving:Connect(function()
        omniModeX = false; omniModeY = false; omniRmbHeld = false
        if omniInSky then omniInSky = false; omniOrbiting = false; if omniSkyBP then omniSkyBP:Destroy(); omniSkyBP = nil end end
        local char = _lplr.Character; local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then camera.CameraSubject = hum end
        omniDestroyDecoy(); omniDestroyCamSubject(); omniClearESP()
    end))
end

-- ═══════════════════════════════════════════════════════════════════════════
--  API PÚBLICA
-- ═══════════════════════════════════════════════════════════════════════════

-- Inicia OmniBlock.
-- Keys debe tener los campos:
--   OmniBlock  (KeyCode) – tecla de bloqueo. NO es modificable en caliente.
--   Omni4D     (KeyCode) – tecla para activar/desactivar el Modo 4D. SÍ es modificable.
function M.Start(Keys, lplr)
    if enabled then M.Stop() end
    _keys = Keys
    _lplr = lplr
    enabled = true
    omniStart()
end

-- Detiene OmniBlock por completo (incluye salir del modo 4D si está activo).
function M.Stop()
    enabled = false
    omniStop()
    disconnectAllConnections()
end

-- Cambia en caliente SOLO la tecla del Modo 4D.
-- La tecla OmniBlock (F) es fija y no puede modificarse desde aquí.
function M.Set4DKey(kc)
    if _keys then _keys.Omni4D = kc end
end

-- ¿Está OmniBlock en modo bloqueo activo (tecla mantenida)?
function M.IsBlocking()
    return omniModeX
end

-- ¿Está el Modo 4D (clon + escudo en el cielo) activo en este momento?
function M.Is4DActive()
    return omniInSky
end

return M
