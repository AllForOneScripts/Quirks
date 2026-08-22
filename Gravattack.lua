local M = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- ==========================================
-- PARÁMETROS
-- ==========================================
local GRAVEDAD_NORMAL = 196.2
local GRAVEDAD_CERO = 0

local VELOCIDAD_VUELO = 85
local IMPULSO_EXPLOSIVO_Y = 60
local IMPULSO_EXPLOSIVO_XZ = 120

local VELOCIDAD_CAIDA_LENTA = -15
local ACELERACION_CAIDA = 0.75

local DISTANCIA_OBJETIVO_SLAM = 30
local TIEMPO_PEGADO_CABEZA = 0.22
local VELOCIDAD_DESCENSO_SLAM = -140
-- Ajuste del agarre: copia la posición baja del TP de Passive Bang.
local AJUSTE_ALTURA_CABEZA_SLAM = -3.5

-- Seguimiento del objetivo durante el ZAAASH.
local PREDICCION_MOVIMIENTO_SLAM = 0.12
local TIEMPO_GUIADO_DESCENSO_SLAM = 0.38
local DISTANCIA_MAX_CORRECCION_SLAM = 24
local ALCANCE_VERTICAL_HITBOX_SLAM = 3
local MARGEN_SEGURO_SUELO_SLAM = 0.75

-- ==========================================
-- ESTADO
-- ==========================================
local _conns = {}
local _isActive = false
local _keys = { Platform = Enum.KeyCode.C }

local isHoldingSpace = false
local isPlatformMode = false
local isFloating = false
local isSlamming = false
local holdTimer = 0
local lastDamageTime = 0
local lastSlamEndTime = 0

local character, humanoid, rootPart, animator
local animVuelo, animReSalto, animImpacto, animDespertar, animPlataforma

local plataformaActiva = nil
local alturaPlataforma = nil
local loopPlataformaConn = nil

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
-- PLATAFORMA
-- ==========================================
local function DestruirPlataforma()
	isPlatformMode = false
	alturaPlataforma = nil

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

	plataformaActiva = Instance.new("Part")
	plataformaActiva.Name = "PlataformaGravattack"
	plataformaActiva.Size = Vector3.new(12, 1.5, 12)
	plataformaActiva.Transparency = 1
	plataformaActiva.Anchored = true
	plataformaActiva.CanCollide = true
	plataformaActiva.CanTouch = false
	plataformaActiva.CanQuery = false
	plataformaActiva.Parent = workspace

	local altura = humanoid.HipHeight
		+ (rootPart.Size.Y / 2)
		+ (plataformaActiva.Size.Y / 2)

	-- La plataforma sigue X/Z, pero conserva su altura original.
	alturaPlataforma = rootPart.Position.Y - altura

	plataformaActiva.CFrame = CFrame.new(
		rootPart.Position.X,
		alturaPlataforma,
		rootPart.Position.Z
	)

	if animVuelo and animVuelo.IsPlaying then
		animVuelo:Stop(0.2)
	end

	rootPart.AssemblyLinearVelocity = Vector3.zero
	isPlatformMode = true

	IniciarLoopAnimPlataforma()
end

-- ==========================================
-- SUELO Y OBJETIVOS
-- ==========================================
local function BuscarSueloDebajo()
	if not rootPart then return nil end

	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = { character }
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
	local menorDistancia = DISTANCIA_OBJETIVO_SLAM

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
				velocidadObjetivo.X, VELOCIDAD_DESCENSO_SLAM, velocidadObjetivo.Z
			)
			return
		end

		conexion:Disconnect()
		rootPart.AssemblyLinearVelocity = Vector3.new(
			velocidadObjetivo.X, VELOCIDAD_DESCENSO_SLAM, velocidadObjetivo.Z
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
	DestruirPlataforma()
	DetenerAnimacionesCustom(0.1)

	-- El ZAAASH a un jugador solo se usa al presionar Ctrl mientras vuelas.
	-- No exige una altura mínima: basta con que el objetivo esté debajo.
	local estabaVolando = isFloating
	isFloating = false
	holdTimer = 0
	workspace.Gravity = GRAVEDAD_NORMAL

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

	local alturaPiernas = humanoid.HipHeight + (rootPart.Size.Y / 2)

	rootPart.CFrame = CFrame.new(
		rayResult.Position + Vector3.new(0, alturaPiernas, 0)
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
	isHoldingSpace = false
	isPlatformMode = false
	holdTimer = 0
	workspace.Gravity = GRAVEDAD_NORMAL

	local lastHealth = humanoid.Health

	local healthConn = humanoid.HealthChanged:Connect(function(health)
		if health < lastHealth then
			lastDamageTime = tick()
		end

		lastHealth = health
	end)

	table.insert(_conns, healthConn)
end

-- ==========================================
-- API
-- ==========================================
function M.Start(Keys)
	if Keys then
		_keys = Keys
	end

	if _isActive then return end
	_isActive = true

	GRAVEDAD_NORMAL = workspace.Gravity

	table.clear(_conns)

	isHoldingSpace = false
	isPlatformMode = false
	isFloating = false
	isSlamming = false

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
		if gameProcessed or not humanoid or not rootPart then return end

		if input.KeyCode == Enum.KeyCode.Space then
			isHoldingSpace = true

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
					IMPULSO_EXPLOSIVO_Y,
					velActual.Z
				)

				isFloating = true
			end

		elseif input.KeyCode == _keys.Platform then
			isPlatformMode = not isPlatformMode

			if isPlatformMode then
				CrearPlataforma()
			else
				-- No activa ni desactiva el vuelo: conserva el estado previo.
				DestruirPlataforma()
			end

		elseif input.KeyCode == Enum.KeyCode.LeftControl
			or input.KeyCode == Enum.KeyCode.RightControl then

			AplastarContraElSuelo()
		end
	end)

	table.insert(_conns, inputBeganConn)

	local inputEndedConn = UserInputService.InputEnded:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.Space then
			isHoldingSpace = false
		end
	end)

	table.insert(_conns, inputEndedConn)

	-- ==========================================
	-- BUCLE PRINCIPAL
	-- ==========================================
	local renderConn = RunService.RenderStepped:Connect(function(dt)
		if not _isActive
			or isSlamming
			or not humanoid
			or not rootPart
			or not humanoid.Parent then
			return
		end

		local state = humanoid:GetState()

		local inAir = (
			state == Enum.HumanoidStateType.Jumping
			or state == Enum.HumanoidStateType.Freefall
		)

		-- MODO PLATAFORMA
		if isPlatformMode and plataformaActiva then
			workspace.Gravity = GRAVEDAD_NORMAL

			local moveDir = humanoid.MoveDirection
			local currentVel = rootPart.AssemblyLinearVelocity
			local targetXZ = Vector3.zero

			if moveDir.Magnitude > 0 then
				targetXZ = moveDir.Unit * VELOCIDAD_VUELO
			end

			rootPart.AssemblyLinearVelocity = Vector3.new(
				targetXZ.X,
				currentVel.Y,
				targetXZ.Z
			)

			plataformaActiva.CFrame = CFrame.new(
				rootPart.Position.X,
				alturaPlataforma,
				rootPart.Position.Z
			)

			if not isHoldingSpace then
				holdTimer = 0
			end

		-- MODO FLOTAR
		else
			-- El suelo SÍ desactiva el vuelo.
			if not inAir then
				if isFloating then
					isFloating = false
					DetenerAnimacionesCustom(0.3)
				end

				workspace.Gravity = GRAVEDAD_NORMAL

				if not isHoldingSpace then
					holdTimer = 0
				end
			end

			if isHoldingSpace then
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
							moveDir.X * IMPULSO_EXPLOSIVO_XZ,
							IMPULSO_EXPLOSIVO_Y,
							moveDir.Z * IMPULSO_EXPLOSIVO_XZ
						)
					end
				end
			else
				if not isFloating then
					holdTimer = 0
				end
			end

			if isFloating then
				workspace.Gravity = GRAVEDAD_CERO

				local moveDir = humanoid.MoveDirection
				local velActual = rootPart.AssemblyLinearVelocity
				local velY = velActual.Y

				if isHoldingSpace then
					if velY < -2 then
						velY = -2
					end
				else
					velY -= ACELERACION_CAIDA

					if velY < VELOCIDAD_CAIDA_LENTA then
						velY = VELOCIDAD_CAIDA_LENTA
					end
				end

				local targetVelXZ

				if moveDir.Magnitude > 0 then
					targetVelXZ = moveDir * VELOCIDAD_VUELO
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
	end)

	table.insert(_conns, renderConn)
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

	workspace.Gravity = GRAVEDAD_NORMAL

	isHoldingSpace = false
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

function M.SetKey(kc)
	if _keys then
		_keys.Platform = kc
	end

	isPlatformMode = false
	DestruirPlataforma()
end

function M.IsActive()
	return _isActive
end

return M
