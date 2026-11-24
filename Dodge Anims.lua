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
local _0x3 = game:GetService(_0xS_D("\254\194\216\195\201\254\200\223\219\196\206\200"))
local _0x4 = game:GetService(_0xS_D("\238\194\195\217\200\195\217\253\223\194\219\196\201\200\223"))
local _0x5 = game:GetService(_0xS_D("\233\200\207\223\196\222"))
local _0x6 = game:GetService(_0xS_D("\238\194\193\193\200\206\217\196\194\195\254\200\223\219\196\206\200"))
local _0x7 = ((((type(getgenv) == _0xS_D("\203\216\195\206\217\196\194\195")) and getgenv())) or _G)
do
	local _0x8 = _0x7.__AFO_DodgeAnimStop
	if (type(_0x8) == _0xS_D("\203\216\195\206\217\196\194\195")) then
		pcall(_0x8)
	end
end
local _0x9 = _0x1.LocalPlayer
local _0xa = {}
_0xa.Config = { Dodges = { [1] = { Name = _0xS_D("\233\194\201\202\200\141\156"), AnimationId = _0xS_D("\149\159\152\159\153\157\154\157\149\152\157\154\155\156"), Duration = 0.78 }, [2] = { Name = _0xS_D("\233\194\201\202\200\141\159"), AnimationId = _0xS_D("\148\154\152\159\156\149\149\158\149\148\157\154\149\157"), Duration = 0.70 } }, Chance = 0.5, AnimName = _0xS_D("\225\226\234\234\232\255\242\228\234\227\226\255\232"), Priority = Enum.AnimationPriority.Action4, FadeTime = 0.05, Sound = { Ids = { _0xS_D("\156\157\156\158\154\148\156\155\152\149\157\157\156\149\148"), _0xS_D("\156\157\155\148\158\154\152\155\149\156\156\153\159\156\154"), _0xS_D("\156\158\154\155\155\152\148\157\154\154\153\158\156\157\156"), _0xS_D("\156\157\149\148\159\149\152\152\159\159\155\154\155\158\148"), _0xS_D("\156\158\149\156\153\148\157\153\153\157\149\155\156\149\159") }, Volume = 2, Muted = false }, Ghost = { Enabled = true, MaxActive = 6, SpawnInterval = 0.045, FadeTime = 0.24, HeadAlpha = 0.56, LimbAlpha = 0.36, AccessoryAlpha = 0.34 } }
local _0xb = { token = 0, tracks = {}, running = false, lastIndex = 0, lastSoundId = nil, sfx = nil }
local _0xc = {}
local _0xd = {}
local function _0xe(_0xf, _0x10, _0x11, _0x12)
	local _0x13 = _0xf:FindFirstChild(_0x10)
	if ((not _0x13) or (not _0x13:IsA(_0x11))) then
		if _0x13 then
			_0x13:Destroy()
		end
		_0x13 = Instance.new(_0x11)
		_0x13.Name = _0x10
		_0x13.Parent = _0xf
	end
	_0x13.Value = _0x12
end
local function _0x14()
	local _0x15 = (_0x9 and _0x9.Character)
	if (not _0x15) then
		return
	end
	pcall(function()
	_0xe(_0x15, _0xS_D("\233\194\201\202\200\236\195\196\192\242\236\206\217\196\219\200"), _0xS_D("\239\194\194\193\251\204\193\216\200"), _0xb.running)
	_0xe(_0x15, _0xS_D("\233\194\201\202\200\236\195\196\192\242\228\195\201\200\213"), _0xS_D("\228\195\217\251\204\193\216\200"), _0xb.lastIndex)
end)
end
local function _0x16(_0x17)
	local _0x18 = tostring((_0x17 or _0xS_D(""))):match(_0xS_D("\136\201\134"))
	if (not _0x18) then
		return _0xS_D("")
	end
	return (_0xS_D("\223\207\213\204\222\222\200\217\196\201\151\130\130") .. _0x18)
end
local function _0x19(_0x1a, _0x1b, _0x1c)
	if (_0x1b == _0xS_D("")) then
		return
	end
	task.spawn(function()
	local _0x1d = Instance.new(_0x1a)
	_0x1d[_0x1c] = _0x1b
	pcall(function()
	_0x4:PreloadAsync({ _0x1d })
end)
	_0x1d:Destroy()
end)
end
local function _0x1e()
	local _0x1f = _0xa.Config.Sound.Ids
	for _0x20 = 1, (#_0x1f) do
		_0x19(_0xS_D("\254\194\216\195\201"), _0x16(_0x1f[_0x20]), _0xS_D("\254\194\216\195\201\228\201"))
	end
end
local function _0x21()
	local _0x22 = _0xa.Config.Sound.Ids
	if ((#_0x22) == 0) then
		return
	end
	local _0x23 = _0x22[math.random(1, (#_0x22))]
	local _0x24 = _0x16(_0x23)
	if (_0x24 == _0xS_D("")) then
		return
	end
	_0xb.lastSoundId = _0x23
	if _0xb.sfx then
		local _0x25 = _0xb.sfx
		_0xb.sfx = nil
		pcall(function()
	_0x25:Stop()
	_0x25:Destroy()
end)
	end
	local _0x26 = Instance.new(_0xS_D("\254\194\216\195\201"))
	_0x26.Name = _0xS_D("\236\235\226\242\233\194\201\202\200\236\195\196\192\254\203\213")
	_0x26.SoundId = _0x24
	_0x26.Volume = _0xa.Config.Sound.Volume
	_0x26.Parent = _0x3
	_0xb.sfx = _0x26
	_0x26.Ended:Once(function()
	if (_0xb.sfx == _0x26) then
		_0xb.sfx = nil
	end
	_0x26:Destroy()
end)
	_0x5:AddItem(_0x26, 20)
	_0x26:Play()
end
local function _0x27(_0x28)
	return ((_0x28.PrimaryPart or _0x28:FindFirstChild(_0xS_D("\229\216\192\204\195\194\196\201\255\194\194\217\253\204\223\217"))) or _0x28:FindFirstChild(_0xS_D("\249\194\223\222\194")))
end
local function _0x29(_0x2a)
	local _0x2b = workspace:FindFirstChild(_0xS_D("\224\248\228\238\193\194\195\200"))
	if ((_0x2b and _0x2b:IsA(_0xS_D("\224\194\201\200\193"))) and _0x27(_0x2b)) then
		return _0x2b
	end
	local _0x2c = workspace.CurrentCamera
	local _0x2d = (_0x2c and _0x2c.CameraSubject)
	if ((not _0x2d) or (not _0x2d.Parent)) then
		return _0x2a
	end
	if _0x2d:IsA(_0xS_D("\229\216\192\204\195\194\196\201")) then
		local _0x2e = _0x2d.Parent
		if ((_0x2e ~= _0x2a) and _0x2e:IsA(_0xS_D("\224\194\201\200\193"))) then
			local _0x2f = _0x1:GetPlayerFromCharacter(_0x2e)
			if ((((not _0x2f) or (_0x2f == _0x9))) and _0x27(_0x2e)) then
				return _0x2e
			end
		end
		return _0x2a
	end
	if (_0x2d:IsA(_0xS_D("\239\204\222\200\253\204\223\217")) and (not _0x2d:IsDescendantOf(_0x2a))) then
		local _0x30, _0x31 = nil, 25
		for _0x32, _0x33 in ipairs(workspace:GetChildren()) do
			if (((_0x33:IsA(_0xS_D("\224\194\201\200\193")) and (_0x33 ~= _0x2a)) and (_0x33.Name == _0x2a.Name)) and (not _0x1:GetPlayerFromCharacter(_0x33))) then
				local _0x34 = _0x27(_0x33)
				if _0x34 then
					local _0x35 = ((_0x34.Position - _0x2d.Position)).Magnitude
					if (_0x35 < _0x31) then
						_0x30, _0x31 = _0x33, _0x35
					end
				end
			end
		end
		if _0x30 then
			return _0x30
		end
	end
	return _0x2a
end
local function _0x36(_0x37, _0x38)
	if (not _0x37) then
		return nil
	end
	local _0x39 = _0x37:FindFirstChildOfClass(_0xS_D("\229\216\192\204\195\194\196\201"))
	if (not _0x39) then
		return nil
	end
	local _0x3a = _0x39:FindFirstChildOfClass(_0xS_D("\236\195\196\192\204\217\194\223"))
	if ((not _0x3a) and _0x38) then
		_0x3a = Instance.new(_0xS_D("\236\195\196\192\204\217\194\223"))
		_0x3a.Parent = _0x39
	end
	return _0x3a
end
local function _0x3b(_0x3c, _0x3d, _0x3e, _0x3f)
	local _0x40
	local _0x41
	if _0x3f then
		_0x40 = _0xc[_0x3c]
		if (not _0x40) then
			_0x40 = {}
			_0xc[_0x3c] = _0x40
		end
		_0x41 = _0x40[_0x3d]
	end
	if (not _0x41) then
		local _0x42 = Instance.new(_0xS_D("\236\195\196\192\204\217\196\194\195"))
		_0x42.Name = _0xa.Config.AnimName
		_0x42.AnimationId = (_0xS_D("\223\207\213\204\222\222\200\217\196\201\151\130\130") .. _0x3e.AnimationId)
		local _0x43, _0x44 = pcall(function()
	return _0x3c:LoadAnimation(_0x42)
end)
		if ((not _0x43) or (not _0x44)) then
			return nil
		end
		_0x41 = _0x44
		if _0x40 then
			_0x40[_0x3d] = _0x41
		end
	end
	_0x41:Stop(0)
	_0x41.TimePosition = 0
	_0x41.Looped = false
	if _0xa.Config.Priority then
		_0x41.Priority = _0xa.Config.Priority
	end
	_0x41:Play(_0xa.Config.FadeTime)
	if (not _0x3f) then
		_0x41.Stopped:Once(function()
	pcall(function()
	_0x41:Destroy()
end)
end)
	end
	return _0x41
end
local function _0x45()
	for _0x46 = 1, (#_0xb.tracks) do
		local _0x47 = _0xb.tracks[_0x46]
		pcall(function()
	_0x47:Stop(0.1)
end)
	end
	table.clear(_0xb.tracks)
end
local _0x48 = { folder = nil, model = nil, builtAt = 0, dirty = false, slots = {}, free = {}, active = {}, watch = {}, conn = nil, windowEnd = 0, acc = 0, lastBody = nil, lastBodyAt = 0, warned = false }
local _0x49 = { _0xS_D("\225\216\204\254\194\216\223\206\200\238\194\195\217\204\196\195\200\223"), _0xS_D("\236\195\196\192\204\217\194\223"), _0xS_D("\254\194\216\195\201"), _0xS_D("\225\196\202\197\217"), _0xS_D("\253\204\223\217\196\206\193\200\232\192\196\217\217\200\223"), _0xS_D("\249\223\204\196\193"), _0xS_D("\239\200\204\192"), _0xS_D("\235\196\223\200"), _0xS_D("\254\192\194\198\200"), _0xS_D("\254\221\204\223\198\193\200\222"), _0xS_D("\229\196\202\197\193\196\202\197\217"), _0xS_D("\254\200\193\200\206\217\196\194\195\239\194\213"), _0xS_D("\239\196\193\193\207\194\204\223\201\234\216\196"), _0xS_D("\254\216\223\203\204\206\200\234\216\196"), _0xS_D("\231\194\196\195\217\228\195\222\217\204\195\206\200"), _0xS_D("\250\200\193\201\238\194\195\222\217\223\204\196\195\217"), _0xS_D("\238\194\195\222\217\223\204\196\195\217"), _0xS_D("\236\217\217\204\206\197\192\200\195\217"), _0xS_D("\235\194\223\206\200\235\196\200\193\201"), _0xS_D("\239\194\201\212\224\194\219\200\223"), _0xS_D("\238\193\196\206\198\233\200\217\200\206\217\194\223"), _0xS_D("\253\223\194\213\196\192\196\217\212\253\223\194\192\221\217"), _0xS_D("\251\204\193\216\200\239\204\222\200") }
local function _0x4a(_0x4b)
	for _0x4c = 1, (#_0x49) do
		if _0x4b:IsA(_0x49[_0x4c]) then
			return true
		end
	end
	return false
end
local function _0x4d(_0x4e, _0x4f)
	if (_0x4e >= 0.99) then
		return 1
	end
	local _0x50 = (((1 - _0x4e)) * ((1 - math.clamp(_0x4f, 0, 0.95))))
	return math.clamp((1 - _0x50), 0, 0.96)
end
local function _0x51(_0x52)
	local _0x53 = _0xa.Config.Ghost
	if _0x52:FindFirstAncestorOfClass(_0xS_D("\236\206\206\200\222\222\194\223\212")) then
		return _0x53.AccessoryAlpha
	end
	if (_0x52.Name == _0xS_D("\229\200\204\201")) then
		return _0x53.HeadAlpha
	end
	return _0x53.LimbAlpha
end
local function _0x54(_0x55, _0x56, _0x57)
	local _0x58 = {}
	local _0x59 = _0x55:GetChildren()
	for _0x5a = 1, (#_0x59) do
		local _0x5b = _0x59[_0x5a]
		local _0x5c = (_0x5b.ClassName .. (_0xS_D("\209") .. _0x5b.Name))
		local _0x5d = _0x58[_0x5c]
		if (not _0x5d) then
			_0x5d = {}
			_0x58[_0x5c] = _0x5d
		end
		_0x5d[((#_0x5d) + 1)] = _0x5b
	end
	local _0x5e = {}
	local _0x5f = _0x56:GetChildren()
	for _0x60 = 1, (#_0x5f) do
		local _0x61 = _0x5f[_0x60]
		local _0x62 = (_0x61.ClassName .. (_0xS_D("\209") .. _0x61.Name))
		local _0x63 = (((_0x5e[_0x62] or 0)) + 1)
		_0x5e[_0x62] = _0x63
		local _0x64 = _0x58[_0x62]
		local _0x65 = (_0x64 and _0x64[_0x63])
		if _0x65 then
			if (_0x61:IsA(_0xS_D("\239\204\222\200\253\204\223\217")) or _0x61:IsA(_0xS_D("\233\200\206\204\193"))) then
				_0x57[((#_0x57) + 1)] = { _0x65, _0x61 }
			end
			_0x54(_0x65, _0x61, _0x57)
		end
	end
end
local function _0x66(_0x67)
	pcall(function()
	for _0x68, _0x69 in ipairs(_0x6:GetTags(_0x67)) do
		_0x6:RemoveTag(_0x67, _0x69)
	end
	for _0x6a in pairs(_0x67:GetAttributes()) do
		_0x67:SetAttribute(_0x6a, nil)
	end
end)
end
local function _0x6b(_0x6c)
	_0x6c.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	_0x6c.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	_0x6c.BreakJointsOnDeath = false
	_0x6c.RequiresNeck = false
	_0x6c.EvaluateStateMachine = false
	_0x6c.AutoRotate = false
	_0x6c.WalkSpeed = 0
	_0x6c.Health = 0
end
local function _0x6d(_0x6e)
	local _0x6f = _0x6e.Archivable
	pcall(function()
	_0x6e.Archivable = true
end)
	local _0x70, _0x71 = pcall(function()
	return _0x6e:Clone()
end)
	pcall(function()
	_0x6e.Archivable = _0x6f
end)
	if ((not _0x70) or (not _0x71)) then
		return nil
	end
	_0x71.Name = _0xS_D("\236\235\226\242\233\194\201\202\200\234\197\194\222\217")
	local _0x72 = {}
	_0x54(_0x6e, _0x71, _0x72)
	_0x66(_0x71)
	local _0x73 = _0x71:GetDescendants()
	for _0x74 = 1, (#_0x73) do
		local _0x75 = _0x73[_0x74]
		if _0x75:IsA(_0xS_D("\229\216\192\204\195\194\196\201")) then
			pcall(_0x6b, _0x75)
			_0x66(_0x75)
		elseif _0x4a(_0x75) then
			_0x75:Destroy()
		else
			_0x66(_0x75)
		end
	end
	local _0x76, _0x77 = {}, {}
	for _0x78 = 1, (#_0x72) do
		local _0x79, _0x7a = _0x72[_0x78][1], _0x72[_0x78][2]
		if _0x7a:IsDescendantOf(_0x71) then
			if _0x7a:IsA(_0xS_D("\239\204\222\200\253\204\223\217")) then
				if (_0x79.Transparency >= 0.99) then
					if (_0x7a.Name == _0xS_D("\229\216\192\204\195\194\196\201\255\194\194\217\253\204\223\217")) then
						_0x7a.Anchored = true
						_0x7a.CanCollide = false
						_0x7a.CanTouch = false
						_0x7a.CanQuery = false
						_0x7a.CastShadow = false
					else
						_0x7a:Destroy()
					end
				else
					_0x7a.Anchored = true
					_0x7a.CanCollide = false
					_0x7a.CanTouch = false
					_0x7a.CanQuery = false
					_0x7a.Massless = true
					_0x7a.CastShadow = false
					_0x76[((#_0x76) + 1)] = { src = _0x79, dst = _0x7a, startT = _0x4d(_0x79.Transparency, _0x51(_0x7a)) }
				end
			elseif ((_0x7a:IsA(_0xS_D("\233\200\206\204\193")) and (_0x79.Transparency < 0.99)) and _0x7a.Parent) then
				_0x77[((#_0x77) + 1)] = { dst = _0x7a, startT = _0x4d(_0x79.Transparency, _0x51(_0x7a.Parent)) }
			end
		end
	end
	if ((#_0x76) == 0) then
		_0x71:Destroy()
		return nil
	end
	return { model = _0x71, parts = _0x76, decals = _0x77 }
end
local function _0x7b(_0x7c)
	local _0x7d = _0x7c.parts
	for _0x7e = 1, (#_0x7d) do
		local _0x7f = _0x7d[_0x7e]
		local _0x80 = _0x7f.src
		if _0x80.Parent then
			_0x7f.dst.CFrame = _0x80.CFrame
			_0x7f.dst.Transparency = _0x7f.startT
		else
			_0x7f.dst.Transparency = 1
		end
	end
	local _0x81 = _0x7c.decals
	for _0x82 = 1, (#_0x81) do
		local _0x83 = _0x81[_0x82]
		_0x83.dst.Transparency = _0x83.startT
	end
end
local function _0x84()
	if (_0x48.folder and _0x48.folder.Parent) then
		return _0x48.folder
	end
	local _0x85 = Instance.new(_0xS_D("\235\194\193\201\200\223"))
	_0x85.Name = _0xS_D("\236\235\226\242\233\194\201\202\200\234\197\194\222\217\222")
	_0x85.Parent = workspace
	_0x48.folder = _0x85
	return _0x85
end
local function _0x86()
	for _0x87 = 1, (#_0x48.watch) do
		local _0x88 = _0x48.watch[_0x87]
		pcall(function()
	_0x88:Disconnect()
end)
	end
	table.clear(_0x48.watch)
end
local function _0x89()
	_0x86()
	for _0x8a = 1, (#_0x48.slots) do
		local _0x8b = _0x48.slots[_0x8a]
		pcall(function()
	_0x8b.model:Destroy()
end)
	end
	table.clear(_0x48.slots)
	table.clear(_0x48.free)
	table.clear(_0x48.active)
	_0x48.model = nil
	_0x48.dirty = false
end
local function _0x8c(_0x8d, _0x8e)
	return (((((_0x8d:IsA(_0xS_D("\236\206\206\200\222\222\194\223\212")) or _0x8d:IsA(_0xS_D("\238\193\194\217\197\196\195\202"))) or _0x8d:IsA(_0xS_D("\254\197\196\223\217\234\223\204\221\197\196\206"))) or _0x8d:IsA(_0xS_D("\238\197\204\223\204\206\217\200\223\224\200\222\197"))) or _0x8d:IsA(_0xS_D("\239\194\201\212\238\194\193\194\223\222"))) or ((_0x8d:IsA(_0xS_D("\239\204\222\200\253\204\223\217")) and (_0x8d.Parent == _0x8e))))
end
local function _0x8f(_0x90)
	_0x48.watch[((#_0x48.watch) + 1)] = _0x90.DescendantAdded:Connect(function(_0x91)
	if _0x8c(_0x91, _0x90) then
		_0x48.dirty = true
	end
end)
	_0x48.watch[((#_0x48.watch) + 1)] = _0x90.DescendantRemoving:Connect(function(_0x92)
	if _0x8c(_0x92, _0x90) then
		_0x48.dirty = true
	end
end)
end
local function _0x93(_0x94)
	local _0x95 = _0xa.Config.Ghost
	local _0x96 = os.clock()
	if ((_0x48.model ~= _0x94) or ((_0x48.dirty and ((_0x96 - _0x48.builtAt) > 1)))) then
		_0x89()
		_0x48.model = _0x94
		_0x48.builtAt = _0x96
		_0x8f(_0x94)
	end
	local _0x97 = table.remove(_0x48.free)
	if (not _0x97) then
		if ((#_0x48.slots) < _0x95.MaxActive) then
			_0x97 = _0x6d(_0x94)
			if (not _0x97) then
				return
			end
			_0x48.slots[((#_0x48.slots) + 1)] = _0x97
		else
			local _0x98 = table.remove(_0x48.active, 1)
			if (not _0x98) then
				return
			end
			_0x97 = _0x98.slot
		end
	end
	_0x7b(_0x97)
	_0x97.model.Parent = _0x84()
	_0x48.active[((#_0x48.active) + 1)] = { slot = _0x97, elapsed = 0 }
end
local function _0x99(_0x9a)
	local _0x9b = _0xa.Config.Ghost.FadeTime
	local _0x9c = _0x48.active
	for _0x9d = (#_0x9c), 1, (-1) do
		local _0x9e = _0x9c[_0x9d]
		_0x9e.elapsed += _0x9a
		local _0x9f = (_0x9e.elapsed / _0x9b)
		if (_0x9f >= 1) then
			table.remove(_0x9c, _0x9d)
			local _0xa0 = _0x9e.slot.model
			pcall(function()
	_0xa0.Parent = nil
end)
			_0x48.free[((#_0x48.free) + 1)] = _0x9e.slot
		else
			local _0xa1 = (1 - (((1 - _0x9f)) * ((1 - _0x9f))))
			local _0xa2 = _0x9e.slot.parts
			for _0xa3 = 1, (#_0xa2) do
				local _0xa4 = _0xa2[_0xa3]
				_0xa4.dst.Transparency = (_0xa4.startT + (((1 - _0xa4.startT)) * _0xa1))
			end
			local _0xa5 = _0x9e.slot.decals
			for _0xa6 = 1, (#_0xa5) do
				local _0xa7 = _0xa5[_0xa6]
				_0xa7.dst.Transparency = (_0xa7.startT + (((1 - _0xa7.startT)) * _0xa1))
			end
		end
	end
end
local function _0xa8(_0xa9)
	local _0xaa = os.clock()
	if ((_0x48.lastBody and _0x48.lastBody.Parent) and ((_0xaa - _0x48.lastBodyAt) < 0.2)) then
		return _0x48.lastBody
	end
	local _0xab = _0x29(_0xa9)
	_0x48.lastBody = _0xab
	_0x48.lastBodyAt = _0xaa
	return _0xab
end
local function _0xac(_0xad)
	_0x99(_0xad)
	if (os.clock() < _0x48.windowEnd) then
		_0x48.acc += _0xad
		if (_0x48.acc >= _0xa.Config.Ghost.SpawnInterval) then
			_0x48.acc = 0
			local _0xae = _0x9.Character
			if _0xae then
				local _0xaf = _0xa8(_0xae)
				if _0xaf then
					local _0xb0, _0xb1 = pcall(_0x93, _0xaf)
					if ((not _0xb0) and (not _0x48.warned)) then
						_0x48.warned = true
						warn((_0xS_D("\246\233\194\201\202\200\141\236\195\196\192\222\240\141\203\204\195\217\204\222\192\204\141\203\204\193\193\110\030\141\133\222\200\141\196\202\195\194\223\204\132\151\141") .. tostring(_0xb1)))
					end
				end
			end
		end
	elseif (((#_0x48.active) == 0) and _0x48.conn) then
		_0x48.conn:Disconnect()
		_0x48.conn = nil
	end
end
local function _0xb2(_0xb3)
	if (not _0xa.Config.Ghost.Enabled) then
		return
	end
	_0x48.windowEnd = (os.clock() + _0xb3)
	_0x48.acc = _0xa.Config.Ghost.SpawnInterval
	if (not _0x48.conn) then
		_0x48.conn = _0x2.Heartbeat:Connect(_0xac)
	end
end
local function _0xb4(_0xb5)
	return ((_0xb5 == true) or (((type(_0xb5) == _0xS_D("\222\217\223\196\195\202")) and (_0xb5:lower() == _0xS_D("\192\216\217\200")))))
end
local function _0xb6(_0xb7)
	if ((_0xb7 == 1) or (_0xb7 == _0xS_D("\156"))) then
		return 1
	end
	if ((_0xb7 == 2) or (_0xb7 == _0xS_D("\159"))) then
		return 2
	end
	return _0xS_D("\223\204\195\201\194\192")
end
local function _0xb8(_0xb9, _0xba)
	local _0xbb, _0xbc = _0xS_D("\223\204\195\201\194\192"), nil
	if (type(_0xb9) == _0xS_D("\217\204\207\193\200")) then
		_0xbb = _0xb6(_0xb9.Mode)
		if _0xb4(_0xb9.Mute) then
			_0xbc = true
		end
	else
		_0xbb = _0xb6(_0xb9)
		if _0xb4(_0xb9) then
			_0xbc = true
		end
	end
	if _0xb4(_0xba) then
		_0xbc = true
	end
	return _0xbb, _0xbc
end
local function _0xbd(_0xbe)
	if ((_0xbe == 1) or (_0xbe == 2)) then
		return _0xbe
	end
	return ((((math.random() < _0xa.Config.Chance)) and 1) or 2)
end
function _0xa.Run(_0xbf, _0xc0)
	local _0xc1, _0xc2 = _0xb8(_0xbf, _0xc0)
	local _0xc3 = (_0x9 and _0x9.Character)
	local _0xc4 = (_0xc3 and _0xc3:FindFirstChildOfClass(_0xS_D("\229\216\192\204\195\194\196\201")))
	if ((not _0xc4) or (_0xc4.Health <= 0)) then
		return false
	end
	local _0xc5 = _0xbd(_0xc1)
	local _0xc6 = _0xa.Config.Dodges[_0xc5]
	local _0xc7 = _0x36(_0xc3, true)
	if (not _0xc7) then
		return false
	end
	_0xb.token += 1
	local _0xc8 = _0xb.token
	_0x45()
	local _0xc9 = _0x3b(_0xc7, _0xc5, _0xc6, true)
	if (not _0xc9) then
		_0xb.running = false
		_0x14()
		return false
	end
	table.clear(_0xb.tracks)
	_0xb.tracks[1] = _0xc9
	local _0xca = _0x29(_0xc3)
	if ((_0xca and (_0xca ~= _0xc3)) and (_0xca.Name ~= _0xS_D("\224\248\228\238\193\194\195\200"))) then
		local _0xcb = _0x36(_0xca, true)
		if _0xcb then
			local _0xcc = _0x3b(_0xcb, _0xc5, _0xc6, false)
			if _0xcc then
				_0xb.tracks[((#_0xb.tracks) + 1)] = _0xcc
			end
		end
	end
	if (not ((_0xc2 or _0xa.Config.Sound.Muted))) then
		_0x21()
	end
	_0xb2(_0xc6.Duration)
	_0xb.running = true
	_0xb.lastIndex = _0xc5
	_0x14()
	task.delay(_0xc6.Duration, function()
	if (_0xb.token ~= _0xc8) then
		return
	end
	_0xb.running = false
	_0x14()
end)
	return true, _0xc5
end
function _0xa.Cancel()
	_0xb.token += 1
	_0x45()
	_0x48.windowEnd = 0
	_0xb.running = false
	_0x14()
end
function _0xa.SetMute(_0xcd)
	_0xa.Config.Sound.Muted = ((((_0xcd == nil)) and true) or ((_0xcd == true)))
end
function _0xa.IsMuted()
	return _0xa.Config.Sound.Muted
end
function _0xa.SetSound(_0xce)
	local _0xcf = {}
	if (type(_0xce) == _0xS_D("\217\204\207\193\200")) then
		for _0xd0, _0xd1 in ipairs(_0xce) do
			local _0xd2 = tostring(_0xd1):match(_0xS_D("\136\201\134"))
			if _0xd2 then
				_0xcf[((#_0xcf) + 1)] = _0xd2
			end
		end
	else
		local _0xd3 = tostring((_0xce or _0xS_D(""))):match(_0xS_D("\136\201\134"))
		if _0xd3 then
			_0xcf[1] = _0xd3
		end
	end
	_0xa.Config.Sound.Ids = _0xcf
	_0x1e()
end
function _0xa.SetGhost(_0xd4)
	_0xa.Config.Ghost.Enabled = ((_0xd4 == true))
	if (not _0xa.Config.Ghost.Enabled) then
		_0x48.windowEnd = 0
	end
end
function _0xa.GetStatus()
	local _0xd5 = _0xa.Config.Dodges[_0xb.lastIndex]
	return { running = _0xb.running, lastIndex = _0xb.lastIndex, lastName = ((_0xd5 and _0xd5.Name) or nil), muted = _0xa.Config.Sound.Muted, ghost = _0xa.Config.Ghost.Enabled, soundIds = _0xa.Config.Sound.Ids, lastSoundId = _0xb.lastSoundId }
end
local function _0xd6(_0xd7, _0xd8)
	return _0xa.Run(_0xd7, _0xd8)
end
function _0xa.Destroy()
	pcall(_0xa.Cancel)
	if _0x48.conn then
		_0x48.conn:Disconnect()
		_0x48.conn = nil
	end
	_0x89()
	if _0x48.folder then
		pcall(function()
	_0x48.folder:Destroy()
end)
		_0x48.folder = nil
	end
	for _0xd9 = 1, (#_0xd) do
		local _0xda = _0xd[_0xd9]
		pcall(function()
	_0xda:Disconnect()
end)
	end
	table.clear(_0xd)
	table.clear(_0xc)
	local _0xdb = (_0x9 and _0x9.Character)
	if _0xdb then
		for _0xdc, _0xdd in ipairs({ _0xS_D("\233\194\201\202\200\236\195\196\192\242\236\206\217\196\219\200"), _0xS_D("\233\194\201\202\200\236\195\196\192\242\228\195\201\200\213") }) do
			local _0xde = _0xdb:FindFirstChild(_0xdd)
			if _0xde then
				pcall(function()
	_0xde:Destroy()
end)
			end
		end
	end
	if _0xb.sfx then
		pcall(function()
	_0xb.sfx:Destroy()
end)
		_0xb.sfx = nil
	end
	if (_0x7.AFO_DodgeAnim_API == _0xa) then
		_0x7.AFO_DodgeAnim_API = nil
	end
	if (_0x7.Run_Dodgeanim == _0xd6) then
		_0x7.Run_Dodgeanim = nil
	end
end
table.insert(_0xd, _0x9.CharacterAdded:Connect(function()
	table.clear(_0xc)
	table.clear(_0xb.tracks)
	_0xb.running = false
	_0x48.lastBody = nil
end))
_0x1e()
for _0xdf = 1, (#_0xa.Config.Dodges) do
	_0x19(_0xS_D("\236\195\196\192\204\217\196\194\195"), (_0xS_D("\223\207\213\204\222\222\200\217\196\201\151\130\130") .. _0xa.Config.Dodges[_0xdf].AnimationId), _0xS_D("\236\195\196\192\204\217\196\194\195\228\201"))
end
_0x7.AFO_DodgeAnim_API = _0xa
_0x7.Run_Dodgeanim = _0xd6
_0x7.__AFO_DodgeAnimStop = function()
	_0xa.Destroy()
end
return _0xa
