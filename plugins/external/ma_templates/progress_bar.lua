local function main()
	-- create the progress bar:
	local progHandle = StartProgress("myProgress")
	-- set start index and end index of the progress bar:
	local startIdx, endIdx = 1, 3

	-- define the range of the progress bar:
	SetProgressRange(progHandle, startIdx, endIdx)
	for i = startIdx, endIdx do
		-- set the progress state of the progress bar:
		SetProgress(progHandle, i)
		coroutine.yield(1)
	end

	-- remove the progress bar:
	StopProgress(progHandle)
end

return main
