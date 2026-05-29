local M = {}

local _isActive = false
local _isAdonis = false
local _oldNc = nil

function M.Start()
    if _isActive then 
        warn("[Anti-Kick]: El módulo ya está activo.")
        return 
    end
    _isActive = true

    local lp = game:GetService('Players').LocalPlayer
    local rs = game:GetService('ReplicatedStorage')

    local function check_adonis(o)
        if not o:IsA('RemoteEvent') then return false end
        local f = o:FindFirstChildWhichIsA('RemoteFunction')
        if not f or f.Name ~= '__FUNCTION' then return false end
        _isAdonis = true
        return true
    end

    if not game:IsLoaded() then
        game.Loaded:Wait()
    end

    for _, o in next, rs:GetDescendants() do 
        check_adonis(o) 
    end

    if not _isAdonis then
        _G.adonis_checker = rs.ChildAdded:Connect(function(o)
            task.wait()
            if not check_adonis(o) then return end
            if _G.adonis_checker then
                _G.adonis_checker:Disconnect()
                _G.adonis_checker = nil
            end
        end)
    end

    task.spawn(function()
        hookfunction(lp.Destroy, newcclosure(function(...)
            if checkcaller() then return end
            return task.wait(9e9)
        end))
        
        if not _isAdonis then
            hookfunction(lp.Kick, newcclosure(function(...)
                if checkcaller() or _isAdonis then return end
                return task.wait(9e9)
            end))
        end
    end)

    if not _oldNc then
        _oldNc = hookmetamethod(game, '__namecall', newcclosure(function(self, ...)
            local method = string.lower(getnamecallmethod())
            
            if self ~= lp or checkcaller() then 
                return _oldNc(self, ...) 
            end

            if method == 'kick' or method == 'destroy' then
                local kscriptz = getcallingscript()
                local kscript = kscriptz and kscriptz:GetFullName() or "No se pudo obtener"
                
                print(string.format('[Anti-Kick]: %s bloqueado. Proveniente de "%s"', method, tostring(kscript)))
                return task.wait(9e9)
            end

            return _oldNc(self, ...)
        end))
    end
    
    print("[Anti-Kick]: Inicializado correctamente.")
end

function M.Stop()
    if _G.adonis_checker then
        _G.adonis_checker:Disconnect()
        _G.adonis_checker = nil
    end
    
    _isActive = false
    warn("[Anti-Kick]: El escáner se ha detenido. (Los hooks de protección persisten en la memoria).")
end

return M
