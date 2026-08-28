-- SoftAim.lua
local M = {}

local SOFTAIM = {
    KEYS = { 
        Enum.KeyCode.One, 
        Enum.KeyCode.Two, 
        Enum.KeyCode.Three, 
        Enum.KeyCode.Four, 
        Enum.UserInputType.MouseButton1 
    },
    LOCK_DURATION = 0.75,
}

local _enabled = false
local _inputConn, _endConn, _heartbeatConn
local _targetHRP, _active, _lockTime = nil, false, 0
local _heldKeys = {}
local _activeTrigger = "None"
local _lastCamY = nil
local _currentHighlight = nil
local _Keys, _lplr, _Players, _RunService, _UIS, _camera

-- ==============================
-- Funciones Visuales (Marca)
-- ==============================
local function removeHighlight()
    if _currentHighlight then
        _currentHighlight:Destroy()
        _currentHighlight = nil
    end
end

local function applyHighlight(targetChar)
    if not targetChar then return end
    if _currentHighlight and _currentHighlight.Parent == targetChar then return end
    removeHighlight()
    
    _currentHighlight = Instance.new("Highlight")
    _currentHighlight.Name = "SoftAimHighlight"
    _currentHighlight.FillTransparency = 1
    _currentHighlight.OutlineColor = Color3.new(1, 1, 1)
    _currentHighlight.OutlineTransparency = 0.4
    _currentHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    _currentHighlight.Parent = targetChar
end

-- ==============================
-- Lógica Principal
-- ==============================
local function clearSoftAim()
    _active = false
    _lockTime = 0
    _targetHRP = nil
    _heldKeys = {}
    _activeTrigger = "None"
    _lastCamY = nil
    removeHighlight()
end

local function updateTriggerType()
    if _heldKeys[Enum.UserInputType.MouseButton1] then
        _activeTrigger = "Click"
    else
        local numHeld = false
        for _, k in ipairs({Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Four}) do
            if _heldKeys[k] then numHeld = true; break end
        end
        _activeTrigger = numHeld and "Number" or "None"
    end
end

local function findTarget(myHRP)
    local myPos = myHRP.Position
    local myLook = myHRP.CFrame.LookVector
    local myVel = myHRP.AssemblyLinearVelocity
    local mouse = _UIS:GetMouseLocation()

    local bestPriority, bestPriorityScore = nil, math.huge
    local bestNormal, bestNormalScore = nil, math.huge

    local maxDist = (_activeTrigger == "Click") and 6 or 35

    for _, player in ipairs(_Players:GetPlayers()) do
        if player ~= _lplr then
            local char = player.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")

            -- Evita buscar cadáveres desde el inicio
            if root and hum and hum.Health > 0 then
                local dir = root.Position - myPos
                local dist = dir.Magnitude

                if dist <= maxDist then
                    local dirUnit = dir.Unit
                    local lookDot = myLook:Dot(dirUnit)
                    local velDot = myVel:Dot(dirUnit)

                    if lookDot > 0.85 and velDot > 0.5 then
                        if dist < bestPriorityScore then
                            bestPriorityScore = dist
                            bestPriority = root
                        end
                    end

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

    _heartbeatConn = _RunService.Heartbeat:Connect(function(dt)
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

        -- VALIDACIÓN ANTI-CADÁVERES: Si el objetivo actual muere, lo soltamos inmediatamente
        if _targetHRP and _targetHRP.Parent then
            local targetHum = _targetHRP.Parent:FindFirstChildOfClass("Humanoid")
            if not targetHum or targetHum.Health <= 0 then
                _targetHRP = nil
                removeHighlight()
            end
        end

        if not _targetHRP or not _targetHRP.Parent then 
            _targetHRP = findTarget(root) 
            _lastCamY = nil 
        end
        
        if not _targetHRP then 
            removeHighlight()
            return 
        end

        local targetChar = _targetHRP.Parent
        applyHighlight(targetChar)

        local aimPart = (targetChar and targetChar:FindFirstChild("UpperTorso")) or _targetHRP
        local targetPos = aimPart.Position
        local rootPos = root.Position

        local hzDist = Vector2.new(targetPos.X - rootPos.X, targetPos.Z - rootPos.Z).Magnitude

        if hzDist > 1.5 then 
            
            -- Movimiento del Cuerpo
            local lookTargetBody = Vector3.new(targetPos.X, rootPos.Y, targetPos.Z)
            local velocity = root.AssemblyLinearVelocity
            local targetBodyCFrame = CFrame.lookAt(rootPos, lookTargetBody)
            root.CFrame = root.CFrame:Lerp(targetBodyCFrame, math.clamp(dt * 18, 0, 1))
            root.AssemblyLinearVelocity = velocity 
            
            -- Movimiento de Cámara
            local camPos = _camera.CFrame.Position
            if not _lastCamY then _lastCamY = targetPos.Y end
            _lastCamY = _lastCamY + (targetPos.Y - _lastCamY) * math.clamp(dt * 3.5, 0, 1)

            local camLookPos = Vector3.new(targetPos.X, _lastCamY, targetPos.Z)
            local desiredCamCFrame = CFrame.lookAt(camPos, camLookPos)
            
            _camera.CFrame = _camera.CFrame:Lerp(desiredCamCFrame, math.clamp(dt * 12, 0, 1))
        end
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
            updateTriggerType()
            _active = true
            _lockTime = tick() + SOFTAIM.LOCK_DURATION
        end
    end)

    _endConn = _UIS.InputEnded:Connect(function(input)
        local matchedKey = getMatchedKey(input)
        if matchedKey then
            _heldKeys[matchedKey] = false
            updateTriggerType()
        end
    end)
end

function M.SetEnabled(value)
    _enabled = value == true
    if not _enabled then clearSoftAim() end
end

return M
