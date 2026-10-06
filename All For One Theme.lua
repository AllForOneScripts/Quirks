-- ═══════════════════════════════════════════════════════════════════════════
--  ALL FOR ONE THEME - V7 (Corrección Exacta)
--  Rayos horizontales lentos, Viñeta, Cenizas, Censura nativa y Título exacto.
-- ═══════════════════════════════════════════════════════════════════════════
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Theme = {
    Accent = Color3.fromRGB(165, 20, 220),
    GlowColor = Color3.fromRGB(180, 20, 255),
    Crimson = Color3.fromRGB(220, 20, 60),
    Yellow = Color3.fromRGB(255, 215, 0),
    DarkMatter = Color3.fromRGB(12, 6, 18),
    
    IconColor = Color3.fromRGB(225, 130, 255),
    IconSize = 18,
    
    AcrylicMain = Color3.fromRGB(8, 4, 12),
    AcrylicBorder = Color3.fromRGB(80, 10, 110),
    
    AcrylicGradient = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(10, 5, 15)),
        ColorSequenceKeypoint.new(0.35, Color3.fromRGB(70, 8, 115)),
        ColorSequenceKeypoint.new(0.65, Color3.fromRGB(80, 10, 25)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 5, 15)),
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
    FogTexture = "rbxassetid://2118357406",
    Vignette = "rbxassetid://182223762" -- Textura de viñeta oscura
}

Theme.BuildDesign = function(Window)
    local Root = Window.Root
    local acrylicFrame = Window.AcrylicPaint.Frame

    ---------------------------------------------------------------------
    -- 1) Atmósfera: Banner, Niebla, Viñeta y Cenizas
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

    local fogLayer = Instance.new("ImageLabel")
    fogLayer.Name = "AFOFog"
    fogLayer.BackgroundTransparency = 1
    fogLayer.Image = Theme.Assets.FogTexture
    fogLayer.ImageColor3 = Theme.GlowColor
    fogLayer.ImageTransparency = 0.85
    fogLayer.Size = UDim2.fromScale(2, 2)
    fogLayer.ZIndex = 2
    fogLayer.Parent = art

    task.spawn(function()
        while task.wait() do
            if not Root then break end
            local t = tick() * 0.03
            fogLayer.Position = UDim2.new(-0.5 + math.sin(t) * 0.1, 0, -0.5 + math.cos(t) * 0.1, 0)
        end
    end)

    -- Viñeta para concentrar la oscuridad
    local vignette = Instance.new("ImageLabel")
    vignette.BackgroundTransparency = 1
    vignette.Size = UDim2.fromScale(1, 1)
    vignette.Image = Theme.Assets.Vignette
    vignette.ImageColor3 = Theme.DarkMatter
    vignette.ImageTransparency = 0.2
    vignette.ZIndex = 5
    vignette.Parent = art

    -- Sistema de Cenizas Flotantes (Partículas oscuras)
    local ashLayer = Instance.new("Frame")
    ashLayer.BackgroundTransparency = 1
    ashLayer.Size = UDim2.fromScale(1, 1)
    ashLayer.ZIndex = 3
    ashLayer.Parent = art
    
    task.spawn(function()
        while task.wait(0.3) do
            if not Root or not Root.Parent then break end
            local ash = Instance.new("Frame")
            ash.BackgroundColor3 = Color3.fromRGB(5, 2, 10)
            ash.BorderSizePixel = 0
            local size = math.random(2, 4)
            ash.Size = UDim2.new(0, size, 0, size)
            ash.Position = UDim2.new(math.random(0, 100)/100, 0, 1.1, 0)
            ash.Rotation = math.random(0, 360)
            ash.Parent = ashLayer
            
            TweenService:Create(ash, TweenInfo.new(math.random(4, 7), Enum.EasingStyle.Linear), {
                Position = UDim2.new(ash.Position.X.Scale + math.random(-10, 10)/100, 0, -0.1, 0),
                Rotation = ash.Rotation + math.random(-180, 180),
                BackgroundTransparency = 1
            }):Play()
            game:GetService("Debris"):AddItem(ash, 8)
        end
    end)

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
    -- 3) Rayos Horizontales Lentos y Prolongados
    ---------------------------------------------------------------------
    local SparksLayer = Instance.new("Frame")
    SparksLayer.Name = "AFO_LightningStrikes"
    SparksLayer.Size = UDim2.fromScale(1, 1)
    SparksLayer.BackgroundTransparency = 1
    SparksLayer.ZIndex = 4
    SparksLayer.Parent = art

    local powerColors = { Theme.GlowColor, Theme.Crimson, Theme.Yellow, Color3.fromRGB(150, 150, 150) }

    task.spawn(function()
        while task.wait(math.random(4, 10) * 0.1) do
            if not Root or not Root.Parent then break end
            
            local strike = Instance.new("ImageLabel")
            strike.BackgroundTransparency = 1
            strike.Image = Theme.Assets.LightningTexture
            strike.ImageColor3 = powerColors[math.random(1, #powerColors)]
            
            local w = math.random(800, 1200)
            local h = math.random(25, 60)
            strike.Size = UDim2.new(0, w, 0, h)
            
            -- Lógica para atravesar la pantalla
            local isLeftToRight = math.random() > 0.5
            local startX = isLeftToRight and -0.8 or 1.8
            local endX = isLeftToRight and 1.8 or -0.8
            
            strike.Rotation = isLeftToRight and 0 or 180
            strike.Position = UDim2.new(startX, 0, math.random(10, 90)/100, 0)
            strike.ImageTransparency = 0
            strike.Parent = SparksLayer

            -- Tiempos mucho más lentos (1.5 a 3 segundos de duración)
            local travelTime = math.random(15, 30) / 10
            
            -- Movimiento físico de lado a lado
            TweenService:Create(strike, TweenInfo.new(travelTime, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                Position = UDim2.new(endX, 0, strike.Position.Y.Scale, 0)
            }):Play()

            -- Fade out progresivo
            TweenService:Create(strike, TweenInfo.new(travelTime * 0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                ImageTransparency = 1,
                Size = UDim2.new(0, w * 1.5, 0, h * 0.3)
            }):Play()

            game:GetService("Debris"):AddItem(strike, travelTime + 0.5)
        end
    end)

    ---------------------------------------------------------------------
    -- 4) Borde Corrupto/Glitch
    ---------------------------------------------------------------------
    local stroke = Root:FindFirstChildOfClass("UIStroke")
    if not stroke then
        stroke = Instance.new("UIStroke")
        stroke.Parent = Root
    end
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Color = Color3.new(1, 1, 1)

    local strokeGradient = stroke:FindFirstChildOfClass("UIGradient") or Instance.new("UIGradient")
    strokeGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Theme.Crimson),
        ColorSequenceKeypoint.new(0.3, Theme.GlowColor),
        ColorSequenceKeypoint.new(0.7, Theme.Yellow),
        ColorSequenceKeypoint.new(1, Theme.Crimson)
    })
    strokeGradient.Parent = stroke

    local shadow = Root:FindFirstChildOfClass("UIShadow") or Instance.new("UIShadow")
    shadow.Color = Theme.GlowColor
    shadow.BlurRadius = UDim.new(0, 60)
    shadow.ZIndex = -1
    shadow.Parent = Root

    local timeX = 0
    RunService.RenderStepped:Connect(function(dt)
        timeX = timeX + (dt * 5.0) 
        local noise = math.noise(timeX, 0, 0)
        
        if stroke then
            local glitchSpike = (math.random() > 0.95) and math.random(2, 6) or 0
            stroke.Thickness = 2 + math.abs(noise * 3) + glitchSpike
            strokeGradient.Rotation = (timeX * 20) % 360
        end
        
        if shadow then
            shadow.Transparency = 0.15 + math.abs(noise * 0.3)
            shadow.Spread = 10 + (noise * 8)
            shadow.Color = noise > 0.4 and Theme.Crimson or Theme.GlowColor
        end
    end)

    ---------------------------------------------------------------------
    -- 5) Correcciones Textuales: Título Exacto y Censura "Villain"
    ---------------------------------------------------------------------
    task.spawn(function()
        task.wait(0.5) 
        if not Root then return end

        for _, obj in pairs(Root:GetDescendants()) do
            
            -- Bolita de versión (Interceptamos su tamaño estándar y la cambiamos a Rojo Carmesí)
            if obj:IsA("Frame") and obj.Size == UDim2.new(0, 6, 0, 6) then
                obj.BackgroundColor3 = Theme.Crimson
            end

            if obj:IsA("TextLabel") then
                
                -- FIJAR TÍTULO (Verificamos que esté en la parte superior para no tocar otras cosas)
                if obj.AbsolutePosition.Y < 50 and (obj.Text:lower():find("all for one") or obj.Text:lower():find("villain")) then
                    obj.Text = "All For One (2.0)"
                    obj.Font = Enum.Font.GothamBlack
                    obj.TextSize = 18
                end

                -- FIJAR SISTEMA DE CENSURA (Se intercepta SÓLO el estado "Anonymous")
                if obj.Text == "Anonymous" then
                    obj.Text = "Villain"
                    obj.TextSize = 14
                    obj.Font = Enum.Font.GothamBold
                    
                    -- Esto asegura que al darle al ojito se muestre tu nombre real.
                    -- Y si vuelves a censurarlo, Fluent intentará poner "Anonymous", pero esto lo cambiará a "Villain".
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
