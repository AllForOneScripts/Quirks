local M = {}

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

    local CoreGui = game:GetService("CoreGui")
    local Players = game:GetService("Players")
    local TeleportService = game:GetService("TeleportService")
    local lplr = Players.LocalPlayer

    local placeId = game.PlaceId
    local jobId = game.JobId

    local promptOverlay = CoreGui:WaitForChild("RobloxPromptGui"):WaitForChild("promptOverlay")

    _connection = promptOverlay.ChildAdded:Connect(function(child)
        if child.Name ~= "ErrorPrompt" then return end
        
        if _kickedByHub then 
            _kickedByHub = false 
            return 
        end
        
        if not _autoRejoinEnabled then return end

        pcall(function()
            child.Size = UDim2.new(0, 400, 0, 230)
            child.MessageArea.MessageAreaPadding.PaddingTop = UDim.new(0, -20)
            child.MessageArea.ErrorFrame.ErrorFrameLayout.Padding = UDim.new(0, 5)
            child.MessageArea.ErrorFrame.ButtonArea.ButtonLayout.CellPadding = UDim2.new(0, 0, 0, 5)
        end)

        local leaveBtn = child.MessageArea.ErrorFrame.ButtonArea:FindFirstChild("LeaveButton")
        if not leaveBtn then return end

        local rejoinBtn = leaveBtn:Clone()
        rejoinBtn.Name = "RejoinButton"
        rejoinBtn.Parent = leaveBtn.Parent
        
        pcall(function()
            rejoinBtn.ButtonText.Text = (_lang == "ES") and "Reconectar" or "Rejoin"
        end)

        rejoinBtn.MouseButton1Up:Connect(function()
            pcall(function()
                rejoinBtn.ButtonText.Text = (_lang == "ES") and "Conectando..." or "Joining..."
            end)

            if #Players:GetPlayers() <= 1 then
                TeleportService:Teleport(placeId, lplr)
            else
                TeleportService:TeleportToPlaceInstance(placeId, jobId, lplr)
            end
        end)
    end)

    print("[Auto-Rejoin]: Inicializado correctamente.")
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
