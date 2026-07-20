local Theme = {
    -- Color de marca: botones activos, sliders, toggles, foco...
    Accent = Color3.fromRGB(165, 20, 220),
    -- Íconos (Lucide) en orquídea claro, más "morado" y menos azulado que antes
    IconColor = Color3.fromRGB(225, 130, 255),
    IconSize = 18,
    -- Fondo Acrylic
    AcrylicMain = Color3.fromRGB(12, 6, 18),
    AcrylicBorder = Color3.fromRGB(100, 10, 145),
    -- Gradiente de 3 paradas (antes 2) para dar más profundidad, tipo Acrylic premium
    AcrylicGradient = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(18, 8, 26)),
        ColorSequenceKeypoint.new(0.55, Color3.fromRGB(12, 6, 18)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(5, 2, 9)),
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
    -- Hover (ligeramente más vivo para dar buen feedback)
    Hover = Color3.fromRGB(48, 20, 68),
    HoverChange = 0.05,
    -- Borde animado (shine/partículas) DESACTIVADO por petición
    -- Se deja la tabla presente (apagada) en vez de borrarla, para evitar
    -- errores de index nil si el render de la lib la consulta igual.
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
--  Diseño / arte decorativo (antes vivía en el loader, ahora vive aquí)
-- ═══════════════════════════════════════════════════════════════════════════
-- Assets: para que cambiar el banner/logo sea un solo lugar, no tocar el loader.
Theme.Assets = {
    BannerId = "rbxassetid://135276561043104",
    LogoId = "rbxassetid://76033225639305",
    BannerImageTransparency = 0.72,
    TintTransparency = 0.35,
}

-- BuildArt(Window): crea el banner + overlay morado + logo dentro del
-- AcrylicPaint del Window. El loader solo necesita llamar a esta función
-- después de crear el Window; todo lo visual se define y se ajusta aquí.
-- Como es un closure sobre `Theme`, si cambias los colores de arriba
-- (AcrylicBorder, AcrylicMain, Accent...) el overlay los sigue automáticamente.
Theme.BuildArt = function(Window)
    local acrylicFrame = Window.AcrylicPaint.Frame

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

    -- Overlay morado por encima del banner: lo tiñe y lo apaga más,
    -- con degradado (no color liso) para un efecto más "cool".
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

    local logo = Instance.new("ImageLabel")
    logo.Name = "Logo"
    logo.BackgroundTransparency = 1
    logo.Image = Theme.Assets.LogoId
    logo.AnchorPoint = Vector2.new(0.5, 0)
    logo.Position = UDim2.new(0.5, 0, 0, 14)
    logo.Size = UDim2.fromOffset(72, 72)
    logo.ZIndex = 3
    logo.Parent = art

    return art
end

return Theme
