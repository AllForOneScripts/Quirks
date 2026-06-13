--[[
╔══════════════════════════════════════════════════════════════════════════════╗
║                    LOCK SYSTEM  ·  ModuleScript                              ║
║  Versión modular de lock.lua (inline AllForOne / Power)                      ║
║  Uso:  local LockSystem = require(path.LockSystem)                           ║
║        LockSystem.Init(deps)   -- pasar dependencias una sola vez            ║
║        LockSystem.Start()      -- arranca B1-B4                              ║
║        LockSystem.Stop()       -- para y limpia todo                         ║
║        LockSystem.SetKey(kc)   -- cambia flyanim.lockKey                     ║
║        LockSystem.IsLockActive() → bool                                      ║
╚══════════════════════════════════════════════════════════════════════════════╝
--]]

local M = {}

-- ─────────────────────────────────────────────────────────────────────────────
-- ESTADO INTERNO
-- ─────────────────────────────────────────────────────────────────────────────

-- Dependencias (se rellenan en M.Init)
local lplr, camera, flyanim, flyModule
local isnan, safepos, isTyping, isTargetValidForLock
local FT, LOCK_ROTATION_SMOOTH
local Players, RunService, UserInputService

-- Conexiones propias del módulo
local _lockConn        = nil
local _lockRenderConn  = nil
local _brakeConn       = nil
local _activeHitboxMarkers = {}


-- ─────────────────────────────────────────────────────────────────────────────
-- M.Init  — inyección de dependencias
-- ─────────────────────────────────────────────────────────────────────────────

function M.Init(deps)
    lplr                  = deps.lplr
    camera                = deps.camera
    flyanim               = deps.flyanim
    flyModule             = deps.flyModule          -- puede ser nil al inicio
    isnan                 = deps.isnan
    safepos               = deps.safepos
    isTyping              = deps.isTyping
    isTargetValidForLock  = deps.isTargetValidForLock
    FT                    = deps.FT
    LOCK_ROTATION_SMOOTH  = deps.LOCK_ROTATION_SMOOTH
    Players               = deps.Players or game:GetService("Players")
    RunService            = deps.RunService or game:GetService("RunService")
    UserInputService      = deps.UserInputService or game:GetService("UserInputService")
end

-- Permite actualizar flyModule después de que se cargue
function M.SetFlyModule(fm)
    flyModule = fm
end


-- ─────────────────────────────────────────────────────────────────────────────
-- [B1] MOVIMIENTO DE CÁMARA, PERSONAJE E INCLINACIÓN
-- ─────────────────────────────────────────────────────────────────────────────

-- Devuelve el jugador más cercano al cursor (≤300px pantalla, ≤750 studs).
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

-- Lerp suave de cámara hacia el target. Factor se reduce a distancias cortas
-- para evitar temblor (<8 studs → ×0.25, <20 studs → ×0.6).
local function updateLockCamera()
    if not flyanim.lockActive or not flyanim.lockedTarget then return end
    local targetChar = flyanim.lockedTarget.Character
    if not targetChar then
        flyanim.lockActive = false; flyanim.lockedTarget = nil
        M._removeLockIcon(); M._updateLockHighlight()
        return
    end
    if not isTargetValidForLock(flyanim.lockedTarget) then
        flyanim.lockActive = false; flyanim.lockedTarget = nil
        M._removeLockIcon(); M._updateLockHighlight()
        return
    end
    local myChar     = lplr and lplr.Character
    local myRoot     = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
    if myRoot and targetRoot then
        local d = (myRoot.Position - targetRoot.Position).Magnitude
        if not isnan(d) and d > 750 then
            flyanim.lockActive = false; flyanim.lockedTarget = nil
            M._removeLockIcon(); M._updateLockHighlight()
            return
        end
    end
    local targetPart = targetChar:FindFirstChild("UpperTorso") or targetChar:FindFirstChild("HumanoidRootPart")
    if not targetPart then return end
    if not camera then return end
    local worldDist  = myRoot and (myRoot.Position - targetPart.Position).Magnitude or 999
    if isnan(worldDist) then worldDist = 999 end
    local currentPos = camera.CFrame.Position
    local desiredCF  = CFrame.new(currentPos, targetPart.Position)
    local lerpFactor = flyanim.lockCameraLerp
    if worldDist < 8  then lerpFactor = lerpFactor * 0.25
    elseif worldDist < 20 then lerpFactor = lerpFactor * 0.6 end
    lerpFactor = math.clamp(lerpFactor, 0, 1)
    pcall(function() camera.CFrame = camera.CFrame:Lerp(desiredCF, lerpFactor) end)
end

-- Alterna lock on/off. Al activar busca el target más cercano al cursor.
local function toggleLock()
    if not flyanim.enabled then return end
    if not flyanim.lockActive then
        local found = getClosestLockTarget()
        if found and isTargetValidForLock(found) then
            flyanim.lockedTarget = found
            flyanim.lockActive   = true
            M._applyLockIcon(found)
            M._updateLockHighlight()
            M._loadAvatarImage()
        end
    else
        flyanim.lockActive   = false
        flyanim.lockedTarget = nil
        M._removeLockIcon()
        M._updateLockHighlight()
    end
end


-- ─────────────────────────────────────────────────────────────────────────────
-- [B2] VISUALES, GUI Y LECTORES
-- ─────────────────────────────────────────────────────────────────────────────

function M._removeLockIcon()
    if flyanim.lockIconGui then
        pcall(function() flyanim.lockIconGui:Destroy() end)
        flyanim.lockIconGui = nil
    end
end

function M._applyLockIcon(player)
    M._removeLockIcon()
    local chest = player.Character and player.Character:FindFirstChild("UpperTorso")
    local torso = chest or (player.Character and player.Character:FindFirstChild("HumanoidRootPart"))
    if not torso then return end
    flyanim.lockIconGui             = Instance.new("BillboardGui", torso)
    flyanim.lockIconGui.Name        = "LockIcon"
    flyanim.lockIconGui.Size        = UDim2.new(0, 50, 0, 50)
    flyanim.lockIconGui.AlwaysOnTop = true
    flyanim.lockIconGui.StudsOffset = Vector3.new(0, 0, 0)
    local img = Instance.new("ImageLabel", flyanim.lockIconGui)
    img.Size                   = UDim2.new(1, 0, 1, 0)
    img.BackgroundTransparency = 1
    img.Image                  = "rbxassetid://82817965256191"
    img.ImageColor3            = Color3.fromRGB(255, 255, 255)
    img.ScaleType              = Enum.ScaleType.Fit
end

local function ensureLockHighlight()
    if not flyanim.lockHighlight then
        flyanim.lockHighlight                     = Instance.new("Highlight")
        flyanim.lockHighlight.FillTransparency    = 1
        flyanim.lockHighlight.OutlineColor        = Color3.fromRGB(255, 255, 255)
        flyanim.lockHighlight.OutlineTransparency = 0
    end
end

function M._updateLockHighlight()
    if not flyanim.lockActive or not flyanim.lockedTarget then
        if flyanim.lockHighlight then flyanim.lockHighlight.Parent = nil end
        return
    end
    if not isTargetValidForLock(flyanim.lockedTarget) then
        if flyanim.lockHighlight then flyanim.lockHighlight.Parent = nil end
        return
    end
    ensureLockHighlight()
    local targetChar = flyanim.lockedTarget.Character
    if targetChar then flyanim.lockHighlight.Parent = targetChar
    else               flyanim.lockHighlight.Parent = nil end
end

function M._loadAvatarImage()
    if not flyanim.lockInfoGui then return end
    local playerImg = flyanim.lockInfoGui:FindFirstChild("PlayerImage", true)
    if not playerImg then return end
    if flyanim.lockActive and flyanim.lockedTarget then
        local userId = flyanim.lockedTarget.UserId
        task.spawn(function()
            local success, content = pcall(function()
                return Players:GetUserThumbnailAsync(
                    userId,
                    Enum.ThumbnailType.AvatarBust,
                    Enum.ThumbnailSize.Size420x420
                )
            end)
            if success and content and playerImg and playerImg.Parent then
                playerImg.Image = content
            end
        end)
    end
end

function M.CreateLockInfoGui(parentFrame)
    if flyanim.lockInfoGui then
        pcall(function() flyanim.lockInfoGui:Destroy() end)
        flyanim.lockInfoGui = nil
    end
    local C_PURPLE = Color3.fromRGB(110, 30, 180)
    local C_BLACK  = Color3.fromRGB(6, 4, 12)
    local C_TEXT   = Color3.fromRGB(220, 190, 255)

    local infoFrame = Instance.new("Frame")
    infoFrame.Name                   = "LockInfoPanel"
    infoFrame.Size                   = UDim2.new(0, 220, 0, 95)
    infoFrame.Position               = UDim2.new(1, 12, 0, 8)
    infoFrame.BackgroundColor3       = C_BLACK
    infoFrame.BackgroundTransparency = 0.15
    infoFrame.BorderSizePixel        = 0
    infoFrame.ZIndex                 = 10
    infoFrame.Visible                = false
    infoFrame.Parent                 = parentFrame
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
    nameLabel.TextSize=12; nameLabel.TextColor3=C_TEXT; nameLabel.Text="---"
    nameLabel.TextXAlignment=Enum.TextXAlignment.Left

    local distLabel = Instance.new("TextLabel", infoFrame)
    distLabel.Name="DistLabel"; distLabel.Size=UDim2.new(0,120,0,18); distLabel.Position=UDim2.new(0,40,0,28)
    distLabel.BackgroundTransparency=1; distLabel.Font=Enum.Font.Gotham
    distLabel.TextSize=10; distLabel.TextColor3=Color3.fromRGB(200,170,255)
    distLabel.Text="--- studs"; distLabel.TextXAlignment=Enum.TextXAlignment.Left

    local healthLabel = Instance.new("TextLabel", infoFrame)
    healthLabel.Name="HealthLabel"; healthLabel.Size=UDim2.new(0,120,0,18); healthLabel.Position=UDim2.new(0,40,0,48)
    healthLabel.BackgroundTransparency=1; healthLabel.Font=Enum.Font.Legacy
    healthLabel.TextSize=10; healthLabel.TextColor3=Color3.fromRGB(255,150,150)
    healthLabel.Text="❤️ ---"; healthLabel.TextXAlignment=Enum.TextXAlignment.Left

    local heightLabel = Instance.new("TextLabel", infoFrame)
    heightLabel.Name="HeightLabel"; heightLabel.Size=UDim2.new(0,120,0,15); heightLabel.Position=UDim2.new(0,40,0,68)
    heightLabel.BackgroundTransparency=1; heightLabel.Font=Enum.Font.Gotham
    heightLabel.TextSize=9; heightLabel.TextColor3=Color3.fromRGB(150,220,255)
    heightLabel.Text="---"; heightLabel.TextXAlignment=Enum.TextXAlignment.Left

    local playerImgContainer = Instance.new("Frame", infoFrame)
    playerImgContainer.Name="PlayerImgContainer"; playerImgContainer.Size=UDim2.new(0,55,0,55)
    playerImgContainer.Position=UDim2.new(1,-65,0,20)
    playerImgContainer.BackgroundColor3=Color3.fromRGB(20,10,40)
    playerImgContainer.BackgroundTransparency=0.3
    playerImgContainer.BorderSizePixel=0; playerImgContainer.ZIndex=11
    Instance.new("UICorner", playerImgContainer).CornerRadius = UDim.new(1, 0)

    local playerImg = Instance.new("ImageLabel", playerImgContainer)
    playerImg.Name="PlayerImage"; playerImg.Size=UDim2.new(1,0,1,0); playerImg.Position=UDim2.new(0,0,0,0)
    playerImg.BackgroundTransparency=1; playerImg.Image=""; playerImg.ZIndex=12
    Instance.new("UICorner", playerImg).CornerRadius = UDim.new(1, 0)

    flyanim.lockInfoGui = infoFrame
end

-- Actualiza el panel de info en cada RenderStepped.
-- Incluye el TP "estar abajo de" (condicionado al fly activo, Parche A-1).
local function updateLockInfoGui()
    if not flyanim.lockInfoGui then return end
    if not flyanim.lockActive or not flyanim.lockedTarget
    or not flyanim.lockedTarget.Character
    or not isTargetValidForLock(flyanim.lockedTarget) then
        flyanim.lockInfoGui.Visible = false
        if flyanim.lockActive and flyanim.lockedTarget
           and not isTargetValidForLock(flyanim.lockedTarget) then
            flyanim.lockActive   = false
            flyanim.lockedTarget = nil
            M._removeLockIcon()
            M._updateLockHighlight()
        end
        return
    end

    flyanim.lockInfoGui.Visible = true
    local root     = flyanim.lockedTarget.Character:FindFirstChild("HumanoidRootPart")
    local humanoid = flyanim.lockedTarget.Character:FindFirstChildOfClass("Humanoid")
    local myChar   = lplr and lplr.Character
    local myRoot   = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local dist = camera and (camera.CFrame.Position - root.Position).Magnitude or 0
    if isnan(dist) then dist = 0 end
    local displayName = flyanim.lockedTarget.DisplayName or "?"
    if #displayName > 14 then displayName = displayName:sub(1, 12) .. ".." end
    local nameLabel = flyanim.lockInfoGui:FindFirstChild("NameLabel")
    if nameLabel then nameLabel.Text = displayName end
    local distLabel = flyanim.lockInfoGui:FindFirstChild("DistLabel")
    if distLabel then distLabel.Text = math.floor(dist) .. " studs" end

    local healthLabel = flyanim.lockInfoGui:FindFirstChild("HealthLabel")
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
        if rawHealth <= 0 then        heartEmoji = "☠️"
        elseif pct > 0.75 then        heartEmoji = "💚"
        elseif pct > 0.50 then        heartEmoji = "💛"
        elseif pct > 0.25 then        heartEmoji = "🧡"
        else                          heartEmoji = "❤️" end
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

    local heightLabel = flyanim.lockInfoGui:FindFirstChild("HeightLabel")
    if heightLabel and myRoot then
        local heightDiff = math.floor(myRoot.Position.Y - root.Position.Y)
        if isnan(heightDiff) then heightDiff = 0 end
        if heightDiff > 0 then
            heightLabel.Text       = "▼ " .. heightDiff .. " " .. FT.height_below
            heightLabel.TextColor3 = Color3.fromRGB(150, 220, 255)
        elseif heightDiff < 0 then
            heightLabel.Text       = "▲ " .. math.abs(heightDiff) .. " " .. FT.height_above
            heightLabel.TextColor3 = Color3.fromRGB(255, 200, 100)

            -- TP "estar abajo de" — solo cuando el fly está activo (Parche A-1)
            if flyanim.enabled
               and flyModule and flyModule.IsEnabled and flyModule.IsEnabled()
               and math.abs(heightDiff) >= 15 then
                local toTargetH = Vector3.new(
                    root.Position.X - myRoot.Position.X, 0,
                    root.Position.Z - myRoot.Position.Z
                )
                local behindDir = toTargetH.Magnitude > 0.1 and -toTargetH.Unit or Vector3.new(0, 0, 1)
                local tpPos     = root.Position + behindDir * 3
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
                    if preTPHeight > (flyanim.maxHeightAboveGround or 0) then
                        flyanim.maxHeightAboveGround = preTPHeight
                    end
                end
            end
        else
            heightLabel.Text       = "● " .. FT.height_same
            heightLabel.TextColor3 = Color3.fromRGB(150, 255, 150)
        end
    end

    M._loadAvatarImage()
end


-- ─────────────────────────────────────────────────────────────────────────────
-- [B3] SISTEMA DE FRENO
-- ─────────────────────────────────────────────────────────────────────────────

local function clearHitboxMarkers()
    for _, marker in ipairs(_activeHitboxMarkers) do
        pcall(function() marker:Destroy() end)
    end
    _activeHitboxMarkers = {}
end

local function showHitboxMarkers(targetChar)
    clearHitboxMarkers()
    if not targetChar then return end
    local box = Instance.new("SelectionBox")
    box.Adornee       = targetChar
    box.Color3        = Color3.fromRGB(255, 150, 50)
    box.Transparency  = 0.5
    box.LineThickness = 0.1
    box.Parent        = targetChar
    table.insert(_activeHitboxMarkers, box)
    task.delay(0.6, clearHitboxMarkers)
end

local function startBrakeSystem()
    if _brakeConn then _brakeConn:Disconnect(); _brakeConn = nil end
    local myBrakeSession = flyanim.sessionToken
    _brakeConn = RunService.RenderStepped:Connect(function()
        if flyanim.sessionToken ~= myBrakeSession then
            if _brakeConn then _brakeConn:Disconnect(); _brakeConn = nil end
            return
        end
        if not flyanim.enabled then return end
        if flyanim.mode ~= "fast" and flyanim.mode ~= "turbo" then return end
        if not flyanim.lockActive or not flyanim.lockedTarget then return end
        if flyanim.dashTimer <= 0 then return end

        local char   = lplr and lplr.Character
        local myRoot = char and char:FindFirstChild("HumanoidRootPart")
        if not myRoot then return end

        local targetChar = flyanim.lockedTarget.Character
        local targetRoot = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
        if not targetRoot then return end

        local dist = (myRoot.Position - targetRoot.Position).Magnitude
        if isnan(dist) then return end

        if dist <= flyanim.BRAKE_HARD_DISTANCE then
            flyanim.dashVel       = Vector3.new(0, 0, 0)
            flyanim.dashTimer     = 0
            flyanim.brakingActive = false
            showHitboxMarkers(targetChar)
        elseif dist <= flyanim.BRAKE_DISTANCE then
            local t           = 1 - ((dist - flyanim.BRAKE_HARD_DISTANCE) / (flyanim.BRAKE_DISTANCE - flyanim.BRAKE_HARD_DISTANCE))
            local brakeFactor = 1 - (t * 0.92)
            flyanim.dashVel       = flyanim.dashVel * math.max(brakeFactor, 0.05)
            flyanim.brakingActive = true
        else
            flyanim.brakingActive = false
        end
    end)
end

local function stopBrakeSystem()
    if _brakeConn then _brakeConn:Disconnect(); _brakeConn = nil end
    flyanim.brakingActive = false
    clearHitboxMarkers()
end


-- ─────────────────────────────────────────────────────────────────────────────
-- [B4] TECLAS  +  API PÚBLICA
-- ─────────────────────────────────────────────────────────────────────────────

-- Arranca: tecla de lock + RenderStepped de cámara/info + sistema de freno.
function M.Start()
    _lockConn = UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe or isTyping() then return end
        if input.KeyCode == flyanim.lockKey then
            toggleLock()
        end
    end)

    _lockRenderConn = RunService.RenderStepped:Connect(function()
        if not flyanim.enabled then return end
        updateLockInfoGui()
        updateLockCamera()
        M._updateLockHighlight()
    end)

    -- Conexiones guardadas también en flyanim para compatibilidad con código externo
    flyanim.lockConn       = _lockConn
    flyanim.lockRenderConn = _lockRenderConn

    startBrakeSystem()
end

-- Para todo y limpia estado.
function M.Stop()
    if _lockConn       then _lockConn:Disconnect();       _lockConn       = nil end
    if _lockRenderConn then _lockRenderConn:Disconnect(); _lockRenderConn = nil end
    flyanim.lockConn       = nil
    flyanim.lockRenderConn = nil
    flyanim.lockActive     = false
    flyanim.lockedTarget   = nil
    M._removeLockIcon()
    M._updateLockHighlight()
    if flyanim.lockInfoGui   then pcall(function() flyanim.lockInfoGui:Destroy()   end); flyanim.lockInfoGui   = nil end
    if flyanim.lockHighlight then pcall(function() flyanim.lockHighlight:Destroy() end); flyanim.lockHighlight = nil end
    stopBrakeSystem()
end

-- Cambia la tecla de toggle del lock en caliente.
function M.SetKey(keyCode)
    flyanim.lockKey = keyCode
end

-- Devuelve si el lock está activo en este momento.
function M.IsLockActive()
    return flyanim.lockActive == true
end


return M
