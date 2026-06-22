local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS        = game:GetService("UserInputService")
local Camera     = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

print("[publichook] Arsenal logic loaded.")

-- ─── HELPERS ────────────────────────────────────────────────────────────────

local function getColor(flag, default)
    local f = flags()[flag]
    if f and f.Color then return f.Color end
    return default or Color3.fromRGB(255, 255, 255)
end

local function newDrawing(kind, props)
    local d = Drawing.new(kind)
    for k, v in pairs(props) do d[k] = v end
    return d
end

local function w2s(pos)
    local screen, inView = Camera:WorldToViewportPoint(pos)
    if not inView or screen.Z <= 0 then return nil end
    return Vector2.new(screen.X, screen.Y), screen.Z
end

local function getBoundingBox(char)
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    local head = char:FindFirstChild("Head")
    local top = head and head.Position + Vector3.new(0, head.Size.Y / 2 + 0.1, 0)
             or root.Position + Vector3.new(0, 3, 0)
    local bottom = root.Position - Vector3.new(0, 3, 0)
    local topScreen, dist = w2s(top)
    local bottomScreen    = w2s(bottom)
    if not topScreen or not bottomScreen then return nil end
    local height = math.abs(bottomScreen.Y - topScreen.Y)
    local width  = height * 0.6
    local cx     = topScreen.X
    return {
        tl     = Vector2.new(cx - width/2, topScreen.Y),
        tr     = Vector2.new(cx + width/2, topScreen.Y),
        bl     = Vector2.new(cx - width/2, bottomScreen.Y),
        br     = Vector2.new(cx + width/2, bottomScreen.Y),
        center = Vector2.new(cx, topScreen.Y),
        bottom = bottomScreen,
        dist   = dist,
        height = height,
    }
end

-- Raycast from camera to target — returns false if something opaque blocks the view
local function hasLineOfSight(targetPos)
    local origin  = Camera.CFrame.Position
    local delta   = targetPos - origin
    local dir     = delta.Unit
    local dist    = delta.Magnitude

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = { LocalPlayer.Character, Camera }

    local result = workspace:Raycast(origin, dir * dist, params)
    if not result then return true end

    local hitModel = result.Instance:FindFirstAncestorOfClass("Model")
    if hitModel and hitModel:FindFirstChildOfClass("Humanoid") then
        return true
    end
    return false
end

-- Returns true if player should be targeted/shown (team check, alive check,
-- wall check, distance check — evaluated every call for continuous validation)
local function isEnemy(player, skipCombatChecks)
    if not player or not player.Parent then return false end
    if player == LocalPlayer then return false end
    local f = flags()

    -- Alive check
    if f.AliveCheck then
        local char = player.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then return false end
    end

    -- Team check
    if f.TeamCheck then
        local myTeam    = LocalPlayer.Team
        local theirTeam = player.Team
        if myTeam and theirTeam and myTeam == theirTeam then return false end
    end

    -- These checks are for combat (aimbot/silent aim) — skip for ESP
    if not skipCombatChecks then
        -- Global distance check
        local maxDist = f.MaxAimDistance or 1000
        if maxDist > 0 then
            local char = player.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if root then
                local d = (root.Position - Camera.CFrame.Position).Magnitude
                if d > maxDist then return false end
            end
        end

        -- Wall check
        if f.WallCheck then
            local char = player.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if root and not hasLineOfSight(root.Position) then return false end
        end
    end

    return true
end

-- Get the aim part for a player based on the specified hit part flag
local function getAimPart(player, flag)
    local char = player and player.Character
    if not char then return nil end
    local hitPart = (flags()[flag or "AimbotHitPart"] or "Head")
    return char:FindFirstChild(hitPart)
        or char:FindFirstChild("Head")
        or char:FindFirstChild("HumanoidRootPart")
end

local function getMousePos()
    local pos = UIS:GetMouseLocation()
    return Vector2.new(pos.X, pos.Y)
end

-- ─── ESP ────────────────────────────────────────────────────────────────────

local espObjects = {}

local function createEspFor(player)
    if player == LocalPlayer then return end
    if espObjects[player] then return end
    local obj = {}

    obj.boxLines = {}
    for i = 1, 4 do
        obj.boxLines[i] = newDrawing("Line", {
            Thickness = 1, Color = Color3.fromRGB(255,255,255),
            Transparency = 1, Visible = false,
        })
    end

    obj.nameTag = newDrawing("Text", {
        Size = 13, Color = Color3.fromRGB(255,255,255),
        Outline = true, OutlineColor = Color3.fromRGB(0,0,0),
        Center = true, Visible = false, Text = player.Name,
    })

    obj.distTag = newDrawing("Text", {
        Size = 11, Color = Color3.fromRGB(200,200,200),
        Outline = true, OutlineColor = Color3.fromRGB(0,0,0),
        Center = true, Visible = false, Text = "",
    })

    obj.healthBg = newDrawing("Line", {
        Thickness = 4, Color = Color3.fromRGB(0,0,0),
        Transparency = 0.5, Visible = false,
    })
    obj.healthBar = newDrawing("Line", {
        Thickness = 3, Color = Color3.fromRGB(0,255,0),
        Transparency = 1, Visible = false,
    })

    obj.highlight = Instance.new("Highlight")
    obj.highlight.FillTransparency   = 0.5
    obj.highlight.OutlineTransparency = 1
    obj.highlight.Enabled = false
    obj.highlight.Parent  = game:GetService("CoreGui")

    espObjects[player] = obj
end

local function removeEspFor(player)
    local obj = espObjects[player]
    if not obj then return end
    for _, l in ipairs(obj.boxLines or {}) do pcall(function() l:Remove() end) end
    for _, k in ipairs({"nameTag","distTag","healthBg","healthBar"}) do
        pcall(function() obj[k]:Remove() end)
    end
    pcall(function() obj.highlight:Destroy() end)
    espObjects[player] = nil
end

for _, p in ipairs(Players:GetPlayers()) do createEspFor(p) end
Players.PlayerAdded:Connect(createEspFor)
Players.PlayerRemoving:Connect(removeEspFor)

RunService.RenderStepped:Connect(function()
    local f         = flags()
    local espOn     = f.ESPEnabled    or false
    local showBox   = f.ESPBoxes      or false
    local showName  = f.ESPName       or false
    local showDist  = f.ESPDistance   or false
    local showHP    = f.ESPHealthBar  or false
    local showChams = f.ESPChams      or false
    local maxDist   = f.ESPMaxDist    or 2000

    local boxColor  = getColor("ESPBoxColor",      Color3.fromRGB(255,255,255))
    local nameColor = getColor("ESPNameColor",     Color3.fromRGB(255,255,255))
    local distColor = getColor("ESPDistanceColor", Color3.fromRGB(200,200,200))
    local chamsColorData = f.ESPChamsColor
    local chamsColor = chamsColorData and chamsColorData.Color or Color3.fromRGB(255,0,0)
    local chamsAlpha = chamsColorData and chamsColorData.Transparency or 0.5

    for player, obj in pairs(espObjects) do
        local char = player.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        local alive = hum and hum.Health > 0

        -- Chams (not affected by wall check — only alive check)
        if espOn and showChams and alive then
            obj.highlight.Adornee = char
            obj.highlight.FillColor = chamsColor
            obj.highlight.FillTransparency = chamsAlpha
            obj.highlight.Enabled = true
        else
            obj.highlight.Enabled = false
        end

        if not espOn or not alive then
            for _, l in ipairs(obj.boxLines) do l.Visible = false end
            obj.nameTag.Visible = false
            obj.distTag.Visible = false
            obj.healthBg.Visible = false
            obj.healthBar.Visible = false
            continue
        end

        local bb = getBoundingBox(char)
        if not bb or bb.dist > maxDist then
            for _, l in ipairs(obj.boxLines) do l.Visible = false end
            obj.nameTag.Visible = false
            obj.distTag.Visible = false
            obj.healthBg.Visible = false
            obj.healthBar.Visible = false
            continue
        end

        -- Box
        if showBox then
            local lines = obj.boxLines
            local tl, tr, bl, br = bb.tl, bb.tr, bb.bl, bb.br
            lines[1].From = tl  lines[1].To = tr
            lines[2].From = bl  lines[2].To = br
            lines[3].From = tl  lines[3].To = bl
            lines[4].From = tr  lines[4].To = br
            for _, l in ipairs(lines) do
                l.Color = boxColor
                l.Visible = true
            end
        else
            for _, l in ipairs(obj.boxLines) do l.Visible = false end
        end

        -- Name
        if showName then
            obj.nameTag.Text = player.Name
            obj.nameTag.Position = bb.center + Vector2.new(0, -3)
            obj.nameTag.Color = nameColor
            obj.nameTag.Visible = true
        else
            obj.nameTag.Visible = false
        end

        -- Distance
        if showDist then
            obj.distTag.Text = math.floor(bb.dist) .. "m"
            obj.distTag.Position = bb.bottom + Vector2.new(0, 3)
            obj.distTag.Color = distColor
            obj.distTag.Visible = true
        else
            obj.distTag.Visible = false
        end

        -- Health bar
        if showHP then
            local hp = hum.Health
            local maxHp = hum.MaxHealth
            local pct  = maxHp > 0 and math.clamp(hp / maxHp, 0, 1) or 0
            local barX = bb.tl.X - 5
            local barTop = bb.tl.Y
            local barBottom = bb.bl.Y
            local barFill  = barTop + (barBottom - barTop) * (1 - pct)
            local g = pct * 255
            local r = (1 - pct) * 255
            local hpColor = Color3.fromRGB(r, g, 0)
            obj.healthBg.From    = Vector2.new(barX, barTop)
            obj.healthBg.To      = Vector2.new(barX, barBottom)
            obj.healthBg.Visible = true
            obj.healthBar.From   = Vector2.new(barX, barFill)
            obj.healthBar.To     = Vector2.new(barX, barBottom)
            obj.healthBar.Color  = hpColor
            obj.healthBar.Visible = true
        else
            obj.healthBg.Visible = false
            obj.healthBar.Visible = false
        end
    end
end)

-- ─── WALKSPEED ──────────────────────────────────────────────────────────────

task.spawn(function()
    while task.wait(0.1) do
        local char = LocalPlayer.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if not hum then continue end

        local speed = flags().MovementWalkSpeed or 16
        local mode  = flags().MovementWSMode or "Humanoid"

        if speed > 16 then
            if mode == "Humanoid" then
                hum.WalkSpeed = speed
            elseif mode == "Velocity" then
                local root = char:FindFirstChild("HumanoidRootPart")
                if root and hum.MoveDirection.Magnitude > 0 then
                    root.AssemblyLinearVelocity = Vector3.new(
                        hum.MoveDirection.X * speed,
                        root.AssemblyLinearVelocity.Y,
                        hum.MoveDirection.Z * speed
                    )
                end
            end
        end
    end
end)

-- ─── AIMBOT ─────────────────────────────────────────────────────────────────

do
    local lockedPlayer  = nil
    local bindWasActive = false

    local fovCircle = Drawing.new("Circle")
    fovCircle.Thickness  = 1
    fovCircle.Color      = Color3.fromRGB(255, 255, 255)
    fovCircle.Filled     = false
    fovCircle.Visible    = false
    fovCircle.NumSides   = 64

    local function pickTarget(fov, mode)
        local mousePos = getMousePos()
        local best, bestVal = nil, math.huge
        for _, p in ipairs(Players:GetPlayers()) do
            if not isEnemy(p) then continue end
            local part = getAimPart(p, "AimbotHitPart")
            if not part then continue end
            local sp, inView = Camera:WorldToViewportPoint(part.Position)
            if not inView or sp.Z <= 0 then continue end
            local d2 = (Vector2.new(sp.X, sp.Y) - mousePos).Magnitude
            if d2 > fov then continue end
            local val
            if mode == "Health" then
                val = p.Character:FindFirstChildOfClass("Humanoid").Health
            elseif mode == "Distance" then
                val = (part.Position - Camera.CFrame.Position).Magnitude
            else
                val = d2
            end
            if val < bestVal then best, bestVal = p, val end
        end
        return best
    end

    local function isInFOV(player, fov)
        local part = getAimPart(player, "AimbotHitPart")
        if not part then return false end
        local sp, inView = Camera:WorldToViewportPoint(part.Position)
        if not inView or sp.Z <= 0 then return false end
        local mousePos = getMousePos()
        return (Vector2.new(sp.X, sp.Y) - mousePos).Magnitude <= fov
    end

    RunService:BindToRenderStep("publichook_aimbot", Enum.RenderPriority.Camera.Value + 1, function()
        local f = flags()

        -- FOV circle
        local showCircle = f.AimbotFOVCircle or false
        if showCircle then
            local circleColor = f.AimbotFOVCircleColor
            fovCircle.Color    = circleColor and circleColor.Color or Color3.fromRGB(255, 255, 255)
            fovCircle.Radius   = f.AimbotFOVRadius or 120
            fovCircle.Position = getMousePos()
            fovCircle.Visible  = true
        else
            fovCircle.Visible = false
        end

        local bind = f.AimbotBind
        local bindMode = bind and bind.Mode or "Toggle"

        local active = false
        if bindMode == "Hold" then
            if bind and bind.Key and bind.Key ~= "NONE" then
                local ok, held = pcall(function() return UIS:IsKeyDown(bind.Key) end)
                active = ok and held or false
            end
        else
            if not f.AimbotEnabled then
                lockedPlayer  = nil
                bindWasActive = false
                return
            end
            if bind and bind.Key and bind.Key ~= "NONE" then
                active = bind.Active or false
            end
        end

        if not active then
            lockedPlayer  = nil
            bindWasActive = false
            return
        end

        local fov    = f.AimbotFOVRadius or 120
        local mode   = f.AimbotTargetMode or "FOV"
        local smooth = f.AimbotSmooth or 20
        local alpha  = 1 - ((smooth - 1) / 99 * 0.95)
        local hardLock = f.AimbotHardLock or false

        -- Fresh press → pick a new target
        if not bindWasActive then
            lockedPlayer  = pickTarget(fov, mode)
            bindWasActive = true
        end

        -- Every frame: re-validate the target (alive, team, wall, distance)
        -- If target fails any check, drop them
        if lockedPlayer and not isEnemy(lockedPlayer) then
            lockedPlayer = nil
        end

        -- Soft lock: drop if left FOV
        if not hardLock and lockedPlayer and not isInFOV(lockedPlayer, fov) then
            lockedPlayer = nil
        end

        -- If we lost the target, try to pick a new one
        if not lockedPlayer then
            lockedPlayer = pickTarget(fov, mode)
        end

        local part = getAimPart(lockedPlayer, "AimbotHitPart")
        if not part then return end

        local targetCF = CFrame.new(Camera.CFrame.Position, part.Position)
        Camera.CFrame  = Camera.CFrame:Lerp(targetCF, alpha)
    end)
end

-- ─── SILENT AIM (mouse.Hit index hook) ─────────────────────────────────────

do
    local cachedSilentTarget = nil

    local saFOVCircle = Drawing.new("Circle")
    saFOVCircle.Thickness  = 1
    saFOVCircle.Color      = Color3.fromRGB(255, 100, 100)
    saFOVCircle.Filled     = false
    saFOVCircle.Visible    = false
    saFOVCircle.NumSides   = 64

    local function pickSilentTarget(fov, mode)
        local mousePos = getMousePos()
        local best, bestVal = nil, math.huge
        for _, p in ipairs(Players:GetPlayers()) do
            if not isEnemy(p) then continue end
            local part = getAimPart(p, "SilentAimHitPart")
            if not part then continue end
            local sp, inView = Camera:WorldToViewportPoint(part.Position)
            if not inView or sp.Z <= 0 then continue end
            local d2 = (Vector2.new(sp.X, sp.Y) - mousePos).Magnitude
            if d2 > fov then continue end
            local val
            if mode == "Health" then
                val = p.Character:FindFirstChildOfClass("Humanoid").Health
            elseif mode == "Distance" then
                val = (part.Position - Camera.CFrame.Position).Magnitude
            else
                val = d2
            end
            if val < bestVal then best, bestVal = part, val end
        end
        return best
    end

    -- Update cached target every frame
    RunService.RenderStepped:Connect(function()
        local f = flags()

        -- FOV circle
        if f.SilentAimFOVCircle then
            local cd = f.SilentAimFOVCircleColor
            saFOVCircle.Color    = cd and cd.Color or Color3.fromRGB(255, 100, 100)
            saFOVCircle.Radius   = f.SilentAimFOV or 200
            saFOVCircle.Position = getMousePos()
            saFOVCircle.Visible  = true
        else
            saFOVCircle.Visible = false
        end

        if not f.SilentAim then
            cachedSilentTarget = nil
            return
        end

        local fov  = f.SilentAimFOV or 200
        local mode = f.SilentAimTargetMode or "FOV"

        -- Every frame: validate the cached target (alive, team, wall, distance)
        if cachedSilentTarget then
            local player = Players:GetPlayerFromCharacter(cachedSilentTarget:FindFirstAncestorOfClass("Model"))
            if not player or not isEnemy(player) then
                cachedSilentTarget = nil
            end
        end

        -- Drop if left FOV
        if cachedSilentTarget then
            local sp, inView = Camera:WorldToViewportPoint(cachedSilentTarget.Position)
            if not inView or sp.Z <= 0 then
                cachedSilentTarget = nil
            elseif (Vector2.new(sp.X, sp.Y) - getMousePos()).Magnitude > fov then
                cachedSilentTarget = nil
            end
        end

        -- Pick a new target if needed
        if not cachedSilentTarget then
            cachedSilentTarget = pickSilentTarget(fov, mode)
        end
    end)

    -- Hook mouse.Hit via __index on the Mouse metatable
    if not getgenv().__SilentAimHooked then
        getgenv().__SilentAimHooked = true

        local mouse = LocalPlayer:GetMouse()
        local mt    = getrawmetatable(mouse)
        local oldIndex = rawget(mt, "__index")

        local proxy = setmetatable({}, { __index = mt })
        proxy.__index = function(self, key)
            if key == "Hit" and flags().SilentAim and cachedSilentTarget then
                return CFrame.new(Camera.CFrame.Position, cachedSilentTarget.Position)
            end
            return oldIndex(self, key)
        end

        setrawmetatable(mouse, proxy)
    end
end
