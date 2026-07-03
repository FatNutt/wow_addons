-- ============================================================================
-- Config.lua — Settings Panel
-- ============================================================================
-- This file registers addon settings with Blizzard's modern Settings API,
-- introduced in 10.0 and updated in 11.0.2 with new signatures.
--
-- The Settings API automatically creates a polished options panel in
-- Game Menu > Options > AddOns. No custom frame code needed — Blizzard
-- handles layout, scrolling, and the Apply/Cancel/Default flow.
--
-- KEY FUNCTIONS:
--   Settings.RegisterVerticalLayoutCategory(name)  — Auto-stacking controls
--   Settings.RegisterAddOnSetting(...)             — Bind a setting to your DB
--   Settings.CreateCheckbox(category, setting, tooltip)
--   Settings.CreateSlider(category, setting, options, tooltip)
--   Settings.CreateDropdown(category, setting, getOptions, tooltip)
--   Settings.RegisterAddOnCategory(category)       — Add to AddOns tab
--
-- SIGNATURES CHANGED IN 11.0.2:
--   Settings.RegisterAddOnSetting(categoryTbl, variable, variableKey,
--       variableTbl, variableType, name, defaultValue)
--
-- Reference: https://warcraft.wiki.gg/wiki/Settings_API
-- ============================================================================

local addonName, ns = ...

-- ============================================================================
-- Register Settings
-- ============================================================================
-- Called from Init.lua after SavedVariables are loaded.
-- At this point, ns.db is guaranteed to exist and have all default values.

function ns:RegisterSettings()
    -- Create a category for our addon in the AddOns settings tab.
    -- RegisterVerticalLayoutCategory auto-stacks controls vertically.
    -- For a fully custom layout, use RegisterCanvasLayoutCategory instead.
    local category = Settings.RegisterVerticalLayoutCategory(addonName)

    -- Store the category ID so slash commands can open it.
    ns.settingsCategoryID = category:GetID()

    -- ================================================================
    -- Checkbox: Enable/Disable the addon
    -- ================================================================
    -- RegisterAddOnSetting creates a setting object that reads/writes
    -- directly from/to a table field. The signature (11.0.2+):
    --
    --   Settings.RegisterAddOnSetting(
    --       categoryTbl,   -- The category from RegisterVerticalLayoutCategory
    --       variable,      -- Unique string ID (used internally)
    --       variableKey,   -- Key name in the variableTbl (string)
    --       variableTbl,   -- The table to read/write (your SavedVariables)
    --       variableType,  -- type() of the value: type(false), type(0), etc.
    --       name,          -- Display name shown to the player
    --       defaultValue   -- Default value (used by the "Defaults" button)
    --   )
    do
        local setting = Settings.RegisterAddOnSetting(category,
            addonName .. "_Enabled",  -- Unique ID (convention: AddonName_SettingName)
            "enabled",                -- Key in ns.db
            ns.db,                    -- The table (our SavedVariables)
            type(true),               -- Variable type (boolean)
            "Enable " .. addonName,   -- Display name
            ns.defaults.enabled       -- Default value
        )

        -- CreateCheckbox generates a toggle control bound to this setting.
        -- The third argument is tooltip text shown on hover.
        Settings.CreateCheckbox(category, setting,
            "Enable or disable the addon's display frame.")

        -- React to changes in real time (not just on Apply).
        -- This callback fires whenever the player toggles the checkbox.
        setting:SetValueChangedCallback(function(_, newValue)
            ns.db.enabled = newValue
            if newValue then
                if ns.Enable then ns:Enable() end
            else
                if ns.Disable then ns:Disable() end
            end
        end)
    end

    -- ================================================================
    -- Slider: Frame Scale
    -- ================================================================
    -- Sliders need an options object to define min, max, and step.
    do
        local setting = Settings.RegisterAddOnSetting(category,
            addonName .. "_Scale",
            "scale",
            ns.db,
            type(1.0),               -- Variable type (number)
            "Frame Scale",
            ns.defaults.scale
        )

        -- CreateSliderOptions defines the slider's range and step size.
        local options = Settings.CreateSliderOptions(
            0.5,   -- Minimum value
            2.0,   -- Maximum value
            0.05   -- Step size (granularity)
        )

        -- SetLabelFormatter adds a visual label to the slider.
        -- Label.Right shows the current value on the right side.
        options:SetLabelFormatter(
            MinimalSliderWithSteppersMixin.Label.Right
        )

        Settings.CreateSlider(category, setting, options,
            "Adjust the scale of the addon's display frame.")

        setting:SetValueChangedCallback(function(_, newValue)
            ns.db.scale = newValue
            if ns.RefreshUI then ns:RefreshUI() end
        end)
    end

    -- ================================================================
    -- Checkbox: Show Welcome Message
    -- ================================================================
    do
        local setting = Settings.RegisterAddOnSetting(category,
            addonName .. "_ShowWelcome",
            "showWelcome",
            ns.db,
            type(true),
            "Show Welcome Message",
            ns.defaults.showWelcome
        )

        Settings.CreateCheckbox(category, setting,
            "Show a welcome message in chat when you log in.")

        -- No callback needed — this is only read at login time.
    end

    -- ================================================================
    -- Dropdown Example (Commented Out)
    -- ================================================================
    -- Dropdowns use Settings.CreateDropdown with a function that returns
    -- a container of labeled options.
    --
    -- do
    --     local function GetAnchorOptions()
    --         local container = Settings.CreateControlTextContainer()
    --         container:Add("CENTER", "Center")
    --         container:Add("TOPLEFT", "Top Left")
    --         container:Add("TOPRIGHT", "Top Right")
    --         container:Add("BOTTOMLEFT", "Bottom Left")
    --         container:Add("BOTTOMRIGHT", "Bottom Right")
    --         return container:GetData()
    --     end
    --
    --     local setting = Settings.RegisterAddOnSetting(category,
    --         addonName .. "_AnchorPoint",
    --         "anchorPoint",
    --         ns.db,
    --         type(""),                -- Variable type (string)
    --         "Anchor Point",
    --         ns.defaults.anchorPoint
    --     )
    --
    --     Settings.CreateDropdown(category, setting, GetAnchorOptions,
    --         "Choose where the frame anchors on screen.")
    --
    --     setting:SetValueChangedCallback(function(_, newValue)
    --         ns.db.anchorPoint = newValue
    --         if ns.RefreshUI then ns:RefreshUI() end
    --     end)
    -- end

    -- ================================================================
    -- Section Headers (optional, for organizing larger settings panels)
    -- ================================================================
    -- Uncomment to add a visual separator between control groups:
    --
    -- local headerText = Settings.CreateControlTextContainer()
    -- headerText:Add("Appearance")
    -- Settings.CreateControls(category, headerText)

    -- ================================================================
    -- Register the category in the AddOns tab
    -- ================================================================
    -- This MUST be called last. After this, the category appears in
    -- Game Menu > Options > AddOns.
    Settings.RegisterAddOnCategory(category)
end
