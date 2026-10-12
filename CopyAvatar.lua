print("nyaaa232")

local M = {}

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ContentProvider = game:GetService("ContentProvider")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")
local Debris = game:GetService("Debris")

--------------------------------------------------------------------
-- ESTADO
--------------------------------------------------------------------
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
local originalHip = setmetatable({}, { __mode = "k" })
local ownedAccessories = setmetatable({}, { __mode = "k" })
local protectedAccessories = setmetatable({}, { __mode = "k" })
local trackedCharacters = setmetatable({}, { __mode = "k" })

--------------------------------------------------------------------
-- CONFIGURACION
--------------------------------------------------------------------
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

local MIN_FACTOR = 0.03
local SHRINK_TIME = 0.55
local GROW_TIME = 0.75
local STAGGER = 0.3
local SIMILAR_MIN, SIMILAR_MAX = 0.6, 1.7

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

-- Opciones nuevas (v5) ---------------------------------------------
-- Ajusta HipHeight (solo R15) al avatar nuevo y lo restaura al resetear.
local ADJUST_HIPHEIGHT = true
-- Respeta accesorios que NO son del avatar (ej: la corona que da un juego
-- battleground): los añadidos por el juego despues de cargar el personaje, y
-- los cuyo nombre contenga alguno de KEEP_NAME_PATTERNS.
local PRESERVE_GAME_ACCESSORIES = true
local KEEP_NAME_PATTERNS = { "crown", "corona" }
-- Tras cambiar de avatar se vigila que los accesorios sigan pegados al
-- cuerpo (algunos juegos los borran / sueltan) y se reparan solos.
local GUARD_SECONDS = 6
local GUARD_INTERVAL = 0.35
local MAX_REPAIRS = 3
-- Pon DEBUG = true para ver en consola que rig se detecta y que se repara.
local DEBUG = false

local function dbg(...)
	if DEBUG then
		print("[CopyAvatar]", ...)
	end
end

--------------------------------------------------------------------
-- UTILIDADES
--------------------------------------------------------------------
local function clamp01(x)
	return math.clamp(x, 0, 1)
end

-- Curva suave (Smoothstep) para evitar cambios bruscos/salvajes
local function easeSmooth(t)
	t = clamp01(t)
	return t * t * (3 - 2 * t)
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

--------------------------------------------------------------------
-- DETECCION DE RIG (R6 / R15)
--
-- Humanoid.RigType MIENTE en muchos juegos (battlegrounds con rigs custom).
-- Orden de fiabilidad:
--   1) la articulacion que cuelga de HumanoidRootPart
--      (R15: LowerTorso / R6: Torso),
--   2) que partes del cuerpo existen de verdad (ignorando accesorios),
--   3) Humanoid.RigType como ultimo recurso.
--------------------------------------------------------------------
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
						dbg("rig = R15 (articulacion de la raiz -> LowerTorso). Humanoid.RigType dice:", humanoid.RigType.Name)
						return Enum.HumanoidRigType.R15
					elseif other.Name == "Torso" then
						dbg("rig = R6 (articulacion de la raiz -> Torso). Humanoid.RigType dice:", humanoid.RigType.Name)
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
		dbg("rig = R15 (partes)")
		return Enum.HumanoidRigType.R15
	end
	if r6 >= 4 and r15 < 3 then
		dbg("rig = R6 (partes)")
		return Enum.HumanoidRigType.R6
	end
	if r15 > 0 or r6 > 0 then
		local s15, s6 = r15 / #R15_NAMES, r6 / #R6_NAMES
		if s15 ~= s6 then
			return (s15 > s6) and Enum.HumanoidRigType.R15 or Enum.HumanoidRigType.R6
		end
	end

	dbg("rig = Humanoid.RigType (sin otra pista):", humanoid.RigType.Name)
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
--------------------------------------------------------------------
-- CAPA GRIS BRILLANTE (Highlight)
--------------------------------------------------------------------
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

--------------------------------------------------------------------
-- FASES
--------------------------------------------------------------------
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

--------------------------------------------------------------------
-- ANIMACION SEGURA (FANTASMA VISUAL)
--
-- CAUSA DEL BUG: la version anterior encogia/agrandaba el cuerpo REAL
-- (Part.Size cada frame), anclaba la raiz y tocaba el HipHeight. En juegos
-- battleground eso choca con el propio juego (anti-cheat, estados, stuns,
-- fisicas) y deja el personaje en un estado raro (partes mal, sin accesorios
-- soldados al cuerpo, empujones, etc.).
--
-- AHORA: el cuerpo real NO se toca fisicamente durante la animacion. Solo se
-- pone invisible en TU pantalla (LocalTransparencyModifier) y la animacion se
-- hace sobre un "fantasma" (clon anclado, sin colision, sin scripts) que
-- sigue a tu HumanoidRootPart. Si el fantasma falla, se hace el cambio
-- directo sin animacion.
--------------------------------------------------------------------
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
					saved[d] = d.LocalTransparencyModifier
				end
				d.LocalTransparencyModifier = 1
			end
		end
	end
end

-- Devuelve el cuerpo real a su estado visual anterior (solo si se oculto).
local function showCharacter()
	pcall(function()
		RunService:UnbindFromRenderStep(HIDE_STEP)
	end)
	local state = hideState
	hideState = nil
	if not state then
		return
	end
	local target = state.character
	if target and target.Parent then
		for _, d in ipairs(target:GetDescendants()) do
			if d:IsA("BasePart") then
				d.LocalTransparencyModifier = state.saved[d] or 0
			end
		end
	end
end

local function hideCharacter(character)
	showCharacter()
	hideState = { character = character, saved = setmetatable({}, { __mode = "k" }) }
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

local function makeGhost(character, root)
	destroyGhost()

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

	pcall(function()
		local gHum = clone:FindFirstChildOfClass("Humanoid")
		if gHum then
			gHum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
			gHum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
			gHum.RequiresNeck = false
			gHum.BreakJointsOnDeath = false
			gHum.AutoRotate = false
			gHum.WalkSpeed = 0
		end
	end)

	local rootCF = gRoot.CFrame
	local items = {}
	for _, d in ipairs(clone:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanTouch = false
			d.CanQuery = false
			d.LocalTransparencyModifier = 0
			if d ~= gRoot then
				local item = {
					part = d,
					orig = d.Size,
					rel = rootCF:ToObjectSpace(d.CFrame),
					meshes = {},
					delay = math.random() * STAGGER,
					seed = math.random() * 6.28,
				}
				for _, child in ipairs(d:GetChildren()) do
					if child:IsA("SpecialMesh") and child.MeshType == Enum.MeshType.FileMesh then
						table.insert(item.meshes, { mesh = child, orig = child.Scale })
					end
				end
				table.insert(items, item)
			end
		end
	end

	-- Punto de anclaje de la animacion: los PIES (el cuerpo se derrite hacia el
	-- suelo y crece desde el suelo, no desde el aire).
	local pivot = Vector3.new(0, -3, 0)
	local okBB, bbCF, bbSize = pcall(function()
		return clone:GetBoundingBox()
	end)
	if okBB and bbCF and bbSize then
		local rel = rootCF:ToObjectSpace(bbCF)
		pivot = rel.Position - rel.UpVector * (bbSize.Y / 2)
	end

	clone.Name = "AFO_Ghost"
	clone.Parent = workspace.CurrentCamera or workspace

	local g = { model = clone, items = items, pivot = pivot }
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
	local v = item.rel.Position - g.pivot
	part.CFrame = followCF * CFrame.new(g.pivot + v * k) * item.rel.Rotation
end

local function animateGhost(g, root, grow, id, isValid)
	local dur = grow and GROW_TIME or SHRINK_TIME
	local total = dur + STAGGER
	return runPhase(total, function(alpha)
		local t = alpha * total
		local followCF = root.CFrame
		for _, item in ipairs(g.items) do
			local la = clamp01((t - item.delay) / dur)
			local e = easeSmooth(la)
			local k
			if grow then
				k = MIN_FACTOR + (1 - MIN_FACTOR) * e
			else
				k = 1 - (1 - MIN_FACTOR) * e
			end
			local w = 0
			if la > 0 and la < 1 then
				w = math.sin(la * 9 + item.seed) * 0.08 * math.sin(la * math.pi)
			end
			poseGhostItem(g, item, k, Vector3.new(k * (1 + w), k * (1 - w * 0.5), k * (1 + w)), followCF)
		end
	end, id, isValid)
end

-- Evita que dos transformaciones se pisen: una nueva espera a que la anterior
-- termine su limpieza antes de empezar.
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

--------------------------------------------------------------------
-- ACCESORIOS QUE NO SON DEL AVATAR (ej: corona de un battleground)
--------------------------------------------------------------------
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

-- Marca como "del juego" todo accesorio que aparezca despues de que el
-- personaje termino de cargar su apariencia y que no hayamos creado nosotros.
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
		if state.settled and child:IsA("Accessory") and not ownedAccessories[child] then
			protectedAccessories[child] = true
			dbg("accesorio del juego protegido:", child.Name)
		end
	end))
end


--------------------------------------------------------------------
-- BUSQUEDA DE PARTES (no depende solo de character:FindFirstChild)
--------------------------------------------------------------------
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

-- Los handles de accesorios nunca deben tener masa ni colision.
local function sanitizeAccessories(character)
	for _, child in ipairs(character:GetChildren()) do
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

--------------------------------------------------------------------
-- ACCESORIOS (3 niveles de fijacion para que NUNCA se pierdan)
--   1) Humanoid:AddAccessory (normal)
--   2) por nombre de Attachment (solo en partes del cuerpo)
--   3) weld calculado con los datos del donante / adivinando la parte
--------------------------------------------------------------------
local function findHandleAttachment(handle)
	for _, child in ipairs(handle:GetChildren()) do
		if child:IsA("Attachment") then
			return child
		end
	end
	return nil
end

-- Antes buscaba en TODO el personaje y podia pegar la corona al attachment de
-- OTRO accesorio. Ahora solo mira partes del cuerpo.
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

-- Lee, del accesorio ORIGINAL del donante (con su weld intacto), a que parte
-- iba pegado y con que offsets. Hay que hacerlo antes de clonar: un clon suelto
-- pierde la referencia Part1.
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

	-- 1) camino normal
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

	-- 2) por nombre de attachment
	pcall(manualAttachAccessory, accessory, character)
	if isAttached(character, accessory) then
		prepareHandle(handle)
		return accessory
	end

	-- 3) weld de respaldo
	local okFallback = pcall(fallbackWeld, character, accessory, handle, info, isR15)
	if okFallback and isAttached(character, accessory) then
		dbg("accesorio fijado con weld de respaldo:", accessory.Name)
		return accessory
	end

	warn("[CopyAvatar] No se pudo fijar el accesorio: " .. tostring(accessory.Name))
	accessory:Destroy()
	return nil
end

-- Vigila unos segundos que los accesorios sigan en su sitio y los repara.
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
					dbg("reparando accesorio:", rec.backup.Name, "intento", rec.repairs)
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

--------------------------------------------------------------------
-- LIMPIEZA Y ADAPTACION DE RIG (R15 / R6 / UGC)
--------------------------------------------------------------------
-- Ropa en capas (WrapLayer): solo se deforma sobre cuerpos R15.
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

local function wipeAppearance(character)
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
		if part:IsA("BasePart") and not isInsideAccessoryOrTool(part) then
			for _, sub in ipairs(part:GetChildren()) do
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

local function meshIdOf(handle)
	if handle:IsA("MeshPart") then
		return handle.MeshId
	end
	local mesh = handle:FindFirstChildOfClass("SpecialMesh")
	return mesh and mesh.MeshId or ""
end

-- Si el avatar nuevo trae un accesorio igual a uno protegido (misma corona),
-- no se duplica.
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

local function copyVisual(part, donorPart)
	part.Color = donorPart.Color
	part.Material = donorPart.Material
	part.Reflectance = donorPart.Reflectance
	part.Transparency = donorPart.Transparency
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
			d:Clone().Parent = part
		end
	end
end

local APPEARANCE_CLASSES = {
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
	for _, className in ipairs(APPEARANCE_CLASSES) do
		if inst:IsA(className) then
			return true
		end
	end
	return false
end

-- Reemplaza una parte del cuerpo conservando TODAS las uniones que dependian de
-- ella. Antes solo se reapuntaban los Motor6D: el AccessoryWeld de la corona
-- apuntaba a la cabeza vieja (destruida) y la corona se caia.
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

	-- Mover a la parte nueva todo lo que NO es apariencia (uniones, attachments
	-- propios del juego, luces, etc.).
	for _, child in ipairs(oldPart:GetChildren()) do
		if not isAppearanceChild(child) then
			local clash = child:IsA("Attachment") and newPart:FindFirstChild(child.Name)
			if not clash then
				child.Parent = newPart
			end
		end
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

	oldPart:Destroy()
	return newPart
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

	if part:IsA("MeshPart") and donorPart:IsA("MeshPart") and not needsFullReplace(donorPart) then
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
			copyVisual(part, donorPart)
			copyPartChildren(part, donorPart)
			return part
		end
	end

	return replaceBodyPart(character, part, donorPart)
end

-- Adaptación forzada de Bundles R15 / UGC a R6
local function adaptR15ToR6(character, donor)
	local mapping = {
		["Torso"] = { "UpperTorso", "Torso", "LowerTorso" },
		["Left Arm"] = { "LeftUpperArm", "LeftArm", "LeftHand", "LeftLowerArm" },
		["Right Arm"] = { "RightUpperArm", "RightArm", "RightHand", "RightLowerArm" },
		["Left Leg"] = { "LeftUpperLeg", "LeftLeg", "LeftFoot", "LeftLowerLeg" },
		["Right Leg"] = { "RightUpperLeg", "RightLeg", "RightFoot", "RightLowerLeg" },
		["Head"] = { "Head" },
	}

	for r6Name, r15Candidates in pairs(mapping) do
		local r6Part = findPart(character, r6Name)
		if r6Part then
			local foundDonorPart
			for _, cand in ipairs(r15Candidates) do
				local p = donor:FindFirstChild(cand)
				if p and p:IsA("BasePart") then
					foundDonorPart = p
					break
				end
			end

			if foundDonorPart then
				if r6Name == "Head" then
					local donorHead = foundDonorPart
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
					-- Que la cabeza R6 tenga SIEMPRE los attachments de accesorios
					-- (en algunos juegos battleground no los tiene).
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
					copyVisual(r6Part, donorHead)
				else
					if foundDonorPart:IsA("MeshPart") and r6Part:IsA("MeshPart") then
						pcall(function()
							r6Part:ApplyMesh(foundDonorPart)
						end)
						r6Part.TextureID = foundDonorPart.TextureID
					end
					copyVisual(r6Part, foundDonorPart)
					copyPartChildren(r6Part, foundDonorPart)
				end
			end
		end
	end
end

-- Aplica el avatar del donante. NO hace yields (todo ocurre en el mismo frame).
-- Devuelve la lista de accesorios aplicados (para el guardian).
local function applyDonorData(character, humanoid, donor, isR15)
	-- Transparencia ORIGINAL de las partes del cuerpo. Algunos juegos ocultan
	-- las partes del rig y dibujan el cuerpo con accesorios.
	local keepTransparency = {}
	for _, d in ipairs(character:GetDescendants()) do
		if d:IsA("BasePart") and not isInsideAccessoryOrTool(d) then
			keepTransparency[d.Name] = d.Transparency
		end
	end

	wipeAppearance(character)

	if isR15 then
		for _, donorPart in ipairs(donor:GetChildren()) do
			if donorPart:IsA("BasePart") and donorPart.Name ~= "HumanoidRootPart" then
				syncR15Part(character, donorPart)
			end
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
	else
		adaptR15ToR6(character, donor)
	end

	-- Caras (conservando las originales y evitando conflictos con cabezas dinámicas)
	local head = findPart(character, "Head")
	local donorHead = donor:FindFirstChild("Head")
	if head then
		if not isR15 and not head:FindFirstChildOfClass("DataModelMesh") then
			local mesh = Instance.new("SpecialMesh")
			mesh.MeshType = Enum.MeshType.Head
			mesh.Scale = Vector3.new(1.25, 1.25, 1.25)
			mesh.Parent = head
		end

		local dynamic = head:FindFirstChildWhichIsA("FaceControls") ~= nil
			or head:FindFirstChildWhichIsA("Bone", true) ~= nil

		if dynamic then
			for _, child in ipairs(head:GetChildren()) do
				if child:IsA("Decal") then
					child:Destroy()
				end
			end
		else
			local hasDecal = head:FindFirstChildOfClass("Decal") ~= nil
			if not hasDecal and donorHead then
				for _, child in ipairs(donorHead:GetChildren()) do
					if child:IsA("Decal") then
						child:Clone().Parent = head
						hasDecal = true
					end
				end
			end
			if not hasDecal then
				local face = Instance.new("Decal")
				face.Name = "face"
				face.Face = Enum.NormalId.Front
				face.Texture = "rbxasset://textures/face.png"
				face.Parent = head
			end
		end
	end

	local donorColors = donor:FindFirstChildOfClass("BodyColors")
	if donorColors then
		local newColors = donorColors:Clone()
		newColors.Parent = character
		applyManualBodyColors(character, newColors)
	end

	-- Ropa (los assets ya se precargaron junto al donante: aqui NO se hace yield)
	for _, child in ipairs(donor:GetChildren()) do
		if child:IsA("Shirt") or child:IsA("Pants") or child:IsA("ShirtGraphic") or child:IsA("CharacterMesh") then
			child:Clone().Parent = character
		end
	end

	-- Accesorios
	local records = {}
	for _, template in ipairs(donor:GetChildren()) do
		if template:IsA("Accessory") then
			local skip = false
			if not isR15 and isLayeredAccessory(template) then
				skip = true -- R6: no se puede deformar, se omite en vez de dibujarla rigida
			elseif duplicatesProtected(character, template) then
				skip = true -- ya hay una igual (ej: la corona del juego)
			end

			if not skip then
				local info = getWeldInfo(template)
				local accessory = attachAccessory(character, humanoid, template, info, isR15)
				if accessory then
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

	for name, transparency in pairs(keepTransparency) do
		local p = findPart(character, name)
		if p then
			p.Transparency = transparency
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

--------------------------------------------------------------------
-- PAQUETE DE ANIMACIONES (R15)
--------------------------------------------------------------------
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

-- Solo toca el script Animate si de verdad hay animaciones distintas, no
-- espera 5 s si el personaje no tiene Animate, y solo detiene los tracks que
-- pertenecian a las animaciones que cambian (no mata las del propio juego).
local function applyAnimations(character, humanoid, description, isR15)
	if not isR15 then
		return
	end

	local animate = character:FindFirstChild("Animate")
	if not animate then
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

	local changed = false
	local oldIds = {}
	for _, entry in ipairs(ANIM_MAP) do
		local folder = animate:FindFirstChild(entry[1])
		local anim = folder and folder:FindFirstChild(entry[2])
		if anim and anim:IsA("Animation") then
			local id = description and description[entry[3]] or 0
			local newId = (id and id ~= 0) and ("rbxassetid://" .. tostring(id)) or defaults[entry[1] .. "/" .. entry[2]]
			if newId and anim.AnimationId ~= newId then
				oldIds[anim.AnimationId] = true
				anim.AnimationId = newId
				changed = true
			end
		end
	end

	if not changed then
		return
	end

	local animator = humanoid:FindFirstChildOfClass("Animator")
	if animator then
		for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
			local playing = track.Animation
			if playing and oldIds[playing.AnimationId] then
				track:Stop(0)
			end
		end
	end

	setAnimateEnabled(animate, false)
	task.wait()
	setAnimateEnabled(animate, true)
end

--------------------------------------------------------------------
-- EFECTO SPLASH (Estilo Baba / Slime viscoso)
--------------------------------------------------------------------
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

	-- Gotas de baba viscosa con estiramiento según velocidad (Squash & Stretch)
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

--------------------------------------------------------------------
-- APLICAR AVATAR
--------------------------------------------------------------------
local function applyAvatar(username, isReset, animated, onFail, force)
	if not localPlayer or not username or username == "" then
		return
	end

	username = trim(username)
	-- Si ya es el avatar actual no hace nada (salvo reset o reaplicacion forzada tras respawn)
	if not force and not isReset and lastUsername and username:lower() == lastUsername:lower() then
		return
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
				-- si falla, no dejar "bloqueado" el nombre para poder reintentar
				lastUsername = previousUsername
				releaseGray(false)
				if onFail then
					onFail()
				end
			end
		end

		local description = getDescription(userId)
		if not stillValid() then
			return
		end
		if not description then
			fail()
			return
		end

		-- Rig REAL del cuerpo (no Humanoid.RigType, que puede mentir)
		local rigType = getRigType(character, humanoid)
		local isR15 = rigType == Enum.HumanoidRigType.R15

		local donor = callMethod(
			Players,
			{ "CreateHumanoidModelFromDescriptionAsync", "CreateHumanoidModelFromDescription" },
			description,
			rigType
		)
		if not stillValid() then
			if donor then
				donor:Destroy()
			end
			return
		end
		local donorHumanoid = donor and donor:FindFirstChildOfClass("Humanoid")
		if not donor or not donorHumanoid then
			if donor then
				donor:Destroy()
			end
			fail()
			return
		end

		local preloaded = false
		task.spawn(function()
			pcall(function()
				ContentProvider:PreloadAsync(donor:GetDescendants())
			end)
			preloaded = true
		end)
		local waited = 0
		while not preloaded and waited < 8 do
			task.wait(0.1)
			waited += 0.1
		end

		if not stillValid() then
			donor:Destroy()
			return
		end

		-- Esperar a que termine (y limpie) cualquier transformacion anterior
		if not waitTransformFree(currentRequest) or not stillValid() then
			donor:Destroy()
			return
		end

		-- Ajuste unico de HipHeight (R15). Un solo cambio, sin tocar la raiz ni
		-- anclar nada: el Humanoid se acomoda solo.
		local function applyHip()
			if not isR15 or not ADJUST_HIPHEIGHT then
				return
			end
			if originalHip[character] == nil then
				originalHip[character] = humanoid.HipHeight
			end
			local target = isReset and originalHip[character] or donorHumanoid.HipHeight
			if target and math.abs(humanoid.HipHeight - target) > 0.001 then
				humanoid.HipHeight = target
			end
		end

		local function doSwap()
			local records = applyDonorData(character, humanoid, donor, isR15)
			sanitizeAccessories(character)
			applyHip()
			fixColorsDeferred(character, currentRequest)
			guardAccessories(character, humanoid, records, isR15, currentRequest)
			return records
		end

		----------------------------------------------------------------
		-- Cambio instantaneo (respawn / Stop): solo swap, sin animacion
		----------------------------------------------------------------
		if not animated then
			transforming = true
			local okRun, err = pcall(doSwap)
			if not okRun then
				warn("[CopyAvatar] Error aplicando avatar: " .. tostring(err))
			end
			donor:Destroy()

			local okAnim, animErr = pcall(applyAnimations, character, humanoid, description, isR15)
			if not okAnim then
				warn("[CopyAvatar] Error aplicando animaciones: " .. tostring(animErr))
			end
			transforming = false
			return
		end

		----------------------------------------------------------------
		-- Cambio animado (encoger -> swap -> crecer) SOLO visual:
		-- el cuerpo real no se ancla, no se escala y no se mueve.
		----------------------------------------------------------------
		transforming = true
		local completed = false
		local stage = "inicio"

		local okRun, err = pcall(function()
			local function valid()
				return stillValid() and root.Parent ~= nil
			end

			-- Fase 1: fantasma del avatar VIEJO se encoge
			stage = "fantasma viejo"
			local oldGhost = makeGhost(character, root)
			local useGhost = oldGhost ~= nil
			if oldGhost then
				hideCharacter(character)
				retargetGray(oldGhost.model)
				stage = "encoger"
				local ok = animateGhost(oldGhost, root, false, currentRequest, valid)
				destroyGhost()
				if not ok then
					return
				end
			else
				warn("[CopyAvatar] No se pudo crear el fantasma de animacion: cambio directo.")
			end

			-- Swap (el cuerpo real esta oculto, invisible para ti)
			stage = "swap de apariencia"
			doSwap()

			stage = "animaciones"
			local okAnim, animErr = pcall(applyAnimations, character, humanoid, description, isR15)
			if not okAnim then
				warn("[CopyAvatar] Error aplicando animaciones: " .. tostring(animErr))
			end

			if not valid() then
				return
			end

			-- Fase 2: fantasma del avatar NUEVO crece
			if useGhost then
				stage = "fantasma nuevo"
				local newGhost = makeGhost(character, root)
				if newGhost then
					retargetGray(newGhost.model)
					stage = "crecer"
					local ok = animateGhost(newGhost, root, true, currentRequest, valid)
					if not ok then
						return
					end
				end
			end

			completed = true
		end)

		----------------------------------------------------------------
		-- LIMPIEZA: siempre se ejecuta (exito, cancelacion o error)
		----------------------------------------------------------------
		destroyGhost()
		showCharacter()
		if gray and gray.character == character then
			retargetGray(character)
		end
		donor:Destroy()
		transforming = false

		if not okRun then
			warn("[CopyAvatar] Error en la transformacion (etapa: " .. stage .. "): " .. tostring(err))
		end

		if currentRequest == requestId then
			if completed then
				splash(character, humanoid)
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

--------------------------------------------------------------------
-- API
--------------------------------------------------------------------
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

	-- Bug 4: Tip "Username"
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

	-- Bug 5: Sistema robusto para reconocer "name" / apodos / comillas / prefijos automáticamente
	local function parseInput(text)
		text = trim(text)
		text = (text:gsub("\u{201C}", '"'):gsub("\u{201D}", '"'))

		-- Si usa prefijo "name:" o "user:" o "@"
		local prefixed = text:match("^%s*[%w_]+%s*:%s*(.+)$") or text:match("^%s*@(.+)$")
		if prefixed then
			return trim(prefixed), true
		end

		-- Si está entre comillas
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

		-- Intentar como usuario exacto; si falla y no se intentó búsqueda por servidor, buscar en servidor
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
		if active and lastUsername and lastUsername:lower() ~= localPlayer.Name:lower() then
			task.spawn(function()
				character:WaitForChild("Humanoid", 10)
				character:WaitForChild("HumanoidRootPart", 10)
				local t = 0
				while not localPlayer:HasAppearanceLoaded() and t < 10 do
					task.wait(0.2)
					t += 0.2
				end
				task.wait(0.5)
				if active and lastUsername and localPlayer.Character == character then
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
