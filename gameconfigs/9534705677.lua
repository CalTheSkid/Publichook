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
                                    Options = {"FOV", "Distance", "Health"},
                                    Default = "FOV",
                                    Callback = function() end
                                },
                                {
                                    Type = "Toggle",
                                    Name = "Show FOV Circle",
                                    Flag = "AimbotFOVCircle",
                                    Default = false,
                                    Callback = function() end,
                                    Colorpicker = {
                                        Name = "FOV Circle Color",
                                        Flag = "AimbotFOVCircleColor",
                                        Color = Color3.fromRGB(255, 255, 255),
                                        Transparency = 0
                                    }
                                },
                                {
                                    Type = "Dropdown",
                                    Name = "Hit Part",
                                    Flag = "AimbotHitPart",
                                    Options = {"Head", "HumanoidRootPart", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg"},
                                    Default = "Head",
                                    Callback = function() end
                                },
                                {
                                    Type = "Toggle",
                                    Name = "Hard Lock",
                                    Flag = "AimbotHardLock",
                                    Default = false,
                                    Callback = function() end,
                                    Tooltip = {
                                        Title = "Hard Lock",
                                        Text = "When enabled, stays locked onto the target\neven if they leave your FOV circle.\nOnly unlocks if the target dies or leaves.",
                                        Width = 180
                                    }
                                }
                            }
                        },
                        {
                            Name = "Silent Aim",
                            Side = "Left",
                            Elements = {
                                {
                                    Type = "Toggle",
                                    Name = "Enabled",
                                    Flag = "SilentAim",
                                    Default = false,
                                    Callback = function() end
                                },
                                {
                                    Type = "Slider",
                                    Name = "FOV Radius",
                                    Flag = "SilentAimFOV",
                                    Min = 10,
                                    Max = 800,
                                    Decimal = 1,
                                    Default = 200,
                                    Suffix = "px",
                                    Callback = function() end
                                },
                                {
                                    Type = "Toggle",
                                    Name = "Show FOV Circle",
                                    Flag = "SilentAimFOVCircle",
                                    Default = false,
                                    Callback = function() end,
                                    Colorpicker = {
                                        Name = "FOV Circle Color",
                                        Flag = "SilentAimFOVCircleColor",
                                        Color = Color3.fromRGB(255, 100, 100),
                                        Transparency = 0
                                    }
                                },
                                {
                                    Type = "Dropdown",
                                    Name = "Hit Part",
                                    Flag = "SilentAimHitPart",
                                    Options = {"Head", "HumanoidRootPart", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg"},
                                    Default = "Head",
                                    Callback = function() end
                                },
                                {
                                    Type = "Dropdown",
                                    Name = "Target Mode",
                                    Flag = "SilentAimTargetMode",
                                    Options = {"FOV", "Distance", "Health"},
                                    Default = "FOV",
                                    Callback = function() end
                                }
                            }
                        },
                        {
                            Name = "Movement",
                            Side = "Left",
                            Elements = {
                                {
                                    Type = "Toggle",
                                    Name = "Team Check",
                                    Flag = "TeamCheck",
                                    Default = true,
                                    Callback = function() end,
                                    Tooltip = {
                                        Title = "Team Check",
                                        Text = "Ignores players on your team.\nApplies to ESP, Aimbot, Silent Aim.",
                                        Width = 170
                                    }
                                },
                                {
                                    Type = "Toggle",
                                    Name = "Alive Check",
                                    Flag = "AliveCheck",
                                    Default = true,
                                    Callback = function() end,
                                    Tooltip = {
                                        Title = "Alive Check",
                                        Text = "Ignores dead players.\nApplies to ESP, Aimbot, Silent Aim.",
                                        Width = 170
                                    }
                                },
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
                                    Default = 50,
                                    Suffix = " studs",
                                    Callback = function() end
                                },
                                {
                                    Type = "Toggle",
                                    Name = "No Jump Cooldown",
                                    Flag = "NoJumpCooldown",
                                    Default = false,
                                    Callback = function() end
                                },
                                {
                                    Type = "Toggle",
                                    Name = "Bhop",
                                    Flag = "Bhop",
                                    Default = false,
                                    Callback = function() end,
                                    Tooltip = {
                                        Title = "Bhop",
                                        Text = "Works best with\nNo Jump Cooldown enabled.",
                                        Width = 160
                                    },
                                    Keybind = {
                                        Name = "Bhop Bind",
                                        Flag = "BhopBind",
                                        Mode = "Toggle"
                                    }
                                },
                                {
                                    Type = "Toggle",
                                    Name = "No Recoil",
                                    Flag = "NoRecoil",
                                    Default = false,
                                    Callback = function() end,
                                    Tooltip = {
                                        Title = "No Recoil",
                                        Text = "!! CANT BE DISABLED, MUST REJOIN TO DISABLED !!",
                                        Width = 220
                                    }
                                },
                                {
                                    Type = "Toggle",
                                    Name = "No Spread",
                                    Flag = "NoSpread",
                                    Default = false,
                                    Callback = function() end,
                                    Tooltip = {
                                        Title = "No Spread",
                                        Text = "!! CANT BE DISABLED, MUST REJOIN TO DISABLED !!",
                                        Width = 220
                                    }
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
                                        Color = Color3.fromRGB(200, 200, 200),
                                        Transparency = 0
                                    }
                                },
                                {
                                    Type = "Toggle",
                                    Name = "Health Bar",
                                    Flag = "ESPHealthBar",
                                    Default = false,
                                    Callback = function() end,
                                    Colorpicker = {
                                        Name = "High HP Color",
                                        Flag = "ESPHealthHighColor",
                                        Color = Color3.fromRGB(0, 255, 0),
                                        Transparency = 0
                                    }
                                },
                                {
                                    Type = "Label",
                                    Name = "Health Bar Colors"
                                },
                                {
                                    Type = "Colorpicker",
                                    Name = "Low HP Color",
                                    Flag = "ESPHealthLowColor",
                                    Color = Color3.fromRGB(255, 0, 0),
                                    Transparency = 0,
                                    Callback = function() end
                                },
                                {
                                    Type = "Colorpicker",
                                    Name = "HP Background",
                                    Flag = "ESPHealthBgColor",
                                    Color = Color3.fromRGB(0, 0, 0),
                                    Transparency = 0,
                                    Callback = function() end
                                },
                                {
                                    Type = "Toggle",
                                    Name = "Chams",
                                    Flag = "ESPChams",
                                    Default = false,
                                    Callback = function() end,
                                    Colorpicker = {
                                        Name = "Chams Fill",
                                        Flag = "ESPChamsColor",
                                        Color = Color3.fromRGB(255, 0, 0),
                                        Transparency = 0.5
                                    }
                                },
                                {
                                    Type = "Label",
                                    Name = "Chams Outline"
                                },
                                {
                                    Type = "Colorpicker",
                                    Name = "Chams Outline Color",
                                    Flag = "ESPChamsOutlineColor",
                                    Color = Color3.fromRGB(255, 255, 255),
                                    Transparency = 0,
                                    Callback = function() end
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
                                        local P  = game:GetService("Players")
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
