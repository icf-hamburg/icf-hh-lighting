local QUICKEYS = Root().ShowData.DataPools.Default.Quickeys

local function CreateQuickey(number, code)
    QUICKEYS:Create(number)
    QUICKEYS[number]:Set("NAME", code)
    QUICKEYS[number]:Set("CODE", code)
    QUICKEYS[number]:Set("LOCK", true)
end


local function main()
    CreateQuickey(40, "ESC")
    CreateQuickey(41, "GO")
    CreateQuickey(42, "GOBACK")
end


return main
