--[[
╔══════════════════════════════════════════════════════════════════════╗
║                     AstraUiLibrary  v2.0                           ║
║              Monochromatic Edition — ASTRA Admin Panel Style        ║
╠══════════════════════════════════════════════════════════════════════╣
║  Palette (from panel.html):                                         ║
║    Bg        #000000  →  RGB(0,   0,   0  )                         ║
║    Surface   #0d0d0d  →  RGB(13,  13,  13 )                         ║
║    Surface2  #141414  →  RGB(20,  20,  20 )                         ║
║    Line      #1f1f1f  →  RGB(31,  31,  31 )                         ║
║    LineMid   #2e2e2e  →  RGB(46,  46,  46 )                         ║
║    Fg        #ffffff  →  RGB(255, 255, 255)                         ║
║    Fg2       #888888  →  RGB(136, 136, 136)                         ║
║    Fg3       #444444  →  RGB(68,  68,  68 )                         ║
║    Danger    #ff3b3b  →  RGB(255, 59,  59 )                         ║
║                                                                      ║
║  Zero border-radius — everything sharp & editorial.                  ║
╠══════════════════════════════════════════════════════════════════════╣
║  Components:                                                         ║
║    CreateTab             Sidebar nav tab                             ║
║    CreateSectionHeader   UPPERCASE section label                     ║
║    CreateLabel           Text label with color/size options          ║
║    CreateSeparator       Divider (optional centered text)            ║
║    CreateParagraph       Info card (title + body)                    ║
║    CreateButton          primary / ghost / danger styles             ║
║    CreateToggle          Sharp rectangular toggle switch             ║
║    CreateSlider          Minimal track + square knob                 ║
║    CreateTextBox         Bordered input (optional numbers-only)      ║
║    CreateDropdown        Single / multi-select + search box          ║
║    CreateCheckbox        Sharp square checkbox                       ║
║    CreateKeybind         Monospace key tag + linked toggle dot       ║
║    CreateColorPicker     Compact HSV picker (floats in ScreenGui)    ║
║    CreateProgressBar     Animated fill bar                           ║
║    CreateTable           Editorial table with sortable columns       ║
║    CreateBadge           Outlined uppercase badge                    ║
║    CreateRadioGroup      Square dot radio buttons                    ║
║    CreateConfigSection   Full config save / load / delete UI         ║
╠══════════════════════════════════════════════════════════════════════╣
║  Library methods:                                                    ║
║    Library.new(title, options)   Create window                       ║
║    :Toggle()                     Show / hide window                  ║
║    :SetToggleKey(keyCode)        Keybind to toggle UI visibility     ║
║    :SetAccentColor(color)        Change accent (danger stays red)    ║
║    :SetWatermark(text)           Bottom-right watermark label        ║
║    :Notify(config)               Toast notification (corner)         ║
║    :SaveConfig(name)             Serialize all flagged elements      ║
║    :LoadConfig(name)             Restore all flagged elements        ║
║    :DeleteConfig(name)           Delete a saved config file          ║
║    :GetConfigs()                 List all saved config names         ║
║    :SetAutoSave(bool)            Auto-save every 30 s               ║
║    :Destroy()                    Clean up ScreenGui + connections    ║
╚══════════════════════════════════════════════════════════════════════╝
]]

-- ══════════════════════════════════════════════════════════════════════
-- SERVICES
-- ══════════════════════════════════════════════════════════════════════
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players          = game:GetService("Players")
local HttpService      = game:GetService("HttpService")

-- ══════════════════════════════════════════════════════════════════════
-- COLOUR PALETTE
-- ══════════════════════════════════════════════════════════════════════
local C = {
    Bg        = Color3.fromRGB(0,   0,   0  ),
    Surface   = Color3.fromRGB(13,  13,  13 ),
    Surface2  = Color3.fromRGB(20,  20,  20 ),
    Line      = Color3.fromRGB(31,  31,  31 ),
    LineMid   = Color3.fromRGB(46,  46,  46 ),
    Fg        = Color3.fromRGB(255, 255, 255),
    Fg2       = Color3.fromRGB(136, 136, 136),
    Fg3       = Color3.fromRGB(68,  68,  68 ),
    Danger    = Color3.fromRGB(255, 59,  59 ),
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
    MonoBold = Font.new("rbxasset://fonts/families/RobotoMono.json", Enum.FontWeight.Bold),
}

local TS = {
    Title  = 15,
    Normal = 13,
    Small  = 12,
    Tiny   = 10,
}

local ANIM = {
    Fast   = 0.08,
    Normal = 0.15,
    Slow   = 0.22,
}

-- ══════════════════════════════════════════════════════════════════════
-- LIBRARY OBJECT
-- ══════════════════════════════════════════════════════════════════════
local Library = {}
Library.__index = Library

-- Global drag / dropdown / picker state — single connection, no leaks
Library._activeDragger  = nil
Library._activeDropdown = nil
Library._activePicker   = nil

UserInputService.InputChanged:Connect(function(input)
    if Library._activeDragger
    and (input.UserInputType == Enum.UserInputType.MouseMovement
      or input.UserInputType == Enum.UserInputType.Touch)
    then
        Library._activeDragger(input)
    end
end)

-- ══════════════════════════════════════════════════════════════════════
-- INTERNAL UTILITY FUNCTIONS
-- ══════════════════════════════════════════════════════════════════════

--- Create a Roblox Instance and set all properties in one call.
local function Inst(class, props)
    local obj = Instance.new(class)
    for k, v in pairs(props) do
        if k ~= "Parent" then
            pcall(function() obj[k] = v end)
        end
    end
    if props.Parent then obj.Parent = props.Parent end
    return obj
end

--- UIStroke helper (border mode).
local function Stroke(parent, color, thickness)
    return Inst("UIStroke", {
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Color           = color     or C.Line,
        Thickness       = thickness or 1,
        Parent          = parent,
    })
end

--- UIPadding helper.
local function Pad(parent, top, bottom, left, right)
    return Inst("UIPadding", {
        PaddingTop    = UDim.new(0, top    or 0),
        PaddingBottom = UDim.new(0, bottom or 0),
        PaddingLeft   = UDim.new(0, left   or 0),
        PaddingRight  = UDim.new(0, right  or 0),
        Parent        = parent,
    })
end

--- UIListLayout helper (vertical by default).
local function List(parent, padding, direction, align)
    return Inst("UIListLayout", {
        Padding          = UDim.new(0, padding or 0),
        FillDirection    = direction or Enum.FillDirection.Vertical,
        SortOrder        = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = align or Enum.HorizontalAlignment.Left,
        Parent           = parent,
    })
end

--- TweenService shorthand.
local function Tween(obj, props, t, style, dir)
    local tw = TweenService:Create(obj,
        TweenInfo.new(
            t     or ANIM.Normal,
            style or Enum.EasingStyle.Quad,
            dir   or Enum.EasingDirection.Out),
        props)
    tw:Play()
    return tw
end

--- 1px horizontal divider.
local function HDivider(parent, yOffset)
    return Inst("Frame", {
        BackgroundColor3 = C.Line,
        BorderSizePixel  = 0,
        Position         = UDim2.new(0, 0, 0, yOffset or 0),
        Size             = UDim2.new(1, 0, 0, 1),
        Parent           = parent,
    })
end

--- 1px vertical divider.
local function VDivider(parent, xOffset)
    return Inst("Frame", {
        BackgroundColor3 = C.Line,
        BorderSizePixel  = 0,
        Position         = UDim2.new(0, xOffset or 0, 0, 0),
        Size             = UDim2.new(0, 1, 1, 0),
        Parent           = parent,
    })
end

--- Make a frame draggable via a given handle.
local function MakeDraggable(frame, handle)
    handle = handle or frame
    local dragging, dragStart, startPos = false, nil, nil

    handle.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
        and input.UserInputType ~= Enum.UserInputType.Touch then return end

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

--- Config folder helpers (safe — pcall-wrapped).
local CONFIG_FOLDER = "AstraConfigs"

local function EnsureFolder()
    if isfolder and not isfolder(CONFIG_FOLDER) then
        pcall(makefolder, CONFIG_FOLDER)
    end
end

local function GetConfigPath(name)
    return CONFIG_FOLDER .. "/" .. name .. ".json"
end

local function ListConfigs()
    local list = {}
    if not (isfolder and listfiles) then return list end
    EnsureFolder()
    local ok, files = pcall(listfiles, CONFIG_FOLDER)
    if not ok then return list end
    for _, f in ipairs(files) do
        local n = f:match(CONFIG_FOLDER .. "/(.+)%.json$")
                or f:match(CONFIG_FOLDER .. "\\(.+)%.json$")
        if n then table.insert(list, n) end
    end
    return list
end

-- ══════════════════════════════════════════════════════════════════════
-- LIBRARY.NEW  —  constructor
-- ══════════════════════════════════════════════════════════════════════
--[[
    options = {
        Width         = number,   default 740
        Height        = number,   default 460
        MinWidth      = number,   default 480
        MinHeight     = number,   default 300
        MaxWidth      = number,   default 1280
        MaxHeight     = number,   default 860
        AccentColor   = Color3,   replaces C.Fg accent (keeps Danger as-is)
        Watermark     = string,   bottom-right text
        ToggleKey     = KeyCode,  default RightControl
    }
]]
function Library.new(title, options)
    local self = setmetatable({}, Library)
    local opts = options or {}

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

    -- Window size bounds
    self._defaultW = opts.Width     or 740
    self._defaultH = opts.Height    or 460
    self._minW     = opts.MinWidth  or 480
    self._minH     = opts.MinHeight or 300
    self._maxW     = opts.MaxWidth  or 1280
    self._maxH     = opts.MaxHeight or 860
    self._origH    = self._defaultH

    -- Optional accent override
    if opts.AccentColor then
        C.Fg               = opts.AccentColor
        C.Toggle           = opts.AccentColor
    end

    self:_Build()
    self:_SetupKeybindListener()
    self:_SetupMobileButton()

    if opts.Watermark then
        self:SetWatermark(opts.Watermark)
    end

    return self
end

-- ══════════════════════════════════════════════════════════════════════
-- WINDOW CONSTRUCTION
-- ══════════════════════════════════════════════════════════════════════
function Library:_Build()
    local lp = Players.LocalPlayer

    -- ── ScreenGui ─────────────────────────────────────────────────────
    self.Gui = Inst("ScreenGui", {
        Name           = "AstraV2",
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn   = false,
        Parent         = lp:WaitForChild("PlayerGui"),
    })

    -- ── Outer container ───────────────────────────────────────────────
    self.Container = Inst("Frame", {
        Name             = "Container",
        BackgroundColor3 = C.Bg,
        BorderSizePixel  = 0,
        Size             = UDim2.new(0, self._defaultW, 0, self._defaultH),
        Position         = UDim2.new(0.5, -self._defaultW/2, 0.5, -self._defaultH/2),
        ClipsDescendants = false,
        Parent           = self.Gui,
    })
    self._containerStroke = Stroke(self.Container, C.Line, 1)

    -- ── Top bar (48 px) ───────────────────────────────────────────────
    self.TopBar = Inst("Frame", {
        Name             = "TopBar",
        BackgroundColor3 = C.Bg,
        BorderSizePixel  = 0,
        Size             = UDim2.new(1, 0, 0, 48),
        ZIndex           = 5,
        Parent           = self.Container,
    })
    HDivider(self.TopBar, 47)

    -- Title label
    self._titleLabel = Inst("TextLabel", {
        Name           = "TitleLabel",
        Text           = self.title,
        FontFace       = F.Black,
        TextSize       = TS.Title,
        TextColor3     = C.Fg,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        Position       = UDim2.new(0, 18, 0, 0),
        Size           = UDim2.new(0.5, 0, 1, 0),
        ZIndex         = 6,
        Parent         = self.TopBar,
    })

    -- Window control buttons (close, minimize)
    self:_BuildWindowControls()

    -- Make whole window draggable via top bar
    MakeDraggable(self.Container, self.TopBar)

    -- ── Body frame (below top bar) ────────────────────────────────────
    self.Body = Inst("Frame", {
        Name           = "Body",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position       = UDim2.new(0, 0, 0, 48),
        Size           = UDim2.new(1, 0, 1, -48),
        Parent         = self.Container,
    })

    -- ── Sidebar wrapper (holds the scroll + right border) ────────────
    -- NOTE: The border MUST live here, NOT inside the ScrollingFrame,
    -- because ScrollingFrame has UIListLayout and any Frame child
    -- (including a 1px divider) would be treated as a list item.
    local sidebarWrap = Inst("Frame", {
        Name             = "SidebarWrap",
        BackgroundColor3 = C.Bg,
        BorderSizePixel  = 0,
        Size             = UDim2.new(0, 175, 1, 0),
        Parent           = self.Body,
    })
    -- Right border line — lives on the wrapper, NOT the scroll frame
    Inst("Frame", {
        Name             = "SidebarBorder",
        BackgroundColor3 = C.Line,
        BorderSizePixel  = 0,
        AnchorPoint      = Vector2.new(1, 0),
        Position         = UDim2.new(1, 0, 0, 0),
        Size             = UDim2.new(0, 1, 1, 0),
        ZIndex           = 3,
        Parent           = sidebarWrap,
    })

    -- ── Sidebar ScrollingFrame (nav items only — no border frames!) ───
    self.Sidebar = Inst("ScrollingFrame", {
        Name                  = "Sidebar",
        BackgroundColor3      = C.Bg,
        BackgroundTransparency = 1,
        BorderSizePixel       = 0,
        Size                  = UDim2.new(1, -1, 1, 0), -- -1 so border shows
        ScrollBarThickness    = 0,
        CanvasSize            = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize   = Enum.AutomaticSize.Y,
        ScrollingDirection    = Enum.ScrollingDirection.Y,
        Parent                = sidebarWrap,
    })
    List(self.Sidebar, 0)
    Pad(self.Sidebar, 8, 8, 0, 0)

    -- ── Content area ──────────────────────────────────────────────────
    self.ContentArea = Inst("ScrollingFrame", {
        Name                  = "ContentArea",
        BackgroundTransparency = 1,
        BorderSizePixel       = 0,
        Position              = UDim2.new(0, 175, 0, 0),
        Size                  = UDim2.new(1, -175, 1, 0),
        ScrollBarThickness    = 2,
        ScrollBarImageColor3  = C.LineMid,
        CanvasSize            = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize   = Enum.AutomaticSize.Y,
        ScrollingDirection    = Enum.ScrollingDirection.Y,
        Parent                = self.Body,
    })
    -- ContentArea has NO UIListLayout — each tab is a full-size child
    -- that overlaps the others. Only one is Visible at a time.

    -- ── Resize handle (bottom-right corner) ──────────────────────────
    self:_BuildResizeHandle()

    -- ── Notification container (top-right of screen) ─────────────────
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

-- ── Window control buttons ────────────────────────────────────────────
function Library:_BuildWindowControls()
    -- Helper for a small text-button in the top bar
    local function CtrlBtn(symbol, xOffset, hoverCol)
        local btn = Inst("TextButton", {
            Name           = symbol,
            Text           = symbol,
            FontFace       = F.Regular,
            TextSize       = 18,
            TextColor3     = C.Fg3,
            BackgroundTransparency = 1,
            AnchorPoint    = Vector2.new(1, 0.5),
            Position       = UDim2.new(1, xOffset, 0.5, 0),
            Size           = UDim2.new(0, 28, 0, 28),
            ZIndex         = 6,
            Parent         = self.TopBar,
        })
        btn.MouseEnter:Connect(function() btn.TextColor3 = hoverCol end)
        btn.MouseLeave:Connect(function() btn.TextColor3 = C.Fg3 end)
        return btn
    end

    -- Close ×
    local closeBtn = CtrlBtn("×", -10, C.Danger)
    closeBtn.MouseButton1Click:Connect(function() self:Destroy() end)

    -- Minimize −
    local minBtn = CtrlBtn("−", -42, C.Fg)
    minBtn.MouseButton1Click:Connect(function()
        self:_ToggleMinimize()
    end)
end

-- ── Minimize / restore ────────────────────────────────────────────────
function Library:_ToggleMinimize()
    self._minimized = not self._minimized
    if self._minimized then
        self._origH = self.Container.AbsoluteSize.Y
        Tween(self.Container, {Size = UDim2.new(0, self.Container.AbsoluteSize.X, 0, 48)}, ANIM.Normal)
        task.delay(ANIM.Normal - 0.02, function()
            if self._minimized then self.Body.Visible = false end
        end)
        if self._resizeBtn then self._resizeBtn.Visible = false end
    else
        self.Body.Visible = true
        Tween(self.Container, {Size = UDim2.new(0, self.Container.AbsoluteSize.X, 0, self._origH)}, ANIM.Normal)
        if self._resizeBtn then self._resizeBtn.Visible = true end
    end
end

-- ── Resize handle ─────────────────────────────────────────────────────
function Library:_BuildResizeHandle()
    local handle = Inst("TextButton", {
        Name           = "ResizeHandle",
        Text           = "",
        BackgroundTransparency = 1,
        AnchorPoint    = Vector2.new(1, 1),
        Position       = UDim2.new(1, 0, 1, 0),
        Size           = UDim2.new(0, 18, 0, 18),
        ZIndex         = 8,
        Parent         = self.Container,
    })
    -- Visual indicator (two diagonal lines)
    local grip = Inst("TextLabel", {
        Text       = "⌟",
        FontFace   = F.Regular,
        TextSize   = 14,
        TextColor3 = C.Fg3,
        BackgroundTransparency = 1,
        Size       = UDim2.new(1, 0, 1, 0),
        ZIndex     = 9,
        Parent     = handle,
    })

    handle.MouseEnter:Connect(function() grip.TextColor3 = C.Fg end)
    handle.MouseLeave:Connect(function() grip.TextColor3 = C.Fg3 end)

    self._resizeBtn = handle

    local resizing = false
    local resizeStart, startSize

    handle.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
        and input.UserInputType ~= Enum.UserInputType.Touch then return end

        resizing    = true
        resizeStart = input.Position
        startSize   = self.Container.AbsoluteSize

        Library._activeDragger = function(inp)
            if not resizing then return end
            local d  = inp.Position - resizeStart
            local nw = math.clamp(startSize.X + d.X, self._minW, self._maxW)
            local nh = math.clamp(startSize.Y + d.Y, self._minH, self._maxH)
            self.Container.Size = UDim2.new(0, nw, 0, nh)
            self._origH = nh
        end

        local conn
        conn = input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                resizing = false
                Library._activeDragger = nil
                grip.TextColor3 = C.Fg3
                conn:Disconnect()
            end
        end)
    end)
end

-- ══════════════════════════════════════════════════════════════════════
-- KEYBIND LISTENER  &  MOBILE BUTTON
-- ══════════════════════════════════════════════════════════════════════
function Library:_SetupKeybindListener()
    self._connections["__keybind_global"] = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        -- Toggle UI visibility
        if input.KeyCode == self._toggleKey then
            self:Toggle()
        end
        -- Fire registered keybinds
        for _, kb in pairs(self._keybinds) do
            if input.KeyCode == kb.key then
                pcall(kb.callback)
            end
        end
    end)
end

function Library:_SetupMobileButton()
    -- Only show on touch-only devices
    if not (UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled) then return end

    local btn = Inst("TextButton", {
        Name           = "MobileToggle",
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

    -- Draggable mobile button
    local drag, dragStart, startPos = false, nil, nil
    btn.InputBegan:Connect(function(inp)
        if inp.UserInputType ~= Enum.UserInputType.Touch then return end
        drag = true; dragStart = inp.Position; startPos = btn.Position
        Library._activeDragger = function(i)
            if not drag then return end
            local d = i.Position - dragStart
            btn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
                                     startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
    btn.InputEnded:Connect(function(inp)
        if inp.UserInputType ~= Enum.UserInputType.Touch then return end
        if drag and (inp.Position - dragStart).Magnitude < 10 then self:Toggle() end
        drag = false; Library._activeDragger = nil
    end)

    self._mobileBtn = btn
end

-- ══════════════════════════════════════════════════════════════════════
-- PUBLIC API
-- ══════════════════════════════════════════════════════════════════════

--- Show or hide the entire UI window.
function Library:Toggle()
    self._visible = not self._visible
    self.Container.Visible = self._visible
    if self._mobileBtn then
        self._mobileBtn.Visible = not self._visible
    end
end

--- Change the keybind that toggles visibility.
function Library:SetToggleKey(keyCode)
    self._toggleKey = keyCode
end

--- Override the accent colour at runtime.
function Library:SetAccentColor(color)
    C.Fg = color
    -- Update existing toggle switches, sliders, etc. already in the tree
    if self._titleLabel then self._titleLabel.TextColor3 = color end
end

--- Bottom-right watermark label.
function Library:SetWatermark(text)
    if self._watermarkLabel then
        self._watermarkLabel.Text = text
        return
    end
    self._watermarkLabel = Inst("TextLabel", {
        Name           = "Watermark",
        Text           = text,
        FontFace       = F.Mono,
        TextSize       = TS.Tiny,
        TextColor3     = C.Fg3,
        TextXAlignment = Enum.TextXAlignment.Right,
        BackgroundTransparency = 1,
        AnchorPoint    = Vector2.new(1, 1),
        Position       = UDim2.new(1, -10, 1, -6),
        Size           = UDim2.new(0, 320, 0, 14),
        ZIndex         = 10,
        Parent         = self.Gui,
    })
end

--- Clean up all connections and destroy the ScreenGui.
function Library:Destroy()
    if self._autoSave then
        pcall(function() self:SaveConfig(self._currentConfig) end)
    end
    for _, c in pairs(self._connections) do
        if typeof(c) == "RBXScriptConnection" then
            pcall(function() c:Disconnect() end)
        end
    end
    self._connections = {}
    if self.Gui then self.Gui:Destroy() end
end

-- ══════════════════════════════════════════════════════════════════════
-- NOTIFICATIONS  —  toast style (top-right corner)
-- ══════════════════════════════════════════════════════════════════════
--[[
    config = {
        Title       = "string",
        Description = "string",
        Duration    = number (seconds, default 3),
        Error       = bool   (true for danger border/colour),
        Icon        = assetId string (optional ImageLabel)
    }
]]
function Library:Notify(config)
    local title    = config.Title       or "Notification"
    local desc     = config.Description or ""
    local duration = config.Duration    or 3
    local isErr    = config.Error       or false
    local icon     = config.Icon        or nil

    local accentCol = isErr and C.Danger or C.Fg
    local borderCol = isErr and C.Danger or C.LineMid

    -- Container card
    local card = Inst("Frame", {
        Name             = "Toast",
        BackgroundColor3 = C.Surface,
        BorderSizePixel  = 0,
        Size             = UDim2.new(1, 0, 0, 70),
        Position         = UDim2.new(1, 20, 0, 0),  -- starts off-screen
        ClipsDescendants = true,
        ZIndex           = 9999,
        Parent           = self._notifHolder,
    })
    Stroke(card, borderCol, 1)

    -- Title
    Inst("TextLabel", {
        Text           = title,
        FontFace       = F.Bold,
        TextSize       = TS.Normal,
        TextColor3     = accentCol,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        Position       = UDim2.new(0, 14, 0, 14),
        Size           = UDim2.new(1, icon and -48 or -28, 0, 18),
        ZIndex         = 10000,
        Parent         = card,
    })

    -- Description
    Inst("TextLabel", {
        Text           = desc,
        FontFace       = F.Regular,
        TextSize       = TS.Small,
        TextColor3     = C.Fg2,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate   = Enum.TextTruncate.AtEnd,
        BackgroundTransparency = 1,
        Position       = UDim2.new(0, 14, 0, 36),
        Size           = UDim2.new(1, icon and -48 or -28, 0, 16),
        ZIndex         = 10000,
        Parent         = card,
    })

    -- Optional icon
    if icon then
        local img = Inst("ImageLabel", {
            Image          = icon,
            BackgroundTransparency = 1,
            AnchorPoint    = Vector2.new(1, 0.5),
            Position       = UDim2.new(1, -14, 0.5, 0),
            Size           = UDim2.new(0, 20, 0, 20),
            ZIndex         = 10000,
            Parent         = card,
        })
        Inst("UIAspectRatioConstraint", {Parent = img})
    end

    -- Progress bar at bottom
    local timerBar = Inst("Frame", {
        BackgroundColor3 = accentCol,
        BorderSizePixel  = 0,
        Position         = UDim2.new(0, 0, 1, -2),
        Size             = UDim2.new(1, 0, 0, 2),
        ZIndex           = 10000,
        Parent           = card,
    })

    -- Slide in
    Tween(card, {Position = UDim2.new(0, 0, 0, 0)}, ANIM.Slow,
          Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

    -- Timer bar drains
    Tween(timerBar, {Size = UDim2.new(0, 0, 0, 2)}, duration, Enum.EasingStyle.Linear)

    -- Slide out after duration
    task.delay(duration, function()
        Tween(card, {Position = UDim2.new(1, 20, 0, 0)}, ANIM.Normal,
              Enum.EasingStyle.Quart, Enum.EasingDirection.In)
        task.wait(ANIM.Normal + 0.05)
        pcall(function() card:Destroy() end)
    end)

    return card
end

-- ══════════════════════════════════════════════════════════════════════
-- CONFIG ELEMENT REGISTRY
-- (internal — components register themselves when they have a Flag)
-- ══════════════════════════════════════════════════════════════════════
function Library:_RegConfig(flag, getter, setter)
    if flag and flag ~= "" then
        self._configElements[flag] = {getValue = getter, setValue = setter}
    end
end

-- ══════════════════════════════════════════════════════════════════════
-- CONFIG SYSTEM  —  save / load / delete
-- ══════════════════════════════════════════════════════════════════════

function Library:SaveConfig(name)
    if not writefile then
        self:Notify({Title="Error", Description="writefile not supported", Error=true})
        return false
    end
    EnsureFolder()

    local data = {}
    for flag, el in pairs(self._configElements) do
        local ok, val = pcall(el.getValue)
        if ok and val ~= nil then
            -- Serialize special types
            if typeof(val) == "Color3" then
                val = {_t = "Color3", r = val.R, g = val.G, b = val.B}
            elseif typeof(val) == "EnumItem" then
                val = {_t = "Enum", en = tostring(val.EnumType), vl = val.Name}
            end
            data[flag] = val
        end
    end

    local ok2, err = pcall(writefile, GetConfigPath(name), HttpService:JSONEncode(data))
    if ok2 then
        self._currentConfig = name
        self:Notify({Title = "Config Saved", Description = name})
        return true
    end
    self:Notify({Title = "Error", Description = "Save failed: " .. tostring(err), Error = true})
    return false
end

function Library:LoadConfig(name)
    if not (readfile and isfile) then
        self:Notify({Title="Error", Description="readfile not supported", Error=true})
        return false
    end
    local path = GetConfigPath(name)
    if not isfile(path) then
        self:Notify({Title="Error", Description="Not found: " .. name, Error=true})
        return false
    end

    local ok, data = pcall(function()
        return HttpService:JSONDecode(readfile(path))
    end)
    if not ok or type(data) ~= "table" then
        self:Notify({Title="Error", Description="Invalid config file", Error=true})
        return false
    end

    for flag, val in pairs(data) do
        if self._configElements[flag] then
            -- Deserialize special types
            if type(val) == "table" and val._t == "Color3" then
                val = Color3.new(val.r, val.g, val.b)
            elseif type(val) == "table" and val._t == "Enum" then
                val = Enum[val.en][val.vl]
            end
            pcall(self._configElements[flag].setValue, val)
        end
    end

    self._currentConfig = name
    self:Notify({Title = "Config Loaded", Description = name})
    return true
end

function Library:DeleteConfig(name)
    if not (delfile and isfile) then return false end
    local path = GetConfigPath(name)
    if isfile(path) then
        pcall(delfile, path)
        self:Notify({Title = "Config Deleted", Description = name})
        return true
    end
    return false
end

function Library:GetConfigs()
    return ListConfigs()
end

function Library:SetAutoSave(enabled)
    self._autoSave = enabled
    if enabled then
        task.spawn(function()
            while self._autoSave and self.Gui and self.Gui.Parent do
                task.wait(30)
                if self._autoSave then
                    pcall(function() self:SaveConfig(self._currentConfig) end)
                end
            end
        end)
    end
end

-- ══════════════════════════════════════════════════════════════════════
-- TAB SYSTEM  —  sidebar nav + content frames
-- ══════════════════════════════════════════════════════════════════════
--[[
    Usage:
        local tab = window:CreateTab("Player", "rbxassetid://...")
        tab:CreateToggle({ Name="Noclip", ... })
]]
function Library:CreateTab(name, icon)

    -- ── Sidebar nav item ──────────────────────────────────────────────
    local navItem = Inst("Frame", {
        Name             = "NavItem_" .. name,
        BackgroundColor3 = C.Bg,
        BackgroundTransparency = 1,
        BorderSizePixel  = 0,
        Size             = UDim2.new(1, 0, 0, 38),
        Parent           = self.Sidebar,
    })

    -- Left accent stripe (visible when active)
    local accentStripe = Inst("Frame", {
        Name             = "Stripe",
        BackgroundColor3 = C.Fg,
        BackgroundTransparency = 1,
        BorderSizePixel  = 0,
        Size             = UDim2.new(0, 2, 1, 0),
        ZIndex           = 2,
        Parent           = navItem,
    })

    -- Icon image
    local iconImg = Inst("ImageLabel", {
        Name             = "Icon",
        Image            = icon or "rbxassetid://112235310154264",
        ImageColor3      = C.Fg3,
        BackgroundTransparency = 1,
        AnchorPoint      = Vector2.new(0, 0.5),
        Position         = UDim2.new(0, 20, 0.5, -8),
        Size             = UDim2.new(0, 16, 0, 16),
        ZIndex           = 2,
        Parent           = navItem,
    })

    -- Label text
    local navText = Inst("TextLabel", {
        Name             = "NavText",
        Text             = name,
        FontFace         = F.Medium,
        TextSize         = TS.Normal,
        TextColor3       = C.Fg2,
        TextXAlignment   = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        Position         = UDim2.new(0, 46, 0, 0),
        Size             = UDim2.new(1, -54, 1, 0),
        ZIndex           = 2,
        Parent           = navItem,
    })

    -- Click area
    local clickArea = Inst("TextButton", {
        Text             = "",
        BackgroundTransparency = 1,
        Size             = UDim2.new(1, 0, 1, 0),
        ZIndex           = 3,
        Parent           = navItem,
    })

    -- ── Content frame (right panel) ───────────────────────────────────
    -- Each tab gets its own ScrollingFrame that fills the ContentArea.
    -- They are NOT laid out by ContentArea's UIListLayout —
    -- only one is Visible at a time and they all share the same space.
    local content = Inst("ScrollingFrame", {
        Name                  = name .. "_Content",
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        Size                   = UDim2.new(1, 0, 1, 0),
        CanvasSize             = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize    = Enum.AutomaticSize.Y,
        ScrollBarThickness     = 2,
        ScrollBarImageColor3   = C.LineMid,
        ScrollingDirection     = Enum.ScrollingDirection.Y,
        Visible                = false,
        Parent                 = self.ContentArea,
    })
    List(content, 8)
    Pad(content, 20, 20, 20, 20)

    -- ── Tab data table ────────────────────────────────────────────────
    local tab = {
        name    = name,
        navItem = navItem,
        stripe  = accentStripe,
        icon    = iconImg,
        text    = navText,
        content = content,
        _lib    = self,
    }

    -- ── Hover states ──────────────────────────────────────────────────
    clickArea.MouseEnter:Connect(function()
        if self.currentTab == tab then return end
        navItem.BackgroundTransparency = 0.88
        navItem.BackgroundColor3       = C.Fg
        navText.TextColor3             = C.Fg
        iconImg.ImageColor3            = C.Fg2
    end)
    clickArea.MouseLeave:Connect(function()
        if self.currentTab == tab then return end
        navItem.BackgroundTransparency = 1
        navText.TextColor3             = C.Fg2
        iconImg.ImageColor3            = C.Fg3
    end)

    -- ── Click to select ───────────────────────────────────────────────
    clickArea.MouseButton1Click:Connect(function()
        self:_SelectTab(tab)
    end)

    table.insert(self.tabs, tab)
    if not self.currentTab then self:_SelectTab(tab) end

    -- ── Wrap tab with all component methods ───────────────────────────
    local m = setmetatable({}, {__index = tab})
    function m:CreateSectionHeader(n)   return Library._SectionHeader(self, n) end
    function m:CreateLabel(c)           return Library._Label(self, c) end
    function m:CreateSeparator(c)       return Library._Separator(self, c) end
    function m:CreateParagraph(c)       return Library._Paragraph(self, c) end
    function m:CreateButton(c)          return Library._Button(self, c) end
    function m:CreateToggle(c)          return Library._Toggle(self, c) end
    function m:CreateSlider(c)          return Library._Slider(self, c) end
    function m:CreateTextBox(c)         return Library._TextBox(self, c) end
    function m:CreateDropdown(c)        return Library._Dropdown(self, c) end
    function m:CreateCheckbox(c)        return Library._Checkbox(self, c) end
    function m:CreateKeybind(c)         return Library._Keybind(self, c) end
    function m:CreateColorPicker(c)     return Library._ColorPicker(self, c) end
    function m:CreateProgressBar(c)     return Library._ProgressBar(self, c) end
    function m:CreateTable(c)           return Library._Table(self, c) end
    function m:CreateBadge(c)           return Library._Badge(self, c) end
    function m:CreateRadioGroup(c)      return Library._RadioGroup(self, c) end
    function m:CreateConfigSection()    return Library._ConfigSection(self) end

    return m
end

-- ── Select tab (deselect previous, activate new) ─────────────────────
function Library:_SelectTab(tab)
    -- Deactivate current tab
    if self.currentTab then
        local p = self.currentTab
        p.content.Visible               = false
        p.navItem.BackgroundTransparency = 1
        p.stripe.BackgroundTransparency  = 1
        p.text.TextColor3               = C.Fg2
        p.text.FontFace                 = F.Medium
        p.icon.ImageColor3              = C.Fg3
    end

    -- Activate new tab
    self.currentTab = tab
    tab.content.Visible               = true
    tab.navItem.BackgroundTransparency = 0
    tab.navItem.BackgroundColor3      = C.Surface
    tab.stripe.BackgroundTransparency  = 0
    tab.text.TextColor3               = C.Fg
    tab.text.FontFace                 = F.SemiBold
    tab.icon.ImageColor3              = C.Fg

    -- Reset this tab's scroll to top
    tab.content.CanvasPosition = Vector2.zero
end

-- ══════════════════════════════════════════════════════════════════════
-- COMPONENT: SECTION HEADER
-- ══════════════════════════════════════════════════════════════════════
function Library._SectionHeader(tab, name)
    return Inst("TextLabel", {
        Name           = "SectionHeader",
        Text           = string.upper(name),
        FontFace       = F.Bold,
        TextSize       = TS.Tiny,
        TextColor3     = C.Fg3,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        Size           = UDim2.new(1, 0, 0, 22),
        Parent         = tab.content,
    })
end

-- ══════════════════════════════════════════════════════════════════════
-- COMPONENT: LABEL
-- ══════════════════════════════════════════════════════════════════════
--[[
    config = { Text, Color, TextSize }
]]
function Library._Label(tab, config)
    local text  = config.Text     or "Label"
    local color = config.Color    or C.Fg2
    local tsize = config.TextSize or TS.Normal

    local lbl = Inst("TextLabel", {
        Text           = text,
        FontFace       = F.Regular,
        TextSize       = tsize,
        TextColor3     = color,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped    = true,
        BackgroundTransparency = 1,
        AutomaticSize  = Enum.AutomaticSize.Y,
        Size           = UDim2.new(1, 0, 0, 0),
        Parent         = tab.content,
    })

    return {
        SetText  = function(_, t)  lbl.Text = t end,
        SetColor = function(_, co) lbl.TextColor3 = co end,
        GetText  = function()      return lbl.Text end,
    }
end

-- ══════════════════════════════════════════════════════════════════════
-- COMPONENT: SEPARATOR
-- ══════════════════════════════════════════════════════════════════════
--[[
    config = { Text }  (optional centered label)
]]
function Library._Separator(tab, config)
    local text = config and config.Text

    local wrap = Inst("Frame", {
        Name           = "Separator",
        BackgroundTransparency = 1,
        Size           = UDim2.new(1, 0, 0, 16),
        Parent         = tab.content,
    })

    if text and text ~= "" then
        -- Left line
        local ll = Inst("Frame", {
            BackgroundColor3 = C.Line,
            BorderSizePixel  = 0,
            AnchorPoint      = Vector2.new(0, 0.5),
            Position         = UDim2.new(0, 0, 0.5, 0),
            Size             = UDim2.new(0.1, 0, 0, 1),
            Parent           = wrap,
        })
        -- Center text
        local ct = Inst("TextLabel", {
            Text           = string.upper(text),
            FontFace       = F.Bold,
            TextSize       = TS.Tiny,
            TextColor3     = C.Fg3,
            BackgroundTransparency = 1,
            AnchorPoint    = Vector2.new(0.5, 0.5),
            Position       = UDim2.new(0.5, 0, 0.5, 0),
            AutomaticSize  = Enum.AutomaticSize.X,
            Size           = UDim2.new(0, 0, 1, 0),
            Parent         = wrap,
        })
        -- Right line
        local rl = Inst("Frame", {
            BackgroundColor3 = C.Line,
            BorderSizePixel  = 0,
            AnchorPoint      = Vector2.new(1, 0.5),
            Position         = UDim2.new(1, 0, 0.5, 0),
            Size             = UDim2.new(0.1, 0, 0, 1),
            Parent           = wrap,
        })
        -- Adjust lines after label resolves
        task.defer(function()
            local lw = ct.AbsoluteSize.X
            local tw = wrap.AbsoluteSize.X
            local ew = math.max(0, math.floor((tw - lw - 16) / 2))
            ll.Size = UDim2.new(0, ew, 0, 1)
            rl.Size = UDim2.new(0, ew, 0, 1)
        end)
    else
        Inst("Frame", {
            BackgroundColor3 = C.Line,
            BorderSizePixel  = 0,
            AnchorPoint      = Vector2.new(0, 0.5),
            Position         = UDim2.new(0, 0, 0.5, 0),
            Size             = UDim2.new(1, 0, 0, 1),
            Parent           = wrap,
        })
    end

    return wrap
end

-- ══════════════════════════════════════════════════════════════════════
-- COMPONENT: PARAGRAPH  (info card)
-- ══════════════════════════════════════════════════════════════════════
--[[
    config = { Title, Content }
]]
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
        Text           = title,
        FontFace       = F.SemiBold,
        TextSize       = TS.Normal,
        TextColor3     = C.Fg,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        Size           = UDim2.new(1, 0, 0, 20),
        Parent         = frame,
    })
    local contLbl = Inst("TextLabel", {
        Text           = content,
        FontFace       = F.Regular,
        TextSize       = TS.Small,
        TextColor3     = C.Fg2,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped    = true,
        BackgroundTransparency = 1,
        AutomaticSize  = Enum.AutomaticSize.Y,
        Position       = UDim2.new(0, 0, 0, 24),
        Size           = UDim2.new(1, 0, 0, 0),
        Parent         = frame,
    })

    return {
        SetTitle   = function(_, t) titleLbl.Text = t end,
        SetContent = function(_, t) contLbl.Text  = t end,
        GetTitle   = function()     return titleLbl.Text end,
        GetContent = function()     return contLbl.Text end,
    }
end

-- ══════════════════════════════════════════════════════════════════════
-- COMPONENT: BUTTON
-- ══════════════════════════════════════════════════════════════════════
--[[
    config = {
        Name     = "string",
        Style    = "primary" | "ghost" | "danger",
        Callback = function
    }
]]
function Library._Button(tab, config)
    local name     = config.Name     or "Button"
    local style    = config.Style    or "primary"
    local callback = config.Callback or function() end

    -- Determine colours per style
    local bgNormal, bgHover, bgClick, fgColor, strokeColor
    if style == "primary" then
        bgNormal  = C.Fg
        bgHover   = Color3.fromRGB(210, 210, 210)
        bgClick   = Color3.fromRGB(160, 160, 160)
        fgColor   = C.Bg
        strokeColor = nil
    elseif style == "danger" then
        bgNormal  = C.Bg
        bgHover   = Color3.fromRGB(14, 0, 0)
        bgClick   = Color3.fromRGB(30, 0, 0)
        fgColor   = C.Danger
        strokeColor = C.Danger
    else -- ghost
        bgNormal  = C.Bg
        bgHover   = C.Surface2
        bgClick   = C.Surface
        fgColor   = C.Fg
        strokeColor = C.LineMid
    end

    local frame = Inst("Frame", {
        Name             = "Button_" .. name,
        BackgroundColor3 = bgNormal,
        BorderSizePixel  = 0,
        Size             = UDim2.new(1, 0, 0, 36),
        Parent           = tab.content,
    })
    if strokeColor then Stroke(frame, strokeColor, 1) end

    local lbl = Inst("TextLabel", {
        Text           = name,
        FontFace       = F.SemiBold,
        TextSize       = TS.Normal,
        TextColor3     = fgColor,
        BackgroundTransparency = 1,
        Size           = UDim2.new(1, 0, 1, 0),
        Parent         = frame,
    })

    local btn = Inst("TextButton", {
        Text           = "",
        BackgroundTransparency = 1,
        Size           = UDim2.new(1, 0, 1, 0),
        Parent         = frame,
    })

    btn.MouseEnter:Connect(function()
        Tween(frame, {BackgroundColor3 = bgHover}, ANIM.Fast)
    end)
    btn.MouseLeave:Connect(function()
        Tween(frame, {BackgroundColor3 = bgNormal}, ANIM.Fast)
    end)
    btn.MouseButton1Down:Connect(function()
        Tween(frame, {BackgroundColor3 = bgClick}, ANIM.Fast)
    end)
    btn.MouseButton1Up:Connect(function()
        Tween(frame, {BackgroundColor3 = bgHover}, ANIM.Fast)
    end)
    btn.MouseButton1Click:Connect(function()
        pcall(callback)
    end)

    return {
        SetText = function(_, t) lbl.Text = t end,
        GetText = function()     return lbl.Text end,
    }
end

-- ══════════════════════════════════════════════════════════════════════
-- COMPONENT: TOGGLE  (sharp rectangular switch)
-- ══════════════════════════════════════════════════════════════════════
--[[
    config = { Name, Default, Callback, Flag }
]]
function Library._Toggle(tab, config)
    local name     = config.Name     or "Toggle"
    local default  = config.Default  or false
    local callback = config.Callback or function() end
    local flag     = config.Flag
    local enabled  = default

    local frame = Inst("Frame", {
        Name             = "Toggle_" .. name,
        BackgroundColor3 = C.Surface,
        BorderSizePixel  = 0,
        Size             = UDim2.new(1, 0, 0, 38),
        Parent           = tab.content,
    })
    Stroke(frame, C.Line, 1)

    -- Hover effect on row
    local rowBtn = Inst("TextButton", {
        Text             = "",
        BackgroundTransparency = 1,
        Size             = UDim2.new(1, 0, 1, 0),
        Parent           = frame,
    })
    rowBtn.MouseEnter:Connect(function() Tween(frame, {BackgroundColor3 = C.Surface2}, ANIM.Fast) end)
    rowBtn.MouseLeave:Connect(function() Tween(frame, {BackgroundColor3 = C.Surface}, ANIM.Fast) end)

    -- Name label
    Inst("TextLabel", {
        Text           = name,
        FontFace       = F.Medium,
        TextSize       = TS.Normal,
        TextColor3     = C.Fg,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        Position       = UDim2.new(0, 14, 0, 0),
        Size           = UDim2.new(1, -66, 1, 0),
        Parent         = frame,
    })

    -- Track (sharp rectangle)
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

    -- Indicator square
    local indicator = Inst("Frame", {
        BackgroundColor3 = enabled and C.Bg or C.Fg3,
        BorderSizePixel  = 0,
        AnchorPoint      = Vector2.new(0, 0.5),
        Position         = enabled
            and UDim2.new(0, 22, 0.5, 0)
            or  UDim2.new(0,  4, 0.5, 0),
        Size             = UDim2.new(0, 12, 0, 12),
        ZIndex           = 3,
        Parent           = track,
    })

    local function SetVisual(state)
        Tween(track,     {BackgroundColor3 = state and C.Fg or C.Surface2}, ANIM.Fast)
        Tween(indicator, {BackgroundColor3 = state and C.Bg or C.Fg3},      ANIM.Fast)
        Tween(indicator, {Position = state
            and UDim2.new(0, 22, 0.5, 0)
            or  UDim2.new(0,  4, 0.5, 0)}, ANIM.Fast)
        trackStroke.Color = state and C.Fg or C.LineMid
    end

    rowBtn.MouseButton1Click:Connect(function()
        enabled = not enabled
        SetVisual(enabled)
        pcall(callback, enabled)
    end)

    local methods = {
        SetValue = function(_, v)
            enabled = v; SetVisual(enabled); pcall(callback, enabled)
        end,
        GetValue = function() return enabled end,
    }
    tab._lib:_RegConfig(flag,
        function() return enabled end,
        function(v) methods:SetValue(v) end)
    return methods
end

-- ══════════════════════════════════════════════════════════════════════
-- COMPONENT: SLIDER
-- ══════════════════════════════════════════════════════════════════════
--[[
    config = { Name, Min, Max, Default, Step, Suffix, Callback, Flag }
]]
function Library._Slider(tab, config)
    local name     = config.Name     or "Slider"
    local min      = config.Min      or 0
    local max      = config.Max      or 100
    local default  = config.Default  or min
    local step     = config.Step     or 1
    local suffix   = config.Suffix   or ""
    local callback = config.Callback or function() end
    local flag     = config.Flag

    -- Calculate decimal places from step
    local decimals = 0
    local stepStr  = tostring(step)
    local dotPos   = stepStr:find("%.")
    if dotPos then decimals = #stepStr - dotPos end

    local function Snap(raw)
        if step <= 0 then return raw end
        local snapped = math.floor((raw - min) / step + 0.5) * step + min
        snapped = math.clamp(snapped, min, max)
        if decimals > 0 then
            local m = 10 ^ decimals
            return math.floor(snapped * m + 0.5) / m
        end
        return math.floor(snapped + 0.5)
    end

    local function Fmt(v)
        if decimals > 0 then
            return string.format("%." .. decimals .. "f", v) .. suffix
        end
        return tostring(math.floor(v)) .. suffix
    end

    local current = Snap(math.clamp(default, min, max))

    -- Frame
    local frame = Inst("Frame", {
        Name             = "Slider_" .. name,
        BackgroundColor3 = C.Surface,
        BorderSizePixel  = 0,
        Size             = UDim2.new(1, 0, 0, 52),
        Parent           = tab.content,
    })
    Stroke(frame, C.Line, 1)

    -- Name label
    Inst("TextLabel", {
        Text           = name,
        FontFace       = F.Medium,
        TextSize       = TS.Normal,
        TextColor3     = C.Fg,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        Position       = UDim2.new(0, 14, 0, 8),
        Size           = UDim2.new(0.65, -14, 0, 18),
        Parent         = frame,
    })

    -- Value label (mono font, right-aligned)
    local valLbl = Inst("TextLabel", {
        Text           = Fmt(current),
        FontFace       = F.Mono,
        TextSize       = TS.Small,
        TextColor3     = C.Fg2,
        TextXAlignment = Enum.TextXAlignment.Right,
        BackgroundTransparency = 1,
        AnchorPoint    = Vector2.new(1, 0),
        Position       = UDim2.new(1, -14, 0, 8),
        Size           = UDim2.new(0, 80, 0, 18),
        Parent         = frame,
    })

    -- Track background (3 px tall, 1px border)
    local trackBg = Inst("Frame", {
        BackgroundColor3 = C.Line,
        BorderSizePixel  = 0,
        Position         = UDim2.new(0, 14, 0, 36),
        Size             = UDim2.new(1, -28, 0, 3),
        Parent           = frame,
    })

    -- Fill
    local pct0 = (current - min) / math.max(max - min, 0.001)
    local fill = Inst("Frame", {
        BackgroundColor3 = C.Fg,
        BorderSizePixel  = 0,
        Size             = UDim2.new(pct0, 0, 1, 0),
        Parent           = trackBg,
    })

    -- Square knob
    local knob = Inst("Frame", {
        BackgroundColor3 = C.Fg,
        BorderSizePixel  = 0,
        AnchorPoint      = Vector2.new(0.5, 0.5),
        Position         = UDim2.new(pct0, 0, 0.5, 0),
        Size             = UDim2.new(0, 10, 0, 10),
        ZIndex           = 2,
        Parent           = trackBg,
    })

    -- Larger invisible hit area over track
    local hitArea = Inst("TextButton", {
        Text             = "",
        BackgroundTransparency = 1,
        Position         = UDim2.new(0, 0, -1, 0),
        Size             = UDim2.new(1, 0, 3, 0),
        ZIndex           = 3,
        Parent           = trackBg,
    })

    local function Apply(inp)
        local rel = math.clamp(
            (inp.Position.X - trackBg.AbsolutePosition.X) / trackBg.AbsoluteSize.X,
            0, 1)
        current = Snap(min + (max - min) * rel)
        local pct = (current - min) / math.max(max - min, 0.001)
        fill.Size     = UDim2.new(pct, 0, 1, 0)
        knob.Position = UDim2.new(pct, 0, 0.5, 0)
        valLbl.Text   = Fmt(current)
        pcall(callback, current)
    end

    hitArea.InputBegan:Connect(function(inp)
        if inp.UserInputType ~= Enum.UserInputType.MouseButton1
        and inp.UserInputType ~= Enum.UserInputType.Touch then return end
        Apply(inp)
        Library._activeDragger = Apply
    end)
    hitArea.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            Library._activeDragger = nil
        end
    end)

    local methods = {
        SetValue = function(_, v)
            current = Snap(math.clamp(v, min, max))
            local pct = (current - min) / math.max(max - min, 0.001)
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

-- ══════════════════════════════════════════════════════════════════════
-- COMPONENT: TEXT BOX
-- ══════════════════════════════════════════════════════════════════════
--[[
    config = {
        Name, Default, Placeholder,
        NumbersOnly = bool,
        ClearOnFocus = bool,
        Callback = function(text, enterPressed),
        Flag
    }
]]
function Library._TextBox(tab, config)
    local name        = config.Name         or "TextBox"
    local default     = config.Default      or ""
    local placeholder = config.Placeholder  or "Enter text..."
    local numbersOnly = config.NumbersOnly  or false
    local clearFocus  = config.ClearOnFocus or false
    local callback    = config.Callback     or function() end
    local flag        = config.Flag
    local current     = tostring(default)

    local frame = Inst("Frame", {
        Name             = "TextBox_" .. name,
        BackgroundColor3 = C.Surface,
        BorderSizePixel  = 0,
        Size             = UDim2.new(1, 0, 0, 38),
        Parent           = tab.content,
    })
    Stroke(frame, C.Line, 1)

    Inst("TextLabel", {
        Text           = name,
        FontFace       = F.Medium,
        TextSize       = TS.Normal,
        TextColor3     = C.Fg,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        Position       = UDim2.new(0, 14, 0, 0),
        Size           = UDim2.new(0.45, -14, 1, 0),
        Parent         = frame,
    })

    local inputBg = Inst("Frame", {
        BackgroundColor3 = C.Bg,
        BorderSizePixel  = 0,
        AnchorPoint      = Vector2.new(1, 0.5),
        Position         = UDim2.new(1, -14, 0.5, 0),
        Size             = UDim2.new(0, 175, 0, 26),
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
        ClearTextOnFocus  = clearFocus,
        Position          = UDim2.new(0, 8, 0, 0),
        Size              = UDim2.new(1, -16, 1, 0),
        Parent            = inputBg,
    })

    input.Focused:Connect(function()
        Tween(inputBg, {BackgroundColor3 = C.Surface2}, ANIM.Fast)
        inputStroke.Color = C.Fg
    end)
    input.FocusLost:Connect(function(enter)
        Tween(inputBg, {BackgroundColor3 = C.Bg}, ANIM.Fast)
        inputStroke.Color = C.LineMid
        if numbersOnly then
            local n = tonumber(input.Text)
            if n then current = tostring(n); input.Text = current
            else      input.Text = current end
        else
            current = input.Text
        end
        pcall(callback, current, enter)
    end)

    if numbersOnly then
        input:GetPropertyChangedSignal("Text"):Connect(function()
            local filtered = input.Text:gsub("[^%d%.%-]", "")
            if input.Text ~= filtered then input.Text = filtered end
        end)
    end

    local methods = {
        SetText        = function(_, t)   current = tostring(t); input.Text = current end,
        GetText        = function()       return current end,
        SetPlaceholder = function(_, t)   input.PlaceholderText = t end,
        Focus          = function()       input:CaptureFocus() end,
    }
    tab._lib:_RegConfig(flag,
        function() return current end,
        function(v) methods:SetText(v) end)
    return methods
end

-- ══════════════════════════════════════════════════════════════════════
-- COMPONENT: DROPDOWN  (single / multi-select + optional search box)
-- ══════════════════════════════════════════════════════════════════════
--[[
    config = {
        Name, Options = {}, Default,
        MultiSelect = bool,
        SearchBox   = bool (default true when options > 5),
        Callback    = function(selected),
        Flag
    }
]]
function Library._Dropdown(tab, config)
    local name        = config.Name        or "Dropdown"
    local options     = config.Options     or {}
    local multiSelect = config.MultiSelect or false
    local callback    = config.Callback    or function() end
    local flag        = config.Flag
    local lib         = tab._lib

    -- Determine initial selection
    local selected
    if multiSelect then
        selected = (type(config.Default) == "table") and config.Default or {}
    else
        selected = config.Default or (options[1] or "")
    end

    local expanded    = false
    -- Show search box when > 5 options (can be overridden with SearchBox = false)
    local showSearch  = (config.SearchBox ~= false) and (#options > 5)
    local maxVisible  = 5
    local optionH     = 28

    -- ── Outer frame ───────────────────────────────────────────────────
    local frame = Inst("Frame", {
        Name             = "Dropdown_" .. name,
        BackgroundColor3 = C.Surface,
        BorderSizePixel  = 0,
        Size             = UDim2.new(1, 0, 0, 38),
        ClipsDescendants = false,
        ZIndex           = 1,
        Parent           = tab.content,
    })
    Stroke(frame, C.Line, 1)

    -- Row hover
    local rowHover = Inst("TextButton", {
        Text = "", BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0), ZIndex = 2, Parent = frame,
    })
    rowHover.MouseEnter:Connect(function() Tween(frame, {BackgroundColor3 = C.Surface2}, ANIM.Fast) end)
    rowHover.MouseLeave:Connect(function() Tween(frame, {BackgroundColor3 = C.Surface}, ANIM.Fast) end)

    Inst("TextLabel", {
        Text           = name,
        FontFace       = F.Medium,
        TextSize       = TS.Normal,
        TextColor3     = C.Fg,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        Position       = UDim2.new(0, 14, 0, 0),
        Size           = UDim2.new(0.45, -14, 1, 0),
        ZIndex         = 3,
        Parent         = frame,
    })

    -- Display box (current selection)
    local displayBg = Inst("Frame", {
        BackgroundColor3 = C.Bg,
        BorderSizePixel  = 0,
        AnchorPoint      = Vector2.new(1, 0.5),
        Position         = UDim2.new(1, -14, 0.5, 0),
        Size             = UDim2.new(0, 175, 0, 26),
        ZIndex           = 3,
        Parent           = frame,
    })
    Stroke(displayBg, C.LineMid, 1)

    local function GetDisplayText()
        if multiSelect then
            return #selected > 0 and table.concat(selected, ", ") or "None"
        end
        return tostring(selected)
    end

    local selLbl = Inst("TextLabel", {
        Text           = GetDisplayText(),
        FontFace       = F.Regular,
        TextSize       = TS.Small,
        TextColor3     = C.Fg,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate   = Enum.TextTruncate.AtEnd,
        BackgroundTransparency = 1,
        Position       = UDim2.new(0, 8, 0, 0),
        Size           = UDim2.new(1, -24, 1, 0),
        ZIndex         = 4,
        Parent         = displayBg,
    })

    local arrowLbl = Inst("TextLabel", {
        Text           = "▾",
        FontFace       = F.Regular,
        TextSize       = TS.Tiny,
        TextColor3     = C.Fg3,
        BackgroundTransparency = 1,
        AnchorPoint    = Vector2.new(1, 0.5),
        Position       = UDim2.new(1, -6, 0.5, 0),
        Size           = UDim2.new(0, 12, 0, 12),
        ZIndex         = 4,
        Parent         = displayBg,
    })

    -- ── Options list (floats below the row) ───────────────────────────
    local searchH    = showSearch and 30 or 0
    local listHeight = math.min(#options, maxVisible) * optionH + searchH

    local listFrame = Inst("Frame", {
        BackgroundColor3 = C.Surface,
        BorderSizePixel  = 0,
        Position         = UDim2.new(1, -189, 0, 40),
        Size             = UDim2.new(0, 175, 0, listHeight),
        Visible          = false,
        ZIndex           = 50,
        ClipsDescendants = true,
        Parent           = frame,
    })
    Stroke(listFrame, C.LineMid, 1)

    -- Optional search input
    local searchBox = nil
    if showSearch then
        local searchBg = Inst("Frame", {
            BackgroundColor3 = C.Bg,
            BorderSizePixel  = 0,
            Position         = UDim2.new(0, 0, 0, 0),
            Size             = UDim2.new(1, 0, 0, searchH),
            ZIndex           = 51,
            Parent           = listFrame,
        })
        HDivider(searchBg, searchH - 1)
        searchBox = Inst("TextBox", {
            Text              = "",
            PlaceholderText   = "Search...",
            PlaceholderColor3 = C.Fg3,
            FontFace          = F.Regular,
            TextSize          = TS.Small,
            TextColor3        = C.Fg,
            TextXAlignment    = Enum.TextXAlignment.Left,
            BackgroundTransparency = 1,
            ClearTextOnFocus  = false,
            Position          = UDim2.new(0, 10, 0, 0),
            Size              = UDim2.new(1, -10, 1, 0),
            ZIndex            = 52,
            Parent            = searchBg,
        })
    end

    -- Scrollable options container
    local listScroll = Inst("ScrollingFrame", {
        BackgroundTransparency = 1,
        BorderSizePixel  = 0,
        Position         = UDim2.new(0, 0, 0, searchH),
        Size             = UDim2.new(1, 0, 1, -searchH),
        CanvasSize       = UDim2.new(0, 0, 0, #options * optionH),
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = C.LineMid,
        ZIndex           = 51,
        Parent           = listFrame,
    })
    List(listScroll, 0)

    local function IsSelected(opt)
        if multiSelect then return table.find(selected, opt) ~= nil end
        return selected == opt
    end

    local function RebuildOptions(filterText)
        -- Destroy old buttons
        for _, c in ipairs(listScroll:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end

        local visible = 0
        for _, opt in ipairs(options) do
            local show = (not filterText or filterText == "")
                      or opt:lower():find(filterText:lower(), 1, true) ~= nil
            if show then
                visible = visible + 1
                local sel = IsSelected(opt)
                local ob  = Inst("TextButton", {
                    Name             = opt,
                    Text             = opt,
                    FontFace         = sel and F.SemiBold or F.Regular,
                    TextSize         = TS.Small,
                    TextColor3       = sel and C.Fg or C.Fg2,
                    TextXAlignment   = Enum.TextXAlignment.Left,
                    BackgroundColor3 = sel and C.Surface2 or C.Surface,
                    BackgroundTransparency = sel and 0 or 1,
                    BorderSizePixel  = 0,
                    Size             = UDim2.new(1, 0, 0, optionH),
                    ZIndex           = 52,
                    Parent           = listScroll,
                })
                Pad(ob, 0, 0, 10, 0)

                ob.MouseEnter:Connect(function()
                    ob.BackgroundTransparency = 0
                    ob.BackgroundColor3       = C.Surface2
                    ob.TextColor3             = C.Fg
                end)
                ob.MouseLeave:Connect(function()
                    ob.BackgroundTransparency = IsSelected(opt) and 0 or 1
                    ob.TextColor3             = IsSelected(opt) and C.Fg or C.Fg2
                end)
                ob.MouseButton1Click:Connect(function()
                    if multiSelect then
                        local idx = table.find(selected, opt)
                        if idx then table.remove(selected, idx)
                        else        table.insert(selected, opt) end
                        selLbl.Text = GetDisplayText()
                        pcall(callback, selected)
                        RebuildOptions(searchBox and searchBox.Text or nil)
                    else
                        selected    = opt
                        selLbl.Text = GetDisplayText()
                        pcall(callback, selected)
                        -- Close on single-select
                        expanded          = false
                        listFrame.Visible = false
                        arrowLbl.Text     = "▾"
                        frame.ZIndex      = 1
                        if Library._activeDropdown == CloseDropdown then
                            Library._activeDropdown = nil
                        end
                        RebuildOptions()
                    end
                end)
            end
        end

        -- Resize list to match visible options
        local newH = math.min(visible, maxVisible) * optionH
        listScroll.CanvasSize = UDim2.new(0, 0, 0, visible * optionH)
        listFrame.Size        = UDim2.new(0, 175, 0, newH + searchH)
    end

    RebuildOptions()

    if searchBox then
        searchBox:GetPropertyChangedSignal("Text"):Connect(function()
            RebuildOptions(searchBox.Text)
        end)
    end

    -- Close function (shared between toggle + outside-click)
    function CloseDropdown()
        expanded          = false
        listFrame.Visible = false
        arrowLbl.Text     = "▾"
        frame.ZIndex      = 1
        if searchBox then searchBox.Text = "" end
        RebuildOptions()
        if Library._activeDropdown == CloseDropdown then
            Library._activeDropdown = nil
        end
    end

    -- Toggle button over display box
    local toggleBtn = Inst("TextButton", {
        Text = "", BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0), ZIndex = 5, Parent = displayBg,
    })
    toggleBtn.MouseButton1Click:Connect(function()
        if expanded then
            CloseDropdown()
        else
            if Library._activeDropdown then Library._activeDropdown() end
            expanded          = true
            listFrame.Visible = true
            arrowLbl.Text     = "▴"
            frame.ZIndex      = 10
            Library._activeDropdown = CloseDropdown
        end
    end)

    -- Close when clicking outside
    lib._connections["dd_outside_" .. tostring(frame)] = UserInputService.InputBegan:Connect(function(inp)
        if not expanded then return end
        if inp.UserInputType ~= Enum.UserInputType.MouseButton1
        and inp.UserInputType ~= Enum.UserInputType.Touch then return end
        local mp = inp.Position
        local lp_, ls = listFrame.AbsolutePosition, listFrame.AbsoluteSize
        local fp, fs   = frame.AbsolutePosition,    frame.AbsoluteSize
        local inList   = mp.X >= lp_.X and mp.X <= lp_.X + ls.X
                     and mp.Y >= lp_.Y and mp.Y <= lp_.Y + ls.Y
        local inHeader = mp.X >= fp.X  and mp.X <= fp.X  + fs.X
                     and mp.Y >= fp.Y  and mp.Y <= fp.Y  + fs.Y
        if not inList and not inHeader then CloseDropdown() end
    end)

    local methods = {
        SetValue = function(_, v)
            if multiSelect and type(v) == "table" then selected = v
            elseif not multiSelect then selected = v end
            selLbl.Text = GetDisplayText()
            RebuildOptions()
            pcall(callback, selected)
        end,
        GetValue = function() return selected end,
        Refresh  = function(_, newOpts)
            options = newOpts
            RebuildOptions(searchBox and searchBox.Text or nil)
        end,
    }
    tab._lib:_RegConfig(flag,
        function() return selected end,
        function(v) methods:SetValue(v) end)
    return methods
end

-- ══════════════════════════════════════════════════════════════════════
-- COMPONENT: CHECKBOX  (sharp square)
-- ══════════════════════════════════════════════════════════════════════
--[[
    config = { Name, Default, Callback, Flag }
]]
function Library._Checkbox(tab, config)
    local name     = config.Name     or "Checkbox"
    local default  = config.Default  or false
    local callback = config.Callback or function() end
    local flag     = config.Flag
    local enabled  = default

    local frame = Inst("Frame", {
        Name             = "Checkbox_" .. name,
        BackgroundColor3 = C.Surface,
        BorderSizePixel  = 0,
        Size             = UDim2.new(1, 0, 0, 38),
        Parent           = tab.content,
    })
    Stroke(frame, C.Line, 1)

    local rowBtn = Inst("TextButton", {
        Text = "", BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0), Parent = frame,
    })
    rowBtn.MouseEnter:Connect(function() Tween(frame, {BackgroundColor3 = C.Surface2}, ANIM.Fast) end)
    rowBtn.MouseLeave:Connect(function() Tween(frame, {BackgroundColor3 = C.Surface}, ANIM.Fast) end)

    Inst("TextLabel", {
        Text           = name,
        FontFace       = F.Medium,
        TextSize       = TS.Normal,
        TextColor3     = C.Fg,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        Position       = UDim2.new(0, 14, 0, 0),
        Size           = UDim2.new(1, -44, 1, 0),
        Parent         = frame,
    })

    -- Square checkbox
    local box = Inst("Frame", {
        BackgroundColor3 = enabled and C.Fg or C.Bg,
        BorderSizePixel  = 0,
        AnchorPoint      = Vector2.new(1, 0.5),
        Position         = UDim2.new(1, -14, 0.5, 0),
        Size             = UDim2.new(0, 16, 0, 16),
        ZIndex           = 2,
        Parent           = frame,
    })
    local boxStroke = Stroke(box, enabled and C.Fg or C.LineMid, 1)

    local checkMark = Inst("TextLabel", {
        Text           = "✓",
        FontFace       = F.Bold,
        TextSize       = 10,
        TextColor3     = C.Bg,
        BackgroundTransparency = 1,
        Size           = UDim2.new(1, 0, 1, 0),
        Visible        = enabled,
        ZIndex         = 3,
        Parent         = box,
    })

    local function SetVisual(state)
        Tween(box, {BackgroundColor3 = state and C.Fg or C.Bg}, ANIM.Fast)
        boxStroke.Color  = state and C.Fg or C.LineMid
        checkMark.Visible = state
    end

    -- Hover feedback on box border
    rowBtn.MouseEnter:Connect(function()
        if not enabled then boxStroke.Color = C.Fg2 end
    end)
    rowBtn.MouseLeave:Connect(function()
        if not enabled then boxStroke.Color = C.LineMid end
    end)

    rowBtn.MouseButton1Click:Connect(function()
        enabled = not enabled; SetVisual(enabled); pcall(callback, enabled)
    end)

    local methods = {
        SetValue = function(_, v) enabled = v; SetVisual(enabled); pcall(callback, enabled) end,
        GetValue = function()    return enabled end,
    }
    tab._lib:_RegConfig(flag,
        function() return enabled end,
        function(v) methods:SetValue(v) end)
    return methods
end

-- ══════════════════════════════════════════════════════════════════════
-- COMPONENT: KEYBIND  (monospace tag + optional linked toggle dot)
-- ══════════════════════════════════════════════════════════════════════
--[[
    config = {
        Name, Default = KeyCode,
        Callback = function(keyCode),
        Toggle   = toggleMethods reference  (optional — dot reflects toggle state),
        Flag
    }
]]
function Library._Keybind(tab, config)
    local name         = config.Name     or "Keybind"
    local default      = config.Default  or Enum.KeyCode.F
    local callback     = config.Callback or function() end
    local linkedToggle = config.Toggle
    local flag         = config.Flag
    local currentKey   = default
    local listening    = false

    -- When a toggle is linked, the keybind flips it + fires the callback
    local function Fire()
        if linkedToggle then
            local newVal = not linkedToggle:GetValue()
            linkedToggle:SetValue(newVal)
        end
        pcall(callback, currentKey)
    end

    local frame = Inst("Frame", {
        Name             = "Keybind_" .. name,
        BackgroundColor3 = C.Surface,
        BorderSizePixel  = 0,
        Size             = UDim2.new(1, 0, 0, 38),
        Parent           = tab.content,
    })
    Stroke(frame, C.Line, 1)

    local rowBtn = Inst("TextButton", {
        Text = "", BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0), Parent = frame,
    })
    rowBtn.MouseEnter:Connect(function() Tween(frame, {BackgroundColor3 = C.Surface2}, ANIM.Fast) end)
    rowBtn.MouseLeave:Connect(function() Tween(frame, {BackgroundColor3 = C.Surface}, ANIM.Fast) end)

    -- Status dot (only when a toggle is linked — reflects toggle state)
    local statusDot = nil
    local nameXOffset = 14

    if linkedToggle then
        statusDot = Inst("Frame", {
            BackgroundColor3 = linkedToggle:GetValue() and C.Fg or C.Fg3,
            BorderSizePixel  = 0,
            AnchorPoint      = Vector2.new(0, 0.5),
            Position         = UDim2.new(0, 14, 0.5, 0),
            Size             = UDim2.new(0, 6, 0, 6),
            ZIndex           = 2,
            Parent           = frame,
        })
        nameXOffset = 26

        -- Intercept toggle's SetValue to keep dot in sync
        local origSet = linkedToggle.SetValue
        linkedToggle.SetValue = function(self_, v)
            origSet(self_, v)
            if statusDot then
                statusDot.BackgroundColor3 = v and C.Fg or C.Fg3
            end
        end
    end

    -- Name label
    Inst("TextLabel", {
        Text           = name,
        FontFace       = F.Medium,
        TextSize       = TS.Normal,
        TextColor3     = C.Fg,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        Position       = UDim2.new(0, nameXOffset, 0, 0),
        Size           = UDim2.new(1, -(nameXOffset + 88), 1, 0),
        ZIndex         = 2,
        Parent         = frame,
    })

    -- Key tag (monospace, right side)
    local keyBg = Inst("Frame", {
        BackgroundColor3 = C.Bg,
        BorderSizePixel  = 0,
        AnchorPoint      = Vector2.new(1, 0.5),
        Position         = UDim2.new(1, -14, 0.5, 0),
        Size             = UDim2.new(0, 72, 0, 22),
        ZIndex           = 2,
        Parent           = frame,
    })
    Stroke(keyBg, C.LineMid, 1)

    local keyLbl = Inst("TextLabel", {
        Text           = currentKey.Name,
        FontFace       = F.Mono,
        TextSize       = TS.Tiny,
        TextColor3     = C.Fg2,
        TextTruncate   = Enum.TextTruncate.AtEnd,
        BackgroundTransparency = 1,
        Size           = UDim2.new(1, 0, 1, 0),
        ZIndex         = 3,
        Parent         = keyBg,
    })

    local kbBtn = Inst("TextButton", {
        Text = "", BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0), ZIndex = 4, Parent = keyBg,
    })

    -- Register keybind in library table
    local kbId = name .. "_" .. tostring(tick())
    tab._lib._keybinds[kbId] = {key = currentKey, callback = Fire}

    local function UpdateDisplay()
        if listening then
            keyLbl.Text       = "..."
            keyLbl.TextColor3 = C.Fg
        else
            keyLbl.Text       = currentKey.Name
            keyLbl.TextColor3 = C.Fg2
        end
    end

    kbBtn.MouseButton1Click:Connect(function()
        listening = true; UpdateDisplay()
    end)

    local conn
    conn = UserInputService.InputBegan:Connect(function(inp, gp)
        if gp or not listening then return end
        local modifiers = {
            [Enum.KeyCode.LeftShift]   = true, [Enum.KeyCode.RightShift]   = true,
            [Enum.KeyCode.LeftControl] = true, [Enum.KeyCode.RightControl] = true,
            [Enum.KeyCode.LeftAlt]     = true, [Enum.KeyCode.RightAlt]     = true,
            [Enum.KeyCode.LeftMeta]    = true, [Enum.KeyCode.RightMeta]    = true,
        }
        if inp.UserInputType == Enum.UserInputType.Keyboard
        and not modifiers[inp.KeyCode] then
            currentKey = inp.KeyCode
            listening  = false
            tab._lib._keybinds[kbId].key = currentKey
            UpdateDisplay()
        end
    end)
    tab._lib._connections["kbconn_" .. kbId] = conn

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

-- ══════════════════════════════════════════════════════════════════════
-- COMPONENT: COLOR PICKER  (compact HSV — floats in ScreenGui)
-- ══════════════════════════════════════════════════════════════════════
--[[
    config = { Name, Default = Color3, Callback, Flag }
]]
function Library._ColorPicker(tab, config)
    local name     = config.Name     or "Color"
    local default  = config.Default  or Color3.fromRGB(255, 255, 255)
    local callback = config.Callback or function() end
    local flag     = config.Flag
    local h, s, v  = default:ToHSV()
    local current  = default
    local expanded = false

    -- ── Collapsed row ─────────────────────────────────────────────────
    local row = Inst("Frame", {
        Name             = "ColorPicker_" .. name,
        BackgroundColor3 = C.Surface,
        BorderSizePixel  = 0,
        Size             = UDim2.new(1, 0, 0, 38),
        Parent           = tab.content,
    })
    Stroke(row, C.Line, 1)

    local rowBtn = Inst("TextButton", {
        Text = "", BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0), Parent = row,
    })
    rowBtn.MouseEnter:Connect(function() Tween(row, {BackgroundColor3 = C.Surface2}, ANIM.Fast) end)
    rowBtn.MouseLeave:Connect(function() Tween(row, {BackgroundColor3 = C.Surface}, ANIM.Fast) end)

    Inst("TextLabel", {
        Text           = name,
        FontFace       = F.Medium,
        TextSize       = TS.Normal,
        TextColor3     = C.Fg,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        Position       = UDim2.new(0, 14, 0, 0),
        Size           = UDim2.new(1, -70, 1, 0),
        ZIndex         = 2,
        Parent         = row,
    })

    -- Colour preview swatch
    local preview = Inst("Frame", {
        BackgroundColor3 = current,
        BorderSizePixel  = 0,
        AnchorPoint      = Vector2.new(1, 0.5),
        Position         = UDim2.new(1, -14, 0.5, 0),
        Size             = UDim2.new(0, 48, 0, 18),
        ZIndex           = 2,
        Parent           = row,
    })
    Stroke(preview, C.LineMid, 1)

    -- ── Floating picker (parented to ScreenGui to avoid clipping) ─────
    local picker = Inst("Frame", {
        BackgroundColor3 = C.Surface,
        BorderSizePixel  = 0,
        Size             = UDim2.new(0, 176, 0, 126),
        Visible          = false,
        ZIndex           = 3000,
        Parent           = tab._lib.Gui,
    })
    Stroke(picker, C.LineMid, 1)

    -- SV gradient area
    local svArea = Inst("Frame", {
        BackgroundColor3 = Color3.fromHSV(h, 1, 1),
        BorderSizePixel  = 0,
        Position         = UDim2.new(0, 8, 0, 8),
        Size             = UDim2.new(1, -16, 0, 92),
        ZIndex           = 3001,
        Parent           = picker,
    })
    -- White overlay (left→right, 0→transparent)
    local wLayer = Inst("Frame", {BackgroundColor3 = Color3.new(1,1,1),
        Size = UDim2.new(1,0,1,0), ZIndex = 3002, Parent = svArea})
    Inst("UIGradient", {
        Color = ColorSequence.new(Color3.new(1,1,1)),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(1, 1),
        }),
        Parent = wLayer,
    })
    -- Black overlay (top→bottom, transparent→0)
    local bLayer = Inst("Frame", {BackgroundColor3 = Color3.new(0,0,0),
        Size = UDim2.new(1,0,1,0), ZIndex = 3003, Parent = svArea})
    Inst("UIGradient", {
        Rotation = 90,
        Color = ColorSequence.new(Color3.new(0,0,0)),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(1, 0),
        }),
        Parent = bLayer,
    })
    -- SV cursor (square)
    local svCursor = Inst("Frame", {
        BackgroundTransparency = 1,
        BorderSizePixel  = 0,
        AnchorPoint      = Vector2.new(0.5, 0.5),
        Position         = UDim2.new(s, 0, 1 - v, 0),
        Size             = UDim2.new(0, 8, 0, 8),
        ZIndex           = 3005,
        Parent           = svArea,
    })
    Stroke(svCursor, Color3.new(1,1,1), 2)

    -- Hue slider
    local hueBar = Inst("Frame", {
        BorderSizePixel  = 0,
        Position         = UDim2.new(0, 8, 0, 106),
        Size             = UDim2.new(1, -16, 0, 8),
        ZIndex           = 3001,
        Parent           = picker,
    })
    Inst("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0,     Color3.fromHSV(0,     1, 1)),
            ColorSequenceKeypoint.new(0.167, Color3.fromHSV(0.167, 1, 1)),
            ColorSequenceKeypoint.new(0.333, Color3.fromHSV(0.333, 1, 1)),
            ColorSequenceKeypoint.new(0.5,   Color3.fromHSV(0.5,   1, 1)),
            ColorSequenceKeypoint.new(0.667, Color3.fromHSV(0.667, 1, 1)),
            ColorSequenceKeypoint.new(0.833, Color3.fromHSV(0.833, 1, 1)),
            ColorSequenceKeypoint.new(1,     Color3.fromHSV(1,     1, 1)),
        }),
        Parent = hueBar,
    })
    local hueCursor = Inst("Frame", {
        BackgroundColor3 = Color3.new(1,1,1),
        BorderSizePixel  = 0,
        AnchorPoint      = Vector2.new(0.5, 0.5),
        Position         = UDim2.new(h, 0, 0.5, 0),
        Size             = UDim2.new(0, 8, 0, 12),
        ZIndex           = 3005,
        Parent           = hueBar,
    })
    Stroke(hueCursor, C.Bg, 1)

    -- Update all visuals from current h,s,v
    local function UpdateColor()
        current = Color3.fromHSV(h, s, v)
        preview.BackgroundColor3 = current
        svArea.BackgroundColor3  = Color3.fromHSV(h, 1, 1)
        svCursor.Position  = UDim2.new(s, 0, 1 - v, 0)
        hueCursor.Position = UDim2.new(h, 0, 0.5, 0)
        pcall(callback, current)
    end

    -- Drag logic
    local svDrag, hueDrag = false, false
    local function ProcessInput(inp)
        if not picker.Visible then return end
        if svDrag then
            local p  = svArea.AbsolutePosition
            local sz = svArea.AbsoluteSize
            s = math.clamp((inp.Position.X - p.X) / sz.X, 0, 1)
            v = 1 - math.clamp((inp.Position.Y - p.Y) / sz.Y, 0, 1)
            UpdateColor()
        elseif hueDrag then
            local p  = hueBar.AbsolutePosition
            local sz = hueBar.AbsoluteSize
            h = math.clamp((inp.Position.X - p.X) / sz.X, 0, 1)
            UpdateColor()
        end
    end

    svArea.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            svDrag = true; ProcessInput(inp); Library._activeDragger = ProcessInput
        end
    end)
    hueBar.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            hueDrag = true; ProcessInput(inp); Library._activeDragger = ProcessInput
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            svDrag = false; hueDrag = false; Library._activeDragger = nil
        end
    end)

    -- Position picker near the swatch, staying within viewport
    local function OpenPicker()
        if Library._activePicker then Library._activePicker() end
        Library._activePicker = ClosePicker

        local vp = game.Workspace.CurrentCamera.ViewportSize
        local bp = preview.AbsolutePosition
        local tx = bp.X - 186
        local ty = bp.Y

        if ty + 130 > vp.Y  then ty = vp.Y - 134 end
        if ty < 0            then ty = 4 end
        if tx < 0            then tx = bp.X + 58 end

        picker.Position = UDim2.new(0, tx, 0, ty)
        picker.Visible  = true
        expanded         = true
    end

    function ClosePicker()
        picker.Visible = false
        expanded        = false
        if Library._activePicker == ClosePicker then Library._activePicker = nil end
    end

    rowBtn.MouseButton1Click:Connect(function()
        if expanded then ClosePicker() else OpenPicker() end
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

-- ══════════════════════════════════════════════════════════════════════
-- COMPONENT: PROGRESS BAR  (read-only animated fill)
-- ══════════════════════════════════════════════════════════════════════
--[[
    config = { Name, Min, Max, Default, Suffix }
]]
function Library._ProgressBar(tab, config)
    local name    = config.Name    or "Progress"
    local min     = config.Min     or 0
    local max     = config.Max     or 100
    local default = config.Default or 0
    local suffix  = config.Suffix  or ""
    local current = math.clamp(default, min, max)

    local frame = Inst("Frame", {
        Name             = "ProgressBar_" .. name,
        BackgroundColor3 = C.Surface,
        BorderSizePixel  = 0,
        Size             = UDim2.new(1, 0, 0, 52),
        Parent           = tab.content,
    })
    Stroke(frame, C.Line, 1)

    Inst("TextLabel", {
        Text           = name,
        FontFace       = F.Medium,
        TextSize       = TS.Normal,
        TextColor3     = C.Fg,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        Position       = UDim2.new(0, 14, 0, 8),
        Size           = UDim2.new(0.65, -14, 0, 18),
        Parent         = frame,
    })

    local valLbl = Inst("TextLabel", {
        Text           = tostring(current) .. suffix,
        FontFace       = F.Mono,
        TextSize       = TS.Small,
        TextColor3     = C.Fg3,
        TextXAlignment = Enum.TextXAlignment.Right,
        BackgroundTransparency = 1,
        AnchorPoint    = Vector2.new(1, 0),
        Position       = UDim2.new(1, -14, 0, 8),
        Size           = UDim2.new(0, 80, 0, 18),
        Parent         = frame,
    })

    local track = Inst("Frame", {
        BackgroundColor3 = C.Line,
        BorderSizePixel  = 0,
        Position         = UDim2.new(0, 14, 0, 36),
        Size             = UDim2.new(1, -28, 0, 3),
        Parent           = frame,
    })

    local ratio = (max - min) > 0 and (current - min) / (max - min) or 0
    local fill  = Inst("Frame", {
        BackgroundColor3 = C.Fg,
        BorderSizePixel  = 0,
        Size             = UDim2.new(ratio, 0, 1, 0),
        Parent           = track,
    })

    local function Refresh(val)
        current = math.clamp(val, min, max)
        local r = (max - min) > 0 and (current - min) / (max - min) or 0
        Tween(fill, {Size = UDim2.new(r, 0, 1, 0)}, ANIM.Normal)
        valLbl.Text = tostring(current) .. suffix
    end

    return {
        SetValue = function(_, v) Refresh(v) end,
        GetValue = function()    return current end,
        SetMax   = function(_, v) max = v; Refresh(current) end,
        SetMin   = function(_, v) min = v; Refresh(current) end,
    }
end

-- ══════════════════════════════════════════════════════════════════════
-- COMPONENT: TABLE  (editorial, alternating rows)
-- ══════════════════════════════════════════════════════════════════════
--[[
    config = {
        Name, Columns = {"Col1","Col2",...},
        RowHeight = 30, MaxVisible = 6
    }
    methods: AddRow(data), RemoveRow(idx), ClearRows(), SetData(rows), GetData()
]]
function Library._Table(tab, config)
    local name       = config.Name       or "Table"
    local columns    = config.Columns    or {"Name", "Value"}
    local rowH       = config.RowHeight  or 30
    local maxVisible = config.MaxVisible or 6
    local colN       = #columns
    local data       = {}

    -- Outer container (auto-sizes vertically)
    local frame = Inst("Frame", {
        Name             = "Table_" .. name,
        BackgroundColor3 = C.Surface,
        BorderSizePixel  = 0,
        AutomaticSize    = Enum.AutomaticSize.Y,
        Size             = UDim2.new(1, 0, 0, 0),
        Parent           = tab.content,
    })
    Stroke(frame, C.Line, 1)

    -- Title bar
    local titleBar = Inst("Frame", {
        BackgroundColor3 = C.Surface2,
        BorderSizePixel  = 0,
        Size             = UDim2.new(1, 0, 0, 28),
        Parent           = frame,
    })
    Inst("TextLabel", {
        Text           = string.upper(name),
        FontFace       = F.Bold,
        TextSize       = TS.Tiny,
        TextColor3     = C.Fg3,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        Position       = UDim2.new(0, 14, 0, 0),
        Size           = UDim2.new(1, -28, 1, 0),
        Parent         = titleBar,
    })
    HDivider(frame, 28)

    -- Column headers
    local headerRow = Inst("Frame", {
        BackgroundColor3 = C.Surface2,
        BorderSizePixel  = 0,
        Position         = UDim2.new(0, 0, 0, 29),
        Size             = UDim2.new(1, 0, 0, 26),
        Parent           = frame,
    })
    for i, col in ipairs(columns) do
        Inst("TextLabel", {
            Text           = string.upper(col),
            FontFace       = F.Bold,
            TextSize       = TS.Tiny,
            TextColor3     = C.Fg3,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate   = Enum.TextTruncate.AtEnd,
            BackgroundTransparency = 1,
            Position       = UDim2.new((i-1)/colN, i==1 and 14 or 6, 0, 0),
            Size           = UDim2.new(1/colN, -(i==1 and 14 or 6), 1, 0),
            Parent         = headerRow,
        })
    end
    HDivider(headerRow, 25)

    -- Scrollable body
    local body = Inst("ScrollingFrame", {
        BackgroundTransparency = 1,
        BorderSizePixel  = 0,
        Position         = UDim2.new(0, 0, 0, 55),
        Size             = UDim2.new(1, 0, 0, 0),   -- adjusted below
        CanvasSize       = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = C.LineMid,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        Parent           = frame,
    })
    List(body, 0)

    local function RefreshLayout()
        local vis = math.min(#data, maxVisible)
        body.Size       = UDim2.new(1, 0, 0, vis * rowH)
        body.CanvasSize = UDim2.new(0, 0, 0, #data * rowH)
    end

    local rowFrames = {}

    local function MakeRow(idx, rowData)
        local r = Inst("Frame", {
            BackgroundColor3 = idx%2==0 and C.Surface2 or C.Surface,
            BorderSizePixel  = 0,
            LayoutOrder      = idx,
            Size             = UDim2.new(1, 0, 0, rowH),
            Parent           = body,
        })
        HDivider(r, rowH - 1)
        for i = 1, colN do
            Inst("TextLabel", {
                Text           = tostring(rowData[i] or ""),
                FontFace       = F.Regular,
                TextSize       = TS.Small,
                TextColor3     = C.Fg,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate   = Enum.TextTruncate.AtEnd,
                BackgroundTransparency = 1,
                Position       = UDim2.new((i-1)/colN, i==1 and 14 or 6, 0, 0),
                Size           = UDim2.new(1/colN, -(i==1 and 14 or 6), 1, 0),
                Parent         = r,
            })
        end
        return r
    end

    local function FullRender()
        for _, r in ipairs(rowFrames) do pcall(function() r:Destroy() end) end
        rowFrames = {}
        for i, d in ipairs(data) do
            table.insert(rowFrames, MakeRow(i, d))
        end
        RefreshLayout()
    end

    RefreshLayout()

    return {
        AddRow = function(_, rowData)
            table.insert(data, rowData)
            table.insert(rowFrames, MakeRow(#data, rowData))
            RefreshLayout()
        end,
        RemoveRow = function(_, idx)
            if data[idx] then
                table.remove(data, idx)
                FullRender()
            end
        end,
        ClearRows = function(_) data = {}; FullRender() end,
        SetData   = function(_, d) data = d; FullRender() end,
        GetData   = function()    return data end,
        SetName   = function(_, t)
            -- Update title label if accessible
        end,
    }
end

-- ══════════════════════════════════════════════════════════════════════
-- COMPONENT: BADGE  (outlined, uppercase, read-only display)
-- ══════════════════════════════════════════════════════════════════════
--[[
    config = {
        Text,
        Style = "active" | "inactive" | "neutral" | "danger"
    }
]]
function Library._Badge(tab, config)
    local text  = config.Text  or "Badge"
    local style = config.Style or "neutral"

    local styleColors = {
        active   = C.Fg,
        inactive = C.Fg3,
        neutral  = C.Fg2,
        danger   = C.Danger,
    }
    local col = styleColors[style] or styleColors.neutral

    local badge = Inst("TextLabel", {
        Name           = "Badge_" .. text,
        Text           = string.upper(text),
        FontFace       = F.Bold,
        TextSize       = TS.Tiny,
        TextColor3     = col,
        BackgroundTransparency = 1,
        AutomaticSize  = Enum.AutomaticSize.X,
        Size           = UDim2.new(0, 0, 0, 22),
        Parent         = tab.content,
    })
    Pad(badge, 0, 0, 10, 10)
    Stroke(badge, col, 1)

    local function SetStyle(st)
        local nc = styleColors[st] or styleColors.neutral
        badge.TextColor3 = nc
        for _, ch in ipairs(badge:GetChildren()) do
            if ch:IsA("UIStroke") then ch.Color = nc end
        end
    end

    return {
        SetText  = function(_, t) badge.Text = string.upper(t) end,
        SetStyle = SetStyle,
        GetText  = function()     return badge.Text end,
    }
end

-- ══════════════════════════════════════════════════════════════════════
-- COMPONENT: RADIO GROUP  (square dot buttons)
-- ══════════════════════════════════════════════════════════════════════
--[[
    config = { Name, Options = {}, Default, Callback, Flag }
]]
function Library._RadioGroup(tab, config)
    local name     = config.Name     or "Radio"
    local options  = config.Options  or {"Option 1", "Option 2"}
    local default  = config.Default  or options[1]
    local callback = config.Callback or function() end
    local flag     = config.Flag
    local selected = default

    local frame = Inst("Frame", {
        Name             = "RadioGroup_" .. name,
        BackgroundColor3 = C.Surface,
        BorderSizePixel  = 0,
        AutomaticSize    = Enum.AutomaticSize.Y,
        Size             = UDim2.new(1, 0, 0, 0),
        Parent           = tab.content,
    })
    Stroke(frame, C.Line, 1)
    Pad(frame, 10, 10, 14, 14)
    List(frame, 6)

    -- Group header label
    Inst("TextLabel", {
        Text           = string.upper(name),
        FontFace       = F.Bold,
        TextSize       = TS.Tiny,
        TextColor3     = C.Fg3,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        LayoutOrder    = 0,
        Size           = UDim2.new(1, 0, 0, 18),
        Parent         = frame,
    })

    local optData = {}

    local function UpdateAll()
        for _, d in pairs(optData) do
            local sel = d.value == selected
            Tween(d.box,    {BackgroundColor3 = sel and C.Fg or C.Bg}, ANIM.Fast)
            d.boxStroke.Color = sel and C.Fg or C.LineMid
            d.dot.Visible     = sel
            d.lbl.TextColor3  = sel and C.Fg or C.Fg2
            d.lbl.FontFace    = sel and F.SemiBold or F.Regular
        end
    end

    for i, opt in ipairs(options) do
        local row = Inst("Frame", {
            BackgroundTransparency = 1,
            LayoutOrder            = i,
            Size                   = UDim2.new(1, 0, 0, 28),
            Parent                 = frame,
        })

        -- Square indicator
        local box = Inst("Frame", {
            BackgroundColor3 = opt == selected and C.Fg or C.Bg,
            BorderSizePixel  = 0,
            AnchorPoint      = Vector2.new(0, 0.5),
            Position         = UDim2.new(0, 0, 0.5, 0),
            Size             = UDim2.new(0, 14, 0, 14),
            ZIndex           = 2,
            Parent           = row,
        })
        local bStroke = Stroke(box, opt == selected and C.Fg or C.LineMid, 1)

        -- Inner dot (filled square)
        local dot = Inst("Frame", {
            BackgroundColor3 = C.Bg,
            BorderSizePixel  = 0,
            AnchorPoint      = Vector2.new(0.5, 0.5),
            Position         = UDim2.new(0.5, 0, 0.5, 0),
            Size             = UDim2.new(0, 6, 0, 6),
            Visible          = (opt == selected),
            ZIndex           = 3,
            Parent           = box,
        })

        -- Option label
        local lbl = Inst("TextLabel", {
            Text           = opt,
            FontFace       = opt == selected and F.SemiBold or F.Regular,
            TextSize       = TS.Normal,
            TextColor3     = opt == selected and C.Fg or C.Fg2,
            TextXAlignment = Enum.TextXAlignment.Left,
            BackgroundTransparency = 1,
            Position       = UDim2.new(0, 24, 0, 0),
            Size           = UDim2.new(1, -24, 1, 0),
            ZIndex         = 2,
            Parent         = row,
        })

        local btn = Inst("TextButton", {
            Text = "", BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0), ZIndex = 3, Parent = row,
        })

        optData[opt] = {value = opt, box = box, boxStroke = bStroke, dot = dot, lbl = lbl}

        btn.MouseButton1Click:Connect(function()
            selected = opt; UpdateAll(); pcall(callback, selected)
        end)
        btn.MouseEnter:Connect(function()
            if selected ~= opt then lbl.TextColor3 = C.Fg end
        end)
        btn.MouseLeave:Connect(function()
            if selected ~= opt then lbl.TextColor3 = C.Fg2 end
        end)
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

-- ══════════════════════════════════════════════════════════════════════
-- COMPONENT: CONFIG SECTION  (pre-built save/load/delete UI)
-- ══════════════════════════════════════════════════════════════════════
function Library._ConfigSection(tab)
    local lib = tab._lib

    Library._SectionHeader(tab, "Configuration")

    -- Config name input
    local nameBox = Library._TextBox(tab, {
        Name        = "Config Name",
        Default     = "default",
        Placeholder = "Enter name...",
        Callback    = function(t)
            if t and t ~= "" then lib._currentConfig = t end
        end,
    })

    -- Existing configs dropdown
    local cfgDropdown
    cfgDropdown = Library._Dropdown(tab, {
        Name     = "Saved Configs",
        Options  = lib:GetConfigs(),
        Default  = "",
        Callback = function(sel)
            if sel and sel ~= "" then
                nameBox:SetText(sel)
                lib._currentConfig = sel
            end
        end,
    })

    -- Save
    Library._Button(tab, {
        Name  = "Save Config",
        Style = "primary",
        Callback = function()
            local n = nameBox:GetText()
            if n ~= "" then
                lib:SaveConfig(n)
                cfgDropdown:Refresh(lib:GetConfigs())
            end
        end,
    })

    -- Load
    Library._Button(tab, {
        Name  = "Load Config",
        Style = "ghost",
        Callback = function()
            local n = nameBox:GetText()
            if n ~= "" then lib:LoadConfig(n) end
        end,
    })

    -- Delete
    Library._Button(tab, {
        Name  = "Delete Config",
        Style = "danger",
        Callback = function()
            local n = nameBox:GetText()
            if n ~= "" then
                lib:DeleteConfig(n)
                cfgDropdown:Refresh(lib:GetConfigs())
            end
        end,
    })

    -- Refresh list
    Library._Button(tab, {
        Name  = "Refresh List",
        Style = "ghost",
        Callback = function()
            cfgDropdown:Refresh(lib:GetConfigs())
            lib:Notify({Title = "List Refreshed", Description = "Config list updated"})
        end,
    })

    -- Auto Save toggle
    Library._Toggle(tab, {
        Name     = "Auto Save (30s)",
        Default  = false,
        Callback = function(v) lib:SetAutoSave(v) end,
    })

    return {
        RefreshConfigs = function() cfgDropdown:Refresh(lib:GetConfigs()) end,
    }
end

-- ══════════════════════════════════════════════════════════════════════
return Library
