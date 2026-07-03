-- ============================================================================
-- .luacheckrc — Luacheck Static Analysis Configuration
-- ============================================================================
-- Luacheck catches bugs before they hit production:
--   - Undefined global access (typos, missing imports)
--   - Unused variables (dead code)
--   - Shadowed variables (accidentally reusing names)
--   - Unreachable code
--
-- Install: brew install luacheck  (macOS)
-- Run:     luacheck .
-- CI:      Uses nebularg/actions-luacheck@v1 in GitHub Actions
--
-- For a comprehensive auto-generated config covering ALL WoW globals,
-- see: https://github.com/Jayrgo/wow-luacheckrc
--
-- Reference: https://luacheck.readthedocs.io/
-- ============================================================================

-- WoW uses Lua 5.1. This sets the base standard library.
std = "lua51"

-- Don't enforce line length — WoW addon code often has long lines
-- for readability (function calls with many args, table constructors).
max_line_length = false

-- ============================================================================
-- Excluded Directories
-- ============================================================================
-- Don't lint external libraries or build artifacts.
-- Libs/ contains third-party code fetched by the packager.
-- .release/ is the packager's staging directory.
exclude_files = {
    "Libs",
    "Libs/**",
    ".release",
    ".release/**",
}

-- ============================================================================
-- Ignored Warnings
-- ============================================================================
-- Suppress false positives common in WoW addon code.
ignore = {
    -- 11x: Setting globals. We intentionally set SLASH_* and SlashCmdList.
    "11./SLASH_",

    -- 212: Unused argument. Common in WoW callbacks where you must accept
    -- 'self' and 'event' even if you only use the varargs.
    "212/self",
    "212/event",
    "212/...",
}

-- ============================================================================
-- Addon Globals (Writable)
-- ============================================================================
-- These are globals that YOUR addon intentionally creates.
-- Slash command globals and SavedVariables must be global.
globals = {
    -- Slash command triggers (set in Init.lua)
    "SLASH_War_Games1",
    "SLASH_War_Games2",

    -- SavedVariables (declared in .toc, must be global Lua variables)
    "War_GamesDB",
    "War_GamesCharDB",

    -- Addon Compartment callbacks (must be global for TOC reference)
    "War_Games_OnCompartmentClick",
    "War_Games_OnCompartmentEnter",
    "War_Games_OnCompartmentLeave",

    -- SlashCmdList — Init.lua writes to it (SlashCmdList["War_Games"] = ...)
    "SlashCmdList",
}

-- ============================================================================
-- WoW Environment Read-Only Globals
-- ============================================================================
-- These are globals provided by the WoW client that your code reads but
-- never writes to. This is NOT exhaustive — add what you use.
-- For a complete list, use Jayrgo/wow-luacheckrc.
read_globals = {
    -- ---- Core Frame & Widget API ----
    "CreateFrame",
    "UIParent",
    "WorldFrame",
    "GameTooltip",
    "Settings",
    "MinimalSliderWithSteppersMixin",

    -- ---- Addon Management ----
    "C_AddOns",

    -- ---- Unit Functions ----
    "UnitName",
    "UnitClass",
    "UnitLevel",
    "UnitHealth",
    "UnitHealthMax",
    "UnitHealthPercent",
    "UnitPower",
    "UnitPowerMax",
    "UnitPowerPercent",
    "UnitExists",
    "UnitIsPlayer",
    "UnitIsDeadOrGhost",
    "UnitGroupRolesAssigned",
    "GetComboPoints",
    "IsInRaid",
    "GetZoneText",

    -- ---- Combat & Security ----
    "InCombatLockdown",
    "issecretvalue",
    "hooksecurefunc",
    "securecallfunction",

    -- ---- Timers ----
    "C_Timer",
    "GetTime",

    -- ---- Spell & Action Bar (12.0 namespaces) ----
    "C_Spell",
    "C_SpellBook",
    "C_ActionBar",
    "C_DurationUtil",
    "C_Secrets",

    -- ---- Cooldown Manager ----
    "C_DamageMeter",
    "C_EncounterTimeline",
    "C_CombatLog",

    -- ---- Edit Mode ----
    "C_EditMode",
    "EditModeManagerFrame",
    "EventRegistry",

    -- ---- Modern UI ----
    "C_Container",
    "C_NamePlate",
    "MenuUtil",
    "Menu",

    -- ---- Class Colors ----
    "RAID_CLASS_COLORS",
    "NORMAL_FONT_COLOR",
    "RED_FONT_COLOR",
    "GREEN_FONT_COLOR",
    "HIGHLIGHT_FONT_COLOR",
    "CreateColor",

    -- ---- Mixins & Templates ----
    "Mixin",
    "CreateFromMixins",
    "CreateAndInitFromMixin",
    "BackdropTemplateMixin",

    -- ---- Common Blizzard Frames ----
    "PlayerFrame",
    "TargetFrame",
    "FocusFrame",
    "NamePlateDriverFrame",
    "PlayerCastingBarFrame",
    "CompactUnitFrame_UpdateName",

    -- ---- String Functions (WoW aliases) ----
    "strlower",
    "strupper",
    "strtrim",
    "strsplit",
    "strjoin",
    "format",

    -- ---- Table Functions (WoW aliases) ----
    "tinsert",
    "tremove",
    "wipe",
    "tContains",
    "tInvert",
    "CopyTable",

    -- ---- Math Functions (WoW aliases) ----
    "min",
    "max",
    "floor",
    "ceil",
    "abs",
    "random",

    -- ---- Misc ----
    "print",
    "date",
    "time",
    "GetBuildInfo",
    "GetLocale",
    "IsLoggedIn",
    "MAX_RAID_MEMBERS",
    "LibStub",
    "WOW_PROJECT_ID",
    "WOW_PROJECT_MAINLINE",

    -- ---- Event System ----
    "PLAYER_REGEN_ENABLED",
    "PLAYER_REGEN_DISABLED",
}
