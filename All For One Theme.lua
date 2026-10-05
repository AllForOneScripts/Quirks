-- ═══════════════════════════════════════════════════════════════════════════
--  ALL FOR ONE THEME - OVERHAUL CAÓTICO Y SALVAJE (VERSIÓN CORREGIDA)
--  Dirección de arte: Energía oscura inestable, múltiples quirks chocando.
--  Indicador superior izquierdo cambiado directamente a rojo carmesí.
-- ═══════════════════════════════════════════════════════════════════════════
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Theme = {
    -- Color de marca original
    Accent = Color3.fromRGB(165, 20, 220),
    -- Morado inestable para los quirks
    GlowColor = Color3.fromRGB(180, 20, 255),
    -- Rojo Carmesí puro de All For One
    CrimsonGlow = Color3.fromRGB(220, 20, 60), 
    
    IconColor = Color3.fromRGB(225, 130, 255),
    IconSize = 18,
    
    AcrylicMain = Color3.fromRGB(12, 6, 18),
    AcrylicBorder = Color3.fromRGB(100, 10, 145),
    
    -- Degradado corrompido: Morado -> Sangre -> Negro
    AcrylicGradient = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(70, 8, 115)),
        ColorSequenceKeypoint.new(0.3, Color3.fromRGB(15, 3, 20)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(90, 5, 20)), -- Inyección carmesí
        ColorSequenceKeypoint.new(0.7, Color3.fromRGB(30, 4, 45)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(5, 1, 8)),
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

-- ═══════════════════════════════════════════════════════════════════════════
--  Assets
-- ═══════════════════════════════════════════════════════════════════════════
Theme.Assets = {
    BannerId = "rbxassetid://135276561043104",
    BannerImageTransparency = 0.75,
    TintTransparency = 0.25,
    LightningTexture = "rbxassetid://96766676523858",
}

-- ═══════════════════════════════════════════════════════════════════════════
--  Theme.BuildDesign(Window)
-- ═══════════════════════════════════════════════════════════════════════════
Theme.BuildDesign = function(Window)
    local Root = Window.Root
    local acrylicFrame = Window.AcrylicPaint.Frame

    ---------------------------------------------------------------------
    -- 1) Banner y Tintado Oscuro
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
        ColorSequenceKeypoint.new(0, Theme.CrimsonGlow),
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
    -- 3) Sistema de Chispas Residuales (Energía Descontrolada)
    ---------------------------------------------------------------------
    local SparksLayer = Instance.new("Frame")
    SparksLayer.Name = "AFO_Sparks"
    SparksLayer.Size = UDim2.fromScale(1, 1)
    SparksLayer.BackgroundTransparency = 1
    SparksLayer.ZIndex = 3
    SparksLayer.Parent = art

    task.spawn(function()
        while task.wait(math.random(1, 4) * 0.1) do
            if not Root or not Root.Parent then break end
            local spark = Instance.new("Frame")
            spark.BackgroundColor3 = math.random() > 0.4 and Theme.CrimsonGlow or Theme.GlowColor
            spark.BorderSizePixel = 0
            spark.Size = UDim2.new(0, math.random(10, 60), 0, math.random(1, 3))
            spark.Position = UDim2.new(math.random(), 0, math.random(), 0)
            spark.Rotation = math.random(-25, 25)
            spark.BackgroundTransparency = 0.2
            spark.Parent = SparksLayer

            TweenService:Create(spark, TweenInfo.new(math.random(3, 7) * 0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, math.random(120, 350), 0, 0),
                BackgroundTransparency = 1,
                Position = spark.Position + UDim2.new(math.random(-15, 15)/100, 0, math.random(-15, 15)/100, 0)
            }):Play()

            game:GetService("Debris"):AddItem(spark, 1)
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
    -- 5) Inestabilidad (Ruido Perlin) para Latidos Caóticos
    ---------------------------------------------------------------------
    local timeX = 0
    RunService.RenderStepped:Connect(function(dt)
        timeX = timeX + (dt * 3.5)
        local noise = math.noise(timeX, 0, 0)
        
        if stroke then
            stroke.Thickness = 2 + math.abs(noise * 3)
        end
        if shadow then
            shadow.Transparency = 0.35 + math.abs(noise * 0.25)
            shadow.Spread = 3 + (noise * 3)
        end
    end)

    ---------------------------------------------------------------------
    -- 6) Aura Dual: Rayos Morados y Carmesí Entrelazados
    ---------------------------------------------------------------------
    local STRIP_THICKNESS = 6
    local TILE_SIZE = 96
    local SCROLL_TIME = 3.5

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

    -- Capa 1: Quirks Normales (Morado oscuro)
    makeEdge("BoltTop_P", UDim2.new(1, 0, 0, STRIP_THICKNESS), UDim2.new(0, 0, 0, 0), true, Theme.GlowColor, SCROLL_TIME, false)
    makeEdge("BoltBottom_P", UDim2.new(1, 0, 0, STRIP_THICKNESS), UDim2.new(0, 0, 1, -STRIP_THICKNESS), true, Theme.GlowColor, SCROLL_TIME, false)
    makeEdge("BoltLeft_P", UDim2.new(0, STRIP_THICKNESS, 1, 0), UDim2.new(0, 0, 0, 0), false, Theme.GlowColor, SCROLL_TIME, false)
    makeEdge("BoltRight_P", UDim2.new(0, STRIP_THICKNESS, 1, 0), UDim2.new(1, -STRIP_THICKNESS, 0, 0), false, Theme.GlowColor, SCROLL_TIME, false)

    -- Capa 2: All For One (Rojo Carmesí)
    makeEdge("BoltTop_C", UDim2.new(1, 0, 0, STRIP_THICKNESS), UDim2.new(0, 0, 0, 0), true, Theme.CrimsonGlow, SCROLL_TIME * 0.75, true)
    makeEdge("BoltBottom_C", UDim2.new(1, 0, 0, STRIP_THICKNESS), UDim2.new(0, 0, 1, -STRIP_THICKNESS), true, Theme.CrimsonGlow, SCROLL_TIME * 0.75, true)
    makeEdge("BoltLeft_C", UDim2.new(0, STRIP_THICKNESS, 1, 0), UDim2.new(0, 0, 0, 0), false, Theme.CrimsonGlow, SCROLL_TIME * 0.75, true)
    makeEdge("BoltRight_C", UDim2.new(0, STRIP_THICKNESS, 1, 0), UDim2.new(1, -STRIP_THICKNESS, 0, 0), false, Theme.CrimsonGlow, SCROLL_TIME * 0.75, true)

    ---------------------------------------------------------------------
    -- 7) Firma Asimétrica AFO
    ---------------------------------------------------------------------
    local rootCorner = Root:FindFirstChildOfClass("UICorner")
    if rootCorner then
        rootCorner.TopLeftRadius = UDim.new(0, 1)
        rootCorner.BottomRightRadius = UDim.new(0, 1)
    end

    ---------------------------------------------------------------------
    -- 8) Cambio de color de la "bolita" verde superior izquierda a Rojo Carmesí
    ---------------------------------------------------------------------
    task.spawn(function()
        task.wait(0.4) -- Esperar a que Fluent cargue los elementos internos
        if not Root then return end

        for _, obj in pairs(Root:GetDescendants()) do
            -- Buscamos marcos pequeños con esquinas redondeadas (la bolita de estado/versión suele ser un Frame con UICorner completo)
            if obj:IsA("Frame") and (obj.AbsoluteSize.X <= 16 and obj.AbsoluteSize.Y <= 16) then
                local corner = obj:FindFirstChildOfClass("UICorner")
                if corner then
                    obj.BackgroundColor3 = Theme.CrimsonGlow
                end
            end
        end
    end)
end

return Theme
