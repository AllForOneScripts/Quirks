print("seriously?3433")

local M = {}
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ContentProvider = game:GetService("ContentProvider")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")
local Debris = game:GetService("Debris")
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
local quietUntil = 0
local gray = nil
local descriptionCache = {}
local defaultAnims = setmetatable({}, { __mode = "k" })
local originalHip = setmetatable({}, { __mode = "k" })
local ownedAccessories = setmetatable({}, { __mode = "k" })
local protectedAccessories = setmetatable({}, { __mode = "k" })
local trackedCharacters = setmetatable({}, { __mode = "k" })
local originalDescriptions = setmetatable({}, { __mode = "k" })
local applyingChange = false
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
local MIN_FACTOR = 0.7
local SHRINK_TIME = 0.55
local GROW_TIME = 0.75
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
local PRESERVE_GAME_ACCESSORIES = true
local KEEP_NAME_PATTERNS = { "crown", "corona" }
local GUARD_SECONDS = 6
local GUARD_INTERVAL = 0.35
local MAX_REPAIRS = 3
local USE_APPLY_DESCRIPTION_R15 = true
local USE_APPLY_DESCRIPTION_R6 = false
local DEATH_WINDOW = 8
local MAX_DEATH_STRIKES = 2
local DESCRIPTION_TIMEOUT = 20
local R6_SKIN_FALLBACK = true
local COPY_BODY_SCALES = true
local function clamp01(x)
	return math.clamp(x, 0, 1)
end

local function easeInBack(t)
	t = clamp01(t)
	local c1 = 1.2
	return (c1 + 1) * t ^ 3 - c1 * t ^ 2
end
local function easeOutBack(t)
	t = clamp01(t)
	local c1 = 1.70158
	local c3 = c1 + 1
	return 1 + c3 * (t - 1) ^ 3 + c1 * (t - 1) ^ 2
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
local hideState = nil
local ghostState = nil
local STRIP_CLASSES = {
	"BaseScript",
	"ModuleScript",
	"Sound",
	"ForceField",
	"Tool",
	"Highlight",
	"BillboardGui",
	"ProximityPrompt",
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
local function hideStep()
	local state = hideState
	if not state then
		return
	end
	local character = state.character
	if not character or not character.Parent then
		return
	end
	local saved = state.saved
	for _, d in ipairs(character:GetDescendants()) do
		if d:IsA("BasePart") then
			local parent = d.Parent
			if not (parent and parent:IsA("Tool")) then
				if saved[d] == nil then
					local init = state.initial[d]
					saved[d] = (init ~= nil) and init or 0
				end
				d.LocalTransparencyModifier = 1
			end
		elseif isFxInstance(d) then
			if state.fx[d] == nil then
				state.fx[d] = d.Enabled
				if d:IsA("ParticleEmitter") then
					pcall(function()
						d:Clear()
					end)
				end
			end
			if d.Enabled then
				d.Enabled = false
			end
		end
	end
end
local function ensureVisible(character, initial)
	if not character or not character.Parent then
		return
	end
	if hideState and hideState.character == character then
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
	for inst, wasEnabled in pairs(state.fx) do
		if inst.Parent then
			pcall(function()
				inst.Enabled = wasEnabled
			end)
		end
	end
	local target = state.character
	if target and target.Parent then
		for _, d in ipairs(target:GetDescendants()) do
			if d:IsA("BasePart") then
				d.LocalTransparencyModifier = state.saved[d] or 0
			end
		end
		for _, delayTime in ipairs({ 0.05, 0.4, 1.2 }) do
			task.delay(delayTime, function()
				ensureVisible(target, state.initial)
			end)
		end
	end
end
local function hideCharacter(character)
	showCharacter()
	hideState = {
		character = character,
		saved = setmetatable({}, { __mode = "k" }),
		fx = setmetatable({}, { __mode = "k" }),
		initial = setmetatable({}, { __mode = "k" }),
	}
	for _, d in ipairs(character:GetDescendants()) do
		if d:IsA("BasePart") then
			hideState.initial[d] = d.LocalTransparencyModifier
		end
	end
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
end
local function clearTransformVisuals()
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
local function scaleSequence(sequence, k)
	local points = {}
	for i, keypoint in ipairs(sequence.Keypoints) do
		points[i] = NumberSequenceKeypoint.new(keypoint.Time, keypoint.Value * k, keypoint.Envelope * k)
	end
	return NumberSequence.new(points)
end

local function makeGhost(character, root)
	destroyGhost()
	local state = hideState and hideState.character == character and hideState or nil
	local hiddenPaths = {}
	local fxStates = {}
	for _, d in ipairs(character:GetDescendants()) do
		if d:IsA("BasePart") then
			local ltm
			if state then
				ltm = state.saved[d]
				if ltm == nil then
					ltm = state.initial[d] or 0
				end
			else
				ltm = d.LocalTransparencyModifier
			end
			if ltm >= 0.95 then
				hiddenPaths[relPath(d, character)] = true
			end
		elseif isFxInstance(d) then
			local enabled = d.Enabled
			if state and state.fx[d] ~= nil then
				enabled = state.fx[d]
			end
			fxStates[relPath(d, character)] = enabled
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
	for _, d in ipairs(clone:GetDescendants()) do
		if isFxInstance(d) then
			local enabled = fxStates[relPath(d, clone)]
			if enabled ~= nil then
				d.Enabled = enabled
			end
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
					orig = d.Size,
					pos = rel.Position,
					rot = rel - rel.Position,
					meshes = {},
					seed = math.random() * 6.28,
				}
				for _, child in ipairs(d:GetChildren()) do
					if child:IsA("SpecialMesh") and child.MeshType == Enum.MeshType.FileMesh then
						table.insert(item.meshes, { mesh = child, orig = child.Scale })
					end
				end
				table.insert(items, item)
				itemOf[d] = item
			end
		end
	end
	for _, d in ipairs(clone:GetDescendants()) do
		if d:IsA("ParticleEmitter") then
			local owner = d:FindFirstAncestorWhichIsA("BasePart")
			local item = owner and itemOf[owner]
			if item then
				item.emitters = item.emitters or {}
				table.insert(item.emitters, { emitter = d, size = d.Size })
			end
		end
	end
	for _, d in ipairs(clone:GetDescendants()) do
		if d:IsA("JointInstance") or d:IsA("WeldConstraint") or d:IsA("Constraint") then
			d:Destroy()
		end
	end
	local minY
	for _, item in ipairs(items) do
		if item.part.Transparency < 0.95 then
			local r = item.rot
			local s = item.orig
			local extent = (math.abs(r.RightVector.Y) * s.X + math.abs(r.UpVector.Y) * s.Y + math.abs(r.LookVector.Y) * s.Z) / 2
			local low = item.pos.Y - extent
			if not minY or low < minY then
				minY = low
			end
		end
	end
	clone.Name = "AFO_Ghost"
	clone.Parent = workspace.CurrentCamera or workspace
	local g = { model = clone, items = items, pivot = Vector3.new(0, minY or -3, 0) }
	ghostState = g
	return g
end
local function poseGhostItem(g, item, k, sizeMul, followCF)
	local part = item.part
	if not part or not part.Parent then
		return
	end
	part.Size = item.orig * sizeMul
	for _, entry in ipairs(item.meshes) do
		if entry.mesh.Parent then
			entry.mesh.Scale = entry.orig * sizeMul
		end
	end
	if item.emitters and math.abs(k - (item.lastK or -1)) > 0.004 then
		item.lastK = k
		for _, entry in ipairs(item.emitters) do
			if entry.emitter.Parent then
				entry.emitter.Size = scaleSequence(entry.size, k)
			end
		end
	end
	local pivot = g.pivot
	part.CFrame = followCF * (CFrame.new(pivot + (item.pos - pivot) * k) * item.rot)
end
local function animateGhost(g, root, grow, id, isValid)
	local dur = grow and GROW_TIME or SHRINK_TIME
	return runPhase(dur, function(alpha)
		local followCF = root.CFrame
		local k
		if grow then
			k = MIN_FACTOR + (1 - MIN_FACTOR) * easeOutBack(alpha)
		else
			k = 1 - (1 - MIN_FACTOR) * easeInBack(alpha)
		end
		k = math.max(k, MIN_FACTOR)
		local envelope = math.sin(alpha * math.pi)
		for _, item in ipairs(g.items) do
			local w = math.sin(alpha * 9 + item.seed) * 0.03 * envelope
			poseGhostItem(g, item, k, Vector3.new(k * (1 + w), k * (1 - w * 0.5), k * (1 + w)), followCF)
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
local function isProtectedAccessory(accessory)
	if ownedAccessories[accessory] then
		return false
	end
	if PRESERVE_GAME_ACCESSORIES and protectedAccessories[accessory] then
		return true
	end
	if accessory:GetAttribute("AFO_Keep") then
		return true
	end
	local lname = accessory.Name:lower()
	for _, pattern in ipairs(KEEP_NAME_PATTERNS) do
		if lname:find(pattern, 1, true) then
			return true
		end
	end
	return false
end
local function trackCharacter(character)
	if not active or not PRESERVE_GAME_ACCESSORIES or trackedCharacters[character] then
		return
	end
	local state = { settled = false }
	trackedCharacters[character] = state
	task.spawn(function()
		local t = 0
		while localPlayer and not localPlayer:HasAppearanceLoaded() and t < 10 do
			task.wait(0.2)
			t += 0.2
		end
		task.wait(1.5)
		state.settled = true
	end)
	table.insert(connections, character.ChildAdded:Connect(function(child)
		if state.settled and not applyingChange and not transforming and os.clock() > quietUntil
			and child:IsA("Accessory") and not ownedAccessories[child] then
			protectedAccessories[child] = true
		end
	end))
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
local function guessPartForAttachment(character, attName, isR15)
	local n = attName or ""
	if n:find("Hat") or n:find("Hair") or n:find("Face") then
		return findPart(character, "Head")
	end
	return findPart(character, isR15 and "UpperTorso" or "Torso")
end
local function fallbackWeld(character, accessory, handle, info, isR15)
	local handleAttachment = findHandleAttachment(handle)
	local part, c0, c1
	if info then
		part = findPart(character, info.partName)
		if part then
			c0, c1 = info.c0, info.c1
		end
	end
	if not part then
		part = guessPartForAttachment(character, handleAttachment and handleAttachment.Name, isR15)
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
local function attachAccessory(character, humanoid, template, info, isR15)
	local accessory = template:Clone()
	ownedAccessories[accessory] = true
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
	local okFallback = pcall(fallbackWeld, character, accessory, handle, info, isR15)
	if okFallback and isAttached(character, accessory) then
		return accessory
	end
	accessory:Destroy()
	return nil
end
local function guardAccessories(character, humanoid, records, isR15, id)
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
					rec.accessory = attachAccessory(character, humanoid, rec.backup, rec.info, isR15)
				end
			end
		end
	end)
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
		if child:IsA("Accessory") then
			if not isProtectedAccessory(child) then
				child:Destroy()
			end
		elseif child:IsA("Clothing")
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
local function meshIdOf(handle)
	if handle:IsA("MeshPart") then
		return handle.MeshId
	end
	local mesh = handle:FindFirstChildOfClass("SpecialMesh")
	return mesh and mesh.MeshId or ""
end
local function duplicatesProtected(character, template)
	local templateHandle = template:FindFirstChild("Handle")
	local templateMesh = templateHandle and meshIdOf(templateHandle) or ""
	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("Accessory") and isProtectedAccessory(child) then
			if child.Name == template.Name then
				return true
			end
			local handle = child:FindFirstChild("Handle")
			if handle and handle:IsA("BasePart") and templateMesh ~= "" and meshIdOf(handle) == templateMesh then
				return true
			end
		end
	end
	return false
end

local function copyPartChildren(part, donorPart)
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
			for _, existing in ipairs(part:GetChildren()) do
				if existing.ClassName == d.ClassName and (not d:IsA("Decal") or existing.Name == d.Name) then
					existing:Destroy()
				end
			end
			d:Clone().Parent = part
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
	if hideState and hideState.saved[oldPart] ~= nil then
		hideState.saved[newPart] = hideState.saved[oldPart]
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
local function meshKey(id)
	local text = tostring(id or "")
	return text:match("id=(%d+)") or text:match("rbxassetid://(%d+)") or text:match("(%d+)$") or text
end

local function needsFullReplace(donorPart)
	return donorPart:FindFirstChildWhichIsA("FaceControls") ~= nil
		or donorPart:FindFirstChildWhichIsA("Bone", true) ~= nil
end
local function syncR15Part(character, donorPart)
	local part = findPart(character, donorPart.Name)
	if not part then
		return nil
	end
	if donorPart.Name == "Head" and needsFullReplace(donorPart) then
		return replaceBodyPart(character, part, donorPart)
	end
	if donorPart:IsA("MeshPart") and not part:IsA("MeshPart") then
		return replaceBodyPart(character, part, donorPart)
	end
	if part:IsA("MeshPart") and donorPart:IsA("MeshPart") then
		if meshKey(part.MeshId) ~= meshKey(donorPart.MeshId) then
			pcall(function()
				part:ApplyMesh(donorPart)
			end)
			if meshKey(part.MeshId) ~= meshKey(donorPart.MeshId) then
				pcall(function()
					part.MeshId = donorPart.MeshId
				end)
			end
		end
		if meshKey(part.MeshId) ~= meshKey(donorPart.MeshId) then
			return replaceBodyPart(character, part, donorPart)
		end
		part.TextureID = donorPart.TextureID
	end
	part.Size = donorPart.Size
	copyPartChildren(part, donorPart)
	return part
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
local function copyDecalsFrom(source, head)
	local found = false
	if source then
		for _, c in ipairs(source:GetChildren()) do
			if c:IsA("Decal") and c.Texture ~= "" then
				c:Clone().Parent = head
				found = true
			end
		end
	end
	return found
end
local function newFaceDecal(head, texture)
	local face = Instance.new("Decal")
	face.Name = "face"
	face.Face = Enum.NormalId.Front
	face.Texture = texture
	face.Parent = head
	return face
end
local function applyFace(head, donorHead, description, skinDonor, isR15)
	if isR15 and isDynamicHead(head) then
		for _, child in ipairs(head:GetChildren()) do
			if child:IsA("Decal") then
				child:Destroy()
			end
		end
		return
	end
	if hasFaceDecal(head) then
		return
	end
	if copyDecalsFrom(donorHead, head) then
		return
	end
	if copyDecalsFrom(skinDonor and skinDonor:FindFirstChild("Head"), head) then
		return
	end
	local faceId = description and description.Face
	if faceId and faceId ~= 0 then
		newFaceDecal(head, "rbxassetid://" .. tostring(faceId))
		return
	end
	newFaceDecal(head, "rbxasset://textures/face.png")
end
local SCALE_MAP = {
	{ "BodyHeightScale", "HeightScale" },
	{ "BodyWidthScale", "WidthScale" },
	{ "BodyDepthScale", "DepthScale" },
	{ "HeadScale", "HeadScale" },
	{ "BodyTypeScale", "BodyTypeScale" },
	{ "BodyProportionScale", "ProportionScale" },
}
local function verifyScales(humanoid, description)
	if not description then
		return
	end
	for _, entry in ipairs(SCALE_MAP) do
		local ok, wanted = pcall(function()
			return description[entry[2]]
		end)
		local value = humanoid:FindFirstChild(entry[1])
		if ok and type(wanted) == "number" and value and value:IsA("NumberValue") then
			if math.abs(value.Value - wanted) > 0.001 then
				value.Value = wanted
			end
		end
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
local function hasCustomBody(description)
	if not description then
		return false
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
			return true
		end
	end
	return false
end
local SKIN_STRIP = { "Motor6D", "Weld", "Attachment", "FaceControls", "Bone", "WrapTarget", "WrapLayer" }
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
		for _, group in ipairs(R6_GROUPS) do
			local ok, id = pcall(function()
				return description[group.descKey]
			end)
			if ok and type(id) == "number" and id ~= 0 and not donorHasNative(donor, group.bodyPart) then
				applySkinGroup(character, skinDonor, group, poses)
			end
		end
	end
end
local function fixNeck(character)
	local head = findPart(character, "Head")
	if not head or not isDynamicHead(head) then
		return
	end
	for _, d in ipairs(character:GetDescendants()) do
		if d:IsA("Motor6D") and d.Name == "Neck" and d.Part1 == head and d.Part0 then
			local a0 = d.Part0:FindFirstChild("NeckRigAttachment")
			local a1 = head:FindFirstChild("NeckRigAttachment")
			if a0 and a1 and a0:IsA("Attachment") and a1:IsA("Attachment") then
				d.C0 = a0.CFrame
				d.C1 = a1.CFrame
			end
			return
		end
	end
end

local function syncBodyGeometry(character, donor)
	for _, donorPart in ipairs(donor:GetChildren()) do
		if donorPart:IsA("BasePart") and donorPart.Name ~= "HumanoidRootPart" then
			syncR15Part(character, donorPart)
		end
	end
	local donorRoot = donor:FindFirstChild("HumanoidRootPart")
	local myRoot = character:FindFirstChild("HumanoidRootPart")
	if donorRoot and donorRoot:IsA("BasePart") and myRoot and myRoot:IsA("BasePart") then
		pcall(function()
			myRoot.Size = donorRoot.Size
		end)
	end
	for _, donorMotor in ipairs(donor:GetDescendants()) do
		if donorMotor:IsA("Motor6D") and donorMotor.Part1 then
			local owner = findPart(character, donorMotor.Part1.Name)
			local motor = owner and owner:FindFirstChild(donorMotor.Name)
			if motor and motor:IsA("Motor6D") then
				motor.C0 = donorMotor.C0
				motor.C1 = donorMotor.C1
			end
		end
	end
	fixNeck(character)
end

local function bodyMismatch(character, donor)
	for _, donorPart in ipairs(donor:GetChildren()) do
		if donorPart:IsA("BasePart") and donorPart.Name ~= "HumanoidRootPart" then
			local mine = findPart(character, donorPart.Name)
			if not mine then
				return true
			end
			if donorPart:IsA("MeshPart") and (not mine:IsA("MeshPart") or meshKey(mine.MeshId) ~= meshKey(donorPart.MeshId)) then
				return true
			end
			if (mine.Size - donorPart.Size).Magnitude > 0.15 then
				return true
			end
		end
	end
	return false
end

local function applyDonorData(character, humanoid, donor, isR15, extra)
	removeSkin(character)
	local keepTransparency = {}
	for _, d in ipairs(character:GetDescendants()) do
		if d:IsA("BasePart") and not isInsideAccessoryOrTool(d) then
			keepTransparency[d.Name] = d.Transparency
		end
	end
	wipeAppearance(character)
	if isR15 then
		syncBodyGeometry(character, donor)
	else
		adaptR15ToR6(character, donor, extra)
	end
	local head = findPart(character, "Head")
	local donorHead = donor:FindFirstChild("Head")
	if head and not head:GetAttribute("AFO_Skinned") then
		if not isR15 and not head:FindFirstChildOfClass("DataModelMesh") then
			local mesh = Instance.new("SpecialMesh")
			mesh.MeshType = Enum.MeshType.Head
			mesh.Scale = Vector3.new(1.25, 1.25, 1.25)
			mesh.Parent = head
		end
		applyFace(head, donorHead, extra and extra.description, extra and extra.skinDonor, isR15)
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
			local skip = (not isR15 and isLayeredAccessory(template)) or duplicatesProtected(character, template)
			if not skip then
				local info = getWeldInfo(template)
				local accessory = attachAccessory(character, humanoid, template, info, isR15)
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
		if child:IsA("Accessory") and not keep[child] and not isProtectedAccessory(child) then
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
local function restartTracks(animator)
	if not animator then
		return
	end
	local saved = {}
	for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
		table.insert(saved, {
			track = track,
			time = track.TimePosition,
			weight = track.WeightTarget,
			speed = track.Speed,
		})
	end
	for _, rec in ipairs(saved) do
		pcall(function()
			rec.track:Stop(0)
		end)
	end
	RunService.Heartbeat:Wait()
	for _, rec in ipairs(saved) do
		pcall(function()
			rec.track:Play(0.1, rec.weight > 0 and rec.weight or 1, rec.speed)
			rec.track.TimePosition = rec.time
		end)
	end
end
local animationCache = {}

local function loadAnimationContainer(assetId)
	local cached = animationCache[assetId]
	if cached ~= nil then
		return cached or nil
	end
	local container
	local ok, result = pcall(function()
		return game:GetObjects("rbxassetid://" .. tostring(assetId))
	end)
	if ok and type(result) == "table" and result[1] then
		container = result[1]
	end
	if not container then
		local ok2, model = pcall(function()
			return game:GetService("InsertService"):LoadAsset(assetId)
		end)
		if ok2 and model then
			container = model
		end
	end
	animationCache[assetId] = container or false
	return container
end

local function animationLoads(id)
	local ok, sequence = pcall(function()
		return game:GetService("KeyframeSequenceProvider"):GetKeyframeSequenceAsync(id)
	end)
	return ok and sequence ~= nil
end

local function resolveAnimationId(assetId, animName)
	local container = loadAnimationContainer(assetId)
	if not container then
		local direct = "rbxassetid://" .. tostring(assetId)
		if animationLoads(direct) then
			return direct
		end
		return nil
	end
	local found
	if container:IsA("Animation") then
		found = container.AnimationId
	else
		local fallback
		for _, d in ipairs(container:GetDescendants()) do
			if d:IsA("Animation") and d.AnimationId ~= "" then
				if d.Name == animName then
					found = d.AnimationId
					break
				end
				fallback = fallback or d.AnimationId
			end
		end
		found = found or fallback
	end
	if found and found ~= "" and animationLoads(found) then
		return found
	end
	return nil
end

local function resolveAnimationSet(description)
	local set = {}
	for _, entry in ipairs(ANIM_MAP) do
		local id = description[entry[3]]
		local key = entry[1] .. "/" .. entry[2]
		if type(id) == "number" and id ~= 0 then
			local real = resolveAnimationId(id, entry[2])
			if real then
				set[key] = real
			end
		else
			set[key] = false
		end
	end
	return set
end

local function applyAnimations(character, humanoid, animSet, isR15)
	if not isR15 then
		return
	end
	local animator = humanoid:FindFirstChildOfClass("Animator")
	local animate = character:FindFirstChild("Animate")
	if not animate then
		restartTracks(animator)
		return
	end
	local defaults = defaultAnims[character]
	if not defaults then
		defaults = {}
		for _, entry in ipairs(ANIM_MAP) do
			local folder = animate:FindFirstChild(entry[1])
			local anim = folder and folder:FindFirstChild(entry[2])
			if anim and anim:IsA("Animation") then
				defaults[entry[1] .. "/" .. entry[2]] = anim.AnimationId
			end
		end
		defaultAnims[character] = defaults
	end
	for _, entry in ipairs(ANIM_MAP) do
		local key = entry[1] .. "/" .. entry[2]
		local folder = animate:FindFirstChild(entry[1])
		local anim = folder and folder:FindFirstChild(entry[2])
		if anim and anim:IsA("Animation") then
			local value = animSet and animSet[key]
			local newId
			if value then
				newId = value
			elseif value == false or not animSet then
				newId = defaults[key]
			else
				local current = anim.AnimationId
				if current ~= "" and animationLoads(current) then
					newId = current
				else
					newId = defaults[key]
				end
			end
			if newId and anim.AnimationId ~= newId then
				anim.AnimationId = newId
			end
		end
	end
	if animator then
		for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
			pcall(function()
				track:Stop(0)
			end)
		end
	end
	setAnimateEnabled(animate, false)
	task.wait()
	setAnimateEnabled(animate, true)
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
local function newFxPart(props)
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
	Debris:AddItem(p, 3)
	return p
end
local function splash(character, humanoid)
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	local center = root.Position
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }
	local hit = workspace:Raycast(center, Vector3.new(0, -15, 0), params)
	local groundPos = hit and (hit.Position + Vector3.new(0, 0.1, 0)) or (center - Vector3.new(0, 3, 0))
	if gray then
		gray.boost = 1
	end
	local emitterPart = newFxPart({ Transparency = 1, Size = Vector3.one, Position = center })
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(225, 227, 235)
	light.Brightness = 5
	light.Range = 22
	light.Parent = emitterPart
	TweenService:Create(light, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Brightness = 0,
	}):Play()
	local mist = Instance.new("ParticleEmitter")
	mist.Texture = "rbxasset://textures/particles/smoke_main.dds"
	mist.Color = ColorSequence.new(Color3.fromRGB(190, 192, 200), Color3.fromRGB(120, 122, 130))
	mist.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 2),
		NumberSequenceKeypoint.new(1, 8),
	})
	mist.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.15),
		NumberSequenceKeypoint.new(1, 1),
	})
	mist.Lifetime = NumberRange.new(0.6, 1.1)
	mist.Speed = NumberRange.new(14, 28)
	mist.SpreadAngle = Vector2.new(180, 180)
	mist.Drag = 3
	mist.Rate = 0
	mist.LightEmission = 0.1
	mist.Parent = emitterPart
	mist:Emit(45)
	local ring = newFxPart({
		Shape = Enum.PartType.Cylinder,
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(235, 237, 245),
		Transparency = 0.2,
		Size = Vector3.new(0.15, 2, 2),
		CFrame = CFrame.new(groundPos) * CFrame.Angles(0, 0, math.rad(90)),
	})
	TweenService:Create(ring, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(0.15, 28, 28),
		Transparency = 1,
	}):Play()
	local drops = {}
	for i = 1, 22 do
		local s = 0.35 + math.random() * 0.45
		local part = newFxPart({
			Shape = Enum.PartType.Ball,
			Material = Enum.Material.SmoothPlastic,
			Reflectance = 0.4,
			Color = GRAY_A:Lerp(GRAY_B, math.random()),
			Size = Vector3.new(s * 1.4, s * 0.7, s * 1.4),
			Position = center,
		})
		local dir = Vector3.new(math.random() * 2 - 1, math.random() * 0.8 + 0.3, math.random() * 2 - 1).Unit
		drops[i] = { part = part, vel = dir * (12 + math.random() * 18), size = s }
	end
	local t0 = os.clock()
	local conn
	conn = RunService.Heartbeat:Connect(function(dt)
		local t = os.clock() - t0
		if t > 0.9 then
			conn:Disconnect()
			for _, d in ipairs(drops) do
				d.part:Destroy()
			end
			return
		end
		local k = clamp01((t - 0.45) / 0.4)
		for _, d in ipairs(drops) do
			d.vel += Vector3.new(0, -55 * dt, 0)
			d.part.Position += d.vel * dt
			local stretch = math.max(d.size * (1 - k), 0.02)
			d.part.Size = Vector3.new(stretch * 1.3, stretch * 0.6, stretch * 1.3)
		end
	end)
	local camera = workspace.CurrentCamera
	if camera then
		local fov = camera.FieldOfView
		local out = TweenService:Create(camera, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			FieldOfView = fov + 7,
		})
		out:Play()
		out.Completed:Once(function()
			TweenService:Create(camera, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				FieldOfView = fov,
			}):Play()
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
	originalDescriptions[character] = (ok and desc) or false
	captureDefaultAnims(character)
	if originalHip[character] == nil then
		originalHip[character] = humanoid.HipHeight
	end
end


local function stashProtectedAccessories(character)
	local stash = {}
	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("Accessory") and isProtectedAccessory(child) then
			local rec = { accessory = child }
			local handle = child:FindFirstChild("Handle")
			if handle and handle:IsA("BasePart") then
				for _, j in ipairs(handle:GetChildren()) do
					if j:IsA("JointInstance") and j.Part0 and j.Part1 then
						rec.weld = j
						rec.handleIsPart0 = (j.Part0 == handle)
						rec.partName = rec.handleIsPart0 and j.Part1.Name or j.Part0.Name
						break
					end
				end
			end
			table.insert(stash, rec)
		end
	end
	for _, rec in ipairs(stash) do
		rec.accessory.Parent = nil
	end
	return stash
end
local function restoreProtectedAccessories(character, stash, isR15)
	for _, rec in ipairs(stash) do
		local accessory = rec.accessory
		local handle = accessory:FindFirstChild("Handle")
		accessory.Parent = character
		protectedAccessories[accessory] = true
		if handle and handle:IsA("BasePart") then
			local part = rec.partName and findPart(character, rec.partName)
			if part and rec.weld and rec.weld.Parent then
				if rec.handleIsPart0 then
					rec.weld.Part0 = handle
					rec.weld.Part1 = part
				else
					rec.weld.Part0 = part
					rec.weld.Part1 = handle
				end
			end
			prepareHandle(handle)
			if not isAttached(character, accessory) then
				pcall(fallbackWeld, character, accessory, handle, nil, isR15)
			end
			if not isAttached(character, accessory) then
			end
		end
	end
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
local STANDARD_ATTACHMENTS = {
	FaceCenterAttachment = true,
	FaceFrontAttachment = true,
	HairAttachment = true,
	HatAttachment = true,
	NeckAttachment = true,
	BodyFrontAttachment = true,
	BodyBackAttachment = true,
	LeftCollarAttachment = true,
	RightCollarAttachment = true,
	WaistFrontAttachment = true,
	WaistBackAttachment = true,
	WaistCenterAttachment = true,
	LeftShoulderAttachment = true,
	RightShoulderAttachment = true,
	LeftGripAttachment = true,
	RightGripAttachment = true,
	LeftFootAttachment = true,
	RightFootAttachment = true,
	RootAttachment = true,
}
local function isAppearanceOrRigChild(inst)
	if inst:IsA("Motor6D")
		or inst:IsA("Decal")
		or inst:IsA("Texture")
		or inst:IsA("SurfaceAppearance")
		or inst:IsA("FaceControls")
		or inst:IsA("WrapTarget")
		or inst:IsA("WrapLayer")
		or inst:IsA("Bone")
		or inst:IsA("DataModelMesh")
		or inst:IsA("BodyPartDescription") then
		return true
	end
	if inst.Name == "OriginalSize" or inst.Name == "AvatarPartScaleType" then
		return true
	end
	if inst:IsA("Attachment") then
		return STANDARD_ATTACHMENTS[inst.Name] == true or inst.Name:find("RigAttachment$") ~= nil
	end
	return false
end
local function isBodyPart(part)
	return part:IsA("BasePart")
		and BODY_COLOR_MAP[part.Name] ~= nil
		and not isInsideAccessoryOrTool(part)
end
local function bodyPartName(part)
	if part and isBodyPart(part) then
		return part.Name
	end
	return nil
end
local function stashExtras(character)
	local extras = { children = {}, links = {}, adornees = {} }
	for _, d in ipairs(character:GetDescendants()) do
		if (d:IsA("JointInstance") and not d:IsA("Motor6D")) or d:IsA("WeldConstraint") then
			local owner = d.Parent
			if not (owner and owner:IsA("BasePart") and isInsideAccessoryOrTool(owner)) then
				local n0, n1 = bodyPartName(d.Part0), bodyPartName(d.Part1)
				if n0 or n1 then
					table.insert(extras.links, { joint = d, n0 = n0, n1 = n1 })
				end
			end
		elseif (d:IsA("BillboardGui") or d:IsA("SurfaceGui")) and d.Name ~= GRAY_NAME then
			local name = bodyPartName(d.Adornee)
			if name then
				table.insert(extras.adornees, { gui = d, name = name })
			end
		end
	end
	for _, part in ipairs(character:GetDescendants()) do
		if isBodyPart(part) then
			for _, child in ipairs(part:GetChildren()) do
				if child.Name ~= GRAY_NAME
					and not isAppearanceOrRigChild(child)
					and not child:IsA("BaseScript") then
					table.insert(extras.children, { inst = child, partName = part.Name })
				end
			end
		end
	end
	for _, rec in ipairs(extras.children) do
		rec.inst.Parent = nil
	end
	return extras
end
local function restoreExtras(character, extras)
	local fallback = character:FindFirstChild("HumanoidRootPart")
	for _, rec in ipairs(extras.children) do
		local part = findPart(character, rec.partName) or fallback
		if part then
			pcall(function()
				if rec.inst:IsA("Attachment") and part:FindFirstChild(rec.inst.Name) then
					rec.inst:Destroy()
				else
					rec.inst.Parent = part
				end
			end)
		end
	end
	for _, rec in ipairs(extras.links) do
		local joint = rec.joint
		if joint and joint.Parent then
			pcall(function()
				local p0 = rec.n0 and findPart(character, rec.n0)
				local p1 = rec.n1 and findPart(character, rec.n1)
				if p0 and joint.Part0 ~= p0 then
					joint.Part0 = p0
				end
				if p1 and joint.Part1 ~= p1 then
					joint.Part1 = p1
				end
			end)
		end
	end
	for _, rec in ipairs(extras.adornees) do
		if rec.gui and rec.gui.Parent then
			local part = findPart(character, rec.name)
			if part and rec.gui.Adornee ~= part then
				pcall(function()
					rec.gui.Adornee = part
				end)
			end
		end
	end
end
local function applyDescriptionInner(character, humanoid, description, isR15)
	removeSkin(character)
	local keepTransparency = {}
	for _, d in ipairs(character:GetDescendants()) do
		if d:IsA("BasePart") and not isInsideAccessoryOrTool(d) then
			keepTransparency[d.Name] = d.Transparency
		end
	end
	local stash = PRESERVE_GAME_ACCESSORIES and stashProtectedAccessories(character) or {}
	local extras = PRESERVE_GAME_ACCESSORIES and stashExtras(character) or nil
	applyingChange = true
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
	if COPY_BODY_SCALES and isR15 and done and okRun then
		pcall(verifyScales, humanoid, description)
	end
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
	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("Accessory") then
			ownedAccessories[child] = true
		end
	end
	if extras then
		restoreExtras(character, extras)
	end
	restoreProtectedAccessories(character, stash, isR15)
	return done and okRun
end
local function applyDescriptionToCharacter(character, humanoid, description, isR15)
	local ok, result = pcall(applyDescriptionInner, character, humanoid, description, isR15)
	applyingChange = false
	if not ok then
		error(result, 0)
	end
	return result
end
local function notify(text)
	pcall(function()
		game:GetService("StarterGui"):SetCore("SendNotification", {
			Title = "Avatar Changer",
			Text = text,
			Duration = 8,
		})
	end)
end
local function guardedSwap(humanoid, fn)
	local prevNeck = humanoid.RequiresNeck
	local prevDead = true
	pcall(function()
		prevDead = humanoid:GetStateEnabled(Enum.HumanoidStateType.Dead)
	end)
	pcall(function()
		humanoid.RequiresNeck = false
	end)
	pcall(function()
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
	end)
	local ok, a, b = pcall(fn)
	pcall(function()
		humanoid.RequiresNeck = prevNeck
	end)
	pcall(function()
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, prevDead)
	end)
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
local function cleanupAfterChange(character, vis, before)
	local groups = {}
	for _, d in ipairs(character:GetDescendants()) do
		if d:IsA("BasePart") and not isInsideAccessoryOrTool(d)
			and (BODY_COLOR_MAP[d.Name] or d.Name == "HumanoidRootPart") then
			local list = groups[d.Name]
			if not list then
				list = {}
				groups[d.Name] = list
			end
			table.insert(list, d)
		end
	end
	for name, list in pairs(groups) do
		if #list > 1 then
			local olds = 0
			for _, part in ipairs(list) do
				if before[part] then
					olds += 1
				end
			end
			local keepFirstNew = olds == 0
			for _, part in ipairs(list) do
				if not before[part] then
					if keepFirstNew then
						keepFirstNew = false
					else
						part:Destroy()
					end
				end
			end
		end
	end
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
	for _, delayTime in ipairs({ 0.4, 1.5, 3 }) do
		task.delay(delayTime, function()
			if character.Parent then
				for _, child in ipairs(character:GetChildren()) do
					if child:IsA("Accessory") and not isProtectedAccessory(child) then
						ownedAccessories[child] = true
					end
				end
			end
		end)
	end
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
			notify("El cambio de avatar mataba a tu personaje: se detuvo la reaplicacion automatica. Prueba otra vez con el boton Apply.")
		end
	end)
	task.delay(DEATH_WINDOW, function()
		if conn and conn.Connected then
			conn:Disconnect()
			deathStrikes = 0
		end
	end)
end
local function applyAvatar(username, isReset, animated, onFail, force)
	if not localPlayer or not username or username == "" then
		return
	end
	username = trim(username)
	if not force and not isReset and lastUsername and username:lower() == lastUsername:lower() then
		return
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
		trackCharacter(character)
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
		if animated then
			ensureGray(character)
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
		local useDescription = ((isR15 and USE_APPLY_DESCRIPTION_R15) or (not isR15 and USE_APPLY_DESCRIPTION_R6))
			and humanoid.RigType == rigType
		local description
		if isReset and useDescription and originalDescriptions[character] then
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
		local animSet
		local animReady = not isR15
		if isR15 then
			task.spawn(function()
				local ok, result = pcall(resolveAnimationSet, description)
				if ok then
					animSet = result
				end
				animReady = true
			end)
		end
		local donor, donorHumanoid, skinDonor
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
			local dh = d:FindFirstChildOfClass("Humanoid")
			if not dh then
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
			return d, dh
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
			donor, donorHumanoid = buildDonor()
			if not stillValid() then
				cleanupDonors()
				return
			end
			if not donor then
				fail()
				return
			end
			if not isR15 and R6_SKIN_FALLBACK and hasCustomBody(description) then
				skinDonor = buildDonor(Enum.HumanoidRigType.R15)
				if not stillValid() then
					cleanupDonors()
					return
				end
			end
		end
		if not waitTransformFree(currentRequest) or not stillValid() then
			cleanupDonors()
			return
		end
		local function applyHip()
			if not donorHumanoid then
				return
			end
			if originalHip[character] == nil then
				originalHip[character] = humanoid.HipHeight
			end
			local target = donorHumanoid.HipHeight
			if isReset and originalHip[character] ~= nil then
				target = originalHip[character]
			end
			if math.abs(humanoid.HipHeight - target) > 0.001 then
				humanoid.HipHeight = target
			end
		end
		local function doSwap()
			local records = applyDonorData(character, humanoid, donor, isR15, {
				description = description,
				skinDonor = skinDonor,
			})
			sanitizeAccessories(character)
			if isR15 then
				applyHip()
			end
			fixColorsDeferred(character, currentRequest)
			guardAccessories(character, humanoid, records, isR15, currentRequest)
		end
		local function performChangeInner()
			if useDescription then
				local ok = applyDescriptionToCharacter(character, humanoid, description, isR15)
				if ok then
					sanitizeAccessories(character)
					if isR15 then
						if not donor then
							donor, donorHumanoid = buildDonor()
						end
						if donor and bodyMismatch(character, donor) then
							syncBodyGeometry(character, donor)
							applyHip()
						end
						fixNeck(character)
					end
					return true
				end
				if not stillValid() then
					return false
				end
			end
			if not donor then
				donor, donorHumanoid = buildDonor()
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
		local function finishAnimations()
			local waitedAnim = 0
			while not animReady and waitedAnim < 8 do
				task.wait(0.05)
				waitedAnim += 0.05
			end
			pcall(applyAnimations, character, humanoid, animSet, isR15)
			recoverCharacter(character, humanoid)
		end
		if not animated then
			transforming = true
			pcall(performChange)
			finishAnimations()
			cleanupDonors()
			transforming = false
			quietUntil = os.clock() + 8
			return
		end
		transforming = true
		local completed = false
		local changeDone, changeOk = false, false
		pcall(function()
			local function valid()
				return stillValid() and root.Parent ~= nil
			end
			local oldGhost = makeGhost(character, root)
			local useGhost = oldGhost ~= nil
			if oldGhost then
				hideCharacter(character)
				retargetGray(oldGhost.model)
			end
			task.spawn(function()
				local okChange, result = pcall(performChange)
				changeOk = okChange and result == true
				changeDone = true
			end)
			if oldGhost then
				if not animateGhost(oldGhost, root, false, currentRequest, valid) then
					destroyGhost()
					return
				end
			end
			local waitedChange = 0
			while not changeDone and waitedChange < 25 do
				if not valid() then
					destroyGhost()
					return
				end
				local g = ghostState
				if g then
					local cf = root.CFrame
					for _, item in ipairs(g.items) do
						poseGhostItem(g, item, MIN_FACTOR, Vector3.one * MIN_FACTOR, cf)
					end
				end
				waitedChange += RunService.Heartbeat:Wait()
			end
			if not changeOk then
				destroyGhost()
				return
			end
			finishAnimations()
			if not valid() then
				destroyGhost()
				return
			end
			if useGhost then
				RunService.Heartbeat:Wait()
				RunService.Heartbeat:Wait()
				local newGhost = makeGhost(character, root)
				if newGhost then
					retargetGray(newGhost.model)
					if not animateGhost(newGhost, root, true, currentRequest, valid) then
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
		destroyGhost()
		showCharacter()
		if gray and gray.character == character then
			retargetGray(character)
		end
		cleanupDonors()
		transforming = false
		quietUntil = os.clock() + 8
		if currentRequest == requestId then
			if completed then
				splash(character, humanoid)
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
	table.clear(trackedCharacters)
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
	hint.Text = "Tip: Username"
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
		trackCharacter(character)
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
	if localPlayer.Character then
		trackCharacter(localPlayer.Character)
	end
	if defaultAvatar:lower() == localPlayer.Name:lower() then
		loadAvatarImage(localPlayer.UserId, requestId)
	else
		applyAvatar(defaultAvatar, false, true, flashError)
	end
	return true
end
return M
