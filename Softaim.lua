-- SoftAim.lua
local M = {}

local SOFTAIM = {
    -- Se añadió MouseButton1 (Click Izquierdo) para que active el efecto de inmediato.
    KEYS = { 
        Enum.KeyCode.One, 
        Enum.KeyCode.Two, 
        Enum.KeyCode.Three, 
        Enum.KeyCode.Four, 
        Enum.UserInputType.MouseButton1 
    },
    MAX_DIST = 150,
    LOCK_DURATION = 0.75,
}

local _enabled = false
local _inputConn, _endConn, _heartbeatConn
local _targetHRP, _active, _lockTime = nil, false, 0
local _heldKeys = {}
local _Keys, _lplr, _Players, _RunService, _UIS, _camera

local function clearSoftAim()
    _active = false
    _lockTime = 0
    _targetHRP = nil
    _heldKeys = {}
end

local function findTarget(myHRP)
    local myPos = myHRP.Position
    local myLook = myHRP.CFrame.LookVector
    local myVel = myHRP.AssemblyLinearVelocity
    local mouse = _UIS:GetMouseLocation()

    local bestPriority, bestPriorityScore = nil, math.huge
    local bestNormal, bestNormalScore = nil, math.huge

    for _, player in ipairs(_Players:GetPlayers()) do
        if player ~= _lplr then
            local char = player.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")

            if root and hum and hum.Health > 0 then
                local dir = root.Position - myPos
                local dist = dir.Magnitude

                if dist <= SOFTAIM.MAX_DIST then
                    local dirUnit = dir.Unit
                    local lookDot = myLook:Dot(dirUnit)
                    local velDot = myVel:Dot(dirUnit)

                    -- Verificación de prioridad (Cuerpo en línea fija y moviéndonos hacia él)
                    -- lookDot > 0.85 significa que lo estás mirando casi de frente.
                    -- velDot > 0.5 significa que hay inercia física hacia su dirección.
                    if lookDot > 0.85 and velDot > 0.5 then
                        if dist < bestPriorityScore then
                            bestPriorityScore = dist
                            bestPriority = root
                        end
                    end

                    -- Búsqueda normal (El más cercano al puntero/centro de la pantalla)
                    local screenPos, onScreen = _camera:WorldToViewportPoint(root.Position)
                    if onScreen then
                        local nScore = Vector2.new(mouse.X - screenPos.X, mouse.Y - screenPos.Y).Magnitude
                        if nScore < bestNormalScore then
                            bestNormalScore = nScore
                            bestNormal = root
                        end
                    end
                end
            end
        end
    end

    -- Si hay un objetivo de prioridad, lo asume instantáneamente. Si no, usa el normal.
    return bestPriority or bestNormal
end

local function anyKeyHeld()
    for _, key in ipairs(SOFTAIM.KEYS) do
        if _heldKeys[key] then return true end
    end
    return false
end

local function getMatchedKey(input)
    for _, key in ipairs(SOFTAIM.KEYS) do
        if input.KeyCode == key or input.UserInputType == key then
            return key
        end
    end
    return nil
end

function M.Stop()
    _enabled = false
    clearSoftAim()
    if _inputConn then _inputConn:Disconnect(); _inputConn = nil end
    if _endConn then _endConn:Disconnect(); _endConn = nil end
    if _heartbeatConn then _heartbeatConn:Disconnect(); _heartbeatConn = nil end
end

function M.Setup(Keys, lplr, PlayersRef, RunServiceRef, UserInputService, camera)
    M.Stop()
    _Keys, _lplr, _Players = Keys or {}, lplr, PlayersRef
    _RunService, _UIS, _camera = RunServiceRef, UserInputService, camera
    _enabled = true

    _heartbeatConn = _RunService.Heartbeat:Connect(function()
        if not _enabled then return end

        if anyKeyHeld() then
            _active = true
            _lockTime = tick() + SOFTAIM.LOCK_DURATION
        end
        
        if not _active then return end
        if tick() >= _lockTime then clearSoftAim(); return end

        local char = _lplr.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then return end

        if not _targetHRP or not _targetHRP.Parent then 
            _targetHRP = findTarget(root) 
        end
        
        if not _targetHRP then return end

        local targetChar = _targetHRP.Parent
        local aimPart = (targetChar and targetChar:FindFirstChild("UpperTorso")) or _targetHRP
        local targetPos = aimPart.Position

        -- Ultra Apuntar: Fuerza al cuerpo a mirar EXACTAMENTE al objetivo (CFrame.lookAt puro)
        local rootPos = root.Position
        local lookTargetBody = Vector3.new(targetPos.X, rootPos.Y, targetPos.Z)
        
        if (lookTargetBody - rootPos).Magnitude > 0.1 then
            local velocity = root.AssemblyLinearVelocity
            root.CFrame = CFrame.lookAt(rootPos, lookTargetBody)
            root.AssemblyLinearVelocity = velocity -- Conserva el momentum
        end

        -- Ultra Apuntar: Fuerza a la vista (Cámara) a centrarse en el objetivo instantáneamente
        _camera.CFrame = CFrame.lookAt(_camera.CFrame.Position, targetPos)
    end)

    _inputConn = _UIS.InputBegan:Connect(function(input, gpe)
        if gpe or not _enabled then return end

        if input.KeyCode == Enum.KeyCode.Q
            or input.KeyCode == _Keys.EmoteSteal
            or input.KeyCode == _Keys.EmoteExecute
            or input.KeyCode == _Keys.EmoteExpand then
            clearSoftAim()
            return
        end
        
        local matchedKey = getMatchedKey(input)
        if matchedKey then
            _heldKeys[matchedKey] = true
            _active = true
            _lockTime = tick() + SOFTAIM.LOCK_DURATION
        end
    end)

    _endConn = _UIS.InputEnded:Connect(function(input)
        local matchedKey = getMatchedKey(input)
        if matchedKey then
            _heldKeys[matchedKey] = false
        end
    end)
end

function M.SetEnabled(value)
    _enabled = value == true
    if not _enabled then clearSoftAim() end
end

return M
