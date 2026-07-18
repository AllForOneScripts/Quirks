-- ═══════════════════════════════════════════════════════════════════════════
--  CONFIG
-- ═══════════════════════════════════════════════════════════════════════════

local cloneref = cloneref or function(x) return x end

local M = {}

local Players          = cloneref(game:GetService("Players"))
local RunService       = cloneref(game:GetService("RunService"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local Debris           = game:GetService("Debris")

local camera = workspace.CurrentCamera

local OCFG = {
    SAFE_DIST = 20, WALL_BUFFER = 8,
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

    PRED_SAMPLES      = 30,
    PRED_DT           = 0.03,
    PRED_MAX_TIME     = 2.5,
    PRED_THREAT_SPEED = 25,
}

-- ═══════════════════════════════════════════════════════════════════════════
--  ESTADO
-- ═══════════════════════════════════════════════════════════════════════════
local enabled = false
local _lplr, _keys

local omniModeX = false
local omniESP = {}
local omniHeartbeat = nil
local omniInputBegin = nil
local omniInputEnd = nil
local omniCharConn = nil

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
--  LINES (ESP)
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
--  AERIAL (INTELIGENCIA DE ESQUIVA, SIN DIBUJO)
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
    omniModeX = false
    omniClearESP()
    if omniHeartbeat  then disconnectTracked(omniHeartbeat);  omniHeartbeat  = nil end
    if omniInputBegin then disconnectTracked(omniInputBegin); omniInputBegin = nil end
    if omniInputEnd   then disconnectTracked(omniInputEnd);   omniInputEnd   = nil end
    if omniCharConn   then disconnectTracked(omniCharConn);   omniCharConn   = nil end
end

local function omniStart()
    omniHeartbeat = trackConnection(RunService.Heartbeat:Connect(function()
        local char  = _lplr.Character
        local myHRP = omniGetHRP(char)
        local hum   = char and char:FindFirstChildOfClass("Humanoid")

        -- Actualizar ESP
        omniUpdateESP(myHRP and myHRP.Position)

        if not omniModeX or not myHRP or (hum and hum.Health <= 0) then return end

        local threats   = {}
        local mainThreat = nil
        local minDist    = math.huge

        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= _lplr and p.Character then
                local tHRP = omniGetHRP(p.Character)
                local tHum = p.Character:FindFirstChildOfClass("Humanoid")
                if tHRP and tHum and tHum.Health > 0 then
                    local dist = (tHRP.Position - myHRP.Position).Magnitude
                    if dist < 100 then
                        table.insert(threats, {HRP = tHRP, Hum = tHum, Player = p})
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
            camera.CFrame = camera.CFrame:Lerp(
                CFrame.lookAt(camera.CFrame.Position, mainThreat.Position), 0.1)
        end
    end))

    omniInputBegin = trackConnection(UserInputService.InputBegan:Connect(function(input, gp)
        if gp or not enabled then return end
        if input.KeyCode == _keys.OmniBlock then
            omniModeX = true
        end
    end))

    omniInputEnd = trackConnection(UserInputService.InputEnded:Connect(function(input)
        if input.KeyCode == _keys.OmniBlock then
            omniModeX = false
            omniClearESP()
        end
    end))

    omniCharConn = trackConnection(_lplr.CharacterRemoving:Connect(function()
        omniModeX = false
        omniClearESP()
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

function M.IsBlocking()
    return omniModeX
end

return M
