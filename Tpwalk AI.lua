local M = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- Variables del Módulo
local _lplr = nil
local _keys = nil
local _active = false
local connections = {}
local modifiedParts = {}

-- Variables de Interfaz y Físicas
local gui
local character, humanoid, rootPart
local movementAttachment, linearVelocity
local isEnabled = true 
local currentSpeed = 100 
local gameBaseSpeed = 16 

-- Configuración interna
local isExploding = false
local DASH_COOLDOWN = 1.2
local lastDashEnd = 0
local EXPLOSION_BASE_FORCE = 130 
local GHOST_DURATION = 0.4 

-----------------------------------
-- FUNCIONES INTERNAS DE LIMPIEZA
-----------------------------------
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
    if linearVelocity then linearVelocity:Destroy(); linearVelocity = nil end
    if movementAttachment then movementAttachment:Destroy(); movementAttachment = nil end
    isExploding = false
    restoreAllGhostParts()
end

-----------------------------------
-- MÉTODOS DEL MÓDULO -------------
-----------------------------------
function M.Stop()
    _active = false
    isEnabled = false
    
    clearPhysics()
    
    -- Desconectar todos los eventos vinculados a este módulo
    for _, conn in ipairs(connections) do
        if conn then conn:Disconnect() end
    end
    table.clear(connections)
    
    -- Eliminar la GUI
    if gui and gui.Parent then
        gui:Destroy()
    end
    gui = nil
end

function M.SetKey(kc)
    if _keys then _keys.Dash = kc end
end

function M.Start(Keys, lplr)
    _keys = Keys
    _lplr = lplr or Players.LocalPlayer
    local camera = workspace.CurrentCamera
    
    local playerGui = _lplr:WaitForChild("PlayerGui")
    
    -- REGLA: Si la GUI ya existe, se aborta la creación para no duplicar
    if _active or playerGui:FindFirstChild("CustomMovementGUI") then
        return 
    end
    
    -- Limpieza de seguridad por si había un proceso fantasma
    M.Stop()
    
    -- Inicializar variables para esta sesión
    _active = true
    isEnabled = true
    currentSpeed = 100
    gameBaseSpeed = 16
    isExploding = false
    lastDashEnd = 0
    
    -----------------------------------
    -- CREACIÓN DE LA INTERFAZ (GUI) --
    -----------------------------------
    gui = Instance.new("ScreenGui")
    gui.Name = "CustomMovementGUI"
    gui.ResetOnSpawn = false
    gui.Parent = playerGui

    local frame = Instance.new("Frame", gui)
    frame.Size = UDim2.new(0, 220, 0, 70)
    frame.Position = UDim2.new(1, -240, 0, 20) 
    frame.BackgroundColor3 = Color3.fromRGB(25, 10, 35)
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Draggable = true
    local frameCorner = Instance.new("UICorner", frame)
    frameCorner.CornerRadius = UDim.new(0, 8)

    local logo = Instance.new("ImageLabel", frame)
    logo.Size = UDim2.new(0, 50, 0, 50)
    logo.Position = UDim2.new(0, 10, 0.5, -25)
    logo.BackgroundTransparency = 1
    logo.Image = "rbxassetid://127633283332495"
    logo.ScaleType = Enum.ScaleType.Fit

    local logoBtn = Instance.new("TextButton", frame)
    logoBtn.Size = UDim2.new(0, 50, 0, 50)
    logoBtn.Position = UDim2.new(0, 10, 0.5, -25)
    logoBtn.BackgroundTransparency = 1
    logoBtn.Text = ""

    local controlsFrame = Instance.new("Frame", frame)
    controlsFrame.Size = UDim2.new(1, -70, 1, 0)
    controlsFrame.Position = UDim2.new(0, 65, 0, 0)
    controlsFrame.BackgroundTransparency = 1

    local minimizeBtn = Instance.new("TextButton", controlsFrame)
    minimizeBtn.Size = UDim2.new(0, 20, 0, 20)
    minimizeBtn.Position = UDim2.new(1, -45, 0, 5)
    minimizeBtn.BackgroundTransparency = 1
    minimizeBtn.Text = "-"
    minimizeBtn.TextColor3 = Color3.new(1, 1, 1)
    minimizeBtn.Font = Enum.Font.GothamBold
    minimizeBtn.TextSize = 18

    local closeBtn = Instance.new("TextButton", controlsFrame)
    closeBtn.Size = UDim2.new(0, 20, 0, 20)
    closeBtn.Position = UDim2.new(1, -25, 0, 5)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 14

    local textBox = Instance.new("TextBox", controlsFrame)
    textBox.Size = UDim2.new(1, -10, 0, 18)
    textBox.Position = UDim2.new(0, 0, 0, 22)
    textBox.BackgroundColor3 = Color3.fromRGB(35, 15, 45) 
    textBox.TextColor3 = Color3.new(1, 1, 1)
    textBox.PlaceholderText = "Velocidad"
    textBox.Text = "100" 
    textBox.Font = Enum.Font.Gotham
    textBox.TextSize = 11
    Instance.new("UICorner", textBox).CornerRadius = UDim.new(0, 4)

    local toggleBtn = Instance.new("TextButton", controlsFrame)
    toggleBtn.Size = UDim2.new(1, -10, 0, 18)
    toggleBtn.Position = UDim2.new(0, 0, 0, 44)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(70, 20, 100) 
    toggleBtn.TextColor3 = Color3.new(1, 1, 1)
    toggleBtn.Text = "On"
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.TextSize = 11
    Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 4)

    -----------------------------------
    -- LÓGICA DE INTERFAZ LOCAL -------
    -----------------------------------
    local isMinimized = false
    local function toggleMinimizeState()
        isMinimized = not isMinimized
        if isMinimized then
            controlsFrame.Visible = false
            frame.Size = UDim2.new(0, 50, 0, 50)
            frameCorner.CornerRadius = UDim.new(1, 0) 
            logo.Position = UDim2.new(0, 0, 0, 0)
            logo.Size = UDim2.new(1, 0, 1, 0)
            logoBtn.Position = UDim2.new(0, 0, 0, 0)
            logoBtn.Size = UDim2.new(1, 0, 1, 0)
        else
            controlsFrame.Visible = true
            frame.Size = UDim2.new(0, 220, 0, 70)
            frameCorner.CornerRadius = UDim.new(0, 8)
            logo.Size = UDim2.new(0, 50, 0, 50)
            logo.Position = UDim2.new(0, 10, 0.5, -25)
            logoBtn.Size = UDim2.new(0, 50, 0, 50)
            logoBtn.Position = UDim2.new(0, 10, 0.5, -25)
        end
    end

    minimizeBtn.MouseButton1Click:Connect(toggleMinimizeState)
    logoBtn.MouseButton1Click:Connect(function()
        if isMinimized then toggleMinimizeState() end
    end)
    
    -- Conectar el botón de Cerrar (X) con el Stop del Módulo
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
                    if gameBaseSpeed == 0 then gameBaseSpeed = 16 end
                end
                toggleBtn.Text = "On"
                toggleBtn.BackgroundColor3 = Color3.fromRGB(70, 20, 100)
            else
                toggleBtn.Text = "Inválido"
                task.wait(1)
                if not isEnabled then toggleBtn.Text = "Off" end
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
        if gameBaseSpeed == 0 then gameBaseSpeed = 16 end
        
        clearPhysics()
    end

    -----------------------------------
    -- EVENTOS Y FÍSICAS --------------
    -----------------------------------
    if _lplr.Character then setupCharacter(_lplr.Character) end
    table.insert(connections, _lplr.CharacterAdded:Connect(setupCharacter))

    table.insert(connections, UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe or not isEnabled or not character or not humanoid then return end
        if textBox:IsFocused() then return end

        if input.KeyCode == Enum.KeyCode.Q then
            local state = humanoid:GetState()
            if state == Enum.HumanoidStateType.FallingDown or state == Enum.HumanoidStateType.Ragdoll or humanoid.PlatformStand then return end

            if tick() - lastDashEnd >= DASH_COOLDOWN then
                if UserInputService:IsKeyDown(Enum.KeyCode.S) or UserInputService:IsKeyDown(Enum.KeyCode.A) or UserInputService:IsKeyDown(Enum.KeyCode.D) then
                    return 
                end

                lastDashEnd = tick()
                isExploding = true
                
                local dir = humanoid.MoveDirection
                if dir.Magnitude < 0.01 then dir = rootPart.CFrame.LookVector end
                
                local pushDir = Vector3.new(dir.X, 0, dir.Z).Unit
                local safeCurrentGameSpeed = math.abs(humanoid.WalkSpeed)
                local safeBaseSpeed = math.abs(gameBaseSpeed)
                if safeBaseSpeed == 0 then safeBaseSpeed = 16 end
                
                local speedMultiplier = math.max(1, safeCurrentGameSpeed / safeBaseSpeed)
                local finalWalkSpeed = math.abs(currentSpeed * speedMultiplier)
                
                local dashForce = math.max(EXPLOSION_BASE_FORCE, finalWalkSpeed * 2.3)
                
                rootPart:ApplyImpulse(pushDir * rootPart.AssemblyMass * dashForce)

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
        local isRagdoll = (state == Enum.HumanoidStateType.FallingDown) or (state == Enum.HumanoidStateType.Ragdoll) or humanoid.PlatformStand

        if isRagdoll then
            isExploding = false
        end

        local moveDir = humanoid.MoveDirection
        local currentTime = tick()
        
        -- Extracción Manual en estado STUN
        if isRagdoll and moveDir.Magnitude < 0.01 then
            local camCFrame = camera.CFrame
            local forward = Vector3.new(camCFrame.LookVector.X, 0, camCFrame.LookVector.Z)
            forward = forward.Magnitude > 0 and forward.Unit or Vector3.new(0, 0, -1)
            
            local right = Vector3.new(camCFrame.RightVector.X, 0, camCFrame.RightVector.Z)
            right = right.Magnitude > 0 and right.Unit or Vector3.new(1, 0, 0)
            
            local manualDir = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then manualDir = manualDir + forward end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then manualDir = manualDir - forward end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then manualDir = manualDir + right end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then manualDir = manualDir - right end
            
            if manualDir.Magnitude > 0.01 then
                moveDir = manualDir.Unit
            end
        end

        -- "Efecto Bala" con rastreo
        local floorPart = nil
        local overlapParams = OverlapParams.new()
        overlapParams.FilterDescendantsInstances = {character}
        overlapParams.FilterType = Enum.RaycastFilterType.Exclude

        if not isRagdoll then
            local rayParams = RaycastParams.new()
            rayParams.FilterDescendantsInstances = {character}
            rayParams.FilterType = Enum.RaycastFilterType.Exclude
            
            local rayResult = workspace:Raycast(rootPart.Position, Vector3.new(0, -5, 0), rayParams)
            if rayResult then
                floorPart = rayResult.Instance
            end
            
            local checkDir = moveDir
            if isExploding and rootPart.AssemblyLinearVelocity.Magnitude > 0.1 then
                checkDir = rootPart.AssemblyLinearVelocity.Unit
            end

            if checkDir.Magnitude > 0.01 then
                local lookDir = CFrame.lookAt(rootPart.Position, rootPart.Position + checkDir)
                local boxCFrame = lookDir * CFrame.new(0, 1.5, -2) 
                local boxSize = Vector3.new(2, 3, 2) 

                local partsInFront = workspace:GetPartBoundsInBox(boxCFrame, boxSize, overlapParams)

                for _, hitPart in ipairs(partsInFront) do
                    if hitPart:IsA("BasePart") and not hitPart:IsA("Terrain") and hitPart.CanCollide then
                        if hitPart == floorPart then continue end

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
        local touchingParts = workspace:GetPartBoundsInBox(rootPart.CFrame, safeBoxSize, overlapParams)
        
        for part, data in pairs(modifiedParts) do
            if currentTime >= data.RestoreTime then
                if part and part.Parent then
                    local isIntersecting = false
                    for _, p in ipairs(touchingParts) do
                        if p == part then
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

        -- Velocidad Constante + Radar Buff
        local safeCurrentGameSpeed = math.abs(humanoid.WalkSpeed)
        local safeBaseSpeed = math.abs(gameBaseSpeed)
        if safeBaseSpeed == 0 then safeBaseSpeed = 16 end
        
        local speedMultiplier = math.max(1, safeCurrentGameSpeed / safeBaseSpeed)
        local finalSpeed = math.abs(currentSpeed * speedMultiplier)

        local isPlayerNearby = false
        for _, otherPlayer in ipairs(Players:GetPlayers()) do
            if otherPlayer ~= _lplr and otherPlayer.Character then
                local otherRoot = otherPlayer.Character:FindFirstChild("HumanoidRootPart")
                if otherRoot then
                    local distance = (otherRoot.Position - rootPart.Position).Magnitude
                    if distance <= 22.5 then
                        isPlayerNearby = true
                        break
                    end
                end
            end
        end

        if not isPlayerNearby then
            finalSpeed = finalSpeed * 2
        end

        if not linearVelocity or not linearVelocity.Parent then
            movementAttachment = Instance.new("Attachment", rootPart)
            movementAttachment.Position = Vector3.zero 
            linearVelocity = Instance.new("LinearVelocity", rootPart)
            linearVelocity.Attachment0 = movementAttachment
            linearVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
            linearVelocity.ForceLimitMode = Enum.ForceLimitMode.PerAxis
        end

        local moveMagnitude = moveDir.Magnitude
        local activeForce = isRagdoll and 45000 or 1e5
        
        if moveMagnitude > 0.01 then
            local preciseDir = moveDir.Unit
            local targetVelocity = preciseDir * finalSpeed
            
            linearVelocity.MaxAxesForce = Vector3.new(activeForce, 0, activeForce) 
            linearVelocity.VectorVelocity = Vector3.new(targetVelocity.X, 0, targetVelocity.Z)
        else
            linearVelocity.MaxAxesForce = Vector3.new(activeForce, 0, activeForce)
            linearVelocity.VectorVelocity = Vector3.zero
        end
    end))
end

return M
