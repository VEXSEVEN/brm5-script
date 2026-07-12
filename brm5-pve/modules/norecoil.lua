local Weapons = {}

function Weapons.patchWeapons(replicatedStorage, patchOptions)
    local shared = replicatedStorage:FindFirstChild("Shared")
    if not shared then return end
    
    local configs = shared:FindFirstChild("Configs")
    if not configs then return end
    
    local weaponFolder = configs:FindFirstChild("Weapon")
    if not weaponFolder then return end
    
    local weaponsPlayer = weaponFolder:FindFirstChild("Weapons_Player")
    if not weaponsPlayer then return end

    for _, platform in pairs(weaponsPlayer:GetChildren()) do
        if platform:IsA("Folder") then
            for _, weapon in pairs(platform:GetChildren()) do
                for _, child in pairs(weapon:GetChildren()) do
                    if child:IsA("ModuleScript") and child.Name:match("^Receiver%.") then
                        local success, receiver = pcall(require, child)
                        
                        if success and receiver and receiver.Config and receiver.Config.Tune then
                            local tune = receiver.Config.Tune
                            
                            -- Cream o copie nouă a tabelei de configurare (evităm readonly/freeze)
                            local newTune = {}
                            for k, v in pairs(tune) do
                                newTune[k] = v
                            end
                            
                            -- Aplicăm patch-ul pe copia nouă
                            if patchOptions.recoil then
                                newTune.Recoil_X = 0
                                newTune.Recoil_Z = 0
                                newTune.RecoilForce_Tap = 0
                                newTune.RecoilForce_Impulse = 0
                                newTune.Recoil_Camera = 0
                                newTune.Recoil_Range = Vector2.new(0, 0)
                                newTune.RecoilAccelDamp_Crouch = Vector3.new(0, 0, 0)
                                newTune.RecoilAccelDamp_Prone = Vector3.new(0, 0, 0)
                                newTune.Recoil_Random = Vector2.new(0, 0)
                            end
                            
                            if patchOptions.firemodes then
                                newTune.Firemodes = {3, 2, 1, 0}
                            end
                            
                            -- Suprascriem tabela originală cu cea nouă
                            receiver.Config.Tune = newTune
                            print("DEBUG: Patch FORȚAT pe: " .. child.Name)
                        end
                    end
                end
            end
        end
    end
end

return Weapons