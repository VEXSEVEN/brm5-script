-- BRM5 v7.0 by dexter 
if typeof(clear) == "function" then
    clear()
end

local MAIN_VERSION = "cache-bust-2026-03-18-01"
local GITHUB_BASE = "https://raw.githubusercontent.com/VEXSEVEN/brm5-script/main/brm5-pve/modules/"
local CACHE_BUSTER = MAIN_VERSION .. "-" .. tostring(os.time())

local function loadModule(moduleName)
    local url = GITHUB_BASE .. moduleName .. ".lua?v=" .. CACHE_BUSTER

    local okResponse, response = pcall(function()
        return game:HttpGet(url)
    end)
    if not okResponse then
        warn("Failed to download module: " .. moduleName)
        warn("URL: " .. url)
        warn("HttpGet error: " .. tostring(response))
        return nil
    end

    if type(response) ~= "string" or response == "" then
        warn("Module download returned empty content: " .. moduleName)
        warn("URL: " .. url)
        return nil
    end

    local chunk, compileError = loadstring(response)
    if not chunk then
        warn("Failed to compile module: " .. moduleName)
        warn("URL: " .. url)
        warn("Compile error: " .. tostring(compileError))
        return nil
    end

    local okRun, result = pcall(chunk)
    if not okRun then
        warn("Failed to execute module: " .. moduleName)
        warn("URL: " .. url)
        warn("Runtime error: " .. tostring(result))
        return nil
    end

    return result
end

local Services = loadModule("services")
local Config = loadModule("config")
local NPCManager = loadModule("npc_manager")
local TargetSizing = loadModule("silent")
local Markers = loadModule("walls")
local Lighting = loadModule("fullbright")
local Weapons = loadModule("norecoil")
local GUI = loadModule("gui")

if not (Services and Config and NPCManager and TargetSizing and Markers and Lighting and Weapons and GUI) then
    error("Failed to load one or more modules. Please verify the remote module files.")
end

Config:load()
Lighting:storeOriginalSettings(Services.Lighting)

local runtimeConnections = {}

local function saveConfig()
    Config:save()
end

local function syncMouseState()
    if Config.guiVisible then
        -- Meniul deschis: forțăm mouse-ul liber
        Services.UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        Services.UserInputService.MouseIconEnabled = true
    else
        -- Meniul închis: eliberăm controlul către joc
        Services.UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        Services.UserInputService.MouseIconEnabled = false
    end
end

local function resetUIFocus()
    -- Căutăm ScreenGui-ul creat de Fluent pentru a-i reseta starea
    local playerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    for _, obj in pairs(playerGui:GetDescendants()) do
        if obj:IsA("ScreenGui") and obj.Name == "Fluent" then
            obj.Enabled = Config.guiVisible
            -- Dacă există un frame de fundal (care blochează input-ul), asigură-te că e setat corect
            -- Uneori Fluent pune .Modal = true pe un frame invizibil
        end
    end
end

local function forceMouseLock()
    Services.UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
    Services.UserInputService.MouseIconEnabled = false
end

local function releaseCameraFocus()
    -- Acestea forțează Roblox să elibereze focusul de pe orice GUI
    Services.UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter

    -- Truc: Simulăm o mică interacțiune pentru a "păcăli" camera jocului
    local VirtualInputManager = game:GetService("VirtualInputManager")
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
end

local function toggleGUIVisibility()
    Config.guiVisible = GUI:toggleVisibility()

    -- Setăm starea o singură dată, la schimbare
    if Config.guiVisible then
        Services.UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        Services.UserInputService.MouseIconEnabled = true

        -- Asigură-te că UI-ul este activ
        local playerGui = Services.Players.LocalPlayer:WaitForChild("PlayerGui")
        for _, gui in pairs(playerGui:GetChildren()) do
            if gui:IsA("ScreenGui") and gui.Name ~= "PlayerGui" then
                gui.Enabled = true
            end
        end
    else
        Services.UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        Services.UserInputService.MouseIconEnabled = false
    end

    return Config.guiVisible
end

local function disconnectRuntimeConnections()
    for _, connection in ipairs(runtimeConnections) do
        pcall(function()
            connection:Disconnect()
        end)
    end
    runtimeConnections = {}
end

local callbacks = {
    onSizingToggle = function(enabled)
        Config.sizingEnabled = enabled
        if not enabled then
            TargetSizing:cleanup(NPCManager)
        end
        NPCManager:refreshTrackedNPCs(Services.Workspace, Markers, TargetSizing, Config)
        saveConfig()
    end,

    onShowTargetBoxToggle = function(enabled)
        Config.showTargetBox = enabled
        NPCManager:refreshTrackedNPCs(Services.Workspace, Markers, TargetSizing, Config)
        saveConfig()
    end,

    onHighlightsToggle = function(enabled)
        Config.highlightEnabled = enabled
        NPCManager:refreshTrackedNPCs(Services.Workspace, Markers, TargetSizing, Config)
        if enabled then
            Markers.enable(NPCManager, Config)
        else
            Markers.disable()
        end
        saveConfig()
    end,

    onFullBrightToggle = function(enabled)
        Config.fullBrightEnabled = enabled
        if not enabled then
            Lighting:restoreOriginal(Services.Lighting)
        end
        saveConfig()
    end,

    onStabilityToggle = function(enabled)
        Config.patchOptions.recoil = enabled
        print("DEBUG: Stability Toggle activat, starea:", enabled)
        Weapons.patchWeapons(Services.ReplicatedStorage, Config.patchOptions)
        saveConfig()
    end,

    onFiremodeOptionsToggle = function(enabled)
        Config.patchOptions.firemodes = enabled
        print("DEBUG: Firemode Toggle activat, starea:", enabled)
        Weapons.patchWeapons(Services.ReplicatedStorage, Config.patchOptions)
        saveConfig()
    end,

    onVisibleRChange = function(value)
        Config:updateVisibleColor(value, nil, nil)
        saveConfig()
    end,

    onVisibleGChange = function(value)
        Config:updateVisibleColor(nil, value, nil)
        saveConfig()
    end,

    onVisibleBChange = function(value)
        Config:updateVisibleColor(nil, nil, value)
        saveConfig()
    end,

    onHiddenRChange = function(value)
        Config:updateHiddenColor(value, nil, nil)
        saveConfig()
    end,

    onHiddenGChange = function(value)
        Config:updateHiddenColor(nil, value, nil)
        saveConfig()
    end,

    onHiddenBChange = function(value)
        Config:updateHiddenColor(nil, nil, value)
        saveConfig()
    end,

    onNPCDetectionRadiusChange = function(value)
        Config:updateNPCDetectionRadius(value)
        NPCManager:refreshTrackedNPCs(Services.Workspace, Markers, TargetSizing, Config)
        saveConfig()
    end,

    onVisibilityToggle = function()
        toggleGUIVisibility()
    end,

    onUnload = function()
        if Config.isUnloaded then
            return
        end

        Config.isUnloaded = true
        disconnectRuntimeConnections()
        Markers.disable()
        TargetSizing:cleanup(NPCManager)
        NPCManager:cleanup()
        Lighting:restoreOriginal(Services.Lighting)
        Config.guiVisible = false
        saveConfig()
        forceMouseLock()
        GUI:destroy()
    end
}

GUI:init(Services, Config, callbacks)
syncMouseState()

NPCManager:scanWorkspace(Services.Workspace, Markers, Config)
NPCManager:setupListener(Services.Workspace, Markers, Config)
if Config.highlightEnabled then
    Markers.enable(NPCManager, Config)
end
if Config.patchOptions.recoil or Config.patchOptions.firemodes then
    print("DEBUG: Inițializare patch-uri arme...")
    Weapons.patchWeapons(Services.ReplicatedStorage, Config.patchOptions)
end

local markerAccumulator = 0
local targetAccumulator = 0
local npcAccumulator = 0

table.insert(runtimeConnections, Services.RunService.Heartbeat:Connect(function(dt)
    if Config.isUnloaded then
        return
    end

    -- DOAR actualizăm poziția cursorului dacă meniul e deschis
    if Config.guiVisible then
        GUI:updateCursorPosition(Services.UserInputService)
        -- Nu forțăm MouseBehavior aici!
    end

    Lighting:update(Services.Lighting, Config)

    npcAccumulator = npcAccumulator + dt
    if npcAccumulator >= Config.NPC_REFRESH_INTERVAL then
        NPCManager:refreshTrackedNPCs(Services.Workspace, Markers, TargetSizing, Config)
        npcAccumulator = 0
    end

    markerAccumulator = markerAccumulator + dt
    if markerAccumulator >= Config.RAYCAST_COOLDOWN then
        local okMarkers, markerError = pcall(Markers.updateColors, NPCManager,
            Services.Workspace.CurrentCamera or Services.camera, Services.Workspace, Services.localPlayer, Config)
        if not okMarkers then
            warn("Markers.updateColors failed: " .. tostring(markerError))
        end
        markerAccumulator = 0
    end

    targetAccumulator = targetAccumulator + dt
    if targetAccumulator >= Config.TARGET_SYNC_INTERVAL then
        TargetSizing:updateAllTargets(NPCManager, Config)
        targetAccumulator = 0
    end
end))

table.insert(runtimeConnections, Services.UserInputService.InputBegan:Connect(
    function(input, gameProcessed)
        if Config.isUnloaded then
            return
        end

        if not gameProcessed and input.KeyCode == Enum.KeyCode.Insert then
            toggleGUIVisibility()
        end
    end))
