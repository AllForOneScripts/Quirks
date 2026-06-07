-- ──────────────────────────────────────────────
-- 8. FLY (comunicación con módulo externo)
-- ──────────────────────────────────────────────

local flyModule = nil
local flyKeyDetectorConn = nil

local function loadFlyModule()
    if flyModule then return flyModule end
    local url = "https://raw.githubusercontent.com/AllForOneScripts/Quirks/main/Fly.lua"
    local ok, result = pcall(function()
        return loadstring(game:HttpGet(url))()
    end)
    if ok and result then
        flyModule = result
        print("[HUB] Módulo Fly cargado correctamente")
    else
        warn("[HUB] Error al cargar Fly.lua")
    end
    return flyModule
end

local function flyInitialize()
    local fm = loadFlyModule()
    if fm then
        fm.Start(lplr, Keys.Fly)
        if fm.SetLockKey then fm.SetLockKey(Keys.FlyLock) end
        fm.Toggle(false)
        getgenv()._AFO_FLY_MODULE = fm
        pcall(function()
            if Options["FlyToggle"] and Options["FlyToggle"].SetValue then
                Options["FlyToggle"]:SetValue(false)
            end
        end)
        if _tpModule and _tpModule.SetFlyModule then
            pcall(function() _tpModule.SetFlyModule(fm) end)
        end
    end
end

Power:AddToggle("FlyToggle", {
    Title = T.lbl_fly,
    Description = T.lbl_fly_desc,
    Default = false,
    Callback = function(value)
        local fm = loadFlyModule()
        if fm then
            fm.Toggle(value)
        else
            flyInitialize()
            fm = loadFlyModule()
            if fm then fm.Toggle(value) end
        end
        notify(T.notif_fly_title, value and T.notif_on or T.notif_off)
    end
})

local function updateFlyToggleFromKey()
    local fm = loadFlyModule()
    if fm and fm.IsEnabled then
        local isFlying = fm.IsEnabled()
        pcall(function()
            if Options["FlyToggle"] and Options["FlyToggle"].SetValue then
                Options["FlyToggle"]:SetValue(isFlying)
            end
        end)
    end
end

local function connectFlyKeyDetector()
    if flyKeyDetectorConn then disconnectTracked(flyKeyDetectorConn) end
    flyKeyDetectorConn = trackConnection(UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == Keys.Fly then
            task.spawn(function()
                task.wait(0.1)
                updateFlyToggleFromKey()
            end)
        end
    end))
end

Power:AddKeybind("FlyKeybind", {
    Title = T.lbl_fly_key,
    Description = T.lbl_fly_key_desc,
    Default = "C",
    Callback = function(key)
        if type(key) == "string" then
            applyKey("Fly", key, Enum.KeyCode.C)
            local fm = loadFlyModule()
            if fm and fm.SetKey then fm.SetKey(Keys.Fly) end
            connectFlyKeyDetector()
        end
    end,
    ChangedCallback = function(key)
        applyKey("Fly", key, Enum.KeyCode.C)
        local fm = loadFlyModule()
        if fm and fm.SetKey then fm.SetKey(Keys.Fly) end
        connectFlyKeyDetector()
    end
})

Power:AddKeybind("FlyLockKeybind", {
    Title = T.lbl_fly_lock_key,
    Description = T.lbl_fly_lock_key_desc,
    Default = "X",
    Callback = function(key)
        if type(key) == "string" then
            applyKey("FlyLock", key, Enum.KeyCode.X)
            local fm = loadFlyModule()
            if fm and fm.SetLockKey then fm.SetLockKey(Keys.FlyLock) end
        end
    end,
    ChangedCallback = function(key)
        applyKey("FlyLock", key, Enum.KeyCode.X)
        local fm = loadFlyModule()
        if fm and fm.SetLockKey then fm.SetLockKey(Keys.FlyLock) end
    end
})

flyInitialize()
connectFlyKeyDetector()
