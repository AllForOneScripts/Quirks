-- ═══════════════════════════════════════════════════════════════════════════
--  ALL FOR ONE THEME - OVERHAUL CAÓTICO Y SALVAJE (V5)
--  Dirección de arte: Energía oscura profunda, rayos inestables reales, bordes expansivos.
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
    
    -- Degradado Morado Puro, más profundo
    AcrylicGradient = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 5, 100)),
        ColorSequenceKeypoint.new(0.4, Color3.fromRGB(15, 4, 25)),
        ColorSequenceKeypoint.new(0.6, Color3.fromRGB(35, 4, 65)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(5, 2, 10)),
    }),
    AcrylicNoise = 0.75,
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
    
    DropdownFrame = Color3.fromRGB(16, 6, 23),
    DropdownHolder = Color3.fromRGB(6, 3, 10),
    DropdownBorder = Color3.fromRGB(80, 8, 120),
    DropdownOption = Color3.fromRGB(24, 10, 34),
    Keybind = Color3.fromRGB(24, 10, 34),
    
    Input = Color3.fromRGB(16, 6, 23),
    InputFocused = Color3.fromRGB(6, 3, 10),
    InputIndicator = Color3.fromRGB(125, 15, 180),
    
    Dialog = Color3.fromRGB(16, 6, 23),
    DialogHolder = Color3.fromRGB(6, 3, 10),
    DialogHolderLine = Color3.fromRGB(80, 8, 120),
    DialogButton = Color3.fromRGB(19, 8, 28),
    DialogButtonBorder = Color3.fromRGB(80, 8, 120),
    DialogBorder = Color3.fromRGB(80, 8, 120),
    DialogInput = Color3.fromRGB(16, 6, 23),
    DialogInputLine = Color3.fromRGB(125, 15, 180),
    
    Text = Color3.fromRGB(244, 235, 250),
    SubText = Color3.fromRGB(185, 150, 215),
    Hover = Color3.fromRGB(48, 20, 68),
    HoverChange = 0.05,
    
    ShineEnabled = false,
    StrokeShine = false,
    StrokeDark = Color3.fromRGB(60, 5, 95),
    
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
    BannerImageTransparency = 0.8,
    TintTransparency = 0.15,
    LightningTexture = "rbxassetid://7151777149", -- Textura Vertical de Rayo actualizada
}

Theme.BuildDesign = function(Window)
    local Root = Window.Root
    local acrylicFrame = Window.AcrylicPaint.Frame

    ---------------------------------------------------------------------
    -- 1) Atmósfera Base y Viñeta de Energía Oscura
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

    -- Viñeta oscura expansiva (Da sensación de profundidad y arte)
    local vignette = Instance.new("ImageLabel")
    vignette.Name = "DarkVignette"
    vignette.BackgroundTransparency = 1
    vignette.Image = "rbxassetid://115456208168249" -- Sombra radial estándar
    vignette.ImageColor3 = Color3.fromRGB(0, 0, 0)
    vignette.Size = UDim2.fromScale(1, 1)
    vignette.ZIndex = 3
    vignette.ImageTransparency = 0.4
    vignette.Parent = art

    ---------------------------------------------------------------------
    -- 2) Fondo Deslizante Profundo
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
        TweenInfo.new(12, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        { Offset = Vector2.new(0.5, 0) }
    ):Play()

    ---------------------------------------------------------------------
    -- 3) Expansión Agresiva de Bordes (Stroke & Shadow)
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
    shadow.BlurRadius = UDim.new(0, 60) -- Blur base más alto
    shadow.ZIndex = -1

    -- Inestabilidad Amplificada
    local timeX = 0
    RunService.RenderStepped:Connect(function(dt)
        timeX = timeX + (dt * 6.5) 
        local noise = math.noise(timeX, 0, 0)
        
        -- Expansión masiva: El borde y la sombra reaccionan violentamente
        if stroke then
            stroke.Thickness = 2 + math.abs(noise * 7) -- Antes 3.5, ahora se expande el doble
        end
        if shadow then
            shadow.Transparency = 0.15 + math.abs(noise * 0.4)
            shadow.Spread = 5 + (math.abs(noise) * 15) -- Expansión dramática del aura
        end
        if vignette then
            vignette.ImageTransparency = 0.3 + math.abs(noise * 0.2)
        end
    end)

    ---------------------------------------------------------------------
    -- 4) Sistema de Descargas Eléctricas Reales
    ---------------------------------------------------------------------
    local LightningLayer = Instance.new("Frame")
    LightningLayer.Name = "AFO_Lightning"
    LightningLayer.Size = UDim2.fromScale(1, 1)
    LightningLayer.BackgroundTransparency = 1
    LightningLayer.ZIndex = 5
    LightningLayer.ClipsDescendants = true
    LightningLayer.Parent = art

    -- Función para simular un "flash" de rayo real
    local function flashLightning(bolt)
        bolt.ImageTransparency = 0
        task.wait(math.random(2, 5) * 0.01)
        bolt.ImageTransparency = 0.8
        task.wait(math.random(1, 3) * 0.01)
        bolt.ImageTransparency = 0.2
        
        TweenService:Create(bolt, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            ImageTransparency = 1,
            Size = UDim2.new(bolt.Size.X.Scale, bolt.Size.X.Offset * 1.5, bolt.Size.Y.Scale, bolt.Size.Y.Offset * 1.2)
        }):Play()
        
        game:GetService("Debris"):AddItem(bolt, 0.25)
    end

    task.spawn(function()
        while task.wait(math.random(1, 8) * 0.05) do -- Rayos caóticos
            if not Root or not Root.Parent then break end
            
            local isCrimson = math.random() > 0.65
            local bolt = Instance.new("ImageLabel")
            bolt.Image = Theme.Assets.LightningTexture
            bolt.BackgroundTransparency = 1
            bolt.ImageColor3 = isCrimson and Theme.CrimsonGlow or Theme.GlowColor
            bolt.ImageTransparency = 1
            
            -- Posicionamiento Aleatorio en Bordes
            local edge = math.random(1, 4)
            local boltWidth = math.random(20, 60)
            local boltLength = math.random(150, 400)
            
            if edge == 1 then -- Arriba
                bolt.Size = UDim2.new(0, boltLength, 0, boltWidth)
                bolt.Position = UDim2.new(math.random(), 0, 0, -boltWidth/2)
                bolt.Rotation = 90 + math.random(-10, 10)
            elseif edge == 2 then -- Abajo
                bolt.Size = UDim2.new(0, boltLength, 0, boltWidth)
                bolt.Position = UDim2.new(math.random(), 0, 1, -boltWidth/2)
                bolt.Rotation = 90 + math.random(-10, 10)
            elseif edge == 3 then -- Izquierda
                bolt.Size = UDim2.new(0, boltWidth, 0, boltLength)
                bolt.Position = UDim2.new(0, -boltWidth/2, math.random(), 0)
                bolt.Rotation = math.random(-10, 10)
            else -- Derecha
                bolt.Size = UDim2.new(0, boltWidth, 0, boltLength)
                bolt.Position = UDim2.new(1, -boltWidth/2, math.random(), 0)
                bolt.Rotation = math.random(-10, 10)
            end
            
            bolt.Parent = LightningLayer
            task.spawn(flashLightning, bolt)
        end
    end)

    ---------------------------------------------------------------------
    -- 5) Parche de Título y Bolita de Versión
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
    -- 6) Limpieza de Perfil (UserCard: Eliminar Subtítulo)
    ---------------------------------------------------------------------
    task.spawn(function()
        task.wait(1.0) -- Esperar a que la UI de Fluent se arme
        if not Root then return end

        local userCard
        -- Buscamos el contenedor del perfil guiándonos por el Avatar
        for _, obj in pairs(Root:GetDescendants()) do
            if obj:IsA("ImageLabel") and obj.Image:match("rbxthumb") then
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
                -- Ordenar por posición Y para saber cuál está arriba y cuál abajo
                table.sort(labels, function(a, b) return a.AbsolutePosition.Y < b.AbsolutePosition.Y end)
                
                local topLabel = labels[1]
                local bottomLabel = labels[2]

                -- Destruimos la segunda línea de texto por completo
                if bottomLabel then
                    bottomLabel.Visible = false
                    bottomLabel:Destroy()
                end

                -- Centramos y ajustamos la línea principal
                if topLabel then
                    topLabel.Size = UDim2.new(1, 0, 1, 0)
                    topLabel.TextYAlignment = Enum.TextYAlignment.Center
                    topLabel.TextScaled = true
                    
                    local constraint = Instance.new("UITextSizeConstraint")
                    constraint.MaxTextSize = 15 -- Evita que nombres cortos se vean gigantes
                    constraint.Parent = topLabel
                end
            end
        end
    end)
end

return Theme
