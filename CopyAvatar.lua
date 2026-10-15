print("seriously?34")|

local M = {}

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ContentProvider = game:GetService("ContentProvider")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")
local Debris = game:GetService("Debris")
local StarterGui = game:GetService("StarterGui")

local R15, R6 = Enum.HumanoidRigType.R15, Enum.HumanoidRigType.R6

local C_PURPLE = Color3.fromRGB(110, 30, 180)
local C_BLACK = Color3.fromRGB(6, 4, 12)
local C_TEXT = Color3.fromRGB(220, 190, 255)
local C_SUB = Color3.fromRGB(200, 170, 255)
local C_BOX = Color3.fromRGB(20, 10, 40)
local GRAY_A = Color3.fromRGB(125, 127, 134)
local GRAY_B = Color3.fromRGB(208, 210, 218)
local GRAY_NAME = "AFO_GrayLayer"
local HIDE_STEP = "AFO_HideCharacter"

local PANEL_W, PANEL_H, BOX_W = 290, 128, 190
local MAX_TEXT, MIN_TEXT, MAX_RESULTS, ROW_H, MENU_MAX_ROWS = 14, 11, 12, 52, 3
local MIN_SCALE, SHRINK_TIME, GROW_TIME = 0.7, 0.55, 0.75
local ENGINE_R6 = true
local KEEP_NAME_PATTERNS = { "crown", "corona" }
local DEATH_WINDOW, MAX_DEATH_STRIKES, DESCRIPTION_TIMEOUT = 8, 2, 20

local R15_NAMES = { "UpperTorso", "LowerTorso", "LeftUpperArm", "RightUpperArm", "LeftUpperLeg", "RightUpperLeg" }
local R6_NAMES = { "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg" }
local STRIP_CLASSES = { "BaseScript", "ModuleScript", "Sound", "ForceField", "Tool", "Highlight", "BillboardGui", "ProximityPrompt", "Humanoid", "Animator" }
local FX_CLASSES = { "ParticleEmitter", "Trail", "Beam", "Fire", "Smoke", "Sparkles", "Light" }
local RIG_CLASSES = { "Motor6D", "Decal", "Texture", "SurfaceAppearance", "FaceControls", "WrapTarget", "WrapLayer", "Bone", "DataModelMesh", "BodyPartDescription" }
local DESCRIPTION_METHODS = { "ApplyDescriptionResetAsync", "ApplyDescriptionReset", "ApplyDescriptionAsync", "ApplyDescription" }
local SCALES = {
	{ "BodyHeightScale", "HeightScale" },
	{ "BodyWidthScale", "WidthScale" },
	{ "BodyDepthScale", "DepthScale" },
	{ "HeadScale", "HeadScale" },
	{ "BodyTypeScale", "BodyTypeScale" },
	{ "BodyProportionScale", "ProportionScale" },
}

local BODY_COLOR_MAP = { Head = "HeadColor3" }
for _, name in ipairs({ "Torso", "UpperTorso", "LowerTorso" }) do
	BODY_COLOR_MAP[name] = "TorsoColor3"
end
for _, side in ipairs({ "Left", "Right" }) do
	for _, limb in ipairs({ "Arm", "Leg" }) do
		local prop = side .. limb .. "Color3"
		BODY_COLOR_MAP[side .. " " .. limb] = prop
		for _, segment in ipairs(limb == "Arm" and { "UpperArm", "LowerArm", "Hand" } or { "UpperLeg", "LowerLeg", "Foot" }) do
			BODY_COLOR_MAP[side .. segment] = prop
		end
	end
end

local STD_ATTACHMENTS = {}
for name in ("FaceCenter FaceFront Hair Hat Neck BodyFront BodyBack LeftCollar RightCollar WaistFront WaistBack WaistCenter LeftShoulder RightShoulder LeftGrip RightGrip LeftFoot RightFoot Root"):gmatch("%S+") do
	STD_ATTACHMENTS[name .. "Attachment"] = true
end

local function weakTable()
	return setmetatable({}, { __mode = "k" })
end

local localPlayer, keys, gui, mainFrame, playerImage, setPanelOpen, gray, hideState, ghostState, lastUsername
local active, isOpen, transforming, applyingChange, autoReapply = false, false, false, false, true
local requestId, quietUntil, deathStrikes = 0, 0, 0
local toggleKey = Enum.KeyCode.F4
local connections = {}
local descriptionCache = {}
local ownedAccessories, protectedAccessories = weakTable(), weakTable()
local trackedCharacters, originalDescriptions = weakTable(), weakTable()

local function clamp01(x)
	return math.clamp(x, 0, 1)
end

local function easeInBack(t)
	t = clamp01(t)
	return 2.2 * t ^ 3 - 1.2 * t ^ 2
end

local function easeOutBack(t)
	t = clamp01(t)
	return 1 + 2.70158 * (t - 1) ^ 3 + 1.70158 * (t - 1) ^ 2
end

local function disconnectAll()
	for _, connection in ipairs(connections) do
		if connection.Connected then
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

local function new(class, props, parent)
	local inst = Instance.new(class)
	for key, value in pairs(props) do
		inst[key] = value
	end
	inst.Parent = parent
	return inst
end

local function corner(inst, radius)
	return new("UICorner", { CornerRadius = UDim.new(0, radius) }, inst)
end

local function stroke(inst, thickness, transparency)
	return new("UIStroke", { Color = C_PURPLE, Thickness = thickness, Transparency = transparency }, inst)
end

local function isClass(inst, classes)
	for _, className in ipairs(classes) do
		if inst:IsA(className) then
			return true
		end
	end
	return false
end

local function insideItem(inst)
	return inst:FindFirstAncestorWhichIsA("Accessory") ~= nil or inst:FindFirstAncestorWhichIsA("Tool") ~= nil
end

local function isBody(part)
	return part:IsA("BasePart") and BODY_COLOR_MAP[part.Name] ~= nil and not insideItem(part)
end

local function findPart(character, name)
	local direct = character:FindFirstChild(name)
	if direct and direct:IsA("BasePart") then
		return direct
	end
	for _, d in ipairs(character:GetDescendants()) do
		if d.Name == name and d:IsA("BasePart") and not insideItem(d) then
			return d
		end
	end
	return nil
end

local function runWithTimeout(fn, timeout)
	local done = false
	task.spawn(function()
		pcall(fn)
		done = true
	end)
	local waited = 0
	while not done and waited < timeout do
		waited += task.wait(0.05)
	end
	return done
end

local function notify(text)
	pcall(function()
		StarterGui:SetCore("SendNotification", { Title = "Avatar Changer", Text = text, Duration = 8 })
	end)
end

local function countParts(character, names)
	local count = 0
	for _, name in ipairs(names) do
		if findPart(character, name) then
			count += 1
		end
	end
	return count
end

local function getRigType(character, humanoid)
	local root = character:FindFirstChild("HumanoidRootPart")
	if root then
		for _, d in ipairs(character:GetDescendants()) do
			if d:IsA("Motor6D") and (d.Part0 == root or d.Part1 == root) then
				local other = d.Part0 == root and d.Part1 or d.Part0
				if other and other.Name == "LowerTorso" then
					return R15
				elseif other and other.Name == "Torso" then
					return R6
				end
			end
		end
	end
	local r15, r6 = countParts(character, R15_NAMES), countParts(character, R6_NAMES)
	if r15 >= 3 and r6 < 3 then
		return R15
	elseif r6 >= 4 and r15 < 3 then
		return R6
	elseif r15 > 0 or r6 > 0 then
		local s15, s6 = r15 / #R15_NAMES, r6 / #R6_NAMES
		if s15 ~= s6 then
			return s15 > s6 and R15 or R6
		end
	end
	return humanoid.RigType
end

local function getUserId(username)
	username = trim(username)
	if #username < 1 or #username > 20 or not username:match("^[%w_]+$") then
		return nil
	end
	local target = Players:FindFirstChild(username)
	if target and target:IsA("Player") then
		return target.UserId
	end
	local ok, userId = pcall(Players.GetUserIdFromNameAsync, Players, username)
	return ok and userId or nil
end

local function getDescription(userId)
	local cached = descriptionCache[userId]
	if cached and os.clock() - cached.time < 120 then
		return cached.value:Clone()
	end
	local description = callMethod(Players, { "GetHumanoidDescriptionFromUserIdAsync", "GetHumanoidDescriptionFromUserId" }, userId)
	if description then
		descriptionCache[userId] = { value = description, time = os.clock() }
		return description:Clone()
	end
	return nil
end

local function loadAvatarImage(userId, currentRequest)
	task.spawn(function()
		local ok, image = pcall(Players.GetUserThumbnailAsync, Players, userId, Enum.ThumbnailType.AvatarBust, Enum.ThumbnailSize.Size420x420)
		if currentRequest ~= requestId or not ok or not image or not playerImage or not playerImage.Parent then
			return
		end
		playerImage.Image = image
		pcall(ContentProvider.PreloadAsync, ContentProvider, { playerImage })
	end)
end

local function releaseGray(instant)
	local g = gray
	if not g then
		return
	end
	gray = nil
	g.conn:Disconnect()
	for inst, was in pairs(g.saved) do
		if inst.Parent then
			inst.Enabled = was
		end
	end
	local h = g.highlight
	if not h.Parent then
		return
	end
	if instant then
		h:Destroy()
		return
	end
	local tween = TweenService:Create(h, TweenInfo.new(0.45, Enum.EasingStyle.Quad), { FillTransparency = 1, OutlineTransparency = 1 })
	tween:Play()
	tween.Completed:Once(function()
		h:Destroy()
	end)
end

local function ensureGray(character)
	if gray and gray.character == character and gray.highlight.Parent then
		return
	end
	releaseGray(true)
	local saved = {}
	local function consider(h)
		if h:IsA("Highlight") and h.Name ~= GRAY_NAME then
			saved[h] = h.Enabled
			h.Enabled = false
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
	local h = new("Highlight", {
		Name = GRAY_NAME,
		Adornee = character,
		FillColor = GRAY_A,
		OutlineColor = Color3.new(1, 1, 1),
		FillTransparency = 1,
		OutlineTransparency = 1,
		DepthMode = Enum.HighlightDepthMode.Occluded,
	}, character)
	local g = { highlight = h, saved = saved, character = character, boost = 0 }
	local t0 = os.clock()
	g.conn = RunService.Heartbeat:Connect(function()
		if h.Parent then
			local wave = (math.sin((os.clock() - t0) * 5) + 1) / 2
			h.FillColor = GRAY_A:Lerp(GRAY_B, wave * (0.35 + g.boost * 0.65))
		end
	end)
	gray = g
	TweenService:Create(h, TweenInfo.new(0.3, Enum.EasingStyle.Quad), { FillTransparency = 0, OutlineTransparency = 0 }):Play()
end

local function retargetGray(target)
	if gray and gray.highlight.Parent then
		pcall(function()
			gray.highlight.Adornee = target
		end)
	end
end

local function runPhase(duration, step, id, isValid)
	local t0 = os.clock()
	while true do
		if id ~= requestId or not active or not isValid() then
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

local function hideStep()
	local s = hideState
	if not s or not s.character.Parent then
		return
	end
	for _, d in ipairs(s.character:GetDescendants()) do
		if d:IsA("BasePart") then
			if not d.Parent:IsA("Tool") then
				if s.saved[d] == nil then
					s.saved[d] = s.initial[d] or 0
				end
				d.LocalTransparencyModifier = 1
			end
		elseif isClass(d, FX_CLASSES) then
			if s.fx[d] == nil then
				s.fx[d] = d.Enabled
				if d:IsA("ParticleEmitter") then
					d:Clear()
				end
			end
			d.Enabled = false
		end
	end
end

local function showCharacter()
	pcall(RunService.UnbindFromRenderStep, RunService, HIDE_STEP)
	local s = hideState
	hideState = nil
	if not s then
		return
	end
	for inst, was in pairs(s.fx) do
		if inst.Parent then
			inst.Enabled = was
		end
	end
	if s.character.Parent then
		for _, d in ipairs(s.character:GetDescendants()) do
			if d:IsA("BasePart") then
				d.LocalTransparencyModifier = s.saved[d] or 0
			end
		end
	end
end

local function hideCharacter(character)
	showCharacter()
	hideState = { character = character, saved = weakTable(), fx = weakTable(), initial = weakTable() }
	for _, d in ipairs(character:GetDescendants()) do
		if d:IsA("BasePart") then
			hideState.initial[d] = d.LocalTransparencyModifier
		end
	end
	hideStep()
	pcall(RunService.BindToRenderStep, RunService, HIDE_STEP, Enum.RenderPriority.Last.Value, hideStep)
end

local function destroyGhost()
	local g = ghostState
	ghostState = nil
	if g then
		pcall(g.model.Destroy, g.model)
	end
end

local function clearTransformVisuals()
	destroyGhost()
	showCharacter()
end

local function relPath(inst, root)
	local names = {}
	while inst and inst ~= root do
		table.insert(names, 1, inst.Name)
		inst = inst.Parent
	end
	return table.concat(names, "/")
end

local function makeGhost(character, root)
	destroyGhost()
	local hiddenPaths = {}
	local hiding = hideState and hideState.character == character
	for _, d in ipairs(character:GetDescendants()) do
		if d:IsA("BasePart") then
			local ltm = hiding and (hideState.saved[d] or hideState.initial[d] or 0) or d.LocalTransparencyModifier
			if ltm >= 0.95 then
				hiddenPaths[relPath(d, character)] = true
			end
		end
	end

	local fx = hiding and hideState.fx or {}
	for inst, was in pairs(fx) do
		if inst.Parent then
			inst.Enabled = was
		end
	end
	local previous = character.Archivable
	character.Archivable = true
	local okClone, clone = pcall(character.Clone, character)
	character.Archivable = previous
	for inst in pairs(fx) do
		if inst.Parent then
			inst.Enabled = false
		end
	end
	if not okClone or not clone then
		return nil
	end

	for _, d in ipairs(clone:GetDescendants()) do
		if isClass(d, STRIP_CLASSES) then
			d:Destroy()
		end
	end

	local gRoot = clone:FindFirstChild("HumanoidRootPart")
	if not gRoot or not gRoot:IsA("BasePart") then
		clone:Destroy()
		return nil
	end

	local rootCF = gRoot.CFrame
	local items = {}
	for _, d in ipairs(clone:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored, d.CanCollide, d.CanTouch, d.CanQuery, d.Massless = true, false, false, false, true
			d.LocalTransparencyModifier = 0
			if hiddenPaths[relPath(d, clone)] then
				d.Transparency = 1
			end
			if d ~= gRoot then
				local item = { part = d, orig = d.Size, rel = rootCF:ToObjectSpace(d.CFrame), meshes = {}, seed = math.random() * 6.28 }
				for _, child in ipairs(d:GetChildren()) do
					if child:IsA("SpecialMesh") and child.MeshType == Enum.MeshType.FileMesh then
						table.insert(item.meshes, { mesh = child, orig = child.Scale })
					end
				end
				table.insert(items, item)
			end
		end
	end

	for _, d in ipairs(clone:GetDescendants()) do
		if d:IsA("JointInstance") or d:IsA("WeldConstraint") or d:IsA("Constraint") then
			d:Destroy()
		end
	end

	local pivot = Vector3.new(0, -3, 0)
	local okBB, bbCF, bbSize = pcall(clone.GetBoundingBox, clone)
	if okBB and bbCF then
		local rel = rootCF:ToObjectSpace(bbCF)
		pivot = Vector3.new(0, (rel.Position - rel.UpVector * (bbSize.Y / 2)).Y, 0)
	end

	clone.Name = "AFO_Ghost"
	clone.Parent = workspace.CurrentCamera or workspace
	ghostState = { model = clone, items = items, pivot = pivot }
	return ghostState
end

local function poseGhost(g, cf, k, a)
	for _, item in ipairs(g.items) do
		local part = item.part
		if part.Parent then
			local w = a and math.sin(a * 9 + item.seed) * 0.08 * math.sin(a * math.pi) or 0
			local mul = Vector3.new(k * (1 + w), k * (1 - w * 0.5), k * (1 + w))
			part.Size = item.orig * mul
			for _, entry in ipairs(item.meshes) do
				if entry.mesh.Parent then
					entry.mesh.Scale = entry.orig * mul
				end
			end
			part.CFrame = cf * (CFrame.new(g.pivot + (item.rel.Position - g.pivot) * k) * item.rel.Rotation)
		end
	end
end

local function animateGhost(g, root, grow, id, isValid)
	return runPhase(grow and GROW_TIME or SHRINK_TIME, function(a)
		local k = grow and (MIN_SCALE + (1 - MIN_SCALE) * easeOutBack(a)) or (1 - (1 - MIN_SCALE) * easeInBack(a))
		poseGhost(g, root.CFrame, k, a)
	end, id, isValid)
end

local function holdGhost(root, isDone, maxTime)
	local waited = 0
	while not isDone() and waited < maxTime do
		if ghostState then
			poseGhost(ghostState, root.CFrame, MIN_SCALE)
		end
		waited += RunService.Heartbeat:Wait()
	end
end

local function waitTransformFree(currentRequest)
	local waited = 0
	while transforming and waited < 3 do
		if currentRequest ~= requestId then
			return false
		end
		waited += task.wait(0.05)
	end
	return currentRequest == requestId
end

local function isProtected(accessory)
	if ownedAccessories[accessory] then
		return false
	end
	if protectedAccessories[accessory] or accessory:GetAttribute("AFO_Keep") then
		return true
	end
	local name = accessory.Name:lower()
	for _, pattern in ipairs(KEEP_NAME_PATTERNS) do
		if name:find(pattern, 1, true) then
			return true
		end
	end
	return false
end

local function markOwned(character)
	if not character.Parent then
		return
	end
	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("Accessory") and not protectedAccessories[child] and not child:GetAttribute("AFO_Keep") then
			ownedAccessories[child] = true
		end
	end
end

local function trackCharacter(character)
	if not active or trackedCharacters[character] then
		return
	end
	local state = { settled = false }
	trackedCharacters[character] = state
	task.spawn(function()
		local t = 0
		while localPlayer and not localPlayer:HasAppearanceLoaded() and t < 10 do
			t += task.wait(0.2)
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

local function isRigChild(inst)
	if isClass(inst, RIG_CLASSES) or inst.Name == "OriginalSize" or inst.Name == "AvatarPartScaleType" then
		return true
	end
	if inst:IsA("Attachment") then
		return STD_ATTACHMENTS[inst.Name] == true or inst.Name:find("RigAttachment$") ~= nil
	end
	return false
end

local function stashGameObjects(character)
	local s = { accessories = {}, children = {}, links = {}, guis = {} }
	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("Accessory") and isProtected(child) then
			local rec = { accessory = child }
			local handle = child:FindFirstChild("Handle")
			if handle then
				for _, j in ipairs(handle:GetChildren()) do
					if j:IsA("JointInstance") and j.Part0 and j.Part1 then
						rec.weld = j
						rec.handleIsPart0 = j.Part0 == handle
						rec.partName = (rec.handleIsPart0 and j.Part1 or j.Part0).Name
						break
					end
				end
			end
			table.insert(s.accessories, rec)
		end
	end
	for _, d in ipairs(character:GetDescendants()) do
		if (d:IsA("JointInstance") and not d:IsA("Motor6D")) or d:IsA("WeldConstraint") then
			if not insideItem(d) then
				local n0 = d.Part0 and isBody(d.Part0) and d.Part0.Name
				local n1 = d.Part1 and isBody(d.Part1) and d.Part1.Name
				if n0 or n1 then
					table.insert(s.links, { joint = d, n0 = n0, n1 = n1 })
				end
			end
		elseif (d:IsA("BillboardGui") or d:IsA("SurfaceGui")) and d.Name ~= GRAY_NAME and d.Adornee and isBody(d.Adornee) then
			table.insert(s.guis, { gui = d, name = d.Adornee.Name })
		elseif isBody(d) then
			for _, child in ipairs(d:GetChildren()) do
				if child.Name ~= GRAY_NAME and not isRigChild(child) and not child:IsA("BaseScript") then
					table.insert(s.children, { inst = child, partName = d.Name })
				end
			end
		end
	end
	for _, rec in ipairs(s.accessories) do
		rec.accessory.Parent = nil
	end
	for _, rec in ipairs(s.children) do
		rec.inst.Parent = nil
	end
	return s
end

local function restoreGameObjects(character, s)
	local fallback = character:FindFirstChild("HumanoidRootPart")
	for _, rec in ipairs(s.children) do
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
	for _, rec in ipairs(s.links) do
		if rec.joint.Parent then
			pcall(function()
				local p0 = rec.n0 and findPart(character, rec.n0)
				local p1 = rec.n1 and findPart(character, rec.n1)
				if p0 and rec.joint.Part0 ~= p0 then
					rec.joint.Part0 = p0
				end
				if p1 and rec.joint.Part1 ~= p1 then
					rec.joint.Part1 = p1
				end
			end)
		end
	end
	for _, rec in ipairs(s.guis) do
		local part = rec.gui.Parent and findPart(character, rec.name)
		if part and rec.gui.Adornee ~= part then
			pcall(function()
				rec.gui.Adornee = part
			end)
		end
	end
	for _, rec in ipairs(s.accessories) do
		rec.accessory.Parent = character
		protectedAccessories[rec.accessory] = true
		local handle = rec.accessory:FindFirstChild("Handle")
		local part = rec.partName and findPart(character, rec.partName)
		if handle and part and rec.weld and rec.weld.Parent then
			if rec.handleIsPart0 then
				rec.weld.Part0, rec.weld.Part1 = handle, part
			else
				rec.weld.Part0, rec.weld.Part1 = part, handle
			end
		end
	end
end

local function snapshotTransparency(character)
	local snap, hidden = {}, 0
	for _, d in ipairs(character:GetDescendants()) do
		if isBody(d) then
			snap[d.Name] = d.Transparency
			if d.Name ~= "Head" and d.Transparency >= 0.95 then
				hidden += 1
			end
		end
	end
	return hidden >= 3 and snap or nil
end

local function lockTransparency(character, snap)
	if not snap then
		return
	end
	local function enforce()
		if not character.Parent then
			return
		end
		for _, d in ipairs(character:GetDescendants()) do
			local want = isBody(d) and snap[d.Name]
			if want and d.Transparency < want - 0.01 then
				d.Transparency = want
			end
		end
	end
	enforce()
	for _, delayTime in ipairs({ 0.3, 1, 2.5 }) do
		task.delay(delayTime, enforce)
	end
end

local function verifyScales(humanoid, description)
	for _, entry in ipairs(SCALES) do
		local value = humanoid:FindFirstChild(entry[1])
		local ok, wanted = pcall(function()
			return description[entry[2]]
		end)
		if ok and type(wanted) == "number" and value and value:IsA("NumberValue") and math.abs(value.Value - wanted) > 0.001 then
			value.Value = wanted
		end
	end
end

local function runDescription(humanoid, description)
	local success = false
	local done = runWithTimeout(function()
		for _, name in ipairs(DESCRIPTION_METHODS) do
			if pcall(function()
				humanoid[name](humanoid, description)
			end) then
				success = true
				return
			end
		end
	end, DESCRIPTION_TIMEOUT)
	return done and success
end

local function applyEngine(character, humanoid, description)
	local stash = stashGameObjects(character)
	applyingChange = true
	local ok, result = pcall(function()
		local done = runDescription(humanoid, description)
		task.wait(0.15)
		if done then
			verifyScales(humanoid, description)
		end
		markOwned(character)
		return done
	end)
	pcall(restoreGameObjects, character, stash)
	applyingChange = false
	for _, delayTime in ipairs({ 0.4, 1.5, 3 }) do
		task.delay(delayTime, markOwned, character)
	end
	return ok and result
end

local function buildDonor(description)
	local donor = callMethod(Players, { "CreateHumanoidModelFromDescriptionAsync", "CreateHumanoidModelFromDescription" }, description, R6)
	if donor then
		runWithTimeout(function()
			ContentProvider:PreloadAsync(donor:GetDescendants())
		end, 8)
	end
	return donor
end

local function duplicatesProtected(character, template)
	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("Accessory") and child.Name == template.Name and isProtected(child) then
			return true
		end
	end
	return false
end

local function applyManualR6(character, humanoid, donor, description)
	for _, child in ipairs(character:GetChildren()) do
		if (child:IsA("Accessory") and not isProtected(child)) or child:IsA("CharacterAppearance") then
			child:Destroy()
		end
	end

	local head, donorHead = findPart(character, "Head"), donor:FindFirstChild("Head")
	if head then
		for _, child in ipairs(head:GetChildren()) do
			if child:IsA("Decal") or child:IsA("DataModelMesh") then
				child:Destroy()
			end
		end
		if donorHead then
			for _, child in ipairs(donorHead:GetChildren()) do
				if child:IsA("Decal") or child:IsA("DataModelMesh") then
					child:Clone().Parent = head
				end
			end
		end
		if not head:FindFirstChildOfClass("DataModelMesh") then
			new("SpecialMesh", { MeshType = Enum.MeshType.Head, Scale = Vector3.new(1.25, 1.25, 1.25) }, head)
		end
		local hasFace = false
		for _, child in ipairs(head:GetChildren()) do
			if child:IsA("Decal") and child.Texture ~= "" then
				hasFace = true
			end
		end
		if not hasFace then
			local faceId = description.Face
			new("Decal", {
				Name = "face",
				Face = Enum.NormalId.Front,
				Texture = faceId ~= 0 and ("rbxassetid://" .. faceId) or "rbxasset://textures/face.png",
			}, head)
		end
	end

	for _, child in ipairs(donor:GetChildren()) do
		if child:IsA("CharacterAppearance") then
			local copy = child:Clone()
			copy.Parent = character
			if copy:IsA("BodyColors") then
				for _, part in ipairs(character:GetDescendants()) do
					local prop = isBody(part) and BODY_COLOR_MAP[part.Name]
					if prop then
						part.Color = copy[prop]
					end
				end
			end
		elseif child:IsA("Accessory") then
			local handle = child:FindFirstChild("Handle")
			if handle and not handle:FindFirstChildWhichIsA("WrapLayer", true) and not duplicatesProtected(character, child) then
				local accessory = child:Clone()
				ownedAccessories[accessory] = true
				local newHandle = accessory:FindFirstChild("Handle")
				local stale = newHandle:FindFirstChild("AccessoryWeld")
				if stale then
					stale:Destroy()
				end
				pcall(humanoid.AddAccessory, humanoid, accessory)
				if accessory.Parent ~= character then
					accessory.Parent = character
				end
				newHandle.CanCollide, newHandle.CanTouch, newHandle.Massless = false, false, true
			end
		end
	end
	return true
end

local function guarded(humanoid, fn)
	local neck = humanoid.RequiresNeck
	local _, dead = pcall(humanoid.GetStateEnabled, humanoid, Enum.HumanoidStateType.Dead)
	pcall(function()
		humanoid.RequiresNeck = false
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
	end)
	local ok, result = pcall(fn)
	pcall(function()
		humanoid.RequiresNeck = neck
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, dead ~= false)
	end)
	if not ok then
		error(result, 0)
	end
	return result
end

local function watchDeath(humanoid)
	local conn
	conn = humanoid.Died:Connect(function()
		conn:Disconnect()
		deathStrikes += 1
		if deathStrikes >= MAX_DEATH_STRIKES then
			autoReapply = false
			lastUsername = nil
			requestId += 1
			notify("El cambio de avatar mataba a tu personaje: se detuvo la reaplicacion automatica.")
		end
	end)
	task.delay(DEATH_WINDOW, function()
		if conn.Connected then
			conn:Disconnect()
			deathStrikes = 0
		end
	end)
end

local function setScriptEnabled(script, enabled)
	if not pcall(function()
		script.Enabled = enabled
	end) then
		pcall(function()
			script.Disabled = not enabled
		end)
	end
end

local function restartAnimations(character, humanoid)
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if animator then
		for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
			pcall(track.Stop, track, 0)
		end
	end
	local state = humanoid:GetState()
	if state == Enum.HumanoidStateType.FallingDown or state == Enum.HumanoidStateType.Ragdoll then
		humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	end
	local animate = character:FindFirstChild("Animate")
	if animate then
		setScriptEnabled(animate, false)
		task.wait()
		setScriptEnabled(animate, true)
	end
end

local function newFxPart(props)
	local part = Instance.new("Part")
	part.Anchored, part.CanCollide, part.CanQuery, part.CanTouch, part.CastShadow = true, false, false, false, false
	part.TopSurface, part.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	for key, value in pairs(props) do
		part[key] = value
	end
	part.Parent = workspace
	Debris:AddItem(part, 3)
	return part
end

local function splash(character)
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	local center = root.Position
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }
	local hit = workspace:Raycast(center, Vector3.new(0, -15, 0), params)
	local ground = hit and (hit.Position + Vector3.new(0, 0.1, 0)) or (center - Vector3.new(0, 3, 0))
	if gray then
		gray.boost = 1
	end

	local quad = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local emitterPart = newFxPart({ Transparency = 1, Size = Vector3.one, Position = center })
	local light = new("PointLight", { Color = Color3.fromRGB(225, 227, 235), Brightness = 5, Range = 22 }, emitterPart)
	TweenService:Create(light, quad, { Brightness = 0 }):Play()

	local mist = new("ParticleEmitter", {
		Texture = "rbxasset://textures/particles/smoke_main.dds",
		Color = ColorSequence.new(Color3.fromRGB(190, 192, 200), Color3.fromRGB(120, 122, 130)),
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 2), NumberSequenceKeypoint.new(1, 8) }),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.15), NumberSequenceKeypoint.new(1, 1) }),
		Lifetime = NumberRange.new(0.6, 1.1),
		Speed = NumberRange.new(14, 28),
		SpreadAngle = Vector2.new(180, 180),
		Drag = 3,
		Rate = 0,
		LightEmission = 0.1,
	}, emitterPart)
	mist:Emit(45)

	local ring = newFxPart({
		Shape = Enum.PartType.Cylinder,
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(235, 237, 245),
		Transparency = 0.2,
		Size = Vector3.new(0.15, 2, 2),
		CFrame = CFrame.new(ground) * CFrame.Angles(0, 0, math.rad(90)),
	})
	TweenService:Create(ring, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(0.15, 28, 28),
		Transparency = 1,
	}):Play()

	local drops = {}
	for i = 1, 22 do
		local s = 0.35 + math.random() * 0.45
		local dir = Vector3.new(math.random() * 2 - 1, math.random() * 0.8 + 0.3, math.random() * 2 - 1).Unit
		drops[i] = {
			part = newFxPart({
				Shape = Enum.PartType.Ball,
				Material = Enum.Material.SmoothPlastic,
				Reflectance = 0.4,
				Color = GRAY_A:Lerp(GRAY_B, math.random()),
				Size = Vector3.new(s * 1.4, s * 0.7, s * 1.4),
				Position = center,
			}),
			vel = dir * (12 + math.random() * 18),
			size = s,
		}
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
		local out = TweenService:Create(camera, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { FieldOfView = fov + 7 })
		out:Play()
		out.Completed:Once(function()
			TweenService:Create(camera, quad, { FieldOfView = fov }):Play()
		end)
	end
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
		local root = character:WaitForChild("HumanoidRootPart", 10)
		if not humanoid or not root then
			return
		end

		trackCharacter(character)
		if originalDescriptions[character] == nil then
			local ok, applied = pcall(humanoid.GetAppliedDescription, humanoid)
			originalDescriptions[character] = ok and applied or false
		end

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
			return currentRequest == requestId and localPlayer.Character == character and character.Parent ~= nil and humanoid.Health > 0
		end

		local rigType = getRigType(character, humanoid)
		local isR15 = rigType == R15
		local useEngine = humanoid.RigType == rigType and (isR15 or ENGINE_R6)
		local original = originalDescriptions[character]
		local description = (isReset and useEngine and original) and original:Clone() or getDescription(userId)
		if not stillValid() then
			return
		end
		if not description then
			if currentRequest == requestId then
				lastUsername = previousUsername
				releaseGray(false)
				if onFail then
					onFail()
				end
			end
			return
		end
		if not waitTransformFree(currentRequest) or not stillValid() then
			return
		end

		local donor
		local function performChange()
			local transparency = snapshotTransparency(character)
			local ok, result = pcall(guarded, humanoid, function()
				if useEngine and applyEngine(character, humanoid, description) then
					return true
				end
				if isR15 or not stillValid() then
					return false
				end
				donor = donor or buildDonor(description)
				return donor ~= nil and applyManualR6(character, humanoid, donor, description)
			end)
			lockTransparency(character, transparency)
			if not ok then
				error(result, 0)
			end
			if result then
				watchDeath(humanoid)
			end
			return result
		end

		transforming = true

		if not animated then
			pcall(performChange)
			pcall(restartAnimations, character, humanoid)
			if donor then
				donor:Destroy()
			end
			transforming = false
			quietUntil = os.clock() + 8
			return
		end

		local completed, changeDone, changeOk = false, false, false

		pcall(function()
			local function valid()
				return stillValid() and root.Parent ~= nil
			end

			local oldGhost = makeGhost(character, root)
			if oldGhost then
				hideCharacter(character)
				retargetGray(oldGhost.model)
			end

			task.spawn(function()
				local ok, result = pcall(performChange)
				changeOk = ok and result == true
				changeDone = true
			end)

			if oldGhost and not animateGhost(oldGhost, root, false, currentRequest, valid) then
				return
			end

			holdGhost(root, function()
				return changeDone or not valid()
			end, 25)
			if not (valid() and changeOk) then
				return
			end

			local ready = false
			task.spawn(function()
				pcall(restartAnimations, character, humanoid)
				task.wait(0.2)
				ready = true
			end)
			holdGhost(root, function()
				return ready or not valid()
			end, 3)
			if not valid() then
				return
			end

			if oldGhost then
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

		local waited = 0
		while not changeDone and waited < 25 do
			waited += task.wait(0.05)
		end

		destroyGhost()
		showCharacter()
		if gray and gray.character == character then
			retargetGray(character)
		end
		if donor then
			donor:Destroy()
		end
		transforming = false
		quietUntil = os.clock() + 8

		if currentRequest == requestId then
			if completed then
				splash(character)
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
	gui, mainFrame, playerImage, setPanelOpen, isOpen = nil, nil, nil, nil, false
	if restoreAvatar and localPlayer then
		lastUsername = nil
		applyAvatar(localPlayer.Name, true, false, nil)
	end
end

function M.Start(firstArgument, secondArgument, thirdArgument)
	if typeof(firstArgument) == "Instance" and firstArgument:IsA("Player") then
		localPlayer, keys = firstArgument, secondArgument
	else
		keys, localPlayer = firstArgument, secondArgument or Players.LocalPlayer
	end
	if not localPlayer then
		return false
	end

	local defaultAvatar = type(thirdArgument) == "string" and thirdArgument ~= "" and thirdArgument or localPlayer.Name
	if keys then
		local configured = keys.CopyAvatar or keys.Toggle
		if typeof(configured) == "EnumItem" then
			toggleKey = configured
		end
	end

	requestId += 1
	autoReapply, deathStrikes = true, 0
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

	active, isOpen, lastUsername = true, false, nil

	gui = new("ScreenGui", {
		Name = "AFO_AvatarChanger",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}, playerGui)

	mainFrame = new("Frame", {
		Name = "MainPanel",
		Size = UDim2.new(0, PANEL_W, 0, PANEL_H),
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, PANEL_W + 40, 0, 190),
		BackgroundColor3 = C_BLACK,
		BackgroundTransparency = 0.15,
		BorderSizePixel = 0,
		ZIndex = 10,
	}, gui)
	corner(mainFrame, 8)
	stroke(mainFrame, 1, 0.5)

	local closeButton = new("TextButton", {
		Size = UDim2.new(0, 20, 0, 20),
		Position = UDim2.new(1, -30, 0, 10),
		BackgroundColor3 = Color3.fromRGB(200, 40, 40),
		BackgroundTransparency = 0.2,
		TextColor3 = Color3.new(1, 1, 1),
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		Text = "X",
		BorderSizePixel = 0,
	}, mainFrame)
	corner(closeButton, 4)

	new("TextLabel", {
		Size = UDim2.new(0, 150, 0, 20),
		Position = UDim2.new(0, 15, 0, 10),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		TextColor3 = C_TEXT,
		Text = "Avatar Changer",
		TextXAlignment = Enum.TextXAlignment.Left,
	}, mainFrame)

	local textBox = new("TextBox", {
		Size = UDim2.new(0, BOX_W, 0, 28),
		Position = UDim2.new(0, 15, 0, 42),
		BackgroundColor3 = C_BOX,
		BackgroundTransparency = 0.3,
		TextColor3 = C_TEXT,
		PlaceholderColor3 = C_SUB,
		PlaceholderText = "Username...",
		Text = defaultAvatar,
		Font = Enum.Font.Gotham,
		TextSize = MAX_TEXT,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClipsDescendants = true,
		BorderSizePixel = 0,
		ClearTextOnFocus = false,
	}, mainFrame)
	corner(textBox, 4)
	new("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, textBox)
	local boxStroke = stroke(textBox, 1, 0.7)

	local applyButton = new("TextButton", {
		Size = UDim2.new(0, 150, 0, 26),
		Position = UDim2.new(0, 15, 0, 82),
		BackgroundColor3 = Color3.fromRGB(80, 20, 140),
		BackgroundTransparency = 0.2,
		TextColor3 = Color3.new(1, 1, 1),
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		Text = "Apply",
		BorderSizePixel = 0,
	}, mainFrame)
	corner(applyButton, 4)

	local resetButton = new("TextButton", {
		Size = UDim2.new(0, 35, 0, 26),
		Position = UDim2.new(0, 170, 0, 82),
		BackgroundColor3 = Color3.fromRGB(80, 20, 140),
		BackgroundTransparency = 0.2,
		TextColor3 = Color3.new(1, 1, 1),
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		Text = "🔄",
		BorderSizePixel = 0,
	}, mainFrame)
	corner(resetButton, 4)

	new("TextLabel", {
		Size = UDim2.new(1, -30, 0, 12),
		Position = UDim2.new(0, 15, 0, 112),
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		TextSize = 9,
		TextColor3 = C_SUB,
		TextTransparency = 0.35,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = "Tip: Username",
	}, mainFrame)

	local imageContainer = new("Frame", {
		Size = UDim2.new(0, 55, 0, 55),
		Position = UDim2.new(1, -70, 0, 34),
		BackgroundColor3 = C_BOX,
		BackgroundTransparency = 0.3,
		BorderSizePixel = 0,
		ZIndex = 11,
	}, mainFrame)
	corner(imageContainer, 28)

	playerImage = new("ImageLabel", {
		Name = "PlayerImage",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Image = "",
		ZIndex = 12,
	}, imageContainer)
	corner(playerImage, 28)

	local menu = new("Frame", {
		Name = "NicknameMenu",
		Size = UDim2.new(1, 0, 0, 0),
		Position = UDim2.new(0, 0, 1, 6),
		BackgroundColor3 = C_BLACK,
		BackgroundTransparency = 0.15,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = 10,
	}, mainFrame)
	corner(menu, 8)
	stroke(menu, 1, 0.5)

	local list = new("ScrollingFrame", {
		Size = UDim2.new(1, -8, 1, -8),
		Position = UDim2.new(0, 4, 0, 4),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = C_PURPLE,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ZIndex = 11,
	}, menu)
	new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, list)

	local panelTween = TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

	setPanelOpen = function(open)
		if not active or not mainFrame or not mainFrame.Parent then
			return
		end
		isOpen = open
		local position = open and UDim2.new(1, -20, 0, 190) or UDim2.new(1, PANEL_W + 40, 0, 190)
		TweenService:Create(mainFrame, panelTween, { Position = position }):Play()
	end

	local function fitText()
		local size = MAX_TEXT
		while size > MIN_TEXT do
			local bounds = TextService:GetTextSize(textBox.Text, size, textBox.Font, Vector2.new(10000, 100))
			if bounds.X <= BOX_W - 16 then
				break
			end
			size -= 1
		end
		textBox.TextSize = size
	end
	fitText()

	local errorToken = 0
	local function flashError()
		if not textBox.Parent then
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
			TweenService:Create(textBox, info, { BackgroundColor3 = C_BOX, BackgroundTransparency = 0.3 }):Play()
			TweenService:Create(boxStroke, info, { Color = C_PURPLE, Transparency = 0.7 }):Play()
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
		TweenService:Create(menu, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Size = UDim2.new(1, 0, 0, 0) }):Play()
		task.delay(0.3, function()
			if not menuOpen and list.Parent then
				clearRows()
			end
		end)
	end

	local function openMenu(results, onPick)
		clearRows()
		menuOpen = true
		list.CanvasPosition = Vector2.zero

		for index, player in ipairs(results) do
			local row = new("TextButton", {
				LayoutOrder = index,
				Size = UDim2.new(1, -6, 0, ROW_H),
				BackgroundColor3 = C_BOX,
				BackgroundTransparency = 0.3,
				BorderSizePixel = 0,
				AutoButtonColor = false,
				Text = "",
				ZIndex = 12,
			}, list)
			corner(row, 6)

			local holder = new("Frame", {
				Size = UDim2.new(0, 40, 0, 40),
				Position = UDim2.new(0, 6, 0, 6),
				BackgroundColor3 = C_BLACK,
				BorderSizePixel = 0,
				ZIndex = 13,
			}, row)
			corner(holder, 20)

			local avatarImage = new("ImageLabel", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				ZIndex = 14,
			}, holder)
			corner(avatarImage, 20)

			new("TextLabel", {
				Size = UDim2.new(1, -60, 0, 20),
				Position = UDim2.new(0, 54, 0, 7),
				BackgroundTransparency = 1,
				Font = Enum.Font.GothamBold,
				TextSize = 13,
				TextColor3 = C_TEXT,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Text = player.DisplayName,
				ZIndex = 13,
			}, row)

			new("TextLabel", {
				Size = UDim2.new(1, -60, 0, 16),
				Position = UDim2.new(0, 54, 0, 28),
				BackgroundTransparency = 1,
				Font = Enum.Font.Gotham,
				TextSize = 11,
				TextColor3 = C_SUB,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Text = "@" .. player.Name,
				ZIndex = 13,
			}, row)

			task.spawn(function()
				local ok, image = pcall(Players.GetUserThumbnailAsync, Players, player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
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
				onPick(player.Name)
			end)
		end

		menu.Size = UDim2.new(1, 0, 0, 0)
		TweenService:Create(menu, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Size = UDim2.new(1, 0, 0, math.min(#results, MENU_MAX_ROWS) * (ROW_H + 4) + 8),
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

	local function pick(username)
		textBox.Text = username
		closeMenu()
		applyAvatar(username, false, true, flashError)
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
				openMenu(results, pick)
				return
			end
		end
		if getUserId(queryText) then
			closeMenu()
			applyAvatar(queryText, false, true, flashError)
			return
		end
		local results = searchPlayers(queryText)
		if #results > 0 then
			openMenu(results, pick)
		else
			closeMenu()
			flashError()
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
					t += task.wait(0.2)
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
		applyAvatar(localPlayer.Name, true, true, nil)
	end))

	table.insert(connections, closeButton.MouseButton1Click:Connect(function()
		M.Stop(true)
	end))

	table.insert(connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if not gameProcessed and input.KeyCode == toggleKey then
			setPanelOpen(not isOpen)
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
