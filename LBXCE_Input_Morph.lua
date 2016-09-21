-----------------------------------------
-- SCRIPT 2 --bind it to MIDI or OSC control
-----------------------------------------

is_new_value,filename,sectionID,cmdID,mode,resolution,val = reaper.get_action_context()
reaper.SetExtState( 'LBX_Morph', 'MorphValue', val/resolution, false)