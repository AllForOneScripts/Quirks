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
-- v2: la tecla del menú pasó a F6. Los archivos v1 guardaban otra (RightShift) y la pisaban.
local VERSION_CONFIG = 2

local SCHEMA = {
	{ tipo = "titulo", texto = "TECLAS" },
	{ tipo = "tecla", id = "Fly",      texto = "Volar (mantener)",         def = Enum.KeyCode.Space },
	{ tipo = "tecla", id = "Platform", texto = "Caminar en el aire",       def = Enum.KeyCode.C },
	{ tipo = "tecla", id = "Slam",     texto = "Slam / ZAAASH",            def = Enum.KeyCode.LeftControl },
	{ tipo = "tecla", id = "Menu",     texto = "Abrir / cerrar este menú", def = Enum.KeyCode.F6 },

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
local _hubKeys = nil   -- tabla Keys del hub (se reflejan Platform y GravattackMenu)

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

	local data = { _v = VERSION_CONFIG }
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

	local version = (type(data._v) == "number") and data._v or 1

	for _, item in ipairs(SCHEMA) do
		local v = item.id and data[item.id]
		if item.id == "Menu" and version < 2 then v = nil end -- tecla de menú antigua: se descarta
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
		_hubKeys.GravattackMenu = _cfg.Menu
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
-- MENÚ DE AJUSTES  (GUI centrada · estilo Operation Phoenix)
-- ==========================================
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local _menuGui = nil            -- ScreenGui vivo (nil = menú cerrado)
local _menuUI = nil             -- referencias del menú abierto (se usan al animar el cierre)
local _estadoLabel = nil
local _menuConns = {}
local _refrescadores = {}
local _capturando = nil
local _ultimaCaptura = -10      -- os.clock() de la última captura de tecla (-10 = ninguna)
local _menuEstado = "cerrado"   -- cerrado | abriendo | abierto | cerrando
local _menuPendiente = nil      -- "abrir" | "cerrar": se pidió algo mientras animaba
local _menuToken = 0            -- invalida animaciones/tareas de un menú que ya se destruyó

local DestruirMenu, ConstruirMenu, CerrarMenuAnimado, AbrirMenu

-- ------------------------------------------
-- Primitivas neón (mismo lenguaje visual que Operation Phoenix)
-- ------------------------------------------
local UI = {}

do
	local C = {
		NEGRO = Color3.fromRGB(10, 6, 18),
		MORADO = Color3.fromRGB(155, 48, 255),
		MORADO_BRILLO = Color3.fromRGB(200, 100, 255),
		MORADO_OSC = Color3.fromRGB(52, 18, 92),
		VERDE = Color3.fromRGB(0, 255, 120),
		VERDE_OSC = Color3.fromRGB(4, 62, 34),
		ROJO = Color3.fromRGB(255, 45, 110),
		ROJO_OSC = Color3.fromRGB(74, 8, 30),
		CIAN = Color3.fromRGB(70, 230, 255),   -- solo para el glitch
		TEXTO = Color3.fromRGB(240, 235, 255),
		FANTASMA = Color3.fromRGB(150, 125, 200),
		AMBAR = Color3.fromRGB(255, 190, 90),
	}

	local FONT_TITLE = Enum.Font.Michroma
	local FONT_MONO = Enum.Font.Code
	local GLYPHS = "ABCDEFGHJKLMNPQRSTUVWXYZ0123456789#%&/<>"
	local BG_REST = Color3.fromRGB(190, 190, 190)

	UI.C = C
	UI.FONT_TITLE = FONT_TITLE
	UI.FONT_MONO = FONT_MONO
	UI.GUI_NAME = "GravattackMenu"
	UI.MOUSE_BIND = "GravattackMenuMouse"

	-- Contenedor transparente a tamaño completo
	local function makeGroup(parent, z)
		local g = Instance.new("Frame")
		g.Size = UDim2.fromScale(1, 1)
		g.BackgroundTransparency = 1
		g.BorderSizePixel = 0
		g.ZIndex = z
		g.Parent = parent
		return g
	end
	UI.makeGroup = makeGroup

	-- Segmento neón entre dos puntos (núcleo brillante + 2 halos)
	local function neonSeg(parent, x1, y1, x2, y2, color, thick, z, bag)
		local dx, dy = x2 - x1, y2 - y1
		local len = math.sqrt(dx * dx + dy * dy)
		local ang = math.deg(math.atan2(dy, dx))
		local cx, cy = (x1 + x2) / 2, (y1 + y2) / 2

		local function make(t, transp, zi, round)
			local f = Instance.new("Frame")
			f.AnchorPoint = Vector2.new(0.5, 0.5)
			f.Position = UDim2.fromOffset(cx, cy)
			f.Size = UDim2.fromOffset(len + (round and t * 0.5 or 0), t)
			f.Rotation = ang
			f.BackgroundColor3 = color
			f.BackgroundTransparency = transp
			f.BorderSizePixel = 0
			f.ZIndex = zi
			if round then
				local u = Instance.new("UICorner")
				u.CornerRadius = UDim.new(0.5, 0)
				u.Parent = f
			end
			f.Parent = parent
			return f
		end

		make(thick * 5, 0.9, z, true)
		make(thick * 2.6, 0.75, z, true)
		local core = make(thick, 0, z + 1, false)
		if bag then table.insert(bag, core) end
		return core
	end
	UI.neonSeg = neonSeg

	-- Nodo en forma de rombo (terminal de circuito)
	local function neonDot(parent, x, y, color, z)
		local function make(size, transp, zi)
			local f = Instance.new("Frame")
			f.AnchorPoint = Vector2.new(0.5, 0.5)
			f.Position = UDim2.fromOffset(x, y)
			f.Size = UDim2.fromOffset(size, size)
			f.Rotation = 45
			f.BackgroundColor3 = color
			f.BackgroundTransparency = transp
			f.BorderSizePixel = 0
			f.ZIndex = zi
			f.Parent = parent
		end
		make(12, 0.8, z)
		make(5, 0, z + 1)
	end
	UI.neonDot = neonDot

	-- Línea horizontal que se desvanece en los extremos. Devuelve (halo, núcleo).
	local function fadeLine(parent, x, y, w, color, thick, z)
		local function make(t, peak, zi)
			local f = Instance.new("Frame")
			f.Position = UDim2.fromOffset(x, y - t / 2)
			f.Size = UDim2.fromOffset(w, t)
			f.BackgroundColor3 = color
			f.BackgroundTransparency = 0
			f.BorderSizePixel = 0
			f.ZIndex = zi
			local g = Instance.new("UIGradient")
			g.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.2, peak),
				NumberSequenceKeypoint.new(0.8, peak),
				NumberSequenceKeypoint.new(1, 1),
			})
			g.Parent = f
			f.Parent = parent
			return f
		end
		local glow = make(thick * 4, 0.82, z)
		local core = make(thick, 0, z + 1)
		return glow, core
	end
	UI.fadeLine = fadeLine

	-- Chevron « o » (dir = -1 apunta a la izquierda, 1 a la derecha)
	local function chevron(parent, tipX, cy, s, dir, color, z)
		local ex = tipX - dir * s
		neonSeg(parent, tipX, cy, ex, cy - s, color, 1.6, z)
		neonSeg(parent, tipX, cy, ex, cy + s, color, 1.6, z)
	end

	-- Cristal oscuro: translúcido en el centro y se disuelve hacia los lados
	function UI.crystalPlate(parent, z)
		local plate = Instance.new("Frame")
		plate.Size = UDim2.fromScale(1, 1)
		plate.BackgroundColor3 = Color3.new(1, 1, 1)
		plate.BorderSizePixel = 0
		plate.ZIndex = z
		plate.Parent = parent
		local grad = Instance.new("UIGradient")
		grad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(34, 14, 58)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(12, 6, 24)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(34, 14, 58)),
		})
		grad.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.1, 0.78),
			NumberSequenceKeypoint.new(0.5, 0.5),
			NumberSequenceKeypoint.new(0.9, 0.78),
			NumberSequenceKeypoint.new(1, 1),
		})
		grad.Parent = plate
		return plate
	end

	-- Parpadeo digital al aparecer / desaparecer un objeto
	function UI.flickerIn(obj, delay)
		task.spawn(function()
			task.wait(delay or 0)
			for _, v in ipairs({ true, false, true, false, true }) do
				if not obj.Parent then return end
				obj.Visible = v
				task.wait(0.045)
			end
		end)
	end

	function UI.flickerOut(obj, delay)
		task.spawn(function()
			task.wait(delay or 0)
			for _, v in ipairs({ false, true, false, true, false }) do
				if not obj.Parent then return end
				obj.Visible = v
				task.wait(0.045)
			end
		end)
	end

	-- Texto que se "decodifica" desde caracteres aleatorios (o se corrompe si reverse = true)
	function UI.scramble(label, finalText, duration, reverse)
		local steps = 14
		for i = 0, steps do
			if not label.Parent then return end
			local reveal = reverse and (1 - i / steps) or (i / steps)
			local n = math.floor(#finalText * reveal)
			local out = {}
			for k = 1, #finalText do
				local ch = finalText:sub(k, k)
				if ch == " " or k <= n then
					out[k] = ch
				else
					local r = math.random(1, #GLYPHS)
					out[k] = GLYPHS:sub(r, r)
				end
			end
			label.Text = table.concat(out)
			task.wait(duration / steps)
		end
		if not reverse and label.Parent then label.Text = finalText end
	end

	-- Botón neón: hover, brillo que cruza, rebote y flash al click.
	-- Devuelve un objeto { holder, btn, setText(t), setColor(c) }.
	-- o.font / o.size = tipografía; o.chevrons = true dibuja los chevrones laterales.
	function UI.neonButton(parent, anchor, pos, w, h, label, color, dimColor, onClick, o)
		o = o or {}

		local slot = Instance.new("Frame")
		slot.AnchorPoint = anchor
		slot.Position = pos
		slot.Size = UDim2.fromOffset(w, h)
		slot.BackgroundTransparency = 1
		slot.BorderSizePixel = 0
		slot.ZIndex = 5
		slot.Parent = parent

		local holder = Instance.new("Frame")
		holder.AnchorPoint = Vector2.new(0.5, 0.5)
		holder.Position = UDim2.fromScale(0.5, 0.5)
		holder.Size = UDim2.fromOffset(w, h)
		holder.BackgroundTransparency = 1
		holder.BorderSizePixel = 0
		holder.ZIndex = 5
		holder.Parent = slot

		local scale = Instance.new("UIScale")
		scale.Parent = holder

		local bg = Instance.new("Frame")
		bg.Size = UDim2.fromScale(1, 1)
		bg.BackgroundColor3 = BG_REST
		bg.BackgroundTransparency = 0
		bg.BorderSizePixel = 0
		bg.ZIndex = 5
		bg.Parent = holder
		local grad = Instance.new("UIGradient")
		grad.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.82),
			NumberSequenceKeypoint.new(0.5, 0.55),
			NumberSequenceKeypoint.new(1, 0.82),
		})
		grad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, dimColor),
			ColorSequenceKeypoint.new(0.5, C.NEGRO),
			ColorSequenceKeypoint.new(1, dimColor),
		})
		grad.Parent = bg

		fadeLine(holder, 0, 1, w, color, 1.4, 6)
		fadeLine(holder, 0, h - 1, w, color, 1.4, 6)

		local hoverL, hoverR
		if o.chevrons then
			hoverL, hoverR = makeGroup(holder, 7), makeGroup(holder, 7)
			local s = math.floor(h * 0.2)
			local cy = h / 2
			for i = 0, 1 do
				chevron(hoverL, 10 + i * 9, cy, s, -1, color, 7)
				chevron(hoverR, w - 10 - i * 9, cy, s, 1, color, 7)
			end
		end

		-- Capa recortada para brillo y flash
		local clip = Instance.new("Frame")
		clip.Size = UDim2.fromScale(1, 1)
		clip.BackgroundTransparency = 1
		clip.ClipsDescendants = true
		clip.ZIndex = 9
		clip.Parent = holder

		local btn = Instance.new("TextButton")
		btn.Size = UDim2.fromScale(1, 1)
		btn.BackgroundTransparency = 1
		btn.AutoButtonColor = false
		btn.Font = o.font or FONT_TITLE
		btn.Text = label
		btn.TextColor3 = color
		btn.TextSize = o.size or 11
		btn.ZIndex = 20
		btn.Parent = holder

		local textGlow = Instance.new("UIStroke")
		textGlow.Color = color
		textGlow.Thickness = 1.4
		textGlow.Transparency = 0.72
		textGlow.Parent = btn

		local hovered = false
		local bright = color:Lerp(Color3.new(1, 1, 1), 0.4)
		local tint = color:Lerp(Color3.new(1, 1, 1), 0.5)

		local function shine()
			local bar = Instance.new("Frame")
			bar.Size = UDim2.new(0, 22, 1, 0)
			bar.Position = UDim2.new(0, -30, 0, 0)
			bar.BackgroundColor3 = tint
			bar.BorderSizePixel = 0
			bar.ZIndex = 9
			local g = Instance.new("UIGradient")
			g.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.5, 0.55),
				NumberSequenceKeypoint.new(1, 1),
			})
			g.Parent = bar
			bar.Parent = clip
			TweenService:Create(bar, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ Position = UDim2.new(0, w + 10, 0, 0) }):Play()
			Debris:AddItem(bar, 0.45)
		end

		local function flash()
			local f = Instance.new("Frame")
			f.Size = UDim2.fromScale(1, 1)
			f.BackgroundColor3 = tint
			f.BackgroundTransparency = 0.2
			f.BorderSizePixel = 0
			f.ZIndex = 9
			f.Parent = clip
			TweenService:Create(f, TweenInfo.new(0.35), { BackgroundTransparency = 1 }):Play()
			Debris:AddItem(f, 0.4)
		end

		local function setScale(v, t, style, dir)
			TweenService:Create(scale, TweenInfo.new(t, style, dir), { Scale = v }):Play()
		end

		local function setChevronShift(x, t, style)
			if not hoverL then return end
			local info = TweenInfo.new(t, style, Enum.EasingDirection.Out)
			TweenService:Create(hoverL, info, { Position = UDim2.fromOffset(x, 0) }):Play()
			TweenService:Create(hoverR, info, { Position = UDim2.fromOffset(-x, 0) }):Play()
		end

		btn.MouseEnter:Connect(function()
			hovered = true
			TweenService:Create(bg, TweenInfo.new(0.2), { BackgroundColor3 = Color3.new(1, 1, 1) }):Play()
			TweenService:Create(textGlow, TweenInfo.new(0.2), { Transparency = 0.3 }):Play()
			TweenService:Create(btn, TweenInfo.new(0.2), { TextColor3 = bright }):Play()
			setScale(1.06, 0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
			setChevronShift(5, 0.25, Enum.EasingStyle.Back)
			shine()
		end)
		btn.MouseLeave:Connect(function()
			hovered = false
			TweenService:Create(bg, TweenInfo.new(0.2), { BackgroundColor3 = BG_REST }):Play()
			TweenService:Create(textGlow, TweenInfo.new(0.2), { Transparency = 0.72 }):Play()
			TweenService:Create(btn, TweenInfo.new(0.2), { TextColor3 = color }):Play()
			setScale(1, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			setChevronShift(0, 0.2, Enum.EasingStyle.Quad)
		end)
		btn.MouseButton1Down:Connect(function()
			setScale(0.93, 0.07, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			setChevronShift(9, 0.07, Enum.EasingStyle.Quad)
			TweenService:Create(textGlow, TweenInfo.new(0.07), { Transparency = 0.05 }):Play()
		end)
		btn.MouseButton1Up:Connect(function()
			setScale(hovered and 1.06 or 1, 0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
			setChevronShift(hovered and 5 or 0, 0.25, Enum.EasingStyle.Back)
		end)
		btn.MouseButton1Click:Connect(function()
			flash()
			onClick()
		end)

		local obj = { holder = slot, btn = btn }

		function obj.setText(t)
			btn.Text = t
		end

		function obj.setColor(c)
			color = c
			bright = c:Lerp(Color3.new(1, 1, 1), 0.4)
			tint = c:Lerp(Color3.new(1, 1, 1), 0.5)
			btn.TextColor3 = hovered and bright or c
			textGlow.Color = c
		end

		return obj
	end

	-- Coloca la GUI donde se pueda: gethui > CoreGui > PlayerGui
	function UI.montarGui(gui)
		if type(gethui) == "function" then
			local ok, h = pcall(gethui)
			if ok and h then
				local ok2 = pcall(function() gui.Parent = h end)
				if ok2 and gui.Parent then return true end
			end
		end

		local ok3 = pcall(function() gui.Parent = game:GetService("CoreGui") end)
		if ok3 and gui.Parent then return true end

		local pg = player:FindFirstChildOfClass("PlayerGui") or player:WaitForChild("PlayerGui", 5)
		if pg then
			gui.Parent = pg
			return gui.Parent ~= nil
		end

		return false
	end

	-- Borra copias huérfanas (de una carga anterior del script) en todos los sitios posibles
	function UI.limpiarHuerfanos()
		local raices = {}

		if type(gethui) == "function" then
			local ok, h = pcall(gethui)
			if ok and h then table.insert(raices, h) end
		end

		pcall(function() table.insert(raices, game:GetService("CoreGui")) end)

		local pg = player:FindFirstChildOfClass("PlayerGui")
		if pg then table.insert(raices, pg) end

		for _, raiz in ipairs(raices) do
			pcall(function()
				for _, hijo in ipairs(raiz:GetChildren()) do
					if hijo.Name == UI.GUI_NAME then hijo:Destroy() end
				end
			end)
		end
	end
end

-- ------------------------------------------
-- Lógica del menú (teclas, captura, estado)
-- ------------------------------------------
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

	pcall(function()
		c.b.setText(_cfg[c.id].Name)
		c.b.setColor(UI.C.MORADO_BRILLO)
	end)

	ActualizarEstadoMenu()
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

local function IniciarCaptura(id, b)
	CancelarCaptura()

	b.setText("PULSA UNA TECLA")
	b.setColor(UI.C.VERDE)

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

	_capturando = { id = id, b = b, conn = conn }
	ActualizarEstadoMenu()
end

ActualizarEstadoMenu = function()
	if not _estadoLabel or not _estadoLabel.Parent then return end

	if _capturando then
		_estadoLabel.Text = "PULSA LA NUEVA TECLA  //  ESC CANCELA"
		_estadoLabel.TextColor3 = UI.C.VERDE
	elseif _guardadoOk == true then
		_estadoLabel.Text = "Guardado en " .. ARCHIVO_CONFIG
		_estadoLabel.TextColor3 = UI.C.VERDE
	elseif _guardadoOk == false then
		_estadoLabel.Text = "No se pudo guardar (el ejecutor no tiene writefile)"
		_estadoLabel.TextColor3 = UI.C.AMBAR
	else
		_estadoLabel.Text = "Los cambios se guardan solos"
		_estadoLabel.TextColor3 = UI.C.FANTASMA
	end
end

DestruirMenu = function()
	_menuToken += 1

	CancelarCaptura()

	for _, c in ipairs(_menuConns) do
		pcall(function() c:Disconnect() end)
	end
	table.clear(_menuConns)
	table.clear(_refrescadores)

	if _menuGui then
		pcall(function() _menuGui:Destroy() end)
	end

	_menuGui, _menuUI, _estadoLabel = nil, nil, nil
	_menuEstado = "cerrado"
	_menuPendiente = nil

	UI.limpiarHuerfanos()
end

-- ------------------------------------------
-- Construcción de la GUI
-- ------------------------------------------
ConstruirMenu = function()
	DestruirMenu()

	local token = _menuToken
	_menuEstado = "abriendo"

	local C = UI.C
	local FONT_TITLE, FONT_MONO = UI.FONT_TITLE, UI.FONT_MONO

	local W, H = 420, 540
	local LISTA_Y, PIE_H = 72, 62
	local TITULO = "GRAVATTACK"
	local TITULO_POS = UDim2.fromOffset(20, 14)

	local gui = Instance.new("ScreenGui")
	gui.Name = UI.GUI_NAME
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true           -- centro real de la pantalla
	gui.DisplayOrder = 1000
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	if not UI.montarGui(gui) then
		gui:Destroy()
		error("no hay dónde colocar la GUI (gethui / CoreGui / PlayerGui)")
	end

	_menuGui = gui

	local function vivo()
		return token == _menuToken and gui.Parent ~= nil
	end

	-- Mientras el menú está abierto, el cursor queda libre (primera persona / shift lock)
	local iconoPrevio = UserInputService.MouseIconEnabled
	pcall(function()
		RunService:BindToRenderStep(UI.MOUSE_BIND, Enum.RenderPriority.Last.Value, function()
			if UserInputService.MouseBehavior ~= Enum.MouseBehavior.Default then
				UserInputService.MouseBehavior = Enum.MouseBehavior.Default
			end
			if not UserInputService.MouseIconEnabled then
				UserInputService.MouseIconEnabled = true
			end
		end)
	end)
	table.insert(_menuConns, {
		Disconnect = function()
			pcall(function() RunService:UnbindFromRenderStep(UI.MOUSE_BIND) end)
			pcall(function() UserInputService.MouseIconEnabled = iconoPrevio end)
		end,
	})

	-- "clipper": revela el panel con un barrido de línea (centrado en pantalla)
	local clipper = Instance.new("Frame")
	clipper.Name = "MainFrame"
	clipper.AnchorPoint = Vector2.new(0.5, 0.5)
	clipper.Position = UDim2.fromScale(0.5, 0.5)
	clipper.Size = UDim2.fromOffset(0, 2)
	clipper.BackgroundTransparency = 1
	clipper.BorderSizePixel = 0
	clipper.ClipsDescendants = true
	clipper.ZIndex = 2
	clipper.Parent = gui

	-- Si la pantalla es pequeña, el panel se reduce para caber
	local escala = Instance.new("UIScale")
	escala.Parent = clipper

	local function ajustarEscala()
		local cam = workspace.CurrentCamera
		local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
		escala.Scale = math.clamp(math.min((vp.X - 24) / W, (vp.Y - 24) / H), 0.4, 1)
	end
	ajustarEscala()

	if workspace.CurrentCamera then
		table.insert(_menuConns, workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(ajustarEscala))
	end

	-- "content": tamaño fijo, centrado; todo el diseño vive aquí
	local content = Instance.new("Frame")
	content.Name = "Content"
	content.AnchorPoint = Vector2.new(0.5, 0.5)
	content.Position = UDim2.fromScale(0.5, 0.5)
	content.Size = UDim2.fromOffset(W, H)
	content.BackgroundTransparency = 1
	content.BorderSizePixel = 0
	content.ZIndex = 2
	content.Parent = clipper

	-- Línea de escaneo (aparece/desaparece con el panel)
	local scanGlow = Instance.new("Frame")
	scanGlow.AnchorPoint = Vector2.new(0.5, 0.5)
	scanGlow.Position = UDim2.fromScale(0.5, 0.5)
	scanGlow.Size = UDim2.new(1, 0, 0, 7)
	scanGlow.BackgroundColor3 = C.MORADO_BRILLO
	scanGlow.BackgroundTransparency = 0.6
	scanGlow.BorderSizePixel = 0
	scanGlow.ZIndex = 29
	scanGlow.Parent = clipper

	local scanCore = Instance.new("Frame")
	scanCore.AnchorPoint = Vector2.new(0.5, 0.5)
	scanCore.Position = UDim2.fromScale(0.5, 0.5)
	scanCore.Size = UDim2.new(1, 0, 0, 2)
	scanCore.BackgroundColor3 = Color3.fromRGB(245, 235, 255)
	scanCore.BackgroundTransparency = 0
	scanCore.BorderSizePixel = 0
	scanCore.ZIndex = 30
	scanCore.Parent = clipper

	-- Cristal oscuro
	local plate = UI.crystalPlate(content, 2)
	plate.Name = "Plate"

	-- Barrido de luz periódico
	local sweep = Instance.new("Frame")
	sweep.Name = "Sweep"
	sweep.Size = UDim2.fromOffset(40, H - 16)
	sweep.Position = UDim2.fromOffset(20, 8)
	sweep.BackgroundColor3 = C.MORADO_BRILLO
	sweep.BackgroundTransparency = 1
	sweep.BorderSizePixel = 0
	sweep.ZIndex = 2
	sweep.Parent = content
	local sweepGrad = Instance.new("UIGradient")
	sweepGrad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, 0.82),
		NumberSequenceKeypoint.new(1, 1),
	})
	sweepGrad.Parent = sweep

	-- Marco geométrico: trazos con escalón y diagonales, simétrico por punto (180°)
	local pulseBag = {}
	local function drawPath(pts, flipped, withDot)
		local p = {}
		for i, v in ipairs(pts) do
			p[i] = flipped and { W - v[1], H - v[2] } or { v[1], v[2] }
		end
		for i = 1, #p - 1 do
			UI.neonSeg(content, p[i][1], p[i][2], p[i + 1][1], p[i + 1][2], C.MORADO, 1.8, 3, pulseBag)
		end
		if withDot then
			UI.neonDot(content, p[#p][1], p[#p][2], C.MORADO_BRILLO, 3)
		end
	end

	local pathA = { { 6, 30 }, { 6, 14 }, { 18, 2 }, { 100, 2 } }
	local slash1 = { { 105, 10 }, { 113, 2 } }
	local slash2 = { { 113, 10 }, { 121, 2 } }
	local pathB = { { W - 6, 30 }, { W - 6, 14 }, { W - 18, 2 }, { W - 80, 2 }, { W - 88, 10 }, { W - 140, 10 } }

	for _, flipped in ipairs({ false, true }) do
		drawPath(pathA, flipped, true)
		drawPath(slash1, flipped, false)
		drawPath(slash2, flipped, false)
		drawPath(pathB, flipped, true)
	end

	-- Título + subtítulo (muestra la tecla actual del menú)
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, -40, 0, 24)
	titleLabel.Position = TITULO_POS
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = FONT_TITLE
	titleLabel.Text = ""
	titleLabel.TextColor3 = C.TEXTO
	titleLabel.TextSize = 18
	titleLabel.TextXAlignment = Enum.TextXAlignment.Center
	titleLabel.ZIndex = 10
	titleLabel.Parent = content

	local titleGlow = Instance.new("UIStroke")
	titleGlow.Color = C.MORADO
	titleGlow.Thickness = 2
	titleGlow.Transparency = 0.5
	titleGlow.Parent = titleLabel

	local subtitulo = Instance.new("TextLabel")
	subtitulo.Size = UDim2.new(1, -40, 0, 14)
	subtitulo.Position = UDim2.fromOffset(20, 42)
	subtitulo.BackgroundTransparency = 1
	subtitulo.Font = FONT_MONO
	subtitulo.TextSize = 11
	subtitulo.TextColor3 = C.FANTASMA
	subtitulo.TextXAlignment = Enum.TextXAlignment.Center
	subtitulo.ZIndex = 10
	subtitulo.Parent = content

	local function pintarSubtitulo()
		subtitulo.Text = "AJUSTES  //  [" .. string.upper(_cfg.Menu.Name) .. "] ABRE / CIERRA"
	end
	pintarSubtitulo()
	table.insert(_refrescadores, pintarSubtitulo)

	UI.fadeLine(content, 20, 64, W - 40, C.MORADO, 1.2, 4)

	-- Asa de arrastre (la barra del título mueve el panel)
	local asa = Instance.new("TextButton")
	asa.Name = "Asa"
	asa.Size = UDim2.fromOffset(W - 70, 62)
	asa.Position = UDim2.fromOffset(0, 0)
	asa.BackgroundTransparency = 1
	asa.AutoButtonColor = false
	asa.Text = ""
	asa.ZIndex = 8
	asa.Parent = content

	local arrastrando = false
	local inicioArrastre = Vector3.new(0, 0, 0)
	local posInicial = clipper.Position

	asa.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			arrastrando = true
			inicioArrastre = input.Position
			posInicial = clipper.Position
		end
	end)

	table.insert(_menuConns, UserInputService.InputChanged:Connect(function(input)
		if arrastrando and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			local d = input.Position - inicioArrastre
			local k = escala.Scale
			clipper.Position = UDim2.new(
				posInicial.X.Scale, posInicial.X.Offset + d.X / k,
				posInicial.Y.Scale, posInicial.Y.Offset + d.Y / k
			)
		end
	end))

	table.insert(_menuConns, UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			arrastrando = false
		end
	end))

	-- Botón de cerrar (esquina superior derecha)
	local cerrarBtn = UI.neonButton(content, Vector2.new(1, 0), UDim2.fromOffset(W - 22, 14), 26, 22, "X",
		C.ROJO, C.ROJO_OSC, function() AbrirMenu(false) end, { font = FONT_TITLE, size = 10 })
	cerrarBtn.holder.Visible = false

	-- ------------------------------------------------------
	-- Lista con scroll (filas del SCHEMA)
	-- ------------------------------------------------------
	local lista = Instance.new("ScrollingFrame")
	lista.Name = "Lista"
	lista.Position = UDim2.fromOffset(16, LISTA_Y)
	lista.Size = UDim2.fromOffset(W - 32, H - LISTA_Y - PIE_H)
	lista.BackgroundTransparency = 1
	lista.BorderSizePixel = 0
	lista.ScrollBarThickness = 3
	lista.ScrollBarImageColor3 = C.MORADO_BRILLO
	lista.ScrollBarImageTransparency = 0.2
	lista.ScrollingDirection = Enum.ScrollingDirection.Y
	lista.ElasticBehavior = Enum.ElasticBehavior.Never
	lista.CanvasSize = UDim2.new(0, 0, 0, 0)
	lista.AutomaticCanvasSize = Enum.AutomaticSize.Y
	lista.ZIndex = 10
	lista.Visible = false               -- se revela con parpadeo al terminar el barrido
	lista.Parent = content

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 5)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = lista

	local relleno = Instance.new("UIPadding")
	relleno.PaddingTop = UDim.new(0, 2)
	relleno.PaddingBottom = UDim.new(0, 8)
	relleno.PaddingRight = UDim.new(0, 8)
	relleno.Parent = lista

	local ANCHO_FILA = W - 32 - 8        -- ancho útil de una fila
	local orden = 0

	local function nuevaFila(alto)
		orden += 1
		local f = Instance.new("Frame")
		f.Size = UDim2.new(1, 0, 0, alto)
		f.BackgroundColor3 = Color3.new(1, 1, 1)
		f.BackgroundTransparency = 0
		f.BorderSizePixel = 0
		f.LayoutOrder = orden
		f.ZIndex = 2
		f.Parent = lista

		local g = Instance.new("UIGradient")
		g.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(52, 22, 92)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(16, 8, 30)),
		})
		g.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.45),
			NumberSequenceKeypoint.new(1, 0.88),
		})
		g.Parent = f

		-- Marca neón a la izquierda
		local marca = Instance.new("Frame")
		marca.Size = UDim2.new(0, 2, 1, -10)
		marca.Position = UDim2.fromOffset(0, 5)
		marca.BackgroundColor3 = C.MORADO
		marca.BackgroundTransparency = 0.2
		marca.BorderSizePixel = 0
		marca.ZIndex = 3
		marca.Parent = f

		return f
	end

	local function etiqueta(fila, texto)
		local l = Instance.new("TextLabel")
		l.BackgroundTransparency = 1
		l.Position = UDim2.fromOffset(12, 0)
		l.Size = UDim2.new(1, -12 - 136, 1, 0)
		l.Font = FONT_MONO
		l.TextSize = 12
		l.TextColor3 = C.TEXTO
		l.TextXAlignment = Enum.TextXAlignment.Left
		l.TextTruncate = Enum.TextTruncate.AtEnd
		l.ZIndex = 5
		l.Text = texto
		l.Parent = fila
		return l
	end

	local ARRIBA_DER = Vector2.new(1, 0.5)

	for _, item in ipairs(SCHEMA) do
		if item.tipo == "titulo" then
			orden += 1
			local f = Instance.new("Frame")
			f.Size = UDim2.new(1, 0, 0, 28)
			f.BackgroundTransparency = 1
			f.BorderSizePixel = 0
			f.LayoutOrder = orden
			f.ZIndex = 2
			f.Parent = lista

			local t = Instance.new("TextLabel")
			t.BackgroundTransparency = 1
			t.Position = UDim2.fromOffset(4, 4)
			t.Size = UDim2.new(1, -8, 0, 16)
			t.Font = FONT_TITLE
			t.TextSize = 10
			t.TextColor3 = C.MORADO_BRILLO
			t.TextXAlignment = Enum.TextXAlignment.Left
			t.ZIndex = 5
			t.Text = item.texto
			t.Parent = f

			UI.fadeLine(f, 0, 25, ANCHO_FILA, C.MORADO, 1.2, 4)

		elseif item.tipo == "tecla" then
			local fila = nuevaFila(32)
			etiqueta(fila, item.texto)

			local b
			b = UI.neonButton(fila, ARRIBA_DER, UDim2.new(1, -8, 0.5, 0), 124, 24, _cfg[item.id].Name,
				C.MORADO_BRILLO, C.MORADO_OSC, function() IniciarCaptura(item.id, b) end,
				{ font = FONT_MONO, size = 12 })

			table.insert(_refrescadores, function()
				if not (_capturando and _capturando.b == b) then
					b.setText(_cfg[item.id].Name)
				end
			end)

		elseif item.tipo == "num" then
			local fila = nuevaFila(32)
			etiqueta(fila, item.texto)

			local valor = Instance.new("TextLabel")
			valor.AnchorPoint = ARRIBA_DER
			valor.Position = UDim2.new(1, -38, 0.5, 0)
			valor.Size = UDim2.fromOffset(56, 24)
			valor.BackgroundTransparency = 1
			valor.Font = FONT_MONO
			valor.TextSize = 14
			valor.TextColor3 = C.TEXTO
			valor.ZIndex = 5
			valor.Text = tostring(_cfg[item.id])
			valor.Parent = fila

			local function cambiar(dir)
				local v = _cfg[item.id] + dir * item.paso
				v = math.floor(v / item.paso + 0.5) * item.paso
				_cfg[item.id] = math.clamp(v, item.min, item.max)
				valor.Text = tostring(_cfg[item.id])
				GuardarConRetardo()
			end

			UI.neonButton(fila, ARRIBA_DER, UDim2.new(1, -98, 0.5, 0), 26, 24, "-",
				C.MORADO_BRILLO, C.MORADO_OSC, function() cambiar(-1) end,
				{ font = FONT_MONO, size = 16 })
			UI.neonButton(fila, ARRIBA_DER, UDim2.new(1, -8, 0.5, 0), 26, 24, "+",
				C.MORADO_BRILLO, C.MORADO_OSC, function() cambiar(1) end,
				{ font = FONT_MONO, size = 16 })

			table.insert(_refrescadores, function() valor.Text = tostring(_cfg[item.id]) end)

		elseif item.tipo == "bool" then
			local fila = nuevaFila(32)
			etiqueta(fila, item.texto)

			local b
			local function pintar()
				b.setText(_cfg[item.id] and "ON" or "OFF")
				b.setColor(_cfg[item.id] and C.VERDE or C.ROJO)
			end

			b = UI.neonButton(fila, ARRIBA_DER, UDim2.new(1, -8, 0.5, 0), 70, 24,
				_cfg[item.id] and "ON" or "OFF", _cfg[item.id] and C.VERDE or C.ROJO, C.MORADO_OSC,
				function()
					_cfg[item.id] = not _cfg[item.id]
					pintar()
					GuardarConRetardo()
				end, { font = FONT_TITLE, size = 10 })

			table.insert(_refrescadores, pintar)
		end
	end

	-- ------------------------------------------------------
	-- Pie: estado de guardado + restablecer
	-- ------------------------------------------------------
	local pie = UI.makeGroup(content, 10)
	pie.Name = "Pie"
	pie.Visible = false

	UI.fadeLine(pie, 20, H - PIE_H + 2, W - 40, C.MORADO, 1.2, 4)

	local estado = Instance.new("TextLabel")
	estado.BackgroundTransparency = 1
	estado.Position = UDim2.fromOffset(22, H - PIE_H + 10)
	estado.Size = UDim2.fromOffset(W - 44 - 150 - 10, 34)
	estado.Font = FONT_MONO
	estado.TextSize = 10
	estado.TextWrapped = true
	estado.TextXAlignment = Enum.TextXAlignment.Left
	estado.TextYAlignment = Enum.TextYAlignment.Center
	estado.ZIndex = 10
	estado.Parent = pie
	_estadoLabel = estado

	UI.neonButton(pie, Vector2.new(1, 0), UDim2.fromOffset(W - 22, H - PIE_H + 12), 150, 30, "RESTABLECER",
		C.ROJO, C.ROJO_OSC, function()
			CancelarCaptura()
			for _, it in ipairs(SCHEMA) do
				if it.id then _cfg[it.id] = it.def end
			end
			SincronizarHub()
			RefrescarMenu()
			GuardarConRetardo()
		end, { font = FONT_TITLE, size = 9, chevrons = true })

	ActualizarEstadoMenu()

	-- ------------------------------------------------------
	-- Glitch en los bordes (cortes horizontales con separación cromática)
	-- ------------------------------------------------------
	local function slice(x, y, w, h, color, endX, life)
		local f = Instance.new("Frame")
		f.AnchorPoint = Vector2.new(0, 0.5)
		f.Position = UDim2.fromOffset(x, y)
		f.Size = UDim2.fromOffset(w, h)
		f.BackgroundColor3 = color
		f.BorderSizePixel = 0
		f.ZIndex = 8
		f.Parent = content
		TweenService:Create(f, TweenInfo.new(life, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Position = UDim2.fromOffset(endX, y),
			BackgroundTransparency = 1,
		}):Play()
		Debris:AddItem(f, life + 0.05)
	end

	local function glitchBurst(fuerte)
		local n = fuerte and math.random(8, 11) or math.random(3, 6)
		local cols = { C.MORADO_BRILLO, C.CIAN, C.ROJO }

		for _ = 1, n do
			task.spawn(function()
				task.wait(math.random() * 0.14)
				if not vivo() then return end
				local izq = math.random() < 0.5
				local y = math.random(4, H - 4)
				local w = math.random(10, 40)
				local h = math.random(1, 3)
				local dist = math.random(16, fuerte and 52 or 36)
				local life = 0.18 + math.random() * 0.2
				local x0 = izq and math.random(0, 8) or (W - w - math.random(0, 8))
				local x1 = izq and (x0 - dist) or (x0 + dist)
				local sgn = izq and -1 or 1
				slice(x0, y, w, h, cols[math.random(1, #cols)], x1, life)
				slice(x0 + sgn * 2, y + 1, w, h, cols[math.random(1, #cols)], x1 + sgn * 6, life)
			end)
		end

		-- Sacudida horizontal del panel y del título con destello cian
		task.spawn(function()
			titleGlow.Color = C.CIAN
			for _, dx in ipairs({ -3, 3, -2, 2, 0 }) do
				if not vivo() then return end
				content.Position = UDim2.new(0.5, dx, 0.5, 0)
				titleLabel.Position = UDim2.fromOffset(20 - dx, 14)
				task.wait(0.03)
			end
			content.Position = UDim2.fromScale(0.5, 0.5)
			titleLabel.Position = TITULO_POS
			titleGlow.Color = C.MORADO
		end)
	end

	_menuUI = {
		clipper = clipper,
		scanCore = scanCore,
		scanGlow = scanGlow,
		titleLabel = titleLabel,
		lista = lista,
		pie = pie,
		cerrar = cerrarBtn.holder,
		glitch = glitchBurst,
		TITULO = TITULO,
		W = W,
	}

	-- ------------------------------------------------------
	-- Entrada: línea de escaneo, apertura vertical, título decodificado, lista y pie en parpadeo
	-- ------------------------------------------------------
	task.spawn(function()
		TweenService:Create(clipper, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
			{ Size = UDim2.fromOffset(W, 2) }):Play()
		task.wait(0.23)
		if not vivo() then return end

		TweenService:Create(clipper, TweenInfo.new(0.36, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
			{ Size = UDim2.fromOffset(W, H) }):Play()
		task.spawn(function() UI.scramble(titleLabel, TITULO, 0.5, false) end)
		task.wait(0.37)
		if not vivo() then return end

		clipper.ClipsDescendants = false
		TweenService:Create(scanCore, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
		TweenService:Create(scanGlow, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
		UI.flickerIn(lista, 0)
		UI.flickerIn(pie, 0.12)
		UI.flickerIn(cerrarBtn.holder, 0.12)
		task.wait(0.4)
		if not vivo() then return end

		_menuEstado = "abierto"
		glitchBurst(true)

		if _menuPendiente == "cerrar" then
			_menuPendiente = nil
			CerrarMenuAnimado()
		end
	end)

	-- Glitch aleatorio recurrente
	task.spawn(function()
		while true do
			task.wait(1.8 + math.random() * 2.4)
			if not vivo() then break end
			if _menuEstado == "abierto" then glitchBurst(false) end
		end
	end)

	-- Pulso del marco y "respiración" del cristal
	task.spawn(function()
		local dim = true
		while vivo() do
			local info = TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
			for _, c in ipairs(pulseBag) do
				TweenService:Create(c, info, { BackgroundTransparency = dim and 0.35 or 0 }):Play()
			end
			TweenService:Create(plate, info, { BackgroundTransparency = dim and 0.18 or 0 }):Play()
			dim = not dim
			task.wait(1.1)
		end
	end)

	-- Barrido de luz periódico
	task.spawn(function()
		while vivo() do
			sweep.Position = UDim2.fromOffset(20, 8)
			sweep.BackgroundTransparency = 1
			TweenService:Create(sweep, TweenInfo.new(0.5), { BackgroundTransparency = 0 }):Play()
			TweenService:Create(sweep, TweenInfo.new(2.6, Enum.EasingStyle.Linear),
				{ Position = UDim2.fromOffset(W - 60, 8) }):Play()
			task.wait(2.1)
			TweenService:Create(sweep, TweenInfo.new(0.5), { BackgroundTransparency = 1 }):Play()
			task.wait(2.5)
		end
	end)
end

-- ------------------------------------------
-- Cierre animado y apertura / alternancia
-- ------------------------------------------
CerrarMenuAnimado = function()
	if _menuEstado ~= "abierto" or not _menuUI then return end

	_menuEstado = "cerrando"
	_menuPendiente = nil
	CancelarCaptura()

	local token = _menuToken
	local u = _menuUI

	task.spawn(function()
		local function vivo()
			return token == _menuToken and _menuGui ~= nil and _menuGui.Parent ~= nil
		end

		u.glitch(true)
		task.spawn(function() UI.scramble(u.titleLabel, u.TITULO, 0.28, true) end)
		UI.flickerOut(u.lista, 0.05)
		UI.flickerOut(u.pie, 0.12)
		UI.flickerOut(u.cerrar, 0.12)
		task.wait(0.32)
		if not vivo() then return end

		u.clipper.ClipsDescendants = true
		u.scanCore.BackgroundTransparency = 0
		u.scanGlow.BackgroundTransparency = 0.6
		TweenService:Create(u.clipper, TweenInfo.new(0.26, Enum.EasingStyle.Quart, Enum.EasingDirection.In),
			{ Size = UDim2.fromOffset(u.W, 2) }):Play()
		task.wait(0.27)
		if not vivo() then return end

		TweenService:Create(u.clipper, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.In),
			{ Size = UDim2.fromOffset(0, 2) }):Play()
		task.wait(0.21)
		if token ~= _menuToken then return end

		local pendiente = _menuPendiente
		DestruirMenu()

		-- Si se pidió abrirlo otra vez mientras se cerraba, se reabre
		if pendiente == "abrir" then
			AbrirMenu(true)
		end
	end)
end

-- visible = true abre, false cierra, nil alterna. Nunca falla en silencio: si la GUI no
-- se puede crear, el motivo sale en la consola (F9) y el siguiente intento vuelve a probar.
AbrirMenu = function(visible)
	local est = _menuEstado

	if visible == nil then
		visible = not (est == "abierto" or est == "abriendo")
	end

	if visible then
		if est == "cerrado" then
			local ok, err = pcall(ConstruirMenu)
			if not ok then
				warn("[Gravattack] No se pudo crear el menú: " .. tostring(err))
				pcall(DestruirMenu)
			end
		elseif est == "cerrando" then
			_menuPendiente = "abrir"
		elseif est == "abriendo" then
			_menuPendiente = nil
		end
	else
		if est == "abierto" then
			CerrarMenuAnimado()
		elseif est == "abriendo" then
			_menuPendiente = "cerrar"
		elseif est == "cerrando" then
			_menuPendiente = nil
		end
	end
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

	-- Prioridad de las teclas: archivo guardado > hub > por defecto
	local cargadas = Cargar()
	if _hubKeys then
		if typeof(_hubKeys.Platform) == "EnumItem" and not cargadas.Platform then
			_cfg.Platform = _hubKeys.Platform
		end
		if typeof(_hubKeys.GravattackMenu) == "EnumItem" and not cargadas.Menu then
			_cfg.Menu = _hubKeys.GravattackMenu
		end
	end
	SincronizarHub()

	table.clear(_conns)

	isHoldingFly = false
	isPlatformMode = false
	isFloating = false
	isSlamming = false

	-- El menú se construye al abrirlo (AbrirMenu). Antes se creaba aquí dentro de un pcall:
	-- si algo fallaba no salía ningún error y el menú simplemente "no salía".
	DestruirMenu()

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

		-- Tecla del menú: NO se filtra por gameProcessed (el juego o el CoreGui pueden marcar
		-- la tecla como procesada y el menú nunca abría). Solo se ignora si el jugador está
		-- escribiendo en un TextBox (p. ej. el chat).
		if Coincide(input, _cfg.Menu) then
			if UserInputService:GetFocusedTextBox() then return end
			AbrirMenu()
			return
		end

		if gameProcessed then return end

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
-- Atajo para el menú:     SetMenuKey(kc)
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

function M.SetMenuKey(kc)
	if typeof(kc) ~= "EnumItem" then return end
	AsignarTecla("Menu", kc)
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

function M.IsMenuOpen() return _menuEstado == "abierto" or _menuEstado == "abriendo" end
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
