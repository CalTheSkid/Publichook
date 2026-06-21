local Config = {
    Window = {
        Size = UDim2.new(0, 455, 0, 605)
    },
    Tabs = {
        {
            Name = "Gun Modifiers",
            Columns = {
                {
                    Sections = {
                        {
                            Name = "Weapon Mechanics",
                            Side = "Left",
                            Elements = {
                                {
                                    Type = "Toggle",
                                    Name = "Infinite Ammo",
                                    Flag = "GunModsInfAmmo",
                                    Default = true,
                                    Callback = function(val)
                                        print("[publichook] Infinite Ammo toggled:", val)
                                    end
                                },
                                {
                                    Type = "Toggle",
                                    Name = "No Recoil",
                                    Flag = "GunModsNoRecoil",
                                    Default = false,
                                    Callback = function(val)
                                        print("[publichook] No Recoil toggled:", val)
                                    end,
                                    Keybind = {
                                        Name = "Recoil Bind",
                                        Flag = "GunModsNoRecoilBind",
                                        Default = Enum.KeyCode.H,
                                        Mode = "Toggle"
                                    }
                                },
                                {
                                    Type = "Toggle",
                                    Name = "Rapid Fire",
                                    Flag = "GunModsRapidFire",
                                    Default = false,
                                    Callback = function(val)
                                        print("[publichook] Rapid Fire toggled:", val)
                                    end
                                },
                                {
                                    Type = "Slider",
                                    Name = "Fire Rate Speed",
                                    Flag = "GunModsFireRateSpeed",
                                    Min = 1,
                                    Max = 5,
                                    Decimal = 0.1,
                                    Default = 1.5,
                                    Suffix = "x Speed",
                                    Callback = function(val)
                                        print("[publichook] Fire Rate Speed Multiplier:", val)
                                    end
                                }
                            }
                        }
                    }
                }
            }
        },
        {
            Name = "Teleports",
            Columns = {
                {
                    Sections = {
                        {
                            Name = "World Navigation",
                            Side = "Left",
                            Elements = {
                                {
                                    Type = "Button",
                                    Name = "Teleport to Spawn",
                                    Callback = function()
                                        print("[publichook] Teleporting to Spawn...")
                                    end
                                },
                                {
                                    Type = "Button",
                                    Name = "Teleport to Flag",
                                    Callback = function()
                                        print("[publichook] Teleporting to Flag...")
                                    end
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
