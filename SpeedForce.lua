local M = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")
local ContentProvider = game:GetService("ContentProvider")
local LocalizationService = game:GetService("LocalizationService")

local localPlayer = nil
local keys = nil
local active = false
local connections = {}

local gui, mainFrame, setPanelOpen
local isOpen = false
local toggleKey = Enum.KeyCode.F5
local meterLabel, meterGradient, meterNeedle, meterNeedleParts
local meterFrac, meterColorFrac = 0, -1

local character, humanoid, rootPart
local movementAttachment, linearVelocity
local isEnabled = true
local DEFAULT_SPEED = 162.5 -- x2 (maximo sin enemigos cerca) = 325 studs/s
local currentSpeed = DEFAULT_SPEED

-- Zonas de multiplicador (configurables desde "Mas opciones"):
--   cerca  (hasta nearDist)           -> nearMult
--   medio  (nearDist - farDist)       -> midMult
--   lejos  (mas alla de farDist) / sin enemigos / boost -> farMult
-- Cada frontera se mezcla en una franja suave (smoothstep) para evitar saltos.
local DEFAULT_ZONES = {
	nearDist = 15,
	farDist = 45,
	nearMult = 1,
	midMult = 1.35,
	farMult = 2,
}
local zones = {}
local function resetZones()
	for k, v in pairs(DEFAULT_ZONES) do
		zones[k] = v
	end
end
resetZones()

local BAND_NEAR_FRAC = 1 / 3  -- semi-ancho de la franja cerca/medio = nearDist * 1/3 (15 -> +-5)
local BAND_FAR_FRAC = 2 / 9   -- semi-ancho de la franja medio/lejos = farDist * 2/9 (45 -> +-10)
-- Bonus por movimiento (originales), aplicados de forma suave y topados en el multiplicador maximo
local BONUS_TOWARD_MID = 1.15     -- avanzar hacia el enemigo (zona media)
local BONUS_STRAFE_MID = 1.10     -- moverte de lado (zona media)
local BONUS_STRAFE_NEAR = 1.05    -- moverte de lado (zona cercana)
local MULT_SMOOTH_RATE = 3        -- mayor = el multiplicador reacciona mas rapido
local smoothMult = zones.farMult

local function smoothStep(lo, hi, x)
	local t = math.clamp((x - lo) / (hi - lo), 0, 1)
	return t * t * (3 - 2 * t)
end
local gameBaseSpeed = 16
local currentSmoothSpeed = 16

local isExploding = false
local DASH_COOLDOWN = 1.2
local lastDashEnd = 0
local boostEndTime = 0
local EXPLOSION_BASE_FORCE = 130

local C_BLACK = Color3.fromRGB(15, 15, 20)
local C_PURPLE = Color3.fromRGB(100, 50, 150)
local C_TEXT = Color3.fromRGB(255, 255, 255)
local C_SUB = Color3.fromRGB(180, 180, 180)

local TAG = "AFO_SpeedForce"
local createdObjects = {}
local sessionId = 0
local heartbeatConn = nil
local startPhysicsLoop

local env = (getgenv and getgenv()) or _G

local SILENT_ATTR = "AFO_SilentStop"

local I18N = {}
I18N.strings = {
	es = {
		title = "SPEEDFORCE",
		placeholder = "Velocidad...",
		on = "Prendido",
		off = "Apagado",
		invalid = "Inv\195\161lido",
		more = "M\195\161s opciones",
		less = "Menos opciones",
		zonesTitle = "MULTIPLICADORES",
		zoneNear = "Cerca",
		zoneMid = "Medio",
		zoneFar = "Lejos",
		colUntil = "HASTA",
		colMult = "MULT.",
		colSpeed = "STUDS/S",
		zonesHint = "Distancia en studs al enemigo m\195\161s cercano",
	},
	en = {
		title = "SPEEDFORCE",
		placeholder = "Speed...",
		on = "On",
		off = "Off",
		invalid = "Invalid",
		more = "More options",
		less = "Less options",
		zonesTitle = "MULTIPLIERS",
		zoneNear = "Near",
		zoneMid = "Mid",
		zoneFar = "Far",
		colUntil = "UP TO",
		colMult = "MULT.",
		colSpeed = "STUDS/S",
		zonesHint = "Distance in studs to the nearest enemy",
	},
}
I18N.markers = {
	es = {
		"personajes", "despert", "sobrecarga", "presiona", "patada", "disparo", "ataque", "rel\195\161mpago", "relampago",
		"velocidad", "aplicar", "jugador", "ajustes", "configuraci\195\179n", "configuracion", "tienda", "misiones",
		"inventario", "amigos", "habilidades", "equipo", "m\195\161xim", "maxim", "nivel de", "salir", "cerrar",
	},
	en = {
		"characters", "awaken", "overload", "press ", "kick", "shot", "attack", "lightning", "speed", "apply",
		"player", "settings", "shop", "quests", "inventory", "friends", "skills", "team", "maximum", "level of",
		"leave", "close",
	},
}
I18N.forced = nil

function I18N.score(text, scores)
	text = string.lower(text)
	for lang, markers in pairs(I18N.markers) do
		for _, marker in ipairs(markers) do
			if text:find(marker, 1, true) then
				scores[lang] = scores[lang] + 1
			end
		end
	end
	if text:find("[\195\161\195\169\195\173\195\179\195\186\195\177\194\191\194\161]") then
		scores.es = scores.es + 1
	end
end

function I18N.detect()
	if I18N.forced and I18N.strings[I18N.forced] then
		return I18N.forced
	end
	local code = ""
	pcall(function()
		code = string.lower(LocalizationService.RobloxLocaleId or "")
	end)
	if code == "" then
		pcall(function()
			code = string.lower(LocalizationService.SystemLocaleId or "")
		end)
	end
	local prefix = code:sub(1, 2)
	if I18N.strings[prefix] then
		return prefix
	end
	local scores = { es = 0, en = 0 }
	pcall(function()
		local playerGui = localPlayer and localPlayer:FindFirstChildOfClass("PlayerGui")
		if not playerGui then
			return
		end
		local checked = 0
		for _, d in ipairs(playerGui:GetDescendants()) do
			if (d:IsA("TextLabel") or d:IsA("TextButton")) and d.Text ~= "" then
				if not d:FindFirstAncestor("AFO_AvatarChanger") and not d:FindFirstAncestor("AFO_CustomMovement") then
					I18N.score(d.Text, scores)
				end
				checked = checked + 1
				if checked > 3000 then
					break
				end
			end
		end
	end)
	if scores.es ~= scores.en then
		return scores.es > scores.en and "es" or "en"
	end
	return "en"
end

local currentLang = "en"
local applyLanguage

local function L(key)
	local t = I18N.strings[currentLang] or I18N.strings.en
	return t[key] or I18N.strings.en[key] or ""
end

local SFX_ON_ID = "rbxassetid://118075222341359"
local SFX_OFF_ID = "rbxassetid://112416614144985"
local SFX_VOLUME = 4
local currentSfx = nil

local function playSfx(id)
	if currentSfx then
		local old = currentSfx
		currentSfx = nil
		pcall(function()
			old:Stop()
			old:Destroy()
		end)
	end
	local sound = Instance.new("Sound")
	sound.Name = "AFO_SpeedForceSfx"
	sound.SoundId = id
	sound.Volume = SFX_VOLUME
	sound.Parent = SoundService
	currentSfx = sound
	sound.Ended:Once(function()
		if currentSfx == sound then
			currentSfx = nil
		end
		sound:Destroy()
	end)
	Debris:AddItem(sound, 20)
	sound:Play()
end

local function preloadSfx()
	task.spawn(function()
		local list = {}
		for _, id in ipairs({ SFX_ON_ID, SFX_OFF_ID }) do
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

local FX = {
	DURATION = 0.42,
	TAIL = 2.3,
	BOLTS = 14,
	POINTS = 7,
	FORK_AT = 4,
	FORK_CHANCE = 0.7,
	GOLD_CHANCE = 0.3,
	RED_CHANCE = 0.3,
	OUTER_MIN = 5,
	OUTER_MAX = 11,
	LEN_MIN = 2.6,
	LEN_MAX = 5.5,
	JITTER = 0.6,
	STEP = 0.022,
	PULSE_TIME = 0.15,
	LIGHT_RANGE = 24,
	AURA_TIME = 0.5,
	GLOW_TIME = 0.95,
	STAR_RATE_RING = 50,
	STAR_RATE_GLOW = 16,
	RING_TIME = 0.65,
	RING_SEGMENTS = 36,
	RING_STEP = 0.025,
	SPARK_RATE_RING = 34,
	RING_RADIUS = 15,
	FEET_SMOKE_RATE = 26,
	FEET_SMOKE_TIME = 1.0,
	FEET_PUFF = 20,
}

local FX_COL = {
	BLACK = Color3.new(0, 0, 0),
	V_GLOW = Color3.fromRGB(130, 40, 225),
	V_BODY = Color3.fromRGB(190, 125, 255),
	V_CORE = Color3.fromRGB(255, 246, 200),
	G_GLOW = Color3.fromRGB(255, 180, 25),
	G_BODY = Color3.fromRGB(255, 214, 50),
	G_CORE = Color3.fromRGB(255, 252, 225),
	H_GLOW = Color3.fromRGB(255, 205, 50),
	H_BODY = Color3.fromRGB(255, 244, 170),
	H_CORE = Color3.fromRGB(255, 255, 255),
	R_GLOW = Color3.fromRGB(190, 10, 25),
	R_BODY = Color3.fromRGB(255, 45, 40),
	R_CORE = Color3.fromRGB(255, 190, 175),
	RH_GLOW = Color3.fromRGB(255, 55, 35),
	RH_BODY = Color3.fromRGB(255, 125, 105),
	RH_CORE = Color3.fromRGB(255, 240, 235),
	AURA_FILL = Color3.fromRGB(150, 60, 255),
	AURA_EDGE = Color3.fromRGB(255, 220, 120),
	AURA_HOT = Color3.fromRGB(255, 240, 200),
}

local RING_STOPS_GLOW = {
	Color3.fromRGB(255, 205, 70),
	Color3.fromRGB(255, 140, 80),
	Color3.fromRGB(255, 45, 40),
	Color3.fromRGB(235, 85, 190),
	Color3.fromRGB(150, 65, 245),
	Color3.fromRGB(60, 35, 175),
}
local RING_STOPS_CORE = {
	Color3.fromRGB(255, 255, 255),
	Color3.fromRGB(255, 240, 175),
	Color3.fromRGB(255, 190, 175),
	Color3.fromRGB(255, 205, 230),
	Color3.fromRGB(215, 175, 255),
	Color3.fromRGB(130, 95, 235),
}

local function rampColor(stops, t)
	local n = #stops
	local pos = math.clamp(t, 0, 1) * (n - 1)
	local i = math.floor(pos)
	if i >= n - 1 then return stops[n] end
	return stops[i + 1]:Lerp(stops[i + 2], pos - i)
end

local FX_LAYERS = { "dark", "glow", "body", "core" }
local FX_WIDTH = { dark = 0.62, glow = 0.4, body = 0.15, core = 0.055 }
local FX_EMISSION = { dark = 0, glow = 1, body = 0.55, core = 1 }
local FX_KIND_PREFIX = { violet = "V_", gold = "G_", red = "R_" }
local FX_HOT_PREFIX = { violet = "H_", gold = "H_", red = "RH_" }
local FX_OPACITY = { dark = 0.55, glow = 0.55, body = 0.95, core = 1 }
local FX_ZOFFSET = { dark = 0, glow = 0.01, body = 0.02, core = 0.03 }

local FX_SPARK_TEX = "rbxasset://textures/particles/sparkles_main.dds"
local FX_SMOKE_TEX = "rbxasset://textures/particles/smoke_main.dds"

local FX_NAME = "AFO_SpeedForceFx"
local fxState = nil
local fxWarned = false

local function failInert(what, err)
	if fxWarned then return end
	fxWarned = true
	warn("[SpeedForce] " .. what .. " falló (se ignora y el resto sigue): " .. tostring(err))
end

local function cancelFx()
	local state = fxState
	fxState = nil
	if not state then return end
	if state.conn then
		pcall(function() state.conn:Disconnect() end)
	end
	for i = #state.objects, 1, -1 do
		pcall(function() state.objects[i]:Destroy() end)
	end
end

local function nseq(...)
	local a = { ... }
	local kps = {}
	for i = 1, #a, 2 do
		table.insert(kps, NumberSequenceKeypoint.new(a[i], a[i + 1]))
	end
	return NumberSequence.new(kps)
end

local function cseq(...)
	local a = { ... }
	local kps = {}
	for i = 1, #a, 2 do
		table.insert(kps, ColorSequenceKeypoint.new(a[i], a[i + 1]))
	end
	return ColorSequence.new(kps)
end

local function layerColor(bolt, layer, hot)
	if layer == "dark" then return FX_COL.BLACK end
	local prefix = hot and FX_HOT_PREFIX[bolt.kind] or FX_KIND_PREFIX[bolt.kind]
	return FX_COL[prefix .. string.upper(layer)]
end

local function recolor(bolt, hot)
	bolt.hot = hot
	for _, layer in ipairs(FX_LAYERS) do
		local seq = ColorSequence.new(layerColor(bolt, layer, hot))
		for _, beam in ipairs(bolt.layers[layer]) do
			beam.Color = seq
		end
	end
end

local function rerollJitter(bolt)
	for k = 1, FX.POINTS do
		local frac = (k - 1) / (FX.POINTS - 1)
		local amp = FX.JITTER * math.sin(math.pi * frac)
		bolt.jit[k] = bolt.p1 * ((math.random() - 0.5) * 2 * amp)
			+ bolt.p2 * ((math.random() - 0.5) * 2 * amp)
	end
	for k = 1, 2 do
		bolt.bJit[k] = bolt.p1 * ((math.random() - 0.5) * 0.8) + bolt.p2 * ((math.random() - 0.5) * 0.8)
	end
	bolt.flick = math.random() < 0.14 and 0.2 or (0.55 + math.random() * 0.45)
end

local function makeEmitter(parent, o)
	local e = Instance.new("ParticleEmitter")
	e.Name = FX_NAME
	e.Enabled = false
	e.Rate = 0
	e.Texture = o.texture or FX_SPARK_TEX
	e.Color = o.color
	e.Size = o.size
	e.Transparency = o.transparency
	e.Lifetime = o.lifetime
	e.Speed = o.speed
	e.Drag = o.drag or 0
	e.Acceleration = o.accel or Vector3.zero
	e.LightEmission = o.light
	e.LightInfluence = 0
	if o.streak then
		e.Orientation = Enum.ParticleOrientation.VelocityParallel
		e.Rotation = NumberRange.new(0, 0)
		e.RotSpeed = NumberRange.new(0, 0)
	else
		e.Rotation = NumberRange.new(0, 360)
		e.RotSpeed = NumberRange.new(-120, 120)
	end
	e.Shape = o.shape or Enum.ParticleEmitterShape.Sphere
	e.ShapeStyle = o.surface and Enum.ParticleEmitterShapeStyle.Surface or Enum.ParticleEmitterShapeStyle.Volume
	e.ShapeInOut = o.inward and Enum.ParticleEmitterShapeInOut.Inward or Enum.ParticleEmitterShapeInOut.Outward
	e.LockedToPart = not o.world
	e.Parent = parent
	return e
end

local function makeBlock(parent, size, color, material, shape)
	local part = Instance.new("Part")
	part.Name = FX_NAME
	part.Shape = shape or Enum.PartType.Block
	part.Material = material or Enum.Material.SmoothPlastic
	part.Color = color or FX_COL.BLACK
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Massless = true
	part.Transparency = 1
	part.Size = size
	part.Parent = parent
	return part
end

local function bodyRootOf(m)
	return m.PrimaryPart or m:FindFirstChild("HumanoidRootPart") or m:FindFirstChild("Torso")
end

local function pickChest(m, r)
	return (m and (m:FindFirstChild("UpperTorso") or m:FindFirstChild("Torso"))) or r
end

-- A qué cuerpo se le pone el efecto: al que la cámara te está mostrando.
-- Normalmente es tu personaje, pero con clones (p. ej. el modo 4D de Omniblock) tu cuerpo real
-- queda invisible en otro lado y lo que ves es el clon, mientras la cámara sigue una parte suelta.
-- Devuelve la parte raíz y el modelo (el modelo puede ser nil si solo hay una parte).
local function resolveBody(realRoot)
	if not realRoot or not realRoot.Parent then return nil end
	local char = realRoot.Parent
	local cam = workspace.CurrentCamera
	local subject = cam and cam.CameraSubject
	if not subject or not subject.Parent then return realRoot, char end

	-- cámara siguiendo un Humanoid: tu personaje, o un clon que tenga Humanoid
	if subject:IsA("Humanoid") then
		local m = subject.Parent
		if m ~= char and m:IsA("Model") then
			local owner = Players:GetPlayerFromCharacter(m)
			if not owner or owner == localPlayer then
				local r = bodyRootOf(m)
				if r then return r, m end
			end
		end
		return realRoot, char
	end

	-- cámara siguiendo una parte suelta (Omniblock 4D): buscar el clon que está junto a ella
	if subject:IsA("BasePart") and not subject:IsDescendantOf(char) then
		local best, bestDist = nil, 25
		for _, m in ipairs(workspace:GetChildren()) do
			if m:IsA("Model") and m ~= char and m.Name == char.Name and not Players:GetPlayerFromCharacter(m) then
				local r = bodyRootOf(m)
				if r then
					local d = (r.Position - subject.Position).Magnitude
					if d < bestDist then best, bestDist = m, d end
				end
			end
		end
		if best then return bodyRootOf(best), best end
		-- sin clon reconocible: se ancla el efecto a la parte que sigue la cámara (sin silueta)
		return subject, nil
	end

	return realRoot, char
end

local function playElectricFx(realRoot, mode)
	cancelFx()
	if not realRoot or not realRoot.Parent then return end
	local root, model = resolveBody(realRoot)
	if not root or not root.Parent then return end
	local isIn = (mode == "in")

	local state = { objects = {}, fast = {}, conn = nil }
	fxState = state
	local TOTAL = FX.DURATION + FX.TAIL

	local function track(obj, isFast)
		table.insert(state.objects, obj)
		if isFast then table.insert(state.fast, obj) end
		Debris:AddItem(obj, TOTAL + 1.5)
		return obj
	end

	local fxParent = workspace.CurrentCamera or workspace
	local startPos = root.Position

	local chestPart = pickChest(model, root)

	local carrier = track(makeBlock(fxParent, Vector3.new(12, 12, 12)))
	carrier.CFrame = CFrame.new(startPos)
	local core = track(Instance.new("Attachment"))
	core.Name = FX_NAME
	core.Parent = carrier

	local auraBox = track(makeBlock(fxParent, Vector3.new(3.2, 5.8, 2.4)))
	auraBox.CFrame = CFrame.new(startPos)

	local sparkAlpha = nseq(0, 0, 0.7, 0.25, 1, 1)
	local gravity = Vector3.new(0, -70, 0)

	local inViolet = track(makeEmitter(carrier, {
		surface = true, inward = true, streak = true, light = 0.7,
		color = cseq(0, Color3.fromRGB(200, 140, 255), 0.5, Color3.fromRGB(125, 45, 220), 1, Color3.fromRGB(30, 10, 60)),
		size = nseq(0, 0.36, 1, 0.03), transparency = sparkAlpha,
		lifetime = NumberRange.new(0.14, 0.22), speed = NumberRange.new(34, 52),
	}))
	local inGold = track(makeEmitter(carrier, {
		surface = true, inward = true, streak = true, light = 0.9,
		color = cseq(0, Color3.fromRGB(255, 250, 215), 0.4, Color3.fromRGB(255, 224, 70), 1, Color3.fromRGB(150, 60, 200)),
		size = nseq(0, 0.34, 1, 0.03), transparency = sparkAlpha,
		lifetime = NumberRange.new(0.12, 0.2), speed = NumberRange.new(38, 58),
	}))
	local burstGold = track(makeEmitter(core, {
		streak = true, light = 1,
		color = cseq(0, Color3.fromRGB(255, 252, 225), 0.35, Color3.fromRGB(255, 218, 60), 1, Color3.fromRGB(140, 50, 210)),
		size = nseq(0, 0.4, 1, 0.03), transparency = sparkAlpha,
		lifetime = NumberRange.new(0.2, 0.45), speed = NumberRange.new(40, 95), drag = 2.2,
		accel = gravity,
	}))
	local burstViolet = track(makeEmitter(core, {
		streak = true, light = 0.8,
		color = cseq(0, Color3.fromRGB(215, 160, 255), 0.5, Color3.fromRGB(120, 40, 215), 1, Color3.fromRGB(25, 8, 50)),
		size = nseq(0, 0.44, 1, 0.03), transparency = sparkAlpha,
		lifetime = NumberRange.new(0.18, 0.4), speed = NumberRange.new(30, 80), drag = 2.4,
		accel = gravity,
	}))
	local smoke = track(makeEmitter(core, {
		texture = FX_SMOKE_TEX, light = 0,
		color = cseq(0, Color3.fromRGB(120, 12, 18), 1, Color3.fromRGB(5, 2, 3)),
		size = nseq(0, 0.8, 1, 2.4), transparency = nseq(0, 0.62, 0.5, 0.8, 1, 1),
		lifetime = NumberRange.new(0.4, 0.7), speed = NumberRange.new(3, 10), drag = 1.5,
		accel = Vector3.new(0, 5, 0),
	}))
	local flare = track(makeEmitter(core, {
		texture = FX_SMOKE_TEX, light = 1,
		color = cseq(0, Color3.fromRGB(255, 248, 200), 0.4, Color3.fromRGB(200, 120, 255), 1, Color3.fromRGB(110, 40, 200)),
		size = nseq(0, 4, 1, 8), transparency = nseq(0, 0.55, 1, 1),
		lifetime = NumberRange.new(0.09, 0.13), speed = NumberRange.new(0, 0),
	}))

	local auraSmoke = track(makeEmitter(auraBox, {
		shape = Enum.ParticleEmitterShape.Box, surface = true,
		texture = FX_SMOKE_TEX, light = 0,
		color = cseq(0, Color3.fromRGB(110, 10, 16), 1, Color3.fromRGB(4, 2, 3)),
		size = nseq(0, 1.1, 1, 2.6), transparency = nseq(0, 0.75, 0.4, 0.82, 1, 1),
		lifetime = NumberRange.new(0.4, 0.7), speed = NumberRange.new(0, 1.5), drag = 1,
		accel = Vector3.new(0, 7, 0),
	}))

	local function calcFootOffset()
		local off = root.Size.Y / 2 + 2
		local hum = model and model:FindFirstChildOfClass("Humanoid")
		if hum and hum.RigType == Enum.HumanoidRigType.R15 then
			off = root.Size.Y / 2 + hum.HipHeight
		end
		return off
	end
	local footOffset = calcFootOffset()
	local function feetCFrame()
		return CFrame.new(root.Position - Vector3.new(0, footOffset - 0.2, 0))
	end
	local feetPart = track(makeBlock(fxParent, Vector3.new(0.3, 0.1, 0.3)))
	feetPart.CFrame = feetCFrame()

	-- humo negro con brasas rojas: nace rojizo y se apaga a negro
	local feetSmokeColor = cseq(0, Color3.fromRGB(150, 16, 22), 0.3, Color3.fromRGB(48, 6, 10), 1, Color3.fromRGB(4, 2, 3))
	-- LockedToPart: la nube viaja con el cuerpo; nace en un punto central y se abre chica y suave
	local feetPuff = track(makeEmitter(feetPart, {
		shape = Enum.ParticleEmitterShape.Disc,
		texture = FX_SMOKE_TEX, light = 0,
		color = feetSmokeColor,
		size = nseq(0, 0.7, 0.5, 2.6, 1, 3.4),
		transparency = nseq(0, 1, 0.12, 0.84, 0.5, 0.92, 1, 1),
		lifetime = NumberRange.new(1.0, 1.5), speed = NumberRange.new(0.3, 5), drag = 2.4,
		accel = Vector3.zero,
	}))
	local feetSmoke = track(makeEmitter(feetPart, {
		shape = Enum.ParticleEmitterShape.Disc,
		texture = FX_SMOKE_TEX, light = 0,
		color = feetSmokeColor,
		size = nseq(0, 0.6, 0.5, 2.0, 1, 2.7),
		transparency = nseq(0, 1, 0.15, 0.86, 0.55, 0.93, 1, 1),
		lifetime = NumberRange.new(0.9, 1.4), speed = NumberRange.new(1, 3.5), drag = 2,
		accel = Vector3.zero,
	}))
	local smokeStart = isIn and (FX.DURATION * 0.62) or 0

	local light = track(Instance.new("PointLight"))
	light.Name = FX_NAME
	light.Color = FX_COL.V_GLOW
	light.Range = FX.LIGHT_RANGE
	light.Brightness = 0
	light.Shadows = false
	light.Parent = carrier

	local silhouette = track(Instance.new("Highlight"))
	silhouette.Name = FX_NAME
	silhouette.DepthMode = Enum.HighlightDepthMode.Occluded
	silhouette.FillColor = FX_COL.AURA_FILL
	silhouette.OutlineColor = FX_COL.AURA_EDGE
	silhouette.FillTransparency = 1
	silhouette.OutlineTransparency = 1
	-- la silueta solo va en tu personaje real: un clon (Omniblock 4D) ya trae su propio Highlight
	-- con su relleno de color, y dos Highlight sobre el mismo modelo se pisan entre sí
	local function aimSilhouette()
		if model and model == realRoot.Parent then
			silhouette.Adornee = model
			silhouette.Parent = model
		else
			silhouette.Adornee = nil
			silhouette.Parent = nil
		end
	end
	aimSilhouette()

	local S = FX.RING_SEGMENTS
	local ringAtt, ringGlow, ringCore = {}, {}, {}
	local ringShown = false
	local ringPart = track(makeBlock(fxParent, Vector3.one))
	ringPart.CFrame = CFrame.new(chestPart.Position)
	local starY = {}
	for k = 1, S do
		local att = track(Instance.new("Attachment"))
		att.Name = FX_NAME
		att.Parent = ringPart
		ringAtt[k] = att
		starY[k] = ((k * 0.618034) % 1 - 0.7) * 3.6
	end

	-- paleta en ciclo cerrado (dorado > naranja > rojo > rosa > violeta > índigo > de vuelta):
	-- cada punto tiene su color y entre puntos el color se funde sin saltos
	local ringPhase = math.random()
	local ringGlowCol, ringCoreCol = {}, {}
	for k = 1, S do
		local u = ((k - 1) / S + ringPhase) % 1
		local t = 1 - math.abs(2 * u - 1)
		local g = rampColor(RING_STOPS_GLOW, t)
		ringGlowCol[k] = g
		ringCoreCol[k] = rampColor(RING_STOPS_CORE, t):Lerp(g, 0.4)
	end

	local starStride = math.max(1, math.floor(S / 12))
	local stars = {}
	for k = 1, S, starStride do
		table.insert(stars, track(makeEmitter(ringAtt[k], {
			light = 1,
			color = cseq(0, ringCoreCol[k], 1, ringGlowCol[k]),
			size = nseq(0, 0.55, 0.5, 0.4, 1, 0.02),
			transparency = nseq(0, 0.1, 0.65, 0.35, 1, 1),
			lifetime = NumberRange.new(0.35, 0.65), speed = NumberRange.new(0.4, 1.8), drag = 3,
		})))
	end

	local ringJit, ringFlick = {}, {}
	for k = 1, S do
		ringJit[k] = Vector3.zero
		ringFlick[k] = 1
	end
	local sparks, forks = {}, {}

	if not isIn then
		local function addRingBeam(list, a0, a1, w0, w1, colorSeq, emission)
			local beam = track(Instance.new("Beam"))
			beam.Name = FX_NAME
			beam.Attachment0 = a0
			beam.Attachment1 = a1
			beam.Color = colorSeq
			beam.LightEmission = emission
			beam.LightInfluence = 0
			beam.FaceCamera = true
			beam.Segments = 1
			beam.Width0 = w0
			beam.Width1 = w1
			beam.Transparency = NumberSequence.new(1)
			beam.Parent = ringPart
			table.insert(list, beam)
			return beam
		end
		for k = 1, S do
			local nk = k % S + 1
			addRingBeam(ringGlow, ringAtt[k], ringAtt[nk], 1.2, 1.2, cseq(0, ringGlowCol[k], 1, ringGlowCol[nk]), 1)
			addRingBeam(ringCore, ringAtt[k], ringAtt[nk], 0.32, 0.32, cseq(0, ringCoreCol[k], 1, ringCoreCol[nk]), 1)
		end

		-- chispas que salen disparadas del aro
		for k = 2, S, starStride do
			table.insert(sparks, track(makeEmitter(ringAtt[k], {
				streak = true, light = 1,
				color = cseq(0, ringCoreCol[k], 1, ringGlowCol[k]),
				size = nseq(0, 0.38, 1, 0.03), transparency = sparkAlpha,
				lifetime = NumberRange.new(0.12, 0.3), speed = NumberRange.new(10, 26), drag = 2,
			})))
		end

		-- ramitas de rayo que aparecen y desaparecen sobre el aro
		local function newRingAtt()
			local att = track(Instance.new("Attachment"))
			att.Name = FX_NAME
			att.Parent = ringPart
			return att
		end
		for k = 1, S, 3 do
			local f = {
				idx = k, a1 = newRingAtt(), a2 = newRingAtt(),
				o1 = Vector3.zero, o2 = Vector3.zero, glow = {}, core = {}, on = false,
			}
			local gcol, ccol = ColorSequence.new(ringGlowCol[k]), ColorSequence.new(ringCoreCol[k])
			addRingBeam(f.glow, ringAtt[k], f.a1, 0.8, 0.45, gcol, 1)
			addRingBeam(f.glow, f.a1, f.a2, 0.45, 0.12, gcol, 1)
			addRingBeam(f.core, ringAtt[k], f.a1, 0.22, 0.12, ccol, 1)
			addRingBeam(f.core, f.a1, f.a2, 0.12, 0.04, ccol, 1)
			table.insert(forks, f)
		end
	end

	local spread = isIn and 0.25 or 0.1
	local N = FX.POINTS
	local bolts = {}
	for i = 1, FX.BOLTS do
		local a = math.random() * math.pi * 2
		local y = math.clamp((math.random() - 0.45) * 1.5, -0.7, 0.8)
		local h = math.sqrt(1 - y * y)
		local dir = Vector3.new(math.cos(a) * h, y, math.sin(a) * h)
		local p1 = dir:Cross(Vector3.yAxis).Unit
		local p2 = dir:Cross(p1).Unit
		local phi = math.random() * math.pi * 2
		local bdir = (dir * 0.55 + (p1 * math.cos(phi) + p2 * math.sin(phi)) * 0.85).Unit
		local bdir2 = (bdir + (p1 * (math.random() - 0.5) + p2 * (math.random() - 0.5)) * 0.9).Unit

		local kind
		if i == 1 then
			kind = "violet"
		elseif i == 2 then
			kind = "gold"
		elseif i == 3 then
			kind = "red"
		else
			local roll = math.random()
			kind = roll < FX.GOLD_CHANCE and "gold" or (roll < FX.GOLD_CHANCE + FX.RED_CHANCE and "red" or "violet")
		end

		local bolt = {
			dir = dir, p1 = p1, p2 = p2, bdir = bdir, bdir2 = bdir2,
			outer = FX.OUTER_MIN + math.random() * (FX.OUTER_MAX - FX.OUTER_MIN),
			len = FX.LEN_MIN + math.random() * (FX.LEN_MAX - FX.LEN_MIN),
			start = math.random() * spread,
			window = 1 - spread,
			scale = (0.8 + math.random() * 0.55) * (kind == "red" and 1.15 or 1),
			kind = kind,
			fork = math.random() < FX.FORK_CHANCE,
			flick = 1, visible = false, hot = false,
			att = {}, jit = {}, bAtt = {}, bJit = {},
			layers = { dark = {}, glow = {}, body = {}, core = {} },
		}

		local function newAtt()
			local att = track(Instance.new("Attachment"), true)
			att.Name = FX_NAME
			att.Parent = carrier
			return att
		end
		for k = 1, N do bolt.att[k] = newAtt() end
		if bolt.fork then
			bolt.bAtt[1] = newAtt()
			bolt.bAtt[2] = newAtt()
		end

		local function addBeam(layer, a0, a1, w0, w1)
			local beam = track(Instance.new("Beam"), true)
			beam.Name = FX_NAME
			beam.Attachment0 = a0
			beam.Attachment1 = a1
			beam.Color = ColorSequence.new(layerColor(bolt, layer, false))
			beam.LightEmission = FX_EMISSION[layer]
			beam.LightInfluence = 0
			beam.FaceCamera = true
			beam.Segments = 1
			beam.ZOffset = FX_ZOFFSET[layer]
			beam.Width0 = w0
			beam.Width1 = w1
			beam.Transparency = NumberSequence.new(1)
			beam.Parent = carrier
			table.insert(bolt.layers[layer], beam)
		end

		for _, layer in ipairs(FX_LAYERS) do
			local base = FX_WIDTH[layer] * bolt.scale
			for s = 1, N - 1 do
				addBeam(layer, bolt.att[s], bolt.att[s + 1],
					base * (1 - 0.7 * (s - 1) / (N - 1)), base * (1 - 0.7 * s / (N - 1)))
			end
			if bolt.fork then
				addBeam(layer, bolt.att[FX.FORK_AT], bolt.bAtt[1], base * 0.55, base * 0.38)
				addBeam(layer, bolt.bAtt[1], bolt.bAtt[2], base * 0.38, base * 0.12)
			end
		end

		rerollJitter(bolt)
		table.insert(bolts, bolt)
	end

	local pulseT0 = nil
	local function impact()
		pulseT0 = os.clock()
		flare:Emit(1)
		burstGold:Emit(isIn and 34 or 46)
		burstViolet:Emit(isIn and 22 or 30)
		smoke:Emit(isIn and 4 or 6)
		feetPuff:Emit(FX.FEET_PUFF)
	end

	local events
	if isIn then
		events = {
			{ t = 0.00, fn = function() inViolet:Emit(22) end },
			{ t = 0.08, fn = function() inViolet:Emit(18); inGold:Emit(10) end },
			{ t = 0.18, fn = function() inViolet:Emit(16); inGold:Emit(10) end },
			{ t = 0.30, fn = function() inViolet:Emit(12); inGold:Emit(8) end },
			{ t = 0.62, fn = impact },
		}
	else
		events = {
			{ t = 0.00, fn = impact },
			{ t = 0.10, fn = function() burstViolet:Emit(14) end },
			{ t = 0.22, fn = function() burstViolet:Emit(8); burstGold:Emit(8) end },
		}
	end
	local nextEvent = 1

	local invisible = NumberSequence.new(1)
	local function hideFork(f)
		for _, b in ipairs(f.glow) do b.Transparency = invisible end
		for _, b in ipairs(f.core) do b.Transparency = invisible end
		f.on = false
	end
	local t0 = os.clock()
	local lastStep = t0
	local lastRingStep = 0
	local nextResolve = 0
	local boltsCleared = false

	local function update()
		local now = os.clock()
		local elapsed = now - t0
		if elapsed >= TOTAL then
			cancelFx()
			return
		end

		-- el efecto sigue al cuerpo que estás viendo: si aparece un clon (4D) o desaparece, se muda solo
		if now >= nextResolve or not root.Parent then
			nextResolve = now + 0.12
			local r, m = resolveBody(realRoot)
			if not r or not r.Parent then
				cancelFx()
				return
			end
			if r ~= root then
				root, model = r, m
				chestPart = pickChest(model, root)
				footOffset = calcFootOffset()
				aimSilhouette()
			end
		end

		local cf = CFrame.new(root.Position)
		carrier.CFrame = cf
		auraBox.CFrame = cf
		feetPart.CFrame = feetCFrame()
		ringPart.CFrame = CFrame.new(chestPart.Position)

		local tn = elapsed / FX.DURATION
		while events[nextEvent] and tn >= events[nextEvent].t do
			local ev = events[nextEvent]
			nextEvent += 1
			ev.fn()
		end

		local inten = 0
		local hotK = 0
		local colorT = 0
		local ringU = 2
		if isIn then
			local rise = FX.DURATION * 0.62
			if elapsed < rise then
				local x = elapsed / rise
				inten = x * x * (3 - 2 * x)
			else
				local f = (elapsed - rise) / FX.GLOW_TIME
				inten = f < 1 and (1 - f) ^ 1.4 or 0
			end
			colorT = math.clamp(elapsed / (rise + FX.GLOW_TIME), 0, 1)
		elseif pulseT0 then
			local au = (now - pulseT0) / FX.AURA_TIME
			if au < 1 then
				inten = (1 - au) ^ 1.6
				hotK = math.clamp(1 - au * 2.5, 0, 1)
			end
			ringU = (now - pulseT0) / FX.RING_TIME
		end
		local level = inten * (0.88 + math.random() * 0.12)

		local lightColor
		local starRate = 0
		local sparkRate = 0
		if isIn then
			local glowNow = rampColor(RING_STOPS_GLOW, colorT)
			local coreNow = rampColor(RING_STOPS_CORE, colorT)
			silhouette.FillColor = glowNow
			silhouette.OutlineColor = coreNow
			lightColor = glowNow
			starRate = FX.STAR_RATE_GLOW * level
			local spin = elapsed * 2.2
			local orbit = 1.9 + 1.4 * colorT
			for k = 1, S do
				local ang = (k - 1) / S * math.pi * 2 + spin
				ringAtt[k].Position = Vector3.new(math.cos(ang) * orbit, starY[k], math.sin(ang) * orbit)
			end
		else
			silhouette.FillColor = FX_COL.AURA_FILL:Lerp(FX_COL.AURA_HOT, hotK)
			silhouette.OutlineColor = FX_COL.AURA_EDGE:Lerp(FX_COL.H_CORE, hotK)
			lightColor = FX_COL.V_GLOW:Lerp(FX_COL.H_BODY, hotK)
		end
		silhouette.FillTransparency = 1 - 0.5 * level
		silhouette.OutlineTransparency = 1 - 0.95 * level

		local auraOn = level > 0.03
		auraSmoke.Enabled = auraOn
		auraSmoke.Rate = 20 * level

		local sk = elapsed - smokeStart
		local smokeLive = sk < 0 and 0 or math.clamp(1 - sk / FX.FEET_SMOKE_TIME, 0, 1) ^ 1.3
		feetSmoke.Enabled = smokeLive > 0.02
		feetSmoke.Rate = FX.FEET_SMOKE_RATE * smokeLive

		light.Color = lightColor
		light.Brightness = 8 * level * level

		if not isIn and ringU < 1 then
			local ease = 1 - (1 - ringU) ^ 3
			local radius = 0.6 + FX.RING_RADIUS * ease
			local fade = (1 - ringU) ^ 1.4
			starRate = FX.STAR_RATE_RING * fade
			sparkRate = FX.SPARK_RATE_RING * fade

			-- cada ~0.025 s el aro se "sacude" de nuevo: zigzag, titileo y ramas nuevas
			local ringStep = (now - lastRingStep) >= FX.RING_STEP
			if ringStep then
				lastRingStep = now
				local rAmp = 0.35 + radius * 0.07
				local yAmp = 0.3 + radius * 0.03
				for k = 1, S do
					local sign = (k % 2 == 0) and 1 or -1
					ringJit[k] = Vector3.new(
						sign * (0.3 + math.random() * 0.7) * rAmp,
						(math.random() - 0.5) * 2 * yAmp,
						(math.random() - 0.5) * rAmp * 0.8
					)
					ringFlick[k] = math.random() < 0.12 and 0.12 or (0.6 + math.random() * 0.4)
				end
			end

			for k = 1, S do
				local ang = (k - 1) / S * math.pi * 2
				local c, sn = math.cos(ang), math.sin(ang)
				local j = ringJit[k]
				local rr = radius + j.X
				ringAtt[k].Position = Vector3.new(c * rr - sn * j.Z, j.Y, sn * rr + c * j.Z)
			end

			if ringStep then
				local widthMul = 1 - 0.5 * ringU
				for k = 1, S do
					local fl = ringFlick[k] * fade
					local wv = (0.75 + math.random() * 0.5) * widthMul
					local g, c = ringGlow[k], ringCore[k]
					g.Transparency = NumberSequence.new(1 - 0.85 * fl)
					c.Transparency = NumberSequence.new(1 - 0.95 * fl)
					g.Width0 = 1.2 * wv
					g.Width1 = 1.2 * wv
					c.Width0 = 0.32 * wv
					c.Width1 = 0.32 * wv
				end
				for _, f in ipairs(forks) do
					if math.random() < 0.55 then
						local base = ringAtt[f.idx].Position
						local flat = Vector3.new(base.X, 0, base.Z)
						local out = flat.Magnitude > 0.01 and flat.Unit or Vector3.xAxis
						local side = Vector3.new(-out.Z, 0, out.X) * ((math.random() - 0.5) * 1.4)
						local len = (0.9 + radius * 0.12) * (0.7 + math.random() * 0.6)
						f.o1 = (out * 0.7 + side + Vector3.yAxis * ((math.random() - 0.3) * 0.9)) * len
						f.o2 = f.o1 + (out * 0.8 - side * 0.6 + Vector3.yAxis * ((math.random() - 0.5) * 1.4)) * len * 0.7
						local ft = fade * (0.6 + math.random() * 0.4)
						for _, b in ipairs(f.glow) do b.Transparency = NumberSequence.new(1 - 0.85 * ft) end
						for _, b in ipairs(f.core) do b.Transparency = NumberSequence.new(1 - 0.95 * ft) end
						f.on = true
					elseif f.on then
						hideFork(f)
					end
				end
			end

			for _, f in ipairs(forks) do
				if f.on then
					local base = ringAtt[f.idx].Position
					f.a1.Position = base + f.o1
					f.a2.Position = base + f.o2
				end
			end
			ringShown = true
		elseif ringShown then
			ringShown = false
			for k = 1, S do
				ringGlow[k].Transparency = invisible
				ringCore[k].Transparency = invisible
			end
			for _, f in ipairs(forks) do
				hideFork(f)
			end
		end

		local sparksOn = sparkRate > 0.5
		for _, sp in ipairs(sparks) do
			sp.Enabled = sparksOn
			if sparksOn then
				sp.Rate = sparkRate
			end
		end

		local starsOn = starRate > 0.5
		for _, star in ipairs(stars) do
			star.Enabled = starsOn
			if starsOn then
				star.Rate = starRate
			end
		end

		if tn >= 1 then
			if not boltsCleared then
				boltsCleared = true
				for i = #state.fast, 1, -1 do
					pcall(function() state.fast[i]:Destroy() end)
				end
			end
			return
		end

		local reroll = (now - lastStep) >= FX.STEP
		if reroll then lastStep = now end

		for _, bolt in ipairs(bolts) do
			local p = (tn - bolt.start) / bolt.window
			if p > 0 and p < 1 then
				if reroll then rerollJitter(bolt) end

				local lead, lenEff, boltInten, hot
				if isIn then
					lead = bolt.outer * (1 - p ^ 3)
					local er = math.clamp((p - 0.62) / 0.38, 0, 1)
					lenEff = bolt.len * (1 - er ^ 1.5)
					boltInten = math.clamp(p / 0.1, 0, 1) * (p > 0.9 and (1 - p) / 0.1 or 1)
					hot = p > 0.78
				else
					lead = bolt.outer * (1 - (1 - p) ^ 4)
					local er = math.clamp((p - 0.3) / 0.7, 0, 1)
					lenEff = bolt.len * (1 - er ^ 1.5)
					boltInten = math.clamp(p / 0.04, 0, 1) * (1 - p ^ 2.2)
					hot = p < 0.25
				end
				boltInten = boltInten * bolt.flick

				if hot ~= bolt.hot then recolor(bolt, hot) end

				local sizeFactor = math.clamp(lenEff / bolt.len, 0, 1)
				local forkBase
				for k = 1, N do
					local kf = (k - 1) / (N - 1)
					local along = isIn and (lead + kf * lenEff) or (lead - kf * lenEff)
					along = math.max(0, along)
					local v = bolt.dir * along + bolt.jit[k] * sizeFactor
					bolt.att[k].Position = v
					if k == FX.FORK_AT then forkBase = v end
				end
				if bolt.fork then
					local b1 = forkBase + bolt.bdir * (lenEff * 0.3) + bolt.bJit[1] * sizeFactor
					local b2 = b1 + bolt.bdir2 * (lenEff * 0.28) + bolt.bJit[2] * sizeFactor
					bolt.bAtt[1].Position = b1
					bolt.bAtt[2].Position = b2
				end

				for _, layer in ipairs(FX_LAYERS) do
					local seq = NumberSequence.new(1 - boltInten * FX_OPACITY[layer])
					for _, beam in ipairs(bolt.layers[layer]) do
						beam.Transparency = seq
					end
				end
				bolt.visible = true
			elseif bolt.visible then
				for _, layer in ipairs(FX_LAYERS) do
					for _, beam in ipairs(bolt.layers[layer]) do
						beam.Transparency = invisible
					end
				end
				bolt.visible = false
			end
		end
	end

	state.conn = RunService.RenderStepped:Connect(function()
		if fxState ~= state then return end
		local ok, err = pcall(update)
		if not ok then
			cancelFx()
			failInert("efecto (frame)", err)
		end
	end)
end

local function safeSfx(id)
	local ok, err = pcall(playSfx, id)
	if not ok then failInert("sonido", err) end
end

local function safeFx(root, mode)
	local ok, err = pcall(playElectricFx, root, mode)
	if not ok then
		cancelFx()
		failInert("efecto", err)
	end
end

local function disconnectAll()
	for _, conn in ipairs(connections) do
		if conn then
			pcall(function() conn:Disconnect() end)
		end
	end
	table.clear(connections)
	heartbeatConn = nil
end

local GAUGE_LOW = Color3.fromRGB(0, 255, 140)
local GAUGE_MID = Color3.fromRGB(255, 220, 60)
local GAUGE_HIGH = Color3.fromRGB(255, 60, 110)
local NEEDLE_MIN, NEEDLE_MAX = -80, 80

local function gaugeColor(frac)
	if frac < 0.5 then
		return GAUGE_LOW:Lerp(GAUGE_MID, frac / 0.5)
	end
	return GAUGE_MID:Lerp(GAUGE_HIGH, (frac - 0.5) / 0.5)
end

local function updateMeter(speed, dt)
	if not meterLabel or not meterLabel.Parent then return end
	meterLabel.Text = string.format("%.1f", speed)

	-- Escala dinamica: 0 hasta (velocidad base X) * (multiplicador mas alto). Por defecto X * 2.
	local maxMult = math.max(zones.nearMult, zones.midMult, zones.farMult)
	local maxSpeed = math.max(currentSpeed * maxMult, 1)
	local target = math.clamp(speed / maxSpeed, 0, 1)
	meterFrac = meterFrac + (target - meterFrac) * math.clamp(12 * (dt or 1 / 60), 0, 1)

	if meterNeedle then
		meterNeedle.Rotation = NEEDLE_MIN + meterFrac * (NEEDLE_MAX - NEEDLE_MIN)
	end

	if math.abs(meterFrac - meterColorFrac) > 0.01 or meterFrac == 0 then
		meterColorFrac = meterFrac
		local c = gaugeColor(meterFrac)
		if meterGradient then
			meterGradient.Color = ColorSequence.new(c:Lerp(Color3.new(1, 1, 1), 0.6), c)
		end
		if meterNeedleParts then
			for _, part in ipairs(meterNeedleParts) do
				part.BackgroundColor3 = c
			end
		end
	end
end

local function stopPhysicsLoop()
	if heartbeatConn then
		pcall(function() heartbeatConn:Disconnect() end)
		heartbeatConn = nil
	end
	updateMeter(0, 1)
end

local function destroyTracked()
	for i = #createdObjects, 1, -1 do
		local obj = createdObjects[i]
		pcall(function() obj:Destroy() end)
	end
	table.clear(createdObjects)
	linearVelocity = nil
	movementAttachment = nil
end

local function isLegacyLeftover(obj)
	if not obj:IsA("LinearVelocity") or obj.Name ~= "LinearVelocity" then return false end
	if not obj.Parent or obj.Parent.Name ~= "HumanoidRootPart" then return false end
	if obj.ForceLimitMode ~= Enum.ForceLimitMode.PerAxis then return false end
	if obj.RelativeTo ~= Enum.ActuatorRelativeTo.World then return false end
	local f = obj.MaxAxesForce
	if f.Y ~= 0 or f.X ~= f.Z then return false end
	if f.X ~= 0 and f.X ~= 1e5 and f.X ~= 45000 then return false end
	local att = obj.Attachment0
	return att ~= nil and att.Parent == obj.Parent and att.Name == "Attachment"
end

local function sweepContainer(container)
	if not container then return end
	local ok, descendants = pcall(function() return container:GetDescendants() end)
	if not ok then return end
	for _, d in ipairs(descendants) do
		if d:GetAttribute(TAG) then
			pcall(function() d:Destroy() end)
		elseif isLegacyLeftover(d) then
			local att = d.Attachment0
			pcall(function() d:Destroy() end)
			if att then pcall(function() att:Destroy() end) end
		end
	end
end

local function clearPhysics()
	destroyTracked()
	local current = localPlayer and localPlayer.Character
	sweepContainer(current)
	if character and character ~= current then
		sweepContainer(character)
	end
	isExploding = false
end

local function shutdownForeignInstances()
	local playerGui = localPlayer and localPlayer:FindFirstChild("PlayerGui")
	if not playerGui then return end
	for _, g in ipairs(playerGui:GetChildren()) do
		if g.Name == "AFO_CustomMovement" and g ~= gui then
			pcall(function() g:SetAttribute(SILENT_ATTR, true) end)
			local buttons = {}
			for _, d in ipairs(g:GetDescendants()) do
				if d:IsA("TextButton") and d.Text == "X" then
					table.insert(buttons, d)
				end
			end
			for _, btn in ipairs(buttons) do
				pcall(function()
					if getconnections then
						for _, c in ipairs(getconnections(btn.MouseButton1Click)) do
							pcall(function()
								if c.Fire then c:Fire() elseif c.Function then c.Function() end
							end)
						end
					elseif firesignal then
						firesignal(btn.MouseButton1Click)
					end
				end)
			end
			pcall(function() g:Destroy() end)
		end
	end
end

local function createPhysics()
	destroyTracked()
	if not rootPart then return end

	local att = Instance.new("Attachment")
	att.Name = TAG .. "_Attachment"
	att:SetAttribute(TAG, true)
	att.Position = Vector3.zero
	att.Parent = rootPart

	local lv = Instance.new("LinearVelocity")
	lv.Name = TAG .. "_LinearVelocity"
	lv:SetAttribute(TAG, true)
	lv.Attachment0 = att
	lv.RelativeTo = Enum.ActuatorRelativeTo.World
	lv.ForceLimitMode = Enum.ForceLimitMode.PerAxis
	lv.MaxAxesForce = Vector3.zero
	lv.VectorVelocity = Vector3.zero
	lv.Parent = rootPart

	table.insert(createdObjects, att)
	table.insert(createdObjects, lv)
	movementAttachment = att
	linearVelocity = lv
end

function M.SetLanguage(code)
	I18N.forced = (type(code) == "string" and I18N.strings[string.lower(code)]) and string.lower(code) or nil
	if active and applyLanguage then
		applyLanguage()
	end
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

function M.Stop(withEffect)
	if withEffect == true and active and isEnabled then
		safeSfx(SFX_OFF_ID)
		safeFx(rootPart, "out")
	end

	sessionId += 1
	active = false
	isEnabled = false

	stopPhysicsLoop()
	disconnectAll()

	if gui and gui.Parent then
		gui:Destroy()
	end
	shutdownForeignInstances()
	clearPhysics()

	gui = nil
	mainFrame = nil
	meterLabel, meterGradient, meterNeedle, meterNeedleParts = nil, nil, nil, nil
	meterFrac, meterColorFrac = 0, -1
	setPanelOpen = nil
	applyLanguage = nil
	isOpen = false
	character, humanoid, rootPart = nil, nil, nil
	isExploding = false
end

function M.Start(firstArgument, secondArgument)
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
	local mySession = sessionId
	preloadSfx()

	active = true
	isEnabled = true
	isOpen = false
	currentSpeed = DEFAULT_SPEED
	gameBaseSpeed = 16
	currentSmoothSpeed = 16
	isExploding = false
	lastDashEnd = 0
	boostEndTime = 0
	resetZones()
	smoothMult = zones.farMult

	local playerGui = localPlayer:WaitForChild("PlayerGui")

	gui = Instance.new("ScreenGui")
	gui.Name = "AFO_CustomMovement"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = playerGui

	mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainPanel"
	mainFrame.Size = UDim2.new(0, 290, 0, 160)
	mainFrame.AnchorPoint = Vector2.new(0, 0)
	mainFrame.Position = UDim2.new(0, -300, 0, 190)
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

	local titleBox = Instance.new("Frame")
	titleBox.Name = "TitleBox"
	titleBox.Size = UDim2.new(0, 145, 0, 28)
	titleBox.Position = UDim2.new(0, 15, 0, 10)
	titleBox.BackgroundColor3 = Color3.fromRGB(20, 10, 40)
	titleBox.BackgroundTransparency = 0.3
	titleBox.BorderSizePixel = 0
	titleBox.Parent = mainFrame
	Instance.new("UICorner", titleBox).CornerRadius = UDim.new(0, 4)

	local titleBoxStroke = Instance.new("UIStroke")
	titleBoxStroke.Color = C_PURPLE
	titleBoxStroke.Thickness = 1
	titleBoxStroke.Transparency = 0.7
	titleBoxStroke.Parent = titleBox

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 1, 0)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextSize = 14
	title.TextColor3 = C_TEXT
	title.Text = I18N.strings.en.title
	title.TextXAlignment = Enum.TextXAlignment.Center
	title.TextYAlignment = Enum.TextYAlignment.Center
	title.Parent = titleBox

	local titleGradient = Instance.new("UIGradient")
	titleGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(230, 205, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(170, 215, 255)),
	})
	titleGradient.Parent = title

	local textBox = Instance.new("TextBox")
	textBox.Size = UDim2.new(0, 145, 0, 28)
	textBox.Position = UDim2.new(0, 15, 0, 47)
	textBox.BackgroundColor3 = Color3.fromRGB(20, 10, 40)
	textBox.BackgroundTransparency = 0.3
	textBox.TextColor3 = C_TEXT
	textBox.PlaceholderColor3 = C_SUB
	textBox.PlaceholderText = ""
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
	toggleBtn.Size = UDim2.new(0, 103, 0, 28)
	toggleBtn.Position = UDim2.new(0, 15, 0, 84)
	toggleBtn.BackgroundColor3 = Color3.fromRGB(80, 20, 140)
	toggleBtn.BackgroundTransparency = 0.2
	toggleBtn.TextColor3 = C_TEXT
	toggleBtn.Font = Enum.Font.GothamBold
	toggleBtn.TextSize = 12
	toggleBtn.Text = ""
	toggleBtn.BorderSizePixel = 0
	toggleBtn.Parent = mainFrame
	Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 4)

	local toggleGradient = Instance.new("UIGradient")
	toggleGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(190, 175, 215)),
	})
	toggleGradient.Rotation = 90
	toggleGradient.Parent = toggleBtn

	local resetButton = Instance.new("TextButton")
	resetButton.Name = "ResetButton"
	resetButton.Size = UDim2.new(0, 36, 0, 28)
	resetButton.Position = UDim2.new(0, 15 + 145 - 36, 0, 84)
	resetButton.BackgroundColor3 = Color3.fromRGB(80, 20, 140)
	resetButton.BackgroundTransparency = 0.2
	resetButton.TextColor3 = C_TEXT
	resetButton.Font = Enum.Font.GothamBold
	resetButton.TextSize = 14
	resetButton.Text = "\240\159\148\132"
	resetButton.BorderSizePixel = 0
	resetButton.Parent = mainFrame
	Instance.new("UICorner", resetButton).CornerRadius = UDim.new(0, 4)
	toggleGradient:Clone().Parent = resetButton

	local moreBtn = Instance.new("TextButton")
	moreBtn.Name = "MoreOptions"
	moreBtn.Size = UDim2.new(0, 260, 0, 24)
	moreBtn.Position = UDim2.new(0, 15, 0, 124)
	moreBtn.AutoButtonColor = false
	moreBtn.BackgroundColor3 = Color3.fromRGB(20, 10, 40)
	moreBtn.BackgroundTransparency = 0.3
	moreBtn.TextColor3 = C_SUB
	moreBtn.Font = Enum.Font.GothamBold
	moreBtn.TextSize = 11
	moreBtn.Text = ""
	moreBtn.BorderSizePixel = 0
	moreBtn.Parent = mainFrame
	Instance.new("UICorner", moreBtn).CornerRadius = UDim.new(0, 4)
	local moreStroke = Instance.new("UIStroke")
	moreStroke.Color = C_PURPLE
	moreStroke.Thickness = 1
	moreStroke.Transparency = 0.7
	moreStroke.Parent = moreBtn

	local GAUGE_R = 50

	local meterGroup = Instance.new("Frame")
	meterGroup.Name = "SpeedGauge"
	meterGroup.Size = UDim2.new(0, GAUGE_R * 2, 0, 88)
	meterGroup.Position = UDim2.new(0, 172, 0, 34)
	meterGroup.BackgroundTransparency = 1
	meterGroup.ZIndex = 11
	meterGroup.Parent = mainFrame

	local dialClip = Instance.new("Frame")
	dialClip.Name = "Dial"
	dialClip.Size = UDim2.new(0, GAUGE_R * 2, 0, GAUGE_R)
	dialClip.BackgroundTransparency = 1
	dialClip.ClipsDescendants = true
	dialClip.ZIndex = 11
	dialClip.Parent = meterGroup

	local dialCircle = Instance.new("Frame")
	dialCircle.Size = UDim2.new(0, GAUGE_R * 2 - 6, 0, GAUGE_R * 2 - 6)
	dialCircle.Position = UDim2.new(0, 3, 0, 3)
	dialCircle.BackgroundColor3 = Color3.new(1, 1, 1)
	dialCircle.BackgroundTransparency = 0.1
	dialCircle.BorderSizePixel = 0
	dialCircle.ZIndex = 11
	dialCircle.Parent = dialClip
	Instance.new("UICorner", dialCircle).CornerRadius = UDim.new(0.5, 0)

	local dialGradient = Instance.new("UIGradient")
	dialGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(52, 24, 92)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 6, 18)),
	})
	dialGradient.Rotation = 90
	dialGradient.Parent = dialCircle

	local dialStroke = Instance.new("UIStroke")
	dialStroke.Color = Color3.new(1, 1, 1)
	dialStroke.Thickness = 3
	dialStroke.Parent = dialCircle
	local dialStrokeGradient = Instance.new("UIGradient")
	dialStrokeGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, GAUGE_LOW),
		ColorSequenceKeypoint.new(0.5, GAUGE_MID),
		ColorSequenceKeypoint.new(1, GAUGE_HIGH),
	})
	dialStrokeGradient.Parent = dialStroke

	for i = 0, 10 do
		local a = math.rad(10 + i * 16)
		local major = (i % 5 == 0)
		local len = major and 8 or 5
		local radius = GAUGE_R - 8 - len / 2
		local tick = Instance.new("Frame")
		tick.AnchorPoint = Vector2.new(0.5, 0.5)
		tick.Position = UDim2.fromOffset(GAUGE_R - math.cos(a) * radius, GAUGE_R - math.sin(a) * radius)
		tick.Size = UDim2.fromOffset(major and 2 or 1, len)
		tick.Rotation = math.deg(a) - 90
		tick.BackgroundColor3 = gaugeColor(i / 10)
		tick.BackgroundTransparency = major and 0.05 or 0.45
		tick.BorderSizePixel = 0
		tick.ZIndex = 12
		tick.Parent = dialClip
	end

	local needleLen = GAUGE_R - 14
	meterNeedle = Instance.new("Frame")
	meterNeedle.Name = "Needle"
	meterNeedle.AnchorPoint = Vector2.new(0.5, 0.5)
	meterNeedle.Position = UDim2.fromOffset(GAUGE_R, GAUGE_R)
	meterNeedle.Size = UDim2.fromOffset(needleLen * 2, needleLen * 2)
	meterNeedle.BackgroundTransparency = 1
	meterNeedle.Rotation = NEEDLE_MIN
	meterNeedle.ZIndex = 13
	meterNeedle.Parent = dialClip

	local needleGlow = Instance.new("Frame")
	needleGlow.AnchorPoint = Vector2.new(0.5, 0)
	needleGlow.Position = UDim2.fromScale(0.5, 0)
	needleGlow.Size = UDim2.fromOffset(6, needleLen)
	needleGlow.BackgroundColor3 = GAUGE_LOW
	needleGlow.BackgroundTransparency = 0.8
	needleGlow.BorderSizePixel = 0
	needleGlow.ZIndex = 13
	needleGlow.Parent = meterNeedle
	Instance.new("UICorner", needleGlow).CornerRadius = UDim.new(0.5, 0)

	local needleCore = Instance.new("Frame")
	needleCore.AnchorPoint = Vector2.new(0.5, 0)
	needleCore.Position = UDim2.fromScale(0.5, 0)
	needleCore.Size = UDim2.fromOffset(2, needleLen)
	needleCore.BackgroundColor3 = GAUGE_LOW
	needleCore.BorderSizePixel = 0
	needleCore.ZIndex = 14
	needleCore.Parent = meterNeedle
	Instance.new("UICorner", needleCore).CornerRadius = UDim.new(0.5, 0)
	meterNeedleParts = { needleGlow, needleCore }

	local hub = Instance.new("Frame")
	hub.AnchorPoint = Vector2.new(0.5, 0.5)
	hub.Position = UDim2.fromOffset(GAUGE_R, GAUGE_R)
	hub.Size = UDim2.fromOffset(14, 14)
	hub.BackgroundColor3 = Color3.new(1, 1, 1)
	hub.BorderSizePixel = 0
	hub.ZIndex = 15
	hub.Parent = dialClip
	Instance.new("UICorner", hub).CornerRadius = UDim.new(0.5, 0)
	local hubGradient = Instance.new("UIGradient")
	hubGradient.Color = ColorSequence.new(Color3.fromRGB(120, 70, 190), C_BLACK)
	hubGradient.Rotation = 90
	hubGradient.Parent = hub
	local hubStroke = Instance.new("UIStroke")
	hubStroke.Color = C_PURPLE
	hubStroke.Thickness = 1.5
	hubStroke.Parent = hub

	meterLabel = Instance.new("TextLabel")
	meterLabel.Name = "SpeedValue"
	meterLabel.Size = UDim2.new(1, 0, 0, 24)
	meterLabel.Position = UDim2.new(0, 0, 0, 52)
	meterLabel.BackgroundTransparency = 1
	meterLabel.Font = Enum.Font.GothamBold
	meterLabel.TextSize = 20
	meterLabel.TextColor3 = Color3.new(1, 1, 1)
	meterLabel.Text = "0.0"
	meterLabel.ZIndex = 12
	meterLabel.Parent = meterGroup

	meterGradient = Instance.new("UIGradient")
	meterGradient.Rotation = 90
	meterGradient.Parent = meterLabel

	local unitLabel = Instance.new("TextLabel")
	unitLabel.Size = UDim2.new(1, 0, 0, 12)
	unitLabel.Position = UDim2.new(0, 0, 0, 76)
	unitLabel.BackgroundTransparency = 1
	unitLabel.Font = Enum.Font.GothamBold
	unitLabel.TextSize = 9
	unitLabel.TextColor3 = Color3.new(1, 1, 1)
	unitLabel.Text = "STUDS/S"
	unitLabel.ZIndex = 12
	unitLabel.Parent = meterGroup
	local unitGradient = Instance.new("UIGradient")
	unitGradient.Color = ColorSequence.new(Color3.fromRGB(150, 110, 220), Color3.fromRGB(150, 215, 255))
	unitGradient.Parent = unitLabel

	meterFrac, meterColorFrac = 0, -1
	updateMeter(0, 1)

	-- =====================================================================
	-- "Mas opciones": zonas de multiplicador configurables (distancia + valor)
	-- =====================================================================
	local refreshZonesUI = function(instant) end
	local applyAdvLanguage = function() end

	do
		local ADV_H = 180
		local BOX_BG = Color3.fromRGB(20, 10, 40)
		local ZONE_COLORS = {
			near = Color3.fromRGB(255, 95, 125),
			mid = Color3.fromRGB(255, 210, 85),
			far = Color3.fromRGB(95, 230, 165),
		}
		local TWEEN_BAR = TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
		local ROW_Y0, ROW_H, ROW_GAP = 70, 26, 4
		local COL = { distX = 91, distW = 58, multX = 153, multW = 58, speedX = 215, speedW = 60 }

		local function fmtNum(n, decimals)
			local str = string.format("%." .. (decimals or 2) .. "f", n)
			if str:find("%.") then
				str = str:gsub("0+$", "")
				str = str:gsub("%.$", "")
			end
			return str
		end

		local function parseNumber(text)
			text = string.gsub(text, "[\195\151xX%s]", "")
			text = string.gsub(text, ",", ".")
			local n = tonumber(text)
			if not n or n ~= n or n == math.huge or n == -math.huge then
				return nil
			end
			return n
		end

		local function makeLabel(text, size, x, y, w, h, align, color)
			local lbl = Instance.new("TextLabel")
			lbl.Size = UDim2.new(0, w, 0, h)
			lbl.Position = UDim2.new(0, x, 0, y)
			lbl.BackgroundTransparency = 1
			lbl.Font = Enum.Font.GothamBold
			lbl.TextSize = size
			lbl.TextColor3 = color or C_TEXT
			lbl.TextXAlignment = align or Enum.TextXAlignment.Center
			lbl.TextYAlignment = Enum.TextYAlignment.Center
			lbl.Text = text
			return lbl
		end

		-- Panel desplegable pegado debajo del principal (mismo estilo que el menu de CopyAvatar)
		local advMenu = Instance.new("Frame")
		advMenu.Name = "MultipliersMenu"
		advMenu.Size = UDim2.new(1, 0, 0, 0)
		advMenu.Position = UDim2.new(0, 0, 1, 6)
		advMenu.BackgroundColor3 = C_BLACK
		advMenu.BackgroundTransparency = 0.15
		advMenu.BorderSizePixel = 0
		advMenu.ClipsDescendants = true
		advMenu.Visible = false
		advMenu.ZIndex = 10
		advMenu.Parent = mainFrame
		Instance.new("UICorner", advMenu).CornerRadius = UDim.new(0, 8)
		local advStroke = Instance.new("UIStroke")
		advStroke.Color = C_PURPLE
		advStroke.Thickness = 1
		advStroke.Transparency = 0.5
		advStroke.Parent = advMenu

		local advTitle = makeLabel("", 11, 15, 8, 260, 16)
		advTitle.Parent = advMenu
		local advTitleGradient = Instance.new("UIGradient")
		advTitleGradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(230, 205, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(170, 215, 255)),
		})
		advTitleGradient.Parent = advTitle

		-- Barra visual de zonas (se redimensiona sola segun las distancias)
		local bar = Instance.new("Frame")
		bar.Name = "ZoneBar"
		bar.Size = UDim2.new(0, 260, 0, 22)
		bar.Position = UDim2.new(0, 15, 0, 28)
		bar.BackgroundColor3 = BOX_BG
		bar.BackgroundTransparency = 0.3
		bar.BorderSizePixel = 0
		bar.ClipsDescendants = true
		bar.Parent = advMenu
		Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 4)
		local barStroke = Instance.new("UIStroke")
		barStroke.Color = C_PURPLE
		barStroke.Thickness = 1
		barStroke.Transparency = 0.7
		barStroke.Parent = bar

		local segs = {}
		for i, id in ipairs({ "near", "mid", "far" }) do
			local seg = Instance.new("Frame")
			seg.Name = id
			seg.BackgroundColor3 = ZONE_COLORS[id]
			seg.BackgroundTransparency = 0.15
			seg.BorderSizePixel = 0
			seg.ClipsDescendants = true
			seg.Parent = bar
			local segGradient = Instance.new("UIGradient")
			segGradient.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(205, 205, 205))
			segGradient.Rotation = 90
			segGradient.Parent = seg
			local lbl = Instance.new("TextLabel")
			lbl.Size = UDim2.fromScale(1, 1)
			lbl.BackgroundTransparency = 1
			lbl.Font = Enum.Font.GothamBold
			lbl.TextScaled = true
			lbl.TextColor3 = Color3.fromRGB(15, 8, 25)
			lbl.Text = ""
			lbl.Parent = seg
			local limit = Instance.new("UITextSizeConstraint")
			limit.MaxTextSize = 10
			limit.MinTextSize = 6
			limit.Parent = lbl
			segs[i] = { frame = seg, label = lbl }
		end

		-- Cabeceras de columna
		local colUntil = makeLabel("", 9, COL.distX, 56, COL.distW, 12, nil, C_SUB)
		local colMult = makeLabel("", 9, COL.multX, 56, COL.multW, 12, nil, C_SUB)
		local colSpeed = makeLabel("", 9, COL.speedX, 56, COL.speedW, 12, nil, C_SUB)
		colUntil.Parent = advMenu
		colMult.Parent = advMenu
		colSpeed.Parent = advMenu

		local function makeField(x, y, w, h)
			local box = Instance.new("TextBox")
			box.Size = UDim2.new(0, w, 0, h)
			box.Position = UDim2.new(0, x, 0, y)
			box.BackgroundColor3 = BOX_BG
			box.BackgroundTransparency = 0.3
			box.TextColor3 = C_TEXT
			box.PlaceholderColor3 = C_SUB
			box.Font = Enum.Font.Gotham
			box.TextSize = 12
			box.ClearTextOnFocus = true
			box.BorderSizePixel = 0
			box.Text = ""
			box.Parent = advMenu
			Instance.new("UICorner", box).CornerRadius = UDim.new(0, 4)
			local st = Instance.new("UIStroke")
			st.Color = C_PURPLE
			st.Thickness = 1
			st.Transparency = 0.7
			st.Parent = box
			return box, st
		end

		local function flashField(box, st)
			box.BackgroundColor3 = Color3.fromRGB(190, 60, 70)
			box.BackgroundTransparency = 0.25
			st.Color = Color3.fromRGB(255, 110, 120)
			st.Transparency = 0.1
			local info = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0.3)
			TweenService:Create(box, info, { BackgroundColor3 = BOX_BG, BackgroundTransparency = 0.3 }):Play()
			TweenService:Create(st, info, { Color = C_PURPLE, Transparency = 0.7 }):Play()
		end

		-- Filas: punto de color + nombre | hasta (studs) | multiplicador | velocidad resultante
		local rows = {
			{ id = "near", multKey = "nearMult", distKey = "nearDist" },
			{ id = "mid", multKey = "midMult", distKey = "farDist" },
			{ id = "far", multKey = "farMult" },
		}
		local fields, speedLabels, nameLabels = {}, {}, {}
		local farDistLabel
		for i, row in ipairs(rows) do
			local y = ROW_Y0 + (i - 1) * (ROW_H + ROW_GAP)
			local color = ZONE_COLORS[row.id]

			local dot = Instance.new("Frame")
			dot.Size = UDim2.fromOffset(8, 8)
			dot.Position = UDim2.new(0, 15, 0, y + (ROW_H - 8) / 2)
			dot.BackgroundColor3 = color
			dot.BorderSizePixel = 0
			dot.Parent = advMenu
			Instance.new("UICorner", dot).CornerRadius = UDim.new(0.5, 0)

			local nameLabel = makeLabel("", 11, 27, y, 60, ROW_H, Enum.TextXAlignment.Left)
			nameLabel.Parent = advMenu
			nameLabels[row.id] = nameLabel

			if row.distKey then
				local box, st = makeField(COL.distX, y, COL.distW, ROW_H)
				fields[row.distKey] = { box = box, stroke = st, isMult = false }
			else
				farDistLabel = makeLabel("", 12, COL.distX, y, COL.distW, ROW_H, nil, C_SUB)
				farDistLabel.Font = Enum.Font.Gotham
				farDistLabel.Parent = advMenu
			end

			local mbox, mst = makeField(COL.multX, y, COL.multW, ROW_H)
			fields[row.multKey] = { box = mbox, stroke = mst, isMult = true }

			local speedLabel = makeLabel("", 12, COL.speedX, y, COL.speedW, ROW_H, nil, color)
			speedLabel.Parent = advMenu
			speedLabels[row.id] = speedLabel
		end

		local advHint = makeLabel("", 9, 15, 160, 260, 12, nil, C_SUB)
		advHint.Font = Enum.Font.Gotham
		advHint.TextTransparency = 0.2
		advHint.Parent = advMenu

		-- ---------- Estado visual ----------
		local advOpen = false

		applyAdvLanguage = function()
			advTitle.Text = L("zonesTitle")
			nameLabels.near.Text = L("zoneNear")
			nameLabels.mid.Text = L("zoneMid")
			nameLabels.far.Text = L("zoneFar")
			colUntil.Text = L("colUntil")
			colMult.Text = L("colMult")
			colSpeed.Text = L("colSpeed")
			advHint.Text = L("zonesHint")
			moreBtn.Text = L(advOpen and "less" or "more") .. (advOpen and " \226\150\180" or " \226\150\190")
		end

		refreshZonesUI = function(instant)
			if not advMenu.Parent then return end

			for key, f in pairs(fields) do
				local v = zones[key]
				local txt = f.isMult and ("\195\151" .. fmtNum(v, 2)) or fmtNum(v, 1)
				f.box.PlaceholderText = txt
				if not f.box:IsFocused() then
					f.box.Text = txt
				end
			end

			speedLabels.near.Text = fmtNum(currentSpeed * zones.nearMult, 1)
			speedLabels.mid.Text = fmtNum(currentSpeed * zones.midMult, 1)
			speedLabels.far.Text = fmtNum(currentSpeed * zones.farMult, 1)
			farDistLabel.Text = fmtNum(zones.farDist, 1) .. "+"

			local dash = "\226\128\147"
			segs[1].label.Text = "0" .. dash .. fmtNum(zones.nearDist, 1)
			segs[2].label.Text = fmtNum(zones.nearDist, 1) .. dash .. fmtNum(zones.farDist, 1)
			segs[3].label.Text = fmtNum(zones.farDist, 1) .. "+"

			local f1 = zones.nearDist
			local f2 = zones.farDist - zones.nearDist
			local f3 = zones.farDist * 0.4
			local total = f1 + f2 + f3
			local w = { f1 / total, f2 / total, f3 / total }
			local sum = 0
			for i = 1, 3 do
				w[i] = math.max(w[i], 0.1)
				sum += w[i]
			end
			local cum = 0
			for i = 1, 3 do
				local frac = w[i] / sum
				local size = UDim2.new(frac, i < 3 and -1 or 0, 1, 0)
				local pos = UDim2.new(cum, 0, 0, 0)
				cum += frac
				if instant then
					segs[i].frame.Size = size
					segs[i].frame.Position = pos
				else
					TweenService:Create(segs[i].frame, TWEEN_BAR, { Size = size, Position = pos }):Play()
				end
			end
		end

		local function setAdvOpen(open)
			advOpen = open
			applyAdvLanguage()
			if open then
				refreshZonesUI(true)
				advMenu.Visible = true
				TweenService:Create(advMenu, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
					Size = UDim2.new(1, 0, 0, ADV_H),
				}):Play()
			else
				local tween = TweenService:Create(advMenu, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
					Size = UDim2.new(1, 0, 0, 0),
				})
				tween:Play()
				tween.Completed:Once(function()
					if not advOpen and advMenu.Parent then
						advMenu.Visible = false
					end
				end)
			end
		end

		local function setZone(key, n)
			if key == "nearDist" then
				zones.nearDist = math.clamp(n, 1, math.max(zones.farDist - 1, 1))
			elseif key == "farDist" then
				zones.farDist = math.clamp(n, zones.nearDist + 1, 1000)
			else
				zones[key] = math.clamp(n, 0.1, 10)
			end
		end

		-- ---------- Eventos ----------
		for key, f in pairs(fields) do
			table.insert(connections, f.box.FocusLost:Connect(function()
				local raw = string.gsub(f.box.Text, "%s", "")
				if raw ~= "" then
					local n = parseNumber(raw)
					if n and n > 0 then
						setZone(key, n)
					else
						flashField(f.box, f.stroke)
					end
				end
				refreshZonesUI()
			end))
		end

		table.insert(connections, moreBtn.MouseButton1Click:Connect(function()
			setAdvOpen(not advOpen)
		end))
		table.insert(connections, moreBtn.MouseEnter:Connect(function()
			TweenService:Create(moreStroke, TweenInfo.new(0.15), { Transparency = 0.3 }):Play()
			TweenService:Create(moreBtn, TweenInfo.new(0.15), { TextColor3 = C_TEXT }):Play()
		end))
		table.insert(connections, moreBtn.MouseLeave:Connect(function()
			TweenService:Create(moreStroke, TweenInfo.new(0.15), { Transparency = 0.7 }):Play()
			TweenService:Create(moreBtn, TweenInfo.new(0.15), { TextColor3 = C_SUB }):Play()
		end))

		-- Reestablecer: velocidad + multiplicadores + distancias a sus valores predeterminados
		table.insert(connections, resetButton.MouseButton1Click:Connect(function()
			currentSpeed = DEFAULT_SPEED
			resetZones()
			textBox.Text = tostring(DEFAULT_SPEED)
			refreshZonesUI()
			local press = TweenService:Create(resetButton, TweenInfo.new(0.1), { BackgroundTransparency = 0.6 })
			press:Play()
			press.Completed:Once(function()
				TweenService:Create(resetButton, TweenInfo.new(0.2), { BackgroundTransparency = 0.2 }):Play()
			end)
		end))

		applyAdvLanguage()
		refreshZonesUI(true)
	end

	local function refreshToggleText()
		toggleBtn.Text = isEnabled and L("on") or L("off")
	end

	applyLanguage = function()
		currentLang = I18N.detect()
		local t = I18N.strings[currentLang] or I18N.strings.en
		title.Text = t.title
		textBox.PlaceholderText = t.placeholder
		refreshToggleText()
		applyAdvLanguage()
	end
	applyLanguage()

	local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

	setPanelOpen = function(open)
		if not active or not mainFrame or not mainFrame.Parent then return end
		isOpen = open
		if open and applyLanguage then
			applyLanguage()
		end
		local position = isOpen
			and UDim2.new(0, 20, 0, 190)
			or UDim2.new(0, -300, 0, 190)

		TweenService:Create(mainFrame, tweenInfo, { Position = position }):Play()
	end

	local function togglePanel()
		setPanelOpen(not isOpen)
	end

	table.insert(connections, toggleBtn.MouseButton1Click:Connect(function()
		local num = tonumber(textBox.Text)

		if not isEnabled then
			if num and num > 0 then
				currentSpeed = math.abs(num)
				refreshZonesUI()
				isEnabled = true
				if humanoid then
					gameBaseSpeed = math.abs(humanoid.WalkSpeed)
					if gameBaseSpeed == 0 then gameBaseSpeed = 16 end
					currentSmoothSpeed = gameBaseSpeed
				end
				if startPhysicsLoop then startPhysicsLoop() end
				refreshToggleText()
				toggleBtn.BackgroundColor3 = Color3.fromRGB(80, 20, 140)
				safeSfx(SFX_ON_ID)
				safeFx(rootPart, "in")
			else
				toggleBtn.Text = L("invalid")
				task.wait(1)
				if mySession == sessionId and not isEnabled and toggleBtn.Parent then
					refreshToggleText()
				end
			end
		else
			safeSfx(SFX_OFF_ID)
			safeFx(rootPart, "out")
			isEnabled = false
			stopPhysicsLoop()
			clearPhysics()
			refreshToggleText()
			toggleBtn.BackgroundColor3 = Color3.fromRGB(40, 10, 60)
		end
	end))

	table.insert(connections, textBox.FocusLost:Connect(function(enterPressed)
		if enterPressed then
			local num = tonumber(textBox.Text)
			if num and num > 0 and isEnabled then
				currentSpeed = math.abs(num)
				refreshZonesUI()
			end
		end
	end))

	table.insert(connections, closeButton.MouseButton1Click:Connect(function()
		local silent = gui and gui:GetAttribute(SILENT_ATTR)
		M.Stop(not silent)
	end))

	table.insert(connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if not gameProcessed and input.KeyCode == toggleKey then
			togglePanel()
		end
	end))

	local function setupCharacter(char)
		clearPhysics()
		character, humanoid, rootPart = nil, nil, nil
		local newHumanoid = char:WaitForChild("Humanoid")
		local newRoot = char:WaitForChild("HumanoidRootPart")
		if mySession ~= sessionId then return end
		character, humanoid, rootPart = char, newHumanoid, newRoot

		task.spawn(function()
			while not char.Parent or newHumanoid.WalkSpeed == 0 do
				if mySession ~= sessionId or character ~= char then return end
				task.wait(0.05)
			end

			task.wait(0.3)
			if mySession ~= sessionId or character ~= char then return end

			gameBaseSpeed = math.abs(newHumanoid.WalkSpeed)
			if gameBaseSpeed == 0 then gameBaseSpeed = 16 end
			currentSmoothSpeed = gameBaseSpeed
			clearPhysics()
		end)
	end

	if localPlayer.Character then
		setupCharacter(localPlayer.Character)
	end
	if mySession ~= sessionId then return false end
	table.insert(connections, localPlayer.CharacterAdded:Connect(setupCharacter))

	table.insert(connections, UserInputService.InputBegan:Connect(function(input, gpe)
		if gpe or not active or not isEnabled or not character or not humanoid or not rootPart then return end
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
				-- FIX: la velocidad ya no depende del WalkSpeed del juego (era aleatorio)
				local finalWalkSpeed = math.abs(currentSpeed)
				local dashForce = math.max(EXPLOSION_BASE_FORCE, finalWalkSpeed * 2.3)

				rootPart:ApplyImpulse(pushDir * rootPart.AssemblyMass * dashForce)

				task.delay(0.15, function()
					isExploding = false
				end)
			end
		end
	end))

	local function onHeartbeat(deltaTime)
		if not isEnabled or not character or not humanoid or not rootPart or not character.Parent then
			updateMeter(0, deltaTime)
			return
		end

		local vel = rootPart.AssemblyLinearVelocity
		updateMeter(Vector3.new(vel.X, 0, vel.Z).Magnitude, deltaTime)

		local state = humanoid:GetState()
		local isRagdoll = state == Enum.HumanoidStateType.FallingDown or state == Enum.HumanoidStateType.Ragdoll or humanoid.PlatformStand

		if isRagdoll then isExploding = false end

		local moveDir = humanoid.MoveDirection
		local currentTime = tick()
		local camera = workspace.CurrentCamera

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

		if isExploding then
			if linearVelocity then linearVelocity.MaxAxesForce = Vector3.zero end
			return
		end

		-- FIX: antes se multiplicaba por (WalkSpeed actual / WalkSpeed capturado).
		-- Si el juego cambiaba el WalkSpeed (sprint, buffs, habilidades) o la
		-- captura se hacia en otro momento, el mismo valor daba 200 o 325.
		-- Ahora la velocidad base depende SOLO del valor que escribe el usuario.
		local baseTargetSpeed = math.abs(currentSpeed)
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

		-- Multiplicador objetivo (zonas configurables con transiciones suaves)
		local targetMult = zones.farMult
		if tick() >= boostEndTime and nearestEnemyHRP then
			local b1, b2 = zones.nearDist, zones.farDist
			local gap = math.max(b2 - b1, 0.1)
			local hw1 = math.min(b1 * BAND_NEAR_FRAC, gap * 0.4)
			local hw2 = math.min(b2 * BAND_FAR_FRAC, gap * 0.4)
			local wMid = smoothStep(b1 - hw1, b1 + hw1, minDistance) -- 0 = cerca, 1 = medio o mas
			local wFar = smoothStep(b2 - hw2, b2 + hw2, minDistance) -- 0 = medio o menos, 1 = lejos

			local zoneMult = zones.nearMult + (zones.midMult - zones.nearMult) * wMid
			zoneMult = zoneMult + (zones.farMult - zoneMult) * wFar

			-- Bonus por movimiento (se desvanece al acercarse a la zona lejana)
			local moveVector = moveDir.Magnitude > 0 and moveDir.Unit or Vector3.zero
			local bonus = 1
			if moveVector.Magnitude > 0 then
				local dirToEnemy = (nearestEnemyHRP.Position - rootPart.Position).Unit
				local moveDot = moveVector:Dot(dirToEnemy)
				if moveDot > 0.8 then
					bonus = 1 + (BONUS_TOWARD_MID - 1) * wMid
				elseif math.abs(moveDot) < 0.4 then
					bonus = BONUS_STRAFE_NEAR + (BONUS_STRAFE_MID - BONUS_STRAFE_NEAR) * wMid
				end
			end
			bonus = 1 + (bonus - 1) * (1 - wFar)

			local capMult = math.max(zones.nearMult, zones.midMult, zones.farMult)
			targetMult = math.min(zoneMult * bonus, capMult)
		end

		-- Suavizado del multiplicador (independiente del framerate)
		smoothMult = smoothMult + (targetMult - smoothMult) * (1 - math.exp(-MULT_SMOOTH_RATE * deltaTime))
		finalTargetSpeed = baseTargetSpeed * smoothMult

		local lerpSpeed = math.clamp(14 * deltaTime, 0, 1)
		currentSmoothSpeed = currentSmoothSpeed + (finalTargetSpeed - currentSmoothSpeed) * lerpSpeed

		if not linearVelocity or linearVelocity.Parent ~= rootPart then
			createPhysics()
			if not linearVelocity then return end
		end

		local moveMagnitude = moveDir.Magnitude
		local activeForce = isRagdoll and 45000 or 1e5

		if moveMagnitude > 0.01 then
			local preciseDir = moveDir.Unit
			local targetVelocityVector = preciseDir * currentSmoothSpeed
			linearVelocity.MaxAxesForce = Vector3.new(activeForce, 0, activeForce)
			linearVelocity.VectorVelocity = Vector3.new(targetVelocityVector.X, 0, targetVelocityVector.Z)

			for _, track in ipairs(humanoid:GetPlayingAnimationTracks()) do
				local animName = track.Name:lower()
				if animName:find("walk") or animName:find("run") or animName:find("move") or animName:find("climb") then
					track:AdjustSpeed(1)
				end
			end
		else
			linearVelocity.MaxAxesForce = Vector3.new(activeForce, 0, activeForce)
			linearVelocity.VectorVelocity = Vector3.zero
		end
	end

	startPhysicsLoop = function()
		if heartbeatConn then return end
		heartbeatConn = RunService.Heartbeat:Connect(function(deltaTime)
			if mySession ~= sessionId or not active or not isEnabled then return end
			onHeartbeat(deltaTime)
		end)
		table.insert(connections, heartbeatConn)
	end
	startPhysicsLoop()

	return true
end

do
	local previousStop = env.__AFO_SpeedForceStop
	if type(previousStop) == "function" then
		pcall(previousStop)
	end
	env.__AFO_SpeedForceStop = function() M.Stop() end
end

return M
