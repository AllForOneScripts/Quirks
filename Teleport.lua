local M = {}
local UserInputService = game:GetService("UserInputService")
local _conn = nil
local _lplr = nil
local _keys = nil
local _flyModule = nil

function M.Start(Keys, lplr, flyModuleRef)
    _keys = Keys
    _lplr = lplr
    _flyModule = flyModuleRef
    if _conn then _conn:Disconnect() end
    local mouse = lplr:GetMouse()
    _conn = UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == _keys.Teleport then
            local char = _lplr.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp and mouse.Target then
                -- Bypass: notificar a Fly antes del TP
                local _fm = _flyModule or rawget(getgenv(), "_AFO_FLY_MODULE")
                if _fm and _fm.Bypass then
                    _fm.Bypass(0.5, "teleport")
                end
                hrp.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0, 5, 0))
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

function M.SetFlyModule(flyModuleRef)
    _flyModule = flyModuleRef
end

return M
