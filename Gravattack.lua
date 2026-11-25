--[[
	Gravattack.lua  (v3)

	Cambios de la v3.1: salto aéreo más fuerte, impulso mucho más potente y sin bugs (ya no te manda al suelo ni te
	deja clavado: dirección horizontal con zona muerta + inercia), anillos eléctricos amarillos finos con borde irregular, humo blanco.

	Cambios de la v3:
	  1) Despegue (el salto que activa el Gravattack): ahora sube SIEMPRE ALTURA_DESPEGUE studs (60 por defecto).
	  2) Salto en el aire mucho más bajo: ALTURA_SALTO_AEREO (12) y ALTURA_MEGA_AEREO (30). Antes se acumulaba sin freno.
	  3) Mega impulso rehecho: va hacia donde apunta la cámara (como triggerDash("forward") de Fly) y usa la
	     animación de CAMINAR HACIA ADELANTE de Fly (mov_forward), no la pose del mega/turbo.
	  4) Paleta dorada y eléctrica estilo SpeedForce (oro, amarillo eléctrico, relámpagos neón).
	  5) Caída épica SOLO con: estar en el aire + Ctrl + sin jugador debajo. Aterrizar solo ya no la dispara.
	  6) Mega impulso con el sonido, las ondas sónicas, el aura de aire, el destello y las estelas del Mega Turbo de Fly.

	Space (mantener)  -> la gravedad pierde: salto enorme + planeo antigravitacional
	Ctrl              -> slam (ZAAASH) a la cabeza de un objetivo, o CAÍDA ÉPICA si estás en el aire y no caes sobre un jugador
	Space en vuelo    -> impulso desde los pies (chorro de aire hacia abajo) + re-salto
	Shift en vuelo    -> boost de velocidad
	Q en vuelo        -> MEGA IMPULSO (Mega Turbo de Fly en dorado/eléctrico): sonido, aura, ondas, destello, estelas y la animación de caminar de Fly;
	                     empuja hacia donde apunta la cámara, agarre mini si hay objetivo cerca, se cancela si te quedas quieto
	Space en vuelo (mantener) -> mega salto aéreo

	La suspensión aérea (tecla C) vive ahora en Suspension.lua (menú con F8).
	Los dos módulos se hablan por ENV.AFO_GRAVATTACK_API / ENV.AFO_SUSPENSION_API.

	Cambios de esta versión:
	  1) Efectos con estética All For One: aire comprimido, humo negro-violeta y chispas oscuras (una sola paleta).
	  2) Efecto de caída: rayas de aire al caer rápido + impacto al aterrizar según lo que hayas caído.
	  3) Ctrl = caída épica copiada de Fly.lua: mide la altura al suelo y, desde 45 studs, cae de golpe con
	     ondas, polvo, cráter, sonido, sacudida de cámara y animación; escala con la altura.
	  4) Movilidad en vuelo: mirar arriba/abajo con W sube/pica, Shift = boost, Q = dash aéreo.
	  5) Gravedad aún más baja en vuelo; saltos aéreos más fuertes y mega salto aéreo (mantener Space).
	  6) Planeo tipo Genshin con fuerzas reales (LinearVelocity + VectorForce), sin tocar workspace.Gravity.
	  7) La suspensión aérea vive en Suspension.lua.
]]

local M = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

-- Tabla compartida entre módulos del hub (getgenv si existe, _G si no).
local ENV = (typeof(getgenv) == "function" and getgenv()) or _G

-- ==========================================
-- PARÁMETROS
-- ==========================================

-- Impulso inicial al perder la gravedad
-- El despegue y los saltos aéreos se definen por ALTURA (studs) y TIEMPO de ascenso: durante ese tiempo
-- la velocidad vertical baja linealmente hasta 0 con fuerza alta, así que SIEMPRE suben la altura indicada.
local ALTURA_DESPEGUE = 60             -- altura del salto que activa el Gravattack
local TIEMPO_ASCENSO_DESPEGUE = 0.5
local ACEL_ASCENSO_BURST = 900         -- fuerza del ascenso (studs/s²): alta para que nada lo frene
local IMPULSO_EXPLOSIVO_XZ = 120

-- Saltos en el aire (Space estando en vuelo)
local ALTURA_SALTO_AEREO = 28          -- altura de cada salto aéreo (v3 tenía 12)
local TIEMPO_SALTO_AEREO = 0.25
local ALTURA_MEGA_AEREO = 60           -- altura del mega salto aéreo (v3 tenía 30)
local TIEMPO_ASCENSO_MEGA_AEREO = 0.35
local TIEMPO_MEGA_AEREO = 0.4           -- s que hay que mantener Space para que sea mega salto
local MEGA_AEREO_REPETIBLE = true       -- true: seguir manteniendo Space encadena OTRO mega salto cada TIEMPO_MEGA_AEREO

-- Planeo (estilo planeador de Genshin)
local VELOCIDAD_VUELO = 85          -- velocidad horizontal cuando hay input
local VELOCIDAD_CAIDA_PLANEO = -3   -- descenso constante al planear (soltando Space) (antes -7)
local VELOCIDAD_SUSTENTACION = -0.15 -- descenso casi nulo mientras mantienes Space
local DESCENSO_AL_AVANZAR = 1       -- multiplicador del descenso cuando avanzas (0 = vuelo nivelado)

-- Aceleraciones máximas en studs/s². La fuerza real es masa * aceleración.
local ACEL_HORIZONTAL = 240                 -- al empezar a avanzar
local ACEL_FRENADO = 280                    -- al soltar el input: quieto de inmediato
local ACEL_VERTICAL_EMPUJAR = 60            -- cuando hay que subir la velocidad vertical
local ACEL_VERTICAL_FRENAR_SOSTENIENDO = 5  -- frena la subida con Space mantenido (menos = menos gravedad)
local ACEL_VERTICAL_FRENAR_SUELTO = 12      -- frena la subida al soltar Space

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

-- Efectos visuales (estilo All For One: energía negro-violeta, aire comprimido, chispas oscuras).
-- UNA SOLA paleta para TODO (carga, despegue, salto en el aire, caída e impacto): las tres
-- tonalidades salen del mismo violeta base. Si quieres otro color, cambia solo COLOR_AFO.
-- ACTUALIZADO: paleta dorada y eléctrica estilo SpeedForce. Los nombres de las constantes se mantienen.
local COLOR_AFO = Color3.fromRGB(255, 200, 45)                       -- dorado SpeedForce
local COLOR_AFO_CLARO = Color3.fromRGB(255, 248, 190)                 -- núcleo blanco-amarillo eléctrico
local COLOR_AFO_OSCURO = Color3.fromRGB(255, 140, 15)                -- dorado anaranjado
local COLOR_RAYO = Color3.fromRGB(255, 236, 100)                    -- relámpagos
local ALFA_MAX = 0.55                -- opacidad máxima de todo el efecto (menor = más transparente)

-- Texturas de Fly.lua (mismos assets)
local FLY_RING = "rbxassetid://12914395250"            -- anillo de onda sónica
local FLY_AIRSHOCK = "rbxassetid://112096280571499"    -- aura de aire
local FLY_STREAK = "rbxassetid://106822944701902"      -- raya de partículas del turbo
local IDS_MEGA = {
	shock = "rbxassetid://117592591478260",   -- onda de choque del Mega Turbo de Fly
	sfx = "rbxassetid://111391583223900",     -- sonido del Mega Turbo de Fly
	caminar = "rbxassetid://46196309",        -- mov_forward de Fly (caminar hacia adelante con el vuelo activo)
}

local INICIO_VISUAL_FRACCION = 0.45 -- el efecto de carga empieza tras esta fracción del retardo...
local INICIO_VISUAL_MIN = 0.1       -- ...y nunca antes de estos segundos (un salto normal no lo dispara)
local ANILLOS_CARGA = 2             -- anillos de aire que se cierran sobre tus pies mientras cargas
local RADIO_CARGA = 4.5
local PERIODO_CARGA = 0.45          -- s que tarda cada anillo en cerrarse sobre los pies

-- Impulso (despegue y salto en el aire): onda en los pies + chorro de aire comprimido hacia abajo
local DURACION_ONDA_PIES = 0.32
local RADIO_ONDA_PIES = 8
local VELOCIDAD_CHORRO = 85          -- velocidad de salida del aire (studs/s)
local ARRASTRE_AIRE = 3.2            -- 1/s (arrastre exponencial)
local ANGULO_CONO_GRADOS = 20        -- semiángulo de apertura del cono
local RADIO_BASE_CHORRO = 1.4
local ANILLOS_CONO = 7
local SEPARACION_PARCELAS = 0.028    -- s entre anillos de aire consecutivos
local VIDA_PARCELA = 0.4
local DURACION_SALPICADURA = 0.28
local DELTA_V_REF = 2 * ALTURA_DESPEGUE / TIEMPO_ASCENSO_DESPEGUE - VELOCIDAD_CAIDA_PLANEO

-- Caída (leve): rayas de aire oscuro cuando caes rápido (slam, picada o caída libre) + impacto al aterrizar.
-- Una caída normal de salto (~50 studs/s) no lo activa.
local VELOCIDAD_MIN_CAIDA = 65       -- por debajo de esto no hay efecto
local VELOCIDAD_MAX_CAIDA = 140      -- a esta velocidad (slam) el efecto llega a su máximo
local RAYAS_CAIDA = 4
local VIDA_RAYA = 0.22
local DURACION_IMPACTO = 0.3
local RADIO_IMPACTO = 6

-- Caída épica (copiada de Fly.lua). Se activa con Ctrl y depende de la altura medida bajo el personaje.
local ALTURA_MIN_EPICA = 8              -- altura mínima sobre el suelo para que Ctrl en el aire haga la caída épica
local ALTURA_CAIDA_MAX = 1500        -- a esta altura el nivel de caída llega a su máximo
local ALTURA_IMPACTO_MIN = 12        -- aterrizajes naturales más bajos que esto no hacen efecto
local EFECTO_ATERRIZAJE_NATURAL = true -- aterrizar sin Ctrl solo hace un anillo pequeño (NUNCA la caída épica)
local ALTURA_REF_IMPACTO_NATURAL = 45

-- Movilidad en vuelo
local CONTROL_VERTICAL_CON_CAMARA = true -- mirar arriba/abajo con W sube/baja (estilo planeador)
local ZONA_MUERTA_PITCH = 0.12           -- inclinación de cámara (0-1) por debajo de la cual no sube ni baja
local VELOCIDAD_ASCENSO_MAX = 70         -- studs/s al mirar casi recto hacia arriba
local VELOCIDAD_PICADA_MAX = 110         -- studs/s al mirar casi recto hacia abajo
local REDUCCION_H_ASCENSO = 0.3          -- cuánto se frena el avance horizontal al trepar fuerte
local ACEL_ASCENSO = 110
local ACEL_PICADA = 140
local VELOCIDAD_BOOST = 1.7              -- multiplicador de velocidad mientras mantienes Shift
local TECLA_DASH = Enum.KeyCode.Q        -- MEGA IMPULSO (reinterpretación del Mega Turbo de Fly; cambia la tecla aquí)
local VELOCIDAD_DASH = 700               -- velocidad del mega impulso (Fly usa 607)
local DURACION_DASH = 0.55               -- duración máxima del mega impulso
local FRENADO_FINAL_DASH = 0.35          -- la velocidad cae a este factor al final del impulso
local INERCIA_DASH = 1.2                 -- s tras el impulso en que conservas inercia (frenado suave)
local ACEL_INERCIA_DASH = 220            -- frenado (studs/s²) durante esa inercia: ya no te quedas clavado en el aire
local ZONA_MUERTA_Y_DASH = 0.4           -- si la cámara mira menos inclinada que esto, el impulso va HORIZONTAL
local ESCALA_ONDA_MEGA = 0.55            -- tamaño de las ondas sónicas (Fly: 0.7)
local ENFRIAMIENTO_DASH = 0.9
local ACEL_DASH = 4000

-- Mega impulso: animación de CAMINAR HACIA ADELANTE de Fly con el vuelo activo (IDS_MEGA.caminar, Action3)
local VEL_ANIM_CAMINAR = 1.5                   -- velocidad de reproducción durante el impulso
local FADE_CAMINAR = 0.25                    -- salida suave de la animación

-- Mega impulso: agarre al objetivo (mini versión del GrabSystem de Fly, con la misma lógica de "espalda + resorte")
local AGARRE_ACTIVO = true
local AGARRE_ALCANCE_BUSQUEDA = 140     -- distancia máx. a la que se considera "tengo objetivo" en el impulso
local AGARRE_DISTANCIA_ENGANCHE = 14    -- si el impulso te deja a esta distancia, se activa el agarre
local AGARRE_DURACION = 0.7             -- s que dura el agarre tras enganchar
local AGARRE_RADIO = 3.4                -- distancia a la espalda del objetivo (LATCH_RADIUS de Fly)
local AGARRE_RIGIDEZ = 60               -- fuerza del resorte hacia la espalda
local AGARRE_MARGEN_VACIO = 80          -- como Fly: sobre FallenPartsDestroyHeight se considera vacío

-- Mega impulso: si te quedas quieto se cancela (con su set de partículas de frenado)
local CANCELAR_SI_QUIETO = false  -- (era true: cortaba el impulso y te dejaba clavado en el aire)
local GRACIA_QUIETO = 0.3               -- s de gracia desde que empieza antes de poder cancelar

-- TPs forzados solo en Y (el juego detecta mal tras movimientos bruscos): X/Z no se tocan
local TP_Y_REPETICIONES = 4             -- cuántas veces se re-fija la Y
local TP_Y_ALTURAS = { 0.6, 0, 0.3, 0 } -- desfase sobre el suelo en cada TP (alterna para que el cliente "asiente" la caída)

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
local animCaminar -- animación de caminar hacia adelante de Fly (mega impulso)

local fuerzaAttach, fuerzaVel, antiGravedad = nil, nil, nil
local dash = { fin = 0, listo = 0, dir = Vector3.zero }
local ascenso = { t0 = 0, dur = 0, v0 = 0 } -- ascenso por altura (despegue y saltos aéreos)

-- Empieza un ascenso que llega a "altura" studs en "dur" s (v0 = 2h/T, baja linealmente a 0). Devuelve v0.
local function IniciarAscenso(altura, dur)
	ascenso.t0 = tick()
	ascenso.dur = dur
	ascenso.v0 = 2 * altura / dur
	return ascenso.v0
end

-- Estado del mega impulso (reinterpretación del Mega Turbo de Fly)
local mega = {
	activo = false,
	t0 = 0,
	dir = Vector3.zero,
	jugador = nil,     -- objetivo (Player) si lo hay
	agarre = nil,      -- { t0, jugador, ultPos, vel } mientras el agarre está corriendo
}

-- Ajustes expuestos para el menú (ENV.AFO_GRAVATTACK_API.GetSettings / SetSetting)
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
	{ id = "VELOCIDAD_DASH", nombre = "Velocidad mega impulso", tipo = "number", min = 50, max = 1200,
		get = function() return VELOCIDAD_DASH end, set = function(v) VELOCIDAD_DASH = v end },
	{ id = "DURACION_DASH", nombre = "Duración mega impulso (s)", tipo = "number", min = 0.1, max = 1.5,
		get = function() return DURACION_DASH end, set = function(v) DURACION_DASH = v end },
	{ id = "ENFRIAMIENTO_DASH", nombre = "Enfriamiento mega impulso (s)", tipo = "number", min = 0, max = 5,
		get = function() return ENFRIAMIENTO_DASH end, set = function(v) ENFRIAMIENTO_DASH = v end },
	{ id = "FRENADO_FINAL_DASH", nombre = "Velocidad final del impulso (factor)", tipo = "number", min = 0.05, max = 1,
		get = function() return FRENADO_FINAL_DASH end, set = function(v) FRENADO_FINAL_DASH = v end },
	{ id = "ESCALA_ONDA_MEGA", nombre = "Tamaño de las ondas del impulso", tipo = "number", min = 0.1, max = 1.5,
		get = function() return ESCALA_ONDA_MEGA end, set = function(v) ESCALA_ONDA_MEGA = v end },
	{ id = "AGARRE_ACTIVO", nombre = "Agarre al objetivo en el impulso", tipo = "bool",
		get = function() return AGARRE_ACTIVO end, set = function(v) AGARRE_ACTIVO = v end },
	{ id = "AGARRE_DISTANCIA_ENGANCHE", nombre = "Distancia para enganchar (studs)", tipo = "number", min = 4, max = 60,
		get = function() return AGARRE_DISTANCIA_ENGANCHE end, set = function(v) AGARRE_DISTANCIA_ENGANCHE = v end },
	{ id = "AGARRE_DURACION", nombre = "Duración del agarre (s)", tipo = "number", min = 0.1, max = 5,
		get = function() return AGARRE_DURACION end, set = function(v) AGARRE_DURACION = v end },
	{ id = "CANCELAR_SI_QUIETO", nombre = "Cancelar impulso si me quedo quieto", tipo = "bool",
		get = function() return CANCELAR_SI_QUIETO end, set = function(v) CANCELAR_SI_QUIETO = v end },
	{ id = "GRACIA_QUIETO", nombre = "Gracia antes de cancelar (s)", tipo = "number", min = 0, max = 1,
		get = function() return GRACIA_QUIETO end, set = function(v) GRACIA_QUIETO = v end },
	{ id = "ALFA_MAX", nombre = "Opacidad de efectos", tipo = "number", min = 0.05, max = 1,
		get = function() return ALFA_MAX end, set = function(v) ALFA_MAX = v end },
}
local holdAereo = { activo = false, t = 0, hecho = false } -- Space mantenido tras un salto aéreo

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
	if animCaminar and animCaminar.IsPlaying then animCaminar:Stop(fadeTime) end
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

	-- Agarre del mega impulso: el personaje sigue la velocidad del objetivo (la posición la fija MegaPaso).
	if mega.agarre then
		fuerzaVel.VectorVelocity = mega.agarre.vel or Vector3.zero
		fuerzaVel.MaxAxesForce = Vector3.new(masa * ACEL_DASH, masa * ACEL_DASH, masa * ACEL_DASH)
		return
	end

	-- Dash aéreo: durante unos instantes manda sobre todo lo demás.
	if tick() < dash.fin then
		-- Empuje fuerte al inicio que se va soltando hacia el final del impulso.
		local k = math.clamp(1 - (dash.fin - tick()) / math.max(DURACION_DASH, 0.05), 0, 1)
		local v = VELOCIDAD_DASH * (1 - (1 - FRENADO_FINAL_DASH) * k * k)
		fuerzaVel.VectorVelocity = dash.dir * v
		fuerzaVel.MaxAxesForce = Vector3.new(masa * ACEL_DASH, masa * ACEL_DASH, masa * ACEL_DASH)
		return
	end

	local escribiendo = UserInputService:GetFocusedTextBox() ~= nil
	local boost = not escribiendo and UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
	local mult = boost and VELOCIDAD_BOOST or 1

	-- Avance horizontal + control vertical con la cámara (mirar arriba/abajo mientras avanzas).
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

	-- Subir/picar con la cámara reemplaza el planeo solo cuando va más allá de él.
	if vertical > 0 then
		objetivoY = math.max(objetivoY, vertical)
	elseif vertical < 0 then
		objetivoY = math.min(objetivoY, vertical)
	end

	local aXZ = (conInput and ACEL_HORIZONTAL or ACEL_FRENADO) * (boost and 1.3 or 1)

	-- Tras el impulso conservas la inercia (frenado suave) en vez de quedarte parado de golpe.
	if not conInput and tick() < (dash.inerciaFin or 0) then
		aXZ = ACEL_INERCIA_DASH
	end

	local aY
	if velActual.Y > objetivoY then
		if vertical < 0 then
			aY = ACEL_PICADA
		else
			aY = isHoldingSpace and ACEL_VERTICAL_FRENAR_SOSTENIENDO or ACEL_VERTICAL_FRENAR_SUELTO
		end
	else
		aY = vertical > 0 and ACEL_ASCENSO or ACEL_VERTICAL_EMPUJAR
	end

	-- Ascenso por altura (despegue / salto aéreo): manda sobre la velocidad vertical mientras dura.
	if ascenso.dur > 0 then
		local k = (tick() - ascenso.t0) / ascenso.dur

		if k < 1 then
			objetivoY = math.max(objetivoY, ascenso.v0 * (1 - k))
			aY = ACEL_ASCENSO_BURST
		else
			ascenso.dur = 0
		end
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
	local anillosCono = {}
	local anillosCarga = {}
	local rayas = {}
	local salpicadura, ondaPies, ondaImpacto
	local parteAire, emisorAire, emisorChispasAire
	local parteCarga, emisorChispasCarga
	local parteImpacto, emisorHumoImpacto, emisorChispasImpacto
	local parteDash, emisorHumoDash, emisorChispasDash

	-- Carga: anillos de aire que se cierran sobre tus pies mientras mantienes Space.
	local carga = { objetivo = 0, alfa = 0, t = 0 }

	-- Onda que sale de los pies al impulsarte.
	local onda = { activa = false, t = 0, s = 1, pos = Vector3.zero }

	-- Impacto al aterrizar de una caída rápida (o del slam).
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

	-- Anillo plano dibujado con SurfaceGui (círculo + UIStroke). Siempre con la misma paleta.
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

			-- Igual que sonicBoomEffect de Fly: dos ImageLabel con el anillo RING_ID (uno exterior y uno interior)
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

	-- Humo oscuro (sin brillo propio: se ve negro-violeta, como la energía de All For One).
	local function CrearHumo(padre, direccion, velMin, velMax, apertura)
		local e = Instance.new("ParticleEmitter")
		e.Texture = FLY_AIRSHOCK
		e.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(215, 215, 220))
		e.LightEmission = 0.1
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

	-- Chispas finas de energía (como el chisporroteo de sus poderes), alargadas según su velocidad.
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

	-- Raya de aire que queda tras tu cuerpo al caer rápido: una Trail en un punto fijo del cuerpo.
	local ALTURAS_RAYAS = { 0.9, -0.5, 1.4, -1.1 }

	local function CrearRaya(i)
		local parte = NuevaParte("RayaCaida")
		parte.Size = Vector3.new(0.2, 0.2, 0.2)

		local a0 = Instance.new("Attachment")
		a0.Position = Vector3.new(0, 0.22, 0)
		a0.Parent = parte

		local a1 = Instance.new("Attachment")
		a1.Position = Vector3.new(0, -0.22, 0)
		a1.Parent = parte

		local estela = Instance.new("Trail")
		estela.Attachment0 = a0
		estela.Attachment1 = a1
		estela.Lifetime = VIDA_RAYA
		estela.MinLength = 0.05
		estela.FaceCamera = true
		estela.LightEmission = 0.2
		estela.LightInfluence = 0
		estela.Color = ColorSequence.new(COLOR_AFO_CLARO, COLOR_AFO_OSCURO)
		estela.WidthScale = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(1, 0),
		})
		estela.Transparency = NumberSequence.new(0.85, 1)
		estela.Enabled = false
		estela.Parent = parte

		local ang = (i - 0.5) / RAYAS_CAIDA * math.pi * 2

		return {
			parte = parte,
			estela = estela,
			offset = Vector3.new(
				math.cos(ang) * 1.7,
				ALTURAS_RAYAS[(i - 1) % #ALTURAS_RAYAS + 1],
				math.sin(ang) * 1.7
			),
			activo = false,
			opacidad = -1,
		}
	end

	-- ---------- construcción ----------
	local function Preparar()
		if carpeta and carpeta.Parent then return true end

		carpeta = Instance.new("Folder")
		carpeta.Name = "AFO_GravattackFX"
		carpeta.Parent = workspace

		anillosCono, anillosCarga, rayas = {}, {}, {}

		for i = 1, ANILLOS_CONO do
			anillosCono[i] = CrearAnillo()
		end

		for i = 1, ANILLOS_CARGA do
			anillosCarga[i] = CrearAnillo()
		end

		for i = 1, RAYAS_CAIDA do
			rayas[i] = CrearRaya(i)
		end

		salpicadura = CrearAnillo()
		ondaPies = CrearAnillo()
		ondaImpacto = CrearAnillo()

		-- Impulso: aire comprimido (humo oscuro) y chispas que salen de los pies hacia abajo
		parteAire = NuevaParte("ChorroAire")
		emisorAire = CrearHumo(parteAire, Enum.NormalId.Bottom, VELOCIDAD_CHORRO * 0.65, VELOCIDAD_CHORRO, ANGULO_CONO_GRADOS)
		emisorAire.Lifetime = NumberRange.new(0.25, 0.38)
		emisorAire.Drag = ARRASTRE_AIRE
		emisorChispasAire = CrearChispas(parteAire, Enum.NormalId.Bottom, VELOCIDAD_CHORRO * 0.5, VELOCIDAD_CHORRO * 0.9, ANGULO_CONO_GRADOS + 10)

		-- Carga: chisporroteo muy leve que sube de tus pies
		parteCarga = NuevaParte("CargaPies")
		emisorChispasCarga = CrearChispas(parteCarga, Enum.NormalId.Top, 5, 11, 40)

		-- Impacto: humo oscuro que se abre por el suelo y chispas
		parteImpacto = NuevaParte("Impacto")
		emisorHumoImpacto = CrearHumo(parteImpacto, Enum.NormalId.Top, 8, 16, 75)
		emisorChispasImpacto = CrearChispas(parteImpacto, Enum.NormalId.Top, 14, 28, 65)

		-- Dash aéreo: humo y chispas que quedan detrás de ti
		parteDash = NuevaParte("DashAereo")
		emisorHumoDash = CrearHumo(parteDash, Enum.NormalId.Front, 12, 30, 25)
		emisorChispasDash = CrearChispas(parteDash, Enum.NormalId.Front, 25, 55, 20)

		return true
	end

	-- ---------- carga (aire y energía que se juntan en tus pies) ----------
	local function RenderCarga(dt)
		-- Sube con suavidad y se apaga rápido.
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
			local aparicion = math.sin(fase * math.pi) -- nace y muere suave, sin saltos

			PonerAnillo(
				a,
				CFrame.new(pies + Vector3.new(0, 0.12, 0)),
				radio,
				carga.alfa * aparicion * ALFA_MAX * 0.8
			)
		end
	end

	-- ---------- onda de impulso en los pies ----------
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

	-- ---------- chorro de aire hacia abajo ----------
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

	-- ---------- impacto de aterrizaje ----------
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

	-- ---------- caída rápida (rayas de aire; el aterrizaje lo gestiona RastrearAterrizaje) ----------
	local function ApagarRayas()
		for _, r in ipairs(rayas) do
			if r.activo then
				r.estela.Enabled = false
				r.activo = false
			end
		end
	end

	local function RenderCaida()
		local viva = rootPart and rootPart.Parent and humanoid and humanoid.Parent
		local vy = viva and rootPart.AssemblyLinearVelocity.Y or 0

		if not (viva and vy < -VELOCIDAD_MIN_CAIDA) then
			ApagarRayas()
			return
		end

		local k = math.clamp((-vy - VELOCIDAD_MIN_CAIDA) / (VELOCIDAD_MAX_CAIDA - VELOCIDAD_MIN_CAIDA), 0, 1)
		local opacidad = 0.88 - 0.3 * k
		local base = rootPart.Position

		for _, r in ipairs(rayas) do
			r.parte.CFrame = CFrame.new(base + r.offset)

			if not r.activo then
				r.estela.Enabled = true
				r.activo = true
			end

			if math.abs(r.opacidad - opacidad) > 0.03 then
				r.opacidad = opacidad
				r.estela.Transparency = NumberSequence.new(opacidad, 1)
			end
		end
	end

	-- ---------- impulso (despegue y salto en el aire comparten ESTE efecto) ----------
	-- Conservación del momento: m * dV = m_aire * v_chorro. Con v_chorro fija, un dV
	-- mayor mueve más aire: más densidad (opacidad y partículas). s = 1 es el despegue.
	local function Impulsar(s)
		local pies = PiesActuales()
		if not pies then return end

		-- Lo que había de la carga desaparece en el mismo instante.
		carga.objetivo = 0
		carga.alfa = 0
		OcultarAnillos(anillosCarga)
		emisorChispasCarga.Rate = 0

		-- Onda desde los pies
		onda.activa = true
		onda.t = 0
		onda.s = s
		onda.pos = pies

		-- Chorro hacia abajo
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

	-- ---------- mega impulso: anillos de onda sónica MINI (como sonicBoomEffect de Fly) + frenado ----------
	local extra = { pool = {} }
	local megaFx = { activo = false, t = 0, pos = Vector3.zero, dir = Vector3.zAxis, defs = {} }

	-- El anillo queda perpendicular a la dirección del impulso (su cara Top mira hacia dir).
	local function CFrameAnillo(pos, dir)
		local arriba = math.abs(dir.Y) > 0.95 and Vector3.xAxis or Vector3.yAxis
		return CFrame.lookAt(pos, pos + dir, arriba) * CFrame.Angles(math.rad(-90), 0, 0)
	end

	local function PoolAnillos()
		if #extra.pool == 0 or not extra.pool[1].parte.Parent then
			extra.pool = {}

			for i = 1, 3 do
				extra.pool[i] = CrearAnillo()
			end
		end

		return extra.pool
	end

	local function IniciarAnillos(defs, pos, dir)
		local pool = PoolAnillos()

		megaFx.activo = true
		megaFx.t = 0
		megaFx.pos = pos
		megaFx.dir = dir
		megaFx.defs = {}

		for i, d in ipairs(defs) do
			d.a = pool[i]
			megaFx.defs[i] = d
		end

		for i = #defs + 1, #pool do
			PonerAnillo(pool[i], CFrame.identity, 1, 0)
		end
	end

	local function RenderMega(dt)
		if not megaFx.activo then return end

		megaFx.t += dt

		local vivo = false

		for _, d in ipairs(megaFx.defs) do
			local edad = megaFx.t - d.delay

			if edad < 0 then
				vivo = true
			elseif edad >= d.dur then
				PonerAnillo(d.a, CFrame.identity, 1, 0)
			else
				vivo = true

				local k = edad / d.dur
				local e = 1 - (1 - k) ^ 4
				local radio = d.r0 + (d.r1 - d.r0) * e
				local alfa = (d.entra and math.sin(k * math.pi) or (1 - k) ^ 1.2) * ALFA_MAX * d.fuerza

				PonerAnillo(d.a, CFrameAnillo(megaFx.pos, megaFx.dir), radio, alfa)
			end
		end

		if not vivo then
			megaFx.activo = false
		end
	end

	-- Aura de aire (BillboardGui con AIR_SHOCK de Fly) que se agranda y se desvanece, en pequeño.
	local function AuraAire(px0, px1, dur, alfa)
		if not rootPart or not rootPart.Parent then return end

		local bb = Instance.new("BillboardGui")
		bb.Adornee = rootPart
		bb.AlwaysOnTop = false
		bb.LightInfluence = 0
		bb.Size = UDim2.fromOffset(px0, px0)
		bb.ResetOnSpawn = false
		bb.Parent = carpeta

		local img = Instance.new("ImageLabel")
		img.Image = FLY_AIRSHOCK
		img.Size = UDim2.fromScale(1, 1)
		img.BackgroundTransparency = 1
		img.ImageColor3 = COLOR_AFO
		img.ImageTransparency = 1 - alfa
		img.ScaleType = Enum.ScaleType.Fit
		img.Parent = bb

		TweenService:Create(bb, TweenInfo.new(dur, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
			{ Size = UDim2.fromOffset(px1, px1) }):Play()
		TweenService:Create(img, TweenInfo.new(dur, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
			{ ImageTransparency = 1 }):Play()

		task.delay(dur + 0.05, function()
			pcall(function()
				bb:Destroy()
			end)
		end)
	end

	local E = {} -- helpers del mega impulso (una sola variable local)

	-- ---------- Mega impulso estilo Fly: sonido + aura + ondas + destello + estelas + relámpagos ----------
	-- Réplica del Mega Turbo de Fly (playLocalSound + sonicBoomEffect(2) + airShockAura(2) + speedWhiteFlash
	-- + createParticle), teñida con la paleta dorada/eléctrica y con relámpagos estilo SpeedForce.
	E.impulso = { activo = false, fin = 0, dir = Vector3.zAxis, acc = 0, accRayo = 0 }
	
	function E.Az(a, b)
		return a + math.random() * (b - a)
	end

	function E.SonidoLocal(id, volumen)
		local s = Instance.new("Sound")
		s.SoundId = id
		s.Volume = volumen
		s.RollOffMaxDistance = 0
		s.Parent = game:GetService("SoundService")
		s:Play()

		task.delay(10, function()
			pcall(function()
				s:Destroy()
			end)
		end)
	end

	-- Igual que airShockAura(2) de Fly: dos auras de aire que se agrandan y se desvanecen (en dorado).
	function E.AuraFly()
		local raiz = rootPart

		if not raiz or not raiz.Parent or not carpeta then return end

		local function NuevaAura(px, c1, t1, rot1, c2, t2, rot2)
			local bb = Instance.new("BillboardGui")
			bb.Adornee = raiz
			bb.AlwaysOnTop = false
			bb.LightInfluence = 0
			bb.Size = UDim2.new(0, px, 0, px)
			bb.ResetOnSpawn = false
			bb.ZIndexBehavior = Enum.ZIndexBehavior.Global
			bb.Parent = carpeta

			local img = Instance.new("ImageLabel")
			img.Image = FLY_AIRSHOCK
			img.Size = UDim2.new(1, 0, 1, 0)
			img.BackgroundTransparency = 1
			img.ImageColor3 = c1
			img.ImageTransparency = t1
			img.ScaleType = Enum.ScaleType.Fit
			img.Rotation = rot1
			img.Parent = bb

			local img2 = Instance.new("ImageLabel")
			img2.Image = FLY_AIRSHOCK
			img2.Size = UDim2.new(1.3, 0, 1.3, 0)
			img2.Position = UDim2.new(-0.15, 0, -0.15, 0)
			img2.BackgroundTransparency = 1
			img2.ImageColor3 = c2
			img2.ImageTransparency = t2
			img2.ScaleType = Enum.ScaleType.Fit
			img2.Rotation = rot2
			img2.Parent = bb

			return bb, img, img2
		end

		-- Primera aura (la de intensidad 1 de Fly)
		task.spawn(function()
			local bb, img, img2 = NuevaAura(50, COLOR_AFO_CLARO, 0.4, 0, COLOR_AFO, 0.55, 45)

			TweenService:Create(bb, TweenInfo.new(0.14, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
				{ Size = UDim2.new(0, 200, 0, 200) }):Play()
			task.wait(0.05)

			if not bb.Parent then return end

			TweenService:Create(bb, TweenInfo.new(0.20, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
				{ Size = UDim2.new(0, 280, 0, 280) }):Play()
			TweenService:Create(img, TweenInfo.new(0.22, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
				{ ImageTransparency = 1 }):Play()
			TweenService:Create(img2, TweenInfo.new(0.18, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
				{ ImageTransparency = 1 }):Play()

			task.delay(0.32, function()
				pcall(function()
					bb:Destroy()
				end)
			end)
		end)

		-- Segunda aura, más grande (la extra del Mega de Fly)
		task.spawn(function()
			task.wait(0.05)

			if not raiz.Parent or not carpeta then return end

			local bb2, i1, i2 = NuevaAura(50, COLOR_AFO_CLARO, 0.35, 22, COLOR_AFO_OSCURO, 0.5, 60)

			TweenService:Create(bb2, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
				{ Size = UDim2.new(0, 320, 0, 320) }):Play()
			task.wait(0.10)

			if not bb2.Parent then return end

			TweenService:Create(bb2, TweenInfo.new(0.26, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
				{ Size = UDim2.new(0, 420, 0, 420) }):Play()
			TweenService:Create(i1, TweenInfo.new(0.28, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
				{ ImageTransparency = 1 }):Play()
			TweenService:Create(i2, TweenInfo.new(0.22, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
				{ ImageTransparency = 1 }):Play()

			task.delay(0.40, function()
				pcall(function()
					bb2:Destroy()
				end)
			end)
		end)
	end

	-- ---------- Anillos eléctricos amarillos (como la referencia) ----------
	-- Cada anillo son segmentos neón en círculo, perpendicular a la dirección del impulso, que se
	-- expande y se apaga; el borde vibra y suelta chispas/espinas. Un halo translúcido más grueso da el brillo.
	E.NSEG = 24
	E.NESPINAS = 9
	E.anillosElec = {}

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

	function E.NuevoAnillo(pos, dir, r0, r1, dur, grosor, retraso)
		if not carpeta then return end

		-- limite de seguridad para no saturar de partes
		if #E.anillosElec > 14 then return end

		local arriba = math.abs(dir.Y) > 0.95 and Vector3.xAxis or Vector3.yAxis
		local base = CFrame.lookAt(pos, pos + dir, arriba) -- el anillo vive en el plano XY, mirando a "dir"

		local carp = Instance.new("Folder")
		carp.Name = "AnilloElectrico"
		carp.Parent = carpeta

		local segs, espinas = {}, {}

		for i = 1, E.NSEG do
			local nucleo = E.ParteNeon(COLOR_RAYO, 1)
			local halo = E.ParteNeon(COLOR_AFO, 1)
			nucleo.Parent = carp
			halo.Parent = carp
			segs[i] = { nucleo, halo }
		end

		for j = 1, E.NESPINAS do
			local sp = E.ParteNeon(COLOR_AFO_CLARO, 1)
			sp.Parent = carp
			espinas[j] = sp
		end

		table.insert(E.anillosElec, {
			t = -(retraso or 0), dur = dur, r0 = r0, r1 = r1, pos = pos, base = base,
			segs = segs, espinas = espinas, folder = carp, grosor = grosor,
		})
	end

	function E.RenderAnillos(dt)
		for idx = #E.anillosElec, 1, -1 do
			local a = E.anillosElec[idx]

			a.t += dt

			if not a.folder.Parent or a.t >= a.dur then
				pcall(function()
					a.folder:Destroy()
				end)
				table.remove(E.anillosElec, idx)
			elseif a.t >= 0 then
				local k = a.t / a.dur
				local e = 1 - (1 - k) ^ 3
				local r = a.r0 + (a.r1 - a.r0) * e
				local alfa = math.clamp(k ^ 1.6, 0, 1)
				local grosor = a.grosor * (1 - 0.55 * k)
				local puntos = {}

				for i = 1, E.NSEG do
					local ang = (i - 1) / E.NSEG * math.pi * 2
					local rr = r * (1 + E.Az(-0.07, 0.07)) -- borde irregular/distorsionado como electricidad

					puntos[i] = a.base * Vector3.new(math.cos(ang) * rr, math.sin(ang) * rr, 0)
				end

				for i = 1, E.NSEG do
					local p1 = puntos[i]
					local p2 = puntos[i % E.NSEG + 1]
					local len = (p2 - p1).Magnitude + 0.06
					local cf = CFrame.lookAt((p1 + p2) / 2, p2)
					local s = a.segs[i]

					s[1].Size = Vector3.new(grosor, grosor, len)
					s[1].CFrame = cf
					s[1].Transparency = alfa * 0.9

					s[2].Size = Vector3.new(grosor * 2.2, grosor * 2.2, len)
					s[2].CFrame = cf
					s[2].Transparency = 0.78 + 0.22 * alfa
				end

				-- chispas que saltan del borde y cambian de sitio cada cuadro
				for j, sp in ipairs(a.espinas) do
					local p = puntos[math.random(1, E.NSEG)]
					local radial = p - a.pos

					if radial.Magnitude > 0.1 then
						local d = (radial.Unit + Vector3.new(E.Az(-0.7, 0.7), E.Az(-0.7, 0.7), E.Az(-0.7, 0.7))).Unit
						local largo = E.Az(0.9, 2.6) * (0.6 + r / 14)

						sp.Size = Vector3.new(grosor * 0.7, grosor * 0.7, largo)
						sp.CFrame = CFrame.lookAt(p + d * largo / 2, p + d * largo)
						sp.Transparency = math.clamp(alfa + E.Az(0, 0.35), 0, 1)
					end
				end
			end
		end
	end

	-- Igual que speedWhiteFlash de Fly pero con destello dorado.
	function E.DestelloPantalla()
		local gui = Instance.new("ScreenGui")
		gui.Name = "AFO_GravDestello"
		gui.ResetOnSpawn = false
		gui.IgnoreGuiInset = true
		gui.DisplayOrder = 950
		gui.ZIndexBehavior = Enum.ZIndexBehavior.Global

		local ok = pcall(function()
			gui.Parent = game:GetService("CoreGui")
		end)

		if not ok or not gui.Parent then
			pcall(function()
				gui.Parent = player:FindFirstChildOfClass("PlayerGui")
			end)
		end

		if not gui.Parent then return end

		local marco = Instance.new("Frame")
		marco.Size = UDim2.new(1, 0, 1, 0)
		marco.BackgroundColor3 = Color3.fromRGB(255, 226, 110)
		marco.BackgroundTransparency = 1
		marco.BorderSizePixel = 0
		marco.Parent = gui

		TweenService:Create(marco, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ BackgroundTransparency = 0.82 }):Play()

		task.delay(0.1, function()
			if not marco.Parent then return end

			TweenService:Create(marco, TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
				{ BackgroundTransparency = 1 }):Play()
		end)

		task.delay(0.5, function()
			pcall(function()
				gui:Destroy()
			end)
		end)
	end

	-- Raya de aire que queda atrás (createParticle de Fly): imagen alargada que mira a la cámara,
	-- se aleja en sentido contrario al impulso y se desvanece.
	function E.CrearEstelaFly(dir)
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
		parte.Size = Vector3.new(0.18, 8, 0.1)
		parte.CFrame = CFrame.fromMatrix(pos, derecha, arriba, mira)
		parte.Parent = carpeta

		local sg = Instance.new("SurfaceGui")
		sg.Adornee = parte
		sg.Face = Enum.NormalId.Front
		sg.AlwaysOnTop = true
		sg.LightInfluence = 0
		sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		sg.PixelsPerStud = 50
		sg.Parent = parte

		local img = Instance.new("ImageLabel")
		img.Image = FLY_STREAK
		img.Size = UDim2.new(1, 0, 1, 0)
		img.BackgroundTransparency = 1
		img.ImageColor3 = math.random() < 0.5 and COLOR_AFO_CLARO or COLOR_AFO
		img.ImageTransparency = 0.25
		img.ScaleType = Enum.ScaleType.Fit
		img.Parent = sg

		local FADE = 0.42

		TweenService:Create(img, TweenInfo.new(FADE, Enum.EasingStyle.Linear), { ImageTransparency = 1 }):Play()
		TweenService:Create(parte, TweenInfo.new(FADE, Enum.EasingStyle.Linear),
			{ Position = pos + lejos * 7 }):Play()

		task.delay(FADE + 0.05, function()
			pcall(function()
				parte:Destroy()
			end)
		end)
	end

	-- Relámpago en zigzag (segmentos neón dorados que parpadean y se apagan en una fracción de segundo).
	function E.Relampago(origen, dir)
		if not carpeta then return end

		local actual = origen
		local d = dir
		local partes = {}
		local segmentos = math.random(5, 8)
		local largo = E.Az(1.1, 2.2)

		for i = 1, segmentos do
			d = (d + Vector3.new(E.Az(-1, 1), E.Az(-1, 1), E.Az(-1, 1)) * 0.9)

			if d.Magnitude < 0.1 then
				d = Vector3.yAxis
			end

			d = d.Unit

			local siguiente = actual + d * largo
			local len = (siguiente - actual).Magnitude

			local p = Instance.new("Part")
			p.Name = "Relampago"
			p.Anchored = true
			p.CanCollide = false
			p.CanQuery = false
			p.CanTouch = false
			p.CastShadow = false
			p.Material = Enum.Material.Neon
			p.Color = (i % 2 == 0) and COLOR_RAYO or COLOR_AFO_CLARO
			p.Transparency = 0.05
			p.Size = Vector3.new(0.14, 0.14, len)
			p.CFrame = CFrame.lookAt((actual + siguiente) / 2, siguiente)
			p.Parent = carpeta

			TweenService:Create(p, TweenInfo.new(0.13, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{ Transparency = 1 }):Play()

			partes[i] = p
			actual = siguiente
		end

		task.delay(0.17, function()
			for _, p in ipairs(partes) do
				pcall(function()
					p:Destroy()
				end)
			end
		end)
	end

	-- Aura dorada pegada al cuerpo mientras dura el impulso (resplandor + luz que parpadean).
	function E.QuitarAura(inmediato)
		local hl, luz = E.resaltadoAura, E.luzAura

		E.resaltadoAura, E.luzAura = nil, nil

		if hl then
			if inmediato or not hl.Parent then
				pcall(function()
					hl:Destroy()
				end)
			else
				TweenService:Create(hl, TweenInfo.new(0.35), { FillTransparency = 1, OutlineTransparency = 1 }):Play()

				task.delay(0.4, function()
					pcall(function()
						hl:Destroy()
					end)
				end)
			end
		end

		if luz then
			if inmediato or not luz.Parent then
				pcall(function()
					luz:Destroy()
				end)
			else
				TweenService:Create(luz, TweenInfo.new(0.3), { Brightness = 0 }):Play()

				task.delay(0.35, function()
					pcall(function()
						luz:Destroy()
					end)
				end)
			end
		end
	end

	function E.IniciarAura()
		E.QuitarAura(true)

		if not (character and rootPart and carpeta) then return end

		local ok, hl = pcall(function()
			local h = Instance.new("Highlight")
			h.Name = "AuraDorada"
			h.Adornee = character
			h.FillColor = COLOR_AFO
			h.OutlineColor = COLOR_AFO_CLARO
			h.FillTransparency = 0.55
			h.OutlineTransparency = 0.1
			h.DepthMode = Enum.HighlightDepthMode.Occluded
			h.Parent = carpeta
			return h
		end)

		if ok then
			E.resaltadoAura = hl
		end

		local luz = Instance.new("PointLight")
		luz.Name = "LuzAuraDorada"
		luz.Color = COLOR_AFO
		luz.Brightness = 6
		luz.Range = 26
		luz.Parent = rootPart
		E.luzAura = luz
	end

	function E.RenderEstela(dt)
		if not E.impulso.activo then return end

		if tick() >= E.impulso.fin or not (rootPart and rootPart.Parent) then
			E.impulso.activo = false
			E.QuitarAura(false)
			return
		end

		-- Chisporroteo de la aura
		if E.resaltadoAura and E.resaltadoAura.Parent then
			E.resaltadoAura.FillTransparency = 0.45 + math.random() * 0.25
		end

		if E.luzAura and E.luzAura.Parent then
			E.luzAura.Brightness = 4 + math.random() * 4
		end

		E.impulso.acc += dt
		E.impulso.accRayo += dt
		E.impulso.accAnillo = (E.impulso.accAnillo or 0) + dt

		while E.impulso.accAnillo >= 0.07 do
			E.impulso.accAnillo -= 0.07

			E.NuevoAnillo(rootPart.Position - E.impulso.dir * 1.5, E.impulso.dir, 2.5, 14 * ESCALA_ONDA_MEGA / 0.55, 0.42, 0.16, 0)
		end

		while E.impulso.acc >= 0.04 do
			E.impulso.acc -= 0.04
			E.CrearEstelaFly(E.impulso.dir)
		end

		while E.impulso.accRayo >= 0.05 do
			E.impulso.accRayo -= 0.05

			for _ = 1, 2 do
				local origen = rootPart.Position + Vector3.new(E.Az(-2, 2), E.Az(-2.5, 2.5), E.Az(-2, 2))
				local d = Vector3.new(E.Az(-1, 1), E.Az(-1, 1), E.Az(-1, 1)) - E.impulso.dir * 0.6

				if d.Magnitude < 0.1 then
					d = -E.impulso.dir
				end

				E.Relampago(origen, d.Unit)
			end
		end
	end

	-- ---------- API ----------
	function FX.Iniciar()
		Preparar()
	end

	function FX.Render(dt)
		if not carpeta then return end

		E.RenderEstela(dt)
		E.RenderAnillos(dt)
		RenderMega(dt)
		RenderCarga(dt)
		RenderOnda(dt)
		RenderCono(dt)
		RenderCaida()
		RenderImpacto(dt)
	end

	-- Llamar cada cuadro mientras se mantiene el salto: p va de 0 a 1.
	function FX.Cargar(p)
		if not Preparar() then return end

		carga.objetivo = math.clamp(p, 0, 1)
	end

	-- Soltaste antes de tiempo (o algo lo interrumpió): la carga se apaga rápido.
	function FX.Cancelar()
		carga.objetivo = 0
	end

	-- Despegue (pierdes la gravedad): impulso desde los pies. Después no queda nada pegado al cuerpo.
	function FX.Liberar()
		if not Preparar() then return end

		Impulsar(1)
	end

	-- Salto en pleno vuelo: el mismo impulso, escalado por cuánta velocidad ganas.
	function FX.RafagaAbajo(deltaV)
		if not Preparar() then return end

		Impulsar(math.clamp((deltaV or DELTA_V_REF) / DELTA_V_REF, 0.35, 1.25))
	end

	-- Impacto explícito (el slam al suelo teletransporta y no pasa por la caída rápida).
	function FX.Impacto(pos, s)
		if not Preparar() or not pos then return end

		Aterrizar(pos, s or 1)
	end

	-- Mega impulso (Mega Turbo de Fly en dorado/eléctrico): sonido + ondas sónicas + aura de aire + destello
	-- + aura dorada pegada al cuerpo + estelas de aire hacia atrás + relámpagos.
	function FX.Dash(dir, duracion)
		if not Preparar() or not rootPart or not dir then return end

		local pos = rootPart.Position
		local arriba = math.abs(dir.Y) > 0.95 and Vector3.xAxis or Vector3.yAxis

		E.SonidoLocal(IDS_MEGA.sfx, 0.88)
		local esc = ESCALA_ONDA_MEGA / 0.55

		E.NuevoAnillo(pos, dir, 2, 16 * esc, 0.5, 0.2, 0)
		E.NuevoAnillo(pos, dir, 2, 26 * esc, 0.55, 0.18, 0.05)
		E.NuevoAnillo(pos, dir, 2, 38 * esc, 0.6, 0.16, 0.10)
		E.AuraFly()
		E.DestelloPantalla()
		E.IniciarAura()

		E.impulso.activo = true
		E.impulso.fin = tick() + (duracion or DURACION_DASH) + 0.12
		E.impulso.dir = dir
		E.impulso.acc = 0
		E.impulso.accRayo = 0

		for _ = 1, 8 do
			local d = Vector3.new(E.Az(-1, 1), E.Az(-1, 1), E.Az(-1, 1))

			E.Relampago(pos + Vector3.new(E.Az(-2, 2), E.Az(-2.5, 2.5), E.Az(-2, 2)), d.Magnitude > 0.1 and d.Unit or Vector3.yAxis)
		end

		parteDash.CFrame = CFrame.lookAt(pos, pos - dir, arriba)
		emisorHumoDash:Emit(10)
		emisorChispasDash:Emit(26)
	end

	-- Fin del mega impulso: deja de emitir estelas/relámpagos y apaga la aura dorada.
	function FX.FinDash(inmediato)
		E.impulso.activo = false
		E.QuitarAura(inmediato == true)
	end

	-- Cancelación por quedarte quieto: anillos que se CIERRAN hacia ti + rayas que salen hacia adelante (inercia).
	function FX.Frenar(dir)
		if not Preparar() or not rootPart or not dir then return end

		local pos = rootPart.Position
		local arriba = math.abs(dir.Y) > 0.95 and Vector3.xAxis or Vector3.yAxis

		IniciarAnillos({
			{ delay = 0,    dur = 0.24, r0 = 7.0, r1 = 1.2, fuerza = 0.9, entra = true },
			{ delay = 0.05, dur = 0.20, r0 = 4.5, r1 = 0.8, fuerza = 0.7, entra = true },
		}, pos, dir)

		AuraAire(70, 24, 0.22, 0.3)

		parteDash.CFrame = CFrame.lookAt(pos, pos + dir, arriba)
		emisorHumoDash:Emit(5)
		emisorChispasDash:Emit(9)
	end

	function FX.Destruir()
		E.QuitarAura(true)
		E.impulso.activo = false
		E.anillosElec = {}

		if carpeta then
			carpeta:Destroy()
		end

		carpeta = nil
		anillosCono, anillosCarga, rayas = {}, {}, {}
		extra.pool = {}
		megaFx.activo = false
		carga.objetivo, carga.alfa = 0, 0
		onda.activa = false
		impacto.activo = false
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
-- CAÍDA ÉPICA (copia del sistema de Fly.lua)
-- ==========================================
-- Ctrl sin objetivo debajo: se mide la altura al suelo con un raycast hacia abajo (como
-- measureGround de Fly). Con Ctrl en el aire (y sin jugador debajo) caes de golpe al suelo y se dispara
-- el aterrizaje épico: ondas, polvo del color del suelo, cráter de rocas, luz, sonido, sacudida
-- de cámara y la animación de agachado. Todo escala con la altura (nivel 1 a 4).
-- Los aterrizajes naturales (planeando) usan el mismo aterrizaje según lo que hayas caído.
local ID_CAIDA_BASE = "rbxassetid://287325678"
local ID_CAIDA_OVERLAY = "rbxassetid://70439247"
local ID_AIRE_ONDA = "rbxassetid://112096280571499"
local ID_PARTICULA = "rbxassetid://106822944701902"
local ID_ONDA_CIRCULO = "rbxassetid://5457833933"
local ID_SFX_ATERRIZAJE = "rbxassetid://135226467234227"
local ID_SFX_ATERRIZAJE_CRISTAL = "rbxassetid://132535085898211"

local seguimiento = { enAire = false, pico = 0, ultimo = 0 }
local tokenAterrizaje = 0

-- Evita que un aterrizaje se cuente dos veces (slam + detección natural).
local function MarcarAterrizaje()
	seguimiento.ultimo = tick()
	seguimiento.enAire = false

	if rootPart then
		seguimiento.pico = rootPart.Position.Y
	end
end

local function Finito(v)
	return v.X == v.X and v.Y == v.Y and v.Z == v.Z
		and math.abs(v.X) < 1e9 and math.abs(v.Y) < 1e9 and math.abs(v.Z) < 1e9
end

-- ---------- sacudida de cámara ----------
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

-- ---------- medición de altura (igual que measureGround de Fly) ----------
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

-- Suelo plano debajo (9 rayos): devuelve el punto del suelo, no la posición del torso.
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

		-- Si lo primero que hay debajo es el personaje de otro jugador, NO es suelo: se devuelve (nil, true).
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

-- ---------- efectos del aterrizaje ----------
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

		-- Destello de luz (mismo violeta de toda la paleta)
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

				-- Atraviesa partes casi invisibles (cristales, triggers)
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
				polvoBase = c:Lerp(Color3.new(1, 1, 1), 0.18)
			end
		end

		local polvoClaro = polvoBase:Lerp(Color3.new(1, 1, 1), 0.2)
		local polvoOscuro = polvoBase:Lerp(Color3.new(0, 0, 0), 0.25)

		local esCristal = materialImpacto == Enum.Material.Glass
			or materialImpacto == Enum.Material.ForceField
			or materialImpacto == Enum.Material.Ice

		-- Sonido (más grave y fuerte cuanto más alto caes)
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
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(0.1, 20 * mult),
				NumberSequenceKeypoint.new(1, 60 * mult),
			}), multEscala)
			anillo.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.4),
				NumberSequenceKeypoint.new(0.2, 0.7),
				NumberSequenceKeypoint.new(1, 1),
			})
			anillo.Color = ColorSequence.new(color)
			anillo.Lifetime = NumberRange.new(0.35 + nivel * 0.05)
			anillo.LightEmission = 0.8
			anillo.Rate = 0
			anillo.Parent = adj
			anillo:Emit(2)

			task.delay(2, function()
				pcall(function()
					anillo:Destroy()
				end)
			end)
		end

		-- Ondas de choque: mismas texturas y tamaños que Fly, teñidas con la paleta violeta.
		EmitirAnillo(ID_ONDA_CIRCULO, adjPlano, 1.2, COLOR_AFO_CLARO)

		if nivel > 1 then
			EmitirAnillo(ID_PARTICULA, adjPlano, 1.4, COLOR_AFO_CLARO:Lerp(COLOR_AFO, 0.15))
			EmitirAnillo(ID_ONDA_CIRCULO, adjInclinado1, 0.9, COLOR_AFO_CLARO:Lerp(COLOR_AFO, 0.35))
			EmitirAnillo(ID_PARTICULA, adjInclinado2, 1.1, COLOR_AFO_CLARO:Lerp(COLOR_AFO, 0.25))
		end

		-- Polvo rodante, onda de aire y polvo vertical (color del suelo, como en Fly)
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

		-- Cráter de rocas con el material y color del suelo
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
						-- Sobre cristal/hielo las piezas salen disparadas y se desvanecen
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

			-- Las rocas se hunden y el cráter desaparece
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

-- ---------- aterrizaje (efectos + animación de agachado) ----------
local function PiesDe(raiz, hum)
	return raiz.Position - Vector3.new(0, hum.HipHeight + raiz.Size.Y / 2, 0)
end

local function AterrizajeEpico(char, altura, conAnimacion)
	if not char or not char.Parent then return end

	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then return end

	if NivelCaida(altura) <= 0 then return end

	local raiz = char:FindFirstChild("HumanoidRootPart")
	local anim = hum:FindFirstChildOfClass("Animator")

	tokenAterrizaje += 1
	local miToken = tokenAterrizaje

	DetenerAnimacionesCustom(0)

	local posicion = (raiz and Finito(raiz.Position)) and (PiesDe(raiz, hum) + Vector3.new(0, 0.2, 0))
		or Vector3.new(0, 0, 0)

	EfectosAterrizaje(posicion, math.max(altura * 0.5, 22))

	if not conAnimacion or not anim then return end

	-- Igual que Fly: durante el agachado se apaga el Animate y solo suenan estas dos animaciones.
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

	-- Fases como en Fly: golpe rápido, pausa, recuperación lenta, salida
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

	-- Si ya volviste a volar no se toca el estado del Humanoid.
	if hum.Parent and hum.Health > 0 and not isFloating then
		pcall(function()
			hum:ChangeState(Enum.HumanoidStateType.Running)
		end)
	end
end

-- TPs forzados SOLO en Y: el juego a veces detecta mal tras movimientos bruscos, así que se re-fija la Y
-- varias veces (alternando un pequeño desfase) sin tocar X/Z. El último TP siempre queda a ras de suelo.
-- El primero es inmediato; los demás ocurren en los siguientes Heartbeat.
local function ForzarTPsY(yFinal)
	local n = math.max(TP_Y_REPETICIONES, 1)
	local char = character

	local function Aplicar(i)
		if not (rootPart and rootPart.Parent and character == char) then return false end

		local p = rootPart.Position
		local desfase = (i < n) and (TP_Y_ALTURAS[(i - 1) % #TP_Y_ALTURAS + 1] or 0) or 0

		-- X y Z se leen de la posición ACTUAL: no se modifican.
		rootPart.CFrame = CFrame.new(p.X, yFinal + desfase, p.Z) * rootPart.CFrame.Rotation
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

-- Ctrl: cae de golpe al suelo y dispara el aterrizaje según la altura medida.
-- ¿Estás realmente en el aire? (sin suelo bajo los pies ni FloorMaterial)
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

local function CaidaEpica(altura, sueloDado)
	local suelo = sueloDado or BuscarSueloSeguro(rootPart, character)

	if not suelo then return false end

	local alturaPiernas = humanoid.HipHeight + (rootPart.Size.Y / 2)

	ForzarTPsY(suelo.Y + alturaPiernas)

	humanoid.PlatformStand = false
	humanoid:ChangeState(Enum.HumanoidStateType.Landed)

	MarcarAterrizaje()

	local char = character

	task.spawn(AterrizajeEpico, char, altura, true)

	task.delay(0.1, function()
		if not _isActive then return end

		isSlamming = false
		lastSlamEndTime = tick()
	end)

	return true
end

-- Aterrizaje al terminar de caer/planear: efecto según lo que hayas caído (pico - altura actual).
local function AterrizajeNatural(altura)
	if not EFECTO_ATERRIZAJE_NATURAL then return end
	if not (character and rootPart and humanoid) then return end

	-- Aterrizar sin Ctrl NUNCA dispara la caída épica: solo un anillo pequeño según lo que hayas caído.
	FX.Impacto(PiesDe(rootPart, humanoid), math.clamp(altura / ALTURA_REF_IMPACTO_NATURAL, 0.3, 0.8))
end

-- Se llama cada cuadro: sigue el punto más alto del salto/vuelo y detecta cuándo tocas el suelo.
local function RastrearAterrizaje()
	if not (humanoid and rootPart and humanoid.Parent and rootPart.Parent) or humanoid.Health <= 0 then
		seguimiento.enAire = false
		return
	end

	local py = rootPart.Position.Y

	if humanoid.FloorMaterial == Enum.Material.Air then
		if not seguimiento.enAire then
			seguimiento.enAire = true
			seguimiento.pico = py
		end

		seguimiento.pico = math.max(seguimiento.pico, py)
		return
	end

	if seguimiento.enAire then
		seguimiento.enAire = false

		local altura = seguimiento.pico - py

		if tick() - seguimiento.ultimo > 0.6 and altura >= ALTURA_IMPACTO_MIN then
			seguimiento.ultimo = tick()
			AterrizajeNatural(altura)
		end
	end

	seguimiento.pico = py
end

-- ==========================================
-- DASH AÉREO
-- ==========================================
-- Reinterpretación del Mega Turbo de Fly (Q):
--   Fly: Q en turbo -> pre-mega (agachado) -> onda sónica + aura + flash + dash hacia adelante a x1.5;
--        el modo se cancela solo (idleWatcher) cuando sueltas todas las teclas; el GrabSystem se activa
--        cuando la trayectoria te lleva hacia un enemigo.
--   Aquí: Q en vuelo -> pose de brazos atrás (frame congelado, Action4) + onda sónica mini + impulso fuerte;
--        si hay objetivo y el impulso te deja cerca, se engancha a su espalda un instante (agarre);
--        si te quedas quieto el impulso se cancela con su set de partículas de frenado.
local function ObtenerObjetivoMega(dir)
	if not rootPart then return nil, nil end

	local function Valido(jug)
		if not jug or jug == player then return nil end

		local ch = jug.Character
		local hum = ch and ch:FindFirstChildOfClass("Humanoid")
		local r = ch and ch:FindFirstChild("HumanoidRootPart")

		if hum and r and hum.Health > 0 then
			return r
		end

		return nil
	end

	-- 1) Objetivo del Lock de Fly (lo publica en el Character)
	if character then
		local act = character:FindFirstChild("AFO_LockActive")
		local tgt = character:FindFirstChild("AFO_LockedTarget")

		if act and tgt and act.Value == true and typeof(tgt.Value) == "Instance" then
			local r = Valido(tgt.Value)

			if r then return tgt.Value, r end
		end
	end

	-- 2) Si no hay Lock: el jugador más cercano que esté delante de la dirección del impulso
	local mejor, mejorRoot, mejorScore = nil, nil, math.huge

	for _, jug in ipairs(Players:GetPlayers()) do
		local r = Valido(jug)

		if r then
			local hacia = r.Position - rootPart.Position
			local d = hacia.Magnitude

			if d > 1 and d <= AGARRE_ALCANCE_BUSQUEDA and hacia.Unit:Dot(dir) > 0.8 then
				local score = d * (2 - hacia.Unit:Dot(dir))

				if score < mejorScore then
					mejor, mejorRoot, mejorScore = jug, r, score
				end
			end
		end
	end

	return mejor, mejorRoot
end

-- Animación de CAMINAR HACIA ADELANTE de Fly con el vuelo activo (mov_forward, Action3, en bucle).
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

local function SoltarAgarre()
	local ag = mega.agarre

	if not ag then return end

	mega.agarre = nil

	if rootPart and rootPart.Parent then
		pcall(function()
			rootPart.AssemblyLinearVelocity = ag.vel or Vector3.zero
		end)
	end
end

local function TerminarMega(motivo)
	if not mega.activo and not mega.agarre then return end

	local dir = mega.dir

	mega.activo = false
	mega.jugador = nil
	dash.fin = 0

	if motivo ~= "quieto" then
		dash.inerciaFin = tick() + INERCIA_DASH
	end

	PonerPoseBrazos(false)
	FX.FinDash()
	SoltarAgarre()

	if motivo == "quieto" and rootPart and rootPart.Parent then
		-- Frenado: se mata el impulso (queda la inercia mínima) y se dispara el set de partículas.
		local v = rootPart.AssemblyLinearVelocity

		rootPart.AssemblyLinearVelocity = Vector3.new(v.X * 0.1, v.Y * 0.3, v.Z * 0.1)

		FX.Frenar(dir)
	end
end

local function PosicionEnVacio(pos, vel)
	local limite = workspace.FallenPartsDestroyHeight

	if type(limite) ~= "number" or limite ~= limite or limite < -1e6 then
		limite = -500
	end

	limite += AGARRE_MARGEN_VACIO

	if pos.Y <= limite then return true end

	return vel ~= nil and vel.Y < -80 and (pos.Y + vel.Y * 1.0) <= limite
end

-- Se llama cada cuadro desde el bucle principal.
local function MegaPaso(dt)
	if not (rootPart and humanoid) or humanoid.Health <= 0 then
		if mega.activo or mega.agarre then TerminarMega() end
		return
	end

	local ahora = tick()

	-- Pose de brazos: se re-fija el frame cada cuadro mientras dura.
	if mega.activo then
		PonerPoseBrazos(true)
	elseif animCaminar and animCaminar.IsPlaying then
		PonerPoseBrazos(false)
	end

	-- ---------- agarre en curso (versión mini del GrabSystem de Fly: espalda del objetivo + resorte) ----------
	local ag = mega.agarre

	if ag then
		local ch = ag.jugador and ag.jugador.Character
		local thum = ch and ch:FindFirstChildOfClass("Humanoid")
		local troot = ch and ch:FindFirstChild("HumanoidRootPart")

		if not (thum and troot and thum.Health > 0) or ahora - ag.t0 >= AGARRE_DURACION then
			TerminarMega()
			return
		end

		local tpos = troot.Position
		local delta = ag.ultPos and (tpos - ag.ultPos) or Vector3.zero

		ag.vel = (dt > 0) and (delta / math.max(dt, 1e-3)) or Vector3.zero

		if ag.vel.Magnitude > 3000 or ag.vel ~= ag.vel then
			ag.vel = Vector3.zero
		end

		ag.ultPos = tpos

		-- Como Fly: si el objetivo cae/va al vacío, te suelta ANTES de arrastrarte.
		if PosicionEnVacio(tpos, troot.AssemblyLinearVelocity) then
			TerminarMega()
			return
		end

		-- Alejarte (S) tras una breve gracia suelta el agarre, igual que en Fly.
		if ahora - ag.t0 > 0.25 and UserInputService:GetFocusedTextBox() == nil
			and UserInputService:IsKeyDown(Enum.KeyCode.S) then
			TerminarMega()
			return
		end

		local lv = troot.CFrame.LookVector
		local plano = Vector3.new(lv.X, 0, lv.Z)
		local espalda = plano.Magnitude > 0.2 and -plano.Unit or Vector3.new(0, 0, 1)
		local deseada = tpos + espalda * AGARRE_RADIO

		local base = rootPart.Position + delta
		local final = base:Lerp(deseada, 1 - math.exp(-AGARRE_RIGIDEZ * dt))

		if final.X ~= final.X or final.Y ~= final.Y or final.Z ~= final.Z then
			TerminarMega()
			return
		end

		local minY = workspace.FallenPartsDestroyHeight
		if type(minY) == "number" and minY == minY and minY > -1e6 then
			final = Vector3.new(final.X, math.max(final.Y, minY + AGARRE_MARGEN_VACIO + 20), final.Z)
		end

		local mira = Vector3.new(tpos.X - final.X, 0, tpos.Z - final.Z)

		if mira.Magnitude > 0.3 then
			rootPart.CFrame = CFrame.lookAt(final, final + mira)
		else
			rootPart.CFrame = CFrame.new(final) * rootPart.CFrame.Rotation
		end

		rootPart.AssemblyLinearVelocity = ag.vel
		rootPart.AssemblyAngularVelocity = Vector3.zero

		return
	end

	if not mega.activo then return end

	-- ---------- fin natural del impulso ----------
	if ahora >= dash.fin then
		TerminarMega()
		return
	end

	-- ---------- cancelar si te quedas quieto ----------
	if CANCELAR_SI_QUIETO and ahora - mega.t0 > GRACIA_QUIETO then
		local conTeclas = humanoid.MoveDirection.Magnitude > 0.05
		local conObjetivo = mega.jugador ~= nil

		if not conTeclas and not conObjetivo then
			TerminarMega("quieto")
			return
		end
	end

	-- ---------- engancharse al objetivo si el impulso te acerca demasiado ----------
	if AGARRE_ACTIVO and mega.jugador then
		local ch = mega.jugador.Character
		local thum = ch and ch:FindFirstChildOfClass("Humanoid")
		local troot = ch and ch:FindFirstChild("HumanoidRootPart")

		if thum and troot and thum.Health > 0 then
			local dist = (troot.Position - rootPart.Position).Magnitude

			-- Si el Grab de Fly ya está agarrando, no se duplica.
			local flyGrab = character and character:FindFirstChild("AFO_GrabActive")
			local flyAgarrando = flyGrab and flyGrab.Value == true

			if dist <= AGARRE_DISTANCIA_ENGANCHE and not flyAgarrando
				and not PosicionEnVacio(troot.Position, troot.AssemblyLinearVelocity) then

				mega.activo = false
				dash.fin = 0
				PonerPoseBrazos(false)
				FX.FinDash()

				mega.agarre = {
					t0 = ahora,
					jugador = mega.jugador,
					ultPos = troot.Position,
					vel = troot.AssemblyLinearVelocity,
				}
			end
		else
			mega.jugador = nil
		end
	end
end

local function IniciarDash()
	if not (rootPart and humanoid and isFloating) then return end

	local ahora = tick()

	if ahora < dash.listo then return end

	local cam = workspace.CurrentCamera

	if not cam then return end

	-- Igual que triggerDash("forward") de Fly: el impulso va hacia donde apunta la cámara (con su inclinación).
	local dir = cam.CFrame.LookVector

	-- La cámara normal mira un poco hacia abajo: antes eso te mandaba al suelo al impulsarte quieto.
	-- Con inclinación pequeña el impulso es horizontal; si inclinas la cámara de verdad, sube o pica.
	if math.abs(dir.Y) < ZONA_MUERTA_Y_DASH then
		dir = Vector3.new(dir.X, 0, dir.Z)
	end

	if dir.Magnitude < 0.01 then return end

	dir = dir.Unit

	-- Si ya hay un agarre o impulso en curso no se apila otro.
	if mega.agarre then return end

	-- Objetivo (Lock de Fly o jugador delante): si el impulso va más o menos hacia él, se apunta a su centro.
	local jugador, objRoot = ObtenerObjetivoMega(dir)

	if objRoot then
		local hacia = objRoot.Position - rootPart.Position

		if hacia.Magnitude > 1 and hacia.Unit:Dot(dir) > 0.5 then
			dir = hacia.Unit
		end
	end

	dash.dir = dir
	dash.fin = ahora + DURACION_DASH
	dash.listo = ahora + ENFRIAMIENTO_DASH

	mega.activo = true
	mega.t0 = ahora
	mega.dir = dir
	mega.jugador = jugador

	rootPart.AssemblyLinearVelocity = dir * VELOCIDAD_DASH

	PonerPoseBrazos(true)
	FX.Dash(dir, DURACION_DASH)
	SacudirCamara(0.9, 0.14)
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

	-- Condición 1: tienes que estar en el aire (en el suelo Ctrl no hace nada).
	if not EnElAire() then return end

	local estabaVolando = isFloating
	local objetivo = BuscarObjetivoDebajo()

	-- Condición 3: si debajo hay un jugador NO hay caída épica.
	-- Volando: ZAAASH a su cabeza. Cayendo sin volar: no pasa nada.
	if objetivo then
		if not estabaVolando then return end

		isSlamming = true
		CancelarSuspension()
		DetenerAnimacionesCustom(0.1)

		isFloating = false
		holdTimer = 0
		ApagarFuerzas()
		FX.Cancelar()

		PegarALaCabeza(objetivo)
		return
	end

	-- También cuenta como jugador el que quede justo bajo tus pies (rayos al suelo).
	local suelo, hayJugador = BuscarSueloSeguro(rootPart, character)

	if hayJugador or not suelo then return end

	local altura = rootPart.Position.Y - suelo.Y

	if altura < ALTURA_MIN_EPICA then return end

	-- Condición 2 cumplida (Ctrl) + aire + sin jugador: caída épica.
	isSlamming = true
	CancelarSuspension()
	DetenerAnimacionesCustom(0.1)

	if mega.activo or mega.agarre then
		TerminarMega()
	end

	isFloating = false
	holdTimer = 0
	ApagarFuerzas()
	FX.Cancelar()

	if not CaidaEpica(altura, suelo) then
		isSlamming = false
		lastSlamEndTime = tick()
	end
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
		-- Animación de caminar hacia adelante de Fly (mov_forward) para el mega impulso
		animCaminar = LoadAnim(IDS_MEGA.caminar, Enum.AnimationPriority.Action3, true)

	end

	mega.activo, mega.agarre, mega.jugador = false, nil, nil

	CrearFuerzas()

	isFloating = false
	isSlamming = false
	isHoldingSpace = false
	holdTimer = 0
	tSuelo = 0
	estabaSuspendido = false
	tokenAterrizaje += 1
	seguimiento.enAire = false
	dash.fin = 0
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
	holdAereo.activo = false -- seguir mantenido el Space del despegue NO cuenta como mega salto aéreo

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

	local vDespegue = IniciarAscenso(ALTURA_DESPEGUE, TIEMPO_ASCENSO_DESPEGUE)

	rootPart.AssemblyLinearVelocity = Vector3.new(
		moveDir.X * IMPULSO_EXPLOSIVO_XZ,
		vDespegue,
		moveDir.Z * IMPULSO_EXPLOSIVO_XZ
	)
end

-- Mega salto aéreo: Space mantenido tras un salto en el aire. Mismo impulso desde los pies,
-- al máximo, con empuje horizontal como el del despegue si te estás moviendo.
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
	SacudirCamara(1.2, 0.2)

	-- Seguir manteniendo Space encadena OTRO mega salto tras TIEMPO_MEGA_AEREO.
	if MEGA_AEREO_REPETIBLE then
		holdAereo.t = 0
		holdAereo.hecho = false
	end
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
				-- Saltar durante la suspensión la termina (Suspension.lua) y sigues volando.
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

				-- Si mantienes Space después de este salto, se convierte en mega salto.
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

				-- Reacción: el impulso hacia arriba empuja una ráfaga de aire hacia abajo.
				FX.RafagaAbajo(deltaV)
			end

		elseif input.KeyCode == Enum.KeyCode.LeftControl
			or input.KeyCode == Enum.KeyCode.RightControl then

			AplastarContraElSuelo()

		elseif input.KeyCode == TECLA_DASH then
			if not EstaSuspendido() then
				IniciarDash()
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

	-- ==========================================
	-- BUCLE PRINCIPAL
	-- ==========================================
	local renderConn = RunService.RenderStepped:Connect(function(dt)
		-- Los efectos se dibujan siempre, para que el desvanecimiento termine bien.
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

		-- Mega salto aéreo: mantener Space después de un salto en el aire.
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
	mega.activo, mega.agarre, mega.jugador = false, nil, nil
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
