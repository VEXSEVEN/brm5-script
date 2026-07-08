-- GUI Module (Fluent)
-- This module replaces the custom UI with the Fluent library.

local GUI = {}

GUI.Fluent = nil
GUI.Window = nil
GUI.Tabs = nil
GUI.Options = nil

local function safeHttpGet(url)
    local ok, res = pcall(function()
        return game:HttpGet(url)
    end)
    if not ok then
        return nil
    end
    if type(res) ~= "string" or res == "" then
        return nil
    end
    return res
end

function GUI:init(services, config, callbacks)
    local fluentSrc = safeHttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua")
    if not fluentSrc then
        error("Fluent UI download failed (main.lua).")
    end

    local saveManagerSrc = safeHttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua")
    local interfaceManagerSrc = safeHttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua")
    if not saveManagerSrc or not interfaceManagerSrc then
        error("Fluent UI download failed (addons).")
    end

    local Fluent = loadstring(fluentSrc)()
    local SaveManager = loadstring(saveManagerSrc)()
    local InterfaceManager = loadstring(interfaceManagerSrc)()

    self.Fluent = Fluent

    local window = Fluent:CreateWindow({
        Title = "BRM5 " .. tostring(Fluent.Version),
        SubTitle = "PVE",
        TabWidth = 160,
        Size = UDim2.fromOffset(580, 460),
        Acrylic = true,
        Theme = "Dark",
        MinimizeKey = Enum.KeyCode.LeftControl
    })
    self.Window = window

    local Tabs = {
        Combat = window:AddTab({ Title = "Combat", Icon = "swords" }),
        Visuals = window:AddTab({ Title = "Visuals", Icon = "eye" }),
        Weapons = window:AddTab({ Title = "Weapons", Icon = "wrench" }),
        Colors = window:AddTab({ Title = "Colors", Icon = "palette" }),
        Settings = window:AddTab({ Title = "Settings", Icon = "settings" }),
        Credits = window:AddTab({ Title = "Credits", Icon = "help-circle" }),
    }
    self.Tabs = Tabs

    local Options = Fluent.Options
    self.Options = Options

    -- Visual toggles / controls (callbacks are from brm5-pve/main.lua)
    do
        Tabs.Combat:AddToggle("Silent", { Title = "Silent", Default = config.sizingEnabled }):OnChanged(function(v)
            callbacks.onSizingToggle(v)
        end)

        Tabs.Combat:AddToggle("ShowTargetBox", { Title = "Show HitBox", Default = config.showTargetBox }):OnChanged(function(v)
            callbacks.onShowTargetBoxToggle(v)
        end)

        Tabs.Visuals:AddToggle("Walls", { Title = "Walls", Default = config.highlightEnabled }):OnChanged(function(v)
            callbacks.onHighlightsToggle(v)
        end)

        Tabs.Visuals:AddToggle("FullBright", { Title = "FullBright", Default = config.fullBrightEnabled }):OnChanged(function(v)
            callbacks.onFullBrightToggle(v)
        end)

        Tabs.Visuals:AddSlider("NPCRange", {
            Title = "NPC Range",
            Description = "Lower for better performance",
            Default = config.npcDetectionRadius,
            Min = 0,
            Max = config.MAX_NPC_DETECTION_RADIUS,
            Rounding = 0,
        }):OnChanged(function(v)
            callbacks.onNPCDetectionRadiusChange(v)
        end)

        Tabs.Weapons:AddToggle("NoRecoil", { Title = "No recoil", Default = config.patchOptions.recoil }):OnChanged(function(v)
            callbacks.onStabilityToggle(v)
        end)

        Tabs.Weapons:AddToggle("AllFiremodes", { Title = "All Firemodes", Default = config.patchOptions.firemodes }):OnChanged(function(v)
            callbacks.onFiremodeOptionsToggle(v)
        end)

        -- Colors: sliders per channel
        local function bindColorSlider(optionName, title, default, onChange)
            Tabs.Colors:AddSlider(optionName, {
                Title = title,
                Default = default,
                Min = 0,
                Max = 255,
                Rounding = 0,
            }):OnChanged(function(v)
                onChange(v)
            end)
        end

        bindColorSlider("VR", "Visible R", config.visibleR, callbacks.onVisibleRChange)
        bindColorSlider("VG", "Visible G", config.visibleG, callbacks.onVisibleGChange)
        bindColorSlider("VB", "Visible B", config.visibleB, callbacks.onVisibleBChange)

        bindColorSlider("HR", "Hidden R", config.hiddenR, callbacks.onHiddenRChange)
        bindColorSlider("HG", "Hidden G", config.hiddenG, callbacks.onHiddenGChange)
        bindColorSlider("HB", "Hidden B", config.hiddenB, callbacks.onHiddenBChange)

        -- Credits
        Tabs.Credits:AddParagraph({ Title = "Made by", Content = "HiIxX0Dexter0XxIiH" })
        Tabs.Credits:AddButton({
            Title = "Unload Script",
            Description = "Stops the module and cleans up UI",
            Callback = function()
                callbacks.onUnload()
            end
        })
    end

    -- Settings: keybind for GUI minimize/toggle
    do
        local openCloseKeybind = Tabs.Settings:AddKeybind("GuiToggleKeybind", {
            Title = "GUI Keybind",
            Mode = "Toggle",
            Default = "LeftControl",
            Callback = function()
                if callbacks.onVisibilityToggle then
                    callbacks.onVisibilityToggle()
                end
            end,
        })

        -- Ensure initial state
        if config.guiVisible == false then
            -- Fluent handles its own visibility via minimize, but we still keep config in sync
            -- by calling the callback once only if needed.
            -- (We do not auto-toggle to avoid double flips.)
        end

        -- Store with SaveManager
        SaveManager:SetLibrary(Fluent)
        InterfaceManager:SetLibrary(Fluent)
        SaveManager:IgnoreThemeSettings()
        SaveManager:SetIgnoreIndexes({})
        InterfaceManager:SetFolder("FluentScriptHub")
        SaveManager:SetFolder("FluentScriptHub/specific-game")
        InterfaceManager:BuildInterfaceSection(Tabs.Settings)
        SaveManager:BuildConfigSection(Tabs.Settings)

        SaveManager:LoadAutoloadConfig()
    end

    -- Set initial visibility (best-effort)
    pcall(function()
        if config.guiVisible == false then
            window:Minimize(true)
        else
            window:Minimize(false)
        end
    end)
end

function GUI:toggleVisibility()
    if callbacks and callbacks.onVisibilityToggle then
        callbacks.onVisibilityToggle()
        return true
    end
    return false
end

function GUI:setVisibleState(isVisible)
    if self.Window and self.Window.Minimize then
        pcall(function()
            self.Window:Minimize(not isVisible)
        end)
    end
    return isVisible
end

function GUI:destroy()
    if self.Fluent and self.Fluent.Unload then
        pcall(function()
            self.Fluent:Destroy()
        end)
    end
    self.Fluent = nil
    self.Window = nil
    self.Tabs = nil
end

return GUI


