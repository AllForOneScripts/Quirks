--[[
	Gravattack.lua  (v2)

	Space (mantener)  -> la gravedad pierde: salto enorme + planeo antigravitacional
	Ctrl              -> slam (ZAAASH) contra el suelo / la cabeza de un objetivo
	Space en vuelo    -> ráfaga de aire hacia abajo (cono de aire presionado) + re-salto

	La suspensión aérea (tecla C) vive ahora en Suspension.lua (menú con F8).
	Los dos módulos se hablan por ENV.AFO_GRAVATTACK_API / ENV.AFO_SUSPENSION_API.

	Cambios de esta versión:
	  1) Viento que se enrosca por tu cuerpo mientras mantienes Space y sale disparado al perder la gravedad.
	  2) Planeo tipo Genshin con fuerzas reales (LinearVelocity + VectorForce), sin tocar workspace.Gravity.
	  3) Ráfaga de aire hacia abajo al saltar en pleno vuelo.
	  4) Todo lo de la plataforma se movió a Suspension.lua.
]]

local M = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- Tabla compartida entre módulos del hub (getgenv si existe, _G si no).
local ENV = (typeof(getgenv) == "function" and getgenv()) or _G

-- ==========================================
-- PARÁMETROS
-- ==========================================

-- Impulso inicial al perder la gravedad
local IMPULSO_EXPLOSIVO_Y = 60
local IMPULSO_EXPLOSIVO_XZ = 120

-- Planeo (estilo planeador de Genshin)
local VELOCIDAD_VUELO = 85          -- velocidad horizontal cuando hay input
local VELOCIDAD_CAIDA_PLANEO = -15  -- descenso constante al planear (soltando Space)
local VELOCIDAD_SUSTENTACION = -2   -- descenso casi nulo mientras mantienes Space
local DESCENSO_AL_AVANZAR = 1       -- multiplicador del descenso cuando avanzas (0 = vuelo nivelado)

-- Aceleraciones máximas en studs/s². La fuerza real es masa * aceleración.
local ACEL_HORIZONTAL = 240                 -- al empezar a avanzar
local ACEL_FRENADO = 280                    -- al soltar el input: quieto de inmediato
local ACEL_VERTICAL_EMPUJAR = 60            -- cuando hay que subir la velocidad vertical
local ACEL_VERTICAL_FRENAR_SOSTENIENDO = 25 -- frena la subida con Space mantenido (salto grande)
local ACEL_VERTICAL_FRENAR_SUELTO = 45      -- frena la subida al soltar Space

-- Slam
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

-- Viento (visual al cargar y al salir disparado)
local COLOR_VIENTO_CLARO = Color3.fromRGB(240, 250, 255)  -- cabeza de la estela
local COLOR_VIENTO = Color3.fromRGB(110, 185, 255)        -- cola de la estela (azul MHA)
local COLOR_ONDA = Color3.fromRGB(35, 140, 255)           -- halo del cono de aire
local COLOR_AIRE = Color3.fromRGB(215, 240, 255)
local INICIO_VISUAL_FRACCION = 0.45 -- el viento empieza a verse tras esta fracción del retardo...
local INICIO_VISUAL_MIN = 0.1       -- ...y nunca antes de estos segundos (un salto normal no lo dispara)
local FILAMENTOS_VIENTO = 8          -- estelas de viento alrededor del cuerpo
local VIDA_ESTELA = 0.3              -- s que dura cada estela (también el tiempo de desvanecido)
local RADIO_VIENTO_INICIO = 2.6      -- el viento arranca algo separado...
local RADIO_VIENTO_CUERPO = 1.5      -- ...y se va pegando al cuerpo al cargar
local ALTO_CUERPO_VIENTO = 6.4       -- de los pies a un poco por encima de la cabeza
local TORSION_VIENTO = 2.4           -- radianes que se enrosca la espiral de pies a cabeza
local VELOCIDAD_MIN_VIENTO = 28      -- tras salir disparado, el viento sigue mientras te muevas más rápido que esto
local DURACION_MAX_VIENTO = 2        -- tope en segundos

-- Ráfaga de aire (física simple: arrastre exponencial)
local VELOCIDAD_CHORRO = 85          -- velocidad de salida del aire (studs/s)
local ARRASTRE_AIRE = 3.2            -- 1/s
local ANGULO_CONO_GRADOS = 20        -- semiángulo de apertura del cono
local RADIO_BASE_CHORRO = 1.4
local ANILLOS_CONO = 7
local SEPARACION_PARCELAS = 0.028    -- s entre anillos de aire consecutivos
local VIDA_PARCELA = 0.4
local DURACION_SALPICADURA = 0.28
local DELTA_V_REF = IMPULSO_EXPLOSIVO_Y - VELOCIDAD_CAIDA_PLANEO

-- ==========================================
-- ESTADO
-- ==========================================
local _conns = {}
local _charConns = {}
local _isActive = false
local _keys = {}

local isHoldingSpace = false
local isFloating = false
local isSlamming = false
local holdTimer = 0
local lastDamageTime = 0
local lastSlamEndTime = 0
local estabaSuspendido = false
local tSuelo = 0

local character, humanoid, rootPart, animator
local animVuelo, animReSalto, animImpacto, animDespertar

local fuerzaAttach, fuerzaVel, antiGravedad = nil, nil, nil

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
end

-- ==========================================
-- FUERZAS (antigravedad + planeo)
-- ==========================================
-- VectorForce cancela exactamente el peso (masa * g) y LinearVelocity empuja la
-- velocidad hacia el objetivo con una fuerza limitada: cada cambio es una
-- aceleración constante, sin escribir la velocidad cuadro a cuadro.
local function DestruirFuerzas()
	if antiGravedad then antiGravedad:Destroy() end
	if fuerzaVel then fuerzaVel:Destroy() end
	if fuerzaAttach then fuerzaAttach:Destroy() end
	antiGravedad, fuerzaVel, fuerzaAttach = nil, nil, nil
end

local function CrearFuerzas()
	DestruirFuerzas()
	if not rootPart then return end

	fuerzaAttach = Instance.new("Attachment")
	fuerzaAttach.Name = "AFO_GravAttach"
	fuerzaAttach.Parent = rootPart

	antiGravedad = Instance.new("VectorForce")
	antiGravedad.Name = "AFO_AntiGravedad"
	antiGravedad.Attachment0 = fuerzaAttach
	antiGravedad.RelativeTo = Enum.ActuatorRelativeTo.World
	antiGravedad.ApplyAtCenterOfMass = true
	antiGravedad.Force = Vector3.zero
	antiGravedad.Enabled = false
	antiGravedad.Parent = rootPart

	fuerzaVel = Instance.new("LinearVelocity")
	fuerzaVel.Name = "AFO_VelocidadPlaneo"
	fuerzaVel.Attachment0 = fuerzaAttach
	fuerzaVel.RelativeTo = Enum.ActuatorRelativeTo.World
	fuerzaVel.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
	fuerzaVel.ForceLimitMode = Enum.ForceLimitMode.PerAxis
	fuerzaVel.MaxAxesForce = Vector3.zero
	fuerzaVel.VectorVelocity = Vector3.zero
	fuerzaVel.Enabled = false
	fuerzaVel.Parent = rootPart
end

local function ApagarFuerzas()
	if antiGravedad then
		antiGravedad.Enabled = false
		antiGravedad.Force = Vector3.zero
	end

	if fuerzaVel then
		fuerzaVel.Enabled = false
		fuerzaVel.MaxAxesForce = Vector3.zero
	end
end

local function EncenderFuerzas()
	if not fuerzaVel or not antiGravedad then return end

	antiGravedad.Enabled = true
	fuerzaVel.Enabled = true
end

local function ActualizarFuerzas()
	if not (rootPart and humanoid) then return end

	-- Otros módulos (SpeedForce, etc.) pueden borrar o apagar constraints del personaje.
	-- Si faltan o están apagadas, se recrean / se encienden aquí mismo.
	if not (fuerzaVel and antiGravedad and fuerzaAttach)
		or fuerzaAttach.Parent ~= rootPart
		or fuerzaVel.Parent ~= rootPart
		or antiGravedad.Parent ~= rootPart
		or fuerzaVel.Attachment0 ~= fuerzaAttach
		or antiGravedad.Attachment0 ~= fuerzaAttach then

		CrearFuerzas()
	end

	if not fuerzaVel.Enabled then
		fuerzaVel.Enabled = true
	end

	if not antiGravedad.Enabled then
		antiGravedad.Enabled = true
	end

	local masa = rootPart.AssemblyMass
	antiGravedad.Force = Vector3.new(0, masa * workspace.Gravity, 0)

	local moveDir = humanoid.MoveDirection
	local conInput = moveDir.Magnitude > 0.05
	local velActual = rootPart.AssemblyLinearVelocity

	-- Quieto -> solo hacia abajo. Avanzando -> hacia adelante. Nada más.
	local objetivoXZ = Vector3.zero
	if conInput then
		objetivoXZ = moveDir * VELOCIDAD_VUELO
	end

	local objetivoY
	if isHoldingSpace then
		objetivoY = VELOCIDAD_SUSTENTACION
	elseif conInput then
		objetivoY = VELOCIDAD_CAIDA_PLANEO * DESCENSO_AL_AVANZAR
	else
		objetivoY = VELOCIDAD_CAIDA_PLANEO
	end

	local aXZ = conInput and ACEL_HORIZONTAL or ACEL_FRENADO

	local aY
	if velActual.Y > objetivoY then
		aY = isHoldingSpace and ACEL_VERTICAL_FRENAR_SOSTENIENDO or ACEL_VERTICAL_FRENAR_SUELTO
	else
		aY = ACEL_VERTICAL_EMPUJAR
	end

	fuerzaVel.VectorVelocity = Vector3.new(objetivoXZ.X, objetivoY, objetivoXZ.Z)
	fuerzaVel.MaxAxesForce = Vector3.new(masa * aXZ, masa * aY, masa * aXZ)
end

-- ==========================================
-- EFECTOS VISUALES
-- ==========================================
local FX = {}

do
	local carpeta
	local filamentos = {}
	local anillosCono = {}
	local salpicadura
	local parteSuelo, emisorSuelo
	local parteAire, emisorAire

	local estado = {
		modo = "idle", -- "idle" | "carga" | "impulso" | "apagando"
		carga = 0,
		t = 0,
		tImpulso = 0,
		tApagando = 0,
	}

	local cono = {
		activo = false,
		t = 0,
		s = 1,
		parcelas = {},
		impacto = nil,
		ultimoPies = Vector3.zero,
	}

	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.RespectCanCollide = true

	local TAN_CONO = math.tan(math.rad(ANGULO_CONO_GRADOS))

	-- ---------- utilidades ----------
	local function NuevaParte(nombre)
		local p = Instance.new("Part")
		p.Name = nombre
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Massless = true
		p.Transparency = 1
		p.Size = Vector3.new(1, 1, 1)
		p.Parent = carpeta
		return p
	end

	local function PiesActuales()
		if not rootPart or not rootPart.Parent then return nil end

		local alto = (humanoid and humanoid.HipHeight or 2) + rootPart.Size.Y / 2
		return rootPart.Position - Vector3.new(0, alto, 0)
	end

	-- Anillo plano dibujado con SurfaceGui (círculo + UIStroke). Solo lo usa el cono de aire.
	local function CrearAnillo(colorBorde)
		local a = {
			parte = NuevaParte("AnilloFX"),
			guis = {},
			nucleos = {},
			halos = {},
			visible = false,
		}

		a.parte.Size = Vector3.new(2, 0.05, 2)

		for i, cara in ipairs({ Enum.NormalId.Top, Enum.NormalId.Bottom }) do
			local gui = Instance.new("SurfaceGui")
			gui.Name = "GuiAnillo"
			gui.Face = cara
			gui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
			gui.CanvasSize = Vector2.new(256, 256)
			gui.LightInfluence = 0
			gui.AlwaysOnTop = false
			gui.Enabled = false
			pcall(function()
				gui.Brightness = 1.6
			end)
			gui.Parent = a.parte

			local function NuevoMarco(grosor, color, zindex)
				local f = Instance.new("Frame")
				f.AnchorPoint = Vector2.new(0.5, 0.5)
				f.Position = UDim2.fromScale(0.5, 0.5)
				f.Size = UDim2.fromScale(0.84, 0.84)
				f.BackgroundTransparency = 1
				f.BorderSizePixel = 0
				f.ZIndex = zindex
				f.Parent = gui

				local c = Instance.new("UICorner")
				c.CornerRadius = UDim.new(0.5, 0)
				c.Parent = f

				local s = Instance.new("UIStroke")
				s.Thickness = grosor
				s.Color = color
				s.Transparency = 1
				s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				s.Parent = f

				return s
			end

			a.guis[i] = gui
			a.halos[i] = NuevoMarco(16, COLOR_ONDA, 1)
			a.nucleos[i] = NuevoMarco(5, colorBorde, 2)
		end

		return a
	end

	local function PonerAnillo(a, cf, radio, alfa)
		alfa = math.clamp(alfa or 0, 0, 1)

		if alfa < 0.01 then
			if a.visible then
				a.visible = false
				for _, g in ipairs(a.guis) do
					g.Enabled = false
				end
			end
			return
		end

		if not a.visible then
			a.visible = true
			for _, g in ipairs(a.guis) do
				g.Enabled = true
			end
		end

		local d = math.max(radio * 2, 0.3)
		a.parte.Size = Vector3.new(d, 0.05, d)
		a.parte.CFrame = cf

		for i = 1, #a.guis do
			a.nucleos[i].Transparency = 1 - alfa
			a.halos[i].Transparency = 1 - alfa * 0.4
		end
	end

	-- ---------- viento por el cuerpo ----------
	-- Cada filamento es una parte invisible con una Trail. Al moverla en espiral
	-- alrededor del cuerpo la estela dibuja una línea de viento que sube de los pies
	-- a la cabeza. Al salir disparado hacia arriba, el propio movimiento del cuerpo
	-- alarga las estelas y se ve el aire pasando pegado a ti.
	local function CrearFilamento(i)
		local parte = NuevaParte("Viento")
		parte.Size = Vector3.new(0.2, 0.2, 0.2)

		local a0 = Instance.new("Attachment")
		a0.Position = Vector3.new(0, 0.25, 0)
		a0.Parent = parte

		local a1 = Instance.new("Attachment")
		a1.Position = Vector3.new(0, -0.25, 0)
		a1.Parent = parte

		local estela = Instance.new("Trail")
		estela.Attachment0 = a0
		estela.Attachment1 = a1
		estela.Lifetime = VIDA_ESTELA
		estela.MinLength = 0.02
		estela.FaceCamera = true
		estela.LightEmission = 0.55
		estela.LightInfluence = 0
		estela.Color = ColorSequence.new(COLOR_VIENTO_CLARO, COLOR_VIENTO)
		estela.WidthScale = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(1, 0),
		})
		estela.Transparency = NumberSequence.new(0.5, 1)
		estela.Enabled = false
		estela.Parent = parte

		return {
			parte = parte,
			estela = estela,
			fase = ((i - 1) * 0.382) % 1,
			angulo = (i - 1) / FILAMENTOS_VIENTO * math.pi * 2,
			uPrev = 0,
			activo = false,
			reactivar = false,
			opacidad = -1,
		}
	end

	local function ApagarFilamentos()
		for _, f in ipairs(filamentos) do
			if f.activo then
				f.estela.Enabled = false
				f.activo = false
				f.reactivar = false
			end
		end
	end

	-- cuantos: filamentos encendidos. subida: vueltas de pies a cabeza por segundo.
	-- giro: rad/s alrededor del cuerpo. opacidad: transparencia de la cabeza de la estela.
	local function MoverFilamentos(cuantos, subida, giro, radio, opacidad)
		local base = rootPart.Position
		local pies = -((humanoid and humanoid.HipHeight or 2) + rootPart.Size.Y / 2)

		for i, f in ipairs(filamentos) do
			if i <= cuantos then
				local u = (estado.t * subida + f.fase) % 1
				local h = pies - 0.2 + u * ALTO_CUERPO_VIENTO
				local ang = f.angulo + estado.t * giro + u * TORSION_VIENTO

				f.parte.CFrame = CFrame.new(base + Vector3.new(math.cos(ang) * radio, h, math.sin(ang) * radio))

				if not f.activo then
					f.uPrev = u
					f.estela.Enabled = true
					f.activo = true
					f.reactivar = false
				elseif u < f.uPrev then
					-- Dio la vuelta (de la cabeza a los pies): corta la estela para que no una los dos extremos.
					f.estela.Enabled = false
					f.reactivar = true
				elseif f.reactivar then
					f.estela.Enabled = true
					f.reactivar = false
				end

				f.uPrev = u

				if math.abs(f.opacidad - opacidad) > 0.03 then
					f.opacidad = opacidad
					f.estela.Transparency = NumberSequence.new(opacidad, 1)
				end
			elseif f.activo then
				f.estela.Enabled = false
				f.activo = false
				f.reactivar = false
			end
		end
	end

	local function RenderViento(dt)
		if estado.modo == "idle" then return end

		if not rootPart or not rootPart.Parent then
			ApagarFilamentos()
			emisorSuelo.Rate = 0
			estado.modo = "idle"
			return
		end

		estado.t += dt

		if estado.modo == "carga" then
			-- El aire se junta: más estelas, más rápidas y cada vez más pegadas al cuerpo.
			local p = estado.carga
			local cuantos = math.floor(1 + (FILAMENTOS_VIENTO - 1) * p + 0.5)
			local radio = RADIO_VIENTO_INICIO + (RADIO_VIENTO_CUERPO - RADIO_VIENTO_INICIO) * p

			MoverFilamentos(cuantos, 0.9 + 2.2 * p, 4 + 8 * p, radio, 0.92 - 0.77 * p)

			local pies = PiesActuales()

			if pies then
				parteSuelo.CFrame = CFrame.new(pies)
			end

			emisorSuelo.Rate = 55 * p

		elseif estado.modo == "impulso" then
			-- Salida disparada: todas las estelas suben por el cuerpo mientras vas rápido.
			estado.tImpulso += dt

			local vel = rootPart.AssemblyLinearVelocity.Magnitude
			local k = math.clamp(vel / 80, 0.3, 1)
			local radio = RADIO_VIENTO_CUERPO + 0.8 * math.min(estado.tImpulso / 0.35, 1)

			MoverFilamentos(FILAMENTOS_VIENTO, 3.2, 14, radio, 0.55 - 0.45 * k)

			if (estado.tImpulso > 0.35 and vel < VELOCIDAD_MIN_VIENTO)
				or estado.tImpulso > DURACION_MAX_VIENTO then

				ApagarFilamentos()
				estado.modo = "apagando"
				estado.tApagando = 0
			end

		elseif estado.modo == "apagando" then
			-- Las estelas ya no emiten: se desvanecen solas en VIDA_ESTELA.
			estado.tApagando += dt

			if estado.tApagando > VIDA_ESTELA + 0.05 then
				estado.modo = "idle"
			end
		end
	end

	-- ---------- construcción ----------
	local function Preparar()
		if carpeta and carpeta.Parent then return true end

		carpeta = Instance.new("Folder")
		carpeta.Name = "AFO_GravattackFX"
		carpeta.Parent = workspace

		filamentos, anillosCono = {}, {}

		for i = 1, FILAMENTOS_VIENTO do
			filamentos[i] = CrearFilamento(i)
		end

		for i = 1, ANILLOS_CONO do
			anillosCono[i] = CrearAnillo(COLOR_AIRE)
		end

		salpicadura = CrearAnillo(COLOR_AIRE)

		-- Resoplido de viento a ras de suelo mientras cargas y al salir disparado
		parteSuelo = NuevaParte("VientoSuelo")
		parteSuelo.Size = Vector3.new(3.2, 0.2, 3.2)

		emisorSuelo = Instance.new("ParticleEmitter")
		emisorSuelo.Texture = "rbxasset://textures/particles/smoke_main.dds"
		emisorSuelo.Color = ColorSequence.new(COLOR_VIENTO_CLARO, COLOR_VIENTO)
		emisorSuelo.LightEmission = 0.5
		emisorSuelo.LightInfluence = 0
		emisorSuelo.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.7),
			NumberSequenceKeypoint.new(1, 2.6),
		})
		emisorSuelo.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.55),
			NumberSequenceKeypoint.new(1, 1),
		})
		emisorSuelo.Lifetime = NumberRange.new(0.4, 0.7)
		emisorSuelo.Speed = NumberRange.new(5, 11)
		emisorSuelo.Drag = 2
		emisorSuelo.SpreadAngle = Vector2.new(80, 80)
		emisorSuelo.EmissionDirection = Enum.NormalId.Top
		emisorSuelo.Shape = Enum.ParticleEmitterShape.Disc
		emisorSuelo.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
		emisorSuelo.Rotation = NumberRange.new(0, 360)
		emisorSuelo.RotSpeed = NumberRange.new(-80, 80)
		emisorSuelo.Rate = 0
		emisorSuelo.Parent = parteSuelo

		-- Corriente de aire de la ráfaga hacia abajo
		parteAire = NuevaParte("ChorroAire")
		emisorAire = Instance.new("ParticleEmitter")
		emisorAire.Texture = "rbxasset://textures/particles/smoke_main.dds"
		emisorAire.Color = ColorSequence.new(COLOR_AIRE, COLOR_ONDA)
		emisorAire.LightEmission = 0.6
		emisorAire.LightInfluence = 0
		emisorAire.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.8),
			NumberSequenceKeypoint.new(1, 3),
		})
		emisorAire.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.35),
			NumberSequenceKeypoint.new(1, 1),
		})
		emisorAire.Lifetime = NumberRange.new(0.28, 0.4)
		emisorAire.Speed = NumberRange.new(VELOCIDAD_CHORRO * 0.65, VELOCIDAD_CHORRO)
		emisorAire.Drag = ARRASTRE_AIRE
		emisorAire.SpreadAngle = Vector2.new(ANGULO_CONO_GRADOS, ANGULO_CONO_GRADOS)
		emisorAire.EmissionDirection = Enum.NormalId.Bottom
		emisorAire.Rotation = NumberRange.new(0, 360)
		emisorAire.RotSpeed = NumberRange.new(-60, 60)
		emisorAire.Rate = 0
		emisorAire.Parent = parteAire

		return true
	end

	-- ---------- ráfaga de aire ----------
	local function RenderCono(dt)
		if not cono.activo then return end

		cono.t += dt

		local s = cono.s
		local vivo = false

		for i, pr in ipairs(cono.parcelas) do
			local a = anillosCono[i]
			local edad = cono.t - pr.ts

			if edad < 0 then
				vivo = true
			elseif edad >= VIDA_PARCELA then
				PonerAnillo(a, CFrame.identity, 1, 0)
			else
				vivo = true

				if not pr.pos then
					pr.pos = PiesActuales() or cono.ultimoPies
				end

				local k = edad / VIDA_PARCELA
				local recorrido = (VELOCIDAD_CHORRO / ARRASTRE_AIRE) * (1 - math.exp(-ARRASTRE_AIRE * edad))
				local radio = RADIO_BASE_CHORRO + recorrido * TAN_CONO
				local pos = pr.pos - Vector3.new(0, recorrido, 0)

				PonerAnillo(a, CFrame.new(pos), radio, s * (1 - k) ^ 1.2 * 0.9)
			end
		end

		-- El chorro llega al suelo y se abre en una salpicadura radial
		local sp = cono.impacto

		if sp then
			local edad = cono.t - sp.t

			if edad < 0 then
				vivo = true
			elseif edad < DURACION_SALPICADURA then
				vivo = true

				local k = edad / DURACION_SALPICADURA
				local e = 1 - (1 - k) ^ 2

				PonerAnillo(
					salpicadura,
					CFrame.new(sp.centro + Vector3.new(0, 0.12, 0)),
					sp.radio0 + 9 * e * s,
					s * (1 - k) ^ 1.3 * 0.85
				)
			else
				PonerAnillo(salpicadura, CFrame.identity, 1, 0)
				cono.impacto = nil
			end
		end

		if not vivo then
			cono.activo = false
		end
	end

	-- ---------- API ----------
	function FX.Iniciar()
		Preparar()
	end

	function FX.Render(dt)
		if not carpeta then return end

		RenderViento(dt)
		RenderCono(dt)
	end

	-- Llamar cada cuadro mientras se mantiene el salto: p va de 0 a 1.
	function FX.Cargar(p)
		if not Preparar() then return end

		estado.modo = "carga"
		estado.carga = math.clamp(p, 0, 1)
	end

	-- Soltaste antes de tiempo (o algo lo interrumpió): el viento deja de emitir
	-- y las estelas se acaban solas en una fracción de segundo.
	function FX.Cancelar()
		if estado.modo == "idle" or estado.modo == "apagando" then return end

		ApagarFilamentos()
		emisorSuelo.Rate = 0
		estado.modo = "apagando"
		estado.tApagando = 0
	end

	-- La gravedad perdió: el viento sale disparado por el cuerpo y el suelo resopla.
	function FX.Liberar()
		if not Preparar() then return end

		estado.modo = "impulso"
		estado.tImpulso = 0
		emisorSuelo.Rate = 0

		local pies = PiesActuales()

		if pies then
			parteSuelo.CFrame = CFrame.new(pies)
			emisorSuelo:Emit(26)
		end
	end

	-- Ráfaga de aire hacia abajo al saltar en pleno vuelo.
	-- Conservación del momento: m * dV = m_aire * v_chorro. Con v_chorro fija, un
	-- dV mayor mueve más aire: más densidad (opacidad y partículas) en el cono.
	function FX.RafagaAbajo(deltaV)
		if not Preparar() then return end

		local pies = PiesActuales()
		if not pies then return end

		local s = math.clamp((deltaV or DELTA_V_REF) / DELTA_V_REF, 0.35, 1.25)

		cono.activo = true
		cono.t = 0
		cono.s = s
		cono.impacto = nil
		cono.ultimoPies = pies
		cono.parcelas = {}

		for i = 1, #anillosCono do
			cono.parcelas[i] = { ts = (i - 1) * SEPARACION_PARCELAS, pos = nil }
		end

		parteAire.CFrame = CFrame.new(pies)
		emisorAire:Emit(math.floor(14 * s + 0.5))

		-- ¿Llega el chorro al suelo? Con arrastre exponencial el alcance máximo es v/c.
		rayParams.FilterDescendantsInstances = { character, carpeta }

		local alcance = VELOCIDAD_CHORRO / ARRASTRE_AIRE
		local res = workspace:Raycast(pies + Vector3.new(0, 1, 0), Vector3.new(0, -alcance, 0), rayParams)

		if res then
			local distancia = pies.Y - res.Position.Y
			local x = distancia * ARRASTRE_AIRE / VELOCIDAD_CHORRO

			if distancia > 0 and x < 0.97 then
				cono.impacto = {
					t = -math.log(1 - x) / ARRASTRE_AIRE,
					centro = res.Position,
					radio0 = RADIO_BASE_CHORRO + distancia * TAN_CONO,
				}
			end
		end
	end

	function FX.Destruir()
		if carpeta then
			carpeta:Destroy()
		end

		carpeta = nil
		filamentos, anillosCono = {}, {}
		estado.modo = "idle"
		cono.activo = false
		cono.impacto = nil
	end
end

-- ==========================================
-- SUSPENSIÓN (script aparte: Suspension.lua)
-- ==========================================
local function ObtenerSuspension()
	local api = ENV.AFO_SUSPENSION_API

	if type(api) == "table" then
		return api
	end

	return nil
end

local function EstaSuspendido()
	local api = ObtenerSuspension()
	return api ~= nil and api.IsSuspended() == true
end

local function CancelarSuspension()
	local api = ObtenerSuspension()

	if api and api.IsSuspended() then
		api.Cancel()
	end
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
	CancelarSuspension()
	DetenerAnimacionesCustom(0.1)

	-- El ZAAASH a un jugador solo se usa al presionar Ctrl mientras vuelas.
	-- No exige una altura mínima: basta con que el objetivo esté debajo.
	local estabaVolando = isFloating
	isFloating = false
	holdTimer = 0
	ApagarFuerzas()
	FX.Cancelar()

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
local function LimpiarConexionesPersonaje()
	for _, c in ipairs(_charConns) do
		if c.Disconnect then
			c:Disconnect()
		end
	end

	table.clear(_charConns)
end

local function SetupCharacter(newCharacter)
	LimpiarConexionesPersonaje()
	DestruirFuerzas()
	FX.Cancelar()

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
	end

	CrearFuerzas()

	isFloating = false
	isSlamming = false
	isHoldingSpace = false
	holdTimer = 0
	tSuelo = 0
	estabaSuspendido = false

	local lastHealth = humanoid.Health

	table.insert(_charConns, humanoid.HealthChanged:Connect(function(health)
		if health < lastHealth then
			lastDamageTime = tick()
		end

		lastHealth = health
	end))

	table.insert(_charConns, humanoid.Died:Connect(function()
		isFloating = false
		ApagarFuerzas()
		FX.Cancelar()
	end))
end

-- ==========================================
-- ANTIGRAVEDAD
-- ==========================================
local paramsSuelo = RaycastParams.new()
paramsSuelo.FilterType = Enum.RaycastFilterType.Exclude
paramsSuelo.RespectCanCollide = true

-- Se detecta con un raycast y no con humanoid:GetState(): otros módulos pueden dejar
-- al Humanoid en otro estado (PlatformStand, Running, estados desactivados...) y eso
-- cortaba el vuelo a los pocos cuadros.
local function EstaEnElSuelo()
	if not humanoid or not rootPart then return false end

	-- Subiendo rápido nunca cuenta como suelo (cubre el instante del impulso).
	if rootPart.AssemblyLinearVelocity.Y > 6 then return false end

	paramsSuelo.FilterDescendantsInstances = { character }

	local alcance = math.max(humanoid.HipHeight + rootPart.Size.Y / 2, 3) + 0.6

	return workspace:Raycast(
		rootPart.Position,
		Vector3.new(0, -alcance, 0),
		paramsSuelo
	) ~= nil
end

local function ObtenerTiempoRequerido()
	local ahora = tick()

	if ahora - lastDamageTime <= 3 then
		return 0.15
	elseif ahora - lastSlamEndTime <= 1.5 then
		return 0.3
	end

	return 0.5
end

local function ActivarAntigravedad()
	isFloating = true
	tSuelo = 0

	local herido = tick() - lastDamageTime <= 3

	-- La onda se completa y se suelta (se congela en el suelo donde estabas)
	FX.Liberar()

	if herido then
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

	EncenderFuerzas()

	rootPart.AssemblyLinearVelocity = Vector3.new(
		moveDir.X * IMPULSO_EXPLOSIVO_XZ,
		IMPULSO_EXPLOSIVO_Y,
		moveDir.Z * IMPULSO_EXPLOSIVO_XZ
	)
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

	table.clear(_conns)

	isHoldingSpace = false
	isFloating = false
	isSlamming = false
	estabaSuspendido = false

	FX.Iniciar()

	ENV.AFO_GRAVATTACK_API = {
		IsActive = function()
			return _isActive
		end,
		IsFloating = function()
			return isFloating
		end,
	}

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

			local suspendido = EstaSuspendido()

			if isFloating or suspendido then
				-- Saltar durante la suspensión la termina (Suspension.lua) y sigues volando.
				if suspendido then
					CancelarSuspension()
				end

				if animReSalto then
					animReSalto:Play(0.1)
					animReSalto:AdjustSpeed(2)
				end

				local velActual = rootPart.AssemblyLinearVelocity
				local deltaV = IMPULSO_EXPLOSIVO_Y - velActual.Y

				isFloating = true
				EncenderFuerzas()

				rootPart.AssemblyLinearVelocity = Vector3.new(
					velActual.X,
					IMPULSO_EXPLOSIVO_Y,
					velActual.Z
				)

				-- Reacción: el impulso hacia arriba empuja una ráfaga de aire hacia abajo.
				FX.RafagaAbajo(deltaV)
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
		-- Los efectos se dibujan siempre, para que el desvanecimiento termine bien.
		FX.Render(dt)

		if not _isActive
			or isSlamming
			or not humanoid
			or not rootPart
			or not humanoid.Parent then
			return
		end

		-- Suspensión (Suspension.lua) toma el control mientras la plataforma exista.
		local suspendido = EstaSuspendido()

		if suspendido ~= estabaSuspendido then
			estabaSuspendido = suspendido

			if suspendido then
				ApagarFuerzas()
				FX.Cancelar()

				if animVuelo and animVuelo.IsPlaying then
					animVuelo:Stop(0.2)
				end
			elseif isFloating then
				-- Si ya estabas volando antes de la plataforma, continuarás volando.
				EncenderFuerzas()

				if animVuelo then
					animVuelo:Play(0.2)
				end
			end
		end

		if suspendido then
			if not isHoldingSpace then
				holdTimer = 0
			end

			return
		end

		-- El suelo SÍ desactiva el vuelo (con un pequeño margen para no cortarlo por un cuadro).
		if isFloating then
			if EstaEnElSuelo() then
				tSuelo += dt

				if tSuelo > 0.08 then
					tSuelo = 0
					isFloating = false
					ApagarFuerzas()
					DetenerAnimacionesCustom(0.3)
				end
			else
				tSuelo = 0
			end
		end

		if isHoldingSpace then
			if not isFloating then
				holdTimer += dt

				local requerido = ObtenerTiempoRequerido()

				if holdTimer > requerido then
					ActivarAntigravedad()
				else
					-- El viento se va formando al ritmo del retardo (dinámico): no aparece al
					-- tocar Space, empieza tras una fracción del retardo y llega a 1 justo
					-- cuando se pierde la gravedad (con curva suave para que arranque flojito).
					local inicio = math.min(
						math.max(requerido * INICIO_VISUAL_FRACCION, INICIO_VISUAL_MIN),
						requerido * 0.8
					)

					if holdTimer > inicio then
						FX.Cargar(((holdTimer - inicio) / (requerido - inicio)) ^ 1.6)
					end
				end
			end
		elseif not isFloating then
			holdTimer = 0
			FX.Cancelar()
		end

		if isFloating then
			ActualizarFuerzas()
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
	LimpiarConexionesPersonaje()

	ENV.AFO_GRAVATTACK_API = nil

	DetenerAnimacionesCustom(0)
	DestruirFuerzas()
	FX.Destruir()

	isHoldingSpace = false
	isFloating = false
	isSlamming = false
	holdTimer = 0
	estabaSuspendido = false

	if rootPart and character and character.Parent then
		local velActual = rootPart.AssemblyLinearVelocity

		rootPart.AssemblyLinearVelocity = Vector3.new(
			velActual.X,
			math.min(velActual.Y, 0),
			velActual.Z
		)
	end
end

-- Compatibilidad con el hub: la tecla de la plataforma ahora es de Suspension.lua.
function M.SetKey(kc)
	local api = ObtenerSuspension()

	if api and api.SetKey then
		api.SetKey(kc)
	end
end

function M.IsActive()
	return _isActive
end

return M
