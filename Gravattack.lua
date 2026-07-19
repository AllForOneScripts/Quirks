local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer

-- ==========================================
-- PARÁMETROS DE DIOS DE LA GRAVEDAD
-- ==========================================
local GRAVEDAD_NORMAL = workspace.Gravity
local GRAVEDAD_CERO = 0

local VELOCIDAD_VUELO = 85        
local IMPULSO_EXPLOSIVO_Y = 60    
local IMPULSO_EXPLOSIVO_XZ = 120  

local VELOCIDAD_CAIDA_LENTA = -15 
local ACELERACION_CAIDA = 0.75    

-- ==========================================
-- VARIABLES DE ESTADO Y REFERENCIAS
-- ==========================================
local isHoldingSpace = false
local isHoldingC = false
local isFloating = false
local isSlamming = false
local holdTimer = 0
local lastDamageTime = 0
local lastSlamEndTime = 0 

-- Variables que se renuevan al revivir
local character, humanoid, rootPart, animator
local animVuelo, animReSalto, animImpacto, animDespertar
local healthConnection

-- ==========================================
-- SISTEMA DE ANIMACIONES
-- ==========================================
local function LoadAnim(id, priority, looped)
    local anim = Instance.new("Animation")
    anim.AnimationId = id
    local track = animator:LoadAnimation(anim)
    track.Priority = priority
    track.Looped = looped
    return track
end

local function DetenerAnimacionesCustom(fadeTime)
    fadeTime = fadeTime or 0.2
    if animVuelo and animVuelo.IsPlaying then animVuelo:Stop(fadeTime) end
    if animReSalto and animReSalto.IsPlaying then animReSalto:Stop(fadeTime) end
    if animImpacto and animImpacto.IsPlaying then animImpacto:Stop(fadeTime) end
    if animDespertar and animDespertar.IsPlaying then animDespertar:Stop(fadeTime) end
end

-- ==========================================
-- INICIALIZACIÓN DE PERSONAJE
-- ==========================================
local function OnCharacterAdded(newCharacter)
    character = newCharacter
    humanoid = character:WaitForChild("Humanoid")
    rootPart = character:WaitForChild("HumanoidRootPart")
    animator = humanoid:WaitForChild("Animator")

    animVuelo = LoadAnim("rbxassetid://85623478299098", Enum.AnimationPriority.Action2, true)
    animReSalto = LoadAnim("rbxassetid://75312251819975", Enum.AnimationPriority.Action3, false)
    animImpacto = LoadAnim("rbxassetid://127236244922151", Enum.AnimationPriority.Action4, false)
    animDespertar = LoadAnim("rbxassetid://83644153292302", Enum.AnimationPriority.Action4, false)

    isFloating = false
    isSlamming = false
    isHoldingSpace = false
    isHoldingC = false
    holdTimer = 0
    workspace.Gravity = GRAVEDAD_NORMAL

    if healthConnection then healthConnection:Disconnect() end
    local lastHealth = humanoid.Health
    healthConnection = humanoid.HealthChanged:Connect(function(health)
        if health < lastHealth then
            lastDamageTime = tick()
        end
        lastHealth = health
    end)
end

player.CharacterAdded:Connect(OnCharacterAdded)
if player.Character then
    OnCharacterAdded(player.Character)
end

-- ==========================================
-- TELETRANSPORTE OFENSIVO (SLAM)
-- ==========================================
local function AplastarContraElSuelo()
    if isSlamming or not rootPart then return end
    
    local rayOrigin = rootPart.Position
    local rayDirection = Vector3.new(0, -2000, 0) 
    
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {character} 
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    
    local rayResult = workspace:Raycast(rayOrigin, rayDirection, rayParams)
    
    if rayResult then
        isSlamming = true
        DetenerAnimacionesCustom(0.1) 
        
        local impactoBase = rayResult.Position
        local objetivo = nil
        local menorDistancia = 30 
        
        for _, otroJugador in ipairs(Players:GetPlayers()) do
            if otroJugador ~= player and otroJugador.Character then
                local rootEnemigo = otroJugador.Character:FindFirstChild("HumanoidRootPart")
                if rootEnemigo then
                    local distXZ = (Vector3.new(impactoBase.X, 0, impactoBase.Z) - Vector3.new(rootEnemigo.Position.X, 0, rootEnemigo.Position.Z)).Magnitude
                    local difY = math.abs(impactoBase.Y - rootEnemigo.Position.Y)
                    if distXZ <= menorDistancia and difY <= 50 then
                        objetivo = rootEnemigo
                        menorDistancia = distXZ
                    end
                end
            end
        end
        
        if objetivo then
            animImpacto:Play(0.1) 
            
            local tiempoAgarre = 0.2
            local t = 0
            local agarreConn
            
            agarreConn = RunService.Heartbeat:Connect(function(dt)
                t = t + dt
                if t >= tiempoAgarre or not objetivo or not objetivo.Parent then
                    agarreConn:Disconnect()
                    isSlamming = false
                    lastSlamEndTime = tick() -- Se registra para el combo de 1.5s
                    DetenerAnimacionesCustom(0.2)
                else
                    local alturaAgarre = (objetivo.Size.Y / 2) + 1.5
                    rootPart.CFrame = CFrame.new(objetivo.Position + Vector3.new(0, alturaAgarre, 0))
                    rootPart.AssemblyLinearVelocity = Vector3.zero 
                end
            end)
        else
            local alturaPiernas = humanoid.HipHeight + (rootPart.Size.Y / 2)
            rootPart.CFrame = CFrame.new(impactoBase + Vector3.new(0, alturaPiernas, 0))
            rootPart.AssemblyLinearVelocity = Vector3.zero 
            
            task.delay(0.1, function()
                isSlamming = false
                lastSlamEndTime = tick() -- Se registra para el combo de 1.5s
                DetenerAnimacionesCustom(0.2)
            end)
        end
        
        if isFloating then
            isFloating = false
        end
        holdTimer = 0
        workspace.Gravity = GRAVEDAD_NORMAL
    end
end

-- ==========================================
-- BUCLE PRINCIPAL (RUNSERVICE)
-- ==========================================
RunService.RenderStepped:Connect(function(dt)
    if isSlamming or not humanoid or not rootPart then return end

    local state = humanoid:GetState()
    local inAir = (state == Enum.HumanoidStateType.Jumping or state == Enum.HumanoidStateType.Freefall)

    if not inAir then
        if isFloating then
            isFloating = false
            DetenerAnimacionesCustom(0.3)
        end
        workspace.Gravity = GRAVEDAD_NORMAL
        
        if not isHoldingSpace then
            holdTimer = 0
        end
    end

    if isHoldingSpace then
        if not isFloating then
            holdTimer = holdTimer + dt
            
            -- LÓGICA DINÁMICA DE TIEMPOS DE CARGA
            local tiempoRequerido = 0.5 -- Tiempo base
            
            if tick() - lastDamageTime <= 3 then
                tiempoRequerido = 0.15 -- Recibió daño reciente, activación casi instantánea
            elseif tick() - lastSlamEndTime <= 1.5 then
                tiempoRequerido = 0.3 -- Ventana de combo de 1.5s tras un Slam
            end
            
            if holdTimer > tiempoRequerido then
                isFloating = true
                
                if tick() - lastDamageTime <= 3 then
                    animDespertar:Play(0.1)
                    task.delay(0.73, function()
                        if isFloating and animDespertar.IsPlaying then
                            animDespertar:Stop(0.3)
                            animVuelo:Play(0.3)
                        end
                    end)
                else
                    animVuelo:Play(0.3)
                end
                
                humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
                local moveDir = humanoid.MoveDirection
                rootPart.AssemblyLinearVelocity = Vector3.new(
                    moveDir.X * IMPULSO_EXPLOSIVO_XZ, 
                    IMPULSO_EXPLOSIVO_Y, 
                    moveDir.Z * IMPULSO_EXPLOSIVO_XZ
                )
            end
        end
    else
        if not isFloating then
            holdTimer = 0
        end
    end
    
    if isFloating then
        workspace.Gravity = GRAVEDAD_CERO
        local moveDir = humanoid.MoveDirection
        local velActual = rootPart.AssemblyLinearVelocity
        local velY = velActual.Y
        
        if isHoldingC then
            velY = -0.1
        elseif isHoldingSpace then
            if velY < -2 then velY = -2 end
        else
            velY = velY - ACELERACION_CAIDA
            if velY < VELOCIDAD_CAIDA_LENTA then velY = VELOCIDAD_CAIDA_LENTA end
        end
        
        local targetVelXZ
        if moveDir.Magnitude > 0 then
            targetVelXZ = moveDir * VELOCIDAD_VUELO
        else
            targetVelXZ = Vector3.new(velActual.X * 0.9, 0, velActual.Z * 0.9)
        end
        
        rootPart.AssemblyLinearVelocity = Vector3.new(targetVelXZ.X, velY, targetVelXZ.Z)
    end
end)

-- ==========================================
-- INPUTS
-- ==========================================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed or not humanoid or not rootPart then return end

    if input.KeyCode == Enum.KeyCode.Space then
        isHoldingSpace = true
        
        if isFloating then
            animReSalto:Play(0.1)
            animReSalto:AdjustSpeed(2) 
            
            local velActual = rootPart.AssemblyLinearVelocity
            rootPart.AssemblyLinearVelocity = Vector3.new(velActual.X, IMPULSO_EXPLOSIVO_Y, velActual.Z)
        end
        
    elseif input.KeyCode == Enum.KeyCode.C then
        isHoldingC = true
        
    elseif input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl then
        local state = humanoid:GetState()
        if state == Enum.HumanoidStateType.Jumping or state == Enum.HumanoidStateType.Freefall or isFloating then
            AplastarContraElSuelo()
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.Space then
        isHoldingSpace = false
    elseif input.KeyCode == Enum.KeyCode.C then
        isHoldingC = false
    end
end)
