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

-- Variables de GUI
local gui, mainFrame, setPanelOpen
local isOpen = false
local toggleKey = Enum.KeyCode.F5
local meterLabel, meterGradient, meterNeedle, meterNeedleParts
local meterFrac, meterColorFrac = 0, -1

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

-- Paleta de colores heredada
local C_BLACK = Color3.fromRGB(15, 15, 20)
local C_PURPLE = Color3.fromRGB(100, 50, 150)
local C_TEXT = Color3.fromRGB(255, 255, 255)
local C_SUB = Color3.fromRGB(180, 180, 180)

-- Todo lo que este script crea en el personaje lleva esta etiqueta y se guarda en
-- createdObjects, para poder destruirlo aunque se pierda la referencia directa.
local TAG = "AFO_SpeedForce"
local createdObjects = {}
local sessionId = 0          -- sube con cada Start/Stop: invalida hilos y bucles viejos
local heartbeatConn = nil
local startPhysicsLoop       -- se asigna dentro de Start

local env = (getgenv and getgenv()) or _G

-- Atributo que se pone a un panel ajeno para que, al cerrarlo desde otra copia, NO suene ni
-- se vea el efecto de apagado (solo debe verse cuando el usuario cierra SU panel con la X).
local SILENT_ATTR = "AFO_SilentStop"

-- ============================================================================
-- IDIOMA: mismo sistema de detección que CopyAvatar (es / en)
-- "SPEEDFORCE" se mantiene igual en ambos idiomas.
-- ============================================================================
local I18N = {}
I18N.strings = {
	es = {
		title = "SPEEDFORCE",
		placeholder = "Velocidad...",
		on = "Prendido",
		off = "Apagado",
		invalid = "Inv\195\161lido",
	},
	en = {
		title = "SPEEDFORCE",
		placeholder = "Speed...",
		on = "On",
		off = "Off",
		invalid = "Invalid",
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
local applyLanguage          -- se asigna dentro de Start (necesita los elementos del panel)

local function L(key)
	local t = I18N.strings[currentLang] or I18N.strings.en
	return t[key] or I18N.strings.en[key] or ""
end

-- ============================================================================
-- SONIDOS (van en SoundService: sobreviven a Stop() y a la destrucción del panel)
-- ============================================================================
local SFX_ON_ID = "rbxassetid://118075222341359"     -- prender
local SFX_OFF_ID = "rbxassetid://112416614144985"    -- apagar
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

-- ============================================================================
-- EFECTO DE ELECTRICIDAD · estilo All For One (negro / morado / amarillo)
--   "in"  = prendido: los rayos viajan desde fuera y se clavan en el cuerpo -> destello
--   "out" = apagado : destello en el cuerpo -> los rayos salen disparados y se erosionan
--
-- Receta (tomada de las guías anime_cel / DESIGN del pack roblox-vfx):
--   * Cada rayo son 4 capas: tinta NEGRA translúcida debajo, brillo MORADO, cuerpo de color
--     y un núcleo fino casi blanco. "Núcleo blanco, borde saturado, acentos oscuros".
--   * Un color dominante (morado) y un acento (amarillo). Al clavarse / al salir, el rayo
--     se pone "al rojo blanco" (amarillo-blanco) y se enfría a su color.
--   * Trazo cónico (grueso en la punta, fino en la cola), nunca un cilindro uniforme.
--   * Se "redibujan" cada ~0.08 s (a 2s/3s, como en anime) en vez de moverse suave.
--   * Se erosionan desde la cola en vez de desvanecerse en línea recta.
--   * Ramas laterales en algunos rayos, largos y tiempos distintos: nada simétrico.
--   * Destello LOCAL (esfera de neón + cáscara ForceField), nunca pantalla blanca.
--   * Chispas amarillas y moradas + humo negro-violeta que se queda un instante (residuo).
--
-- Es 100% independiente del panel y de la sesión (sessionId / connections): puede terminar
-- aunque Stop() destruya el panel. Sus objetos NO llevan la etiqueta TAG, así que el barrido
-- de clearPhysics() no los toca; se limpian solos y Debris es la red de seguridad.
-- ============================================================================
local FX = {
	DURATION = 0.8,       -- segundos que dura la fase de rayos
	TAIL = 0.6,           -- segundos extra en que solo terminan de morir chispas y humo
	BOLTS = 11,           -- rayos principales
	POINTS = 5,           -- puntos por rayo (más = más quebrado)
	FORK_CHANCE = 0.45,   -- probabilidad de que un rayo tenga una rama
	OUTER_MIN = 4.5,      -- distancia desde el cuerpo donde nacen / mueren (studs)
	OUTER_MAX = 8.5,
	LEN_MIN = 1.8,        -- largo de cada rayo
	LEN_MAX = 3.8,
	JITTER = 0.55,        -- cuánto se quiebra el rayo
	STEP = 0.08,          -- cada cuánto "se redibuja" el rayo
	PULSE_TIME = 0.24,    -- duración del destello (esfera)
	LIGHT_RANGE = 15,
}

local FX_COL = {
	BLACK = Color3.fromRGB(10, 5, 18),
	-- rayo morado (dominante)
	V_GLOW = Color3.fromRGB(130, 40, 225),
	V_BODY = Color3.fromRGB(190, 125, 255),
	V_CORE = Color3.fromRGB(255, 246, 200),
	-- rayo dorado (acento)
	G_GLOW = Color3.fromRGB(115, 32, 200),
	G_BODY = Color3.fromRGB(255, 214, 50),
	G_CORE = Color3.fromRGB(255, 252, 225),
	-- "al rojo blanco": el instante del impacto / de la salida
	H_GLOW = Color3.fromRGB(255, 205, 50),
	H_BODY = Color3.fromRGB(255, 244, 170),
	H_CORE = Color3.fromRGB(255, 255, 255),
	-- destello
	FLASH = Color3.fromRGB(255, 240, 160),
	SHELL = Color3.fromRGB(140, 40, 230),
}

local FX_LAYERS = { "dark", "glow", "body", "core" }
local FX_WIDTH = { dark = 0.95, glow = 0.6, body = 0.2, core = 0.07 }
local FX_EMISSION = { dark = 0, glow = 0.9, body = 0.5, core = 1 }
local FX_OPACITY = { dark = 0.55, glow = 0.6, body = 0.95, core = 1 }   -- la tinta negra nunca es una losa opaca
local FX_ZOFFSET = { dark = 0, glow = 0.01, body = 0.02, core = 0.03 }  -- evita que las capas se peleen (z-fighting)

local FX_SPARK_TEX = "rbxasset://textures/particles/sparkles_main.dds"
local FX_SMOKE_TEX = "rbxasset://textures/particles/smoke_main.dds"

local FX_NAME = "AFO_SpeedForceFx"
local fxState = nil
local fxWarned = false

-- Un fallo visual no debe romper nada, pero tampoco pasar en silencio: avisa UNA vez.
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

-- nseq(t0, v0, t1, v1, ...) / cseq(t0, c0, t1, c1, ...)
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
	local prefix = hot and "H_" or (bolt.gold and "G_" or "V_")
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
		local amp = FX.JITTER * math.sin(math.pi * frac)   -- los extremos quedan sobre el eje
		bolt.jit[k] = bolt.p1 * ((math.random() - 0.5) * 2 * amp)
			+ bolt.p2 * ((math.random() - 0.5) * 2 * amp)
	end
	for k = 1, 2 do
		bolt.bJit[k] = bolt.p1 * ((math.random() - 0.5) * 0.6) + bolt.p2 * ((math.random() - 0.5) * 0.6)
	end
	bolt.flick = 0.7 + math.random() * 0.3
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
	e.Rotation = NumberRange.new(0, 360)
	e.RotSpeed = NumberRange.new(-220, 220)
	e.Shape = Enum.ParticleEmitterShape.Sphere
	e.ShapeStyle = o.surface and Enum.ParticleEmitterShapeStyle.Surface or Enum.ParticleEmitterShapeStyle.Volume
	e.ShapeInOut = o.inward and Enum.ParticleEmitterShapeInOut.Inward or Enum.ParticleEmitterShapeInOut.Outward
	e.LockedToPart = true   -- las chispas siguen al personaje aunque corra a toda velocidad
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

local function playElectricFx(root, mode)
	cancelFx()   -- si había uno a medias (clics rápidos), se corta limpio
	if not root or not root.Parent then return end
	local isIn = (mode == "in")

	local state = { objects = {}, fast = {}, conn = nil }
	fxState = state
	local TOTAL = FX.DURATION + FX.TAIL

	-- track(obj, isFast): todo queda registrado al instante, así un error a mitad de camino
	-- no deja nada huérfano. Lo "fast" (rayos, esferas, luz) se borra al acabar la fase de
	-- rayos; lo demás (chispas, humo) vive hasta TOTAL para que mueran solas.
	local function track(obj, isFast)
		table.insert(state.objects, obj)
		if isFast then table.insert(state.fast, obj) end
		Debris:AddItem(obj, TOTAL + 1.5)
		return obj
	end

	local fxParent = workspace.CurrentCamera or workspace
	local startPos = root.Position

	-- Portador de partículas y esferas: anclado, invisible, sigue al torso cada frame.
	local carrier = track(makeBlock(fxParent, Vector3.new(12, 12, 12)))
	carrier.CFrame = CFrame.new(startPos)
	local core = track(Instance.new("Attachment"))
	core.Name = FX_NAME
	core.Parent = carrier

	-- Esferas del destello: núcleo de neón (amarillo-blanco) + cáscara ForceField morada
	local flashCore = track(makeBlock(fxParent, Vector3.one * 2, FX_COL.FLASH, Enum.Material.Neon, Enum.PartType.Ball), true)
	local flashShell = track(makeBlock(fxParent, Vector3.one * 2, FX_COL.SHELL, Enum.Material.ForceField, Enum.PartType.Ball), true)

	-- Chispas
	local sparkAlpha = nseq(0, 0.05, 0.65, 0.3, 1, 1)
	local inViolet = track(makeEmitter(carrier, {
		surface = true, inward = true, light = 0.6,
		color = cseq(0, Color3.fromRGB(200, 140, 255), 0.5, Color3.fromRGB(125, 45, 220), 1, Color3.fromRGB(30, 10, 60)),
		size = nseq(0, 0.5, 1, 0.05), transparency = sparkAlpha,
		lifetime = NumberRange.new(0.3, 0.4), speed = NumberRange.new(16, 24),
	}))
	local inGold = track(makeEmitter(carrier, {
		surface = true, inward = true, light = 0.9,
		color = cseq(0, Color3.fromRGB(255, 250, 215), 0.4, Color3.fromRGB(255, 224, 70), 1, Color3.fromRGB(150, 60, 200)),
		size = nseq(0, 0.45, 1, 0.05), transparency = sparkAlpha,
		lifetime = NumberRange.new(0.28, 0.36), speed = NumberRange.new(18, 26),
	}))
	local burstGold = track(makeEmitter(core, {
		light = 1,
		color = cseq(0, Color3.fromRGB(255, 252, 225), 0.35, Color3.fromRGB(255, 218, 60), 1, Color3.fromRGB(140, 50, 210)),
		size = nseq(0, 0.6, 1, 0.04), transparency = nseq(0, 0, 0.6, 0.25, 1, 1),
		lifetime = NumberRange.new(0.28, 0.5), speed = NumberRange.new(18, 42), drag = 3,
	}))
	local burstViolet = track(makeEmitter(core, {
		light = 0.7,
		color = cseq(0, Color3.fromRGB(215, 160, 255), 0.5, Color3.fromRGB(120, 40, 215), 1, Color3.fromRGB(25, 8, 50)),
		size = nseq(0, 0.9, 1, 0.1), transparency = nseq(0, 0.05, 0.6, 0.3, 1, 1),
		lifetime = NumberRange.new(0.35, 0.6), speed = NumberRange.new(10, 26), drag = 2,
	}))
	-- Humo negro-violeta, translúcido (residuo que se queda un instante)
	local smoke = track(makeEmitter(core, {
		texture = FX_SMOKE_TEX, light = 0,
		color = cseq(0, Color3.fromRGB(45, 14, 80), 1, Color3.fromRGB(6, 3, 12)),
		size = nseq(0, 0.9, 1, 2.1), transparency = nseq(0, 0.45, 0.5, 0.65, 1, 1),
		lifetime = NumberRange.new(0.5, 0.8), speed = NumberRange.new(3, 9), drag = 1,
		accel = Vector3.new(0, 4, 0),
	}))

	local light = track(Instance.new("PointLight"), true)
	light.Name = FX_NAME
	light.Color = FX_COL.V_GLOW
	light.Range = FX.LIGHT_RANGE
	light.Brightness = 0
	light.Shadows = false
	light.Parent = root

	-- Rayos
	local spread = isIn and 0.3 or 0.15
	local N = FX.POINTS
	local bolts = {}
	for _ = 1, FX.BOLTS do
		local a = math.random() * math.pi * 2
		local y = math.clamp((math.random() - 0.45) * 1.5, -0.7, 0.8)
		local h = math.sqrt(1 - y * y)
		local dir = Vector3.new(math.cos(a) * h, y, math.sin(a) * h)
		local p1 = dir:Cross(Vector3.yAxis).Unit
		local p2 = dir:Cross(p1).Unit
		local phi = math.random() * math.pi * 2
		local bdir = (dir * 0.55 + (p1 * math.cos(phi) + p2 * math.sin(phi)) * 0.85).Unit
		local bdir2 = (bdir + (p1 * (math.random() - 0.5) + p2 * (math.random() - 0.5)) * 0.9).Unit

		local bolt = {
			dir = dir, p1 = p1, p2 = p2, bdir = bdir, bdir2 = bdir2,
			outer = FX.OUTER_MIN + math.random() * (FX.OUTER_MAX - FX.OUTER_MIN),
			len = FX.LEN_MIN + math.random() * (FX.LEN_MAX - FX.LEN_MIN),
			start = math.random() * spread,
			window = 1 - spread,
			scale = 0.8 + math.random() * 0.55,
			gold = math.random() < 0.35,
			fork = math.random() < FX.FORK_CHANCE,
			flick = 1, visible = false, hot = false,
			att = {}, jit = {}, bAtt = {}, bJit = {},
			layers = { dark = {}, glow = {}, body = {}, core = {} },
		}

		local function newAtt()
			local att = track(Instance.new("Attachment"), true)
			att.Name = FX_NAME
			att.Parent = root
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
			beam.Transparency = NumberSequence.new(1)   -- invisible hasta el primer frame
			beam.Parent = root
			table.insert(bolt.layers[layer], beam)
		end

		for _, layer in ipairs(FX_LAYERS) do
			local base = FX_WIDTH[layer] * bolt.scale
			-- tronco: cónico, grueso en la punta (k=1) y fino en la cola
			for s = 1, N - 1 do
				addBeam(layer, bolt.att[s], bolt.att[s + 1],
					base * (1 - 0.7 * (s - 1) / (N - 1)), base * (1 - 0.7 * s / (N - 1)))
			end
			-- rama: sale del punto 3 del tronco, más fina
			if bolt.fork then
				addBeam(layer, bolt.att[3], bolt.bAtt[1], base * 0.55, base * 0.38)
				addBeam(layer, bolt.bAtt[1], bolt.bAtt[2], base * 0.38, base * 0.12)
			end
		end

		rerollJitter(bolt)
		table.insert(bolts, bolt)
	end

	-- Calendario de eventos (t en fracción de DURATION)
	local pulseT0 = nil
	local pulseDone = false
	local function impact()
		pulseT0 = os.clock()
		burstGold:Emit(isIn and 20 or 28)
		burstViolet:Emit(isIn and 14 or 18)
		smoke:Emit(isIn and 5 or 7)
	end

	local events
	if isIn then
		events = {
			{ t = 0.00, fn = function() inViolet:Emit(14) end },
			{ t = 0.08, fn = function() inViolet:Emit(12); inGold:Emit(6) end },
			{ t = 0.18, fn = function() inViolet:Emit(10); inGold:Emit(6) end },
			{ t = 0.30, fn = function() inViolet:Emit(8); inGold:Emit(5) end },
			{ t = 0.62, fn = impact },
		}
	else
		events = {
			{ t = 0.00, fn = impact },
			{ t = 0.10, fn = function() burstViolet:Emit(8) end },
		}
	end
	local nextEvent = 1

	local invisible = NumberSequence.new(1)
	local t0 = os.clock()
	local lastStep = t0
	local boltsCleared = false

	local function update()
		local now = os.clock()
		local elapsed = now - t0
		if elapsed >= TOTAL or not root.Parent then
			cancelFx()
			return
		end

		-- Portador y esferas siguen al torso
		local cf = CFrame.new(root.Position)
		carrier.CFrame = cf
		if not boltsCleared then
			flashCore.CFrame = cf
			flashShell.CFrame = cf
		end

		local tn = elapsed / FX.DURATION
		while events[nextEvent] and tn >= events[nextEvent].t do
			local ev = events[nextEvent]
			nextEvent += 1
			ev.fn()
		end

		-- Fin de la fase de rayos: se borran rayos, esferas y luz; chispas y humo terminan solos
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

				local lead, lenEff, inten, hot
				if isIn then
					-- llega acelerando y se clava; la cola se erosiona al final
					lead = bolt.outer * (1 - p * p)
					local er = math.clamp((p - 0.62) / 0.38, 0, 1)
					lenEff = bolt.len * (1 - er ^ 1.5)
					inten = math.clamp(p / 0.1, 0, 1) * (p > 0.9 and (1 - p) / 0.1 or 1)
					hot = p > 0.78
				else
					-- sale de golpe, al rojo blanco, y se va enfriando y erosionando
					lead = bolt.outer * (1 - (1 - p) ^ 3)
					local er = math.clamp((p - 0.3) / 0.7, 0, 1)
					lenEff = bolt.len * (1 - er ^ 1.5)
					inten = math.clamp(p / 0.04, 0, 1) * (1 - p ^ 2.2)
					hot = p < 0.25
				end
				inten = inten * bolt.flick

				if hot ~= bolt.hot then recolor(bolt, hot) end

				local sizeFactor = math.clamp(lenEff / bolt.len, 0, 1)
				local pos3
				for k = 1, N do
					local kf = (k - 1) / (N - 1)
					local along = isIn and (lead + kf * lenEff) or (lead - kf * lenEff)
					along = math.max(0, along)
					local v = bolt.dir * along + bolt.jit[k] * sizeFactor
					bolt.att[k].Position = v
					if k == 3 then pos3 = v end
				end
				if bolt.fork then
					local b1 = pos3 + bolt.bdir * (lenEff * 0.3) + bolt.bJit[1] * sizeFactor
					local b2 = b1 + bolt.bdir2 * (lenEff * 0.28) + bolt.bJit[2] * sizeFactor
					bolt.bAtt[1].Position = b1
					bolt.bAtt[2].Position = b2
				end

				for _, layer in ipairs(FX_LAYERS) do
					local seq = NumberSequence.new(1 - inten * FX_OPACITY[layer])
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

		-- Destello local (esfera) + luz
		if pulseT0 then
			local u = (now - pulseT0) / FX.PULSE_TIME
			if u < 1 then
				local ease = 1 - (1 - u) ^ 3
				flashCore.Size = Vector3.one * (2.5 + 5 * ease)
				flashCore.Transparency = u < 0.35 and 0.05 or (0.05 + 0.95 * ((u - 0.35) / 0.65) ^ 0.7)
				flashShell.Size = Vector3.one * (4 + 8 * ease)
				flashShell.Transparency = 0.2 + 0.8 * u
				light.Color = u < 0.4 and FX_COL.H_BODY or FX_COL.V_GLOW
				light.Brightness = 3 * (1 - u) ^ 2
			elseif not pulseDone then
				pulseDone = true
				flashCore.Transparency = 1
				flashShell.Transparency = 1
				light.Brightness = 0
			end
		elseif isIn then
			light.Color = FX_COL.V_GLOW
			light.Brightness = 1.4 * math.min(tn / 0.62, 1) ^ 2
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

-- Envoltorios seguros: un fallo visual jamás debe romper el prender/apagar ni el Stop().
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

	local maxSpeed = math.max(currentSpeed * 2.5, 50)
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

-- Restos de versiones anteriores del script (no tenían etiqueta): mismo "molde" exacto.
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

-- Apaga cualquier OTRA copia de SpeedForce que siga viva (p. ej. la version vieja que carga el
-- hub desde GitHub). Su boton X llama al Stop() de ESA copia, asi que se detiene su bucle y su
-- fisica de verdad; despues se borra su panel. Sin esto, la copia vieja seguiria recreando su
-- LinearVelocity cada frame y se sumaria a la nueva (doble freno = "mas friccion").
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

-- Stop(true) = apagado "con despedida" (sonido + electricidad saliendo). Solo el botón X lo usa.
-- Stop() sin argumentos es silencioso: lo usan Start(), la re-ejecución del script y el hub, así
-- no suena ni se ve nada cuando el script solo se está reiniciando o reemplazando.
function M.Stop(withEffect)
	-- Se decide ANTES de tocar el estado, y solo si de verdad estaba prendido.
	if withEffect == true and active and isEnabled then
		safeSfx(SFX_OFF_ID)
		safeFx(rootPart, "out")
	end

	sessionId += 1           -- mata cualquier hilo / bucle de esta sesión
	active = false
	isEnabled = false

	stopPhysicsLoop()
	disconnectAll()

	if gui and gui.Parent then
		gui:Destroy()
	end
	shutdownForeignInstances()   -- copias anteriores / versión vieja del hub
	clearPhysics()               -- y después se barre lo que hayan dejado

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
	currentSpeed = 100
	gameBaseSpeed = 16
	currentSmoothSpeed = 16
	isExploding = false
	lastDashEnd = 0
	boostEndTime = 0

	local playerGui = localPlayer:WaitForChild("PlayerGui")
	
	gui = Instance.new("ScreenGui")
	gui.Name = "AFO_CustomMovement"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = playerGui

	mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainPanel"
	mainFrame.Size = UDim2.new(0, 290, 0, 124)
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
	toggleBtn.Size = UDim2.new(0, 145, 0, 28)
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

	local function refreshToggleText()
		toggleBtn.Text = isEnabled and L("on") or L("off")
	end

	applyLanguage = function()
		currentLang = I18N.detect()
		local t = I18N.strings[currentLang] or I18N.strings.en
		title.Text = t.title
		textBox.PlaceholderText = t.placeholder
		refreshToggleText()
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
				isEnabled = true
				if humanoid then
					gameBaseSpeed = math.abs(humanoid.WalkSpeed)
					if gameBaseSpeed == 0 then gameBaseSpeed = 16 end
					currentSmoothSpeed = gameBaseSpeed
				end
				if startPhysicsLoop then startPhysicsLoop() end
				refreshToggleText()
				toggleBtn.BackgroundColor3 = Color3.fromRGB(80, 20, 140)
				-- Prendido a mano: sonido + electricidad entrando al cuerpo
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
			-- Apagado a mano: sonido + electricidad saliendo del cuerpo
			safeSfx(SFX_OFF_ID)
			safeFx(rootPart, "out")
			isEnabled = false
			stopPhysicsLoop()   -- el bucle deja de correr por completo
			clearPhysics()      -- y se elimina todo lo que cancelaba impulsos
			refreshToggleText()
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
		local silent = gui and gui:GetAttribute(SILENT_ATTR)
		M.Stop(not silent)
	end))

	table.insert(connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if not gameProcessed and input.KeyCode == toggleKey then
			togglePanel()
		end
	end))

	local function setupCharacter(char)
		clearPhysics()   -- fuera cualquier LinearVelocity del personaje anterior
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
	if mySession ~= sessionId then return false end   -- se llamó a Stop mientras cargaba
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

			-- CORRECCIÓN: Normalizar la velocidad de las animaciones para que manos y pies vayan a velocidad normal
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

-- Imprime en consola qué fuerzas/velocidades hay sobre tu HumanoidRootPart y de quién son.
function M.Diagnose()
	local char = localPlayer and localPlayer.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local panels = 0
	local playerGui = localPlayer and localPlayer:FindFirstChild("PlayerGui")
	if playerGui then
		for _, g in ipairs(playerGui:GetChildren()) do
			if g.Name == "AFO_CustomMovement" then panels += 1 end
		end
	end
	print(("[SpeedForce] activo=%s | habilitado=%s | bucle=%s | paneles=%d")
		:format(tostring(active), tostring(isEnabled), tostring(heartbeatConn ~= nil), panels))
	local found = 0
	if root then
		local kinds = { LinearVelocity = true, BodyVelocity = true, BodyPosition = true, VectorForce = true,
			AlignPosition = true, BodyForce = true, BodyThrust = true, LineForce = true }
		for _, d in ipairs(root:GetDescendants()) do
			if kinds[d.ClassName] then
				found += 1
				local owner = d:GetAttribute(TAG) and "esta copia" or "OTRO / versión vieja"
				local force = "?"
				pcall(function() force = tostring(d.MaxAxesForce or d.MaxForce or d.Force) end)
				print(("[SpeedForce]  %s '%s' | dueño: %s | fuerza: %s"):format(d.ClassName, d.Name, owner, force))
			end
		end
	end
	print(("[SpeedForce] controladores de movimiento sobre tu personaje: %d"):format(found))
	return found
end

-- Si ya había otra copia de este módulo corriendo (re-ejecución del script), se apaga primero.
do
	local previousStop = env.__AFO_SpeedForceStop
	if type(previousStop) == "function" then
		pcall(previousStop)
	end
	env.__AFO_SpeedForceStop = function() M.Stop() end
	env.AFO_SpeedForceDiagnose = function() return M.Diagnose() end
end

return M
