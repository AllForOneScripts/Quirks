local M = {}

-- ──────────────────────────────────────────────────────────────────
-- SERVICIOS Y VARIABLES LOCALES
-- ──────────────────────────────────────────────────────────────────
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local _lplr = nil
local _isActive = false
local _steppedConn = nil

-- ──────────────────────────────────────────────────────────────────
-- FUNCIONES INTERNAS DE ANTI-FLING
-- ──────────────────────────────────────────────────────────────────
local function enableAntiFling()
    _isActive = true
    getgenv().AFO_ANTIFLINGSTATE = true -- Variable global para el Hub

    -- Limpiamos cualquier conexión previa por seguridad
    if _steppedConn then 
        _steppedConn:Disconnect() 
        _steppedConn = nil 
    end

    -- Bucle centralizado: desactiva colisiones de otros jugadores antes de cada frame de físicas
    _steppedConn = RunService.Stepped:Connect(function()
        if not _isActive then return end
        
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= _lplr and player.Character then
                for _, part in ipairs(player.Character:GetChildren()) do
                    if part:IsA("BasePart") and part.CanCollide then
                        part.CanCollide = false
                    end
                end
            end
        end
    end)
end

local function disableAntiFling()
    _isActive = false
    getgenv().AFO_ANTIFLINGSTATE = false

    if _steppedConn then
        _steppedConn:Disconnect()
        _steppedConn = nil
    end
end

-- ──────────────────────────────────────────────────────────────────
-- API PRINCIPAL (Conecta con All For One Hub)
-- ──────────────────────────────────────────────────────────────────

function M.Start(lplr)
    _lplr = lplr or Players.LocalPlayer
    -- Inicializa variables base pero se mantiene apagado hasta llamar a Toggle
    if _steppedConn then M.Stop() end
end

function M.Stop()
    M.Toggle(false)
end

function M.Toggle(state)
    if state == _isActive then return end
    if state then
        enableAntiFling()
    else
        disableAntiFling()
    end
end

-- ──────────────────────────────────────────────────────────────────
-- MÉTODOS DE CONFIGURACIÓN Y HUD
-- ──────────────────────────────────────────────────────────────────

function M.IsEnabled()
    return _isActive
end

function M.BuildHUD(parentFrame)
    -- Contenedor principal
    local uiStroke = Instance.new("UIStroke", parentFrame)
    uiStroke.Color = Color3.fromRGB(255, 80, 80) -- Color por defecto (Standby)
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
    title.Text = "ANTI-FLING SYSTEM"
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
                status.Text = "ACTIVE | NO COLLISIONS"
                status.TextColor3 = Color3.fromRGB(0, 255, 140)
                uiStroke.Color = Color3.fromRGB(0, 255, 140)
            else
                status.Text = "STANDBY"
                status.TextColor3 = Color3.fromRGB(150, 150, 150)
                uiStroke.Color = Color3.fromRGB(255, 80, 80)
            end
        end
    end)
    
    return parentFrame, setExpanded
end

return M
