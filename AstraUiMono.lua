--[[
╔══════════════════════════════════════════════════════════════════════╗
║                   AstraUiLibrary  v2.1  — FIXED                    ║
║           Monochromatic Edition — ASTRA Admin Panel Style           ║
╠══════════════════════════════════════════════════════════════════════╣
║  Bugs fixed in this version:                                        ║
║  · Icon Y-offset (-8) removed — icons now perfectly centered        ║
║  · Dropdown listFrame parented to ScreenGui (no clip by ScrollFrame)║
║  · CloseDropdown properly scoped as local per instance              ║
║  · SectionHeader visually distinct (background + bottom border)     ║
║  · ContentArea no longer uses AutomaticCanvasSize (no UIListLayout) ║
║  · Separator line calculation simplified (no task.defer needed)     ║
╚══════════════════════════════════════════════════════════════════════╝

    Palette (from panel.html):
      Bg        #000000  →  RGB(0,   0,   0  )
      Surface   #0d0d0d  →  RGB(13,  13,  13 )
      Surface2  #141414  →  RGB(20,  20,  20 )
      Line      #1f1f1f  →  RGB(31,  31,  31 )
      LineMid   #2e2e2e  →  RGB(46,  46,  46 )
      Fg        #ffffff  →  RGB(255, 255, 255)
      Fg2       #888888  →  RGB(136, 136, 136)
      Fg3       #444444  →  RGB(68,  68,  68 )
      Danger    #ff3b3b  →  RGB(255, 59,  59 )

    Zero border-radius — everything sharp & editorial.

    Components:
      CreateTab             Sidebar nav tab
      CreateSectionHeader   Uppercase section label with line
      CreateLabel           Text label
      CreateSeparator       Horizontal divider (optional text)
      CreateParagraph       Info card (title + body)
      CreateButton          primary / ghost / danger
      CreateToggle          Sharp rectangular switch
      CreateSlider          Track + square knob
      CreateTextBox         Bordered input (numbers-only option)
      CreateDropdown        Single / multi-select + search
      CreateCheckbox        Sharp square checkbox
      CreateKeybind         Monospace tag + linked toggle dot
      CreateColorPicker     Compact HSV picker
      CreateProgressBar     Animated fill bar
      CreateTable           Editorial table
      CreateBadge           Outlined uppercase badge
      CreateRadioGroup      Square dot radio buttons
      CreateConfigSection   Full save / load / delete UI

    Library methods:
      Library.new(title, options)
      :Toggle()
      :SetToggleKey(keyCode)
      :SetAccentColor(color)
      :SetWatermark(text)
      :Notify(config)
      :SaveConfig(name)  :LoadConfig(name)  :DeleteConfig(name)
      :GetConfigs()      :SetAutoSave(bool)
      :Destroy()
]]

-- ══════════════════════════════════════════════════════════════════════
-- SERVICES
-- ══════════════════════════════════════════════════════════════════════
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players          = game:GetService("Players")
local HttpService      = game:GetService("HttpService")

-- ══════════════════════════════════════════════════════════════════════
-- PALETTE
-- ══════════════════════════════════════════════════════════════════════
local C = {
    Bg       = Color3.fromRGB(0,   0,   0  ),
    Surface  = Color3.fromRGB(13,  13,  13 ),
    Surface2 = Color3.fromRGB(20,  20,  20 ),
    Line     = Color3.fromRGB(31,  31,  31 ),
    LineMid  = Color3.fromRGB(46,  46,  46 ),
    Fg       = Color3.fromRGB(255, 255, 255),
    Fg2      = Color3.fromRGB(136, 136, 136),
    Fg3      = Color3.fromRGB(68,  68,  68 ),
    Danger   = Color3.fromRGB(255, 59,  59 ),
}

-- ══════════════════════════════════════════════════════════════════════
-- TYPOGRAPHY
-- ══════════════════════════════════════════════════════════════════════
local F = {
    Regular  = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular),
    Medium   = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium),
    SemiBold = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold),
    Bold     = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold),
    Black    = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.ExtraBold),
    Mono     = Font.new("rbxasset://fonts/families/RobotoMono.json", Enum.FontWeight.Regular),
}

local TS = { Title = 15, Normal = 13, Small = 12, Tiny = 10 }

local ANIM = { Fast = 0.08, Normal = 0.15, Slow = 0.22 }

-- ══════════════════════════════════════════════════════════════════════
-- LIBRARY
-- ══════════════════════════════════════════════════════════════════════
local Library = {}
Library.__index = Library

Library._activeDragger  = nil
Library._activeDropdown = nil   -- holds CloseDropdown() of the open dropdown
Library._activePicker   = nil   -- holds ClosePicker() of the open color picker

-- Single global mouse-move handler — avoids N connections
UserInputService.InputChanged:Connect(function(input)
    if Library._activeDragger
    and (input.UserInputType == Enum.UserInputType.MouseMovement
      or input.UserInputType == Enum.UserInputType.Touch)
    then
        Library._activeDragger(input)
    end
end)

-- ══════════════════════════════════════════════════════════════════════
-- HELPERS
-- ══════════════════════════════════════════════════════════════════════

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
        Color     = color     or C.Line,
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

local function List(parent, padding, dir)
    return Inst("UIListLayout", {
        Padding             = UDim.new(0, padding or 0),
        FillDirection       = dir or Enum.FillDirection.Vertical,
        SortOrder           = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        Parent              = parent,
    })
end

local function Tween(obj, props, t, style, dir)
    TweenService:Create(obj, TweenInfo.new(
        t     or ANIM.Normal,
        style or Enum.EasingStyle.Quad,
        dir   or Enum.EasingDirection.Out
    ), props):Play()
end

-- 1 px horizontal line
local function HLine(parent, yOff, zIdx)
    return Inst("Frame", {
        BackgroundColor3 = C.Line,
        BorderSizePixel  = 0,
        Position         = UDim2.new(0, 0, 0, yOff or 0),
        Size             = UDim2.new(1, 0, 0, 1),
        ZIndex           = zIdx or 1,
        Parent           = parent,
    })
end

local function MakeDraggable(frame, handle)
    local dragging, ds, sp = false, nil, nil
    handle = handle or frame
    handle.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
        and input.UserInputType ~= Enum.UserInputType.Touch then return end
        dragging = true; ds = input.Position; sp = frame.Position
        Library._activeDragger = function(inp)
            if not dragging then return end
            local d = inp.Position - ds
            frame.Position = UDim2.new(sp.X.Scale, sp.X.Offset+d.X, sp.Y.Scale, sp.Y.Offset+d.Y)
        end
        local c; c = input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false; Library._activeDragger = nil; c:Disconnect()
            end
        end)
    end)
end

-- Config helpers
local CFOLDER = "AstraConfigs"
local function EnsureFolder()
    if isfolder and not isfolder(CFOLDER) then pcall(makefolder, CFOLDER) end
end
local function CfgPath(n) return CFOLDER.."/"..n..".json" end
local function ListConfigs()
    local out = {}
    if not (isfolder and listfiles) then return out end
    EnsureFolder()
    local ok, files = pcall(listfiles, CFOLDER)
    if not ok then return out end
    for _, f in ipairs(files) do
        local n = f:match(CFOLDER.."/(.+)%.json$") or f:match(CFOLDER.."\\(.+)%.json$")
        if n then table.insert(out, n) end
    end
    return out
end

-- ══════════════════════════════════════════════════════════════════════
-- LIBRARY.NEW
-- ══════════════════════════════════════════════════════════════════════
function Library.new(title, options)
    local self    = setmetatable({}, Library)
    local opts    = options or {}

    self.title           = title or "Astra"
    self.tabs            = {}
    self.currentTab      = nil
    self._keybinds       = {}
    self._connections    = {}
    self._configElements = {}
    self._currentConfig  = "default"
    self._autoSave       = false
    self._visible        = true
    self._minimized      = false
    self._toggleKey      = opts.ToggleKey or Enum.KeyCode.RightControl
    self._defaultW       = opts.Width     or 740
    self._defaultH       = opts.Height    or 460
    self._minW           = opts.MinWidth  or 480
    self._minH           = opts.MinHeight or 300
    self._maxW           = opts.MaxWidth  or 1280
    self._maxH           = opts.MaxHeight or 860
    self._origH          = opts.Height    or 460

    if opts.AccentColor then C.Fg = opts.AccentColor end

    self:_Build()
    self:_SetupKeys()
    self:_SetupMobile()
    if opts.Watermark then self:SetWatermark(opts.Watermark) end

    return self
end

-- ══════════════════════════════════════════════════════════════════════
-- WINDOW BUILD
-- ══════════════════════════════════════════════════════════════════════
function Library:_Build()
    local lp = Players.LocalPlayer

    -- ScreenGui
    self.Gui = Inst("ScreenGui", {
        Name           = "AstraV2",
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn   = false,
        Parent         = lp:WaitForChild("PlayerGui"),
    })

    -- Outer container
    self.Container = Inst("Frame", {
        Name             = "Container",
        BackgroundColor3 = C.Bg,
        BorderSizePixel  = 0,
        Size             = UDim2.new(0, self._defaultW, 0, self._defaultH),
        Position         = UDim2.new(0.5, -self._defaultW/2, 0.5, -self._defaultH/2),
        ClipsDescendants = false,
        Parent           = self.Gui,
    })
    Stroke(self.Container, C.Line, 1)

    -- Top bar — 48 px
    self.TopBar = Inst("Frame", {
        Name             = "TopBar",
        BackgroundColor3 = C.Bg,
        BorderSizePixel  = 0,
        Size             = UDim2.new(1, 0, 0, 48),
        ZIndex           = 5,
        Parent           = self.Container,
    })
    HLine(self.TopBar, 47, 5)

    -- Title
    self._titleLabel = Inst("TextLabel", {
        Text           = self.title,
        FontFace       = F.Black,
        TextSize       = TS.Title,
        TextColor3     = C.Fg,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        Position       = UDim2.new(0, 18, 0, 0),
        Size           = UDim2.new(0.6, 0, 1, 0),
        ZIndex         = 6,
        Parent         = self.TopBar,
    })

    self:_BuildControls()
    MakeDraggable(self.Container, self.TopBar)

    -- Body
    self.Body = Inst("Frame", {
        Name           = "Body",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position       = UDim2.new(0, 0, 0, 48),
        Size           = UDim2.new(1, 0, 1, -48),
        Parent         = self.Container,
    })

    -- ── Sidebar wrapper (border lives here, NOT in the ScrollingFrame) ──
    -- IMPORTANT: Any Frame inside a ScrollingFrame with UIListLayout is
    -- treated as a list item — including 1px border frames.
    -- So the right-border lives on a wrapper Frame, outside the scroll.
    self._sidebarWrap = Inst("Frame", {
        Name             = "SidebarWrap",
        BackgroundColor3 = C.Bg,
        BorderSizePixel  = 0,
        Size             = UDim2.new(0, 175, 1, 0),
        Parent           = self.Body,
    })
    -- Right border of sidebar
    Inst("Frame", {
        BackgroundColor3 = C.Line,
        BorderSizePixel  = 0,
        AnchorPoint      = Vector2.new(1, 0),
        Position         = UDim2.new(1, 0, 0, 0),
        Size             = UDim2.new(0, 1, 1, 0),
        ZIndex           = 4,
        Parent           = self._sidebarWrap,
    })

    -- Sidebar ScrollingFrame — contains ONLY nav items
    self.Sidebar = Inst("ScrollingFrame", {
        Name               = "Sidebar",
        BackgroundTransparency = 1,
        BorderSizePixel    = 0,
        Size               = UDim2.new(1, -1, 1, 0),
        ScrollBarThickness = 0,
        CanvasSize         = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        Parent             = self._sidebarWrap,
    })
    List(self.Sidebar, 0)
    Pad(self.Sidebar, 8, 8, 0, 0)

    -- Content area — full size minus sidebar, NO layout (tabs overlay each other)
    self.ContentArea = Inst("Frame", {
        Name            = "ContentArea",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position        = UDim2.new(0, 175, 0, 0),
        Size            = UDim2.new(1, -175, 1, 0),
        ClipsDescendants = true,
        Parent          = self.Body,
    })
    -- No UIListLayout here — each tab fills the whole area

    self:_BuildResize()

    -- Notification holder (top-right corner of screen)
    self._notifHolder = Inst("Frame", {
        Name                  = "NotifHolder",
        BackgroundTransparency = 1,
        AnchorPoint           = Vector2.new(1, 0),
        Position              = UDim2.new(1, -16, 0, 16),
        Size                  = UDim2.new(0, 275, 1, 0),
        ZIndex                = 9999,
        Parent                = self.Gui,
    })
    List(self._notifHolder, 8)
end

-- Window control buttons
function Library:_BuildControls()
    local function CtrlBtn(sym, xOff, hoverCol)
        local b = Inst("TextButton", {
            Text           = sym,
            FontFace       = F.Regular,
            TextSize       = 18,
            TextColor3     = C.Fg3,
            BackgroundTransparency = 1,
            AnchorPoint    = Vector2.new(1, 0.5),
            Position       = UDim2.new(1, xOff, 0.5, 0),
            Size           = UDim2.new(0, 28, 0, 28),
            ZIndex         = 6,
            Parent         = self.TopBar,
        })
        b.MouseEnter:Connect(function() b.TextColor3 = hoverCol end)
        b.MouseLeave:Connect(function() b.TextColor3 = C.Fg3 end)
        return b
    end

    local closeBtn = CtrlBtn("×", -10, C.Danger)
    closeBtn.MouseButton1Click:Connect(function() self:Destroy() end)

    local minBtn = CtrlBtn("−", -42, C.Fg)
    minBtn.MouseButton1Click:Connect(function() self:_ToggleMinimize() end)
end

function Library:_ToggleMinimize()
    self._minimized = not self._minimized
    if self._minimized then
        self._origH = self.Container.AbsoluteSize.Y
        Tween(self.Container, {Size = UDim2.new(0, self.Container.AbsoluteSize.X, 0, 48)})
        task.delay(ANIM.Normal, function()
            if self._minimized then self.Body.Visible = false end
        end)
        if self._resizeBtn then self._resizeBtn.Visible = false end
    else
        self.Body.Visible = true
        Tween(self.Container, {Size = UDim2.new(0, self.Container.AbsoluteSize.X, 0, self._origH)})
        if self._resizeBtn then self._resizeBtn.Visible = true end
    end
end

-- Resize handle
function Library:_BuildResize()
    local handle = Inst("TextButton", {
        Name           = "ResizeHandle",
        Text           = "⌟",
        FontFace       = F.Regular,
        TextSize       = 14,
        TextColor3     = C.Fg3,
        BackgroundTransparency = 1,
        AnchorPoint    = Vector2.new(1, 1),
        Position       = UDim2.new(1, 0, 1, 0),
        Size           = UDim2.new(0, 18, 0, 18),
        ZIndex         = 8,
        Parent         = self.Container,
    })
    self._resizeBtn = handle

    handle.MouseEnter:Connect(function() handle.TextColor3 = C.Fg end)
    handle.MouseLeave:Connect(function() handle.TextColor3 = C.Fg3 end)

    local resizing, rs, ss = false, nil, nil
    handle.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
        and input.UserInputType ~= Enum.UserInputType.Touch then return end
        resizing = true; rs = input.Position; ss = self.Container.AbsoluteSize
        Library._activeDragger = function(inp)
            if not resizing then return end
            local d  = inp.Position - rs
            local nw = math.clamp(ss.X + d.X, self._minW, self._maxW)
            local nh = math.clamp(ss.Y + d.Y, self._minH, self._maxH)
            self.Container.Size = UDim2.new(0, nw, 0, nh)
            self._origH = nh
        end
        local c; c = input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                resizing = false; Library._activeDragger = nil; c:Disconnect()
            end
        end)
    end)
end

-- ══════════════════════════════════════════════════════════════════════
-- KEYS & MOBILE
-- ══════════════════════════════════════════════════════════════════════
function Library:_SetupKeys()
    self._connections["_keys"] = UserInputService.InputBegan:Connect(function(inp, gp)
        if gp then return end
        if inp.KeyCode == self._toggleKey then self:Toggle() end
        for _, kb in pairs(self._keybinds) do
            if inp.KeyCode == kb.key then pcall(kb.callback) end
        end
    end)
end

function Library:_SetupMobile()
    if not (UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled) then return end
    local btn = Inst("TextButton", {
        Text           = "∞",
        FontFace       = F.Black,
        TextSize       = 22,
        TextColor3     = C.Fg,
        BackgroundColor3 = C.Surface,
        BorderSizePixel = 0,
        Size           = UDim2.new(0, 48, 0, 48),
        Position       = UDim2.new(0, 12, 0.5, -24),
        ZIndex         = 9999,
        Visible        = false,
        Parent         = self.Gui,
    })
    Stroke(btn, C.LineMid, 1)
    local drag, ds, sp = false, nil, nil
    btn.InputBegan:Connect(function(i)
        if i.UserInputType ~= Enum.UserInputType.Touch then return end
        drag=true; ds=i.Position; sp=btn.Position
        Library._activeDragger = function(inp)
            if not drag then return end
            local d = inp.Position - ds
            btn.Position = UDim2.new(sp.X.Scale, sp.X.Offset+d.X, sp.Y.Scale, sp.Y.Offset+d.Y)
        end
    end)
    btn.InputEnded:Connect(function(i)
        if i.UserInputType ~= Enum.UserInputType.Touch then return end
        if drag and (i.Position-ds).Magnitude < 10 then self:Toggle() end
        drag=false; Library._activeDragger = nil
    end)
    self._mobileBtn = btn
end

-- ══════════════════════════════════════════════════════════════════════
-- PUBLIC API
-- ══════════════════════════════════════════════════════════════════════
function Library:Toggle()
    self._visible = not self._visible
    self.Container.Visible = self._visible
    if self._mobileBtn then self._mobileBtn.Visible = not self._visible end
end

function Library:SetToggleKey(k) self._toggleKey = k end

function Library:SetAccentColor(color) C.Fg = color end

function Library:SetWatermark(text)
    if self._watermarkLabel then self._watermarkLabel.Text = text; return end
    self._watermarkLabel = Inst("TextLabel", {
        Text           = text,
        FontFace       = F.Mono,
        TextSize       = TS.Tiny,
        TextColor3     = C.Fg3,
        TextXAlignment = Enum.TextXAlignment.Right,
        BackgroundTransparency = 1,
        AnchorPoint    = Vector2.new(1, 1),
        Position       = UDim2.new(1, -10, 1, -6),
        Size           = UDim2.new(0, 340, 0, 14),
        ZIndex         = 10,
        Parent         = self.Gui,
    })
end

function Library:Destroy()
    if self._autoSave then pcall(function() self:SaveConfig(self._currentConfig) end) end
    for _, c in pairs(self._connections) do
        if typeof(c) == "RBXScriptConnection" then pcall(function() c:Disconnect() end) end
    end
    if self.Gui then self.Gui:Destroy() end
end

-- ══════════════════════════════════════════════════════════════════════
-- NOTIFICATIONS  (toast, top-right)
-- ══════════════════════════════════════════════════════════════════════
function Library:Notify(cfg)
    local title    = cfg.Title       or "Notification"
    local desc     = cfg.Description or ""
    local duration = cfg.Duration    or 3
    local isErr    = cfg.Error       or false
    local icon     = cfg.Icon

    local accent = isErr and C.Danger or C.Fg
    local border = isErr and C.Danger or C.LineMid

    local card = Inst("Frame", {
        BackgroundColor3 = C.Surface,
        BorderSizePixel  = 0,
        Size             = UDim2.new(1, 0, 0, 68),
        Position         = UDim2.new(1, 20, 0, 0),
        ClipsDescendants = true,
        ZIndex           = 9999,
        Parent           = self._notifHolder,
    })
    Stroke(card, border, 1)

    Inst("TextLabel", {
        Text           = title,
        FontFace       = F.Bold,
        TextSize       = TS.Normal,
        TextColor3     = accent,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        Position       = UDim2.new(0, 14, 0, 13),
        Size           = UDim2.new(1, icon and -46 or -28, 0, 18),
        ZIndex         = 10000,
        Parent         = card,
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
        Size           = UDim2.new(1, icon and -46 or -28, 0, 16),
        ZIndex         = 10000,
        Parent         = card,
    })
    if icon then
        Inst("ImageLabel", {
            Image          = icon,
            BackgroundTransparency = 1,
            AnchorPoint    = Vector2.new(1, 0.5),
            Position       = UDim2.new(1, -14, 0.5, 0),
            Size           = UDim2.new(0, 20, 0, 20),
            ZIndex         = 10000,
            Parent         = card,
        })
    end
    local bar = Inst("Frame", {
        BackgroundColor3 = accent,
        BorderSizePixel  = 0,
        Position         = UDim2.new(0, 0, 1, -2),
        Size             = UDim2.new(1, 0, 0, 2),
        ZIndex           = 10000,
        Parent           = card,
    })

    Tween(card, {Position = UDim2.new(0, 0, 0, 0)}, ANIM.Slow, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    Tween(bar,  {Size = UDim2.new(0, 0, 0, 2)}, duration, Enum.EasingStyle.Linear)

    task.delay(duration, function()
        Tween(card, {Position = UDim2.new(1, 20, 0, 0)}, ANIM.Normal, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
        task.wait(ANIM.Normal + 0.05)
        pcall(function() card:Destroy() end)
    end)
    return card
end

-- ══════════════════════════════════════════════════════════════════════
-- CONFIG REGISTRATION
-- ══════════════════════════════════════════════════════════════════════
function Library:_Reg(flag, getter, setter)
    if flag and flag ~= "" then
        self._configElements[flag] = {getValue = getter, setValue = setter}
    end
end

-- ══════════════════════════════════════════════════════════════════════
-- CONFIG SAVE / LOAD / DELETE
-- ══════════════════════════════════════════════════════════════════════
function Library:SaveConfig(name)
    if not writefile then self:Notify({Title="Error",Description="writefile not supported",Error=true}); return false end
    EnsureFolder()
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
    local ok2, err = pcall(writefile, CfgPath(name), HttpService:JSONEncode(data))
    if ok2 then
        self._currentConfig = name
        self:Notify({Title="Config Saved", Description=name})
        return true
    end
    self:Notify({Title="Error", Description="Save failed", Error=true})
    return false
end

function Library:LoadConfig(name)
    if not (readfile and isfile) then self:Notify({Title="Error",Description="readfile not supported",Error=true}); return false end
    if not isfile(CfgPath(name)) then self:Notify({Title="Error",Description="Not found: "..name,Error=true}); return false end
    local ok, data = pcall(function() return HttpService:JSONDecode(readfile(CfgPath(name))) end)
    if not ok or type(data)~="table" then self:Notify({Title="Error",Description="Invalid config",Error=true}); return false end
    for flag, val in pairs(data) do
        if self._configElements[flag] then
            if type(val)=="table" and val._t=="Color3" then val = Color3.new(val.r,val.g,val.b)
            elseif type(val)=="table" and val._t=="Enum" then val = Enum[val.en][val.vl] end
            pcall(self._configElements[flag].setValue, val)
        end
    end
    self._currentConfig = name
    self:Notify({Title="Config Loaded", Description=name})
    return true
end

function Library:DeleteConfig(name)
    if not (delfile and isfile) then return false end
    if isfile(CfgPath(name)) then
        pcall(delfile, CfgPath(name))
        self:Notify({Title="Config Deleted", Description=name})
        return true
    end
    return false
end

function Library:GetConfigs() return ListConfigs() end

function Library:SetAutoSave(enabled)
    self._autoSave = enabled
    if enabled then
        task.spawn(function()
            while self._autoSave and self.Gui and self.Gui.Parent do
                task.wait(30)
                if self._autoSave then pcall(function() self:SaveConfig(self._currentConfig) end) end
            end
        end)
    end
end

-- ══════════════════════════════════════════════════════════════════════
-- TAB SYSTEM
-- ══════════════════════════════════════════════════════════════════════
function Library:CreateTab(name, icon)

    -- ── Nav item (sidebar) ────────────────────────────────────────────
    local navItem = Inst("Frame", {
        Name             = "NavItem_"..name,
        BackgroundColor3 = C.Bg,
        BackgroundTransparency = 1,
        BorderSizePixel  = 0,
        Size             = UDim2.new(1, 0, 0, 38),
        Parent           = self.Sidebar,
    })

    -- Left accent stripe (2 px, shown when active)
    local stripe = Inst("Frame", {
        BackgroundColor3     = C.Fg,
        BackgroundTransparency = 1,
        BorderSizePixel      = 0,
        Size                 = UDim2.new(0, 2, 1, 0),
        ZIndex               = 2,
        Parent               = navItem,
    })

    -- Icon — FIX: no Y offset. AnchorPoint (0, 0.5) + Y scale 0.5 = perfectly centered.
    local iconImg = Inst("ImageLabel", {
        Name             = "Icon",
        Image            = icon or "rbxassetid://112235310154264",
        ImageColor3      = C.Fg3,
        BackgroundTransparency = 1,
        AnchorPoint      = Vector2.new(0, 0.5),
        Position         = UDim2.new(0, 12, 0.5, 0),   -- ← was (0,20,0.5,-8), -8 caused the offset
        Size             = UDim2.new(0, 16, 0, 16),
        ZIndex           = 2,
        Parent           = navItem,
    })

    -- Label — starts right after icon (12 + 16 + 8 = 36)
    local navText = Inst("TextLabel", {
        Name             = "NavText",
        Text             = name,
        FontFace         = F.Medium,
        TextSize         = TS.Normal,
        TextColor3       = C.Fg2,
        TextXAlignment   = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        AnchorPoint      = Vector2.new(0, 0.5),
        Position         = UDim2.new(0, 36, 0.5, 0),   -- ← anchored to 0.5 Y so it stays centered
        Size             = UDim2.new(1, -44, 0, 18),
        ZIndex           = 2,
        Parent           = navItem,
    })

    -- Click area
    local click = Inst("TextButton", {
        Text = "", BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0), ZIndex = 3, Parent = navItem,
    })

    -- ── Content ScrollingFrame (fills ContentArea, tabs overlay each other) ──
    local content = Inst("ScrollingFrame", {
        Name                  = name.."_Content",
        BackgroundTransparency = 1,
        BorderSizePixel       = 0,
        -- Fill the whole ContentArea.  Only one is Visible at a time.
        Size                  = UDim2.new(1, 0, 1, 0),
        CanvasSize            = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize   = Enum.AutomaticSize.Y,
        ScrollBarThickness    = 2,
        ScrollBarImageColor3  = C.LineMid,
        ScrollingDirection    = Enum.ScrollingDirection.Y,
        -- ClipsDescendants = false so dropdown/colorpicker lists
        -- that are parented to ScreenGui aren't affected, but this
        -- frame itself will still clip at ContentArea (which does clip).
        ClipsDescendants      = true,
        Visible               = false,
        Parent                = self.ContentArea,
    })
    List(content, 8)
    Pad(content, 18, 18, 18, 18)

    -- Tab record
    local tab = {
        name    = name,
        navItem = navItem,
        stripe  = stripe,
        icon    = iconImg,
        text    = navText,
        content = content,
        _lib    = self,
    }

    -- Hover
    click.MouseEnter:Connect(function()
        if self.currentTab == tab then return end
        navItem.BackgroundTransparency = 0.88
        navItem.BackgroundColor3       = C.Fg
        navText.TextColor3             = C.Fg
        iconImg.ImageColor3            = C.Fg2
    end)
    click.MouseLeave:Connect(function()
        if self.currentTab == tab then return end
        navItem.BackgroundTransparency = 1
        navText.TextColor3             = C.Fg2
        iconImg.ImageColor3            = C.Fg3
    end)
    click.MouseButton1Click:Connect(function() self:_SelectTab(tab) end)

    table.insert(self.tabs, tab)
    if not self.currentTab then self:_SelectTab(tab) end

    -- Wrap with component methods
    local m = setmetatable({}, {__index = tab})
    function m:CreateSectionHeader(n)  return Library._SectionHeader(self, n) end
    function m:CreateLabel(c)          return Library._Label(self, c) end
    function m:CreateSeparator(c)      return Library._Separator(self, c) end
    function m:CreateParagraph(c)      return Library._Paragraph(self, c) end
    function m:CreateButton(c)         return Library._Button(self, c) end
    function m:CreateToggle(c)         return Library._Toggle(self, c) end
    function m:CreateSlider(c)         return Library._Slider(self, c) end
    function m:CreateTextBox(c)        return Library._TextBox(self, c) end
    function m:CreateDropdown(c)       return Library._Dropdown(self, c) end
    function m:CreateCheckbox(c)       return Library._Checkbox(self, c) end
    function m:CreateKeybind(c)        return Library._Keybind(self, c) end
    function m:CreateColorPicker(c)    return Library._ColorPicker(self, c) end
    function m:CreateProgressBar(c)    return Library._ProgressBar(self, c) end
    function m:CreateTable(c)          return Library._Table(self, c) end
    function m:CreateBadge(c)          return Library._Badge(self, c) end
    function m:CreateRadioGroup(c)     return Library._RadioGroup(self, c) end
    function m:CreateConfigSection()   return Library._ConfigSection(self) end
    return m
end

function Library:_SelectTab(tab)
    if self.currentTab then
        local p = self.currentTab
        p.content.Visible               = false
        p.navItem.BackgroundTransparency = 1
        p.stripe.BackgroundTransparency  = 1
        p.text.TextColor3               = C.Fg2
        p.text.FontFace                 = F.Medium
        p.icon.ImageColor3              = C.Fg3
    end
    self.currentTab                     = tab
    tab.content.Visible                 = true
    tab.navItem.BackgroundTransparency  = 0
    tab.navItem.BackgroundColor3        = C.Surface
    tab.stripe.BackgroundTransparency   = 0
    tab.text.TextColor3                 = C.Fg
    tab.text.FontFace                   = F.SemiBold
    tab.icon.ImageColor3                = C.Fg
    tab.content.CanvasPosition          = Vector2.zero
end

-- ══════════════════════════════════════════════════════════════════════
-- COMPONENT: SECTION HEADER
-- Visually distinct: uppercase label + bottom border line
-- ══════════════════════════════════════════════════════════════════════
function Library._SectionHeader(tab, name)
    local wrap = Inst("Frame", {
        Name             = "SectionHeader_"..name,
        BackgroundTransparency = 1,
        BorderSizePixel  = 0,
        Size             = UDim2.new(1, 0, 0, 28),
        Parent           = tab.content,
    })
    Inst("TextLabel", {
        Text           = string.upper(name),
        FontFace       = F.Bold,
        TextSize       = TS.Tiny,
        TextColor3     = C.Fg2,         -- brighter than Fg3 so it's readable
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        AnchorPoint    = Vector2.new(0, 1),
        Position       = UDim2.new(0, 0, 1, -5),
        Size           = UDim2.new(1, 0, 0, 14),
        Parent         = wrap,
    })
    -- Bottom accent line — makes the section stand out
    HLine(wrap, 27)
    return wrap
end

-- ══════════════════════════════════════════════════════════════════════
-- COMPONENT: LABEL
-- ══════════════════════════════════════════════════════════════════════
function Library._Label(tab, cfg)
    local lbl = Inst("TextLabel", {
        Text           = cfg.Text     or "Label",
        FontFace       = F.Regular,
        TextSize       = cfg.TextSize or TS.Normal,
        TextColor3     = cfg.Color    or C.Fg2,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped    = true,
        BackgroundTransparency = 1,
        AutomaticSize  = Enum.AutomaticSize.Y,
        Size           = UDim2.new(1, 0, 0, 0),
        Parent         = tab.content,
    })
    return {
        SetText  = function(_, t) lbl.Text = t end,
        SetColor = function(_, c) lbl.TextColor3 = c end,
        GetText  = function()     return lbl.Text end,
    }
end

-- ══════════════════════════════════════════════════════════════════════
-- COMPONENT: SEPARATOR
-- ══════════════════════════════════════════════════════════════════════
function Library._Separator(tab, cfg)
    local text = cfg and cfg.Text

    local wrap = Inst("Frame", {
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        Size                   = UDim2.new(1, 0, 0, 18),
        Parent                 = tab.content,
    })

    if text and text ~= "" then
        -- Simple layout: short line — label — short line
        Inst("Frame", {
            BackgroundColor3 = C.Line, BorderSizePixel = 0,
            AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0),
            Size = UDim2.new(0.08, 0, 0, 1), Parent = wrap,
        })
        Inst("TextLabel", {
            Text = string.upper(text), FontFace = F.Bold, TextSize = TS.Tiny,
            TextColor3 = C.Fg3, BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0),
            AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0, 0, 1, 0),
            Parent = wrap,
        })
        Inst("Frame", {
            BackgroundColor3 = C.Line, BorderSizePixel = 0,
            AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
            Size = UDim2.new(0.08, 0, 0, 1), Parent = wrap,
        })
    else
        Inst("Frame", {
            BackgroundColor3 = C.Line, BorderSizePixel = 0,
            AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0),
            Size = UDim2.new(1, 0, 0, 1), Parent = wrap,
        })
    end
    return wrap
end

-- ══════════════════════════════════════════════════════════════════════
-- COMPONENT: PARAGRAPH
-- ══════════════════════════════════════════════════════════════════════
function Library._Paragraph(tab, cfg)
    local frame = Inst("Frame", {
        BackgroundColor3 = C.Surface,
        BorderSizePixel  = 0,
        AutomaticSize    = Enum.AutomaticSize.Y,
        Size             = UDim2.new(1, 0, 0, 0),
        Parent           = tab.content,
    })
    Stroke(frame, C.Line, 1)
    Pad(frame, 12, 12, 12, 12)

    local titleLbl = Inst("TextLabel", {
        Text = cfg.Title or "Title", FontFace = F.SemiBold, TextSize = TS.Normal,
        TextColor3 = C.Fg, TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 20), Parent = frame,
    })
    local contLbl = Inst("TextLabel", {
        Text = cfg.Content or "", FontFace = F.Regular, TextSize = TS.Small,
        TextColor3 = C.Fg2, TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true, BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y,
        Position = UDim2.new(0, 0, 0, 24), Size = UDim2.new(1, 0, 0, 0),
        Parent = frame,
    })
    return {
        SetTitle   = function(_, t) titleLbl.Text = t end,
        SetContent = function(_, t) contLbl.Text  = t end,
    }
end

-- ══════════════════════════════════════════════════════════════════════
-- COMPONENT: BUTTON
-- ══════════════════════════════════════════════════════════════════════
function Library._Button(tab, cfg)
    local name     = cfg.Name     or "Button"
    local style    = cfg.Style    or "primary"
    local callback = cfg.Callback or function() end

    local bgN, bgH, bgC, fg, sc
    if style == "primary" then
        bgN=C.Fg; bgH=Color3.fromRGB(210,210,210); bgC=Color3.fromRGB(160,160,160); fg=C.Bg
    elseif style == "danger" then
        bgN=C.Bg; bgH=Color3.fromRGB(14,0,0); bgC=Color3.fromRGB(28,0,0); fg=C.Danger; sc=C.Danger
    else -- ghost
        bgN=C.Bg; bgH=C.Surface2; bgC=C.Surface; fg=C.Fg; sc=C.LineMid
    end

    local frame = Inst("Frame", {
        Name = "Button_"..name, BackgroundColor3 = bgN,
        BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 36), Parent = tab.content,
    })
    if sc then Stroke(frame, sc, 1) end

    local lbl = Inst("TextLabel", {
        Text = name, FontFace = F.SemiBold, TextSize = TS.Normal,
        TextColor3 = fg, BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0), Parent = frame,
    })
    local btn = Inst("TextButton", {
        Text = "", BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0), Parent = frame,
    })
    btn.MouseEnter:Connect(function()    Tween(frame, {BackgroundColor3 = bgH}, ANIM.Fast) end)
    btn.MouseLeave:Connect(function()    Tween(frame, {BackgroundColor3 = bgN}, ANIM.Fast) end)
    btn.MouseButton1Down:Connect(function() Tween(frame, {BackgroundColor3 = bgC}, ANIM.Fast) end)
    btn.MouseButton1Up:Connect(function()   Tween(frame, {BackgroundColor3 = bgH}, ANIM.Fast) end)
    btn.MouseButton1Click:Connect(function() pcall(callback) end)

    return {
        SetText = function(_, t) lbl.Text = t end,
        GetText = function()     return lbl.Text end,
    }
end

-- ══════════════════════════════════════════════════════════════════════
-- COMPONENT: TOGGLE
-- ══════════════════════════════════════════════════════════════════════
function Library._Toggle(tab, cfg)
    local name     = cfg.Name     or "Toggle"
    local default  = cfg.Default  or false
    local callback = cfg.Callback or function() end
    local flag     = cfg.Flag
    local enabled  = default

    local frame = Inst("Frame", {
        Name = "Toggle_"..name, BackgroundColor3 = C.Surface,
        BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 38), Parent = tab.content,
    })
    Stroke(frame, C.Line, 1)

    local rowBtn = Inst("TextButton", {
        Text = "", BackgroundTransparency = 1, Size = UDim2.new(1,0,1,0), Parent = frame,
    })
    rowBtn.MouseEnter:Connect(function() Tween(frame,{BackgroundColor3=C.Surface2},ANIM.Fast) end)
    rowBtn.MouseLeave:Connect(function() Tween(frame,{BackgroundColor3=C.Surface},ANIM.Fast) end)

    Inst("TextLabel", {
        Text=name, FontFace=F.Medium, TextSize=TS.Normal, TextColor3=C.Fg,
        TextXAlignment=Enum.TextXAlignment.Left, BackgroundTransparency=1,
        AnchorPoint=Vector2.new(0,0.5), Position=UDim2.new(0,14,0.5,0),
        Size=UDim2.new(1,-66,0,18), Parent=frame,
    })

    local track = Inst("Frame", {
        BackgroundColor3 = enabled and C.Fg or C.Surface2,
        BorderSizePixel  = 0,
        AnchorPoint      = Vector2.new(1, 0.5),
        Position         = UDim2.new(1, -14, 0.5, 0),
        Size             = UDim2.new(0, 38, 0, 18),
        ZIndex           = 2,
        Parent           = frame,
    })
    local trackStroke = Stroke(track, enabled and C.Fg or C.LineMid, 1)

    local dot = Inst("Frame", {
        BackgroundColor3 = enabled and C.Bg or C.Fg3,
        BorderSizePixel  = 0,
        AnchorPoint      = Vector2.new(0, 0.5),
        Position         = enabled and UDim2.new(0,22,0.5,0) or UDim2.new(0,4,0.5,0),
        Size             = UDim2.new(0, 12, 0, 12),
        ZIndex           = 3,
        Parent           = track,
    })

    local function SetVisual(on)
        Tween(track, {BackgroundColor3 = on and C.Fg or C.Surface2}, ANIM.Fast)
        Tween(dot,   {BackgroundColor3 = on and C.Bg or C.Fg3},      ANIM.Fast)
        Tween(dot,   {Position = on and UDim2.new(0,22,0.5,0) or UDim2.new(0,4,0.5,0)}, ANIM.Fast)
        trackStroke.Color = on and C.Fg or C.LineMid
    end

    rowBtn.MouseButton1Click:Connect(function()
        enabled = not enabled; SetVisual(enabled); pcall(callback, enabled)
    end)

    local methods = {
        SetValue = function(_, v) enabled=v; SetVisual(v); pcall(callback,v) end,
        GetValue = function()    return enabled end,
    }
    tab._lib:_Reg(flag, function() return enabled end, function(v) methods:SetValue(v) end)
    return methods
end

-- ══════════════════════════════════════════════════════════════════════
-- COMPONENT: SLIDER
-- ══════════════════════════════════════════════════════════════════════
function Library._Slider(tab, cfg)
    local name     = cfg.Name     or "Slider"
    local min      = cfg.Min      or 0
    local max      = cfg.Max      or 100
    local default  = cfg.Default  or min
    local step     = cfg.Step     or 1
    local suffix   = cfg.Suffix   or ""
    local callback = cfg.Callback or function() end
    local flag     = cfg.Flag

    local decimals = 0
    local dot = tostring(step):find("%.")
    if dot then decimals = #tostring(step) - dot end

    local function Snap(v)
        local s = math.floor((v-min)/step+0.5)*step+min
        s = math.clamp(s, min, max)
        if decimals > 0 then
            local m = 10^decimals
            return math.floor(s*m+0.5)/m
        end
        return math.floor(s+0.5)
    end
    local function Fmt(v)
        if decimals > 0 then return string.format("%."..decimals.."f",v)..suffix end
        return tostring(math.floor(v))..suffix
    end

    local cur = Snap(math.clamp(default, min, max))

    local frame = Inst("Frame", {
        Name = "Slider_"..name, BackgroundColor3 = C.Surface,
        BorderSizePixel = 0, Size = UDim2.new(1,0,0,52), Parent = tab.content,
    })
    Stroke(frame, C.Line, 1)

    Inst("TextLabel", {
        Text=name, FontFace=F.Medium, TextSize=TS.Normal, TextColor3=C.Fg,
        TextXAlignment=Enum.TextXAlignment.Left, BackgroundTransparency=1,
        AnchorPoint=Vector2.new(0,0.5), Position=UDim2.new(0,14,0,17),
        Size=UDim2.new(0.6,-14,0,18), Parent=frame,
    })
    local valLbl = Inst("TextLabel", {
        Text=Fmt(cur), FontFace=F.Mono, TextSize=TS.Small, TextColor3=C.Fg2,
        TextXAlignment=Enum.TextXAlignment.Right, BackgroundTransparency=1,
        AnchorPoint=Vector2.new(1,0), Position=UDim2.new(1,-14,0,8),
        Size=UDim2.new(0,80,0,18), Parent=frame,
    })

    local trackBg = Inst("Frame", {
        BackgroundColor3=C.Line, BorderSizePixel=0,
        Position=UDim2.new(0,14,0,36), Size=UDim2.new(1,-28,0,3), Parent=frame,
    })
    local pct0 = (cur-min)/math.max(max-min,0.001)
    local fill = Inst("Frame", {
        BackgroundColor3=C.Fg, BorderSizePixel=0,
        Size=UDim2.new(pct0,0,1,0), Parent=trackBg,
    })
    local knob = Inst("Frame", {
        BackgroundColor3=C.Fg, BorderSizePixel=0,
        AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.new(pct0,0,0.5,0),
        Size=UDim2.new(0,10,0,10), ZIndex=2, Parent=trackBg,
    })
    local hit = Inst("TextButton", {
        Text="", BackgroundTransparency=1,
        Position=UDim2.new(0,0,-1,0), Size=UDim2.new(1,0,3,0), ZIndex=3, Parent=trackBg,
    })

    local function Apply(inp)
        local rel = math.clamp((inp.Position.X - trackBg.AbsolutePosition.X)/trackBg.AbsoluteSize.X, 0, 1)
        cur = Snap(min + (max-min)*rel)
        local pct = (cur-min)/math.max(max-min,0.001)
        fill.Size=UDim2.new(pct,0,1,0); knob.Position=UDim2.new(pct,0,0.5,0)
        valLbl.Text=Fmt(cur); pcall(callback,cur)
    end

    hit.InputBegan:Connect(function(inp)
        if inp.UserInputType~=Enum.UserInputType.MouseButton1 and inp.UserInputType~=Enum.UserInputType.Touch then return end
        Apply(inp); Library._activeDragger = Apply
    end)
    hit.InputEnded:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
            Library._activeDragger = nil
        end
    end)

    local methods = {
        SetValue = function(_,v)
            cur=Snap(math.clamp(v,min,max)); local pct=(cur-min)/math.max(max-min,0.001)
            fill.Size=UDim2.new(pct,0,1,0); knob.Position=UDim2.new(pct,0,0.5,0)
            valLbl.Text=Fmt(cur); pcall(callback,cur)
        end,
        GetValue = function() return cur end,
        SetMin   = function(_,v) min=v end,
        SetMax   = function(_,v) max=v end,
    }
    tab._lib:_Reg(flag, function() return cur end, function(v) methods:SetValue(v) end)
    return methods
end

-- ══════════════════════════════════════════════════════════════════════
-- COMPONENT: TEXT BOX
-- ══════════════════════════════════════════════════════════════════════
function Library._TextBox(tab, cfg)
    local name        = cfg.Name         or "TextBox"
    local default     = cfg.Default      or ""
    local placeholder = cfg.Placeholder  or "Enter text..."
    local numbersOnly = cfg.NumbersOnly  or false
    local clearFocus  = cfg.ClearOnFocus or false
    local callback    = cfg.Callback     or function() end
    local flag        = cfg.Flag
    local cur         = tostring(default)

    local frame = Inst("Frame", {
        Name="TextBox_"..name, BackgroundColor3=C.Surface,
        BorderSizePixel=0, Size=UDim2.new(1,0,0,38), Parent=tab.content,
    })
    Stroke(frame, C.Line, 1)

    Inst("TextLabel", {
        Text=name, FontFace=F.Medium, TextSize=TS.Normal, TextColor3=C.Fg,
        TextXAlignment=Enum.TextXAlignment.Left, BackgroundTransparency=1,
        AnchorPoint=Vector2.new(0,0.5), Position=UDim2.new(0,14,0.5,0),
        Size=UDim2.new(0.45,-14,0,18), Parent=frame,
    })

    local inputBg = Inst("Frame", {
        BackgroundColor3=C.Bg, BorderSizePixel=0,
        AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,-14,0.5,0),
        Size=UDim2.new(0,175,0,26), Parent=frame,
    })
    local inputStroke = Stroke(inputBg, C.LineMid, 1)

    local input = Inst("TextBox", {
        Text=cur, PlaceholderText=placeholder, PlaceholderColor3=C.Fg3,
        FontFace=F.Mono, TextSize=TS.Small, TextColor3=C.Fg,
        TextXAlignment=Enum.TextXAlignment.Left, BackgroundTransparency=1,
        ClearTextOnFocus=clearFocus, Position=UDim2.new(0,8,0,0),
        Size=UDim2.new(1,-16,1,0), Parent=inputBg,
    })

    input.Focused:Connect(function()
        Tween(inputBg,{BackgroundColor3=C.Surface2},ANIM.Fast); inputStroke.Color=C.Fg
    end)
    input.FocusLost:Connect(function(enter)
        Tween(inputBg,{BackgroundColor3=C.Bg},ANIM.Fast); inputStroke.Color=C.LineMid
        if numbersOnly then
            local n = tonumber(input.Text)
            if n then cur=tostring(n); input.Text=cur else input.Text=cur end
        else cur=input.Text end
        pcall(callback, cur, enter)
    end)
    if numbersOnly then
        input:GetPropertyChangedSignal("Text"):Connect(function()
            local f=input.Text:gsub("[^%d%.%-]",""); if input.Text~=f then input.Text=f end
        end)
    end

    local methods = {
        SetText        = function(_,t) cur=tostring(t); input.Text=cur end,
        GetText        = function()    return cur end,
        SetPlaceholder = function(_,t) input.PlaceholderText=t end,
        Focus          = function()    input:CaptureFocus() end,
    }
    tab._lib:_Reg(flag, function() return cur end, function(v) methods:SetText(v) end)
    return methods
end

-- ══════════════════════════════════════════════════════════════════════
-- COMPONENT: DROPDOWN
-- FIX: listFrame is parented to ScreenGui and positioned absolutely.
--      This prevents clipping from the tab's ScrollingFrame.
--      CloseDropdown is a local per-instance function.
-- ══════════════════════════════════════════════════════════════════════
function Library._Dropdown(tab, cfg)
    local name        = cfg.Name        or "Dropdown"
    local options     = cfg.Options     or {}
    local multiSelect = cfg.MultiSelect or false
    local callback    = cfg.Callback    or function() end
    local flag        = cfg.Flag
    local lib         = tab._lib

    local selected
    if multiSelect then
        selected = (type(cfg.Default)=="table") and cfg.Default or {}
    else
        selected = cfg.Default or (options[1] or "")
    end

    local expanded   = false
    local showSearch = (cfg.SearchBox ~= false) and (#options > 5)
    local maxVisible = 5
    local optionH    = 28

    -- ── Row (inside tab content) ──────────────────────────────────────
    local frame = Inst("Frame", {
        Name="Dropdown_"..name, BackgroundColor3=C.Surface,
        BorderSizePixel=0, Size=UDim2.new(1,0,0,38),
        ClipsDescendants=false, ZIndex=1, Parent=tab.content,
    })
    Stroke(frame, C.Line, 1)

    local rowBtn = Inst("TextButton", {
        Text="", BackgroundTransparency=1, Size=UDim2.new(1,0,1,0), ZIndex=2, Parent=frame,
    })
    rowBtn.MouseEnter:Connect(function() Tween(frame,{BackgroundColor3=C.Surface2},ANIM.Fast) end)
    rowBtn.MouseLeave:Connect(function() Tween(frame,{BackgroundColor3=C.Surface},ANIM.Fast) end)

    Inst("TextLabel", {
        Text=name, FontFace=F.Medium, TextSize=TS.Normal, TextColor3=C.Fg,
        TextXAlignment=Enum.TextXAlignment.Left, BackgroundTransparency=1,
        AnchorPoint=Vector2.new(0,0.5), Position=UDim2.new(0,14,0.5,0),
        Size=UDim2.new(0.45,-14,0,18), ZIndex=3, Parent=frame,
    })

    -- Display box
    local displayBg = Inst("Frame", {
        BackgroundColor3=C.Bg, BorderSizePixel=0,
        AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,-14,0.5,0),
        Size=UDim2.new(0,175,0,26), ZIndex=3, Parent=frame,
    })
    Stroke(displayBg, C.LineMid, 1)

    local function GetDisplayText()
        if multiSelect then
            return #selected>0 and table.concat(selected,", ") or "None"
        end
        return tostring(selected)
    end

    local selLbl = Inst("TextLabel", {
        Text=GetDisplayText(), FontFace=F.Regular, TextSize=TS.Small, TextColor3=C.Fg,
        TextXAlignment=Enum.TextXAlignment.Left, TextTruncate=Enum.TextTruncate.AtEnd,
        BackgroundTransparency=1, Position=UDim2.new(0,8,0,0),
        Size=UDim2.new(1,-22,1,0), ZIndex=4, Parent=displayBg,
    })
    local arrowLbl = Inst("TextLabel", {
        Text="▾", FontFace=F.Regular, TextSize=TS.Tiny, TextColor3=C.Fg3,
        BackgroundTransparency=1, AnchorPoint=Vector2.new(1,0.5),
        Position=UDim2.new(1,-6,0.5,0), Size=UDim2.new(0,12,0,12), ZIndex=4, Parent=displayBg,
    })

    -- ── Options list — parented to ScreenGui to escape ScrollFrame clip ──
    local searchH   = showSearch and 30 or 0
    local listH     = math.min(#options,maxVisible)*optionH + searchH

    local listFrame = Inst("Frame", {
        BackgroundColor3=C.Surface2, BorderSizePixel=0,
        Size=UDim2.new(0,175,0,listH),
        Visible=false, ZIndex=500,
        ClipsDescendants=true,
        Parent=lib.Gui,      -- ← ScreenGui, not tab.content
    })
    Stroke(listFrame, C.LineMid, 1)

    -- Optional search box
    local searchBox = nil
    if showSearch then
        local sBg = Inst("Frame", {
            BackgroundColor3=C.Bg, BorderSizePixel=0,
            Size=UDim2.new(1,0,0,searchH), ZIndex=501, Parent=listFrame,
        })
        HLine(sBg, searchH-1, 501)
        searchBox = Inst("TextBox", {
            Text="", PlaceholderText="Search...", PlaceholderColor3=C.Fg3,
            FontFace=F.Regular, TextSize=TS.Small, TextColor3=C.Fg,
            TextXAlignment=Enum.TextXAlignment.Left, BackgroundTransparency=1,
            ClearTextOnFocus=false, Position=UDim2.new(0,10,0,0),
            Size=UDim2.new(1,-10,1,0), ZIndex=502, Parent=sBg,
        })
    end

    local listScroll = Inst("ScrollingFrame", {
        BackgroundTransparency=1, BorderSizePixel=0,
        Position=UDim2.new(0,0,0,searchH), Size=UDim2.new(1,0,1,-searchH),
        CanvasSize=UDim2.new(0,0,0,#options*optionH),
        ScrollBarThickness=2, ScrollBarImageColor3=C.LineMid,
        ZIndex=501, Parent=listFrame,
    })
    List(listScroll, 0)

    local function IsSel(opt)
        return multiSelect and (table.find(selected,opt)~=nil) or (selected==opt)
    end

    local function RebuildList(filter)
        for _,c in ipairs(listScroll:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        local vis = 0
        for _,opt in ipairs(options) do
            local show = (not filter or filter=="") or opt:lower():find(filter:lower(),1,true)
            if show then
                vis = vis + 1
                local sel = IsSel(opt)
                local ob = Inst("TextButton", {
                    Name=opt, Text=opt,
                    FontFace=sel and F.SemiBold or F.Regular,
                    TextSize=TS.Small, TextColor3=sel and C.Fg or C.Fg2,
                    TextXAlignment=Enum.TextXAlignment.Left,
                    BackgroundColor3=sel and C.Surface or C.Surface2,
                    BackgroundTransparency=sel and 0 or 1,
                    BorderSizePixel=0, Size=UDim2.new(1,0,0,optionH), ZIndex=502,
                    Parent=listScroll,
                })
                Pad(ob, 0, 0, 10, 0)
                ob.MouseEnter:Connect(function() ob.BackgroundTransparency=0; ob.BackgroundColor3=C.Surface; ob.TextColor3=C.Fg end)
                ob.MouseLeave:Connect(function()
                    ob.BackgroundTransparency = IsSel(opt) and 0 or 1
                    ob.BackgroundColor3 = IsSel(opt) and C.Surface or C.Surface2
                    ob.TextColor3 = IsSel(opt) and C.Fg or C.Fg2
                end)
                ob.MouseButton1Click:Connect(function()
                    if multiSelect then
                        local idx = table.find(selected,opt)
                        if idx then table.remove(selected,idx) else table.insert(selected,opt) end
                        selLbl.Text = GetDisplayText()
                        pcall(callback, selected)
                        RebuildList(searchBox and searchBox.Text or nil)
                    else
                        selected = opt
                        selLbl.Text = GetDisplayText()
                        pcall(callback, selected)
                        -- Auto-close on single select
                        CloseDD()
                        RebuildList()
                    end
                end)
            end
        end
        local newH = math.min(vis,maxVisible)*optionH
        listScroll.CanvasSize = UDim2.new(0,0,0,vis*optionH)
        listFrame.Size = UDim2.new(0,175,0,newH+searchH)
    end
    RebuildList()

    if searchBox then
        searchBox:GetPropertyChangedSignal("Text"):Connect(function()
            RebuildList(searchBox.Text)
        end)
    end

    -- Reposition list below the display box (called each time it opens
    -- so it follows if the window was moved)
    local function RepositionList()
        local vp  = game.Workspace.CurrentCamera.ViewportSize
        local ap  = displayBg.AbsolutePosition
        local as  = displayBg.AbsoluteSize
        local lh  = listFrame.AbsoluteSize.Y
        local tx  = ap.X
        local ty  = ap.Y + as.Y + 2
        -- Flip upward if too close to bottom
        if ty + lh > vp.Y - 8 then ty = ap.Y - lh - 2 end
        if tx + 175 > vp.X    then tx = vp.X - 179 end
        listFrame.Position = UDim2.new(0, tx, 0, ty)
    end

    -- FIX: CloseDD is local per dropdown instance (not global CloseDropdown)
    function CloseDD()
        expanded = false
        listFrame.Visible = false
        arrowLbl.Text = "▾"
        if searchBox then searchBox.Text="" end
        if Library._activeDropdown == CloseDD then
            Library._activeDropdown = nil
        end
    end

    local toggleBtn = Inst("TextButton", {
        Text="", BackgroundTransparency=1, Size=UDim2.new(1,0,1,0), ZIndex=5, Parent=displayBg,
    })
    toggleBtn.MouseButton1Click:Connect(function()
        if expanded then
            CloseDD()
        else
            if Library._activeDropdown then Library._activeDropdown() end
            RepositionList()
            expanded = true
            listFrame.Visible = true
            arrowLbl.Text = "▴"
            Library._activeDropdown = CloseDD
        end
    end)

    -- Close when clicking outside
    lib._connections["dd_out_"..tostring(frame)] = UserInputService.InputBegan:Connect(function(inp)
        if not expanded then return end
        if inp.UserInputType~=Enum.UserInputType.MouseButton1
        and inp.UserInputType~=Enum.UserInputType.Touch then return end
        local mp = inp.Position
        local lp,ls = listFrame.AbsolutePosition, listFrame.AbsoluteSize
        local fp,fs = frame.AbsolutePosition,     frame.AbsoluteSize
        local inL = mp.X>=lp.X and mp.X<=lp.X+ls.X and mp.Y>=lp.Y and mp.Y<=lp.Y+ls.Y
        local inH = mp.X>=fp.X and mp.X<=fp.X+fs.X and mp.Y>=fp.Y and mp.Y<=fp.Y+fs.Y
        if not inL and not inH then CloseDD() end
    end)

    local methods = {
        SetValue = function(_,v)
            if multiSelect and type(v)=="table" then selected=v
            elseif not multiSelect then selected=v end
            selLbl.Text=GetDisplayText(); RebuildList(); pcall(callback,selected)
        end,
        GetValue = function() return selected end,
        Refresh  = function(_,newOpts)
            options=newOpts
            listFrame.Size=UDim2.new(0,175,0,math.min(#options,maxVisible)*optionH+searchH)
            RebuildList(searchBox and searchBox.Text or nil)
        end,
    }
    tab._lib:_Reg(flag, function() return selected end, function(v) methods:SetValue(v) end)
    return methods
end

-- ══════════════════════════════════════════════════════════════════════
-- COMPONENT: CHECKBOX
-- ══════════════════════════════════════════════════════════════════════
function Library._Checkbox(tab, cfg)
    local name     = cfg.Name     or "Checkbox"
    local default  = cfg.Default  or false
    local callback = cfg.Callback or function() end
    local flag     = cfg.Flag
    local enabled  = default

    local frame = Inst("Frame", {
        Name="Checkbox_"..name, BackgroundColor3=C.Surface,
        BorderSizePixel=0, Size=UDim2.new(1,0,0,38), Parent=tab.content,
    })
    Stroke(frame, C.Line, 1)

    local rowBtn = Inst("TextButton", {Text="",BackgroundTransparency=1,Size=UDim2.new(1,0,1,0),Parent=frame})
    rowBtn.MouseEnter:Connect(function() Tween(frame,{BackgroundColor3=C.Surface2},ANIM.Fast) end)
    rowBtn.MouseLeave:Connect(function() Tween(frame,{BackgroundColor3=C.Surface},ANIM.Fast) end)

    Inst("TextLabel", {
        Text=name, FontFace=F.Medium, TextSize=TS.Normal, TextColor3=C.Fg,
        TextXAlignment=Enum.TextXAlignment.Left, BackgroundTransparency=1,
        AnchorPoint=Vector2.new(0,0.5), Position=UDim2.new(0,14,0.5,0),
        Size=UDim2.new(1,-46,0,18), Parent=frame,
    })

    local box = Inst("Frame", {
        BackgroundColor3=enabled and C.Fg or C.Bg, BorderSizePixel=0,
        AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,-14,0.5,0),
        Size=UDim2.new(0,16,0,16), ZIndex=2, Parent=frame,
    })
    local bStroke = Stroke(box, enabled and C.Fg or C.LineMid, 1)
    local check = Inst("TextLabel", {
        Text="✓", FontFace=F.Bold, TextSize=10, TextColor3=C.Bg,
        BackgroundTransparency=1, Size=UDim2.new(1,0,1,0),
        Visible=enabled, ZIndex=3, Parent=box,
    })

    local function SetVisual(on)
        Tween(box,{BackgroundColor3=on and C.Fg or C.Bg},ANIM.Fast)
        bStroke.Color=on and C.Fg or C.LineMid; check.Visible=on
    end

    rowBtn.MouseEnter:Connect(function() if not enabled then bStroke.Color=C.Fg2 end end)
    rowBtn.MouseLeave:Connect(function() if not enabled then bStroke.Color=C.LineMid end end)
    rowBtn.MouseButton1Click:Connect(function()
        enabled=not enabled; SetVisual(enabled); pcall(callback,enabled)
    end)

    local methods = {
        SetValue = function(_,v) enabled=v; SetVisual(v); pcall(callback,v) end,
        GetValue = function()    return enabled end,
    }
    tab._lib:_Reg(flag, function() return enabled end, function(v) methods:SetValue(v) end)
    return methods
end

-- ══════════════════════════════════════════════════════════════════════
-- COMPONENT: KEYBIND
-- ══════════════════════════════════════════════════════════════════════
function Library._Keybind(tab, cfg)
    local name         = cfg.Name     or "Keybind"
    local default      = cfg.Default  or Enum.KeyCode.F
    local callback     = cfg.Callback or function() end
    local linkedToggle = cfg.Toggle
    local flag         = cfg.Flag
    local curKey       = default
    local listening    = false

    local function Fire()
        if linkedToggle then linkedToggle:SetValue(not linkedToggle:GetValue()) end
        pcall(callback, curKey)
    end

    local frame = Inst("Frame", {
        Name="Keybind_"..name, BackgroundColor3=C.Surface,
        BorderSizePixel=0, Size=UDim2.new(1,0,0,38), Parent=tab.content,
    })
    Stroke(frame, C.Line, 1)

    local rowBtn = Inst("TextButton", {Text="",BackgroundTransparency=1,Size=UDim2.new(1,0,1,0),Parent=frame})
    rowBtn.MouseEnter:Connect(function() Tween(frame,{BackgroundColor3=C.Surface2},ANIM.Fast) end)
    rowBtn.MouseLeave:Connect(function() Tween(frame,{BackgroundColor3=C.Surface},ANIM.Fast) end)

    -- Optional status dot (linked toggle state)
    local statusDot = nil
    local nameX = 14
    if linkedToggle then
        statusDot = Inst("Frame", {
            BackgroundColor3 = linkedToggle:GetValue() and C.Fg or C.Fg3,
            BorderSizePixel  = 0,
            AnchorPoint      = Vector2.new(0,0.5),
            Position         = UDim2.new(0,14,0.5,0),
            Size             = UDim2.new(0,6,0,6),
            ZIndex           = 2,
            Parent           = frame,
        })
        nameX = 26
        local origSet = linkedToggle.SetValue
        linkedToggle.SetValue = function(self_, v)
            origSet(self_, v)
            if statusDot then statusDot.BackgroundColor3 = v and C.Fg or C.Fg3 end
        end
    end

    Inst("TextLabel", {
        Text=name, FontFace=F.Medium, TextSize=TS.Normal, TextColor3=C.Fg,
        TextXAlignment=Enum.TextXAlignment.Left, BackgroundTransparency=1,
        AnchorPoint=Vector2.new(0,0.5), Position=UDim2.new(0,nameX,0.5,0),
        Size=UDim2.new(1,-(nameX+90),0,18), ZIndex=2, Parent=frame,
    })

    local keyBg = Inst("Frame", {
        BackgroundColor3=C.Bg, BorderSizePixel=0,
        AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,-14,0.5,0),
        Size=UDim2.new(0,74,0,22), ZIndex=2, Parent=frame,
    })
    Stroke(keyBg, C.LineMid, 1)
    local keyLbl = Inst("TextLabel", {
        Text=curKey.Name, FontFace=F.Mono, TextSize=TS.Tiny, TextColor3=C.Fg2,
        TextTruncate=Enum.TextTruncate.AtEnd, BackgroundTransparency=1,
        Size=UDim2.new(1,0,1,0), ZIndex=3, Parent=keyBg,
    })
    local kbBtn = Inst("TextButton", {Text="",BackgroundTransparency=1,Size=UDim2.new(1,0,1,0),ZIndex=4,Parent=keyBg})

    local kbId = name.."_"..tostring(tick())
    tab._lib._keybinds[kbId] = {key=curKey, callback=Fire}

    local function UpdateDisplay()
        keyLbl.Text      = listening and "..." or curKey.Name
        keyLbl.TextColor3 = listening and C.Fg or C.Fg2
    end

    kbBtn.MouseButton1Click:Connect(function() listening=true; UpdateDisplay() end)

    local conn; conn = UserInputService.InputBegan:Connect(function(inp,gp)
        if gp or not listening then return end
        local skip={[Enum.KeyCode.LeftShift]=true,[Enum.KeyCode.RightShift]=true,
                    [Enum.KeyCode.LeftControl]=true,[Enum.KeyCode.RightControl]=true,
                    [Enum.KeyCode.LeftAlt]=true,[Enum.KeyCode.RightAlt]=true}
        if inp.UserInputType==Enum.UserInputType.Keyboard and not skip[inp.KeyCode] then
            curKey=inp.KeyCode; listening=false
            tab._lib._keybinds[kbId].key=curKey; UpdateDisplay()
        end
    end)
    tab._lib._connections["kb_"..kbId] = conn

    local methods = {
        SetKey = function(_,k) curKey=k; tab._lib._keybinds[kbId].key=k; UpdateDisplay() end,
        GetKey = function()    return curKey end,
    }
    tab._lib:_Reg(flag, function() return curKey end, function(v) methods:SetKey(v) end)
    return methods
end

-- ══════════════════════════════════════════════════════════════════════
-- COMPONENT: COLOR PICKER
-- (parented to ScreenGui — same fix as dropdown)
-- ══════════════════════════════════════════════════════════════════════
function Library._ColorPicker(tab, cfg)
    local name     = cfg.Name     or "Color"
    local default  = cfg.Default  or Color3.fromRGB(255,255,255)
    local callback = cfg.Callback or function() end
    local flag     = cfg.Flag
    local h,s,v   = default:ToHSV()
    local cur      = default
    local expanded = false

    local row = Inst("Frame", {
        Name="ColorPicker_"..name, BackgroundColor3=C.Surface,
        BorderSizePixel=0, Size=UDim2.new(1,0,0,38), Parent=tab.content,
    })
    Stroke(row, C.Line, 1)

    local rowBtn = Inst("TextButton", {Text="",BackgroundTransparency=1,Size=UDim2.new(1,0,1,0),Parent=row})
    rowBtn.MouseEnter:Connect(function() Tween(row,{BackgroundColor3=C.Surface2},ANIM.Fast) end)
    rowBtn.MouseLeave:Connect(function() Tween(row,{BackgroundColor3=C.Surface},ANIM.Fast) end)

    Inst("TextLabel", {
        Text=name, FontFace=F.Medium, TextSize=TS.Normal, TextColor3=C.Fg,
        TextXAlignment=Enum.TextXAlignment.Left, BackgroundTransparency=1,
        AnchorPoint=Vector2.new(0,0.5), Position=UDim2.new(0,14,0.5,0),
        Size=UDim2.new(1,-70,0,18), ZIndex=2, Parent=row,
    })

    local preview = Inst("Frame", {
        BackgroundColor3=cur, BorderSizePixel=0,
        AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,-14,0.5,0),
        Size=UDim2.new(0,48,0,18), ZIndex=2, Parent=row,
    })
    Stroke(preview, C.LineMid, 1)
    local prevBtn = Inst("TextButton", {Text="",BackgroundTransparency=1,Size=UDim2.new(1,0,1,0),ZIndex=3,Parent=preview})

    -- Picker parented to ScreenGui
    local picker = Inst("Frame", {
        BackgroundColor3=C.Surface, BorderSizePixel=0,
        Size=UDim2.new(0,176,0,126), Visible=false, ZIndex=3000, Parent=tab._lib.Gui,
    })
    Stroke(picker, C.LineMid, 1)

    local svArea = Inst("Frame", {
        BackgroundColor3=Color3.fromHSV(h,1,1), BorderSizePixel=0,
        Position=UDim2.new(0,8,0,8), Size=UDim2.new(1,-16,0,92), ZIndex=3001, Parent=picker,
    })
    local wLayer = Inst("Frame", {BackgroundColor3=Color3.new(1,1,1),Size=UDim2.new(1,0,1,0),ZIndex=3002,Parent=svArea})
    Inst("UIGradient", {Color=ColorSequence.new(Color3.new(1,1,1)),
        Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(1,1)}),
        Parent=wLayer})
    local bLayer = Inst("Frame", {BackgroundColor3=Color3.new(0,0,0),Size=UDim2.new(1,0,1,0),ZIndex=3003,Parent=svArea})
    Inst("UIGradient", {Rotation=90,Color=ColorSequence.new(Color3.new(0,0,0)),
        Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(1,0)}),
        Parent=bLayer})
    local svCursor = Inst("Frame", {BackgroundTransparency=1,BorderSizePixel=0,
        AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.new(s,0,1-v,0),
        Size=UDim2.new(0,8,0,8),ZIndex=3005,Parent=svArea})
    Stroke(svCursor, Color3.new(1,1,1), 2)

    local hBar = Inst("Frame", {BorderSizePixel=0,Position=UDim2.new(0,8,0,106),Size=UDim2.new(1,-16,0,8),ZIndex=3001,Parent=picker})
    Inst("UIGradient", {Color=ColorSequence.new({
        ColorSequenceKeypoint.new(0,Color3.fromHSV(0,1,1)),ColorSequenceKeypoint.new(0.167,Color3.fromHSV(0.167,1,1)),
        ColorSequenceKeypoint.new(0.333,Color3.fromHSV(0.333,1,1)),ColorSequenceKeypoint.new(0.5,Color3.fromHSV(0.5,1,1)),
        ColorSequenceKeypoint.new(0.667,Color3.fromHSV(0.667,1,1)),ColorSequenceKeypoint.new(0.833,Color3.fromHSV(0.833,1,1)),
        ColorSequenceKeypoint.new(1,Color3.fromHSV(1,1,1)),
    }),Parent=hBar})
    local hCursor = Inst("Frame", {BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0,
        AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.new(h,0,0.5,0),Size=UDim2.new(0,8,0,12),ZIndex=3005,Parent=hBar})
    Stroke(hCursor, C.Bg, 1)

    local function UpdateColor()
        cur = Color3.fromHSV(h,s,v)
        preview.BackgroundColor3 = cur
        svArea.BackgroundColor3  = Color3.fromHSV(h,1,1)
        svCursor.Position = UDim2.new(s,0,1-v,0)
        hCursor.Position  = UDim2.new(h,0,0.5,0)
        pcall(callback,cur)
    end

    local svDrag,hDrag = false,false
    local function ProcessInput(inp)
        if not picker.Visible then return end
        if svDrag then
            local p=svArea.AbsolutePosition; local sz=svArea.AbsoluteSize
            s=math.clamp((inp.Position.X-p.X)/sz.X,0,1); v=1-math.clamp((inp.Position.Y-p.Y)/sz.Y,0,1)
            UpdateColor()
        elseif hDrag then
            local p=hBar.AbsolutePosition; local sz=hBar.AbsoluteSize
            h=math.clamp((inp.Position.X-p.X)/sz.X,0,1); UpdateColor()
        end
    end
    svArea.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 then svDrag=true;ProcessInput(inp);Library._activeDragger=ProcessInput end
    end)
    hBar.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 then hDrag=true;ProcessInput(inp);Library._activeDragger=ProcessInput end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 then svDrag=false;hDrag=false;Library._activeDragger=nil end
    end)

    local function ClosePicker()
        picker.Visible=false; expanded=false
        if Library._activePicker==ClosePicker then Library._activePicker=nil end
    end
    local function OpenPicker()
        if Library._activePicker then Library._activePicker() end
        Library._activePicker = ClosePicker
        local vp=game.Workspace.CurrentCamera.ViewportSize
        local bp=preview.AbsolutePosition
        local tx=bp.X-186; local ty=bp.Y
        if ty+130>vp.Y then ty=vp.Y-134 end
        if ty<0        then ty=4 end
        if tx<0        then tx=bp.X+58 end
        picker.Position=UDim2.new(0,tx,0,ty); picker.Visible=true; expanded=true
    end
    prevBtn.MouseButton1Click:Connect(function()
        if expanded then ClosePicker() else OpenPicker() end
    end)

    local methods = {
        SetColor = function(_,c) cur=c;h,s,v=c:ToHSV();UpdateColor() end,
        GetColor = function()    return cur end,
    }
    tab._lib:_Reg(flag, function() return cur end, function(c) methods:SetColor(c) end)
    return methods
end

-- ══════════════════════════════════════════════════════════════════════
-- COMPONENT: PROGRESS BAR
-- ══════════════════════════════════════════════════════════════════════
function Library._ProgressBar(tab, cfg)
    local name  = cfg.Name    or "Progress"
    local min   = cfg.Min     or 0
    local max   = cfg.Max     or 100
    local dflt  = cfg.Default or 0
    local sfx   = cfg.Suffix  or ""
    local cur   = math.clamp(dflt,min,max)

    local frame = Inst("Frame", {
        Name="ProgressBar_"..name, BackgroundColor3=C.Surface,
        BorderSizePixel=0, Size=UDim2.new(1,0,0,52), Parent=tab.content,
    })
    Stroke(frame, C.Line, 1)

    Inst("TextLabel", {
        Text=name, FontFace=F.Medium, TextSize=TS.Normal, TextColor3=C.Fg,
        TextXAlignment=Enum.TextXAlignment.Left, BackgroundTransparency=1,
        AnchorPoint=Vector2.new(0,0), Position=UDim2.new(0,14,0,8),
        Size=UDim2.new(0.65,-14,0,18), Parent=frame,
    })
    local valLbl = Inst("TextLabel", {
        Text=tostring(cur)..sfx, FontFace=F.Mono, TextSize=TS.Small, TextColor3=C.Fg3,
        TextXAlignment=Enum.TextXAlignment.Right, BackgroundTransparency=1,
        AnchorPoint=Vector2.new(1,0), Position=UDim2.new(1,-14,0,8),
        Size=UDim2.new(0,80,0,18), Parent=frame,
    })

    local track = Inst("Frame", {BackgroundColor3=C.Line,BorderSizePixel=0,
        Position=UDim2.new(0,14,0,36),Size=UDim2.new(1,-28,0,3),Parent=frame})
    local ratio = (max-min)>0 and (cur-min)/(max-min) or 0
    local fill  = Inst("Frame", {BackgroundColor3=C.Fg,BorderSizePixel=0,
        Size=UDim2.new(ratio,0,1,0),Parent=track})

    local function Refresh(val)
        cur=math.clamp(val,min,max)
        local r=(max-min)>0 and (cur-min)/(max-min) or 0
        Tween(fill,{Size=UDim2.new(r,0,1,0)},ANIM.Normal)
        valLbl.Text=tostring(cur)..sfx
    end

    return {
        SetValue = function(_,v) Refresh(v) end,
        GetValue = function()    return cur end,
        SetMax   = function(_,v) max=v; Refresh(cur) end,
        SetMin   = function(_,v) min=v; Refresh(cur) end,
    }
end

-- ══════════════════════════════════════════════════════════════════════
-- COMPONENT: TABLE
-- ══════════════════════════════════════════════════════════════════════
function Library._Table(tab, cfg)
    local name       = cfg.Name       or "Table"
    local columns    = cfg.Columns    or {"Name","Value"}
    local rowH       = cfg.RowHeight  or 30
    local maxVisible = cfg.MaxVisible or 6
    local colN       = #columns
    local data       = {}

    local frame = Inst("Frame", {
        Name="Table_"..name, BackgroundColor3=C.Surface,
        BorderSizePixel=0, AutomaticSize=Enum.AutomaticSize.Y,
        Size=UDim2.new(1,0,0,0), Parent=tab.content,
    })
    Stroke(frame, C.Line, 1)

    local titleBar = Inst("Frame", {BackgroundColor3=C.Surface2,BorderSizePixel=0,Size=UDim2.new(1,0,0,28),Parent=frame})
    Inst("TextLabel", {Text=string.upper(name),FontFace=F.Bold,TextSize=TS.Tiny,TextColor3=C.Fg3,
        TextXAlignment=Enum.TextXAlignment.Left,BackgroundTransparency=1,
        Position=UDim2.new(0,14,0,0),Size=UDim2.new(1,-28,1,0),Parent=titleBar})
    HLine(frame, 28)

    local headerRow = Inst("Frame", {BackgroundColor3=C.Surface2,BorderSizePixel=0,Position=UDim2.new(0,0,0,29),Size=UDim2.new(1,0,0,26),Parent=frame})
    for i,col in ipairs(columns) do
        local xOff = i==1 and 14 or 6
        Inst("TextLabel", {Text=string.upper(col),FontFace=F.Bold,TextSize=TS.Tiny,TextColor3=C.Fg3,
            TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd,
            BackgroundTransparency=1,Position=UDim2.new((i-1)/colN,xOff,0,0),
            Size=UDim2.new(1/colN,-xOff,1,0),Parent=headerRow})
    end
    HLine(headerRow, 25)

    local body = Inst("ScrollingFrame", {
        BackgroundTransparency=1,BorderSizePixel=0,
        Position=UDim2.new(0,0,0,55),Size=UDim2.new(1,0,0,0),
        CanvasSize=UDim2.new(0,0,0,0),ScrollBarThickness=2,
        ScrollBarImageColor3=C.LineMid,ScrollingDirection=Enum.ScrollingDirection.Y,
        Parent=frame,
    })
    List(body, 0)

    local rowFrames = {}
    local function RefreshLayout()
        local vis = math.min(#data,maxVisible)
        body.Size=UDim2.new(1,0,0,vis*rowH); body.CanvasSize=UDim2.new(0,0,0,#data*rowH)
    end
    local function MakeRow(idx, rd)
        local r = Inst("Frame", {
            BackgroundColor3=idx%2==0 and C.Surface2 or C.Surface,
            BorderSizePixel=0,LayoutOrder=idx,Size=UDim2.new(1,0,0,rowH),Parent=body,
        })
        HLine(r, rowH-1)
        for i=1,colN do
            local xOff=i==1 and 14 or 6
            Inst("TextLabel", {Text=tostring(rd[i] or ""),FontFace=F.Regular,TextSize=TS.Small,TextColor3=C.Fg,
                TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd,
                BackgroundTransparency=1,Position=UDim2.new((i-1)/colN,xOff,0,0),
                Size=UDim2.new(1/colN,-xOff,1,0),Parent=r})
        end
        return r
    end
    local function FullRender()
        for _,r in ipairs(rowFrames) do pcall(function() r:Destroy() end) end
        rowFrames={}
        for i,d in ipairs(data) do table.insert(rowFrames,MakeRow(i,d)) end
        RefreshLayout()
    end
    RefreshLayout()

    return {
        AddRow    = function(_,d) table.insert(data,d); table.insert(rowFrames,MakeRow(#data,d)); RefreshLayout() end,
        RemoveRow = function(_,i) if data[i] then table.remove(data,i); FullRender() end end,
        ClearRows = function(_)   data={}; FullRender() end,
        SetData   = function(_,d) data=d; FullRender() end,
        GetData   = function()    return data end,
    }
end

-- ══════════════════════════════════════════════════════════════════════
-- COMPONENT: BADGE
-- ══════════════════════════════════════════════════════════════════════
function Library._Badge(tab, cfg)
    local text  = cfg.Text  or "Badge"
    local style = cfg.Style or "neutral"
    local palette = {active=C.Fg, inactive=C.Fg3, neutral=C.Fg2, danger=C.Danger}
    local col = palette[style] or palette.neutral

    local badge = Inst("TextLabel", {
        Name="Badge_"..text, Text=string.upper(text),
        FontFace=F.Bold, TextSize=TS.Tiny, TextColor3=col,
        BackgroundTransparency=1, AutomaticSize=Enum.AutomaticSize.X,
        Size=UDim2.new(0,0,0,22), Parent=tab.content,
    })
    Pad(badge,0,0,10,10)
    Stroke(badge, col, 1)

    return {
        SetText  = function(_,t) badge.Text=string.upper(t) end,
        SetStyle = function(_,st)
            local nc=palette[st] or palette.neutral; badge.TextColor3=nc
            for _,ch in ipairs(badge:GetChildren()) do if ch:IsA("UIStroke") then ch.Color=nc end end
        end,
        GetText  = function() return badge.Text end,
    }
end

-- ══════════════════════════════════════════════════════════════════════
-- COMPONENT: RADIO GROUP
-- ══════════════════════════════════════════════════════════════════════
function Library._RadioGroup(tab, cfg)
    local name     = cfg.Name     or "Radio"
    local options  = cfg.Options  or {"Option 1","Option 2"}
    local default  = cfg.Default  or options[1]
    local callback = cfg.Callback or function() end
    local flag     = cfg.Flag
    local selected = default

    local frame = Inst("Frame", {
        Name="RadioGroup_"..name, BackgroundColor3=C.Surface,
        BorderSizePixel=0, AutomaticSize=Enum.AutomaticSize.Y,
        Size=UDim2.new(1,0,0,0), Parent=tab.content,
    })
    Stroke(frame, C.Line, 1)
    Pad(frame, 10, 10, 14, 14)
    List(frame, 6)

    Inst("TextLabel", {
        Text=string.upper(name), FontFace=F.Bold, TextSize=TS.Tiny, TextColor3=C.Fg3,
        TextXAlignment=Enum.TextXAlignment.Left, BackgroundTransparency=1,
        LayoutOrder=0, Size=UDim2.new(1,0,0,16), Parent=frame,
    })

    local optData = {}
    local function UpdateAll()
        for _,d in pairs(optData) do
            local sel = d.value==selected
            Tween(d.box,{BackgroundColor3=sel and C.Fg or C.Bg},ANIM.Fast)
            d.bStroke.Color=sel and C.Fg or C.LineMid
            d.dot.Visible=sel
            d.lbl.TextColor3=sel and C.Fg or C.Fg2
            d.lbl.FontFace=sel and F.SemiBold or F.Regular
        end
    end

    for i,opt in ipairs(options) do
        local row = Inst("Frame", {BackgroundTransparency=1,LayoutOrder=i,Size=UDim2.new(1,0,0,28),Parent=frame})
        local box = Inst("Frame", {BackgroundColor3=opt==selected and C.Fg or C.Bg,BorderSizePixel=0,
            AnchorPoint=Vector2.new(0,0.5),Position=UDim2.new(0,0,0.5,0),Size=UDim2.new(0,14,0,14),ZIndex=2,Parent=row})
        local bStroke = Stroke(box, opt==selected and C.Fg or C.LineMid, 1)
        local dot = Inst("Frame", {BackgroundColor3=C.Bg,BorderSizePixel=0,
            AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.new(0.5,0,0.5,0),
            Size=UDim2.new(0,6,0,6),Visible=opt==selected,ZIndex=3,Parent=box})
        local lbl = Inst("TextLabel", {Text=opt,FontFace=opt==selected and F.SemiBold or F.Regular,
            TextSize=TS.Normal,TextColor3=opt==selected and C.Fg or C.Fg2,
            TextXAlignment=Enum.TextXAlignment.Left,BackgroundTransparency=1,
            Position=UDim2.new(0,24,0,0),Size=UDim2.new(1,-24,1,0),ZIndex=2,Parent=row})
        local btn = Inst("TextButton", {Text="",BackgroundTransparency=1,Size=UDim2.new(1,0,1,0),ZIndex=3,Parent=row})
        optData[opt] = {value=opt,box=box,bStroke=bStroke,dot=dot,lbl=lbl}
        btn.MouseButton1Click:Connect(function() selected=opt; UpdateAll(); pcall(callback,selected) end)
        btn.MouseEnter:Connect(function() if selected~=opt then lbl.TextColor3=C.Fg end end)
        btn.MouseLeave:Connect(function() if selected~=opt then lbl.TextColor3=C.Fg2 end end)
    end

    local methods = {
        SetValue = function(_,v) selected=v; UpdateAll(); pcall(callback,selected) end,
        GetValue = function()    return selected end,
    }
    tab._lib:_Reg(flag, function() return selected end, function(v) methods:SetValue(v) end)
    return methods
end

-- ══════════════════════════════════════════════════════════════════════
-- CONFIG SECTION  (pre-built save/load/delete UI)
-- ══════════════════════════════════════════════════════════════════════
function Library._ConfigSection(tab)
    local lib = tab._lib
    Library._SectionHeader(tab, "Configuration")

    local nameBox = Library._TextBox(tab, {
        Name="Config Name", Default="default", Placeholder="Enter name...",
        Callback=function(t) if t~="" then lib._currentConfig=t end end,
    })
    local cfgDrop; cfgDrop = Library._Dropdown(tab, {
        Name="Saved Configs", Options=lib:GetConfigs(), Default="",
        Callback=function(sel)
            if sel~="" then nameBox:SetText(sel); lib._currentConfig=sel end
        end,
    })
    Library._Button(tab, {Name="Save Config", Style="primary",
        Callback=function()
            local n=nameBox:GetText()
            if n~="" then lib:SaveConfig(n); cfgDrop:Refresh(lib:GetConfigs()) end
        end})
    Library._Button(tab, {Name="Load Config", Style="ghost",
        Callback=function()
            local n=nameBox:GetText(); if n~="" then lib:LoadConfig(n) end
        end})
    Library._Button(tab, {Name="Delete Config", Style="danger",
        Callback=function()
            local n=nameBox:GetText()
            if n~="" then lib:DeleteConfig(n); cfgDrop:Refresh(lib:GetConfigs()) end
        end})
    Library._Button(tab, {Name="Refresh List", Style="ghost",
        Callback=function()
            cfgDrop:Refresh(lib:GetConfigs())
            lib:Notify({Title="Refreshed", Description="Config list updated"})
        end})
    Library._Toggle(tab, {Name="Auto Save (30s)", Default=false,
        Callback=function(v) lib:SetAutoSave(v) end})

    return {RefreshConfigs=function() cfgDrop:Refresh(lib:GetConfigs()) end}
end

-- ══════════════════════════════════════════════════════════════════════
return Library
