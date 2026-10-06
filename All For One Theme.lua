-- ═══════════════════════════════════════════════════════════════════════════
--  ALL FOR ONE THEME - V8 (OVERHAUL AMBIENTAL Y RAYOS GLITCH)
--  Rayos eléctricos erráticos, YouTube Ambient Light, y Olas de Oscuridad.
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
    
    -- El gradiente base ahora es un abismo profundo (las olas se harán por script)
    AcrylicGradient = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(8, 4, 12)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(18, 6, 26)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(8, 4, 12)),
    }),
    AcrylicNoise = 0.8,
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
    TintTransparency = 0.35,
    LightningTexture = "rbxassetid://96766676523858",
    CloudDarkness = "rbxassetid://8992237346", -- Textura de nubes orgánicas sin bordes rectos
    AmbientGlow = "rbxassetid://1868803131"    -- Textura radial suave para el Ambient Light
}

Theme.BuildDesign = function(Window)
    local Root = Window.Root
    local acrylicFrame = Window.AcrylicPaint.Frame

    ---------------------------------------------------------------------
    -- 1) YouTube Ambient Light (Sangrado de colores fuera del Hub)
    ---------------------------------------------------------------------
    local ambientLight = Instance.new("ImageLabel")
    ambientLight.Name = "YouTubeAmbientLight"
    ambientLight.BackgroundTransparency = 1
    ambientLight.Image = Theme.Assets.AmbientGlow
    -- Escalarlo mucho más grande que el Hub para que actúe como resplandor exterior
    ambientLight.Size = UDim2.new(1, 140, 1, 140)
    ambientLight.Position = UDim2.new(0, -70, 0, -70)
    ambientLight.ZIndex = -5 -- Muy al fondo
    ambientLight.ImageTransparency = 0.4
    ambientLight.Parent = Root

    local ambientGradient = Instance.new("UIGradient")
    ambientGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Theme.Crimson),
        ColorSequenceKeypoint.new(0.5, Theme.GlowColor),
        ColorSequenceKeypoint.new(1, Theme.Yellow),
    })
    ambientGradient.Parent = ambientLight

    -- Animación del resplandor ambiental
    task.spawn(function()
        local t = 0
        while task.wait() do
            if not Root then break end
            t = t + 0.015
            ambientGradient.Rotation = (t * 30) % 360
            ambientLight.ImageTransparency = 0.4 + math.sin(t * 2) * 0.15
        end
    end)

    ---------------------------------------------------------------------
    -- 2) Nubes de Oscuridad Orgánicas (Eliminación de la cruz)
    ---------------------------------------------------------------------
    local art = Instance.new("Frame")
    art.Name = "AllForOneArt"
    art.BackgroundTransparency = 1
    art.ClipsDescendants = true
    art.Size = UDim2.fromScale(1, 1)
    art.Parent = acrylicFrame

    local banner = Instance.new("ImageLabel")
    banner.Name = "Banner"
    banner.BackgroundTransparency = 1
    banner.Image = Theme.Assets.BannerId
    banner.ScaleType = Enum.ScaleType.Crop
    banner.Size = UDim2.fromScale(1, 1)
    banner.ImageTransparency = Theme.Assets.BannerImageTransparency
    banner.ZIndex = 1
    banner.Parent = art

    -- Olas de nubes rotatorias (no generan cruces porque rotan desde el centro en lugar de desplazarse en X/Y)
    local cloud1 = Instance.new("ImageLabel")
    cloud1.BackgroundTransparency = 1
    cloud1.Image = Theme.Assets.CloudDarkness
    cloud1.ImageColor3 = Theme.GlowColor
    cloud1.ImageTransparency = 0.85
    cloud1.Size = UDim2.fromScale(2.5, 2.5) -- Sobredimensionado para que al rotar no se vean las esquinas
    cloud1.Position = UDim2.fromScale(-0.75, -0.75)
    cloud1.ZIndex = 2
    cloud1.Parent = art

    local cloud2 = cloud1:Clone()
    cloud2.ImageColor3 = Theme.Crimson
    cloud2.ImageTransparency = 0.9
    cloud2.Size = UDim2.fromScale(3, 3)
    cloud2.Position = UDim2.fromScale(-1, -1)
    cloud2.Parent = art

    task.spawn(function()
        local rot1, rot2 = 0, 360
        while task.wait() do
            if not Root then break end
            rot1 = (rot1 + 0.1) % 360
            rot2 = (rot2 - 0.08) % 360
            cloud1.Rotation = rot1
            cloud2.Rotation = rot2
            
            -- Respiración sutil de la oscuridad
            local pulse = math.sin(tick() * 0.5)
            cloud1.ImageTransparency = 0.8 + (pulse * 0.1)
        end
    end)

    local tint = Instance.new("Frame")
    tint.BackgroundColor3 = Theme.DarkMatter
    tint.BackgroundTransparency = 0.45
    tint.BorderSizePixel = 0
    tint.Size = UDim2.fromScale(1, 1)
    tint.ZIndex = 3
    tint.Parent = art

    ---------------------------------------------------------------------
    -- 3) Rayos Eléctricos Violentos (Glitch, Brillo y Parpadeo Errático)
    ---------------------------------------------------------------------
    local SparksLayer = Instance.new("Frame")
    SparksLayer.Name = "AFO_LightningStrikes"
    SparksLayer.Size = UDim2.fromScale(1, 1)
    SparksLayer.BackgroundTransparency = 1
    SparksLayer.ZIndex = 4
    SparksLayer.Parent = art

    local powerColors = { Theme.GlowColor, Theme.Crimson, Theme.Yellow, Color3.fromRGB(200, 200, 255) }

    task.spawn(function()
        while task.wait(math.random(6, 15) * 0.1) do
            if not Root or not Root.Parent then break end
            
            local color = powerColors[math.random(1, #powerColors)]
            
            local strikeCore = Instance.new("ImageLabel")
            strikeCore.BackgroundTransparency = 1
            strikeCore.Image = Theme.Assets.LightningTexture
            strikeCore.ImageColor3 = Color3.new(1, 1, 1) -- Núcleo blanco (Brillo real)
            
            local strikeAura = Instance.new("ImageLabel")
            strikeAura.BackgroundTransparency = 1
            strikeAura.Image = Theme.Assets.LightningTexture
            strikeAura.ImageColor3 = color
            strikeAura.Size = UDim2.fromScale(1, 1.5)
            strikeAura.Position = UDim2.fromScale(0, -0.25)
            strikeAura.ZIndex = -1
            strikeAura.Parent = strikeCore
            
            local w = math.random(800, 1400)
            local h = math.random(10, 30)
            strikeCore.Size = UDim2.new(0, w, 0, h)
            
            local isLeftToRight = math.random() > 0.5
            local startX = isLeftToRight and -1 or 1
            local endX = isLeftToRight and 1.5 or -1.5
            local baseY = math.random(10, 90) / 100
            
            strikeCore.Rotation = isLeftToRight and 0 or 180
            strikeCore.Position = UDim2.new(startX, 0, baseY, 0)
            strikeCore.Parent = SparksLayer

            local travelTime = math.random(15, 25) / 10
            
            -- Movimiento físico general
            TweenService:Create(strikeCore, TweenInfo.new(travelTime, Enum.EasingStyle.Linear), {
                Position = UDim2.new(endX, 0, baseY, 0)
            }):Play()

            -- LOOP DE GLITCH (Simulación eléctrica real)
            task.spawn(function()
                local elapsed = 0
                while elapsed < travelTime do
                    if not strikeCore.Parent then break end
                    local waitTime = math.random(2, 6) / 100
                    elapsed = elapsed + waitTime
                    task.wait(waitTime)
                    
                    -- Parpadeo violento
                    strikeCore.ImageTransparency = math.random(0, 80) / 100
                    strikeAura.ImageTransparency = math.random(20, 60) / 100
                    
                    -- Temblor vertical y distorsión de tamaño (Glitch)
                    local jitterY = math.random(-3, 3) / 100
                    strikeCore.Position = UDim2.new(strikeCore.Position.X.Scale, 0, baseY + jitterY, 0)
                    strikeCore.Size = UDim2.new(0, w * (math.random(90, 110)/100), 0, h * (math.random(50, 200)/100))
                end
                strikeCore:Destroy()
            end)
        end
    end)

    ---------------------------------------------------------------------
    -- 4) Borde Corrupto Glitcheado
    ---------------------------------------------------------------------
    local stroke = Root:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke")
    stroke.Parent = Root
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
    shadow.BlurRadius = UDim.new(0, 40)
    shadow.ZIndex = -1
    shadow.Parent = Root

    local timeX = 0
    RunService.RenderStepped:Connect(function(dt)
        timeX = timeX + (dt * 8.0) 
        local noise = math.noise(timeX, 0, 0)
        
        if stroke then
            -- Borde con estática severa
            local glitchSpike = (math.random() > 0.90) and math.random(1, 4) or 0
            stroke.Thickness = 2 + math.abs(noise * 2) + glitchSpike
            strokeGradient.Rotation = (timeX * 40) % 360
        end
    end)

    ---------------------------------------------------------------------
    -- 5) Textos, Títulos y Censura Villain (Intacto)
    ---------------------------------------------------------------------
    task.spawn(function()
        task.wait(0.5) 
        if not Root then return end

        for _, obj in pairs(Root:GetDescendants()) do
            if obj:IsA("Frame") and obj.Size == UDim2.new(0, 6, 0, 6) then
                obj.BackgroundColor3 = Theme.Crimson
            end

            if obj:IsA("TextLabel") then
                if obj.AbsolutePosition.Y < 50 and (obj.Text:lower():find("all for one") or obj.Text:lower():find("villain")) then
                    obj.Text = "All For One (2.0)"
                    obj.Font = Enum.Font.GothamBlack
                    obj.TextSize = 18
                end

                if obj.Text == "Anonymous" then
                    obj.Text = "Villain"
                    obj.TextSize = 14
                    obj.Font = Enum.Font.GothamBold
                    
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
