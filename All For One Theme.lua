return {
    -- Color de marca: botones activos, sliders, toggles, foco...
    Accent = Color3.fromRGB(160, 32, 240),

    -- Íconos (Lucide) en lila claro, para que no compitan con el Accent
    IconColor = Color3.fromRGB(205, 150, 255),
    IconSize = 18,

    -- Fondo Acrylic
    AcrylicMain = Color3.fromRGB(15, 10, 22),
    AcrylicBorder = Color3.fromRGB(90, 15, 140),
    AcrylicGradient = ColorSequence.new(Color3.fromRGB(15, 10, 22), Color3.fromRGB(8, 4, 12)),
    AcrylicNoise = 0.70,

    TitleBarLine = Color3.fromRGB(90, 15, 140),

    -- Estructura
    Tab = Color3.fromRGB(22, 14, 32),
    Element = Color3.fromRGB(18, 10, 26),
    ElementBorder = Color3.fromRGB(70, 10, 110),
    InElementBorder = Color3.fromRGB(110, 20, 170),
    ElementTransparency = 0.85,

    -- Controles
    ToggleSlider = Color3.fromRGB(35, 18, 55),
    ToggleToggled = Color3.fromRGB(160, 32, 240),
    SliderRail = Color3.fromRGB(35, 18, 55),

    -- Dropdown
    DropdownFrame = Color3.fromRGB(14, 8, 20),
    DropdownHolder = Color3.fromRGB(8, 4, 12),
    DropdownBorder = Color3.fromRGB(70, 10, 110),
    DropdownOption = Color3.fromRGB(22, 14, 32),

    Keybind = Color3.fromRGB(22, 14, 32),

    -- Inputs
    Input = Color3.fromRGB(14, 8, 20),
    InputFocused = Color3.fromRGB(8, 4, 12),
    InputIndicator = Color3.fromRGB(110, 20, 170),

    -- Diálogos
    Dialog = Color3.fromRGB(14, 8, 20),
    DialogHolder = Color3.fromRGB(8, 4, 12),
    DialogHolderLine = Color3.fromRGB(70, 10, 110),
    DialogButton = Color3.fromRGB(18, 10, 26),
    DialogButtonBorder = Color3.fromRGB(70, 10, 110),
    DialogBorder = Color3.fromRGB(70, 10, 110),
    DialogInput = Color3.fromRGB(14, 8, 20),
    DialogInputLine = Color3.fromRGB(110, 20, 170),

    -- Texto
    Text = Color3.fromRGB(240, 230, 255),
    SubText = Color3.fromRGB(170, 140, 210),

    -- Hover (ligeramente más vivo que el original para dar mejor feedback)
    Hover = Color3.fromRGB(42, 22, 62),
    HoverChange = 0.05,

    -- Borde animado (shine)
    ShineEnabled = true,
    Shine = {
        Speed = 0.5,
        RotationSpeed = 25,
        ColorSequence = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 0, 80)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(160, 32, 240)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(50, 0, 80)),
        }),
    },
    StrokeShine = true,
    StrokeDark = Color3.fromRGB(50, 0, 80),

    -- Botones con gradiente
    ButtonGradient = {
        Background = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 8, 70)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 4, 35)),
        }),
        Stroke = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(90, 15, 140)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(160, 32, 240)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(90, 15, 140)),
        }),
    },
}
