local M = {}

local _enabled = false
local _inputConn = nil

-- Referencias a los servicios enviados por el Hub
local _Keys, _lplr, _Players, _RunService, _UIS, _camera

-- Función para buscar el objetivo más cercano al centro de la pantalla
local function getClosestTarget()
    local closestTarget = nil
    local shortestDistance = math.huge
    local mousePos = _UIS:GetMouseLocation()

    for _, player in ipairs(_Players:GetPlayers()) do
        if player ~= _lplr and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Humanoid") then
            if player.Character.Humanoid.Health > 0 then
                -- Proyección a 2D para comprobar si está en pantalla
                local pos, onScreen = _camera:WorldToViewportPoint(player.Character.HumanoidRootPart.Position)
                
                if onScreen then
                    local distance = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
                    if distance < shortestDistance then
                        shortestDistance = distance
                        closestTarget = player.Character.HumanoidRootPart
                    end
                end
            end
        end
    end
    return closestTarget
end

-- El Hub llama a esta función pasándole todos los servicios necesarios
function M.Setup(Keys, lplr, Players, RunService, UserInputService, camera)
    _Keys = Keys
    _lplr = lplr
    _Players = Players
    _RunService = RunService
    _UIS = UserInputService
    _camera = camera

    -- Limpiamos cualquier conexión previa por si el usuario lo reactiva
    M.Stop()
    _enabled = true

    -- Detectar cuando se presionan las teclas de habilidad (1, 2, 3, 4)
    _inputConn = _UIS.InputBegan:Connect(function(input, gpe)
        if gpe or not _enabled then return end

        local k = input.KeyCode
        if k == Enum.KeyCode.One or k == Enum.KeyCode.Two or k == Enum.KeyCode.Three or k == Enum.KeyCode.Four then
            local targetPart = getClosestTarget()
            
            if targetPart then
                -- Auto-facing: Forzamos el CFrame de la cámara para mirar al objetivo
                _camera.CFrame = CFrame.new(_camera.CFrame.Position, targetPart.Position)
            end
        end
    end)
end

-- El Hub llama a esta función desde el Toggle de la UI
function M.SetEnabled(value)
    _enabled = value
end

-- El Hub llama a esta función para limpiar la memoria y detener el módulo
function M.Stop()
    _enabled = false
    if _inputConn then
        _inputConn:Disconnect()
        _inputConn = nil
    end
end

return M
