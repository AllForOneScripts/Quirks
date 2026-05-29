local M = {}

local _isActive = false
local _antiAfkEnabled = true
local _connections = {}

function M.Start()
    if _isActive then return end
    _isActive = true

    local UserInputService = game:GetService("UserInputService")
    local VirtualUser = game:GetService("VirtualUser")
    local Players = game:GetService("Players")

    local lastInput = tick()
    local antiAfkRunning = false

    -- Monitorear interacciones para reiniciar el temporizador
    table.insert(_connections, UserInputService.InputBegan:Connect(function()
        lastInput = tick()
    end))

    table.insert(_connections, UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            lastInput = tick()
        end
    end))

    -- Respaldo de seguridad nativo de Roblox (Idled event - 20 minutos)
    table.insert(_connections, Players.LocalPlayer.Idled:Connect(function()
        if not _antiAfkEnabled then return end
        VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    end))

    -- Bucle principal del Anti-AFK (10 minutos)
    task.spawn(function()
        while _isActive do
            if _antiAfkEnabled then
                if tick() - lastInput >= 600 and not antiAfkRunning then
                    antiAfkRunning = true
                    local actionDuration = math.random(10, 60)
                    local endTime = tick() + actionDuration
                    
                    -- Continuar la acción hasta que acabe el tiempo, pero abortar si se detiene el módulo
                    while tick() < endTime and _isActive and _antiAfkEnabled do
                        VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
                        task.wait(0.5)
                        VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
                        task.wait(0.5)
                    end
                    
                    lastInput = tick()
                    antiAfkRunning = false
                end
            end
            task.wait(1)
        end
    end)
end

function M.Stop()
    _isActive = false
    
    -- Limpiar todas las conexiones para evitar fugas de memoria
    for _, connection in ipairs(_connections) do
        if connection.Connected then
            connection:Disconnect()
        end
    end
    table.clear(_connections)
end

function M.SetAntiAfkEnabled(state)
    _antiAfkEnabled = state
end

return M
