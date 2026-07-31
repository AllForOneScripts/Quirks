local M = {}

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ContentProvider = game:GetService("ContentProvider")

local localPlayer
local keys
local active = false
local connections = {}

local gui
local mainFrame
local playerImage
local isOpen = false
local setPanelOpen

local toggleKey = Enum.KeyCode.F4
local lastUsername = nil
local requestId = 0

local C_PURPLE = Color3.fromRGB(110, 30, 180)
local C_BLACK = Color3.fromRGB(6, 4, 12)
local C_TEXT = Color3.fromRGB(220, 190, 255)
local C_SUB = Color3.fromRGB(200, 170, 255)

local function disconnectAll()
	for _, connection in ipairs(connections) do
		if connection and connection.Connected then
			connection:Disconnect()
		end
	end

	table.clear(connections)
end

local function getUserId(username)
	local targetPlayer = Players:FindFirstChild(username)

	if targetPlayer then
		return targetPlayer.UserId
	end

	local success, userId = pcall(
		Players.GetUserIdFromNameAsync,
		Players,
		username
	)

	if success then
		return userId
	end

	return nil
end

local function loadAvatarImage(userId, currentRequest)
	task.spawn(function()
		local success, image = pcall(function()
			return Players:GetUserThumbnailAsync(
				userId,
				Enum.ThumbnailType.AvatarBust,
				Enum.ThumbnailSize.Size420x420
			)
		end)

		if currentRequest ~= requestId then
			return
		end

		if success and image and playerImage and playerImage.Parent then
			playerImage.Image = image

			pcall(function()
				ContentProvider:PreloadAsync({ playerImage })
			end)
		end
	end)
end

local function findHandleAttachment(handle)
	for _, child in ipairs(handle:GetChildren()) do
		if child:IsA("Attachment") then
			return child
		end
	end

	return nil
end

local function findCharacterAttachment(character, attachmentName)
	for _, descendant in ipairs(character:GetDescendants()) do
		if descendant:IsA("Attachment")
			and descendant.Name == attachmentName
			and descendant.Parent:IsA("BasePart") then
			return descendant
		end
	end

	return nil
end

local function manualAttachAccessory(accessory, character)
	local handle = accessory:FindFirstChild("Handle")

	if not handle or not handle:IsA("BasePart") then
		return false
	end

	local handleAttachment = findHandleAttachment(handle)

	if not handleAttachment then
		return false
	end

	local characterAttachment = findCharacterAttachment(
		character,
		handleAttachment.Name
	)

	if not characterAttachment then
		return false
	end

	accessory.Parent = character
	handle.Anchored = false
	handle.CanCollide = false
	handle.Massless = true
	handle.LocalTransparencyModifier = 0

	handle.CFrame =
		characterAttachment.Parent.CFrame
		* characterAttachment.CFrame
		* handleAttachment.CFrame:Inverse()

	local oldWeld = handle:FindFirstChild("AccessoryWeld")

	if oldWeld then
		oldWeld:Destroy()
	end

	local weld = Instance.new("Weld")
	weld.Name = "AccessoryWeld"
	weld.Part0 = handle
	weld.Part1 = characterAttachment.Parent
	weld.C0 = handleAttachment.CFrame
	weld.C1 = characterAttachment.CFrame
	weld.Parent = handle

	return true
end

local function applyAvatar(username, isReset)
	if not localPlayer or not username or username == "" then
		return
	end

	requestId += 1
	local currentRequest = requestId

	task.spawn(function()
		local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()

		if currentRequest ~= requestId then
			return
		end

		local humanoid = character:WaitForChild("Humanoid", 10)

		if not humanoid or currentRequest ~= requestId then
			return
		end

		local userId = getUserId(username)

		if not userId or currentRequest ~= requestId then
			return
		end

		loadAvatarImage(userId, currentRequest)

		local success, appearanceModel = pcall(function()
			return Players:GetCharacterAppearanceAsync(userId)
		end)

		if not success or not appearanceModel or currentRequest ~= requestId then
			if appearanceModel then
				appearanceModel:Destroy()
			end
			return
		end

		for _, child in ipairs(character:GetChildren()) do
			if child:IsA("Accessory")
				or child:IsA("Hat")
				or child:IsA("Shirt")
				or child:IsA("Pants")
				or child:IsA("ShirtGraphic")
				or child:IsA("CharacterMesh") then
				child:Destroy()
			end
		end

		local head = character:FindFirstChild("Head")

		if head then
			for _, child in ipairs(head:GetChildren()) do
				if child:IsA("DataModelMesh") or child:IsA("Decal") then
					child:Destroy()
				end
			end

			local defaultMesh = Instance.new("SpecialMesh")
			defaultMesh.MeshType = Enum.MeshType.Head
			defaultMesh.Scale = Vector3.new(1.25, 1.25, 1.25)
			defaultMesh.Parent = head
		end

		local loadedFace = false

		for _, item in ipairs(appearanceModel:GetChildren()) do
			if currentRequest ~= requestId then
				appearanceModel:Destroy()
				return
			end

			if item:IsA("Accessory") then
				local accessory = item:Clone()

				local added = pcall(function()
					humanoid:AddAccessory(accessory)
				end)

				local handle = accessory:FindFirstChild("Handle")

				if not (added and handle and handle:FindFirstChild("AccessoryWeld")) then
					manualAttachAccessory(accessory, character)
				end

			elseif item:IsA("Shirt")
				or item:IsA("Pants")
				or item:IsA("ShirtGraphic") then
				item:Clone().Parent = character

			elseif item:IsA("BodyColors") then
				local oldColors = character:FindFirstChildOfClass("BodyColors")

				if oldColors then
					oldColors:Destroy()
				end

				item:Clone().Parent = character

			elseif item:IsA("Decal") and item.Name:lower() == "face" then
				if head then
					loadedFace = true

					local face = item:Clone()
					local faceId = string.match(item.Texture, "%d+")

					if faceId then
						face.Texture = "rbxthumb://type=Asset&id="
							.. faceId
							.. "&w=420&h=420"
					end

					face.Parent = head
				end

			elseif item.Name == "R6" and item:IsA("Folder") then
				for _, r6Item in ipairs(item:GetChildren()) do
					if r6Item:IsA("CharacterMesh") then
						r6Item:Clone().Parent = character

					elseif r6Item:IsA("DataModelMesh") and head then
						for _, oldMesh in ipairs(head:GetChildren()) do
							if oldMesh:IsA("DataModelMesh") then
								oldMesh:Destroy()
							end
						end

						r6Item:Clone().Parent = head
					end
				end

			elseif item:IsA("CharacterMesh") then
				item:Clone().Parent = character
			end
		end

		appearanceModel:Destroy()

		if currentRequest ~= requestId then
			return
		end

		if isReset then
			if head and not head:FindFirstChildOfClass("Decal") then
				local defaultFace = Instance.new("Decal")
				defaultFace.Name = "face"
				defaultFace.Face = Enum.NormalId.Front
				defaultFace.Texture = "rbxasset://textures/face.png"
				defaultFace.Parent = head
			end

			return
		end

		if humanoid.RigType == Enum.HumanoidRigType.R6 and head and not loadedFace then
			local errorFace = Instance.new("Decal")
			errorFace.Name = "face"
			errorFace.Face = Enum.NormalId.Front
			errorFace.Texture = "rbxthumb://type=Asset&id=7084675103&w=420&h=420"
			errorFace.Parent = head
		end
	end)
end

local function resetToOriginal()
	if not localPlayer then
		return
	end

	lastUsername = nil
	applyAvatar(localPlayer.Name, true)
end

function M.SetKey(keyCode)
	if typeof(keyCode) ~= "EnumItem" then
		return
	end

	toggleKey = keyCode

	if keys then
		keys.Toggle = keyCode
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

function M.Stop(restoreAvatar)
	requestId += 1
	active = false
	disconnectAll()

	if gui then
		gui:Destroy()
	end

	gui = nil
	mainFrame = nil
	playerImage = nil
	setPanelOpen = nil
	isOpen = false

	if restoreAvatar and localPlayer then
		applyAvatar(localPlayer.Name, true)
	end
end

function M.Start(firstArgument, secondArgument)
	-- Compatible con Start(Keys, Player) y Start(Player, Keys).
	if typeof(firstArgument) == "Instance" and firstArgument:IsA("Player") then
		localPlayer = firstArgument
		keys = secondArgument
	else
		keys = firstArgument
		localPlayer = secondArgument or Players.LocalPlayer
	end

	if not localPlayer then
		warn("[CopyAvatar] No se encontró LocalPlayer.")
		return false
	end

	if keys and typeof(keys.Toggle) == "EnumItem" then
		toggleKey = keys.Toggle
	end

	-- Cancela tareas anteriores y elimina una GUI vieja,
	-- sin restaurar el avatar durante el arranque.
	requestId += 1
	disconnectAll()

	if gui then
		gui:Destroy()
	end

	local playerGui = localPlayer:WaitForChild("PlayerGui")
	local oldGui = playerGui:FindFirstChild("AFO_AvatarChanger")

	if oldGui then
		oldGui:Destroy()
	end

	active = true
	isOpen = false
	lastUsername = "Wiftor"

	gui = Instance.new("ScreenGui")
	gui.Name = "AFO_AvatarChanger"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = playerGui

	mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainPanel"
	mainFrame.Size = UDim2.new(0, 240, 0, 115)
	mainFrame.AnchorPoint = Vector2.new(1, 0)
	mainFrame.Position = UDim2.new(1, 300, 0, 190)
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
	closeButton.TextColor3 = Color3.new(1, 1, 1)
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
	title.Text = "Avatar Changer"
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = mainFrame

	local textBox = Instance.new("TextBox")
	textBox.Size = UDim2.new(0, 145, 0, 25)
	textBox.Position = UDim2.new(0, 15, 0, 40)
	textBox.BackgroundColor3 = Color3.fromRGB(20, 10, 40)
	textBox.BackgroundTransparency = 0.3
	textBox.TextColor3 = C_TEXT
	textBox.PlaceholderColor3 = C_SUB
	textBox.PlaceholderText = "Username..."
	textBox.Text = "Wiftor"
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

	local applyButton = Instance.new("TextButton")
	applyButton.Size = UDim2.new(0, 115, 0, 25)
	applyButton.Position = UDim2.new(0, 15, 0, 75)
	applyButton.BackgroundColor3 = Color3.fromRGB(80, 20, 140)
	applyButton.BackgroundTransparency = 0.2
	applyButton.TextColor3 = Color3.new(1, 1, 1)
	applyButton.Font = Enum.Font.GothamBold
	applyButton.TextSize = 12
	applyButton.Text = "Apply"
	applyButton.BorderSizePixel = 0
	applyButton.Parent = mainFrame

	Instance.new("UICorner", applyButton).CornerRadius = UDim.new(0, 4)

	local resetButton = Instance.new("TextButton")
	resetButton.Size = UDim2.new(0, 25, 0, 25)
	resetButton.Position = UDim2.new(0, 135, 0, 75)
	resetButton.BackgroundColor3 = Color3.fromRGB(80, 20, 140)
	resetButton.BackgroundTransparency = 0.2
	resetButton.TextColor3 = Color3.new(1, 1, 1)
	resetButton.Font = Enum.Font.GothamBold
	resetButton.TextSize = 14
	resetButton.Text = "↻"
	resetButton.BorderSizePixel = 0
	resetButton.Parent = mainFrame

	Instance.new("UICorner", resetButton).CornerRadius = UDim.new(0, 4)

	local imageContainer = Instance.new("Frame")
	imageContainer.Size = UDim2.new(0, 55, 0, 55)
	imageContainer.Position = UDim2.new(1, -70, 0, 30)
	imageContainer.BackgroundColor3 = Color3.fromRGB(20, 10, 40)
	imageContainer.BackgroundTransparency = 0.3
	imageContainer.BorderSizePixel = 0
	imageContainer.ZIndex = 11
	imageContainer.Parent = mainFrame

	Instance.new("UICorner", imageContainer).CornerRadius = UDim.new(1, 0)

	playerImage = Instance.new("ImageLabel")
	playerImage.Name = "PlayerImage"
	playerImage.Size = UDim2.fromScale(1, 1)
	playerImage.BackgroundTransparency = 1
	playerImage.Image = ""
	playerImage.ZIndex = 12
	playerImage.Parent = imageContainer

	Instance.new("UICorner", playerImage).CornerRadius = UDim.new(1, 0)

	local tweenInfo = TweenInfo.new(
		0.5,
		Enum.EasingStyle.Quart,
		Enum.EasingDirection.Out
	)

	setPanelOpen = function(open)
		if not active or not mainFrame or not mainFrame.Parent then
			return
		end

		isOpen = open

		local position = isOpen
			and UDim2.new(1, -20, 0, 190)
			or UDim2.new(1, 300, 0, 190)

		TweenService:Create(mainFrame, tweenInfo, {
			Position = position,
		}):Play()
	end

	local function togglePanel()
		setPanelOpen(not isOpen)
	end

	local function startNewAvatar(username)
		if username and username ~= "" then
			lastUsername = username
			applyAvatar(username, false)
		end
	end

	table.insert(connections, localPlayer.CharacterAppearanceLoaded:Connect(function()
		if active and lastUsername and lastUsername ~= localPlayer.Name then
			applyAvatar(lastUsername, false)
		end
	end))

	table.insert(connections, applyButton.MouseButton1Click:Connect(function()
		startNewAvatar(textBox.Text)
	end))

	table.insert(connections, textBox.FocusLost:Connect(function(enterPressed)
		if enterPressed then
			startNewAvatar(textBox.Text)
		end
	end))

	table.insert(connections, resetButton.MouseButton1Click:Connect(function()
		textBox.Text = localPlayer.Name
		resetToOriginal()
	end))

	table.insert(connections, closeButton.MouseButton1Click:Connect(function()
		M.Stop(true)
	end))

	table.insert(connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if not gameProcessed and input.KeyCode == toggleKey then
			togglePanel()
		end
	end))

	startNewAvatar("Wiftor")
	M.Open()

	return true
end

return M
