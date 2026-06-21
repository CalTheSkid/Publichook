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
                                    Callback = function(val)
                                        print("[publichook] Aimbot Enabled:", val)
                                    end,
                                    Keybind = {
                                        Name = "Aimbot Bind",
                                        Flag = "AimbotBind",
                                        Default = Enum.KeyCode.F,
                                        Mode = "Hold"
                                    }
                                },
                                {
                                    Type = "Toggle",
                                    Name = "Show FOV Circle",
                                    Flag = "AimbotShowFOV",
                                    Default = false,
                                    Callback = function(val)
                                        print("[publichook] Show FOV:", val)
                                    end,
                                    Colorpicker = {
                                        Name = "FOV Circle Color",
                                        Flag = "AimbotFOVColor",
                                        Color = Color3.fromRGB(0, 230, 118),
                                        Transparency = 0.5
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
                                    Callback = function(val)
                                        print("[publichook] FOV Radius:", val)
                                    end
                                },
                                {
                                    Type = "Dropdown",
                                    Name = "Target Mode",
                                    Flag = "AimbotTargetMode",
                                    Options = {"Distance", "FOV", "Health"},
                                    Default = "Distance",
                                    Callback = function(val)
                                        print("[publichook] Target Mode:", val)
                                    end
                                }
                            }
                        }
                    }
                },
                {
                    Sections = {
                        {
                            Name = "Movement",
                            Side = "Right",
                            Elements = {
                                {
                                    Type = "Slider",
                                    Name = "WalkSpeed Override",
                                    Flag = "MovementWalkSpeed",
                                    Min = 16,
                                    Max = 150,
                                    Decimal = 1,
                                    Default = 16,
                                    Suffix = " studs",
                                    Callback = function(val)
                                        print("[publichook] WalkSpeed:", val)
                                    end
                                },
                                {
                                    Type = "Dropdown",
                                    Name = "WalkSpeed Mode",
                                    Flag = "MovementWSMode",
                                    Options = {"Velocity", "Humanoid", "CFrame"},
                                    Default = "Humanoid",
                                    Callback = function(val)
                                        print("[publichook] WalkSpeed Mode:", val)
                                    end
                                }
                            }
                        },
                        {
                            Name = "ESP",
                            Side = "Right",
                            Elements = {
                                {
                                    Type = "Toggle",
                                    Name = "Enabled",
                                    Flag = "ESPEnabled",
                                    Default = false,
                                    Callback = function(val)
                                        if getgenv().Options then
                                            getgenv().Options["Enabled"] = val
                                        end
                                    end
                                },
                                {
                                    Type = "Toggle",
                                    Name = "Boxes",
                                    Flag = "ESPBoxes",
                                    Default = false,
                                    Callback = function(val)
                                        if getgenv().Options then
                                            getgenv().Options["Boxes"] = val
                                        end
                                    end
                                },
                                {
                                    Type = "Toggle",
                                    Name = "Healthbar",
                                    Flag = "ESPHealthbar",
                                    Default = false,
                                    Callback = function(val)
                                        if getgenv().Options then
                                            getgenv().Options["Healthbar"] = val
                                        end
                                    end
                                },
                                {
                                    Type = "Toggle",
                                    Name = "Name",
                                    Flag = "ESPName",
                                    Default = false,
                                    Callback = function(val)
                                        if getgenv().Options then
                                            getgenv().Options["Name_Text"] = val
                                        end
                                    end
                                },
                                {
                                    Type = "Toggle",
                                    Name = "Distance",
                                    Flag = "ESPDistance",
                                    Default = false,
                                    Callback = function(val)
                                        if getgenv().Options then
                                            getgenv().Options["Distance_Text"] = val
                                        end
                                    end
                                },
                                {
                                    Type = "Slider",
                                    Name = "Render Distance",
                                    Flag = "ESPRenderDist",
                                    Min = 100,
                                    Max = 10000,
                                    Decimal = 100,
                                    Default = 10000,
                                    Suffix = " studs",
                                    Callback = function(val)
                                        if getgenv().Options then
                                            getgenv().Options["Render Distance"] = val
                                        end
                                    end
                                }
                            }
                        }
                    }
                }
            }
        },
        {
            Name = "Miscellaneous",
            Columns = {
                {
                    Sections = {
                        {
                            Name = "Player Actions",
                            Side = "Left",
                            Elements = {
                                {
                                    Type = "Button",
                                    Name = "Rejoin Server",
                                    Callback = function()
                                        local TeleportService = game:GetService("TeleportService")
                                        local Players = game:GetService("Players")
                                        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, Players.LocalPlayer)
                                    end
                                },
                                {
                                    Type = "Button",
                                    Name = "Server Hop",
                                    Callback = function()
                                        local HttpService = game:GetService("HttpService")
                                        local TeleportService = game:GetService("TeleportService")
                                        local ok, result = pcall(function()
                                            return HttpService:JSONDecode(game:HttpGet(
                                                "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
                                            ))
                                        end)
                                        if ok and result and result.data and #result.data > 0 then
                                            local server = result.data[math.random(1, #result.data)]
                                            TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id)
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
                                {
                                    Type = "Label",
                                    Name = "Framework: publichook"
                                },
                                {
                                    Type = "Label",
                                    Name = "UI Library: octohook"
                                }
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
