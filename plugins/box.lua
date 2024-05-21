-- https://help.malighting.com/grandMA3/2.0/HTML/lua_objectfree_messagebox.html

local function Main()
    local messageBoxOptions = {
        title = "Hazer Erinnerung",
        message = "Bitte den Hazer nicht vergessen!",

        -- colors: https://help.malighting.com/grandMA3/2.0/HTML/ws_colors_color_theme.html
        -- Settings > Desk Light & Color Theme > Edit > *Use name and not GlobalDefRef*
        titleTextColor = "Global.Text",
        messageTextColor = "Global.Text",
        backColor = "Global.AlertText",
    }
    MessageBox(messageBoxOptions)
end

return Main
