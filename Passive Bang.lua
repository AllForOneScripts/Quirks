-- PassiveBang_lock_reader.lua
-- Requiere que el lector de Lock se haya ejecutado primero y haya inyectado
-- los valores AFO_LockActive y AFO_LockedTarget en el Character.

local M = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local _lplr
local _camera = workspace.CurrentCamera
local _conns = {}
local _bangKey = Enum.KeyCode.Quote
local _holding = false
local _targetHRP
local _targetPlayer
local _leftDown = false
local _rightDown = false
local _rescore = 0
local _wasLockActive = false

-- Sistema de depuración (Debug)
local _lastError = ""
local function dLog(msg)
    warn("[PassiveBang Debug] " .. tostring(msg))
end

local function dError(msg)
    -- Evitar spam de 60 errores por segundo en la consola
    if msg ~= _lastError then
        warn("[PassiveBang ERROR CRÍTICO] " .. tostring(msg))
        _lastError = msg
    end
end

-- Estado del TP de caída
local _dropTargetRoot
local _dropStickUntil = 0
local _dropCompletedFor

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
    CAMERA_SMOOTH = 1,
    FALL_TRIGGER_HEIGHT = 20,
    FALL_HEAD_STICK_TIME = 0.22,
    FALL_STICK_VELOCITY = -20,
    FALL_RELEASE_VELOCITY = -140,
    FALL_HITBOX_VERTICAL_REACH = 3,
    FALL_GROUND_SAFETY_MARGIN = 0.75,
    FALL_HEAD_HEIGHT_ADJUSTMENT = -3.5,
}

local function isSafeVector(v)
    return v.X == v.X and v.Y == v.Y and v.Z == v.Z and math.abs(v.X) < 1e5 and math.abs(v.Y) < 1e5 and math.abs(v.Z) < 1e5
end

local function resetDrop()
    _dropTargetRoot = nil
    _dropStickUntil = 0
    _dropCompletedFor = nil
end

local function resetTarget()
    if _targetPlayer then
        dLog("Objetivo reseteado (Anterior: " .. tostring(_targetPlayer) .. ")")
    end
    _targetHRP = nil
    _targetPlayer = nil
    _rescore = PB.RESCORE_INTERVAL
    resetDrop()
end

local function updateCharacter()
    dLog("Personaje actualizado/reaparecido.")
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
    if not root or not isSafeVector(root.Position) then return nil end

    local distance = (root.Position - myRoot.Position).Magnitude
    local isCurrent = root == _targetHRP
    if distance > (isCurrent and PB.MAX_ENGAGED_DIST or PB.MAX_3D_DIST) then return nil end

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

    for _, candidate in ipairs(Players:GetPlayers()) do
        local score, root, player = scoreCandidate(candidate, myRoot, mouse.X, mouse.Y)
        if score and score > bestScore then
            bestScore, bestRoot, bestPlayer = score, root, player
        end
    end
    return bestRoot, bestPlayer
end

local function getLockAPIState()
    local lplr = _lplr or Players.LocalPlayer
    local char = lplr and lplr.Character
    
    if not char then
        return { success = false, isLocked = false, target = nil }
    end

    local activeVal = char:FindFirstChild("AFO_LockActive")
    local targetVal = char:FindFirstChild("AFO_LockedTarget")

    if not activeVal or not targetVal then
        return { success = false, isLocked = false, target = nil }
    end

    return {
        success = true,
        isLocked = activeVal.Value,
        target = targetVal.Value
    }
end

local function getLockTarget()
    local lockData = getLockAPIState()
    
    if lockData.success and lockData.isLocked and lockData.target then
        if typeof(lockData.target) == "Instance" and lockData.target:IsA("Player") then
            local root = getLiveRoot(lockData.target)
            if root then
                return lockData.target, root
            end
        end
    end
    
    return nil, nil
end

local function getPredictedPosition(targetRoot)
    local velocity = targetRoot.AssemblyLinearVelocity
    if not isSafeVector(velocity) then velocity = Vector3.zero end
    
    local predicted = targetRoot.Position + velocity * (PB.PING_PREDICT_BASE + PB.PING_PREDICT_EXTRA)
    local horizontalVelocity = Vector3.new(velocity.X, 0, velocity.Z)
    local lead = Vector3.zero
    if horizontalVelocity.Magnitude > PB.VEL_THRESHOLD then
        lead = horizontalVelocity.Unit * math.clamp(horizontalVelocity.Magnitude * PB.LEAD_FACTOR, 0, PB.LEAD_MAX)
    end
    return predicted, velocity, lead
end

local function faceTarget(myRoot, targetPosition)
    if not isSafeVector(targetPosition) then return end
    local flatTarget = Vector3.new(targetPosition.X, myRoot.Position.Y, targetPosition.Z)
    if (flatTarget - myRoot.Position).Magnitude > 0.05 then
        myRoot.CFrame = CFrame.lookAt(myRoot.Position, flatTarget)
    end
end

local function aimCamera(targetPosition)
    _camera = workspace.CurrentCamera or _camera
    if not _camera or not isSafeVector(targetPosition) then return end
    local origin = _camera.CFrame.Position
    if (targetPosition - origin).Magnitude > 0.05 then
        _camera.CFrame = _camera.CFrame:Lerp(CFrame.lookAt(origin, targetPosition), math.clamp(PB.CAMERA_SMOOTH, 0, 1))
    end
end

local function getGroundBelow(position, ignored)
    if not isSafeVector(position) then return nil end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = ignored
    params.RespectCanCollide = true
    return workspace:Raycast(position + Vector3.new(0, 3, 0), Vector3.new(0, -10000, 0), params)
end

local function doFallingTeleport(myRoot, myHumanoid, targetRoot)
    local now = tick()

    if _dropCompletedFor == targetRoot then
        myRoot.CFrame = CFrame.new(targetRoot.Position.X, myRoot.Position.Y, targetRoot.Position.Z)
        myRoot.AssemblyLinearVelocity = Vector3.new(0, myRoot.AssemblyLinearVelocity.Y, 0)
        return true
    end

    if _dropTargetRoot ~= targetRoot and _dropCompletedFor ~= targetRoot
        and myRoot.Position.Y - targetRoot.Position.Y >= PB.FALL_TRIGGER_HEIGHT then
        _dropTargetRoot = targetRoot
        _dropStickUntil = now + PB.FALL_HEAD_STICK_TIME
    end

    if _dropTargetRoot ~= targetRoot then return false end
    if not targetRoot.Parent then
        resetDrop()
        return false
    end

    if now < _dropStickUntil then
        local head = targetRoot.Parent:FindFirstChild("Head")
        local headPosition = head and head.Position or (targetRoot.Position + Vector3.new(0, targetRoot.Size.Y, 0))
        local footHeight = myHumanoid.HipHeight + (myRoot.Size.Y / 2) + 0.15
        local height = footHeight + PB.FALL_HEAD_HEIGHT_ADJUSTMENT

        local ground = getGroundBelow(headPosition, { myRoot.Parent, targetRoot.Parent })
        local entryY = math.max(
            headPosition.Y + height,
            targetRoot.Position.Y + PB.FALL_HITBOX_VERTICAL_REACH
        )
        if ground then
            entryY = math.max(
                entryY,
                ground.Position.Y + PB.FALL_HITBOX_VERTICAL_REACH + PB.FALL_GROUND_SAFETY_MARGIN
            )
        end

        myRoot.CFrame = CFrame.new(targetRoot.Position.X, entryY, targetRoot.Position.Z)
        myRoot.AssemblyLinearVelocity = Vector3.new(0, PB.FALL_STICK_VELOCITY, 0)
        return true
    end

    myRoot.CFrame = CFrame.new(targetRoot.Position.X, myRoot.Position.Y, targetRoot.Position.Z)
    myRoot.AssemblyLinearVelocity = Vector3.new(0, PB.FALL_RELEASE_VELOCITY, 0)
    _dropCompletedFor = targetRoot
    _dropTargetRoot = nil
    return true
end

function M.Start(lplr)
    -- Corrección: Asegurarse de que el argumento pasado sea una instancia de Player
    if typeof(lplr) ~= "Instance" or not lplr:IsA("Player") then
        lplr = Players.LocalPlayer
    end
    
    -- Corrección: Esperar al LocalPlayer en caso de que el script se ejecute prematuramente
    while not lplr do
        task.wait()
        lplr = Players.LocalPlayer
    end
    
    _lplr = lplr
    dLog("Módulo Start() llamado. LocalPlayer: " .. tostring(_lplr.Name))

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
            dLog("Tecla activada (" .. tostring(_bangKey) .. "). _holding = true")
        end
    end))

    table.insert(_conns, UserInputService.InputEnded:Connect(function(input)
        if input.KeyCode == _bangKey then
            _holding = false
            resetTarget()
            dLog("Tecla soltada. _holding = false")
        end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then _leftDown = false end
        if input.UserInputType == Enum.UserInputType.MouseButton2 then _rightDown = false end
    end))

    table.insert(_conns, RunService.RenderStepped:Connect(function()
        if not _holding then return end

        local success, err = pcall(function()
            local myChar = _lplr.Character
            local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
            local myHumanoid = myChar and myChar:FindFirstChildOfClass("Humanoid")
            if not myRoot or not myHumanoid or not isSafeVector(myRoot.Position) then return end

            local lockedPlayer, lockedRoot = getLockTarget()
            local isLocked = lockedPlayer ~= nil and lockedRoot ~= nil
            
            if isLocked ~= _wasLockActive then
                resetDrop()
                _wasLockActive = isLocked
                dLog("Cambio de estado Lock: " .. tostring(isLocked))
            end
            
            if isLocked then
                if _targetHRP ~= lockedRoot then
                    resetDrop()
                end
                _targetPlayer, _targetHRP = lockedPlayer, lockedRoot
                _rescore = PB.RESCORE_INTERVAL
            else
                _rescore = _rescore + 1
                if _rescore >= PB.RESCORE_INTERVAL or not _targetHRP then
                    _rescore = 0
                    local newRoot, newPlayer = selectPassiveTarget(myRoot)
                    if newRoot then 
                        if _targetPlayer ~= newPlayer then
                            dLog("Nuevo objetivo pasivo seleccionado: " .. tostring(newPlayer))
                        end
                        _targetHRP, _targetPlayer = newRoot, newPlayer 
                    else 
                        resetTarget() 
                    end
                end
            end

            local validRoot = _targetPlayer and getLiveRoot(_targetPlayer)
            if not validRoot then resetTarget(); return end
            _targetHRP = validRoot

            local predicted, velocity, lead = getPredictedPosition(_targetHRP)

            local fly_success, fly = pcall(function() 
                if type(getgenv) == "function" then
                    return getgenv()._AFO_FLY_MODULE 
                end
                return nil
            end)
            if fly_success and fly and type(fly.Bypass) == "function" then
                pcall(fly.Bypass, 0.1, "passivebang")
            end

            local doingFallTP = doFallingTeleport(myRoot, myHumanoid, _targetHRP)
            if not doingFallTP and isSafeVector(predicted) then
                local behind = _targetHRP.CFrame.LookVector * -2.8
                local vertical = velocity.Y < -10 and -2 or 0
                local targetPosition = predicted + behind + lead
                targetPosition = Vector3.new(targetPosition.X, _targetHRP.Position.Y + vertical, targetPosition.Z)
                if isLocked then targetPosition += Vector3.new(0, 2.5, 0) end
                
                if (targetPosition - predicted).Magnitude > 0.05 then
                    myRoot.CFrame = CFrame.lookAt(targetPosition, predicted)
                else
                    myRoot.CFrame = CFrame.new(targetPosition)
                end
            end

            faceTarget(myRoot, predicted)

            if not isLocked then
                aimCamera(predicted)
            end

            if not isLocked and _leftDown and _rightDown then
                dLog("Clicks izquierdo y derecho presionados, reseteando objetivo.")
                resetTarget()
                _leftDown, _rightDown = false, false
            end
        end)

        if not success then
            dError("Fallo en el bucle RenderStepped: " .. tostring(err))
        end
    end))
end

function M.Stop()
    dLog("Deteniendo módulo.")
    for _, connection in ipairs(_conns) do pcall(function() connection:Disconnect() end) end
    table.clear(_conns)
    _holding = false
    _leftDown, _rightDown = false, false
    _wasLockActive = false
    resetTarget()
end

function M.SetLockModule(module)
end

function M.SetKeybind(keyCode)
    dLog("Tecla cambiada a: " .. tostring(keyCode))
    _bangKey = keyCode
    _holding = false
    resetTarget()
end

function M.GetTeleportTarget()
    if not _holding then return nil end
    local lockedPlayer, lockedRoot = getLockTarget()
    
    if lockedPlayer and lockedRoot then
        return {
            player = lockedPlayer,
            hrp = lockedRoot,
            isLockedByModule = true,
        }
    end
    return {
        player = _targetPlayer,
        hrp = _targetHRP,
        isLockedByModule = false,
    }
end

return M
