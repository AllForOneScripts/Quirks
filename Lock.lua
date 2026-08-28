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
-- [2]  IDIOMA / LOCALIZACIÓN
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

local FT = LockLang["ES"]

local function _reloadFT()
    local lang = "ES"
    pcall(function()
        local data = readfile("AllForOne/lang.txt")
        if data == "EN" or data == "ES" then lang = data end
    end)
    FT = LockLang[lang]
end

_reloadFT()

-- ──────────────────────────────────────────────────────────────────
-- [3]  ESTADO INTERNO (L)
-- ──────────────────────────────────────────────────────────────────
local LOCK_ROTATION_SMOOTH = 1.0
local SOFTAIM_BODY_SMOOTH  = 1.0
local LOCK_ICON_ID         = "rbxassetid://82817965256191"

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
    lockRenderConn = nil,

    lockCameraLerp = 0.18,
    softBodyRotation = true,
}

local lplr   = nil
local camera = nil

-- ──────────────────────────────────────────────────────────────────
-- PROVEEDOR DE OMNIBLOCK
-- ──────────────────────────────────────────────────────────────────
local isOmniBlockActiveFn = function() return false end

local function isOmniActive()
    local ok, res = pcall(isOmniBlockActiveFn)
    return ok and res == true
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
    if L.lockIconGui then
        pcall(function() L.lockIconGui:Destroy() end)
        L.lockIconGui = nil
    end
end

local function applyLockIcon(player)
    if not L.systemEnabled or not L.lockActive or player ~= L.lockedTarget then return end
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
        end
    end)
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
        local ok, playerGui = pcall(function() return lplr.PlayerGui end)
        screenGui.Parent = (ok and playerGui) or game:GetService("CoreGui")
        L.ownScreenGui   = screenGui
        parent           = screenGui
    end

    local C_PURPLE = Color3.fromRGB(110, 30, 180)
    local C_BLACK  = Color3.fromRGB(6, 4, 12)
    local C_TEXT   = Color3.fromRGB(220, 190, 255)

    local infoFrame = Instance.new("Frame")
    infoFrame.Name                  = "LockInfoPanel"
    infoFrame.Size                  = UDim2.new(0, 220, 0, 95)
    infoFrame.Position              = UDim2.new(1, -232, 0, 80)
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

    local nameLabel = Instance.new("TextLabel", infoFrame)
    nameLabel.Name               = "NameLabel"
    nameLabel.Size               = UDim2.new(0, 120, 0, 20)
    nameLabel.Position           = UDim2.new(0, 40, 0, 6)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Font               = Enum.Font.GothamBold
    nameLabel.TextSize           = 12
    nameLabel.TextColor3         = C_TEXT
    nameLabel.Text               = "---"
    nameLabel.TextXAlignment     = Enum.TextXAlignment.Left

    local distLabel = Instance.new("TextLabel", infoFrame)
    distLabel.Name               = "DistLabel"
    distLabel.Size               = UDim2.new(0, 120, 0, 18)
    distLabel.Position           = UDim2.new(0, 40, 0, 28)
    distLabel.BackgroundTransparency = 1
    distLabel.Font               = Enum.Font.Gotham
    distLabel.TextSize           = 10
    distLabel.TextColor3         = Color3.fromRGB(200, 170, 255)
    distLabel.Text               = "--- studs"
    distLabel.TextXAlignment     = Enum.TextXAlignment.Left

    local healthLabel = Instance.new("TextLabel", infoFrame)
    healthLabel.Name             = "HealthLabel"
    healthLabel.Size             = UDim2.new(0, 120, 0, 18)
    healthLabel.Position         = UDim2.new(0, 40, 0, 48)
    healthLabel.BackgroundTransparency = 1
    healthLabel.Font             = Enum.Font.Legacy
    healthLabel.TextSize         = 10
    healthLabel.TextColor3       = Color3.fromRGB(255, 150, 150)
    healthLabel.Text             = "❤️ ---"
    healthLabel.TextXAlignment   = Enum.TextXAlignment.Left

    local heightLabel = Instance.new("TextLabel", infoFrame)
    heightLabel.Name             = "HeightLabel"
    heightLabel.Size             = UDim2.new(0, 120, 0, 15)
    heightLabel.Position         = UDim2.new(0, 40, 0, 68)
    heightLabel.BackgroundTransparency = 1
    healthLabel.Font             = Enum.Font.Gotham
    heightLabel.TextSize         = 9
    heightLabel.TextColor3       = Color3.fromRGB(150, 220, 255)
    heightLabel.Text             = "---"
    heightLabel.TextXAlignment   = Enum.TextXAlignment.Left

    local playerImgContainer = Instance.new("Frame", infoFrame)
    playerImgContainer.Name               = "PlayerImgContainer"
    playerImgContainer.Size               = UDim2.new(0, 55, 0, 55)
    playerImgContainer.Position           = UDim2.new(1, -65, 0, 20)
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
    L.avatarRequestId += 1
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
            heightLabel.Text      = "▼ " .. heightDiff .. " " .. FT.height_below
            heightLabel.TextColor3 = Color3.fromRGB(150, 220, 255)
        elseif heightDiff < 0 then
            heightLabel.Text      = "▲ " .. math.abs(heightDiff) .. " " .. FT.height_above
            heightLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
        else
            heightLabel.Text      = "● " .. FT.height_same
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
    if not targetChar then clearLock(); return end
    if not isTargetValidForLock(L.lockedTarget) then clearLock(); return end

    local myChar     = lplr and lplr.Character
    local myRoot     = myChar and myChar:FindFirstChild("HumanoidRootPart")
    
    local targetPart = targetChar:FindFirstChild("UpperTorso")
        or targetChar:FindFirstChild("HumanoidRootPart")
    if not targetPart then return end
    if not camera then return end

    local worldDist = myRoot and (myRoot.Position - targetPart.Position).Magnitude or 999
    if isnan(worldDist) then worldDist = 999 end

    local currentPos = camera.CFrame.Position
    local lerpFactor = L.lockCameraLerp
    if worldDist < 8  then lerpFactor = lerpFactor * 0.25
    elseif worldDist < 20 then lerpFactor = lerpFactor * 0.6 end
    lerpFactor = math.clamp(lerpFactor, 0, 1)

    local omniOn = isOmniActive()

    if omniOn then
        return
    end

    local desiredCF = CFrame.new(currentPos, targetPart.Position)
    pcall(function() camera.CFrame = camera.CFrame:Lerp(desiredCF, lerpFactor) end)
end

-- ──────────────────────────────────────────────────────────────────
-- [7b] GIRO SUAVE DEL HRP
-- ──────────────────────────────────────────────────────────────────
local function updateSoftBodyRotation()
    if not L.softBodyRotation then return end
    if isOmniActive() then return end
    if not L.lockActive or not L.lockedTarget then return end
    
    local tChar = L.lockedTarget.Character
    if not tChar or not isTargetValidForLock(L.lockedTarget) then return end
    
    local myChar = lplr and lplr.Character
    local hrp    = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local aimPart = tChar:FindFirstChild("UpperTorso")
        or tChar:FindFirstChild("HumanoidRootPart")
    if not aimPart then return end
    
    local lookTarget = Vector3.new(aimPart.Position.X, hrp.Position.Y, aimPart.Position.Z)
    if (lookTarget - hrp.Position).Magnitude <= 0.1 then return end
    
    local _, curYaw, _ = hrp.CFrame:ToEulerAnglesYXZ()
    local _, tarYaw, _ = CFrame.lookAt(hrp.Position, lookTarget):ToEulerAnglesYXZ()
    local diff = tarYaw - curYaw
    if diff >  math.pi then diff = diff - 2 * math.pi end
    if diff < -math.pi then diff = diff + 2 * math.pi end
    
    local savedVel = hrp.AssemblyLinearVelocity
    pcall(function()
        hrp.CFrame = CFrame.new(hrp.Position)
            * CFrame.Angles(0, curYaw + diff * SOFTAIM_BODY_SMOOTH, 0)
        hrp.AssemblyLinearVelocity = savedVel
    end)
end

-- ──────────────────────────────────────────────────────────────────
-- [8]  TOGGLE / START / STOP
-- ──────────────────────────────────────────────────────────────────
local function toggleLock()
    if not L.systemEnabled then return end

    if not L.lockActive then
        local found = getClosestLockTarget()
        if found and isTargetValidForLock(found) then
            L.lockedTarget = found
            L.lockActive   = true
            applyLockIcon(found)
            updateLockHighlight()
            createLockInfoGui(L.infoGuiParent)
            loadAvatarImage()
        end
    else
        clearLock()
    end
end

local function startLockSystem()
    if L.lockConn then L.lockConn:Disconnect(); L.lockConn = nil end
    if L.lockRenderConn then L.lockRenderConn:Disconnect(); L.lockRenderConn = nil end

    L.lockConn = UserInputService.InputBegan:Connect(function(input, gpe)
        if not L.systemEnabled or gpe or isTyping() then return end
        if input.KeyCode == L.lockKey then toggleLock() end
    end)

    L.lockRenderConn = RunService.RenderStepped:Connect(function()
        if not L.systemEnabled then return end
        updateLockInfoGui()
        updateLockCamera()
        updateLockHighlight()
        updateSoftBodyRotation()
    end)
end

local function stopLockSystem()
    L.systemEnabled = false
    L.avatarRequestId += 1
    if L.lockConn       then L.lockConn:Disconnect();       L.lockConn       = nil end
    if L.lockRenderConn then L.lockRenderConn:Disconnect(); L.lockRenderConn = nil end
    clearLock()
    if L.lockHighlight then
        pcall(function() L.lockHighlight:Destroy() end)
        L.lockHighlight = nil
    end
end

-- ──────────────────────────────────────────────────────────────────
-- [9]  GUI EMBEBIBLE — sección "LOCK"
-- ──────────────────────────────────────────────────────────────────
local HUD_SECTION_HEIGHT = 38

local function buildHUDLockSection(expandZone, makeSection, makeRow, colors)
    local C_SEC1, C_ACCENT, C_GOLD, C_TEXT, C_SUBTEXT =
        colors.SEC1, colors.ACCENT, colors.GOLD, colors.TEXT, colors.SUBTEXT

    local lockSec = makeSection(HUD_SECTION_HEIGHT, C_SEC1, C_ACCENT)
    lockSec.Parent = expandZone

    local ROW_H   = 22
    local lockRow = makeRow(lockSec, (HUD_SECTION_HEIGHT - ROW_H) / 2)

    local lockIconEmoji = Instance.new("TextLabel", lockRow)
    lockIconEmoji.Size               = UDim2.new(0, 18, 1, 0)
    lockIconEmoji.Position           = UDim2.new(0, 0, 0, 0)
    lockIconEmoji.BackgroundTransparency = 1
    lockIconEmoji.Font               = Enum.Font.Legacy
    lockIconEmoji.TextSize           = 11
    lockIconEmoji.TextColor3         = C_GOLD
    lockIconEmoji.Text               = "🎯"
    lockIconEmoji.TextXAlignment     = Enum.TextXAlignment.Center
    lockIconEmoji.TextYAlignment     = Enum.TextYAlignment.Center

    local lockLabel = Instance.new("TextLabel", lockRow)
    lockLabel.Size               = UDim2.new(0, 100, 1, 0)
    lockLabel.Position           = UDim2.new(0, 22, 0, 0)
    lockLabel.BackgroundTransparency = 1
    lockLabel.Font               = Enum.Font.GothamBold
    lockLabel.TextSize           = 11
    lockLabel.TextColor3         = C_TEXT
    lockLabel.Text               = FT.lock_label .. "  [" .. L.lockKey.Name .. "]"
    lockLabel.TextXAlignment     = Enum.TextXAlignment.Left
    lockLabel.TextYAlignment     = Enum.TextYAlignment.Center

    local lockHint = Instance.new("TextLabel", lockRow)
    lockHint.Size               = UDim2.new(1, -128, 1, 0)
    lockHint.Position           = UDim2.new(0, 124, 0, 0)
    lockHint.BackgroundTransparency = 1
    lockHint.Font               = Enum.Font.Gotham
    lockHint.TextSize           = 9
    lockHint.TextColor3         = C_SUBTEXT
    lockHint.Text               = FT.lock_hint_prefix .. L.lockKey.Name
    lockHint.TextXAlignment     = Enum.TextXAlignment.Right
    lockHint.TextYAlignment     = Enum.TextYAlignment.Center

    L.lockLabels = { label = lockLabel, hint = lockHint }
    return lockSec
end

-- ──────────────────────────────────────────────────────────────────
-- [10] API PÚBLICA
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
    if not M.IsLockActive() then return nil end
    local myChar = lplr and lplr.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local tChar  = L.lockedTarget.Character
    local tRoot  = tChar and tChar:FindFirstChild("HumanoidRootPart")
    if not myRoot or not tRoot then return nil end
    local dist = (myRoot.Position - tRoot.Position).Magnitude
    if isnan(dist) then return nil end
    return dist
end

function M.GetStatus()
    local active = M.IsLockActive()
    local health, maxHealth = M.GetTargetHealth()
    return {
        lockActive = active,
        target     = active and L.lockedTarget or nil,
        targetName = active and L.lockedTarget.Name or nil,
        health     = health,
        maxHealth  = maxHealth,
        distance   = M.GetTargetDistance(),
    }
end

function M.SetOmniBlockProvider(fn)
    if type(fn) == "function" then
        isOmniBlockActiveFn = fn
    end
end

function M.IsOmniBlockActive()
    return isOmniActive()
end

function M.SetPreTeleportHeightCallback(fn)
    L.onPreTeleportHeight = fn
end

function M.SetSoftBodyRotation(enabled)
    L.softBodyRotation = (enabled == true or enabled == nil)
end
function M.GetSoftBodyRotation() return L.softBodyRotation end

M.CreateInfoGui = function(parentFrame)
    if L.systemEnabled and L.lockActive and L.lockedTarget then
        createLockInfoGui(parentFrame)
    end
end

M.DestroyInfoGui     = destroyLockInfoGui
M.BuildHUDLockSection = buildHUDLockSection
M.HUD_SECTION_HEIGHT  = HUD_SECTION_HEIGHT

return M
