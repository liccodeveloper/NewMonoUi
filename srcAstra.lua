local ts  = game:GetService("TweenService")
local ui  = game:GetService("UserInputService")
local plr = game:GetService("Players")
local hs  = game:GetService("HttpService")

local n = "Astra"

local c = {
    Background = Color3.fromRGB(0,   0,   0  ),
    Secondary  = Color3.fromRGB(13,  13,  13 ),
    Border     = Color3.fromRGB(31,  31,  31 ),
    BorderMid  = Color3.fromRGB(46,  46,  46 ),
    Text       = Color3.fromRGB(255, 255, 255),
    TextDark   = Color3.fromRGB(136, 136, 136),
    TextFade   = Color3.fromRGB(0,   0,   0  ),
    Accent     = Color3.fromRGB(255, 255, 255),
    Toggle = {
        Enabled  = Color3.fromRGB(255, 255, 255),
        Disabled = Color3.fromRGB(20,  20,  20 ),
        Circle   = Color3.fromRGB(13,  13,  13 ),
    },
    Checkbox = {
        Enabled  = Color3.fromRGB(255, 255, 255),
        Disabled = Color3.fromRGB(13,  13,  13 ),
        Border   = Color3.fromRGB(46,  46,  46 ),
        Check    = Color3.fromRGB(0,   0,   0  ),
    },
    Notification = {
        Background = Color3.fromRGB(13,  13,  13 ),
        Border     = Color3.fromRGB(31,  31,  31 ),
        Timer      = Color3.fromRGB(255, 255, 255),
    },
}

local s = {
    Window     = {Width = 690, Height = 446},
    MinWindow  = {Width = 500, Height = 300},
    MaxWindow  = {Width = 1200, Height = 800},
    Toggle     = {Width = 38,  Height = 21, Circle = 13},
    Button     = {Height = 39},
    Slider     = {Height = 46},
    Dropdown   = {Height = 39, OptionHeight = 30},
    Tab        = {Width = 135, Height = 35},
    ColorPicker= {Width = 180, Height = 160},
    Notification={Width = 220, Height = 70},
    TextBox    = {Height = 39, InputWidth = 150},
}

local f = {
    Regular = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold),
    Bold    = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold),
}

local textsize = {
    Title  = 14,
    Normal = 14,
    Small  = 13,
    Tiny   = 11,
}

local animspeed = {
    Fast     = 0.1,
    Normal   = 0.15,
    Slow     = 0.2,
    VerySlow = 0.3,
}

local Library = {}
Library.__index = Library

Library._activeDragger  = nil
Library._activeDropdown = nil
Library._activePicker   = nil

ui.InputChanged:Connect(function(input)
    if Library._activeDragger
    and (input.UserInputType == Enum.UserInputType.MouseMovement
      or input.UserInputType == Enum.UserInputType.Touch) then
        Library._activeDragger(input)
    end
end)

local function Tween(instance, properties, duration, style, direction)
    ts:Create(instance, TweenInfo.new(
        duration  or animspeed.Normal,
        style     or Enum.EasingStyle.Quad,
        direction or Enum.EasingDirection.Out
    ), properties):Play()
end

local function New(class, props)
    local obj = Instance.new(class)
    for k, v in pairs(props) do
        if k ~= "Parent" then
            pcall(function() obj[k] = v end)
        end
    end
    if props.Parent then obj.Parent = props.Parent end
    return obj
end

local function Stroke(parent, color, transparency)
    return New("UIStroke", {
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Color           = color or c.Border,
        Transparency    = transparency or 0,
        Thickness       = 1,
        Parent          = parent,
    })
end

local function Padding(parent, top, bottom, left, right)
    return New("UIPadding", {
        PaddingTop    = UDim.new(0, top    or 0),
        PaddingBottom = UDim.new(0, bottom or 0),
        PaddingLeft   = UDim.new(0, left   or 0),
        PaddingRight  = UDim.new(0, right  or 0),
        Parent        = parent,
    })
end

local function Layout(parent, padding, sortOrder, direction)
    return New("UIListLayout", {
        Padding       = UDim.new(0, padding or 0),
        SortOrder     = sortOrder  or Enum.SortOrder.LayoutOrder,
        FillDirection = direction  or Enum.FillDirection.Vertical,
        Parent        = parent,
    })
end

local function IsMobile()
    return ui.TouchEnabled and not ui.KeyboardEnabled
end

local function MakeDraggable(frame, handle)
    local dragging, dragStart, startPos = false, nil, nil
    handle = handle or frame
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

local function EnsureConfigFolder()
    if isfolder and not isfolder("AstraConfigs") then
        pcall(makefolder, "AstraConfigs")
    end
end

local function GetAvailableConfigs()
    local configs = {}
    if not (isfolder and listfiles) then return configs end
    EnsureConfigFolder()
    local ok, files = pcall(listfiles, "AstraConfigs")
    if not ok then return configs end
    for _, file in ipairs(files) do
        local name = file:match("AstraConfigs/(.+)%.json$")
                  or file:match("AstraConfigs\\(.+)%.json$")
        if name then table.insert(configs, name) end
    end
    return configs
end

local function CreateNotificationContainer(screenGui)
    local container = New("Frame", {
        Name                  = "NotificationContainer",
        BackgroundTransparency = 1,
        Position              = UDim2.new(1, -240, 0, 20),
        Size                  = UDim2.new(0, 220, 1, -40),
        Parent                = screenGui,
    })
    Layout(container, 10, Enum.SortOrder.LayoutOrder, Enum.FillDirection.Vertical)
    return container
end

function Library.new(title, configFolder, sizeConfig, options)
    local self = setmetatable({}, Library)
    self.title        = title        or "Astra"
    self.configFolder = configFolder or title or "Astra"

    local sc  = sizeConfig or {}
    local def = sc.Default or {}
    local mn  = sc.Min     or {}
    local mx  = sc.Max     or {}

    self._defaultSize  = Vector2.new(def.Width or s.Window.Width,    def.Height or s.Window.Height)
    self._minSize      = Vector2.new(mn.Width  or s.MinWindow.Width,  mn.Height  or s.MinWindow.Height)
    self._maxSize      = Vector2.new(mx.Width  or s.MaxWindow.Width,  mx.Height  or s.MaxWindow.Height)
    self.sections      = {}
    self.currentTab    = nil
    self.minimized     = false
    self._keybinds     = {}
    self._toggleKey    = Enum.KeyCode.RightControl
    self._visible      = true
    self._originalHeight = self._defaultSize.Y
    self._mobileToggle = nil
    self._configElements = {}
    self._autoSave     = false
    self._currentConfig = "default"
    self._connections  = {}

    local opts = options or {}
    if opts.AccentColor then
        c.Accent            = opts.AccentColor
        c.Toggle.Enabled    = opts.AccentColor
        c.Checkbox.Enabled  = opts.AccentColor
        c.Checkbox.Border   = opts.AccentColor
    end
    self._watermarkText = opts.Watermark or nil

    self:_CreateMainWindow()
    self:_SetupKeybindListener()
    self:_SetupMobileSupport()
    self._notifContainer = CreateNotificationContainer(self.screenGui)
    if self._watermarkText then self:_CreateWatermark(self._watermarkText) end
    return self
end

function Library:SetAccentColor(color)
    c.Accent           = color
    c.Toggle.Enabled   = color
    c.Checkbox.Enabled = color
    c.Checkbox.Border  = color
end

function Library:SetWatermark(text)
    self._watermarkText = text
    if self._watermarkLabel then self._watermarkLabel.Text = text
    else self:_CreateWatermark(text) end
end

function Library:_CreateWatermark(text)
    self._watermarkLabel = New("TextLabel", {
        Name                  = "Watermark",
        FontFace              = f.Regular,
        TextColor3            = Color3.fromRGB(40, 40, 40),
        Text                  = text,
        TextXAlignment        = Enum.TextXAlignment.Right,
        BackgroundTransparency = 1,
        TextSize              = 11,
        AnchorPoint           = Vector2.new(1, 1),
        Position              = UDim2.new(1, -8, 1, -6),
        Size                  = UDim2.new(0, 300, 0, 16),
        ZIndex                = 10,
        Parent                = self.screenGui,
    })
end

function Library:Notify(config)
    local title    = config.Title       or "Notification"
    local desc     = config.Description or ""
    local duration = config.Duration    or 3
    local icon     = config.Icon        or "rbxassetid://10709775704"

    local notification = New("Frame", {
        Name             = "Notification",
        BackgroundColor3 = c.Notification.Background,
        Position         = UDim2.new(1, 20, 0, 0),
        Size             = UDim2.new(1, 0, 0, s.Notification.Height),
        ClipsDescendants = true,
        Parent           = self._notifContainer,
    })
    Stroke(notification, c.Notification.Border, 0)
    New("TextLabel", {
        FontFace              = f.Regular,
        TextColor3            = c.Text,
        Text                  = title,
        TextXAlignment        = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        Position              = UDim2.new(0, 14, 0, 16),
        TextSize              = textsize.Normal,
        Size                  = UDim2.new(1, -60, 0, 19),
        Parent                = notification,
    })
    New("TextLabel", {
        FontFace              = f.Regular,
        TextColor3            = c.TextDark,
        Text                  = desc,
        TextXAlignment        = Enum.TextXAlignment.Left,
        TextTruncate          = Enum.TextTruncate.AtEnd,
        BackgroundTransparency = 1,
        Position              = UDim2.new(0, 14, 0, 38),
        TextSize              = textsize.Normal,
        Size                  = UDim2.new(1, -60, 0, 19),
        Parent                = notification,
    })
    New("ImageLabel", {
        BackgroundTransparency = 1,
        Image                 = icon,
        Position              = UDim2.new(1, -33, 0, 23),
        Size                  = UDim2.new(0, 19, 0, 19),
        Parent                = notification,
    })
    local timerBar = New("Frame", {
        BackgroundColor3 = c.Notification.Timer,
        BorderSizePixel  = 0,
        Position         = UDim2.new(0, 0, 1, -2),
        Size             = UDim2.new(1, 0, 0, 2),
        Parent           = notification,
    })
    Tween(notification, {Position = UDim2.new(0, 0, 0, 0)}, 0.28,
          Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    Tween(timerBar, {Size = UDim2.new(0, 0, 0, 2)}, duration, Enum.EasingStyle.Linear)
    task.delay(duration, function()
        Tween(notification, {Position = UDim2.new(1, 20, 0, 0)}, 0.22,
              Enum.EasingStyle.Quart, Enum.EasingDirection.In)
        task.wait(0.25)
        pcall(function() notification:Destroy() end)
    end)
    return notification
end

function Library:_SetupKeybindListener()
    self._connections["keybind_listener"] = ui.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == self._toggleKey then self:Toggle() end
        for _, kb in pairs(self._keybinds) do
            if input.KeyCode == kb.key then pcall(kb.callback) end
        end
    end)
end

function Library:Toggle()
    self._visible = not self._visible
    self.container.Visible = self._visible
    if self._mobileToggle then
        self._mobileToggle.Visible = not self._visible
    end
end

function Library:SetToggleKey(keyCode)
    self._toggleKey = keyCode
end

function Library:_SetupMobileSupport()
    local btn = New("ImageButton", {
        Name                 = "MobileToggle",
        Image                = "rbxassetid://112235310154264",
        ImageColor3          = c.Text,
        BackgroundColor3     = c.Background,
        BackgroundTransparency = 0.1,
        Position             = UDim2.new(0, 15, 0.5, -25),
        Size                 = UDim2.new(0, 50, 0, 50),
        AnchorPoint          = Vector2.new(0, 0.5),
        Visible              = false,
        ZIndex               = 999,
        Parent               = self.screenGui,
    })
    Stroke(btn)

    local dragging, dragStart, startPos = false, nil, nil
    btn.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.Touch
        and input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        dragging  = true
        dragStart = input.Position
        startPos  = btn.Position
        Library._activeDragger = function(inp)
            if not dragging then return end
            local d = inp.Position - dragStart
            btn.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
    btn.InputEnded:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.Touch
        and input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        if dragging and (input.Position - dragStart).Magnitude < 10 then
            self:Toggle()
        end
        dragging = false
        Library._activeDragger = nil
    end)

    self._mobileToggle = btn
    if IsMobile() then btn.Visible = not self._visible end
end

function Library:_CreateMainWindow()
    self.screenGui = New("ScreenGui", {
        Name           = n,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn   = false,
    })

    self.container = New("Frame", {
        Name             = "Container",
        BackgroundColor3 = c.Background,
        Position         = UDim2.new(0.5, -self._defaultSize.X/2, 0.5, -self._defaultSize.Y/2),
        BorderSizePixel  = 0,
        Size             = UDim2.new(0, self._defaultSize.X, 0, self._defaultSize.Y),
        ClipsDescendants = false,
        Parent           = self.screenGui,
    })
    Stroke(self.container)

    self.topBar = New("Frame", {
        Name                  = "TopBar",
        BackgroundTransparency = 1,
        Size                  = UDim2.new(1, 0, 0, 45),
        Parent                = self.container,
    })

    New("TextLabel", {
        Name                  = "Title",
        FontFace              = f.Regular,
        TextColor3            = c.Text,
        Text                  = self.title,
        BackgroundTransparency = 1,
        Position              = UDim2.new(0, 10, 0, 10),
        TextXAlignment        = Enum.TextXAlignment.Left,
        TextSize              = textsize.Title,
        Size                  = UDim2.new(0, 150, 0, 25),
        Parent                = self.topBar,
    })

    self:_CreateWindowControls()

    New("Frame", {
        Name             = "Header",
        BackgroundColor3 = c.Border,
        Position         = UDim2.new(0, 0, 0, 45),
        BorderSizePixel  = 0,
        Size             = UDim2.new(1, 0, 0, 1),
        Parent           = self.container,
    })

    self:_CreateContentArea()
    MakeDraggable(self.container, self.topBar)

    self.screenGui.Parent = plr.LocalPlayer:WaitForChild("PlayerGui")
end

function Library:_CreateWindowControls()
    local minimizeBtn = New("ImageLabel", {
        Name                  = "Minimize",
        ImageColor3           = c.TextDark,
        Image                 = "rbxassetid://82603981310445",
        BackgroundTransparency = 1,
        AnchorPoint           = Vector2.new(1, 0),
        Position              = UDim2.new(1, -35, 0, 15),
        Size                  = UDim2.new(0, 15, 0, 15),
        Parent                = self.topBar,
    })
    local minimizeClick = New("TextButton", {
        Text                  = "",
        Rotation              = 0.01,
        BackgroundTransparency = 1,
        Size                  = UDim2.new(0, 21, 0, 15),
        Parent                = minimizeBtn,
    })
    minimizeClick.MouseButton1Click:Connect(function() self:_ToggleMinimize() end)
    minimizeBtn.MouseEnter:Connect(function() minimizeBtn.ImageColor3 = c.Text end)
    minimizeBtn.MouseLeave:Connect(function() minimizeBtn.ImageColor3 = c.TextDark end)

    local closeBtn = New("ImageButton", {
        Name                  = "Close",
        ImageColor3           = c.TextDark,
        Image                 = "rbxassetid://119943770201674",
        BackgroundTransparency = 1,
        AnchorPoint           = Vector2.new(1, 0),
        Position              = UDim2.new(1, -10, 0, 15),
        Size                  = UDim2.new(0, 15, 0, 15),
        Parent                = self.topBar,
    })
    closeBtn.MouseButton1Click:Connect(function() self:Destroy() end)
    closeBtn.MouseEnter:Connect(function() closeBtn.ImageColor3 = Color3.fromRGB(255, 59, 59) end)
    closeBtn.MouseLeave:Connect(function() closeBtn.ImageColor3 = c.TextDark end)

    -- Resize handle em L invertido (canto inferior direito):
    -- linha horizontal na base + linha vertical na direita
    local resizeWrap = New("Frame", {
        Name                   = "ResizeHandle",
        BackgroundTransparency = 1,
        AnchorPoint            = Vector2.new(1, 1),
        Position               = UDim2.new(1, -2, 1, -2),
        Size                   = UDim2.new(0, 10, 0, 10),
        BorderSizePixel        = 0,
        ZIndex                 = 8,
        Parent                 = self.container,
    })
    -- linha horizontal (base do L)
    New("Frame", {
        BackgroundColor3 = c.TextDark,
        BorderSizePixel  = 0,
        AnchorPoint      = Vector2.new(0, 1),
        Position         = UDim2.new(0, 0, 1, 0),
        Size             = UDim2.new(1, 0, 0, 1),
        ZIndex           = 9,
        Parent           = resizeWrap,
    })
    -- linha vertical (lateral direita do L)
    New("Frame", {
        BackgroundColor3 = c.TextDark,
        BorderSizePixel  = 0,
        AnchorPoint      = Vector2.new(1, 0),
        Position         = UDim2.new(1, 0, 0, 0),
        Size             = UDim2.new(0, 1, 1, 0),
        ZIndex           = 9,
        Parent           = resizeWrap,
    })
    local resizeClickArea = New("TextButton", {
        Text="", BackgroundTransparency=1,
        AnchorPoint = Vector2.new(1, 1),
        Position    = UDim2.new(1, 4, 1, 4),
        Size        = UDim2.new(0, 18, 0, 18),
        ZIndex      = 10,
        Parent      = self.container,
    })
    self.resizeBtn = resizeWrap
    self:_SetupSmartResize(resizeClickArea, resizeWrap)
end

function Library:_CreateContentArea()
    self.mainContent = New("Frame", {
        Name                  = "MainContent",
        BackgroundTransparency = 1,
        Position              = UDim2.new(0, 0, 0, 46),
        Size                  = UDim2.new(1, 0, 1, -46),
        ClipsDescendants      = true,
        Parent                = self.container,
    })

    self.sectionsContainer = New("ScrollingFrame", {
        Name                 = "SectionsContainer",
        ScrollBarThickness   = 0,
        BackgroundTransparency = 1,
        Position             = UDim2.new(0, 0, 0, 0),
        Size                 = UDim2.new(0, 165, 1, 0),
        CanvasSize           = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize  = Enum.AutomaticSize.Y,
        ScrollingDirection   = Enum.ScrollingDirection.Y,
        Parent               = self.mainContent,
    })
    Layout(self.sectionsContainer, 0, Enum.SortOrder.LayoutOrder)
    Padding(self.sectionsContainer, 5, 5, 5, 5)

    New("Frame", {
        Name             = "Separator",
        BackgroundColor3 = c.Border,
        Position         = UDim2.new(0, 165, 0, 0),
        BorderSizePixel  = 0,
        Size             = UDim2.new(0, 1, 1, 0),
        Parent           = self.mainContent,
    })

    self.contentContainer = New("ScrollingFrame", {
        Name                  = "ContentContainer",
        ScrollBarThickness    = 0,
        BackgroundTransparency = 1,
        Position              = UDim2.new(0, 166, 0, 0),
        Size                  = UDim2.new(1, -166, 1, 0),
        CanvasSize            = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize   = Enum.AutomaticSize.Y,
        ScrollingDirection    = Enum.ScrollingDirection.Y,
        Parent                = self.mainContent,
    })
    Layout(self.contentContainer, 8, Enum.SortOrder.LayoutOrder)
    Padding(self.contentContainer, 10, 10, 15, 15)
end

function Library:_SetupSmartResize(handle, visual)
    local resizing, resizeStart, startSize = false, nil, nil
    local function setColor(col)
        if not visual then return end
        for _, ch in ipairs(visual:GetChildren()) do
            if ch:IsA("Frame") then ch.BackgroundColor3 = col end
        end
    end
    handle.MouseEnter:Connect(function() setColor(c.Text) end)
    handle.MouseLeave:Connect(function() if not resizing then setColor(c.TextDark) end end)
    handle.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
        and input.UserInputType ~= Enum.UserInputType.Touch then return end
        resizing    = true
        resizeStart = input.Position
        startSize   = self.container.AbsoluteSize
        self._originalHeight = startSize.Y
        Library._activeDragger = function(inp)
            if not resizing then return end
            local d  = inp.Position - resizeStart
            local nw = math.clamp(startSize.X + d.X, self._minSize.X, self._maxSize.X)
            local nh = math.clamp(startSize.Y + d.Y, self._minSize.Y, self._maxSize.Y)
            self.container.Size  = UDim2.new(0, nw, 0, nh)
            self._originalHeight = nh
        end
        local conn
        conn = input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                resizing = false
                Library._activeDragger = nil
                setColor(c.TextDark)
                conn:Disconnect()
            end
        end)
    end)
end


function Library:_ToggleMinimize()
    self.minimized = not self.minimized
    if self.minimized then
        self.mainContent.Size  = UDim2.new(1, 0, 0, 0)
        self.container.Size    = UDim2.new(0, self.container.AbsoluteSize.X, 0, 45)
        if self.resizeBtn then self.resizeBtn.Visible = false end
    else
        self.container.Size    = UDim2.new(0, self.container.AbsoluteSize.X, 0, self._originalHeight)
        self.mainContent.Size  = UDim2.new(1, 0, 1, -46)
        if self.resizeBtn then self.resizeBtn.Visible = true end
    end
end

function Library:Destroy()
    if self._autoSave then pcall(function() self:SaveConfig(self._currentConfig) end) end
    for _, conn in pairs(self._connections) do
        if typeof(conn) == "RBXScriptConnection" then pcall(function() conn:Disconnect() end) end
    end
    self._connections = {}
    if self.screenGui then self.screenGui:Destroy() end
end

function Library:_RegisterConfigElement(id, elementType, getValue, setValue)
    self._configElements[id] = {type = elementType, getValue = getValue, setValue = setValue}
end

function Library:SaveConfig(configName)
    if not writefile then
        self:Notify({Title="Error", Description="Config system not supported", Duration=3})
        return false
    end
    EnsureConfigFolder()
    local data = {}
    for id, el in pairs(self._configElements) do
        local ok, val = pcall(el.getValue)
        if ok and val ~= nil then
            if typeof(val) == "Color3" then
                val = {R=val.R, G=val.G, B=val.B, _type="Color3"}
            elseif typeof(val) == "EnumItem" then
                val = {_type="EnumItem", _enum=tostring(val.EnumType), _value=val.Name}
            end
            data[id] = val
        end
    end
    local ok2 = pcall(writefile, "AstraConfigs/"..configName..".json", hs:JSONEncode(data))
    if ok2 then
        self._currentConfig = configName
        self:Notify({Title="Config Saved", Description="Saved as: "..configName, Duration=2, Icon="rbxassetid://10723356507"})
        return true
    end
    self:Notify({Title="Error", Description="Failed to save config", Duration=3})
    return false
end

function Library:LoadConfig(configName)
    if not (readfile and isfile) then
        self:Notify({Title="Error", Description="Config system not supported", Duration=3})
        return false
    end
    local path = "AstraConfigs/"..configName..".json"
    if not isfile(path) then
        self:Notify({Title="Error", Description="Config not found: "..configName, Duration=3})
        return false
    end
    local ok, data = pcall(function() return hs:JSONDecode(readfile(path)) end)
    if not ok or not data then
        self:Notify({Title="Error", Description="Failed to load config", Duration=3})
        return false
    end
    for id, value in pairs(data) do
        if self._configElements[id] then
            if type(value)=="table" and value._type=="Color3" then
                value = Color3.new(value.R, value.G, value.B)
            elseif type(value)=="table" and value._type=="EnumItem" then
                value = Enum[value._enum][value._value]
            end
            pcall(function() self._configElements[id].setValue(value) end)
        end
    end
    self._currentConfig = configName
    self:Notify({Title="Config Loaded", Description="Loaded: "..configName, Duration=2, Icon="rbxassetid://10723356507"})
    return true
end

function Library:DeleteConfig(configName)
    if not (delfile and isfile) then return false end
    local path = "AstraConfigs/"..configName..".json"
    if isfile(path) then
        delfile(path)
        self:Notify({Title="Config Deleted", Description="Deleted: "..configName, Duration=2})
        return true
    end
    return false
end

function Library:GetConfigs() return GetAvailableConfigs() end

function Library:SetAutoSave(enabled)
    self._autoSave = enabled
    if enabled then
        task.spawn(function()
            while self._autoSave and self.screenGui and self.screenGui.Parent do
                task.wait(30)
                if self._autoSave then pcall(function() self:SaveConfig(self._currentConfig) end) end
            end
        end)
    end
end

function Library:CreateSection(name)
    local section = {name=name, tabs={}, expanded=true, _library=self}

    local sectionFrame = New("Frame", {
        Name              = "Section_"..name,
        BackgroundTransparency = 1,
        Size              = UDim2.new(1, -10, 0, 0),
        AutomaticSize     = Enum.AutomaticSize.Y,
        Parent            = self.sectionsContainer,
    })
    Layout(sectionFrame, 2, Enum.SortOrder.LayoutOrder)

    local headerContainer = New("Frame", {
        Name              = "HeaderContainer",
        BackgroundTransparency = 1,
        Size              = UDim2.new(1, 0, 0, 25),
        LayoutOrder       = 0,
        Parent            = sectionFrame,
    })
    local headerBtn = New("TextButton", {
        FontFace          = f.Regular,
        TextColor3        = c.TextDark,
        Text              = "",
        BackgroundTransparency = 1,
        BorderSizePixel   = 0,
        Size              = UDim2.new(1, 0, 1, 0),
        Parent            = headerContainer,
    })
    New("TextLabel", {
        FontFace          = f.Bold,
        TextColor3        = c.TextDark,
        Text              = string.upper(name),
        TextXAlignment    = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        Position          = UDim2.new(0, 5, 0, 0),
        TextSize          = textsize.Tiny,
        Size              = UDim2.new(1, -25, 1, 0),
        Parent            = headerContainer,
    })
    local arrow = New("ImageButton", {
        Image             = "rbxassetid://105558791071013",
        ImageColor3       = c.TextDark,
        BackgroundTransparency = 1,
        Position          = UDim2.new(1, -20, 0.5, -7),
        Size              = UDim2.new(0, 15, 0, 15),
        Rotation          = 0,
        Parent            = headerContainer,
    })

    local tabsContainer = New("Frame", {
        Name              = "TabsContainer",
        BackgroundTransparency = 1,
        Size              = UDim2.new(1, 0, 0, 0),
        AutomaticSize     = Enum.AutomaticSize.Y,
        ClipsDescendants  = true,
        LayoutOrder       = 1,
        Parent            = sectionFrame,
    })
    Layout(tabsContainer, 2, Enum.SortOrder.LayoutOrder)
    Padding(tabsContainer, 0, 0, 5, 0)

    local function ToggleSection()
        section.expanded  = not section.expanded
        arrow.Rotation    = section.expanded and 0 or 180
        tabsContainer.Visible = section.expanded
    end
    headerBtn.MouseButton1Click:Connect(ToggleSection)
    arrow.MouseButton1Click:Connect(ToggleSection)

    section.frame         = sectionFrame
    section.tabsContainer = tabsContainer
    table.insert(self.sections, section)

    local sectionMethods = setmetatable({}, {__index = section})
    function sectionMethods:CreateTab(tabName, icon)
        return Library._CreateTab(self, tabName, icon)
    end
    return sectionMethods
end

function Library._CreateTab(section, name, icon)
    local tab = {name=name, elements={}}

    local tabBtn = New("Frame", {
        Name             = name,
        BackgroundColor3 = c.Secondary,
        BackgroundTransparency = 1,
        BorderSizePixel  = 0,
        Size             = UDim2.new(0, s.Tab.Width, 0, s.Tab.Height),
        Parent           = section.tabsContainer,
    })
    local tabStroke = Stroke(tabBtn, c.Border, 1)

    -- Barra vertical branca no canto esquerdo (visivel apenas quando ativa)
    local accentBar = New("Frame", {
        BackgroundColor3       = c.Text,
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        Size                   = UDim2.new(0, 2, 1, 0),
        ZIndex                 = 2,
        Parent                 = tabBtn,
    })

    local iconLabel = New("ImageLabel", {
        BackgroundTransparency = 1,
        Image            = icon or "rbxassetid://112235310154264",
        ImageColor3      = c.TextDark,
        AnchorPoint      = Vector2.new(0, 0.5),
        Position         = UDim2.new(0, 11, 0.5, 0),
        Size             = UDim2.new(0, 15, 0, 15),
        Parent           = tabBtn,
    })

    local tabText = New("TextLabel", {
        FontFace         = f.Regular,
        TextColor3       = c.TextDark,
        Text             = name,
        TextXAlignment   = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        Position         = UDim2.new(0, 33, 0, 0),
        Size             = UDim2.new(1, -42, 1, 0),
        TextSize         = textsize.Small,
        Parent           = tabBtn,
    })
    Padding(tabText, 0, 0, 0, 9)

    local textGradient = New("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0,    c.TextDark),
            ColorSequenceKeypoint.new(0.65, c.TextDark),
            ColorSequenceKeypoint.new(1,    c.TextFade),
        }),
        Parent = tabText,
    })

    local clickBtn = New("TextButton", {
        Text             = "",
        BackgroundTransparency = 1,
        Size             = UDim2.new(1, 0, 1, 0),
        Parent           = tabBtn,
    })

    tab.content = New("Frame", {
        Name             = name.."_Content",
        BackgroundTransparency = 1,
        Size             = UDim2.new(1, 0, 0, 0),
        AutomaticSize    = Enum.AutomaticSize.Y,
        Visible          = false,
        Parent           = section._library.contentContainer,
    })
    Layout(tab.content, 8, Enum.SortOrder.LayoutOrder)

    clickBtn.MouseButton1Click:Connect(function()
        Library._SelectTab(section._library, tab, tabBtn, tabStroke, iconLabel, tabText, textGradient)
    end)
    clickBtn.MouseEnter:Connect(function()
        if section._library.currentTab ~= tab then tabBtn.BackgroundTransparency = 0.7 end
    end)
    clickBtn.MouseLeave:Connect(function()
        if section._library.currentTab ~= tab then tabBtn.BackgroundTransparency = 1 end
    end)

    tab.button       = tabBtn
    tab.stroke       = tabStroke
    tab.accentBar    = accentBar
    tab.icon         = iconLabel
    tab.textLabel    = tabText
    tab.textGradient = textGradient
    tab._library     = section._library
    table.insert(section.tabs, tab)

    if not section._library.currentTab then
        Library._SelectTab(section._library, tab, tabBtn, tabStroke, iconLabel, tabText, textGradient)
    end

    local tabMethods = setmetatable({}, {__index = tab})
    function tabMethods:CreateSection(sectionName) return Library._CreateContentSection(self, sectionName) end
    function tabMethods:CreateLabel(config)         return Library._CreateLabel(self, config) end
    function tabMethods:CreateSeparator(config)     return Library._CreateSeparator(self, config) end
    function tabMethods:CreateParagraph(config)     return Library._CreateParagraph(self, config) end
    function tabMethods:CreateSlider(config)        return Library._CreateSlider(self, config) end
    function tabMethods:CreateButton(config)        return Library._CreateButton(self, config) end
    function tabMethods:CreateToggle(config)        return Library._CreateToggle(self, config) end
    function tabMethods:CreateCheckbox(config)      return Library._CreateCheckbox(self, config) end
    function tabMethods:CreateRadioGroup(config)    return Library._CreateRadioGroup(self, config) end
    function tabMethods:CreateDropdown(config)      return Library._CreateDropdown(self, config) end
    function tabMethods:CreateKeybind(config)       return Library._CreateKeybind(self, config, section._library) end
    function tabMethods:CreateColorPicker(config)   return Library._CreateColorPicker(self, config) end
    function tabMethods:CreateTextBox(config)       return Library._CreateTextBox(self, config) end
    function tabMethods:CreateConfigSection()       return Library._CreateConfigSection(self) end
    function tabMethods:CreateProgressBar(config)   return Library._CreateProgressBar(self, config) end
    function tabMethods:CreateTable(config)         return Library._CreateTable(self, config) end
    return tabMethods
end

function Library._SelectTab(lib, tab, btn, stroke, icon, textLabel, textGradient)
    if lib.currentTab then
        local p = lib.currentTab
        p.content.Visible                = false
        p.button.BackgroundTransparency  = 1
        p.icon.ImageColor3               = c.TextDark
        p.stroke.Transparency            = 1
        if p.accentBar then p.accentBar.BackgroundTransparency = 1 end
        if p.textGradient then p.textGradient.Enabled = true end
    end
    lib.currentTab             = tab
    tab.content.Visible        = true
    btn.BackgroundTransparency = 0.85
    btn.BackgroundColor3       = c.Secondary
    icon.ImageColor3           = c.Text
    if tab.accentBar then tab.accentBar.BackgroundTransparency = 0 end
    if textGradient then textGradient.Enabled = false end
    textLabel.TextColor3       = c.Text
end

function Library._CreateContentSection(tab, name)
    local wrap = New("Frame", {
        Name             = "Section_"..name,
        BackgroundColor3 = c.Background,
        BorderSizePixel  = 0,
        Size             = UDim2.new(1, 0, 0, 30),
        Parent           = tab.content,
    })
    New("TextLabel", {
        FontFace         = f.Bold,
        TextColor3       = c.TextDark,
        Text             = string.upper(name),
        TextXAlignment   = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        AnchorPoint      = Vector2.new(0, 1),
        Position         = UDim2.new(0, 0, 1, -6),
        Size             = UDim2.new(1, 0, 0, 12),
        TextSize         = textsize.Tiny,
        Parent           = wrap,
    })
    New("Frame", {
        BackgroundColor3 = c.Border,
        BorderSizePixel  = 0,
        AnchorPoint      = Vector2.new(0, 1),
        Position         = UDim2.new(0, 0, 1, 0),
        Size             = UDim2.new(1, 0, 0, 1),
        Parent           = wrap,
    })
    return wrap
end

function Library._CreateLabel(tab, config)
    local lbl = New("TextLabel", {
        FontFace         = f.Regular,
        TextColor3       = config.TextColor or c.TextDark,
        Text             = config.Text or "Label",
        TextXAlignment   = Enum.TextXAlignment.Left,
        TextWrapped      = true,
        BackgroundTransparency = 1,
        TextSize         = config.TextSize or textsize.Normal,
        Size             = UDim2.new(1, 0, 0, 0),
        AutomaticSize    = Enum.AutomaticSize.Y,
        Parent           = tab.content,
    })
    return {
        SetText  = function(_, t) lbl.Text = t end,
        SetColor = function(_, co) lbl.TextColor3 = co end,
        GetText  = function() return lbl.Text end,
    }
end

function Library._CreateSeparator(tab, config)
    local text = config and config.Text or nil
    local container = New("Frame", {
        BackgroundTransparency = 1,
        Size             = UDim2.new(1, 0, 0, text and 20 or 10),
        Parent           = tab.content,
    })
    if text and text ~= "" then
        local ll = New("Frame", {BackgroundColor3=c.Border, AnchorPoint=Vector2.new(0,0.5),
            Position=UDim2.new(0,0,0.5,0), BorderSizePixel=0, Size=UDim2.new(0,0,0,1), Parent=container})
        local lbl = New("TextLabel", {FontFace=f.Regular, TextColor3=c.TextDark, Text=text,
            BackgroundTransparency=1, TextSize=textsize.Tiny, AnchorPoint=Vector2.new(0.5,0.5),
            Position=UDim2.new(0.5,0,0.5,0), Size=UDim2.new(0,0,1,0), AutomaticSize=Enum.AutomaticSize.X,
            Parent=container})
        local rl = New("Frame", {BackgroundColor3=c.Border, AnchorPoint=Vector2.new(1,0.5),
            Position=UDim2.new(1,0,0.5,0), BorderSizePixel=0, Size=UDim2.new(0,0,0,1), Parent=container})
        task.defer(function()
            local lw = lbl.AbsoluteSize.X
            local tw = container.AbsoluteSize.X
            local ew = math.max(0, math.floor((tw-lw-12)/2))
            ll.Size = UDim2.new(0,ew,0,1); rl.Size = UDim2.new(0,ew,0,1)
        end)
    else
        New("Frame", {BackgroundColor3=c.Border, AnchorPoint=Vector2.new(0,0.5),
            Position=UDim2.new(0,0,0.5,0), BorderSizePixel=0, Size=UDim2.new(1,0,0,1), Parent=container})
    end
    return container
end

function Library._CreateParagraph(tab, config)
    local frame = New("Frame", {
        BackgroundColor3 = c.Secondary,
        BackgroundTransparency = 0.4,
        BorderSizePixel  = 0,
        Size             = UDim2.new(1, 0, 0, 0),
        AutomaticSize    = Enum.AutomaticSize.Y,
        Parent           = tab.content,
    })
    Stroke(frame)
    Padding(frame, 10, 10, 10, 10)
    local titleLbl = New("TextLabel", {
        FontFace=f.Regular, TextColor3=c.Text, Text=config.Title or "Paragraph",
        TextXAlignment=Enum.TextXAlignment.Left, BackgroundTransparency=1,
        TextSize=textsize.Normal, Size=UDim2.new(1,0,0,20), Parent=frame,
    })
    local contLbl = New("TextLabel", {
        FontFace=f.Regular, TextColor3=c.TextDark, Text=config.Content or "",
        TextXAlignment=Enum.TextXAlignment.Left, TextWrapped=true, BackgroundTransparency=1,
        TextSize=textsize.Small, Position=UDim2.new(0,0,0,22),
        Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y, Parent=frame,
    })
    return {
        SetTitle   = function(_, t) titleLbl.Text = t end,
        SetContent = function(_, t) contLbl.Text  = t end,
    }
end

function Library._CreateSlider(tab, config)
    local name     = config.Name     or "Slider"
    local min      = config.Min      or 0
    local max      = config.Max      or 100
    local default  = config.Default  or 50
    local step     = config.Step     or 1
    local suffix   = config.Suffix   or ""
    local callback = config.Callback or function() end
    local flag     = config.Flag

    local decimals = 0
    if step < 1 then
        local dot = tostring(step):find("%.")
        if dot then decimals = #tostring(step) - dot end
    end
    local function Round(v)
        local sn = math.floor((v-min)/step+0.5)*step+min
        sn = math.clamp(sn,min,max)
        if decimals > 0 then local m=10^decimals; return math.floor(sn*m+0.5)/m end
        return math.floor(sn+0.5)
    end
    local function Fmt(v)
        if decimals > 0 then return string.format("%."..decimals.."f",v)..suffix end
        return tostring(math.floor(v))..suffix
    end

    local cur = Round(default)
    local frame = New("Frame", {
        Name=name, BackgroundColor3=c.Secondary, BackgroundTransparency=0.4,
        BorderSizePixel=0, Size=UDim2.new(1,0,0,s.Slider.Height), Parent=tab.content,
    })
    Stroke(frame)
    New("TextLabel", {FontFace=f.Regular, TextColor3=c.Text, Text=name,
        TextXAlignment=Enum.TextXAlignment.Left, BackgroundTransparency=1,
        Position=UDim2.new(0,10,0,5), TextSize=textsize.Normal, Size=UDim2.new(0,200,0,20), Parent=frame})
    local valLbl = New("TextLabel", {FontFace=f.Regular, TextColor3=c.Text, Text=Fmt(cur),
        TextXAlignment=Enum.TextXAlignment.Right, BackgroundTransparency=1,
        Position=UDim2.new(1,-70,0,5), TextSize=textsize.Normal, Size=UDim2.new(0,60,0,20), Parent=frame})
    local trackBg = New("Frame", {BackgroundColor3=c.Toggle.Disabled,
        Position=UDim2.new(0,10,0,29), BorderSizePixel=0, Size=UDim2.new(1,-20,0,7), Parent=frame})
    local sliderFill = New("Frame", {BackgroundColor3=c.Accent, BorderSizePixel=0,
        Size=UDim2.new((cur-min)/math.max(max-min,0.001),0,1,0), Parent=trackBg})

    local function UpdateSlider(input)
        local rel = math.clamp((input.Position.X-trackBg.AbsolutePosition.X)/trackBg.AbsoluteSize.X,0,1)
        cur = Round(min+(max-min)*rel)
        local pct = (cur-min)/math.max(max-min,0.001)
        sliderFill.Size = UDim2.new(pct,0,1,0)
        valLbl.Text = Fmt(cur)
        callback(cur)
    end
    trackBg.InputBegan:Connect(function(input)
        if input.UserInputType~=Enum.UserInputType.MouseButton1 and input.UserInputType~=Enum.UserInputType.Touch then return end
        UpdateSlider(input)
        Library._activeDragger = function(inp) UpdateSlider(inp) end
    end)
    trackBg.InputEnded:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
            Library._activeDragger = nil
        end
    end)

    local methods = {
        SetValue = function(_, v)
            cur = Round(math.clamp(v,min,max))
            sliderFill.Size = UDim2.new((cur-min)/math.max(max-min,0.001),0,1,0)
            valLbl.Text = Fmt(cur); callback(cur)
        end,
        GetValue = function() return cur end,
    }
    if flag and tab._library then
        tab._library:_RegisterConfigElement(flag, "Slider",
            function() return cur end, function(v) methods:SetValue(v) end)
    end
    return methods
end


-- ══════════════════════════════════════════════════════════════════════
-- FLOATING SHORTCUT BUTTON
-- Criado automaticamente quando Shortcut = true em qualquer elemento.
-- Só aparece em dispositivos mobile (TouchEnabled e sem teclado).
-- Arrastável, tem X para fechar, executa a mesma callback do elemento.
-- ══════════════════════════════════════════════════════════════════════
function Library:_CreateFloatingShortcut(name, callback)
    if not IsMobile() then return end

    local screenGui = self.screenGui

    -- Posição inicial: canto inferior direito, um pouco acima do centro
    local startX = 0.75
    local startY = 0.72

    local wrapper = New("Frame", {
        Name                   = "Shortcut_" .. name,
        BackgroundColor3       = c.Background,
        BackgroundTransparency = 0.25,
        BorderSizePixel        = 0,
        AnchorPoint            = Vector2.new(0.5, 0.5),
        Position               = UDim2.new(startX, 0, startY, 0),
        Size                   = UDim2.new(0, 110, 0, 36),
        ZIndex                 = 8000,
        Parent                 = screenGui,
    })
    Stroke(wrapper, c.Border, 1)

    -- Nome da ação
    New("TextLabel", {
        Text                  = string.upper(name),
        FontFace              = f.Bold,
        TextSize              = textsize.Tiny,
        TextColor3            = c.Text,
        BackgroundTransparency = 1,
        AnchorPoint           = Vector2.new(0, 0.5),
        Position              = UDim2.new(0, 10, 0.5, 0),
        Size                  = UDim2.new(1, -30, 0, 16),
        ZIndex                = 8001,
        Parent                = wrapper,
    })

    -- Botão X para fechar
    local closeBtn = New("TextButton", {
        Text                  = "×",
        FontFace              = f.Regular,
        TextSize              = 14,
        TextColor3            = c.TextDark,
        BackgroundTransparency = 1,
        AnchorPoint           = Vector2.new(1, 0.5),
        Position              = UDim2.new(1, -4, 0.5, 0),
        Size                  = UDim2.new(0, 20, 0, 20),
        ZIndex                = 8002,
        Parent                = wrapper,
    })
    closeBtn.MouseEnter:Connect(function() closeBtn.TextColor3 = c.Danger end)
    closeBtn.MouseLeave:Connect(function() closeBtn.TextColor3 = c.TextDark end)
    closeBtn.MouseButton1Click:Connect(function()
        wrapper:Destroy()
    end)

    -- Área de clique principal (executa callback)
    local hitBtn = New("TextButton", {
        Text                  = "",
        BackgroundTransparency = 1,
        Size                  = UDim2.new(1, -24, 1, 0),
        ZIndex                = 8002,
        Parent                = wrapper,
    })
    hitBtn.MouseButton1Click:Connect(function()
        Tween(wrapper, {BackgroundTransparency = 0.05}, animspeed.Fast)
        task.wait(0.12)
        Tween(wrapper, {BackgroundTransparency = 0.25}, animspeed.Fast)
        pcall(callback)
    end)

    -- Drag
    local dragging, ds, sp = false, nil, nil
    wrapper.InputBegan:Connect(function(inp)
        if inp.UserInputType ~= Enum.UserInputType.Touch
        and inp.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        dragging = true; ds = inp.Position; sp = wrapper.Position
        Library._activeDragger = function(i)
            if not dragging then return end
            local d = i.Position - ds
            wrapper.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
        end
        local conn; conn = inp.Changed:Connect(function()
            if inp.UserInputState == Enum.UserInputState.End then
                dragging = false; Library._activeDragger = nil; conn:Disconnect()
            end
        end)
    end)

    return wrapper
end

function Library._CreateButton(tab, config)
    local name     = config.Name     or "Button"
    local callback = config.Callback or function() end
    local shortcut = config.Shortcut or false
    local frame = New("Frame", {
        BackgroundColor3=c.Secondary, BackgroundTransparency=0.4,
        BorderSizePixel=0, Size=UDim2.new(1,0,0,s.Button.Height), Parent=tab.content,
    })
    Stroke(frame)
    local nameLbl = New("TextLabel", {FontFace=f.Regular, TextColor3=c.Text, Text=name,
        TextXAlignment=Enum.TextXAlignment.Left, BackgroundTransparency=1,
        Position=UDim2.new(0,10,0.5,-10), TextSize=textsize.Normal, Size=UDim2.new(0,200,0,20), Parent=frame})
    New("ImageLabel", {BackgroundTransparency=1, Image="rbxassetid://10734898355",
        ImageColor3=c.Text, Position=UDim2.new(1,-30,0.5,-10), Size=UDim2.new(0,20,0,20), Parent=frame})
    local btn = New("TextButton", {Text="", BackgroundTransparency=1, Size=UDim2.new(1,0,1,0), Parent=frame})
    btn.MouseButton1Click:Connect(function()
        frame.BackgroundTransparency = 0.2
        task.wait(0.1)
        frame.BackgroundTransparency = 0.4
        pcall(callback)
    end)
    if shortcut then
        tab._lib:_CreateFloatingShortcut(name, callback)
    end
    return {SetText = function(_, t) nameLbl.Text = t end}
end

function Library._CreateToggle(tab, config)
    local name     = config.Name     or "Toggle"
    local default  = config.Default  or false
    local callback = config.Callback or function() end
    local flag     = config.Flag
    local shortcut = config.Shortcut or false
    local enabled  = default

    local frame = New("Frame", {
        BackgroundColor3=c.Secondary, BackgroundTransparency=0.4,
        BorderSizePixel=0, Size=UDim2.new(1,0,0,s.Button.Height), Parent=tab.content,
    })
    Stroke(frame)
    New("TextLabel", {FontFace=f.Regular, TextColor3=c.Text, Text=name,
        TextXAlignment=Enum.TextXAlignment.Left, BackgroundTransparency=1,
        Position=UDim2.new(0,10,0.5,-10), TextSize=textsize.Normal, Size=UDim2.new(0,200,0,20), Parent=frame})
    local switchBg = New("Frame", {
        BackgroundColor3=enabled and c.Toggle.Enabled or c.Toggle.Disabled,
        Position=UDim2.new(1,-48,0.5,-10), BorderSizePixel=0,
        Size=UDim2.new(0,s.Toggle.Width,0,s.Toggle.Height), Parent=frame,
    })
    local switchStroke = Stroke(switchBg, enabled and c.Toggle.Enabled or c.BorderMid)
    local switchCircle = New("Frame", {
        BackgroundColor3=c.Toggle.Circle, AnchorPoint=Vector2.new(0,0.5),
        Position=enabled and UDim2.new(0,21,0.5,0) or UDim2.new(0,4,0.5,0),
        BorderSizePixel=0, Size=UDim2.new(0,s.Toggle.Circle,0,s.Toggle.Circle), Parent=switchBg,
    })
    local btn = New("TextButton", {Text="", BackgroundTransparency=1, Size=UDim2.new(1,0,1,0), Parent=frame})

    local function UpdateToggle()
        Tween(switchBg,     {BackgroundColor3 = enabled and c.Toggle.Enabled or c.Toggle.Disabled}, animspeed.Fast)
        Tween(switchCircle, {Position = enabled and UDim2.new(0,21,0.5,0) or UDim2.new(0,4,0.5,0)}, animspeed.Fast)
        switchStroke.Color = enabled and c.Toggle.Enabled or c.BorderMid
    end
    btn.MouseButton1Click:Connect(function()
        enabled = not enabled; UpdateToggle(); pcall(callback, enabled)
    end)

    local methods = {
        SetValue = function(_, v) enabled=v; UpdateToggle(); pcall(callback, enabled) end,
        GetValue = function()    return enabled end,
    }
    if flag and tab._library then
        tab._library:_RegisterConfigElement(flag, "Toggle",
            function() return enabled end, function(v) methods:SetValue(v) end)
    end
    if shortcut then
        -- Para toggle o shortcut alterna o estado ao ser clicado
        tab._lib:_CreateFloatingShortcut(name, function()
            enabled = not enabled; UpdateToggle(); pcall(callback, enabled)
        end)
    end
    return methods
end

function Library._CreateCheckbox(tab, config)
    local name     = config.Name     or "Checkbox"
    local default  = config.Default  or false
    local callback = config.Callback or function() end
    local flag     = config.Flag
    local enabled  = default

    local frame = New("Frame", {
        BackgroundColor3=c.Secondary, BackgroundTransparency=0.4,
        BorderSizePixel=0, Size=UDim2.new(1,0,0,s.Button.Height), Parent=tab.content,
    })
    Stroke(frame)
    New("TextLabel", {FontFace=f.Regular, TextColor3=c.Text, Text=name,
        TextXAlignment=Enum.TextXAlignment.Left, BackgroundTransparency=1,
        Position=UDim2.new(0,10,0.5,-10), TextSize=textsize.Normal, Size=UDim2.new(0,200,0,20), Parent=frame})

    local checkBg = New("Frame", {
        BackgroundColor3 = enabled and c.Checkbox.Enabled or c.Checkbox.Disabled,
        AnchorPoint      = Vector2.new(1, 0.5),
        Position         = UDim2.new(1, -10, 0.5, 0),
        BorderSizePixel  = 0,
        Size             = UDim2.new(0, 18, 0, 18),
        Parent           = frame,
    })
    local checkStroke = New("UIStroke", {
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Color     = enabled and c.Checkbox.Enabled or c.Checkbox.Border,
        Thickness = 1.5,
        Parent    = checkBg,
    })
    -- Quadrado branco centralizado como indicador (sem texto, limpo e alinhado)
    local checkMark = New("Frame", {
        BackgroundColor3 = c.Checkbox.Check,
        BorderSizePixel  = 0,
        AnchorPoint      = Vector2.new(0.5, 0.5),
        Position         = UDim2.new(0.5, 0, 0.5, 0),
        Size             = UDim2.new(0, 8, 0, 8),
        Visible          = enabled,
        ZIndex           = 2,
        Parent           = checkBg,
    })

    local btn = New("TextButton", {Text="", BackgroundTransparency=1, Size=UDim2.new(1,0,1,0), Parent=frame})

    local function UpdateCheckbox()
        Tween(checkBg, {BackgroundColor3 = enabled and c.Checkbox.Enabled or c.Checkbox.Disabled}, animspeed.Fast)
        checkStroke.Color  = enabled and c.Checkbox.Enabled or c.Checkbox.Border
        checkMark.Visible  = enabled
    end
    btn.MouseButton1Click:Connect(function()
        enabled = not enabled; UpdateCheckbox(); pcall(callback, enabled)
    end)
    btn.MouseEnter:Connect(function() if not enabled then checkStroke.Color = Color3.fromRGB(90,90,90) end end)
    btn.MouseLeave:Connect(function() if not enabled then checkStroke.Color = c.Checkbox.Border end end)

    local methods = {
        SetValue = function(_, v) enabled=v; UpdateCheckbox(); pcall(callback, enabled) end,
        GetValue = function()    return enabled end,
    }
    if flag and tab._library then
        tab._library:_RegisterConfigElement(flag, "Checkbox",
            function() return enabled end, function(v) methods:SetValue(v) end)
    end
    return methods
end

function Library._CreateRadioGroup(tab, config)
    local name     = config.Name     or "Radio Group"
    local options  = config.Options  or {"Option 1","Option 2","Option 3"}
    local default  = config.Default  or options[1]
    local callback = config.Callback or function() end
    local flag     = config.Flag
    local selected = default

    local frame = New("Frame", {
        BackgroundColor3=c.Secondary, BackgroundTransparency=0.4,
        BorderSizePixel=0, Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
        Parent=tab.content,
    })
    Stroke(frame)
    Padding(frame,8,8,10,10)
    Layout(frame,5,Enum.SortOrder.LayoutOrder)
    New("TextLabel", {FontFace=f.Regular, TextColor3=c.Text, Text=name,
        TextXAlignment=Enum.TextXAlignment.Left, BackgroundTransparency=1,
        LayoutOrder=0, TextSize=textsize.Normal, Size=UDim2.new(1,0,0,20), Parent=frame})

    local optionFrames = {}
    local function UpdateRadio()
        for _, d in pairs(optionFrames) do
            local sel = d.value == selected
            d.outerRing.BackgroundColor3 = sel and c.Accent or c.Secondary
            d.stroke.Color               = sel and c.Accent or c.Border
            d.innerDot.Visible           = sel
            d.label.TextColor3           = sel and c.Text or c.TextDark
        end
    end

    for i, option in ipairs(options) do
        local row = New("Frame", {BackgroundTransparency=1, Size=UDim2.new(1,0,0,28), LayoutOrder=i, Parent=frame})
        local outerRing = New("Frame", {
            BackgroundColor3=option==selected and c.Accent or c.Secondary,
            AnchorPoint=Vector2.new(0,0.5), Position=UDim2.new(0,0,0.5,0),
            BorderSizePixel=0, Size=UDim2.new(0,16,0,16), Parent=row,
        })
        local ringStroke = New("UIStroke", {ApplyStrokeMode=Enum.ApplyStrokeMode.Border,
            Color=option==selected and c.Accent or c.Border, Thickness=1.5, Parent=outerRing})
        local innerDot = New("Frame", {BackgroundColor3=c.Background,
            AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.new(0.5,0,0.5,0),
            BorderSizePixel=0, Size=UDim2.new(0,6,0,6), Visible=option==selected, Parent=outerRing})
        local optLabel = New("TextLabel", {FontFace=f.Regular,
            TextColor3=option==selected and c.Text or c.TextDark, Text=option,
            TextXAlignment=Enum.TextXAlignment.Left, BackgroundTransparency=1,
            Position=UDim2.new(0,26,0,0), TextSize=textsize.Small, Size=UDim2.new(1,-26,1,0), Parent=row})
        local clickBtn = New("TextButton", {Text="", BackgroundTransparency=1, Size=UDim2.new(1,0,1,0), Parent=row})
        optionFrames[option] = {value=option, outerRing=outerRing, stroke=ringStroke, innerDot=innerDot, label=optLabel}
        clickBtn.MouseButton1Click:Connect(function() selected=option; UpdateRadio(); pcall(callback,selected) end)
        clickBtn.MouseEnter:Connect(function() if selected~=option then optLabel.TextColor3=c.Text end end)
        clickBtn.MouseLeave:Connect(function() if selected~=option then optLabel.TextColor3=c.TextDark end end)
    end

    local methods = {
        SetValue = function(_, v) selected=v; UpdateRadio(); pcall(callback,selected) end,
        GetValue = function()    return selected end,
    }
    if flag and tab._library then
        tab._library:_RegisterConfigElement(flag,"RadioGroup",
            function() return selected end, function(v) methods:SetValue(v) end)
    end
    return methods
end

function Library._CreateDropdown(tab, config)
    local name        = config.Name        or "Dropdown"
    local options     = config.Options     or {"Option 1","Option 2","Option 3"}
    local default     = config.Default     or options[1]
    local multiSelect = config.MultiSelect or false
    local callback    = config.Callback    or function() end
    local flag        = config.Flag
    local lib         = tab._library

    local selected = multiSelect and {} or default
    if multiSelect and type(default)=="table" then selected = default
    elseif multiSelect then selected = {} end

    local expanded     = false
    local searchEnabled = config.SearchBox ~= false and #options > 5
    local searchHeight  = searchEnabled and 32 or 0
    local maxVisible    = 5
    local optH          = s.Dropdown.OptionHeight

    local frame = New("Frame", {
        BackgroundColor3=c.Secondary, BackgroundTransparency=0.4,
        BorderSizePixel=0, Size=UDim2.new(1,0,0,s.Dropdown.Height),
        ClipsDescendants=false, ZIndex=1, Parent=tab.content,
    })
    Stroke(frame)
    New("TextLabel", {FontFace=f.Regular, TextColor3=c.Text, Text=name,
        TextXAlignment=Enum.TextXAlignment.Left, BackgroundTransparency=1,
        Position=UDim2.new(0,10,0,10), TextSize=textsize.Normal, Size=UDim2.new(0,200,0,20),
        ZIndex=1, Parent=frame})

    local selDisplay = New("Frame", {
        BackgroundColor3=c.Secondary, BackgroundTransparency=0.04,
        Position=UDim2.new(1,-145,0,6), BorderSizePixel=0,
        Size=UDim2.new(0,135,0,26), ZIndex=2, Parent=frame,
    })
    Stroke(selDisplay, c.Border)

    local function GetDisplayText()
        if multiSelect then return #selected>0 and table.concat(selected,", ") or "None" end
        return tostring(selected)
    end

    local selLbl = New("TextLabel", {FontFace=f.Regular, TextColor3=c.Text, Text=GetDisplayText(),
        TextTruncate=Enum.TextTruncate.AtEnd, BackgroundTransparency=1, TextSize=textsize.Small,
        Size=UDim2.new(1,-30,1,0), Position=UDim2.new(0,10,0,0), TextXAlignment=Enum.TextXAlignment.Left,
        ZIndex=2, Parent=selDisplay})
    local arrow = New("ImageLabel", {Image="rbxassetid://105558791071013",
        ImageColor3=c.TextDark, BackgroundTransparency=1,
        Position=UDim2.new(1,-20,0.5,-5), Size=UDim2.new(0,10,0,10), Rotation=0, ZIndex=2, Parent=selDisplay})

    local totalH = math.min(#options*optH, maxVisible*optH) + searchHeight

    -- FIX: list parented to ScreenGui to avoid clipping from ScrollingFrame content area
    local optContainer = New("Frame", {
        BackgroundColor3=c.Secondary, BackgroundTransparency=0.04,
        BorderSizePixel=0, Size=UDim2.new(0,135,0,totalH),
        Visible=false, ZIndex=100, ClipsDescendants=true,
        Parent=lib.screenGui,
    })
    Stroke(optContainer, c.Border)

    local searchBox = nil
    if searchEnabled then
        local searchBg = New("Frame", {BackgroundColor3=c.Background, BackgroundTransparency=0.3,
            Position=UDim2.new(0,6,0,6), Size=UDim2.new(1,-12,0,20), BorderSizePixel=0, ZIndex=101, Parent=optContainer})
        Stroke(searchBg, c.Border, 0)
        searchBox = New("TextBox", {FontFace=f.Regular, TextColor3=c.Text, PlaceholderText="Search...",
            PlaceholderColor3=c.TextDark, Text="", TextXAlignment=Enum.TextXAlignment.Left,
            TextSize=textsize.Small, BackgroundTransparency=1, Size=UDim2.new(1,-8,1,0),
            Position=UDim2.new(0,6,0,0), ClearTextOnFocus=false, ZIndex=102, Parent=searchBg})
    end

    local optScroll = New("ScrollingFrame", {
        BackgroundTransparency=1, BorderSizePixel=0,
        Position=UDim2.new(0,0,0,searchHeight), Size=UDim2.new(1,0,1,-searchHeight),
        CanvasSize=UDim2.new(0,0,0,#options*optH),
        ScrollBarThickness=0,
        ZIndex=100, Parent=optContainer,
    })
    Layout(optScroll, 0, Enum.SortOrder.LayoutOrder)

    -- FIX: CloseDropdown declared as LOCAL UPVALUE before CreateOptionButton
    -- so the click handler can reference it correctly on first call
    local CloseDropdown

    local function CreateOptionButton(option)
        local ob = New("TextButton", {Name=option, FontFace=f.Regular, TextColor3=c.Text, Text=option,
            BackgroundColor3=Color3.fromRGB(30,30,30), BackgroundTransparency=1, BorderSizePixel=0,
            TextSize=textsize.Small, Size=UDim2.new(1,0,0,optH), ZIndex=100, Parent=optScroll})
        ob.MouseEnter:Connect(function() ob.BackgroundTransparency=0.5 end)
        ob.MouseLeave:Connect(function() ob.BackgroundTransparency=1 end)
        ob.MouseButton1Click:Connect(function()
            if multiSelect then
                local idx = table.find(selected, option)
                if idx then table.remove(selected, idx) else table.insert(selected, option) end
                selLbl.Text = GetDisplayText()
                pcall(callback, selected)
            else
                selected = option
                selLbl.Text = GetDisplayText()
                pcall(callback, selected)
                -- FIX: call the local upvalue, not inline logic that forgets _activeDropdown
                CloseDropdown()
            end
        end)
        return ob
    end

    for _, option in ipairs(options) do CreateOptionButton(option) end

    if searchBox then
        searchBox:GetPropertyChangedSignal("Text"):Connect(function()
            local q = searchBox.Text:lower()
            local vis = 0
            for _, child in ipairs(optScroll:GetChildren()) do
                if child:IsA("TextButton") then
                    local m = q=="" or child.Name:lower():find(q,1,true)
                    child.Visible = m~=nil and m~=false
                    if child.Visible then vis=vis+1 end
                end
            end
            local newH = math.min(vis*optH, maxVisible*optH)
            optScroll.CanvasSize   = UDim2.new(0,0,0,vis*optH)
            optContainer.Size      = UDim2.new(0,135,0,newH+searchHeight)
        end)
    end

    local function RepositionList()
        local vp = game.Workspace.CurrentCamera.ViewportSize
        local ap = selDisplay.AbsolutePosition
        local as = selDisplay.AbsoluteSize
        local lh = optContainer.AbsoluteSize.Y
        local tx = ap.X; local ty = ap.Y + as.Y + 2
        if ty + lh > vp.Y - 8 then ty = ap.Y - lh - 2 end
        if tx + 135 > vp.X   then tx = vp.X - 139 end
        optContainer.Position = UDim2.new(0, tx, 0, ty)
    end

    -- NOW assign CloseDropdown — CreateOptionButton's closures already captured the slot
    CloseDropdown = function()
        expanded            = false
        optContainer.Visible = false
        arrow.Rotation      = 0
        frame.ZIndex        = 1
        if searchBox then searchBox.Text = "" end
        if Library._activeDropdown == CloseDropdown then
            Library._activeDropdown = nil
        end
    end

    local toggleBtn = New("TextButton", {Text="", BackgroundTransparency=1,
        Size=UDim2.new(1,0,1,0), ZIndex=3, Parent=selDisplay})
    toggleBtn.MouseButton1Click:Connect(function()
        if expanded then
            CloseDropdown()
        else
            if Library._activeDropdown then Library._activeDropdown() end
            RepositionList()
            expanded             = true
            optContainer.Visible = true
            arrow.Rotation       = 180
            frame.ZIndex         = 10
            Library._activeDropdown = CloseDropdown
        end
    end)

    lib._connections["dropdown_"..tostring(frame)] = ui.InputBegan:Connect(function(input)
        if not expanded then return end
        if input.UserInputType~=Enum.UserInputType.MouseButton1
        and input.UserInputType~=Enum.UserInputType.Touch then return end
        local mp = input.Position
        local lp2, ls = optContainer.AbsolutePosition, optContainer.AbsoluteSize
        local fp,  fs = frame.AbsolutePosition,        frame.AbsoluteSize
        local inL = mp.X>=lp2.X and mp.X<=lp2.X+ls.X and mp.Y>=lp2.Y and mp.Y<=lp2.Y+ls.Y
        local inH = mp.X>=fp.X  and mp.X<=fp.X+fs.X  and mp.Y>=fp.Y  and mp.Y<=fp.Y+fs.Y
        if not inL and not inH then CloseDropdown() end
    end)

    local methods = {
        SetValue = function(_, v)
            if multiSelect and type(v)=="table" then selected=v elseif not multiSelect then selected=v end
            selLbl.Text = GetDisplayText(); pcall(callback, selected)
        end,
        GetValue = function() return selected end,
        Refresh  = function(_, newOptions)
            options = newOptions
            for _, child in ipairs(optScroll:GetChildren()) do
                if child:IsA("TextButton") then child:Destroy() end
            end
            for _, option in ipairs(options) do CreateOptionButton(option) end
            optScroll.CanvasSize = UDim2.new(0,0,0,#options*optH)
            local newH = math.min(#options*optH, maxVisible*optH)
            optContainer.Size = UDim2.new(0,135,0,newH+searchHeight)
        end,
    }
    if flag and tab._library then
        tab._library:_RegisterConfigElement(flag,"Dropdown",
            function() return selected end, function(v) methods:SetValue(v) end)
    end
    return methods
end

function Library._CreateKeybind(tab, config, lib)
    local name         = config.Name     or "Keybind"
    local default      = config.Default  or Enum.KeyCode.F
    local callback     = config.Callback or function() end
    local linkedToggle = config.Toggle
    local flag         = config.Flag
    local currentKey   = default
    local listening    = false

    local function FireAction()
        if linkedToggle then linkedToggle:SetValue(not linkedToggle:GetValue()) end
        pcall(callback, currentKey)
    end

    local frame = New("Frame", {
        BackgroundColor3=c.Secondary, BackgroundTransparency=0.4,
        BorderSizePixel=0, Size=UDim2.new(1,0,0,s.Button.Height), Parent=tab.content,
    })
    Stroke(frame)

    local nameLbl = New("TextLabel", {FontFace=f.Regular, TextColor3=c.Text, Text=name,
        TextXAlignment=Enum.TextXAlignment.Left, BackgroundTransparency=1,
        Position=UDim2.new(0,10,0.5,-10), TextSize=textsize.Normal, Size=UDim2.new(0,200,0,20), Parent=frame})

    local statusDot = nil
    if linkedToggle then
        statusDot = New("Frame", {
            BackgroundColor3=linkedToggle:GetValue() and c.Accent or c.TextDark,
            AnchorPoint=Vector2.new(0,0.5), Position=UDim2.new(0,10,0.5,0),
            Size=UDim2.new(0,6,0,6), BorderSizePixel=0, Parent=frame,
        })
        nameLbl.Position = UDim2.new(0,22,0.5,-10)
        local origSet = linkedToggle.SetValue
        linkedToggle.SetValue = function(self_, v)
            origSet(self_, v)
            if statusDot then statusDot.BackgroundColor3 = v and c.Accent or c.TextDark end
        end
    end

    local keybindBox = New("Frame", {
        BackgroundColor3=c.Secondary, BackgroundTransparency=0.04,
        AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,-10,0.5,0),
        BorderSizePixel=0, Size=UDim2.new(0,30,0,26), Parent=frame,
    })
    Stroke(keybindBox)
    local keyLbl = New("TextLabel", {FontFace=f.Regular, TextColor3=c.Text, Text=currentKey.Name,
        BackgroundTransparency=1, TextSize=textsize.Normal, Size=UDim2.new(1,0,1,0), Parent=keybindBox})
    local kbBtn  = New("TextButton", {Text="", BackgroundTransparency=1, Size=UDim2.new(1,0,1,0), Parent=keybindBox})

    local keybindId = name.."_"..tostring(tick())
    lib._keybinds[keybindId] = {key=currentKey, callback=FireAction}

    local function UpdateKeyDisplay()
        if listening then
            keyLbl.Text = "..."
            keybindBox.Size = UDim2.new(0,43,0,26)
        else
            local kn = currentKey.Name
            keybindBox.Size = UDim2.new(0, math.max(#kn*9+10,24), 0, 26)
            keyLbl.Text = kn
        end
    end

    kbBtn.MouseButton1Click:Connect(function() listening=true; UpdateKeyDisplay() end)

    local inputConn
    inputConn = ui.InputBegan:Connect(function(input, gp)
        if gp or not listening then return end
        if input.UserInputType == Enum.UserInputType.Keyboard then
            local ignore = {
                [Enum.KeyCode.LeftShift]=true,[Enum.KeyCode.RightShift]=true,
                [Enum.KeyCode.LeftControl]=true,[Enum.KeyCode.RightControl]=true,
                [Enum.KeyCode.LeftAlt]=true,[Enum.KeyCode.RightAlt]=true,
                [Enum.KeyCode.LeftMeta]=true,[Enum.KeyCode.RightMeta]=true,
            }
            if not ignore[input.KeyCode] then
                currentKey = input.KeyCode; listening = false
                lib._keybinds[keybindId].key = currentKey; UpdateKeyDisplay()
            end
        end
    end)
    lib._connections["keybind_"..keybindId] = inputConn
    UpdateKeyDisplay()

    local methods = {
        SetKey = function(_, k) currentKey=k; lib._keybinds[keybindId].key=k; UpdateKeyDisplay() end,
        GetKey = function()    return currentKey end,
    }
    if flag and lib then
        lib:_RegisterConfigElement(flag,"Keybind",
            function() return currentKey end, function(v) methods:SetKey(v) end)
    end
    return methods
end

function Library._CreateColorPicker(tab, config)
    local name     = config.Name     or "Color Picker"
    local default  = config.Default  or Color3.fromRGB(255,255,255)
    local callback = config.Callback or function() end
    local flag     = config.Flag
    local cur      = default
    local hue, sat, val = cur:ToHSV()
    local expanded = false
    local lib      = tab._library

    local frame = New("Frame", {
        BackgroundColor3=c.Secondary, BackgroundTransparency=0.4,
        BorderSizePixel=0, Size=UDim2.new(1,0,0,s.Button.Height), Parent=tab.content,
    })
    Stroke(frame)
    New("TextLabel", {FontFace=f.Regular, TextColor3=c.Text, Text=name,
        TextXAlignment=Enum.TextXAlignment.Left, BackgroundTransparency=1,
        Position=UDim2.new(0,10,0,0), TextSize=textsize.Normal, Size=UDim2.new(1,-50,1,0), Parent=frame})
    local colorPreview = New("Frame", {BackgroundColor3=cur, Position=UDim2.new(1,-45,0.5,-8),
        Size=UDim2.new(0,35,0,16), ZIndex=2, Parent=frame})
    Stroke(colorPreview)
    local prevBtn = New("TextButton", {Text="", BackgroundTransparency=1,
        Size=UDim2.new(1,0,1,0), ZIndex=3, Parent=colorPreview})

    -- FIX: picker parented to screenGui to avoid clipping
    local pickerContainer = New("Frame", {
        BackgroundColor3=Color3.fromRGB(20,20,20),
        BorderSizePixel=0, Size=UDim2.new(0,160,0,115),
        Visible=false, ZIndex=3000, Parent=lib.screenGui,
    })
    Stroke(pickerContainer, Color3.fromRGB(40,40,40))

    local svPicker = New("Frame", {BackgroundColor3=Color3.fromHSV(hue,1,1),
        Position=UDim2.new(0,8,0,8), Size=UDim2.new(1,-16,0,85), ZIndex=3001, Parent=pickerContainer})
    local wl = New("Frame", {BackgroundColor3=Color3.new(1,1,1), Size=UDim2.new(1,0,1,0), ZIndex=3002, Parent=svPicker})
    New("UIGradient", {Color=ColorSequence.new(Color3.new(1,1,1)),
        Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(1,1)}), Parent=wl})
    local bl = New("Frame", {BackgroundColor3=Color3.new(0,0,0), Size=UDim2.new(1,0,1,0), ZIndex=3003, Parent=svPicker})
    New("UIGradient", {Color=ColorSequence.new(Color3.new(0,0,0)), Rotation=90,
        Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(1,0)}), Parent=bl})
    local svCursor = New("Frame", {BackgroundColor3=Color3.new(1,1,1), BackgroundTransparency=1,
        AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.new(sat,0,1-val,0),
        Size=UDim2.new(0,10,0,10), ZIndex=3005, Parent=svPicker})
    New("UIStroke", {Thickness=1.5, Color=Color3.new(1,1,1), Parent=svCursor})

    local hueSlider = New("Frame", {Position=UDim2.new(0,8,0,98), Size=UDim2.new(1,-16,0,8), ZIndex=3001, Parent=pickerContainer})
    New("UIGradient", {Color=ColorSequence.new({
        ColorSequenceKeypoint.new(0,     Color3.fromHSV(0,    1,1)),
        ColorSequenceKeypoint.new(0.167, Color3.fromHSV(0.167,1,1)),
        ColorSequenceKeypoint.new(0.333, Color3.fromHSV(0.333,1,1)),
        ColorSequenceKeypoint.new(0.5,   Color3.fromHSV(0.5,  1,1)),
        ColorSequenceKeypoint.new(0.667, Color3.fromHSV(0.667,1,1)),
        ColorSequenceKeypoint.new(0.833, Color3.fromHSV(0.833,1,1)),
        ColorSequenceKeypoint.new(1,     Color3.fromHSV(1,    1,1)),
    }), Parent=hueSlider})
    local hueCursor = New("Frame", {BackgroundColor3=Color3.new(1,1,1),
        AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.new(hue,0,0.5,0),
        Size=UDim2.new(0,10,0,10), ZIndex=3005, Parent=hueSlider})
    New("UIStroke", {Thickness=1, Color=Color3.fromRGB(20,20,20), Parent=hueCursor})

    local function UpdateColor()
        cur = Color3.fromHSV(hue,sat,val)
        colorPreview.BackgroundColor3 = cur
        svPicker.BackgroundColor3     = Color3.fromHSV(hue,1,1)
        svCursor.Position             = UDim2.new(sat,0,1-val,0)
        hueCursor.Position            = UDim2.new(hue,0,0.5,0)
        pcall(callback, cur)
    end

    local svDragging, hueDragging = false, false
    local function ProcessInput(input)
        if not pickerContainer.Visible then return end
        if svDragging then
            local sz=svPicker.AbsoluteSize; local pos=svPicker.AbsolutePosition
            sat = math.clamp((input.Position.X-pos.X)/sz.X,0,1)
            val = 1-math.clamp((input.Position.Y-pos.Y)/sz.Y,0,1)
            UpdateColor()
        elseif hueDragging then
            local sz=hueSlider.AbsoluteSize; local pos=hueSlider.AbsolutePosition
            hue = math.clamp((input.Position.X-pos.X)/sz.X,0,1)
            UpdateColor()
        end
    end
    svPicker.InputBegan:Connect(function(inp)
        if inp.UserInputType~=Enum.UserInputType.MouseButton1 then return end
        svDragging=true; ProcessInput(inp); Library._activeDragger=ProcessInput
    end)
    hueSlider.InputBegan:Connect(function(inp)
        if inp.UserInputType~=Enum.UserInputType.MouseButton1 then return end
        hueDragging=true; ProcessInput(inp); Library._activeDragger=ProcessInput
    end)
    ui.InputEnded:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 then
            svDragging=false; hueDragging=false; Library._activeDragger=nil
        end
    end)

    local function ClosePicker()
        pickerContainer.Visible=false; expanded=false
        if Library._activePicker==ClosePicker then Library._activePicker=nil end
    end
    local function OpenPicker()
        if Library._activePicker then Library._activePicker() end
        Library._activePicker=ClosePicker
        local vp  = game.Workspace.CurrentCamera.ViewportSize
        local bp  = colorPreview.AbsolutePosition
        local tx  = bp.X - 170; local ty = bp.Y
        if ty+115 > vp.Y then ty = vp.Y-125 end
        if tx < 0         then tx = bp.X+50 end
        pickerContainer.Position = UDim2.new(0,tx,0,ty)
        pickerContainer.Visible  = true
        expanded = true
    end

    prevBtn.MouseButton1Click:Connect(function()
        if expanded then ClosePicker() else OpenPicker() end
    end)

    -- FIX: outside-click closes the picker (was missing in original)
    lib._connections["colorpicker_"..tostring(frame)] = ui.InputBegan:Connect(function(inp)
        if not expanded then return end
        if inp.UserInputType~=Enum.UserInputType.MouseButton1
        and inp.UserInputType~=Enum.UserInputType.Touch then return end
        if svDragging or hueDragging then return end
        local mp  = inp.Position
        local pp, ps = pickerContainer.AbsolutePosition, pickerContainer.AbsoluteSize
        local fp, fs = frame.AbsolutePosition,          frame.AbsoluteSize
        local inPicker = mp.X>=pp.X and mp.X<=pp.X+ps.X and mp.Y>=pp.Y and mp.Y<=pp.Y+ps.Y
        local inFrame  = mp.X>=fp.X and mp.X<=fp.X+fs.X and mp.Y>=fp.Y and mp.Y<=fp.Y+fs.Y
        if not inPicker and not inFrame then ClosePicker() end
    end)

    local methods = {
        SetColor = function(_, color)
            cur=color; hue,sat,val=color:ToHSV(); UpdateColor()
        end,
        GetColor = function() return cur end,
    }
    if flag and tab._library then
        tab._library:_RegisterConfigElement(flag,"ColorPicker",
            function() return cur end, function(v) methods:SetColor(v) end)
    end
    return methods
end

function Library._CreateTextBox(tab, config)
    local name        = config.Name         or "TextBox"
    local default     = config.Default      or ""
    local placeholder = config.Placeholder  or "Enter text..."
    local callback    = config.Callback     or function() end
    local clearFocus  = config.ClearOnFocus or false
    local numbersOnly = config.NumbersOnly  or false
    local flag        = config.Flag
    local cur         = default

    local frame = New("Frame", {
        BackgroundColor3=c.Secondary, BackgroundTransparency=0.4,
        BorderSizePixel=0, Size=UDim2.new(1,0,0,s.TextBox.Height), Parent=tab.content,
    })
    Stroke(frame)
    New("TextLabel", {FontFace=f.Regular, TextColor3=c.Text, Text=name,
        TextXAlignment=Enum.TextXAlignment.Left, BackgroundTransparency=1,
        Position=UDim2.new(0,10,0.5,-10), TextSize=textsize.Normal, Size=UDim2.new(0,150,0,20), Parent=frame})
    local icon = New("ImageLabel", {BackgroundTransparency=1, Image="rbxassetid://93828793199781",
        ImageColor3=c.TextDark, AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,-165,0.5,0),
        Size=UDim2.new(0,18,0,18), Parent=frame})
    local tbContainer = New("Frame", {BackgroundColor3=c.Secondary, BackgroundTransparency=0.04,
        AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,-10,0.5,0), BorderSizePixel=0,
        Size=UDim2.new(0,s.TextBox.InputWidth,0,26), Parent=frame})
    local tbStroke = Stroke(tbContainer)
    local textBox = New("TextBox", {FontFace=f.Regular, TextColor3=c.Text, PlaceholderText=placeholder,
        PlaceholderColor3=c.TextDark, Text=cur, TextXAlignment=Enum.TextXAlignment.Left,
        TextTruncate=Enum.TextTruncate.AtEnd, BackgroundTransparency=1, TextSize=textsize.Small,
        Size=UDim2.new(1,-16,1,0), Position=UDim2.new(0,8,0,0), ClearTextOnFocus=clearFocus,
        Parent=tbContainer})

    textBox.Focused:Connect(function()
        tbContainer.BackgroundTransparency=0; tbStroke.Color=c.Accent; icon.ImageColor3=c.Text
    end)
    textBox.FocusLost:Connect(function(entered)
        tbContainer.BackgroundTransparency=0.04; tbStroke.Color=c.Border; icon.ImageColor3=c.TextDark
        if numbersOnly then
            local n = tonumber(textBox.Text)
            if n then cur=tostring(n); textBox.Text=cur else textBox.Text=cur end
        else cur=textBox.Text end
        pcall(callback, cur, entered)
    end)
    if numbersOnly then
        textBox:GetPropertyChangedSignal("Text"):Connect(function()
            local fl=textBox.Text:gsub("[^%d%.%-]","")
            if textBox.Text~=fl then textBox.Text=fl end
        end)
    end

    local methods = {
        SetText        = function(_, t) cur=tostring(t); textBox.Text=cur end,
        GetText        = function()    return cur end,
        SetPlaceholder = function(_, t) textBox.PlaceholderText=t end,
        Focus          = function()    textBox:CaptureFocus() end,
    }
    if flag and tab._library then
        tab._library:_RegisterConfigElement(flag,"TextBox",
            function() return cur end, function(v) methods:SetText(v) end)
    end
    return methods
end

function Library._CreateProgressBar(tab, config)
    local name    = config.Name    or "Progress"
    local min     = config.Min     or 0
    local max     = config.Max     or 100
    local default = config.Default or 0
    local suffix  = config.Suffix  or ""
    local cur     = math.clamp(default, min, max)

    local frame = New("Frame", {
        BackgroundColor3=c.Secondary, BackgroundTransparency=0.4,
        BorderSizePixel=0, Size=UDim2.new(1,0,0,s.Slider.Height), Parent=tab.content,
    })
    Stroke(frame)
    New("TextLabel", {FontFace=f.Regular, TextColor3=c.Text, Text=name,
        TextXAlignment=Enum.TextXAlignment.Left, BackgroundTransparency=1,
        Position=UDim2.new(0,10,0,5), TextSize=textsize.Normal, Size=UDim2.new(0,200,0,20), Parent=frame})
    local valLbl = New("TextLabel", {FontFace=f.Regular, TextColor3=c.TextDark, Text=tostring(cur)..suffix,
        TextXAlignment=Enum.TextXAlignment.Right, BackgroundTransparency=1,
        Position=UDim2.new(1,-60,0,5), TextSize=textsize.Normal, Size=UDim2.new(0,50,0,20), Parent=frame})
    local trackBg = New("Frame", {BackgroundColor3=c.Toggle.Disabled,
        Position=UDim2.new(0,10,0,29), BorderSizePixel=0, Size=UDim2.new(1,-20,0,7), Parent=frame})
    local ratio = (max-min)>0 and (cur-min)/(max-min) or 0
    local fill  = New("Frame", {BackgroundColor3=c.Accent, BorderSizePixel=0,
        Size=UDim2.new(ratio,0,1,0), Parent=trackBg})

    local function Refresh(value)
        cur = math.clamp(value,min,max)
        local r=(max-min)>0 and (cur-min)/(max-min) or 0
        fill.Size=UDim2.new(r,0,1,0); valLbl.Text=tostring(cur)..suffix
    end
    return {
        SetValue = function(_,v) Refresh(v) end,
        GetValue = function()   return cur end,
        SetMax   = function(_,v) max=v; Refresh(cur) end,
        SetMin   = function(_,v) min=v; Refresh(cur) end,
    }
end

function Library._CreateTable(tab, config)
    local name       = config.Name       or "Table"
    local columns    = config.Columns    or {"Name","Value"}
    local rowHeight  = config.RowHeight  or 28
    local maxVisible = config.MaxVisible or 6
    local data       = {}
    local colCount   = #columns

    local frame = New("Frame", {
        BackgroundColor3=c.Secondary, BackgroundTransparency=0.4,
        BorderSizePixel=0, Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
        ClipsDescendants=true, Parent=tab.content,
    })
    Stroke(frame)
    local titleLbl = New("TextLabel", {FontFace=f.Regular, TextColor3=c.Text, Text=name,
        TextXAlignment=Enum.TextXAlignment.Left, BackgroundTransparency=1,
        Position=UDim2.new(0,10,0,6), TextSize=textsize.Normal, Size=UDim2.new(1,-20,0,20), Parent=frame})

    local headerRow = New("Frame", {BackgroundColor3=c.Background, BackgroundTransparency=0.2,
        BorderSizePixel=0, Position=UDim2.new(0,0,0,30), Size=UDim2.new(1,0,0,26), Parent=frame})
    for i, col in ipairs(columns) do
        local xPos=(i-1)/colCount; local w=1/colCount
        New("TextLabel", {FontFace=f.Bold, TextColor3=c.TextDark, Text=col,
            TextXAlignment=Enum.TextXAlignment.Left, TextTruncate=Enum.TextTruncate.AtEnd,
            BackgroundTransparency=1, Position=UDim2.new(xPos,i==1 and 10 or 4,0,0),
            Size=UDim2.new(w,i==1 and -10 or -4,1,0), TextSize=textsize.Small, Parent=headerRow})
    end
    New("Frame", {BackgroundColor3=c.Border, BorderSizePixel=0,
        Position=UDim2.new(0,0,0,56), Size=UDim2.new(1,0,0,1), Parent=frame})

    local bodyScroll = New("ScrollingFrame", {
        BackgroundTransparency=1, BorderSizePixel=0,
        Position=UDim2.new(0,0,0,57), Size=UDim2.new(1,0,0,0),
        CanvasSize=UDim2.new(0,0,0,0), AutomaticCanvasSize=Enum.AutomaticSize.Y,
        ScrollBarThickness=0,
        ScrollingDirection=Enum.ScrollingDirection.Y, Parent=frame,
    })
    Layout(bodyScroll, 0, Enum.SortOrder.LayoutOrder)

    local rowFrames = {}
    local function RefreshHeight()
        local vis=math.min(#data,maxVisible); local h=vis*rowHeight
        bodyScroll.Size=UDim2.new(1,0,0,h); bodyScroll.CanvasSize=UDim2.new(0,0,0,#data*rowHeight)
        frame.Size=UDim2.new(1,0,0,57+h+(h>0 and 6 or 0))
    end
    local function MakeRowFrame(idx, rowData)
        local isEven=idx%2==0
        local r = New("Frame", {
            BackgroundColor3=isEven and c.Background or c.Secondary,
            BackgroundTransparency=isEven and 0.5 or 0.8,
            BorderSizePixel=0, Size=UDim2.new(1,0,0,rowHeight), LayoutOrder=idx, Parent=bodyScroll,
        })
        for i=1,colCount do
            local xPos=(i-1)/colCount; local w=1/colCount
            New("TextLabel", {FontFace=f.Regular, TextColor3=c.Text, Text=tostring(rowData[i] or ""),
                TextXAlignment=Enum.TextXAlignment.Left, TextTruncate=Enum.TextTruncate.AtEnd,
                BackgroundTransparency=1, Position=UDim2.new(xPos,i==1 and 10 or 4,0,0),
                Size=UDim2.new(w,i==1 and -10 or -4,1,0), TextSize=textsize.Small, Parent=r})
        end
        return r
    end
    local function RenderRows()
        for _,r in ipairs(rowFrames) do if r and r.Parent then r:Destroy() end end
        rowFrames={}
        for i,d in ipairs(data) do table.insert(rowFrames,MakeRowFrame(i,d)) end
        RefreshHeight()
    end
    RefreshHeight()

    return {
        AddRow    = function(_,d) table.insert(data,d); local r=MakeRowFrame(#data,d); table.insert(rowFrames,r); RefreshHeight() end,
        RemoveRow = function(_,i) if i>=1 and i<=#data then table.remove(data,i); RenderRows() end end,
        ClearRows = function(_) data={}; RenderRows() end,
        SetData   = function(_,d) data=d; RenderRows() end,
        GetData   = function()  return data end,
        SetTitle  = function(_,t) titleLbl.Text=t end,
    }
end

function Library._CreateConfigSection(tab)
    local lib = tab._library
    Library._CreateContentSection(tab, "Configuration")

    local configNameBox = Library._CreateTextBox(tab, {
        Name="Config Name", Default="default", Placeholder="Enter config name...",
        Callback=function(text) lib._currentConfig=text end,
    })
    local configDropdown
    configDropdown = Library._CreateDropdown(tab, {
        Name="Select Config", Options=lib:GetConfigs(), Default="default",
        Callback=function(selected) configNameBox:SetText(selected); lib._currentConfig=selected end,
    })
    Library._CreateButton(tab, {Name="Save Config", Callback=function()
        local n=configNameBox:GetText()
        if n~="" then lib:SaveConfig(n); configDropdown:Refresh(lib:GetConfigs()) end
    end})
    Library._CreateButton(tab, {Name="Load Config", Callback=function()
        local n=configNameBox:GetText()
        if n~="" then lib:LoadConfig(n) end
    end})
    Library._CreateButton(tab, {Name="Delete Config", Callback=function()
        local n=configNameBox:GetText()
        if n~="" then lib:DeleteConfig(n); configDropdown:Refresh(lib:GetConfigs()) end
    end})
    Library._CreateButton(tab, {Name="Refresh Configs", Callback=function()
        configDropdown:Refresh(lib:GetConfigs())
        lib:Notify({Title="Configs Refreshed", Description="Config list updated", Duration=2, Icon="rbxassetid://10723356507"})
    end})
    Library._CreateToggle(tab, {Name="Auto Save", Default=false,
        Callback=function(enabled) lib:SetAutoSave(enabled) end})

    return {RefreshConfigs=function() configDropdown:Refresh(lib:GetConfigs()) end}
end

return Library
