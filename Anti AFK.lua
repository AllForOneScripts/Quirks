local M = {}

local _isActive = false
local _antiAfkEnabled = true
local _connections = {}
local _afkGui = nil -- Guardaremos la UI aquí para poder borrarla si se detiene el script

function M.Start()
    if _isActive then return end
    _isActive = true

    local UserInputService = game:GetService("UserInputService")
    local VirtualUser = game:GetService("VirtualUser")
    local Players = game:GetService("Players")
    local TweenService = game:GetService("TweenService")
    local CoreGui = game:GetService("CoreGui")
    
    local lplr = Players.LocalPlayer
    local lastInput = os.clock()
    local antiAfkRunning = false

    -- Función para mostrar el cartel de AFK en pantalla
    local function showAfkMessage()
        pcall(function()
            if _afkGui then _afkGui:Destroy() end
            
            -- Buscamos un lugar seguro donde poner la UI (CoreGui si es posible, si no PlayerGui)
            local guiParent = pcall(function() return CoreGui.Name end) and CoreGui or lplr:WaitForChild("PlayerGui")
            
            _afkGui = Instance.new("ScreenGui")
            _afkGui.Name = "AntiAfkAlert"
            _afkGui.Parent = guiParent

            local textLabel = Instance.new("TextLabel")
            textLabel.Size = UDim2.new(0, 300, 0, 100)
            textLabel.Position = UDim2.new(0.5, -150, 0.8, 0) -- Abajo al centro
            textLabel.BackgroundTransparency = 0.5
            textLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            textLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
            textLabel.TextScaled = true
            textLabel.Font = Enum.Font.GothamBold
            textLabel.Text = "AFK ACTIVO"
            textLabel.Parent = _afkGui

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 15)
            corner.Parent = textLabel

            -- Animación para que desaparezca suavemente
            task.delay(2, function()
                if textLabel then
                    local tweenInfo = TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                    local tween = TweenService:Create(textLabel, tweenInfo, {TextTransparency = 1, BackgroundTransparency = 1})
                    tween:Play()
                    tween.Completed:Connect(function()
                        if _afkGui then _afkGui:Destroy() _afkGui = nil end
                    end)
                end
            end)
        end)
    end

    -- Función que decide aleatoriamente qué hacer (Saltar o Clic)
    local function doWildAntiAfk()
        if not _antiAfkEnabled then return end
        
        showAfkMessage()
        
        local action = math.random(1, 2)
        
        if action == 1 then
            -- Acción 1: Forzar Salto
            local char = lplr.Character
            if char and char:FindFirstChild("Humanoid") then
                char.Humanoid.Jump = true
                print("[Anti-AFK]: Personaje saltó.")
            end
        else
            -- Acción 2: Simular un clic de ratón en el centro de la pantalla
            -- VirtualUser es la forma más efectiva de evadir el kick por inactividad
            VirtualUser:CaptureController()
            VirtualUser:ClickButton1(Vector2.new(0, 0))
            print("[Anti-AFK]: Clic de ratón simulado.")
        end
    end

    -- Monitorear interacciones (Teclas y clics)
    table.insert(_connections, UserInputService.InputBegan:Connect(function()
        lastInput = os.clock()
    end))

    -- Monitorear movimiento de cámara, mouse y pantalla táctil
    table.insert(_connections, UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            lastInput = os.clock()
        end
    end))

    -- EL SALVAVIDAS NATIVO: Si todo falla y Roblox está a punto de echarte (20 mins), esto se activa
    table.insert(_connections, lplr.Idled:Connect(function()
        if _antiAfkEnabled then
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new(0, 0)) -- Clic derecho simulado
            print("[Anti-AFK]: Alerta Idled de Roblox prevenida.")
        end
    end))

    -- Bucle principal del Anti-AFK (5 minutos = 300 segundos)
    task.spawn(function()
        while _isActive do
            if _antiAfkEnabled then
                -- os.clock() es más preciso y moderno que tick()
                if os.clock() - lastInput >= 300 and not antiAfkRunning then
                    antiAfkRunning = true
                    
                    doWildAntiAfk()
                    
                    lastInput = os.clock()
                    antiAfkRunning = false
                end
            end
            task.wait(1)
        end
    end)

    print("[Anti-AFK]: Módulo Salvaje Inicializado.")
end

function M.Stop()
    _isActive = false
    
    for _, connection in ipairs(_connections) do
        if connection.Connected then
            connection:Disconnect()
        end
    end
    table.clear(_connections)
    
    if _afkGui then
        _afkGui:Destroy()
        _afkGui = nil
    end

    print("[Anti-AFK]: Módulo detenido.")
end

function M.SetAntiAfkEnabled(state)
    _antiAfkEnabled = state
end

return M
