-- ═══════════════════════════════════════════════════════════════════════════
--  ULTRA INSTINCT TABLE
--  Tabla de Dodges que Ultra Instinct descarga al ejecutarse (igual que Omniblock Maths).
--  Cada entrada ES el disparador: cuando un enemigo reproduce esa animacion, Ultra Instinct
--  esquiva y lanza el efecto de Dodge Anims. No hay tecla manual.
--
--  Cada entrada:
--    AnimationId = id de la animacion del ataque enemigo
--    Delay       = segundos desde que empieza la animacion hasta que hay que estar esquivando
--    Duration    = segundos que dura el estado de esquive (y la sesion si Mode = "Ghost")
--    Distance    = (opcional) solo se esquiva si el enemigo esta a esta distancia o menos (studs)
--    DisplayName = nombre que se muestra en la tarjeta / alerta
--
--  -- Dodge Anims
--    Mode        = "Random" | 1 | 2 | "Ghost"   (o "Off" para no lanzar animacion)
--                  Random/1/2: un esquive al activarse; si durante el esquive llega otro
--                              disparador de la lista, se lanza otra vez cuando pega (tras su Delay)
--                  Ghost:      fantasmas + animacion en bucle durante toda la Duration
--    Mute        = true para que ese esquive no suene
-- ═══════════════════════════════════════════════════════════════════════════
return {
    Bakugo_Nuker = {
        AnimationId = "18673594132",
        Delay = 5,
        Duration = 5,
        DisplayName = "Bakugo Supreme Nuker",
-- Dodge Anims
        Mode = "Random",
        Mute = false,
    },
    Bakugo_Supreme_Awakening = {
        AnimationId = "18210811961",
        Delay = 10.8,
        Duration = 4.5,
        DisplayName = "Bakugo Supreme Awakening",
-- Dodge Anims
        Mode = "Random",
        Mute = false,
    },
    Dabi_Ultimate_Grab = {
        AnimationId = "13618038577",
        Delay = 0,
        Duration = 0.67,
        Distance = 25,
        DisplayName = "Dabi Ultimate Grab",
-- Dodge Anims
        Mode = "Random",
        Mute = false,
    },
    Dabi_Awakening = {
        AnimationId = "13584284573",
        Delay = 2.8,
        Duration = 1.25,
        Distance = 40,
        DisplayName = "Dabi Awakening",
-- Dodge Anims
        Mode = "Random",
        Mute = false,
    },
    Dabi_Ultimate_Rush = {
        AnimationId = "13845967429",
        Delay = 0,
        Duration = 1.5,
        Distance = 60,
        DisplayName = "Dabi Ultimate Rush",
-- Dodge Anims
        Mode = "Random",
        Mute = false,
    },
    Dabi_Ultimate_Eruption = {
        AnimationId = "13644046903",
        Delay = 0,
        Duration = 3.5,
        Distance = 50,
        DisplayName = "Dabi Ultimate Eruption",
-- Dodge Anims
        Mode = "Random",
        Mute = false,
    },
    Deku_Ultimate_1000000 = {
        AnimationId = "129634511518053",
        Delay = 3,
        Duration = 1.8,
        Distance = 300,
        DisplayName = "Deku Ultimate 1000000%",
-- Dodge Anims
        Mode = "Random",
        Mute = false,
    },
    Deku_Ultimate_Combo = {
        AnimationId = "18340622535",
        Delay = 0.7,
        Duration = 1.75,
        Distance = 150,
        DisplayName = "Deku Ultimate Combo",
-- Dodge Anims
        Mode = "Random",
        Mute = false,
    },
    Deku_Ultimate_Grab = {
        AnimationId = "13273487545",
        Delay = 0.5,
        Duration = 1,
        Distance = 50,
        DisplayName = "Deku Ultimate Grab",
-- Dodge Anims
        Mode = "Random",
        Mute = false,
    },
    Deku_Ultimate_Kick = {
        AnimationId = "13233337912",
        Delay = 0,
        Duration = 1.35,
        Distance = 200,
        DisplayName = "Deku Ultimate Kick",
-- Dodge Anims
        Mode = "Random",
        Mute = false,
    },
}
