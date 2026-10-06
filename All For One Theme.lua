local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TextService = game:GetService("TextService")

local Theme = {
    Accent = Color3.fromRGB(135, 18, 195),
    GlowColor = Color3.fromRGB(140, 22, 215),
    Crimson = Color3.fromRGB(220, 20, 60),
    Yellow = Color3.fromRGB(255, 215, 0),
    DarkMatter = Color3.fromRGB(10, 4, 16),

    IconColor = Color3.fromRGB(205, 120, 245),
    IconSize = 18,

    AcrylicMain = Color3.fromRGB(7, 3, 11),
    AcrylicBorder = Color3.fromRGB(70, 10, 100),
    AcrylicGradient = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(7, 3, 11)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(15, 5, 23)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(7, 3, 11)),
    }),
    AcrylicNoise = 0.8,
    TitleBarLine = Color3.fromRGB(90, 10, 130),

    Tab = Color3.fromRGB(16, 7, 24),
    Element = Color3.fromRGB(13, 5, 19),
    ElementBorder = Color3.fromRGB(72, 8, 108),
    InElementBorder = Color3.fromRGB(110, 14, 160),
    ElementTransparency = 0.85,

    ToggleSlider = Color3.fromRGB(34, 13, 52),
    ToggleToggled = Color3.fromRGB(135, 18, 195),
    SliderRail = Color3.fromRGB(34, 13, 52),

    DropdownFrame = Color3.fromRGB(11, 5, 17),
    DropdownHolder = Color3.fromRGB(6, 3, 10),
    DropdownBorder = Color3.fromRGB(72, 8, 108),
    DropdownOption = Color3.fromRGB(16, 7, 24),
    Keybind = Color3.fromRGB(16, 7, 24),

    Input = Color3.fromRGB(11, 5, 17),
    InputFocused = Color3.fromRGB(6, 3, 10),
    InputIndicator = Color3.fromRGB(110, 14, 160),

    Dialog = Color3.fromRGB(11, 5, 17),
    DialogHolder = Color3.fromRGB(6, 3, 10),
    DialogHolderLine = Color3.fromRGB(72, 8, 108),
    DialogButton = Color3.fromRGB(13, 5, 19),
    DialogButtonBorder = Color3.fromRGB(72, 8, 108),
    DialogBorder = Color3.fromRGB(72, 8, 108),
    DialogInput = Color3.fromRGB(11, 5, 17),
    DialogInputLine = Color3.fromRGB(110, 14, 160),

    Text = Color3.fromRGB(240, 230, 248),
    SubText = Color3.fromRGB(175, 140, 205),
    Hover = Color3.fromRGB(42, 17, 62),
    HoverChange = 0.05,

    ShineEnabled = false,
    StrokeShine = false,
    StrokeDark = Color3.fromRGB(36, 5, 54),

    ButtonGradient = {
        Background = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(36, 8, 64)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(13, 4, 27)),
        }),
        Stroke = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(90, 10, 135)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(220, 20, 60)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 215, 0)),
        }),
    },
}

Theme.Assets = {
    BannerId = "rbxassetid://135276561043104",
    BannerImageTransparency = 0.65,
    TintTransparency = 0.35,
    CloudDarkness = "rbxassetid://8992237346",
    AmbientGlow = "rbxassetid://1868803131",
}

Theme.BuildDesign = function(Window)
    local Root = Window.Root
    local acrylicFrame = Window.AcrylicPaint.Frame
    local lp = Players.LocalPlayer
    local rand = math.random
    local WHITE = Color3.new(1, 1, 1)

    -- Paleta (más inclinada a violetas oscuros)
    local DEEP = Color3.fromRGB(70, 10, 115)
    local VIOLET = Color3.fromRGB(125, 20, 200)
    local LAV = Color3.fromRGB(190, 150, 255)

    local alive = true
    local S = { t = 0, surge = 0, flashColor = Theme.GlowColor, tglitch = 0, wave = 1, px = 0, py = 0 }

    local rootCorner = Root:FindFirstChildOfClass("UICorner")
    local cornerR = rootCorner and rootCorner.CornerRadius or UDim.new(0, 8)

    local powerColors = { Theme.GlowColor, VIOLET, Theme.Crimson, LAV, Theme.Yellow }

    local function pickColor()
        local r = rand()
        if r < 0.30 then return Theme.GlowColor
        elseif r < 0.52 then return VIOLET
        elseif r < 0.62 then return LAV
        elseif r < 0.82 then return Theme.Crimson
        else return Theme.Yellow end
    end

    local function round(inst, radius)
        local c = Instance.new("UICorner")
        c.CornerRadius = radius or UDim.new(1, 0)
        c.Parent = inst
        return c
    end

    local function newFrame(parent, z)
        local f = Instance.new("Frame")
        f.BackgroundTransparency = 1
        f.BorderSizePixel = 0
        f.Size = UDim2.fromScale(1, 1)
        f.ZIndex = z or 1
        f.Parent = parent
        return f
    end

    ---------------------------------------------------------------------
    -- 1) LUZ AMBIENTAL EXTERIOR
    ---------------------------------------------------------------------
    local ambientLight = Instance.new("ImageLabel")
    ambientLight.Name = "AFO_AmbientLight"
    ambientLight.BackgroundTransparency = 1
    ambientLight.Image = Theme.Assets.AmbientGlow
    ambientLight.Size = UDim2.new(1, 140, 1, 140)
    ambientLight.Position = UDim2.new(0, -70, 0, -70)
    ambientLight.ZIndex = -5
    ambientLight.ImageTransparency = 0.4
    ambientLight.Parent = Root

    local ambientGradient = Instance.new("UIGradient")
    ambientGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Theme.Crimson),
        ColorSequenceKeypoint.new(0.3, VIOLET),
        ColorSequenceKeypoint.new(0.55, DEEP),
        ColorSequenceKeypoint.new(0.75, Color3.fromRGB(190, 140, 10)),
        ColorSequenceKeypoint.new(0.9, VIOLET),
        ColorSequenceKeypoint.new(1, Theme.Crimson),
    })
    ambientGradient.Parent = ambientLight

    ---------------------------------------------------------------------
    -- 2) CAPAS INTERNAS
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

    local tint = Instance.new("Frame")
    tint.BackgroundColor3 = Theme.DarkMatter
    tint.BackgroundTransparency = 0.45
    tint.BorderSizePixel = 0
    tint.Size = UDim2.fromScale(1, 1)
    tint.ZIndex = 2
    tint.Parent = art

    local fogBack = newFrame(art, 3)
    local fogMid = newFrame(art, 4)
    local fogFront = newFrame(art, 5)

    local function vignette(size, pos, rot)
        local v = Instance.new("Frame")
        v.BackgroundColor3 = Color3.new(0, 0, 0)
        v.BorderSizePixel = 0
        v.Size = size
        v.Position = pos
        v.ZIndex = 6
        local g = Instance.new("UIGradient")
        g.Rotation = rot
        g.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.2),
            NumberSequenceKeypoint.new(1, 1),
        })
        g.Parent = v
        v.Parent = art
    end
    vignette(UDim2.fromScale(1, 0.3), UDim2.fromScale(0, 0), 90)
    vignette(UDim2.fromScale(1, 0.3), UDim2.fromScale(0, 0.7), 270)
    vignette(UDim2.fromScale(0.2, 1), UDim2.fromScale(0, 0), 0)
    vignette(UDim2.fromScale(0.2, 1), UDim2.fromScale(0.8, 0), 180)

    local mist = Instance.new("Frame")
    mist.BackgroundColor3 = Color3.fromRGB(80, 16, 130)
    mist.BorderSizePixel = 0
    mist.Size = UDim2.fromScale(1, 0.5)
    mist.Position = UDim2.fromScale(0, 0.5)
    mist.ZIndex = 6
    local mg = Instance.new("UIGradient")
    mg.Rotation = 90
    mg.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(1, 0.6),
    })
    mg.Parent = mist
    mist.Parent = art

    local flash = Instance.new("Frame")
    flash.BackgroundColor3 = Theme.GlowColor
    flash.BackgroundTransparency = 1
    flash.BorderSizePixel = 0
    flash.Size = UDim2.fromScale(1, 1)
    flash.ZIndex = 7
    flash.Parent = art

    local glowLayer = newFrame(art, 8)
    local boltLayer = newFrame(art, 9)
    boltLayer.Name = "AFO_LightningStrikes"
    local partLayer = newFrame(art, 10)

    ---------------------------------------------------------------------
    -- 3) NUBES VOLUMÉTRICAS (3 capas de profundidad + núcleo iluminado + parallax)
    ---------------------------------------------------------------------
    local fogSpec = {
        { parent = fogBack, count = 3, sz = 1.9, tr = 0.60, par = 4, sp = 0.05, rot = 1.5,
          colors = { Color3.fromRGB(26, 6, 46), Color3.fromRGB(36, 8, 62), Color3.fromRGB(46, 10, 72) } },
        { parent = fogMid, count = 4, sz = 1.4, tr = 0.66, par = 11, sp = 0.09, rot = 3,
          colors = { Color3.fromRGB(60, 10, 95), Color3.fromRGB(76, 12, 116), Color3.fromRGB(88, 12, 70), Color3.fromRGB(54, 8, 86) } },
        { parent = fogFront, count = 3, sz = 1.0, tr = 0.74, par = 24, sp = 0.14, rot = 5,
          colors = { Color3.fromRGB(96, 24, 150), Color3.fromRGB(110, 28, 170), Color3.fromRGB(80, 14, 120) } },
    }
    local fog = {}
    local function cloudImg(parent)
        local p = Instance.new("ImageLabel")
        p.BackgroundTransparency = 1
        p.Image = Theme.Assets.CloudDarkness
        p.AnchorPoint = Vector2.new(0.5, 0.5)
        p.Parent = parent
        return p
    end
    for _, L in ipairs(fogSpec) do
        for i = 1, L.count do
            local base = L.colors[(i - 1) % #L.colors + 1]
            fog[#fog + 1] = {
                body = cloudImg(L.parent), rim = cloudImg(L.parent),
                base = base, rimC = base:Lerp(LAV, 0.45),
                sz = L.sz * (0.85 + rand() * 0.3), par = L.par,
                ax = (i - 0.5) / L.count + (rand() - 0.5) * 0.15, ay = 0.15 + rand() * 0.7,
                amp = 0.05 + rand() * 0.08, sp = L.sp * (0.8 + rand() * 0.5), ph = rand() * 6.28,
                rs = (rand() - 0.5) * L.rot, bt = L.tr, lit = 0, cx = 0.5, cy = 0.5,
            }
        end
    end

    ---------------------------------------------------------------------
    -- 4) LUZ DE RAYOS (glow en escena + derrame sobre toda la GUI)
    ---------------------------------------------------------------------
    local spill = Instance.new("Frame")
    spill.Name = "AFO_LightSpill"
    spill.BackgroundTransparency = 1
    spill.ClipsDescendants = true
    spill.Size = UDim2.fromScale(1, 1)
    spill.ZIndex = 50
    spill.Parent = Root
    round(spill, cornerR)

    local glows = {}
    local function addGlow(parent, pos, size, color, base, life)
        local g = Instance.new("ImageLabel")
        g.BackgroundTransparency = 1
        g.Image = Theme.Assets.AmbientGlow
        g.ImageColor3 = color
        g.AnchorPoint = Vector2.new(0.5, 0.5)
        g.Position = UDim2.fromOffset(pos.X, pos.Y)
        g.Size = UDim2.fromOffset(size, size)
        g.ImageTransparency = base
        g.Parent = parent
        glows[#glows + 1] = { obj = g, age = 0, life = life, base = base }
    end

    ---------------------------------------------------------------------
    -- 5) PARTÍCULAS
    ---------------------------------------------------------------------
    local particles = {}
    local function newParticle(parent)
        local f = Instance.new("Frame")
        f.BorderSizePixel = 0
        f.AnchorPoint = Vector2.new(0.5, 0.5)
        round(f)
        local h = Instance.new("Frame")
        h.BorderSizePixel = 0
        h.AnchorPoint = Vector2.new(0.5, 0.5)
        h.Position = UDim2.fromScale(0.5, 0.5)
        h.Size = UDim2.fromScale(3.4, 3.4)
        h.BackgroundTransparency = 0.88
        round(h)
        h.Parent = f
        f.Parent = parent
        local p = { f = f, h = h, age = 0, life = 1, x = 0, y = 0, vx = 0, vy = 0, sway = 0, swayF = 1, phase = rand() * 6.28, gravity = 0, mode = "soft", size = 3 }
        particles[#particles + 1] = p
        return p
    end

    local function paint(p, color, size)
        p.size = size
        p.f.BackgroundColor3 = color
        p.h.BackgroundColor3 = color
        p.f.Size = UDim2.fromOffset(size, size)
    end

    local function resetAmbient(p, initial)
        local sz = art.AbsoluteSize
        local W, H = math.max(sz.X, 300), math.max(sz.Y, 200)
        p.x = rand() * W
        p.y = initial and rand() * H or H + 8
        p.vx = (rand() - 0.5) * 14
        p.vy = -(14 + rand() * 34)
        p.sway = 6 + rand() * 14
        p.swayF = 0.6 + rand() * 1.4
        p.life = 5 + rand() * 6
        p.age = initial and rand() * p.life or 0
        paint(p, pickColor(), 2 + rand() * 3.2)
    end

    for _ = 1, 34 do
        local p = newParticle(partLayer)
        p.reset = resetAmbient
        resetAmbient(p, true)
    end

    local function burst(pos, count, parent, speed)
        for _ = 1, count do
            if #particles > 130 then return end
            local p = newParticle(parent)
            local a = rand() * math.pi * 2
            local sp = (speed or 120) * (0.4 + rand())
            p.x, p.y = pos.X, pos.Y
            p.vx, p.vy = math.cos(a) * sp, math.sin(a) * sp - 40
            p.gravity = 380
            p.life = 0.4 + rand() * 0.6
            p.mode = "spark"
            paint(p, rand() < 0.4 and Theme.Yellow or pickColor(), 2 + rand() * 2.5)
        end
    end

    ---------------------------------------------------------------------
    -- 6) RAYOS DE PLASMA (bordes suaves, trazo que se arrastra, ramas y arcos de impacto)
    ---------------------------------------------------------------------
    local energyGradient -- se define en la sección del borde

    local function boltPath(a, b, detail, spread)
        local pts = { a, b }
        for _ = 1, detail do
            local new = {}
            for j = 1, #pts - 1 do
                local p1, p2 = pts[j], pts[j + 1]
                local d = p2 - p1
                local n = d.Magnitude > 0 and Vector2.new(-d.Y, d.X).Unit or Vector2.new(1, 0)
                new[#new + 1] = p1
                new[#new + 1] = (p1 + p2) / 2 + n * ((rand() - 0.5) * spread)
            end
            new[#new + 1] = pts[#pts]
            pts = new
            spread = spread / 2
        end
        return pts
    end

    local function lightUp(pos, color, power)
        S.surge = math.max(S.surge, power)
        S.flashColor = color
        local W = math.max(art.AbsoluteSize.X, 1)
        local H = math.max(art.AbsoluteSize.Y, 1)
        for _, f in ipairs(fog) do
            local c = Vector2.new(f.cx * W, f.cy * H)
            local infl = math.clamp(1 - (c - pos).Magnitude / (W * 0.75), 0, 1) ^ 1.4
            f.lit = math.max(f.lit, infl * power)
        end
        addGlow(glowLayer, pos, 460 * power + 120, color, 0.3, 0.55)
        addGlow(spill, pos, 760 * power + 200, color, 0.86, 0.45)
    end

    local function strike()
        local sz = art.AbsoluteSize
        local W, H = sz.X, sz.Y
        if W < 60 or H < 60 then return end
        local color = powerColors[rand(1, #powerColors)]

        local side = rand(1, 5)
        local sx, sy
        if side <= 3 then sx, sy = rand() * W, -12
        elseif side == 4 then sx, sy = -12, rand() * H * 0.4
        else sx, sy = W + 12, rand() * H * 0.4 end
        local a = Vector2.new(sx, sy)
        local b = Vector2.new(W * (0.15 + rand() * 0.7), H * (0.35 + rand() * 0.6))
        local len = (b - a).Magnitude

        local container = newFrame(boltLayer, 1)
        local paths = {}

        local function addPath(pts, scale, full)
            local path = { pts = pts, scale = scale, layers = {} }
            local specs = {
                { th = 20, col = color, base = 0.35, g = { 1, 0.3, 1 } },
                { th = 7, col = color:Lerp(WHITE, 0.55), base = 0.1, g = { 1, 0, 1 } },
                { th = 2.2, col = WHITE, base = 0, g = { 0.75, 0, 0.75 } },
            }
            for si, sp in ipairs(specs) do
                if full or si ~= 2 then
                    local layer = { th = sp.th, base = sp.base, frames = {} }
                    for i = 1, #pts - 1 do
                        local f = Instance.new("Frame")
                        f.BorderSizePixel = 0
                        f.AnchorPoint = Vector2.new(0.5, 0.5)
                        f.BackgroundColor3 = sp.col
                        f.BackgroundTransparency = sp.base
                        f.ZIndex = si
                        local g = Instance.new("UIGradient")
                        g.Rotation = 90
                        g.Transparency = NumberSequence.new({
                            NumberSequenceKeypoint.new(0, sp.g[1]),
                            NumberSequenceKeypoint.new(0.5, sp.g[2]),
                            NumberSequenceKeypoint.new(1, sp.g[3]),
                        })
                        g.Parent = f
                        f.Parent = container
                        layer.frames[i] = f
                    end
                    path.layers[#path.layers + 1] = layer
                end
            end
            paths[#paths + 1] = path
        end

        local function layout(path, jit)
            local pts = path.pts
            local n = #pts
            local cur = {}
            for i = 1, n do
                local p = pts[i]
                if i > 1 and i < n and jit > 0 then
                    p = p + Vector2.new((rand() - 0.5) * jit, (rand() - 0.5) * jit)
                end
                cur[i] = p
            end
            local flick = 0.75 + rand() * 0.5
            for _, layer in ipairs(path.layers) do
                for i = 1, n - 1 do
                    local p1, p2 = cur[i], cur[i + 1]
                    local d = p2 - p1
                    local m = (p1 + p2) / 2
                    local taper = 1.1 - 0.5 * (i / (n - 1))
                    local f = layer.frames[i]
                    f.Position = UDim2.fromOffset(m.X, m.Y)
                    f.Size = UDim2.fromOffset(d.Magnitude + layer.th * 0.4, layer.th * taper * path.scale * flick)
                    f.Rotation = math.deg(math.atan2(d.Y, d.X))
                end
            end
        end

        local function setFade(fade)
            for _, path in ipairs(paths) do
                for _, layer in ipairs(path.layers) do
                    for _, f in ipairs(layer.frames) do
                        f.BackgroundTransparency = layer.base + (1 - layer.base) * fade
                    end
                end
            end
        end

        local pts = boltPath(a, b, 5, len * 0.2)
        addPath(pts, 1, true)

        local dir = (b - a).Unit
        for _ = 1, rand(2, 4) do
            local origin = pts[rand(3, #pts - 4)]
            local ang = math.rad((rand() * 70 + 15) * (rand() < 0.5 and -1 or 1))
            local cs, sn = math.cos(ang), math.sin(ang)
            local d = Vector2.new(dir.X * cs - dir.Y * sn, dir.X * sn + dir.Y * cs)
            local bl = len * (0.12 + rand() * 0.2)
            addPath(boltPath(origin, origin + d * bl, 3, bl * 0.35), 0.5, false)
        end
        -- Arcos de impacto radiales
        for _ = 1, rand(5, 8) do
            local ang = rand() * math.pi * 2
            local l = 25 + rand() * 55
            addPath(boltPath(b, b + Vector2.new(math.cos(ang), math.sin(ang)) * l, 2, l * 0.45), 0.45, false)
        end

        lightUp(b, color, 1)
        lightUp(pts[math.floor(#pts / 3)], color, 0.6)
        lightUp(pts[math.floor(#pts * 2 / 3)], color, 0.6)
        burst(b, 16, partLayer, 160)
        S.tglitch = 0.25

        -- Onda de energía que recorre el borde desde el lado del impacto
        local c = Vector2.new(W / 2, H / 2)
        if energyGradient then
            energyGradient.Rotation = math.deg(math.atan2(c.Y - b.Y, c.X - b.X))
            energyGradient.Color = ColorSequence.new(WHITE:Lerp(color, 0.45))
        end
        S.wave = 0

        task.spawn(function()
            for _, fade in ipairs({ 0, 0.6, 0.05, 0.8, 0, 0.5, 0.15 }) do
                for _, path in ipairs(paths) do layout(path, 7) end
                setFade(fade)
                if fade < 0.1 then
                    S.surge = 1
                    lightUp(b, color, 0.55)
                end
                task.wait(0.03 + rand() * 0.035)
            end
            for i = 1, 10 do
                for _, path in ipairs(paths) do layout(path, 4) end
                setFade(i / 10)
                task.wait(0.03)
            end
            container:Destroy()
        end)
    end

    task.spawn(function()
        task.wait(1)
        while alive do
            pcall(strike)
            if rand() < 0.3 then
                task.wait(0.07 + rand() * 0.12)
                pcall(strike)
            end
            task.wait(1.1 + rand() * 2.4)
        end
    end)

    ---------------------------------------------------------------------
    -- 7) BORDE DE ENERGÍA (crepitante, con onda de impacto)
    ---------------------------------------------------------------------
    local stroke = Root:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke")
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Color = WHITE
    stroke.Transparency = 0
    stroke.Parent = Root

    local strokeGradient = stroke:FindFirstChildOfClass("UIGradient") or Instance.new("UIGradient")
    strokeGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Theme.Crimson),
        ColorSequenceKeypoint.new(0.18, DEEP),
        ColorSequenceKeypoint.new(0.36, VIOLET),
        ColorSequenceKeypoint.new(0.52, DEEP),
        ColorSequenceKeypoint.new(0.6, Theme.Yellow),
        ColorSequenceKeypoint.new(0.67, VIOLET),
        ColorSequenceKeypoint.new(0.84, DEEP),
        ColorSequenceKeypoint.new(1, Theme.Crimson),
    })
    strokeGradient.Parent = stroke

    local halo = Instance.new("Frame")
    halo.Name = "AFO_EdgeHalo"
    halo.BackgroundTransparency = 1
    halo.AnchorPoint = Vector2.new(0.5, 0.5)
    halo.Position = UDim2.fromScale(0.5, 0.5)
    halo.Size = UDim2.new(1, 12, 1, 12)
    halo.ZIndex = 0
    halo.Parent = Root
    round(halo, UDim.new(cornerR.Scale, cornerR.Offset + 6))
    local haloStroke = Instance.new("UIStroke")
    haloStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    haloStroke.Color = WHITE
    haloStroke.Thickness = 5
    haloStroke.Transparency = 0.65
    haloStroke.Parent = halo
    local haloGradient = Instance.new("UIGradient")
    haloGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, DEEP),
        ColorSequenceKeypoint.new(0.33, Theme.Crimson),
        ColorSequenceKeypoint.new(0.66, VIOLET),
        ColorSequenceKeypoint.new(1, DEEP),
    })
    haloGradient.Parent = haloStroke

    local energyEdge = Instance.new("Frame")
    energyEdge.Name = "AFO_EnergyEdge"
    energyEdge.BackgroundTransparency = 1
    energyEdge.Size = UDim2.fromScale(1, 1)
    energyEdge.ZIndex = 56
    energyEdge.Parent = Root
    round(energyEdge, cornerR)
    local energyStroke = Instance.new("UIStroke")
    energyStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    energyStroke.Color = WHITE
    energyStroke.Thickness = 3
    energyStroke.Transparency = 1
    energyStroke.Parent = energyEdge
    energyGradient = Instance.new("UIGradient")
    energyGradient.Color = ColorSequence.new(WHITE)
    energyGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.42, 1),
        NumberSequenceKeypoint.new(0.5, 0),
        NumberSequenceKeypoint.new(0.58, 1),
        NumberSequenceKeypoint.new(1, 1),
    })
    energyGradient.Parent = energyStroke

    local orbs = {}
    local corners = { Vector2.new(0, 0), Vector2.new(1, 0), Vector2.new(0, 1), Vector2.new(1, 1) }
    for i, c in ipairs(corners) do
        local o = Instance.new("Frame")
        o.BorderSizePixel = 0
        o.AnchorPoint = Vector2.new(0.5, 0.5)
        o.Position = UDim2.fromScale(c.X, c.Y)
        o.BackgroundColor3 = (i % 2 == 0) and Theme.Yellow or Theme.Crimson
        o.ZIndex = 55
        round(o)
        local h = Instance.new("Frame")
        h.BorderSizePixel = 0
        h.AnchorPoint = Vector2.new(0.5, 0.5)
        h.Position = UDim2.fromScale(0.5, 0.5)
        h.Size = UDim2.fromScale(3, 3)
        h.BackgroundColor3 = o.BackgroundColor3
        h.BackgroundTransparency = 0.8
        round(h)
        h.Parent = o
        o.Parent = Root
        orbs[i] = { o = o, ph = i * 1.3 }
    end

    ---------------------------------------------------------------------
    -- 8) TÍTULO (letras justificadas) Y TARJETA DE USUARIO
    ---------------------------------------------------------------------
    local TITLE = "All For One"
    local TITLE_BASE = Color3.fromRGB(232, 220, 250)
    local titleLabel, titleTarget
    local letters = {}
    local titleFX = newFrame(Root, 60)
    titleFX.Name = "AFO_TitleFX"

    local function findSideBar()
        for _, obj in ipairs(Root:GetDescendants()) do
            if obj:IsA("TextBox") then
                local ph = obj.PlaceholderText:lower()
                if ph:find("search", 1, true) or ph:find("buscar", 1, true) then
                    local bar = obj.Parent
                    while bar and bar ~= Root and bar:IsA("GuiObject") and bar.AbsoluteSize.X < 100 do
                        bar = bar.Parent
                    end
                    if bar and bar ~= Root and bar:IsA("GuiObject") then return bar end
                end
            end
        end
    end

    local function measure(size)
        local ws, sum = {}, 0
        for i = 1, #TITLE do
            local ch = TITLE:sub(i, i)
            local w
            if ch == " " then
                w = size * 0.32
            else
                w = TextService:GetTextSize(ch, size, Enum.Font.GothamBlack, Vector2.new(1000, 1000)).X
            end
            ws[i] = w
            sum = sum + w
        end
        return ws, sum
    end

    local function setupTitle(label)
        label:SetAttribute("AFO", true)
        local bar = findSideBar()
        local target = bar and bar.AbsoluteSize.X or math.clamp(Root.AbsoluteSize.X * 0.25, 150, 240)

        label.AutomaticSize = Enum.AutomaticSize.None
        label.RichText = false
        label.Text = TITLE
        label.TextTransparency = 1
        label.TextStrokeTransparency = 1
        local h = math.max(label.AbsoluteSize.Y, 30)
        label.Size = UDim2.fromOffset(target, h)
        if bar then
            local dx = bar.AbsolutePosition.X - label.AbsolutePosition.X
            if math.abs(dx) > 1 then label.Position = label.Position + UDim2.fromOffset(dx, 0) end
        end
        titleTarget = target

        local size = 14
        for s = 30, 14, -1 do
            local _, sum = measure(s)
            if sum + (#TITLE - 1) * 1.5 <= target then size = s break end
        end
        local ws, sum = measure(size)
        local extra = math.max(0, (target - sum) / (#TITLE - 1))

        local box = newFrame(label, label.ZIndex + 1)
        box.Name = "AFO_Letters"
        local x = 0
        for i = 1, #TITLE do
            local ch = TITLE:sub(i, i)
            if ch ~= " " then
                local l = Instance.new("TextLabel")
                l:SetAttribute("AFO", true)
                l.BackgroundTransparency = 1
                l.Font = Enum.Font.GothamBlack
                l.TextSize = size
                l.Text = ch
                l.TextColor3 = TITLE_BASE
                l.TextXAlignment = Enum.TextXAlignment.Center
                l.TextYAlignment = Enum.TextYAlignment.Center
                l.Size = UDim2.new(0, ws[i] + 2, 1, 0)
                l.Position = UDim2.fromOffset(x, 0)
                local st = Instance.new("UIStroke")
                st.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
                st.Color = Color3.fromRGB(50, 6, 85)
                st.Thickness = 1.3
                st.Transparency = 0.25
                st.Parent = l
                l.Parent = box
                letters[#letters + 1] = { l = l, x = x, u = (x + ws[i] / 2) / target }
            end
            x = x + ws[i] + extra
        end

        label:GetPropertyChangedSignal("Text"):Connect(function()
            if label.Text ~= TITLE then label.Text = TITLE end
        end)
        titleLabel = label
    end

    -- Oculta por completo el badge de versión ("2.0")
    local function hideBadge(lbl)
        lbl:SetAttribute("AFO", true)
        local target = lbl
        local par = lbl.Parent
        if lbl.BackgroundTransparency >= 1 and par and par:IsA("GuiObject") and par ~= Root
            and par.BackgroundTransparency < 1 and par.AbsoluteSize.X < 100 then
            target = par
        end
        target.Visible = false
        target:GetPropertyChangedSignal("Visible"):Connect(function()
            if target.Visible then target.Visible = false end
        end)
    end

    -- Tarjeta de usuario: arriba nombre visible, abajo @usuario. Oculto: Villain / @******
    local userTop, userBottom
    local userHidden = false
    local function renderUser()
        if not (userTop and userBottom) then return end
        local topT = userHidden and "Villain" or lp.DisplayName
        local botT = userHidden and "@******" or ("@" .. lp.Name)
        if userTop.Text ~= topT then userTop.Text = topT end
        if userBottom.Text ~= botT then userBottom.Text = botT end
    end

    local function setupUser(top, bottom)
        userTop, userBottom = top, bottom
        top:SetAttribute("AFO", true)
        bottom:SetAttribute("AFO", true)
        top.TextTruncate = Enum.TextTruncate.AtEnd
        local tt = top.Text
        local raw = (bottom.Text:gsub("^@", ""))
        userHidden = (tt == "Anonymous" or tt == "Villain" or raw:match("^%*+$") ~= nil)
        top:GetPropertyChangedSignal("Text"):Connect(function()
            local tx = top.Text
            if tx == "Villain" then return end
            userHidden = (tx == "Anonymous")
            renderUser()
        end)
        bottom:GetPropertyChangedSignal("Text"):Connect(function()
            local r = (bottom.Text:gsub("^@", ""))
            if r:match("^%*+$") then userHidden = true
            elseif r == lp.Name then userHidden = false end
            renderUser()
        end)
        renderUser()
    end

    local function applyTexts()
        if not alive or not Root.Parent then return end
        local rootY = Root.AbsolutePosition.Y
        local titleCands, badgeCands = {}, {}
        local bottomCand

        for _, obj in ipairs(Root:GetDescendants()) do
            if obj:IsA("Frame") and obj.Size == UDim2.new(0, 6, 0, 6) then
                obj.BackgroundColor3 = Theme.Crimson
            end
            if obj:IsA("TextLabel") and not obj:GetAttribute("AFO") then
                local txt = obj.Text
                local rel = obj.AbsolutePosition.Y - rootY
                if rel < 52 then
                    local l = txt:lower()
                    if l:find("all for one", 1, true) or l:find("todo para uno", 1, true) then
                        titleCands[#titleCands + 1] = obj
                    elseif txt:match("^%s*%(?%s*[vV]?%d+%.%d+%s*%)?%s*$") then
                        badgeCands[#badgeCands + 1] = obj
                    end
                elseif not bottomCand and not userTop then
                    local raw = (txt:gsub("^@", ""))
                    if raw == lp.Name or raw:match("^%*+$") then bottomCand = obj end
                end
            end
        end

        -- Título
        if #titleCands > 0 then
            local main = titleLabel
            if not main then
                main = titleCands[1]
                for _, c in ipairs(titleCands) do
                    if c.Text:lower():find("all for one", 1, true) then main = c break end
                end
                setupTitle(main)
            end
            for _, c in ipairs(titleCands) do
                if c ~= main then
                    c.Visible = false
                    c:SetAttribute("AFO", true)
                end
            end
        end

        -- Badge de versión: se oculta
        for _, c in ipairs(badgeCands) do hideBadge(c) end

        -- Tarjeta de usuario
        if bottomCand and not userTop then
            local top
            local bestDy = math.huge
            for _, obj in ipairs(Root:GetDescendants()) do
                if obj:IsA("TextLabel") and obj ~= bottomCand and not obj:GetAttribute("AFO") then
                    local dy = bottomCand.AbsolutePosition.Y - obj.AbsolutePosition.Y
                    local dx = math.abs(bottomCand.AbsolutePosition.X - obj.AbsolutePosition.X)
                    if dy > 0 and dy < 40 and dx < 40 and dy < bestDy then
                        top, bestDy = obj, dy
                    end
                end
            end
            if top then setupUser(top, bottomCand) end
        end
    end

    task.spawn(function()
        task.wait(0.5)
        applyTexts()
        task.wait(1.5)
        applyTexts()
    end)
    local pending = false
    Root.DescendantAdded:Connect(function(d)
        if not (d:IsA("TextLabel") or d:IsA("TextBox")) then return end
        if d:IsDescendantOf(art) or d:IsDescendantOf(titleFX) or d:IsDescendantOf(spill) then return end
        if pending then return end
        pending = true
        task.delay(0.3, function()
            pending = false
            applyTexts()
        end)
    end)

    ---------------------------------------------------------------------
    -- 9) BUCLE PRINCIPAL
    ---------------------------------------------------------------------
    local hb
    local titleAcc = 0
    hb = RunService.Heartbeat:Connect(function(dt)
        if not alive or not Root.Parent then
            alive = false
            hb:Disconnect()
            return
        end
        dt = math.min(dt, 0.1)
        S.t = S.t + dt
        local t = S.t
        S.surge = math.max(0, S.surge - dt * 2.2)
        S.tglitch = math.max(0, S.tglitch - dt)
        local sg = S.surge

        -- Parallax con el mouse (profundidad de las nubes)
        local rs = Root.AbsoluteSize
        local rc = Root.AbsolutePosition + rs / 2
        local mouse = UserInputService:GetMouseLocation()
        local tx = math.clamp((mouse.X - rc.X) / math.max(rs.X, 1), -1, 1)
        local ty = math.clamp((mouse.Y - rc.Y) / math.max(rs.Y, 1), -1, 1)
        local k = math.min(1, dt * 3)
        S.px = S.px + (tx - S.px) * k
        S.py = S.py + (ty - S.py) * k

        -- Luz ambiental exterior
        ambientGradient.Rotation = (t * 30) % 360
        ambientLight.ImageTransparency = math.clamp(0.42 + math.sin(t * 2) * 0.12 - sg * 0.3, 0, 1)
        ambientLight.ImageColor3 = WHITE:Lerp(S.flashColor, sg * 0.7)
        local grow = 70 + sg * 45
        ambientLight.Size = UDim2.new(1, grow * 2, 1, grow * 2)
        ambientLight.Position = UDim2.new(0, -grow, 0, -grow)

        flash.BackgroundColor3 = S.flashColor
        flash.BackgroundTransparency = 1 - sg * 0.16
        mist.BackgroundColor3 = Color3.fromRGB(80, 16, 130):Lerp(S.flashColor, sg * 0.5)
        mist.BackgroundTransparency = 0.08 + math.sin(t * 0.6) * 0.06 - sg * 0.08

        -- Nubes volumétricas
        for _, f in ipairs(fog) do
            f.lit = f.lit * math.exp(-dt * 3.2)
            local x = f.ax + math.sin(t * f.sp + f.ph) * f.amp
            local y = f.ay + math.cos(t * f.sp * 0.8 + f.ph) * f.amp * 0.7
            f.cx, f.cy = x, y
            local bil = 1 + 0.04 * math.sin(t * 0.3 + f.ph)
            local L = math.clamp(f.lit, 0, 1)
            local ox, oy = S.px * f.par, S.py * f.par
            local rot = (t * f.rs) % 360

            f.body.Position = UDim2.new(x, ox, y, oy)
            f.body.Size = UDim2.fromScale(f.sz * bil, f.sz * bil)
            f.body.Rotation = rot
            f.body.ImageTransparency = math.clamp(f.bt + math.sin(t * 0.4 + f.ph) * 0.03 - L * 0.35, 0.15, 1)
            f.body.ImageColor3 = f.base:Lerp(S.flashColor, L * 0.6)

            f.rim.Position = UDim2.new(x - 0.012, ox * 1.25, y - 0.02, oy * 1.25)
            f.rim.Size = UDim2.fromScale(f.sz * 0.85 * bil, f.sz * 0.85 * bil)
            f.rim.Rotation = rot + 8
            f.rim.ImageTransparency = math.clamp(f.bt + 0.1 - L * 0.5, 0.1, 1)
            f.rim.ImageColor3 = f.rimC:Lerp(S.flashColor, L * 0.9)
        end

        -- Glows de rayos
        for i = #glows, 1, -1 do
            local g = glows[i]
            g.age = g.age + dt
            if g.age >= g.life then
                g.obj:Destroy()
                table.remove(glows, i)
            else
                g.obj.ImageTransparency = g.base + (1 - g.base) * (g.age / g.life) ^ 0.6
            end
        end

        -- Borde: crepita (no lineal), con onda de energía en el impacto
        local noise = math.noise(t * 1.3, 0, 0)
        local crack = sg * sg
        stroke.Thickness = 2.2 + math.abs(noise) * 2 + math.sin(t * 2.5) * 0.6 + crack * (1.5 + rand() * 3.5)
        strokeGradient.Rotation = (t * (45 + sg * 250)) % 360
        haloStroke.Thickness = 5 + math.abs(math.noise(t * 0.9, 3, 0)) * 5 + crack * rand() * 10
        haloStroke.Transparency = math.clamp(0.68 - sg * 0.4 + math.sin(t * 1.7) * 0.06 + (rand() - 0.5) * crack * 0.2, 0, 1)
        haloGradient.Rotation = (-t * (30 + sg * 200)) % 360

        if S.wave < 1 then
            S.wave = math.min(1, S.wave + dt * 1.7)
            energyGradient.Offset = Vector2.new(-1 + 2 * S.wave, 0)
            energyStroke.Thickness = 2.5 + rand() * 4
            energyStroke.Transparency = 0.05 + rand() * 0.25
        else
            energyStroke.Transparency = 1
        end

        for _, o in ipairs(orbs) do
            local s = 6 + math.sin(t * 3 + o.ph) * 1.5 + sg * 9
            o.o.Size = UDim2.fromOffset(s, s)
        end

        -- Título: barrido de luz, glitch por letra, emisor de chispas
        if titleLabel and titleLabel.Parent and #letters > 0 then
            local sweep = (t * 0.5) % 1.6 - 0.3
            local gl = S.tglitch > 0
            if not gl and rand() < 0.004 then S.tglitch = 0.12 end
            for _, L in ipairs(letters) do
                local kk = math.clamp(1 - math.abs(L.u - sweep) * 4.5, 0, 1)
                local c = TITLE_BASE:Lerp(Color3.fromRGB(255, 225, 190), kk):Lerp(S.flashColor, sg * 0.75)
                if gl then
                    L.l.Position = UDim2.new(0, L.x + rand(-2, 2), 0, rand(-2, 2))
                    if rand() < 0.35 then c = (rand() < 0.5) and Theme.Crimson or VIOLET end
                    L.dirty = true
                elseif L.dirty then
                    L.l.Position = UDim2.fromOffset(L.x, 0)
                    L.dirty = false
                end
                L.l.TextColor3 = c
            end

            titleAcc = titleAcc + dt * 16
            local rp, ap = Root.AbsolutePosition, titleLabel.AbsolutePosition
            local sz = titleLabel.AbsoluteSize
            while titleAcc >= 1 do
                titleAcc = titleAcc - 1
                if #particles < 110 and sz.X > 4 then
                    local p = newParticle(titleFX)
                    p.x = (ap.X - rp.X) + rand() * sz.X
                    p.y = (ap.Y - rp.Y) + rand() * sz.Y
                    p.vx = (rand() - 0.5) * 30
                    p.vy = -(10 + rand() * 35)
                    p.gravity = -10
                    p.life = 0.7 + rand() * 0.7
                    p.swayF = 3
                    p.sway = 6
                    paint(p, pickColor(), 1.5 + rand() * 1.8)
                end
            end
        end

        -- Partículas
        for i = #particles, 1, -1 do
            local p = particles[i]
            p.age = p.age + dt
            local dead = false
            if p.age >= p.life then
                if p.reset then
                    p.reset(p, false)
                else
                    p.f:Destroy()
                    table.remove(particles, i)
                    dead = true
                end
            end
            if not dead then
                p.vy = p.vy + p.gravity * dt
                p.x = p.x + (p.vx + math.cos(t * p.swayF + p.phase) * p.sway) * dt
                p.y = p.y + p.vy * dt
                local r = math.clamp(p.age / p.life, 0, 1)
                local a = (p.mode == "spark") and (1 - r * r) or math.sin(math.pi * r)
                a = a * (0.8 + 0.2 * math.sin(t * 8 + p.phase))
                p.f.Position = UDim2.fromOffset(p.x, p.y)
                p.f.BackgroundTransparency = 1 - a * 0.95
                p.h.BackgroundTransparency = 1 - a * 0.18
            end
        end
    end)

    Root.AncestryChanged:Connect(function()
        if not Root:IsDescendantOf(game) then alive = false end
    end)
end

return Theme
