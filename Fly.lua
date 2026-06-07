print("version 1.66 - Iniciando carga")

local BASE_URL = "https://raw.githubusercontent.com/AllForOneScripts/Quirks/Fly/"
local MODULES = {
    FlyText   = BASE_URL .. "Text.lua",
    FlyAnim   = BASE_URL .. "Anim.lua",
    FlyLogic  = BASE_URL .. "Logic.lua",
    FlyControl= BASE_URL .. "Control.lua",
}

local function loadModuleFromURL(url, name)
    print("[Fly] Cargando " .. name .. " desde " .. url)
    local success, result = pcall(function()
        return loadstring(game:HttpGet(url))()
    end)
    if not success or not result then
        warn("[Fly] Error cargando módulo " .. name .. ": " .. tostring(success))
        return nil
    end
    print("[Fly] Módulo " .. name .. " cargado correctamente")
    return result
end

local FlyText   = loadModuleFromURL(MODULES.FlyText, "FlyText")
local FlyAnim   = loadModuleFromURL(MODULES.FlyAnim, "FlyAnim")
local FlyLogic  = loadModuleFromURL(MODULES.FlyLogic, "FlyLogic")
local FlyControl = loadModuleFromURL(MODULES.FlyControl, "FlyControl")

if not FlyText or not FlyAnim or not FlyLogic or not FlyControl then
    error("[Fly] No se pudieron cargar todos los submódulos. Revisa las URLs y la existencia de los archivos en la rama Fly.")
end

print("[Fly] Todos los submódulos cargados. Inicializando...")

local isInitialized = false
local currentFlyKey = Enum.KeyCode.C
local currentLockKey = Enum.KeyCode.X

local M = {}

function M.Start(lplrRef, flyKeyRef)
    print("[Fly] M.Start llamado con lplr:", lplrRef, "flyKey:", flyKeyRef)
    if not lplrRef then
        warn("[Fly] No se proporcionó jugador local.")
        return
    end
    if flyKeyRef then currentFlyKey = flyKeyRef end
    if FlyText.Reload then FlyText.Reload() end
    print("[Fly] Llamando a FlyControl.Start...")
    FlyControl.Start(lplrRef, currentFlyKey)
    if FlyControl.SetLockKey then FlyControl.SetLockKey(currentLockKey) end
    isInitialized = true
    print("[Fly] Inicialización completa.")
end

function M.Stop()
    if not isInitialized then return end
    FlyControl.Stop()
    isInitialized = false
end

function M.Toggle(state)
    if not isInitialized then warn("[Fly] No iniciado") return end
    FlyControl.Toggle(state)
end

function M.SetKey(keyCode)
    currentFlyKey = keyCode
    if isInitialized and FlyControl.SetKey then FlyControl.SetKey(keyCode) end
end

function M.SetLockKey(keyCode)
    currentLockKey = keyCode
    if isInitialized and FlyControl.SetLockKey then FlyControl.SetLockKey(keyCode) end
end

function M.GetFlyKey() return currentFlyKey end
function M.GetLockKey() return currentLockKey end
function M.IsEnabled() return isInitialized and FlyControl.IsEnabled and FlyControl.IsEnabled() or false end
function M.Bypass(duration, reason) if isInitialized and FlyControl.Bypass then FlyControl.Bypass(duration, reason) end end

print("[Fly] Módulo listo, esperando M.Start desde el hub")
return M
