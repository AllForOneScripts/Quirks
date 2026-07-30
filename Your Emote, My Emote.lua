local miscEmoteEnabled = false
local miscEmoteScreenGui = nil
 
local stealerTrack, stolenTrack, animator, animatorConn = nil, nil, nil, nil
local stoledAnimId, stolenAnimOwner, stolenAnimSource = nil, nil, nil
local isStealerActive, isStolenPlaying = false, false
local currentAimedPlayer, lastCirclePlayer = nil, nil
local panelHideTimer, warningTimer = nil, nil
local yHeld, uHeld, tHeld = false, false, false
local expandConsumed, tyConsumed, isInputOpen = false, false, false
local circleIndicatorBB, circleIndicatorConn, circleAlphaThread, pulseThread = nil, nil, nil, nil
local miscInputBegin, miscInputEnd, miscRenderConn, miscCharConn = nil, nil, nil, nil
 
local function miscEmoteStart()
    if miscEmoteScreenGui then return end
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
@@ -21,30 +58,30 @@ local function miscEmoteStart()
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
    screenGui.Parent = CoreGui
    miscEmoteScreenGui = screenGui
 
    screenGui.Parent = _CoreGui
    _screenGui = screenGui

    local shadow = Instance.new("Frame")
    shadow.Size = UDim2.new(0, 296, 0, BASE_HEIGHT + 8)
    shadow.Position = SHADOW_POS
@@ -55,7 +92,7 @@ local function miscEmoteStart()
    shadow.Visible = false
    shadow.Parent = screenGui
    do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,15); c.Parent = shadow end
 

    local panel = Instance.new("Frame")
    panel.Size = UDim2.new(0, 288, 0, BASE_HEIGHT)
    panel.Position = PANEL_POS
@@ -67,7 +104,7 @@ local function miscEmoteStart()
    panel.ClipsDescendants = true
    panel.Parent = screenGui
    do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,13); c.Parent = panel end
 

    local grad = Instance.new("UIGradient")
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, AFO_BLACK),
@@ -76,14 +113,14 @@ local function miscEmoteStart()
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
@@ -92,7 +129,7 @@ local function miscEmoteStart()
    baseZone.BorderSizePixel = 0
    baseZone.ZIndex = 3
    baseZone.Parent = panel
 

    local infoLabel = Instance.new("TextLabel")
    infoLabel.Size = UDim2.new(1, -18, 0, 22)
    infoLabel.Position = UDim2.new(0, 9, 0, 5)
@@ -105,7 +142,7 @@ local function miscEmoteStart()
    infoLabel.TextXAlignment = Enum.TextXAlignment.Left
    infoLabel.ZIndex = 4
    infoLabel.Parent = baseZone
 

    local warningLabel = Instance.new("TextLabel")
    warningLabel.Size = UDim2.new(1, -18, 1, 0)
    warningLabel.Position = UDim2.new(0, 9, 0, 0)
@@ -120,7 +157,7 @@ local function miscEmoteStart()
    warningLabel.ZIndex = 5
    warningLabel.Visible = false
    warningLabel.Parent = baseZone
 

    local idButton = Instance.new("TextButton")
    idButton.Size = UDim2.new(1, -18, 0, 20)
    idButton.Position = UDim2.new(0, 9, 0, 28)
@@ -136,7 +173,7 @@ local function miscEmoteStart()
    idButton.Visible = false
    idButton.Parent = baseZone
    do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,5); c.Parent = idButton end
 

    local execBtn = Instance.new("TextButton")
    execBtn.Size = UDim2.new(1, -18, 0, 26)
    execBtn.Position = UDim2.new(0, 9, 0, 28)
@@ -160,7 +197,7 @@ local function miscEmoteStart()
        g2.Rotation = 0
        g2.Parent = execBtn
    end
 

    local expandZone = Instance.new("Frame")
    expandZone.AnchorPoint = Vector2.new(0, 1)
    expandZone.Size = UDim2.new(1, 0, 0, 0)
@@ -171,7 +208,7 @@ local function miscEmoteStart()
    expandZone.ClipsDescendants = true
    expandZone.Visible = false
    expandZone.Parent = panel
 

    local histTitle = Instance.new("TextLabel")
    histTitle.Size = UDim2.new(1, -18, 0, 22)
    histTitle.Position = UDim2.new(0, 9, 0, 6)
@@ -183,7 +220,7 @@ local function miscEmoteStart()
    histTitle.Text = L("📎 Animaciones robadas ["..kn(emoteExecuteKey).."+"..kn(emoteExpandKey).." para cerrar]", "📎 Stolen animations ["..kn(emoteExecuteKey).."+"..kn(emoteExpandKey).." to close]")
    histTitle.ZIndex = 5
    histTitle.Parent = expandZone
 

    local histSep = Instance.new("Frame")
    histSep.Size = UDim2.new(1, -18, 0, 1)
    histSep.Position = UDim2.new(0, 9, 0, 30)
@@ -192,7 +229,7 @@ local function miscEmoteStart()
    histSep.BorderSizePixel = 0
    histSep.ZIndex = 5
    histSep.Parent = expandZone
 

    local historyFrame = Instance.new("ScrollingFrame")
    historyFrame.Size = UDim2.new(1, -18, 1, -36)
    historyFrame.Position = UDim2.new(0, 9, 0, 34)
@@ -204,12 +241,12 @@ local function miscEmoteStart()
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
@@ -221,13 +258,13 @@ local function miscEmoteStart()
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
@@ -239,7 +276,7 @@ local function miscEmoteStart()
    inputTitle.Text = L("🔑 Cargar ID [Enter/clic confirmar · "..kn(emoteStealKey).."+"..kn(emoteExecuteKey).." cerrar]", "🔑 Load ID [Enter/click confirm · "..kn(emoteStealKey).."+"..kn(emoteExecuteKey).." close]")
    inputTitle.ZIndex = 21
    inputTitle.Parent = inputPopup
 

    local inputBox = Instance.new("TextBox")
    inputBox.Size = UDim2.new(1, -16, 0, 30)
    inputBox.Position = UDim2.new(0, 8, 0, 34)
@@ -260,7 +297,7 @@ local function miscEmoteStart()
        local s = Instance.new("UIStroke")
        s.Color = AFO_ACCENT; s.Thickness = 1.5; s.Transparency = 0.4; s.Parent = inputBox
    end
 

    local inputConfirmBtn = Instance.new("TextButton")
    inputConfirmBtn.Size = UDim2.new(1, -16, 0, 26)
    inputConfirmBtn.Position = UDim2.new(0, 8, 0, 70)
@@ -274,48 +311,49 @@ local function miscEmoteStart()
    inputConfirmBtn.ZIndex = 21
    inputConfirmBtn.Parent = inputPopup
    do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,7); c.Parent = inputConfirmBtn end
 
    local TWEEN_IN  = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local TWEEN_OUT = TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

    local TWEEN_IN     = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local TWEEN_OUT    = TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    local EXPAND_TWEEN = TweenInfo.new(0.32, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
 
    local stolenHistory = {}
    stealerTrack    = nil
    isStealerActive = false
    stoledAnimId    = nil
    stolenAnimOwner = nil
    stolenAnimSource = nil
    stolenTrack     = nil
    isStolenPlaying = false
    currentAimedPlayer = nil
    animator = nil
    if animatorConn then animatorConn:Disconnect(); animatorConn = nil end
    panelHideTimer = nil
    warningTimer   = nil
    local isExpanded = false
    yHeld = false; uHeld = false; tHeld = false
    expandConsumed = false; tyConsumed = false; isInputOpen = false
    lastCirclePlayer = nil
    circleIndicatorBB = nil; circleIndicatorConn = nil
    circleAlphaThread = nil; pulseThread = nil
    miscInputBegin = nil; miscInputEnd = nil
    miscRenderConn = nil; miscCharConn = nil
 

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
            TweenService:Create(panel, EXPAND_TWEEN, {Size = ps}):Play()
            TweenService:Create(shadow, EXPAND_TWEEN, {Size = ss}):Play()
            _TweenService:Create(panel, EXPAND_TWEEN, {Size = ps}):Play()
            _TweenService:Create(shadow, EXPAND_TWEEN, {Size = ss}):Play()
        else
            panel.Size = ps; shadow.Size = ss
        end
    end
 

    local function clearBaseZone()
        infoLabel.TextTransparency = 1
        warningLabel.TextTransparency = 1
@@ -327,39 +365,40 @@ local function miscEmoteStart()
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
        TweenService:Create(stroke, TweenInfo.new(0.3), {Color = AFO_PURPLE, Thickness = 2, Transparency = 0}):Play()
        _TweenService:Create(stroke, TweenInfo.new(0.3), {Color = AFO_PURPLE, Thickness = 2, Transparency = 0}):Play()
    end
 

    local function startPulse()
        stopPulse()
        pulseThread = task.spawn(function()
            while true do
                TweenService:Create(stroke, TweenInfo.new(0.55, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Thickness = 3.5, Transparency = 0, Color = AFO_ACCENT}):Play()
                _TweenService:Create(stroke, TweenInfo.new(0.55, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Thickness = 3.5, Transparency = 0, Color = AFO_ACCENT}):Play()
                task.wait(0.55)
                TweenService:Create(stroke, TweenInfo.new(0.55, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Thickness = 1.2, Transparency = 0.35, Color = AFO_PURPLE}):Play()
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
@@ -391,16 +430,19 @@ local function miscEmoteStart()
        circleIndicatorBB = bb
        circleAlphaThread = task.spawn(function()
            while bb and bb.Parent do
                TweenService:Create(ringStroke, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Thickness = 5, Transparency = 0}):Play()
                _TweenService:Create(ringStroke, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Thickness = 5, Transparency = 0}):Play()
                task.wait(0.6)
                if not bb.Parent then break end
                TweenService:Create(ringStroke, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Thickness = 2, Transparency = 0.45}):Play()
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
@@ -411,9 +453,9 @@ local function miscEmoteStart()
            task.delay(0.28, function() expandZone.Visible = false end)
        end
        clearBaseZone()
        TweenService:Create(shadow, TWEEN_OUT, {BackgroundTransparency = 1}):Play()
        TweenService:Create(panel, TWEEN_OUT, {BackgroundTransparency = 1}):Play()
        TweenService:Create(stroke, TWEEN_OUT, {Transparency = 1}):Play()
        _TweenService:Create(shadow, TWEEN_OUT, {BackgroundTransparency = 1}):Play()
        _TweenService:Create(panel, TWEEN_OUT, {BackgroundTransparency = 1}):Play()
        _TweenService:Create(stroke, TWEEN_OUT, {Transparency = 1}):Play()
        task.delay(0.35, function()
            panel.Visible = false
            shadow.Visible = false
@@ -422,7 +464,7 @@ local function miscEmoteStart()
            idButton.Visible = false
        end)
    end
 

    local function showWarning(label)
        cancelHideTimer()
        if warningTimer then task.cancel(warningTimer); warningTimer = nil end
@@ -433,25 +475,25 @@ local function miscEmoteStart()
        shadow.Visible = true
        baseZone.Size = UDim2.new(1, 0, 0, BASE_HEIGHT)
        if not isExpanded then applyPanelSize(BASE_HEIGHT, false) end
        TweenService:Create(shadow, TWEEN_IN, {BackgroundTransparency = 0.58}):Play()
        TweenService:Create(panel, TWEEN_IN, {BackgroundTransparency = 0.08}):Play()
        TweenService:Create(stroke, TWEEN_IN, {Transparency = 0.3}):Play()
        TweenService:Create(warningLabel, TWEEN_IN, {TextTransparency = 0}):Play()
        _TweenService:Create(shadow, TWEEN_IN, {BackgroundTransparency = 0.58}):Play()
        _TweenService:Create(panel, TWEEN_IN, {BackgroundTransparency = 0.08}):Play()
        _TweenService:Create(stroke, TWEEN_IN, {Transparency = 0.3}):Play()
        _TweenService:Create(warningLabel, TWEEN_IN, {TextTransparency = 0}):Play()
        warningTimer = task.delay(2, function()
            warningTimer = nil
            TweenService:Create(warningLabel, TWEEN_OUT, {TextTransparency = 1}):Play()
            _TweenService:Create(warningLabel, TWEEN_OUT, {TextTransparency = 1}):Play()
            task.delay(0.32, function()
                warningLabel.Visible = false
                if not isStealerActive and not isStolenPlaying then
                    TweenService:Create(shadow, TWEEN_OUT, {BackgroundTransparency = 1}):Play()
                    TweenService:Create(panel, TWEEN_OUT, {BackgroundTransparency = 1}):Play()
                    TweenService:Create(stroke, TWEEN_OUT, {Transparency = 1}):Play()
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
@@ -466,13 +508,13 @@ local function miscEmoteStart()
        panel.Visible = true
        shadow.Visible = true
        if not isExpanded then applyPanelSize(BASE_HEIGHT, false) end
        TweenService:Create(shadow, TWEEN_IN, {BackgroundTransparency = 0.52}):Play()
        TweenService:Create(panel, TWEEN_IN, {BackgroundTransparency = 0.08}):Play()
        TweenService:Create(stroke, TWEEN_IN, {Transparency = 0}):Play()
        TweenService:Create(infoLabel, TWEEN_IN, {TextTransparency = 0}):Play()
        TweenService:Create(execBtn, TWEEN_IN, {BackgroundTransparency = 0, TextTransparency = 0}):Play()
        _TweenService:Create(shadow, TWEEN_IN, {BackgroundTransparency = 0.52}):Play()
        _TweenService:Create(panel, TWEEN_IN, {BackgroundTransparency = 0.08}):Play()
        _TweenService:Create(stroke, TWEEN_IN, {Transparency = 0}):Play()
        _TweenService:Create(infoLabel, TWEEN_IN, {TextTransparency = 0}):Play()
        _TweenService:Create(execBtn, TWEEN_IN, {BackgroundTransparency = 0, TextTransparency = 0}):Play()
    end
 

    local function showPanelModoY(animId, sourceDisplay)
        cancelHideTimer()
        clearBaseZone()
@@ -489,13 +531,13 @@ local function miscEmoteStart()
        panel.Visible = true
        shadow.Visible = true
        if not isExpanded then applyPanelSize(PLAYING_HEIGHT, true) end
        TweenService:Create(shadow, TWEEN_IN, {BackgroundTransparency = 0.52}):Play()
        TweenService:Create(panel, TWEEN_IN, {BackgroundTransparency = 0.08}):Play()
        TweenService:Create(stroke, TWEEN_IN, {Transparency = 0}):Play()
        TweenService:Create(infoLabel, TWEEN_IN, {TextTransparency = 0}):Play()
        TweenService:Create(idButton, TWEEN_IN, {TextTransparency = 0, BackgroundTransparency = 0.4}):Play()
        _TweenService:Create(shadow, TWEEN_IN, {BackgroundTransparency = 0.52}):Play()
        _TweenService:Create(panel, TWEEN_IN, {BackgroundTransparency = 0.08}):Play()
        _TweenService:Create(stroke, TWEEN_IN, {Transparency = 0}):Play()
        _TweenService:Create(infoLabel, TWEEN_IN, {TextTransparency = 0}):Play()
        _TweenService:Create(idButton, TWEEN_IN, {TextTransparency = 0, BackgroundTransparency = 0.4}):Play()
    end
 

    local function addToHistory(animId, ownerName, ownerDisplay)
        if not animId or animId == "" then return end
        if #stolenHistory > 0 and stolenHistory[#stolenHistory].animId == animId then return end
@@ -507,7 +549,7 @@ local function miscEmoteStart()
        })
        if #stolenHistory > MAX_HISTORY then table.remove(stolenHistory, 1) end
    end
 

    local function rebuildHistoryUI()
        for _, child in ipairs(historyFrame:GetChildren()) do
            if child:IsA("GuiObject") then child:Destroy() end
@@ -567,7 +609,7 @@ local function miscEmoteStart()
        end
        historyFrame.CanvasSize = UDim2.new(0, 0, 0, totalH)
    end
 

    local function openHistoryPanel()
        if isExpanded or not panel.Visible then return end
        isExpanded = true
@@ -576,7 +618,7 @@ local function miscEmoteStart()
        local rows = math.min(#stolenHistory, MAX_HISTORY)
        local headerH = 34
        local rawHistH = rows * 54
        local vp = camera.ViewportSize
        local vp = _camera.ViewportSize
        local maxTotal = math.floor(vp.Y - 30)
        local maxHistH = maxTotal - baseH - headerH
        local histH = math.max(math.min(rawHistH, maxHistH), 30)
@@ -587,31 +629,32 @@ local function miscEmoteStart()
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
@@ -629,7 +672,7 @@ local function miscEmoteStart()
        end
        return false
    end
 

    local function stealFromTarget(player)
        if not player or not player.Character then return nil end
        local char = player.Character
@@ -647,9 +690,9 @@ local function miscEmoteStart()
        end
        return nil
    end
 

    local function getTargetInView()
        local char = lplr.Character
        local char = _lplr.Character
        local excluded = {}
        if char then
            table.insert(excluded, char)
@@ -658,44 +701,44 @@ local function miscEmoteStart()
        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude
        raycastParams.FilterDescendantsInstances = excluded
        local origin = camera.CFrame.Position
        local look = camera.CFrame.LookVector
        local origin = _camera.CFrame.Position
        local look = _camera.CFrame.LookVector
        local result = workspace:Raycast(origin, look * MAX_STEAL_DIST, raycastParams)
        if result and result.Instance then
            local model = result.Instance:FindFirstAncestorOfClass("Model")
            if model then
                local player = Players:GetPlayerFromCharacter(model)
                if player and player ~= lplr then return player end
                local p = _Players:GetPlayerFromCharacter(model)
                if p and p ~= _lplr then return p end
            end
        end
        local bestDot, bestPlayer = 0.90, nil
        for _, player in ipairs(Players:GetPlayers()) do
            if player == lplr then continue end
            local pchar = player.Character; if not pchar then continue end
        for _, p in ipairs(_Players:GetPlayers()) do
            if p == _lplr then continue end
            local pchar = p.Character; if not pchar then continue end
            local hrp = pchar:FindFirstChild("HumanoidRootPart"); if not hrp then continue end
            local myHRP = char and char:FindFirstChild("HumanoidRootPart")
            if myHRP and (hrp.Position - myHRP.Position).Magnitude > MAX_STEAL_DIST then continue end
            local dot = look:Dot((hrp.Position - origin).Unit)
            if dot > bestDot then bestDot = dot; bestPlayer = player end
            if dot > bestDot then bestDot = dot; bestPlayer = p end
        end
        if bestPlayer then return bestPlayer end
        local vp = camera.ViewportSize
        local vp = _camera.ViewportSize
        local cx, cy = vp.X / 2, vp.Y / 2
        local bestDist2D, bestByScreen = math.huge, nil
        for _, player in ipairs(Players:GetPlayers()) do
            if player == lplr then continue end
            local pchar = player.Character; if not pchar then continue end
        for _, p in ipairs(_Players:GetPlayers()) do
            if p == _lplr then continue end
            local pchar = p.Character; if not pchar then continue end
            local hrp = pchar:FindFirstChild("HumanoidRootPart"); if not hrp then continue end
            local myHRP = char and char:FindFirstChild("HumanoidRootPart")
            if myHRP and (hrp.Position - myHRP.Position).Magnitude > MAX_STEAL_DIST then continue end
            local screenPos, onScreen = camera:WorldToScreenPoint(hrp.Position)
            local screenPos, onScreen = _camera:WorldToScreenPoint(hrp.Position)
            if not onScreen then continue end
            local d2 = (screenPos.X - cx)^2 + (screenPos.Y - cy)^2
            if d2 < 200*200 and d2 < bestDist2D then bestDist2D = d2; bestByScreen = player end
            if d2 < 200*200 and d2 < bestDist2D then bestDist2D = d2; bestByScreen = p end
        end
        return bestByScreen
    end
 

    local function actualizarPanelModoT(player)
        if not isStealerActive then return end
        if warningLabel.Visible then return end
@@ -715,7 +758,7 @@ local function miscEmoteStart()
            infoLabel.Text = L("Sin objetivo en rango", "No target in range")
        end
    end
 

    local function ejecutarRobada()
        if not animator then return end
        if isStolenPlaying then
@@ -760,12 +803,13 @@ local function miscEmoteStart()
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
@@ -795,6 +839,7 @@ local function miscEmoteStart()
        stealerTrack.Looped = false
        lockAnimations(STEALER_ANIM_ID)
        stealerTrack:Play(0.1, 1, 1)
        _stealerTrack = stealerTrack
        local activeStealerTrack = stealerTrack
        task.spawn(function()
            local waited = 0
@@ -820,7 +865,7 @@ local function miscEmoteStart()
        startPulse()
        if firstTarget then showCircleIndicator(firstTarget) end
    end
 

    local function cancelarStealer()
        unlockAnimations()
        if stealerTrack then
@@ -832,7 +877,7 @@ local function miscEmoteStart()
        resetBorder()
        hidePanel()
    end
 

    idButton.MouseButton1Click:Connect(function()
        if not stoledAnimId then return end
        pcall(function() setclipboard(stoledAnimId) end)
@@ -843,15 +888,15 @@ local function miscEmoteStart()
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
@@ -873,21 +918,21 @@ local function miscEmoteStart()
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
 
    miscRenderConn = RunService.RenderStepped:Connect(function()
        if not lplr.Character or not lplr.Character.Parent then return end

    _miscRenderConn = _RunService.RenderStepped:Connect(function()
        if not _lplr.Character or not _lplr.Character.Parent then return end
        if isStealerActive then
            local aimed = getTargetInView()
            if aimed ~= lastCirclePlayer then
@@ -902,10 +947,14 @@ local function miscEmoteStart()
            end
        end
    end)
 
    miscInputBegin = UserInputService.InputBegan:Connect(function(input, gameProcessed)
    miscRenderConn = _miscRenderConn

    _miscInputBegin = _UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == emoteStealKey then
        local stealKey   = _Keys.EmoteSteal
        local executeKey = _Keys.EmoteExecute
        local expandKey  = _Keys.EmoteExpand
        if input.KeyCode == stealKey then
            tHeld = true
            if yHeld then
                if not tyConsumed then
@@ -920,7 +969,7 @@ local function miscEmoteStart()
            if isStealerActive then activarStealer() else cancelarStealer() end
            return
        end
        if input.KeyCode == emoteExecuteKey then
        if input.KeyCode == executeKey then
            yHeld = true
            if tHeld then
                if not tyConsumed then
@@ -952,7 +1001,7 @@ local function miscEmoteStart()
            ejecutarRobada()
            return
        end
        if input.KeyCode == emoteExpandKey then
        if input.KeyCode == expandKey then
            uHeld = true
            if yHeld and not expandConsumed then
                expandConsumed = true
@@ -961,16 +1010,22 @@ local function miscEmoteStart()
            return
        end
    end)
 
    miscInputEnd = UserInputService.InputEnded:Connect(function(input, _)
        if input.KeyCode == emoteStealKey then tHeld = false; tyConsumed = false end
        if input.KeyCode == emoteExecuteKey then yHeld = false; tyConsumed = false; expandConsumed = false end
        if input.KeyCode == emoteExpandKey then uHeld = false; expandConsumed = false end
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
@@ -981,46 +1036,49 @@ local function miscEmoteStart()
        hidePanel(); resetBorder()
        local humanoid = char:WaitForChild("Humanoid")
        animator = humanoid:WaitForChild("Animator")
        _animator = animator
        task.wait(0.1)
    end
 
    if lplr.Character then iniciarMiscChar(lplr.Character) end
    miscCharConn = lplr.CharacterAdded:Connect(function(newChar)

    if _lplr.Character then iniciarMiscChar(_lplr.Character) end
    _miscCharConn = _lplr.CharacterAdded:Connect(function(newChar)
        task.wait(0.5)
        iniciarMiscChar(newChar)
    end)
    miscCharConn = _miscCharConn
end
 
local function miscEmoteStop(preserveEnabled)
    if not preserveEnabled then miscEmoteEnabled = false end
    isStealerActive = false; isStolenPlaying = false
    yHeld = false; uHeld = false; tHeld = false
    expandConsumed = false; tyConsumed = false; isInputOpen = false
    currentAimedPlayer = nil; lastCirclePlayer = nil
    if panelHideTimer then pcall(function() task.cancel(panelHideTimer) end); panelHideTimer = nil end
    if warningTimer then pcall(function() task.cancel(warningTimer) end); warningTimer = nil end
    if circleAlphaThread then pcall(function() task.cancel(circleAlphaThread) end); circleAlphaThread = nil end
    if pulseThread then pcall(function() task.cancel(pulseThread) end); pulseThread = nil end
    if miscRenderConn then pcall(function() miscRenderConn:Disconnect() end); miscRenderConn = nil end
    if miscInputBegin then pcall(function() miscInputBegin:Disconnect() end); miscInputBegin = nil end
    if miscInputEnd then pcall(function() miscInputEnd:Disconnect() end); miscInputEnd = nil end
    if miscCharConn then pcall(function() miscCharConn:Disconnect() end); miscCharConn = nil end
    if animatorConn then pcall(function() animatorConn:Disconnect() end); animatorConn = nil end

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
        if stealerTrack then stealerTrack:AdjustSpeed(1); stealerTrack:Stop(0) end
        if stolenTrack then stolenTrack:AdjustSpeed(1); stolenTrack:Stop(0) end
        if animator then
            for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
        if _stealerTrack then _stealerTrack:AdjustSpeed(1); _stealerTrack:Stop(0) end
        if _stolenTrack then _stolenTrack:AdjustSpeed(1); _stolenTrack:Stop(0) end
        if _animator then
            for _, track in ipairs(_animator:GetPlayingAnimationTracks()) do
                pcall(function() track:AdjustSpeed(1); track:Stop(0) end)
            end
        end
    end)
    stealerTrack = nil; stolenTrack = nil; animator = nil
    stoledAnimId = nil; stolenAnimOwner = nil; stolenAnimSource = nil
    if circleIndicatorConn then pcall(function() circleIndicatorConn:Disconnect() end); circleIndicatorConn = nil end
    if circleIndicatorBB then pcall(function() circleIndicatorBB:Destroy() end); circleIndicatorBB = nil end
    if miscEmoteScreenGui then
        pcall(function() miscEmoteScreenGui:Destroy() end)
        miscEmoteScreenGui = nil
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
