local M = {}

local _isActive = false
local _antiAfkEnabled = true
local _connections = {}

function M.Start()
    if _isActive then return end
    _isActive = true

    local UserInputService = game:GetService("UserInputService")
    local VirtualInputManager = game:GetService("VirtualInputManager")
    local Players = game:GetService("Players")

    local lastInput = tick()
    local antiAfkRunning = false

    -- Función que hace el "baile" rápido de A y D
    local function doAntiAfkDance()
        if not _antiAfkEnabled then return end
        
        -- Simular presionar la tecla 'A'
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.A, false, game)
        task.wait(0.1) -- Espera un instante para que el juego lo registre
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.A, false, game) -- Soltar 'A'
        
        task.wait(0.1)
        
        -- Simular presionar la tecla 'D'
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.D, false, game)
        task.wait(0.1)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.D, false, game) -- Soltar 'D'
    end

    -- Monitorear interacciones para reiniciar el temporizador si estás jugando activamente
    table.insert(_connections, UserInputService.InputBegan:Connect(function()
        lastInput = tick()
    end))

    table.insert(_connections, UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            lastInput = tick()
        end
    end))

    -- Respaldo de seguridad nativo de Roblox (Evento Idled)
    -- Esto se dispara justo antes de que Roblox te vaya a expulsar por estar 20 minutos inactivo.
    table.insert(_connections, Players.LocalPlayer.Idled:Connect(function()
        doAntiAfkDance()
    end))

    -- Bucle principal del Anti-AFK (Se ejecuta cada 10 minutos sin actividad)
    task.spawn(function()
        while _isActive do
            if _antiAfkEnabled then
                if tick() - lastInput >= 600 and not antiAfkRunning then
                    antiAfkRunning = true
                    
                    -- Ejecutar el movimiento A y D
                    doAntiAfkDance()
                    
                    -- Reiniciar contadores
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
