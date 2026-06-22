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
        local show = isEnemy(player, true) and alive

        -- Chams (not affected by wall check — only alive check)
        if espOn and showChams and show then
            obj.highlight.Adornee = char
            obj.highlight.FillColor = chamsColor
            obj.highlight.FillTransparency = chamsAlpha
            obj.highlight.Enabled = true
        else
            obj.highlight.Enabled = false
        end

        if not espOn or not show then
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

-- ─── SILENT AIM ─────────────────────────────────────────────────────────────

do
    local saFOVCircle = Drawing.new("Circle")
    saFOVCircle.Thickness  = 1
    saFOVCircle.Color      = Color3.fromRGB(255, 100, 100)
    saFOVCircle.Filled     = false
    saFOVCircle.Visible    = false
    saFOVCircle.NumSides   = 64

    -- Sync config to camera attributes every frame + draw FOV circle
    RunService.RenderStepped:Connect(function()
        local f = flags()

        if f.SilentAimFOVCircle then
            local cd = f.SilentAimFOVCircleColor
            saFOVCircle.Color    = cd and cd.Color or Color3.fromRGB(255, 100, 100)
            saFOVCircle.Radius   = f.SilentAimFOV or 200
            saFOVCircle.Position = getMousePos()
            saFOVCircle.Visible  = true
        else
            saFOVCircle.Visible = false
        end

        Camera:SetAttribute("BN_SilentAim", f.SilentAim or false)
        Camera:SetAttribute("BN_FOV", f.SilentAimFOV or 200)
        Camera:SetAttribute("BN_HitPart", f.SilentAimHitPart or "Head")
        Camera:SetAttribute("BN_WallCheck", f.WallCheck or false)
    end)

    -- Actor-based hook (only run once)
    if not getgenv().__SilentAimHooked then
        getgenv().__SilentAimHooked = true

        local actorOk = pcall(function()
            if not (getactors and run_on_actor) then
                error("executor lacks actor support (getactors/run_on_actor)")
            end
            local actors = getactors()
            local actor = actors and actors[1]
            if not actor then
                error("no actors available")
            end

            run_on_actor(actor, [==[
                local players = game:GetService("Players")
                local input_service = game:GetService("UserInputService")
                local local_player = players.LocalPlayer
                local camera = workspace.CurrentCamera

                local function cfg(name, default)
                    local v = camera:GetAttribute(name)
                    if v == nil then return default end
                    return v
                end

                local function get_closest_target()
                    if not cfg("BN_SilentAim", false) then return nil end

                    local fov = cfg("BN_FOV", 200)
                    local hitpart = cfg("BN_HitPart", "Head")
                    local wallcheck = cfg("BN_WallCheck", false)

                    local closest_part = nil
                    local closest_distance = fov
                    local local_team = local_player.Team
                    local mouse_location = input_service:GetMouseLocation()
                    local cam_pos = camera.CFrame.Position

                    for _, player in players:GetPlayers() do
                        if player == local_player then continue end
                        if local_team and player.Team == local_team then continue end

                        local character = player.Character
                        if not character then continue end

                        local part = character:FindFirstChild(hitpart) or character:FindFirstChild("Head")
                        if not part then continue end

                        local nrpbs = player:FindFirstChild("NRPBS")
                        if not nrpbs then continue end
                        local health = nrpbs:FindFirstChild("Health")
                        if not health or health.Value <= 0 then continue end

                        local screen_pos, on_screen = camera:WorldToViewportPoint(part.Position)
                        if not on_screen then continue end

                        local distance = (Vector2.new(screen_pos.X, screen_pos.Y) - mouse_location).Magnitude
                        if distance < closest_distance then
                            if wallcheck then
                                local params = RaycastParams.new()
                                params.FilterType = Enum.RaycastFilterType.Exclude
                                params.FilterDescendantsInstances = { character, local_player.Character }
                                params.IgnoreWater = true
                                pcall(function() params.RespectCanCollide = true end)
                                local dir = part.Position - cam_pos
                                local result = workspace:Raycast(cam_pos, dir, params)
                                if result then
                                    continue
                                end
                            end
                            closest_distance = distance
                            closest_part = part
                        end
                    end

                    return closest_part
                end

                local old_index
                old_index = hookmetamethod(game, "__index", newcclosure(function(self, index)
                    if self == camera and index == "CoordinateFrame" then
                        local source = debug.info(3, "s")
                        local name = debug.info(3, "n")
                        if source and string.find(source, "First") and name ~= "RotCamera" then
                            local info = debug.getinfo(3)
                            if info and info.nups == 35 then
                                local hit_part = get_closest_target()
                                if hit_part then
                                    return CFrame.new(camera.CFrame.Position, hit_part.Position)
                                end
                            end
                        end
                    end
                    return old_index(self, index)
                end))
            ]==])
        end)

        if not actorOk then
            warn("[publichook] Silent Aim: actor hook failed, falling back to main thread hook")
            local oldIndex
            oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, index)
                if flags().SilentAim and self == Camera and index == "CoordinateFrame" then
                    local source = debug.info(3, "s") or ""
                    if string.match(source, "Client.Functions.Weapons") and debug.info(debug.info(3, "f"), "n") ~= "RotCamera" then
                        local mousePos = getMousePos()
                        local f = flags()
                        local best, bestDist = nil, f.SilentAimFOV or 200
                        for _, p in ipairs(Players:GetPlayers()) do
                            if not isEnemy(p) then continue end
                            local part = getAimPart(p, "SilentAimHitPart")
                            if not part then continue end
                            local sp, inView = Camera:WorldToViewportPoint(part.Position)
                            if not inView or sp.Z <= 0 then continue end
                            local d = (Vector2.new(sp.X, sp.Y) - mousePos).Magnitude
                            if d < bestDist then best, bestDist = part, d end
                        end
                        if best then
                            return CFrame.new(Camera.CFrame.Position, best.Position)
                        end
                    end
                end
                return oldIndex(self, index)
            end))
        end
    end
end

-- ─── FLY ───────────────────────────────────────────────────────────────────

do
    local flying = false
    local speed = 50
    local bodyGyro, bodyVelocity

    function startFly()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        bodyGyro = Instance.new("BodyGyro")
        bodyGyro.P = 9e4
        bodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        bodyGyro.CFrame = hrp.CFrame
        bodyGyro.Parent = hrp

        bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.Velocity = Vector3.zero
        bodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        bodyVelocity.Parent = hrp

        flying = true

        RunService:BindToRenderStep("Fly", Enum.RenderPriority.Character.Value, function()
            local cam = workspace.CurrentCamera
            local moveVec = Vector3.zero

            if UIS:IsKeyDown(Enum.KeyCode.W) then
                moveVec += cam.CFrame.LookVector
            end
            if UIS:IsKeyDown(Enum.KeyCode.S) then
                moveVec -= cam.CFrame.LookVector
            end
            if UIS:IsKeyDown(Enum.KeyCode.A) then
                moveVec -= cam.CFrame.RightVector
            end
            if UIS:IsKeyDown(Enum.KeyCode.D) then
                moveVec += cam.CFrame.RightVector
            end
            if UIS:IsKeyDown(Enum.KeyCode.Space) then
                moveVec += Vector3.new(0, 1, 0)
            end
            if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
                moveVec -= Vector3.new(0, 1, 0)
            end

            if moveVec.Magnitude > 0 then
                moveVec = moveVec.Unit * speed
            end

            bodyVelocity.Velocity = moveVec
            bodyGyro.CFrame = cam.CFrame
        end)
    end

    function stopFly()
        flying = false
        RunService:UnbindFromRenderStep("Fly")

        if bodyGyro then bodyGyro:Destroy() end
        if bodyVelocity then bodyVelocity:Destroy() end
    end

    task.spawn(function()
        local wasActive = false
        while task.wait() do
            local f = flags()
            local bind = f.FlyBind
            if not bind or not f.Fly then
                if flying then stopFly() end
                wasActive = false
                continue
            end
            if bind.Active and not wasActive then
                if not flying then startFly() end
            elseif wasActive and not bind.Active then
                if flying then stopFly() end
            end
            wasActive = bind.Active
        end
    end)
end
