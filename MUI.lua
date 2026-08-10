-- Roblox LocalScript / ModuleScript (Luau)
--
-- Replace the original MUIClearSourceDeathWatch + MUIWatchSourceDeath block.
-- Add MUIRefreshSourceDeath() in MUIHeartbeat before the
-- `if MUINow >= MUIActiveUntil then` condition.
--
-- This deliberately tracks the Player AND the exact Character that triggered
-- the dodge. The target respawning is therefore the death/end of that source.

local MUISourceDeathConnections = {}
local MUISourceCharacter = nil

local function MUIClearSourceDeathWatch()
    for _, MUIConnection in ipairs(MUISourceDeathConnections) do
        MUIDisconnect(MUIConnection)
    end
    table.clear(MUISourceDeathConnections)
    MUISourceCharacter = nil
    MUISourceDied = false
end

local function MUIMarkSourceDead(MUIPlayer, MUICharacter)
    if MUIPlayer == MUIActiveSource
        and (MUICharacter == nil or MUICharacter == MUISourceCharacter) then
        MUISourceDied = true
    end
end

local function MUIRefreshSourceDeath()
    local MUIPlayer = MUIActiveSource
    local MUICharacter = MUISourceCharacter
    if not MUIExtendUntilSourceDies or MUISourceDied then
        return
    end
    if not MUIPlayer or not MUICharacter
        or MUIPlayer.Parent ~= MUIPlayers
        or MUIPlayer.Character ~= MUICharacter then
        MUIMarkSourceDead(MUIPlayer, MUICharacter)
        return
    end
    local MUIHumanoid = MUIGetHumanoid(MUICharacter)
    if not MUIHumanoid
        or MUIHumanoid.Health <= 0
        or MUIHumanoid:GetState() == Enum.HumanoidStateType.Dead then
        MUIMarkSourceDead(MUIPlayer, MUICharacter)
    end
end

local function MUIWatchSourceDeath(MUIPlayer)
    MUIClearSourceDeathWatch()
    if not MUIPlayer then
        return
    end

    local MUICharacter = MUIPlayer.Character
    MUISourceCharacter = MUICharacter
    if not MUICharacter then
        MUIMarkSourceDead(MUIPlayer)
        return
    end

    local MUIHumanoid = MUIGetHumanoid(MUICharacter)
    if not MUIHumanoid then
        MUIMarkSourceDead(MUIPlayer, MUICharacter)
        return
    end

    table.insert(MUISourceDeathConnections, MUIHumanoid.Died:Connect(function()
        MUIMarkSourceDead(MUIPlayer, MUICharacter)
    end))
    table.insert(MUISourceDeathConnections, MUIHumanoid.HealthChanged:Connect(function(MUIHealth)
        if MUIHealth <= 0 then
            MUIMarkSourceDead(MUIPlayer, MUICharacter)
        end
    end))
    table.insert(MUISourceDeathConnections, MUIPlayer.CharacterRemoving:Connect(function(MUIRemovingCharacter)
        if MUIRemovingCharacter == MUICharacter then
            MUIMarkSourceDead(MUIPlayer, MUICharacter)
        end
    end))
    table.insert(MUISourceDeathConnections, MUIPlayer.CharacterAdded:Connect(function(MUINewCharacter)
        if MUINewCharacter ~= MUICharacter then
            MUIMarkSourceDead(MUIPlayer, MUICharacter)
        end
    end))
    table.insert(MUISourceDeathConnections, MUICharacter.AncestryChanged:Connect(function(_, MUIParent)
        if not MUIParent then
            MUIMarkSourceDead(MUIPlayer, MUICharacter)
        end
    end))

    MUIRefreshSourceDeath()
end

-- In MUIHeartbeat, insert this directly before the timeout block:
--
--     MUIRefreshSourceDeath()
--     if MUINow >= MUIActiveUntil then
--         ... existing code ...
