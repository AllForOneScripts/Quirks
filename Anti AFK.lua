local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local Players = game:GetService("Players")

local lastInput = tick()
local antiAfkRunning = false

UserInputService.InputBegan:Connect(function()
    lastInput = tick()
end)

UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        lastInput = tick()
    end
end)

task.spawn(function()
    while task.wait(1) do
        if tick() - lastInput >= 600 and not antiAfkRunning then
            antiAfkRunning = true
            local actionDuration = math.random(10, 60)
            local endTime = tick() + actionDuration
            
            while tick() < endTime do
                VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
                task.wait(0.5)
                VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
                task.wait(0.5)
            end
            
            lastInput = tick()
            antiAfkRunning = false
        end
    end
end)

-- Respaldo de seguridad nativo de Roblox por si el juego fuerza el evento Idled (20 minutos)
Players.LocalPlayer.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    task.wait(1)
    VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
end)
