local M = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- ==========================================
-- PARÁMETROS DE DIOS DE LA GRAVEDAD
-- ==========================================
local GRAVEDAD_NORMAL = 196.2
local GRAVEDAD_CERO = 0

local VELOCIDAD_VUELO = 85
local IMPULSO_EXPLOSIVO_Y = 60
local IMPULSO_EXPLOSIVO_XZ = 120

local VELOCIDAD_CAIDA_LENTA = -15
local ACELERACION_CAIDA = 0.75

-- ==========================================
-- VARIABLES DE ESTADO Y REFERENCIAS
-- ==========================================
local _conns = {}
local _isActive = false
local _dropKey = Enum.KeyCode.C

local isHoldingSpace = false
local isHoldingDrop = false
local isFloating = false
local isSlamming = false
local isPlatformActive = false
local holdTimer = 0
local lastDamageTime = 0
local lastSlamEndTime = 0

local character, humanoid, rootPart, animator
local animVuelo, animReSalto, animImpacto, animDespertar, animPlataforma
local platformPart = nil
local platformY = 0

-- ==========================================
-- SISTEMA DE ANIMACIONES
-- ==========================================
local function LoadAnim(id, priority, looped)
    if not animator then return nil end
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
    if animPlataforma and animPlataforma.IsPlaying then animPlataforma:Stop(fadeTime) end
end

-- ==========================================
-- PLATAFORMA INVISIBLE (NUEVA LÓGICA DEL CLAVADO)
-- ==========================================
local function ActivarPlataforma()
    if not rootPart or not humanoid or isPlatformActive then return end

    -- Cancelar vuelo y restaurar gravedad normal
    isFloating = false
    isPlatformActive = true
    workspace.Gravity = GRAVEDAD_NORMAL

    -- Calcular altura de la plataforma justo debajo de los pies
    platformY = rootPart.Position.Y - humanoid.HipHeight - 1.5

    -- Crear la plataforma si no existe, o reutilizarla
    if not platformPart then
        platformPart = Instance.new("Part")
        platformPart.Anchored = true
        platformPart.CanCollide = true
        platformPart.Transparency = 1        -- Totalmente invisible
        platformPart.Size = Vector3.new(25, 1, 25)
        platformPart.Name = "GravPlatform"
        platformPart.Parent = workspace
    end
    platformPart.CanCollide = true
    platformPart.Position = Vector3.new(rootPart.Position.X, platformY, rootPart.Position.Z)

    -- Reducir velocidad vertical para posarse rápido sobre la plataforma
    local vel = rootPart.AssemblyLinearVelocity
    rootPart.AssemblyLinearVelocity = Vector3.new(vel.X, math.min(vel.Y, -10), vel.Z)

    -- Reproducir animación de plataforma
    if animPlataforma then
        animPlataforma:Play(0.1)
    end
end

local function DesactivarPlataforma()
    if not isPlatformActive then return end
    isPlatformActive = false

    if platformPart then
        platformPart.CanCollide = false
        platformPart.Position = Vector3.new(0, -100, 0)  -- Mover fuera de la vista
    end

    if animPlataforma and animPlataforma.IsPlaying then
        animPlataforma:Stop(0.2)
    end
end

-- ==========================================
-- TELETRANSPORTE OFENSIVO (SLAM) – ya no se usa con Ctrl
-- ==========================================
local function AplastarContraElSuelo()
    if isSlamming or not rootPart or not _isActive then return end
    
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
                local humEnemigo = otroJugador.Character:FindFirstChild("Humanoid")
                
                if rootEnemigo and humEnemigo and humEnemigo.Health > 0 then
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
            if animImpacto then animImpacto:Play(0.1) end
            
            local tiempoAgarre = 0.2
            local t = 0
            local agarreConn
            
            agarreConn = RunService.Heartbeat:Connect(function(dt)
                if not _isActive then
                    if agarreConn then agarreConn:Disconnect() end
                    return
                end
                
                t = t + dt
                if t >= tiempoAgarre or not objetivo or not objetivo.Parent then
                    agarreConn:Disconnect()
                    isSlamming = false
                    lastSlamEndTime = tick()
                    DetenerAnimacionesCustom(0.2)
                else
                    local alturaAgarre = (objetivo.Size.Y / 2) + 1.5
                    rootPart.CFrame = CFrame.new(objetivo.Position + Vector3.new(0, alturaAgarre, 0))
                    rootPart.AssemblyLinearVelocity = Vector3.zero
                end
            end)
            table.insert(_conns, agarreConn)
        else
            local alturaPiernas = humanoid.HipHeight + (rootPart.Size.Y / 2)
            rootPart.CFrame = CFrame.new(impactoBase + Vector3.new(0, alturaPiernas, 0))
            rootPart.AssemblyLinearVelocity = Vector3.zero
            
            task.delay(0.1, function()
                if not _isActive then return end
                isSlamming = false
                lastSlamEndTime = tick()
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
-- INICIALIZACIÓN DE PERSONAJE
-- ==========================================
local function SetupCharacter(newCharacter)
    character = newCharacter
    humanoid = character:WaitForChild("Humanoid", 3)
    rootPart = character:WaitForChild("HumanoidRootPart", 3)
    
    if not humanoid or not rootPart then return end
    
    animator = humanoid:WaitForChild("Animator", 3)

    if animator then
        animVuelo = LoadAnim("rbxassetid://85623478299098", Enum.AnimationPriority.Action2, true)
        animReSalto = LoadAnim("rbxassetid://75312251819975", Enum.AnimationPriority.Action3, false)
        animImpacto = LoadAnim("rbxassetid://127236244922151", Enum.AnimationPriority.Action4, false)
        animDespertar = LoadAnim("rbxassetid://83644153292302", Enum.AnimationPriority.Action4, false)
        -- Nueva animación para la plataforma
        animPlataforma = LoadAnim("rbxassetid://75699931064837", Enum.AnimationPriority.Action3, true)
    end

    isFloating = false
    isSlamming = false
    isPlatformActive = false
    isHoldingSpace = false
    isHoldingDrop = false
    holdTimer = 0
    workspace.Gravity = GRAVEDAD_NORMAL

    local lastHealth = humanoid.Health
    local healthConn = humanoid.HealthChanged:Connect(function(health)
        if health < lastHealth then
            lastDamageTime = tick()
        end
        lastHealth = health
    end)
    table.insert(_conns, healthConn)
end

-- ==========================================
-- API PRINCIPAL (MÓDULO)
-- ==========================================

function M.Start()
    if _isActive then return end
    _isActive = true
    
    GRAVEDAD_NORMAL = workspace.Gravity
    
    table.clear(_conns)
    isHoldingSpace = false
    isHoldingDrop = false
    isFloating = false
    isSlamming = false
    isPlatformActive = false
    
    if player.Character then SetupCharacter(player.Character) end
    
    local charAddedConn = player.CharacterAdded:Connect(function(newChar)
        if _isActive then SetupCharacter(newChar) end
    end)
    table.insert(_conns, charAddedConn)

    -- INPUTS
    local inputBeganConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed or not humanoid or not rootPart then return end

        if input.KeyCode == Enum.KeyCode.Space then
            isHoldingSpace = true
            
            if isFloating then
                if animReSalto then
                    animReSalto:Play(0.1)
                    animReSalto:AdjustSpeed(2)
                end
                local velActual = rootPart.AssemblyLinearVelocity
                rootPart.AssemblyLinearVelocity = Vector3.new(velActual.X, IMPULSO_EXPLOSIVO_Y, velActual.Z)
            end
            
        elseif input.KeyCode == _dropKey then
            isHoldingDrop = true
            
        elseif input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl then
            -- REEMPLAZO: en lugar del slam, activar plataforma si estás en el aire
            local state = humanoid:GetState()
            if (state == Enum.HumanoidStateType.Jumping or state == Enum.HumanoidStateType.Freefall or isFloating) then
                ActivarPlataforma()
            end
        end
    end)
    table.insert(_conns, inputBeganConn)

    local inputEndedConn = UserInputService.InputEnded:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.Space then
            isHoldingSpace = false
        elseif input.KeyCode == _dropKey then
            isHoldingDrop = false
        elseif input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl then
            -- Al soltar Ctrl, se desactiva la plataforma
            DesactivarPlataforma()
        end
    end)
    table.insert(_conns, inputEndedConn)

    -- BUCLE PRINCIPAL
    local renderConn = RunService.RenderStepped:Connect(function(dt)
        if not _isActive or not humanoid or not rootPart or not humanoid.Parent then return end

        -- Mientras la plataforma está activa, solo actualizamos su posición (horizontal)
        if isPlatformActive then
            if platformPart then
                platformPart.Position = Vector3.new(rootPart.Position.X, platformY, rootPart.Position.Z)
            end
            return
        end

        if isSlamming then return end

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
                
                local tiempoRequerido = 0.5
                if tick() - lastDamageTime <= 3 then
                    tiempoRequerido = 0.15
                elseif tick() - lastSlamEndTime <= 1.5 then
                    tiempoRequerido = 0.3
                end
                
                if holdTimer > tiempoRequerido then
                    isFloating = true
                    
                    if tick() - lastDamageTime <= 3 then
                        if animDespertar then animDespertar:Play(0.1) end
                        task.delay(0.73, function()
                            if _isActive and isFloating and animDespertar and animDespertar.IsPlaying then
                                animDespertar:Stop(0.3)
                                if animVuelo then animVuelo:Play(0.3) end
                            end
                        end)
                    else
                        if animVuelo then animVuelo:Play(0.3) end
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
            
            if isHoldingDrop then
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
    table.insert(_conns, renderConn)
end

function M.Stop()
    if not _isActive then return end
    _isActive = false
    
    -- Asegurarse de desactivar la plataforma
    DesactivarPlataforma()
    
    for _, c in ipairs(_conns) do
        if c.Disconnect then c:Disconnect() end
    end
    table.clear(_conns)
    
    DetenerAnimacionesCustom(0)
    workspace.Gravity = GRAVEDAD_NORMAL
    
    isHoldingSpace = false
    isHoldingDrop = false
    isFloating = false
    isSlamming = false
    isPlatformActive = false
    holdTimer = 0
    
    if rootPart and character and character.Parent then
        local velActual = rootPart.AssemblyLinearVelocity
        rootPart.AssemblyLinearVelocity = Vector3.new(velActual.X, math.min(velActual.Y, 0), velActual.Z)
    end
end

function M.SetDropKeybind(keyCode)
    if typeof(keyCode) == "EnumItem" then
        _dropKey = keyCode
        isHoldingDrop = false
    end
end

function M.IsActive()
    return _isActive
end

return M
