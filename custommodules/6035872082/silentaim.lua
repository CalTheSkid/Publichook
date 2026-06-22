--[[
    Silent Aim — redirects shots to nearest target within FOV.
    You still fire manually; the remote data is modified to aim at the target.
    Settings: FOV radius, Hit Part
    Enabled via flags().RivalsSilentAim
]]
return function()
    local rs = game:GetService("ReplicatedStorage")
    local players = game:GetService("Players")
    local workspace = game:GetService("Workspace")
    local lplr = players.LocalPlayer

    local function findTarget(fov, hitPart)
        local camera = workspace.CurrentCamera
        local center = camera.ViewportSize / 2
        local best, bestd = nil, fov
        for _, p in ipairs(players:GetPlayers()) do
            if p == lplr then continue end
            local char = p.Character
            if not char then continue end
            local hum = char:FindFirstChildOfClass("Humanoid")
            if not hum or hum.Health <= 0 then continue end
            local part = char:FindFirstChild(hitPart or "Head") or char:FindFirstChild("HumanoidRootPart")
            if not part then continue end
            local sp, inView = camera:WorldToViewportPoint(part.Position)
            if not inView then continue end
            local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
            if d < bestd then bestd = d; best = part end
        end
        return best
    end

    if getgenv().__RivalsSilentAimHooked then return end
    getgenv().__RivalsSilentAimHooked = true

    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        if getnamecallmethod() == "FireServer" and self == rs.Remotes.Replication.Fighter.UseItem then
            local f = flags()
            if f.RivalsSilentAim then
                local args = {...}
                local data = args[3]
                if data and type(data) == "table" then
                    local target = findTarget(f.RivalsSilentAimFOV or 360, f.RivalsSilentAimHitPart or "Head")
                    if target then
                        local inner = data[utf8.char(1)]
                        if inner then
                            local posData = inner[utf8.char(0)]
                            if posData then
                                local from = Vector3.new(posData[utf8.char(0)], posData[utf8.char(1)], posData[utf8.char(2)])
                                local toPt = target.Position
                                local look = CFrame.lookAt(from, toPt)
                                local rx, ry, rz = look:ToOrientation()
                                posData[utf8.char(3)] = rx
                                posData[utf8.char(4)] = ry
                                posData[utf8.char(5)] = rz
                                local innerCopy = inner[utf8.char(1)]
                                if innerCopy then
                                    innerCopy[utf8.char(3)] = rx
                                    innerCopy[utf8.char(4)] = ry
                                    innerCopy[utf8.char(5)] = rz
                                end
                                inner[utf8.char(2)] = target
                                local objSpace = target.CFrame:ToObjectSpace(CFrame.new(toPt))
                                local oa, ob, oc = objSpace:ToOrientation()
                                local targetData = inner[utf8.char(3)]
                                if targetData then
                                    targetData[utf8.char(0)] = objSpace.X
                                    targetData[utf8.char(1)] = objSpace.Y
                                    targetData[utf8.char(2)] = objSpace.Z
                                    targetData[utf8.char(3)] = oa
                                    targetData[utf8.char(4)] = ob
                                    targetData[utf8.char(5)] = oc
                                end
                                args[3] = data
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