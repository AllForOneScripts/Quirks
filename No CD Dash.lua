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
    
    -- Función separada para mayor claridad, igual que en tu segundo script
    local function removeFolders()
        local live = workspace:FindFirstChild("Live")
        if not live then return end
        
        -- Buscamos el personaje en cada frame para asegurar que funcione incluso tras reaparecer (respawn)
        local targetParent = live:FindFirstChild(_lplr.Name)
        if not targetParent then return end
        
        -- ipairs es ligeramente más rápido que pairs para listas/arrays indexados
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
