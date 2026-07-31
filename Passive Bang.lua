local M = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local _lplr = nil
local _camera = workspace.CurrentCamera
local _conns = {}

local _bangKey = Enum.KeyCode.Quote
local _lockModuleRef = nil

local _holding = false
local _targetHRP = nil
local _targetPlayer = nil
local _leftDown = false
local _rightDown = false
local _rescore = 0

local hrp = nil

-- Configuración
local PB = {
    MAX_3D_DIST = 150,
    MAX_ENGAGED_DIST = 250,
    W_PROXIMITY = 7.0,
    W_MOUSE = 3.0,
    MAX_SCREEN_DIST_MOUSE = 350,
    W_CONTINUITY = 2.0,
    ORBIT_RADIUS = 5.5,
    ORBIT_SPEED = 12,
    PING_PREDICT_BASE = 0.15,
    PING_PREDICT_EXTRA = 0.10,
    LEAD_FACTOR = 0.55,
    LEAD_MAX = 8,
    VEL_THRESHOLD = 8,
    RESCORE_INTERVAL = 12,
}

-- ─────────────────────────────────────────
-- 🔁 MANEJO DE RESPAWN (FIX PRINCIPAL)
-- ─────────────────────────────────────────
local function updateCharacter(char)
    if not char then return end

    local newHRP = char:WaitForChild("HumanoidRootPart", 5)
    if newHRP then
        hrp = newHRP
    end

    -- Reset estado
    _holding = false
    _targetHRP = nil
    _targetPlayer = nil
    _rescore = PB.RESCORE_INTERVAL
end

-- ─────────────────────────────────────────
-- SCAN
-- ─────────────────────────────────────────
local function pbScoreCandidate(candidatePlayer, myHRP, mouseX, mouseY)
    if candidatePlayer == _lplr then return nil end
    local char = candidatePlayer.Character
    if not char then return nil end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChild("Humanoid")
    if not hrp or not hum or hum.Health <= 0 then return nil end

    local dist3D = (hrp.Position - myHRP.Position).Magnitude
    local isCurrent = (hrp == _targetHRP)
    local maxDist = isCurrent and PB.MAX_ENGAGED_DIST or PB.MAX_3D_DIST

    if dist3D > maxDist then return nil end

    local proximityScore = PB.W_PROXIMITY * (1 - math.clamp(dist3D / PB.MAX_3D_DIST, 0, 1))
    local mouseScore = 0

    local screenPos, onScreen = _camera:WorldToViewportPoint(hrp.Position)
    if onScreen then
        local screenDist = Vector2.new(mouseX - screenPos.X, mouseY - screenPos.Y).Magnitude
        if screenDist <= PB.MAX_SCREEN_DIST_MOUSE then
            mouseScore = PB.W_MOUSE * (1 - screenDist / PB.MAX_SCREEN_DIST_MOUSE)
        end
    end

    local continuityScore = isCurrent and PB.W_CONTINUITY or 0
    return proximityScore + mouseScore + continuityScore, hrp, candidatePlayer
end

local function pbSelectBestTarget(myHRP)
    local mouse = _lplr:GetMouse()
    local mx, my = mouse.X, mouse.Y

    local bestScore, bestHRP, bestPlayer = -math.huge, nil, nil

    for _, p in pairs(Players:GetPlayers()) do
        local score, hrp, pl = pbScoreCandidate(p, myHRP, mx, my)
        if score and score > bestScore then
            bestScore = score
            bestHRP = hrp
            bestPlayer = pl
        end
    end

    return bestHRP, bestPlayer
end

-- ─────────────────────────────────────────
-- START
-- ─────────────────────────────────────────
function M.Start(lplr)
    _lplr = lplr or Players.LocalPlayer

    if #_conns > 0 then M.Stop() end

    -- 🔁 Detectar respawn
    local cChar = _lplr.CharacterAdded:Connect(updateCharacter)
    table.insert(_conns, cChar)

    -- Inicial
    updateCharacter(_lplr.Character)

    -- INPUT
    local c1 = UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end

        if input.UserInputType == Enum.UserInputType.MouseButton1 then _leftDown = true end
        if input.UserInputType == Enum.UserInputType.MouseButton2 then _rightDown = true end

        if input.KeyCode == _bangKey then
            _holding = true
            _rescore = PB.RESCORE_INTERVAL
        end
    end)

    local c2 = UserInputService.InputEnded:Connect(function(input)
        if input.KeyCode == _bangKey then
            _holding = false
            _targetHRP = nil
            _targetPlayer = nil
        end

        if input.UserInputType == Enum.UserInputType.MouseButton1 then _leftDown = false end
        if input.UserInputType == Enum.UserInputType.MouseButton2 then _rightDown = false end
    end)

    -- LOOP PRINCIPAL
    local c3 = RunService.RenderStepped:Connect(function()
        if not _holding then return end

        -- 🔥 HRP dinámico SIEMPRE actualizado
        if not _lplr.Character then return end
        local currentHRP = _lplr.Character:FindFirstChild("HumanoidRootPart")
        if not currentHRP then return end

        hrp = currentHRP

        local hasLock = false

        -- PRIORIDAD LOCK
        if _lockModuleRef and _lockModuleRef.IsLockActive and _lockModuleRef.IsLockActive() then
            hasLock = true

            local lockTarget = _lockModuleRef.GetTarget and _lockModuleRef.GetTarget() or nil

            if lockTarget and lockTarget.Character then
                local lHRP = lockTarget.Character:FindFirstChild("HumanoidRootPart")
                local lHum = lockTarget.Character:FindFirstChild("Humanoid")

                if lHRP and lHum and lHum.Health > 0 then
                    _targetHRP = lHRP
                    _targetPlayer = lockTarget
                    _rescore = PB.RESCORE_INTERVAL
                else
                    hasLock = false
                end
            else
                hasLock = false
            end
        end

        -- SCAN PASIVO
        if not hasLock then
            _rescore += 1

            if _rescore >= PB.RESCORE_INTERVAL or not _targetHRP then
                _rescore = 0
                local newHRP, newPlayer = pbSelectBestTarget(hrp)

                if newHRP then
                    _targetHRP = newHRP
                    _targetPlayer = newPlayer
                end
            end
        end

        -- VALIDACIÓN
        if _targetHRP then
            local tHum = _targetHRP.Parent and _targetHRP.Parent:FindFirstChild("Humanoid")
            if not _targetHRP.Parent or not tHum or tHum.Health <= 0 then
                _targetHRP = nil
                _targetPlayer = nil
                _rescore = PB.RESCORE_INTERVAL
                return
            end
        end

        if not _targetHRP then return end

        -- PREDICCIÓN
        local pingPredict = PB.PING_PREDICT_BASE + PB.PING_PREDICT_EXTRA
        local tVel = _targetHRP.AssemblyLinearVelocity
        local predictedPos = _targetHRP.Position + tVel * pingPredict

        local moveDir2D = Vector3.new(tVel.X, 0, tVel.Z)
        local moveSpeed2D = moveDir2D.Magnitude

        local leadOffset = Vector3.new()

        if moveSpeed2D > PB.VEL_THRESHOLD then
            leadOffset = moveDir2D.Unit * math.clamp(moveSpeed2D * PB.LEAD_FACTOR, 0, PB.LEAD_MAX)
        end

        local targetLook = _targetHRP.CFrame.LookVector
        local behindOffset = targetLook * -2.8
        local verticalOffset = (tVel.Y < -10) and -2 or 0

        local targetPos = predictedPos + behindOffset + leadOffset
        targetPos = Vector3.new(targetPos.X, _targetHRP.Position.Y + verticalOffset, targetPos.Z)

        if _lockModuleRef and _lockModuleRef.IsLockActive and _lockModuleRef.IsLockActive() then
            targetPos += Vector3.new(0, 2.5, 0)
        end

        local _fm = rawget(getgenv(), "_AFO_FLY_MODULE")
        if _fm and _fm.Bypass then
            _fm.Bypass(0.1, "passivebang")
        end

        hrp.CFrame = CFrame.new(targetPos, predictedPos)
        _camera.CFrame = _camera.CFrame:Lerp(
            CFrame.new(_camera.CFrame.Position, predictedPos),
            0.25
        )

        -- DESENGANCHE
        if _leftDown and _rightDown then
            _targetHRP = nil
            _targetPlayer = nil
            _rescore = PB.RESCORE_INTERVAL
            _leftDown = false
            _rightDown = false
        end
    end)

    table.insert(_conns, c1)
    table.insert(_conns, c2)
    table.insert(_conns, c3)
end

-- STOP
function M.Stop()
    for _, c in ipairs(_conns) do
        if c.Disconnect then c:Disconnect() end
    end

    table.clear(_conns)

    _holding = false
    _targetHRP = nil
    _targetPlayer = nil
    _rescore = 0
end

-- CONFIG
function M.SetLockModule(module)
    _lockModuleRef = module
end

function M.SetKeybind(keyCode)
    _bangKey = keyCode
    _holding = false
    _targetHRP = nil
    _targetPlayer = nil
end

function M.GetTeleportTarget()
    if not _holding then return nil end

    local lockActive = false
    if _lockModuleRef and _lockModuleRef.IsLockActive then
        lockActive = _lockModuleRef.IsLockActive()
    end

    return {
        player = _targetPlayer,
        hrp = _targetHRP,
        isLockedByModule = lockActive
    }
end

return M
