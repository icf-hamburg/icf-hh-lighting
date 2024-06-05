
local function setMeasure(preset_nr, groups, ma_attribute)
    -- Group 10 At Preset 21.1 Attribute "Dimmer" At Measure 0.75 Store Preset 21.47
    local str = "Group " .. groups .. " At Preset 21." .. preset_nr .. " Attribute "
    str = str .. "\"" .. ma_attribute .. "\" At Measure "

    Cmd(str .. "0.75")
    Cmd("Store Preset 21." .. preset_nr + 1)


    Cmd(str .. "1.5")
    Cmd("Store Preset 21." .. preset_nr + 2)

    local phaser_pool = FromAddr("13.13.1.4.21")
    local name = phaser_pool[preset_nr].Name
    phaser_pool[preset_nr + 1].Name = name .. " T(3/4)"
    phaser_pool[preset_nr + 2].Name = name .. " T(6/4)"

end


return function(display_handle, argument)
    -- argument = 50
    Cmd("ClearAll")

    argument = tonumber(argument)
    Printf(argument)

    if argument == nil then
        ErrPrintf("Plugin needs to be called with Preset to be cloned from Preset Pool 21.")
        return
    end

    local groups = { 10, 20 }

    local phaser_pool = FromAddr("13.13.1.4.21")

    local main_preset = phaser_pool[argument]
    Printf(main_preset:Dump()   )
    local main_preset_is_missing = main_preset == nil

    if main_preset_is_missing then
        ErrPrintf("Preset 21." .. argument .. " does not exist")
        return
    end

    -- local main_phaser_name = main_preset.Name
    -- Printf("Name of preset 21." .. argument .. ": " .. main_phaser_name)

    local ahead1 = argument + 1
    local ahead2 = argument + 2
    local ahead_is_empty = ((phaser_pool[ahead1] == nil) and (phaser_pool[ahead2] == nil))

    if not ahead_is_empty then
        ErrPrintf("Preset 21." .. ahead1 .. " _AND_ 21." .. ahead2 .. " need to be empty")
        return
    end

    local groups_str = ""
    for k, v in pairs(groups) do
        groups_str = groups_str .. " + " .. v
    end
    groups_str = string.sub(groups_str, 4) -- remove first 3 chars


    -- Printf("Groups which are affected: " .. groups_str)
    setMeasure(argument, groups_str, "Dimmer")
    Cmd("ClearAll")

end
