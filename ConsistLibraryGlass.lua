local BASE_LIBRARY_URL = "https://raw.githubusercontent.com/GetConsist/Consist-UI-Library/refs/heads/main/src/ConsistLibrary.lua"

local source = game:HttpGet(BASE_LIBRARY_URL)

local function replacePlain(oldText, newText, label)
    local first, last = source:find(oldText, 1, true)
    assert(first, "Consist glass patch could not find: " .. tostring(label or oldText:sub(1, 80)))
    source = source:sub(1, first - 1) .. newText .. source:sub(last + 1)
end

local function replaceRange(startMarker, endMarker, newText, label)
    local first = source:find(startMarker, 1, true)
    assert(first, "Consist glass patch could not find start: " .. tostring(label or startMarker))
    local finish = source:find(endMarker, first + #startMarker, true)
    assert(finish, "Consist glass patch could not find end: " .. tostring(label or endMarker))
    source = source:sub(1, first - 1) .. newText .. source:sub(finish)
end

-- Keep dropdown borders consistent with the section/sidebar outline language.
source = source:gsub(
    "local menuStroke = stroke%(menu, THEMES%[activeThemeName%]%.stroke, 1, 0%.15%)",
    "local menuStroke = stroke(menu, THEMES[activeThemeName].stroke, 1, 0)"
)
source = source:gsub(
    "local fs = stroke%(field, THEMES%[activeThemeName%]%.stroke, 1, 0%.15%)",
    "local fs = stroke(field, THEMES[activeThemeName].stroke, 1, 0)"
)

local appStrokeLine = [[local AppStroke = stroke(App, THEMES[activeThemeName].strokeStrong, 1, 0)]]
local glassInfrastructure = appStrokeLine .. [[

-- Consist acrylic/glass layer. The physical blur is one deep layer behind the
-- full app. Sections and controls use translucent tint layers over that same
-- blur so they read as separate glass depths without stacking expensive blur
-- geometry for every card.
local ConsistGlassLighting = game:GetService("Lighting")
local CONSIST_GLASS_RENDER = "Consist Acrylic Blur Render"
local CONSIST_GLASS_EFFECT = "Consist Acrylic Blur"
local CONSIST_GLASS_TAG = "ConsistAcrylicBlur"
local CONSIST_GLASS_PART_SIZE = 0.01
local CONSIST_GLASS_PART_TRANSPARENCY = 1 - 1e-7
local CONSIST_GLASS_INSET = Vector2.new(8, 8)

local function glassShellTransparency(themeName)
    if themeName == "Light" then
        return 0.20
    elseif themeName == "Black" then
        return 0.31
    end
    return 0.35
end

local function glassBlurIntensity(themeName)
    if themeName == "Light" then
        return 0.74
    elseif themeName == "Black" then
        return 0.84
    end
    return 0.81
end

local function glassTransparencyForKey(key, themeName)
    themeName = themeName or activeThemeName

    if key == "surface" then
        if themeName == "Light" then return 0.38 end
        if themeName == "Black" then return 0.45 end
        return 0.48
    elseif key == "field" then
        if themeName == "Light" then return 0.20 end
        if themeName == "Black" then return 0.27 end
        return 0.30
    elseif key == "fieldHover" then
        if themeName == "Light" then return 0.13 end
        if themeName == "Black" then return 0.19 end
        return 0.21
    elseif key == "popup" then
        if themeName == "Light" then return 0.16 end
        if themeName == "Black" then return 0.21 end
        return 0.24
    end

    return nil
end

App.BackgroundTransparency = glassShellTransparency(activeThemeName)

local AppGlassGradient = new("UIGradient", {
    Rotation = 18,
}, App)

local function refreshAppGlassGradient()
    local white = Color3.new(1, 1, 1)
    local accentMix = activeThemeName == "Light" and 0.025 or 0.075
    local accentTint = white:Lerp(Accent, accentMix)
    local softTint = white:Lerp(Accent, accentMix * 0.40)

    AppGlassGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, white),
        ColorSequenceKeypoint.new(0.42, softTint),
        ColorSequenceKeypoint.new(0.72, accentTint),
        ColorSequenceKeypoint.new(1, white),
    })
end

refreshAppGlassGradient()

local ConsistGlassController = (function()
    pcall(function()
        RunService:UnbindFromRenderStep(CONSIST_GLASS_RENDER)
    end)

    local oldEffect = ConsistGlassLighting:FindFirstChild(CONSIST_GLASS_EFFECT)
    if oldEffect then
        oldEffect:Destroy()
    end

    local function cleanTagged(parent)
        if not parent then
            return
        end
        for _, object in ipairs(parent:GetChildren()) do
            if object:GetAttribute(CONSIST_GLASS_TAG) then
                pcall(function()
                    object:Destroy()
                end)
            end
        end
    end

    cleanTagged(workspace)
    cleanTagged(workspace.CurrentCamera)

    local effect = Instance.new("DepthOfFieldEffect")
    effect.Name = CONSIST_GLASS_EFFECT
    effect:SetAttribute(CONSIST_GLASS_TAG, true)
    effect.FarIntensity = 0
    effect.NearIntensity = glassBlurIntensity(activeThemeName)
    effect.FocusDistance = 0.25
    effect.InFocusRadius = 0
    effect.Enabled = false
    effect.Parent = ConsistGlassLighting

    local part = Instance.new("Part")
    part.Name = "ConsistAcrylicGlass"
    part.Size = Vector3.new(CONSIST_GLASS_PART_SIZE, CONSIST_GLASS_PART_SIZE, CONSIST_GLASS_PART_SIZE)
    part.Anchored = true
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.CastShadow = false
    part.Material = Enum.Material.Glass
    part.Transparency = 1
    part:SetAttribute(CONSIST_GLASS_TAG, true)
    part.Parent = workspace

    local mesh = Instance.new("BlockMesh")
    mesh.Parent = part

    local bound = false
    local destroyed = false

    local function rayPlaneIntersect(planePosition, planeNormal, rayOrigin, rayDirection)
        local denominator = planeNormal:Dot(rayDirection)
        if math.abs(denominator) < 0.00001 then
            return nil
        end
        local numerator = planeNormal:Dot(rayOrigin - planePosition)
        local distance = -numerator / denominator
        return rayOrigin + rayDirection * distance
    end

    local function hidePhysicalBlur()
        if part then
            part.Transparency = 1
        end
        if effect then
            effect.Enabled = false
        end
    end

    local function updateGeometry()
        if destroyed or not Screen.Enabled or not App.Visible or not App.Parent then
            hidePhysicalBlur()
            return
        end

        local camera = workspace.CurrentCamera
        if not camera then
            hidePhysicalBlur()
            return
        end

        if part.Parent ~= workspace then
            part.Parent = workspace
        end

        local appPosition = App.AbsolutePosition
        local appSize = App.AbsoluteSize
        local corner0 = Vector2.new(appPosition.X, appPosition.Y) + CONSIST_GLASS_INSET
        local corner1 = Vector2.new(appPosition.X + appSize.X, appPosition.Y + appSize.Y) - CONSIST_GLASS_INSET

        if corner1.X <= corner0.X or corner1.Y <= corner0.Y then
            hidePhysicalBlur()
            return
        end

        local ray0 = camera:ViewportPointToRay(corner0.X, corner0.Y, 1)
        local ray1 = camera:ViewportPointToRay(corner1.X, corner1.Y, 1)
        local planeOrigin = camera.CFrame.Position + camera.CFrame.LookVector * (0.05 - camera.NearPlaneZ)
        local planeNormal = camera.CFrame.LookVector

        local world0 = rayPlaneIntersect(planeOrigin, planeNormal, ray0.Origin, ray0.Direction)
        local world1 = rayPlaneIntersect(planeOrigin, planeNormal, ray1.Origin, ray1.Direction)

        if not world0 or not world1 then
            hidePhysicalBlur()
            return
        end

        local local0 = camera.CFrame:PointToObjectSpace(world0)
        local local1 = camera.CFrame:PointToObjectSpace(world1)
        local localSize = local1 - local0
        local center = (local0 + local1) * 0.5

        part.CFrame = camera.CFrame
        mesh.Offset = center
        mesh.Scale = Vector3.new(
            math.abs(localSize.X) / CONSIST_GLASS_PART_SIZE,
            math.abs(localSize.Y) / CONSIST_GLASS_PART_SIZE,
            0.05
        )

        part.Material = Enum.Material.Glass
        part.Transparency = CONSIST_GLASS_PART_TRANSPARENCY
        part.Anchored = true
        part.CanCollide = false
        part.CanTouch = false
        part.CanQuery = false

        effect.Enabled = true
        effect.FarIntensity = 0
        effect.NearIntensity = glassBlurIntensity(activeThemeName)
        effect.FocusDistance = 0.25 - camera.NearPlaneZ
        effect.InFocusRadius = 0
    end

    local function setEnabled(enabled)
        enabled = enabled == true and not destroyed

        if enabled and not bound then
            RunService:BindToRenderStep(
                CONSIST_GLASS_RENDER,
                Enum.RenderPriority.Last.Value,
                updateGeometry
            )
            bound = true
            updateGeometry()
        elseif not enabled then
            if bound then
                pcall(function()
                    RunService:UnbindFromRenderStep(CONSIST_GLASS_RENDER)
                end)
                bound = false
            end
            hidePhysicalBlur()
        end
    end

    local function refreshThemeGlass()
        App.BackgroundTransparency = glassShellTransparency(activeThemeName)
        refreshAppGlassGradient()
        if effect then
            effect.NearIntensity = glassBlurIntensity(activeThemeName)
        end
        if Screen.Enabled then
            updateGeometry()
        end
    end

    local enabledConnection = Screen:GetPropertyChangedSignal("Enabled"):Connect(function()
        setEnabled(Screen.Enabled)
    end)

    local ancestryConnection
    ancestryConnection = Screen.AncestryChanged:Connect(function(_, parent)
        if parent then
            return
        end

        destroyed = true
        setEnabled(false)

        if enabledConnection then
            enabledConnection:Disconnect()
            enabledConnection = nil
        end
        if ancestryConnection then
            ancestryConnection:Disconnect()
            ancestryConnection = nil
        end
        if effect then
            effect:Destroy()
            effect = nil
        end
        if part then
            part:Destroy()
            part = nil
        end
    end)

    setEnabled(Screen.Enabled)

    return {
        SetEnabled = setEnabled,
        RefreshTheme = refreshThemeGlass,
        Update = updateGeometry,
    }
end)()
]]
replacePlain(appStrokeLine, glassInfrastructure, "App glass infrastructure")

local oldThemeObject = [[local themed = {}
local function themeObject(object, property, key)
    themed[#themed + 1] = {object = object, property = property, key = key}
    object[property] = THEMES[activeThemeName][key]
end]]
local newThemeObject = [[local themed = {}
local function themeObject(object, property, key)
    themed[#themed + 1] = {object = object, property = property, key = key}
    object[property] = THEMES[activeThemeName][key]

    if property == "BackgroundColor3" and object:IsA("GuiObject") then
        local targetTransparency = glassTransparencyForKey(key, activeThemeName)
        if targetTransparency ~= nil and object.BackgroundTransparency < 0.95 then
            object.BackgroundTransparency = targetTransparency
            object:SetAttribute("ConsistGlassManaged", true)
            object:SetAttribute("ConsistGlassThemeKey", key)
        end
    end
end]]
replacePlain(oldThemeObject, newThemeObject, "themeObject glass behavior")

-- Expanded dropdown surfaces are denser glass than normal controls and retain
-- the normal Consist outline.
local dropdownRound = [[    round(menu, 8)
    local menuStroke = stroke(menu, THEMES[activeThemeName].stroke, 1, 0)]]
local dropdownGlass = [[    round(menu, 8)
    menu.BackgroundColor3 = THEMES[activeThemeName].popup
    menu.BackgroundTransparency = glassTransparencyForKey("popup", activeThemeName) or 0.24
    menu:SetAttribute("ConsistGlassManaged", true)
    menu:SetAttribute("ConsistGlassThemeKey", "popup")
    themeObject(menu, "BackgroundColor3", "popup")
    local menuStroke = stroke(menu, THEMES[activeThemeName].stroke, 1, 0)]]
replacePlain(dropdownRound, dropdownGlass, "dropdown glass popup")


-- Three-dot panes and their second-level panes use the same denser popup glass.
source = source:gsub(
    'round%(menu, 7%)\n    stroke%(menu, THEMES%[activeThemeName%]%.strokeStrong, 1, 0%.76%)',
    'round(menu, 7)\n    menu.BackgroundTransparency = glassTransparencyForKey("popup", activeThemeName) or 0.24\n    stroke(menu, THEMES[activeThemeName].strokeStrong, 1, 0.76)'
)

-- Inline color pickers stay readable but inherit the glass behind them.
source = source:gsub(
    'round%(picker, 9%)\n    capturePopupSurface%(picker, 1500%)',
    'round(picker, 9)\n    picker.BackgroundTransparency = glassTransparencyForKey("popup", activeThemeName) or 0.24\n    capturePopupSurface(picker, 1500)'
)

-- Theme refresh also restores glass opacity rules. Objects that intentionally
-- started transparent (labels, blank rows, etc.) are never marked as managed.
local oldRefreshLoop = [[    for _, item in ipairs(themed) do
        if item.object and item.object.Parent then
            item.object[item.property] = theme[item.key]
        end
    end]]
local newRefreshLoop = [[    for _, item in ipairs(themed) do
        if item.object and item.object.Parent then
            item.object[item.property] = theme[item.key]

            if item.property == "BackgroundColor3"
                and item.object:IsA("GuiObject")
                and item.object:GetAttribute("ConsistGlassManaged") then
                local glassKey = item.object:GetAttribute("ConsistGlassThemeKey") or item.key
                local targetTransparency = glassTransparencyForKey(glassKey, activeThemeName)
                if targetTransparency ~= nil then
                    item.object.BackgroundTransparency = targetTransparency
                end
            end
        end
    end]]
replacePlain(oldRefreshLoop, newRefreshLoop, "refreshTheme glass loop")

local oldNavTransparency = [[        info.button.BackgroundTransparency = active and 0 or 1]]
local newNavTransparency = [[        info.button.BackgroundTransparency = active
            and (glassTransparencyForKey("field", activeThemeName) or 0)
            or 1]]
replacePlain(oldNavTransparency, newNavTransparency, "active navigation glass")

local oldRefreshEnding = [[    SearchIcon.ImageColor3 = theme.iconHover
    SearchIcon.ImageTransparency = 0
    SettingsButton.ImageColor3 = theme.icon
end]]
local newRefreshEnding = [[    SearchIcon.ImageColor3 = theme.iconHover
    SearchIcon.ImageTransparency = 0
    SettingsButton.ImageColor3 = theme.icon

    if ConsistGlassController then
        ConsistGlassController.RefreshTheme()
    end
end]]
replacePlain(oldRefreshEnding, newRefreshEnding, "refreshTheme glass controller")

local oldAppThemeTween = [[        addTween(App, {
            BackgroundColor3 = target.shell,
        })]]
local newAppThemeTween = [[        addTween(App, {
            BackgroundColor3 = target.shell,
            BackgroundTransparency = glassShellTransparency(themeName),
        })]]
replacePlain(oldAppThemeTween, newAppThemeTween, "theme tween shell opacity")

-- Every theme transition is now the same restrained cross-fade. The old
-- Light <-> Dark/Black radial/sweeping wipe is intentionally removed.
local simpleThemeTransition = [[local function animateThemeTransition(themeName, originAbsolutePosition, onFinished)
    if themeName == activeThemeName or themeTransitionBusy then
        if onFinished then
            onFinished()
        end
        return
    end

    themeTransitionBusy = true
    local visualTweens = tweenThemeVisuals(themeName, 0.28, true)
    local completionTween = visualTweens[1]
    local finished = false

    local function completeTransition()
        if finished then
            return
        end
        finished = true
        activeThemeName = themeName
        refreshTheme()
        if onFinished then
            onFinished()
        end
        themeTransitionBusy = false
    end

    if completionTween then
        local completionConnection
        completionConnection = completionTween.Completed:Connect(function()
            if completionConnection then
                completionConnection:Disconnect()
                completionConnection = nil
            end
            completeTransition()
        end)
    else
        completeTransition()
    end
end

]]
replaceRange(
    "local function animateThemeTransition(themeName, originAbsolutePosition, onFinished)",
    "local function setActivePage",
    simpleThemeTransition,
    "theme transition"
)

return loadstring(source)()
