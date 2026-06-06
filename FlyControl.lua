-- FlyControl.lua
-- Controlador principal que integra FlyAnim, FlyText y FlyLogic.
-- Expone la API esperada por el sistema de módulos.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

-- Cargar submódulos (deben estar en la misma carpeta)
local FlyAnim = require(script.Parent.FlyAnim)
local FlyText = require(script.Parent.FlyText)
local FlyLogic = require(script.Parent.FlyLogic)

-- ============================================================
-- Variables locales
-- ============================================================
local lplr = nil
local camera = nil

-- Estado de teclas para FlyAnim
local wDown = false
local sDown = false
local aDown = false
local dDown = false
local spaceDown = false
local ctrlDown = false

-- GUI y estado
local gui = nil
local expanded = false
local pulseConn = nil
local updateModeCallback = nil
local updateLockLabelsCallback = nil
local movementDebounceToken = 0

-- ============================================================
-- Funciones auxiliares
-- ============================================================
local function isTyping()
    return UserInputService:GetFocusedTextBox() ~= nil
end

local function updateMovementState()
    if FlyAnim.updateMovement then
        FlyAnim.updateMovement(wDown, sDown, aDown, dDown, spaceDown, FlyLogic.getMode() == "megaup")
    end
end

local function debouncedUpdateMovement()
    movementDebounceToken = movementDebounceToken + 1
    local token = movementDebounceToken
    task.delay(0.08, function()
        if movementDebounceToken == token then
            updateMovementState()
        end
    end)
end

-- ============================================================
-- Construcción de la GUI (usando FlyText)
-- ============================================================
local function destroyGUI()
    if pulseConn then
        pcall(function() task.cancel(pulseConn) end)
        pulseConn = nil
    end
    if gui then
        pcall(function() gui:Destroy() end)
        gui = nil
    end
end

local function buildGUI()
    destroyGUI()

    local FT = FlyText  -- atajo

    local C_PURPLE = Color3.fromRGB(110,30,180)
    local C_DIM  = Color3.fromRGB(40,6,72)
    local C_BLACK  = Color3.fromRGB(6,4,12)
    local C_ACCENT = Color3.fromRGB(160,60,255)
    local C_TEXT   = Color3.fromRGB(220,190,255)
    local C_GREEN = Color3.fromRGB(80,255,150)
    local C_YELLOW = Color3.fromRGB(255,220,60)
    local C_RED   = Color3.fromRGB(255,80,80)
    local C_CYAN   = Color3.fromRGB(80,200,255)

    local W = 280
    local H_MINI = 48
    local DOT_SIZE = 10
    local CONTENT_H = 8 + 30 + 6 + 82 + 6 + 104 + 8
    local H_FULL = H_MINI + CONTENT_H
    local TW = TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

    local sg = Instance.new("ScreenGui")
    sg.Name = "AFO_FlyHUD"
    sg.ResetOnSpawn = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.IgnoreGuiInset = true
    sg.Parent = CoreGui
    gui = sg

    local root = Instance.new("Frame", sg)
    root.Size = UDim2.new(0, W, 0, H_FULL)
    root.Position = UDim2.new(0.5, -W/2, 0, 6)
    root.BackgroundTransparency = 1

    local panel = Instance.new("Frame", root)
    panel.Size = UDim2.new(1, 0, 0, H_MINI)
    panel.BackgroundColor3 = C_BLACK
    panel.BackgroundTransparency = 0.06
    panel.BorderSizePixel = 0
    Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 12)
    local stroke = Instance.new("UIStroke", panel)
    stroke.Color = C_PURPLE
    stroke.Thickness = 1.2
    stroke.Transparency = 0.75

    local topBar = Instance.new("Frame", panel)
    topBar.Size = UDim2.new(1, 0, 0, H_MINI)
    topBar.BackgroundTransparency = 1

    local iconLbl = Instance.new("TextLabel", topBar)
    iconLbl.Size = UDim2.new(0, 28, 1, 0)
    iconLbl.Position = UDim2.new(0, 8, 0, 0)
    iconLbl.BackgroundTransparency = 1
    iconLbl.Font = Enum.Font.GothamBold
    iconLbl.TextSize = 14
    iconLbl.TextColor3 = C_ACCENT
    iconLbl.Text = "🚀"
    iconLbl.TextXAlignment = Enum.TextXAlignment.Center

    local titleLbl = Instance.new("TextLabel", topBar)
    titleLbl.Size = UDim2.new(0, 75, 1, 0)
    titleLbl.Position = UDim2.new(0, 34, 0, 0)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextSize = 12
    titleLbl.TextColor3 = C_TEXT
    titleLbl.Text = FT.get("fly_title") .. " [" .. FlyLogic.getFlyKey().Name .. "]"
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left

    local sep = Instance.new("Frame", topBar)
    sep.Size = UDim2.new(0, 1, 0, 22)
    sep.Position = UDim2.new(0, 113, 0.5, -11)
    sep.BackgroundColor3 = C_PURPLE
    sep.BackgroundTransparency = 0.4

    local modeLbl = Instance.new("TextLabel", topBar)
    modeLbl.Size = UDim2.new(1, -134, 1, 0)
    modeLbl.Position = UDim2.new(0, 119, 0, 0)
    modeLbl.BackgroundTransparency = 1
    modeLbl.Font = Enum.Font.GothamBold
    modeLbl.TextSize = 12
    modeLbl.TextColor3 = C_GREEN
    modeLbl.Text = FT.getModeText("normal", 1)
    modeLbl.TextXAlignment = Enum.TextXAlignment.Center

    local dotBtn = Instance.new("TextButton", topBar)
    dotBtn.Size = UDim2.new(0, DOT_SIZE+10, 1, 0)
    dotBtn.Position = UDim2.new(1, -(DOT_SIZE+14), 0, 0)
    dotBtn.BackgroundTransparency = 1
    dotBtn.Text = ""

    local dot = Instance.new("Frame", dotBtn)
    dot.Size = UDim2.new(0, DOT_SIZE, 0, DOT_SIZE)
    dot.Position = UDim2.new(0.5, -DOT_SIZE/2, 0.5, -DOT_SIZE/2)
    dot.BackgroundColor3 = C_ACCENT
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

    local expandZone = Instance.new("Frame", panel)
    expandZone.Size = UDim2.new(1, -16, 0, CONTENT_H)
    expandZone.Position = UDim2.new(0, 8, 0, H_MINI)
    expandZone.BackgroundColor3 = C_DIM
    expandZone.BackgroundTransparency = 0.3
    expandZone.BorderSizePixel = 0
    expandZone.Visible = false
    Instance.new("UICorner", expandZone).CornerRadius = UDim.new(0, 8)
    local exStroke = Instance.new("UIStroke", expandZone)
    exStroke.Color = C_PURPLE
    exStroke.Thickness = 1
    exStroke.Transparency = 0.55

    local layout = Instance.new("UIListLayout", expandZone)
    layout.Padding = UDim.new(0, 6)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    local topSpacer = Instance.new("Frame")
    topSpacer.Size = UDim2.new(1, 0, 0, 5)
    topSpacer.BackgroundTransparency = 1
    topSpacer.Parent = expandZone

    local function makeSection(h)
        local f = Instance.new("Frame")
        f.Size = UDim2.new(1, -20, 0, h)
        f.BackgroundColor3 = Color3.fromRGB(30,10,50)
        f.BackgroundTransparency = 0.3
        Instance.new("UICorner", f).CornerRadius = UDim.new(0, 6)
        local s = Instance.new("UIStroke", f)
        s.Color = C_ACCENT
        s.Thickness = 1
        s.Transparency = 0.6
        return f
    end

    -- Sección Lock
    local lockSec = makeSection(30)
    lockSec.Parent = expandZone
    local lockIconImg = Instance.new("TextLabel", lockSec)
    lockIconImg.Size = UDim2.new(0, 24, 0, 24)
    lockIconImg.Position = UDim2.new(0, 6, 0.5, -12)
    lockIconImg.BackgroundTransparency = 1
    lockIconImg.Font = Enum.Font.GothamBold
    lockIconImg.TextSize = 16
    lockIconImg.TextColor3 = Color3.fromRGB(255,220,80)
    lockIconImg.Text = "🎯"
    local lockLabel = Instance.new("TextLabel", lockSec)
    lockLabel.Size = UDim2.new(0, 80, 1, 0)
    lockLabel.Position = UDim2.new(0, 34, 0, 0)
    lockLabel.BackgroundTransparency = 1
    lockLabel.Font = Enum.Font.GothamBold
    lockLabel.TextSize = 11
    lockLabel.TextColor3 = C_TEXT
    lockLabel.Text = FT.get("lock_label") .. " [" .. FlyLogic.getLockKey().Name .. "]"
    lockLabel.TextXAlignment = Enum.TextXAlignment.Left
    local lockHint = Instance.new("TextLabel", lockSec)
    lockHint.Size = UDim2.new(1, -100, 1, 0)
    lockHint.Position = UDim2.new(0, 95, 0, 0)
    lockHint.BackgroundTransparency = 1
    lockHint.Font = Enum.Font.Gotham
    lockHint.TextSize = 9
    lockHint.TextColor3 = Color3.fromRGB(150,120,200)
    lockHint.Text = FT.get("lock_hint_prefix") .. FlyLogic.getLockKey().Name
    lockHint.TextXAlignment = Enum.TextXAlignment.Right

    -- Sección Noclip
    local noclipSec = makeSection(82)
    noclipSec.Parent = expandZone
    local noclipTitle = Instance.new("TextLabel", noclipSec)
    noclipTitle.Size = UDim2.new(1, -12, 0, 16)
    noclipTitle.Position = UDim2.new(0, 6, 0, 2)
    noclipTitle.BackgroundTransparency = 1
    noclipTitle.Font = Enum.Font.GothamBold
    noclipTitle.TextSize = 11
    noclipTitle.TextColor3 = C_TEXT
    noclipTitle.Text = FT.get("noclip_title")
    noclipTitle.TextXAlignment = Enum.TextXAlignment.Left

    local function createToggle(parent, xPos, yPos, initialState, onChange)
        local switchWidth = 36; local switchHeight = 18; local knobSize = 14
        local bg = Instance.new("Frame")
        bg.Size = UDim2.new(0, switchWidth, 0, switchHeight)
        bg.Position = UDim2.new(0, xPos, 0, yPos)
        bg.BackgroundColor3 = initialState and Color3.fromRGB(80,200,80) or Color3.fromRGB(80,80,80)
        bg.BorderSizePixel = 0
        bg.Parent = parent
        Instance.new("UICorner", bg).CornerRadius = UDim.new(1,0)
        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, knobSize, 0, knobSize)
        knob.Position = initialState and UDim2.new(1,-knobSize-2,0.5,-knobSize/2) or UDim2.new(0,2,0.5,-knobSize/2)
        knob.BackgroundColor3 = Color3.fromRGB(255,255,255)
        knob.BorderSizePixel = 0
        knob.Parent = bg
        Instance.new("UICorner", knob).CornerRadius = UDim.new(1,0)
        local state = initialState
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(1,0,1,0)
        button.BackgroundTransparency = 1
        button.Text = ""
        button.Parent = bg
        button.MouseButton1Click:Connect(function()
            state = not state
            TweenService:Create(bg, TweenInfo.new(0.1, Enum.EasingStyle.Quad),
                {BackgroundColor3 = state and Color3.fromRGB(80,200,80) or Color3.fromRGB(80,80,80)}):Play()
            TweenService:Create(knob, TweenInfo.new(0.1, Enum.EasingStyle.Quad),
                {Position = state and UDim2.new(1,-knobSize-2,0.5,-knobSize/2) or UDim2.new(0,2,0.5,-knobSize/2)}):Play()
            if onChange then onChange(state) end
        end)
        return bg
    end

    -- Fila Espacio
    local spaceRow = Instance.new("Frame", noclipSec)
    spaceRow.Size = UDim2.new(1, -12, 0, 20)
    spaceRow.Position = UDim2.new(0, 6, 0, 18)
    spaceRow.BackgroundTransparency = 1
    local spaceLabel = Instance.new("TextLabel", spaceRow)
    spaceLabel.Size = UDim2.new(0, 88, 1, 0)
    spaceLabel.BackgroundTransparency = 1
    spaceLabel.Font = Enum.Font.Gotham
    spaceLabel.TextSize = 10
    spaceLabel.TextColor3 = C_TEXT
    spaceLabel.Text = FT.get("noclip_space")
    spaceLabel.TextXAlignment = Enum.TextXAlignment.Left
    createToggle(spaceRow, 146, 1, FlyLogic.getNoclipSpace(), function(state)
        FlyLogic.setNoclipSpace(state)
    end)

    -- Fila Ctrl
    local ctrlRow = Instance.new("Frame", noclipSec)
    ctrlRow.Size = UDim2.new(1, -12, 0, 20)
    ctrlRow.Position = UDim2.new(0, 6, 0, 40)
    ctrlRow.BackgroundTransparency = 1
    local ctrlLabel = Instance.new("TextLabel", ctrlRow)
    ctrlLabel.Size = UDim2.new(0, 88, 1, 0)
    ctrlLabel.BackgroundTransparency = 1
    ctrlLabel.Font = Enum.Font.Gotham
    ctrlLabel.TextSize = 10
    ctrlLabel.TextColor3 = C_TEXT
    ctrlLabel.Text = FT.get("noclip_ctrl")
    ctrlLabel.TextXAlignment = Enum.TextXAlignment.Left
    createToggle(ctrlRow, 146, 1, FlyLogic.getNoclipCtrl(), function(state)
        FlyLogic.setNoclipCtrl(state)
    end)

    -- Fila Mega Turbo
    local megaRow = Instance.new("Frame", noclipSec)
    megaRow.Size = UDim2.new(1, -12, 0, 20)
    megaRow.Position = UDim2.new(0, 6, 0, 62)
    megaRow.BackgroundTransparency = 1
    local megaLabel = Instance.new("TextLabel", megaRow)
    megaLabel.Size = UDim2.new(0, 88, 1, 0)
    megaLabel.BackgroundTransparency = 1
    megaLabel.Font = Enum.Font.Gotham
    megaLabel.TextSize = 10
    megaLabel.TextColor3 = C_TEXT
    megaLabel.Text = FT.get("noclip_mega")
    megaLabel.TextXAlignment = Enum.TextXAlignment.Left
    createToggle(megaRow, 146, 1, FlyLogic.getNoclipMega(), function(state)
        FlyLogic.setNoclipMega(state)
    end)

    -- Sección Speed
    local speedSec = makeSection(104)
    speedSec.BackgroundColor3 = Color3.fromRGB(25,12,55)
    speedSec.Parent = expandZone
    local speedStroke = Instance.new("UIStroke", speedSec)
    speedStroke.Color = C_PURPLE
    speedStroke.Thickness = 1
    speedStroke.Transparency = 0.6

    local function makeRow(labelText, yPos, defaultVal, minVal, maxVal, onChange)
        local lbl = Instance.new("TextLabel", speedSec)
        lbl.Size = UDim2.new(0, 88, 0, 18)
        lbl.Position = UDim2.new(0, 8, 0, yPos)
        lbl.BackgroundTransparency = 1
        lbl.Font = Enum.Font.GothamSemibold
        lbl.TextSize = 10
        lbl.TextColor3 = C_TEXT
        lbl.Text = labelText
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        local box = Instance.new("TextBox", speedSec)
        box.Size = UDim2.new(1, -100, 0, 18)
        box.Position = UDim2.new(0, 94, 0, yPos)
        box.BackgroundColor3 = Color3.fromRGB(18,6,32)
        box.BackgroundTransparency = 0.05
        box.BorderSizePixel = 0
        box.Font = Enum.Font.GothamBold
        box.TextSize = 10
        box.TextColor3 = C_ACCENT
        box.Text = tostring(defaultVal)
        box.ClearTextOnFocus = true
        Instance.new("UICorner", box).CornerRadius = UDim.new(0, 4)
        local bs = Instance.new("UIStroke", box)
        bs.Color = C_ACCENT
        bs.Thickness = 1
        bs.Transparency = 0.55
        box:GetPropertyChangedSignal("Text"):Connect(function()
            local n = tonumber(box.Text:match("[%d%.]+"))
            if n then n = math.clamp(n, minVal, maxVal); box.Text = tostring(n) end
        end)
        if onChange then
            box.FocusLost:Connect(function()
                local n = tonumber(box.Text:match("[%d%.]+"))
                if n then onChange(math.clamp(n, minVal, maxVal)) end
            end)
        end
        return box
    end

    local speedBox = makeRow(FT.get("speed_base"), 6, FlyLogic.getBaseSpeed(), 1, 10000, function(v)
        FlyLogic.setBaseSpeed(v)
        if updateModeCallback then updateModeCallback(FlyLogic.getMode()) end
    end)
    local fastBox = makeRow(FT.get("speed_turbo_mult"), 30, FlyLogic.getFastMult(), 1, 1000, function(v)
        FlyLogic.setFastMult(v)
        if updateModeCallback then updateModeCallback(FlyLogic.getMode()) end
    end)
    local turboBox = makeRow(FT.get("speed_mega_mult"), 54, FlyLogic.getTurboMult(), 1, 1000, function(v)
        FlyLogic.setTurboMult(v)
        if updateModeCallback then updateModeCallback(FlyLogic.getMode()) end
    end)

    local resetBtn = Instance.new("TextButton", speedSec)
    resetBtn.Size = UDim2.new(0, 90, 0, 20)
    resetBtn.Position = UDim2.new(0.5, -45, 0, 82)
    resetBtn.BackgroundColor3 = Color3.fromRGB(60,10,110)
    resetBtn.BackgroundTransparency = 0.2
    resetBtn.BorderSizePixel = 0
    resetBtn.Font = Enum.Font.GothamBold
    resetBtn.TextSize = 10
    resetBtn.TextColor3 = C_TEXT
    resetBtn.Text = FT.get("speed_reset")
    Instance.new("UICorner", resetBtn).CornerRadius = UDim.new(0, 5)
    resetBtn.MouseButton1Click:Connect(function()
        FlyLogic.resetSpeeds()
        speedBox.Text = tostring(FlyLogic.getBaseSpeed())
        fastBox.Text = tostring(FlyLogic.getFastMult())
        turboBox.Text = tostring(FlyLogic.getTurboMult())
        if updateModeCallback then updateModeCallback(FlyLogic.getMode()) end
        TweenService:Create(resetBtn, TweenInfo.new(0.1), {TextColor3 = C_GREEN}):Play()
        task.delay(0.5, function()
            pcall(function() TweenService:Create(resetBtn, TweenInfo.new(0.3), {TextColor3 = C_TEXT}):Play() end)
        end)
    end)

    local function startPulse()
        if pulseConn then return end
        pulseConn = task.spawn(function()
            while gui and gui.Parent and expanded do
                TweenService:Create(stroke, TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                    {Thickness = 2.5, Color = C_ACCENT, Transparency = 0}):Play()
                task.wait(0.7)
                if not (gui and gui.Parent and expanded) then break end
                TweenService:Create(stroke, TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                    {Thickness = 1.5, Color = C_PURPLE, Transparency = 0.35}):Play()
                task.wait(0.7)
            end
            pcall(function()
                stroke.Thickness = 1.2
                stroke.Color = C_PURPLE
                stroke.Transparency = 0.75
            end)
            pulseConn = nil
        end)
    end

    local function setExpanded(state)
        expanded = state
        expandZone.Visible = state
        local h = state and H_FULL or H_MINI
        root.Size = UDim2.new(0, W, 0, h)
        TweenService:Create(panel, TW, {Size = UDim2.new(1, 0, 0, h)}):Play()
        TweenService:Create(dot, TweenInfo.new(0.2, Enum.EasingStyle.Quad),
            {BackgroundTransparency = state and 0 or 0.35}):Play()
        TweenService:Create(dot, TweenInfo.new(0.2, Enum.EasingStyle.Quad),
            {Size = state and UDim2.new(0, DOT_SIZE, 0, DOT_SIZE) or UDim2.new(0, DOT_SIZE-3, 0, DOT_SIZE-3),
             Position = state and UDim2.new(0.5, -DOT_SIZE/2, 0.5, -DOT_SIZE/2) or UDim2.new(0.5, -(DOT_SIZE-3)/2, 0.5, -(DOT_SIZE-3)/2)}):Play()
        if state then
            startPulse()
        else
            if pulseConn then task.cancel(pulseConn); pulseConn = nil end
            pcall(function()
                stroke.Thickness = 1.2
                stroke.Color = C_PURPLE
                stroke.Transparency = 0.75
            end)
        end
    end

    dotBtn.MouseButton1Click:Connect(function() setExpanded(not expanded) end)

    -- Hacer la GUI arrastrable
    local dragging = false
    local dragStartMouse = Vector2.new()
    local dragStartPos = UDim2.new()
    topBar.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStartMouse = Vector2.new(inp.Position.X, inp.Position.Y)
            dragStartPos = root.Position
        end
    end)
    topBar.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if not dragging then return end
        if inp.UserInputType ~= Enum.UserInputType.MouseMovement and inp.UserInputType ~= Enum.UserInputType.Touch then return end
        local delta = Vector2.new(inp.Position.X, inp.Position.Y) - dragStartMouse
        root.Position = UDim2.new(dragStartPos.X.Scale, dragStartPos.X.Offset + delta.X, dragStartPos.Y.Scale, dragStartPos.Y.Offset + delta.Y)
    end)

    updateModeCallback = function(newMode)
        local mult = (newMode == "fast" and FlyLogic.getFastMult()) or (newMode == "turbo" and FlyLogic.getTurboMult()) or 1
        modeLbl.Text = FT.getModeText(newMode, mult)
        local colors = { normal = C_GREEN, fast = C_YELLOW, turbo = C_RED, megaup = C_CYAN }
        modeLbl.TextColor3 = colors[newMode] or C_GREEN
        TweenService:Create(dot, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {BackgroundColor3 = colors[newMode] or C_ACCENT}):Play()
    end

    updateLockLabelsCallback = function()
        lockLabel.Text = FT.get("lock_label") .. " [" .. FlyLogic.getLockKey().Name .. "]"
        lockHint.Text = FT.get("lock_hint_prefix") .. FlyLogic.getLockKey().Name
    end

    updateModeCallback(FlyLogic.getMode())
end

-- ============================================================
-- Manejo de eventos de entrada
-- ============================================================
local inputConn = nil
local inputEndConn = nil
local characterConn = nil

local function onInputBegan(input, gpe)
    if gpe or isTyping() then return end

    if input.KeyCode == FlyLogic.getFlyKey() then
        if FlyLogic.isEnabled() then
            M.Stop()
        else
            M.Start(lplr, FlyLogic.getFlyKey())
        end
        return
    end

    if input.KeyCode == Enum.KeyCode.Q then
        FlyLogic.onQPress()
        return
    end

    if input.KeyCode == Enum.KeyCode.F then
        FlyAnim.onBlockPress()
        return
    end

    if input.KeyCode == Enum.KeyCode.Space then
        spaceDown = true
        FlyLogic.onSpacePress()
        if FlyLogic.isEnabled() and FlyLogic.getMode() == "normal" then
            FlyAnim.onSpacePress()
        end
        debouncedUpdateMovement()
        return
    end

    if input.KeyCode == Enum.KeyCode.LeftControl then
        ctrlDown = true
        FlyLogic.onCtrlPress()
        return
    end

    if input.KeyCode == Enum.KeyCode.W then wDown = true; debouncedUpdateMovement() end
    if input.KeyCode == Enum.KeyCode.S then sDown = true; debouncedUpdateMovement() end
    if input.KeyCode == Enum.KeyCode.A then aDown = true; debouncedUpdateMovement() end
    if input.KeyCode == Enum.KeyCode.D then dDown = true; debouncedUpdateMovement() end
end

local function onInputEnded(input, gpe)
    if gpe then return end

    if input.KeyCode == Enum.KeyCode.F then
        FlyAnim.onBlockRelease()
        return
    end

    if input.KeyCode == Enum.KeyCode.Space then
        spaceDown = false
        FlyLogic.onSpaceRelease()
        if FlyLogic.isEnabled() then
            FlyAnim.onSpaceRelease()
        end
        debouncedUpdateMovement()
        return
    end

    if input.KeyCode == Enum.KeyCode.LeftControl then
        ctrlDown = false
        FlyLogic.onCtrlRelease()
        return
    end

    if input.KeyCode == Enum.KeyCode.W then wDown = false; debouncedUpdateMovement() end
    if input.KeyCode == Enum.KeyCode.S then sDown = false; debouncedUpdateMovement() end
    if input.KeyCode == Enum.KeyCode.A then aDown = false; debouncedUpdateMovement() end
    if input.KeyCode == Enum.KeyCode.D then dDown = false; debouncedUpdateMovement() end
end

local function onCharacterAdded(newChar)
    local humanoid = newChar:FindFirstChildOfClass("Humanoid")
    local rootJoint = newChar:FindFirstChild("HumanoidRootPart") and newChar.HumanoidRootPart:FindFirstChild("RootJoint")
    if humanoid and rootJoint then
        FlyAnim.init(newChar, humanoid, rootJoint)
        FlyAnim.setDamageDetector(humanoid)
    end
    if FlyLogic.isEnabled() then
        FlyLogic.stop()
        FlyAnim.setEnabled(false)
        task.wait(0.5)
        FlyLogic.start()
        FlyAnim.setEnabled(true)
    end
end

local function connectEvents()
    if inputConn then inputConn:Disconnect() end
    if inputEndConn then inputEndConn:Disconnect() end
    if characterConn then characterConn:Disconnect() end
    inputConn = UserInputService.InputBegan:Connect(onInputBegan)
    inputEndConn = UserInputService.InputEnded:Connect(onInputEnded)
    characterConn = Players.LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
end

local function disconnectEvents()
    if inputConn then inputConn:Disconnect(); inputConn = nil end
    if inputEndConn then inputEndConn:Disconnect(); inputEndConn = nil end
    if characterConn then characterConn:Disconnect(); characterConn = nil end
end

-- ============================================================
-- API PÚBLICA (EXACTAMENTE LA QUE ESPERA TU SISTEMA)
-- ============================================================
local M = {}

function M.Start(lplrRef, flyKey)
    lplr = lplrRef or Players.LocalPlayer
    camera = workspace.CurrentCamera
    if flyKey then FlyLogic.setFlyKey(flyKey) end
    FlyText.reload()
    FlyLogic.init(lplr, camera, FlyAnim)
    buildGUI()
    connectEvents()
    FlyLogic.start()
    FlyAnim.setEnabled(true)
    local char = lplr.Character
    if char then
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        local rootJoint = char:FindFirstChild("HumanoidRootPart") and char.HumanoidRootPart:FindFirstChild("RootJoint")
        if humanoid and rootJoint then
            FlyAnim.init(char, humanoid, rootJoint)
            FlyAnim.setDamageDetector(humanoid)
        end
    end
end

function M.Stop()
    if not FlyLogic.isEnabled() then return end
    FlyLogic.stop()
    FlyAnim.setEnabled(false)
    disconnectEvents()
    destroyGUI()
end

function M.Toggle(state)
    if state then
        if not FlyLogic.isEnabled() then
            M.Start(lplr, FlyLogic.getFlyKey())
        end
    else
        if FlyLogic.isEnabled() then
            M.Stop()
        end
    end
end

function M.SetKey(keyCode)
    FlyLogic.setFlyKey(keyCode)
    if gui then
        local titleLbl = gui:FindFirstChild("Frame") and gui.Frame:FindFirstChild("titleLbl")
        if titleLbl then
            titleLbl.Text = FlyText.get("fly_title") .. " [" .. keyCode.Name .. "]"
        end
    end
    -- Reconectar eventos para que la nueva tecla tenga efecto inmediato
    if FlyLogic.isEnabled() then
        disconnectEvents()
        connectEvents()
    end
end

function M.SetLockKey(keyCode)
    FlyLogic.setLockKey(keyCode)
    if updateLockLabelsCallback then updateLockLabelsCallback() end
    -- Reconectar lock system
    if FlyLogic.isEnabled() then
        -- Forzar reinicio del lock system (FlyLogic ya tiene su propio reconexión)
        FlyLogic.setLockKey(keyCode)  -- ya llamamos a setLockKey, que internamente hará lo necesario
    end
end

function M.GetFlyKey()
    return FlyLogic.getFlyKey()
end

function M.GetLockKey()
    return FlyLogic.getLockKey()
end

function M.IsEnabled()
    return FlyLogic.isEnabled()
end

return M
