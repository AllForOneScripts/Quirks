local M = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local _lplr = nil
local _keys = nil
local _active = false
local connections = {}
local modifiedParts = {}

local gui
local character, humanoid, rootPart
local movementAttachment, linearVelocity
local isEnabled = true
local currentSpeed = 100
local gameBaseSpeed = 16

local isExploding = false
local DASH_COOLDOWN = 1.2
local lastDashEnd = 0
local boostEndTime = 0
local EXPLOSION_BASE_FORCE = 130
local GHOST_DURATION = 0.4
local currentSmoothSpeed = 16

local function restoreAllGhostParts()
    for part, data in pairs(modifiedParts) do
        if part and part.Parent then
            part.CanCollide = data.OriginalCollide
            part.Transparency = data.OriginalTransparency
        end
    end
    table.clear(modifiedParts)
end

local function clearPhysics()
    if linearVelocity then
        linearVelocity:Destroy()
        linearVelocity = nil
    end

    if movementAttachment then
        movementAttachment:Destroy()
        movementAttachment = nil
    end

    isExploding = false
    restoreAllGhostParts()
end

function M.Stop()
    _active = false
    isEnabled = false

    clearPhysics()

    for _, conn in ipairs(connections) do
        if conn then
            conn:Disconnect()
        end
    end

    table.clear(connections)

    if gui and gui.Parent then
        gui:Destroy()
    end

    gui = nil
end

function M.SetKey(kc)
    if _keys then
        _keys.Dash = kc
    end
end

function M.Start(Keys, lplr)
    _keys = Keys
    _lplr = lplr or Players.LocalPlayer

    local camera = workspace.CurrentCamera
    local playerGui = _lplr:WaitForChild("PlayerGui")

    if _active or playerGui:FindFirstChild("CustomMovementGUI") then
        return
    end

    M.Stop()

    _active = true
    isEnabled = true
    currentSpeed = 100
    gameBaseSpeed = 16
    currentSmoothSpeed = 16
    isExploding = false
    lastDashEnd = 0
    boostEndTime = 0

    gui = Instance.new("ScreenGui")
    gui.Name = "CustomMovementGUI"
    gui.ResetOnSpawn = false
    gui.Parent = playerGui

    -- GUI 35% más pequeña y en la esquina inferior izquierda
    local GUI_WIDTH = 143
    local GUI_HEIGHT = 46
    local BUBBLE_SIZE = 30
    local MARGIN = 16

    local frame = Instance.new("Frame")
    frame.Name = "MovementPanel"
    frame.Parent = gui
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.Size = UDim2.fromOffset(GUI_WIDTH, GUI_HEIGHT)
    frame.Position = UDim2.new(
        0,
        MARGIN + GUI_WIDTH / 2,
        1,
        -MARGIN - GUI_HEIGHT / 2
    )
    frame.BackgroundColor3 = Color3.fromRGB(25, 10, 35)
    frame.BorderSizePixel = 0
    frame.Active = true

    local frameCorner = Instance.new("UICorner")
    frameCorner.CornerRadius = UDim.new(0, 6)
    frameCorner.Parent = frame

    local logo = Instance.new("ImageLabel")
    logo.Parent = frame
    logo.Size = UDim2.fromOffset(33, 33)
    logo.Position = UDim2.new(0, 7, 0.5, -16.5)
    logo.BackgroundTransparency = 1
    logo.Image = "rbxassetid://127633283332495"
    logo.ScaleType = Enum.ScaleType.Fit

    local logoBtn = Instance.new("TextButton")
    logoBtn.Parent = frame
    logoBtn.Size = logo.Size
    logoBtn.Position = logo.Position
    logoBtn.BackgroundTransparency = 1
    logoBtn.Text = ""

    local controlsFrame = Instance.new("Frame")
    controlsFrame.Parent = frame
    controlsFrame.Size = UDim2.new(1, -46, 1, 0)
    controlsFrame.Position = UDim2.new(0, 42, 0, 0)
    controlsFrame.BackgroundTransparency = 1

    local minimizeBtn = Instance.new("TextButton")
    minimizeBtn.Parent = controlsFrame
    minimizeBtn.Size = UDim2.fromOffset(15, 15)
    minimizeBtn.Position = UDim2.new(1, -32, 0, 2)
    minimizeBtn.BackgroundTransparency = 1
    minimizeBtn.Text = "-"
    minimizeBtn.TextColor3 = Color3.new(1, 1, 1)
    minimizeBtn.Font = Enum.Font.GothamBold
    minimizeBtn.TextSize = 14

    local closeBtn = Instance.new("TextButton")
    closeBtn.Parent = controlsFrame
    closeBtn.Size = UDim2.fromOffset(15, 15)
    closeBtn.Position = UDim2.new(1, -16, 0, 2)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 10

    local textBox = Instance.new("TextBox")
    textBox.Parent = controlsFrame
    textBox.Size = UDim2.new(1, -6, 0, 12)
    textBox.Position = UDim2.new(0, 0, 0, 14)
    textBox.BackgroundColor3 = Color3.fromRGB(35, 15, 45)
    textBox.TextColor3 = Color3.new(1, 1, 1)
    textBox.PlaceholderText = "Velocidad"
    textBox.Text = "100"
    textBox.Font = Enum.Font.Gotham
    textBox.TextSize = 8
    Instance.new("UICorner", textBox).CornerRadius = UDim.new(0, 3)

    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Parent = controlsFrame
    toggleBtn.Size = UDim2.new(1, -6, 0, 12)
    toggleBtn.Position = UDim2.new(0, 0, 0, 29)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(70, 20, 100)
    toggleBtn.TextColor3 = Color3.new(1, 1, 1)
    toggleBtn.Text = "On"
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.TextSize = 8
    Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 3)

    -- Arrastrar GUI
    local dragging = false
    local dragStart
    local startPosition

    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then

            dragging = true
            dragStart = input.Position
            startPosition = frame.Position
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not dragging then
            return
        end

        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then

            local delta = input.Position - dragStart

            frame.Position = UDim2.new(
                startPosition.X.Scale,
                startPosition.X.Offset + delta.X,
                startPosition.Y.Scale,
                startPosition.Y.Offset + delta.Y
            )
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then

            dragging = false
        end
    end)

    -- Minimizar hacia el centro en forma de bolita
    local isMinimized = false
    local tweenInfo = TweenInfo.new(
        0.22,
        Enum.EasingStyle.Quad,
        Enum.EasingDirection.Out
    )

    local function toggleMinimizeState()
        isMinimized = not isMinimized

        if isMinimized then
            controlsFrame.Visible = false

            TweenService:Create(frame, tweenInfo, {
                Size = UDim2.fromOffset(BUBBLE_SIZE, BUBBLE_SIZE)
            }):Play()

            TweenService:Create(frameCorner, tweenInfo, {
                CornerRadius = UDim.new(1, 0)
            }):Play()

            TweenService:Create(logo, tweenInfo, {
                Size = UDim2.new(1, 0, 1, 0),
                Position = UDim2.new(0, 0, 0, 0)
            }):Play()

            TweenService:Create(logoBtn, tweenInfo, {
                Size = UDim2.new(1, 0, 1, 0),
                Position = UDim2.new(0, 0, 0, 0)
            }):Play()
        else
            TweenService:Create(frame, tweenInfo, {
                Size = UDim2.fromOffset(GUI_WIDTH, GUI_HEIGHT)
            }):Play()

            TweenService:Create(frameCorner, tweenInfo, {
                CornerRadius = UDim.new(0, 6)
            }):Play()

            TweenService:Create(logo, tweenInfo, {
                Size = UDim2.fromOffset(33, 33),
                Position = UDim2.new(0, 7, 0.5, -16.5)
            }):Play()

            TweenService:Create(logoBtn, tweenInfo, {
                Size = UDim2.fromOffset(33, 33),
                Position = UDim2.new(0, 7, 0.5, -16.5)
            }):Play()

            task.delay(tweenInfo.Time * 0.55, function()
                if not isMinimized then
                    controlsFrame.Visible = true
                end
            end)
        end
    end

    minimizeBtn.MouseButton1Click:Connect(toggleMinimizeState)

    logoBtn.MouseButton1Click:Connect(function()
        if isMinimized then
            toggleMinimizeState()
        end
    end)

    closeBtn.MouseButton1Click:Connect(function()
        M.Stop()
    end)

    toggleBtn.MouseButton1Click:Connect(function()
        local num = tonumber(textBox.Text)

        if not isEnabled then
            if num and num > 0 then
                currentSpeed = math.abs(num)
                isEnabled = true

                if humanoid then
                    gameBaseSpeed = math.abs(humanoid.WalkSpeed)

                    if gameBaseSpeed == 0 then
                        gameBaseSpeed = 16
                    end

                    currentSmoothSpeed = gameBaseSpeed
                end

                toggleBtn.Text = "On"
                toggleBtn.BackgroundColor3 = Color3.fromRGB(70, 20, 100)
            else
                toggleBtn.Text = "Inválido"

                task.wait(1)

                if not isEnabled then
                    toggleBtn.Text = "Off"
                end
            end
        else
            isEnabled = false
            clearPhysics()
            toggleBtn.Text = "Off"
            toggleBtn.BackgroundColor3 = Color3.fromRGB(45, 15, 60)
        end
    end)

    local function setupCharacter(char)
        character = char
        humanoid = char:WaitForChild("Humanoid")
        rootPart = char:WaitForChild("HumanoidRootPart")

        gameBaseSpeed = math.abs(humanoid.WalkSpeed)

        if gameBaseSpeed == 0 then
            gameBaseSpeed = 16
        end

        currentSmoothSpeed = gameBaseSpeed
        clearPhysics()
    end

    if _lplr.Character then
        setupCharacter(_lplr.Character)
    end

    table.insert(connections, _lplr.CharacterAdded:Connect(setupCharacter))

    table.insert(connections, UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe or not isEnabled or not character or not humanoid then
            return
        end

        if textBox:IsFocused() then
            return
        end

        if input.KeyCode == Enum.KeyCode.Q then
            local state = humanoid:GetState()

            if state == Enum.HumanoidStateType.FallingDown
                or state == Enum.HumanoidStateType.Ragdoll
                or humanoid.PlatformStand then
                return
            end

            if tick() - lastDashEnd >= DASH_COOLDOWN then
                local isLateral = UserInputService:IsKeyDown(Enum.KeyCode.A)
                    or UserInputService:IsKeyDown(Enum.KeyCode.D)

                local isForwardBack = UserInputService:IsKeyDown(Enum.KeyCode.W)
                    or UserInputService:IsKeyDown(Enum.KeyCode.S)

                if isForwardBack or not isLateral then
                    return
                end

                lastDashEnd = tick()
                isExploding = true

                local dir = humanoid.MoveDirection

                if dir.Magnitude < 0.01 then
                    dir = rootPart.CFrame.LookVector
                end

                local pushDir = Vector3.new(dir.X, 0, dir.Z).Unit
                local safeCurrentGameSpeed = math.abs(humanoid.WalkSpeed)
                local safeBaseSpeed = math.abs(gameBaseSpeed)

                if safeBaseSpeed == 0 then
                    safeBaseSpeed = 16
                end

                local speedMultiplier = math.max(1, safeCurrentGameSpeed / safeBaseSpeed)
                local finalWalkSpeed = math.abs(currentSpeed * speedMultiplier)
                local dashForce = math.max(EXPLOSION_BASE_FORCE, finalWalkSpeed * 2.3)

                rootPart:ApplyImpulse(
                    pushDir * rootPart.AssemblyMass * dashForce
                )

                task.delay(0.15, function()
                    isExploding = false
                end)
            end
        end
    end))

    table.insert(connections, RunService.Heartbeat:Connect(function(deltaTime)
        if not isEnabled or not character or not humanoid or not rootPart or not character.Parent then
            return
        end

        local state = humanoid:GetState()
        local isRagdoll = state == Enum.HumanoidStateType.FallingDown
            or state == Enum.HumanoidStateType.Ragdoll
            or humanoid.PlatformStand

        if isRagdoll then
            isExploding = false
        end

        local moveDir = humanoid.MoveDirection
        local currentTime = tick()

        if isRagdoll and moveDir.Magnitude < 0.01 then
            local camCFrame = camera.CFrame

            local forward = Vector3.new(
                camCFrame.LookVector.X,
                0,
                camCFrame.LookVector.Z
            )

            forward = forward.Magnitude > 0
                and forward.Unit
                or Vector3.new(0, 0, -1)

            local right = Vector3.new(
                camCFrame.RightVector.X,
                0,
                camCFrame.RightVector.Z
            )

            right = right.Magnitude > 0
                and right.Unit
                or Vector3.new(1, 0, 0)

            local manualDir = Vector3.zero

            if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                manualDir += forward
            end

            if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                manualDir -= forward
            end

            if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                manualDir += right
            end

            if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                manualDir -= right
            end

            if manualDir.Magnitude > 0.01 then
                moveDir = manualDir.Unit
            end
        end

        local overlapParams = OverlapParams.new()
        overlapParams.FilterDescendantsInstances = { character }
        overlapParams.FilterType = Enum.RaycastFilterType.Exclude

        if not isRagdoll then
            local floorPart = nil
            local rayParams = RaycastParams.new()

            rayParams.FilterDescendantsInstances = { character }
            rayParams.FilterType = Enum.RaycastFilterType.Exclude

            local rayResult = workspace:Raycast(
                rootPart.Position,
                Vector3.new(0, -5, 0),
                rayParams
            )

            if rayResult then
                floorPart = rayResult.Instance
            end

            local checkDir = moveDir

            if isExploding and rootPart.AssemblyLinearVelocity.Magnitude > 0.1 then
                checkDir = rootPart.AssemblyLinearVelocity.Unit
            end

            if checkDir.Magnitude > 0.01 then
                local lookDir = CFrame.lookAt(
                    rootPart.Position,
                    rootPart.Position + checkDir
                )

                local boxCFrame = lookDir * CFrame.new(0, 1.5, -2)
                local boxSize = Vector3.new(2, 3, 2)

                local partsInFront = workspace:GetPartBoundsInBox(
                    boxCFrame,
                    boxSize,
                    overlapParams
                )

                for _, hitPart in ipairs(partsInFront) do
                    if hitPart:IsA("BasePart")
                        and not hitPart:IsA("Terrain")
                        and hitPart.CanCollide then

                        if hitPart == floorPart then
                            continue
                        end

                        if not modifiedParts[hitPart] then
                            modifiedParts[hitPart] = {
                                OriginalCollide = hitPart.CanCollide,
                                OriginalTransparency = hitPart.Transparency,
                                RestoreTime = currentTime + GHOST_DURATION
                            }

                            hitPart.CanCollide = false
                            hitPart.Transparency = 0.6
                        else
                            modifiedParts[hitPart].RestoreTime = currentTime + GHOST_DURATION
                        end
                    end
                end
            end
        end

        local safeBoxSize = Vector3.new(3, 6, 3)
        local touchingParts = workspace:GetPartBoundsInBox(
            rootPart.CFrame,
            safeBoxSize,
            overlapParams
        )

        for part, data in pairs(modifiedParts) do
            if currentTime >= data.RestoreTime then
                if part and part.Parent then
                    local isIntersecting = false

                    for _, touchingPart in ipairs(touchingParts) do
                        if touchingPart == part then
                            isIntersecting = true
                            break
                        end
                    end

                    if isIntersecting then
                        data.RestoreTime = currentTime + 0.1
                        continue
                    end

                    part.CanCollide = data.OriginalCollide
                    part.Transparency = data.OriginalTransparency
                end

                modifiedParts[part] = nil
            end
        end

        if isExploding then
            if linearVelocity then
                linearVelocity.MaxAxesForce = Vector3.zero
            end

            return
        end

        local safeCurrentGameSpeed = math.abs(humanoid.WalkSpeed)
        local safeBaseSpeed = math.abs(gameBaseSpeed)

        if safeBaseSpeed == 0 then
            safeBaseSpeed = 16
        end

        local speedMultiplier = math.max(1, safeCurrentGameSpeed / safeBaseSpeed)
        local baseTargetSpeed = math.abs(currentSpeed * speedMultiplier)
        local finalTargetSpeed = baseTargetSpeed

        local nearestEnemyHRP = nil
        local minDistance = math.huge

        for _, otherPlayer in ipairs(Players:GetPlayers()) do
            if otherPlayer ~= _lplr and otherPlayer.Character then
                local otherHum = otherPlayer.Character:FindFirstChild("Humanoid")
                local otherRoot = otherPlayer.Character:FindFirstChild("HumanoidRootPart")

                if otherRoot and otherHum and otherHum.Health > 0 then
                    local distance = (otherRoot.Position - rootPart.Position).Magnitude

                    if distance < minDistance then
                        minDistance = distance
                        nearestEnemyHRP = otherRoot
                    end
                end
            end
        end

        if nearestEnemyHRP and humanoid.Health <= humanoid.MaxHealth * 0.5 then
            local directionToEnemy = (nearestEnemyHRP.Position - rootPart.Position).Unit
            local lookVector = rootPart.CFrame.LookVector
            local dotProduct = lookVector:Dot(directionToEnemy)

            if dotProduct < -0.2 then
                boostEndTime = tick() + 10
            end
        end

        if tick() < boostEndTime then
            finalTargetSpeed = baseTargetSpeed * 2
        elseif nearestEnemyHRP then
            local dirToEnemy = (nearestEnemyHRP.Position - rootPart.Position).Unit
            local moveVector = moveDir.Magnitude > 0 and moveDir.Unit or Vector3.zero
            local moveDot = moveVector.Magnitude > 0 and moveVector:Dot(dirToEnemy) or 0

            if minDistance > 45 then
                finalTargetSpeed = baseTargetSpeed * 2
            elseif minDistance >= 15 and minDistance <= 45 then
                finalTargetSpeed = baseTargetSpeed * 1.3

                if moveDot > 0.8 then
                    finalTargetSpeed *= 1.15
                elseif math.abs(moveDot) < 0.4 and moveVector.Magnitude > 0 then
                    finalTargetSpeed *= 1.10
                end
            else
                finalTargetSpeed = baseTargetSpeed

                if math.abs(moveDot) < 0.4 and moveVector.Magnitude > 0 then
                    finalTargetSpeed *= 1.05
                end
            end
        else
            finalTargetSpeed = baseTargetSpeed * 2
        end

        local lerpSpeed = math.clamp(14 * deltaTime, 0, 1)

        currentSmoothSpeed = currentSmoothSpeed
            + (finalTargetSpeed - currentSmoothSpeed) * lerpSpeed

        if not linearVelocity or not linearVelocity.Parent then
            movementAttachment = Instance.new("Attachment")
            movementAttachment.Parent = rootPart
            movementAttachment.Position = Vector3.zero

            linearVelocity = Instance.new("LinearVelocity")
            linearVelocity.Parent = rootPart
            linearVelocity.Attachment0 = movementAttachment
            linearVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
            linearVelocity.ForceLimitMode = Enum.ForceLimitMode.PerAxis
        end

        local moveMagnitude = moveDir.Magnitude
        local activeForce = isRagdoll and 45000 or 1e5

        if moveMagnitude > 0.01 then
            local preciseDir = moveDir.Unit
            local targetVelocityVector = preciseDir * currentSmoothSpeed

            linearVelocity.MaxAxesForce = Vector3.new(activeForce, 0, activeForce)
            linearVelocity.VectorVelocity = Vector3.new(
                targetVelocityVector.X,
                0,
                targetVelocityVector.Z
            )
        else
            linearVelocity.MaxAxesForce = Vector3.new(activeForce, 0, activeForce)
            linearVelocity.VectorVelocity = Vector3.zero
        end
    end))
end

return M
