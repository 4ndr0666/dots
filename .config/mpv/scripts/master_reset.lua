-- master_reset.lua
-- Place in ~/.config/mpv/scripts/
local function master_clean()
    -- Reset EQ
    mp.set_property("contrast", 0)
    mp.set_property("brightness", 0)
    mp.set_property("gamma", 0)
    mp.set_property("saturation", 0)

    -- Reset Geometry (Mirroring your current '0' binding)
    mp.set_property("video-zoom", 0)
    mp.set_property("video-pan-x", 0)
    mp.set_property("video-pan-y", 0)
    mp.set_property("video-rotate", 0)

    -- Reset Playback
    mp.set_property("speed", 1.0)

    mp.osd_message("System Purge: All Settings Defaulted", 3)
end

mp.add_key_binding("Alt+0", "master_clean", master_clean)
