local M = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local localPlayer = nil
local keys = nil
local active = false
local connections = {}
local modifiedParts = {}

-- Variables de GUI
local gui, mainFrame, setPanelOpen
local isOpen = false
local toggleKey = Enum.KeyCode.F5
local meterLabel -- Label para el medidor de velocidad

-- Variables de físicas y personaje
local character, humanoid, rootPart
local movementAttachment, linearVelocity
local isEnabled = true
local currentSpeed = 100
local gameBaseSpeed = 16
local currentSmoothSpeed = 16

local isExploding = false
local DASH_COOLDOWN = 1.2
local lastDashEnd = 0
local boostEndTime = 0
local EXPLOSION_BASE_FORCE = 130
local GHOST_DURATION = 0.4

-- Paleta de colores heredada
local C_BLACK = Color3.fromRGB(15, 15, 20)
local C_PURPLE = Color3.fromRGB(100, 50, 150)
local C_TEXT = Color3.fromRGB(255, 255, 255)
local C_SUB = Color3.fromRGB(180, 180, 180)

local function disconnectAll()
	for _, conn in ipairs(connections) do
		if conn then
			conn:Disconnect()
		end
	end
	table.clear(connections)
end

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

function M.SetKey(keyCode)
	if typeof(keyCode) ~= "EnumItem" then
		return
	end

	toggleKey = keyCode

	if keys then
		keys.Movement = keyCode
	end
end

function M.Open()
	if not active or not setPanelOpen then
		return false
	end
	setPanelOpen(true)
	return true
end

function M.Close()
	if not active or not setPanelOpen then
		return false
	end
	setPanelOpen(false)
	return true
end

function M.Stop()
	active = false
	isEnabled = false

	clearPhysics()
	disconnectAll()

	if gui and gui.Parent then
		gui:Destroy()
	end

	gui = nil
	mainFrame = nil
	setPanelOpen = nil
	isOpen = false
end

function M.Start(firstArgument, secondArgument)
	-- Compatible con Start(Keys, Player) y Start(Player, Keys)
	if typeof(firstArgument) == "Instance" and firstArgument:IsA("Player") then
		localPlayer = firstArgument
		keys = secondArgument
	else
		keys = firstArgument
		localPlayer = secondArgument or Players.LocalPlayer
	end

	if not localPlayer then
		warn("[MovementHub] No se encontró LocalPlayer.")
		return false
	end

	if keys then
		local configuredKey = keys.Movement or keys.Toggle
		if typeof(configuredKey) == "EnumItem" then
			toggleKey = configuredKey
		end
	end

	M.Stop()

	active = true
	isEnabled = true
	isOpen = false
	currentSpeed = 100
	gameBaseSpeed = 16
	currentSmoothSpeed = 16
	isExploding = false
	lastDashEnd = 0
	boostEndTime = 0

	local playerGui = localPlayer:WaitForChild("PlayerGui")
	
	-- GUI Setup (Estilo panel lateral izquierdo)
	gui = Instance.new("ScreenGui")
	gui.Name = "AFO_CustomMovement"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = playerGui

	mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainPanel"
	mainFrame.Size = UDim2.new(0, 240, 0, 115)
	-- Anchor 0,0 para que se esconda y salga por la izquierda
	mainFrame.AnchorPoint = Vector2.new(0, 0)
	mainFrame.Position = UDim2.new(0, -300, 0, 190) -- Escondido a la izquierda
	mainFrame.BackgroundColor3 = C_BLACK
	mainFrame.BackgroundTransparency = 0.15
	mainFrame.BorderSizePixel = 0
	mainFrame.ZIndex = 10
	mainFrame.Parent = gui

	Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 8)

	local stroke = Instance.new("UIStroke")
	stroke.Color = C_PURPLE
	stroke.Thickness = 1
	stroke.Transparency = 0.5
	stroke.Parent = mainFrame

	local closeButton = Instance.new("TextButton")
	closeButton.Size = UDim2.new(0, 20, 0, 20)
	closeButton.Position = UDim2.new(1, -25, 0, 10)
	closeButton.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
	closeButton.BackgroundTransparency = 0.2
	closeButton.TextColor3 = C_TEXT
	closeButton.Font = Enum.Font.GothamBold
	closeButton.TextSize = 12
	closeButton.Text = "X"
	closeButton.BorderSizePixel = 0
	closeButton.Parent = mainFrame
	Instance.new("UICorner", closeButton).CornerRadius = UDim.new(0, 4)

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(0, 150, 0, 20)
	title.Position = UDim2.new(0, 15, 0, 10)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextSize = 14
	title.TextColor3 = C_TEXT
	title.Text = "Speed Force"
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = mainFrame

	local textBox = Instance.new("TextBox")
	textBox.Size = UDim2.new(0, 145, 0, 25)
	textBox.Position = UDim2.new(0, 15, 0, 40)
	textBox.BackgroundColor3 = Color3.fromRGB(20, 10, 40)
	textBox.BackgroundTransparency = 0.3
	textBox.TextColor3 = C_TEXT
	textBox.PlaceholderColor3 = C_SUB
	textBox.PlaceholderText = "Velocidad..."
	textBox.Text = tostring(currentSpeed)
	textBox.Font = Enum.Font.Gotham
	textBox.TextSize = 12
	textBox.BorderSizePixel = 0
	textBox.ClearTextOnFocus = true
	textBox.Parent = mainFrame
	Instance.new("UICorner", textBox).CornerRadius = UDim.new(0, 4)

	local boxStroke = Instance.new("UIStroke")
	boxStroke.Color = C_PURPLE
	boxStroke.Thickness = 1
	boxStroke.Transparency = 0.7
	boxStroke.Parent = textBox

	local toggleBtn = Instance.new("TextButton")
	toggleBtn.Size = UDim2.new(0, 145, 0, 25)
	toggleBtn.Position = UDim2.new(0, 15, 0, 75)
	toggleBtn.BackgroundColor3 = Color3.fromRGB(80, 20, 140)
	toggleBtn.BackgroundTransparency = 0.2
	toggleBtn.TextColor3 = C_TEXT
	toggleBtn.Font = Enum.Font.GothamBold
	toggleBtn.TextSize = 12
	toggleBtn.Text = "ON"
	toggleBtn.BorderSizePixel = 0
	toggleBtn.Parent = mainFrame
	Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 4)

	-- Contenedor del medidor (donde iba el avatar)
	local meterContainer = Instance.new("Frame")
	meterContainer.Size = UDim2.new(0, 55, 0, 55)
	meterContainer.Position = UDim2.new(1, -70, 0, 30)
	meterContainer.BackgroundColor3 = Color3.fromRGB(20, 10, 40)
	meterContainer.BackgroundTransparency = 0.3
	meterContainer.BorderSizePixel = 0
	meterContainer.ZIndex = 11
	meterContainer.Parent = mainFrame
	Instance.new("UICorner", meterContainer).CornerRadius = UDim.new(0, 6)
	
	local meterStroke = Instance.new("UIStroke")
	meterStroke.Color = C_PURPLE
	meterStroke.Thickness = 1
	meterStroke.Transparency = 0.7
	meterStroke.Parent = meterContainer

	local meterTitle = Instance.new("TextLabel")
	meterTitle.Size = UDim2.new(1, 0, 0, 15)
	meterTitle.Position = UDim2.new(0, 0, 0, 5)
	meterTitle.BackgroundTransparency = 1
	meterTitle.Font = Enum.Font.Gotham
	meterTitle.TextSize = 9
	meterTitle.TextColor3 = C_SUB
	meterTitle.Text = "SPEED"
	meterTitle.Parent = meterContainer

	meterLabel = Instance.new("TextLabel")
	meterLabel.Size = UDim2.new(1, 0, 1, -20)
	meterLabel.Position = UDim2.new(0, 0, 0, 20)
	meterLabel.BackgroundTransparency = 1
	meterLabel.Font = Enum.Font.GothamBold
	meterLabel.TextSize = 13
	meterLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
	meterLabel.Text = "0.0"
	meterLabel.Parent = meterContainer

	-- Animación del Panel hacia la izquierda
	local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

	setPanelOpen = function(open)
		if not active or not mainFrame or not mainFrame.Parent then return end
		isOpen = open
		local position = isOpen 
			and UDim2.new(0, 20, 0, 190)   -- Posición visible a la izquierda
			or UDim2.new(0, -300, 0, 190)  -- Escondido a la izquierda

		TweenService:Create(mainFrame, tweenInfo, { Position = position }):Play()
	end

	local function togglePanel()
		setPanelOpen(not isOpen)
	end

	-- Funcionalidad de Botones
	table.insert(connections, toggleBtn.MouseButton1Click:Connect(function()
		local num = tonumber(textBox.Text)

		if not isEnabled then
			if num and num > 0 then
				currentSpeed = math.abs(num)
				isEnabled = true
				if humanoid then
					gameBaseSpeed = math.abs(humanoid.WalkSpeed)
					if gameBaseSpeed == 0 then gameBaseSpeed = 16 end
					currentSmoothSpeed = gameBaseSpeed
				end
				toggleBtn.Text = "ON"
				toggleBtn.BackgroundColor3 = Color3.fromRGB(80, 20, 140)
			else
				toggleBtn.Text = "Inválido"
				task.wait(1)
				if not isEnabled then
					toggleBtn.Text = "OFF"
				end
			end
		else
			isEnabled = false
			clearPhysics()
			toggleBtn.Text = "OFF"
			toggleBtn.BackgroundColor3 = Color3.fromRGB(40, 10, 60)
		end
	end))

	table.insert(connections, textBox.FocusLost:Connect(function(enterPressed)
		if enterPressed then
			local num = tonumber(textBox.Text)
			if num and num > 0 and isEnabled then
				currentSpeed = math.abs(num)
			end
		end
	end))

	table.insert(connections, closeButton.MouseButton1Click:Connect(function()
		M.Stop()
	end))

	table.insert(connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if not gameProcessed and input.KeyCode == toggleKey then
			togglePanel()
		end
	end))

	-- Fix del Bug de inicialización de Velocidad
	local function setupCharacter(char)
		character = char
		humanoid = char:WaitForChild("Humanoid")
		rootPart = char:WaitForChild("HumanoidRootPart")

		task.spawn(function()
			-- Esperamos a que el personaje esté físicamente validado y su velocidad cargue
			while not char.Parent or humanoid.WalkSpeed == 0 do
				task.wait(0.05)
			end
			
			-- Pequeño delay de seguridad adicional para lectura del estado real del motor
			task.wait(0.3)
			
			gameBaseSpeed = math.abs(humanoid.WalkSpeed)
			if gameBaseSpeed == 0 then gameBaseSpeed = 16 end
			currentSmoothSpeed = gameBaseSpeed
			clearPhysics()
		end)
	end

	if localPlayer.Character then
		setupCharacter(localPlayer.Character)
	end
	table.insert(connections, localPlayer.CharacterAdded:Connect(setupCharacter))

	-- Controles de Dash (Q)
	table.insert(connections, UserInputService.InputBegan:Connect(function(input, gpe)
		if gpe or not isEnabled or not character or not humanoid then return end
		if textBox:IsFocused() then return end

		if input.KeyCode == Enum.KeyCode.Q then
			local state = humanoid:GetState()
			if state == Enum.HumanoidStateType.FallingDown or state == Enum.HumanoidStateType.Ragdoll or humanoid.PlatformStand then
				return
			end

			if tick() - lastDashEnd >= DASH_COOLDOWN then
				local isLateral = UserInputService:IsKeyDown(Enum.KeyCode.A) or UserInputService:IsKeyDown(Enum.KeyCode.D)
				local isForwardBack = UserInputService:IsKeyDown(Enum.KeyCode.W) or UserInputService:IsKeyDown(Enum.KeyCode.S)

				if isForwardBack or not isLateral then return end

				lastDashEnd = tick()
				isExploding = true

				local dir = humanoid.MoveDirection
				if dir.Magnitude < 0.01 then
					dir = rootPart.CFrame.LookVector
				end

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

	-- Heartbeat: Físicas y Actualización del Medidor
	table.insert(connections, RunService.Heartbeat:Connect(function(deltaTime)
		if not isEnabled or not character or not humanoid or not rootPart or not character.Parent then 
			if meterLabel then meterLabel.Text = "0.0" end
			return 
		end

		-- Actualizar Medidor de Velocidad (Magnitud horizontal para studs/s precisos en tierra)
		if meterLabel then
			local vel = rootPart.AssemblyLinearVelocity
			local horizontalVel = Vector3.new(vel.X, 0, vel.Z).Magnitude
			meterLabel.Text = string.format("%.1f", horizontalVel)
		end

		local state = humanoid:GetState()
		local isRagdoll = state == Enum.HumanoidStateType.FallingDown or state == Enum.HumanoidStateType.Ragdoll or humanoid.PlatformStand

		if isRagdoll then isExploding = false end

		local moveDir = humanoid.MoveDirection
		local currentTime = tick()
		local camera = workspace.CurrentCamera

		-- Lógica de dirección manual en ragdoll
		if isRagdoll and moveDir.Magnitude < 0.01 then
			local camCFrame = camera.CFrame
			local forward = Vector3.new(camCFrame.LookVector.X, 0, camCFrame.LookVector.Z)
			forward = forward.Magnitude > 0 and forward.Unit or Vector3.new(0, 0, -1)
			local right = Vector3.new(camCFrame.RightVector.X, 0, camCFrame.RightVector.Z)
			right = right.Magnitude > 0 and right.Unit or Vector3.new(1, 0, 0)

			local manualDir = Vector3.zero
			if UserInputService:IsKeyDown(Enum.KeyCode.W) then manualDir += forward end
			if UserInputService:IsKeyDown(Enum.KeyCode.S) then manualDir -= forward end
			if UserInputService:IsKeyDown(Enum.KeyCode.D) then manualDir += right end
			if UserInputService:IsKeyDown(Enum.KeyCode.A) then manualDir -= right end

			if manualDir.Magnitude > 0.01 then
				moveDir = manualDir.Unit
			end
		end

		-- Ghosting de partes
		local overlapParams = OverlapParams.new()
		overlapParams.FilterDescendantsInstances = { character }
		overlapParams.FilterType = Enum.RaycastFilterType.Exclude

		if not isRagdoll then
			local floorPart = nil
			local rayParams = RaycastParams.new()
			rayParams.FilterDescendantsInstances = { character }
			rayParams.FilterType = Enum.RaycastFilterType.Exclude

			local rayResult = workspace:Raycast(rootPart.Position, Vector3.new(0, -5, 0), rayParams)
			if rayResult then floorPart = rayResult.Instance end

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
			if linearVelocity then linearVelocity.MaxAxesForce = Vector3.zero end
			return
		end

		-- Cálculo de velocidad segura
		local safeCurrentGameSpeed = math.abs(humanoid.WalkSpeed)
		local safeBaseSpeed = math.abs(gameBaseSpeed)
		if safeBaseSpeed == 0 then safeBaseSpeed = 16 end

		local speedMultiplier = math.max(1, safeCurrentGameSpeed / safeBaseSpeed)
		local baseTargetSpeed = math.abs(currentSpeed * speedMultiplier)
		local finalTargetSpeed = baseTargetSpeed

		local nearestEnemyHRP = nil
		local minDistance = math.huge

		for _, otherPlayer in ipairs(Players:GetPlayers()) do
			if otherPlayer ~= localPlayer and otherPlayer.Character then
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
		currentSmoothSpeed = currentSmoothSpeed + (finalTargetSpeed - currentSmoothSpeed) * lerpSpeed

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
			linearVelocity.VectorVelocity = Vector3.new(targetVelocityVector.X, 0, targetVelocityVector.Z)
		else
			linearVelocity.MaxAxesForce = Vector3.new(activeForce, 0, activeForce)
			linearVelocity.VectorVelocity = Vector3.zero
		end
	end))

	return true
end

return M
