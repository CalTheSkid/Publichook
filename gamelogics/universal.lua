local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

print("[publichook] Universal logic loaded.")

-- ─── ESP ────────────────────────────────────────────────────────────────────

local espObjects = {} -- [player] = { box, nameTag, distTag, healthBg, healthBar, highlight }

local function getFlags()
    return flags()
end

local function getColor(flag, default)
    local f = getFlags()[flag]
    if f and f.Color then return f.Color end
    return default or Color3.fromRGB(255, 255, 255)
end

local function newDrawing(type, props)
    local d = Drawing.new(type)
    for k, v in pairs(props) do d[k] = v end
    return d
end

local function createEspFor(player)
    if player == LocalPlayer then return end
    if espObjects[player] then return end

    local obj = {}

    -- Box (4 lines)
    obj.boxLines = {}
    for i = 1, 4 do
        obj.boxLines[i] = newDrawing("Line", {
            Thickness = 1,
            Color = Color3.fromRGB(255,255,255),
            Transparency = 1,
            Visible = false,
        })
    end

    -- Name
    obj.nameTag = newDrawing("Text", {
        Size = 13,
        Color = Color3.fromRGB(255,255,255),
        Outline = true,
        OutlineColor = Color3.fromRGB(0,0,0),
        Center = true,
        Visible = false,
        Text = player.Name,
    })

    -- Distance
    obj.distTag = newDrawing("Text", {
        Size = 11,
        Color = Color3.fromRGB(200,200,200),
        Outline = true,
        OutlineColor = Color3.fromRGB(0,0,0),
        Center = true,
        Visible = false,
        Text = "",
    })

    -- Health bar (background + fill)
    obj.healthBg = newDrawing("Line", {
        Thickness = 4,
        Color = Color3.fromRGB(0,0,0),
        Transparency = 0.5,
        Visible = false,
    })
    obj.healthBar = newDrawing("Line", {
        Thickness = 3,
        Color = Color3.fromRGB(0,255,0),
        Transparency = 1,
        Visible = false,
    })

    -- Chams (Highlight)
    obj.highlight = Instance.new("Highlight")
    obj.highlight.FillTransparency = 0.5
    obj.highlight.OutlineTransparency = 1
    obj.highlight.Enabled = false
    obj.highlight.Parent = game:GetService("CoreGui")

    espObjects[player] = obj
end

local function removeEspFor(player)
    local obj = espObjects[player]
    if not obj then return end
    for _, line in ipairs(obj.boxLines or {}) do pcall(function() line:Remove() end) end
    pcall(function() obj.nameTag:Remove() end)
    pcall(function() obj.distTag:Remove() end)
    pcall(function() obj.healthBg:Remove() end)
    pcall(function() obj.healthBar:Remove() end)
    pcall(function() obj.highlight:Destroy() end)
    espObjects[player] = nil
end

-- world-to-viewport with on-screen check
local function w2s(pos)
    local screen, inView = Camera:WorldToViewportPoint(pos)
    if not inView or screen.Z <= 0 then return nil end
    return Vector2.new(screen.X, screen.Y), screen.Z
end

-- get 2D bounding box from character
local function getBoundingBox(char)
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end

    -- Use head top and foot bottom for height
    local head = char:FindFirstChild("Head")
    local top = head and head.Position + Vector3.new(0, head.Size.Y / 2 + 0.1, 0) or root.Position + Vector3.new(0, 3, 0)
    local bottom = root.Position - Vector3.new(0, 3, 0)

    local topScreen, dist = w2s(top)
    local bottomScreen = w2s(bottom)
    if not topScreen or not bottomScreen then return nil end

    local height = math.abs(bottomScreen.Y - topScreen.Y)
    local width = height * 0.6
    local cx = topScreen.X

    return {
        tl = Vector2.new(cx - width/2, topScreen.Y),
        tr = Vector2.new(cx + width/2, topScreen.Y),
        bl = Vector2.new(cx - width/2, bottomScreen.Y),
        br = Vector2.new(cx + width/2, bottomScreen.Y),
        top = topScreen,
        bottom = bottomScreen,
        center = Vector2.new(cx, topScreen.Y),
        dist = dist,
        width = width,
        height = height,
    }
end

-- setup existing players
for _, p in ipairs(Players:GetPlayers()) do
    createEspFor(p)
end
Players.PlayerAdded:Connect(createEspFor)
Players.PlayerRemoving:Connect(removeEspFor)

-- main render loop
RunService.RenderStepped:Connect(function()
    local f = getFlags()
    local espOn     = f.ESPEnabled or false
    local showBox   = f.ESPBoxes or false
    local showName  = f.ESPName or false
    local showDist  = f.ESPDistance or false
    local showHP    = f.ESPHealthBar or false
    local showChams = f.ESPChams or false
    local maxDist   = f.ESPMaxDist or 2000

    local boxColor   = getColor("ESPBoxColor",      Color3.fromRGB(255,255,255))
    local nameColor  = getColor("ESPNameColor",     Color3.fromRGB(255,255,255))
    local distColor  = getColor("ESPDistanceColor", Color3.fromRGB(200,200,200))
    local chamsColorData = f.ESPChamsColor
    local chamsColor = chamsColorData and chamsColorData.Color or Color3.fromRGB(255,0,0)
    local chamsAlpha = chamsColorData and chamsColorData.Transparency or 0.5

    for player, obj in pairs(espObjects) do
        local char = player.Character
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        local alive = humanoid and humanoid.Health > 0

        -- chams
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
            lines[1].From = tl  lines[1].To = tr  -- top
            lines[2].From = bl  lines[2].To = br  -- bottom
            lines[3].From = tl  lines[3].To = bl  -- left
            lines[4].From = tr  lines[4].To = br  -- right
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

        -- Health bar (left side of box)
        if showHP then
            local hp = humanoid.Health
            local maxHp = humanoid.MaxHealth
            local pct = maxHp > 0 and math.clamp(hp / maxHp, 0, 1) or 0
            local barX = bb.tl.X - 5
            local barTop = bb.tl.Y
            local barBottom = bb.bl.Y
            local barFill = barTop + (barBottom - barTop) * (1 - pct)

            local g = pct * 255
            local r = (1 - pct) * 255
            local hpColor = Color3.fromRGB(r, g, 0)

            obj.healthBg.From = Vector2.new(barX, barTop)
            obj.healthBg.To   = Vector2.new(barX, barBottom)
            obj.healthBg.Visible = true

            obj.healthBar.From  = Vector2.new(barX, barFill)
            obj.healthBar.To    = Vector2.new(barX, barBottom)
            obj.healthBar.Color = hpColor
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
        local hum = char and char:FindFirstChildOfClass("Humanoid")
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

task.spawn(function()
    while task.wait() do
        local f = flags()
        if not (f.AimbotEnabled) then continue end
        local bind = f.AimbotBind
        if not (bind and bind.Active) then continue end

        local fov    = f.AimbotFOVRadius or 120
        local mode   = f.AimbotTargetMode or "Distance"
        local center = Camera.ViewportSize / 2

        local best, bestVal = nil, math.huge

        for _, p in ipairs(Players:GetPlayers()) do
            if p == LocalPlayer then continue end
            local char = p.Character
            if not char then continue end
            local hum = char:FindFirstChildOfClass("Humanoid")
            if not hum or hum.Health <= 0 then continue end
            local root = char:FindFirstChild("HumanoidRootPart")
            local head = char:FindFirstChild("Head")
            if not root then continue end

            local sp, inView = Camera:WorldToViewportPoint((head or root).Position)
            if not inView then continue end

            local d2 = (Vector2.new(sp.X, sp.Y) - center).Magnitude
            if d2 > fov then continue end

            local val
            if mode == "FOV" then
                val = d2
            elseif mode == "Health" then
                val = hum.Health
            else
                val = (root.Position - Camera.CFrame.Position).Magnitude
            end

            if val < bestVal then
                best, bestVal = (head or root), val
            end
        end

        if best then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, best.Position)
        end
    end
end)
