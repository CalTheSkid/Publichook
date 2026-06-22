local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS        = game:GetService("UserInputService")
local Camera     = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

print("[publichook] Sniper Arena logic loaded.")

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
    local head   = char:FindFirstChild("Head")
    local top    = head and head.Position + Vector3.new(0, head.Size.Y / 2 + 0.1, 0)
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
    }
end

local function getMousePos()
    local pos = UIS:GetMouseLocation()
    return Vector2.new(pos.X, pos.Y)
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

-- Returns true if player should be targeted/shown
-- Respects TeamCheck and AliveCheck flags globally
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
        -- Distance check
        local maxDist = f.MaxAimDistance
        if maxDist and maxDist > 0 then
            local char = player.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if root and (root.Position - Camera.CFrame.Position).Magnitude > maxDist then
                return false
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
    obj.highlight.FillTransparency     = 0.5
    obj.highlight.OutlineTransparency  = 1
    obj.highlight.Enabled              = false
    obj.highlight.Parent               = game:GetService("CoreGui")

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
    local f        = flags()
    local espOn    = f.ESPEnabled    or false
    local showBox  = f.ESPBoxes      or false
    local showName = f.ESPName       or false
    local showDist = f.ESPDistance   or false
    local showHP   = f.ESPHealthBar  or false
    local showChams= f.ESPChams      or false
    local maxDist  = f.ESPMaxDist    or 2000

    local boxColor     = getColor("ESPBoxColor",        Color3.fromRGB(255,255,255))
    local nameColor    = getColor("ESPNameColor",       Color3.fromRGB(255,255,255))
    local distColor    = getColor("ESPDistanceColor",   Color3.fromRGB(200,200,200))
    local hpHighColor  = getColor("ESPHealthHighColor", Color3.fromRGB(0,255,0))
    local hpLowColor   = getColor("ESPHealthLowColor",  Color3.fromRGB(255,0,0))
    local hpBgColor    = getColor("ESPHealthBgColor",   Color3.fromRGB(0,0,0))
    local chamsData    = f.ESPChamsColor
    local chamsColor   = chamsData and chamsData.Color or Color3.fromRGB(255,0,0)
    local chamsAlpha   = chamsData and chamsData.Transparency or 0.5
    local chamsOutData = f.ESPChamsOutlineColor
    local chamsOutColor= chamsOutData and chamsOutData.Color or Color3.fromRGB(255,255,255)

    for player, obj in pairs(espObjects) do
        local char     = player.Character
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        local alive    = humanoid and humanoid.Health > 0
        local show     = isEnemy(player, true) and alive

        if espOn and showChams and show then
            obj.highlight.Adornee          = char
            obj.highlight.FillColor        = chamsColor
            obj.highlight.FillTransparency = chamsAlpha
            obj.highlight.OutlineColor     = chamsOutColor
            obj.highlight.Enabled          = true
        else
            obj.highlight.Enabled = false
        end

        if not espOn or not show then
            for _, l in ipairs(obj.boxLines) do l.Visible = false end
            obj.nameTag.Visible = false obj.distTag.Visible = false
            obj.healthBg.Visible = false obj.healthBar.Visible = false
            continue
        end

        local bb = getBoundingBox(char)
        if not bb or bb.dist > maxDist then
            for _, l in ipairs(obj.boxLines) do l.Visible = false end
            obj.nameTag.Visible = false obj.distTag.Visible = false
            obj.healthBg.Visible = false obj.healthBar.Visible = false
            continue
        end

        if showBox then
            local L = obj.boxLines
            L[1].From=bb.tl L[1].To=bb.tr L[2].From=bb.bl L[2].To=bb.br
            L[3].From=bb.tl L[3].To=bb.bl L[4].From=bb.tr L[4].To=bb.br
            for _, l in ipairs(L) do l.Color=boxColor l.Visible=true end
        else
            for _, l in ipairs(obj.boxLines) do l.Visible=false end
        end

        if showName then
            obj.nameTag.Text=player.Name obj.nameTag.Position=bb.center+Vector2.new(0,-3)
            obj.nameTag.Color=nameColor  obj.nameTag.Visible=true
        else obj.nameTag.Visible=false end

        if showDist then
            obj.distTag.Text=math.floor(bb.dist).."m"
            obj.distTag.Position=bb.bottom+Vector2.new(0,3)
            obj.distTag.Color=distColor obj.distTag.Visible=true
        else obj.distTag.Visible=false end

        if showHP then
            local pct   = math.clamp(humanoid.Health/math.max(humanoid.MaxHealth,1),0,1)
            local barX  = bb.tl.X-5
            local bTop  = bb.tl.Y  local bBot = bb.bl.Y
            local fill  = bTop+(bBot-bTop)*(1-pct)
            local hpCol = hpLowColor:Lerp(hpHighColor, pct)
            obj.healthBg.From=Vector2.new(barX,bTop) obj.healthBg.To=Vector2.new(barX,bBot)
            obj.healthBg.Color=hpBgColor obj.healthBg.Visible=true
            obj.healthBar.From=Vector2.new(barX,fill) obj.healthBar.To=Vector2.new(barX,bBot)
            obj.healthBar.Color=hpCol obj.healthBar.Visible=true
        else
            obj.healthBg.Visible=false obj.healthBar.Visible=false
        end
    end
end)

-- ─── WALKSPEED KICK BYPASS ───────────────────────────────────────────────────

task.spawn(function()
    local ok, LocalEntity = pcall(require, game:GetService("ReplicatedStorage")
        .Remote.EntityService.Entity.HumanoidEntity.PlayerEntity.LocalEntity)
    if not ok then return end

    LocalEntity._HumanoidWalkSpeed = math.huge

    local old = LocalEntity.UpdateWalkSpeed
    LocalEntity.UpdateWalkSpeed = function(self, ...)
        old(self, ...)
        self._HumanoidWalkSpeed = math.huge
    end
end)

-- ─── WALKSPEED (velocity + teleport modes) ──────────────────────────────────

-- Velocity mode (default) — runs every 0.1s
task.spawn(function()
    while task.wait(0.1) do
        local char = LocalPlayer.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not hum or not root then continue end

        local f = flags()
        if not f.MovementEnabled then
            if hum.WalkSpeed ~= 16 then hum.WalkSpeed = 16 end
            continue
        end

        local mode  = f.MovementWSMode or "Velocity"
        local speed = f.MovementWalkSpeed or 50

        if mode == "Teleport" then
            -- Teleport mode handled on Heartbeat below
            hum.WalkSpeed = 16
        else
            -- Velocity / Humanoid mode
            hum.WalkSpeed = 16
            if hum.MoveDirection.Magnitude > 0 then
                root.AssemblyLinearVelocity = Vector3.new(
                    hum.MoveDirection.X * speed,
                    root.AssemblyLinearVelocity.Y,
                    hum.MoveDirection.Z * speed
                )
            end
        end
    end
end)

-- Teleport mode (bypasses server speed checks)
local bodyVel
local function ensureBodyVel(root)
    if not bodyVel or bodyVel.Parent ~= root then
        bodyVel = Instance.new("BodyVelocity")
        bodyVel.MaxForce = Vector3.new(9e9, 0, 9e9) -- horizontal only
        bodyVel.P = 10000
        bodyVel.Parent = root
    end
end

RunService.Heartbeat:Connect(function(dt)
    local f = flags()
    if not f.MovementEnabled then return end
    local mode = f.MovementWSMode or "Velocity"
    if mode ~= "Teleport" then return end

    local char = LocalPlayer.Character
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not hum or not root then return end

    local speed = f.MovementWalkSpeed or 50
    local move  = hum.MoveDirection

    if move.Magnitude > 0 then
        ensureBodyVel(root)
        bodyVel.Velocity = move.Unit * speed
        hum.WalkSpeed = 16
    elseif bodyVel and bodyVel.Parent then
        bodyVel:Destroy()
    end
end)

-- ─── NO JUMP COOLDOWN ───────────────────────────────────────────────────────

task.spawn(function()
    while task.wait() do
        local f = flags()
        if not f.NoJumpCooldown then continue end
        local char = LocalPlayer.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.JumpPower = 50
        end
    end
end)

-- ─── BHOP ───────────────────────────────────────────────────────────────────

task.spawn(function()
    while task.wait() do
        local f = flags()
        if not f.Bhop then continue end
        local char = LocalPlayer.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not hum or not root then continue end

        local grounded = hum.FloorMaterial ~= Enum.Material.Air
        if grounded then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

-- ─── NO RECOIL ───────────────────────────────────────────────────────────────

task.spawn(function()
    while task.wait() do
        local f = flags()
        if f and f.NoRecoil then
            local RecoilConnection = filtergc("function", { Constants = { Enum.EasingDirection.Out, Enum.EasingDirection.InOut, "fromOrientation" } }, true)
            if RecoilConnection then
                hookfunction(RecoilConnection, function() return end)
            end
            break
        end
    end
end)

-- ─── AIMBOT ─────────────────────────────────────────────────────────────────

do
    local lockedPlayer  = nil
    local bindWasActive = false

    local fovCircle = Drawing.new("Circle")
    fovCircle.Thickness = 1
    fovCircle.Color     = Color3.fromRGB(255, 255, 255)
    fovCircle.Filled    = false
    fovCircle.Visible   = false
    fovCircle.NumSides  = 64

    local function playerIsValid(p)
        if not p or not p.Parent then return false end
        local char = p.Character
        if not char then return false end
        local hum = char:FindFirstChildOfClass("Humanoid")
        return hum ~= nil and hum.Health > 0
    end

    local function getAimPart(p)
        local char = p and p.Character
        if not char then return nil end
        local hitPart = flags().AimbotHitPart or "Head"
        return char:FindFirstChild(hitPart)
            or char:FindFirstChild("Head")
            or char:FindFirstChild("HumanoidRootPart")
    end

    local function pickTarget(fov, mode)
        local mousePos = getMousePos()
        local best, bestVal = nil, math.huge
        for _, p in ipairs(Players:GetPlayers()) do
            if not isEnemy(p) then continue end
            local part = getAimPart(p)
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
            else val = d2 end
            if val < bestVal then best, bestVal = p, val end
        end
        return best
    end

    local function isInFOV(p, fov)
        local part = getAimPart(p)
        if not part then return false end
        local sp, inView = Camera:WorldToViewportPoint(part.Position)
        if not inView or sp.Z <= 0 then return false end
        return (Vector2.new(sp.X, sp.Y) - getMousePos()).Magnitude <= fov
    end

    RunService:BindToRenderStep("publichook_aimbot", Enum.RenderPriority.Camera.Value + 1, function()
        local f = flags()

        if f.AimbotFOVCircle then
            local cd = f.AimbotFOVCircleColor
            fovCircle.Color    = cd and cd.Color or Color3.fromRGB(255,255,255)
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
            -- Hold mode: bypass main toggle, activate only while key is physically held
            if bind and bind.Key and bind.Key ~= "NONE" then
                local ok, held = pcall(function()
                    return UIS:IsKeyDown(bind.Key)
                end)
                active = ok and held or false
            end
        else
            -- Toggle/Always mode: main toggle must be on
            if not f.AimbotEnabled then
                lockedPlayer = nil bindWasActive = false return
            end
            if bind and bind.Key and bind.Key ~= "NONE" then
                active = bind.Active or false
            end
        end
        if not active then
            lockedPlayer = nil bindWasActive = false return
        end

        local fov      = f.AimbotFOVRadius or 120
        local mode     = f.AimbotTargetMode or "FOV"
        local smooth   = f.AimbotSmooth or 20
        local alpha    = 1 - ((smooth - 1) / 99 * 0.95)
        local hardLock = f.AimbotHardLock or false

        if not bindWasActive then
            lockedPlayer  = pickTarget(fov, mode)
            bindWasActive = true
        end
        if not isEnemy(lockedPlayer) then
            lockedPlayer = pickTarget(fov, mode)
        end
        if not hardLock and lockedPlayer and not isInFOV(lockedPlayer, fov) then
            lockedPlayer = pickTarget(fov, mode)
        end

        local part = getAimPart(lockedPlayer)
        if not part then return end
        Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, part.Position), alpha)
    end)
end

-- ─── SILENT AIM ─────────────────────────────────────────────────────────────

do
    -- Fully independent from aimbot: own FOV, own hit part, own target cache
    local cachedSilentTarget = nil  -- BasePart

    local saFOVCircle = Drawing.new("Circle")
    saFOVCircle.Thickness = 1
    saFOVCircle.Color     = Color3.fromRGB(255, 100, 100)
    saFOVCircle.Filled    = false
    saFOVCircle.Visible   = false
    saFOVCircle.NumSides  = 64

    local function playerIsValid(p)
        if not p or not p.Parent then return false end
        local char = p.Character
        if not char then return false end
        local hum = char:FindFirstChildOfClass("Humanoid")
        return hum ~= nil and hum.Health > 0
    end

    local function isValidPart(part)
        if not part or not part.Parent then return false end
        local hum = part.Parent:FindFirstChildOfClass("Humanoid")
        return hum ~= nil and hum.Health > 0
    end

    local function getSilentPart(p)
        local char = p and p.Character
        if not char then return nil end
        local hitPart = flags().SilentAimHitPart or "Head"
        return char:FindFirstChild(hitPart)
            or char:FindFirstChild("Head")
            or char:FindFirstChild("HumanoidRootPart")
    end

    local function pickSilentTarget(fov, mode)
        local mousePos = getMousePos()
        local best, bestVal = nil, math.huge
        for _, p in ipairs(Players:GetPlayers()) do
            if not isEnemy(p) then continue end
            local part = getSilentPart(p)
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
            else val = d2 end
            if val < bestVal then best, bestVal = part, val end
        end
        return best
    end

    -- Update cached target every frame
    RunService.RenderStepped:Connect(function()
        local f = flags()

        if f.SilentAimFOVCircle then
            local cd = f.SilentAimFOVCircleColor
            saFOVCircle.Color    = cd and cd.Color or Color3.fromRGB(255,100,100)
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

        -- Clear if dead/gone
        if not isValidPart(cachedSilentTarget) then
            cachedSilentTarget = nil
        end

        -- Clear if target has left the FOV circle
        if cachedSilentTarget then
            local sp, inView = Camera:WorldToViewportPoint(cachedSilentTarget.Position)
            if not inView or sp.Z <= 0 then
                cachedSilentTarget = nil
            elseif (Vector2.new(sp.X, sp.Y) - getMousePos()).Magnitude > fov then
                cachedSilentTarget = nil
            end
        end

        -- Pick new target if we don't have one
        if not cachedSilentTarget then
            cachedSilentTarget = pickSilentTarget(fov, mode)
        end
    end)

    -- Hook
    if not getgenv()._SilentAimHooked then
        getgenv()._SilentAimHooked = true

        local function hookTargetingSystem()
            local ok, CameraController = pcall(function()
                return require(game:GetService("ReplicatedStorage").Client.CameraController)
            end)

            if not ok or not CameraController or not CameraController.GetTargetingFn then
                warn("[publichook] Silent Aim: CameraController not found or missing GetTargetingFn")
                return
            end

            local originalGetTargeting = CameraController.GetTargetingFn()

            if not hookfunction or not originalGetTargeting then
                warn("[publichook] Silent Aim: hookfunction unavailable or GetTargeting is nil")
                return
            end

            local original
            original = hookfunction(originalGetTargeting, newcclosure(function(...)
                local results = {original(...)}

                if not getgenv()._TargetingDebugLogged then
                    getgenv()._TargetingDebugLogged = true
                    print("=== GetTargeting() Return Values ===")
                    for i, v in ipairs(results) do
                        print(string.format("[%d] = %s (type: %s)", i, tostring(v), typeof(v)))
                    end
                    print("=====================================")
                end

                if flags().SilentAim and isValidPart(cachedSilentTarget) then
                    results[2] = cachedSilentTarget
                end

                return unpack(results)
            end))

            print("[publichook] Silent Aim: hook installed")
        end

        task.delay(0.5, hookTargetingSystem)
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
