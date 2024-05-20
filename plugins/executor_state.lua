-- Source: https://github.com/xxpasixx/pam-osc/blob/main/pam-OSC.lua


local executorsToWatch = {}
local oldValues = {}
local oldButtonValues = {}
local oldNameValues = {}
local oldMasterEnabledValue = {
    highlight = false,
    lowlight = false,
    solo = false,
    blind = false
}

local oscEntry = 6
local oscPrefix = "gma3_tosc"
local SendOSC = 'SendOSC ' .. oscEntry .. ' "/' .. oscPrefix

-- Configure here, what executors you want to watch:
for i = 201, 210 do
    executorsToWatch[#executorsToWatch + 1] = i
end

-- set the default Values
for _, number in ipairs(executorsToWatch) do
    oldValues[number] = "000"
    oldButtonValues[number] = false
    oldNameValues[number] = ";"
end

-- the Speed to check executors
local tick = 1 / 10 -- 1/10
local resendTick = 0



local function getName(sequence)
    if sequence["CUENAME"] ~= nil then
        return sequence["NAME"] .. ";" .. sequence["CUENAME"]
    end
    return sequence["NAME"] .. ";"
end

local function getMasterEnabled(masterName)
    if MasterPool()['Grand'][masterName]['FADERENABLED'] then
        return true
    else
        return false
    end
end

local function main()
    local automaticResendButtons = GetVar(GlobalVars(), "automaticResendButtons") or false
    local sendColors = GetVar(GlobalVars(), "sendColors") or false
    local sendNames = 1
    local firstIter = true

    Printf("1")
    Printf("automaticResendButtons: " .. (automaticResendButtons and "true" or "false"))
    Printf("sendColors: " .. (sendColors and "true" or "false"))
    Printf("sendNames: " .. (sendNames and "true" or "false"))

    local destPage = 1
    local forceReload = true
    local forceReloadButtons = false

    if GetVar(GlobalVars(), "opdateOSC") ~= nil then
        SetVar(GlobalVars(), "opdateOSC", not GetVar(GlobalVars(), "opdateOSC"))
    else
        SetVar(GlobalVars(), "opdateOSC", true)
    end

    while (GetVar(GlobalVars(), "opdateOSC")) do
        if GetVar(GlobalVars(), "forceReload") == true then
            forceReload = true
            automaticResendButtons = GetVar(GlobalVars(), "automaticResendButtons") or false
            sendColors = GetVar(GlobalVars(), "sendColors") or false
            sendNames = GetVar(GlobalVars(), "sendNames") or false
            SetVar(GlobalVars(), "forceReload", false)
        end

        if automaticResendButtons then
            resendTick = resendTick + 1
        end
        if resendTick >= 15 then
            forceReloadButtons = true
            resendTick = 0
        end

        -- Check Master Enabled Values
        for masterKey, masterValue in pairs(oldMasterEnabledValue) do
            local currValue = getMasterEnabled(masterKey)
            if currValue ~= masterValue then
                Cmd(SendOSC .. '/masterEnabled/' .. masterKey .. ',i,' .. (currValue and 1 or 0))
                oldMasterEnabledValue[masterKey] = currValue
            end
        end


        -- Check Page
        local myPage = CurrentExecPage()
        if myPage.index ~= destPage then
            destPage = myPage.index
            for maKey, maValue in pairs(oldValues) do
                oldValues[maKey] = 000
            end
            for maKey, maValue in pairs(oldButtonValues) do
                oldButtonValues[maKey] = false
            end
            forceReload = true
            Cmd(SendOSC .. '/CurrentPageNo,s,' .. destPage)
        end

        -- Get all Executors
        local executors = DataPool().Pages:Children()[destPage]:Children()

        for listKey, listValue in pairs(executorsToWatch) do
            local faderValue = 0
            local buttonValue = false
            local colorValue = "0,0,0,0"
            local nameValue = ";"
            local isFlash = false

            -- Set Fader & button Values
            for maKey, maValue in pairs(executors) do
                if maValue.No == listValue then
                    local faderOptions = {}
                    faderOptions.value = faderEnd
                    faderOptions.token = "FaderMaster"
                    faderOptions.faderDisabled = false

                    faderValue = maValue:GetFader(faderOptions)
                    isFlash = maValue.KEY == "Flash"

                    local myobject = maValue.Object
                    if myobject ~= nil then
                        buttonValue = myobject:HasActivePlayback() and true or false
                        if sendColors then
                            colorValue = getApereanceColor(myobject)
                        end
                        if sendNames then
                            nameValue = getName(myobject)
                        end
                    end
                end
            end

            -- Send Fader Value
            if (oldValues[listKey] ~= faderValue and not (isFlash and buttonValue and faderValue == 100)) or forceReload then
                hasFaderUpdated = true
                oldValues[listKey] = faderValue
                Cmd(SendOSC .. '/Fader' .. listValue .. ',f,' .. faderValue .. '"')
            end

            -- Send Button Value
            if oldButtonValues[listKey] ~= buttonValue or forceReload or forceReloadButtons then
                oldButtonValues[listKey] = buttonValue
                Cmd(SendOSC .. '/Button' .. listValue .. ',s,' ..
                    (buttonValue and "On" or "Off") .. '"')
            end

            -- Send Name Value
            if sendNames and (oldNameValues[listKey] ~= nameValue or forceReload) then
                oldNameValues[listKey] = nameValue
                Cmd(SendOSC .. '/Name' .. listValue .. ',s,' .. nameValue .. '"')
            end
        end
        forceReload = false
        forceReloadButtons = false

        -- delay
        coroutine.yield(tick)
    end
end

return main
