--[[
╔══════════════════════════════════════════════════════════════════╗
║                 GRAVATTACK SYSTEM (Módulo aislado)               ║
║  Sistema de control de gravedad, vuelo, animaciones y            ║
║  teletransporte ofensivo (Slam) estructurado de forma modular.   ║
╚══════════════════════════════════════════════════════════════════╝

  ÍNDICE
  ──────
  [1] SERVICIOS Y UTILIDADES
  [2] PARÁMETROS Y CONSTANTES
  [3] ESTADO INTERNO (S)
  [4] SISTEMA DE ANIMACIONES
  [5] INICIALIZACIÓN DE PERSONAJE
  [6] TELETRANSPORTE OFENSIVO (SLAM)
  [7] BUCLE PRINCIPAL (RUNSERVICE)
  [8] MANEJO DE INPUTS
  [9] API PÚBLICA (M)
--]]

-- ──────────────────────────────────────────────────────────────────
-- [1]  SERVICIOS Y UTILIDADES
-- ──────────────────────────────────────────────────────────────────
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local Players          = game:GetService("Players")

-- ──────────────────────────────────────────────────────────────────
-- [2]  PARÁMETROS Y CONSTANTES
-- ──────────────────────────────────────────────────────────────────
local CONST = {
    GRAVEDAD_NORMAL      = workspace.Gravity,
    GRAVEDAD_CERO        = 0,
    VELOCIDAD_VUELO      = 85,
    IMPULSO_EXPLOSIVO_Y  = 60,
    IMPULSO_EXPLOSIVO_XZ = 120,
    VELOCIDAD_CAIDA_LENTA = -15,
    ACELERACION_CAIDA    = 0.75,
}

local ANIM_IDS = {
    Vuelo     = "rbxassetid://85623478299098",
    ReSalto   = "rbxassetid://75312251819975",
    Impacto   = "rbxassetid://127236244922151",
    Despertar = "rbxassetid://83644153292302"
}

-- ──────────────────────────────────────────────────────────────────
-- [3]  ESTADO INTERNO (S)
-- ──────────────────────────────────────────────────────────────────
local S = {
    player          = nil,
    character       = nil,
    humanoid        = nil,
    rootPart        = nil,
    animator        = nil,

    isHoldingSpace  = false,
    isHoldingC      = false,
    isFloating      = false,
    isSlamming      = false,
    holdTimer       = 0,
    lastDamageTime  = 0,
    lastSlamEndTime = 0,

    anims = {
        vuelo     = nil,
        reSalto   = nil,
        impacto   = nil,
        despertar = nil
    },

    -- Conexiones
    connections = {
        charAdded   = nil,
        health      = nil,
        render      = nil,
        inputBegan  = nil,
        inputEnded  = nil
    }
}

-- ──────────────────────────────────────────────────────────────────
-- [4]  SISTEMA DE ANIMACIONES
-- ──────────────────────────────────────────────────────────────────
local function LoadAnim(id, priority, looped)
    if not S.animator then return nil end
    local anim = Instance.new("Animation")
    anim.AnimationId = id
    local track = S.animator:LoadAnimation(anim)
    track.Priority = priority
    track.Looped = looped
    return track
end

local function DetenerAnimacionesCustom(fadeTime)
    fadeTime = fadeTime or 0.2
    if S.anims.vuelo and S.anims.vuelo.IsPlaying then S.anims.vuelo:Stop(fadeTime) end
    if S.anims.reSalto and S.anims.reSalto.IsPlaying then S.anims.reSalto:Stop(fadeTime) end
    if S.anims.impacto and S.anims.impacto.IsPlaying then S.anims.impacto:Stop(fadeTime) end
    if S.anims.despertar and S.anims.despertar.IsPlaying then S.anims.despertar:Stop(fadeTime) end
end

-- ──────────────────────────────────────────────────────────────────
-- [5]  INICIALIZACIÓN DE PERSONAJE
-- ──────────────────────────────────────────────────────────────────
local function OnCharacterAdded(newCharacter)
    S.character = newCharacter
    S.humanoid  = S.character:WaitForChild("Humanoid")
    S.rootPart  = S.character:WaitForChild("HumanoidRootPart")
    S.animator  = S.humanoid:WaitForChild("Animator")

    S.anims.vuelo     = LoadAnim(ANIM_IDS.Vuelo, Enum.AnimationPriority.Action2, true)
    S.anims.reSalto   = LoadAnim(ANIM_IDS.ReSalto, Enum.AnimationPriority.Action3, false)
    S.anims.impacto   = LoadAnim(ANIM_IDS.Impacto, Enum.AnimationPriority.Action4, false)
    S.anims.despertar = LoadAnim(ANIM_IDS.Despertar, Enum.AnimationPriority.Action4, false)

    S.isFloating     = false
    S.isSlamming     = false
    S.isHoldingSpace = false
    S.isHoldingC     = false
    S.holdTimer      = 0
    workspace.Gravity = CONST.GRAVEDAD_NORMAL

    if S.connections.health then S.connections.health:Disconnect() end
    local lastHealth = S.humanoid.Health
    
    S.connections.health = S.humanoid.HealthChanged:Connect(function(health)
        if health < lastHealth then
            S.lastDamageTime = tick()
        end
        lastHealth = health
    end)
end

-- ──────────────────────────────────────────────────────────────────
-- [6]  TELETRANSPORTE OFENSIVO (SLAM)
-- ──────────────────────────────────────────────────────────────────
local function AplastarContraElSuelo()
    if S.isSlamming or not S.rootPart then return end
    
    local rayOrigin = S.rootPart.Position
    local rayDirection = Vector3.new(0, -2000, 0) 
    
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {S.character} 
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    
    local rayResult = workspace:Raycast(rayOrigin, rayDirection, rayParams)
    
    if rayResult then
        S.isSlamming = true
        DetenerAnimacionesCustom(0.1) 
        
        local impactoBase = rayResult.Position
        local objetivo = nil
        local menorDistancia = 30 
        
        for _, otroJugador in ipairs(Players:GetPlayers()) do
            if otroJugador ~= S.player and otroJugador.Character then
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
            S.anims.impacto:Play(0.1) 
            
            local tiempoAgarre = 0.2
            local t = 0
            local agarreConn
            
            agarreConn = RunService.Heartbeat:Connect(function(dt)
                t = t + dt
                if t >= tiempoAgarre or not objetivo or not objetivo.Parent then
                    agarreConn:Disconnect()
                    S.isSlamming = false
                    S.lastSlamEndTime = tick()
                    DetenerAnimacionesCustom(0.2)
                else
                    local alturaAgarre = (objetivo.Size.Y / 2) + 1.5
                    S.rootPart.CFrame = CFrame.new(objetivo.Position + Vector3.new(0, alturaAgarre, 0))
                    S.rootPart.AssemblyLinearVelocity = Vector3.zero 
                end
            end)
        else
            local alturaPiernas = S.humanoid.HipHeight + (S.rootPart.Size.Y / 2)
            S.rootPart.CFrame = CFrame.new(impactoBase + Vector3.new(0, alturaPiernas, 0))
            S.rootPart.AssemblyLinearVelocity = Vector3.zero 
            
            task.delay(0.1, function()
                S.isSlamming = false
                S.lastSlamEndTime = tick()
                DetenerAnimacionesCustom(0.2)
            end)
        end
        
        if S.isFloating then
            S.isFloating = false
        end
        S.holdTimer = 0
        workspace.Gravity = CONST.GRAVEDAD_NORMAL
    end
end

-- ──────────────────────────────────────────────────────────────────
-- [7]  BUCLE PRINCIPAL (RUNSERVICE)
-- ──────────────────────────────────────────────────────────────────
local function UpdateLoop(dt)
    if S.isSlamming or not S.humanoid or not S.rootPart then return end

    local state = S.humanoid:GetState()
    local inAir = (state == Enum.HumanoidStateType.Jumping or state == Enum.HumanoidStateType.Freefall)

    if not inAir then
        if S.isFloating then
            S.isFloating = false
            DetenerAnimacionesCustom(0.3)
        end
        workspace.Gravity = CONST.GRAVEDAD_NORMAL
        
        if not S.isHoldingSpace then
            S.holdTimer = 0
        end
    end

    if S.isHoldingSpace then
        if not S.isFloating then
            S.holdTimer = S.holdTimer + dt
            
            local tiempoRequerido = 0.5 
            
            if tick() - S.lastDamageTime <= 3 then
                tiempoRequerido = 0.15 
            elseif tick() - S.lastSlamEndTime <= 1.5 then
                tiempoRequerido = 0.3 
            end
            
            if S.holdTimer > tiempoRequerido then
                S.isFloating = true
                
                if tick() - S.lastDamageTime <= 3 then
                    S.anims.despertar:Play(0.1)
                    task.delay(0.73, function()
                        if S.isFloating and S.anims.despertar.IsPlaying then
                            S.anims.despertar:Stop(0.3)
                            S.anims.vuelo:Play(0.3)
                        end
                    end)
                else
                    S.anims.vuelo:Play(0.3)
                end
                
                S.humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
                local moveDir = S.humanoid.MoveDirection
                S.rootPart.AssemblyLinearVelocity = Vector3.new(
                    moveDir.X * CONST.IMPULSO_EXPLOSIVO_XZ, 
                    CONST.IMPULSO_EXPLOSIVO_Y, 
                    moveDir.Z * CONST.IMPULSO_EXPLOSIVO_XZ
                )
            end
        end
    else
        if not S.isFloating then
            S.holdTimer = 0
        end
    end
    
    if S.isFloating then
        workspace.Gravity = CONST.GRAVEDAD_CERO
        local moveDir = S.humanoid.MoveDirection
        local velActual = S.rootPart.AssemblyLinearVelocity
        local velY = velActual.Y
        
        if S.isHoldingC then
            velY = -0.1
        elseif S.isHoldingSpace then
            if velY < -2 then velY = -2 end
        else
            velY = velY - CONST.ACELERACION_CAIDA
            if velY < CONST.VELOCIDAD_CAIDA_LENTA then velY = CONST.VELOCIDAD_CAIDA_LENTA end
        end
        
        local targetVelXZ
        if moveDir.Magnitude > 0 then
            targetVelXZ = moveDir * CONST.VELOCIDAD_VUELO
        else
            targetVelXZ = Vector3.new(velActual.X * 0.9, 0, velActual.Z * 0.9)
        end
        
        S.rootPart.AssemblyLinearVelocity = Vector3.new(targetVelXZ.X, velY, targetVelXZ.Z)
    end
end

-- ──────────────────────────────────────────────────────────────────
-- [8]  MANEJO DE INPUTS
-- ──────────────────────────────────────────────────────────────────
local function OnInputBegan(input, gameProcessed)
    if gameProcessed or not S.humanoid or not S.rootPart then return end

    if input.KeyCode == Enum.KeyCode.Space then
        S.isHoldingSpace = true
        
        if S.isFloating then
            S.anims.reSalto:Play(0.1)
            S.anims.reSalto:AdjustSpeed(2) 
            
            local velActual = S.rootPart.AssemblyLinearVelocity
            S.rootPart.AssemblyLinearVelocity = Vector3.new(velActual.X, CONST.IMPULSO_EXPLOSIVO_Y, velActual.Z)
        end
        
    elseif input.KeyCode == Enum.KeyCode.C then
        S.isHoldingC = true
        
    elseif input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl then
        local state = S.humanoid:GetState()
        if state == Enum.HumanoidStateType.Jumping or state == Enum.HumanoidStateType.Freefall or S.isFloating then
            AplastarContraElSuelo()
        end
    end
end

local function OnInputEnded(input, gameProcessed)
    if input.KeyCode == Enum.KeyCode.Space then
        S.isHoldingSpace = false
    elseif input.KeyCode == Enum.KeyCode.C then
        S.isHoldingC = false
    end
end

-- ──────────────────────────────────────────────────────────────────
-- [9]  API PÚBLICA (M)
-- ──────────────────────────────────────────────────────────────────
local M = {}

-- Inicia el sistema de Gravattack para un jugador específico
function M.Start(lplrRef)
    if S.player then M.Stop() end -- Previene múltiples inicios
    
    S.player = lplrRef or Players.LocalPlayer
    
    -- Conectar CharacterAdded
    S.connections.charAdded = S.player.CharacterAdded:Connect(OnCharacterAdded)
    if S.player.Character then
        OnCharacterAdded(S.player.Character)
    end

    -- Conectar bucles y eventos
    S.connections.render = RunService.RenderStepped:Connect(UpdateLoop)
    S.connections.inputBegan = UserInputService.InputBegan:Connect(OnInputBegan)
    S.connections.inputEnded = UserInputService.InputEnded:Connect(OnInputEnded)
end

-- Detiene el sistema y limpia conexiones/estado
function M.Stop()
    for key, conn in pairs(S.connections) do
        if conn then
            conn:Disconnect()
            S.connections[key] = nil
        end
    end
    
    DetenerAnimacionesCustom(0)
    workspace.Gravity = CONST.GRAVEDAD_NORMAL
    S.player = nil
    S.character = nil
end

-- Devuelve si el jugador está actualmente flotando/volando
function M.IsFloating()
    return S.isFloating
end

-- Fuerza un Slam (útil si quieres activarlo desde un UI o botón en pantalla)
function M.ForceSlam()
    AplastarContraElSuelo()
end

return M
