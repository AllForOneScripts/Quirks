--[[
	Gravattack.lua  (v3.5)

	Cambios de la v3.5:
      - El efecto de aterrizaje SOLO sale tras una caída en la que usaste la habilidad de flotar (antes salía con cualquier caída).
      - Los hilos de viento de la caída también salen al SUBIR (con el largo limitado para que no distraigan).
      - Subida/picada y saltos aéreos ~15-20 % más rápidos. Búfer de 0.18 s para Q (si la pulsas un instante antes de que acabe el enfriamiento).
      - Rendimiento: parámetros de raycast reutilizados, discos en pool, sin tablas nuevas por cuadro. Más guardas ante casos límite.

    Cambios de la v3.4:
	  - Caída épica (Ctrl): el aro del suelo desaparece y se reemplaza por un leve mega turbo hacia abajo desde el punto donde pulsaste.
	  - Sin clones. Todos los efectos en amarillo puro (nada blanco). Discos que se acumulan + onda de aire al impulsarte.
	  - El impulso decae suave (sin corte ni quedarte estático), se puede DIRECCIONAR con la cámara y su enfriamiento es corto.
	  - Agarre estilo Passive Bang al objetivo del Lock tras un impulso; impacto con el suelo = caída épica según la potencia.
	  - Ascensos (despegue y saltos aéreos) con curva más suave; aura de aterrizaje desde los pies reales.

	Cambios de la v3.3:
	  1) Mega impulso (Q) = SOLO una fuerza lineal (LinearVelocity) hacia donde apunta la cámara. Se eliminó todo lo que
		 tocaba el CFrame o la velocidad a mano: el agarre al objetivo (resorte sobre el CFrame), la puntería automática
		 hacia el Lock/jugador, la escritura directa de AssemblyLinearVelocity, la inercia sobrante y la sacudida de cámara.
	  2) El impulso recorre DISTANCIA_DASH = 200 studs (antes ~400) y su energía se CONSUME: arranca fuerte y cae a 0
		 en DURACION_DASH segundos (v = v0 * (1 - t/T)^2). Ya no sigues volando sin parar.
	  3) Efectos del impulso mucho más suaves: sin destello de pantalla, sin parpadeo, sin relámpagos por cuadro, menos anillos.
	  4) Todos los efectos pasan a la estética de Shigaraki (temporada 8): anillos eléctricos amarillos finos con espinas,
		 humo y chispas (en v3.4 todo pasó a amarillo puro y se quitaron los clones).

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
	Q en vuelo        -> MEGA IMPULSO: una fuerza lineal de DISTANCIA_DASH studs hacia donde apunta la cámara que se agota sola;
						 sonido, discos que se acumulan + onda de aire amarilla y la animación de caminar de Fly; direccionable con la cámara
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
local POTENCIA_ASCENSO = 2             -- curva v = v0 * (1 - t/T)^n: n = 2 acaba suave (sin frenazo al llegar arriba)
local ALTURA_DESPEGUE = 60             -- altura del salto que activa el Gravattack
local TIEMPO_ASCENSO_DESPEGUE = 0.45
local ACEL_ASCENSO_BURST = 900         -- fuerza del ascenso (studs/s²): alta para que nada lo frene
local IMPULSO_EXPLOSIVO_XZ = 120

-- Saltos en el aire (Space estando en vuelo)
local ALTURA_SALTO_AEREO = 28          -- altura de cada salto aéreo (v3 tenía 12)
local TIEMPO_SALTO_AEREO = 0.35
local ALTURA_MEGA_AEREO = 60           -- altura del mega salto aéreo (v3 tenía 30)
local TIEMPO_ASCENSO_MEGA_AEREO = 0.5
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

-- Efectos visuales (estética Shigaraki, temporada 8 de My Hero Academia): TODO en amarillo (anillos eléctricos,
-- discos, onda de aire, humo y chispas); ningún efecto usa blanco ni azul. UNA SOLA paleta para TODO (carga,
-- despegue, salto en el aire, caída, impacto y mega impulso). Los nombres COLOR_AFO* se mantienen por compatibilidad.
local COLOR_AFO = Color3.fromRGB(255, 214, 20)              -- amarillo eléctrico puro
local COLOR_AFO_CLARO = Color3.fromRGB(255, 232, 70)        -- amarillo más vivo (NO casi blanco: con brillo se vería blanco)
local COLOR_AFO_OSCURO = Color3.fromRGB(230, 170, 10)       -- amarillo profundo
local COLOR_RAYO = Color3.fromRGB(255, 222, 40)             -- núcleo de los anillos eléctricos
local COLOR_ESPINA_OSCURA = Color3.fromRGB(55, 45, 20)      -- fragmentos oscuros en el borde de los anillos
local COLOR_AIRE = Color3.fromRGB(255, 212, 30)             -- humo / aire: también amarillo
local COLOR_AIRE_OSCURO = Color3.fromRGB(205, 150, 10)      -- sombra del humo (amarillo oscuro)
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
local DELTA_V_REF = (POTENCIA_ASCENSO + 1) * ALTURA_DESPEGUE / TIEMPO_ASCENSO_DESPEGUE - VELOCIDAD_CAIDA_PLANEO

-- Caída (leve): rayas de aire oscuro cuando caes rápido (slam, picada o caída libre) + impacto al aterrizar.
-- Una caída normal de salto (~50 studs/s) no lo activa.
local VELOCIDAD_MIN_CAIDA = 65       -- por debajo de esto no hay efecto
local VELOCIDAD_MAX_CAIDA = 140      -- a esta velocidad (slam) el efecto llega a su máximo
local VELOCIDAD_MIN_SUBIDA = 55      -- lo mismo al SUBIR (despegue, saltos aéreos, trepar con la cámara)
local LARGO_MAX_RAYA = 28            -- studs: largo máximo de cada hilo (a velocidades altas se acorta para no distraer)
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
local VELOCIDAD_ASCENSO_MAX = 85         -- studs/s al mirar casi recto hacia arriba
local VELOCIDAD_PICADA_MAX = 130         -- studs/s al mirar casi recto hacia abajo
local REDUCCION_H_ASCENSO = 0.3          -- cuánto se frena el avance horizontal al trepar fuerte
local ACEL_ASCENSO = 135
local ACEL_PICADA = 170
local VELOCIDAD_BOOST = 1.7              -- multiplicador de velocidad mientras mantienes Shift
local TECLA_DASH = Enum.KeyCode.Q                -- MEGA IMPULSO (cambia la tecla aquí)
-- El impulso es una fuerza lineal (LinearVelocity) hacia donde apunta la cámara y puedes DIRECCIONARLO mientras dura.
-- Su velocidad decae exponencialmente (v = v0 * e^(-c*t)): arranca fuerte y se apaga suave, sin corte brusco. v0 y c
-- se calculan para que recorra EXACTAMENTE DISTANCIA_DASH studs en DURACION_DASH s y termine a VELOCIDAD_SALIDA_DASH.
local DISTANCIA_DASH = 200                   -- studs que recorre el impulso en total
local DURACION_DASH = 1.2                    -- s que dura la fuerza del impulso (los efectos duran menos)
local VELOCIDAD_SALIDA_DASH = 20             -- studs/s con los que acaba y se entrega al vuelo normal
local ACEL_INERCIA_DASH = 70                 -- frenado suave tras el impulso si no pulsas nada (studs/s²)
local INERCIA_DASH = 0.6                     -- s que dura ese frenado suave
local GIRO_DASH = 4.5                        -- rad/s: lo rápido que puedes girar el impulso con la cámara
local ZONA_MUERTA_Y_DASH = 0.15              -- inclinación de cámara que se ignora (para no clavarte al suelo)
local ESCALA_ONDA_MEGA = 0.55                -- tamaño de los discos y la onda de aire del impulso
local ENFRIAMIENTO_DASH = 0.35               -- s entre impulsos
local BUFFER_DASH = 0.18                     -- s: si pulsas Q un instante ANTES de que acabe el enfriamiento, se ejecuta en cuanto acaba
local ACEL_DASH = 100000                     -- tope de fuerza (studs/s² * masa): alto para alcanzar la velocidad objetivo al instante

-- Agarre estilo Passive Bang: tras un impulso, si el objetivo del Lock está cerca, te pegas a su espalda un instante
-- y su cuerpo te frena. (Solo con Lock activo.)
local AGARRE_ACTIVO = true
local AGARRE_DISTANCIA = 16                  -- studs: "cerca" del objetivo
local AGARRE_DURACION = 0.35                 -- s que dura el agarre
local AGARRE_RADIO = 3.2                     -- studs detrás del objetivo
local AGARRE_AJUSTE_Y = -1.0                 -- altura respecto a su HumanoidRootPart (negativo = más bajo, como el TP de Passive Bang)
local AGARRE_RIGIDEZ = 45                    -- lo rápido que te pegas a su espalda
local AGARRE_MARGEN_VACIO = 80               -- sobre FallenPartsDestroyHeight se considera vacío (no agarra ni sigue)

-- Impacto contra el suelo con el impulso -> caída épica
local IMPACTO_VEL_Y_MIN = 30                 -- studs/s hacia abajo mínimos para contar como impacto
local IMPACTO_ESCALA_VEL = 0.45              -- velocidad de choque -> intensidad del aterrizaje (como caer desde esa altura)                     -- tope de fuerza (studs/s² * masa): alto para que la velocidad objetivo se alcance al instante

-- Mega impulso: animación de CAMINAR HACIA ADELANTE de Fly con el vuelo activo (IDS_MEGA.caminar, Action3)
local VEL_ANIM_CAMINAR = 1.5                   -- velocidad de reproducción durante el impulso
local FADE_CAMINAR = 0.25                    -- salida suave de la animación

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
local dash = { buffer = 0, fin = 0, listo = 0, dir = Vector3.zero, t0 = 0, dur = 1.2, v0 = 0, c = 0, ult = 0, inerciaFin = 0 }
local ascenso = { t0 = 0, dur = 0, v0 = 0 } -- ascenso por altura (despegue y saltos aéreos)

-- Empieza un ascenso que llega a "altura" studs en "dur" s (v0 = (n+1)h/T, v = v0*(1-t/T)^n: acaba suave). Devuelve v0.
local function IniciarAscenso(altura, dur)
	ascenso.t0 = tick()
	ascenso.dur = dur
	ascenso.v0 = (POTENCIA_ASCENSO + 1) * altura / dur
	return ascenso.v0
end

-- Dirección de la cámara para el impulso: ignora una pequeña inclinación (suave, sin saltos) para no clavarte al suelo.
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

-- Gira el vector "actual" hacia "deseada" como máximo maxRad radianes.
local function GirarHacia(actual, deseada, maxRad)
	local ang = math.acos(math.clamp(actual:Dot(deseada), -1, 1))

	if ang < 1e-3 or maxRad <= 0 then return actual end

	local t = math.min(1, maxRad / ang)

	if t >= 1 then return deseada end

	local r = CFrame.lookAt(Vector3.zero, actual):Lerp(CFrame.lookAt(Vector3.zero, deseada), t).LookVector

	return r.Magnitude > 0.01 and r.Unit or actual
end

-- Resuelve v0 y c para recorrer D studs en T s acabando a vh: vh * (e^(cT) - 1) / c = D (bisección).
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

-- Velocidad del mega impulso en la fracción k (0..1) de su duración: v0 * e^(-c*t). Nunca llega a un corte seco:
-- acaba en VELOCIDAD_SALIDA_DASH y de ahí sigue el frenado suave de ACEL_INERCIA_DASH.
local function VelocidadImpulso(k)
	return dash.v0 * math.exp(-dash.c * math.clamp(k, 0, 1) * dash.dur)
end

-- Estado del mega impulso
local mega = {
	activo = false,
	t0 = 0,
	dir = Vector3.zero,
	agarre = nil, -- { t0, root, vel } mientras estás pegado al objetivo
}

-- Parámetros de raycast del personaje, reutilizados (no se crea ninguna tabla nueva por cuadro).
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

-- Vector sin NaN ni infinitos (guarda ante cámaras o físicas raras).
local function EsFinito(v)
	return v.X == v.X and v.Y == v.Y and v.Z == v.Z
		and math.abs(v.X) < 1e9 and math.abs(v.Y) < 1e9 and math.abs(v.Z) < 1e9
end

-- Posición REAL de los pies (entre los dos pies, en su punto más bajo y pegada al suelo si lo hay), no una fórmula
-- con HipHeight: así los efectos salen de los pies y no de los tobillos.
local function PosicionPies(char, raiz, hum)
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

	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude
	rp.FilterDescendantsInstances = { char }
	rp.RespectCanCollide = true

	local hit = workspace:Raycast(pos + Vector3.new(0, 1.5, 0), Vector3.new(0, -2.7, 0), rp)

	if hit then
		pos = Vector3.new(pos.X, hit.Position.Y, pos.Z)
	end

	return pos
end

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
	{ id = "AGARRE_ACTIVO", nombre = "Agarre al objetivo tras el impulso", tipo = "bool",
			get = function() return AGARRE_ACTIVO end, set = function(v) AGARRE_ACTIVO = v end },
	{ id = "AGARRE_DISTANCIA", nombre = "Distancia 'cerca' del agarre (studs)", tipo = "number", min = 2, max = 80,
			get = function() return AGARRE_DISTANCIA end, set = function(v) AGARRE_DISTANCIA = v end },
	{ id = "AGARRE_DURACION", nombre = "Duración del agarre (s)", tipo = "number", min = 0.05, max = 2,
			get = function() return AGARRE_DURACION end, set = function(v) AGARRE_DURACION = v end },
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

	-- Agarre (Passive Bang): pegado al objetivo tu velocidad es la suya; el CFrame lo coloca MegaPaso.
	if mega.agarre then
		fuerzaVel.VectorVelocity = mega.agarre.vel
		fuerzaVel.MaxAxesForce = Vector3.new(masa * ACEL_DASH, masa * ACEL_DASH, masa * ACEL_DASH)
		return
	end

	-- Mega impulso: una fuerza lineal con velocidad que decae suave (VelocidadImpulso) y dirección GIRABLE con la cámara.
	if tick() < dash.fin then
		local ahora = tick()
		local dtImp = math.clamp(ahora - dash.ult, 0, 0.1)
		local cam = workspace.CurrentCamera

		dash.ult = ahora

		if cam then
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

	-- Tras el impulso, si no pulsas nada, el último tramo de velocidad se apaga suave en vez de frenar en seco.
	if not conInput and tick() < dash.inerciaFin then
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
			objetivoY = math.max(objetivoY, ascenso.v0 * (1 - k) ^ POTENCIA_ASCENSO)
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
		return PosicionPies()
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
		estela.Color = ColorSequence.new(COLOR_AFO_CLARO, COLOR_AIRE)
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
			vida = -1,
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
		local rapidez = math.abs(vy)
		local minimo = vy >= 0 and VELOCIDAD_MIN_SUBIDA or VELOCIDAD_MIN_CAIDA

		-- Los mismos hilos de viento al caer (hacia abajo) y al subir: la Trail siempre queda detrás del movimiento.
		if not (viva and rapidez > minimo) then
			ApagarRayas()
			return
		end

		local k = math.clamp((rapidez - minimo) / math.max(VELOCIDAD_MAX_CAIDA - minimo, 1), 0, 1)
		local opacidad = 0.88 - 0.3 * k
		local vida = math.min(VIDA_RAYA, LARGO_MAX_RAYA / rapidez)
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

			if math.abs(r.vida - vida) > 0.015 then
				r.vida = vida
				r.estela.Lifetime = vida
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

	-- ---------- Mega impulso: estética Shigaraki (temporada 8), TODO en amarillo ----------
	-- Al impulsarte: unos discos amarillos se ACUMULAN rápido sobre ti (se cierran) y de ahí sale una ONDA DE AIRE
	-- (anillos que se abren + halo). Sin clones, sin destello de pantalla, sin sacudida de cámara.
	local E = {}

	E.impulso = { activo = false, t0 = 0, dur = 0.6, fin = 0, dir = Vector3.zAxis, accEstela = 0, ondaPend = false, ondaEn = 0 }
	E.NSEG = 24            -- segmentos por anillo
	E.NESPINAS = 7         -- espinas por anillo
	E.MAX_ANILLOS = 4      -- tope de anillos vivos a la vez
	E.MAX_DISCOS = 12      -- tope de discos/ondas vivos a la vez
	E.anillosElec = {}
	E.discos = {}
	E.poolDiscos = {}      -- anillos ya creados listos para reutilizar

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

	-- Halo de aire amarillo anclado en un punto fijo (px0 -> px1 píxeles en 'dur' s).
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

	-- Halo de aire que se abre desde el cuerpo (una sola capa, pequeña y transparente).
	function E.AuraSuave()
		local raiz = rootPart

		if not raiz or not raiz.Parent or not carpeta then return end

		local bb = Instance.new("BillboardGui")
		bb.Adornee = raiz
		bb.AlwaysOnTop = false
		bb.LightInfluence = 0
		bb.Size = UDim2.fromOffset(60, 60)
		bb.ResetOnSpawn = false
		bb.Parent = carpeta

		local img = Instance.new("ImageLabel")
		img.Image = FLY_AIRSHOCK
		img.Size = UDim2.fromScale(1, 1)
		img.BackgroundTransparency = 1
		img.ImageColor3 = COLOR_AIRE
		img.ImageTransparency = 0.7
		img.ScaleType = Enum.ScaleType.Fit
		img.Parent = bb

		TweenService:Create(bb, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
			{ Size = UDim2.fromOffset(190, 190) }):Play()
		TweenService:Create(img, TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
			{ ImageTransparency = 1 }):Play()

		task.delay(0.35, function()
			pcall(function()
				bb:Destroy()
			end)
		end)
	end

	-- ---------- Discos y onda de aire (anillos con la textura de Fly, perpendiculares al impulso) ----------
	-- "entra" = el disco se CIERRA sobre ti (se acumula) con fundido de entrada y salida; si no, se ABRE y se apaga.
	local function CFrameDisco(pos, dir)
		local arriba = math.abs(dir.Y) > 0.95 and Vector3.xAxis or Vector3.yAxis

		return CFrame.lookAt(pos, pos + dir, arriba) * CFrame.Angles(math.pi / 2, 0, 0)
	end

	-- Saca un anillo del pool (o lo crea la primera vez).
	function E.TomarAnillo()
		local a = table.remove(E.poolDiscos)

		if a and a.parte.Parent then
			return a
		end

		return CrearAnillo()
	end

	function E.NuevoDisco(pos, dir, r0, r1, dur, retraso, alfa, entra)
		if not carpeta or #E.discos >= E.MAX_DISCOS then return end

		table.insert(E.discos, {
			a = E.TomarAnillo(), t = -(retraso or 0), dur = dur, r0 = r0, r1 = r1,
			pos = pos, dir = dir, alfa = alfa, entra = entra,
		})
	end

	function E.RenderDiscos(dt)
		for idx = #E.discos, 1, -1 do
			local d = E.discos[idx]

			d.t += dt

			if d.t >= d.dur or not d.a.parte.Parent then
				-- Se oculta y vuelve al pool (si su carpeta ya no existe, simplemente se descarta).
				if d.a.parte.Parent then
					PonerAnillo(d.a, CFrame.identity, 1, 0)
					table.insert(E.poolDiscos, d.a)
				end

				table.remove(E.discos, idx)
			elseif d.t >= 0 then
				local k = d.t / d.dur
				local e = 1 - (1 - k) ^ 3
				local radio = d.r0 + (d.r1 - d.r0) * e
				local fade = d.entra and (math.sin(k * math.pi) ^ 0.7) or (1 - k) ^ 1.3

				PonerAnillo(d.a, CFrameDisco(d.pos, d.dir), radio, fade * d.alfa * ALFA_MAX / 0.55)
			end
		end
	end

	-- Tres discos que se acumulan rápido sobre ti (el 2.º y 3.º un instante después, apilados detrás).
	function E.Acumular(pos, dir, esc, fuerza)
		for i = 1, 3 do
			E.NuevoDisco(pos - dir * (0.5 + 0.9 * (i - 1)), dir, (8 - 0.8 * (i - 1)) * esc, 2.6 * esc,
				0.16, 0.035 * (i - 1), 0.95 * fuerza, true)
		end
	end

	-- Onda de aire que sale al impulsarte: anillos que se abren rápido + halo de aire + destello de onda de choque.
	function E.OndaAire(pos, dir, esc, fuerza)
		E.NuevoDisco(pos, dir, 2 * esc, 11 * esc, 0.26, 0, 0.9 * fuerza, false)
		E.NuevoDisco(pos, dir, 1.5 * esc, 16 * esc, 0.32, 0.04, 0.6 * fuerza, false)

		E.AuraEn(pos, 40, 230 * esc * fuerza, 0.30, 0.5 * fuerza, FLY_AIRSHOCK)
		E.AuraEn(pos, 50, 170 * esc * fuerza, 0.18, 0.4 * fuerza, IDS_MEGA.shock)
	end

	-- ---------- Anillos eléctricos amarillos (como la referencia; los usan despegue y salto aéreo) ----------
	-- Cada anillo son segmentos neón en círculo, perpendicular a la dirección, que se expande y se apaga. Un halo
	-- translúcido da el brillo y unas pocas espinas (claras y oscuras) saltan del borde.
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

		-- límite de seguridad para no saturar de partes
		if #E.anillosElec >= E.MAX_ANILLOS then return end

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
			-- la mitad de las espinas son oscuras, como los fragmentos negros de la referencia
			local sp = E.ParteNeon(j % 2 == 0 and COLOR_ESPINA_OSCURA or COLOR_AFO_CLARO, 1)
			sp.Parent = carp
			espinas[j] = sp
		end

		table.insert(E.anillosElec, {
			t = -(retraso or 0), dur = dur, r0 = r0, r1 = r1, pos = pos, base = base,
			segs = segs, espinas = espinas, folder = carp, grosor = grosor,
			jt = 1e9, jit = {}, esp = {}, puntos = {},
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
				local alfa = math.clamp(k ^ 1.5, 0, 1)
				local grosor = a.grosor * (1 - 0.5 * k)

				-- El borde vibra, pero a ~16 Hz y poco (antes cambiaba en CADA cuadro y parpadeaba).
				a.jt += dt

				if a.jt >= 0.06 then
					a.jt = 0

					for i = 1, E.NSEG do
						a.jit[i] = 1 + E.Az(-0.03, 0.03)
					end

					for j = 1, E.NESPINAS do
						a.esp[j] = {
							i = math.random(1, E.NSEG),
							d = Vector3.new(E.Az(-0.7, 0.7), E.Az(-0.7, 0.7), E.Az(-0.7, 0.7)),
							largo = E.Az(0.7, 1.8),
						}
					end
				end

				local puntos = a.puntos -- tabla reutilizada: nada nuevo por cuadro

				for i = 1, E.NSEG do
					local ang = (i - 1) / E.NSEG * math.pi * 2
					local rr = r * a.jit[i]

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
					s[1].Transparency = 0.1 + 0.9 * alfa

					s[2].Size = Vector3.new(grosor * 2.2, grosor * 2.2, len)
					s[2].CFrame = cf
					s[2].Transparency = 0.82 + 0.18 * alfa
				end

				for j, sp in ipairs(a.espinas) do
					local dato = a.esp[j]

					if dato then
						local p = puntos[dato.i]
						local radial = p - a.pos

						if radial.Magnitude > 0.1 then
							local d = (radial.Unit + dato.d).Unit
							local largo = dato.largo * (0.6 + r / 14)

							sp.Size = Vector3.new(grosor * 0.6, grosor * 0.6, largo)
							sp.CFrame = CFrame.lookAt(p + d * largo / 2, p + d * largo)
							sp.Transparency = math.clamp(0.25 + alfa, 0, 1)
						end
					end
				end
			end
		end
	end

	-- Raya amarilla de velocidad que queda atrás (imagen alargada que mira a la cámara) y se desvanece.
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
		img.ImageTransparency = 0.5
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

	-- Relámpago fino en zigzag (se usa solo UNA vez, al arrancar el impulso).
	function E.Relampago(origen, dir)
		if not carpeta then return end

		local actual = origen
		local d = dir
		local partes = {}
		local segmentos = math.random(4, 6)
		local largo = E.Az(1.0, 1.8)

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
			p.Transparency = 0.2
			p.Size = Vector3.new(0.1, 0.1, len)
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

	-- Aura pegada al cuerpo mientras dura el impulso: contorno amarillo fino + relleno blanco-azulado casi invisible
	-- y una luz suave y CONSTANTE (antes parpadeaba al azar en cada cuadro).
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
			h.Name = "AuraImpulso"
			h.Adornee = character
			h.FillColor = COLOR_AIRE
			h.OutlineColor = COLOR_AFO
			h.FillTransparency = 0.88
			h.OutlineTransparency = 0.55
			h.DepthMode = Enum.HighlightDepthMode.Occluded
			h.Parent = carpeta
			return h
		end)

		if ok then
			E.resaltadoAura = hl
		end

		local luz = Instance.new("PointLight")
		luz.Name = "LuzImpulso"
		luz.Color = COLOR_AFO_CLARO
		luz.Brightness = 1.2
		luz.Range = 14
		luz.Parent = rootPart
		E.luzAura = luz
	end

	-- Líneas amarillas verticales entre el punto donde pulsaste Ctrl y el suelo (la caída épica "impulsada").
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
			E.QuitarAura(false)
			return
		end

		local esc = ESCALA_ONDA_MEGA / 0.55

		-- La onda de aire sale justo después de que los discos se acumulan.
		if im.ondaPend and tick() >= im.ondaEn then
			im.ondaPend = false

			local pos = rootPart.Position - im.dir * 1.2

			E.OndaAire(pos, im.dir, esc, 1)

			parteDash.CFrame = CFrame.lookAt(pos, pos - im.dir, Vector3.xAxis)
			emisorHumoDash:Emit(6)
			emisorChispasDash:Emit(8)
		end

		-- Rayas amarillas de velocidad, poco frecuentes y solo mientras el impulso va fuerte.
		local kd = (tick() - im.t0) / math.max(im.dur, 0.05)

		im.accEstela += dt

		if im.accEstela >= 0.09 then
			im.accEstela = 0

			if kd < 0.85 then
				E.CrearEstela(im.dir)
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
		E.RenderDiscos(dt)
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

	-- Despegue (pierdes la gravedad): impulso desde los pies + un anillo eléctrico fino en el suelo.
	function FX.Liberar()
		if not Preparar() then return end

		Impulsar(1)

		local pies = PiesActuales()

		if pies then
			E.NuevoAnillo(pies + Vector3.new(0, 0.25, 0), Vector3.yAxis, 1.2, 6, 0.32, 0.14, 0)
		end
	end

	-- Salto en pleno vuelo: el mismo impulso, escalado por cuánta velocidad ganas.
	function FX.RafagaAbajo(deltaV)
		if not Preparar() then return end

		local s = math.clamp((deltaV or DELTA_V_REF) / DELTA_V_REF, 0.35, 1.25)

		Impulsar(s)

		local pies = PiesActuales()

		if pies then
			E.NuevoAnillo(pies + Vector3.new(0, 0.25, 0), Vector3.yAxis, 1.0, 3.5 + 2.5 * s, 0.28, 0.12, 0)
		end
	end

	-- Impacto explícito (el slam al suelo teletransporta y no pasa por la caída rápida).
	function FX.Impacto(pos, s)
		if not Preparar() or not pos then return end

		Aterrizar(pos, s or 1)
	end

	-- Anillo eléctrico suelto (lo usa el aterrizaje épico, que vive fuera de este bloque).
	function FX.AnilloElectrico(pos, dir, r0, r1, dur, grosor, retraso)
		if not Preparar() or not pos or not dir then return end

		E.NuevoAnillo(pos, dir, r0, r1, dur, grosor, retraso)
	end

	-- Mega impulso: sonido + discos que se acumulan + onda de aire + halo + rayas amarillas.
	-- Sin clones, sin destello de pantalla ni sacudida de cámara.
	function FX.Dash(dir, duracion)
		if not Preparar() or not rootPart or not dir then return end

		local pos = rootPart.Position
		local esc = ESCALA_ONDA_MEGA / 0.55
		-- Los efectos duran poco aunque la fuerza del impulso se alargue en una cola suave.
		local dur = math.min(duracion or DURACION_DASH, 0.6)

		E.SonidoLocal(IDS_MEGA.sfx, 0.88)

		E.Acumular(pos, dir, esc, 1)
		E.IniciarAura()

		E.impulso.activo = true
		E.impulso.t0 = tick()
		E.impulso.dur = dur
		E.impulso.fin = tick() + dur + 0.12
		E.impulso.dir = dir
		E.impulso.accEstela = 0
		E.impulso.ondaPend = true
		E.impulso.ondaEn = tick() + 0.14
	end

	-- Mientras te direccionas, los efectos siguen la dirección actual.
	function FX.SetDirDash(dir)
		if dir then
			E.impulso.dir = dir
		end
	end

	-- Ctrl en el aire: un "leve mega turbo" hacia abajo desde el punto donde pulsaste (discos + onda de aire +
	-- líneas hasta el suelo), para que se sienta que te impulsaste con tus poderes.
	function FX.CaidaMega(origen, suelo, altura)
		if not Preparar() or not origen then return end

		local dir = Vector3.new(0, -1, 0)
		local esc = 0.75 * ESCALA_ONDA_MEGA / 0.55

		E.SonidoLocal(IDS_MEGA.sfx, 0.45)
		E.Acumular(origen, dir, esc, 0.8)
		E.LineasCaida(origen, suelo)

		task.delay(0.14, function()
			if not carpeta then return end

			pcall(function()
				E.OndaAire(origen, dir, esc, 0.75)

				parteDash.CFrame = CFrame.lookAt(origen, origen - dir, Vector3.xAxis)
				emisorHumoDash:Emit(5)
				emisorChispasDash:Emit(6)
			end)
		end)
	end

	-- Fin del mega impulso: deja de soltar efectos y apaga el aura.
	function FX.FinDash(inmediato)
		E.impulso.activo = false
		E.QuitarAura(inmediato == true)
	end

	function FX.Destruir()
		E.QuitarAura(true)
		E.impulso.activo = false
		E.anillosElec = {}
		E.discos = {}
		E.poolDiscos = {}

		if carpeta then
			carpeta:Destroy()
		end

		carpeta = nil
		anillosCono, anillosCarga, rayas = {}, {}, {}
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

-- habilidad: true si durante ESTE tiempo en el aire usaste la habilidad de flotar (solo así hay efecto de aterrizaje).
local seguimiento = { enAire = false, pico = 0, ultimo = 0, habilidad = false }
local tokenAterrizaje = 0

-- Evita que un aterrizaje se cuente dos veces (slam + detección natural).
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
				polvoBase = c:Lerp(COLOR_AFO, 0.12)
			end
		end

		local polvoClaro = polvoBase:Lerp(COLOR_AFO_CLARO, 0.2)
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

		-- (sin aros en el suelo: la caída épica ahora lleva su leve mega turbo hacia abajo desde donde pulsaste Ctrl)

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
	return PosicionPies(raiz.Parent, raiz, hum)
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
local function ForzarTPsY(yFinal, posXZ)
	local n = math.max(TP_Y_REPETICIONES, 1)
	local char = character
	-- Solo se conserva el giro (yaw): de pie y recto, sin inclinación heredada del impulso.
	local _, yaw = rootPart.CFrame:ToOrientation()

	local function Aplicar(i)
		if not (rootPart and rootPart.Parent and character == char) then return false end

		local p = rootPart.Position
		local desfase = (i < n) and (TP_Y_ALTURAS[(i - 1) % #TP_Y_ALTURAS + 1] or 0) or 0

		-- X y Z: el punto de impacto si se da (impulso contra el suelo, solo la 1.ª vez); si no, la posición actual.
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
	local volando = isFloating

	if humanoid.FloorMaterial == Enum.Material.Air then
		if not seguimiento.enAire then
			seguimiento.enAire = true
			seguimiento.pico = py
		end

		-- Basta con haber flotado en algún momento de esta caída (aunque luego la desactives en el aire).
		if volando then
			seguimiento.habilidad = true
		end

		seguimiento.pico = math.max(seguimiento.pico, py)
		return
	end

	if seguimiento.enAire then
		seguimiento.enAire = false

		local altura = seguimiento.pico - py

		-- Una caída normal (salto, caída libre, escalón...) NO dispara el efecto: solo las posteriores a flotar.
		if seguimiento.habilidad and tick() - seguimiento.ultimo > 0.6 and altura >= ALTURA_IMPACTO_MIN then
			seguimiento.ultimo = tick()
			AterrizajeNatural(altura)
		end

		seguimiento.habilidad = false
	elseif not volando then
		-- En el suelo y sin volar: nada pendiente (evita arrastrar el flag de un despegue fallido).
		seguimiento.habilidad = false
	end

	seguimiento.pico = py
end

-- ==========================================
-- MEGA IMPULSO (Q)
-- ==========================================
-- Es una fuerza lineal: al pulsar Q se calcula una curva de velocidad que arranca fuerte y se apaga suave
-- (ver VelocidadImpulso) y ActualizarFuerzas() empuja la LinearVelocity con ella. Mientras dura puedes
-- DIRECCIONARLO con la cámara (la dirección gira a GIRO_DASH rad/s; la velocidad sigue su curva).
-- Dos sistemas puntuales, ambos con condiciones estrictas:
--   * Agarre (estilo Passive Bang): si el impulso te deja CERCA del objetivo del Lock, te pegas a su espalda un
--     instante y su cuerpo absorbe la energía del impulso. Es lo único que toca el CFrame, y solo AGARRE_DURACION s.
--   * Impacto con el suelo: si el impulso te lanza contra el suelo, se ejecuta la caída épica con la potencia
--     que llevabas (velocidad de impacto) y te coloca de pie sobre el suelo.

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

local IniciarDash -- (se define más abajo; MegaPaso lo usa para el búfer de Q)

local function TerminarMega()
	if not mega.activo then return end

	mega.activo = false
	dash.fin = 0

	PonerPoseBrazos(false)
	FX.FinDash()
end

-- ---------- Agarre al objetivo del Lock (estilo Passive Bang) ----------
local function PosicionEnVacio(pos)
	return pos.Y < workspace.FallenPartsDestroyHeight + AGARRE_MARGEN_VACIO
end

-- Solo el objetivo del Lock de Fly (lo publica en el Character). Sin Lock no hay agarre.
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

local function SoltarAgarre()
	if not mega.agarre then return end

	mega.agarre = nil

	-- Sales con la velocidad del objetivo (ya la llevas) y el último tramo se apaga suave.
	dash.inerciaFin = tick() + INERCIA_DASH
end

local function IniciarAgarre(troot)
	mega.agarre = { t0 = tick(), root = troot, vel = troot.AssemblyLinearVelocity }

	-- El impulso termina aquí: su energía se la come el cuerpo del objetivo.
	mega.activo = false
	mega.agarre = nil
	dash.fin = 0

	PonerPoseBrazos(false)
	FX.FinDash()

	pcall(FX.AnilloElectrico, troot.Position, dash.dir, 1, 5, 0.25, 0.12, 0)
end

-- ¿El impulso te deja cerca del objetivo del Lock y vas hacia él? Entonces te agarras.
local function RevisarAgarre(dt)
	if not AGARRE_ACTIVO or mega.agarre then return false end

	local troot = ObtenerObjetivoLock()

	if not troot then return false end

	local hacia = troot.Position - rootPart.Position
	local dist = hacia.Magnitude
	local vel = rootPart.AssemblyLinearVelocity.Magnitude

	-- Margen extra por lo que avanzas en un cuadro, para no pasar de largo a alta velocidad.
	if dist > AGARRE_DISTANCIA + vel * dt then return false end
	if dist > 1 and hacia.Unit:Dot(dash.dir) < 0.2 then return false end
	if PosicionEnVacio(troot.Position) then return false end

	IniciarAgarre(troot)

	return true
end

local function PasoAgarre(dt)
	local ag = mega.agarre
	local troot = ag.root

	if not (troot and troot.Parent) or tick() - ag.t0 >= AGARRE_DURACION
		or PosicionEnVacio(troot.Position) or PosicionEnVacio(rootPart.Position)
        or (troot.Position - rootPart.Position).Magnitude > AGARRE_DISTANCIA * 4 then
		SoltarAgarre()
		return
	end

	ag.vel = troot.AssemblyLinearVelocity

	-- Detrás del objetivo y más bajo que su centro, como el TP de Passive Bang.
	local atras = -troot.CFrame.LookVector
	local plano = Vector3.new(atras.X, 0, atras.Z)
	plano = plano.Magnitude > 0.01 and plano.Unit or Vector3.zAxis

	local deseada = troot.Position + plano * AGARRE_RADIO + Vector3.new(0, AGARRE_AJUSTE_Y, 0)
	local nueva = rootPart.Position:Lerp(deseada, 1 - math.exp(-AGARRE_RIGIDEZ * dt))

	rootPart.CFrame = CFrame.lookAt(nueva, Vector3.new(troot.Position.X, nueva.Y, troot.Position.Z))
	rootPart.AssemblyLinearVelocity = ag.vel
	rootPart.AssemblyAngularVelocity = Vector3.zero
end

-- ---------- Impacto contra el suelo con el impulso -> caída épica ----------
-- Rayo barrido (≈1.5 cuadros por delante, hasta la altura de los pies): detecta el suelo ANTES de atravesarlo aunque
-- vayas a cientos de studs/s. La potencia del aterrizaje sale de la velocidad real con la que chocas.
local function RevisarImpactoSuelo(dt)
	local vel = rootPart.AssemblyLinearVelocity

	if vel.Y > -IMPACTO_VEL_Y_MIN then return false end

	local alcance = humanoid.HipHeight + rootPart.Size.Y / 2

	local avance = vel * math.max(dt, 1 / 120) * 1.5
	local res = workspace:Raycast(rootPart.Position, avance + Vector3.new(0, -alcance, 0), ParamsPersonaje())

	if not res or res.Normal.Y < 0.5 then return false end

	-- Si debajo hay un jugador no hay caída épica (misma regla que Ctrl).
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

-- Se llama cada cuadro desde el bucle principal.
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

	-- Búfer de Q: si se pulsó justo antes de acabar el enfriamiento y sigues volando, se lanza ahora.
	if dash.buffer > 0 then
		local ahora = tick()

		if ahora > dash.buffer or not isFloating then
			dash.buffer = 0
		elseif ahora >= dash.listo then
			IniciarDash()
		end
	end

	if mega.activo then
		-- Se agotó la energía del impulso, o dejaste de volar (slam, caída épica, muerte...).
		if tick() >= dash.fin or not isFloating then
			TerminarMega()
			return
		end

		FX.SetDirDash(dash.dir)

		if RevisarImpactoSuelo(dt) then return end
		if RevisarAgarre(dt) then return end

		-- La animación de caminar solo mientras el impulso va fuerte.
		PonerPoseBrazos((tick() - dash.t0) / math.max(dash.dur, 0.05) < 0.6)
	elseif animCaminar and animCaminar.IsPlaying then
		PonerPoseBrazos(false)
	end
end

function IniciarDash()
	if not (rootPart and humanoid and isFloating) then return end
	if mega.agarre then return end

	local ahora = tick()

	if ahora < dash.listo then
		-- Aún en enfriamiento: se recuerda la pulsación un instante (se siente más fluido en combate).
		dash.buffer = ahora + BUFFER_DASH
		return
	end

	dash.buffer = 0

	local cam = workspace.CurrentCamera

	if not cam then return end

	-- Dirección inicial: exactamente hacia donde mira la cámara. Después puedes girarla con la cámara.
	local dir = DireccionCamara(cam)

	dash.dir = dir
	dash.t0 = ahora
	dash.ult = ahora
	dash.dur = math.max(DURACION_DASH, 0.2)
	dash.v0, dash.c = ResolverImpulso(DISTANCIA_DASH, dash.dur, VELOCIDAD_SALIDA_DASH)
	dash.fin = ahora + dash.dur
	dash.inerciaFin = dash.fin + INERCIA_DASH
	dash.listo = ahora + ENFRIAMIENTO_DASH

	mega.activo = true
	mega.t0 = ahora
	mega.dir = dir

	PonerPoseBrazos(true)

	-- Efectos aislados: si algo falla en lo visual, el impulso sigue funcionando.
	pcall(FX.Dash, dir, dash.dur)
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

	-- También cuenta como jugador el que quede justo bajo tus pies (rayos al suelo).
	local suelo, hayJugador = BuscarSueloSeguro(rootPart, character)

	if hayJugador or not suelo then return end

	local altura = rootPart.Position.Y - suelo.Y

	if altura < ALTURA_MIN_EPICA then return end

	-- Condición 2 cumplida (Ctrl) + aire + sin jugador: caída épica.
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

	-- Leve mega turbo hacia abajo desde el punto donde pulsaste Ctrl (en lugar del aro del suelo).
	pcall(FX.CaidaMega, rootPart.Position, suelo, altura)

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
	-- (sin sacudida de cámara: movía la cámara con la que apuntas el mega impulso)

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
