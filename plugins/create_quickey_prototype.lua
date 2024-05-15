local function CreateQuickey(number, code)
    local obj = Root().ShowData.DataPools.Default.Quickeys
    obj:Create(number)
    obj[number]:Set("Name", code)
    obj[number]:Set("CODE", code)
end


local function main()
    CreateQuickey(40, "ESC")
    CreateQuickey(41, "GO")
    CreateQuickey(42, "GOBACK")
end


return main
