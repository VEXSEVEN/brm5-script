local Weapons = {}

function Weapons.patchWeapons(replicatedStorage, patchOptions)
    -- 1. Aplică patch-ul pe modulele din Shared (pentru armele viitoare)
    local shared = replicatedStorage:FindFirstChild("Shared")
    if shared then
        local weaponsPlayer = shared:FindFirstChild("Configs") and shared.Configs:FindFirstChild("Weapon") and shared.Configs.Weapon:FindFirstChild("Weapons_Player")
        if weaponsPlayer then
            for _, platform in pairs(weaponsPlayer:GetChildren()) do
                if platform:IsA("Folder") then
                    for _, weapon in pairs(platform:GetChildren()) do
                        for _, child in pairs(weapon:GetChildren()) do
                            if child:IsA("ModuleScript") and child.Name:match("^Receiver%.") then
                                local success, receiver = pcall(require, child)
                                if success and receiver and receiver.Config and receiver.Config.Tune then
                                    local tune = receiver.Config.Tune
                                    if patchOptions.recoil then
                                        tune.Recoil_X = 0
                                        tune.Recoil_Z = 0
                                        tune.Recoil_Camera = 0
                                    end
                                    receiver.Config.Tune = tune -- Suprascriere
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    -- 2. FORCE PATCH: Caută arma activă în caracter (Dacă există)
    local player = game:GetService("Players").LocalPlayer
    if player.Character then
        for _, obj in pairs(player.Character:GetChildren()) do
            if obj:IsA("Tool") then
                -- Căutăm configurația internă a armei echipate
                local config = obj:FindFirstChild("Config") or obj:FindFirstChild("Settings")
                if config and config:FindFirstChild("Tune") then
                    local tune = config.Tune
                    if patchOptions.recoil then
                        tune.Recoil_X = 0
                        tune.Recoil_Z = 0
                        tune.Recoil_Camera = 0
                        print("DEBUG: Patch aplicat direct pe arma echipată!")
                    end
                end
            end
        end
    end
end

return Weapons