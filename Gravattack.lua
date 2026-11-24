--[[
	Gravattack.lua  (v2)

	Space (mantener)  -> la gravedad pierde: salto enorme + planeo antigravitacional
	Ctrl              -> slam (ZAAASH) contra el suelo / la cabeza de un objetivo
	Space en vuelo    -> ráfaga de aire hacia abajo (cono de aire presionado) + re-salto

	La suspensión aérea (tecla C) vive ahora en Suspension.lua (menú con F8).
	Los dos módulos se hablan por ENV.AFO_GRAVATTACK_API / ENV.AFO_SUSPENSION_API.

	Cambios de esta versión:
	  1) Onda magnética azul que se forma mientras mantienes Space y se suelta al perder la gravedad.
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

-- Onda magnética (visual)
local COLOR_DOMO = Color3.fromRGB(0, 110, 255)         -- saturado: pálido se ve como vidrio
local COLOR_ONDA = Color3.fromRGB(35, 140, 255)
local COLOR_ONDA_BORDE = Color3.fromRGB(165, 225, 255)
local COLOR_ONDA_FONDO = Color3.fromRGB(8, 30, 110)
local COLOR_AIRE = Color3.fromRGB(215, 240, 255)
local RADIO_ONDA = 11                -- radio final de la cúpula
local DISTANCIA_SUELO_ONDA = 16      -- si el suelo está más lejos, la onda se arma en tus pies
local DURACION_ONDA_LIBERACION = 0.3 -- anillo que sale disparado al perder la gravedad
local DESVANECER_CANCELAR = 0.09     -- soltar Space antes de tiempo: casi instantáneo
local DESVANECER_FINAL = 0.14        -- al completarse la carga
local ANILLOS_CAMPO = 5
local ANILLOS_PULSO = 2

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
	if not (rootPart and humanoid and fuerzaVel and antiGravedad) then return end

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
	local domo, suelo, ondaLiberacion, salpicadura
	local anillosCampo, anillosPulso, anillosCono = {}, {}, {}
	local parteChispas, emisorChispas, parteAire, emisorAire

	local estado = {
		activo = false,
		cargando = false,
		carga = 0,
		intensidad = 0,
		t = 0,
		desvanecer = nil,
		faseDesv = 0,
		destello = 0,
		onda = nil,
		congelar = false,
		baseCF = CFrame.identity,
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
	local function SmoothStep(a, b, x)
		local k = math.clamp((x - a) / (b - a), 0, 1)
		return k * k * (3 - 2 * k)
	end

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

	-- Anillo plano dibujado con SurfaceGui (círculo + UIStroke): sin assets externos,
	-- visible desde arriba y desde abajo, y escala con el tamaño de la parte.
	local function CrearAnillo(colorBorde, conRelleno)
		local a = {
			parte = NuevaParte("AnilloFX"),
			guis = {},
			nucleos = {},
			halos = {},
			rellenos = {},
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

				local s
				if grosor then
					s = Instance.new("UIStroke")
					s.Thickness = grosor
					s.Color = color
					s.Transparency = 1
					s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
					s.Parent = f
				end

				return f, s
			end

			if conRelleno then
				local relleno = NuevoMarco(nil, nil, 1)
				relleno.BackgroundColor3 = COLOR_ONDA_FONDO
				a.rellenos[i] = relleno
			end

			local _, halo = NuevoMarco(16, COLOR_ONDA, 2)
			local _, nucleo = NuevoMarco(5, colorBorde, 3)

			a.guis[i] = gui
			a.halos[i] = halo
			a.nucleos[i] = nucleo
		end

		return a
	end

	local function PonerAnillo(a, cf, radio, alfa, alfaRelleno)
		alfa = math.clamp(alfa or 0, 0, 1)
		alfaRelleno = math.clamp(alfaRelleno or 0, 0, 1)

		if alfa < 0.01 and alfaRelleno < 0.01 then
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

			if a.rellenos[i] then
				a.rellenos[i].BackgroundTransparency = 1 - alfaRelleno
			end
		end
	end

	local function PiesActuales()
		if not rootPart or not rootPart.Parent then return nil end

		local alto = (humanoid and humanoid.HipHeight or 2) + rootPart.Size.Y / 2
		return rootPart.Position - Vector3.new(0, alto, 0)
	end

	-- Base de la onda: el suelo bajo tus pies, o tus pies si estás muy alto.
	local function ObtenerBase()
		local pies = PiesActuales() or Vector3.zero

		rayParams.FilterDescendantsInstances = { character, carpeta }

		local res = workspace:Raycast(
			pies + Vector3.new(0, 1.5, 0),
			Vector3.new(0, -DISTANCIA_SUELO_ONDA, 0),
			rayParams
		)

		if res then
			local n = res.Normal
			if n.Y < 0.6 then
				n = Vector3.yAxis
			end
			return res.Position, n
		end

		return pies, Vector3.yAxis
	end

	local function BaseCF(pos, arriba)
		local x = arriba:Cross(Vector3.zAxis)
		if x.Magnitude < 0.001 then
			x = Vector3.xAxis
		end
		return CFrame.fromMatrix(pos, x.Unit, arriba)
	end

	-- ---------- construcción ----------
	local function Preparar()
		if carpeta and carpeta.Parent then return true end

		carpeta = Instance.new("Folder")
		carpeta.Name = "AFO_GravattackFX"
		carpeta.Parent = workspace

		domo = NuevaParte("Domo")
		domo.Shape = Enum.PartType.Ball
		domo.Material = Enum.Material.ForceField
		domo.Color = COLOR_DOMO

		suelo = CrearAnillo(COLOR_ONDA_BORDE, true)
		ondaLiberacion = CrearAnillo(COLOR_ONDA_BORDE, false)
		salpicadura = CrearAnillo(COLOR_AIRE, false)

		anillosCampo, anillosPulso, anillosCono = {}, {}, {}

		for i = 1, ANILLOS_CAMPO do
			anillosCampo[i] = CrearAnillo(COLOR_ONDA_BORDE, false)
		end

		for i = 1, ANILLOS_PULSO do
			anillosPulso[i] = CrearAnillo(COLOR_ONDA_BORDE, false)
		end

		for i = 1, ANILLOS_CONO do
			anillosCono[i] = CrearAnillo(COLOR_AIRE, false)
		end

		-- Chispas que suben alrededor de tus pies mientras cargas
		parteChispas = NuevaParte("Chispas")
		emisorChispas = Instance.new("ParticleEmitter")
		emisorChispas.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		emisorChispas.Color = ColorSequence.new(COLOR_ONDA_BORDE, COLOR_ONDA)
		emisorChispas.LightEmission = 1
		emisorChispas.LightInfluence = 0
		emisorChispas.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.55),
			NumberSequenceKeypoint.new(1, 0),
		})
		emisorChispas.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.7, 0.3),
			NumberSequenceKeypoint.new(1, 1),
		})
		emisorChispas.Lifetime = NumberRange.new(0.5, 0.9)
		emisorChispas.Speed = NumberRange.new(4, 10)
		emisorChispas.Drag = 0.5
		emisorChispas.Acceleration = Vector3.new(0, 10, 0)
		emisorChispas.SpreadAngle = Vector2.new(35, 35)
		emisorChispas.EmissionDirection = Enum.NormalId.Top
		emisorChispas.Shape = Enum.ParticleEmitterShape.Disc
		emisorChispas.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
		emisorChispas.Rate = 0
		emisorChispas.Parent = parteChispas

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

	-- ---------- onda magnética ----------
	local function OcultarOnda()
		if not carpeta then return end

		domo.Transparency = 1
		PonerAnillo(suelo, CFrame.identity, 1, 0, 0)
		PonerAnillo(ondaLiberacion, CFrame.identity, 1, 0)

		for _, a in ipairs(anillosCampo) do
			PonerAnillo(a, CFrame.identity, 1, 0)
		end

		for _, a in ipairs(anillosPulso) do
			PonerAnillo(a, CFrame.identity, 1, 0)
		end

		emisorChispas.Rate = 0
	end

	local function RenderOnda(dt)
		if not estado.activo then return end

		if not rootPart or not rootPart.Parent then
			estado.activo = false
			OcultarOnda()
			return
		end

		estado.t += dt

		if estado.desvanecer then
			estado.faseDesv += dt / estado.desvanecer
			estado.intensidad = math.max(0, 1 - estado.faseDesv)
		end

		estado.destello = math.max(0, estado.destello - dt * 8)

		local ondaViva = false

		if estado.onda then
			estado.onda += dt
			ondaViva = estado.onda < DURACION_ONDA_LIBERACION

			if not ondaViva then
				estado.onda = nil
			end
		end

		if estado.intensidad <= 0 and not ondaViva then
			estado.activo = false
			estado.desvanecer = nil
			estado.congelar = false
			OcultarOnda()
			return
		end

		local cf
		if estado.congelar then
			cf = estado.baseCF
		else
			local centro, arriba = ObtenerBase()
			cf = BaseCF(centro, arriba)
		end

		local p = estado.carga
		local radio = RADIO_ONDA * (0.12 + 0.88 * p ^ 1.4)
		local fuerza = estado.intensidad * (0.3 + 0.7 * p)

		-- Cúpula (ForceField): aparece lenta con la carga, destello al soltarse
		domo.Size = Vector3.new(radio * 2, radio * 2, radio * 2)
		domo.CFrame = cf
		domo.Transparency = math.clamp(1 - 0.55 * fuerza - 0.35 * estado.destello, 0.05, 1)

		-- Disco del suelo con borde brillante
		PonerAnillo(suelo, cf * CFrame.new(0, 0.12, 0), radio, fuerza, fuerza * 0.55)

		-- Líneas de campo: aros que suben por la cúpula siguiendo su superficie
		local velCampo = 0.8 + 1.6 * p

		for i, a in ipairs(anillosCampo) do
			local u = ((i - 1) / #anillosCampo + estado.t * velCampo) % 1
			local h = u * radio * 0.96
			local r = math.sqrt(math.max(radio * radio - h * h, 0))
			local alfa = fuerza * (1 - u) ^ 0.7 * SmoothStep(0, 0.1, u)

			PonerAnillo(a, cf * CFrame.new(0, h + 0.12, 0), r, alfa)
		end

		-- Pulsos magnéticos: ondas planas que salen de tus pies hacia el borde
		local velPulso = 1.5 + 1.8 * p

		for i, a in ipairs(anillosPulso) do
			local fase = (estado.t * velPulso + (i - 1) / #anillosPulso) % 1

			PonerAnillo(
				a,
				cf * CFrame.new(0, 0.1, 0),
				radio * (0.1 + 0.9 * fase),
				fuerza * (1 - fase) ^ 1.3 * 0.9
			)
		end

		-- Anillo de liberación: sale disparado cuando la gravedad pierde
		if ondaViva then
			local k = estado.onda / DURACION_ONDA_LIBERACION
			local e = 1 - (1 - k) ^ 3

			PonerAnillo(
				ondaLiberacion,
				cf * CFrame.new(0, 0.15, 0),
				RADIO_ONDA * (0.35 + 1.5 * e),
				(1 - k) ^ 1.4
			)
		else
			PonerAnillo(ondaLiberacion, CFrame.identity, 1, 0)
		end

		-- Chispas
		parteChispas.CFrame = cf
		parteChispas.Size = Vector3.new(radio * 2, 0.2, radio * 2)

		if estado.cargando and not estado.desvanecer then
			emisorChispas.Rate = 6 + 50 * p
		else
			emisorChispas.Rate = 0
		end
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

		RenderOnda(dt)
		RenderCono(dt)
	end

	-- Llamar cada cuadro mientras se mantiene el salto: p va de 0 a 1.
	function FX.Cargar(p)
		if not Preparar() then return end

		estado.activo = true
		estado.cargando = true
		estado.desvanecer = nil
		estado.congelar = false
		estado.carga = math.clamp(p, 0, 1)
		estado.intensidad = 1
	end

	-- Soltaste antes de tiempo (o algo lo interrumpió): se apaga casi al instante.
	function FX.Cancelar()
		if not estado.activo or estado.desvanecer then return end

		estado.cargando = false
		estado.desvanecer = DESVANECER_CANCELAR
		estado.faseDesv = 0
	end

	-- La gravedad perdió: la onda se completa, dispara el anillo y se desvanece.
	function FX.Liberar()
		if not Preparar() then return end

		local centro, arriba = ObtenerBase()

		estado.baseCF = BaseCF(centro, arriba)
		estado.congelar = true
		estado.activo = true
		estado.cargando = false
		estado.carga = math.max(estado.carga, 0.75)
		estado.intensidad = 1
		estado.destello = 1
		estado.onda = 0
		estado.desvanecer = DESVANECER_FINAL
		estado.faseDesv = 0

		parteChispas.CFrame = estado.baseCF
		emisorChispas:Emit(26)
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
		estado.activo = false
		estado.desvanecer = nil
		estado.onda = nil
		estado.congelar = false
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

		local state = humanoid:GetState()

		local inAir = (
			state == Enum.HumanoidStateType.Jumping
			or state == Enum.HumanoidStateType.Freefall
		)

		-- El suelo SÍ desactiva el vuelo.
		if not inAir then
			if isFloating then
				isFloating = false
				ApagarFuerzas()
				DetenerAnimacionesCustom(0.3)
			end

			if not isHoldingSpace then
				holdTimer = 0
			end
		end

		if isHoldingSpace then
			if not isFloating then
				holdTimer += dt

				local requerido = ObtenerTiempoRequerido()

				if holdTimer > requerido then
					ActivarAntigravedad()
				else
					-- La onda se va formando al ritmo exacto del retardo (dinámico).
					FX.Cargar(holdTimer / requerido)
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
