--[[
    AstraUiLibrary v2.0
    Monochromatic Edition — Inspired by ASTRA Admin Panel
    -------------------------------------------------------
    Palette (from panel.html):
      Bg        #000000   → RGB(0,0,0)
      Surface   #0d0d0d   → RGB(13,13,13)
      Surface2  #141414   → RGB(20,20,20)
      Line      #1f1f1f   → RGB(31,31,31)
      LineMid   #2e2e2e   → RGB(46,46,46)
      Fg        #ffffff   → RGB(255,255,255)
      Fg2       #888888   → RGB(136,136,136)
      Fg3       #444444   → RGB(68,68,68)
      Danger    #ff3b3b   → RGB(255,59,59)

    Zero border-radius — everything sharp & editorial.
    -------------------------------------------------------
    Components:
      CreateTab            — sidebar nav tab
      CreateSectionHeader  — uppercase section label
      CreateLabel          — text label
      CreateSeparator      — divider (optional text)
      CreateParagraph      — info card
      CreateButton         — primary / ghost / danger
      CreateToggle         — sharp rectangular toggle
      CreateSlider         — minimal track + knob
      CreateTextBox        — bordered input
      CreateDropdown       — single or multi-select
      CreateCheckbox       — sharp square checkbox
      CreateKeybind        — monospace key tag
      CreateColorPicker    — compact HSV picker
      CreateProgressBar    — animated fill bar
      CreateTable          — editorial table with header
      CreateBadge          — outlined uppercase badge
      CreateRadioGroup     — square dot radio buttons
      CreateConfigSection  — save / load / autosave
    -------------------------------------------------------
    Notify(config)         — toast notification (corner)
    Toggle()               — show / hide window
    SetToggleKey(key)      — set keybind to toggle UI
    SaveConfig(name)       — save element states to JSON
    LoadConfig(name)       — load element states from JSON
    GetConfigs()           — list saved configs
    SetAutoSave(bool)      — auto-save every 30s
    Destroy()              — clean up everything
    -------------------------------------------------------
]]

local TweenService       = game:GetService("TweenService")
local UserInputService   = game:GetService("UserInputService")
local Players            = game:GetService("Players")
local HttpService        = game:GetService("HttpService")

--------------------------------------------------
-- COLOUR PALETTE
--------------------------------------------------
local C = {
    Bg       = Color3.fromRGB(0,   0,   0),
    Surface  = Color3.fromRGB(13,  13,  13),
    Surface2 = Color3.fromRGB(20,  20,  20),
    Line     = Color3.fromRGB(31,  31,  31),
    LineMid  = Color3.fromRGB(46,  46,  46),
    Fg       = Color3.fromRGB(255, 255, 255),
    Fg2      = Color3.fromRGB(136, 136, 136),
    Fg3      = Color3.fromRGB(68,  68,  68),
    Danger   = Color3.fromRGB(255, 59,  59),
}

--------------------------------------------------
-- TYPOGRAPHY
--------------------------------------------------
local F = {
    Regular  = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular),
    Medium   = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium),
    SemiBold = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold),
    Bold     = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold),
    Black    = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.ExtraBold),
    Mono     = Font.new("rbxasset://fonts/families/RobotoMono.json", Enum.FontWeight.Regular),
}
local TS = { Title = 15, Normal = 13, Small = 12, Tiny = 10 }

--------------------------------------------------
-- LIBRARY OBJECT
--------------------------------------------------
local Library = {}
Library.__index = Library

-- Single global dragger — prevents N mouse connections
Library._activeDragger  = nil
Library._activeDropdown = nil
Library._activePicker   = nil

UserInputService.InputChanged:Connect(function(input)
    if Library._activeDragger and
       (input.UserInputType == Enum.UserInputType.MouseMovement or
        input.UserInputType == Enum.UserInputType.Touch) then
        Library._activeDragger(input)
    end
end)

--------------------------------------------------
-- INTERNAL HELPERS
--------------------------------------------------
local function Inst(class, props)
    local obj = Instance.new(class)
    for k, v in pairs(props) do
        if k ~= "Parent" then pcall(function() obj[k] = v end) end
    end
    if props.Parent then obj.Parent = props.Parent end
    return obj
end

local function Stroke(parent, color, thickness)
    return Inst("UIStroke", {
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Color     = color or C.Line,
        Thickness = thickness or 1,
        Parent    = parent,
    })
end

local function Pad(parent, top, bottom, left, right)
    return Inst("UIPadding", {
        PaddingTop    = UDim.new(0, top    or 0),
        PaddingBottom = UDim.new(0, bottom or 0),
        PaddingLeft   = UDim.new(0, left   or 0),
        PaddingRight  = UDim.new(0, right  or 0),
        Parent        = parent,
    })
end

local function List(parent, padding, direction)
    return Inst("UIListLayout", {
        Padding       = UDim.new(0, padding or 0),
        FillDirection = direction or Enum.FillDirection.Vertical,
        SortOrder     = Enum.SortOrder.LayoutOrder,
        Parent        = parent,
    })
end

local function Tween(obj, props, t, style, dir)
    local tw = TweenService:Create(obj,
        TweenInfo.new(t or 0.15,
            style or Enum.EasingStyle.Quad,
            dir   or Enum.EasingDirection.Out),
        props)
    tw:Play()
    return tw
end

local function Divider(parent, y, w)
    return Inst("Frame", {
        BackgroundColor3 = C.Line,
        BorderSizePixel  = 0,
        Position         = UDim2.new(0, 0, 0, y or 0),
        Size             = UDim2.new(w or 1, 0, 0, 1),
        Parent           = parent,
    })
end

local function MakeDraggable(frame, handle)
    local dragging, dragStart, startPos = false, nil, nil
    handle = handle or frame
    handle.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and
           input.UserInputType ~= Enum.UserInputType.Touch then return end
        dragging  = true
        dragStart = input.Position
        startPos  = frame.Position
        Library._activeDragger = function(inp)
            if not dragging then return end
            local d = inp.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
        local conn
        conn = input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
                Library._activeDragger = nil
                conn:Disconnect()
            end
        end)
    end)
end

--------------------------------------------------
-- LIBRARY.NEW
--------------------------------------------------
function Library.new(title, options)
    local self     = setmetatable({}, Library)
    local opts     = options or {}
    self.title          = title or "Astra"
    self.tabs           = {}
    self.currentTab     = nil
    self._keybinds      = {}
    self._toggleKey     = Enum.KeyCode.RightControl
    self._visible       = true
    self._minimized     = false
    self._connections   = {}
    self._configElements = {}
    self._currentConfig  = "default"
    self._autoSave       = false
    self._windowW        = opts.Width  or 720
    self._windowH        = opts.Height or 440

    self:_Build()
    self:_SetupKeys()
    self:_SetupMobile()
    return self
end

--------------------------------------------------
-- WINDOW CONSTRUCTION
--------------------------------------------------
function Library:_Build()
    local lp = Players.LocalPlayer

    -- ScreenGui
    self.Gui = Inst("ScreenGui", {
        Name           = "AstraV2",
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn   = false,
        Parent         = lp:WaitForChild("PlayerGui"),
    })

    -- Main container
    self.Container = Inst("Frame", {
        Name             = "Container",
        BackgroundColor3 = C.Bg,
        BorderSizePixel  = 0,
        Size             = UDim2.new(0, self._windowW, 0, self._windowH),
        Position         = UDim2.new(0.5, -self._windowW/2, 0.5, -self._windowH/2),
        ClipsDescendants = false,
        Parent           = self.Gui,
    })
    Stroke(self.Container, C.Line, 1)

    -- Top bar (48 px)
    self.TopBar = Inst("Frame", {
        Name             = "TopBar",
        BackgroundColor3 = C.Bg,
        BorderSizePixel  = 0,
        Size             = UDim2.new(1, 0, 0, 48),
        ZIndex           = 5,
        Parent           = self.Container,
    })
    Divider(self.TopBar, 47)

    -- Title
    Inst("TextLabel", {
        Name             = "TitleLabel",
        Text             = self.title,
        FontFace         = F.Black,
        TextSize         = TS.Title,
        TextColor3       = C.Fg,
        TextXAlignment   = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        Position         = UDim2.new(0, 18, 0, 0),
        Size             = UDim2.new(0.5, 0, 1, 0),
        ZIndex           = 6,
        Parent           = self.TopBar,
    })

    -- Window controls
    self:_WindowControls()
    MakeDraggable(self.Container, self.TopBar)

    -- Body
    self.Body = Inst("Frame", {
        Name             = "Body",
        BackgroundTransparency = 1,
        BorderSizePixel  = 0,
        Position         = UDim2.new(0, 0, 0, 48),
        Size             = UDim2.new(1, 0, 1, -48),
        Parent           = self.Container,
    })

    -- Sidebar (175 px wide)
    self.Sidebar = Inst("ScrollingFrame", {
        Name                  = "Sidebar",
        BackgroundColor3      = C.Bg,
        BorderSizePixel       = 0,
        Size                  = UDim2.new(0, 175, 1, 0),
        ScrollBarThickness    = 0,
        CanvasSize            = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize   = Enum.AutomaticSize.Y,
        ScrollingDirection    = Enum.ScrollingDirection.Y,
        Parent                = self.Body,
    })
    -- Sidebar right border
    Inst("Frame", {
        BackgroundColor3 = C.Line,
        BorderSizePixel  = 0,
        Position         = UDim2.new(1, -1, 0, 0),
        Size             = UDim2.new(0, 1, 1, 0),
        Parent           = self.Sidebar,
    })
    List(self.Sidebar, 0)
    Pad(self.Sidebar, 10, 10, 0, 0)

    -- Content area
    self.ContentArea = Inst("ScrollingFrame", {
        Name                = "Content",
        BackgroundTransparency = 1,
        BorderSizePixel     = 0,
        Position            = UDim2.new(0, 175, 0, 0),
        Size                = UDim2.new(1, -175, 1, 0),
        ScrollBarThickness  = 2,
        ScrollBarImageColor3 = C.LineMid,
        CanvasSize          = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection  = Enum.ScrollingDirection.Y,
        Parent              = self.Body,
    })
    List(self.ContentArea, 10)
    Pad(self.ContentArea, 22, 22, 22, 22)

    -- Notification container (top-right of screen)
    self._notifHolder = Inst("Frame", {
        Name                 = "NotifHolder",
        BackgroundTransparency = 1,
        AnchorPoint          = Vector2.new(1, 0),
        Position             = UDim2.new(1, -18, 0, 18),
        Size                 = UDim2.new(0, 270, 1, 0),
        ZIndex               = 999,
        Parent               = self.Gui,
    })
    List(self._notifHolder, 8)
end

function Library:_WindowControls()
    -- Close button (×)
    local function CtrlBtn(text, xOffset, hoverColor)
        local btn = Inst("TextButton", {
            Name             = text,
            Text             = text,
            FontFace         = F.Regular,
            TextSize         = 18,
            TextColor3       = C.Fg3,
            BackgroundTransparency = 1,
            AnchorPoint      = Vector2.new(1, 0.5),
            Position         = UDim2.new(1, xOffset, 0.5, 0),
            Size             = UDim2.new(0, 30, 0, 30),
            ZIndex           = 6,
            Parent           = self.TopBar,
        })
        btn.MouseEnter:Connect(function() btn.TextColor3 = hoverColor end)
        btn.MouseLeave:Connect(function() btn.TextColor3 = C.Fg3 end)
        return btn
    end

    local closeBtn = CtrlBtn("×", -8, C.Danger)
    closeBtn.MouseButton1Click:Connect(function() self:Destroy() end)

    local minBtn = CtrlBtn("−", -38, C.Fg)
    self._originalHeight = self._windowH
    minBtn.MouseButton1Click:Connect(function()
        self._minimized = not self._minimized
        if self._minimized then
            self._originalHeight = self.Container.AbsoluteSize.Y
            Tween(self.Container, {Size = UDim2.new(0, self._windowW, 0, 48)}, 0.18)
            task.wait(0.05)
            self.Body.Visible = false
        else
            self.Body.Visible = true
            Tween(self.Container, {Size = UDim2.new(0, self._windowW, 0, self._originalHeight)}, 0.18)
        end
    end)
end

--------------------------------------------------
-- KEY / MOBILE SETUP
--------------------------------------------------
function Library:_SetupKeys()
    self._connections["keys"] = UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == self._toggleKey then self:Toggle() end
        for _, kb in pairs(self._keybinds) do
            if input.KeyCode == kb.key then pcall(kb.callback) end
        end
    end)
end

function Library:_SetupMobile()
    if not (UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled) then return end
    local btn = Inst("TextButton", {
        Name             = "MobileBtn",
        Text             = "∞",
        FontFace         = F.Black,
        TextSize         = 22,
        TextColor3       = C.Fg,
        BackgroundColor3 = C.Surface,
        BorderSizePixel  = 0,
        Size             = UDim2.new(0, 46, 0, 46),
        Position         = UDim2.new(0, 12, 0.5, -23),
        ZIndex           = 999,
        Visible          = false,
        Parent           = self.Gui,
    })
    Stroke(btn, C.LineMid, 1)

    local drag, ds, sp = false, nil, nil
    btn.InputBegan:Connect(function(i)
        if i.UserInputType ~= Enum.UserInputType.Touch then return end
        drag = true; ds = i.Position; sp = btn.Position
        Library._activeDragger = function(inp)
            if not drag then return end
            local d = inp.Position - ds
            btn.Position = UDim2.new(sp.X.Scale, sp.X.Offset+d.X, sp.Y.Scale, sp.Y.Offset+d.Y)
        end
    end)
    btn.InputEnded:Connect(function(i)
        if i.UserInputType ~= Enum.UserInputType.Touch then return end
        if drag and (i.Position - ds).Magnitude < 10 then self:Toggle() end
        drag = false; Library._activeDragger = nil
    end)
    self._mobileBtn = btn
end

--------------------------------------------------
-- PUBLIC METHODS
--------------------------------------------------
function Library:Toggle()
    self._visible = not self._visible
    self.Container.Visible = self._visible
    if self._mobileBtn then self._mobileBtn.Visible = not self._visible end
end

function Library:SetToggleKey(key) self._toggleKey = key end

function Library:Destroy()
    for _, c in pairs(self._connections) do
        if typeof(c) == "RBXScriptConnection" then pcall(function() c:Disconnect() end) end
    end
    if self.Gui then self.Gui:Destroy() end
end

--------------------------------------------------
-- NOTIFICATIONS (toast style, bottom-right)
--------------------------------------------------
function Library:Notify(config)
    local title    = config.Title or "Notification"
    local desc     = config.Description or ""
    local duration = config.Duration or 3
    local isErr    = config.Error or false

    local notif = Inst("Frame", {
        Name             = "Notif",
        BackgroundColor3 = C.Surface,
        BorderSizePixel  = 0,
        Size             = UDim2.new(1, 0, 0, 66),
        Position         = UDim2.new(1, 20, 0, 0),
        ClipsDescendants = true,
        ZIndex           = 1000,
        Parent           = self._notifHolder,
    })
    Stroke(notif, isErr and C.Danger or C.LineMid, 1)

    Inst("TextLabel", {
        Text           = title,
        FontFace       = F.Bold,
        TextSize       = TS.Normal,
        TextColor3     = isErr and C.Danger or C.Fg,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        Position       = UDim2.new(0, 14, 0, 13),
        Size           = UDim2.new(1, -28, 0, 18),
        ZIndex         = 1001,
        Parent         = notif,
    })
    Inst("TextLabel", {
        Text           = desc,
        FontFace       = F.Regular,
        TextSize       = TS.Small,
        TextColor3     = C.Fg2,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate   = Enum.TextTruncate.AtEnd,
        BackgroundTransparency = 1,
        Position       = UDim2.new(0, 14, 0, 35),
        Size           = UDim2.new(1, -28, 0, 16),
        ZIndex         = 1001,
        Parent         = notif,
    })
    -- Timer bar
    local bar = Inst("Frame", {
        BackgroundColor3 = isErr and C.Danger or C.Fg,
        BorderSizePixel  = 0,
        Position         = UDim2.new(0, 0, 1, -2),
        Size             = UDim2.new(1, 0, 0, 2),
        ZIndex           = 1001,
        Parent           = notif,
    })

    Tween(notif, {Position = UDim2.new(0, 0, 0, 0)}, 0.28,
        Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    Tween(bar, {Size = UDim2.new(0, 0, 0, 2)}, duration, Enum.EasingStyle.Linear)

    task.delay(duration, function()
        Tween(notif, {Position = UDim2.new(1, 20, 0, 0)}, 0.22)
        task.wait(0.25)
        pcall(function() notif:Destroy() end)
    end)
    return notif
end

--------------------------------------------------
-- CREATE TAB
--------------------------------------------------
function Library:CreateTab(name, icon)
    -- Sidebar nav item
    local navItem = Inst("TextButton", {
        Name             = "Tab_"..name,
        Text             = "",
        BackgroundColor3 = C.Bg,
        BackgroundTransparency = 1,
        BorderSizePixel  = 0,
        Size             = UDim2.new(1, 0, 0, 38),
        Parent           = self.Sidebar,
    })
    -- Left accent stripe (2 px)
    local accentBar = Inst("Frame", {
        Name             = "Accent",
        BackgroundColor3 = C.Fg,
        BorderSizePixel  = 0,
        BackgroundTransparency = 1,
        Size             = UDim2.new(0, 2, 1, 0),
        Parent           = navItem,
    })
    -- Icon
    local iconImg = Inst("ImageLabel", {
        Name             = "Icon",
        Image            = icon or "rbxassetid://112235310154264",
        ImageColor3      = C.Fg3,
        BackgroundTransparency = 1,
        AnchorPoint      = Vector2.new(0, 0.5),
        Position         = UDim2.new(0, 20, 0.5, -8),
        Size             = UDim2.new(0, 16, 0, 16),
        Parent           = navItem,
    })
    -- Text
    local navText = Inst("TextLabel", {
        Name             = "NavText",
        Text             = name,
        FontFace         = F.Medium,
        TextSize         = TS.Normal,
        TextColor3       = C.Fg2,
        TextXAlignment   = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        Position         = UDim2.new(0, 44, 0, 0),
        Size             = UDim2.new(1, -50, 1, 0),
        Parent           = navItem,
    })

    -- Content frame (inside ContentArea)
    local content = Inst("Frame", {
        Name             = name.."_Content",
        BackgroundTransparency = 1,
        Size             = UDim2.new(1, 0, 0, 0),
        AutomaticSize    = Enum.AutomaticSize.Y,
        Visible          = false,
        Parent           = self.ContentArea,
    })
    List(content, 8)

    -- Tab data
    local tab = {
        name     = name,
        navItem  = navItem,
        accent   = accentBar,
        icon     = iconImg,
        text     = navText,
        content  = content,
        _lib     = self,
    }

    -- Hover
    navItem.MouseEnter:Connect(function()
        if self.currentTab == tab then return end
        navItem.BackgroundTransparency = 0.9
        navItem.BackgroundColor3 = C.Fg
        navText.TextColor3 = C.Fg
        iconImg.ImageColor3 = C.Fg2
    end)
    navItem.MouseLeave:Connect(function()
        if self.currentTab == tab then return end
        navItem.BackgroundTransparency = 1
        navText.TextColor3 = C.Fg2
        iconImg.ImageColor3 = C.Fg3
    end)
    navItem.MouseButton1Click:Connect(function() self:_SelectTab(tab) end)

    table.insert(self.tabs, tab)
    if not self.currentTab then self:_SelectTab(tab) end

    -- Wrap tab with component methods
    local methods = setmetatable({}, {__index = tab})

    function methods:CreateSectionHeader(n)     return Library._SectionHeader(self, n) end
    function methods:CreateLabel(c)             return Library._Label(self, c) end
    function methods:CreateSeparator(c)         return Library._Separator(self, c) end
    function methods:CreateParagraph(c)         return Library._Paragraph(self, c) end
    function methods:CreateButton(c)            return Library._Button(self, c) end
    function methods:CreateToggle(c)            return Library._Toggle(self, c) end
    function methods:CreateSlider(c)            return Library._Slider(self, c) end
    function methods:CreateTextBox(c)           return Library._TextBox(self, c) end
    function methods:CreateDropdown(c)          return Library._Dropdown(self, c) end
    function methods:CreateCheckbox(c)          return Library._Checkbox(self, c) end
    function methods:CreateKeybind(c)           return Library._Keybind(self, c) end
    function methods:CreateColorPicker(c)       return Library._ColorPicker(self, c) end
    function methods:CreateProgressBar(c)       return Library._ProgressBar(self, c) end
    function methods:CreateTable(c)             return Library._Table(self, c) end
    function methods:CreateBadge(c)             return Library._Badge(self, c) end
    function methods:CreateRadioGroup(c)        return Library._RadioGroup(self, c) end
    function methods:CreateConfigSection()      return Library._ConfigSection(self) end

    return methods
end

function Library:_SelectTab(tab)
    if self.currentTab then
        local p = self.currentTab
        p.content.Visible              = false
        p.navItem.BackgroundTransparency = 1
        p.navItem.BackgroundColor3     = C.Bg
        p.accent.BackgroundTransparency = 1
        p.text.TextColor3              = C.Fg2
        p.text.FontFace                = F.Medium
        p.icon.ImageColor3             = C.Fg3
    end
    self.currentTab = tab
    tab.content.Visible              = true
    tab.navItem.BackgroundTransparency = 0
    tab.navItem.BackgroundColor3     = C.Surface
    tab.accent.BackgroundTransparency = 0
    tab.text.TextColor3              = C.Fg
    tab.text.FontFace                = F.SemiBold
    tab.icon.ImageColor3             = C.Fg
    self.ContentArea.CanvasPosition  = Vector2.zero
end

--------------------------------------------------
-- CONFIG REGISTRATION (internal)
--------------------------------------------------
function Library:_RegConfig(flag, getter, setter)
    if flag then
        self._configElements[flag] = {getValue = getter, setValue = setter}
    end
end

--------------------------------------------------
-- COMPONENT: SECTION HEADER
--------------------------------------------------
function Library._SectionHeader(tab, name)
    return Inst("TextLabel", {
        Name             = "SectionHeader_"..name,
        Text             = string.upper(name),
        FontFace         = F.Bold,
        TextSize         = TS.Tiny,
        TextColor3       = C.Fg3,
        TextXAlignment   = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        Size             = UDim2.new(1, 0, 0, 24),
        Parent           = tab.content,
    })
end

--------------------------------------------------
-- COMPONENT: LABEL
--------------------------------------------------
function Library._Label(tab, config)
    local text  = config.Text  or "Label"
    local color = config.Color or C.Fg2

    local lbl = Inst("TextLabel", {
        Name             = "Label",
        Text             = text,
        FontFace         = F.Regular,
        TextSize         = TS.Normal,
        TextColor3       = color,
        TextXAlignment   = Enum.TextXAlignment.Left,
        TextWrapped      = true,
        BackgroundTransparency = 1,
        AutomaticSize    = Enum.AutomaticSize.Y,
        Size             = UDim2.new(1, 0, 0, 0),
        Parent           = tab.content,
    })
    return {
        SetText  = function(_, t) lbl.Text = t end,
        SetColor = function(_, c) lbl.TextColor3 = c end,
        GetText  = function()    return lbl.Text end,
    }
end

--------------------------------------------------
-- COMPONENT: SEPARATOR
--------------------------------------------------
function Library._Separator(tab, config)
    local text = config and config.Text
    local wrap = Inst("Frame", {
        Name             = "Separator",
        BackgroundTransparency = 1,
        Size             = UDim2.new(1, 0, 0, 18),
        Parent           = tab.content,
    })
    if text and text ~= "" then
        local uTxt = string.upper(text)
        Inst("Frame", {BackgroundColor3=C.Line, BorderSizePixel=0,
            AnchorPoint=Vector2.new(0,0.5), Position=UDim2.new(0,0,0.5,0),
            Size=UDim2.new(0.12,0,0,1), Parent=wrap})
        Inst("TextLabel", {
            Text=uTxt, FontFace=F.Bold, TextSize=TS.Tiny, TextColor3=C.Fg3,
            BackgroundTransparency=1,
            AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.new(0.5,0,0.5,0),
            Size=UDim2.new(0.7,0,1,0), Parent=wrap})
        Inst("Frame", {BackgroundColor3=C.Line, BorderSizePixel=0,
            AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,0,0.5,0),
            Size=UDim2.new(0.12,0,0,1), Parent=wrap})
    else
        Inst("Frame", {BackgroundColor3=C.Line, BorderSizePixel=0,
            AnchorPoint=Vector2.new(0,0.5), Position=UDim2.new(0,0,0.5,0),
            Size=UDim2.new(1,0,0,1), Parent=wrap})
    end
    return wrap
end

--------------------------------------------------
-- COMPONENT: PARAGRAPH (info card)
--------------------------------------------------
function Library._Paragraph(tab, config)
    local title   = config.Title   or "Title"
    local content = config.Content or ""

    local frame = Inst("Frame", {
        Name             = "Paragraph",
        BackgroundColor3 = C.Surface,
        BorderSizePixel  = 0,
        AutomaticSize    = Enum.AutomaticSize.Y,
        Size             = UDim2.new(1, 0, 0, 0),
        Parent           = tab.content,
    })
    Stroke(frame, C.Line, 1)
    Pad(frame, 14, 14, 14, 14)

    local titleLbl = Inst("TextLabel", {
        Name             = "PTitle",
        Text             = title,
        FontFace         = F.SemiBold,
        TextSize         = TS.Normal,
        TextColor3       = C.Fg,
        TextXAlignment   = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        Size             = UDim2.new(1, 0, 0, 20),
        Parent           = frame,
    })
    local contLbl = Inst("TextLabel", {
        Name             = "PContent",
        Text             = content,
        FontFace         = F.Regular,
        TextSize         = TS.Small,
        TextColor3       = C.Fg2,
        TextXAlignment   = Enum.TextXAlignment.Left,
        TextWrapped      = true,
        BackgroundTransparency = 1,
        AutomaticSize    = Enum.AutomaticSize.Y,
        Position         = UDim2.new(0, 0, 0, 24),
        Size             = UDim2.new(1, 0, 0, 0),
        Parent           = frame,
    })
    return {
        SetTitle   = function(_, t) titleLbl.Text = t end,
        SetContent = function(_, t) contLbl.Text  = t end,
    }
end

--------------------------------------------------
-- COMPONENT: BUTTON
--------------------------------------------------
function Library._Button(tab, config)
    local name     = config.Name     or "Button"
    local callback = config.Callback or function() end
    -- style: "primary" (white fill) | "ghost" (outlined) | "danger" (danger outlined)
    local style    = config.Style    or "primary"

    local bgNormal, bgHover, fgColor, strokeColor
    if style == "primary" then
        bgNormal    = C.Fg
        bgHover     = Color3.fromRGB(210, 210, 210)
        fgColor     = C.Bg
        strokeColor = nil
    elseif style == "danger" then
        bgNormal    = C.Bg
        bgHover     = Color3.fromRGB(10, 0, 0)
        fgColor     = C.Danger
        strokeColor = C.Danger
    else -- ghost
        bgNormal    = C.Bg
        bgHover     = C.Surface2
        fgColor     = C.Fg
        strokeColor = C.LineMid
    end

    local frame = Inst("Frame", {
        Name             = "Button_"..name,
        BackgroundColor3 = bgNormal,
        BorderSizePixel  = 0,
        Size             = UDim2.new(1, 0, 0, 36),
        Parent           = tab.content,
    })
    if strokeColor then Stroke(frame, strokeColor, 1) end

    local lbl = Inst("TextLabel", {
        Name             = "BtnLabel",
        Text             = name,
        FontFace         = F.SemiBold,
        TextSize         = TS.Normal,
        TextColor3       = fgColor,
        BackgroundTransparency = 1,
        Size             = UDim2.new(1, 0, 1, 0),
        Parent           = frame,
    })
    local btn = Inst("TextButton", {
        Text             = "",
        BackgroundTransparency = 1,
        Size             = UDim2.new(1, 0, 1, 0),
        Parent           = frame,
    })

    btn.MouseEnter:Connect(function()  frame.BackgroundColor3 = bgHover end)
    btn.MouseLeave:Connect(function()  frame.BackgroundColor3 = bgNormal end)
    btn.MouseButton1Click:Connect(function()
        Tween(frame, {BackgroundColor3 = style=="primary" and Color3.fromRGB(170,170,170) or C.Surface2}, 0.07)
        task.wait(0.12)
        Tween(frame, {BackgroundColor3 = bgNormal}, 0.07)
        pcall(callback)
    end)

    return {
        SetText = function(_, t) lbl.Text = t end,
    }
end

--------------------------------------------------
-- COMPONENT: TOGGLE (sharp rectangular)
--------------------------------------------------
function Library._Toggle(tab, config)
    local name     = config.Name     or "Toggle"
    local default  = config.Default  or false
    local callback = config.Callback or function() end
    local flag     = config.Flag
    local enabled  = default

    local frame = Inst("Frame", {
        Name             = "Toggle_"..name,
        BackgroundColor3 = C.Surface,
        BorderSizePixel  = 0,
        Size             = UDim2.new(1, 0, 0, 38),
        Parent           = tab.content,
    })
    Stroke(frame, C.Line, 1)

    Inst("TextLabel", {
        Text             = name,
        FontFace         = F.Medium,
        TextSize         = TS.Normal,
        TextColor3       = C.Fg,
        TextXAlignment   = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        Position         = UDim2.new(0, 14, 0, 0),
        Size             = UDim2.new(1, -68, 1, 0),
        Parent           = frame,
    })

    -- Track (sharp rectangle)
    local track = Inst("Frame", {
        Name             = "Track",
        BackgroundColor3 = enabled and C.Fg or C.Surface2,
        BorderSizePixel  = 0,
        AnchorPoint      = Vector2.new(1, 0.5),
        Position         = UDim2.new(1, -14, 0.5, 0),
        Size             = UDim2.new(0, 38, 0, 18),
        Parent           = frame,
    })
    local trackStroke = Stroke(track, enabled and C.Fg or C.LineMid, 1)

    -- Indicator square
    local indicator = Inst("Frame", {
        Name             = "Indicator",
        BackgroundColor3 = enabled and C.Bg or C.Fg3,
        BorderSizePixel  = 0,
        AnchorPoint      = Vector2.new(0, 0.5),
        Position         = enabled
            and UDim2.new(0, 22, 0.5, 0)
            or  UDim2.new(0, 4,  0.5, 0),
        Size             = UDim2.new(0, 12, 0, 12),
        Parent           = track,
    })

    local function UpdateVisual()
        if enabled then
            track.BackgroundColor3     = C.Fg
            trackStroke.Color          = C.Fg
            indicator.BackgroundColor3 = C.Bg
            Tween(indicator, {Position = UDim2.new(0, 22, 0.5, 0)}, 0.1)
        else
            track.BackgroundColor3     = C.Surface2
            trackStroke.Color          = C.LineMid
            indicator.BackgroundColor3 = C.Fg3
            Tween(indicator, {Position = UDim2.new(0, 4, 0.5, 0)}, 0.1)
        end
    end

    local btn = Inst("TextButton", {
        Text = "", BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0), Parent = frame,
    })
    btn.MouseButton1Click:Connect(function()
        enabled = not enabled
        UpdateVisual()
        pcall(callback, enabled)
    end)

    local methods = {
        SetValue = function(_, v) enabled = v; UpdateVisual(); pcall(callback, enabled) end,
        GetValue = function()    return enabled end,
    }
    tab._lib:_RegConfig(flag,
        function() return enabled end,
        function(v) methods:SetValue(v) end)
    return methods
end

--------------------------------------------------
-- COMPONENT: SLIDER
--------------------------------------------------
function Library._Slider(tab, config)
    local name     = config.Name     or "Slider"
    local min      = config.Min      or 0
    local max      = config.Max      or 100
    local default  = config.Default  or min
    local step     = config.Step     or 1
    local suffix   = config.Suffix   or ""
    local callback = config.Callback or function() end
    local flag     = config.Flag

    -- Decimal places from step
    local decimals = 0
    local stepStr  = tostring(step)
    local dot      = stepStr:find("%.")
    if dot then decimals = #stepStr - dot end

    local function Snap(raw)
        if step <= 0 then return raw end
        local snapped = math.floor((raw - min) / step + 0.5) * step + min
        snapped = math.clamp(snapped, min, max)
        if decimals > 0 then
            local m = 10^decimals
            return math.floor(snapped * m + 0.5) / m
        end
        return math.floor(snapped + 0.5)
    end
    local function Fmt(v)
        if decimals > 0 then return string.format("%."..decimals.."f", v)..suffix end
        return tostring(math.floor(v))..suffix
    end

    local current = Snap(math.clamp(default, min, max))

    local frame = Inst("Frame", {
        Name             = "Slider_"..name,
        BackgroundColor3 = C.Surface,
        BorderSizePixel  = 0,
        Size             = UDim2.new(1, 0, 0, 50),
        Parent           = tab.content,
    })
    Stroke(frame, C.Line, 1)

    Inst("TextLabel", {
        Text             = name,
        FontFace         = F.Medium,
        TextSize         = TS.Normal,
        TextColor3       = C.Fg,
        TextXAlignment   = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        Position         = UDim2.new(0, 14, 0, 8),
        Size             = UDim2.new(0.65, 0, 0, 18),
        Parent           = frame,
    })
    local valLbl = Inst("TextLabel", {
        Text             = Fmt(current),
        FontFace         = F.Mono,
        TextSize         = TS.Small,
        TextColor3       = C.Fg2,
        TextXAlignment   = Enum.TextXAlignment.Right,
        BackgroundTransparency = 1,
        AnchorPoint      = Vector2.new(1, 0),
        Position         = UDim2.new(1, -14, 0, 8),
        Size             = UDim2.new(0, 60, 0, 18),
        Parent           = frame,
    })

    -- Track
    local track = Inst("Frame", {
        BackgroundColor3 = C.Line,
        BorderSizePixel  = 0,
        Position         = UDim2.new(0, 14, 0, 35),
        Size             = UDim2.new(1, -28, 0, 3),
        Parent           = frame,
    })
    local fill = Inst("Frame", {
        BackgroundColor3 = C.Fg,
        BorderSizePixel  = 0,
        Size             = UDim2.new((current-min)/math.max(max-min,0.001), 0, 1, 0),
        Parent           = track,
    })
    -- Knob (square)
    local knob = Inst("Frame", {
        BackgroundColor3 = C.Fg,
        BorderSizePixel  = 0,
        AnchorPoint      = Vector2.new(0.5, 0.5),
        Position         = UDim2.new((current-min)/math.max(max-min,0.001), 0, 0.5, 0),
        Size             = UDim2.new(0, 10, 0, 10),
        ZIndex           = 2,
        Parent           = track,
    })

    local function UpdateFromInput(inp)
        local rel = (inp.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X
        rel     = math.clamp(rel, 0, 1)
        current = Snap(min + (max - min) * rel)
        local pct = (current - min) / math.max(max - min, 0.001)
        fill.Size         = UDim2.new(pct, 0, 1, 0)
        knob.Position     = UDim2.new(pct, 0, 0.5, 0)
        valLbl.Text       = Fmt(current)
        pcall(callback, current)
    end

    local dragging = false
    track.InputBegan:Connect(function(inp)
        if inp.UserInputType ~= Enum.UserInputType.MouseButton1 and
           inp.UserInputType ~= Enum.UserInputType.Touch then return end
        dragging = true
        UpdateFromInput(inp)
        Library._activeDragger = UpdateFromInput
    end)
    track.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or
           inp.UserInputType == Enum.UserInputType.Touch then
            dragging = false
            Library._activeDragger = nil
        end
    end)

    local methods = {
        SetValue = function(_, v)
            current = Snap(math.clamp(v, min, max))
            local pct = (current-min)/math.max(max-min,0.001)
            fill.Size     = UDim2.new(pct, 0, 1, 0)
            knob.Position = UDim2.new(pct, 0, 0.5, 0)
            valLbl.Text   = Fmt(current)
            pcall(callback, current)
        end,
        GetValue = function() return current end,
        SetMin   = function(_, v) min = v end,
        SetMax   = function(_, v) max = v end,
    }
    tab._lib:_RegConfig(flag,
        function() return current end,
        function(v) methods:SetValue(v) end)
    return methods
end

--------------------------------------------------
-- COMPONENT: TEXT BOX
--------------------------------------------------
function Library._TextBox(tab, config)
    local name        = config.Name        or "TextBox"
    local default     = config.Default     or ""
    local placeholder = config.Placeholder or "Enter text..."
    local callback    = config.Callback    or function() end
    local numbersOnly = config.NumbersOnly or false
    local flag        = config.Flag
    local current     = tostring(default)

    local frame = Inst("Frame", {
        Name             = "TextBox_"..name,
        BackgroundColor3 = C.Surface,
        BorderSizePixel  = 0,
        Size             = UDim2.new(1, 0, 0, 38),
        Parent           = tab.content,
    })
    Stroke(frame, C.Line, 1)

    Inst("TextLabel", {
        Text             = name,
        FontFace         = F.Medium,
        TextSize         = TS.Normal,
        TextColor3       = C.Fg,
        TextXAlignment   = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        Position         = UDim2.new(0, 14, 0, 0),
        Size             = UDim2.new(0.45, 0, 1, 0),
        Parent           = frame,
    })

    local inputBg = Inst("Frame", {
        BackgroundColor3 = C.Bg,
        BorderSizePixel  = 0,
        AnchorPoint      = Vector2.new(1, 0.5),
        Position         = UDim2.new(1, -14, 0.5, 0),
        Size             = UDim2.new(0, 165, 0, 24),
        Parent           = frame,
    })
    local inputStroke = Stroke(inputBg, C.LineMid, 1)

    local input = Inst("TextBox", {
        Text              = current,
        PlaceholderText   = placeholder,
        PlaceholderColor3 = C.Fg3,
        FontFace          = F.Mono,
        TextSize          = TS.Small,
        TextColor3        = C.Fg,
        TextXAlignment    = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        ClearTextOnFocus  = false,
        Position          = UDim2.new(0, 8, 0, 0),
        Size              = UDim2.new(1, -16, 1, 0),
        Parent            = inputBg,
    })

    input.Focused:Connect(function()    inputStroke.Color = C.Fg end)
    input.FocusLost:Connect(function(enter)
        inputStroke.Color = C.LineMid
        if numbersOnly then
            local n = tonumber(input.Text)
            if n then current = tostring(n); input.Text = current
            else input.Text = current end
        else
            current = input.Text
        end
        pcall(callback, current, enter)
    end)
    if numbersOnly then
        input:GetPropertyChangedSignal("Text"):Connect(function()
            local f = input.Text:gsub("[^%d%.%-]","")
            if input.Text ~= f then input.Text = f end
        end)
    end

    local methods = {
        SetText        = function(_, t) current = tostring(t); input.Text = current end,
        GetText        = function()     return current end,
        SetPlaceholder = function(_, t) input.PlaceholderText = t end,
        Focus          = function()     input:CaptureFocus() end,
    }
    tab._lib:_RegConfig(flag,
        function() return current end,
        function(v) methods:SetText(v) end)
    return methods
end

--------------------------------------------------
-- COMPONENT: DROPDOWN
--------------------------------------------------
function Library._Dropdown(tab, config)
    local name        = config.Name        or "Dropdown"
    local options     = config.Options     or {}
    local default     = config.Default     or (options[1] or "")
    local multiSelect = config.MultiSelect or false
    local callback    = config.Callback    or function() end
    local flag        = config.Flag
    local selected    = multiSelect
        and (type(config.Default)=="table" and config.Default or {})
        or  default
    local expanded = false

    local frame = Inst("Frame", {
        Name             = "Dropdown_"..name,
        BackgroundColor3 = C.Surface,
        BorderSizePixel  = 0,
        Size             = UDim2.new(1, 0, 0, 38),
        ClipsDescendants = false,
        ZIndex           = 1,
        Parent           = tab.content,
    })
    Stroke(frame, C.Line, 1)

    Inst("TextLabel", {
        Text             = name,
        FontFace         = F.Medium,
        TextSize         = TS.Normal,
        TextColor3       = C.Fg,
        TextXAlignment   = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        Position         = UDim2.new(0, 14, 0, 0),
        Size             = UDim2.new(0.45, 0, 1, 0),
        ZIndex           = 2,
        Parent           = frame,
    })

    local displayBg = Inst("Frame", {
        BackgroundColor3 = C.Bg,
        BorderSizePixel  = 0,
        AnchorPoint      = Vector2.new(1, 0.5),
        Position         = UDim2.new(1, -14, 0.5, 0),
        Size             = UDim2.new(0, 160, 0, 26),
        ZIndex           = 2,
        Parent           = frame,
    })
    Stroke(displayBg, C.LineMid, 1)

    local function GetText()
        if multiSelect then
            return #selected > 0 and table.concat(selected, ", ") or "None"
        end
        return tostring(selected)
    end

    local selLbl = Inst("TextLabel", {
        Text             = GetText(),
        FontFace         = F.Regular,
        TextSize         = TS.Small,
        TextColor3       = C.Fg,
        TextXAlignment   = Enum.TextXAlignment.Left,
        TextTruncate     = Enum.TextTruncate.AtEnd,
        BackgroundTransparency = 1,
        Position         = UDim2.new(0, 10, 0, 0),
        Size             = UDim2.new(1, -28, 1, 0),
        ZIndex           = 3,
        Parent           = displayBg,
    })
    local arrow = Inst("TextLabel", {
        Text             = "▾",
        FontFace         = F.Regular,
        TextSize         = TS.Tiny,
        TextColor3       = C.Fg3,
        BackgroundTransparency = 1,
        AnchorPoint      = Vector2.new(1, 0.5),
        Position         = UDim2.new(1, -8, 0.5, 0),
        Size             = UDim2.new(0, 14, 0, 14),
        ZIndex           = 3,
        Parent           = displayBg,
    })

    local maxShow = 5
    local listH   = math.min(#options, maxShow) * 28
    local listFrame = Inst("Frame", {
        BackgroundColor3 = C.Surface,
        BorderSizePixel  = 0,
        Position         = UDim2.new(1, -174, 0, 40),
        Size             = UDim2.new(0, 160, 0, listH),
        Visible          = false,
        ZIndex           = 50,
        ClipsDescendants = true,
        Parent           = frame,
    })
    Stroke(listFrame, C.LineMid, 1)

    local listScroll = Inst("ScrollingFrame", {
        BackgroundTransparency = 1,
        BorderSizePixel  = 0,
        Size             = UDim2.new(1, 0, 1, 0),
        CanvasSize       = UDim2.new(0, 0, 0, #options * 28),
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = C.LineMid,
        ZIndex           = 51,
        Parent           = listFrame,
    })
    List(listScroll, 0)

    local function IsSel(opt)
        return multiSelect and table.find(selected, opt) ~= nil or selected == opt
    end

    local function BuildList()
        for _, c in ipairs(listScroll:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        for _, opt in ipairs(options) do
            local sel = IsSel(opt)
            local ob = Inst("TextButton", {
                Name             = opt,
                Text             = opt,
                FontFace         = sel and F.SemiBold or F.Regular,
                TextSize         = TS.Small,
                TextColor3       = sel and C.Fg or C.Fg2,
                TextXAlignment   = Enum.TextXAlignment.Left,
                BackgroundColor3 = sel and C.Surface2 or C.Surface,
                BackgroundTransparency = sel and 0 or 1,
                BorderSizePixel  = 0,
                Size             = UDim2.new(1, 0, 0, 28),
                ZIndex           = 52,
                Parent           = listScroll,
            })
            Pad(ob, 0, 0, 12, 0)
            ob.MouseEnter:Connect(function()
                ob.BackgroundTransparency = 0
                ob.BackgroundColor3 = C.Surface2
            end)
            ob.MouseLeave:Connect(function()
                ob.BackgroundTransparency = IsSel(opt) and 0 or 1
                if IsSel(opt) then ob.BackgroundColor3 = C.Surface2 end
            end)
            ob.MouseButton1Click:Connect(function()
                if multiSelect then
                    local idx = table.find(selected, opt)
                    if idx then table.remove(selected, idx)
                    else    table.insert(selected, opt) end
                    selLbl.Text = GetText()
                    pcall(callback, selected)
                    BuildList()
                else
                    selected    = opt
                    selLbl.Text = GetText()
                    pcall(callback, selected)
                    expanded         = false
                    listFrame.Visible = false
                    arrow.Text       = "▾"
                    frame.ZIndex     = 1
                    if Library._activeDropdown == Close then Library._activeDropdown = nil end
                    BuildList()
                end
            end)
        end
        listScroll.CanvasSize = UDim2.new(0, 0, 0, #options * 28)
    end
    BuildList()

    function Close()
        expanded          = false
        listFrame.Visible = false
        arrow.Text        = "▾"
        frame.ZIndex      = 1
        if Library._activeDropdown == Close then Library._activeDropdown = nil end
    end

    local toggleBtn = Inst("TextButton", {
        Text = "", BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0), ZIndex = 4, Parent = displayBg,
    })
    toggleBtn.MouseButton1Click:Connect(function()
        if expanded then Close()
        else
            if Library._activeDropdown then Library._activeDropdown() end
            expanded          = true
            listFrame.Visible = true
            arrow.Text        = "▴"
            frame.ZIndex      = 10
            Library._activeDropdown = Close
        end
    end)

    tab._lib._connections["dd_"..tostring(frame)] = UserInputService.InputBegan:Connect(function(inp)
        if not expanded then return end
        if inp.UserInputType ~= Enum.UserInputType.MouseButton1 and
           inp.UserInputType ~= Enum.UserInputType.Touch then return end
        local mp = inp.Position
        local lp, ls = listFrame.AbsolutePosition, listFrame.AbsoluteSize
        local fp, fs = frame.AbsolutePosition,     frame.AbsoluteSize
        local inList = mp.X>=lp.X and mp.X<=lp.X+ls.X and mp.Y>=lp.Y and mp.Y<=lp.Y+ls.Y
        local inHead = mp.X>=fp.X and mp.X<=fp.X+fs.X and mp.Y>=fp.Y and mp.Y<=fp.Y+fs.Y
        if not inList and not inHead then Close() end
    end)

    local methods = {
        SetValue = function(_, v)
            if multiSelect and type(v) == "table" then selected = v
            elseif not multiSelect then selected = v end
            selLbl.Text = GetText()
            BuildList()
            pcall(callback, selected)
        end,
        GetValue = function() return selected end,
        Refresh  = function(_, newOpts)
            options = newOpts
            listFrame.Size = UDim2.new(0, 160, 0, math.min(#options, maxShow) * 28)
            BuildList()
        end,
    }
    tab._lib:_RegConfig(flag,
        function() return selected end,
        function(v) methods:SetValue(v) end)
    return methods
end

--------------------------------------------------
-- COMPONENT: CHECKBOX (sharp square)
--------------------------------------------------
function Library._Checkbox(tab, config)
    local name     = config.Name     or "Checkbox"
    local default  = config.Default  or false
    local callback = config.Callback or function() end
    local flag     = config.Flag
    local enabled  = default

    local frame = Inst("Frame", {
        Name             = "Checkbox_"..name,
        BackgroundColor3 = C.Surface,
        BorderSizePixel  = 0,
        Size             = UDim2.new(1, 0, 0, 38),
        Parent           = tab.content,
    })
    Stroke(frame, C.Line, 1)

    Inst("TextLabel", {
        Text             = name,
        FontFace         = F.Medium,
        TextSize         = TS.Normal,
        TextColor3       = C.Fg,
        TextXAlignment   = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        Position         = UDim2.new(0, 14, 0, 0),
        Size             = UDim2.new(1, -46, 1, 0),
        Parent           = frame,
    })

    local box = Inst("Frame", {
        BackgroundColor3 = enabled and C.Fg or C.Bg,
        BorderSizePixel  = 0,
        AnchorPoint      = Vector2.new(1, 0.5),
        Position         = UDim2.new(1, -14, 0.5, 0),
        Size             = UDim2.new(0, 16, 0, 16),
        Parent           = frame,
    })
    local boxStroke = Stroke(box, enabled and C.Fg or C.LineMid, 1)

    local check = Inst("TextLabel", {
        Text             = "✓",
        FontFace         = F.Bold,
        TextSize         = 10,
        TextColor3       = C.Bg,
        BackgroundTransparency = 1,
        Size             = UDim2.new(1, 0, 1, 0),
        Visible          = enabled,
        Parent           = box,
    })

    local function UpdateVisual()
        box.BackgroundColor3 = enabled and C.Fg or C.Bg
        boxStroke.Color      = enabled and C.Fg or C.LineMid
        check.Visible        = enabled
    end

    local btn = Inst("TextButton", {
        Text = "", BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0), Parent = frame,
    })
    btn.MouseButton1Click:Connect(function()
        enabled = not enabled; UpdateVisual(); pcall(callback, enabled)
    end)

    local methods = {
        SetValue = function(_, v) enabled = v; UpdateVisual(); pcall(callback, enabled) end,
        GetValue = function()    return enabled end,
    }
    tab._lib:_RegConfig(flag,
        function() return enabled end,
        function(v) methods:SetValue(v) end)
    return methods
end

--------------------------------------------------
-- COMPONENT: KEYBIND
--------------------------------------------------
function Library._Keybind(tab, config)
    local name          = config.Name     or "Keybind"
    local default       = config.Default  or Enum.KeyCode.F
    local callback      = config.Callback or function() end
    local linkedToggle  = config.Toggle
    local flag          = config.Flag
    local currentKey    = default
    local listening     = false

    local function Fire()
        if linkedToggle then linkedToggle:SetValue(not linkedToggle:GetValue()) end
        pcall(callback, currentKey)
    end

    local frame = Inst("Frame", {
        Name             = "Keybind_"..name,
        BackgroundColor3 = C.Surface,
        BorderSizePixel  = 0,
        Size             = UDim2.new(1, 0, 0, 38),
        Parent           = tab.content,
    })
    Stroke(frame, C.Line, 1)

    Inst("TextLabel", {
        Text             = name,
        FontFace         = F.Medium,
        TextSize         = TS.Normal,
        TextColor3       = C.Fg,
        TextXAlignment   = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        Position         = UDim2.new(0, 14, 0, 0),
        Size             = UDim2.new(1, -82, 1, 0),
        Parent           = frame,
    })

    local keyBg = Inst("Frame", {
        BackgroundColor3 = C.Bg,
        BorderSizePixel  = 0,
        AnchorPoint      = Vector2.new(1, 0.5),
        Position         = UDim2.new(1, -14, 0.5, 0),
        Size             = UDim2.new(0, 62, 0, 22),
        Parent           = frame,
    })
    Stroke(keyBg, C.LineMid, 1)

    local keyLbl = Inst("TextLabel", {
        Text             = currentKey.Name,
        FontFace         = F.Mono,
        TextSize         = TS.Tiny,
        TextColor3       = C.Fg2,
        BackgroundTransparency = 1,
        Size             = UDim2.new(1, 0, 1, 0),
        Parent           = keyBg,
    })

    local kbBtn = Inst("TextButton", {
        Text = "", BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0), Parent = keyBg,
    })

    local kbId = name..tostring(tick())
    tab._lib._keybinds[kbId] = {key = currentKey, callback = Fire}

    local function UpdateDisplay()
        keyLbl.Text      = listening and "..." or currentKey.Name
        keyLbl.TextColor3 = listening and C.Fg or C.Fg2
    end

    kbBtn.MouseButton1Click:Connect(function()
        listening = true; UpdateDisplay()
    end)

    local conn
    conn = UserInputService.InputBegan:Connect(function(inp, gp)
        if gp or not listening then return end
        local skip = {
            [Enum.KeyCode.LeftShift]=true,   [Enum.KeyCode.RightShift]=true,
            [Enum.KeyCode.LeftControl]=true,  [Enum.KeyCode.RightControl]=true,
            [Enum.KeyCode.LeftAlt]=true,      [Enum.KeyCode.RightAlt]=true,
        }
        if inp.UserInputType == Enum.UserInputType.Keyboard and not skip[inp.KeyCode] then
            currentKey = inp.KeyCode
            listening  = false
            tab._lib._keybinds[kbId].key = currentKey
            UpdateDisplay()
        end
    end)
    tab._lib._connections["kb_"..kbId] = conn

    local methods = {
        SetKey = function(_, k)
            currentKey = k
            tab._lib._keybinds[kbId].key = k
            UpdateDisplay()
        end,
        GetKey = function() return currentKey end,
    }
    tab._lib:_RegConfig(flag,
        function() return currentKey end,
        function(v) methods:SetKey(v) end)
    return methods
end

--------------------------------------------------
-- COMPONENT: COLOR PICKER (compact HSV)
--------------------------------------------------
function Library._ColorPicker(tab, config)
    local name     = config.Name     or "Color"
    local default  = config.Default  or Color3.fromRGB(255, 255, 255)
    local callback = config.Callback or function() end
    local flag     = config.Flag
    local h, s, v  = default:ToHSV()
    local current  = default
    local expanded = false

    local row = Inst("Frame", {
        Name             = "ColorPicker_"..name,
        BackgroundColor3 = C.Surface,
        BorderSizePixel  = 0,
        Size             = UDim2.new(1, 0, 0, 38),
        Parent           = tab.content,
    })
    Stroke(row, C.Line, 1)

    Inst("TextLabel", {
        Text             = name,
        FontFace         = F.Medium,
        TextSize         = TS.Normal,
        TextColor3       = C.Fg,
        TextXAlignment   = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        Position         = UDim2.new(0, 14, 0, 0),
        Size             = UDim2.new(1, -64, 1, 0),
        Parent           = row,
    })

    local preview = Inst("Frame", {
        BackgroundColor3 = current,
        BorderSizePixel  = 0,
        AnchorPoint      = Vector2.new(1, 0.5),
        Position         = UDim2.new(1, -14, 0.5, 0),
        Size             = UDim2.new(0, 44, 0, 18),
        Parent           = row,
    })
    Stroke(preview, C.LineMid, 1)

    local prevBtn = Inst("TextButton", {
        Text = "", BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0), ZIndex = 3, Parent = preview,
    })

    -- Picker floats in ScreenGui so it can't get clipped
    local picker = Inst("Frame", {
        BackgroundColor3 = C.Surface,
        BorderSizePixel  = 0,
        Size             = UDim2.new(0, 172, 0, 122),
        Visible          = false,
        ZIndex           = 3000,
        Parent           = tab._lib.Gui,
    })
    Stroke(picker, C.LineMid, 1)

    -- SV area
    local svArea = Inst("Frame", {
        BackgroundColor3 = Color3.fromHSV(h, 1, 1),
        BorderSizePixel  = 0,
        Position         = UDim2.new(0, 8, 0, 8),
        Size             = UDim2.new(1, -16, 0, 88),
        ZIndex           = 3001,
        Parent           = picker,
    })
    local wLayer = Inst("Frame", {BackgroundColor3=Color3.new(1,1,1),
        Size=UDim2.new(1,0,1,0), ZIndex=3002, Parent=svArea})
    Inst("UIGradient", {
        Color = ColorSequence.new(Color3.new(1,1,1)),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(1, 1)}),
        Parent = wLayer})
    local bLayer = Inst("Frame", {BackgroundColor3=Color3.new(0,0,0),
        Size=UDim2.new(1,0,1,0), ZIndex=3003, Parent=svArea})
    Inst("UIGradient", {
        Rotation = 90,
        Color = ColorSequence.new(Color3.new(0,0,0)),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(1, 0)}),
        Parent = bLayer})

    local svCursor = Inst("Frame", {
        BackgroundColor3 = Color3.new(1,1,1),
        BorderSizePixel  = 0,
        AnchorPoint      = Vector2.new(0.5, 0.5),
        Position         = UDim2.new(s, 0, 1-v, 0),
        Size             = UDim2.new(0, 8, 0, 8),
        ZIndex           = 3005,
        Parent           = svArea,
    })
    Stroke(svCursor, C.Bg, 1)

    -- Hue bar
    local hBar = Inst("Frame", {
        BorderSizePixel = 0,
        Position        = UDim2.new(0, 8, 0, 102),
        Size            = UDim2.new(1, -16, 0, 8),
        ZIndex          = 3001,
        Parent          = picker,
    })
    Inst("UIGradient", {Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,     Color3.fromHSV(0,     1, 1)),
        ColorSequenceKeypoint.new(0.167, Color3.fromHSV(0.167, 1, 1)),
        ColorSequenceKeypoint.new(0.333, Color3.fromHSV(0.333, 1, 1)),
        ColorSequenceKeypoint.new(0.5,   Color3.fromHSV(0.5,   1, 1)),
        ColorSequenceKeypoint.new(0.667, Color3.fromHSV(0.667, 1, 1)),
        ColorSequenceKeypoint.new(0.833, Color3.fromHSV(0.833, 1, 1)),
        ColorSequenceKeypoint.new(1,     Color3.fromHSV(1,     1, 1)),
    }), Parent = hBar})

    local hCursor = Inst("Frame", {
        BackgroundColor3 = Color3.new(1,1,1),
        BorderSizePixel  = 0,
        AnchorPoint      = Vector2.new(0.5, 0.5),
        Position         = UDim2.new(h, 0, 0.5, 0),
        Size             = UDim2.new(0, 8, 0, 12),
        ZIndex           = 3005,
        Parent           = hBar,
    })
    Stroke(hCursor, C.Bg, 1)

    local function UpdateColor()
        current = Color3.fromHSV(h, s, v)
        preview.BackgroundColor3 = current
        svArea.BackgroundColor3  = Color3.fromHSV(h, 1, 1)
        svCursor.Position = UDim2.new(s, 0, 1-v, 0)
        hCursor.Position  = UDim2.new(h, 0, 0.5, 0)
        pcall(callback, current)
    end

    local svDrag, hDrag = false, false
    local function ProcessInput(inp)
        if svDrag then
            local p  = svArea.AbsolutePosition; local sz = svArea.AbsoluteSize
            s = math.clamp((inp.Position.X - p.X) / sz.X, 0, 1)
            v = 1 - math.clamp((inp.Position.Y - p.Y) / sz.Y, 0, 1)
            UpdateColor()
        elseif hDrag then
            local p  = hBar.AbsolutePosition; local sz = hBar.AbsoluteSize
            h = math.clamp((inp.Position.X - p.X) / sz.X, 0, 1)
            UpdateColor()
        end
    end

    svArea.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            svDrag = true; ProcessInput(inp); Library._activeDragger = ProcessInput
        end
    end)
    hBar.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            hDrag = true; ProcessInput(inp); Library._activeDragger = ProcessInput
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            svDrag = false; hDrag = false; Library._activeDragger = nil
        end
    end)

    local function ClosePicker()
        picker.Visible = false; expanded = false
        if Library._activePicker == ClosePicker then Library._activePicker = nil end
    end

    prevBtn.MouseButton1Click:Connect(function()
        if expanded then ClosePicker()
        else
            if Library._activePicker then Library._activePicker() end
            Library._activePicker = ClosePicker
            local vp = game.Workspace.CurrentCamera.ViewportSize
            local bp = preview.AbsolutePosition
            local tx = bp.X - 182
            local ty = bp.Y
            if ty + 130 > vp.Y then ty = vp.Y - 134 end
            if tx < 0 then tx = bp.X + 50 end
            picker.Position = UDim2.new(0, tx, 0, ty)
            picker.Visible  = true
            expanded         = true
        end
    end)

    local methods = {
        SetColor = function(_, col)
            current = col; h, s, v = col:ToHSV(); UpdateColor()
        end,
        GetColor = function() return current end,
    }
    tab._lib:_RegConfig(flag,
        function() return current end,
        function(col) methods:SetColor(col) end)
    return methods
end

--------------------------------------------------
-- COMPONENT: PROGRESS BAR
--------------------------------------------------
function Library._ProgressBar(tab, config)
    local name    = config.Name    or "Progress"
    local min     = config.Min     or 0
    local max     = config.Max     or 100
    local default = config.Default or 0
    local suffix  = config.Suffix  or ""
    local current = math.clamp(default, min, max)

    local frame = Inst("Frame", {
        Name             = "ProgressBar_"..name,
        BackgroundColor3 = C.Surface,
        BorderSizePixel  = 0,
        Size             = UDim2.new(1, 0, 0, 50),
        Parent           = tab.content,
    })
    Stroke(frame, C.Line, 1)

    Inst("TextLabel", {
        Text             = name,
        FontFace         = F.Medium,
        TextSize         = TS.Normal,
        TextColor3       = C.Fg,
        TextXAlignment   = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        Position         = UDim2.new(0, 14, 0, 8),
        Size             = UDim2.new(0.65, 0, 0, 18),
        Parent           = frame,
    })
    local valLbl = Inst("TextLabel", {
        Text             = tostring(current)..suffix,
        FontFace         = F.Mono,
        TextSize         = TS.Small,
        TextColor3       = C.Fg3,
        TextXAlignment   = Enum.TextXAlignment.Right,
        BackgroundTransparency = 1,
        AnchorPoint      = Vector2.new(1, 0),
        Position         = UDim2.new(1, -14, 0, 8),
        Size             = UDim2.new(0, 60, 0, 18),
        Parent           = frame,
    })

    local track = Inst("Frame", {
        BackgroundColor3 = C.Line,
        BorderSizePixel  = 0,
        Position         = UDim2.new(0, 14, 0, 35),
        Size             = UDim2.new(1, -28, 0, 3),
        Parent           = frame,
    })
    local ratio = (max-min) > 0 and (current-min)/(max-min) or 0
    local fill  = Inst("Frame", {
        BackgroundColor3 = C.Fg,
        BorderSizePixel  = 0,
        Size             = UDim2.new(ratio, 0, 1, 0),
        Parent           = track,
    })

    local function Refresh(val)
        current = math.clamp(val, min, max)
        local r = (max-min) > 0 and (current-min)/(max-min) or 0
        Tween(fill, {Size = UDim2.new(r, 0, 1, 0)}, 0.18)
        valLbl.Text = tostring(current)..suffix
    end

    return {
        SetValue = function(_, v) Refresh(v) end,
        GetValue = function()    return current end,
        SetMax   = function(_, v) max = v; Refresh(current) end,
        SetMin   = function(_, v) min = v; Refresh(current) end,
    }
end

--------------------------------------------------
-- COMPONENT: TABLE (editorial style)
--------------------------------------------------
function Library._Table(tab, config)
    local name       = config.Name       or "Table"
    local columns    = config.Columns    or {"Name", "Value"}
    local rowH       = config.RowHeight  or 32
    local maxVisible = config.MaxVisible or 5
    local data       = {}
    local colN       = #columns

    local frame = Inst("Frame", {
        Name             = "Table_"..name,
        BackgroundColor3 = C.Surface,
        BorderSizePixel  = 0,
        AutomaticSize    = Enum.AutomaticSize.Y,
        Size             = UDim2.new(1, 0, 0, 0),
        Parent           = tab.content,
    })
    Stroke(frame, C.Line, 1)

    -- Label bar
    local topBar = Inst("Frame", {
        BackgroundColor3 = C.Surface2,
        BorderSizePixel  = 0,
        Size             = UDim2.new(1, 0, 0, 28),
        Parent           = frame,
    })
    Inst("TextLabel", {
        Text             = string.upper(name),
        FontFace         = F.Bold,
        TextSize         = TS.Tiny,
        TextColor3       = C.Fg3,
        TextXAlignment   = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        Position         = UDim2.new(0, 14, 0, 0),
        Size             = UDim2.new(1, -28, 1, 0),
        Parent           = topBar,
    })
    Divider(frame, 28)

    -- Column headers
    local headerRow = Inst("Frame", {
        BackgroundColor3 = C.Surface2,
        BorderSizePixel  = 0,
        Position         = UDim2.new(0, 0, 0, 29),
        Size             = UDim2.new(1, 0, 0, 26),
        Parent           = frame,
    })
    for i, col in ipairs(columns) do
        local xOff = i == 1 and 14 or 6
        Inst("TextLabel", {
            Text             = string.upper(col),
            FontFace         = F.Bold,
            TextSize         = TS.Tiny,
            TextColor3       = C.Fg3,
            TextXAlignment   = Enum.TextXAlignment.Left,
            BackgroundTransparency = 1,
            Position         = UDim2.new((i-1)/colN, xOff, 0, 0),
            Size             = UDim2.new(1/colN, -xOff, 1, 0),
            Parent           = headerRow,
        })
    end
    Divider(headerRow, 25)

    -- Scrollable body
    local body = Inst("ScrollingFrame", {
        BackgroundTransparency = 1,
        BorderSizePixel  = 0,
        Position         = UDim2.new(0, 0, 0, 55),
        Size             = UDim2.new(1, 0, 0, 0),
        CanvasSize       = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = C.LineMid,
        Parent           = frame,
    })
    List(body, 0)

    local rowFrames = {}

    local function RefreshSizes()
        local vis = math.min(#data, maxVisible)
        body.Size       = UDim2.new(1, 0, 0, vis * rowH)
        body.CanvasSize = UDim2.new(0, 0, 0, #data * rowH)
    end

    local function MakeRow(idx, rowData)
        local r = Inst("Frame", {
            BackgroundColor3 = idx%2==0 and C.Surface2 or C.Surface,
            BorderSizePixel  = 0,
            LayoutOrder      = idx,
            Size             = UDim2.new(1, 0, 0, rowH),
            Parent           = body,
        })
        Divider(r, rowH-1)
        for i = 1, colN do
            local xOff = i == 1 and 14 or 6
            Inst("TextLabel", {
                Text             = tostring(rowData[i] or ""),
                FontFace         = F.Regular,
                TextSize         = TS.Small,
                TextColor3       = C.Fg,
                TextXAlignment   = Enum.TextXAlignment.Left,
                TextTruncate     = Enum.TextTruncate.AtEnd,
                BackgroundTransparency = 1,
                Position         = UDim2.new((i-1)/colN, xOff, 0, 0),
                Size             = UDim2.new(1/colN, -xOff, 1, 0),
                Parent           = r,
            })
        end
        return r
    end

    local function RenderAll()
        for _, r in ipairs(rowFrames) do pcall(function() r:Destroy() end) end
        rowFrames = {}
        for i, d in ipairs(data) do table.insert(rowFrames, MakeRow(i, d)) end
        RefreshSizes()
    end

    RefreshSizes()

    return {
        AddRow    = function(_, d)
            table.insert(data, d)
            table.insert(rowFrames, MakeRow(#data, d))
            RefreshSizes()
        end,
        RemoveRow = function(_, i)
            if data[i] then table.remove(data, i); RenderAll() end
        end,
        ClearRows = function(_) data = {}; RenderAll() end,
        SetData   = function(_, d) data = d; RenderAll() end,
        GetData   = function()    return data end,
    }
end

--------------------------------------------------
-- COMPONENT: BADGE (outlined, uppercase)
--------------------------------------------------
function Library._Badge(tab, config)
    local text  = config.Text  or "Badge"
    -- style: "active" | "inactive" | "neutral" | "danger"
    local style = config.Style or "neutral"

    local palette = {
        active   = C.Fg,
        inactive = C.Fg3,
        neutral  = C.Fg2,
        danger   = C.Danger,
    }
    local col = palette[style] or palette.neutral

    local badge = Inst("TextLabel", {
        Name             = "Badge_"..text,
        Text             = string.upper(text),
        FontFace         = F.Bold,
        TextSize         = TS.Tiny,
        TextColor3       = col,
        BackgroundTransparency = 1,
        AutomaticSize    = Enum.AutomaticSize.X,
        Size             = UDim2.new(0, 0, 0, 22),
        Parent           = tab.content,
    })
    Pad(badge, 0, 0, 10, 10)
    Stroke(badge, col, 1)

    return {
        SetText  = function(_, t) badge.Text = string.upper(t) end,
        SetStyle = function(_, st)
            local nc = palette[st] or palette.neutral
            badge.TextColor3 = nc
            for _, ch in ipairs(badge:GetChildren()) do
                if ch:IsA("UIStroke") then ch.Color = nc end
            end
        end,
    }
end

--------------------------------------------------
-- COMPONENT: RADIO GROUP
--------------------------------------------------
function Library._RadioGroup(tab, config)
    local name     = config.Name     or "Radio"
    local options  = config.Options  or {"Option 1", "Option 2"}
    local default  = config.Default  or options[1]
    local callback = config.Callback or function() end
    local flag     = config.Flag
    local selected = default

    local frame = Inst("Frame", {
        Name             = "RadioGroup_"..name,
        BackgroundColor3 = C.Surface,
        BorderSizePixel  = 0,
        AutomaticSize    = Enum.AutomaticSize.Y,
        Size             = UDim2.new(1, 0, 0, 0),
        Parent           = tab.content,
    })
    Stroke(frame, C.Line, 1)
    Pad(frame, 10, 10, 14, 14)
    List(frame, 5)

    Inst("TextLabel", {
        Name             = "RadioHeader",
        Text             = string.upper(name),
        FontFace         = F.Bold,
        TextSize         = TS.Tiny,
        TextColor3       = C.Fg3,
        TextXAlignment   = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        LayoutOrder      = 0,
        Size             = UDim2.new(1, 0, 0, 18),
        Parent           = frame,
    })

    local optionData = {}

    local function UpdateAll()
        for _, d in pairs(optionData) do
            local sel = d.value == selected
            d.box.BackgroundColor3 = sel and C.Fg or C.Bg
            d.boxStroke.Color      = sel and C.Fg or C.LineMid
            d.dot.Visible          = sel
            d.lbl.TextColor3       = sel and C.Fg or C.Fg2
            d.lbl.FontFace         = sel and F.SemiBold or F.Regular
        end
    end

    for i, opt in ipairs(options) do
        local row = Inst("Frame", {
            BackgroundTransparency = 1,
            LayoutOrder            = i,
            Size                   = UDim2.new(1, 0, 0, 28),
            Parent                 = frame,
        })
        local box = Inst("Frame", {
            BackgroundColor3 = opt==selected and C.Fg or C.Bg,
            BorderSizePixel  = 0,
            AnchorPoint      = Vector2.new(0, 0.5),
            Position         = UDim2.new(0, 0, 0.5, 0),
            Size             = UDim2.new(0, 14, 0, 14),
            Parent           = row,
        })
        local bStroke = Stroke(box, opt==selected and C.Fg or C.LineMid, 1)

        local dot = Inst("Frame", {
            BackgroundColor3 = C.Bg,
            BorderSizePixel  = 0,
            AnchorPoint      = Vector2.new(0.5, 0.5),
            Position         = UDim2.new(0.5, 0, 0.5, 0),
            Size             = UDim2.new(0, 6, 0, 6),
            Visible          = opt == selected,
            Parent           = box,
        })
        local lbl = Inst("TextLabel", {
            Text             = opt,
            FontFace         = opt==selected and F.SemiBold or F.Regular,
            TextSize         = TS.Normal,
            TextColor3       = opt==selected and C.Fg or C.Fg2,
            TextXAlignment   = Enum.TextXAlignment.Left,
            BackgroundTransparency = 1,
            Position         = UDim2.new(0, 24, 0, 0),
            Size             = UDim2.new(1, -24, 1, 0),
            Parent           = row,
        })
        local btn = Inst("TextButton", {
            Text = "", BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0), Parent = row,
        })

        optionData[opt] = {value=opt, box=box, boxStroke=bStroke, dot=dot, lbl=lbl}

        btn.MouseButton1Click:Connect(function()
            selected = opt; UpdateAll(); pcall(callback, selected)
        end)
        btn.MouseEnter:Connect(function() if selected ~= opt then lbl.TextColor3 = C.Fg end end)
        btn.MouseLeave:Connect(function() if selected ~= opt then lbl.TextColor3 = C.Fg2 end end)
    end

    local methods = {
        SetValue = function(_, v) selected = v; UpdateAll(); pcall(callback, selected) end,
        GetValue = function()    return selected end,
    }
    tab._lib:_RegConfig(flag,
        function() return selected end,
        function(v) methods:SetValue(v) end)
    return methods
end

--------------------------------------------------
-- CONFIG SYSTEM
--------------------------------------------------
function Library:SaveConfig(name)
    if not writefile then
        self:Notify({Title="Error", Description="writefile not supported", Error=true})
        return false
    end
    if not isfolder("AstraConfigs") then makefolder("AstraConfigs") end
    local data = {}
    for flag, el in pairs(self._configElements) do
        local ok, val = pcall(el.getValue)
        if ok and val ~= nil then
            if typeof(val) == "Color3" then
                val = {_t="Color3", r=val.R, g=val.G, b=val.B}
            elseif typeof(val) == "EnumItem" then
                val = {_t="Enum", en=tostring(val.EnumType), vl=val.Name}
            end
            data[flag] = val
        end
    end
    local ok2 = pcall(writefile, "AstraConfigs/"..name..".json",
        HttpService:JSONEncode(data))
    if ok2 then
        self._currentConfig = name
        self:Notify({Title="Config Saved", Description=name})
        return true
    end
    self:Notify({Title="Error", Description="Failed to save", Error=true})
    return false
end

function Library:LoadConfig(name)
    if not readfile or not isfile then
        self:Notify({Title="Error", Description="readfile not supported", Error=true})
        return false
    end
    local path = "AstraConfigs/"..name..".json"
    if not isfile(path) then
        self:Notify({Title="Error", Description="Config not found: "..name, Error=true})
        return false
    end
    local ok, data = pcall(function()
        return HttpService:JSONDecode(readfile(path))
    end)
    if not ok or not data then
        self:Notify({Title="Error", Description="Invalid config", Error=true})
        return false
    end
    for flag, val in pairs(data) do
        if self._configElements[flag] then
            if type(val) == "table" and val._t == "Color3" then
                val = Color3.new(val.r, val.g, val.b)
            elseif type(val) == "table" and val._t == "Enum" then
                val = Enum[val.en][val.vl]
            end
            pcall(self._configElements[flag].setValue, val)
        end
    end
    self._currentConfig = name
    self:Notify({Title="Config Loaded", Description=name})
    return true
end

function Library:GetConfigs()
    local list = {}
    if isfolder and listfiles then
        if not isfolder("AstraConfigs") then makefolder("AstraConfigs") end
        for _, f in ipairs(listfiles("AstraConfigs")) do
            local n = f:match("AstraConfigs/(.+)%.json$")
                   or f:match("AstraConfigs\\(.+)%.json$")
            if n then table.insert(list, n) end
        end
    end
    return list
end

function Library:SetAutoSave(enabled)
    self._autoSave = enabled
    if enabled then
        task.spawn(function()
            while self._autoSave and self.Gui and self.Gui.Parent do
                task.wait(30)
                if self._autoSave then self:SaveConfig(self._currentConfig) end
            end
        end)
    end
end

-- CONFIG TAB SECTION (pre-built)
function Library._ConfigSection(tab)
    local lib = tab._lib
    Library._SectionHeader(tab, "Configuration")

    local nameBox = Library._TextBox(tab, {
        Name        = "Config Name",
        Default     = "default",
        Placeholder = "name...",
        Callback    = function(t) lib._currentConfig = t end,
    })

    local dropdown
    dropdown = Library._Dropdown(tab, {
        Name     = "Saved Configs",
        Options  = lib:GetConfigs(),
        Default  = "",
        Callback = function(sel)
            nameBox:SetText(sel)
            lib._currentConfig = sel
        end,
    })

    Library._Button(tab, {
        Name     = "Save Config",
        Style    = "primary",
        Callback = function()
            local n = nameBox:GetText()
            if n ~= "" then
                lib:SaveConfig(n)
                dropdown:Refresh(lib:GetConfigs())
            end
        end,
    })
    Library._Button(tab, {
        Name     = "Load Config",
        Style    = "ghost",
        Callback = function()
            local n = nameBox:GetText()
            if n ~= "" then lib:LoadConfig(n) end
        end,
    })
    Library._Toggle(tab, {
        Name     = "Auto Save (30s)",
        Default  = false,
        Callback = function(v) lib:SetAutoSave(v) end,
    })

    return {
        RefreshConfigs = function() dropdown:Refresh(lib:GetConfigs()) end,
    }
end

return Library
