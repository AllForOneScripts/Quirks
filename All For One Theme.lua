-- ═══════════════════════════════════════════════════════════════════════════
--  ALL FOR ONE THEME
--  Dirección de arte: energía oscura y viva. Nada de partículas sueltas
--  flotando (ya se quitaron a propósito) — el "movimiento" viene de la
--  propia energía del borde (rayos), un fondo que respira, y un brillo
--  morado que pulsa, como si el hub tuviera el quirk encerrado adentro.
-- ═══════════════════════════════════════════════════════════════════════════
local TweenService = game:GetService("TweenService")

local Theme = {
    -- Color de marca: botones activos, sliders, toggles, foco...
    Accent = Color3.fromRGB(165, 20, 220),
    -- Morado más vivo, reservado para brillos/sombra/rayos (no botones normales)
    GlowColor = Color3.fromRGB(205, 55, 255),
    -- Íconos (Lucide) en orquídea claro
    IconColor = Color3.fromRGB(225, 130, 255),
    IconSize = 18,
    -- Fondo Acrylic
    AcrylicMain = Color3.fromRGB(12, 6, 18),
    AcrylicBorder = Color3.fromRGB(100, 10, 145),
    -- Degradado morado / morado oscuro (ahora además se anima, ver BuildDesign)
    AcrylicGradient = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(70, 8, 115)),
        ColorSequenceKeypoint.new(0.35, Color3.fromRGB(18, 6, 30)),
        ColorSequenceKeypoint.new(0.65, Color3.fromRGB(45, 5, 80)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(8, 3, 14)),
    }),
    AcrylicNoise = 0.55,
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
    -- Hover
    Hover = Color3.fromRGB(48, 20, 68),
    HoverChange = 0.05,
    -- Shine (partículas de borde) DESACTIVADO — se deja apagado, no borrado,
    -- para no romper nada si el render de Fluent lo consulta igual.
    ShineEnabled = false,
    Shine = {
        Speed = 0,
        RotationSpeed = 0,
        ColorSequence = ColorSequence.new(Color3.fromRGB(165, 20, 220)),
    },
    StrokeShine = false,
    StrokeDark = Color3.fromRGB(60, 5, 95),
    -- Botones con gradiente
    ButtonGradient = {
        Background = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(52, 10, 85)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(22, 4, 40)),
        }),
        Stroke = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 10, 145)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(165, 20, 220)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 10, 145)),
        }),
    },
}

-- ═══════════════════════════════════════════════════════════════════════════
--  Assets
-- ═══════════════════════════════════════════════════════════════════════════
Theme.Assets = {
    BannerId = "rbxassetid://135276561043104",
    BannerImageTransparency = 0.72,
    TintTransparency = 0.35,
    -- Textura de "rayos" pedida para el borde de energía
    LightningTexture = "rbxassetid://96766676523858",
}

-- ═══════════════════════════════════════════════════════════════════════════
--  Theme.BuildDesign(Window)
--  TODO el diseño visual del hub vive aquí. El loader solo llama a esto
--  una vez, después de Fluent:CreateWindow(...).
-- ═══════════════════════════════════════════════════════════════════════════
Theme.BuildDesign = function(Window)
    local Root = Window.Root
    local acrylicFrame = Window.AcrylicPaint.Frame

    ---------------------------------------------------------------------
    -- 1) Banner con overlay morado (sin logo, sin partículas)
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
    -- (el logo de arriba se quitó a propósito: ya no hace falta)

    ---------------------------------------------------------------------
    -- 2) Fondo: degradado morado / morado oscuro que se desliza
    --    en vez de quedarse fijo como un color plano.
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
        TweenInfo.new(6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        { Offset = Vector2.new(0.35, 0) }
    ):Play()

    ---------------------------------------------------------------------
    -- 3) Borde morado brillante que "respira" (crece y encoge el grosor)
    ---------------------------------------------------------------------
    local stroke = Root:FindFirstChildOfClass("UIStroke")
    if not stroke then
        stroke = Instance.new("UIStroke")
        stroke.Parent = Root
    end
    stroke.Color = Theme.GlowColor
    stroke.Thickness = 2
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    TweenService:Create(
        stroke,
        TweenInfo.new(1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        { Thickness = 4 }
    ):Play()

    ---------------------------------------------------------------------
    -- 4) Sombra morada del hub (UIShadow nativo — sin depender de imágenes)
    ---------------------------------------------------------------------
    local shadow = Root:FindFirstChildOfClass("UIShadow")
    if not shadow then
        shadow = Instance.new("UIShadow")
        shadow.Parent = Root
    end
    shadow.Color = Theme.GlowColor
    shadow.BlurRadius = UDim.new(0, 45)
    shadow.Spread = 4
    shadow.Offset = UDim2.new(0, 0, 0, 0)
    shadow.Transparency = 0.35
    shadow.ZIndex = -1
    -- La sombra "respira" en sincronía con el borde: sensación de energía viva.
    TweenService:Create(
        shadow,
        TweenInfo.new(1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        { Transparency = 0.55 }
    ):Play()

    ---------------------------------------------------------------------
    -- 5) Bordes de "rayo" con la textura pedida, recorriendo el marco
    ---------------------------------------------------------------------
    local STRIP_THICKNESS = 6
    local TILE_SIZE = 96
    local SCROLL_TIME = 3.5

    local function makeEdge(name, size, position, horizontal)
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
        img.ImageColor3 = Theme.GlowColor
        img.ScaleType = Enum.ScaleType.Tile
        if horizontal then
            img.Size = UDim2.new(2, 0, 1, 0)
            img.TileSize = UDim2.new(0, TILE_SIZE, 1, 0)
        else
            img.Size = UDim2.new(1, 0, 2, 0)
            img.TileSize = UDim2.new(1, 0, 0, TILE_SIZE)
        end
        img.Parent = mask

        local goal = horizontal and UDim2.new(-1, 0, 0, 0) or UDim2.new(0, 0, -1, 0)
        TweenService:Create(
            img,
            TweenInfo.new(SCROLL_TIME, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1, false),
            { Position = goal }
        ):Play()
    end

    makeEdge("BoltTop", UDim2.new(1, 0, 0, STRIP_THICKNESS), UDim2.new(0, 0, 0, 0), true)
    makeEdge("BoltBottom", UDim2.new(1, 0, 0, STRIP_THICKNESS), UDim2.new(0, 0, 1, -STRIP_THICKNESS), true)
    makeEdge("BoltLeft", UDim2.new(0, STRIP_THICKNESS, 1, 0), UDim2.new(0, 0, 0, 0), false)
    makeEdge("BoltRight", UDim2.new(0, STRIP_THICKNESS, 1, 0), UDim2.new(1, -STRIP_THICKNESS, 0, 0), false)

    ---------------------------------------------------------------------
    -- 6) Firma "All For One": una esquina asimétrica (usa el nuevo
    --    per-corner rounding de UICorner). Sutil, no rompe el layout,
    --    y hace que el hub no se vea "genérico". Fácil de revertir si
    --    no te convence: solo borra este bloque.
    ---------------------------------------------------------------------
    local rootCorner = Root:FindFirstChildOfClass("UICorner")
    if rootCorner then
        rootCorner.TopLeftRadius = UDim.new(0, 2)
    end
end

return Theme
