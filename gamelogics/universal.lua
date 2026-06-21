local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

print("[publichook] Universal gameplay logic loaded.")

-- WalkSpeed loop
task.spawn(function()
    while task.wait(0.1) do
        local character = LocalPlayer.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if not humanoid then continue end

        local speedVal = flags().MovementWalkSpeed or 16
        local wsMode = flags().MovementWSMode or "Humanoid"

        if speedVal > 16 then
            if wsMode == "Humanoid" then
                humanoid.WalkSpeed = speedVal
            elseif wsMode == "Velocity" then
                local rootPart = character:FindFirstChild("HumanoidRootPart")
                if rootPart and humanoid.MoveDirection.Magnitude > 0 then
                    rootPart.AssemblyLinearVelocity = Vector3.new(
                        humanoid.MoveDirection.X * speedVal,
                        rootPart.AssemblyLinearVelocity.Y,
                        humanoid.MoveDirection.Z * speedVal
                    )
                end
            end
        end
    end
end)

-- Aimbot loop
task.spawn(function()
    local Camera = workspace.CurrentCamera

    local function getClosestTarget()
        local fov = flags().AimbotFOVRadius or 120
        local mode = flags().AimbotTargetMode or "Distance"
        local center = Camera.ViewportSize / 2

        local best, bestVal = nil, math.huge

        for _, player in Players:GetPlayers() do
            if player == LocalPlayer then continue end
            local char = player.Character
            if not char then continue end
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if not humanoid or humanoid.Health <= 0 then continue end
            local root = char:FindFirstChild("HumanoidRootPart")
            if not root then continue end

            local screenPos, onScreen = Camera:WorldToViewportPoint(root.Position)
            if not onScreen then continue end

            local dist2D = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude

            if mode == "FOV" then
                if dist2D < fov and dist2D < bestVal then
                    best, bestVal = player, dist2D
                end
            elseif mode == "Distance" then
                local dist3D = (root.Position - Camera.CFrame.Position).Magnitude
                if dist2D < fov and dist3D < bestVal then
                    best, bestVal = player, dist3D
                end
            elseif mode == "Health" then
                if dist2D < fov and humanoid.Health < bestVal then
                    best, bestVal = player, humanoid.Health
                end
            end
        end

        return best
    end

    while task.wait() do
        local aimbotEnabled = flags().AimbotEnabled or false
        local bindData = flags().AimbotBind
        local isActive = bindData and bindData.Active or false

        if aimbotEnabled and isActive then
            local target = getClosestTarget()
            if target and target.Character then
                local root = target.Character:FindFirstChild("HumanoidRootPart")
                local head = target.Character:FindFirstChild("Head")
                local aimAt = head or root
                if aimAt then
                    Camera.CFrame = CFrame.new(Camera.CFrame.Position, aimAt.Position)
                end
            end
        end
    end
end)
