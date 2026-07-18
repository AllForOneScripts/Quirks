local M = {}
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local _conn = nil 
local _lplr = nil

local foldersToDelete = { 
    "DASHCD", "SideDashCounter", "ForwardDashCD", "DashPunchCD", 
    "DontAllowBlocking", "RecentSideDash", "TRUECANTSIDEDASH", 
    "CantPunchOnCLIENT", "DownSlamCD", "RecentStun", "RecentStunNoAction", 
    "recentdashok", "RagdollCancelCD" 
}

function M.Start(lplr)
    -- Si no se especifica un jugador al llamar la función, usa el LocalPlayer automáticamente
    _lplr = lplr or Players.LocalPlayer
    
    -- Desconecta cualquier conexión anterior para evitar duplicados
    if _conn then M.Stop() end
    
    local function removeFolders()
        local live = workspace:FindFirstChild("Live")
        if not live then return end
        
        local targetParent = live:FindFirstChild(_lplr.Name)
        if not targetParent then return end
        
        for _, folderName in ipairs(foldersToDelete) do
            local folder = targetParent:FindFirstChild(folderName)
            if folder then
                folder:Destroy()
            end
        end
    end

    -- Conectamos la función al Heartbeat
    _conn = RunService.Heartbeat:Connect(removeFolders)
end

function M.Stop()
    if _conn then 
        _conn:Disconnect() 
        _conn = nil 
    end 
end

return M
