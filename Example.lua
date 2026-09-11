local Consist = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/GetConsist/Consist-UI-Library/main/src/ConsistLibrary.lua"
))()

local camlockEnabled = false
local aimPart = "Head"
local smoothness = 25

local Combat = Consist:Page("Combat")

local Main = Combat:Section({
    Side = "Left",
})

Main:Toggle({
    Name = "Camlock",
    Default = false,
    Callback = function(value)
        camlockEnabled = value
    end,
})

Main:Dropdown({
    Name = "Aim Part",
    Options = {"Head", "UpperTorso", "HumanoidRootPart"},
    Default = "Head",
    Callback = function(value)
        aimPart = value
    end,
})

local Aim = Combat:Section({
    Side = "Right",
})

Aim:Slider({
    Name = "Smoothness",
    Minimum = 0,
    Maximum = 100,
    Default = 25,
    Suffix = "%",
    Callback = function(value)
        smoothness = value
    end,
})

Consist:SelectPage("Combat")

