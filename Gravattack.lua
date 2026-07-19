--[[
╔══════════════════════════════════════════════════════════════════╗
║                   GRAVATTACK SYSTEM (Corregido)                  ║
║  Sistema de control de gravedad y animaciones para R6.           ║
╚══════════════════════════════════════════════════════════════════╝
--]]

local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local Players          = game:GetService("Players")

local CONST = {
    GRAVEDAD_NORMAL  = workspace.Gravity,
    GRAVEDAD_VUELO   = 10,
    GRAVEDAD_INTENSA = 300,
}

local ANIM_IDS = {
    Vuelo     = "rbxassetid://85623478299098",
    ReSalto   = "rbxassetid://75312251819975",
    Impacto   = "rbxassetid://127236244922151",
    Despertar = "rbxassetid://83644153292302"
}

local S = {
    player          = nil,
    character       = nil,
    humanoid        = nil,
    rootPart        = nil,
    animator        = nil,

    isHoldingSpace  = false,
    isFloating      = false,

    anims = {
        vuelo     = nil,
        reSalto   = nil,
        impacto   = nil,
        despertar = nil
    },

    connections = {
        charAdded   = nil,
        state       = nil,
        inputBegan  = nil,
        inputEnded  = nil
    }
}

-- ──────────────────────────────────────────────────────────────────
-- SISTEMA DE ANIMACIONES SEGURO
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
-- INICIALIZACIÓN (Soporte R6)
-- ──────────────────────────────────────────────────────────────────
local function OnCharacterAdded(newCharacter)
    S.character = newCharacter
    S.humanoid  = S.character:WaitForChild("Humanoid")
    S.rootPart  = S.character:WaitForChild("HumanoidRootPart")
    
    -- Corrección: Crear el Animator si no existe en R6 para evitar valores nulos
    S.animator = S.humanoid:FindFirstChild("Animator")
    if not S.animator then
        S.animator = Instance.new("Animator")
        S.animator.Parent = S.humanoid
    end

    S.anims.vuelo     = LoadAnim(ANIM_IDS.Vuelo, Enum.AnimationPriority.Action2, true)
    S.anims.reSalto   = LoadAnim(ANIM_IDS.ReSalto, Enum.AnimationPriority.Action3, false)
    S.anims.impacto   = LoadAnim(ANIM_IDS.Impacto, Enum.AnimationPriority.Action4, false)
    S.anims.despertar = LoadAnim(ANIM_IDS.Despertar, Enum.AnimationPriority.Action4, false)

    S.isFloating     = false
    S.isHoldingSpace = false
    workspace.Gravity = CONST.GRAVEDAD_NORMAL

    if S.connections.state then S.connections.state:Disconnect() end
    
    -- Manejo de gravedad automático al tocar el suelo o saltar
    S.connections.state = S.humanoid.StateChanged:Connect(function(oldState, newState)
        if newState == Enum.HumanoidStateType.Landed then
            workspace.Gravity = CONST.GRAVEDAD_NORMAL
            S.isFloating = false
            DetenerAnimacionesCustom(0.2)
        elseif newState == Enum.HumanoidStateType.Freefall or newState == Enum.HumanoidStateType.Jumping then
            if S.isHoldingSpace then
                workspace.Gravity = CONST.GRAVEDAD_VUELO
                S.isFloating = true
                if S.anims.vuelo and not S.anims.vuelo.IsPlaying then
                    S.anims.vuelo:Play(0.3)
                end
            end
        end
    end)
end

-- ──────────────────────────────────────────────────────────────────
-- MANEJO DE INPUTS Y GRAVEDAD
-- ──────────────────────────────────────────────────────────────────
local function OnInputBegan(input, gameProcessed)
    if gameProcessed or not S.humanoid or not S.rootPart then return end

    if input.KeyCode == Enum.KeyCode.Space then
        S.isHoldingSpace = true
        local state = S.humanoid:GetState()
        
        -- Si ya está en el aire al mantener espacio, vuela a gravedad 10
        if state == Enum.HumanoidStateType.Freefall or state == Enum.HumanoidStateType.Jumping then
            workspace.Gravity = CONST.GRAVEDAD_VUELO
            S.isFloating = true
            if S.anims.vuelo and not S.anims.vuelo.IsPlaying then 
                S.anims.vuelo:Play(0.2) 
            end
        end
        
    elseif input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl then
        local state = S.humanoid:GetState()
        
        -- Caída intensa con gravedad 300
        if state == Enum.HumanoidStateType.Jumping or state == Enum.HumanoidStateType.Freefall or S.isFloating then
            workspace.Gravity = CONST.GRAVEDAD_INTENSA
            S.isFloating = false
            DetenerAnimacionesCustom(0.1)
        end
    end
end

local function OnInputEnded(input, gameProcessed)
    if input.KeyCode == Enum.KeyCode.Space then
        S.isHoldingSpace = false
        -- Dejar de presionar espacio no hace nada, se mantiene flotando en gravedad 10
    end
end

-- ──────────────────────────────────────────────────────────────────
-- API PÚBLICA
-- ──────────────────────────────────────────────────────────────────
local M = {}

function M.Start(lplrRef)
    if S.player then M.Stop() end 
    
    S.player = lplrRef or Players.LocalPlayer
    
    S.connections.charAdded = S.player.CharacterAdded:Connect(OnCharacterAdded)
    if S.player.Character then
        OnCharacterAdded(S.player.Character)
    end

    S.connections.inputBegan = UserInputService.InputBegan:Connect(OnInputBegan)
    S.connections.inputEnded = UserInputService.InputEnded:Connect(OnInputEnded)
end

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

function M.IsFloating()
    return S.isFloating
end

return M
