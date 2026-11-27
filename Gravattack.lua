local M = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

local ENV = (typeof(getgenv) == "function" and getgenv()) or _G

local POTENCIA_ASCENSO = 2
local ALTURA_DESPEGUE = 60
local TIEMPO_ASCENSO_DESPEGUE = 0.45
local ACEL_ASCENSO_BURST = 900
local IMPULSO_EXPLOSIVO_XZ = 120

local ALTURA_SALTO_AEREO = 28
local TIEMPO_SALTO_AEREO = 0.35
local ALTURA_MEGA_AEREO = 60
local TIEMPO_ASCENSO_MEGA_AEREO = 0.5
local TIEMPO_MEGA_AEREO = 0.4
local MEGA_AEREO_REPETIBLE = true

local TIEMPO_ACTIVAR = 0.75
local TIEMPO_ACTIVAR_TRAS_SLAM = 0.45
local TIEMPO_ACTIVAR_HERIDO = 0.25
local VELOCIDAD_VUELO = 92
local VELOCIDAD_CAIDA_PLANEO = 0
local VELOCIDAD_SUSTENTACION = 0
local DESCENSO_AL_AVANZAR = 1

local ACEL_HORIZONTAL = 320
local ACEL_FRENADO = 240
local ACEL_EXCESO_VELOCIDAD = 70
local GIRO_BOOST_VUELO = 1.0
local ACEL_VERTICAL_EMPUJAR = 170
local ACEL_VERTICAL_FRENAR_SOSTENIENDO = 45
local ACEL_VERTICAL_FRENAR_SUELTO = 170

local DISTANCIA_OBJETIVO_SLAM = 30
local TIEMPO_PEGADO_CABEZA = 0.22
local VELOCIDAD_DESCENSO_SLAM = -140

local AJUSTE_ALTURA_CABEZA_SLAM = -3.5

local PREDICCION_MOVIMIENTO_SLAM = 0.12
local TIEMPO_GUIADO_DESCENSO_SLAM = 0.38
local DISTANCIA_MAX_CORRECCION_SLAM = 24
local ALCANCE_VERTICAL_HITBOX_SLAM = 3
local MARGEN_SEGURO_SUELO_SLAM = 0.75

local COLOR_AFO = Color3.fromRGB(255, 214, 20)
local COLOR_AFO_CLARO = Color3.fromRGB(255, 232, 70)
local COLOR_AFO_OSCURO = Color3.fromRGB(230, 170, 10)
local COLOR_RAYO = Color3.fromRGB(255, 222, 40)
local COLOR_ESPINA_OSCURA = Color3.fromRGB(55, 45, 20)
local COLOR_AIRE = Color3.fromRGB(255, 212, 30)
local COLOR_AIRE_OSCURO = Color3.fromRGB(205, 150, 10)
local ALFA_MAX = 0.75

local FLY_RING = "rbxassetid://12914395250"
local FLY_AIRSHOCK = "rbxassetid://112096280571499"
local FLY_STREAK = "rbxassetid://106822944701902"
local IDS_MEGA = {
	shock = "rbxassetid://117592591478260",
	sfx = "rbxassetid://111391583223900",
	caminar = "rbxassetid://46196309",
	dash_atras = "rbxassetid://82718659527221",
	dash_der = "rbxassetid://93831708296422",
}

local IDS_SFX = {
	elevar = "rbxassetid://97849925223786",
	aterrizaje = "rbxassetid://121663969839080",
}

local INICIO_VISUAL_FRACCION = 0.45
local INICIO_VISUAL_MIN = 0.1
local ANILLOS_CARGA = 2
local RADIO_CARGA = 4.5
local PERIODO_CARGA = 0.45

local DURACION_ONDA_PIES = 0.32
local RADIO_ONDA_PIES = 8
local VELOCIDAD_CHORRO = 85
local ARRASTRE_AIRE = 3.2
local ANGULO_CONO_GRADOS = 20
local RADIO_BASE_CHORRO = 1.4
local ANILLOS_CONO = 7
local SEPARACION_PARCELAS = 0.028
local VIDA_PARCELA = 0.4
local DURACION_SALPICADURA = 0.28
local DELTA_V_REF = (POTENCIA_ASCENSO + 1) * ALTURA_DESPEGUE / TIEMPO_ASCENSO_DESPEGUE - VELOCIDAD_CAIDA_PLANEO

local VIENTO_ACTIVO = true
local VIENTO_VEL_MIN = 12
local VIENTO_VEL_MAX = 130
local VIENTO_MAX_RAYAS = 18
local DURACION_IMPACTO = 0.3
local RADIO_IMPACTO = 6

local ALTURA_MIN_EPICA = 8
local ALTURA_CAIDA_MAX = 1500
local ALTURA_IMPACTO_MIN = 12
local EFECTO_ATERRIZAJE_NATURAL = true
local ALTURA_REF_IMPACTO_NATURAL = 45

local CONTROL_VERTICAL_CON_CAMARA = true
local ZONA_MUERTA_PITCH = 0.12
local VELOCIDAD_ASCENSO_MAX = 85
local VELOCIDAD_PICADA_MAX = 130
local REDUCCION_H_ASCENSO = 0.15
local ACEL_ASCENSO = 200
local ACEL_PICADA = 240
local VELOCIDAD_BOOST = 1.7
local TECLA_DASH = Enum.KeyCode.Q

local DISTANCIA_DASH = 215
local DURACION_DASH = 0.8
local VELOCIDAD_SALIDA_DASH = 70
local ACEL_INERCIA_DASH = 50
local INERCIA_DASH = 1.6
local GIRO_DASH = 4.5
local ZONA_MUERTA_Y_DASH = 0.15
local ESCALA_ONDA_MEGA = 0.55
local ENFRIAMIENTO_DASH = 0.35
local DISTANCIA_DASH_ATRAS = 100
local DURACION_DASH_ATRAS = 0.9
local DISTANCIA_DASH_LATERAL = 75
local DURACION_DASH_LATERAL = 0.8
local BUFFER_DASH = 0.18
local ACEL_DASH = 100000

local AGARRE_ACTIVO = true
local AGARRE_DISTANCIA = 14
local AGARRE_ANTICIPACION = 0.05
local AGARRE_TOLERANCIA = 12
local AGARRE_DURACION = 0.15
local AGARRE_DETRAS = true
local AGARRE_RADIO = 4.5
local AGARRE_AJUSTE_Y = 0
local AGARRE_SOLTAR_RETROCEDER = true
local AGARRE_RIGIDEZ = 60
local AGARRE_MARGEN_VACIO = 80

local IMPACTO_VEL_Y_MIN = 30
local IMPACTO_ESCALA_VEL = 0.45

local VEL_ANIM_CAMINAR = 1.5
local FADE_CAMINAR = 0.25

local TP_Y_REPETICIONES = 4
local TP_Y_ALTURAS = { 0.6, 0, 0.3, 0 }

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
local animCaminar
local animDashAtras, animDashDer

local fuerzaAttach, fuerzaVel, antiGravedad = nil, nil, nil
local vuelo = { ult = 0 }

local dash = { tipo = "adelante", bufferTipo = "adelante", buffer = 0, fin = 0, listo = 0, dir = Vector3.zero, t0 = 0, dur = 1.2, v0 = 0, c = 0, ult = 0, inerciaFin = 0 }
local ascenso = { t0 = 0, dur = 0, v0 = 0 }

local function IniciarAscenso(altura, dur)
	ascenso.t0 = tick()
	ascenso.dur = dur
	ascenso.v0 = (POTENCIA_ASCENSO + 1) * altura / dur
	return ascenso.v0
end

local function DireccionCamara(cam)
	local d = cam.CFrame.LookVector
	local y = d.Y

	if math.abs(y) < ZONA_MUERTA_Y_DASH then
		y = 0
	else
		y = y - math.sign(y) * ZONA_MUERTA_Y_DASH
	end

	local v = Vector3.new(d.X, y, d.Z)

	return v.Magnitude > 0.01 and v.Unit or d
end

local function GirarHacia(actual, deseada, maxRad)
	local ang = math.acos(math.clamp(actual:Dot(deseada), -1, 1))

	if ang < 1e-3 or maxRad <= 0 then return actual end

	local t = math.min(1, maxRad / ang)

	if t >= 1 then return deseada end

	local r = CFrame.lookAt(Vector3.zero, actual):Lerp(CFrame.lookAt(Vector3.zero, deseada), t).LookVector

	return r.Magnitude > 0.01 and r.Unit or actual
end

local function ResolverImpulso(D, T, vh)
	T = math.max(T, 0.1)
	D = math.max(D, vh * T * 1.01)

	local lo, hi = 1e-4, 60

	for _ = 1, 50 do
		local c = (lo + hi) / 2

		if vh * (math.exp(c * T) - 1) / c < D then
			lo = c
		else
			hi = c
		end
	end

	local c = (lo + hi) / 2

	return vh * math.exp(c * T), c
end

local function VelocidadImpulso(k)
	return dash.v0 * math.exp(-dash.c * math.clamp(k, 0, 1) * dash.dur)
end

local mega = {
	activo = false,
	t0 = 0,
	dir = Vector3.zero,
	agarre = nil,
}

local paramsPersonaje = RaycastParams.new()
paramsPersonaje.FilterType = Enum.RaycastFilterType.Exclude
paramsPersonaje.RespectCanCollide = true

local filtroDe = nil

local function ParamsPersonaje()
	if filtroDe ~= character then
		filtroDe = character
		paramsPersonaje.FilterDescendantsInstances = { character }
	end

	return paramsPersonaje
end

local function EsFinito(v)
	return v.X == v.X and v.Y == v.Y and v.Z == v.Z
		and math.abs(v.X) < 1e9 and math.abs(v.Y) < 1e9 and math.abs(v.Z) < 1e9
end

local function PosicionPies(char, raiz, hum, snap)
	char, raiz, hum = char or character, raiz or rootPart, hum or humanoid

	if not (raiz and raiz.Parent) then return nil end

	local alto = (hum and hum.HipHeight or 2) + raiz.Size.Y / 2
	local fallback = raiz.Position - Vector3.new(0, alto, 0)

	if not char then return fallback end

	local minY, sx, sz, n = math.huge, 0, 0, 0

	for _, nombre in ipairs({ "LeftFoot", "RightFoot", "Left Leg", "Right Leg" }) do
		local p = char:FindFirstChild(nombre)

		if p and p:IsA("BasePart") then
			local cf, s = p.CFrame, p.Size
			local mitad = 0.5 * (math.abs(cf.RightVector.Y) * s.X + math.abs(cf.UpVector.Y) * s.Y
				+ math.abs(cf.LookVector.Y) * s.Z)

			minY = math.min(minY, cf.Position.Y - mitad)
			sx += cf.Position.X
			sz += cf.Position.Z
			n += 1
		end
	end

	if n == 0 then return fallback end

	local pos = Vector3.new(sx / n, minY, sz / n)

	local rp

	if char == character then
		rp = ParamsPersonaje()
	else
		rp = RaycastParams.new()
		rp.FilterType = Enum.RaycastFilterType.Exclude
		rp.FilterDescendantsInstances = { char }
		rp.RespectCanCollide = true
	end

	local alcanceSuelo = snap or 3
	local hit = workspace:Raycast(pos + Vector3.new(0, 2, 0), Vector3.new(0, -(2 + alcanceSuelo), 0), rp)

	if hit then
		pos = Vector3.new(pos.X, hit.Position.Y, pos.Z)
	end

	return pos
end

local AJUSTES = {
	{ id = "ALTURA_DESPEGUE", nombre = "Altura del despegue (studs)", tipo = "number", min = 5, max = 400,
		get = function() return ALTURA_DESPEGUE end, set = function(v) ALTURA_DESPEGUE = v end },
	{ id = "ALTURA_SALTO_AEREO", nombre = "Altura salto aéreo (studs)", tipo = "number", min = 2, max = 200,
		get = function() return ALTURA_SALTO_AEREO end, set = function(v) ALTURA_SALTO_AEREO = v end },
	{ id = "ALTURA_MEGA_AEREO", nombre = "Altura mega salto aéreo (studs)", tipo = "number", min = 5, max = 400,
		get = function() return ALTURA_MEGA_AEREO end, set = function(v) ALTURA_MEGA_AEREO = v end },
	{ id = "TIEMPO_MEGA_AEREO", nombre = "Mantener Space para mega salto (s)", tipo = "number", min = 0.1, max = 2,
		get = function() return TIEMPO_MEGA_AEREO end, set = function(v) TIEMPO_MEGA_AEREO = v end },
	{ id = "MEGA_AEREO_REPETIBLE", nombre = "Encadenar mega saltos al mantener", tipo = "bool",
		get = function() return MEGA_AEREO_REPETIBLE end, set = function(v) MEGA_AEREO_REPETIBLE = v end },
	{ id = "VELOCIDAD_CAIDA_PLANEO", nombre = "Descenso al planear (negativo = baja)", tipo = "number", min = -60, max = 0,
		get = function() return VELOCIDAD_CAIDA_PLANEO end, set = function(v) VELOCIDAD_CAIDA_PLANEO = v end },
	{ id = "VELOCIDAD_SUSTENTACION", nombre = "Descenso con Space mantenido", tipo = "number", min = -20, max = 5,
		get = function() return VELOCIDAD_SUSTENTACION end, set = function(v) VELOCIDAD_SUSTENTACION = v end },
	{ id = "ACEL_VERTICAL_FRENAR_SOSTENIENDO", nombre = "Freno de subida (Space mantenido)", tipo = "number", min = 0.5, max = 100,
		get = function() return ACEL_VERTICAL_FRENAR_SOSTENIENDO end, set = function(v) ACEL_VERTICAL_FRENAR_SOSTENIENDO = v end },
	{ id = "ACEL_VERTICAL_FRENAR_SUELTO", nombre = "Freno de subida (Space suelto)", tipo = "number", min = 0.5, max = 100,
		get = function() return ACEL_VERTICAL_FRENAR_SUELTO end, set = function(v) ACEL_VERTICAL_FRENAR_SUELTO = v end },
	{ id = "DISTANCIA_DASH", nombre = "Distancia del impulso (studs)", tipo = "number", min = 20, max = 800,
			get = function() return DISTANCIA_DASH end, set = function(v) DISTANCIA_DASH = v end },
	{ id = "DURACION_DASH", nombre = "Duración del impulso (s)", tipo = "number", min = 0.2, max = 1.5,
			get = function() return DURACION_DASH end, set = function(v) DURACION_DASH = v end },
	{ id = "ENFRIAMIENTO_DASH", nombre = "Enfriamiento mega impulso (s)", tipo = "number", min = 0, max = 5,
			get = function() return ENFRIAMIENTO_DASH end, set = function(v) ENFRIAMIENTO_DASH = v end },
	{ id = "ESCALA_ONDA_MEGA", nombre = "Tamaño de los anillos del impulso", tipo = "number", min = 0.1, max = 1.5,
			get = function() return ESCALA_ONDA_MEGA end, set = function(v) ESCALA_ONDA_MEGA = v end },
	{ id = "GIRO_DASH", nombre = "Giro del impulso con la cámara (rad/s)", tipo = "number", min = 0, max = 15,
			get = function() return GIRO_DASH end, set = function(v) GIRO_DASH = v end },
	{ id = "DISTANCIA_DASH_ATRAS", nombre = "Distancia dash atrás (studs)", tipo = "number", min = 20, max = 600,
			get = function() return DISTANCIA_DASH_ATRAS end, set = function(v) DISTANCIA_DASH_ATRAS = v end },
	{ id = "DISTANCIA_DASH_LATERAL", nombre = "Distancia dash lateral (studs)", tipo = "number", min = 20, max = 600,
			get = function() return DISTANCIA_DASH_LATERAL end, set = function(v) DISTANCIA_DASH_LATERAL = v end },
	{ id = "AGARRE_TOLERANCIA", nombre = "Tolerancia lateral del agarre (studs)", tipo = "number", min = 1, max = 60,
			get = function() return AGARRE_TOLERANCIA end, set = function(v) AGARRE_TOLERANCIA = v end },
	{ id = "TIEMPO_ACTIVAR", nombre = "Mantener Space para activar (s)", tipo = "number", min = 0.1, max = 3,
			get = function() return TIEMPO_ACTIVAR end, set = function(v) TIEMPO_ACTIVAR = v end },
	{ id = "VIENTO_ACTIVO", nombre = "Hilos de viento al subir/bajar", tipo = "bool",
			get = function() return VIENTO_ACTIVO end, set = function(v) VIENTO_ACTIVO = v end },
	{ id = "AGARRE_SOLTAR_RETROCEDER", nombre = "Soltar agarre al retroceder", tipo = "bool",
			get = function() return AGARRE_SOLTAR_RETROCEDER end, set = function(v) AGARRE_SOLTAR_RETROCEDER = v end },
	{ id = "AGARRE_ACTIVO", nombre = "Agarre al objetivo tras el impulso", tipo = "bool",
			get = function() return AGARRE_ACTIVO end, set = function(v) AGARRE_ACTIVO = v end },
	{ id = "AGARRE_DISTANCIA", nombre = "Distancia 'cerca' del agarre (studs)", tipo = "number", min = 2, max = 80,
			get = function() return AGARRE_DISTANCIA end, set = function(v) AGARRE_DISTANCIA = v end },
	{ id = "AGARRE_DURACION", nombre = "Duración del agarre (s)", tipo = "number", min = 0.05, max = 2,
			get = function() return AGARRE_DURACION end, set = function(v) AGARRE_DURACION = v end },
	{ id = "ALFA_MAX", nombre = "Opacidad de efectos", tipo = "number", min = 0.05, max = 1,
		get = function() return ALFA_MAX end, set = function(v) ALFA_MAX = v end },
}
local holdAereo = { activo = false, t = 0, hecho = false }

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
	if animCaminar and animCaminar.IsPlaying then animCaminar:Stop(fadeTime) end
	if animDashAtras and animDashAtras.IsPlaying then animDashAtras:Stop(fadeTime) end
	if animDashDer and animDashDer.IsPlaying then animDashDer:Stop(fadeTime) end
end

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

	if mega.agarre then
		fuerzaVel.VectorVelocity = mega.agarre.vel
		fuerzaVel.MaxAxesForce = Vector3.new(masa * ACEL_DASH, masa * ACEL_DASH, masa * ACEL_DASH)
		return
	end

	if tick() < dash.fin then
		local ahora = tick()
		local dtImp = math.clamp(ahora - dash.ult, 0, 0.1)
		local cam = workspace.CurrentCamera

		dash.ult = ahora

		if cam and dash.tipo == "adelante" then
			local nueva = GirarHacia(dash.dir, DireccionCamara(cam), GIRO_DASH * dtImp)

			if EsFinito(nueva) and nueva.Magnitude > 0.5 then
				dash.dir = nueva
			end
		end

		local k = (ahora - dash.t0) / math.max(dash.dur, 0.05)

		fuerzaVel.VectorVelocity = dash.dir * VelocidadImpulso(k)
		fuerzaVel.MaxAxesForce = Vector3.new(masa * ACEL_DASH, masa * ACEL_DASH, masa * ACEL_DASH)
		return
	end

	local escribiendo = UserInputService:GetFocusedTextBox() ~= nil
	local boost = not escribiendo and UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
	local mult = boost and VELOCIDAD_BOOST or 1

	local objetivoXZ = Vector3.zero
	local vertical = 0

	if conInput then
		local factorH = 1
		local cam = workspace.CurrentCamera

		if CONTROL_VERTICAL_CON_CAMARA and cam then
			local look = cam.CFrame.LookVector
			local plano = Vector3.new(look.X, 0, look.Z)

			if plano.Magnitude > 0.01 then
				local avance = moveDir:Dot(plano.Unit)

				if avance > 0.3 then
					local mag = (math.abs(look.Y) - ZONA_MUERTA_PITCH) / (1 - ZONA_MUERTA_PITCH)

					if mag > 0 then
						if look.Y > 0 then
							vertical = mag * avance * VELOCIDAD_ASCENSO_MAX * mult
							factorH = 1 - REDUCCION_H_ASCENSO * mag
						else
							vertical = -mag * avance * VELOCIDAD_PICADA_MAX * mult
						end
					end
				end
			end
		end

		objetivoXZ = moveDir * VELOCIDAD_VUELO * mult * factorH
	end

	local objetivoY

	if isHoldingSpace then
		objetivoY = VELOCIDAD_SUSTENTACION
	elseif conInput then
		objetivoY = VELOCIDAD_CAIDA_PLANEO * DESCENSO_AL_AVANZAR
	else
		objetivoY = VELOCIDAD_CAIDA_PLANEO
	end

	if vertical > 0 then
		objetivoY = math.max(objetivoY, vertical)
	elseif vertical < 0 then
		objetivoY = math.min(objetivoY, vertical)
	end

	local ahora = tick()
	local dt = ahora - vuelo.ult

	dt = dt > 0.25 and 1 / 60 or math.clamp(dt, 1 / 240, 0.1)
	vuelo.ult = ahora

	local velH = Vector3.new(velActual.X, 0, velActual.Z)
	local rapH = velH.Magnitude
	local aXZ

	if conInput then
		local rapObj = objetivoXZ.Magnitude
		local alineado = (rapH > 1 and rapObj > 1) and velH.Unit:Dot(objetivoXZ.Unit) or 1

		if rapH > rapObj + 1 and alineado > 0.5 then
			aXZ = ACEL_EXCESO_VELOCIDAD
		else
			aXZ = ACEL_HORIZONTAL * (1 + GIRO_BOOST_VUELO * (1 - alineado) / 2)
		end
	elseif ahora < dash.inerciaFin then
		aXZ = ACEL_INERCIA_DASH
	else
		aXZ = ACEL_FRENADO
	end

	aXZ = aXZ * (boost and 1.3 or 1)

	local aY

	if objetivoY < velActual.Y then
		if vertical < 0 then
			aY = ACEL_PICADA
		else
			aY = isHoldingSpace and ACEL_VERTICAL_FRENAR_SOSTENIENDO or ACEL_VERTICAL_FRENAR_SUELTO
		end
	else
		aY = vertical > 0 and ACEL_ASCENSO or ACEL_VERTICAL_EMPUJAR
	end

	if ascenso.dur > 0 then
		local k = (ahora - ascenso.t0) / ascenso.dur

		if k < 1 then
			objetivoY = math.max(objetivoY, ascenso.v0 * (1 - k) ^ POTENCIA_ASCENSO)
			aY = ACEL_ASCENSO_BURST
		else
			ascenso.dur = 0
		end
	end

	local deltaH = objetivoXZ - velH
	local pasoH = aXZ * dt
	local nuevaH = deltaH.Magnitude <= pasoH and objetivoXZ or velH + deltaH.Unit * pasoH

	local deltaY = objetivoY - velActual.Y
	local pasoY = aY * dt
	local nuevaY = math.abs(deltaY) <= pasoY and objetivoY or velActual.Y + math.sign(deltaY) * pasoY

	fuerzaVel.VectorVelocity = Vector3.new(nuevaH.X, nuevaY, nuevaH.Z)
	fuerzaVel.MaxAxesForce = Vector3.new(masa * aXZ * 2, masa * aY * 2, masa * aXZ * 2)
end

local FX = {}

do
	local carpeta
	local anillosCono = {}
	local anillosCarga = {}
	local salpicadura, ondaPies, ondaImpacto
	local parteAire, emisorAire, emisorChispasAire
	local parteCarga, emisorChispasCarga
	local parteImpacto, emisorHumoImpacto, emisorChispasImpacto
	local parteDash, emisorHumoDash, emisorChispasDash

	local carga = { objetivo = 0, alfa = 0, t = 0 }

	local onda = { activa = false, t = 0, s = 1, pos = Vector3.zero }

	local impacto = { activo = false, t = 0, s = 1, pos = Vector3.zero }

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
		return PosicionPies()
	end

	local function CrearAnillo()
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
				gui.Brightness = 1.2
			end)
			gui.Parent = a.parte

			local function NuevaImagen(escala, textura, color, zindex)
				local img = Instance.new("ImageLabel")
				img.AnchorPoint = Vector2.new(0.5, 0.5)
				img.Position = UDim2.fromScale(0.5, 0.5)
				img.Size = UDim2.fromScale(escala, escala)
				img.BackgroundTransparency = 1
				img.Image = textura
				img.ImageColor3 = color
				img.ImageTransparency = 1
				img.ScaleType = Enum.ScaleType.Fit
				img.ZIndex = zindex
				img.Parent = gui

				return img
			end

			a.guis[i] = gui
			a.halos[i] = NuevaImagen(1, FLY_RING, COLOR_AFO, 1)
			a.nucleos[i] = NuevaImagen(0.72, FLY_RING, COLOR_AFO_CLARO, 2)
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
			a.nucleos[i].ImageTransparency = 1 - alfa
			a.halos[i].ImageTransparency = 1 - alfa * 0.6
		end
	end

	local function OcultarAnillos(lista)
		for _, a in ipairs(lista) do
			PonerAnillo(a, CFrame.identity, 1, 0)
		end
	end

	local function CrearHumo(padre, direccion, velMin, velMax, apertura)
		local e = Instance.new("ParticleEmitter")
		e.Texture = FLY_AIRSHOCK
		e.Color = ColorSequence.new(COLOR_AIRE, COLOR_AIRE_OSCURO)
		e.LightEmission = 0.2
		e.LightInfluence = 0
		e.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.6),
			NumberSequenceKeypoint.new(1, 2.6),
		})
		e.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.78),
			NumberSequenceKeypoint.new(1, 1),
		})
		e.Lifetime = NumberRange.new(0.3, 0.55)
		e.Speed = NumberRange.new(velMin, velMax)
		e.Drag = 3
		e.SpreadAngle = Vector2.new(apertura, apertura)
		e.EmissionDirection = direccion
		e.Rotation = NumberRange.new(0, 360)
		e.RotSpeed = NumberRange.new(-60, 60)
		e.Rate = 0
		e.Parent = padre
		return e
	end

	local function CrearChispas(padre, direccion, velMin, velMax, apertura)
		local e = Instance.new("ParticleEmitter")
		e.Texture = FLY_STREAK
		e.Color = ColorSequence.new(COLOR_AFO_CLARO, COLOR_AFO)
		e.LightEmission = 0.5
		e.LightInfluence = 0
		e.Orientation = Enum.ParticleOrientation.VelocityParallel
		e.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.9),
			NumberSequenceKeypoint.new(1, 0),
		})
		e.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.6),
			NumberSequenceKeypoint.new(1, 1),
		})
		e.Lifetime = NumberRange.new(0.18, 0.34)
		e.Speed = NumberRange.new(velMin, velMax)
		e.Drag = 2
		e.SpreadAngle = Vector2.new(apertura, apertura)
		e.EmissionDirection = direccion
		e.Rate = 0
		e.Parent = padre
		return e
	end

	local function Preparar()
		if carpeta and carpeta.Parent then return true end

		carpeta = Instance.new("Folder")
		carpeta.Name = "AFO_GravattackFX"
		carpeta.Parent = workspace

		anillosCono, anillosCarga = {}, {}

		for i = 1, ANILLOS_CONO do
			anillosCono[i] = CrearAnillo()
		end

		for i = 1, ANILLOS_CARGA do
			anillosCarga[i] = CrearAnillo()
		end

		salpicadura = CrearAnillo()
		ondaPies = CrearAnillo()
		ondaImpacto = CrearAnillo()

		parteAire = NuevaParte("ChorroAire")
		emisorAire = CrearHumo(parteAire, Enum.NormalId.Bottom, VELOCIDAD_CHORRO * 0.65, VELOCIDAD_CHORRO, ANGULO_CONO_GRADOS)
		emisorAire.Lifetime = NumberRange.new(0.25, 0.38)
		emisorAire.Drag = ARRASTRE_AIRE
		emisorChispasAire = CrearChispas(parteAire, Enum.NormalId.Bottom, VELOCIDAD_CHORRO * 0.5, VELOCIDAD_CHORRO * 0.9, ANGULO_CONO_GRADOS + 10)

		parteCarga = NuevaParte("CargaPies")
		emisorChispasCarga = CrearChispas(parteCarga, Enum.NormalId.Top, 5, 11, 40)

		parteImpacto = NuevaParte("Impacto")
		emisorHumoImpacto = CrearHumo(parteImpacto, Enum.NormalId.Top, 8, 16, 75)
		emisorChispasImpacto = CrearChispas(parteImpacto, Enum.NormalId.Top, 14, 28, 65)

		parteDash = NuevaParte("DashAereo")
		emisorHumoDash = CrearHumo(parteDash, Enum.NormalId.Front, 12, 30, 25)
		emisorChispasDash = CrearChispas(parteDash, Enum.NormalId.Front, 25, 55, 20)

		return true
	end

	local function RenderCarga(dt)

		local vel = carga.objetivo > carga.alfa and 6 or 16
		carga.alfa += (carga.objetivo - carga.alfa) * math.min(dt * vel, 1)

		local pies = PiesActuales()

		if carga.alfa < 0.01 or not pies then
			if carga.objetivo == 0 then carga.alfa = 0 end
			OcultarAnillos(anillosCarga)
			emisorChispasCarga.Rate = 0
			return
		end

		carga.t += dt

		parteCarga.CFrame = CFrame.new(pies + Vector3.new(0, 0.2, 0))
		emisorChispasCarga.Rate = 16 * carga.alfa

		for i, a in ipairs(anillosCarga) do
			local fase = (carga.t / PERIODO_CARGA + (i - 1) / #anillosCarga) % 1
			local radio = 0.9 + RADIO_CARGA * (1 - fase)
			local aparicion = math.sin(fase * math.pi)

			PonerAnillo(
				a,
				CFrame.new(pies + Vector3.new(0, 0.12, 0)),
				radio,
				carga.alfa * aparicion * ALFA_MAX * 0.8
			)
		end
	end

	local function RenderOnda(dt)
		if not onda.activa then return end

		onda.t += dt

		local k = onda.t / DURACION_ONDA_PIES

		if k >= 1 then
			onda.activa = false
			PonerAnillo(ondaPies, CFrame.identity, 1, 0)
			return
		end

		local e = 1 - (1 - k) ^ 3

		PonerAnillo(
			ondaPies,
			CFrame.new(onda.pos + Vector3.new(0, 0.12, 0)),
			1.2 + RADIO_ONDA_PIES * e * onda.s,
			onda.s * (1 - k) ^ 1.4 * ALFA_MAX
		)
	end

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

				PonerAnillo(a, CFrame.new(pos), radio, s * (1 - k) ^ 1.2 * ALFA_MAX)
			end
		end

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
					s * (1 - k) ^ 1.3 * ALFA_MAX
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

	local function Aterrizar(pos, s)
		impacto.activo = true
		impacto.t = 0
		impacto.s = s
		impacto.pos = pos

		parteImpacto.CFrame = CFrame.new(pos + Vector3.new(0, 0.15, 0))
		emisorHumoImpacto:Emit(math.floor(8 * s + 0.5))
		emisorChispasImpacto:Emit(math.floor(10 * s + 0.5))
	end

	local function RenderImpacto(dt)
		if not impacto.activo then return end

		impacto.t += dt

		local k = impacto.t / DURACION_IMPACTO

		if k >= 1 then
			impacto.activo = false
			PonerAnillo(ondaImpacto, CFrame.identity, 1, 0)
			return
		end

		local e = 1 - (1 - k) ^ 3

		PonerAnillo(
			ondaImpacto,
			CFrame.new(impacto.pos + Vector3.new(0, 0.12, 0)),
			1 + RADIO_IMPACTO * e * impacto.s,
			impacto.s * (1 - k) ^ 1.3 * ALFA_MAX
		)
	end

	local function Impulsar(s)
		local pies = PiesActuales()
		if not pies then return end

		carga.objetivo = 0
		carga.alfa = 0
		OcultarAnillos(anillosCarga)
		emisorChispasCarga.Rate = 0

		onda.activa = true
		onda.t = 0
		onda.s = s
		onda.pos = pies

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
		emisorAire:Emit(math.floor(12 * s + 0.5))
		emisorChispasAire:Emit(math.floor(10 * s + 0.5))

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

	local E = {}

	E.impulso = { activo = false, t0 = 0, dur = 0.6, fin = 0, dir = Vector3.zAxis, fuerza = 1, accEstela = 0, ondaPend = false, ondaEn = 0 }
	E.NSEG = 20
	E.NLINEAS = 10
	E.MAX_ANILLOS = 8
	E.anillosElec = {}
	E.poolAnillos = {}

	function E.Az(a, b)
		return a + math.random() * (b - a)
	end

	function E.SonidoLocal(id, volumen, velocidad)
		local s = Instance.new("Sound")
		s.SoundId = id
		s.Volume = volumen
		s.PlaybackSpeed = velocidad or 1
		s.RollOffMaxDistance = 0
		s.Parent = game:GetService("SoundService")
		s:Play()

		task.delay(10, function()
			pcall(function()
				s:Destroy()
			end)
		end)
	end

	function E.AuraEn(pos, px0, px1, dur, alfa, imagen)
		if not carpeta then return end

		local ancla = Instance.new("Part")
		ancla.Name = "AnclaAura"
		ancla.Anchored = true
		ancla.CanCollide = false
		ancla.CanQuery = false
		ancla.CanTouch = false
		ancla.CastShadow = false
		ancla.Transparency = 1
		ancla.Size = Vector3.new(0.2, 0.2, 0.2)
		ancla.Position = pos
		ancla.Parent = carpeta

		local bb = Instance.new("BillboardGui")
		bb.Adornee = ancla
		bb.AlwaysOnTop = false
		bb.LightInfluence = 0
		bb.Size = UDim2.fromOffset(px0, px0)
		bb.ResetOnSpawn = false
		bb.Parent = ancla

		local img = Instance.new("ImageLabel")
		img.Image = imagen or FLY_AIRSHOCK
		img.Size = UDim2.fromScale(1, 1)
		img.BackgroundTransparency = 1
		img.ImageColor3 = COLOR_AFO
		img.ImageTransparency = 1 - math.clamp(alfa, 0, 1)
		img.ScaleType = Enum.ScaleType.Fit
		img.Parent = bb

		TweenService:Create(bb, TweenInfo.new(dur, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
			{ Size = UDim2.fromOffset(px1, px1) }):Play()
		TweenService:Create(img, TweenInfo.new(dur, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
			{ ImageTransparency = 1 }):Play()

		task.delay(dur + 0.05, function()
			pcall(function()
				ancla:Destroy()
			end)
		end)
	end

	function E.ParteNeon(color, transp)
		local p = Instance.new("Part")
		p.Name = "SegmentoAnillo"
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Material = Enum.Material.Neon
		p.Color = color
		p.Transparency = transp
		p.Size = Vector3.new(0.2, 0.2, 0.2)
		return p
	end

	E.COS, E.SIN = {}, {}

	for i = 1, E.NSEG + 1 do
		local ang = (i - 1) / E.NSEG * math.pi * 2

		E.COS[i], E.SIN[i] = math.cos(ang), math.sin(ang)
	end

	local function OcultarAnillo(o)
		for _, p in ipairs(o.segs) do
			p.Transparency = 1
		end

		for _, p in ipairs(o.lineas) do
			p.Transparency = 1
		end
	end

	function E.TomarAnillo()
		local o = table.remove(E.poolAnillos)

		if o and o.folder.Parent then
			return o
		end

		local carp = Instance.new("Folder")
		carp.Name = "AnilloShigaraki"
		carp.Parent = carpeta

		local segs, lineas = {}, {}

		for i = 1, E.NSEG do
			segs[i] = E.ParteNeon(COLOR_RAYO, 1)
			segs[i].Parent = carp
		end

		for j = 1, E.NLINEAS do

			lineas[j] = E.ParteNeon(j % 3 == 0 and COLOR_ESPINA_OSCURA or COLOR_AFO_CLARO, 1)
			lineas[j].Parent = carp
		end

		return { folder = carp, segs = segs, lineas = lineas }
	end

	function E.NuevoAnillo(pos, dir, r0, r1, dur, grosor, retraso, entra, op)
		if not carpeta or #E.anillosElec >= E.MAX_ANILLOS then return end

		local arriba = math.abs(dir.Y) > 0.95 and Vector3.xAxis or Vector3.yAxis
		local lin = {}

		for j = 1, E.NLINEAS do
			lin[j] = {
				ang = ((j - 1) + E.Az(-0.3, 0.3)) / E.NLINEAS * math.pi * 2,
				largo = E.Az(0.6, 1.5),
				giro = E.Az(-0.6, 0.6),
				lado = (j % 2 == 0) and 1 or -1,
			}
		end

		table.insert(E.anillosElec, {
			o = E.TomarAnillo(), t = -(retraso or 0), dur = dur, r0 = r0, r1 = r1,
			base = CFrame.lookAt(pos, pos + dir, arriba), grosor = grosor,
			entra = entra == true, op = op or 1, lin = lin, puntos = {},
		})
	end

	function E.RenderAnillos(dt)
		for idx = #E.anillosElec, 1, -1 do
			local a = E.anillosElec[idx]

			a.t += dt

			if a.t >= a.dur or not a.o.folder.Parent then

				if a.o.folder.Parent then
					OcultarAnillo(a.o)
					table.insert(E.poolAnillos, a.o)
				end

				table.remove(E.anillosElec, idx)
			elseif a.t >= 0 then
				local k = a.t / a.dur
				local e = 1 - (1 - k) ^ 3
				local r = a.r0 + (a.r1 - a.r0) * e
				local fade = a.entra and (math.sin(k * math.pi) ^ 0.7) or (1 - k) ^ 1.2
				local transp = math.clamp(1 - fade * a.op, 0, 1)
				local grosor = a.grosor * (0.6 + r / 18) * (a.entra and 1 or (1 - 0.4 * k))
				local base = a.base
				local puntos = a.puntos
				local COS, SIN = E.COS, E.SIN

				for i = 1, E.NSEG + 1 do
					puntos[i] = base * Vector3.new(COS[i] * r, SIN[i] * r, 0)
				end

				for i = 1, E.NSEG do
					local p1, p2 = puntos[i], puntos[i + 1]
					local s = a.o.segs[i]

					s.Size = Vector3.new(grosor, grosor, (p2 - p1).Magnitude + grosor * 0.3)
					s.CFrame = CFrame.lookAt((p1 + p2) / 2, p2)
					s.Transparency = transp
				end

				local transpL = math.clamp(transp + 0.05, 0, 1)

				for j = 1, E.NLINEAS do
					local d = a.lin[j]
					local cx, cy = math.cos(d.ang) * r, math.sin(d.ang) * r
					local largo = d.largo * (0.5 + r / 12)
					local dx = math.cos(d.ang + d.giro) * d.lado * largo
					local dy = math.sin(d.ang + d.giro) * d.lado * largo
					local p1 = base * Vector3.new(cx, cy, 0)
					local p2 = base * Vector3.new(cx + dx, cy + dy, 0)
					local l = a.o.lineas[j]

					l.Size = Vector3.new(grosor * 0.45, grosor * 0.45, largo)
					l.CFrame = CFrame.lookAt((p1 + p2) / 2, p2)
					l.Transparency = transpL
				end
			end
		end
	end

	function E.Acumular(pos, dir, esc, fuerza)
		for i = 1, 3 do
			E.NuevoAnillo(pos - dir * (0.5 + 0.9 * (i - 1)), dir, (8 - 0.8 * (i - 1)) * esc, 2.6 * esc,
				0.16, 0.34, 0.035 * (i - 1), true, fuerza)
		end
	end

	function E.OndaAire(pos, dir, esc, fuerza)
		E.NuevoAnillo(pos, dir, 2 * esc, 11 * esc, 0.28, 0.36, 0, false, fuerza)
		E.NuevoAnillo(pos, dir, 1.5 * esc, 16 * esc, 0.34, 0.3, 0.05, false, 0.8 * fuerza)

		E.AuraEn(pos, 40, 230 * esc * fuerza, 0.30, 0.75 * fuerza, FLY_AIRSHOCK)
		E.AuraEn(pos, 50, 170 * esc * fuerza, 0.18, 0.65 * fuerza, IDS_MEGA.shock)
	end

	function E.CrearEstela(dir)
		local cam = workspace.CurrentCamera

		if not (rootPart and rootPart.Parent and cam and carpeta) then return end

		local lejos = -dir
		local pos = rootPart.Position + lejos * 1 + Vector3.new(E.Az(-1.6, 1.6), E.Az(-1.6, 1.6), E.Az(-1.6, 1.6))

		local haciaCam = cam.CFrame.Position - pos
		haciaCam = haciaCam.Magnitude > 0.01 and haciaCam.Unit or Vector3.new(0, 0, -1)

		local arriba = lejos.Unit
		local derecha = arriba:Cross(haciaCam)
		derecha = derecha.Magnitude < 0.01 and Vector3.xAxis or derecha.Unit
		local mira = derecha:Cross(arriba).Unit

		local parte = Instance.new("Part")
		parte.Name = "EstelaImpulso"
		parte.Anchored = true
		parte.CanCollide = false
		parte.CanQuery = false
		parte.CanTouch = false
		parte.CastShadow = false
		parte.Transparency = 1
		parte.Size = Vector3.new(0.14, 6, 0.1)
		parte.CFrame = CFrame.fromMatrix(pos, derecha, arriba, mira)
		parte.Parent = carpeta

		local sg = Instance.new("SurfaceGui")
		sg.Adornee = parte
		sg.Face = Enum.NormalId.Front
		sg.AlwaysOnTop = false
		sg.LightInfluence = 0
		sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		sg.PixelsPerStud = 50
		sg.Parent = parte

		local img = Instance.new("ImageLabel")
		img.Image = FLY_STREAK
		img.Size = UDim2.new(1, 0, 1, 0)
		img.BackgroundTransparency = 1
		img.ImageColor3 = math.random() < 0.5 and COLOR_AFO or COLOR_AFO_CLARO
		img.ImageTransparency = 0.25
		img.ScaleType = Enum.ScaleType.Fit
		img.Parent = sg

		local FADE = 0.35

		TweenService:Create(img, TweenInfo.new(FADE, Enum.EasingStyle.Linear), { ImageTransparency = 1 }):Play()
		TweenService:Create(parte, TweenInfo.new(FADE, Enum.EasingStyle.Linear),
			{ Position = pos + lejos * 5 }):Play()

		task.delay(FADE + 0.05, function()
			pcall(function()
				parte:Destroy()
			end)
		end)
	end

	E.viento = { acum = 0, libres = {}, vivos = {} }

	function E.TomarRaya()
		local r = table.remove(E.viento.libres)

		if r and r.p.Parent then
			return r
		end

		local p = E.ParteNeon(Color3.fromRGB(255, 255, 255), 1)
		p.Name = "VientoRaya"
		p.Parent = carpeta

		return { p = p, t = 0, vida = 0.3, op = 0.5 }
	end

	function E.RenderViento(dt)
		local v = E.viento

		for i = #v.vivos, 1, -1 do
			local r = v.vivos[i]

			r.t += dt

			local k = r.t / r.vida

			if k >= 1 or not r.p.Parent then
				if r.p.Parent then
					r.p.Transparency = 1
					table.insert(v.libres, r)
				end

				table.remove(v.vivos, i)
			else
				r.p.Transparency = r.op + (1 - r.op) * k * k
			end
		end

		local activo = VIENTO_ACTIVO and (isFloating or isSlamming) and rootPart and rootPart.Parent
			and humanoid and humanoid.Health > 0

		if not activo then
			v.acum = 0
			return
		end

		local vy = rootPart.AssemblyLinearVelocity.Y
		local rapidez = math.abs(vy)

		if rapidez < VIENTO_VEL_MIN then
			v.acum = 0
			return
		end

		local k = math.clamp((rapidez - VIENTO_VEL_MIN) / math.max(VIENTO_VEL_MAX - VIENTO_VEL_MIN, 1), 0, 1)
		local intervalo = 0.12 - 0.085 * k

		v.acum += dt

		if v.acum < intervalo then return end

		local n = math.min(math.floor(v.acum / intervalo), 3)

		v.acum = 0

		local signo = vy > 0 and 1 or -1
		local base = rootPart.Position

		for _ = 1, n do
			if #v.vivos >= VIENTO_MAX_RAYAS then break end

			local r = E.TomarRaya()
			local ang = math.random() * math.pi * 2
			local radio = E.Az(3.2, 9)
			local adelante = E.Az(4, 10 + 26 * k)
			local largo = (2.5 + 11.5 * k) * E.Az(0.7, 1.25)
			local grosor = 0.05 + 0.05 * k

			r.p.Size = Vector3.new(grosor, largo, grosor)
			r.p.CFrame = CFrame.new(base + Vector3.new(math.cos(ang) * radio, signo * adelante, math.sin(ang) * radio))
			r.op = 0.5 - 0.25 * k + E.Az(0, 0.12)
			r.p.Transparency = r.op
			r.t = 0
			r.vida = 0.28 + 0.12 * math.random()

			table.insert(v.vivos, r)
		end
	end

	function E.LineasCaida(origen, suelo)
		if not (carpeta and suelo) then return end

		local largo = math.min(origen.Y - suelo.Y, 140)

		if largo < 4 then return end

		for i = 1, 4 do
			local ang = math.random() * math.pi * 2
			local r = E.Az(0.5, 1.6)
			local len = largo * E.Az(0.5, 1)
			local techo = origen.Y - E.Az(0, largo - len)

			local p = E.ParteNeon(i % 2 == 0 and COLOR_AFO or COLOR_AFO_CLARO, 0.35)
			p.Size = Vector3.new(0.12, len, 0.12)
			p.Position = Vector3.new(origen.X + math.cos(ang) * r, techo - len / 2, origen.Z + math.sin(ang) * r)
			p.Parent = carpeta

			TweenService:Create(p, TweenInfo.new(0.35, Enum.EasingStyle.Linear), { Transparency = 1 }):Play()

			task.delay(0.4, function()
				pcall(function()
					p:Destroy()
				end)
			end)
		end
	end

	function E.RenderEstela(dt)
		local im = E.impulso

		if not im.activo then return end

		if tick() >= im.fin or not (rootPart and rootPart.Parent) then
			im.activo = false
			im.ondaPend = false
			return
		end

		local esc = ESCALA_ONDA_MEGA / 0.55

		if im.ondaPend and tick() >= im.ondaEn then
			im.ondaPend = false

			local pos = rootPart.Position - im.dir * 1.2
			local arriba = math.abs(im.dir.X) > 0.95 and Vector3.yAxis or Vector3.xAxis

			E.OndaAire(pos, im.dir, esc, im.fuerza)

			parteDash.CFrame = CFrame.lookAt(pos, pos - im.dir, arriba)
			emisorHumoDash:Emit(math.floor(8 * im.fuerza + 0.5))
			emisorChispasDash:Emit(math.floor(14 * im.fuerza + 0.5))
		end

		local kd = (tick() - im.t0) / math.max(im.dur, 0.05)

		im.accEstela += dt

		if im.accEstela >= 0.09 then
			im.accEstela = 0

			if kd < 0.85 then
				E.CrearEstela(im.dir)
			end
		end
	end

	function FX.Iniciar()
		Preparar()
	end

	function FX.Render(dt)
		if not carpeta then return end

		E.RenderEstela(dt)
		E.RenderAnillos(dt)
		RenderCarga(dt)
		RenderOnda(dt)
		RenderCono(dt)
		E.RenderViento(dt)
		RenderImpacto(dt)
	end

	function FX.Cargar(p)
		if not Preparar() then return end

		carga.objetivo = math.clamp(p, 0, 1)
	end

	function FX.Cancelar()
		carga.objetivo = 0
	end

	function FX.Liberar()
		if not Preparar() then return end

		Impulsar(1)
		E.SonidoLocal(IDS_SFX.elevar, 0.9, 1)

		local pies = PiesActuales()

		if pies then
			E.NuevoAnillo(pies + Vector3.new(0, 0.25, 0), Vector3.yAxis, 1.2, 6, 0.32, 0.3, 0, false, 1)
		end
	end

	function FX.RafagaAbajo(deltaV)
		if not Preparar() then return end

		local s = math.clamp((deltaV or DELTA_V_REF) / DELTA_V_REF, 0.35, 1.25)

		Impulsar(s)
		E.SonidoLocal(IDS_SFX.elevar, math.clamp(0.45 * s, 0.2, 0.7), 1.12)

		local pies = PiesActuales()

		if pies then
			E.NuevoAnillo(pies + Vector3.new(0, 0.25, 0), Vector3.yAxis, 1.0, 3.5 + 2.5 * s, 0.28, 0.26, 0, false, math.clamp(s, 0.5, 1))
		end
	end

	function FX.Impacto(pos, s)
		if not Preparar() or not pos then return end

		s = s or 1

		Aterrizar(pos, s)
		E.SonidoLocal(IDS_SFX.aterrizaje, math.clamp(0.3 + 0.45 * s, 0.2, 0.9), 1)
	end

	function FX.AnilloShigaraki(pos, dir, r0, r1, dur, grosor, retraso)
		if not Preparar() or not pos or not dir then return end

		E.NuevoAnillo(pos, dir, r0, r1, dur, grosor, retraso, false, 1)
	end

	function FX.Dash(dir, duracion, fuerza)
		if not Preparar() or not rootPart or not dir then return end

		fuerza = fuerza or 1

		local pos = rootPart.Position
		local esc = ESCALA_ONDA_MEGA / 0.55

		local dur = math.min(duracion or DURACION_DASH, 0.6)

		E.SonidoLocal(IDS_MEGA.sfx, 0.88 * fuerza, 1)

		E.Acumular(pos, dir, esc, fuerza)

		E.impulso.activo = true
		E.impulso.t0 = tick()
		E.impulso.dur = dur
		E.impulso.fin = tick() + dur + 0.12
		E.impulso.dir = dir
		E.impulso.fuerza = fuerza
		E.impulso.accEstela = 0
		E.impulso.ondaPend = true
		E.impulso.ondaEn = tick() + 0.14
	end

	function FX.SetDirDash(dir)
		if dir then
			E.impulso.dir = dir
		end
	end

	function FX.CaidaMega(origen, suelo, altura)
		if not Preparar() or not origen then return end

		local dir = Vector3.new(0, -1, 0)
		local esc = 0.75 * ESCALA_ONDA_MEGA / 0.55

		E.SonidoLocal(IDS_MEGA.sfx, 0.45, 1)
		E.Acumular(origen, dir, esc, 0.8)
		E.LineasCaida(origen, suelo)

		task.delay(0.14, function()
			if not carpeta then return end

			pcall(function()
				E.OndaAire(origen, dir, esc, 0.75)

				parteDash.CFrame = CFrame.lookAt(origen, origen - dir, Vector3.xAxis)
				emisorHumoDash:Emit(6)
				emisorChispasDash:Emit(8)
			end)
		end)
	end

	function FX.FinDash(inmediato)
		E.impulso.activo = false
	end

	function FX.Destruir()
		E.impulso.activo = false
		E.viento = { acum = 0, libres = {}, vivos = {} }
		E.anillosElec = {}
		E.poolAnillos = {}

		if carpeta then
			carpeta:Destroy()
		end

		carpeta = nil
		anillosCono, anillosCarga = {}, {}
		carga.objetivo, carga.alfa = 0, 0
		onda.activa = false
		impacto.activo = false
		cono.activo = false
		cono.impacto = nil
	end
end

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

local ID_CAIDA_BASE = "rbxassetid://287325678"
local ID_CAIDA_OVERLAY = "rbxassetid://70439247"
local ID_AIRE_ONDA = "rbxassetid://112096280571499"
local ID_PARTICULA = "rbxassetid://106822944701902"
local ID_ONDA_CIRCULO = "rbxassetid://5457833933"
local ID_SFX_ATERRIZAJE = "rbxassetid://135226467234227"
local ID_SFX_ATERRIZAJE_CRISTAL = "rbxassetid://132535085898211"

local seguimiento = { enAire = false, pico = 0, ultimo = 0, habilidad = false }
local tokenAterrizaje = 0

local function MarcarAterrizaje()
	seguimiento.ultimo = tick()
	seguimiento.enAire = false
	seguimiento.habilidad = false

	if rootPart then
		seguimiento.pico = rootPart.Position.Y
	end
end

local function Finito(v)
	return v.X == v.X and v.Y == v.Y and v.Z == v.Z
		and math.abs(v.X) < 1e9 and math.abs(v.Y) < 1e9 and math.abs(v.Z) < 1e9
end

local sacudidaConn, sacudidaBase, sacudidaAplicada

local function CfIgual(a, b)
	return (a.Position - b.Position).Magnitude < 1e-3
		and a.LookVector:Dot(b.LookVector) > 0.99999
		and a.UpVector:Dot(b.UpVector) > 0.99999
end

local function DetenerSacudida()
	if sacudidaConn then
		pcall(function()
			sacudidaConn:Disconnect()
		end)
		sacudidaConn = nil
	end

	local cam = workspace.CurrentCamera

	if cam and sacudidaBase and sacudidaAplicada
		and Finito(sacudidaBase.Position) and Finito(sacudidaBase.LookVector) then

		local ok, igual = pcall(function()
			return CfIgual(cam.CFrame, sacudidaAplicada)
		end)

		if ok and igual then
			pcall(function()
				cam.CFrame = sacudidaBase
			end)
		end
	end

	sacudidaBase = nil
	sacudidaAplicada = nil
end

local function SacudirCamara(intensidad, duracion)
	DetenerSacudida()

	if not workspace.CurrentCamera then return end
	if not intensidad or intensidad ~= intensidad or intensidad <= 0 then return end
	if not duracion or duracion ~= duracion or duracion <= 0 then return end

	local inicio = tick()

	sacudidaConn = RunService.RenderStepped:Connect(function()
		local cam = workspace.CurrentCamera

		if not cam then
			DetenerSacudida()
			return
		end

		local t = tick() - inicio

		if t >= duracion then
			DetenerSacudida()
			return
		end

		local base = cam.CFrame

		if sacudidaBase and sacudidaAplicada and CfIgual(base, sacudidaAplicada) then
			base = sacudidaBase
		end

		if not Finito(base.Position) or not Finito(base.LookVector) or not Finito(base.UpVector) then
			DetenerSacudida()
			return
		end

		local decaimiento = 1 - (t / duracion)
		local t2 = t * math.pi
		local ax = math.sin(t2 * 30) * intensidad * decaimiento
		local ay = math.sin(t2 * 25) * intensidad * decaimiento * 0.8
		local az = math.sin(t2 * 35) * intensidad * decaimiento * 0.6
		local aplicada = base * CFrame.Angles(math.rad(ax), math.rad(ay), math.rad(az))

		if not Finito(aplicada.Position) or not Finito(aplicada.LookVector) then
			DetenerSacudida()
			return
		end

		sacudidaBase = base
		sacudidaAplicada = aplicada

		pcall(function()
			cam.CFrame = aplicada
		end)
	end)
end

local function MedirAltura(raiz, char)
	if not raiz then return nil end

	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude
	rp.FilterDescendantsInstances = { char }
	rp.IgnoreWater = true
	pcall(function()
		rp.RespectCanCollide = true
	end)

	local origen = raiz.Position
	local res = workspace:Raycast(origen, Vector3.new(0, -5000, 0), rp)

	if not res then return nil end

	return math.max(0, origen.Y - res.Position.Y)
end

local function BuscarSueloSeguro(raiz, char)
	if not raiz then return nil end

	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude
	rp.FilterDescendantsInstances = { char }

	local desfases = {
		Vector3.new(0, 0, 0),
		Vector3.new(1.5, 0, 0), Vector3.new(-1.5, 0, 0),
		Vector3.new(0, 0, 1.5), Vector3.new(0, 0, -1.5),
		Vector3.new(1, 0, 1), Vector3.new(-1, 0, 1),
		Vector3.new(1, 0, -1), Vector3.new(-1, 0, -1),
	}

	local mejorY = nil

	for _, d in ipairs(desfases) do
		local res = workspace:Raycast(raiz.Position + d, Vector3.new(0, -3000, 0), rp)

		if res then
			local modelo = res.Instance:FindFirstAncestorWhichIsA("Model")

			if modelo and Players:GetPlayerFromCharacter(modelo) then
				return nil, true
			end
		end

		if res and res.Normal.Y > 0.5 then
			if mejorY == nil or res.Position.Y > mejorY then
				mejorY = res.Position.Y
			end
		end
	end

	if mejorY == nil then return nil end

	return Vector3.new(raiz.Position.X, mejorY, raiz.Position.Z)
end

local function NivelCaida(altura)
	if altura < ALTURA_MIN_EPICA then
		return 0
	end

	local t = math.clamp((altura - ALTURA_MIN_EPICA) / (ALTURA_CAIDA_MAX - ALTURA_MIN_EPICA), 0, 1)

	return 1 + t * 3
end

local function EfectosAterrizaje(posicion, velocidad)
	if not posicion then return end

	task.spawn(function()
		local intensidad = math.clamp(velocidad / 150, 0, 1)

		if intensidad < 0.05 then return end

		local nivel = math.clamp(math.floor(1 + intensidad * 3 + 0.5), 1, 4)
		local multEscala = 0.4 + intensidad * 1.2
		local multEmision = multEscala

		local parteFX = Instance.new("Part")
		parteFX.Name = "AFO_AterrizajeFX"
		parteFX.Size = Vector3.new(1, 1, 1)
		parteFX.Position = posicion + Vector3.new(0, 0.5, 0)
		parteFX.Anchored = true
		parteFX.CanCollide = false
		parteFX.CanQuery = false
		parteFX.CanTouch = false
		parteFX.Transparency = 1
		parteFX.Parent = workspace

		local destello = Instance.new("PointLight")
		destello.Color = COLOR_AFO_CLARO
		destello.Range = 40 * multEscala
		destello.Brightness = 15 * multEscala
		destello.Shadows = true
		destello.Parent = parteFX

		TweenService:Create(
			destello,
			TweenInfo.new(0.15 * multEscala, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out),
			{ Brightness = 0, Range = 0 }
		):Play()

		local excluirExtra = {}

		local function LanzarAlSuelo(origen, largo)
			local rp = RaycastParams.new()
			rp.FilterType = Enum.RaycastFilterType.Exclude
			rp.IgnoreWater = true
			pcall(function()
				rp.RespectCanCollide = true
			end)

			local lista = { parteFX }

			if character then
				table.insert(lista, character)
			end

			for _, e in ipairs(excluirExtra) do
				table.insert(lista, e)
			end

			for _ = 1, 5 do
				rp.FilterDescendantsInstances = lista

				local hit = workspace:Raycast(origen, Vector3.new(0, -largo, 0), rp)

				if not hit then return nil end

				local inst = hit.Instance

				if inst:IsA("BasePart") and not inst:IsA("Terrain") and inst.Transparency >= 0.95 then
					table.insert(lista, inst)
				else
					return hit
				end
			end

			return nil
		end

		local function InfoSuelo(hit)
			local color = Color3.fromRGB(120, 115, 110)
			local material = Enum.Material.Rock
			local variante = ""

			if hit then
				material = hit.Material
				local inst = hit.Instance

				if inst:IsA("Terrain") then
					pcall(function()
						color = workspace.Terrain:GetMaterialColor(hit.Material)
					end)
				elseif inst:IsA("BasePart") then
					color = inst.Color
					pcall(function()
						variante = inst.MaterialVariant or ""
					end)
				end
			end

			return color, material, variante
		end

		local materialImpacto = Enum.Material.Grass
		local polvoBase = Color3.fromRGB(200, 200, 205)

		do
			local temprano = LanzarAlSuelo(posicion + Vector3.new(0, 3, 0), 12)
				or LanzarAlSuelo(posicion + Vector3.new(0, 6, 0), 30)
				or LanzarAlSuelo(posicion + Vector3.new(0, 10, 0), 80)

			if temprano then
				materialImpacto = temprano.Material
				local c = InfoSuelo(temprano)
				polvoBase = c:Lerp(COLOR_AFO, 0.12)
			end
		end

		local polvoClaro = polvoBase:Lerp(COLOR_AFO_CLARO, 0.2)
		local polvoOscuro = polvoBase:Lerp(Color3.new(0, 0, 0), 0.25)

		local esCristal = materialImpacto == Enum.Material.Glass
			or materialImpacto == Enum.Material.ForceField
			or materialImpacto == Enum.Material.Ice

		local volumen = { 1.0, 2.5, 4.5, 7.0 }
		local tono = { 1.1, 0.85, 0.65, 0.5 }

		local sfx = Instance.new("Sound")
		sfx.SoundId = esCristal and ID_SFX_ATERRIZAJE_CRISTAL or ID_SFX_ATERRIZAJE
		sfx.Volume = volumen[nivel]
		sfx.PlaybackSpeed = tono[nivel]
		sfx.RollOffMaxDistance = 300 * multEscala
		sfx.Parent = parteFX
		sfx:Play()

		task.delay(8, function()
			pcall(function()
				sfx:Destroy()
			end)
		end)

		local adjunto = Instance.new("Attachment", parteFX)

		local adjPlano = Instance.new("Attachment", parteFX)
		adjPlano.Orientation = Vector3.new(0, 0, 0)

		local adjInclinado1 = Instance.new("Attachment", parteFX)
		adjInclinado1.Orientation = Vector3.new(35, 45, 0)

		local adjInclinado2 = Instance.new("Attachment", parteFX)
		adjInclinado2.Orientation = Vector3.new(-25, -60, 15)

		local function EscalarNS(ns, escala)
			local kps = {}

			for _, kp in ipairs(ns.Keypoints) do
				table.insert(kps, NumberSequenceKeypoint.new(kp.Time, kp.Value * escala, kp.Envelope * escala))
			end

			return NumberSequence.new(kps)
		end

		local function EscalarNR(nr, escala)
			return NumberRange.new(nr.Min * escala, nr.Max * escala)
		end

		local function EmitirAnillo(textura, adj, mult, color)
			local anillo = Instance.new("ParticleEmitter")
			anillo.Texture = textura
			anillo.Orientation = Enum.ParticleOrientation.VelocityPerpendicular
			anillo.EmissionDirection = Enum.NormalId.Top
			anillo.Speed = NumberRange.new(0.01)
			anillo.Size = EscalarNS(NumberSequence.new({
				NumberSequenceKeypoint.new(0, 2 * mult),
				NumberSequenceKeypoint.new(0.25, 38 * mult),
				NumberSequenceKeypoint.new(1, 78 * mult),
			}), multEscala)
			anillo.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.2),
				NumberSequenceKeypoint.new(0.3, 0.55),
				NumberSequenceKeypoint.new(0.65, 0.9),
				NumberSequenceKeypoint.new(1, 1),
			})
			anillo.Color = ColorSequence.new(color)
			anillo.Lifetime = NumberRange.new(0.4 + nivel * 0.04)
			anillo.LightEmission = 0.35
			anillo.Rate = 0
			anillo.Parent = adj
			anillo:Emit(2)

			task.delay(2, function()
				pcall(function()
					anillo:Destroy()
				end)
			end)
		end

		local blanco = Color3.fromRGB(255, 255, 255)

		EmitirAnillo(ID_ONDA_CIRCULO, adjPlano, 1.2, blanco)

		if nivel > 1 then
			EmitirAnillo(ID_PARTICULA, adjPlano, 1.4, blanco)
			EmitirAnillo(ID_ONDA_CIRCULO, adjInclinado1, 0.9, blanco)
			EmitirAnillo(ID_PARTICULA, adjInclinado2, 1.1, blanco)
		end

		local polvo1 = Instance.new("ParticleEmitter")
		polvo1.Texture = ID_CAIDA_BASE
		polvo1.Size = EscalarNS(NumberSequence.new({
			NumberSequenceKeypoint.new(0, 5),
			NumberSequenceKeypoint.new(0.2, 14),
			NumberSequenceKeypoint.new(1, 22),
		}), multEscala)
		polvo1.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.1, 0.1),
			NumberSequenceKeypoint.new(0.8, 0.7),
			NumberSequenceKeypoint.new(1, 1),
		})
		polvo1.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, polvoClaro),
			ColorSequenceKeypoint.new(0.6, polvoBase),
			ColorSequenceKeypoint.new(1, polvoOscuro),
		})
		polvo1.Lifetime = EscalarNR(NumberRange.new(1.2, 1.8), 1 + nivel * 0.1)
		polvo1.Speed = EscalarNR(NumberRange.new(55, 90), multEscala)
		polvo1.SpreadAngle = Vector2.new(180, 180)
		polvo1.RotSpeed = NumberRange.new(-250, 250)
		polvo1.Drag = 14
		polvo1.Acceleration = Vector3.new(0, -40 * multEscala, 0)
		polvo1.ZOffset = 2
		polvo1.Rate = 0
		polvo1.Parent = adjunto

		local polvo2 = Instance.new("ParticleEmitter")
		polvo2.Texture = ID_AIRE_ONDA
		polvo2.Size = polvo1.Size
		polvo2.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.3),
			NumberSequenceKeypoint.new(1, 1),
		})
		polvo2.Color = polvo1.Color
		polvo2.Lifetime = polvo1.Lifetime
		polvo2.Speed = polvo1.Speed
		polvo2.SpreadAngle = polvo1.SpreadAngle
		polvo2.RotSpeed = NumberRange.new(-50, 50)
		polvo2.Drag = polvo1.Drag
		polvo2.Acceleration = polvo1.Acceleration
		polvo2.ZOffset = 1
		polvo2.Rate = 0
		polvo2.Parent = adjunto

		local polvoVertical = Instance.new("ParticleEmitter")
		polvoVertical.Texture = ID_CAIDA_OVERLAY
		polvoVertical.EmissionDirection = Enum.NormalId.Top
		polvoVertical.Size = EscalarNS(NumberSequence.new({
			NumberSequenceKeypoint.new(0, 4),
			NumberSequenceKeypoint.new(1, 18),
		}), multEscala)
		polvoVertical.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.1),
			NumberSequenceKeypoint.new(0.7, 0.8),
			NumberSequenceKeypoint.new(1, 1),
		})
		polvoVertical.Color = ColorSequence.new(polvoBase)
		polvoVertical.Lifetime = EscalarNR(NumberRange.new(1.5, 2.5), 1 + nivel * 0.1)
		polvoVertical.Speed = EscalarNR(NumberRange.new(25, 55), multEscala)
		polvoVertical.SpreadAngle = Vector2.new(35, 35)
		polvoVertical.RotSpeed = NumberRange.new(-40, 40)
		polvoVertical.Drag = 7
		polvoVertical.Acceleration = Vector3.new(0, -10 * multEscala, 0)
		polvoVertical.ZOffset = 0
		polvoVertical.Rate = 0
		polvoVertical.Parent = adjunto

		polvo1:Emit(math.floor(50 * multEmision))
		polvo2:Emit(math.floor(40 * multEmision))
		polvoVertical:Emit(math.floor((nivel == 1 and 10 or 25) * multEmision))

		task.delay(8, function()
			pcall(function()
				parteFX:Destroy()
			end)
		end)

		if intensidad >= 0.15 then
			local escalaTam = multEscala * 0.7
			local escalaCant = multEmision * 0.7

			local carpetaCrater = Instance.new("Folder")
			carpetaCrater.Name = "AFO_CraterAterrizaje"
			carpetaCrater.Parent = workspace
			table.insert(excluirExtra, carpetaCrater)

			local colorSuelo, materialSuelo, varianteSuelo

			task.wait(0.15)

			local function GolpeSuelo(pos)
				return LanzarAlSuelo(pos + Vector3.new(0, 4, 0), 12)
					or LanzarAlSuelo(pos + Vector3.new(0, 4, 0), 30)
			end

			local function PosRaizActual()
				local pos = posicion

				if rootPart and rootPart.Parent then
					pos = rootPart.Position
				end

				return pos
			end

			local function IntentarSuelo()
				local cur = PosRaizActual()

				return LanzarAlSuelo(cur + Vector3.new(0, 5, 0), 25)
					or LanzarAlSuelo(cur + Vector3.new(0, 5, 0), 60)
					or LanzarAlSuelo(posicion + Vector3.new(0, 5, 0), 25)
					or LanzarAlSuelo(posicion + Vector3.new(0, 5, 0), 60)
			end

			local golpeSuelo = IntentarSuelo()

			if not golpeSuelo then
				task.wait(0.1)
				golpeSuelo = IntentarSuelo()
			end

			colorSuelo, materialSuelo, varianteSuelo = InfoSuelo(golpeSuelo)

			task.wait(0.05)

			local anillosRoca = {
				{
					piezas = math.max(4, math.floor(8 * escalaCant)),
					radio = 5 * escalaTam,
					mult = 1.0 * escalaTam,
				},
				{
					piezas = math.max(6, math.floor(12 * escalaCant)),
					radio = 10 * escalaTam,
					mult = 1.3 * escalaTam,
				},
				{
					piezas = math.max(8, math.floor(18 * escalaCant)),
					radio = 16 * escalaTam,
					mult = 1.6 * escalaTam,
				},
			}

			local rocas = {}

			for _, anillo in ipairs(anillosRoca) do
				for i = 1, anillo.piezas do
					local angulo = math.rad((360 / anillo.piezas) * i + math.random(-8, 8))
					local desfase = Vector3.new(math.cos(angulo) * anillo.radio, 0, math.sin(angulo) * anillo.radio)

					local roca = Instance.new("Part")
					roca.Size = Vector3.new(
						math.random(25, 45) / 10 * anillo.mult,
						math.random(15, 25) / 10 * (escalaTam ^ 0.5),
						math.random(35, 65) / 10 * anillo.mult
					)

					local posLateral = Vector3.new(posicion.X + desfase.X, posicion.Y, posicion.Z + desfase.Z)
					local golpeRoca = GolpeSuelo(posLateral)
					local sueloY = golpeRoca and golpeRoca.Position.Y or posicion.Y
					local cColor, cMaterial, cVariante = colorSuelo, materialSuelo, varianteSuelo

					if golpeRoca then
						cColor, cMaterial, cVariante = InfoSuelo(golpeRoca)
					end

					roca.Position = Vector3.new(
						posicion.X + desfase.X,
						sueloY - roca.Size.Y * 0.5,
						posicion.Z + desfase.Z
					)
					roca.Anchored = true
					roca.CanCollide = false
					roca.CanQuery = false
					roca.CanTouch = false

					pcall(function()
						roca.Material = cMaterial
					end)

					roca.Color = cColor

					if cVariante and cVariante ~= "" then
						pcall(function()
							roca.MaterialVariant = cVariante
						end)
					end

					if golpeRoca and golpeRoca.Instance:IsA("BasePart") and not golpeRoca.Instance:IsA("Terrain") then
						for _, hijo in ipairs(golpeRoca.Instance:GetChildren()) do
							if hijo:IsA("SurfaceAppearance") or hijo:IsA("Texture") then
								pcall(function()
									hijo:Clone().Parent = roca
								end)
							end
						end
					end

					local mira = CFrame.lookAt(roca.Position, Vector3.new(posicion.X, roca.Position.Y, posicion.Z))
					local inclinacion = math.rad(-math.random(30, 55) + (anillo.radio * 1.5 / escalaTam))
					local giro = math.rad(math.random(-15, 15))

					roca.CFrame = mira * CFrame.Angles(inclinacion, 0, giro)
					roca.Parent = carpetaCrater
					table.insert(rocas, roca)

					if esCristal then

						local dir = (desfase.Magnitude > 0.01 and desfase.Unit)
							or Vector3.new(math.random(-10, 10) / 10, 0, math.random(-10, 10) / 10)
						local distancia = (8 + math.random() * 14) * escalaTam
						local subida = (6 + math.random() * 10) * escalaTam
						local giroFuerte = math.rad(math.random(180, 720)) * (math.random() < 0.5 and -1 or 1)
						local destino = roca.CFrame + (dir * distancia) + Vector3.new(0, subida, 0)

						destino = destino * CFrame.Angles(giroFuerte, giroFuerte * 0.6, giroFuerte * 0.3)

						local tiempo = 0.5 + math.random() * 0.4

						TweenService:Create(
							roca,
							TweenInfo.new(tiempo, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
							{ CFrame = destino, Transparency = 1 }
						):Play()

						task.delay(tiempo + 0.05, function()
							pcall(function()
								roca:Destroy()
							end)
						end)
					else
						local arriba = roca.CFrame + Vector3.new(0, roca.Size.Y * 0.9, 0)

						TweenService:Create(
							roca,
							TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
							{ CFrame = arriba }
						):Play()
					end
				end
			end

			task.delay(3.5 + nivel * 0.5, function()
				for _, roca in ipairs(rocas) do
					if roca and roca.Parent then
						TweenService:Create(
							roca,
							TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
							{ CFrame = roca.CFrame - Vector3.new(0, roca.Size.Y * 2, 0) }
						):Play()
					end
				end

				task.delay(2, function()
					pcall(function()
						carpetaCrater:Destroy()
					end)
				end)
			end)
		end

		if intensidad >= 0.33 then
			SacudirCamara(2.0 + intensidad * 1.5, 0.30)
		else
			SacudirCamara(0.8 + intensidad * 3.6, 0.18)
		end
	end)
end

local function PiesDe(raiz, hum)
	return PosicionPies(raiz.Parent, raiz, hum, 8)
end

local function AterrizajeEpico(char, altura, conAnimacion, velocidad)
	if not char or not char.Parent then return end

	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then return end

	if NivelCaida(altura) <= 0 then return end

	local raiz = char:FindFirstChild("HumanoidRootPart")
	local anim = hum:FindFirstChildOfClass("Animator")

	tokenAterrizaje += 1
	local miToken = tokenAterrizaje

	DetenerAnimacionesCustom(0)

	local posicion = (raiz and Finito(raiz.Position)) and (PiesDe(raiz, hum) + Vector3.new(0, 0.05, 0))
		or Vector3.new(0, 0, 0)

	EfectosAterrizaje(posicion, velocidad or math.max(altura * 0.5, 22))

	if not conAnimacion or not anim then return end

	local scriptAnimate = char:FindFirstChild("Animate")

	if scriptAnimate then
		pcall(function()
			scriptAnimate.Disabled = true
		end)
	end

	local ok, tocando = pcall(function()
		return anim:GetPlayingAnimationTracks()
	end)

	if ok and tocando then
		for _, pista in ipairs(tocando) do
			pcall(function()
				pista:Stop(0)
			end)
		end
	end

	local idsAterrizaje = { [ID_CAIDA_BASE] = true, [ID_CAIDA_OVERLAY] = true }

	local connReproducida = anim.AnimationPlayed:Connect(function(pista)
		if pista.Animation and not idsAterrizaje[pista.Animation.AnimationId] then
			pcall(function()
				pista:Stop(0)
			end)
		end
	end)

	local function CargarPista(id, prioridad)
		local a = Instance.new("Animation")
		a.AnimationId = id

		local pista = anim:LoadAnimation(a)

		pcall(function()
			a:Destroy()
		end)

		pista.Priority = prioridad
		pista.Looped = true

		return pista
	end

	local pistaBase = CargarPista(ID_CAIDA_BASE, Enum.AnimationPriority.Action3)
	local pistaOverlay = CargarPista(ID_CAIDA_OVERLAY, Enum.AnimationPriority.Action4)

	pcall(function()
		pistaBase:Play(0.0, 1, 1)
		pistaOverlay:Play(0.0, 1, 1)
	end)

	local inicio = tick()
	local cancelado = false

	local connInput = UserInputService.InputBegan:Connect(function(input)
		if UserInputService:GetFocusedTextBox() then return end

		local kc = input.KeyCode

		if kc == Enum.KeyCode.W or kc == Enum.KeyCode.A or kc == Enum.KeyCode.S or kc == Enum.KeyCode.D
			or kc == Enum.KeyCode.Space or kc == Enum.KeyCode.Q or kc == Enum.KeyCode.F
			or kc == Enum.KeyCode.LeftShift or kc == Enum.KeyCode.LeftControl
			or input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then

			cancelado = true
		end
	end)

	local function Esperar(d)
		local t0 = tick()

		while tick() - t0 < d do
			if tokenAterrizaje ~= miToken then return "token" end
			if cancelado then return "cancel" end

			if tick() - inicio > 0.25 and hum.MoveDirection.Magnitude > 0.1 then
				cancelado = true
				return "cancel"
			end

			task.wait()
		end

		return nil
	end

	local function Terminar()
		connInput:Disconnect()
		connReproducida:Disconnect()
	end

	local fases = { { 0.06, 8.0 }, { 0.30, 0 }, { 0.45, 0.3 }, { 0.30, 1.0 } }
	local interrumpido = false

	for _, fase in ipairs(fases) do
		pcall(function()
			pistaBase:AdjustSpeed(fase[2])
			pistaOverlay:AdjustSpeed(fase[2])
		end)

		local r = Esperar(fase[1])

		if r == "token" then
			Terminar()
			return
		end

		if r == "cancel" then
			interrumpido = true
			break
		end
	end

	local desvanecer = interrumpido and 0.08 or 0.5

	pcall(function()
		pistaBase:Stop(desvanecer)
		pistaOverlay:Stop(desvanecer)
	end)

	if interrumpido then
		task.wait(0.08)
	elseif Esperar(0.5) == "token" then
		Terminar()
		return
	end

	Terminar()

	if tokenAterrizaje ~= miToken then return end

	pcall(function()
		pistaBase:Destroy()
		pistaOverlay:Destroy()
	end)

	if scriptAnimate then
		pcall(function()
			scriptAnimate.Disabled = false
		end)
	end

	if hum.Parent and hum.Health > 0 and not isFloating then
		pcall(function()
			hum:ChangeState(Enum.HumanoidStateType.Running)
		end)
	end
end

local function ForzarTPsY(yFinal, posXZ)
	local n = math.max(TP_Y_REPETICIONES, 1)
	local char = character

	local _, yaw = rootPart.CFrame:ToOrientation()

	local function Aplicar(i)
		if not (rootPart and rootPart.Parent and character == char) then return false end

		local p = rootPart.Position
		local desfase = (i < n) and (TP_Y_ALTURAS[(i - 1) % #TP_Y_ALTURAS + 1] or 0) or 0

		local base = (i == 1 and posXZ) or p

		rootPart.CFrame = CFrame.new(base.X, yFinal + desfase, base.Z) * CFrame.Angles(0, yaw, 0)
		rootPart.AssemblyLinearVelocity = Vector3.zero
		rootPart.AssemblyAngularVelocity = Vector3.zero

		return true
	end

	Aplicar(1)

	if n > 1 then
		task.spawn(function()
			for i = 2, n do
				RunService.Heartbeat:Wait()

				if not Aplicar(i) then return end
			end
		end)
	end
end

local function EnElAire()
	if not (humanoid and rootPart and character) then return false end

	if humanoid.FloorMaterial ~= Enum.Material.Air then return false end

	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude
	rp.FilterDescendantsInstances = { character }
	rp.RespectCanCollide = true

	local alcance = math.max(humanoid.HipHeight + rootPart.Size.Y / 2, 3) + 1.5

	return workspace:Raycast(rootPart.Position, Vector3.new(0, -alcance, 0), rp) == nil
end

local function CaidaEpica(altura, sueloDado, opciones)
	local suelo = sueloDado or BuscarSueloSeguro(rootPart, character)

	if not suelo then return false end

	local alturaPiernas = humanoid.HipHeight + (rootPart.Size.Y / 2)

	ForzarTPsY(suelo.Y + alturaPiernas, opciones and opciones.xz)

	humanoid.PlatformStand = false
	humanoid:ChangeState(Enum.HumanoidStateType.Landed)

	MarcarAterrizaje()

	local char = character

	task.spawn(AterrizajeEpico, char, altura, true, opciones and opciones.velocidad)

	task.delay(0.1, function()
		if not _isActive then return end

		isSlamming = false
		lastSlamEndTime = tick()
	end)

	return true
end

local function AterrizajeNatural(altura)
	if not EFECTO_ATERRIZAJE_NATURAL then return end
	if not (character and rootPart and humanoid) then return end

	FX.Impacto(PiesDe(rootPart, humanoid), math.clamp(altura / ALTURA_REF_IMPACTO_NATURAL, 0.3, 0.8))
end

local function RastrearAterrizaje()
	if not (humanoid and rootPart and humanoid.Parent and rootPart.Parent) or humanoid.Health <= 0 then
		seguimiento.enAire = false
		return
	end

	local py = rootPart.Position.Y
	local volando = isFloating

	if humanoid.FloorMaterial == Enum.Material.Air then
		if not seguimiento.enAire then
			seguimiento.enAire = true
			seguimiento.pico = py
		end

		if volando then
			seguimiento.habilidad = true
		end

		seguimiento.pico = math.max(seguimiento.pico, py)
		return
	end

	if seguimiento.enAire then
		seguimiento.enAire = false

		local altura = seguimiento.pico - py

		if seguimiento.habilidad and tick() - seguimiento.ultimo > 0.6 and altura >= ALTURA_IMPACTO_MIN then
			seguimiento.ultimo = tick()
			AterrizajeNatural(altura)
		end

		seguimiento.habilidad = false
	elseif not volando then

		seguimiento.habilidad = false
	end

	seguimiento.pico = py
end

local function PonerPoseBrazos(activa)
	if not animCaminar then return end

	if activa then
		if not animCaminar.IsPlaying then
			pcall(function()
				animCaminar:Play(0.1)
				animCaminar:AdjustSpeed(VEL_ANIM_CAMINAR)
			end)
		end
	elseif animCaminar.IsPlaying then
		pcall(function()
			animCaminar:Stop(FADE_CAMINAR)
		end)
	end
end

local tokenAnimDash = 0

local function ReproducirAnimDash(tipo)
	local pista = (tipo == "der") and animDashDer or animDashAtras

	if not pista then return end

	tokenAnimDash += 1

	local miToken = tokenAnimDash

	task.spawn(function()
		local limite = tick() + 2

		while pista.Length == 0 and tick() < limite do
			task.wait()
		end

		if miToken ~= tokenAnimDash or not mega.activo then return end

		pcall(function()
			if pista.IsPlaying then
				pista:Stop(0)
			end

			pista.Looped = false
			pista.Priority = Enum.AnimationPriority.Action4
			pista:Play(0.04, 1, 1)
			pista:AdjustSpeed(3.0)
		end)
	end)
end

local function PararAnimDash()
	tokenAnimDash += 1

	for _, pista in ipairs({ animDashAtras, animDashDer }) do
		if pista and pista.IsPlaying then
			pcall(function()
				pista:Stop(0.1)
			end)
		end
	end
end

local IniciarDash

local function TerminarMega()
	if not mega.activo then return end

	mega.activo = false
	dash.fin = 0

	PonerPoseBrazos(false)
	PararAnimDash()
	FX.FinDash()
end

local function PosicionEnVacio(pos)
	return pos.Y < workspace.FallenPartsDestroyHeight + AGARRE_MARGEN_VACIO
end

local function ObtenerObjetivoLock()
	if not (character and rootPart) then return nil end

	local act = character:FindFirstChild("AFO_LockActive")
	local tgt = character:FindFirstChild("AFO_LockedTarget")

	if not (act and tgt and act.Value == true and typeof(tgt.Value) == "Instance") then return nil end

	local jug = tgt.Value

	if jug == player then return nil end

	local ch = jug:IsA("Player") and jug.Character or (jug:IsA("Model") and jug or nil)
	local hum = ch and ch:FindFirstChildOfClass("Humanoid")
	local r = ch and ch:FindFirstChild("HumanoidRootPart")

	if hum and r and hum.Health > 0 then
		return r
	end

	return nil
end

local function QuiereRetroceder()
	if not humanoid or UserInputService:GetFocusedTextBox() then return false end

	local cam = workspace.CurrentCamera
	local md = humanoid.MoveDirection

	if not cam or md.Magnitude < 0.1 then return false end

	local look = cam.CFrame.LookVector
	local plano = Vector3.new(look.X, 0, look.Z)

	if plano.Magnitude < 0.01 then return false end

	return md.Unit:Dot(plano.Unit) < -0.5
end

local function SoltarAgarre()
	if not mega.agarre then return end

	mega.agarre = nil

	dash.inerciaFin = tick() + INERCIA_DASH
end

local function IniciarAgarre(troot)
	local tpos = troot.Position
	local lado

	if AGARRE_DETRAS then

		local atras = -troot.CFrame.LookVector

		lado = Vector3.new(atras.X, 0, atras.Z)
	else

		lado = Vector3.new(rootPart.Position.X - tpos.X, 0, rootPart.Position.Z - tpos.Z)
	end

	lado = lado.Magnitude > 0.01 and lado.Unit or Vector3.zAxis

	mega.agarre = { t0 = tick(), root = troot, vel = troot.AssemblyLinearVelocity, lado = lado, primera = true }

	mega.activo = false
	dash.fin = 0

	PonerPoseBrazos(false)
	FX.FinDash()

	pcall(FX.AnilloShigaraki, tpos, dash.dir, 1, 5, 0.25, 0.3, 0)
end

local function RevisarAgarre(dt)
	if not AGARRE_ACTIVO or mega.agarre or dash.tipo ~= "adelante" then return false end

	if AGARRE_SOLTAR_RETROCEDER and QuiereRetroceder() then return false end

	local troot = ObtenerObjetivoLock()

	if not troot then return false end

	local vel = rootPart.AssemblyLinearVelocity
	local rapidez = vel.Magnitude

	if rapidez < 1 then return false end

	local dirV = vel / rapidez
	local hacia = troot.Position - rootPart.Position
	local dist = hacia.Magnitude
	local pasoCuadro = rapidez * math.max(dt, 1 / 60)
	local radio = AGARRE_DISTANCIA + rapidez * math.max(dt * 2, AGARRE_ANTICIPACION)

	if dist > radio then return false end

	local avance = hacia:Dot(dirV)

	if avance < -pasoCuadro then return false end

	if (hacia - dirV * avance).Magnitude > AGARRE_TOLERANCIA then return false end
	if PosicionEnVacio(troot.Position) then return false end

	IniciarAgarre(troot)

	return true
end

local function PasoAgarre(dt)
	local ag = mega.agarre
	local troot = ag.root

	if AGARRE_SOLTAR_RETROCEDER and QuiereRetroceder() then
		SoltarAgarre()
		return
	end

	if not (troot and troot.Parent) or tick() - ag.t0 >= AGARRE_DURACION
		or PosicionEnVacio(troot.Position) or PosicionEnVacio(rootPart.Position)
		or (troot.Position - rootPart.Position).Magnitude > (AGARRE_DISTANCIA + 300) then
		SoltarAgarre()
		return
	end

	ag.vel = troot.AssemblyLinearVelocity

	local deseada = troot.Position + ag.lado * AGARRE_RADIO + Vector3.new(0, AGARRE_AJUSTE_Y, 0)

	if ag.primera then
		ag.primera = false

		local salto = deseada - rootPart.Position
		local res = salto.Magnitude > 0.5 and workspace:Raycast(rootPart.Position, salto, ParamsPersonaje()) or nil

		if res and not res.Instance:IsDescendantOf(troot.Parent) then
			deseada = res.Position - salto.Unit * 2.5
		end

		ag.local_ = troot.CFrame:PointToObjectSpace(deseada)
	end

	local destino = troot.CFrame:PointToWorldSpace(ag.local_)

	local nueva = rootPart.Position:Lerp(destino, 1 - math.exp(-AGARRE_RIGIDEZ * dt))

	if not EsFinito(nueva) then
		SoltarAgarre()
		return
	end

	rootPart.CFrame = CFrame.lookAt(nueva, Vector3.new(troot.Position.X, nueva.Y, troot.Position.Z))
	rootPart.AssemblyLinearVelocity = ag.vel
	rootPart.AssemblyAngularVelocity = Vector3.zero
end

local function RevisarImpactoSuelo(dt)
	if dash.tipo ~= "adelante" then return false end

	local vel = rootPart.AssemblyLinearVelocity

	if vel.Y > -IMPACTO_VEL_Y_MIN then return false end

	local alcance = humanoid.HipHeight + rootPart.Size.Y / 2

	local avance = vel * math.max(dt, 1 / 120) * 1.5
	local res = workspace:Raycast(rootPart.Position, avance + Vector3.new(0, -alcance, 0), ParamsPersonaje())

	if not res or res.Normal.Y < 0.5 then return false end

	local modelo = res.Instance:FindFirstAncestorWhichIsA("Model")

	if modelo and Players:GetPlayerFromCharacter(modelo) then return false end

	local suelo = res.Position
	local velH = Vector3.new(vel.X, 0, vel.Z).Magnitude
	local velocidad = math.clamp((-vel.Y + 0.3 * velH) * IMPACTO_ESCALA_VEL, 22, 150)
	local altura = math.max(ALTURA_MIN_EPICA + 1, rootPart.Position.Y - suelo.Y)

	isSlamming = true
	CancelarSuspension()
	DetenerAnimacionesCustom(0.1)
	TerminarMega()

	isFloating = false
	holdTimer = 0
	ApagarFuerzas()
	FX.Cancelar()

	if not CaidaEpica(altura, suelo, { velocidad = velocidad, xz = suelo }) then
		isSlamming = false
		lastSlamEndTime = tick()
	end

	return true
end

local function MegaPaso(dt)
	if not (rootPart and humanoid) or humanoid.Health <= 0 then
		if mega.agarre then SoltarAgarre() end
		if mega.activo then TerminarMega() end
		return
	end

	if mega.agarre then
		PasoAgarre(dt)
		return
	end

	if dash.buffer > 0 then
		local ahora = tick()

		if ahora > dash.buffer or not isFloating then
			dash.buffer = 0
		elseif ahora >= dash.listo then
			IniciarDash(dash.bufferTipo)
		end
	end

	if mega.activo then

		if tick() >= dash.fin or not isFloating then
			TerminarMega()
			return
		end

		if dash.tipo == "adelante" then
			FX.SetDirDash(dash.dir)

			if RevisarImpactoSuelo(dt) then return end
			if RevisarAgarre(dt) then return end

			PonerPoseBrazos((tick() - dash.t0) / math.max(dash.dur, 0.05) < 0.6)
		end
	elseif animCaminar and animCaminar.IsPlaying then
		PonerPoseBrazos(false)
	end
end

local function TipoDashPorTeclas()
	local w = UserInputService:IsKeyDown(Enum.KeyCode.W)
	local s = UserInputService:IsKeyDown(Enum.KeyCode.S)
	local a = UserInputService:IsKeyDown(Enum.KeyCode.A)
	local d = UserInputService:IsKeyDown(Enum.KeyCode.D)

	if not w then
		if s and not a and not d then return "atras" end
		if a and not s and not d then return "izq" end
		if d and not s and not a then return "der" end
	end

	return "adelante"
end

local function DireccionDash(tipo, cam)
	if tipo == "adelante" then
		return DireccionCamara(cam)
	end

	local l, r = cam.CFrame.LookVector, cam.CFrame.RightVector
	local v

	if tipo == "atras" then
		v = Vector3.new(-l.X, 0, -l.Z)
	elseif tipo == "izq" then
		v = Vector3.new(-r.X, 0, -r.Z)
	else
		v = Vector3.new(r.X, 0, r.Z)
	end

	if v.Magnitude < 0.05 then
		local cl, cr = rootPart.CFrame.LookVector, rootPart.CFrame.RightVector
		local w = (tipo == "atras" and -cl) or (tipo == "izq" and -cr) or cr

		v = Vector3.new(w.X, 0, w.Z)
	end

	return v.Magnitude > 0.01 and v.Unit or nil
end

function IniciarDash(tipo)
	tipo = tipo or "adelante"

	if not (rootPart and humanoid and isFloating) then return end
	if mega.agarre then return end

	local ahora = tick()

	if ahora < dash.listo then

		dash.buffer = ahora + BUFFER_DASH
		dash.bufferTipo = tipo
		return
	end

	dash.buffer = 0

	local cam = workspace.CurrentCamera

	if not cam then return end

	local dir = DireccionDash(tipo, cam)

	if not dir then return end

	local distancia, duracion = DISTANCIA_DASH, DURACION_DASH

	if tipo == "atras" then
		distancia, duracion = DISTANCIA_DASH_ATRAS, DURACION_DASH_ATRAS
	elseif tipo ~= "adelante" then
		distancia, duracion = DISTANCIA_DASH_LATERAL, DURACION_DASH_LATERAL
	end

	dash.tipo = tipo
	dash.dir = dir
	dash.t0 = ahora
	dash.ult = ahora
	dash.dur = math.max(duracion, 0.2)
	dash.v0, dash.c = ResolverImpulso(distancia, dash.dur, VELOCIDAD_SALIDA_DASH)
	dash.fin = ahora + dash.dur
	dash.inerciaFin = dash.fin + INERCIA_DASH
	dash.listo = ahora + ENFRIAMIENTO_DASH

	mega.activo = true
	mega.t0 = ahora
	mega.dir = dir

	PonerPoseBrazos(tipo == "adelante")

	if tipo ~= "adelante" then
		ReproducirAnimDash(tipo)
	end

	pcall(FX.Dash, dir, dash.dur, tipo == "adelante" and 1 or 0.7)
end

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

		local posicionPredicha = posicionCabeza
			+ Vector3.new(velocidadObjetivo.X, 0, velocidadObjetivo.Z)
				* PREDICCION_MOVIMIENTO_SLAM

		local alturaSobreCabeza = humanoid.HipHeight
			+ (rootPart.Size.Y / 2) + 0.15 + AJUSTE_ALTURA_CABEZA_SLAM
		local sueloObjetivo = BuscarSueloDebajoDe(posicionPredicha, {
			character,
			objetivoRoot.Parent,
		})

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

	if not EnElAire() then return end

	local estabaVolando = isFloating
	local objetivo = BuscarObjetivoDebajo()

	if objetivo then
		if not estabaVolando then return end

		isSlamming = true
		CancelarSuspension()
		DetenerAnimacionesCustom(0.1)

		if mega.agarre then
			SoltarAgarre()
		end

		isFloating = false
		holdTimer = 0
		ApagarFuerzas()
		FX.Cancelar()

		PegarALaCabeza(objetivo)
		return
	end

	local suelo, hayJugador = BuscarSueloSeguro(rootPart, character)

	if hayJugador or not suelo then return end

	local altura = rootPart.Position.Y - suelo.Y

	if altura < ALTURA_MIN_EPICA then return end

	isSlamming = true
	CancelarSuspension()
	DetenerAnimacionesCustom(0.1)

	if mega.agarre then
		SoltarAgarre()
	end

	if mega.activo then
		TerminarMega()
	end

	isFloating = false
	holdTimer = 0
	ApagarFuerzas()
	FX.Cancelar()

	pcall(FX.CaidaMega, rootPart.Position, suelo, altura)

	if not CaidaEpica(altura, suelo) then
		isSlamming = false
		lastSlamEndTime = tick()
	end
end

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

		animCaminar = LoadAnim(IDS_MEGA.caminar, Enum.AnimationPriority.Action3, true)
		animDashAtras = LoadAnim(IDS_MEGA.dash_atras, Enum.AnimationPriority.Action4, false)
		animDashDer = LoadAnim(IDS_MEGA.dash_der, Enum.AnimationPriority.Action4, false)

		task.spawn(function()
			local lista = {}

			for _, id in ipairs({ IDS_MEGA.dash_atras, IDS_MEGA.dash_der }) do
				local a = Instance.new("Animation")
				a.AnimationId = id
				table.insert(lista, a)
			end

			pcall(function()
				game:GetService("ContentProvider"):PreloadAsync(lista)
			end)

			for _, a in ipairs(lista) do
				a:Destroy()
			end
		end)

	end

	mega.activo = false
	mega.agarre = nil

	CrearFuerzas()

	isFloating = false
	isSlamming = false
	isHoldingSpace = false
	holdTimer = 0
	tSuelo = 0
	estabaSuspendido = false
	tokenAterrizaje += 1
	seguimiento.enAire = false
	seguimiento.habilidad = false
	dash.fin = 0
	dash.buffer = 0
	ascenso.dur = 0
	holdAereo.activo = false

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

local paramsSuelo = RaycastParams.new()
paramsSuelo.FilterType = Enum.RaycastFilterType.Exclude
paramsSuelo.RespectCanCollide = true

local function EstaEnElSuelo()
	if not humanoid or not rootPart then return false end

	if rootPart.AssemblyLinearVelocity.Y > 6 then return false end

	local alcance = math.max(humanoid.HipHeight + rootPart.Size.Y / 2, 3) + 0.6

	return workspace:Raycast(
		rootPart.Position,
		Vector3.new(0, -alcance, 0),
		ParamsPersonaje()
	) ~= nil
end

local function ObtenerTiempoRequerido()
	local ahora = tick()

	if ahora - lastDamageTime <= 3 then
		return TIEMPO_ACTIVAR_HERIDO
	elseif ahora - lastSlamEndTime <= 1.5 then
		return TIEMPO_ACTIVAR_TRAS_SLAM
	end

	return TIEMPO_ACTIVAR
end

local function ActivarAntigravedad()
	isFloating = true
	tSuelo = 0
	holdAereo.activo = false

	local herido = tick() - lastDamageTime <= 3

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

	local vDespegue = IniciarAscenso(ALTURA_DESPEGUE, TIEMPO_ASCENSO_DESPEGUE)

	rootPart.AssemblyLinearVelocity = Vector3.new(
		moveDir.X * IMPULSO_EXPLOSIVO_XZ,
		vDespegue,
		moveDir.Z * IMPULSO_EXPLOSIVO_XZ
	)
end

local function MegaSaltoAereo()
	if not (rootPart and humanoid and isFloating) then return end

	holdAereo.hecho = true

	local moveDir = humanoid.MoveDirection
	local velActual = rootPart.AssemblyLinearVelocity
	local vMega = IniciarAscenso(ALTURA_MEGA_AEREO, TIEMPO_ASCENSO_MEGA_AEREO)
	local deltaV = vMega - velActual.Y

	if animReSalto then
		animReSalto:Play(0.1)
		animReSalto:AdjustSpeed(2.5)
	end

	EncenderFuerzas()

	local xz = Vector3.new(velActual.X, 0, velActual.Z)

	if moveDir.Magnitude > 0.05 then
		xz = moveDir * IMPULSO_EXPLOSIVO_XZ
	end

	rootPart.AssemblyLinearVelocity = Vector3.new(xz.X, vMega, xz.Z)

	FX.RafagaAbajo(deltaV)

	if MEGA_AEREO_REPETIBLE then
		holdAereo.t = 0
		holdAereo.hecho = false
	end
end

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
		IsMegaImpulse = function()
				return mega.activo or mega.agarre ~= nil
		end,
		GetSettings = function()
			return AJUSTES
		end,
		GetSetting = function(id)
			for _, a in ipairs(AJUSTES) do
				if a.id == id then return a.get() end
			end
			return nil
		end,
		SetSetting = function(id, valor)
			for _, a in ipairs(AJUSTES) do
				if a.id == id then
					if a.tipo == "bool" then
						a.set(valor == true)
					else
						local n = tonumber(valor)
						if not n then return false end
						a.set(math.clamp(n, a.min or n, a.max or n))
					end
					return true
				end
			end
			return false
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

				if suspendido then
					CancelarSuspension()
				end

				if animReSalto then
					animReSalto:Play(0.1)
					animReSalto:AdjustSpeed(2)
				end

				local velActual = rootPart.AssemblyLinearVelocity
				local vSalto = IniciarAscenso(ALTURA_SALTO_AEREO, TIEMPO_SALTO_AEREO)
				local deltaV = vSalto - velActual.Y

				holdAereo.activo = true
				holdAereo.t = 0
				holdAereo.hecho = false

				isFloating = true
				EncenderFuerzas()

				rootPart.AssemblyLinearVelocity = Vector3.new(
					velActual.X,
					vSalto,
					velActual.Z
				)

				FX.RafagaAbajo(deltaV)
			end

		elseif input.KeyCode == Enum.KeyCode.LeftControl
			or input.KeyCode == Enum.KeyCode.RightControl then

			AplastarContraElSuelo()

		elseif input.KeyCode == TECLA_DASH then
			if not EstaSuspendido() then
				IniciarDash(TipoDashPorTeclas())
			end
		end
	end)

	table.insert(_conns, inputBeganConn)

	local inputEndedConn = UserInputService.InputEnded:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.Space then
			isHoldingSpace = false
			holdAereo.activo = false
		end
	end)

	table.insert(_conns, inputEndedConn)

	local renderConn = RunService.RenderStepped:Connect(function(dt)

		FX.Render(dt)

		if _isActive then
			RastrearAterrizaje()
			MegaPaso(dt)
		end

		if not _isActive
			or isSlamming
			or not humanoid
			or not rootPart
			or not humanoid.Parent then
			return
		end

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

		if isFloating and holdAereo.activo and isHoldingSpace and not holdAereo.hecho then
			holdAereo.t += dt

			if holdAereo.t >= TIEMPO_MEGA_AEREO then
				MegaSaltoAereo()
			else
				local inicioAereo = math.min(
					math.max(TIEMPO_MEGA_AEREO * INICIO_VISUAL_FRACCION, INICIO_VISUAL_MIN),
					TIEMPO_MEGA_AEREO * 0.8
				)

				if holdAereo.t > inicioAereo then
					FX.Cargar(((holdAereo.t - inicioAereo) / (TIEMPO_MEGA_AEREO - inicioAereo)) ^ 1.6)
				end
			end
		elseif isFloating then
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
	mega.activo = false
	mega.agarre = nil
	dash.fin = 0

	DetenerAnimacionesCustom(0)
	DestruirFuerzas()
	FX.Destruir()
	tokenAterrizaje += 1
	DetenerSacudida()

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
