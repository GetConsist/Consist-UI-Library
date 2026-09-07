local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local GuiParent = PlayerGui
if typeof(gethui) == "function" then
    local ok, result = pcall(gethui)
    if ok and result then
        GuiParent = result
    end
end

local old = GuiParent:FindFirstChild("ConsistUI")
if old then
    old:Destroy()
end

local function new(className, properties, parent)
    local object = Instance.new(className)
    for property, value in pairs(properties or {}) do
        object[property] = value
    end
    object.Parent = parent
    return object
end

local function round(object, radius)
    return new("UICorner", {
        CornerRadius = UDim.new(0, radius),
    }, object)
end

local function stroke(object, color, thickness, transparency)
    return new("UIStroke", {
        Color = color,
        Thickness = thickness or 1,
        Transparency = transparency or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, object)
end

local function tween(object, duration, properties)
    local animation = TweenService:Create(
        object,
        TweenInfo.new(duration or 0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        properties
    )
    animation:Play()
    return animation
end

local UI_FONT = Enum.Font.BuilderSans
local UI_FONT_MEDIUM = Enum.Font.BuilderSansMedium
local UI_FONT_BOLD = Enum.Font.BuilderSansBold
local SLIDER_FONT = Enum.Font.Gotham

local CONSIST_ICON_BASE_URL = "https://sprightly-scone-c58b48.netlify.app/icons/v3/"

local CONSIST_ICON_FILES = {
    Reset = "reset.png",
    Chevron = "chevron.png",
    Home = "home.png",
    Combat = "combat.png",
    Visual = "visual.png",
    Player = "player.png",
    Movement = "movement.png",
    World = "world.png",
    Misc = "misc.png",
    Configs = "configs.png",
    Settings = "settings.png",
    Search = "search.png",
}

local PAGE_ICONS = {
    Home = "Home",
    Combat = "Combat",
    Visual = "Visual",
    Player = "Player",
    Movement = "Movement",
    World = "World",
    Misc = "Misc",
    Configs = "Configs",
    Settings = "Settings",
}

local hostedIconAssets = {}

local CONSIST_ICON_REVISION = "v4_20260906"
local CONSIST_SITE_ROOT = "https://sprightly-scone-c58b48.netlify.app/"

local function resolveHostedIcon(iconName)
    if not iconName then
        return ""
    end

    if hostedIconAssets[iconName] then
        return hostedIconAssets[iconName]
    end

    local fileName = CONSIST_ICON_FILES[iconName]
    if not fileName then
        return ""
    end

    if type(writefile) ~= "function" or type(getcustomasset) ~= "function" then
        return ""
    end

    local safeName = string.lower(fileName):gsub("[^%w%._%-]", "_")
    local localFileName = "consist_ui_" .. CONSIST_ICON_REVISION .. "_" .. safeName

    -- Fast path: after the first successful run, use the already-downloaded
    -- icon immediately instead of hitting Netlify again.
    if type(isfile) == "function" then
        local cached = false

        pcall(function()
            cached = isfile(localFileName)
        end)

        if cached then
            local assetOk, asset = pcall(function()
                return getcustomasset(localFileName)
            end)

            if assetOk and asset then
                hostedIconAssets[iconName] = asset
                return asset
            end
        end
    end

    local urls = {
        CONSIST_ICON_BASE_URL .. fileName .. "?rev=" .. CONSIST_ICON_REVISION,
        CONSIST_SITE_ROOT .. "icons/" .. fileName .. "?rev=" .. CONSIST_ICON_REVISION,
        CONSIST_SITE_ROOT .. fileName .. "?rev=" .. CONSIST_ICON_REVISION,
    }

    local bytes

    for _, url in ipairs(urls) do
        local ok, result = pcall(function()
            return game:HttpGet(url, true)
        end)

        if ok and type(result) == "string" and #result > 32 then
            bytes = result
            break
        end
    end

    if not bytes then
        return ""
    end

    local wrote = pcall(function()
        writefile(localFileName, bytes)
    end)

    if not wrote then
        return ""
    end

    local assetOk, asset = pcall(function()
        return getcustomasset(localFileName)
    end)

    if assetOk and asset then
        hostedIconAssets[iconName] = asset
        return asset
    end

    return ""
end

local function preloadHostedIcons()
    local remaining = 0
    local finished = Instance.new("BindableEvent")

    for iconName in pairs(CONSIST_ICON_FILES) do
        remaining += 1

        task.spawn(function()
            resolveHostedIcon(iconName)

            remaining -= 1
            if remaining <= 0 then
                finished:Fire()
            end
        end)
    end

    if remaining > 0 then
        finished.Event:Wait()
    end

    finished:Destroy()
end

-- Load all hosted images together before constructing the UI. Missing images
-- download concurrently; cached images resolve almost instantly on later runs.
preloadHostedIcons()

local CONSIST_RESET_ICON = resolveHostedIcon("Reset")

local CONSIST_COLOR_WHEEL_B64 = "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"
local colorWheelAsset

local function decodeBase64(data)
    local alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    data = tostring(data or ""):gsub("[^" .. alphabet .. "=]", "")

    return (data:gsub(".", function(char)
        if char == "=" then
            return ""
        end

        local value = alphabet:find(char, 1, true)
        if not value then
            return ""
        end

        value -= 1
        local bits = ""

        for bit = 6, 1, -1 do
            bits ..= value % (2 ^ bit) - value % (2 ^ (bit - 1)) > 0 and "1" or "0"
        end

        return bits
    end):gsub("%d%d%d?%d?%d?%d?%d?%d?", function(bits)
        if #bits ~= 8 then
            return ""
        end

        local byte = 0
        for index = 1, 8 do
            if bits:sub(index, index) == "1" then
                byte += 2 ^ (8 - index)
            end
        end

        return string.char(byte)
    end))
end

local function resolveColorWheelAsset()
    if colorWheelAsset then
        return colorWheelAsset
    end

    if type(writefile) ~= "function" or type(getcustomasset) ~= "function" then
        return nil
    end

    local fileName = "consist_mockup_color_wheel.png"
    local exists = false

    if type(isfile) == "function" then
        pcall(function()
            exists = isfile(fileName)
        end)
    end

    if not exists then
        local bytes = decodeBase64(CONSIST_COLOR_WHEEL_B64)
        if bytes == "" then
            return nil
        end

        local ok = pcall(function()
            writefile(fileName, bytes)
        end)

        if not ok then
            return nil
        end
    end

    pcall(function()
        colorWheelAsset = getcustomasset(fileName)
    end)

    return colorWheelAsset
end

local THEMES = {
    Light = {
        shell = Color3.fromRGB(253, 253, 253),
        surface = Color3.fromRGB(243, 244, 247),
        surfaceHover = Color3.fromRGB(239, 241, 245),
        field = Color3.fromRGB(237, 239, 243),
        fieldHover = Color3.fromRGB(233, 236, 241),
        stroke = Color3.fromRGB(226, 229, 234),
        strokeStrong = Color3.fromRGB(213, 217, 224),
        text = Color3.fromRGB(62, 66, 73),
        label = Color3.fromRGB(79, 84, 93),
        muted = Color3.fromRGB(132, 138, 148),
        dim = Color3.fromRGB(167, 173, 182),
        icon = Color3.fromRGB(118, 123, 132),
        iconHover = Color3.fromRGB(58, 63, 71),
        iconActive = Color3.fromRGB(0, 0, 0),
        track = Color3.fromRGB(221, 225, 231),
        knob = Color3.fromRGB(252, 252, 252),
        knobStroke = Color3.fromRGB(136, 142, 151),
        shadow = Color3.fromRGB(80, 85, 94),
        toggleOff = Color3.fromRGB(229, 232, 237),
        toggleStroke = Color3.fromRGB(218, 222, 228),
        popup = Color3.fromRGB(249, 250, 252),
    },
    Dark = {
        shell = Color3.fromRGB(18, 19, 22),
        surface = Color3.fromRGB(23, 24, 28),
        surfaceHover = Color3.fromRGB(29, 30, 35),
        field = Color3.fromRGB(28, 29, 34),
        fieldHover = Color3.fromRGB(34, 35, 41),
        stroke = Color3.fromRGB(39, 41, 47),
        strokeStrong = Color3.fromRGB(50, 52, 59),
        text = Color3.fromRGB(230, 232, 237),
        label = Color3.fromRGB(205, 208, 214),
        muted = Color3.fromRGB(141, 145, 154),
        dim = Color3.fromRGB(92, 96, 105),
        icon = Color3.fromRGB(154, 159, 169),
        iconHover = Color3.fromRGB(216, 220, 227),
        iconActive = Color3.fromRGB(255, 255, 255),
        track = Color3.fromRGB(44, 46, 53),
        knob = Color3.fromRGB(250, 250, 250),
        knobStroke = Color3.fromRGB(205, 208, 214),
        shadow = Color3.fromRGB(0, 0, 0),
        toggleOff = Color3.fromRGB(36, 38, 44),
        toggleStroke = Color3.fromRGB(49, 51, 58),
        popup = Color3.fromRGB(21, 22, 26),
    },
    Black = {
        shell = Color3.fromRGB(9, 10, 12),
        surface = Color3.fromRGB(14, 15, 18),
        surfaceHover = Color3.fromRGB(20, 21, 25),
        field = Color3.fromRGB(19, 20, 24),
        fieldHover = Color3.fromRGB(25, 26, 31),
        stroke = Color3.fromRGB(31, 33, 38),
        strokeStrong = Color3.fromRGB(43, 45, 51),
        text = Color3.fromRGB(235, 236, 240),
        label = Color3.fromRGB(209, 212, 218),
        muted = Color3.fromRGB(133, 137, 147),
        dim = Color3.fromRGB(78, 82, 90),
        icon = Color3.fromRGB(150, 155, 165),
        iconHover = Color3.fromRGB(220, 224, 231),
        iconActive = Color3.fromRGB(255, 255, 255),
        track = Color3.fromRGB(35, 37, 43),
        knob = Color3.fromRGB(252, 252, 252),
        knobStroke = Color3.fromRGB(214, 217, 224),
        shadow = Color3.fromRGB(0, 0, 0),
        toggleOff = Color3.fromRGB(28, 30, 35),
        toggleStroke = Color3.fromRGB(42, 44, 50),
        popup = Color3.fromRGB(12, 13, 16),
    },
}

local ACCENTS = {
    Color3.fromRGB(119, 115, 226),
    Color3.fromRGB(145, 174, 255),
    Color3.fromRGB(117, 177, 236),
    Color3.fromRGB(112, 206, 225),
    Color3.fromRGB(108, 225, 192),
}

local activeThemeName = "Dark"
local Accent = ACCENTS[2]

local Screen = new("ScreenGui", {
    Name = "ConsistUI",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Global,
    DisplayOrder = 100,
}, GuiParent)

local Overlay = new("Frame", {
    Name = "Overlay",
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ZIndex = 100000,
}, Screen)

local App = new("Frame", {
    Name = "App",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(748, 474),
    BackgroundColor3 = THEMES[activeThemeName].shell,
    BorderSizePixel = 0,
    ClipsDescendants = true,
}, Screen)
round(App, 15)
local AppStroke = stroke(App, THEMES[activeThemeName].strokeStrong, 1, 0)

local themed = {}
local function themeObject(object, property, key)
    themed[#themed + 1] = {object = object, property = property, key = key}
    object[property] = THEMES[activeThemeName][key]
end

local accentObjects = {}
local function accentObject(object, property)
    accentObjects[#accentObjects + 1] = {object = object, property = property}
    object[property] = Accent
end

local SearchPanel = new("Frame", {
    Position = UDim2.fromOffset(8, 8),
    Size = UDim2.fromOffset(176, 24),
    BorderSizePixel = 0,
    ClipsDescendants = true,
}, App)
round(SearchPanel, 10)
themeObject(SearchPanel, "BackgroundColor3", "surface")
local SearchPanelStroke = stroke(SearchPanel, THEMES[activeThemeName].stroke, 1, 0.15)
themeObject(SearchPanelStroke, "Color", "stroke")

local SearchIcon = new("ImageLabel", {
    Position = UDim2.fromOffset(10, 4),
    Size = UDim2.fromOffset(16, 16),
    BackgroundTransparency = 1,
    ImageTransparency = 0,
    Image = resolveHostedIcon("Search"),
    ScaleType = Enum.ScaleType.Fit,
    ZIndex = 2,
}, SearchPanel)
themeObject(SearchIcon, "ImageColor3", "icon")

local SearchTextClip = new("Frame", {
    Position = UDim2.fromOffset(31, 0),
    Size = UDim2.new(1, -38, 1, 0),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ClipsDescendants = true,
}, SearchPanel)

local SearchBox = new("TextBox", {
    Position = UDim2.fromOffset(0, 0),
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ClipsDescendants = true,
    ClearTextOnFocus = false,
    PlaceholderText = "Search function ...",
    Text = "",
    Font = UI_FONT,
    TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left,
}, SearchTextClip)
themeObject(SearchBox, "TextColor3", "text")
themeObject(SearchBox, "PlaceholderColor3", "dim")

local SEARCH_CHARACTER_LIMIT = 40
local trimmingSearchText = false

SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    if trimmingSearchText then
        return
    end

    local text = SearchBox.Text
    local characterCount = utf8.len(text)

    if characterCount and characterCount > SEARCH_CHARACTER_LIMIT then
        local cutoff = utf8.offset(text, SEARCH_CHARACTER_LIMIT + 1)

        if cutoff then
            trimmingSearchText = true
            SearchBox.Text = string.sub(text, 1, cutoff - 1)
            SearchBox.CursorPosition = #SearchBox.Text + 1
            trimmingSearchText = false
        end
    elseif not characterCount and #text > SEARCH_CHARACTER_LIMIT then
        trimmingSearchText = true
        SearchBox.Text = string.sub(text, 1, SEARCH_CHARACTER_LIMIT)
        SearchBox.CursorPosition = #SearchBox.Text + 1
        trimmingSearchText = false
    end
end)

local SettingsButton = new("ImageButton", {
    Position = UDim2.fromOffset(206, 8),
    Size = UDim2.fromOffset(24, 24),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    AutoButtonColor = false,
    Image = resolveHostedIcon("Settings"),
    ImageTransparency = 0.08,
    ScaleType = Enum.ScaleType.Fit,
    ZIndex = 20,
}, App)
themeObject(SettingsButton, "ImageColor3", "icon")


local UtilityBar = new("Frame", {
    Position = UDim2.fromOffset(482, 8),
    Size = UDim2.fromOffset(258, 24),
    BorderSizePixel = 0,
    ClipsDescendants = true,
    ZIndex = 10,
}, App)
round(UtilityBar, 10)
themeObject(UtilityBar, "BackgroundColor3", "surface")
local UtilityBarStroke = stroke(UtilityBar, THEMES[activeThemeName].stroke, 1, 0.15)
themeObject(UtilityBarStroke, "Color", "stroke")

local Sidebar = new("Frame", {
    Position = UDim2.fromOffset(8, 45),
    Size = UDim2.fromOffset(176, 421),
    BorderSizePixel = 0,
    ClipsDescendants = true,
}, App)
round(Sidebar, 13)
themeObject(Sidebar, "BackgroundColor3", "surface")
local SidebarStroke = stroke(Sidebar, THEMES[activeThemeName].stroke, 1, 0)
themeObject(SidebarStroke, "Color", "stroke")

local Logo = new("Frame", {
    Position = UDim2.fromOffset(20, 17),
    Size = UDim2.fromOffset(130, 32),
    BackgroundTransparency = 1,
}, Sidebar)

local logoLayout = new("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    VerticalAlignment = Enum.VerticalAlignment.Center,
    Padding = UDim.new(0, 1),
}, Logo)

for _, letter in ipairs({"C","O","N","S","I","S","T"}) do
    local label = new("TextLabel", {
        Size = UDim2.fromOffset(18, 28),
        BackgroundTransparency = 1,
        Text = letter,
        Font = UI_FONT_BOLD,
        TextSize = 24,
        TextXAlignment = Enum.TextXAlignment.Center,
    }, Logo)

    if letter == "I" or (#Logo:GetChildren() >= 6 and (letter == "S" or letter == "T")) then
        label.TextColor3 = Accent
        accentObject(label, "TextColor3")
    else
        themeObject(label, "TextColor3", "text")
    end
end

local pageOrder = {"Home","Combat","Visual","Player","Movement","World","Misc","Configs","Settings"}
local activePage = "Combat"
local navButtons = {}

local ActiveBar = new("Frame", {
    Position = UDim2.fromOffset(3, 141),
    Size = UDim2.fromOffset(2, 18),
    BackgroundColor3 = Accent,
    BorderSizePixel = 0,
    ZIndex = 6,
}, App)
round(ActiveBar, 999)
accentObject(ActiveBar, "BackgroundColor3")

local navY = 62
for index, pageName in ipairs(pageOrder) do
    local button = new("TextButton", {
        Name = pageName,
        Position = UDim2.fromOffset(8, navY + (index - 1) * 37),
        Size = UDim2.fromOffset(160, 32),
        BackgroundTransparency = pageName == activePage and 0 or 1,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        ZIndex = 3,
    }, Sidebar)
    round(button, 8)

    if pageName == activePage then
        themeObject(button, "BackgroundColor3", "field")
    else
        button.BackgroundColor3 = THEMES[activeThemeName].surface
    end

    local icon = new("ImageLabel", {
        Position = UDim2.fromOffset(16, 3),
        Size = UDim2.fromOffset(26, 26),
        BackgroundTransparency = 1,
        Image = resolveHostedIcon(PAGE_ICONS[pageName]),
        ScaleType = Enum.ScaleType.Fit,
        ZIndex = 4,
    }, button)

    local label = new("TextLabel", {
        Position = UDim2.fromOffset(48, 0),
        Size = UDim2.new(1, -54, 1, 0),
        BackgroundTransparency = 1,
        Text = pageName,
        Font = UI_FONT_MEDIUM,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 4,
    }, button)

    navButtons[pageName] = {
        button = button,
        icon = icon,
        label = label,
        index = index,
    }
end

local Main = new("Frame", {
    Position = UDim2.fromOffset(184, 0),
    Size = UDim2.fromOffset(564, 474),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
}, App)

local Content = new("Frame", {
    Position = UDim2.fromOffset(28, 45),
    Size = UDim2.fromOffset(538, 417),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
}, Main)

local function label(parent, properties)
    local l = new("TextLabel", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Font = UI_FONT,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
    }, parent)

    for k, v in pairs(properties or {}) do
        l[k] = v
    end

    return l
end

local SectionObjects = {}
local function makeSection(titleText, x, y, width, height, parent)
    parent = parent or Content

    local shadow = new("Frame", {
        Position = UDim2.fromOffset(x, y + 1),
        Size = UDim2.fromOffset(width, height),
        BackgroundTransparency = 0.95,
        BorderSizePixel = 0,
        ZIndex = 0,
    }, parent)
    round(shadow, 12)
    themeObject(shadow, "BackgroundColor3", "shadow")

    local panel = new("Frame", {
        Position = UDim2.fromOffset(x, y),
        Size = UDim2.fromOffset(width, height),
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 1,
    }, parent)
    round(panel, 12)
    themeObject(panel, "BackgroundColor3", "surface")
    local panelStroke = stroke(panel, THEMES[activeThemeName].stroke, 1, 0.15)
    themeObject(panelStroke, "Color", "stroke")

    SectionObjects[#SectionObjects + 1] = panel
    return panel, shadow
end

local function separator(parent, y)
    local line = new("Frame", {
        Position = UDim2.fromOffset(9, y),
        Size = UDim2.new(1, -18, 0, 1),
        BorderSizePixel = 0,
    }, parent)
    themeObject(line, "BackgroundColor3", "stroke")
end

local function makeToggle(parent, x, y, initial, onChanged)
    local state = initial == true

    local box = new("Frame", {
        Position = UDim2.fromOffset(x, y),
        Size = UDim2.fromOffset(17, 17),
        BackgroundColor3 = state and Accent or THEMES[activeThemeName].toggleOff,
        BorderSizePixel = 0,
        ZIndex = 8,
    }, parent)
    round(box, 5)

    local boxStroke = stroke(
        box,
        state and Accent or THEMES[activeThemeName].toggleStroke,
        1,
        state and 0.05 or 0
    )

    if state then
        accentObject(box, "BackgroundColor3")
        accentObject(boxStroke, "Color")
    else
        themeObject(box, "BackgroundColor3", "toggleOff")
        themeObject(boxStroke, "Color", "toggleStroke")
    end

    local hit = new("TextButton", {
        Position = UDim2.fromOffset(x - 3, y - 3),
        Size = UDim2.fromOffset(24, 24),
        BackgroundTransparency = 1,
        Text = "",
        BorderSizePixel = 0,
        AutoButtonColor = false,
        ZIndex = 9,
    }, parent)

    local function setState(nextState, emit)
        state = nextState == true
        tween(box, 0.12, {
            BackgroundColor3 = state and Accent or THEMES[activeThemeName].toggleOff,
        })
        tween(boxStroke, 0.12, {
            Color = state and Accent or THEMES[activeThemeName].toggleStroke,
        })
        if emit and onChanged then
            task.spawn(onChanged, state)
        end
    end

    hit.MouseButton1Click:Connect(function()
        setState(not state, true)
    end)

    return {
        Instance = hit,
        Set = function(_, value, silent)
            setState(value, silent ~= true)
        end,
        Get = function()
            return state
        end,
        SetVisible = function(_, visible)
            hit.Parent.Visible = visible ~= false
        end,
    }
end

local activePopup
local activeSubmenu
local activeDropdown
local activeColorPicker
local activePopupButton
local activeSubmenuButton
local activeDropdownButton
local activeDropdownArrow
local activeColorPickerButton
local closePopup
local closeSubmenu
local closeDropdown
local closeColorPicker

local function pointInside(guiObject, point)
    if not guiObject or not guiObject.Parent then
        return false
    end
    local p = guiObject.AbsolutePosition
    local s = guiObject.AbsoluteSize
    return point.X >= p.X and point.X <= p.X + s.X
        and point.Y >= p.Y and point.Y <= p.Y + s.Y
end

closeColorPicker = function()
    if activeColorPicker then
        activeColorPicker:Destroy()
        activeColorPicker = nil
    end
    activeColorPickerButton = nil
end

closeDropdown = function()
    if activeDropdownArrow and activeDropdownArrow.Parent then
        tween(activeDropdownArrow, 0.12, {Rotation = 0})
    end
    activeDropdownArrow = nil

    if activeDropdown then
        activeDropdown:Destroy()
        activeDropdown = nil
    end
    activeDropdownButton = nil
end

closeSubmenu = function()
    closeDropdown()
    closeColorPicker()

    if activeSubmenu then
        activeSubmenu:Destroy()
        activeSubmenu = nil
    end
    activeSubmenuButton = nil
end

closePopup = function()
    closeSubmenu()

    if activePopup then
        activePopup:Destroy()
        activePopup = nil
    end
    activePopupButton = nil
end

local function capturePopupSurface(frame, zIndex)
    local capture = new("TextButton", {
        Name = "InputCapture",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        Active = true,
        ZIndex = zIndex,
    }, frame)

    capture.MouseButton1Click:Connect(function()
        -- Intentionally consume blank popup clicks.
    end)

    return capture
end

local function popupPositionBeside(anchorButton, width, height, preferRight)
    local appPos = App.AbsolutePosition
    local appSize = App.AbsoluteSize
    local anchorPos = anchorButton.AbsolutePosition
    local anchorSize = anchorButton.AbsoluteSize
    local overlayPos = Overlay.AbsolutePosition

    local appLeft = appPos.X - overlayPos.X + 8
    local appRight = appPos.X - overlayPos.X + appSize.X - 8
    local appTop = appPos.Y - overlayPos.Y + 8
    local appBottom = appPos.Y - overlayPos.Y + appSize.Y - 8

    local left = anchorPos.X - overlayPos.X
    local right = left + anchorSize.X
    local top = anchorPos.Y - overlayPos.Y

    local x
    if preferRight then
        x = right + 6
        if x + width > appRight then
            x = left - width - 6
        end
    else
        x = left - width - 6
        if x < appLeft then
            x = right + 6
        end
    end

    x = math.clamp(x, appLeft, math.max(appLeft, appRight - width))
    local y = math.clamp(top - 4, appTop, math.max(appTop, appBottom - height))

    return UDim2.fromOffset(math.floor(x), math.floor(y))
end

local function popupPositionOutsideChain(anchorButton, width, height)
    local appPos = App.AbsolutePosition
    local appSize = App.AbsoluteSize
    local overlayPos = Overlay.AbsolutePosition
    local anchorPos = anchorButton.AbsolutePosition
    local anchorSize = anchorButton.AbsoluteSize

    local appLeft = appPos.X - overlayPos.X + 8
    local appRight = appPos.X - overlayPos.X + appSize.X - 8
    local appTop = appPos.Y - overlayPos.Y + 8
    local appBottom = appPos.Y - overlayPos.Y + appSize.Y - 8

    local chainLeft = anchorPos.X - overlayPos.X
    local chainRight = chainLeft + anchorSize.X

    for _, popup in ipairs({activePopup, activeSubmenu}) do
        if popup and popup.Parent then
            local p = popup.AbsolutePosition
            local s = popup.AbsoluteSize
            local left = p.X - overlayPos.X
            local right = left + s.X
            chainLeft = math.min(chainLeft, left)
            chainRight = math.max(chainRight, right)
        end
    end

    local gap = 6
    local rightCandidate = chainRight + gap
    local leftCandidate = chainLeft - width - gap

    local rightFits = rightCandidate + width <= appRight
    local leftFits = leftCandidate >= appLeft

    local anchorCenter = (anchorPos.X - overlayPos.X) + (anchorSize.X * 0.5)
    local screenCenter = (appLeft + appRight) * 0.5

    local preferRight
    if activePopup and activePopup.Parent and activeSubmenu and activeSubmenu.Parent then
        local popupCenter = (activePopup.AbsolutePosition.X - overlayPos.X) + (activePopup.AbsoluteSize.X * 0.5)
        local submenuCenter = (activeSubmenu.AbsolutePosition.X - overlayPos.X) + (activeSubmenu.AbsoluteSize.X * 0.5)

        if math.abs(submenuCenter - popupCenter) > 2 then
            preferRight = submenuCenter < popupCenter
        else
            preferRight = anchorCenter <= screenCenter
        end
    else
        preferRight = anchorCenter <= screenCenter
    end

    local x
    if preferRight and rightFits then
        x = rightCandidate
    elseif (not preferRight) and leftFits then
        x = leftCandidate
    elseif rightFits then
        x = rightCandidate
    elseif leftFits then
        x = leftCandidate
    else
        local rightRoom = appRight - chainRight
        local leftRoom = chainLeft - appLeft
        if rightRoom >= leftRoom then
            x = math.clamp(rightCandidate, appLeft, math.max(appLeft, appRight - width))
        else
            x = math.clamp(leftCandidate, appLeft, math.max(appLeft, appRight - width))
        end
    end

    local anchorTop = anchorPos.Y - overlayPos.Y
    local y = math.clamp(anchorTop - 4, appTop, math.max(appTop, appBottom - height))

    return UDim2.fromOffset(math.floor(x), math.floor(y))
end

local function popupPositionNextTo(referenceFrame, width, height, preferRight)
    local appPos = App.AbsolutePosition
    local appSize = App.AbsoluteSize
    local overlayPos = Overlay.AbsolutePosition
    local refPos = referenceFrame.AbsolutePosition
    local refSize = referenceFrame.AbsoluteSize

    local appLeft = appPos.X - overlayPos.X + 8
    local appRight = appPos.X - overlayPos.X + appSize.X - 8
    local appTop = appPos.Y - overlayPos.Y + 8
    local appBottom = appPos.Y - overlayPos.Y + appSize.Y - 8

    local left = refPos.X - overlayPos.X
    local right = left + refSize.X
    local top = refPos.Y - overlayPos.Y

    local gap = 6
    local rightCandidate = right + gap
    local leftCandidate = left - width - gap

    local x
    if preferRight then
        x = rightCandidate
        if x + width > appRight then
            x = leftCandidate
        end
    else
        x = leftCandidate
        if x < appLeft then
            x = rightCandidate
        end
    end

    x = math.clamp(x, appLeft, math.max(appLeft, appRight - width))
    local y = math.clamp(top, appTop, math.max(appTop, appBottom - height))

    return UDim2.fromOffset(math.floor(x), math.floor(y))
end

local function makeDots(parent, x, y, onClick)
    local button = new("TextButton", {
        Position = UDim2.fromOffset(x, y),
        Size = UDim2.fromOffset(28, 18),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = "· · ·",
        Font = UI_FONT_BOLD,
        TextSize = 14,
        AutoButtonColor = false,
        ZIndex = 12,
    }, parent)
    themeObject(button, "TextColor3", "muted")

    button.MouseEnter:Connect(function()
        tween(button, 0.10, {TextColor3 = THEMES[activeThemeName].text})
    end)
    button.MouseLeave:Connect(function()
        tween(button, 0.10, {TextColor3 = THEMES[activeThemeName].muted})
    end)
    button.MouseButton1Click:Connect(function()
        onClick(button)
    end)

    return button
end

local function makeRow(parent, y, textValue, disabled)
    local row = new("Frame", {
        Position = UDim2.fromOffset(0, y),
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, parent)

    local title = label(row, {
        Position = UDim2.fromOffset(10, 0),
        Size = UDim2.new(1, -78, 1, 0),
        Text = textValue,
        TextSize = 13,
        Font = UI_FONT_MEDIUM,
    })

    if disabled then
        themeObject(title, "TextColor3", "dim")
    else
        themeObject(title, "TextColor3", "label")
    end

    return row, title
end

local function makePremiumSlider(parent, y, titleText, valueText, alpha, sliderOptions)
    sliderOptions = sliderOptions or {}
    local minimum = tonumber(sliderOptions.Minimum) or 0
    local maximum = tonumber(sliderOptions.Maximum) or 100
    local suffix = sliderOptions.Suffix or ""
    local decimals = math.max(0, tonumber(sliderOptions.Decimals) or 0)
    local onChanged = sliderOptions.Callback

    if sliderOptions.Default ~= nil and maximum ~= minimum then
        alpha = math.clamp((tonumber(sliderOptions.Default) - minimum) / (maximum - minimum), 0, 1)
    end
    local holder = new("Frame", {
        Position = UDim2.fromOffset(0, y),
        Size = UDim2.new(1, 0, 0, 52),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, parent)

    local title = label(holder, {
        Position = UDim2.fromOffset(10, 3),
        Size = UDim2.new(1, -92, 0, 18),
        Text = titleText,
        TextSize = 12,
        Font = UI_FONT_MEDIUM,
    })
    themeObject(title, "TextColor3", "label")

    local value = label(holder, {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -10, 0, 3),
        Size = UDim2.fromOffset(78, 18),
        Text = valueText,
        Font = SLIDER_FONT,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Right,
    })
    themeObject(value, "TextColor3", "muted")

    local track = new("Frame", {
        Position = UDim2.fromOffset(18, 31),
        Size = UDim2.new(1, -36, 0, 5),
        BorderSizePixel = 0,
        ZIndex = 4,
    }, holder)
    round(track, 999)
    themeObject(track, "BackgroundColor3", "track")

    local fill = new("Frame", {
        Size = UDim2.new(alpha or 0.5, 0, 1, 0),
        BackgroundColor3 = Accent,
        BorderSizePixel = 0,
        ZIndex = 5,
    }, track)
    round(fill, 999)
    accentObject(fill, "BackgroundColor3")

    local shadow = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(alpha or 0.5, 0, 0.5, 1),
        Size = UDim2.fromOffset(14, 14),
        BackgroundTransparency = 0.84,
        BorderSizePixel = 0,
        ZIndex = 5,
    }, track)
    round(shadow, 999)
    themeObject(shadow, "BackgroundColor3", "shadow")

    local knob = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(alpha or 0.5, 0, 0.5, 0),
        Size = UDim2.fromOffset(11, 11),
        BorderSizePixel = 0,
        ZIndex = 7,
    }, track)
    round(knob, 999)
    themeObject(knob, "BackgroundColor3", "knob")
    local ks = stroke(knob, THEMES[activeThemeName].knobStroke, 1, 0)
    themeObject(ks, "Color", "knobStroke")

    local hit = new("TextButton", {
        Position = UDim2.fromOffset(-4, -7),
        Size = UDim2.new(1, 8, 0, 19),
        BackgroundTransparency = 1,
        Text = "",
        BorderSizePixel = 0,
        AutoButtonColor = false,
        ZIndex = 8,
    }, track)

    local dragging = false

    local function numberFromAlpha(a)
        return minimum + ((maximum - minimum) * a)
    end

    local function formatValue(a)
        if sliderOptions.LibraryControl then
            local number = numberFromAlpha(a)
            if decimals == 0 then
                return tostring(math.floor(number + 0.5)) .. suffix
            end
            return string.format("%." .. decimals .. "f", number) .. suffix
        end
        if tostring(valueText or ""):find("↔") then
            return valueText
        elseif tostring(valueText or ""):find("°") then
            local deg = math.floor(a * 1000 + 0.5)
            return tostring(deg) .. "°"
        elseif tostring(valueText or ""):find("%%") then
            return tostring(math.floor(a * 100 + 0.5)) .. "%"
        elseif tostring(valueText or ""):find("%.") then
            return string.format("%.2f", a * 5)
        else
            return string.format("%.1f", a * 100)
        end
    end

    local function setFromAlpha(a, emit)
        a = math.clamp(a, 0, 1)
        fill.Size = UDim2.new(a, 0, 1, 0)
        knob.Position = UDim2.new(a, 0, 0.5, 0)
        shadow.Position = UDim2.new(a, 0, 0.5, 1)
        value.Text = formatValue(a)
        if emit and onChanged then
            task.spawn(onChanged, numberFromAlpha(a))
        end
    end

    local function setFromX(x)
        local a = math.clamp((x - track.AbsolutePosition.X) / math.max(1, track.AbsoluteSize.X), 0, 1)
        setFromAlpha(a, true)
    end

    setFromAlpha(alpha or 0.5, false)

    hit.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            setFromX(input.Position.X)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            setFromX(input.Position.X)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    return {
        Instance = holder,
        Set = function(_, newValue, silent)
            local nextAlpha = maximum == minimum
                and 0
                or math.clamp((tonumber(newValue) - minimum) / (maximum - minimum), 0, 1)
            setFromAlpha(nextAlpha, silent ~= true)
        end,
        Get = function()
            return numberFromAlpha(fill.Size.X.Scale)
        end,
        SetVisible = function(_, visible)
            holder.Visible = visible ~= false
        end,
    }
end

local function openDropdown(anchorButton, arrow, values, onSelected)
    if activeDropdown and activeDropdownButton == anchorButton then
        closeDropdown()
        return false
    end

    closeDropdown()

    local width = anchorButton.AbsoluteSize.X
    local fieldHeight = anchorButton.AbsoluteSize.Y
    local optionHeight = 24
    local contentHeight = fieldHeight + (#values * optionHeight) + 6
    local overlayPos = Overlay.AbsolutePosition
    local p = anchorButton.AbsolutePosition

    local zBase = 1300
    if activeSubmenu and anchorButton:IsDescendantOf(activeSubmenu) then
        zBase = 1450
    elseif activePopup and anchorButton:IsDescendantOf(activePopup) then
        zBase = 1360
    end

    local menu = new("Frame", {
        Size = UDim2.fromOffset(width, fieldHeight),
        BackgroundColor3 = THEMES[activeThemeName].field,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Active = true,
        ZIndex = zBase,
    }, Overlay)
    round(menu, 8)
    local menuStroke = stroke(menu, THEMES[activeThemeName].stroke, 1, 0.15)
    themeObject(menuStroke, "Color", "stroke")
    capturePopupSurface(menu, zBase)

    menu.Position = UDim2.fromOffset(
        p.X - overlayPos.X,
        p.Y - overlayPos.Y
    )

    local currentText = anchorButton:GetAttribute("SelectedValue") or values[1] or "Untitled"
    for _, child in ipairs(anchorButton:GetChildren()) do
        if child:IsA("TextLabel") then
            currentText = child.Text
            break
        end
    end

    local topField = new("TextButton", {
        Size = UDim2.new(1, 0, 0, fieldHeight),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        ZIndex = zBase + 1,
    }, menu)
    topField.MouseButton1Click:Connect(function()
        closeDropdown()
    end)

    local topValue = label(topField, {
        Position = UDim2.fromOffset(9, 0),
        Size = UDim2.new(1, -32, 1, 0),
        Text = currentText,
        TextSize = 11,
        Font = UI_FONT_MEDIUM,
        ZIndex = zBase + 2,
    })
    themeObject(topValue, "TextColor3", "label")

    local topArrow = new("ImageLabel", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(1, -14, 0.5, 0),
        Size = UDim2.fromOffset(12, 12),
        BackgroundTransparency = 1,
        Image = resolveHostedIcon("Chevron"),
        Rotation = 180,
        ScaleType = Enum.ScaleType.Fit,
        ZIndex = zBase + 2,
    }, topField)
    themeObject(topArrow, "ImageColor3", "icon")

    for index, item in ipairs(values) do
        local isSelected = item == currentText
        local option = new("TextButton", {
            Position = UDim2.fromOffset(0, fieldHeight + ((index - 1) * optionHeight)),
            Size = UDim2.new(1, 0, 0, optionHeight),
            BackgroundTransparency = isSelected and 0 or 1,
            BackgroundColor3 = THEMES[activeThemeName].fieldHover,
            BorderSizePixel = 0,
            Text = item,
            Font = UI_FONT_MEDIUM,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            AutoButtonColor = false,
            ZIndex = zBase + 1,
        }, menu)
        new("UIPadding", {PaddingLeft = UDim.new(0, 10)}, option)
        option.TextColor3 = THEMES[activeThemeName].label

        option.MouseEnter:Connect(function()
            tween(option, 0.08, {
                BackgroundTransparency = 0,
                BackgroundColor3 = THEMES[activeThemeName].fieldHover,
            })
        end)

        option.MouseLeave:Connect(function()
            local selected = item == (anchorButton:GetAttribute("SelectedValue") or currentText)
            tween(option, 0.08, {
                BackgroundTransparency = selected and 0 or 1,
                BackgroundColor3 = THEMES[activeThemeName].fieldHover,
            })
        end)

        option.MouseButton1Click:Connect(function()
            currentText = item
            anchorButton:SetAttribute("SelectedValue", item)
            for _, child in ipairs(anchorButton:GetChildren()) do
                if child:IsA("TextLabel") then
                    child.Text = item
                    break
                end
            end
            if onSelected then
                onSelected(item)
            end
            closeDropdown()
        end)
    end

    activeDropdown = menu
    activeDropdownButton = anchorButton
    activeDropdownArrow = arrow

    if arrow and arrow.Parent then
        tween(arrow, 0.12, {Rotation = 180})
    end

    tween(menu, 0.12, {Size = UDim2.fromOffset(width, contentHeight)})
    return true
end

local function makeDropdown(parent, y, titleText, valueText, values, onSelected)
    local holder = new("Frame", {
        Position = UDim2.fromOffset(0, y),
        Size = UDim2.new(1, 0, 0, 57),
        BackgroundTransparency = 1,
    }, parent)

    local title = label(holder, {
        Position = UDim2.fromOffset(10, 2),
        Size = UDim2.new(1, -20, 0, 18),
        Text = titleText,
        TextSize = 11,
    })
    themeObject(title, "TextColor3", "label")

    local field = new("TextButton", {
        Position = UDim2.fromOffset(8, 25),
        Size = UDim2.new(1, -16, 0, 27),
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 6,
    }, holder)
    round(field, 8)
    themeObject(field, "BackgroundColor3", "field")
    local fs = stroke(field, THEMES[activeThemeName].stroke, 1, 0.15)
    themeObject(fs, "Color", "stroke")

    field:SetAttribute("SelectedValue", valueText)

    local value = label(field, {
        Position = UDim2.fromOffset(9, 0),
        Size = UDim2.new(1, -32, 1, 0),
        Text = valueText,
        TextSize = 11,
        Font = UI_FONT_MEDIUM,
        ZIndex = 7,
    })
    themeObject(value, "TextColor3", "label")

    local arrow = new("ImageLabel", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(1, -14, 0.5, 0),
        Size = UDim2.fromOffset(12, 12),
        BackgroundTransparency = 1,
        Image = resolveHostedIcon("Chevron"),
        Rotation = 0,
        ScaleType = Enum.ScaleType.Fit,
        ZIndex = 7,
    }, field)
    themeObject(arrow, "ImageColor3", "icon")

    field.MouseEnter:Connect(function()
        tween(field, 0.08, {BackgroundColor3 = THEMES[activeThemeName].fieldHover})
    end)
    field.MouseLeave:Connect(function()
        tween(field, 0.08, {BackgroundColor3 = THEMES[activeThemeName].field})
    end)

    field.MouseButton1Click:Connect(function()
        openDropdown(field, arrow, values or {"Untitled", "Untitled 02", "Untitled 03"}, onSelected)
    end)

    return {
        Instance = holder,
        Set = function(_, selected, silent)
            selected = tostring(selected)
            field:SetAttribute("SelectedValue", selected)
            value.Text = selected
            if silent ~= true and onSelected then
                task.spawn(onSelected, selected)
            end
        end,
        Get = function()
            return field:GetAttribute("SelectedValue")
        end,
        SetVisible = function(_, visible)
            holder.Visible = visible ~= false
        end,
    }
end

local function addToggleRow(panel, y, textValue, withDots, onDots, initialState, isLast, onChanged)
    local row = makeRow(panel, y, textValue, false)
    local control

    if withDots then
        makeDots(row, 199, 9, onDots)
        control = makeToggle(row, 233, 9, initialState == nil and true or initialState, onChanged)
    else
        control = makeToggle(row, 233, 9, initialState == true, onChanged)
    end

    if not isLast then
        separator(panel, y + 35)
    end

    return control
end

local function openColorPicker(anchorButton)
    if activeColorPicker and activeColorPickerButton == anchorButton then
        closeColorPicker()
        return
    end

    closeColorPicker()

    local width = 196
    local height = 282
    local picker = new("Frame", {
        Size = UDim2.fromOffset(width, 0),
        BackgroundColor3 = THEMES[activeThemeName].popup,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Active = true,
        ZIndex = 1500,
    }, Overlay)
    round(picker, 11)
    stroke(picker, THEMES[activeThemeName].strokeStrong, 1, 0.05)
    capturePopupSurface(picker, 1500)

    if activeSubmenu and activeSubmenu.Parent then
        local preferRight = activeSubmenu.AbsolutePosition.X < (App.AbsolutePosition.X + App.AbsoluteSize.X * 0.5)
        picker.Position = popupPositionNextTo(activeSubmenu, width, height, preferRight)
    elseif activePopup and activePopup.Parent then
        local preferRight = activePopup.AbsolutePosition.X < (App.AbsolutePosition.X + App.AbsoluteSize.X * 0.5)
        picker.Position = popupPositionNextTo(activePopup, width, height, preferRight)
    else
        picker.Position = popupPositionOutsideChain(anchorButton, width, height)
    end

    local title = label(picker, {
        Position = UDim2.fromOffset(10, 5),
        Size = UDim2.fromOffset(90, 18),
        Text = "Color",
        TextSize = 10,
        ZIndex = 1501,
    })
    title.TextColor3 = THEMES[activeThemeName].label

    local x = new("TextButton", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -6, 0, 3),
        Size = UDim2.fromOffset(20, 20),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = "×",
        Font = UI_FONT_MEDIUM,
        TextSize = 14,
        AutoButtonColor = false,
        ZIndex = 1502,
    }, picker)
    x.TextColor3 = THEMES[activeThemeName].muted
    x.MouseButton1Click:Connect(closeColorPicker)

    local wheelImage = resolveColorWheelAsset()
    local wheel = new("ImageLabel", {
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 28),
        Size = UDim2.fromOffset(130, 130),
        BackgroundTransparency = wheelImage and 1 or 0,
        BackgroundColor3 = Accent,
        BorderSizePixel = 0,
        Image = wheelImage or "",
        ScaleType = Enum.ScaleType.Fit,
        ZIndex = 1501,
    }, picker)
    round(wheel, 999)

    local selector = new("Frame", {
        Position = UDim2.fromOffset(56, 44),
        Size = UDim2.fromOffset(12, 12),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        ZIndex = 1503,
    }, picker)
    round(selector, 999)
    stroke(selector, Color3.fromRGB(90, 94, 102), 1, 0)

    local function colorBar(y, gradientColors)
        local bar = new("Frame", {
            Position = UDim2.fromOffset(13, y),
            Size = UDim2.fromOffset(width - 26, 7),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BorderSizePixel = 0,
            ZIndex = 1501,
        }, picker)
        round(bar, 999)
        new("UIGradient", {Color = gradientColors}, bar)

        local thumb = new("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.82, 0, 0.5, 0),
            Size = UDim2.fromOffset(10, 14),
            BackgroundColor3 = Color3.fromRGB(15, 15, 17),
            BorderSizePixel = 0,
            ZIndex = 1503,
        }, bar)
        round(thumb, 999)
        stroke(thumb, Color3.fromRGB(255, 255, 255), 1, 0.05)
    end

    colorBar(171, ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
        ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
        ColorSequenceKeypoint.new(0.34, Color3.fromRGB(0, 255, 0)),
        ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 255, 255)),
        ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
        ColorSequenceKeypoint.new(0.84, Color3.fromRGB(255, 0, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
    }))
    colorBar(189, ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, Accent),
    }))
    colorBar(207, ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
        ColorSequenceKeypoint.new(1, Accent),
    }))

    local hex = new("TextBox", {
        Position = UDim2.fromOffset(10, 230),
        Size = UDim2.fromOffset(105, 27),
        BackgroundColor3 = THEMES[activeThemeName].field,
        BorderSizePixel = 0,
        Text = "#9496FF",
        ClearTextOnFocus = false,
        Font = UI_FONT_MEDIUM,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 1501,
    }, picker)
    round(hex, 7)
    new("UIPadding", {PaddingLeft = UDim.new(0, 8)}, hex)
    hex.TextColor3 = THEMES[activeThemeName].text

    local apply = new("TextButton", {
        Position = UDim2.fromOffset(121, 230),
        Size = UDim2.fromOffset(65, 27),
        BackgroundColor3 = Accent,
        BorderSizePixel = 0,
        Text = "Apply",
        TextColor3 = Color3.fromRGB(255,255,255),
        Font = UI_FONT_MEDIUM,
        TextSize = 10,
        AutoButtonColor = false,
        ZIndex = 1501,
    }, picker)
    round(apply, 7)
    apply.MouseEnter:Connect(function()
        tween(apply, 0.08, {BackgroundColor3 = Accent:Lerp(Color3.new(1,1,1), 0.10)})
    end)
    apply.MouseLeave:Connect(function()
        tween(apply, 0.08, {BackgroundColor3 = Accent})
    end)

    activeColorPicker = picker
    activeColorPickerButton = anchorButton
    tween(picker, 0.13, {Size = UDim2.fromOffset(width, height)})
end

local function openSecondLevel(anchorRow)
    if activeSubmenu and activeSubmenuButton == anchorRow then
        closeSubmenu()
        return
    end

    closeSubmenu()

    local width = 176
    local height = 182

    local menu = new("Frame", {
        Size = UDim2.fromOffset(width, 0),
        BackgroundColor3 = THEMES[activeThemeName].popup,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Active = true,
        ZIndex = 1400,
    }, Overlay)
    round(menu, 10)
    stroke(menu, THEMES[activeThemeName].strokeStrong, 1, 0.05)
    capturePopupSurface(menu, 1400)

    if activePopup and activePopup.Parent then
        local preferRight = activePopup.AbsolutePosition.X < (App.AbsolutePosition.X + App.AbsoluteSize.X * 0.5)
        menu.Position = popupPositionNextTo(activePopup, width, height, preferRight)
    else
        menu.Position = popupPositionOutsideChain(anchorRow, width, height)
    end

    local title = label(menu, {
        Position = UDim2.fromOffset(10, 5),
        Size = UDim2.new(1, -20, 0, 18),
        Text = "Untitled",
        TextSize = 10,
        Font = UI_FONT_MEDIUM,
        ZIndex = 1401,
    })
    title.TextColor3 = THEMES[activeThemeName].label

    local dropdownHolder = makeDropdown(menu, 26, "Untitled", anchorRow:GetAttribute("SecondLevelDropdownValue") or "Untitled", {"Untitled", "Untitled 02", "Untitled 03"}, function(selected) anchorRow:SetAttribute("SecondLevelDropdownValue", selected) end)
    dropdownHolder.Size = UDim2.new(1, -20, 0, 57)
    dropdownHolder.Position = UDim2.fromOffset(10, 26)

    local r2 = makeRow(menu, 88, "Untitled", false)
    makeToggle(r2, 150, 9, true)

    makePremiumSlider(menu, 123, "Untitled", "50%", 0.58)

    local colorRow = makeRow(menu, 175, "Untitled", false)
    local swatchButton = new("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -9, 0.5, 0),
        Size = UDim2.fromOffset(44, 20),
        BackgroundColor3 = THEMES[activeThemeName].field,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 1403,
    }, colorRow)
    round(swatchButton, 7)
    local swatch = new("Frame", {
        Position = UDim2.fromOffset(4, 4),
        Size = UDim2.fromOffset(36, 12),
        BackgroundColor3 = Accent,
        BorderSizePixel = 0,
        ZIndex = 1404,
    }, swatchButton)
    round(swatch, 5)
    swatchButton.MouseButton1Click:Connect(function()
        openColorPicker(swatchButton)
    end)

    for _, obj in ipairs(menu:GetDescendants()) do
        if obj:IsA("GuiObject") and obj ~= menu and obj.ZIndex < 1400 then
            obj.ZIndex = obj.ZIndex + 1400
        end
    end

    activeSubmenu = menu
    activeSubmenuButton = anchorRow
    tween(menu, 0.12, {Size = UDim2.fromOffset(width, height)})
end

local function openThreeDotMenu(anchorButton)
    if activePopup and activePopupButton == anchorButton then
        closePopup()
        return
    end

    closePopup()
    activePopupButton = anchorButton

    local width = 176
    local height = 182

    local menu = new("Frame", {
        Size = UDim2.fromOffset(width, 0),
        BackgroundColor3 = THEMES[activeThemeName].popup,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Active = true,
        ZIndex = 1350,
    }, Overlay)
    round(menu, 10)
    stroke(menu, THEMES[activeThemeName].strokeStrong, 1, 0.05)
    capturePopupSurface(menu, 1350)
    menu.Position = popupPositionBeside(anchorButton, width, height, false)

    local names = {"Untitled 01","Untitled 02","Untitled 03","Untitled 04","Untitled 05"}
    local selectedIndex = anchorButton:GetAttribute("PopupSelectedIndex") or 0
    local rows = {}

    local function refreshRows(hoverRow)
        for i, row in ipairs(rows) do
            local selected = (i == selectedIndex)
            if row ~= hoverRow then
                row.BackgroundTransparency = selected and 0 or 1
                row.BackgroundColor3 = selected and THEMES[activeThemeName].fieldHover or THEMES[activeThemeName].field
            end
        end
    end

    for index, itemText in ipairs(names) do
        local row = new("TextButton", {
            Position = UDim2.fromOffset(5, 5 + (index - 1) * 34),
            Size = UDim2.new(1, -10, 0, 31),
            BackgroundTransparency = index == selectedIndex and 0 or 1,
            BackgroundColor3 = index == selectedIndex and THEMES[activeThemeName].fieldHover or THEMES[activeThemeName].field,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
            ZIndex = 1351,
        }, menu)
        round(row, 7)
        rows[index] = row

        local rowLabel = label(row, {
            Position = UDim2.fromOffset(10, 0),
            Size = UDim2.new(1, -36, 1, 0),
            Text = itemText,
            TextSize = 10,
            ZIndex = 1352,
        })
        rowLabel.TextColor3 = THEMES[activeThemeName].label

        local arrow = new("ImageLabel", {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -8, 0.5, 0),
            Size = UDim2.fromOffset(11, 11),
            BackgroundTransparency = 1,
            Image = resolveHostedIcon("Chevron"),
            Rotation = 270,
            ScaleType = Enum.ScaleType.Fit,
            ZIndex = 1352,
        }, row)
        arrow.ImageColor3 = THEMES[activeThemeName].icon

        row.MouseEnter:Connect(function()
            tween(row, 0.08, {
                BackgroundTransparency = 0,
                BackgroundColor3 = THEMES[activeThemeName].fieldHover,
            })
        end)
        row.MouseLeave:Connect(function()
            local selected = (index == selectedIndex)
            tween(row, 0.08, {
                BackgroundTransparency = selected and 0 or 1,
                BackgroundColor3 = selected and THEMES[activeThemeName].fieldHover or THEMES[activeThemeName].field,
            })
        end)

        row.MouseButton1Click:Connect(function()
            selectedIndex = index
            anchorButton:SetAttribute("PopupSelectedIndex", index)
            refreshRows()
            openSecondLevel(row)
        end)
    end

    activePopup = menu
    tween(menu, 0.12, {Size = UDim2.fromOffset(width, height)})
end


local PageFrames = {}

local function createPageFrame(pageName)
    local frame = new("Frame", {
        Name = pageName .. "Page",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Visible = false,
    }, Content)
    PageFrames[pageName] = frame
    return frame
end

local PageBuilders = {}
local SectionBuilder = {}
SectionBuilder.__index = SectionBuilder

local function resizeSection(section)
    local height = math.max(1, section.ContentHeight)
    section.Frame.Size = UDim2.fromOffset(258, height)
    section.Shadow.Size = UDim2.fromOffset(258, height)

    local layout = section.Page.Layout
    layout[section.Side] = math.max(layout[section.Side], section.Y + height + 10)
end

local function reserveSectionSpace(section, height)
    local y = section.ContentHeight
    if y > 0 then
        separator(section.Frame, y - 1)
    end
    section.ContentHeight += height
    resizeSection(section)
    return y
end

function SectionBuilder:Toggle(options)
    options = options or {}
    local y = reserveSectionSpace(self, 36)
    return addToggleRow(
        self.Frame,
        y,
        options.Name or "Toggle",
        options.Advanced == true,
        options.Advanced == true and openThreeDotMenu or nil,
        options.Default == true,
        true,
        options.Callback
    )
end

function SectionBuilder:Dropdown(options)
    options = options or {}
    local values = options.Options or {"Option 1", "Option 2"}
    local default = options.Default or values[1] or "None"
    local y = reserveSectionSpace(self, 58)
    return makeDropdown(
        self.Frame,
        y,
        options.Name or "Dropdown",
        tostring(default),
        values,
        options.Callback
    )
end

function SectionBuilder:Slider(options)
    options = options or {}
    local minimum = tonumber(options.Minimum) or 0
    local maximum = tonumber(options.Maximum) or 100
    local default = tonumber(options.Default) or minimum
    local alpha = maximum == minimum and 0 or math.clamp((default - minimum) / (maximum - minimum), 0, 1)
    local suffix = options.Suffix or ""
    local decimals = math.max(0, tonumber(options.Decimals) or 0)
    local shown = decimals == 0
        and tostring(math.floor(default + 0.5)) .. suffix
        or string.format("%." .. decimals .. "f", default) .. suffix
    local y = reserveSectionSpace(self, 52)

    return makePremiumSlider(self.Frame, y, options.Name or "Slider", shown, alpha, {
        LibraryControl = true,
        Minimum = minimum,
        Maximum = maximum,
        Default = default,
        Suffix = suffix,
        Decimals = decimals,
        Callback = options.Callback,
    })
end

for _, pageName in ipairs(pageOrder) do
    PageBuilders[pageName] = {
        Name = pageName,
        Frame = createPageFrame(pageName),
        Layout = {
            Left = 0,
            Right = 0,
        },
    }
end

for _, page in pairs(PageBuilders) do
    function page:Section(options)
        options = options or {}
        local side = options.Side == "Right" and "Right" or "Left"
        local x = side == "Right" and 270 or 0
        local y = self.Layout[side]
        local panel, shadow = makeSection(options.Name or "Section", x, y, 258, 1, self.Frame)
        local section = setmetatable({
            Page = self,
            Side = side,
            Y = y,
            Frame = panel,
            Shadow = shadow,
            ContentHeight = 0,
        }, SectionBuilder)
        return section
    end
end

local SettingsPopup
local SettingsPopupOpen = false

local function closeSettingsPopup()
    if SettingsPopup then
        SettingsPopup:Destroy()
        SettingsPopup = nil
    end
    SettingsPopupOpen = false
end

local function refreshTheme()
    local theme = THEMES[activeThemeName]

    App.BackgroundColor3 = theme.shell
    AppStroke.Color = theme.strokeStrong

    for _, item in ipairs(themed) do
        if item.object and item.object.Parent then
            item.object[item.property] = theme[item.key]
        end
    end

    for _, item in ipairs(accentObjects) do
        if item.object and item.object.Parent then
            item.object[item.property] = Accent
        end
    end

    for pageName, info in pairs(navButtons) do
        local active = pageName == activePage
        info.icon.ImageColor3 = active and theme.iconActive or theme.icon
        info.label.TextColor3 = active and theme.text or theme.muted
        info.button.BackgroundColor3 = active and theme.field or theme.surface
        info.button.BackgroundTransparency = active and 0 or 1
    end

    SearchIcon.ImageColor3 = theme.iconHover
    SearchIcon.ImageTransparency = 0
    SettingsButton.ImageColor3 = theme.icon
end

local themeTransitionBusy = false

local function tweenThemeVisuals(themeName, duration, includeShell)
    local target = THEMES[themeName]
    local info = TweenInfo.new(
        duration or 0.24,
        Enum.EasingStyle.Quad,
        Enum.EasingDirection.Out
    )

    local tweens = {}

    local function addTween(object, properties)
        if object and object.Parent then
            local animation = TweenService:Create(object, info, properties)
            table.insert(tweens, animation)
            animation:Play()
        end
    end

    if includeShell ~= false then
        addTween(App, {
            BackgroundColor3 = target.shell,
        })

        addTween(AppStroke, {
            Color = target.strokeStrong,
        })
    end

    for _, item in ipairs(themed) do
        if item.object and item.object.Parent then
            local targetValue = target[item.key]
            if targetValue ~= nil then
                addTween(item.object, {
                    [item.property] = targetValue,
                })
            end
        end
    end

    for pageName, nav in pairs(navButtons) do
        local active = pageName == activePage

        addTween(nav.icon, {
            ImageColor3 = active and target.iconActive or target.icon,
        })

        addTween(nav.label, {
            TextColor3 = active and target.text or target.muted,
        })

        addTween(nav.button, {
            BackgroundColor3 = active and target.field or target.surface,
        })
    end

    addTween(SearchIcon, {
        ImageColor3 = target.iconHover,
    })

    addTween(SettingsButton, {
        ImageColor3 = target.icon,
    })

    return tweens
end

local function animateThemeTransition(themeName, originAbsolutePosition, onFinished)
    if themeName == activeThemeName or themeTransitionBusy then
        if onFinished then
            onFinished()
        end
        return
    end

    themeTransitionBusy = true

    local previousThemeName = activeThemeName
    local darkFamilyTransition =
        (previousThemeName == "Dark" or previousThemeName == "Black")
        and (themeName == "Dark" or themeName == "Black")

    local transitionBlock = new("TextButton", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        Active = true,
        ZIndex = 9998,
    }, App)

    if darkFamilyTransition then
        -- Dark <-> Black is intentionally a straight color fade rather than
        -- the circular wipe. It feels more like the two dark themes are
        -- blending into one another instead of switching modes.
        local visualTweens = tweenThemeVisuals(themeName, 0.28, true)
        local completionTween = visualTweens[1]

        if completionTween then
            completionTween.Completed:Connect(function()
                activeThemeName = themeName
                refreshTheme()

                if onFinished then
                    onFinished()
                end

                if transitionBlock then
                    transitionBlock:Destroy()
                end

                themeTransitionBusy = false
            end)
        else
            activeThemeName = themeName
            refreshTheme()

            if onFinished then
                onFinished()
            end

            if transitionBlock then
                transitionBlock:Destroy()
            end

            themeTransitionBusy = false
        end

        return
    end

    -- Light <-> Dark/Black keeps the radial wipe, but the wipe now sits much
    -- lower in the UI stack while the actual controls tween to their target
    -- colors at the same time. This avoids the old "dark sheet over the UI"
    -- appearance and keeps toggles/buttons readable during the transition.
    local appPosition = App.AbsolutePosition
    local appSize = App.AbsoluteSize
    local origin = originAbsolutePosition or (appPosition + appSize * 0.5)
    local localOrigin = origin - appPosition

    local corners = {
        Vector2.new(0, 0),
        Vector2.new(appSize.X, 0),
        Vector2.new(0, appSize.Y),
        Vector2.new(appSize.X, appSize.Y),
    }

    local maxDistance = 0
    for _, corner in ipairs(corners) do
        maxDistance = math.max(maxDistance, (corner - localOrigin).Magnitude)
    end

    -- Oversize the circle so the edge is already well beyond every rounded
    -- corner before we finish the theme swap.
    local finalDiameter = math.ceil(maxDistance * 2 + 48)

    -- Lift every existing visual above the radial layer temporarily.
    -- This keeps the logo, search bar, text, toggles, sliders, panels, etc.
    -- fully visible while only their colors transition.
    local liftedZ = {}

    for _, object in ipairs(App:GetDescendants()) do
        if object:IsA("GuiObject") then
            liftedZ[object] = object.ZIndex
            object.ZIndex = object.ZIndex + 100
        end
    end

    transitionBlock.ZIndex = 20000

    -- Build the radial wipe from thin horizontal slices instead of one giant
    -- child circle. Roblox ClipsDescendants clips children to a rectangle,
    -- not to the App's UICorner, which is what caused the square corner flash.
    -- Each slice is manually constrained to the 15px rounded shell shape, so
    -- the wipe can reach the edges without ever drawing into square corners.
    local shellRadius = 15
    local bandHeight = 3
    local slices = {}

    local function roundedHorizontalBounds(yCenter)
        local inset = 0

        if yCenter < shellRadius then
            local dy = shellRadius - yCenter
            inset = shellRadius - math.sqrt(
                math.max(0, shellRadius * shellRadius - dy * dy)
            )
        elseif yCenter > appSize.Y - shellRadius then
            local dy = yCenter - (appSize.Y - shellRadius)
            inset = shellRadius - math.sqrt(
                math.max(0, shellRadius * shellRadius - dy * dy)
            )
        end

        return inset, appSize.X - inset
    end

    local y = 0
    while y < appSize.Y do
        local actualHeight = math.min(bandHeight, appSize.Y - y)
        local yCenter = y + actualHeight * 0.5
        local leftBound, rightBound = roundedHorizontalBounds(yCenter)

        local slice = new("Frame", {
            Position = UDim2.fromOffset(leftBound, y),
            Size = UDim2.fromOffset(0, actualHeight),
            BackgroundColor3 = THEMES[themeName].shell,
            BackgroundTransparency = 0,
            BorderSizePixel = 0,
            ZIndex = 1,
        }, App)

        slices[#slices + 1] = {
            frame = slice,
            yCenter = yCenter,
            leftBound = leftBound,
            rightBound = rightBound,
            height = actualHeight,
            y = y,
        }

        y += actualHeight
    end

    -- All actual controls remain visible and morph their colors while the
    -- sliced radial background travels underneath them.
    tweenThemeVisuals(themeName, 0.27, false)

    local radiusValue = new("NumberValue", {
        Value = 0,
    }, App)

    local function updateSlices(radius)
        local ox = localOrigin.X
        local oy = localOrigin.Y

        for _, data in ipairs(slices) do
            local dy = data.yCenter - oy
            local absDy = math.abs(dy)

            if absDy <= radius then
                local halfWidth = math.sqrt(
                    math.max(0, radius * radius - dy * dy)
                )

                local x1 = math.max(data.leftBound, ox - halfWidth)
                local x2 = math.min(data.rightBound, ox + halfWidth)
                local width = math.max(0, x2 - x1)

                data.frame.Position = UDim2.fromOffset(x1, data.y)
                data.frame.Size = UDim2.fromOffset(width, data.height)
            else
                data.frame.Size = UDim2.fromOffset(0, data.height)
            end
        end
    end

    local radiusConnection = radiusValue.Changed:Connect(updateSlices)
    updateSlices(0)

    local grow = TweenService:Create(
        radiusValue,
        TweenInfo.new(0.36, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        {
            Value = maxDistance + 24,
        }
    )

    grow.Completed:Connect(function()
        activeThemeName = themeName
        refreshTheme()

        if onFinished then
            onFinished()
        end

        if radiusConnection then
            radiusConnection:Disconnect()
        end

        if radiusValue then
            radiusValue:Destroy()
        end

        for _, data in ipairs(slices) do
            if data.frame then
                data.frame:Destroy()
            end
        end

        for object, originalZ in pairs(liftedZ) do
            if object and object.Parent then
                object.ZIndex = originalZ
            end
        end

        if transitionBlock then
            transitionBlock:Destroy()
        end

        themeTransitionBusy = false
    end)

    grow:Play()
end

local function setActivePage(pageName)
    activePage = pageName
    local info = navButtons[pageName]
    if not info then
        return
    end

    for name, frame in pairs(PageFrames) do
        frame.Visible = name == pageName
    end

    local y = Sidebar.Position.Y.Offset + navY + (info.index - 1) * 37 + 7
    tween(ActiveBar, 0.16, {Position = UDim2.fromOffset(3, y)})

    refreshTheme()
end

for pageName, info in pairs(navButtons) do
    info.button.MouseEnter:Connect(function()
        if pageName ~= activePage then
            tween(info.button, 0.08, {
                BackgroundTransparency = 0,
                BackgroundColor3 = THEMES[activeThemeName].fieldHover,
            })
            tween(info.icon, 0.08, {ImageColor3 = THEMES[activeThemeName].iconHover})
            tween(info.label, 0.08, {TextColor3 = THEMES[activeThemeName].label})
        end
    end)

    info.button.MouseLeave:Connect(function()
        if pageName ~= activePage then
            tween(info.button, 0.08, {BackgroundTransparency = 1})
            tween(info.icon, 0.08, {ImageColor3 = THEMES[activeThemeName].icon})
            tween(info.label, 0.08, {TextColor3 = THEMES[activeThemeName].muted})
        end
    end)

    info.button.MouseButton1Click:Connect(function()
        setActivePage(pageName)
    end)
end

local function openSettingsPopup()
    closePopup()
    closeDropdown()
    closeSettingsPopup()

    SettingsPopupOpen = true

    local width = 248
    local height = 176

    local popup = new("Frame", {
        Size = UDim2.fromOffset(width, 0),
        BackgroundColor3 = THEMES[activeThemeName].surface,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Active = true,
        ZIndex = 1600,
    }, Overlay)
    round(popup, 12)
    local popupStroke = stroke(popup, THEMES[activeThemeName].strokeStrong, 1, 0.05)
    themeObject(popup, "BackgroundColor3", "surface")
    themeObject(popupStroke, "Color", "strokeStrong")
    capturePopupSurface(popup, 1600)

    do
        local overlayPos = Overlay.AbsolutePosition
        local buttonPos = SettingsButton.AbsolutePosition
        local buttonSize = SettingsButton.AbsoluteSize
        local appPos = App.AbsolutePosition
        local appSize = App.AbsoluteSize
        local appLeft = appPos.X - overlayPos.X + 8
        local appRight = appPos.X - overlayPos.X + appSize.X - 8
        local appTop = appPos.Y - overlayPos.Y + 8
        local appBottom = appPos.Y - overlayPos.Y + appSize.Y - 8

        local x = math.clamp(
            buttonPos.X - overlayPos.X - 2,
            appLeft,
            math.max(appLeft, appRight - width)
        )
        local y = math.clamp(
            buttonPos.Y - overlayPos.Y + buttonSize.Y + 6,
            appTop,
            math.max(appTop, appBottom - height)
        )

        popup.Position = UDim2.fromOffset(math.floor(x), math.floor(y))
    end

    local title = label(popup, {
        Position = UDim2.fromOffset(11, 6),
        Size = UDim2.fromOffset(130, 19),
        Text = "App settings",
        TextSize = 11,
        Font = UI_FONT_MEDIUM,
        ZIndex = 1601,
    })
    themeObject(title, "TextColor3", "text")

    local close = new("TextButton", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -6, 0, 2),
        Size = UDim2.fromOffset(24, 24),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = "×",
        Font = UI_FONT_MEDIUM,
        TextSize = 19,
        AutoButtonColor = false,
        ZIndex = 1603,
    }, popup)
    themeObject(close, "TextColor3", "muted")
    close.MouseButton1Click:Connect(closeSettingsPopup)

    local segmented = new("Frame", {
        Position = UDim2.fromOffset(11, 32),
        Size = UDim2.new(1, -22, 0, 30),
        BackgroundColor3 = THEMES[activeThemeName].field,
        BorderSizePixel = 0,
        ZIndex = 1601,
    }, popup)
    round(segmented, 999)
    local segmentedStroke = stroke(segmented, THEMES[activeThemeName].stroke, 1, 0.10)
    themeObject(segmented, "BackgroundColor3", "field")
    themeObject(segmentedStroke, "Color", "stroke")

    local themeNames = {"Light", "Dark", "Black"}
    local themeButtons = {}

    local function themeIndex(name)
        for index, value in ipairs(themeNames) do
            if value == name then
                return index
            end
        end
        return 1
    end

    local selectedIndex = themeIndex(activeThemeName)

    local selector = new("Frame", {
        Position = UDim2.new((selectedIndex - 1) / 3, 2, 0, 2),
        Size = UDim2.new(1 / 3, -4, 1, -4),
        BackgroundColor3 = THEMES[activeThemeName].surface,
        BorderSizePixel = 0,
        ZIndex = 1602,
    }, segmented)
    round(selector, 999)
    local selectorStroke = stroke(selector, THEMES[activeThemeName].strokeStrong, 1, 0.02)
    themeObject(selector, "BackgroundColor3", "surface")
    themeObject(selectorStroke, "Color", "strokeStrong")

    local function refreshThemeButtonText()
        for index, button in ipairs(themeButtons) do
            button.TextColor3 =
                index == selectedIndex
                and THEMES[activeThemeName].text
                or THEMES[activeThemeName].label
        end
    end

    for index, themeName in ipairs(themeNames) do
        local button = new("TextButton", {
            Position = UDim2.new((index - 1) / 3, 0, 0, 0),
            Size = UDim2.new(1 / 3, 0, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Text = themeName,
            Font = UI_FONT_MEDIUM,
            TextSize = 10,
            AutoButtonColor = false,
            ZIndex = 1603,
        }, segmented)

        themeButtons[index] = button

        button.MouseEnter:Connect(function()
            if index ~= selectedIndex then
                tween(button, 0.08, {
                    TextColor3 = THEMES[activeThemeName].text,
                })
            end
        end)

        button.MouseLeave:Connect(function()
            if index ~= selectedIndex then
                tween(button, 0.08, {
                    TextColor3 = THEMES[activeThemeName].label,
                })
            end
        end)

        button.MouseButton1Click:Connect(function()
            if index == selectedIndex or themeTransitionBusy then
                return
            end

            selectedIndex = index

            tween(selector, 0.18, {
                Position = UDim2.new((selectedIndex - 1) / 3, 2, 0, 2),
            })

            refreshThemeButtonText()

            local absoluteOrigin =
                segmented.AbsolutePosition
                + Vector2.new(
                    segmented.AbsoluteSize.X * ((index - 0.5) / 3),
                    segmented.AbsoluteSize.Y * 0.5
                )

            animateThemeTransition(themeName, absoluteOrigin, function()
                selector.BackgroundColor3 = THEMES[activeThemeName].surface
                selectorStroke.Color = THEMES[activeThemeName].strokeStrong
                segmented.BackgroundColor3 = THEMES[activeThemeName].field
                segmentedStroke.Color = THEMES[activeThemeName].stroke
                popup.BackgroundColor3 = THEMES[activeThemeName].surface
                popupStroke.Color = THEMES[activeThemeName].strokeStrong
                refreshThemeButtonText()
            end)
        end)
    end

    refreshThemeButtonText()

    local accentLabel = label(popup, {
        Position = UDim2.fromOffset(11, 70),
        Size = UDim2.fromOffset(65, 16),
        Text = "Accent",
        TextSize = 10,
        Font = UI_FONT_MEDIUM,
        ZIndex = 1601,
    })
    themeObject(accentLabel, "TextColor3", "label")

    for index, color in ipairs(ACCENTS) do
        local dot = new("TextButton", {
            Position = UDim2.fromOffset(11 + (index - 1) * 24, 88),
            Size = UDim2.fromOffset(16, 16),
            BackgroundColor3 = color,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
            ZIndex = 1602,
        }, popup)
        round(dot, 999)

        if color == Accent then
            local selectedStroke = stroke(dot, THEMES[activeThemeName].text, 2, 0.03)
            themeObject(selectedStroke, "Color", "text")
        end

        dot.MouseButton1Click:Connect(function()
            Accent = color
            refreshTheme()
            closeSettingsPopup()
            openSettingsPopup()
        end)
    end

    local scaleLabel = label(popup, {
        Position = UDim2.fromOffset(11, 112),
        Size = UDim2.new(1, -22, 0, 16),
        Text = "Interface scale",
        TextSize = 10,
        Font = UI_FONT_MEDIUM,
        ZIndex = 1601,
    })
    themeObject(scaleLabel, "TextColor3", "label")

    local scaleValue = label(popup, {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -11, 0, 112),
        Size = UDim2.fromOffset(55, 16),
        Text = "100%",
        TextSize = 10,
        Font = UI_FONT_MEDIUM,
        TextXAlignment = Enum.TextXAlignment.Right,
        ZIndex = 1601,
    })
    themeObject(scaleValue, "TextColor3", "text")

    local track = new("Frame", {
        Position = UDim2.fromOffset(11, 138),
        Size = UDim2.new(1, -22, 0, 5),
        BackgroundColor3 = THEMES[activeThemeName].track,
        BorderSizePixel = 0,
        ZIndex = 1601,
    }, popup)
    round(track, 999)
    themeObject(track, "BackgroundColor3", "track")

    local fill = new("Frame", {
        Size = UDim2.new(0.58, 0, 1, 0),
        BackgroundColor3 = Accent,
        BorderSizePixel = 0,
        ZIndex = 1602,
    }, track)
    round(fill, 999)
    accentObject(fill, "BackgroundColor3")

    local knob = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.58, 0, 0.5, 0),
        Size = UDim2.fromOffset(13, 13),
        BackgroundColor3 = THEMES[activeThemeName].knob,
        BorderSizePixel = 0,
        ZIndex = 1603,
    }, track)
    round(knob, 999)
    themeObject(knob, "BackgroundColor3", "knob")
    local knobStroke = stroke(knob, THEMES[activeThemeName].knobStroke, 1, 0)
    themeObject(knobStroke, "Color", "knobStroke")

    local sliderHit = new("TextButton", {
        Position = UDim2.fromOffset(-4, -7),
        Size = UDim2.new(1, 8, 0, 19),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 1604,
    }, track)

    local draggingScale = false

    local function updateScaleFromX(x)
        local alpha = math.clamp(
            (x - track.AbsolutePosition.X) / math.max(1, track.AbsoluteSize.X),
            0,
            1
        )

        fill.Size = UDim2.new(alpha, 0, 1, 0)
        knob.Position = UDim2.new(alpha, 0, 0.5, 0)

        local percent = math.floor(80 + alpha * 40 + 0.5)
        scaleValue.Text = tostring(percent) .. "%"
    end

    sliderHit.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            draggingScale = true
            updateScaleFromX(input.Position.X)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if draggingScale and (
            input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch
        ) then
            updateScaleFromX(input.Position.X)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            draggingScale = false
        end
    end)

    SettingsPopup = popup
    tween(popup, 0.13, {Size = UDim2.fromOffset(width, height)})
end

SettingsButton.MouseEnter:Connect(function()
    tween(SettingsButton, 0.08, {
        ImageColor3 = THEMES[activeThemeName].iconHover,
    })
end)
SettingsButton.MouseLeave:Connect(function()
    tween(SettingsButton, 0.08, {
        ImageColor3 = THEMES[activeThemeName].icon,
    })
end)
SettingsButton.MouseButton1Click:Connect(function()
    if SettingsPopupOpen then
        closeSettingsPopup()
    else
        openSettingsPopup()
    end
end)

UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.Escape then
        closePopup()
        closeDropdown()
        closeColorPicker()
        closeSettingsPopup()
        return
    end

    if input.UserInputType ~= Enum.UserInputType.MouseButton1
        and input.UserInputType ~= Enum.UserInputType.Touch then
        return
    end

    -- Keep trigger clicks alive so their own MouseButton1Click handler can
    -- correctly toggle the already-open panel closed.
    if activePopupButton and pointInside(activePopupButton, input.Position) then
        return
    end
    if activeSubmenuButton and pointInside(activeSubmenuButton, input.Position) then
        return
    end
    if activeDropdownButton and pointInside(activeDropdownButton, input.Position) then
        return
    end
    if activeColorPickerButton and pointInside(activeColorPickerButton, input.Position) then
        return
    end
    if SettingsPopupOpen and pointInside(SettingsButton, input.Position) then
        return
    end

    if activeColorPicker and pointInside(activeColorPicker, input.Position) then
        return
    end
    if activeSubmenu and pointInside(activeSubmenu, input.Position) then
        return
    end
    if activePopup and pointInside(activePopup, input.Position) then
        return
    end
    if activeDropdown and pointInside(activeDropdown, input.Position) then
        return
    end
    if SettingsPopup and pointInside(SettingsPopup, input.Position) then
        return
    end

    if activePopup or activeSubmenu or activeColorPicker or activeDropdown or SettingsPopupOpen then
        closePopup()
        closeDropdown()
        closeColorPicker()
        closeSettingsPopup()
    end
end)

local dragInfo
local dragHandles = {}

local function addDragHandle(name, position, size)
    local handle = new("Frame", {
        Name = name,
        Position = position,
        Size = size,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Active = true,
        ZIndex = 9000,
    }, App)
    dragHandles[#dragHandles + 1] = handle
end

addDragHandle("TopDrag", UDim2.fromOffset(218, 0), UDim2.fromOffset(530, 34))
addDragHandle("TopEdge", UDim2.fromOffset(0, 0), UDim2.fromOffset(748, 5))
addDragHandle("LeftEdge", UDim2.fromOffset(0, 5), UDim2.fromOffset(5, 464))
addDragHandle("RightEdge", UDim2.fromOffset(743, 5), UDim2.fromOffset(5, 464))
addDragHandle("BottomEdge", UDim2.fromOffset(0, 469), UDim2.fromOffset(748, 5))

local function startDrag(input)
    closePopup()
    closeDropdown()
    closeColorPicker()
    closeSettingsPopup()

    dragInfo = {
        input = input,
        start = input.Position,
        appPosition = App.Position,
    }
end

for _, handle in ipairs(dragHandles) do
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            startDrag(input)
        end
    end)
end

UserInputService.InputChanged:Connect(function(input)
    if not dragInfo then
        return
    end

    if input.UserInputType ~= Enum.UserInputType.MouseMovement
        and input.UserInputType ~= Enum.UserInputType.Touch then
        return
    end

    local delta = input.Position - dragInfo.start
    App.Position = UDim2.new(
        dragInfo.appPosition.X.Scale,
        dragInfo.appPosition.X.Offset + delta.X,
        dragInfo.appPosition.Y.Scale,
        dragInfo.appPosition.Y.Offset + delta.Y
    )
end)

UserInputService.InputEnded:Connect(function(input)
    if dragInfo and (
        input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch
    ) then
        dragInfo = nil
    end
end)

refreshTheme()

-- Explicitly tint the uploaded transparent-black decal icons. The hit-part
-- visual picker assets are untouched because they are not sidebar icons.
for pageName, info in pairs(navButtons) do
    local active = pageName == activePage
    info.icon.ImageColor3 =
        active
        and THEMES[activeThemeName].iconActive
        or THEMES[activeThemeName].icon
end

SearchIcon.ImageColor3 = THEMES[activeThemeName].iconHover
SearchIcon.ImageTransparency = 0
SettingsButton.ImageColor3 = THEMES[activeThemeName].icon

setActivePage("Combat")

local Consist = {
    Version = "1.0.0",
    Gui = Screen,
    App = App,
}

function Consist:Page(pageName)
    local page = PageBuilders[pageName]
    assert(page, "Unknown Consist page: " .. tostring(pageName))
    return page
end

function Consist:SelectPage(pageName)
    assert(PageBuilders[pageName], "Unknown Consist page: " .. tostring(pageName))
    setActivePage(pageName)
end

function Consist:SetTheme(themeName, animated)
    assert(THEMES[themeName], "Unknown Consist theme: " .. tostring(themeName))
    if animated == false then
        activeThemeName = themeName
        refreshTheme()
        return
    end
    local origin = SettingsButton.AbsolutePosition + (SettingsButton.AbsoluteSize * 0.5)
    animateThemeTransition(themeName, origin)
end

function Consist:GetTheme()
    return activeThemeName
end

function Consist:SetAccent(color)
    assert(typeof(color) == "Color3", "Consist:SetAccent expects a Color3")
    Accent = color
    refreshTheme()
end

function Consist:SetVisible(visible)
    Screen.Enabled = visible ~= false
end

function Consist:Destroy()
    Screen:Destroy()
end

return Consist
