local M = {}

-- ──────────────────────────────────────────────────────────────────
-- SERVICIOS Y VARIABLES LOCALES
-- ──────────────────────────────────────────────────────────────────
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local _lplr = nil
local _camera = workspace.CurrentCamera
local _conns = {}

-- Teclas por defecto
local _flyKey = Enum.KeyCode.C
local _lockKey = Enum.KeyCode.Z

-- Estados internos
local _isActive = false
local _maxHeight = 99999
local _bg = nil
local _bv = nil
local _flightLoopConn = nil

-- Controles de movimiento
local _ctrl = {f = 0, b = 0, l = 0, r = 0, u = 0, d = 0}

-- Configuración interna del Gravattack
local GA = {
    BASE_SPEED = 60,
    FAST_SPEED = 150,
    SMOOTHNESS = 0.15,
}

local _currentSpeed = GA.BASE_SPEED

-- ──────────────────────────────────────────────────────────────────
-- FUNCIONES INTERNAS DE VUELO
-- ──────────────────────────────────────────────────────────────────
local function enableFlight()
    local char = _lplr.Character
    if not char then return end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChild("Humanoid")
    if not hrp or not hum then return end
    
    _isActive = true
    getgenv().AFO_GRAVATTACKSTATE = true -- Variable global esperada por otros módulos
    
    hum.PlatformStand = true
    
    -- Inicializamos físicas
    _bg = Instance.new("BodyGyro")
    _bg.P = 9e4
    _bg.maxTorque = Vector3.new(9e9, 9e9, 9e9)
    _bg.cframe = hrp.CFrame
    _bg.Parent = hrp
    
    _bv = Instance.new("BodyVelocity")
    _bv.velocity = Vector3.new(0, 0, 0)
    _bv.maxForce = Vector3.new(9e9, 9e9, 9e9)
    _bv.Parent = hrp
    
    -- Bucle de vuelo
    if _flightLoopConn then _flightLoopConn:Disconnect() end
    _flightLoopConn = RunService.RenderStepped:Connect(function()
        if not _isActive or not hrp or not hrp.Parent or not hum or hum.Health <= 0 then
            M.Toggle(false)
            return
        end
        
        local camCF = _camera.CFrame
        local moveDir = Vector3.new()
        
        -- Cálculo de dirección en base a los inputs
        moveDir = moveDir + camCF.LookVector * (_ctrl.f + _ctrl.b)
        moveDir = moveDir + camCF.RightVector * (_ctrl.r + _ctrl.l)
        moveDir = moveDir + camCF.UpVector * (_ctrl.u + _ctrl.d)
        
        if moveDir.Magnitude > 0 then
            moveDir = moveDir.Unit
        end
        
        local targetVel = moveDir * _currentSpeed
        
        -- Límite de altura impuesto por el Lock o configuraciones
        if hrp.Position.Y >= _maxHeight and targetVel.Y > 0 then
            targetVel = Vector3.new(targetVel.X, 0, targetVel.Z)
        end
        
        _bv.velocity = _bv.velocity:Lerp(targetVel, GA.SMOOTHNESS)
        _bg.cframe = camCF
    end)
end

local function disableFlight()
    _isActive = false
    getgenv().AFO_GRAVATTACKSTATE = false
    
    if _flightLoopConn then 
        _flightLoopConn:Disconnect()
        _flightLoopConn = nil 
    end
    
    if _bg then _bg:Destroy(); _bg = nil end
    if _bv then _bv:Destroy(); _bv = nil end
    
    local char = _lplr.Character
    if char then
        local hum = char:FindFirstChild("Humanoid")
        if hum then hum.PlatformStand = false end
    end
    
    -- Resetear controles para evitar movimiento fantasma al reactivar
    _ctrl = {f = 0, b = 0, l = 0, r = 0, u = 0, d = 0}
end

-- ──────────────────────────────────────────────────────────────────
-- API PRINCIPAL (Conecta con All For One Hub)
-- ──────────────────────────────────────────────────────────────────

function M.Start(lplr, keyCode)
    _lplr = lplr or Players.LocalPlayer
    if keyCode then _flyKey = keyCode end
    
    if #_conns > 0 then M.Stop() end
    
    -- Captura de controles
    local c1 = UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe or not _isActive then return end
        if input.KeyCode == Enum.KeyCode.W then _ctrl.f = 1
        elseif input.KeyCode == Enum.KeyCode.S then _ctrl.b = -1
        elseif input.KeyCode == Enum.KeyCode.A then _ctrl.l = -1
        elseif input.KeyCode == Enum.KeyCode.D then _ctrl.r = 1
        elseif input.KeyCode == Enum.KeyCode.Space then _ctrl.u = 1
        elseif input.KeyCode == Enum.KeyCode.LeftControl then _ctrl.d = -1
        elseif input.KeyCode == Enum.KeyCode.LeftShift then _currentSpeed = GA.FAST_SPEED end
    end)
    
    local c2 = UserInputService.InputEnded:Connect(function(input, gpe)
        if gpe or not _isActive then return end
        if input.KeyCode == Enum.KeyCode.W then _ctrl.f = 0
        elseif input.KeyCode == Enum.KeyCode.S then _ctrl.b = 0
        elseif input.KeyCode == Enum.KeyCode.A then _ctrl.l = 0
        elseif input.KeyCode == Enum.KeyCode.D then _ctrl.r = 0
        elseif input.KeyCode == Enum.KeyCode.Space then _ctrl.u = 0
        elseif input.KeyCode == Enum.KeyCode.LeftControl then _ctrl.d = 0
        elseif input.KeyCode == Enum.KeyCode.LeftShift then _currentSpeed = GA.BASE_SPEED end
    end)
    
    table.insert(_conns, c1)
    table.insert(_conns, c2)
end

function M.Stop()
    M.Toggle(false)
    for _, c in ipairs(_conns) do
        if c.Disconnect then c:Disconnect() end
    end
    table.clear(_conns)
end

function M.Toggle(state)
    if state == _isActive then return end
    if state then
        enableFlight()
    else
        disableFlight()
    end
end

-- ──────────────────────────────────────────────────────────────────
-- MÉTODOS DE CONFIGURACIÓN Y HUD
-- ──────────────────────────────────────────────────────────────────

function M.SetKey(keyCode)
    _flyKey = keyCode
end

function M.SetLockKey(keyCode)
    _lockKey = keyCode
end

function M.UpdateMaxHeight(height)
    _maxHeight = height or 99999
end

function M.IsEnabled()
    return _isActive
end

function M.BuildHUD(parentFrame)
    -- Contenedor principal
    local uiStroke = Instance.new("UIStroke", parentFrame)
    uiStroke.Color = Color3.fromRGB(150, 0, 255)
    uiStroke.Thickness = 2
    
    local bg = Instance.new("Frame", parentFrame)
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    bg.BackgroundTransparency = 0.4
    
    local corner = Instance.new("UICorner", bg)
    corner.CornerRadius = UDim.new(0, 8)

    local title = Instance.new("TextLabel", bg)
    title.Size = UDim2.new(1, 0, 0.4, 0)
    title.BackgroundTransparency = 1
    title.Text = "GRAVATTACK SYSTEM"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    
    local status = Instance.new("TextLabel", bg)
    status.Size = UDim2.new(1, 0, 0.6, 0)
    status.Position = UDim2.new(0, 0, 0.4, 0)
    status.BackgroundTransparency = 1
    status.Text = "STANDBY"
    status.TextColor3 = Color3.fromRGB(150, 150, 150)
    status.Font = Enum.Font.Gotham
    status.TextSize = 12

    local function setExpanded(state)
        parentFrame.Visible = state
    end
    
    -- Actualizar HUD en tiempo real
    task.spawn(function()
        while task.wait(0.1) do
            if not parentFrame or not parentFrame.Parent then break end
            if _isActive then
                status.Text = "ACTIVE | SPEED: " .. (_currentSpeed == GA.FAST_SPEED and "FAST" or "NORMAL")
                status.TextColor3 = Color3.fromRGB(0, 255, 100)
                uiStroke.Color = Color3.fromRGB(0, 255, 100)
            else
                status.Text = "STANDBY"
                status.TextColor3 = Color3.fromRGB(150, 150, 150)
                uiStroke.Color = Color3.fromRGB(150, 0, 255)
            end
        end
    end)
    
    return parentFrame, setExpanded
end

return M
