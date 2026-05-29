local M = {}
local _running = false
local _loop = nil
local _animConn = nil
local _activeTrack = nil
local _history = {}

function M.Start(char)
    M.Stop()
    if not char then return end
    _running = true

    local humanoid = char:WaitForChild("Humanoid")
    local animator = humanoid:WaitForChild("Animator")

    _animConn = animator.AnimationPlayed:Connect(function(track)
        if track:GetAttribute("EsLag") then return end
        local id = track.Animation and track.Animation.AnimationId
        if id and id ~= "" and not table.find(_history, id) then
            table.insert(_history, id)
            if #_history > 20 then table.remove(_history, 1) end
        end
    end)

    _loop = task.spawn(function()
        while _running and char and char.Parent do
            local hum = char:FindFirstChildOfClass("Humanoid")
            if not hum or hum.Health <= 0 then break end
            if #_history > 0 then
                local index = math.random(1,100) <= 70 and #_history or math.random(1, #_history)
                local nextId = _history[index]
                local newTrack
                local ok = pcall(function()
                    local anim = Instance.new("Animation")
                    anim.AnimationId = nextId
                    newTrack = animator:LoadAnimation(anim)
                    newTrack:SetAttribute("EsLag", true)
                    newTrack.Priority = Enum.AnimationPriority.Action4
                    newTrack:Play(0.3)
                end)
                if ok and newTrack then
                    local prev = _activeTrack
                    _activeTrack = newTrack
                    if prev then
                        pcall(function() prev:Stop(0.3) end)
                        task.delay(0.5, function() pcall(function() prev:Destroy() end) end)
                    end
                end
                task.wait(0.5)
            else
                task.wait(0.1)
            end
        end
        if _activeTrack then pcall(function() _activeTrack:Stop(0.3) end); _activeTrack = nil end
    end)
end

function M.Stop()
    _running = false
    if _loop then task.cancel(_loop); _loop = nil end
    if _animConn then pcall(function() _animConn:Disconnect() end); _animConn = nil end
    if _activeTrack then pcall(function() _activeTrack:Stop(0.3) end); _activeTrack = nil end
    _history = {}
end

return M
