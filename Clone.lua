-- ProClonePlayer Module - Versión Avanzada
local M = {}

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- Variables de Estado
local _lplr = nil
local _lang = "ES"
local _guiActive = false
local spawnedClones = {}
local espHighlights = {}

-- Modos
local isPlacing = false
local ghostClone = nil
local targetToClone = nil
local deleteMode = false
local editorSelectedClone = nil

-- Estados de grabación
local isRecording = false
local recordedFrames = {}
local recordTimeLeft = 0

-- UI Elements
local ScreenGui, MainFrame, LeftMenu, RightMenu
local RedHighlight

-- ==========================================
-- FUNCIONES AUXILIARES
-- ==========================================
local function LC(es, en) return (_lang == "EN") and en or es end

local function CreateHighlight(target, color, fillTrans)
    local hl = Instance.new("Highlight")
    hl.Adornee = target
    hl.FillColor = color
    hl.FillTransparency = fillTrans or 0.5
    hl.OutlineColor = Color3.new(1, 1, 1)
    hl.OutlineTransparency = 0.2
    hl.Parent = target
    return hl
end

local function UpdateESP(active)
    for _, hl in ipairs(espHighlights) do hl:Destroy() end
    table.clear(espHighlights)
    if active then
        for _, clone in ipairs(spawnedClones) do
            if clone and clone.Parent then
                table.insert(espHighlights, CreateHighlight(clone, Color3.fromRGB(160, 60, 255), 0.7))
            end
        end
    end
end

local function CleanupAll()
    for _, clone in ipairs(spawnedClones) do
        if clone and clone.Parent then clone:Destroy() end
    end
    table.clear(spawnedClones)
    if ghostClone then ghostClone:Destroy() ghostClone = nil end
    if RedHighlight then RedHighlight:Destroy() RedHighlight = nil end
    UpdateESP(false)
    isPlacing = false
    deleteMode = false
end

-- ==========================================
-- LÓGICA DE CLONACIÓN Y POSICIONAMIENTO
-- ==========================================
local function FinalizeClone(cframe)
    if not targetToClone or not targetToClone.Character then return end
    
    local PlrChar = targetToClone.Character
    PlrChar.Archivable = true
    local Clon = PlrChar:Clone()
    PlrChar.Archivable = false
    
    Clon.Parent = workspace
    Clon:SetPrimaryPartCFrame(cframe)
    Clon:MakeJoints()
    
    -- Limpiar scripts del clon
    for _, v in ipairs(Clon:GetDescendants()) do
        if v:IsA("Script") or v:IsA("LocalScript") then v.Disabled = true end
    end
    
    table.insert(spawnedClones, Clon)
    if #espHighlights > 0 then UpdateESP(true) end -- Actualizar ESP si está activo
    
    return Clon
end

local function StartGhostPlacement()
    if not targetToClone or not targetToClone.Character then return end
    isPlacing = true
    
    local PlrChar = targetToClone.Character
    PlrChar.Archivable = true
    ghostClone = PlrChar:Clone()
    PlrChar.Archivable = false
    
    for _, v in ipairs(ghostClone:GetDescendants()) do
        if v:IsA("BasePart") then
            v.Transparency = 0.7
            v.CanCollide = false
            v.Anchored = true
            v.Material = Enum.Material.ForceField
        elseif v:IsA("Script") or v:IsA("LocalScript") then
            v.Disabled = true
        end
    end
    ghostClone.Parent = workspace
end

RunService.RenderStepped:Connect(function()
    -- Lógica de Posicionamiento Fantasma
    if isPlacing and ghostClone and ghostClone.PrimaryPart then
        local hit = Mouse.Hit
        if hit then
            -- Ajustar para que no atraviese el suelo (básico)
            ghostClone:SetPrimaryPartCFrame(CFrame.new(hit.p + Vector3.new(0, 3, 0)))
        end
    end
    
    -- Lógica de Modo Borrar (Hover rojo)
    if deleteMode and not isPlacing then
        local target = Mouse.Target
        if target then
            local model = target:FindFirstAncestorOfClass("Model")
            if model and table.find(spawnedClones, model) then
                if not RedHighlight or RedHighlight.Adornee ~= model then
                    if RedHighlight then RedHighlight:Destroy() end
                    RedHighlight = CreateHighlight(model, Color3.fromRGB(255, 0, 0), 0.4)
                end
            else
                if RedHighlight then RedHighlight:Destroy() RedHighlight = nil end
            end
        else
            if RedHighlight then RedHighlight:Destroy() RedHighlight = nil end
        end
    end
end)

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    
    if isPlacing then
        if input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.KeypadEnter then
            -- Aceptar Clon
            local finalCFrame = ghostClone.PrimaryPart.CFrame
            ghostClone:Destroy()
            ghostClone = nil
            isPlacing = false
            FinalizeClone(finalCFrame)
        elseif input.KeyCode == Enum.KeyCode.Delete or input.KeyCode == Enum.KeyCode.Backspace then
            -- Cancelar
            ghostClone:Destroy()
            ghostClone = nil
            isPlacing = false
        end
    end
    
    if deleteMode and input.UserInputType == Enum.UserInputType.MouseButton1 then
        if RedHighlight and RedHighlight.Adornee then
            local toDelete = RedHighlight.Adornee
            local idx = table.find(spawnedClones, toDelete)
            if idx then table.remove(spawnedClones, idx) end
            toDelete:Destroy()
            RedHighlight:Destroy()
            RedHighlight = nil
        end
    end
    
    -- Seleccionar clon para el editor (Click derecho si el editor está abierto)
    if input.UserInputType == Enum.UserInputType.MouseButton2 and RightMenu.Position.X.Scale < 1 then
        local target = Mouse.Target
        if target then
            local model = target:FindFirstAncestorOfClass("Model")
            if model and table.find(spawnedClones, model) then
                editorSelectedClone = model
                print("Clon seleccionado para edición")
            end
        end
    end
end)

-- ==========================================
-- UI PRINCIPAL
-- ==========================================
function M.Start(lplr, lang)
    _lplr = lplr
    _lang = lang or "ES"
end

function M.Open()
    if _guiActive then return end
    _guiActive = true

    pcall(function()
        local old = CoreGui:FindFirstChild("ProCloneGui")
        if old then old:Destroy() end
    end)

    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "ProCloneGui"
    ScreenGui.ResetOnSpawn = false
    pcall(function() ScreenGui.Parent = CoreGui end)
    if not ScreenGui.Parent then ScreenGui.Parent = _lplr:WaitForChild("PlayerGui") end

    -- MainFrame (Basado en "Lector de animaciones")
    MainFrame = Instance.new("Frame", ScreenGui)
    MainFrame.Size = UDim2.new(0, 300, 0, 400)
    MainFrame.Position = UDim2.new(0.5, -150, 0.5, -200)
    MainFrame.BackgroundColor3 = Color3.fromRGB(6, 4, 12) -- Color del lector
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true
    Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

    local TopBar = Instance.new("Frame", MainFrame)
    TopBar.Size = UDim2.new(1, 0, 0, 40)
    TopBar.BackgroundColor3 = Color3.fromRGB(28, 20, 45)
    Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 8)
    
    local Title = Instance.new("TextLabel", TopBar)
    Title.Size = UDim2.new(1, -50, 1, 0)
    Title.Position = UDim2.new(0, 10, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "CLONE MANAGER PRO"
    Title.TextColor3 = Color3.fromRGB(220, 190, 255)
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 14
    Title.TextXAlignment = Enum.TextXAlignment.Left

    local CloseBtn = Instance.new("TextButton", TopBar)
    CloseBtn.Size = UDim2.new(0, 26, 0, 26)
    CloseBtn.Position = UDim2.new(1, -32, 0.5, -13)
    CloseBtn.BackgroundColor3 = Color3.fromRGB(60, 15, 20)
    CloseBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
    CloseBtn.Text = "X"
    CloseBtn.Font = Enum.Font.GothamBold
    Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 5)
    CloseBtn.MouseButton1Click:Connect(M.Stop)

    -- Player Input y Autocompletado
    local PlayerBox = Instance.new("TextBox", MainFrame)
    PlayerBox.Size = UDim2.new(0.9, 0, 0, 35)
    PlayerBox.Position = UDim2.new(0.05, 0, 0, 50)
    PlayerBox.BackgroundColor3 = Color3.fromRGB(18, 12, 30)
    PlayerBox.TextColor3 = Color3.fromRGB(220, 190, 255)
    PlayerBox.Font = Enum.Font.Gotham
    PlayerBox.TextSize = 14
    PlayerBox.PlaceholderText = LC("Nombre del jugador", "Player name")
    Instance.new("UICorner", PlayerBox).CornerRadius = UDim.new(0, 6)
    
    PlayerBox.FocusLost:Connect(function()
        local text = PlayerBox.Text:lower()
        for _, p in ipairs(Players:GetPlayers()) do
            if string.sub(p.Name:lower(), 1, #text) == text or string.sub(p.DisplayName:lower(), 1, #text) == text then
                PlayerBox.Text = p.Name
                break
            end
        end
    end)

    -- Botón Principal de Clonar
    local CloneBtn = Instance.new("TextButton", MainFrame)
    CloneBtn.Size = UDim2.new(0.9, 0, 0, 35)
    CloneBtn.Position = UDim2.new(0.05, 0, 0, 95)
    CloneBtn.BackgroundColor3 = Color3.fromRGB(160, 60, 255)
    CloneBtn.TextColor3 = Color3.new(1, 1, 1)
    CloneBtn.Font = Enum.Font.GothamBold
    CloneBtn.TextSize = 14
    CloneBtn.Text = LC("Clonar (Click -> Enter)", "Clone (Click -> Enter)")
    Instance.new("UICorner", CloneBtn).CornerRadius = UDim.new(0, 6)
    
    CloneBtn.MouseButton1Click:Connect(function()
        targetToClone = Players:FindFirstChild(PlayerBox.Text)
        if targetToClone then StartGhostPlacement() end
    end)

    -- Panel de Control (Delete, ESP, TP)
    local ControlFrame = Instance.new("Frame", MainFrame)
    ControlFrame.Size = UDim2.new(0.9, 0, 0, 80)
    ControlFrame.Position = UDim2.new(0.05, 0, 0, 140)
    ControlFrame.BackgroundTransparency = 1
    
    local function CreateMiniBtn(txt, pos, color, parent)
        local btn = Instance.new("TextButton", parent)
        btn.Size = UDim2.new(0.48, 0, 0, 30)
        btn.Position = pos
        btn.BackgroundColor3 = color
        btn.TextColor3 = Color3.new(1,1,1)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 12
        btn.Text = txt
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)
        return btn
    end

    local ToggleDeleteBtn = CreateMiniBtn("Modo Borrar: OFF", UDim2.new(0, 0, 0, 0), Color3.fromRGB(60, 20, 20), ControlFrame)
    ToggleDeleteBtn.MouseButton1Click:Connect(function()
        deleteMode = not deleteMode
        ToggleDeleteBtn.Text = "Modo Borrar: " .. (deleteMode and "ON" or "OFF")
        ToggleDeleteBtn.BackgroundColor3 = deleteMode and Color3.fromRGB(150, 30, 30) or Color3.fromRGB(60, 20, 20)
    end)

    local DeleteAllBtn = CreateMiniBtn("Borrar Todos", UDim2.new(0.52, 0, 0, 0), Color3.fromRGB(100, 20, 20), ControlFrame)
    DeleteAllBtn.MouseButton1Click:Connect(function()
        for _, c in ipairs(spawnedClones) do c:Destroy() end
        table.clear(spawnedClones)
    end)

    local ToggleESPBtn = CreateMiniBtn("ESP: OFF", UDim2.new(0, 0, 0, 35), Color3.fromRGB(20, 60, 20), ControlFrame)
    local espState = false
    ToggleESPBtn.MouseButton1Click:Connect(function()
        espState = not espState
        ToggleESPBtn.Text = "ESP: " .. (espState and "ON" or "OFF")
        ToggleESPBtn.BackgroundColor3 = espState and Color3.fromRGB(40, 120, 40) or Color3.fromRGB(20, 60, 20)
        UpdateESP(espState)
    end)

    local TpBtn = CreateMiniBtn("TP al Último Clon", UDim2.new(0.52, 0, 0, 35), Color3.fromRGB(20, 40, 80), ControlFrame)
    TpBtn.MouseButton1Click:Connect(function()
        local lastClone = spawnedClones[#spawnedClones]
        if lastClone and LocalPlayer.Character and LocalPlayer.Character.PrimaryPart then
            LocalPlayer.Character:SetPrimaryPartCFrame(lastClone.PrimaryPart.CFrame + Vector3.new(0, 5, 0))
        end
    end)

    -- ==========================================
    -- MENÚ AVANZADO (IZQUIERDA)
    -- ==========================================
    LeftMenu = Instance.new("Frame", MainFrame)
    LeftMenu.Size = UDim2.new(0, 200, 1, 0)
    LeftMenu.Position = UDim2.new(0, 0, 0, 0) -- Escondido por ZIndex o Clip
    LeftMenu.BackgroundColor3 = Color3.fromRGB(12, 8, 20)
    LeftMenu.ZIndex = -1
    Instance.new("UICorner", LeftMenu).CornerRadius = UDim.new(0, 8)
    
    local LblAdv = Instance.new("TextLabel", LeftMenu)
    LblAdv.Size = UDim2.new(1, 0, 0, 30)
    LblAdv.Text = "Menú Avanzado"
    LblAdv.TextColor3 = Color3.fromRGB(220, 190, 255)
    LblAdv.BackgroundTransparency = 1
    LblAdv.Font = Enum.Font.GothamBold

    local AnimInput = Instance.new("TextBox", LeftMenu)
    AnimInput.Size = UDim2.new(0.9, 0, 0, 30)
    AnimInput.Position = UDim2.new(0.05, 0, 0, 40)
    AnimInput.BackgroundColor3 = Color3.fromRGB(18, 12, 30)
    AnimInput.TextColor3 = Color3.fromRGB(80, 200, 255)
    AnimInput.PlaceholderText = "ID Animación"
    Instance.new("UICorner", AnimInput).CornerRadius = UDim.new(0, 4)

    local PlayAnimBtn = CreateMiniBtn("Animar Último", UDim2.new(0.05, 0, 0, 75), Color3.fromRGB(60, 20, 100), LeftMenu)
    PlayAnimBtn.Size = UDim2.new(0.9, 0, 0, 30)
    PlayAnimBtn.MouseButton1Click:Connect(function()
        local last = spawnedClones[#spawnedClones]
        local id = AnimInput.Text:match("%d+")
        if last and id then
            local hum = last:FindFirstChildOfClass("Humanoid")
            local anim = Instance.new("Animation")
            anim.AnimationId = "rbxassetid://" .. id
            local track = hum:LoadAnimation(anim)
            track:Play()
        end
    end)

    local RecordBtn = CreateMiniBtn("Grabar (Cortina)", UDim2.new(0.05, 0, 0, 115), Color3.fromRGB(100, 50, 20), LeftMenu)
    RecordBtn.Size = UDim2.new(0.9, 0, 0, 30)
    -- Lógica de grabación simplificada: Graba CFrame del jugador local
    local recConnection
    RecordBtn.MouseButton1Click:Connect(function()
        if isRecording then
            isRecording = false
            RecordBtn.Text = "Grabar (Cortina)"
            if recConnection then recConnection:Disconnect() end
            -- Aplicar al último clon
            local last = spawnedClones[#spawnedClones]
            if last and #recordedFrames > 0 then
                task.spawn(function()
                    for _, frame in ipairs(recordedFrames) do
                        if not last or not last.Parent then break end
                        last:SetPrimaryPartCFrame(frame)
                        task.wait(0.03) -- aprox 30 FPS playback
                    end
                end)
            end
        else
            isRecording = true
            table.clear(recordedFrames)
            RecordBtn.Text = "Detener Grabación"
            recConnection = RunService.RenderStepped:Connect(function()
                if LocalPlayer.Character and LocalPlayer.Character.PrimaryPart then
                    table.insert(recordedFrames, LocalPlayer.Character.PrimaryPart.CFrame)
                end
            end)
        end
    end)

    -- ==========================================
    -- EDITOR MENÚ (DERECHA)
    -- ==========================================
    RightMenu = Instance.new("Frame", MainFrame)
    RightMenu.Size = UDim2.new(0, 200, 1, 0)
    RightMenu.Position = UDim2.new(1, -200, 0, 0)
    RightMenu.BackgroundColor3 = Color3.fromRGB(12, 8, 20)
    RightMenu.ZIndex = -1
    Instance.new("UICorner", RightMenu).CornerRadius = UDim.new(0, 8)

    local LblEd = Instance.new("TextLabel", RightMenu)
    LblEd.Size = UDim2.new(1, 0, 0, 30)
    LblEd.Text = "Editor (Click Der. a Clon)"
    LblEd.TextColor3 = Color3.fromRGB(220, 190, 255)
    LblEd.BackgroundTransparency = 1
    LblEd.Font = Enum.Font.GothamBold
    LblEd.TextScaled = true

    local HealthInput = Instance.new("TextBox", RightMenu)
    HealthInput.Size = UDim2.new(0.6, 0, 0, 30)
    HealthInput.Position = UDim2.new(0.05, 0, 0, 40)
    HealthInput.BackgroundColor3 = Color3.fromRGB(18, 12, 30)
    HealthInput.TextColor3 = Color3.new(1,1,1)
    HealthInput.PlaceholderText = "Vida"
    Instance.new("UICorner", HealthInput).CornerRadius = UDim.new(0, 4)

    local ModeToggle = CreateMiniBtn("Raw", UDim2.new(0.7, 0, 0, 40), Color3.fromRGB(40,40,40), RightMenu)
    ModeToggle.Size = UDim2.new(0.25, 0, 0, 30)
    local isPercent = false
    ModeToggle.MouseButton1Click:Connect(function()
        isPercent = not isPercent
        ModeToggle.Text = isPercent and "%" or "Raw"
    end)

    local ApplyHBtn = CreateMiniBtn("Aplicar Vida", UDim2.new(0.05, 0, 0, 75), Color3.fromRGB(20, 60, 20), RightMenu)
    ApplyHBtn.Size = UDim2.new(0.9, 0, 0, 30)
    ApplyHBtn.MouseButton1Click:Connect(function()
        if editorSelectedClone then
            local hum = editorSelectedClone:FindFirstChildOfClass("Humanoid")
            if hum then
                local val = tonumber(HealthInput.Text)
                if val then
                    if isPercent then
                        hum.Health = (val / 100) * hum.MaxHealth
                    else
                        hum.MaxHealth = math.max(hum.MaxHealth, val)
                        hum.Health = val
                    end
                end
            end
        end
    end)

    local ColBtn = CreateMiniBtn("Colisión: ON", UDim2.new(0.05, 0, 0, 115), Color3.fromRGB(80, 80, 20), RightMenu)
    ColBtn.Size = UDim2.new(0.9, 0, 0, 30)
    local colState = true
    ColBtn.MouseButton1Click:Connect(function()
        if editorSelectedClone then
            colState = not colState
            ColBtn.Text = "Colisión: " .. (colState and "ON" or "OFF")
            for _, v in ipairs(editorSelectedClone:GetDescendants()) do
                if v:IsA("BasePart") then v.CanCollide = colState end
            end
        end
    end)

    -- Botones para abrir/cerrar menús laterales
    local BtnLeft = Instance.new("TextButton", MainFrame)
    BtnLeft.Size = UDim2.new(0, 20, 0, 60)
    BtnLeft.Position = UDim2.new(0, -20, 0.5, -30)
    BtnLeft.BackgroundColor3 = Color3.fromRGB(28, 20, 45)
    BtnLeft.TextColor3 = Color3.new(1,1,1)
    BtnLeft.Text = "<"
    Instance.new("UICorner", BtnLeft).CornerRadius = UDim.new(0, 5)
    local leftOpen = false
    BtnLeft.MouseButton1Click:Connect(function()
        leftOpen = not leftOpen
        TweenService:Create(LeftMenu, TweenInfo.new(0.3, Enum.EasingStyle.Back), {Position = UDim2.new(0, leftOpen and -210 or 0, 0, 0)}):Play()
        BtnLeft.Text = leftOpen and ">" or "<"
    end)

    local BtnRight = Instance.new("TextButton", MainFrame)
    BtnRight.Size = UDim2.new(0, 20, 0, 60)
    BtnRight.Position = UDim2.new(1, 0, 0.5, -30)
    BtnRight.BackgroundColor3 = Color3.fromRGB(28, 20, 45)
    BtnRight.TextColor3 = Color3.new(1,1,1)
    BtnRight.Text = ">"
    Instance.new("UICorner", BtnRight).CornerRadius = UDim.new(0, 5)
    local rightOpen = false
    BtnRight.MouseButton1Click:Connect(function()
        rightOpen = not rightOpen
        TweenService:Create(RightMenu, TweenInfo.new(0.3, Enum.EasingStyle.Back), {Position = UDim2.new(1, rightOpen and 10 or -200, 0, 0)}):Play()
        BtnRight.Text = rightOpen and "<" or ">"
    end)

end

function M.Stop()
    _guiActive = false
    CleanupAll()
    pcall(function()
        local old = CoreGui:FindFirstChild("ProCloneGui")
        if old then old:Destroy() end
        if ScreenGui then ScreenGui:Destroy() end
    end)
end

return M
