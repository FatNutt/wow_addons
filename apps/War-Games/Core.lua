-- ============================================================================
-- Core.lua — Main Addon Logic
-- ============================================================================
-- This file contains the addon's primary feature code:
--   1. Frame creation and layout
--   2. hooksecurefunc examples (the Midnight-safe way to modify Blizzard UI)
--   3. Combat lockdown handling (queue operations for after combat)
--   4. C_Timer usage for delayed/repeating operations
--   5. Event registration patterns
--
-- MIDNIGHT RULES:
--   - Always use hooksecurefunc() to modify Blizzard frames (runs AFTER)
--   - Always check frame:IsForbidden() before touching any hooked frame
--   - Never call :Show()/:Hide()/:SetPoint() on secure frames during combat
--   - Use InCombatLockdown() to check if the player is in combat
--   - Use issecretvalue() before comparing/computing combat values
--   - Use Duration Objects (C_DurationUtil) for cooldown display
-- ============================================================================

local addonName, ns = ...

-- ============================================================================
-- Upvalues (Performance)
-- ============================================================================
-- Localizing frequently-called globals avoids repeated global table lookups.
-- This matters in hot paths (OnUpdate, event handlers that fire often).
-- For rarely-called functions, don't bother — readability > micro-optimization.
local CreateFrame = CreateFrame
local hooksecurefunc = hooksecurefunc
local InCombatLockdown = InCombatLockdown
local UnitName = UnitName
local UnitClass = UnitClass
local UnitLevel = UnitLevel
local format = format

-- ============================================================================
-- Combat Lockdown Queue
-- ============================================================================
-- Many frame operations (Show, Hide, SetPoint, SetAttribute) are FORBIDDEN
-- on secure/protected frames during combat. If your code needs to do these
-- things, queue them and execute after combat ends.
--
-- PATTERN:
--   1. Check InCombatLockdown() before modifying frames
--   2. If in combat, push the operation to a queue
--   3. On PLAYER_REGEN_ENABLED (combat ends), flush the queue

-- Queue of functions to run after combat ends.
local combatQueue = {}

-- Queue a function to run after combat ends (or run immediately if not in combat).
local function RunAfterCombat(func)
    if InCombatLockdown() then
        -- We're in combat — defer the operation.
        combatQueue[#combatQueue + 1] = func
    else
        -- Not in combat — run immediately.
        func()
    end
end

-- Export to namespace so other files can use it.
ns.RunAfterCombat = RunAfterCombat

-- Register the combat-end event to flush the queue.
-- PLAYER_REGEN_ENABLED fires when the player LEAVES combat.
-- PLAYER_REGEN_DISABLED fires when the player ENTERS combat.
ns.RegisterEvent("PLAYER_REGEN_ENABLED", function()
    -- Flush all queued operations.
    for i = 1, #combatQueue do
        combatQueue[i]()
        combatQueue[i] = nil
    end
end)

-- ============================================================================
-- Main Display Frame
-- ============================================================================
-- This creates a simple draggable info frame to demonstrate frame creation,
-- event handling, and the namespace pattern.

local function CreateInfoFrame()
    -- Create the main frame with a backdrop for visibility.
    -- BackdropTemplate provides :SetBackdrop() and :SetBackdropColor().
    local frame = CreateFrame("Frame", "WarGamesInfoFrame", UIParent,
        "BackdropTemplate")

    -- Size and position. We use saved position if available.
    frame:SetSize(220, 80)
    frame:SetPoint(
        ns.db.anchorPoint, UIParent, ns.db.anchorPoint,
        ns.db.xOffset, ns.db.yOffset
    )

    -- Visual appearance: dark semi-transparent background with a thin border.
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    frame:SetBackdropColor(0.05, 0.05, 0.05, 0.8)
    frame:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

    -- ---- Make it draggable ----
    -- SetMovable + RegisterForDrag + OnDragStart/Stop is the standard pattern.
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetClampedToScreen(true)  -- Prevent dragging off-screen

    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        -- Save the new position to SavedVariables.
        local point, _, _, x, y = self:GetPoint()
        ns.db.anchorPoint = point
        ns.db.xOffset = x
        ns.db.yOffset = y
    end)

    -- ---- Title Text ----
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", 8, -8)
    title:SetText("|cff33ff99" .. addonName .. "|r")

    -- ---- Info Text (updated dynamically) ----
    local info = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    info:SetPoint("TOPLEFT", 8, -26)
    info:SetPoint("BOTTOMRIGHT", -8, 8)
    info:SetJustifyH("LEFT")
    info:SetJustifyV("TOP")
    frame.infoText = info

    -- Store on namespace for access from other files.
    ns.infoFrame = frame

    return frame
end

-- ============================================================================
-- Update Logic
-- ============================================================================
-- Update the info display with current player data.
-- This demonstrates reading game data and formatting it for display.
--
-- Note: In Midnight 12.0+, some combat APIs return "secret values" during
-- M+, PvP, and boss encounters. Use ns.SafeValue() to guard any value
-- before using it in string formatting or comparisons. Widget setters
-- (StatusBar:SetValue, FontString:SetText) accept secret values directly
-- — only guard when doing Lua-side math or format().

local function UpdateInfoDisplay()
    local frame = ns.infoFrame
    if not frame or not frame:IsShown() then return end

    local name = UnitName("player")
    local _, className = UnitClass("player")
    local classColor = RAID_CLASS_COLORS[className]

    -- UnitLevel() can return a secret value during M+/PvP/encounters in
    -- Midnight 12.0+. Guard before using in format() or comparisons.
    local level = UnitLevel("player")
    level = ns.SafeValue(level, "??")  -- Falls back to "??" if secret

    local lines = {}
    lines[1] = format("Player: %s%s|r",
        classColor and classColor:GenerateHexColorMarkup() or "|cffffffff",
        name or "Unknown")
    lines[2] = format("Level: %s", level)
    lines[3] = format("Zone: %s", GetZoneText() or "Unknown")

    frame.infoText:SetText(table.concat(lines, "\n"))
end

-- ============================================================================
-- hooksecurefunc Examples
-- ============================================================================
-- hooksecurefunc() is the SAFE way to modify Blizzard frames in Midnight.
-- It runs your function AFTER Blizzard's code — you never replace or
-- pre-empt their logic. This avoids taint (secure frame corruption).
--
-- Two forms:
--   hooksecurefunc("GlobalFuncName", yourFunc)      -- Hook a global function
--   hooksecurefunc(object, "MethodName", yourFunc)   -- Hook a method on an object
--
-- Your hook receives the SAME arguments as the original function.

local function SetupHooks()
    -- EXAMPLE 1: Hook a global Blizzard function.
    -- CompactUnitFrame_UpdateName fires when a raid frame's name updates.
    -- We restyle the name font after Blizzard sets it.
    --
    -- NOTE: This function lives in Blizzard_CompactRaidFrames, which may
    -- not be loaded yet. Use ADDON_LOADED to wait for it if needed.
    if CompactUnitFrame_UpdateName then
        hooksecurefunc("CompactUnitFrame_UpdateName", function(frame)
            -- ALWAYS check IsForbidden(). Forbidden frames belong to
            -- Blizzard's secure environment and CANNOT be modified.
            -- Accessing a forbidden frame throws an error.
            if frame:IsForbidden() then return end

            -- Restyle the name text.
            if frame.name then
                frame.name:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
            end
        end)
    end

    -- EXAMPLE 2: Hook a method on a specific frame object.
    -- This runs after PlayerFrame updates its health bar.
    -- Useful for reskinning without replacing the frame.
    --
    -- RECURSION GUARD: If your hook calls the same method it's hooking,
    -- use a flag to prevent infinite loops.
    -- if PlayerFrame and PlayerFrame.PlayerFrameContent then
    --     local healthBar = PlayerFrame.PlayerFrameContent
    --         .PlayerFrameContentMain.HealthBarsContainer.HealthBar
    --     if healthBar then
    --         hooksecurefunc(healthBar, "UpdateFillBar", function(self)
    --             if self:IsForbidden() then return end
    --             -- Your customization here
    --         end)
    --     end
    -- end
end

-- ============================================================================
-- C_Timer Examples
-- ============================================================================
-- C_Timer provides timer functions that are SAFE in the WoW environment.
-- Unlike CreateFrame + OnUpdate, timers don't run every frame — they fire
-- at a specific time, which is better for performance.
--
--   C_Timer.After(seconds, callback)         — One-shot timer
--   C_Timer.NewTimer(seconds, callback)      — One-shot, returns handle
--   C_Timer.NewTicker(seconds, callback, n)  — Repeating, optional count

local function StartPeriodicUpdate()
    -- Update the info display every 2 seconds.
    -- NewTicker returns a handle you can :Cancel() later.
    ns.updateTicker = C_Timer.NewTicker(2, function()
        UpdateInfoDisplay()
    end)
end

local function StopPeriodicUpdate()
    if ns.updateTicker then
        ns.updateTicker:Cancel()
        ns.updateTicker = nil
    end
end

-- ============================================================================
-- Enable / Disable
-- ============================================================================
-- Called from Init.lua when the addon should start or stop.
-- Separating enable/disable from creation allows clean toggling.

function ns:Enable()
    -- Create the frame if it doesn't exist yet.
    if not ns.infoFrame then
        CreateInfoFrame()
    end

    -- Show the frame (defer if in combat, since it might be a secure child).
    RunAfterCombat(function()
        if ns.infoFrame then
            ns.infoFrame:Show()
        end
    end)

    -- Register events we care about during gameplay.
    ns.RegisterEvent("ZONE_CHANGED_NEW_AREA", function()
        UpdateInfoDisplay()
    end)

    ns.RegisterEvent("PLAYER_LEVEL_UP", function()
        UpdateInfoDisplay()
    end)

    -- Start periodic updates.
    StartPeriodicUpdate()

    -- Set up hooks ONCE. hooksecurefunc() is permanent — calling it again
    -- on the same function stacks another hook, causing duplicate work and
    -- potential performance issues. The ns.hooksApplied flag ensures we
    -- only install hooks on the first Enable() call.
    if not ns.hooksApplied then
        SetupHooks()
        ns.hooksApplied = true
    end

    -- Initial update.
    UpdateInfoDisplay()
end

function ns:Disable()
    -- Hide the frame.
    RunAfterCombat(function()
        if ns.infoFrame then
            ns.infoFrame:Hide()
        end
    end)

    -- Unregister gameplay events (stop processing them).
    ns.UnregisterEvent("ZONE_CHANGED_NEW_AREA")
    ns.UnregisterEvent("PLAYER_LEVEL_UP")

    -- Stop periodic updates.
    StopPeriodicUpdate()
end

-- ============================================================================
-- Refresh UI
-- ============================================================================
-- Called when settings change (from Config.lua callbacks).
-- Repositions/rescales the frame based on current settings.

function ns:RefreshUI()
    local frame = ns.infoFrame
    if not frame then return end

    RunAfterCombat(function()
        -- Reposition using saved settings.
        frame:ClearAllPoints()
        frame:SetPoint(
            ns.db.anchorPoint, UIParent, ns.db.anchorPoint,
            ns.db.xOffset, ns.db.yOffset
        )

        -- Apply scale.
        frame:SetScale(ns.db.scale)

        -- Update content.
        UpdateInfoDisplay()
    end)
end
