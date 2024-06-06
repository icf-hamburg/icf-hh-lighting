local function updateMatricksIndex(matricks_ref)
    -- 32767 is there max value that MAtricks Shuffle will accept
    local maxval = 32767
    local update = math.random(1, maxval)
    matricks_ref.XSHUFFLE = update
end


return function()
    -- MAtricks address (ShowData.DataPool.Default.MAtricks[idx])
    local matricks_pool = FromAddr("13.13.1.10")
    local phaser_pool = FromAddr("13.13.1.4.21")

    updateMatricksIndex(matricks_pool[33])
    updateMatricksIndex(phaser_pool[123])
end
