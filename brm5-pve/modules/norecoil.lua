local Weapons = {}

-- Funcție pentru a forța deblocarea tabelelor înghețate de sistemul BRM5
local function forceUnlock(tbl)
    local mt = getrawmetatable(tbl)
    if mt then
        setreadonly(mt, false)
        return true
    end
    return false
end

function Weapons.patchWeapons(replicatedStorage, patchOptions)
    -- Identificăm calea corectă către fișierele de configurare
    local shared = replicatedStorage:FindFirstChild("Shared")
    if not shared then return end
    
    local configs = shared:FindFirstChild("Configs")
    if not configs then return end
    
    local weaponsPlayer = configs:FindFirstChild("Weapon") and configs.Weapon:FindFirstChild("Weapons_Player")
    if not weaponsPlayer then return end

    -- Iterăm prin toate platformele de arme
    for _, platform in pairs(weaponsPlayer:GetChildren()) do
        if platform:IsA("Folder") then
            for _, weapon in pairs(platform:GetChildren()) do
                for _, child in pairs(weapon:GetChildren()) do
                    -- Vizăm doar modulele de tip receiver
                    if child:IsA("ModuleScript") and child.Name:match("^Receiver%.") then
                        local success, receiver = pcall(require, child)
                        
                        if success and receiver and receiver.Config and receiver.Config.Tune then
                            local tune = receiver.Config.Tune
                            
                            -- Deblocăm tabela pentru a permite modificarea valorilor
                            forceUnlock(tune)
                            
                            -- Aplicăm patch-ul de Recoil
                            if patchOptions.recoil then
                                tune.Recoil_X = 0
                                tune.Recoil_Z = 0
                                tune.RecoilForce_Tap = 0
                                tune.RecoilForce_Impulse = 0
                                tune.Recoil_Camera = 0
                                tune.Recoil_Range = Vector2.new(0, 0)
                                tune.RecoilAccelDamp_Crouch = Vector3.new(0, 0, 0)
                                tune.RecoilAccelDamp_Prone = Vector3.new(0, 0, 0)
                            end
                            
                            -- Aplicăm patch-ul de Firemodes (dacă este activat)
                            if patchOptions.firemodes then
                                tune.Firemodes = {3, 2, 1, 0}
                            end
                        end
                    end
                end
            end
        end
    end
end

return Weapons