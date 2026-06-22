local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

print("[publichook] Rivals logic loaded.")

-- ─── ANTI-CHEAT BYPASS ─────────────────────────────────────────────────────

do
    local oldMT
    oldMT = hookfunction(getrenv().setmetatable, newcclosure(function(Table, Metatable)
        if Metatable and typeof(Metatable) == "table" and rawget(Metatable, "__mode") == "kv" then
            local trace = debug.traceback()
            if trace:find("MiscellaneousController") then
                return oldMT({1, 2, 3}, {})
            end
        end
        return oldMT(Table, Metatable)
    end))
end

-- ─── ESP ────────────────────────────────────────────────────────────────────

local espObjects = {} -- [player] = { box, nameTag, distTag, healthBg, healthBar, highlight }

-- flags() is injected by the loader directly into this environment.
-- It returns Library.Flags — the live flag table from the UI.

local function getColor(flag, default)
    local f = flags()[flag]
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
    local f = flags()
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

        -- Boxwell
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

-- ─── WEAPON MODS ───────────────────────────────────────────────────────────

task.spawn(function()
    local RS = game:GetService("ReplicatedStorage")
    local success, GunModule = pcall(function()
        return require(LocalPlayer.PlayerScripts.Modules.ItemTypes.Gun)
    end)
    if not success or not GunModule then return end

    local origStartShooting   = GunModule.StartShooting
    local origStartReloading  = GunModule.StartReloading
    local origRecoil          = GunModule._Recoil
    local origStartAiming     = GunModule.StartAiming
    local origGetAimSpeed     = GunModule.GetAimSpeed
    local origEquip           = GunModule.Equip
    local origLocalTracers    = GunModule._LocalTracers
    local origProjectileEffect = GunModule._ProjectileEffect

    GunModule.StartShooting = function(self, p26, p27)
        local f = flags()
        if f.RivalsInfiniteAmmo then
            local currentAmmo = self:Get("Ammo")
            if currentAmmo <= 0 then
                self:SetReplicate("Ammo", self.Info.MaxAmmo)
            end
        end

        local oldShootCooldown, oldBurstCooldown
        if f.RivalsRapidFire then
            oldShootCooldown = self.Info.ShootCooldown
            oldBurstCooldown = self.Info.ShootBurstCooldown
            self.Info.ShootCooldown = f.RivalsRapidFireSpeed or 0.01
            self.Info.ShootBurstCooldown = f.RivalsRapidFireSpeed or 0.01
        end

        local result = { origStartShooting(self, p26, p27) }

        if f.RivalsRapidFire then
            self.Info.ShootCooldown = oldShootCooldown
            self.Info.ShootBurstCooldown = oldBurstCooldown
        end

        return unpack(result)
    end

    GunModule.StartReloading = function(self, p40, p41, p42)
        if flags().RivalsInstantReload then
            self:_ResetReloadState()
            local currentAmmo = self:Get("Ammo")
            local maxAmmo = self.Info.MaxAmmo
            local reserve = self:Get("AmmoReserve")
            if currentAmmo < maxAmmo and reserve > 0 then
                local needed = maxAmmo - currentAmmo
                local toReload = math.min(needed, reserve)
                self:SetReplicate("Ammo", currentAmmo + toReload)
                self:SetReplicate("AmmoReserve", reserve - toReload)
            end
            return true, "StartReloading", self:ToEnum("Reload")
        end
        return origStartReloading(self, p40, p41, p42)
    end

    GunModule._Recoil = function(self, multiplier)
        local f = flags()
        if f.RivalsNoRecoil then
            local reduction = f.RivalsRecoilReduction or 100
            local newMultiplier = multiplier * (1 - reduction / 100)
            if newMultiplier <= 0.001 then return end
            return origRecoil(self, newMultiplier)
        end
        return origRecoil(self, multiplier)
    end

    GunModule.StartAiming = function(self, p71)
        if flags().RivalsInstantADS then
            self:SetReplicate("IsAiming", true)
            self.StopSprinting:Fire()
            self.ViewModel:SetAiming(true)
            self:SetReplicate("FOVOffset", self.Info.AimFOVOffset)
            if self.ViewModel.CurrentAimValue then
                self.ViewModel.CurrentAimValue = 1
            end
            return true, "StartAiming"
        end
        return origStartAiming(self, p71)
    end

    GunModule.GetAimSpeed = function(self)
        if flags().RivalsInstantADS then return 999 end
        return origGetAimSpeed(self)
    end

    GunModule.Equip = function(self, ...)
        local f = flags()
        if f.RivalsInstantEquip then
            self._is_revolver_quick_shooting = nil
            self._shoot_cooldown = 0
            self:_ResetReloadState()
            return
        end
        if f.RivalsNoEquipAnimation then
            local result = { origEquip(self, ...) }
            if self.ViewModel then
                self.ViewModel:StopAnimation("Equip")
                self.ViewModel:StopAnimation("EquipEmpty")
            end
            return unpack(result)
        end
        return origEquip(self, ...)
    end

    GunModule._ProjectileEffect = function(self, p_u_84, p85)
        if flags().RivalsProjectileSpeed and p_u_84 then
            local velocity = p_u_84.Velocity
            if velocity then
                p_u_84.Velocity = velocity * (flags().RivalsProjectileSpeedMultiplier or 5)
            end
        end
        return origProjectileEffect(self, p_u_84, p85)
    end

    GunModule._LocalTracers = function(self, p109, p110)
        if flags().RivalsInstantBulletTravel then
            local originalPierce = self.Info.RaycastPierceCount
            local originalBounce = self.Info.RaycastBounceCount
            local originalBounceAngle = self.Info.RaycastBounceRedirectionAngle
            self.Info.RaycastPierceCount = 999
            self.Info.RaycastBounceCount = 0
            self.Info.RaycastBounceRedirectionAngle = 0

            local result = { origLocalTracers(self, p109, p110) }

            self.Info.RaycastPierceCount = originalPierce
            self.Info.RaycastBounceCount = originalBounce
            self.Info.RaycastBounceRedirectionAngle = originalBounceAngle

            return unpack(result)
        end
        return origLocalTracers(self, p109, p110)
    end
end)

task.spawn(function()
    local success, GameplayUtility = pcall(function()
        return require(game:GetService("ReplicatedStorage").Modules.GameplayUtility)
    end)
    if success and GameplayUtility and GameplayUtility.GetSpread then
        local origGetSpread = GameplayUtility.GetSpread
        GameplayUtility.GetSpread = function(spread, aimMultiplier, isAiming, isCrouching, pelletIndex, totalPellets, consistent)
            if flags().RivalsNoSpread then return CFrame.new() end
            return origGetSpread(spread, aimMultiplier, isAiming, isCrouching, pelletIndex, totalPellets, consistent)
        end
    end
end)

task.spawn(function()
    local success, ViewModelModule = pcall(function()
        return require(LocalPlayer.PlayerScripts.Modules.ViewModel)
    end)
    if success and ViewModelModule and ViewModelModule.new then
        local origNew = ViewModelModule.new
        ViewModelModule.new = function(...)
            local viewModel = origNew(...)
            if viewModel.Update then
                local origUpdate = viewModel.Update
                viewModel.Update = function(self, ...)
                    if flags().RivalsNoWeaponBob then
                        if self.BobSpeed then self.BobSpeed = 0 end
                        if self.BobIntensity then self.BobIntensity = 0 end
                    end
                    return origUpdate(self, ...)
                end
            end
            return viewModel
        end
    end
end)
