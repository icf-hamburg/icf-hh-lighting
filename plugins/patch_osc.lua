local LOCALHOST = "127.0.0.1"

local function patchDict(name, addr, port, send)
    local SUFFIX = (send and "SEND") or "RECV"
    SUFFIX = "[" .. SUFFIX .. "]"

    return {
        name = name .. " " .. SUFFIX,
        port = port,
        addr = addr,
        send = send,
    }
end

local function patchOscObject(handle, dict)
    -- map the MA OSCData object to our dict definition, e.g.
    -- OSCData[1].DESTINATIONIP = "127.0.0.1"

    handle.NAME = dict.name
    handle.PORT = dict.port
    handle.DESTINATIONIP = dict.addr

    handle.SEND = dict.send
    handle.SENDCOMMAND = dict.send
    handle.ECHOOUTPUT = dict.send

    handle.RECEIVE = not dict.send
    handle.RECEIVECOMMAND = not dict.send
    handle.ECHOINPUT = not dict.send
end


local function singlePatchCedric()
    local PRIMARY_IF = "192.168.178.10"

    return {
        patchDict("TouchOSC Einleuchten", PRIMARY_IF, "7011", true),
        patchDict("TouchOSC Einleuchten", PRIMARY_IF, "7012", false),
        patchDict("Resolume", LOCALHOST, "7021", true),
        patchDict("Companion", LOCALHOST, "7032", false),
    }
end


local function singlePatchEmporio()
    local PRIMARY_IF = "192.168.1.10"

    return {
        patchDict("TouchOSC Einleuchten", PRIMARY_IF, "7011", true),
        patchDict("TouchOSC Einleuchten", PRIMARY_IF, "7012", false),
        patchDict("Resolume", LOCALHOST, "7021", true),
        patchDict("Companion", LOCALHOST, "7032", false),
    }
end


local function displayPrompt()
    local messageBoxOptions = {
        title = "Patch Plan auswählen",
        message = "Achtung: Aktuelle OSC In-/Output Daten werden komplett überschrieben",
        commands = {
            { value = nil, name = "Abbrechen" },
            { value = 1,   name = "Emporio" },
            { value = 2,   name = "Cédric" },
        }
    }
    return MessageBox(messageBoxOptions).result
end



return function()
    local prompt = displayPrompt()
    local patchPlan = nil

    if prompt == 1 then
        patchPlan = singlePatchEmporio()
    elseif prompt == 2 then
        patchPlan = singlePatchCedric()
    end


    local OSCBase = Root().ShowData.OSCBase
    -- OSCBase:Dump()
    -- local OSCData = OSCBase:Children()
    -- OSCData[1]:Dump()


    if patchPlan ~= nil then
        -- remove all entries, a first entry is automatically added
        while OSCBase:Count() > 1 do
            OSCBase:Remove(1)
        end

        for k, v in pairs(patchPlan) do
            local new_obj = OSCBase:Append()
            patchOscObject(new_obj, v)
        end
        OSCBase:Remove(1) -- remove the first automatically added entry
    end
end
