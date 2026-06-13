--[[
╔══════════════════════════════════════════════════════════════════╗
║                    LOCK SYSTEM  (módulo independiente)           ║
║  Sistema de lock/target: cámara, GUI info, highlight, icono,      ║
║  tecla de lock, y "hooks" que el módulo de Fly puede consultar    ║
║  para aplicar TP‑debajo / anti‑orbiting / rotación‑Y SOLO         ║
║  cuando el vuelo está activo.                                     ║
║                                                                    ║
║  VERSIÓN MODULAR: sin ejecución de código al cargar, todo         ║
║  se inicializa explícitamente mediante M.Start().                 ║
╚══════════════════════════════════════════════════════════════════╝
--]]

-- ──────────────────────────────────────────────────────────────────
-- [1]  SERVICIOS Y UTILIDADES GENÉRICAS
-- ──────────────────────────────────────────────────────────────────
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

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
-- [2]  IDIOMA / LOCALIZACIÓN (subset usado por el sistema de lock)
-- ──────────────────────────────────────────────────────────────────
local LockLang = {
    ES = {
        lock_label       = "LOCK",
        lock_hint_prefix = "Apuntar + ",
        height_below     = "studs abajo",
        height_above     = "studs arriba",
        height_same      = "mismo nivel",
    },
    EN = {
        lock_label       = "LOCK",
        lock_hint_prefix = "Aim + ",
        height_below     = "studs below",
        height_above     = "studs above",
        height_same      = "same level",
    },
}

-- Variable de idioma actual (se asigna en M.Start)
local FT = LockLang["ES"]

-- ──────────────────────────────────────────────────────────────────
-- [3]  ESTADO INTERNO (L)
-- ──────────────────────────────────────────────────────────────────
local LOCK_ROTATION_SMOOTH = 0.8
local LOCK_ICON_ID = "rbxassetid://82817965256191"

local L = {
    lockKey        = Enum.KeyCode.X,
    lockActive     = false,
    lockedTarget   = nil,

    lockIconGui    = nil,
    lockInfoGui    = nil,
    lockHighlight  = nil,
    lockLabels     = nil,

    lockConn       = nil,
    lockRenderConn = nil,

    lockCameraLerp = 0.18,

    straightLineActive = false,      -- usado por anti‑orbiting
}

local lplr   = nil
local camera = nil

-- Proveedor del estado del Fly (se asigna con M.SetFlyEnabledProvider)
local isFlyEnabledFn = function() return false end

-- Callback opcional para registrar altura previa a TP (caída épica)
local onPreTeleportHeight = nil

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
    if not camera then return nil end
    for _, player in ipairs(Players:GetPlayers()) do
        if player == lplr then continue end
        if not isTargetValidForLock(player) then continue end
        local targetChar = player.Character
        if not targetChar then continue end
        local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
        if not targetRoot then continue end
        local ok3, screenPos, onScreen = pcall(function()
            return camera:WorldToScreenPoint(targetRoot.Position)
        end)
        if not ok3 or not onScreen then continue end
        local mousePos   = UserInputService:GetMouseLocation()
        local screenDist = (Vector2.new(mousePos.X, mousePos.Y) - Vector2.new(screenPos.X, screenPos.Y)).Magnitude
        if isnan(screenDist) or screenDist > 300 then continue end
        local worldDist  = myRoot and (myRoot.Position - targetRoot.Position).Magnitude or 0
        if isnan(worldDist) then continue end
        local score = screenDist + (worldDist * 0.2)
        if score < bestScore then bestScore = score; closestPlayer = player end
    end
    return closestPlayer
end

-- ──────────────────────────────────────────────────────────────────
-- [5]  ICONO DE LOCK + HIGHLIGHT
-- ──────────────────────────────────────────────────────────────────
local function removeLockIcon()
    if L.lockIconGui then pcall(function() L.lockIconGui:Destroy() end); L.lockIconGui = nil end
end

local function applyLockIcon(player)
    removeLockIcon()
    local chest = player.Character and player.Character:FindFirstChild("UpperTorso")
    local torso = chest or (player.Character and player.Character:FindFirstChild("HumanoidRootPart"))
    if not torso then return end
    L.lockIconGui = Instance.new("BillboardGui", torso)
    L.lockIconGui.Name        = "LockIcon"
    L.lockIconGui.Size        = UDim2.new(0, 50, 0, 50)
    L.lockIconGui.AlwaysOnTop = true
    L.lockIconGui.StudsOffset = Vector3.new(0, 0, 0)
    local img = Instance.new("ImageLabel", L.lockIconGui)
    img.Size = UDim2.new(1, 0, 1, 0); img.BackgroundTransparency = 1
    img.Image = LOCK_ICON_ID
    img.ImageColor3 = Color3.fromRGB(255, 255, 255); img.ScaleType = Enum.ScaleType.Fit
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
    if not L.lockActive or not L.lockedTarget then
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
    if not L.lockInfoGui then return end
    local playerImg = L.lockInfoGui:FindFirstChild("PlayerImage", true)
    if not playerImg then return end
    if L.lockActive and L.lockedTarget then
        local userId = L.lockedTarget.UserId
        task.spawn(function()
            local success, content = pcall(function()
                return Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.AvatarBust, Enum.ThumbnailSize.Size420x420)
            end)
            if success and content and playerImg and playerImg.Parent then
                playerImg.Image = content
            end
        end)
    end
end

local function createLockInfoGui(parentFrame)
    if L.lockInfoGui then pcall(function() L.lockInfoGui:Destroy() end); L.lockInfoGui = nil end
    local C_PURPLE = Color3.fromRGB(110, 30, 180)
    local C_BLACK  = Color3.fromRGB(6, 4, 12)
    local C_TEXT   = Color3.fromRGB(220, 190, 255)
    local infoFrame = Instance.new("Frame")
    infoFrame.Name = "LockInfoPanel"; infoFrame.Size = UDim2.new(0, 220, 0, 95)
    infoFrame.Position = UDim2.new(1, 12, 0, 8); infoFrame.BackgroundColor3 = C_BLACK
    infoFrame.BackgroundTransparency = 0.15; infoFrame.BorderSizePixel = 0
    infoFrame.ZIndex = 10; infoFrame.Visible = false; infoFrame.Parent = parentFrame
    Instance.new("UICorner", infoFrame).CornerRadius = UDim.new(0, 8)
    local stroke = Instance.new("UIStroke", infoFrame)
    stroke.Color = C_PURPLE; stroke.Thickness = 1; stroke.Transparency = 0.5
    local iconLbl = Instance.new("TextLabel", infoFrame)
    iconLbl.Size=UDim2.new(0,28,0,28); iconLbl.Position=UDim2.new(0,6,0.5,-14)
    iconLbl.BackgroundTransparency=1; iconLbl.Font=Enum.Font.Legacy
    iconLbl.TextSize=20; iconLbl.TextColor3=Color3.fromRGB(255,220,80); iconLbl.Text="🎯"
    local nameLabel = Instance.new("TextLabel", infoFrame)
    nameLabel.Name="NameLabel"; nameLabel.Size=UDim2.new(0,120,0,20); nameLabel.Position=UDim2.new(0,40,0,6)
    nameLabel.BackgroundTransparency=1; nameLabel.Font=Enum.Font.GothamBold
    nameLabel.TextSize=12; nameLabel.TextColor3=C_TEXT; nameLabel.Text="---"; nameLabel.TextXAlignment=Enum.TextXAlignment.Left
    local distLabel = Instance.new("TextLabel", infoFrame)
    distLabel.Name="DistLabel"; distLabel.Size=UDim2.new(0,120,0,18); distLabel.Position=UDim2.new(0,40,0,28)
    distLabel.BackgroundTransparency=1; distLabel.Font=Enum.Font.Gotham
    distLabel.TextSize=10; distLabel.TextColor3=Color3.fromRGB(200,170,255); distLabel.Text="--- studs"; distLabel.TextXAlignment=Enum.TextXAlignment.Left
    local healthLabel = Instance.new("TextLabel", infoFrame)
    healthLabel.Name="HealthLabel"; healthLabel.Size=UDim2.new(0,120,0,18); healthLabel.Position=UDim2.new(0,40,0,48)
    healthLabel.BackgroundTransparency=1; healthLabel.Font=Enum.Font.Legacy
    healthLabel.TextSize=10; healthLabel.TextColor3=Color3.fromRGB(255,150,150); healthLabel.Text="❤️ ---"; healthLabel.TextXAlignment=Enum.TextXAlignment.Left
    local heightLabel = Instance.new("TextLabel", infoFrame)
    heightLabel.Name="HeightLabel"; heightLabel.Size=UDim2.new(0,120,0,15); heightLabel.Position=UDim2.new(0,40,0,68)
    heightLabel.BackgroundTransparency=1; heightLabel.Font=Enum.Font.Gotham
    heightLabel.TextSize=9; heightLabel.TextColor3=Color3.fromRGB(150,220,255); heightLabel.Text="---"; heightLabel.TextXAlignment=Enum.TextXAlignment.Left
    local playerImgContainer = Instance.new("Frame", infoFrame)
    playerImgContainer.Name="PlayerImgContainer"; playerImgContainer.Size=UDim2.new(0,55,0,55)
    playerImgContainer.Position=UDim2.new(1,-65,0,20); playerImgContainer.BackgroundColor3=Color3.fromRGB(20,10,40)
    playerImgContainer.BackgroundTransparency=0.3; playerImgContainer.BorderSizePixel=0; playerImgContainer.ZIndex=11
    Instance.new("UICorner", playerImgContainer).CornerRadius = UDim.new(1, 0)
    local playerImg = Instance.new("ImageLabel", playerImgContainer)
    playerImg.Name="PlayerImage"; playerImg.Size=UDim2.new(1,0,1,0); playerImg.Position=UDim2.new(0,0,0,0)
    playerImg.BackgroundTransparency=1; playerImg.Image=""; playerImg.ZIndex=12
    Instance.new("UICorner", playerImg).CornerRadius = UDim.new(1, 0)
    L.lockInfoGui = infoFrame
end

local function destroyLockInfoGui()
    if L.lockInfoGui then pcall(function() L.lockInfoGui:Destroy() end); L.lockInfoGui = nil end
end

-- updateLockInfoGui actualiza el panel de información del objetivo.
-- IMPORTANTE: el bloque "TP estar abajo de" (cuando el objetivo está
-- muy por encima nuestro) SOLO se ejecuta si isFlyEnabledFn() es true.
local function updateLockInfoGui()
    if not L.lockInfoGui then return end
    if not L.lockActive or not L.lockedTarget
    or not L.lockedTarget.Character
    or not isTargetValidForLock(L.lockedTarget) then
        L.lockInfoGui.Visible = false
        if L.lockActive and L.lockedTarget and not isTargetValidForLock(L.lockedTarget) then
            L.lockActive   = false
            L.lockedTarget = nil
            removeLockIcon()
            updateLockHighlight()
        end
        return
    end
    L.lockInfoGui.Visible = true
    local root     = L.lockedTarget.Character:FindFirstChild("HumanoidRootPart")
    local humanoid = L.lockedTarget.Character:FindFirstChildOfClass("Humanoid")
    local myChar   = lplr and lplr.Character
    local myRoot   = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local dist = camera and (camera.CFrame.Position - root.Position).Magnitude or 0
    if isnan(dist) then dist = 0 end
    local displayName = L.lockedTarget.DisplayName or "?"
    if #displayName > 14 then displayName = displayName:sub(1, 12) .. ".." end
    local nameLabel = L.lockInfoGui:FindFirstChild("NameLabel")
    if nameLabel then nameLabel.Text = displayName end
    local distLabel = L.lockInfoGui:FindFirstChild("DistLabel")
    if distLabel then distLabel.Text = math.floor(dist) .. " studs" end
    local healthLabel = L.lockInfoGui:FindFirstChild("HealthLabel")
    if healthLabel and humanoid then
        local rawHealth = math.max(humanoid.Health, 0)
        local maxHealth = math.max(humanoid.MaxHealth, 1)
        local healthStr
        local intPart = math.floor(rawHealth)
        if intPart == 0 and rawHealth > 0 then
            local rounded = math.floor(rawHealth * 100 + 0.5) / 100
            healthStr = string.format("%.2f", rounded)
        else
            healthStr = tostring(math.floor(rawHealth + 0.5))
        end
        local pct = rawHealth / maxHealth
        local heartEmoji
        if rawHealth <= 0 then
            heartEmoji = "☠️"
        elseif pct > 0.75 then
            heartEmoji = "💚"
        elseif pct > 0.50 then
            heartEmoji = "💛"
        elseif pct > 0.25 then
            heartEmoji = "🧡"
        else
            heartEmoji = "❤️"
        end
        healthLabel.Font = Enum.Font.Legacy
        healthLabel.Text = heartEmoji .. " " .. healthStr .. "/" .. tostring(math.floor(maxHealth + 0.5))
        if rawHealth <= 0 then
            healthLabel.TextColor3 = Color3.fromRGB(120, 120, 120)
        elseif pct > 0.75 then
            healthLabel.TextColor3 = Color3.fromRGB(80, 255, 80)
        elseif pct > 0.50 then
            healthLabel.TextColor3 = Color3.fromRGB(255, 220, 80)
        elseif pct > 0.25 then
            healthLabel.TextColor3 = Color3.fromRGB(255, 160, 60)
        else
            healthLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
        end
    end
    local heightLabel = L.lockInfoGui:FindFirstChild("HeightLabel")
    if heightLabel and myRoot then
        local heightDiff = math.floor(myRoot.Position.Y - root.Position.Y)
        if isnan(heightDiff) then heightDiff = 0 end
        if heightDiff > 0 then
            heightLabel.Text = "▼ " .. heightDiff .. " " .. FT.height_below
            heightLabel.TextColor3 = Color3.fromRGB(150, 220, 255)
        elseif heightDiff < 0 then
            heightLabel.Text = "▲ " .. math.abs(heightDiff) .. " " .. FT.height_above
            heightLabel.TextColor3 = Color3.fromRGB(255, 200, 100)

            -- ════════════════════════════════════════════════════════
            -- [SUB-SISTEMA 1] TP "estar abajo de" el objetivo
            -- Solo se aplica si el Fly está activo (isFlyEnabledFn).
            -- ════════════════════════════════════════════════════════
            if isFlyEnabledFn() and math.abs(heightDiff) >= 15 then
                local toTargetH = Vector3.new(
                    root.Position.X - myRoot.Position.X, 0,
                    root.Position.Z - myRoot.Position.Z
                )
                local behindDir = toTargetH.Magnitude > 0.1 and -toTargetH.Unit or Vector3.new(0, 0, 1)
                local tpPos = root.Position + behindDir * 3
                if safepos(tpPos) then
                    local preTPHeight = 0
                    do
                        local rp4 = RaycastParams.new()
                        rp4.FilterType = Enum.RaycastFilterType.Exclude
                        rp4.FilterDescendantsInstances = {lplr and lplr.Character}
                        local ray4 = workspace:Raycast(myRoot.Position, Vector3.new(0, -3000, 0), rp4)
                        if ray4 then preTPHeight = myRoot.Position.Y - ray4.Position.Y end
                    end
                    pcall(function()
                        myRoot.CFrame = CFrame.new(tpPos, root.Position)
                        myRoot.AssemblyLinearVelocity  = Vector3.new(0, 0, 0)
                        myRoot.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                    end)
                    if preTPHeight > 0 and type(onPreTeleportHeight) == "function" then
                        pcall(onPreTeleportHeight, preTPHeight)
                    end
                end
            end
        else
            heightLabel.Text = "● " .. FT.height_same
            heightLabel.TextColor3 = Color3.fromRGB(150, 255, 150)
        end
    end
    loadAvatarImage()
end

-- ──────────────────────────────────────────────────────────────────
-- [7]  CÁMARA DE LOCK
-- ──────────────────────────────────────────────────────────────────
local function updateLockCamera()
    if not L.lockActive or not L.lockedTarget then return end
    local targetChar = L.lockedTarget.Character
    if not targetChar then L.lockActive=false; L.lockedTarget=nil; removeLockIcon(); updateLockHighlight(); return end
    if not isTargetValidForLock(L.lockedTarget) then
        L.lockActive=false; L.lockedTarget=nil; removeLockIcon(); updateLockHighlight(); return
    end
    local myChar     = lplr and lplr.Character
    local myRoot     = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
    if myRoot and targetRoot then
        local d = (myRoot.Position - targetRoot.Position).Magnitude
        if not isnan(d) and d > 750 then
            L.lockActive=false; L.lockedTarget=nil; removeLockIcon(); updateLockHighlight(); return
        end
    end
    local targetPart = targetChar:FindFirstChild("UpperTorso") or targetChar:FindFirstChild("HumanoidRootPart")
    if not targetPart then return end
    if not camera then return end
    local worldDist = myRoot and (myRoot.Position - targetPart.Position).Magnitude or 999
    if isnan(worldDist) then worldDist = 999 end
    local currentPos = camera.CFrame.Position
    local desiredCF  = CFrame.new(currentPos, targetPart.Position)
    local lerpFactor = L.lockCameraLerp
    if worldDist < 8  then lerpFactor = lerpFactor * 0.25
    elseif worldDist < 20 then lerpFactor = lerpFactor * 0.6 end
    lerpFactor = math.clamp(lerpFactor, 0, 1)
    pcall(function() camera.CFrame = camera.CFrame:Lerp(desiredCF, lerpFactor) end)
end

-- ──────────────────────────────────────────────────────────────────
-- [8]  TOGGLE / START / STOP
-- ──────────────────────────────────────────────────────────────────
local function toggleLock()
    if not L.lockActive then
        local found = getClosestLockTarget()
        if found and isTargetValidForLock(found) then
            L.lockedTarget = found
            L.lockActive   = true
            applyLockIcon(found)
            updateLockHighlight()
            loadAvatarImage()
        end
    else
        L.lockActive   = false
        L.lockedTarget = nil
        removeLockIcon()
        updateLockHighlight()
    end
end

local function startLockSystem()
    if L.lockConn then L.lockConn:Disconnect(); L.lockConn = nil end
    if L.lockRenderConn then L.lockRenderConn:Disconnect(); L.lockRenderConn = nil end

    L.lockConn = UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe or isTyping() then return end
        if input.KeyCode == L.lockKey then toggleLock() end
    end)

    L.lockRenderConn = RunService.RenderStepped:Connect(function()
        updateLockInfoGui()
        updateLockCamera()
        updateLockHighlight()
    end)
end

local function stopLockSystem()
    if L.lockConn       then L.lockConn:Disconnect();       L.lockConn       = nil end
    if L.lockRenderConn then L.lockRenderConn:Disconnect(); L.lockRenderConn = nil end
    L.lockActive   = false
    L.lockedTarget = nil
    removeLockIcon()
    updateLockHighlight()
    destroyLockInfoGui()
    if L.lockHighlight then pcall(function() L.lockHighlight:Destroy() end); L.lockHighlight = nil end
end

-- ──────────────────────────────────────────────────────────────────
-- [9]  GUI EMBEBIBLE — sección "LOCK" del HUD de Fly
-- ──────────────────────────────────────────────────────────────────
local HUD_SECTION_HEIGHT = 38

local function buildHUDLockSection(expandZone, makeSection, makeRow, colors)
    local C_SEC1, C_ACCENT, C_GOLD, C_TEXT, C_SUBTEXT =
        colors.SEC1, colors.ACCENT, colors.GOLD, colors.TEXT, colors.SUBTEXT

    local lockSec = makeSection(HUD_SECTION_HEIGHT, C_SEC1, C_ACCENT)
    lockSec.Parent = expandZone

    local ROW_H = 22
    local lockRow = makeRow(lockSec, (HUD_SECTION_HEIGHT - ROW_H) / 2)

    local lockIconEmoji = Instance.new("TextLabel", lockRow)
    lockIconEmoji.Size = UDim2.new(0, 18, 1, 0); lockIconEmoji.Position = UDim2.new(0, 0, 0, 0)
    lockIconEmoji.BackgroundTransparency = 1; lockIconEmoji.Font = Enum.Font.Legacy
    lockIconEmoji.TextSize = 11; lockIconEmoji.TextColor3 = C_GOLD
    lockIconEmoji.Text = "🎯"; lockIconEmoji.TextXAlignment = Enum.TextXAlignment.Center
    lockIconEmoji.TextYAlignment = Enum.TextYAlignment.Center

    local lockLabel = Instance.new("TextLabel", lockRow)
    lockLabel.Size = UDim2.new(0, 100, 1, 0); lockLabel.Position = UDim2.new(0, 22, 0, 0)
    lockLabel.BackgroundTransparency = 1; lockLabel.Font = Enum.Font.GothamBold
    lockLabel.TextSize = 11; lockLabel.TextColor3 = C_TEXT
    lockLabel.Text = FT.lock_label .. "  [" .. L.lockKey.Name .. "]"
    lockLabel.TextXAlignment = Enum.TextXAlignment.Left
    lockLabel.TextYAlignment = Enum.TextYAlignment.Center

    local lockHint = Instance.new("TextLabel", lockRow)
    lockHint.Size = UDim2.new(1, -128, 1, 0); lockHint.Position = UDim2.new(0, 124, 0, 0)
    lockHint.BackgroundTransparency = 1; lockHint.Font = Enum.Font.Gotham
    lockHint.TextSize = 9; lockHint.TextColor3 = C_SUBTEXT
    lockHint.Text = FT.lock_hint_prefix .. L.lockKey.Name
    lockHint.TextXAlignment = Enum.TextXAlignment.Right
    lockHint.TextYAlignment = Enum.TextYAlignment.Center

    L.lockLabels = { label = lockLabel, hint = lockHint }
    return lockSec
end

-- ──────────────────────────────────────────────────────────────────
-- [10] HOOKS PARA FLY (sub-sistemas condicionados)
-- ──────────────────────────────────────────────────────────────────

-- [SUB-SISTEMA 3] Rotación Y (mirar arriba/abajo hacia el target)
-- Devuelve nil si el Fly está apagado o no hay lock activo/válido.
local function getAimCFrame(rootPosition, dashMagnitude)
    if not isFlyEnabledFn() then return nil end
    if not L.lockActive or not L.lockedTarget then return nil end
    local tChar = L.lockedTarget.Character
    if not tChar or not isTargetValidForLock(L.lockedTarget) then
        L.lockActive=false; L.lockedTarget=nil; removeLockIcon(); updateLockHighlight()
        return nil
    end
    local aimPart = tChar:FindFirstChild("UpperTorso") or tChar:FindFirstChild("HumanoidRootPart")
    if not aimPart then return nil end
    local desiredCF = CFrame.lookAt(rootPosition, aimPart.Position, Vector3.new(0, 1, 0))
    local smooth = LOCK_ROTATION_SMOOTH * (1 + math.min(0.5, ((dashMagnitude or 0) / 300)))
    smooth = math.clamp(smooth, 0, 1)
    return desiredCF, smooth
end

-- [SUB-SISTEMA 2] Anti-orbiting
-- Redirige el vector de movimiento para evitar orbitar al objetivo.
-- Solo se aplica si el Fly está activo, el modo es fast/turbo, hay lock y W presionada.
local function applyAntiOrbit(root2, move, mode, wD)
    if not isFlyEnabledFn() then
        L.straightLineActive = false
        return move
    end
    if not ((mode == "fast" or mode == "turbo") and L.lockActive and L.lockedTarget and wD) then
        L.straightLineActive = false
        return move
    end
    if not root2 then return move end

    local targetChar2 = L.lockedTarget.Character
    if not targetChar2 then return move end
    local targetRoot2 = targetChar2:FindFirstChild("HumanoidRootPart")
    if not targetRoot2 or not safepos(targetRoot2.Position) then return move end

    -- Si no hay suelo y objetivo muy arriba, TP lateral (parte del anti-orbiting)
    local noFloor = false
    do
        local rpCheck = RaycastParams.new()
        rpCheck.FilterType = Enum.RaycastFilterType.Exclude
        if lplr and lplr.Character then rpCheck.FilterDescendantsInstances = {lplr.Character} end
        local hitCheck = workspace:Raycast(root2.Position, Vector3.new(0, -5, 0), rpCheck)
        noFloor = (hitCheck == nil)
    end
    local heightDiff = targetRoot2.Position.Y - root2.Position.Y
    if noFloor and not isnan(heightDiff) and heightDiff > 10 then
        local toTarget = targetRoot2.Position - root2.Position
        if toTarget.Magnitude > 0.01 then
            local newPos = targetRoot2.Position - (toTarget.Unit * 5)
            if safepos(newPos) then
                pcall(function() root2.CFrame = CFrame.new(newPos, targetRoot2.Position) end)
            end
        end
    end

    -- Redirección del vector de movimiento
    local toTarget3D = targetRoot2.Position - root2.Position
    local horDist2   = Vector3.new(toTarget3D.X, 0, toTarget3D.Z).Magnitude
    local vertDiff   = math.abs(toTarget3D.Y)
    if not isnan(horDist2) and not isnan(vertDiff) and horDist2 < 25 and vertDiff > 8 then
        L.straightLineActive = true
        if toTarget3D.Magnitude > 0.1 then
            move = toTarget3D.Unit * move.Magnitude
            if move.Magnitude < 0.01 then move = toTarget3D.Unit end
        end
    else
        L.straightLineActive = false
        local horDir2 = Vector3.new(toTarget3D.X, 0, toTarget3D.Z)
        if horDir2.Magnitude > 0.1 then
            move = Vector3.new(horDir2.Unit.X * move.Magnitude, move.Y, horDir2.Unit.Z * move.Magnitude)
        end
        if not isnan(horDist2) and horDist2 < 15 then
            local factor2 = math.clamp(horDist2 / 15, 0.2, 1)
            move = move * factor2
        end
    end

    return move
end

-- ──────────────────────────────────────────────────────────────────
-- [11] API PÚBLICA (M)
-- ──────────────────────────────────────────────────────────────────
local M = {}

-- Inicializa el sistema de lock.
-- @param lplrRef - Players.LocalPlayer
-- @param lockKeyCode - Enum.KeyCode opcional (default X)
-- @param parentFrameForInfoGui - Frame opcional donde montar el panel info
-- @param lang - string "ES" o "EN" (opcional, por defecto lee de readfile si existe, sino "ES")
function M.Start(lplrRef, lockKeyCode, parentFrameForInfoGui, lang)
    lplr   = lplrRef or Players.LocalPlayer
    camera = workspace.CurrentCamera

    if lockKeyCode then
        L.lockKey = lockKeyCode
    end

    -- Cargar idioma
    local desiredLang = lang
    if not desiredLang then
        pcall(function()
            local data = readfile("AllForOne/lang.txt")
            if data == "EN" or data == "ES" then desiredLang = data end
        end)
    end
    if desiredLang == "EN" then
        FT = LockLang["EN"]
    else
        FT = LockLang["ES"]
    end

    if parentFrameForInfoGui then
        createLockInfoGui(parentFrameForInfoGui)
    end

    startLockSystem()
end

-- Detiene completamente el sistema de lock (libera conexiones y GUI).
function M.Stop()
    stopLockSystem()
end

-- Activa/desactiva manualmente el lock sobre el objetivo más cercano al cursor.
function M.Toggle()
    toggleLock()
end

-- Cambia la tecla de lock (por defecto X).
function M.SetLockKey(keyCode)
    L.lockKey = keyCode
    if L.lockLabels then
        L.lockLabels.label.Text = FT.lock_label .. "  [" .. keyCode.Name .. "]"
        L.lockLabels.hint.Text  = FT.lock_hint_prefix .. keyCode.Name
    end
    -- Reconectar el InputBegan con la nueva tecla
    if L.lockConn then
        L.lockConn:Disconnect()
        L.lockConn = nil
    end
    L.lockConn = UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe or isTyping() then return end
        if input.KeyCode == L.lockKey then toggleLock() end
    end)
end

function M.GetLockKey()
    return L.lockKey
end

function M.IsActive()
    return L.lockActive
end

function M.GetTarget()
    return L.lockedTarget
end

-- Provee una función que devuelve true si el vuelo está activo.
-- Debe ser llamada por el módulo de Fly una vez al inicio.
function M.SetFlyEnabledProvider(fn)
    if type(fn) == "function" then
        isFlyEnabledFn = fn
    end
end

-- Callback opcional: se invoca con la altura previa a un TP "estar abajo de".
function M.SetPreTeleportHeightCallback(fn)
    onPreTeleportHeight = fn
end

-- Crea el panel de información (lo llama el Fly cuando construye su HUD)
function M.CreateInfoGui(parentFrame)
    createLockInfoGui(parentFrame)
end

-- Destruye el panel de información
function M.DestroyInfoGui()
    destroyLockInfoGui()
end

-- Construye la sección "LOCK" dentro del HUD del Fly
function M.BuildHUDLockSection(expandZone, makeSection, makeRow, colors)
    return buildHUDLockSection(expandZone, makeSection, makeRow, colors)
end

-- Altura de la sección (para que el Fly pueda calcular el layout)
M.HUD_SECTION_HEIGHT = HUD_SECTION_HEIGHT

-- Hooks de Fly (sub-sistemas 2 y 3)
M.GetAimCFrame   = getAimCFrame
M.ApplyAntiOrbit = applyAntiOrbit

-- Indica si el movimiento está siendo forzado en línea recta hacia el target
function M.IsStraightLineActive()
    return L.straightLineActive
end

return M
