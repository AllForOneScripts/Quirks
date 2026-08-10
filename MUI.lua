--[[
    ╔══════════════════════════════════════════════════════════════════════╗
    ║  MUI — PRUEBA LOCAL: DUMMY BAKUGO NUKER (RETIRABLE)                  ║
    ║  Pegar ESTE BLOQUE después de `local function MUITrigger(...) ...`.  ║
    ╚══════════════════════════════════════════════════════════════════════╝

    Cambios mínimos adicionales en el MUI principal:

    1) Junto a los estados locales:
       local MUITestInputConnection = nil
       local MUITestFolder = nil
       local MUITestSourceAlive = false

    2) En MUIBegin, sustituir la asignación de MUIExtendUntilSourceDies por:
       MUIExtendUntilSourceDies = MUIDodge.ExtendUntilSourceDies == true
           and (MUISource ~= nil or MUITestSourceAlive)

    3) En MUIDeactivate, antes de reproducir el sonido de desactivación:
       MUITestSourceAlive = false

    4) Al final de M.Start, después de crear MUIRenderConnection:
       MUITestInputConnection = MUIUserInputService.InputBegan:Connect(MUITestInput)

    5) En M.Stop, antes de poner las conexiones en nil:
       MUIDisconnect(MUITestInputConnection)
       MUITestInputConnection = nil
       MUITestClear()

    No cambiar Humanoid.Health: la explosión sólo simula daño visual local.
]]

-- ═══════════════════════════════════════════════════════════════════════════
--  CONFIGURACIÓN DE PRUEBA
-- ═══════════════════════════════════════════════════════════════════════════

local MUITestConfig = {
    Key = Enum.KeyCode.K,
    DummyUserId = 525350506, -- DummyROBLOX1
    DodgeName = "Bakugo_Nuker",
    RiseHeight = 130,
    RiseSeconds = 1.15,
    ChargeSeconds = 3.55, -- Delay normal del Dodge (5 s) - ascenso
    DiveSeconds = 0.62,
    ImpactRadius = 18,
    MaximumDummies = 8,
}

local MUITestDummies = {}
local MUITestSerial = 0

-- ═══════════════════════════════════════════════════════════════════════════
--  HELPERS DE EFECTOS
-- ═══════════════════════════════════════════════════════════════════════════

local function MUITestFolderGet()
    if MUITestFolder and MUITestFolder.Parent then return MUITestFolder end
    MUITestFolder = Instance.new("Folder")
    MUITestFolder.Name = "MUI_LocalBakugoNukerTest"
    MUITestFolder.Parent = workspace
    return MUITestFolder
end

local function MUITestPart(MUIName, MUISize, MUICFrame, MUIColor)
    local MUIPart = Instance.new("Part")
    MUIPart.Name = MUIName
    MUIPart.Size = MUISize
    MUIPart.CFrame = MUICFrame
    MUIPart.Anchored = true
    MUIPart.CanCollide = false
    MUIPart.CanTouch = false
    MUIPart.CanQuery = false
    MUIPart.CastShadow = false
    MUIPart.Material = Enum.Material.Neon
    MUIPart.Color = MUIColor
    MUIPart.Parent = MUITestFolderGet()
    return MUIPart
end

local function MUITestRing(MUIPosition, MUIStart, MUIFinish, MUIColor, MUITime)
    local MUIRing = MUITestPart(
        "NukerShockRing",
        Vector3.new(0.1, MUIStart * 2, MUIStart * 2),
        CFrame.new(MUIPosition + Vector3.new(0, 0.12, 0)) * CFrame.Angles(0, 0, math.rad(90)),
        MUIColor
    )
    MUIRing.Shape = Enum.PartType.Cylinder
    MUIRing.Transparency = 0.2
    MUITweenService:Create(MUIRing, TweenInfo.new(MUITime, Enum.EasingStyle.Quad), {
        Size = Vector3.new(0.1, MUIFinish * 2, MUIFinish * 2),
        Transparency = 1,
    }):Play()
    MUIDebris:AddItem(MUIRing, MUITime + 0.1)
end

local function MUITestBurst(MUIPosition, MUIColor, MUIAmount, MUISpeed)
    local MUIAnchor = MUITestPart("NukerParticles", Vector3.new(0.1, 0.1, 0.1), CFrame.new(MUIPosition), MUIColor)
    MUIAnchor.Transparency = 1
    local MUIAttachment = Instance.new("Attachment")
    MUIAttachment.Parent = MUIAnchor
    local MUIEmitter = Instance.new("ParticleEmitter")
    MUIEmitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    MUIEmitter.Color = ColorSequence.new(MUIColor, Color3.fromRGB(255, 236, 145))
    MUIEmitter.LightEmission = 1
    MUIEmitter.LightInfluence = 0
    MUIEmitter.Lifetime = NumberRange.new(0.35, 0.8)
    MUIEmitter.Speed = NumberRange.new(MUISpeed * 0.45, MUISpeed)
    MUIEmitter.SpreadAngle = Vector2.new(180, 180)
    MUIEmitter.Drag = 5
    MUIEmitter.Size = NumberSequence.new(0.75, 0)
    MUIEmitter.Transparency = NumberSequence.new(0, 1)
    MUIEmitter.Parent = MUIAttachment
    MUIEmitter:Emit(MUIAmount)
    MUIDebris:AddItem(MUIAnchor, 1.25)
end

local function MUITestGround(MUIPosition)
    local MUIParams = RaycastParams.new()
    MUIParams.FilterType = Enum.RaycastFilterType.Exclude
    MUIParams.FilterDescendantsInstances = { MUITestFolderGet(), MUILocalPlayer.Character }
    local MUIHit = workspace:Raycast(
        MUIPosition + Vector3.new(0, 150, 0),
        Vector3.new(0, -700, 0),
        MUIParams
    )
    return MUIHit and MUIHit.Position or MUIPosition
end

local function MUITestDamageFlash()
    local MUIPlayerGui = MUILocalPlayer:FindFirstChildOfClass("PlayerGui")
    if not MUIPlayerGui then return end
    local MUIGui = Instance.new("ScreenGui")
    MUIGui.Name = "MUITestNukerDamageVisual"
    MUIGui.IgnoreGuiInset = true
    MUIGui.DisplayOrder = 1000
    MUIGui.Parent = MUIPlayerGui
    local MUIFlash = Instance.new("Frame")
    MUIFlash.Size = UDim2.fromScale(1, 1)
    MUIFlash.BorderSizePixel = 0
    MUIFlash.BackgroundColor3 = Color3.fromRGB(255, 150, 55)
    MUIFlash.BackgroundTransparency = 1
    MUIFlash.Parent = MUIGui
    MUITweenService:Create(MUIFlash, TweenInfo.new(0.08), { BackgroundTransparency = 0.22 }):Play()
    task.delay(0.1, function()
        if MUIFlash.Parent then
            MUITweenService:Create(MUIFlash, TweenInfo.new(0.7), { BackgroundTransparency = 1 }):Play()
        end
    end)
    MUIDebris:AddItem(MUIGui, 0.9)
end

-- ═══════════════════════════════════════════════════════════════════════════
--  DUMMY Y SECUENCIA NUKER
-- ═══════════════════════════════════════════════════════════════════════════

local function MUITestCreateDummy()
    local MUIOk, MUIDescription = pcall(function()
        return MUIPlayers:GetHumanoidDescriptionFromUserId(MUITestConfig.DummyUserId)
    end)
    if not MUIOk or not MUIDescription then return nil end
    local MUIModelOk, MUIModel = pcall(function()
        return MUIPlayers:CreateHumanoidModelFromDescription(MUIDescription, Enum.HumanoidRigType.R15)
    end)
    if not MUIModelOk or not MUIModel then return nil end
    local MUIRoot = MUIGetRoot(MUIModel)
    if not MUIRoot then MUIModel:Destroy(); return nil end
    for _, MUIInstance in ipairs(MUIModel:GetDescendants()) do
        if MUIInstance:IsA("BasePart") then
            MUIInstance.Anchored = true
            MUIInstance.CanCollide = false
            MUIInstance.CanTouch = false
            MUIInstance.CanQuery = false
            MUIInstance.CastShadow = false
        end
    end
    MUITestSerial += 1
    MUIModel.Name = "Dummy_BakugoNuker_" .. MUITestSerial
    MUIModel.PrimaryPart = MUIRoot
    MUIModel.Parent = MUITestFolderGet()
    local MUIHighlight = Instance.new("Highlight")
    MUIHighlight.FillColor = Color3.fromRGB(255, 80, 28)
    MUIHighlight.FillTransparency = 0.5
    MUIHighlight.OutlineColor = Color3.fromRGB(255, 221, 115)
    MUIHighlight.OutlineTransparency = 0.05
    MUIHighlight.Parent = MUIModel
    local MUIGui = Instance.new("BillboardGui")
    MUIGui.Size = UDim2.fromOffset(170, 34)
    MUIGui.StudsOffset = Vector3.new(0, 4.3, 0)
    MUIGui.AlwaysOnTop = true
    MUIGui.Adornee = MUIModel:FindFirstChild("Head") or MUIRoot
    MUIGui.Parent = MUIModel
    local MUILabel = Instance.new("TextLabel")
    MUILabel.Size = UDim2.fromScale(1, 1)
    MUILabel.BackgroundTransparency = 1
    MUILabel.Font = Enum.Font.GothamBlack
    MUILabel.TextSize = 14
    MUILabel.TextStrokeTransparency = 0
    MUILabel.TextColor3 = Color3.fromRGB(255, 215, 80)
    MUILabel.Text = "DUMMY • BAKUGO NUKER"
    MUILabel.Parent = MUIGui
    return { Model = MUIModel, Root = MUIRoot, Cancelled = false }
end

local function MUITestPivot(MUIRecord, MUIFrom, MUITo, MUITime, MUILookAt)
    local MUIElapsed = 0
    while MUIEnabled and not MUIRecord.Cancelled and MUIRecord.Model.Parent and MUIElapsed < MUITime do
        MUIElapsed += MUIRunService.Heartbeat:Wait()
        local MUIAlpha = math.clamp(MUIElapsed / MUITime, 0, 1)
        MUIAlpha = 1 - (1 - MUIAlpha) * (1 - MUIAlpha)
        local MUIPosition = MUIFrom:Lerp(MUITo, MUIAlpha)
        local MUIFace = MUILookAt or MUITo
        MUIRecord.Model:PivotTo(CFrame.lookAt(MUIPosition, Vector3.new(MUIFace.X, MUIPosition.Y, MUIFace.Z)))
    end
end

local function MUITestLaunch()
    if not MUIEnabled then return end
    local MUIRoot = MUIGetRoot(MUILocalPlayer.Character)
    if not MUIRoot then return end
    local MUIDodge
    for _, MUIValue in pairs(MUIDodgeByAnimationId) do
        if MUIValue.Name == MUITestConfig.DodgeName then MUIDodge = MUIValue; break end
    end
    if not MUIDodge then
        warn("[MUI Test] Dodge not configured: " .. MUITestConfig.DodgeName)
        return
    end

    -- The MUI sees this as its synthetic source. It is alive until the local
    -- dummy reaches its impact, where MUISourceDied becomes true.
    MUITestSourceAlive = true
    MUITrigger(MUIDodge, nil)

    local MUIRecord = MUITestCreateDummy()
    if not MUIRecord then return end
    table.insert(MUITestDummies, MUIRecord)
    if #MUITestDummies > MUITestConfig.MaximumDummies then
        local MUIOldest = table.remove(MUITestDummies, 1)
        MUIOldest.Cancelled = true
        MUIOldest.Model:Destroy()
    end

    local MUIAngle = math.random() * math.pi * 2
    local MUIStart = MUITestGround(MUIRoot.Position + Vector3.new(math.cos(MUIAngle) * 28, 0, math.sin(MUIAngle) * 28))
        + Vector3.new(0, 4, 0)
    MUIRecord.Model:PivotTo(CFrame.lookAt(MUIStart, MUIRoot.Position))
    task.spawn(function()
        local MUISky = MUIStart + Vector3.new(0, MUITestConfig.RiseHeight, 0)
        MUITestBurst(MUIStart, Color3.fromRGB(255, 111, 34), 26, 22)
        MUITestRing(MUIStart, 1, 10, Color3.fromRGB(255, 105, 30), 0.42)
        MUITestPivot(MUIRecord, MUIStart, MUISky, MUITestConfig.RiseSeconds, MUIRoot.Position)
        for _ = 1, 5 do
            if MUIRecord.Cancelled then return end
            MUITestBurst(MUISky, Color3.fromRGB(255, 185, 55), 12, 14)
            MUITestRing(MUISky, 1.5, 8, Color3.fromRGB(255, 220, 95), 0.32)
            task.wait(MUITestConfig.ChargeSeconds / 5)
        end
        local MUIImpact = MUITestGround(MUIGetRoot(MUILocalPlayer.Character).Position)
        MUITestPivot(MUIRecord, MUIRecord.Model:GetPivot().Position, MUIImpact + Vector3.new(0, 2, 0), MUITestConfig.DiveSeconds, MUIImpact)
        if not MUIRecord.Cancelled then
            MUITestBurst(MUIImpact, Color3.fromRGB(255, 91, 25), 120, 74)
            MUITestRing(MUIImpact, 2, MUITestConfig.ImpactRadius, Color3.fromRGB(255, 80, 30), 0.35)
            MUITestRing(MUIImpact, 4, MUITestConfig.ImpactRadius * 1.65, Color3.fromRGB(255, 215, 80), 0.72)
            MUITestDamageFlash()
            -- This is the test equivalent of the threat dying after impact.
            MUITestSourceAlive = false
            MUISourceDied = true
        end
        MUIDebris:AddItem(MUIRecord.Model, 0.18)
    end)
end

local function MUITestInput(MUIInput, MUIProcessed)
    if MUIProcessed or MUIUserInputService:GetFocusedTextBox() then return end
    if MUIInput.KeyCode == MUITestConfig.Key then MUITestLaunch() end
end

local function MUITestClear()
    for _, MUIRecord in ipairs(MUITestDummies) do
        MUIRecord.Cancelled = true
        if MUIRecord.Model then MUIRecord.Model:Destroy() end
    end
    table.clear(MUITestDummies)
    if MUITestFolder then MUITestFolder:Destroy(); MUITestFolder = nil end
    MUITestSourceAlive = false
end
