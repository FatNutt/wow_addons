-- ============================================================================
-- Init.lua — Addon Initialization
-- ============================================================================
-- This file is loaded FIRST (after libraries). It sets up:
--   1. The addon namespace (shared table between all files)
--   2. The event dispatcher (table-dispatch pattern)
--   3. SavedVariables initialization
--   4. Slash command registration
--   5. Addon Compartment button callbacks
--
-- PATTERN: local addonName, ns = ...
--   addonName = string name of this addon (matches the folder name)
--   ns = a private table shared between ALL .lua files listed in the .toc
--   Use ns.* to share data/functions between files. Never use globals.
-- ============================================================================

-- Capture the addon name and shared namespace.
-- Every .lua file in the .toc receives the same (addonName, ns) pair.
local addonName, ns = ...

-- ============================================================================
-- Namespace Setup
-- ============================================================================
-- The namespace table (ns) is your addon's private global space.
-- Attach everything here — data, functions, frame references.
-- Other files access it as: local addonName, ns = ...

-- Store the addon name for use in other files (texture paths, etc.)
ns.addonName = addonName

-- Default settings. These are used when SavedVariables don't exist yet
-- (first install) or when a new setting is added in an update.
-- ALWAYS define defaults here so the rest of the code can assume
-- ns.db.settingName exists and has a valid value.
ns.defaults = {
    _version = 1,         -- DB schema version (increment when restructuring)
    enabled = true,       -- Master toggle
    scale = 1.0,          -- UI scale multiplier
    showWelcome = true,   -- Show login message
    anchorPoint = "CENTER", -- Frame anchor
    xOffset = 0,          -- Horizontal offset
    yOffset = 100,        -- Vertical offset
}

-- ============================================================================
-- Secret Values (Midnight 12.0+)
-- ============================================================================
-- In M+, PvP, and boss encounters, combat APIs (UnitHealth, spell
-- cooldowns, etc.) return opaque "secret values" that cannot be
-- compared, used in arithmetic, or tested for truthiness.
-- Always guard with issecretvalue() before doing math or comparisons.

--- Whether the Secret Values system is available (12.0+)
ns.SECRETS_ENABLED = type(issecretvalue) == "function"

--- Safely unwrap a value that might be a secret.
--- Returns fallback if the value is secret, otherwise returns the value.
---@param val any
---@param fallback any
---@return any
function ns.SafeValue(val, fallback)
    if ns.SECRETS_ENABLED and issecretvalue(val) then
        return fallback
    end
    return val
end

-- ============================================================================
-- Utilities
-- ============================================================================

--- Create a debounced version of a function.
--- Calls fn at most once per `delay` seconds; resets timer on each call.
---@param delay number Seconds to wait
---@param fn function Function to call
---@return function debounced Call this instead of fn directly
function ns.Debounce(delay, fn)
    local timer
    return function(...)
        if timer then timer:Cancel() end
        local args = { ... }
        timer = C_Timer.NewTimer(delay, function()
            timer = nil
            fn(unpack(args))
        end)
    end
end

-- ============================================================================
-- Event Dispatcher
-- ============================================================================
-- The table-dispatch pattern: register event handlers as methods on a table,
-- then dispatch in OnEvent. This is cleaner than a giant if/elseif chain
-- and makes it trivial to add new events.
--
-- WHY a hidden frame? WoW events require a Frame to listen on.
-- We create one invisible frame solely for event handling.

-- Create a hidden frame for event registration.
-- It has no size, no parent visibility — it exists only to receive events.
local eventFrame = CreateFrame("Frame")

-- The dispatch table. Keys are event names, values are handler functions.
-- When an event fires, we look up the handler and call it.
local eventHandlers = {}

-- The OnEvent script: look up the event name in our dispatch table
-- and call the handler if one exists. The ... captures event-specific args.
eventFrame:SetScript("OnEvent", function(self, event, ...)
    local handler = eventHandlers[event]
    if handler then
        handler(self, event, ...)
    end
end)

-- Helper: register an event and its handler in one call.
-- This keeps registration and handler definition together.
local function RegisterEvent(event, handler)
    eventHandlers[event] = handler
    eventFrame:RegisterEvent(event)
end

-- Helper: unregister an event (stops it from firing).
local function UnregisterEvent(event)
    eventHandlers[event] = nil
    eventFrame:UnregisterEvent(event)
end

-- Export helpers to the namespace so other files can use them.
ns.RegisterEvent = RegisterEvent
ns.UnregisterEvent = UnregisterEvent

-- ============================================================================
-- ADDON_LOADED Handler
-- ============================================================================
-- ADDON_LOADED fires once per addon, with the addon name as the first arg.
-- This is the EARLIEST point where SavedVariables are available.
-- Use this for: DB init, slash commands, static setup.
-- Do NOT create visible UI here — the game world isn't ready yet.

RegisterEvent("ADDON_LOADED", function(self, event, loadedAddon)
    -- ADDON_LOADED fires for EVERY addon. Only act on ours.
    if loadedAddon ~= addonName then return end

    -- We only need this event once. Unregister to avoid wasted cycles.
    UnregisterEvent("ADDON_LOADED")

    -- ---- Initialize SavedVariables ----
    -- If this is the first load (fresh install), the global will be nil.
    -- Create it with an empty table so we can merge defaults into it.
    if not WarGamesDB then
        WarGamesDB = {}
    end

    -- Merge defaults: for any key in ns.defaults that doesn't exist
    -- in the saved data, copy the default value. This handles:
    --   - Fresh installs (all defaults applied)
    --   - Addon updates that add new settings (new defaults applied,
    --     existing user settings preserved)
    for key, defaultValue in pairs(ns.defaults) do
        if WarGamesDB[key] == nil then
            WarGamesDB[key] = defaultValue
        end
    end

    -- Point ns.db at the SavedVariables table for convenient access.
    -- All other files use ns.db.settingName to read/write settings.
    ns.db = WarGamesDB

    -- ---- SavedVariables Migration ----
    -- Bump ns.defaults._version when you restructure the DB.
    -- Add migration blocks here to transform old data:
    --
    -- if (ns.db._version or 0) < 2 then
    --     -- v1 → v2: rename "showWelcome" to "welcomeEnabled"
    --     if ns.db.showWelcome ~= nil then
    --         ns.db.welcomeEnabled = ns.db.showWelcome
    --         ns.db.showWelcome = nil
    --     end
    -- end
    --
    ns.db._version = ns.defaults._version

    -- ---- Per-character SavedVariables (optional) ----
    -- Uncomment if you declared SavedVariablesPerCharacter in the .toc:
    -- if not WarGamesCharDB then WarGamesCharDB = {} end
    -- ns.charDb = WarGamesCharDB

    -- ---- Register Slash Commands ----
    -- Slash commands require two things:
    --   1. A global SLASH_NAME1 = "/command" (the trigger)
    --   2. A SlashCmdList["NAME"] = function (the handler)
    -- The NAME must be uppercase and match between both.
    SLASH_WARGAMES1 = "/wargames"
    SLASH_WARGAMES2 = "/wg"  -- Short alias
    SlashCmdList["WARGAMES"] = function(input)
        -- input is everything after the slash command, trimmed.
        local cmd = strlower(strtrim(input or ""))

        if cmd == "config" or cmd == "options" then
            -- Open the Settings panel to our category.
            -- ns.settingsCategoryID is set in Config.lua.
            if ns.settingsCategoryID then
                Settings.OpenToCategory(ns.settingsCategoryID)
            end
        elseif cmd == "toggle" then
            -- Toggle the main feature
            ns.db.enabled = not ns.db.enabled
            if ns.db.enabled then
                print("|cff00ff00" .. addonName .. "|r enabled.")
                ns:Enable()
            else
                print("|cffff0000" .. addonName .. "|r disabled.")
                ns:Disable()
            end
        elseif cmd == "reset" then
            -- Reset all settings to defaults
            for key, value in pairs(ns.defaults) do
                ns.db[key] = value
            end
            print(addonName .. ": Settings reset to defaults.")
            -- Refresh the UI if it exists
            if ns.RefreshUI then ns:RefreshUI() end
        else
            -- Show help text
            print("|cff33ff99" .. addonName .. "|r commands:")
            print("  /wargames config  — Open settings")
            print("  /wargames toggle  — Enable/disable")
            print("  /wargames reset   — Reset settings to defaults")
        end
    end

    -- ---- Register Settings Panel ----
    -- Config.lua defines ns:RegisterSettings(). Call it now that the DB exists.
    if ns.RegisterSettings then
        ns:RegisterSettings()
    end

    -- Print a subtle load confirmation (debug-only, remove for release).
    --@debug@
    print(format("%s loaded (v%s).",
        addonName,
        C_AddOns.GetAddOnMetadata(addonName, "Version") or "dev"))
    --@end-debug@
end)

-- ============================================================================
-- PLAYER_LOGIN Handler
-- ============================================================================
-- PLAYER_LOGIN fires once after the player enters the world.
-- This is the RIGHT time to: create UI, register gameplay events,
-- start timers, and do anything that depends on the game world.
--
-- Why not PLAYER_ENTERING_WORLD? That fires on EVERY loading screen
-- (portals, instances, etc.). PLAYER_LOGIN fires exactly once per session.

RegisterEvent("PLAYER_LOGIN", function(self, event)
    -- We only need this event once.
    UnregisterEvent("PLAYER_LOGIN")

    -- ---- Initialize Core Features ----
    -- Core.lua defines ns:Enable(). Call it to start the addon's features.
    if ns.db.enabled and ns.Enable then
        ns:Enable()
    end

    -- ---- Welcome Message ----
    if ns.db.showWelcome then
        print(format("|cff33ff99%s|r: Type |cffffd100/%s|r for options.",
            addonName, strlower(addonName)))
    end
end)

-- ============================================================================
-- Addon Compartment Callbacks (Minimap Dropdown)
-- ============================================================================
-- These functions MUST be global — the TOC references them by name.
-- They are called when the player interacts with the addon's entry
-- in the minimap Addon Compartment dropdown (introduced in 10.1.0).
--
-- Callback signatures for TOC-based registration:
--   function(addonName, buttonName)            -- Click
--   function(addonName, menuButtonFrame)       -- Enter/Leave

-- Left-click: toggle addon or open settings.
-- Right-click: open settings.
function WarGames_OnCompartmentClick(_, buttonName)
    if buttonName == "RightButton" then
        if ns.settingsCategoryID then
            Settings.OpenToCategory(ns.settingsCategoryID)
        end
    else
        -- Left-click: toggle the main feature
        if ns.db then
            ns.db.enabled = not ns.db.enabled
            if ns.db.enabled then
                if ns.Enable then ns:Enable() end
            else
                if ns.Disable then ns:Disable() end
            end
        end
    end
end

-- Mouse enters the compartment button: show a tooltip.
function WarGames_OnCompartmentEnter(_, menuButtonFrame)
    GameTooltip:SetOwner(menuButtonFrame, "ANCHOR_LEFT")
    GameTooltip:SetText(addonName)
    GameTooltip:AddLine("Left-click to toggle.", 1, 1, 1)
    GameTooltip:AddLine("Right-click for settings.", 1, 1, 1)
    GameTooltip:Show()
end

-- Mouse leaves the compartment button: hide the tooltip.
function WarGames_OnCompartmentLeave(_, _menuButtonFrame)
    GameTooltip:Hide()
end
