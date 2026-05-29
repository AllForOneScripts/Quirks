local M = {}

local _lplr = nil
local _lang = "ES"
local _guiActive = false

function M.Start(lplr, lang)
    _lplr = lplr
    _lang = lang or "ES"
end

function M.Open()
    if _guiActive then return end
    _guiActive = true

    local function LC(es, en) return (_lang == "EN") and en or es end

    pcall(function()
        local old = _lplr:FindFirstChildOfClass("PlayerGui"):FindFirstChild("CloneGui")
        if old then old:Destroy() end
    end)

    local ScreenGui = Instance.new("ScreenGui", _lplr:FindFirstChildOfClass("PlayerGui"))
    ScreenGui.Name = "CloneGui"
    ScreenGui.ResetOnSpawn = false

    local Frame = Instance.new("Frame", ScreenGui)
    Frame.Size = UDim2.new(0, 230, 0, 90)
    Frame.Position = UDim2.new(0.4, 0, 0.4, 0)
    Frame.BackgroundColor3 = Color3.fromRGB(150, 26, 20)
    Frame.BorderSizePixel = 0
    Frame.Active = true
    Frame.Draggable = true

    local Title = Instance.new("TextLabel", Frame)
    Title.Size = UDim2.new(1, -30, 0, 28)
    Title.Position = UDim2.new(0, 0, 0, 0)
    Title.BackgroundColor3 = Color3.fromRGB(121, 17, 15)
    Title.BorderSizePixel = 0
    Title.Font = Enum.Font.SourceSansBold
    Title.Text = "Clone Player"
    Title.TextColor3 = Color3.new(1, 1, 1)
    Title.TextSize = 18

    local CloseBtn = Instance.new("TextButton", Frame)
    CloseBtn.Size = UDim2.new(0, 30, 0, 28)
    CloseBtn.Position = UDim2.new(1, -30, 0, 0)
    CloseBtn.BackgroundColor3 = Color3.fromRGB(80, 8, 8)
    CloseBtn.BorderSizePixel = 0
    CloseBtn.Font = Enum.Font.SourceSansBold
    CloseBtn.Text = "✕"
    CloseBtn.TextColor3 = Color3.new(1, 1, 1)
    CloseBtn.TextSize = 16
    CloseBtn.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
        _guiActive = false
    end)

    local PlayerBox = Instance.new("TextBox", Frame)
    PlayerBox.Size = UDim2.new(0, 210, 0, 26)
    PlayerBox.Position = UDim2.new(0, 10, 0, 34)
    PlayerBox.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    PlayerBox.BorderSizePixel = 0
    PlayerBox.Font = Enum.Font.SourceSansBold
    PlayerBox.Text = LC("Nombre del jugador", "Player name")
    PlayerBox.TextColor3 = Color3.new(1, 1, 1)
    PlayerBox.TextSize = 17
    PlayerBox.ClearTextOnFocus = true

    local CloneBtn = Instance.new("TextButton", Frame)
    CloneBtn.Size = UDim2.new(0, 210, 0, 24)
    CloneBtn.Position = UDim2.new(0, 10, 0, 64)
    CloneBtn.BackgroundColor3 = Color3.fromRGB(121, 17, 15)
    CloneBtn.BorderSizePixel = 0
    CloneBtn.Font = Enum.Font.SourceSansBold
    CloneBtn.Text = LC("Clonar", "Clone")
    CloneBtn.TextColor3 = Color3.new(1, 1, 1)
    CloneBtn.TextSize = 18

    CloneBtn.MouseButton1Click:Connect(function()
        local Players = game:GetService("Players")
        local name = PlayerBox.Text
        local target = Players:FindFirstChild(name)
        if target and target.Character then
            local Plr = target.Character
            Plr.Archivable = true
            local Clon = Plr:Clone()
            Clon.Parent = workspace
            Clon:MoveTo(Plr:GetModelCFrame().p)
            Clon:MakeJoints()
            Plr.Archivable = false
        else
            PlayerBox.Text = LC("Jugador no encontrado", "Player not found")
        end
    end)
end

function M.Stop()
    _guiActive = false
    pcall(function()
        if _lplr then
            local old = _lplr:FindFirstChildOfClass("PlayerGui"):FindFirstChild("CloneGui")
            if old then old:Destroy() end
        end
    end)
end

return M
