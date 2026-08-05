local M = {}

local MUIPlayers = game:GetService("Players")
local MUIRunService = game:GetService("RunService")
local MUIUserInputService = game:GetService("UserInputService")
local MUITweenService = game:GetService("TweenService")
local MUIDebris = game:GetService("Debris")
local MUISoundService = game:GetService("SoundService")
local MUIContentProvider = game:GetService("ContentProvider")

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
local MUIEnabled = false
local MUILocalPlayer = nil
local MUIDefenseActive = false
local MUIActivationToken = 0
local MUIPendingToken = 0
local MUIPendingDodge = nil
local MUIActiveUntil = 0
local MUIActiveDuration = 0
local MUIActiveDodgeName = nil
local MUIActiveSource = nil
local MUIExtendUntilSourceDies = false
local MUISourceDied = false

local MUIDodgeByAnimationId = {}
local MUILastTriggerAt = {}
local MUIPlayerWatches = {}
local MUIThreats = {}
local MUIThumbnailCache = {}
local MUIOriginalTransparency = setmetatable({}, { __mode = "k" })

local MUIHeartbeatConnection = nil
local MUIRenderConnection = nil
local MUIPlayerAddedConnection = nil
local MUIPlayerRemovingConnection = nil
local MUICharacterRemovingConnection = nil
local MUISourceDiedConnection = nil

local MUICloneModel = nil
local MUICloneRoot = nil
local MUICloneCountdownGui = nil
local MUICloneCountdownLabel = nil
local MUICloneCountdownSubLabel = nil
local MUIAuraFolder = nil
local MUIAuraRings = {}
local MUIAuraLight = nil
local MUICameraSubject = nil
local MUISkyVelocity = nil
local MUISkyPosition = nil
local MUIVirtualRootPosition = nil
local MUISkyY = nil
local MUIFootOffset = 3
local MUIHud = nil
local MUIHudCards = nil
local MUIHudLines = nil
local MUILastHudUpdate = 0
local MUILastAuraUpdate = 0

local function MUIDisconnect(MUIConnection)
    if MUIConnection then
        pcall(function()
            MUIConnection:Disconnect()
        end)
    end
end

local function MUIAssetNumber(MUIValue)
    return tostring(MUIValue or ""):match("%d+") or ""
end

local function MUIAssetId(MUIValue)
    local MUIId = MUIAssetNumber(MUIValue)
    return MUIId ~= "" and "rbxassetid://" .. MUIId or ""
end

local function MUIGetRoot(MUICharacter)
    return MUICharacter
        and (MUICharacter:FindFirstChild("HumanoidRootPart")
            or MUICharacter:FindFirstChild("Torso"))
end

local function MUIGetHumanoid(MUICharacter)
    return MUICharacter
        and MUICharacter:FindFirstChildOfClass("Humanoid")
end

local function MUIGetFootOffset(MUICharacter)
    local MUIHumanoid = MUIGetHumanoid(MUICharacter)
    local MUIRoot = MUIGetRoot(MUICharacter)
    if MUIHumanoid and MUIRoot then
        return MUIHumanoid.HipHeight + MUIRoot.Size.Y * 0.5
    end
    return 3
end

local function MUIMergeConfig(MUITarget, MUISource)
    for MUIKey, MUIValue in pairs(MUISource) do
        if MUIKey ~= "Dodges"
            and type(MUIValue) == "table"
            and type(MUITarget[MUIKey]) == "table" then
            MUIMergeConfig(
                MUITarget[MUIKey],
                MUIValue
            )
        else
            MUITarget[MUIKey] = MUIValue
        end
    end
end

local function MUIRebuildDodgeIndex()
    table.clear(MUIDodgeByAnimationId)
    for MUIName, MUIDodge in pairs(M.Config.Dodges) do
        local MUIId = MUIAssetNumber(MUIDodge.AnimationId)
        local MUIDelay = tonumber(MUIDodge.Delay) or 0
        local MUIDuration = tonumber(MUIDodge.Duration)
        if MUIId ~= ""
            and MUIDelay >= 0
            and MUIDuration
            and MUIDuration > 0 then
            MUIDodgeByAnimationId[MUIId] = {
                Name = MUIName,
                Delay = MUIDelay,
                Duration = MUIDuration,
                ExtendUntilSourceDies = MUIDodge.ExtendUntilSourceDies == true,
            }
        end
    end
end

-- Sounds are parented to SoundService and locally preloaded. This handles the
-- common failure mode where a short-lived Sound is destroyed before it loads.
local function MUIPlayLocalSound(MUISoundId)
    local MUIResolvedId = MUIAssetId(MUISoundId)
    if MUIResolvedId == "" then
        return
    end

    local MUISound = Instance.new("Sound")
    MUISound.Name = "MUISound"
    MUISound.SoundId = MUIResolvedId
    MUISound.Volume = M.Config.SoundVolume
    MUISound.Parent = MUISoundService
    MUIDebris:AddItem(MUISound, 12)

    task.spawn(function()
        pcall(function()
            MUIContentProvider:PreloadAsync({ MUISound })
        end)
    end)
    local MUIPlayed = pcall(function()
        if MUISoundService.PlayLocalSound then
            MUISoundService:PlayLocalSound(MUISound)
        else
            MUISound:Play()
        end
    end)
    if not MUIPlayed then
        pcall(function()
            MUISound:Play()
        end)
    end
end

local function MUIDestroySkyForces()
    if MUISkyVelocity then
        MUISkyVelocity:Destroy()
        MUISkyVelocity = nil
    end
    if MUISkyPosition then
        MUISkyPosition:Destroy()
        MUISkyPosition = nil
    end
end

local function MUIDestroyClone()
    if MUICloneModel then
        MUICloneModel:Destroy()
    end
    MUICloneModel = nil
    MUICloneRoot = nil
    MUICloneCountdownGui = nil
    MUICloneCountdownLabel = nil
    MUICloneCountdownSubLabel = nil
    MUIAuraFolder = nil
    MUIAuraRings = {}
    MUIAuraLight = nil
end

local function MUIDestroyCameraSubject()
    if MUICameraSubject then
        MUICameraSubject:Destroy()
    end
    MUICameraSubject = nil
end

local function MUIHideRealCharacter(MUICharacter)
    table.clear(MUIOriginalTransparency)
    for _, MUIInstance in ipairs(MUICharacter:GetDescendants()) do
        if MUIInstance:IsA("BasePart") or MUIInstance:IsA("Decal") then
            MUIOriginalTransparency[MUIInstance] =
                MUIInstance.LocalTransparencyModifier
            MUIInstance.LocalTransparencyModifier = 1
        end
    end
end

local function MUIRestoreRealCharacter()
    for MUIInstance, MUITransparency in pairs(MUIOriginalTransparency) do
        if MUIInstance.Parent then
            pcall(function()
                MUIInstance.LocalTransparencyModifier = MUITransparency
            end)
        end
    end
    table.clear(MUIOriginalTransparency)
end

local function MUICreateClone(MUICharacter, MUIStartCFrame)
    local MUIPreviousArchivable = MUICharacter.Archivable
    MUICharacter.Archivable = true
    local MUIOk, MUIClone = pcall(function()
        return MUICharacter:Clone()
    end)
    MUICharacter.Archivable = MUIPreviousArchivable
    if not MUIOk or not MUIClone then
        return nil, nil
    end

    MUIClone.Name = "MUIClone"
    for _, MUIInstance in ipairs(MUIClone:GetDescendants()) do
        if MUIInstance:IsA("Script")
            or MUIInstance:IsA("LocalScript")
            or MUIInstance:IsA("ModuleScript") then
            MUIInstance:Destroy()
        elseif MUIInstance:IsA("BasePart") then
            MUIInstance.Anchored = true
            MUIInstance.CanCollide = false
            MUIInstance.CanTouch = false
            MUIInstance.CanQuery = false
            MUIInstance.CastShadow = false
        elseif MUIInstance:IsA("Humanoid") then
            MUIInstance.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
            MUIInstance.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
            MUIInstance.AutoRotate = false
        end
    end

    MUIClone.Parent = workspace
    MUIClone:PivotTo(MUIStartCFrame)
    return MUIClone, MUIGetRoot(MUIClone)
end

local function MUICreateCameraSubject(MUIPosition)
    local MUISubject = Instance.new("Part")
    MUISubject.Name = "MUICameraSubject"
    MUISubject.Size = Vector3.one
    MUISubject.Transparency = 1
    MUISubject.Anchored = true
    MUISubject.CanCollide = false
    MUISubject.CanTouch = false
    MUISubject.CanQuery = false
    MUISubject.CFrame = CFrame.new(
        MUIPosition + Vector3.new(0, M.Config.CloneHeadOffset, 0)
    )
    MUISubject.Parent = workspace
    return MUISubject
end

local function MUICreateCloneCountdown()
    if not MUICloneModel or not MUICloneRoot then
        return
    end
    local MUIAdornee = MUICloneModel:FindFirstChild("Head") or MUICloneRoot
    MUICloneCountdownGui = Instance.new("BillboardGui")
    MUICloneCountdownGui.Name = "MUICloneCountdown"
    MUICloneCountdownGui.Adornee = MUIAdornee
    MUICloneCountdownGui.AlwaysOnTop = true
    MUICloneCountdownGui.LightInfluence = 0
    MUICloneCountdownGui.Size = UDim2.fromOffset(130, 52)
    MUICloneCountdownGui.StudsOffset = Vector3.new(0, 4.4, 0)
    MUICloneCountdownGui.Parent = MUICloneModel

    local MUIPanel = Instance.new("Frame")
    MUIPanel.BackgroundColor3 = Color3.fromRGB(7, 7, 9)
    MUIPanel.BackgroundTransparency = 0.12
    MUIPanel.BorderSizePixel = 0
    MUIPanel.Size = UDim2.fromScale(1, 1)
    MUIPanel.Parent = MUICloneCountdownGui
    Instance.new("UICorner", MUIPanel).CornerRadius = UDim.new(0, 7)
    local MUIStroke = Instance.new("UIStroke")
    MUIStroke.Color = Color3.fromRGB(255, 215, 35)
    MUIStroke.Thickness = 2
    MUIStroke.Parent = MUIPanel

    MUICloneCountdownLabel = Instance.new("TextLabel")
    MUICloneCountdownLabel.Name = "MUITimeRemaining"
    MUICloneCountdownLabel.BackgroundTransparency = 1
    MUICloneCountdownLabel.Position = UDim2.fromOffset(0, 3)
    MUICloneCountdownLabel.Size = UDim2.new(1, 0, 0, 28)
    MUICloneCountdownLabel.Font = Enum.Font.GothamBlack
    MUICloneCountdownLabel.TextColor3 = Color3.fromRGB(255, 222, 56)
    MUICloneCountdownLabel.TextSize = 21
    MUICloneCountdownLabel.Text = "5.0s"
    MUICloneCountdownLabel.Parent = MUIPanel

    MUICloneCountdownSubLabel = Instance.new("TextLabel")
    MUICloneCountdownSubLabel.Name = "MUIFormStatus"
    MUICloneCountdownSubLabel.BackgroundTransparency = 1
    MUICloneCountdownSubLabel.Position = UDim2.fromOffset(0, 30)
    MUICloneCountdownSubLabel.Size = UDim2.new(1, 0, 0, 17)
    MUICloneCountdownSubLabel.Font = Enum.Font.GothamBold
    MUICloneCountdownSubLabel.TextColor3 = Color3.fromRGB(235, 235, 235)
    MUICloneCountdownSubLabel.TextSize = 9
    MUICloneCountdownSubLabel.Text = "RETURN TO NORMAL"
    MUICloneCountdownSubLabel.Parent = MUIPanel
end

local function MUIUpdateCloneCountdown(MUINow)
    if not MUICloneCountdownLabel or not MUICloneCountdownLabel.Parent then
        return
    end
    local MUIRemaining = math.max(0, MUIActiveUntil - MUINow)
    MUICloneCountdownLabel.Text = string.format("%.1fs", MUIRemaining)
    if MUICloneCountdownSubLabel then
        MUICloneCountdownSubLabel.Text = MUIExtendUntilSourceDies
            and "SOURCE LOCK ACTIVE"
            or "RETURN TO NORMAL"
    end
end

-- The original aura is retained, but its instances are created once and only
-- their transforms are touched while the 4D defense is active.
local function MUICreateParticle(
    MUIParent,
    MUIColor,
    MUIRate,
    MUISpeed,
    MUILifetime,
    MUISize,
    MUITransparency
)
    local MUIEmitter = Instance.new("ParticleEmitter")
    MUIEmitter.Texture = "rbxasset://textures/particles/smoke_main.dds"
    MUIEmitter.Color = ColorSequence.new(MUIColor)
    MUIEmitter.LightEmission = 0.9
    MUIEmitter.LightInfluence = 0
    MUIEmitter.Rate = MUIRate
    MUIEmitter.Lifetime = MUILifetime
    MUIEmitter.Speed = MUISpeed
    MUIEmitter.Acceleration = Vector3.new(0, 10, 0)
    MUIEmitter.SpreadAngle = Vector2.new(22, 22)
    MUIEmitter.EmissionDirection = Enum.NormalId.Top
    MUIEmitter.Size = MUISize
    MUIEmitter.Transparency = MUITransparency
    MUIEmitter.Parent = MUIParent
end

local function MUICreateAuraRing(
    MUIFolder,
    MUIColor,
    MUIRadius,
    MUIYOffset,
    MUIPhase
)
    local MUIRing = {
        Parts = {},
        Radius = MUIRadius,
        YOffset = MUIYOffset,
        Phase = MUIPhase,
    }
    local MUISegments = math.max(8, math.floor(M.Config.Aura.RingSegments))
    for _ = 1, MUISegments do
        local MUIPart = Instance.new("Part")
        MUIPart.Name = "MUIAuraRing"
        MUIPart.Anchored = true
        MUIPart.CanCollide = false
        MUIPart.CanTouch = false
        MUIPart.CanQuery = false
        MUIPart.CastShadow = false
        MUIPart.Material = Enum.Material.Neon
        MUIPart.Color = MUIColor
        MUIPart.Transparency = 0.32
        MUIPart.Size = Vector3.new(0.12, 0.12, 0.12)
        MUIPart.Parent = MUIFolder
        table.insert(MUIRing.Parts, MUIPart)
    end
    return MUIRing
end

local function MUICreateAura()
    if not M.Config.Aura.Enabled or not MUICloneRoot or not MUICloneModel then
        return
    end
    local MUIConfig = M.Config.Aura
    MUIAuraFolder = Instance.new("Folder")
    MUIAuraFolder.Name = "MUIAura"
    MUIAuraFolder.Parent = MUICloneModel
    local MUILower = Instance.new("Attachment")
    MUILower.Position = Vector3.new(0, -2.2, 0)
    MUILower.Parent = MUICloneRoot
    local MUIUpper = Instance.new("Attachment")
    MUIUpper.Position = Vector3.new(0, 2.2, 0)
    MUIUpper.Parent = MUICloneRoot
    MUICreateParticle(
        MUILower, MUIConfig.CyanColor,
        MUIConfig.ParticleRate, NumberRange.new(4, 8), NumberRange.new(0.46, 0.82),
        NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.9), NumberSequenceKeypoint.new(0.45, 2.1), NumberSequenceKeypoint.new(1, 0.15) }),
        NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.38), NumberSequenceKeypoint.new(0.65, 0.58), NumberSequenceKeypoint.new(1, 1) })
    )
    MUICreateParticle(
        MUIUpper, MUIConfig.VioletColor,
        math.floor(MUIConfig.ParticleRate * 0.42), NumberRange.new(2, 5), NumberRange.new(0.55, 1.05),
        NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(0.5, 1.45), NumberSequenceKeypoint.new(1, 0.05) }),
        NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(1, 1) })
    )
    MUIAuraLight = Instance.new("PointLight")
    MUIAuraLight.Name = "MUIAuraGlow"
    MUIAuraLight.Color = MUIConfig.CyanColor
    MUIAuraLight.Brightness = 1.8
    MUIAuraLight.Range = 18
    MUIAuraLight.Shadows = false
    MUIAuraLight.Parent = MUICloneRoot
    MUIAuraRings = {
        MUICreateAuraRing(MUIAuraFolder, MUIConfig.CoreColor, 3.2, -1.7, 0),
        MUICreateAuraRing(MUIAuraFolder, MUIConfig.CyanColor, 4.7, -0.1, math.pi),
        MUICreateAuraRing(MUIAuraFolder, MUIConfig.VioletColor, 3.8, 1.6, math.pi * 0.5),
    }
end

local function MUIUpdateAura(MUINow)
    if not MUICloneRoot then
        return
    end
    for MUIRingIndex, MUIRing in ipairs(MUIAuraRings) do
        local MUICount = #MUIRing.Parts
        local MUIRadius = MUIRing.Radius + math.sin(MUINow * 3.2 + MUIRing.Phase) * 0.18
        local MUIY = MUIRing.YOffset + math.sin(MUINow * 2.4 + MUIRing.Phase) * 0.22
        local MUIRotation = MUINow
            * (MUIRingIndex % 2 == 0 and -1.6 or 1.25)
            + MUIRing.Phase
        local MUIArc = (2 * math.pi * MUIRadius / MUICount) * 0.82
        for MUIIndex, MUIPart in ipairs(MUIRing.Parts) do
            local MUIAngle = MUIRotation
                + (MUIIndex - 1) / MUICount * math.pi * 2
            local MUIRadial = Vector3.new(math.cos(MUIAngle), 0, math.sin(MUIAngle))
            local MUITangent = Vector3.new(-math.sin(MUIAngle), 0, math.cos(MUIAngle))
            local MUIPosition = MUICloneRoot.Position
                + MUIRadial * MUIRadius + Vector3.new(0, MUIY, 0)
            MUIPart.Size = Vector3.new(0.09, 0.09, MUIArc)
            MUIPart.CFrame = CFrame.lookAt(MUIPosition, MUIPosition + MUITangent)
            MUIPart.Transparency = 0.25 + math.abs(math.sin(MUINow * 4 + MUIIndex)) * 0.35
        end
    end
    if MUIAuraLight then
        MUIAuraLight.Brightness = 1.4 + (math.sin(MUINow * 7) + 1) * 0.65
    end
end

local function MUIGroundPosition(MUIPosition, MUICharacter)
    local MUIRayParams = RaycastParams.new()
    MUIRayParams.FilterType = Enum.RaycastFilterType.Exclude
    MUIRayParams.FilterDescendantsInstances = {
        MUICharacter,
        MUICloneModel,
        MUICameraSubject,
    }
    local MUIOrigin = Vector3.new(
        MUIPosition.X,
        MUIPosition.Y + M.Config.GroundProbeHeight,
        MUIPosition.Z
    )
    local MUIHit = workspace:Raycast(
        MUIOrigin,
        Vector3.new(0, -M.Config.GroundProbeDepth, 0),
        MUIRayParams
    )
    if MUIHit then
        return Vector3.new(
            MUIPosition.X,
            MUIHit.Position.Y + MUIFootOffset,
            MUIPosition.Z
        )
    end
    return MUIPosition
end

local function MUIBuildHud()
    if MUIHud and MUIHud.Parent then
        return
    end
    local MUIPlayerGui = MUILocalPlayer:FindFirstChildOfClass("PlayerGui")
    if not MUIPlayerGui then
        return
    end

    MUIHud = Instance.new("ScreenGui")
    MUIHud.Name = "MUIThreatHUD"
    MUIHud.IgnoreGuiInset = true
    MUIHud.ResetOnSpawn = false
    MUIHud.DisplayOrder = 75
    MUIHud.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    MUIHud.Parent = MUIPlayerGui

    MUIHudCards = Instance.new("Frame")
    MUIHudCards.Name = "MUIThreatCards"
    MUIHudCards.BackgroundTransparency = 1
    MUIHudCards.Size = UDim2.fromScale(1, 1)
    MUIHudCards.Parent = MUIHud

    MUIHudLines = Instance.new("Frame")
    MUIHudLines.Name = "MUIDangerLines"
    MUIHudLines.BackgroundTransparency = 1
    MUIHudLines.Size = UDim2.fromScale(1, 1)
    MUIHudLines.Parent = MUIHud
end

local function MUISetText(MUIObject, MUIText)
    if MUIObject and MUIObject.Parent then
        MUIObject.Text = MUIText
    end
end

local function MUICreateThreatCard(MUIThreat)
    MUIBuildHud()
    if not MUIHudCards then
        return
    end

    local MUIGroup = Instance.new("CanvasGroup")
    MUIGroup.Name = "MUIAlert_" .. MUIThreat.Player.UserId
    MUIGroup.BackgroundTransparency = 1
    MUIGroup.GroupTransparency = 1
    MUIGroup.Parent = MUIHudCards
    local MUIScale = Instance.new("UIScale")
    MUIScale.Scale = 0.82
    MUIScale.Parent = MUIGroup

    local MUIPanel = Instance.new("Frame")
    MUIPanel.BackgroundColor3 = Color3.fromRGB(8, 8, 10)
    MUIPanel.BackgroundTransparency = 0.08
    MUIPanel.BorderSizePixel = 0
    MUIPanel.Size = UDim2.fromScale(1, 1)
    MUIPanel.Parent = MUIGroup
    Instance.new("UICorner", MUIPanel).CornerRadius = UDim.new(0, 7)
    local MUIStroke = Instance.new("UIStroke")
    MUIStroke.Color = Color3.fromRGB(255, 209, 35)
    MUIStroke.Thickness = 2
    MUIStroke.Parent = MUIPanel

    local MUIDangerStrip = Instance.new("Frame")
    MUIDangerStrip.BackgroundColor3 = Color3.fromRGB(255, 209, 35)
    MUIDangerStrip.BorderSizePixel = 0
    MUIDangerStrip.Size = UDim2.new(0, 5, 1, -14)
    MUIDangerStrip.Position = UDim2.fromOffset(8, 7)
    MUIDangerStrip.Parent = MUIPanel
    Instance.new("UICorner", MUIDangerStrip).CornerRadius = UDim.new(1, 0)

    local function MUICardLabel(MUIName, MUIY, MUIFont, MUISize, MUIColor)
        local MUILabel = Instance.new("TextLabel")
        MUILabel.Name = MUIName
        MUILabel.BackgroundTransparency = 1
        MUILabel.Position = UDim2.new(0, 25, 0, MUIY)
        MUILabel.Size = UDim2.new(1, -88, 0, MUISize + 5)
        MUILabel.Font = MUIFont
        MUILabel.TextSize = MUISize
        MUILabel.TextColor3 = MUIColor
        MUILabel.TextXAlignment = Enum.TextXAlignment.Left
        MUILabel.TextTruncate = Enum.TextTruncate.AtEnd
        MUILabel.Parent = MUIPanel
        return MUILabel
    end

    MUICardLabel("ThreatLabel", 8, Enum.Font.GothamBold, 13, Color3.fromRGB(255, 221, 65)).Text = "THREAT DETECTED"
    local MUIName = MUICardLabel("NameLabel", 29, Enum.Font.GothamBold, 13, Color3.fromRGB(245, 245, 245))
    local MUIDistance = MUICardLabel("DistanceLabel", 50, Enum.Font.Gotham, 11, Color3.fromRGB(220, 220, 220))
    local MUIHealth = MUICardLabel("HealthLabel", 67, Enum.Font.Gotham, 11, Color3.fromRGB(220, 220, 220))
    local MUIAbility = MUICardLabel("AbilityLabel", 84, Enum.Font.GothamBold, 10, Color3.fromRGB(255, 209, 35))
    MUIAbility.Size = UDim2.new(1, -35, 0, 17)

    local MUIImageHolder = Instance.new("Frame")
    MUIImageHolder.BackgroundColor3 = Color3.fromRGB(255, 209, 35)
    MUIImageHolder.BorderSizePixel = 0
    MUIImageHolder.Position = UDim2.new(1, -57, 0, 26)
    MUIImageHolder.Size = UDim2.fromOffset(44, 44)
    MUIImageHolder.Parent = MUIPanel
    Instance.new("UICorner", MUIImageHolder).CornerRadius = UDim.new(1, 0)
    local MUIImage = Instance.new("ImageLabel")
    MUIImage.Name = "Portrait"
    MUIImage.BackgroundColor3 = Color3.fromRGB(13, 13, 16)
    MUIImage.BorderSizePixel = 0
    MUIImage.Position = UDim2.fromOffset(2, 2)
    MUIImage.Size = UDim2.fromOffset(40, 40)
    MUIImage.Parent = MUIImageHolder
    Instance.new("UICorner", MUIImage).CornerRadius = UDim.new(1, 0)

    MUIThreat.Card = MUIGroup
    MUIThreat.CardScale = MUIScale
    MUIThreat.CardLabels = {
        Name = MUIName,
        Distance = MUIDistance,
        Health = MUIHealth,
        Ability = MUIAbility,
        Portrait = MUIImage,
    }
    MUITweenService:Create(
        MUIGroup,
        TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { GroupTransparency = 0 }
    ):Play()
    MUITweenService:Create(
        MUIScale,
        TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        { Scale = 1 }
    ):Play()

    local MUIUserId = MUIThreat.Player.UserId
    local MUICachedThumbnail = MUIThumbnailCache[MUIUserId]
    if MUICachedThumbnail then
        MUIImage.Image = MUICachedThumbnail
    else
        task.spawn(function()
            local MUIOk, MUIThumbnail = pcall(function()
                return MUIPlayers:GetUserThumbnailAsync(
                    MUIUserId,
                    Enum.ThumbnailType.HeadShot,
                    Enum.ThumbnailSize.Size100x100
                )
            end)
            if MUIOk then
                MUIThumbnailCache[MUIUserId] = MUIThumbnail
                if MUIThreat.Card
                    and MUIThreat.Card.Parent
                    and MUIThreat.CardLabels.Portrait then
                    MUIThreat.CardLabels.Portrait.Image = MUIThumbnail
                end
            end
        end)
    end
end

local function MUICreateLine(MUIThreat)
    MUIBuildHud()
    if not MUIHudLines then
        return
    end
    local MUIOuter = Instance.new("Frame")
    MUIOuter.Name = "MUIDangerLine"
    MUIOuter.AnchorPoint = Vector2.new(0, 0.5)
    MUIOuter.BackgroundColor3 = Color3.new(0, 0, 0)
    MUIOuter.BorderSizePixel = 0
    MUIOuter.Visible = false
    MUIOuter.ZIndex = 2
    MUIOuter.Parent = MUIHudLines
    local MUIInner = Instance.new("Frame")
    MUIInner.AnchorPoint = Vector2.new(0, 0.5)
    MUIInner.BackgroundColor3 = Color3.fromRGB(255, 214, 24)
    MUIInner.BorderSizePixel = 0
    MUIInner.Position = UDim2.new(0, 0, 0.5, 0)
    MUIInner.Size = UDim2.new(1, 0, 0, M.Config.ThreatLineInnerThickness)
    MUIInner.ZIndex = 3
    MUIInner.Parent = MUIOuter
    MUIThreat.Line = MUIOuter
end

local function MUICreateFarLight(MUIThreat)
    local MUICharacter = MUIThreat.Player.Character
    local MUIRoot = MUIGetRoot(MUICharacter)
    if not MUIRoot then
        return
    end
    local MUIHighlight = Instance.new("Highlight")
    MUIHighlight.Name = "MUIThreatFarLight"
    MUIHighlight.FillColor = Color3.fromRGB(255, 202, 0)
    MUIHighlight.OutlineColor = Color3.fromRGB(255, 240, 120)
    MUIHighlight.FillTransparency = 0.55
    MUIHighlight.OutlineTransparency = 0
    MUIHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    MUIHighlight.Adornee = MUICharacter
    MUIHighlight.Parent = MUICharacter

    local MUIBillboard = Instance.new("BillboardGui")
    MUIBillboard.Name = "MUIThreatBeacon"
    MUIBillboard.Adornee = MUIRoot
    MUIBillboard.AlwaysOnTop = true
    MUIBillboard.LightInfluence = 0
    MUIBillboard.Size = UDim2.fromOffset(86, 86)
    MUIBillboard.StudsOffset = Vector3.new(0, 4.5, 0)
    MUIBillboard.Parent = MUICharacter
    local MUIBeacon = Instance.new("TextLabel")
    MUIBeacon.BackgroundTransparency = 1
    MUIBeacon.Size = UDim2.fromScale(1, 1)
    MUIBeacon.Font = Enum.Font.GothamBlack
    MUIBeacon.Text = "!"
    MUIBeacon.TextColor3 = Color3.fromRGB(255, 218, 35)
    MUIBeacon.TextStrokeColor3 = Color3.new(0, 0, 0)
    MUIBeacon.TextStrokeTransparency = 0
    MUIBeacon.TextSize = 74
    MUIBeacon.Parent = MUIBillboard
    local MUIBeaconScale = Instance.new("UIScale")
    MUIBeaconScale.Parent = MUIBillboard
    local MUIPointLight = Instance.new("PointLight")
    MUIPointLight.Name = "MUIThreatFarLight"
    MUIPointLight.Color = Color3.fromRGB(255, 214, 24)
    MUIPointLight.Brightness = 8
    MUIPointLight.Range = M.Config.ThreatFarLightRange
    MUIPointLight.Shadows = false
    MUIPointLight.Parent = MUIRoot

    MUIThreat.Highlight = MUIHighlight
    MUIThreat.Beacon = MUIBillboard
    MUIThreat.BeaconScale = MUIBeaconScale
    MUIThreat.FarLight = MUIPointLight
end

local function MUIDestroyThreatVisuals(MUIThreat)
    if MUIThreat.Line then
        MUIThreat.Line:Destroy()
    end
    if MUIThreat.Highlight then
        MUIThreat.Highlight:Destroy()
    end
    if MUIThreat.Beacon then
        MUIThreat.Beacon:Destroy()
    end
    if MUIThreat.FarLight then
        MUIThreat.FarLight:Destroy()
    end
    MUIThreat.Line = nil
    MUIThreat.Highlight = nil
    MUIThreat.Beacon = nil
    MUIThreat.FarLight = nil
end

local function MUIDismissThreat(MUIThreat)
    if MUIThreat.Removing then
        return
    end
    MUIThreat.Removing = true
    MUIDestroyThreatVisuals(MUIThreat)
    if MUIThreat.Card and MUIThreat.Card.Parent then
        local MUICard = MUIThreat.Card
        if MUIThreat.CardScale then
            MUITweenService:Create(
                MUIThreat.CardScale,
                TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
                { Scale = 0.9 }
            ):Play()
        end
        MUITweenService:Create(
            MUICard,
            TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            { GroupTransparency = 1 }
        ):Play()
        task.delay(0.18, function()
            if MUICard then
                MUICard:Destroy()
            end
        end)
    end
    MUIThreats[MUIThreat.Player] = nil
end

local function MUIMarkThreat(MUIPlayer, MUIDodge)
    if not MUIPlayer or MUIPlayer == MUILocalPlayer then
        return
    end
    local MUINow = os.clock()
    local MUIThreat = MUIThreats[MUIPlayer]
    if MUIThreat then
        MUIThreat.DodgeName = MUIDodge.Name
        MUIThreat.ExpiresAt = MUINow + M.Config.ThreatAlertLifetime
        MUIThreat.Removing = false
        return
    end

    MUIThreat = {
        Player = MUIPlayer,
        DodgeName = MUIDodge.Name,
        MarkedAt = MUINow,
        ExpiresAt = MUINow + M.Config.ThreatAlertLifetime,
    }
    MUIThreats[MUIPlayer] = MUIThreat
    MUICreateThreatCard(MUIThreat)
    MUICreateLine(MUIThreat)
    MUICreateFarLight(MUIThreat)
end

local function MUIThreatList()
    local MUIList = {}
    for _, MUIThreat in pairs(MUIThreats) do
        table.insert(MUIList, MUIThreat)
    end
    table.sort(MUIList, function(MUILeft, MUIRight)
        return MUILeft.MarkedAt > MUIRight.MarkedAt
    end)
    return MUIList
end

local function MUIUpdateThreatHud(MUINow)
    local MUIList = MUIThreatList()
    local MUICount = #MUIList
    local MUICardWidth = math.max(118, 238 - math.max(0, MUICount - 1) * 22)
    local MUICardHeight = math.max(74, 108 - math.max(0, MUICount - 1) * 7)
    local MUIOriginRoot = MUIDefenseActive
        and MUICloneRoot
        or MUIGetRoot(MUILocalPlayer and MUILocalPlayer.Character)
    local MUIOriginPosition = MUIOriginRoot
        and MUIOriginRoot.Position
        or MUIVirtualRootPosition

    for MUIIndex, MUIThreat in ipairs(MUIList) do
        local MUICharacter = MUIThreat.Player.Character
        local MUIRoot = MUIGetRoot(MUICharacter)
        local MUIHumanoid = MUIGetHumanoid(MUICharacter)
        if not MUIRoot or not MUIHumanoid or MUIHumanoid.Health <= 0 then
            MUIDismissThreat(MUIThreat)
            continue
        end

        if MUIThreat.Card and MUIThreat.Card.Parent then
            MUIThreat.Card.AnchorPoint = Vector2.new(1, 0)
            MUIThreat.Card.Position = UDim2.new(
                1,
                -M.Config.ThreatHudRightOffset - (MUIIndex - 1) * (MUICardWidth + 8),
                0,
                M.Config.ThreatHudTopOffset
            )
            MUIThreat.Card.Size = UDim2.fromOffset(MUICardWidth, MUICardHeight)
            local MUIDistance = MUIOriginPosition
                and (MUIRoot.Position - MUIOriginPosition).Magnitude
                or 0
            MUISetText(
                MUIThreat.CardLabels.Name,
                MUIThreat.Player.DisplayName or MUIThreat.Player.Name
            )
            MUISetText(MUIThreat.CardLabels.Distance, string.format("%.0f studs", MUIDistance))
            MUISetText(
                MUIThreat.CardLabels.Health,
                string.format("HP  %.0f / %.0f", math.max(0, MUIHumanoid.Health), MUIHumanoid.MaxHealth)
            )
            MUISetText(MUIThreat.CardLabels.Ability, MUIThreat.DodgeName)
        end

        if MUIThreat.BeaconScale then
            MUIThreat.BeaconScale.Scale = 0.92 + math.abs(math.sin(MUINow * 7)) * 0.18
        end
        if MUIThreat.Highlight then
            MUIThreat.Highlight.FillTransparency = 0.44 + math.abs(math.sin(MUINow * 6)) * 0.22
        end
    end
end

local function MUIRenderThreatLines()
    local MUICamera = workspace.CurrentCamera
    local MUIOriginRoot = MUIDefenseActive
        and MUICloneRoot
        or MUIGetRoot(MUILocalPlayer and MUILocalPlayer.Character)
    local MUIOriginPosition = MUIOriginRoot
        and MUIOriginRoot.Position
        or MUIVirtualRootPosition
    if not MUICamera or not MUIOriginPosition then
        return
    end
    local MUIOriginScreen, MUIOriginVisible =
        MUICamera:WorldToViewportPoint(MUIOriginPosition)

    for _, MUIThreat in pairs(MUIThreats) do
        local MUILine = MUIThreat.Line
        local MUITargetRoot = MUIGetRoot(MUIThreat.Player.Character)
        if not MUILine or not MUITargetRoot or not MUIOriginVisible then
            if MUILine then
                MUILine.Visible = false
            end
            continue
        end
        local MUITargetScreen, MUITargetVisible =
            MUICamera:WorldToViewportPoint(MUITargetRoot.Position)
        if not MUITargetVisible then
            MUILine.Visible = false
            continue
        end
        local MUIDelta = Vector2.new(
            MUITargetScreen.X - MUIOriginScreen.X,
            MUITargetScreen.Y - MUIOriginScreen.Y
        )
        local MUILength = MUIDelta.Magnitude
        if MUILength < 2 then
            MUILine.Visible = false
            continue
        end
        MUILine.Visible = true
        MUILine.Position = UDim2.fromOffset(MUIOriginScreen.X, MUIOriginScreen.Y)
        MUILine.Size = UDim2.fromOffset(MUILength, M.Config.ThreatLineOuterThickness)
        MUILine.Rotation = math.deg(math.atan2(MUIDelta.Y, MUIDelta.X))
    end
end

local function MUIClearSourceDeathWatch()
    MUIDisconnect(MUISourceDiedConnection)
    MUISourceDiedConnection = nil
    MUISourceDied = false
end

local function MUIWatchSourceDeath(MUIPlayer)
    MUIClearSourceDeathWatch()
    if not MUIPlayer then
        return
    end
    local MUIHumanoid = MUIGetHumanoid(MUIPlayer.Character)
    if not MUIHumanoid then
        return
    end
    if MUIHumanoid.Health <= 0 then
        MUISourceDied = true
        return
    end
    MUISourceDiedConnection = MUIHumanoid.Died:Connect(function()
        MUISourceDied = true
    end)
end

local function MUIStartSkyLift(MUIRoot, MUIToken)
    MUIDestroySkyForces()
    MUISkyVelocity = Instance.new("BodyVelocity")
    MUISkyVelocity.Name = "MUILift"
    MUISkyVelocity.Velocity = Vector3.new(0, M.Config.LiftSpeed, 0)
    MUISkyVelocity.MaxForce = Vector3.new(0, M.Config.HoldForce, 0)
    MUISkyVelocity.Parent = MUIRoot

    task.spawn(function()
        local MUIStartedAt = os.clock()
        while MUIDefenseActive
            and MUIToken == MUIActivationToken
            and MUIRoot.Parent do
            if MUIRoot.Position.Y >= MUISkyY - 20
                or os.clock() - MUIStartedAt >= M.Config.LiftTimeout then
                break
            end
            task.wait(0.05)
        end
        if not MUIDefenseActive
            or MUIToken ~= MUIActivationToken
            or not MUIRoot.Parent then
            return
        end
        if MUISkyVelocity then
            MUISkyVelocity:Destroy()
            MUISkyVelocity = nil
        end
        MUISkyPosition = Instance.new("BodyPosition")
        MUISkyPosition.Name = "MUIHold"
        MUISkyPosition.Position = Vector3.new(
            MUIRoot.Position.X,
            MUISkyY,
            MUIRoot.Position.Z
        )
        MUISkyPosition.MaxForce = Vector3.new(M.Config.HoldForce, M.Config.HoldForce, M.Config.HoldForce)
        MUISkyPosition.P = 60000
        MUISkyPosition.D = 2500
        MUISkyPosition.Parent = MUIRoot
    end)
end

local MUIDeactivate

local function MUIBegin(MUIDodge, MUISource)
    local MUICharacter = MUILocalPlayer and MUILocalPlayer.Character
    local MUIRoot = MUIGetRoot(MUICharacter)
    local MUIHumanoid = MUIGetHumanoid(MUICharacter)
    if not MUICharacter
        or not MUIRoot
        or not MUIHumanoid
        or MUIHumanoid.Health <= 0 then
        return
    end

    MUIFootOffset = MUIGetFootOffset(MUICharacter)
    MUIVirtualRootPosition = MUIGroundPosition(
        MUIRoot.Position,
        MUICharacter
    )
    local _, MUIYaw = MUIRoot.CFrame:ToOrientation()
    local MUICloneCFrame = CFrame.new(MUIVirtualRootPosition)
        * CFrame.Angles(0, MUIYaw, 0)
    MUICloneModel, MUICloneRoot =
        MUICreateClone(MUICharacter, MUICloneCFrame)
    if not MUICloneRoot then
        MUIDestroyClone()
        MUIVirtualRootPosition = nil
        return
    end

    MUIDefenseActive = true
    MUIActivationToken += 1
    local MUIToken = MUIActivationToken
    MUIActiveDodgeName = MUIDodge.Name
    MUIActiveDuration = MUIDodge.Duration
    MUIActiveUntil = os.clock() + MUIDodge.Duration
    MUIActiveSource = MUISource
    MUIExtendUntilSourceDies =
        MUIDodge.ExtendUntilSourceDies == true and MUISource ~= nil
    MUIPendingDodge = nil
    MUISkyY = MUIVirtualRootPosition.Y + M.Config.SkyAltitude
    MUICameraSubject = MUICreateCameraSubject(MUIVirtualRootPosition)
    MUIHideRealCharacter(MUICharacter)
    MUICreateAura()
    MUICreateCloneCountdown()
    MUIWatchSourceDeath(MUISource)

    local MUICamera = workspace.CurrentCamera
    if MUICamera then
        MUICamera.CameraSubject = MUICameraSubject
    end
    MUIStartSkyLift(MUIRoot, MUIToken)
    MUIPlayLocalSound(M.Config.ActivationSoundId)
end

MUIDeactivate = function(MUIReturnToClone)
    if not MUIDefenseActive then
        return
    end
    MUIDefenseActive = false
    MUIActivationToken += 1
    MUIDestroySkyForces()
    MUIClearSourceDeathWatch()

    local MUICharacter = MUILocalPlayer and MUILocalPlayer.Character
    local MUIRoot = MUIGetRoot(MUICharacter)
    local MUIHumanoid = MUIGetHumanoid(MUICharacter)
    if MUIReturnToClone
        and MUIRoot
        and MUIHumanoid
        and MUIHumanoid.Health > 0
        and MUIVirtualRootPosition then
        local MUILandingPosition = MUIGroundPosition(
            MUIVirtualRootPosition,
            MUICharacter
        )
        local MUIYaw = 0
        if MUICloneRoot then
            local _, MUICloneYaw = MUICloneRoot.CFrame:ToOrientation()
            MUIYaw = MUICloneYaw
        end
        pcall(function()
            MUIHumanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
            MUIRoot.CFrame = CFrame.new(MUILandingPosition)
                * CFrame.Angles(0, MUIYaw, 0)
            MUIRoot.AssemblyLinearVelocity = Vector3.zero
            MUIRoot.AssemblyAngularVelocity = Vector3.zero
            task.defer(function()
                if MUIHumanoid.Parent then
                    MUIHumanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
                    MUIHumanoid:ChangeState(Enum.HumanoidStateType.Landed)
                end
            end)
        end)
    end

    local MUICamera = workspace.CurrentCamera
    if MUICamera and MUIHumanoid and MUIHumanoid.Parent then
        MUICamera.CameraSubject = MUIHumanoid
    end
    MUIRestoreRealCharacter()
    MUIDestroyClone()
    MUIDestroyCameraSubject()
    MUIVirtualRootPosition = nil
    MUISkyY = nil
    MUIActiveDodgeName = nil
    MUIActiveDuration = 0
    MUIActiveSource = nil
    MUIExtendUntilSourceDies = false
    MUIPlayLocalSound(M.Config.DeactivationSoundId)
end

local function MUIMoveClone(MUIDeltaTime, MUICharacter)
    if not M.Config.AllowCloneMovement or not MUIVirtualRootPosition then
        return
    end
    local MUICamera = workspace.CurrentCamera
    if not MUICamera then
        return
    end
    local MUILook = MUICamera.CFrame.LookVector
    local MUIRight = MUICamera.CFrame.RightVector
    local MUIForwardFlat = Vector3.new(MUILook.X, 0, MUILook.Z)
    local MUIRightFlat = Vector3.new(MUIRight.X, 0, MUIRight.Z)
    if MUIForwardFlat.Magnitude > 0 then MUIForwardFlat = MUIForwardFlat.Unit end
    if MUIRightFlat.Magnitude > 0 then MUIRightFlat = MUIRightFlat.Unit end
    local MUIMovement = Vector3.zero
    if MUIUserInputService:IsKeyDown(Enum.KeyCode.W) then MUIMovement += MUIForwardFlat end
    if MUIUserInputService:IsKeyDown(Enum.KeyCode.S) then MUIMovement -= MUIForwardFlat end
    if MUIUserInputService:IsKeyDown(Enum.KeyCode.D) then MUIMovement += MUIRightFlat end
    if MUIUserInputService:IsKeyDown(Enum.KeyCode.A) then MUIMovement -= MUIRightFlat end
    if MUIMovement.Magnitude <= 0 then
        return
    end
    local MUIProposed = MUIVirtualRootPosition
        + MUIMovement.Unit * M.Config.CloneWalkSpeed * MUIDeltaTime
    local MUIGrounded = MUIGroundPosition(MUIProposed, MUICharacter)
    local MUIYDelta = math.clamp(
        MUIGrounded.Y - MUIVirtualRootPosition.Y,
        -M.Config.MaxGroundStepPerSecond * MUIDeltaTime,
        M.Config.MaxGroundStepPerSecond * MUIDeltaTime
    )
    MUIVirtualRootPosition = Vector3.new(
        MUIProposed.X,
        MUIVirtualRootPosition.Y + MUIYDelta,
        MUIProposed.Z
    )
end

local function MUIUpdateCloneAndCamera()
    if not MUIVirtualRootPosition then
        return
    end
    local MUICamera = workspace.CurrentCamera
    local MUIYaw = 0
    if MUICamera then
        local MUILook = MUICamera.CFrame.LookVector
        if Vector3.new(MUILook.X, 0, MUILook.Z).Magnitude > 0.01 then
            MUIYaw = math.atan2(-MUILook.X, -MUILook.Z)
        end
    end
    if MUICloneModel and MUICloneRoot then
        MUICloneModel:PivotTo(
            CFrame.new(MUIVirtualRootPosition) * CFrame.Angles(0, MUIYaw, 0)
        )
    end
    if MUICameraSubject then
        MUICameraSubject.CFrame = CFrame.new(
            MUIVirtualRootPosition + Vector3.new(0, M.Config.CloneHeadOffset, 0)
        )
    end
    if MUISkyPosition and MUISkyY then
        MUISkyPosition.Position = Vector3.new(
            MUIVirtualRootPosition.X,
            MUISkyY,
            MUIVirtualRootPosition.Z
        )
    end
end

local function MUITrigger(MUIDodge, MUIPlayer)
    if not MUIEnabled or not MUIDodge then
        return
    end
    local MUINow = os.clock()
    local MUIKey = tostring(MUIPlayer and MUIPlayer.UserId or 0)
        .. ":" .. MUIDodge.Name
    if MUINow - (MUILastTriggerAt[MUIKey] or -math.huge)
        < M.Config.SameAnimationCooldown then
        return
    end
    MUILastTriggerAt[MUIKey] = MUINow
    MUIMarkThreat(MUIPlayer, MUIDodge)

    if MUIDefenseActive then
        if M.Config.RefreshOnRepeatedTrigger then
            MUIActiveUntil = math.max(
                MUIActiveUntil,
                MUINow + MUIDodge.Duration
            )
        end
        return
    end
    if MUIPendingDodge then
        return
    end
    if MUIDodge.Delay <= 0 then
        MUIBegin(MUIDodge, MUIPlayer)
        return
    end
    MUIPendingDodge = MUIDodge.Name
    MUIPendingToken += 1
    local MUIToken = MUIPendingToken
    task.delay(MUIDodge.Delay, function()
        if MUIToken ~= MUIPendingToken then
            return
        end
        MUIPendingDodge = nil
        if MUIEnabled and not MUIDefenseActive then
            MUIBegin(MUIDodge, MUIPlayer)
        end
    end)
end

local function MUIOnAnimation(MUIPlayer, MUITrack)
    local MUIAnimation = MUITrack and MUITrack.Animation
    local MUIId = MUIAnimation
        and MUIAssetNumber(MUIAnimation.AnimationId)
    if MUIId ~= "" then
        MUITrigger(MUIDodgeByAnimationId[MUIId], MUIPlayer)
    end
end

local function MUIDisconnectWatch(MUIPlayer)
    local MUIWatch = MUIPlayerWatches[MUIPlayer]
    if MUIWatch then
        MUIDisconnect(MUIWatch.CharacterAdded)
        MUIDisconnect(MUIWatch.AnimationPlayed)
        MUIPlayerWatches[MUIPlayer] = nil
    end
    local MUIThreat = MUIThreats[MUIPlayer]
    if MUIThreat then
        MUIDismissThreat(MUIThreat)
    end
    if MUIActiveSource == MUIPlayer then
        MUISourceDied = true
    end
end

local function MUIHookCharacter(MUIPlayer, MUICharacter)
    local MUIWatch = MUIPlayerWatches[MUIPlayer]
    if not MUIWatch then
        return
    end
    MUIDisconnect(MUIWatch.AnimationPlayed)
    MUIWatch.AnimationPlayed = nil
    task.spawn(function()
        local MUIHumanoid = MUICharacter:WaitForChild("Humanoid", 5)
        if not MUIEnabled
            or MUIPlayer.Character ~= MUICharacter
            or MUIPlayerWatches[MUIPlayer] ~= MUIWatch
            or not MUIHumanoid then
            return
        end
        local MUIAnimator = MUIHumanoid:FindFirstChildOfClass("Animator")
            or MUIHumanoid:WaitForChild("Animator", 5)
        if not MUIEnabled or MUIPlayerWatches[MUIPlayer] ~= MUIWatch then
            return
        end
        MUIAnimator = MUIAnimator or MUIHumanoid
        MUIWatch.AnimationPlayed = MUIAnimator.AnimationPlayed:Connect(function(MUITrack)
            MUIOnAnimation(MUIPlayer, MUITrack)
        end)
    end)
end

local function MUIWatchRemotePlayer(MUIPlayer)
    if MUIPlayer == MUILocalPlayer
        or MUIPlayerWatches[MUIPlayer] then
        return
    end
    local MUIWatch = {}
    MUIPlayerWatches[MUIPlayer] = MUIWatch
    MUIWatch.CharacterAdded = MUIPlayer.CharacterAdded:Connect(function(MUICharacter)
        MUIHookCharacter(MUIPlayer, MUICharacter)
    end)
    if MUIPlayer.Character then
        MUIHookCharacter(MUIPlayer, MUIPlayer.Character)
    end
end

local function MUIHeartbeat(MUIDeltaTime)
    local MUINow = os.clock()
    for _, MUIThreat in pairs(MUIThreats) do
        if MUIThreat.ExpiresAt <= MUINow
            and MUIThreat.Player ~= MUIActiveSource then
            MUIDismissThreat(MUIThreat)
        end
    end
    if MUINow - MUILastHudUpdate >= 0.1 then
        MUILastHudUpdate = MUINow
        MUIUpdateThreatHud(MUINow)
    end

    if not MUIDefenseActive then
        return
    end
    local MUICharacter = MUILocalPlayer and MUILocalPlayer.Character
    local MUIRoot = MUIGetRoot(MUICharacter)
    local MUIHumanoid = MUIGetHumanoid(MUICharacter)
    if not MUICharacter
        or not MUIRoot
        or not MUIHumanoid
        or MUIHumanoid.Health <= 0 then
        MUIDeactivate(false)
        return
    end
    if MUINow >= MUIActiveUntil then
        if MUIExtendUntilSourceDies and not MUISourceDied then
            MUIActiveUntil = MUINow + MUIActiveDuration
        else
            MUIDeactivate(true)
        end
        return
    end
    MUIMoveClone(MUIDeltaTime, MUICharacter)
    MUIUpdateCloneAndCamera()
    MUIUpdateCloneCountdown(MUINow)
    if MUINow - MUILastAuraUpdate >= M.Config.Aura.UpdateInterval then
        MUILastAuraUpdate = MUINow
        MUIUpdateAura(MUINow)
    end
end

local function MUIStopWatchingEveryone()
    local MUIWatched = {}
    for MUIPlayer in pairs(MUIPlayerWatches) do
        table.insert(MUIWatched, MUIPlayer)
    end
    for _, MUIPlayer in ipairs(MUIWatched) do
        MUIDisconnectWatch(MUIPlayer)
    end
    MUIDisconnect(MUIPlayerAddedConnection)
    MUIDisconnect(MUIPlayerRemovingConnection)
    MUIPlayerAddedConnection = nil
    MUIPlayerRemovingConnection = nil
    table.clear(MUILastTriggerAt)
end

function M.Configure(MUIOverrides)
    assert(type(MUIOverrides) == "table", "Configure expects a table")
    MUIMergeConfig(M.Config, MUIOverrides)
    MUIRebuildDodgeIndex()
end

function M.SetDodges(MUIDodges)
    assert(type(MUIDodges) == "table", "SetDodges expects a table")
    M.Config.Dodges = MUIDodges
    MUIRebuildDodgeIndex()
end

function M.Start(MUIOverrides)
    if MUIEnabled then
        M.Stop()
    end
    if MUIOverrides then
        M.Configure(MUIOverrides)
    else
        MUIRebuildDodgeIndex()
    end
    MUILocalPlayer = MUIPlayers.LocalPlayer
    assert(MUILocalPlayer, "MUI4DDodge must run on the client")
    MUIEnabled = true
    MUIBuildHud()
    for _, MUIPlayer in ipairs(MUIPlayers:GetPlayers()) do
        MUIWatchRemotePlayer(MUIPlayer)
    end
    MUIPlayerAddedConnection = MUIPlayers.PlayerAdded:Connect(MUIWatchRemotePlayer)
    MUIPlayerRemovingConnection = MUIPlayers.PlayerRemoving:Connect(MUIDisconnectWatch)
    MUICharacterRemovingConnection = MUILocalPlayer.CharacterRemoving:Connect(function()
        MUIDeactivate(false)
    end)
    MUIHeartbeatConnection = MUIRunService.Heartbeat:Connect(MUIHeartbeat)
    MUIRenderConnection = MUIRunService.RenderStepped:Connect(MUIRenderThreatLines)
end

function M.Stop()
    MUIPendingToken += 1
    MUIPendingDodge = nil
    if MUIDefenseActive then
        MUIDeactivate(true)
    end
    MUIEnabled = false
    MUIStopWatchingEveryone()
    MUIDisconnect(MUIHeartbeatConnection)
    MUIDisconnect(MUIRenderConnection)
    MUIDisconnect(MUICharacterRemovingConnection)
    MUIHeartbeatConnection = nil
    MUIRenderConnection = nil
    MUICharacterRemovingConnection = nil
    for _, MUIThreat in pairs(MUIThreats) do
        MUIDismissThreat(MUIThreat)
    end
    if MUIHud then
        MUIHud:Destroy()
    end
    MUIHud = nil
    MUIHudCards = nil
    MUIHudLines = nil
    MUILastHudUpdate = 0
    MUILastAuraUpdate = 0
end

function M.TriggerDodge(MUIDodgeName)
    for _, MUIDodge in pairs(MUIDodgeByAnimationId) do
        if MUIDodge.Name == MUIDodgeName then
            MUITrigger(MUIDodge, nil)
            return true
        end
    end
    return false
end

function M.IsDefenseActive()
    return MUIDefenseActive
end

function M.IsActive()
    return M.IsDefenseActive()
end

function M.GetActiveDodge()
    return MUIActiveDodgeName
end

function M.GetMarkedThreats()
    local MUIResult = {}
    local MUIOrigin = MUIVirtualRootPosition
        or (MUIGetRoot(MUILocalPlayer and MUILocalPlayer.Character) or {}).Position
    for _, MUIThreat in ipairs(MUIThreatList()) do
        local MUIRoot = MUIGetRoot(MUIThreat.Player.Character)
        table.insert(MUIResult, {
            player = MUIThreat.Player,
            name = MUIThreat.Player.Name,
            displayName = MUIThreat.Player.DisplayName,
            ability = MUIThreat.DodgeName,
            distance = MUIRoot and MUIOrigin
                and (MUIRoot.Position - MUIOrigin).Magnitude
                or nil,
            isActiveSource = MUIThreat.Player == MUIActiveSource,
        })
    end
    return MUIResult
end

function M.GetThreatState()
    return {
        defenseActive = MUIDefenseActive,
        activeDodge = MUIActiveDodgeName,
        activeSource = MUIActiveSource,
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
