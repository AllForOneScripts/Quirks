local _0xS_K = 173
local function _0xS_D(s)
	local r = {}
	for i = 1, #s do
		r[i] = string.char(bit32.bxor(string.byte(s, i), _0xS_K))
	end
	return table.concat(r)
end
print(_0xS_D("\253\223\216\200\207\204\141\222\196\195\141\194\203\216\222\206\204\223"))
local _0x1 = {}
local _0x2 = {}
local _0x3 = game:GetService(_0xS_D("\253\193\204\212\200\223\222"))
local _0x4 = game:GetService(_0xS_D("\248\222\200\223\228\195\221\216\217\254\200\223\219\196\206\200"))
local _0x5 = game:GetService(_0xS_D("\249\218\200\200\195\254\200\223\219\196\206\200"))
local _0x6 = game:GetService(_0xS_D("\238\194\195\217\200\195\217\253\223\194\219\196\201\200\223"))
local _0x7 = game:GetService(_0xS_D("\255\216\195\254\200\223\219\196\206\200"))
local _0x8 = game:GetService(_0xS_D("\249\200\213\217\254\200\223\219\196\206\200"))
local _0x9 = game:GetService(_0xS_D("\233\200\207\223\196\222"))
local _0xa = game:GetService(_0xS_D("\254\194\216\195\201\254\200\223\219\196\206\200"))
local _0xb = game:GetService(_0xS_D("\225\194\206\204\193\196\215\204\217\196\194\195\254\200\223\219\196\206\200"))
local _0xc
local _0xd
local _0xe = false
local _0xf = {}
local _0x10
local _0x11
local _0x12
local _0x13 = false
local _0x14
local _0x15 = Enum.KeyCode.F4
local _0x16 = nil
local _0x17 = 0
local _0x18 = false
local _0x19 = nil
local _0x1a = {}
local _0x1b = setmetatable({}, { __mode = _0xS_D("\198") })
local _0x1c = setmetatable({}, { __mode = _0xS_D("\198") })
local _0x1d = setmetatable({}, { __mode = _0xS_D("\198") })
local _0x1e = true
local _0x1f = 0
_0x2.C_PURPLE = Color3.fromRGB(110, 30, 180)
_0x2.C_BLACK = Color3.fromRGB(6, 4, 12)
_0x2.C_TEXT = Color3.fromRGB(220, 190, 255)
_0x2.C_SUB = Color3.fromRGB(200, 170, 255)
_0x2.C_BOX = Color3.fromRGB(20, 10, 40)
_0x2.PANEL_W, _0x2.PANEL_H = 360, 190
_0x2.BOX_W = 190
_0x2.MAX_TEXT, _0x2.MIN_TEXT = 14, 11
_0x2.MAX_RESULTS = 12
_0x2.ROW_H = 52
_0x2.MENU_MAX_ROWS = 3
_0x2.GRAY_A = Color3.fromRGB(125, 127, 134)
_0x2.GRAY_B = Color3.fromRGB(208, 210, 218)
_0x2.GRAY_NAME = _0xS_D("\236\235\226\242\234\223\204\212\225\204\212\200\223")
_0x2.BODY_COLOR_MAP = { [_0xS_D("\229\200\204\201")] = _0xS_D("\229\200\204\201\238\194\193\194\223\158"), [_0xS_D("\249\194\223\222\194")] = _0xS_D("\249\194\223\222\194\238\194\193\194\223\158"), [_0xS_D("\248\221\221\200\223\249\194\223\222\194")] = _0xS_D("\249\194\223\222\194\238\194\193\194\223\158"), [_0xS_D("\225\194\218\200\223\249\194\223\222\194")] = _0xS_D("\249\194\223\222\194\238\194\193\194\223\158"), [_0xS_D("\225\200\203\217\141\236\223\192")] = _0xS_D("\225\200\203\217\236\223\192\238\194\193\194\223\158"), [_0xS_D("\225\200\203\217\248\221\221\200\223\236\223\192")] = _0xS_D("\225\200\203\217\236\223\192\238\194\193\194\223\158"), [_0xS_D("\225\200\203\217\225\194\218\200\223\236\223\192")] = _0xS_D("\225\200\203\217\236\223\192\238\194\193\194\223\158"), [_0xS_D("\225\200\203\217\229\204\195\201")] = _0xS_D("\225\200\203\217\236\223\192\238\194\193\194\223\158"), [_0xS_D("\255\196\202\197\217\141\236\223\192")] = _0xS_D("\255\196\202\197\217\236\223\192\238\194\193\194\223\158"), [_0xS_D("\255\196\202\197\217\248\221\221\200\223\236\223\192")] = _0xS_D("\255\196\202\197\217\236\223\192\238\194\193\194\223\158"), [_0xS_D("\255\196\202\197\217\225\194\218\200\223\236\223\192")] = _0xS_D("\255\196\202\197\217\236\223\192\238\194\193\194\223\158"), [_0xS_D("\255\196\202\197\217\229\204\195\201")] = _0xS_D("\255\196\202\197\217\236\223\192\238\194\193\194\223\158"), [_0xS_D("\225\200\203\217\141\225\200\202")] = _0xS_D("\225\200\203\217\225\200\202\238\194\193\194\223\158"), [_0xS_D("\225\200\203\217\248\221\221\200\223\225\200\202")] = _0xS_D("\225\200\203\217\225\200\202\238\194\193\194\223\158"), [_0xS_D("\225\200\203\217\225\194\218\200\223\225\200\202")] = _0xS_D("\225\200\203\217\225\200\202\238\194\193\194\223\158"), [_0xS_D("\225\200\203\217\235\194\194\217")] = _0xS_D("\225\200\203\217\225\200\202\238\194\193\194\223\158"), [_0xS_D("\255\196\202\197\217\141\225\200\202")] = _0xS_D("\255\196\202\197\217\225\200\202\238\194\193\194\223\158"), [_0xS_D("\255\196\202\197\217\248\221\221\200\223\225\200\202")] = _0xS_D("\255\196\202\197\217\225\200\202\238\194\193\194\223\158"), [_0xS_D("\255\196\202\197\217\225\194\218\200\223\225\200\202")] = _0xS_D("\255\196\202\197\217\225\200\202\238\194\193\194\223\158"), [_0xS_D("\255\196\202\197\217\235\194\194\217")] = _0xS_D("\255\196\202\197\217\225\200\202\238\194\193\194\223\158") }
_0x2.ANIM_MAP = { { _0xS_D("\196\201\193\200"), _0xS_D("\236\195\196\192\204\217\196\194\195\156"), _0xS_D("\228\201\193\200\236\195\196\192\204\217\196\194\195") }, { _0xS_D("\196\201\193\200"), _0xS_D("\236\195\196\192\204\217\196\194\195\159"), _0xS_D("\228\201\193\200\236\195\196\192\204\217\196\194\195") }, { _0xS_D("\218\204\193\198"), _0xS_D("\250\204\193\198\236\195\196\192"), _0xS_D("\250\204\193\198\236\195\196\192\204\217\196\194\195") }, { _0xS_D("\223\216\195"), _0xS_D("\255\216\195\236\195\196\192"), _0xS_D("\255\216\195\236\195\196\192\204\217\196\194\195") }, { _0xS_D("\199\216\192\221"), _0xS_D("\231\216\192\221\236\195\196\192"), _0xS_D("\231\216\192\221\236\195\196\192\204\217\196\194\195") }, { _0xS_D("\203\204\193\193"), _0xS_D("\235\204\193\193\236\195\196\192"), _0xS_D("\235\204\193\193\236\195\196\192\204\217\196\194\195") }, { _0xS_D("\206\193\196\192\207"), _0xS_D("\238\193\196\192\207\236\195\196\192"), _0xS_D("\238\193\196\192\207\236\195\196\192\204\217\196\194\195") }, { _0xS_D("\222\218\196\192"), _0xS_D("\254\218\196\192"), _0xS_D("\254\218\196\192\236\195\196\192\204\217\196\194\195") } }
_0x2.GUARD_SECONDS = 6
_0x2.GUARD_INTERVAL = 0.35
_0x2.MAX_REPAIRS = 3
_0x2.USE_APPLY_DESCRIPTION_R6 = false
_0x2.DEATH_WINDOW = 8
_0x2.MAX_DEATH_STRIKES = 2
_0x2.DESCRIPTION_TIMEOUT = 20
_0x2.HIP_FOLLOW_RATE = 10
local function _0x20(_0x21)
	return math.clamp(_0x21, 0, 1)
end
local function _0x22(_0x23)
	_0x23 = _0x20(_0x23)
	return (0.5 - (0.5 * math.cos((math.pi * _0x23))))
end
local function _0x24()
	for _0x25, _0x26 in ipairs(_0xf) do
		if (_0x26 and _0x26.Connected) then
			_0x26:Disconnect()
		end
	end
	table.clear(_0xf)
end
local function _0x27(_0x28, _0x29, ...)
	local _0x2a = table.pack(...)
	for _0x2b, _0x2c in ipairs(_0x29) do
		local _0x2d, _0x2e = pcall(function()
	return _0x28[_0x2c](_0x28, table.unpack(_0x2a, 1, _0x2a.n))
end)
		if (_0x2d and (_0x2e ~= nil)) then
			return _0x2e
		end
	end
	return nil
end
local function _0x2f(_0x30)
	return ((_0x30:match(_0xS_D("\243\136\222\135\133\131\128\132\136\222\135\137"))) or _0xS_D(""))
end
_0x2.R15_NAMES = { _0xS_D("\248\221\221\200\223\249\194\223\222\194"), _0xS_D("\225\194\218\200\223\249\194\223\222\194"), _0xS_D("\225\200\203\217\248\221\221\200\223\236\223\192"), _0xS_D("\255\196\202\197\217\248\221\221\200\223\236\223\192"), _0xS_D("\225\200\203\217\248\221\221\200\223\225\200\202"), _0xS_D("\255\196\202\197\217\248\221\221\200\223\225\200\202") }
_0x2.R6_NAMES = { _0xS_D("\249\194\223\222\194"), _0xS_D("\225\200\203\217\141\236\223\192"), _0xS_D("\255\196\202\197\217\141\236\223\192"), _0xS_D("\225\200\203\217\141\225\200\202"), _0xS_D("\255\196\202\197\217\141\225\200\202") }
local function _0x31(_0x32)
	return ((_0x32:FindFirstAncestorWhichIsA(_0xS_D("\236\206\206\200\222\222\194\223\212")) ~= nil) or (_0x32:FindFirstAncestorWhichIsA(_0xS_D("\249\194\194\193")) ~= nil))
end
local function _0x33(_0x34)
	local _0x35 = {}
	for _0x36, _0x37 in ipairs(_0x34:GetDescendants()) do
		if (_0x37:IsA(_0xS_D("\239\204\222\200\253\204\223\217")) and (not _0x31(_0x37))) then
			_0x35[_0x37.Name] = true
		end
	end
	return _0x35
end
local function _0x38(_0x39, _0x3a)
	local _0x3b = _0x39:FindFirstChild(_0xS_D("\229\216\192\204\195\194\196\201\255\194\194\217\253\204\223\217"))
	if (_0x3b and _0x3b:IsA(_0xS_D("\239\204\222\200\253\204\223\217"))) then
		for _0x3c, _0x3d in ipairs(_0x39:GetDescendants()) do
			if _0x3d:IsA(_0xS_D("\224\194\217\194\223\155\233")) then
				local _0x3e
				if (_0x3d.Part0 == _0x3b) then
					_0x3e = _0x3d.Part1
				elseif (_0x3d.Part1 == _0x3b) then
					_0x3e = _0x3d.Part0
				end
				if _0x3e then
					if (_0x3e.Name == _0xS_D("\225\194\218\200\223\249\194\223\222\194")) then
						return Enum.HumanoidRigType.R15
					elseif (_0x3e.Name == _0xS_D("\249\194\223\222\194")) then
						return Enum.HumanoidRigType.R6
					end
				end
			end
		end
	end
	local _0x3f = _0x33(_0x39)
	local _0x40, _0x41 = 0, 0
	for _0x42, _0x43 in ipairs(_0x2.R15_NAMES) do
		if _0x3f[_0x43] then
			_0x40 = (_0x40 + 1)
		end
	end
	for _0x44, _0x45 in ipairs(_0x2.R6_NAMES) do
		if _0x3f[_0x45] then
			_0x41 = (_0x41 + 1)
		end
	end
	if ((_0x40 >= 3) and (_0x41 < 3)) then
		return Enum.HumanoidRigType.R15
	end
	if ((_0x41 >= 4) and (_0x40 < 3)) then
		return Enum.HumanoidRigType.R6
	end
	if ((_0x40 > 0) or (_0x41 > 0)) then
		local _0x46, _0x47 = (_0x40 / (#_0x2.R15_NAMES)), (_0x41 / (#_0x2.R6_NAMES))
		if (_0x46 ~= _0x47) then
			return ((((_0x46 > _0x47)) and Enum.HumanoidRigType.R15) or Enum.HumanoidRigType.R6)
		end
	end
	return _0x3a.RigType
end
local function _0x48(_0x49)
	_0x49 = _0x2f(_0x49)
	if ((((#_0x49) < 1) or ((#_0x49) > 20)) or (not _0x49:match(_0xS_D("\243\246\136\218\242\240\134\137")))) then
		return nil
	end
	local _0x4a = _0x3:FindFirstChild(_0x49)
	if (_0x4a and _0x4a:IsA(_0xS_D("\253\193\204\212\200\223"))) then
		return _0x4a.UserId
	end
	local _0x4b, _0x4c = pcall(_0x3.GetUserIdFromNameAsync, _0x3, _0x49)
	if _0x4b then
		return _0x4c
	end
	return nil
end
local function _0x4d(_0x4e)
	local _0x4f = _0x1a[_0x4e]
	if (_0x4f and ((os.clock() - _0x4f.time) < 120)) then
		return _0x4f.value:Clone()
	end
	local _0x50 = _0x27(_0x3, { _0xS_D("\234\200\217\229\216\192\204\195\194\196\201\233\200\222\206\223\196\221\217\196\194\195\235\223\194\192\248\222\200\223\228\201\236\222\212\195\206"), _0xS_D("\234\200\217\229\216\192\204\195\194\196\201\233\200\222\206\223\196\221\217\196\194\195\235\223\194\192\248\222\200\223\228\201") }, _0x4e)
	if _0x50 then
		_0x1a[_0x4e] = { value = _0x50, time = os.clock() }
		return _0x50:Clone()
	end
	return nil
end
local function _0x51(_0x52, _0x53)
	task.spawn(function()
	local _0x54
	for _0x55 = 1, 5 do
		local _0x56, _0x57, _0x58 = pcall(function()
	return _0x3:GetUserThumbnailAsync(_0x52, Enum.ThumbnailType.AvatarThumbnail, Enum.ThumbnailSize.Size420x420)
end)
		if (_0x53 ~= _0x17) then
			return
		end
		if (_0x56 and _0x57) then
			_0x54 = _0x57
			if (_0x58 ~= false) then
				break
			end
		end
		task.wait(1)
	end
	if ((((_0x53 ~= _0x17) or (not _0x54)) or (not _0x12)) or (not _0x12.Parent)) then
		return
	end
	_0x12.Image = _0x54
	pcall(function()
	_0x6:PreloadAsync({ _0x12 })
end)
	if ((_0x53 ~= _0x17) or (not _0x12.Parent)) then
		return
	end
	_0x12.ImageTransparency = 1
	_0x5:Create(_0x12, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { ImageTransparency = 0 }):Play()
end)
end
_0x2.SFX_START = _0xS_D("\223\207\213\204\222\222\200\217\196\201\151\130\130\156\158\158\155\158\155\152\157\148\154\148\153\152\152\152")
_0x2.SFX_LOOP = { _0xS_D("\223\207\213\204\222\222\200\217\196\201\151\130\130\154\154\155\155\156\157\156\157\149\154\148\155\153\155"), _0xS_D("\223\207\213\204\222\222\200\217\196\201\151\130\130\156\156\159\159\152\156\148\157\152\159\155\153\159\152\157") }
_0x2.SFX_FINISH = _0xS_D("\223\207\213\204\222\222\200\217\196\201\151\130\130\156\158\157\152\157\154\149\157\154\158\154\157\158\155\154")
_0x2.SFX_START_VOLUME = 4
_0x2.SFX_LOOP_VOLUME = 7
_0x2.SFX_FINISH_VOLUME = 5
_0x2.SFX_LOOP_CLIP_TIMEOUT = 10
local _0x59 = 0
local _0x5a = nil
local function _0x5b(_0x5c, _0x5d)
	local _0x5e = Instance.new(_0xS_D("\254\194\216\195\201"))
	_0x5e.Name = _0xS_D("\236\235\226\242\254\203\213")
	_0x5e.SoundId = _0x5c
	_0x5e.Volume = _0x5d
	_0x5e.Parent = _0xa
	return _0x5e
end
local function _0x5f(_0x60, _0x61)
	local _0x62 = _0x5b(_0x60, _0x61)
	_0x62.Ended:Once(function()
	_0x62:Destroy()
end)
	_0x9:AddItem(_0x62, 20)
	_0x62:Play()
end
local function _0x63()
	_0x59 = (_0x59 + 1)
	local _0x64 = _0x5a
	_0x5a = nil
	if _0x64 then
		pcall(function()
	_0x64:Stop()
	_0x64:Destroy()
end)
	end
end
local function _0x65()
	_0x63()
	local _0x66 = _0x59
	task.spawn(function()
	while ((_0x66 == _0x59) and _0xe) do
		local _0x67 = _0x5b(_0x2.SFX_LOOP[math.random((#_0x2.SFX_LOOP))], _0x2.SFX_LOOP_VOLUME)
		_0x5a = _0x67
		local _0x68 = false
		_0x67.Ended:Once(function()
	_0x68 = true
end)
		_0x67:Play()
		local _0x69 = os.clock()
		while ((_0x66 == _0x59) and (not _0x68)) do
			local _0x6a = (os.clock() - _0x69)
			if ((_0x6a > _0x2.SFX_LOOP_CLIP_TIMEOUT) or (((_0x6a > 2) and (not _0x67.IsPlaying)))) then
				break
			end
			task.wait(0.05)
		end
		if (_0x5a == _0x67) then
			_0x5a = nil
		end
		pcall(function()
	_0x67:Destroy()
end)
	end
end)
end
local function _0x6b()
	task.spawn(function()
	local _0x6c = {}
	for _0x6d, _0x6e in ipairs({ _0x2.SFX_START, _0x2.SFX_LOOP[1], _0x2.SFX_LOOP[2], _0x2.SFX_FINISH }) do
		local _0x6f = Instance.new(_0xS_D("\254\194\216\195\201"))
		_0x6f.SoundId = _0x6e
		table.insert(_0x6c, _0x6f)
	end
	pcall(function()
	_0x6:PreloadAsync(_0x6c)
end)
	for _0x70, _0x71 in ipairs(_0x6c) do
		_0x71:Destroy()
	end
end)
end
local function _0x72(_0x73)
	local _0x74 = {}
	local function _0x75(_0x76)
		if (_0x76:IsA(_0xS_D("\229\196\202\197\193\196\202\197\217")) and (_0x76.Name ~= _0x2.GRAY_NAME)) then
			_0x74[_0x76] = { Enabled = _0x76.Enabled, FillColor = _0x76.FillColor, FillTransparency = _0x76.FillTransparency, OutlineColor = _0x76.OutlineColor, OutlineTransparency = _0x76.OutlineTransparency }
		end
	end
	for _0x77, _0x78 in ipairs(_0x73:GetDescendants()) do
		_0x75(_0x78)
	end
	for _0x79, _0x7a in ipairs(workspace:GetChildren()) do
		if (_0x7a:IsA(_0xS_D("\229\196\202\197\193\196\202\197\217")) and (_0x7a.Adornee == _0x73)) then
			_0x75(_0x7a)
		end
	end
	return _0x74
end
local function _0x7b(_0x7c)
	for _0x7d, _0x7e in pairs(_0x7c) do
		if _0x7d.Parent then
			for _0x7f, _0x80 in pairs(_0x7e) do
				pcall(function()
	_0x7d[_0x7f] = _0x80
end)
			end
		end
	end
end
local function _0x81(_0x82)
	_0x63()
	local _0x83 = _0x19
	if (not _0x83) then
		return
	end
	_0x19 = nil
	if _0x83.conn then
		_0x83.conn:Disconnect()
	end
	_0x7b(_0x83.saved)
	local _0x84 = _0x83.highlight
	if ((not _0x84) or (not _0x84.Parent)) then
		return
	end
	if _0x82 then
		_0x84:Destroy()
		return
	end
	local _0x85 = _0x5:Create(_0x84, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { FillTransparency = 1, OutlineTransparency = 1 })
	_0x85:Play()
	_0x85.Completed:Once(function()
	_0x84:Destroy()
end)
end
local function _0x86(_0x87)
	if (((_0x19 and (_0x19.character == _0x87)) and _0x19.highlight) and _0x19.highlight.Parent) then
		return _0x19
	end
	_0x81(true)
	local _0x88 = _0x72(_0x87)
	for _0x89 in pairs(_0x88) do
		_0x89.Enabled = false
	end
	local _0x8a = Instance.new(_0xS_D("\229\196\202\197\193\196\202\197\217"))
	_0x8a.Name = _0x2.GRAY_NAME
	_0x8a.Adornee = _0x87
	_0x8a.FillColor = _0x2.GRAY_A
	_0x8a.OutlineColor = Color3.new(1, 1, 1)
	_0x8a.FillTransparency = 1
	_0x8a.OutlineTransparency = 1
	_0x8a.DepthMode = Enum.HighlightDepthMode.Occluded
	_0x8a.Parent = _0x87
	local _0x8b = { highlight = _0x8a, saved = _0x88, character = _0x87, boost = 0 }
	local _0x8c = os.clock()
	_0x8b.conn = _0x7.Heartbeat:Connect(function()
	if (not _0x8a.Parent) then
		return
	end
	local _0x8d = (((math.sin((((os.clock() - _0x8c)) * 5)) + 1)) / 2)
	_0x8a.FillColor = _0x2.GRAY_A:Lerp(_0x2.GRAY_B, (_0x8d * ((0.35 + (_0x8b.boost * 0.65)))))
end)
	_0x19 = _0x8b
	_0x5:Create(_0x8a, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { FillTransparency = 0, OutlineTransparency = 0 }):Play()
	return _0x8b
end
local function _0x8e(_0x8f)
	local _0x90 = _0x19
	if ((_0x90 and _0x90.highlight) and _0x90.highlight.Parent) then
		pcall(function()
	_0x90.highlight.Adornee = _0x8f
end)
	end
end
local function _0x91(_0x92, _0x93, _0x94, _0x95)
	local _0x96 = os.clock()
	while true do
		if (((_0x94 ~= _0x17) or (not _0xe)) or ((_0x95 and (not _0x95())))) then
			return false
		end
		local _0x97 = (os.clock() - _0x96)
		_0x93(math.min((_0x97 / _0x92), 1))
		if (_0x97 >= _0x92) then
			return true
		end
		_0x7.Heartbeat:Wait()
	end
end
_0x2.HIDE_STEP = _0xS_D("\236\235\226\242\229\196\201\200\238\197\204\223\204\206\217\200\223")
local _0x98 = nil
local _0x99 = nil
local _0x9a = nil
local _0x9b = nil
local _0x9c = {}
local _0x9d = nil
_0x2.STRIP_CLASSES = { _0xS_D("\239\204\222\200\254\206\223\196\221\217"), _0xS_D("\224\194\201\216\193\200\254\206\223\196\221\217"), _0xS_D("\254\194\216\195\201"), _0xS_D("\235\194\223\206\200\235\196\200\193\201"), _0xS_D("\249\194\194\193"), _0xS_D("\229\196\202\197\193\196\202\197\217"), _0xS_D("\239\196\193\193\207\194\204\223\201\234\216\196"), _0xS_D("\253\223\194\213\196\192\196\217\212\253\223\194\192\221\217"), _0xS_D("\253\204\223\217\196\206\193\200\232\192\196\217\217\200\223"), _0xS_D("\249\223\204\196\193"), _0xS_D("\239\200\204\192"), _0xS_D("\235\196\223\200"), _0xS_D("\254\192\194\198\200"), _0xS_D("\254\221\204\223\198\193\200\222"), _0xS_D("\225\196\202\197\217") }
_0x2.FX_CLASSES = { _0xS_D("\253\204\223\217\196\206\193\200\232\192\196\217\217\200\223"), _0xS_D("\249\223\204\196\193"), _0xS_D("\239\200\204\192"), _0xS_D("\235\196\223\200"), _0xS_D("\254\192\194\198\200"), _0xS_D("\254\221\204\223\198\193\200\222"), _0xS_D("\225\196\202\197\217") }
local function _0x9e(_0x9f)
	for _0xa0, _0xa1 in ipairs(_0x2.FX_CLASSES) do
		if _0x9f:IsA(_0xa1) then
			return true
		end
	end
	return false
end
_0x1.SmartBone = { TAGS = { _0xS_D("\254\192\204\223\217\239\194\195\200"), _0xS_D("\254\192\204\223\217\238\194\193\193\196\201\200\223") }, WELD_NAME = _0xS_D("\254\192\204\223\217\250\200\193\201") }
function _0x1.SmartBone.resetBones(_0xa2)
	for _0xa3, _0xa4 in ipairs(_0xa2:GetDescendants()) do
		if _0xa4:IsA(_0xS_D("\239\194\195\200")) then
			pcall(function()
	_0xa4.Transform = CFrame.identity
end)
		end
	end
end
function _0x1.SmartBone.strip(_0xa5)
	local function _0xa6(_0xa7)
		for _0xa8, _0xa9 in ipairs(_0x1.SmartBone.TAGS) do
			if game:GetService(_0xS_D("\238\194\193\193\200\206\217\196\194\195\254\200\223\219\196\206\200")):HasTag(_0xa7, _0xa9) then
				game:GetService(_0xS_D("\238\194\193\193\200\206\217\196\194\195\254\200\223\219\196\206\200")):RemoveTag(_0xa7, _0xa9)
			end
		end
	end
	_0xa6(_0xa5)
	for _0xaa, _0xab in ipairs(_0xa5:GetDescendants()) do
		_0xa6(_0xab)
		if (_0xab:IsA(_0xS_D("\226\207\199\200\206\217\251\204\193\216\200")) and (_0xab.Name == _0x1.SmartBone.WELD_NAME)) then
			_0xab:Destroy()
		end
	end
	_0x1.SmartBone.resetBones(_0xa5)
end
function _0x1.SmartBone.settle(_0xac)
	if ((not _0xac) or (not _0xac.Parent)) then
		return
	end
	local _0xad = {}
	for _0xae, _0xaf in ipairs(_0xac:GetDescendants()) do
		if (_0xaf:IsA(_0xS_D("\224\200\222\197\253\204\223\217")) and game:GetService(_0xS_D("\238\194\193\193\200\206\217\196\194\195\254\200\223\219\196\206\200")):HasTag(_0xaf, _0xS_D("\254\192\204\223\217\239\194\195\200"))) then
			table.insert(_0xad, _0xaf)
		end
	end
	if ((#_0xad) == 0) then
		return
	end
	for _0xb0, _0xb1 in ipairs(_0xad) do
		game:GetService(_0xS_D("\238\194\193\193\200\206\217\196\194\195\254\200\223\219\196\206\200")):RemoveTag(_0xb1, _0xS_D("\254\192\204\223\217\239\194\195\200"))
		_0x1.SmartBone.resetBones(_0xb1)
	end
	_0x7.Heartbeat:Wait()
	for _0xb2, _0xb3 in ipairs(_0xad) do
		if (_0xb3.Parent and _0xb3:IsDescendantOf(_0xac)) then
			game:GetService(_0xS_D("\238\194\193\193\200\206\217\196\194\195\254\200\223\219\196\206\200")):AddTag(_0xb3, _0xS_D("\254\192\204\223\217\239\194\195\200"))
		end
	end
end
function _0x1.SmartBone.scheduleSettle(_0xb4, _0xb5)
	for _0xb6, _0xb7 in ipairs({ 0.4, (_0x2.GUARD_SECONDS + 0.6) }) do
		task.delay(_0xb7, function()
	if ((_0x17 ~= _0xb5) or (not _0xb4.Parent)) then
		return
	end
	pcall(_0x1.SmartBone.settle, _0xb4)
end)
	end
end
_0x1.Hybrid = { HIDE_R6_WHEN_R15 = true, PAIRS = { { _0xS_D("\249\194\223\222\194"), _0xS_D("\248\221\221\200\223\249\194\223\222\194") }, { _0xS_D("\225\200\203\217\141\236\223\192"), _0xS_D("\225\200\203\217\248\221\221\200\223\236\223\192") }, { _0xS_D("\255\196\202\197\217\141\236\223\192"), _0xS_D("\255\196\202\197\217\248\221\221\200\223\236\223\192") }, { _0xS_D("\225\200\203\217\141\225\200\202"), _0xS_D("\225\200\203\217\248\221\221\200\223\225\200\202") }, { _0xS_D("\255\196\202\197\217\141\225\200\202"), _0xS_D("\255\196\202\197\217\248\221\221\200\223\225\200\202") } } }
function _0x1.Hybrid.hideR6(_0xb8)
	if (((not _0x1.Hybrid.HIDE_R6_WHEN_R15) or (not _0xb8)) or (not _0xb8.Parent)) then
		return
	end
	local _0xb9 = {}
	for _0xba, _0xbb in ipairs(_0x1.Hybrid.PAIRS) do
		local _0xbc = _0xb8:FindFirstChild(_0xbb[1], true)
		local _0xbd = _0xb8:FindFirstChild(_0xbb[2], true)
		if ((((((_0xbc and _0xbd) and _0xbc:IsA(_0xS_D("\239\204\222\200\253\204\223\217"))) and _0xbd:IsA(_0xS_D("\239\204\222\200\253\204\223\217"))) and (not _0xbc:FindFirstAncestorWhichIsA(_0xS_D("\236\206\206\200\222\222\194\223\212")))) and (not _0xbd:FindFirstAncestorWhichIsA(_0xS_D("\236\206\206\200\222\222\194\223\212")))) and (_0xbd.Transparency < 0.95)) then
			table.insert(_0xb9, _0xbc)
		end
	end
	if ((#_0xb9) < 3) then
		return
	end
	for _0xbe, _0xbf in ipairs(_0xb9) do
		local _0xc0 = false
		if (_0xbf:GetAttribute(_0xS_D("\236\235\226\242\226\223\196\202\249\223\204\195\222\221\204\223\200\195\206\212")) == nil) then
			if (_0xbf.Transparency >= 0.95) then
				_0xc0 = true
			else
				_0xbf:SetAttribute(_0xS_D("\236\235\226\242\226\223\196\202\249\223\204\195\222\221\204\223\200\195\206\212"), _0xbf.Transparency)
			end
		end
		if (not _0xc0) then
			_0xbf.Transparency = 1
		end
	end
end
function _0x1.Hybrid.apply(_0xc1, _0xc2)
	pcall(_0x1.Hybrid.hideR6, _0xc1)
	for _0xc3, _0xc4 in ipairs({ 0.3, 1.2, 3 }) do
		task.delay(_0xc4, function()
	if ((_0x17 ~= _0xc2) or (not _0xc1.Parent)) then
		return
	end
	pcall(_0x1.Hybrid.hideR6, _0xc1)
end)
	end
end
local function _0xc5()
	local _0xc6 = workspace.CurrentCamera
	if (not _0xc6) then
		return false
	end
	return (((_0xc6.Focus.Position - _0xc6.CFrame.Position)).Magnitude < 1)
end
local function _0xc7(_0xc8, _0xc9)
	if ((not _0xc9:IsA(_0xS_D("\239\204\222\200\253\204\223\217"))) or _0xc8.partSet[_0xc9]) then
		return
	end
	local _0xca = _0xc9.Parent
	if (_0xca and _0xca:IsA(_0xS_D("\249\194\194\193"))) then
		return
	end
	_0xc8.partSet[_0xc9] = true
	table.insert(_0xc8.parts, _0xc9)
end
local function _0xcb()
	local _0xcc = _0x9a
	if (not _0xcc) then
		return
	end
	local _0xcd = _0xcc.character
	if ((not _0xcd) or (not _0xcd.Parent)) then
		return
	end
	local _0xce = _0xcc.parts
	local _0xcf = 1
	while (_0xcf <= (#_0xce)) do
		local _0xd0 = _0xce[_0xcf]
		if (_0xd0.Parent == nil) then
			_0xcc.partSet[_0xd0] = nil
			_0xce[_0xcf] = _0xce[(#_0xce)]
			_0xce[(#_0xce)] = nil
		else
			if (_0xd0.LocalTransparencyModifier ~= 1) then
				_0xd0.LocalTransparencyModifier = 1
			end
			_0xcf = (_0xcf + 1)
		end
	end
end
local function _0xd1(_0xd2, _0xd3, _0xd4)
	local _0xd5 = _0xd2.initial[_0xd3]
	if (_0xd5 == nil) then
		_0xd5 = _0xd2.baseLTM
	end
	if _0xd4 then
		if (_0xd5 < 0.99) then
			_0xd5 = 1
		end
	elseif (_0xd5 < 0.99) then
		_0xd5 = 0
	end
	return _0xd5
end
local function _0xd6(_0xd7, _0xd8)
	if ((not _0xd7) or (not _0xd7.Parent)) then
		return
	end
	if (_0x9a and (_0x9a.character == _0xd7)) then
		return
	end
	if _0xc5() then
		return
	end
	for _0xd9, _0xda in ipairs(_0xd7:GetDescendants()) do
		if (_0xda:IsA(_0xS_D("\239\204\222\200\253\204\223\217")) and (_0xda.LocalTransparencyModifier >= 0.99)) then
			local _0xdb = (((_0xd8 ~= nil) and (_0xd8[_0xda] ~= nil)) and (_0xd8[_0xda] >= 0.99))
			if ((not _0xdb) and (((_0x2.BODY_COLOR_MAP[_0xda.Name] ~= nil) or (_0xda:FindFirstAncestorWhichIsA(_0xS_D("\236\206\206\200\222\222\194\223\212")) ~= nil)))) then
				_0xda.LocalTransparencyModifier = 0
			end
		end
	end
end
local function _0xdc()
	pcall(function()
	_0x7:UnbindFromRenderStep(_0x2.HIDE_STEP)
end)
	local _0xdd = _0x9a
	_0x9a = nil
	if (not _0xdd) then
		return
	end
	for _0xde, _0xdf in ipairs(_0xdd.conns) do
		pcall(function()
	_0xdf:Disconnect()
end)
	end
	local _0xe0 = _0xdd.character
	if (_0xe0 and _0xe0.Parent) then
		local _0xe1 = _0xc5()
		for _0xe2, _0xe3 in ipairs(_0xe0:GetDescendants()) do
			if _0xe3:IsA(_0xS_D("\239\204\222\200\253\204\223\217")) then
				local _0xe4 = _0xe3.Parent
				if (not ((_0xe4 and _0xe4:IsA(_0xS_D("\249\194\194\193"))))) then
					_0xe3.LocalTransparencyModifier = _0xd1(_0xdd, _0xe3, _0xe1)
				end
			end
		end
		if (_0xdd.baseLTM < 0.5) then
			for _0xe5, _0xe6 in ipairs({ 0.05, 0.4, 1.2 }) do
				task.delay(_0xe6, function()
	_0xd6(_0xe0, _0xdd.initial)
end)
			end
		end
	end
end
local function _0xe7(_0xe8)
	_0xdc()
	local _0xe9 = { character = _0xe8, parts = {}, partSet = {}, initial = setmetatable({}, { __mode = _0xS_D("\198") }), conns = {}, baseLTM = 0 }
	local _0xea
	for _0xeb, _0xec in ipairs(_0xe8:GetDescendants()) do
		if _0xec:IsA(_0xS_D("\239\204\222\200\253\204\223\217")) then
			_0xe9.initial[_0xec] = _0xec.LocalTransparencyModifier
			if ((_0xec.Name == _0xS_D("\229\200\204\201")) and (not _0x31(_0xec))) then
				_0xe9.baseLTM = _0xec.LocalTransparencyModifier
				_0xea = true
			elseif (((not _0xea) and (_0xec.Name ~= _0xS_D("\229\216\192\204\195\194\196\201\255\194\194\217\253\204\223\217"))) and (_0xe9.baseLTM == 0)) then
				_0xe9.baseLTM = _0xec.LocalTransparencyModifier
			end
			_0xc7(_0xe9, _0xec)
		end
	end
	table.insert(_0xe9.conns, _0xe8.DescendantAdded:Connect(function(_0xed)
	if (_0x9a == _0xe9) then
		_0xc7(_0xe9, _0xed)
	end
end))
	_0x9a = _0xe9
	_0xcb()
	pcall(function()
	_0x7:BindToRenderStep(_0x2.HIDE_STEP, Enum.RenderPriority.Last.Value, _0xcb)
end)
end
local function _0xee()
	local _0xef = _0x9b
	_0x9b = nil
	if (_0xef and _0xef.model) then
		pcall(function()
	_0xef.model:Destroy()
end)
	end
	for _0xf0, _0xf1 in ipairs(_0x9c) do
		pcall(function()
	_0xf1.model:Destroy()
end)
	end
	table.clear(_0x9c)
	if _0x9d then
		local _0xf2 = _0x9d
		_0x9d = nil
		pcall(function()
	_0xf2:Destroy()
end)
	end
end
local function _0xf3()
	if (_0x9d and _0x9d.Parent) then
		return _0x9d
	end
	local _0xf4 = Instance.new(_0xS_D("\224\194\201\200\193"))
	_0xf4.Name = _0xS_D("\236\235\226\242\234\197\194\222\217\234\223\194\216\221")
	_0xf4.Parent = (workspace.CurrentCamera or workspace)
	_0x9d = _0xf4
	return _0xf4
end
local function _0xf5()
	_0x99 = nil
	_0xee()
	_0xdc()
end
local function _0xf6(_0xf7, _0xf8)
	local _0xf9 = {}
	local _0xfa = _0xf7
	while (_0xfa and (_0xfa ~= _0xf8)) do
		table.insert(_0xf9, 1, _0xfa.Name)
		_0xfa = _0xfa.Parent
	end
	return table.concat(_0xf9, _0xS_D("\130"))
end
local function _0xfb(_0xfc, _0xfd)
	return (((((math.abs(_0xfc.RightVector.Y) * _0xfd.X) + (math.abs(_0xfc.UpVector.Y) * _0xfd.Y)) + (math.abs(_0xfc.LookVector.Y) * _0xfd.Z))) / 2)
end
local function _0xfe(_0xff)
	local _0x100 = {}
	local _0x101 = _0xff:FindFirstChild(_0xS_D("\229\216\192\204\195\194\196\201\255\194\194\217\253\204\223\217"))
	if (not _0x101) then
		return _0x100
	end
	_0x100[_0x101] = CFrame.new()
	local _0x102 = {}
	for _0x103, _0x104 in ipairs(_0xff:GetDescendants()) do
		if ((_0x104:IsA(_0xS_D("\224\194\217\194\223\155\233")) and _0x104.Part0) and _0x104.Part1) then
			table.insert(_0x102, _0x104)
		end
	end
	local _0x105 = true
	while _0x105 do
		_0x105 = false
		for _0x106, _0x107 in ipairs(_0x102) do
			if (_0x100[_0x107.Part0] and (not _0x100[_0x107.Part1])) then
				_0x100[_0x107.Part1] = ((_0x100[_0x107.Part0] * _0x107.C0) * _0x107.C1:Inverse())
				_0x105 = true
			end
		end
	end
	return _0x100
end
local function _0x108(_0x109, _0x10a, _0x10b, _0x10c, _0x10d)
	if (_0x10d and _0x9b) then
		table.insert(_0x9c, _0x9b)
		_0x9b = nil
	else
		_0xee()
	end
	local _0x10e = (((_0x9a and (_0x9a.character == _0x109)) and _0x9a) or nil)
	local _0x10f = {}
	for _0x110, _0x111 in ipairs(_0x109:GetDescendants()) do
		if _0x111:IsA(_0xS_D("\239\204\222\200\253\204\223\217")) then
			local _0x112
			if _0x10e then
				_0x112 = (_0x10e.initial[_0x111] or 0)
			else
				_0x112 = _0x111.LocalTransparencyModifier
			end
			if (_0x112 >= 0.95) then
				_0x10f[_0xf6(_0x111, _0x109)] = true
			end
		end
	end
	local _0x113
	local _0x114 = _0x109.Archivable
	pcall(function()
	_0x109.Archivable = true
end)
	local _0x115 = pcall(function()
	_0x113 = _0x109:Clone()
end)
	pcall(function()
	_0x109.Archivable = _0x114
end)
	if ((not _0x115) or (not _0x113)) then
		return nil
	end
	for _0x116, _0x117 in ipairs(_0x113:GetDescendants()) do
		for _0x118, _0x119 in ipairs(_0x2.STRIP_CLASSES) do
			if _0x117:IsA(_0x119) then
				_0x117:Destroy()
				break
			end
		end
	end
	pcall(_0x1.SmartBone.strip, _0x113)
	local _0x11a = _0x113:FindFirstChild(_0xS_D("\229\216\192\204\195\194\196\201\255\194\194\217\253\204\223\217"))
	if ((not _0x11a) or (not _0x11a:IsA(_0xS_D("\239\204\222\200\253\204\223\217")))) then
		_0x113:Destroy()
		return nil
	end
	for _0x11b, _0x11c in ipairs(_0x113:GetDescendants()) do
		if (_0x11c:IsA(_0xS_D("\229\216\192\204\195\194\196\201")) or _0x11c:IsA(_0xS_D("\236\195\196\192\204\217\194\223"))) then
			_0x11c:Destroy()
		end
	end
	local _0x11d = _0x11a.CFrame
	local _0x11e = {}
	local _0x11f = {}
	for _0x120, _0x121 in ipairs(_0x113:GetDescendants()) do
		if _0x121:IsA(_0xS_D("\239\204\222\200\253\204\223\217")) then
			_0x121.Anchored = true
			_0x121.CanCollide = false
			_0x121.CanTouch = false
			_0x121.CanQuery = false
			_0x121.Massless = true
			_0x121.LocalTransparencyModifier = 0
			if _0x10f[_0xf6(_0x121, _0x113)] then
				_0x121.Transparency = 1
			end
			if (_0x121 ~= _0x11a) then
				local _0x122 = _0x11d:ToObjectSpace(_0x121.CFrame)
				local _0x123 = { part = _0x121, key = _0xf6(_0x121, _0x113), orig = _0x121.Size, pos = _0x122.Position, rot = (_0x122 - _0x122.Position), meshes = {}, decals = {}, baseT = _0x121.Transparency, seed = (math.random() * 6.28) }
				for _0x124, _0x125 in ipairs(_0x121:GetChildren()) do
					if (_0x125:IsA(_0xS_D("\254\221\200\206\196\204\193\224\200\222\197")) and (_0x125.MeshType == Enum.MeshType.FileMesh)) then
						table.insert(_0x123.meshes, { mesh = _0x125, orig = _0x125.Scale })
					elseif (_0x125:IsA(_0xS_D("\233\200\206\204\193")) or _0x125:IsA(_0xS_D("\249\200\213\217\216\223\200"))) then
						table.insert(_0x123.decals, { inst = _0x125, orig = _0x125.Transparency })
					end
				end
				table.insert(_0x11e, _0x123)
				_0x11f[_0x121] = _0x123
			end
		end
	end
	local _0x126 = _0xfe(_0x113)
	local _0x127, _0x128
	for _0x129, _0x12a in ipairs(_0x11e) do
		local _0x12b = _0x12a.part
		local _0x12c = _0x126[_0x12b]
		if ((_0x12c and (_0x12b.Transparency < 0.95)) and (not _0x31(_0x12b))) then
			local _0x12d = _0xfb(_0x12c, _0x12a.orig)
			local _0x12e, _0x12f = (_0x12c.Position.Y - _0x12d), (_0x12c.Position.Y + _0x12d)
			_0x127 = ((_0x127 and math.min(_0x127, _0x12e)) or _0x12e)
			_0x128 = ((_0x128 and math.max(_0x128, _0x12f)) or _0x12f)
		end
	end
	for _0x130, _0x131 in ipairs(_0x113:GetDescendants()) do
		if ((_0x131:IsA(_0xS_D("\231\194\196\195\217\228\195\222\217\204\195\206\200")) or _0x131:IsA(_0xS_D("\250\200\193\201\238\194\195\222\217\223\204\196\195\217"))) or _0x131:IsA(_0xS_D("\238\194\195\222\217\223\204\196\195\217"))) then
			_0x131:Destroy()
		end
	end
	local _0x132, _0x133, _0x134
	for _0x135, _0x136 in ipairs(_0x11e) do
		if (_0x136.part.Transparency < 0.95) then
			local _0x137 = _0xfb(_0x136.rot, _0x136.orig)
			local _0x138, _0x139 = (_0x136.pos.Y - _0x137), (_0x136.pos.Y + _0x137)
			_0x134 = ((_0x134 and math.min(_0x134, _0x138)) or _0x138)
			if (not _0x31(_0x136.part)) then
				_0x132 = ((_0x132 and math.min(_0x132, _0x138)) or _0x138)
				_0x133 = ((_0x133 and math.max(_0x133, _0x139)) or _0x139)
			end
		end
	end
	local _0x13a = ((_0x132 or _0x134) or (-3))
	do
		local _0x13b = ((_0x132 or _0x134) or (-3))
		local _0x13c = (_0x133 or ((_0x13b + 5)))
		local _0x13d = math.max((_0x13c - _0x13b), 0.5)
		for _0x13e, _0x13f in ipairs(_0x11e) do
			_0x13f.stagger = _0x20((((_0x13f.pos.Y - _0x13b)) / _0x13d))
		end
	end
	local _0x140
	if (_0x127 and _0x128) then
		_0x140 = (_0x128 - _0x127)
	elseif (_0x132 and _0x133) then
		_0x140 = (_0x133 - _0x132)
	end
	_0x113.Name = _0xS_D("\236\235\226\242\234\197\194\222\217")
	_0x113.Parent = _0xf3()
	local _0x141 = (_0x10b.HipHeight + (_0x10a.Size.Y / 2))
	local _0x142 = { model = _0x113, items = _0x11e, pivot = Vector3.new(0, _0x13a, 0), height = _0x140, followHip = _0x10c, total0 = _0x141, total = _0x141, lastT = os.clock() }
	_0x9b = _0x142
	return _0x142
end
local function _0x143(_0x144, _0x145, _0x146)
	if (not _0x144.followHip) then
		return _0x145.CFrame
	end
	local _0x147 = os.clock()
	local _0x148 = math.min((_0x147 - _0x144.lastT), 0.1)
	_0x144.lastT = _0x147
	local _0x149 = (_0x146.HipHeight + (_0x145.Size.Y / 2))
	_0x144.total = (_0x144.total + ((((_0x149 - _0x144.total)) * ((1 - math.exp(((-_0x148) * _0x2.HIP_FOLLOW_RATE)))))))
	return (_0x145.CFrame - Vector3.new(0, (_0x144.total - _0x144.total0), 0))
end
local function _0x14a(_0x14b, _0x14c, _0x14d, _0x14e, _0x14f, _0x150)
	local _0x151 = _0x14c.part
	if ((not _0x151) or (not _0x151.Parent)) then
		return
	end
	if (_0x14c.lastMul ~= _0x14e) then
		_0x14c.lastMul = _0x14e
		_0x151.Size = (_0x14c.orig * _0x14e)
		for _0x152, _0x153 in ipairs(_0x14c.meshes) do
			if _0x153.mesh.Parent then
				_0x153.mesh.Scale = (_0x153.orig * _0x14e)
			end
		end
	end
	if _0x150 then
		_0x151.CFrame = (_0x14f * _0x150)
		return
	end
	local _0x154 = _0x14b.pivot
	_0x151.CFrame = (_0x14f * ((CFrame.new((_0x154 + (((_0x14c.pos - _0x154)) * _0x14d))) * _0x14c.rot)))
end
local function _0x155(_0x156, _0x157, _0x158, _0x159, _0x15a, _0x15b)
	local _0x15c = _0x143(_0x156, _0x157, _0x158)
	for _0x15d, _0x15e in ipairs(_0x156.items) do
		local _0x15f = ((math.sin((_0x15b + _0x15e.seed)) * 0.03) * _0x15a)
		_0x14a(_0x156, _0x15e, _0x159, Vector3.new((_0x159 * ((1 + _0x15f))), _0x159, (_0x159 * ((1 + _0x15f)))), _0x15c)
	end
end
_0x2.MORPH_DURATION = 1.25
_0x2.MORPH_HOLD_MIN = 0.55
_0x2.MORPH_STAGGER = 0.3
_0x2.MORPH_WOBBLE = 0.03
_0x2.MIN_SCALE = 0.03
local function _0x160(_0x161)
	_0x161 = _0x20(_0x161)
	return ((_0x161 * _0x161) * ((3 - (2 * _0x161))))
end
local function _0x162(_0x163, _0x164, _0x165)
	return (_0x163 + (((_0x164 - _0x163)) * _0x165))
end
local function _0x166(_0x167, _0x168, _0x169)
	local _0x16a = _0x143(_0x167, _0x168, _0x169)
	local _0x16b = os.clock()
	local _0x16c = (Vector3.new(math.sin((_0x16b * 53)), math.sin(((_0x16b * 47) + 1.3)), math.sin(((_0x16b * 61) + 2.1))) * 0.035)
	for _0x16d, _0x16e in ipairs(_0x167.items) do
		local _0x16f = _0x16e.part
		if (_0x16f and _0x16f.Parent) then
			_0x16f.CFrame = ((_0x16a * CFrame.new((_0x16e.pos + _0x16c))) * _0x16e.rot)
		end
	end
end
local function _0x170(_0x171, _0x172)
	local _0x173 = {}
	for _0x174, _0x175 in ipairs(_0x171.items) do
		_0x175.twin = nil
		if (_0x175.key and (not _0x173[_0x175.key])) then
			_0x173[_0x175.key] = _0x175
		end
	end
	for _0x176, _0x177 in ipairs(_0x172.items) do
		_0x177.twin = nil
		local _0x178 = (_0x177.key and _0x173[_0x177.key])
		if _0x178 then
			_0x173[_0x177.key] = nil
			_0x177.twin = _0x178
			_0x178.twin = _0x177
		end
	end
end
local function _0x179(_0x17a, _0x17b, _0x17c)
	local _0x17d = _0x17a.part
	if ((not _0x17d) or (not _0x17d.Parent)) then
		return
	end
	local _0x17e = _0x17a.orig
	_0x17d.Size = Vector3.new(math.max(_0x17b.X, 0.02), math.max(_0x17b.Y, 0.02), math.max(_0x17b.Z, 0.02))
	if ((#_0x17a.meshes) > 0) then
		local _0x17f = (_0x17b.X / math.max(_0x17e.X, 0.001))
		local _0x180 = (_0x17b.Y / math.max(_0x17e.Y, 0.001))
		local _0x181 = (_0x17b.Z / math.max(_0x17e.Z, 0.001))
		for _0x182, _0x183 in ipairs(_0x17a.meshes) do
			if _0x183.mesh.Parent then
				_0x183.mesh.Scale = Vector3.new((_0x183.orig.X * _0x17f), (_0x183.orig.Y * _0x180), (_0x183.orig.Z * _0x181))
			end
		end
	end
	_0x17d.Transparency = (1 - (((1 - _0x17a.baseT)) * _0x17c))
	for _0x184, _0x185 in ipairs(_0x17a.decals) do
		if _0x185.inst.Parent then
			_0x185.inst.Transparency = (1 - (((1 - _0x185.orig)) * _0x17c))
		end
	end
end
local function _0x186(_0x187, _0x188, _0x189, _0x18a, _0x18b, _0x18c, _0x18d)
	return _0x91(_0x18b, function(_0x18e)
	local _0x18f = _0x143(_0x187, _0x189, _0x18a)
	local _0x190 = _0x143(_0x188, _0x189, _0x18a)
	local _0x191 = os.clock()
	local _0x192 = (_0x2.MORPH_WOBBLE * math.sin((_0x18e * math.pi)))
	local function _0x193(_0x194)
		return _0x20(((_0x18e * ((1 + _0x2.MORPH_STAGGER))) - (((_0x194.stagger or 0)) * _0x2.MORPH_STAGGER)))
	end
	for _0x195, _0x196 in ipairs(_0x188.items) do
		local _0x197 = _0x193(_0x196)
		local _0x198 = _0x160(_0x197)
		local _0x199 = (math.sin((((_0x191 * 11) + (((_0x196.stagger or 0)) * 6)) + _0x196.seed)) * _0x192)
		local _0x19a = Vector3.new((1 + _0x199), (1 - (_0x199 * 0.8)), (1 + _0x199))
		local _0x19b = ((_0x190 * CFrame.new(_0x196.pos)) * _0x196.rot)
		local _0x19c = _0x196.twin
		if _0x19c then
			local _0x19d = ((_0x18f * CFrame.new(_0x19c.pos)) * _0x19c.rot)
			local _0x19e = _0x19d:Lerp(_0x19b, _0x198)
			local _0x19f = (_0x19c.orig:Lerp(_0x196.orig, _0x198) * _0x19a)
			_0x196.part.CFrame = _0x19e
			_0x19c.part.CFrame = _0x19e
			local _0x1a0 = (_0x197 >= 0.5)
			_0x179(_0x196, _0x19f, ((_0x1a0 and 1) or 0))
			_0x179(_0x19c, _0x19f, ((_0x1a0 and 0) or 1))
		else
			_0x196.part.CFrame = _0x19b
			_0x179(_0x196, (_0x196.orig * _0x162(_0x2.MIN_SCALE, 1, _0x198)), _0x160((_0x197 / 0.7)))
		end
	end
	for _0x1a1, _0x1a2 in ipairs(_0x187.items) do
		if (not _0x1a2.twin) then
			local _0x1a3 = _0x193(_0x1a2)
			local _0x1a4 = _0x160(_0x1a3)
			_0x1a2.part.CFrame = ((_0x18f * CFrame.new(_0x1a2.pos)) * _0x1a2.rot)
			_0x179(_0x1a2, (_0x1a2.orig * _0x162(1, _0x2.MIN_SCALE, _0x1a4)), (1 - _0x160((_0x1a3 / 0.8))))
		end
	end
end, _0x18c, _0x18d)
end
local function _0x1a5(_0x1a6)
	local _0x1a7 = 0
	while (_0x18 and (_0x1a7 < 3)) do
		if (_0x1a6 ~= _0x17) then
			return false
		end
		task.wait(0.05)
		_0x1a7 = (_0x1a7 + 0.05)
	end
	return (_0x1a6 == _0x17)
end
local function _0x1a8(_0x1a9, _0x1aa)
	local _0x1ab = _0x1a9:FindFirstChild(_0x1aa)
	if (_0x1ab and _0x1ab:IsA(_0xS_D("\239\204\222\200\253\204\223\217"))) then
		return _0x1ab
	end
	for _0x1ac, _0x1ad in ipairs(_0x1a9:GetDescendants()) do
		if (((_0x1ad.Name == _0x1aa) and _0x1ad:IsA(_0xS_D("\239\204\222\200\253\204\223\217"))) and (not _0x31(_0x1ad))) then
			return _0x1ad
		end
	end
	return nil
end
local function _0x1ae(_0x1af)
	for _0x1b0, _0x1b1 in ipairs(_0x1af:GetChildren()) do
		if (_0x1b1:IsA(_0xS_D("\239\204\222\200\253\204\223\217")) and _0x1b1:GetAttribute(_0xS_D("\236\235\226\254\198\196\195"))) then
			_0x1b1.CanCollide = false
			_0x1b1.CanTouch = false
			_0x1b1.Massless = true
		end
		if _0x1b1:IsA(_0xS_D("\236\206\206\200\222\222\194\223\212")) then
			for _0x1b2, _0x1b3 in ipairs(_0x1b1:GetDescendants()) do
				if _0x1b3:IsA(_0xS_D("\239\204\222\200\253\204\223\217")) then
					_0x1b3.CanCollide = false
					_0x1b3.CanTouch = false
					_0x1b3.Massless = true
				end
			end
			local _0x1b4 = _0x1b1:FindFirstChild(_0xS_D("\229\204\195\201\193\200"))
			if (_0x1b4 and _0x1b4:IsA(_0xS_D("\239\204\222\200\253\204\223\217"))) then
				_0x1b4.CanCollide = false
				_0x1b4.CanTouch = false
				_0x1b4.Massless = true
			end
		end
	end
end
local function _0x1b5(_0x1b6)
	for _0x1b7, _0x1b8 in ipairs(_0x1b6:GetChildren()) do
		if _0x1b8:IsA(_0xS_D("\236\217\217\204\206\197\192\200\195\217")) then
			return _0x1b8
		end
	end
	return nil
end
local function _0x1b9(_0x1ba, _0x1bb)
	for _0x1bc, _0x1bd in ipairs(_0x1ba:GetDescendants()) do
		if (((_0x1bd:IsA(_0xS_D("\236\217\217\204\206\197\192\200\195\217")) and (_0x1bd.Name == _0x1bb)) and _0x1bd.Parent:IsA(_0xS_D("\239\204\222\200\253\204\223\217"))) and (not _0x31(_0x1bd.Parent))) then
			return _0x1bd
		end
	end
	return nil
end
local function _0x1be(_0x1bf)
	_0x1bf.Anchored = false
	_0x1bf.CanCollide = false
	_0x1bf.CanTouch = false
	_0x1bf.Massless = true
end
local function _0x1c0(_0x1c1, _0x1c2)
	if (_0x1c2.Parent ~= _0x1c1) then
		return false
	end
	local _0x1c3 = _0x1c2:FindFirstChild(_0xS_D("\229\204\195\201\193\200"))
	if ((not _0x1c3) or (not _0x1c3:IsA(_0xS_D("\239\204\222\200\253\204\223\217")))) then
		return false
	end
	for _0x1c4, _0x1c5 in ipairs(_0x1c3:GetChildren()) do
		if (_0x1c5:IsA(_0xS_D("\231\194\196\195\217\228\195\222\217\204\195\206\200")) or _0x1c5:IsA(_0xS_D("\250\200\193\201\238\194\195\222\217\223\204\196\195\217"))) then
			local _0x1c6 = ((((_0x1c5.Part0 == _0x1c3)) and _0x1c5.Part1) or _0x1c5.Part0)
			if (((_0x1c6 and (_0x1c6 ~= _0x1c3)) and _0x1c6:IsDescendantOf(_0x1c1)) and (not _0x1c6:FindFirstAncestorWhichIsA(_0xS_D("\236\206\206\200\222\222\194\223\212")))) then
				return true
			end
		end
	end
	return false
end
local function _0x1c7(_0x1c8)
	local _0x1c9 = _0x1c8:FindFirstChild(_0xS_D("\229\204\195\201\193\200"))
	local _0x1ca = (_0x1c9 and _0x1c9:FindFirstChild(_0xS_D("\236\206\206\200\222\222\194\223\212\250\200\193\201")))
	if (((_0x1ca and _0x1ca:IsA(_0xS_D("\231\194\196\195\217\228\195\222\217\204\195\206\200"))) and _0x1ca.Part0) and _0x1ca.Part1) then
		if (_0x1ca.Part0 == _0x1c9) then
			return { partName = _0x1ca.Part1.Name, c0 = _0x1ca.C0, c1 = _0x1ca.C1 }
		else
			return { partName = _0x1ca.Part0.Name, c0 = _0x1ca.C1, c1 = _0x1ca.C0 }
		end
	end
	return nil
end
local function _0x1cb(_0x1cc, _0x1cd)
	local _0x1ce = _0x1cc:FindFirstChild(_0xS_D("\229\204\195\201\193\200"))
	if ((not _0x1ce) or (not _0x1ce:IsA(_0xS_D("\239\204\222\200\253\204\223\217")))) then
		return false
	end
	local _0x1cf = _0x1b5(_0x1ce)
	if (not _0x1cf) then
		return false
	end
	local _0x1d0 = _0x1b9(_0x1cd, _0x1cf.Name)
	if (not _0x1d0) then
		return false
	end
	_0x1cc.Parent = _0x1cd
	_0x1be(_0x1ce)
	_0x1ce.CFrame = ((_0x1d0.Parent.CFrame * _0x1d0.CFrame) * _0x1cf.CFrame:Inverse())
	local _0x1d1 = _0x1ce:FindFirstChild(_0xS_D("\236\206\206\200\222\222\194\223\212\250\200\193\201"))
	if _0x1d1 then
		_0x1d1:Destroy()
	end
	local _0x1d2 = Instance.new(_0xS_D("\250\200\193\201"))
	_0x1d2.Name = _0xS_D("\236\206\206\200\222\222\194\223\212\250\200\193\201")
	_0x1d2.Part0 = _0x1ce
	_0x1d2.Part1 = _0x1d0.Parent
	_0x1d2.C0 = _0x1cf.CFrame
	_0x1d2.C1 = _0x1d0.CFrame
	_0x1d2.Parent = _0x1ce
	return true
end
local function _0x1d3(_0x1d4, _0x1d5)
	local _0x1d6 = (_0x1d5 or _0xS_D(""))
	if ((_0x1d6:find(_0xS_D("\229\204\217")) or _0x1d6:find(_0xS_D("\229\204\196\223"))) or _0x1d6:find(_0xS_D("\235\204\206\200"))) then
		return _0x1a8(_0x1d4, _0xS_D("\229\200\204\201"))
	end
	return _0x1a8(_0x1d4, _0xS_D("\249\194\223\222\194"))
end
local function _0x1d7(_0x1d8, _0x1d9, _0x1da, _0x1db)
	local _0x1dc = _0x1b5(_0x1da)
	local _0x1dd, _0x1de, _0x1df
	if _0x1db then
		_0x1dd = _0x1a8(_0x1d8, _0x1db.partName)
		if _0x1dd then
			_0x1de, _0x1df = _0x1db.c0, _0x1db.c1
		end
	end
	if (not _0x1dd) then
		_0x1dd = (_0x1d3(_0x1d8, (_0x1dc and _0x1dc.Name)) or _0x1d8:FindFirstChild(_0xS_D("\229\216\192\204\195\194\196\201\255\194\194\217\253\204\223\217")))
		if ((not _0x1dd) or (not _0x1dd:IsA(_0xS_D("\239\204\222\200\253\204\223\217")))) then
			return false
		end
		local _0x1e0 = (_0x1dd.Name == _0xS_D("\229\200\204\201"))
		if _0x1dc then
			_0x1de = _0x1dc.CFrame
			_0x1df = ((_0x1e0 and CFrame.new(0, (_0x1dd.Size.Y / 2), 0)) or CFrame.identity)
		else
			local _0x1e1, _0x1e2 = pcall(function()
	return _0x1d9.AttachmentPoint
end)
			_0x1de = ((_0x1e1 and _0x1e2) or CFrame.identity)
			_0x1df = CFrame.new(0, (_0x1dd.Size.Y / 2), 0)
		end
	end
	_0x1d9.Parent = _0x1d8
	_0x1be(_0x1da)
	_0x1da.CFrame = ((_0x1dd.CFrame * _0x1df) * _0x1de:Inverse())
	local _0x1e3 = _0x1da:FindFirstChild(_0xS_D("\236\206\206\200\222\222\194\223\212\250\200\193\201"))
	if _0x1e3 then
		_0x1e3:Destroy()
	end
	local _0x1e4 = Instance.new(_0xS_D("\250\200\193\201"))
	_0x1e4.Name = _0xS_D("\236\206\206\200\222\222\194\223\212\250\200\193\201")
	_0x1e4.Part0 = _0x1da
	_0x1e4.Part1 = _0x1dd
	_0x1e4.C0 = _0x1de
	_0x1e4.C1 = _0x1df
	_0x1e4.Parent = _0x1da
	return true
end
local function _0x1e5(_0x1e6, _0x1e7, _0x1e8, _0x1e9)
	local _0x1ea = _0x1e8:Clone()
	local _0x1eb = _0x1ea:FindFirstChild(_0xS_D("\229\204\195\201\193\200"))
	if ((not _0x1eb) or (not _0x1eb:IsA(_0xS_D("\239\204\222\200\253\204\223\217")))) then
		_0x1ea:Destroy()
		return nil
	end
	_0x1e9 = (_0x1e9 or _0x1c7(_0x1e8))
	local _0x1ec = _0x1eb:FindFirstChild(_0xS_D("\236\206\206\200\222\222\194\223\212\250\200\193\201"))
	if _0x1ec then
		_0x1ec:Destroy()
	end
	_0x1eb.Anchored = false
	pcall(function()
	_0x1e7:AddAccessory(_0x1ea)
end)
	if (_0x1ea.Parent ~= _0x1e6) then
		_0x1ea.Parent = _0x1e6
	end
	if _0x1c0(_0x1e6, _0x1ea) then
		_0x1be(_0x1eb)
		return _0x1ea
	end
	pcall(_0x1cb, _0x1ea, _0x1e6)
	if _0x1c0(_0x1e6, _0x1ea) then
		_0x1be(_0x1eb)
		return _0x1ea
	end
	local _0x1ed = pcall(_0x1d7, _0x1e6, _0x1ea, _0x1eb, _0x1e9)
	if (_0x1ed and _0x1c0(_0x1e6, _0x1ea)) then
		return _0x1ea
	end
	_0x1ea:Destroy()
	return nil
end
local function _0x1ee(_0x1ef, _0x1f0, _0x1f1, _0x1f2)
	if ((not _0x1f1) or ((#_0x1f1) == 0)) then
		return
	end
	task.spawn(function()
	local _0x1f3 = 0
	while (_0x1f3 < _0x2.GUARD_SECONDS) do
		task.wait(_0x2.GUARD_INTERVAL)
		_0x1f3 = (_0x1f3 + (_0x2.GUARD_INTERVAL))
		if (((_0x1f2 ~= _0x17) or (not _0x1ef.Parent)) or (_0x1f0.Health <= 0)) then
			return
		end
		for _0x1f4, _0x1f5 in ipairs(_0x1f1) do
			local _0x1f6 = _0x1f5.accessory
			if ((not ((_0x1f6 and _0x1c0(_0x1ef, _0x1f6)))) and (((_0x1f5.repairs or 0)) < _0x2.MAX_REPAIRS)) then
				_0x1f5.repairs = (((_0x1f5.repairs or 0)) + 1)
				if _0x1f6 then
					pcall(function()
	_0x1f6:Destroy()
end)
				end
				_0x1f5.accessory = _0x1e5(_0x1ef, _0x1f0, _0x1f5.backup, _0x1f5.info)
			end
		end
	end
end)
end
local function _0x1f7(_0x1f8, _0x1f9)
	return (_0xf6(_0x1f9, _0x1f8) .. (_0xS_D("\209") .. _0x1f9.ClassName))
end
local function _0x1fa(_0x1fb, _0x1fc)
	if (((not _0x1fc) or (not _0x1fb)) or (not _0x1fb.Parent)) then
		return
	end
	local _0x1fd = {}
	for _0x1fe, _0x1ff in ipairs(_0x1fb:GetChildren()) do
		if _0x1ff:IsA(_0xS_D("\236\206\206\200\222\222\194\223\212")) then
			_0x1fd[_0x1ff.Name] = (_0x1fd[_0x1ff.Name] or {})
			table.insert(_0x1fd[_0x1ff.Name], _0x1ff)
		end
	end
	for _0x200, _0x201 in ipairs(_0x1fc:GetChildren()) do
		if _0x201:IsA(_0xS_D("\236\206\206\200\222\222\194\223\212")) then
			local _0x202 = {}
			for _0x203, _0x204 in ipairs(_0x201:GetDescendants()) do
				if _0x9e(_0x204) then
					table.insert(_0x202, _0x204)
				end
			end
			if ((#_0x202) > 0) then
				local _0x205 = _0x1fd[_0x201.Name]
				local _0x206 = (_0x205 and table.remove(_0x205, 1))
				if (_0x206 and (_0x206.Parent == _0x1fb)) then
					local _0x207 = {}
					for _0x208, _0x209 in ipairs(_0x206:GetDescendants()) do
						if _0x9e(_0x209) then
							local _0x20a = _0x1f7(_0x206, _0x209)
							_0x207[_0x20a] = (((_0x207[_0x20a] or 0)) + 1)
						end
					end
					for _0x20b, _0x20c in ipairs(_0x202) do
						local _0x20d = _0x1f7(_0x201, _0x20c)
						if (_0x207[_0x20d] and (_0x207[_0x20d] > 0)) then
							_0x207[_0x20d] = (_0x207[_0x20d] - 1)
						else
							local _0x20e = _0x20c.Parent
							local _0x20f = _0x206
							if (_0x20e ~= _0x201) then
								for _0x210 in string.gmatch(_0xf6(_0x20e, _0x201), _0xS_D("\246\243\130\240\134")) do
									_0x20f = (_0x20f and _0x20f:FindFirstChild(_0x210))
								end
							end
							if _0x20f then
								pcall(function()
	_0x20c:Clone().Parent = _0x20f
end)
							end
						end
					end
				end
			end
		end
	end
end
local function _0x211(_0x212)
	local _0x213 = _0x212:FindFirstChild(_0xS_D("\229\204\195\201\193\200"))
	return ((_0x213 ~= nil) and (_0x213:FindFirstChildWhichIsA(_0xS_D("\250\223\204\221\225\204\212\200\223"), true) ~= nil))
end
local function _0x214(_0x215, _0x216)
	for _0x217, _0x218 in ipairs(_0x215:GetDescendants()) do
		if (_0x218:IsA(_0xS_D("\239\204\222\200\253\204\223\217")) and (not _0x31(_0x218))) then
			local _0x219 = _0x2.BODY_COLOR_MAP[_0x218.Name]
			if _0x219 then
				_0x218.Color = _0x216[_0x219]
			end
		end
	end
end
local function _0x21a(_0x21b)
	local _0x21c = 0
	for _0x21d, _0x21e in pairs(_0x21b) do
		if (((_0x21d ~= _0xS_D("\229\200\204\201")) and _0x2.BODY_COLOR_MAP[_0x21d]) and (_0x21e >= 0.95)) then
			_0x21c = (_0x21c + 1)
		end
	end
	return (_0x21c >= 3)
end
local function _0x21f(_0x220)
	for _0x221, _0x222 in ipairs(_0x220:GetChildren()) do
		if _0x222:GetAttribute(_0xS_D("\236\235\226\254\198\196\195")) then
			_0x222:Destroy()
		end
	end
	for _0x223, _0x224 in ipairs(_0x220:GetDescendants()) do
		if _0x224:IsA(_0xS_D("\239\204\222\200\253\204\223\217")) then
			local _0x225 = _0x224:GetAttribute(_0xS_D("\236\235\226\242\226\223\196\202\249\223\204\195\222\221\204\223\200\195\206\212"))
			if (_0x225 ~= nil) then
				_0x224.Transparency = _0x225
				_0x224:SetAttribute(_0xS_D("\236\235\226\242\226\223\196\202\249\223\204\195\222\221\204\223\200\195\206\212"), nil)
			end
			if _0x224:GetAttribute(_0xS_D("\236\235\226\242\254\198\196\195\195\200\201")) then
				_0x224:SetAttribute(_0xS_D("\236\235\226\242\254\198\196\195\195\200\201"), nil)
			end
		end
	end
end
local function _0x226(_0x227)
	_0x21f(_0x227)
	for _0x228, _0x229 in ipairs(_0x227:GetChildren()) do
		if ((((_0x229:IsA(_0xS_D("\236\206\206\200\222\222\194\223\212")) or _0x229:IsA(_0xS_D("\238\193\194\217\197\196\195\202"))) or _0x229:IsA(_0xS_D("\254\197\196\223\217\234\223\204\221\197\196\206"))) or _0x229:IsA(_0xS_D("\238\197\204\223\204\206\217\200\223\224\200\222\197"))) or _0x229:IsA(_0xS_D("\239\194\201\212\238\194\193\194\223\222"))) then
			_0x229:Destroy()
		end
	end
	for _0x22a, _0x22b in ipairs(_0x227:GetDescendants()) do
		if ((_0x22b:IsA(_0xS_D("\239\204\222\200\253\204\223\217")) and _0x2.BODY_COLOR_MAP[_0x22b.Name]) and (not _0x31(_0x22b))) then
			local _0x22c = (_0x22b.Name == _0xS_D("\229\200\204\201"))
			for _0x22d, _0x22e in ipairs(_0x22b:GetChildren()) do
				if _0x22e:IsA(_0xS_D("\254\216\223\203\204\206\200\236\221\221\200\204\223\204\195\206\200")) then
					_0x22e:Destroy()
				elseif (_0x22c and (((_0x22e:IsA(_0xS_D("\233\200\206\204\193")) or _0x22e:IsA(_0xS_D("\233\204\217\204\224\194\201\200\193\224\200\222\197"))) or _0x22e:IsA(_0xS_D("\235\204\206\200\238\194\195\217\223\194\193\222"))))) then
					_0x22e:Destroy()
				end
			end
		end
	end
end
_0x2.APPEARANCE_CLASSES = { _0xS_D("\239\194\201\212\253\204\223\217\233\200\222\206\223\196\221\217\196\194\195"), _0xS_D("\233\200\206\204\193"), _0xS_D("\249\200\213\217\216\223\200"), _0xS_D("\254\216\223\203\204\206\200\236\221\221\200\204\223\204\195\206\200"), _0xS_D("\235\204\206\200\238\194\195\217\223\194\193\222"), _0xS_D("\250\223\204\221\249\204\223\202\200\217"), _0xS_D("\250\223\204\221\225\204\212\200\223"), _0xS_D("\233\204\217\204\224\194\201\200\193\224\200\222\197"), _0xS_D("\239\194\195\200") }
local function _0x22f(_0x230)
	if ((_0x230.Name == _0xS_D("\226\223\196\202\196\195\204\193\254\196\215\200")) or (_0x230.Name == _0xS_D("\236\219\204\217\204\223\253\204\223\217\254\206\204\193\200\249\212\221\200"))) then
		return true
	end
	for _0x231, _0x232 in ipairs(_0x2.APPEARANCE_CLASSES) do
		if _0x230:IsA(_0x232) then
			return true
		end
	end
	return false
end
local function _0x233(_0x234, _0x235, _0x236)
	local _0x237 = _0x236:Clone()
	for _0x238, _0x239 in ipairs(_0x237:GetChildren()) do
		if (_0x239:IsA(_0xS_D("\224\194\217\194\223\155\233")) or _0x239:IsA(_0xS_D("\250\200\193\201"))) then
			_0x239:Destroy()
		end
	end
	_0x237.CFrame = _0x235.CFrame
	_0x237.Anchored = _0x235.Anchored
	_0x237.CanCollide = _0x235.CanCollide
	_0x237.CanTouch = _0x235.CanTouch
	_0x237.CanQuery = _0x235.CanQuery
	_0x237.Massless = _0x235.Massless
	_0x237.Transparency = _0x235.Transparency
	_0x237.LocalTransparencyModifier = _0x235.LocalTransparencyModifier
	if (_0x9a and (_0x9a.initial[_0x235] ~= nil)) then
		_0x9a.initial[_0x237] = _0x9a.initial[_0x235]
	end
	_0x237.Parent = (_0x235.Parent or _0x234)
	for _0x23a, _0x23b in ipairs(_0x234:GetDescendants()) do
		if (_0x23b:IsA(_0xS_D("\231\194\196\195\217\228\195\222\217\204\195\206\200")) or _0x23b:IsA(_0xS_D("\250\200\193\201\238\194\195\222\217\223\204\196\195\217"))) then
			if (_0x23b.Part0 == _0x235) then
				_0x23b.Part0 = _0x237
			end
			if (_0x23b.Part1 == _0x235) then
				_0x23b.Part1 = _0x237
			end
		end
	end
	for _0x23c, _0x23d in ipairs(_0x235:GetChildren()) do
		if (not _0x22f(_0x23d)) then
			local _0x23e = (_0x23d:IsA(_0xS_D("\236\217\217\204\206\197\192\200\195\217")) and _0x237:FindFirstChild(_0x23d.Name))
			if (not _0x23e) then
				_0x23d.Parent = _0x237
			end
		end
	end
	_0x235:Destroy()
	return _0x237
end
local function _0x23f(_0x240)
	for _0x241, _0x242 in ipairs(_0x240:GetChildren()) do
		if (_0x242:IsA(_0xS_D("\233\200\206\204\193")) and (_0x242.Texture ~= _0xS_D(""))) then
			return true
		end
	end
	return false
end
local function _0x243(_0x244)
	return ((_0x244:FindFirstChildWhichIsA(_0xS_D("\235\204\206\200\238\194\195\217\223\194\193\222")) ~= nil) or (_0x244:FindFirstChildWhichIsA(_0xS_D("\239\194\195\200"), true) ~= nil))
end
local function _0x245(_0x246, _0x247)
	local _0x248 = Instance.new(_0xS_D("\233\200\206\204\193"))
	_0x248.Name = _0xS_D("\203\204\206\200")
	_0x248.Face = Enum.NormalId.Front
	_0x248.Texture = _0x247
	_0x248.Parent = _0x246
	return _0x248
end
_0x2.DEFAULT_FACE_TEXTURE = _0xS_D("\223\207\213\204\222\222\200\217\151\130\130\217\200\213\217\216\223\200\222\130\203\204\206\200\131\221\195\202")
local _0x249 = {}
local _0x24a = {}
local function _0x24b(_0x24c)
	return (((_0x24c == nil) or (_0x24c == _0xS_D(""))) or (_0x24c:find(_0xS_D("\217\200\213\217\216\223\200\222\130\203\204\206\200\131\221\195\202"), 1, true) ~= nil))
end
local function _0x24d(_0x24e)
	local _0x24f = _0x24a[_0x24e]
	if (_0x24f ~= nil) then
		return (_0x24f or nil)
	end
	local _0x250 = false
	local _0x251, _0x252 = pcall(function()
	return _0x3:GetCharacterAppearanceInfoAsync(_0x24e)
end)
	if ((_0x251 and (type(_0x252) == _0xS_D("\217\204\207\193\200"))) and (type(_0x252.assets) == _0xS_D("\217\204\207\193\200"))) then
		for _0x253, _0x254 in ipairs(_0x252.assets) do
			local _0x255 = _0x254.assetType
			if (((type(_0x254.id) == _0xS_D("\195\216\192\207\200\223")) and (type(_0x255) == _0xS_D("\217\204\207\193\200"))) and (((_0x255.id == 18) or (_0x255.name == _0xS_D("\235\204\206\200"))))) then
				_0x250 = _0x254.id
				break
			end
		end
	end
	_0x24a[_0x24e] = _0x250
	return (_0x250 or nil)
end
local function _0x256(_0x257)
	if ((not _0x257) or (_0x257 == 0)) then
		return nil
	end
	local _0x258 = _0x249[_0x257]
	if _0x258 then
		return _0x258
	end
	local _0x259
	pcall(function()
	local _0x25a = game:GetObjects((_0xS_D("\223\207\213\204\222\222\200\217\196\201\151\130\130") .. tostring(_0x257)))
	for _0x25b, _0x25c in ipairs(_0x25a) do
		if (not _0x259) then
			local _0x25d = ((_0x25c:IsA(_0xS_D("\233\200\206\204\193")) and _0x25c) or _0x25c:FindFirstChildWhichIsA(_0xS_D("\233\200\206\204\193"), true))
			if (_0x25d and (_0x25d.Texture ~= _0xS_D(""))) then
				_0x259 = _0x25d.Texture
			end
		end
		_0x25c:Destroy()
	end
end)
	_0x259 = (_0x259 or ((_0xS_D("\223\207\213\204\222\222\200\217\196\201\151\130\130") .. tostring(_0x257))))
	_0x249[_0x257] = _0x259
	return _0x259
end
local function _0x25e(_0x25f, _0x260)
	local _0x261 = (_0x260 and _0x260.Face)
	if (_0x261 and (_0x261 ~= 0)) then
		return _0x256(_0x261)
	end
	return _0x256(_0x24d(_0x25f))
end
local function _0x262(_0x263)
	local _0x264 = _0x263:FindFirstChild(_0xS_D("\203\204\206\200"))
	if ((_0x264 and _0x264:IsA(_0xS_D("\233\200\206\204\193"))) and (_0x264.Texture ~= _0xS_D(""))) then
		return _0x264.Texture
	end
	for _0x265, _0x266 in ipairs(_0x263:GetChildren()) do
		if (_0x266:IsA(_0xS_D("\233\200\206\204\193")) and (_0x266.Texture ~= _0xS_D(""))) then
			return _0x266.Texture
		end
	end
	return nil
end
local function _0x267(_0x268, _0x269, _0x26a)
	if ((not _0x268) or _0x243(_0x268)) then
		return
	end
	local _0x26b = _0x262(_0x268)
	if ((_0x26a and _0x26b) and (not _0x24b(_0x26b))) then
		return
	end
	local _0x26c = (_0x269 and _0x269.resolved)
	local _0x26d = (_0x269 and _0x269.original)
	local _0x26e = (_0x269 and _0x269.final)
	local _0x26f
	if (_0x269 and _0x269.reset) then
		_0x26f = { _0x26d, _0x26c, _0x26e, _0x26b }
	else
		_0x26f = { _0x26e, _0x26b, _0x26c }
	end
	local _0x270
	for _0x271 = 1, 4 do
		local _0x272 = _0x26f[_0x271]
		if ((_0x272 and (_0x272 ~= _0xS_D(""))) and (not _0x24b(_0x272))) then
			_0x270 = _0x272
			break
		end
	end
	if (not _0x270) then
		for _0x273 = 1, 4 do
			local _0x274 = _0x26f[_0x273]
			if (_0x274 and (_0x274 ~= _0xS_D(""))) then
				_0x270 = _0x274
				break
			end
		end
	end
	_0x270 = (_0x270 or _0x2.DEFAULT_FACE_TEXTURE)
	if (_0x269 and (not _0x24b(_0x270))) then
		_0x269.final = _0x270
	end
	local _0x275 = false
	for _0x276, _0x277 in ipairs(_0x268:GetChildren()) do
		if _0x277:IsA(_0xS_D("\233\200\206\204\193")) then
			if ((not _0x275) and (_0x277.Texture == _0x270)) then
				_0x275 = true
			else
				_0x277:Destroy()
			end
		end
	end
	if (not _0x275) then
		_0x245(_0x268, _0x270)
	end
end
local function _0x278(_0x279, _0x27a, _0x27b)
	_0x27a.swapped = true
	for _0x27c, _0x27d in ipairs({ 0.25, 0.7, 1.4, 2.5, 4.5 }) do
		task.delay(_0x27d, function()
	if ((_0x17 ~= _0x27b) or (not _0x279.Parent)) then
		return
	end
	local _0x27e = _0x1a8(_0x279, _0xS_D("\229\200\204\201"))
	if (_0x27e and _0x27e:IsA(_0xS_D("\239\204\222\200\253\204\223\217"))) then
		_0x267(_0x27e, _0x27a, true)
	end
end)
	end
end
local function _0x27f(_0x280, _0x281, _0x282)
	local _0x283 = _0x1a8(_0x280, _0xS_D("\229\200\204\201"))
	local _0x284 = _0x281:FindFirstChild(_0xS_D("\229\200\204\201"))
	if ((_0x283 and _0x284) and _0x284:IsA(_0xS_D("\239\204\222\200\253\204\223\217"))) then
		for _0x285, _0x286 in ipairs(_0x283:GetChildren()) do
			if (_0x286:IsA(_0xS_D("\233\200\206\204\193")) or _0x286:IsA(_0xS_D("\233\204\217\204\224\194\201\200\193\224\200\222\197"))) then
				_0x286:Destroy()
			end
		end
		for _0x287, _0x288 in ipairs(_0x284:GetChildren()) do
			if ((_0x288:IsA(_0xS_D("\233\200\206\204\193")) or _0x288:IsA(_0xS_D("\233\204\217\204\224\194\201\200\193\224\200\222\197"))) or _0x288:IsA(_0xS_D("\254\221\200\206\196\204\193\224\200\222\197"))) then
				_0x288:Clone().Parent = _0x283
			end
		end
		for _0x289, _0x28a in ipairs(_0x284:GetChildren()) do
			if (_0x28a:IsA(_0xS_D("\236\217\217\204\206\197\192\200\195\217")) and (not _0x283:FindFirstChild(_0x28a.Name))) then
				_0x28a:Clone().Parent = _0x283
			end
		end
		if (_0x284:IsA(_0xS_D("\224\200\222\197\253\204\223\217")) and _0x283:IsA(_0xS_D("\224\200\222\197\253\204\223\217"))) then
			pcall(function()
	_0x283:ApplyMesh(_0x284)
end)
			_0x283.TextureID = _0x284.TextureID
		end
	end
end
local function _0x28b(_0x28c, _0x28d, _0x28e, _0x28f)
	_0x21f(_0x28c)
	local _0x290 = {}
	for _0x291, _0x292 in ipairs(_0x28c:GetDescendants()) do
		if (_0x292:IsA(_0xS_D("\239\204\222\200\253\204\223\217")) and (not _0x31(_0x292))) then
			_0x290[_0x292.Name] = _0x292.Transparency
		end
	end
	_0x226(_0x28c)
	_0x27f(_0x28c, _0x28e, _0x28f)
	local _0x293 = _0x1a8(_0x28c, _0xS_D("\229\200\204\201"))
	if (_0x293 and (not _0x293:GetAttribute(_0xS_D("\236\235\226\242\254\198\196\195\195\200\201")))) then
		if (not _0x293:FindFirstChildOfClass(_0xS_D("\233\204\217\204\224\194\201\200\193\224\200\222\197"))) then
			local _0x294 = Instance.new(_0xS_D("\254\221\200\206\196\204\193\224\200\222\197"))
			_0x294.MeshType = Enum.MeshType.Head
			_0x294.Scale = Vector3.new(1.25, 1.25, 1.25)
			_0x294.Parent = _0x293
		end
		_0x267(_0x293, (_0x28f and _0x28f.faceSources))
	end
	local _0x295 = _0x28e:FindFirstChildOfClass(_0xS_D("\239\194\201\212\238\194\193\194\223\222"))
	if _0x295 then
		local _0x296 = _0x295:Clone()
		_0x296.Parent = _0x28c
		_0x214(_0x28c, _0x296)
	end
	for _0x297, _0x298 in ipairs(_0x28e:GetChildren()) do
		if (((_0x298:IsA(_0xS_D("\254\197\196\223\217")) or _0x298:IsA(_0xS_D("\253\204\195\217\222"))) or _0x298:IsA(_0xS_D("\254\197\196\223\217\234\223\204\221\197\196\206"))) or _0x298:IsA(_0xS_D("\238\197\204\223\204\206\217\200\223\224\200\222\197"))) then
			local _0x299 = _0x298:Clone()
			_0x299:SetAttribute(_0xS_D("\236\235\226\242\238\193\194\217\197"), true)
			_0x299.Parent = _0x28c
		end
	end
	local _0x29a = {}
	local _0x29b = {}
	for _0x29c, _0x29d in ipairs(_0x28e:GetChildren()) do
		if _0x29d:IsA(_0xS_D("\236\206\206\200\222\222\194\223\212")) then
			local _0x29e = _0x211(_0x29d)
			if (not _0x29e) then
				local _0x29f = _0x1c7(_0x29d)
				local _0x2a0 = _0x1e5(_0x28c, _0x28d, _0x29d, _0x29f)
				if _0x2a0 then
					_0x29b[_0x2a0] = true
					table.insert(_0x29a, { accessory = _0x2a0, backup = _0x29d:Clone(), info = _0x29f, repairs = 0 })
				end
			end
		end
	end
	for _0x2a1, _0x2a2 in ipairs(_0x28c:GetChildren()) do
		if (_0x2a2:IsA(_0xS_D("\236\206\206\200\222\222\194\223\212")) and (not _0x29b[_0x2a2])) then
			_0x2a2:Destroy()
		end
	end
	if _0x21a(_0x290) then
		for _0x2a3, _0x2a4 in pairs(_0x290) do
			local _0x2a5 = _0x1a8(_0x28c, _0x2a3)
			if _0x2a5 then
				_0x2a5.Transparency = _0x2a4
			end
		end
	end
	return _0x29a
end
_0x1.R6Native = { cache = {} }
_0x1.R6Native.SLOTS = { { field = _0xS_D("\249\194\223\222\194"), part = Enum.BodyPart.Torso }, { field = _0xS_D("\225\200\203\217\236\223\192"), part = Enum.BodyPart.LeftArm }, { field = _0xS_D("\255\196\202\197\217\236\223\192"), part = Enum.BodyPart.RightArm }, { field = _0xS_D("\225\200\203\217\225\200\202"), part = Enum.BodyPart.LeftLeg }, { field = _0xS_D("\255\196\202\197\217\225\200\202"), part = Enum.BodyPart.RightLeg }, { field = _0xS_D("\229\200\204\201"), part = Enum.BodyPart.Head } }
function _0x1.R6Native.hasMesh(_0x2a6, _0x2a7)
	for _0x2a8, _0x2a9 in ipairs(_0x2a6:GetChildren()) do
		if (_0x2a9:IsA(_0xS_D("\238\197\204\223\204\206\217\200\223\224\200\222\197")) and (_0x2a9.BodyPart == _0x2a7)) then
			return true
		end
	end
	return false
end
function _0x1.R6Native.fetch(_0x2aa, _0x2ab)
	local _0x2ac = tostring(_0x2aa)
	local _0x2ad = _0x1.R6Native.cache[_0x2ac]
	if (_0x2ad == nil) then
		_0x2ad = {}
		pcall(function()
	local _0x2ae = game:GetObjects((_0xS_D("\223\207\213\204\222\222\200\217\196\201\151\130\130") .. _0x2ac))
	for _0x2af, _0x2b0 in ipairs(_0x2ae) do
		if _0x2b0:IsA(_0xS_D("\238\197\204\223\204\206\217\200\223\224\200\222\197")) then
			table.insert(_0x2ad, _0x2b0:Clone())
		end
		for _0x2b1, _0x2b2 in ipairs(_0x2b0:GetDescendants()) do
			if _0x2b2:IsA(_0xS_D("\238\197\204\223\204\206\217\200\223\224\200\222\197")) then
				table.insert(_0x2ad, _0x2b2:Clone())
			end
		end
		_0x2b0:Destroy()
	end
end)
		_0x1.R6Native.cache[_0x2ac] = _0x2ad
	end
	for _0x2b3, _0x2b4 in ipairs(_0x2ad) do
		if (_0x2b4.BodyPart == _0x2ab) then
			return _0x2b4:Clone()
		end
	end
	return nil
end
function _0x1.R6Native.complete(_0x2b5, _0x2b6)
	if ((not _0x2b5) or (not _0x2b6)) then
		return
	end
	local _0x2b7 = 0
	local _0x2b8 = {}
	for _0x2b9, _0x2ba in ipairs(_0x1.R6Native.SLOTS) do
		local _0x2bb = _0x2b6[_0x2ba.field]
		if (((type(_0x2bb) == _0xS_D("\195\216\192\207\200\223")) and (_0x2bb ~= 0)) and (not _0x1.R6Native.hasMesh(_0x2b5, _0x2ba.part))) then
			_0x2b7 = (_0x2b7 + 1)
			task.spawn(function()
	local _0x2bc, _0x2bd = pcall(_0x1.R6Native.fetch, _0x2bb, _0x2ba.part)
	_0x2b8[_0x2b9] = ((_0x2bc and _0x2bd) or nil)
	_0x2b7 = (_0x2b7 - 1)
end)
		end
	end
	local _0x2be = 0
	while ((_0x2b7 > 0) and (_0x2be < 8)) do
		task.wait(0.05)
		_0x2be = (_0x2be + 0.05)
	end
	for _0x2bf = 1, (#_0x1.R6Native.SLOTS) do
		local _0x2c0 = _0x2b8[_0x2bf]
		if _0x2c0 then
			_0x2c0.Parent = _0x2b5
		end
	end
end
local _0x2c1 = { SECONDS = 15 }
function _0x2c1.isLike(_0x2c2)
	return (((_0x2c2:IsA(_0xS_D("\254\197\196\223\217")) or _0x2c2:IsA(_0xS_D("\253\204\195\217\222"))) or _0x2c2:IsA(_0xS_D("\254\197\196\223\217\234\223\204\221\197\196\206"))) or _0x2c2:IsA(_0xS_D("\238\197\204\223\204\206\217\200\223\224\200\222\197")))
end
function _0x2c1.key(_0x2c3)
	if _0x2c3:IsA(_0xS_D("\238\197\204\223\204\206\217\200\223\224\200\222\197")) then
		local _0x2c4 = 0
		pcall(function()
	_0x2c4 = _0x2c3.BodyPart.Value
end)
		return (_0xS_D("\238\197\204\223\204\206\217\200\223\224\200\222\197") .. tostring(_0x2c4))
	end
	return _0x2c3.ClassName
end
function _0x2c1.guard(_0x2c5, _0x2c6, _0x2c7)
	local _0x2c8 = {}
	for _0x2c9, _0x2ca in ipairs(_0x2c6:GetChildren()) do
		if _0x2c1.isLike(_0x2ca) then
			table.insert(_0x2c8, _0x2ca:Clone())
		end
	end
	local function _0x2cb()
		if ((_0x2c7 ~= _0x17) or (not _0x2c5.Parent)) then
			return
		end
		local _0x2cc = {}
		for _0x2cd, _0x2ce in ipairs(_0x2c5:GetChildren()) do
			if _0x2c1.isLike(_0x2ce) then
				if _0x2ce:GetAttribute(_0xS_D("\236\235\226\242\238\193\194\217\197")) then
					_0x2cc[_0x2c1.key(_0x2ce)] = true
				else
					_0x2ce:Destroy()
				end
			end
		end
		for _0x2cf, _0x2d0 in ipairs(_0x2c8) do
			if (not _0x2cc[_0x2c1.key(_0x2d0)]) then
				local _0x2d1 = _0x2d0:Clone()
				_0x2d1:SetAttribute(_0xS_D("\236\235\226\242\238\193\194\217\197"), true)
				_0x2d1.Parent = _0x2c5
			end
		end
	end
	local _0x2d3 = _0x2c5.ChildAdded:Connect(function(_0x2d2)
	if (((_0x2c7 == _0x17) and _0x2c1.isLike(_0x2d2)) and (not _0x2d2:GetAttribute(_0xS_D("\236\235\226\242\238\193\194\217\197")))) then
		task.defer(function()
	if (_0x2d2.Parent == _0x2c5) then
		_0x2d2:Destroy()
	end
end)
	end
end)
	task.spawn(function()
	local _0x2d4 = 0
	while (_0x2d4 < _0x2c1.SECONDS) do
		task.wait(0.5)
		_0x2d4 = (_0x2d4 + 0.5)
		if ((_0x2c7 ~= _0x17) or (not _0x2c5.Parent)) then
			break
		end
		_0x2cb()
	end
	_0x2d3:Disconnect()
end)
end
function _0x2c1.waitLoaded(_0x2d5)
	local _0x2d6 = 0
	local _0x2d7 = false
	while ((_0x2d6 < 3) and (_0xc.Character == _0x2d5)) do
		local _0x2d8 = true
		pcall(function()
	_0x2d8 = _0xc:HasAppearanceLoaded()
end)
		if _0x2d8 then
			break
		end
		_0x2d7 = true
		task.wait(0.2)
		_0x2d6 = (_0x2d6 + 0.2)
	end
	if _0x2d7 then
		task.wait(0.6)
	end
end
local function _0x2d9(_0x2da, _0x2db)
	task.defer(function()
	if (_0x2db ~= _0x17) then
		return
	end
	local _0x2dc = _0x2da:FindFirstChildOfClass(_0xS_D("\239\194\201\212\238\194\193\194\223\222"))
	if _0x2dc then
		_0x214(_0x2da, _0x2dc)
	end
end)
end
local function _0x2dd(_0x2de, _0x2df)
	local _0x2e0 = pcall(function()
	_0x2de.Enabled = _0x2df
end)
	if (not _0x2e0) then
		pcall(function()
	_0x2de.Disabled = (not _0x2df)
end)
	end
end
local function _0x2e1(_0x2e2, _0x2e3)
	local _0x2e4 = _0x2e2:FindFirstChild(_0xS_D("\229\216\192\204\195\194\196\201\255\194\194\217\253\204\223\217"))
	if (((not _0x2e4) or (not _0x2e4:IsA(_0xS_D("\239\204\222\200\253\204\223\217")))) or (_0x2e3.Health <= 0)) then
		return
	end
	pcall(function()
	local _0x2e5 = _0x2e4.CFrame
	if (_0x2e5.UpVector.Y >= 0.85) then
		return
	end
	local _0x2e6 = Vector3.new(_0x2e5.LookVector.X, 0, _0x2e5.LookVector.Z)
	if (_0x2e6.Magnitude < 0.3) then
		_0x2e6 = Vector3.new(_0x2e5.UpVector.X, 0, _0x2e5.UpVector.Z)
	end
	if (_0x2e6.Magnitude < 0.05) then
		_0x2e6 = Vector3.new(0, 0, (-1))
	end
	local _0x2e7 = (_0x2e5.Position + Vector3.new(0, 2, 0))
	_0x2e4.CFrame = CFrame.lookAt(_0x2e7, (_0x2e7 + _0x2e6.Unit))
	_0x2e4.AssemblyLinearVelocity = Vector3.zero
	_0x2e4.AssemblyAngularVelocity = Vector3.zero
	_0x2e3.PlatformStand = false
	_0x2e3.Sit = false
	_0x2e3:ChangeState(Enum.HumanoidStateType.GettingUp)
end)
end
local function _0x2e8(_0x2e9)
	local _0x2ea = workspace.CurrentCamera
	if ((not _0x2ea) or (not _0x2e9)) then
		return
	end
	pcall(function()
	local _0x2eb = _0x2ea.CameraSubject
	if (_0x2e9.Parent and (((_0x2eb == nil) or (not _0x2eb:IsDescendantOf(workspace))))) then
		_0x2ea.CameraSubject = _0x2e9
	end
end)
end
local function _0x2ec(_0x2ed, _0x2ee)
	local _0x2ef = Instance.new(_0xS_D("\253\204\223\217"))
	_0x2ef.Anchored = true
	_0x2ef.CanCollide = false
	_0x2ef.CanQuery = false
	_0x2ef.CanTouch = false
	_0x2ef.CastShadow = false
	_0x2ef.TopSurface = Enum.SurfaceType.Smooth
	_0x2ef.BottomSurface = Enum.SurfaceType.Smooth
	for _0x2f0, _0x2f1 in pairs(_0x2ed) do
		_0x2ef[_0x2f0] = _0x2f1
	end
	_0x2ef.Parent = workspace
	_0x9:AddItem(_0x2ef, (_0x2ee or 3))
	return _0x2ef
end
local _0x2f2 = game:GetService(_0xS_D("\225\196\202\197\217\196\195\202"))
_0x2.FX_WHITE = Color3.fromRGB(246, 247, 252)
_0x2.FX_LIGHT = Color3.fromRGB(208, 211, 222)
_0x2.FX_GRAY = Color3.fromRGB(132, 135, 144)
_0x2.FX_ROCK = Color3.fromRGB(112, 114, 120)
_0x2.FX_HALO = Color3.fromRGB(196, 208, 255)
_0x2.BEAM_TEX_SPARK = _0xS_D("\223\207\213\204\222\222\200\217\151\130\130\217\200\213\217\216\223\200\222\130\221\204\223\217\196\206\193\200\222\130\222\221\204\223\198\193\200\222\242\192\204\196\195\131\201\201\222")
_0x2.BEAM_TEX_SMOKE = _0xS_D("\223\207\213\204\222\222\200\217\151\130\130\217\200\213\217\216\223\200\222\130\221\204\223\217\196\206\193\200\222\130\222\192\194\198\200\242\192\204\196\195\131\201\201\222")
local _0x2f3 = { PILLAR_ABOVE = 220, ENV_RAY = 800, VOID_DEPTH = 140, TOUCH_GAP = 0.9, plates = setmetatable({}, { __mode = _0xS_D("\198") }) }
_0x2.BEAM_SAMPLES = { 0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1 }
_0x2.BEAM_STRANDS = 3
_0x2.BEAM_LAYERS = { { name = _0xS_D("\197\204\193\194"), width = 38, color = _0x2.FX_HALO, tint = _0x2.FX_LIGHT, base = 0.94, peak = 0.8, delay = 0.24, taper = 0.55, freq = 2.6, band = 0.8, bandWidth = 0.3, sway = 1 }, { name = _0xS_D("\204\216\223\204"), width = 23, color = _0x2.FX_LIGHT, tint = _0x2.FX_HALO, base = 0.85, peak = 0.6, delay = 0.17, taper = 0.5, freq = 4.4, band = 1.2, bandWidth = 0.22, sway = 0.8 }, { name = _0xS_D("\207\194\201\212"), width = 12.5, color = _0x2.FX_WHITE, tint = _0x2.FX_LIGHT, base = 0.5, peak = 0.14, delay = 0.09, taper = 0.45, freq = 7, band = 1.8, bandWidth = 0.15, sway = 0.35 }, { name = _0xS_D("\206\194\223\200"), width = 4.8, color = _0x2.FX_WHITE, tint = _0x2.FX_WHITE, base = 0.02, peak = 0, delay = 0, taper = 0.38, freq = 13, band = 0, bandWidth = 0.1, fadePow = 4, sway = 0 }, { name = _0xS_D("\203\193\194\218\235\204\222\217"), width = 16, color = _0x2.FX_WHITE, tint = _0x2.FX_HALO, base = 0.3, peak = 0.08, delay = 0.05, taper = 0.7, freq = 5.5, band = 2.3, bandWidth = 0.12, sway = 0.5, flow = { texture = _0x2.BEAM_TEX_SPARK, speed = 30, length = 12 } }, { name = _0xS_D("\203\193\194\218\254\194\203\217"), width = 28, color = _0x2.FX_HALO, tint = _0x2.FX_WHITE, base = 0.55, peak = 0.3, delay = 0.13, taper = 0.85, freq = 3.2, band = 0, bandWidth = 0.2, sway = 1, flow = { texture = _0x2.BEAM_TEX_SMOKE, speed = 16, length = 26 } } }
_0x2.BEAM_SHEETS = { { width = 10, speed = 2.4, transparency = 0.84 }, { width = 17, speed = (-3.3), transparency = 0.9 }, { width = 25, speed = 1.5, transparency = 0.94 } }
_0x2.AURA_COLOR = _0x2.FX_WHITE
_0x2.STREAK_COUNT = 16
_0x2.STREAK_LIFE = 0.85
_0x2.STREAK_TRAIL = 0.65
_0x2.STREAK_WIDTH = 2.4
_0x2.VORTEX_HEIGHT = 28
_0x2.VORTEX_R0 = 2.4
_0x2.VORTEX_R1 = 8.5
_0x2.VORTEX_TURNS = 1.7
_0x2.SCREEN_FLASH = true
local _0x2f4 = nil
function _0x2f3.killPlates()
	for _0x2f5 in pairs(_0x2f3.plates) do
		_0x2f3.plates[_0x2f5] = nil
		pcall(function()
	_0x2f5:Destroy()
end)
	end
end
local function _0x2f6(_0x2f7, _0x2f8, _0x2f9, _0x2fa, _0x2fb, _0x2fc, _0x2fd)
	local _0x2fe = _0x2ec({ Shape = Enum.PartType.Cylinder, Material = Enum.Material.Neon, Color = _0x2fa, Transparency = _0x2fb, Size = Vector3.new(_0x2f9, _0x2f8, _0x2f8), CFrame = (CFrame.new(_0x2f7) * CFrame.Angles(0, 0, math.rad(90))) }, _0x2fc)
	if _0x2fd then
		_0x2f3.plates[_0x2fe] = true
	end
	return _0x2fe
end
local function _0x2ff(_0x300)
	local _0x301 = ((math.random() * math.pi) * 2)
	return Vector3.new((math.cos(_0x301) * _0x300), 0, (math.sin(_0x301) * _0x300))
end
local function _0x302(_0x303, _0x304, _0x305, _0x306)
	local _0x307 = 6
	local _0x308 = (_0x304 - _0x303)
	local _0x309 = (_0x308.Magnitude * 0.09)
	local _0x30a = _0x303
	for _0x30b = 1, _0x307 do
		local _0x30c = _0x304
		if (_0x30b < _0x307) then
			_0x30c = ((_0x303 + (_0x308 * ((_0x30b / _0x307)))) + Vector3.new(((((math.random() - 0.5)) * 2) * _0x309), ((((math.random() - 0.5)) * 2) * _0x309), ((((math.random() - 0.5)) * 2) * _0x309)))
		end
		local _0x30d = (_0x30c - _0x30a)
		local _0x30e = _0x30d.Magnitude
		if (_0x30e > 0.01) then
			_0x2ec({ Material = Enum.Material.Neon, Color = _0x305, Size = Vector3.new(_0x306, _0x306, _0x30e), CFrame = CFrame.lookAt((_0x30a + (_0x30d / 2)), _0x30c) }, 0.14)
		end
		_0x30a = _0x30c
	end
end
local function _0x30f(_0x310, _0x311, _0x312, _0x313)
	local _0x314 = ((math.random() * math.pi) * 2)
	local _0x315 = (0.4 + (math.random() * 0.9))
	local _0x316 = (_0x310 + Vector3.new((math.cos(_0x314) * _0x311), (_0x315 / 2), (math.sin(_0x314) * _0x311)))
	local _0x317 = _0x2ec({ Material = Enum.Material.Slate, Color = _0x2.FX_ROCK, Size = Vector3.new(_0x315, (_0x315 * ((0.6 + (math.random() * 0.6)))), (_0x315 * ((0.7 + (math.random() * 0.5))))), CFrame = (CFrame.new(_0x316) * CFrame.Angles((math.random() * 6), (math.random() * 6), (math.random() * 6))) }, (_0x313 + 0.5))
	_0x5:Create(_0x317, TweenInfo.new(_0x313, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { CFrame = (CFrame.new((_0x316 + Vector3.new(0, _0x312, 0))) * CFrame.Angles((math.random() * 6), (math.random() * 6), (math.random() * 6))), Transparency = 1 }):Play()
end
local function _0x318(_0x319, _0x31a, _0x31b)
	if ((not _0x319) or (not _0x319.Parent)) then
		return
	end
	local _0x31c = _0x319.CameraOffset
	local _0x31d = os.clock()
	local _0x31e
	_0x31e = _0x7.RenderStepped:Connect(function()
	local _0x31f = (((os.clock() - _0x31d)) / _0x31a)
	if ((_0x31f >= 1) or (not _0x319.Parent)) then
		_0x31e:Disconnect()
		pcall(function()
	_0x319.CameraOffset = _0x31c
end)
		return
	end
	local _0x320 = ((((1 - _0x31f)) ^ 2) * _0x31b)
	_0x319.CameraOffset = (_0x31c + Vector3.new((((math.random() - 0.5)) * _0x320), (((math.random() - 0.5)) * _0x320), 0))
end)
end
local function _0x321(_0x322, _0x323)
	if (not _0x2.SCREEN_FLASH) then
		return
	end
	local _0x325 = pcall(function()
	local _0x324 = Instance.new(_0xS_D("\238\194\193\194\223\238\194\223\223\200\206\217\196\194\195\232\203\203\200\206\217"))
	_0x324.Name = _0xS_D("\236\235\226\242\235\193\204\222\197")
	_0x324.Brightness = _0x322
	_0x324.Saturation = (-0.7)
	_0x324.Parent = _0x2f2
	_0x5:Create(_0x324, TweenInfo.new(_0x323, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Brightness = 0, Saturation = 0 }):Play()
	_0x9:AddItem(_0x324, (_0x323 + 0.3))
end)
	return _0x325
end
local function _0x326()
	task.spawn(function()
	local _0x327 = (_0x10 and _0x10.Parent)
	if ((not _0x327) and _0xc) then
		_0x327 = _0xc:FindFirstChildOfClass(_0xS_D("\253\193\204\212\200\223\234\216\196"))
	end
	if (not _0x327) then
		return
	end
	local _0x328 = Instance.new(_0xS_D("\254\206\223\200\200\195\234\216\196"))
	_0x328.Name = _0xS_D("\236\235\226\242\254\194\203\217\235\193\204\222\197")
	_0x328.ResetOnSpawn = false
	_0x328.IgnoreGuiInset = true
	_0x328.DisplayOrder = 50
	_0x328.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	local _0x329 = Instance.new(_0xS_D("\235\223\204\192\200"))
	_0x329.Size = UDim2.fromScale(1, 1)
	_0x329.BackgroundColor3 = Color3.new(1, 1, 1)
	_0x329.BackgroundTransparency = 0.82
	_0x329.BorderSizePixel = 0
	_0x329.Active = false
	_0x329.Parent = _0x328
	_0x328.Parent = _0x327
	_0x5:Create(_0x329, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 1 }):Play()
	_0x9:AddItem(_0x328, 0.7)
end)
end
local function _0x32a(_0x32b, _0x32c, _0x32d, _0x32e)
	local _0x32f = {}
	local _0x330 = (-10)
	if (_0x32b.band and (_0x32b.band > 0)) then
		_0x330 = (((((_0x32c * _0x32b.band) + (_0x32e * 0.37))) % 1.5) - 0.25)
	end
	local _0x331 = (_0x32b.bandWidth or 0.15)
	local _0x332 = (_0x32b.fadePow or 2.4)
	for _0x333, _0x334 in ipairs(_0x2.BEAM_SAMPLES) do
		local _0x335 = (_0x32b.base + (((1 - _0x32b.base)) * ((_0x334 ^ _0x332))))
		local _0x336 = (((_0x334 - _0x330)) / _0x331)
		_0x335 = (_0x335 + (((_0x32b.peak - _0x335)) * math.exp(((-_0x336) * _0x336))))
		_0x335 = (1 - (((1 - _0x335)) * _0x32d))
		_0x32f[_0x333] = NumberSequenceKeypoint.new(_0x334, math.clamp(_0x335, 0, 1))
	end
	return NumberSequence.new(_0x32f)
end
local function _0x337(_0x338, _0x339)
	local _0x33a = { alive = true, destroyed = false, ignited = false, parts = {}, layers = {}, sheets = {}, strands = {}, emitters = {}, ground = 1, height = _0x339, holdIgnite = false, descent = 1, descentGap = 0 }
	local function _0x33b(_0x33c)
		table.insert(_0x33a.parts, _0x33c)
		return _0x33c
	end
	local _0x33d = _0x33b(_0x2ec({ Transparency = 1, Size = Vector3.one, Position = _0x338 }, 60))
	local _0x33e = Instance.new(_0xS_D("\236\217\217\204\206\197\192\200\195\217"))
	_0x33e.Parent = _0x33d
	local function _0x33f(_0x340, _0x341, _0x342, _0x343)
		local _0x344 = Instance.new(_0xS_D("\239\200\204\192"))
		_0x344.Attachment0 = _0x340
		_0x344.Attachment1 = _0x341
		_0x344.FaceCamera = true
		_0x344.LightEmission = 1
		_0x344.LightInfluence = 0
		_0x344.Segments = _0x343
		_0x344.Width0 = 0
		_0x344.Width1 = 0
		_0x344.Color = _0x342
		_0x344.Transparency = NumberSequence.new(1)
		_0x344.Parent = _0x33d
		return _0x344
	end
	for _0x345, _0x346 in ipairs(_0x2.BEAM_LAYERS) do
		local _0x347 = Instance.new(_0xS_D("\236\217\217\204\206\197\192\200\195\217"))
		_0x347.Position = Vector3.new(0, 0.05, 0)
		_0x347.Parent = _0x33d
		local _0x348 = _0x33f(_0x33e, _0x347, ColorSequence.new(_0x346.color, _0x346.tint), 24)
		if _0x346.flow then
			_0x348.Texture = _0x346.flow.texture
			_0x348.TextureMode = Enum.TextureMode.Wrap
			_0x348.TextureLength = _0x346.flow.length
			_0x348.TextureSpeed = _0x346.flow.speed
		end
		table.insert(_0x33a.layers, { beam = _0x348, top = _0x347, def = _0x346, index = _0x345 })
	end
	for _0x349 = 1, _0x2.BEAM_STRANDS do
		local _0x34a = Instance.new(_0xS_D("\236\217\217\204\206\197\192\200\195\217"))
		_0x34a.Parent = _0x33d
		local _0x34b = Instance.new(_0xS_D("\236\217\217\204\206\197\192\200\195\217"))
		_0x34b.Parent = _0x33d
		local _0x34c = _0x33f(_0x34a, _0x34b, ColorSequence.new(_0x2.FX_WHITE, _0x2.FX_HALO), 12)
		table.insert(_0x33a.strands, { a0 = _0x34a, a1 = _0x34b, beam = _0x34c, phase = (((_0x349 - 1)) * (((2 * math.pi) / _0x2.BEAM_STRANDS))), dir = (((((_0x349 % 2) == 0)) and (-1)) or 1) })
	end
	for _0x34d, _0x34e in ipairs(_0x2.BEAM_SHEETS) do
		for _0x34f = 0, 1 do
			local _0x350 = _0x33b(_0x2ec({ Material = Enum.Material.Neon, Color = ((((_0x34f == 0)) and _0x2.FX_WHITE) or _0x2.FX_HALO), Transparency = 1, Size = Vector3.new(0.12, 1, _0x34e.width), Position = _0x338 }, 60))
			table.insert(_0x33a.sheets, { part = _0x350, def = _0x34e, offset = ((_0x34f * math.pi) / 2) })
		end
	end
	local _0x351 = _0x33b(_0x2ec({ Shape = Enum.PartType.Ball, Material = Enum.Material.Neon, Color = _0x2.FX_WHITE, Transparency = 1, Size = Vector3.one, Position = _0x338 }, 60))
	local _0x352 = _0x33b(_0x2f6((_0x338 + Vector3.new(0, 0.12, 0)), 10, 0.3, _0x2.FX_WHITE, 0.25, 60))
	local _0x353 = _0x33b(_0x2f6((_0x338 + Vector3.new(0, 0.1, 0)), 28, 0.2, _0x2.FX_HALO, 0.82, 60))
	local _0x354 = _0x33b(_0x2ec({ Transparency = 1, Size = Vector3.one, Position = (_0x338 + Vector3.new(0, 6, 0)) }, 60))
	local _0x355 = Instance.new(_0xS_D("\253\194\196\195\217\225\196\202\197\217"))
	_0x355.Color = _0x2.FX_WHITE
	_0x355.Range = 46
	_0x355.Brightness = 0
	_0x355.Parent = _0x354
	local _0x356 = _0x33b(_0x2ec({ Transparency = 1, Size = Vector3.new(6, 0.5, 6), Position = (_0x338 + Vector3.new(0, 0.5, 0)) }, 60))
	local _0x357 = Instance.new(_0xS_D("\253\204\223\217\196\206\193\200\232\192\196\217\217\200\223"))
	_0x357.Texture = _0x2.BEAM_TEX_SPARK
	_0x357.Color = ColorSequence.new(_0x2.FX_WHITE, _0x2.FX_HALO)
	_0x357.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.8), NumberSequenceKeypoint.new(1, 0.3) })
	_0x357.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(0.7, 0.4), NumberSequenceKeypoint.new(1, 1) })
	_0x357.Lifetime = NumberRange.new(0.6, 1.1)
	_0x357.Speed = NumberRange.new(110, 200)
	_0x357.SpreadAngle = Vector2.new(2, 2)
	_0x357.EmissionDirection = Enum.NormalId.Top
	_0x357.LightEmission = 1
	_0x357.Rate = 0
	pcall(function()
	_0x357.Orientation = Enum.ParticleOrientation.VelocityParallel
	_0x357.Shape = Enum.ParticleEmitterShape.Cylinder
	_0x357.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
end)
	_0x357.Parent = _0x356
	table.insert(_0x33a.emitters, _0x357)
	local _0x358 = Instance.new(_0xS_D("\253\204\223\217\196\206\193\200\232\192\196\217\217\200\223"))
	_0x358.Texture = _0x2.BEAM_TEX_SPARK
	_0x358.Color = ColorSequence.new(_0x2.FX_WHITE, _0x2.FX_HALO)
	_0x358.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.7), NumberSequenceKeypoint.new(1, 0) })
	_0x358.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
	_0x358.Lifetime = NumberRange.new(1.1, 2)
	_0x358.Speed = NumberRange.new(18, 42)
	_0x358.SpreadAngle = Vector2.new(24, 24)
	_0x358.EmissionDirection = Enum.NormalId.Top
	_0x358.Acceleration = Vector3.new(0, 14, 0)
	_0x358.LightEmission = 1
	_0x358.Rate = 0
	_0x358.Parent = _0x356
	table.insert(_0x33a.emitters, _0x358)
	local _0x359 = Instance.new(_0xS_D("\253\204\223\217\196\206\193\200\232\192\196\217\217\200\223"))
	_0x359.Texture = _0x2.BEAM_TEX_SMOKE
	_0x359.Color = ColorSequence.new(_0x2.FX_LIGHT, _0x2.FX_GRAY)
	_0x359.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 5), NumberSequenceKeypoint.new(1, 18) })
	_0x359.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(1, 1) })
	_0x359.Lifetime = NumberRange.new(0.9, 1.6)
	_0x359.Speed = NumberRange.new(14, 32)
	_0x359.SpreadAngle = Vector2.new(88, 88)
	_0x359.EmissionDirection = Enum.NormalId.Top
	_0x359.Rotation = NumberRange.new(0, 360)
	_0x359.RotSpeed = NumberRange.new((-70), 70)
	_0x359.Drag = 3
	_0x359.LightEmission = 0.35
	_0x359.Rate = 0
	_0x359.Parent = _0x356
	table.insert(_0x33a.emitters, _0x359)
	local _0x35a = Instance.new(_0xS_D("\253\204\223\217\196\206\193\200\232\192\196\217\217\200\223"))
	_0x35a.Texture = _0x2.BEAM_TEX_SMOKE
	_0x35a.Color = ColorSequence.new(_0x2.FX_WHITE, _0x2.FX_HALO)
	_0x35a.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 10), NumberSequenceKeypoint.new(1, 26) })
	_0x35a.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.45), NumberSequenceKeypoint.new(1, 1) })
	_0x35a.Lifetime = NumberRange.new(0.35, 0.55)
	_0x35a.Speed = NumberRange.new(0, 0)
	_0x35a.LightEmission = 1
	_0x35a.Rate = 0
	_0x35a.Parent = _0x356
	table.insert(_0x33a.emitters, _0x35a)
	function _0x33a.ignite(_0x35b)
		local _0x35c = _0x2ec({ Shape = Enum.PartType.Ball, Material = Enum.Material.Neon, Color = _0x2.FX_WHITE, Transparency = 0.1, Size = Vector3.new(6, 6, 6), Position = (_0x35b + Vector3.new(0, 2, 0)) }, 1)
		_0x5:Create(_0x35c, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = Vector3.new(32, 32, 32), Transparency = 1 }):Play()
		if (_0x33a.ground > 0.5) then
			for _0x35d = 0, 1 do
				local _0x35e = _0x2f6((_0x35b + Vector3.new(0, 0.2, 0)), 4, 0.3, ((((_0x35d == 0)) and _0x2.FX_WHITE) or _0x2.FX_HALO), 0.15, 1.2, true)
				local _0x35f = (48 + (_0x35d * 18))
				_0x5:Create(_0x35e, TweenInfo.new((0.5 + (_0x35d * 0.15)), Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = Vector3.new(0.15, _0x35f, _0x35f), Transparency = 1 }):Play()
			end
			_0x359:Emit(28)
		end
		_0x357:Emit(24)
		_0x35a:Emit(3)
	end
	function _0x33a.step(_0x360, _0x361, _0x362, _0x363, _0x364)
		if (not _0x33a.alive) then
			return
		end
		_0x364 = math.clamp(_0x364, 0, 1)
		local _0x365 = math.clamp((_0x33a.ground or 1), 0, 1)
		local _0x366 = math.clamp((_0x33a.descent or 1), 0, 1)
		if ((((not _0x33a.ignited) and (not _0x33a.holdIgnite)) and (_0x362 > 0.04)) and (_0x364 > 0.3)) then
			_0x33a.ignited = true
			pcall(_0x33a.ignite, _0x361)
		end
		local _0x367 = math.max((_0x33a.height * _0x362), 0.1)
		_0x33d.Position = _0x361
		_0x33e.Position = Vector3.new(0, (((_0x33a.descentGap or 0)) * ((1 - _0x366))), 0)
		for _0x368, _0x369 in ipairs(_0x33a.layers) do
			local _0x36a = _0x369.def
			local _0x36b = _0x160((((_0x362 - _0x36a.delay)) / math.max((1 - _0x36a.delay), 0.05)))
			_0x369.top.Position = Vector3.new(0, math.max((_0x367 * _0x36b), 0.1), 0)
			local _0x36c = ((1 + (0.16 * math.sin(((_0x360 * _0x36a.freq) + (_0x369.index * 1.7))))) + (0.07 * math.sin((((_0x360 * _0x36a.freq) * 2.3) + (_0x369.index * 0.9)))))
			if (_0x36a.name == _0xS_D("\206\194\223\200")) then
				_0x36c = (_0x36c + ((0.1 * math.sin((_0x360 * 31)))))
			end
			local _0x36d = (((_0x36a.width * _0x363) * _0x36c) * ((0.35 + (0.65 * _0x36b))))
			_0x369.beam.Width0 = _0x36d
			_0x369.beam.Width1 = (_0x36d * _0x36a.taper)
			_0x369.beam.Transparency = _0x32a(_0x36a, _0x360, _0x364, _0x369.index)
			local _0x36e = (((math.sin((((_0x360 * _0x36a.freq) * 0.5) + _0x369.index)) * 1.6) * _0x363) * ((_0x36a.sway or 0)))
			_0x369.beam.CurveSize0 = _0x36e
			_0x369.beam.CurveSize1 = (-_0x36e)
		end
		local _0x36f = _0x160(_0x362)
		local _0x370 = _0x160((((_0x362 - 0.1)) / 0.9))
		local _0x371 = (3 + (6 * math.min(_0x363, 1.6)))
		for _0x372, _0x373 in ipairs(_0x33a.strands) do
			local _0x374 = (_0x373.phase + ((_0x360 * 2.6) * _0x373.dir))
			_0x373.a0.Position = Vector3.new((math.cos(_0x374) * _0x371), 0.3, (math.sin(_0x374) * _0x371))
			local _0x375 = (_0x374 + (1.9 * _0x373.dir))
			local _0x376 = (_0x371 * 0.3)
			_0x373.a1.Position = Vector3.new((math.cos(_0x375) * _0x376), math.max(((_0x367 * _0x370) * 0.9), 0.3), (math.sin(_0x375) * _0x376))
			local _0x377 = (0.55 * math.max(_0x363, 0.2))
			_0x373.beam.Width0 = _0x377
			_0x373.beam.Width1 = (_0x377 * 0.3)
			_0x373.beam.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, (1 - ((0.85 * _0x364) * _0x366))), NumberSequenceKeypoint.new(0.4, (1 - ((0.5 * _0x364) * _0x366))), NumberSequenceKeypoint.new(1, 1) })
		end
		local _0x378 = math.max(((_0x367 * 0.75) * _0x36f), 0.2)
		for _0x379, _0x37a in ipairs(_0x33a.sheets) do
			local _0x37b = (_0x37a.offset + (_0x360 * _0x37a.def.speed))
			_0x37a.part.Size = Vector3.new(0.12, _0x378, math.max((_0x37a.def.width * _0x363), 0.05))
			_0x37a.part.CFrame = (CFrame.new((_0x361 + Vector3.new(0, (_0x378 / 2), 0))) * CFrame.Angles(0, _0x37b, 0))
			_0x37a.part.Transparency = (1 - ((((1 - _0x37a.def.transparency)) * _0x364) * _0x366))
		end
		local _0x37c = math.max((_0x363 * ((11 + (3 * math.sin((_0x360 * 17)))))), 0.1)
		_0x351.Size = Vector3.new(_0x37c, _0x37c, _0x37c)
		_0x351.Position = (_0x361 + Vector3.new(0, (_0x367 * _0x36f), 0))
		_0x351.Transparency = ((((_0x362 < 0.04)) and 1) or ((1 - (0.65 * _0x364))))
		local _0x37d = (1 + (0.18 * math.sin((_0x360 * 22))))
		local _0x37e = math.max(((10 * _0x363) * _0x37d), 0.1)
		_0x352.Size = Vector3.new(0.3, _0x37e, _0x37e)
		_0x352.CFrame = (CFrame.new((_0x361 + Vector3.new(0, 0.12, 0))) * CFrame.Angles(0, 0, math.rad(90)))
		local _0x37f = math.max((28 * _0x363), 0.1)
		_0x353.Size = Vector3.new(0.2, _0x37f, _0x37f)
		_0x353.CFrame = (CFrame.new((_0x361 + Vector3.new(0, 0.1, 0))) * CFrame.Angles(0, 0, math.rad(90)))
		_0x352.Transparency = (0.25 + (0.75 * ((1 - _0x365))))
		_0x353.Transparency = (0.82 + (0.18 * ((1 - _0x365))))
		_0x354.Position = (_0x361 + Vector3.new(0, 6, 0))
		_0x355.Brightness = ((((12 * _0x364) * _0x366) * math.min(_0x363, 1.5)) * ((0.85 + (0.15 * math.sin((_0x360 * 31))))))
		local _0x380 = (2 + (5 * math.min(_0x363, 2)))
		_0x356.Size = Vector3.new(_0x380, 0.5, _0x380)
		_0x356.Position = (_0x361 + Vector3.new(0, 0.5, 0))
		_0x357.Rate = ((((_0x362 > 0.15)) and (((130 * _0x364) * _0x366))) or 0)
		_0x358.Rate = ((50 * _0x364) * _0x366)
		_0x359.Rate = (((26 * _0x364) * math.min(_0x363, 1.5)) * _0x365)
		_0x35a.Rate = ((12 * _0x364) * _0x366)
	end
	function _0x33a.pulse(_0x381, _0x382)
		if (((_0x33a.ground or 1)) < 0.5) then
			return
		end
		local _0x383 = (_0x33a.height * ((0.55 + (0.4 * math.random()))))
		for _0x384 = 0, 1 do
			local _0x385 = _0x2f6((_0x381 + Vector3.new(0, 0.4, 0)), math.max((((9 + (_0x384 * 5))) * _0x382), 1), (0.3 + (_0x384 * 0.2)), ((((_0x384 == 0)) and _0x2.FX_WHITE) or _0x2.FX_HALO), (0.15 + (_0x384 * 0.3)), 1.6, true)
			local _0x386 = math.max((((4 + (_0x384 * 2.5))) * _0x382), 0.5)
			_0x5:Create(_0x385, TweenInfo.new(((0.5 + (math.random() * 0.3)) + (_0x384 * 0.12)), Enum.EasingStyle.Quad, Enum.EasingDirection.In), { CFrame = (CFrame.new((_0x381 + Vector3.new(0, _0x383, 0))) * CFrame.Angles(0, 0, math.rad(90))), Size = Vector3.new(0.2, _0x386, _0x386), Transparency = 1 }):Play()
		end
	end
	function _0x33a.destroy()
		if _0x33a.destroyed then
			return
		end
		_0x33a.destroyed = true
		_0x33a.alive = false
		for _0x387, _0x388 in ipairs(_0x33a.emitters) do
			_0x388.Enabled = false
		end
		for _0x389, _0x38a in ipairs(_0x33a.layers) do
			_0x38a.beam.Enabled = false
		end
		for _0x38b, _0x38c in ipairs(_0x33a.strands) do
			_0x38c.beam.Enabled = false
		end
		task.delay(1, function()
	for _0x38d, _0x38e in ipairs(_0x33a.parts) do
		pcall(function()
	_0x38e:Destroy()
end)
	end
end)
	end
	function _0x33a.play(_0x38f, _0x390, _0x391)
		local _0x392 = os.clock()
		local _0x393
		_0x393 = _0x7.Heartbeat:Connect(function()
	local _0x394 = (os.clock() - _0x392)
	if ((_0x394 >= _0x390) or (not _0x33a.alive)) then
		_0x393:Disconnect()
		_0x33a.destroy()
		return
	end
	local _0x395, _0x396, _0x397 = _0x391(_0x394)
	_0x33a.step(_0x394, _0x38f, _0x395, _0x396, _0x397)
end)
	end
	return _0x33a
end
function _0x2f3.params(_0x398)
	local _0x399 = RaycastParams.new()
	_0x399.FilterType = Enum.RaycastFilterType.Exclude
	local _0x39a = { _0x398 }
	if workspace.CurrentCamera then
		table.insert(_0x39a, workspace.CurrentCamera)
	end
	_0x399.FilterDescendantsInstances = _0x39a
	pcall(function()
	_0x399.RespectCanCollide = true
end)
	return _0x399
end
function _0x2f3.lowestY(_0x39b, _0x39c)
	local _0x39d = math.huge
	for _0x39e, _0x39f in ipairs(_0x39b:GetChildren()) do
		if (_0x39f:IsA(_0xS_D("\239\204\222\200\253\204\223\217")) and (_0x39f ~= _0x39c)) then
			local _0x3a0 = (_0x39f.Position.Y - _0xfb(_0x39f.CFrame, _0x39f.Size))
			if (_0x3a0 < _0x39d) then
				_0x39d = _0x3a0
			end
		end
	end
	if (_0x39d == math.huge) then
		return (_0x39c.Position.Y - 3)
	end
	return _0x39d
end
function _0x2f3.sense(_0x3a1, _0x3a2, _0x3a3, _0x3a4)
	local _0x3a5 = _0x2f3.lowestY(_0x3a1, _0x3a2)
	local _0x3a6 = _0x3a2.Position
	local _0x3a7 = { feetY = _0x3a5, mode = _0xS_D("\202\223\194\216\195\201"), touching = true, groundY = _0x3a5, gap = 0 }
	local _0x3a8 = Vector3.new(_0x3a6.X, (_0x3a5 + 1.5), _0x3a6.Z)
	local _0x3a9 = workspace:Raycast(_0x3a8, Vector3.new(0, (-_0x2f3.ENV_RAY), 0), _0x3a4)
	if (not _0x3a9) then
		if (_0x3a3.FloorMaterial ~= Enum.Material.Air) then
			return _0x3a7
		end
		_0x3a7.mode = _0xS_D("\219\194\196\201")
		_0x3a7.touching = false
		_0x3a7.groundY = (_0x3a5 - _0x2f3.VOID_DEPTH)
		_0x3a7.gap = _0x2f3.VOID_DEPTH
		return _0x3a7
	end
	_0x3a7.groundY = (_0x3a9.Position.Y + 0.08)
	_0x3a7.gap = math.max((_0x3a5 - _0x3a9.Position.Y), 0)
	local _0x3aa = false
	pcall(function()
	_0x3aa = (_0x3a3:GetState() == Enum.HumanoidStateType.Swimming)
end)
	if (_0x3aa or (_0x3a9.Material == Enum.Material.Water)) then
		_0x3a7.mode = _0xS_D("\218\204\217\200\223")
		_0x3a7.touching = false
	elseif (_0x3a7.gap <= _0x2f3.TOUCH_GAP) then
		_0x3a7.mode = _0xS_D("\202\223\194\216\195\201")
		_0x3a7.touching = true
	else
		_0x3a7.mode = _0xS_D("\204\196\223")
		_0x3a7.touching = false
	end
	return _0x3a7
end
local function _0x3ab(_0x3ac)
	local _0x3ad = _0x2ec({ Transparency = 1, Size = Vector3.new(0.2, 0.2, 0.2) }, 60)
	local _0x3ae = Instance.new(_0xS_D("\236\217\217\204\206\197\192\200\195\217"))
	_0x3ae.Position = Vector3.new(0, (_0x2.STREAK_WIDTH / 2), 0)
	_0x3ae.Parent = _0x3ad
	local _0x3af = Instance.new(_0xS_D("\236\217\217\204\206\197\192\200\195\217"))
	_0x3af.Position = Vector3.new(0, ((-_0x2.STREAK_WIDTH) / 2), 0)
	_0x3af.Parent = _0x3ad
	local _0x3b0 = Instance.new(_0xS_D("\249\223\204\196\193"))
	_0x3b0.Attachment0 = _0x3ae
	_0x3b0.Attachment1 = _0x3af
	_0x3b0.Lifetime = _0x2.STREAK_TRAIL
	_0x3b0.MinLength = 0.02
	_0x3b0.FaceCamera = true
	_0x3b0.LightEmission = 1
	_0x3b0.LightInfluence = 0
	_0x3b0.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)), ColorSequenceKeypoint.new(0.4, _0x3ac), ColorSequenceKeypoint.new(1, _0x3ac) })
	_0x3b0.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.6, 0.4), NumberSequenceKeypoint.new(1, 1) })
	_0x3b0.WidthScale = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) })
	_0x3b0.Enabled = false
	_0x3b0.Parent = _0x3ad
	return _0x3ad, _0x3b0
end
local function _0x3b1(_0x3b2, _0x3b3, _0x3b4, _0x3b5, _0x3b6)
	local _0x3b7 = ((_0x3b5 * _0x3b5) * ((3 - (2 * _0x3b5))))
	local _0x3b8 = (_0x3b3 + ((((_0x3b4 * _0x3b7) * _0x2.VORTEX_TURNS) * 2) * math.pi))
	local _0x3b9 = (((_0x2.VORTEX_R0 + (((_0x2.VORTEX_R1 - _0x2.VORTEX_R0)) * ((_0x3b5 ^ 1.6))))) * _0x3b6)
	local _0x3ba = ((_0x2.VORTEX_HEIGHT * ((_0x3b5 ^ 0.85))) * _0x3b6)
	return (_0x3b2 + Vector3.new((math.cos(_0x3b8) * _0x3b9), _0x3ba, (math.sin(_0x3b8) * _0x3b9)))
end
local function _0x3bb(_0x3bc, _0x3bd, _0x3be)
	if _0x2f4 then
		pcall(_0x2f4.stop)
	end
	local _0x3bf = _0x2f3.params(_0x3bc)
	local _0x3c0 = { alive = true, parts = {}, mode = _0xS_D("\202\223\194\216\195\201") }
	local function _0x3c1(_0x3c2)
		table.insert(_0x3c0.parts, _0x3c2)
		return _0x3c2
	end
	local _0x3c3 = _0x2f3.sense(_0x3bc, _0x3bd, _0x3be, _0x3bf)
	local _0x3c4 = _0x3c3.touching
	local _0x3c5 = ((_0x3c4 and 1) or 0)
	local _0x3c6 = ((_0x3c4 and 1) or 0)
	local _0x3c7 = _0x3c3.groundY
	local _0x3c8 = ((_0x3c4 and 1) or 0)
	local function _0x3c9(_0x3ca)
		_0x3c3 = _0x2f3.sense(_0x3bc, _0x3bd, _0x3be, _0x3bf)
		if _0x3c3.touching then
			_0x3c5 = (_0x3c5 + _0x3ca)
			if (_0x3c5 >= 0.06) then
				_0x3c4 = true
			end
		else
			_0x3c5 = 0
			_0x3c4 = false
		end
		_0x3c6 = (_0x3c6 + (((((((_0x3c4 and 1) or 0)) - _0x3c6)) * ((1 - math.exp(((-_0x3ca) * (((_0x3c4 and 9) or 40)))))))))
		_0x3c7 = (_0x3c7 + ((((_0x3c3.groundY - _0x3c7)) * ((1 - math.exp(((-_0x3ca) * 18)))))))
		local _0x3cb = _0x3bd.Position
		_0x3c0.mode = ((_0x3c4 and _0xS_D("\202\223\194\216\195\201")) or ((((_0x3c3.mode == _0xS_D("\202\223\194\216\195\201")) and _0xS_D("\204\196\223")) or _0x3c3.mode)))
		return Vector3.new(_0x3cb.X, _0x3c3.feetY, _0x3cb.Z), Vector3.new(_0x3cb.X, _0x3c7, _0x3cb.Z), math.max((_0x3c3.feetY - _0x3c7), 0)
	end
	local _0x3cc, _0x3cd, _0x3ce = _0x3c9(0)
	local _0x3cf = _0x3c1(_0x2ec({ Transparency = 1, Size = Vector3.new(22, 22, 22), Position = (_0x3cc + Vector3.new(0, 3, 0)) }, 60))
	local _0x3d0 = Instance.new(_0xS_D("\253\204\223\217\196\206\193\200\232\192\196\217\217\200\223"))
	_0x3d0.Texture = _0xS_D("\223\207\213\204\222\222\200\217\151\130\130\217\200\213\217\216\223\200\222\130\221\204\223\217\196\206\193\200\222\130\222\221\204\223\198\193\200\222\242\192\204\196\195\131\201\201\222")
	_0x3d0.Color = ColorSequence.new(_0x2.FX_WHITE, _0x2.FX_LIGHT)
	_0x3d0.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.9), NumberSequenceKeypoint.new(1, 0) })
	_0x3d0.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
	_0x3d0.Lifetime = NumberRange.new(0.5, 0.8)
	_0x3d0.Speed = NumberRange.new(16, 26)
	_0x3d0.Rate = 70
	_0x3d0.LightEmission = 1
	_0x3d0.Drag = 0
	pcall(function()
	_0x3d0.Shape = Enum.ParticleEmitterShape.Sphere
	_0x3d0.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
	_0x3d0.ShapeInOut = Enum.ParticleEmitterShapeInOut.Inward
end)
	_0x3d0.Parent = _0x3cf
	local _0x3d1 = Instance.new(_0xS_D("\253\194\196\195\217\225\196\202\197\217"))
	_0x3d1.Color = _0x2.FX_WHITE
	_0x3d1.Range = 26
	_0x3d1.Brightness = 0
	_0x3d1.Parent = _0x3cf
	local _0x3d2 = _0x337(_0x3cd, (_0x3ce + _0x2f3.PILLAR_ABOVE))
	_0x3d2.ground = _0x3c6
	_0x3d2.descentGap = _0x3ce
	_0x3d2.descent = _0x3c8
	_0x3d2.holdIgnite = ((_0x3c0.mode == _0xS_D("\204\196\223")) or (_0x3c0.mode == _0xS_D("\218\204\217\200\223")))
	if (_0x3c0.mode == _0xS_D("\219\194\196\201")) then
		_0x3d2.ignited = true
	end
	local _0x3d3 = {}
	for _0x3d4 = 0, (_0x2.STREAK_COUNT - 1) do
		local _0x3d5 = (_0x3d4 % 3)
		local _0x3d6 = ((((_0x3d5 == 0)) and _0x2.FX_GRAY) or (((((_0x3d5 == 1)) and _0x2.FX_WHITE) or _0x2.FX_LIGHT)))
		local _0x3d7, _0x3d8 = _0x3ab(_0x3d6)
		_0x3c1(_0x3d7)
		table.insert(_0x3d3, { part = _0x3d7, trail = _0x3d8, direction = (((((_0x3d4 % 4) == 3)) and (-1)) or 1), baseAngle = ((((_0x3d4 / _0x2.STREAK_COUNT)) * 2) * math.pi), birth = (((_0x3d4 / _0x2.STREAK_COUNT)) * _0x2.STREAK_LIFE), cycle = (-1), jitter = 0, fresh = false })
	end
	local _0x3d9 = os.clock()
	local _0x3da, _0x3db, _0x3dc, _0x3dd = 0, 0, 0, 0
	local _0x3de = (_0x3c6 > 0.55)
	_0x3c0.conn = _0x7.Heartbeat:Connect(function(_0x3df)
	if ((not _0x3c0.alive) or (not _0x3bd.Parent)) then
		return
	end
	local _0x3e0 = (os.clock() - _0x3d9)
	_0x3cc, _0x3cd, _0x3ce = _0x3c9(_0x3df)
	local _0x3e1 = (_0x3c6 > 0.55)
	if (_0x3de and (not _0x3e1)) then
		_0x2f3.killPlates()
	end
	_0x3de = _0x3e1
	if _0x3c4 then
		_0x3c8 = 1
	elseif (_0x3e0 > 0.1) then
		_0x3c8 = math.min((_0x3c8 + (_0x3df / 0.5)), 1)
	end
	_0x3d2.ground = _0x3c6
	_0x3d2.height = (_0x3ce + _0x2f3.PILLAR_ABOVE)
	_0x3d2.descentGap = _0x3ce
	_0x3d2.descent = (1 - (((1 - _0x3c8)) ^ 3))
	if (_0x3d2.holdIgnite and ((_0x3c4 or (_0x3c8 >= 0.96)))) then
		_0x3d2.holdIgnite = false
	end
	if (_0x3c0.mode == _0xS_D("\219\194\196\201")) then
		_0x3d2.ignited = true
	end
	local _0x3e2 = _0x160((_0x3e0 / 0.7))
	_0x3cf.Position = (_0x3cc + Vector3.new(0, 3, 0))
	_0x3d1.Brightness = (2 + ((6 * _0x3e2) * ((0.7 + (0.3 * math.sin((_0x3e0 * 30)))))))
	local _0x3e3 = (0.2 + (0.8 * _0x3e2))
	_0x3d2.step(_0x3e0, _0x3cd, (1 - (((1 - math.min((_0x3e0 / 0.5), 1))) ^ 3)), _0x3e3, 1)
	if (_0x3e1 and (_0x3e0 >= _0x3dd)) then
		_0x3dd = ((_0x3e0 + 0.16) + (math.random() * 0.1))
		_0x3d2.pulse(_0x3cd, _0x3e3)
	end
	for _0x3e4, _0x3e5 in ipairs(_0x3d3) do
		local _0x3e6 = (_0x3e0 - _0x3e5.birth)
		if (_0x3e6 >= 0) then
			local _0x3e7 = math.floor((_0x3e6 / _0x2.STREAK_LIFE))
			local _0x3e8 = ((_0x3e6 / _0x2.STREAK_LIFE) - _0x3e7)
			if (_0x3e7 ~= _0x3e5.cycle) then
				_0x3e5.cycle = _0x3e7
				_0x3e5.trail.Enabled = false
				_0x3e5.fresh = true
				_0x3e5.jitter = (math.random() * 0.6)
			elseif _0x3e5.fresh then
				_0x3e5.fresh = false
				_0x3e5.trail.Enabled = true
			end
			_0x3e5.part.CFrame = CFrame.new(_0x3b1(_0x3cc, (_0x3e5.baseAngle + _0x3e5.jitter), _0x3e5.direction, _0x3e8, (0.45 + (0.55 * _0x3e2))))
		end
	end
	if ((_0x3e0 >= _0x3da) and _0x3e1) then
		_0x3da = (_0x3e0 + 0.3)
		local _0x3e9
		if (_0x3e0 < 0.6) then
			_0x3e9 = _0x2f6((_0x3cd + Vector3.new(0, 0.1, 0)), 28, 0.15, _0x2.FX_LIGHT, 0.7, 1, true)
			_0x5:Create(_0x3e9, TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Size = Vector3.new(0.15, 4, 4), Transparency = 0.1 }):Play()
		else
			_0x3e9 = _0x2f6((_0x3cd + Vector3.new(0, 0.1, 0)), 6, 0.15, ((((math.random() < 0.5)) and _0x2.FX_WHITE) or _0x2.FX_LIGHT), 0.35, 1, true)
			_0x5:Create(_0x3e9, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = Vector3.new(0.15, 26, 26), Transparency = 1 }):Play()
		end
	end
	if ((_0x3e2 > 0.3) and (_0x3e0 >= _0x3db)) then
		_0x3db = (_0x3e0 + 0.09)
		for _0x3ea = 1, 2 do
			local _0x3eb = ((_0x3cc + Vector3.new(0, (0.5 + (math.random() * 2)), 0)) + _0x2ff(1.5))
			local _0x3ec = ((_0x3cc + Vector3.new(0, (4 + (math.random() * 14)), 0)) + _0x2ff((4 + (math.random() * 5))))
			_0x302(_0x3eb, _0x3ec, ((((math.random() < 0.6)) and _0x2.FX_WHITE) or _0x2.FX_LIGHT), 0.16)
		end
	end
	if (((_0x3e2 > 0.15) and (_0x3e0 >= _0x3dc)) and _0x3e1) then
		_0x3dc = (_0x3e0 + 0.1)
		_0x30f(_0x3cd, (3 + (math.random() * 7)), (6 + (math.random() * 12)), 1.4)
	end
end)
	function _0x3c0.stop()
		if (not _0x3c0.alive) then
			return
		end
		_0x3c0.alive = false
		if (_0x2f4 == _0x3c0) then
			_0x2f4 = nil
		end
		if _0x3c0.conn then
			_0x3c0.conn:Disconnect()
		end
		_0x3d0.Enabled = false
		for _0x3ed, _0x3ee in ipairs(_0x3d3) do
			_0x3ee.trail.Enabled = false
		end
		pcall(function()
	_0x3d2.play(_0x3cd, 0.45, function(_0x3ef)
	local _0x3f0 = (_0x3ef / 0.45)
	return 1, (((1 - _0x3f0)) ^ 2), (1 - _0x3f0)
end)
	_0x5:Create(_0x3d1, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Brightness = 0 }):Play()
end)
		task.delay(1.2, function()
	for _0x3f1, _0x3f2 in ipairs(_0x3c0.parts) do
		pcall(function()
	_0x3f2:Destroy()
end)
	end
end)
	end
	_0x2f4 = _0x3c0
	return _0x3c0
end
local function _0x3f3(_0x3f4, _0x3f5)
	local _0x3f6 = _0x3f4:FindFirstChild(_0xS_D("\229\216\192\204\195\194\196\201\255\194\194\217\253\204\223\217"))
	if (not _0x3f6) then
		return
	end
	_0x63()
	_0x5f(_0x2.SFX_FINISH, _0x2.SFX_FINISH_VOLUME)
	local _0x3f7 = _0x3f6.Position
	local _0x3f8 = _0x2f3.sense(_0x3f4, _0x3f6, _0x3f5, _0x2f3.params(_0x3f4))
	local _0x3f9 = _0x3f8.touching
	local _0x3fa = Vector3.new(_0x3f7.X, _0x3f8.groundY, _0x3f7.Z)
	if _0x19 then
		_0x19.boost = 1
	end
	_0x321(0.55, 0.75)
	_0x318(_0x3f5, 0.6, 0.9)
	local _0x3fb = _0x2ec({ Shape = Enum.PartType.Ball, Material = Enum.Material.Neon, Color = _0x2.FX_WHITE, Transparency = 0, Size = Vector3.new(5, 5, 5), Position = _0x3f7 }, 1.5)
	_0x5:Create(_0x3fb, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = Vector3.new(36, 36, 36), Transparency = 1 }):Play()
	local _0x3fc = _0x337(_0x3fa, (math.max((_0x3f8.feetY - _0x3f8.groundY), 0) + _0x2f3.PILLAR_ABOVE))
	_0x3fc.ground = ((_0x3f9 and 1) or 0)
	if (_0x3f8.mode == _0xS_D("\219\194\196\201")) then
		_0x3fc.ignited = true
	end
	_0x3fc.play(_0x3fa, 1.1, function(_0x3fd)
	local _0x3fe = (_0x3fd / 1.1)
	local _0x3ff = math.min((_0x3fd / 0.07), 1)
	return (1 - (((1 - math.min((_0x3fd / 0.14), 1))) ^ 3)), ((2.6 * _0x3ff) * (((1 - _0x3fe)) ^ 2.2)), (1 - _0x3fe)
end)
	for _0x400 = 0, 3 do
		task.delay((_0x400 * 0.08), function()
	_0x3fc.pulse(_0x3fa, 1.8)
end)
	end
	for _0x401 = 0, ((_0x3f9 and 2) or (-1)) do
		task.delay((_0x401 * 0.09), function()
	local _0x402 = (70 + (_0x401 * 12))
	local _0x403 = _0x2f6(_0x3fa, 4, 0.35, (((((_0x401 % 2) == 0)) and _0x2.FX_WHITE) or _0x2.FX_LIGHT), 0.1, 1.5, true)
	_0x5:Create(_0x403, TweenInfo.new(0.75, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = Vector3.new(0.12, _0x402, _0x402), Transparency = 1 }):Play()
end)
	end
	for _0x404 = 1, 8 do
		local _0x405 = (_0x3f7 + _0x2ff(1))
		local _0x406 = ((_0x3f7 + Vector3.new(0, (((math.random() - 0.3)) * 10), 0)) + _0x2ff((8 + (math.random() * 8))))
		_0x302(_0x405, _0x406, ((((math.random() < 0.5)) and _0x2.FX_WHITE) or _0x2.FX_LIGHT), 0.2)
	end
	for _0x407 = 1, ((_0x3f9 and 18) or 0) do
		_0x30f(_0x3fa, (2 + (math.random() * 9)), (8 + (math.random() * 14)), 1.6)
	end
	local _0x408 = _0x2ec({ Transparency = 1, Size = Vector3.one, Position = (_0x3fa + Vector3.new(0, 4, 0)) })
	local _0x409 = Instance.new(_0xS_D("\253\194\196\195\217\225\196\202\197\217"))
	_0x409.Color = _0x2.FX_WHITE
	_0x409.Brightness = 8
	_0x409.Range = 34
	_0x409.Parent = _0x408
	_0x5:Create(_0x409, TweenInfo.new(1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Brightness = 0 }):Play()
	local _0x40a = Instance.new(_0xS_D("\253\204\223\217\196\206\193\200\232\192\196\217\217\200\223"))
	_0x40a.Texture = _0xS_D("\223\207\213\204\222\222\200\217\151\130\130\217\200\213\217\216\223\200\222\130\221\204\223\217\196\206\193\200\222\130\222\221\204\223\198\193\200\222\242\192\204\196\195\131\201\201\222")
	_0x40a.Color = ColorSequence.new(_0x2.FX_WHITE, _0x2.FX_LIGHT)
	_0x40a.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0) })
	_0x40a.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
	_0x40a.Lifetime = NumberRange.new(0.7, 1.2)
	_0x40a.Speed = NumberRange.new(10, 24)
	_0x40a.SpreadAngle = Vector2.new(180, 180)
	_0x40a.Drag = 2
	_0x40a.Rate = 0
	_0x40a.LightEmission = 1
	_0x40a.Parent = _0x408
	_0x40a:Emit(40)
	task.delay(0.05, function()
	if (not _0x3f4.Parent) then
		return
	end
	local _0x40b = Instance.new(_0xS_D("\229\196\202\197\193\196\202\197\217"))
	_0x40b.Name = _0xS_D("\236\235\226\242\236\216\223\204\235\193\204\222\197")
	_0x40b.Adornee = _0x3f4
	_0x40b.FillColor = _0x2.AURA_COLOR
	_0x40b.FillTransparency = 0.55
	_0x40b.OutlineColor = _0x2.AURA_COLOR
	_0x40b.OutlineTransparency = 0
	_0x40b.DepthMode = Enum.HighlightDepthMode.Occluded
	_0x40b.Parent = workspace
	_0x5:Create(_0x40b, TweenInfo.new(1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { FillTransparency = 1, OutlineTransparency = 1 }):Play()
	_0x9:AddItem(_0x40b, 1.4)
end)
	local _0x40c = workspace.CurrentCamera
	if (_0x40c and (not _0x98)) then
		local _0x40d = _0x40c.FieldOfView
		_0x98 = _0x40d
		local _0x40e = _0x5:Create(_0x40c, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { FieldOfView = (_0x40d + 10) })
		_0x40e:Play()
		_0x40e.Completed:Once(function()
	local _0x40f = _0x5:Create(_0x40c, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { FieldOfView = _0x40d })
	_0x40f:Play()
	_0x40f.Completed:Once(function()
	_0x40c.FieldOfView = _0x40d
	_0x98 = nil
end)
end)
		task.delay(1.9, function()
	if (_0x98 == _0x40d) then
		pcall(function()
	_0x40c.FieldOfView = _0x40d
end)
		_0x98 = nil
	end
end)
	end
end
local function _0x410(_0x411)
	if _0x1b[_0x411] then
		return
	end
	local _0x412 = _0x411:FindFirstChild(_0xS_D("\236\195\196\192\204\217\200"))
	if (not _0x412) then
		return
	end
	local _0x413 = {}
	for _0x414, _0x415 in ipairs(_0x2.ANIM_MAP) do
		local _0x416 = _0x412:FindFirstChild(_0x415[1])
		local _0x417 = (_0x416 and _0x416:FindFirstChild(_0x415[2]))
		if (_0x417 and _0x417:IsA(_0xS_D("\236\195\196\192\204\217\196\194\195"))) then
			_0x413[(_0x415[1] .. (_0xS_D("\130") .. _0x415[2]))] = _0x417.AnimationId
		end
	end
	_0x1b[_0x411] = _0x413
end
local function _0x418(_0x419, _0x41a)
	if (_0x1c[_0x419] ~= nil) then
		return
	end
	local _0x41b, _0x41c = pcall(function()
	return _0x41a:GetAppliedDescription()
end)
	local _0x41d = _0x1a8(_0x419, _0xS_D("\229\200\204\201"))
	local _0x41e = false
	if (_0x41d and (not _0x243(_0x41d))) then
		for _0x41f, _0x420 in ipairs(_0x41d:GetChildren()) do
			if (_0x420:IsA(_0xS_D("\233\200\206\204\193")) and (_0x420.Texture ~= _0xS_D(""))) then
				_0x41e = _0x420.Texture
				break
			end
		end
	end
	_0x1d[_0x419] = _0x41e
	_0x1c[_0x419] = (((_0x41b and _0x41c)) or false)
	_0x410(_0x419)
end
local function _0x421(_0x422, _0x423)
	local _0x424 = { _0xS_D("\236\221\221\193\212\233\200\222\206\223\196\221\217\196\194\195\255\200\222\200\217\236\222\212\195\206"), _0xS_D("\236\221\221\193\212\233\200\222\206\223\196\221\217\196\194\195\255\200\222\200\217"), _0xS_D("\236\221\221\193\212\233\200\222\206\223\196\221\217\196\194\195\236\222\212\195\206"), _0xS_D("\236\221\221\193\212\233\200\222\206\223\196\221\217\196\194\195") }
	for _0x425, _0x426 in ipairs(_0x424) do
		local _0x427 = pcall(function()
	_0x422[_0x426](_0x422, _0x423)
end)
		if _0x427 then
			return true
		end
	end
	return false
end
local function _0x428(_0x429, _0x42a, _0x42b)
	_0x21f(_0x429)
	local _0x42c = {}
	for _0x42d, _0x42e in ipairs(_0x429:GetDescendants()) do
		if (_0x42e:IsA(_0xS_D("\239\204\222\200\253\204\223\217")) and (not _0x31(_0x42e))) then
			_0x42c[_0x42e.Name] = _0x42e.Transparency
		end
	end
	local _0x42f, _0x430 = false, false
	task.spawn(function()
	_0x430 = _0x421(_0x42a, _0x42b)
	_0x42f = true
end)
	local _0x431 = 0
	while ((not _0x42f) and (_0x431 < _0x2.DESCRIPTION_TIMEOUT)) do
		task.wait(0.05)
		_0x431 = (_0x431 + 0.05)
	end
	task.wait(0.15)
	if (_0x42f and _0x430) then
		pcall(function()
	local _0x432 = _0x1a8(_0x429, _0xS_D("\229\200\204\201"))
	if (((_0x432 and (_0x42b.Face ~= 0)) and (not _0x23f(_0x432))) and (not _0x243(_0x432))) then
		_0x245(_0x432, (_0xS_D("\223\207\213\204\222\222\200\217\196\201\151\130\130") .. tostring(_0x42b.Face)))
	end
end)
	end
	if _0x21a(_0x42c) then
		for _0x433, _0x434 in pairs(_0x42c) do
			local _0x435 = _0x1a8(_0x429, _0x433)
			if (_0x435 and (_0x435.Transparency ~= _0x434)) then
				_0x435.Transparency = _0x434
			end
		end
	end
	return (_0x42f and _0x430)
end
local _0x436 = setmetatable({}, { __mode = _0xS_D("\198") })
_0x2.GUARD_HOLD = 1.2
local function _0x437(_0x438)
	local _0x439 = _0x436[_0x438]
	if (not _0x439) then
		_0x439 = { count = 0, prevNeck = _0x438.RequiresNeck, prevDead = true }
		pcall(function()
	_0x439.prevDead = _0x438:GetStateEnabled(Enum.HumanoidStateType.Dead)
end)
		_0x436[_0x438] = _0x439
	end
	_0x439.count = (_0x439.count + 1)
	pcall(function()
	_0x438.RequiresNeck = false
end)
	pcall(function()
	_0x438:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
end)
	return _0x439
end
local function _0x43a(_0x43b, _0x43c, _0x43d)
	local function _0x43e()
		_0x43c.count = (_0x43c.count - 1)
		if (_0x43c.count > 0) then
			return
		end
		_0x436[_0x43b] = nil
		pcall(function()
	_0x43b.RequiresNeck = _0x43c.prevNeck
end)
		pcall(function()
	_0x43b:SetStateEnabled(Enum.HumanoidStateType.Dead, _0x43c.prevDead)
end)
	end
	if (_0x43d and (_0x43d > 0)) then
		task.delay(_0x43d, _0x43e)
	else
		_0x43e()
	end
end
local function _0x43f(_0x440, _0x441)
	local _0x442 = _0x437(_0x440)
	local _0x443, _0x444, _0x445 = pcall(_0x441)
	_0x43a(_0x440, _0x442, _0x2.GUARD_HOLD)
	if (not _0x443) then
		error(_0x444, 0)
	end
	return _0x444, _0x445
end
local function _0x446(_0x447)
	local _0x448 = {}
	for _0x449, _0x44a in ipairs(_0x447:GetDescendants()) do
		if (_0x44a:IsA(_0xS_D("\239\204\222\200\253\204\223\217")) and (not _0x31(_0x44a))) then
			_0x448[_0x44a.Name] = _0x44a.Transparency
		end
	end
	return _0x448
end
local function _0x44b(_0x44c)
	local _0x44d = setmetatable({}, { __mode = _0xS_D("\198") })
	for _0x44e, _0x44f in ipairs(_0x44c:GetDescendants()) do
		if (_0x44f:IsA(_0xS_D("\239\204\222\200\253\204\223\217")) and (not _0x31(_0x44f))) then
			_0x44d[_0x44f] = true
		end
	end
	return _0x44d
end
local function _0x450(_0x451, _0x452)
	local _0x453 = {}
	local _0x454 = {}
	for _0x455, _0x456 in ipairs(_0x451:GetDescendants()) do
		if (_0x456:IsA(_0xS_D("\224\194\217\194\223\155\233")) and _0x456.Part1) then
			_0x453[_0x456.Part1] = true
		end
	end
	local function _0x457(_0x458, _0x459)
		return (_0x453[_0x459] == true)
	end
	for _0x45a, _0x45b in ipairs(_0x451:GetDescendants()) do
		if ((_0x45b:IsA(_0xS_D("\239\204\222\200\253\204\223\217")) and _0x2.BODY_COLOR_MAP[_0x45b.Name]) and (not _0x31(_0x45b))) then
			local _0x45c = _0x454[_0x45b.Name]
			if (not _0x45c) then
				_0x45c = {}
				_0x454[_0x45b.Name] = _0x45c
			end
			table.insert(_0x45c, _0x45b)
		end
	end
	for _0x45d, _0x45e in pairs(_0x454) do
		if ((#_0x45e) > 1) then
			local _0x45f, _0x460 = {}, {}
			for _0x461, _0x462 in ipairs(_0x45e) do
				if _0x452[_0x462] then
					table.insert(_0x460, _0x462)
				else
					table.insert(_0x45f, _0x462)
				end
			end
			local _0x463
			for _0x464, _0x465 in ipairs(_0x45f) do
				if _0x457(_0x451, _0x465) then
					_0x463 = _0x465
					break
				end
			end
			if (not _0x463) then
				local _0x466
				for _0x467, _0x468 in ipairs(_0x460) do
					if _0x457(_0x451, _0x468) then
						_0x466 = _0x468
						break
					end
				end
				if (_0x466 and ((#_0x45f) > 0)) then
					_0x463 = _0x233(_0x451, _0x466, _0x45f[1])
				else
					_0x463 = ((_0x466 or _0x45f[1]) or _0x460[1])
				end
			end
			for _0x469, _0x46a in ipairs(_0x45e) do
				if ((_0x46a ~= _0x463) and _0x46a.Parent) then
					_0x46a:Destroy()
				end
			end
		end
	end
end
local function _0x46b(_0x46c, _0x46d, _0x46e)
	_0x450(_0x46c, _0x46e)
	local _0x46f = _0x21a(_0x46d)
	local function _0x470()
		if (not _0x46f) then
			return
		end
		for _0x471, _0x472 in ipairs(_0x46c:GetDescendants()) do
			if (_0x472:IsA(_0xS_D("\239\204\222\200\253\204\223\217")) and (not _0x31(_0x472))) then
				local _0x473 = _0x46d[_0x472.Name]
				if (_0x473 and (_0x472.Transparency < (_0x473 - 0.01))) then
					_0x472.Transparency = _0x473
				end
			end
		end
	end
	_0x470()
	for _0x474, _0x475 in ipairs({ 0.3, 1, 2.5 }) do
		task.delay(_0x475, function()
	if _0x46c.Parent then
		_0x470()
	end
end)
	end
end
local function _0x476(_0x477)
	local _0x478 = os.clock()
	local _0x479
	_0x479 = _0x477.Died:Connect(function()
	if _0x479 then
		_0x479:Disconnect()
	end
	if ((os.clock() - _0x478) > _0x2.DEATH_WINDOW) then
		return
	end
	_0x1f = (_0x1f + 1)
	if (_0x1f >= _0x2.MAX_DEATH_STRIKES) then
		_0x1e = false
		_0x16 = nil
		_0x17 = (_0x17 + 1)
	end
end)
	task.delay(_0x2.DEATH_WINDOW, function()
	if (_0x479 and _0x479.Connected) then
		_0x479:Disconnect()
		_0x1f = 0
	end
end)
end
_0x2.R15 = {}
_0x2.ANIM_SLOTS = { { slot = _0xS_D("\196\201\193\200"), label = _0xS_D("\220\216\196\200\217\194"), prop = _0xS_D("\228\201\193\200\236\195\196\192\204\217\196\194\195"), typeId = 51 }, { slot = _0xS_D("\218\204\193\198"), label = _0xS_D("\206\204\192\196\195\204\223"), prop = _0xS_D("\250\204\193\198\236\195\196\192\204\217\196\194\195"), typeId = 55 }, { slot = _0xS_D("\223\216\195"), label = _0xS_D("\206\194\223\223\200\223"), prop = _0xS_D("\255\216\195\236\195\196\192\204\217\196\194\195"), typeId = 53 }, { slot = _0xS_D("\199\216\192\221"), label = _0xS_D("\222\204\193\217\204\223"), prop = _0xS_D("\231\216\192\221\236\195\196\192\204\217\196\194\195"), typeId = 52 }, { slot = _0xS_D("\203\204\193\193"), label = _0xS_D("\206\204\200\223"), prop = _0xS_D("\235\204\193\193\236\195\196\192\204\217\196\194\195"), typeId = 50 }, { slot = _0xS_D("\206\193\196\192\207"), label = _0xS_D("\217\223\200\221\204\223"), prop = _0xS_D("\238\193\196\192\207\236\195\196\192\204\217\196\194\195"), typeId = 48 }, { slot = _0xS_D("\222\218\196\192"), label = _0xS_D("\195\204\201\204\223"), prop = _0xS_D("\254\218\196\192\236\195\196\192\204\217\196\194\195"), typeId = 54 } }
_0x2.SLOT_NAMES = { idle = true, walk = true, run = true, jump = true, fall = true, climb = true, swim = true }
_0x2.ROBLOX_DEFAULT_ANIMS = { idle = { 507766666, 507766951, 507766388 }, walk = { 507777826 }, run = { 507767714 }, jump = { 507765000 }, fall = { 507767968 }, climb = { 507765644 }, swim = { 507784897 } }
_0x2.R15.FIXED_ANIMS = { climb = 82587632175618, fall = 110319921537712, idle = 132984592941585, idleExtra = 124200992648318, jump = 83380602503991, run = 90449724957683, walk = 106767496454996 }
_0x2.PRIORITY_LADDER = { Enum.AnimationPriority.Core, Enum.AnimationPriority.Idle, Enum.AnimationPriority.Movement, Enum.AnimationPriority.Action, Enum.AnimationPriority.Action2, Enum.AnimationPriority.Action3, Enum.AnimationPriority.Action4 }
local function _0x47a(_0x47b)
	if (type(_0x47b) == _0xS_D("\195\216\192\207\200\223")) then
		return _0x47b
	end
	local _0x47c = tostring((_0x47b or _0xS_D("")))
	local _0x47d = string.match(_0x47c, _0xS_D("\246\146\139\240\196\201\144\133\136\201\134\132"))
	if _0x47d then
		return tonumber(_0x47d)
	end
	local _0x47e
	for _0x47f in string.gmatch(_0x47c, _0xS_D("\136\201\134")) do
		_0x47e = _0x47f
	end
	return ((_0x47e and tonumber(_0x47e)) or nil)
end
local _0x480 = {}
function _0x480.fromDescription(_0x481)
	local _0x482 = { ids = {}, names = {}, source = {} }
	for _0x483, _0x484 in ipairs(_0x2.ANIM_SLOTS) do
		local _0x485, _0x486 = pcall(function()
	return _0x481[_0x484.prop]
end)
		if ((_0x485 and (type(_0x486) == _0xS_D("\195\216\192\207\200\223"))) and (_0x486 ~= 0)) then
			_0x482.ids[_0x484.slot] = _0x486
			_0x482.source[_0x484.slot] = _0xS_D("\201\200\222\206\223\196\221\206\196\194\195")
		end
	end
	return _0x482
end
function _0x480.forceFixed(_0x487)
	_0x487.ids = (_0x487.ids or {})
	_0x487.source = (_0x487.source or {})
	for _0x488, _0x489 in ipairs({ _0xS_D("\196\201\193\200"), _0xS_D("\218\204\193\198"), _0xS_D("\223\216\195"), _0xS_D("\199\216\192\221"), _0xS_D("\203\204\193\193"), _0xS_D("\206\193\196\192\207") }) do
		_0x487.ids[_0x489] = _0x2.R15.FIXED_ANIMS[_0x489]
		_0x487.source[_0x489] = _0xS_D("\203\196\199\194")
	end
	_0x487.idleExtra = _0x2.R15.FIXED_ANIMS.idleExtra
	_0x487.fixed = true
	return _0x487
end
function _0x480.build(_0x48a, _0x48b, _0x48c, _0x48d)
	local _0x48e = _0x480.fromDescription(_0x48c)
	local _0x48f, _0x490 = pcall(function()
	return _0x3:GetCharacterAppearanceInfoAsync(_0x48a)
end)
	if ((_0x48f and (type(_0x490) == _0xS_D("\217\204\207\193\200"))) and (type(_0x490.assets) == _0xS_D("\217\204\207\193\200"))) then
		for _0x491, _0x492 in ipairs(_0x490.assets) do
			local _0x493 = ((type(_0x492) == _0xS_D("\217\204\207\193\200")) and _0x492.assetType)
			local _0x494 = (((type(_0x493) == _0xS_D("\217\204\207\193\200")) and _0x493.id) or nil)
			local _0x495 = nil
			if ((type(_0x493) == _0xS_D("\217\204\207\193\200")) and (type(_0x493.name) == _0xS_D("\222\217\223\196\195\202"))) then
				local _0x496 = string.gsub(_0x493.name, _0xS_D("\136\222"), _0xS_D(""))
				_0x495 = string.lower(_0x496)
			end
			for _0x497, _0x498 in ipairs(_0x2.ANIM_SLOTS) do
				if ((_0x494 == _0x498.typeId) or (_0x495 == string.lower(_0x498.prop))) then
					_0x48e.names[_0x498.slot] = _0x492.name
					if (((not _0x48e.ids[_0x498.slot]) and (type(_0x492.id) == _0xS_D("\195\216\192\207\200\223"))) and (_0x492.id ~= 0)) then
						_0x48e.ids[_0x498.slot] = _0x492.id
						_0x48e.source[_0x498.slot] = _0xS_D("\204\221\204\223\196\200\195\206\196\204")
					end
				end
			end
		end
	end
	if _0x48d then
		local _0x499 = _0x2.R15.readLiveAnimations(_0x48d)
		for _0x49a, _0x49b in ipairs(_0x2.ANIM_MAP) do
			local _0x49c = _0x49b[1]
			local _0x49d = _0x499[(_0x49b[1] .. (_0xS_D("\130") .. _0x49b[2]))]
			if ((_0x2.SLOT_NAMES[_0x49c] and _0x49d) and (not _0x48e.ids[_0x49c])) then
				local _0x49e = _0x47a(_0x49d)
				if (_0x49e and (_0x49e ~= 0)) then
					_0x48e.ids[_0x49c] = _0x49e
					_0x48e.source[_0x49c] = _0xS_D("\199\216\202\204\201\194\223\141\200\195\141\200\193\141\222\200\223\219\196\201\194\223")
				end
			end
		end
		local _0x49f = _0x47a(_0x499[_0xS_D("\196\201\193\200\130\236\195\196\192\204\217\196\194\195\156")])
		local _0x4a0 = _0x47a(_0x499[_0xS_D("\196\201\193\200\130\236\195\196\192\204\217\196\194\195\159")])
		if ((_0x4a0 and (_0x4a0 ~= 0)) and (_0x49f == _0x48e.ids.idle)) then
			_0x48e.idleExtra = _0x4a0
		end
	end
	if (_0x48e.ids.walk and (not _0x48e.ids.run)) then
		_0x48e.ids.run = _0x48e.ids.walk
		_0x48e.source.run = _0xS_D("\206\194\221\196\204\201\194\141\201\200\141\206\204\192\196\195\204\223")
	elseif (_0x48e.ids.run and (not _0x48e.ids.walk)) then
		_0x48e.ids.walk = _0x48e.ids.run
		_0x48e.source.walk = _0xS_D("\206\194\221\196\204\201\194\141\201\200\141\206\194\223\223\200\223")
	end
	_0x480.forceFixed(_0x48e)
	return _0x48e
end
function _0x480.probe(_0x4a1, _0x4a2, _0x4a3)
	local _0x4a4 = Instance.new(_0xS_D("\236\195\196\192\204\217\196\194\195"))
	_0x4a4.AnimationId = (_0xS_D("\223\207\213\204\222\222\200\217\196\201\151\130\130") .. tostring(_0x4a2))
	local _0x4a5, _0x4a6 = pcall(function()
	return _0x4a1:LoadAnimation(_0x4a4)
end)
	if ((not _0x4a5) or (not _0x4a6)) then
		_0x4a4:Destroy()
		return nil
	end
	while (os.clock() < _0x4a3) do
		local _0x4a7, _0x4a8 = pcall(function()
	return _0x4a6.Length
end)
		if ((_0x4a7 and _0x4a8) and (_0x4a8 > 0)) then
			break
		end
		task.wait(0.05)
	end
	local _0x4a9, _0x4aa = 0, nil
	pcall(function()
	_0x4a9 = _0x4a6.Length
	_0x4aa = _0x4a6.Looped
end)
	pcall(function()
	_0x4a6:Destroy()
end)
	_0x4a4:Destroy()
	if (_0x4a9 and (_0x4a9 > 0)) then
		return _0x4a9, _0x4aa
	end
	return nil
end
function _0x480.resolve(_0x4ab)
	local _0x4ac, _0x4ad = pcall(function()
	return game:GetObjects((_0xS_D("\223\207\213\204\222\222\200\217\196\201\151\130\130") .. tostring(_0x4ab)))
end)
	if ((not _0x4ac) or (type(_0x4ad) ~= _0xS_D("\217\204\207\193\200"))) then
		return nil
	end
	local _0x4ae
	for _0x4af, _0x4b0 in ipairs(_0x4ad) do
		if _0x4b0:IsA(_0xS_D("\236\195\196\192\204\217\196\194\195")) then
			_0x4ae = _0x4b0
		else
			_0x4ae = _0x4b0:FindFirstChildWhichIsA(_0xS_D("\236\195\196\192\204\217\196\194\195"), true)
		end
		if _0x4ae then
			break
		end
	end
	local _0x4b1 = ((_0x4ae and _0x47a(_0x4ae.AnimationId)) or nil)
	for _0x4b2, _0x4b3 in ipairs(_0x4ad) do
		pcall(function()
	_0x4b3:Destroy()
end)
	end
	return _0x4b1
end
function _0x480.fillMissing(_0x4b4)
	if (_0x4b4.ids.walk and (not _0x4b4.ids.run)) then
		_0x4b4.ids.run = _0x4b4.ids.walk
		_0x4b4.source.run = _0xS_D("\206\194\221\196\204\201\194\141\201\200\141\206\204\192\196\195\204\223")
	elseif (_0x4b4.ids.run and (not _0x4b4.ids.walk)) then
		_0x4b4.ids.walk = _0x4b4.ids.run
		_0x4b4.source.walk = _0xS_D("\206\194\221\196\204\201\194\141\201\200\141\206\194\223\223\200\223")
	end
end
function _0x480.validate(_0x4b5, _0x4b6)
	_0x4b6.lengths = {}
	if _0x4b6.fixed then
		return
	end
	local _0x4b7 = (_0x4b5:FindFirstChildOfClass(_0xS_D("\236\195\196\192\204\217\194\223")) or _0x4b5:WaitForChild(_0xS_D("\236\195\196\192\204\217\194\223"), 2))
	if (not _0x4b7) then
		return
	end
	local _0x4b8 = {}
	for _0x4b9, _0x4ba in pairs(_0x4b6.ids) do
		table.insert(_0x4b8, { slot = _0x4b9, id = _0x4ba })
	end
	if _0x4b6.idleExtra then
		table.insert(_0x4b8, { slot = _0xS_D("\196\201\193\200\159"), id = _0x4b6.idleExtra })
	end
	local _0x4bb = (#_0x4b8)
	local _0x4bc = (os.clock() + 4)
	for _0x4bd, _0x4be in ipairs(_0x4b8) do
		task.spawn(function()
	local _0x4bf, _0x4c0 = _0x480.probe(_0x4b7, _0x4be.id, _0x4bc)
	if (not _0x4bf) then
		local _0x4c1 = _0x480.resolve(_0x4be.id)
		if (_0x4c1 and (_0x4c1 ~= _0x4be.id)) then
			_0x4bf, _0x4c0 = _0x480.probe(_0x4b7, _0x4c1, (os.clock() + 2))
			if _0x4bf then
				_0x4be.resolvedFrom = _0x4be.id
				_0x4be.id = _0x4c1
			end
		end
	end
	_0x4be.length, _0x4be.looped = _0x4bf, _0x4c0
	_0x4bb = (_0x4bb - 1)
end)
	end
	local _0x4c2 = (os.clock() + 9)
	while ((_0x4bb > 0) and (os.clock() < _0x4c2)) do
		task.wait(0.05)
	end
	for _0x4c3, _0x4c4 in ipairs(_0x4b8) do
		if _0x4c4.length then
			if (_0x4c4.slot == _0xS_D("\196\201\193\200\159")) then
				_0x4b6.idleExtra = _0x4c4.id
			else
				_0x4b6.ids[_0x4c4.slot] = _0x4c4.id
			end
			_0x4b6.lengths[_0x4c4.id] = _0x4c4.length
		else
			if (_0x4c4.slot == _0xS_D("\196\201\193\200\159")) then
				_0x4b6.idleExtra = nil
			else
				_0x4b6.ids[_0x4c4.slot] = nil
			end
		end
	end
	_0x480.fillMissing(_0x4b6)
end
function _0x2.R15.animateTracks(_0x4c5, _0x4c6)
	local _0x4c7 = _0x4c5:FindFirstChild(_0xS_D("\236\195\196\192\204\217\200"))
	local _0x4c8 = _0x4c6:FindFirstChildOfClass(_0xS_D("\236\195\196\192\204\217\194\223"))
	local _0x4c9 = {}
	if ((not _0x4c7) or (not _0x4c8)) then
		return _0x4c9, _0x4c7, _0x4c8
	end
	local _0x4ca, _0x4cb = pcall(function()
	return _0x4c8:GetPlayingAnimationTracks()
end)
	if _0x4ca then
		for _0x4cc, _0x4cd in ipairs(_0x4cb) do
			local _0x4ce = _0x4cd.Animation
			if (_0x4ce and _0x4ce:IsDescendantOf(_0x4c7)) then
				table.insert(_0x4c9, _0x4cd)
			end
		end
	end
	return _0x4c9, _0x4c7, _0x4c8
end
function _0x2.R15.animationsHealthy(_0x4cf, _0x4d0, _0x4d1)
	local _0x4d2, _0x4d3, _0x4d4 = _0x2.R15.animateTracks(_0x4cf, _0x4d0)
	if ((not _0x4d3) or (not _0x4d4)) then
		return true, _0xS_D("\222\196\195\141\236\195\196\192\204\217\200\130\236\195\196\192\204\217\194\223\129\141\195\204\201\204\141\220\216\200\141\206\194\192\221\223\194\207\204\223")
	end
	if (_0x4d0.Health <= 0) then
		return true, _0xS_D("\221\200\223\222\194\195\204\199\200\141\192\216\200\223\217\194")
	end
	if ((#_0x4d2) == 0) then
		return false, _0xS_D("\195\196\195\202\216\195\204\141\204\195\196\192\204\206\196\110\030\195\141\201\200\193\141\236\195\196\192\204\217\200\141\222\200\141\200\222\217\110\012\141\223\200\221\223\194\201\216\206\196\200\195\201\194")
	end
	local _0x4d5 = ((_0x4d1 and _0x4d1.lengths) or {})
	local _0x4d6 = {}
	for _0x4d7, _0x4d8 in ipairs(_0x4d2) do
		local _0x4d9 = _0x4d5[_0x47a(_0x4d8.Animation.AnimationId)]
		if (_0x4d9 and (math.abs((_0x4d8.Length - _0x4d9)) > 0.02)) then
			return false, (_0xS_D("\222\200\141\223\200\221\223\194\201\216\206\200\141\216\195\204\141\221\196\222\217\204\141\206\204\223\202\204\201\204\141\206\194\195\141\216\195\141\196\201\141\204\195\217\200\223\196\194\223\141\133") .. (tostring(_0x4d8.Animation.Name) .. _0xS_D("\132")))
		end
		_0x4d6[_0x4d8] = _0x4d8.TimePosition
	end
	task.wait(0.3)
	for _0x4da, _0x4db in ipairs(_0x4d2) do
		local _0x4dc = pcall(function()
	if (((_0x4db.IsPlaying and (_0x4db.Length > 0.1)) and (_0x4db.Speed ~= 0)) and (_0x4db.WeightCurrent > 0.05)) then
		if (_0x4db.TimePosition == _0x4d6[_0x4db]) then
			error(_0xS_D("\203\223\194\215\200\195"))
		end
	end
end)
		if (not _0x4dc) then
			return false, (_0xS_D("\193\204\141\221\194\222\200\141\200\222\217\110\012\141\206\194\195\202\200\193\204\201\204\141\133") .. (tostring(_0x4db.Animation.Name) .. _0xS_D("\132")))
		end
	end
	return true, _0xS_D("\194\198")
end
local function _0x4dd(_0x4de)
	local _0x4df, _0x4e0 = pcall(function()
	return _0x4de.Enabled
end)
	if (_0x4df and (type(_0x4e0) == _0xS_D("\207\194\194\193\200\204\195"))) then
		return _0x4e0
	end
	local _0x4e1, _0x4e2 = pcall(function()
	return _0x4de.Disabled
end)
	if (_0x4e1 and (type(_0x4e2) == _0xS_D("\207\194\194\193\200\204\195"))) then
		return (not _0x4e2)
	end
	return true
end
function _0x2.R15.reloadAnimate(_0x4e3, _0x4e4)
	local _0x4e5, _0x4e6 = _0x2.R15.animateTracks(_0x4e3, _0x4e4)
	if (not _0x4e6) then
		return false
	end
	local _0x4e7 = _0x4e6.Archivable
	pcall(function()
	_0x4e6.Archivable = true
end)
	local _0x4e8
	local _0x4e9 = pcall(function()
	_0x4e8 = _0x4e6:Clone()
end)
	pcall(function()
	_0x4e6.Archivable = _0x4e7
end)
	if ((not _0x4e9) or (not _0x4e8)) then
		return false
	end
	for _0x4ea, _0x4eb in ipairs(_0x4e5) do
		pcall(function()
	_0x4eb:Stop(0)
end)
	end
	_0x4e6:Destroy()
	task.wait()
	if (not _0x4e3.Parent) then
		_0x4e8:Destroy()
		return false
	end
	_0x4e8.Parent = _0x4e3
	return true
end
function _0x2.R15.rebuildAnimator(_0x4ec, _0x4ed)
	local _0x4ee = _0x4ed:FindFirstChildOfClass(_0xS_D("\236\195\196\192\204\217\194\223"))
	if _0x4ee then
		local _0x4ef, _0x4f0 = pcall(function()
	return _0x4ee:GetPlayingAnimationTracks()
end)
		if _0x4ef then
			for _0x4f1, _0x4f2 in ipairs(_0x4f0) do
				pcall(function()
	_0x4f2:Stop(0)
end)
			end
		end
		pcall(function()
	_0x4ee:Destroy()
end)
		task.wait()
	end
	local _0x4f3 = Instance.new(_0xS_D("\236\195\196\192\204\217\194\223"))
	_0x4f3.Parent = _0x4ed
	return _0x4f3
end
local _0x4f4 = nil
function _0x2.R15.stopDriver()
	local _0x4f5 = _0x4f4
	_0x4f4 = nil
	if (not _0x4f5) then
		return
	end
	for _0x4f6, _0x4f7 in ipairs(_0x4f5.conns) do
		pcall(function()
	_0x4f7:Disconnect()
end)
	end
	for _0x4f8, _0x4f9 in pairs(_0x4f5.tracks) do
		pcall(function()
	_0x4f9:Stop(0.1)
	_0x4f9:Destroy()
end)
	end
	for _0x4fa, _0x4fb in ipairs(_0x4f5.anims) do
		pcall(function()
	_0x4fb:Destroy()
end)
	end
	if (_0x4f5.animate and _0x4f5.animate.Parent) then
		_0x2dd(_0x4f5.animate, true)
	end
end
function _0x2.R15.startDriver(_0x4fc, _0x4fd, _0x4fe)
	_0x2.R15.stopDriver()
	local _0x4ff = _0x4fc:FindFirstChild(_0xS_D("\229\216\192\204\195\194\196\201\255\194\194\217\253\204\223\217"))
	local _0x500 = _0x4fd:FindFirstChildOfClass(_0xS_D("\236\195\196\192\204\217\194\223"))
	if ((not _0x4ff) or (not _0x500)) then
		return false
	end
	local _0x501 = _0x4fc:FindFirstChild(_0xS_D("\236\195\196\192\204\217\200"))
	if _0x501 then
		_0x2dd(_0x501, false)
	end
	local _0x502, _0x503 = pcall(function()
	return _0x500:GetPlayingAnimationTracks()
end)
	if _0x502 then
		for _0x504, _0x505 in ipairs(_0x503) do
			pcall(function()
	_0x505:Stop(0.1)
end)
		end
	end
	local _0x506 = { tracks = {}, anims = {}, conns = {}, current = nil, name = nil, animate = _0x501 }
	_0x4f4 = _0x506
	local _0x507 = ((_0x4fe and _0x4fe.ids) or {})
	local _0x508 = { idle = true, walk = true, run = true, fall = true, climb = true, swim = true }
	for _0x509 in pairs(_0x2.SLOT_NAMES) do
		local _0x50a = _0x507[_0x509]
		if (not _0x50a) then
			local _0x50b = _0x2.ROBLOX_DEFAULT_ANIMS[_0x509]
			_0x50a = (_0x50b and _0x50b[1])
		end
		if _0x50a then
			local _0x50c = Instance.new(_0xS_D("\236\195\196\192\204\217\196\194\195"))
			_0x50c.AnimationId = (_0xS_D("\223\207\213\204\222\222\200\217\196\201\151\130\130") .. tostring(_0x50a))
			table.insert(_0x506.anims, _0x50c)
			local _0x50d, _0x50e = pcall(function()
	return _0x500:LoadAnimation(_0x50c)
end)
			if (_0x50d and _0x50e) then
				if _0x508[_0x509] then
					pcall(function()
	_0x50e.Looped = true
end)
				end
				_0x506.tracks[_0x509] = _0x50e
			end
		end
	end
	local function _0x50f(_0x510, _0x511)
		local _0x512 = _0x506.tracks[_0x510]
		if (not _0x512) then
			_0x510 = _0xS_D("\196\201\193\200")
			_0x512 = _0x506.tracks.idle
		end
		if (not _0x512) then
			return
		end
		if (_0x506.name ~= _0x510) then
			if _0x506.current then
				pcall(function()
	_0x506.current:Stop(0.2)
end)
			end
			pcall(function()
	_0x512:Play(0.2)
end)
			_0x506.current = _0x512
			_0x506.name = _0x510
		end
		if _0x511 then
			pcall(function()
	_0x512:AdjustSpeed(_0x511)
end)
		end
	end
	local function _0x513()
		if _0x506.current then
			pcall(function()
	_0x506.current:Stop(0.2)
end)
			_0x506.current = nil
			_0x506.name = nil
		end
	end
	table.insert(_0x506.conns, _0x7.Heartbeat:Connect(function()
	if (((_0x4f4 ~= _0x506) or (_0x4fd.Health <= 0)) or (not _0x4ff.Parent)) then
		return
	end
	local _0x514 = _0x4fd:GetState()
	local _0x515 = _0x4ff.AssemblyLinearVelocity
	local _0x516 = Vector3.new(_0x515.X, 0, _0x515.Z).Magnitude
	if (_0x514 == Enum.HumanoidStateType.Jumping) then
		_0x50f(_0xS_D("\199\216\192\221"), 1)
	elseif (_0x514 == Enum.HumanoidStateType.Freefall) then
		local _0x517 = _0x506.tracks.jump
		local _0x518 = ((((_0x506.name == _0xS_D("\199\216\192\221")) and _0x517) and _0x517.IsPlaying) and (_0x517.TimePosition < (_0x517.Length - 0.05)))
		if (not _0x518) then
			_0x50f(_0xS_D("\203\204\193\193"), 1)
		end
	elseif (_0x514 == Enum.HumanoidStateType.Climbing) then
		_0x50f(_0xS_D("\206\193\196\192\207"), math.clamp((_0x515.Y / 5), (-3), 3))
	elseif (_0x514 == Enum.HumanoidStateType.Swimming) then
		_0x50f(_0xS_D("\222\218\196\192"), 1)
	elseif ((((((_0x514 == Enum.HumanoidStateType.Seated) or (_0x514 == Enum.HumanoidStateType.Dead)) or (_0x514 == Enum.HumanoidStateType.PlatformStanding)) or (_0x514 == Enum.HumanoidStateType.FallingDown)) or (_0x514 == Enum.HumanoidStateType.Ragdoll)) or (_0x514 == Enum.HumanoidStateType.Physics)) then
		_0x513()
	elseif (_0x516 > 0.75) then
		local _0x519 = (((((_0x506.tracks.run and _0x507.run) and (_0x516 > 21))) and _0xS_D("\223\216\195")) or _0xS_D("\218\204\193\198"))
		_0x50f(_0x519, math.clamp((_0x516 / 16), 0.4, 2.2))
	else
		_0x50f(_0xS_D("\196\201\193\200"), 1)
	end
end))
	table.insert(_0x506.conns, _0x4fc.AncestryChanged:Connect(function(_0x51a, _0x51b)
	if ((not _0x51b) and (_0x4f4 == _0x506)) then
		_0x2.R15.stopDriver()
	end
end))
	return true
end
function _0x2.R15.driverMoving()
	local _0x51c = _0x4f4
	if ((not _0x51c) or (not _0x51c.current)) then
		return true
	end
	local _0x51d = _0x51c.current.TimePosition
	task.wait(0.25)
	if ((_0x4f4 ~= _0x51c) or (not _0x51c.current)) then
		return true
	end
	return ((_0x51c.current.TimePosition ~= _0x51d) or (_0x51c.current.Length <= 0.1))
end
function _0x2.R15.finalizeAnimations(_0x51e, _0x51f, _0x520, _0x521, _0x522, _0x523)
	if (not _0x523()) then
		return
	end
	_0x2.R15.stopDriver()
	local _0x524 = (_0x2.R15.applyAnimations(_0x51e, _0x51f, _0x520, _0x521, _0x522) or 0)
	if (_0x524 > 0) then
		_0x2.R15.reloadAnimate(_0x51e, _0x51f)
	end
	task.wait(0.7)
	if (not _0x523()) then
		return
	end
	if _0x2.R15.animationsHealthy(_0x51e, _0x51f, _0x522) then
		return
	end
	local _0x525 = _0x51e:FindFirstChild(_0xS_D("\236\195\196\192\204\217\200"))
	if ((not _0x525) or (not _0x4dd(_0x525))) then
		return
	end
	local _0x526 = { function()
	_0x2.R15.reloadAnimate(_0x51e, _0x51f)
end, function()
	_0x2.R15.rebuildAnimator(_0x51e, _0x51f)
	_0x2.R15.reloadAnimate(_0x51e, _0x51f)
end }
	for _0x527, _0x528 in ipairs(_0x526) do
		if (not _0x523()) then
			return
		end
		pcall(_0x528)
		task.wait(1)
		if (not _0x523()) then
			return
		end
		if _0x2.R15.animationsHealthy(_0x51e, _0x51f, _0x522) then
			return
		end
	end
	if (not _0x523()) then
		return
	end
	if _0x2.R15.startDriver(_0x51e, _0x51f, _0x522) then
		task.wait(0.6)
		if (_0x523() and (not _0x2.R15.driverMoving())) then
			_0x2.R15.rebuildAnimator(_0x51e, _0x51f)
			if _0x523() then
				_0x2.R15.startDriver(_0x51e, _0x51f, _0x522)
			end
		end
	end
end
function _0x2.R15.manualAttach(_0x529, _0x52a)
	local _0x52b = _0x529:FindFirstChild(_0xS_D("\229\204\195\201\193\200"))
	if ((not _0x52b) or (not _0x52b:IsA(_0xS_D("\239\204\222\200\253\204\223\217")))) then
		return false
	end
	local _0x52c = _0x1b5(_0x52b)
	if (not _0x52c) then
		return false
	end
	local _0x52d = _0x1b9(_0x52a, _0x52c.Name)
	if (not _0x52d) then
		return false
	end
	_0x529.Parent = _0x52a
	_0x52b.Anchored = false
	_0x52b.CanCollide = false
	_0x52b.Massless = true
	_0x52b.CFrame = ((_0x52d.Parent.CFrame * _0x52d.CFrame) * _0x52c.CFrame:Inverse())
	local _0x52e = _0x52b:FindFirstChild(_0xS_D("\236\206\206\200\222\222\194\223\212\250\200\193\201"))
	if _0x52e then
		_0x52e:Destroy()
	end
	local _0x52f = Instance.new(_0xS_D("\250\200\193\201"))
	_0x52f.Name = _0xS_D("\236\206\206\200\222\222\194\223\212\250\200\193\201")
	_0x52f.Part0 = _0x52b
	_0x52f.Part1 = _0x52d.Parent
	_0x52f.C0 = _0x52c.CFrame
	_0x52f.C1 = _0x52d.CFrame
	_0x52f.Parent = _0x52b
	return true
end
function _0x2.R15.wipeAppearance(_0x530)
	for _0x531, _0x532 in ipairs(_0x530:GetChildren()) do
		if (((((_0x532:IsA(_0xS_D("\236\206\206\200\222\222\194\223\212")) or _0x532:IsA(_0xS_D("\229\204\217"))) or _0x532:IsA(_0xS_D("\238\193\194\217\197\196\195\202"))) or _0x532:IsA(_0xS_D("\254\197\196\223\217\234\223\204\221\197\196\206"))) or _0x532:IsA(_0xS_D("\238\197\204\223\204\206\217\200\223\224\200\222\197"))) or _0x532:IsA(_0xS_D("\239\194\201\212\238\194\193\194\223\222"))) then
			_0x532:Destroy()
		elseif _0x532:IsA(_0xS_D("\239\204\222\200\253\204\223\217")) then
			for _0x533, _0x534 in ipairs(_0x532:GetChildren()) do
				if (((((_0x534:IsA(_0xS_D("\233\200\206\204\193")) or _0x534:IsA(_0xS_D("\254\216\223\203\204\206\200\236\221\221\200\204\223\204\195\206\200"))) or _0x534:IsA(_0xS_D("\233\204\217\204\224\194\201\200\193\224\200\222\197"))) or _0x534:IsA(_0xS_D("\235\204\206\200\238\194\195\217\223\194\193\222"))) or _0x534:IsA(_0xS_D("\250\223\204\221\249\204\223\202\200\217"))) or _0x534:IsA(_0xS_D("\250\223\204\221\225\204\212\200\223"))) then
					_0x534:Destroy()
				end
			end
		end
	end
end
function _0x2.R15.copyVisual(_0x535, _0x536)
	_0x535.Color = _0x536.Color
	_0x535.Material = _0x536.Material
	_0x535.Reflectance = _0x536.Reflectance
	_0x535.Transparency = _0x536.Transparency
end
function _0x2.R15.copyPartChildren(_0x537, _0x538)
	for _0x539, _0x53a in ipairs(_0x538:GetChildren()) do
		if _0x53a:IsA(_0xS_D("\236\217\217\204\206\197\192\200\195\217")) then
			local _0x53b = _0x537:FindFirstChild(_0x53a.Name)
			if (_0x53b and _0x53b:IsA(_0xS_D("\236\217\217\204\206\197\192\200\195\217"))) then
				_0x53b.CFrame = _0x53a.CFrame
			else
				_0x53a:Clone().Parent = _0x537
			end
		elseif (((((_0x53a:IsA(_0xS_D("\254\216\223\203\204\206\200\236\221\221\200\204\223\204\195\206\200")) or _0x53a:IsA(_0xS_D("\235\204\206\200\238\194\195\217\223\194\193\222"))) or _0x53a:IsA(_0xS_D("\250\223\204\221\249\204\223\202\200\217"))) or _0x53a:IsA(_0xS_D("\250\223\204\221\225\204\212\200\223"))) or _0x53a:IsA(_0xS_D("\233\200\206\204\193"))) or _0x53a:IsA(_0xS_D("\233\204\217\204\224\194\201\200\193\224\200\222\197"))) then
			_0x53a:Clone().Parent = _0x537
		end
	end
end
function _0x2.R15.replaceBodyPart(_0x53c, _0x53d, _0x53e)
	local _0x53f = _0x53e:Clone()
	for _0x540, _0x541 in ipairs(_0x53f:GetChildren()) do
		if (_0x541:IsA(_0xS_D("\224\194\217\194\223\155\233")) or _0x541:IsA(_0xS_D("\250\200\193\201"))) then
			_0x541:Destroy()
		end
	end
	_0x53f.CFrame = _0x53d.CFrame
	_0x53f.Anchored = false
	_0x53f.CanCollide = _0x53d.CanCollide
	_0x53f.CanTouch = _0x53d.CanTouch
	_0x53f.CanQuery = _0x53d.CanQuery
	_0x53f.Massless = _0x53d.Massless
	_0x53f.Parent = _0x53c
	for _0x542, _0x543 in ipairs(_0x53c:GetDescendants()) do
		if _0x543:IsA(_0xS_D("\224\194\217\194\223\155\233")) then
			if (_0x543.Part1 == _0x53d) then
				_0x543.Part1 = _0x53f
				_0x543.Parent = _0x53f
			end
			if (_0x543.Part0 == _0x53d) then
				_0x543.Part0 = _0x53f
			end
		end
	end
	_0x53d:Destroy()
	return _0x53f
end
function _0x2.R15.needsFullReplace(_0x544)
	return (_0x544:FindFirstChildWhichIsA(_0xS_D("\239\194\195\200"), true) ~= nil)
end
function _0x2.R15.syncPart(_0x545, _0x546)
	local _0x547 = _0x545:FindFirstChild(_0x546.Name)
	if (not ((_0x547 and _0x547:IsA(_0xS_D("\239\204\222\200\253\204\223\217"))))) then
		return nil
	end
	if ((_0x547:IsA(_0xS_D("\224\200\222\197\253\204\223\217")) and _0x546:IsA(_0xS_D("\224\200\222\197\253\204\223\217"))) and (not _0x2.R15.needsFullReplace(_0x546))) then
		local _0x548 = (_0x547.MeshId == _0x546.MeshId)
		if (not _0x548) then
			pcall(function()
	_0x547:ApplyMesh(_0x546)
end)
			_0x548 = (_0x547.MeshId == _0x546.MeshId)
		end
		if _0x548 then
			_0x547.TextureID = _0x546.TextureID
			_0x547.Size = _0x546.Size
			_0x2.R15.copyVisual(_0x547, _0x546)
			_0x2.R15.copyPartChildren(_0x547, _0x546)
			return _0x547
		end
	end
	return _0x2.R15.replaceBodyPart(_0x545, _0x547, _0x546)
end
function _0x2.R15.applyDonorData(_0x549, _0x54a, _0x54b, _0x54c)
	_0x2.R15.wipeAppearance(_0x549)
	for _0x54d, _0x54e in ipairs(_0x54b:GetChildren()) do
		if (_0x54e:IsA(_0xS_D("\239\204\222\200\253\204\223\217")) and (_0x54e.Name ~= _0xS_D("\229\216\192\204\195\194\196\201\255\194\194\217\253\204\223\217"))) then
			_0x2.R15.syncPart(_0x549, _0x54e)
		end
	end
	for _0x54f, _0x550 in ipairs(_0x54b:GetDescendants()) do
		if (_0x550:IsA(_0xS_D("\224\194\217\194\223\155\233")) and _0x550.Part1) then
			local _0x551 = _0x549:FindFirstChild(_0x550.Part1.Name)
			local _0x552 = (_0x551 and _0x551:FindFirstChild(_0x550.Name))
			if (_0x552 and _0x552:IsA(_0xS_D("\224\194\217\194\223\155\233"))) then
				_0x552.C0 = _0x550.C0
				_0x552.C1 = _0x550.C1
			end
		end
	end
	local _0x553 = _0x549:FindFirstChild(_0xS_D("\229\200\204\201"))
	if (_0x553 and _0x553:IsA(_0xS_D("\239\204\222\200\253\204\223\217"))) then
		_0x267(_0x553, _0x54c)
	end
	local _0x554 = _0x54b:FindFirstChildOfClass(_0xS_D("\239\194\201\212\238\194\193\194\223\222"))
	if _0x554 then
		local _0x555 = _0x554:Clone()
		_0x555.Parent = _0x549
		_0x214(_0x549, _0x555)
	end
	for _0x556, _0x557 in ipairs(_0x54b:GetChildren()) do
		if (((_0x557:IsA(_0xS_D("\254\197\196\223\217")) or _0x557:IsA(_0xS_D("\253\204\195\217\222"))) or _0x557:IsA(_0xS_D("\254\197\196\223\217\234\223\204\221\197\196\206"))) or _0x557:IsA(_0xS_D("\238\197\204\223\204\206\217\200\223\224\200\222\197"))) then
			_0x557:Clone().Parent = _0x549
		end
	end
	local _0x558 = {}
	for _0x559, _0x55a in ipairs(_0x54b:GetChildren()) do
		if _0x55a:IsA(_0xS_D("\236\206\206\200\222\222\194\223\212")) then
			local _0x55b = _0x55a:Clone()
			local _0x55c = _0x55b:FindFirstChild(_0xS_D("\229\204\195\201\193\200"))
			if _0x55c then
				local _0x55d = _0x55c:FindFirstChild(_0xS_D("\236\206\206\200\222\222\194\223\212\250\200\193\201"))
				if _0x55d then
					_0x55d:Destroy()
				end
			end
			local _0x55e = pcall(function()
	_0x54a:AddAccessory(_0x55b)
end)
			_0x55c = _0x55b:FindFirstChild(_0xS_D("\229\204\195\201\193\200"))
			if (not (((_0x55e and _0x55c) and _0x55c:FindFirstChild(_0xS_D("\236\206\206\200\222\222\194\223\212\250\200\193\201"))))) then
				_0x2.R15.manualAttach(_0x55b, _0x549)
			end
			_0x558[_0x55a] = _0x55b
		end
	end
	return _0x558
end
function _0x2.R15.readLiveAnimations(_0x55f)
	local _0x560 = {}
	pcall(function()
	local _0x561 = (_0x55f and _0x55f.Character)
	local _0x562 = (_0x561 and _0x561:FindFirstChildOfClass(_0xS_D("\229\216\192\204\195\194\196\201")))
	if ((not _0x562) or (_0x562.RigType ~= Enum.HumanoidRigType.R15)) then
		return
	end
	local _0x563 = _0x561:FindFirstChild(_0xS_D("\236\195\196\192\204\217\200"))
	if (not _0x563) then
		return
	end
	for _0x564, _0x565 in ipairs(_0x2.ANIM_MAP) do
		local _0x566 = _0x563:FindFirstChild(_0x565[1])
		local _0x567 = (_0x566 and _0x566:FindFirstChild(_0x565[2]))
		if ((_0x567 and _0x567:IsA(_0xS_D("\236\195\196\192\204\217\196\194\195"))) and (_0x567.AnimationId ~= _0xS_D(""))) then
			_0x560[(_0x565[1] .. (_0xS_D("\130") .. _0x565[2]))] = _0x567.AnimationId
		end
	end
end)
	return _0x560
end
function _0x2.R15.applyAnimations(_0x568, _0x569, _0x56a, _0x56b, _0x56c)
	local _0x56d = (_0x568:FindFirstChild(_0xS_D("\236\195\196\192\204\217\200")) or _0x568:WaitForChild(_0xS_D("\236\195\196\192\204\217\200"), 1))
	if (not _0x56d) then
		return
	end
	_0x410(_0x568)
	local _0x56e = (_0x1b[_0x568] or {})
	local _0x56f = {}
	for _0x570, _0x571 in ipairs(_0x2.ANIM_MAP) do
		local _0x572, _0x573 = _0x571[1], _0x571[2]
		local _0x574 = (_0x572 .. (_0xS_D("\130") .. _0x573))
		local _0x575 = (_0x56c and _0x56c.ids[_0x572])
		if ((((_0x572 == _0xS_D("\196\201\193\200")) and (_0x573 == _0xS_D("\236\195\196\192\204\217\196\194\195\159"))) and _0x56c) and _0x56c.idleExtra) then
			_0x575 = _0x56c.idleExtra
		end
		local _0x576 = ((_0x575 and ((_0xS_D("\223\207\213\204\222\222\200\217\196\201\151\130\130") .. tostring(_0x575)))) or _0x56e[_0x574])
		local _0x577 = _0x56d:FindFirstChild(_0x572)
		local _0x578 = (_0x577 and _0x577:FindFirstChild(_0x573))
		if _0x576 then
			if (not _0x577) then
				_0x577 = Instance.new(_0xS_D("\254\217\223\196\195\202\251\204\193\216\200"))
				_0x577.Name = _0x572
				_0x577:SetAttribute(_0xS_D("\236\235\226\242\238\223\200\204\217\200\201"), true)
				_0x577.Parent = _0x56d
			end
			if (not ((_0x578 and _0x578:IsA(_0xS_D("\236\195\196\192\204\217\196\194\195"))))) then
				_0x578 = Instance.new(_0xS_D("\236\195\196\192\204\217\196\194\195"))
				_0x578.Name = _0x573
				_0x578:SetAttribute(_0xS_D("\236\235\226\242\238\223\200\204\217\200\201"), true)
				_0x578.Parent = _0x577
			end
			if (_0x578.AnimationId ~= _0x576) then
				_0x578.AnimationId = _0x576
				table.insert(_0x56f, _0x578)
			end
		elseif (_0x578 and _0x578:GetAttribute(_0xS_D("\236\235\226\242\238\223\200\204\217\200\201"))) then
			_0x578:Destroy()
			if ((_0x577 and _0x577:GetAttribute(_0xS_D("\236\235\226\242\238\223\200\204\217\200\201"))) and ((#_0x577:GetChildren()) == 0)) then
				_0x577:Destroy()
			end
		end
	end
	if ((#_0x56f) > 0) then
		local _0x579 = false
		task.spawn(function()
	pcall(function()
	_0x6:PreloadAsync(_0x56f)
end)
	_0x579 = true
end)
		local _0x57a = 0
		while ((not _0x579) and (_0x57a < 2)) do
			task.wait(0.05)
			_0x57a = (_0x57a + 0.05)
		end
	end
	return (#_0x56f)
end
function _0x2.R15.forceFixed(_0x57b, _0x57c)
	if (((not _0x57b) or (not _0x57c)) or (_0x57c.RigType ~= Enum.HumanoidRigType.R15)) then
		return
	end
	local _0x57d = (_0x57b:FindFirstChild(_0xS_D("\236\195\196\192\204\217\200")) or _0x57b:WaitForChild(_0xS_D("\236\195\196\192\204\217\200"), 5))
	if (not _0x57d) then
		return
	end
	local _0x57e = _0x480.forceFixed({ ids = {}, source = {} })
	local _0x57f = (_0x2.R15.applyAnimations(_0x57b, _0x57c, nil, nil, _0x57e) or 0)
	if ((_0x57f > 0) and _0x57b.Parent) then
		_0x2.R15.reloadAnimate(_0x57b, _0x57c)
	end
end
function _0x2.R15.measureHipHeight(_0x580, _0x581)
	local _0x582 = _0xfe(_0x580)
	local _0x583
	for _0x584, _0x585 in pairs(_0x582) do
		if (((_0x584 ~= _0x581) and _0x584:IsA(_0xS_D("\239\204\222\200\253\204\223\217"))) and (not _0x31(_0x584))) then
			local _0x586 = (_0x585.Position.Y - _0xfb(_0x585, _0x584.Size))
			_0x583 = ((_0x583 and math.min(_0x583, _0x586)) or _0x586)
		end
	end
	if (not _0x583) then
		return nil
	end
	local _0x587 = ((-_0x583) - (_0x581.Size.Y / 2))
	if ((_0x587 < 0.3) or (_0x587 > 15)) then
		return nil
	end
	return _0x587
end
function _0x2.R15.syncRoot(_0x588, _0x589, _0x58a)
	local _0x58b = _0x588:FindFirstChild(_0xS_D("\229\216\192\204\195\194\196\201\255\194\194\217\253\204\223\217"))
	if (not _0x58b) then
		return
	end
	local _0x58c = _0x2.R15.measureHipHeight(_0x588, _0x58b)
	if (not _0x58c) then
		local _0x58d = _0x58a:FindFirstChild(_0xS_D("\229\216\192\204\195\194\196\201\255\194\194\217\253\204\223\217"))
		local _0x58e = _0x58a:FindFirstChildOfClass(_0xS_D("\229\216\192\204\195\194\196\201"))
		if (_0x58d and _0x58e) then
			_0x58c = math.max(((_0x58e.HipHeight + (_0x58d.Size.Y / 2)) - (_0x58b.Size.Y / 2)), 0)
		end
	end
	if _0x58c then
		pcall(function()
	_0x589.HipHeight = _0x58c
end)
	end
end
function _0x2.R15.swap(_0x58f, _0x590, _0x591, _0x592, _0x593, _0x594, _0x595)
	_0x2.R15.applyDonorData(_0x58f, _0x590, _0x591, _0x595)
	_0x2.R15.syncRoot(_0x58f, _0x590, _0x591)
end
local function _0x596(_0x597, _0x598, _0x599, _0x59a, _0x59b)
	if (((not _0xc) or (not _0x597)) or (_0x597 == _0xS_D(""))) then
		return
	end
	_0x597 = _0x2f(_0x597)
	local _0x59c = false
	if ((not _0x59b) and (not _0x598)) then
		local _0x59d = (_0x16 or _0xc.Name)
		if (_0x597:lower() == _0x59d:lower()) then
			_0x59c = true
			_0x599 = false
		end
	end
	if (not _0x59b) then
		_0x1e = true
	end
	task.spawn(function()
	local _0x59e = (_0xc.Character or _0xc.CharacterAdded:Wait())
	local _0x59f = _0x59e:WaitForChild(_0xS_D("\229\216\192\204\195\194\196\201"), 10)
	if (not _0x59f) then
		return
	end
	local _0x5a0 = _0x59e:WaitForChild(_0xS_D("\229\216\192\204\195\194\196\201\255\194\194\217\253\204\223\217"), 10)
	if (not _0x5a0) then
		return
	end
	pcall(_0x2c1.waitLoaded, _0x59e)
	_0x418(_0x59e, _0x59f)
	local _0x5a1 = _0x48(_0x597)
	if (not _0x5a1) then
		if _0x59a then
			_0x59a()
		end
		return
	end
	_0x17 = (_0x17 + 1)
	local _0x5a2 = _0x17
	local _0x5a3 = _0x16
	_0x16 = _0x597
	_0x51(_0x5a1, _0x5a2)
	if _0x59c then
		_0x326()
	end
	if _0x599 then
		_0x86(_0x59e)
		_0x5f(_0x2.SFX_START, _0x2.SFX_START_VOLUME)
		_0x65()
	end
	local function _0x5a4()
		return ((((_0x5a2 == _0x17) and (_0xc.Character == _0x59e)) and (_0x59e.Parent ~= nil)) and (_0x59f.Health > 0))
	end
	local function _0x5a5()
		if (_0x5a2 == _0x17) then
			_0x16 = _0x5a3
			_0x81(false)
			if _0x59a then
				_0x59a()
			end
		end
	end
	local _0x5a6 = _0x38(_0x59e, _0x59f)
	local _0x5a7 = (_0x5a6 == Enum.HumanoidRigType.R15)
	local _0x5a8
	if (_0x598 and _0x1c[_0x59e]) then
		_0x5a8 = _0x1c[_0x59e]:Clone()
	else
		_0x5a8 = _0x4d(_0x5a1)
	end
	if (not _0x5a4()) then
		return
	end
	if (not _0x5a8) then
		_0x5a5()
		return
	end
	local _0x5a9 = nil
	if (_0x5a7 and (not _0x598)) then
		_0x5a9 = _0x3:GetPlayerByUserId(_0x5a1)
		if (_0x5a9 == _0xc) then
			_0x5a9 = nil
		end
	end
	local _0x5aa = nil
	if _0x5a7 then
		_0x5aa = _0x480.build(_0x5a1, _0x597, _0x5a8, _0x5a9)
		if (not _0x5a4()) then
			return
		end
	end
	local _0x5ab = true
	if (_0x5a7 and _0x5aa) then
		_0x5ab = false
		task.spawn(function()
	local _0x5ac, _0x5ad = pcall(_0x480.validate, _0x59f, _0x5aa)
	if (not _0x5ac) then
	end
	_0x5ab = true
end)
	end
	local _0x5ae = { reset = _0x598, original = ((_0x598 and _0x1d[_0x59e]) or nil) }
	local _0x5af = false
	task.spawn(function()
	_0x5ae.resolved = _0x25e(_0x5a1, _0x5a8)
	_0x5af = true
	if ((_0x5ae.swapped and (_0x5a2 == _0x17)) and _0x59e.Parent) then
		local _0x5b0 = _0x1a8(_0x59e, _0xS_D("\229\200\204\201"))
		if (_0x5b0 and _0x5b0:IsA(_0xS_D("\239\204\222\200\253\204\223\217"))) then
			_0x267(_0x5b0, _0x5ae, true)
		end
	end
end)
	local _0x5b1 = ((((not _0x5a7)) and _0x2.USE_APPLY_DESCRIPTION_R6) and (_0x59f.RigType == _0x5a6))
	local _0x5b2
	local function _0x5b3(_0x5b4)
		local _0x5b5 = _0x27(_0x3, { _0xS_D("\238\223\200\204\217\200\229\216\192\204\195\194\196\201\224\194\201\200\193\235\223\194\192\233\200\222\206\223\196\221\217\196\194\195\236\222\212\195\206"), _0xS_D("\238\223\200\204\217\200\229\216\192\204\195\194\196\201\224\194\201\200\193\235\223\194\192\233\200\222\206\223\196\221\217\196\194\195") }, _0x5a8, (_0x5b4 or _0x5a6))
		if (not _0x5b5) then
			return nil
		end
		if (not _0x5b5:FindFirstChildOfClass(_0xS_D("\229\216\192\204\195\194\196\201"))) then
			_0x5b5:Destroy()
			return nil
		end
		local _0x5b6 = false
		task.spawn(function()
	pcall(function()
	_0x6:PreloadAsync(_0x5b5:GetDescendants())
end)
	_0x5b6 = true
end)
		local _0x5b7 = 0
		while ((not _0x5b6) and (_0x5b7 < 8)) do
			task.wait(0.1)
			_0x5b7 = (_0x5b7 + 0.1)
		end
		pcall(_0x1.SmartBone.strip, _0x5b5)
		if (((_0x5b4 or _0x5a6)) == Enum.HumanoidRigType.R6) then
			pcall(_0x1.R6Native.complete, _0x5b5, _0x5a8)
		end
		return _0x5b5
	end
	local function _0x5b8()
		if _0x5b2 then
			_0x5b2:Destroy()
		end
	end
	if (not _0x5b1) then
		_0x5b2 = _0x5b3()
		if (not _0x5a4()) then
			_0x5b8()
			return
		end
		if (not _0x5b2) then
			_0x5a5()
			return
		end
	end
	local _0x5b9 = os.clock()
	while ((not _0x5ab) and ((os.clock() - _0x5b9) < 12)) do
		task.wait(0.05)
	end
	local _0x5ba = os.clock()
	while ((not _0x5af) and ((os.clock() - _0x5ba) < 4)) do
		task.wait(0.05)
	end
	if ((not _0x1a5(_0x5a2)) or (not _0x5a4())) then
		_0x5b8()
		return
	end
	local function _0x5bb()
		local _0x5bc
		if _0x5a7 then
			_0x2.R15.swap(_0x59e, _0x59f, _0x5b2, _0x5a8, _0x5a9, _0x5aa, _0x5ae)
		else
			_0x5bc = _0x28b(_0x59e, _0x59f, _0x5b2, { description = _0x5a8, faceSources = _0x5ae })
		end
		_0x278(_0x59e, _0x5ae, _0x5a2)
		_0x1ae(_0x59e)
		pcall(_0x1fa, _0x59e, _0x5b2)
		_0x2d9(_0x59e, _0x5a2)
		_0x1ee(_0x59e, _0x59f, _0x5bc, _0x5a2)
		_0x1.SmartBone.scheduleSettle(_0x59e, _0x5a2)
		if (_0x5a7 and (not _0x598)) then
			_0x1.Hybrid.apply(_0x59e, _0x5a2)
		end
		if (not _0x5a7) then
			pcall(_0x2c1.guard, _0x59e, _0x5b2, _0x5a2)
		end
	end
	local function _0x5bd()
		if _0x5b1 then
			local _0x5be = _0x428(_0x59e, _0x59f, _0x5a8)
			if _0x5be then
				_0x1ae(_0x59e)
				_0x1.SmartBone.scheduleSettle(_0x59e, _0x5a2)
				return true
			end
			if (not _0x5a4()) then
				return false
			end
		end
		if (not _0x5b2) then
			_0x5b2 = _0x5b3()
		end
		if (not _0x5b2) then
			return false
		end
		_0x5bb()
		return true
	end
	local function _0x5bf()
		_0x21f(_0x59e)
		local _0x5c0 = _0x446(_0x59e)
		local _0x5c1 = _0x44b(_0x59e)
		local _0x5c2, _0x5c3 = pcall(_0x43f, _0x59f, _0x5bd)
		pcall(_0x46b, _0x59e, _0x5c0, _0x5c1)
		if (not _0x5c2) then
			error(_0x5c3, 0)
		end
		if (_0x5c3 == true) then
			_0x476(_0x59f)
		end
		return _0x5c3
	end
	local function _0x5c4()
		if _0x5b2 then
			pcall(_0x1fa, _0x59e, _0x5b2)
		end
		_0x2e1(_0x59e, _0x59f)
		if (_0x5a7 and _0x5aa) then
			task.spawn(function()
	local _0x5c5, _0x5c6 = pcall(_0x2.R15.finalizeAnimations, _0x59e, _0x59f, _0x5a8, _0x5a9, _0x5aa, function()
	return (((_0x5a2 == _0x17) and (_0x59e.Parent ~= nil)) and (_0x59f.Health > 0))
end)
	if (not _0x5c5) then
	end
end)
		end
	end
	if (not _0x599) then
		_0x18 = true
		local _0x5c7, _0x5c8 = pcall(_0x5bf)
		_0x5c4()
		_0x5b8()
		_0x18 = false
		return
	end
	_0x18 = true
	local _0x5c9 = false
	local _0x5ca, _0x5cb = false, false
	local _0x5cc
	pcall(function()
	local function _0x5cd()
		return (_0x5a4() and (_0x5a0.Parent ~= nil))
	end
	local _0x5ce
	if (not _0xc5()) then
		_0x5ce = _0x108(_0x59e, _0x5a0, _0x59f, true)
	end
	local _0x5cf = (_0x5ce ~= nil)
	if _0x5ce then
		_0x99 = _0x5a2
		_0xe7(_0x59e)
		_0x8e(_0xf3())
	end
	local _0x5d0, _0x5d1 = pcall(_0x3bb, _0x59e, _0x5a0, _0x59f)
	if _0x5d0 then
		_0x5cc = _0x5d1
	else
	end
	task.spawn(function()
	local _0x5d2, _0x5d3 = pcall(_0x5bf)
	_0x5cb = (_0x5d2 and (_0x5d3 == true))
	_0x5ca = true
end)
	local _0x5d4 = os.clock()
	local _0x5d5 = 0
	while ((((not _0x5ca) or ((os.clock() - _0x5d4) < _0x2.MORPH_HOLD_MIN))) and (_0x5d5 < 25)) do
		if (not _0x5cd()) then
			_0xee()
			return
		end
		if _0x5ce then
			_0x166(_0x5ce, _0x5a0, _0x59f)
		end
		_0x5d5 = (_0x5d5 + (_0x7.Heartbeat:Wait()))
	end
	if (not _0x5cb) then
		_0xee()
		return
	end
	_0x5c4()
	if (not _0x5cd()) then
		_0xee()
		return
	end
	if _0x5cf then
		_0x7.Heartbeat:Wait()
		_0x7.Heartbeat:Wait()
		local _0x5d6 = _0x108(_0x59e, _0x5a0, _0x59f, false, true)
		if _0x5d6 then
			_0x170(_0x5ce, _0x5d6)
			if (not _0x186(_0x5ce, _0x5d6, _0x5a0, _0x59f, _0x2.MORPH_DURATION, _0x5a2, _0x5cd)) then
				return
			end
		end
	end
	_0x5c9 = true
end)
	local _0x5d7 = 0
	while ((not _0x5ca) and (_0x5d7 < 25)) do
		task.wait(0.05)
		_0x5d7 = (_0x5d7 + 0.05)
	end
	if _0x5cc then
		pcall(_0x5cc.stop)
	end
	if ((_0x99 == nil) or (_0x99 == _0x5a2)) then
		_0xee()
		_0xdc()
		_0x99 = nil
		_0x18 = false
	end
	if (_0x19 and (_0x19.character == _0x59e)) then
		_0x8e(_0x59e)
	end
	_0x2e8(_0x59f)
	_0x5b8()
	if (_0x5a2 == _0x17) then
		if _0x5c9 then
			pcall(_0x3f3, _0x59e, _0x59f)
		elseif (_0x5ca and (not _0x5cb)) then
			_0x16 = _0x5a3
			if _0x59a then
				_0x59a()
			end
		end
		_0x81(false)
	end
end)
end
_0x2.I18N = {}
_0x2.I18N.strings = { es = { title = _0xS_D("\238\236\224\239\228\236\255\141\236\251\236\249\236\255"), placeholder = _0xS_D("\248\222\216\204\223\196\194\131\131\131"), apply = _0xS_D("\236\221\193\196\206\204\223"), tip = _0xS_D("\249\196\221\151\141\143\236\221\194\201\194\143\167\239\216\222\206\204\141\199\216\202\204\201\194\223\200\222\141\200\195\141\200\222\217\200\141\222\200\223\219\196\201\194\223") }, en = { title = _0xS_D("\236\251\236\249\236\255\141\238\229\236\227\234\232\255"), placeholder = _0xS_D("\248\222\200\223\195\204\192\200\131\131\131"), apply = _0xS_D("\236\221\221\193\212"), tip = _0xS_D("\249\196\221\151\141\143\227\196\206\198\195\204\192\200\143\167\254\200\204\223\206\197\141\221\193\204\212\200\223\222\141\196\195\141\217\197\196\222\141\222\200\223\219\200\223") } }
_0x2.I18N.markers = { es = { _0xS_D("\221\200\223\222\194\195\204\199\200\222"), _0xS_D("\201\200\222\221\200\223\217"), _0xS_D("\222\194\207\223\200\206\204\223\202\204"), _0xS_D("\221\223\200\222\196\194\195\204"), _0xS_D("\221\204\217\204\201\204"), _0xS_D("\201\196\222\221\204\223\194"), _0xS_D("\204\217\204\220\216\200"), _0xS_D("\223\200\193\110\012\192\221\204\202\194"), _0xS_D("\223\200\193\204\192\221\204\202\194"), _0xS_D("\219\200\193\194\206\196\201\204\201"), _0xS_D("\204\221\193\196\206\204\223"), _0xS_D("\199\216\202\204\201\194\223"), _0xS_D("\204\199\216\222\217\200\222"), _0xS_D("\206\194\195\203\196\202\216\223\204\206\196\110\030\195"), _0xS_D("\206\194\195\203\196\202\216\223\204\206\196\194\195"), _0xS_D("\217\196\200\195\201\204"), _0xS_D("\192\196\222\196\194\195\200\222"), _0xS_D("\196\195\219\200\195\217\204\223\196\194"), _0xS_D("\204\192\196\202\194\222"), _0xS_D("\197\204\207\196\193\196\201\204\201\200\222"), _0xS_D("\200\220\216\196\221\194"), _0xS_D("\192\110\012\213\196\192"), _0xS_D("\192\204\213\196\192"), _0xS_D("\195\196\219\200\193\141\201\200"), _0xS_D("\222\204\193\196\223"), _0xS_D("\206\200\223\223\204\223") }, en = { _0xS_D("\206\197\204\223\204\206\217\200\223\222"), _0xS_D("\204\218\204\198\200\195"), _0xS_D("\194\219\200\223\193\194\204\201"), _0xS_D("\221\223\200\222\222\141"), _0xS_D("\198\196\206\198"), _0xS_D("\222\197\194\217"), _0xS_D("\204\217\217\204\206\198"), _0xS_D("\193\196\202\197\217\195\196\195\202"), _0xS_D("\222\221\200\200\201"), _0xS_D("\204\221\221\193\212"), _0xS_D("\221\193\204\212\200\223"), _0xS_D("\222\200\217\217\196\195\202\222"), _0xS_D("\222\197\194\221"), _0xS_D("\220\216\200\222\217\222"), _0xS_D("\196\195\219\200\195\217\194\223\212"), _0xS_D("\203\223\196\200\195\201\222"), _0xS_D("\222\198\196\193\193\222"), _0xS_D("\217\200\204\192"), _0xS_D("\192\204\213\196\192\216\192"), _0xS_D("\193\200\219\200\193\141\194\203"), _0xS_D("\193\200\204\219\200"), _0xS_D("\206\193\194\222\200") } }
_0x2.I18N.forced = nil
function _0x2.I18N.score(_0x5d8, _0x5d9)
	_0x5d8 = string.lower(_0x5d8)
	for _0x5da, _0x5db in pairs(_0x2.I18N.markers) do
		for _0x5dc, _0x5dd in ipairs(_0x5db) do
			if _0x5d8:find(_0x5dd, 1, true) then
				_0x5d9[_0x5da] = (_0x5d9[_0x5da] + 1)
			end
		end
	end
	if _0x5d8:find(_0xS_D("\246\110\012\110\004\110\000\110\030\110\023\110\028\111\018\111\012\240")) then
		_0x5d9.es = (_0x5d9.es + 1)
	end
end
function _0x2.I18N.detect()
	if (_0x2.I18N.forced and _0x2.I18N.strings[_0x2.I18N.forced]) then
		return _0x2.I18N.forced
	end
	local _0x5de = _0xS_D("")
	pcall(function()
	_0x5de = string.lower((_0xb.RobloxLocaleId or _0xS_D("")))
end)
	if (_0x5de == _0xS_D("")) then
		pcall(function()
	_0x5de = string.lower((_0xb.SystemLocaleId or _0xS_D("")))
end)
	end
	local _0x5df = _0x5de:sub(1, 2)
	if _0x2.I18N.strings[_0x5df] then
		return _0x5df
	end
	local _0x5e0 = { es = 0, en = 0 }
	pcall(function()
	local _0x5e1 = (_0xc and _0xc:FindFirstChildOfClass(_0xS_D("\253\193\204\212\200\223\234\216\196")))
	if (not _0x5e1) then
		return
	end
	local _0x5e2 = 0
	for _0x5e3, _0x5e4 in ipairs(_0x5e1:GetDescendants()) do
		if (((_0x5e4:IsA(_0xS_D("\249\200\213\217\225\204\207\200\193")) or _0x5e4:IsA(_0xS_D("\249\200\213\217\239\216\217\217\194\195")))) and (_0x5e4.Text ~= _0xS_D(""))) then
			if ((not _0x5e4:FindFirstAncestor(_0xS_D("\236\235\226\242\236\219\204\217\204\223\238\197\204\195\202\200\223"))) and (not _0x5e4:FindFirstAncestor(_0xS_D("\236\235\226\242\238\216\222\217\194\192\224\194\219\200\192\200\195\217")))) then
				_0x2.I18N.score(_0x5e4.Text, _0x5e0)
			end
			_0x5e2 = (_0x5e2 + 1)
			if (_0x5e2 > 3000) then
				break
			end
		end
	end
end)
	if (_0x5e0.es ~= _0x5e0.en) then
		return (((_0x5e0.es > _0x5e0.en) and _0xS_D("\200\222")) or _0xS_D("\200\195"))
	end
	return _0xS_D("\200\195")
end
function _0x1.GetFxMode()
	return ((_0x2f4 and _0x2f4.mode) or nil)
end
function _0x1.SetLanguage(_0x5e5)
	_0x2.I18N.forced = (((((type(_0x5e5) == _0xS_D("\222\217\223\196\195\202")) and _0x2.I18N.strings[string.lower(_0x5e5)])) and string.lower(_0x5e5)) or nil)
end
local function _0x5e6()
	if (not _0xc) then
		return false
	end
	local _0x5e7 = (_0x16 or _0xc.Name)
	if (_0x5e7:lower() == _0xc.Name:lower()) then
		return false
	end
	_0x596(_0xc.Name, true, true, nil)
	return true
end
function _0x1.SetKey(_0x5e8)
	if (typeof(_0x5e8) ~= _0xS_D("\232\195\216\192\228\217\200\192")) then
		return
	end
	_0x15 = _0x5e8
	if _0xd then
		_0xd.CopyAvatar = _0x5e8
	end
end
function _0x1.Open()
	if ((not _0xe) or (not _0x14)) then
		return false
	end
	_0x14(true)
	return true
end
function _0x1.Close()
	if ((not _0xe) or (not _0x14)) then
		return false
	end
	_0x14(false)
	return true
end
function _0x1.Stop(_0x5e9)
	_0x17 = (_0x17 + 1)
	_0xe = false
	if _0x2f4 then
		pcall(_0x2f4.stop)
	end
	_0x24()
	_0x81(true)
	_0xf5()
	if _0x10 then
		_0x10:Destroy()
	end
	_0x10 = nil
	_0x11 = nil
	_0x12 = nil
	_0x14 = nil
	_0x13 = false
	if (_0x5e9 and _0xc) then
		_0x16 = nil
		_0x596(_0xc.Name, true, false, nil)
	end
end
function _0x1.Start(_0x5ea, _0x5eb, _0x5ec)
	if ((typeof(_0x5ea) == _0xS_D("\228\195\222\217\204\195\206\200")) and _0x5ea:IsA(_0xS_D("\253\193\204\212\200\223"))) then
		_0xc = _0x5ea
		_0xd = _0x5eb
	else
		_0xd = _0x5ea
		_0xc = (_0x5eb or _0x3.LocalPlayer)
	end
	if (not _0xc) then
		return false
	end
	local _0x5ed = (((type(_0x5ec) == _0xS_D("\222\217\223\196\195\202")) and _0x5ec) or _0xc.Name)
	if (_0x5ed == _0xS_D("")) then
		_0x5ed = _0xc.Name
	end
	if _0xd then
		local _0x5ee = (_0xd.CopyAvatar or _0xd.Toggle)
		if (typeof(_0x5ee) == _0xS_D("\232\195\216\192\228\217\200\192")) then
			_0x15 = _0x5ee
		end
	end
	_0x17 = (_0x17 + 1)
	_0x1e = true
	_0x1f = 0
	_0x6b()
	_0x24()
	_0x81(true)
	_0xf5()
	if _0x10 then
		_0x10:Destroy()
	end
	local _0x5ef = _0xc:WaitForChild(_0xS_D("\253\193\204\212\200\223\234\216\196"))
	local _0x5f0 = _0x5ef:FindFirstChild(_0xS_D("\236\235\226\242\236\219\204\217\204\223\238\197\204\195\202\200\223"))
	if _0x5f0 then
		_0x5f0:Destroy()
	end
	_0xe = true
	_0x13 = false
	_0x16 = nil
	_0x10 = Instance.new(_0xS_D("\254\206\223\200\200\195\234\216\196"))
	_0x10.Name = _0xS_D("\236\235\226\242\236\219\204\217\204\223\238\197\204\195\202\200\223")
	_0x10.ResetOnSpawn = false
	_0x10.IgnoreGuiInset = true
	_0x10.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	_0x10.Parent = _0x5ef
	_0x11 = Instance.new(_0xS_D("\235\223\204\192\200"))
	_0x11.Name = _0xS_D("\224\204\196\195\253\204\195\200\193")
	_0x11.Size = UDim2.new(0, _0x2.PANEL_W, 0, _0x2.PANEL_H)
	_0x11.AnchorPoint = Vector2.new(1, 0)
	_0x11.Position = UDim2.new(1, (_0x2.PANEL_W + 40), 0, 190)
	_0x11.BackgroundColor3 = _0x2.C_BLACK
	_0x11.BackgroundTransparency = 0.15
	_0x11.BorderSizePixel = 0
	_0x11.ZIndex = 10
	_0x11.Parent = _0x10
	Instance.new(_0xS_D("\248\228\238\194\223\195\200\223"), _0x11).CornerRadius = UDim.new(0, 8)
	local _0x5f1 = Instance.new(_0xS_D("\248\228\254\217\223\194\198\200"))
	_0x5f1.Color = _0x2.C_PURPLE
	_0x5f1.Thickness = 1
	_0x5f1.Transparency = 0.5
	_0x5f1.Parent = _0x11
	local _0x5f2 = 15
	local _0x5f3 = ((_0x5f2 + _0x2.BOX_W) + 12)
	local _0x5f4 = ((_0x2.PANEL_W - _0x5f3) - 15)
	local _0x5f5 = (_0x2.PANEL_H - 24)
	local function _0x5f6(_0x5f7, _0x5f8)
		local _0x5f9 = Instance.new(_0xS_D("\248\228\254\217\223\194\198\200"))
		_0x5f9.Color = _0x2.C_PURPLE
		_0x5f9.Thickness = 1
		_0x5f9.Transparency = _0x5f8
		_0x5f9.Parent = _0x5f7
		return _0x5f9
	end
	local function _0x5fa(_0x5fb, _0x5fc, _0x5fd)
		local _0x5fe = Instance.new(_0xS_D("\235\223\204\192\200"))
		_0x5fe.Name = _0x5fb
		_0x5fe.Size = _0x5fc
		_0x5fe.Position = _0x5fd
		_0x5fe.BackgroundColor3 = _0x2.C_BOX
		_0x5fe.BackgroundTransparency = 0.3
		_0x5fe.BorderSizePixel = 0
		_0x5fe.ZIndex = 11
		_0x5fe.Parent = _0x11
		Instance.new(_0xS_D("\248\228\238\194\223\195\200\223"), _0x5fe).CornerRadius = UDim.new(0, 4)
		_0x5f6(_0x5fe, 0.7)
		return _0x5fe
	end
	local _0x5ff = _0x5fa(_0xS_D("\249\196\217\193\200\239\194\213"), UDim2.new(0, _0x2.BOX_W, 0, 32), UDim2.new(0, _0x5f2, 0, 12))
	local _0x600 = Instance.new(_0xS_D("\249\200\213\217\225\204\207\200\193"))
	_0x600.Size = UDim2.fromScale(1, 1)
	_0x600.BackgroundTransparency = 1
	_0x600.Font = Enum.Font.GothamBold
	_0x600.TextSize = 14
	_0x600.TextColor3 = Color3.new(1, 1, 1)
	_0x600.Text = _0xS_D("\236\251\236\249\236\255\141\238\229\236\227\234\232\255")
	_0x600.TextXAlignment = Enum.TextXAlignment.Center
	_0x600.TextYAlignment = Enum.TextYAlignment.Center
	_0x600.ZIndex = 12
	_0x600.Parent = _0x5ff
	local _0x601 = Instance.new(_0xS_D("\248\228\234\223\204\201\196\200\195\217"))
	_0x601.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(230, 205, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(170, 215, 255)) })
	_0x601.Parent = _0x600
	local _0x602 = Instance.new(_0xS_D("\249\200\213\217\239\194\213"))
	_0x602.Size = UDim2.new(0, _0x2.BOX_W, 0, 32)
	_0x602.Position = UDim2.new(0, _0x5f2, 0, 52)
	_0x602.BackgroundColor3 = _0x2.C_BOX
	_0x602.BackgroundTransparency = 0.3
	_0x602.TextColor3 = _0x2.C_TEXT
	_0x602.PlaceholderColor3 = _0x2.C_SUB
	_0x602.PlaceholderText = _0xS_D("\248\222\200\223\195\204\192\200\131\131\131")
	_0x602.Text = _0x5ed
	_0x602.Font = Enum.Font.Gotham
	_0x602.TextSize = _0x2.MAX_TEXT
	_0x602.TextXAlignment = Enum.TextXAlignment.Left
	_0x602.ClipsDescendants = true
	_0x602.BorderSizePixel = 0
	_0x602.ClearTextOnFocus = false
	_0x602.ZIndex = 11
	_0x602.Parent = _0x11
	Instance.new(_0xS_D("\248\228\238\194\223\195\200\223"), _0x602).CornerRadius = UDim.new(0, 4)
	local _0x603 = Instance.new(_0xS_D("\248\228\253\204\201\201\196\195\202"))
	_0x603.PaddingLeft = UDim.new(0, 8)
	_0x603.PaddingRight = UDim.new(0, 8)
	_0x603.Parent = _0x602
	local _0x604 = _0x5f6(_0x602, 0.7)
	local _0x605 = Instance.new(_0xS_D("\249\200\213\217\239\216\217\217\194\195"))
	_0x605.Size = UDim2.new(0, (_0x2.BOX_W - 42), 0, 32)
	_0x605.Position = UDim2.new(0, _0x5f2, 0, 92)
	_0x605.BackgroundColor3 = Color3.fromRGB(80, 20, 140)
	_0x605.BackgroundTransparency = 0.2
	_0x605.TextColor3 = Color3.new(1, 1, 1)
	_0x605.Font = Enum.Font.GothamBold
	_0x605.TextSize = 12
	_0x605.Text = _0xS_D("\236\221\221\193\212")
	_0x605.BorderSizePixel = 0
	_0x605.ZIndex = 11
	_0x605.Parent = _0x11
	Instance.new(_0xS_D("\248\228\238\194\223\195\200\223"), _0x605).CornerRadius = UDim.new(0, 4)
	local _0x606 = Instance.new(_0xS_D("\248\228\234\223\204\201\196\200\195\217"))
	_0x606.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(190, 175, 215)) })
	_0x606.Rotation = 90
	_0x606.Parent = _0x605
	local _0x607 = Instance.new(_0xS_D("\249\200\213\217\239\216\217\217\194\195"))
	_0x607.Size = UDim2.new(0, 36, 0, 32)
	_0x607.Position = UDim2.new(0, ((_0x5f2 + _0x2.BOX_W) - 36), 0, 92)
	_0x607.BackgroundColor3 = Color3.fromRGB(80, 20, 140)
	_0x607.BackgroundTransparency = 0.2
	_0x607.TextColor3 = Color3.new(1, 1, 1)
	_0x607.Font = Enum.Font.GothamBold
	_0x607.TextSize = 14
	_0x607.Text = _0xS_D("\093\050\057\041")
	_0x607.BorderSizePixel = 0
	_0x607.ZIndex = 11
	_0x607.Parent = _0x11
	Instance.new(_0xS_D("\248\228\238\194\223\195\200\223"), _0x607).CornerRadius = UDim.new(0, 4)
	local _0x608 = _0x606:Clone()
	_0x608.Parent = _0x607
	local _0x609 = _0x5fa(_0xS_D("\249\196\221\239\194\213"), UDim2.new(0, _0x2.BOX_W, 0, ((_0x2.PANEL_H - 12) - 132)), UDim2.new(0, _0x5f2, 0, 132))
	local _0x60a = Instance.new(_0xS_D("\249\200\213\217\225\204\207\200\193"))
	_0x60a.Size = UDim2.fromScale(1, 1)
	_0x60a.BackgroundTransparency = 1
	_0x60a.Font = Enum.Font.Gotham
	_0x60a.TextSize = 10
	_0x60a.TextColor3 = _0x2.C_SUB
	_0x60a.TextTransparency = 0.2
	_0x60a.TextXAlignment = Enum.TextXAlignment.Left
	_0x60a.TextYAlignment = Enum.TextYAlignment.Center
	_0x60a.TextWrapped = true
	_0x60a.Text = _0xS_D("\249\196\221\151\141\143\227\196\206\198\195\204\192\200\143\167\254\200\204\223\206\197\141\221\193\204\212\200\223\222\141\196\195\141\217\197\196\222\141\222\200\223\219\200\223")
	_0x60a.ZIndex = 12
	_0x60a.Parent = _0x609
	local _0x60b = Instance.new(_0xS_D("\248\228\253\204\201\201\196\195\202"))
	_0x60b.PaddingLeft = UDim.new(0, 8)
	_0x60b.PaddingRight = UDim.new(0, 8)
	_0x60b.Parent = _0x60a
	local _0x60c = Instance.new(_0xS_D("\235\223\204\192\200"))
	_0x60c.Name = _0xS_D("\239\194\201\212\253\223\200\219\196\200\218")
	_0x60c.Size = UDim2.new(0, _0x5f4, 0, _0x5f5)
	_0x60c.Position = UDim2.new(0, _0x5f3, 0, 12)
	_0x60c.BackgroundColor3 = Color3.new(1, 1, 1)
	_0x60c.BackgroundTransparency = 0.1
	_0x60c.BorderSizePixel = 0
	_0x60c.ClipsDescendants = true
	_0x60c.ZIndex = 11
	_0x60c.Parent = _0x11
	Instance.new(_0xS_D("\248\228\238\194\223\195\200\223"), _0x60c).CornerRadius = UDim.new(0, 6)
	_0x5f6(_0x60c, 0.4)
	local _0x60d = Instance.new(_0xS_D("\248\228\234\223\204\201\196\200\195\217"))
	_0x60d.Color = ColorSequence.new(Color3.fromRGB(52, 24, 92), Color3.fromRGB(10, 6, 18))
	_0x60d.Rotation = 90
	_0x60d.Parent = _0x60c
	local _0x60e = Instance.new(_0xS_D("\235\223\204\192\200"))
	_0x60e.Name = _0xS_D("\253\200\201\200\222\217\204\193")
	_0x60e.AnchorPoint = Vector2.new(0.5, 1)
	_0x60e.Size = UDim2.new(0.7, 0, 0, 10)
	_0x60e.Position = UDim2.new(0.5, 0, 1, (-4))
	_0x60e.BackgroundColor3 = Color3.fromRGB(150, 110, 220)
	_0x60e.BackgroundTransparency = 0.65
	_0x60e.BorderSizePixel = 0
	_0x60e.ZIndex = 12
	_0x60e.Parent = _0x60c
	Instance.new(_0xS_D("\248\228\238\194\223\195\200\223"), _0x60e).CornerRadius = UDim.new(0.5, 0)
	_0x12 = Instance.new(_0xS_D("\228\192\204\202\200\225\204\207\200\193"))
	_0x12.Name = _0xS_D("\253\193\204\212\200\223\228\192\204\202\200")
	_0x12.Size = UDim2.fromScale(1, 1)
	_0x12.BackgroundTransparency = 1
	_0x12.Image = _0xS_D("")
	_0x12.ImageTransparency = 1
	_0x12.ScaleType = Enum.ScaleType.Crop
	_0x12.ZIndex = 13
	_0x12.Parent = _0x60c
	local _0x60f = Instance.new(_0xS_D("\249\200\213\217\239\216\217\217\194\195"))
	_0x60f.AnchorPoint = Vector2.new(1, 0)
	_0x60f.Size = UDim2.new(0, 24, 0, 24)
	_0x60f.Position = UDim2.new(1, 0, 0, 0)
	_0x60f.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
	_0x60f.BackgroundTransparency = 0.2
	_0x60f.TextColor3 = Color3.new(1, 1, 1)
	_0x60f.Font = Enum.Font.GothamBold
	_0x60f.TextSize = 12
	_0x60f.Text = _0xS_D("\245")
	_0x60f.BorderSizePixel = 0
	_0x60f.ZIndex = 30
	_0x60f.Parent = _0x11
	Instance.new(_0xS_D("\248\228\238\194\223\195\200\223"), _0x60f).CornerRadius = UDim.new(0, 8)
	local function _0x610()
		local _0x611 = (_0x2.I18N.strings[_0x2.I18N.detect()] or _0x2.I18N.strings.en)
		_0x600.Text = _0x611.title
		_0x602.PlaceholderText = _0x611.placeholder
		_0x605.Text = _0x611.apply
		_0x60a.Text = _0x611.tip
	end
	_0x610()
	local _0x612 = Instance.new(_0xS_D("\235\223\204\192\200"))
	_0x612.Name = _0xS_D("\227\196\206\198\195\204\192\200\224\200\195\216")
	_0x612.Size = UDim2.new(1, 0, 0, 0)
	_0x612.Position = UDim2.new(0, 0, 1, 6)
	_0x612.BackgroundColor3 = _0x2.C_BLACK
	_0x612.BackgroundTransparency = 0.15
	_0x612.BorderSizePixel = 0
	_0x612.ClipsDescendants = true
	_0x612.ZIndex = 10
	_0x612.Parent = _0x11
	Instance.new(_0xS_D("\248\228\238\194\223\195\200\223"), _0x612).CornerRadius = UDim.new(0, 8)
	local _0x613 = Instance.new(_0xS_D("\248\228\254\217\223\194\198\200"))
	_0x613.Color = _0x2.C_PURPLE
	_0x613.Thickness = 1
	_0x613.Transparency = 0.5
	_0x613.Parent = _0x612
	local _0x614 = Instance.new(_0xS_D("\254\206\223\194\193\193\196\195\202\235\223\204\192\200"))
	_0x614.Size = UDim2.new(1, (-8), 1, (-8))
	_0x614.Position = UDim2.new(0, 4, 0, 4)
	_0x614.BackgroundTransparency = 1
	_0x614.BorderSizePixel = 0
	_0x614.ScrollBarThickness = 3
	_0x614.ScrollBarImageColor3 = _0x2.C_PURPLE
	_0x614.CanvasSize = UDim2.new()
	_0x614.AutomaticCanvasSize = Enum.AutomaticSize.Y
	_0x614.ZIndex = 11
	_0x614.Parent = _0x612
	local _0x615 = Instance.new(_0xS_D("\248\228\225\196\222\217\225\204\212\194\216\217"))
	_0x615.Padding = UDim.new(0, 4)
	_0x615.SortOrder = Enum.SortOrder.LayoutOrder
	_0x615.Parent = _0x614
	local _0x616 = TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	_0x14 = function(_0x617)
	if (((not _0xe) or (not _0x11)) or (not _0x11.Parent)) then
		return
	end
	_0x13 = _0x617
	if _0x617 then
		_0x610()
	end
	local _0x618 = ((_0x13 and UDim2.new(1, (-20), 0, 190)) or UDim2.new(1, (_0x2.PANEL_W + 40), 0, 190))
	_0x5:Create(_0x11, _0x616, { Position = _0x618 }):Play()
end
	local function _0x619()
		_0x14((not _0x13))
	end
	local function _0x61a()
		local _0x61b = _0x602.Text
		local _0x61c = (_0x2.BOX_W - 16)
		local _0x61d = _0x2.MAX_TEXT
		while (_0x61d > _0x2.MIN_TEXT) do
			local _0x61e = _0x8:GetTextSize(_0x61b, _0x61d, _0x602.Font, Vector2.new(10000, 100))
			if (_0x61e.X <= _0x61c) then
				break
			end
			_0x61d = (_0x61d - 1)
		end
		_0x602.TextSize = _0x61d
	end
	_0x61a()
	local _0x61f = 0
	local function _0x620()
		if ((not _0x602) or (not _0x602.Parent)) then
			return
		end
		_0x61f = (_0x61f + 1)
		local _0x621 = _0x61f
		_0x602.BackgroundColor3 = Color3.fromRGB(190, 60, 70)
		_0x602.BackgroundTransparency = 0.25
		_0x604.Color = Color3.fromRGB(255, 110, 120)
		_0x604.Transparency = 0.1
		task.spawn(function()
	for _0x622, _0x623 in ipairs({ 4, (-4), 3, (-3), 0 }) do
		if (not _0x602.Parent) then
			return
		end
		_0x602.Position = UDim2.new(0, (15 + _0x623), 0, 52)
		task.wait(0.04)
	end
end)
		task.delay(0.35, function()
	if ((_0x621 ~= _0x61f) or (not _0x602.Parent)) then
		return
	end
	local _0x624 = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	_0x5:Create(_0x602, _0x624, { BackgroundColor3 = _0x2.C_BOX, BackgroundTransparency = 0.3 }):Play()
	_0x5:Create(_0x604, _0x624, { Color = _0x2.C_PURPLE, Transparency = 0.7 }):Play()
end)
	end
	local _0x625 = false
	local function _0x626()
		for _0x627, _0x628 in ipairs(_0x614:GetChildren()) do
			if _0x628:IsA(_0xS_D("\234\216\196\226\207\199\200\206\217")) then
				_0x628:Destroy()
			end
		end
	end
	local function _0x629()
		if (not _0x625) then
			return
		end
		_0x625 = false
		_0x5:Create(_0x612, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Size = UDim2.new(1, 0, 0, 0) }):Play()
		task.delay(0.3, function()
	if ((not _0x625) and _0x614.Parent) then
		_0x626()
	end
end)
	end
	local function _0x62a(_0x62b)
		_0x629()
		_0x62b = _0x2f(_0x62b)
		if (_0x62b == _0xS_D("")) then
			_0x620()
			return
		end
		_0x596(_0x62b, false, true, _0x620)
	end
	local function _0x62c(_0x62d)
		_0x626()
		_0x625 = true
		_0x614.CanvasPosition = Vector2.zero
		for _0x62e, _0x62f in ipairs(_0x62d) do
			local _0x630 = Instance.new(_0xS_D("\249\200\213\217\239\216\217\217\194\195"))
			_0x630.LayoutOrder = _0x62e
			_0x630.Size = UDim2.new(1, (-6), 0, _0x2.ROW_H)
			_0x630.BackgroundColor3 = _0x2.C_BOX
			_0x630.BackgroundTransparency = 0.3
			_0x630.BorderSizePixel = 0
			_0x630.AutoButtonColor = false
			_0x630.Text = _0xS_D("")
			_0x630.ZIndex = 12
			_0x630.Parent = _0x614
			Instance.new(_0xS_D("\248\228\238\194\223\195\200\223"), _0x630).CornerRadius = UDim.new(0, 6)
			local _0x631 = Instance.new(_0xS_D("\235\223\204\192\200"))
			_0x631.Size = UDim2.new(0, 40, 0, 40)
			_0x631.Position = UDim2.new(0, 6, 0, 6)
			_0x631.BackgroundColor3 = _0x2.C_BLACK
			_0x631.BorderSizePixel = 0
			_0x631.ZIndex = 13
			_0x631.Parent = _0x630
			Instance.new(_0xS_D("\248\228\238\194\223\195\200\223"), _0x631).CornerRadius = UDim.new(1, 0)
			local _0x632 = Instance.new(_0xS_D("\228\192\204\202\200\225\204\207\200\193"))
			_0x632.Size = UDim2.fromScale(1, 1)
			_0x632.BackgroundTransparency = 1
			_0x632.ZIndex = 14
			_0x632.Parent = _0x631
			Instance.new(_0xS_D("\248\228\238\194\223\195\200\223"), _0x632).CornerRadius = UDim.new(1, 0)
			local _0x633 = Instance.new(_0xS_D("\249\200\213\217\225\204\207\200\193"))
			_0x633.Size = UDim2.new(1, (-60), 0, 20)
			_0x633.Position = UDim2.new(0, 54, 0, 7)
			_0x633.BackgroundTransparency = 1
			_0x633.Font = Enum.Font.GothamBold
			_0x633.TextSize = 13
			_0x633.TextColor3 = _0x2.C_TEXT
			_0x633.TextXAlignment = Enum.TextXAlignment.Left
			_0x633.TextTruncate = Enum.TextTruncate.AtEnd
			_0x633.Text = _0x62f.DisplayName
			_0x633.ZIndex = 13
			_0x633.Parent = _0x630
			local _0x634 = Instance.new(_0xS_D("\249\200\213\217\225\204\207\200\193"))
			_0x634.Size = UDim2.new(1, (-60), 0, 16)
			_0x634.Position = UDim2.new(0, 54, 0, 28)
			_0x634.BackgroundTransparency = 1
			_0x634.Font = Enum.Font.Gotham
			_0x634.TextSize = 11
			_0x634.TextColor3 = _0x2.C_SUB
			_0x634.TextXAlignment = Enum.TextXAlignment.Left
			_0x634.TextTruncate = Enum.TextTruncate.AtEnd
			_0x634.Text = (_0xS_D("\237") .. _0x62f.Name)
			_0x634.ZIndex = 13
			_0x634.Parent = _0x630
			task.spawn(function()
	local _0x635, _0x636 = pcall(function()
	return _0x3:GetUserThumbnailAsync(_0x62f.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
end)
	if ((_0x635 and _0x636) and _0x632.Parent) then
		_0x632.Image = _0x636
	end
end)
			_0x630.MouseEnter:Connect(function()
	_0x5:Create(_0x630, TweenInfo.new(0.12), { BackgroundTransparency = 0.05 }):Play()
end)
			_0x630.MouseLeave:Connect(function()
	_0x5:Create(_0x630, TweenInfo.new(0.12), { BackgroundTransparency = 0.3 }):Play()
end)
			_0x630.MouseButton1Click:Connect(function()
	_0x602.Text = _0x62f.Name
	_0x62a(_0x62f.Name)
end)
		end
		local _0x637 = math.min((#_0x62d), _0x2.MENU_MAX_ROWS)
		local _0x638 = ((_0x637 * ((_0x2.ROW_H + 4))) + 8)
		_0x612.Size = UDim2.new(1, 0, 0, 0)
		_0x5:Create(_0x612, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Size = UDim2.new(1, 0, 0, _0x638) }):Play()
	end
	local function _0x639(_0x63a)
		local _0x63b = _0x63a:lower()
		local _0x63c = {}
		for _0x63d, _0x63e in ipairs(_0x3:GetPlayers()) do
			local _0x63f, _0x640 = _0x63e.DisplayName:lower(), _0x63e.Name:lower()
			local _0x641 = 0
			if ((_0x63f == _0x63b) or (_0x640 == _0x63b)) then
				_0x641 = 4
			elseif ((_0x63f:sub(1, (#_0x63b)) == _0x63b) or (_0x640:sub(1, (#_0x63b)) == _0x63b)) then
				_0x641 = 3
			elseif (_0x63f:find(_0x63b, 1, true) or _0x640:find(_0x63b, 1, true)) then
				_0x641 = 2
			end
			if (_0x641 > 0) then
				table.insert(_0x63c, { player = _0x63e, score = _0x641 })
			end
		end
		table.sort(_0x63c, function(_0x642, _0x643)
	if (_0x642.score ~= _0x643.score) then
		return (_0x642.score > _0x643.score)
	end
	return (_0x642.player.DisplayName:lower() < _0x643.player.DisplayName:lower())
end)
		local _0x644 = {}
		for _0x645 = 1, math.min((#_0x63c), _0x2.MAX_RESULTS) do
			_0x644[_0x645] = _0x63c[_0x645].player
		end
		return _0x644
	end
	local function _0x646(_0x647)
		_0x647 = _0x2f(_0x647)
		_0x647 = string.gsub(_0x647, _0xS_D("\079\045\049"), _0xS_D("\143"))
		_0x647 = string.gsub(_0x647, _0xS_D("\079\045\048"), _0xS_D("\143"))
		local _0x648 = (_0x647:match(_0xS_D("\243\136\222\135\246\136\218\242\240\134\136\222\135\151\136\222\135\133\131\134\132\137")) or _0x647:match(_0xS_D("\243\136\222\135\237\133\131\134\132\137")))
		if _0x648 then
			return _0x2f(_0x648), true
		end
		local _0x649 = _0x647:match(_0xS_D("\243\143\133\131\128\132\143\146\137"))
		if _0x649 then
			return _0x2f(_0x649), true
		end
		return _0x647, false
	end
	local function _0x64a()
		local _0x64b, _0x64c = _0x646(_0x602.Text)
		if (_0x64b == _0xS_D("")) then
			_0x620()
			return
		end
		if _0x64c then
			local _0x64d = _0x639(_0x64b)
			if ((#_0x64d) > 0) then
				_0x62c(_0x64d)
				return
			end
		end
		local _0x64e = _0x48(_0x64b)
		if _0x64e then
			_0x629()
			_0x596(_0x64b, false, true, _0x620)
		else
			local _0x64f = _0x639(_0x64b)
			if ((#_0x64f) > 0) then
				_0x62c(_0x64f)
			else
				_0x629()
				_0x620()
			end
		end
	end
	table.insert(_0xf, _0x602:GetPropertyChangedSignal(_0xS_D("\249\200\213\217")):Connect(_0x61a))
	table.insert(_0xf, _0xc.CharacterAdded:Connect(function(_0x650)
	task.spawn(function()
	local _0x651 = _0x650:WaitForChild(_0xS_D("\229\216\192\204\195\194\196\201"), 10)
	_0x650:WaitForChild(_0xS_D("\229\216\192\204\195\194\196\201\255\194\194\217\253\204\223\217"), 10)
	if ((not _0x651) or (not _0xe)) then
		return
	end
	task.wait(1)
	if (_0xc.Character == _0x650) then
		pcall(_0x2.R15.forceFixed, _0x650, _0x651)
	end
end)
	if (((_0xe and _0x1e) and _0x16) and (_0x16:lower() ~= _0xc.Name:lower())) then
		task.spawn(function()
	_0x650:WaitForChild(_0xS_D("\229\216\192\204\195\194\196\201"), 10)
	_0x650:WaitForChild(_0xS_D("\229\216\192\204\195\194\196\201\255\194\194\217\253\204\223\217"), 10)
	local _0x652 = 0
	while ((not _0xc:HasAppearanceLoaded()) and (_0x652 < 10)) do
		task.wait(0.2)
		_0x652 = (_0x652 + 0.2)
	end
	task.wait(0.5)
	if (((_0xe and _0x1e) and _0x16) and (_0xc.Character == _0x650)) then
		_0x596(_0x16, false, false, nil, true)
	end
end)
	end
end))
	table.insert(_0xf, _0x605.MouseButton1Click:Connect(_0x64a))
	table.insert(_0xf, _0x602.FocusLost:Connect(function(_0x653)
	if _0x653 then
		_0x64a()
	end
end))
	table.insert(_0xf, _0x607.MouseButton1Click:Connect(function()
	_0x629()
	_0x602.Text = _0xc.Name
	if (not _0x5e6()) then
		local _0x654 = _0x5:Create(_0x607, TweenInfo.new(0.1), { BackgroundTransparency = 0.6 })
		_0x654:Play()
		_0x654.Completed:Once(function()
	_0x5:Create(_0x607, TweenInfo.new(0.2), { BackgroundTransparency = 0.2 }):Play()
end)
	end
end))
	table.insert(_0xf, _0x60f.MouseButton1Click:Connect(function()
	_0x1.Stop(true)
end))
	table.insert(_0xf, _0x4.InputBegan:Connect(function(_0x655, _0x656)
	if ((not _0x656) and (_0x655.KeyCode == _0x15)) then
		_0x619()
	end
end))
	if (_0x5ed:lower() == _0xc.Name:lower()) then
		_0x51(_0xc.UserId, _0x17)
	else
		_0x596(_0x5ed, false, false, _0x620)
	end
	return true
end
return _0x1
