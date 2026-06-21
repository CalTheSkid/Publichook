local Config = {
    Window = {
        Size = UDim2.new(0, 455, 0, 605)
    },
    Tabs = {
        {
            Name = "Main",
            Columns = {
                {
                    Sections = {
                        {
                            Name = "Aimbot",
                            Side = "Left",
                            Elements = {
                                {
                                    Type = "Toggle",
                                    Name = "Enabled",
                                    Flag = "AimbotEnabled",
                                    Default = false,
                                    Callback = function() end,
                                    Keybind = {
                                        Name = "Aimbot Bind",
                                        Flag = "AimbotBind",
                                        Key = Enum.KeyCode.F,
                                        Mode = "Hold"
                                    }
                                },
                                {
                                    Type = "Slider",
                                    Name = "FOV Radius",
                                    Flag = "AimbotFOVRadius",
                                    Min = 10,
                                    Max = 800,
                                    Decimal = 1,
                                    Default = 120,
                                    Suffix = "px",
                                    Callback = function() end
                                },
                                {
                                    Type = "Slider",
                                    Name = "Smoothness",
                                    Flag = "AimbotSmooth",
                                    Min = 1,
                                    Max = 100,
                                    Decimal = 1,
                                    Default = 20,
                                    Callback = function() end
                                },
                                {
                                    Type = "Dropdown",
                                    Name = "Target Mode",
                                    Flag = "AimbotTargetMode",
                                    Options = {"Distance", "FOV", "Health"},
                                    Default = "Distance",
                                    Callback = function() end
                                }
                            }
                        }
                    }
                },
                {
                    Sections = {
                        {
                            Name = "ESP",
                            Side = "Right",
                            Elements = {
                                {
                                    Type = "Toggle",
                                    Name = "Enabled",
                                    Flag = "ESPEnabled",
                                    Default = false,
                                    Callback = function() end
                                },
                                {
                                    Type = "Toggle",
                                    Name = "Boxes",
                                    Flag = "ESPBoxes",
                                    Default = false,
                                    Callback = function() end,
                                    Colorpicker = {
                                        Name = "Box Color",
                                        Flag = "ESPBoxColor",
                                        Color = Color3.fromRGB(255, 255, 255),
                                        Transparency = 0
                                    }
                                },
                                {
                                    Type = "Toggle",
                                    Name = "Name",
                                    Flag = "ESPName",
                                    Default = false,
                                    Callback = function() end,
                                    Colorpicker = {
                                        Name = "Name Color",
                                        Flag = "ESPNameColor",
                                        Color = Color3.fromRGB(255, 255, 255),
                                        Transparency = 0
                                    }
                                },
                                {
                                    Type = "Toggle",
                                    Name = "Distance",
                                    Flag = "ESPDistance",
                                    Default = false,
                                    Callback = function() end,
                                    Colorpicker = {
                                        Name = "Distance Color",
                                        Flag = "ESPDistanceColor",
                                        Color = Color3.fromRGB(255, 255, 255),
                                        Transparency = 0
                                    }
                                },
                                {
                                    Type = "Toggle",
                                    Name = "Health Bar",
                                    Flag = "ESPHealthBar",
                                    Default = false,
                                    Callback = function() end
                                },
                                {
                                    Type = "Toggle",
                                    Name = "Chams",
                                    Flag = "ESPChams",
                                    Default = false,
                                    Callback = function() end,
                                    Colorpicker = {
                                        Name = "Chams Color",
                                        Flag = "ESPChamsColor",
                                        Color = Color3.fromRGB(255, 0, 0),
                                        Transparency = 0.5
                                    }
                                },
                                {
                                    Type = "Slider",
                                    Name = "Max Distance",
                                    Flag = "ESPMaxDist",
                                    Min = 50,
                                    Max = 5000,
                                    Decimal = 50,
                                    Default = 2000,
                                    Suffix = " studs",
                                    Callback = function() end
                                }
                            }
                        },
                        {
                            Name = "Movement",
                            Side = "Right",
                            Elements = {
                                {
                                    Type = "Toggle",
                                    Name = "Enabled",
                                    Flag = "MovementEnabled",
                                    Default = false,
                                    Callback = function() end
                                },
                                {
                                    Type = "Slider",
                                    Name = "WalkSpeed",
                                    Flag = "MovementWalkSpeed",
                                    Min = 16,
                                    Max = 150,
                                    Decimal = 1,
                                    Default = 16,
                                    Suffix = " studs",
                                    Callback = function() end
                                },
                                {
                                    Type = "Dropdown",
                                    Name = "Speed Mode",
                                    Flag = "MovementWSMode",
                                    Options = {"Humanoid", "Velocity"},
                                    Default = "Humanoid",
                                    Callback = function() end
                                }
                            }
                        }
                    }
                }
            }
        },
        {
            Name = "Misc",
            Columns = {
                {
                    Sections = {
                        {
                            Name = "Server",
                            Side = "Left",
                            Elements = {
                                {
                                    Type = "Button",
                                    Name = "Rejoin",
                                    Callback = function()
                                        local TP = game:GetService("TeleportService")
                                        local P = game:GetService("Players")
                                        TP:TeleportToPlaceInstance(game.PlaceId, game.JobId, P.LocalPlayer)
                                    end
                                },
                                {
                                    Type = "Button",
                                    Name = "Server Hop",
                                    Callback = function()
                                        local ok, result = pcall(function()
                                            return game:GetService("HttpService"):JSONDecode(
                                                game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100")
                                            )
                                        end)
                                        if ok and result and result.data and #result.data > 0 then
                                            local s = result.data[math.random(1, #result.data)]
                                            game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, s.id)
                                        end
                                    end
                                }
                            }
                        }
                    }
                },
                {
                    Sections = {
                        {
                            Name = "Credits",
                            Side = "Right",
                            Elements = {
                                { Type = "Label", Name = "publichook framework" },
                                { Type = "Label", Name = "UI: octohook by @finobe" }
                            }
                        }
                    }
                }
            }
        }
    },
    ConfigsTab = {
        TabName = "Settings"
    }
}

return Config
