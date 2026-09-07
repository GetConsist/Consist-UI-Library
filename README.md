# Consist UI Library

Reusable Luau interface library for Consist.

## Load the library

```lua
local Consist = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/GetConsist/Consist-UI-Library/main/src/ConsistLibrary.lua"
))()
```

## Add controls

```lua
local Combat = Consist:Page("Combat")

local Main = Combat:Section({
    Side = "Left",
})

Main:Toggle({
    Name = "Camlock",
    Default = false,
    Callback = function(enabled)
        print(enabled)
    end,
})

Main:Dropdown({
    Name = "Aim Part",
    Options = {"Head", "UpperTorso", "HumanoidRootPart"},
    Default = "Head",
    Callback = function(option)
        print(option)
    end,
})

Main:Slider({
    Name = "Smoothness",
    Minimum = 0,
    Maximum = 100,
    Default = 25,
    Suffix = "%",
    Callback = function(value)
        print(value)
    end,
})
```

Available pages are `Home`, `Combat`, `Visual`, `Player`, `Movement`, `World`, `Misc`, `Configs`, and `Settings`.

Create controls in a section before creating the next section on the same side. Sections automatically stack vertically.

## Window methods

```lua
Consist:SelectPage("Combat")
Consist:SetTheme("Dark")
Consist:SetAccent(Color3.fromRGB(145, 174, 255))
Consist:SetVisible(true)
Consist:Destroy()
```

The hosted interface uses the Consist icon site already configured inside `src/ConsistLibrary.lua`.

