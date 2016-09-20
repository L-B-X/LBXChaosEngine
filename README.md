# LBXChaosEngine
Reaper FX Plugin Parameter Morphing and Sequencing

*** LBX Chaos Engine.

A reascript (Lua) utility to automate plugin parameters manually and automatically.

IMPORTANT NOTE:  Some parameters can cause huge amounts of gain to be added to the signal (ie EQ's etc) - 
ALWAYS USE A LIMITER AND KEEP MONITORING LEVELS LOW WHEN MESSING ABOUT WITH THE RANDOMIZE BUTTON!  
Ear and monitor damage might occur if things go a bit mad.



------ MPL is my hero ------

This utility script is based on code by mpl: Randomize Track FX Parameter.lua.  From virtually this code alone - 
I was able learn the ins and outs of Lua scripting language - and also build upon it to create this utility.  
I am most grateful to mpl for this, and for allowing me to build upon his code. 

----------------------------



*** TO INSTALL:

Place in folder <REAPER>\Scripts\LBX\ 

The LBX folder must exist to enable all features.



*** TO USE:

1. To get started - you must first choose a preset slot (P1, P2, P3 etc...).  Click on the Setup Px button.  

2. Focus a track FX plugin by opening it - then use the Get Focussed FX button to initialize it within the Chaos Engine utility.

3. Choose the parameters you wish to automate using the parameter list on the right of the utility GUI.

4. Once happy that parameters are chosen - click again on the Setup Px button (now glowing red).

5. Now set up different values for the parameters - either within the plugin, or dragging the parameter bars in the 
Chaos Engine GUI (you can also randomize the parameters using the red randomize button).

6. When the plugin is set up (ie. you like the sound) - click a Capture button to save those settings in a slot (A-H).  
It's required that the morph slider (middle bottom) is over all the way to the right to enable correct capturing of the values 
(especially when using the randomize button).

7. Then repeat steps 5 and 6 - to capture alternative settings and capture into different slots.

Then you can select different slots on each side of the morph slider.  Say the blue (left side) you select slot A, and the 
red side (right side) slot B.  You can then morph between these settings using the morph slider.

The Red side also allows you to automorph between slots.  Right click on a new slot (Red side only) and the Chaos Engine 
will morph between the two presets (like an LFO) depending on the morph settings above the morph slider.

You can then start to play with the sequencer also - to add more variation to the morphing.  These parameter changes can be syncronized to the project tempo and you can get some great rhythmic movement going on.

Please note - each preset can hold 1 or more FX plugins parameters if you wish to control more than one FX plugin using the morph slider.  You caan also start multiple sequencers at once using the Play Grp settings, and play buttons, but you uneed to set these up.

Ok - that's the gist - go play with it.



NOTES:

Morphing some parameters can cause unwanted artifacts - especially things like delay times, reverb sizes, predelays etc.  To avoid these - remove these from the selected morph parameters.

The sequencer and auto morphing is not sample accurate - but should stay in time with the project.  Small variations in timing will occur (especially when many parameters are selected) - as this is entirely CPU dependant.  Faster CPU's are obviously better at keeping everything accurate - but nevertheless - the system should never go horribly out of time - but there might be bigger jumps between parameters if the system cannot keep up.

The faster changes (1/8 note and faster) can sometimes struggle to keep up too - but again - it's there for those systems that can handle it.

Morph shapes available: TRI = linear morphing
			SIN = Simple Sine wave morphing
			SQR = square wave 
			FST = fast attack 
			FST2 = very fast attack
			SLW = slow attack
			SLW2 = very slow attack
			SMO = smooth - like a sine wave but faster (steeper) across the centre.

Rebound means that when the current morph is finished - it jumps back to the start position.  Setting rebound along with a SQR morph shape - will result in no morphing at all.

The system should be able to cope with moving the FX plugins up and down the fx order.

IMPORTANT NOTE:  Some parameters can cause huge amounts of gain to be added to the signal (ie in EQ's etc) - ALWAYS USE A LIMITER AND KEEP MONITORING LEVELS LOW WHEN MESSINGS ABOUT WITH THE RANDOMIZE BUTTON!  Ear and monitor damages can occur if things go a bit mad.


MORE FEATURES:

I plan to add features when I have time.  I already have plans to allow the system to generate offline the fx envelopes at the edit cursor - so you can insert the sequences exactly as they're meant to sound.  Also - I have disabled the Rec Automation button as this no longer works currently as designed due to vast changes to the project made since I added that code.

I also plan to further optimize where I can.  Possibly including a stripped down 'LIVE' version - where you cannot change any of the settings - but can trigger and run the morphing and sequences.  This may allow for more accurate reproduction of the parameter changes.
