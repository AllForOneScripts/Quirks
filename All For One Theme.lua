local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local Theme = {
    Accent = Color3.fromRGB(165, 20, 220),
    GlowColor = Color3.fromRGB(205, 55, 255),
    CrimsonGlow = Color3.fromRGB(220, 20, 60),
    IconColor = Color3.fromRGB(225, 130, 255),
    IconSize = 18,

    AcrylicMain = Color3.fromRGB(22, 8, 30),
    AcrylicBorder = Color3.fromRGB(100, 10, 145),

    AcrylicGradient = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(88, 12, 125)),
        ColorSequenceKeypoint.new(0.35, Color3.fromRGB(35, 10, 48)),
        ColorSequenceKeypoint.new(0.65, Color3.fromRGB(70, 8, 105)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(25, 6, 35)),
    }),

    AcrylicNoise = 0.55,
    TitleBarLine = Color3.fromRGB(100, 10, 145),

    Tab = Color3.fromRGB(28, 11, 38),
    Element = Color3.fromRGB(22, 9, 31),
    ElementBorder = Color3.fromRGB(80, 8, 120),
    InElementBorder = Color3.fromRGB(125, 15, 180),
    ElementTransparency = 0.85,

    ToggleSlider = Color3.fromRGB(38, 15, 58),
    ToggleToggled = Color3.fromRGB(165, 20, 220),
    SliderRail = Color3.fromRGB(38, 15, 58),

    DropdownFrame = Color3.fromRGB(20, 7, 27),
    DropdownHolder = Color3.fromRGB(9, 4, 13),
    DropdownBorder = Color3.fromRGB(80, 8, 120),
    DropdownOption = Color3.fromRGB(28, 11, 38),
    Keybind = Color3.fromRGB(28, 11, 38),

    Input = Color3.fromRGB(20, 7, 27),
    InputFocused = Color3.fromRGB(9, 4, 13),
    InputIndicator = Color3.fromRGB(125, 15, 180),

    Dialog = Color3.fromRGB(20, 7, 27),
    DialogHolder = Color3.fromRGB(9, 4, 13),
    DialogHolderLine = Color3.fromRGB(80, 8, 120),
    DialogButton = Color3.fromRGB(22, 9, 31),
    DialogButtonBorder = Color3.fromRGB(80, 8, 120),
    DialogBorder = Color3.fromRGB(80, 8, 120),
    DialogInput = Color3.fromRGB(20, 7, 27),
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
            ColorSequenceKeypoint.new(0, Color3.fromRGB(58, 12, 92)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(25, 5, 43)),
        }),
        Stroke = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 10, 145)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(205, 55, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 10, 145)),
        }),
    },
}

Theme.Assets = {
    BannerId = "rbxassetid://135276561043104",
    BannerImageTransparency = 0.62,
    TintTransparency = 0.48,
    LightningTexture = "rbxassetid://7151777149",
    StaticNoise = "rbxassetid://167262864",
}

Theme.BuildDesign = function(Window)
    local Root = Window.Root
    local acrylicFrame = Window.AcrylicPaint.Frame

    local oldArt = acrylicFrame:FindFirstChild("AllForOneArt")
    if oldArt then
        oldArt:Destroy()
    end

    for _, name in ipairs({
        "AFO_LightningStrikes",
        "BoltTop_P",
        "BoltBottom_P",
        "BoltLeft_P",
        "BoltRight_P",
        "BoltTop_C",
        "BoltBottom_C",
        "BoltLeft_C",
        "BoltRight_C"
    }) do
        local old = Root:FindFirstChild(name)
        if old then
            old:Destroy()
        end
    end

    local art = Instance.new("Frame")
    art.Name = "AllForOneArt"
    art.BackgroundTransparency = 1
    art.ClipsDescendants = true
    art.Size = UDim2.fromScale(1, 1)
    art.ZIndex = 0
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
        ColorSequenceKeypoint.new(0, Color3.fromRGB(115, 18, 155)),
        ColorSequenceKeypoint.new(0.45, Color3.fromRGB(70, 10, 100)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 7, 42)),
    })
    tintGradient.Rotation = 90
    tintGradient.Parent = tint

    local staticFx = Instance.new("ImageLabel")
    staticFx.Name = "Static"
    staticFx.BackgroundTransparency = 1
    staticFx.Image = Theme.Assets.StaticNoise
    staticFx.ImageTransparency = 0.94
    staticFx.Size = UDim2.fromScale(2, 2)
    staticFx.ZIndex = 3
    staticFx.Parent = art

    task.spawn(function()
        while staticFx.Parent and Root.Parent do
            staticFx.Position = UDim2.new(
                math.random(-50, 0) / 100,
                0,
                math.random(-50, 0) / 100,
                0
            )
            task.wait(0.06)
        end
    end)

    local bgGradient = acrylicFrame:FindFirstChildOfClass("UIGradient")
    if not bgGradient then
        bgGradient = Instance.new("UIGradient")
        bgGradient.Parent = acrylicFrame
    end

    bgGradient.Color = Theme.AcrylicGradient
    bgGradient.Rotation = 115

    TweenService:Create(
        bgGradient,
        TweenInfo.new(8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {
            Offset = Vector2.new(0.35, 0)
        }
    ):Play()

    local SparksLayer = Instance.new("Frame")
    SparksLayer.Name = "AFO_LightningStrikes"
    SparksLayer.Size = UDim2.fromScale(1, 1)
    SparksLayer.BackgroundTransparency = 1
    SparksLayer.ClipsDescendants = true
    SparksLayer.ZIndex = 4
    SparksLayer.Parent = art

    task.spawn(function()
        while SparksLayer.Parent and Root.Parent do
            task.wait(math.random(5, 16) / 100)

            local strike = Instance.new("ImageLabel")
            strike.BackgroundTransparency = 1
            strike.Image = Theme.Assets.LightningTexture
            strike.ImageColor3 = math.random() > 0.25
                and Theme.GlowColor
                or Theme.CrimsonGlow
            strike.ScaleType = Enum.ScaleType.Stretch
            strike.AnchorPoint = Vector2.new(0, 0.5)

            local w = math.random(500, 1100)
            local h = math.random(35, 85)

            strike.Size = UDim2.fromOffset(w, h)
            strike.Position = UDim2.new(
                math.random(-80, 10) / 100,
                0,
                math.random(5, 95) / 100,
                0
            )
            strike.Rotation = math.random(-8, 8)
            strike.ImageTransparency = math.random(0, 25) / 100
            strike.ZIndex = 4
            strike.Parent = SparksLayer

            local targetX = math.random(105, 180) / 100
            local targetRotation = math.random(-8, 8)

            TweenService:Create(
                strike,
                TweenInfo.new(
                    math.random(18, 34) / 100,
                    Enum.EasingStyle.Exponential,
                    Enum.EasingDirection.In
                ),
                {
                    Position = UDim2.new(targetX, 0, strike.Position.Y.Scale, 0),
                    Rotation = targetRotation,
                    ImageTransparency = 1
                }
            ):Play()

            Debris:AddItem(strike, 0.45)
        end
    end)

    local stroke = Root:FindFirstChildOfClass("UIStroke")
    if not stroke then
        stroke = Instance.new("UIStroke")
        stroke.Parent = Root
    end

    stroke.Color = Theme.GlowColor
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Thickness = 2

    local shadow = Root:FindFirstChildOfClass("UIShadow")
    if not shadow then
        shadow = Instance.new("UIShadow")
        shadow.Parent = Root
    end

    shadow.Color = Theme.GlowColor
    shadow.BlurRadius = UDim.new(0, 45)
    shadow.Offset = UDim2.new(0, 0, 0, 0)
    shadow.Spread = 5
    shadow.Transparency = 0.35
    shadow.ZIndex = -1

    local timeX = 0

    RunService.RenderStepped:Connect(function(dt)
        if not Root.Parent then
            return
        end

        timeX += dt * 7
        local noise = math.noise(timeX, 0, 0)

        stroke.Thickness = 2 + math.abs(noise * 3)

        shadow.Transparency = 0.28 + math.abs(noise * 0.28)
        shadow.Spread = 5 + noise * 5
        shadow.Color = noise > 0.45
            and Theme.CrimsonGlow
            or Theme.GlowColor
    end)

    local STRIP_THICKNESS = 10
    local TILE_SIZE = 105
    local SCROLL_TIME = 0.72

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

        if horizontal then
            img.Size = UDim2.new(2, 0, 1, 0)
            img.TileSize = UDim2.new(0, TILE_SIZE, 1, 0)

            if reverse then
                img.Position = UDim2.new(-1, 0, 0, 0)
                img.Parent = mask

                TweenService:Create(
                    img,
                    TweenInfo.new(
                        speed,
                        Enum.EasingStyle.Linear,
                        Enum.EasingDirection.In,
                        -1,
                        false
                    ),
                    {
                        Position = UDim2.new(0, 0, 0, 0)
                    }
                ):Play()
            else
                img.Position = UDim2.new(0, 0, 0, 0)
                img.Parent = mask

                TweenService:Create(
                    img,
                    TweenInfo.new(
                        speed,
                        Enum.EasingStyle.Linear,
                        Enum.EasingDirection.In,
                        -1,
                        false
                    ),
                    {
                        Position = UDim2.new(-1, 0, 0, 0)
                    }
                ):Play()
            end
        else
            img.Size = UDim2.new(1, 0, 2, 0)
            img.TileSize = UDim2.new(1, 0, 0, TILE_SIZE)

            if reverse then
                img.Position = UDim2.new(0, 0, -1, 0)
                img.Parent = mask

                TweenService:Create(
                    img,
                    TweenInfo.new(
                        speed,
                        Enum.EasingStyle.Linear,
                        Enum.EasingDirection.In,
                        -1,
                        false
                    ),
                    {
                        Position = UDim2.new(0, 0, 0, 0)
                    }
                ):Play()
            else
                img.Position = UDim2.new(0, 0, 0, 0)
                img.Parent = mask

                TweenService:Create(
                    img,
                    TweenInfo.new(
                        speed,
                        Enum.EasingStyle.Linear,
                        Enum.EasingDirection.In,
                        -1,
                        false
                    ),
                    {
                        Position = UDim2.new(0, 0, -1, 0)
                    }
                ):Play()
            end
        end

        task.spawn(function()
            while img.Parent do
                task.wait(math.random(3, 9) / 10)

                TweenService:Create(
                    img,
                    TweenInfo.new(0.07, Enum.EasingStyle.Linear),
                    {
                        ImageTransparency = math.random(5, 45) / 100
                    }
                ):Play()

                task.wait(0.07)

                TweenService:Create(
                    img,
                    TweenInfo.new(0.07, Enum.EasingStyle.Linear),
                    {
                        ImageTransparency = 0
                    }
                ):Play()
            end
        end)
    end

    makeEdge(
        "BoltTop_P",
        UDim2.new(1, 0, 0, STRIP_THICKNESS),
        UDim2.new(0, 0, 0, -STRIP_THICKNESS / 2),
        true,
        Theme.GlowColor,
        SCROLL_TIME,
        false
    )

    makeEdge(
        "BoltBottom_P",
        UDim2.new(1, 0, 0, STRIP_THICKNESS),
        UDim2.new(0, 0, 1, -STRIP_THICKNESS / 2),
        true,
        Theme.GlowColor,
        SCROLL_TIME,
        true
    )

    makeEdge(
        "BoltLeft_P",
        UDim2.new(0, STRIP_THICKNESS, 1, 0),
        UDim2.new(0, -STRIP_THICKNESS / 2, 0, 0),
        false,
        Theme.GlowColor,
        SCROLL_TIME,
        true
    )

    makeEdge(
        "BoltRight_P",
        UDim2.new(0, STRIP_THICKNESS, 1, 0),
        UDim2.new(1, -STRIP_THICKNESS / 2, 0, 0),
        false,
        Theme.GlowColor,
        SCROLL_TIME,
        false
    )

    makeEdge(
        "BoltTop_C",
        UDim2.new(1, 0, 0, STRIP_THICKNESS),
        UDim2.new(0, 0, 0, -STRIP_THICKNESS / 2),
        true,
        Theme.CrimsonGlow,
        SCROLL_TIME * 0.65,
        true
    )

    makeEdge(
        "BoltBottom_C",
        UDim2.new(1, 0, 0, STRIP_THICKNESS),
        UDim2.new(0, 0, 1, -STRIP_THICKNESS / 2),
        true,
        Theme.CrimsonGlow,
        SCROLL_TIME * 0.65,
        false
    )

    makeEdge(
        "BoltLeft_C",
        UDim2.new(0, STRIP_THICKNESS, 1, 0),
        UDim2.new(0, -STRIP_THICKNESS / 2, 0, 0),
        false,
        Theme.CrimsonGlow,
        SCROLL_TIME * 0.65,
        false
    )

    makeEdge(
        "BoltRight_C",
        UDim2.new(0, STRIP_THICKNESS, 1, 0),
        UDim2.new(1, -STRIP_THICKNESS / 2, 0, 0),
        false,
        Theme.CrimsonGlow,
        SCROLL_TIME * 0.65,
        true
    )

    task.spawn(function()
        task.wait(0.25)

        for _, obj in ipairs(Root:GetDescendants()) do
            if obj:IsA("TextLabel") or obj:IsA("TextButton") then
                local text = obj.Text

                if text:find("Todo para Uno") then
                    obj.Text = "All For One"
                    text = "All For One"
                elseif text:find("All For One") then
                    obj.Text = "All For One"
                    text = "All For One"
                end

                if text:lower():find("villain") then
                    obj.Text = "Villain"
                    obj.TextScaled = false
                    obj.TextSize = math.max(obj.TextSize, 18)
                end

                obj.TextScaled = false
                obj.TextWrapped = false
                obj.TextTruncate = Enum.TextTruncate.None

                if text == "All For One" then
                    obj.TextSize = 28
                    obj.Font = Enum.Font.GothamBlack
                    obj.AnchorPoint = Vector2.new(0.5, 0.5)
                    obj.Position = UDim2.new(
                        obj.Position.X.Scale,
                        obj.Position.X.Offset,
                        obj.Position.Y.Scale,
                        obj.Position.Y.Offset - 2
                    )
                    obj.Size = UDim2.new(
                        obj.Size.X.Scale,
                        obj.Size.X.Offset,
                        0,
                        38
                    )
                end
            end
        end

        for _, obj in ipairs(Root:GetDescendants()) do
            if obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
                local image = tostring(obj.Image):lower()

                if image:find("eye") or image:find("vision") then
                    obj.Visible = false
                end
            end
        end

        local villainLabel

        for _, obj in ipairs(Root:GetDescendants()) do
            if obj:IsA("TextLabel") or obj:IsA("TextButton") then
                if obj.Text:lower():find("villain") then
                    villainLabel = obj
                    break
                end
            end
        end

        if villainLabel then
            villainLabel.Text = "Villain"
            villainLabel.Visible = true
            villainLabel.TextTransparency = 0
            villainLabel.TextScaled = false
        end
    end)
end

return Theme
