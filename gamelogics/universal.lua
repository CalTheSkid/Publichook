local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

print("[publichook] Universal gameplay logic loaded successfully.")

task.spawn(function()
    while true do
        task.wait(0.1)
        
        local character = LocalPlayer.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        
        if humanoid then
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
    end
end)

task.spawn(function()
    while true do
        task.wait(1)
        
        local isBoxESP = flags().ESPBoxEnabled or false
        local boxColorSettings = flags().ESPBoxColor
        
        if isBoxESP then
            local colorHex = "#FFFFFF"
            if boxColorSettings and boxColorSettings.Color then
                local color = boxColorSettings.Color
                colorHex = string.format("#%02X%02X%02X", math.floor(color.R*255), math.floor(color.G*255), math.floor(color.B*255))
            end
            print(string.format("[publichook ESP] Rendering Box ESP active with color %s", colorHex))
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(0.5)
        
        local aimbotActive = flags().AimbotEnabled or false
        local aimbotBind = flags().AimbotBind
        
        if aimbotActive then
            local isKeyHeld = false
            if aimbotBind then
                isKeyHeld = aimbotBind.Active
            end
            
            if isKeyHeld then
                print("[publichook Aimbot] Tracking target. (Bind Active)")
            else
                print("[publichook Aimbot] Idle (Waiting for bind)")
            end
        end
    end
end)
