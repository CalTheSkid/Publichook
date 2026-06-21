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
                            Name = "Visuals (ESP)",
                            Side = "Right",
                            Elements = {
                                {
                                    Type = "Toggle",
                                    Name = "Box ESP",
                                    Flag = "ESPBoxEnabled",
                                    Default = false,
                                    Callback = function(val)
                                        print("[publichook] Box ESP:", val)
                                    end,
                                    Colorpicker = {
                                        Name = "Box Color",
                                        Flag = "ESPBoxColor",
                                        Color = Color3.fromRGB(255, 61, 0),
                                        Transparency = 0
                                    }
                                },
                                {
                                    Type = "Toggle",
                                    Name = "Name ESP",
                                    Flag = "ESPNameEnabled",
                                    Default = false,
                                    Callback = function(val)
                                        print("[publichook] Name ESP:", val)
                                    end
                                },
                                {
                                    Type = "Toggle",
                                    Name = "Skeleton ESP",
                                    Flag = "ESPSkeletonEnabled",
                                    Default = false,
                                    Callback = function(val)
                                        print("[publichook] Skeleton ESP:", val)
                                    end
                                }
                            }
                        },
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
                                        print("[publichook] WalkSpeed Limit:", val)
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
                                        if #Players:GetPlayers() <= 1 then
                                            Players.LocalPlayer:Kick("Rejoining...")
                                            task.wait()
                                            TeleportService:Teleport(game.PlaceId, Players.LocalPlayer)
                                        else
                                            TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, Players.LocalPlayer)
                                        end
                                    end
                                },
                                {
                                    Type = "Button",
                                    Name = "Server Hop",
                                    Callback = function()
                                        print("[publichook] Attempting Server Hop...")
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
                                    Name = "Developer: @finobe & Pair Partner"
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
