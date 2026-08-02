-- PassiveBang_corregido.lua
-- El módulo Lock debe conectarse antes de usar el bang:
--   PassiveBang.SetLockModule(LockModule)

local M = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local _lplr
local _camera = workspace.CurrentCamera
local _conns = {}

local _bangKey = Enum.KeyCode.Quote
local _lockModuleRef
local _holding = false
local _targetHRP
local _targetPlayer
local _leftDown = false
local _rightDown = false
local _rescore = 0

local PB = {
    MAX_3D_DIST = 150,
    MAX_ENGAGED_DIST = 250,
    W_PROXIMITY = 7.0,
    W_MOUSE = 3.0,
    MAX_SCREEN_DIST_MOUSE = 350,
    W_CONTINUITY = 2.0,
    PING_PREDICT_BASE = 0.15,
    PING_PREDICT_EXTRA = 0.10,
    LEAD_FACTOR = 0.55,
    LEAD_MAX = 8,
    VEL_THRESHOLD = 8,
    RESCORE_INTERVAL = 12,
    -- 1 = giro inmediato; garantiza que la cámara no quede mirando al objetivo anterior.
    CAMERA_SMOOTH = 1,
}

local function resetTarget()
    _targetHRP = nil
    _targetPlayer = nil
    _rescore = PB.RESCORE_INTERVAL
end

local function updateCharacter()
    _holding = false
    resetTarget()
end

local function getLiveRoot(player)
    if not player or player == _lplr then return nil end
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not root or not hum or hum.Health <= 0 then return nil end
    return root, hum
end

local function scoreCandidate(player, myRoot, mouseX, mouseY)
    local root = getLiveRoot(player)
    if not root then return nil end

    local distance = (root.Position - myRoot.Position).Magnitude
    local isCurrent = root == _targetHRP
    local maxDistance = isCurrent and PB.MAX_ENGAGED_DIST or PB.MAX_3D_DIST
    if distance > maxDistance then return nil end

    local proximity = PB.W_PROXIMITY * (1 - math.clamp(distance / PB.MAX_3D_DIST, 0, 1))
    local mouseScore = 0
    local screenPos, onScreen = _camera:WorldToViewportPoint(root.Position)
    if onScreen then
        local screenDistance = Vector2.new(mouseX - screenPos.X, mouseY - screenPos.Y).Magnitude
        if screenDistance <= PB.MAX_SCREEN_DIST_MOUSE then
            mouseScore = PB.W_MOUSE * (1 - screenDistance / PB.MAX_SCREEN_DIST_MOUSE)
        end
    end

    return proximity + mouseScore + (isCurrent and PB.W_CONTINUITY or 0), root, player
end

local function selectPassiveTarget(myRoot)
    local mouse = _lplr:GetMouse()
    local bestScore, bestRoot, bestPlayer = -math.huge, nil, nil

    for _, player in ipairs(Players:GetPlayers()) do
        local score, root, candidate = scoreCandidate(player, myRoot, mouse.X, mouse.Y)
        if score and score > bestScore then
            bestScore, bestRoot, bestPlayer = score, root, candidate
        end
    end

    return bestRoot, bestPlayer
end

-- Devuelve el lock solo si las dos llamadas de la API son válidas.
-- No hay ningún filtro de distancia aquí: un lock válido siempre gana.
local function getLockTarget()
    if not _lockModuleRef
        or type(_lockModuleRef.IsLockActive) ~= "function"
        or type(_lockModuleRef.GetTarget) ~= "function" then
        return nil
    end

    local okActive, active = pcall(_lockModuleRef.IsLockActive)
    if not okActive or active ~= true then return nil end

    local okTarget, target = pcall(_lockModuleRef.GetTarget)
    if not okTarget then return nil end

    local root = getLiveRoot(target)
    if not root then return nil end
    return target, root
end

local function getPredictedPosition(targetRoot)
    local velocity = targetRoot.AssemblyLinearVelocity
    local predicted = targetRoot.Position + velocity * (PB.PING_PREDICT_BASE + PB.PING_PREDICT_EXTRA)
    local horizontalVelocity = Vector3.new(velocity.X, 0, velocity.Z)
    local lead = Vector3.zero

    if horizontalVelocity.Magnitude > PB.VEL_THRESHOLD then
        lead = horizontalVelocity.Unit * math.clamp(
            horizontalVelocity.Magnitude * PB.LEAD_FACTOR,
            0,
            PB.LEAD_MAX
        )
    end

    return predicted, velocity, lead
end

local function faceTarget(myRoot, targetPosition)
    -- Mantiene el eje vertical del personaje estable y mira horizontalmente al objetivo.
    local flatTarget = Vector3.new(targetPosition.X, myRoot.Position.Y, targetPosition.Z)
    if (flatTarget - myRoot.Position).Magnitude > 0.01 then
        myRoot.CFrame = CFrame.lookAt(myRoot.Position, flatTarget)
    end
end

local function aimCamera(targetPosition)
    _camera = workspace.CurrentCamera or _camera
    if not _camera then return end

    local origin = _camera.CFrame.Position
    if (targetPosition - origin).Magnitude > 0.01 then
        _camera.CFrame = _camera.CFrame:Lerp(
            CFrame.lookAt(origin, targetPosition),
            PB.CAMERA_SMOOTH
        )
    end
end

function M.Start(lplr)
    _lplr = lplr or Players.LocalPlayer
    if #_conns > 0 then M.Stop() end

    table.insert(_conns, _lplr.CharacterAdded:Connect(updateCharacter))
    updateCharacter()

    table.insert(_conns, UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then _leftDown = true end
        if input.UserInputType == Enum.UserInputType.MouseButton2 then _rightDown = true end
        if input.KeyCode == _bangKey then
            _holding = true
            _rescore = PB.RESCORE_INTERVAL
        end
    end))

    table.insert(_conns, UserInputService.InputEnded:Connect(function(input)
        if input.KeyCode == _bangKey then
            _holding = false
            resetTarget()
        end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then _leftDown = false end
        if input.UserInputType == Enum.UserInputType.MouseButton2 then _rightDown = false end
    end))

    table.insert(_conns, RunService.RenderStepped:Connect(function()
        if not _holding then return end

        local myChar = _lplr.Character
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myRoot then return end

        -- Esta decisión ocurre antes del scan: el lock siempre tiene prioridad.
        local lockedPlayer, lockedRoot = getLockTarget()
        local isLocked = lockedPlayer ~= nil

        if isLocked then
            _targetPlayer, _targetHRP = lockedPlayer, lockedRoot
            _rescore = PB.RESCORE_INTERVAL
        else
            _rescore += 1
            if _rescore >= PB.RESCORE_INTERVAL or not _targetHRP then
                _rescore = 0
                local newRoot, newPlayer = selectPassiveTarget(myRoot)
                if newRoot then
                    _targetHRP, _targetPlayer = newRoot, newPlayer
                else
                    resetTarget()
                end
            end
        end

        local validRoot = _targetPlayer and getLiveRoot(_targetPlayer)
        if not validRoot then
            resetTarget()
            return
        end
        _targetHRP = validRoot

        local predicted, velocity, lead = getPredictedPosition(_targetHRP)
        local behind = _targetHRP.CFrame.LookVector * -2.8
        local vertical = velocity.Y < -10 and -2 or 0
        local targetPosition = predicted + behind + lead
        targetPosition = Vector3.new(targetPosition.X, _targetHRP.Position.Y + vertical, targetPosition.Z)
        if isLocked then targetPosition += Vector3.new(0, 2.5, 0) end

        local fly = rawget(getgenv(), "_AFO_FLY_MODULE")
        if fly and type(fly.Bypass) == "function" then
            fly.Bypass(0.1, "passivebang")
        end

        myRoot.CFrame = CFrame.lookAt(targetPosition, predicted)

        -- También se ejecuta sin lock: cámara y personaje quedan mirando al objetivo pasivo.
        faceTarget(myRoot, predicted)
        aimCamera(predicted)

        if _leftDown and _rightDown then
            resetTarget()
            _leftDown, _rightDown = false, false
        end
    end))
end

function M.Stop()
    for _, connection in ipairs(_conns) do connection:Disconnect() end
    table.clear(_conns)
    _holding = false
    _leftDown, _rightDown = false, false
    resetTarget()
end

function M.SetLockModule(module)
    _lockModuleRef = module
end

function M.SetKeybind(keyCode)
    _bangKey = keyCode
    _holding = false
    resetTarget()
end

function M.GetTeleportTarget()
    if not _holding then return nil end
    local lockedPlayer = getLockTarget()
    return { player = _targetPlayer, hrp = _targetHRP, isLockedByModule = lockedPlayer ~= nil }
end

return M
