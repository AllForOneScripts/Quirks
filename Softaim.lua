-- SoftAim_corregido.lua
-- Integración obligatoria: SoftAim.SetLockModule(LockModule)

local M = {}

local SOFTAIM = {
    KEYS = { Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Four },
    MAX_DIST = 80,
    ROTATION_SMOOTH = 0.8,
    LOCK_DURATION = 0.75,
}

local _enabled = false
local _inputConn, _endConn, _heartbeatConn
local _targetHRP, _active, _lockTime, _highlight = nil, false, 0, nil
local _heldKeys = {}
local _Keys, _lplr, _Players, _RunService, _UIS, _camera
local _lockModuleRef

local function clearHighlight()
    if _highlight then _highlight.Parent = nil end
end

local function clearSoftAim()
    _active = false
    _lockTime = 0
    _targetHRP = nil
    _heldKeys = {}
    clearHighlight()
end

local function ensureHighlight()
    if _highlight then return end
    _highlight = Instance.new("Highlight")
    _highlight.FillColor = Color3.fromRGB(255, 0, 0)
    _highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    _highlight.FillTransparency = 0.85
end

-- Una única fuente de verdad: la API pública del módulo Lock.
-- No depende de getgenv(), porque el Lock compartido no publica AFO_LOCK_ACTIVE.
local function lockHasValidTarget()
    if not _lockModuleRef
        or type(_lockModuleRef.IsLockActive) ~= "function"
        or type(_lockModuleRef.GetTarget) ~= "function" then
        return false
    end

    local okActive, isActive = pcall(_lockModuleRef.IsLockActive)
    if not okActive or isActive ~= true then return false end

    local okTarget, target = pcall(_lockModuleRef.GetTarget)
    if not okTarget or not target then return false end

    local char = target.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    return hum ~= nil and hum.Health > 0
end

local function findNearestTarget(myHRP)
    local mouse = _UIS:GetMouseLocation()
    local best, bestScore = nil, math.huge
    for _, player in ipairs(_Players:GetPlayers()) do
        if player ~= _lplr then
            local char = player.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if root and hum and hum.Health > 0 then
                local distance = (root.Position - myHRP.Position).Magnitude
                if distance <= SOFTAIM.MAX_DIST then
                    local screenPos, onScreen = _camera:WorldToViewportPoint(root.Position)
                    local score = onScreen
                        and Vector2.new(mouse.X - screenPos.X, mouse.Y - screenPos.Y).Magnitude
                        or 10000 + distance
                    if score < bestScore then best, bestScore = root, score end
                end
            end
        end
    end
    return best
end

local function anyKeyHeld()
    for _, key in ipairs(SOFTAIM.KEYS) do
        if _heldKeys[key] then return true end
    end
    return false
end

function M.Stop()
    _enabled = false
    clearSoftAim()
    if _inputConn then _inputConn:Disconnect(); _inputConn = nil end
    if _endConn then _endConn:Disconnect(); _endConn = nil end
    if _heartbeatConn then _heartbeatConn:Disconnect(); _heartbeatConn = nil end
end

function M.SetLockModule(lockModule)
    _lockModuleRef = lockModule
    -- Si se conecta un Lock que ya está activo, no queda softaim residual.
    if lockHasValidTarget() then clearSoftAim() end
end

function M.Setup(Keys, lplr, Players, RunService, UserInputService, camera)
    M.Stop()
    _Keys, _lplr, _Players = Keys or {}, lplr, Players
    _RunService, _UIS, _camera = RunService, UserInputService, camera
    _enabled = true
    ensureHighlight()

    _heartbeatConn = _RunService.Heartbeat:Connect(function()
        if not _enabled then return end

        -- Se apaga por completo y borra teclas retenidas mientras exista lock.
        if lockHasValidTarget() then
            clearSoftAim()
            return
        end

        if anyKeyHeld() then
            _active = true
            _lockTime = tick() + SOFTAIM.LOCK_DURATION
        end
        if not _active then clearHighlight(); return end
        if tick() >= _lockTime then clearSoftAim(); return end

        local char = _lplr.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        if not _targetHRP or not _targetHRP.Parent then _targetHRP = findNearestTarget(root) end
        if not _targetHRP then clearHighlight(); return end

        local targetChar = _targetHRP.Parent
        local aimPart = (targetChar and targetChar:FindFirstChild("UpperTorso")) or _targetHRP
        local lookTarget = Vector3.new(aimPart.Position.X, root.Position.Y, aimPart.Position.Z)
        if (lookTarget - root.Position).Magnitude > 0.1 then
            local _, currentYaw = root.CFrame:ToEulerAnglesYXZ()
            local _, targetYaw = CFrame.lookAt(root.Position, lookTarget):ToEulerAnglesYXZ()
            local difference = targetYaw - currentYaw
            if difference > math.pi then difference -= 2 * math.pi end
            if difference < -math.pi then difference += 2 * math.pi end
            local velocity = root.AssemblyLinearVelocity
            root.CFrame = CFrame.new(root.Position) * CFrame.Angles(0, currentYaw + difference * SOFTAIM.ROTATION_SMOOTH, 0)
            root.AssemblyLinearVelocity = velocity
        end
        _highlight.Parent = targetChar
    end)

    _inputConn = _UIS.InputBegan:Connect(function(input, gpe)
        if gpe or not _enabled then return end
        -- Impide incluso crear/renovar estado de softaim mientras Lock tiene objetivo.
        if lockHasValidTarget() then clearSoftAim(); return end

        if input.KeyCode == Enum.KeyCode.Q
            or input.KeyCode == _Keys.EmoteSteal
            or input.KeyCode == _Keys.EmoteExecute
            or input.KeyCode == _Keys.EmoteExpand then
            clearSoftAim()
            return
        end
        for _, key in ipairs(SOFTAIM.KEYS) do
            if input.KeyCode == key then
                _heldKeys[key] = true
                _active = true
                _lockTime = tick() + SOFTAIM.LOCK_DURATION
                break
            end
        end
    end)

    _endConn = _UIS.InputEnded:Connect(function(input)
        for _, key in ipairs(SOFTAIM.KEYS) do
            if input.KeyCode == key then _heldKeys[key] = false; break end
        end
    end)
end

function M.SetEnabled(value)
    _enabled = value == true
    if not _enabled then clearSoftAim() end
end

return M
