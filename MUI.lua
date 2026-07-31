--[[
    UltraInstinct4DDodge.lua

    Módulo de cliente para integrarlo en un hub. Detecta animaciones que el
    cliente recibe de jugadores remotos y ejecuta un 4D temporal para cada
    regla configurada.

    Uso mínimo:
        local Dodge4D = loadstring(readfile("UltraInstinct4DDodge.lua"))()
        Dodge4D.Start()

    O, si se guarda como ModuleScript:
        local Dodge4D = require(path.AlModulo)
        Dodge4D.Start()

    El personaje real se mueve hacia arriba y solo se oculta localmente.
    El clon, el aura y los sonidos también son locales. La experiencia debe
    permitir al cliente controlar el movimiento de su personaje para que el
    desplazamiento físico tenga efecto fuera de su propio cliente.
]]

local M = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Debris = game:GetService("Debris")
local SoundService = game:GetService("SoundService")

-- ============================================================================
-- CONFIGURACIÓN
-- ============================================================================
-- Añade tus animaciones aquí. La clave es solo un nombre legible para el hub.
-- Duration está expresada en segundos.
M.Config = {

	Dodges = {
		Bakugo_Ultimate = {
			AnimationId = "18673594132",
			Duration = 2.50,
		},
	},

	-- 4D
	SkyAltitude = 1500,
	LiftSpeed = 900,
	LiftTimeout = 4,
	HoldForce = 9e8,
	RefreshOnRepeatedTrigger = true,
	SameAnimationCooldown = 0.20,

	-- Clon visual. Puedes moverlo con WASD mientras el 4D está activo.
	AllowCloneMovement = true,
	CloneWalkSpeed = 105,
	CloneHeadOffset = 3,
	GroundProbeHeight = 220,
	GroundProbeDepth = 520,
	MaxGroundStepPerSecond = 28,

	-- Sonidos pedidos
	ActivationSoundId = "140694363106746",
	DeactivationSoundId = "130457690489621",
	SoundVolume = 1.35,

	-- Aura local: plata, blanco, cian y violeta; el cuerpo del clon no se tiñe.
	Aura = {
		Enabled = true,
		CoreColor = Color3.fromRGB(245, 250, 255),
		CyanColor = Color3.fromRGB(95, 225, 255),
		VioletColor = Color3.fromRGB(156, 115, 255),
		ParticleRate = 56,
		RingSegments = 18,
	},

	-- Normalmente se deja en false: AnimationPlayed solo captura futuras pistas.
	-- Activarlo también evalúa las animaciones que ya estaban reproduciéndose al
	-- conectarse al personaje remoto.
	ScanAlreadyPlayingOnAttach = false,
}

-- ============================================================================
-- ESTADO INTERNO
-- ============================================================================
local enabled = false
local localPlayer = nil
local active = false
local activeUntil = 0
local activationToken = 0
local activeDodgeName = nil

local dodgeByAnimationId = {}
local lastTriggerAt = {}
local playerWatches = {}

local heartbeatConnection = nil
local playerAddedConnection = nil
local playerRemovingConnection = nil
local localCharacterRemovingConnection = nil

local cloneModel = nil
local cloneRoot = nil
local cameraSubject = nil
local skyVelocity = nil
local skyPosition = nil
local auraFolder = nil
local auraRings = {}
local auraLight = nil

local virtualRootPosition = nil
local skyY = nil
local footOffset = 3
local originalTransparency = setmetatable({}, { __mode = "k" })

-- ============================================================================
-- UTILIDADES
-- ============================================================================
local function disconnect(connection)
	if connection then
		pcall(function()
			connection:Disconnect()
		end)
	end
end

local function assetNumber(value)
	return tostring(value or ""):match("%d+") or ""
end

local function toAssetId(value)
	local id = assetNumber(value)
	return id ~= "" and ("rbxassetid://" .. id) or ""
end

local function getRoot(character)
	return character and (character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso"))
end

local function getHumanoid(character)
	return character and character:FindFirstChildOfClass("Humanoid")
end

local function getFootOffset(character)
	local humanoid = getHumanoid(character)
	local root = getRoot(character)
	if humanoid and root then
		return humanoid.HipHeight + root.Size.Y * 0.5
	end
	return 3
end

local function playLocalSound(id)
	local soundId = toAssetId(id)
	if soundId == "" then
		return
	end

	local sound = Instance.new("Sound")
	sound.Name = "UltraInstinct4DSound"
	sound.SoundId = soundId
	sound.Volume = M.Config.SoundVolume
	sound.Parent = SoundService
	sound:Play()
	Debris:AddItem(sound, 8)
end

local function rebuildDodgeIndex()
	table.clear(dodgeByAnimationId)
	for dodgeName, dodge in pairs(M.Config.Dodges) do
		local id = assetNumber(dodge.AnimationId)
		local duration = tonumber(dodge.Duration)
		if id ~= "" and duration and duration > 0 then
			dodgeByAnimationId[id] = {
				Name = dodgeName,
				Duration = duration,
			}
		end
	end
end

local function mergeConfig(target, source)
	for key, value in pairs(source) do
		if key ~= "Dodges" and type(value) == "table" and type(target[key]) == "table" then
			mergeConfig(target[key], value)
		else
			target[key] = value
		end
	end
end

local function destroySkyForces()
	if skyVelocity then
		skyVelocity:Destroy()
		skyVelocity = nil
	end
	if skyPosition then
		skyPosition:Destroy()
		skyPosition = nil
	end
end

local function destroyCameraSubject()
	if cameraSubject then
		cameraSubject:Destroy()
		cameraSubject = nil
	end
end

local function destroyClone()
	if cloneModel then
		cloneModel:Destroy()
		cloneModel = nil
		cloneRoot = nil
	end
end

local function destroyAura()
	if auraFolder then
		auraFolder:Destroy()
		auraFolder = nil
	end
	auraRings = {}
	auraLight = nil
end

local function hideRealCharacter(character)
	table.clear(originalTransparency)
	for _, descendant in ipairs(character:GetDescendants()) do
		if descendant:IsA("BasePart") or descendant:IsA("Decal") then
			pcall(function()
				originalTransparency[descendant] = descendant.LocalTransparencyModifier
				descendant.LocalTransparencyModifier = 1
			end)
		end
	end
end

local function restoreRealCharacter()
	for instance, previousValue in pairs(originalTransparency) do
		if instance and instance.Parent then
			pcall(function()
				instance.LocalTransparencyModifier = previousValue
			end)
		end
	end
	table.clear(originalTransparency)
end

local function createVisualClone(character, startCFrame)
	local previousArchivable = character.Archivable
	character.Archivable = true
	local ok, clone = pcall(function()
		return character:Clone()
	end)
	character.Archivable = previousArchivable

	if not ok or not clone then
		return nil, nil
	end

	clone.Name = "UltraInstinct4DClone"
	for _, descendant in ipairs(clone:GetDescendants()) do
		if descendant:IsA("Script") or descendant:IsA("LocalScript") then
			descendant:Destroy()
		elseif descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
			descendant.CanTouch = false
			descendant.CanQuery = false
			descendant.CastShadow = false
		elseif descendant:IsA("Humanoid") then
			descendant.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
			descendant.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
			descendant.AutoRotate = false
		end
	end

	clone.Parent = workspace
	clone:PivotTo(startCFrame)
	return clone, getRoot(clone)
end

local function createCameraSubject(position)
	local subject = Instance.new("Part")
	subject.Name = "UltraInstinct4DCameraSubject"
	subject.Size = Vector3.new(1, 1, 1)
	subject.Transparency = 1
	subject.Anchored = true
	subject.CanCollide = false
	subject.CanTouch = false
	subject.CanQuery = false
	subject.CFrame = CFrame.new(position + Vector3.new(0, M.Config.CloneHeadOffset, 0))
	subject.Parent = workspace
	return subject
end

local function makeParticle(parent, color, rate, speed, lifetime, size, transparency)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = "rbxasset://textures/particles/smoke_main.dds"
	emitter.Color = ColorSequence.new(color)
	emitter.LightEmission = 0.9
	emitter.LightInfluence = 0
	emitter.Rate = rate
	emitter.Lifetime = lifetime
	emitter.Speed = speed
	emitter.Acceleration = Vector3.new(0, 10, 0)
	emitter.SpreadAngle = Vector2.new(22, 22)
	emitter.EmissionDirection = Enum.NormalId.Top
	emitter.Rotation = NumberRange.new(0, 360)
	emitter.RotSpeed = NumberRange.new(-75, 75)
	emitter.Size = size
	emitter.Transparency = transparency
	emitter.Parent = parent
	return emitter
end

local function createRing(folder, color, radius, yOffset, phase)
	local ring = {
		Parts = {},
		Color = color,
		Radius = radius,
		YOffset = yOffset,
		Phase = phase,
	}

	local segments = math.max(8, math.floor(M.Config.Aura.RingSegments))
	for _ = 1, segments do
		local part = Instance.new("Part")
		part.Name = "AuraRingSegment"
		part.Anchored = true
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
		part.CastShadow = false
		part.Material = Enum.Material.Neon
		part.Color = color
		part.Transparency = 0.32
		part.Size = Vector3.new(0.12, 0.12, 0.12)
		part.Parent = folder
		table.insert(ring.Parts, part)
	end
	return ring
end

local function createUltraInstinctAura(root)
	if not M.Config.Aura.Enabled or not root then
		return
	end

	local aura = Instance.new("Folder")
	aura.Name = "UltraInstinctAura_Local"
	aura.Parent = cloneModel
	auraFolder = aura

	local lowerAttachment = Instance.new("Attachment")
	lowerAttachment.Name = "AuraLower"
	lowerAttachment.Position = Vector3.new(0, -2.2, 0)
	lowerAttachment.Parent = root

	local upperAttachment = Instance.new("Attachment")
	upperAttachment.Name = "AuraUpper"
	upperAttachment.Position = Vector3.new(0, 2.2, 0)
	upperAttachment.Parent = root

	local auraConfig = M.Config.Aura
	makeParticle(
		lowerAttachment,
		auraConfig.CyanColor,
		auraConfig.ParticleRate,
		NumberRange.new(4, 8),
		NumberRange.new(0.46, 0.82),
		NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.9),
			NumberSequenceKeypoint.new(0.45, 2.1),
			NumberSequenceKeypoint.new(1, 0.15),
		}),
		NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.38),
			NumberSequenceKeypoint.new(0.65, 0.58),
			NumberSequenceKeypoint.new(1, 1),
		})
	)

	makeParticle(
		upperAttachment,
		auraConfig.VioletColor,
		math.floor(auraConfig.ParticleRate * 0.42),
		NumberRange.new(2, 5),
		NumberRange.new(0.55, 1.05),
		NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.35),
			NumberSequenceKeypoint.new(0.5, 1.45),
			NumberSequenceKeypoint.new(1, 0.05),
		}),
		NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.55),
			NumberSequenceKeypoint.new(1, 1),
		})
	)

	local sparks = Instance.new("ParticleEmitter")
	sparks.Name = "SilverSparks"
	sparks.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparks.Color = ColorSequence.new(auraConfig.CoreColor, auraConfig.CyanColor)
	sparks.LightEmission = 1
	sparks.LightInfluence = 0
	sparks.Rate = math.floor(auraConfig.ParticleRate * 0.6)
	sparks.Lifetime = NumberRange.new(0.65, 1.25)
	sparks.Speed = NumberRange.new(2, 7)
	sparks.Acceleration = Vector3.new(0, 5, 0)
	sparks.SpreadAngle = Vector2.new(180, 180)
	sparks.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.18),
		NumberSequenceKeypoint.new(0.5, 0.5),
		NumberSequenceKeypoint.new(1, 0),
	})
	sparks.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.7, 0.1),
		NumberSequenceKeypoint.new(1, 1),
	})
	sparks.Parent = upperAttachment

	local light = Instance.new("PointLight")
	light.Name = "UltraInstinctGlow"
	light.Color = auraConfig.CyanColor
	light.Brightness = 1.8
	light.Range = 18
	light.Shadows = false
	light.Parent = root
	auraLight = light

	auraRings = {
		createRing(aura, auraConfig.CoreColor, 3.2, -1.7, 0),
		createRing(aura, auraConfig.CyanColor, 4.7, -0.1, math.pi),
		createRing(aura, auraConfig.VioletColor, 3.8, 1.6, math.pi * 0.5),
	}
end

local function updateAura(now)
	if not cloneRoot then
		return
	end

	for ringIndex, ring in ipairs(auraRings) do
		local parts = ring.Parts
		local count = #parts
		local radius = ring.Radius + math.sin(now * 3.2 + ring.Phase) * 0.18
		local y = ring.YOffset + math.sin(now * 2.4 + ring.Phase) * 0.22
		local rotation = now * (ringIndex % 2 == 0 and -1.6 or 1.25) + ring.Phase
		local arcLength = (2 * math.pi * radius / count) * 0.82

		for index, part in ipairs(parts) do
			if part.Parent then
				local angle = rotation + (index - 1) / count * math.pi * 2
				local radial = Vector3.new(math.cos(angle), 0, math.sin(angle))
				local position = cloneRoot.Position + radial * radius + Vector3.new(0, y, 0)
				local tangent = Vector3.new(-math.sin(angle), 0, math.cos(angle))
				part.Size = Vector3.new(0.09, 0.09, arcLength)
				part.CFrame = CFrame.lookAt(position, position + tangent)
				part.Transparency = 0.25 + math.abs(math.sin(now * 4 + index)) * 0.35
			end
		end
	end

	if auraLight and auraLight.Parent then
		auraLight.Brightness = 1.4 + (math.sin(now * 7) + 1) * 0.65
	end
end

local function getGroundRootPosition(position, character)
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = { character, cloneModel, cameraSubject, auraFolder }

	local origin = Vector3.new(position.X, position.Y + M.Config.GroundProbeHeight, position.Z)
	local result = workspace:Raycast(origin, Vector3.new(0, -M.Config.GroundProbeDepth, 0), rayParams)
	if result then
		return Vector3.new(position.X, result.Position.Y + footOffset, position.Z)
	end
	return position
end

local function moveVirtualClone(dt, character)
	if not M.Config.AllowCloneMovement or not virtualRootPosition then
		return
	end

	local camera = workspace.CurrentCamera
	if not camera then
		return
	end

	local look = camera.CFrame.LookVector
	local right = camera.CFrame.RightVector
	local forwardFlat = Vector3.new(look.X, 0, look.Z)
	local rightFlat = Vector3.new(right.X, 0, right.Z)
	if forwardFlat.Magnitude > 0 then forwardFlat = forwardFlat.Unit end
	if rightFlat.Magnitude > 0 then rightFlat = rightFlat.Unit end

	local movement = Vector3.zero
	if UserInputService:IsKeyDown(Enum.KeyCode.W) then movement += forwardFlat end
	if UserInputService:IsKeyDown(Enum.KeyCode.S) then movement -= forwardFlat end
	if UserInputService:IsKeyDown(Enum.KeyCode.D) then movement += rightFlat end
	if UserInputService:IsKeyDown(Enum.KeyCode.A) then movement -= rightFlat end

	if movement.Magnitude > 0 then
		local proposed = virtualRootPosition + movement.Unit * M.Config.CloneWalkSpeed * dt
		local grounded = getGroundRootPosition(proposed, character)
		local yDelta = math.clamp(
			grounded.Y - virtualRootPosition.Y,
			-M.Config.MaxGroundStepPerSecond * dt,
			M.Config.MaxGroundStepPerSecond * dt
		)
		virtualRootPosition = Vector3.new(proposed.X, virtualRootPosition.Y + yDelta, proposed.Z)
	end
end

local function updateCloneAndCamera()
	if not virtualRootPosition then
		return
	end

	local camera = workspace.CurrentCamera
	local yaw = 0
	if camera then
		local look = camera.CFrame.LookVector
		if Vector3.new(look.X, 0, look.Z).Magnitude > 0.01 then
			yaw = math.atan2(-look.X, -look.Z)
		end
	end

	if cloneModel and cloneRoot then
		cloneModel:PivotTo(CFrame.new(virtualRootPosition) * CFrame.Angles(0, yaw, 0))
	end
	if cameraSubject then
		cameraSubject.CFrame = CFrame.new(virtualRootPosition + Vector3.new(0, M.Config.CloneHeadOffset, 0))
	end
	if skyPosition and skyY then
		skyPosition.Position = Vector3.new(virtualRootPosition.X, skyY, virtualRootPosition.Z)
	end
end

local deactivate4D

local function startSkyLift(character, root, token)
	destroySkyForces()

	skyVelocity = Instance.new("BodyVelocity")
	skyVelocity.Name = "UltraInstinct4DLift"
	skyVelocity.Velocity = Vector3.new(0, M.Config.LiftSpeed, 0)
	skyVelocity.MaxForce = Vector3.new(0, M.Config.HoldForce, 0)
	skyVelocity.Parent = root

	task.spawn(function()
		local startedAt = os.clock()
		while active and token == activationToken and root.Parent do
			if root.Position.Y >= skyY - 20 or os.clock() - startedAt >= M.Config.LiftTimeout then
				break
			end
			task.wait(0.05)
		end

		if not active or token ~= activationToken or not root.Parent then
			return
		end

		if skyVelocity then
			skyVelocity:Destroy()
			skyVelocity = nil
		end

		skyPosition = Instance.new("BodyPosition")
		skyPosition.Name = "UltraInstinct4DHold"
		skyPosition.Position = Vector3.new(root.Position.X, skyY, root.Position.Z)
		skyPosition.MaxForce = Vector3.new(M.Config.HoldForce, M.Config.HoldForce, M.Config.HoldForce)
		skyPosition.P = 60000
		skyPosition.D = 2500
		skyPosition.Parent = root
	end)
end

local function begin4D(dodge)
	local character = localPlayer and localPlayer.Character
	local root = getRoot(character)
	local humanoid = getHumanoid(character)
	if not character or not root or not humanoid or humanoid.Health <= 0 then
		return
	end

	active = true
	activationToken += 1
	local token = activationToken
	activeDodgeName = dodge.Name
	activeUntil = os.clock() + dodge.Duration
	footOffset = getFootOffset(character)
	virtualRootPosition = root.Position
	skyY = root.Position.Y + M.Config.SkyAltitude

	cloneModel, cloneRoot = createVisualClone(character, root.CFrame)
	cameraSubject = createCameraSubject(virtualRootPosition)
	hideRealCharacter(character)
	createUltraInstinctAura(cloneRoot)

	local camera = workspace.CurrentCamera
	if camera and cameraSubject then
		camera.CameraSubject = cameraSubject
	end

	startSkyLift(character, root, token)
	playLocalSound(M.Config.ActivationSoundId)
end

deactivate4D = function(shouldReturnToClone)
	if not active then
		return
	end

	active = false
	activationToken += 1
	destroySkyForces()

	local character = localPlayer and localPlayer.Character
	local root = getRoot(character)
	local humanoid = getHumanoid(character)
	local landingCFrame = cloneRoot and cloneRoot.CFrame or (root and root.CFrame)

	if shouldReturnToClone and root and humanoid and humanoid.Health > 0 and landingCFrame then
		local _, yaw = landingCFrame:ToOrientation()
		local landingPosition = virtualRootPosition or landingCFrame.Position
		landingPosition = getGroundRootPosition(landingPosition, character)

		pcall(function()
			humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
			root.CFrame = CFrame.new(landingPosition) * CFrame.Angles(0, yaw, 0)
			root.AssemblyLinearVelocity = Vector3.zero
			root.AssemblyAngularVelocity = Vector3.zero
			task.defer(function()
				if humanoid.Parent then
					humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
				end
			end)
		end)
	end

	local camera = workspace.CurrentCamera
	if camera and humanoid and humanoid.Parent then
		camera.CameraSubject = humanoid
	end

	restoreRealCharacter()
	destroyAura()
	destroyClone()
	destroyCameraSubject()
	virtualRootPosition = nil
	skyY = nil
	activeDodgeName = nil
	playLocalSound(M.Config.DeactivationSoundId)
end

local function triggerDodge(dodge, player)
	if not enabled or not dodge then
		return
	end

	local now = os.clock()
	local playerKey = player and player.UserId or 0
	local triggerKey = tostring(playerKey) .. ":" .. dodge.Name
	if now - (lastTriggerAt[triggerKey] or -math.huge) < M.Config.SameAnimationCooldown then
		return
	end
	lastTriggerAt[triggerKey] = now

	if active then
		if M.Config.RefreshOnRepeatedTrigger then
			activeUntil = math.max(activeUntil, now + dodge.Duration)
		end
		return
	end

	begin4D(dodge)
end

local function onRemoteAnimationPlayed(player, track)
	local animation = track and track.Animation
	local animationId = animation and assetNumber(animation.AnimationId)
	if animationId == "" then
		return
	end
	triggerDodge(dodgeByAnimationId[animationId], player)
end

local function disconnectWatch(player)
	local watch = playerWatches[player]
	if not watch then
		return
	end
	disconnect(watch.CharacterAdded)
	disconnect(watch.AnimationPlayed)
	playerWatches[player] = nil
end

local function hookCharacter(player, character)
	local watch = playerWatches[player]
	if not watch then
		return
	end
	disconnect(watch.AnimationPlayed)
	watch.AnimationPlayed = nil

	task.spawn(function()
		local humanoid = character:WaitForChild("Humanoid", 5)
		if not enabled or player.Character ~= character or playerWatches[player] ~= watch or not humanoid then
			return
		end

		local animator = humanoid:FindFirstChildOfClass("Animator") or humanoid:WaitForChild("Animator", 5)
		if not enabled or player.Character ~= character or playerWatches[player] ~= watch then
			return
		end
		animator = animator or humanoid

		watch.AnimationPlayed = animator.AnimationPlayed:Connect(function(track)
			onRemoteAnimationPlayed(player, track)
		end)

		if M.Config.ScanAlreadyPlayingOnAttach then
			for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
				onRemoteAnimationPlayed(player, track)
			end
		end
	end)
end

local function watchRemotePlayer(player)
	if player == localPlayer or playerWatches[player] then
		return
	end

	local watch = {}
	playerWatches[player] = watch
	watch.CharacterAdded = player.CharacterAdded:Connect(function(character)
		hookCharacter(player, character)
	end)

	if player.Character then
		hookCharacter(player, player.Character)
	end
end

local function stopWatchingEveryone()
	local watchedPlayers = {}
	for player in pairs(playerWatches) do
		table.insert(watchedPlayers, player)
	end
	for _, player in ipairs(watchedPlayers) do
		disconnectWatch(player)
	end
	disconnect(playerAddedConnection)
	disconnect(playerRemovingConnection)
	playerAddedConnection = nil
	playerRemovingConnection = nil
	table.clear(lastTriggerAt)
end

local function onHeartbeat(dt)
	if not active then
		return
	end

	local character = localPlayer and localPlayer.Character
	local root = getRoot(character)
	local humanoid = getHumanoid(character)
	if not character or not root or not humanoid or humanoid.Health <= 0 then
		deactivate4D(false)
		return
	end

	if os.clock() >= activeUntil then
		deactivate4D(true)
		return
	end

	moveVirtualClone(dt, character)
	updateCloneAndCamera()
	updateAura(os.clock())
end

-- ============================================================================
-- API PÚBLICA PARA EL HUB
-- ============================================================================
function M.Configure(overrides)
	assert(type(overrides) == "table", "Configure espera una tabla")
	mergeConfig(M.Config, overrides)
	rebuildDodgeIndex()
end

function M.SetDodges(dodges)
	assert(type(dodges) == "table", "SetDodges espera una tabla")
	M.Config.Dodges = dodges
	rebuildDodgeIndex()
end

function M.Start(overrides)
	if enabled then
		M.Stop()
	end
	if overrides then
		M.Configure(overrides)
	else
		rebuildDodgeIndex()
	end

	localPlayer = Players.LocalPlayer
	assert(localPlayer, "UltraInstinct4DDodge debe ejecutarse desde un LocalScript")
	enabled = true

	for _, player in ipairs(Players:GetPlayers()) do
		watchRemotePlayer(player)
	end
	playerAddedConnection = Players.PlayerAdded:Connect(watchRemotePlayer)
	playerRemovingConnection = Players.PlayerRemoving:Connect(disconnectWatch)
	localCharacterRemovingConnection = localPlayer.CharacterRemoving:Connect(function()
		deactivate4D(false)
	end)
	heartbeatConnection = RunService.Heartbeat:Connect(onHeartbeat)
end

function M.Stop()
	if not enabled then
		return
	end

	if active then
		deactivate4D(true)
	end
	enabled = false
	stopWatchingEveryone()
	disconnect(heartbeatConnection)
	disconnect(localCharacterRemovingConnection)
	heartbeatConnection = nil
	localCharacterRemovingConnection = nil
end

function M.TriggerDodge(dodgeName)
	local dodge = nil
	for _, candidate in pairs(dodgeByAnimationId) do
		if candidate.Name == dodgeName then
			dodge = candidate
			break
		end
	end
	triggerDodge(dodge, nil)
end

function M.IsActive()
	return active
end

function M.GetActiveDodge()
	return activeDodgeName
end

return M
