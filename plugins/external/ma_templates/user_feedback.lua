local function main()
	local title = "This is the title"
	local message = "The message to be displayed."
	local input = TextInput(title,message)
	Printf("You entered this message: %s",tostring(input))

	if Confirm("Confirm me", "Tap OK") then
		Printf("OK")
	else
		Printf("Cancel.")
	end

	local descTable = {
		title = "Demo",
		caller = GetFocusDisplay(),
		items = {"Select","Some","Value","Please"},
		selectedValue = "Some",
		add_args = {FilterSupport="Yes"},
	}
	local a,b = PopupInput(descTable)
	Printf("a = %s",tostring(a))
	Printf("b = %s",tostring(b))

end

return main
