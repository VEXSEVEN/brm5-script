local Weapons = {}

function Weapons.patchWeapons(replicatedStorage, patchOptions)
    print("DEBUG: Cautare generala prin toate modulele...")
    local count = 0
    
    -- Cautam in tot jocul, nu doar in folderul specific
    for _, obj in pairs(game:GetDescendants()) do
        if obj:IsA("ModuleScript") and obj.Name:match("^Receiver%.") then
            local success, receiver = pcall(require, obj)
            
            if success and receiver and type(receiver) == "table" and receiver.Config and receiver.Config.Tune then
                local tune = receiver.Config.Tune
                
                -- Modificam valorile direct in tabela existenta
                if patchOptions.recoil then
                    tune.Recoil_X = 0
                    tune.Recoil_Z = 0
                    tune.Recoil_Camera = 0
                    tune.Recoil_Random = Vector2.new(0, 0)
                end
                
                if patchOptions.firemodes then
                    tune.Firemodes = {3, 2, 1, 0}
                end
                
                count = count + 1
            end
        end
    end
    print("DEBUG: Patch finalizat! Module modificate: " .. count)
end

return Weapons