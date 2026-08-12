if getgenv()._GarouAnimRunning then
    warn("La cinemática ya está en curso. Ignorando ejecución.")
    return
end
getgenv()._GarouAnimRunning = true
local function LiberarCinematica()
    getgenv()._GarouAnimRunning = false
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local ContentProvider = game:GetService("ContentProvider")
local player = Players.LocalPlayer
local cam = workspace.CurrentCamera
local pGui = player:WaitForChild("PlayerGui")

-- Flash de entrada
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

-- ============================================================
-- GUARDIÁN DE CÁMARA (Evita que el juego recupere la cámara)
-- ============================================================
local cameraWatchdog = RunService.Heartbeat:Connect(function()
    if cam.CameraType ~= Enum.CameraType.Scriptable then
        cam.CameraType = Enum.CameraType.Scriptable
    end
end)

-- ============================================================
-- POSICIÓN ORIGINAL DEL JUGADOR
-- ============================================================
local oldCF = root.CFrame
local oldAutoRotate = hum.AutoRotate
hum.AutoRotate = false
local originalRootPos = root.Position
local originalGroundY = originalRootPos.Y

-- ============================================================
-- 1. CREAR CLON EN POSICIÓN FIJA (CINEMÁTICA)
-- ============================================================
pcall(function() char.Archivable = true end)
local cloneChar = char:Clone()
pcall(function() char.Archivable = false end)

if not cloneChar then
    warn("No se pudo clonar el personaje. Abortando.")
    flashGui:Destroy()
    if cameraWatchdog then cameraWatchdog:Disconnect() end
    LiberarCinematica()
    return
end

-- Limpiar scripts del clon
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

-- Posición fija de la cinemática
local CINEMATIC_CF = CFrame.new(876.2, 1882, -397.6, -0.56, 0, 0.82, 0, 1, 0, -0.82, 0, -0.56)
cloneChar:PivotTo(CINEMATIC_CF)
cloneChar.Parent = workspace

if cloneChar:FindFirstChild("Humanoid") then
    cloneChar.Humanoid.NameDisplayDistance = 0
end

_G.cloneRoot = cloneRoot
_G.cloneChar = cloneChar

-- ============================================================
-- 2. OCULTAR Y ELEVAR AL PERSONAJE REAL (MODO 4D ESTÁTICO)
-- ============================================================
local originalParts = {}
for _, part in ipairs(char:GetDescendants()) do
    if part:IsA("BasePart") then
        originalParts[part] = {
            LocalTransparencyModifier = part.LocalTransparencyModifier,
            Transparency = part.Transparency,
            CanCollide = part.CanCollide,
            CanTouch = part.CanTouch,
        }
        part.LocalTransparencyModifier = 1  
        part.CanCollide = false
        part.CanTouch = false
    end
end
for _, acc in ipairs(char:GetChildren()) do
    if acc:IsA("Accessory") then
        local handle = acc:FindFirstChild("Handle")
        if handle and handle:IsA("BasePart") then
            originalParts[handle] = {
                LocalTransparencyModifier = handle.LocalTransparencyModifier,
                Transparency = handle.Transparency,
                CanCollide = handle.CanCollide,
                CanTouch = handle.CanTouch,
            }
            handle.LocalTransparencyModifier = 1
        end
    end
end

local SKY_ALTITUDE = 1500
local skyY = originalGroundY + SKY_ALTITUDE

hum.PlatformStand = true
root.Anchored = true 
root.CFrame = CFrame.new(originalRootPos.X, skyY, originalRootPos.Z)

-- ============================================================
-- 3. CONTINUAR CON EL RESTO DEL SCRIPT ORIGINAL
-- ============================================================
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
local AnimAssetURL = "https://github.com/ian49972/RBXMS/raw/refs/heads/main/CosmicG.rbxmx"
local AudioAssetURL = "https://github.com/ian49972/smth/raw/refs/heads/main/Cosmic.mp3"

-- Funciones auxiliares para apariencia (JAIDEN)
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
    
    if not successId or not userId then 
        warn("No se pudo obtener el ID del jugador: " .. targetUsername)
        return 
    end
    
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

-- ============================================================
-- 4. CARGAR ASSET
-- ============================================================
local s, Asset = pcall(function() return game:GetObjects(GetCustomResource("CosmicG.rbxmx", AnimAssetURL))[1] end)
if not s or not Asset then
    flashGui:Destroy()
    RestoreHighlights()
    if cameraWatchdog then cameraWatchdog:Disconnect() end
    if animator then animator.Parent = hum end
    if animateScript then animateScript.Disabled = false end
    LiberarCinematica()
    return
end
Asset.Parent = workspace
local CRigs, Anims = Asset:FindFirstChild("CosmicRigs"), Asset:FindFirstChild("Anims")
if CRigs.GOD then ApplyJaidenAppearance(CRigs.GOD) end

-- ============================================================
-- 5. CONFIGURAR CÁMARA Y REPRODUCIR CINEMÁTICA
-- ============================================================
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
pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/AllForOneScripts/Quirks/refs/heads/main/SummonCam.lua"))() end)

local fadeOutTw = TweenService:Create(flashFrame, TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1})
fadeOutTw:Play()
fadeOutTw.Completed:Connect(function() flashGui:Destroy() end)

-- ============================================================
-- 6. REPRODUCIR ANIMACIONES (SOBRE EL CLON)
-- ============================================================
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

-- ============================================================
-- MOVER CLON AL POLO A TIERRA
-- ============================================================
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

-- ============================================================
-- 7. PREPARAR RESTAURACIÓN Y DETENER LUCHA DE CÁMARAS
-- ============================================================
-- Apagamos el Guardián porque nosotros tomaremos el control manual ahora
if cameraWatchdog then cameraWatchdog:Disconnect() end

-- Desvincular de forma agresiva cualquier residuo de SummonCam
pcall(function() RunService:UnbindFromRenderStep("FollowCinematic") end)
getgenv()._StopCinematic = true -- Flag de seguridad común por si SummonCam lo lee

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

hum.PlatformStand = false
root.Anchored = false
root.CFrame = targetCF
root.AssemblyLinearVelocity = Vector3.zero
root.AssemblyAngularVelocity = Vector3.zero

for part, data in pairs(originalParts) do
    if part and part.Parent then
        part.LocalTransparencyModifier = data.LocalTransparencyModifier
        part.Transparency = data.Transparency
        part.CanCollide = data.CanCollide
        part.CanTouch = data.CanTouch
    end
end

hum.PlatformStand = false
hum.AutoRotate = oldAutoRotate

if cloneChar then cloneChar:Destroy() end
_G.cloneRoot = nil
_G.cloneChar = nil

-- ============================================================
-- APLICAR ANIMACIÓN FINAL (18941564777) ANTES DE RESTAURAR CÁMARA
-- ============================================================
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

-- ============================================================
-- RESTAURAR CÁMARA (TWEEN POR PROXY INFALIBLE)
-- ============================================================
local targetOffset = oldCF * CFrame.new(0, 2, 12)
local targetCameraCFrame = CFrame.lookAt(targetOffset.Position, oldCF.Position)

-- En lugar de afectar a la cámara directamente (lo que causa tirones por luchas de RenderStepped),
-- Animamos valores abstractos (Proxies) y forzamos su aplicación.
local camProxy = Instance.new("CFrameValue")
camProxy.Value = cam.CFrame

local fovProxy = Instance.new("NumberValue")
fovProxy.Value = cam.FieldOfView

-- Bindeamos un override absoluto con la máxima prioridad (Camera + 200). 
-- Esto APLASTA cualquier modificación que intente hacer el juego u otros scripts.
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

-- Una vez terminado el tween suave, soltamos nuestro control absoluto
RunService:UnbindFromRenderStep(overrideId)

cam.CameraSubject = hum
cam.CameraType = Enum.CameraType.Custom

-- ============================================================
-- DESVANECER ANIMACIÓN FINAL Y REACTIVAR Animate
-- ============================================================
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
    
    LiberarCinematica()
end)
