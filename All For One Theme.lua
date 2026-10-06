-- ═══════════════════════════════════════════════════════════════════════════
--  ALL FOR ONE THEME - V6 (Corrección Definitiva)
--  Colores integrados (Morado, Negro, Rojo, Amarillo). Niebla implementada.
--  Rayos horizontales múltiples. Sistema de censura "Villain" respetado.
-- ═══════════════════════════════════════════════════════════════════════════
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Theme = {
    -- Paleta principal All For One (Morado, Negro, Rojo, Amarillo)
    Accent = Color3.fromRGB(165, 20, 220),
    GlowColor = Color3.fromRGB(180, 20, 255),
    Crimson = Color3.fromRGB(220, 20, 60),
    Yellow = Color3.fromRGB(255, 215, 0),
    DarkMatter = Color3.fromRGB(12, 6, 18),
    
    IconColor = Color3.fromRGB(225, 130, 255),
    IconSize = 18,
    
    AcrylicMain = Color3.fromRGB(8, 4, 12), -- Más oscuro (Negro/Morado)
    AcrylicBorder = Color3.fromRGB(80, 10, 110),
    
    -- Degradado de fondo priorizando Negro, Morado y destellos Rojos
    AcrylicGradient = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(10, 5, 15)),     -- Negro
        ColorSequenceKeypoint.new(0.35, Color3.fromRGB(70, 8, 115)), -- Morado
        ColorSequenceKeypoint.new(0.65, Color3.fromRGB(80, 10, 25)), -- Rojo Oscuro
        ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 5, 15)),     -- Negro
    }),
    AcrylicNoise = 0.65,
    TitleBarLine = Color3.fromRGB(100, 10, 145),
    
    Tab = Color3.fromRGB(18, 8, 26),
    Element = Color3.fromRGB(14, 6, 20),
    ElementBorder = Color3.fromRGB(80, 8, 120),
    InElementBorder = Color3.fromRGB(125, 15, 180),
    ElementTransparency = 0.85,
    
    ToggleSlider = Color3.fromRGB(38, 15, 58),
    ToggleToggled = Color3.fromRGB(165, 20, 220),
    SliderRail = Color3.fromRGB(38, 15, 58),
    
    DropdownFrame = Color3.fromRGB(12, 6, 18),
    DropdownHolder = Color3.fromRGB(6, 3, 10),
    DropdownBorder = Color3.fromRGB(80, 8, 120),
    DropdownOption = Color3.fromRGB(18, 8, 26),
    Keybind = Color3.fromRGB(18, 8, 26),
    
    Input = Color3.fromRGB(12, 6, 18),
    InputFocused = Color3.fromRGB(6, 3, 10),
    InputIndicator = Color3.fromRGB(125, 15, 180),
    
    Dialog = Color3.fromRGB(12, 6, 18),
    DialogHolder = Color3.fromRGB(6, 3, 10),
    DialogHolderLine = Color3.fromRGB(80, 8, 120),
    DialogButton = Color3.fromRGB(14, 6, 20),
    DialogButtonBorder = Color3.fromRGB(80, 8, 120),
    DialogBorder = Color3.fromRGB(80, 8, 120),
    DialogInput = Color3.fromRGB(12, 6, 18),
    DialogInputLine = Color3.fromRGB(125, 15, 180),
    
    Text = Color3.fromRGB(244, 235, 250),
    SubText = Color3.fromRGB(185, 150, 215),
    Hover = Color3.fromRGB(48, 20, 68),
    HoverChange = 0.05,
    
    ShineEnabled = false,
    StrokeShine = false,
    StrokeDark = Color3.fromRGB(40, 5, 60),
    
    ButtonGradient = {
        Background = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 8, 70)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 4, 30)),
        }),
        Stroke = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 10, 145)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(220, 20, 60)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 215, 0)),
        }),
    },
}

Theme.Assets = {
    BannerId = "rbxassetid://135276561043104",
    BannerImageTransparency = 0.65,
    TintTransparency = 0.40,
    LightningTexture = "rbxassetid://96766676523858",
    FogTexture = "rbxassetid://2118357406" -- Textura de niebla densa
}

Theme.BuildDesign = function(Window)
    local Root = Window.Root
    local acrylicFrame = Window.AcrylicPaint.Frame

    ---------------------------------------------------------------------
    -- 1) Banner, Tintado y Sistema de Niebla (Fog)
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

    -- Niebla Ambiental Lenta
    local fogLayer = Instance.new("ImageLabel")
    fogLayer.Name = "AFOFog"
    fogLayer.BackgroundTransparency = 1
    fogLayer.Image = Theme.Assets.FogTexture
    fogLayer.ImageColor3 = Theme.GlowColor
    fogLayer.ImageTransparency = 0.75
    fogLayer.Size = UDim2.fromScale(2, 2)
    fogLayer.ZIndex = 2
    fogLayer.Parent = art

    task.spawn(function()
        while task.wait() do
            if not Root then break end
            local t = tick() * 0.05
            fogLayer.Position = UDim2.new(-0.5 + math.sin(t) * 0.1, 0, -0.5 + math.cos(t) * 0.1, 0)
        end
    end)

    local tint = Instance.new("Frame")
    tint.Name = "DarkTint"
    tint.BackgroundColor3 = Theme.DarkMatter
    tint.BackgroundTransparency = Theme.Assets.TintTransparency
    tint.BorderSizePixel = 0
    tint.Size = UDim2.fromScale(1, 1)
    tint.ZIndex = 3
    tint.Parent = art

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
        TweenInfo.new(10, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        { Offset = Vector2.new(0.5, 0) }
    ):Play()

    ---------------------------------------------------------------------
    -- 3) Efecto de Rayos Múltiples (Estrictamente Horizontales)
    ---------------------------------------------------------------------
    local SparksLayer = Instance.new("Frame")
    SparksLayer.Name = "AFO_LightningStrikes"
    SparksLayer.Size = UDim2.fromScale(1, 1)
    SparksLayer.BackgroundTransparency = 1
    SparksLayer.ZIndex = 4
    SparksLayer.Parent = art

    local powerColors = {
        Theme.GlowColor, -- Morado
        Theme.Crimson,   -- Rojo
        Theme.Yellow,    -- Amarillo
        Color3.fromRGB(150, 150, 150) -- Quirk Cinético (Blanco/Gris)
    }

    task.spawn(function()
        while task.wait(math.random(2, 6) * 0.1) do
            if not Root or not Root.Parent then break end
            
            local strike = Instance.new("ImageLabel")
            strike.BackgroundTransparency = 1
            strike.Image = Theme.Assets.LightningTexture
            strike.ImageColor3 = powerColors[math.random(1, #powerColors)]
            
            -- Dimensiones horizontales puras (Ancho masivo, altura contenida)
            local w = math.random(800, 1500)
            local h = math.random(20, 60)
            strike.Size = UDim2.new(0, w, 0, h)
            
            -- Aparecen cruzando de izquierda a derecha (0 o 180 grados, nunca verticales)
            strike.Rotation = math.random() > 0.5 and 0 or 180
            strike.Position = UDim2.new(math.random(-50, 50)/100, 0, math.random(5, 95)/100, 0)
            strike.ImageTransparency = 0
            strike.Parent = SparksLayer

            TweenService:Create(strike, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, w * 1.8, 0, h * 0.2),
                ImageTransparency = 1
            }):Play()

            game:GetService("Debris"):AddItem(strike, 0.3)
        end
    end)

    ---------------------------------------------------------------------
    -- 4) Borde Corrupto/Glitch (Reemplazo de la barra neón simple)
    ---------------------------------------------------------------------
    local stroke = Root:FindFirstChildOfClass("UIStroke")
    if not stroke then
        stroke = Instance.new("UIStroke")
        stroke.Parent = Root
    end
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Color = Color3.new(1, 1, 1) -- Se sobreescribe con el gradiente

    -- Degradado en el borde para eliminar la sensación de color plano
    local strokeGradient = stroke:FindFirstChildOfClass("UIGradient")
    if not strokeGradient then
        strokeGradient = Instance.new("UIGradient")
        strokeGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Theme.Crimson),
            ColorSequenceKeypoint.new(0.3, Theme.GlowColor),
            ColorSequenceKeypoint.new(0.7, Theme.Yellow),
            ColorSequenceKeypoint.new(1, Theme.Crimson)
        })
        strokeGradient.Parent = stroke
    end

    local shadow = Root:FindFirstChildOfClass("UIShadow")
    if not shadow then
        shadow = Instance.new("UIShadow")
        shadow.Parent = Root
    end
    shadow.Color = Theme.GlowColor
    shadow.BlurRadius = UDim.new(0, 60)
    shadow.ZIndex = -1

    local timeX = 0
    RunService.RenderStepped:Connect(function(dt)
        timeX = timeX + (dt * 5.0) 
        local noise = math.noise(timeX, 0, 0)
        
        -- Ruido visual tipo glitch en el borde
        if stroke then
            local glitchSpike = (math.random() > 0.95) and math.random(2, 6) or 0
            stroke.Thickness = 2 + math.abs(noise * 3) + glitchSpike
            strokeGradient.Rotation = (timeX * 20) % 360
        end
        
        if shadow then
            shadow.Transparency = 0.15 + math.abs(noise * 0.3)
            shadow.Spread = 10 + (noise * 8)
            -- Intercambio sutil de sombras según el ruido
            shadow.Color = noise > 0.4 and Theme.Crimson or Theme.GlowColor
        end
    end)

    ---------------------------------------------------------------------
    -- 5) Correcciones Textuales: Título, Bolita Carmesí y Sistema Villain
    ---------------------------------------------------------------------
    task.spawn(function()
        task.wait(0.5) 
        if not Root then return end

        for _, obj in pairs(Root:GetDescendants()) do
            
            -- Bolita de versión (Identificada por el tamaño diminuto estándar de Fluent o su color)
            if obj:IsA("Frame") and (obj.Size == UDim2.new(0, 6, 0, 6) or (obj.BackgroundColor3.G > 0.5 and obj.BackgroundColor3.R < 0.3)) then
                if obj.Parent and obj.Parent.Name:match("Title") then
                    obj.BackgroundColor3 = Theme.Crimson
                end
            end

            if obj:IsA("TextLabel") then
                -- Titulo Exacto "All For One (2.0)"
                if obj.Text:lower():find("all for one") then
                    obj.Text = "All For One (2.0)"
                    obj.Font = Enum.Font.GothamBlack
                    obj.TextSize = 18
                end

                -- Integración con el Sistema de Censura "Villain" (Reemplaza a Anonymous)
                if obj.Text == "Anonymous" or obj.Text:match("Villain") or obj.Text:find("Todo para Uno") then
                    -- Estado inicial censurado
                    obj.Text = "Villain"
                    obj.TextSize = 14
                    obj.Font = Enum.Font.GothamBold
                    
                    -- Escuchar cambios. Si Fluent restaura a "Anonymous", lo forzamos de vuelta a "Villain".
                    -- Si el usuario le da al ojito, Fluent pondrá su Username, lo cual permitimos.
                    obj:GetPropertyChangedSignal("Text"):Connect(function()
                        if obj.Text == "Anonymous" then
                            obj.Text = "Villain"
                        end
                    end)
                end
            end
        end
    end)
end

return Theme
