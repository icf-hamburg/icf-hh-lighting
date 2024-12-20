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

    local osc_patch = 3;

    -- local bpm = 69.5;
    local bpm = argument;

    if bpm == nil then
        displayError("BPM Argument fehlt.")
        return
    end

    local speedmaster = "3.2";
    local reset_speedscale = "Set Master " .. speedmaster .. " \"SpeedScale\" \"One\""
    local gma_set_bpm = "Master " .. speedmaster .. " BPM " .. bpm


    local resolume_bpm = (bpm - 20) / 480;

    -- bpm range: 20/500 - val: 0-1
    -- maths: (bpm-20)/480
    -- Example: SendOSC 3 "/composition/tempocontroller/tempo,f,0.103125"  [69.5 bpm]
    local osc_path = "/composition/tempocontroller/tempo"
    local maSuffix = ",f," .. resolume_bpm
    local rslm_set_bpm = "SendOSC " .. osc_patch .. " \"" .. osc_path .. maSuffix .. "\""

    Cmd(reset_speedscale)
    Cmd(gma_set_bpm)
    Cmd(rslm_set_bpm)

end

return Main
