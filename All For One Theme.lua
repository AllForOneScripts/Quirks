-- ═══════════════════════════════════════════════════════════════════════════
--  ALL FOR ONE THEME - OVERHAUL CAÓTICO Y SALVAJE (V6)
--  Rayos laterales cruzados, Perfil de "Villain" HD y Título Imponente
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
    
    -- Degradado Morado (Más claro para no oscurecer el fondo)
    AcrylicGradient = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(85, 15, 130)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(35, 10, 60)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(85, 15, 130)),
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
    BannerImageTransparency = 0.4, -- Más transparente para dejar ver tu fondo
    TintTransparency = 0.1, -- Menos oscuridad
    LightningTexture = "rbxassetid://7151777149",
    StaticNoise = "rbxassetid://167262864", 
}

Theme.BuildDesign = function(Window)
    local Root = Window.Root
    local acrylicFrame = Window.AcrylicPaint.Frame

    ---------------------------------------------------------------------
    -- 1) Banner, Estática y Tintado
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

    local staticFx = Instance.new("ImageLabel")
    staticFx.BackgroundTransparency = 1
    staticFx.Image = Theme.Assets.StaticNoise
    staticFx.ImageTransparency = 0.90
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
    -- 3) Rayos Horizontales (De lado a lado)
    ---------------------------------------------------------------------
    local SparksLayer = Instance.new("Frame")
    SparksLayer.Name = "AFO_LightningStrikes"
    SparksLayer.Size = UDim2.fromScale(1, 1)
    SparksLayer.BackgroundTransparency = 1
    SparksLayer.ZIndex = 4
    SparksLayer.Parent = art

    task.spawn(function()
        while task.wait(math.random(1, 5) * 0.1) do
            if not Root or not Root.Parent then break end
            
            local strike = Instance.new("ImageLabel")
            strike.BackgroundTransparency = 1
            strike.Image = Theme.Assets.LightningTexture
            strike.ImageColor3 = math.random() > 0.3 and Theme.GlowColor or Theme.CrimsonGlow
            
            -- Al estar la textura vertical, la rotamos ~90 grados
            -- Y hacemos que su tamaño "Y" (que ahora es horizontal) sea gigantesco para cruzar la pantalla
            strike.Size = UDim2.new(0, math.random(50, 120), 1.5, 0)
            strike.AnchorPoint = Vector2.new(0.5, 0.5)
            strike.Position = UDim2.new(0.5, 0, math.random(10, 90)/100, 0)
            strike.Rotation = math.random(85, 95)
            
            strike.ImageTransparency = 0
            strike.Parent = SparksLayer

            TweenService:Create(strike, TweenInfo.new(0.3, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, math.random(10, 40), 2, 0), -- Se estira y adelgaza al desaparecer
                ImageTransparency = 1
            }):Play()

            game:GetService("Debris"):AddItem(strike, 0.4)
        end
    end)

    ---------------------------------------------------------------------
    -- 4) Estructuras UI Visuales (Aura Latiendo)
    ---------------------------------------------------------------------
    local stroke = Root:FindFirstChildOfClass("UIStroke")
    if not stroke then stroke = Instance.new("UIStroke"); stroke.Parent = Root end
    stroke.Color = Theme.GlowColor
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    local shadow = Root:FindFirstChildOfClass("UIShadow")
    if not shadow then shadow = Instance.new("UIShadow"); shadow.Parent = Root end
    shadow.Color = Theme.GlowColor
    shadow.BlurRadius = UDim.new(0, 50)
    shadow.Offset = UDim2.new(0, 0, 0, 0)
    shadow.ZIndex = -1

    local timeX = 0
    RunService.RenderStepped:Connect(function(dt)
        timeX = timeX + (dt * 8.0) 
        local noise = math.noise(timeX, 0, 0)
        if stroke then stroke.Thickness = 1.5 + math.abs(noise * 3) end
        if shadow then
            shadow.Transparency = 0.15 + math.abs(noise * 0.4)
            shadow.Spread = 8 + (noise * 6)
            shadow.Color = noise > 0.4 and Theme.CrimsonGlow or Theme.GlowColor
        end
    end)

    ---------------------------------------------------------------------
    -- 5) Inyección de Textos y Corrección de Perfil
    ---------------------------------------------------------------------
    task.spawn(function()
        task.wait(1.5) 
        if not Root then return end

        for _, obj in pairs(Root:GetDescendants()) do
            -- A) MEJORA DEL TÍTULO PRINCIPAL
            if obj:IsA("TextLabel") and (obj.Text:find("All For One") or obj.Text:find("Todo para Uno")) then
                obj.Text = "ALL FOR ONE"
                obj.TextScaled = false
                obj.TextSize = 22
                obj.Font = Enum.Font.GothamBlack
                obj.TextColor3 = Theme.CrimsonGlow
                
                local titleStroke = obj:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke")
                titleStroke.Color = Theme.GlowColor
                titleStroke.Thickness = 1.2
                titleStroke.Transparency = 0.3
                titleStroke.Parent = obj
            end
            
            -- B) CORRECCIÓN DEL PERFIL DE USUARIO
            if obj:IsA("ImageLabel") and obj.Image:match("rbxthumb") then
                local userCard = obj.Parent
                local labels = {}
                
                for _, child in pairs(userCard:GetDescendants()) do
                    if child:IsA("TextLabel") then
                        table.insert(labels, child)
                    elseif child:IsA("ImageLabel") and child.Image:match("eye") then
                        -- Destruir el icono del ojo por completo
                        local btn = child.Parent
                        if btn and (btn:IsA("TextButton") or btn:IsA("ImageButton")) then
                            btn.Visible = false
                        end
                        child.Visible = false
                    end
                end
                
                -- Organizar labels por posición Y para saber cuál es el de arriba
                table.sort(labels, function(a, b) return a.AbsolutePosition.Y < b.AbsolutePosition.Y end)
                
                if #labels > 0 then
                    local topLabel = labels[1]
                    
                    -- Desactivar el TextScaled para recuperar calidad HD
                    topLabel.TextScaled = false
                    topLabel.TextSize = 16 
                    topLabel.Font = Enum.Font.GothamBold
                    topLabel.Text = "Villain"
                    topLabel.TextColor3 = Theme.GlowColor
                    
                    -- Si hay un segundo texto (el @username), lo ocultamos
                    -- Esto arregla el bug del texto desplazado hacia abajo
                    if #labels >= 2 then
                        labels[2].Visible = false
                    end
                    
                    -- Candado para que Fluent no lo vuelva a cambiar
                    topLabel:GetPropertyChangedSignal("Text"):Connect(function()
                        if topLabel.Text ~= "Villain" then
                            topLabel.Text = "Villain"
                        end
                    end)
                end
            end
        end
    end)
end

return Theme
