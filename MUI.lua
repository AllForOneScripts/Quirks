local M = {}

local MUIPlayers = game:GetService("Players")
local MUIRunService = game:GetService("RunService")
local MUIUserInputService = game:GetService("UserInputService")
local MUITweenService = game:GetService("TweenService")
local MUIDebris = game:GetService("Debris")
local MUISoundService = game:GetService("SoundService")
local MUIContentProvider = game:GetService("ContentProvider")
local HttpService = game:GetService("HttpService")

M.Config = {
    Dodges = {
        Bakugo_Nuker = {
            AnimationId = "18673594132",
            Delay = 5,
            Duration = 5,
            Style = "Dodge",
            DisplayName = "Bakugo's Nuker",
        },
    },

    SkyAltitude = 1500,
    LiftSpeed = 900,
    LiftTimeout = 4,
    HoldForce = 9e8,
    SkySnapTolerance = 42,
    SkySafetyGrace = 0.35,
    SameAnimationCooldown = 0.20,
    RefreshOnRepeatedTrigger = true,

    AllowCloneMovement = true,
    CloneWalkSpeed = 105,
    CloneHeadOffset = 3,
    CloneJumpVelocity = 52,
    CloneJumpGravity = workspace.Gravity,
    CloneGroundEpsilon = 0.03,
    GroundProbeHeight = 220,
    GroundProbeDepth = 520,
    MaxGroundStepPerSecond = 28,

    ActivationSoundId = "140694363106746",
    DeactivationSoundId = "130457690489621",
    SoundVolume = 4,
    PingInstantThreshold = 0.18,
    Locale = "es",
    DodgeKey = Enum.KeyCode.Five,

    Aura = {
        Enabled = true,
        CoreColor = Color3.fromRGB(245, 250, 255),
        CyanColor = Color3.fromRGB(95, 225, 255),
        VioletColor = Color3.fromRGB(156, 115, 255),
        ParticleRate = 56,
    },

    ThreatAlertLifetime = 8,
    ThreatHudTopOffset = 330,
    ThreatHudRightOffset = 18,
    ThreatLineOuterThickness = 18,
    ThreatFarLightRange = 72,
    ImpulseRadius = 38,
    ImpulseWallHeight = 64,
    ImpulseWallThickness = 2,
    ImpulseEmergencyDistance = 12,
    FallSafetyY = -250,
    FallSafetyScanRadius = 360,
    FallSafetyPlatformLifetime = 7,
    ForceDismissKey = Enum.KeyCode.X,
}

local MUIEnabled = false
local MUILocalPlayer = nil
local MUIDefenseActive = false
local MUIActivationToken = 0
local MUIPendingToken = 0
local MUIPendingDodge = nil
local MUIPendingDodgeExpectedTime = nil
local MUIActiveUntil = 0
local MUIActiveDuration = 0
local MUIActiveDodgeName = nil
local MUIActiveStyle = nil
local MUIActiveSource = nil
local MUIActiveSources = {}

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
local MUIInputConnection = nil

local MUICloneModel = nil
local MUICloneRoot = nil
local MUICloneCountdownGui = nil
local MUICloneCountdownLabel = nil
local MUICloneCountdownSubLabel = nil
local MUICameraSubject = nil
local MUISkyVelocity = nil
local MUISkyPosition = nil
local MUIVirtualRootPosition = nil
local MUISkyY = nil
local MUIFootOffset = 3
local MUICloneFootOffset = 3
local MUICloneJumpOffset = 0
local MUICloneJumpVelocity = 0
local MUICloneTracks = {}
local MUICloneHighlight = nil
local MUIHud = nil
local MUIHudCards = nil
local MUIRealBodyLineDraw = nil
local MUILastHudUpdate = 0
local MUISkySafetyStartedAt = 0
local MUIHudDismissButton = nil
local MUIForceDismissAll
local MUIImpulseFolder = nil
local MUIImpulseZone = nil
local MUIFallPlatform = nil
local MUIFallPlatformLastTouched = 0

local MUIStrings = {
    es = {
        threat = "⚠ AMENAZA DETECTADA",
        impulse = "DEFENSA IMPULSE",
        dodge = "DEFENSA DODGE",
        mui_dialogue_step1 = "Puedes esquivar por\ntu cuenta si presionas\nel número 5 o si me\ndas click a mi",
        mui_dialogue_step2 = "¡Bien hecho!, ahora\nhazlo otra vez para\ndesactivar tu estado\nde esquive"
    },
    en = {
        threat = "⚠ THREAT DETECTED",
        impulse = "IMPULSE DEFENSE",
        dodge = "DODGE DEFENSE",
        mui_dialogue_step1 = "You can dodge on your\nown if you press the\nnumber 5 or if you\nclick on me",
        mui_dialogue_step2 = "Well done!, now do\nit again to disable\nyour dodge state"
    },
}

local function _reloadLocale()
    pcall(function()
        if type(readfile) == "function" then
            local data = readfile("AllForOne/lang.txt")
            if data == "EN" or data == "en" then
                M.Config.Locale = "en"
            elseif data == "ES" or data == "es" then
                M.Config.Locale = "es"
            end
        end
    end)
end

_reloadLocale()

local function getCleanKeyName(keyCode)
    if not keyCode then return "5" end
    local name = keyCode.Name
    local numberMap = {
        Zero = "0", One = "1", Two = "2", Three = "3", Four = "4",
        Five = "5", Six = "6", Seven = "7", Eight = "8", Nine = "9",
        KeypadZero = "0", KeypadOne = "1", KeypadTwo = "2", KeypadThree = "3",
        KeypadFour = "4", KeypadFive = "5", KeypadSix = "6", KeypadSeven = "7",
        KeypadEight = "8", KeypadNine = "9"
    }
    return numberMap[name] or name
end

local function getDialogueStep1()
    local locale = (M.Config.Locale or "es"):lower()
    local ft = MUIStrings[locale] or MUIStrings.es
    local raw = ft.mui_dialogue_step1 or MUIStrings.es.mui_dialogue_step1
    local keyName = getCleanKeyName(M.Config.DodgeKey)
    
    local translated = raw
    if locale == "es" then
        if tonumber(keyName) then
            translated = translated:gsub("el número 5", "el número " .. keyName):gsub("5", keyName)
        else
            translated = translated:gsub("el número 5", "la tecla " .. keyName):gsub("número 5", "la tecla " .. keyName):gsub("5", keyName)
        end
    else
        if tonumber(keyName) then
            translated = translated:gsub("number 5", "number " .. keyName):gsub("5", keyName)
        else
            translated = translated:gsub("number 5", "the " .. keyName .. " key"):gsub("5", keyName)
        end
    end
    return translated
end

local function MUIDisconnect(MUIConnection)
    if MUIConnection then
        pcall(function() MUIConnection:Disconnect() end)
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
    return MUICharacter and (MUICharacter:FindFirstChild("HumanoidRootPart") or MUICharacter:FindFirstChild("Torso"))
end

local function MUIGetVisualPosition(MUICharacter)
    if not MUICharacter then return nil end
    local MUIVisualPart = MUICharacter:FindFirstChild("UpperTorso") 
        or MUICharacter:FindFirstChild("Torso") 
        or MUIGetRoot(MUICharacter)
    return MUIVisualPart and MUIVisualPart.Position
end

local function MUIGetHumanoid(MUICharacter)
    return MUICharacter and MUICharacter:FindFirstChildOfClass("Humanoid")
end

local function MUIGetText(MUIKey)
    local locale = (M.Config.Locale or "es"):lower()
    local MUILocale = MUIStrings[locale] or MUIStrings.es
    return MUILocale[MUIKey] or MUIStrings.es[MUIKey] or MUIKey
end

local function MUIGetDodgeDisplayName(MUIDodge)
    return (MUIDodge and (MUIDodge.DisplayName or MUIDodge.Name)) or "Unknown"
end

local function MUIGetPingSeconds()
    local MUIOk, MUIPing = pcall(function()
        local MUIItem = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]
        return MUIItem and MUIItem:GetValue()
    end)
    local MUIValue = MUIOk and tonumber(MUIPing)
    return MUIValue and math.max(0, MUIValue / 1000) or 0
end

local function MUIGetFootOffset(MUICharacter)
    local MUIHumanoid = MUIGetHumanoid(MUICharacter)
    local MUIRoot = MUIGetRoot(MUICharacter)
    if MUIHumanoid and MUIRoot then
        return MUIHumanoid.HipHeight + MUIRoot.Size.Y * 0.5
    end
    return 3
end

local function MUIGetCloneFootOffset(MUIClone, MUIRoot)
    if not MUIClone or not MUIRoot then return 3 end
    local MUILowestY = math.huge
    local MUIFeet = {
        LeftFoot = true, RightFoot = true,
        LeftLowerLeg = true, RightLowerLeg = true,
        ["Left Leg"] = true, ["Right Leg"] = true,
    }
    for _, MUIPart in ipairs(MUIClone:GetDescendants()) do
        if MUIPart:IsA("BasePart") and MUIFeet[MUIPart.Name] then
            local MUIHalf = MUIPart.Size * 0.5
            for _, MUIX in ipairs({ -1, 1 }) do
                for _, MUIY in ipairs({ -1, 1 }) do
                    for _, MUIZ in ipairs({ -1, 1 }) do
                        local MUICorner = MUIPart.CFrame:PointToWorldSpace(
                            Vector3.new(MUIHalf.X * MUIX, MUIHalf.Y * MUIY, MUIHalf.Z * MUIZ)
                        )
                        MUILowestY = math.min(MUILowestY, MUIRoot.CFrame:PointToObjectSpace(MUICorner).Y)
                    end
                end
            end
        end
    end
    return MUILowestY == math.huge and 3 or -MUILowestY
end

local function MUIMergeConfig(MUITarget, MUISource)
    for MUIKey, MUIValue in pairs(MUISource) do
        if MUIKey ~= "Dodges" and type(MUIValue) == "table" and type(MUITarget[MUIKey]) == "table" then
            MUIMergeConfig(MUITarget[MUIKey], MUIValue)
        else
            MUITarget[MUIKey] = MUIValue
        end
    end
end

local function MUIRebuildDodgeIndex()
    MUIDodgeByAnimationId = {}
    for MUIName, MUIDodge in pairs(M.Config.Dodges) do
        local MUIId = MUIAssetNumber(MUIDodge.AnimationId)
        local MUIDelay = tonumber(MUIDodge.Delay) or 0
        local MUIDuration = tonumber(MUIDodge.Duration)
        if MUIId ~= "" and MUIDelay >= 0 and MUIDuration and MUIDuration > 0 then
            MUIDodgeByAnimationId[MUIId] = {
                Name = MUIName,
                DisplayName = MUIDodge.DisplayName or MUIName,
                Style = MUIDodge.Style == "Impulse" and "Impulse" or "Dodge",
                Delay = MUIDelay,
                Duration = MUIDuration,
            }
        end
    end
end

local function MUIPlayLocalSound(MUISoundId)
    local MUIResolvedId = MUIAssetId(MUISoundId)
    if MUIResolvedId == "" then return end
    local MUISound = Instance.new("Sound")
    MUISound.Name = "MUISound"
    MUISound.SoundId = MUIResolvedId
    MUISound.Volume = M.Config.SoundVolume
    MUISound.Parent = MUISoundService
    MUIDebris:AddItem(MUISound, 12)
    task.spawn(function() pcall(function() MUIContentProvider:PreloadAsync({ MUISound }) end) end)
    local MUIPlayed = pcall(function()
        if MUISoundService.PlayLocalSound then
            MUISoundService:PlayLocalSound(MUISound)
        else
            MUISound:Play()
        end
    end)
    if not MUIPlayed then pcall(function() MUISound:Play() end) end
end

local function MUIDestroySkyForces()
    if MUISkyVelocity then MUISkyVelocity:Destroy(); MUISkyVelocity = nil end
    if MUISkyPosition then MUISkyPosition:Destroy(); MUISkyPosition = nil end
end

local function MUIDestroyClone()
    if MUICloneHighlight then MUICloneHighlight:Destroy(); MUICloneHighlight = nil end
    if MUICloneModel then MUICloneModel:Destroy() end
    MUICloneModel = nil
    MUICloneRoot = nil
    MUICloneCountdownGui = nil
    MUICloneCountdownLabel = nil
    MUICloneCountdownSubLabel = nil
    MUICloneFootOffset = 3
    MUICloneJumpOffset = 0
    MUICloneJumpVelocity = 0
    MUICloneTracks = {}
end

local function MUIDestroyCameraSubject()
    if MUICameraSubject then MUICameraSubject:Destroy() end
    MUICameraSubject = nil
end

local function MUIHideRealCharacter(MUICharacter)
    MUIOriginalTransparency = setmetatable({}, { __mode = "k" })
    for _, MUIInstance in ipairs(MUICharacter:GetDescendants()) do
        if MUIInstance:IsA("BasePart") or MUIInstance:IsA("Decal") then
            MUIOriginalTransparency[MUIInstance] = MUIInstance.LocalTransparencyModifier
            MUIInstance.LocalTransparencyModifier = 1
        end
    end
end

local function MUIRestoreRealCharacter()
    for MUIInstance, MUITransparency in pairs(MUIOriginalTransparency) do
        if MUIInstance.Parent then pcall(function() MUIInstance.LocalTransparencyModifier = MUITransparency end) end
    end
    MUIOriginalTransparency = setmetatable({}, { __mode = "k" })
end

local function MUICreateClone(MUICharacter, MUIStartCFrame)
    local MUIPreviousArchivable = MUICharacter.Archivable
    MUICharacter.Archivable = true
    local MUIOk, MUIClone = pcall(function() return MUICharacter:Clone() end)
    MUICharacter.Archivable = MUIPreviousArchivable
    if not MUIOk or not MUIClone then return nil, nil end

    MUIClone.Name = "MUIClone"
    for _, MUIInstance in ipairs(MUIClone:GetDescendants()) do
        if MUIInstance:IsA("Script") or MUIInstance:IsA("LocalScript") or MUIInstance:IsA("ModuleScript") then
            MUIInstance:Destroy()
        elseif MUIInstance:IsA("BasePart") then
            MUIInstance.Anchored = false
            MUIInstance.CanCollide = false
            MUIInstance.CanTouch = false
            MUIInstance.CanQuery = false
            MUIInstance.CastShadow = false
            MUIInstance.Massless = true
        elseif MUIInstance:IsA("Humanoid") then
            MUIInstance.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
            MUIInstance.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
            MUIInstance.AutoRotate = false
        end
    end

    MUIClone.Parent = workspace
    local MUICloneRoot = MUIGetRoot(MUIClone)
    if MUICloneRoot then
        MUICloneRoot.Anchored = true
        MUIClone.PrimaryPart = MUICloneRoot
    end
    MUIClone:PivotTo(MUIStartCFrame)
    return MUIClone, MUICloneRoot
end

local function MUISyncCloneAnimation(MUICharacter)
    local MUIHumanoid = MUIGetHumanoid(MUICharacter)
    local MUICloneHumanoid = MUIGetHumanoid(MUICloneModel)
    if not MUIHumanoid or not MUICloneHumanoid then return end
    
    local MUIAnimator = MUIHumanoid:FindFirstChildOfClass("Animator")
    if not MUIAnimator then return end
    
    local MUICloneAnimator = MUICloneHumanoid:FindFirstChildOfClass("Animator")
    if not MUICloneAnimator then
        MUICloneAnimator = Instance.new("Animator")
        MUICloneAnimator.Parent = MUICloneHumanoid
    end
    
    local MUISeen = {}
    for _, MUITrack in ipairs(MUIAnimator:GetPlayingAnimationTracks()) do
        local MUIAnimation = MUITrack.Animation
        local MUIId = MUIAnimation and tostring(MUIAnimation.AnimationId) or ""
        
        if not string.find(MUIId, "215384594") then
            if MUIId ~= "" then
                MUISeen[MUIId] = true
                local MUICloneTrack = MUICloneTracks[MUIId]
                if not MUICloneTrack then
                    local MUIOk, MUILoaded = pcall(function() return MUICloneAnimator:LoadAnimation(MUIAnimation) end)
                    if MUIOk and MUILoaded then
                        MUICloneTrack = MUILoaded
                        MUICloneTracks[MUIId] = MUICloneTrack
                        MUICloneTrack.Priority = MUITrack.Priority
                        MUICloneTrack:Play(0)
                    end
                end
                if MUICloneTrack then
                    MUICloneTrack.Priority = MUITrack.Priority
                    MUICloneTrack:AdjustSpeed(MUITrack.Speed)
                    MUICloneTrack:AdjustWeight(MUITrack.WeightCurrent, 0)
                    if math.abs(MUICloneTrack.TimePosition - MUITrack.TimePosition) > 0.08 then
                        MUICloneTrack.TimePosition = MUITrack.TimePosition
                    end
                end
            end
        end
    end
    
    for MUIId, MUITrack in pairs(MUICloneTracks) do
        if not MUISeen[MUIId] then
            MUITrack:Stop(0.12)
            MUICloneTracks[MUIId] = nil
        end
    end

    for _, MUIMotor in ipairs(MUICharacter:GetDescendants()) do
        if MUIMotor:IsA("Motor6D") then
            local MUINames = {}
            local MUINode = MUIMotor
            while MUINode and MUINode ~= MUICharacter do
                table.insert(MUINames, 1, MUINode.Name)
                MUINode = MUINode.Parent
            end
            
            local MUITarget = MUICloneModel
            for _, MUIName in ipairs(MUINames) do
                MUITarget = MUITarget and MUITarget:FindFirstChild(MUIName)
            end
            
            if MUITarget and MUITarget:IsA("Motor6D") then
                MUITarget.Transform = MUIMotor.Transform
            end
        end
    end
end

local function MUICreateCameraSubject(MUIPosition)
    local MUISubject = Instance.new("Part")
    MUISubject.Name = "MUICameraSubject"
    MUISubject.Size = Vector3.new(1, 1, 1)
    MUISubject.Transparency = 1
    MUISubject.Anchored = true
    MUISubject.CanCollide = false
    MUISubject.CanTouch = false
    MUISubject.CanQuery = false
    MUISubject.CFrame = CFrame.new(MUIPosition + Vector3.new(0, M.Config.CloneHeadOffset, 0))
    MUISubject.Parent = workspace
    return MUISubject
end

local function MUICreateCloneCountdown()
    if not MUICloneModel or not MUICloneRoot then return end
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
    if not MUICloneCountdownLabel or not MUICloneCountdownLabel.Parent then return end
    local MUIRemaining = math.max(0, MUIActiveUntil - MUINow)
    MUICloneCountdownLabel.Text = string.format("%.1fs", MUIRemaining)
end

local function MUICreateDivineCloneVFX()
    if not M.Config.Aura.Enabled or not MUICloneModel then return end
    local GLOBAL_SCALE = 0.64 
    
    MUICloneHighlight = Instance.new("Highlight")
    MUICloneHighlight.Name = "MUI_DivineGlow"
    MUICloneHighlight.FillTransparency = 0.99
    MUICloneHighlight.FillColor = Color3.fromRGB(240, 250, 255)
    MUICloneHighlight.OutlineTransparency = 0
    MUICloneHighlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    MUICloneHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    MUICloneHighlight.Parent = MUICloneModel

    for _, MUIPart in ipairs(MUICloneModel:GetDescendants()) do
        if MUIPart:IsA("BasePart") and not MUIPart:FindFirstAncestorOfClass("Accessory")
            and MUIPart.Name ~= "HumanoidRootPart" and MUIPart.Transparency < 1 then
            
            local lowerName = MUIPart.Name:lower()
            local baseScale = math.clamp((MUIPart.Size.X + MUIPart.Size.Y + MUIPart.Size.Z) / 3, 0.6, 1.5)
            local partScale = baseScale * GLOBAL_SCALE
            
            local MUIAttachment = Instance.new("Attachment")
            MUIAttachment.Name = "MUI_DivineNode"
            
            local c1Multiplier = 1 
            
            if lowerName:find("torso") then
                MUIAttachment.Position = Vector3.new(0, 0, 0)
                partScale = partScale * 1.6 
            elseif lowerName:find("head") then
                MUIAttachment.Position = Vector3.new(0, -MUIPart.Size.Y * 0.35, 0)
                partScale = partScale * 1.2
            elseif lowerName:find("arm") or lowerName:find("hand") then
                MUIAttachment.Position = Vector3.new(0, 0, 0)
                partScale = partScale * 1.45 
                c1Multiplier = 0.5 
            elseif lowerName:find("foot") then
                MUIAttachment.Position = Vector3.new(0, MUIPart.Size.Y * 0.25, 0)
                partScale = partScale * 1.6 
            elseif lowerName:find("leg") then
                MUIAttachment.Position = Vector3.new(0, 0, 0)
                partScale = partScale * 1.55 
            end
            
            MUIAttachment.Parent = MUIPart

            local innerAura = Instance.new("ParticleEmitter")
            innerAura.Name = "C1_LiquidEdge"
            innerAura.Texture = "rbxassetid://74305120244941"
            innerAura.LockedToPart = true 
            innerAura.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)), 
                ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 240, 255))
            })
            innerAura.Rate = 20 
            innerAura.Lifetime = NumberRange.new(0.4, 0.6)
            innerAura.Speed = NumberRange.new(0.5, 1.2)
            
            if lowerName:find("leg") or lowerName:find("foot") then
                innerAura.Acceleration = Vector3.new(0, 5, 0) 
            elseif lowerName:find("arm") or lowerName:find("hand") then
                innerAura.Acceleration = Vector3.new(0, -12, 0) 
            else
                innerAura.Acceleration = Vector3.new(0, 3, 0)
            end
            
            innerAura.Rotation = NumberRange.new(-180, 180)
            innerAura.RotSpeed = NumberRange.new(-30, 30)
            innerAura.Size = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.9 * partScale * c1Multiplier),
                NumberSequenceKeypoint.new(0.5, 1.2 * partScale * c1Multiplier), 
                NumberSequenceKeypoint.new(1, 0.5 * partScale * c1Multiplier)
            })
            innerAura.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1),
                NumberSequenceKeypoint.new(0.2, 0.7), 
                NumberSequenceKeypoint.new(1, 1)
            })
            innerAura.LightEmission = 0.48
            innerAura.ZOffset = -0.1 
            innerAura.Parent = MUIAttachment
            
            local slidingFires = innerAura:Clone()
            slidingFires.Name = "C1_Sub_SlidingFires"
            slidingFires.Rate = 40 
            slidingFires.Lifetime = NumberRange.new(0.2, 0.4) 
            slidingFires.Speed = NumberRange.new(0.1, 0.5) 
            slidingFires.Acceleration = slidingFires.Acceleration * 2
            slidingFires.RotSpeed = NumberRange.new(200, 400) 
            slidingFires.Size = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.1 * partScale),
                NumberSequenceKeypoint.new(0.4, 0.3 * partScale), 
                NumberSequenceKeypoint.new(1, 0.05 * partScale)
            })
            slidingFires.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1),
                NumberSequenceKeypoint.new(0.1, 0.6), 
                NumberSequenceKeypoint.new(0.5, 0.8), 
                NumberSequenceKeypoint.new(0.8, 0.6), 
                NumberSequenceKeypoint.new(1, 1)
            })
            slidingFires.LightEmission = 1 
            slidingFires.ZOffset = -0.05 
            slidingFires.Parent = MUIAttachment

            local middleAura = Instance.new("ParticleEmitter")
            middleAura.Name = "C2_EnergyFlow"
            middleAura.Texture = "rbxassetid://74305120244941"
            middleAura.LockedToPart = true 
            middleAura.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(160, 80, 255)), 
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(60, 100, 255)), 
                ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 20, 150)) 
            })
            middleAura.Rate = 15
            middleAura.Lifetime = NumberRange.new(0.5, 0.8)
            middleAura.Speed = NumberRange.new(1.0, 2.5)
            
            if lowerName:find("leg") or lowerName:find("foot") then
                middleAura.Acceleration = Vector3.new(0, 8, 0) 
            elseif lowerName:find("arm") or lowerName:find("hand") then
                middleAura.Acceleration = Vector3.new(0, -20, 0) 
            else
                middleAura.Acceleration = Vector3.new(0, 6, 0)
            end
            
            middleAura.Rotation = NumberRange.new(-180, 180)
            middleAura.RotSpeed = NumberRange.new(-20, 20)
            middleAura.Size = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1.2 * partScale),
                NumberSequenceKeypoint.new(0.5, 1.6 * partScale),
                NumberSequenceKeypoint.new(1, 0.8 * partScale)
            })
            middleAura.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1),
                NumberSequenceKeypoint.new(0.3, 0.7), 
                NumberSequenceKeypoint.new(1, 1)
            })
            middleAura.LightEmission = 0.5 
            middleAura.ZOffset = -0.5 
            middleAura.Parent = MUIAttachment
            
            local crystalAura = Instance.new("ParticleEmitter")
            crystalAura.Name = "C4_CrystalAflame"
            crystalAura.Texture = "rbxassetid://74305120244941" 
            crystalAura.LockedToPart = true 
            crystalAura.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)), 
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(200, 255, 255)), 
                ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)) 
            })
            crystalAura.Rate = 15 
            crystalAura.Lifetime = NumberRange.new(0.3, 0.5) 
            crystalAura.Speed = NumberRange.new(1.5, 3.0) 
            
            if lowerName:find("arm") or lowerName:find("hand") then
                crystalAura.Acceleration = Vector3.new(0, -18, 0) 
            else
                crystalAura.Acceleration = Vector3.new(0, 8, 0) 
            end
            
            crystalAura.Rotation = NumberRange.new(-180, 180) 
            crystalAura.RotSpeed = NumberRange.new(50, 120) 
            crystalAura.Size = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.4 * partScale), 
                NumberSequenceKeypoint.new(0.5, 0.7 * partScale), 
                NumberSequenceKeypoint.new(1, 0.3 * partScale) 
            })
            crystalAura.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1), 
                NumberSequenceKeypoint.new(0.2, 0.5), 
                NumberSequenceKeypoint.new(0.8, 0.5), 
                NumberSequenceKeypoint.new(1, 1) 
            })
            crystalAura.LightEmission = 0.95 
            crystalAura.ZOffset = -0.8 
            crystalAura.Parent = MUIAttachment
        end
    end
end

local function MUIGroundPosition(MUIPosition, MUICharacter)
    local MUIRayParams = RaycastParams.new()
    MUIRayParams.FilterType = Enum.RaycastFilterType.Exclude
    MUIRayParams.FilterDescendantsInstances = { MUICharacter, MUICloneModel, MUICameraSubject }
    local MUIOrigin = Vector3.new(MUIPosition.X, MUIPosition.Y + M.Config.GroundProbeHeight, MUIPosition.Z)
    local MUIHit = workspace:Raycast(MUIOrigin, Vector3.new(0, -M.Config.GroundProbeDepth, 0), MUIRayParams)
    if MUIHit then
        return Vector3.new(MUIPosition.X, MUIHit.Position.Y + MUIFootOffset, MUIPosition.Z)
    end
    return MUIPosition
end

local function MUIBuildHud()
    if MUIHud and MUIHud.Parent then return end
    local MUIPlayerGui = MUILocalPlayer:FindFirstChildOfClass("PlayerGui")
    if not MUIPlayerGui then return end

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

    if not MUIRealBodyLineDraw then
        MUIRealBodyLineDraw = Drawing.new("Line")
        MUIRealBodyLineDraw.Color = Color3.fromRGB(70, 185, 255)
        MUIRealBodyLineDraw.Transparency = 0.42
        MUIRealBodyLineDraw.Thickness = 3
    end

    MUIHudDismissButton = Instance.new("TextButton")
    MUIHudDismissButton.Name = "MUIForceDismiss"
    MUIHudDismissButton.AnchorPoint = Vector2.new(1, 0)
    MUIHudDismissButton.Position = UDim2.new(1, -M.Config.ThreatHudRightOffset, 0, M.Config.ThreatHudTopOffset - 30)
    MUIHudDismissButton.Size = UDim2.fromOffset(26, 26)
    MUIHudDismissButton.BackgroundColor3 = Color3.fromRGB(90, 16, 18)
    MUIHudDismissButton.BackgroundTransparency = 0.08
    MUIHudDismissButton.BorderSizePixel = 0
    MUIHudDismissButton.Font = Enum.Font.GothamBlack
    MUIHudDismissButton.Text = "X"
    MUIHudDismissButton.TextColor3 = Color3.fromRGB(255, 225, 225)
    MUIHudDismissButton.TextSize = 14
    MUIHudDismissButton.Visible = false
    MUIHudDismissButton.Parent = MUIHud
    Instance.new("UICorner", MUIHudDismissButton).CornerRadius = UDim.new(0, 6)
    MUIHudDismissButton.Activated:Connect(function()
        if MUIForceDismissAll then MUIForceDismissAll() end
    end)
end

local function MUISetText(MUIObject, MUIText)
    if MUIObject and MUIObject.Parent then MUIObject.Text = MUIText end
end

local function MUICreateThreatCard(MUIThreat)
    MUIBuildHud()
    if not MUIHudCards then return end

    local MUIGroup = Instance.new("CanvasGroup")
    MUIGroup.Name = "MUIAlert_" .. MUIThreat.Player.UserId
    MUIGroup.BackgroundTransparency = 1
    MUIGroup.GroupTransparency = 1
    MUIGroup.Parent = MUIHudCards
    local MUIScale = Instance.new("UIScale")
    MUIScale.Scale = 0.82
    MUIScale.Parent = MUIGroup

    local MUIPanel = Instance.new("Frame")
    MUIPanel.BackgroundColor3 = Color3.fromRGB(6, 4, 12)
    MUIPanel.BackgroundTransparency = 0.15
    MUIPanel.BorderSizePixel = 0
    MUIPanel.Size = UDim2.fromScale(1, 1)
    MUIPanel.Parent = MUIGroup
    Instance.new("UICorner", MUIPanel).CornerRadius = UDim.new(0, 8)
    
    local MUIStroke = Instance.new("UIStroke")
    MUIStroke.Color = Color3.fromRGB(110, 30, 180)
    MUIStroke.Thickness = 1
    MUIStroke.Transparency = 0.5
    MUIStroke.Parent = MUIPanel

    local MUIDangerStrip = Instance.new("Frame")
    MUIDangerStrip.BackgroundColor3 = Color3.fromRGB(110, 30, 180)
    MUIDangerStrip.BorderSizePixel = 0
    MUIDangerStrip.Size = UDim2.new(0, 4, 1, -16)
    MUIDangerStrip.Position = UDim2.fromOffset(6, 8)
    MUIDangerStrip.Parent = MUIPanel
    Instance.new("UICorner", MUIDangerStrip).CornerRadius = UDim.new(1, 0)

    local function MUICardLabel(MUIName, MUIY, MUIFont, MUISize, MUIColor)
        local MUILabel = Instance.new("TextLabel")
        MUILabel.Name = MUIName
        MUILabel.BackgroundTransparency = 1
        MUILabel.Position = UDim2.new(0, 20, 0, MUIY)
        MUILabel.Size = UDim2.new(1, -88, 0, MUISize + 5)
        MUILabel.Font = MUIFont
        MUILabel.TextSize = MUISize
        MUILabel.TextColor3 = MUIColor
        MUILabel.TextXAlignment = Enum.TextXAlignment.Left
        MUILabel.TextTruncate = Enum.TextTruncate.AtEnd
        MUILabel.Parent = MUIPanel
        return MUILabel
    end

    MUICardLabel("ThreatLabel", 8, Enum.Font.GothamBold, 13, Color3.fromRGB(220, 190, 255)).Text = MUIGetText("threat")
    local MUIName = MUICardLabel("NameLabel", 29, Enum.Font.GothamBold, 13, Color3.fromRGB(245, 245, 245))
    local MUIDistance = MUICardLabel("DistanceLabel", 50, Enum.Font.Gotham, 11, Color3.fromRGB(200, 170, 255))
    local MUIHealth = MUICardLabel("HealthLabel", 67, Enum.Font.Legacy, 11, Color3.fromRGB(255, 150, 150))
    local MUIAbility = MUICardLabel("AbilityLabel", 84, Enum.Font.GothamBold, 10, Color3.fromRGB(150, 220, 255))
    MUIAbility.Size = UDim2.new(1, -35, 0, 17)

    local MUIImageHolder = Instance.new("Frame")
    MUIImageHolder.BackgroundColor3 = Color3.fromRGB(20, 10, 40)
    MUIImageHolder.BackgroundTransparency = 0.3
    MUIImageHolder.BorderSizePixel = 0
    MUIImageHolder.Position = UDim2.new(1, -65, 0, 20)
    MUIImageHolder.Size = UDim2.fromOffset(55, 55)
    MUIImageHolder.Parent = MUIPanel
    Instance.new("UICorner", MUIImageHolder).CornerRadius = UDim.new(1, 0)
    
    local MUIImage = Instance.new("ImageLabel")
    MUIImage.Name = "Portrait"
    MUIImage.BackgroundTransparency = 1
    MUIImage.BorderSizePixel = 0
    MUIImage.Position = UDim2.fromOffset(0, 0)
    MUIImage.Size = UDim2.fromScale(1, 1)
    MUIImage.Parent = MUIImageHolder
    Instance.new("UICorner", MUIImage).CornerRadius = UDim.new(1, 0)

    MUIThreat.Card = MUIGroup
    MUIThreat.CardScale = MUIScale
    MUIThreat.CardLabels = { Name = MUIName, Distance = MUIDistance, Health = MUIHealth, Ability = MUIAbility, Portrait = MUIImage }
    
    MUITweenService:Create(MUIGroup, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { GroupTransparency = 0 }):Play()
    MUITweenService:Create(MUIScale, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()

    local MUIUserId = MUIThreat.Player.UserId
    local MUICachedThumbnail = MUIThumbnailCache[MUIUserId]
    if MUICachedThumbnail then
        MUIImage.Image = MUICachedThumbnail
    else
        task.spawn(function()
            local MUIOk, MUIThumbnail = pcall(function() return MUIPlayers:GetUserThumbnailAsync(MUIUserId, Enum.ThumbnailType.AvatarBust, Enum.ThumbnailSize.Size420x420) end)
            if MUIOk then
                MUIThumbnailCache[MUIUserId] = MUIThumbnail
                if MUIThreat.Card and MUIThreat.Card.Parent and MUIThreat.CardLabels.Portrait then MUIThreat.CardLabels.Portrait.Image = MUIThumbnail end
            end
        end)
    end
end

local function MUICreateLine(MUIThreat)
    local gw = Drawing.new("Line"); gw.Transparency = 0.35
    local ol = Drawing.new("Line"); ol.Transparency = 0.65; ol.Color = Color3.fromRGB(0, 0, 0)
    local ln = Drawing.new("Line"); ln.Transparency = 1
    MUIThreat.ESP = { line = ln, outline = ol, glow = gw }
end

local function MUICreateFarLight(MUIThreat)
    local MUICharacter = MUIThreat.Player.Character
    local MUIRoot = MUIGetRoot(MUICharacter)
    if not MUIRoot then return end
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

    MUIThreat.Beacon = MUIBillboard
    MUIThreat.BeaconScale = MUIBeaconScale
    MUIThreat.FarLight = MUIPointLight
end

local function MUIDestroyThreatVisuals(MUIThreat)
    if MUIThreat.ESP then
        if MUIThreat.ESP.line then MUIThreat.ESP.line:Remove() end
        if MUIThreat.ESP.outline then MUIThreat.ESP.outline:Remove() end
        if MUIThreat.ESP.glow then MUIThreat.ESP.glow:Remove() end
        MUIThreat.ESP = nil
    end
    if MUIThreat.Beacon then MUIThreat.Beacon:Destroy() end
    if MUIThreat.FarLight then MUIThreat.FarLight:Destroy() end
    MUIThreat.Beacon = nil
    MUIThreat.FarLight = nil
end

local function MUIDismissThreat(MUIThreat)
    if MUIThreat.Removing then return end
    MUIThreat.Removing = true
    MUIDestroyThreatVisuals(MUIThreat)
    if MUIThreat.Card and MUIThreat.Card.Parent then
        local MUICard = MUIThreat.Card
        if MUIThreat.CardScale then
            MUITweenService:Create(MUIThreat.CardScale, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0.9 }):Play()
        end
        MUITweenService:Create(MUICard, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { GroupTransparency = 1 }):Play()
        task.delay(0.18, function() if MUICard then MUICard:Destroy() end end)
    end
    MUIThreats[MUIThreat.Player] = nil
end

local function MUIMarkThreat(MUIPlayer, MUIDodge)
    if not MUIPlayer or MUIPlayer == MUILocalPlayer then return end
    local MUINow = os.clock()
    local MUIThreat = MUIThreats[MUIPlayer]
    if MUIThreat then
        MUIThreat.DodgeName = MUIDodge.Name
        MUIThreat.DodgeDisplayName = MUIGetDodgeDisplayName(MUIDodge)
        MUIThreat.Style = MUIDodge.Style
        MUIThreat.ExpiresAt = MUINow + M.Config.ThreatAlertLifetime
        MUIThreat.Removing = false
        return
    end

    MUIThreat = {
        Player = MUIPlayer,
        DodgeName = MUIDodge.Name,
        DodgeDisplayName = MUIGetDodgeDisplayName(MUIDodge),
        Style = MUIDodge.Style,
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
    for _, MUIThreat in pairs(MUIThreats) do table.insert(MUIList, MUIThreat) end
    table.sort(MUIList, function(MUILeft, MUIRight) return MUILeft.MarkedAt > MUIRight.MarkedAt end)
    return MUIList
end

local function MUIUpdateThreatHud(MUINow)
    local MUIList = MUIThreatList()
    local MUICount = #MUIList
    if MUIHudDismissButton then MUIHudDismissButton.Visible = MUICount > 0 or MUIDefenseActive end
    local MUICardWidth = math.max(118, 238 - math.max(0, MUICount - 1) * 22)
    local MUICardHeight = math.max(74, 108 - math.max(0, MUICount - 1) * 7)
    local MUIOriginRoot = MUIDefenseActive and MUICloneRoot or MUIGetRoot(MUILocalPlayer and MUILocalPlayer.Character)
    local MUIOriginPosition = MUIOriginRoot and MUIOriginRoot.Position or MUIVirtualRootPosition

    for MUIIndex, MUIThreat in ipairs(MUIList) do
        local MUICharacter = MUIThreat.Player.Character
        local MUIRoot = MUIGetRoot(MUICharacter)
        local MUIHumanoid = MUIGetHumanoid(MUICharacter)
        if not MUIRoot or not MUIHumanoid or MUIHumanoid.Health <= 0 then
            MUIDismissThreat(MUIThreat)
        else
            if MUIThreat.Card and MUIThreat.Card.Parent then
                MUIThreat.Card.AnchorPoint = Vector2.new(1, 0)
                MUIThreat.Card.Position = UDim2.new(1, -M.Config.ThreatHudRightOffset - (MUIIndex - 1) * (MUICardWidth + 8), 0, M.Config.ThreatHudTopOffset)
                MUIThreat.Card.Size = UDim2.fromOffset(MUICardWidth, MUICardHeight)
                local MUIDistance = MUIOriginPosition and (MUIRoot.Position - MUIOriginPosition).Magnitude or 0
                MUISetText(MUIThreat.CardLabels.Name, MUIThreat.Player.DisplayName or MUIThreat.Player.Name)
                MUISetText(MUIThreat.CardLabels.Distance, string.format("%.0f studs", MUIDistance))
                MUISetText(MUIThreat.CardLabels.Health, string.format("❤️ %.0f / %.0f", math.max(0, MUIHumanoid.Health), MUIHumanoid.MaxHealth))
                MUISetText(MUIThreat.CardLabels.Ability, MUIThreat.DodgeDisplayName)
            end
            if MUIThreat.BeaconScale then MUIThreat.BeaconScale.Scale = 0.92 + math.abs(math.sin(MUINow * 7)) * 0.18 end
        end
    end
end

local function MUIRenderThreatLines()
    local MUICamera = workspace.CurrentCamera
    local MUIOriginRoot = MUIDefenseActive and MUICloneRoot or MUIGetRoot(MUILocalPlayer and MUILocalPlayer.Character)
    local MUIOriginPosition = MUIOriginRoot and MUIOriginRoot.Position or MUIVirtualRootPosition
    
    if not MUICamera or not MUIOriginPosition then
        if MUIRealBodyLineDraw then MUIRealBodyLineDraw.Visible = false end
        for _, MUIThreat in pairs(MUIThreats) do
            if MUIThreat.ESP then
                MUIThreat.ESP.line.Visible = false
                MUIThreat.ESP.outline.Visible = false
                MUIThreat.ESP.glow.Visible = false
            end
        end
        return
    end
    
    local MUIOriginScreen, MUIOriginVisible = MUICamera:WorldToViewportPoint(MUIOriginPosition)
    local MUIRealVisualPos = MUIGetVisualPosition(MUILocalPlayer and MUILocalPlayer.Character)
    local MUIRealScreen, MUIRealVisible
    
    if MUIRealVisualPos then
        MUIRealScreen, MUIRealVisible = MUICamera:WorldToViewportPoint(MUIRealVisualPos)
    end
    
    if MUIRealBodyLineDraw then
        if MUIDefenseActive and MUICloneRoot and MUIOriginVisible and MUIRealVisible then
            local dist = (Vector2.new(MUIRealScreen.X, MUIRealScreen.Y) - Vector2.new(MUIOriginScreen.X, MUIOriginScreen.Y)).Magnitude
            MUIRealBodyLineDraw.Visible = dist >= 2
            MUIRealBodyLineDraw.From = Vector2.new(MUIOriginScreen.X, MUIOriginScreen.Y)
            MUIRealBodyLineDraw.To = Vector2.new(MUIRealScreen.X, MUIRealScreen.Y)
        else
            MUIRealBodyLineDraw.Visible = false
        end
    end

    for _, MUIThreat in pairs(MUIThreats) do
        local d = MUIThreat.ESP
        local MUITargetVisualPos = MUIGetVisualPosition(MUIThreat.Player.Character)
        
        if not d or not MUITargetVisualPos or not MUIOriginVisible then
            if d then d.line.Visible = false; d.outline.Visible = false; d.glow.Visible = false end
        else
            local MUITargetScreen, MUITargetVisible = MUICamera:WorldToViewportPoint(MUITargetVisualPos)
            if not MUITargetVisible then
                d.line.Visible = false; d.outline.Visible = false; d.glow.Visible = false
            else
                local MUIDistance = (MUITargetVisualPos - MUIOriginPosition).Magnitude
                local threatLvl = math.clamp(1 - (MUIDistance / 100), 0, 1)
                local col = Color3.fromRGB(255, 210, 25)
                local thick = 2.5 + (threatLvl ^ 1.3) * (22 - 2.5)

                local from2 = Vector2.new(MUIOriginScreen.X, MUIOriginScreen.Y)
                local to2 = Vector2.new(MUITargetScreen.X, MUITargetScreen.Y)
                
                if (to2 - from2).Magnitude < 2 then
                    d.line.Visible = false; d.outline.Visible = false; d.glow.Visible = false
                else
                    d.glow.Visible = true; d.glow.From = from2; d.glow.To = to2; d.glow.Color = col; d.glow.Thickness = thick + 11
                    d.outline.Visible = true; d.outline.From = from2; d.outline.To = to2; d.outline.Thickness = thick + 5
                    d.line.Visible = true; d.line.From = from2; d.line.To = to2; d.line.Color = col; d.line.Thickness = thick
                end
            end
        end
    end
end

local function MUIStartSkyLift(MUIRoot, MUIToken)
    MUIDestroySkyForces()
    
    pcall(function()
        MUIRoot.AssemblyLinearVelocity = Vector3.zero
        MUIRoot.AssemblyAngularVelocity = Vector3.zero
    end)
    
    local skyX, skyZ = MUIRoot.Position.X, MUIRoot.Position.Z
    MUIRoot.CFrame = CFrame.new(skyX, MUISkyY, skyZ) * (MUIRoot.CFrame - MUIRoot.CFrame.Position)

    MUISkyPosition = Instance.new("BodyPosition", MUIRoot)
    MUISkyPosition.Name = "MUIHold"
    MUISkyPosition.Position = Vector3.new(skyX, MUISkyY, skyZ)
    MUISkyPosition.MaxForce = Vector3.new(M.Config.HoldForce, M.Config.HoldForce, M.Config.HoldForce)
    MUISkyPosition.P = 60000
    MUISkyPosition.D = 2500

    MUISkyVelocity = Instance.new("BodyVelocity", MUIRoot)
    MUISkyVelocity.Name = "MUISkyBV"
    MUISkyVelocity.MaxForce = Vector3.new(0, M.Config.HoldForce, 0)
    MUISkyVelocity.Velocity = Vector3.zero
end

local function MUIEnforceSkySafety(MUIRoot, MUIHumanoid)
    if not MUIDefenseActive or not MUISkyY or not MUIVirtualRootPosition then return end
    
    if math.abs(MUIRoot.Position.Y - MUISkyY) > 0.5 then
        MUIRoot.CFrame = CFrame.new(MUIRoot.Position.X, MUISkyY, MUIRoot.Position.Z) * (MUIRoot.CFrame - MUIRoot.CFrame.Position)
    end
    
    if MUISkyPosition then
        MUISkyPosition.Position = Vector3.new(MUIVirtualRootPosition.X, MUISkyY, MUIVirtualRootPosition.Z)
    end
    
    if MUIHumanoid then
        MUIHumanoid.PlatformStand = false
        MUIHumanoid.Sit = false
    end
end

local function MUIDestroyImpulseZone()
    if MUIImpulseZone then MUIImpulseZone:Destroy() end
    MUIImpulseZone = nil
end

local function MUICreateImpulseZone(MUISource)
    MUIDestroyImpulseZone()
    local MUIRoot = MUIGetRoot(MUISource and MUISource.Character)
    if not MUIRoot then return end
    MUIImpulseFolder = MUIImpulseFolder or Instance.new("Folder")
    MUIImpulseFolder.Name = "MUI_ImpulseZones"
    MUIImpulseFolder.Parent = workspace
    local MUIZone = Instance.new("Part")
    MUIZone.Name = "MUI_ImpulseBarrier"
    MUIZone.Shape = Enum.PartType.Cylinder
    MUIZone.Size = Vector3.new(M.Config.ImpulseWallHeight, M.Config.ImpulseRadius * 2, M.Config.ImpulseRadius * 2)
    MUIZone.CFrame = CFrame.new(MUIRoot.Position) * CFrame.Angles(0, 0, math.rad(90))
    MUIZone.Anchored = true
    MUIZone.CanCollide = false
    MUIZone.CanTouch = false
    MUIZone.CanQuery = true
    MUIZone.Material = Enum.Material.ForceField
    MUIZone.Color = Color3.fromRGB(145, 70, 255)
    MUIZone.Transparency = 0.94
    MUIZone:SetAttribute("MUIImpulseZone", true)
    MUIZone:SetAttribute("NoTeleportZone", true)
    MUIZone:SetAttribute("Radius", M.Config.ImpulseRadius)
    MUIZone:SetAttribute("SourceUserId", MUISource.UserId)
    MUIZone.Parent = MUIImpulseFolder
    MUIImpulseZone = MUIZone
end

local function MUIEnforceImpulseDistance(MUIRoot)
    if not MUIImpulseZone or not MUIActiveSource then return end
    local MUISourceRoot = MUIGetRoot(MUIActiveSource.Character)
    if not MUISourceRoot then return end
    MUIImpulseZone.CFrame = CFrame.new(MUISourceRoot.Position) * CFrame.Angles(0, 0, math.rad(90))
    local MUIOffset = MUIRoot.Position - MUISourceRoot.Position
    local MUIFlat = Vector3.new(MUIOffset.X, 0, MUIOffset.Z)
    if MUIFlat.Magnitude < M.Config.ImpulseEmergencyDistance then
        local MUIDirection = MUIFlat.Magnitude > 0.01 and MUIFlat.Unit or Vector3.new(0, 0, 1)
        local MUISafe = MUISourceRoot.Position + MUIDirection * M.Config.ImpulseRadius
        MUIRoot.CFrame = CFrame.new(MUISafe.X, math.max(MUIRoot.Position.Y, MUISafe.Y + 8), MUISafe.Z)
        MUIRoot.AssemblyLinearVelocity = Vector3.zero
        MUIRoot.AssemblyAngularVelocity = Vector3.zero
    end
end

local function MUICreateFallPlatform(MUIRoot, MUICharacter)
    if MUIFallPlatform then MUIFallPlatform:Destroy() end
    MUIFallPlatform = Instance.new("Part")
    MUIFallPlatform.Name = "MUI_FallSafetyPlatform"
    MUIFallPlatform.Size = Vector3.new(90, 5, 90)
    MUIFallPlatform.CFrame = CFrame.new(MUIRoot.Position.X, MUIRoot.Position.Y - MUIGetFootOffset(MUICharacter) - 2.5, MUIRoot.Position.Z)
    MUIFallPlatform.Anchored = true
    MUIFallPlatform.CanCollide = true
    MUIFallPlatform.CanTouch = true
    MUIFallPlatform.CanQuery = true
    MUIFallPlatform.Material = Enum.Material.ForceField
    MUIFallPlatform.Color = Color3.fromRGB(95, 190, 255)
    MUIFallPlatform.Transparency = 0.82
    MUIFallPlatform:SetAttribute("MUIFallSafety", true)
    MUIFallPlatform.Parent = workspace
    MUIFallPlatformLastTouched = os.clock()
    MUIFallPlatform.Touched:Connect(function(MUIHit)
        if MUIHit:IsDescendantOf(MUICharacter) then MUIFallPlatformLastTouched = os.clock() end
    end)
end

local function MUIEnforceFallSafety(MUIRoot, MUICharacter)
    if MUIFallPlatform and os.clock() - MUIFallPlatformLastTouched >= M.Config.FallSafetyPlatformLifetime then
        MUIFallPlatform:Destroy(); MUIFallPlatform = nil
    end
    if MUIRoot.Position.Y >= M.Config.FallSafetyY then return end
    local MUIParams = RaycastParams.new()
    MUIParams.FilterType = Enum.RaycastFilterType.Exclude
    MUIParams.FilterDescendantsInstances = { MUICharacter, MUICloneModel, MUICameraSubject }
    local MUIBestPosition = nil
    for MUIIndex = 0, 12 do
        local MUIAngle = (MUIIndex / 12) * math.pi * 2
        local MUIOffset = Vector3.new(math.cos(MUIAngle) * M.Config.FallSafetyScanRadius, 0, math.sin(MUIAngle) * M.Config.FallSafetyScanRadius)
        local MUIHit = workspace:Raycast(MUIRoot.Position + MUIOffset + Vector3.new(0, 1200, 0), Vector3.new(0, -2400, 0), MUIParams)
        if MUIHit and MUIHit.Position.Y > M.Config.FallSafetyY and (not MUIBestPosition or MUIHit.Position.Y > MUIBestPosition.Y) then
            MUIBestPosition = MUIHit.Position
        end
    end
    if MUIBestPosition then
        MUIRoot.CFrame = CFrame.new(MUIBestPosition + Vector3.new(0, MUIGetFootOffset(MUICharacter) + 0.5, 0))
    else
        MUICreateFallPlatform(MUIRoot, MUICharacter)
        MUIRoot.AssemblyLinearVelocity = Vector3.zero
    end
end

local MUIDeactivate

local function MUIBegin(MUIDodge, MUISource)
    local MUICharacter = MUILocalPlayer and MUILocalPlayer.Character
    local MUIRoot = MUIGetRoot(MUICharacter)
    local MUIHumanoid = MUIGetHumanoid(MUICharacter)
    if not MUICharacter or not MUIRoot or not MUIHumanoid or MUIHumanoid.Health <= 0 then return end

    MUIFootOffset = MUIGetFootOffset(MUICharacter)
    MUIVirtualRootPosition = MUIGroundPosition(MUIRoot.Position, MUICharacter)
    
    if MUIDodge.Style == "Dodge" then
        -- Verificamos si Omniblock ya está activo en modo 4D para evitar clones duplicados
        local omniApi = rawget(getgenv(), "AFO_OMNIBLOCK_API")
        local isOmniActive = omniApi and type(omniApi.Is4DActive) == "function" and omniApi.Is4DActive()

        if not isOmniActive then
            local _, MUIYaw = MUIRoot.CFrame:ToOrientation()
            local MUICloneCFrame = CFrame.new(MUIVirtualRootPosition) * CFrame.Angles(0, MUIYaw, 0)
            MUICloneModel, MUICloneRoot = MUICreateClone(MUICharacter, MUICloneCFrame)
            if not MUICloneRoot then
                MUIDestroyClone(); MUIVirtualRootPosition = nil
                return
            end
            MUICloneFootOffset = MUIGetCloneFootOffset(MUICloneModel, MUICloneRoot)
        else
            MUICloneModel = nil
            MUICloneRoot = nil
        end
    end

    MUIDefenseActive = true
    MUIActivationToken = MUIActivationToken + 1
    local MUIToken = MUIActivationToken
    MUIActiveDodgeName = MUIDodge.Name
    MUIActiveStyle = MUIDodge.Style
    MUIActiveDuration = MUIDodge.Duration
    MUIActiveUntil = os.clock() + MUIDodge.Duration
    MUIActiveSource = MUISource
    MUIActiveSources = {}
    
    MUIPendingDodge = nil
    MUIPendingDodgeExpectedTime = nil
    MUISkyY = MUIVirtualRootPosition.Y + M.Config.SkyAltitude
    MUISkySafetyStartedAt = os.clock()
    MUICameraSubject = MUICreateCameraSubject(MUIVirtualRootPosition)
    MUIHideRealCharacter(MUICharacter)
    if MUICloneRoot then
        MUICreateDivineCloneVFX()
        MUICreateCloneCountdown()
    else
        MUICreateImpulseZone(MUISource)
    end

    local MUICamera = workspace.CurrentCamera
    if MUICamera then MUICamera.CameraSubject = MUICameraSubject end
    MUIStartSkyLift(MUIRoot, MUIToken)
    MUIPlayLocalSound(M.Config.ActivationSoundId)
end

MUIDeactivate = function(MUIReturnToClone)
    if not MUIDefenseActive then return end
    
    local omniApi = rawget(getgenv(), "AFO_OMNIBLOCK_API")
    local isOmniActive = omniApi and type(omniApi.Is4DActive) == "function" and omniApi.Is4DActive()

    MUIDefenseActive = false
    MUIActivationToken = MUIActivationToken + 1
    MUIDestroySkyForces()

    local MUICharacter = MUILocalPlayer and MUILocalPlayer.Character
    local MUIRoot = MUIGetRoot(MUICharacter)
    local MUIHumanoid = MUIGetHumanoid(MUICharacter)

    if not isOmniActive then
        if MUIReturnToClone and MUIRoot and MUIHumanoid and MUIHumanoid.Health > 0 then
            local baseLandingPos = MUIVirtualRootPosition
            local MUIYaw = 0
            if MUICloneRoot then
                baseLandingPos = MUICloneRoot.Position
                local _, MUICloneYaw = MUICloneRoot.CFrame:ToOrientation()
                MUIYaw = MUICloneYaw
            end

            if baseLandingPos then
                local MUILandingPosition = MUIGroundPosition(baseLandingPos, MUICharacter)
                pcall(function()
                    MUIHumanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
                    MUIRoot.CFrame = CFrame.new(MUILandingPosition) * CFrame.Angles(0, MUIYaw, 0)
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
        end

        local MUICamera = workspace.CurrentCamera
        if MUICamera and MUIHumanoid and MUIHumanoid.Parent then 
            MUICamera.CameraSubject = MUIHumanoid 
        end
        MUIRestoreRealCharacter()
    else
        MUIRestoreRealCharacter()
    end

    MUIDestroyClone()
    MUIDestroyCameraSubject()
    MUIVirtualRootPosition = nil
    MUISkyY = nil
    MUIActiveDodgeName = nil
    MUIActiveStyle = nil
    MUIDestroyImpulseZone()
    MUIActiveDuration = 0
    MUIActiveSource = nil
    MUIActiveSources = {}
    MUIPlayLocalSound(M.Config.DeactivationSoundId)
end

MUIForceDismissAll = function()
    MUIPendingToken = MUIPendingToken + 1
    MUIPendingDodge = nil
    MUIPendingDodgeExpectedTime = nil
    local MUIList = MUIThreatList()
    for _, MUIThreat in ipairs(MUIList) do MUIDismissThreat(MUIThreat) end
    MUIActiveSources = {}
    if MUIDefenseActive then MUIDeactivate(true) end
end

local TogaAlertGuiInstance = nil
local TogaImpulseCount = 0
local TogaLastImpulseTime = 0
local TogaCooldown = 0.5
local TogaActiveDodge = nil
local TogaActivePlayer = nil

local function MUIDestroyTogaAlert()
    if TogaAlertGuiInstance then
        pcall(function() TogaAlertGuiInstance:Destroy() end)
        TogaAlertGuiInstance = nil
    end
    TogaImpulseCount = 0
    TogaActiveDodge = nil
    TogaActivePlayer = nil
end

local function MUIOpenTogaAlert(MUIDodge, MUIPlayer, MUIToken)
    MUIDestroyTogaAlert()
    TogaActiveDodge = MUIDodge
    TogaActivePlayer = MUIPlayer
    TogaImpulseCount = 0

    local container = (function()
        local s, r = pcall(function()
            if gethui then return gethui()
            elseif syn and syn.protect_gui then
                local sg = Instance.new("ScreenGui")
                syn.protect_gui(sg)
                return sg
            else
                return MUILocalPlayer:WaitForChild("PlayerGui")
            end
        end)
        return (s and r) and r or game:GetService("CoreGui")
    end())

    local oldGui = container:FindFirstChild("TogaAlertUI")
    if oldGui then oldGui:Destroy() end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "TogaAlertUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.DisplayOrder = 80 
    ScreenGui.Parent = container
    TogaAlertGuiInstance = ScreenGui

    local isUIActive = true
    local isClosing = false

    local MainHolder = Instance.new("Frame")
    MainHolder.Name = "MainHolder"
    MainHolder.BackgroundTransparency = 1
    MainHolder.Size = UDim2.new(0, 300, 0, 300)
    MainHolder.AnchorPoint = Vector2.new(0.5, 0.5)

    local StartPos = UDim2.new(1, 220, 0.72, 0)
    local EndPos = UDim2.new(1, -140, 0.72, 0)

    MainHolder.Position = StartPos
    MainHolder.Parent = ScreenGui

    local GlowHolder = Instance.new("Frame")
    GlowHolder.Name = "GlowHolder"
    GlowHolder.BackgroundTransparency = 1
    GlowHolder.AnchorPoint = Vector2.new(0.5, 0.5)
    GlowHolder.Position = UDim2.new(0.58, 0, 0.5, 0)
    GlowHolder.Size = UDim2.new(0, 420, 0, 420)
    GlowHolder.ZIndex = 1
    GlowHolder.Parent = MainHolder

    local RadialGradient = Instance.new("UIGradient")
    RadialGradient.Rotation = 0
    RadialGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(0.6, 0.4),
        NumberSequenceKeypoint.new(1, 1)
    })
    RadialGradient.Parent = GlowHolder

    local GlowImage = Instance.new("ImageLabel")
    GlowImage.Name = "CenterGlow"
    GlowImage.Image = "rbxassetid://9055001972"
    GlowImage.ImageColor3 = Color3.fromRGB(255, 235, 100)
    GlowImage.BackgroundTransparency = 1
    GlowImage.Size = UDim2.new(1, 0, 1, 0)
    GlowImage.ImageTransparency = 0.2
    GlowImage.ZIndex = 1
    GlowImage.Parent = GlowHolder

    task.spawn(function()
        while isUIActive and GlowHolder and GlowHolder.Parent do
            local growTween = MUITweenService:Create(GlowHolder, TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                Size = UDim2.new(0, 520, 0, 520)
            })
            local growImg = MUITweenService:Create(GlowImage, TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                ImageTransparency = 0.08
            })
            growTween:Play()
            growImg:Play()
            growTween.Completed:Wait()
            
            local shrinkTween = MUITweenService:Create(GlowHolder, TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                Size = UDim2.new(0, 390, 0, 390)
            })
            local shrinkImg = MUITweenService:Create(GlowImage, TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                ImageTransparency = 0.3
            })
            shrinkTween:Play()
            shrinkImg:Play()
            shrinkTween.Completed:Wait()
        end
    end)

    local MainImage = Instance.new("ImageButton")
    MainImage.Name = "MainCharacterImage"
    MainImage.Image = "rbxassetid://12077128922"
    MainImage.BackgroundTransparency = 1
    MainImage.AutoButtonColor = false
    MainImage.ZIndex = 2
    MainImage.Size = UDim2.new(-1, 0, 1, 0)
    MainImage.Position = UDim2.new(1, 0, 0, 0)
    MainImage.Parent = MainHolder

    local MangaBubble = Instance.new("ImageLabel")
    MangaBubble.Name = "MangaDialogue"
    MangaBubble.Image = "rbxassetid://136797177442983"
    MangaBubble.BackgroundTransparency = 1
    MangaBubble.Size = UDim2.new(0, 320, 0, 220)
    MangaBubble.Position = UDim2.new(1, -410, 0.72, -160)
    MangaBubble.ImageTransparency = 1
    MangaBubble.ZIndex = 3
    MangaBubble.Parent = ScreenGui

    local DialogueText = Instance.new("TextLabel")
    DialogueText.Size = UDim2.new(0.56, 0, 0.56, 0)       
    DialogueText.Position = UDim2.new(0.23, 0, 0.20, 0)   
    DialogueText.BackgroundTransparency = 1
    DialogueText.Text = getDialogueStep1()
    DialogueText.TextColor3 = Color3.fromRGB(15, 15, 15)
    DialogueText.TextScaled = true
    DialogueText.TextWrapped = true
    DialogueText.Font = Enum.Font.Bangers
    DialogueText.TextTransparency = 1
    DialogueText.ZIndex = 4
    DialogueText.Parent = MangaBubble

    local function playTalkAnimation()
        task.spawn(function()
            local squashTween = MUITweenService:Create(MainHolder, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 320, 0, 260),
                Rotation = -5
            })
            squashTween:Play()
            squashTween.Completed:Wait()
            
            local stretchTween = MUITweenService:Create(MainHolder, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 280, 0, 330),
                Rotation = 5
            })
            stretchTween:Play()
            stretchTween.Completed:Wait()
            
            local resetTween = MUITweenService:Create(MainHolder, TweenInfo.new(0.25, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 300, 0, 300),
                Rotation = 0
            })
            resetTween:Play()
        end)
    end

    local enterTween = MUITweenService:Create(MainHolder, TweenInfo.new(0.55, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = EndPos})
    enterTween:Play()

    enterTween.Completed:Connect(function()
        if not isUIActive or isClosing then return end
        
        MangaBubble.Size = UDim2.new(0, 0, 0, 0)
        MangaBubble.Position = UDim2.new(1, -250, 0.72, -80)
        MangaBubble.ImageTransparency = 0
        DialogueText.TextTransparency = 0
        
        local bubbleTween = MUITweenService:Create(MangaBubble, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 320, 0, 220),
            Position = UDim2.new(1, -410, 0.72, -160)
        })
        bubbleTween:Play()
        playTalkAnimation()
    end)

    local function triggerExitSequence()
        if isClosing or not isUIActive then return end
        isClosing = true
        isUIActive = false
        
        MUITweenService:Create(MangaBubble, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            ImageTransparency = 1,
            Size = UDim2.new(0, 350, 0, 240)
        }):Play()
        
        MUITweenService:Create(DialogueText, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            TextTransparency = 1
        }):Play()
        
        local exitTween = MUITweenService:Create(MainHolder, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Position = StartPos
        })
        
        MUITweenService:Create(GlowImage, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            ImageTransparency = 1
        }):Play()
        
        exitTween:Play()
        exitTween.Completed:Connect(function()
            if ScreenGui and ScreenGui.Parent then ScreenGui:Destroy() end
            if TogaAlertGuiInstance == ScreenGui then TogaAlertGuiInstance = nil end
        end)
    end

    local function handleImpulse()
        if not isUIActive or isClosing then return end
        
        local currentTime = os.clock()
        if (currentTime - TogaLastImpulseTime) < TogaCooldown then
            return
        end
        TogaLastImpulseTime = currentTime
        
        TogaImpulseCount = TogaImpulseCount + 1
        
        if TogaImpulseCount == 1 then
            MUIPendingDodge = nil
            MUIPendingDodgeExpectedTime = nil
            if TogaActiveDodge then
                MUIBegin(TogaActiveDodge, TogaActivePlayer)
            end

            playTalkAnimation()
            
            local popOut = MUITweenService:Create(MangaBubble, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Size = UDim2.new(0, 260, 0, 180)
            })
            popOut:Play()
            popOut.Completed:Wait()
            
            local locale = (M.Config.Locale or "es"):lower()
            local ft = MUIStrings[locale] or MUIStrings.es
            DialogueText.Text = ft.mui_dialogue_step2 or MUIStrings.es.mui_dialogue_step2
            
            local popIn = MUITweenService:Create(MangaBubble, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 320, 0, 220)
            })
            popIn:Play()
            
        elseif TogaImpulseCount >= 2 then
            if MUIDefenseActive then
                MUIDeactivate(true)
            end
            triggerExitSequence()
        end
    end

    MainImage.MouseButton1Click:Connect(handleImpulse)

    local keyConn
    keyConn = MUIUserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not isUIActive or isClosing then
            if keyConn then keyConn:Disconnect() end
            return
        end
        
        if input.KeyCode == M.Config.DodgeKey or input.KeyCode == Enum.KeyCode.Five or input.KeyCode == Enum.KeyCode.KeypadFive then
            handleImpulse()
        end
    end)
end

local function MUIMoveClone(MUIDeltaTime, MUICharacter)
    if not M.Config.AllowCloneMovement or not MUIVirtualRootPosition then return end
    local MUICamera = workspace.CurrentCamera
    if not MUICamera then return end
    local MUILook = MUICamera.CFrame.LookVector
    local MUIRight = MUICamera.CFrame.RightVector
    local MUIForwardFlat = Vector3.new(MUILook.X, 0, MUILook.Z)
    local MUIRightFlat = Vector3.new(MUIRight.X, 0, MUIRight.Z)
    if MUIForwardFlat.Magnitude > 0 then MUIForwardFlat = MUIForwardFlat.Unit end
    if MUIRightFlat.Magnitude > 0 then MUIRightFlat = MUIRightFlat.Unit end
    local MUIMovement = Vector3.zero
    if MUIUserInputService:IsKeyDown(Enum.KeyCode.W) then MUIMovement = MUIMovement + MUIForwardFlat end
    if MUIUserInputService:IsKeyDown(Enum.KeyCode.S) then MUIMovement = MUIMovement - MUIForwardFlat end
    if MUIUserInputService:IsKeyDown(Enum.KeyCode.D) then MUIMovement = MUIMovement + MUIRightFlat end
    if MUIUserInputService:IsKeyDown(Enum.KeyCode.A) then MUIMovement = MUIMovement - MUIRightFlat end
    local MUIProposed = MUIVirtualRootPosition
    if MUIMovement.Magnitude > 0 then
        MUIProposed = MUIProposed + MUIMovement.Unit * M.Config.CloneWalkSpeed * MUIDeltaTime
    end
    local MUIGrounded = MUIGroundPosition(MUIProposed, MUICharacter)
    local MUIYDelta = MUIGrounded.Y - MUIVirtualRootPosition.Y
    if MUIYDelta < 0 then
        MUIYDelta = math.max(MUIYDelta, -M.Config.MaxGroundStepPerSecond * MUIDeltaTime)
    end
    if MUIUserInputService:IsKeyDown(Enum.KeyCode.Space) and MUICloneJumpVelocity == 0 and MUICloneJumpOffset == 0 then
        MUICloneJumpVelocity = M.Config.CloneJumpVelocity
    end
    if MUICloneJumpVelocity ~= 0 then
        local MUINextOffset = MUICloneJumpOffset + MUICloneJumpVelocity * MUIDeltaTime - 0.5 * M.Config.CloneJumpGravity * MUIDeltaTime * MUIDeltaTime
        MUICloneJumpVelocity = MUICloneJumpVelocity - M.Config.CloneJumpGravity * MUIDeltaTime
        if MUINextOffset <= 0 then
            MUICloneJumpOffset, MUICloneJumpVelocity = 0, 0
        else
            MUICloneJumpOffset = MUINextOffset
        end
    end
    MUIVirtualRootPosition = Vector3.new(MUIProposed.X, MUIVirtualRootPosition.Y + MUIYDelta, MUIProposed.Z)
end

local function MUIUpdateCloneAndCamera()
    if not MUIVirtualRootPosition then return end
    local MUICamera = workspace.CurrentCamera
    local MUIYaw = 0
    if MUICamera then
        local MUILook = MUICamera.CFrame.LookVector
        if Vector3.new(MUILook.X, 0, MUILook.Z).Magnitude > 0.01 then
            MUIYaw = math.atan2(-MUILook.X, -MUILook.Z)
        end
    end
    local MUICharacter = MUILocalPlayer and MUILocalPlayer.Character
    if MUICloneModel and MUICloneRoot then
        MUISyncCloneAnimation(MUICharacter)
        MUICloneFootOffset = MUIGetCloneFootOffset(MUICloneModel, MUICloneRoot)
        local MUIGroundSurfaceY = MUIVirtualRootPosition.Y - MUIFootOffset
        local MUIClonePosition = Vector3.new(
            MUIVirtualRootPosition.X,
            MUIGroundSurfaceY + MUICloneFootOffset + MUICloneJumpOffset + M.Config.CloneGroundEpsilon,
            MUIVirtualRootPosition.Z
        )
        MUICloneModel:PivotTo(CFrame.new(MUIClonePosition) * CFrame.Angles(0, MUIYaw, 0))
    end
    if MUICameraSubject then
        MUICameraSubject.CFrame = CFrame.new(MUIVirtualRootPosition + Vector3.new(0, M.Config.CloneHeadOffset + MUICloneJumpOffset, 0))
    end
    if MUISkyPosition and MUISkyY then
        MUISkyPosition.Position = Vector3.new(MUIVirtualRootPosition.X, MUISkyY, MUIVirtualRootPosition.Z)
    end
end

local function MUIUpdateExposedData()
    local MUICharacter = MUILocalPlayer and MUILocalPlayer.Character
    if not MUICharacter then return end

    local function ensureValue(name, className)
        local val = MUICharacter:FindFirstChild(name)
        if not val or not val:IsA(className) then
            if val then val:Destroy() end
            val = Instance.new(className)
            val.Name = name
            val.Parent = MUICharacter
        end
        return val
    end

    local alarmVal = ensureValue("MUI_Alarm", "BoolValue")
    local tpTimeVal = ensureValue("MUI_TeleportTime", "BoolValue")
    local stateVal = ensureValue("MUI_SkyCloneState", "BoolValue")
    local threatsVal = ensureValue("MUI_ThreatsData", "StringValue")

    local hasThreats = false
    local threatList = {}
    for _, t in pairs(MUIThreats) do
        hasThreats = true
        table.insert(threatList, {
            Target = t.Player.Name,
            Ability = t.DodgeDisplayName or t.DodgeName,
            TimeRemaining = math.max(0, t.ExpiresAt - os.clock())
        })
    end
    
    alarmVal.Value = hasThreats or MUIDefenseActive
    stateVal.Value = MUIDefenseActive and (MUICloneRoot ~= nil)

    local isTeleportingSoon = false
    if MUIPendingDodge and MUIPendingDodgeExpectedTime then
        if (MUIPendingDodgeExpectedTime - os.clock()) <= 0.4 then
            isTeleportingSoon = true
        end
    end
    tpTimeVal.Value = isTeleportingSoon

    local ok, json = pcall(function() return HttpService:JSONEncode(threatList) end)
    threatsVal.Value = ok and json or "[]"
end

local function MUITrigger(MUIDodge, MUIPlayer, MUITrack)
    if not MUIEnabled or not MUIDodge then return end
    local MUINow = os.clock()
    local MUIKey = tostring(MUIPlayer and MUIPlayer.UserId or 0) .. ":" .. MUIDodge.Name
    if MUINow - (MUILastTriggerAt[MUIKey] or -math.huge) < M.Config.SameAnimationCooldown then return end
    
    MUILastTriggerAt[MUIKey] = MUINow
    MUIMarkThreat(MUIPlayer, MUIDodge)

    if MUIDefenseActive then
        if M.Config.RefreshOnRepeatedTrigger then
            MUIActiveUntil = math.max(MUIActiveUntil, MUINow + MUIDodge.Duration)
        end
        return
    end
    if MUIPendingDodge then return end
    
    if MUIDodge.Delay <= 0 or MUIGetPingSeconds() >= M.Config.PingInstantThreshold then
        MUIBegin(MUIDodge, MUIPlayer)
        return
    end
    
    MUIPendingDodge = MUIDodge.Name
    MUIPendingToken = MUIPendingToken + 1
    local MUIToken = MUIPendingToken
    MUIPendingDodgeExpectedTime = os.clock() + MUIDodge.Delay
    
    MUIOpenTogaAlert(MUIDodge, MUIPlayer, MUIToken)
end

local function MUIOnAnimation(MUIPlayer, MUITrack)
    local MUIAnimation = MUITrack and MUITrack.Animation
    local MUIId = MUIAnimation and MUIAssetNumber(MUIAnimation.AnimationId)
    if MUIId ~= "" then
        MUITrigger(MUIDodgeByAnimationId[MUIId], MUIPlayer, MUITrack)
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
    if MUIThreat then MUIDismissThreat(MUIThreat) end
end

local function MUIHookCharacter(MUIPlayer, MUICharacter)
    local MUIWatch = MUIPlayerWatches[MUIPlayer]
    if not MUIWatch then return end
    MUIDisconnect(MUIWatch.AnimationPlayed)
    MUIWatch.AnimationPlayed = nil
    task.spawn(function()
        local MUIHumanoid = MUICharacter:WaitForChild("Humanoid", 5)
        if not MUIEnabled or MUIPlayer.Character ~= MUICharacter or MUIPlayerWatches[MUIPlayer] ~= MUIWatch or not MUIHumanoid then return end
        local MUIAnimator = MUIHumanoid:FindFirstChildOfClass("Animator") or MUIHumanoid:WaitForChild("Animator", 5)
        if not MUIEnabled or MUIPlayerWatches[MUIPlayer] ~= MUIWatch then return end
        if not MUIAnimator then
            MUIAnimator = Instance.new("Animator")
            MUIAnimator.Parent = MUIHumanoid
        end
        MUIWatch.AnimationPlayed = MUIAnimator.AnimationPlayed:Connect(function(MUITrack)
            MUIOnAnimation(MUIPlayer, MUITrack)
        end)
    end)
end

local function MUIWatchRemotePlayer(MUIPlayer)
    if MUIPlayer == MUILocalPlayer or MUIPlayerWatches[MUIPlayer] then return end
    local MUIWatch = {}
    MUIPlayerWatches[MUIPlayer] = MUIWatch
    MUIWatch.CharacterAdded = MUIPlayer.CharacterAdded:Connect(function(MUICharacter) MUIHookCharacter(MUIPlayer, MUICharacter) end)
    if MUIPlayer.Character then MUIHookCharacter(MUIPlayer, MUIPlayer.Character) end
end

local function MUIHeartbeat(MUIDeltaTime)
    local MUINow = os.clock()
    for _, MUIThreat in pairs(MUIThreats) do
        if MUIThreat.ExpiresAt <= MUINow and MUIThreat.Player ~= MUIActiveSource then
            MUIDismissThreat(MUIThreat)
        end
    end
    if MUINow - MUILastHudUpdate >= 0.1 then
        MUILastHudUpdate = MUINow
        MUIUpdateThreatHud(MUINow)
    end

    if MUICloneHighlight and MUIDefenseActive then
        local sineWaveColor = (math.sin(MUINow * 3) + 1) / 2 
        MUICloneHighlight.OutlineColor = Color3.fromRGB(255, 255, 255):Lerp(Color3.fromRGB(150, 200, 255), sineWaveColor)
    end

    local MUIFreeCharacter = MUILocalPlayer and MUILocalPlayer.Character
    local MUIFreeRoot = MUIGetRoot(MUIFreeCharacter)
    if MUIFreeRoot and MUIFreeCharacter then MUIEnforceFallSafety(MUIFreeRoot, MUIFreeCharacter) end
    
    MUIUpdateExposedData()

    if not MUIDefenseActive then return end
    local MUICharacter = MUILocalPlayer and MUILocalPlayer.Character
    local MUIRoot = MUIGetRoot(MUICharacter)
    local MUIHumanoid = MUIGetHumanoid(MUICharacter)
    if not MUICharacter or not MUIRoot or not MUIHumanoid or MUIHumanoid.Health <= 0 then
        MUIDeactivate(false)
        return
    end
    
    MUIEnforceSkySafety(MUIRoot, MUIHumanoid)
    if MUIActiveStyle == "Impulse" then MUIEnforceImpulseDistance(MUIRoot) end
    
    if MUINow >= MUIActiveUntil then
        local omniApi = rawget(getgenv(), "AFO_OMNIBLOCK_API")
        local isOmniActive = omniApi and type(omniApi.Is4DActive) == "function" and omniApi.Is4DActive()
        
        if isOmniActive then
            MUIDeactivate(false)
        else
            MUIDeactivate(true)
        end
        return
    end
    
    if MUIActiveStyle == "Dodge" then MUIMoveClone(MUIDeltaTime, MUICharacter) end
    MUIUpdateCloneAndCamera()
    MUIUpdateCloneCountdown(MUINow)
end

local function MUIStopWatchingEveryone()
    local MUIWatched = {}
    for MUIPlayer in pairs(MUIPlayerWatches) do table.insert(MUIWatched, MUIPlayer) end
    for _, MUIPlayer in ipairs(MUIWatched) do MUIDisconnectWatch(MUIPlayer) end
    MUIDisconnect(MUIPlayerAddedConnection)
    MUIDisconnect(MUIPlayerRemovingConnection)
    MUIPlayerAddedConnection = nil
    MUIPlayerRemovingConnection = nil
    MUILastTriggerAt = {}
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

function M.SetDodgeKey(keyCode)
    M.Config.DodgeKey = keyCode
end

function M.GetDodgeKey()
    return M.Config.DodgeKey or Enum.KeyCode.Five
end

function M.Start(MUIOverrides)
    if MUIEnabled then M.Stop() end
    if typeof(MUIOverrides) == "Instance" and MUIOverrides:IsA("Player") then MUIOverrides = nil end
    if MUIOverrides then M.Configure(MUIOverrides) else MUIRebuildDodgeIndex() end
    MUILocalPlayer = MUIPlayers.LocalPlayer
    assert(MUILocalPlayer, "MUI4DDodge must run on the client")
    MUIEnabled = true
    MUIBuildHud()
    _reloadLocale()
    for _, MUIPlayer in ipairs(MUIPlayers:GetPlayers()) do MUIWatchRemotePlayer(MUIPlayer) end
    MUIPlayerAddedConnection = MUIPlayers.PlayerAdded:Connect(MUIWatchRemotePlayer)
    MUIPlayerRemovingConnection = MUIPlayers.PlayerRemoving:Connect(MUIDisconnectWatch)
    MUICharacterRemovingConnection = MUILocalPlayer.CharacterRemoving:Connect(function() MUIDeactivate(false) end)
    MUIHeartbeatConnection = MUIRunService.Heartbeat:Connect(MUIHeartbeat)
    MUIRenderConnection = MUIRunService.RenderStepped:Connect(MUIRenderThreatLines)
    MUIInputConnection = MUIUserInputService.InputBegan:Connect(function(MUIInput)
        if MUIUserInputService:GetFocusedTextBox() then return end
        if MUIInput.KeyCode == M.Config.ForceDismissKey then MUIForceDismissAll() end
    end)
end

function M.Stop()
    MUIPendingToken = MUIPendingToken + 1
    MUIPendingDodge = nil
    MUIPendingDodgeExpectedTime = nil
    MUIDestroyTogaAlert()
    if MUIDefenseActive then MUIDeactivate(true) end
    MUIEnabled = false
    MUIStopWatchingEveryone()
    MUIDisconnect(MUIHeartbeatConnection)
    MUIDisconnect(MUIRenderConnection)
    MUIDisconnect(MUICharacterRemovingConnection)
    MUIDisconnect(MUIInputConnection)
    MUIHeartbeatConnection = nil
    MUIRenderConnection = nil
    MUICharacterRemovingConnection = nil
    MUIInputConnection = nil
    for _, MUIThreat in pairs(MUIThreats) do MUIDismissThreat(MUIThreat) end
    if MUIHud then MUIHud:Destroy() end
    if MUIRealBodyLineDraw then MUIRealBodyLineDraw.Remove(); MUIRealBodyLineDraw = nil end
    MUIDestroyImpulseZone()
    if MUIImpulseFolder then MUIImpulseFolder:Destroy(); MUIImpulseFolder = nil end
    if MUIFallPlatform then MUIFallPlatform:Destroy(); MUIFallPlatform = nil end
    MUIHud = nil
    MUIHudCards = nil
    MUIHudDismissButton = nil
    MUILastHudUpdate = 0
end

function M.TriggerDodge(MUIDodgeName)
    for _, MUIDodge in pairs(MUIDodgeByAnimationId) do
        if MUIDodge.Name == MUIDodgeName then
            MUITrigger(MUIDodge, nil, nil)
            return true
        end
    end
    return false
end

function M.IsDefenseActive() return MUIDefenseActive end
function M.IsActive() return M.IsDefenseActive() end
function M.GetActiveDodge() return MUIActiveDodgeName end

function M.GetMarkedThreats()
    local MUIResult = {}
    local MUIOrigin = MUIVirtualRootPosition or (MUIGetRoot(MUILocalPlayer and MUILocalPlayer.Character) or {}).Position
    for _, MUIThreat in ipairs(MUIThreatList()) do
        local MUIRoot = MUIGetRoot(MUIThreat.Player.Character)
        table.insert(MUIResult, {
            player = MUIThreat.Player,
            name = MUIThreat.Player.Name,
            displayName = MUIThreat.Player.DisplayName,
            ability = MUIThreat.DodgeDisplayName or MUIThreat.DodgeName,
            style = MUIThreat.Style,
            distance = MUIRoot and MUIOrigin and (MUIRoot.Position - MUIOrigin).Magnitude or nil,
            isActiveSource = MUIThreat.Player == MUIActiveSource,
        })
    end
    return MUIResult
end

function M.GetThreatState()
    return {
        defenseActive = MUIDefenseActive,
        activeDodge = MUIActiveDodgeName,
        activeStyle = MUIActiveStyle,
        activeSource = MUIActiveSource,
        markedThreats = M.GetMarkedThreats(),
    }
end

function M.GetStatus()
    local MUIThreats = M.GetMarkedThreats()
    local MUIPrimary = MUIThreats[1]
    return {
        systemEnabled = MUIEnabled,
        defenseActive = MUIDefenseActive,
        lockActive = MUIDefenseActive,
        target = MUIPrimary and MUIPrimary.player or nil,
        targetName = MUIPrimary and (MUIPrimary.displayName or MUIPrimary.name) or nil,
        distance = MUIPrimary and MUIPrimary.distance or nil,
        activeDodge = MUIActiveDodgeName,
        markedThreats = MUIThreats,
    }
end

M.API = {
    GetMarkedThreats = M.GetMarkedThreats,
    IsDefenseActive = M.IsDefenseActive,
    GetThreatState = M.GetThreatState,
    GetStatus = M.GetStatus,
}

if type(getgenv) == "function" then
    pcall(function() getgenv().AFO_MUI_API = M end)
end

return M
