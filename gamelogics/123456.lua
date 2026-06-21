local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

print("[publichook] Game ID 123456 gameplay logic loaded successfully.")

task.spawn(function()
    while true do
        task.wait(1)
        
        if LocalPlayer.Character then
            local infAmmo = flags().GunModsInfAmmo or false
            local noRecoil = flags().GunModsNoRecoil or false
            local rapidFire = flags().GunModsRapidFire or false
            local fireRateSpeed = flags().GunModsFireRateSpeed or 1.5
            
            local activeMods = {}
            if infAmmo then table.insert(activeMods, "Inf Ammo") end
            if noRecoil then table.insert(activeMods, "No Recoil") end
            if rapidFire then table.insert(activeMods, "Rapid Fire (" .. tostring(fireRateSpeed) .. "x)") end
            
            if #activeMods > 0 then
                print("[publichook Game 123456] Weapon Modifiers Active: " .. table.concat(activeMods, ", "))
            else
                print("[publichook Game 123456] No weapon modifiers currently enabled.")
            end
        end
    end
end)
