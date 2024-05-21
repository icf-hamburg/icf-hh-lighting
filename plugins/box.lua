-- https://help.malighting.com/grandMA3/2.0/HTML/lua_objectfree_messagebox.html

local function Main()
    local messageBoxOptions = {
        title = "Hello World!",
        message = "",
        commands = {
            { value = false, name = "Cancel" },
            { value = true, name = "OK" }
        },
        inputs = {
            { name = "Hello", vkPlugin = "TextInput" },
            { name = "World", vkPlugin = "TextInput" },
        }
    }
    local result = MessageBox(messageBoxOptions)
    Drt.table2String(result)
    Printf("------------------------------")
    Drt.table2String(result.inputs)
    Printf("------------------------------")
    Printf(result.inputs["Hello"])
    -- Printf(result.inputs[1])  -- does not work
end

return Main
