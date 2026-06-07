-- ═══════════════════════════════════════════════════════════════════════════
-- MÓDULO: Fly (Main)
-- Versión standalone: descarga sus propios submódulos desde GitHub.
-- No requiere que los submódulos estén en la misma carpeta.
-- ═══════════════════════════════════════════════════════════════════════════

print("version 1.66")

-- ============================================================
-- URLs de los submódulos (rama Fly del repositorio)
-- ============================================================
local BASE_URL = "https://raw.githubusercontent.com/AllForOneScripts/Quirks/Fly/"
local MODULES = {
    FlyText   = BASE_URL .. "Text.lua",
    FlyAnim   = BASE_URL .. "Anim.lua",
    FlyLogic  = BASE_URL .. "Logic.lua",
    FlyControl= BASE_URL .. "Control.lua",
}

-- ============================================================
-- Función para cargar un módulo desde URL
-- ============================================================
local function loadModuleFromURL(url, name)
    local success, result = pcall(function()
        return loadstring(game:HttpGet(url))()
    end)
    if not success or not result then
        warn("[Fly] Error cargando módulo " .. name .. " desde " .. url)
        return nil
    end
    return result
end

-- ============================================================
-- Cargar todos los submódulos
-- ============================================================
local FlyText   = loadModuleFromURL(MODULES.FlyText, "FlyText")
local FlyAnim   = loadModuleFromURL(MODULES.FlyAnim, "FlyAnim")
local FlyLogic  = loadModuleFromURL(MODULES.FlyLogic, "FlyLogic")
local FlyControl = loadModuleFromURL(MODULES.FlyControl, "FlyControl")

-- Verificar que todos se cargaron correctamente
if not FlyText or not FlyAnim or not FlyLogic or not FlyControl then
    error("[Fly] No se pudieron cargar todos los submódulos. Vuelo no disponible.")
end

-- ============================================================
-- Variables de estado local
-- ============================================================
local isInitialized = false
local currentFlyKey = Enum.KeyCode.C
local currentLockKey = Enum.KeyCode.X

-- ============================================================
-- API PÚBLICA (igual que el monolítico)
-- ============================================================
local M = {}

function M.Start(lplrRef, flyKeyRef)
    if not lplrRef then
        warn("[Fly] No se proporcionó jugador local.")
        return
    end
    
    if flyKeyRef then
        currentFlyKey = flyKeyRef
    end
    
    -- Sincronizar idioma con el hub (esto requiere readfile, funciona en ejecución)
    if FlyText.Reload then
        FlyText.Reload()
    end
    
    -- Inicializar el controlador principal
    FlyControl.Start(lplrRef, currentFlyKey)
    
    -- Configurar la tecla de lock si el módulo lo soporta
    if FlyControl.SetLockKey then
        FlyControl.SetLockKey(currentLockKey)
    end
    
    isInitialized = true
end

function M.Stop()
    if not isInitialized then return end
    FlyControl.Stop()
    isInitialized = false
end

function M.Toggle(state)
    if not isInitialized then
        warn("[Fly] No iniciado. Llama a Start() primero.")
        return
    end
    FlyControl.Toggle(state)
end

function M.SetKey(keyCode)
    currentFlyKey = keyCode
    if isInitialized and FlyControl.SetKey then
        FlyControl.SetKey(keyCode)
    end
end

function M.SetLockKey(keyCode)
    currentLockKey = keyCode
    if isInitialized and FlyControl.SetLockKey then
        FlyControl.SetLockKey(keyCode)
    end
end

function M.GetFlyKey()
    return currentFlyKey
end

function M.GetLockKey()
    return currentLockKey
end

function M.IsEnabled()
    return isInitialized and FlyControl.IsEnabled and FlyControl.IsEnabled() or false
end

function M.Bypass(duration, reason)
    if not isInitialized then return end
    if FlyControl.Bypass then
        FlyControl.Bypass(duration, reason)
    end
end

return M
