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

-- Dependencias inyectadas por Start()
local _Keys, _lplr, _CoreGui, _RunService, _TweenService, _camera, _Players, _UserInputService

function M.Start(Keys, lplr, CoreGui, RunService, TweenService, camera)
    _Keys           = Keys
    _lplr           = lplr
    _CoreGui        = CoreGui
    _RunService     = RunService
    _TweenService   = TweenService
    _camera         = camera
    _Players        = game:GetService("Players")
    _UserInputService = game:GetService("UserInputService")

    -- Alias locales para que el código interno funcione sin cambios
    local emoteStealKey   = Keys.EmoteSteal
    local emoteExecuteKey = Keys.EmoteExecute
    local emoteExpandKey  = Keys.EmoteExpand

    if _screenGui then return end  -- ya activo

    -- ══════════════════════════════════════════════
    -- A partir de aquí va TODO el código original
    -- de miscEmoteStart(), con los siguientes cambios:
    --
    --   CoreGui        → _CoreGui
    --   RunService     → _RunService
    --   TweenService   → _TweenService
    --   camera         → _camera
    --   lplr           → _lplr
    --   Players        → _Players
    --   UserInputService → _UserInputService
    --
    -- Y las variables de módulo (stealerTrack, etc.)
    -- pasan a ser las locales de módulo definidas arriba
    -- (con prefijo _), o simplemente se dejan como
    -- locales dentro de esta función si no necesitan
    -- ser accedidas desde Stop().
    -- ══════════════════════════════════════════════

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

    local BASE_HEIGHT    = 62
    local PLAYING_HEIGHT = 70
    local PANEL_POS      = UDim2.new(0.5, -144, 1, -188)
    local SHADOW_POS     = UDim2.new(0.5, -148, 1, -191)
    local MAX_STEAL_DIST = 120
    local MAX_HISTORY    = 10
    local STEALER_ANIM_ID = "rbxassetid://84027724325738"

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "StealerHUD"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = _CoreGui
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
    histTitle.Size = UDim2.new(1, -18, 0, 22)
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
    historyFrame.ScrollBarThickness = 3
    historyFrame.ScrollBarImageColor3 = AFO_ACCENT
    historyFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    historyFrame.ZIndex = 4
    historyFrame.ClipsDescendants = true
    historyFrame.Parent = expandZone

    local historyLayout = Instance.new("UIListLayout")
    historyLayout.SortOrder = Enum.SortOrder.LayoutOrder
    historyLayout.Padding = UDim.new(0, 4)
    historyLayout.Parent = historyFrame

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

    local stolenHistory  = {}
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
    local yHeld = false; local uHeld = false; local tHeld = false
    local expandConsumed = false; local tyConsumed = false; local isInputOpen = false
    local circleIndicatorBB = nil; local circleIndicatorConn = nil
    local circleAlphaThread = nil; local pulseThread = nil

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

    local function clearCircleIndicator()
        if circleAlphaThread then task.cancel(circleAlphaThread); circleAlphaThread = nil end
        if circleIndicatorConn then circleIndicatorConn:Disconnect(); circleIndicatorConn = nil end
        if circleIndicatorBB and circleIndicatorBB.Parent then circleIndicatorBB:Destroy() end
        circleIndicatorBB = nil
    end

    local function showCircleIndicator(player)
        if circleIndicatorBB and circleIndicatorBB.Adornee then
            local char = player and player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp and circleIndicatorBB.Adornee == hrp then return end
        end
        clearCircleIndicator()
        if not player or not player.Character then return end
        local root = player.Character:FindFirstChild("HumanoidRootPart")
        if not root then return end
        local bb = Instance.new("BillboardGui")
        bb.Adornee = root
        bb.Size = UDim2.new(0, 90, 0, 90)
        bb.AlwaysOnTop = false
        bb.ResetOnSpawn = false
        bb.LightInfluence = 0
        bb.Parent = workspace
        local ring = Instance.new("Frame")
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
        circleIndicatorBB = bb
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
        if isExpanded then
            isExpanded = false
            local baseH = getPanelBaseH()
            applyPanelSize(baseH, true)
            task.delay(0.28, function() expandZone.Visible = false end)
        end
        clearBaseZone()
        _TweenService:Create(shadow, TWEEN_OUT, {BackgroundTransparency = 1}):Play()
        _TweenService:Create(panel, TWEEN_OUT, {BackgroundTransparency = 1}):Play()
        _TweenService:Create(stroke, TWEEN_OUT, {Transparency = 1}):Play()
        task.delay(0.35, function()
            panel.Visible = false
            shadow.Visible = false
            warningLabel.Visible = false
            execBtn.Visible = false
            idButton.Visible = false
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

    local function addToHistory(animId, ownerName, ownerDisplay)
        if not animId or animId == "" then return end
        if #stolenHistory > 0 and stolenHistory[#stolenHistory].animId == animId then return end
        local clipboard_label = L("portapapeles", "clipboard")
        table.insert(stolenHistory, {
            animId = animId,
            ownerName = ownerName or clipboard_label,
            displayName = ownerDisplay or ownerName or clipboard_label,
        })
        if #stolenHistory > MAX_HISTORY then table.remove(stolenHistory, 1) end
    end

    local function rebuildHistoryUI()
        for _, child in ipairs(historyFrame:GetChildren()) do
            if child:IsA("GuiObject") then child:Destroy() end
        end
        local totalH = 0
        for i = #stolenHistory, 1, -1 do
            local entry = stolenHistory[i]
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, 0, 0, 50)
            row.BackgroundColor3 = AFO_PURPLE_DIM
            row.BackgroundTransparency = 0.35
            row.BorderSizePixel = 0
            row.LayoutOrder = #stolenHistory - i
            row.ZIndex = 5
            row.Parent = historyFrame
            do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,6); c.Parent = row end
            local nameLabel = Instance.new("TextLabel")
            nameLabel.Size = UDim2.new(1, -8, 0, 18)
            nameLabel.Position = UDim2.new(0, 6, 0, 3)
            nameLabel.BackgroundTransparency = 1
            nameLabel.TextColor3 = AFO_TEXT
            nameLabel.Text = L("De: ", "From: ") .. entry.displayName
            nameLabel.Font = Enum.Font.GothamSemibold
            nameLabel.TextScaled = true
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.ZIndex = 6
            nameLabel.Parent = row
            local idShort = entry.animId:match("%d+") or entry.animId
            local copyBtn = Instance.new("TextButton")
            copyBtn.Size = UDim2.new(1, -8, 0, 22)
            copyBtn.Position = UDim2.new(0, 4, 0, 23)
            copyBtn.BackgroundColor3 = AFO_BLACK
            copyBtn.BackgroundTransparency = 0.2
            copyBtn.TextColor3 = AFO_ACCENT
            copyBtn.Text = "📋 " .. idShort
            copyBtn.Font = Enum.Font.Code
            copyBtn.TextScaled = true
            copyBtn.BorderSizePixel = 0
            copyBtn.ZIndex = 6
            copyBtn.Parent = row
            do local c2 = Instance.new("UICorner"); c2.CornerRadius = UDim.new(0,4); c2.Parent = copyBtn end
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
            totalH = totalH + 54
        end
        historyFrame.CanvasSize = UDim2.new(0, 0, 0, totalH)
    end

    local function openHistoryPanel()
        if isExpanded or not panel.Visible then return end
        isExpanded = true
        rebuildHistoryUI()
        local baseH = getPanelBaseH()
        local rows = math.min(#stolenHistory, MAX_HISTORY)
        local headerH = 34
        local rawHistH = rows * 54
        local vp = _camera.ViewportSize
        local maxTotal = math.floor(vp.Y - 30)
        local maxHistH = maxTotal - baseH - headerH
        local histH = math.max(math.min(rawHistH, maxHistH), 30)
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
    end

    local function unlockAnimations()
        if animatorConn then animatorConn:Disconnect(); animatorConn = nil end
    end

    local function lockAnimations(allowedId)
        unlockAnimations()
        animatorConn = animator.AnimationPlayed:Connect(function(track)
            if track.Animation and track.Animation.AnimationId ~= allowedId then track:Stop(0) end
        end)
        _animatorConn = animatorConn
    end

    local function stopAllTracks()
        if not animator then return end
        for _, t in ipairs(animator:GetPlayingAnimationTracks()) do t:Stop(0) end
    end

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
        local char = _lplr.Character
        local excluded = {}
        if char then
            table.insert(excluded, char)
            for _, d in ipairs(char:GetDescendants()) do table.insert(excluded, d) end
        end
        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude
        raycastParams.FilterDescendantsInstances = excluded
        local origin = _camera.CFrame.Position
        local look = _camera.CFrame.LookVector
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
        local vp = _camera.ViewportSize
        local cx, cy = vp.X / 2, vp.Y / 2
        local bestDist2D, bestByScreen = math.huge, nil
        for _, p in ipairs(_Players:GetPlayers()) do
            if p == _lplr then continue end
            local pchar = p.Character; if not pchar then continue end
            local hrp = pchar:FindFirstChild("HumanoidRootPart"); if not hrp then continue end
            local myHRP = char and char:FindFirstChild("HumanoidRootPart")
            if myHRP and (hrp.Position - myHRP.Position).Magnitude > MAX_STEAL_DIST then continue end
            local screenPos, onScreen = _camera:WorldToScreenPoint(hrp.Position)
            if not onScreen then continue end
            local d2 = (screenPos.X - cx)^2 + (screenPos.Y - cy)^2
            if d2 < 200*200 and d2 < bestDist2D then bestDist2D = d2; bestByScreen = p end
        end
        return bestByScreen
    end

    local function actualizarPanelModoT(player)
        if not isStealerActive then return end
        if warningLabel.Visible then return end
        currentAimedPlayer = player
        if player then
            local animId = stealFromTarget(player)
            stoledAnimId = animId
            stolenAnimOwner = player
            stolenAnimSource = "player"
            local displayName = player.DisplayName ~= "" and player.DisplayName or player.Name
            if animId then
                infoLabel.Text = L("Robada de ", "Stolen from ") .. displayName .. " · " .. (animId:match("%d+") or animId)
            else
                infoLabel.Text = L("Sin animación en ", "No animation on ") .. displayName
            end
        else
            infoLabel.Text = L("Sin objetivo en rango", "No target in range")
        end
    end

    local function ejecutarRobada()
        if not animator then return end
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
        addToHistory(stoledAnimId, sourceName, sourceDisplay)
        isStolenPlaying = true
        stopAllTracks()
        local animObj = Instance.new("Animation")
        animObj.AnimationId = stoledAnimId
        stolenTrack = animator:LoadAnimation(animObj)
        stolenTrack.Priority = Enum.AnimationPriority.Action4
        stolenTrack.Looped = true
        stolenTrack:Play(0.1, 1, 1)
        _stolenTrack = stolenTrack
        task.wait()
        lockAnimations(stoledAnimId)
        resetBorder()
        showPanelModoY(stoledAnimId, sourceDisplay)
    end

    local function activarStealer()
        if not animator then return end
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

    local function openInputPopup()
        isInputOpen = true
        inputBox.Text = ""
        inputPopup.Visible = true
        inputBox:CaptureFocus()
    end

    _miscRenderConn = _RunService.RenderStepped:Connect(function()
        if not _lplr.Character or not _lplr.Character.Parent then return end
        if isStealerActive then
            local aimed = getTargetInView()
            if aimed ~= lastCirclePlayer then
                lastCirclePlayer = aimed
                if aimed then showCircleIndicator(aimed) else clearCircleIndicator() end
                actualizarPanelModoT(aimed)
            end
        else
            if lastCirclePlayer ~= nil then
                lastCirclePlayer = nil
                clearCircleIndicator()
            end
        end
    end)
    miscRenderConn = _miscRenderConn

    _miscInputBegin = _UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        local stealKey   = _Keys.EmoteSteal
        local executeKey = _Keys.EmoteExecute
        local expandKey  = _Keys.EmoteExpand
        if input.KeyCode == stealKey then
            tHeld = true
            if yHeld then
                if not tyConsumed then
                    tyConsumed = true
                    if isInputOpen then closeInputPopup() else openInputPopup() end
                end
                return
            end
            if isInputOpen then closeInputPopup(); return end
            if isStolenPlaying then ejecutarRobada(); return end
            isStealerActive = not isStealerActive
            if isStealerActive then activarStealer() else cancelarStealer() end
            return
        end
        if input.KeyCode == executeKey then
            yHeld = true
            if tHeld then
                if not tyConsumed then
                    tyConsumed = true
                    if isInputOpen then closeInputPopup() else openInputPopup() end
                end
                return
            end
            if uHeld then
                if not expandConsumed then
                    expandConsumed = true
                    if isExpanded then closeHistoryPanel() else if panel.Visible then openHistoryPanel() end end
                end
                return
            end
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
        if input.KeyCode == expandKey then
            uHeld = true
            if yHeld and not expandConsumed then
                expandConsumed = true
                if isExpanded then closeHistoryPanel() else if panel.Visible then openHistoryPanel() end end
            end
            return
        end
    end)
    miscInputBegin = _miscInputBegin

    _miscInputEnd = _UserInputService.InputEnded:Connect(function(input)
        local stealKey   = _Keys.EmoteSteal
        local executeKey = _Keys.EmoteExecute
        local expandKey  = _Keys.EmoteExpand
        if input.KeyCode == stealKey then tHeld = false; tyConsumed = false end
        if input.KeyCode == executeKey then yHeld = false; tyConsumed = false; expandConsumed = false end
        if input.KeyCode == expandKey then uHeld = false; expandConsumed = false end
    end)
    miscInputEnd = _miscInputEnd

    local function iniciarMiscChar(char)
        unlockAnimations()
        stealerTrack = nil; stolenTrack = nil
        _stealerTrack = nil; _stolenTrack = nil
        stoledAnimId = nil; stolenAnimOwner = nil; stolenAnimSource = nil
        isStealerActive = false; isStolenPlaying = false
        currentAimedPlayer = nil; lastCirclePlayer = nil
        yHeld = false; uHeld = false; tHeld = false
        isExpanded = false; expandConsumed = false; tyConsumed = false; isInputOpen = false
        warningLabel.Visible = false; expandZone.Visible = false
        inputPopup.Visible = false; execBtn.Visible = false; idButton.Visible = false
        hidePanel(); resetBorder()
        local humanoid = char:WaitForChild("Humanoid")
        animator = humanoid:WaitForChild("Animator")
        _animator = animator
        task.wait(0.1)
    end

    if _lplr.Character then iniciarMiscChar(_lplr.Character) end
    _miscCharConn = _lplr.CharacterAdded:Connect(function(newChar)
        task.wait(0.5)
        iniciarMiscChar(newChar)
    end)
    miscCharConn = _miscCharConn
end

function M.Stop(preserveEnabled)
    if _miscRenderConn then pcall(function() _miscRenderConn:Disconnect() end); _miscRenderConn = nil end
    if _miscInputBegin then pcall(function() _miscInputBegin:Disconnect() end); _miscInputBegin = nil end
    if _miscInputEnd then pcall(function() _miscInputEnd:Disconnect() end); _miscInputEnd = nil end
    if _miscCharConn then pcall(function() _miscCharConn:Disconnect() end); _miscCharConn = nil end
    if _animatorConn then pcall(function() _animatorConn:Disconnect() end); _animatorConn = nil end
    if _circleAlphaThread then pcall(function() task.cancel(_circleAlphaThread) end); _circleAlphaThread = nil end
    if _pulseThread then pcall(function() task.cancel(_pulseThread) end); _pulseThread = nil end
    if _circleIndicatorConn then pcall(function() _circleIndicatorConn:Disconnect() end); _circleIndicatorConn = nil end
    if _circleIndicatorBB then pcall(function() _circleIndicatorBB:Destroy() end); _circleIndicatorBB = nil end
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
    if _screenGui then
        pcall(function() _screenGui:Destroy() end)
        _screenGui = nil
    end
end

function M.Restart()
    M.Stop(true)
    if _Keys and _lplr then
        M.Start(_Keys, _lplr, _CoreGui, _RunService, _TweenService, _camera)
    end
end

return M
