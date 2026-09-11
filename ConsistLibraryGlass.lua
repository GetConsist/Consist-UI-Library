local Glass = {}

local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local GuiService = game:GetService("GuiService")

local RENDER_NAME = "ConsistGlassRenderV5"
local TAG = "ConsistGlassOwnedV5"
local PART_SIZE = 0.01
local PART_TRANSPARENCY = 1 - 1e-7

-- Three nested glass sheets are used instead of one sheet. The outer sheet
-- keeps the entire shell frosted while the inner sheets compound the blur
-- through the body of the interface without requiring dozens of per-control
-- 3D parts.
local GLASS_LAYERS = {
    {Inset = Vector2.new(3, 3), Depth = 0.72},
    {Inset = Vector2.new(12, 12), Depth = 0.18},
    {Inset = Vector2.new(28, 28), Depth = 0.055},
}

local PALETTES = {
    Light = {
        shell = Color3.fromRGB(238, 240, 244),
        chrome = Color3.fromRGB(232, 235, 240),
        surface = Color3.fromRGB(226, 230, 236),
        field = Color3.fromRGB(218, 223, 230),
        popup = Color3.fromRGB(222, 226, 233),
        shellTransparency = 0.16,
        chromeTransparency = 0.27,
        surfaceTransparency = 0.33,
        fieldTransparency = 0.25,
        popupTransparency = 0.16,
        tintA = Color3.fromRGB(238, 241, 247),
        tintB = Color3.fromRGB(226, 232, 242),
    },
    Dark = {
        shell = Color3.fromRGB(7, 8, 11),
        chrome = Color3.fromRGB(11, 12, 16),
        surface = Color3.fromRGB(14, 15, 19),
        field = Color3.fromRGB(17, 18, 23),
        popup = Color3.fromRGB(10, 11, 15),
        shellTransparency = 0.18,
        chromeTransparency = 0.28,
        surfaceTransparency = 0.34,
        fieldTransparency = 0.27,
        popupTransparency = 0.17,
        tintA = Color3.fromRGB(20, 22, 29),
        tintB = Color3.fromRGB(12, 14, 20),
    },
    Black = {
        shell = Color3.fromRGB(3, 4, 6),
        chrome = Color3.fromRGB(7, 8, 11),
        surface = Color3.fromRGB(9, 10, 13),
        field = Color3.fromRGB(12, 13, 17),
        popup = Color3.fromRGB(6, 7, 10),
        shellTransparency = 0.145,
        chromeTransparency = 0.24,
        surfaceTransparency = 0.30,
        fieldTransparency = 0.23,
        popupTransparency = 0.14,
        tintA = Color3.fromRGB(13, 15, 21),
        tintB = Color3.fromRGB(7, 9, 14),
    },
}

local function plainReplaceRange(source, startMarker, endMarker, replacement)
    local first = source:find(startMarker, 1, true)
    if not first then
        return source, false
    end

    local finish = source:find(endMarker, first + #startMarker, true)
    if not finish then
        return source, false
    end

    return source:sub(1, first - 1) .. replacement .. source:sub(finish), true
end

local function injectAfter(source, needle, line)
    local start = source:find(needle, 1, true)
    if not start then
        return source
    end
    local finish = start + #needle - 1
    return source:sub(1, finish) .. "\n" .. line .. source:sub(finish + 1)
end

function Glass.PatchLibrarySource(source)
    if type(source) ~= "string" or source == "" then
        return source
    end

    source = source:gsub(
        "local menuStroke = stroke%(menu, THEMES%[activeThemeName%]%.stroke, 1, 0%.15%)",
        "local menuStroke = stroke(menu, THEMES[activeThemeName].stroke, 1, 0)"
    )
    source = source:gsub(
        "local fs = stroke%(field, THEMES%[activeThemeName%]%.stroke, 1, 0%.15%)",
        "local fs = stroke(field, THEMES[activeThemeName].stroke, 1, 0)"
    )

    -- Mark the important material layers so Attach can style them without
    -- guessing from color values. These insertions are intentionally small
    -- and do not change the control/layout API.
    source = injectAfter(source, "round(App, 15)", 'App:SetAttribute("ConsistGlassRole", "Shell")')
    source = injectAfter(source, "round(SearchPanel, 10)", 'SearchPanel:SetAttribute("ConsistGlassRole", "Chrome")')
    source = injectAfter(source, "round(SettingsButton, 10)", 'SettingsButton:SetAttribute("ConsistGlassRole", "Chrome")')
    source = injectAfter(source, "round(UtilityBar, 10)", 'UtilityBar:SetAttribute("ConsistGlassRole", "Chrome")')
    source = injectAfter(source, "round(Sidebar, 13)", 'Sidebar:SetAttribute("ConsistGlassRole", "Chrome")')

    -- All navigation buttons use the same glass field treatment whenever
    -- they become visible/active.
    source = source:gsub(
        "round%(button, 8%)",
        'round(button, 8)\n    button:SetAttribute("ConsistGlassRole", "Nav")',
        1
    )

    -- The first panel declaration after makeSection is the section surface.
    source = source:gsub(
        "round%(panel, 10%)",
        'round(panel, 10)\n    panel:SetAttribute("ConsistGlassRole", "Section")',
        1
    )

    -- Dropdown fields and popup containers.
    source = source:gsub(
        "round%(field, 6%)",
        'round(field, 6)\n    field:SetAttribute("ConsistGlassRole", "Field")'
    )
    source = source:gsub(
        "round%(menu, 8%)",
        'round(menu, 8)\n    menu:SetAttribute("ConsistGlassRole", "Popup")'
    )
    source = source:gsub(
        "round%(menu, 7%)",
        'round(menu, 7)\n    menu:SetAttribute("ConsistGlassRole", "Popup")'
    )

    local replacement = [[local function animateThemeTransition(themeName, originAbsolutePosition, onFinished)
    if themeName == activeThemeName or themeTransitionBusy then
        if onFinished then
            onFinished()
        end
        return
    end

    themeTransitionBusy = true
    tweenThemeVisuals(themeName, 0.24, true)

    task.delay(0.24, function()
        activeThemeName = themeName
        refreshTheme()
        if onFinished then
            onFinished()
        end
        themeTransitionBusy = false
    end)
end

]]

    source = plainReplaceRange(
        source,
        "local function animateThemeTransition(themeName, originAbsolutePosition, onFinished)",
        "local function setActivePage",
        replacement
    )

    return source
end

local function rayPlaneIntersect(planePosition, planeNormal, rayOrigin, rayDirection)
    local denominator = planeNormal:Dot(rayDirection)
    if math.abs(denominator) < 0.00001 then
        return nil
    end

    local numerator = planeNormal:Dot(rayOrigin - planePosition)
    local distance = -numerator / denominator
    return rayOrigin + rayDirection * distance
end

local function roundedRole(object)
    if not object or not object:IsA("GuiObject") then
        return nil
    end
    return object:GetAttribute("ConsistGlassRole")
end

function Glass.Attach(Consist)
    assert(type(Consist) == "table", "Consist glass expected the Consist library table")
    assert(Consist.Gui and Consist.App, "Consist glass could not find Gui/App")

    local screen = Consist.Gui
    local app = Consist.App
    local alive = true
    local bound = false
    local connections = {}
    local watched = setmetatable({}, {__mode = "k"})
    local internalWrite = setmetatable({}, {__mode = "k"})
    local lastTheme

    pcall(function()
        RunService:UnbindFromRenderStep(RENDER_NAME)
    end)

    -- Clean older Consist/Wave-style glass leftovers that could stack blur or
    -- leave a displaced strip above the new UI.
    for _, parent in ipairs({workspace, workspace.CurrentCamera, Lighting}) do
        if parent then
            for _, object in ipairs(parent:GetChildren()) do
                if object:GetAttribute(TAG)
                    or object:GetAttribute("ConsistGlassOwned")
                    or object.Name == "ConsistAcrylicDepth"
                    or object.Name == "ConsistAcrylicGlass" then
                    pcall(function()
                        object:Destroy()
                    end)
                end
            end
        end
    end

    local oldGradient = app:FindFirstChild("ConsistAcrylicTint")
    if oldGradient then
        oldGradient:Destroy()
    end

    local gradient = Instance.new("UIGradient")
    gradient.Name = "ConsistAcrylicTint"
    gradient.Rotation = 18
    gradient.Parent = app

    -- Stacking a few near-only DOF passes gives the glass a much denser,
    -- Windows-taskbar-like frost than NearIntensity=1 on a single pass.
    local effects = {}
    local effectSettings = {
        {Name = "ConsistAcrylicDepthA", Intensity = 1.00, Focus = 1.80},
        {Name = "ConsistAcrylicDepthB", Intensity = 1.00, Focus = 1.05},
        {Name = "ConsistAcrylicDepthC", Intensity = 0.82, Focus = 0.62},
    }

    for _, settings in ipairs(effectSettings) do
        local effect = Instance.new("DepthOfFieldEffect")
        effect.Name = settings.Name
        effect:SetAttribute(TAG, true)
        effect.FarIntensity = 0
        effect.NearIntensity = settings.Intensity
        effect.FocusDistance = settings.Focus
        effect.InFocusRadius = 0
        effect.Enabled = false
        effect.Parent = Lighting
        effects[#effects + 1] = {
            Effect = effect,
            Focus = settings.Focus,
            Intensity = settings.Intensity,
        }
    end

    local layers = {}
    for index, spec in ipairs(GLASS_LAYERS) do
        local part = Instance.new("Part")
        part.Name = "ConsistAcrylicGlass" .. tostring(index)
        part:SetAttribute(TAG, true)
        part.Size = Vector3.new(PART_SIZE, PART_SIZE, PART_SIZE)
        part.Anchored = true
        part.CanCollide = false
        part.CanTouch = false
        part.CanQuery = false
        part.CastShadow = false
        part.Material = Enum.Material.Glass
        part.Transparency = 1
        part.Parent = workspace

        local mesh = Instance.new("BlockMesh")
        mesh.Parent = part

        layers[#layers + 1] = {
            Part = part,
            Mesh = mesh,
            Inset = spec.Inset,
            Depth = spec.Depth,
        }
    end

    local function currentTheme()
        local ok, result = pcall(function()
            return Consist:GetTheme()
        end)
        if ok and PALETTES[result] then
            return result
        end
        return "Dark"
    end

    local function paletteForCurrentTheme()
        return PALETTES[currentTheme()] or PALETTES.Dark
    end

    local function writeSurface(object, color, transparency)
        if not object or not object.Parent then
            return
        end
        internalWrite[object] = true
        object.BackgroundColor3 = color
        object.BackgroundTransparency = transparency
        internalWrite[object] = nil
    end

    local function applyRole(object, palette)
        if not object or not object.Parent or not object:IsA("GuiObject") then
            return
        end

        local role = roundedRole(object)
        if role == "Shell" then
            writeSurface(object, palette.shell, palette.shellTransparency)
        elseif role == "Chrome" then
            writeSurface(object, palette.chrome, palette.chromeTransparency)
        elseif role == "Section" then
            writeSurface(object, palette.surface, palette.surfaceTransparency)
        elseif role == "Field" then
            if object.BackgroundTransparency < 0.94 then
                writeSurface(object, palette.field, palette.fieldTransparency)
            end
        elseif role == "Nav" then
            -- Inactive nav rows intentionally stay fully transparent. When a
            -- row becomes active, give it the same secondary glass as fields.
            if object.BackgroundTransparency < 0.90 then
                writeSurface(object, palette.field, palette.fieldTransparency)
            end
        elseif role == "Popup" then
            writeSurface(object, palette.popup, palette.popupTransparency)
        end
    end

    local function applyFallbackSurface(object, palette)
        if not object or not object.Parent or not object:IsA("GuiObject") then
            return
        end
        if roundedRole(object) then
            applyRole(object, palette)
            return
        end

        -- Popups/color pickers created outside App live in the overlay with
        -- high Z indices. Keep them dense enough that text beneath cannot show
        -- through, but still let the same blur material read through them.
        if not object:IsDescendantOf(app)
            and object.BackgroundTransparency < 0.90
            and object.AbsoluteSize.X >= 40
            and object.AbsoluteSize.Y >= 20
            and object.ZIndex >= 1000 then
            writeSurface(object, palette.popup, palette.popupTransparency)
            return
        end

        -- Secondary controls inside the app: dropdown fields, keybind pills,
        -- active tabs, search/settings chrome, etc. Tiny toggles/sliders are
        -- deliberately skipped so their accent/state colors stay crisp.
        if object:IsDescendantOf(app)
            and object ~= app
            and object.BackgroundTransparency < 0.90
            and object.AbsoluteSize.X >= 24
            and object.AbsoluteSize.Y >= 20 then
            local area = object.AbsoluteSize.X * object.AbsoluteSize.Y
            if area >= 480 and object.AbsoluteSize.Y <= 36 then
                writeSurface(object, palette.field, palette.fieldTransparency)
            end
        end
    end

    local function watchSurface(object)
        if watched[object] or not object:IsA("GuiObject") then
            return
        end
        if not roundedRole(object) then
            return
        end
        watched[object] = true

        connections[#connections + 1] = object:GetPropertyChangedSignal("BackgroundTransparency"):Connect(function()
            if not alive or internalWrite[object] or not object.Parent then
                return
            end
            task.defer(function()
                if alive and object.Parent then
                    applyRole(object, paletteForCurrentTheme())
                end
            end)
        end)
    end

    local function applyGradient(themeName)
        local palette = PALETTES[themeName] or PALETTES.Dark
        gradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
            ColorSequenceKeypoint.new(0.36, palette.tintA),
            ColorSequenceKeypoint.new(0.72, palette.tintB),
            ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1)),
        })
        gradient.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.010),
            NumberSequenceKeypoint.new(0.42, 0.035),
            NumberSequenceKeypoint.new(0.74, 0.026),
            NumberSequenceKeypoint.new(1, 0.010),
        })
    end

    local function refreshGlass()
        if not alive or not app.Parent then
            return
        end

        local themeName = currentTheme()
        local palette = PALETTES[themeName] or PALETTES.Dark
        lastTheme = themeName
        applyGradient(themeName)

        applyRole(app, palette)
        watchSurface(app)

        for _, object in ipairs(app:GetDescendants()) do
            if object:IsA("GuiObject") then
                watchSurface(object)
                applyFallbackSurface(object, palette)
            end
        end

        for _, object in ipairs(screen:GetDescendants()) do
            if object:IsA("GuiObject") and not object:IsDescendantOf(app) then
                watchSurface(object)
                applyFallbackSurface(object, palette)
            end
        end
    end

    local function hideBlur()
        for _, layer in ipairs(layers) do
            if layer.Part then
                layer.Part.Transparency = 1
            end
        end
        for _, data in ipairs(effects) do
            if data.Effect then
                data.Effect.Enabled = false
            end
        end
    end

    local function getGuiCoordinateCorrection()
        -- AbsolutePosition and camera viewport coordinates can disagree by the
        -- CoreGui/top-bar inset depending on executor/client UI mode. That was
        -- the source of the visible blurred strip sitting above Consist.
        local correction = Vector2.zero
        pcall(function()
            local topLeftInset = GuiService:GetGuiInset()
            correction = Vector2.new(topLeftInset.X, topLeftInset.Y)
        end)
        return correction
    end

    local function placeLayer(layer, camera, appPosition, appSize, correction)
        local inset = layer.Inset
        local corner0 = Vector2.new(
            appPosition.X + inset.X + correction.X,
            appPosition.Y + inset.Y + correction.Y
        )
        local corner1 = Vector2.new(
            appPosition.X + appSize.X - inset.X + correction.X,
            appPosition.Y + appSize.Y - inset.Y + correction.Y
        )

        if corner1.X <= corner0.X or corner1.Y <= corner0.Y then
            layer.Part.Transparency = 1
            return false
        end

        local ray0 = camera:ViewportPointToRay(corner0.X, corner0.Y, 1)
        local ray1 = camera:ViewportPointToRay(corner1.X, corner1.Y, 1)
        local planeDistance = layer.Depth - camera.NearPlaneZ
        local planeOrigin = camera.CFrame.Position + camera.CFrame.LookVector * planeDistance
        local planeNormal = camera.CFrame.LookVector

        local world0 = rayPlaneIntersect(planeOrigin, planeNormal, ray0.Origin, ray0.Direction)
        local world1 = rayPlaneIntersect(planeOrigin, planeNormal, ray1.Origin, ray1.Direction)
        if not world0 or not world1 then
            layer.Part.Transparency = 1
            return false
        end

        local local0 = camera.CFrame:PointToObjectSpace(world0)
        local local1 = camera.CFrame:PointToObjectSpace(world1)
        local localSize = local1 - local0
        local center = (local0 + local1) * 0.5

        layer.Part.CFrame = camera.CFrame
        layer.Mesh.Offset = center
        layer.Mesh.Scale = Vector3.new(
            math.abs(localSize.X) / PART_SIZE,
            math.abs(localSize.Y) / PART_SIZE,
            0.04
        )
        layer.Part.Material = Enum.Material.Glass
        layer.Part.Transparency = PART_TRANSPARENCY
        return true
    end

    local function updateGeometry()
        if not alive or not screen.Enabled or not app.Visible or not app.Parent then
            hideBlur()
            return
        end

        local camera = workspace.CurrentCamera
        if not camera then
            hideBlur()
            return
        end

        local appPosition = app.AbsolutePosition
        local appSize = app.AbsoluteSize
        local correction = getGuiCoordinateCorrection()
        local anyVisible = false

        for _, layer in ipairs(layers) do
            if layer.Part.Parent ~= workspace then
                layer.Part.Parent = workspace
            end
            if placeLayer(layer, camera, appPosition, appSize, correction) then
                anyVisible = true
            end
        end

        for _, data in ipairs(effects) do
            local effect = data.Effect
            effect.Enabled = anyVisible
            effect.FarIntensity = 0
            effect.NearIntensity = data.Intensity
            effect.FocusDistance = data.Focus - camera.NearPlaneZ
            effect.InFocusRadius = 0
        end
    end

    local function setBlurRunning(enabled)
        enabled = enabled == true and alive

        if enabled and not bound then
            RunService:BindToRenderStep(
                RENDER_NAME,
                Enum.RenderPriority.Last.Value,
                updateGeometry
            )
            bound = true
            updateGeometry()
        elseif not enabled and bound then
            pcall(function()
                RunService:UnbindFromRenderStep(RENDER_NAME)
            end)
            bound = false
            hideBlur()
        elseif not enabled then
            hideBlur()
        end
    end

    connections[#connections + 1] = screen:GetPropertyChangedSignal("Enabled"):Connect(function()
        setBlurRunning(screen.Enabled)
        if screen.Enabled then
            task.defer(refreshGlass)
        end
    end)

    connections[#connections + 1] = app.DescendantAdded:Connect(function(object)
        task.defer(function()
            if not alive or not object.Parent then
                return
            end
            if object:IsA("GuiObject") then
                watchSurface(object)
                applyFallbackSurface(object, paletteForCurrentTheme())
            end
        end)
    end)

    connections[#connections + 1] = screen.DescendantAdded:Connect(function(object)
        if object:IsDescendantOf(app) then
            return
        end
        task.defer(function()
            if alive and object.Parent and object:IsA("GuiObject") then
                watchSurface(object)
                applyFallbackSurface(object, paletteForCurrentTheme())
            end
        end)
    end)

    task.spawn(function()
        local maintenanceAccumulator = 0
        while alive and screen.Parent do
            local themeName = currentTheme()
            if themeName ~= lastTheme then
                refreshGlass()
            elseif screen.Enabled then
                maintenanceAccumulator += 1
                -- Low-frequency maintenance catches active nav buttons and
                -- hover-created controls without scanning the tree every frame.
                if maintenanceAccumulator >= 5 then
                    maintenanceAccumulator = 0
                    refreshGlass()
                end
            end
            task.wait(0.12)
        end
    end)

    local function destroy()
        if not alive then
            return
        end
        alive = false
        setBlurRunning(false)

        for _, connection in ipairs(connections) do
            pcall(function()
                connection:Disconnect()
            end)
        end

        for _, data in ipairs(effects) do
            if data.Effect then
                pcall(function()
                    data.Effect:Destroy()
                end)
            end
        end
        for _, layer in ipairs(layers) do
            if layer.Part then
                pcall(function()
                    layer.Part:Destroy()
                end)
            end
        end
        if gradient and gradient.Parent then
            gradient:Destroy()
        end
    end

    connections[#connections + 1] = screen.AncestryChanged:Connect(function(_, parent)
        if not parent then
            destroy()
        end
    end)

    refreshGlass()
    setBlurRunning(screen.Enabled)

    return {
        Refresh = refreshGlass,
        Destroy = destroy,
    }
end

return Glass
