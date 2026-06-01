local M = {}
local UserInputService = game:GetService("UserInputService")
local _conn = nil
local _lplr = nil
local _keys = nil

local ALTURA_EXTRA = 5

function M.Start(Keys, lplr)
    _keys = Keys
    _lplr = lplr
    if _conn then _conn:Disconnect() end
    local mouse = lplr:GetMouse()
    _conn = UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == _keys.Teleport then
            local char = _lplr.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp and mouse.Target then
                hrp.CFrame = CFrame.new(
                    mouse.Hit.Position + Vector3.new(0, ALTURA_EXTRA, 0)
                )
            end
        end
    end)
end

function M.Stop()
    if _conn then _conn:Disconnect(); _conn = nil end
end

function M.SetKey(kc)
    if _keys then _keys.Teleport = kc end
end

return M
