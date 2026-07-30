local M = {}

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ContentProvider = game:GetService("ContentProvider")

-- Variables del Módulo
local _lplr = nil
local _keys = nil
local _active = false
local connections = {}

-- Variables de Interfaz y Estado
local gui
local mainFrame
local playerImage
local lastUsername = "Wiftor"
local isOpen = false
local toggleKey = Enum.KeyCode.F4

-- === COLORES DE LA INTERFAZ ===
local C_PURPLE = Color3.fromRGB(110, 30, 180)
local C_BLACK  = Color3.fromRGB(6, 4, 12)
local C_TEXT   = Color3.fromRGB(220, 190, 255)
local C_SUB    = Color3.fromRGB(200, 170, 255)

-----------------------------------
-- FUNCIONES INTERNAS DE AVATAR ---
-----------------------------------
local function loadAvatarImage(userId)
    task.spawn(function()
        local success, content = pcall(function()
            return Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.AvatarBust, Enum.ThumbnailSize.Size420x420)
        end)
        if success and content and playerImage then
            playerImage.Image = content
            pcall(function()
                ContentProvider:PreloadAsync({playerImage})
            end)
        end
    end)
end

local function findHandleAttachment(handle)
    for _, child in ipairs(handle:GetChildren()) do
        if child:IsA("Attachment") then return child end
    end
    return nil
end

local function findCharacterAttachment(character, attachmentName)
    for _, descendant in ipairs(character:GetDescendants()) do
        if descendant:IsA("Attachment") and descendant.Name == attachmentName and descendant.Parent:IsA("BasePart") then
            return descendant
        end
    end
    return nil
end

local function manualAttachAccessory(accessory, character)
    local handle = accessory:FindFirstChild("Handle")
    if not handle or not handle:IsA("BasePart") then return false end
    
    local handleAttachment = findHandleAttachment(handle)
    if not handleAttachment then return false end
    
    local characterAttachment = findCharacterAttachment(character, handleAttachment.Name)
    if not characterAttachment then return false end

    accessory.Parent = character
    handle.Anchored = false
    handle.CanCollide = false
    handle.Massless = true
    handle.LocalTransparencyModifier = 0
    handle.CFrame = characterAttachment.Parent.CFrame * characterAttachment.CFrame * handleAttachment.CFrame:Inverse()

    local oldWeld = handle:FindFirstChild("AccessoryWeld")
    if oldWeld then oldWeld:Destroy() end

    local weld = Instance.new("Weld")
    weld.Name = "AccessoryWeld"
    weld.Part0 = handle
    weld.Part1 = characterAttachment.Parent
    weld.C0 = handleAttachment.CFrame
    weld.C1 = characterAttachment.CFrame
    weld.Parent = handle
    
    return true
end

local function apply_avatar(username, isReset)
    task.spawn(function()
        if not _lplr then return end
        local char = _lplr.Character or _lplr.CharacterAdded:Wait()
        local hum = char:WaitForChild("Humanoid", 10)
        if not hum then return end

        -- 1. Conseguir el UserId
        local targetUserId = nil
        local targetPlayer = Players:FindFirstChild(username)
        
        if targetPlayer then
            targetUserId = targetPlayer.UserId
        else
            local ok, userId = pcall(Players.GetUserIdFromNameAsync, Players, username)
            if ok then targetUserId = userId end
        end

        if not targetUserId then return end
        loadAvatarImage(targetUserId)

        -- 2. === DESCARGAR APARIENCIA COMPLETA ===
        local successApp, appearanceModel = pcall(function() return Players:GetCharacterAppearanceAsync(targetUserId) end)
        if not successApp or not appearanceModel then return end

        -- 3. === LIMPIEZA TOTAL DEL AVATAR ===
        for _, c in ipairs(char:GetChildren()) do
            if c:IsA("Accessory") or c:IsA("Hat") or c:IsA("Shirt") or c:IsA("Pants") or c:IsA("ShirtGraphic") or c:IsA("CharacterMesh") then
                c:Destroy()
            end
        end

        local head = char:FindFirstChild("Head")
        if head then
            for _, m in ipairs(head:GetChildren()) do
                if m:IsA("DataModelMesh") or m:IsA("Decal") then m:Destroy() end
            end
            local defaultMesh = Instance.new("SpecialMesh")
            defaultMesh.MeshType = Enum.MeshType.Head
            defaultMesh.Scale = Vector3.new(1.25, 1.25, 1.25)
            defaultMesh.Parent = head
        end

        local loadedFace = false

        -- 4. === APLICACIÓN FINAL ===
        for _, item in ipairs(appearanceModel:GetChildren()) do
            if item:IsA("Accessory") then
                local acc = item:Clone()
                local addSuccess = pcall(function() hum:AddAccessory(acc) end)
                
                local handle = acc:FindFirstChild("Handle")
                if not (addSuccess and handle and handle:FindFirstChild("AccessoryWeld")) then
                    manualAttachAccessory(acc, char)
                end
            elseif item:IsA("Shirt") or item:IsA("Pants") or item:IsA("ShirtGraphic") then
                item:Clone().Parent = char
            elseif item:IsA("BodyColors") then
                local oldColors = char:FindFirstChildOfClass("BodyColors")
                if oldColors then oldColors:Destroy() end
                item:Clone().Parent = char
            elseif item:IsA("Decal") and item.Name:lower() == "face" then
                if head then
                    loadedFace = true
                    local newFace = item:Clone()
                    local faceId = string.match(item.Texture, "%d+")
                    if faceId then
                        newFace.Texture = "rbxthumb://type=Asset&id=" .. faceId .. "&w=420&h=420"
                    end
                    newFace.Parent = head
                end
            elseif item.Name == "R6" and item:IsA("Folder") then
                for _, r6Item in ipairs(item:GetChildren()) do
                    if r6Item:IsA("CharacterMesh") then
                        r6Item:Clone().Parent = char
                    elseif r6Item:IsA("DataModelMesh") then 
                        if head then
                            for _, oldMesh in ipairs(head:GetChildren()) do
                                if oldMesh:IsA("DataModelMesh") then oldMesh:Destroy() end
                            end
                            r6Item:Clone().Parent = head
                        end
                    end
                end
            elseif item:IsA("CharacterMesh") then
                item:Clone().Parent = char
            end
        end
        
        appearanceModel:Destroy()

        -- 5. === FALLBACK ESTRICTO DE CARA ===
        if isReset then
            if head and not head:FindFirstChildOfClass("Decal") then
                local defaultFace = Instance.new("Decal")
                defaultFace.Name = "face"
                defaultFace.Texture = "rbxasset://textures/face.png"
                defaultFace.Parent = head
            end
            return 
        end

        local isR6 = (hum.RigType == Enum.HumanoidRigType.R6)
        if isR6 and head and not loadedFace then
            local errFace = Instance.new("Decal")
            errFace.Name = "face"
            errFace.Face = Enum.NormalId.Front
            errFace.Texture = "rbxthumb://type=Asset&id=7084675103&w=420&h=420" 
            errFace.Parent = head
        end
    end)
end

local function reset_to_original()
    if not _lplr then return end
    local myName = _lplr.Name
    lastUsername = nil 
    apply_avatar(myName, true)
end

-----------------------------------
-- MÉTODOS DEL MÓDULO -------------
-----------------------------------
function M.Stop()
    _active = false
    
    -- Restaura avatar original si estaba cambiado
    if _lplr then
        reset_to_original()
    end

    -- Desconecta todos los eventos registrados
    for _, conn in ipairs(connections) do
        if conn and conn.Connected then conn:Disconnect() end
    end
    table.clear(connections)

    -- Destruye la GUI
    if gui and gui.Parent then
        gui:Destroy()
    end
    gui = nil
    mainFrame = nil
    playerImage = nil
end

function M.SetKey(kc)
    if _keys then _keys.Toggle = kc end
    toggleKey = kc or toggleKey
end

function M.Start(Keys, lplr)
    _keys = Keys
    _lplr = lplr or Players.LocalPlayer

    if _keys and _keys.Toggle then
        toggleKey = _keys.Toggle
    end

    local playerGui = _lplr:WaitForChild("PlayerGui")

    if _active or playerGui:FindFirstChild("AFO_AvatarChanger") then
        return
    end

    M.Stop()

    _active = true
    lastUsername = "Wiftor"
    isOpen = false

    -----------------------------------
    -- CREACIÓN DE LA INTERFAZ (GUI) --
    -----------------------------------
    gui = Instance.new("ScreenGui")
    gui.Name = "AFO_AvatarChanger"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = playerGui

    mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainPanel"
    mainFrame.Size = UDim2.new(0, 240, 0, 115)
    mainFrame.AnchorPoint = Vector2.new(1, 0)
    mainFrame.Position = UDim2.new(1, 300, 0, 190) -- Posición inicial fuera de pantalla
    mainFrame.BackgroundColor3 = C_BLACK
    mainFrame.BackgroundTransparency = 0.15
    mainFrame.BorderSizePixel = 0
    mainFrame.ZIndex = 10
    mainFrame.Parent = gui

    Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 8)

    local stroke = Instance.new("UIStroke", mainFrame)
    stroke.Color = C_PURPLE
    stroke.Thickness = 1
    stroke.Transparency = 0.5

    -- Botón Cerrar (X)
    local closeBtn = Instance.new("TextButton", mainFrame)
    closeBtn.Size = UDim2.new(0, 20, 0, 20)
    closeBtn.Position = UDim2.new(1, -25, 0, 10)
    closeBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
    closeBtn.BackgroundTransparency = 0.2
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 12
    closeBtn.Text = "X"
    closeBtn.BorderSizePixel = 0
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 4)

    -- Título
    local title = Instance.new("TextLabel", mainFrame)
    title.Size = UDim2.new(0, 150, 0, 20)
    title.Position = UDim2.new(0, 15, 0, 10)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    title.TextColor3 = C_TEXT
    title.Text = "Avatar Changer"
    title.TextXAlignment = Enum.TextXAlignment.Left

    -- TextBox
    local textBox = Instance.new("TextBox", mainFrame)
    textBox.Size = UDim2.new(0, 145, 0, 25)
    textBox.Position = UDim2.new(0, 15, 0, 40)
    textBox.BackgroundColor3 = Color3.fromRGB(20, 10, 40)
    textBox.BackgroundTransparency = 0.3
    textBox.TextColor3 = C_TEXT
    textBox.PlaceholderColor3 = C_SUB
    textBox.PlaceholderText = "Username..."
    textBox.Text = "Wiftor"
    textBox.Font = Enum.Font.Gotham
    textBox.TextSize = 12
    textBox.BorderSizePixel = 0
    textBox.ClearTextOnFocus = true
    Instance.new("UICorner", textBox).CornerRadius = UDim.new(0, 4)

    local boxStroke = Instance.new("UIStroke", textBox)
    boxStroke.Color = C_PURPLE
    boxStroke.Thickness = 1
    boxStroke.Transparency = 0.7

    -- Botón Apply
    local applyBtn = Instance.new("TextButton", mainFrame)
    applyBtn.Size = UDim2.new(0, 115, 0, 25)
    applyBtn.Position = UDim2.new(0, 15, 0, 75)
    applyBtn.BackgroundColor3 = Color3.fromRGB(80, 20, 140)
    applyBtn.BackgroundTransparency = 0.2
    applyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    applyBtn.Font = Enum.Font.GothamBold
    applyBtn.TextSize = 12
    applyBtn.Text = "Apply"
    applyBtn.BorderSizePixel = 0
    Instance.new("UICorner", applyBtn).CornerRadius = UDim.new(0, 4)

    -- Botón Rebobinar (Avatar Original)
    local rewindBtn = Instance.new("TextButton", mainFrame)
    rewindBtn.Size = UDim2.new(0, 25, 0, 25)
    rewindBtn.Position = UDim2.new(0, 135, 0, 75)
    rewindBtn.BackgroundColor3 = Color3.fromRGB(80, 20, 140)
    rewindBtn.BackgroundTransparency = 0.2
    rewindBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    rewindBtn.Font = Enum.Font.GothamBold
    rewindBtn.TextSize = 14
    rewindBtn.Text = "🔄"
    rewindBtn.BorderSizePixel = 0
    Instance.new("UICorner", rewindBtn).CornerRadius = UDim.new(0, 4)

    -- Contenedor de Imagen de Perfil
    local playerImgContainer = Instance.new("Frame", mainFrame)
    playerImgContainer.Name = "PlayerImgContainer"
    playerImgContainer.Size = UDim2.new(0, 55, 0, 55)
    playerImgContainer.Position = UDim2.new(1, -70, 0, 30)
    playerImgContainer.BackgroundColor3 = Color3.fromRGB(20, 10, 40)
    playerImgContainer.BackgroundTransparency = 0.3
    playerImgContainer.BorderSizePixel = 0
    playerImgContainer.ZIndex = 11
    Instance.new("UICorner", playerImgContainer).CornerRadius = UDim.new(1, 0)

    playerImage = Instance.new("ImageLabel", playerImgContainer)
    playerImage.Name = "PlayerImage"
    playerImage.Size = UDim2.new(1, 0, 1, 0)
    playerImage.BackgroundTransparency = 1
    playerImage.Image = ""
    playerImage.ZIndex = 12
    Instance.new("UICorner", playerImage).CornerRadius = UDim.new(1, 0)

    -----------------------------------
    -- LÓGICA DE INTERFAZ LOCAL -------
    -----------------------------------
    local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

    local function toggleGUI()
        isOpen = not isOpen
        local targetPos = isOpen and UDim2.new(1, -20, 0, 190) or UDim2.new(1, 300, 0, 190)
        local tween = TweenService:Create(mainFrame, tweenInfo, {Position = targetPos})
        tween:Play()
    end

    local function start_new_avatar(username)
        if username and username ~= "" then
            lastUsername = username
            apply_avatar(username, false)
        end
    end

    -----------------------------------
    -- EVENTOS Y CONEXIONES -----------
    -----------------------------------
    table.insert(connections, _lplr.CharacterAppearanceLoaded:Connect(function(char)
        if lastUsername and lastUsername ~= _lplr.Name then
            apply_avatar(lastUsername, false)
        end
    end))

    table.insert(connections, applyBtn.MouseButton1Click:Connect(function()
        start_new_avatar(textBox.Text)
    end))

    table.insert(connections, textBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then start_new_avatar(textBox.Text) end
    end))

    table.insert(connections, textBox.Focused:Connect(function()
        textBox.Text = ""
    end))

    table.insert(connections, rewindBtn.MouseButton1Click:Connect(function()
        local myName = _lplr.Name
        textBox.Text = myName
        reset_to_original()
    end))

    table.insert(connections, closeBtn.MouseButton1Click:Connect(function()
        M.Stop()
    end))

    table.insert(connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == toggleKey then
            toggleGUI()
        end
    end))

    -- Carga inicial del avatar por defecto y despliegue del GUI
    task.spawn(function()
        start_new_avatar("Wiftor")
    end)
    
    toggleGUI()
end

return M
