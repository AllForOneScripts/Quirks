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
-- EFECTO DE ELECTRICIDAD (estilo Dragon Ball)
--   "in"  = prendido: rayos que viajan desde fuera y se meten en el cuerpo
--   "out" = apagado : rayos que salen del cuerpo hacia afuera
-- Es 100% independiente del panel y de la sesión (sessionId / connections): así puede
-- terminar de reproducirse aunque Stop() destruya el panel. Sus objetos NO llevan la
-- etiqueta TAG, por eso el barrido de clearPhysics() no los toca; se limpian solos al
-- terminar, y Debris es la red de seguridad por si algo falla.
-- ============================================================================
local FX = {
	DURATION = 0.6,       -- segundos
	BOLTS = 12,           -- cantidad de rayos
	POINTS = 5,           -- puntos por rayo (más = más quebrado)
	OUTER_MIN = 4.5,      -- distancia desde el cuerpo donde nacen / mueren (studs)
	OUTER_MAX = 8,
	LEN_MIN = 1.6,        -- largo de cada rayo
	LEN_MAX = 3.4,
	JITTER = 0.5,         -- cuánto se quiebra el rayo
	STEP = 0.045,         -- cada cuánto "chisporrotea" (cambia la forma)
	CORE = Color3.fromRGB(255, 252, 215),   -- núcleo casi blanco
	GLOW = Color3.fromRGB(255, 205, 40),    -- brillo amarillo (cámbialo a azul si prefieres)
	LIGHT_RANGE = 16,
}
local FX_NAME = "AFO_SpeedForceFx"
local fxState = nil

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

local function rerollJitter(bolt)
	for k = 1, FX.POINTS do
		local frac = (k - 1) / (FX.POINTS - 1)
		local amp = FX.JITTER * math.sin(math.pi * frac)   -- los extremos quedan sobre el eje
		bolt.jit[k] = bolt.p1 * ((math.random() - 0.5) * 2 * amp)
			+ bolt.p2 * ((math.random() - 0.5) * 2 * amp)
	end
	bolt.flick = 0.7 + math.random() * 0.3
end

local function makeBeam(a0, a1, color, width, parent)
	local beam = Instance.new("Beam")
	beam.Name = FX_NAME
	beam.Attachment0 = a0
	beam.Attachment1 = a1
	beam.Color = ColorSequence.new(color)
	beam.LightEmission = 1
	beam.LightInfluence = 0
	beam.FaceCamera = true
	beam.Segments = 1
	beam.Width0 = width
	beam.Width1 = width
	beam.Transparency = NumberSequence.new(1)   -- invisible hasta el primer frame
	beam.Parent = parent
	return beam
end

local function playElectricFx(root, mode)
	cancelFx()   -- si había uno a medias (clics rápidos), se corta limpio
	if not root or not root.Parent then return end
	local isIn = (mode == "in")

	local state = { objects = {}, conn = nil }
	fxState = state

	local function track(obj)
		table.insert(state.objects, obj)
		Debris:AddItem(obj, FX.DURATION + 2)
		return obj
	end

	local spread = isIn and 0.35 or 0.2
	local bolts = {}
	for _ = 1, FX.BOLTS do
		local a = math.random() * math.pi * 2
		local y = math.clamp((math.random() - 0.45) * 1.5, -0.7, 0.8)
		local h = math.sqrt(1 - y * y)
		local dir = Vector3.new(math.cos(a) * h, y, math.sin(a) * h)
		local p1 = dir:Cross(Vector3.yAxis).Unit
		local p2 = dir:Cross(p1).Unit

		local bolt = {
			dir = dir, p1 = p1, p2 = p2,
			outer = FX.OUTER_MIN + math.random() * (FX.OUTER_MAX - FX.OUTER_MIN),
			len = FX.LEN_MIN + math.random() * (FX.LEN_MAX - FX.LEN_MIN),
			start = math.random() * spread,
			window = 1 - spread,
			flick = 1,
			visible = false,
			att = {}, jit = {}, glow = {}, core = {},
		}

		for k = 1, FX.POINTS do
			local att = Instance.new("Attachment")
			att.Name = FX_NAME
			att.Parent = root
			track(att)
			bolt.att[k] = att
		end

		local glowWidth = 0.35 + math.random() * 0.2
		local coreWidth = 0.1 + math.random() * 0.06
		for k = 1, FX.POINTS - 1 do
			bolt.glow[k] = track(makeBeam(bolt.att[k], bolt.att[k + 1], FX.GLOW, glowWidth, root))
			bolt.core[k] = track(makeBeam(bolt.att[k], bolt.att[k + 1], FX.CORE, coreWidth, root))
		end

		rerollJitter(bolt)
		table.insert(bolts, bolt)
	end

	local light = Instance.new("PointLight")
	light.Name = FX_NAME
	light.Color = FX.CORE
	light.Range = FX.LIGHT_RANGE
	light.Brightness = 0
	light.Shadows = false
	light.Parent = root
	track(light)

	local invisible = NumberSequence.new(1)
	local t0 = os.clock()
	local lastStep = t0

	local function update()
		local now = os.clock()
		local tn = (now - t0) / FX.DURATION
		if tn >= 1 or not root.Parent then
			cancelFx()
			return
		end

		local reroll = (now - lastStep) >= FX.STEP
		if reroll then lastStep = now end

		for _, bolt in ipairs(bolts) do
			local p = (tn - bolt.start) / bolt.window
			if p > 0 and p < 1 then
				if reroll then rerollJitter(bolt) end

				local r, inten
				if isIn then
					-- llega acelerando y se "traga" dentro del cuerpo
					r = bolt.outer + (-bolt.len - bolt.outer) * (p * p)
					inten = math.clamp(p / 0.2, 0, 1) * math.clamp((1 - p) / 0.3, 0, 1)
				else
					-- sale de golpe y se va apagando mientras se aleja
					local e = 1 - (1 - p) ^ 3
					r = -bolt.len + (bolt.outer + bolt.len) * e
					inten = math.clamp(p / 0.05, 0, 1) * math.clamp((1 - p) / 0.7, 0, 1)
				end
				inten = inten * bolt.flick

				for k = 1, FX.POINTS do
					local frac = (k - 1) / (FX.POINTS - 1)
					local along = math.max(0, r + frac * bolt.len)   -- nunca cruza al otro lado
					bolt.att[k].Position = bolt.dir * along + bolt.jit[k]
				end

				local glowSeq = NumberSequence.new(1 - inten * 0.55)
				local coreSeq = NumberSequence.new(1 - inten)
				for k = 1, FX.POINTS - 1 do
					bolt.glow[k].Transparency = glowSeq
					bolt.core[k].Transparency = coreSeq
				end
				bolt.visible = true
			elseif bolt.visible then
				for k = 1, FX.POINTS - 1 do
					bolt.glow[k].Transparency = invisible
					bolt.core[k].Transparency = invisible
				end
				bolt.visible = false
			end
		end

		if isIn then
			light.Brightness = 3.5 * tn * tn * math.clamp((1 - tn) / 0.15, 0, 1)
		else
			light.Brightness = 4 * (1 - tn) ^ 2
		end
	end

	state.conn = RunService.Heartbeat:Connect(function()
		if fxState ~= state then return end
		local ok = pcall(update)
		if not ok then cancelFx() end   -- si algo falla, limpia y no se queda arrastrando errores
	end)
end

-- Envoltorios seguros: un fallo visual jamás debe romper el prender/apagar ni el Stop().
local function safeSfx(id)
	pcall(playSfx, id)
end

local function safeFx(root, mode)
	local ok = pcall(playElectricFx, root, mode)
	if not ok then cancelFx() end
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
