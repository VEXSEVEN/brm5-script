local Weapons = {}

local function forceUnlock(tbl)
    local mt = getrawmetatable(tbl)
    if mt then
        setreadonly(mt, false)
        return true
    end
    return false
end

function Weapons.patchWeapons(replicatedStorage, patchOptions)
    print("DEBUG: Caut Shared...")
    local shared = replicatedStorage:FindFirstChild("Shared")
    if not shared then print("DEBUG: NU am găsit Shared!") return end
    
    print("DEBUG: Caut Configs...")
    local configs = shared:FindFirstChild("Configs")
    if not configs then print("DEBUG: NU am găsit Configs!") return end
    
    -- Verificăm dacă există Weapon și Weapons_Player
    local weaponFolder = configs:FindFirstChild("Weapon")
    if not weaponFolder then print("DEBUG: NU am găsit folderul Weapon!") return end
    
    local weaponsPlayer = weaponFolder:FindFirstChild("Weapons_Player")
    if not weaponsPlayer then print("DEBUG: NU am găsit Weapons_Player!") return end

    print("DEBUG: Am găsit tot! Încep iterarea...")

    for _, platform in pairs(weaponsPlayer:GetChildren()) do
        if platform:IsA("Folder") then
            for _, weapon in pairs(platform:GetChildren()) do
                for _, child in pairs(weapon:GetChildren()) do
                    if child:IsA("ModuleScript") and child.Name:match("^Receiver%.") then
                        print("DEBUG: Găsit receiver: " .. child.Name)
                        local success, receiver = pcall(require, child)
                        
                        if success and receiver and receiver.Config and receiver.Config.Tune then
                            local tune = receiver.Config.Tune
                            forceUnlock(tune)
                            
                            if patchOptions.recoil then
                                tune.Recoil_X = 0
                                tune.Recoil_Z = 0
                                tune.Recoil_Camera = 0
                                -- Adăugăm și asta pentru siguranță
                                tune.Recoil_Random = Vector2.new(0, 0)
                            end
                            print("DEBUG: Patch aplicat pe: " .. child.Name)
                        end
                    end
                end
            end
        end
    end
end

return Weapons