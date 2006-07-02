################
#
# ADF
#
################

animateAdfDisplay = func {
	adfFreq = getprop("/instrumentation/adf/frequencies/selected-khz");
	adfE3 = int(adfFreq/1000);
	adfE2 = int((adfFreq-(adfE3*1000))/100);
	adfE0 = adfFreq-(adfE3*1000)-(adfE2*100);
	setprop("/sim/model/ch53e/instrument-pos/ADFFreqDisp1", adfE3);
	setprop("/sim/model/ch53e/instrument-pos/ADFFreqDisp2", adfE2);
	setprop("/sim/model/ch53e/instrument-pos/ADFFreqDisp3", adfE0);
}
setlistener("/instrumentation/adf/frequencies/selected-khz", animateAdfDisplay);

watchAdfSelector = func {
	if (getprop("/instrumentation/adf/control-switch") == 0) {
		setprop("/instrumentation/adf/serviceable", 0);
	} else {
		setprop("/instrumentation/adf/serviceable", 1);
	}
}
setlistener("/instrumentation/adf/control-switch", watchAdfSelector);

setlistener("/instrumentation/adf/volume-norm", func{setprop("/instrumentation/adf/ident-audible", 1)} );

initAdf = func {
	setprop("/instrumentation/adf/control-switch", getprop("/instrumentation/adf/serviceable"));
	animateAdfDisplay();
	watchAdfSelector();
}
settimer(initAdf, 0);

################
#
# Comm
#
################

adjustCommDisplay = func(radioNumber) {
	if (getprop('/instrumentation/comm['~radioNumber~']/serviceable')) {
		freqGhz = 1000 * getprop('/instrumentation/comm['~radioNumber~']/frequencies/selected-mhz');
		# This is done in a cleaner way in the TACAN code
		digit1 = int(freqGhz/100000);
		freqGhz = freqGhz-digit1*100000;
		digit2 = int(freqGhz/10000);
		freqGhz = freqGhz-digit2*10000;
		digit3 = int(freqGhz/1000);
		freqGhz = freqGhz-digit3*1000;
		digit4 = int(freqGhz/100);
		freqGhz = freqGhz-digit4*100;
		digit5 = int(freqGhz/10);
		freqGhz = int(freqGhz-digit5*10);
		setprop('/sim/model/ch53e/instrument-pos/VHF'~radioNumber~'Display1-texture', 'LCD-'~digit1~'.rgb');
		setprop('/sim/model/ch53e/instrument-pos/VHF'~radioNumber~'Display2-texture', 'LCD-'~digit2~'.rgb');
		setprop('/sim/model/ch53e/instrument-pos/VHF'~radioNumber~'Display3-texture', 'LCD-'~digit3~'.rgb');
		setprop('/sim/model/ch53e/instrument-pos/VHF'~radioNumber~'Display4-texture', 'LCD-Period.rgb');
		setprop('/sim/model/ch53e/instrument-pos/VHF'~radioNumber~'Display5-texture', 'LCD-'~digit4~'.rgb');
		setprop('/sim/model/ch53e/instrument-pos/VHF'~radioNumber~'Display6-texture', 'LCD-'~digit5~'.rgb');
		setprop('/sim/model/ch53e/instrument-pos/VHF'~radioNumber~'Display7-texture', 'LCD-'~freqGhz~'.rgb');
	} else {
		for (i=1; i<=7; i+=1) {
			setprop('/sim/model/ch53e/instrument-pos/VHF'~radioNumber~'Display'~i~'-texture', 'transparent.rgb');
		}
	}
}

settimer(func{adjustCommDisplay(0)}, 0);
settimer(func{adjustCommDisplay(1)}, 0);
setlistener('/instrumentation/comm[0]/serviceable', func{adjustCommDisplay(0)});
setlistener('/instrumentation/comm[1]/serviceable', func{adjustCommDisplay(1)});
setlistener('/instrumentation/comm[0]/frequencies/selected-mhz', func{adjustCommDisplay(0)});
setlistener('/instrumentation/comm[1]/frequencies/selected-mhz', func{adjustCommDisplay(1)});

################
#
# Landing gear animation support
#
################

# Emergency extension

emergGearActivate = func {
	setprop('/sim/model/ch53e/control-input/emergency-gear-release', 0);
	if (getprop('/sim/model/ch53e/control-pos/LandingGearEmergExt-rot-norm') == 0) {
		interpolate('/sim/model/ch53e/control-pos/LandingGearEmergExt-rot-norm', 1, 0.25);
	} elsif (getprop('/sim/model/ch53e/control-pos/LandingGearEmergExt-rot-norm') == 1) {
		interpolate('/sim/model/ch53e/control-pos/LandingGearEmergExt-pos-norm', 1, 0.25);
		# FIXME the gear should drop very quickly, not take the 6 sec cycle time
		settimer(func {controls.gearDown(1)}, 0.5);
	}
}
setlistener('/sim/model/ch53e/control-input/emergency-gear-release', emergGearActivate);

# Indicator tabs and light

turnGearLight = func(status) {
	base = "/sim/model/ch53e/instrument-pos/gearHandleGlow/";
	if (status == 'red') {
		setprop(base~"emission/red", 0.65);
		setprop(base~"emission/green", 0);
		setprop(base~"ambient/red", 0.8);
		setprop(base~"ambient/green", 0.2);
		setprop(base~"ambient/blue", 0.2);
	} elsif (status == 'green') {
		setprop(base~"emission/red", 0);
		setprop(base~"emission/green", 0.65);
		setprop(base~"ambient/red", 0.2);
		setprop(base~"ambient/green", 0.8);
		setprop(base~"ambient/blue", 0.2);
	} elsif (status == 'off') {
		setprop(base~"emission/red", 0);
		setprop(base~"emission/green", 0);
		setprop(base~"ambient/red", 0.8);
		setprop(base~"ambient/green", 0.8);
		setprop(base~"ambient/blue", 0.8);
	}
}

origGearDown = controls.gearDown;
lastGearPosition = '';
controls.gearDown = func(position) {
	# Someone moved the gear handle. Indicate barberpole until further notice, unless the emergency release has been pulled.
	# Mode the control handle regardless
	interpolate("/sim/model/ch53e/control-pos/LandingGearHandle-pos-norm", position, 0.2);
	if ((position != 0) and (position != lastGearPosition) and (getprop('/sim/model/ch53e/control-pos/LandingGearEmergExt-pos-norm') != 1)) {
		lastGearPosition = position;
		# Turn light red right away
		turnGearLight('red');
		# Display all barber poles right away
		interpolate("/sim/model/ch53e/instrument-pos/GearIndicator0-pos", 0, 0.1);
		interpolate("/sim/model/ch53e/instrument-pos/GearIndicator1-pos", 0, 0.1);
		interpolate("/sim/model/ch53e/instrument-pos/GearIndicator2-pos", 0, 0.1);
		# Make sure these times match those in the YASim file FIXME
		if (position == 1) {
			settimer(func {interpolate("/sim/model/ch53e/instrument-pos/GearIndicator0-pos", 1, 0.1)}, 6.0);
			settimer(func {interpolate("/sim/model/ch53e/instrument-pos/GearIndicator1-pos", 1, 0.1)}, 6.0);
			settimer(func {interpolate("/sim/model/ch53e/instrument-pos/GearIndicator2-pos", 1, 0.1)}, 6.0);
			settimer(func {turnGearLight('green')}, 6.0);
		} elsif (position == -1) {
			settimer(func {interpolate("/sim/model/ch53e/instrument-pos/GearIndicator0-pos", -1, 0.1)}, 6.0);
			settimer(func {interpolate("/sim/model/ch53e/instrument-pos/GearIndicator1-pos", -1, 0.1)}, 6.0);
			settimer(func {interpolate("/sim/model/ch53e/instrument-pos/GearIndicator2-pos", -1, 0.1)}, 6.0);
			settimer(func {turnGearLight('off')}, 6.0);
		}
		origGearDown(position);
	}
}

gearInit = func {
	position = getprop('/controls/gear/gear-down');
	setprop("/sim/model/ch53e/control-pos/LandingGearHandle-pos-norm", position);
	setprop("/sim/model/ch53e/instrument-pos/GearIndicator0-pos", position);
	setprop("/sim/model/ch53e/instrument-pos/GearIndicator1-pos", position);
	setprop("/sim/model/ch53e/instrument-pos/GearIndicator2-pos", position);
	if (position == 1) {
		turnGearLight('green');
	} else {
		turnGearLight('off');
	}
}
settimer(gearInit, 0);

################
#
# Stick Position
#
################

pollStickPos = func {
	# TODO test button?
	materials = '/sim/model/ch53e/materials/';
	quant_pitch = int(((getprop('/controls/flight/elevator'))+1)/0.0606060606);
	quant_roll = int(((getprop('/controls/flight/aileron'))+1)/0.0606060606);
	# setprop('/sim/model/ch53e/quant-roll', quant_roll);
	# setprop('/sim/model/ch53e/quant-pitch', quant_pitch);
	if (getprop('/controls/lighting/nvg-mode') == 1) {
		led_color = 'green';
		led_intensity = (getprop('/controls/lighting/instrument-norm')*0.5);
	} else {
		led_color = 'red';
		led_intensity = getprop('/controls/lighting/instrument-norm');
	}
	# Turn it all off
	for (i=1;i<=8;i+=1) {
		foreach (zone; ['HSPLeft.00', 'HSPRight.00', 'VSPFore.00', 'VSPAft.00']) {
			foreach (color; ['red','green','blue']) {
				setprop(materials~zone~i~'/emission/'~color, '0'); 
			}
		}
	}
	setprop(materials~'CenterStickPos'~'/emission/red', 0); 
	setprop(materials~'CenterStickPos'~'/emission/green', 0); 
	if (getprop('/instrumentation/stick-position-indicator/serviceable') == 1) {
		# Centering
		if ((quant_roll == 16) or (quant_pitch == 16)) {
			setprop(materials~'CenterStickPos'~'/emission/'~led_color, led_intensity); 
		}
		# Pitch
		if (quant_roll == 0) {
			setprop(materials~'HSPLeft.008'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_roll == 1) {
			setprop(materials~'HSPLeft.008'~'/emission/'~led_color, led_intensity); 
			setprop(materials~'HSPLeft.007'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_roll == 2) {
			setprop(materials~'HSPLeft.007'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_roll == 3) {
			setprop(materials~'HSPLeft.007'~'/emission/'~led_color, led_intensity); 
			setprop(materials~'HSPLeft.006'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_roll == 4) {
			setprop(materials~'HSPLeft.006'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_roll == 5) {
			setprop(materials~'HSPLeft.006'~'/emission/'~led_color, led_intensity); 
			setprop(materials~'HSPLeft.005'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_roll == 6) {
			setprop(materials~'HSPLeft.005'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_roll == 7) {
			setprop(materials~'HSPLeft.005'~'/emission/'~led_color, led_intensity); 
			setprop(materials~'HSPLeft.004'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_roll == 8) {
			setprop(materials~'HSPLeft.004'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_roll == 9) {
			setprop(materials~'HSPLeft.004'~'/emission/'~led_color, led_intensity); 
			setprop(materials~'HSPLeft.003'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_roll == 10) {
			setprop(materials~'HSPLeft.003'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_roll == 11) {
			setprop(materials~'HSPLeft.003'~'/emission/'~led_color, led_intensity); 
			setprop(materials~'HSPLeft.002'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_roll == 12) {
			setprop(materials~'HSPLeft.002'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_roll == 13) {
			setprop(materials~'HSPLeft.002'~'/emission/'~led_color, led_intensity); 
			setprop(materials~'HSPLeft.001'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_roll == 14) {
			setprop(materials~'HSPLeft.001'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_roll == 15) {
			setprop(materials~'HSPLeft.001'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_roll == 17) {
			setprop(materials~'HSPRight.001'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_roll == 18) {
			setprop(materials~'HSPRight.001'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_roll == 19) {
			setprop(materials~'HSPRight.001'~'/emission/'~led_color, led_intensity); 
			setprop(materials~'HSPRight.002'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_roll == 20) {
			setprop(materials~'HSPRight.002'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_roll == 21) {
			setprop(materials~'HSPRight.002'~'/emission/'~led_color, led_intensity); 
			setprop(materials~'HSPRight.003'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_roll == 22) {
			setprop(materials~'HSPRight.003'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_roll == 23) {
			setprop(materials~'HSPRight.003'~'/emission/'~led_color, led_intensity); 
			setprop(materials~'HSPRight.004'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_roll == 24) {
			setprop(materials~'HSPRight.004'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_roll == 25) {
			setprop(materials~'HSPRight.004'~'/emission/'~led_color, led_intensity); 
			setprop(materials~'HSPRight.005'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_roll == 26) {
			setprop(materials~'HSPRight.005'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_roll == 27) {
			setprop(materials~'HSPRight.005'~'/emission/'~led_color, led_intensity); 
			setprop(materials~'HSPRight.006'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_roll == 28) {
			setprop(materials~'HSPRight.006'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_roll == 29) {
			setprop(materials~'HSPRight.006'~'/emission/'~led_color, led_intensity); 
			setprop(materials~'HSPRight.007'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_roll == 30) {
			setprop(materials~'HSPRight.007'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_roll == 31) {
			setprop(materials~'HSPRight.007'~'/emission/'~led_color, led_intensity); 
			setprop(materials~'HSPRight.008'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_roll >= 32) {
			setprop(materials~'HSPRight.008'~'/emission/'~led_color, led_intensity); 
		}
		# Roll
		if (quant_pitch == 0) {
			setprop(materials~'VSPAft.008'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_pitch == 1) {
			setprop(materials~'VSPAft.008'~'/emission/'~led_color, led_intensity); 
			setprop(materials~'VSPAft.007'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_pitch == 2) {
			setprop(materials~'VSPAft.007'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_pitch == 3) {
			setprop(materials~'VSPAft.007'~'/emission/'~led_color, led_intensity); 
			setprop(materials~'VSPAft.006'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_pitch == 4) {
			setprop(materials~'VSPAft.006'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_pitch == 5) {
			setprop(materials~'VSPAft.006'~'/emission/'~led_color, led_intensity); 
			setprop(materials~'VSPAft.005'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_pitch == 6) {
			setprop(materials~'VSPAft.005'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_pitch == 7) {
			setprop(materials~'VSPAft.005'~'/emission/'~led_color, led_intensity); 
			setprop(materials~'VSPAft.004'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_pitch == 8) {
			setprop(materials~'VSPAft.004'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_pitch == 9) {
			setprop(materials~'VSPAft.004'~'/emission/'~led_color, led_intensity); 
			setprop(materials~'VSPAft.003'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_pitch == 10) {
			setprop(materials~'VSPAft.003'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_pitch == 11) {
			setprop(materials~'VSPAft.003'~'/emission/'~led_color, led_intensity); 
			setprop(materials~'VSPAft.002'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_pitch == 12) {
			setprop(materials~'VSPAft.002'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_pitch == 13) {
			setprop(materials~'VSPAft.002'~'/emission/'~led_color, led_intensity); 
			setprop(materials~'VSPAft.001'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_pitch == 14) {
			setprop(materials~'VSPAft.001'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_pitch == 15) {
			setprop(materials~'VSPAft.001'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_pitch == 17) {
			setprop(materials~'VSPFore.001'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_pitch == 18) {
			setprop(materials~'VSPFore.001'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_pitch == 19) {
			setprop(materials~'VSPFore.001'~'/emission/'~led_color, led_intensity); 
			setprop(materials~'VSPFore.002'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_pitch == 20) {
			setprop(materials~'VSPFore.002'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_pitch == 21) {
			setprop(materials~'VSPFore.002'~'/emission/'~led_color, led_intensity); 
			setprop(materials~'VSPFore.003'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_pitch == 22) {
			setprop(materials~'VSPFore.003'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_pitch == 23) {
			setprop(materials~'VSPFore.003'~'/emission/'~led_color, led_intensity); 
			setprop(materials~'VSPFore.004'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_pitch == 24) {
			setprop(materials~'VSPFore.004'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_pitch == 25) {
			setprop(materials~'VSPFore.004'~'/emission/'~led_color, led_intensity); 
			setprop(materials~'VSPFore.005'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_pitch == 26) {
			setprop(materials~'VSPFore.005'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_pitch == 27) {
			setprop(materials~'VSPFore.005'~'/emission/'~led_color, led_intensity); 
			setprop(materials~'VSPFore.006'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_pitch == 28) {
			setprop(materials~'VSPFore.006'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_pitch == 29) {
			setprop(materials~'VSPFore.006'~'/emission/'~led_color, led_intensity); 
			setprop(materials~'VSPFore.007'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_pitch == 30) {
			setprop(materials~'VSPFore.007'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_pitch == 31) {
			setprop(materials~'VSPFore.007'~'/emission/'~led_color, led_intensity); 
			setprop(materials~'VSPFore.008'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_pitch >= 32) {
			setprop(materials~'VSPFore.008'~'/emission/'~led_color, led_intensity); 
		}
	}
	settimer(pollStickPos, 0);
}
settimer(pollStickPos, 0);

################
#
# TACAN
#
################
tacanChan1 = '';
tacanChan2 = '';
tacanChan3 = '';
tacanInit = func {
	tacanChan1 = props.globals.getNode('/instrumentation/tacan/frequencies/selected-channel[1]', 1);
	tacanChan2 = props.globals.getNode('/instrumentation/tacan/frequencies/selected-channel[2]', 1);
	tacanChan3 = props.globals.getNode('/instrumentation/tacan/frequencies/selected-channel[3]', 1);
}
settimer(tacanInit, 0);
adjustTacanChannel = func(increment) {
	tacanChannel = tacanChan1.getValue() * 100 + tacanChan2.getValue() * 10 + tacanChan3.getValue();
	# buisiness part
	tacanChannel += increment;
	if (tacanChannel > 126) {tacanChannel = 126;}
	if (tacanChannel < 0) {tacanChannel = 0;}
	# convert back
	# TODO make these interpolate, crossing boundary condition correctly
	tacanChannel = sprintf("%03.3d", tacanChannel);
	tacanChan1.setValue(chr(tacanChannel[0]));
	tacanChan2.setValue(chr(tacanChannel[1]));
	tacanChan3.setValue(chr(tacanChannel[2]));
}
adjustTacanMode = func {
	if (getprop('/instrumentation/tacan/frequencies/selected-channel[4]') == 'X') {
		interpolate('/instrumentation/tacan/mode', 0, 0.1);
	} elsif (getprop('/instrumentation/tacan/frequencies/selected-channel[4]') == 'Y') {
		interpolate('/instrumentation/tacan/mode', 1, 0.1);
	}
}
setlistener('/instrumentation/tacan/frequencies/selected-channel[4]', adjustTacanMode);
settimer(adjustTacanMode, 0);

################
#
# General Stuff
#
################

debugInit = func {
	if (getprop('/sim/model/ch53e/debug-model') == 1) {
		# material.showDialog('/sim/model/ch53e/instrument-pos/gearHandleGlow');
	}
}
settimer(debugInit, 0);

print("ch53e.nas initialized");

