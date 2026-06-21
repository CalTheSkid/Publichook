local GITHUB_OWNER = "CalTheSkid"
local GITHUB_REPO = "Publichook"
local GITHUB_BRANCH = "main"

local function fetchFile(path)
    local baseUrl = string.format("https://raw.githubusercontent.com/%s/%s/%s/%s", GITHUB_OWNER, GITHUB_REPO, GITHUB_BRANCH, path)
    local separator = baseUrl:find("%?") and "&" or "?"
    local cacheBustedUrl = string.format("%s%snocache=%d%d", baseUrl, separator, os.time(), math.random(100000, 999999))

    local success, content = pcall(function()
        return game:HttpGet(cacheBustedUrl)
    end)

    if success and content and content ~= "404: Not Found" and not content:find("^404: Not Found") then
        return content
    end
    return nil
end

getgenv().flags = function()
    if getgenv().Library and getgenv().Library.Flags then
        return getgenv().Library.Flags
    end
    return {}
end

local uiLibraryContent = fetchFile("uilibrary.lua")
if not uiLibraryContent then
    error("[publichook] Critical Error: Failed to fetch UI Library from GitHub. Verify repository settings.")
end

local Library = loadstring(uiLibraryContent)()
if not Library then
    error("[publichook] Critical Error: Failed to initialize UI Library.")
end

local MarketplaceService = game:GetService("MarketplaceService")
local success, productInfo = pcall(function()
    return MarketplaceService:GetProductInfo(game.PlaceId)
end)
local gameName = "Universal"
if success and productInfo and productInfo.Name then
    gameName = productInfo.Name
end

local gameId = tostring(game.GameId)
print("[publichook] Initializing loader for Game ID: " .. gameId)

local configContent = fetchFile("gameconfigs/" .. gameId .. ".lua")
if not configContent or configContent == "" then
    print("[publichook] Specific game config not found. Falling back to universal config.")
    configContent = fetchFile("gameconfigs/universal.lua")
end

if not configContent then
    error("[publichook] Critical Error: Failed to retrieve universal configuration. Please verify your repository folders and file spelling.")
end

local configFunc, compileErr = loadstring(configContent, "=config")
if not configFunc then
    error("[publichook] Configuration compile error: " .. tostring(compileErr))
end

local execSuccess, configTable = pcall(configFunc)
if not execSuccess then
    error("[publichook] Configuration runtime execution error: " .. tostring(configTable))
end

if type(configTable) ~= "table" then
    error("[publichook] Configuration file did not return a valid table (returned type: " .. type(configTable) .. "). Ensure you have 'return Config' at the bottom of the config file.")
end

local logicContent = fetchFile("gamelogics/" .. gameId .. ".lua")
if not logicContent then
    print("[publichook] Specific game logic not found. Falling back to universal logic.")
    logicContent = fetchFile("gamelogics/universal.lua")
end

local function buildUI(config)
    local windowData = config.Window or {}
    local windowSize = windowData.Size or UDim2.new(0, 455, 0, 605)

    local WindowObj = Library:Window({
        Name = "publichook",
        Size = windowSize
    })

    if WindowObj.Items and WindowObj.Items.Title then
        WindowObj.Items.Title.RichText = true
    end

    local coloredTitle = string.format('publichook <font color="#00E676">| %s</font>', gameName)
    WindowObj.ChangeMenuTitle(coloredTitle)

    local PanelObj = WindowObj:Panel({
        Name = gameName,
        Size = windowSize
    })

    if PanelObj.Items and PanelObj.Items.Title then
        PanelObj.Items.Title.RichText = true
        PanelObj.Items.Title.Text = string.format('publichook <font color="#00E676">| %s</font>', gameName)
    end

    if config.Tabs then
        for _, tabData in ipairs(config.Tabs) do
            local TabObj = PanelObj:Tab({
                Name = tabData.Name or "Tab"
            })

            if tabData.Columns and type(tabData.Columns) == "table" then
                for _, colData in ipairs(tabData.Columns) do
                    local ColObj = TabObj:Column({})

                    if colData.Sections and type(colData.Sections) == "table" then
                        for _, secData in ipairs(colData.Sections) do
                            local SecObj = ColObj:Section({
                                Name = secData.Name or "Section",
                                Side = secData.Side or "Left",
                                Size = secData.Size
                            })

                            if secData.Elements and type(secData.Elements) == "table" then
                                for _, elemData in ipairs(secData.Elements) do
                                    local elemType = elemData.Type
                                    local elemObj = nil

                                    if elemType == "Toggle" then
                                        elemObj = SecObj:Toggle({
                                            Name = elemData.Name or "Toggle",
                                            Flag = elemData.Flag,
                                            Default = elemData.Default or false,
                                            Callback = elemData.Callback or function() end,
                                            Tooltip = elemData.Tooltip
                                        })

                                        if elemData.Colorpicker and type(elemData.Colorpicker) == "table" then
                                            elemObj:Colorpicker({
                                                Name = elemData.Colorpicker.Name,
                                                Flag = elemData.Colorpicker.Flag,
                                                Color = elemData.Colorpicker.Color or Color3.fromRGB(255, 255, 255),
                                                Alpha = elemData.Colorpicker.Alpha or elemData.Colorpicker.Transparency or 1,
                                                Callback = elemData.Colorpicker.Callback or function() end
                                            })
                                        end

                                        if elemData.Keybind and type(elemData.Keybind) == "table" then
                                            elemObj:Keybind({
                                                Name = elemData.Keybind.Name,
                                                Flag = elemData.Keybind.Flag,
                                                Key = elemData.Keybind.Key,
                                                Mode = elemData.Keybind.Mode or "Toggle",
                                                Default = elemData.Keybind.Default or false,
                                                ShowInList = elemData.Keybind.ShowInList ~= false,
                                                Callback = elemData.Keybind.Callback or function() end
                                            })
                                        end

                                    elseif elemType == "Slider" then
                                        elemObj = SecObj:Slider({
                                            Name = elemData.Name or "Slider",
                                            Suffix = elemData.Suffix or "",
                                            Flag = elemData.Flag,
                                            Min = elemData.Min or 0,
                                            Max = elemData.Max or 100,
                                            Decimal = elemData.Decimal or 1,
                                            Default = elemData.Default or 50,
                                            Callback = elemData.Callback or function() end
                                        })

                                    elseif elemType == "Dropdown" then
                                        elemObj = SecObj:Dropdown({
                                            Name = elemData.Name or "Dropdown",
                                            Flag = elemData.Flag,
                                            Options = elemData.Options or {},
                                            Default = elemData.Default,
                                            Multi = elemData.Multi or false,
                                            Scrolling = elemData.Scrolling or false,
                                            Size = elemData.Size or elemData.YSize or 100,
                                            Search = elemData.Search or false,
                                            Callback = elemData.Callback or function() end
                                        })

                                    elseif elemType == "Textbox" then
                                        elemObj = SecObj:Textbox({
                                            Name = elemData.Name or "Textbox",
                                            PlaceHolder = elemData.PlaceHolder or elemData.HolderText or "Type here...",
                                            ClearTextOnFocus = elemData.ClearTextOnFocus or false,
                                            Default = elemData.Default or "",
                                            Flag = elemData.Flag,
                                            Callback = elemData.Callback or function() end
                                        })

                                    elseif elemType == "Button" then
                                        elemObj = SecObj:Button({
                                            Name = elemData.Name or "Button",
                                            Callback = elemData.Callback or function() end
                                        })

                                    elseif elemType == "Keybind" then
                                        elemObj = SecObj:Keybind({
                                            Name = elemData.Name or "Keybind",
                                            Flag = elemData.Flag,
                                            Key = elemData.Key,
                                            Mode = elemData.Mode or "Toggle",
                                            Default = elemData.Default or false,
                                            ShowInList = elemData.ShowInList ~= false,
                                            Callback = elemData.Callback or function() end
                                        })

                                    elseif elemType == "Colorpicker" then
                                        elemObj = SecObj:Colorpicker({
                                            Name = elemData.Name or "Colorpicker",
                                            Flag = elemData.Flag,
                                            Color = elemData.Color or Color3.fromRGB(255, 255, 255),
                                            Alpha = elemData.Alpha or elemData.Transparency or 1,
                                            Callback = elemData.Callback or function() end
                                        })

                                    elseif elemType == "Label" then
                                        elemObj = SecObj:Label({
                                            Name = elemData.Name or elemData.Text or ""
                                        })
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    if config.ConfigsTab and config.ConfigsTab.TabName then
        local ConfigTab = PanelObj:Tab({
            Name = config.ConfigsTab.TabName
        })
        Library:Configs(WindowObj, ConfigTab)
    end

    return WindowObj
end

local Window = buildUI(configTable)

if logicContent then
    local logicFunction, compileErr = loadstring(logicContent)
    if logicFunction then
        task.spawn(function()
            local success, runErr = pcall(logicFunction)
            if not success then
                warn("[publichook] Gameplay logic runtime error: " .. tostring(runErr))
            end
        end)
    else
        warn("[publichook] Gameplay logic compile error: " .. tostring(compileErr))
    end
else
    print("[publichook] No gameplay logic file loaded.")
end
