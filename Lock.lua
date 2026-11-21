local _0xS_K = 173
local function _0xS_D(s)
	local r = {}
	for i = 1, #s do
		r[i] = string.char(bit32.bxor(string.byte(s, i), _0xS_K))
	end
	return table.concat(r)
end
local _0x1 = game:GetService(_0xS_D("\253\193\204\212\200\223\222"))
local _0x2 = game:GetService(_0xS_D("\255\216\195\254\200\223\219\196\206\200"))
local _0x3 = game:GetService(_0xS_D("\248\222\200\223\228\195\221\216\217\254\200\223\219\196\206\200"))
local _0x4 = game:GetService(_0xS_D("\249\200\213\217\254\200\223\219\196\206\200"))
local function _0x5(_0x6)
	return (_0x6 ~= _0x6)
end
local function _0x7(_0x8)
	if (not _0x8) then
		return false
	end
	return (not (((_0x5(_0x8.X) or _0x5(_0x8.Y)) or _0x5(_0x8.Z))))
end
local function _0x9()
	return (_0x3:GetFocusedTextBox() ~= nil)
end
local _0xa = (((debug and debug.profilebegin)) or function()

end)
local _0xb = (((debug and debug.profileend)) or function()

end)
local _0xc = { ES = { lock_label = _0xS_D("\225\226\238\230"), lock_hint_prefix = _0xS_D("\236\221\216\195\217\204\223\141\134\141"), height_below = _0xS_D("\222\217\216\201\222\141\204\207\204\199\194"), height_above = _0xS_D("\222\217\216\201\222\141\204\223\223\196\207\204"), height_same = _0xS_D("\192\196\222\192\194\141\195\196\219\200\193"), studs = _0xS_D("\222\217\216\201\222") }, EN = { lock_label = _0xS_D("\225\226\238\230"), lock_hint_prefix = _0xS_D("\236\196\192\141\134\141"), height_below = _0xS_D("\222\217\216\201\222\141\207\200\193\194\218"), height_above = _0xS_D("\222\217\216\201\222\141\204\207\194\219\200"), height_same = _0xS_D("\222\204\192\200\141\193\200\219\200\193"), studs = _0xS_D("\222\217\216\201\222") } }
local _0xd = _0xc[_0xS_D("\232\254")]
local function _0xe()
	local _0xf = _0xS_D("\232\254")
	pcall(function()
	if (type(readfile) == _0xS_D("\203\216\195\206\217\196\194\195")) then
		local _0x10 = readfile(_0xS_D("\236\193\193\235\194\223\226\195\200\130\193\204\195\202\131\217\213\217"))
		if ((_0x10 == _0xS_D("\232\227")) or (_0x10 == _0xS_D("\232\254"))) then
			_0xf = _0x10
		end
	end
end)
	_0xd = _0xc[_0xf]
end
_0xe()
local _0x11 = _0xS_D("\223\207\213\204\222\222\200\217\196\201\151\130\130\149\159\149\156\154\148\155\152\159\152\155\156\148\156")
local _0x12 = { lockKey = Enum.KeyCode.X, systemEnabled = false, lockActive = false, lockedTarget = nil, avatarRequestId = 0, lockIconGui = nil, lockInfoGui = nil, ownScreenGui = nil, infoGuiParent = nil, lockHighlight = nil, lockLabels = nil, lockConn = nil, aimPart = nil, aimOffset = Vector3.zero, aimAtCursor = true, trackStiffness = 40, snapAngle = math.rad(1.5), trackBoost = 60, maxPitch = math.rad(70), nearMinHz = 1.5, nearFullHz = 4, pitchMinHz = 4, projectileSpeed = 0, maxTurnSpeed = math.rad(2000), jitterRadius = 0.6, guiInterval = (1 / 15), guiClock = 0, lockValid = false, aimPoint = nil, renderName = _0xS_D("\236\235\226\242\225\194\206\198\238\204\192\200\223\204") }
local _0x13 = nil
local _0x14 = nil
local function _0x15()
	_0x14 = (workspace.CurrentCamera or _0x14)
	return _0x14
end
local _0x16 = { _0xS_D("\248\221\221\200\223\249\194\223\222\194"), _0xS_D("\249\194\223\222\194"), _0xS_D("\229\216\192\204\195\194\196\201\255\194\194\217\253\204\223\217") }
local function _0x17(_0x18)
	if (not _0x18) then
		return nil
	end
	if _0x12.aimPart then
		local _0x19 = _0x18:FindFirstChild(_0x12.aimPart)
		if (_0x19 and _0x19:IsA(_0xS_D("\239\204\222\200\253\204\223\217"))) then
			return _0x19
		end
	end
	for _0x1a, _0x1b in ipairs(_0x16) do
		local _0x1c = _0x18:FindFirstChild(_0x1b)
		if (_0x1c and _0x1c:IsA(_0xS_D("\239\204\222\200\253\204\223\217"))) then
			return _0x1c
		end
	end
	local _0x1d = _0x18:FindFirstChildOfClass(_0xS_D("\229\216\192\204\195\194\196\201"))
	return ((_0x1d and _0x1d.RootPart) or nil)
end
local function _0x1e(_0x1f, _0x20)
	local _0x21 = _0x17(_0x1f)
	if (not _0x21) then
		return nil
	end
	local _0x22 = (_0x21.Position + _0x12.aimOffset)
	if (not _0x7(_0x22)) then
		return nil
	end
	local _0x23 = _0x12.projectileSpeed
	if ((_0x23 and (_0x23 > 0)) and _0x20) then
		local _0x24 = (_0x1f:FindFirstChild(_0xS_D("\229\216\192\204\195\194\196\201\255\194\194\217\253\204\223\217")) or _0x21)
		local _0x25 = _0x1f:FindFirstChildOfClass(_0xS_D("\229\216\192\204\195\194\196\201"))
		local _0x26 = _0x24.AssemblyLinearVelocity
		if (_0x7(_0x26) and (_0x26.Magnitude < 200)) then
			if (not ((_0x25 and (_0x25:GetState() == Enum.HumanoidStateType.Freefall)))) then
				_0x26 = Vector3.new(_0x26.X, 0, _0x26.Z)
			end
			local _0x27 = (((_0x22 - _0x20)).Magnitude / _0x23)
			for _0x28 = 1, 2 do
				_0x27 = (((((_0x22 + (_0x26 * _0x27))) - _0x20)).Magnitude / _0x23)
			end
			_0x22 = (_0x22 + (_0x26 * _0x27))
		end
	end
	return _0x22
end
local function _0x29(_0x2a)
	if (not _0x2a) then
		return false
	end
	local _0x2b = _0x2a.Character
	if (not _0x2b) then
		return false
	end
	local _0x2c = _0x2b:FindFirstChildOfClass(_0xS_D("\229\216\192\204\195\194\196\201"))
	if (not _0x2c) then
		return false
	end
	if (_0x2c.Health <= 0) then
		return false
	end
	if (_0x2c:GetState() == Enum.HumanoidStateType.Dead) then
		return false
	end
	return true
end
local function _0x2d()
	local _0x2e = nil
	local _0x2f = math.huge
	local _0x30 = (_0x13 and _0x13.Character)
	local _0x31 = (_0x30 and _0x30:FindFirstChild(_0xS_D("\229\216\192\204\195\194\196\201\255\194\194\217\253\204\223\217")))
	if (not _0x15()) then
		return nil
	end
	for _0x32, _0x33 in ipairs(_0x1:GetPlayers()) do
		if (_0x33 == _0x13) then
			continue
		end
		if (not _0x29(_0x33)) then
			continue
		end
		local _0x34 = _0x33.Character
		if (not _0x34) then
			continue
		end
		local _0x35 = _0x17(_0x34)
		if (not _0x35) then
			continue
		end
		local _0x36, _0x37, _0x38 = pcall(function()
	return _0x14:WorldToViewportPoint(_0x35.Position)
end)
		if ((not _0x36) or (not _0x38)) then
			continue
		end
		local _0x39 = _0x3:GetMouseLocation()
		local _0x3a = ((_0x39 - Vector2.new(_0x37.X, _0x37.Y))).Magnitude
		if (_0x5(_0x3a) or (_0x3a > 300)) then
			continue
		end
		local _0x3b = ((_0x31 and ((_0x31.Position - _0x35.Position)).Magnitude) or 0)
		if _0x5(_0x3b) then
			continue
		end
		local _0x3c = (_0x3a + ((_0x3b * 0.2)))
		if (_0x3c < _0x2f) then
			_0x2f = _0x3c
			_0x2e = _0x33
		end
	end
	return _0x2e
end
local _0x3d = 12
local function _0x3e(_0x3f)
	return ((tostring((_0x3f or _0xS_D(""))):match(_0xS_D("\243\136\222\135\133\131\128\132\136\222\135\137"))) or _0xS_D(""))
end
local function _0x40(_0x41)
	_0x41 = _0x3e(_0x41)
	_0x41 = (_0x41:gsub(_0xS_D("\079\045\049"), _0xS_D("\143")):gsub(_0xS_D("\079\045\048"), _0xS_D("\143")))
	local _0x42 = _0x41:match(_0xS_D("\243\143\133\131\128\132\143\146\137"))
	if _0x42 then
		return _0x3e(_0x42), true
	end
	return _0x41, false
end
local function _0x43(_0x44)
	local _0x45 = _0x44.DisplayName
	if ((not _0x45) or (_0x45 == _0xS_D(""))) then
		_0x45 = _0x44.Name
	end
	return _0x45
end
local function _0x46(_0x47, _0x48)
	local _0x49 = ((_0x47 or _0xS_D(""))):lower()
	if (_0x49 == _0xS_D("")) then
		return {}
	end
	local _0x4a = {}
	for _0x4b, _0x4c in ipairs(_0x1:GetPlayers()) do
		if (_0x4c == _0x13) then
			continue
		end
		local _0x4d = (((_0x48 and _0x43(_0x4c)) or _0x4c.Name)):lower()
		local _0x4e = 0
		if (_0x4d == _0x49) then
			_0x4e = 3
		elseif (_0x4d:sub(1, (#_0x49)) == _0x49) then
			_0x4e = 2
		elseif _0x4d:find(_0x49, 1, true) then
			_0x4e = 1
		end
		if (_0x4e > 0) then
			table.insert(_0x4a, { player = _0x4c, score = _0x4e, key = _0x4d })
		end
	end
	table.sort(_0x4a, function(_0x4f, _0x50)
	if (_0x4f.score ~= _0x50.score) then
		return (_0x4f.score > _0x50.score)
	end
	return (_0x4f.key < _0x50.key)
end)
	local _0x51 = {}
	for _0x52 = 1, math.min((#_0x4a), _0x3d) do
		_0x51[_0x52] = _0x4a[_0x52].player
	end
	return _0x51
end
local function _0x53(_0x54)
	local _0x55, _0x56 = _0x40(_0x54)
	local _0x57 = _0x46(_0x55, _0x56)[1]
	if (not _0x57) then
		return nil, _0x54, _0x56
	end
	local _0x58 = ((_0x56 and ((_0xS_D("\143") .. (_0x43(_0x57) .. _0xS_D("\143"))))) or _0x57.Name)
	return _0x57, _0x58, _0x56
end
local function _0x59()
	if _0x12.lockIconGui then
		pcall(function()
	_0x12.lockIconGui:Destroy()
end)
		_0x12.lockIconGui = nil
	end
end
local function _0x5a(_0x5b)
	if (((not _0x12.systemEnabled) or (not _0x12.lockActive)) or (_0x5b ~= _0x12.lockedTarget)) then
		return
	end
	_0x59()
	local _0x5c = _0x17(_0x5b.Character)
	if (not _0x5c) then
		return
	end
	_0x12.lockIconGui = Instance.new(_0xS_D("\239\196\193\193\207\194\204\223\201\234\216\196"), _0x5c)
	_0x12.lockIconGui.Name = _0xS_D("\225\194\206\198\228\206\194\195")
	_0x12.lockIconGui.Size = UDim2.new(0, 50, 0, 50)
	_0x12.lockIconGui.AlwaysOnTop = true
	_0x12.lockIconGui.StudsOffset = Vector3.new(0, 0, 0)
	local _0x5d = Instance.new(_0xS_D("\228\192\204\202\200\225\204\207\200\193"), _0x12.lockIconGui)
	_0x5d.Size = UDim2.new(1, 0, 1, 0)
	_0x5d.BackgroundTransparency = 1
	_0x5d.Image = _0x11
	_0x5d.ImageColor3 = Color3.fromRGB(255, 255, 255)
	_0x5d.ScaleType = Enum.ScaleType.Fit
end
local function _0x5e()
	if (not _0x12.lockHighlight) then
		_0x12.lockHighlight = Instance.new(_0xS_D("\229\196\202\197\193\196\202\197\217"))
		_0x12.lockHighlight.Name = _0xS_D("\236\235\226\242\225\194\206\198\229\196\202\197\193\196\202\197\217")
		_0x12.lockHighlight.FillTransparency = 1
		_0x12.lockHighlight.OutlineColor = Color3.fromRGB(255, 255, 255)
		_0x12.lockHighlight.OutlineTransparency = 0
	end
end
local function _0x5f()
	local _0x60 = nil
	if (((_0x12.systemEnabled and _0x12.lockActive) and _0x12.lockedTarget) and _0x29(_0x12.lockedTarget)) then
		_0x60 = _0x12.lockedTarget.Character
	end
	if _0x60 then
		_0x5e()
		if (_0x12.lockHighlight.Parent ~= _0x60) then
			_0x12.lockHighlight.Parent = _0x60
		end
	elseif (_0x12.lockHighlight and (_0x12.lockHighlight.Parent ~= nil)) then
		_0x12.lockHighlight.Parent = nil
	end
end
local function _0x61()
	if ((((not _0x12.systemEnabled) or (not _0x12.lockActive)) or (not _0x12.lockedTarget)) or (not _0x12.lockInfoGui)) then
		return
	end
	local _0x62 = _0x12.lockInfoGui:FindFirstChild(_0xS_D("\253\193\204\212\200\223\228\192\204\202\200"), true)
	if (not _0x62) then
		return
	end
	if (_0x12.avatarLoadedGui == _0x12.lockInfoGui) then
		return
	end
	if (os.clock() < ((_0x12.avatarRetryAt or 0))) then
		return
	end
	_0x12.avatarLoadedGui = _0x12.lockInfoGui
	local _0x63 = _0x12.lockedTarget
	local _0x64 = _0x12.lockInfoGui
	local _0x65 = _0x12.avatarRequestId
	local _0x66 = _0x63.UserId
	task.spawn(function()
	local _0x67, _0x68 = pcall(function()
	return _0x1:GetUserThumbnailAsync(_0x66, Enum.ThumbnailType.AvatarBust, Enum.ThumbnailSize.Size420x420)
end)
	if (((((((_0x67 and _0x68) and _0x12.systemEnabled) and _0x12.lockActive) and (_0x12.lockedTarget == _0x63)) and (_0x12.lockInfoGui == _0x64)) and (_0x12.avatarRequestId == _0x65)) and _0x62.Parent) then
		_0x62.Image = _0x68
	elseif (_0x12.avatarLoadedGui == _0x64) then
		_0x12.avatarLoadedGui = nil
		_0x12.avatarRetryAt = (os.clock() + 3)
	end
end)
end
local function _0x69(_0x6a, _0x6b, _0x6c)
	local _0x6d = _0x6a.Text
	if (_0x6a:GetAttribute(_0xS_D("\235\196\217\249\200\213\217")) == _0x6d) then
		return
	end
	_0x6a:SetAttribute(_0xS_D("\235\196\217\249\200\213\217"), _0x6d)
	local _0x6e = _0x6a.AbsoluteSize.X
	if (_0x6e <= 0) then
		_0x6e = 132
	end
	local _0x6f = _0x6b
	while (_0x6f > _0x6c) do
		local _0x70, _0x71 = pcall(function()
	return _0x4:GetTextSize(_0x6d, _0x6f, _0x6a.Font, Vector2.new(10000, 100))
end)
		if ((not _0x70) or (_0x71.X <= _0x6e)) then
			break
		end
		_0x6f = (_0x6f - 1)
	end
	_0x6a.TextSize = _0x6f
end
local function _0x72(_0x73)
	if (((not _0x12.systemEnabled) or (not _0x12.lockActive)) or (not _0x12.lockedTarget)) then
		return
	end
	if _0x12.lockInfoGui then
		pcall(function()
	_0x12.lockInfoGui:Destroy()
end)
		_0x12.lockInfoGui = nil
	end
	local _0x74 = _0x73
	if (not _0x74) then
		if _0x12.ownScreenGui then
			pcall(function()
	_0x12.ownScreenGui:Destroy()
end)
			_0x12.ownScreenGui = nil
		end
		local _0x75 = Instance.new(_0xS_D("\254\206\223\200\200\195\234\216\196"))
		_0x75.Name = _0xS_D("\236\235\226\242\225\194\206\198\234\216\196")
		_0x75.ResetOnSpawn = false
		_0x75.IgnoreGuiInset = true
		_0x75.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		local _0x76
		if (type(gethui) == _0xS_D("\203\216\195\206\217\196\194\195")) then
			local _0x77, _0x78 = pcall(gethui)
			if (_0x77 and _0x78) then
				_0x76 = _0x78
			end
		end
		if (not _0x76) then
			local _0x79, _0x7a = pcall(function()
	return _0x13.PlayerGui
end)
			_0x76 = (((_0x79 and _0x7a)) or game:GetService(_0xS_D("\238\194\223\200\234\216\196")))
		end
		_0x75.Parent = _0x76
		_0x12.ownScreenGui = _0x75
		_0x74 = _0x75
	end
	local _0x7b = Color3.fromRGB(110, 30, 180)
	local _0x7c = Color3.fromRGB(6, 4, 12)
	local _0x7d = Color3.fromRGB(220, 190, 255)
	local _0x7e = Instance.new(_0xS_D("\235\223\204\192\200"))
	_0x7e.Name = _0xS_D("\225\194\206\198\228\195\203\194\253\204\195\200\193")
	_0x7e.Size = UDim2.new(0, 250, 0, 122)
	_0x7e.Position = UDim2.new(1, (-262), 0, 44)
	_0x7e.AnchorPoint = Vector2.new(0, 0)
	_0x7e.BackgroundColor3 = _0x7c
	_0x7e.BackgroundTransparency = 0.15
	_0x7e.BorderSizePixel = 0
	_0x7e.ZIndex = 10
	_0x7e.Visible = true
	_0x7e.Parent = _0x74
	Instance.new(_0xS_D("\248\228\238\194\223\195\200\223"), _0x7e).CornerRadius = UDim.new(0, 8)
	local _0x7f = Instance.new(_0xS_D("\248\228\254\217\223\194\198\200"), _0x7e)
	_0x7f.Color = _0x7b
	_0x7f.Thickness = 1
	_0x7f.Transparency = 0.5
	local _0x80 = Instance.new(_0xS_D("\249\200\213\217\225\204\207\200\193"), _0x7e)
	_0x80.Size = UDim2.new(0, 28, 0, 28)
	_0x80.Position = UDim2.new(0, 6, 0.5, (-14))
	_0x80.BackgroundTransparency = 1
	_0x80.Font = Enum.Font.Legacy
	_0x80.TextSize = 20
	_0x80.TextColor3 = Color3.fromRGB(255, 220, 80)
	_0x80.Text = _0xS_D("\093\050\035\002")
	local function _0x81(_0x82, _0x83, _0x84, _0x85, _0x86, _0x87, _0x88)
		local _0x89 = Instance.new(_0xS_D("\249\200\213\217\225\204\207\200\193"), _0x7e)
		_0x89.Name = _0x82
		_0x89.Size = UDim2.new(1, (-118), 0, _0x84)
		_0x89.Position = UDim2.new(0, 40, 0, _0x83)
		_0x89.BackgroundTransparency = 1
		_0x89.Font = _0x85
		_0x89.TextSize = _0x86
		_0x89.TextColor3 = _0x87
		_0x89.Text = _0x88
		_0x89.TextXAlignment = Enum.TextXAlignment.Left
		_0x89.TextTruncate = Enum.TextTruncate.AtEnd
		return _0x89
	end
	_0x81(_0xS_D("\227\204\192\200\225\204\207\200\193"), 8, 18, Enum.Font.GothamBold, 13, _0x7d, _0xS_D("\128\128\128"))
	_0x81(_0xS_D("\248\222\200\223\225\204\207\200\193"), 26, 14, Enum.Font.Gotham, 10, Color3.fromRGB(170, 150, 210), _0xS_D("\237\128\128\128"))
	_0x81(_0xS_D("\233\196\222\217\225\204\207\200\193"), 44, 15, Enum.Font.Gotham, 11, Color3.fromRGB(200, 170, 255), (_0xS_D("\128\128\128\141") .. _0xd.studs))
	_0x81(_0xS_D("\229\200\196\202\197\217\225\204\207\200\193"), 60, 15, Enum.Font.Gotham, 10, Color3.fromRGB(150, 220, 255), _0xS_D("\128\128\128"))
	_0x81(_0xS_D("\229\200\204\193\217\197\225\204\207\200\193"), 77, 18, Enum.Font.Legacy, 12, Color3.fromRGB(255, 150, 150), _0xS_D("\079\048\009\066\021\034\141\128\128\128"))
	local _0x8a = Instance.new(_0xS_D("\235\223\204\192\200"), _0x7e)
	_0x8a.Name = _0xS_D("\229\200\204\193\217\197\239\204\223\239\202")
	_0x8a.Size = UDim2.new(1, (-24), 0, 6)
	_0x8a.Position = UDim2.new(0, 12, 1, (-14))
	_0x8a.BackgroundColor3 = Color3.fromRGB(30, 18, 50)
	_0x8a.BorderSizePixel = 0
	_0x8a.ZIndex = 11
	Instance.new(_0xS_D("\248\228\238\194\223\195\200\223"), _0x8a).CornerRadius = UDim.new(1, 0)
	local _0x8b = Instance.new(_0xS_D("\235\223\204\192\200"), _0x8a)
	_0x8b.Name = _0xS_D("\229\200\204\193\217\197\239\204\223\235\196\193\193")
	_0x8b.Size = UDim2.new(1, 0, 1, 0)
	_0x8b.BackgroundColor3 = Color3.fromRGB(80, 255, 80)
	_0x8b.BorderSizePixel = 0
	_0x8b.ZIndex = 12
	Instance.new(_0xS_D("\248\228\238\194\223\195\200\223"), _0x8b).CornerRadius = UDim.new(1, 0)
	local _0x8c = Instance.new(_0xS_D("\235\223\204\192\200"), _0x7e)
	_0x8c.Name = _0xS_D("\253\193\204\212\200\223\228\192\202\238\194\195\217\204\196\195\200\223")
	_0x8c.Size = UDim2.new(0, 64, 0, 64)
	_0x8c.Position = UDim2.new(1, (-74), 0, 12)
	_0x8c.BackgroundColor3 = Color3.fromRGB(20, 10, 40)
	_0x8c.BackgroundTransparency = 0.3
	_0x8c.BorderSizePixel = 0
	_0x8c.ZIndex = 11
	Instance.new(_0xS_D("\248\228\238\194\223\195\200\223"), _0x8c).CornerRadius = UDim.new(1, 0)
	local _0x8d = Instance.new(_0xS_D("\228\192\204\202\200\225\204\207\200\193"), _0x8c)
	_0x8d.Name = _0xS_D("\253\193\204\212\200\223\228\192\204\202\200")
	_0x8d.Size = UDim2.new(1, 0, 1, 0)
	_0x8d.Position = UDim2.new(0, 0, 0, 0)
	_0x8d.BackgroundTransparency = 1
	_0x8d.Image = _0xS_D("")
	_0x8d.ZIndex = 12
	Instance.new(_0xS_D("\248\228\238\194\223\195\200\223"), _0x8d).CornerRadius = UDim.new(1, 0)
	_0x12.lockInfoGui = _0x7e
end
local function _0x8e()
	if _0x12.lockInfoGui then
		pcall(function()
	_0x12.lockInfoGui:Destroy()
end)
		_0x12.lockInfoGui = nil
	end
	if _0x12.ownScreenGui then
		pcall(function()
	_0x12.ownScreenGui:Destroy()
end)
		_0x12.ownScreenGui = nil
	end
end
local function _0x8f()
	_0x12.avatarRequestId = (_0x12.avatarRequestId + 1)
	_0x12.lockActive = false
	_0x12.lockedTarget = nil
	_0x12.lockValid = false
	_0x59()
	_0x5f()
	_0x8e()
end
local function _0x90()
	if (not _0x12.lockInfoGui) then
		return
	end
	if ((((not _0x12.lockActive) or (not _0x12.lockedTarget)) or (not _0x12.lockedTarget.Character)) or (not _0x29(_0x12.lockedTarget))) then
		_0x8f()
		return
	end
	local _0x91 = _0x12.lockedTarget
	local _0x92 = _0x91.Character:FindFirstChild(_0xS_D("\229\216\192\204\195\194\196\201\255\194\194\217\253\204\223\217"))
	local _0x93 = _0x91.Character:FindFirstChildOfClass(_0xS_D("\229\216\192\204\195\194\196\201"))
	local _0x94 = (_0x13 and _0x13.Character)
	local _0x95 = (_0x94 and _0x94:FindFirstChild(_0xS_D("\229\216\192\204\195\194\196\201\255\194\194\217\253\204\223\217")))
	if (not _0x92) then
		return
	end
	local _0x96 = _0x12.lockInfoGui
	local _0x97 = _0x96:FindFirstChild(_0xS_D("\227\204\192\200\225\204\207\200\193"))
	if _0x97 then
		local _0x98 = _0x91.DisplayName
		if ((not _0x98) or (_0x98 == _0xS_D(""))) then
			_0x98 = _0x91.Name
		end
		_0x97.Text = _0x98
		_0x69(_0x97, 13, 7)
	end
	local _0x99 = _0x96:FindFirstChild(_0xS_D("\248\222\200\223\225\204\207\200\193"))
	if _0x99 then
		_0x99.Text = (_0xS_D("\237") .. _0x91.Name)
		_0x69(_0x99, 10, 7)
	end
	local _0x9a = 0
	if ((_0x95 and _0x7(_0x95.Position)) and _0x7(_0x92.Position)) then
		_0x9a = ((_0x95.Position - _0x92.Position)).Magnitude
	elseif _0x15() then
		_0x9a = ((_0x14.CFrame.Position - _0x92.Position)).Magnitude
	end
	if _0x5(_0x9a) then
		_0x9a = 0
	end
	local _0x9b = _0x96:FindFirstChild(_0xS_D("\233\196\222\217\225\204\207\200\193"))
	if _0x9b then
		_0x9b.Text = (math.floor((_0x9a + 0.5)) .. (_0xS_D("\141") .. _0xd.studs))
	end
	local _0x9c = _0x96:FindFirstChild(_0xS_D("\229\200\196\202\197\217\225\204\207\200\193"))
	if (((_0x9c and _0x95) and _0x7(_0x95.Position)) and _0x7(_0x92.Position)) then
		local _0x9d = math.floor(((_0x95.Position.Y - _0x92.Position.Y) + 0.5))
		if _0x5(_0x9d) then
			_0x9d = 0
		end
		if (_0x9d > 0) then
			_0x9c.Text = (_0xS_D("\079\059\017\141") .. (_0x9d .. (_0xS_D("\141") .. _0xd.height_below)))
			_0x9c.TextColor3 = Color3.fromRGB(150, 220, 255)
		elseif (_0x9d < 0) then
			_0x9c.Text = (_0xS_D("\079\059\031\141") .. (math.abs(_0x9d) .. (_0xS_D("\141") .. _0xd.height_above)))
			_0x9c.TextColor3 = Color3.fromRGB(255, 200, 100)
		else
			_0x9c.Text = (_0xS_D("\079\058\034\141") .. _0xd.height_same)
			_0x9c.TextColor3 = Color3.fromRGB(150, 255, 150)
		end
	end
	local _0x9e = _0x96:FindFirstChild(_0xS_D("\229\200\204\193\217\197\225\204\207\200\193"))
	if (_0x9e and _0x93) then
		local _0x9f = math.max(_0x93.Health, 0)
		local _0xa0 = math.max(_0x93.MaxHealth, 1)
		local _0xa1
		if ((math.floor(_0x9f) == 0) and (_0x9f > 0)) then
			_0xa1 = string.format(_0xS_D("\136\131\159\203"), (math.floor(((_0x9f * 100) + 0.5)) / 100))
		else
			_0xa1 = tostring(math.floor((_0x9f + 0.5)))
		end
		local _0xa2 = math.clamp((_0x9f / _0xa0), 0, 1)
		local _0xa3, _0xa4
		if (_0x9f <= 0) then
			_0xa3, _0xa4 = _0xS_D("\079\053\013\066\021\034"), Color3.fromRGB(120, 120, 120)
		elseif (_0xa2 > 0.75) then
			_0xa3, _0xa4 = _0xS_D("\093\050\063\055"), Color3.fromRGB(80, 255, 80)
		elseif (_0xa2 > 0.50) then
			_0xa3, _0xa4 = _0xS_D("\093\050\063\054"), Color3.fromRGB(255, 220, 80)
		elseif (_0xa2 > 0.25) then
			_0xa3, _0xa4 = _0xS_D("\093\050\010\012"), Color3.fromRGB(255, 160, 60)
		else
			_0xa3, _0xa4 = _0xS_D("\079\048\009\066\021\034"), Color3.fromRGB(255, 80, 80)
		end
		_0x9e.Font = Enum.Font.Legacy
		_0x9e.Text = (_0xa3 .. (_0xS_D("\141") .. (_0xa1 .. (_0xS_D("\130") .. tostring(math.floor((_0xa0 + 0.5)))))))
		_0x9e.TextColor3 = _0xa4
		local _0xa5 = _0x96:FindFirstChild(_0xS_D("\229\200\204\193\217\197\239\204\223\239\202"))
		local _0xa6 = (_0xa5 and _0xa5:FindFirstChild(_0xS_D("\229\200\204\193\217\197\239\204\223\235\196\193\193")))
		if _0xa6 then
			_0xa6.Size = UDim2.new(_0xa2, 0, 1, 0)
			_0xa6.BackgroundColor3 = _0xa4
		end
	end
	_0x61()
end
local _0xa7 = 0.40
local _0xa8 = 0.85
local _0xa9 = 0.30
local _0xaa = 10
local function _0xab(_0xac)
	return ((((_0xac + math.pi)) % ((2 * math.pi))) - math.pi)
end
local function _0xad(_0xae, _0xaf)
	local _0xb0 = math.sqrt(((_0xae.X * _0xae.X) + (_0xae.Z * _0xae.Z)))
	return math.atan2((-_0xae.X), (-_0xae.Z)), math.atan2(_0xae.Y, math.max(_0xb0, (_0xaf or 0)))
end
local function _0xb1(_0xb2, _0xb3, _0xb4)
	local _0xb5 = math.clamp((((_0xb2 - _0xb3)) / math.max((_0xb4 - _0xb3), 1e-3)), 0, 1)
	return ((_0xb5 * _0xb5) * ((3 - (2 * _0xb5))))
end
local function _0xb6(_0xb7, _0xb8)
	if ((not _0xb8) or (_0xb8 <= 0)) then
		return 0
	end
	local _0xb9 = math.clamp((((_0xb7 - 4)) / 8), 0, 1)
	local _0xba = (_0xb8 * ((1 - ((_0xb9 * _0xb9) * ((3 - (2 * _0xb9)))))))
	return math.atan2(_0xba, math.max(_0xb7, 0.5))
end
local function _0xbb(_0xbc, _0xbd, _0xbe, _0xbf, _0xc0, _0xc1)
	local _0xc2 = Vector3.new((_0xbd * _0xbc), (_0xbe * _0xbc), (-1)).Unit
	local _0xc3 = _0xc2:Dot(_0xbf)
	local _0xc4 = (((_0xc3 * _0xc3) - _0xbf:Dot(_0xbf)) + (_0xc0 * _0xc0))
	local _0xc5 = (_0xbf + (_0xc2 * (((-_0xc3) + math.sqrt(math.max(_0xc4, 0))))))
	local _0xc6 = _0xc5.Magnitude
	if (_0xc6 < 1e-3) then
		return nil, false
	end
	_0xc5 = (_0xc5 / _0xc6)
	local _0xc7 = math.sqrt(((_0xc5.Y * _0xc5.Y) + (_0xc5.Z * _0xc5.Z)))
	local _0xc8 = (_0xa7 * _0xc0)
	return _0xc5, ((((_0xc4 >= (_0xc8 * _0xc8))) and ((math.abs(_0xc1) <= (_0xa8 * _0xc7)))) and ((_0xc5.Z <= (-_0xa9))))
end
local function _0xc9(_0xca, _0xcb, _0xcc, _0xcd, _0xce, _0xcf)
	local _0xd0 = _0xca.CFrame
	local _0xd1 = (_0xcc - _0xcb)
	local _0xd2 = _0xd1.Magnitude
	if (_0xd2 < 0.5) then
		return nil
	end
	local _0xd3, _0xd4 = _0xad(_0xd0.LookVector)
	local _0xd5 = _0xd0:VectorToObjectSpace((_0xd0.Position - _0xcb))
	local _0xd6 = _0xd0:VectorToObjectSpace(_0xca:ViewportPointToRay(_0xcd.X, _0xcd.Y).Direction)
	local _0xd7, _0xd8 = 0, 0
	if (_0xd6.Z < (-1e-3)) then
		_0xd7, _0xd8 = (_0xd6.X / (-_0xd6.Z)), (_0xd6.Y / (-_0xd6.Z))
	end
	local _0xd9, _0xda = _0xad(_0xd1, _0xce)
	local _0xdb = math.sin(_0xda)
	local _0xdc, _0xdd = _0xbb(1, _0xd7, _0xd8, _0xd5, _0xd2, _0xdb)
	if (not _0xdd) then
		local _0xde, _0xdf = 0, 1
		for _0xe0 = 1, _0xaa do
			local _0xe1 = (((_0xde + _0xdf)) * 0.5)
			local _0xe2, _0xe3 = _0xbb(_0xe1, _0xd7, _0xd8, _0xd5, _0xd2, _0xdb)
			if _0xe3 then
				_0xde = _0xe1
			else
				_0xdf = _0xe1
			end
		end
		_0xdc = _0xbb(_0xde, _0xd7, _0xd8, _0xd5, _0xd2, _0xdb)
	end
	if (not _0xdc) then
		return nil
	end
	local _0xe4, _0xe5 = _0xdc.Y, (-_0xdc.Z)
	local _0xe6 = math.sqrt(((_0xe4 * _0xe4) + (_0xe5 * _0xe5)))
	local _0xe7 = _0xd4
	if (_0xe6 > 1e-6) then
		local _0xe8 = math.atan2(_0xe5, _0xe4)
		local _0xe9 = math.acos(math.clamp((_0xdb / _0xe6), (-1), 1))
		local _0xea, _0xeb = _0xab((_0xe8 + _0xe9)), _0xab((_0xe8 - _0xe9))
		_0xe7 = ((((math.abs(_0xab((_0xea - _0xd4))) <= math.abs(_0xab((_0xeb - _0xd4))))) and _0xea) or _0xeb)
	end
	local _0xec = math.max(_0xcf, math.abs(_0xd4))
	_0xe7 = math.clamp(_0xe7, (-_0xec), _0xec)
	local _0xed = math.atan2((-_0xdc.X), (-(((math.sin(_0xe7) * _0xdc.Y) + (math.cos(_0xe7) * _0xdc.Z)))))
	local _0xee = _0xab((_0xd9 - _0xed))
	return _0xee, _0xe7, _0xd3, _0xd4, _0xd5
end
local function _0xef(_0xf0, _0xf1)
	local _0xf2 = _0xf0.CFrame.Position
	local _0xf3 = _0xf2
	if (_0xf0.CameraType ~= Enum.CameraType.Scriptable) then
		local _0xf4 = _0xf0.Focus.Position
		if ((not _0xf1(_0xf4)) and (((_0xf4 - _0xf2)).Magnitude < 100)) then
			_0xf3 = _0xf4
		end
	end
	if (((_0xf2 - _0xf3)).Magnitude < 1.5) then
		_0xf3 = _0xf2
	end
	return _0xf3
end
local function _0xf5(_0xf6, _0xf7, _0xf8, _0xf9, _0xfa)
	if ((_0xf8 ~= _0xf8) or (_0xf9 ~= _0xf9)) then
		return
	end
	local _0xfb = CFrame.fromEulerAnglesYXZ(_0xf9, _0xf8, 0)
	_0xf6.CFrame = (CFrame.new((_0xf7 + _0xfb:VectorToWorldSpace(_0xfa))) * _0xfb)
end
local function _0xfc(_0xfd, _0xfe, _0xff, _0x100, _0x101, _0x102, _0x103, _0x104, _0x105)
	local _0x106 = math.sqrt(((_0x102 * _0x102) + (_0x103 * _0x103)))
	local _0x107 = (((_0x104 or math.huge)) * _0x105)
	if (_0x106 > _0x107) then
		local _0x108 = (_0x107 / _0x106)
		_0x102, _0x103 = (_0x102 * _0x108), (_0x103 * _0x108)
	end
	_0xf5(_0xfd, _0xfe, (_0xff + _0x102), (_0x100 + _0x103), _0x101)
end
local function _0x109(_0x10a)
	return (not _0x7(_0x10a))
end
local function _0x10b(_0x10c, _0x10d, _0x10e)
	local _0x10f = _0xef(_0x10c, _0x109)
	local _0x110 = (_0x10d - _0x10f)
	local _0x111 = _0xb1(math.sqrt(((_0x110.X * _0x110.X) + (_0x110.Z * _0x110.Z))), _0x12.nearMinHz, _0x12.nearFullHz)
	if (_0x111 <= 0) then
		return
	end
	local _0x112
	if (_0x12.aimAtCursor and (_0x3.MouseBehavior ~= Enum.MouseBehavior.LockCenter)) then
		_0x112 = _0x3:GetMouseLocation()
	else
		_0x112 = (_0x10c.ViewportSize / 2)
	end
	local _0x113, _0x114, _0x115, _0x116, _0x117 = _0xc9(_0x10c, _0x10f, _0x10d, _0x112, _0x12.pitchMinHz, _0x12.maxPitch)
	if (((((not _0x113) or (not _0x114)) or (not _0x115)) or (not _0x116)) or (not _0x117)) then
		return
	end
	local _0x118 = _0xab((_0x113 - _0x115))
	local _0x119 = (_0x114 - _0x116)
	local _0x11a = math.sqrt(((_0x118 * _0x118) + (_0x119 * _0x119)))
	local _0x11b = _0xb6(_0x110.Magnitude, _0x12.jitterRadius)
	if (_0x11a <= _0x11b) then
		return
	end
	if (_0x11b > 0) then
		local _0x11c = (((_0x11a - _0x11b)) / _0x11a)
		_0x118, _0x119 = (_0x118 * _0x11c), (_0x119 * _0x11c)
	end
	local _0x11d = math.max(math.abs(_0x118), math.abs(_0x119))
	local _0x11e = (1 - math.exp(((-((_0x12.trackStiffness + (_0x11d * _0x12.trackBoost)))) * _0x10e)))
	if (_0x11d <= _0x12.snapAngle) then
		_0x11e = 1
	end
	_0x11e = (_0x11e * _0x111)
	_0xfc(_0x10c, _0x10f, _0x115, _0x116, _0x117, (_0x118 * _0x11e), (_0x119 * _0x11e), _0x12.maxTurnSpeed, _0x10e)
end
local function _0x11f(_0x120)
	_0x12.aimPoint = nil
	_0x12.lockValid = false
	if ((not _0x12.lockActive) or (not _0x12.lockedTarget)) then
		return
	end
	local _0x121 = _0x12.lockedTarget.Character
	if ((not _0x121) or (not _0x29(_0x12.lockedTarget))) then
		_0x8f()
		return
	end
	_0x12.lockValid = true
	local _0x122 = _0x15()
	if (not _0x122) then
		return
	end
	local _0x123 = (_0x13 and _0x13.Character)
	local _0x124 = (_0x123 and _0x123:FindFirstChild(_0xS_D("\229\216\192\204\195\194\196\201\255\194\194\217\253\204\223\217")))
	local _0x125 = _0x1e(_0x121, (_0x124 and _0x124.Position))
	if (not _0x125) then
		return
	end
	_0x12.aimPoint = _0x125
	pcall(_0x10b, _0x122, _0x125, math.min((_0x120 or 0.016), 0.1))
end
local _0x126 = { char = nil, active = nil, target = nil, aim = nil }
local function _0x127(_0x128, _0x129, _0x12a)
	local _0x12b = _0x128:FindFirstChild(_0x12a)
	if (not _0x12b) then
		_0x12b = Instance.new(_0x129)
		_0x12b.Name = _0x12a
		_0x12b.Parent = _0x128
	end
	return _0x12b
end
local function _0x12c()
	local _0x12d = (_0x13 and _0x13.Character)
	if (not _0x12d) then
		return
	end
	if (((((((_0x126.char ~= _0x12d) or (not _0x126.active)) or (_0x126.active.Parent ~= _0x12d)) or (not _0x126.target)) or (_0x126.target.Parent ~= _0x12d)) or (not _0x126.aim)) or (_0x126.aim.Parent ~= _0x12d)) then
		_0x126.char = _0x12d
		_0x126.active = _0x127(_0x12d, _0xS_D("\239\194\194\193\251\204\193\216\200"), _0xS_D("\236\235\226\242\225\194\206\198\236\206\217\196\219\200"))
		_0x126.target = _0x127(_0x12d, _0xS_D("\226\207\199\200\206\217\251\204\193\216\200"), _0xS_D("\236\235\226\242\225\194\206\198\200\201\249\204\223\202\200\217"))
		_0x126.aim = _0x127(_0x12d, _0xS_D("\251\200\206\217\194\223\158\251\204\193\216\200"), _0xS_D("\236\235\226\242\236\196\192\253\194\196\195\217"))
	end
	local _0x12e = ((_0x12.lockActive and (_0x12.lockedTarget ~= nil)) and _0x12.lockValid)
	if (_0x126.active.Value ~= _0x12e) then
		_0x126.active.Value = _0x12e
	end
	local _0x12f = ((_0x12e and _0x12.lockedTarget) or nil)
	if (_0x126.target.Value ~= _0x12f) then
		_0x126.target.Value = _0x12f
	end
	if ((_0x12e and _0x12.aimPoint) and (_0x126.aim.Value ~= _0x12.aimPoint)) then
		_0x126.aim.Value = _0x12.aimPoint
	end
end
local function _0x130(_0x131)
	if (((not _0x12.systemEnabled) or (not _0x131)) or (_0x131 == _0x13)) then
		return false
	end
	if (not _0x29(_0x131)) then
		return false
	end
	_0x12.avatarRequestId = (_0x12.avatarRequestId + 1)
	_0x12.lockedTarget = _0x131
	_0x12.lockActive = true
	_0x5a(_0x131)
	_0x5f()
	_0x72(_0x12.infoGuiParent)
	_0x61()
	return true
end
local function _0x132()
	if (not _0x12.systemEnabled) then
		return
	end
	if (not _0x12.lockActive) then
		local _0x133 = _0x2d()
		if (_0x133 and _0x29(_0x133)) then
			_0x130(_0x133)
		end
	else
		_0x8f()
	end
end
local function _0x134(_0x135)
	_0x11f(_0x135)
	_0x12.guiClock = (_0x12.guiClock + _0x135)
	if (_0x12.guiClock >= _0x12.guiInterval) then
		_0x12.guiClock = 0
		_0x90()
		_0x5f()
	end
	_0x12c()
end
local function _0x136()
	if _0x12.lockConn then
		_0x12.lockConn:Disconnect()
		_0x12.lockConn = nil
	end
	pcall(function()
	_0x2:UnbindFromRenderStep(_0x12.renderName)
end)
	_0x12.lockConn = _0x3.InputBegan:Connect(function(_0x137, _0x138)
	if (((not _0x12.systemEnabled) or _0x138) or _0x9()) then
		return
	end
	if (_0x137.KeyCode == _0x12.lockKey) then
		_0x132()
	end
end)
	_0x12.guiClock = 0
	_0x2:BindToRenderStep(_0x12.renderName, (Enum.RenderPriority.Camera.Value + 1), function(_0x139)
	if (not _0x12.systemEnabled) then
		return
	end
	_0xa(_0xS_D("\236\235\226\242\225\194\206\198"))
	local _0x13a, _0x13b = pcall(_0x134, _0x139)
	_0xb()
	if ((not _0x13a) and (not _0x12.errWarned)) then
		_0x12.errWarned = true
		warn((_0xS_D("\246\236\235\226\141\225\194\206\198\240\141") .. tostring(_0x13b)))
	end
end)
end
local function _0x13c()
	_0x12.systemEnabled = false
	_0x12.avatarRequestId = (_0x12.avatarRequestId + 1)
	if _0x12.lockConn then
		_0x12.lockConn:Disconnect()
		_0x12.lockConn = nil
	end
	pcall(function()
	_0x2:UnbindFromRenderStep(_0x12.renderName)
end)
	_0x8f()
	if _0x12.lockHighlight then
		pcall(function()
	_0x12.lockHighlight:Destroy()
end)
		_0x12.lockHighlight = nil
	end
	_0x12c()
end
local _0x13d = 66
local function _0x13e(_0x13f, _0x140, _0x141, _0x142)
	local _0x143, _0x144, _0x145, _0x146, _0x147 = _0x142.SEC1, _0x142.ACCENT, _0x142.GOLD, _0x142.TEXT, _0x142.SUBTEXT
	local _0x148 = _0x140(_0x13d, _0x143, _0x144)
	_0x148.Parent = _0x13f
	local _0x149 = 22
	local _0x14a = _0x141(_0x148, 8)
	local _0x14b = Instance.new(_0xS_D("\249\200\213\217\225\204\207\200\193"), _0x14a)
	_0x14b.Size = UDim2.new(0, 18, 1, 0)
	_0x14b.Position = UDim2.new(0, 0, 0, 0)
	_0x14b.BackgroundTransparency = 1
	_0x14b.Font = Enum.Font.Legacy
	_0x14b.TextSize = 11
	_0x14b.TextColor3 = _0x145
	_0x14b.Text = _0xS_D("\093\050\035\002")
	_0x14b.TextXAlignment = Enum.TextXAlignment.Center
	_0x14b.TextYAlignment = Enum.TextYAlignment.Center
	local _0x14c = Instance.new(_0xS_D("\249\200\213\217\225\204\207\200\193"), _0x14a)
	_0x14c.Size = UDim2.new(0, 100, 1, 0)
	_0x14c.Position = UDim2.new(0, 22, 0, 0)
	_0x14c.BackgroundTransparency = 1
	_0x14c.Font = Enum.Font.GothamBold
	_0x14c.TextSize = 11
	_0x14c.TextColor3 = _0x146
	_0x14c.Text = (_0xd.lock_label .. (_0xS_D("\141\141\246") .. (_0x12.lockKey.Name .. _0xS_D("\240"))))
	_0x14c.TextXAlignment = Enum.TextXAlignment.Left
	_0x14c.TextYAlignment = Enum.TextYAlignment.Center
	local _0x14d = Instance.new(_0xS_D("\249\200\213\217\225\204\207\200\193"), _0x14a)
	_0x14d.Size = UDim2.new(1, (-128), 1, 0)
	_0x14d.Position = UDim2.new(0, 124, 0, 0)
	_0x14d.BackgroundTransparency = 1
	_0x14d.Font = Enum.Font.Gotham
	_0x14d.TextSize = 9
	_0x14d.TextColor3 = _0x147
	_0x14d.Text = (_0xd.lock_hint_prefix .. _0x12.lockKey.Name)
	_0x14d.TextXAlignment = Enum.TextXAlignment.Right
	_0x14d.TextYAlignment = Enum.TextYAlignment.Center
	_0x12.lockLabels = { label = _0x14c, hint = _0x14d }
	local _0x14e = _0x141(_0x148, ((8 + _0x149) + 6))
	local _0x14f = Instance.new(_0xS_D("\249\200\213\217\239\194\213"), _0x14e)
	_0x14f.Name = _0xS_D("\225\194\206\198\254\200\204\223\206\197\239\194\213")
	_0x14f.Size = UDim2.new(1, 0, 1, 0)
	_0x14f.BackgroundColor3 = Color3.fromRGB(18, 12, 30)
	_0x14f.BorderSizePixel = 0
	_0x14f.Font = Enum.Font.Gotham
	_0x14f.TextSize = 10
	_0x14f.TextColor3 = _0x146
	_0x14f.PlaceholderText = _0xS_D("\231\216\202\204\201\194\223\141\141\111\026\141\141\143\141\221\204\223\204\141\204\221\194\201\194")
	_0x14f.PlaceholderColor3 = _0x147
	_0x14f.Text = _0xS_D("")
	_0x14f.ClearTextOnFocus = false
	_0x14f.ClipsDescendants = true
	_0x14f.TextXAlignment = Enum.TextXAlignment.Left
	Instance.new(_0xS_D("\248\228\238\194\223\195\200\223"), _0x14f).CornerRadius = UDim.new(0, 5)
	local _0x150 = Instance.new(_0xS_D("\248\228\253\204\201\201\196\195\202"), _0x14f)
	_0x150.PaddingLeft = UDim.new(0, 6)
	local _0x151 = Instance.new(_0xS_D("\248\228\254\217\223\194\198\200"), _0x14f)
	_0x151.Thickness = 1
	local _0x152 = Color3.fromRGB(80, 200, 255)
	local _0x153 = 0
	local function _0x154()
		local _0x155, _0x156 = _0x40(_0x14f.Text)
		_0x151.Color = ((_0x156 and _0x152) or _0x144)
		_0x151.Transparency = ((_0x156 and 0.2) or 0.6)
	end
	_0x154()
	local function _0x157(_0x158)
		_0x153 = (_0x153 + 1)
		local _0x159 = _0x153
		_0x151.Color = _0x158
		_0x151.Transparency = 0
		task.delay(0.6, function()
	if ((_0x159 == _0x153) and _0x151.Parent) then
		_0x154()
	end
end)
	end
	_0x14f:GetPropertyChangedSignal(_0xS_D("\249\200\213\217")):Connect(function()
	if _0x14f:IsFocused() then
		_0x154()
	end
end)
	_0x14f.FocusLost:Connect(function(_0x15a)
	if (_0x3e(_0x14f.Text) == _0xS_D("")) then
		_0x154()
		return
	end
	local _0x15b, _0x15c = _0x53(_0x14f.Text)
	if (not _0x15b) then
		_0x157(Color3.fromRGB(255, 80, 80))
		return
	end
	_0x14f.Text = _0x15c
	if _0x15a then
		_0x157(((_0x130(_0x15b) and Color3.fromRGB(80, 255, 150)) or Color3.fromRGB(255, 80, 80)))
	else
		_0x154()
	end
end)
	_0x12.searchBox = _0x14f
	return _0x148
end
local _0x15d = {}
function _0x15d.Start(_0x15e, _0x15f)
	_0x13 = (_0x15e or _0x1.LocalPlayer)
	_0x14 = workspace.CurrentCamera
	if _0x15f then
		_0x12.lockKey = _0x15f
	end
	_0xe()
	_0x12.systemEnabled = true
	_0x136()
end
function _0x15d.Stop()
	_0x13c()
end
function _0x15d.Toggle()
	_0x132()
end
function _0x15d.SetLockKey(_0x160)
	_0x12.lockKey = _0x160
	if _0x12.lockLabels then
		_0x12.lockLabels.label.Text = (_0xd.lock_label .. (_0xS_D("\141\141\246") .. (_0x160.Name .. _0xS_D("\240"))))
		_0x12.lockLabels.hint.Text = (_0xd.lock_hint_prefix .. _0x160.Name)
	end
	if (not _0x12.systemEnabled) then
		return
	end
	if _0x12.lockConn then
		_0x12.lockConn:Disconnect()
		_0x12.lockConn = nil
	end
	_0x12.lockConn = _0x3.InputBegan:Connect(function(_0x161, _0x162)
	if (((not _0x12.systemEnabled) or _0x162) or _0x9()) then
		return
	end
	if (_0x161.KeyCode == _0x12.lockKey) then
		_0x132()
	end
end)
end
function _0x15d.ParseQuery(_0x163)
	return _0x40(_0x163)
end
function _0x15d.AutocompletePlayer(_0x164)
	return _0x53(_0x164)
end
function _0x15d.SearchPlayers(_0x165)
	local _0x166, _0x167 = _0x40(_0x165)
	return _0x46(_0x166, _0x167)
end
function _0x15d.LockOnPlayer(_0x168)
	local _0x169 = _0x168
	if (type(_0x168) == _0xS_D("\222\217\223\196\195\202")) then
		_0x169 = _0x53(_0x168)
	end
	return _0x130(_0x169)
end
function _0x15d.SetAimPart(_0x16a)
	_0x12.aimPart = _0x16a
end
function _0x15d.SetAimOffset(_0x16b)
	_0x12.aimOffset = (_0x16b or Vector3.zero)
end
function _0x15d.SetAimAtCursor(_0x16c)
	_0x12.aimAtCursor = (_0x16c == true)
end
function _0x15d.SetTrackStiffness(_0x16d)
	_0x12.trackStiffness = math.max((tonumber(_0x16d) or 40), 1)
end
function _0x15d.SetTrackBoost(_0x16e)
	_0x12.trackBoost = math.max((tonumber(_0x16e) or 60), 0)
end
function _0x15d.SetProjectileSpeed(_0x16f)
	_0x12.projectileSpeed = math.max((tonumber(_0x16f) or 0), 0)
end
function _0x15d.SetJitterRadius(_0x170)
	_0x12.jitterRadius = math.max((tonumber(_0x170) or 0.6), 0)
end
function _0x15d.SetMaxTurnSpeedDeg(_0x171)
	_0x12.maxTurnSpeed = math.rad(math.max((tonumber(_0x171) or 2000), 1))
end
function _0x15d.GetAimPoint()
	return _0x12.aimPoint
end
function _0x15d.GetLockKey()
	return _0x12.lockKey
end
function _0x15d.IsActive()
	return _0x12.lockActive
end
function _0x15d.GetTarget()
	return _0x12.lockedTarget
end
function _0x15d.IsLockActive()
	return (((_0x12.lockActive == true) and (_0x12.lockedTarget ~= nil)) and _0x29(_0x12.lockedTarget))
end
function _0x15d.GetTargetInfo()
	if (not _0x15d.IsLockActive()) then
		return nil
	end
	return _0x12.lockedTarget
end
function _0x15d.GetTargetHealth()
	if (not _0x15d.IsLockActive()) then
		return 0, 0
	end
	local _0x172 = _0x12.lockedTarget.Character
	local _0x173 = (_0x172 and _0x172:FindFirstChildOfClass(_0xS_D("\229\216\192\204\195\194\196\201")))
	if (not _0x173) then
		return 0, 0
	end
	return math.max(_0x173.Health, 0), math.max(_0x173.MaxHealth, 1)
end
function _0x15d.GetTargetDistance()
	if (not _0x15d.IsLockActive()) then
		return 0
	end
	local _0x174 = (_0x13 and _0x13.Character)
	local _0x175 = (_0x174 and _0x174:FindFirstChild(_0xS_D("\229\216\192\204\195\194\196\201\255\194\194\217\253\204\223\217")))
	local _0x176 = _0x12.lockedTarget.Character
	local _0x177 = (_0x176 and _0x176:FindFirstChild(_0xS_D("\229\216\192\204\195\194\196\201\255\194\194\217\253\204\223\217")))
	if ((not _0x175) or (not _0x177)) then
		return 0
	end
	local _0x178 = ((_0x175.Position - _0x177.Position)).Magnitude
	if _0x5(_0x178) then
		return 0
	end
	return _0x178
end
function _0x15d.GetStatus()
	local _0x179 = _0x15d.IsLockActive()
	local _0x17a, _0x17b = _0x15d.GetTargetHealth()
	return { lockActive = _0x179, target = ((_0x179 and _0x12.lockedTarget) or nil), targetName = ((_0x179 and _0x12.lockedTarget.Name) or _0xS_D("")), targetDisplayName = ((_0x179 and ((_0x12.lockedTarget.DisplayName or _0x12.lockedTarget.Name))) or _0xS_D("")), health = _0x17a, maxHealth = _0x17b, distance = _0x15d.GetTargetDistance() }
end
_0x15d.CreateInfoGui = function(_0x17c)
	if ((_0x12.systemEnabled and _0x12.lockActive) and _0x12.lockedTarget) then
		_0x72(_0x17c)
	end
end
_0x15d.DestroyInfoGui = _0x8e
_0x15d.BuildHUDLockSection = _0x13e
_0x15d.HUD_SECTION_HEIGHT = _0x13d
return _0x15d
