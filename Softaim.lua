-- ───────────────────────────────────────────────────────────────────────────
-- SOFT AIM (módulo aislado)
-- ───────────────────────────────────────────────────────────────────────────
local M = {}

-- Constantes
local SOFTAIM = {
    KEYS = {Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Four},
    MAX_DIST = 80,
    ROTATION_SMOOTH = 0.8,
    LOCK_DURATION = 0.75,
    HOLD_RENEW_RATE = 0.05,
}

-- Estado interno
local _enabled = false
local _inputConn = nil
local _endConn = nil
local _heartbeatConn = nil
local _targetHRP = nil
local _active = false
local _lockTime = 0
local _highlight = nil
local _heldKeys = {}

-- Referencias a servicios
local _Keys, _lplr, _Players, _RunService, _UIS, _camera

-- ───────────────────────────────────────────────────────────────────────────
-- FUNCIONES AUXILIARES
-- ───────────────────────────────────────────────────────────────────────────

-- Verifica si Lock está activo y tiene un objetivo válido
local function isLockActiveAndTargeting()
    -- Lock.lua escribe estas variables en getgenv()
    local lockActive = getgenv().AFO_LOCK_ACTIVE
    local lockedTarget = getgenv().AFO_LOCKED_TARGET

    if lockActive and lockedTarget then
        -- Verificar que el objetivo sigue siendo válido
        local char = lockedTarget.Character
        if char and char:FindFirstChild("Humanoid") then
            local hum = char:FindFirstChild("Humanoid")
            if hum and hum.Health > 0 then
                return true
            end
        end
    end
    return false
end

-- Busca el objetivo más cercano al centro de la pantalla
local function findNearestTarget(myHRP)
    local mouse = _UIS:GetMouseLocation()
    local best, bestScore = nil, math.huge

    for _, player in ipairs(_Players:GetPlayers()) do
        if player ~= _lplr and player.Character then
            local tHRP = player.Character:FindFirstChild("HumanoidRootPart")
            local tHum = player.Character:FindFirstChild("Humanoid")
            if tHRP and tHum and tHum.Health > 0 then
                local dist3D = (tHRP.Position - myHRP.Position).Magnitude
                if dist3D <= SOFTAIM.MAX_DIST then
                    local screenPos, onScreen = _camera:WorldToViewportPoint(tHRP.Position)
                    local score = onScreen and Vector2.new(mouse.X - screenPos.X, mouse.Y - screenPos.Y).Magnitude or (10000 + dist3D)
                    if score < bestScore then
                        bestScore = score
                        best = tHRP
                    end
                end
            end
        end
    end
    return best
end

-- Verifica si alguna tecla de softaim está siendo presionada
local function anyKeyHeld()
    for _, kc in ipairs(SOFTAIM.KEYS) do
        if _heldKeys[kc] then return true end
    end
    return false
end

-- ───────────────────────────────────────────────────────────────────────────
-- HIGHLIGHT
-- ───────────────────────────────────────────────────────────────────────────
local function ensureHighlight()
    if not _highlight then
        _highlight = Instance.new("Highlight")
        _highlight.FillColor = Color3.fromRGB(255, 0, 0)
        _highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        _highlight.FillTransparency = 0.85
    end
end

local function clearHighlight()
    if _highlight then _highlight.Parent = nil end
end

-- ───────────────────────────────────────────────────────────────────────────
-- STOP
-- ───────────────────────────────────────────────────────────────────────────
function M.Stop()
    _enabled = false
    _active = false
    _lockTime = 0
    _targetHRP = nil
    _heldKeys = {}
    clearHighlight()

    if _inputConn then _inputConn:Disconnect(); _inputConn = nil end
    if _endConn then _endConn:Disconnect(); _endConn = nil end
    if _heartbeatConn then _heartbeatConn:Disconnect(); _heartbeatConn = nil end
end

-- ───────────────────────────────────────────────────────────────────────────
-- SETUP
-- ───────────────────────────────────────────────────────────────────────────
function M.Setup(Keys, lplr, Players, RunService, UserInputService, camera)
    -- Guardar referencias
    _Keys = Keys
    _lplr = lplr
    _Players = Players
    _RunService = RunService
    _UIS = UserInputService
    _camera = camera

    -- Limpiar cualquier estado previo
    M.Stop()
    _enabled = true

    -- Crear highlight
    ensureHighlight()

    -- ── Heartbeat: lógica principal de softaim ──
    _heartbeatConn = _RunService.Heartbeat:Connect(function(dt)
        if not _enabled then return end

        -- Si Lock está activo y tiene objetivo, desactivar softaim
        if isLockActiveAndTargeting() then
            _active = false
            _targetHRP = nil
            clearHighlight()
            return
        end

        -- Renovar el tiempo de bloqueo si se mantiene presionada una tecla
        if anyKeyHeld() then
            _active = true
            _lockTime = tick() + SOFTAIM.LOCK_DURATION
        end

        -- Si no está activo o expiró el tiempo, limpiar
        if not _active then
            clearHighlight()
            return
        end

        if tick() >= _lockTime then
            _active = false
            _targetHRP = nil
            clearHighlight()
            return
        end

        -- Obtener el personaje del jugador
        local char = _lplr.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        -- Buscar o mantener el objetivo
        if not _targetHRP or not _targetHRP.Parent then
            _targetHRP = findNearestTarget(hrp)
        end

        if not _targetHRP then
            clearHighlight()
            return
        end

        -- Aplicar rotación suave hacia el objetivo
        local tChar = _targetHRP.Parent
        local aimPart = (tChar and tChar:FindFirstChild("UpperTorso")) or _targetHRP
        local lookTarget = Vector3.new(aimPart.Position.X, hrp.Position.Y, aimPart.Position.Z)

        if (lookTarget - hrp.Position).Magnitude > 0.1 then
            local _, curYaw, _ = hrp.CFrame:ToEulerAnglesYXZ()
            local _, tarYaw, _ = CFrame.lookAt(hrp.Position, lookTarget):ToEulerAnglesYXZ()

            local diff = tarYaw - curYaw
            if diff > math.pi then diff = diff - 2 * math.pi end
            if diff < -math.pi then diff = diff + 2 * math.pi end

            local savedVel = hrp.AssemblyLinearVelocity
            hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, curYaw + diff * SOFTAIM.ROTATION_SMOOTH, 0)
            hrp.AssemblyLinearVelocity = savedVel
        end

        -- Mostrar highlight en el objetivo
        _highlight.Parent = _targetHRP.Parent
    end)

    -- ── Detectar presión de teclas (1,2,3,4) ──
    _inputConn = _UIS.InputBegan:Connect(function(input, gpe)
        if gpe or not _enabled then return end

        -- Si se presiona Q o teclas de emote, cancelar softaim
        if input.KeyCode == Enum.KeyCode.Q or
           input.KeyCode == _Keys.EmoteSteal or
           input.KeyCode == _Keys.EmoteExecute or
           input.KeyCode == _Keys.EmoteExpand then
            _active = false
            _heldKeys = {}
            _targetHRP = nil
            clearHighlight()
            return
        end

        -- Verificar si es una tecla de softaim (1-4)
        for _, kc in ipairs(SOFTAIM.KEYS) do
            if input.KeyCode == kc then
                _heldKeys[kc] = true
                _active = true
                _lockTime = tick() + SOFTAIM.LOCK_DURATION

                -- Buscar objetivo si no se tiene uno
                if not _targetHRP or not _targetHRP.Parent then
                    local myHRP = _lplr.Character and _lplr.Character:FindFirstChild("HumanoidRootPart")
                    if myHRP then
                        _targetHRP = findNearestTarget(myHRP)
                    end
                end
                break
            end
        end
    end)

    -- ── Detectar liberación de teclas ──
    _endConn = _UIS.InputEnded:Connect(function(input)
        for _, kc in ipairs(SOFTAIM.KEYS) do
            if input.KeyCode == kc then
                _heldKeys[kc] = false
                break
            end
        end
    end)
end

-- ───────────────────────────────────────────────────────────────────────────
-- API PARA EL HUB
-- ───────────────────────────────────────────────────────────────────────────
function M.SetEnabled(value)
    _enabled = value
    if not value then
        _active = false
        _targetHRP = nil
        clearHighlight()
    end
end

return M
