local M = {}

local _screenGui = nil
local _miscInputBegin, _miscInputEnd, _miscRenderConn, _miscCharConn = nil, nil, nil, nil
local _stealerTrack, _stolenTrack, _animator, _animatorConn = nil, nil, nil, nil
local _stoledAnimId, _stolenAnimOwner, _stolenAnimSource = nil, nil, nil
local _isStealerActive, _isStolenPlaying = false, false
local _currentAimedPlayer, _lastCirclePlayer = nil, nil
local _panelHideTimer, _warningTimer = nil, nil
local _yHeld, _uHeld, _tHeld = false, false, false
local _expandConsumed, _tyConsumed, _isInputOpen = false, false, false
local _circleIndicatorBB, _circleIndicatorConn, _circleAlphaThread, _pulseThread = nil, nil, nil, nil
local _playerRenderConn, _playerInputChanged, _playerInputEnded = nil, nil, nil
local _ringFolder = nil
local _running = false

local DEFAULT_KEYS = {
    EmoteSteal   = Enum.KeyCode.T,
    EmoteExecute = Enum.KeyCode.Y,
    EmoteExpand  = Enum.KeyCode.U,
}
local FX_FOLDER_NAME = "AFO_EmoteFx"
local HUD_NAME       = "StealerHUD"

-- Registro global: permite que una ejecucion nueva del script apague la anterior
local function getEnv()
    if type(getgenv) == "function" then
        local ok, env = pcall(getgenv)
        if ok and type(env) == "table" then return env end
    end
    return nil
end
local function myCleanup() M.Stop(true) end


-- Dependencias inyectadas por Start()
local _Keys, _lplr, _CoreGui, _RunService, _TweenService, _camera, _Players, _UserInputService

-- ==========================================================
-- ALMACEN DEL HISTORIAL
--  * Fuente de verdad: getgenv().AFO_EMOTE_HISTORY (sobrevive a respawn, Stop y Start)
--  * Copia en disco:   AllForOne/emote_history.json (si el ejecutor tiene writefile)
--  * Espejo visible:   StringValue "AFO_EmoteHistory" dentro del Character (JSON)
--    El Character se destruye al morir, por eso NO es la fuente de verdad: se regenera en cada respawn.
-- ==========================================================
local HISTORY_FILE = "AllForOne/emote_history.json"
local HISTORY_MAX  = 25
local HISTORY_VALUE_NAME = "AFO_EmoteHistory"

local function jsonEncode(v)
    local ok, r = pcall(function() return game:GetService("HttpService"):JSONEncode(v) end)
    return ok and r or nil
end
local function jsonDecode(v)
    local ok, r = pcall(function() return game:GetService("HttpService"):JSONDecode(v) end)
    return ok and r or nil
end

local function sanitizeHistory(raw)
    local out = {}
    if type(raw) == "table" then
        for _, e in ipairs(raw) do
            if type(e) == "table" and type(e.animId) == "string" and e.animId:match("%d+") then
                table.insert(out, {
                    animId        = e.animId,
                    ownerName     = tostring(e.ownerName or "?"),
                    displayName   = tostring(e.displayName or e.ownerName or "?"),
                    animationName = tostring(e.animationName or ""),
                    duration      = tonumber(e.duration) or 0,
                    time          = tonumber(e.time) or 0,
                })
            end
        end
    end
    while #out > HISTORY_MAX do table.remove(out, 1) end
    return out
end

local function getHistoryStore()
    local env = getEnv()
    if env and type(env.AFO_EMOTE_HISTORY) == "table" then return env.AFO_EMOTE_HISTORY end
    local list = {}
    pcall(function()
        if type(isfile) == "function" and type(readfile) == "function" and isfile(HISTORY_FILE) then
            list = sanitizeHistory(jsonDecode(readfile(HISTORY_FILE)))
        end
    end)
    if env then env.AFO_EMOTE_HISTORY = list end
    return list
end

local _historySaveToken = 0
local function saveHistoryFile(list)
    if type(writefile) ~= "function" then return end
    _historySaveToken = _historySaveToken + 1
    local mine = _historySaveToken
    task.delay(1, function() -- agrupa varios cambios seguidos en una sola escritura
        if mine ~= _historySaveToken then return end
        pcall(function()
            if type(makefolder) == "function" and type(isfolder) == "function" and not isfolder("AllForOne") then
                makefolder("AllForOne")
            end
            local j = jsonEncode(list)
            if j then writefile(HISTORY_FILE, j) end
        end)
    end)
end

local function mirrorHistoryToCharacter(list)
    local char = _lplr and _lplr.Character
    if not char then return end
    local v = char:FindFirstChild(HISTORY_VALUE_NAME)
    if not v then
        v = Instance.new("StringValue")
        v.Name = HISTORY_VALUE_NAME
        v.Parent = char
    end
    local j = jsonEncode(list) or "[]"
    if v.Value ~= j then v.Value = j end
end

function M.GetHistory()
    local copy = {}
    for i, e in ipairs(getHistoryStore()) do copy[i] = table.clone(e) end
    return copy
end

function M.ClearHistory()
    local list = getHistoryStore()
    for i = #list, 1, -1 do table.remove(list, i) end
    saveHistoryFile(list)
    mirrorHistoryToCharacter(list)
end

function M.Start(Keys, lplr, CoreGui, RunService, TweenService, camera)
    -- Apaga cualquier instancia previa (de este modulo o de una ejecucion anterior del script)
    local env = getEnv()
    if env and type(env.AFO_EMOTE_CLEANUP) == "function" and env.AFO_EMOTE_CLEANUP ~= myCleanup then
        pcall(env.AFO_EMOTE_CLEANUP)
    end
    M.Stop(true)

    -- Dependencias con valores por defecto (si el loader no las pasa, el script sigue funcionando)
    local keysSrc = type(Keys) == "table" and Keys or {}
    -- Se lee en vivo de la tabla del loader, con T / Y / U como respaldo
    _Keys = setmetatable({}, { __index = function(_, k)
        local v = keysSrc[k]
        if v ~= nil then return v end
        return DEFAULT_KEYS[k]
    end })
    _Players          = game:GetService("Players")
    _UserInputService = game:GetService("UserInputService")
    _lplr             = lplr or _Players.LocalPlayer
    _CoreGui          = CoreGui or game:GetService("CoreGui")
    _RunService       = RunService or game:GetService("RunService")
    _TweenService     = TweenService or game:GetService("TweenService")
    _camera           = nil -- la camara se lee siempre de workspace.CurrentCamera
    if not _lplr then warn("[Emote] No se encontro LocalPlayer"); return end

    _running = true
    if env then env.AFO_EMOTE_CLEANUP = myCleanup; env.AFO_EMOTE_API = M end

    -- Alias locales para que el código interno funcione sin cambios
    local emoteStealKey   = _Keys.EmoteSteal
    local emoteExecuteKey = _Keys.EmoteExecute
    local emoteExpandKey  = _Keys.EmoteExpand

    -- Elimina HUDs huerfanos de ejecuciones anteriores
    for _, host in ipairs({ _CoreGui, _Players.LocalPlayer and _Players.LocalPlayer:FindFirstChildOfClass("PlayerGui") }) do
        local old = host and host:FindFirstChild(HUD_NAME)
        if old then pcall(function() old:Destroy() end) end
    end
    if type(gethui) == "function" then
        local okH, h = pcall(gethui)
        local old = okH and h and h:FindFirstChild(HUD_NAME)
        if old then pcall(function() old:Destroy() end) end
    end

    local _lang = "ES"
    pcall(function()
        local data = readfile("AllForOne/lang.txt")
        if data == "EN" or data == "ES" then _lang = data end
    end)
    local _isEN = (_lang == "EN")
    local function L(es, en) return _isEN and en or es end
    local function kn(k) return k and k.Name or "?" end

    local AFO_PURPLE     = Color3.fromRGB(110, 30, 180)
    local AFO_PURPLE_DIM = Color3.fromRGB(55, 8, 95)
    local AFO_BLACK      = Color3.fromRGB(8, 5, 14)
    local AFO_ACCENT     = Color3.fromRGB(160, 60, 255)
    local AFO_TEXT       = Color3.fromRGB(220, 190, 255)
    local AFO_WARN       = Color3.fromRGB(255, 80, 80)
    local AFO_GREEN      = Color3.fromRGB(80, 255, 150)

    -- ==========================================
    -- UTILIDADES DE ANIMACION E HISTORIAL
    -- ==========================================
    local MarketplaceService = game:GetService("MarketplaceService")
    local function shortId(value)
        return (value and value:match("%d+")) or value or "?"
    end
    local function normalizeAnimationId(value)
        local digits = tostring(value or ""):match("%d+")
        return digits and ("rbxassetid://" .. digits) or nil
    end
    local function formatDuration(seconds)
        seconds = tonumber(seconds) or 0
        if seconds <= 0 then return L("Duración desconocida", "Unknown duration") end
        return string.format(L("Duración · %.2fs", "Duration · %.2fs"), seconds)
    end

    local BASE_HEIGHT    = 62
    local PLAYING_HEIGHT = 70
    local PANEL_POS      = UDim2.new(0.5, -144, 1, -188)
    local SHADOW_POS     = UDim2.new(0.5, -148, 1, -191)
    local MAX_STEAL_DIST = 120
    local MAX_HISTORY    = HISTORY_MAX
    local STEALER_ANIM_ID = "rbxassetid://84027724325738"

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = HUD_NAME
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    do
        local container = _CoreGui
        if type(gethui) == "function" then
            local okH, h = pcall(gethui)
            if okH and typeof(h) == "Instance" then container = h end
        end
        local okP = pcall(function() screenGui.Parent = container end)
        if not okP or not screenGui.Parent then screenGui.Parent = _CoreGui end
    end
    _screenGui = screenGui

    local shadow = Instance.new("Frame")
    shadow.Size = UDim2.new(0, 296, 0, BASE_HEIGHT + 8)
    shadow.Position = SHADOW_POS
    shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    shadow.BackgroundTransparency = 1
    shadow.BorderSizePixel = 0
    shadow.ZIndex = 1
    shadow.Visible = false
    shadow.Parent = screenGui
    do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,15); c.Parent = shadow end

    local panel = Instance.new("Frame")
    panel.Size = UDim2.new(0, 288, 0, BASE_HEIGHT)
    panel.Position = PANEL_POS
    panel.BackgroundColor3 = AFO_BLACK
    panel.BackgroundTransparency = 1
    panel.BorderSizePixel = 0
    panel.Visible = false
    panel.ZIndex = 2
    panel.ClipsDescendants = true
    panel.Parent = screenGui
    do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,13); c.Parent = panel end

    local grad = Instance.new("UIGradient")
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, AFO_BLACK),
        ColorSequenceKeypoint.new(0.55, AFO_BLACK),
        ColorSequenceKeypoint.new(1, AFO_PURPLE_DIM),
    })
    grad.Rotation = 85
    grad.Parent = panel

    local stroke = Instance.new("UIStroke")
    stroke.Color = AFO_PURPLE
    stroke.Thickness = 2
    stroke.Transparency = 1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = panel

    local baseZone = Instance.new("Frame")
    baseZone.AnchorPoint = Vector2.new(0, 1)
    baseZone.Size = UDim2.new(1, 0, 0, BASE_HEIGHT)
    baseZone.Position = UDim2.new(0, 0, 1, 0)
    baseZone.BackgroundTransparency = 1
    baseZone.BorderSizePixel = 0
    baseZone.ZIndex = 3
    baseZone.Parent = panel

    local infoLabel = Instance.new("TextLabel")
    infoLabel.Size = UDim2.new(1, -18, 0, 22)
    infoLabel.Position = UDim2.new(0, 9, 0, 5)
    infoLabel.BackgroundTransparency = 1
    infoLabel.TextColor3 = AFO_TEXT
    infoLabel.TextTransparency = 1
    infoLabel.TextScaled = true
    infoLabel.Font = Enum.Font.GothamSemibold
    infoLabel.Text = ""
    infoLabel.TextXAlignment = Enum.TextXAlignment.Left
    infoLabel.ZIndex = 4
    infoLabel.Parent = baseZone

    local warningLabel = Instance.new("TextLabel")
    warningLabel.Size = UDim2.new(1, -18, 1, 0)
    warningLabel.Position = UDim2.new(0, 9, 0, 0)
    warningLabel.BackgroundTransparency = 1
    warningLabel.TextColor3 = AFO_WARN
    warningLabel.TextTransparency = 1
    warningLabel.TextScaled = true
    warningLabel.Font = Enum.Font.GothamBold
    warningLabel.Text = ""
    warningLabel.TextXAlignment = Enum.TextXAlignment.Center
    warningLabel.TextYAlignment = Enum.TextYAlignment.Center
    warningLabel.ZIndex = 5
    warningLabel.Visible = false
    warningLabel.Parent = baseZone

    local idButton = Instance.new("TextButton")
    idButton.Size = UDim2.new(1, -18, 0, 20)
    idButton.Position = UDim2.new(0, 9, 0, 28)
    idButton.BackgroundColor3 = AFO_PURPLE_DIM
    idButton.BackgroundTransparency = 1
    idButton.TextColor3 = AFO_ACCENT
    idButton.TextTransparency = 1
    idButton.Text = ""
    idButton.Font = Enum.Font.Code
    idButton.TextScaled = true
    idButton.BorderSizePixel = 0
    idButton.ZIndex = 4
    idButton.Visible = false
    idButton.Parent = baseZone
    do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,5); c.Parent = idButton end

    local execBtn = Instance.new("TextButton")
    execBtn.Size = UDim2.new(1, -18, 0, 26)
    execBtn.Position = UDim2.new(0, 9, 0, 28)
    execBtn.BackgroundColor3 = AFO_PURPLE_DIM
    execBtn.BackgroundTransparency = 1
    execBtn.TextColor3 = AFO_TEXT
    execBtn.TextTransparency = 1
    execBtn.Text = L("▶ Ejecutar animación robada ["..kn(emoteExecuteKey).."]", "▶ Play stolen animation ["..kn(emoteExecuteKey).."]")
    execBtn.Font = Enum.Font.GothamBold
    execBtn.TextScaled = true
    execBtn.BorderSizePixel = 0
    execBtn.ZIndex = 4
    execBtn.Parent = baseZone
    do
        local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,7); c.Parent = execBtn
        local g2 = Instance.new("UIGradient")
        g2.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, AFO_PURPLE_DIM),
            ColorSequenceKeypoint.new(1, AFO_PURPLE),
        })
        g2.Rotation = 0
        g2.Parent = execBtn
    end

    local expandZone = Instance.new("Frame")
    expandZone.AnchorPoint = Vector2.new(0, 1)
    expandZone.Size = UDim2.new(1, 0, 0, 0)
    expandZone.Position = UDim2.new(0, 0, 1, -BASE_HEIGHT)
    expandZone.BackgroundTransparency = 1
    expandZone.BorderSizePixel = 0
    expandZone.ZIndex = 3
    expandZone.ClipsDescendants = true
    expandZone.Visible = false
    expandZone.Parent = panel

    local histTitle = Instance.new("TextLabel")
    histTitle.Size = UDim2.new(1, -52, 0, 22)
    histTitle.Position = UDim2.new(0, 9, 0, 6)
    histTitle.BackgroundTransparency = 1
    histTitle.TextColor3 = AFO_ACCENT
    histTitle.Font = Enum.Font.GothamBold
    histTitle.TextScaled = true
    histTitle.TextXAlignment = Enum.TextXAlignment.Left
    histTitle.Text = L("📎 Animaciones robadas ["..kn(emoteExecuteKey).."+"..kn(emoteExpandKey).." para cerrar]", "📎 Stolen animations ["..kn(emoteExecuteKey).."+"..kn(emoteExpandKey).." to close]")
    histTitle.ZIndex = 5
    histTitle.Parent = expandZone

    local histSep = Instance.new("Frame")
    histSep.Size = UDim2.new(1, -18, 0, 1)
    histSep.Position = UDim2.new(0, 9, 0, 30)
    histSep.BackgroundColor3 = AFO_ACCENT
    histSep.BackgroundTransparency = 0.5
    histSep.BorderSizePixel = 0
    histSep.ZIndex = 5
    histSep.Parent = expandZone

    local historyFrame = Instance.new("ScrollingFrame")
    historyFrame.Size = UDim2.new(1, -18, 1, -36)
    historyFrame.Position = UDim2.new(0, 9, 0, 34)
    historyFrame.BackgroundTransparency = 1
    historyFrame.BorderSizePixel = 0
    historyFrame.ScrollBarThickness = 6
    historyFrame.ScrollBarImageColor3 = AFO_ACCENT
    historyFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    historyFrame.ZIndex = 4
    historyFrame.ClipsDescendants = true
    historyFrame.Parent = expandZone

    local historyLayout = Instance.new("UIListLayout")
    historyLayout.SortOrder = Enum.SortOrder.LayoutOrder
    historyLayout.Padding = UDim.new(0, 4)
    historyLayout.Parent = historyFrame

    -- ==========================================
    -- REPRODUCTOR UNICO (U / HISTORIAL)
    -- ==========================================
    -- Un solo panel reutilizable evita que se acumulen ventanas al reproducir
    -- desde el historial. Permanece abierto aunque se cierre el historial.
    local playerPanel = Instance.new("Frame")
    playerPanel.Name = "AnimationPlayer"
    playerPanel.AnchorPoint = Vector2.new(0, 1)
    playerPanel.Size = UDim2.new(0, 348, 0, 218)
    playerPanel.Position = UDim2.new(0.5, 152, 1, -126)
    playerPanel.BackgroundColor3 = AFO_BLACK
    playerPanel.BackgroundTransparency = 0.04
    playerPanel.BorderSizePixel = 0
    playerPanel.Visible = false
    playerPanel.ZIndex = 30
    playerPanel.Parent = screenGui
    do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 12); c.Parent = playerPanel end
    do local s = Instance.new("UIStroke"); s.Color = AFO_ACCENT; s.Thickness = 2; s.Parent = playerPanel end
    do
        local g = Instance.new("UIGradient")
        g.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, AFO_BLACK), ColorSequenceKeypoint.new(1, AFO_PURPLE_DIM)})
        g.Rotation = 75; g.Parent = playerPanel
    end

    local playerHeader = Instance.new("TextLabel")
    playerHeader.Size = UDim2.new(1, -54, 0, 26)
    playerHeader.Position = UDim2.new(0, 10, 0, 7)
    playerHeader.BackgroundTransparency = 1
    playerHeader.Text = L("REPRODUCTOR DE ANIMACIONES", "ANIMATION PLAYER")
    playerHeader.TextColor3 = AFO_ACCENT
    playerHeader.Font = Enum.Font.GothamBold
    playerHeader.TextSize = 13
    playerHeader.TextXAlignment = Enum.TextXAlignment.Left
    playerHeader.ZIndex = 31
    playerHeader.Parent = playerPanel

    local playerClose = Instance.new("TextButton")
    playerClose.Size = UDim2.new(0, 26, 0, 26)
    playerClose.Position = UDim2.new(1, -34, 0, 7)
    playerClose.BackgroundColor3 = AFO_WARN
    playerClose.Text = "X"
    playerClose.TextColor3 = Color3.new(1, 1, 1)
    playerClose.Font = Enum.Font.GothamBold
    playerClose.TextSize = 13
    playerClose.BorderSizePixel = 0
    playerClose.ZIndex = 32
    playerClose.Parent = playerPanel
    do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 6); c.Parent = playerClose end

    local playerInput = Instance.new("TextBox")
    playerInput.Size = UDim2.new(1, -20, 0, 28)
    playerInput.Position = UDim2.new(0, 10, 0, 39)
    playerInput.BackgroundColor3 = AFO_PURPLE_DIM
    playerInput.BackgroundTransparency = 0.15
    playerInput.PlaceholderText = L("ID de animación (números o rbxassetid://)", "Animation ID (numbers or rbxassetid://)")
    playerInput.PlaceholderColor3 = Color3.fromRGB(155, 125, 190)
    playerInput.Text = ""
    playerInput.TextColor3 = AFO_TEXT
    playerInput.Font = Enum.Font.Code
    playerInput.TextSize = 12
    playerInput.ClearTextOnFocus = false
    playerInput.BorderSizePixel = 0
    playerInput.ZIndex = 31
    playerInput.Parent = playerPanel
    do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 6); c.Parent = playerInput end

    local playerName = Instance.new("TextLabel")
    playerName.Size = UDim2.new(1, -20, 0, 17)
    playerName.Position = UDim2.new(0, 10, 0, 72)
    playerName.BackgroundTransparency = 1
    playerName.Text = L("Carga una animación con U", "Load an animation with U")
    playerName.TextColor3 = AFO_TEXT
    playerName.Font = Enum.Font.GothamSemibold
    playerName.TextSize = 11
    playerName.TextXAlignment = Enum.TextXAlignment.Left
    playerName.TextTruncate = Enum.TextTruncate.AtEnd
    playerName.ZIndex = 31
    playerName.Parent = playerPanel

    local timelineBar = Instance.new("TextButton")
    timelineBar.Size = UDim2.new(1, -20, 0, 12)
    timelineBar.Position = UDim2.new(0, 10, 0, 98)
    timelineBar.BackgroundColor3 = Color3.fromRGB(28, 18, 45)
    timelineBar.Text = ""
    timelineBar.AutoButtonColor = false
    timelineBar.BorderSizePixel = 0
    timelineBar.ZIndex = 31
    timelineBar.Parent = playerPanel
    do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1, 0); c.Parent = timelineBar end
    local timelineFill = Instance.new("Frame")
    timelineFill.Size = UDim2.new(0, 0, 1, 0)
    timelineFill.BackgroundColor3 = AFO_ACCENT
    timelineFill.BorderSizePixel = 0
    timelineFill.ZIndex = 32
    timelineFill.Parent = timelineBar
    do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1, 0); c.Parent = timelineFill end

    local timeLabel = Instance.new("TextLabel")
    timeLabel.Size = UDim2.new(1, -20, 0, 16)
    timeLabel.Position = UDim2.new(0, 10, 0, 114)
    timeLabel.BackgroundTransparency = 1
    timeLabel.Text = "0.00s / 0.00s · 0%"
    timeLabel.TextColor3 = AFO_TEXT
    timeLabel.Font = Enum.Font.Gotham
    timeLabel.TextSize = 10
    timeLabel.TextXAlignment = Enum.TextXAlignment.Center
    timeLabel.ZIndex = 31
    timeLabel.Parent = playerPanel

    local function makePlayerButton(text, position, size, color)
        local button = Instance.new("TextButton")
        button.Size = size; button.Position = position
        button.BackgroundColor3 = color or Color3.fromRGB(28, 18, 45)
        button.TextColor3 = AFO_TEXT; button.Text = text
        button.Font = Enum.Font.GothamBold; button.TextSize = 11
        button.BorderSizePixel = 0; button.ZIndex = 31; button.Parent = playerPanel
        local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 6); c.Parent = button
        return button
    end
    local playButton = makePlayerButton(L("▶ Cargar", "▶ Load"), UDim2.new(0, 10, 0, 140), UDim2.new(0.31, -4, 0, 28), AFO_PURPLE)
    local pauseButton = makePlayerButton(L("❚❚ Pausa", "❚❚ Pause"), UDim2.new(0.31, 4, 0, 140), UDim2.new(0.31, -4, 0, 28))
    local loopButton = makePlayerButton(L("↻ Loop", "↻ Loop"), UDim2.new(0.62, 4, 0, 140), UDim2.new(0.38, -14, 0, 28))
    local stopButton = makePlayerButton(L("■ Detener todo", "■ Stop all"), UDim2.new(0, 10, 0, 176), UDim2.new(1, -20, 0, 28), Color3.fromRGB(75, 22, 36))

    local inputPopup = Instance.new("Frame")
    inputPopup.AnchorPoint = Vector2.new(0.5, 0.5)
    inputPopup.Size = UDim2.new(0, 340, 0, 108)
    inputPopup.Position = UDim2.new(0.5, 0, 0.5, 0)
    inputPopup.BackgroundColor3 = AFO_BLACK
    inputPopup.BackgroundTransparency = 0.06
    inputPopup.BorderSizePixel = 0
    inputPopup.Visible = false
    inputPopup.ZIndex = 20
    inputPopup.Parent = screenGui
    do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,13); c.Parent = inputPopup end

    local inputStroke = Instance.new("UIStroke")
    inputStroke.Color = AFO_ACCENT
    inputStroke.Thickness = 2
    inputStroke.Transparency = 0
    inputStroke.Parent = inputPopup

    local inputTitle = Instance.new("TextLabel")
    inputTitle.Size = UDim2.new(1, -16, 0, 24)
    inputTitle.Position = UDim2.new(0, 8, 0, 6)
    inputTitle.BackgroundTransparency = 1
    inputTitle.TextColor3 = AFO_ACCENT
    inputTitle.Font = Enum.Font.GothamBold
    inputTitle.TextScaled = true
    inputTitle.TextXAlignment = Enum.TextXAlignment.Left
    inputTitle.Text = L("🔑 Cargar ID [Enter/clic confirmar · "..kn(emoteStealKey).."+"..kn(emoteExecuteKey).." cerrar]", "🔑 Load ID [Enter/click confirm · "..kn(emoteStealKey).."+"..kn(emoteExecuteKey).." close]")
    inputTitle.ZIndex = 21
    inputTitle.Parent = inputPopup

    local inputBox = Instance.new("TextBox")
    inputBox.Size = UDim2.new(1, -16, 0, 30)
    inputBox.Position = UDim2.new(0, 8, 0, 34)
    inputBox.BackgroundColor3 = AFO_PURPLE_DIM
    inputBox.BackgroundTransparency = 0.3
    inputBox.TextColor3 = AFO_TEXT
    inputBox.PlaceholderText = L("rbxassetid://... o solo los números", "rbxassetid://... or just the numbers")
    inputBox.PlaceholderColor3 = Color3.fromRGB(140, 110, 180)
    inputBox.Text = ""
    inputBox.Font = Enum.Font.Code
    inputBox.TextScaled = true
    inputBox.ClearTextOnFocus = false
    inputBox.BorderSizePixel = 0
    inputBox.ZIndex = 21
    inputBox.Parent = inputPopup
    do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,7); c.Parent = inputBox end
    do
        local s = Instance.new("UIStroke")
        s.Color = AFO_ACCENT; s.Thickness = 1.5; s.Transparency = 0.4; s.Parent = inputBox
    end

    local inputConfirmBtn = Instance.new("TextButton")
    inputConfirmBtn.Size = UDim2.new(1, -16, 0, 26)
    inputConfirmBtn.Position = UDim2.new(0, 8, 0, 70)
    inputConfirmBtn.BackgroundColor3 = AFO_PURPLE
    inputConfirmBtn.BackgroundTransparency = 0.15
    inputConfirmBtn.TextColor3 = AFO_TEXT
    inputConfirmBtn.Font = Enum.Font.GothamBold
    inputConfirmBtn.TextScaled = true
    inputConfirmBtn.Text = L("✔ Confirmar", "✔ Confirm")
    inputConfirmBtn.BorderSizePixel = 0
    inputConfirmBtn.ZIndex = 21
    inputConfirmBtn.Parent = inputPopup
    do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,7); c.Parent = inputConfirmBtn end

    local TWEEN_IN     = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local TWEEN_OUT    = TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    local EXPAND_TWEEN = TweenInfo.new(0.32, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

    local stolenHistory  = getHistoryStore() -- misma tabla que getgenv().AFO_EMOTE_HISTORY
    local stealerTrack   = nil
    local stolenTrack    = nil
    local animator       = nil
    local animatorConn   = nil
    local stoledAnimId   = nil
    local stolenAnimOwner  = nil
    local stolenAnimSource = nil
    local isStealerActive  = false
    local isStolenPlaying  = false
    local currentAimedPlayer = nil
    local lastCirclePlayer   = nil
    local panelHideTimer = nil
    local warningTimer   = nil
    local isExpanded     = false
    local isInputOpen = false
    local lastStealPoll = 0
    local circleIndicatorBB = nil; local circleIndicatorConn = nil
    local circleAlphaThread = nil; local pulseThread = nil
    local playerTrack, playerRenderConn = nil, nil
    local playerPaused, playerLooped, playerScrubbing = false, false, false
    local playAnimationInPlayer

    -- Guarda referencias para Stop()
    _stealerTrack  = nil; _stolenTrack = nil; _animator = nil; _animatorConn = nil

    local function getPanelBaseH()
        return isStolenPlaying and PLAYING_HEIGHT or BASE_HEIGHT
    end

    local function applyPanelSize(h, animated)
        local ps = UDim2.new(0, 288, 0, h)
        local ss = UDim2.new(0, 296, 0, h + 8)
        if animated then
            _TweenService:Create(panel, EXPAND_TWEEN, {Size = ps}):Play()
            _TweenService:Create(shadow, EXPAND_TWEEN, {Size = ss}):Play()
        else
            panel.Size = ps; shadow.Size = ss
        end
    end

    local function clearBaseZone()
        infoLabel.TextTransparency = 1
        warningLabel.TextTransparency = 1
        warningLabel.Visible = false
        execBtn.TextTransparency = 1
        execBtn.BackgroundTransparency = 1
        execBtn.Visible = false
        idButton.TextTransparency = 1
        idButton.BackgroundTransparency = 1
        idButton.Visible = false
    end

    local function cancelHideTimer()
        if panelHideTimer then task.cancel(panelHideTimer); panelHideTimer = nil end
    end

    local function stopPulse()
        if pulseThread then task.cancel(pulseThread); pulseThread = nil end
    end

    local function resetBorder()
        stopPulse()
        _TweenService:Create(stroke, TweenInfo.new(0.3), {Color = AFO_PURPLE, Thickness = 2, Transparency = 0}):Play()
    end

    local function startPulse()
        stopPulse()
        pulseThread = task.spawn(function()
            while true do
                _TweenService:Create(stroke, TweenInfo.new(0.55, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Thickness = 3.5, Transparency = 0, Color = AFO_ACCENT}):Play()
                task.wait(0.55)
                _TweenService:Create(stroke, TweenInfo.new(0.55, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Thickness = 1.2, Transparency = 0.35, Color = AFO_PURPLE}):Play()
                task.wait(0.55)
            end
        end)
        _pulseThread = pulseThread
    end

    local ringStrokeRef = nil

    local function clearCircleIndicator()
        if circleAlphaThread then pcall(task.cancel, circleAlphaThread); circleAlphaThread = nil end
        if circleIndicatorConn then circleIndicatorConn:Disconnect(); circleIndicatorConn = nil end
        if circleIndicatorBB then pcall(function() circleIndicatorBB:Destroy() end) end
        circleIndicatorBB = nil
        ringStrokeRef = nil
        -- mantener sincronizadas las referencias del modulo (Stop() las usa)
        _circleAlphaThread, _circleIndicatorConn, _circleIndicatorBB = nil, nil, nil
    end

    local function getRingFolder()
        if _ringFolder and _ringFolder.Parent then return _ringFolder end
        local f = Instance.new("Folder")
        f.Name = FX_FOLDER_NAME
        f.Parent = workspace
        _ringFolder = f
        return f
    end

    -- Color del anillo: morado = hay animacion que robar, rojo = el objetivo no tiene ninguna
    local function setRingState(hasAnim)
        if ringStrokeRef then ringStrokeRef.Color = hasAnim and AFO_ACCENT or AFO_WARN end
    end

    local function showCircleIndicator(player)
        if circleIndicatorBB and circleIndicatorBB.Parent and circleIndicatorBB.Adornee then
            local char = player and player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp and circleIndicatorBB.Adornee == hrp then return end
        end
        clearCircleIndicator()
        if not player or not player.Character then return end
        local root = player.Character:FindFirstChild("HumanoidRootPart")
        if not root then return end

        local bb = Instance.new("BillboardGui")
        bb.Name = "AFO_EmoteRing"
        bb.Adornee = root
        -- Tamaño en STUDS (escala): el anillo rodea al personaje y se achica con la distancia
        bb.Size = UDim2.new(6.5, 0, 6.5, 0)
        -- Siempre visible: antes, al estar en el centro del cuerpo, el propio personaje lo tapaba
        bb.AlwaysOnTop = true
        bb.MaxDistance = MAX_STEAL_DIST + 30
        bb.ResetOnSpawn = false
        bb.LightInfluence = 0
        bb.Parent = getRingFolder()

        local ring = Instance.new("Frame")
        ring.Name = "Ring"
        ring.Size = UDim2.new(1, 0, 1, 0)
        ring.BackgroundTransparency = 1
        ring.BorderSizePixel = 0
        ring.Parent = bb
        do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0.5, 0); c.Parent = ring end
        local ringStroke = Instance.new("UIStroke")
        ringStroke.Color = AFO_ACCENT
        ringStroke.Thickness = 3
        ringStroke.Transparency = 0.1
        ringStroke.Parent = ring

        -- aro interior tenue para dar profundidad
        local inner = Instance.new("Frame")
        inner.Name = "Inner"
        inner.AnchorPoint = Vector2.new(0.5, 0.5)
        inner.Position = UDim2.new(0.5, 0, 0.5, 0)
        inner.Size = UDim2.new(0.82, 0, 0.82, 0)
        inner.BackgroundTransparency = 1
        inner.BorderSizePixel = 0
        inner.Parent = bb
        do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0.5, 0); c.Parent = inner end
        local innerStroke = Instance.new("UIStroke")
        innerStroke.Color = AFO_TEXT
        innerStroke.Thickness = 1
        innerStroke.Transparency = 0.6
        innerStroke.Parent = inner

        circleIndicatorBB = bb
        ringStrokeRef = ringStroke
        setRingState(stoledAnimId ~= nil and stolenAnimOwner == player)

        circleAlphaThread = task.spawn(function()
            while bb and bb.Parent do
                _TweenService:Create(ringStroke, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Thickness = 5, Transparency = 0}):Play()
                task.wait(0.6)
                if not bb.Parent then break end
                _TweenService:Create(ringStroke, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Thickness = 2, Transparency = 0.45}):Play()
                task.wait(0.6)
            end
        end)
        _circleAlphaThread = circleAlphaThread
        circleIndicatorConn = player.CharacterRemoving:Connect(clearCircleIndicator)
        _circleIndicatorConn = circleIndicatorConn
        _circleIndicatorBB = bb
    end

    local function hidePanel()
        cancelHideTimer()
        if warningTimer then task.cancel(warningTimer); warningTimer = nil end
        clearBaseZone()
        if isExpanded then
            -- El historial es independiente: sigue abierto aunque termine el robo o la reproduccion.
            infoLabel.Text = L("📎 Historial de animaciones", "📎 Animation history")
            infoLabel.TextColor3 = AFO_TEXT
            _TweenService:Create(infoLabel, TWEEN_IN, {TextTransparency = 0}):Play()
            return
        end
        _TweenService:Create(shadow, TWEEN_OUT, {BackgroundTransparency = 1}):Play()
        _TweenService:Create(panel, TWEEN_OUT, {BackgroundTransparency = 1}):Play()
        _TweenService:Create(stroke, TWEEN_OUT, {Transparency = 1}):Play()
        task.delay(0.35, function()
            if not isStealerActive and not isStolenPlaying and not isExpanded then
                panel.Visible = false
                shadow.Visible = false
                warningLabel.Visible = false
                execBtn.Visible = false
                idButton.Visible = false
            end
        end)
    end

    local function showWarning(label)
        cancelHideTimer()
        if warningTimer then task.cancel(warningTimer); warningTimer = nil end
        clearBaseZone()
        warningLabel.Text = label
        warningLabel.Visible = true
        panel.Visible = true
        shadow.Visible = true
        baseZone.Size = UDim2.new(1, 0, 0, BASE_HEIGHT)
        if not isExpanded then applyPanelSize(BASE_HEIGHT, false) end
        _TweenService:Create(shadow, TWEEN_IN, {BackgroundTransparency = 0.58}):Play()
        _TweenService:Create(panel, TWEEN_IN, {BackgroundTransparency = 0.08}):Play()
        _TweenService:Create(stroke, TWEEN_IN, {Transparency = 0.3}):Play()
        _TweenService:Create(warningLabel, TWEEN_IN, {TextTransparency = 0}):Play()
        warningTimer = task.delay(2, function()
            warningTimer = nil
            _TweenService:Create(warningLabel, TWEEN_OUT, {TextTransparency = 1}):Play()
            task.delay(0.32, function()
                warningLabel.Visible = false
                if not isStealerActive and not isStolenPlaying then
                    _TweenService:Create(shadow, TWEEN_OUT, {BackgroundTransparency = 1}):Play()
                    _TweenService:Create(panel, TWEEN_OUT, {BackgroundTransparency = 1}):Play()
                    _TweenService:Create(stroke, TWEEN_OUT, {Transparency = 1}):Play()
                    task.delay(0.32, function() panel.Visible = false; shadow.Visible = false end)
                end
            end)
        end)
    end

    local function showPanelModoT(label)
        cancelHideTimer()
        clearBaseZone()
        execBtn.Visible = true
        execBtn.Text = L("▶ Ejecutar animación robada ["..kn(emoteExecuteKey).."]", "▶ Play stolen animation ["..kn(emoteExecuteKey).."]")
        infoLabel.Position = UDim2.new(0, 9, 0, 5)
        execBtn.Position = UDim2.new(0, 9, 0, 28)
        execBtn.Size = UDim2.new(1, -18, 0, 26)
        baseZone.Size = UDim2.new(1, 0, 0, BASE_HEIGHT)
        if label then infoLabel.Text = label end
        infoLabel.TextColor3 = AFO_TEXT
        panel.Visible = true
        shadow.Visible = true
        if not isExpanded then applyPanelSize(BASE_HEIGHT, false) end
        _TweenService:Create(shadow, TWEEN_IN, {BackgroundTransparency = 0.52}):Play()
        _TweenService:Create(panel, TWEEN_IN, {BackgroundTransparency = 0.08}):Play()
        _TweenService:Create(stroke, TWEEN_IN, {Transparency = 0}):Play()
        _TweenService:Create(infoLabel, TWEEN_IN, {TextTransparency = 0}):Play()
        _TweenService:Create(execBtn, TWEEN_IN, {BackgroundTransparency = 0, TextTransparency = 0}):Play()
    end

    local function showPanelModoY(animId, sourceDisplay)
        cancelHideTimer()
        clearBaseZone()
        idButton.Visible = true
        local idShort = animId and (animId:match("%d+") or animId) or "?"
        local clipboard_label = L("portapapeles", "clipboard")
        local srcLabel = sourceDisplay or clipboard_label
        infoLabel.Text = L("▶ Ejecutando · De: ", "▶ Playing · From: ") .. srcLabel
        infoLabel.Position = UDim2.new(0, 9, 0, 4)
        idButton.Position = UDim2.new(0, 9, 0, 28)
        idButton.Size = UDim2.new(1, -18, 0, 22)
        idButton.Text = "📋 " .. idShort .. L(" (clic para copiar)", " (click to copy)")
        baseZone.Size = UDim2.new(1, 0, 0, PLAYING_HEIGHT)
        panel.Visible = true
        shadow.Visible = true
        if not isExpanded then applyPanelSize(PLAYING_HEIGHT, true) end
        _TweenService:Create(shadow, TWEEN_IN, {BackgroundTransparency = 0.52}):Play()
        _TweenService:Create(panel, TWEEN_IN, {BackgroundTransparency = 0.08}):Play()
        _TweenService:Create(stroke, TWEEN_IN, {Transparency = 0}):Play()
        _TweenService:Create(infoLabel, TWEEN_IN, {TextTransparency = 0}):Play()
        _TweenService:Create(idButton, TWEEN_IN, {TextTransparency = 0, BackgroundTransparency = 0.4}):Play()
    end

    local rebuildHistoryUI

    local function persistHistory()
        saveHistoryFile(stolenHistory)
        mirrorHistoryToCharacter(stolenHistory)
    end

    -- Añade (o sube al primer puesto si ya existia) una animacion. Devuelve la entrada.
    local function addToHistory(animId, ownerName, ownerDisplay)
        if not animId or animId == "" then return nil end
        local idNum = shortId(animId)
        local clipboard_label = L("portapapeles", "clipboard")
        local entry
        for i = #stolenHistory, 1, -1 do
            if shortId(stolenHistory[i].animId) == idNum then
                entry = table.remove(stolenHistory, i)
                break
            end
        end
        if entry then
            entry.ownerName   = ownerName or entry.ownerName
            entry.displayName = ownerDisplay or ownerName or entry.displayName
            entry.time        = os.time()
        else
            entry = {
                animId        = animId,
                ownerName     = ownerName or clipboard_label,
                displayName   = ownerDisplay or ownerName or clipboard_label,
                animationName = "",
                duration      = 0,
                time          = os.time(),
            }
        end
        table.insert(stolenHistory, entry)
        while #stolenHistory > MAX_HISTORY do table.remove(stolenHistory, 1) end
        persistHistory()

        if entry.animationName == "" then
            task.spawn(function()
                local ok, info = pcall(function()
                    return MarketplaceService:GetProductInfo(tonumber(idNum), Enum.InfoType.Asset)
                end)
                if not _running then return end
                entry.animationName = (ok and info and info.Name) or L("Animación sin nombre", "Unnamed animation")
                persistHistory()
                if isExpanded then rebuildHistoryUI() end
            end)
        end
        if isExpanded then rebuildHistoryUI() end
        return entry
    end

    local function removeFromHistory(entry)
        for i = #stolenHistory, 1, -1 do
            if stolenHistory[i] == entry then table.remove(stolenHistory, i) break end
        end
        persistHistory()
        rebuildHistoryUI()
    end

    -- Boton "borrar todo" en la cabecera del historial
    local clearHistBtn = Instance.new("TextButton")
    clearHistBtn.Name = "ClearHistory"
    clearHistBtn.Size = UDim2.new(0, 34, 0, 22)
    clearHistBtn.Position = UDim2.new(1, -43, 0, 6)
    clearHistBtn.BackgroundColor3 = Color3.fromRGB(75, 22, 36)
    clearHistBtn.TextColor3 = AFO_TEXT
    clearHistBtn.Text = "🗑"
    clearHistBtn.Font = Enum.Font.Legacy
    clearHistBtn.TextSize = 14
    clearHistBtn.BorderSizePixel = 0
    clearHistBtn.ZIndex = 6
    clearHistBtn.Parent = expandZone
    do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 5); c.Parent = clearHistBtn end
    clearHistBtn.MouseButton1Click:Connect(function()
        for i = #stolenHistory, 1, -1 do table.remove(stolenHistory, i) end
        persistHistory()
        rebuildHistoryUI()
    end)

    rebuildHistoryUI = function()
        for _, child in ipairs(historyFrame:GetChildren()) do
            if child:IsA("GuiObject") then child:Destroy() end
        end
        if #stolenHistory == 0 then
            local emptyLabel = Instance.new("TextLabel")
            emptyLabel.Size = UDim2.new(1, -8, 0, 26)
            emptyLabel.BackgroundTransparency = 1
            emptyLabel.Text = L("Aún no hay animaciones en el historial.", "There are no animations in the history yet.")
            emptyLabel.TextColor3 = AFO_TEXT
            emptyLabel.TextTransparency = 0.3
            emptyLabel.Font = Enum.Font.Gotham
            emptyLabel.TextSize = 11
            emptyLabel.TextWrapped = true
            emptyLabel.ZIndex = 6
            emptyLabel.Parent = historyFrame
        end
        local totalH = 0
        for i = #stolenHistory, 1, -1 do
            local entry = stolenHistory[i]
            local idShort = entry.animId:match("%d+") or entry.animId

            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, 0, 0, 76)
            row.BackgroundColor3 = AFO_PURPLE_DIM
            row.BackgroundTransparency = 0.35
            row.BorderSizePixel = 0
            row.LayoutOrder = #stolenHistory - i
            row.ZIndex = 5
            row.Parent = historyFrame
            do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 6); c.Parent = row end

            local ownerText = L("Usuario robado: ", "Stolen user: ") .. entry.displayName .. " · " .. entry.ownerName
            if (entry.time or 0) > 0 then
                local okD, hhmm = pcall(os.date, "%H:%M", entry.time)
                if okD then ownerText = ownerText .. " · " .. hhmm end
            end
            local ownerLabel = Instance.new("TextLabel")
            ownerLabel.Size = UDim2.new(1, -62, 0, 14)
            ownerLabel.Position = UDim2.new(0, 6, 0, 3)
            ownerLabel.BackgroundTransparency = 1
            ownerLabel.TextColor3 = AFO_TEXT
            ownerLabel.TextTransparency = 0.35
            ownerLabel.Text = ownerText
            ownerLabel.Font = Enum.Font.Gotham
            ownerLabel.TextSize = 9
            ownerLabel.TextXAlignment = Enum.TextXAlignment.Left
            ownerLabel.TextTruncate = Enum.TextTruncate.AtEnd
            ownerLabel.ZIndex = 6
            ownerLabel.Parent = row

            local nameLabel = Instance.new("TextLabel")
            nameLabel.Size = UDim2.new(1, -62, 0, 18)
            nameLabel.Position = UDim2.new(0, 6, 0, 17)
            nameLabel.BackgroundTransparency = 1
            nameLabel.TextColor3 = AFO_TEXT
            local shownName = (entry.animationName ~= "" and entry.animationName) or L("Resolviendo animación…", "Resolving animation…")
            nameLabel.Text = shownName .. " · " .. idShort
            nameLabel.Font = Enum.Font.GothamSemibold
            nameLabel.TextSize = 11
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
            nameLabel.ZIndex = 6
            nameLabel.Parent = row

            local copyBtn = Instance.new("TextButton")
            copyBtn.Size = UDim2.new(1, -62, 0, 19)
            copyBtn.Position = UDim2.new(0, 4, 0, 37)
            copyBtn.BackgroundColor3 = AFO_BLACK
            copyBtn.BackgroundTransparency = 0.2
            copyBtn.TextColor3 = AFO_ACCENT
            copyBtn.Text = "📋 " .. idShort
            copyBtn.Font = Enum.Font.Code
            copyBtn.TextScaled = true
            copyBtn.BorderSizePixel = 0
            copyBtn.ZIndex = 6
            copyBtn.Parent = row
            do local c2 = Instance.new("UICorner"); c2.CornerRadius = UDim.new(0, 4); c2.Parent = copyBtn end
            local copied = false
            local capturedId = entry.animId
            copyBtn.MouseButton1Click:Connect(function()
                if copied then return end
                copied = true
                pcall(function() setclipboard(capturedId) end)
                local orig = copyBtn.Text
                copyBtn.Text = L("✓ ¡Copiado!", "✓ Copied!")
                copyBtn.TextColor3 = AFO_GREEN
                task.wait(1.2)
                copyBtn.Text = orig
                copyBtn.TextColor3 = AFO_ACCENT
                copied = false
            end)

            local durationLabel = Instance.new("TextLabel")
            durationLabel.Size = UDim2.new(1, -62, 0, 14)
            durationLabel.Position = UDim2.new(0, 6, 0, 59)
            durationLabel.BackgroundTransparency = 1
            durationLabel.TextColor3 = AFO_ACCENT
            durationLabel.Text = "━━━━ " .. formatDuration(entry.duration) .. " ━━━━"
            durationLabel.Font = Enum.Font.Gotham
            durationLabel.TextSize = 9
            durationLabel.TextXAlignment = Enum.TextXAlignment.Left
            durationLabel.ZIndex = 6
            durationLabel.Parent = row

            -- Borrar esta entrada
            local delBtn = Instance.new("TextButton")
            delBtn.Size = UDim2.new(0, 52, 0, 18)
            delBtn.Position = UDim2.new(1, -56, 0, 4)
            delBtn.BackgroundColor3 = Color3.fromRGB(75, 22, 36)
            delBtn.TextColor3 = AFO_TEXT
            delBtn.Text = "✕"
            delBtn.Font = Enum.Font.GothamBold
            delBtn.TextSize = 11
            delBtn.BorderSizePixel = 0
            delBtn.ZIndex = 7
            delBtn.Parent = row
            do local c4 = Instance.new("UICorner"); c4.CornerRadius = UDim.new(0, 5); c4.Parent = delBtn end
            delBtn.MouseButton1Click:Connect(function() removeFromHistory(entry) end)

            local playHistoryButton = Instance.new("TextButton")
            playHistoryButton.Size = UDim2.new(0, 52, 0, 46)
            playHistoryButton.Position = UDim2.new(1, -56, 0, 26)
            playHistoryButton.BackgroundColor3 = AFO_PURPLE
            playHistoryButton.TextColor3 = Color3.new(1, 1, 1)
            playHistoryButton.Text = ">"
            playHistoryButton.Font = Enum.Font.GothamBold
            playHistoryButton.TextSize = 20
            playHistoryButton.BorderSizePixel = 0
            playHistoryButton.ZIndex = 7
            playHistoryButton.Parent = row
            do local c3 = Instance.new("UICorner"); c3.CornerRadius = UDim.new(0, 7); c3.Parent = playHistoryButton end
            playHistoryButton.MouseButton1Click:Connect(function()
                if playAnimationInPlayer then playAnimationInPlayer(entry.animId, entry.animationName, entry) end
            end)
            totalH = totalH + 80
        end
        historyFrame.CanvasSize = UDim2.new(0, 0, 0, totalH)
        -- La fila más reciente queda arriba; el ScrollBar permite recorrer las anteriores.
        historyFrame.CanvasPosition = Vector2.new(0, 0)
    end

    -- Muestra la base del panel con la etiqueta "Historial" cuando no hay otra cosa activa
    local function showBaseForHistory()
        if panel.Visible then return end
        cancelHideTimer()
        clearBaseZone()
        infoLabel.Text = L("📎 Historial de animaciones", "📎 Animation history")
        infoLabel.TextColor3 = AFO_TEXT
        infoLabel.Position = UDim2.new(0, 9, 0, 5)
        baseZone.Size = UDim2.new(1, 0, 0, BASE_HEIGHT)
        panel.Visible = true
        shadow.Visible = true
        applyPanelSize(BASE_HEIGHT, false)
        _TweenService:Create(shadow, TWEEN_IN, {BackgroundTransparency = 0.52}):Play()
        _TweenService:Create(panel, TWEEN_IN, {BackgroundTransparency = 0.08}):Play()
        _TweenService:Create(stroke, TWEEN_IN, {Transparency = 0}):Play()
        _TweenService:Create(infoLabel, TWEEN_IN, {TextTransparency = 0}):Play()
    end

    local function openHistoryPanel()
        if isExpanded then return end
        showBaseForHistory()
        isExpanded = true
        rebuildHistoryUI()
        local baseH = getPanelBaseH()
        local rows = math.min(#stolenHistory, MAX_HISTORY)
        local headerH = 34
        local rawHistH = rows * 80
        local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
        local maxTotal = math.floor(vp.Y - 30)
        local maxHistH = maxTotal - baseH - headerH
        local histH = math.max(math.min(rawHistH, maxHistH), 40)
        local totalH = baseH + headerH + histH
        expandZone.Position = UDim2.new(0, 0, 1, -baseH)
        expandZone.Size = UDim2.new(1, 0, 0, headerH + histH)
        expandZone.Visible = true
        baseZone.Size = UDim2.new(1, 0, 0, baseH)
        applyPanelSize(totalH, true)
    end

    local function closeHistoryPanel()
        if not isExpanded then return end
        isExpanded = false
        local baseH = getPanelBaseH()
        applyPanelSize(baseH, true)
        task.delay(0.28, function() expandZone.Visible = false end)
        -- Si no hay robo ni reproduccion activos, el panel se oculta del todo
        if not isStealerActive and not isStolenPlaying and not warningLabel.Visible then
            hidePanel()
        end
    end

    -- Devuelve el Animator vigente; lo busca/crea si aun no existe (evita que T/Y no hagan nada)
    local function getAnimator()
        if animator and animator.Parent then return animator end
        local char = _lplr.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not hum then return nil end
        local a = hum:FindFirstChildOfClass("Animator")
        if not a then
            a = Instance.new("Animator")
            a.Parent = hum
        end
        animator = a
        _animator = a
        return a
    end

    local function unlockAnimations()
        if animatorConn then animatorConn:Disconnect(); animatorConn = nil end
    end

    local function lockAnimations(allowedId)
        unlockAnimations()
        if not getAnimator() then return end
        animatorConn = animator.AnimationPlayed:Connect(function(track)
            if track.Animation and track.Animation.AnimationId ~= allowedId then track:Stop(0) end
        end)
        _animatorConn = animatorConn
    end

    local function stopAllTracks()
        if not getAnimator() then return end
        for _, t in ipairs(animator:GetPlayingAnimationTracks()) do t:Stop(0) end
    end

    -- ==========================================
    -- LOGICA DEL REPRODUCTOR Y KEYFRAMES
    -- ==========================================
    local function closePlayer(stopTrack)
        if stopTrack and playerTrack then pcall(function() playerTrack:Stop(0.12) end) end
        if stopTrack then playerTrack = nil end
        if playerRenderConn then playerRenderConn:Disconnect(); playerRenderConn = nil; _playerRenderConn = nil end
        pcall(function() playerInput:ReleaseFocus() end)
        playerPanel.Visible = false
    end

    local function updatePlayerTimeline()
        if not playerTrack then
            timelineFill.Size = UDim2.new(0, 0, 1, 0)
            timeLabel.Text = "0.00s / 0.00s · 0%"
            return
        end
        local length = math.max(playerTrack.Length or 0, 0.001)
        local position = math.clamp(playerTrack.TimePosition or 0, 0, length)
        local percentage = position / length
        timelineFill.Size = UDim2.new(percentage, 0, 1, 0)
        timeLabel.Text = string.format("%.2fs / %.2fs · %d%%", position, length, math.floor(percentage * 100))
    end

    local function startPlayerTimeline(entry)
        if playerRenderConn then playerRenderConn:Disconnect() end
        playerRenderConn = _RunService.RenderStepped:Connect(function()
            if not playerTrack then return end
            updatePlayerTimeline()
            if entry and playerTrack.Length and playerTrack.Length > 0 and entry.duration ~= playerTrack.Length then
                entry.duration = playerTrack.Length
                persistHistory()
                if isExpanded then rebuildHistoryUI() end
            end
        end)
        _playerRenderConn = playerRenderConn
    end

    playAnimationInPlayer = function(rawId, animationName, historyEntry)
        local animationId = normalizeAnimationId(rawId)
        if not animationId or not getAnimator() then
            showWarning(L("⚠ ID de animación inválido", "⚠ Invalid animation ID"))
            return
        end
        -- Las cargadas a mano por ID tambien quedan en el historial
        if not historyEntry then
            historyEntry = addToHistory(animationId, L("manual", "manual"), L("ID manual", "Manual ID"))
        end
        -- Cargar una nueva animación sustituye por completo a la anterior.
        unlockAnimations()
        stopAllTracks()
        if playerTrack then pcall(function() playerTrack:Stop(0) end) end
        isStolenPlaying = false
        stolenTrack = nil
        _stolenTrack = nil
        local animObj = Instance.new("Animation")
        animObj.AnimationId = animationId
        local newTrack = animator:LoadAnimation(animObj)
        newTrack.Priority = Enum.AnimationPriority.Action4
        newTrack.Looped = false
        newTrack:Play(0.1, 1, 1)
        playerTrack = newTrack
        playerPaused, playerLooped = false, false
        playerInput.Text = shortId(animationId)
        playerName.Text = (animationName and animationName ~= "" and animationName or L("Animación sin nombre", "Unnamed animation")) .. " · " .. shortId(animationId)
        pauseButton.Text = L("❚❚ Pausa", "❚❚ Pause")
        loopButton.Text = L("↻ Loop", "↻ Loop")
        loopButton.BackgroundColor3 = Color3.fromRGB(28, 18, 45)
        playerPanel.Visible = true
        startPlayerTimeline(historyEntry)
    end

    playerClose.MouseButton1Click:Connect(function() closePlayer(true) end)
    stopButton.MouseButton1Click:Connect(function()
        unlockAnimations(); stopAllTracks(); playerTrack = nil; isStolenPlaying = false
        closePlayer(false)
    end)
    playButton.MouseButton1Click:Connect(function() playAnimationInPlayer(playerInput.Text, nil, nil) end)
    playerInput.FocusLost:Connect(function(enterPressed)
        if enterPressed then playAnimationInPlayer(playerInput.Text, nil, nil) end
    end)
    pauseButton.MouseButton1Click:Connect(function()
        if not playerTrack then return end
        if playerPaused then
            if playerTrack.TimePosition >= math.max(playerTrack.Length - 0.05, 0) then playerTrack.TimePosition = 0; playerTrack:Play() else playerTrack:AdjustSpeed(1) end
            playerPaused = false; pauseButton.Text = L("❚❚ Pausa", "❚❚ Pause")
        else
            playerTrack:AdjustSpeed(0); playerPaused = true; pauseButton.Text = L("▶ Reanudar", "▶ Resume")
        end
    end)
    loopButton.MouseButton1Click:Connect(function()
        if not playerTrack then return end
        playerLooped = not playerLooped
        playerTrack.Looped = playerLooped
        loopButton.Text = playerLooped and L("↻ Loop ON", "↻ Loop ON") or L("↻ Loop", "↻ Loop")
        loopButton.BackgroundColor3 = playerLooped and Color3.fromRGB(20, 75, 42) or Color3.fromRGB(28, 18, 45)
    end)
    timelineBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then playerScrubbing = true end
    end)
    _playerInputChanged = _UserInputService.InputChanged:Connect(function(input)
        if playerScrubbing and input.UserInputType == Enum.UserInputType.MouseMovement and playerTrack and playerTrack.Length > 0 then
            local fraction = math.clamp((input.Position.X - timelineBar.AbsolutePosition.X) / timelineBar.AbsoluteSize.X, 0, 1)
            playerTrack.TimePosition = fraction * playerTrack.Length
            updatePlayerTimeline()
        end
    end)
    _playerInputEnded = _UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then playerScrubbing = false end
    end)

    local BLOCKED_ANIM_IDS = {
        STEALER_ANIM_ID,
        "rbxassetid://13076726811",
        "rbxassetid://13076725138",
        "rbxassetid://13076773226",
        "rbxassetid://180435571",
    }
    local function isBlockedAnim(id)
        if not id or id == "" then return false end
        for _, blocked in ipairs(BLOCKED_ANIM_IDS) do
            if id == blocked then return true end
            local blockedNum = blocked:match("%d+")
            local idNum = id:match("%d+")
            if blockedNum and idNum and blockedNum == idNum then return true end
        end
        return false
    end

    local function stealFromTarget(player)
        if not player or not player.Character then return nil end
        local char = player.Character
        local humanoid = char:FindFirstChildOfClass("Humanoid"); if not humanoid then return nil end
        local anim = humanoid:FindFirstChildOfClass("Animator") or char:FindFirstChildOfClass("Animator")
        if not anim then return nil end
        local tracks = anim:GetPlayingAnimationTracks()
        if #tracks == 0 then return nil end
        for i = #tracks, 1, -1 do
            local t = tracks[i]
            if t and t.Animation and t.Animation.AnimationId ~= "" then
                local id = t.Animation.AnimationId
                if not isBlockedAnim(id) then return id end
            end
        end
        return nil
    end

    local function getTargetInView()
        if not workspace.CurrentCamera then return nil end
        local char = _lplr.Character
        -- Excluir el modelo ya excluye todos sus descendientes (antes se armaba una tabla enorme por frame)
        local excluded = {}
        if char then table.insert(excluded, char) end
        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude
        raycastParams.FilterDescendantsInstances = excluded
        local origin = workspace.CurrentCamera.CFrame.Position
        local look = workspace.CurrentCamera.CFrame.LookVector
        local result = workspace:Raycast(origin, look * MAX_STEAL_DIST, raycastParams)
        if result and result.Instance then
            local model = result.Instance:FindFirstAncestorOfClass("Model")
            if model then
                local p = _Players:GetPlayerFromCharacter(model)
                if p and p ~= _lplr then return p end
            end
        end
        local bestDot, bestPlayer = 0.90, nil
        for _, p in ipairs(_Players:GetPlayers()) do
            if p == _lplr then continue end
            local pchar = p.Character; if not pchar then continue end
            local hrp = pchar:FindFirstChild("HumanoidRootPart"); if not hrp then continue end
            local myHRP = char and char:FindFirstChild("HumanoidRootPart")
            if myHRP and (hrp.Position - myHRP.Position).Magnitude > MAX_STEAL_DIST then continue end
            local dot = look:Dot((hrp.Position - origin).Unit)
            if dot > bestDot then bestDot = dot; bestPlayer = p end
        end
        if bestPlayer then return bestPlayer end
        local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
        local cx, cy = vp.X / 2, vp.Y / 2
        local bestDist2D, bestByScreen = math.huge, nil
        for _, p in ipairs(_Players:GetPlayers()) do
            if p == _lplr then continue end
            local pchar = p.Character; if not pchar then continue end
            local hrp = pchar:FindFirstChild("HumanoidRootPart"); if not hrp then continue end
            local myHRP = char and char:FindFirstChild("HumanoidRootPart")
            if myHRP and (hrp.Position - myHRP.Position).Magnitude > MAX_STEAL_DIST then continue end
            local screenPos, onScreen = workspace.CurrentCamera:WorldToScreenPoint(hrp.Position)
            if not onScreen then continue end
            local d2 = (screenPos.X - cx)^2 + (screenPos.Y - cy)^2
            if d2 < 200*200 and d2 < bestDist2D then bestDist2D = d2; bestByScreen = p end
        end
        return bestByScreen
    end

    local function actualizarPanelModoT(player, targetChanged)
        if not isStealerActive then return end
        if warningLabel.Visible then return end
        currentAimedPlayer = player
        if player then
            local animId = stealFromTarget(player)
            if animId then
                stoledAnimId = animId
                stolenAnimOwner = player
                stolenAnimSource = "player"
            elseif targetChanged or stolenAnimOwner ~= player then
                stoledAnimId = nil
                stolenAnimOwner = player
                stolenAnimSource = "player"
            end
            local displayName = player.DisplayName ~= "" and player.DisplayName or player.Name
            setRingState(stoledAnimId ~= nil and stolenAnimOwner == player)
            if stoledAnimId and stolenAnimOwner == player then
                infoLabel.Text = L("Robada de ", "Stolen from ") .. displayName .. " · " .. (stoledAnimId:match("%d+") or stoledAnimId)
            else
                infoLabel.Text = L("Sin animación en ", "No animation on ") .. displayName
            end
        else
            infoLabel.Text = L("Sin objetivo en rango", "No target in range")
        end
    end

    local function ejecutarRobada()
        if not getAnimator() then
            showWarning(L("⚠ Personaje no listo", "⚠ Character not ready"))
            return
        end
        if isStolenPlaying then
            isStolenPlaying = false
            unlockAnimations()
            if stolenTrack then stolenTrack:Stop(0.2); stolenTrack = nil end
            hidePanel()
            return
        end
        if not stoledAnimId or stoledAnimId == "" then
            showWarning(L("⚠ Roba una animación primero ["..kn(emoteStealKey).."]", "⚠ Steal an animation first ["..kn(emoteStealKey).."]"))
            return
        end
        if isStealerActive then
            isStealerActive = false
            if stealerTrack then
                unlockAnimations()
                stealerTrack:AdjustSpeed(1)
                stealerTrack:Stop(0)
                stealerTrack = nil
            end
            clearCircleIndicator()
            resetBorder()
            stopPulse()
        end
        local clipboard_label = L("portapapeles", "clipboard")
        local sourceDisplay, sourceName
        if stolenAnimSource == "clipboard" then
            sourceDisplay = clipboard_label; sourceName = clipboard_label
        else
            sourceDisplay = stolenAnimOwner
                and (stolenAnimOwner.DisplayName ~= "" and stolenAnimOwner.DisplayName or stolenAnimOwner.Name)
                or clipboard_label
            sourceName = stolenAnimOwner and stolenAnimOwner.Name or clipboard_label
        end
        local histEntry = addToHistory(stoledAnimId, sourceName, sourceDisplay)
        isStolenPlaying = true
        stopAllTracks()
        local animObj = Instance.new("Animation")
        animObj.AnimationId = stoledAnimId
        stolenTrack = animator:LoadAnimation(animObj)
        stolenTrack.Priority = Enum.AnimationPriority.Action4
        stolenTrack.Looped = true
        stolenTrack:Play(0.1, 1, 1)
        _stolenTrack = stolenTrack
        -- Guarda la duracion real en el historial en cuanto el track la conozca
        local lengthTrack = stolenTrack
        task.spawn(function()
            local waited = 0
            while lengthTrack and (lengthTrack.Length or 0) == 0 and waited < 2 do
                waited = waited + task.wait(0.05)
            end
            if histEntry and lengthTrack and (lengthTrack.Length or 0) > 0 and histEntry.duration ~= lengthTrack.Length then
                histEntry.duration = lengthTrack.Length
                persistHistory()
                if isExpanded then rebuildHistoryUI() end
            end
        end)
        task.wait()
        lockAnimations(stoledAnimId)
        resetBorder()
        showPanelModoY(stoledAnimId, sourceDisplay)
    end

    local function activarStealer()
        if not getAnimator() then
            isStealerActive = false
            showWarning(L("⚠ Personaje no listo", "⚠ Character not ready"))
            return
        end
        local firstTarget = getTargetInView()
        currentAimedPlayer = firstTarget
        if firstTarget then
            stolenAnimOwner = firstTarget
            stoledAnimId = stealFromTarget(firstTarget)
            stolenAnimSource = "player"
        end
        local label
        if firstTarget then
            local displayName = firstTarget.DisplayName ~= "" and firstTarget.DisplayName or firstTarget.Name
            if stoledAnimId then
                label = L("Robada de ", "Stolen from ") .. displayName .. " · " .. (stoledAnimId:match("%d+") or stoledAnimId)
            else
                label = L("Sin animación en ", "No animation on ") .. displayName
            end
        else
            label = L("Sin objetivo en rango", "No target in range")
        end
        stopAllTracks()
        unlockAnimations()
        local animObj = Instance.new("Animation")
        animObj.AnimationId = STEALER_ANIM_ID
        stealerTrack = animator:LoadAnimation(animObj)
        stealerTrack.Priority = Enum.AnimationPriority.Action4
        stealerTrack.Looped = false
        lockAnimations(STEALER_ANIM_ID)
        stealerTrack:Play(0.1, 1, 1)
        _stealerTrack = stealerTrack
        local activeStealerTrack = stealerTrack
        task.spawn(function()
            local waited = 0
            while activeStealerTrack and activeStealerTrack == stealerTrack
                and (not activeStealerTrack.Length or activeStealerTrack.Length == 0)
                and waited < 2 do
                waited += task.wait(0.05)
            end
            if not activeStealerTrack or activeStealerTrack ~= stealerTrack then return end
            local len = activeStealerTrack.Length
            if len and len > 0 then
                local targetTime = len * 0.55
                local elapsed = 0
                repeat elapsed += task.wait()
                until not activeStealerTrack or activeStealerTrack ~= stealerTrack
                    or not activeStealerTrack.IsPlaying or elapsed >= targetTime
                if activeStealerTrack and activeStealerTrack == stealerTrack and activeStealerTrack.IsPlaying then
                    activeStealerTrack:AdjustSpeed(0)
                end
            end
        end)
        showPanelModoT(label)
        startPulse()
        if firstTarget then showCircleIndicator(firstTarget) end
    end

    local function cancelarStealer()
        unlockAnimations()
        if stealerTrack then
            stealerTrack:AdjustSpeed(1)
            stealerTrack:Stop(0.2)
            stealerTrack = nil
        end
        clearCircleIndicator()
        resetBorder()
        hidePanel()
    end

    idButton.MouseButton1Click:Connect(function()
        if not stoledAnimId then return end
        pcall(function() setclipboard(stoledAnimId) end)
        local orig = idButton.Text
        idButton.Text = L("✓ ¡ID copiado!", "✓ ID copied!")
        idButton.TextColor3 = AFO_GREEN
        task.wait(1.2)
        idButton.Text = orig
        idButton.TextColor3 = AFO_ACCENT
    end)

    execBtn.MouseButton1Click:Connect(function() ejecutarRobada() end)

    local function closeInputPopup()
        isInputOpen = false
        pcall(function() inputBox:ReleaseFocus() end)
        inputPopup.Visible = false
        inputBox.Text = ""
    end

    local function confirmInputId()
        local raw = inputBox.Text
        local digits = raw:match("%d+")
        if not digits or digits == "" then
            inputStroke.Color = AFO_WARN
            task.delay(0.7, function() inputStroke.Color = AFO_ACCENT end)
            return
        end
        local candidateId = "rbxassetid://" .. digits
        if isBlockedAnim(candidateId) then
            closeInputPopup()
            showWarning(L("⚠ ID bloqueada — animaciones meh", "⚠ ID blocked — meh animations"))
            stoledAnimId = nil
            return
        end
        stoledAnimId = candidateId
        stolenAnimOwner = nil
        stolenAnimSource = "clipboard"
        closeInputPopup()
        ejecutarRobada()
    end

    inputConfirmBtn.MouseButton1Click:Connect(confirmInputId)
    inputBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then confirmInputId() end
    end)

    -- Captura el foco un frame despues para que la tecla que abrio el popup no se escriba dentro
    local function focusBoxLater(box)
        task.spawn(function()
            _RunService.RenderStepped:Wait()
            if box and box.Parent and _running then box:CaptureFocus() end
        end)
    end

    local function openInputPopup()
        isInputOpen = true
        inputBox.Text = ""
        inputPopup.Visible = true
        focusBoxLater(inputBox)
    end

    _miscRenderConn = _RunService.RenderStepped:Connect(function()
        if not _running then return end
        if not _lplr.Character or not _lplr.Character.Parent then return end
        if isStealerActive then
            local aimed = getTargetInView()
            if aimed ~= lastCirclePlayer then
                lastCirclePlayer = aimed
                if aimed then showCircleIndicator(aimed) else clearCircleIndicator() end
                actualizarPanelModoT(aimed, true)
            elseif aimed then
                -- recrea el anillo si el objetivo reaparecio y refresca la animacion cada 0.2 s
                showCircleIndicator(aimed)
                local now = os.clock()
                if now - lastStealPoll >= 0.2 then
                    lastStealPoll = now
                    actualizarPanelModoT(aimed, false)
                end
            end
        else
            if lastCirclePlayer ~= nil then
                lastCirclePlayer = nil
                clearCircleIndicator()
            end
        end
    end)

    -- Teclas: se consulta IsKeyDown en vez de banderas "held" (no se atascan al perder el foco de la ventana)
    -- y se ignora gameProcessed (muchos juegos lo marcan en true), salvo que estes escribiendo en una caja de texto.
    local function isDown(key) return key ~= nil and _UserInputService:IsKeyDown(key) end

    local function onInputBegan(input)
        if not _running then return end
        local kc = input.KeyCode
        if kc == Enum.KeyCode.Unknown then return end

        local stealKey   = _Keys.EmoteSteal
        local executeKey = _Keys.EmoteExecute
        local expandKey  = _Keys.EmoteExpand

        local focused = _UserInputService:GetFocusedTextBox()
        if kc == Enum.KeyCode.Escape then
            if isInputOpen then closeInputPopup(); return end
            if focused == playerInput then pcall(function() playerInput:ReleaseFocus() end); return end
        end
        if focused then
            -- Popup de ID abierto: T+Y lo cierra aunque la caja tenga el foco (antes era imposible)
            if isInputOpen and focused == inputBox
                and ((kc == stealKey and isDown(executeKey)) or (kc == executeKey and isDown(stealKey))) then
                closeInputPopup()
            end
            return
        end

        local function togglePopup()
            if isInputOpen then closeInputPopup() else openInputPopup() end
        end
        local function toggleHistory()
            if isExpanded then closeHistoryPanel() else openHistoryPanel() end
        end

        if kc == stealKey then
            if isDown(executeKey) then togglePopup(); return end      -- T + Y
            if isInputOpen then closeInputPopup(); return end
            if isStolenPlaying then ejecutarRobada(); return end
            isStealerActive = not isStealerActive
            if isStealerActive then activarStealer() else cancelarStealer() end
            return
        end

        if kc == executeKey then
            if isDown(stealKey) then togglePopup(); return end        -- T + Y
            if isDown(expandKey) then toggleHistory(); return end     -- Y + U
            if isInputOpen then closeInputPopup(); return end
            if isStealerActive then
                isStealerActive = false
                if stealerTrack then
                    unlockAnimations()
                    stealerTrack:AdjustSpeed(1)
                    stealerTrack:Stop(0)
                    stealerTrack = nil
                end
                clearCircleIndicator()
                resetBorder()
                stopPulse()
            end
            ejecutarRobada()
            return
        end

        if kc == expandKey then
            if isDown(executeKey) then
                toggleHistory()                                        -- Y + U
            else
                -- U abre/cierra el reproductor único; Y+U conserva el historial.
                playerPanel.Visible = not playerPanel.Visible
                if playerPanel.Visible then
                    focusBoxLater(playerInput)
                else
                    pcall(function() playerInput:ReleaseFocus() end)
                end
            end
            return
        end
    end

    _miscInputBegin = _UserInputService.InputBegan:Connect(function(input)
        local okKey, errKey = pcall(onInputBegan, input)
        if not okKey then warn("[Emote] Error en tecla: " .. tostring(errKey)) end
    end)

    local function iniciarMiscChar(char)
        unlockAnimations()
        closePlayer(true)
        clearCircleIndicator(); stopPulse()
        stealerTrack = nil; stolenTrack = nil
        _stealerTrack = nil; _stolenTrack = nil
        stoledAnimId = nil; stolenAnimOwner = nil; stolenAnimSource = nil
        isStealerActive = false; isStolenPlaying = false
        currentAimedPlayer = nil; lastCirclePlayer = nil
        isExpanded = false; isInputOpen = false
        warningLabel.Visible = false; expandZone.Visible = false
        inputPopup.Visible = false; execBtn.Visible = false; idButton.Visible = false
        hidePanel(); resetBorder()
        animator = nil; _animator = nil
        local humanoid = char:WaitForChild("Humanoid", 10)
        if humanoid then
            animator = humanoid:FindFirstChildOfClass("Animator") or humanoid:WaitForChild("Animator", 5)
            _animator = animator
        end
        getAnimator() -- respaldo: lo crea si el juego no lo trae
        mirrorHistoryToCharacter(stolenHistory) -- el Character nuevo recibe el historial guardado
    end

    -- No bloquea Start(): las teclas ya estan conectadas y el Animator se resuelve de forma perezosa
    if _lplr.Character then
        task.spawn(function()
            local ok, err = pcall(iniciarMiscChar, _lplr.Character)
            if not ok then warn("[Emote] iniciarMiscChar: " .. tostring(err)) end
        end)
    end
    _miscCharConn = _lplr.CharacterAdded:Connect(function(newChar)
        task.wait(0.5)
        if not _running then return end
        local ok, err = pcall(iniciarMiscChar, newChar)
        if not ok then warn("[Emote] iniciarMiscChar: " .. tostring(err)) end
    end)
end

function M.Stop(preserveEnabled)
    _running = false
    local function disc(c) if c then pcall(function() c:Disconnect() end) end end
    disc(_miscRenderConn);   _miscRenderConn = nil
    disc(_miscInputBegin);   _miscInputBegin = nil
    disc(_miscInputEnd);     _miscInputEnd = nil
    disc(_miscCharConn);     _miscCharConn = nil
    disc(_playerRenderConn); _playerRenderConn = nil
    disc(_playerInputChanged); _playerInputChanged = nil
    disc(_playerInputEnded); _playerInputEnded = nil
    disc(_animatorConn);     _animatorConn = nil
    disc(_circleIndicatorConn); _circleIndicatorConn = nil
    if _circleAlphaThread then pcall(task.cancel, _circleAlphaThread); _circleAlphaThread = nil end
    if _pulseThread then pcall(task.cancel, _pulseThread); _pulseThread = nil end
    if _circleIndicatorBB then pcall(function() _circleIndicatorBB:Destroy() end); _circleIndicatorBB = nil end

    -- Anillos / efectos: se destruye la carpeta completa y se barre cualquier resto con el mismo nombre
    pcall(function()
        local ch = _lplr and _lplr.Character
        local hv = ch and ch:FindFirstChild(HISTORY_VALUE_NAME)
        if hv then hv:Destroy() end
    end)
    if _ringFolder then pcall(function() _ringFolder:Destroy() end); _ringFolder = nil end
    for _ = 1, 8 do
        local leftover = workspace:FindFirstChild(FX_FOLDER_NAME)
        if not leftover then break end
        pcall(function() leftover:Destroy() end)
    end

    pcall(function()
        if _stealerTrack then _stealerTrack:AdjustSpeed(1); _stealerTrack:Stop(0) end
        if _stolenTrack then _stolenTrack:AdjustSpeed(1); _stolenTrack:Stop(0) end
        if _animator then
            for _, track in ipairs(_animator:GetPlayingAnimationTracks()) do
                pcall(function() track:AdjustSpeed(1); track:Stop(0) end)
            end
        end
    end)
    _stealerTrack = nil; _stolenTrack = nil; _animator = nil
    _isStealerActive, _isStolenPlaying = false, false

    if _screenGui then
        pcall(function() _screenGui:Destroy() end)
        _screenGui = nil
    end
    -- por si quedo un HUD huerfano de una instancia anterior
    local hosts = { game:GetService("CoreGui") }
    if _CoreGui then table.insert(hosts, _CoreGui) end
    local lp = game:GetService("Players").LocalPlayer
    if lp then table.insert(hosts, lp:FindFirstChildOfClass("PlayerGui")) end
    if type(gethui) == "function" then
        local okH, h = pcall(gethui)
        if okH and h then table.insert(hosts, h) end
    end
    for _, host in ipairs(hosts) do
        local old = host and host:FindFirstChild(HUD_NAME)
        if old then pcall(function() old:Destroy() end) end
    end

    if not preserveEnabled then
        local env = getEnv()
        if env and env.AFO_EMOTE_CLEANUP == myCleanup then env.AFO_EMOTE_CLEANUP = nil end
    end
end

function M.IsActive()
    return _running and _screenGui ~= nil and _screenGui.Parent ~= nil
end

function M.Restart()
    M.Stop(true)
    if _Keys and _lplr then
        M.Start(_Keys, _lplr, _CoreGui, _RunService, _TweenService)
    end
end

return M
