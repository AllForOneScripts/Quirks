-- ──────────────────────────────────────────────────────────────────
-- [1]  SERVICIOS Y UTILIDADES GENÉRICAS
-- ──────────────────────────────────────────────────────────────────
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TextService      = game:GetService("TextService")

local function isnan(v)
    return v ~= v
end

local function safepos(v3)
    if not v3 then return false end
    return not (isnan(v3.X) or isnan(v3.Y) or isnan(v3.Z))
end

local function isTyping()
    return UserInputService:GetFocusedTextBox() ~= nil
end

-- ──────────────────────────────────────────────────────────────────
-- [2]  IDIOMA / LOCALIZACIÓN
-- ──────────────────────────────────────────────────────────────────
local LockLang = {
    ES = {
        lock_label       = "LOCK",
        lock_hint_prefix = "Apuntar + ",
        height_below     = "studs abajo",
        height_above     = "studs arriba",
        height_same      = "mismo nivel",
        studs            = "studs",
    },
    EN = {
        lock_label       = "LOCK",
        lock_hint_prefix = "Aim + ",
        height_below     = "studs below",
        height_above     = "studs above",
        height_same      = "same level",
        studs            = "studs",
    },
}

local FT = LockLang["ES"]

local function _reloadFT()
    local lang = "ES"
    pcall(function()
        if type(readfile) == "function" then
            local data = readfile("AllForOne/lang.txt")
            if data == "EN" or data == "ES" then lang = data end
        end
    end)
    FT = LockLang[lang]
end

_reloadFT()

-- ──────────────────────────────────────────────────────────────────
-- [3]  ESTADO INTERNO (L)
-- ──────────────────────────────────────────────────────────────────
local LOCK_ICON_ID = "rbxassetid://82817965256191"

local L = {
    lockKey        = Enum.KeyCode.X,
    systemEnabled  = false,
    lockActive     = false,
    lockedTarget   = nil,
    avatarRequestId = 0,

    lockIconGui    = nil,
    lockInfoGui    = nil,
    ownScreenGui   = nil,
    infoGuiParent  = nil,
    lockHighlight  = nil,
    lockLabels     = nil,

    lockConn       = nil,

    -- Puntería
    aimPart         = nil,   -- nil = automático (UpperTorso > Torso > HumanoidRootPart). Ej: "Head"
    aimOffset       = Vector3.zero,
    aimAtCursor     = true,  -- true: el objetivo queda bajo el cursor; false: centro de pantalla
    trackStiffness  = 40,    -- más alto = sigue más pegado (independiente de los FPS)
    snapAngle       = math.rad(1.5), -- por debajo de este error se corrige al 100 %
    trackBoost      = 60,    -- extra de rapidez según el error: giros rápidos = sin "deslizamiento"
    maxPitch        = math.rad(70),  -- límite vertical de la corrección (Roblox permite ±80°)
    nearMinHz       = 1.5,   -- objetivo a menos de esto (horizontal) del pivote: la cámara NO se toca
    nearFullHz      = 4,     -- a partir de esta distancia la corrección es 100 %; entre ambos se desvanece
    pitchMinHz      = 4,     -- distancia horizontal mínima "virtual" para calcular el pitch
    projectileSpeed = 0,     -- studs/s de tu esfera; 0 = sin predicción de movimiento
    aimPoint        = nil,   -- último punto de puntería calculado (Vector3)

    renderName     = "AFO_LockCamera",
}

local lplr   = nil
local camera = nil

local function refreshCamera()
    camera = workspace.CurrentCamera or camera
    return camera
end

-- ──────────────────────────────────────────────────────────────────
-- [3b] PIVOTE Y PUNTO DE PUNTERÍA
-- ──────────────────────────────────────────────────────────────────
-- Un único lugar decide A DÓNDE se apunta, así cámara, icono y selección
-- usan siempre el mismo pivote (antes: UpperTorso o HRP según el módulo,
-- y R6 caía siempre al HRP).
local AIM_FALLBACKS = { "UpperTorso", "Torso", "HumanoidRootPart" }

local function getAimPart(char)
    if not char then return nil end
    if L.aimPart then
        local custom = char:FindFirstChild(L.aimPart)
        if custom and custom:IsA("BasePart") then return custom end
    end
    for _, name in ipairs(AIM_FALLBACKS) do
        local part = char:FindFirstChild(name)
        if part and part:IsA("BasePart") then return part end
    end
    local hum = char:FindFirstChildOfClass("Humanoid")
    return hum and hum.RootPart or nil
end

-- Punto 3D al que hay que apuntar. Si projectileSpeed > 0 se adelanta
-- la posición según la velocidad del objetivo (tiempo de vuelo de la esfera).
local function getAimPoint(char, originPos)
    local part = getAimPart(char)
    if not part then return nil end
    local point = part.Position + L.aimOffset
    if not safepos(point) then return nil end

    local speed = L.projectileSpeed
    if speed and speed > 0 and originPos then
        local root = char:FindFirstChild("HumanoidRootPart") or part
        local hum  = char:FindFirstChildOfClass("Humanoid")
        local vel  = root.AssemblyLinearVelocity
        if safepos(vel) and vel.Magnitude < 200 then
            -- en suelo ignoramos la velocidad vertical (rampas / saltitos)
            if not (hum and hum:GetState() == Enum.HumanoidStateType.Freefall) then
                vel = Vector3.new(vel.X, 0, vel.Z)
            end
            local t = (point - originPos).Magnitude / speed
            for _ = 1, 2 do
                t = ((point + vel * t) - originPos).Magnitude / speed
            end
            point = point + vel * t
        end
    end
    return point
end

-- ──────────────────────────────────────────────────────────────────
-- [4]  TARGETING
-- ──────────────────────────────────────────────────────────────────
local function isTargetValidForLock(target)
    if not target then return false end
    local char = target.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return false end
    if hum.Health <= 0 then return false end
    if hum:GetState() == Enum.HumanoidStateType.Dead then return false end
    return true
end

local function getClosestLockTarget()
    local closestPlayer = nil
    local bestScore     = math.huge
    local myChar = lplr and lplr.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not refreshCamera() then return nil end
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player == lplr then continue end
        if not isTargetValidForLock(player) then continue end
        local targetChar = player.Character
        if not targetChar then continue end
        local targetRoot = getAimPart(targetChar)
        if not targetRoot then continue end
        
        -- WorldToViewportPoint usa el mismo sistema de coordenadas que GetMouseLocation
        local ok3, screenPos, onScreen = pcall(function()
            return camera:WorldToViewportPoint(targetRoot.Position)
        end)
        
        if not ok3 or not onScreen then continue end
        local mousePos   = UserInputService:GetMouseLocation()
        local screenDist = (mousePos - Vector2.new(screenPos.X, screenPos.Y)).Magnitude
        
        if isnan(screenDist) or screenDist > 300 then continue end
        local worldDist  = myRoot and (myRoot.Position - targetRoot.Position).Magnitude or 0
        if isnan(worldDist) then continue end
        
        local score = screenDist + (worldDist * 0.2)
        if score < bestScore then 
            bestScore = score
            closestPlayer = player 
        end
    end
    return closestPlayer
end

-- ──────────────────────────────────────────────────────────────────
-- [4b] AUTOCOMPLETADO DE JUGADORES (apodo / nombre)
-- ──────────────────────────────────────────────────────────────────
-- Detección con comillas:
--   "Cool    →  APODO (DisplayName). La comilla de cierre es opcional: "Cool"
--   Cool     →  NOMBRE de usuario (Name)
local MAX_SUGGESTIONS = 12

local function trimText(text)
    return (tostring(text or ""):match("^%s*(.-)%s*$")) or ""
end

-- Devuelve (consulta, modoApodo)
local function parseQuery(text)
    text = trimText(text)
    text = (text:gsub("\u{201C}", '"'):gsub("\u{201D}", '"'))
    local inside = text:match('^"(.-)"?$')
    if inside then
        return trimText(inside), true
    end
    return text, false
end

local function displayNameOf(player)
    local dn = player.DisplayName
    if not dn or dn == "" then dn = player.Name end
    return dn
end

-- Jugadores del servidor (sin contarte a ti) que encajan, mejor coincidencia primero
local function searchPlayers(query, nickMode)
    local q = (query or ""):lower()
    if q == "" then return {} end
    local found = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player == lplr then continue end
        local field = (nickMode and displayNameOf(player) or player.Name):lower()
        local score = 0
        if field == q then
            score = 3
        elseif field:sub(1, #q) == q then
            score = 2
        elseif field:find(q, 1, true) then
            score = 1
        end
        if score > 0 then
            table.insert(found, { player = player, score = score, key = field })
        end
    end
    table.sort(found, function(a, b)
        if a.score ~= b.score then return a.score > b.score end
        return a.key < b.key
    end)
    local results = {}
    for i = 1, math.min(#found, MAX_SUGGESTIONS) do
        results[i] = found[i].player
    end
    return results
end

-- Devuelve (jugador, textoCompletado, modoApodo). Si no hay coincidencia: (nil, textoOriginal, modoApodo)
local function autocompletePlayer(text)
    local query, nickMode = parseQuery(text)
    local player = searchPlayers(query, nickMode)[1]
    if not player then
        return nil, text, nickMode
    end
    local completed = nickMode and ('"' .. displayNameOf(player) .. '"') or player.Name
    return player, completed, nickMode
end

-- ──────────────────────────────────────────────────────────────────
-- [5]  ICONO DE LOCK + HIGHLIGHT
-- ──────────────────────────────────────────────────────────────────
local function removeLockIcon()
    if L.lockIconGui then
        pcall(function() L.lockIconGui:Destroy() end)
        L.lockIconGui = nil
    end
end

local function applyLockIcon(player)
    if not L.systemEnabled or not L.lockActive or player ~= L.lockedTarget then return end
    removeLockIcon()
    local torso = getAimPart(player.Character)
    if not torso then return end
    L.lockIconGui = Instance.new("BillboardGui", torso)
    L.lockIconGui.Name        = "LockIcon"
    L.lockIconGui.Size        = UDim2.new(0, 50, 0, 50)
    L.lockIconGui.AlwaysOnTop = true
    L.lockIconGui.StudsOffset = Vector3.new(0, 0, 0)
    local img = Instance.new("ImageLabel", L.lockIconGui)
    img.Size                 = UDim2.new(1, 0, 1, 0)
    img.BackgroundTransparency = 1
    img.Image                = LOCK_ICON_ID
    img.ImageColor3          = Color3.fromRGB(255, 255, 255)
    img.ScaleType            = Enum.ScaleType.Fit
end

local function ensureLockHighlight()
    if not L.lockHighlight then
        L.lockHighlight = Instance.new("Highlight")
        L.lockHighlight.FillTransparency    = 1
        L.lockHighlight.OutlineColor        = Color3.fromRGB(255, 255, 255)
        L.lockHighlight.OutlineTransparency = 0
    end
end

local function updateLockHighlight()
    if not L.systemEnabled or not L.lockActive or not L.lockedTarget then
        if L.lockHighlight then L.lockHighlight.Parent = nil end
        return
    end
    if not isTargetValidForLock(L.lockedTarget) then
        if L.lockHighlight then L.lockHighlight.Parent = nil end
        return
    end
    ensureLockHighlight()
    local targetChar = L.lockedTarget.Character
    if targetChar then L.lockHighlight.Parent = targetChar
    else L.lockHighlight.Parent = nil end
end

-- ──────────────────────────────────────────────────────────────────
-- [6]  GUI INFO PANEL
-- ──────────────────────────────────────────────────────────────────
local function loadAvatarImage()
    if not L.systemEnabled or not L.lockActive or not L.lockedTarget or not L.lockInfoGui then return end
    local playerImg = L.lockInfoGui:FindFirstChild("PlayerImage", true)
    if not playerImg then return end
    -- Evita lanzar una peticion web en cada frame: una por panel, con reintento cada 3 s si falla
    if L.avatarLoadedGui == L.lockInfoGui then return end
    if os.clock() < (L.avatarRetryAt or 0) then return end
    L.avatarLoadedGui = L.lockInfoGui
    local target = L.lockedTarget
    local infoGui = L.lockInfoGui
    local requestId = L.avatarRequestId
    local userId = target.UserId

    task.spawn(function()
        local success, content = pcall(function()
            return Players:GetUserThumbnailAsync(
                userId,
                Enum.ThumbnailType.AvatarBust,
                Enum.ThumbnailSize.Size420x420
            )
        end)

        if success and content
            and L.systemEnabled
            and L.lockActive
            and L.lockedTarget == target
            and L.lockInfoGui == infoGui
            and L.avatarRequestId == requestId
            and playerImg.Parent then
            playerImg.Image = content
        elseif L.avatarLoadedGui == infoGui then
            L.avatarLoadedGui = nil
            L.avatarRetryAt = os.clock() + 3
        end
    end)
end

-- Reduce el tamaño de letra hasta que el texto quepa en el ancho de la etiqueta.
-- Roblox permite nombres de hasta 20 caracteres; en el peor caso (ej. "WWWW...")
-- el texto se escala hacia abajo hasta minSize. Solo recalcula si el texto cambió.
local function fitText(lbl, maxSize, minSize)
    local text = lbl.Text
    if lbl:GetAttribute("FitText") == text then return end
    lbl:SetAttribute("FitText", text)

    local availW = lbl.AbsoluteSize.X
    if availW <= 0 then availW = 132 end -- ancho por defecto del panel (250 - 118)

    local size = maxSize
    while size > minSize do
        local okB, bounds = pcall(function()
            return TextService:GetTextSize(text, size, lbl.Font, Vector2.new(10000, 100))
        end)
        if not okB or bounds.X <= availW then break end
        size = size - 1
    end
    lbl.TextSize = size
end

local function createLockInfoGui(parentFrame)
    if not L.systemEnabled or not L.lockActive or not L.lockedTarget then return end

    if L.lockInfoGui then
        pcall(function() L.lockInfoGui:Destroy() end)
        L.lockInfoGui = nil
    end

    local parent = parentFrame
    if not parent then
        if L.ownScreenGui then
            pcall(function() L.ownScreenGui:Destroy() end)
            L.ownScreenGui = nil
        end
        local screenGui = Instance.new("ScreenGui")
        screenGui.Name           = "AFO_LockGui"
        screenGui.ResetOnSpawn   = false
        screenGui.IgnoreGuiInset = true
        screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        local container
        if type(gethui) == "function" then
            local okH, h = pcall(gethui)
            if okH and h then container = h end
        end
        if not container then
            local okP, pg = pcall(function() return lplr.PlayerGui end)
            container = (okP and pg) or game:GetService("CoreGui")
        end
        screenGui.Parent = container
        L.ownScreenGui   = screenGui
        parent           = screenGui
    end

    local C_PURPLE = Color3.fromRGB(110, 30, 180)
    local C_BLACK  = Color3.fromRGB(6, 4, 12)
    local C_TEXT   = Color3.fromRGB(220, 190, 255)

    local infoFrame = Instance.new("Frame")
    infoFrame.Name                  = "LockInfoPanel"
    infoFrame.Size                  = UDim2.new(0, 250, 0, 122)
    infoFrame.Position              = UDim2.new(1, -262, 0, 44)
    infoFrame.AnchorPoint           = Vector2.new(0, 0)
    infoFrame.BackgroundColor3      = C_BLACK
    infoFrame.BackgroundTransparency = 0.15
    infoFrame.BorderSizePixel       = 0
    infoFrame.ZIndex                = 10
    infoFrame.Visible               = true
    infoFrame.Parent                = parent
    Instance.new("UICorner", infoFrame).CornerRadius = UDim.new(0, 8)

    local stroke = Instance.new("UIStroke", infoFrame)
    stroke.Color       = C_PURPLE
    stroke.Thickness   = 1
    stroke.Transparency = 0.5

    local iconLbl = Instance.new("TextLabel", infoFrame)
    iconLbl.Size                 = UDim2.new(0, 28, 0, 28)
    iconLbl.Position             = UDim2.new(0, 6, 0.5, -14)
    iconLbl.BackgroundTransparency = 1
    iconLbl.Font                 = Enum.Font.Legacy
    iconLbl.TextSize             = 20
    iconLbl.TextColor3           = Color3.fromRGB(255, 220, 80)
    iconLbl.Text                 = "🎯"

    -- Crea una etiqueta de texto alineada a la izquierda del bloque central
    local function makeLabel(name, y, h, font, size, color, text)
        local lbl = Instance.new("TextLabel", infoFrame)
        lbl.Name                   = name
        lbl.Size                   = UDim2.new(1, -118, 0, h)
        lbl.Position               = UDim2.new(0, 40, 0, y)
        lbl.BackgroundTransparency = 1
        lbl.Font                   = font
        lbl.TextSize               = size
        lbl.TextColor3             = color
        lbl.Text                   = text
        lbl.TextXAlignment         = Enum.TextXAlignment.Left
        lbl.TextTruncate           = Enum.TextTruncate.AtEnd
        return lbl
    end

    -- 1) Nombre de visualización
    makeLabel("NameLabel", 8, 18, Enum.Font.GothamBold, 13, C_TEXT, "---")
    -- 2) @Nombre real
    makeLabel("UserLabel", 26, 14, Enum.Font.Gotham, 10, Color3.fromRGB(170, 150, 210), "@---")
    -- 3) Distancia en studs
    makeLabel("DistLabel", 44, 15, Enum.Font.Gotham, 11, Color3.fromRGB(200, 170, 255), "--- " .. FT.studs)
    -- 4) Studs arriba / abajo
    makeLabel("HeightLabel", 60, 15, Enum.Font.Gotham, 10, Color3.fromRGB(150, 220, 255), "---")
    -- 5) Vida
    makeLabel("HealthLabel", 77, 18, Enum.Font.Legacy, 12, Color3.fromRGB(255, 150, 150), "❤️ ---")

    -- Barra de vida
    local barBg = Instance.new("Frame", infoFrame)
    barBg.Name                   = "HealthBarBg"
    barBg.Size                   = UDim2.new(1, -24, 0, 6)
    barBg.Position               = UDim2.new(0, 12, 1, -14)
    barBg.BackgroundColor3       = Color3.fromRGB(30, 18, 50)
    barBg.BorderSizePixel        = 0
    barBg.ZIndex                 = 11
    Instance.new("UICorner", barBg).CornerRadius = UDim.new(1, 0)

    local barFill = Instance.new("Frame", barBg)
    barFill.Name                 = "HealthBarFill"
    barFill.Size                 = UDim2.new(1, 0, 1, 0)
    barFill.BackgroundColor3     = Color3.fromRGB(80, 255, 80)
    barFill.BorderSizePixel      = 0
    barFill.ZIndex               = 12
    Instance.new("UICorner", barFill).CornerRadius = UDim.new(1, 0)

    local playerImgContainer = Instance.new("Frame", infoFrame)
    playerImgContainer.Name               = "PlayerImgContainer"
    playerImgContainer.Size               = UDim2.new(0, 64, 0, 64)
    playerImgContainer.Position           = UDim2.new(1, -74, 0, 12)
    playerImgContainer.BackgroundColor3   = Color3.fromRGB(20, 10, 40)
    playerImgContainer.BackgroundTransparency = 0.3
    playerImgContainer.BorderSizePixel    = 0
    playerImgContainer.ZIndex             = 11
    Instance.new("UICorner", playerImgContainer).CornerRadius = UDim.new(1, 0)

    local playerImg = Instance.new("ImageLabel", playerImgContainer)
    playerImg.Name                 = "PlayerImage"
    playerImg.Size                 = UDim2.new(1, 0, 1, 0)
    playerImg.Position             = UDim2.new(0, 0, 0, 0)
    playerImg.BackgroundTransparency = 1
    playerImg.Image                = ""
    playerImg.ZIndex               = 12
    Instance.new("UICorner", playerImg).CornerRadius = UDim.new(1, 0)

    L.lockInfoGui = infoFrame
end

local function destroyLockInfoGui()
    if L.lockInfoGui then
        pcall(function() L.lockInfoGui:Destroy() end)
        L.lockInfoGui = nil
    end
    if L.ownScreenGui then
        pcall(function() L.ownScreenGui:Destroy() end)
        L.ownScreenGui = nil
    end
end

local function clearLock()
    L.avatarRequestId = L.avatarRequestId + 1
    L.lockActive   = false
    L.lockedTarget = nil
    removeLockIcon()
    updateLockHighlight()
    destroyLockInfoGui()
end

local function updateLockInfoGui()
    if not L.lockInfoGui then return end
    if not L.lockActive
    or not L.lockedTarget
    or not L.lockedTarget.Character
    or not isTargetValidForLock(L.lockedTarget) then
        clearLock()
        return
    end

    local target   = L.lockedTarget
    local root     = target.Character:FindFirstChild("HumanoidRootPart")
    local humanoid = target.Character:FindFirstChildOfClass("Humanoid")
    local myChar   = lplr and lplr.Character
    local myRoot   = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local gui = L.lockInfoGui

    -- 1) Nombre de visualización
    local nameLabel = gui:FindFirstChild("NameLabel")
    if nameLabel then
        local dn = target.DisplayName
        if not dn or dn == "" then dn = target.Name end
        nameLabel.Text = dn
        fitText(nameLabel, 13, 7)
    end

    -- 2) @Nombre real
    local userLabel = gui:FindFirstChild("UserLabel")
    if userLabel then
        userLabel.Text = "@" .. target.Name
        fitText(userLabel, 10, 7)
    end

    -- 3) Distancia en studs (desde tu personaje; si no existe, desde la cámara)
    local dist = 0
    if myRoot and safepos(myRoot.Position) and safepos(root.Position) then
        dist = (myRoot.Position - root.Position).Magnitude
    elseif refreshCamera() then
        dist = (camera.CFrame.Position - root.Position).Magnitude
    end
    if isnan(dist) then dist = 0 end
    local distLabel = gui:FindFirstChild("DistLabel")
    if distLabel then distLabel.Text = math.floor(dist + 0.5) .. " " .. FT.studs end

    -- 4) Studs arriba / abajo (respecto a ti)
    local heightLabel = gui:FindFirstChild("HeightLabel")
    if heightLabel and myRoot and safepos(myRoot.Position) and safepos(root.Position) then
        local diff = math.floor(myRoot.Position.Y - root.Position.Y + 0.5)
        if isnan(diff) then diff = 0 end
        if diff > 0 then
            -- el objetivo está por debajo de ti
            heightLabel.Text       = "▼ " .. diff .. " " .. FT.height_below
            heightLabel.TextColor3 = Color3.fromRGB(150, 220, 255)
        elseif diff < 0 then
            -- el objetivo está por encima de ti
            heightLabel.Text       = "▲ " .. math.abs(diff) .. " " .. FT.height_above
            heightLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
        else
            heightLabel.Text       = "● " .. FT.height_same
            heightLabel.TextColor3 = Color3.fromRGB(150, 255, 150)
        end
    end

    -- 5) Vida
    local healthLabel = gui:FindFirstChild("HealthLabel")
    if healthLabel and humanoid then
        local rawHealth = math.max(humanoid.Health, 0)
        local maxHealth = math.max(humanoid.MaxHealth, 1)
        local healthStr
        if math.floor(rawHealth) == 0 and rawHealth > 0 then
            healthStr = string.format("%.2f", math.floor(rawHealth * 100 + 0.5) / 100)
        else
            healthStr = tostring(math.floor(rawHealth + 0.5))
        end

        local pct = math.clamp(rawHealth / maxHealth, 0, 1)
        local heartEmoji, color
        if rawHealth <= 0 then
            heartEmoji, color = "☠️", Color3.fromRGB(120, 120, 120)
        elseif pct > 0.75 then
            heartEmoji, color = "💚", Color3.fromRGB(80, 255, 80)
        elseif pct > 0.50 then
            heartEmoji, color = "💛", Color3.fromRGB(255, 220, 80)
        elseif pct > 0.25 then
            heartEmoji, color = "🧡", Color3.fromRGB(255, 160, 60)
        else
            heartEmoji, color = "❤️", Color3.fromRGB(255, 80, 80)
        end
        healthLabel.Font       = Enum.Font.Legacy
        healthLabel.Text       = heartEmoji .. " " .. healthStr .. "/" .. tostring(math.floor(maxHealth + 0.5))
        healthLabel.TextColor3 = color

        local barBg   = gui:FindFirstChild("HealthBarBg")
        local barFill = barBg and barBg:FindFirstChild("HealthBarFill")
        if barFill then
            barFill.Size             = UDim2.new(pct, 0, 1, 0)
            barFill.BackgroundColor3 = color
        end
    end

    loadAvatarImage()
end

-- ──────────────────────────────────────────────────────────────────
-- [7]  CÁMARA DE LOCK
-- ──────────────────────────────────────────────────────────────────
-- CÓMO FUNCIONA (sin bucles de realimentación):
--   La cámara en 3ª persona orbita alrededor de un pivote (Camera.Focus ≈ tu
--   cabeza). Para que el objetivo quede bajo el cursor basta con que la cámara
--   mire en la dirección pivote→objetivo; el zoom no influye.
--   ANTES se medía el error contra el rayo actual y se giraba alrededor del
--   pivote con un eje cualquiera. Con el objetivo muy cerca cada giro movía tanto
--   la cámara que el error crecía en vez de bajar: la cámara salía disparada hacia
--   arriba y giraba en círculos. Además un eje arbitrario acumula ROLL
--   (inclinación) en giros rápidos, que es lo que se sentía como "deslizarse".
--   AHORA:
--     · yaw/pitch deseados se calculan directamente (no dependen del frame anterior)
--     · la cámara se reconstruye con yaw+pitch y roll = 0 (siempre recta)
--     · si el objetivo está pegado a ti la corrección se desvanece, y el pitch
--       nunca se calcula con un ángulo vertical imposible
--     · el seguimiento acelera con el error: en giros rápidos no se queda atrás
local function wrapAngle(a)
    return (a + math.pi) % (2 * math.pi) - math.pi
end

-- yaw / pitch de un vector (yaw 0 = mirando a -Z, igual que la cámara de Roblox).
-- minHz > 0 evita que el pitch se dispare a ±90° cuando el objetivo está casi
-- encima/debajo (distancia horizontal ~0).
local function dirToAngles(v, minHz)
    local hz = math.sqrt(v.X * v.X + v.Z * v.Z)
    return math.atan2(-v.X, -v.Z), math.atan2(v.Y, math.max(hz, minHz or 0))
end

-- 0 = objetivo pegado a tu pivote (no se toca la cámara), 1 = distancia normal.
local function nearGain(hz, minHz, fullHz)
    local t = math.clamp((hz - minHz) / math.max(fullHz - minHz, 1e-3), 0, 1)
    return t * t * (3 - 2 * t)
end

-- Calcula el yaw/pitch (SIN roll) que debe tener la cámara para que el objetivo
-- quede bajo `screenPoint`. Solución cerrada, sin iterar sobre el frame anterior:
--   · pivote→objetivo expresado en el espacio de la cámara:  u = offset + k·rayo
--   · se busca la rotación yaw+pitch que lleva `u` a la dirección real pivote→objetivo
-- Devuelve goalYaw, goalPitch, curYaw, curPitch, offsetLocal  (o nil si no es calculable)
local function solveAim(cam, pivot, aimPoint, screenPoint, pitchMinHz, maxPitch)
    local cf     = cam.CFrame
    local toAim  = aimPoint - pivot
    local D      = toAim.Magnitude
    if D < 0.5 then return nil end

    local curYaw, curPitch = dirToAngles(cf.LookVector)
    local localOff = cf:VectorToObjectSpace(cf.Position - pivot)
    local lv = cf:VectorToObjectSpace(cam:ViewportPointToRay(screenPoint.X, screenPoint.Y).Direction)

    local b    = lv:Dot(localOff)
    local disc = b * b - localOff:Dot(localOff) + D * D
    local u    = localOff + lv * (-b + math.sqrt(math.max(disc, 0)))
    if u.Magnitude < 1e-3 then return nil end
    u = u.Unit

    local wYaw, wPitch = dirToAngles(toAim, pitchMinHz)

    -- Pitch: (cos p)·u.Y - (sin p)·u.Z = sin(wPitch)
    local A, B = u.Y, -u.Z
    local m = math.sqrt(A * A + B * B)
    local pitch = curPitch
    if m > 1e-6 then
        local base = math.atan2(B, A)
        local off  = math.acos(math.clamp(math.sin(wPitch) / m, -1, 1))
        local p1, p2 = wrapAngle(base + off), wrapAngle(base - off)
        -- de las dos soluciones, la más cercana al pitch actual (evita saltos)
        pitch = (math.abs(wrapAngle(p1 - curPitch)) <= math.abs(wrapAngle(p2 - curPitch))) and p1 or p2
    end
    -- Nunca se manda la cámara más arriba/abajo del límite (evita volteos)
    local lim = math.max(maxPitch, math.abs(curPitch))
    pitch = math.clamp(pitch, -lim, lim)

    -- Yaw con el pitch ya definido
    local alpha = math.atan2(-u.X, -(math.sin(pitch) * u.Y + math.cos(pitch) * u.Z))
    local yaw   = wrapAngle(wYaw - alpha)

    return yaw, pitch, curYaw, curPitch, localOff
end

-- Pivote de órbita: Focus (≈ tu cabeza) si es fiable; en 1ª persona o con la
-- cámara Scriptable se gira la cámara sobre sí misma.
local function getOrbitPivot(cam, isBadFn)
    local camPos = cam.CFrame.Position
    local pivot  = camPos
    if cam.CameraType ~= Enum.CameraType.Scriptable then
        local focusPos = cam.Focus.Position
        if not isBadFn(focusPos) and (focusPos - camPos).Magnitude < 100 then
            pivot = focusPos
        end
    end
    if (camPos - pivot).Magnitude < 1.5 then pivot = camPos end
    return pivot
end

-- Reconstruye la cámara con yaw+pitch y roll = 0 (horizonte siempre recto),
-- conservando zoom y desplazamiento de hombro (offset local).
local function applyCameraAngles(cam, pivot, yaw, pitch, localOff)
    if yaw ~= yaw or pitch ~= pitch then return end
    local rot = CFrame.fromEulerAnglesYXZ(pitch, yaw, 0)
    cam.CFrame = CFrame.new(pivot + rot:VectorToWorldSpace(localOff)) * rot
end

local function updateLockCamera(dt)
    L.aimPoint = nil
    if not L.lockActive or not L.lockedTarget then return end
    local targetChar = L.lockedTarget.Character
    if not targetChar or not isTargetValidForLock(L.lockedTarget) then clearLock(); return end
    local cam = refreshCamera()
    if not cam then return end

    local myChar = lplr and lplr.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")

    local aimPoint = getAimPoint(targetChar, myRoot and myRoot.Position)
    if not aimPoint then return end
    L.aimPoint = aimPoint

    dt = math.min(dt or 0.016, 0.1)

    local ok = pcall(function()
        local pivot = getOrbitPivot(cam, function(v) return not safepos(v) end)

        -- Objetivo pegado a ti: no mover la cámara (evita el giro frenético)
        local toAim = aimPoint - pivot
        local gain = nearGain(math.sqrt(toAim.X * toAim.X + toAim.Z * toAim.Z), L.nearMinHz, L.nearFullHz)
        if gain <= 0 then return end

        -- Punto de pantalla por donde sale realmente el disparo
        local screenPoint
        if L.aimAtCursor and UserInputService.MouseBehavior ~= Enum.MouseBehavior.LockCenter then
            screenPoint = UserInputService:GetMouseLocation()
        else
            screenPoint = cam.ViewportSize / 2
        end

        local goalYaw, goalPitch, curYaw, curPitch, localOff =
            solveAim(cam, pivot, aimPoint, screenPoint, L.pitchMinHz, L.maxPitch)
        if not goalYaw then return end

        local errYaw   = wrapAngle(goalYaw - curYaw)
        local errPitch = goalPitch - curPitch
        local err      = math.max(math.abs(errYaw), math.abs(errPitch))

        -- Rapidez independiente de los FPS que crece con el error
        local alpha = 1 - math.exp(-(L.trackStiffness + err * L.trackBoost) * dt)
        if err <= L.snapAngle then alpha = 1 end
        alpha = alpha * gain

        applyCameraAngles(cam, pivot, curYaw + errYaw * alpha, curPitch + errPitch * alpha, localOff)
    end)
    if not ok then return end
end

-- ──────────────────────────────────────────────────────────────────
-- [8]  EXPOSICIÓN DE DATOS (MONITOREO EXTERNO)
-- ──────────────────────────────────────────────────────────────────
local function updateExposedCharacterData()
    if not lplr or not lplr.Character then return end
    local char = lplr.Character

    local activeVal = char:FindFirstChild("AFO_LockActive")
    if not activeVal then
        activeVal = Instance.new("BoolValue")
        activeVal.Name = "AFO_LockActive"
        activeVal.Parent = char
    end

    local targetVal = char:FindFirstChild("AFO_LockedTarget")
    if not targetVal then
        targetVal = Instance.new("ObjectValue")
        targetVal.Name = "AFO_LockedTarget"
        targetVal.Parent = char
    end

    local isValid = false
    if L.lockActive and L.lockedTarget and isTargetValidForLock(L.lockedTarget) then
        isValid = true
    end

    local aimVal = char:FindFirstChild("AFO_AimPoint")
    if not aimVal then
        aimVal = Instance.new("Vector3Value")
        aimVal.Name = "AFO_AimPoint"
        aimVal.Parent = char
    end

    activeVal.Value = isValid
    
    if isValid then
        targetVal.Value = L.lockedTarget
        if L.aimPoint then aimVal.Value = L.aimPoint end
    else
        targetVal.Value = nil
    end
end

-- ──────────────────────────────────────────────────────────────────
-- [9]  TOGGLE / START / STOP
-- ──────────────────────────────────────────────────────────────────
-- Bloquea a un jugador concreto (también sirve para cambiar de objetivo en caliente)
local function lockOnPlayer(player)
    if not L.systemEnabled or not player or player == lplr then return false end
    if not isTargetValidForLock(player) then return false end
    L.avatarRequestId = L.avatarRequestId + 1
    L.lockedTarget    = player
    L.lockActive      = true
    applyLockIcon(player)
    updateLockHighlight()
    createLockInfoGui(L.infoGuiParent)
    loadAvatarImage()
    return true
end

local function toggleLock()
    if not L.systemEnabled then return end

    if not L.lockActive then
        local found = getClosestLockTarget()
        if found and isTargetValidForLock(found) then
            lockOnPlayer(found)
        end
    else
        clearLock()
    end
end

local function startLockSystem()
    if L.lockConn then L.lockConn:Disconnect(); L.lockConn = nil end
    pcall(function() RunService:UnbindFromRenderStep(L.renderName) end)

    L.lockConn = UserInputService.InputBegan:Connect(function(input, gpe)
        if not L.systemEnabled or gpe or isTyping() then return end
        if input.KeyCode == L.lockKey then toggleLock() end
    end)

    -- Prioridad justo después de la cámara por defecto: la corrección es la última palabra del frame
    RunService:BindToRenderStep(L.renderName, Enum.RenderPriority.Camera.Value + 1, function(dt)
        if not L.systemEnabled then return end
        updateLockCamera(dt)
        updateLockInfoGui()
        updateLockHighlight()
        updateExposedCharacterData()
    end)
end

local function stopLockSystem()
    L.systemEnabled = false
    L.avatarRequestId = L.avatarRequestId + 1
    if L.lockConn then L.lockConn:Disconnect(); L.lockConn = nil end
    pcall(function() RunService:UnbindFromRenderStep(L.renderName) end)
    clearLock()
    if L.lockHighlight then
        pcall(function() L.lockHighlight:Destroy() end)
        L.lockHighlight = nil
    end
    updateExposedCharacterData()
end

-- ──────────────────────────────────────────────────────────────────
-- [10] GUI EMBEBIBLE — sección "LOCK" del HUD externo
-- ──────────────────────────────────────────────────────────────────
local HUD_SECTION_HEIGHT = 66

local function buildHUDLockSection(expandZone, makeSection, makeRow, colors)
    local C_SEC1, C_ACCENT, C_GOLD, C_TEXT, C_SUBTEXT =
        colors.SEC1, colors.ACCENT, colors.GOLD, colors.TEXT, colors.SUBTEXT

    local lockSec = makeSection(HUD_SECTION_HEIGHT, C_SEC1, C_ACCENT)
    lockSec.Parent = expandZone

    local ROW_H   = 22
    local lockRow = makeRow(lockSec, 8)

    local lockIconEmoji = Instance.new("TextLabel", lockRow)
    lockIconEmoji.Size                 = UDim2.new(0, 18, 1, 0)
    lockIconEmoji.Position             = UDim2.new(0, 0, 0, 0)
    lockIconEmoji.BackgroundTransparency = 1
    lockIconEmoji.Font                 = Enum.Font.Legacy
    lockIconEmoji.TextSize             = 11
    lockIconEmoji.TextColor3           = C_GOLD
    lockIconEmoji.Text                 = "🎯"
    lockIconEmoji.TextXAlignment       = Enum.TextXAlignment.Center
    lockIconEmoji.TextYAlignment       = Enum.TextYAlignment.Center

    local lockLabel = Instance.new("TextLabel", lockRow)
    lockLabel.Size                 = UDim2.new(0, 100, 1, 0)
    lockLabel.Position             = UDim2.new(0, 22, 0, 0)
    lockLabel.BackgroundTransparency = 1
    lockLabel.Font                 = Enum.Font.GothamBold
    lockLabel.TextSize             = 11
    lockLabel.TextColor3           = C_TEXT
    lockLabel.Text                 = FT.lock_label .. "  [" .. L.lockKey.Name .. "]"
    lockLabel.TextXAlignment       = Enum.TextXAlignment.Left
    lockLabel.TextYAlignment       = Enum.TextYAlignment.Center

    local lockHint = Instance.new("TextLabel", lockRow)
    lockHint.Size                 = UDim2.new(1, -128, 1, 0)
    lockHint.Position             = UDim2.new(0, 124, 0, 0)
    lockHint.BackgroundTransparency = 1
    lockHint.Font                 = Enum.Font.Gotham
    lockHint.TextSize             = 9
    lockHint.TextColor3           = C_SUBTEXT
    lockHint.Text                 = FT.lock_hint_prefix .. L.lockKey.Name
    lockHint.TextXAlignment       = Enum.TextXAlignment.Right
    lockHint.TextYAlignment       = Enum.TextYAlignment.Center

    L.lockLabels = { label = lockLabel, hint = lockHint }

    -- Fila 2: cuadro con autocompletado.  "apodo  /  nombre   (Enter = completar + lock)
    local searchRow = makeRow(lockSec, 8 + ROW_H + 6)
    local searchBox = Instance.new("TextBox", searchRow)
    searchBox.Name                   = "LockSearchBox"
    searchBox.Size                   = UDim2.new(1, 0, 1, 0)
    searchBox.BackgroundColor3       = Color3.fromRGB(18, 12, 30)
    searchBox.BorderSizePixel        = 0
    searchBox.Font                   = Enum.Font.Gotham
    searchBox.TextSize               = 10
    searchBox.TextColor3             = C_TEXT
    searchBox.PlaceholderText        = 'Jugador  ·  " para apodo'
    searchBox.PlaceholderColor3      = C_SUBTEXT
    searchBox.Text                   = ""
    searchBox.ClearTextOnFocus       = false
    searchBox.ClipsDescendants       = true
    searchBox.TextXAlignment         = Enum.TextXAlignment.Left
    Instance.new("UICorner", searchBox).CornerRadius = UDim.new(0, 5)
    local searchPad = Instance.new("UIPadding", searchBox)
    searchPad.PaddingLeft = UDim.new(0, 6)
    local searchStroke = Instance.new("UIStroke", searchBox)
    searchStroke.Thickness = 1

    local C_NICK = Color3.fromRGB(80, 200, 255)
    local flashToken = 0

    -- Borde morado = busca por nombre; celeste = modo apodo (se detectó la comilla)
    local function paintStroke()
        local _, nickMode = parseQuery(searchBox.Text)
        searchStroke.Color        = nickMode and C_NICK or C_ACCENT
        searchStroke.Transparency = nickMode and 0.2 or 0.6
    end
    paintStroke()

    local function flash(color)
        flashToken = flashToken + 1
        local token = flashToken
        searchStroke.Color        = color
        searchStroke.Transparency = 0
        task.delay(0.6, function()
            if token == flashToken and searchStroke.Parent then paintStroke() end
        end)
    end

    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        if searchBox:IsFocused() then paintStroke() end
    end)

    searchBox.FocusLost:Connect(function(enterPressed)
        if trimText(searchBox.Text) == "" then paintStroke() return end
        local player, completed = autocompletePlayer(searchBox.Text)
        if not player then
            flash(Color3.fromRGB(255, 80, 80))
            return
        end
        searchBox.Text = completed
        if enterPressed then
            flash(lockOnPlayer(player) and Color3.fromRGB(80, 255, 150) or Color3.fromRGB(255, 80, 80))
        else
            paintStroke()
        end
    end)

    L.searchBox = searchBox
    return lockSec
end

-- ──────────────────────────────────────────────────────────────────
-- [11] API PÚBLICA
-- ──────────────────────────────────────────────────────────────────
local M = {}

function M.Start(lplrRef, lockKeyCode)
    lplr   = lplrRef or Players.LocalPlayer
    camera = workspace.CurrentCamera
    if lockKeyCode then L.lockKey = lockKeyCode end
    _reloadFT()
    L.systemEnabled = true
    startLockSystem()
end

function M.Stop()
    stopLockSystem()
end

function M.Toggle()
    toggleLock()
end

function M.SetLockKey(keyCode)
    L.lockKey = keyCode
    if L.lockLabels then
        L.lockLabels.label.Text = FT.lock_label .. "  [" .. keyCode.Name .. "]"
        L.lockLabels.hint.Text  = FT.lock_hint_prefix .. keyCode.Name
    end
    if not L.systemEnabled then return end
    if L.lockConn then L.lockConn:Disconnect(); L.lockConn = nil end
    L.lockConn = UserInputService.InputBegan:Connect(function(input, gpe)
        if not L.systemEnabled or gpe or isTyping() then return end
        if input.KeyCode == L.lockKey then toggleLock() end
    end)
end

-- Autocompletado: "apodo -> DisplayName, nombre -> usuario
function M.ParseQuery(text)         return parseQuery(text) end
function M.AutocompletePlayer(text) return autocompletePlayer(text) end
function M.SearchPlayers(text)
    local query, nickMode = parseQuery(text)
    return searchPlayers(query, nickMode)
end
-- Acepta un Player o un texto ("apodo / nombre) y lo bloquea
function M.LockOnPlayer(playerOrText)
    local player = playerOrText
    if type(playerOrText) == "string" then
        player = autocompletePlayer(playerOrText)
    end
    return lockOnPlayer(player)
end

-- Puntería: usa estos valores para ajustar el pivote desde fuera
function M.SetAimPart(name)           L.aimPart = name end             -- "Head", "UpperTorso"... o nil (auto)
function M.SetAimOffset(v3)           L.aimOffset = v3 or Vector3.zero end
function M.SetAimAtCursor(enabled)    L.aimAtCursor = enabled == true end
function M.SetTrackStiffness(n)       L.trackStiffness = math.max(tonumber(n) or 40, 1) end
function M.SetTrackBoost(n)           L.trackBoost = math.max(tonumber(n) or 60, 0) end
function M.SetProjectileSpeed(n)      L.projectileSpeed = math.max(tonumber(n) or 0, 0) end
-- Punto exacto al que apunta la cámara (úsalo para lanzar tus esferas)
function M.GetAimPoint()              return L.aimPoint end

function M.GetLockKey()  return L.lockKey   end
function M.IsActive()    return L.lockActive end
function M.GetTarget()   return L.lockedTarget end

function M.IsLockActive()
    return L.lockActive == true
        and L.lockedTarget ~= nil
        and isTargetValidForLock(L.lockedTarget)
end

function M.GetTargetInfo()
    if not M.IsLockActive() then return nil end
    return L.lockedTarget
end

function M.GetTargetHealth()
    if not M.IsLockActive() then return 0, 0 end
    local char = L.lockedTarget.Character
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return 0, 0 end
    return math.max(hum.Health, 0), math.max(hum.MaxHealth, 1)
end

function M.GetTargetDistance()
    if not M.IsLockActive() then return 0 end
    local myChar = lplr and lplr.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local tChar  = L.lockedTarget.Character
    local tRoot  = tChar and tChar:FindFirstChild("HumanoidRootPart")
    if not myRoot or not tRoot then return 0 end
    
    local dist = (myRoot.Position - tRoot.Position).Magnitude
    if isnan(dist) then return 0 end
    return dist
end

function M.GetStatus()
    local active = M.IsLockActive()
    local health, maxHealth = M.GetTargetHealth()
    return {
        lockActive = active,
        target     = active and L.lockedTarget or nil,
        targetName = active and L.lockedTarget.Name or "",
        targetDisplayName = active and (L.lockedTarget.DisplayName or L.lockedTarget.Name) or "",
        health     = health,
        maxHealth  = maxHealth,
        distance   = M.GetTargetDistance(),
    }
end

M.CreateInfoGui = function(parentFrame)
    if L.systemEnabled and L.lockActive and L.lockedTarget then
        createLockInfoGui(parentFrame)
    end
end
M.DestroyInfoGui      = destroyLockInfoGui
M.BuildHUDLockSection = buildHUDLockSection
M.HUD_SECTION_HEIGHT  = HUD_SECTION_HEIGHT

return M
