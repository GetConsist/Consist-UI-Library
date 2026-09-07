local Consist = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/GetConsist/Consist-UI-Library/main/src/ConsistLibrary.lua"
))()

local mainFovColor = Color3.fromRGB(145, 174, 255)
local outlineColor = Color3.fromRGB(255, 255, 255)
local fillColor = mainFovColor
local fillUsesMainColor = true

local rainbow = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 76, 76)),
    ColorSequenceKeypoint.new(0.33, Color3.fromRGB(255, 224, 92)),
    ColorSequenceKeypoint.new(0.66, Color3.fromRGB(84, 218, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(177, 104, 255)),
})

local sunset = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 91, 126)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 151, 92)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(126, 83, 255)),
})

local water = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 226, 232)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(70, 149, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(102, 91, 235)),
})

local green = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(92, 232, 151)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(40, 181, 125)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(157, 255, 115)),
})

local fovAdvanced
fovAdvanced = {
    {
        Name = "Appearance",
        Title = "FOV Appearance",
        Controls = {
            {
                Type = "Color",
                Name = "FOV Color",
                Default = mainFovColor,
                Callback = function(color)
                    mainFovColor = color
                    if fillUsesMainColor then
                        fillColor = color
                        fovAdvanced[1].Controls[8].Default = color
                    end
                end,
            },
            {
                Type = "Slider",
                Name = "Thickness",
                Minimum = 1,
                Maximum = 8,
                Default = 2,
            },
            {
                Type = "Toggle",
                Name = "Outline",
                Default = true,
            },
            {
                Type = "Color",
                Name = "Outline Color",
                Default = outlineColor,
                Callback = function(color)
                    outlineColor = color
                end,
            },
            {
                Type = "Slider",
                Name = "Outline Thickness",
                Minimum = 1,
                Maximum = 8,
                Default = 2,
            },
            {
                Type = "Toggle",
                Name = "Fill",
                Default = false,
            },
            {
                Type = "Slider",
                Name = "Fill Transparency",
                Minimum = 0,
                Maximum = 75,
                Default = 35,
                Suffix = "%",
            },
            {
                Type = "Color",
                Name = "Fill Color",
                Default = fillColor,
                Reset = true,
                ResetColor = function()
                    return mainFovColor
                end,
                Callback = function(color, reset)
                    fillUsesMainColor = reset == true
                    fillColor = reset and mainFovColor or color
                    fovAdvanced[1].Controls[8].Default = fillColor
                end,
            },
        },
    },
    {
        Name = "Animate",
        Title = "FOV Animation",
        Controls = {
            {
                Type = "Toggle",
                Name = "Animate Fill",
                Default = false,
            },
            {
                Type = "Toggle",
                Name = "Animate Outline",
                Default = false,
            },
            {
                Type = "Colors",
                Name = "Custom Colors",
                Colors = {
                    Color3.fromRGB(145, 174, 255),
                    Color3.fromRGB(112, 206, 225),
                    Color3.fromRGB(177, 104, 255),
                },
            },
            {
                Type = "Presets",
                Name = "Presets",
                Presets = {rainbow, sunset, water, green},
            },
        },
    },
}

local Combat = Consist:Page("Combat")

local ModeSection = Combat:Section({
    Side = "Left",
})

ModeSection:Dropdown({
    Name = "Combat Mode",
    Options = {"Camlock", "Mouselock", "Silent"},
    Default = "Camlock",
})

ModeSection:Toggle({
    Name = "Toggle",
    Default = false,
})

ModeSection:Keybind({
    Name = "Keybind",
    Default = Enum.KeyCode.Q,
})

ModeSection:Slider({
    Name = "Prediction",
    Minimum = 0,
    Maximum = 0.20,
    Default = 0.10,
    Decimals = 2,
})

ModeSection:Slider({
    Name = "Smoothness",
    Minimum = 0,
    Maximum = 100,
    Default = 50,
    Suffix = "%",
})

local FovSection = Combat:Section({
    Side = "Left",
})

FovSection:Toggle({
    Name = "Toggle",
    Default = false,
    Advanced = fovAdvanced,
})

FovSection:Keybind({
    Name = "Toggle Key",
    Default = Enum.KeyCode.F,
})

FovSection:Slider({
    Name = "FOV Size",
    Minimum = 25,
    Maximum = 600,
    Default = 150,
})

Consist:SelectPage("Combat")
