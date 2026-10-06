local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Theme = {
    -- === PALETA DE COLORES (Extraída directamente del archivo original) ===
    Accent = Color3.fromRGB(165, 20, 220),
    GlowColor = Color3.fromRGB(205, 55, 255),
    IconColor = Color3.fromRGB(225, 130, 255),
    IconSize = 18,
    
    AcrylicMain = Color3.fromRGB(12, 6, 18),
    AcrylicBorder = Color3.fromRGB(100, 10, 145),
    
    AcrylicGradient = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(70, 8, 115)),
        ColorSequenceKeypoint.new(0.35, Color3.fromRGB(18, 6, 30)),
        ColorSequenceKeypoint.new(0.65, Color3.fromRGB(45, 5, 80)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(8, 3, 14)),
    }),
    AcrylicNoise = 0.55,
    TitleBarLine = Color3.fromRGB(100, 10, 145),
    
    Tab = Color3.fromRGB(24, 10, 34),
    Element = Color3.fromRGB(19, 8, 28),
    ElementBorder = Color3.fromRGB(80, 8, 120),
    InElementBorder = Color3.fromRGB(125, 15, 180),
    ElementTransparency = 0.85,
    
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
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(165, 20, 220)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 10, 145)),
        }),
    },
}

Theme.Assets = {
    BannerId = "rbxassetid://135276561043104",
    BannerImageTransparency = 0.72,
    TintTransparency = 0.35,
    LightningTexture = "rbxassetid://96766676523858",
}

Theme.BuildDesign = function(Window)
    local Root = Window.Root
    local acrylicFrame = Window.AcrylicPaint.Frame

    ---------------------------------------------------------------------
    -- 1) Banner y Tintado Oscuro (Sin oscurecer el fondo)
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

    -- Tintado base (se mantiene transparente para no apagar el hub)
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
    -- 2) Fondo Base Deslizante Clásico
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
    -- 3) Efecto de Rayos Violentos (De lado a lado)
    ---------------------------------------------------------------------
    local SparksLayer = Instance.new("Frame")
    SparksLayer.Name = "AFO_LightningStrikes"
    SparksLayer.Size = UDim2.fromScale(1, 1)
    SparksLayer.BackgroundTransparency = 1
    SparksLayer.ZIndex = 4
    SparksLayer.Parent = art

    task.spawn(function()
        while task.wait(math.random(1, 4) * 0.1) do
            if not Root or not Root.Parent then break end
            
            local strike = Instance.new("ImageLabel")
            strike.BackgroundTransparency = 1
            strike.Image = Theme.Assets.LightningTexture
            strike.ImageColor3 = Theme.GlowColor
            
            -- Tamaños ensanchados
            local w = math.random(600, 1200)
            local h = math.random(50, 150)
            strike.Size = UDim2.new(0, w, 0, h)
            
            -- Posición centrada horizontalmente, altitud aleatoria
            strike.Position = UDim2.new(0.5, 0, math.random(-10, 110)/100, 0)
            strike.AnchorPoint = Vector2.new(0.5, 0.5)
            
            -- ROTACIÓN: Giramos la textura vertical a +/- 90 grados para que cruce horizontalmente
            local direction = (math.random() > 0.5) and 90 or -90
            strike.Rotation = direction + math.random(-15, 15)
            
            strike.ImageTransparency = 0
            strike.Parent = SparksLayer

            -- Destello
            TweenService:Create(strike, TweenInfo.new(0.2, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, w * 1.5, 0, h * 0.3),
                ImageTransparency = 1
            }):Play()

            game:GetService("Debris"):AddItem(strike, 0.3)
        end
    end)

    ---------------------------------------------------------------------
    -- 4) Aura y Borde Inestable
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

    local timeX = 0
    RunService.RenderStepped:Connect(function(dt)
        timeX = timeX + (dt * 6.0) 
        local noise = math.noise(timeX, 0, 0)
        
        if stroke then
            stroke.Thickness = 2 + math.abs(noise * 3)
        end
        if shadow then
            shadow.Transparency = 0.2 + math.abs(noise * 0.4)
            shadow.Spread = 6 + (noise * 5)
        end
    end)

    ---------------------------------------------------------------------
    -- 5) Correcciones de Texto y Calidad visual
    ---------------------------------------------------------------------
    task.spawn(function()
        task.wait(0.5) 
        if not Root then return end

        for _, obj in pairs(Root:GetDescendants()) do
            if obj:IsA("TextLabel") then
                -- Desactivar el escalado automático para evitar pérdida de resolución/calidad
                if obj.TextScaled then
                    obj.TextScaled = false
                    if obj.TextSize == 0 then
                        obj.TextSize = 14
                    end
                end
                
                -- Evitar desplazamientos hacia abajo alineando estrictamente al centro
                obj.TextYAlignment = Enum.TextYAlignment.Center

                -- TÍTULO MAYOR: Imponente, grande, destacable.
                if obj.Text:lower():find("all for one") or obj.Name == "Title" then
                    obj.Text = "ALL FOR ONE"
                    obj.TextSize = 22
                    obj.Font = Enum.Font.GothamBlack
                    
                    local titleStroke = obj:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke")
                    titleStroke.Color = Theme.GlowColor
                    titleStroke.Transparency = 0.4
                    titleStroke.Thickness = 1.2
                    titleStroke.Parent = obj
                end

                -- VILLAIN PERMANENTE: Reemplazar textos anteriores o íconos por Villain.
                if obj.Text:find("👁") or obj.Text:lower():find("villain") or obj.Text:find("Todo para Uno") then
                    obj.Text = "Villain"
                    obj.TextSize = 14
                    obj.Font = Enum.Font.GothamBold
                    obj.TextColor3 = Theme.SubText
                    
                    -- Prevenir cualquier salto de línea oculto
                    obj.Text = obj.Text:gsub("\n", "")
                end
            end
        end
    end)
end

return Theme
