local M = {}
local _conn = nil
local _teleporting = false

function M.Start(lplr, TeleportService, placeId)
    _teleporting = false
    local function check(instance)
        if not instance:IsA("Sound") then return end
        local targetId = "9066167010"
        if not (instance.SoundId == "rbxassetid://"..targetId or (instance.SoundId:match("%d+") or "") == targetId) then return end
        local function go()
            if _teleporting then return end
            _teleporting = true
            TeleportService:Teleport(placeId, lplr)
        end
        if instance.IsPlaying then go(); return end
        instance:GetPropertyChangedSignal("IsPlaying"):Connect(function()
            if instance.IsPlaying then go() end
        end)
        instance.Played:Connect(go)
    end
    local function scan(root)
        for _, d in ipairs(root:GetDescendants()) do check(d) end
    end
    scan(workspace)
    scan(game:GetService("SoundService"))
    scan(lplr)
    _conn = workspace.DescendantAdded:Connect(check)
    lplr.CharacterAdded:Connect(function(char)
        task.wait(0.5); scan(char)
        char.DescendantAdded:Connect(check)
    end)
end

function M.Stop()
    _teleporting = false
    if _conn then _conn:Disconnect(); _conn = nil end
end

return M
