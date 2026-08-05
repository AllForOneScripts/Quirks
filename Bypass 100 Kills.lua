local M = {}

local connections = {}
local teleporting = false
local TARGET_ID = "9066167010"

local function disconnectAll()
	for _, connection in ipairs(connections) do
		connection:Disconnect()
	end
	table.clear(connections)
end

local function isTargetSound(sound)
	local id = sound.SoundId:match("%d+")
	return id == TARGET_ID
end

function M.Start(lplr, TeleportService, placeId)
	M.Stop()

	local function teleport()
		if teleporting then return end
		teleporting = true
		TeleportService:Teleport(placeId, lplr)
	end

	local function check(instance)
		if not instance:IsA("Sound") or not isTargetSound(instance) then
			return
		end

		if instance.IsPlaying then
			teleport()
			return
		end

		table.insert(connections, instance:GetPropertyChangedSignal("IsPlaying"):Connect(function()
			if instance.IsPlaying then
				teleport()
			end
		end))
	end

	local function scan(root)
		check(root)
		for _, descendant in ipairs(root:GetDescendants()) do
			check(descendant)
		end
	end

	local function watch(root)
		scan(root)
		table.insert(connections, root.DescendantAdded:Connect(check))
	end

	watch(workspace)
	watch(game:GetService("SoundService"))
	watch(lplr)

	table.insert(connections, lplr.CharacterAdded:Connect(function(character)
		task.defer(scan, character)
		table.insert(connections, character.DescendantAdded:Connect(check))
	end))

	if lplr.Character then
		scan(lplr.Character)
	end
end

function M.Stop()
	teleporting = false
	disconnectAll()
end

return M
