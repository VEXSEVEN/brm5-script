-- GUI Module (Fluent - Versiune Extinsă)
local GUI = {}

GUI.Fluent = nil
GUI.Window = nil
GUI.Tabs = nil
GUI.Options = nil

function GUI:init(services, config, callbacks)
    local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
    local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
    local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()


    local screenGui = Instance.new("ScreenGui", services.CoreGui or services.Players.LocalPlayer:WaitForChild("PlayerGui"))
    screenGui.Name = "CursorIndicatorGui"
    self.screenGui = screenGui

    local cursorIndicator = Instance.new("Frame", screenGui)
    cursorIndicator.Name = "CursorIndicator"
    cursorIndicator.Size = UDim2.fromOffset(10, 10)
    cursorIndicator.AnchorPoint = Vector2.new(0.5, 0.5)
    cursorIndicator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    cursorIndicator.BorderSizePixel = 0
    cursorIndicator.Visible = false -- Vizibil doar când meniul e deschis
    cursorIndicator.ZIndex = 100
    Instance.new("UICorner", cursorIndicator).CornerRadius = UDim.new(1, 0)
    self.cursorIndicator = cursorIndicator

    local cursorStroke = Instance.new("UIStroke", cursorIndicator)
    cursorStroke.Color = Color3.fromRGB(0, 0, 0)
    cursorStroke.Thickness = 1.5
    
    self.Fluent = Fluent
    self.Window = Fluent:CreateWindow({
        Title = "BRM5 " .. Fluent.Version,
        SubTitle = "PVE Pro",
        TabWidth = 160,
        Size = UDim2.fromOffset(580, 460),
        Acrylic = false, 
        IntegrateBackdrop = false, -- ADĂUGĂ LINIA ASTA (previne suprapunerea peste cameră)
        Theme = "Dark",
        MinimizeKey = Enum.KeyCode.RightShift 
    })

    self.Tabs = {
        Combat = self.Window:AddTab({ Title = "Combat", Icon = "swords" }),
        Visuals = self.Window:AddTab({ Title = "Visuals", Icon = "eye" }),
        Weapons = self.Window:AddTab({ Title = "Weapons", Icon = "wrench" }),
        Settings = self.Window:AddTab({ Title = "Settings", Icon = "settings" })
    }

    local Options = Fluent.Options
    self.Options = Options

    -- Combat
    self.Tabs.Combat:AddToggle("Silent", { Title = "Silent Aim", Default = config.sizingEnabled }):OnChanged(callbacks.onSizingToggle)
    self.Tabs.Combat:AddToggle("ShowTargetBox", { Title = "Show HitBox", Default = config.showTargetBox }):OnChanged(callbacks.onShowTargetBoxToggle)

    -- Visuals
    self.Tabs.Visuals:AddToggle("Walls", { Title = "Wall ESP", Default = config.highlightEnabled }):OnChanged(callbacks.onHighlightsToggle)
    self.Tabs.Visuals:AddSlider("NPCRange", {
        Title = "NPC Detection Radius",
        Default = config.npcDetectionRadius,
        Min = 0, Max = config.MAX_NPC_DETECTION_RADIUS,
        Rounding = 0
    }):OnChanged(callbacks.onNPCDetectionRadiusChange)

    -- Exemplu Dropdown Nou
    self.Tabs.Visuals:AddDropdown("VisualStyle", {
        Title = "Highlight Style",
        Values = {"Outline", "Box", "Filled"},
        Multi = false,
        Default = 1,
    }):OnChanged(function(v) print("Style changed to: ", v) end)

    -- Weapons
    self.Tabs.Weapons:AddToggle("NoRecoil", { Title = "No Recoil", Default = config.patchOptions.recoil }):OnChanged(callbacks.onStabilityToggle)
    
    -- Exemplu Input Nou
    self.Tabs.Weapons:AddInput("InputSpeed", {
        Title = "Fire Rate Multiplier",
        Default = "1.0",
        Numeric = true,
        Callback = function(v) print("New rate: ", v) end
    })

    -- ColorPicker Avansat (transparență inclusă)
    self.Tabs.Visuals:AddColorpicker("ESPColor", {
        Title = "ESP Color",
        Transparency = 0,
        Default = Color3.fromRGB(255, 255, 255)
    }):OnChanged(function(val) 
        -- Aici poți apela callbacks.onColorChange(val)
    end)

    -- Settings & Management
    InterfaceManager:SetLibrary(Fluent)
    SaveManager:SetLibrary(Fluent)
    InterfaceManager:SetFolder("FluentScriptHub")
    SaveManager:SetFolder("FluentScriptHub/BRM5")
    
    InterfaceManager:BuildInterfaceSection(self.Tabs.Settings)
    SaveManager:BuildConfigSection(self.Tabs.Settings)

    self.Window:SelectTab(1)
    Fluent:Notify({ Title = "Success", Content = "UI incarcat cu succes!", Duration = 5 })
end

-- Funcțiile tale de control rămân la fel
function GUI:destroy()
    if self.Fluent then self.Fluent:Destroy() end
end

return GUI