local M = {}

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")

local _connection = nil
local _lang = "ES"
local _autoRejoinEnabled = true
local _kickedByHub = false

function M.Start(lang)
    if _connection then 
        warn("[Auto-Rejoin]: El módulo ya está activo.")
        return 
    end

    _lang = lang or "ES"

    local lplr = Players.LocalPlayer
    local placeId = game.PlaceId
    local jobId = game.JobId

    -- Escuchamos cualquier cambio en los mensajes de error de la pantalla
    _connection = GuiService.ErrorMessageChanged:Connect(function(errorMessage)
        -- Verificamos que exista un error real (desconexión, kick, etc.)
        if errorMessage and errorMessage ~= "" then
            
            -- Si el kick fue provocado por el propio hub, lo ignoramos
            if _kickedByHub then 
                _kickedByHub = false 
                return 
            end
            
            -- Si la función está desactivada, cancelamos
            if not _autoRejoinEnabled then return end

            print("[Auto-Rejoin]: Error detectado -> " .. errorMessage)

            if lplr then
                -- Usamos task.wait() que es más eficiente que wait() tradicional
                -- Le damos 1 segundo de margen para evitar saturar el cliente
                task.wait(1)
                
                -- Mantenemos tu lógica de re-conexión original
                if #Players:GetPlayers() <= 1 then
                    TeleportService:Teleport(placeId, lplr)
                else
                    pcall(function()
                        TeleportService:TeleportToPlaceInstance(placeId, jobId, lplr)
                    end)
                end
            end
        end
    end)

    print("[Auto-Rejoin]: Inicializado correctamente (Método GuiService).")
end

function M.Stop()
    if _connection then
        _connection:Disconnect()
        _connection = nil
        print("[Auto-Rejoin]: Módulo detenido.")
    end
end

function M.SetAutoRejoin(state)
    _autoRejoinEnabled = state
end

function M.SetKickedByHub(state)
    _kickedByHub = state
end

return M
