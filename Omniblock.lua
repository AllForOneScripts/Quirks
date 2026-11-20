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
local HttpService      = cloneref(game:GetService("HttpService"))

-- (camara resuelta dinamicamente con workspace.CurrentCamera en cada uso)

local OCFG = {
    SAFE_DIST = 15, WALL_BUFFER = 12,
    DASH_FORCE_BASE = 85, MAX_VELOCITY = 130, ROTATION_SMOOTH = 0.85, -- antes 125 / 200

    AERIAL_DETECT_DIST       = 35,
    AERIAL_HEIGHT_THRESHOLD  = 4,
    AERIAL_ESCAPE_UP         = 55,
    AERIAL_ESCAPE_LATERAL    = 70, -- antes 90
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
    DECOY_JUMP_VELOCITY = 40,
    DECOY_JUMP_GRAVITY  = 80,
    CLONE_NORMAL_GRAVITY = 196.2, 
    SKY_ALTITUDE     = 1500,
    SKY_LIFT_SPEED   = 600,
    SKY_HOLD_FORCE   = 9e8,
    ORBIT_RADIUS     = 55,
    ORBIT_SPEED      = 6,
    ORBIT_DURATION   = 4,
    DECOY_HEAD_Y     = 3,
    CLONE_GROUND_EPSILON = 0.03,
    
    SND_ACTIVATE     = "rbxassetid://121724991975758",
    SND_DEACTIVATE   = "rbxassetid://128617187053393",
    SND_PUSH_TOGGLE  = "rbxassetid://74292212867322",

    GROUND_SCAN_UP      = 160,
    GROUND_SCAN_DOWN    = 420,
    GROUND_NORMAL_MIN   = 0.35,
    MAX_AUTO_RECOVERY_RISE = 24,
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

    -- Rango de amenazas (empuje) y rango de las lineas ESP: iguales para que nunca te empuje
    -- sin que veas la linea de quien lo provoca (antes: empuje hasta 100, lineas solo hasta 60)
    THREAT_RANGE      = 100,
    ESP_LINE_DIST     = 100,

    -- Planificador en matriz (reemplaza al muestreo de 24 direcciones)
    -- El espacio alrededor se divide en una matriz GRID_N x GRID_N de celdas de GRID_CELL studs,
    -- centrada en ti. Cada celda tiene un riesgo; se busca la ruta/meta de menor exposicion.
    GRID_N        = 13,    -- celdas por lado (impar). Alcance = (N-1)/2 * CELL studs a cada lado
    GRID_CELL     = 7,     -- studs por celda
    GRID_SPEED    = 130,   -- tu velocidad de huida (igual que MAX_VELOCITY): para estimar tiempos
    GRID_PLAN_HZ  = 15,    -- replanificaciones por segundo (cada plan lanza ~800 rayos; bajalo si hay lag)

    GRID_RISK_D0       = 20,  -- distancia a la que el riesgo cae a 1/4. Mayor = huye mas lejos
    GRID_CORE_WEIGHT   = 4,   -- castigo extra por quedar dentro del radio de contacto de una amenaza
    GRID_CORE_RADIUS   = 14,  -- radio de contacto (studs)
    GRID_LEAD          = 0.6, -- horizonte (s) en que una amenaza puede avanzar hacia una celda
    GRID_THREAT_MIN_SPEED = 30,  -- velocidad minima que se supone a una amenaza (aunque este quieta)
    GRID_THREAT_MAX_SPEED = 130,

    GRID_STAY_TIME     = 3.0, -- cuanto pesa el riesgo del lugar de llegada frente al del trayecto
    GRID_GOAL_TIME     = 0.5, -- (s) instante en que se evalua el riesgo de la meta
    GRID_TIME_COST     = 0.12,-- leve preferencia por rutas cortas
    GRID_JUMP_COST     = 0.15,-- costo de saltar un obstaculo bajo
    GRID_COST_CAP      = 5,   -- no se expande por celdas con exposicion acumulada mayor

    GRID_OPEN_WEIGHT   = 1.2, -- preferencia por metas con espacio libre alrededor (evita callejones)
    GRID_TERR_TOPK     = 14,  -- cuantas metas candidatas se revisan por territorio
    GRID_TERR_WEIGHT   = 2.5, -- peso del territorio: celdas que alcanzas ANTES que cualquier amenaza
    GRID_HYST_RADIUS   = 3,   -- (celdas) radio de preferencia por la meta anterior
    GRID_HYST_WEIGHT   = 0.15,-- anti-temblor: sube si cambia de meta de un lado a otro
    GRID_MOVE_MARGIN   = 0.02,-- ventaja minima sobre quedarse quieto (si no hay huida forzada)
    GRID_LOOKAHEAD     = 3,   -- waypoints que se promedian para suavizar la direccion

    GRID_CORNER_RISK     = 1.0,  -- riesgo en tu celda a partir del cual se considera "arrinconado"
    GRID_BREAKOUT_COST   = 0.25, -- si salir cuesta mas que esto, es una ruptura de cerco
    GRID_CORNER_RATIO    = 0.6,  -- si la meta no reduce el riesgo por debajo de esta fraccion

    GRID_CHEST_OFFSET  = 0.5, -- altura (sobre el HRP) del rayo que detecta paredes
    GRID_SHIN_OFFSET   = 2,   -- altura (bajo el HRP) del rayo que detecta obstaculos bajos
    GRID_VOID_CHECK    = true,-- no considerar celdas sin suelo (evita empujarte al vacio)
    GRID_VOID_DEPTH    = 60,
    PUSH_TURN_RATE        = 16,   -- suavidad del giro (mas alto = gira mas brusco, mas bajo = arcos mas amplios)

    -- Aura del empuje: lente de agujero negro pegada a la silueta (capas de vidrio reflectivo
    -- apiladas + lineas oscuras entre ellas, como en la referencia). Local: solo tu la ves.
    AURA_STRENGTH   = 0.4,  -- intensidad global (sube para mas visible, baja para mas sutil)
    AURA_ALERT_MULT = 1.2,  -- cuanto se intensifica con un enemigo cerca
    AURA_LAYERS = {         -- de adentro hacia afuera
        -- pad: cuanto sobresale (studs) | transp: transparencia del vidrio | reflect: brillo espejo
        -- line / lineTransp: contorno oscuro de esa capa (nil = sin linea)
        { pad = 0.08, transp = 0.65, reflect = 0.2, color = Color3.fromRGB(255, 255, 255) }, -- vidrio neutro (sin tinte), pegado al cuerpo
        { pad = 0.16, transp = 0.45, reflect = 0.1, color = Color3.fromRGB(255, 255, 255) },
    },
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
local omniCloneFootOffset = 3
local omniOrbiting = false; local omniOrbitAngle = 0
local omniOrbitTimer = 0;   local omniLastHealth = 100
local omniLastCamCF = nil;  local omniCamSubjectPart = nil
local omniHeartbeat = nil;  local omniInputBegin = nil
local omniInputEnd = nil;   local omniCharConn = nil
local omniCloneModel = nil; local omniCloneHighlight = nil
local omniCloneOrigColors = {}; local omniCloneJumpOffset = 0; local omniCloneJumpVel = 0
local omniCloneTracks = {}
local omniCloneGravity = OCFG.DECOY_JUMP_GRAVITY
local omniCloneNormalGravity = OCFG.CLONE_NORMAL_GRAVITY
local omniCloneWasAirborne = false
local omni4DPinned = false; local omniPinGui = nil
local omniLockModuleRef = nil
local _pendingPushKey = nil -- tecla de empuje elegida desde el menu (sobrevive a Start/Stop)
local omniPushEnabled = true -- empuje del estado base (se alterna con R durante F o durante 4D)
local omniPublicState = { threats = {}, primary = nil, distances = {}, is4D = false, is4DPinned = false, mode4D = "off", cornered = false }
local omniLastPublicUpdate = 0

local erraticTimer = 0
local erraticDir = Vector3.new(1, 0, 0)
local erraticSpeed = 500

-- ═══════════════════════════════════════════════════════════════════════════
--  LECTURA SEGURA DE LA API DE MUI (CON PROTECCIÓN ANTE COLAPSOS)
-- ═══════════════════════════════════════════════════════════════════════════
local function omniGetMUIAPIState()
    local ok, result = pcall(function()
        local lplr = Players.LocalPlayer
        local char = lplr and lplr.Character
        
        if not char then
            return { success = false, errorMsg = "Personaje no encontrado", isAlarmActive = false, isSkyCloneActive = false, isTeleportingSoon = false, threats = {} }
        end

        local alarmVal = char:FindFirstChild("MUI_Alarm")
        local stateVal = char:FindFirstChild("MUI_SkyCloneState")
        local tpTimeVal = char:FindFirstChild("MUI_TeleportTime")
        local threatsVal = char:FindFirstChild("MUI_ThreatsData")

        if not alarmVal or not threatsVal then
            if type(getgenv) == "function" and getgenv().AFO_MUI_API then
                local muiStatus = getgenv().AFO_MUI_API.GetStatus()
                return {
                    success = true,
                    errorMsg = nil,
                    isAlarmActive = muiStatus.defenseActive,
                    isSkyCloneActive = muiStatus.lockActive,
                    isTeleportingSoon = false,
                    threats = muiStatus.markedThreats or {}
                }
            end

            return { success = false, errorMsg = "API no inicializada (MUI.lua no cargado)", isAlarmActive = false, isSkyCloneActive = false, isTeleportingSoon = false, threats = {} }
        end

        local threatsData = {}
        if threatsVal.Value and threatsVal.Value ~= "" then
            local okDec, decoded = pcall(function()
                return HttpService:JSONDecode(threatsVal.Value)
            end)
            if okDec and type(decoded) == "table" then
                threatsData = decoded
            end
        end

        return {
            success = true,
            errorMsg = nil,
            isAlarmActive = alarmVal.Value,
            isSkyCloneActive = stateVal and stateVal.Value or false,
            isTeleportingSoon = tpTimeVal and tpTimeVal.Value or false,
            threats = threatsData
        }
    end)

    if not ok or not result then
        return { success = false, errorMsg = "Error en llamada segura", isAlarmActive = false, isSkyCloneActive = false, isTeleportingSoon = false, threats = {} }
    end

    return result
end

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
    local footParts = {
        LeftFoot = true, RightFoot = true,
        LeftLowerLeg = true, RightLowerLeg = true,
        ["Left Leg"] = true, ["Right Leg"] = true,
    }
    for _, part in ipairs(clone:GetDescendants()) do
        if part:IsA("BasePart") and footParts[part.Name] then
            local half = part.Size * 0.5
            for _, sx in ipairs({-1, 1}) do
                for _, sy in ipairs({-1, 1}) do
                    for _, sz in ipairs({-1, 1}) do
                        local corner = part.CFrame:PointToWorldSpace(Vector3.new(half.X * sx, half.Y * sy, half.Z * sz))
                        lowestY = math.min(lowestY, primaryPart.CFrame:PointToObjectSpace(corner).Y)
                    end
                end
            end
        end
    end

    return lowestY == math.huge and 3 or -lowestY
end

local function omniReadGravityProfile()
    local current = workspace.Gravity
    local normal = omniCloneNormalGravity
    local gravityApi = rawget(getgenv(), "AFO_GRAVITY_API")
    if type(gravityApi) == "table" and type(gravityApi.GetGravityState) == "function" then
        local ok, state = pcall(gravityApi.GetGravityState)
        if ok and type(state) == "table" then
            if type(state.currentGravity) == "number" then current = state.currentGravity end
            if type(state.normalGravity) == "number" then normal = state.normalGravity end
        end
    end
    return math.max(current, 0), math.max(normal, 0)
end

local function omniSyncCloneAnimations()
    local char = _lplr and _lplr.Character
    local clone = omniCloneModel
    local sourceHum = char and char:FindFirstChildOfClass("Humanoid")
    local cloneHum = clone and clone:FindFirstChildOfClass("Humanoid")
    if not sourceHum or not cloneHum then return end

    local sourceAnimator = sourceHum:FindFirstChildOfClass("Animator")
    local cloneAnimator = cloneHum:FindFirstChildOfClass("Animator")
    if not sourceAnimator then return end
    if not cloneAnimator then
        cloneAnimator = Instance.new("Animator")
        cloneAnimator.Parent = cloneHum
    end

    local seen = {}
    for _, sourceTrack in ipairs(sourceAnimator:GetPlayingAnimationTracks()) do
        local animation = sourceTrack.Animation
        local id = animation and tostring(animation.AnimationId) or ""
        
        if string.find(id, "215384594") then continue end

        if id ~= "" then
            seen[id] = true
            local cloneTrack = omniCloneTracks[id]
            if not cloneTrack then
                local ok, track = pcall(function()
                    return cloneAnimator:LoadAnimation(animation)
                end)
                if ok and track then
                    cloneTrack = track
                    omniCloneTracks[id] = cloneTrack
                    cloneTrack.Priority = sourceTrack.Priority
                    cloneTrack:Play(0)
                end
            end
            if cloneTrack then
                cloneTrack.Priority = sourceTrack.Priority
                cloneTrack:AdjustSpeed(sourceTrack.Speed)
                cloneTrack:AdjustWeight(sourceTrack.WeightCurrent, 0)
                if math.abs(cloneTrack.TimePosition - sourceTrack.TimePosition) > 0.08 then
                    cloneTrack.TimePosition = sourceTrack.TimePosition
                end
            end
        end
    end

    for id, track in pairs(omniCloneTracks) do
        if not seen[id] then
            track:Stop(0.12)
            omniCloneTracks[id] = nil
        end
    end
end

local function omniSyncClonePose()
    local char = _lplr and _lplr.Character
    local clone = omniCloneModel
    if not char or not clone then return end

    for _, sourceMotor in ipairs(char:GetDescendants()) do
        if sourceMotor:IsA("Motor6D") then
            local names = {}
            local node = sourceMotor
            while node and node ~= char do
                table.insert(names, 1, node.Name)
                node = node.Parent
            end

            local target = clone
            for _, name in ipairs(names) do
                target = target and target:FindFirstChild(name)
            end
            if target and target:IsA("Motor6D") then
                target.Transform = sourceMotor.Transform
            end
        end
    end
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
--  TRAYECTORIA
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
--  SEGUIMIENTO DE TERRENO DEL CLON 
-- ═══════════════════════════════════════════════════════════════════════════
local function omniGetGroundHeight(pos, char)
    local rp = RaycastParams.new()
    rp.FilterType = Enum.RaycastFilterType.Exclude
    local excl = {}
    if char then table.insert(excl, char) end
    if omniCloneModel then table.insert(excl, omniCloneModel) end
    rp.FilterDescendantsInstances = excl
    
    local nearOrigin = Vector3.new(pos.X, pos.Y + 5, pos.Z)
    local nearHit = workspace:Raycast(nearOrigin, Vector3.new(0, -70, 0), rp)
    if nearHit and nearHit.Normal.Y >= OCFG.GROUND_NORMAL_MIN then
        return nearHit.Position.Y + omniFootOffset
    end

    if nearHit and nearHit.Instance:IsA("BasePart") then
        local part = nearHit.Instance
        local topY = part.Position.Y + part.Size.Y * 0.5 + 0.1
        local topOrigin = Vector3.new(pos.X, topY, pos.Z)
        local topHit = workspace:Raycast(topOrigin, Vector3.new(0, -math.max(part.Size.Y + 1, 3), 0), rp)
        if topHit and topHit.Instance == part and topHit.Normal.Y >= OCFG.GROUND_NORMAL_MIN then
            local recoveredY = topHit.Position.Y + omniFootOffset
            if recoveredY - pos.Y <= OCFG.MAX_AUTO_RECOVERY_RISE then
                return recoveredY
            end
        end
    end

    local origin = Vector3.new(pos.X, pos.Y + OCFG.GROUND_SCAN_UP, pos.Z)
    local direction = Vector3.new(0, -OCFG.GROUND_SCAN_DOWN, 0)
    for _ = 1, 8 do
        local hit = workspace:Raycast(origin, direction, rp)
        if not hit then break end
        if hit.Normal.Y >= OCFG.GROUND_NORMAL_MIN then
            local recoveredY = hit.Position.Y + omniFootOffset
            if recoveredY - pos.Y <= OCFG.MAX_AUTO_RECOVERY_RISE then
                return recoveredY
            end
            break
        end
        local used = (hit.Position - origin).Magnitude + 0.05
        if used >= direction.Magnitude then break end
        origin = hit.Position + direction.Unit * 0.05
        direction = Vector3.new(0, -(direction.Magnitude - used), 0)
    end
    return nil
end

local function omniFollowGround(prevPos, desiredXZ, dt, char)
    local newPos = Vector3.new(desiredXZ.X, prevPos.Y, desiredXZ.Z)
    local groundY = omniGetGroundHeight(newPos, char)
    if groundY then
        newPos = Vector3.new(newPos.X, groundY, newPos.Z)
    else
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
--  ESP / LINES
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
    if type(lock) ~= "table" then
        lock = rawget(getgenv(), "AFO_LOCK_API")
    end
    if type(lock) ~= "table" or type(lock.GetStatus) ~= "function" then return nil end

    local okStatus, status = pcall(lock.GetStatus)
    if not okStatus or type(status) ~= "table" or status.lockActive ~= true then
        return nil
    end

    local function getLivePlayer(player)
        local char = player and player.Character
        local root = omniGetHRP(char)
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if root and hum and hum.Health > 0 then return player end
        return nil
    end

    local target
    if type(lock.GetTarget) == "function" then
        local okTarget, value = pcall(lock.GetTarget)
        if okTarget then target = value end
    end
    local function resolvePlayer(candidate)
        if typeof(candidate) == "Instance" then
            if candidate:IsA("Player") then
                return getLivePlayer(candidate)
            elseif candidate:IsA("Model") then
                return getLivePlayer(Players:GetPlayerFromCharacter(candidate))
            elseif candidate:IsA("BasePart") then
                local model = candidate:FindFirstAncestorOfClass("Model")
                return getLivePlayer(model and Players:GetPlayerFromCharacter(model))
            end
        elseif type(candidate) == "table" then
            return resolvePlayer(candidate.player or candidate.targetPlayer
                or candidate.character or candidate.targetCharacter
                or candidate.root or candidate.targetRoot or candidate.target)
        end
        return nil
    end

    for _, candidate in pairs({
        target, status.targetPlayer, status.targetCharacter, status.targetRoot,
        status.player, status.target,
    }) do
        local player = resolvePlayer(candidate)
        if player then return player end
    end

    target = target or status.targetPlayer or status.targetCharacter or status.targetRoot
        or status.player or status.target

    if typeof(target) == "Instance" then
        if target:IsA("Player") then return getLivePlayer(target) end
        if target:IsA("Model") then
            return getLivePlayer(Players:GetPlayerFromCharacter(target))
        end
        if target:IsA("BasePart") then
            local model = target:FindFirstAncestorOfClass("Model")
            return getLivePlayer(model and Players:GetPlayerFromCharacter(model))
        end
    end

    local targetName = status.targetName
    if type(targetName) == "string" then
        targetName = targetName:gsub("^@", ""):lower()
        for _, player in ipairs(Players:GetPlayers()) do
            if player.Name:lower() == targetName or player.DisplayName:lower() == targetName then
                return getLivePlayer(player)
            end
        end
    end

    return nil
end

local function omniBuildThreats(myHRP)
    local locked = omniGetLockTarget()
    local threats = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= _lplr and p.Character then
            local hrp, hum = omniGetHRP(p.Character), p.Character:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 then
                local distance = (hrp.Position - myHRP.Position).Magnitude
                if distance < OCFG.THREAT_RANGE then
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
--  EXPOSICIÓN DE DATOS HACIA EL CHARACTER (API espejo de MUI)
-- ═══════════════════════════════════════════════════════════════════════════
local function omniUpdateExposedData()
    local char = _lplr and _lplr.Character
    if not char then return end

    local function ensureValue(name, className)
        local val = char:FindFirstChild(name)
        if not val or not val:IsA(className) then
            if val then val:Destroy() end
            val = Instance.new(className)
            val.Name = name
            val.Parent = char
        end
        return val
    end

    local activeVal = ensureValue("Omni_Active", "BoolValue")
    local skyStateVal = ensureValue("Omni_4DActive", "BoolValue")
    local pinnedVal = ensureValue("Omni_Pinned", "BoolValue")
    local threatsVal = ensureValue("Omni_ThreatsData", "StringValue")

    activeVal.Value = enabled
    skyStateVal.Value = omniInSky
    pinnedVal.Value = omni4DPinned

    local threatList = {}
    if omniPublicState and omniPublicState.threats then
        for _, t in ipairs(omniPublicState.threats) do
            table.insert(threatList, {
                Target = t.name,
                Distance = t.distance,
                Score = t.score,
                Locked = t.locked
            })
        end
    end

    local ok, json = pcall(function() return HttpService:JSONEncode(threatList) end)
    threatsVal.Value = ok and json or "[]"
end

-- ═══════════════════════════════════════════════════════════════════════════
--  CLON / DECOY
-- ═══════════════════════════════════════════════════════════════════════════
local function omniDestroyDecoy()
    if omniPinGui then omniPinGui:Destroy(); omniPinGui = nil end
    if omniCloneHighlight then omniCloneHighlight.Parent = nil; omniCloneHighlight = nil end
    if omniCloneModel then omniCloneModel:Destroy(); omniCloneModel = nil end
    omniCloneOrigColors = {}; omniCloneTracks = {}
    omniCloneJumpOffset = 0; omniCloneJumpVel = 0; omniCloneFootOffset = 3
    omniCloneGravity = OCFG.DECOY_JUMP_GRAVITY
    omniCloneNormalGravity = OCFG.CLONE_NORMAL_GRAVITY
    omniCloneWasAirborne = false
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
    
    omniCloneGravity, omniCloneNormalGravity = omniReadGravityProfile()
    for _, v in pairs(clone:GetDescendants()) do
        if v:IsA("Script") or v:IsA("LocalScript") or v:IsA("ModuleScript") then v:Destroy() end
    end
    for _, v in pairs(clone:GetDescendants()) do
        if v:IsA("BasePart") then
            omniCloneOrigColors[v] = {Color = v.Color, Material = v.Material}
            v.Anchored = false
            v.CanCollide = false; v.CanTouch = false; v.CanQuery = false
            v.Massless = true
        end
    end

    local hrp = omniGetHRP(char)
    local cloneHRP = clone:FindFirstChild("HumanoidRootPart") or clone:FindFirstChild("Torso")
    if cloneHRP then
        clone.PrimaryPart = cloneHRP
        cloneHRP.Anchored = true
    end
    clone.Parent = workspace
    omniCloneModel = clone

    if cloneHRP then
        omniCloneFootOffset = omniGetCloneFootOffset(clone, cloneHRP)
        local _, ry = cloneHRP.CFrame:ToEulerAnglesYXZ()
        local groundSurfaceY = pos.Y - omniFootOffset
        clone:PivotTo(CFrame.new(
            pos.X,
            groundSurfaceY + omniCloneFootOffset + OCFG.CLONE_GROUND_EPSILON,
            pos.Z
        ) * CFrame.Angles(0, ry, 0))
    end

    omniCloneGravity = omniCloneNormalGravity

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

    pcall(function()
        hrp.AssemblyLinearVelocity  = Vector3.new(0, 0, 0)
        hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
    end)
    local skyX, skyZ = hrp.Position.X, hrp.Position.Z
    hrp.CFrame = CFrame.new(skyX, omniSkyWorldY, skyZ)
                 * (hrp.CFrame - hrp.CFrame.Position)

    omniSkyBP2 = Instance.new("BodyPosition", hrp)
    omniSkyBP2.Name     = "4DSkyBP"
    omniSkyBP2.Position  = Vector3.new(skyX, omniSkyWorldY, skyZ)
    omniSkyBP2.MaxForce  = Vector3.new(OCFG.SKY_HOLD_FORCE, OCFG.SKY_HOLD_FORCE, OCFG.SKY_HOLD_FORCE)
    omniSkyBP2.P         = 60000
    omniSkyBP2.D         = 2500

    omniSkyBV = Instance.new("BodyVelocity", hrp)
    omniSkyBV.Name       = "4DSkyBV"
    omniSkyBV.MaxForce   = Vector3.new(0, OCFG.SKY_HOLD_FORCE, 0)
    omniSkyBV.Velocity   = Vector3.new(0, 0, 0)

    workspace.CurrentCamera.CameraSubject = omniCamSubjectPart
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
    if hum then workspace.CurrentCamera.CameraSubject = hum end

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
--  ESP / LINES
-- ═══════════════════════════════════════════════════════════════════════════
local function omniUpdateESP(originPos)
    if not omniModeX then omniClearESP(); return end
    if not originPos then return end
    local myOrig, myOn = workspace.CurrentCamera:WorldToViewportPoint(originPos)
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= _lplr and p.Character then
            local hum = p.Character:FindFirstChild("Humanoid")
            local hrp = omniGetHRP(p.Character)
            if hrp and hum and hum.Health > 0 then
                local dist = (hrp.Position - originPos).Magnitude
                if dist <= OCFG.ESP_LINE_DIST then
                    if not omniESP[p] then
                        local gw = Drawing.new("Line"); gw.Transparency = 0.35
                        local ol = Drawing.new("Line"); ol.Transparency = OCFG.OUTLINE_ALPHA; ol.Color = Color3.fromRGB(0,0,0)
                        local ln = Drawing.new("Line"); ln.Transparency = 1
                        omniESP[p] = {line = ln, outline = ol, glow = gw}
                    end
                    local sp, on = workspace.CurrentCamera:WorldToViewportPoint(hrp.Position)
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
--  AERIAL & COMBATE
-- ═══════════════════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════════════════
--  PLANIFICADOR EN MATRIZ
--  El espacio alrededor del jugador se discretiza en una matriz N x N de celdas
--  centrada en el jugador. Cada celda recibe:
--     * un RIESGO   = suma de todas las amenazas (cae con 1/d^2, nunca llega a 0,
--                     asi que "mas lejos" SIEMPRE es mejor) + un nucleo de contacto
--     * un estado   = libre / obstaculo bajo (saltable) / pared / vacio
--  Dijkstra recorre la matriz acumulando EXPOSICION (riesgo x tiempo) y se elige la
--  celda meta con menor exposicion total = (riesgo al llegar) + (riesgo del trayecto).
--  Como el trayecto cuenta, cuando te arrinconan la ruta mas barata puede ser
--  colarse por el hueco entre dos amenazas: rompe el cerco en vez de quedarse quieto.
--  Lua puro (sin API de Roblox): el entorno (rayos) entra por `env`.
-- ═══════════════════════════════════════════════════════════════════════════

-- dangers[i] = { x, z, speed, weight, radius, lead }   (plano XZ)
--   speed = velocidad con la que la amenaza PUEDE moverse hacia cualquier celda
-- Modelo de alcanzabilidad: en el tiempo t la amenaza puede haber recorrido speed*t hacia
-- la celda evaluada (sin sobrepasarla). Asi un perseguidor nunca "atraviesa" tu posicion en
-- la prediccion, y quedarte quieto se vuelve mas caro cuanto mas tiempo pasa.
local function omniRiskAt(dangers, x, z, t)
    local d0, coreW = OCFG.GRID_RISK_D0, OCFG.GRID_CORE_WEIGHT
    local r = 0
    for i = 1, #dangers do
        local d  = dangers[i]
        local tt = (t < d.lead) and t or d.lead
        local dx = x - d.x
        local dz = z - d.z
        local dist = math.sqrt(dx * dx + dz * dz) - d.speed * tt
        if dist < 0 then dist = 0 end
        local far = d0 / (d0 + dist)
        local v = far * far
        if dist < d.radius then
            local k = 1 - dist / d.radius
            v = v + coreW * k * k
        end
        r = r + d.weight * v
    end
    return r
end

local OMNI_GRID_OFFS = {
    { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 },
    { 1, 1 }, { 1, -1 }, { -1, 1 }, { -1, -1 },
}

-- env.edge(x0, z0, x1, z1) -> 0 libre | 1 obstaculo bajo (saltable) | 2 pared
-- env.ground(x, z)         -> true si hay suelo (opcional)
-- hint = { x, z } meta del plan anterior (anti-temblor, opcional)
-- forceMove = true: hay una amenaza acercandose; nunca te quedes quieto (elige la mejor celda != actual)
-- Devuelve nil si no hay nada que hacer; si no, una tabla con la ruta elegida.
local function omniGridPlan(env, px, pz, dangers, hint, forceMove)
    local C     = OCFG
    local N     = C.GRID_N
    local cell  = C.GRID_CELL
    local half  = math.floor((N - 1) / 2)
    local speed = C.GRID_SPEED

    local function id(i, j) return (j + half) * N + (i + half) + 1 end

    local cost, plen, parent, jumpIn, closed, ci, cj = {}, {}, {}, {}, {}, {}, {}
    local orth, ground = {}, {}

    -- Arista ortogonal entre (i,j) y (i+di,j+dj); se cachea por arista
    local function orthKind(i, j, di, dj)
        local a, b = i, j
        if di < 0 or dj < 0 then a, b = i + di, j + dj end
        local key = id(a, b) * 2 + ((di ~= 0) and 0 or 1)
        local k = orth[key]
        if k == nil then
            k = env.edge(px + a * cell, pz + b * cell,
                         px + (a + math.abs(di)) * cell, pz + (b + math.abs(dj)) * cell)
            orth[key] = k
        end
        return k
    end

    -- Diagonal permitida solo si las 4 aristas que la rodean lo permiten (no corta esquinas)
    local function edgeKind(i, j, di, dj)
        if di == 0 or dj == 0 then return orthKind(i, j, di, dj) end
        return math.max(
            orthKind(i, j, di, 0), orthKind(i, j, 0, dj),
            orthKind(i + di, j, 0, dj), orthKind(i, j + dj, di, 0))
    end

    local function standable(i, j)
        local key = id(i, j)
        local g = ground[key]
        if g == nil then
            g = (env.ground == nil) or env.ground(px + i * cell, pz + j * cell)
            ground[key] = g
        end
        return g
    end

    -- ── Dijkstra sobre la matriz: costo = exposicion (riesgo x tiempo de transito) ──
    local startId = id(0, 0)
    cost[startId], plen[startId] = 0, 0
    ci[startId], cj[startId] = 0, 0
    local open = { startId }
    local timeCost = C.GRID_TIME_COST
    local jumpCost = C.GRID_JUMP_COST

    while #open > 0 do
        local bi, bc = 1, cost[open[1]]
        for k = 2, #open do
            local c = cost[open[k]]
            if c < bc then bi, bc = k, c end
        end
        local cur = open[bi]
        open[bi] = open[#open]; open[#open] = nil

        if not closed[cur] then
            closed[cur] = true
            if cost[cur] <= C.GRID_COST_CAP then
                local i, j = ci[cur], cj[cur]
                for _, o in ipairs(OMNI_GRID_OFFS) do
                    local di, dj = o[1], o[2]
                    local ni, nj = i + di, j + dj
                    if ni >= -half and ni <= half and nj >= -half and nj <= half then
                        local nid = id(ni, nj)
                        if not closed[nid] then
                            local kind = edgeKind(i, j, di, dj)
                            if kind < 2 and standable(ni, nj) then
                                local stepLen = cell * ((di ~= 0 and dj ~= 0) and 1.41421356 or 1)
                                local nl = plen[cur] + stepLen
                                local dt = stepLen / speed
                                local rk = omniRiskAt(dangers, px + ni * cell, pz + nj * cell, nl / speed)
                                local nc = cost[cur] + rk * dt + timeCost * dt
                                if kind == 1 then nc = nc + jumpCost end
                                if cost[nid] == nil or nc < cost[nid] then
                                    cost[nid], plen[nid], parent[nid] = nc, nl, cur
                                    jumpIn[nid] = (kind == 1)
                                    ci[nid], cj[nid] = ni, nj
                                    open[#open + 1] = nid
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    -- Apertura: que tan despejado esta el entorno 5x5 de una celda (fuera de la matriz = abierto)
    local function openness(i, j)
        local free, total = 0, 0
        for a = -2, 2 do
            for b = -2, 2 do
                local ai, bj = i + a, j + b
                total = total + 1
                if ai < -half or ai > half or bj < -half or bj > half then
                    free = free + 1
                elseif closed[id(ai, bj)] then
                    free = free + 1
                end
            end
        end
        return free / total
    end

    -- ── Eleccion de meta: menor exposicion total + territorio futuro ──
    local tRef, goalT = C.GRID_STAY_TIME, C.GRID_GOAL_TIME
    local hystR = C.GRID_HYST_RADIUS * cell
    local cand = {}
    for nid in pairs(closed) do
        local i, j = ci[nid], cj[nid]
        local x, z = px + i * cell, pz + j * cell
        local tg = math.max(plen[nid] / speed, goalT)
        local rg = omniRiskAt(dangers, x, z, tg)
        local s = -(cost[nid] + tRef * rg) + C.GRID_OPEN_WEIGHT * openness(i, j)
        if nid ~= startId and hint then
            local dd = math.sqrt((x - hint.x) ^ 2 + (z - hint.z) ^ 2)
            if dd < hystR then s = s + C.GRID_HYST_WEIGHT * (1 - dd / hystR) end
        end
        cand[#cand + 1] = { id = nid, s = s, risk = rg, x = x, z = z }
    end
    table.sort(cand, function(a, b) return a.s > b.s end)

    -- Territorio: celdas libres a las que llegas ANTES que cualquier amenaza si te paras
    -- en la meta. Una esquina o un callejon tienen poco; un hueco hacia espacio abierto, mucho.
    local free = {}
    for nid in pairs(closed) do free[#free + 1] = { px + ci[nid] * cell, pz + cj[nid] * cell } end
    local function territory(c)
        local t0, n = plen[c.id] / speed, 0
        for _, f in ipairs(free) do
            local tp = t0 + math.sqrt((f[1] - c.x) ^ 2 + (f[2] - c.z) ^ 2) / speed
            local tt = math.huge
            for k = 1, #dangers do
                local d = dangers[k]
                local td = math.sqrt((f[1] - d.x) ^ 2 + (f[2] - d.z) ^ 2) / math.max(d.speed, 1e-3)
                if td < tt then tt = td end
            end
            if tp < tt then n = n + 1 end
        end
        return n / (N * N)
    end

    local bestId, bestScore, bestRisk = startId, -math.huge, 0
    local stayScore, stayRisk = 0, 0
    local checked, startDone = 0, false
    for _, c in ipairs(cand) do
        local isStart = (c.id == startId)
        if checked < C.GRID_TERR_TOPK or (isStart and not startDone) then
            local s = c.s + C.GRID_TERR_WEIGHT * territory(c)
            c.s = s
            checked = checked + 1
            if isStart then startDone = true; stayScore, stayRisk = s, c.risk end
            if (not isStart or not forceMove) and s > bestScore then bestId, bestScore, bestRisk = c.id, s, c.risk end
        end
    end
    if not startDone then -- la celda actual no entro al top: evaluarla igual (referencia de "quedarse")
        for _, c in ipairs(cand) do
            if c.id == startId then
                stayScore = c.s + C.GRID_TERR_WEIGHT * territory(c); stayRisk = c.risk
                break
            end
        end
    end

    -- Quedarse tiene que ganar por un margen para no quedarse quieto por ruido
    if bestId == startId or (not forceMove and bestScore < stayScore + C.GRID_MOVE_MARGIN) then
        return { stay = true, stayRisk = stayRisk, cornered = false }
    end

    -- ── Reconstruir la ruta y promediar los primeros waypoints (movimiento suave) ──
    local wps, jump = {}, false
    local n = bestId
    while n and n ~= startId do
        table.insert(wps, 1, n)
        n = parent[n]
    end
    local sx, sz, used = 0, 0, 0
    for k = 1, math.min(C.GRID_LOOKAHEAD, #wps) do
        local w = wps[k]
        local ux, uz = ci[w] * cell, cj[w] * cell
        local m = math.sqrt(ux * ux + uz * uz)
        if m > 0.01 then sx, sz, used = sx + ux / m, sz + uz / m, used + 1 end
        if k <= 2 and jumpIn[w] then jump = true end
    end
    if used == 0 then return { stay = true, stayRisk = stayRisk, cornered = false } end
    local m = math.sqrt(sx * sx + sz * sz)
    if m < 0.01 then return { stay = true, stayRisk = stayRisk, cornered = false } end

    local cornered = stayRisk > C.GRID_CORNER_RISK
        and (cost[bestId] > C.GRID_BREAKOUT_COST or bestRisk > C.GRID_CORNER_RATIO * stayRisk)

    return {
        stay = false, dx = sx / m, dz = sz / m, jump = jump, cornered = cornered,
        goalX = px + ci[bestId] * cell, goalZ = pz + cj[bestId] * cell,
        stayRisk = stayRisk, goalRisk = bestRisk, transit = cost[bestId],
    }
end

-- ═══════════════════════════════════════════════════════════════════════════
--  INTEGRACION CON ROBLOX: entorno de rayos, amenazas -> peligros, cache
-- ═══════════════════════════════════════════════════════════════════════════
local omniPushVel      = Vector3.new() -- velocidad de empuje suavizada (la usa el bucle principal)
local omniPushLastTime = 0
local omniGridHint   = nil   -- { x, z, t } meta del plan anterior
local omniGridCache  = {}    -- [tag] = { t, dir, info }  (evita planificar en cada frame)
local omniGridWarned = false

-- Cada celda se valida con rayos: pecho (pared) y espinilla (obstaculo bajo saltable).
-- Los demas jugadores se excluyen: no son paredes, son amenazas (ya estan en el riesgo).
local function omniBuildGridEnv(myHRP)
    local y = myHRP.Position.Y
    local excl = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character then excl[#excl + 1] = p.Character end
    end
    if omniCloneModel then excl[#excl + 1] = omniCloneModel end

    local rp = RaycastParams.new()
    rp.FilterType = Enum.RaycastFilterType.Exclude
    rp.FilterDescendantsInstances = excl
    rp.RespectCanCollide = true

    local minNormal = OCFG.GROUND_NORMAL_MIN
    local env = {}

    function env.edge(x0, z0, x1, z1)
        local dir = Vector3.new(x1 - x0, 0, z1 - z0)
        local hit = workspace:Raycast(Vector3.new(x0, y + OCFG.GRID_CHEST_OFFSET, z0), dir, rp)
        if hit and hit.Normal.Y < minNormal then return 2 end   -- pared
        local low = workspace:Raycast(Vector3.new(x0, y - OCFG.GRID_SHIN_OFFSET, z0), dir, rp)
        if low and low.Normal.Y < minNormal then return 1 end   -- obstaculo bajo: se puede saltar
        return 0
    end

    if OCFG.GRID_VOID_CHECK then
        local down = Vector3.new(0, -OCFG.GRID_VOID_DEPTH, 0)
        function env.ground(x, z)
            return workspace:Raycast(Vector3.new(x, y, z), down, rp) ~= nil
        end
    end

    return env
end

-- Amenaza movil: "speed" es hasta donde PUEDE llegar por segundo (nunca menos que el minimo)
local function omniMakeDanger(tHRP, weight, radius)
    local v  = tHRP.AssemblyLinearVelocity
    local sp = math.sqrt(v.X * v.X + v.Z * v.Z)
    sp = math.clamp(sp, OCFG.GRID_THREAT_MIN_SPEED, OCFG.GRID_THREAT_MAX_SPEED)
    return {
        x = tHRP.Position.X, z = tHRP.Position.Z, speed = sp,
        weight = weight, radius = radius or OCFG.GRID_CORE_RADIUS, lead = OCFG.GRID_LEAD,
    }
end

-- Zona fija (p. ej. punto de impacto de un aereo)
local function omniStaticDanger(pos, weight, radius)
    return { x = pos.X, z = pos.Z, speed = 0, weight = weight, radius = radius, lead = OCFG.GRID_LEAD }
end

-- Devuelve (direccion plana unitaria | nil, info). nil = quedarse es lo mejor.
-- info = { cornered, jump, goalX, goalZ, stayRisk, goalRisk, transit }
local function omniPickSafeDir(myHRP, dangers, forceMove, tag)
    tag = tag or "ground"
    local now = os.clock()
    local c = omniGridCache[tag]
    if c and now - c.t < 1 / OCFG.GRID_PLAN_HZ then return c.dir, c.info end

    local pos  = myHRP.Position
    local hint = (omniGridHint and now - omniGridHint.t < 0.6) and omniGridHint or nil
    local ok, plan = pcall(function()
        return omniGridPlan(omniBuildGridEnv(myHRP), pos.X, pos.Z, dangers, hint, forceMove)
    end)
    if not ok then
        if not omniGridWarned then
            omniGridWarned = true
            warn("[Omniblock] planificador: " .. tostring(plan))
        end
        return nil, nil
    end

    local dir = nil
    if plan and not plan.stay then
        dir = Vector3.new(plan.dx, 0, plan.dz)
        omniGridHint = { x = plan.goalX, z = plan.goalZ, t = now }
    else
        omniGridHint = nil
    end
    omniGridCache[tag] = { t = now, dir = dir, info = plan }
    return dir, plan
end

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
                    local cl = workspace.CurrentCamera.CFrame.LookVector
                    escDir = Vector2.new(cl.Z, -cl.X)
                end
                bestEscape = {
                    dir2D    = escDir.Unit,
                    danger   = danger,
                    isSlamming = isFalling and isAbove,
                    dist2D   = impactDist,
                    impact   = Vector3.new(impactXZ.X, myHRP.Position.Y, impactXZ.Y),
                }
            end
        end
    end

    if bestEscape then
        local d   = bestEscape.danger
        local dir = bestEscape.dir2D
        do
            -- Alejarse del punto de impacto SIN ir hacia las demas amenazas
            local dangers = {}
            for _, t in ipairs(threats) do
                table.insert(dangers, omniMakeDanger(t.HRP, 0.8))
            end
            table.insert(dangers, omniStaticDanger(
                bestEscape.impact, 2.2, OCFG.AERIAL_AOE_RADIUS * 2.2))
            local safe = omniPickSafeDir(myHRP, dangers, true, "aerial")
            if safe then dir = Vector2.new(safe.X, safe.Z) end
        end
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

local function omniApproachScore(myHRP, tHRP, tHum)
    local diff = myHRP.Position - tHRP.Position
    local dist = diff.Magnitude
    if dist < 0.1 then return 1, Vector3.new(0, 0, 1) end

    local dirToMe = diff.Unit
    local vel     = tHRP.AssemblyLinearVelocity
    local speed3D = vel.Magnitude

    local velToward = 0
    if speed3D > 0.1 then
        velToward = math.clamp(vel.Unit:Dot(dirToMe), 0, 1)
    end

    local look     = tHRP.CFrame.LookVector
    local lookToward = math.clamp(look:Dot(dirToMe), 0, 1)

    local prox = math.clamp(1 - (dist / OCFG.MAX_ESP_DIST), 0, 1)
    local speedFactor = math.clamp(speed3D / 60, 0, 1)

    local fallingOnMe = 0
    local heightAbove = tHRP.Position.Y - myHRP.Position.Y
    if heightAbove > OCFG.AERIAL_HEIGHT_THRESHOLD
        and vel.Y < -OCFG.JUMP_VEL_THRESHOLD then
        local pred    = tHRP.Position + vel * (OCFG.SLAM_PREDICT_FRAMES / 60)
        local predXZ  = Vector2.new(pred.X, pred.Z)
        local myXZ    = Vector2.new(myHRP.Position.X, myHRP.Position.Z)
        local impactD = (predXZ - myXZ).Magnitude
        fallingOnMe   = math.clamp(1 - (impactD / OCFG.AERIAL_AOE_RADIUS), 0, 1)
    end

    local hp = tHum and tHum.Health / math.max(tHum.MaxHealth, 1) or 1

    local score =
        prox        * 0.30 +
        velToward   * 0.30 +
        lookToward  * 0.15 +
        speedFactor * 0.10 +
        fallingOnMe * 0.10 +
        hp          * 0.05

    return math.clamp(score, 0, 1), dirToMe
end

local function omniStrategicVec(myHRP, threats)
    local scored = {}
    for _, t in ipairs(threats) do
        local s, dirToMe = omniApproachScore(myHRP, t.HRP, t.Hum)
        table.insert(scored, { threat = t, score = s, dir = dirToMe })
    end
    if #scored == 0 then
        omniGridHint = nil
        omniPublicState.cornered = false
        return Vector3.new()
    end

    table.sort(scored, function(a, b) return a.score > b.score end)
    local primary = scored[1]

    -- TODAS las amenazas entran a la matriz (mas peso las que se acercan). La meta elegida es
    -- la de menor exposicion total, no solo "lejos de la principal".
    local dangers = {}
    for _, s in ipairs(scored) do
        table.insert(dangers, omniMakeDanger(s.threat.HRP, 0.35 + s.score * 1.5))
    end

    if primary.score < 0.02 then
        local strength = 0
        for _, s in ipairs(scored) do
            strength = math.max(strength, math.clamp(1 - (s.threat.Distance / OCFG.SAFE_DIST), 0, 1))
        end
        if strength <= 0 then
            omniPublicState.cornered = false
            return Vector3.new()
        end
        local dir, info = omniPickSafeDir(myHRP, dangers, true)
        omniPublicState.cornered = info ~= nil and info.cornered == true
        return dir and dir * strength or Vector3.new(), info
    end

    local dir, info = omniPickSafeDir(myHRP, dangers, true)
    omniPublicState.cornered = info ~= nil and info.cornered == true
    if not dir then return Vector3.new(), info end

    local mag = 1.4 + primary.score
    -- Arrinconado: rompe el cerco a toda velocidad
    if info and info.cornered then
        mag = math.max(mag, OCFG.MAX_VELOCITY / OCFG.DASH_FORCE_BASE)
    end
    return dir * mag, info
end

-- ═══════════════════════════════════════════════════════════════════════════
--  AURA DEL EMPUJE: lente de agujero negro pegada a la silueta (estado normal con empuje)
--  Cada parte del cuerpo recibe una cáscara de vidrio reflectivo por capa, con su misma
--  forma, apiladas hacia afuera (como los anillos de la referencia). Cada capa lleva un
--  contorno oscuro fino que dibuja las líneas negras entre anillos. Local: solo tú lo ves.
-- ═══════════════════════════════════════════════════════════════════════════
local omniAura = nil          -- { char, root, layers = {{model, rim}}, parts = {{src, shells, phase}}, alpha }
local omniAuraConn = nil
local omniAuraWarned = false

local function omniAuraDestroy()
    if not omniAura then return end
    pcall(function() omniAura.root:Destroy() end)
    omniAura = nil
end

-- Cáscara con la forma de la pieza (clona la malla; el tamaño se ajusta en cada frame)
local function omniAuraShell(src, parent, material, color, reflect)
    local shell
    if src:IsA("MeshPart") or src:FindFirstChildOfClass("SpecialMesh") then
        local ok, c = pcall(function() return src:Clone() end)
        if ok and c then
            for _, ch in ipairs(c:GetChildren()) do
                if not ch:IsA("SpecialMesh") then ch:Destroy() end
            end
            shell = c
        end
    end
    if not shell then
        shell = Instance.new("Part")
        if src:IsA("Part") then shell.Shape = src.Shape end
    end
    shell.Name = "AuraShell"
    if shell:IsA("MeshPart") then shell.TextureID = "" end
    local sm = shell:FindFirstChildOfClass("SpecialMesh")
    if sm then sm.TextureId = "" end
    shell.Anchored = true
    shell.CanCollide = false; shell.CanQuery = false; shell.CanTouch = false
    shell.CastShadow = false; shell.Massless = true; shell.Locked = true
    shell.Material = material
    shell.Color = color
    shell.Reflectance = reflect
    shell.Transparency = 1
    shell.Size = src.Size
    shell.CFrame = src.CFrame
    shell.Parent = parent
    return shell
end

local function omniAuraBuild(char)
    local cam = workspace.CurrentCamera
    if not cam then return nil end

    local root = Instance.new("Folder")
    root.Name = "OmniAura"

    -- Un Model por capa: su Highlight dibuja el contorno de TODA la silueta de esa capa
    local layers = {}
    for li = 1, #OCFG.AURA_LAYERS do
        local m = Instance.new("Model")
        m.Name = "Layer" .. li
        m.Parent = root
        layers[li] = { model = m }
    end

    local parts = {}
    for _, src in ipairs(char:GetChildren()) do
        if src:IsA("BasePart") and src.Name ~= "HumanoidRootPart" and src.Transparency < 0.95 then
            local shells = {}
            for li, cfg in ipairs(OCFG.AURA_LAYERS) do
                shells[li] = omniAuraShell(src, layers[li].model,
                    cfg.material or Enum.Material.Glass, cfg.color, cfg.reflect or 0)
            end
            table.insert(parts, { src = src, shells = shells, phase = #parts * 0.9 })
        end
    end
    if #parts == 0 then root:Destroy(); return nil end
    root.Parent = cam

    for li, cfg in ipairs(OCFG.AURA_LAYERS) do
        if cfg.line then
            local rim = Instance.new("Highlight")
            rim.Adornee = layers[li].model
            rim.FillTransparency = 1
            rim.OutlineColor = cfg.line
            rim.OutlineTransparency = 1
            rim.DepthMode = Enum.HighlightDepthMode.Occluded
            rim.Parent = layers[li].model
            layers[li].rim = rim
        end
    end

    return { char = char, root = root, layers = layers, parts = parts, alpha = 0 }
end

local function omniAuraStep(dt)
    local char = _lplr and _lplr.Character
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    local hrp  = omniGetHRP(char)

    -- En 4D (el cuerpo real viaja al cielo) o sin personaje vivo: fuera al instante
    if omniInSky or not char or not hum or not hrp or hum.Health <= 0 then
        omniAuraDestroy()
        return
    end

    local want = enabled and omniModeX and omniPushEnabled

    if omniAura and omniAura.char ~= char then omniAuraDestroy() end
    if not omniAura then
        if not want then return end
        omniAura = omniAuraBuild(char)
        if not omniAura then return end
    end

    local A = omniAura
    A.alpha = A.alpha + ((want and 1 or 0) - A.alpha) * math.min(1, dt * 12)
    if not want and A.alpha < 0.03 then omniAuraDestroy(); return end

    local now     = os.clock()
    local primary = omniPublicState.primary
    local alert   = want and primary ~= nil and primary.distance < OCFG.SAFE_DIST * 1.5
    local speed   = alert and 1.7 or 1
    local gain    = math.min(OCFG.AURA_STRENGTH * (alert and OCFG.AURA_ALERT_MULT or 1), 1.6) * A.alpha
    local cfgs    = OCFG.AURA_LAYERS

    for i = #A.parts, 1, -1 do
        local e = A.parts[i]
        if not e.src.Parent then
            for _, sh in ipairs(e.shells) do pcall(function() sh:Destroy() end) end
            table.remove(A.parts, i)
        else
            local cf, size = e.src.CFrame, e.src.Size
            for li, cfg in ipairs(cfgs) do
                -- Onda que viaja hacia afuera: los anillos "fluyen" en vez de verse estáticos
                local ph  = now * 2.2 * speed - li * 0.9 + e.phase * 0.35
                local pad = cfg.pad * (1 + 0.14 * math.sin(ph))
                local sh  = e.shells[li]
                sh.CFrame = cf
                sh.Size = size + Vector3.new(pad, pad, pad) * 2
                sh.Transparency = 1 - math.clamp((1 - cfg.transp) * gain, 0, 0.85)
            end
        end
    end

    for li, cfg in ipairs(cfgs) do
        local rim = A.layers[li].rim
        if rim then
            rim.OutlineTransparency = 1 - math.clamp((1 - (cfg.lineTransp or 0.3)) * gain, 0, 1)
        end
    end
end

local function omniAuraStart()
    if omniAuraConn then return end
    -- RenderStepped: se actualiza justo antes de dibujar, así sigue al cuerpo sin desfase
    omniAuraConn = trackConnection(RunService.RenderStepped:Connect(function(dt)
        local ok, err = pcall(omniAuraStep, dt)
        if not ok then
            omniAuraDestroy()
            if not omniAuraWarned then
                omniAuraWarned = true
                warn("[Omniblock] aura: " .. tostring(err))
            end
        end
    end))
end

local function omniAuraStop()
    if omniAuraConn then disconnectTracked(omniAuraConn); omniAuraConn = nil end
    omniAuraDestroy()
end

-- ═══════════════════════════════════════════════════════════════════════════
--  START / STOP INTERNOS
-- ═══════════════════════════════════════════════════════════════════════════
local function omniStop()
    omniAuraStop()
    if omniInSky then omniDeactivate4D() end
    omniModeX = false; omniModeY = false; omniRmbHeld = false
    omniClearESP()
    if omniHeartbeat  then disconnectTracked(omniHeartbeat);  omniHeartbeat  = nil end
    if omniInputBegin then disconnectTracked(omniInputBegin); omniInputBegin = nil end
    if omniInputEnd   then disconnectTracked(omniInputEnd);   omniInputEnd   = nil end
    if omniCharConn   then disconnectTracked(omniCharConn);   omniCharConn   = nil end
end

local function omniStart()
    omniAuraStart()
    omniHeartbeat = trackConnection(RunService.Heartbeat:Connect(function(dt)
        local char  = _lplr.Character
        local myHRP = omniGetHRP(char)
        local hum   = char and char:FindFirstChildOfClass("Humanoid")

        if omniInSky then
            if not myHRP or not hum then return end
            
            -- [CORRECCIÓN DEL BUG DE CÁMARA]: Asegurar que la cámara se mantenga en el clon (omniCamSubjectPart)
            if omniCamSubjectPart and workspace.CurrentCamera.CameraSubject ~= omniCamSubjectPart then
                workspace.CurrentCamera.CameraSubject = omniCamSubjectPart
            end

            omniLastCamCF = workspace.CurrentCamera.CFrame
            local curHP = hum.Health
            if curHP < omniLastHealth - 0.5 then
                omniOrbiting = true; omniOrbitTimer = OCFG.ORBIT_DURATION; omniOrbitAngle = 0
            end
            omniLastHealth = curHP
            if omniOrbiting then
                omniOrbitTimer = omniOrbitTimer - dt
                if omniOrbitTimer <= 0 then omniOrbiting = false end
            end

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
                omniApplyCloneColor(omniOrbiting)

                local prevGroundPos = omniGroundPos
                local camLook  = workspace.CurrentCamera.CFrame.LookVector
                local camRight = workspace.CurrentCamera.CFrame.RightVector
                local fwd   = Vector3.new(camLook.X,  0, camLook.Z)
                local right = Vector3.new(camRight.X, 0, camRight.Z)
                if fwd.Magnitude   > 0 then fwd   = fwd.Unit   end
                if right.Magnitude > 0 then right = right.Unit end

                local move = Vector3.new()
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + fwd   end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - fwd   end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + right  end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - right  end

                local proposed = prevGroundPos
                if move.Magnitude > 0 then
                    proposed = prevGroundPos + move.Unit * OCFG.DECOY_WALK_SPEED * dt
                end
                
                omniGroundPos = omniFollowGround(prevGroundPos,
                    Vector3.new(proposed.X, prevGroundPos.Y, proposed.Z), dt, char)

                if UserInputService:IsKeyDown(Enum.KeyCode.Space) and omniCloneJumpVel == 0 and omniCloneJumpOffset == 0 then
                    omniCloneJumpVel = OCFG.DECOY_JUMP_VELOCITY
                    omniCloneWasAirborne = true
                end
                if omniCloneJumpVel ~= 0 then
                    local nextJumpOffset = omniCloneJumpOffset
                        + omniCloneJumpVel * dt
                        - 0.5 * omniCloneGravity * dt * dt
                    omniCloneJumpVel = omniCloneJumpVel - omniCloneGravity * dt
                    if nextJumpOffset <= 0 then
                        omniCloneJumpOffset = 0
                        omniCloneJumpVel = 0
                        if omniCloneWasAirborne then
                            omniCloneGravity = omniCloneNormalGravity
                            omniCloneWasAirborne = false
                        end
                    else
                        omniCloneJumpOffset = nextJumpOffset
                    end
                end

                if omniCloneModel and omniCloneModel.PrimaryPart then
                    omniSyncCloneAnimations()
                    omniSyncClonePose()
                    omniCloneFootOffset = omniGetCloneFootOffset(omniCloneModel, omniCloneModel.PrimaryPart)
                    local flat = Vector3.new(camLook.X, 0, camLook.Z)
                    local yaw  = flat.Magnitude > 0.01
                        and math.atan2(-flat.X, -flat.Z)
                        or  select(2, omniCloneModel.PrimaryPart.CFrame:ToEulerAnglesYXZ())
                    local groundSurfaceY = omniGroundPos.Y - omniFootOffset
                    local clonePos = Vector3.new(
                        omniGroundPos.X,
                        groundSurfaceY + omniCloneFootOffset + omniCloneJumpOffset + OCFG.CLONE_GROUND_EPSILON,
                        omniGroundPos.Z)
                    local newCF = CFrame.new(clonePos) * CFrame.Angles(0, yaw, 0)
                    omniCloneModel:PivotTo(newCF)
                end

                if omniCamSubjectPart then
                    omniCamSubjectPart.CFrame = CFrame.new(
                        omniGroundPos.X,
                        omniGroundPos.Y + omniCloneJumpOffset + OCFG.DECOY_HEAD_Y,
                        omniGroundPos.Z)
                end

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

            if omniInSky and myHRP then
                if math.abs(myHRP.Position.Y - omniSkyWorldY) > 0.5 then
                    myHRP.CFrame = CFrame.new(myHRP.Position.X, omniSkyWorldY, myHRP.Position.Z)
                                 * (myHRP.CFrame - myHRP.CFrame.Position)
                end
            end

            omniUpdatePublicState(omniBuildThreats(myHRP))
            omniUpdateExposedData()
            omniUpdateESP(omniGroundPos)
            return
        end

        omniUpdateESP(myHRP and myHRP.Position)
        if myHRP then omniUpdatePublicState(omniBuildThreats(myHRP)) else omniUpdatePublicState({}) end
        omniUpdateExposedData()

        if not omniModeX or not myHRP or (hum and hum.Health <= 0) then return end

        local threats = omniBuildThreats(myHRP)
        local mainThreat = threats[1] and threats[1].HRP or nil

        local aerialHandled = omniPushEnabled and omniHandleAerial(myHRP, hum, threats)

        if mainThreat then
            local lookPoint = Vector3.new(mainThreat.Position.X, myHRP.Position.Y, mainThreat.Position.Z)
            myHRP.CFrame = myHRP.CFrame:Lerp(CFrame.lookAt(myHRP.Position, lookPoint), OCFG.ROTATION_SMOOTH)
            if omniPushEnabled and not aerialHandled then
                local forceVec, planInfo = omniStrategicVec(myHRP, threats)
                if planInfo and planInfo.jump and hum and hum.FloorMaterial ~= Enum.Material.Air then
                    hum.Jump = true -- la ruta pasa por un obstaculo bajo: salta
                end
                if forceVec.Magnitude > 0 then
                    local spd    = math.clamp(forceVec.Magnitude * OCFG.DASH_FORCE_BASE, 0, OCFG.MAX_VELOCITY)
                    local target = forceVec.Unit * spd
                    local cur    = myHRP.AssemblyLinearVelocity
                    local nowT   = os.clock()
                    if nowT - omniPushLastTime > 0.25 then
                        -- Empuje nuevo: arrancar ya con buena parte de la velocidad objetivo
                        omniPushVel = Vector3.new(cur.X, 0, cur.Z) * 0.5 + target * 0.5
                    end
                    omniPushLastTime = nowT
                    -- La velocidad gira poco a poco hacia la direccion elegida: trazas arcos
                    -- que rodean la amenaza/items en vez de quiebres bruscos
                    omniPushVel = omniPushVel:Lerp(target, 1 - math.exp(-OCFG.PUSH_TURN_RATE * dt))
                    myHRP.AssemblyLinearVelocity = Vector3.new(omniPushVel.X, cur.Y, omniPushVel.Z)
                end
            end
            workspace.CurrentCamera.CFrame = workspace.CurrentCamera.CFrame:Lerp(
                CFrame.lookAt(workspace.CurrentCamera.CFrame.Position, mainThreat.Position), 0.1)
        end
    end))

    omniInputBegin = trackConnection(UserInputService.InputBegan:Connect(function(input, gp)
        if not enabled then return end

        -- R: activa/desactiva el empuje del estado base. Solo con F mantenida o durante 4D.
        -- Va ANTES del filtro gp: si el juego usa R, Roblox lo marca como "procesado"
        -- y el toggle nunca llegaba. Se ignora solo si el jugador esta escribiendo en un TextBox.
        if input.KeyCode == (_keys.OmniPush or Enum.KeyCode.R)
            and (omniModeX or omniInSky)
            and not UserInputService:GetFocusedTextBox() then
            omniPushEnabled = not omniPushEnabled
            omniPlaySound(OCFG.SND_PUSH_TOGGLE)
            return
        end

        if gp then return end

        local muiState = omniGetMUIAPIState()
        local muiActiveOrWarning = muiState.success and (muiState.isAlarmActive or muiState.isSkyCloneActive or #muiState.threats > 0 or muiState.isTeleportingSoon)

        if input.UserInputType == Enum.UserInputType.MouseButton1 and omniInSky then
            if muiActiveOrWarning then return end 
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
            if omniRmbHeld and not omniInSky then
                if muiActiveOrWarning then return end 
                omniModeY = true; omniActivate4D() 
            end
        end

        if input.KeyCode == _keys.Omni4D then
            if not omniInSky then
                if muiActiveOrWarning then return end 
                omniActivate4D() 
            end
        end

        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            omniRmbHeld = true
            if omniModeX and not omniInSky then
                if muiActiveOrWarning then return end 
                omniModeY = true; omniActivate4D() 
            end
        end
    end))

    omniInputEnd = trackConnection(UserInputService.InputEnded:Connect(function(input)
        local muiState = omniGetMUIAPIState()
        local muiActiveOrWarning = muiState.success and (muiState.isAlarmActive or muiState.isSkyCloneActive)

        if input.KeyCode == _keys.OmniBlock then
            omniModeX = false; omniClearESP()
            if omniInSky and not omni4DPinned then
                if muiActiveOrWarning then return end 
                omniModeY = false; omniDeactivate4D() 
            end
        end
        if input.KeyCode == _keys.Omni4D then
            if omniInSky and not omni4DPinned then
                if muiActiveOrWarning then return end 
                omniModeY = false; omniDeactivate4D() 
            end
        end
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            omniRmbHeld = false
            if omniInSky and not omni4DPinned then
                if muiActiveOrWarning then return end 
                omniModeY = false; omniDeactivate4D() 
            end
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
        if hum then workspace.CurrentCamera.CameraSubject = hum end
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
    _keys.OmniPush = _keys.OmniPush or _pendingPushKey or Enum.KeyCode.R
    omniPushEnabled = true
    if workspace.Gravity > 0 then
        omniCloneNormalGravity = workspace.Gravity
    end
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

function M.SetPushKey(kc)
    _pendingPushKey = kc
    if _keys then _keys.OmniPush = kc end
end

function M.IsPushEnabled()
    return omniPushEnabled
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

-- Si el modulo se carga otra vez (p. ej. al reaplicar ajustes desde el menu), la instancia
-- anterior seguia viva con su propio InputBegan y la tecla R vieja: una instancia apagaba
-- con la tecla nueva y la otra encendia con R. Se desmonta la anterior antes de registrarse.
local _prevApi = rawget(getgenv(), "AFO_OMNIBLOCK_API")
if type(_prevApi) == "table" and _prevApi ~= M and type(_prevApi.Stop) == "function" then
    pcall(_prevApi.Stop)
end
getgenv().AFO_OMNIBLOCK_API = M

return M
