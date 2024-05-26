local function enterIndex()
    local messageBoxOptions = {
        title = "Resolume Informationen eingeben",
        message = "",
        commands = {
            { value = 0, name = "Cancel" },
            { value = 1, name = "OK" }
        },
        inputs = {
            { name = "Clip Nummer", vkPlugin = "TextInputNumOnlyRange" },
            { name = "Ebene",       vkPlugin = "TextInputNumOnlyRange" },
        }
    }
    return MessageBox(messageBoxOptions)
end


local function displayError(msg)
    local messageBoxOptions = {
        title = "Fehler!",
        message = msg,
        titleTextColor = "Global.Text",
        messageTextColor = "Global.Text",
        backColor = "Global.AlertText",
    }
    MessageBox(messageBoxOptions)
end



local function Main(display_handle, argument)
    -- Example Path:
    -- "/composition/layers/2/clips/2/connect"
    local oscPatch = "2"
    local layer = 1
    local clip = 1 -- placeholder



    if argument == nil then
        local result = enterIndex()
        if result.result == 0 then
            -- User pressed cancel
            return
        end
        layer = result.inputs["Ebene"]
        clip = result.inputs["Clip Nummer"]

        if layer == "" then
            displayError("Es muss eine Ebene angeben werden.")
            return
        end

        if clip == "" then
            displayError("Es muss ein Clip angeben werden.")
            return
        end

    else
        clip = argument
    end

    local rslm = "/composition/layers/" .. layer .. "/clips/" .. clip .. "/connect"


    local maSuffix = ",i,1"
    local cmd = "SendOSC " .. oscPatch .. " \"" .. rslm .. maSuffix .. "\""
    Cmd(cmd)
end

return Main
