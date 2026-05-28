local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local targetPlaceId = 13739618407
local targetSoundId = "rbxassetid://9066167010"

local yaTeletransportado = false

-- Función de teletransporte
local function teletransportar()
    if yaTeletransportado then return end
    yaTeletransportado = true
    
    print("Sonido detectado. Teletransportando...")
    TeleportService:Teleport(targetPlaceId, player)
end

-- Revisa el sonido y conecta los eventos
local function verificarSonido(instance)
    if instance:IsA("Sound") then
        if instance.SoundId == targetSoundId or instance.SoundId:match("%d+") == "9066167010" then
            
            if instance.IsPlaying then
                teletransportar()
            end
            
            instance:GetPropertyChangedSignal("IsPlaying"):Connect(function()
                if instance.IsPlaying then
                    teletransportar()
                end
            end)
            
            instance.Played:Connect(teletransportar)
        end
    end
end

-- Función para escanear todo el juego de golpe
local function escanearTodo()
    for _, descendant in ipairs(workspace:GetDescendants()) do
        verificarSonido(descendant)
    end
    for _, descendant in ipairs(SoundService:GetDescendants()) do
        verificarSonido(descendant)
    end
    for _, descendant in ipairs(player:GetDescendants()) do
        verificarSonido(descendant)
    end
end

-- Ejecución inicial
escanearTodo()

-- Escuchar nuevos elementos en cualquier parte clave del juego
workspace.DescendantAdded:Connect(verificarSonido)
SoundService.DescendantAdded:Connect(verificarSonido)
player.DescendantAdded:Connect(verificarSonido)

-- SEGURIDAD EXTRAS: Si el personaje muere, volvemos a escanear todo 
-- por si el sonido se movió o se recreó en el nuevo cuerpo.
player.CharacterAdded:Connect(function(character)
    task.wait(0.5) -- Un microsegundo para dejar que cargue el nuevo cuerpo
    escanearTodo()
    
    -- También escuchamos lo que aparezca dentro de tu nuevo personaje
    character.DescendantAdded:Connect(verificarSonido)
end)
