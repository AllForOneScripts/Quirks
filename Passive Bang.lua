local M = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local _lplr
local _mouse
local _camera = workspace.CurrentCamera
local _conns = {}
local _captureConn
local _capturing = false
local _bangKey = Enum.KeyCode.Quote
local _holding = false
local _latched = false
local _lockedMode = false
local _targetHRP
local _targetPlayer
local _leftDown = false
local _rightDown = false
local _rescore = 0

local _dropTargetRoot
local _dropStickUntil = 0
local _dropCompletedFor
local _dropCompletedAt = 0

local PB = {
    MAX_3D_DIST = 150,
    MAX_ENGAGED_DIST = 250,
    W_PROXIMITY = 7.0,
    W_MOUSE = 3.0,
    MAX_SCREEN_DIST_MOUSE = 350,
    W_CONTINUITY = 2.0,
    RESCORE_INTERVAL = 12,
    CAMERA_SMOOTH = 1,

    BEHIND_DISTANCE = 2.8,
    HEIGHT_OFFSET = 0,
    PREDICT_MIN_TIME = 0.03,
    PREDICT_MAX_TIME = 0.12,
    PREDICT_MAX_DIST = 4,
    PREDICT_MAX_FALL = 3,
    MAX_SANE_SPEED = 70,

    FALL_TRIGGER_HEIGHT = 20,
    FALL_LAND_HEIGHT = 4,
    FALL_HEAD_STICK_TIME = 0.22,
    FALL_STICK_VELOCITY = -20,
    FALL_RELEASE_VELOCITY = -140,
    FALL_HITBOX_VERTICAL_REACH = 3,
    FALL_GROUND_SAFETY_MARGIN = 0.75,
    FALL_HEAD_HEIGHT_ADJUSTMENT = -3.5,
}

local function env()
    if type(getgenv) == "function" then
        local ok, e = pcall(getgenv)
        if ok and type(e) == "table" then return e end
    end
    return _G
end

local function isSafeVector(v)
    return v.X == v.X and v.Y == v.Y and v.Z == v.Z
        and math.abs(v.X) < 1e5 and math.abs(v.Y) < 1e5 and math.abs(v.Z) < 1e5
end

local function resetDrop()
    _dropTargetRoot = nil
    _dropStickUntil = 0
    _dropCompletedFor = nil
    _dropCompletedAt = 0
end

local function resetTarget()
    _targetHRP = nil
    _targetPlayer = nil
    _lockedMode = false
    _rescore = PB.RESCORE_INTERVAL
    resetDrop()
end

local function updateCharacter()
    _holding = false
    _latched = false
    resetTarget()
end

local function getLiveRoot(player)
    if not player or player == _lplr then return nil end
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not root or not hum or hum.Health <= 0 then return nil end
    return root, hum
end

local function scoreCandidate(player, myRoot, mouseX, mouseY)
    local root = getLiveRoot(player)
    if not root or not isSafeVector(root.Position) then return nil end

    local distance = (root.Position - myRoot.Position).Magnitude
    local isCurrent = root == _targetHRP
    if distance > (isCurrent and PB.MAX_ENGAGED_DIST or PB.MAX_3D_DIST) then return nil end

    local proximity = PB.W_PROXIMITY * (1 - math.clamp(distance / PB.MAX_3D_DIST, 0, 1))
    local mouseScore = 0
    _camera = workspace.CurrentCamera or _camera
    local screenPos, onScreen = _camera:WorldToViewportPoint(root.Position)
    if onScreen then
        local screenDistance = Vector2.new(mouseX - screenPos.X, mouseY - screenPos.Y).Magnitude
        if screenDistance <= PB.MAX_SCREEN_DIST_MOUSE then
            mouseScore = PB.W_MOUSE * (1 - screenDistance / PB.MAX_SCREEN_DIST_MOUSE)
        end
    end

    return proximity + mouseScore + (isCurrent and PB.W_CONTINUITY or 0), root, player
end

local function selectPassiveTarget(myRoot)
    _mouse = _mouse or _lplr:GetMouse()
    local bestScore, bestRoot, bestPlayer = -math.huge, nil, nil

    for _, candidate in ipairs(Players:GetPlayers()) do
        local score, root, player = scoreCandidate(candidate, myRoot, _mouse.X, _mouse.Y)
        if score and score > bestScore then
            bestScore, bestRoot, bestPlayer = score, root, player
        end
    end
    return bestRoot, bestPlayer
end

local function resolveTargetValue(val)
    if not val then return nil, nil end

    if typeof(val) == "Instance" then
        if val:IsA("Player") then
            return val, (getLiveRoot(val))
        elseif val:IsA("Model") then
            local plr = Players:GetPlayerFromCharacter(val)
            return plr, (getLiveRoot(plr))
        elseif val:IsA("BasePart") then
            local model = val:FindFirstAncestorOfClass("Model")
            local plr = model and Players:GetPlayerFromCharacter(model)
            return plr, (getLiveRoot(plr))
        end
    elseif type(val) == "string" then
        local name = (val:gsub("^@", "")):lower()
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Name:lower() == name or p.DisplayName:lower() == name then
                return p, (getLiveRoot(p))
            end
        end
    elseif type(val) == "table" then
        local nested = val.player or val.targetPlayer or val.character or val.targetCharacter
            or val.root or val.targetRoot or val.target
        return resolveTargetValue(nested)
    end

    return nil, nil
end

local function readLock()
    local char = _lplr and _lplr.Character
    if char then
        local activeVal = char:FindFirstChild("AFO_LockActive")
        local targetVal = char:FindFirstChild("AFO_LockedTarget")
        if activeVal and targetVal then
            return activeVal.Value == true, targetVal.Value
        end
    end

    local api = rawget(env(), "AFO_LOCK_API")
    if type(api) == "table" and type(api.GetStatus) == "function" then
        local ok, status = pcall(api.GetStatus)
        if ok and type(status) == "table" then
            local target = status.target or status.targetPlayer or status.targetCharacter or status.targetName
            if type(api.GetTarget) == "function" then
                local ok2, target2 = pcall(api.GetTarget)
                if ok2 and target2 then target = target2 end
            end
            return status.lockActive == true, target
        end
    end

    return false, nil
end

local function getPing()
    local ok, ping = pcall(function() return _lplr:GetNetworkPing() end)
    if ok and type(ping) == "number" and ping == ping then return ping end
    return 0
end

local function getPredictedPosition(targetRoot)
    local velocity = targetRoot.AssemblyLinearVelocity
    if not isSafeVector(velocity) then velocity = Vector3.zero end
    if velocity.Magnitude > PB.MAX_SANE_SPEED then
        velocity = velocity.Unit * PB.MAX_SANE_SPEED
    end

    local t = math.clamp(getPing(), PB.PREDICT_MIN_TIME, PB.PREDICT_MAX_TIME)
    local flat = Vector3.new(velocity.X, 0, velocity.Z) * t
    if flat.Magnitude > PB.PREDICT_MAX_DIST then
        flat = flat.Unit * PB.PREDICT_MAX_DIST
    end
    local dy = math.clamp(velocity.Y * t, -PB.PREDICT_MAX_FALL, 0)

    local base = targetRoot.Position
    return Vector3.new(base.X + flat.X, base.Y + dy, base.Z + flat.Z)
end

local function followBehind(myRoot, targetRoot, predicted)
    local look = targetRoot.CFrame.LookVector
    local flatLook = Vector3.new(look.X, 0, look.Z)
    flatLook = flatLook.Magnitude > 0.01 and flatLook.Unit or Vector3.zAxis

    myRoot.CFrame = CFrame.new(
        predicted.X - flatLook.X * PB.BEHIND_DISTANCE,
        predicted.Y + PB.HEIGHT_OFFSET,
        predicted.Z - flatLook.Z * PB.BEHIND_DISTANCE
    )

    local v = myRoot.AssemblyLinearVelocity
    myRoot.AssemblyLinearVelocity = Vector3.new(v.X, 0, v.Z)
end

local function faceTarget(myRoot, targetPosition)
    if not isSafeVector(targetPosition) then return end
    local flatTarget = Vector3.new(targetPosition.X, myRoot.Position.Y, targetPosition.Z)
    if (flatTarget - myRoot.Position).Magnitude > 0.05 then
        myRoot.CFrame = CFrame.lookAt(myRoot.Position, flatTarget)
    end
end

local function aimCamera(targetPosition)
    _camera = workspace.CurrentCamera or _camera
    if not _camera or not isSafeVector(targetPosition) then return end
    local origin = _camera.CFrame.Position
    if (targetPosition - origin).Magnitude > 0.05 then
        _camera.CFrame = _camera.CFrame:Lerp(
            CFrame.lookAt(origin, targetPosition),
            math.clamp(PB.CAMERA_SMOOTH, 0, 1)
        )
    end
end

local function getGroundBelow(position, ignored)
    if not isSafeVector(position) then return nil end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = ignored
    params.RespectCanCollide = true
    return workspace:Raycast(position + Vector3.new(0, 3, 0), Vector3.new(0, -10000, 0), params)
end

local function doFallingTeleport(myRoot, myHumanoid, targetRoot, predicted)
    local now = os.clock()
    local heightDiff = myRoot.Position.Y - targetRoot.Position.Y

    if _dropCompletedFor == targetRoot then
        local landed = now - _dropCompletedAt > 0.3 and math.abs(myRoot.AssemblyLinearVelocity.Y) < 8
        if heightDiff <= PB.FALL_LAND_HEIGHT or landed then
            _dropCompletedFor = nil
            return false
        end
        myRoot.CFrame = CFrame.new(predicted.X, myRoot.Position.Y, predicted.Z)
        return true
    end

    if _dropTargetRoot ~= targetRoot then
        if heightDiff < PB.FALL_TRIGGER_HEIGHT then return false end
        _dropTargetRoot = targetRoot
        _dropStickUntil = now + PB.FALL_HEAD_STICK_TIME
    end

    if not targetRoot.Parent then
        resetDrop()
        return false
    end

    if now < _dropStickUntil then
        local head = targetRoot.Parent:FindFirstChild("Head")
        local headPosition = head and head.Position or (targetRoot.Position + Vector3.new(0, targetRoot.Size.Y, 0))
        local footHeight = myHumanoid.HipHeight + (myRoot.Size.Y / 2) + 0.15
        local height = footHeight + PB.FALL_HEAD_HEIGHT_ADJUSTMENT

        local ground = getGroundBelow(headPosition, { myRoot.Parent, targetRoot.Parent })
        local entryY = math.max(
            headPosition.Y + height,
            targetRoot.Position.Y + PB.FALL_HITBOX_VERTICAL_REACH
        )
        if ground then
            entryY = math.max(
                entryY,
                ground.Position.Y + PB.FALL_HITBOX_VERTICAL_REACH + PB.FALL_GROUND_SAFETY_MARGIN
            )
        end

        myRoot.CFrame = CFrame.new(predicted.X, entryY, predicted.Z)
        myRoot.AssemblyLinearVelocity = Vector3.new(0, PB.FALL_STICK_VELOCITY, 0)
        return true
    end

    myRoot.CFrame = CFrame.new(predicted.X, myRoot.Position.Y, predicted.Z)
    myRoot.AssemblyLinearVelocity = Vector3.new(0, PB.FALL_RELEASE_VELOCITY, 0)
    _dropCompletedFor = targetRoot
    _dropCompletedAt = now
    _dropTargetRoot = nil
    return true
end

local function toKeyCode(key)
    if typeof(key) == "EnumItem" and key.EnumType == Enum.KeyCode then
        return key
    end
    if type(key) == "string" then
        local name = key:match("([%w_]+)$")
        if name then
            local ok, kc = pcall(function() return Enum.KeyCode[name] end)
            if ok and kc then return kc end
        end
    end
    if type(key) == "number" then
        for _, kc in ipairs(Enum.KeyCode:GetEnumItems()) do
            if kc.Value == key then return kc end
        end
    end
    return nil
end

local function step()
    if _latched then return end

    local myChar = _lplr.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local myHumanoid = myChar and myChar:FindFirstChildOfClass("Humanoid")
    if not myRoot or not myHumanoid or not isSafeVector(myRoot.Position) then return end

    if _targetPlayer and not getLiveRoot(_targetPlayer) then
        _latched = true
        resetTarget()
        return
    end

    local lockActive, lockTarget = readLock()
    local locked = false

    if lockActive and lockTarget then
        local plr, root = resolveTargetValue(lockTarget)
        if not (plr and root) then return end
        if _targetHRP ~= root then resetDrop() end
        _targetPlayer, _targetHRP = plr, root
        _rescore = PB.RESCORE_INTERVAL
        locked = true
    else
        _rescore = _rescore + 1
        if _rescore >= PB.RESCORE_INTERVAL or not _targetHRP then
            _rescore = 0
            local newRoot, newPlayer = selectPassiveTarget(myRoot)
            if newRoot then
                if _targetHRP ~= newRoot then resetDrop() end
                _targetHRP, _targetPlayer = newRoot, newPlayer
            else
                resetTarget()
            end
        end
    end

    _lockedMode = locked

    local validRoot = _targetPlayer and getLiveRoot(_targetPlayer)
    if not validRoot then
        resetTarget()
        return
    end
    _targetHRP = validRoot

    local predicted = getPredictedPosition(_targetHRP)
    if not isSafeVector(predicted) then return end

    local flyOk, fly = pcall(function() return env()._AFO_FLY_MODULE end)
    if flyOk and fly and type(fly.Bypass) == "function" then
        pcall(fly.Bypass, 0.1, "passivebang")
    end

    if not doFallingTeleport(myRoot, myHumanoid, _targetHRP, predicted) then
        followBehind(myRoot, _targetHRP, predicted)
    end

    faceTarget(myRoot, predicted)

    if not locked then
        aimCamera(predicted)
    end

    if not locked and _leftDown and _rightDown then
        resetTarget()
        _leftDown, _rightDown = false, false
    end
end

function M.Start(lplr, keyCode)
    if typeof(lplr) ~= "Instance" or not lplr:IsA("Player") then
        lplr = Players.LocalPlayer
    end

    while not lplr do
        task.wait()
        lplr = Players.LocalPlayer
    end

    _lplr = lplr
    _mouse = nil

    if #_conns > 0 then M.Stop() end

    local kc = toKeyCode(keyCode)
    if kc then _bangKey = kc end

    table.insert(_conns, _lplr.CharacterAdded:Connect(updateCharacter))
    updateCharacter()

    table.insert(_conns, UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe or _capturing then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then _leftDown = true end
        if input.UserInputType == Enum.UserInputType.MouseButton2 then _rightDown = true end

        if input.KeyCode == _bangKey then
            _holding = true
            _latched = false
            resetTarget()
        end
    end))

    table.insert(_conns, UserInputService.InputEnded:Connect(function(input)
        if input.KeyCode == _bangKey then
            _holding = false
            _latched = false
            resetTarget()
        end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then _leftDown = false end
        if input.UserInputType == Enum.UserInputType.MouseButton2 then _rightDown = false end
    end))

    table.insert(_conns, RunService.RenderStepped:Connect(function()
        if not _holding then return end
        pcall(step)
    end))
end

function M.Stop()
    for _, connection in ipairs(_conns) do pcall(function() connection:Disconnect() end) end
    table.clear(_conns)
    if _captureConn then
        pcall(function() _captureConn:Disconnect() end)
        _captureConn = nil
    end
    _capturing = false
    _holding = false
    _latched = false
    _leftDown, _rightDown = false, false
    resetTarget()
end

function M.SetLockModule(module)
    if type(module) == "table" then
        rawset(env(), "AFO_LOCK_API", module)
    end
end

function M.SetKeybind(key)
    local kc = toKeyCode(key)
    if not kc then return false end
    _bangKey = kc
    _holding = false
    _latched = false
    resetTarget()
    return true
end

function M.GetKeybind()
    return _bangKey
end

function M.CaptureKeybind(callback)
    if _captureConn then
        pcall(function() _captureConn:Disconnect() end)
        _captureConn = nil
    end
    _capturing = true
    _holding = false
    resetTarget()

    _captureConn = UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
        if _captureConn then
            _captureConn:Disconnect()
            _captureConn = nil
        end
        task.defer(function()
            _capturing = false
            if input.KeyCode ~= Enum.KeyCode.Escape then
                _bangKey = input.KeyCode
            end
            if type(callback) == "function" then
                pcall(callback, _bangKey)
            end
        end)
    end)
end

function M.GetTeleportTarget()
    if not _holding or not _targetHRP then return nil end
    return {
        player = _targetPlayer,
        hrp = _targetHRP,
        isLockedByModule = _lockedMode,
    }
end

return M
