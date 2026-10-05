-- ═══════════════════════════════════════════════════════════════════════════
--  ALL FOR ONE THEME - OVERHAUL CAÓTICO Y SALVAJE (V4)
--  Dirección de arte: Energía oscura inestable, múltiples quirks chocando.
--  Incluye: Perfil hackeado (Censura por defecto, Auto-escala, @Username real).
-- ═══════════════════════════════════════════════════════════════════════════
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Theme = {
    Accent = Color3.fromRGB(165, 20, 220),
    GlowColor = Color3.fromRGB(180, 20, 255),
    CrimsonGlow = Color3.fromRGB(220, 20, 60), 
    
    IconColor = Color3.fromRGB(225, 130, 255),
    IconSize = 18,
    
    AcrylicMain = Color3.fromRGB(12, 6, 18),
    AcrylicBorder = Color3.fromRGB(100, 10, 145),
    
    -- Degradado Morado Puro (sin rojo)
    AcrylicGradient = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(70, 8, 115)),
        ColorSequenceKeypoint.new(0.35, Color3.fromRGB(18, 6, 30)),
        ColorSequenceKeypoint.new(0.65, Color3.fromRGB(45, 5, 80)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(8, 3, 14)),
    }),
    AcrylicNoise = 0.65,
    TitleBarLine = Color3.fromRGB(100, 10, 145),
    
    -- Estructura
    Tab = Color3.fromRGB(24, 10, 34),
    Element = Color3.fromRGB(19, 8, 28),
    ElementBorder = Color3.fromRGB(80, 8, 120),
    InElementBorder = Color3.fromRGB(125, 15, 180),
    ElementTransparency = 0.85,
    
    -- Controles
    ToggleSlider = Color3.fromRGB(38, 15, 58),
    ToggleToggled = Color3.fromRGB(165, 20, 220),
    SliderRail = Color3.fromRGB(38, 15, 58),
    
    -- Dropdown
    DropdownFrame = Color3.fromRGB(16, 6, 23),
    DropdownHolder = Color3.fromRGB(6, 3, 10),
    DropdownBorder = Color3.fromRGB(80, 8, 120),
    DropdownOption = Color3.fromRGB(24, 10, 34),
    Keybind = Color3.fromRGB(24, 10, 34),
    
    -- Inputs
    Input = Color3.fromRGB(16, 6, 23),
    InputFocused = Color3.fromRGB(6, 3, 10),
    InputIndicator = Color3.fromRGB(125, 15, 180),
    
    -- Diálogos
    Dialog = Color3.fromRGB(16, 6, 23),
    DialogHolder = Color3.fromRGB(6, 3, 10),
    DialogHolderLine = Color3.fromRGB(80, 8, 120),
    DialogButton = Color3.fromRGB(19, 8, 28),
    DialogButtonBorder = Color3.fromRGB(80, 8, 120),
    DialogBorder = Color3.fromRGB(80, 8, 120),
    DialogInput = Color3.fromRGB(16, 6, 23),
    DialogInputLine = Color3.fromRGB(125, 15, 180),
    
    -- Texto
    Text = Color3.fromRGB(244, 235, 250),
    SubText = Color3.fromRGB(185, 150, 215),
    Hover = Color3.fromRGB(48, 20, 68),
    HoverChange = 0.05,
    
    ShineEnabled = false,
    Shine = {
        Speed = 0,
        RotationSpeed = 0,
        ColorSequence = ColorSequence.new(Color3.fromRGB(165, 20, 220)),
    },
    StrokeShine = false,
    StrokeDark = Color3.fromRGB(60, 5, 95),
    
    -- Botones
    ButtonGradient = {
        Background = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(52, 10, 85)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(22, 4, 40)),
        }),
        Stroke = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 10, 145)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(220, 20, 60)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 10, 145)),
        }),
    },
}

Theme.Assets = {
    BannerId = "rbxassetid://135276561043104",
    BannerImageTransparency = 0.75,
    TintTransparency = 0.25,
    LightningTexture = "rbxassetid://96766676523858",
}

Theme.BuildDesign = function(Window)
    local Root = Window.Root
    local acrylicFrame = Window.AcrylicPaint.Frame

    ---------------------------------------------------------------------
    -- 1) Banner y Tintado Oscuro (Morado puro)
    ---------------------------------------------------------------------
    local art = Instance.new("Frame")
    art.Name = "AllForOneArt"
    art.BackgroundTransparency = 1
    art.ClipsDescendants = true
    art.Size = UDim2.fromScale(1, 1)
    art.Parent = acrylicFrame

    local artCorner = Instance.new("UICorner")
    artCorner.CornerRadius = UDim.new(0, 10)
    artCorner.Parent = art

    local banner = Instance.new("ImageLabel")
    banner.Name = "Banner"
    banner.BackgroundTransparency = 1
    banner.Image = Theme.Assets.BannerId
    banner.ScaleType = Enum.ScaleType.Crop
    banner.Size = UDim2.fromScale(1, 1)
    banner.ImageTransparency = Theme.Assets.BannerImageTransparency
    banner.ZIndex = 1
    banner.Parent = art

    local tint = Instance.new("Frame")
    tint.Name = "PurpleTint"
    tint.BackgroundColor3 = Theme.AcrylicBorder
    tint.BackgroundTransparency = Theme.Assets.TintTransparency
    tint.BorderSizePixel = 0
    tint.Size = UDim2.fromScale(1, 1)
    tint.ZIndex = 2
    tint.Parent = art

    local tintGradient = Instance.new("UIGradient")
    tintGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Theme.AcrylicBorder),
        ColorSequenceKeypoint.new(1, Theme.AcrylicMain),
    })
    tintGradient.Rotation = 90
    tintGradient.Parent = tint

    ---------------------------------------------------------------------
    -- 2) Fondo Base Deslizante
    ---------------------------------------------------------------------
    local bgGradient = acrylicFrame:FindFirstChildOfClass("UIGradient")
    if not bgGradient then
        bgGradient = Instance.new("UIGradient")
        bgGradient.Color = Theme.AcrylicGradient
        bgGradient.Rotation = 115
        bgGradient.Parent = acrylicFrame
    end
    TweenService:Create(
        bgGradient,
        TweenInfo.new(8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        { Offset = Vector2.new(0.4, 0) }
    ):Play()

    ---------------------------------------------------------------------
    -- 3) Sistema de Chispas Residuales Rápidas
    ---------------------------------------------------------------------
    local SparksLayer = Instance.new("Frame")
    SparksLayer.Name = "AFO_Sparks"
    SparksLayer.Size = UDim2.fromScale(1, 1)
    SparksLayer.BackgroundTransparency = 1
    SparksLayer.ZIndex = 3
    SparksLayer.Parent = art

    task.spawn(function()
        while task.wait(math.random(2, 5) * 0.02) do
            if not Root or not Root.Parent then break end
            local spark = Instance.new("Frame")
            spark.BackgroundColor3 = math.random() > 0.5 and Theme.CrimsonGlow or Theme.GlowColor
            spark.BorderSizePixel = 0
            spark.Size = UDim2.new(0, math.random(15, 80), 0, math.random(1, 4))
            spark.Position = UDim2.new(math.random(), 0, math.random(), 0)
            spark.Rotation = math.random(-35, 35)
            spark.BackgroundTransparency = 0.1
            spark.Parent = SparksLayer

            TweenService:Create(spark, TweenInfo.new(math.random(2, 5) * 0.1, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, math.random(150, 400), 0, 0),
                BackgroundTransparency = 1,
                Position = spark.Position + UDim2.new(math.random(-20, 20)/100, 0, math.random(-20, 20)/100, 0)
            }):Play()

            game:GetService("Debris"):AddItem(spark, 0.6)
        end
    end)

    ---------------------------------------------------------------------
    -- 4) Estructuras UI Visuales (Shadow y Stroke)
    ---------------------------------------------------------------------
    local stroke = Root:FindFirstChildOfClass("UIStroke")
    if not stroke then
        stroke = Instance.new("UIStroke")
        stroke.Parent = Root
    end
    stroke.Color = Theme.GlowColor
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    local shadow = Root:FindFirstChildOfClass("UIShadow")
    if not shadow then
        shadow = Instance.new("UIShadow")
        shadow.Parent = Root
    end
    shadow.Color = Theme.GlowColor
    shadow.BlurRadius = UDim.new(0, 45)
    shadow.Offset = UDim2.new(0, 0, 0, 0)
    shadow.ZIndex = -1

    ---------------------------------------------------------------------
    -- 5) Inestabilidad (Ruido Perlin)
    ---------------------------------------------------------------------
    local timeX = 0
    RunService.RenderStepped:Connect(function(dt)
        timeX = timeX + (dt * 5.0) 
        local noise = math.noise(timeX, 0, 0)
        
        if stroke then
            stroke.Thickness = 2 + math.abs(noise * 3.5)
        end
        if shadow then
            shadow.Transparency = 0.25 + math.abs(noise * 0.3)
            shadow.Spread = 4 + (noise * 4)
        end
    end)

    ---------------------------------------------------------------------
    -- 6) Rayos Morados y Carmesí Entrelazados Rápidos
    ---------------------------------------------------------------------
    local STRIP_THICKNESS = 6
    local TILE_SIZE = 96
    local SCROLL_TIME = 1.8 

    local function makeEdge(name, size, position, horizontal, color, speed, reverse)
        local mask = Instance.new("Frame")
        mask.Name = name
        mask.BackgroundTransparency = 1
        mask.ClipsDescendants = true
        mask.Size = size
        mask.Position = position
        mask.ZIndex = 50
        mask.Active = false
        mask.Parent = Root

        local img = Instance.new("ImageLabel")
        img.BackgroundTransparency = 1
        img.Image = Theme.Assets.LightningTexture
        img.ImageColor3 = color
        img.ScaleType = Enum.ScaleType.Tile
        
        local goal
        if horizontal then
            img.Size = UDim2.new(2, 0, 1, 0)
            img.TileSize = UDim2.new(0, TILE_SIZE, 1, 0)
            if reverse then
                img.Position = UDim2.new(-1, 0, 0, 0)
                goal = UDim2.new(0, 0, 0, 0)
            else
                goal = UDim2.new(-1, 0, 0, 0)
            end
        else
            img.Size = UDim2.new(1, 0, 2, 0)
            img.TileSize = UDim2.new(1, 0, 0, TILE_SIZE)
            if reverse then
                img.Position = UDim2.new(0, 0, -1, 0)
                goal = UDim2.new(0, 0, 0, 0)
            else
                goal = UDim2.new(0, 0, -1, 0)
            end
        end
        img.Parent = mask

        TweenService:Create(
            img,
            TweenInfo.new(speed, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1, false),
            { Position = goal }
        ):Play()
    end

    makeEdge("BoltTop_P", UDim2.new(1, 0, 0, STRIP_THICKNESS), UDim2.new(0, 0, 0, 0), true, Theme.GlowColor, SCROLL_TIME, false)
    makeEdge("BoltBottom_P", UDim2.new(1, 0, 0, STRIP_THICKNESS), UDim2.new(0, 0, 1, -STRIP_THICKNESS), true, Theme.GlowColor, SCROLL_TIME, false)
    makeEdge("BoltLeft_P", UDim2.new(0, STRIP_THICKNESS, 1, 0), UDim2.new(0, 0, 0, 0), false, Theme.GlowColor, SCROLL_TIME, false)
    makeEdge("BoltRight_P", UDim2.new(0, STRIP_THICKNESS, 1, 0), UDim2.new(1, -STRIP_THICKNESS, 0, 0), false, Theme.GlowColor, SCROLL_TIME, false)

    makeEdge("BoltTop_C", UDim2.new(1, 0, 0, STRIP_THICKNESS), UDim2.new(0, 0, 0, 0), true, Theme.CrimsonGlow, SCROLL_TIME * 0.8, true)
    makeEdge("BoltBottom_C", UDim2.new(1, 0, 0, STRIP_THICKNESS), UDim2.new(0, 0, 1, -STRIP_THICKNESS), true, Theme.CrimsonGlow, SCROLL_TIME * 0.8, true)
    makeEdge("BoltLeft_C", UDim2.new(0, STRIP_THICKNESS, 1, 0), UDim2.new(0, 0, 0, 0), false, Theme.CrimsonGlow, SCROLL_TIME * 0.8, true)
    makeEdge("BoltRight_C", UDim2.new(0, STRIP_THICKNESS, 1, 0), UDim2.new(1, -STRIP_THICKNESS, 0, 0), false, Theme.CrimsonGlow, SCROLL_TIME * 0.8, true)

    ---------------------------------------------------------------------
    -- 7) Parche de Título y Bolita de Versión
    ---------------------------------------------------------------------
    task.spawn(function()
        task.wait(0.5) 
        if not Root then return end

        for _, obj in pairs(Root:GetDescendants()) do
            if obj:IsA("TextLabel") and obj.Text:find("Todo para Uno") then
                obj.Text = obj.Text:gsub("Todo para Uno", "") 
            end
            
            if obj:IsA("Frame") and obj.BackgroundColor3.G > 0.5 and obj.BackgroundColor3.R < 0.3 then
                for _, child in pairs(obj:GetChildren()) do
                    if child:IsA("TextLabel") then
                        obj.BackgroundColor3 = Theme.CrimsonGlow
                        break
                    end
                end
            end
        end
    end)

    ---------------------------------------------------------------------
    -- 8) Modificación Hacking del Perfil de Usuario (UserCard)
    ---------------------------------------------------------------------
    task.spawn(function()
        task.wait(1.5) -- Tiempo prudente para que Fluent arme el UserCard
        if not Root then return end

        local player = game:GetService("Players").LocalPlayer
        local realDisplay = player.DisplayName
        local realUser = "@" .. player.Name

        local userCard
        for _, obj in pairs(Root:GetDescendants()) do
            if obj:IsA("ImageLabel") and obj.Image:match("rbxthumb") then
                -- Escalar un par de niveles hasta agarrar el contenedor principal que tiene los textos
                local current = obj.Parent
                local levels = 0
                while current and current ~= Root and levels < 3 do
                    local txtCount = 0
                    for _, child in pairs(current:GetDescendants()) do
                        if child:IsA("TextLabel") then txtCount = txtCount + 1 end
                    end
                    if txtCount >= 2 then
                        userCard = current
                        break
                    end
                    current = current.Parent
                    levels = levels + 1
                end
                break
            end
        end

        if userCard then
            local labels = {}
            for _, obj in pairs(userCard:GetDescendants()) do
                if obj:IsA("TextLabel") then
                    table.insert(labels, obj)
                end
            end
            
            if #labels >= 2 then
                -- El Y absoluto más bajo pertenece al título (arriba)
                table.sort(labels, function(a, b) return a.AbsolutePosition.Y < b.AbsolutePosition.Y end)
                
                local topLabel = labels[1]
                local bottomLabel = labels[2]

                -- Auto-escalado para nombres largos
                topLabel.TextScaled = true
                bottomLabel.TextScaled = true

                -- Limitador para evitar textos gigantes en nombres cortos
                local topConstraint = Instance.new("UITextSizeConstraint")
                topConstraint.MaxTextSize = 14
                topConstraint.Parent = topLabel

                local bottomConstraint = Instance.new("UITextSizeConstraint")
                bottomConstraint.MaxTextSize = 13
                bottomConstraint.Parent = bottomLabel
                
                -- Estado Lógico
                local isAnonymous = true
                local isUpdating = false

                local function applyState()
                    isUpdating = true
                    if isAnonymous then
                        topLabel.Text = "Anonymous"
                        bottomLabel.Text = "Censurado"
                    else
                        topLabel.Text = realDisplay
                        bottomLabel.Text = realUser
                    end
                    isUpdating = false
                end

                -- Bloqueador de Sobreescritura (Ignora los cambios nativos de Fluent)
                topLabel:GetPropertyChangedSignal("Text"):Connect(function()
                    if not isUpdating and topLabel.Text ~= "Anonymous" and topLabel.Text ~= realDisplay then
                        applyState()
                    end
                end)

                -- Interceptar clics en el botón de privacidad (el ojito de Fluent)
                for _, obj in pairs(userCard:GetDescendants()) do
                    if obj:IsA("ImageLabel") and not obj.Image:match("rbxthumb") then
                        local btn = obj.Parent
                        if btn then
                            if btn:IsA("TextButton") or btn:IsA("ImageButton") then
                                btn.MouseButton1Click:Connect(function()
                                    isAnonymous = not isAnonymous
                                    applyState()
                                end)
                            elseif btn:IsA("Frame") then
                                btn.InputBegan:Connect(function(input)
                                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                                        isAnonymous = not isAnonymous
                                        applyState()
                                    end
                                end)
                            end
                        end
                    end
                end

                -- Estado por defecto (Inyección inicial)
                applyState()
            end
        end
    end)
end

return Theme
