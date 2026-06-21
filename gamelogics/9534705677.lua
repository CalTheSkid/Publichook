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

-- Returns true if player should be targeted/shown
-- Respects TeamCheck and AliveCheck flags globally
local function isEnemy(player)
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
        local myTeam   = LocalPlayer.Team
        local theirTeam = player.Team
        if myTeam and theirTeam and myTeam == theirTeam then return false end
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
        local show     = isEnemy(player) and alive

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

-- ─── WALKSPEED (velocity only, no mode dropdown) ────────────────────────────

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

        local speed = f.MovementWalkSpeed or 50
        -- Always velocity mode in Sniper Arena
        hum.WalkSpeed = 16 -- keep humanoid default so game doesn't reset us
        if hum.MoveDirection.Magnitude > 0 then
            root.AssemblyLinearVelocity = Vector3.new(
                hum.MoveDirection.X * speed,
                root.AssemblyLinearVelocity.Y,
                hum.MoveDirection.Z * speed
            )
        end
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

        -- Only jump when on the ground to avoid fighting with physics
        local grounded = hum.FloorMaterial ~= Enum.Material.Air
        if grounded then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
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

        if not f.AimbotEnabled then
            lockedPlayer = nil bindWasActive = false return
        end

        local bind   = f.AimbotBind
        local active = bind and bind.Active or false
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
