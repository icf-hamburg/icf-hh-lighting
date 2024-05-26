local function main(display, args)
	Printf("Called from "..display:ToAddr())
	if args then
		Printf("Plugin called with argument "..args)
	end
end
return main
