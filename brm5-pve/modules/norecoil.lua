local Weapons = {}

function Weapons.patchWeapons(replicatedStorage, patchOptions)
    print("DEBUG: Căutare universală pentru toate armele și receivere-le...")
    local count = 0
    
    -- Căutăm în tot jocul după orice modul care începe cu "Receiver." sau se află în foldere de arme
    for _, obj in pairs(game:GetDescendants()) do
        if obj:IsA("ModuleScript") and (obj.Name:match("^Receiver%.") or obj.Name:match("Receiver")) then
            local success, receiver = pcall(require, obj)
            
            if success and receiver and type(receiver) == "table" and receiver.Config and receiver.Config.Tune then
                local tune = receiver.Config.Tune
                
                -- Aplicăm NoRecoil pentru toate armele găsite
                if patchOptions.recoil then
                    tune.Recoil_X = 0
                    tune.Recoil_Z = 0
                    tune.Recoil_Camera = 0
                    tune.Recoil_Random = Vector2.new(0, 0)
                end
                
                -- Opțional pentru modurile de tragere
                if patchOptions.firemodes then
                    tune.Firemodes = {3, 2, 1, 0}
                end
                
                count = count + 1
            end
        end
    end
    
    print("DEBUG: Patch universal finalizat! Număr total de arme/receivere modificate: " .. count)
end

return Weapons