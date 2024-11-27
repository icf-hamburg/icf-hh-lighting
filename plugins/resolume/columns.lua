local function enterIndex()
    local messageBoxOptions = {
        title = "Resolume Informationen eingeben",
        message = "",
        commands = {
            { value = 0, name = "Cancel" },
            { value = 1, name = "OK" }
        },
        inputs = {
            { name = "Column Number", vkPlugin = "TextInputNumOnlyRange" },
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
    -- "/composition/columns/1/connect"
    local oscPatch = "3"
    local col = 1 -- placeholder



    if argument == nil then
        local result = enterIndex()
        if result.result == 0 then
            -- User pressed cancel
            return
        end
        col = result.inputs["Column Number"]

        if col == "" then
            displayError("Es muss eine Column angeben werden.")
            return
        end

    else
        col = argument
    end

    local rslm = "/composition/columns/" .. col .. "/connect"


    local maSuffix = ",i,1"
    local cmd = "SendOSC " .. oscPatch .. " \"" .. rslm .. maSuffix .. "\""
    Cmd(cmd)
end

return Main
