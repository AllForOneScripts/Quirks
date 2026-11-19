local M = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer

-- ==========================================
-- PARÁMETROS FIJOS (no editables desde el menú)
-- ==========================================
local GRAVEDAD_CERO = 0
local ACELERACION_CAIDA = 0.75      -- por frame a 60 FPS (se escala con dt)

local TIEMPO_PEGADO_CABEZA = 0.22
-- Ajuste del agarre: copia la posición baja del TP de Passive Bang.
local AJUSTE_ALTURA_CABEZA_SLAM = -3.5

-- Seguimiento del objetivo durante el ZAAASH.
local PREDICCION_MOVIMIENTO_SLAM = 0.12
local TIEMPO_GUIADO_DESCENSO_SLAM = 0.38
local DISTANCIA_MAX_CORRECCION_SLAM = 24
local ALCANCE_VERTICAL_HITBOX_SLAM = 3
local MARGEN_SEGURO_SUELO_SLAM = 0.75

-- Plataforma de aire ("caminar en el aire")
local PLAT_TAM = 28                 -- lado (studs). Grande: nunca te quedas sin piso
local PLAT_GROSOR = 4               -- grueso: no se atraviesa
local PLAT_ADELANTO_TIEMPO = 0.12   -- cuánto "por delante" se coloca según tu intención de caminar
local PLAT_ADELANTO_MAX = 8         -- tope del adelanto (studs)
local PLAT_REANCLAR_DIST = 3        -- si algo te saca más de esto del piso, el piso se re-ancla a tus pies
local PLAT_SUBIDA_MAX_SOBRE_PIES = 0.6 -- el piso nunca sube más de esto por encima de tus pies
local PLAT_VY_MAX = 60              -- velocidad vertical máxima al guiarte con la mirada

-- ==========================================
-- AJUSTES EDITABLES (se muestran en el menú y se guardan en archivo)
-- ==========================================
local ARCHIVO_CONFIG = "AllForOne/gravattack_config.json"

local SCHEMA = {
	{ tipo = "titulo", texto = "TECLAS" },
	{ tipo = "tecla", id = "Fly",      texto = "Volar (mantener)",         def = Enum.KeyCode.Space },
	{ tipo = "tecla", id = "Platform", texto = "Caminar en el aire",       def = Enum.KeyCode.C },
	{ tipo = "tecla", id = "Slam",     texto = "Slam / ZAAASH",            def = Enum.KeyCode.LeftControl },
	{ tipo = "tecla", id = "Menu",     texto = "Abrir / cerrar este menú", def = Enum.KeyCode.RightShift },

	{ tipo = "titulo", texto = "CAMINAR EN EL AIRE" },
	{ tipo = "num",  id = "velocidad",   texto = "Velocidad (aire y vuelo)",  def = 85, min = 20,  max = 250, paso = 5 },
	{ tipo = "bool", id = "guiarMirada", texto = "Subir/bajar con la mirada", def = true },
	{ tipo = "num",  id = "zonaMuerta",  texto = "Zona muerta mirada (°)",    def = 20, min = 0,   max = 60,  paso = 5 },

	{ tipo = "titulo", texto = "VUELO" },
	{ tipo = "num", id = "impulsoY",   texto = "Impulso vertical",      def = 60,  min = 10,  max = 200, paso = 5 },
	{ tipo = "num", id = "impulsoXZ",  texto = "Impulso horizontal",    def = 120, min = 0,   max = 300, paso = 10 },
	{ tipo = "num", id = "caidaLenta", texto = "Velocidad de caída",    def = -15, min = -80, max = 0,   paso = 5 },

	{ tipo = "titulo", texto = "SLAM" },
	{ tipo = "num", id = "distSlam",     texto = "Alcance para buscar objetivo", def = 30,   min = 5,    max = 120, paso = 5 },
	{ tipo = "num", id = "descensoSlam", texto = "Velocidad de caída del slam",  def = -140, min = -400, max = -40, paso = 10 },
}

local _cfg = {}
for _, item in ipairs(SCHEMA) do
	if item.id then _cfg[item.id] = item.def end
end

-- ==========================================
-- ESTADO
-- ==========================================
local _conns = {}
local _isActive = false
local _hubKeys = nil   -- tabla Keys del hub (solo se refleja Platform, por compatibilidad)

local isHoldingFly = false
local isPlatformMode = false
local isFloating = false
local isSlamming = false
local holdTimer = 0
local lastDamageTime = 0
local lastSlamEndTime = 0

local character, humanoid, rootPart, animator
local animVuelo, animReSalto, animImpacto, animDespertar, animPlataforma

local plataformaActiva = nil
local alturaPlataforma = 0
local loopPlataformaConn = nil

-- ==========================================
-- GRAVEDAD (a prueba de reinicios del módulo)
-- ==========================================
local GRAVEDAD_NORMAL = 196.2
local genv = (type(getgenv) == "function") and getgenv() or nil

local function RecordarGravedad()
	local g = workspace.Gravity
	if g > 1 then
		GRAVEDAD_NORMAL = g
		if genv then genv.AFO_GRAV_NORMAL = g end
	else
		-- Si el módulo se reinició con gravedad 0, NO se toma ese 0 como "normal"
		GRAVEDAD_NORMAL = (genv and genv.AFO_GRAV_NORMAL) or 196.2
	end
end

local function GravedadCero()
	if workspace.Gravity ~= GRAVEDAD_CERO then workspace.Gravity = GRAVEDAD_CERO end
	if genv then genv.AFO_GRAV_ZEROED = true end
end

local function GravedadNormal()
	if workspace.Gravity ~= GRAVEDAD_NORMAL then workspace.Gravity = GRAVEDAD_NORMAL end
	if genv then genv.AFO_GRAV_ZEROED = false end
end

-- ==========================================
-- GUARDADO / CARGA
-- ==========================================
local _guardadoOk = nil
local _guardarToken = 0
local ActualizarEstadoMenu = function() end

local function GuardarAhora()
	if type(writefile) ~= "function" then
		_guardadoOk = false
		return false
	end

	local data = {}
	for _, item in ipairs(SCHEMA) do
		if item.id then
			local v = _cfg[item.id]
			if item.tipo == "tecla" then
				data[item.id] = v.Name
			else
				data[item.id] = v
			end
		end
	end

	local ok = pcall(function()
		if type(isfolder) == "function" and type(makefolder) == "function"
			and not isfolder("AllForOne") then
			makefolder("AllForOne")
		end
		writefile(ARCHIVO_CONFIG, HttpService:JSONEncode(data))
	end)

	_guardadoOk = ok
	return ok
end

local function GuardarConRetardo()
	_guardarToken += 1
	local mi = _guardarToken

	task.delay(0.35, function()
		if mi ~= _guardarToken then return end
		GuardarAhora()
		ActualizarEstadoMenu()
	end)
end

-- Devuelve la lista de ids que SÍ estaban en el archivo.
local function Cargar()
	local cargadas = {}
	if type(readfile) ~= "function" then return cargadas end

	local ok, raw = pcall(function()
		if type(isfile) == "function" and not isfile(ARCHIVO_CONFIG) then return nil end
		return readfile(ARCHIVO_CONFIG)
	end)
	if not ok or type(raw) ~= "string" or raw == "" then return cargadas end

	local ok2, data = pcall(function() return HttpService:JSONDecode(raw) end)
	if not ok2 or type(data) ~= "table" then return cargadas end

	for _, item in ipairs(SCHEMA) do
		local v = item.id and data[item.id]
		if v ~= nil then
			if item.tipo == "tecla" and type(v) == "string" then
				local okK, kc = pcall(function() return Enum.KeyCode[v] end)
				if okK and typeof(kc) == "EnumItem" then
					_cfg[item.id] = kc
					cargadas[item.id] = true
				end
			elseif item.tipo == "num" and type(v) == "number" then
				_cfg[item.id] = math.clamp(v, item.min, item.max)
				cargadas[item.id] = true
			elseif item.tipo == "bool" and type(v) == "boolean" then
				_cfg[item.id] = v
				cargadas[item.id] = true
			end
		end
	end

	return cargadas
end

local function SincronizarHub()
	if _hubKeys then
		_hubKeys.Platform = _cfg.Platform
	end
end

-- ==========================================
-- TECLAS
-- ==========================================
local EQUIV = {
	[Enum.KeyCode.LeftControl] = Enum.KeyCode.RightControl,
	[Enum.KeyCode.RightControl] = Enum.KeyCode.LeftControl,
}

-- equivalente = true: Ctrl izquierdo/derecho cuentan como la misma tecla.
local function Coincide(input, kc, equivalente)
	if not kc then return false end
	if input.KeyCode == kc then return true end

	if equivalente then
		local eq = EQUIV[kc]
		return eq ~= nil and input.KeyCode == eq
	end

	return false
end

-- ==========================================
-- ANIMACIONES
-- ==========================================
local function LoadAnim(id, priority, looped)
	if not animator then return nil end

	local anim = Instance.new("Animation")
	anim.AnimationId = id

	local track = animator:LoadAnimation(anim)
	track.Priority = priority
	track.Looped = looped

	return track
end

local function DetenerAnimacionesCustom(fadeTime)
	fadeTime = fadeTime or 0.2

	if animVuelo and animVuelo.IsPlaying then animVuelo:Stop(fadeTime) end
	if animReSalto and animReSalto.IsPlaying then animReSalto:Stop(fadeTime) end
	if animImpacto and animImpacto.IsPlaying then animImpacto:Stop(fadeTime) end
	if animDespertar and animDespertar.IsPlaying then animDespertar:Stop(fadeTime) end
	if animPlataforma and animPlataforma.IsPlaying then animPlataforma:Stop(fadeTime) end
end

-- ==========================================
-- ANIMACIÓN DE PLATAFORMA
-- ==========================================
local function IniciarLoopAnimPlataforma()
	if not animPlataforma then return end

	if loopPlataformaConn then
		loopPlataformaConn:Disconnect()
		loopPlataformaConn = nil
	end

	animPlataforma:Play(0.1)

	task.spawn(function()
		while animPlataforma and animPlataforma.Length == 0 do
			task.wait()
		end

		if not animPlataforma or not plataformaActiva then return end

		local totalLength = animPlataforma.Length
		local maxTime = totalLength * 0.49
		local minTime = totalLength * 0.40
		local velocidadFlotar = 0.1

		animPlataforma.TimePosition = maxTime
		animPlataforma:AdjustSpeed(-velocidadFlotar)

		local yendoHaciaAtras = true

		loopPlataformaConn = RunService.Heartbeat:Connect(function()
			if not plataformaActiva or not animPlataforma or not animPlataforma.IsPlaying then
				if loopPlataformaConn then
					loopPlataformaConn:Disconnect()
					loopPlataformaConn = nil
				end
				return
			end

			local currentTime = animPlataforma.TimePosition

			if yendoHaciaAtras then
				if currentTime <= minTime then
					animPlataforma.TimePosition = minTime
					animPlataforma:AdjustSpeed(velocidadFlotar)
					yendoHaciaAtras = false
				end
			else
				if currentTime >= maxTime then
					animPlataforma.TimePosition = maxTime
					animPlataforma:AdjustSpeed(-velocidadFlotar)
					yendoHaciaAtras = true
				end
			end
		end)
	end)
end

-- ==========================================
-- GEOMETRÍA DEL PERSONAJE
-- ==========================================
-- Distancia del centro de la raíz a la suela de los pies (R15 y R6).
local function AlturaRaiz()
	local h = humanoid.HipHeight + (rootPart.Size.Y / 2)

	if humanoid.RigType == Enum.HumanoidRigType.R6 then
		local pierna = character and (character:FindFirstChild("Left Leg") or character:FindFirstChild("Right Leg"))
		h += (pierna and pierna:IsA("BasePart")) and pierna.Size.Y or 2
	end

	return h
end

-- ==========================================
-- PLATAFORMA DE AIRE
-- ==========================================
-- Idea: un piso invisible y grueso que NO se queda debajo de donde estás, sino
-- debajo de donde VAS: se coloca por delante según tu intención de caminar
-- (humanoid.MoveDirection) antes de cada paso de física. Su altura es una variable
-- propia (el "piso de aire"): se mantiene fija mientras caminas y, si quieres,
-- sube/baja según hacia dónde mires. Como el Humanoid pisa suelo real, conservas
-- salto, estado "en suelo" y la gravedad normal del mundo no se toca.
local function DestruirPlataforma()
	isPlatformMode = false

	if loopPlataformaConn then
		loopPlataformaConn:Disconnect()
		loopPlataformaConn = nil
	end

	if plataformaActiva then
		plataformaActiva:Destroy()
		plataformaActiva = nil
	end

	if animPlataforma and animPlataforma.IsPlaying then
		animPlataforma:Stop(0.2)
	end

	-- No cambia isFloating:
	-- si ya estabas volando antes de la plataforma, continuarás volando.
	if isFloating and not isSlamming and animVuelo then
		animVuelo:Play(0.2)
	end
end

local function CrearPlataforma()
	if plataformaActiva or not rootPart or not humanoid then return end

	local p = Instance.new("Part")
	p.Name = "PlataformaGravattack"
	p.Size = Vector3.new(PLAT_TAM, PLAT_GROSOR, PLAT_TAM)
	p.Transparency = 1
	p.Anchored = true
	p.CanCollide = true
	p.CanTouch = false
	-- CanQuery se deja en true a propósito: el Humanoid detecta su piso con consultas
	-- espaciales; con false podía no reconocer la plataforma (estado de caída permanente).
	p.CanQuery = true
	p.CastShadow = false
	p.Locked = true

	local pies = rootPart.Position.Y - AlturaRaiz()
	alturaPlataforma = pies

	p.CFrame = CFrame.new(
		rootPart.Position.X,
		alturaPlataforma - PLAT_GROSOR / 2,
		rootPart.Position.Z
	)
	p.Parent = workspace
	plataformaActiva = p

	if animVuelo and animVuelo.IsPlaying then
		animVuelo:Stop(0.2)
	end

	local vel = rootPart.AssemblyLinearVelocity
	rootPart.AssemblyLinearVelocity = Vector3.new(vel.X, 0, vel.Z)
	isPlatformMode = true

	IniciarLoopAnimPlataforma()
end

-- Se llama antes de cada paso de física mientras la plataforma está activa.
local function ActualizarPlataforma(dt)
	local raiz = AlturaRaiz()
	local pos = rootPart.Position
	local pies = pos.Y - raiz
	local vel = _cfg.velocidad

	-- 1) Intención de caminar
	local mv = humanoid.MoveDirection
	local plano = Vector3.new(mv.X, 0, mv.Z)
	local hayIntencion = plano.Magnitude > 0.05
	local dirIntencion = hayIntencion and plano.Unit or Vector3.zero

	-- 2) Guiado vertical por la mirada (ángulo de la cámara fuera de la zona muerta)
	local vy = 0
	if _cfg.guiarMirada and hayIntencion then
		local cam = workspace.CurrentCamera
		if cam then
			local look = cam.CFrame.LookVector
			local pitch = math.asin(math.clamp(look.Y, -1, 1))
			local zona = math.rad(_cfg.zonaMuerta)
			local efectivo = 0

			if pitch > zona then
				efectivo = pitch - zona
			elseif pitch < -zona then
				efectivo = pitch + zona
			end

			if efectivo ~= 0 then
				local lookPlano = Vector3.new(look.X, 0, look.Z)
				if lookPlano.Magnitude > 1e-3 then
					-- Caminar hacia donde miras sube/baja; de espaldas o de lado, no.
					local alineacion = dirIntencion:Dot(lookPlano.Unit)
					vy = math.clamp(math.sin(efectivo) * vel * 0.8 * alineacion, -PLAT_VY_MAX, PLAT_VY_MAX)
				end
			end
		end
	end

	-- 3) Altura del piso de aire
	if math.abs(pies - alturaPlataforma) > PLAT_REANCLAR_DIST then
		-- Algo te sacó del piso (golpe, ragdoll...): el piso se re-ancla a tus pies
		-- en vez de dejarte atrapado debajo o cayendo.
		alturaPlataforma = pies
	end

	alturaPlataforma += vy * dt

	if alturaPlataforma > pies + PLAT_SUBIDA_MAX_SOBRE_PIES then
		alturaPlataforma = pies + PLAT_SUBIDA_MAX_SOBRE_PIES
	end

	-- El piso de aire no baja del suelo real
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude
	rp.FilterDescendantsInstances = { character, plataformaActiva }
	rp.RespectCanCollide = true

	local suelo = workspace:Raycast(pos, Vector3.new(0, -(raiz + 600), 0), rp)
	if suelo and alturaPlataforma <= suelo.Position.Y then
		alturaPlataforma = suelo.Position.Y
		if vy < 0 then vy = 0 end
	end

	-- 4) Velocidad: horizontal = intención, vertical = guiado + red de seguridad
	local velY = vy
	local errY = alturaPlataforma - pies
	if math.abs(errY) > 0.3 then
		velY += math.clamp(errY * 8, -30, 30)
	end

	local vxz = dirIntencion * vel
	rootPart.AssemblyLinearVelocity = Vector3.new(vxz.X, velY, vxz.Z)

	-- 5) El piso se coloca POR DELANTE, hacia donde quieres ir
	local adelanto = dirIntencion * math.min(vel * PLAT_ADELANTO_TIEMPO, PLAT_ADELANTO_MAX)
	plataformaActiva.CFrame = CFrame.new(
		pos.X + adelanto.X,
		alturaPlataforma - PLAT_GROSOR / 2,
		pos.Z + adelanto.Z
	)
end

-- ==========================================
-- SUELO Y OBJETIVOS
-- ==========================================
local function BuscarSueloDebajo()
	if not rootPart then return nil end

	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = { character, plataformaActiva }
	rayParams.RespectCanCollide = true

	local origen = rootPart.Position + Vector3.new(0, 3, 0)

	return workspace:Raycast(
		origen,
		Vector3.new(0, -10000, 0),
		rayParams
	)
end

local function BuscarSueloDebajoDe(posicion, instanciasIgnoradas)
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = instanciasIgnoradas
	rayParams.RespectCanCollide = true

	return workspace:Raycast(
		posicion + Vector3.new(0, 3, 0),
		Vector3.new(0, -10000, 0),
		rayParams
	)
end

local function BuscarObjetivoDebajo()
	if not rootPart then return nil end

	local objetivo = nil
	local menorDistancia = _cfg.distSlam

	for _, otroJugador in ipairs(Players:GetPlayers()) do
		if otroJugador ~= player and otroJugador.Character then
			local enemigoRoot = otroJugador.Character:FindFirstChild("HumanoidRootPart")
			local enemigoHumanoid = otroJugador.Character:FindFirstChildOfClass("Humanoid")

			if enemigoRoot and enemigoHumanoid and enemigoHumanoid.Health > 0 then
				local diferenciaY = rootPart.Position.Y - enemigoRoot.Position.Y

				local distanciaXZ = (
					Vector3.new(rootPart.Position.X, 0, rootPart.Position.Z)
					- Vector3.new(enemigoRoot.Position.X, 0, enemigoRoot.Position.Z)
				).Magnitude

				if diferenciaY > 2
					and diferenciaY < 150
					and distanciaXZ < menorDistancia then

					objetivo = enemigoRoot
					menorDistancia = distanciaXZ
				end
			end
		end
	end

	return objetivo
end

-- ==========================================
-- SLAM
-- ==========================================
local function PegarALaCabeza(objetivoRoot)
	if not objetivoRoot or not objetivoRoot.Parent then return end

	if animImpacto then
		animImpacto:Play(0.1)
	end

	local tiempo = 0
	local faseDescenso = false
	local conexion

	conexion = RunService.Heartbeat:Connect(function(dt)
		if not _isActive or not rootPart or not humanoid
			or not objetivoRoot or not objetivoRoot.Parent then
			if conexion then conexion:Disconnect() end
			isSlamming = false
			lastSlamEndTime = tick()
			return
		end

		tiempo += dt

		local cabeza = objetivoRoot.Parent:FindFirstChild("Head")
		local posicionCabeza = cabeza and cabeza.Position
			or (objetivoRoot.Position + Vector3.new(0, objetivoRoot.Size.Y, 0))
		local velocidadObjetivo = objetivoRoot.AssemblyLinearVelocity
		-- Predice la posición inmediatamente posterior a un dash del objetivo.
		local posicionPredicha = posicionCabeza
			+ Vector3.new(velocidadObjetivo.X, 0, velocidadObjetivo.Z)
				* PREDICCION_MOVIMIENTO_SLAM

		local alturaSobreCabeza = humanoid.HipHeight
			+ (rootPart.Size.Y / 2) + 0.15 + AJUSTE_ALTURA_CABEZA_SLAM
		local sueloObjetivo = BuscarSueloDebajoDe(posicionPredicha, {
			character,
			objetivoRoot.Parent,
		})

		-- Empieza desde una Y desde la que la zona de impacto alcanza primero al
		-- objetivo, sin que su borde inferior toque el suelo antes.
		local alturaEntrada = math.max(
			posicionCabeza.Y + alturaSobreCabeza,
			objetivoRoot.Position.Y + ALCANCE_VERTICAL_HITBOX_SLAM
		)

		if sueloObjetivo then
			alturaEntrada = math.max(
				alturaEntrada,
				sueloObjetivo.Position.Y
					+ ALCANCE_VERTICAL_HITBOX_SLAM
					+ MARGEN_SEGURO_SUELO_SLAM
			)
		end

		if not faseDescenso and tiempo >= TIEMPO_PEGADO_CABEZA then
			faseDescenso = true
			tiempo = 0
		end

		if not faseDescenso then
			rootPart.CFrame = CFrame.new(
				posicionPredicha.X, alturaEntrada, posicionPredicha.Z
			)
			rootPart.AssemblyLinearVelocity = Vector3.new(
				velocidadObjetivo.X, -20, velocidadObjetivo.Z
			)
			return
		end

		-- Mantiene el X/Z enganchado al objetivo durante el inicio de la caída.
		-- Así un dash súbito no deja el golpe dirigido hacia suelo vacío.
		local diferenciaXZ = Vector3.new(
			posicionPredicha.X - rootPart.Position.X, 0,
			posicionPredicha.Z - rootPart.Position.Z
		)

		if tiempo < TIEMPO_GUIADO_DESCENSO_SLAM
			and diferenciaXZ.Magnitude <= DISTANCIA_MAX_CORRECCION_SLAM then
			rootPart.CFrame = CFrame.new(
				posicionPredicha.X, rootPart.Position.Y, posicionPredicha.Z
			)
			rootPart.AssemblyLinearVelocity = Vector3.new(
				velocidadObjetivo.X, _cfg.descensoSlam, velocidadObjetivo.Z
			)
			return
		end

		conexion:Disconnect()
		rootPart.AssemblyLinearVelocity = Vector3.new(
			velocidadObjetivo.X, _cfg.descensoSlam, velocidadObjetivo.Z
		)
		isSlamming = false
		lastSlamEndTime = tick()
	end)

	table.insert(_conns, conexion)
end

local function AplastarContraElSuelo()
	if isSlamming or not rootPart or not humanoid or not _isActive then
		return
	end

	isSlamming = true

	-- Caminar en el aire también cuenta como "estar volando" para el ZAAASH.
	local estabaEnPlataforma = isPlatformMode
	DestruirPlataforma()
	DetenerAnimacionesCustom(0.1)

	-- El ZAAASH a un jugador solo se usa al presionar el botón de slam estando en el aire.
	-- No exige una altura mínima: basta con que el objetivo esté debajo.
	local estabaVolando = isFloating or estabaEnPlataforma
	isFloating = false
	holdTimer = 0
	GravedadNormal()

	local objetivo = estabaVolando and BuscarObjetivoDebajo() or nil

	if objetivo then
		PegarALaCabeza(objetivo)
		return
	end

	local rayResult = BuscarSueloDebajo()

	if not rayResult then
		rootPart.AssemblyLinearVelocity = Vector3.new(0, -120, 0)
		humanoid:ChangeState(Enum.HumanoidStateType.Freefall)

		task.delay(0.15, function()
			if _isActive then
				isSlamming = false
				lastSlamEndTime = tick()
			end
		end)

		return
	end

	rootPart.CFrame = CFrame.new(
		rayResult.Position + Vector3.new(0, AlturaRaiz(), 0)
	)

	rootPart.AssemblyLinearVelocity = Vector3.zero
	humanoid:ChangeState(Enum.HumanoidStateType.Landed)

	task.delay(0.1, function()
		if not _isActive then return end

		isSlamming = false
		lastSlamEndTime = tick()
		DetenerAnimacionesCustom(0.2)
	end)
end

-- ==========================================
-- PERSONAJE
-- ==========================================
local function SetupCharacter(newCharacter)
	DestruirPlataforma()

	character = newCharacter
	humanoid = character:WaitForChild("Humanoid", 3)
	rootPart = character:WaitForChild("HumanoidRootPart", 3)

	if not humanoid or not rootPart then return end

	animator = humanoid:WaitForChild("Animator", 3)

	if animator then
		animVuelo = LoadAnim("rbxassetid://85623478299098", Enum.AnimationPriority.Action2, true)
		animReSalto = LoadAnim("rbxassetid://75312251819975", Enum.AnimationPriority.Action3, false)
		animImpacto = LoadAnim("rbxassetid://127236244922151", Enum.AnimationPriority.Action4, false)
		animDespertar = LoadAnim("rbxassetid://83644153292302", Enum.AnimationPriority.Action4, false)
		animPlataforma = LoadAnim("rbxassetid://79304876640360", Enum.AnimationPriority.Action4, false)
	end

	isFloating = false
	isSlamming = false
	isHoldingFly = false
	isPlatformMode = false
	holdTimer = 0
	GravedadNormal()

	local lastHealth = humanoid.Health

	local healthConn = humanoid.HealthChanged:Connect(function(health)
		if health < lastHealth then
			lastDamageTime = tick()
		end

		lastHealth = health
	end)

	table.insert(_conns, healthConn)

	-- Al morir: sin plataforma y gravedad normal (antes los cuerpos quedaban flotando)
	local diedConn = humanoid.Died:Connect(function()
		isFloating = false
		isSlamming = false
		isHoldingFly = false
		DestruirPlataforma()
		GravedadNormal()
	end)

	table.insert(_conns, diedConn)
end

-- ==========================================
-- MENÚ DE AJUSTES
-- ==========================================
local _menuGui, _menuMain, _estadoLabel
local _menuConns = {}
local _refrescadores = {}
local _capturando = nil
local _ultimaCaptura = 0

local function RefrescarMenu()
	for _, f in ipairs(_refrescadores) do
		pcall(f)
	end
	ActualizarEstadoMenu()
end

local function CancelarCaptura()
	if not _capturando then return end

	local c = _capturando
	_capturando = nil

	if c.conn then c.conn:Disconnect() end
	if c.boton and c.boton.Parent then
		c.boton.Text = _cfg[c.id].Name
	end
end

local function AsignarTecla(id, kc)
	local anterior = _cfg[id]
	if anterior == kc then return end

	-- Si otra acción ya usaba esa tecla, se intercambian (nunca quedan duplicadas)
	for otroId, valor in pairs(_cfg) do
		if otroId ~= id and valor == kc then
			_cfg[otroId] = anterior
		end
	end

	_cfg[id] = kc
	SincronizarHub()
	RefrescarMenu()
	GuardarConRetardo()
end

local function IniciarCaptura(id, boton)
	CancelarCaptura()

	boton.Text = "Pulsa una tecla..."

	local conn
	conn = UserInputService.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
		if input.KeyCode == Enum.KeyCode.Unknown then return end

		_ultimaCaptura = os.clock()

		if input.KeyCode ~= Enum.KeyCode.Escape then
			AsignarTecla(id, input.KeyCode)
		end

		CancelarCaptura()
	end)

	_capturando = { id = id, boton = boton, conn = conn }
end

ActualizarEstadoMenu = function()
	if not _estadoLabel or not _estadoLabel.Parent then return end

	if _guardadoOk == true then
		_estadoLabel.Text = "Guardado en " .. ARCHIVO_CONFIG
		_estadoLabel.TextColor3 = Color3.fromRGB(120, 220, 140)
	elseif _guardadoOk == false then
		_estadoLabel.Text = "No se pudo guardar (el ejecutor no tiene writefile)"
		_estadoLabel.TextColor3 = Color3.fromRGB(240, 190, 90)
	else
		_estadoLabel.Text = "Los cambios se guardan solos"
		_estadoLabel.TextColor3 = Color3.fromRGB(150, 158, 180)
	end
end

local function DestruirMenu()
	CancelarCaptura()

	for _, c in ipairs(_menuConns) do
		if c.Disconnect then c:Disconnect() end
	end
	table.clear(_menuConns)
	table.clear(_refrescadores)

	if _menuGui then
		_menuGui:Destroy()
	end

	_menuGui, _menuMain, _estadoLabel = nil, nil, nil
end

local function AbrirMenu(visible)
	if not _menuMain then return end

	if visible == nil then
		visible = not _menuMain.Visible
	end

	_menuMain.Visible = visible

	if not visible then
		CancelarCaptura()
	else
		RefrescarMenu()
	end
end

local function CrearMenu()
	if _menuGui then return end

	local gui = Instance.new("ScreenGui")
	gui.Name = "GravattackMenu"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 1000
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	local parentado = false

	if type(gethui) == "function" then
		parentado = pcall(function() gui.Parent = gethui() end) and gui.Parent ~= nil
	end

	if not parentado then
		parentado = pcall(function() gui.Parent = game:GetService("CoreGui") end) and gui.Parent ~= nil
	end

	if not parentado then
		gui.Parent = player:WaitForChild("PlayerGui")
	end

	_menuGui = gui

	local function redondear(obj, radio)
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, radio)
		c.Parent = obj
	end

	local main = Instance.new("Frame")
	main.Name = "Main"
	main.Size = UDim2.fromOffset(360, 480)
	main.Position = UDim2.new(0.5, -180, 0.5, -240)
	main.BackgroundColor3 = Color3.fromRGB(18, 20, 28)
	main.BorderSizePixel = 0
	main.Active = true
	main.Visible = false
	main.Parent = gui
	redondear(main, 10)
	_menuMain = main

	local borde = Instance.new("UIStroke")
	borde.Color = Color3.fromRGB(90, 140, 255)
	borde.Thickness = 1.5
	borde.Transparency = 0.3
	borde.Parent = main

	-- Barra de título (arrastrable)
	local titulo = Instance.new("Frame")
	titulo.Name = "Titulo"
	titulo.Size = UDim2.new(1, 0, 0, 36)
	titulo.BackgroundColor3 = Color3.fromRGB(26, 30, 44)
	titulo.BorderSizePixel = 0
	titulo.Parent = main
	redondear(titulo, 10)

	local tl = Instance.new("TextLabel")
	tl.BackgroundTransparency = 1
	tl.Position = UDim2.fromOffset(12, 0)
	tl.Size = UDim2.new(1, -56, 1, 0)
	tl.Font = Enum.Font.GothamBold
	tl.TextSize = 14
	tl.TextColor3 = Color3.fromRGB(235, 240, 255)
	tl.TextXAlignment = Enum.TextXAlignment.Left
	tl.Text = "GRAVATTACK  ·  Ajustes"
	tl.Parent = titulo

	local cerrar = Instance.new("TextButton")
	cerrar.Size = UDim2.fromOffset(28, 28)
	cerrar.Position = UDim2.new(1, -32, 0, 4)
	cerrar.BackgroundColor3 = Color3.fromRGB(60, 36, 44)
	cerrar.BorderSizePixel = 0
	cerrar.Font = Enum.Font.GothamBold
	cerrar.TextSize = 13
	cerrar.TextColor3 = Color3.fromRGB(255, 190, 190)
	cerrar.Text = "X"
	cerrar.AutoButtonColor = true
	cerrar.Modal = true -- libera el mouse si estás en primera persona / shift lock
	cerrar.Parent = titulo
	redondear(cerrar, 6)
	cerrar.MouseButton1Click:Connect(function() AbrirMenu(false) end)

	local arrastrando = false
	local desfase = Vector2.zero

	titulo.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			arrastrando = true
			desfase = Vector2.new(input.Position.X, input.Position.Y)
				- Vector2.new(main.AbsolutePosition.X, main.AbsolutePosition.Y)
		end
	end)

	table.insert(_menuConns, UserInputService.InputChanged:Connect(function(input)
		if arrastrando and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			main.Position = UDim2.fromOffset(
				math.max(0, input.Position.X - desfase.X),
				math.max(0, input.Position.Y - desfase.Y)
			)
		end
	end))

	table.insert(_menuConns, UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			arrastrando = false
		end
	end))

	local pista = Instance.new("TextLabel")
	pista.BackgroundTransparency = 1
	pista.Position = UDim2.fromOffset(12, 40)
	pista.Size = UDim2.new(1, -24, 0, 26)
	pista.Font = Enum.Font.Gotham
	pista.TextSize = 11
	pista.TextWrapped = true
	pista.TextXAlignment = Enum.TextXAlignment.Left
	pista.TextColor3 = Color3.fromRGB(150, 158, 180)
	pista.Text = "Clic en una tecla y pulsa la nueva (Esc cancela). Si repites una, se intercambian."
	pista.Parent = main

	-- Lista con scroll
	local lista = Instance.new("ScrollingFrame")
	lista.Position = UDim2.fromOffset(8, 70)
	lista.Size = UDim2.new(1, -16, 1, -70 - 46)
	lista.BackgroundTransparency = 1
	lista.BorderSizePixel = 0
	lista.ScrollBarThickness = 4
	lista.CanvasSize = UDim2.new(0, 0, 0, 0)
	lista.AutomaticCanvasSize = Enum.AutomaticSize.Y
	lista.Parent = main

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 4)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = lista

	local orden = 0

	local function nuevaFila(altura)
		orden += 1
		local f = Instance.new("Frame")
		f.Size = UDim2.new(1, -8, 0, altura)
		f.BackgroundColor3 = Color3.fromRGB(28, 32, 46)
		f.BorderSizePixel = 0
		f.LayoutOrder = orden
		f.Parent = lista
		redondear(f, 6)
		return f
	end

	local function etiqueta(padre, texto)
		local l = Instance.new("TextLabel")
		l.BackgroundTransparency = 1
		l.Position = UDim2.fromOffset(10, 0)
		l.Size = UDim2.new(0.52, 0, 1, 0)
		l.Font = Enum.Font.Gotham
		l.TextSize = 12
		l.TextColor3 = Color3.fromRGB(215, 220, 235)
		l.TextXAlignment = Enum.TextXAlignment.Left
		l.TextTruncate = Enum.TextTruncate.AtEnd
		l.Text = texto
		l.Parent = padre
		return l
	end

	local function boton(padre, texto, ancho, derecha)
		local b = Instance.new("TextButton")
		b.AnchorPoint = Vector2.new(1, 0.5)
		b.Position = UDim2.new(1, -derecha, 0.5, 0)
		b.Size = UDim2.fromOffset(ancho, 22)
		b.BackgroundColor3 = Color3.fromRGB(44, 52, 80)
		b.BorderSizePixel = 0
		b.Font = Enum.Font.GothamBold
		b.TextSize = 12
		b.TextColor3 = Color3.fromRGB(235, 240, 255)
		b.Text = texto
		b.AutoButtonColor = true
		b.Parent = padre
		redondear(b, 5)
		return b
	end

	for _, item in ipairs(SCHEMA) do
		if item.tipo == "titulo" then
			orden += 1
			local t = Instance.new("TextLabel")
			t.Size = UDim2.new(1, -8, 0, 22)
			t.BackgroundTransparency = 1
			t.LayoutOrder = orden
			t.Font = Enum.Font.GothamBold
			t.TextSize = 11
			t.TextColor3 = Color3.fromRGB(110, 160, 255)
			t.TextXAlignment = Enum.TextXAlignment.Left
			t.Text = "  " .. item.texto
			t.Parent = lista

		elseif item.tipo == "tecla" then
			local fila = nuevaFila(30)
			etiqueta(fila, item.texto)
			local b = boton(fila, _cfg[item.id].Name, 136, 8)
			b.MouseButton1Click:Connect(function() IniciarCaptura(item.id, b) end)
			table.insert(_refrescadores, function()
				if not (_capturando and _capturando.boton == b) then
					b.Text = _cfg[item.id].Name
				end
			end)

		elseif item.tipo == "num" then
			local fila = nuevaFila(30)
			etiqueta(fila, item.texto)

			local mas = boton(fila, "+", 24, 8)
			local valor = Instance.new("TextLabel")
			valor.AnchorPoint = Vector2.new(1, 0.5)
			valor.Position = UDim2.new(1, -36, 0.5, 0)
			valor.Size = UDim2.fromOffset(52, 22)
			valor.BackgroundTransparency = 1
			valor.Font = Enum.Font.GothamBold
			valor.TextSize = 12
			valor.TextColor3 = Color3.fromRGB(255, 255, 255)
			valor.Text = tostring(_cfg[item.id])
			valor.Parent = fila
			local menos = boton(fila, "-", 24, 92)

			local function cambiar(dir)
				local v = _cfg[item.id] + dir * item.paso
				v = math.floor(v / item.paso + 0.5) * item.paso
				_cfg[item.id] = math.clamp(v, item.min, item.max)
				valor.Text = tostring(_cfg[item.id])
				GuardarConRetardo()
			end

			mas.MouseButton1Click:Connect(function() cambiar(1) end)
			menos.MouseButton1Click:Connect(function() cambiar(-1) end)
			table.insert(_refrescadores, function() valor.Text = tostring(_cfg[item.id]) end)

		elseif item.tipo == "bool" then
			local fila = nuevaFila(30)
			etiqueta(fila, item.texto)
			local b = boton(fila, "", 60, 8)

			local function pintar()
				b.Text = _cfg[item.id] and "ON" or "OFF"
				b.BackgroundColor3 = _cfg[item.id] and Color3.fromRGB(46, 120, 76) or Color3.fromRGB(80, 50, 56)
			end

			pintar()
			b.MouseButton1Click:Connect(function()
				_cfg[item.id] = not _cfg[item.id]
				pintar()
				GuardarConRetardo()
			end)
			table.insert(_refrescadores, pintar)
		end
	end

	-- Pie: estado de guardado + restablecer
	local pie = Instance.new("Frame")
	pie.Position = UDim2.new(0, 8, 1, -40)
	pie.Size = UDim2.new(1, -16, 0, 32)
	pie.BackgroundTransparency = 1
	pie.Parent = main

	local estado = Instance.new("TextLabel")
	estado.BackgroundTransparency = 1
	estado.Size = UDim2.new(1, -110, 1, 0)
	estado.Font = Enum.Font.Gotham
	estado.TextSize = 10
	estado.TextWrapped = true
	estado.TextXAlignment = Enum.TextXAlignment.Left
	estado.Parent = pie
	_estadoLabel = estado

	local reset = Instance.new("TextButton")
	reset.AnchorPoint = Vector2.new(1, 0.5)
	reset.Position = UDim2.new(1, 0, 0.5, 0)
	reset.Size = UDim2.fromOffset(100, 26)
	reset.BackgroundColor3 = Color3.fromRGB(70, 44, 52)
	reset.BorderSizePixel = 0
	reset.Font = Enum.Font.GothamBold
	reset.TextSize = 11
	reset.TextColor3 = Color3.fromRGB(255, 205, 205)
	reset.Text = "Restablecer"
	reset.Parent = pie
	redondear(reset, 6)

	reset.MouseButton1Click:Connect(function()
		CancelarCaptura()
		for _, item in ipairs(SCHEMA) do
			if item.id then _cfg[item.id] = item.def end
		end
		SincronizarHub()
		RefrescarMenu()
		GuardarConRetardo()
	end)

	ActualizarEstadoMenu()
end

-- ==========================================
-- BUCLE PRINCIPAL (antes de cada paso de física)
-- ==========================================
local function Actualizar(dt)
	if not _isActive
		or isSlamming
		or not humanoid
		or not rootPart
		or not humanoid.Parent then
		return
	end

	if humanoid.Health <= 0 then return end

	dt = math.min(dt or 0.016, 0.1)

	-- MODO PLATAFORMA (caminar en el aire)
	if isPlatformMode and plataformaActiva then
		GravedadNormal()
		ActualizarPlataforma(dt)

		if not isHoldingFly then
			holdTimer = 0
		end

		return
	end

	-- Plataforma pedida pero destruida desde fuera: se limpia el estado
	if isPlatformMode and not plataformaActiva then
		isPlatformMode = false
	end

	local state = humanoid:GetState()

	local inAir = (
		state == Enum.HumanoidStateType.Jumping
		or state == Enum.HumanoidStateType.Freefall
	)

	-- MODO FLOTAR
	-- El suelo SÍ desactiva el vuelo.
	if not inAir then
		if isFloating then
			isFloating = false
			DetenerAnimacionesCustom(0.3)
		end

		GravedadNormal()

		if not isHoldingFly then
			holdTimer = 0
		end
	end

	if isHoldingFly then
		if not isFloating then
			holdTimer += dt

			local tiempoRequerido = 0.5

			if tick() - lastDamageTime <= 3 then
				tiempoRequerido = 0.15
			elseif tick() - lastSlamEndTime <= 1.5 then
				tiempoRequerido = 0.3
			end

			if holdTimer > tiempoRequerido then
				isFloating = true

				if tick() - lastDamageTime <= 3 then
					if animDespertar then
						animDespertar:Play(0.1)
					end

					task.delay(0.73, function()
						if _isActive
							and isFloating
							and animDespertar
							and animDespertar.IsPlaying then

							animDespertar:Stop(0.3)

							if animVuelo then
								animVuelo:Play(0.3)
							end
						end
					end)
				else
					if animVuelo then
						animVuelo:Play(0.3)
					end
				end

				humanoid:ChangeState(Enum.HumanoidStateType.Freefall)

				local moveDir = humanoid.MoveDirection

				rootPart.AssemblyLinearVelocity = Vector3.new(
					moveDir.X * _cfg.impulsoXZ,
					_cfg.impulsoY,
					moveDir.Z * _cfg.impulsoXZ
				)
			end
		end
	else
		if not isFloating then
			holdTimer = 0
		end
	end

	if isFloating then
		GravedadCero()

		local moveDir = humanoid.MoveDirection
		local velActual = rootPart.AssemblyLinearVelocity
		local velY = velActual.Y

		if isHoldingFly then
			if velY < -2 then
				velY = -2
			end
		else
			velY -= ACELERACION_CAIDA * dt * 60

			if velY < _cfg.caidaLenta then
				velY = _cfg.caidaLenta
			end
		end

		local targetVelXZ

		if moveDir.Magnitude > 0 then
			targetVelXZ = moveDir * _cfg.velocidad
		else
			targetVelXZ = Vector3.new(
				velActual.X * 0.9,
				0,
				velActual.Z * 0.9
			)
		end

		rootPart.AssemblyLinearVelocity = Vector3.new(
			targetVelXZ.X,
			velY,
			targetVelXZ.Z
		)
	end
end

-- ==========================================
-- API
-- ==========================================
function M.Start(Keys)
	if type(Keys) == "table" then
		_hubKeys = Keys
	end

	if _isActive then return end
	_isActive = true

	RecordarGravedad()

	-- Si un reinicio anterior dejó la gravedad en 0, se repone
	if workspace.Gravity < 1 and genv and genv.AFO_GRAV_ZEROED then
		GravedadNormal()
	end

	-- Prioridad de la tecla de plataforma: archivo guardado > hub > por defecto
	local cargadas = Cargar()
	if _hubKeys and typeof(_hubKeys.Platform) == "EnumItem" and not cargadas.Platform then
		_cfg.Platform = _hubKeys.Platform
	end
	SincronizarHub()

	table.clear(_conns)

	isHoldingFly = false
	isPlatformMode = false
	isFloating = false
	isSlamming = false

	pcall(CrearMenu)

	if player.Character then
		SetupCharacter(player.Character)
	end

	local charAddedConn = player.CharacterAdded:Connect(function(newChar)
		if _isActive then
			SetupCharacter(newChar)
		end
	end)

	table.insert(_conns, charAddedConn)

	local inputBeganConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		-- Mientras se asigna una tecla (o justo después) no se ejecuta ninguna acción
		if _capturando or os.clock() - _ultimaCaptura < 0.2 then return end
		if gameProcessed then return end

		if Coincide(input, _cfg.Menu) then
			AbrirMenu()
			return
		end

		if not humanoid or not rootPart then return end

		if Coincide(input, _cfg.Fly) then
			isHoldingFly = true

			if isFloating or isPlatformMode then
				if plataformaActiva then
					DestruirPlataforma()
				end

				if animReSalto then
					animReSalto:Play(0.1)
					animReSalto:AdjustSpeed(2)
				end

				local velActual = rootPart.AssemblyLinearVelocity

				rootPart.AssemblyLinearVelocity = Vector3.new(
					velActual.X,
					_cfg.impulsoY,
					velActual.Z
				)

				isFloating = true
			end

		elseif Coincide(input, _cfg.Platform) then
			isPlatformMode = not isPlatformMode

			if isPlatformMode then
				CrearPlataforma()
			else
				-- No activa ni desactiva el vuelo: conserva el estado previo.
				DestruirPlataforma()
			end

		elseif Coincide(input, _cfg.Slam, true) then
			AplastarContraElSuelo()
		end
	end)

	table.insert(_conns, inputBeganConn)

	local inputEndedConn = UserInputService.InputEnded:Connect(function(input)
		if Coincide(input, _cfg.Fly) then
			isHoldingFly = false
		end
	end)

	table.insert(_conns, inputEndedConn)

	-- Antes de cada paso de física: el piso y la velocidad se fijan ANTES de simular,
	-- así el personaje nunca va un frame por delante de su plataforma.
	local okEv, evento = pcall(function() return RunService.PreSimulation end)
	if not okEv or not evento then
		evento = RunService.Stepped
	end

	local loopConn = evento:Connect(function(a, b)
		local dt = (type(b) == "number") and b or a
		Actualizar(dt)
	end)

	table.insert(_conns, loopConn)
end

function M.Stop()
	if not _isActive then return end
	_isActive = false

	for _, c in ipairs(_conns) do
		if c.Disconnect then
			c:Disconnect()
		end
	end

	table.clear(_conns)

	DestruirPlataforma()
	DetenerAnimacionesCustom(0)
	DestruirMenu()

	GravedadNormal()

	isHoldingFly = false
	isPlatformMode = false
	isFloating = false
	isSlamming = false
	holdTimer = 0

	if rootPart and character and character.Parent then
		local velActual = rootPart.AssemblyLinearVelocity

		rootPart.AssemblyLinearVelocity = Vector3.new(
			velActual.X,
			math.min(velActual.Y, 0),
			velActual.Z
		)
	end
end

-- Compatible con el hub:  SetKey(kc)  -> tecla de plataforma
-- Nuevo:                  SetKey("Slam", kc) / SetKey("Fly", kc) / SetKey("Menu", kc)
function M.SetKey(a, b)
	local id, kc

	if b ~= nil then
		id, kc = a, b
	else
		id, kc = "Platform", a
	end

	if type(id) ~= "string" or typeof(kc) ~= "EnumItem" then return end
	if typeof(_cfg[id]) ~= "EnumItem" then return end

	AsignarTecla(id, kc)

	if id == "Platform" then
		isPlatformMode = false
		DestruirPlataforma()
	end
end

function M.GetKeys()
	local t = {}
	for _, item in ipairs(SCHEMA) do
		if item.tipo == "tecla" then
			t[item.id] = _cfg[item.id]
		end
	end
	return t
end

function M.GetConfig()
	local t = {}
	for k, v in pairs(_cfg) do t[k] = v end
	return t
end

function M.OpenMenu()   AbrirMenu(true)  end
function M.CloseMenu()  AbrirMenu(false) end
function M.ToggleMenu() AbrirMenu()      end
function M.SaveConfig() local ok = GuardarAhora(); ActualizarEstadoMenu(); return ok end

function M.IsActive()
	return _isActive
end

-- Si el script se carga otra vez, se desmonta la instancia anterior (si no, quedaban
-- dos módulos escuchando teclas y gravedad a la vez).
if genv then
	local previa = rawget(genv, "AFO_GRAVATTACK_API")
	if type(previa) == "table" and previa ~= M and type(previa.Stop) == "function" then
		pcall(previa.Stop)
	end
	genv.AFO_GRAVATTACK_API = M
end

return M
