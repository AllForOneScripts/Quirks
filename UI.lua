--[[
    QuirksUI  —  Custom PC-only UI library (Fluent-style API)
    Repo target: AllForOneScripts/Quirks/UI.lua
    Load with:
        local Fluent = loadstring(game:HttpGet("https://raw.githubusercontent.com/AllForOneScripts/Quirks/main/UI.lua"))()

    Notes:
      - Mouse + keyboard only. No touch/mobile handling anywhere.
      - API mirrors FluentPro naming (CreateWindow, AddTab, AddSection, AddToggle, ...)
        so existing element-creation code written for FluentPro drops in with minimal changes.
      - Single-file, returns the Library table.
]]

local UserInputService = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local Players            = game:GetService("Players")
local RunService         = game:GetService("RunService")
local HttpService        = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

--============================================================
-- ROOT LIBRARY TABLE
--============================================================

local Library = {}
Library.__index = Library

Library.Version        = "1.0.0"
Library.Windows         = {}
Library.Themes          = {}
Library.CurrentTheme    = "Teto"
Library.ThemeTags       = {}   -- list of {Instance, Property, Key} kept alive while UI exists
Library.Options         = {}   -- Flag -> element object (used by SaveManager)
Library.Unloaded        = false
Library.ErrorHandlerFn  = nil
Library.RootGui         = nil

local function protectedCall(fn, ...)
    local ok, err = pcall(fn, ...)
    if not ok and Library.ErrorHandlerFn then
        pcall(Library.ErrorHandlerFn, err, err)
    end
    return ok, err
end

function Library:SetErrorHandler(fn)
    self.ErrorHandlerFn = fn
end

--============================================================
-- SMALL UTILITIES
--============================================================

local function New(class, props, children)
    local inst = Instance.new(class)
    if props then
        for k, v in pairs(props) do
            inst[k] = v
        end
    end
    if children then
        for _, c in ipairs(children) do
            c.Parent = inst
        end
    end
    return inst
end

local function Round(inst, radius)
    return New("UICorner", { CornerRadius = UDim.new(0, radius or 8), Parent = inst })
end

local function Pad(inst, l, t, r, b)
    return New("UIPadding", {
        PaddingLeft = UDim.new(0, l or 0),
        PaddingTop = UDim.new(0, t or l or 0),
        PaddingRight = UDim.new(0, r or l or 0),
        PaddingBottom = UDim.new(0, b or t or l or 0),
        Parent = inst,
    })
end

local function Tween(inst, props, dur, style, dir)
    local info = TweenInfo.new(dur or 0.18, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out)
    local tw = TweenService:Create(inst, info, props)
    tw:Play()
    return tw
end

-- Tags an instance/property pair to a theme color key so it updates on SetTheme
local function Tag(inst, prop, key)
    table.insert(Library.ThemeTags, { Instance = inst, Property = prop, Key = key })
    local theme = Library.Themes[Library.CurrentTheme]
    if theme and theme[key] ~= nil then
        inst[prop] = theme[key]
    end
    return inst
end

--============================================================
-- THEME SYSTEM
--============================================================

-- Minimal but complete color slot set. Any custom theme can override any subset;
-- missing keys fall back to Obsidian's values at registration time.
local BaseThemeKeys = {
    "Accent", "Background", "BackgroundGradientTop", "BackgroundGradientBottom",
    "Border", "TitleBarLine", "Tab", "TabActive", "Element", "ElementBorder",
    "ToggleOff", "ToggleOn", "SliderRail", "SliderFill", "DropdownFrame",
    "DropdownOption", "DropdownBorder", "Input", "InputFocused", "InputIndicator",
    "Dialog", "DialogButton", "DialogBorder", "Text", "SubText", "Hover", "Error",
    "Success", "Warning", "Info",
}

Library.Themes["Obsidian"] = {
    Accent                   = Color3.fromRGB(114, 137, 255),
    Background               = Color3.fromRGB(18, 19, 23),
    BackgroundGradientTop    = Color3.fromRGB(24, 25, 30),
    BackgroundGradientBottom = Color3.fromRGB(14, 15, 18),
    Border                   = Color3.fromRGB(40, 42, 50),
    TitleBarLine             = Color3.fromRGB(40, 42, 50),
    Tab                      = Color3.fromRGB(22, 23, 28),
    TabActive                = Color3.fromRGB(30, 31, 38),
    Element                  = Color3.fromRGB(26, 27, 33),
    ElementBorder            = Color3.fromRGB(42, 44, 52),
    ToggleOff                = Color3.fromRGB(40, 42, 50),
    ToggleOn                 = Color3.fromRGB(114, 137, 255),
    SliderRail                = Color3.fromRGB(40, 42, 50),
    SliderFill                = Color3.fromRGB(114, 137, 255),
    DropdownFrame            = Color3.fromRGB(24, 25, 30),
    DropdownOption           = Color3.fromRGB(28, 29, 35),
    DropdownBorder           = Color3.fromRGB(42, 44, 52),
    Input                    = Color3.fromRGB(24, 25, 30),
    InputFocused             = Color3.fromRGB(20, 21, 26),
    InputIndicator           = Color3.fromRGB(114, 137, 255),
    Dialog                   = Color3.fromRGB(22, 23, 28),
    DialogButton             = Color3.fromRGB(28, 29, 35),
    DialogBorder             = Color3.fromRGB(42, 44, 52),
    Text                     = Color3.fromRGB(235, 236, 240),
    SubText                  = Color3.fromRGB(150, 153, 165),
    Hover                    = Color3.fromRGB(34, 36, 44),
    Error                    = Color3.fromRGB(255, 90, 90),
    Success                  = Color3.fromRGB(90, 220, 140),
    Warning                  = Color3.fromRGB(255, 190, 80),
    Info                     = Color3.fromRGB(114, 170, 255),
}

-- "Teto" — palette inspired by Kasane Teto's signature red/pink hair and eyes.
-- This is the theme your hub currently boots into; registered here so it's the
-- default out of the box. Add more with RegisterCustomTheme and switch the
-- default any time with SetTheme (or InterfaceManager, which persists the choice).
Library.Themes["Teto"] = {
    Accent                   = Color3.fromRGB(255, 66, 112),
    Background               = Color3.fromRGB(20, 14, 17),
    BackgroundGradientTop    = Color3.fromRGB(27, 18, 22),
    BackgroundGradientBottom = Color3.fromRGB(15, 10, 12),
    Border                   = Color3.fromRGB(48, 33, 39),
    TitleBarLine             = Color3.fromRGB(48, 33, 39),
    Tab                      = Color3.fromRGB(25, 17, 20),
    TabActive                = Color3.fromRGB(34, 22, 27),
    Element                  = Color3.fromRGB(29, 19, 23),
    ElementBorder            = Color3.fromRGB(50, 34, 40),
    ToggleOff                = Color3.fromRGB(48, 33, 39),
    ToggleOn                 = Color3.fromRGB(255, 66, 112),
    SliderRail                = Color3.fromRGB(48, 33, 39),
    SliderFill                = Color3.fromRGB(255, 66, 112),
    DropdownFrame            = Color3.fromRGB(25, 17, 20),
    DropdownOption           = Color3.fromRGB(33, 22, 26),
    DropdownBorder           = Color3.fromRGB(50, 34, 40),
    Input                    = Color3.fromRGB(25, 17, 20),
    InputFocused             = Color3.fromRGB(20, 13, 16),
    InputIndicator           = Color3.fromRGB(255, 66, 112),
    Dialog                   = Color3.fromRGB(25, 17, 20),
    DialogButton             = Color3.fromRGB(33, 22, 26),
    DialogBorder             = Color3.fromRGB(50, 34, 40),
    Text                     = Color3.fromRGB(248, 240, 242),
    SubText                  = Color3.fromRGB(180, 152, 160),
    Hover                    = Color3.fromRGB(42, 27, 32),
    Error                    = Color3.fromRGB(255, 90, 90),
    Success                  = Color3.fromRGB(120, 220, 150),
    Warning                  = Color3.fromRGB(255, 190, 90),
    Info                     = Color3.fromRGB(237, 167, 186),
}

function Library:RegisterCustomTheme(name, colors)
    local base = self.Themes["Obsidian"]
    local merged = {}
    for _, key in ipairs(BaseThemeKeys) do
        merged[key] = (colors and colors[key] ~= nil) and colors[key] or base[key]
    end
    -- keep any extra custom keys the caller passed (e.g. future extensions)
    if colors then
        for k, v in pairs(colors) do
            if merged[k] == nil then merged[k] = v end
        end
    end
    self.Themes[name] = merged
    return merged
end

function Library:SetTheme(name)
    local theme = self.Themes[name]
    if not theme then return false end
    self.CurrentTheme = name
    for i = #self.ThemeTags, 1, -1 do
        local tag = self.ThemeTags[i]
        if not tag.Instance or not tag.Instance.Parent then
            table.remove(self.ThemeTags, i)
        else
            local val = theme[tag.Key]
            if val ~= nil then
                tag.Instance[tag.Property] = val
            end
        end
    end
    return true
end

--============================================================
-- DRAG HELPER  (mouse only — no touch)
--============================================================

local function MakeDraggable(handle, target)
    local dragging, dragStart, startPos = false, nil, nil

    handle.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        dragging = true
        dragStart = input.Position
        startPos = target.Position
        local conn
        conn = input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
                conn:Disconnect()
            end
        end)
    end)

    handle.InputChanged:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
        if not dragging then return end
        local delta = input.Position - dragStart
        target.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end)
end

--============================================================
-- ROOT SCREENGUI
--============================================================

local function GetRootGui()
    if Library.RootGui and Library.RootGui.Parent then
        return Library.RootGui
    end
    local gui = New("ScreenGui", {
        Name = "QuirksUI",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 999,
    })
    local ok = pcall(function()
        gui.Parent = gethui and gethui() or game:GetService("CoreGui")
    end)
    if not ok then
        gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
    Library.RootGui = gui
    return gui
end

--============================================================
-- NOTIFY
--============================================================

local NotifyHolder = nil

local function GetNotifyHolder()
    if NotifyHolder and NotifyHolder.Parent then return NotifyHolder end
    NotifyHolder = New("Frame", {
        Name = "Notifications",
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -16, 1, -16),
        Size = UDim2.new(0, 300, 1, -32),
        Parent = GetRootGui(),
    })
    New("UIListLayout", {
        Parent = NotifyHolder,
        VerticalAlignment = Enum.VerticalAlignment.Bottom,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })
    return NotifyHolder
end

local TYPE_KEY = { Info = "Info", Success = "Success", Warning = "Warning", Error = "Error" }

function Library:Notify(opts)
    opts = opts or {}
    local holder = GetNotifyHolder()
    local key = TYPE_KEY[opts.Type] or "Info"

    local card = New("Frame", {
        BackgroundTransparency = 0,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        ClipsDescendants = true,
        Parent = holder,
    })
    Tag(card, "BackgroundColor3", "Element")
    Round(card, 10)
    local stroke = New("UIStroke", { Thickness = 1, Parent = card })
    Tag(stroke, "Color", "ElementBorder")
    local bar = New("Frame", {
        Size = UDim2.new(0, 4, 1, 0),
        BorderSizePixel = 0,
        Parent = card,
    })
    Tag(bar, "BackgroundColor3", key)
    Round(bar, 10)
    Pad(card, 12, 10, 10, 10)

    New("UIListLayout", {
        Parent = card,
        Padding = UDim.new(0, 2),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })

    local title = New("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 18),
        Font = Enum.Font.GothamBold,
        Text = opts.Title or "",
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        RichText = true,
        Parent = card,
    })
    Tag(title, "TextColor3", "Text")

    if opts.Content then
        local content = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Font = Enum.Font.Gotham,
            Text = opts.Content,
            TextSize = 13,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            RichText = true,
            Parent = card,
        })
        Tag(content, "TextColor3", "SubText")
    end

    if opts.SubContent then
        local sub = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Font = Enum.Font.Gotham,
            Text = opts.SubContent,
            TextSize = 11,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            RichText = true,
            Parent = card,
        })
        Tag(sub, "TextColor3", "SubText")
        sub.TextTransparency = 0.25
    end

    card.Size = UDim2.new(1, 0, 0, 0)
    task.delay(opts.Duration or 3, function()
        if card and card.Parent then
            Tween(card, { Size = UDim2.new(1, 0, 0, 0) }, 0.2)
            task.wait(0.2)
            card:Destroy()
        end
    end)

    return card
end

--============================================================
-- WINDOW
--============================================================

local Window = {}
Window.__index = Window

function Library:CreateWindow(opts)
    opts = opts or {}
    local gui = GetRootGui()

    local size = opts.Size or UDim2.fromOffset(560, 420)
    local tabWidth = opts.TabWidth or 150

    local root = New("Frame", {
        Name = "Window",
        Size = size,
        Position = UDim2.new(0.5, -size.X.Offset / 2, 0.5, -size.Y.Offset / 2),
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = gui,
    })
    Tag(root, "BackgroundColor3", "Background")
    Round(root, 12)
    local rootStroke = New("UIStroke", { Thickness = 1, Parent = root })
    Tag(rootStroke, "Color", "Border")

    -- Title bar
    local titleBar = New("Frame", {
        Name = "TitleBar",
        Size = UDim2.new(1, 0, 0, 44),
        BackgroundTransparency = 1,
        Parent = root,
    })
    local titleLine = New("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 1, 0),
        BorderSizePixel = 0,
        Parent = titleBar,
    })
    Tag(titleLine, "BackgroundColor3", "TitleBarLine")

    local titleText = New("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 16, 0, 0),
        Size = UDim2.new(1, -100, 1, 0),
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left,
        RichText = true,
        Text = (opts.Title or "Window") ..
            (opts.SubTitle and ("  <font size=\"12\" transparency=\"0.4\">" .. opts.SubTitle .. "</font>") or ""),
        Parent = titleBar,
    })
    Tag(titleText, "TextColor3", "Text")

    if opts.Version then
        local ver = New("TextLabel", {
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -16, 0.5, 0),
            Size = UDim2.new(0, 100, 0, 20),
            Font = Enum.Font.Gotham,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Right,
            Text = opts.Version,
            Parent = titleBar,
        })
        Tag(ver, "TextColor3", "SubText")
    end

    MakeDraggable(titleBar, root)

    -- Sidebar
    local sidebar = New("Frame", {
        Name = "Sidebar",
        Position = UDim2.new(0, 0, 0, 44),
        Size = UDim2.new(0, tabWidth, 1, -44),
        BackgroundTransparency = 1,
        Parent = root,
    })
    local sidebarLine = New("Frame", {
        Size = UDim2.new(0, 1, 1, 0),
        Position = UDim2.new(1, -1, 0, 0),
        BorderSizePixel = 0,
        Parent = sidebar,
    })
    Tag(sidebarLine, "BackgroundColor3", "Border")

    if opts.UserInfoTop then
        local infoCard = New("Frame", {
            Size = UDim2.new(1, -16, 0, 46),
            Position = UDim2.new(0, 8, 0, 8),
            Parent = sidebar,
        })
        Tag(infoCard, "BackgroundColor3", "Tab")
        Round(infoCard, 8)
        Pad(infoCard, 10, 6, 10, 6)
        local infoTitle = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 16),
            Font = Enum.Font.GothamBold,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = opts.UserInfoTitle or "Welcome",
            Parent = infoCard,
        })
        Tag(infoTitle, "TextColor3", "Text")
        local infoSub = New("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 0, 0, 18),
            Size = UDim2.new(1, 0, 0, 14),
            Font = Enum.Font.Gotham,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = opts.UserInfoSubtitle or "",
            Parent = infoCard,
        })
        infoSub.TextColor3 = opts.UserInfoColor or (Library.Themes[Library.CurrentTheme].SubText)
    end

    local tabList = New("ScrollingFrame", {
        Name = "TabList",
        Position = UDim2.new(0, 6, 0, opts.UserInfoTop and 62 or 8),
        Size = UDim2.new(1, -12, 1, (opts.UserInfoTop and -70 or -16)),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Parent = sidebar,
    })
    New("UIListLayout", {
        Parent = tabList,
        Padding = UDim.new(0, 4),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })

    -- Page container
    local pages = New("Frame", {
        Name = "Pages",
        Position = UDim2.new(0, tabWidth, 0, 44),
        Size = UDim2.new(1, -tabWidth, 1, -44),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        Parent = root,
    })

    local self = setmetatable({
        Root = root,
        TabList = tabList,
        Pages = pages,
        Tabs = {},
        TabOrder = {},
        ActiveTab = nil,
        MinimizeKey = opts.MinimizeKey,
        Visible = true,
    }, Window)

    if opts.MinimizeKey then
        UserInputService.InputBegan:Connect(function(input, processed)
            if processed then return end
            if input.KeyCode == opts.MinimizeKey then
                if self.Visible then self:Hide() else self:Show() end
            end
        end)
    end

    table.insert(Library.Windows, self)
    return self
end

function Window:Show()
    self.Root.Visible = true
    self.Visible = true
end

function Window:Hide()
    self.Root.Visible = false
    self.Visible = false
end

function Window:SelectTab(indexOrTab)
    local tab = type(indexOrTab) == "table" and indexOrTab or self.TabOrder[indexOrTab]
    if not tab then return end
    for _, t in ipairs(self.TabOrder) do
        t.Page.Visible = (t == tab)
        Tween(t.Button, { BackgroundTransparency = (t == tab) and 0 or 1 }, 0.12)
    end
    self.ActiveTab = tab
end

-- Simple confirmation / input dialog
function Window:Dialog(opts)
    opts = opts or {}
    local overlay = New("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 0.45,
        ZIndex = 50,
        Parent = self.Root,
    })

    local card = New("Frame", {
        Size = UDim2.new(0, 300, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        ZIndex = 51,
        Parent = overlay,
    })
    Tag(card, "BackgroundColor3", "Dialog")
    Round(card, 10)
    local stroke = New("UIStroke", { Thickness = 1, Parent = card })
    Tag(stroke, "Color", "DialogBorder")
    Pad(card, 16, 14, 16, 14)
    New("UIListLayout", { Parent = card, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder })

    local title = New("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 18),
        Font = Enum.Font.GothamBold,
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = opts.Title or "",
        Parent = card,
    })
    Tag(title, "TextColor3", "Text")

    if opts.Content then
        local content = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Font = Enum.Font.Gotham,
            TextSize = 13,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = opts.Content,
            Parent = card,
        })
        Tag(content, "TextColor3", "SubText")
    end

    local inputBox = nil
    if opts.Input then
        local box = New("Frame", { Size = UDim2.new(1, 0, 0, 32), Parent = card })
        Tag(box, "BackgroundColor3", "Input")
        Round(box, 6)
        Pad(box, 8)
        inputBox = New("TextBox", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            Font = Enum.Font.Gotham,
            TextSize = 13,
            PlaceholderText = opts.Input.Placeholder or "",
            Text = "",
            ClearTextOnFocus = false,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = box,
        })
        Tag(inputBox, "TextColor3", "Text")
    end

    local btnRow = New("Frame", {
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundTransparency = 1,
        Parent = card,
    })
    New("UIListLayout", {
        Parent = btnRow,
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })

    for _, b in ipairs(opts.Buttons or {}) do
        local btn = New("TextButton", {
            Size = UDim2.new(0, 88, 1, 0),
            Font = Enum.Font.GothamBold,
            TextSize = 13,
            AutoButtonColor = false,
            Text = b.Title or "OK",
            Parent = btnRow,
        })
        Tag(btn, "BackgroundColor3", "DialogButton")
        Tag(btn, "TextColor3", "Text")
        Round(btn, 6)
        local bstroke = New("UIStroke", { Thickness = 1, Parent = btn })
        Tag(bstroke, "Color", "DialogBorder")

        btn.MouseButton1Click:Connect(function()
            overlay:Destroy()
            if b.Callback then
                protectedCall(b.Callback, inputBox and inputBox.Text or nil)
            end
        end)
    end

    return overlay
end

--============================================================
-- ELEMENT CONTAINER (shared Add* methods for Section / CollapsibleSection / Tab)
--============================================================

local Container = {}
Container.__index = Container

local function NewContainer(holder)
    return setmetatable({ Holder = holder, Order = 0 }, Container)
end

local function NextOrder(self)
    self.Order = self.Order + 1
    return self.Order
end

-- Shared card layout used by interactive elements (title/description left, control right)
local function BuildElementBase(holder, order, opts, height)
    local frame = New("Frame", {
        Size = UDim2.new(1, 0, 0, height or 40),
        LayoutOrder = order,
        Parent = holder,
    })
    Tag(frame, "BackgroundColor3", "Element")
    Round(frame, 8)
    local stroke = New("UIStroke", { Thickness = 1, Parent = frame })
    Tag(stroke, "Color", "ElementBorder")
    Pad(frame, 10)

    local textHolder = New("Frame", {
        Size = UDim2.new(1, -130, 1, 0),
        BackgroundTransparency = 1,
        Parent = frame,
    })
    New("UIListLayout", { Parent = textHolder, SortOrder = Enum.SortOrder.LayoutOrder })

    local title = New("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, opts.Description and 16 or 0),
        AutomaticSize = (not opts.Description) and Enum.AutomaticSize.Y or Enum.AutomaticSize.None,
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = opts.Title or "",
        Parent = textHolder,
    })
    Tag(title, "TextColor3", "Text")

    if opts.Description then
        local desc = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 14),
            Font = Enum.Font.Gotham,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = opts.Description,
            Parent = textHolder,
        })
        Tag(desc, "TextColor3", "SubText")
    end

    local right = New("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.new(0, 110, 0, 26),
        BackgroundTransparency = 1,
        Parent = frame,
    })

    return frame, right
end

-- ---- Paragraph ----
function Container:AddParagraph(opts)
    opts = opts or {}
    local frame = New("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        LayoutOrder = NextOrder(self),
        Parent = self.Holder,
    })
    New("UIListLayout", { Parent = frame, Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder })

    if opts.Title then
        local t = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 18),
            Font = Enum.Font.GothamBold,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            RichText = true,
            Text = opts.Title,
            Parent = frame,
        })
        Tag(t, "TextColor3", "Text")
    end
    if opts.Content then
        local c = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Font = Enum.Font.Gotham,
            TextSize = 13,
            TextWrapped = true,
            RichText = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = opts.Content,
            Parent = frame,
        })
        Tag(c, "TextColor3", "SubText")
    end
    return frame
end

-- ---- Divider / Space ----
function Container:AddDivider()
    local line = New("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        BorderSizePixel = 0,
        LayoutOrder = NextOrder(self),
        Parent = self.Holder,
    })
    Tag(line, "BackgroundColor3", "Border")
    return line
end

function Container:AddSpace(opts)
    opts = opts or {}
    return New("Frame", {
        Size = UDim2.new(1, 0, 0, opts.Height or 12),
        BackgroundTransparency = 1,
        LayoutOrder = NextOrder(self),
        Parent = self.Holder,
    })
end

-- ---- Button ----
function Container:AddButton(opts)
    opts = opts or {}
    local frame = BuildElementBase(self.Holder, NextOrder(self), opts, opts.Description and 46 or 38)

    local chevron = New("TextLabel", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.new(0, 16, 0, 16),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        Text = ">",
        Parent = frame,
    })
    Tag(chevron, "TextColor3", "SubText")

    local btn = New("TextButton", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        Parent = frame,
    })
    btn.MouseEnter:Connect(function() Tween(frame, { BackgroundColor3 = Library.Themes[Library.CurrentTheme].Hover }, 0.1) end)
    btn.MouseLeave:Connect(function() Tween(frame, { BackgroundColor3 = Library.Themes[Library.CurrentTheme].Element }, 0.1) end)
    btn.MouseButton1Click:Connect(function()
        if opts.Callback then protectedCall(opts.Callback, btn) end
    end)

    return { Instance = frame }
end

-- ---- Toggle ----
function Container:AddToggle(flag, opts)
    opts = opts or {}
    local frame, right = BuildElementBase(self.Holder, NextOrder(self), opts, opts.Description and 46 or 40)
    local state = opts.Default and true or false

    local switch = New("Frame", { Size = UDim2.new(0, 40, 0, 22), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Parent = right })
    Round(switch, 11)
    local knob = New("Frame", { Size = UDim2.new(0, 18, 0, 18), Position = UDim2.new(0, 2, 0.5, -9), BackgroundColor3 = Color3.new(1, 1, 1), Parent = switch })
    Round(knob, 9)

    local function Render(v, instant)
        local theme = Library.Themes[Library.CurrentTheme]
        local goalColor = v and theme.ToggleOn or theme.ToggleOff
        local goalPos = v and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
        if instant then
            switch.BackgroundColor3 = goalColor
            knob.Position = goalPos
        else
            Tween(switch, { BackgroundColor3 = goalColor }, 0.15)
            Tween(knob, { Position = goalPos }, 0.15)
        end
    end
    Render(state, true)

    local click = New("TextButton", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", Parent = frame })

    local obj = { Value = state, Flag = flag, Type = "Toggle" }
    function obj:SetValue(v)
        state = v and true or false
        self.Value = state
        Render(state)
    end

    click.MouseButton1Click:Connect(function()
        obj:SetValue(not state)
        if opts.Callback then protectedCall(opts.Callback, state) end
    end)

    if flag then Library.Options[flag] = obj end
    return obj
end

-- ---- Checkbox (visually distinct from Toggle, same semantics) ----
function Container:AddCheckbox(flag, opts)
    opts = opts or {}
    local frame, right = BuildElementBase(self.Holder, NextOrder(self), opts, opts.Description and 46 or 40)
    local state = opts.Default and true or false

    local box = New("Frame", { Size = UDim2.new(0, 20, 0, 20), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Parent = right })
    Round(box, 5)
    Tag(box, "BackgroundColor3", "ToggleOff")
    local bstroke = New("UIStroke", { Thickness = 1, Parent = box })
    Tag(bstroke, "Color", "ElementBorder")
    local check = New("TextLabel", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextColor3 = Color3.new(1, 1, 1),
        Text = "v",
        TextTransparency = 1,
        Parent = box,
    })

    local function Render(v, instant)
        local theme = Library.Themes[Library.CurrentTheme]
        local goal = v and theme.ToggleOn or theme.ToggleOff
        if instant then
            box.BackgroundColor3 = goal
            check.TextTransparency = v and 0 or 1
        else
            Tween(box, { BackgroundColor3 = goal }, 0.12)
            Tween(check, { TextTransparency = v and 0 or 1 }, 0.12)
        end
    end
    Render(state, true)

    local click = New("TextButton", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", Parent = frame })

    local obj = { Value = state, Flag = flag, Type = "Checkbox" }
    function obj:SetValue(v)
        state = v and true or false
        self.Value = state
        Render(state)
    end

    click.MouseButton1Click:Connect(function()
        obj:SetValue(not state)
        if opts.Callback then protectedCall(opts.Callback, state) end
    end)

    if flag then Library.Options[flag] = obj end
    return obj
end

-- ---- Slider ----
function Container:AddSlider(flag, opts)
    opts = opts or {}
    local min, max = opts.Min or 0, opts.Max or 100
    local rounding = opts.Rounding or 0
    local value = math.clamp(opts.Default or min, min, max)

    local frame, right = BuildElementBase(self.Holder, NextOrder(self), opts, opts.Description and 52 or 46)

    local rail = New("Frame", {
        Size = UDim2.new(1, 0, 0, 6),
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, 0, 1, -2),
        Parent = right,
    })
    Round(rail, 3)
    Tag(rail, "BackgroundColor3", "SliderRail")

    local fill = New("Frame", { Size = UDim2.new(0, 0, 1, 0), BorderSizePixel = 0, Parent = rail })
    Round(fill, 3)
    Tag(fill, "BackgroundColor3", "SliderFill")

    local valueLabel = New("TextLabel", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, 0, 0, -18),
        Size = UDim2.new(0, 60, 0, 14),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = right,
    })
    Tag(valueLabel, "TextColor3", "SubText")

    local function fmt(v)
        if rounding <= 0 then return tostring(math.floor(v + 0.5)) end
        return string.format("%." .. rounding .. "f", v)
    end

    local function Render(v)
        local alpha = (max > min) and ((v - min) / (max - min)) or 0
        fill.Size = UDim2.new(alpha, 0, 1, 0)
        valueLabel.Text = fmt(v)
    end
    Render(value)

    local dragging = false
    local hit = New("TextButton", { Size = UDim2.new(1, 0, 1, 20), Position = UDim2.new(0,0,0,-14), BackgroundTransparency = 1, Text = "", Parent = right })

    local function SetFromX(x)
        local absPos, absSize = rail.AbsolutePosition.X, rail.AbsoluteSize.X
        local alpha = math.clamp((x - absPos) / math.max(absSize, 1), 0, 1)
        local raw = min + (max - min) * alpha
        if rounding <= 0 then
            raw = math.floor(raw + 0.5)
        else
            local mult = 10 ^ rounding
            raw = math.floor(raw * mult + 0.5) / mult
        end
        raw = math.clamp(raw, min, max)
        value = raw
        Render(value)
        return raw
    end

    hit.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        dragging = true
        local v = SetFromX(input.Position.X)
        if opts.Callback then protectedCall(opts.Callback, v) end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
        local v = SetFromX(input.Position.X)
        if opts.Callback then protectedCall(opts.Callback, v) end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)

    local obj = { Value = value, Flag = flag, Type = "Slider" }
    function obj:SetValue(v)
        value = math.clamp(v, min, max)
        self.Value = value
        Render(value)
    end
    if flag then Library.Options[flag] = obj end
    return obj
end

-- ---- Progress Bar (not fed by user input, controlled via :SetValue) ----
function Container:AddProgressBar(flag, opts)
    opts = opts or {}
    local min, max = opts.Min or 0, opts.Max or 100
    local value = math.clamp(opts.Default or min, min, max)

    local frame, right = BuildElementBase(self.Holder, NextOrder(self), opts, 40)
    right.Size = UDim2.new(0, 110, 0, 8)

    local rail = New("Frame", { Size = UDim2.new(1, 0, 1, 0), Parent = right })
    Round(rail, 4)
    Tag(rail, "BackgroundColor3", "SliderRail")
    local fill = New("Frame", { Size = UDim2.new(0, 0, 1, 0), BorderSizePixel = 0, Parent = rail })
    Round(fill, 4)
    Tag(fill, "BackgroundColor3", "SliderFill")

    local function Render(v)
        local alpha = (max > min) and ((v - min) / (max - min)) or 0
        Tween(fill, { Size = UDim2.new(alpha, 0, 1, 0) }, 0.15)
    end
    Render(value)

    local obj = { Value = value, Min = min, Max = max, Flag = flag, Type = "ProgressBar" }
    function obj:SetValue(v)
        value = math.clamp(v, min, max)
        self.Value = value
        Render(value)
    end
    if flag then Library.Options[flag] = obj end
    return obj
end

-- ---- Input ----
function Container:AddInput(flag, opts)
    opts = opts or {}
    local frame, right = BuildElementBase(self.Holder, NextOrder(self), opts, opts.Description and 46 or 40)
    right.Size = UDim2.new(0, 130, 0, 28)

    local box = New("Frame", { Size = UDim2.new(1, 0, 1, 0), Parent = right })
    Tag(box, "BackgroundColor3", "Input")
    Round(box, 6)
    local bstroke = New("UIStroke", { Thickness = 1, Parent = box })
    Tag(bstroke, "Color", "ElementBorder")
    Pad(box, 8, 0, 8, 0)

    local textbox = New("TextBox", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        ClearTextOnFocus = false,
        Text = opts.Default or "",
        PlaceholderText = opts.Placeholder or "",
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = box,
    })
    Tag(textbox, "TextColor3", "Text")

    textbox.Focused:Connect(function()
        Tag(box, "BackgroundColor3", "InputFocused")
    end)
    textbox.FocusLost:Connect(function(enterPressed)
        Tag(box, "BackgroundColor3", "Input")
        if opts.Callback then protectedCall(opts.Callback, textbox.Text) end
    end)

    local obj = { Value = textbox.Text, Flag = flag, Type = "Input" }
    function obj:SetValue(v)
        textbox.Text = v
        self.Value = v
    end
    if flag then Library.Options[flag] = obj end
    return obj
end

-- ---- Keybind (Toggle / Always, keyboard + mouse buttons only) ----
function Container:AddKeybind(flag, opts)
    opts = opts or {}
    local mode = opts.Mode or "Toggle"
    local currentKey = opts.Default or "None"
    local listening = false
    local toggledState = false

    local frame, right = BuildElementBase(self.Holder, NextOrder(self), opts, opts.Description and 46 or 40)
    right.Size = UDim2.new(0, 90, 0, 26)

    local keyBtn = New("TextButton", {
        Size = UDim2.new(1, 0, 1, 0),
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        AutoButtonColor = false,
        Text = currentKey,
        Parent = right,
    })
    Tag(keyBtn, "BackgroundColor3", "Input")
    Tag(keyBtn, "TextColor3", "Text")
    Round(keyBtn, 6)
    local kstroke = New("UIStroke", { Thickness = 1, Parent = keyBtn })
    Tag(kstroke, "Color", "ElementBorder")

    keyBtn.MouseButton1Click:Connect(function()
        listening = true
        keyBtn.Text = "..."
    end)

    UserInputService.InputBegan:Connect(function(input, processed)
        if listening then
            if input.UserInputType == Enum.UserInputType.Keyboard then
                currentKey = input.KeyCode.Name
                keyBtn.Text = currentKey
                listening = false
            elseif input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.MouseButton2
                or input.UserInputType == Enum.UserInputType.MouseButton3 then
                currentKey = input.UserInputType.Name
                keyBtn.Text = currentKey
                listening = false
            end
            return
        end

        if processed then return end
        local matches = (input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode.Name == currentKey)
            or (input.UserInputType.Name == currentKey)
        if not matches then return end

        if mode == "Always" then
            if opts.Callback then protectedCall(opts.Callback) end
        else
            toggledState = not toggledState
            if opts.Callback then protectedCall(opts.Callback, toggledState) end
        end
    end)

    local obj = { Value = currentKey, Flag = flag, Type = "Keybind" }
    function obj:SetValue(v)
        currentKey = v
        keyBtn.Text = v
        self.Value = v
    end
    if flag then Library.Options[flag] = obj end
    return obj
end

-- ---- Dropdown ----
function Container:AddDropdown(flag, opts)
    opts = opts or {}
    local values = opts.Values or {}
    local multi = opts.Multi or false
    local selected = {} -- set of chosen strings

    if multi then
        if type(opts.Default) == "table" then
            for k, v in pairs(opts.Default) do if v then selected[k] = true end end
        end
    else
        if type(opts.Default) == "string" then selected[opts.Default] = true end
    end

    local frame, right = BuildElementBase(self.Holder, NextOrder(self), opts, opts.Description and 46 or 40)
    right.Size = UDim2.new(0, 130, 0, 26)

    local head = New("TextButton", {
        Size = UDim2.new(1, 0, 1, 0),
        AutoButtonColor = false,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        Text = "",
        Parent = right,
    })
    Tag(head, "BackgroundColor3", "DropdownFrame")
    Round(head, 6)
    local hstroke = New("UIStroke", { Thickness = 1, Parent = head })
    Tag(hstroke, "Color", opts.Animated and "Accent" or "DropdownBorder")

    if opts.Animated then
        task.spawn(function()
            local hue = 0
            while head.Parent do
                hue = (hue + 0.15) % 1
                hstroke.Color = Color3.fromHSV(hue, 0.65, 1)
                task.wait(0.05)
            end
        end)
    end

    local label = New("TextLabel", {
        Size = UDim2.new(1, -22, 1, 0),
        Position = UDim2.new(0, 8, 0, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = head,
    })
    Tag(label, "TextColor3", "Text")

    local arrow = New("TextLabel", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -6, 0.5, 0),
        Size = UDim2.new(0, 14, 0, 14),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        Text = "v",
        Parent = head,
    })
    Tag(arrow, "TextColor3", "SubText")

    local function summary()
        local list = {}
        for _, v in ipairs(values) do if selected[v] then table.insert(list, v) end end
        return (#list > 0) and table.concat(list, ", ") or "Select..."
    end
    label.Text = summary()

    local panel, panelStroke
    local open = false
    local obj = { Value = multi and selected or next(selected), Flag = flag, Type = "Dropdown" }

    local function fireCallback()
        if not opts.Callback then return end
        if multi then
            protectedCall(opts.Callback, selected)
        else
            local pick
            for _, v in ipairs(values) do if selected[v] then pick = v break end end
            protectedCall(opts.Callback, pick)
        end
    end

    local function ClosePanel()
        if panel then panel:Destroy() panel = nil end
        open = false
    end

    local function OpenPanel()
        if open then return end
        open = true
        local rootGui = GetRootGui()
        local outside = opts.DropdownOutsideWindow

        panel = New("Frame", {
            Size = UDim2.new(0, 180, 0, math.min(#values * 28 + 8, 220)),
            ZIndex = 60,
            ClipsDescendants = true,
            Parent = rootGui,
        })
        Tag(panel, "BackgroundColor3", "DropdownFrame")
        Round(panel, 8)
        panelStroke = New("UIStroke", { Thickness = 1, Parent = panel, ZIndex = 60 })
        Tag(panelStroke, "Color", "DropdownBorder")

        if outside then
            local abs = head.AbsolutePosition
            local absSize = head.AbsoluteSize
            local screenW = rootGui.AbsoluteSize.X
            local goLeft = (abs.X + absSize.X + 190) > screenW
            panel.Position = UDim2.fromOffset(
                goLeft and (abs.X - 188) or (abs.X + absSize.X + 8),
                abs.Y
            )
        else
            panel.Position = UDim2.fromOffset(head.AbsolutePosition.X, head.AbsolutePosition.Y + head.AbsoluteSize.Y + 4)
        end

        local list = New("ScrollingFrame", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 3,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ZIndex = 61,
            Parent = panel,
        })
        New("UIListLayout", { Parent = list, SortOrder = Enum.SortOrder.LayoutOrder })
        Pad(list, 4)

        for _, v in ipairs(values) do
            local opt = New("TextButton", {
                Size = UDim2.new(1, 0, 0, 26),
                AutoButtonColor = false,
                Font = Enum.Font.Gotham,
                TextSize = 12,
                Text = "  " .. v,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 61,
                Parent = list,
            })
            Tag(opt, "BackgroundColor3", selected[v] and "Hover" or "DropdownOption")
            Tag(opt, "TextColor3", "Text")
            Round(opt, 5)

            opt.MouseButton1Click:Connect(function()
                if multi then
                    selected[v] = not selected[v] or nil
                    opt.BackgroundColor3 = selected[v] and Library.Themes[Library.CurrentTheme].Hover or Library.Themes[Library.CurrentTheme].DropdownOption
                    label.Text = summary()
                    obj.Value = selected
                    fireCallback()
                else
                    selected = { [v] = true }
                    label.Text = summary()
                    obj.Value = next(selected)
                    fireCallback()
                    ClosePanel()
                end
            end)
        end
    end

    head.MouseButton1Click:Connect(function()
        if open then ClosePanel() else OpenPanel() end
    end)

    function obj:SetValue(v)
        if multi and type(v) == "table" then
            selected = v
        elseif not multi and type(v) == "string" then
            selected = { [v] = true }
        end
        label.Text = summary()
        self.Value = multi and selected or next(selected)
    end
    if flag then Library.Options[flag] = obj end
    return obj
end

-- ---- Colorpicker (RGB sliders in a popover; simplified, no touch) ----
function Container:AddColorpicker(flag, opts)
    opts = opts or {}
    local color = opts.Default or Color3.fromRGB(255, 255, 255)

    local frame, right = BuildElementBase(self.Holder, NextOrder(self), opts, opts.Description and 46 or 40)
    right.Size = UDim2.new(0, 40, 0, 24)

    local swatch = New("TextButton", { Size = UDim2.new(1, 0, 1, 0), AutoButtonColor = false, Text = "", BackgroundColor3 = color, Parent = right })
    Round(swatch, 6)
    local sstroke = New("UIStroke", { Thickness = 1, Parent = swatch })
    Tag(sstroke, "Color", "ElementBorder")

    local obj = { Value = color, Flag = flag, Type = "Colorpicker" }

    swatch.MouseButton1Click:Connect(function()
        local win = self.Window
        if not win then return end
        local overlay = win:Dialog({
            Title = opts.Title or "Color",
            Content = "Adjust RGB values",
            Buttons = { { Title = "Close" } },
        })
        -- inject RGB sliders into the dialog card (first child Frame)
        local card = overlay:FindFirstChildOfClass("Frame")
        if not card then return end
        local r, g, b = color.R * 255, color.G * 255, color.B * 255

        local function miniSlider(labelText, initial, onChange)
            local row = New("Frame", { Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, Parent = card })
            New("TextLabel", { Size = UDim2.new(0, 16, 1, 0), BackgroundTransparency = 1, Text = labelText, TextColor3 = Color3.fromRGB(200,200,200), Font = Enum.Font.GothamBold, TextSize = 12, Parent = row })
            local rail = New("Frame", { Size = UDim2.new(1, -24, 0, 6), Position = UDim2.new(0, 20, 0.5, -3), BackgroundColor3 = Color3.fromRGB(50,50,55), Parent = row })
            Round(rail, 3)
            local fill = New("Frame", { Size = UDim2.new(initial / 255, 0, 1, 0), BackgroundColor3 = Color3.fromRGB(200,200,200), Parent = rail })
            Round(fill, 3)
            local hit = New("TextButton", { Size = UDim2.new(1, 0, 1, 16), Position = UDim2.new(0,0,0,-8), BackgroundTransparency = 1, Text = "", Parent = rail })
            local dragging = false
            local function setFromX(x)
                local a = math.clamp((x - rail.AbsolutePosition.X) / math.max(rail.AbsoluteSize.X, 1), 0, 1)
                fill.Size = UDim2.new(a, 0, 1, 0)
                onChange(a * 255)
            end
            hit.InputBegan:Connect(function(input)
                if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
                dragging = true
                setFromX(input.Position.X)
            end)
            UserInputService.InputChanged:Connect(function(input)
                if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                    setFromX(input.Position.X)
                end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
            end)
        end

        miniSlider("R", r, function(v) r = v; swatch.BackgroundColor3 = Color3.fromRGB(r, g, b) end)
        miniSlider("G", g, function(v) g = v; swatch.BackgroundColor3 = Color3.fromRGB(r, g, b) end)
        miniSlider("B", b, function(v) b = v; swatch.BackgroundColor3 = Color3.fromRGB(r, g, b) end)

        local applyBtn = New("TextButton", {
            Size = UDim2.new(1, 0, 0, 28),
            Text = "Apply",
            Font = Enum.Font.GothamBold,
            TextSize = 13,
            TextColor3 = Color3.new(1,1,1),
            BackgroundColor3 = Library.Themes[Library.CurrentTheme].Accent,
            Parent = card,
        })
        Round(applyBtn, 6)
        applyBtn.MouseButton1Click:Connect(function()
            color = Color3.fromRGB(r, g, b)
            obj.Value = color
            if opts.Callback then protectedCall(opts.Callback, color) end
            overlay:Destroy()
        end)
    end)

    function obj:SetValue(v)
        color = v
        self.Value = v
        swatch.BackgroundColor3 = v
    end
    if flag then Library.Options[flag] = obj end
    return obj
end

-- ---- Code block ----
function Container:AddCode(opts)
    opts = opts or {}
    local frame = New("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = NextOrder(self),
        Parent = self.Holder,
    })
    Tag(frame, "BackgroundColor3", "Element")
    Round(frame, 8)
    local stroke = New("UIStroke", { Thickness = 1, Parent = frame })
    Tag(stroke, "Color", "ElementBorder")
    Pad(frame, 10)
    New("UIListLayout", { Parent = frame, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder })

    if opts.Title then
        local t = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 16),
            Font = Enum.Font.GothamBold,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = opts.Title,
            Parent = frame,
        })
        Tag(t, "TextColor3", "Text")
    end

    local codeBox = New("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Font = Enum.Font.Code,
        TextSize = 12,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        Text = opts.Code or "",
        Parent = frame,
    })
    Tag(codeBox, "TextColor3", "SubText")

    local copyBtn = New("TextButton", {
        Size = UDim2.new(0, 70, 0, 22),
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        Text = "Copy",
        Parent = frame,
    })
    Tag(copyBtn, "BackgroundColor3", "DropdownFrame")
    Tag(copyBtn, "TextColor3", "Text")
    Round(copyBtn, 5)
    copyBtn.MouseButton1Click:Connect(function()
        pcall(function() setclipboard(opts.Code or "") end)
        if opts.OnCopy then protectedCall(opts.OnCopy) end
    end)

    return { Instance = frame }
end

-- ---- Group (side-by-side columns) ----
function Container:AddGroup(opts)
    opts = opts or {}
    local columns = opts.Columns or 2
    local gap = opts.Gap or 6
    local outerWindow = self.Window

    local frame = New("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        LayoutOrder = NextOrder(self),
        Parent = self.Holder,
    })
    New("UIListLayout", {
        Parent = frame,
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, gap),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })

    local group = {}
    function group:AddElement()
        local colFrame = New("Frame", {
            Size = UDim2.new(1 / columns, -gap * (columns - 1) / columns, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Parent = frame,
        })
        New("UIListLayout", { Parent = colFrame, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder })
        local c = NewContainer(colFrame)
        c.Window = outerWindow
        return c
    end

    return group
end

--============================================================
-- SECTION / COLLAPSIBLE SECTION
--============================================================

local function AttachContainerMethods(target, holder, window)
    local c = NewContainer(holder)
    c.Window = window
    for name, fn in pairs(Container) do
        if name ~= "__index" then
            target[name] = function(_, ...) return fn(c, ...) end
        end
    end
    target._Container = c
    return target
end

local function BuildSectionShell(parentHolder, title, icon, order)
    local card = New("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        LayoutOrder = order,
        Parent = parentHolder,
    })
    New("UIListLayout", { Parent = card, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder })

    local header = New("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 16),
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = title or "",
        Parent = card,
    })
    Tag(header, "TextColor3", "SubText")

    local body = New("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Parent = card,
    })
    New("UIListLayout", { Parent = body, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder })

    return card, header, body
end

-- Regular Section
local function NewSection(parentHolder, title, icon, order, window)
    local card, header, body = BuildSectionShell(parentHolder, title, icon, order)
    local section = {}
    AttachContainerMethods(section, body, window)
    return section
end

-- Collapsible Section (lives at Tab level, toggled open/closed)
local function NewCollapsibleSection(parentHolder, title, icon, open, order, window)
    if open == nil then open = true end
    local card = New("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = order,
        Parent = parentHolder,
    })
    Tag(card, "BackgroundColor3", "Element")
    Round(card, 8)
    local cstroke = New("UIStroke", { Thickness = 1, Parent = card })
    Tag(cstroke, "Color", "ElementBorder")

    local headerBtn = New("TextButton", {
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        Text = "",
        Parent = card,
    })
    local headerLabel = New("TextLabel", {
        Size = UDim2.new(1, -30, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = title or "",
        Parent = headerBtn,
    })
    Tag(headerLabel, "TextColor3", "Text")
    local chevron = New("TextLabel", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0),
        Size = UDim2.new(0, 14, 0, 14),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        Text = open and "^" or "v",
        Parent = headerBtn,
    })
    Tag(chevron, "TextColor3", "SubText")

    local body = New("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        Visible = open,
        Parent = card,
    })
    Pad(body, 10, 0, 10, 10)
    New("UIListLayout", { Parent = body, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder })

    headerBtn.MouseButton1Click:Connect(function()
        open = not open
        body.Visible = open
        chevron.Text = open and "^" or "v"
    end)

    local section = {}
    AttachContainerMethods(section, body, window)
    return section
end

--============================================================
-- TAB
--============================================================

local Tab = {}
Tab.__index = Tab

function Window:AddTab(opts)
    opts = opts or {}
    local order = #self.TabOrder + 1

    local button = New("TextButton", {
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        Text = "  " .. (opts.Title or ("Tab " .. order)),
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = order,
        Parent = self.TabList,
    })
    Tag(button, "TextColor3", "Text")
    Tag(button, "BackgroundColor3", "TabActive")
    Round(button, 6)

    local page = New("ScrollingFrame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false,
        Parent = self.Pages,
    })
    Pad(page, 12)
    New("UIListLayout", { Parent = page, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder })

    local tabObj = setmetatable({
        Button = button,
        Page = page,
        Window = self,
        SectionOrder = 0,
    }, Tab)

    -- Direct Add* methods on the tab itself (no section wrapper)
    AttachContainerMethods(tabObj, page, self)

    function tabObj:AddSection(title, icon)
        self.SectionOrder = self.SectionOrder + 1
        return NewSection(self.Page, title, icon, self.SectionOrder, self.Window)
    end

    function tabObj:AddCollapsibleSection(title, icon, open)
        self.SectionOrder = self.SectionOrder + 1
        return NewCollapsibleSection(self.Page, title, icon, open, self.SectionOrder, self.Window)
    end

    button.MouseButton1Click:Connect(function()
        self:SelectTab(tabObj)
    end)

    table.insert(self.TabOrder, tabObj)
    self.Tabs[opts.Title or ("Tab" .. order)] = tabObj

    if #self.TabOrder == 1 then
        self:SelectTab(tabObj)
    end

    return tabObj
end

--============================================================
-- SAVEMANAGER  (config persistence via executor file API, all pcall-guarded)
--============================================================

local SaveManager = { Folder = "QuirksUI/Config", Lib = nil, IgnoreTheme = false }

function SaveManager:SetLibrary(lib) self.Lib = lib end
function SaveManager:SetFolder(path) self.Folder = path end
function SaveManager:IgnoreThemeSettings() self.IgnoreTheme = true end

local function fileApiAvailable()
    return typeof(writefile) == "function" and typeof(readfile) == "function"
        and typeof(isfile) == "function" and typeof(makefolder) == "function"
end

local function ensureFolder(path)
    if not fileApiAvailable() then return end
    pcall(function()
        if not isfolder(path) then makefolder(path) end
    end)
end

function SaveManager:Save(name)
    if not fileApiAvailable() then return false, "file API unavailable" end
    ensureFolder(self.Folder)
    local data = {}
    for flag, obj in pairs(Library.Options) do
        if obj and obj.Value ~= nil and typeof(obj.Value) ~= "Instance" then
            local v = obj.Value
            if typeof(v) == "Color3" then
                v = { __color3 = true, R = v.R, G = v.G, B = v.B }
            end
            data[flag] = v
        end
    end
    if not self.IgnoreTheme then
        data.__theme = Library.CurrentTheme
    end
    local ok = pcall(function()
        writefile(self.Folder .. "/" .. name .. ".json", HttpService:JSONEncode(data))
    end)
    return ok
end

function SaveManager:Load(name)
    if not fileApiAvailable() then return false, "file API unavailable" end
    local path = self.Folder .. "/" .. name .. ".json"
    if not isfile(path) then return false, "not found" end
    local ok, decoded = pcall(function() return HttpService:JSONDecode(readfile(path)) end)
    if not ok then return false, "corrupt config" end
    for flag, v in pairs(decoded) do
        if flag == "__theme" then
            if not self.IgnoreTheme then Library:SetTheme(v) end
        else
            local obj = Library.Options[flag]
            if obj and obj.SetValue then
                if typeof(v) == "table" and v.__color3 then
                    obj:SetValue(Color3.new(v.R, v.G, v.B))
                else
                    obj:SetValue(v)
                end
            end
        end
    end
    return true
end

function SaveManager:ListConfigs()
    if not fileApiAvailable() or typeof(listfiles) ~= "function" then return {} end
    ensureFolder(self.Folder)
    local list = {}
    pcall(function()
        for _, f in ipairs(listfiles(self.Folder)) do
            local name = f:match("([^/\\]+)%.json$")
            if name then table.insert(list, name) end
        end
    end)
    return list
end

function SaveManager:LoadAutoloadConfig()
    if not fileApiAvailable() then return end
    local path = self.Folder .. "/autoload.txt"
    if isfile(path) then
        local ok, name = pcall(readfile, path)
        if ok and name and name ~= "" then
            self:Load(name)
        end
    end
end

function SaveManager:BuildConfigSection(tab)
    if not tab then return end
    local sec = tab:AddSection("Config", "solar/diskette-bold")
    if not fileApiAvailable() then
        sec:AddParagraph({
            Title = "File API unavailable",
            Content = "Your executor does not expose writefile/readfile, so configs can't be saved here.",
        })
        return
    end

    local nameInput = sec:AddInput("__cfg_name", { Title = "Config Name", Placeholder = "my-config" })
    local dropdownValues = self:ListConfigs()
    local dd = sec:AddDropdown("__cfg_select", { Title = "Saved Configs", Values = dropdownValues, Default = dropdownValues[1] })

    sec:AddButton({
        Title = "Save",
        Icon = "solar/diskette-bold",
        Callback = function()
            local name = nameInput.Value ~= "" and nameInput.Value or "default"
            local ok = self:Save(name)
            Library:Notify({ Title = "Config", Content = ok and ("Saved as " .. name) or "Save failed", Type = ok and "Success" or "Error", Duration = 3 })
        end,
    })

    sec:AddButton({
        Title = "Load Selected",
        Icon = "solar/upload-minimalistic-bold",
        Callback = function()
            local pick = next(type(dd.Value) == "table" and dd.Value or {}) or dd.Value
            if not pick then
                Library:Notify({ Title = "Config", Content = "No config selected", Type = "Warning" })
                return
            end
            local ok = self:Load(pick)
            Library:Notify({ Title = "Config", Content = ok and ("Loaded " .. pick) or "Load failed", Type = ok and "Success" or "Error", Duration = 3 })
        end,
    })

    sec:AddButton({
        Title = "Set As Autoload",
        Icon = "solar/star-bold",
        Callback = function()
            local pick = next(type(dd.Value) == "table" and dd.Value or {}) or dd.Value
            if pick then
                pcall(writefile, self.Folder .. "/autoload.txt", pick)
                Library:Notify({ Title = "Config", Content = pick .. " set to autoload", Type = "Success" })
            end
        end,
    })
end

--============================================================
-- INTERFACEMANAGER (theme picker section)
--============================================================

local InterfaceManager = { Folder = "QuirksUI/Interface", Lib = nil }

function InterfaceManager:SetLibrary(lib) self.Lib = lib end
function InterfaceManager:SetFolder(path) self.Folder = path end

function InterfaceManager:BuildInterfaceSection(tab)
    if not tab then return end
    local sec = tab:AddSection("Interface", "solar/palette-bold")

    local names = {}
    for name in pairs(Library.Themes) do table.insert(names, name) end
    table.sort(names)

    sec:AddDropdown("__theme_select", {
        Title = "Theme",
        Values = names,
        Default = Library.CurrentTheme,
        Callback = function(v)
            Library:SetTheme(v)
            if fileApiAvailable() then
                ensureFolder(self.Folder)
                pcall(writefile, self.Folder .. "/theme.txt", v)
            end
        end,
    })
end

function InterfaceManager:ApplyCustomFont(source, weight)
    -- Applies a global font override to all text created going forward.
    -- (Existing labels keep their font; call this before building the window for full effect.)
    Library.CustomFont = { Source = source, Weight = weight }
end

function InterfaceManager:LoadSettings()
    if not fileApiAvailable() then return end
    local path = self.Folder .. "/theme.txt"
    if isfile(path) then
        local ok, theme = pcall(readfile, path)
        if ok and theme and Library.Themes[theme] then
            Library:SetTheme(theme)
        end
    end
end

--============================================================
-- WINDOW: apply initial theme now that SetTheme exists
--============================================================
-- (CreateWindow above already tags instances; if opts.Theme was supplied we honor it here.)

local _origCreateWindow = Library.CreateWindow
function Library:CreateWindow(opts)
    local win = _origCreateWindow(self, opts)
    if opts and opts.Theme and self.Themes[opts.Theme] then
        self:SetTheme(opts.Theme)
    end
    return win
end

--============================================================
-- EXPORTS
--============================================================

Library.SaveManager = SaveManager
Library.InterfaceManager = InterfaceManager

return Library
