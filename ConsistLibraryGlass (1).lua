local Glass = {}

local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local RENDER_NAME = "ConsistGlassRender"
local EFFECT_NAME = "ConsistAcrylicDepth"
local TAG = "ConsistGlassOwned"
local PART_SIZE = 0.01
local PART_TRANSPARENCY = 1 - 1e-7
local INSET = Vector2.new(34, 34) -- guards the DOF kernel so blur does not bleed beyond the UI edges

local PALETTES = {
    Light = {
        shell = Color3.fromRGB(246, 247, 249),
        surface = Color3.fromRGB(238, 240, 244),
        field = Color3.fromRGB(231, 234, 239),
        popup = Color3.fromRGB(234, 237, 242),
        shellTransparency = 0.075,
        surfaceTransparency = 0.16,
        fieldTransparency = 0.085,
        popupTransparency = 0.055,
        blur = 0.96,
        tintA = Color3.fromRGB(244, 246, 250),
        tintB = Color3.fromRGB(235, 239, 247),
    },
    Dark = {
        shell = Color3.fromRGB(13, 14, 17),
        surface = Color3.fromRGB(19, 20, 24),
        field = Color3.fromRGB(22, 23, 28),
        popup = Color3.fromRGB(17, 18, 22),
        shellTransparency = 0.065,
        surfaceTransparency = 0.19,
        fieldTransparency = 0.095,
        popupTransparency = 0.055,
        blur = 1.00,
        tintA = Color3.fromRGB(232, 235, 243),
        tintB = Color3.fromRGB(214, 220, 234),
    },
    Black = {
        shell = Color3.fromRGB(6, 7, 9),
        surface = Color3.fromRGB(11, 12, 15),
        field = Color3.fromRGB(15, 16, 20),
        popup = Color3.fromRGB(9, 10, 13),
        shellTransparency = 0.045,
        surfaceTransparency = 0.15,
        fieldTransparency = 0.075,
        popupTransparency = 0.045,
        blur = 1.00,
        tintA = Color3.fromRGB(226, 229, 238),
        tintB = Color3.fromRGB(204, 210, 225),
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

    local patched
    source, patched = plainReplaceRange(
        source,
        "local function animateThemeTransition(themeName, originAbsolutePosition, onFinished)",
        "local function setActivePage",
        replacement
    )

    return source
end

local function colorDistance(a, b)
    local dr = a.R - b.R
    local dg = a.G - b.G
    local db = a.B - b.B
    return math.sqrt(dr * dr + dg * dg + db * db)
end

local function colorNear(a, b, tolerance)
    return colorDistance(a, b) <= (tolerance or 0.025)
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

function Glass.Attach(Consist)
    assert(type(Consist) == "table", "Consist glass expected the Consist library table")
    assert(Consist.Gui and Consist.App, "Consist glass could not find Gui/App")

    local screen = Consist.Gui
    local app = Consist.App
    local alive = true
    local bound = false
    local connections = {}
    local lastTheme

    pcall(function()
        RunService:UnbindFromRenderStep(RENDER_NAME)
    end)

    for _, parent in ipairs({workspace, workspace.CurrentCamera, Lighting}) do
        if parent then
            for _, object in ipairs(parent:GetChildren()) do
                if object:GetAttribute(TAG) then
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
    gradient.Rotation = 20
    gradient.Parent = app

    local effect = Instance.new("DepthOfFieldEffect")
    effect.Name = EFFECT_NAME
    effect:SetAttribute(TAG, true)
    effect.FarIntensity = 0
    effect.NearIntensity = 1
    effect.FocusDistance = 0.25
    effect.InFocusRadius = 0
    effect.Enabled = false
    effect.Parent = Lighting

    local part = Instance.new("Part")
    part.Name = "ConsistAcrylicGlass"
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

    local function currentTheme()
        local ok, result = pcall(function()
            return Consist:GetTheme()
        end)
        if ok and PALETTES[result] then
            return result
        end
        return "Dark"
    end

    local function applyGradient(themeName)
        local palette = PALETTES[themeName] or PALETTES.Dark
        gradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
            ColorSequenceKeypoint.new(0.38, palette.tintA),
            ColorSequenceKeypoint.new(0.72, palette.tintB),
            ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1)),
        })
        gradient.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.005),
            NumberSequenceKeypoint.new(0.45, 0.018),
            NumberSequenceKeypoint.new(0.75, 0.012),
            NumberSequenceKeypoint.new(1, 0.005),
        })
    end

    local function applyObjectGlass(object, palette)
        if not object:IsA("GuiObject") or object == app then
            return
        end

        if object:IsA("Frame") and object:FindFirstChild("ConsistInnerSectionBorder") then
            object.BackgroundTransparency = palette.surfaceTransparency
            return
        end

        if object.BackgroundTransparency >= 0.94 then
            return
        end

        local z = object.ZIndex or 1
        local color = object.BackgroundColor3

        if z >= 1000 and (colorNear(color, palette.popup, 0.045) or colorNear(color, palette.surface, 0.045)) then
            object.BackgroundTransparency = palette.popupTransparency
            return
        end

        if colorNear(color, palette.field, 0.035) then
            object.BackgroundTransparency = palette.fieldTransparency
            return
        end

        if colorNear(color, palette.surface, 0.035) then
            object.BackgroundTransparency = palette.surfaceTransparency
        end
    end

    local function refreshGlass()
        if not alive or not app.Parent then
            return
        end

        local themeName = currentTheme()
        local palette = PALETTES[themeName] or PALETTES.Dark
        lastTheme = themeName

        app.BackgroundTransparency = palette.shellTransparency
        effect.NearIntensity = palette.blur
        applyGradient(themeName)

        for _, object in ipairs(app:GetDescendants()) do
            if object:IsA("GuiObject") then
                applyObjectGlass(object, palette)
            end
        end

        for _, object in ipairs(screen:GetDescendants()) do
            if object:IsA("GuiObject") and not object:IsDescendantOf(app) then
                applyObjectGlass(object, palette)
            end
        end
    end

    local function hideBlur()
        if part then
            part.Transparency = 1
        end
        if effect then
            effect.Enabled = false
        end
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

        if part.Parent ~= workspace then
            part.Parent = workspace
        end

        local position = app.AbsolutePosition
        local size = app.AbsoluteSize
        local corner0 = Vector2.new(position.X, position.Y) + INSET
        local corner1 = Vector2.new(position.X + size.X, position.Y + size.Y) - INSET

        if corner1.X <= corner0.X or corner1.Y <= corner0.Y then
            hideBlur()
            return
        end

        local ray0 = camera:ViewportPointToRay(corner0.X, corner0.Y, 1)
        local ray1 = camera:ViewportPointToRay(corner1.X, corner1.Y, 1)
        local planeOrigin = camera.CFrame.Position + camera.CFrame.LookVector * (0.05 - camera.NearPlaneZ)
        local planeNormal = camera.CFrame.LookVector

        local world0 = rayPlaneIntersect(planeOrigin, planeNormal, ray0.Origin, ray0.Direction)
        local world1 = rayPlaneIntersect(planeOrigin, planeNormal, ray1.Origin, ray1.Direction)

        if not world0 or not world1 then
            hideBlur()
            return
        end

        local local0 = camera.CFrame:PointToObjectSpace(world0)
        local local1 = camera.CFrame:PointToObjectSpace(world1)
        local localSize = local1 - local0
        local center = (local0 + local1) * 0.5

        part.CFrame = camera.CFrame
        mesh.Offset = center
        mesh.Scale = Vector3.new(
            math.abs(localSize.X) / PART_SIZE,
            math.abs(localSize.Y) / PART_SIZE,
            0.05
        )

        part.Material = Enum.Material.Glass
        part.Transparency = PART_TRANSPARENCY
        effect.Enabled = true
        effect.FarIntensity = 0
        effect.NearIntensity = (PALETTES[currentTheme()] or PALETTES.Dark).blur
        effect.FocusDistance = 0.25 - camera.NearPlaneZ
        effect.InFocusRadius = 0
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
            local palette = PALETTES[currentTheme()] or PALETTES.Dark
            if object:IsA("GuiObject") then
                applyObjectGlass(object, palette)
            elseif object:IsA("UIStroke") and object.Parent and object.Parent:IsA("GuiObject") then
                applyObjectGlass(object.Parent, palette)
            end
        end)
    end)

    connections[#connections + 1] = screen.DescendantAdded:Connect(function(object)
        if object:IsDescendantOf(app) then
            return
        end
        task.defer(function()
            if alive and object.Parent and object:IsA("GuiObject") then
                applyObjectGlass(object, PALETTES[currentTheme()] or PALETTES.Dark)
            end
        end)
    end)

    task.spawn(function()
        while alive and screen.Parent do
            local themeName = currentTheme()
            if themeName ~= lastTheme then
                refreshGlass()
            end
            task.wait(0.12)
        end
    end)

    connections[#connections + 1] = screen.AncestryChanged:Connect(function(_, parent)
        if parent then
            return
        end

        alive = false
        setBlurRunning(false)

        for _, connection in ipairs(connections) do
            pcall(function()
                connection:Disconnect()
            end)
        end

        if effect then
            effect:Destroy()
        end
        if part then
            part:Destroy()
        end
    end)

    refreshGlass()
    setBlurRunning(screen.Enabled)

    return {
        Refresh = refreshGlass,
        Destroy = function()
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
            if effect then
                effect:Destroy()
            end
            if part then
                part:Destroy()
            end
        end,
    }
end

return Glass
