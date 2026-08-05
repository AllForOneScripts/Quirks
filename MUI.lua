--[[
    MasteredUltraInstinct4DDodge.lua
    Client module for a Roblox experience you control.

    Detects configured remote animation tracks, warns locally about their
    source, and activates a temporary Mastered Ultra Instinct 4D defense.
]]

local M = {}

local MasteredUltraInstinctPlayers = game:GetService("Players")
local MasteredUltraInstinctRunService = game:GetService("RunService")
local MasteredUltraInstinctUserInputService = game:GetService("UserInputService")
local MasteredUltraInstinctTweenService = game:GetService("TweenService")
local MasteredUltraInstinctDebris = game:GetService("Debris")
local MasteredUltraInstinctSoundService = game:GetService("SoundService")
local MasteredUltraInstinctContentProvider = game:GetService("ContentProvider")

M.Config = {
    Dodges = {
        Bakugo_Nuker = {
            AnimationId = "18673594132",
            Delay = 5,
            Duration = 5,
            ExtendUntilSourceDies = true,
        },
    },

    SkyAltitude = 1500,
    LiftSpeed = 900,
    LiftTimeout = 4,
    HoldForce = 9e8,
    SameAnimationCooldown = 0.20,
    RefreshOnRepeatedTrigger = true,

    AllowCloneMovement = true,
    CloneWalkSpeed = 105,
    CloneHeadOffset = 3,
    GroundProbeHeight = 220,
    GroundProbeDepth = 520,
    MaxGroundStepPerSecond = 28,

    ActivationSoundId = "140694363106746",
    DeactivationSoundId = "130457690489621",
    SoundVolume = 1.35,

    Aura = {
        Enabled = true,
        CoreColor = Color3.fromRGB(245, 250, 255),
        CyanColor = Color3.fromRGB(95, 225, 255),
        VioletColor = Color3.fromRGB(156, 115, 255),
        ParticleRate = 56,
        RingSegments = 18,
        UpdateInterval = 1 / 30,
    },

    ThreatAlertLifetime = 8,
    ThreatHudTopOffset = 330, -- Deliberately below the CopyAvatar panel.
    ThreatHudRightOffset = 18,
    ThreatLineOuterThickness = 18,
    ThreatLineInnerThickness = 8,
    ThreatFarLightRange = 72,
}

-- All state is private and prefixed to make it easy to identify in a hub.
local MasteredUltraInstinctEnabled = false
local MasteredUltraInstinctLocalPlayer = nil
local MasteredUltraInstinctDefenseActive = false
local MasteredUltraInstinctActivationToken = 0
local MasteredUltraInstinctPendingToken = 0
local MasteredUltraInstinctPendingDodge = nil
local MasteredUltraInstinctActiveUntil = 0
local MasteredUltraInstinctActiveDuration = 0
local MasteredUltraInstinctActiveDodgeName = nil
local MasteredUltraInstinctActiveSource = nil
local MasteredUltraInstinctExtendUntilSourceDies = false
local MasteredUltraInstinctSourceDied = false

local MasteredUltraInstinctDodgeByAnimationId = {}
local MasteredUltraInstinctLastTriggerAt = {}
local MasteredUltraInstinctPlayerWatches = {}
local MasteredUltraInstinctThreats = {}
local MasteredUltraInstinctThumbnailCache = {}
local MasteredUltraInstinctOriginalTransparency = setmetatable({}, { __mode = "k" })

local MasteredUltraInstinctHeartbeatConnection = nil
local MasteredUltraInstinctRenderConnection = nil
local MasteredUltraInstinctPlayerAddedConnection = nil
local MasteredUltraInstinctPlayerRemovingConnection = nil
local MasteredUltraInstinctCharacterRemovingConnection = nil
local MasteredUltraInstinctSourceDiedConnection = nil

local MasteredUltraInstinctCloneModel = nil
local MasteredUltraInstinctCloneRoot = nil
local MasteredUltraInstinctAuraFolder = nil
local MasteredUltraInstinctAuraRings = {}
local MasteredUltraInstinctAuraLight = nil
local MasteredUltraInstinctCameraSubject = nil
local MasteredUltraInstinctSkyVelocity = nil
local MasteredUltraInstinctSkyPosition = nil
local MasteredUltraInstinctVirtualRootPosition = nil
local MasteredUltraInstinctSkyY = nil
local MasteredUltraInstinctFootOffset = 3
local MasteredUltraInstinctHud = nil
local MasteredUltraInstinctHudCards = nil
local MasteredUltraInstinctHudLines = nil
local MasteredUltraInstinctLastHudUpdate = 0
local MasteredUltraInstinctLastAuraUpdate = 0

local function MasteredUltraInstinctDisconnect(MasteredUltraInstinctConnection)
    if MasteredUltraInstinctConnection then
        pcall(function()
            MasteredUltraInstinctConnection:Disconnect()
        end)
    end
end

local function MasteredUltraInstinctAssetNumber(MasteredUltraInstinctValue)
    return tostring(MasteredUltraInstinctValue or ""):match("%d+") or ""
end

local function MasteredUltraInstinctAssetId(MasteredUltraInstinctValue)
    local MasteredUltraInstinctId = MasteredUltraInstinctAssetNumber(MasteredUltraInstinctValue)
    return MasteredUltraInstinctId ~= "" and "rbxassetid://" .. MasteredUltraInstinctId or ""
end

local function MasteredUltraInstinctGetRoot(MasteredUltraInstinctCharacter)
    return MasteredUltraInstinctCharacter
        and (MasteredUltraInstinctCharacter:FindFirstChild("HumanoidRootPart")
            or MasteredUltraInstinctCharacter:FindFirstChild("Torso"))
end

local function MasteredUltraInstinctGetHumanoid(MasteredUltraInstinctCharacter)
    return MasteredUltraInstinctCharacter
        and MasteredUltraInstinctCharacter:FindFirstChildOfClass("Humanoid")
end

local function MasteredUltraInstinctGetFootOffset(MasteredUltraInstinctCharacter)
    local MasteredUltraInstinctHumanoid = MasteredUltraInstinctGetHumanoid(MasteredUltraInstinctCharacter)
    local MasteredUltraInstinctRoot = MasteredUltraInstinctGetRoot(MasteredUltraInstinctCharacter)
    if MasteredUltraInstinctHumanoid and MasteredUltraInstinctRoot then
        return MasteredUltraInstinctHumanoid.HipHeight + MasteredUltraInstinctRoot.Size.Y * 0.5
    end
    return 3
end

local function MasteredUltraInstinctMergeConfig(MasteredUltraInstinctTarget, MasteredUltraInstinctSource)
    for MasteredUltraInstinctKey, MasteredUltraInstinctValue in pairs(MasteredUltraInstinctSource) do
        if MasteredUltraInstinctKey ~= "Dodges"
            and type(MasteredUltraInstinctValue) == "table"
            and type(MasteredUltraInstinctTarget[MasteredUltraInstinctKey]) == "table" then
            MasteredUltraInstinctMergeConfig(
                MasteredUltraInstinctTarget[MasteredUltraInstinctKey],
                MasteredUltraInstinctValue
            )
        else
            MasteredUltraInstinctTarget[MasteredUltraInstinctKey] = MasteredUltraInstinctValue
        end
    end
end

local function MasteredUltraInstinctRebuildDodgeIndex()
    table.clear(MasteredUltraInstinctDodgeByAnimationId)
    for MasteredUltraInstinctName, MasteredUltraInstinctDodge in pairs(M.Config.Dodges) do
        local MasteredUltraInstinctId = MasteredUltraInstinctAssetNumber(MasteredUltraInstinctDodge.AnimationId)
        local MasteredUltraInstinctDelay = tonumber(MasteredUltraInstinctDodge.Delay) or 0
        local MasteredUltraInstinctDuration = tonumber(MasteredUltraInstinctDodge.Duration)
        if MasteredUltraInstinctId ~= ""
            and MasteredUltraInstinctDelay >= 0
            and MasteredUltraInstinctDuration
            and MasteredUltraInstinctDuration > 0 then
            MasteredUltraInstinctDodgeByAnimationId[MasteredUltraInstinctId] = {
                Name = MasteredUltraInstinctName,
                Delay = MasteredUltraInstinctDelay,
                Duration = MasteredUltraInstinctDuration,
                ExtendUntilSourceDies = MasteredUltraInstinctDodge.ExtendUntilSourceDies == true,
            }
        end
    end
end

-- Sounds are parented to SoundService and locally preloaded. This handles the
-- common failure mode where a short-lived Sound is destroyed before it loads.
local function MasteredUltraInstinctPlayLocalSound(MasteredUltraInstinctSoundId)
    local MasteredUltraInstinctResolvedId = MasteredUltraInstinctAssetId(MasteredUltraInstinctSoundId)
    if MasteredUltraInstinctResolvedId == "" then
        return
    end

    local MasteredUltraInstinctSound = Instance.new("Sound")
    MasteredUltraInstinctSound.Name = "MasteredUltraInstinctSound"
    MasteredUltraInstinctSound.SoundId = MasteredUltraInstinctResolvedId
    MasteredUltraInstinctSound.Volume = M.Config.SoundVolume
    MasteredUltraInstinctSound.Parent = MasteredUltraInstinctSoundService
    MasteredUltraInstinctDebris:AddItem(MasteredUltraInstinctSound, 12)

    task.spawn(function()
        pcall(function()
            MasteredUltraInstinctContentProvider:PreloadAsync({ MasteredUltraInstinctSound })
        end)
    end)
    local MasteredUltraInstinctPlayed = pcall(function()
        if MasteredUltraInstinctSoundService.PlayLocalSound then
            MasteredUltraInstinctSoundService:PlayLocalSound(MasteredUltraInstinctSound)
        else
            MasteredUltraInstinctSound:Play()
        end
    end)
    if not MasteredUltraInstinctPlayed then
        pcall(function()
            MasteredUltraInstinctSound:Play()
        end)
    end
end

local function MasteredUltraInstinctDestroySkyForces()
    if MasteredUltraInstinctSkyVelocity then
        MasteredUltraInstinctSkyVelocity:Destroy()
        MasteredUltraInstinctSkyVelocity = nil
    end
    if MasteredUltraInstinctSkyPosition then
        MasteredUltraInstinctSkyPosition:Destroy()
        MasteredUltraInstinctSkyPosition = nil
    end
end

local function MasteredUltraInstinctDestroyClone()
    if MasteredUltraInstinctCloneModel then
        MasteredUltraInstinctCloneModel:Destroy()
    end
    MasteredUltraInstinctCloneModel = nil
    MasteredUltraInstinctCloneRoot = nil
    MasteredUltraInstinctAuraFolder = nil
    MasteredUltraInstinctAuraRings = {}
    MasteredUltraInstinctAuraLight = nil
end

local function MasteredUltraInstinctDestroyCameraSubject()
    if MasteredUltraInstinctCameraSubject then
        MasteredUltraInstinctCameraSubject:Destroy()
    end
    MasteredUltraInstinctCameraSubject = nil
end

local function MasteredUltraInstinctHideRealCharacter(MasteredUltraInstinctCharacter)
    table.clear(MasteredUltraInstinctOriginalTransparency)
    for _, MasteredUltraInstinctInstance in ipairs(MasteredUltraInstinctCharacter:GetDescendants()) do
        if MasteredUltraInstinctInstance:IsA("BasePart") or MasteredUltraInstinctInstance:IsA("Decal") then
            MasteredUltraInstinctOriginalTransparency[MasteredUltraInstinctInstance] =
                MasteredUltraInstinctInstance.LocalTransparencyModifier
            MasteredUltraInstinctInstance.LocalTransparencyModifier = 1
        end
    end
end

local function MasteredUltraInstinctRestoreRealCharacter()
    for MasteredUltraInstinctInstance, MasteredUltraInstinctTransparency in pairs(MasteredUltraInstinctOriginalTransparency) do
        if MasteredUltraInstinctInstance.Parent then
            pcall(function()
                MasteredUltraInstinctInstance.LocalTransparencyModifier = MasteredUltraInstinctTransparency
            end)
        end
    end
    table.clear(MasteredUltraInstinctOriginalTransparency)
end

local function MasteredUltraInstinctCreateClone(MasteredUltraInstinctCharacter, MasteredUltraInstinctStartCFrame)
    local MasteredUltraInstinctPreviousArchivable = MasteredUltraInstinctCharacter.Archivable
    MasteredUltraInstinctCharacter.Archivable = true
    local MasteredUltraInstinctOk, MasteredUltraInstinctClone = pcall(function()
        return MasteredUltraInstinctCharacter:Clone()
    end)
    MasteredUltraInstinctCharacter.Archivable = MasteredUltraInstinctPreviousArchivable
    if not MasteredUltraInstinctOk or not MasteredUltraInstinctClone then
        return nil, nil
    end

    MasteredUltraInstinctClone.Name = "MasteredUltraInstinctClone"
    for _, MasteredUltraInstinctInstance in ipairs(MasteredUltraInstinctClone:GetDescendants()) do
        if MasteredUltraInstinctInstance:IsA("Script")
            or MasteredUltraInstinctInstance:IsA("LocalScript")
            or MasteredUltraInstinctInstance:IsA("ModuleScript") then
            MasteredUltraInstinctInstance:Destroy()
        elseif MasteredUltraInstinctInstance:IsA("BasePart") then
            MasteredUltraInstinctInstance.Anchored = true
            MasteredUltraInstinctInstance.CanCollide = false
            MasteredUltraInstinctInstance.CanTouch = false
            MasteredUltraInstinctInstance.CanQuery = false
            MasteredUltraInstinctInstance.CastShadow = false
        elseif MasteredUltraInstinctInstance:IsA("Humanoid") then
            MasteredUltraInstinctInstance.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
            MasteredUltraInstinctInstance.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
            MasteredUltraInstinctInstance.AutoRotate = false
        end
    end

    MasteredUltraInstinctClone.Parent = workspace
    MasteredUltraInstinctClone:PivotTo(MasteredUltraInstinctStartCFrame)
    return MasteredUltraInstinctClone, MasteredUltraInstinctGetRoot(MasteredUltraInstinctClone)
end

local function MasteredUltraInstinctCreateCameraSubject(MasteredUltraInstinctPosition)
    local MasteredUltraInstinctSubject = Instance.new("Part")
    MasteredUltraInstinctSubject.Name = "MasteredUltraInstinctCameraSubject"
    MasteredUltraInstinctSubject.Size = Vector3.one
    MasteredUltraInstinctSubject.Transparency = 1
    MasteredUltraInstinctSubject.Anchored = true
    MasteredUltraInstinctSubject.CanCollide = false
    MasteredUltraInstinctSubject.CanTouch = false
    MasteredUltraInstinctSubject.CanQuery = false
    MasteredUltraInstinctSubject.CFrame = CFrame.new(
        MasteredUltraInstinctPosition + Vector3.new(0, M.Config.CloneHeadOffset, 0)
    )
    MasteredUltraInstinctSubject.Parent = workspace
    return MasteredUltraInstinctSubject
end

-- The original aura is retained, but its instances are created once and only
-- their transforms are touched while the 4D defense is active.
local function MasteredUltraInstinctCreateParticle(
    MasteredUltraInstinctParent,
    MasteredUltraInstinctColor,
    MasteredUltraInstinctRate,
    MasteredUltraInstinctSpeed,
    MasteredUltraInstinctLifetime,
    MasteredUltraInstinctSize,
    MasteredUltraInstinctTransparency
)
    local MasteredUltraInstinctEmitter = Instance.new("ParticleEmitter")
    MasteredUltraInstinctEmitter.Texture = "rbxasset://textures/particles/smoke_main.dds"
    MasteredUltraInstinctEmitter.Color = ColorSequence.new(MasteredUltraInstinctColor)
    MasteredUltraInstinctEmitter.LightEmission = 0.9
    MasteredUltraInstinctEmitter.LightInfluence = 0
    MasteredUltraInstinctEmitter.Rate = MasteredUltraInstinctRate
    MasteredUltraInstinctEmitter.Lifetime = MasteredUltraInstinctLifetime
    MasteredUltraInstinctEmitter.Speed = MasteredUltraInstinctSpeed
    MasteredUltraInstinctEmitter.Acceleration = Vector3.new(0, 10, 0)
    MasteredUltraInstinctEmitter.SpreadAngle = Vector2.new(22, 22)
    MasteredUltraInstinctEmitter.EmissionDirection = Enum.NormalId.Top
    MasteredUltraInstinctEmitter.Size = MasteredUltraInstinctSize
    MasteredUltraInstinctEmitter.Transparency = MasteredUltraInstinctTransparency
    MasteredUltraInstinctEmitter.Parent = MasteredUltraInstinctParent
end

local function MasteredUltraInstinctCreateAuraRing(
    MasteredUltraInstinctFolder,
    MasteredUltraInstinctColor,
    MasteredUltraInstinctRadius,
    MasteredUltraInstinctYOffset,
    MasteredUltraInstinctPhase
)
    local MasteredUltraInstinctRing = {
        Parts = {},
        Radius = MasteredUltraInstinctRadius,
        YOffset = MasteredUltraInstinctYOffset,
        Phase = MasteredUltraInstinctPhase,
    }
    local MasteredUltraInstinctSegments = math.max(8, math.floor(M.Config.Aura.RingSegments))
    for _ = 1, MasteredUltraInstinctSegments do
        local MasteredUltraInstinctPart = Instance.new("Part")
        MasteredUltraInstinctPart.Name = "MasteredUltraInstinctAuraRing"
        MasteredUltraInstinctPart.Anchored = true
        MasteredUltraInstinctPart.CanCollide = false
        MasteredUltraInstinctPart.CanTouch = false
        MasteredUltraInstinctPart.CanQuery = false
        MasteredUltraInstinctPart.CastShadow = false
        MasteredUltraInstinctPart.Material = Enum.Material.Neon
        MasteredUltraInstinctPart.Color = MasteredUltraInstinctColor
        MasteredUltraInstinctPart.Transparency = 0.32
        MasteredUltraInstinctPart.Size = Vector3.new(0.12, 0.12, 0.12)
        MasteredUltraInstinctPart.Parent = MasteredUltraInstinctFolder
        table.insert(MasteredUltraInstinctRing.Parts, MasteredUltraInstinctPart)
    end
    return MasteredUltraInstinctRing
end

local function MasteredUltraInstinctCreateAura()
    if not M.Config.Aura.Enabled or not MasteredUltraInstinctCloneRoot or not MasteredUltraInstinctCloneModel then
        return
    end
    local MasteredUltraInstinctConfig = M.Config.Aura
    MasteredUltraInstinctAuraFolder = Instance.new("Folder")
    MasteredUltraInstinctAuraFolder.Name = "MasteredUltraInstinctAura"
    MasteredUltraInstinctAuraFolder.Parent = MasteredUltraInstinctCloneModel
    local MasteredUltraInstinctLower = Instance.new("Attachment")
    MasteredUltraInstinctLower.Position = Vector3.new(0, -2.2, 0)
    MasteredUltraInstinctLower.Parent = MasteredUltraInstinctCloneRoot
    local MasteredUltraInstinctUpper = Instance.new("Attachment")
    MasteredUltraInstinctUpper.Position = Vector3.new(0, 2.2, 0)
    MasteredUltraInstinctUpper.Parent = MasteredUltraInstinctCloneRoot
    MasteredUltraInstinctCreateParticle(
        MasteredUltraInstinctLower, MasteredUltraInstinctConfig.CyanColor,
        MasteredUltraInstinctConfig.ParticleRate, NumberRange.new(4, 8), NumberRange.new(0.46, 0.82),
        NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.9), NumberSequenceKeypoint.new(0.45, 2.1), NumberSequenceKeypoint.new(1, 0.15) }),
        NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.38), NumberSequenceKeypoint.new(0.65, 0.58), NumberSequenceKeypoint.new(1, 1) })
    )
    MasteredUltraInstinctCreateParticle(
        MasteredUltraInstinctUpper, MasteredUltraInstinctConfig.VioletColor,
        math.floor(MasteredUltraInstinctConfig.ParticleRate * 0.42), NumberRange.new(2, 5), NumberRange.new(0.55, 1.05),
        NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(0.5, 1.45), NumberSequenceKeypoint.new(1, 0.05) }),
        NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(1, 1) })
    )
    MasteredUltraInstinctAuraLight = Instance.new("PointLight")
    MasteredUltraInstinctAuraLight.Name = "MasteredUltraInstinctAuraGlow"
    MasteredUltraInstinctAuraLight.Color = MasteredUltraInstinctConfig.CyanColor
    MasteredUltraInstinctAuraLight.Brightness = 1.8
    MasteredUltraInstinctAuraLight.Range = 18
    MasteredUltraInstinctAuraLight.Shadows = false
    MasteredUltraInstinctAuraLight.Parent = MasteredUltraInstinctCloneRoot
    MasteredUltraInstinctAuraRings = {
        MasteredUltraInstinctCreateAuraRing(MasteredUltraInstinctAuraFolder, MasteredUltraInstinctConfig.CoreColor, 3.2, -1.7, 0),
        MasteredUltraInstinctCreateAuraRing(MasteredUltraInstinctAuraFolder, MasteredUltraInstinctConfig.CyanColor, 4.7, -0.1, math.pi),
        MasteredUltraInstinctCreateAuraRing(MasteredUltraInstinctAuraFolder, MasteredUltraInstinctConfig.VioletColor, 3.8, 1.6, math.pi * 0.5),
    }
end

local function MasteredUltraInstinctUpdateAura(MasteredUltraInstinctNow)
    if not MasteredUltraInstinctCloneRoot then
        return
    end
    for MasteredUltraInstinctRingIndex, MasteredUltraInstinctRing in ipairs(MasteredUltraInstinctAuraRings) do
        local MasteredUltraInstinctCount = #MasteredUltraInstinctRing.Parts
        local MasteredUltraInstinctRadius = MasteredUltraInstinctRing.Radius + math.sin(MasteredUltraInstinctNow * 3.2 + MasteredUltraInstinctRing.Phase) * 0.18
        local MasteredUltraInstinctY = MasteredUltraInstinctRing.YOffset + math.sin(MasteredUltraInstinctNow * 2.4 + MasteredUltraInstinctRing.Phase) * 0.22
        local MasteredUltraInstinctRotation = MasteredUltraInstinctNow
            * (MasteredUltraInstinctRingIndex % 2 == 0 and -1.6 or 1.25)
            + MasteredUltraInstinctRing.Phase
        local MasteredUltraInstinctArc = (2 * math.pi * MasteredUltraInstinctRadius / MasteredUltraInstinctCount) * 0.82
        for MasteredUltraInstinctIndex, MasteredUltraInstinctPart in ipairs(MasteredUltraInstinctRing.Parts) do
            local MasteredUltraInstinctAngle = MasteredUltraInstinctRotation
                + (MasteredUltraInstinctIndex - 1) / MasteredUltraInstinctCount * math.pi * 2
            local MasteredUltraInstinctRadial = Vector3.new(math.cos(MasteredUltraInstinctAngle), 0, math.sin(MasteredUltraInstinctAngle))
            local MasteredUltraInstinctTangent = Vector3.new(-math.sin(MasteredUltraInstinctAngle), 0, math.cos(MasteredUltraInstinctAngle))
            local MasteredUltraInstinctPosition = MasteredUltraInstinctCloneRoot.Position
                + MasteredUltraInstinctRadial * MasteredUltraInstinctRadius + Vector3.new(0, MasteredUltraInstinctY, 0)
            MasteredUltraInstinctPart.Size = Vector3.new(0.09, 0.09, MasteredUltraInstinctArc)
            MasteredUltraInstinctPart.CFrame = CFrame.lookAt(MasteredUltraInstinctPosition, MasteredUltraInstinctPosition + MasteredUltraInstinctTangent)
            MasteredUltraInstinctPart.Transparency = 0.25 + math.abs(math.sin(MasteredUltraInstinctNow * 4 + MasteredUltraInstinctIndex)) * 0.35
        end
    end
    if MasteredUltraInstinctAuraLight then
        MasteredUltraInstinctAuraLight.Brightness = 1.4 + (math.sin(MasteredUltraInstinctNow * 7) + 1) * 0.65
    end
end

local function MasteredUltraInstinctGroundPosition(MasteredUltraInstinctPosition, MasteredUltraInstinctCharacter)
    local MasteredUltraInstinctRayParams = RaycastParams.new()
    MasteredUltraInstinctRayParams.FilterType = Enum.RaycastFilterType.Exclude
    MasteredUltraInstinctRayParams.FilterDescendantsInstances = {
        MasteredUltraInstinctCharacter,
        MasteredUltraInstinctCloneModel,
        MasteredUltraInstinctCameraSubject,
    }
    local MasteredUltraInstinctOrigin = Vector3.new(
        MasteredUltraInstinctPosition.X,
        MasteredUltraInstinctPosition.Y + M.Config.GroundProbeHeight,
        MasteredUltraInstinctPosition.Z
    )
    local MasteredUltraInstinctHit = workspace:Raycast(
        MasteredUltraInstinctOrigin,
        Vector3.new(0, -M.Config.GroundProbeDepth, 0),
        MasteredUltraInstinctRayParams
    )
    if MasteredUltraInstinctHit then
        return Vector3.new(
            MasteredUltraInstinctPosition.X,
            MasteredUltraInstinctHit.Position.Y + MasteredUltraInstinctFootOffset,
            MasteredUltraInstinctPosition.Z
        )
    end
    return MasteredUltraInstinctPosition
end

local function MasteredUltraInstinctBuildHud()
    if MasteredUltraInstinctHud and MasteredUltraInstinctHud.Parent then
        return
    end
    local MasteredUltraInstinctPlayerGui = MasteredUltraInstinctLocalPlayer:FindFirstChildOfClass("PlayerGui")
    if not MasteredUltraInstinctPlayerGui then
        return
    end

    MasteredUltraInstinctHud = Instance.new("ScreenGui")
    MasteredUltraInstinctHud.Name = "MasteredUltraInstinctThreatHUD"
    MasteredUltraInstinctHud.IgnoreGuiInset = true
    MasteredUltraInstinctHud.ResetOnSpawn = false
    MasteredUltraInstinctHud.DisplayOrder = 75
    MasteredUltraInstinctHud.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    MasteredUltraInstinctHud.Parent = MasteredUltraInstinctPlayerGui

    MasteredUltraInstinctHudCards = Instance.new("Frame")
    MasteredUltraInstinctHudCards.Name = "MasteredUltraInstinctThreatCards"
    MasteredUltraInstinctHudCards.BackgroundTransparency = 1
    MasteredUltraInstinctHudCards.Size = UDim2.fromScale(1, 1)
    MasteredUltraInstinctHudCards.Parent = MasteredUltraInstinctHud

    MasteredUltraInstinctHudLines = Instance.new("Frame")
    MasteredUltraInstinctHudLines.Name = "MasteredUltraInstinctDangerLines"
    MasteredUltraInstinctHudLines.BackgroundTransparency = 1
    MasteredUltraInstinctHudLines.Size = UDim2.fromScale(1, 1)
    MasteredUltraInstinctHudLines.Parent = MasteredUltraInstinctHud
end

local function MasteredUltraInstinctSetText(MasteredUltraInstinctObject, MasteredUltraInstinctText)
    if MasteredUltraInstinctObject and MasteredUltraInstinctObject.Parent then
        MasteredUltraInstinctObject.Text = MasteredUltraInstinctText
    end
end

local function MasteredUltraInstinctCreateThreatCard(MasteredUltraInstinctThreat)
    MasteredUltraInstinctBuildHud()
    if not MasteredUltraInstinctHudCards then
        return
    end

    local MasteredUltraInstinctGroup = Instance.new("CanvasGroup")
    MasteredUltraInstinctGroup.Name = "MasteredUltraInstinctAlert_" .. MasteredUltraInstinctThreat.Player.UserId
    MasteredUltraInstinctGroup.BackgroundTransparency = 1
    MasteredUltraInstinctGroup.GroupTransparency = 1
    MasteredUltraInstinctGroup.Parent = MasteredUltraInstinctHudCards
    local MasteredUltraInstinctScale = Instance.new("UIScale")
    MasteredUltraInstinctScale.Scale = 0.82
    MasteredUltraInstinctScale.Parent = MasteredUltraInstinctGroup

    local MasteredUltraInstinctPanel = Instance.new("Frame")
    MasteredUltraInstinctPanel.BackgroundColor3 = Color3.fromRGB(8, 8, 10)
    MasteredUltraInstinctPanel.BackgroundTransparency = 0.08
    MasteredUltraInstinctPanel.BorderSizePixel = 0
    MasteredUltraInstinctPanel.Size = UDim2.fromScale(1, 1)
    MasteredUltraInstinctPanel.Parent = MasteredUltraInstinctGroup
    Instance.new("UICorner", MasteredUltraInstinctPanel).CornerRadius = UDim.new(0, 7)
    local MasteredUltraInstinctStroke = Instance.new("UIStroke")
    MasteredUltraInstinctStroke.Color = Color3.fromRGB(255, 209, 35)
    MasteredUltraInstinctStroke.Thickness = 2
    MasteredUltraInstinctStroke.Parent = MasteredUltraInstinctPanel

    local MasteredUltraInstinctDangerStrip = Instance.new("Frame")
    MasteredUltraInstinctDangerStrip.BackgroundColor3 = Color3.fromRGB(255, 209, 35)
    MasteredUltraInstinctDangerStrip.BorderSizePixel = 0
    MasteredUltraInstinctDangerStrip.Size = UDim2.new(0, 5, 1, -14)
    MasteredUltraInstinctDangerStrip.Position = UDim2.fromOffset(8, 7)
    MasteredUltraInstinctDangerStrip.Parent = MasteredUltraInstinctPanel
    Instance.new("UICorner", MasteredUltraInstinctDangerStrip).CornerRadius = UDim.new(1, 0)

    local function MasteredUltraInstinctCardLabel(MasteredUltraInstinctName, MasteredUltraInstinctY, MasteredUltraInstinctFont, MasteredUltraInstinctSize, MasteredUltraInstinctColor)
        local MasteredUltraInstinctLabel = Instance.new("TextLabel")
        MasteredUltraInstinctLabel.Name = MasteredUltraInstinctName
        MasteredUltraInstinctLabel.BackgroundTransparency = 1
        MasteredUltraInstinctLabel.Position = UDim2.new(0, 25, 0, MasteredUltraInstinctY)
        MasteredUltraInstinctLabel.Size = UDim2.new(1, -88, 0, MasteredUltraInstinctSize + 5)
        MasteredUltraInstinctLabel.Font = MasteredUltraInstinctFont
        MasteredUltraInstinctLabel.TextSize = MasteredUltraInstinctSize
        MasteredUltraInstinctLabel.TextColor3 = MasteredUltraInstinctColor
        MasteredUltraInstinctLabel.TextXAlignment = Enum.TextXAlignment.Left
        MasteredUltraInstinctLabel.TextTruncate = Enum.TextTruncate.AtEnd
        MasteredUltraInstinctLabel.Parent = MasteredUltraInstinctPanel
        return MasteredUltraInstinctLabel
    end

    MasteredUltraInstinctCardLabel("ThreatLabel", 8, Enum.Font.GothamBold, 13, Color3.fromRGB(255, 221, 65)).Text = "THREAT DETECTED"
    local MasteredUltraInstinctName = MasteredUltraInstinctCardLabel("NameLabel", 29, Enum.Font.GothamBold, 13, Color3.fromRGB(245, 245, 245))
    local MasteredUltraInstinctDistance = MasteredUltraInstinctCardLabel("DistanceLabel", 50, Enum.Font.Gotham, 11, Color3.fromRGB(220, 220, 220))
    local MasteredUltraInstinctHealth = MasteredUltraInstinctCardLabel("HealthLabel", 67, Enum.Font.Gotham, 11, Color3.fromRGB(220, 220, 220))
    local MasteredUltraInstinctAbility = MasteredUltraInstinctCardLabel("AbilityLabel", 84, Enum.Font.GothamBold, 10, Color3.fromRGB(255, 209, 35))
    MasteredUltraInstinctAbility.Size = UDim2.new(1, -35, 0, 17)

    local MasteredUltraInstinctImageHolder = Instance.new("Frame")
    MasteredUltraInstinctImageHolder.BackgroundColor3 = Color3.fromRGB(255, 209, 35)
    MasteredUltraInstinctImageHolder.BorderSizePixel = 0
    MasteredUltraInstinctImageHolder.Position = UDim2.new(1, -57, 0, 26)
    MasteredUltraInstinctImageHolder.Size = UDim2.fromOffset(44, 44)
    MasteredUltraInstinctImageHolder.Parent = MasteredUltraInstinctPanel
    Instance.new("UICorner", MasteredUltraInstinctImageHolder).CornerRadius = UDim.new(1, 0)
    local MasteredUltraInstinctImage = Instance.new("ImageLabel")
    MasteredUltraInstinctImage.Name = "Portrait"
    MasteredUltraInstinctImage.BackgroundColor3 = Color3.fromRGB(13, 13, 16)
    MasteredUltraInstinctImage.BorderSizePixel = 0
    MasteredUltraInstinctImage.Position = UDim2.fromOffset(2, 2)
    MasteredUltraInstinctImage.Size = UDim2.fromOffset(40, 40)
    MasteredUltraInstinctImage.Parent = MasteredUltraInstinctImageHolder
    Instance.new("UICorner", MasteredUltraInstinctImage).CornerRadius = UDim.new(1, 0)

    MasteredUltraInstinctThreat.Card = MasteredUltraInstinctGroup
    MasteredUltraInstinctThreat.CardScale = MasteredUltraInstinctScale
    MasteredUltraInstinctThreat.CardLabels = {
        Name = MasteredUltraInstinctName,
        Distance = MasteredUltraInstinctDistance,
        Health = MasteredUltraInstinctHealth,
        Ability = MasteredUltraInstinctAbility,
        Portrait = MasteredUltraInstinctImage,
    }
    MasteredUltraInstinctTweenService:Create(
        MasteredUltraInstinctGroup,
        TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { GroupTransparency = 0 }
    ):Play()
    MasteredUltraInstinctTweenService:Create(
        MasteredUltraInstinctScale,
        TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        { Scale = 1 }
    ):Play()

    local MasteredUltraInstinctUserId = MasteredUltraInstinctThreat.Player.UserId
    local MasteredUltraInstinctCachedThumbnail = MasteredUltraInstinctThumbnailCache[MasteredUltraInstinctUserId]
    if MasteredUltraInstinctCachedThumbnail then
        MasteredUltraInstinctImage.Image = MasteredUltraInstinctCachedThumbnail
    else
        task.spawn(function()
            local MasteredUltraInstinctOk, MasteredUltraInstinctThumbnail = pcall(function()
                return MasteredUltraInstinctPlayers:GetUserThumbnailAsync(
                    MasteredUltraInstinctUserId,
                    Enum.ThumbnailType.HeadShot,
                    Enum.ThumbnailSize.Size100x100
                )
            end)
            if MasteredUltraInstinctOk then
                MasteredUltraInstinctThumbnailCache[MasteredUltraInstinctUserId] = MasteredUltraInstinctThumbnail
                if MasteredUltraInstinctThreat.Card
                    and MasteredUltraInstinctThreat.Card.Parent
                    and MasteredUltraInstinctThreat.CardLabels.Portrait then
                    MasteredUltraInstinctThreat.CardLabels.Portrait.Image = MasteredUltraInstinctThumbnail
                end
            end
        end)
    end
end

local function MasteredUltraInstinctCreateLine(MasteredUltraInstinctThreat)
    MasteredUltraInstinctBuildHud()
    if not MasteredUltraInstinctHudLines then
        return
    end
    local MasteredUltraInstinctOuter = Instance.new("Frame")
    MasteredUltraInstinctOuter.Name = "MasteredUltraInstinctDangerLine"
    MasteredUltraInstinctOuter.AnchorPoint = Vector2.new(0, 0.5)
    MasteredUltraInstinctOuter.BackgroundColor3 = Color3.new(0, 0, 0)
    MasteredUltraInstinctOuter.BorderSizePixel = 0
    MasteredUltraInstinctOuter.Visible = false
    MasteredUltraInstinctOuter.ZIndex = 2
    MasteredUltraInstinctOuter.Parent = MasteredUltraInstinctHudLines
    local MasteredUltraInstinctInner = Instance.new("Frame")
    MasteredUltraInstinctInner.AnchorPoint = Vector2.new(0, 0.5)
    MasteredUltraInstinctInner.BackgroundColor3 = Color3.fromRGB(255, 214, 24)
    MasteredUltraInstinctInner.BorderSizePixel = 0
    MasteredUltraInstinctInner.Position = UDim2.new(0, 0, 0.5, 0)
    MasteredUltraInstinctInner.Size = UDim2.new(1, 0, 0, M.Config.ThreatLineInnerThickness)
    MasteredUltraInstinctInner.ZIndex = 3
    MasteredUltraInstinctInner.Parent = MasteredUltraInstinctOuter
    MasteredUltraInstinctThreat.Line = MasteredUltraInstinctOuter
end

local function MasteredUltraInstinctCreateFarLight(MasteredUltraInstinctThreat)
    local MasteredUltraInstinctCharacter = MasteredUltraInstinctThreat.Player.Character
    local MasteredUltraInstinctRoot = MasteredUltraInstinctGetRoot(MasteredUltraInstinctCharacter)
    if not MasteredUltraInstinctRoot then
        return
    end
    local MasteredUltraInstinctHighlight = Instance.new("Highlight")
    MasteredUltraInstinctHighlight.Name = "MasteredUltraInstinctThreatFarLight"
    MasteredUltraInstinctHighlight.FillColor = Color3.fromRGB(255, 202, 0)
    MasteredUltraInstinctHighlight.OutlineColor = Color3.fromRGB(255, 240, 120)
    MasteredUltraInstinctHighlight.FillTransparency = 0.55
    MasteredUltraInstinctHighlight.OutlineTransparency = 0
    MasteredUltraInstinctHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    MasteredUltraInstinctHighlight.Adornee = MasteredUltraInstinctCharacter
    MasteredUltraInstinctHighlight.Parent = MasteredUltraInstinctCharacter

    local MasteredUltraInstinctBillboard = Instance.new("BillboardGui")
    MasteredUltraInstinctBillboard.Name = "MasteredUltraInstinctThreatBeacon"
    MasteredUltraInstinctBillboard.Adornee = MasteredUltraInstinctRoot
    MasteredUltraInstinctBillboard.AlwaysOnTop = true
    MasteredUltraInstinctBillboard.LightInfluence = 0
    MasteredUltraInstinctBillboard.Size = UDim2.fromOffset(86, 86)
    MasteredUltraInstinctBillboard.StudsOffset = Vector3.new(0, 4.5, 0)
    MasteredUltraInstinctBillboard.Parent = MasteredUltraInstinctCharacter
    local MasteredUltraInstinctBeacon = Instance.new("TextLabel")
    MasteredUltraInstinctBeacon.BackgroundTransparency = 1
    MasteredUltraInstinctBeacon.Size = UDim2.fromScale(1, 1)
    MasteredUltraInstinctBeacon.Font = Enum.Font.GothamBlack
    MasteredUltraInstinctBeacon.Text = "!"
    MasteredUltraInstinctBeacon.TextColor3 = Color3.fromRGB(255, 218, 35)
    MasteredUltraInstinctBeacon.TextStrokeColor3 = Color3.new(0, 0, 0)
    MasteredUltraInstinctBeacon.TextStrokeTransparency = 0
    MasteredUltraInstinctBeacon.TextSize = 74
    MasteredUltraInstinctBeacon.Parent = MasteredUltraInstinctBillboard
    local MasteredUltraInstinctBeaconScale = Instance.new("UIScale")
    MasteredUltraInstinctBeaconScale.Parent = MasteredUltraInstinctBillboard
    local MasteredUltraInstinctPointLight = Instance.new("PointLight")
    MasteredUltraInstinctPointLight.Name = "MasteredUltraInstinctThreatFarLight"
    MasteredUltraInstinctPointLight.Color = Color3.fromRGB(255, 214, 24)
    MasteredUltraInstinctPointLight.Brightness = 8
    MasteredUltraInstinctPointLight.Range = M.Config.ThreatFarLightRange
    MasteredUltraInstinctPointLight.Shadows = false
    MasteredUltraInstinctPointLight.Parent = MasteredUltraInstinctRoot

    MasteredUltraInstinctThreat.Highlight = MasteredUltraInstinctHighlight
    MasteredUltraInstinctThreat.Beacon = MasteredUltraInstinctBillboard
    MasteredUltraInstinctThreat.BeaconScale = MasteredUltraInstinctBeaconScale
    MasteredUltraInstinctThreat.FarLight = MasteredUltraInstinctPointLight
end

local function MasteredUltraInstinctDestroyThreatVisuals(MasteredUltraInstinctThreat)
    if MasteredUltraInstinctThreat.Line then
        MasteredUltraInstinctThreat.Line:Destroy()
    end
    if MasteredUltraInstinctThreat.Highlight then
        MasteredUltraInstinctThreat.Highlight:Destroy()
    end
    if MasteredUltraInstinctThreat.Beacon then
        MasteredUltraInstinctThreat.Beacon:Destroy()
    end
    if MasteredUltraInstinctThreat.FarLight then
        MasteredUltraInstinctThreat.FarLight:Destroy()
    end
    MasteredUltraInstinctThreat.Line = nil
    MasteredUltraInstinctThreat.Highlight = nil
    MasteredUltraInstinctThreat.Beacon = nil
    MasteredUltraInstinctThreat.FarLight = nil
end

local function MasteredUltraInstinctDismissThreat(MasteredUltraInstinctThreat)
    if MasteredUltraInstinctThreat.Removing then
        return
    end
    MasteredUltraInstinctThreat.Removing = true
    MasteredUltraInstinctDestroyThreatVisuals(MasteredUltraInstinctThreat)
    if MasteredUltraInstinctThreat.Card and MasteredUltraInstinctThreat.Card.Parent then
        local MasteredUltraInstinctCard = MasteredUltraInstinctThreat.Card
        if MasteredUltraInstinctThreat.CardScale then
            MasteredUltraInstinctTweenService:Create(
                MasteredUltraInstinctThreat.CardScale,
                TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
                { Scale = 0.9 }
            ):Play()
        end
        MasteredUltraInstinctTweenService:Create(
            MasteredUltraInstinctCard,
            TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            { GroupTransparency = 1 }
        ):Play()
        task.delay(0.18, function()
            if MasteredUltraInstinctCard then
                MasteredUltraInstinctCard:Destroy()
            end
        end)
    end
    MasteredUltraInstinctThreats[MasteredUltraInstinctThreat.Player] = nil
end

local function MasteredUltraInstinctMarkThreat(MasteredUltraInstinctPlayer, MasteredUltraInstinctDodge)
    if not MasteredUltraInstinctPlayer or MasteredUltraInstinctPlayer == MasteredUltraInstinctLocalPlayer then
        return
    end
    local MasteredUltraInstinctNow = os.clock()
    local MasteredUltraInstinctThreat = MasteredUltraInstinctThreats[MasteredUltraInstinctPlayer]
    if MasteredUltraInstinctThreat then
        MasteredUltraInstinctThreat.DodgeName = MasteredUltraInstinctDodge.Name
        MasteredUltraInstinctThreat.ExpiresAt = MasteredUltraInstinctNow + M.Config.ThreatAlertLifetime
        MasteredUltraInstinctThreat.Removing = false
        return
    end

    MasteredUltraInstinctThreat = {
        Player = MasteredUltraInstinctPlayer,
        DodgeName = MasteredUltraInstinctDodge.Name,
        MarkedAt = MasteredUltraInstinctNow,
        ExpiresAt = MasteredUltraInstinctNow + M.Config.ThreatAlertLifetime,
    }
    MasteredUltraInstinctThreats[MasteredUltraInstinctPlayer] = MasteredUltraInstinctThreat
    MasteredUltraInstinctCreateThreatCard(MasteredUltraInstinctThreat)
    MasteredUltraInstinctCreateLine(MasteredUltraInstinctThreat)
    MasteredUltraInstinctCreateFarLight(MasteredUltraInstinctThreat)
end

local function MasteredUltraInstinctThreatList()
    local MasteredUltraInstinctList = {}
    for _, MasteredUltraInstinctThreat in pairs(MasteredUltraInstinctThreats) do
        table.insert(MasteredUltraInstinctList, MasteredUltraInstinctThreat)
    end
    table.sort(MasteredUltraInstinctList, function(MasteredUltraInstinctLeft, MasteredUltraInstinctRight)
        return MasteredUltraInstinctLeft.MarkedAt > MasteredUltraInstinctRight.MarkedAt
    end)
    return MasteredUltraInstinctList
end

local function MasteredUltraInstinctUpdateThreatHud(MasteredUltraInstinctNow)
    local MasteredUltraInstinctList = MasteredUltraInstinctThreatList()
    local MasteredUltraInstinctCount = #MasteredUltraInstinctList
    local MasteredUltraInstinctCardWidth = math.max(118, 238 - math.max(0, MasteredUltraInstinctCount - 1) * 22)
    local MasteredUltraInstinctCardHeight = math.max(74, 108 - math.max(0, MasteredUltraInstinctCount - 1) * 7)
    local MasteredUltraInstinctOriginRoot = MasteredUltraInstinctDefenseActive
        and MasteredUltraInstinctCloneRoot
        or MasteredUltraInstinctGetRoot(MasteredUltraInstinctLocalPlayer and MasteredUltraInstinctLocalPlayer.Character)
    local MasteredUltraInstinctOriginPosition = MasteredUltraInstinctOriginRoot
        and MasteredUltraInstinctOriginRoot.Position
        or MasteredUltraInstinctVirtualRootPosition

    for MasteredUltraInstinctIndex, MasteredUltraInstinctThreat in ipairs(MasteredUltraInstinctList) do
        local MasteredUltraInstinctCharacter = MasteredUltraInstinctThreat.Player.Character
        local MasteredUltraInstinctRoot = MasteredUltraInstinctGetRoot(MasteredUltraInstinctCharacter)
        local MasteredUltraInstinctHumanoid = MasteredUltraInstinctGetHumanoid(MasteredUltraInstinctCharacter)
        if not MasteredUltraInstinctRoot or not MasteredUltraInstinctHumanoid or MasteredUltraInstinctHumanoid.Health <= 0 then
            MasteredUltraInstinctDismissThreat(MasteredUltraInstinctThreat)
            continue
        end

        if MasteredUltraInstinctThreat.Card and MasteredUltraInstinctThreat.Card.Parent then
            MasteredUltraInstinctThreat.Card.AnchorPoint = Vector2.new(1, 0)
            MasteredUltraInstinctThreat.Card.Position = UDim2.new(
                1,
                -M.Config.ThreatHudRightOffset - (MasteredUltraInstinctIndex - 1) * (MasteredUltraInstinctCardWidth + 8),
                0,
                M.Config.ThreatHudTopOffset
            )
            MasteredUltraInstinctThreat.Card.Size = UDim2.fromOffset(MasteredUltraInstinctCardWidth, MasteredUltraInstinctCardHeight)
            local MasteredUltraInstinctDistance = MasteredUltraInstinctOriginPosition
                and (MasteredUltraInstinctRoot.Position - MasteredUltraInstinctOriginPosition).Magnitude
                or 0
            MasteredUltraInstinctSetText(
                MasteredUltraInstinctThreat.CardLabels.Name,
                MasteredUltraInstinctThreat.Player.DisplayName or MasteredUltraInstinctThreat.Player.Name
            )
            MasteredUltraInstinctSetText(MasteredUltraInstinctThreat.CardLabels.Distance, string.format("%.0f studs", MasteredUltraInstinctDistance))
            MasteredUltraInstinctSetText(
                MasteredUltraInstinctThreat.CardLabels.Health,
                string.format("HP  %.0f / %.0f", math.max(0, MasteredUltraInstinctHumanoid.Health), MasteredUltraInstinctHumanoid.MaxHealth)
            )
            MasteredUltraInstinctSetText(MasteredUltraInstinctThreat.CardLabels.Ability, MasteredUltraInstinctThreat.DodgeName)
        end

        if MasteredUltraInstinctThreat.BeaconScale then
            MasteredUltraInstinctThreat.BeaconScale.Scale = 0.92 + math.abs(math.sin(MasteredUltraInstinctNow * 7)) * 0.18
        end
        if MasteredUltraInstinctThreat.Highlight then
            MasteredUltraInstinctThreat.Highlight.FillTransparency = 0.44 + math.abs(math.sin(MasteredUltraInstinctNow * 6)) * 0.22
        end
    end
end

local function MasteredUltraInstinctRenderThreatLines()
    local MasteredUltraInstinctCamera = workspace.CurrentCamera
    local MasteredUltraInstinctOriginRoot = MasteredUltraInstinctDefenseActive
        and MasteredUltraInstinctCloneRoot
        or MasteredUltraInstinctGetRoot(MasteredUltraInstinctLocalPlayer and MasteredUltraInstinctLocalPlayer.Character)
    local MasteredUltraInstinctOriginPosition = MasteredUltraInstinctOriginRoot
        and MasteredUltraInstinctOriginRoot.Position
        or MasteredUltraInstinctVirtualRootPosition
    if not MasteredUltraInstinctCamera or not MasteredUltraInstinctOriginPosition then
        return
    end
    local MasteredUltraInstinctOriginScreen, MasteredUltraInstinctOriginVisible =
        MasteredUltraInstinctCamera:WorldToViewportPoint(MasteredUltraInstinctOriginPosition)

    for _, MasteredUltraInstinctThreat in pairs(MasteredUltraInstinctThreats) do
        local MasteredUltraInstinctLine = MasteredUltraInstinctThreat.Line
        local MasteredUltraInstinctTargetRoot = MasteredUltraInstinctGetRoot(MasteredUltraInstinctThreat.Player.Character)
        if not MasteredUltraInstinctLine or not MasteredUltraInstinctTargetRoot or not MasteredUltraInstinctOriginVisible then
            if MasteredUltraInstinctLine then
                MasteredUltraInstinctLine.Visible = false
            end
            continue
        end
        local MasteredUltraInstinctTargetScreen, MasteredUltraInstinctTargetVisible =
            MasteredUltraInstinctCamera:WorldToViewportPoint(MasteredUltraInstinctTargetRoot.Position)
        if not MasteredUltraInstinctTargetVisible then
            MasteredUltraInstinctLine.Visible = false
            continue
        end
        local MasteredUltraInstinctDelta = Vector2.new(
            MasteredUltraInstinctTargetScreen.X - MasteredUltraInstinctOriginScreen.X,
            MasteredUltraInstinctTargetScreen.Y - MasteredUltraInstinctOriginScreen.Y
        )
        local MasteredUltraInstinctLength = MasteredUltraInstinctDelta.Magnitude
        if MasteredUltraInstinctLength < 2 then
            MasteredUltraInstinctLine.Visible = false
            continue
        end
        MasteredUltraInstinctLine.Visible = true
        MasteredUltraInstinctLine.Position = UDim2.fromOffset(MasteredUltraInstinctOriginScreen.X, MasteredUltraInstinctOriginScreen.Y)
        MasteredUltraInstinctLine.Size = UDim2.fromOffset(MasteredUltraInstinctLength, M.Config.ThreatLineOuterThickness)
        MasteredUltraInstinctLine.Rotation = math.deg(math.atan2(MasteredUltraInstinctDelta.Y, MasteredUltraInstinctDelta.X))
    end
end

local function MasteredUltraInstinctClearSourceDeathWatch()
    MasteredUltraInstinctDisconnect(MasteredUltraInstinctSourceDiedConnection)
    MasteredUltraInstinctSourceDiedConnection = nil
    MasteredUltraInstinctSourceDied = false
end

local function MasteredUltraInstinctWatchSourceDeath(MasteredUltraInstinctPlayer)
    MasteredUltraInstinctClearSourceDeathWatch()
    if not MasteredUltraInstinctPlayer then
        return
    end
    local MasteredUltraInstinctHumanoid = MasteredUltraInstinctGetHumanoid(MasteredUltraInstinctPlayer.Character)
    if not MasteredUltraInstinctHumanoid then
        return
    end
    if MasteredUltraInstinctHumanoid.Health <= 0 then
        MasteredUltraInstinctSourceDied = true
        return
    end
    MasteredUltraInstinctSourceDiedConnection = MasteredUltraInstinctHumanoid.Died:Connect(function()
        MasteredUltraInstinctSourceDied = true
    end)
end

local function MasteredUltraInstinctStartSkyLift(MasteredUltraInstinctRoot, MasteredUltraInstinctToken)
    MasteredUltraInstinctDestroySkyForces()
    MasteredUltraInstinctSkyVelocity = Instance.new("BodyVelocity")
    MasteredUltraInstinctSkyVelocity.Name = "MasteredUltraInstinctLift"
    MasteredUltraInstinctSkyVelocity.Velocity = Vector3.new(0, M.Config.LiftSpeed, 0)
    MasteredUltraInstinctSkyVelocity.MaxForce = Vector3.new(0, M.Config.HoldForce, 0)
    MasteredUltraInstinctSkyVelocity.Parent = MasteredUltraInstinctRoot

    task.spawn(function()
        local MasteredUltraInstinctStartedAt = os.clock()
        while MasteredUltraInstinctDefenseActive
            and MasteredUltraInstinctToken == MasteredUltraInstinctActivationToken
            and MasteredUltraInstinctRoot.Parent do
            if MasteredUltraInstinctRoot.Position.Y >= MasteredUltraInstinctSkyY - 20
                or os.clock() - MasteredUltraInstinctStartedAt >= M.Config.LiftTimeout then
                break
            end
            task.wait(0.05)
        end
        if not MasteredUltraInstinctDefenseActive
            or MasteredUltraInstinctToken ~= MasteredUltraInstinctActivationToken
            or not MasteredUltraInstinctRoot.Parent then
            return
        end
        if MasteredUltraInstinctSkyVelocity then
            MasteredUltraInstinctSkyVelocity:Destroy()
            MasteredUltraInstinctSkyVelocity = nil
        end
        MasteredUltraInstinctSkyPosition = Instance.new("BodyPosition")
        MasteredUltraInstinctSkyPosition.Name = "MasteredUltraInstinctHold"
        MasteredUltraInstinctSkyPosition.Position = Vector3.new(
            MasteredUltraInstinctRoot.Position.X,
            MasteredUltraInstinctSkyY,
            MasteredUltraInstinctRoot.Position.Z
        )
        MasteredUltraInstinctSkyPosition.MaxForce = Vector3.new(M.Config.HoldForce, M.Config.HoldForce, M.Config.HoldForce)
        MasteredUltraInstinctSkyPosition.P = 60000
        MasteredUltraInstinctSkyPosition.D = 2500
        MasteredUltraInstinctSkyPosition.Parent = MasteredUltraInstinctRoot
    end)
end

local MasteredUltraInstinctDeactivate

local function MasteredUltraInstinctBegin(MasteredUltraInstinctDodge, MasteredUltraInstinctSource)
    local MasteredUltraInstinctCharacter = MasteredUltraInstinctLocalPlayer and MasteredUltraInstinctLocalPlayer.Character
    local MasteredUltraInstinctRoot = MasteredUltraInstinctGetRoot(MasteredUltraInstinctCharacter)
    local MasteredUltraInstinctHumanoid = MasteredUltraInstinctGetHumanoid(MasteredUltraInstinctCharacter)
    if not MasteredUltraInstinctCharacter
        or not MasteredUltraInstinctRoot
        or not MasteredUltraInstinctHumanoid
        or MasteredUltraInstinctHumanoid.Health <= 0 then
        return
    end

    MasteredUltraInstinctFootOffset = MasteredUltraInstinctGetFootOffset(MasteredUltraInstinctCharacter)
    MasteredUltraInstinctVirtualRootPosition = MasteredUltraInstinctGroundPosition(
        MasteredUltraInstinctRoot.Position,
        MasteredUltraInstinctCharacter
    )
    local _, MasteredUltraInstinctYaw = MasteredUltraInstinctRoot.CFrame:ToOrientation()
    local MasteredUltraInstinctCloneCFrame = CFrame.new(MasteredUltraInstinctVirtualRootPosition)
        * CFrame.Angles(0, MasteredUltraInstinctYaw, 0)
    MasteredUltraInstinctCloneModel, MasteredUltraInstinctCloneRoot =
        MasteredUltraInstinctCreateClone(MasteredUltraInstinctCharacter, MasteredUltraInstinctCloneCFrame)
    if not MasteredUltraInstinctCloneRoot then
        MasteredUltraInstinctDestroyClone()
        MasteredUltraInstinctVirtualRootPosition = nil
        return
    end

    MasteredUltraInstinctDefenseActive = true
    MasteredUltraInstinctActivationToken += 1
    local MasteredUltraInstinctToken = MasteredUltraInstinctActivationToken
    MasteredUltraInstinctActiveDodgeName = MasteredUltraInstinctDodge.Name
    MasteredUltraInstinctActiveDuration = MasteredUltraInstinctDodge.Duration
    MasteredUltraInstinctActiveUntil = os.clock() + MasteredUltraInstinctDodge.Duration
    MasteredUltraInstinctActiveSource = MasteredUltraInstinctSource
    MasteredUltraInstinctExtendUntilSourceDies =
        MasteredUltraInstinctDodge.ExtendUntilSourceDies == true and MasteredUltraInstinctSource ~= nil
    MasteredUltraInstinctPendingDodge = nil
    MasteredUltraInstinctSkyY = MasteredUltraInstinctVirtualRootPosition.Y + M.Config.SkyAltitude
    MasteredUltraInstinctCameraSubject = MasteredUltraInstinctCreateCameraSubject(MasteredUltraInstinctVirtualRootPosition)
    MasteredUltraInstinctHideRealCharacter(MasteredUltraInstinctCharacter)
    MasteredUltraInstinctCreateAura()
    MasteredUltraInstinctWatchSourceDeath(MasteredUltraInstinctSource)

    local MasteredUltraInstinctCamera = workspace.CurrentCamera
    if MasteredUltraInstinctCamera then
        MasteredUltraInstinctCamera.CameraSubject = MasteredUltraInstinctCameraSubject
    end
    MasteredUltraInstinctStartSkyLift(MasteredUltraInstinctRoot, MasteredUltraInstinctToken)
    MasteredUltraInstinctPlayLocalSound(M.Config.ActivationSoundId)
end

MasteredUltraInstinctDeactivate = function(MasteredUltraInstinctReturnToClone)
    if not MasteredUltraInstinctDefenseActive then
        return
    end
    MasteredUltraInstinctDefenseActive = false
    MasteredUltraInstinctActivationToken += 1
    MasteredUltraInstinctDestroySkyForces()
    MasteredUltraInstinctClearSourceDeathWatch()

    local MasteredUltraInstinctCharacter = MasteredUltraInstinctLocalPlayer and MasteredUltraInstinctLocalPlayer.Character
    local MasteredUltraInstinctRoot = MasteredUltraInstinctGetRoot(MasteredUltraInstinctCharacter)
    local MasteredUltraInstinctHumanoid = MasteredUltraInstinctGetHumanoid(MasteredUltraInstinctCharacter)
    if MasteredUltraInstinctReturnToClone
        and MasteredUltraInstinctRoot
        and MasteredUltraInstinctHumanoid
        and MasteredUltraInstinctHumanoid.Health > 0
        and MasteredUltraInstinctVirtualRootPosition then
        local MasteredUltraInstinctLandingPosition = MasteredUltraInstinctGroundPosition(
            MasteredUltraInstinctVirtualRootPosition,
            MasteredUltraInstinctCharacter
        )
        local MasteredUltraInstinctYaw = 0
        if MasteredUltraInstinctCloneRoot then
            local _, MasteredUltraInstinctCloneYaw = MasteredUltraInstinctCloneRoot.CFrame:ToOrientation()
            MasteredUltraInstinctYaw = MasteredUltraInstinctCloneYaw
        end
        pcall(function()
            MasteredUltraInstinctHumanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
            MasteredUltraInstinctRoot.CFrame = CFrame.new(MasteredUltraInstinctLandingPosition)
                * CFrame.Angles(0, MasteredUltraInstinctYaw, 0)
            MasteredUltraInstinctRoot.AssemblyLinearVelocity = Vector3.zero
            MasteredUltraInstinctRoot.AssemblyAngularVelocity = Vector3.zero
            task.defer(function()
                if MasteredUltraInstinctHumanoid.Parent then
                    MasteredUltraInstinctHumanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
                    MasteredUltraInstinctHumanoid:ChangeState(Enum.HumanoidStateType.Landed)
                end
            end)
        end)
    end

    local MasteredUltraInstinctCamera = workspace.CurrentCamera
    if MasteredUltraInstinctCamera and MasteredUltraInstinctHumanoid and MasteredUltraInstinctHumanoid.Parent then
        MasteredUltraInstinctCamera.CameraSubject = MasteredUltraInstinctHumanoid
    end
    MasteredUltraInstinctRestoreRealCharacter()
    MasteredUltraInstinctDestroyClone()
    MasteredUltraInstinctDestroyCameraSubject()
    MasteredUltraInstinctVirtualRootPosition = nil
    MasteredUltraInstinctSkyY = nil
    MasteredUltraInstinctActiveDodgeName = nil
    MasteredUltraInstinctActiveDuration = 0
    MasteredUltraInstinctActiveSource = nil
    MasteredUltraInstinctExtendUntilSourceDies = false
    MasteredUltraInstinctPlayLocalSound(M.Config.DeactivationSoundId)
end

local function MasteredUltraInstinctMoveClone(MasteredUltraInstinctDeltaTime, MasteredUltraInstinctCharacter)
    if not M.Config.AllowCloneMovement or not MasteredUltraInstinctVirtualRootPosition then
        return
    end
    local MasteredUltraInstinctCamera = workspace.CurrentCamera
    if not MasteredUltraInstinctCamera then
        return
    end
    local MasteredUltraInstinctLook = MasteredUltraInstinctCamera.CFrame.LookVector
    local MasteredUltraInstinctRight = MasteredUltraInstinctCamera.CFrame.RightVector
    local MasteredUltraInstinctForwardFlat = Vector3.new(MasteredUltraInstinctLook.X, 0, MasteredUltraInstinctLook.Z)
    local MasteredUltraInstinctRightFlat = Vector3.new(MasteredUltraInstinctRight.X, 0, MasteredUltraInstinctRight.Z)
    if MasteredUltraInstinctForwardFlat.Magnitude > 0 then MasteredUltraInstinctForwardFlat = MasteredUltraInstinctForwardFlat.Unit end
    if MasteredUltraInstinctRightFlat.Magnitude > 0 then MasteredUltraInstinctRightFlat = MasteredUltraInstinctRightFlat.Unit end
    local MasteredUltraInstinctMovement = Vector3.zero
    if MasteredUltraInstinctUserInputService:IsKeyDown(Enum.KeyCode.W) then MasteredUltraInstinctMovement += MasteredUltraInstinctForwardFlat end
    if MasteredUltraInstinctUserInputService:IsKeyDown(Enum.KeyCode.S) then MasteredUltraInstinctMovement -= MasteredUltraInstinctForwardFlat end
    if MasteredUltraInstinctUserInputService:IsKeyDown(Enum.KeyCode.D) then MasteredUltraInstinctMovement += MasteredUltraInstinctRightFlat end
    if MasteredUltraInstinctUserInputService:IsKeyDown(Enum.KeyCode.A) then MasteredUltraInstinctMovement -= MasteredUltraInstinctRightFlat end
    if MasteredUltraInstinctMovement.Magnitude <= 0 then
        return
    end
    local MasteredUltraInstinctProposed = MasteredUltraInstinctVirtualRootPosition
        + MasteredUltraInstinctMovement.Unit * M.Config.CloneWalkSpeed * MasteredUltraInstinctDeltaTime
    local MasteredUltraInstinctGrounded = MasteredUltraInstinctGroundPosition(MasteredUltraInstinctProposed, MasteredUltraInstinctCharacter)
    local MasteredUltraInstinctYDelta = math.clamp(
        MasteredUltraInstinctGrounded.Y - MasteredUltraInstinctVirtualRootPosition.Y,
        -M.Config.MaxGroundStepPerSecond * MasteredUltraInstinctDeltaTime,
        M.Config.MaxGroundStepPerSecond * MasteredUltraInstinctDeltaTime
    )
    MasteredUltraInstinctVirtualRootPosition = Vector3.new(
        MasteredUltraInstinctProposed.X,
        MasteredUltraInstinctVirtualRootPosition.Y + MasteredUltraInstinctYDelta,
        MasteredUltraInstinctProposed.Z
    )
end

local function MasteredUltraInstinctUpdateCloneAndCamera()
    if not MasteredUltraInstinctVirtualRootPosition then
        return
    end
    local MasteredUltraInstinctCamera = workspace.CurrentCamera
    local MasteredUltraInstinctYaw = 0
    if MasteredUltraInstinctCamera then
        local MasteredUltraInstinctLook = MasteredUltraInstinctCamera.CFrame.LookVector
        if Vector3.new(MasteredUltraInstinctLook.X, 0, MasteredUltraInstinctLook.Z).Magnitude > 0.01 then
            MasteredUltraInstinctYaw = math.atan2(-MasteredUltraInstinctLook.X, -MasteredUltraInstinctLook.Z)
        end
    end
    if MasteredUltraInstinctCloneModel and MasteredUltraInstinctCloneRoot then
        MasteredUltraInstinctCloneModel:PivotTo(
            CFrame.new(MasteredUltraInstinctVirtualRootPosition) * CFrame.Angles(0, MasteredUltraInstinctYaw, 0)
        )
    end
    if MasteredUltraInstinctCameraSubject then
        MasteredUltraInstinctCameraSubject.CFrame = CFrame.new(
            MasteredUltraInstinctVirtualRootPosition + Vector3.new(0, M.Config.CloneHeadOffset, 0)
        )
    end
    if MasteredUltraInstinctSkyPosition and MasteredUltraInstinctSkyY then
        MasteredUltraInstinctSkyPosition.Position = Vector3.new(
            MasteredUltraInstinctVirtualRootPosition.X,
            MasteredUltraInstinctSkyY,
            MasteredUltraInstinctVirtualRootPosition.Z
        )
    end
end

local function MasteredUltraInstinctTrigger(MasteredUltraInstinctDodge, MasteredUltraInstinctPlayer)
    if not MasteredUltraInstinctEnabled or not MasteredUltraInstinctDodge then
        return
    end
    local MasteredUltraInstinctNow = os.clock()
    local MasteredUltraInstinctKey = tostring(MasteredUltraInstinctPlayer and MasteredUltraInstinctPlayer.UserId or 0)
        .. ":" .. MasteredUltraInstinctDodge.Name
    if MasteredUltraInstinctNow - (MasteredUltraInstinctLastTriggerAt[MasteredUltraInstinctKey] or -math.huge)
        < M.Config.SameAnimationCooldown then
        return
    end
    MasteredUltraInstinctLastTriggerAt[MasteredUltraInstinctKey] = MasteredUltraInstinctNow
    MasteredUltraInstinctMarkThreat(MasteredUltraInstinctPlayer, MasteredUltraInstinctDodge)

    if MasteredUltraInstinctDefenseActive then
        if M.Config.RefreshOnRepeatedTrigger then
            MasteredUltraInstinctActiveUntil = math.max(
                MasteredUltraInstinctActiveUntil,
                MasteredUltraInstinctNow + MasteredUltraInstinctDodge.Duration
            )
        end
        return
    end
    if MasteredUltraInstinctPendingDodge then
        return
    end
    if MasteredUltraInstinctDodge.Delay <= 0 then
        MasteredUltraInstinctBegin(MasteredUltraInstinctDodge, MasteredUltraInstinctPlayer)
        return
    end
    MasteredUltraInstinctPendingDodge = MasteredUltraInstinctDodge.Name
    MasteredUltraInstinctPendingToken += 1
    local MasteredUltraInstinctToken = MasteredUltraInstinctPendingToken
    task.delay(MasteredUltraInstinctDodge.Delay, function()
        if MasteredUltraInstinctToken ~= MasteredUltraInstinctPendingToken then
            return
        end
        MasteredUltraInstinctPendingDodge = nil
        if MasteredUltraInstinctEnabled and not MasteredUltraInstinctDefenseActive then
            MasteredUltraInstinctBegin(MasteredUltraInstinctDodge, MasteredUltraInstinctPlayer)
        end
    end)
end

local function MasteredUltraInstinctOnAnimation(MasteredUltraInstinctPlayer, MasteredUltraInstinctTrack)
    local MasteredUltraInstinctAnimation = MasteredUltraInstinctTrack and MasteredUltraInstinctTrack.Animation
    local MasteredUltraInstinctId = MasteredUltraInstinctAnimation
        and MasteredUltraInstinctAssetNumber(MasteredUltraInstinctAnimation.AnimationId)
    if MasteredUltraInstinctId ~= "" then
        MasteredUltraInstinctTrigger(MasteredUltraInstinctDodgeByAnimationId[MasteredUltraInstinctId], MasteredUltraInstinctPlayer)
    end
end

local function MasteredUltraInstinctDisconnectWatch(MasteredUltraInstinctPlayer)
    local MasteredUltraInstinctWatch = MasteredUltraInstinctPlayerWatches[MasteredUltraInstinctPlayer]
    if MasteredUltraInstinctWatch then
        MasteredUltraInstinctDisconnect(MasteredUltraInstinctWatch.CharacterAdded)
        MasteredUltraInstinctDisconnect(MasteredUltraInstinctWatch.AnimationPlayed)
        MasteredUltraInstinctPlayerWatches[MasteredUltraInstinctPlayer] = nil
    end
    local MasteredUltraInstinctThreat = MasteredUltraInstinctThreats[MasteredUltraInstinctPlayer]
    if MasteredUltraInstinctThreat then
        MasteredUltraInstinctDismissThreat(MasteredUltraInstinctThreat)
    end
    if MasteredUltraInstinctActiveSource == MasteredUltraInstinctPlayer then
        MasteredUltraInstinctSourceDied = true
    end
end

local function MasteredUltraInstinctHookCharacter(MasteredUltraInstinctPlayer, MasteredUltraInstinctCharacter)
    local MasteredUltraInstinctWatch = MasteredUltraInstinctPlayerWatches[MasteredUltraInstinctPlayer]
    if not MasteredUltraInstinctWatch then
        return
    end
    MasteredUltraInstinctDisconnect(MasteredUltraInstinctWatch.AnimationPlayed)
    MasteredUltraInstinctWatch.AnimationPlayed = nil
    task.spawn(function()
        local MasteredUltraInstinctHumanoid = MasteredUltraInstinctCharacter:WaitForChild("Humanoid", 5)
        if not MasteredUltraInstinctEnabled
            or MasteredUltraInstinctPlayer.Character ~= MasteredUltraInstinctCharacter
            or MasteredUltraInstinctPlayerWatches[MasteredUltraInstinctPlayer] ~= MasteredUltraInstinctWatch
            or not MasteredUltraInstinctHumanoid then
            return
        end
        local MasteredUltraInstinctAnimator = MasteredUltraInstinctHumanoid:FindFirstChildOfClass("Animator")
            or MasteredUltraInstinctHumanoid:WaitForChild("Animator", 5)
        if not MasteredUltraInstinctEnabled or MasteredUltraInstinctPlayerWatches[MasteredUltraInstinctPlayer] ~= MasteredUltraInstinctWatch then
            return
        end
        MasteredUltraInstinctAnimator = MasteredUltraInstinctAnimator or MasteredUltraInstinctHumanoid
        MasteredUltraInstinctWatch.AnimationPlayed = MasteredUltraInstinctAnimator.AnimationPlayed:Connect(function(MasteredUltraInstinctTrack)
            MasteredUltraInstinctOnAnimation(MasteredUltraInstinctPlayer, MasteredUltraInstinctTrack)
        end)
    end)
end

local function MasteredUltraInstinctWatchRemotePlayer(MasteredUltraInstinctPlayer)
    if MasteredUltraInstinctPlayer == MasteredUltraInstinctLocalPlayer
        or MasteredUltraInstinctPlayerWatches[MasteredUltraInstinctPlayer] then
        return
    end
    local MasteredUltraInstinctWatch = {}
    MasteredUltraInstinctPlayerWatches[MasteredUltraInstinctPlayer] = MasteredUltraInstinctWatch
    MasteredUltraInstinctWatch.CharacterAdded = MasteredUltraInstinctPlayer.CharacterAdded:Connect(function(MasteredUltraInstinctCharacter)
        MasteredUltraInstinctHookCharacter(MasteredUltraInstinctPlayer, MasteredUltraInstinctCharacter)
    end)
    if MasteredUltraInstinctPlayer.Character then
        MasteredUltraInstinctHookCharacter(MasteredUltraInstinctPlayer, MasteredUltraInstinctPlayer.Character)
    end
end

local function MasteredUltraInstinctHeartbeat(MasteredUltraInstinctDeltaTime)
    local MasteredUltraInstinctNow = os.clock()
    for _, MasteredUltraInstinctThreat in pairs(MasteredUltraInstinctThreats) do
        if MasteredUltraInstinctThreat.ExpiresAt <= MasteredUltraInstinctNow
            and MasteredUltraInstinctThreat.Player ~= MasteredUltraInstinctActiveSource then
            MasteredUltraInstinctDismissThreat(MasteredUltraInstinctThreat)
        end
    end
    if MasteredUltraInstinctNow - MasteredUltraInstinctLastHudUpdate >= 0.1 then
        MasteredUltraInstinctLastHudUpdate = MasteredUltraInstinctNow
        MasteredUltraInstinctUpdateThreatHud(MasteredUltraInstinctNow)
    end

    if not MasteredUltraInstinctDefenseActive then
        return
    end
    local MasteredUltraInstinctCharacter = MasteredUltraInstinctLocalPlayer and MasteredUltraInstinctLocalPlayer.Character
    local MasteredUltraInstinctRoot = MasteredUltraInstinctGetRoot(MasteredUltraInstinctCharacter)
    local MasteredUltraInstinctHumanoid = MasteredUltraInstinctGetHumanoid(MasteredUltraInstinctCharacter)
    if not MasteredUltraInstinctCharacter
        or not MasteredUltraInstinctRoot
        or not MasteredUltraInstinctHumanoid
        or MasteredUltraInstinctHumanoid.Health <= 0 then
        MasteredUltraInstinctDeactivate(false)
        return
    end
    if MasteredUltraInstinctNow >= MasteredUltraInstinctActiveUntil then
        if MasteredUltraInstinctExtendUntilSourceDies and not MasteredUltraInstinctSourceDied then
            MasteredUltraInstinctActiveUntil = MasteredUltraInstinctNow + MasteredUltraInstinctActiveDuration
        else
            MasteredUltraInstinctDeactivate(true)
        end
        return
    end
    MasteredUltraInstinctMoveClone(MasteredUltraInstinctDeltaTime, MasteredUltraInstinctCharacter)
    MasteredUltraInstinctUpdateCloneAndCamera()
    if MasteredUltraInstinctNow - MasteredUltraInstinctLastAuraUpdate >= M.Config.Aura.UpdateInterval then
        MasteredUltraInstinctLastAuraUpdate = MasteredUltraInstinctNow
        MasteredUltraInstinctUpdateAura(MasteredUltraInstinctNow)
    end
end

local function MasteredUltraInstinctStopWatchingEveryone()
    local MasteredUltraInstinctWatched = {}
    for MasteredUltraInstinctPlayer in pairs(MasteredUltraInstinctPlayerWatches) do
        table.insert(MasteredUltraInstinctWatched, MasteredUltraInstinctPlayer)
    end
    for _, MasteredUltraInstinctPlayer in ipairs(MasteredUltraInstinctWatched) do
        MasteredUltraInstinctDisconnectWatch(MasteredUltraInstinctPlayer)
    end
    MasteredUltraInstinctDisconnect(MasteredUltraInstinctPlayerAddedConnection)
    MasteredUltraInstinctDisconnect(MasteredUltraInstinctPlayerRemovingConnection)
    MasteredUltraInstinctPlayerAddedConnection = nil
    MasteredUltraInstinctPlayerRemovingConnection = nil
    table.clear(MasteredUltraInstinctLastTriggerAt)
end

function M.Configure(MasteredUltraInstinctOverrides)
    assert(type(MasteredUltraInstinctOverrides) == "table", "Configure expects a table")
    MasteredUltraInstinctMergeConfig(M.Config, MasteredUltraInstinctOverrides)
    MasteredUltraInstinctRebuildDodgeIndex()
end

function M.SetDodges(MasteredUltraInstinctDodges)
    assert(type(MasteredUltraInstinctDodges) == "table", "SetDodges expects a table")
    M.Config.Dodges = MasteredUltraInstinctDodges
    MasteredUltraInstinctRebuildDodgeIndex()
end

function M.Start(MasteredUltraInstinctOverrides)
    if MasteredUltraInstinctEnabled then
        M.Stop()
    end
    if MasteredUltraInstinctOverrides then
        M.Configure(MasteredUltraInstinctOverrides)
    else
        MasteredUltraInstinctRebuildDodgeIndex()
    end
    MasteredUltraInstinctLocalPlayer = MasteredUltraInstinctPlayers.LocalPlayer
    assert(MasteredUltraInstinctLocalPlayer, "MasteredUltraInstinct4DDodge must run on the client")
    MasteredUltraInstinctEnabled = true
    MasteredUltraInstinctBuildHud()
    for _, MasteredUltraInstinctPlayer in ipairs(MasteredUltraInstinctPlayers:GetPlayers()) do
        MasteredUltraInstinctWatchRemotePlayer(MasteredUltraInstinctPlayer)
    end
    MasteredUltraInstinctPlayerAddedConnection = MasteredUltraInstinctPlayers.PlayerAdded:Connect(MasteredUltraInstinctWatchRemotePlayer)
    MasteredUltraInstinctPlayerRemovingConnection = MasteredUltraInstinctPlayers.PlayerRemoving:Connect(MasteredUltraInstinctDisconnectWatch)
    MasteredUltraInstinctCharacterRemovingConnection = MasteredUltraInstinctLocalPlayer.CharacterRemoving:Connect(function()
        MasteredUltraInstinctDeactivate(false)
    end)
    MasteredUltraInstinctHeartbeatConnection = MasteredUltraInstinctRunService.Heartbeat:Connect(MasteredUltraInstinctHeartbeat)
    MasteredUltraInstinctRenderConnection = MasteredUltraInstinctRunService.RenderStepped:Connect(MasteredUltraInstinctRenderThreatLines)
end

function M.Stop()
    MasteredUltraInstinctPendingToken += 1
    MasteredUltraInstinctPendingDodge = nil
    if MasteredUltraInstinctDefenseActive then
        MasteredUltraInstinctDeactivate(true)
    end
    MasteredUltraInstinctEnabled = false
    MasteredUltraInstinctStopWatchingEveryone()
    MasteredUltraInstinctDisconnect(MasteredUltraInstinctHeartbeatConnection)
    MasteredUltraInstinctDisconnect(MasteredUltraInstinctRenderConnection)
    MasteredUltraInstinctDisconnect(MasteredUltraInstinctCharacterRemovingConnection)
    MasteredUltraInstinctHeartbeatConnection = nil
    MasteredUltraInstinctRenderConnection = nil
    MasteredUltraInstinctCharacterRemovingConnection = nil
    for _, MasteredUltraInstinctThreat in pairs(MasteredUltraInstinctThreats) do
        MasteredUltraInstinctDismissThreat(MasteredUltraInstinctThreat)
    end
    if MasteredUltraInstinctHud then
        MasteredUltraInstinctHud:Destroy()
    end
    MasteredUltraInstinctHud = nil
    MasteredUltraInstinctHudCards = nil
    MasteredUltraInstinctHudLines = nil
    MasteredUltraInstinctLastHudUpdate = 0
    MasteredUltraInstinctLastAuraUpdate = 0
end

function M.TriggerDodge(MasteredUltraInstinctDodgeName)
    for _, MasteredUltraInstinctDodge in pairs(MasteredUltraInstinctDodgeByAnimationId) do
        if MasteredUltraInstinctDodge.Name == MasteredUltraInstinctDodgeName then
            MasteredUltraInstinctTrigger(MasteredUltraInstinctDodge, nil)
            return true
        end
    end
    return false
end

function M.IsDefenseActive()
    return MasteredUltraInstinctDefenseActive
end

function M.IsActive()
    return M.IsDefenseActive()
end

function M.GetActiveDodge()
    return MasteredUltraInstinctActiveDodgeName
end

function M.GetMarkedThreats()
    local MasteredUltraInstinctResult = {}
    local MasteredUltraInstinctOrigin = MasteredUltraInstinctVirtualRootPosition
        or (MasteredUltraInstinctGetRoot(MasteredUltraInstinctLocalPlayer and MasteredUltraInstinctLocalPlayer.Character) or {}).Position
    for _, MasteredUltraInstinctThreat in ipairs(MasteredUltraInstinctThreatList()) do
        local MasteredUltraInstinctRoot = MasteredUltraInstinctGetRoot(MasteredUltraInstinctThreat.Player.Character)
        table.insert(MasteredUltraInstinctResult, {
            player = MasteredUltraInstinctThreat.Player,
            name = MasteredUltraInstinctThreat.Player.Name,
            displayName = MasteredUltraInstinctThreat.Player.DisplayName,
            ability = MasteredUltraInstinctThreat.DodgeName,
            distance = MasteredUltraInstinctRoot and MasteredUltraInstinctOrigin
                and (MasteredUltraInstinctRoot.Position - MasteredUltraInstinctOrigin).Magnitude
                or nil,
            isActiveSource = MasteredUltraInstinctThreat.Player == MasteredUltraInstinctActiveSource,
        })
    end
    return MasteredUltraInstinctResult
end

function M.GetThreatState()
    return {
        defenseActive = MasteredUltraInstinctDefenseActive,
        activeDodge = MasteredUltraInstinctActiveDodgeName,
        activeSource = MasteredUltraInstinctActiveSource,
        markedThreats = M.GetMarkedThreats(),
    }
end

-- Stable hub-facing API. Keep this reference rather than reaching into module
-- locals so other modules can query status without changing this script.
M.API = {
    GetMarkedThreats = function()
        return M.GetMarkedThreats()
    end,
    IsDefenseActive = function()
        return M.IsDefenseActive()
    end,
    GetThreatState = function()
        return M.GetThreatState()
    end,
}

return M
