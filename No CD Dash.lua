local noCDConn = nil
local noCDFolders = {
    "DASHCD", "SideDashCounter", "ForwardDashCD", "DashPunchCD",
    "DontAllowBlocking", "RecentSideDash", "TRUECANTSIDEDASH",
    "CantPunchOnCLIENT", "DownSlamCD", "RecentStun", "RecentStunNoAction",
    "recentdashok", "RagdollCancelCD"
}
 
local function noCDRemove()
    local live = workspace:FindFirstChild("Live")
    if not live then return end
    local pf = live:FindFirstChild(lplr.Name)
    if not pf then return end
    for _, name in pairs(noCDFolders) do
        local f = pf:FindFirstChild(name)
        if f then f:Destroy() end
    end
end
