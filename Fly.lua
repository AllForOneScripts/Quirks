-- ═══════════════════════════════════════════════════════════════════════════
-- MÓDULO: Fly (Main)
-- Punto de entrada único del sistema de vuelo.
-- Requiere e inicializa los submódulos FlyText, FlyAnim, FlyLogic y FlyControl.
-- Expone la API pública que utiliza el hub All For One.
-- ═══════════════════════════════════════════════════════════════════════════

print("version 1.66")   -- Mantiene la misma versión que el monolítico

-- ============================================================
-- CARGAR SUBMÓDULOS (asumiendo que están en la misma carpeta)
-- ============================================================
local FlyText   = require(script.Parent.FlyText)
local FlyAnim   = require(script.Parent.FlyAnim)
local FlyLogic  = require(script.Parent.FlyLogic)
local FlyControl = require(script.Parent.FlyControl)

-- ============================================================
-- INICIALIZACIÓN DIFERIDA
-- ============================================================
local isInitialized = false
local lplr = nil
local flyKey = Enum.KeyCode.C

-- Esta función se llamará desde M.Start
local function ensureInitialized(lplrRef, flyKeyRef)
    if isInitialized then return true end
    if not lplrRef then return false end
    
    -- Guardar referencias
    lplr = lplrRef
    if flyKeyRef then flyKey = flyKeyRef end
    
    -- Sincronizar idioma con el hub (lee AllForOne/lang.txt)
    FlyText.Reload()
    
    -- Inicializar FlyAnim y FlyLogic (inyectan funciones en el estado compartido)
    -- Nota: FlyControl ya contiene el estado 'flyanim' internamente.
    -- Pero necesitamos pasarle las referencias a los submódulos.
    -- La forma correcta es que FlyControl ya haga internamente FlyAnim.Initialize y FlyLogic.Initialize.
    -- Sin embargo, para evitar doble inicialización, FlyControl ya lo hace en su propio M.Start.
    -- Así que simplemente llamamos a FlyControl.Start, que a su vez inicializa todo.
    
    -- Opcional: Podríamos pasar parámetros adicionales si FlyControl lo requiere.
    -- Por ahora, FlyControl.Start ya recibe lplr y flyKey.
    
    isInitialized = true
    return true
end

-- ============================================================
-- API PÚBLICA (expuesta al hub)
-- ============================================================
local M = {}

--- Inicia el sistema de vuelo.
--- @param lplrRef Player - El jugador local.
--- @param flyKeyRef Enum.KeyCode - Tecla para activar/desactivar el vuelo (opcional).
function M.Start(lplrRef, flyKeyRef)
    if not lplrRef then
        warn("[Fly] No se proporcionó lplr. No se puede iniciar.")
        return
    end
    
    -- Asegurar que los submódulos estén cargados (FlyControl se encarga de todo)
    if not ensureInitialized(lplrRef, flyKeyRef) then
        warn("[Fly] Falló la inicialización.")
        return
    end
    
    -- Delegar a FlyControl
    FlyControl.Start(lplrRef, flyKeyRef or flyKey)
end

--- Detiene el sistema de vuelo y limpia recursos.
function M.Stop()
    if not isInitialized then return end
    FlyControl.Stop()
    isInitialized = false
end

--- Activa o desactiva el vuelo manualmente.
--- @param state boolean - true para activar, false para desactivar.
function M.Toggle(state)
    if not isInitialized then
        warn("[Fly] No inicializado. Llama a Start() primero.")
        return
    end
    FlyControl.Toggle(state)
end

--- Cambia la tecla de activación del vuelo.
--- @param keyCode Enum.KeyCode
function M.SetKey(keyCode)
    if not isInitialized then
        -- Permitir cambiar la tecla incluso antes de iniciar
        flyKey = keyCode
        if FlyControl.SetKey then
            FlyControl.SetKey(keyCode)
        end
        return
    end
    FlyControl.SetKey(keyCode)
end

--- Cambia la tecla de fijación (lock) de objetivo durante el vuelo.
--- @param keyCode Enum.KeyCode
function M.SetLockKey(keyCode)
    if not isInitialized then
        if FlyControl.SetLockKey then
            FlyControl.SetLockKey(keyCode)
        end
        return
    end
    FlyControl.SetLockKey(keyCode)
end

--- Devuelve la tecla actual de activación del vuelo.
--- @return Enum.KeyCode
function M.GetFlyKey()
    return flyKey
end

--- Devuelve la tecla actual de fijación de objetivo.
--- @return Enum.KeyCode
function M.GetLockKey()
    return FlyControl.GetLockKey and FlyControl.GetLockKey() or Enum.KeyCode.X
end

--- Indica si el vuelo está actualmente activo.
--- @return boolean
function M.IsEnabled()
    return FlyControl.IsEnabled and FlyControl.IsEnabled() or false
end

--- Bypass temporal del vuelo (útil para otros quirks como passive bang u omniblock).
--- @param duration number - Duración en segundos.
--- @param reason string - Razón (para depuración).
function M.Bypass(duration, reason)
    if not isInitialized then return end
    if FlyControl.Bypass then
        FlyControl.Bypass(duration, reason)
    end
end

-- ============================================================
-- EXPORTACIÓN
-- ============================================================
return M
