-- ═══════════════════════════════════════════════════════════════════════════
--  ALL FOR ONE THEME - V9 (STORM CORE)
--  Rayos procedurales con ramas, luz ambiental que ilumina la GUI, niebla
--  reactiva, partículas de paleta, borde de energía viva y título renovado.
-- ═══════════════════════════════════════════════════════════════════════════
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

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
    CloudDarkness = "rbxassetid://8992237346",
    AmbientGlow = "rbxassetid://1868803131",
}

Theme.BuildDesign = function(Window)
    local Root = Window.Root
    local acrylicFrame = Window.AcrylicPaint.Frame
    local lp = Players.LocalPlayer
    local rand = math.random
    local WHITE = Color3.new(1, 1, 1)

    local alive = true
    local S = { t = 0, surge = 0, flashColor = Theme.GlowColor, tglitch = 0 }

    local rootCorner = Root:FindFirstChildOfClass("UICorner")
    local cornerR = rootCorner and rootCorner.CornerRadius or UDim.new(0, 8)

    local powerColors = { Theme.GlowColor, Theme.Crimson, Theme.Yellow, Color3.fromRGB(200, 190, 255) }

    local function pickColor()
        local r = rand()
        if r < 0.38 then return Theme.Yellow
        elseif r < 0.68 then return Theme.GlowColor
        elseif r < 0.90 then return Theme.Crimson
        else return Theme.IconColor end
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
    -- 1) AMBIENT LIGHT EXTERIOR (sangrado de luz fuera del Hub)
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
        ColorSequenceKeypoint.new(0.5, Theme.GlowColor),
        ColorSequenceKeypoint.new(1, Theme.Yellow),
    })
    ambientGradient.Parent = ambientLight

    ---------------------------------------------------------------------
    -- 2) CAPAS INTERNAS (fondo, niebla, viñeta, luz, rayos, partículas)
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

    local fogLayer = newFrame(art, 2)
    fogLayer.Name = "Fog"

    local tint = Instance.new("Frame")
    tint.BackgroundColor3 = Theme.DarkMatter
    tint.BackgroundTransparency = 0.5
    tint.BorderSizePixel = 0
    tint.Size = UDim2.fromScale(1, 1)
    tint.ZIndex = 3
    tint.Parent = art

    -- Viñeta de oclusión: los bordes se hunden en oscuridad
    local function vignette(size, pos, rot)
        local v = Instance.new("Frame")
        v.BackgroundColor3 = Color3.new(0, 0, 0)
        v.BorderSizePixel = 0
        v.Size = size
        v.Position = pos
        v.ZIndex = 3
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

    -- Bruma baja
    local mist = Instance.new("Frame")
    mist.BackgroundColor3 = Color3.fromRGB(90, 20, 140)
    mist.BorderSizePixel = 0
    mist.Size = UDim2.fromScale(1, 0.5)
    mist.Position = UDim2.fromScale(0, 0.5)
    mist.ZIndex = 3
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
    flash.ZIndex = 4
    flash.Parent = art

    local glowLayer = newFrame(art, 5)
    glowLayer.Name = "StrikeGlows"
    local boltLayer = newFrame(art, 6)
    boltLayer.Name = "AFO_LightningStrikes"
    local partLayer = newFrame(art, 7)
    partLayer.Name = "Particles"

    -- Niebla: nubes que derivan y rotan sin patrón de cruz; se encienden con los rayos
    local fogColors = {
        Color3.fromRGB(70, 12, 105), Color3.fromRGB(125, 10, 40), Color3.fromRGB(95, 25, 150),
        Color3.fromRGB(140, 105, 10), Color3.fromRGB(60, 8, 90), Color3.fromRGB(110, 12, 55),
    }
    local fog = {}
    for i = 1, #fogColors do
        local p = Instance.new("ImageLabel")
        p.BackgroundTransparency = 1
        p.Image = Theme.Assets.CloudDarkness
        p.AnchorPoint = Vector2.new(0.5, 0.5)
        p.Size = UDim2.fromScale(1.2 + rand() * 0.5, 1.2 + rand() * 0.5)
        p.ImageColor3 = fogColors[i]
        p.ImageTransparency = 0.88
        p.Parent = fogLayer
        fog[i] = {
            obj = p, base = fogColors[i], ax = 0.1 + (i - 1) / 5 * 0.8, ay = 0.2 + rand() * 0.6,
            amp = 0.08 + rand() * 0.1, sp = 0.12 + rand() * 0.15, ph = rand() * 6.28,
            rs = (rand() - 0.5) * 4, bt = 0.84 + rand() * 0.06, lit = 0,
        }
    end

    ---------------------------------------------------------------------
    -- 3) LUZ DE RAYOS (glow en la escena + derrame de luz sobre toda la GUI)
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
    -- 4) SISTEMA DE PARTÍCULAS (paleta: violeta, carmesí, dorado)
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
            paint(p, rand() < 0.5 and Theme.Yellow or pickColor(), 2 + rand() * 2.5)
        end
    end

    ---------------------------------------------------------------------
    -- 5) RAYOS PROCEDURALES (zigzag fractal, ramas, destello y reencendido)
    ---------------------------------------------------------------------
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
        for _, f in ipairs(fog) do
            local c = Vector2.new(f.obj.Position.X.Scale * art.AbsoluteSize.X, f.obj.Position.Y.Scale * art.AbsoluteSize.Y)
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
        local items = {}

        local function addSegs(pts, scale, full)
            local layers = {
                { th = 9 * scale, col = color, tr = 0.62, z = 1 },
                { th = 4.5 * scale, col = color:Lerp(WHITE, 0.5), tr = 0.25, z = 2 },
                { th = 1.8 * scale, col = WHITE, tr = 0, z = 3 },
            }
            for _, L in ipairs(layers) do
                if full or L.z ~= 2 then
                    for i = 1, #pts - 1 do
                        local p1, p2 = pts[i], pts[i + 1]
                        local d = p2 - p1
                        local m = (p1 + p2) / 2
                        local s = Instance.new("Frame")
                        s.BorderSizePixel = 0
                        s.AnchorPoint = Vector2.new(0.5, 0.5)
                        s.Position = UDim2.fromOffset(m.X, m.Y)
                        s.Size = UDim2.fromOffset(d.Magnitude + L.th * 0.5, L.th)
                        s.Rotation = math.deg(math.atan2(d.Y, d.X))
                        s.BackgroundColor3 = L.col
                        s.BackgroundTransparency = L.tr
                        s.ZIndex = L.z
                        s.Parent = container
                        items[#items + 1] = { f = s, base = L.tr }
                    end
                end
            end
        end

        local pts = boltPath(a, b, 5, len * 0.22)
        addSegs(pts, 1, true)

        local dir = (b - a).Unit
        for _ = 1, rand(2, 4) do
            local origin = pts[rand(3, #pts - 4)]
            local ang = math.rad((rand() * 70 + 15) * (rand() < 0.5 and -1 or 1))
            local cs, sn = math.cos(ang), math.sin(ang)
            local d = Vector2.new(dir.X * cs - dir.Y * sn, dir.X * sn + dir.Y * cs)
            local bl = len * (0.12 + rand() * 0.2)
            addSegs(boltPath(origin, origin + d * bl, 3, bl * 0.3), 0.5, false)
        end

        local function setFade(fade)
            for _, it in ipairs(items) do
                it.f.BackgroundTransparency = it.base + (1 - it.base) * fade
            end
        end

        -- Luz a lo largo del rayo + impacto
        lightUp(b, color, 1)
        lightUp(pts[math.floor(#pts / 3)], color, 0.6)
        lightUp(pts[math.floor(#pts * 2 / 3)], color, 0.6)
        burst(b, 16, partLayer, 160)
        S.tglitch = 0.25

        task.spawn(function()
            for _, fade in ipairs({ 0, 0.7, 0.05, 0.85, 0, 0.45 }) do
                setFade(fade)
                if fade < 0.1 then
                    S.surge = 1
                    lightUp(b, color, 0.55)
                end
                task.wait(0.035 + rand() * 0.03)
            end
            for i = 1, 10 do
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
    -- 6) BORDE DE ENERGÍA VIVA (colores que se funden, respira y se dispara)
    ---------------------------------------------------------------------
    local stroke = Root:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke")
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Color = WHITE
    stroke.Transparency = 0
    stroke.Parent = Root

    local strokeGradient = stroke:FindFirstChildOfClass("UIGradient") or Instance.new("UIGradient")
    strokeGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Theme.Crimson),
        ColorSequenceKeypoint.new(0.22, Theme.GlowColor),
        ColorSequenceKeypoint.new(0.45, Theme.Yellow),
        ColorSequenceKeypoint.new(0.52, Color3.fromRGB(255, 245, 210)),
        ColorSequenceKeypoint.new(0.6, Theme.Yellow),
        ColorSequenceKeypoint.new(0.78, Theme.GlowColor),
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
        ColorSequenceKeypoint.new(0, Theme.Yellow),
        ColorSequenceKeypoint.new(0.33, Theme.Crimson),
        ColorSequenceKeypoint.new(0.66, Theme.GlowColor),
        ColorSequenceKeypoint.new(1, Theme.Yellow),
    })
    haloGradient.Parent = haloStroke

    -- Orbes de energía en las esquinas
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
    -- 7) TÍTULO, NOMBRE Y TEXTOS
    ---------------------------------------------------------------------
    local TITLE_RICH = 'All For One <font color="rgb(220,20,60)">(2.0)</font>'
    local TITLE_PLAIN = "All For One (2.0)"
    local titleLabel, ghostA, ghostB, titleGradient, titleStroke
    local ghostBase = UDim2.new()
    local titleFX = newFrame(Root, 60)
    titleFX.Name = "AFO_TitleFX"

    local function isTitleText(txt)
        local l = txt:lower()
        return l:find("all for one", 1, true) or l:find("todo para uno", 1, true)
    end

    local function setupTitle(label)
        label:SetAttribute("AFO", true)
        label.RichText = true
        label.Font = Enum.Font.GothamBlack
        label.TextSize = 20
        label.TextColor3 = WHITE
        label.TextWrapped = false
        label.TextTruncate = Enum.TextTruncate.None
        label.AutomaticSize = Enum.AutomaticSize.X
        label.Text = TITLE_RICH

        local function ghost(color)
            local g = label:Clone()
            for _, c in ipairs(g:GetChildren()) do
                if c:IsA("UIGradient") or c:IsA("UIStroke") then c:Destroy() end
            end
            g:SetAttribute("AFO", true)
            g.RichText = false
            g.Text = TITLE_PLAIN
            g.TextColor3 = color
            g.TextTransparency = 1
            g.ZIndex = label.ZIndex - 1
            g.Parent = label.Parent
            return g
        end
        ghostA = ghost(Theme.Crimson)
        ghostB = ghost(Theme.GlowColor)
        ghostBase = label.Position

        titleGradient = Instance.new("UIGradient")
        titleGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(215, 195, 245)),
            ColorSequenceKeypoint.new(0.5, WHITE),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(215, 195, 245)),
        })
        titleGradient.Parent = label

        titleStroke = Instance.new("UIStroke")
        titleStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
        titleStroke.Color = Theme.GlowColor
        titleStroke.Thickness = 1
        titleStroke.Transparency = 0.55
        titleStroke.Parent = label

        label:GetPropertyChangedSignal("Text"):Connect(function()
            if label.Text ~= TITLE_RICH then label.Text = TITLE_RICH end
        end)
        titleLabel = label
    end

    local function prefixName(l)
        if l:GetAttribute("AFO_Name") then return end
        l:SetAttribute("AFO_Name", true)
        l.Text = "@" .. lp.Name
        l:GetPropertyChangedSignal("Text"):Connect(function()
            if l.Text == lp.Name then l.Text = "@" .. lp.Name end
        end)
    end

    local function applyTexts()
        if not alive or not Root.Parent then return end
        local rootY = Root.AbsolutePosition.Y
        local candidates, nameLabels = {}, {}

        for _, obj in ipairs(Root:GetDescendants()) do
            if obj:IsA("Frame") and obj.Size == UDim2.new(0, 6, 0, 6) then
                obj.BackgroundColor3 = Theme.Crimson
            end
            if obj:IsA("TextLabel") and not obj:GetAttribute("AFO") then
                local txt = obj.Text
                local inTitleBar = obj.AbsolutePosition.Y - rootY < 52
                if inTitleBar and isTitleText(txt) then
                    candidates[#candidates + 1] = obj
                elseif inTitleBar then
                    local c = obj.TextColor3
                    if c.G > c.R + 0.15 and c.G > c.B + 0.15 then obj.TextColor3 = Theme.Crimson end
                end
                if txt == "Anonymous" and not obj:GetAttribute("AFO_Villain") then
                    obj:SetAttribute("AFO_Villain", true)
                    obj.Text = "Villain"
                    obj.TextSize = 14
                    obj.Font = Enum.Font.GothamBold
                    obj:GetPropertyChangedSignal("Text"):Connect(function()
                        if obj.Text == "Anonymous" then obj.Text = "Villain" end
                    end)
                end
                if txt == lp.Name then nameLabels[#nameLabels + 1] = obj end
            end
        end

        if #candidates > 0 then
            local main = titleLabel
            if not main then
                main = candidates[1]
                for _, c in ipairs(candidates) do
                    if c.Text:lower():find("all for one", 1, true) then main = c break end
                end
                setupTitle(main)
            end
            for _, c in ipairs(candidates) do
                if c ~= main then
                    c.Visible = false
                    c:SetAttribute("AFO", true)
                end
            end
        end

        if #nameLabels > 0 then
            local list = nameLabels
            if lp.DisplayName == lp.Name then
                local target = nameLabels[1]
                for _, l in ipairs(nameLabels) do
                    if l.AbsolutePosition.Y > target.AbsolutePosition.Y then target = l end
                end
                list = { target }
            end
            for _, l in ipairs(list) do prefixName(l) end
        end
    end

    task.spawn(function()
        task.wait(0.5)
        applyTexts()
        task.wait(1.5)
        applyTexts()
    end)
    local pending = false
    Root.DescendantAdded:Connect(function()
        if pending then return end
        pending = true
        task.delay(0.3, function()
            pending = false
            applyTexts()
        end)
    end)

    ---------------------------------------------------------------------
    -- 8) BUCLE PRINCIPAL
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

        -- Luz ambiental exterior
        ambientGradient.Rotation = (t * 30) % 360
        ambientLight.ImageTransparency = math.clamp(0.42 + math.sin(t * 2) * 0.12 - sg * 0.3, 0, 1)
        ambientLight.ImageColor3 = WHITE:Lerp(S.flashColor, sg * 0.7)
        local grow = 70 + sg * 45
        ambientLight.Size = UDim2.new(1, grow * 2, 1, grow * 2)
        ambientLight.Position = UDim2.new(0, -grow, 0, -grow)

        -- Flash y bruma
        flash.BackgroundColor3 = S.flashColor
        flash.BackgroundTransparency = 1 - sg * 0.16
        mist.BackgroundColor3 = Color3.fromRGB(90, 20, 140):Lerp(S.flashColor, sg * 0.5)
        mist.BackgroundTransparency = 0.08 + math.sin(t * 0.6) * 0.06 - sg * 0.08

        -- Niebla
        for _, f in ipairs(fog) do
            f.lit = f.lit * math.exp(-dt * 3.2)
            f.obj.Position = UDim2.fromScale(
                f.ax + math.sin(t * f.sp + f.ph) * f.amp,
                f.ay + math.cos(t * f.sp * 0.8 + f.ph) * f.amp * 0.7
            )
            f.obj.Rotation = (t * f.rs) % 360
            f.obj.ImageTransparency = math.clamp(f.bt + math.sin(t * 0.4 + f.ph) * 0.03 - f.lit * 0.5, 0.2, 1)
            f.obj.ImageColor3 = f.base:Lerp(S.flashColor, math.clamp(f.lit, 0, 1) * 0.85)
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

        -- Borde vivo
        local noise = math.noise(t * 1.3, 0, 0)
        stroke.Thickness = 2.2 + math.abs(noise) * 2 + math.sin(t * 2.5) * 0.6 + sg * 5
        strokeGradient.Rotation = (t * (45 + sg * 400)) % 360
        haloStroke.Thickness = 5 + math.abs(math.noise(t * 0.9, 3, 0)) * 5 + sg * 14
        haloStroke.Transparency = math.clamp(0.68 - sg * 0.45 + math.sin(t * 1.7) * 0.06, 0, 1)
        haloGradient.Rotation = (-t * (30 + sg * 250)) % 360
        for _, o in ipairs(orbs) do
            local s = 6 + math.sin(t * 3 + o.ph) * 1.5 + sg * 9
            o.o.Size = UDim2.fromOffset(s, s)
        end

        -- Título
        if titleLabel and titleLabel.Parent then
            titleGradient.Offset = Vector2.new(((t * 0.35) % 2) - 1, 0)
            titleStroke.Thickness = 1 + sg * 1.5
            titleStroke.Color = Theme.GlowColor:Lerp(S.flashColor, sg)

            if S.tglitch <= 0 and rand() < 0.004 then S.tglitch = 0.12 end
            local gl = S.tglitch > 0
            local off = gl and (1 + sg * 3) or 0
            ghostA.Position = ghostBase + UDim2.fromOffset(-off - 1, 0)
            ghostB.Position = ghostBase + UDim2.fromOffset(off + 1, 0)
            ghostA.TextTransparency = gl and (0.35 + rand() * 0.4) or 1
            ghostB.TextTransparency = gl and (0.35 + rand() * 0.4) or 1

            -- Emisor de chispas sobre el título
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
