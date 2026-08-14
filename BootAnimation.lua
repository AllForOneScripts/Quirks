if getgenv()._BootAnimRunning then
    return
end
getgenv()._BootAnimRunning = true

local function FreeCinematic()
    getgenv()._BootAnimRunning = false
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local ContentProvider = game:GetService("ContentProvider")

local player = Players.LocalPlayer
local cam = workspace.CurrentCamera
local pGui = player:WaitForChild("PlayerGui")

local flashGui = Instance.new("ScreenGui")
flashGui.IgnoreGuiInset = true
flashGui.ResetOnSpawn = false
flashGui.DisplayOrder = 9999

local flashFrame = Instance.new("Frame", flashGui)
flashFrame.BackgroundColor3 = Color3.new(1, 1, 1)
flashFrame.Size = UDim2.new(1, 0, 1, 0)
flashGui.Parent = pGui

RunService.RenderStepped:Wait()

local char = player.Character or player.CharacterAdded:Wait()
local hum = char:WaitForChild("Humanoid")
local root = char:WaitForChild("HumanoidRootPart")

local cameraWatchdog = RunService.Heartbeat:Connect(function()
    if cam.CameraType ~= Enum.CameraType.Scriptable then
        cam.CameraType = Enum.CameraType.Scriptable
    end
end)

local oldCF = root.CFrame
local oldAutoRotate = hum.AutoRotate
hum.AutoRotate = false

local originalRootPos = root.Position
local originalGroundY = originalRootPos.Y

pcall(function() char.Archivable = true end)
local cloneChar = char:Clone()
pcall(function() char.Archivable = false end)

if not cloneChar then
    flashGui:Destroy()
    if cameraWatchdog then cameraWatchdog:Disconnect() end
    FreeCinematic()
    return
end

for _, v in ipairs(cloneChar:GetDescendants()) do
    if v:IsA("Script") or v:IsA("LocalScript") or v:IsA("ModuleScript") then
        v:Destroy()
    end
end

local cloneAnimator = cloneChar:FindFirstChildOfClass("Animator")
if cloneAnimator then cloneAnimator:Destroy() end

local cloneAnimate = cloneChar:FindFirstChild("Animate")
if cloneAnimate then cloneAnimate.Disabled = true end

local cloneRoot = cloneChar:FindFirstChild("HumanoidRootPart") or cloneChar:FindFirstChild("Torso")
if cloneRoot then
    cloneChar.PrimaryPart = cloneRoot
    for _, part in ipairs(cloneChar:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
            part.CanTouch = false
            part.Massless = true
        end
    end
    cloneRoot.Anchored = true
end

local CINEMATIC_CF = CFrame.new(876.2, 1882, -397.6, -0.56, 0, 0.82, 0, 1, 0, -0.82, 0, -0.56)
cloneChar:PivotTo(CINEMATIC_CF)
cloneChar.Parent = workspace

if cloneChar:FindFirstChild("Humanoid") then
    cloneChar.Humanoid.NameDisplayDistance = 0
end

_G.cloneRoot = cloneRoot
_G.cloneChar = cloneChar

-- SISTEMA ORIGINAL DE TRANSPARENCIA DEL CUERPO (RESTAURADO)
local originalParts = {}
for _, part in ipairs(char:GetDescendants()) do
    if part:IsA("BasePart") then
        originalParts[part] = {
            LocalTransparencyModifier = part.LocalTransparencyModifier,
            Transparency = part.Transparency
        }
        part.LocalTransparencyModifier = 1  
    end
end

for _, acc in ipairs(char:GetChildren()) do
    if acc:IsA("Accessory") then
        local handle = acc:FindFirstChild("Handle")
        if handle and handle:IsA("BasePart") then
            if not originalParts[handle] then
                originalParts[handle] = {
                    LocalTransparencyModifier = handle.LocalTransparencyModifier,
                    Transparency = handle.Transparency
                }
            end
            handle.LocalTransparencyModifier = 1
        end
    end
end

local summonActive = true
local summonSkyY = originalGroundY + 1500

root.Anchored = false 

local bootBV = Instance.new("BodyVelocity", root)
bootBV.Name = "BootBV"
bootBV.Velocity = Vector3.new(0, 600, 0)
bootBV.MaxForce = Vector3.new(0, 9e8, 0)
local bootBP = nil

task.spawn(function()
    local t0 = tick()
    while tick() - t0 < 10 and summonActive do
        if root and root.Parent and root.Position.Y >= summonSkyY - 20 then break end
        task.wait(0.05)
    end
    if not summonActive then return end
    if bootBV then bootBV:Destroy(); bootBV = nil end
    if not root or not root.Parent then return end
    
    bootBP = Instance.new("BodyPosition", root)
    bootBP.Name = "BootBP"
    bootBP.Position = Vector3.new(originalRootPos.X, summonSkyY, originalRootPos.Z)
    bootBP.MaxForce = Vector3.new(9e8, 9e8, 9e8)
    bootBP.P = 60000
    bootBP.D = 2500
end)

local summonMaintainer = RunService.Heartbeat:Connect(function()
    if summonActive and root then
        if math.abs(root.Position.Y - summonSkyY) > 5 then
            root.CFrame = CFrame.new(root.Position.X, summonSkyY, root.Position.Z) * (root.CFrame - root.CFrame.Position)
        end
    end
end)

local animateScript = char:FindFirstChild("Animate")
if animateScript then animateScript.Disabled = true end

local animator = hum:FindFirstChildOfClass("Animator")
if animator then
    for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
        track:Stop(0)
    end
end

local hiddenHighlights = {}
local function HideHighlights()
    table.clear(hiddenHighlights)
    for _, desc in ipairs(workspace:GetDescendants()) do
        if desc:IsA("Highlight") and desc.Enabled then
            hiddenHighlights[desc] = true
            desc.Enabled = false
        end
    end
end

local function RestoreHighlights()
    for highlight, _ in pairs(hiddenHighlights) do
        if highlight and highlight.Parent then
            pcall(function() highlight.Enabled = true end)
        end
    end
    table.clear(hiddenHighlights)
end

HideHighlights()

local function GetCustomResource(fileName, url)
    if not isfile(fileName) then writefile(fileName, game:HttpGet(url)) end
    return getcustomasset(fileName)
end

---------------------------------------------------------------------------INICIO------------------------------------------------------------------------------
-----------------------------------------------------------------------EFECTO ESPECIAL-------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local function SpawnAFODimension(centerCF)
    local dimensionFolder = Instance.new("Folder")
    dimensionFolder.Name = "AFO_Dimension_Effect"
    dimensionFolder.Parent = workspace

    local boxSize = 60 
    local half = boxSize / 2
    local wallThickness = 2

    -- --- ASSETS Y CONFIGURACIÓN ---
    local NEON_TEXTURE_ID = "rbxassetid://17146735339"
    local BG_TEXTURE_ID = "rbxassetid://72194288856630"  
    local NOISE_TEXTURE_ID = "rbxassetid://71963165748803" 
    local SMOKE_TEXTURE_ID = "rbxassetid://13490928216"

    -- --- PALETA: FUCSIA ---
    local AFO_FUCHSIA = Color3.fromRGB(136, 21, 88)    -- Fucsia solicitado
    local AFO_DEEP_PURPLE = Color3.fromRGB(45, 5, 30)  -- Fondo y humo adaptados a tonos fucsia oscuro
    local AFO_BLACK = Color3.fromRGB(5, 5, 5)          -- Paredes y Vacío
    local AFO_RUIDO = Color3.fromRGB(180, 50, 120)     -- Chispas de Ruido en fucsia brillante

    local NEON_SPEED = 180 
    local BG_SPEED = 12    
    local CLIMAX_TIME = 6 -- Cambiado a 6s

    -- --- 1. CONSTRUCCIÓN DE LA ESTRUCTURA (PAREDES INTERNAS) ---
    local facesData = {
        {name = "Top",    offset = CFrame.new(0, half, 0),  size = Vector3.new(boxSize, wallThickness, boxSize), innerFace = Enum.NormalId.Bottom},
        {name = "Bottom", offset = CFrame.new(0, -half, 0), size = Vector3.new(boxSize, wallThickness, boxSize), innerFace = Enum.NormalId.Top},
        {name = "Front",  offset = CFrame.new(0, 0, -half), size = Vector3.new(boxSize, boxSize, wallThickness), innerFace = Enum.NormalId.Back},
        {name = "Back",   offset = CFrame.new(0, 0, half),  size = Vector3.new(boxSize, boxSize, wallThickness), innerFace = Enum.NormalId.Front},
        {name = "Right",  offset = CFrame.new(half, 0, 0),  size = Vector3.new(wallThickness, boxSize, boxSize), innerFace = Enum.NormalId.Left},
        {name = "Left",   offset = CFrame.new(-half, 0, 0), size = Vector3.new(wallThickness, boxSize, boxSize), innerFace = Enum.NormalId.Right}
    }

    local allTextures = {}

    for _, data in ipairs(facesData) do
        local wall = Instance.new("Part")
        wall.Name = data.name
        wall.Shape = Enum.PartType.Block
        wall.Size = data.size
        wall.CFrame = centerCF * data.offset
        wall.Color = AFO_BLACK 
        wall.Material = Enum.Material.SmoothPlastic
        wall.Anchored = true
        wall.CanCollide = false
        wall.CanTouch = false
        wall.CastShadow = false 
        wall.Parent = dimensionFolder

        -- Fondo Scrolling (Oscuro)
        local bgUp = Instance.new("Texture")
        bgUp.Name = "BgUp"
        bgUp.Texture = BG_TEXTURE_ID
        bgUp.Transparency = 0.2 
        bgUp.Color3 = AFO_DEEP_PURPLE 
        bgUp.Face = data.innerFace
        bgUp.StudsPerTileU = boxSize / 1.5
        bgUp.StudsPerTileV = boxSize / 1.5
        bgUp.ZIndex = 1 
        bgUp.Parent = wall
        table.insert(allTextures, bgUp)

        local bgDown = bgUp:Clone()
        bgDown.Name = "BgDown"
        bgDown.Parent = wall
        table.insert(allTextures, bgDown)

        -- Glow Neon (Fucsia)
        local texNeonGlow = Instance.new("Texture")
        texNeonGlow.Name = "NeonGlow"
        texNeonGlow.Texture = NEON_TEXTURE_ID
        texNeonGlow.Transparency = 0.4 
        texNeonGlow.Color3 = AFO_FUCHSIA 
        texNeonGlow.Face = data.innerFace
        texNeonGlow.StudsPerTileU = (boxSize * 3) * 1.35 
        texNeonGlow.StudsPerTileV = (boxSize * 3) * 1.35 
        texNeonGlow.ZIndex = 2 
        texNeonGlow.Parent = wall
        table.insert(allTextures, texNeonGlow)

        -- Neon Principal (Fucsia Intenso)
        local texNeon = Instance.new("Texture")
        texNeon.Name = "NeonMain"
        texNeon.Texture = NEON_TEXTURE_ID
        texNeon.Transparency = 0 
        texNeon.Color3 = AFO_FUCHSIA
        texNeon.Face = data.innerFace
        texNeon.StudsPerTileU = boxSize * 3 
        texNeon.StudsPerTileV = boxSize * 3 
        texNeon.ZIndex = 3 
        texNeon.Parent = wall
        table.insert(allTextures, texNeon)
    end

    -- --- 2. HUMO CENTRAL Y RUIDO (POLOS TOP/BOTTOM) ---
    local topPole = Instance.new("Part")
    topPole.Size = Vector3.new(boxSize, 1, boxSize)
    topPole.CFrame = centerCF * CFrame.new(0, half, 0)
    topPole.Transparency = 1
    topPole.Anchored = true
    topPole.CanCollide = false
    topPole.Parent = dimensionFolder

    local bottomPole = topPole:Clone()
    bottomPole.CFrame = centerCF * CFrame.new(0, -half, 0)
    bottomPole.Parent = dimensionFolder

    local function createSinisterSmoke(polePart, emitDirection)
        local smokeEmitter = Instance.new("ParticleEmitter")
        smokeEmitter.Texture = SMOKE_TEXTURE_ID
        smokeEmitter.LightEmission = 0.1 
        smokeEmitter.ZOffset = 0.5 
        smokeEmitter.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, AFO_DEEP_PURPLE),
            ColorSequenceKeypoint.new(1, AFO_BLACK)
        })
        smokeEmitter.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 10), NumberSequenceKeypoint.new(1, 40)})
        smokeEmitter.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1), 
            NumberSequenceKeypoint.new(0.3, 0.85), 
            NumberSequenceKeypoint.new(1, 1)
        })
        smokeEmitter.Lifetime = NumberRange.new(4, 6)
        smokeEmitter.Rate = 20 
        smokeEmitter.Speed = NumberRange.new(5, 10) 
        smokeEmitter.EmissionDirection = emitDirection
        smokeEmitter.Rotation = NumberRange.new(0, 360)
        smokeEmitter.RotSpeed = NumberRange.new(-10, 10)
        smokeEmitter.Parent = polePart

        local noiseEmitter = Instance.new("ParticleEmitter")
        noiseEmitter.Texture = NOISE_TEXTURE_ID
        noiseEmitter.LightEmission = 0.8 
        noiseEmitter.ZOffset = 0.6 
        noiseEmitter.Color = ColorSequence.new(AFO_RUIDO)
        noiseEmitter.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 5), NumberSequenceKeypoint.new(1, 15)})
        noiseEmitter.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.2, 0), NumberSequenceKeypoint.new(1, 1)})
        noiseEmitter.Lifetime = NumberRange.new(1, 3)
        noiseEmitter.Rate = 15 
        noiseEmitter.Speed = NumberRange.new(20, 50) 
        noiseEmitter.Drag = 5 
        noiseEmitter.EmissionDirection = emitDirection
        noiseEmitter.SpreadAngle = Vector2.new(360, 360)
        noiseEmitter.Parent = polePart -- ¡AQUÍ ESTABA EL ERROR! (antes era noiseEmitter.Parent = noiseEmitter)
    end

    createSinisterSmoke(topPole, Enum.NormalId.Bottom)
    createSinisterSmoke(bottomPole, Enum.NormalId.Top)

    -- --- 3. EFECTO "SOFT" PROGRESIVO (NIEBLA INTERNA CENTRAL) ---
    local softVolume = Instance.new("Part")
    softVolume.Size = Vector3.new(boxSize, boxSize, boxSize)
    softVolume.CFrame = centerCF
    softVolume.Anchored = true
    softVolume.CanCollide = false
    softVolume.Transparency = 1
    softVolume.Parent = dimensionFolder

    local hazeEmitter = Instance.new("ParticleEmitter")
    hazeEmitter.Name = "InternalHaze"
    hazeEmitter.Texture = SMOKE_TEXTURE_ID 
    hazeEmitter.Color = ColorSequence.new(AFO_DEEP_PURPLE)
    hazeEmitter.LightEmission = 0.05 
    hazeEmitter.ZOffset = -1 
    hazeEmitter.Size = NumberSequence.new(boxSize * 0.8) 
    hazeEmitter.Transparency = NumberSequence.new(1) 
    hazeEmitter.Lifetime = NumberRange.new(10) 
    hazeEmitter.Rate = 0 
    hazeEmitter.Speed = NumberRange.new(0) 
    hazeEmitter.Shape = Enum.ParticleEmitterShape.Box
    hazeEmitter.Parent = softVolume

    -- --- 4. VIENTO CAÓTICO (ELIMINADO A PETICIÓN) ---
    -- Se ha eliminado el emisor de partículas que creaba el viento caótico y los cuadraditos transparentes.

    -- --- 5. LUZ Y PARTÍCULAS ENVOLVENTES DESDE EL SUR (BACK) ---
    local southPole = Instance.new("Part")
    southPole.Size = Vector3.new(boxSize, boxSize, 2)
    southPole.CFrame = centerCF * CFrame.new(0, 0, half - 1)
    southPole.Anchored = true
    southPole.CanCollide = false
    southPole.Transparency = 1
    southPole.Parent = dimensionFolder

    -- Partículas Envolventes Caóticas 
    local southParticles = Instance.new("ParticleEmitter")
    southParticles.Name = "SouthEnvelopingVoid"
    southParticles.Texture = SMOKE_TEXTURE_ID
    southParticles.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, AFO_BLACK),
        ColorSequenceKeypoint.new(0.5, AFO_FUCHSIA),
        ColorSequenceKeypoint.new(1, AFO_DEEP_PURPLE)
    })
    southParticles.LightEmission = 0.1
    southParticles.ZOffset = 0.2
    southParticles.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.5, 10), NumberSequenceKeypoint.new(1, 0)})
    southParticles.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1), 
        NumberSequenceKeypoint.new(0.2, 0.8), 
        NumberSequenceKeypoint.new(0.8, 0.8), 
        NumberSequenceKeypoint.new(1, 1)
    })
    southParticles.Lifetime = NumberRange.new(5, 7)
    southParticles.Rate = 0 
    southParticles.Speed = NumberRange.new(20, 40) 
    southParticles.EmissionDirection = Enum.NormalId.Front
    southParticles.SpreadAngle = Vector2.new(80, 80) 
    southParticles.Drag = 3 
    southParticles.Shape = Enum.ParticleEmitterShape.Box
    southParticles.Parent = southPole

    -- --- 6. BUCLE DE ANIMACIÓN Y CRECIMIENTO PROGRESIVO ---
    local startTime = os.clock()
    local conn
    
    conn = RunService.RenderStepped:Connect(function()
        if not dimensionFolder.Parent then
            if conn then conn:Disconnect() end
            return
        end

        local elapsed = os.clock() - startTime
        local alpha = math.clamp(elapsed / CLIMAX_TIME, 0, 1)
        
        southParticles.Rate = alpha * 400

        hazeEmitter.Rate = alpha * 10 
        
        local softTrans = 1 - (alpha * 0.25) 
        hazeEmitter.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.5, softTrans),
            NumberSequenceKeypoint.new(1, 1)
        })
        
        hazeEmitter.Size = NumberSequence.new((boxSize * 0.8) + (alpha * boxSize * 0.2))

        local offsetNeon = elapsed * NEON_SPEED
        local offsetBg = elapsed * BG_SPEED

        for _, tex in ipairs(allTextures) do
            if tex.Name == "NeonMain" or tex.Name == "NeonGlow" then
                if tex.Parent.Name == "Top" or tex.Parent.Name == "Bottom" then
                    tex.OffsetStudsV = offsetNeon
                else
                    tex.OffsetStudsU = offsetNeon
                end
            elseif tex.Name == "BgUp" then
                tex.OffsetStudsV = -offsetBg
            elseif tex.Name == "BgDown" then
                tex.OffsetStudsV = offsetBg
            end
        end
    end)
end
---------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------EFECTO ESPECIAL-------------------------------------------------------------------------
-----------------------------------------------------------------------------FIN-------------------------------------------------------------------------------

local AnimAssetURL = "https://raw.githubusercontent.com/AllForOneScripts/Quirks/refs/heads/main/Summon.rbxmx"
local AudioAssetURL = "https://github.com/ian49972/smth/raw/refs/heads/main/Cosmic.mp3"

local function findHandleAttachment(handle)
    for _, child in ipairs(handle:GetChildren()) do
        if child:IsA("Attachment") then return child end
    end
    return nil
end

local function findCharacterAttachment(character, attachmentName)
    for _, descendant in ipairs(character:GetDescendants()) do
        if descendant:IsA("Attachment") and descendant.Name == attachmentName and descendant.Parent:IsA("BasePart") then
            return descendant
        end
    end
    return nil
end

local function manualAttachAccessory(accessory, character)
    local handle = accessory:FindFirstChild("Handle")
    if not handle or not handle:IsA("BasePart") then return false end
    local handleAttachment = findHandleAttachment(handle)
    if not handleAttachment then return false end
    local characterAttachment = findCharacterAttachment(character, handleAttachment.Name)
    if not characterAttachment then return false end

    accessory.Parent = character
    handle.Anchored = false
    handle.CanCollide = false
    handle.Massless = true
    handle.LocalTransparencyModifier = 0
    handle.CFrame = characterAttachment.Parent.CFrame * characterAttachment.CFrame * handleAttachment.CFrame:Inverse()

    local oldWeld = handle:FindFirstChild("AccessoryWeld")
    if oldWeld then oldWeld:Destroy() end

    local weld = Instance.new("Weld")
    weld.Name = "AccessoryWeld"
    weld.Part0 = handle
    weld.Part1 = characterAttachment.Parent
    weld.C0 = handleAttachment.CFrame
    weld.C1 = characterAttachment.CFrame
    weld.Parent = handle
    return true
end

local function ApplyJaidenAppearance(rig)
    local targetUsername = "Jaiden_X33"
    local successId, userId = pcall(function() return Players:GetUserIdFromNameAsync(targetUsername) end)
    
    if not successId or not userId then return end
    
    local sModel, appearanceModel = pcall(function()
        return Players:GetCharacterAppearanceAsync(userId)
    end)
    
    if not sModel or not appearanceModel then return end
    
    local rigHum = rig:FindFirstChildOfClass("Humanoid")
    if rigHum then rigHum.RigType = Enum.HumanoidRigType.R6 end
    
    for _, v in ipairs(rig:GetChildren()) do
        if v:IsA("Accessory") or v:IsA("Shirt") or v:IsA("Pants") or v:IsA("ShirtGraphic") or v:IsA("BodyColors") then
            v:Destroy()
        end
    end
    
    for _, item in ipairs(appearanceModel:GetChildren()) do
        if item:IsA("Accessory") then
            local clone = item:Clone()
            local added = pcall(function() rigHum:AddAccessory(clone) end)
            local handle = clone:FindFirstChild("Handle")
            
            if not (added and handle and handle:FindFirstChild("AccessoryWeld")) then
                manualAttachAccessory(clone, rig)
            end
            
            if handle then
                local isHeadAcc = false
                local weld = handle:FindFirstChild("AccessoryWeld")
                if weld and weld.Part1 and weld.Part1.Name == "Head" then
                    isHeadAcc = true
                else
                    local att = findHandleAttachment(handle)
                    if att and (att.Name == "HatAttachment" or att.Name == "HairAttachment" or att.Name == "FaceFrontAttachment" or att.Name == "FaceCenterAttachment") then
                        isHeadAcc = true
                    end
                end

                if isHeadAcc then
                    if handle:IsA("MeshPart") then
                        handle.Size = handle.Size * 1.5
                    end
                    local mesh = handle:FindFirstChildOfClass("SpecialMesh")
                    if mesh then
                        mesh.Scale = mesh.Scale * 1.5
                    end
                    local att = handle:FindFirstChildOfClass("Attachment")
                    if att then
                        att.Position = att.Position * 1.5
                        if weld then
                            weld.C0 = att.CFrame * CFrame.new(0, handle.Size.Y * 0.2, 0)
                        end
                    end
                end
            end
            
        elseif item:IsA("Shirt") or item:IsA("Pants") or item:IsA("ShirtGraphic") or item:IsA("BodyColors") then
            item:Clone().Parent = rig
            
        elseif item.Name == "R6" and item:IsA("Folder") then
            for _, r6Item in ipairs(item:GetChildren()) do
                if r6Item:IsA("CharacterMesh") then
                    r6Item:Clone().Parent = rig
                end
            end
            
        elseif item:IsA("CharacterMesh") then
            item:Clone().Parent = rig
        end
    end
    
    appearanceModel:Destroy()

    local head = rig:FindFirstChild("Head")
    if head then
        head.Transparency = 1
        for _, v in ipairs(head:GetChildren()) do
            if v:IsA("Decal") or v:IsA("SpecialMesh") or v:IsA("DataModelMesh") then
                v:Destroy()
            end
        end
    end
end

local function UpdateCloneAppearance()
    if not cloneChar or not char then return end
    
    local cloneHum = cloneChar:FindFirstChildOfClass("Humanoid")
    if not cloneHum then return end

    for _, v in ipairs(cloneChar:GetChildren()) do
        if v:IsA("Accessory") or v:IsA("Hat") or v:IsA("Shirt") or v:IsA("Pants") or v:IsA("ShirtGraphic") or v:IsA("BodyColors") or v:IsA("CharacterMesh") then
            v:Destroy()
        end
    end

    local cHead = cloneChar:FindFirstChild("Head")
    local sHead = char:FindFirstChild("Head")
    
    if cHead then
        for _, child in ipairs(cHead:GetChildren()) do
            if child:IsA("DataModelMesh") or child:IsA("SpecialMesh") or child:IsA("Decal") then
                child:Destroy()
            end
        end
        
        local defaultMesh = Instance.new("SpecialMesh")
        defaultMesh.MeshType = Enum.MeshType.Head
        defaultMesh.Scale = Vector3.new(1.25, 1.25, 1.25)
        defaultMesh.Parent = cHead
    end

    local loadedFace = false

    for _, item in ipairs(char:GetChildren()) do
        if item:IsA("Accessory") then
            local cloneItem = item:Clone()
            local handle = cloneItem:FindFirstChild("Handle")
            
            if handle then
                handle.LocalTransparencyModifier = 0
                handle.Transparency = 0
                
                for _, weld in ipairs(handle:GetChildren()) do
                    if weld:IsA("Weld") or weld:IsA("WeldConstraint") or weld.Name == "AccessoryWeld" then
                        weld:Destroy()
                    end
                end
            end
            
            local added = pcall(function() 
                cloneHum:AddAccessory(cloneItem) 
            end)
            
            if not (added and handle and handle:FindFirstChild("AccessoryWeld")) then
                manualAttachAccessory(cloneItem, cloneChar)
            end
            
        elseif item:IsA("Shirt") or item:IsA("Pants") or item:IsA("ShirtGraphic") or item:IsA("BodyColors") or item:IsA("CharacterMesh") then
            item:Clone().Parent = cloneChar
        end
    end
    
    if sHead and cHead then
        local hasCustomMesh = false
        for _, item in ipairs(sHead:GetChildren()) do
            if item:IsA("DataModelMesh") or item:IsA("SpecialMesh") then
                hasCustomMesh = true
                break
            end
        end
        
        if hasCustomMesh then
            for _, oldMesh in ipairs(cHead:GetChildren()) do
                if oldMesh:IsA("DataModelMesh") or oldMesh:IsA("SpecialMesh") then
                    oldMesh:Destroy()
                end
            end
        end
        
        for _, item in ipairs(sHead:GetChildren()) do
            if item:IsA("Decal") and (item.Name:lower() == "face" or item.Texture ~= "") then
                loadedFace = true
                item:Clone().Parent = cHead
            elseif item:IsA("DataModelMesh") or item:IsA("SpecialMesh") then
                item:Clone().Parent = cHead
            end
        end
    end

    if cloneHum.RigType == Enum.HumanoidRigType.R6 and cHead and not loadedFace then
        local defaultFace = Instance.new("Decal")
        defaultFace.Name = "face"
        defaultFace.Face = Enum.NormalId.Front
        defaultFace.Texture = "rbxasset://textures/face.png"
        defaultFace.Parent = cHead
    end
end

local function PlayKeyframeSequence(Model, KFS, Speed)
    Speed = Speed or 1
    local keyframes, jointData, motorMap = {}, {}, {}
    for _, kf in ipairs(KFS:GetKeyframes()) do table.insert(keyframes, {Time = kf.Time, KF = kf}) end
    table.sort(keyframes, function(a, b) return a.Time < b.Time end)
    if #keyframes == 0 then return nil end
    local function ResolveJoint(pose)
        local name = pose.Name
        if motorMap[name] then return motorMap[name] end
        for _, v in ipairs(Model:GetDescendants()) do
            if v:IsA("Motor6D") and v.Part1 and v.Part1.Name == name then motorMap[name] = v; return v end
        end
        return nil
    end
    for _, entry in ipairs(keyframes) do
        for _, pose in ipairs(entry.KF:GetDescendants()) do
            if pose:IsA("Pose") and pose.Weight > 0 then
                local joint = ResolveJoint(pose)
                if joint then
                    jointData[pose.Name] = jointData[pose.Name] or {}
                    table.insert(jointData[pose.Name], {time = entry.Time, cframe = pose.CFrame, joint = joint})
                end
            end
        end
    end
    local tLength = keyframes[#keyframes].Time / Speed
    local startT, skipOff, isPlaying, conn = os.clock(), 0, true, nil
    conn = RunService.Heartbeat:Connect(function()
        if not isPlaying or not Model or not Model.Parent then
            if conn then conn:Disconnect(); conn = nil end
            return
        end
        local tPos = (((os.clock() - startT) * Speed) + skipOff) % tLength
        for _, poses in pairs(jointData) do
            if #poses < 2 then continue end
            local p1, p2 = poses[1], poses[#poses]
            for i = 1, #poses - 1 do
                if tPos >= poses[i].time and tPos < poses[i + 1].time then p1, p2 = poses[i], poses[i + 1]; break end
            end
            local alpha = (p2.time > p1.time) and ((tPos - p1.time) / (p2.time - p1.time)) or 0
            p1.joint.Transform = p1.cframe:Lerp(p2.cframe, alpha)
        end
    end)
    return {
        Length = tLength,
        Stop = function()
            isPlaying = false
            if conn then conn:Disconnect(); conn = nil end
        end,
        AddSkip = function(s) skipOff = skipOff + s end,
        GetTime = function() return ((os.clock() - startT) * Speed) + skipOff end
    }
end

local s, Asset = pcall(function() return game:GetObjects(GetCustomResource("CosmicG.rbxmx", AnimAssetURL))[1] end)
if not s or not Asset then
    flashGui:Destroy()
    RestoreHighlights()
    if cameraWatchdog then cameraWatchdog:Disconnect() end
    if animator then animator.Parent = hum end
    if animateScript then animateScript.Disabled = false end
    FreeCinematic()
    return
end

Asset.Parent = workspace
local CRigs, Anims = Asset:FindFirstChild("CosmicRigs"), Asset:FindFirstChild("Anims")
if CRigs.GOD then ApplyJaidenAppearance(CRigs.GOD) end

local snd = Instance.new("Sound", workspace)
snd.SoundId, snd.Volume = GetCustomResource("Cosmic.mp3", AudioAssetURL), 2

local oldSky = Lighting:FindFirstChildOfClass("Sky")
local sky = Instance.new("Sky")
sky.SkyboxBk, sky.SkyboxDn, sky.SkyboxFt, sky.SkyboxLf, sky.SkyboxRt, sky.SkyboxUp = 
    "rbxassetid://7188341508", "rbxassetid://7188341508", "rbxassetid://7188341508",
    "rbxassetid://7188341508", "rbxassetid://7188341508", "rbxassetid://7188341508"
sky.Parent = Lighting

task.delay(8.5, function() 
    if sky and sky.Parent then sky:Destroy() end
    if oldSky then oldSky.Parent = Lighting end
    
    local sGui = Instance.new("ScreenGui", pGui)
    sGui.IgnoreGuiInset, sGui.ResetOnSpawn = true, false
    
    local fade = Instance.new("Frame", sGui)
    fade.BackgroundColor3, fade.Size = Color3.new(0,0,0), UDim2.new(1,0,1,0)
    fade.BackgroundTransparency = 0
    
    UpdateCloneAppearance()
    
    task.delay(2, function()
        local tw = TweenService:Create(fade, TweenInfo.new(1), {BackgroundTransparency = 1})
        tw:Play()
        tw.Completed:Connect(function() sGui:Destroy() end)
    end)
end)

local preloadFinished = false
task.spawn(function()
    pcall(function() ContentProvider:PreloadAsync({Asset, sky}) end)
    preloadFinished = true
end)

local startPreloadTime = os.clock()
repeat RunService.RenderStepped:Wait() until preloadFinished or (os.clock() - startPreloadTime > 3.5)
cam.CameraType = Enum.CameraType.Scriptable
snd:Play()

-- SE INICIA LA BURBUJA NEGRA AFO DURANTE LOS PRIMEROS 8.5 SEGUNDOS
SpawnAFODimension(CINEMATIC_CF)

pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/AllForOneScripts/Quirks/refs/heads/main/SummonCam.lua"))() end)

local fadeOutTw = TweenService:Create(flashFrame, TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1})
fadeOutTw:Play()
fadeOutTw.Completed:Connect(function() flashGui:Destroy() end)

local bgAnims = {}
if CRigs.GOD and Anims.GOD then table.insert(bgAnims, PlayKeyframeSequence(CRigs.GOD, Anims.GOD)) end
if CRigs.SceneRig and Anims.SceneRig then table.insert(bgAnims, PlayKeyframeSequence(CRigs.SceneRig, Anims.SceneRig)) end
local pAnim1 = Anims.Player and PlayKeyframeSequence(cloneChar, Anims.Player)

task.delay(8, function()
    for _, a in ipairs(bgAnims) do a.AddSkip(8) end
    if pAnim1 then pAnim1.AddSkip(9.9) end
end)

if pAnim1 then
    repeat task.wait(0.05) until pAnim1.GetTime() >= pAnim1.Length
    pAnim1:Stop()
end

cloneRoot.Anchored = true
cloneRoot.CFrame = oldCF + Vector3.new(0, 0.25, 0)
task.wait(2.9)

if Anims.PlayerTwo then
    local pAnim2 = PlayKeyframeSequence(cloneChar, Anims.PlayerTwo)
    if pAnim2 then
        pAnim2.AddSkip(27.8)
        repeat task.wait(0.05) until pAnim2.GetTime() >= pAnim2.Length
        pAnim2:Stop()
    end
end

local finalCloneCF = cloneRoot.CFrame
local finalPos = finalCloneCF.Position
local finalRot = finalCloneCF - finalCloneCF.Position
local OFFSET_Y = 0.5
local targetPos = finalPos + Vector3.new(0, OFFSET_Y, 0)
local targetCF = CFrame.new(targetPos) * finalRot

if cameraWatchdog then cameraWatchdog:Disconnect() end
pcall(function() RunService:UnbindFromRenderStep("FollowCinematic") end)
getgenv()._StopCinematic = true 

if snd then
    task.delay(5, function()
        local audioFade = TweenService:Create(snd, TweenInfo.new(4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Volume = 0})
        audioFade:Play()
        audioFade.Completed:Connect(function()
            snd:Stop()
            snd:Destroy()
        end)
    end)
end

if sky and sky.Parent then sky:Destroy() end
if oldSky then oldSky.Parent = Lighting end
RestoreHighlights()

for _, motor in ipairs(char:GetDescendants()) do
    if motor:IsA("Motor6D") then
        motor.Transform = CFrame.new()
    end
end

summonActive = false
if summonMaintainer then summonMaintainer:Disconnect() end
if bootBV then bootBV:Destroy() end
if bootBP then bootBP:Destroy() end

-- BUG FIX: Forzar teletransporte hasta confirmar que estás en el suelo (No más jugador en el aire al terminar)
root.Anchored = false
local safeYLimit = originalGroundY + 100
local teleportAttempts = 0

repeat
    root.CFrame = targetCF
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    task.wait(0.05)
    teleportAttempts = teleportAttempts + 1
until (root.Position.Y < safeYLimit) or teleportAttempts > 20

local landBV = Instance.new("BodyVelocity")
landBV.Velocity = Vector3.zero
landBV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
landBV.Parent = root
hum.PlatformStand = true

task.defer(function()
    pcall(function() landBV:Destroy() end)
    if hum and hum.Parent then
        hum.PlatformStand = false
        hum:ChangeState(Enum.HumanoidStateType.Landed)
    end
end)

for part, data in pairs(originalParts) do
    if part and part.Parent then
        part.LocalTransparencyModifier = data.LocalTransparencyModifier
        part.Transparency = data.Transparency
    end
end
hum.AutoRotate = oldAutoRotate

if cloneChar then cloneChar:Destroy() end
_G.cloneRoot = nil
_G.cloneChar = nil

local animatorFinal = hum:FindFirstChildOfClass("Animator")
if not animatorFinal then
    animatorFinal = Instance.new("Animator")
    animatorFinal.Parent = hum
end

for _, track in ipairs(animatorFinal:GetPlayingAnimationTracks()) do
    track:Stop(0)
end

local animObj = Instance.new("Animation")
animObj.AnimationId = "rbxassetid://18941564777"
local trackFinal = animatorFinal:LoadAnimation(animObj)
if trackFinal then
    trackFinal.Priority = Enum.AnimationPriority.Action4
    trackFinal:Play(0.1, 1, 1)  
end

local targetOffset = oldCF * CFrame.new(0, 2, 12)
local targetCameraCFrame = CFrame.lookAt(targetOffset.Position, oldCF.Position)
local camProxy = Instance.new("CFrameValue")
camProxy.Value = cam.CFrame
local fovProxy = Instance.new("NumberValue")
fovProxy.Value = cam.FieldOfView

local overrideId = "Cinematic_Absolute_Cam_Override"
RunService:BindToRenderStep(overrideId, Enum.RenderPriority.Camera.Value + 200, function()
    cam.CameraType = Enum.CameraType.Scriptable
    cam.CFrame = camProxy.Value
    cam.FieldOfView = fovProxy.Value
end)

local camTweenInfo = TweenInfo.new(0.975, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
local camTween = TweenService:Create(camProxy, camTweenInfo, {Value = targetCameraCFrame})
local fovTween = TweenService:Create(fovProxy, camTweenInfo, {Value = 70})

camTween:Play()
fovTween:Play()
camTween.Completed:Wait()

RunService:UnbindFromRenderStep(overrideId)
cam.CameraSubject = hum
cam.CameraType = Enum.CameraType.Custom

task.spawn(function()
    task.wait(0.5)
    
    if trackFinal then
        trackFinal:Stop(0.5)
        task.delay(0.5, function()
            pcall(function() trackFinal:Destroy() end)
        end)
    end
    
    if animateScript then
        animateScript.Disabled = false
        hum:ChangeState(Enum.HumanoidStateType.Landed)
    end
    
    FreeCinematic()
end)
