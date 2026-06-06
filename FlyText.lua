-- FlyText.lua
-- Módulo responsable de textos e idioma.
-- Lee el archivo AllForOne/lang.txt para mantenerse sincronizado con el hub.

local FlyLang = {
    ES = {
        fly_title        = "  VUELO",
        mode_normal      = "NORMAL",
        mode_fast        = "TURBO  ×",
        mode_mega        = "MEGA  ×",
        mode_megaup      = "⬆ MEGA UP  ×",
        lock_label       = "LOCK",
        lock_hint_prefix = "Apuntar + ",
        noclip_title     = "NOCLIP",
        noclip_space     = "Espacio",
        noclip_ctrl      = "Ctrl (bajar)",
        noclip_mega      = "Mega Turbo",
        height_below     = "studs abajo",
        height_above     = "studs arriba",
        height_same      = "↔ mismo nivel",
        speed_base       = "Vel. base",
        speed_turbo_mult = "Turbo ×",
        speed_mega_mult  = "Mega ×",
        speed_reset      = "🔄  Reset",
    },
    EN = {
        fly_title        = "  FLY",
        mode_normal      = "NORMAL",
        mode_fast        = "TURBO  ×",
        mode_mega        = "MEGA  ×",
        mode_megaup      = "⬆ MEGA UP  ×",
        lock_label       = "LOCK",
        lock_hint_prefix = "Aim + ",
        noclip_title     = "NOCLIP",
        noclip_space     = "Space",
        noclip_ctrl      = "Ctrl (down)",
        noclip_mega      = "Mega Turbo",
        height_below     = "studs below",
        height_above     = "studs above",
        height_same      = "↔ same level",
        speed_base       = "Base speed",
        speed_turbo_mult = "Turbo ×",
        speed_mega_mult  = "Mega ×",
        speed_reset      = "🔄  Reset",
    },
}

local currentLang = "ES"   -- por defecto
local FT = FlyLang.ES

-- Carga el idioma desde el archivo del hub
local function reloadLang()
    local lang = "ES"
    local success, data = pcall(function()
        return readfile("AllForOne/lang.txt")
    end)
    if success and (data == "EN" or data == "ES") then
        lang = data
    end
    currentLang = lang
    FT = FlyLang[lang]
end

-- Inicializar al cargar el módulo
reloadLang()

-- API pública
local FlyText = {}

-- Obtiene el texto completo según la clave
function FlyText.get(key)
    return FT[key] or key
end

-- Obtiene el idioma actual ("ES" o "EN")
function FlyText.getLang()
    return currentLang
end

-- Recarga el idioma desde el archivo (útil si el hub cambió de idioma mientras el vuelo estaba activo)
function FlyText.reload()
    reloadLang()
end

-- Devuelve el texto del modo según el modo y multiplicador
function FlyText.getModeText(mode, multiplier)
    if mode == "normal" then
        return FT.mode_normal
    elseif mode == "fast" then
        return FT.mode_fast .. tostring(multiplier)
    elseif mode == "turbo" then
        return FT.mode_mega .. tostring(multiplier)
    elseif mode == "megaup" then
        return FT.mode_megaup .. tostring(multiplier)
    end
    return mode
end

-- Devuelve el texto de altura relativa (positivo = target más abajo, negativo = target más arriba)
function FlyText.getHeightDiffText(diff)
    if diff > 0 then
        return "↓ " .. diff .. " " .. FT.height_below
    elseif diff < 0 then
        return "↑ " .. math.abs(diff) .. " " .. FT.height_above
    else
        return FT.height_same
    end
end

-- Devuelve el color sugerido para el texto de altura según la diferencia
function FlyText.getHeightColor(diff)
    if diff > 0 then
        return Color3.fromRGB(150, 220, 255)   -- azul: ventaja
    elseif diff < 0 then
        return Color3.fromRGB(255, 200, 100)   -- naranja: peligro
    else
        return Color3.fromRGB(150, 255, 150)   -- verde: igual
    end
end

-- Devuelve el color sugerido para la salud (rojo si baja, etc.)
function FlyText.getHealthColor(health, maxHealth)
    if health < 30 then
        return Color3.fromRGB(255, 80, 80)
    elseif health < 60 then
        return Color3.fromRGB(255, 200, 80)
    else
        return Color3.fromRGB(80, 255, 80)
    end
end

return FlyText
