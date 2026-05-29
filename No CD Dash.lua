local M = {}
local RunService = game:GetService("RunService")
local _conn = nil
local _lplr = nil

local noCDFolders = {
    "DASHCD","SideDashCounter","ForwardDashCD","DashPunchCD",
    "DontAllowBlocking","RecentSideDash","TRUECANTSIDEDASH",
    "CantPunchOnCLIENT","DownSlamCD","RecentStun","RecentStunNoAction",
    "recentdashok","RagdollCancelCD"
}

function M.Start(lplr)
    _lplr = lplr
    if _conn then _conn:Disconnect() end
    _conn = RunService.Heartbeat:Connect(function()
        local live = workspace:FindFirstChild("Live")
        if not live then return end
        local pf = live:FindFirstChild(_lplr.Name)
        if not pf then return end
        for _, name in pairs(noCDFolders) do
            local f = pf:FindFirstChild(name)
            if f then f:Destroy() end
        end
    end)
end

function M.Stop()
    if _conn then _conn:Disconnect(); _conn = nil end
end

return M
