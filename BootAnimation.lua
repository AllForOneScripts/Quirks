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

flashFrame.BackgroundColor3 = Color3.new(0, 0, 0)
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




local function ResetCinematicBodyAndCamera()
    if not char or not char.Parent or not hum or not hum.Parent or not root or not root.Parent then return end

    for _, motor in ipairs(char:GetDescendants()) do
        if motor:IsA("Motor6D") then
            motor.Transform = CFrame.new()
        end
    end


    local _, yaw, _ = root.CFrame:ToEulerAnglesYXZ()
    local stableCF = CFrame.new(root.Position) * CFrame.Angles(0, yaw, 0)
    root.CFrame = stableCF
    root.AssemblyAngularVelocity = Vector3.zero

    hum.AutoRotate = false
    cam.CameraSubject = hum
    cam.CameraType = Enum.CameraType.Custom
    RunService.RenderStepped:Wait()

    cam.CameraSubject = hum
    cam.CameraType = Enum.CameraType.Custom
    hum.AutoRotate = oldAutoRotate
    hum:ChangeState(Enum.HumanoidStateType.Running)
end

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




local function SpawnAFODimension(centerCF)
    local dimensionFolder = Instance.new("Folder")
    dimensionFolder.Name = "AFO_Dimension_Effect"
    dimensionFolder.Parent = workspace

    local boxSize = 60 
    local half = boxSize / 2
    local wallThickness = 2

    local NEON_TEXTURE_ID = "rbxassetid://17146735339"
    local BG_TEXTURE_ID = "rbxassetid://72194288856630"  
    local SMOKE_TEXTURE_ID = "rbxassetid://13490928216"

    local AFO_FUCHSIA = Color3.fromRGB(136, 21, 88)
    local NEON_FUCHSIA = Color3.fromRGB(255, 0, 255)
    local AFO_BRIGHT_PURPLE = Color3.fromRGB(170, 0, 255)
    local AFO_DEEP_PURPLE = Color3.fromRGB(45, 5, 30)
    local AFO_BLACK = Color3.fromRGB(5, 5, 5)

    local BG_SPEED = 12    
    local CLIMAX_TIME = 20 

    local facesData = {
        {name = "Top",    offset = CFrame.new(0, half, 0),  size = Vector3.new(boxSize, wallThickness, boxSize), innerFace = Enum.NormalId.Bottom},
        {name = "Bottom", offset = CFrame.new(0, -half, 0), size = Vector3.new(boxSize, wallThickness, boxSize), innerFace = Enum.NormalId.Top},
        {name = "Front",  offset = CFrame.new(0, 0, -half), size = Vector3.new(boxSize, boxSize, wallThickness), innerFace = Enum.NormalId.Back},
        {name = "Back",   offset = CFrame.new(0, 0, half),  size = Vector3.new(boxSize, boxSize, wallThickness), innerFace = Enum.NormalId.Front},
        {name = "Right",  offset = CFrame.new(half, 0, 0),  size = Vector3.new(wallThickness, boxSize, boxSize), innerFace = Enum.NormalId.Left},
        {name = "Left",   offset = CFrame.new(-half, 0, 0), size = Vector3.new(wallThickness, boxSize, boxSize), innerFace = Enum.NormalId.Right}
    }

    local scrollingBackgrounds = {}

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


        local bgUp = Instance.new("Texture")
        bgUp.Name = "BgUp"
        bgUp.Texture = BG_TEXTURE_ID
        bgUp.Transparency = 0.5 
        bgUp.Color3 = AFO_DEEP_PURPLE 
        bgUp.Face = data.innerFace
        bgUp.StudsPerTileU = boxSize / 1.5
        bgUp.StudsPerTileV = boxSize / 1.5
        bgUp.ZIndex = 1 
        bgUp.Parent = wall
        table.insert(scrollingBackgrounds, bgUp)

        local bgDown = bgUp:Clone()
        bgDown.Name = "BgDown"
        bgDown.Parent = wall
        table.insert(scrollingBackgrounds, bgDown)


        local surfGui = Instance.new("SurfaceGui")
        surfGui.Name = "NeonGui"
        surfGui.Face = data.innerFace
        surfGui.CanvasSize = Vector2.new(1000, 1000)
        surfGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        surfGui.Parent = wall
        

        local neonGlow = Instance.new("ImageLabel")
        neonGlow.Name = "NeonGlow"
        neonGlow.BackgroundTransparency = 1
        neonGlow.Image = NEON_TEXTURE_ID
        neonGlow.ImageColor3 = NEON_FUCHSIA
        neonGlow.ImageTransparency = 0.6 
        neonGlow.AnchorPoint = Vector2.new(0.5, 0.5)
        neonGlow.Position = UDim2.new(0.5, 0, 0.5, 0)
        neonGlow.Size = UDim2.new(1.35, 0, 1.35, 0)
        neonGlow.ZIndex = 2
        neonGlow.Parent = surfGui
        
        local neonMain = Instance.new("ImageLabel")
        neonMain.Name = "NeonMain"
        neonMain.BackgroundTransparency = 1
        neonMain.Image = NEON_TEXTURE_ID
        neonMain.ImageColor3 = NEON_FUCHSIA
        neonMain.AnchorPoint = Vector2.new(0.5, 0.5)
        neonMain.Position = UDim2.new(0.5, 0, 0.5, 0)
        neonMain.Size = UDim2.new(1.25, 0, 1.25, 0)
        neonMain.ZIndex = 3
        neonMain.Parent = surfGui


        if data.name == "Back" then
            local lightGui = Instance.new("SurfaceGui")
            lightGui.Name = "SouthLightGui"
            lightGui.Face = data.innerFace
            lightGui.CanvasSize = Vector2.new(1000, 1000)
            lightGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
            lightGui.Parent = wall
            
            local lightImg = Instance.new("ImageLabel")
            lightImg.Name = "ExpandingLight"
            lightImg.BackgroundTransparency = 1
            lightImg.Image = "rbxassetid://6673021984"
            lightImg.ImageColor3 = Color3.new(1, 1, 1) 
            lightImg.AnchorPoint = Vector2.new(0.5, 0.5)
            lightImg.Position = UDim2.new(0.5, 0, 0.5, 0)
            lightImg.Size = UDim2.new(0, 0, 0, 0)
            lightImg.ZIndex = 10
            lightImg.Parent = lightGui
        end
    end

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
        smokeEmitter.LightEmission = 0.5 
        smokeEmitter.ZOffset = 0.5 
        smokeEmitter.Color = ColorSequence.new(AFO_BRIGHT_PURPLE)
        smokeEmitter.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 10), NumberSequenceKeypoint.new(1, 35)})
        smokeEmitter.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1), 
            NumberSequenceKeypoint.new(0.3, 0.7),
            NumberSequenceKeypoint.new(1, 1)
        })
        smokeEmitter.Lifetime = NumberRange.new(5, 7)
        smokeEmitter.Rate = 20 
        smokeEmitter.Speed = NumberRange.new(2, 4)
        smokeEmitter.EmissionDirection = emitDirection
        smokeEmitter.Rotation = NumberRange.new(0, 360)
        smokeEmitter.RotSpeed = NumberRange.new(-5, 5)
        smokeEmitter.Parent = polePart
    end


    createSinisterSmoke(topPole, Enum.NormalId.Bottom)
    createSinisterSmoke(bottomPole, Enum.NormalId.Top)

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

    local southPole = Instance.new("Part")
    southPole.Size = Vector3.new(boxSize, boxSize, 2)
    southPole.CFrame = centerCF * CFrame.new(0, 0, half - 1)
    southPole.Anchored = true
    southPole.CanCollide = false
    southPole.Transparency = 1
    southPole.Parent = dimensionFolder
    
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

    local startTime = os.clock()
    local conn
    
    conn = RunService.RenderStepped:Connect(function(dt)
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

        local offsetBg = elapsed * BG_SPEED
        for _, tex in ipairs(scrollingBackgrounds) do
            if tex.Name == "BgUp" then
                tex.OffsetStudsV = -offsetBg
            elseif tex.Name == "BgDown" then
                tex.OffsetStudsV = offsetBg
            end
        end


        for _, wall in ipairs(dimensionFolder:GetChildren()) do
            local gui = wall:FindFirstChild("NeonGui")
            if gui then
                local main = gui:FindFirstChild("NeonMain")
                local glow = gui:FindFirstChild("NeonGlow")
                

                local currentScale = 1 + (alpha * 6)
                if main then
                    main.Rotation = main.Rotation + (dt * 150)
                    main.Size = UDim2.new(currentScale, 0, currentScale, 0)
                end
                if glow then
                    glow.Rotation = glow.Rotation + (dt * 150)
                    glow.Size = UDim2.new(currentScale + 0.1, 0, currentScale + 0.1, 0)
                end
            end


            if wall.Name == "Back" then
                local sGui = wall:FindFirstChild("SouthLightGui")
                if sGui then
                    local lightImg = sGui:FindFirstChild("ExpandingLight")
                    if lightImg then
                        local lightScale = alpha * 18
                        lightImg.Size = UDim2.new(lightScale, 0, lightScale, 0)
                    end
                end
            end
        end
    end)
    return dimensionFolder
end




local function SpawnDiveTunnel(centerCF)
    local tunnelFolder = Instance.new("Folder")
    tunnelFolder.Name = "AFO_Dimension_Effect"
    tunnelFolder.Parent = workspace

    local tunnelWidth = 110
    local tunnelHeight = 104
    local tunnelLength = 300
    local wallThickness = 2
    local halfWidth = tunnelWidth / 2
    local halfHeight = tunnelHeight / 2
    local halfLength = tunnelLength / 2
    local backgroundTexture = "rbxassetid://72194288856630"
    local backgroundColor = Color3.fromRGB(45, 5, 30)
    local neonColor = Color3.fromRGB(210, 35, 255)
    local walls = {
        {name = "Ceiling", offset = CFrame.new(0, halfHeight, 0), size = Vector3.new(tunnelWidth, wallThickness, tunnelLength), face = Enum.NormalId.Bottom},
        {name = "Floor", offset = CFrame.new(0, -halfHeight, 0), size = Vector3.new(tunnelWidth, wallThickness, tunnelLength), face = Enum.NormalId.Top},
        {name = "LeftWall", offset = CFrame.new(-halfWidth, 0, 0), size = Vector3.new(wallThickness, tunnelHeight, tunnelLength), face = Enum.NormalId.Right},
        {name = "RightWall", offset = CFrame.new(halfWidth, 0, 0), size = Vector3.new(wallThickness, tunnelHeight, tunnelLength), face = Enum.NormalId.Left},
        {name = "BackWall", offset = CFrame.new(0, 0, -halfLength), size = Vector3.new(tunnelWidth, tunnelHeight, wallThickness), face = Enum.NormalId.Front},
        {name = "FrontWall", offset = CFrame.new(0, 0, halfLength), size = Vector3.new(tunnelWidth, tunnelHeight, wallThickness), face = Enum.NormalId.Back}
    }
    local scrollingTextures = {}

    for _, wallData in ipairs(walls) do
        local wall = Instance.new("Part")
        wall.Name = wallData.name
        wall.Size = wallData.size
        wall.CFrame = centerCF * wallData.offset
        wall.Anchored = true
        wall.CanCollide = false
        wall.CanTouch = false
        wall.CanQuery = false
        wall.CastShadow = false
        wall.Material = Enum.Material.SmoothPlastic
        wall.Color = Color3.fromRGB(5, 1, 8)
        wall.Parent = tunnelFolder

        local texture = Instance.new("Texture")
        texture.Name = "ScrollingBackground"
        texture.Texture = backgroundTexture
        texture.Face = wallData.face
        texture.Color3 = backgroundColor
        texture.Transparency = 0.12
        texture.StudsPerTileU = 28
        texture.StudsPerTileV = 28
        texture.Parent = wall
        table.insert(scrollingTextures, texture)
    end

    local smokeAnchor = Instance.new("Part")
    smokeAnchor.Name = "CylinderSmokeAnchor"
    smokeAnchor.Size = Vector3.new(1, 1, 1)
    smokeAnchor.CFrame = centerCF
    smokeAnchor.Transparency = 1
    smokeAnchor.Anchored = true
    smokeAnchor.CanCollide = false
    smokeAnchor.CanTouch = false
    smokeAnchor.CanQuery = false
    smokeAnchor.Parent = tunnelFolder

    local smokeTexture = "rbxassetid://13490928216"
    local smokeRadius = math.sqrt((halfWidth * halfWidth) + (halfHeight * halfHeight)) + 1
    local smokeRingCount = 4
    local smokeEmittersPerRing = 14
    for ring = 0, smokeRingCount - 1 do
        local z = -halfLength + ((ring + 0.5) / smokeRingCount) * tunnelLength
        for segment = 0, smokeEmittersPerRing - 1 do
            local angle = (segment / smokeEmittersPerRing) * math.pi * 2
            local sourcePosition = Vector3.new(math.cos(angle) * smokeRadius, math.sin(angle) * smokeRadius, z)
            local inwardDirection = Vector3.new(-math.cos(angle), -math.sin(angle), 0)
            local attachment = Instance.new("Attachment")
            attachment.Name = "CylinderSmokeEmitter"
            attachment.CFrame = CFrame.lookAt(sourcePosition, sourcePosition + inwardDirection)
            attachment.Parent = smokeAnchor

            local smoke = Instance.new("ParticleEmitter")
            smoke.Texture = smokeTexture
            smoke.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(170, 0, 255)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(45, 5, 30))
            })
            smoke.LightEmission = 0.35
            smoke.Rate = 2
            smoke.Lifetime = NumberRange.new(2.5, 4.5)
            smoke.Speed = NumberRange.new(22, 42)
            smoke.SpreadAngle = Vector2.new(18, 18)
            smoke.EmissionDirection = Enum.NormalId.Front
            smoke.Rotation = NumberRange.new(0, 360)
            smoke.RotSpeed = NumberRange.new(-12, 12)
            smoke.Size = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 6),
                NumberSequenceKeypoint.new(0.65, 17),
                NumberSequenceKeypoint.new(1, 26)
            })
            smoke.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.35),
                NumberSequenceKeypoint.new(0.75, 0.65),
                NumberSequenceKeypoint.new(1, 1)
            })
            smoke.Parent = attachment
        end
    end

    local random = Random.new(71337)
    local rushLines = {}
    for index = 1, 72 do
        local edge = random:NextInteger(1, 4)
        local x, y
        if edge == 1 then
            x = -halfWidth + 1.5
            y = random:NextNumber(-halfHeight + 3, halfHeight - 3)
        elseif edge == 2 then
            x = halfWidth - 1.5
            y = random:NextNumber(-halfHeight + 3, halfHeight - 3)
        elseif edge == 3 then
            x = random:NextNumber(-halfWidth + 3, halfWidth - 3)
            y = halfHeight - 1.5
        else
            x = random:NextNumber(-halfWidth + 3, halfWidth - 3)
            y = -halfHeight + 1.5
        end

        local line = Instance.new("Part")
        line.Name = "NeonRushLine"
        line.Anchored = true
        line.CanCollide = false
        line.CanTouch = false
        line.CanQuery = false
        line.CastShadow = false
        line.Material = Enum.Material.Neon
        line.Color = neonColor
        line.Parent = tunnelFolder
        table.insert(rushLines, {
            part = line,
            x = x,
            y = y,
            phase = random:NextNumber(0, tunnelLength),
            speed = random:NextNumber(145, 230),
            width = random:NextNumber(0.08, 0.28)
        })
    end

    local startedAt = os.clock()
    local connection
    connection = RunService.RenderStepped:Connect(function()
        if not tunnelFolder.Parent then
            connection:Disconnect()
            return
        end

        local elapsed = os.clock() - startedAt
        local backgroundOffset = elapsed * 34
        for _, texture in ipairs(scrollingTextures) do
            texture.OffsetStudsV = -backgroundOffset
            texture.OffsetStudsU = backgroundOffset * 0.25
        end

        for _, lineData in ipairs(rushLines) do
            local progress = ((lineData.phase + elapsed * lineData.speed) % tunnelLength) / tunnelLength
            local z = halfLength - (progress * tunnelLength)
            local perspective = 1 - (progress * 0.78)
            local thickness = lineData.width * (2.9 - progress * 2.4)
            local length = 41 - (progress * 38)
            lineData.part.Size = Vector3.new(thickness, thickness, length)
            lineData.part.CFrame = centerCF * CFrame.new(lineData.x * perspective, lineData.y * perspective, z)
            lineData.part.Transparency = 0.1 + (progress * 0.45)
        end
    end)

    return tunnelFolder
end

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

local function ApplyDummyAppearance(rig)
    local rigHum = rig:FindFirstChildOfClass("Humanoid")
    if not rigHum then return end

    local peach = BrickColor.new("Light orange").Color
    local dummyAssets = {
        Hat = "97472955121755",
        Front = "102552048804307",
        LeftShoulder = "115468631813882",
        RightShoulder = "88203090104599",
    }


    for _, v in ipairs(rig:GetChildren()) do
        if v:IsA("Accessory") or v:IsA("Shirt") or v:IsA("Pants") or v:IsA("ShirtGraphic") or v:IsA("BodyColors") or v:IsA("CharacterMesh") then
            v:Destroy()
        end
    end

    local bodyColors = Instance.new("BodyColors")
    bodyColors.HeadColor3 = peach
    bodyColors.LeftArmColor3 = peach
    bodyColors.LeftLegColor3 = peach
    bodyColors.RightArmColor3 = peach
    bodyColors.RightLegColor3 = peach
    bodyColors.TorsoColor3 = peach
    bodyColors.Parent = rig

    for _, part in ipairs(rig:GetChildren()) do
        if part:IsA("BasePart") then
            part.Color = peach
        end
    end

    local shirt = Instance.new("Shirt")
    shirt.ShirtTemplate = "rbxassetid://97549107762722"
    shirt.Parent = rig

    local pants = Instance.new("Pants")
    pants.PantsTemplate = "rbxassetid://90709447311242"
    pants.Parent = rig

    local function getAccessory(assetId)
        local success, loadedAssets = pcall(function()
            return game:GetObjects("rbxassetid://" .. assetId)
        end)
        if not success or not loadedAssets then return nil end

        local accessory
        for _, loaded in ipairs(loadedAssets) do
            local source = loaded:IsA("Accessory") and loaded or loaded:FindFirstChildWhichIsA("Accessory", true)
            if source then accessory = source:Clone() end
            loaded:Destroy()
            if accessory then break end
        end
        return accessory
    end

    local function addAccessory(assetId, scaleFactor)
        local accessory = getAccessory(assetId)
        if not accessory then
            warn("No se pudo cargar el accesorio del dummy: " .. assetId)
            return
        end

        local added = pcall(function() rigHum:AddAccessory(accessory) end)
        local handle = accessory:FindFirstChild("Handle")
        if not (added and handle and handle:FindFirstChild("AccessoryWeld")) then
            manualAttachAccessory(accessory, rig)
        end

        if scaleFactor and handle then
            if handle:IsA("MeshPart") then
                handle.Size = handle.Size * scaleFactor
            end
            local mesh = handle:FindFirstChildOfClass("SpecialMesh")
            if mesh then mesh.Scale = mesh.Scale * scaleFactor end
        end
    end


    addAccessory(dummyAssets.Hat, 4.5)
    addAccessory(dummyAssets.Front, 1.5)
    addAccessory(dummyAssets.LeftShoulder, 1.5)
    addAccessory(dummyAssets.RightShoulder, 1.5)


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

    for _, item in ipairs(cloneChar:GetChildren()) do
        if item:IsA("Accessory") or item:IsA("Hat") or item:IsA("Shirt") or item:IsA("Pants")
            or item:IsA("ShirtGraphic") or item:IsA("BodyColors") or item:IsA("CharacterMesh") then
            item:Destroy()
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

local CRigs, Anims = Asset:FindFirstChild("CosmicRigs"), Asset:FindFirstChild("Anims")
local sceneRig = CRigs and CRigs:FindFirstChild("SceneRig")
local sceneRigCF = sceneRig and sceneRig:GetPivot() or CINEMATIC_CF
if sceneRig then sceneRig:Destroy() end
Asset.Parent = workspace
local Dummy = CRigs and CRigs:FindFirstChild("GOD")
local DummyAnimation = Anims and Anims:FindFirstChild("GOD")
if Dummy then
    Dummy.Name = "Dummy"
    ApplyDummyAppearance(Dummy)
end

local snd = Instance.new("Sound", workspace)
snd.SoundId, snd.Volume = GetCustomResource("Cosmic.mp3", AudioAssetURL), 2

local oldSky = Lighting:FindFirstChildOfClass("Sky")
local sky = Instance.new("Sky")
local secondFlashGui
sky.SkyboxBk, sky.SkyboxDn, sky.SkyboxFt, sky.SkyboxLf, sky.SkyboxRt, sky.SkyboxUp = 
    "rbxassetid://7188341508", "rbxassetid://7188341508", "rbxassetid://7188341508",
    "rbxassetid://7188341508", "rbxassetid://7188341508", "rbxassetid://7188341508"
sky.Parent = Lighting


task.delay(8.5, function() 
    if sky and sky.Parent then sky:Destroy() end
    if oldSky then oldSky.Parent = Lighting end
    
    secondFlashGui = Instance.new("ScreenGui", pGui)
    secondFlashGui.IgnoreGuiInset, secondFlashGui.ResetOnSpawn = true, false
    
    local fade = Instance.new("Frame", secondFlashGui)
    fade.BackgroundColor3, fade.Size = Color3.new(0,0,0), UDim2.new(1,0,1,0)
    fade.BackgroundTransparency = 0
    
    UpdateCloneAppearance()
    

    task.delay(2, function()
        local tw = TweenService:Create(fade, TweenInfo.new(1), {BackgroundTransparency = 1})
        tw:Play()
        tw.Completed:Connect(function()
            if secondFlashGui and secondFlashGui.Parent then secondFlashGui:Destroy() end
        end)
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

local dimensionEffect = SpawnDiveTunnel(sceneRigCF)

pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/AllForOneScripts/Quirks/refs/heads/main/SummonCam.lua"))() end)


local fadeOutTw = TweenService:Create(flashFrame, TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1})
fadeOutTw:Play()
fadeOutTw.Completed:Connect(function() flashGui:Destroy() end)

local bgAnims = {}
if Dummy and DummyAnimation then table.insert(bgAnims, PlayKeyframeSequence(Dummy, DummyAnimation)) end
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

if cameraWatchdog then cameraWatchdog:Disconnect() end
pcall(function() RunService:UnbindFromRenderStep("FollowCinematic") end)
getgenv()._StopCinematic = true 

if snd then
    task.delay(5, function()
        if not snd or not snd.Parent then return end
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


root.Anchored = false

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.FilterDescendantsInstances = {char, cloneChar, workspace:FindFirstChild("AFO_Dimension_Effect")}

local actualGroundY = originalGroundY
local rayResult = workspace:Raycast(finalPos + Vector3.new(0, 100, 0), Vector3.new(0, -500, 0), rayParams)

if rayResult then
    actualGroundY = rayResult.Position.Y
end

local rootOffset = (hum.HipHeight + (root.Size.Y / 2))
local finalTargetCF = CFrame.new(finalPos.X, actualGroundY + rootOffset, finalPos.Z) * finalRot


root.CFrame = finalTargetCF
root.AssemblyLinearVelocity = Vector3.zero
root.AssemblyAngularVelocity = Vector3.zero


local isPinned = true
local startHealth = hum.Health

local damageConn
damageConn = hum.HealthChanged:Connect(function(newHealth)
    if newHealth < startHealth then
        isPinned = false
    end
    startHealth = newHealth
end)

local pinTime = 0
local pinConn
pinConn = RunService.Heartbeat:Connect(function(dt)
    if not root or not root.Parent then
        isPinned = false
    end

    pinTime = pinTime + dt

    if not isPinned or pinTime >= 2 then
        if pinConn then pinConn:Disconnect() end
        if damageConn then damageConn:Disconnect() end
        return
    end


    root.CFrame = CFrame.new(root.Position.X, finalTargetCF.Y, root.Position.Z) * (root.CFrame - root.CFrame.Position)
    root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, 0, root.AssemblyLinearVelocity.Z)
end)

hum.PlatformStand = false
hum:ChangeState(Enum.HumanoidStateType.Landed)

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
ResetCinematicBodyAndCamera()

local function CleanupCinematicArtifacts()
    for _, animation in ipairs(bgAnims) do
        animation:Stop()
    end
    if dimensionEffect and dimensionEffect.Parent then dimensionEffect:Destroy() end
    if Asset and Asset.Parent then Asset:Destroy() end
    if snd and snd.Parent then snd:Stop(); snd:Destroy() end
    if sky and sky.Parent then sky:Destroy() end
    if flashGui and flashGui.Parent then flashGui:Destroy() end
    if secondFlashGui and secondFlashGui.Parent then secondFlashGui:Destroy() end
    if camProxy then camProxy:Destroy() end
    if fovProxy then fovProxy:Destroy() end
    if animObj then animObj:Destroy() end
end

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
    
    CleanupCinematicArtifacts()
    FreeCinematic()
end)
