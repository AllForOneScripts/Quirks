local M = {}

local _connection
local _isActive = false
local _shieldEnabled = true

local ADMIN_GROUPS = {
    {id=1200769,minRank=1,label="ROBLOX ADMIN"},
    {id=3055661,minRank=1,label="QA TESTER"},
    {id=14593111,minRank=1,label="ROBLOX ADMIN"},
    {id=12513722,minRank=1,label="IMPORTANT PERSON"},
    {id=10279336,minRank=1,label="IMPORTANT PERSON"},
    {id=6821794,minRank=1,label="IMPORTANT PERSON"},
    {id=3253689,minRank=1,label="IMPORTANT PERSON"},
    {id=17395026,minRank=50,label="HEROES BG STAFF"}
}

local QA_HATS = {"Valiant Top Hat of Testing", "Valiant Valkyrie of Testing", "Thoroughly-Tested Hat of QA"}

function M.Start()
    if _isActive then return end
    _isActive = true

    local Players = game:GetService("Players")
    local TeleportService = game:GetService("TeleportService")
    local lplr = Players.LocalPlayer
    local placeId = game.PlaceId

    local function playerIsAdmin(p)
        for _, entry in ipairs(ADMIN_GROUPS) do
            local ok, rank = pcall(function() return p:GetRankInGroup(entry.id) end)
            if ok and rank >= entry.minRank then return true, entry.label end
        end
        if p.Character then
            for _, child in ipairs(p.Character:GetChildren()) do
                if child:IsA("Accessory") then 
                    for _, hat in ipairs(QA_HATS) do 
                        if child.Name == hat then return true, "QA TESTER" end 
                    end 
                end
            end
        end
        return false, nil
    end

    local function handlePossibleAdmin(p)
        if p == lplr then return end
        if not p.Character then pcall(function() p.CharacterAdded:Wait() end); task.wait(1.5) end
        if not _shieldEnabled then return end
        
        local isAdmin, label = playerIsAdmin(p)
        if isAdmin then
            pcall(function()
                if Fluent and T then
                    Fluent:Notify({Title=T.notif_admin_detected_title, Content=T.notif_admin_detected_content.." ("..(label or "?")..")", Duration=5})
                end
            end)
            task.wait(1)
            
            pcall(function() getgenv()._kickedByHub = true end)
            pcall(function() if QueueSelf then QueueSelf() end end)
            
            task.wait(0.3)
            pcall(function() TeleportService:Teleport(placeId, lplr) end)
        end
    end

    task.spawn(function()
        task.wait(2)
        for _, p in ipairs(Players:GetPlayers()) do 
            task.spawn(handlePossibleAdmin, p) 
        end
    end)

    _connection = Players.PlayerAdded:Connect(function(p) 
        task.spawn(handlePossibleAdmin, p) 
    end)
end

function M.Stop()
    _isActive = false
    if _connection then
        _connection:Disconnect()
        _connection = nil
    end
end

function M.SetShieldEnabled(state)
    _shieldEnabled = state
end

return M
