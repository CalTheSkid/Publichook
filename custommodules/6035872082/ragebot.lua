--[[
    Ragebot — auto-targets and auto-shoots through walls/cover.
    Enabled via flags().RivalsRagebot
]]
return function()
    local rs = game:GetService("ReplicatedStorage")
    local players = game:GetService("Players")
    local workspace = game:GetService("Workspace")
    local lplr = players.LocalPlayer

    local enums = require(rs.Modules.EnumLibrary)
    local fighter = require(lplr.PlayerScripts.Controllers.FighterController)

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.IgnoreWater = true

    local heights = {0, 12, 16, 20, 24, 28, 32, 36, 40, 50, 60, 75, 90, 115, 130, 145, 160, 175, 190, 205, 220, 235, 250, 275}

    local function findTarget()
        local c = lplr.Character
        if not c or not c:FindFirstChild("HumanoidRootPart") then return nil end
        local best, bestd = nil, 9e9
        for _, p in ipairs(players:GetPlayers()) do
            if p ~= lplr and p.Character and p.Character:FindFirstChild("Head") then
                local d = (c.HumanoidRootPart.Position - p.Character.Head.Position).Magnitude
                if d < bestd then bestd = d; best = p.Character.Head end
            end
        end
        return best
    end

    local function findShootPos(from, to, char)
        params.FilterDescendantsInstances = {lplr.Character, char}

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

    local function buildData(pos, target)
        local t = target.Position
        local l = CFrame.lookAt(pos, t)
        local x, y, z = l:ToOrientation()
        local e = {[utf8.char(0)] = pos.X, [utf8.char(1)] = pos.Y, [utf8.char(2)] = pos.Z, [utf8.char(3)] = x, [utf8.char(4)] = y, [utf8.char(5)] = z}
        local o = target.CFrame:ToObjectSpace(CFrame.new(t))
        local a, b, c = o:ToOrientation()
        return {[utf8.char(1)] = {[utf8.char(0)] = e, [utf8.char(1)] = e, [utf8.char(2)] = target, [utf8.char(3)] = {[utf8.char(0)] = o.X, [utf8.char(1)] = o.Y, [utf8.char(2)] = o.Z, [utf8.char(3)] = a, [utf8.char(4)] = b, [utf8.char(5)] = c}}}
    end

    task.spawn(function()
        while task.wait(0.1) do
            if not flags().RivalsRagebot then continue end

            local f = fighter.LocalFighter
            if not f then continue end

            local i = f.EquippedItem
            if not i or not i.Info then continue end
            if (i:Get("Ammo") or 0) <= 0 then continue end
            if i._shoot_cooldown and tick() < i._shoot_cooldown then continue end

            local t = findTarget()
            if not t then continue end

            local cam = workspace.CurrentCamera
            if not cam then continue end

            local sp = findShootPos(cam.CFrame.Position, t.Position, t.Parent)
            if not sp then continue end

            local oid = i:Get("ObjectID")
            if not oid then continue end

            local se = enums:ToEnum("StartShooting")
            if not se then continue end

            rs.Remotes.Replication.Fighter.UseItem:FireServer(oid, se, buildData(sp, t), nil)
        end
    end)
end