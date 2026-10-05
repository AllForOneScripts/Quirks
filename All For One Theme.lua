-- ═══════════════════════════════════════════════════════════════════════════
--  ALL FOR ONE THEME - OVERHAUL CAÓTICO Y SALVAJE (V5)
--  Dirección de arte: Energía oscura inestable, rayos reales chocando, estática.
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
    
    -- Degradado Morado Oscuro/Vacío
    AcrylicGradient = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(70, 8, 115)),
        ColorSequenceKeypoint.new(0.35, Color3.fromRGB(18, 6, 30)),
        ColorSequenceKeypoint.new(0.65, Color3.fromRGB(45, 5, 80)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(8, 3, 14)),
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
    BannerImageTransparency = 0.65,
    TintTransparency = 0.35,
    LightningTexture = "rbxassetid://7151777149", -- Textura solicitada
    StaticNoise = "rbxassetid://167262864", -- Estática para dar detalle de inestabilidad
}

Theme.BuildDesign = function(Window)
    local Root = Window.Root
    local acrylicFrame = Window.AcrylicPaint.Frame

    ---------------------------------------------------------------------
    -- 1) Banner, Tintado Oscuro y Estática de "Energía"
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

    -- Capa de estática/ruido animada (Detalle extra de caos)
    local staticFx = Instance.new("ImageLabel")
    staticFx.BackgroundTransparency = 1
    staticFx.Image = Theme.Assets.StaticNoise
    staticFx.ImageTransparency = 0.88
    staticFx.Size = UDim2.fromScale(2, 2)
    staticFx.ZIndex = 2
    staticFx.Parent = art
    
    task.spawn(function()
        while task.wait(0.05) do
            if not Root then break end
            staticFx.Position = UDim2.new(math.random(-50, 0)/100, 0, math.random(-50, 0)/100, 0)
        end
    end)

    local tint = Instance.new("Frame")
    tint.Name = "PurpleTint"
    tint.BackgroundColor3 = Theme.AcrylicBorder
    tint.BackgroundTransparency = Theme.Assets.TintTransparency
    tint.BorderSizePixel = 0
    tint.Size = UDim2.fromScale(1, 1)
    tint.ZIndex = 3
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
    -- 3) Aparición de Rayos Reales (Reemplazo del Confetti)
    ---------------------------------------------------------------------
    local SparksLayer = Instance.new("Frame")
    SparksLayer.Name = "AFO_LightningStrikes"
    SparksLayer.Size = UDim2.fromScale(1, 1)
    SparksLayer.BackgroundTransparency = 1
    SparksLayer.ZIndex = 4
    SparksLayer.Parent = art

    task.spawn(function()
        while task.wait(math.random(1, 6) * 0.1) do
            if not Root or not Root.Parent then break end
            
            local strike = Instance.new("ImageLabel")
            strike.BackgroundTransparency = 1
            strike.Image = Theme.Assets.LightningTexture
            strike.ImageColor3 = math.random() > 0.4 and Theme.GlowColor or Theme.CrimsonGlow
            
            -- Tamaños extremos para simular un relámpago cruzando la pantalla
            local w = math.random(150, 400)
            local h = math.random(30, 100)
            strike.Size = UDim2.new(0, w, 0, h)
            
            strike.Position = UDim2.new(math.random(-10, 90)/100, 0, math.random(-10, 90)/100, 0)
            strike.Rotation = math.random(-180, 180)
            strike.ImageTransparency = 0
            strike.Parent = SparksLayer

            -- Animación de destello eléctrico (aparece y desaparece estirándose)
            TweenService:Create(strike, TweenInfo.new(0.25, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, w * 1.5, 0, h * 0.5),
                ImageTransparency = 1
            }):Play()

            game:GetService("Debris"):AddItem(strike, 0.3)
        end
    end)

    ---------------------------------------------------------------------
    -- 4) Estructuras UI Visuales (Shadow Inestable)
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
    shadow.BlurRadius = UDim.new(0, 50)
    shadow.Offset = UDim2.new(0, 0, 0, 0)
    shadow.ZIndex = -1

    ---------------------------------------------------------------------
    -- 5) Inestabilidad (Ruido Perlin Agresivo para el Aura)
    ---------------------------------------------------------------------
    local timeX = 0
    RunService.RenderStepped:Connect(function(dt)
        timeX = timeX + (dt * 8.0) 
        local noise = math.noise(timeX, 0, 0)
        
        if stroke then
            stroke.Thickness = 2 + math.abs(noise * 4) -- Borde palpitante
        end
        if shadow then
            -- Aura que late fuerte y cambia entre morado y rojo
            shadow.Transparency = 0.15 + math.abs(noise * 0.4)
            shadow.Spread = 8 + (noise * 6)
            shadow.Color = noise > 0.3 and Theme.CrimsonGlow or Theme.GlowColor
        end
    end)

    ---------------------------------------------------------------------
    -- 6) Bordes de Rayos Morados y Carmesí Entrelazados (Más gruesos)
    ---------------------------------------------------------------------
    local STRIP_THICKNESS = 22 -- Bordes más anchos para notar la textura
    local TILE_SIZE = 120
    local SCROLL_TIME = 1.2 

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

        -- Movimiento continuo del rayo
        TweenService:Create(
            img,
            TweenInfo.new(speed, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1, false),
            { Position = goal }
        ):Play()

        -- Pulsación de opacidad para que parezca electricidad viva
        task.spawn(function()
            while task.wait(math.random(2, 6)*0.1) do
                if not img.Parent then break end
                TweenService:Create(img, TweenInfo.new(0.1), {ImageTransparency = math.random(10, 60)/100}):Play()
                task.wait(0.1)
                TweenService:Create(img, TweenInfo.new(0.1), {ImageTransparency = 0}):Play()
            end
        end)
    end

    -- Capa Morada
    makeEdge("BoltTop_P", UDim2.new(1, 0, 0, STRIP_THICKNESS), UDim2.new(0, 0, 0, -STRIP_THICKNESS/2), true, Theme.GlowColor, SCROLL_TIME, false)
    makeEdge("BoltBottom_P", UDim2.new(1, 0, 0, STRIP_THICKNESS), UDim2.new(0, 0, 1, -STRIP_THICKNESS/2), true, Theme.GlowColor, SCROLL_TIME, false)
    makeEdge("BoltLeft_P", UDim2.new(0, STRIP_THICKNESS, 1, 0), UDim2.new(0, -STRIP_THICKNESS/2, 0, 0), false, Theme.GlowColor, SCROLL_TIME, false)
    makeEdge("BoltRight_P", UDim2.new(0, STRIP_THICKNESS, 1, 0), UDim2.new(1, -STRIP_THICKNESS/2, 0, 0), false, Theme.GlowColor, SCROLL_TIME, false)

    -- Capa Carmesí Inversa
    makeEdge("BoltTop_C", UDim2.new(1, 0, 0, STRIP_THICKNESS), UDim2.new(0, 0, 0, -STRIP_THICKNESS/2), true, Theme.CrimsonGlow, SCROLL_TIME * 0.7, true)
    makeEdge("BoltBottom_C", UDim2.new(1, 0, 0, STRIP_THICKNESS), UDim2.new(0, 0, 1, -STRIP_THICKNESS/2), true, Theme.CrimsonGlow, SCROLL_TIME * 0.7, true)
    makeEdge("BoltLeft_C", UDim2.new(0, STRIP_THICKNESS, 1, 0), UDim2.new(0, -STRIP_THICKNESS/2, 0, 0), false, Theme.CrimsonGlow, SCROLL_TIME * 0.7, true)
    makeEdge("BoltRight_C", UDim2.new(0, STRIP_THICKNESS, 1, 0), UDim2.new(1, -STRIP_THICKNESS/2, 0, 0), false, Theme.CrimsonGlow, SCROLL_TIME * 0.7, true)

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
    
    -- Nota: La sección 8 (Perfil hackeado con doble texto) fue eliminada
    -- tal y como solicitaste para mantener el sistema de censura limpio.
end

return Theme
