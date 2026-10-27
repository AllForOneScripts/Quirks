local M = {}
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ContentProvider = game:GetService("ContentProvider")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")
local Debris = game:GetService("Debris")
local SoundService = game:GetService("SoundService")
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
local transforming = false
local gray = nil
local descriptionCache = {}
local defaultAnims = setmetatable({}, { __mode = "k" })
local originalDescriptions = setmetatable({}, { __mode = "k" })
local originalFaces = setmetatable({}, { __mode = "k" })
local autoReapply = true
local deathStrikes = 0
local C_PURPLE = Color3.fromRGB(110, 30, 180)
local C_BLACK = Color3.fromRGB(6, 4, 12)
local C_TEXT = Color3.fromRGB(220, 190, 255)
local C_SUB = Color3.fromRGB(200, 170, 255)
local C_BOX = Color3.fromRGB(20, 10, 40)
local PANEL_W, PANEL_H = 290, 128
local BOX_W = 190
local MAX_TEXT, MIN_TEXT = 14, 11
local MAX_RESULTS = 12
local ROW_H = 52
local MENU_MAX_ROWS = 3
local GRAY_A = Color3.fromRGB(125, 127, 134)
local GRAY_B = Color3.fromRGB(208, 210, 218)
local GRAY_NAME = "AFO_GrayLayer"
local BODY_COLOR_MAP = {
	["Head"] = "HeadColor3",
	["Torso"] = "TorsoColor3",
	["UpperTorso"] = "TorsoColor3",
	["LowerTorso"] = "TorsoColor3",
	["Left Arm"] = "LeftArmColor3",
	["LeftUpperArm"] = "LeftArmColor3",
	["LeftLowerArm"] = "LeftArmColor3",
	["LeftHand"] = "LeftArmColor3",
	["Right Arm"] = "RightArmColor3",
	["RightUpperArm"] = "RightArmColor3",
	["RightLowerArm"] = "RightArmColor3",
	["RightHand"] = "RightArmColor3",
	["Left Leg"] = "LeftLegColor3",
	["LeftUpperLeg"] = "LeftLegColor3",
	["LeftLowerLeg"] = "LeftLegColor3",
	["LeftFoot"] = "LeftLegColor3",
	["Right Leg"] = "RightLegColor3",
	["RightUpperLeg"] = "RightLegColor3",
	["RightLowerLeg"] = "RightLegColor3",
	["RightFoot"] = "RightLegColor3",
}
local ANIM_MAP = {
	{ "idle", "Animation1", "IdleAnimation" },
	{ "idle", "Animation2", "IdleAnimation" },
	{ "walk", "WalkAnim", "WalkAnimation" },
	{ "run", "RunAnim", "RunAnimation" },
	{ "jump", "JumpAnim", "JumpAnimation" },
	{ "fall", "FallAnim", "FallAnimation" },
	{ "climb", "ClimbAnim", "ClimbAnimation" },
	{ "swim", "Swim", "SwimAnimation" },
}
local GUARD_SECONDS = 6
local GUARD_INTERVAL = 0.35
local MAX_REPAIRS = 3
local USE_APPLY_DESCRIPTION_R6 = false
local DEATH_WINDOW = 8
local MAX_DEATH_STRIKES = 2
local DESCRIPTION_TIMEOUT = 20
local R6_SKIN_FALLBACK = true
local MORPH_TIME = 0.55
local HEIGHT_TIME = 0.8
local HEIGHT_EPSILON = 0.02
local HIP_FOLLOW_RATE = 10

local function clamp01(x)
	return math.clamp(x, 0, 1)
end

local function easeInOut(t)
	t = clamp01(t)
	return 0.5 - 0.5 * math.cos(math.pi * t)
end

local function disconnectAll()
	for _, connection in ipairs(connections) do
		if connection and connection.Connected then
			connection:Disconnect()
		end
	end
	table.clear(connections)
end

local function callMethod(object, names, ...)
	local args = table.pack(...)
	for _, name in ipairs(names) do
		local ok, result = pcall(function()
			return object[name](object, table.unpack(args, 1, args.n))
		end)
		if ok and result ~= nil then
			return result
		end
	end
	return nil
end

local function trim(text)
	return (text:match("^%s*(.-)%s*$")) or ""
end
local R15_NAMES = { "UpperTorso", "LowerTorso", "LeftUpperArm", "RightUpperArm", "LeftUpperLeg", "RightUpperLeg" }
local R6_NAMES = { "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg" }

local function isInsideAccessoryOrTool(inst)
	return inst:FindFirstAncestorWhichIsA("Accessory") ~= nil
		or inst:FindFirstAncestorWhichIsA("Tool") ~= nil
end

local function collectBodyNames(character)
	local names = {}
	for _, d in ipairs(character:GetDescendants()) do
		if d:IsA("BasePart") and not isInsideAccessoryOrTool(d) then
			names[d.Name] = true
		end
	end
	return names
end

local function getRigType(character, humanoid)
	local root = character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		for _, d in ipairs(character:GetDescendants()) do
			if d:IsA("Motor6D") then
				local other
				if d.Part0 == root then
					other = d.Part1
				elseif d.Part1 == root then
					other = d.Part0
				end
				if other then
					if other.Name == "LowerTorso" then
						return Enum.HumanoidRigType.R15
					elseif other.Name == "Torso" then
						return Enum.HumanoidRigType.R6
					end
				end
			end
		end
	end
	local names = collectBodyNames(character)
	local r15, r6 = 0, 0
	for _, n in ipairs(R15_NAMES) do
		if names[n] then
			r15 += 1
		end
	end
	for _, n in ipairs(R6_NAMES) do
		if names[n] then
			r6 += 1
		end
	end
	if r15 >= 3 and r6 < 3 then
		return Enum.HumanoidRigType.R15
	end
	if r6 >= 4 and r15 < 3 then
		return Enum.HumanoidRigType.R6
	end
	if r15 > 0 or r6 > 0 then
		local s15, s6 = r15 / #R15_NAMES, r6 / #R6_NAMES
		if s15 ~= s6 then
			return (s15 > s6) and Enum.HumanoidRigType.R15 or Enum.HumanoidRigType.R6
		end
	end
	return humanoid.RigType
end

local function getUserId(username)
	username = trim(username)
	if #username < 1 or #username > 20 or not username:match("^[%w_]+$") then
		return nil
	end
	local targetPlayer = Players:FindFirstChild(username)
	if targetPlayer and targetPlayer:IsA("Player") then
		return targetPlayer.UserId
	end
	local success, userId = pcall(Players.GetUserIdFromNameAsync, Players, username)
	if success then
		return userId
	end
	return nil
end

local function getDescription(userId)
	local cached = descriptionCache[userId]
	if cached and os.clock() - cached.time < 120 then
		return cached.value:Clone()
	end
	local description = callMethod(
		Players,
		{ "GetHumanoidDescriptionFromUserIdAsync", "GetHumanoidDescriptionFromUserId" },
		userId
	)
	if description then
		descriptionCache[userId] = { value = description, time = os.clock() }
		return description:Clone()
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

local SFX_START = "rbxassetid://133636509794555"
local SFX_LOOP = { "rbxassetid://77661010879646", "rbxassetid://112251905264250" }
local SFX_FINISH = "rbxassetid://130507807370367"
local SFX_START_VOLUME = 4
local SFX_LOOP_VOLUME = 7
local SFX_FINISH_VOLUME = 5
local SFX_LOOP_CLIP_TIMEOUT = 10
local sfxLoopToken = 0
local sfxLoopSound = nil

local function newSfx(id, volume)
	local sound = Instance.new("Sound")
	sound.Name = "AFO_Sfx"
	sound.SoundId = id
	sound.Volume = volume
	sound.Parent = SoundService
	return sound
end

local function playSfx(id, volume)
	local sound = newSfx(id, volume)
	sound.Ended:Once(function()
		sound:Destroy()
	end)
	Debris:AddItem(sound, 20)
	sound:Play()
end

local function stopSfxLoop()
	sfxLoopToken += 1
	local sound = sfxLoopSound
	sfxLoopSound = nil
	if sound then
		pcall(function()
			sound:Stop()
			sound:Destroy()
		end)
	end
end

local function startSfxLoop()
	stopSfxLoop()
	local token = sfxLoopToken
	task.spawn(function()
		while token == sfxLoopToken and active do
			local sound = newSfx(SFX_LOOP[math.random(#SFX_LOOP)], SFX_LOOP_VOLUME)
			sfxLoopSound = sound
			local ended = false
			sound.Ended:Once(function()
				ended = true
			end)
			sound:Play()
			local t0 = os.clock()
			while token == sfxLoopToken and not ended do
				local elapsed = os.clock() - t0
				if elapsed > SFX_LOOP_CLIP_TIMEOUT or (elapsed > 2 and not sound.IsPlaying) then
					break
				end
				task.wait(0.05)
			end
			if sfxLoopSound == sound then
				sfxLoopSound = nil
			end
			pcall(function()
				sound:Destroy()
			end)
		end
	end)
end

local function preloadSfx()
	task.spawn(function()
		local list = {}
		for _, id in ipairs({ SFX_START, SFX_LOOP[1], SFX_LOOP[2], SFX_FINISH }) do
			local sound = Instance.new("Sound")
			sound.SoundId = id
			table.insert(list, sound)
		end
		pcall(function()
			ContentProvider:PreloadAsync(list)
		end)
		for _, sound in ipairs(list) do
			sound:Destroy()
		end
	end)
end

local function snapshotHighlights(character)
	local saved = {}
	local function consider(h)
		if h:IsA("Highlight") and h.Name ~= GRAY_NAME then
			saved[h] = {
				Enabled = h.Enabled,
				FillColor = h.FillColor,
				FillTransparency = h.FillTransparency,
				OutlineColor = h.OutlineColor,
				OutlineTransparency = h.OutlineTransparency,
			}
		end
	end
	for _, d in ipairs(character:GetDescendants()) do
		consider(d)
	end
	for _, c in ipairs(workspace:GetChildren()) do
		if c:IsA("Highlight") and c.Adornee == character then
			consider(c)
		end
	end
	return saved
end

local function restoreHighlights(saved)
	for inst, props in pairs(saved) do
		if inst.Parent then
			for key, value in pairs(props) do
				pcall(function()
					inst[key] = value
				end)
			end
		end
	end
end

local function releaseGray(instant)
	stopSfxLoop()
	local g = gray
	if not g then
		return
	end
	gray = nil
	if g.conn then
		g.conn:Disconnect()
	end
	restoreHighlights(g.saved)
	local h = g.highlight
	if not h or not h.Parent then
		return
	end
	if instant then
		h:Destroy()
		return
	end
	local tween = TweenService:Create(h, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		FillTransparency = 1,
		OutlineTransparency = 1,
	})
	tween:Play()
	tween.Completed:Once(function()
		h:Destroy()
	end)
end

local function ensureGray(character)
	if gray and gray.character == character and gray.highlight and gray.highlight.Parent then
		return gray
	end
	releaseGray(true)
	local saved = snapshotHighlights(character)
	for inst in pairs(saved) do
		inst.Enabled = false
	end
	local h = Instance.new("Highlight")
	h.Name = GRAY_NAME
	h.Adornee = character
	h.FillColor = GRAY_A
	h.OutlineColor = Color3.new(1, 1, 1)
	h.FillTransparency = 1
	h.OutlineTransparency = 1
	h.DepthMode = Enum.HighlightDepthMode.Occluded
	h.Parent = character
	local g = { highlight = h, saved = saved, character = character, boost = 0 }
	local t0 = os.clock()
	g.conn = RunService.Heartbeat:Connect(function()
		if not h.Parent then
			return
		end
		local wave = (math.sin((os.clock() - t0) * 5) + 1) / 2
		h.FillColor = GRAY_A:Lerp(GRAY_B, wave * (0.35 + g.boost * 0.65))
	end)
	gray = g
	TweenService:Create(h, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		FillTransparency = 0,
		OutlineTransparency = 0,
	}):Play()
	return g
end

local function retargetGray(target)
	local g = gray
	if g and g.highlight and g.highlight.Parent then
		pcall(function()
			g.highlight.Adornee = target
		end)
	end
end

local function runPhase(duration, step, id, isValid)
	local t0 = os.clock()
	while true do
		if id ~= requestId or not active or (isValid and not isValid()) then
			return false
		end
		local t = os.clock() - t0
		step(math.min(t / duration, 1))
		if t >= duration then
			return true
		end
		RunService.Heartbeat:Wait()
	end
end
local HIDE_STEP = "AFO_HideCharacter"
local fovBase = nil
local visualOwner = nil
local hideState = nil
local ghostState = nil
local retiredGhosts = {}
local ghostGroup = nil
local STRIP_CLASSES = {
	"BaseScript",
	"ModuleScript",
	"Sound",
	"ForceField",
	"Tool",
	"Highlight",
	"BillboardGui",
	"ProximityPrompt",
	"ParticleEmitter",
	"Trail",
	"Beam",
	"Fire",
	"Smoke",
	"Sparkles",
	"Light",
}
local FX_CLASSES = { "ParticleEmitter", "Trail", "Beam", "Fire", "Smoke", "Sparkles", "Light" }

local function isFxInstance(inst)
	for _, className in ipairs(FX_CLASSES) do
		if inst:IsA(className) then
			return true
		end
	end
	return false
end

local function isFirstPerson()
	local camera = workspace.CurrentCamera
	if not camera then
		return false
	end
	return (camera.Focus.Position - camera.CFrame.Position).Magnitude < 1
end

local function trackHiddenPart(state, d)
	if not d:IsA("BasePart") or state.partSet[d] then
		return
	end
	local parent = d.Parent
	if parent and parent:IsA("Tool") then
		return
	end
	state.partSet[d] = true
	table.insert(state.parts, d)
end

local function hideStep()
	local state = hideState
	if not state then
		return
	end
	local character = state.character
	if not character or not character.Parent then
		return
	end
	local parts = state.parts
	local i = 1
	while i <= #parts do
		local p = parts[i]
		if p.Parent == nil then
			state.partSet[p] = nil
			parts[i] = parts[#parts]
			parts[#parts] = nil
		else
			if p.LocalTransparencyModifier ~= 1 then
				p.LocalTransparencyModifier = 1
			end
			i += 1
		end
	end
end

local function restoreValue(state, d, firstPerson)
	local v = state.initial[d]
	if v == nil then
		v = state.baseLTM
	end
	if firstPerson and v < 0.99 then
		v = 1
	end
	return v
end

local function ensureVisible(character, initial)
	if not character or not character.Parent then
		return
	end
	if hideState and hideState.character == character then
		return
	end
	if isFirstPerson() then
		return
	end
	for _, d in ipairs(character:GetDescendants()) do
		if d:IsA("BasePart") and d.LocalTransparencyModifier >= 0.99 then
			local wasHidden = initial ~= nil and initial[d] ~= nil and initial[d] >= 0.99
			if not wasHidden
				and (BODY_COLOR_MAP[d.Name] ~= nil or d:FindFirstAncestorWhichIsA("Accessory") ~= nil) then
				d.LocalTransparencyModifier = 0
			end
		end
	end
end

local function showCharacter()
	pcall(function()
		RunService:UnbindFromRenderStep(HIDE_STEP)
	end)
	local state = hideState
	hideState = nil
	if not state then
		return
	end
	for _, c in ipairs(state.conns) do
		pcall(function()
			c:Disconnect()
		end)
	end
	local target = state.character
	if target and target.Parent then
		local firstPerson = isFirstPerson()
		for _, d in ipairs(target:GetDescendants()) do
			if d:IsA("BasePart") then
				local parent = d.Parent
				if not (parent and parent:IsA("Tool")) then
					d.LocalTransparencyModifier = restoreValue(state, d, firstPerson)
				end
			end
		end
		if state.baseLTM < 0.5 then
			for _, delayTime in ipairs({ 0.05, 0.4, 1.2 }) do
				task.delay(delayTime, function()
					ensureVisible(target, state.initial)
				end)
			end
		end
	end
end

local function hideCharacter(character)
	showCharacter()
	local state = {
		character = character,
		parts = {},
		partSet = {},
		initial = setmetatable({}, { __mode = "k" }),
		conns = {},
		baseLTM = 0,
	}
	local first
	for _, d in ipairs(character:GetDescendants()) do
		if d:IsA("BasePart") then
			state.initial[d] = d.LocalTransparencyModifier
			if d.Name == "Head" and not isInsideAccessoryOrTool(d) then
				state.baseLTM = d.LocalTransparencyModifier
				first = true
			elseif not first and d.Name ~= "HumanoidRootPart" and state.baseLTM == 0 then
				state.baseLTM = d.LocalTransparencyModifier
			end
			trackHiddenPart(state, d)
		end
	end
	table.insert(state.conns, character.DescendantAdded:Connect(function(d)
		if hideState == state then
			trackHiddenPart(state, d)
		end
	end))
	hideState = state
	hideStep()
	pcall(function()
		RunService:BindToRenderStep(HIDE_STEP, Enum.RenderPriority.Last.Value, hideStep)
	end)
end

local function destroyGhost()
	local g = ghostState
	ghostState = nil
	if g and g.model then
		pcall(function()
			g.model:Destroy()
		end)
	end
	for _, r in ipairs(retiredGhosts) do
		pcall(function()
			r.model:Destroy()
		end)
	end
	table.clear(retiredGhosts)
	if ghostGroup then
		local group = ghostGroup
		ghostGroup = nil
		pcall(function()
			group:Destroy()
		end)
	end
end

local function getGhostGroup()
	if ghostGroup and ghostGroup.Parent then
		return ghostGroup
	end
	local group = Instance.new("Model")
	group.Name = "AFO_GhostGroup"
	group.Parent = workspace.CurrentCamera or workspace
	ghostGroup = group
	return group
end

local function clearTransformVisuals()
	visualOwner = nil
	destroyGhost()
	showCharacter()
end

local function relPath(inst, root)
	local names = {}
	local cur = inst
	while cur and cur ~= root do
		table.insert(names, 1, cur.Name)
		cur = cur.Parent
	end
	return table.concat(names, "/")
end

local function verticalExtent(cf, size)
	return (math.abs(cf.RightVector.Y) * size.X + math.abs(cf.UpVector.Y) * size.Y + math.abs(cf.LookVector.Y) * size.Z) / 2
end

local function computePoses(model)
	local poses = {}
	local root = model:FindFirstChild("HumanoidRootPart")
	if not root then
		return poses
	end
	poses[root] = CFrame.new()
	local motors = {}
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("Motor6D") and d.Part0 and d.Part1 then
			table.insert(motors, d)
		end
	end
	local progress = true
	while progress do
		progress = false
		for _, motor in ipairs(motors) do
			if poses[motor.Part0] and not poses[motor.Part1] then
				poses[motor.Part1] = poses[motor.Part0] * motor.C0 * motor.C1:Inverse()
				progress = true
			end
		end
	end
	return poses
end

local function makeGhost(character, root, humanoid, followHip, keepOld)
	if keepOld and ghostState then
		table.insert(retiredGhosts, ghostState)
		ghostState = nil
	else
		destroyGhost()
	end
	local state = hideState and hideState.character == character and hideState or nil
	local hiddenPaths = {}
	for _, d in ipairs(character:GetDescendants()) do
		if d:IsA("BasePart") then
			local ltm
			if state then
				ltm = state.initial[d] or 0
			else
				ltm = d.LocalTransparencyModifier
			end
			if ltm >= 0.95 then
				hiddenPaths[relPath(d, character)] = true
			end
		end
	end
	local clone
	local previous = character.Archivable
	pcall(function()
		character.Archivable = true
	end)
	local okClone = pcall(function()
		clone = character:Clone()
	end)
	pcall(function()
		character.Archivable = previous
	end)
	if not okClone or not clone then
		return nil
	end
	for _, d in ipairs(clone:GetDescendants()) do
		for _, className in ipairs(STRIP_CLASSES) do
			if d:IsA(className) then
				d:Destroy()
				break
			end
		end
	end
	local gRoot = clone:FindFirstChild("HumanoidRootPart")
	if not gRoot or not gRoot:IsA("BasePart") then
		clone:Destroy()
		return nil
	end
	for _, d in ipairs(clone:GetDescendants()) do
		if d:IsA("Humanoid") or d:IsA("Animator") then
			d:Destroy()
		end
	end
	local rootCF = gRoot.CFrame
	local items = {}
	local itemOf = {}
	for _, d in ipairs(clone:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanTouch = false
			d.CanQuery = false
			d.Massless = true
			d.LocalTransparencyModifier = 0
			if hiddenPaths[relPath(d, clone)] then
				d.Transparency = 1
			end
			if d ~= gRoot then
				local rel = rootCF:ToObjectSpace(d.CFrame)
				local item = {
					part = d,
					key = relPath(d, clone),
					orig = d.Size,
					pos = rel.Position,
					rot = rel - rel.Position,
					meshes = {},
					decals = {},
					baseT = d.Transparency,
					seed = math.random() * 6.28,
				}
				for _, child in ipairs(d:GetChildren()) do
					if child:IsA("SpecialMesh") and child.MeshType == Enum.MeshType.FileMesh then
						table.insert(item.meshes, { mesh = child, orig = child.Scale })
					elseif child:IsA("Decal") or child:IsA("Texture") then
						table.insert(item.decals, { inst = child, orig = child.Transparency })
					end
				end
				table.insert(items, item)
				itemOf[d] = item
			end
		end
	end
	local poses = computePoses(clone)
	local restLow, restHigh
	for _, item in ipairs(items) do
		local part = item.part
		local pose = poses[part]
		if pose and part.Transparency < 0.95 and not isInsideAccessoryOrTool(part) then
			local e = verticalExtent(pose, item.orig)
			local low, high = pose.Position.Y - e, pose.Position.Y + e
			restLow = restLow and math.min(restLow, low) or low
			restHigh = restHigh and math.max(restHigh, high) or high
		end
	end
	for _, d in ipairs(clone:GetDescendants()) do
		if d:IsA("JointInstance") or d:IsA("WeldConstraint") or d:IsA("Constraint") then
			d:Destroy()
		end
	end
	local bodyLow, bodyHigh, anyLow
	for _, item in ipairs(items) do
		if item.part.Transparency < 0.95 then
			local e = verticalExtent(item.rot, item.orig)
			local low, high = item.pos.Y - e, item.pos.Y + e
			anyLow = anyLow and math.min(anyLow, low) or low
			if not isInsideAccessoryOrTool(item.part) then
				bodyLow = bodyLow and math.min(bodyLow, low) or low
				bodyHigh = bodyHigh and math.max(bodyHigh, high) or high
			end
		end
	end
	local pivotY = bodyLow or anyLow or -3
	do
		local lo = bodyLow or anyLow or -3
		local hi = bodyHigh or (lo + 5)
		local span = math.max(hi - lo, 0.5)
		for _, item in ipairs(items) do
			item.stagger = clamp01((item.pos.Y - lo) / span)
		end
	end
	local height
	if restLow and restHigh then
		height = restHigh - restLow
	elseif bodyLow and bodyHigh then
		height = bodyHigh - bodyLow
	end
	clone.Name = "AFO_Ghost"
	clone.Parent = getGhostGroup()
	local hipTotal = humanoid.HipHeight + root.Size.Y / 2
	local g = {
		model = clone,
		items = items,
		pivot = Vector3.new(0, pivotY, 0),
		height = height,
		followHip = followHip,
		total0 = hipTotal,
		total = hipTotal,
		lastT = os.clock(),
	}
	ghostState = g
	return g
end

local function ghostBase(g, root, humanoid)
	if not g.followHip then
		return root.CFrame
	end
	local now = os.clock()
	local dt = math.min(now - g.lastT, 0.1)
	g.lastT = now
	local target = humanoid.HipHeight + root.Size.Y / 2
	g.total += (target - g.total) * (1 - math.exp(-dt * HIP_FOLLOW_RATE))
	return root.CFrame - Vector3.new(0, g.total - g.total0, 0)
end

local function poseGhostItem(g, item, k, sizeMul, followCF, relCF)
	local part = item.part
	if not part or not part.Parent then
		return
	end
	if item.lastMul ~= sizeMul then
		item.lastMul = sizeMul
		part.Size = item.orig * sizeMul
		for _, entry in ipairs(item.meshes) do
			if entry.mesh.Parent then
				entry.mesh.Scale = entry.orig * sizeMul
			end
		end
	end
	if relCF then
		part.CFrame = followCF * relCF
		return
	end
	local pivot = g.pivot
	part.CFrame = followCF * (CFrame.new(pivot + (item.pos - pivot) * k) * item.rot)
end

local function poseGhost(g, root, humanoid, k, wobble, phase)
	local followCF = ghostBase(g, root, humanoid)
	for _, item in ipairs(g.items) do
		local w = math.sin(phase + item.seed) * 0.03 * wobble
		poseGhostItem(g, item, k, Vector3.new(k * (1 + w), k, k * (1 + w)), followCF)
	end
end

local function animateGhost(g, root, humanoid, k0, k1, duration, id, isValid)
	return runPhase(duration, function(alpha)
		local k = k0 + (k1 - k0) * easeInOut(alpha)
		poseGhost(g, root, humanoid, k, math.sin(alpha * math.pi), alpha * 9)
	end, id, isValid)
end

local MORPH_DURATION = 1.25
local MORPH_HOLD_MIN = 0.55
local MORPH_STAGGER = 0.3
local MORPH_WOBBLE = 0.03
local MIN_SCALE = 0.03

local function smoothstep(t)
	t = clamp01(t)
	return t * t * (3 - 2 * t)
end

local function lerpNum(a, b, t)
	return a + (b - a) * t
end

local function holdGhost(g, root, humanoid)
	local base = ghostBase(g, root, humanoid)
	local now = os.clock()
	local shake = Vector3.new(math.sin(now * 53), math.sin(now * 47 + 1.3), math.sin(now * 61 + 2.1)) * 0.035
	for _, item in ipairs(g.items) do
		local part = item.part
		if part and part.Parent then
			part.CFrame = base * CFrame.new(item.pos + shake) * item.rot
		end
	end
end

local function pairByKey(oldGhost, newGhost)
	local byKey = {}
	for _, item in ipairs(oldGhost.items) do
		item.twin = nil
		if item.key and not byKey[item.key] then
			byKey[item.key] = item
		end
	end
	for _, item in ipairs(newGhost.items) do
		item.twin = nil
		local old = item.key and byKey[item.key]
		if old then
			byKey[item.key] = nil
			item.twin = old
			old.twin = item
		end
	end
end

local function setItemLook(item, size, visible)
	local part = item.part
	if not part or not part.Parent then
		return
	end
	local o = item.orig
	part.Size = Vector3.new(math.max(size.X, 0.02), math.max(size.Y, 0.02), math.max(size.Z, 0.02))
	if #item.meshes > 0 then
		local rx = size.X / math.max(o.X, 0.001)
		local ry = size.Y / math.max(o.Y, 0.001)
		local rz = size.Z / math.max(o.Z, 0.001)
		for _, entry in ipairs(item.meshes) do
			if entry.mesh.Parent then
				entry.mesh.Scale = Vector3.new(entry.orig.X * rx, entry.orig.Y * ry, entry.orig.Z * rz)
			end
		end
	end
	part.Transparency = 1 - (1 - item.baseT) * visible
	for _, d in ipairs(item.decals) do
		if d.inst.Parent then
			d.inst.Transparency = 1 - (1 - d.orig) * visible
		end
	end
end

local function morphGhosts(oldG, newG, root, humanoid, duration, id, isValid)
	return runPhase(duration, function(alpha)
		local baseOld = ghostBase(oldG, root, humanoid)
		local baseNew = ghostBase(newG, root, humanoid)
		local now = os.clock()
		local wobbleAmp = MORPH_WOBBLE * math.sin(alpha * math.pi)
		local function localAlpha(item)
			return clamp01(alpha * (1 + MORPH_STAGGER) - (item.stagger or 0) * MORPH_STAGGER)
		end
		for _, item in ipairs(newG.items) do
			local a = localAlpha(item)
			local e = smoothstep(a)
			local w = math.sin(now * 11 + (item.stagger or 0) * 6 + item.seed) * wobbleAmp
			local wob = Vector3.new(1 + w, 1 - w * 0.8, 1 + w)
			local cfNew = baseNew * CFrame.new(item.pos) * item.rot
			local twin = item.twin
			if twin then
				local cfOld = baseOld * CFrame.new(twin.pos) * twin.rot
				local cf = cfOld:Lerp(cfNew, e)
				local size = twin.orig:Lerp(item.orig, e) * wob
				item.part.CFrame = cf
				twin.part.CFrame = cf
				setItemLook(item, size, smoothstep(a / 0.55))
				setItemLook(twin, size, 1 - smoothstep((a - 0.3) / 0.6))
			else
				item.part.CFrame = cfNew
				setItemLook(item, item.orig * lerpNum(MIN_SCALE, 1, e), smoothstep(a / 0.7))
			end
		end
		for _, item in ipairs(oldG.items) do
			if not item.twin then
				local a = localAlpha(item)
				local e = smoothstep(a)
				item.part.CFrame = baseOld * CFrame.new(item.pos) * item.rot
				setItemLook(item, item.orig * lerpNum(1, MIN_SCALE, e), 1 - smoothstep(a / 0.8))
			end
		end
	end, id, isValid)
end

local function waitTransformFree(currentRequest)
	local waited = 0
	while transforming and waited < 3 do
		if currentRequest ~= requestId then
			return false
		end
		task.wait(0.05)
		waited += 0.05
	end
	return currentRequest == requestId
end

local function findPart(character, name)
	local direct = character:FindFirstChild(name)
	if direct and direct:IsA("BasePart") then
		return direct
	end
	for _, d in ipairs(character:GetDescendants()) do
		if d.Name == name and d:IsA("BasePart") and not isInsideAccessoryOrTool(d) then
			return d
		end
	end
	return nil
end

local function sanitizeAccessories(character)
	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("BasePart") and child:GetAttribute("AFOSkin") then
			child.CanCollide = false
			child.CanTouch = false
			child.Massless = true
		end
		if child:IsA("Accessory") then
			for _, d in ipairs(child:GetDescendants()) do
				if d:IsA("BasePart") then
					d.CanCollide = false
					d.CanTouch = false
					d.Massless = true
				end
			end
			local handle = child:FindFirstChild("Handle")
			if handle and handle:IsA("BasePart") then
				handle.CanCollide = false
				handle.CanTouch = false
				handle.Massless = true
			end
		end
	end
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
			and descendant.Parent:IsA("BasePart")
			and not isInsideAccessoryOrTool(descendant.Parent) then
			return descendant
		end
	end
	return nil
end

local function prepareHandle(handle)
	handle.Anchored = false
	handle.CanCollide = false
	handle.CanTouch = false
	handle.Massless = true
end

local function isAttached(character, accessory)
	if accessory.Parent ~= character then
		return false
	end
	local handle = accessory:FindFirstChild("Handle")
	if not handle or not handle:IsA("BasePart") then
		return false
	end
	for _, d in ipairs(handle:GetChildren()) do
		if d:IsA("JointInstance") or d:IsA("WeldConstraint") then
			local other = (d.Part0 == handle) and d.Part1 or d.Part0
			if other
				and other ~= handle
				and other:IsDescendantOf(character)
				and not other:FindFirstAncestorWhichIsA("Accessory") then
				return true
			end
		end
	end
	return false
end

local function getWeldInfo(template)
	local handle = template:FindFirstChild("Handle")
	local weld = handle and handle:FindFirstChild("AccessoryWeld")
	if weld and weld:IsA("JointInstance") and weld.Part0 and weld.Part1 then
		if weld.Part0 == handle then
			return { partName = weld.Part1.Name, c0 = weld.C0, c1 = weld.C1 }
		else
			return { partName = weld.Part0.Name, c0 = weld.C1, c1 = weld.C0 }
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
	local characterAttachment = findCharacterAttachment(character, handleAttachment.Name)
	if not characterAttachment then
		return false
	end
	accessory.Parent = character
	prepareHandle(handle)
	handle.CFrame = characterAttachment.Parent.CFrame
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

local function guessPartForAttachment(character, attName)
	local n = attName or ""
	if n:find("Hat") or n:find("Hair") or n:find("Face") then
		return findPart(character, "Head")
	end
	return findPart(character, "Torso")
end

local function fallbackWeld(character, accessory, handle, info)
	local handleAttachment = findHandleAttachment(handle)
	local part, c0, c1
	if info then
		part = findPart(character, info.partName)
		if part then
			c0, c1 = info.c0, info.c1
		end
	end
	if not part then
		part = guessPartForAttachment(character, handleAttachment and handleAttachment.Name)
			or character:FindFirstChild("HumanoidRootPart")
		if not part or not part:IsA("BasePart") then
			return false
		end
		local onHead = part.Name == "Head"
		if handleAttachment then
			c0 = handleAttachment.CFrame
			c1 = onHead and CFrame.new(0, part.Size.Y / 2, 0) or CFrame.identity
		else
			local okPoint, point = pcall(function()
				return accessory.AttachmentPoint
			end)
			c0 = okPoint and point or CFrame.identity
			c1 = CFrame.new(0, part.Size.Y / 2, 0)
		end
	end
	accessory.Parent = character
	prepareHandle(handle)
	handle.CFrame = part.CFrame * c1 * c0:Inverse()
	local oldWeld = handle:FindFirstChild("AccessoryWeld")
	if oldWeld then
		oldWeld:Destroy()
	end
	local weld = Instance.new("Weld")
	weld.Name = "AccessoryWeld"
	weld.Part0 = handle
	weld.Part1 = part
	weld.C0 = c0
	weld.C1 = c1
	weld.Parent = handle
	return true
end

local function attachAccessory(character, humanoid, template, info)
	local accessory = template:Clone()
	local handle = accessory:FindFirstChild("Handle")
	if not handle or not handle:IsA("BasePart") then
		accessory:Destroy()
		return nil
	end
	info = info or getWeldInfo(template)
	local stale = handle:FindFirstChild("AccessoryWeld")
	if stale then
		stale:Destroy()
	end
	handle.Anchored = false
	pcall(function()
		humanoid:AddAccessory(accessory)
	end)
	if accessory.Parent ~= character then
		accessory.Parent = character
	end
	if isAttached(character, accessory) then
		prepareHandle(handle)
		return accessory
	end
	pcall(manualAttachAccessory, accessory, character)
	if isAttached(character, accessory) then
		prepareHandle(handle)
		return accessory
	end
	local okFallback = pcall(fallbackWeld, character, accessory, handle, info)
	if okFallback and isAttached(character, accessory) then
		return accessory
	end
	accessory:Destroy()
	return nil
end

local function guardAccessories(character, humanoid, records, id)
	if not records or #records == 0 then
		return
	end
	task.spawn(function()
		local elapsed = 0
		while elapsed < GUARD_SECONDS do
			task.wait(GUARD_INTERVAL)
			elapsed += GUARD_INTERVAL
			if id ~= requestId or not character.Parent or humanoid.Health <= 0 then
				return
			end
			for _, rec in ipairs(records) do
				local acc = rec.accessory
				if not (acc and isAttached(character, acc)) and (rec.repairs or 0) < MAX_REPAIRS then
					rec.repairs = (rec.repairs or 0) + 1
					if acc then
						pcall(function()
							acc:Destroy()
						end)
					end
					rec.accessory = attachAccessory(character, humanoid, rec.backup, rec.info)
				end
			end
		end
	end)
end

local function fxSignature(root, inst)
	return relPath(inst, root) .. "|" .. inst.ClassName
end

local function repairAccessoryFx(character, donor)
	if not donor or not character or not character.Parent then
		return
	end
	local pool = {}
	for _, acc in ipairs(character:GetChildren()) do
		if acc:IsA("Accessory") then
			pool[acc.Name] = pool[acc.Name] or {}
			table.insert(pool[acc.Name], acc)
		end
	end
	for _, template in ipairs(donor:GetChildren()) do
		if template:IsA("Accessory") then
			local templateFx = {}
			for _, d in ipairs(template:GetDescendants()) do
				if isFxInstance(d) then
					table.insert(templateFx, d)
				end
			end
			if #templateFx > 0 then
				local list = pool[template.Name]
				local mine = list and table.remove(list, 1)
				if mine and mine.Parent == character then
					local present = {}
					for _, d in ipairs(mine:GetDescendants()) do
						if isFxInstance(d) then
							local sig = fxSignature(mine, d)
							present[sig] = (present[sig] or 0) + 1
						end
					end
					for _, fx in ipairs(templateFx) do
						local sig = fxSignature(template, fx)
						if present[sig] and present[sig] > 0 then
							present[sig] -= 1
						else
							local parentTemplate = fx.Parent
							local parentMine = mine
							if parentTemplate ~= template then
								for part in string.gmatch(relPath(parentTemplate, template), "[^/]+") do
									parentMine = parentMine and parentMine:FindFirstChild(part)
								end
							end
							if parentMine then
								pcall(function()
									fx:Clone().Parent = parentMine
								end)
							end
						end
					end
				end
			end
		end
	end
end

local function isLayeredAccessory(accessory)
	local handle = accessory:FindFirstChild("Handle")
	return handle ~= nil and handle:FindFirstChildWhichIsA("WrapLayer", true) ~= nil
end

local function applyManualBodyColors(character, bodyColors)
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") and not isInsideAccessoryOrTool(part) then
			local propertyName = BODY_COLOR_MAP[part.Name]
			if propertyName then
				part.Color = bodyColors[propertyName]
			end
		end
	end
end

local function gameHidesRig(snap)
	local hidden = 0
	for name, transparency in pairs(snap) do
		if name ~= "Head" and BODY_COLOR_MAP[name] and transparency >= 0.95 then
			hidden += 1
		end
	end
	return hidden >= 3
end

local function removeSkin(character)
	for _, child in ipairs(character:GetChildren()) do
		if child:GetAttribute("AFOSkin") then
			child:Destroy()
		end
	end
	for _, p in ipairs(character:GetChildren()) do
		if p:IsA("BasePart") then
			local orig = p:GetAttribute("AFO_OrigTransparency")
			if orig ~= nil then
				p.Transparency = orig
				p:SetAttribute("AFO_OrigTransparency", nil)
			end
			if p:GetAttribute("AFO_Skinned") then
				p:SetAttribute("AFO_Skinned", nil)
			end
		end
	end
end

local function wipeAppearance(character)
	removeSkin(character)
	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("Accessory")
			or child:IsA("Clothing")
			or child:IsA("ShirtGraphic")
			or child:IsA("CharacterMesh")
			or child:IsA("BodyColors") then
			child:Destroy()
		end
	end
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") and BODY_COLOR_MAP[part.Name] and not isInsideAccessoryOrTool(part) then
			local isHead = part.Name == "Head"
			for _, sub in ipairs(part:GetChildren()) do
				if sub:IsA("SurfaceAppearance") then
					sub:Destroy()
				elseif isHead and (sub:IsA("Decal") or sub:IsA("DataModelMesh") or sub:IsA("FaceControls")) then
					sub:Destroy()
				end
			end
		end
	end
end
local APPEARANCE_CLASSES = {
	"BodyPartDescription",
	"Decal",
	"Texture",
	"SurfaceAppearance",
	"FaceControls",
	"WrapTarget",
	"WrapLayer",
	"DataModelMesh",
	"Bone",
}

local function isAppearanceChild(inst)
	if inst.Name == "OriginalSize" or inst.Name == "AvatarPartScaleType" then
		return true
	end
	for _, className in ipairs(APPEARANCE_CLASSES) do
		if inst:IsA(className) then
			return true
		end
	end
	return false
end

local function replaceBodyPart(character, oldPart, donorPart)
	local newPart = donorPart:Clone()
	for _, child in ipairs(newPart:GetChildren()) do
		if child:IsA("Motor6D") or child:IsA("Weld") then
			child:Destroy()
		end
	end
	newPart.CFrame = oldPart.CFrame
	newPart.Anchored = oldPart.Anchored
	newPart.CanCollide = oldPart.CanCollide
	newPart.CanTouch = oldPart.CanTouch
	newPart.CanQuery = oldPart.CanQuery
	newPart.Massless = oldPart.Massless
	newPart.Transparency = oldPart.Transparency
	newPart.LocalTransparencyModifier = oldPart.LocalTransparencyModifier
	if hideState and hideState.initial[oldPart] ~= nil then
		hideState.initial[newPart] = hideState.initial[oldPart]
	end
	newPart.Parent = oldPart.Parent or character
	for _, d in ipairs(character:GetDescendants()) do
		if d:IsA("JointInstance") or d:IsA("WeldConstraint") then
			if d.Part0 == oldPart then
				d.Part0 = newPart
			end
			if d.Part1 == oldPart then
				d.Part1 = newPart
			end
		end
	end
	for _, child in ipairs(oldPart:GetChildren()) do
		if not isAppearanceChild(child) then
			local clash = child:IsA("Attachment") and newPart:FindFirstChild(child.Name)
			if not clash then
				child.Parent = newPart
			end
		end
	end
	oldPart:Destroy()
	return newPart
end

local function hasFaceDecal(head)
	for _, c in ipairs(head:GetChildren()) do
		if c:IsA("Decal") and c.Texture ~= "" then
			return true
		end
	end
	return false
end

local function isDynamicHead(head)
	return head:FindFirstChildWhichIsA("FaceControls") ~= nil
		or head:FindFirstChildWhichIsA("Bone", true) ~= nil
end

local function newFaceDecal(head, texture)
	local face = Instance.new("Decal")
	face.Name = "face"
	face.Face = Enum.NormalId.Front
	face.Texture = texture
	face.Parent = head
	return face
end

local DEFAULT_FACE_TEXTURE = "rbxasset://textures/face.png"
local faceTextureCache = {}
local faceAssetCache = {}

local function isDefaultFaceTexture(texture)
	return texture == nil or texture == "" or texture:find("textures/face.png", 1, true) ~= nil
end

local function fetchFaceAssetId(userId)
	local cached = faceAssetCache[userId]
	if cached ~= nil then
		return cached or nil
	end
	local found = false
	local ok, info = pcall(function()
		return Players:GetCharacterAppearanceInfoAsync(userId)
	end)
	if ok and type(info) == "table" and type(info.assets) == "table" then
		for _, asset in ipairs(info.assets) do
			local assetType = asset.assetType
			if type(asset.id) == "number"
				and type(assetType) == "table"
				and (assetType.id == 18 or assetType.name == "Face") then
				found = asset.id
				break
			end
		end
	end
	faceAssetCache[userId] = found
	return found or nil
end

local function resolveFaceAsset(assetId)
	if not assetId or assetId == 0 then
		return nil
	end
	local cached = faceTextureCache[assetId]
	if cached then
		return cached
	end
	local texture
	pcall(function()
		local objects = game:GetObjects("rbxassetid://" .. tostring(assetId))
		for _, object in ipairs(objects) do
			if not texture then
				local decal = object:IsA("Decal") and object or object:FindFirstChildWhichIsA("Decal", true)
				if decal and decal.Texture ~= "" then
					texture = decal.Texture
				end
			end
			object:Destroy()
		end
	end)
	texture = texture or ("rbxassetid://" .. tostring(assetId))
	faceTextureCache[assetId] = texture
	return texture
end

local function prefetchFace(userId, description)
	local descriptionFace = description and description.Face
	if descriptionFace and descriptionFace ~= 0 then
		return resolveFaceAsset(descriptionFace)
	end
	return resolveFaceAsset(fetchFaceAssetId(userId))
end

local function currentFaceTexture(head)
	local named = head:FindFirstChild("face")
	if named and named:IsA("Decal") and named.Texture ~= "" then
		return named.Texture
	end
	for _, c in ipairs(head:GetChildren()) do
		if c:IsA("Decal") and c.Texture ~= "" then
			return c.Texture
		end
	end
	return nil
end

local function applyFace(head, sources, gentle)
	if not head or isDynamicHead(head) then
		return
	end
	local current = currentFaceTexture(head)
	if gentle and current and not isDefaultFaceTexture(current) then
		return
	end
	local resolved = sources and sources.resolved
	local original = sources and sources.original
	local final = sources and sources.final
	local order
	if sources and sources.reset then
		order = { original, resolved, final, current }
	else
		order = { final, current, resolved }
	end
	local chosen
	for i = 1, 4 do
		local candidate = order[i]
		if candidate and candidate ~= "" and not isDefaultFaceTexture(candidate) then
			chosen = candidate
			break
		end
	end
	if not chosen then
		for i = 1, 4 do
			local candidate = order[i]
			if candidate and candidate ~= "" then
				chosen = candidate
				break
			end
		end
	end
	chosen = chosen or DEFAULT_FACE_TEXTURE
	if sources and not isDefaultFaceTexture(chosen) then
		sources.final = chosen
	end
	local kept = false
	for _, c in ipairs(head:GetChildren()) do
		if c:IsA("Decal") then
			if not kept and c.Texture == chosen then
				kept = true
			else
				c:Destroy()
			end
		end
	end
	if not kept then
		newFaceDecal(head, chosen)
	end
end

local function scheduleFaceChecks(character, sources, token)
	sources.swapped = true
	for _, delayTime in ipairs({ 0.25, 0.7, 1.4, 2.5, 4.5 }) do
		task.delay(delayTime, function()
			if requestId ~= token or not character.Parent then
				return
			end
			local head = findPart(character, "Head")
			if head and head:IsA("BasePart") then
				applyFace(head, sources, true)
			end
			local skinHead = character:FindFirstChild("AFO_Skin_Head")
			if skinHead and skinHead:IsA("BasePart") then
				applyFace(skinHead, sources, true)
			end
		end)
	end
end

local R6_GROUPS = {
	{ name = "Head", bodyPart = Enum.BodyPart.Head, descKey = "Head", skin = { "Head" } },
	{ name = "Torso", bodyPart = Enum.BodyPart.Torso, descKey = "Torso", skin = { "UpperTorso", "LowerTorso" } },
	{ name = "Left Arm", bodyPart = Enum.BodyPart.LeftArm, descKey = "LeftArm", skin = { "LeftUpperArm", "LeftLowerArm", "LeftHand" } },
	{ name = "Right Arm", bodyPart = Enum.BodyPart.RightArm, descKey = "RightArm", skin = { "RightUpperArm", "RightLowerArm", "RightHand" } },
	{ name = "Left Leg", bodyPart = Enum.BodyPart.LeftLeg, descKey = "LeftLeg", skin = { "LeftUpperLeg", "LeftLowerLeg", "LeftFoot" }, bottom = true },
	{ name = "Right Leg", bodyPart = Enum.BodyPart.RightLeg, descKey = "RightLeg", skin = { "RightUpperLeg", "RightLowerLeg", "RightFoot" }, bottom = true },
}

local function hasAdvancedProportions(description)
	if not description then
		return false
	end
	for _, key in ipairs({ "BodyTypeScale", "ProportionScale" }) do
		local ok, value = pcall(function()
			return description[key]
		end)
		if ok and type(value) == "number" and value > 0.001 then
			return true
		end
	end
	return false
end

local function hasCustomBody(description)
	if not description then
		return false
	end
	if hasAdvancedProportions(description) then
		return true
	end
	for _, group in ipairs(R6_GROUPS) do
		local ok, value = pcall(function()
			return description[group.descKey]
		end)
		if ok and type(value) == "number" and value ~= 0 then
			return true
		end
	end
	return false
end

local function donorHasNative(donor, bodyPart)
	for _, c in ipairs(donor:GetChildren()) do
		if c:IsA("CharacterMesh") and c.BodyPart == bodyPart then
			local okMesh, meshId = pcall(function()
				return c.MeshId
			end)
			if okMesh and type(meshId) == "number" and meshId ~= 0 then
				return true
			end
		end
	end
	return false
end
local SKIN_STRIP = { "Motor6D", "Weld", "Attachment", "WrapTarget", "WrapLayer" }

local function applySkinGroup(character, skinDonor, group, poses)
	local target = findPart(character, group.name)
	if not target then
		return false
	end
	local pieces = {}
	local minV, maxV
	for _, r15Name in ipairs(group.skin) do
		local donorPart = skinDonor:FindFirstChild(r15Name)
		local pose = donorPart and poses[donorPart]
		if donorPart and donorPart:IsA("BasePart") and pose then
			local size = donorPart.Size
			local half = Vector3.new(
				(math.abs(pose.RightVector.X) * size.X + math.abs(pose.UpVector.X) * size.Y + math.abs(pose.LookVector.X) * size.Z) / 2,
				(math.abs(pose.RightVector.Y) * size.X + math.abs(pose.UpVector.Y) * size.Y + math.abs(pose.LookVector.Y) * size.Z) / 2,
				(math.abs(pose.RightVector.Z) * size.X + math.abs(pose.UpVector.Z) * size.Y + math.abs(pose.LookVector.Z) * size.Z) / 2
			)
			local low, high = pose.Position - half, pose.Position + half
			if minV then
				minV = Vector3.new(math.min(minV.X, low.X), math.min(minV.Y, low.Y), math.min(minV.Z, low.Z))
				maxV = Vector3.new(math.max(maxV.X, high.X), math.max(maxV.Y, high.Y), math.max(maxV.Z, high.Z))
			else
				minV, maxV = low, high
			end
			table.insert(pieces, { part = donorPart, pose = pose, name = r15Name })
		end
	end
	if #pieces == 0 then
		return false
	end
	if group.requireDeviation then
		local extent = maxV - minV
		local size = target.Size
		local deviates = false
		for _, axis in ipairs({ "X", "Y", "Z" }) do
			local base = math.max(size[axis], 0.05)
			if math.abs(extent[axis] / base - 1) > 0.15 then
				deviates = true
				break
			end
		end
		if not deviates then
			return false
		end
	end
	local anchor = (minV + maxV) / 2
	if group.bottom then
		anchor = Vector3.new(anchor.X, minV.Y + target.Size.Y / 2, anchor.Z)
	end
	for _, piece in ipairs(pieces) do
		local skinPart = piece.part:Clone()
		for _, child in ipairs(skinPart:GetChildren()) do
			for _, className in ipairs(SKIN_STRIP) do
				if child:IsA(className) then
					child:Destroy()
					break
				end
			end
		end
		skinPart.Name = "AFO_Skin_" .. piece.name
		skinPart:SetAttribute("AFOSkin", true)
		skinPart.Anchored = false
		skinPart.CanCollide = false
		skinPart.CanTouch = false
		skinPart.CanQuery = false
		skinPart.Massless = true
		skinPart.LocalTransparencyModifier = 0
		local offset = CFrame.new(piece.pose.Position - anchor) * (piece.pose - piece.pose.Position)
		skinPart.CFrame = target.CFrame * offset
		skinPart.Parent = character
		local weld = Instance.new("Weld")
		weld.Name = "AFOSkinWeld"
		weld.Part0 = target
		weld.Part1 = skinPart
		weld.C0 = offset
		weld.Parent = skinPart
	end
	if target:GetAttribute("AFO_OrigTransparency") == nil then
		target:SetAttribute("AFO_OrigTransparency", target.Transparency)
	end
	target:SetAttribute("AFO_Skinned", true)
	target.Transparency = 1
	return true
end

local function adaptR15ToR6(character, donor, extra)
	local description = extra and extra.description
	local skinDonor = extra and extra.skinDonor
	local r6Part = findPart(character, "Head")
	local donorHead = donor:FindFirstChild("Head")
	if r6Part and donorHead and donorHead:IsA("BasePart") then
		for _, child in ipairs(r6Part:GetChildren()) do
			if child:IsA("Decal") or child:IsA("DataModelMesh") then
				child:Destroy()
			end
		end
		for _, child in ipairs(donorHead:GetChildren()) do
			if child:IsA("Decal") or child:IsA("DataModelMesh") or child:IsA("SpecialMesh") then
				child:Clone().Parent = r6Part
			end
		end
		for _, att in ipairs(donorHead:GetChildren()) do
			if att:IsA("Attachment") and not r6Part:FindFirstChild(att.Name) then
				att:Clone().Parent = r6Part
			end
		end
		if donorHead:IsA("MeshPart") and r6Part:IsA("MeshPart") then
			pcall(function()
				r6Part:ApplyMesh(donorHead)
			end)
			r6Part.TextureID = donorHead.TextureID
		end
	end
	if R6_SKIN_FALLBACK and skinDonor and hasCustomBody(description) then
		local poses = computePoses(skinDonor)
		local advanced = hasAdvancedProportions(description)
		for _, group in ipairs(R6_GROUPS) do
			local ok, id = pcall(function()
				return description[group.descKey]
			end)
			local hasId = ok and type(id) == "number" and id ~= 0
			local native = donorHasNative(donor, group.bodyPart)
			local isLimb = group.name ~= "Head"
			if advanced then
				group.requireDeviation = false
				applySkinGroup(character, skinDonor, group, poses)
			elseif hasId and not native then
				group.requireDeviation = false
				applySkinGroup(character, skinDonor, group, poses)
			elseif hasId and native and isLimb then
				group.requireDeviation = true
				applySkinGroup(character, skinDonor, group, poses)
				group.requireDeviation = false
			end
		end
	end
end

local function applyDonorData(character, humanoid, donor, extra)
	removeSkin(character)
	local keepTransparency = {}
	for _, d in ipairs(character:GetDescendants()) do
		if d:IsA("BasePart") and not isInsideAccessoryOrTool(d) then
			keepTransparency[d.Name] = d.Transparency
		end
	end
	wipeAppearance(character)
	adaptR15ToR6(character, donor, extra)
	local head = findPart(character, "Head")
	if head and not head:GetAttribute("AFO_Skinned") then
		if not head:FindFirstChildOfClass("DataModelMesh") then
			local mesh = Instance.new("SpecialMesh")
			mesh.MeshType = Enum.MeshType.Head
			mesh.Scale = Vector3.new(1.25, 1.25, 1.25)
			mesh.Parent = head
		end
		applyFace(head, extra and extra.faceSources)
	end
	local skinHead = character:FindFirstChild("AFO_Skin_Head")
	if skinHead then
		applyFace(skinHead, extra and extra.faceSources)
	end
	local donorColors = donor:FindFirstChildOfClass("BodyColors")
	if donorColors then
		local newColors = donorColors:Clone()
		newColors.Parent = character
		applyManualBodyColors(character, newColors)
	end
	for _, child in ipairs(donor:GetChildren()) do
		if child:IsA("Shirt") or child:IsA("Pants") or child:IsA("ShirtGraphic") or child:IsA("CharacterMesh") then
			child:Clone().Parent = character
		end
	end
	local records = {}
	local keep = {}
	for _, template in ipairs(donor:GetChildren()) do
		if template:IsA("Accessory") then
			local skip = isLayeredAccessory(template)
			if not skip then
				local info = getWeldInfo(template)
				local accessory = attachAccessory(character, humanoid, template, info)
				if accessory then
					keep[accessory] = true
					table.insert(records, {
						accessory = accessory,
						backup = template:Clone(),
						info = info,
						repairs = 0,
					})
				end
			end
		end
	end
	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("Accessory") and not keep[child] then
			child:Destroy()
		end
	end
	if gameHidesRig(keepTransparency) then
		for name, transparency in pairs(keepTransparency) do
			local p = findPart(character, name)
			if p then
				p.Transparency = transparency
			end
		end
	end
	return records
end

local function fixColorsDeferred(character, currentRequest)
	task.defer(function()
		if currentRequest ~= requestId then
			return
		end
		local colors = character:FindFirstChildOfClass("BodyColors")
		if colors then
			applyManualBodyColors(character, colors)
		end
	end)
end

local function setAnimateEnabled(animate, enabled)
	local ok = pcall(function()
		animate.Enabled = enabled
	end)
	if not ok then
		pcall(function()
			animate.Disabled = not enabled
		end)
	end
end

local function recoverCharacter(character, humanoid)
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") or humanoid.Health <= 0 then
		return
	end
	pcall(function()
		local cf = root.CFrame
		if cf.UpVector.Y >= 0.85 then
			return
		end
		local flat = Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z)
		if flat.Magnitude < 0.3 then
			flat = Vector3.new(cf.UpVector.X, 0, cf.UpVector.Z)
		end
		if flat.Magnitude < 0.05 then
			flat = Vector3.new(0, 0, -1)
		end
		local position = cf.Position + Vector3.new(0, 2, 0)
		root.CFrame = CFrame.lookAt(position, position + flat.Unit)
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
		humanoid.PlatformStand = false
		humanoid.Sit = false
		humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	end)
end

local function fixCamera(humanoid)
	local camera = workspace.CurrentCamera
	if not camera or not humanoid then
		return
	end
	pcall(function()
		local subject = camera.CameraSubject
		if humanoid.Parent and (subject == nil or not subject:IsDescendantOf(workspace)) then
			camera.CameraSubject = humanoid
		end
	end)
end

local function newFxPart(props, life)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for key, value in pairs(props) do
		p[key] = value
	end
	p.Parent = workspace
	Debris:AddItem(p, life or 3)
	return p
end

local Lighting = game:GetService("Lighting")
local FX_WHITE = Color3.fromRGB(246, 247, 252)
local FX_LIGHT = Color3.fromRGB(208, 211, 222)
local FX_GRAY = Color3.fromRGB(132, 135, 144)
local FX_ROCK = Color3.fromRGB(112, 114, 120)
local FX_HALO = Color3.fromRGB(196, 208, 255)
local BEAM_TEX_SPARK = "rbxasset://textures/particles/sparkles_main.dds"
local BEAM_TEX_SMOKE = "rbxasset://textures/particles/smoke_main.dds"
local BEAM_HEIGHT = 240
local BEAM_SAMPLES = { 0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1 }
local BEAM_STRANDS = 3
local BEAM_LAYERS = {
	{ name = "halo", width = 38, color = FX_HALO, tint = FX_LIGHT, base = 0.94, peak = 0.8, delay = 0.24, taper = 0.55, freq = 2.6, band = 0.8, bandWidth = 0.3, sway = 1 },
	{ name = "aura", width = 23, color = FX_LIGHT, tint = FX_HALO, base = 0.85, peak = 0.6, delay = 0.17, taper = 0.5, freq = 4.4, band = 1.2, bandWidth = 0.22, sway = 0.8 },
	{ name = "body", width = 12.5, color = FX_WHITE, tint = FX_LIGHT, base = 0.5, peak = 0.14, delay = 0.09, taper = 0.45, freq = 7, band = 1.8, bandWidth = 0.15, sway = 0.35 },
	{ name = "core", width = 4.8, color = FX_WHITE, tint = FX_WHITE, base = 0.02, peak = 0, delay = 0, taper = 0.38, freq = 13, band = 0, bandWidth = 0.1, fadePow = 4, sway = 0 },
	{ name = "flowFast", width = 16, color = FX_WHITE, tint = FX_HALO, base = 0.3, peak = 0.08, delay = 0.05, taper = 0.7, freq = 5.5, band = 2.3, bandWidth = 0.12, sway = 0.5, flow = { texture = BEAM_TEX_SPARK, speed = 30, length = 12 } },
	{ name = "flowSoft", width = 28, color = FX_HALO, tint = FX_WHITE, base = 0.55, peak = 0.3, delay = 0.13, taper = 0.85, freq = 3.2, band = 0, bandWidth = 0.2, sway = 1, flow = { texture = BEAM_TEX_SMOKE, speed = 16, length = 26 } },
}
local BEAM_SHEETS = {
	{ width = 10, speed = 2.4, transparency = 0.84 },
	{ width = 17, speed = -3.3, transparency = 0.9 },
	{ width = 25, speed = 1.5, transparency = 0.94 },
}
local AURA_COLOR = FX_WHITE
local STREAK_COUNT = 16
local STREAK_LIFE = 0.85
local STREAK_TRAIL = 0.65
local STREAK_WIDTH = 2.4
local VORTEX_HEIGHT = 28
local VORTEX_R0 = 2.4
local VORTEX_R1 = 8.5
local VORTEX_TURNS = 1.7
local SCREEN_FLASH = true
local activeVortex = nil

local function flatRing(position, diameter, thickness, color, transparency, life)
	return newFxPart({
		Shape = Enum.PartType.Cylinder,
		Material = Enum.Material.Neon,
		Color = color,
		Transparency = transparency,
		Size = Vector3.new(thickness, diameter, diameter),
		CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90)),
	}, life)
end

local function ringOffset(radius)
	local angle = math.random() * math.pi * 2
	return Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
end

local function lightningBolt(a, b, color, thickness)
	local segments = 6
	local dir = b - a
	local jitter = dir.Magnitude * 0.09
	local last = a
	for i = 1, segments do
		local nextPoint = b
		if i < segments then
			nextPoint = a
				+ dir * (i / segments)
				+ Vector3.new(
					(math.random() - 0.5) * 2 * jitter,
					(math.random() - 0.5) * 2 * jitter,
					(math.random() - 0.5) * 2 * jitter
				)
		end
		local delta = nextPoint - last
		local length = delta.Magnitude
		if length > 0.01 then
			newFxPart({
				Material = Enum.Material.Neon,
				Color = color,
				Size = Vector3.new(thickness, thickness, length),
				CFrame = CFrame.lookAt(last + delta / 2, nextPoint),
			}, 0.14)
		end
		last = nextPoint
	end
end

local function throwRock(center, distance, rise, life)
	local angle = math.random() * math.pi * 2
	local size = 0.4 + math.random() * 0.9
	local startPos = center + Vector3.new(math.cos(angle) * distance, size / 2, math.sin(angle) * distance)
	local rock = newFxPart({
		Material = Enum.Material.Slate,
		Color = FX_ROCK,
		Size = Vector3.new(size, size * (0.6 + math.random() * 0.6), size * (0.7 + math.random() * 0.5)),
		CFrame = CFrame.new(startPos) * CFrame.Angles(math.random() * 6, math.random() * 6, math.random() * 6),
	}, life + 0.5)
	TweenService:Create(rock, TweenInfo.new(life, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		CFrame = CFrame.new(startPos + Vector3.new(0, rise, 0))
			* CFrame.Angles(math.random() * 6, math.random() * 6, math.random() * 6),
		Transparency = 1,
	}):Play()
end

local function shakeCamera(humanoid, duration, strength)
	if not humanoid or not humanoid.Parent then
		return
	end
	local base = humanoid.CameraOffset
	local t0 = os.clock()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local t = (os.clock() - t0) / duration
		if t >= 1 or not humanoid.Parent then
			conn:Disconnect()
			pcall(function()
				humanoid.CameraOffset = base
			end)
			return
		end
		local k = (1 - t) ^ 2 * strength
		humanoid.CameraOffset = base + Vector3.new((math.random() - 0.5) * k, (math.random() - 0.5) * k, 0)
	end)
end

local function screenFlash(peak, duration)
	if not SCREEN_FLASH then
		return
	end
	local ok = pcall(function()
		local cc = Instance.new("ColorCorrectionEffect")
		cc.Name = "AFO_Flash"
		cc.Brightness = peak
		cc.Saturation = -0.7
		cc.Parent = Lighting
		TweenService:Create(cc, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Brightness = 0,
			Saturation = 0,
		}):Play()
		Debris:AddItem(cc, duration + 0.3)
	end)
	return ok
end

local function softFlash()
	task.spawn(function()
		local parent = gui and gui.Parent
		if not parent and localPlayer then
			parent = localPlayer:FindFirstChildOfClass("PlayerGui")
		end
		if not parent then
			return
		end
		local flash = Instance.new("ScreenGui")
		flash.Name = "AFO_SoftFlash"
		flash.ResetOnSpawn = false
		flash.IgnoreGuiInset = true
		flash.DisplayOrder = 50
		flash.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		local frame = Instance.new("Frame")
		frame.Size = UDim2.fromScale(1, 1)
		frame.BackgroundColor3 = Color3.new(1, 1, 1)
		frame.BackgroundTransparency = 0.82
		frame.BorderSizePixel = 0
		frame.Active = false
		frame.Parent = flash
		flash.Parent = parent
		TweenService:Create(frame, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = 1,
		}):Play()
		Debris:AddItem(flash, 0.7)
	end)
end

local function layerSequence(def, t, alpha, index)
	local keys = {}
	local pos = -10
	if def.band and def.band > 0 then
		pos = (t * def.band + index * 0.37) % 1.5 - 0.25
	end
	local hw = def.bandWidth or 0.15
	local fadePow = def.fadePow or 2.4
	for i, x in ipairs(BEAM_SAMPLES) do
		local v = def.base + (1 - def.base) * (x ^ fadePow)
		local d = (x - pos) / hw
		v = v + (def.peak - v) * math.exp(-d * d)
		v = 1 - (1 - v) * alpha
		keys[i] = NumberSequenceKeypoint.new(x, math.clamp(v, 0, 1))
	end
	return NumberSequence.new(keys)
end

local function createBeamStack(center, height)
	local stack = {
		alive = true,
		destroyed = false,
		ignited = false,
		parts = {},
		layers = {},
		sheets = {},
		strands = {},
		emitters = {},
	}
	local function keep(part)
		table.insert(stack.parts, part)
		return part
	end
	local anchor = keep(newFxPart({ Transparency = 1, Size = Vector3.one, Position = center }, 60))
	local a0 = Instance.new("Attachment")
	a0.Parent = anchor
	local function newBeam(attachment0, attachment1, color, segments)
		local beam = Instance.new("Beam")
		beam.Attachment0 = attachment0
		beam.Attachment1 = attachment1
		beam.FaceCamera = true
		beam.LightEmission = 1
		beam.LightInfluence = 0
		beam.Segments = segments
		beam.Width0 = 0
		beam.Width1 = 0
		beam.Color = color
		beam.Transparency = NumberSequence.new(1)
		beam.Parent = anchor
		return beam
	end
	for index, def in ipairs(BEAM_LAYERS) do
		local top = Instance.new("Attachment")
		top.Position = Vector3.new(0, 0.05, 0)
		top.Parent = anchor
		local beam = newBeam(a0, top, ColorSequence.new(def.color, def.tint), 24)
		if def.flow then
			beam.Texture = def.flow.texture
			beam.TextureMode = Enum.TextureMode.Wrap
			beam.TextureLength = def.flow.length
			beam.TextureSpeed = def.flow.speed
		end
		table.insert(stack.layers, { beam = beam, top = top, def = def, index = index })
	end
	for i = 1, BEAM_STRANDS do
		local s0 = Instance.new("Attachment")
		s0.Parent = anchor
		local s1 = Instance.new("Attachment")
		s1.Parent = anchor
		local beam = newBeam(s0, s1, ColorSequence.new(FX_WHITE, FX_HALO), 12)
		table.insert(stack.strands, {
			a0 = s0,
			a1 = s1,
			beam = beam,
			phase = (i - 1) * (2 * math.pi / BEAM_STRANDS),
			dir = (i % 2 == 0) and -1 or 1,
		})
	end
	for _, def in ipairs(BEAM_SHEETS) do
		for k = 0, 1 do
			local sheet = keep(newFxPart({
				Material = Enum.Material.Neon,
				Color = (k == 0) and FX_WHITE or FX_HALO,
				Transparency = 1,
				Size = Vector3.new(0.12, 1, def.width),
				Position = center,
			}, 60))
			table.insert(stack.sheets, { part = sheet, def = def, offset = k * math.pi / 2 })
		end
	end
	local tip = keep(newFxPart({
		Shape = Enum.PartType.Ball,
		Material = Enum.Material.Neon,
		Color = FX_WHITE,
		Transparency = 1,
		Size = Vector3.one,
		Position = center,
	}, 60))
	local disc = keep(flatRing(center + Vector3.new(0, 0.12, 0), 10, 0.3, FX_WHITE, 0.25, 60))
	local discHalo = keep(flatRing(center + Vector3.new(0, 0.1, 0), 28, 0.2, FX_HALO, 0.82, 60))
	local lightPart = keep(newFxPart({ Transparency = 1, Size = Vector3.one, Position = center + Vector3.new(0, 6, 0) }, 60))
	local light = Instance.new("PointLight")
	light.Color = FX_WHITE
	light.Range = 46
	light.Brightness = 0
	light.Parent = lightPart
	local emitPart = keep(newFxPart({
		Transparency = 1,
		Size = Vector3.new(6, 0.5, 6),
		Position = center + Vector3.new(0, 0.5, 0),
	}, 60))
	local streaks = Instance.new("ParticleEmitter")
	streaks.Texture = BEAM_TEX_SPARK
	streaks.Color = ColorSequence.new(FX_WHITE, FX_HALO)
	streaks.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1.8),
		NumberSequenceKeypoint.new(1, 0.3),
	})
	streaks.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(0.7, 0.4),
		NumberSequenceKeypoint.new(1, 1),
	})
	streaks.Lifetime = NumberRange.new(0.6, 1.1)
	streaks.Speed = NumberRange.new(110, 200)
	streaks.SpreadAngle = Vector2.new(2, 2)
	streaks.EmissionDirection = Enum.NormalId.Top
	streaks.LightEmission = 1
	streaks.Rate = 0
	pcall(function()
		streaks.Orientation = Enum.ParticleOrientation.VelocityParallel
		streaks.Shape = Enum.ParticleEmitterShape.Cylinder
		streaks.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	end)
	streaks.Parent = emitPart
	table.insert(stack.emitters, streaks)
	local embers = Instance.new("ParticleEmitter")
	embers.Texture = BEAM_TEX_SPARK
	embers.Color = ColorSequence.new(FX_WHITE, FX_HALO)
	embers.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.7),
		NumberSequenceKeypoint.new(1, 0),
	})
	embers.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	embers.Lifetime = NumberRange.new(1.1, 2)
	embers.Speed = NumberRange.new(18, 42)
	embers.SpreadAngle = Vector2.new(24, 24)
	embers.EmissionDirection = Enum.NormalId.Top
	embers.Acceleration = Vector3.new(0, 14, 0)
	embers.LightEmission = 1
	embers.Rate = 0
	embers.Parent = emitPart
	table.insert(stack.emitters, embers)
	local dust = Instance.new("ParticleEmitter")
	dust.Texture = BEAM_TEX_SMOKE
	dust.Color = ColorSequence.new(FX_LIGHT, FX_GRAY)
	dust.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 5),
		NumberSequenceKeypoint.new(1, 18),
	})
	dust.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.55),
		NumberSequenceKeypoint.new(1, 1),
	})
	dust.Lifetime = NumberRange.new(0.9, 1.6)
	dust.Speed = NumberRange.new(14, 32)
	dust.SpreadAngle = Vector2.new(88, 88)
	dust.EmissionDirection = Enum.NormalId.Top
	dust.Rotation = NumberRange.new(0, 360)
	dust.RotSpeed = NumberRange.new(-70, 70)
	dust.Drag = 3
	dust.LightEmission = 0.35
	dust.Rate = 0
	dust.Parent = emitPart
	table.insert(stack.emitters, dust)
	local bloom = Instance.new("ParticleEmitter")
	bloom.Texture = BEAM_TEX_SMOKE
	bloom.Color = ColorSequence.new(FX_WHITE, FX_HALO)
	bloom.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 10),
		NumberSequenceKeypoint.new(1, 26),
	})
	bloom.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.45),
		NumberSequenceKeypoint.new(1, 1),
	})
	bloom.Lifetime = NumberRange.new(0.35, 0.55)
	bloom.Speed = NumberRange.new(0, 0)
	bloom.LightEmission = 1
	bloom.Rate = 0
	bloom.Parent = emitPart
	table.insert(stack.emitters, bloom)

	function stack.ignite(position)
		local ball = newFxPart({
			Shape = Enum.PartType.Ball,
			Material = Enum.Material.Neon,
			Color = FX_WHITE,
			Transparency = 0.1,
			Size = Vector3.new(6, 6, 6),
			Position = position + Vector3.new(0, 2, 0),
		}, 1)
		TweenService:Create(ball, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = Vector3.new(32, 32, 32),
			Transparency = 1,
		}):Play()
		for k = 0, 1 do
			local ring = flatRing(position + Vector3.new(0, 0.2, 0), 4, 0.3, (k == 0) and FX_WHITE or FX_HALO, 0.15, 1.2)
			local size = 48 + k * 18
			TweenService:Create(ring, TweenInfo.new(0.5 + k * 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = Vector3.new(0.15, size, size),
				Transparency = 1,
			}):Play()
		end
		dust:Emit(28)
		streaks:Emit(24)
		bloom:Emit(3)
	end

	function stack.step(t, position, grow, widthScale, alpha)
		if not stack.alive then
			return
		end
		alpha = math.clamp(alpha, 0, 1)
		if not stack.ignited and grow > 0.04 and alpha > 0.3 then
			stack.ignited = true
			pcall(stack.ignite, position)
		end
		local fullHeight = math.max(height * grow, 0.1)
		anchor.Position = position
		for _, layer in ipairs(stack.layers) do
			local def = layer.def
			local lg = smoothstep((grow - def.delay) / math.max(1 - def.delay, 0.05))
			layer.top.Position = Vector3.new(0, math.max(fullHeight * lg, 0.1), 0)
			local wobble = 1
				+ 0.16 * math.sin(t * def.freq + layer.index * 1.7)
				+ 0.07 * math.sin(t * def.freq * 2.3 + layer.index * 0.9)
			if def.name == "core" then
				wobble += 0.1 * math.sin(t * 31)
			end
			local width = def.width * widthScale * wobble * (0.35 + 0.65 * lg)
			layer.beam.Width0 = width
			layer.beam.Width1 = width * def.taper
			layer.beam.Transparency = layerSequence(def, t, alpha, layer.index)
			local sway = math.sin(t * def.freq * 0.5 + layer.index) * 1.6 * widthScale * (def.sway or 0)
			layer.beam.CurveSize0 = sway
			layer.beam.CurveSize1 = -sway
		end
		local coreGrow = smoothstep(grow)
		local strandGrow = smoothstep((grow - 0.1) / 0.9)
		local baseRadius = 3 + 6 * math.min(widthScale, 1.6)
		for _, strand in ipairs(stack.strands) do
			local angle = strand.phase + t * 2.6 * strand.dir
			strand.a0.Position = Vector3.new(math.cos(angle) * baseRadius, 0.3, math.sin(angle) * baseRadius)
			local topAngle = angle + 1.9 * strand.dir
			local topRadius = baseRadius * 0.3
			strand.a1.Position = Vector3.new(
				math.cos(topAngle) * topRadius,
				math.max(fullHeight * strandGrow * 0.9, 0.3),
				math.sin(topAngle) * topRadius
			)
			local w = 0.55 * math.max(widthScale, 0.2)
			strand.beam.Width0 = w
			strand.beam.Width1 = w * 0.3
			strand.beam.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1 - 0.85 * alpha),
				NumberSequenceKeypoint.new(0.4, 1 - 0.5 * alpha),
				NumberSequenceKeypoint.new(1, 1),
			})
		end
		local sheetLength = math.max(fullHeight * 0.75 * coreGrow, 0.2)
		for _, sheet in ipairs(stack.sheets) do
			local angle = sheet.offset + t * sheet.def.speed
			sheet.part.Size = Vector3.new(0.12, sheetLength, math.max(sheet.def.width * widthScale, 0.05))
			sheet.part.CFrame = CFrame.new(position + Vector3.new(0, sheetLength / 2, 0)) * CFrame.Angles(0, angle, 0)
			sheet.part.Transparency = 1 - (1 - sheet.def.transparency) * alpha
		end
		local tipSize = math.max(widthScale * (11 + 3 * math.sin(t * 17)), 0.1)
		tip.Size = Vector3.new(tipSize, tipSize, tipSize)
		tip.Position = position + Vector3.new(0, fullHeight * coreGrow, 0)
		tip.Transparency = (grow < 0.04) and 1 or (1 - 0.65 * alpha)
		local pulse = 1 + 0.18 * math.sin(t * 22)
		local discSize = math.max(10 * widthScale * pulse, 0.1)
		disc.Size = Vector3.new(0.3, discSize, discSize)
		disc.CFrame = CFrame.new(position + Vector3.new(0, 0.12, 0)) * CFrame.Angles(0, 0, math.rad(90))
		local haloSize = math.max(28 * widthScale, 0.1)
		discHalo.Size = Vector3.new(0.2, haloSize, haloSize)
		discHalo.CFrame = CFrame.new(position + Vector3.new(0, 0.1, 0)) * CFrame.Angles(0, 0, math.rad(90))
		lightPart.Position = position + Vector3.new(0, 6, 0)
		light.Brightness = 12 * alpha * math.min(widthScale, 1.5) * (0.85 + 0.15 * math.sin(t * 31))
		local reach = 2 + 5 * math.min(widthScale, 2)
		emitPart.Size = Vector3.new(reach, 0.5, reach)
		emitPart.Position = position + Vector3.new(0, 0.5, 0)
		streaks.Rate = (grow > 0.15) and (130 * alpha) or 0
		embers.Rate = 50 * alpha
		dust.Rate = 26 * alpha * math.min(widthScale, 1.5)
		bloom.Rate = 12 * alpha
	end

	function stack.pulse(position, widthScale)
		local rise = height * (0.55 + 0.4 * math.random())
		for k = 0, 1 do
			local ring = flatRing(
				position + Vector3.new(0, 0.4, 0),
				math.max((9 + k * 5) * widthScale, 1),
				0.3 + k * 0.2,
				(k == 0) and FX_WHITE or FX_HALO,
				0.15 + k * 0.3,
				1.6
			)
			local tail = math.max((4 + k * 2.5) * widthScale, 0.5)
			TweenService:Create(ring, TweenInfo.new(0.5 + math.random() * 0.3 + k * 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				CFrame = CFrame.new(position + Vector3.new(0, rise, 0)) * CFrame.Angles(0, 0, math.rad(90)),
				Size = Vector3.new(0.2, tail, tail),
				Transparency = 1,
			}):Play()
		end
	end

	function stack.destroy()
		if stack.destroyed then
			return
		end
		stack.destroyed = true
		stack.alive = false
		for _, emitter in ipairs(stack.emitters) do
			emitter.Enabled = false
		end
		for _, layer in ipairs(stack.layers) do
			layer.beam.Enabled = false
		end
		for _, strand in ipairs(stack.strands) do
			strand.beam.Enabled = false
		end
		task.delay(1, function()
			for _, part in ipairs(stack.parts) do
				pcall(function()
					part:Destroy()
				end)
			end
		end)
	end

	function stack.play(position, duration, curve)
		local started = os.clock()
		local connection
		connection = RunService.Heartbeat:Connect(function()
			local t = os.clock() - started
			if t >= duration or not stack.alive then
				connection:Disconnect()
				stack.destroy()
				return
			end
			local grow, widthScale, alpha = curve(t)
			stack.step(t, position, grow, widthScale, alpha)
		end)
	end

	return stack
end

local function newStreakHead(color)
	local p = newFxPart({
		Transparency = 1,
		Size = Vector3.new(0.2, 0.2, 0.2),
	}, 60)
	local a0 = Instance.new("Attachment")
	a0.Position = Vector3.new(0, STREAK_WIDTH / 2, 0)
	a0.Parent = p
	local a1 = Instance.new("Attachment")
	a1.Position = Vector3.new(0, -STREAK_WIDTH / 2, 0)
	a1.Parent = p
	local trail = Instance.new("Trail")
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	trail.Lifetime = STREAK_TRAIL
	trail.MinLength = 0.02
	trail.FaceCamera = true
	trail.LightEmission = 1
	trail.LightInfluence = 0
	trail.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
		ColorSequenceKeypoint.new(0.4, color),
		ColorSequenceKeypoint.new(1, color),
	})
	trail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.6, 0.4),
		NumberSequenceKeypoint.new(1, 1),
	})
	trail.WidthScale = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(1, 0),
	})
	trail.Enabled = false
	trail.Parent = p
	return p, trail
end

local function streakPoint(center, baseAngle, direction, u, scale)
	local eased = u * u * (3 - 2 * u)
	local angle = baseAngle + direction * eased * VORTEX_TURNS * 2 * math.pi
	local radius = (VORTEX_R0 + (VORTEX_R1 - VORTEX_R0) * (u ^ 1.6)) * scale
	local height = VORTEX_HEIGHT * (u ^ 0.85) * scale
	return center + Vector3.new(math.cos(angle) * radius, height, math.sin(angle) * radius)
end

local function beginVortex(character, root)
	if activeVortex then
		pcall(activeVortex.stop)
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }
	local origin = root.Position
	local hit = workspace:Raycast(origin, Vector3.new(0, -20, 0), params)
	local groundY = hit and (hit.Position.Y + 0.1) or (origin.Y - 3)
	local state = { alive = true, parts = {} }
	local function keep(p)
		table.insert(state.parts, p)
		return p
	end
	local function groundCenter()
		local p = root.Position
		return Vector3.new(p.X, groundY, p.Z)
	end
	local center = groundCenter()

	local gather = keep(newFxPart({
		Transparency = 1,
		Size = Vector3.new(22, 22, 22),
		Position = center + Vector3.new(0, 3, 0),
	}, 60))
	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	emitter.Color = ColorSequence.new(FX_WHITE, FX_LIGHT)
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.9),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Lifetime = NumberRange.new(0.5, 0.8)
	emitter.Speed = NumberRange.new(16, 26)
	emitter.Rate = 70
	emitter.LightEmission = 1
	emitter.Drag = 0
	pcall(function()
		emitter.Shape = Enum.ParticleEmitterShape.Sphere
		emitter.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
		emitter.ShapeInOut = Enum.ParticleEmitterShapeInOut.Inward
	end)
	emitter.Parent = gather
	local light = Instance.new("PointLight")
	light.Color = FX_WHITE
	light.Range = 26
	light.Brightness = 0
	light.Parent = gather

	local beamStack = createBeamStack(center, BEAM_HEIGHT)

	local heads = {}
	for i = 0, STREAK_COUNT - 1 do
		local m = i % 3
		local color = (m == 0) and FX_GRAY or ((m == 1) and FX_WHITE or FX_LIGHT)
		local part, trail = newStreakHead(color)
		keep(part)
		table.insert(heads, {
			part = part,
			trail = trail,
			direction = (i % 4 == 3) and -1 or 1,
			baseAngle = (i / STREAK_COUNT) * 2 * math.pi,
			birth = (i / STREAK_COUNT) * STREAK_LIFE,
			cycle = -1,
			jitter = 0,
			fresh = false,
		})
	end

	local t0 = os.clock()
	local nextRing, nextBolt, nextRock, nextPulse = 0, 0, 0, 0
	state.conn = RunService.Heartbeat:Connect(function()
		if not state.alive or not root.Parent then
			return
		end
		local t = os.clock() - t0
		center = groundCenter()
		local ramp = smoothstep(t / 0.7)
		gather.Position = center + Vector3.new(0, 3, 0)
		light.Brightness = 2 + 6 * ramp * (0.7 + 0.3 * math.sin(t * 30))

		local beamWidth = 0.2 + 0.8 * ramp
		beamStack.step(t, center, 1 - (1 - math.min(t / 0.5, 1)) ^ 3, beamWidth, 1)
		if t >= nextPulse then
			nextPulse = t + 0.16 + math.random() * 0.1
			beamStack.pulse(center, beamWidth)
		end

		for _, h in ipairs(heads) do
			local lt = t - h.birth
			if lt >= 0 then
				local cycle = math.floor(lt / STREAK_LIFE)
				local u = lt / STREAK_LIFE - cycle
				if cycle ~= h.cycle then
					h.cycle = cycle
					h.trail.Enabled = false
					h.fresh = true
					h.jitter = math.random() * 0.6
				elseif h.fresh then
					h.fresh = false
					h.trail.Enabled = true
				end
				h.part.CFrame = CFrame.new(streakPoint(center, h.baseAngle + h.jitter, h.direction, u, 0.45 + 0.55 * ramp))
			end
		end

		if t >= nextRing then
			nextRing = t + 0.3
			local ring
			if t < 0.6 then

				ring = flatRing(center + Vector3.new(0, 0.1, 0), 28, 0.15, FX_LIGHT, 0.7, 1)
				TweenService:Create(ring, TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
					Size = Vector3.new(0.15, 4, 4),
					Transparency = 0.1,
				}):Play()
			else
				ring = flatRing(center + Vector3.new(0, 0.1, 0), 6, 0.15, (math.random() < 0.5) and FX_WHITE or FX_LIGHT, 0.35, 1)
				TweenService:Create(ring, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Size = Vector3.new(0.15, 26, 26),
					Transparency = 1,
				}):Play()
			end
		end

		if ramp > 0.3 and t >= nextBolt then
			nextBolt = t + 0.09
			for _ = 1, 2 do
				local a = center + Vector3.new(0, 0.5 + math.random() * 2, 0) + ringOffset(1.5)
				local b = center + Vector3.new(0, 4 + math.random() * 14, 0) + ringOffset(4 + math.random() * 5)
				lightningBolt(a, b, (math.random() < 0.6) and FX_WHITE or FX_LIGHT, 0.16)
			end
		end

		if ramp > 0.15 and t >= nextRock then
			nextRock = t + 0.1
			throwRock(center, 3 + math.random() * 7, 6 + math.random() * 12, 1.4)
		end
	end)

	function state.stop()
		if not state.alive then
			return
		end
		state.alive = false
		if activeVortex == state then
			activeVortex = nil
		end
		if state.conn then
			state.conn:Disconnect()
		end
		emitter.Enabled = false
		for _, h in ipairs(heads) do
			h.trail.Enabled = false
		end
		pcall(function()
			beamStack.play(center, 0.45, function(t)
				local k = t / 0.45
				return 1, (1 - k) ^ 2, 1 - k
			end)
			TweenService:Create(light, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Brightness = 0,
			}):Play()
		end)
		task.delay(1.2, function()
			for _, p in ipairs(state.parts) do
				pcall(function()
					p:Destroy()
				end)
			end
		end)
	end

	activeVortex = state
	return state
end

local function splash(character, humanoid)
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	stopSfxLoop()
	playSfx(SFX_FINISH, SFX_FINISH_VOLUME)
	local center = root.Position
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }
	local hit = workspace:Raycast(center, Vector3.new(0, -15, 0), params)
	local groundPos = hit and (hit.Position + Vector3.new(0, 0.1, 0)) or (center - Vector3.new(0, 3, 0))
	if gray then
		gray.boost = 1
	end
	screenFlash(0.55, 0.75)
	shakeCamera(humanoid, 0.6, 0.9)

	local flash = newFxPart({
		Shape = Enum.PartType.Ball,
		Material = Enum.Material.Neon,
		Color = FX_WHITE,
		Transparency = 0,
		Size = Vector3.new(5, 5, 5),
		Position = center,
	}, 1.5)
	TweenService:Create(flash, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(36, 36, 36),
		Transparency = 1,
	}):Play()

	local burst = createBeamStack(groundPos, BEAM_HEIGHT)
	burst.play(groundPos, 1.1, function(t)
		local k = t / 1.1
		local attack = math.min(t / 0.07, 1)
		return 1 - (1 - math.min(t / 0.14, 1)) ^ 3, 2.6 * attack * (1 - k) ^ 2.2, 1 - k
	end)
	for i = 0, 3 do
		task.delay(i * 0.08, function()
			burst.pulse(groundPos, 1.8)
		end)
	end

	for k = 0, 2 do
		task.delay(k * 0.09, function()
			local diameter = 70 + k * 12
			local ring = flatRing(groundPos, 4, 0.35, (k % 2 == 0) and FX_WHITE or FX_LIGHT, 0.1, 1.5)
			TweenService:Create(ring, TweenInfo.new(0.75, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = Vector3.new(0.12, diameter, diameter),
				Transparency = 1,
			}):Play()
		end)
	end

	for _ = 1, 8 do
		local a = center + ringOffset(1)
		local b = center + Vector3.new(0, (math.random() - 0.3) * 10, 0) + ringOffset(8 + math.random() * 8)
		lightningBolt(a, b, (math.random() < 0.5) and FX_WHITE or FX_LIGHT, 0.2)
	end
	for _ = 1, 18 do
		throwRock(groundPos, 2 + math.random() * 9, 8 + math.random() * 14, 1.6)
	end

	local emitterPart = newFxPart({ Transparency = 1, Size = Vector3.one, Position = groundPos + Vector3.new(0, 4, 0) })
	local light = Instance.new("PointLight")
	light.Color = FX_WHITE
	light.Brightness = 8
	light.Range = 34
	light.Parent = emitterPart
	TweenService:Create(light, TweenInfo.new(1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Brightness = 0,
	}):Play()
	local sparks = Instance.new("ParticleEmitter")
	sparks.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparks.Color = ColorSequence.new(FX_WHITE, FX_LIGHT)
	sparks.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.6),
		NumberSequenceKeypoint.new(1, 0),
	})
	sparks.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	sparks.Lifetime = NumberRange.new(0.7, 1.2)
	sparks.Speed = NumberRange.new(10, 24)
	sparks.SpreadAngle = Vector2.new(180, 180)
	sparks.Drag = 2
	sparks.Rate = 0
	sparks.LightEmission = 1
	sparks.Parent = emitterPart
	sparks:Emit(40)

	task.delay(0.05, function()
		if not character.Parent then
			return
		end
		local aura = Instance.new("Highlight")
		aura.Name = "AFO_AuraFlash"
		aura.Adornee = character
		aura.FillColor = AURA_COLOR
		aura.FillTransparency = 0.45
		aura.OutlineColor = AURA_COLOR
		aura.OutlineTransparency = 0
		aura.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		aura.Parent = workspace
		TweenService:Create(aura, TweenInfo.new(1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			FillTransparency = 1,
			OutlineTransparency = 1,
		}):Play()
		Debris:AddItem(aura, 1.4)
	end)

	local camera = workspace.CurrentCamera
	if camera and not fovBase then
		local fov = camera.FieldOfView
		fovBase = fov
		local out = TweenService:Create(camera, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			FieldOfView = fov + 10,
		})
		out:Play()
		out.Completed:Once(function()
			local back = TweenService:Create(camera, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				FieldOfView = fov,
			})
			back:Play()
			back.Completed:Once(function()
				camera.FieldOfView = fov
				fovBase = nil
			end)
		end)
		task.delay(1.9, function()
			if fovBase == fov then
				pcall(function()
					camera.FieldOfView = fov
				end)
				fovBase = nil
			end
		end)
	end
end

local function captureDefaultAnims(character)
	if defaultAnims[character] then
		return
	end
	local animate = character:FindFirstChild("Animate")
	if not animate then
		return
	end
	local defaults = {}
	for _, entry in ipairs(ANIM_MAP) do
		local folder = animate:FindFirstChild(entry[1])
		local anim = folder and folder:FindFirstChild(entry[2])
		if anim and anim:IsA("Animation") then
			defaults[entry[1] .. "/" .. entry[2]] = anim.AnimationId
		end
	end
	defaultAnims[character] = defaults
end

local function captureOriginals(character, humanoid)
	if originalDescriptions[character] ~= nil then
		return
	end
	local ok, desc = pcall(function()
		return humanoid:GetAppliedDescription()
	end)
	local originalHead = findPart(character, "Head")
	local originalFace = false
	if originalHead and not isDynamicHead(originalHead) then
		for _, c in ipairs(originalHead:GetChildren()) do
			if c:IsA("Decal") and c.Texture ~= "" then
				originalFace = c.Texture
				break
			end
		end
	end
	originalFaces[character] = originalFace
	originalDescriptions[character] = (ok and desc) or false
	captureDefaultAnims(character)
end

local function runDescriptionMethod(humanoid, description)
	local methods = {
		"ApplyDescriptionResetAsync",
		"ApplyDescriptionReset",
		"ApplyDescriptionAsync",
		"ApplyDescription",
	}
	for _, name in ipairs(methods) do
		local okCall = pcall(function()
			humanoid[name](humanoid, description)
		end)
		if okCall then
			return true
		end
	end
	return false
end

local function applyDescriptionToCharacter(character, humanoid, description)
	removeSkin(character)
	local keepTransparency = {}
	for _, d in ipairs(character:GetDescendants()) do
		if d:IsA("BasePart") and not isInsideAccessoryOrTool(d) then
			keepTransparency[d.Name] = d.Transparency
		end
	end
	local done, okRun = false, false
	task.spawn(function()
		okRun = runDescriptionMethod(humanoid, description)
		done = true
	end)
	local waited = 0
	while not done and waited < DESCRIPTION_TIMEOUT do
		task.wait(0.05)
		waited += 0.05
	end
	task.wait(0.15)
	if done and okRun then
		pcall(function()
			local head = findPart(character, "Head")
			if head and description.Face ~= 0 and not hasFaceDecal(head) and not isDynamicHead(head) then
				newFaceDecal(head, "rbxassetid://" .. tostring(description.Face))
			end
		end)
	end
	if gameHidesRig(keepTransparency) then
		for name, transparency in pairs(keepTransparency) do
			local p = findPart(character, name)
			if p and p.Transparency ~= transparency then
				p.Transparency = transparency
			end
		end
	end
	return done and okRun
end
local swapGuards = setmetatable({}, { __mode = "k" })
local GUARD_HOLD = 1.2

local function acquireSwapGuard(humanoid)
	local g = swapGuards[humanoid]
	if not g then
		g = { count = 0, prevNeck = humanoid.RequiresNeck, prevDead = true }
		pcall(function()
			g.prevDead = humanoid:GetStateEnabled(Enum.HumanoidStateType.Dead)
		end)
		swapGuards[humanoid] = g
	end
	g.count += 1
	pcall(function()
		humanoid.RequiresNeck = false
	end)
	pcall(function()
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
	end)
	return g
end

local function releaseSwapGuard(humanoid, g, hold)
	local function release()
		g.count -= 1
		if g.count > 0 then
			return
		end
		swapGuards[humanoid] = nil
		pcall(function()
			humanoid.RequiresNeck = g.prevNeck
		end)
		pcall(function()
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, g.prevDead)
		end)
	end
	if hold and hold > 0 then
		task.delay(hold, release)
	else
		release()
	end
end

local function guardedSwap(humanoid, fn)
	local g = acquireSwapGuard(humanoid)
	local ok, a, b = pcall(fn)
	releaseSwapGuard(humanoid, g, GUARD_HOLD)
	if not ok then
		error(a, 0)
	end
	return a, b
end

local function snapshotVisibility(character)
	local snap = {}
	for _, d in ipairs(character:GetDescendants()) do
		if d:IsA("BasePart") and not isInsideAccessoryOrTool(d) then
			snap[d.Name] = d.Transparency
		end
	end
	return snap
end

local function snapshotPartSet(character)
	local set = setmetatable({}, { __mode = "k" })
	for _, d in ipairs(character:GetDescendants()) do
		if d:IsA("BasePart") and not isInsideAccessoryOrTool(d) then
			set[d] = true
		end
	end
	return set
end

local function dedupeBodyParts(character, before)
	local jointed = {}
	local groups = {}
	for _, d in ipairs(character:GetDescendants()) do
		if d:IsA("Motor6D") and d.Part1 then
			jointed[d.Part1] = true
		end
	end
	local function hasJoint(_, part)
		return jointed[part] == true
	end
	for _, d in ipairs(character:GetDescendants()) do
		if d:IsA("BasePart") and BODY_COLOR_MAP[d.Name] and not isInsideAccessoryOrTool(d) then
			local list = groups[d.Name]
			if not list then
				list = {}
				groups[d.Name] = list
			end
			table.insert(list, d)
		end
	end
	for _, list in pairs(groups) do
		if #list > 1 then
			local fresh, stale = {}, {}
			for _, part in ipairs(list) do
				if before[part] then
					table.insert(stale, part)
				else
					table.insert(fresh, part)
				end
			end
			local keeper
			for _, part in ipairs(fresh) do
				if hasJoint(character, part) then
					keeper = part
					break
				end
			end
			if not keeper then
				local linked
				for _, part in ipairs(stale) do
					if hasJoint(character, part) then
						linked = part
						break
					end
				end
				if linked and #fresh > 0 then
					keeper = replaceBodyPart(character, linked, fresh[1])
				else
					keeper = linked or fresh[1] or stale[1]
				end
			end
			for _, part in ipairs(list) do
				if part ~= keeper and part.Parent then
					part:Destroy()
				end
			end
		end
	end
end

local function cleanupAfterChange(character, vis, before)
	dedupeBodyParts(character, before)
	local lockVisibility = gameHidesRig(vis)
	local function reassert()
		if not lockVisibility then
			return
		end
		for _, d in ipairs(character:GetDescendants()) do
			if d:IsA("BasePart") and not isInsideAccessoryOrTool(d) then
				local want = vis[d.Name]
				if want and d.Transparency < want - 0.01 then
					d.Transparency = want
				end
			end
		end
	end
	reassert()
	for _, delayTime in ipairs({ 0.3, 1, 2.5 }) do
		task.delay(delayTime, function()
			if character.Parent then
				reassert()
			end
		end)
	end
end

local function watchDeath(humanoid)
	local t0 = os.clock()
	local conn
	conn = humanoid.Died:Connect(function()
		if conn then
			conn:Disconnect()
		end
		if os.clock() - t0 > DEATH_WINDOW then
			return
		end
		deathStrikes += 1
		if deathStrikes >= MAX_DEATH_STRIKES then
			autoReapply = false
			lastUsername = nil
			requestId += 1
		end
	end)
	task.delay(DEATH_WINDOW, function()
		if conn and conn.Connected then
			conn:Disconnect()
			deathStrikes = 0
		end
	end)
end
local R15 = {}

local ANIM_SLOTS = {
	{ slot = "idle", label = "quieto", prop = "IdleAnimation", typeId = 51 },
	{ slot = "walk", label = "caminar", prop = "WalkAnimation", typeId = 55 },
	{ slot = "run", label = "correr", prop = "RunAnimation", typeId = 53 },
	{ slot = "jump", label = "saltar", prop = "JumpAnimation", typeId = 52 },
	{ slot = "fall", label = "caer", prop = "FallAnimation", typeId = 50 },
	{ slot = "climb", label = "trepar", prop = "ClimbAnimation", typeId = 48 },
	{ slot = "swim", label = "nadar", prop = "SwimAnimation", typeId = 54 },
}
local SLOT_NAMES = { idle = true, walk = true, run = true, jump = true, fall = true, climb = true, swim = true }
local ROBLOX_DEFAULT_ANIMS = {
	idle = { 507766666, 507766951, 507766388 },
	walk = { 507777826 },
	run = { 507767714 },
	jump = { 507765000 },
	fall = { 507767968 },
	climb = { 507765644 },
	swim = { 507784897 },
}
R15.FIXED_ANIMS = {
	climb = 82587632175618,
	fall = 110319921537712,
	idle = 132984592941585,
	idleExtra = 124200992648318,
	jump = 83380602503991,
	run = 90449724957683,
	walk = 106767496454996,
}
local OVERRIDE_FADE_OUT = 0.15
local PRIORITY_LADDER = {
	Enum.AnimationPriority.Core,
	Enum.AnimationPriority.Idle,
	Enum.AnimationPriority.Movement,
	Enum.AnimationPriority.Action,
	Enum.AnimationPriority.Action2,
	Enum.AnimationPriority.Action3,
	Enum.AnimationPriority.Action4,
}

local function priorityAbove(priority)
	for i, item in ipairs(PRIORITY_LADDER) do
		if item == priority then
			return PRIORITY_LADDER[math.min(i + 1, #PRIORITY_LADDER)]
		end
	end
	return Enum.AnimationPriority.Movement
end

local function numericAnimId(value)
	if type(value) == "number" then
		return value
	end
	local text = tostring(value or "")
	local fromQuery = string.match(text, "[?&]id=(%d+)")
	if fromQuery then
		return tonumber(fromQuery)
	end
	local last
	for digits in string.gmatch(text, "%d+") do
		last = digits
	end
	return last and tonumber(last) or nil
end

local AnimTable = {}

function AnimTable.fromDescription(description)
	local t = { ids = {}, names = {}, source = {} }
	for _, s in ipairs(ANIM_SLOTS) do
		local ok, value = pcall(function()
			return description[s.prop]
		end)
		if ok and type(value) == "number" and value ~= 0 then
			t.ids[s.slot] = value
			t.source[s.slot] = "descripcion"
		end
	end
	return t
end

function AnimTable.forceFixed(t)
	t.ids = t.ids or {}
	t.source = t.source or {}
	for _, slot in ipairs({ "idle", "walk", "run", "jump", "fall", "climb" }) do
		t.ids[slot] = R15.FIXED_ANIMS[slot]
		t.source[slot] = "fijo"
	end
	t.idleExtra = R15.FIXED_ANIMS.idleExtra
	t.fixed = true
	return t
end

function AnimTable.build(userId, username, description, targetPlayer)
	local t = AnimTable.fromDescription(description)
	local okInfo, info = pcall(function()
		return Players:GetCharacterAppearanceInfoAsync(userId)
	end)
	if okInfo and type(info) == "table" and type(info.assets) == "table" then
		for _, asset in ipairs(info.assets) do
			local assetType = type(asset) == "table" and asset.assetType
			local typeId = type(assetType) == "table" and assetType.id or nil
			local typeName = type(assetType) == "table" and type(assetType.name) == "string"
				and string.lower((assetType.name:gsub("%s", ""))) or nil
			for _, s in ipairs(ANIM_SLOTS) do
				if typeId == s.typeId or typeName == string.lower(s.prop) then
					t.names[s.slot] = asset.name
					if not t.ids[s.slot] and type(asset.id) == "number" and asset.id ~= 0 then
						t.ids[s.slot] = asset.id
						t.source[s.slot] = "apariencia"
					end
				end
			end
		end
	end
	if targetPlayer then
		local live = R15.readLiveAnimations(targetPlayer)
		for _, entry in ipairs(ANIM_MAP) do
			local slot = entry[1]
			local value = live[entry[1] .. "/" .. entry[2]]
			if SLOT_NAMES[slot] and value and not t.ids[slot] then
				local id = numericAnimId(value)
				if id and id ~= 0 then
					t.ids[slot] = id
					t.source[slot] = "jugador en el servidor"
				end
			end
		end
		local liveIdle1 = numericAnimId(live["idle/Animation1"])
		local liveIdle2 = numericAnimId(live["idle/Animation2"])
		if liveIdle2 and liveIdle2 ~= 0 and liveIdle1 == t.ids.idle then
			t.idleExtra = liveIdle2
		end
	end

	if t.ids.walk and not t.ids.run then
		t.ids.run = t.ids.walk
		t.source.run = "copiado de caminar"
	elseif t.ids.run and not t.ids.walk then
		t.ids.walk = t.ids.run
		t.source.walk = "copiado de correr"
	end
	AnimTable.forceFixed(t)
	return t
end

function AnimTable.probe(animator, id, deadline)
	local animation = Instance.new("Animation")
	animation.AnimationId = "rbxassetid://" .. tostring(id)
	local okLoad, track = pcall(function()
		return animator:LoadAnimation(animation)
	end)
	if not okLoad or not track then
		animation:Destroy()
		return nil
	end
	while os.clock() < deadline do
		local okLen, len = pcall(function()
			return track.Length
		end)
		if okLen and len and len > 0 then
			break
		end
		task.wait(0.05)
	end
	local length, looped = 0, nil
	pcall(function()
		length = track.Length
		looped = track.Looped
	end)
	pcall(function()
		track:Destroy()
	end)
	animation:Destroy()
	if length and length > 0 then
		return length, looped
	end
	return nil
end

function AnimTable.resolve(id)
	local okObjects, objects = pcall(function()
		return game:GetObjects("rbxassetid://" .. tostring(id))
	end)
	if not okObjects or type(objects) ~= "table" then
		return nil
	end
	local found
	for _, obj in ipairs(objects) do
		if obj:IsA("Animation") then
			found = obj
		else
			found = obj:FindFirstChildWhichIsA("Animation", true)
		end
		if found then
			break
		end
	end
	local result = found and numericAnimId(found.AnimationId) or nil
	for _, obj in ipairs(objects) do
		pcall(function()
			obj:Destroy()
		end)
	end
	return result
end

function AnimTable.fillMissing(t)
	if t.ids.walk and not t.ids.run then
		t.ids.run = t.ids.walk
		t.source.run = "copiado de caminar"
	elseif t.ids.run and not t.ids.walk then
		t.ids.walk = t.ids.run
		t.source.walk = "copiado de correr"
	end
end

function AnimTable.validate(humanoid, t)
	t.lengths = {}
	if t.fixed then
		return
	end
	local animator = humanoid:FindFirstChildOfClass("Animator") or humanoid:WaitForChild("Animator", 2)
	if not animator then

		return
	end
	local entries = {}
	for slot, id in pairs(t.ids) do
		table.insert(entries, { slot = slot, id = id })
	end
	if t.idleExtra then
		table.insert(entries, { slot = "idle2", id = t.idleExtra })
	end
	local pending = #entries
	local deadline = os.clock() + 4
	for _, entry in ipairs(entries) do
		task.spawn(function()
			local length, looped = AnimTable.probe(animator, entry.id, deadline)
			if not length then
				local realId = AnimTable.resolve(entry.id)
				if realId and realId ~= entry.id then
					length, looped = AnimTable.probe(animator, realId, os.clock() + 2)
					if length then
						entry.resolvedFrom = entry.id
						entry.id = realId
					end
				end
			end
			entry.length, entry.looped = length, looped
			pending -= 1
		end)
	end
	local guard = os.clock() + 9
	while pending > 0 and os.clock() < guard do
		task.wait(0.05)
	end
	for _, entry in ipairs(entries) do
		if entry.length then
			if entry.slot == "idle2" then
				t.idleExtra = entry.id
			else
				t.ids[entry.slot] = entry.id
			end
			t.lengths[entry.id] = entry.length

		else

			if entry.slot == "idle2" then
				t.idleExtra = nil
			else
				t.ids[entry.slot] = nil
			end
		end
	end
	AnimTable.fillMissing(t)
end

function R15.animateTracks(character, humanoid)
	local animate = character:FindFirstChild("Animate")
	local animator = humanoid:FindFirstChildOfClass("Animator")
	local list = {}
	if not animate or not animator then
		return list, animate, animator
	end
	local okTracks, tracks = pcall(function()
		return animator:GetPlayingAnimationTracks()
	end)
	if okTracks then
		for _, track in ipairs(tracks) do
			local anim = track.Animation
			if anim and anim:IsDescendantOf(animate) then
				table.insert(list, track)
			end
		end
	end
	return list, animate, animator
end

function R15.animationsHealthy(character, humanoid, animTable)
	local list, animate, animator = R15.animateTracks(character, humanoid)
	if not animate or not animator then
		return true, "sin Animate/Animator, nada que comprobar"
	end
	if humanoid.Health <= 0 then
		return true, "personaje muerto"
	end
	if #list == 0 then
		return false, "ninguna animación del Animate se está reproduciendo"
	end
	local lengths = animTable and animTable.lengths or {}
	local before = {}
	for _, track in ipairs(list) do
		local expected = lengths[numericAnimId(track.Animation.AnimationId)]
		if expected and math.abs(track.Length - expected) > 0.02 then
			return false, "se reproduce una pista cargada con un id anterior (" .. tostring(track.Animation.Name) .. ")"
		end
		before[track] = track.TimePosition
	end
	task.wait(0.3)
	for _, track in ipairs(list) do
		local okMoving = pcall(function()
			if track.IsPlaying and track.Length > 0.1 and track.Speed ~= 0 and track.WeightCurrent > 0.05 then
				if track.TimePosition == before[track] then
					error("frozen")
				end
			end
		end)
		if not okMoving then
			return false, "la pose está congelada (" .. tostring(track.Animation.Name) .. ")"
		end
	end
	return true, "ok"
end

local function animateIsEnabled(animate)
	local okEnabled, enabled = pcall(function()
		return animate.Enabled
	end)
	if okEnabled and type(enabled) == "boolean" then
		return enabled
	end
	local okDisabled, disabled = pcall(function()
		return animate.Disabled
	end)
	if okDisabled and type(disabled) == "boolean" then
		return not disabled
	end
	return true
end

function R15.reloadAnimate(character, humanoid)
	local list, old = R15.animateTracks(character, humanoid)
	if not old then
		return false
	end
	local previous = old.Archivable
	pcall(function()
		old.Archivable = true
	end)
	local copy
	local okClone = pcall(function()
		copy = old:Clone()
	end)
	pcall(function()
		old.Archivable = previous
	end)
	if not okClone or not copy then
		return false
	end
	for _, track in ipairs(list) do
		pcall(function()
			track:Stop(0)
		end)
	end
	old:Destroy()
	task.wait()
	if not character.Parent then
		copy:Destroy()
		return false
	end
	copy.Parent = character
	return true
end

function R15.rebuildAnimator(character, humanoid)
	local old = humanoid:FindFirstChildOfClass("Animator")
	if old then
		local okTracks, tracks = pcall(function()
			return old:GetPlayingAnimationTracks()
		end)
		if okTracks then
			for _, track in ipairs(tracks) do
				pcall(function()
					track:Stop(0)
				end)
			end
		end
		pcall(function()
			old:Destroy()
		end)
		task.wait()
	end
	local fresh = Instance.new("Animator")
	fresh.Parent = humanoid
	return fresh
end

local driverState = nil

function R15.stopDriver()
	local d = driverState
	driverState = nil
	if not d then
		return
	end
	for _, connection in ipairs(d.conns) do
		pcall(function()
			connection:Disconnect()
		end)
	end
	for _, track in pairs(d.tracks) do
		pcall(function()
			track:Stop(0.1)
			track:Destroy()
		end)
	end
	for _, anim in ipairs(d.anims) do
		pcall(function()
			anim:Destroy()
		end)
	end
	if d.animate and d.animate.Parent then
		setAnimateEnabled(d.animate, true)
	end
end

function R15.startDriver(character, humanoid, animTable)
	R15.stopDriver()
	local root = character:FindFirstChild("HumanoidRootPart")
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not root or not animator then
		return false
	end
	local animate = character:FindFirstChild("Animate")
	if animate then
		setAnimateEnabled(animate, false)
	end
	local okPlaying, playing = pcall(function()
		return animator:GetPlayingAnimationTracks()
	end)
	if okPlaying then
		for _, track in ipairs(playing) do
			pcall(function()
				track:Stop(0.1)
			end)
		end
	end
	local d = { tracks = {}, anims = {}, conns = {}, current = nil, name = nil, animate = animate }
	driverState = d
	local ids = animTable and animTable.ids or {}
	local looped = { idle = true, walk = true, run = true, fall = true, climb = true, swim = true }
	for slot in pairs(SLOT_NAMES) do
		local id = ids[slot]
		if not id then
			local list = ROBLOX_DEFAULT_ANIMS[slot]
			id = list and list[1]
		end
		if id then
			local anim = Instance.new("Animation")
			anim.AnimationId = "rbxassetid://" .. tostring(id)
			table.insert(d.anims, anim)
			local okLoad, track = pcall(function()
				return animator:LoadAnimation(anim)
			end)
			if okLoad and track then
				if looped[slot] then
					pcall(function()
						track.Looped = true
					end)
				end
				d.tracks[slot] = track
			end
		end
	end
	local function play(name, speed)
		local track = d.tracks[name]
		if not track then
			name = "idle"
			track = d.tracks.idle
		end
		if not track then
			return
		end
		if d.name ~= name then
			if d.current then
				pcall(function()
					d.current:Stop(0.2)
				end)
			end
			pcall(function()
				track:Play(0.2)
			end)
			d.current = track
			d.name = name
		end
		if speed then
			pcall(function()
				track:AdjustSpeed(speed)
			end)
		end
	end
	local function halt()
		if d.current then
			pcall(function()
				d.current:Stop(0.2)
			end)
			d.current = nil
			d.name = nil
		end
	end
	table.insert(d.conns, RunService.Heartbeat:Connect(function()
		if driverState ~= d or humanoid.Health <= 0 or not root.Parent then
			return
		end
		local state = humanoid:GetState()
		local velocity = root.AssemblyLinearVelocity
		local planar = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
		if state == Enum.HumanoidStateType.Jumping then
			play("jump", 1)
		elseif state == Enum.HumanoidStateType.Freefall then
			local jumpTrack = d.tracks.jump
			local jumping = d.name == "jump" and jumpTrack and jumpTrack.IsPlaying
				and jumpTrack.TimePosition < jumpTrack.Length - 0.05
			if not jumping then
				play("fall", 1)
			end
		elseif state == Enum.HumanoidStateType.Climbing then
			play("climb", math.clamp(velocity.Y / 5, -3, 3))
		elseif state == Enum.HumanoidStateType.Swimming then
			play("swim", 1)
		elseif state == Enum.HumanoidStateType.Seated
			or state == Enum.HumanoidStateType.Dead
			or state == Enum.HumanoidStateType.PlatformStanding
			or state == Enum.HumanoidStateType.FallingDown
			or state == Enum.HumanoidStateType.Ragdoll
			or state == Enum.HumanoidStateType.Physics then
			halt()
		elseif planar > 0.75 then
			local name = (d.tracks.run and ids.run and planar > 21) and "run" or "walk"
			play(name, math.clamp(planar / 16, 0.4, 2.2))
		else
			play("idle", 1)
		end
	end))
	table.insert(d.conns, character.AncestryChanged:Connect(function(_, parent)
		if not parent and driverState == d then
			R15.stopDriver()
		end
	end))
	return true
end

function R15.driverMoving()
	local d = driverState
	if not d or not d.current then
		return true
	end
	local before = d.current.TimePosition
	task.wait(0.25)
	if driverState ~= d or not d.current then
		return true
	end
	return d.current.TimePosition ~= before or d.current.Length <= 0.1
end

function R15.finalizeAnimations(character, humanoid, description, targetPlayer, animTable, isCurrent)
	if not isCurrent() then
		return
	end
	R15.stopDriver()
	local changed = R15.applyAnimations(character, humanoid, description, targetPlayer, animTable) or 0
	if changed > 0 then
		R15.reloadAnimate(character, humanoid)
	end
	task.wait(0.7)
	if not isCurrent() then
		return
	end
	if R15.animationsHealthy(character, humanoid, animTable) then
		return
	end
	local animate = character:FindFirstChild("Animate")
	if not animate or not animateIsEnabled(animate) then
		return
	end
	local steps = {
		function()
			R15.reloadAnimate(character, humanoid)
		end,
		function()
			R15.rebuildAnimator(character, humanoid)
			R15.reloadAnimate(character, humanoid)
		end,
	}
	for _, run in ipairs(steps) do
		if not isCurrent() then
			return
		end
		pcall(run)
		task.wait(1)
		if not isCurrent() then
			return
		end
		if R15.animationsHealthy(character, humanoid, animTable) then
			return
		end
	end
	if not isCurrent() then
		return
	end
	if R15.startDriver(character, humanoid, animTable) then
		task.wait(0.6)
		if isCurrent() and not R15.driverMoving() then
			R15.rebuildAnimator(character, humanoid)
			if isCurrent() then
				R15.startDriver(character, humanoid, animTable)
			end
		end
	end
end

function R15.manualAttach(accessory, character)
	local handle = accessory:FindFirstChild("Handle")
	if not handle or not handle:IsA("BasePart") then
		return false
	end
	local handleAttachment = findHandleAttachment(handle)
	if not handleAttachment then
		return false
	end
	local characterAttachment = findCharacterAttachment(character, handleAttachment.Name)
	if not characterAttachment then
		return false
	end
	accessory.Parent = character
	handle.Anchored = false
	handle.CanCollide = false
	handle.Massless = true
	handle.CFrame = characterAttachment.Parent.CFrame
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

function R15.wipeAppearance(character)
	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("Accessory")
			or child:IsA("Hat")
			or child:IsA("Clothing")
			or child:IsA("ShirtGraphic")
			or child:IsA("CharacterMesh")
			or child:IsA("BodyColors") then
			child:Destroy()
		elseif child:IsA("BasePart") then
			for _, sub in ipairs(child:GetChildren()) do
				if sub:IsA("Decal")
					or sub:IsA("SurfaceAppearance")
					or sub:IsA("DataModelMesh")
					or sub:IsA("FaceControls")
					or sub:IsA("WrapTarget")
					or sub:IsA("WrapLayer") then
					sub:Destroy()
				end
			end
		end
	end
end

function R15.copyVisual(part, donorPart)
	part.Color = donorPart.Color
	part.Material = donorPart.Material
	part.Reflectance = donorPart.Reflectance
	part.Transparency = donorPart.Transparency
end

function R15.copyPartChildren(part, donorPart)
	for _, d in ipairs(donorPart:GetChildren()) do
		if d:IsA("Attachment") then
			local mine = part:FindFirstChild(d.Name)
			if mine and mine:IsA("Attachment") then
				mine.CFrame = d.CFrame
			else
				d:Clone().Parent = part
			end
		elseif d:IsA("SurfaceAppearance")
			or d:IsA("FaceControls")
			or d:IsA("WrapTarget")
			or d:IsA("WrapLayer")
			or d:IsA("Decal")
			or d:IsA("DataModelMesh") then
			d:Clone().Parent = part
		end
	end
end

function R15.replaceBodyPart(character, oldPart, donorPart)
	local newPart = donorPart:Clone()
	for _, child in ipairs(newPart:GetChildren()) do
		if child:IsA("Motor6D") or child:IsA("Weld") then
			child:Destroy()
		end
	end
	newPart.CFrame = oldPart.CFrame
	newPart.Anchored = false
	newPart.CanCollide = oldPart.CanCollide
	newPart.CanTouch = oldPart.CanTouch
	newPart.CanQuery = oldPart.CanQuery
	newPart.Massless = oldPart.Massless
	newPart.Parent = character
	for _, d in ipairs(character:GetDescendants()) do
		if d:IsA("Motor6D") then
			if d.Part1 == oldPart then
				d.Part1 = newPart
				d.Parent = newPart
			end
			if d.Part0 == oldPart then
				d.Part0 = newPart
			end
		end
	end
	oldPart:Destroy()
	return newPart
end

function R15.needsFullReplace(donorPart)
	return donorPart:FindFirstChildWhichIsA("Bone", true) ~= nil
end

function R15.syncPart(character, donorPart)
	local part = character:FindFirstChild(donorPart.Name)
	if not (part and part:IsA("BasePart")) then
		return nil
	end
	if part:IsA("MeshPart") and donorPart:IsA("MeshPart") and not R15.needsFullReplace(donorPart) then
		local same = part.MeshId == donorPart.MeshId
		if not same then
			pcall(function()
				part:ApplyMesh(donorPart)
			end)
			same = part.MeshId == donorPart.MeshId
		end
		if same then
			part.TextureID = donorPart.TextureID
			part.Size = donorPart.Size
			R15.copyVisual(part, donorPart)
			R15.copyPartChildren(part, donorPart)
			return part
		end
	end
	return R15.replaceBodyPart(character, part, donorPart)
end

function R15.applyDonorData(character, humanoid, donor, faceSources)
	R15.wipeAppearance(character)
	for _, donorPart in ipairs(donor:GetChildren()) do
		if donorPart:IsA("BasePart") and donorPart.Name ~= "HumanoidRootPart" then
			R15.syncPart(character, donorPart)
		end
	end
	for _, donorMotor in ipairs(donor:GetDescendants()) do
		if donorMotor:IsA("Motor6D") and donorMotor.Part1 then
			local owner = character:FindFirstChild(donorMotor.Part1.Name)
			local motor = owner and owner:FindFirstChild(donorMotor.Name)
			if motor and motor:IsA("Motor6D") then
				motor.C0 = donorMotor.C0
				motor.C1 = donorMotor.C1
			end
		end
	end
	local head = character:FindFirstChild("Head")
	if head and head:IsA("BasePart") then
		applyFace(head, faceSources)
	end
	local donorColors = donor:FindFirstChildOfClass("BodyColors")
	if donorColors then
		local newColors = donorColors:Clone()
		newColors.Parent = character
		applyManualBodyColors(character, newColors)
	end
	for _, child in ipairs(donor:GetChildren()) do
		if child:IsA("Shirt")
			or child:IsA("Pants")
			or child:IsA("ShirtGraphic")
			or child:IsA("CharacterMesh") then
			child:Clone().Parent = character
		end
	end
	local result = {}
	for _, template in ipairs(donor:GetChildren()) do
		if template:IsA("Accessory") then
			local accessory = template:Clone()
			local handle = accessory:FindFirstChild("Handle")
			if handle then
				local donorWeld = handle:FindFirstChild("AccessoryWeld")
				if donorWeld then
					donorWeld:Destroy()
				end
			end
			local added = pcall(function()
				humanoid:AddAccessory(accessory)
			end)
			handle = accessory:FindFirstChild("Handle")
			if not (added and handle and handle:FindFirstChild("AccessoryWeld")) then
				R15.manualAttach(accessory, character)
			end
			result[template] = accessory
		end
	end
	return result
end

function R15.readLiveAnimations(targetPlayer)
	local live = {}
	pcall(function()
		local targetCharacter = targetPlayer and targetPlayer.Character
		local targetHumanoid = targetCharacter and targetCharacter:FindFirstChildOfClass("Humanoid")
		if not targetHumanoid or targetHumanoid.RigType ~= Enum.HumanoidRigType.R15 then
			return
		end
		local animate = targetCharacter:FindFirstChild("Animate")
		if not animate then
			return
		end
		for _, entry in ipairs(ANIM_MAP) do
			local folder = animate:FindFirstChild(entry[1])
			local anim = folder and folder:FindFirstChild(entry[2])
			if anim and anim:IsA("Animation") and anim.AnimationId ~= "" then
				live[entry[1] .. "/" .. entry[2]] = anim.AnimationId
			end
		end
	end)
	return live
end

function R15.applyAnimations(character, humanoid, description, targetPlayer, animTable)
	local animate = character:FindFirstChild("Animate") or character:WaitForChild("Animate", 1)
	if not animate then

		return
	end
	captureDefaultAnims(character)
	local defaults = defaultAnims[character] or {}
	local touched = {}
	for _, entry in ipairs(ANIM_MAP) do
		local folderName, animName = entry[1], entry[2]
		local key = folderName .. "/" .. animName
		local id = animTable and animTable.ids[folderName]
		if folderName == "idle" and animName == "Animation2" and animTable and animTable.idleExtra then
			id = animTable.idleExtra
		end
		local newId = id and ("rbxassetid://" .. tostring(id)) or defaults[key]
		local folder = animate:FindFirstChild(folderName)
		local anim = folder and folder:FindFirstChild(animName)
		if newId then
			if not folder then
				folder = Instance.new("StringValue")
				folder.Name = folderName
				folder:SetAttribute("AFO_Created", true)
				folder.Parent = animate
			end
			if not (anim and anim:IsA("Animation")) then
				anim = Instance.new("Animation")
				anim.Name = animName
				anim:SetAttribute("AFO_Created", true)
				anim.Parent = folder
			end
			if anim.AnimationId ~= newId then
				anim.AnimationId = newId
				table.insert(touched, anim)
			end
		elseif anim and anim:GetAttribute("AFO_Created") then
			anim:Destroy()
			if folder and folder:GetAttribute("AFO_Created") and #folder:GetChildren() == 0 then
				folder:Destroy()
			end
		end
	end

	if #touched > 0 then
		local loaded = false
		task.spawn(function()
			pcall(function()
				ContentProvider:PreloadAsync(touched)
			end)
			loaded = true
		end)
		local waited = 0
		while not loaded and waited < 2 do
			task.wait(0.05)
			waited += 0.05
		end
	end
	return #touched
end

function R15.forceFixed(character, humanoid)
	if not character or not humanoid or humanoid.RigType ~= Enum.HumanoidRigType.R15 then
		return
	end
	local animate = character:FindFirstChild("Animate") or character:WaitForChild("Animate", 5)
	if not animate then
		return
	end
	local t = AnimTable.forceFixed({ ids = {}, source = {} })
	local changed = R15.applyAnimations(character, humanoid, nil, nil, t) or 0
	if changed > 0 and character.Parent then
		R15.reloadAnimate(character, humanoid)
	end
end

function R15.measureHipHeight(character, root)
	local poses = computePoses(character)
	local lowest
	for part, pose in pairs(poses) do
		if part ~= root and part:IsA("BasePart") and not isInsideAccessoryOrTool(part) then
			local low = pose.Position.Y - verticalExtent(pose, part.Size)
			lowest = lowest and math.min(lowest, low) or low
		end
	end
	if not lowest then
		return nil
	end
	local hip = -lowest - root.Size.Y / 2
	if hip < 0.3 or hip > 15 then
		return nil
	end
	return hip
end

function R15.syncRoot(character, humanoid, donor)
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	local hip = R15.measureHipHeight(character, root)
	if not hip then
		local donorRoot = donor:FindFirstChild("HumanoidRootPart")
		local donorHumanoid = donor:FindFirstChildOfClass("Humanoid")
		if donorRoot and donorHumanoid then
			hip = math.max(donorHumanoid.HipHeight + donorRoot.Size.Y / 2 - root.Size.Y / 2, 0)
		end
	end
	if hip then

		pcall(function()
			humanoid.HipHeight = hip
		end)
	end
end

function R15.swap(character, humanoid, donor, description, targetPlayer, animTable, faceSources)
	R15.applyDonorData(character, humanoid, donor, faceSources)
	R15.syncRoot(character, humanoid, donor)
end

local function applyAvatar(username, isReset, animated, onFail, force)
	if not localPlayer or not username or username == "" then
		return
	end
	username = trim(username)
	local quietFlash = false
	if not force and not isReset then
		local shown = lastUsername or localPlayer.Name
		if username:lower() == shown:lower() then
			quietFlash = true
			animated = false
		end
	end
	if not force then
		autoReapply = true
	end
	task.spawn(function()
		local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
		local humanoid = character:WaitForChild("Humanoid", 10)
		if not humanoid then
			return
		end
		local root = character:WaitForChild("HumanoidRootPart", 10)
		if not root then
			return
		end
		captureOriginals(character, humanoid)
		local userId = getUserId(username)
		if not userId then
			if onFail then
				onFail()
			end
			return
		end
		requestId += 1
		local currentRequest = requestId
		local previousUsername = lastUsername
		lastUsername = username
		loadAvatarImage(userId, currentRequest)
		if quietFlash then
			softFlash()
		end
		if animated then
			ensureGray(character)
			playSfx(SFX_START, SFX_START_VOLUME)
			startSfxLoop()
		end
		local function stillValid()
			return currentRequest == requestId
				and localPlayer.Character == character
				and character.Parent ~= nil
				and humanoid.Health > 0
		end
		local function fail()
			if currentRequest == requestId then
				lastUsername = previousUsername
				releaseGray(false)
				if onFail then
					onFail()
				end
			end
		end
		local rigType = getRigType(character, humanoid)
		local isR15 = rigType == Enum.HumanoidRigType.R15
		local description
		if isReset and originalDescriptions[character] then
			description = originalDescriptions[character]:Clone()
		else
			description = getDescription(userId)
		end
		if not stillValid() then
			return
		end
		if not description then
			fail()
			return
		end
		local targetPlayer = nil
		if isR15 and not isReset then
			targetPlayer = Players:GetPlayerByUserId(userId)
			if targetPlayer == localPlayer then
				targetPlayer = nil
			end
		end
		local animTable = nil
		if isR15 then
			animTable = AnimTable.build(userId, username, description, targetPlayer)
			if not stillValid() then
				return
			end
		end

		local animReady = true
		if isR15 and animTable then
			animReady = false
			task.spawn(function()
				local okValidate, errValidate = pcall(AnimTable.validate, humanoid, animTable)
				if not okValidate then

				end
				animReady = true
			end)
		end
		local faceSources = { reset = isReset, original = isReset and originalFaces[character] or nil }
		local faceReady = false
		task.spawn(function()
			faceSources.resolved = prefetchFace(userId, description)
			faceReady = true
			if faceSources.swapped and currentRequest == requestId and character.Parent then
				local head = findPart(character, "Head")
				if head and head:IsA("BasePart") then
					applyFace(head, faceSources, true)
				end
			end
		end)
		local useDescription = (not isR15) and USE_APPLY_DESCRIPTION_R6 and humanoid.RigType == rigType
		local donor, skinDonor
		local function buildDonor(rigOverride)
			local d = callMethod(
				Players,
				{ "CreateHumanoidModelFromDescriptionAsync", "CreateHumanoidModelFromDescription" },
				description,
				rigOverride or rigType
			)
			if not d then
				return nil
			end
			if not d:FindFirstChildOfClass("Humanoid") then
				d:Destroy()
				return nil
			end
			local preloaded = false
			task.spawn(function()
				pcall(function()
					ContentProvider:PreloadAsync(d:GetDescendants())
				end)
				preloaded = true
			end)
			local waited = 0
			while not preloaded and waited < 8 do
				task.wait(0.1)
				waited += 0.1
			end
			return d
		end
		local function cleanupDonors()
			if donor then
				donor:Destroy()
			end
			if skinDonor then
				skinDonor:Destroy()
			end
		end
		if not useDescription then
			donor = buildDonor()
			if not stillValid() then
				cleanupDonors()
				return
			end
			if not donor then
				fail()
				return
			end
			if (not isR15) and R6_SKIN_FALLBACK and hasCustomBody(description) then
				skinDonor = buildDonor(Enum.HumanoidRigType.R15)
				if not stillValid() then
					cleanupDonors()
					return
				end
			end
		end
		local animWait = os.clock()
		while not animReady and os.clock() - animWait < 12 do
			task.wait(0.05)
		end
		local faceWait = os.clock()
		while not faceReady and os.clock() - faceWait < 4 do
			task.wait(0.05)
		end
		if not waitTransformFree(currentRequest) or not stillValid() then
			cleanupDonors()
			return
		end
		local function doSwap()
			local records
			if isR15 then
				R15.swap(character, humanoid, donor, description, targetPlayer, animTable, faceSources)
			else
				records = applyDonorData(character, humanoid, donor, {
					description = description,
					skinDonor = skinDonor,
					faceSources = faceSources,
				})
			end
			scheduleFaceChecks(character, faceSources, currentRequest)
			sanitizeAccessories(character)
			pcall(repairAccessoryFx, character, donor)
			fixColorsDeferred(character, currentRequest)
			guardAccessories(character, humanoid, records, currentRequest)
		end
		local function performChangeInner()
			if useDescription then
				local ok = applyDescriptionToCharacter(character, humanoid, description)
				if ok then
					sanitizeAccessories(character)
					return true
				end
				if not stillValid() then
					return false
				end
			end
			if not donor then
				donor = buildDonor()
			end
			if not donor then
				return false
			end
			doSwap()
			return true
		end
		local function performChange()
			removeSkin(character)
			local vis = snapshotVisibility(character)
			local before = snapshotPartSet(character)
			local okSwap, result = pcall(guardedSwap, humanoid, performChangeInner)
			pcall(cleanupAfterChange, character, vis, before)
			if not okSwap then
				error(result, 0)
			end
			if result == true then
				watchDeath(humanoid)
			end
			return result
		end
		local function finishChange()
			if donor then
				pcall(repairAccessoryFx, character, donor)
			end
			recoverCharacter(character, humanoid)

			if isR15 and animTable then
				task.spawn(function()
					local okFinal, errFinal = pcall(R15.finalizeAnimations, character, humanoid, description, targetPlayer, animTable, function()
						return currentRequest == requestId and character.Parent ~= nil and humanoid.Health > 0
					end)
					if not okFinal then

					end
				end)
			end
		end
		if not animated then
			transforming = true
			local okChange, changed = pcall(performChange)
			finishChange()
			cleanupDonors()
			transforming = false
			return
		end
		transforming = true
		local completed = false
		local changeDone, changeOk = false, false
		local vortex
		pcall(function()
			local function valid()
				return stillValid() and root.Parent ~= nil
			end
			local oldGhost
			if not isFirstPerson() then
				oldGhost = makeGhost(character, root, humanoid, true)
			end
			local useGhost = oldGhost ~= nil
			if oldGhost then
				visualOwner = currentRequest
				hideCharacter(character)
				retargetGray(getGhostGroup())
			end
			local okFx, fxResult = pcall(beginVortex, character, root)
			if okFx then
				vortex = fxResult
			else

			end
			task.spawn(function()
				local okChange, result = pcall(performChange)
				changeOk = okChange and result == true
				changeDone = true
			end)

			local holdStart = os.clock()
			local waitedChange = 0
			while (not changeDone or os.clock() - holdStart < MORPH_HOLD_MIN) and waitedChange < 25 do
				if not valid() then
					destroyGhost()
					return
				end
				if oldGhost then
					holdGhost(oldGhost, root, humanoid)
				end
				waitedChange += RunService.Heartbeat:Wait()
			end
			if not changeOk then
				destroyGhost()
				return
			end
			finishChange()
			if not valid() then
				destroyGhost()
				return
			end
			if useGhost then
				RunService.Heartbeat:Wait()
				RunService.Heartbeat:Wait()
				local newGhost = makeGhost(character, root, humanoid, false, true)
				if newGhost then
					pairByKey(oldGhost, newGhost)
					if not morphGhosts(oldGhost, newGhost, root, humanoid, MORPH_DURATION, currentRequest, valid) then
						return
					end
				end
			end
			completed = true
		end)
		local waitedClean = 0
		while not changeDone and waitedClean < 25 do
			task.wait(0.05)
			waitedClean += 0.05
		end
		if vortex then
			pcall(vortex.stop)
		end
		if visualOwner == nil or visualOwner == currentRequest then
			destroyGhost()
			showCharacter()
			visualOwner = nil
			transforming = false
		end
		if gray and gray.character == character then
			retargetGray(character)
		end
		fixCamera(humanoid)
		cleanupDonors()
		if currentRequest == requestId then
			if completed then
				pcall(splash, character, humanoid)
			elseif changeDone and not changeOk then
				lastUsername = previousUsername
				if onFail then
					onFail()
				end
			end
			releaseGray(false)
		end
	end)
end

local function resetToOriginal()
	if not localPlayer then
		return
	end
	applyAvatar(localPlayer.Name, true, true, nil)
end

function M.SetKey(keyCode)
	if typeof(keyCode) ~= "EnumItem" then
		return
	end
	toggleKey = keyCode
	if keys then
		keys.CopyAvatar = keyCode
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
	if activeVortex then
		pcall(activeVortex.stop)
	end
	disconnectAll()
	releaseGray(true)
	clearTransformVisuals()
	if gui then
		gui:Destroy()
	end
	gui = nil
	mainFrame = nil
	playerImage = nil
	setPanelOpen = nil
	isOpen = false
	if restoreAvatar and localPlayer then
		lastUsername = nil
		applyAvatar(localPlayer.Name, true, false, nil)
	end
end

function M.Start(firstArgument, secondArgument, thirdArgument)
	if typeof(firstArgument) == "Instance" and firstArgument:IsA("Player") then
		localPlayer = firstArgument
		keys = secondArgument
	else
		keys = firstArgument
		localPlayer = secondArgument or Players.LocalPlayer
	end
	if not localPlayer then
		return false
	end
	local defaultAvatar = type(thirdArgument) == "string" and thirdArgument or localPlayer.Name
	if defaultAvatar == "" then
		defaultAvatar = localPlayer.Name
	end
	if keys then
		local configuredKey = keys.CopyAvatar or keys.Toggle
		if typeof(configuredKey) == "EnumItem" then
			toggleKey = configuredKey
		end
	end
	requestId += 1
	autoReapply = true
	deathStrikes = 0
	preloadSfx()
	disconnectAll()
	releaseGray(true)
	clearTransformVisuals()
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
	lastUsername = nil
	gui = Instance.new("ScreenGui")
	gui.Name = "AFO_AvatarChanger"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = playerGui
	mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainPanel"
	mainFrame.Size = UDim2.new(0, PANEL_W, 0, PANEL_H)
	mainFrame.AnchorPoint = Vector2.new(1, 0)
	mainFrame.Position = UDim2.new(1, PANEL_W + 40, 0, 190)
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
	closeButton.Position = UDim2.new(1, -30, 0, 10)
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
	textBox.Size = UDim2.new(0, BOX_W, 0, 28)
	textBox.Position = UDim2.new(0, 15, 0, 42)
	textBox.BackgroundColor3 = C_BOX
	textBox.BackgroundTransparency = 0.3
	textBox.TextColor3 = C_TEXT
	textBox.PlaceholderColor3 = C_SUB
	textBox.PlaceholderText = "Username..."
	textBox.Text = defaultAvatar
	textBox.Font = Enum.Font.Gotham
	textBox.TextSize = MAX_TEXT
	textBox.TextXAlignment = Enum.TextXAlignment.Left
	textBox.ClipsDescendants = true
	textBox.BorderSizePixel = 0
	textBox.ClearTextOnFocus = false
	textBox.Parent = mainFrame
	Instance.new("UICorner", textBox).CornerRadius = UDim.new(0, 4)
	local boxPadding = Instance.new("UIPadding")
	boxPadding.PaddingLeft = UDim.new(0, 8)
	boxPadding.PaddingRight = UDim.new(0, 8)
	boxPadding.Parent = textBox
	local boxStroke = Instance.new("UIStroke")
	boxStroke.Color = C_PURPLE
	boxStroke.Thickness = 1
	boxStroke.Transparency = 0.7
	boxStroke.Parent = textBox
	local applyButton = Instance.new("TextButton")
	applyButton.Size = UDim2.new(0, 150, 0, 26)
	applyButton.Position = UDim2.new(0, 15, 0, 82)
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
	resetButton.Size = UDim2.new(0, 35, 0, 26)
	resetButton.Position = UDim2.new(0, 170, 0, 82)
	resetButton.BackgroundColor3 = Color3.fromRGB(80, 20, 140)
	resetButton.BackgroundTransparency = 0.2
	resetButton.TextColor3 = Color3.new(1, 1, 1)
	resetButton.Font = Enum.Font.GothamBold
	resetButton.TextSize = 14
	resetButton.Text = "🔄"
	resetButton.BorderSizePixel = 0
	resetButton.Parent = mainFrame
	Instance.new("UICorner", resetButton).CornerRadius = UDim.new(0, 4)
	local hint = Instance.new("TextLabel")
	hint.Size = UDim2.new(1, -30, 0, 12)
	hint.Position = UDim2.new(0, 15, 0, 112)
	hint.BackgroundTransparency = 1
	hint.Font = Enum.Font.Gotham
	hint.TextSize = 9
	hint.TextColor3 = C_SUB
	hint.TextTransparency = 0.35
	hint.TextXAlignment = Enum.TextXAlignment.Left
	hint.Text = 'Tip: "Nickname"'
	hint.Parent = mainFrame
	local imageContainer = Instance.new("Frame")
	imageContainer.Size = UDim2.new(0, 55, 0, 55)
	imageContainer.Position = UDim2.new(1, -70, 0, 34)
	imageContainer.BackgroundColor3 = C_BOX
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
	local menu = Instance.new("Frame")
	menu.Name = "NicknameMenu"
	menu.Size = UDim2.new(1, 0, 0, 0)
	menu.Position = UDim2.new(0, 0, 1, 6)
	menu.BackgroundColor3 = C_BLACK
	menu.BackgroundTransparency = 0.15
	menu.BorderSizePixel = 0
	menu.ClipsDescendants = true
	menu.ZIndex = 10
	menu.Parent = mainFrame
	Instance.new("UICorner", menu).CornerRadius = UDim.new(0, 8)
	local menuStroke = Instance.new("UIStroke")
	menuStroke.Color = C_PURPLE
	menuStroke.Thickness = 1
	menuStroke.Transparency = 0.5
	menuStroke.Parent = menu
	local list = Instance.new("ScrollingFrame")
	list.Size = UDim2.new(1, -8, 1, -8)
	list.Position = UDim2.new(0, 4, 0, 4)
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.ScrollBarThickness = 3
	list.ScrollBarImageColor3 = C_PURPLE
	list.CanvasSize = UDim2.new()
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.ZIndex = 11
	list.Parent = menu
	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 4)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Parent = list
	local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	setPanelOpen = function(open)
		if not active or not mainFrame or not mainFrame.Parent then
			return
		end
		isOpen = open
		local position = isOpen and UDim2.new(1, -20, 0, 190) or UDim2.new(1, PANEL_W + 40, 0, 190)
		TweenService:Create(mainFrame, tweenInfo, { Position = position }):Play()
	end
	local function togglePanel()
		setPanelOpen(not isOpen)
	end
	local function fitText()
		local text = textBox.Text
		local available = BOX_W - 16
		local size = MAX_TEXT
		while size > MIN_TEXT do
			local bounds = TextService:GetTextSize(text, size, textBox.Font, Vector2.new(10000, 100))
			if bounds.X <= available then
				break
			end
			size -= 1
		end
		textBox.TextSize = size
	end
	fitText()
	local errorToken = 0
	local function flashError()
		if not textBox or not textBox.Parent then
			return
		end
		errorToken += 1
		local token = errorToken
		textBox.BackgroundColor3 = Color3.fromRGB(190, 60, 70)
		textBox.BackgroundTransparency = 0.25
		boxStroke.Color = Color3.fromRGB(255, 110, 120)
		boxStroke.Transparency = 0.1
		task.spawn(function()
			for _, dx in ipairs({ 4, -4, 3, -3, 0 }) do
				if not textBox.Parent then
					return
				end
				textBox.Position = UDim2.new(0, 15 + dx, 0, 42)
				task.wait(0.04)
			end
		end)
		task.delay(0.35, function()
			if token ~= errorToken or not textBox.Parent then
				return
			end
			local info = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			TweenService:Create(textBox, info, {
				BackgroundColor3 = C_BOX,
				BackgroundTransparency = 0.3,
			}):Play()
			TweenService:Create(boxStroke, info, {
				Color = C_PURPLE,
				Transparency = 0.7,
			}):Play()
		end)
	end
	local menuOpen = false
	local function clearRows()
		for _, child in ipairs(list:GetChildren()) do
			if child:IsA("GuiObject") then
				child:Destroy()
			end
		end
	end
	local function closeMenu()
		if not menuOpen then
			return
		end
		menuOpen = false
		TweenService:Create(menu, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Size = UDim2.new(1, 0, 0, 0),
		}):Play()
		task.delay(0.3, function()
			if not menuOpen and list.Parent then
				clearRows()
			end
		end)
	end
	local function submitUsername(username)
		closeMenu()
		username = trim(username)
		if username == "" then
			flashError()
			return
		end
		applyAvatar(username, false, true, flashError)
	end
	local function openMenu(results)
		clearRows()
		menuOpen = true
		list.CanvasPosition = Vector2.zero
		for index, player in ipairs(results) do
			local row = Instance.new("TextButton")
			row.LayoutOrder = index
			row.Size = UDim2.new(1, -6, 0, ROW_H)
			row.BackgroundColor3 = C_BOX
			row.BackgroundTransparency = 0.3
			row.BorderSizePixel = 0
			row.AutoButtonColor = false
			row.Text = ""
			row.ZIndex = 12
			row.Parent = list
			Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)
			local avatarHolder = Instance.new("Frame")
			avatarHolder.Size = UDim2.new(0, 40, 0, 40)
			avatarHolder.Position = UDim2.new(0, 6, 0, 6)
			avatarHolder.BackgroundColor3 = C_BLACK
			avatarHolder.BorderSizePixel = 0
			avatarHolder.ZIndex = 13
			avatarHolder.Parent = row
			Instance.new("UICorner", avatarHolder).CornerRadius = UDim.new(1, 0)
			local avatarImage = Instance.new("ImageLabel")
			avatarImage.Size = UDim2.fromScale(1, 1)
			avatarImage.BackgroundTransparency = 1
			avatarImage.ZIndex = 14
			avatarImage.Parent = avatarHolder
			Instance.new("UICorner", avatarImage).CornerRadius = UDim.new(1, 0)
			local nick = Instance.new("TextLabel")
			nick.Size = UDim2.new(1, -60, 0, 20)
			nick.Position = UDim2.new(0, 54, 0, 7)
			nick.BackgroundTransparency = 1
			nick.Font = Enum.Font.GothamBold
			nick.TextSize = 13
			nick.TextColor3 = C_TEXT
			nick.TextXAlignment = Enum.TextXAlignment.Left
			nick.TextTruncate = Enum.TextTruncate.AtEnd
			nick.Text = player.DisplayName
			nick.ZIndex = 13
			nick.Parent = row
			local real = Instance.new("TextLabel")
			real.Size = UDim2.new(1, -60, 0, 16)
			real.Position = UDim2.new(0, 54, 0, 28)
			real.BackgroundTransparency = 1
			real.Font = Enum.Font.Gotham
			real.TextSize = 11
			real.TextColor3 = C_SUB
			real.TextXAlignment = Enum.TextXAlignment.Left
			real.TextTruncate = Enum.TextTruncate.AtEnd
			real.Text = "@" .. player.Name
			real.ZIndex = 13
			real.Parent = row
			task.spawn(function()
				local ok, image = pcall(function()
					return Players:GetUserThumbnailAsync(
						player.UserId,
						Enum.ThumbnailType.HeadShot,
						Enum.ThumbnailSize.Size100x100
					)
				end)
				if ok and image and avatarImage.Parent then
					avatarImage.Image = image
				end
			end)
			row.MouseEnter:Connect(function()
				TweenService:Create(row, TweenInfo.new(0.12), { BackgroundTransparency = 0.05 }):Play()
			end)
			row.MouseLeave:Connect(function()
				TweenService:Create(row, TweenInfo.new(0.12), { BackgroundTransparency = 0.3 }):Play()
			end)
			row.MouseButton1Click:Connect(function()
				textBox.Text = player.Name
				submitUsername(player.Name)
			end)
		end
		local visibleRows = math.min(#results, MENU_MAX_ROWS)
		local height = visibleRows * (ROW_H + 4) + 8
		menu.Size = UDim2.new(1, 0, 0, 0)
		TweenService:Create(menu, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Size = UDim2.new(1, 0, 0, height),
		}):Play()
	end
	local function searchPlayers(query)
		local q = query:lower()
		local found = {}
		for _, player in ipairs(Players:GetPlayers()) do
			local dn, un = player.DisplayName:lower(), player.Name:lower()
			local score = 0
			if dn == q or un == q then
				score = 4
			elseif dn:sub(1, #q) == q or un:sub(1, #q) == q then
				score = 3
			elseif dn:find(q, 1, true) or un:find(q, 1, true) then
				score = 2
			end
			if score > 0 then
				table.insert(found, { player = player, score = score })
			end
		end
		table.sort(found, function(a, b)
			if a.score ~= b.score then
				return a.score > b.score
			end
			return a.player.DisplayName:lower() < b.player.DisplayName:lower()
		end)
		local results = {}
		for i = 1, math.min(#found, MAX_RESULTS) do
			results[i] = found[i].player
		end
		return results
	end
	local function parseInput(text)
		text = trim(text)
		text = (text:gsub("\u{201C}", '"'):gsub("\u{201D}", '"'))
		local prefixed = text:match("^%s*[%w_]+%s*:%s*(.+)$") or text:match("^%s*@(.+)$")
		if prefixed then
			return trim(prefixed), true
		end
		local inside = text:match('^"(.-)"?$')
		if inside then
			return trim(inside), true
		end
		return text, false
	end
	local function submit()
		local queryText, isNicknameSearch = parseInput(textBox.Text)
		if queryText == "" then
			flashError()
			return
		end
		if isNicknameSearch then
			local results = searchPlayers(queryText)
			if #results > 0 then
				openMenu(results)
				return
			end
		end
		local userId = getUserId(queryText)
		if userId then
			closeMenu()
			applyAvatar(queryText, false, true, flashError)
		else
			local results = searchPlayers(queryText)
			if #results > 0 then
				openMenu(results)
			else
				closeMenu()
				flashError()
			end
		end
	end
	table.insert(connections, textBox:GetPropertyChangedSignal("Text"):Connect(fitText))
	table.insert(connections, localPlayer.CharacterAdded:Connect(function(character)
		task.spawn(function()
			local hum = character:WaitForChild("Humanoid", 10)
			character:WaitForChild("HumanoidRootPart", 10)
			if not hum or not active then
				return
			end
			task.wait(1)
			if localPlayer.Character == character then
				pcall(R15.forceFixed, character, hum)
			end
		end)
		if active and autoReapply and lastUsername and lastUsername:lower() ~= localPlayer.Name:lower() then
			task.spawn(function()
				character:WaitForChild("Humanoid", 10)
				character:WaitForChild("HumanoidRootPart", 10)
				local t = 0
				while not localPlayer:HasAppearanceLoaded() and t < 10 do
					task.wait(0.2)
					t += 0.2
				end
				task.wait(0.5)
				if active and autoReapply and lastUsername and localPlayer.Character == character then
					applyAvatar(lastUsername, false, false, nil, true)
				end
			end)
		end
	end))
	table.insert(connections, applyButton.MouseButton1Click:Connect(submit))
	table.insert(connections, textBox.FocusLost:Connect(function(enterPressed)
		if enterPressed then
			submit()
		end
	end))
	table.insert(connections, resetButton.MouseButton1Click:Connect(function()
		closeMenu()
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
	if defaultAvatar:lower() == localPlayer.Name:lower() then
		loadAvatarImage(localPlayer.UserId, requestId)
	else
		applyAvatar(defaultAvatar, false, false, flashError)
	end
	return true
end
return M
