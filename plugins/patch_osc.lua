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


local function createPatch(TOSC, RESOLUME, COMPANION, MULTI)
    return {
        patchDict("TouchOSC Einleuchten", TOSC, "7011", true),
        patchDict("TouchOSC Einleuchten", TOSC, "7012", false),
        patchDict("Resolume", RESOLUME, "7021", true),
        patchDict("Companion", COMPANION, "7031", true),
        patchDict("Companion", COMPANION, "7032", false),
        patchDict("Multi Timecode Expert", MULTI, "7041", true),
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


    TOSC = LOCALHOST
    RESOLUME = LOCALHOST
    COMPANION = LOCALHOST
    MULTI = LOCALHOST

    if prompt == 1 then  -- Emporio
        MAIN_IF = "10.10.1.10"
        TOSC = "10.10.1.11"
        RESOLUME = LOCALHOST
        COMPANION = LOCALHOST
        MULTI = "10.10.1.12"
        patchPlan = createPatch(TOSC, RESOLUME, COMPANION, MULTI)
    elseif prompt == 2 then  -- At Home
        patchPlan = createPatch(TOSC, RESOLUME, COMPANION, MULTI)
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
