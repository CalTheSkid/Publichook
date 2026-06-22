--[[
    Wallbang — raises the shoot position until line of sight is clear.
    Works with normal firing or Silent Aim.
    Enabled via flags().RivalsWallbang
]]
return function()
    local rs = game:GetService("ReplicatedStorage")
    local players = game:GetService("Players")
    local workspace = game:GetService("Workspace")
    local lplr = players.LocalPlayer

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.IgnoreWater = true

    local heights = {0, 12, 16, 20, 24, 28, 32, 36, 40, 50, 60, 75, 90, 115, 130, 145, 160, 175, 190, 205, 220, 235, 250, 275}

    local function findShootPos(from, to, excludeChar)
        params.FilterDescendantsInstances = {lplr.Character, excludeChar}
        if not workspace:Raycast(from, to - from, params) then
            return from
        end
        for _, h in ipairs(heights) do
            local p = from + Vector3.new(0, h, 0)
            if not workspace:Raycast(p, to - p, params) then
                return p
            end
        end
        return nil
    end

    if getgenv().__RivalsWallbangHooked then return end
    getgenv().__RivalsWallbangHooked = true

    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        if getnamecallmethod() == "FireServer" and self == rs.Remotes.Replication.Fighter.UseItem then
            local f = flags()
            if f.RivalsWallbang then
                local args = {...}
                local data = args[3]
                if data and type(data) == "table" then
                    local inner = data[utf8.char(1)]
                    if inner then
                        local posData = inner[utf8.char(0)]
                        local targetPart = inner[utf8.char(2)]
                        if posData and targetPart then
                            local from = Vector3.new(posData[utf8.char(0)], posData[utf8.char(1)], posData[utf8.char(2)])
                            local to = targetPart.Position
                            local sp = findShootPos(from, to, targetPart.Parent)
                            if sp then
                                posData[utf8.char(0)] = sp.X
                                posData[utf8.char(1)] = sp.Y
                                posData[utf8.char(2)] = sp.Z
                                local innerCopy = inner[utf8.char(1)]
                                if innerCopy then
                                    innerCopy[utf8.char(0)] = sp.X
                                    innerCopy[utf8.char(1)] = sp.Y
                                    innerCopy[utf8.char(2)] = sp.Z
                                end
                            end
                        end
                    end
                end
                return oldNamecall(self, unpack(args))
            end
        end
        return oldNamecall(self, ...)
    end)
end