local M = {}

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local _isEnabled = false
local _speed = 50
local _maxSpeed = 120
local _acceleration = 2
local _bodyVelocity = nil
local _runServiceConnection = nil
local _keyPressed = {}
local _connections = {}

local _controls = {
    forward = Enum.KeyCode.W,
    backward = Enum.KeyCode.S,
    left = Enum.KeyCode.A,
    right = Enum.KeyCode.D,
    up = Enum.KeyCode.Space,
    down = Enum.KeyCode.LeftControl,
}

-- ───────────────────────────────────────────────────────────────────────────
--  UTILIDADES LOCALES
-- ───────────────────────────────────────────────────────────────────────────
local function getRootPart(player)
    local lplr = player or Players.LocalPlayer
    if lplr and lplr.Character then
        return lplr.Character:FindFirstChild("HumanoidRootPart")
    end
    return nil
end

local function createBodyVelocity(player)
    local rootPart = getRootPart(player)
    if not rootPart then return nil end
    
    if rootPart:FindFirstChild("ClusterVelocity") then
        rootPart:FindFirstChild("ClusterVelocity"):Destroy()
    end
    
    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.Name = "ClusterVelocity"
    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bodyVelocity.D = 500
    bodyVelocity.P = 10000
    bodyVelocity.Parent = rootPart
    
    return bodyVelocity
end

local function removeBodyVelocity(player)
    local rootPart = getRootPart(player)
    if rootPart then
        local bv = rootPart:FindFirstChild("ClusterVelocity")
        if bv then bv:Destroy() end
    end
end

-- ───────────────────────────────────────────────────────────────────────────
--  LÓGICA DE MOVIMIENTO
-- ───────────────────────────────────────────────────────────────────────────
local function getMovementDirection()
    local camera = workspace.CurrentCamera
    local direction = Vector3.new(0, 0, 0)
    
    if _keyPressed[_controls.forward] then
        direction = direction + camera.CFrame.LookVector * Vector3.new(1, 0, 1)
    end
    if _keyPressed[_controls.backward] then
        direction = direction - camera.CFrame.LookVector * Vector3.new(1, 0, 1)
    end
    if _keyPressed[_controls.right] then
        direction = direction + camera.CFrame.RightVector * Vector3.new(1, 0, 1)
    end
    if _keyPressed[_controls.left] then
        direction = direction - camera.CFrame.RightVector * Vector3.new(1, 0, 1)
    end
    
    if _keyPressed[_controls.up] then
        direction = direction + Vector3.new(0, 1, 0)
    end
    if _keyPressed[_controls.down] then
        direction = direction - Vector3.new(0, 1, 0)
    end
    
    if direction.Magnitude > 0 then
        direction = direction.Unit
    end
    
    return direction
end

local function updateMovement(player)
    if not _isEnabled then return end
    
    local rootPart = getRootPart(player)
    if not rootPart or not _bodyVelocity then return end
    
    local moveDir = getMovementDirection()
    
    if moveDir.Magnitude > 0 then
        _speed = math.min(_speed + _acceleration, _maxSpeed)
    else
        _speed = math.max(_speed - _acceleration * 0.5, 0)
    end
    
    local velocity = moveDir * _speed
    local currentVel = _bodyVelocity.Velocity
    local smoothVel = currentVel:Lerp(velocity, 0.15)
    
    _bodyVelocity.Velocity = smoothVel
end

-- ───────────────────────────────────────────────────────────────────────────
--  MANEJO DE ENTRADAS (INPUTS)
-- ───────────────────────────────────────────────────────────────────────────
local function setupInputHandling()
    table.insert(_connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == _controls.forward then _keyPressed[_controls.forward] = true end
        if input.KeyCode == _controls.backward then _keyPressed[_controls.backward] = true end
        if input.KeyCode == _controls.left then _keyPressed[_controls.left] = true end
        if input.KeyCode == _controls.right then _keyPressed[_controls.right] = true end
        if input.KeyCode == _controls.up then _keyPressed[_controls.up] = true end
        if input.KeyCode == _controls.down then _keyPressed[_controls.down] = true end
    end))
    
    table.insert(_connections, UserInputService.InputEnded:Connect(function(input)
        if input.KeyCode == _controls.forward then _keyPressed[_controls.forward] = false end
        if input.KeyCode == _controls.backward then _keyPressed[_controls.backward] = false end
        if input.KeyCode == _controls.left then _keyPressed[_controls.left] = false end
        if input.KeyCode == _controls.right then _keyPressed[_controls.right] = false end
        if input.KeyCode == _controls.up then _keyPressed[_controls.up] = false end
        if input.KeyCode == _controls.down then _keyPressed[_controls.down] = false end
    end))
end

-- ───────────────────────────────────────────────────────────────────────────
--  API PÚBLICA
-- ───────────────────────────────────────────────────────────────────────────

function M.Start(player, activationKey)
    if _isEnabled then return end
    _isEnabled = true
    
    local targetPlayer = player or Players.LocalPlayer
    setupInputHandling()
    
    _bodyVelocity = createBodyVelocity(targetPlayer)
    
    _runServiceConnection = RunService.RenderStepped:Connect(function()
        updateMovement(targetPlayer)
    end)
    table.insert(_connections, _runServiceConnection)
    
    if activationKey then
        table.insert(_connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            if input.KeyCode == activationKey then
                M.Toggle(not _isEnabled, targetPlayer)
            end
        end))
    end
end

function M.Stop(player)
    _isEnabled = false
    
    -- Limpiar física
    removeBodyVelocity(player or Players.LocalPlayer)
    
    -- Limpiar todas las conexiones
    for _, connection in ipairs(_connections) do
        if connection.Connected then
            connection:Disconnect()
        end
    end
    
    table.clear(_connections)
    table.clear(_keyPressed)
    
    _runServiceConnection = nil
    _bodyVelocity = nil
    _speed = 50
end

function M.Toggle(state, player)
    local targetPlayer = player or Players.LocalPlayer
    
    if state == nil then
        state = not _isEnabled
    end
    
    _isEnabled = state
    
    if state then
        if not _bodyVelocity then
            _bodyVelocity = createBodyVelocity(targetPlayer)
        end
    else
        removeBodyVelocity(targetPlayer)
        _bodyVelocity = nil
    end
    
    return state
end

function M.IsEnabled()
    return _isEnabled
end

function M.SetSpeed(speed)
    _speed = math.clamp(speed, 0, _maxSpeed)
end

function M.GetSpeed()
    return _speed
end

function M.SetMaxSpeed(maxSpeed)
    _maxSpeed = maxSpeed
end

function M.SetAcceleration(accel)
    _acceleration = accel
end

function M.SetControls(newControls)
    if newControls.forward then _controls.forward = newControls.forward end
    if newControls.backward then _controls.backward = newControls.backward end
    if newControls.left then _controls.left = newControls.left end
    if newControls.right then _controls.right = newControls.right end
    if newControls.up then _controls.up = newControls.up end
    if newControls.down then _controls.down = newControls.down end
end

function M.GetControls()
    return table.clone(_controls)
end

function M.GetState()
    return {
        enabled = _isEnabled,
        speed = _speed,
        maxSpeed = _maxSpeed,
        acceleration = _acceleration,
        bodyVelocity = _bodyVelocity,
        keyPressed = table.clone(_keyPressed)
    }
end

function M.GetVelocity()
    if _bodyVelocity then
        return _bodyVelocity.Velocity
    end
    return Vector3.new(0, 0, 0)
end

return M
