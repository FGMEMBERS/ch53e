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
# Engine
# A sophisticated YASim style turbine simulation.
# Booyah.
#
################

rpm0 = '';
rpm1 = '';
rpm2 = '';
rpmR = '';
engineSim =  func {
	var rpm = (rpmR.getValue() / 0.185);
	rpm0.setDoubleValue(rpm);
	rpm1.setDoubleValue(rpm);
	rpm2.setDoubleValue(rpm);
	settimer(engineSim, 0.1);
}
engineInit = func {
	rpm0 = props.globals.getNode('engines/engine[0]/rpm', 1);
	rpm1 = props.globals.getNode('engines/engine[1]/rpm', 1);
	rpm2 = props.globals.getNode('engines/engine[2]/rpm', 1);
	rpmR = props.globals.getNode('rotors/main/rpm', 1);
	rpmR.setDoubleValue(0);
	engineSim();
}
settimer(engineInit, 0 );

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
lastGearPosition = nil;
controls.gearDown = func(position) {
	# Someone moved the gear handle. Indicate barberpole until further notice, unless the emergency release has been pulled.
	# Mode the control handle regardless
	if ((position != 0) and (position != lastGearPosition) and (getprop('/sim/model/ch53e/control-pos/LandingGearEmergExt-pos-norm') != 1)) {
		interpolate("/sim/model/ch53e/control-pos/LandingGearHandle-pos-norm", position, 0.2);
		lastGearPosition = position;
		# Turn light red right away
		turnGearLight('red');
		# Display all barber poles right away
		interpolate("/sim/model/ch53e/instrument-pos/GearIndicator0-pos", 0, 0.1);
		interpolate("/sim/model/ch53e/instrument-pos/GearIndicator1-pos", 0, 0.1);
		interpolate("/sim/model/ch53e/instrument-pos/GearIndicator2-pos", 0, 0.1);
		# Make sure these times match those in the YASim file TODO
		# Also, these interpolations don't always work right FIXME
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
# NVG Lighting Switch
#
# This model has a night vision mode switch which selects between two colors for the
# panel and instrument lights. Instead of just setting the desired colors for various
# lights in the -set file as would be normal with interior-lights.nas, this system
# watches the apropriate switch and then sets the instument-lights.nas input props
# based on two custom defined color schemes.
#
################

initNvgMode = func {
	adjustNvgMode = func {
		if (nvgMode.getValue()) {
			domeLightRed.setDoubleValue(domeLightRedNvg.getValue());
			domeLightGreen.setDoubleValue(domeLightGreenNvg.getValue());
			domeLightBlue.setDoubleValue(domeLightBlueNvg.getValue());
			panelLightRed.setDoubleValue(panelLightRedNvg.getValue());
			panelLightGreen.setDoubleValue(panelLightGreenNvg.getValue());
			panelLightBlue.setDoubleValue(panelLightBlueNvg.getValue());
			instrumentsLightRed.setDoubleValue(instrumentsLightRedNvg.getValue());
			instrumentsLightGreen.setDoubleValue(instrumentsLightGreenNvg.getValue());
			instrumentsLightBlue.setDoubleValue(instrumentsLightBlueNvg.getValue());
		} else {
			domeLightRed.setDoubleValue(domeLightRedUnaided.getValue());
			domeLightGreen.setDoubleValue(domeLightGreenUnaided.getValue());
			domeLightBlue.setDoubleValue(domeLightBlueUnaided.getValue());
			panelLightRed.setDoubleValue(panelLightRedUnaided.getValue());
			panelLightGreen.setDoubleValue(panelLightGreenUnaided.getValue());
			panelLightBlue.setDoubleValue(panelLightBlueUnaided.getValue());
			instrumentsLightRed.setDoubleValue(instrumentsLightRedUnaided.getValue());
			instrumentsLightGreen.setDoubleValue(instrumentsLightGreenUnaided.getValue());
			instrumentsLightBlue.setDoubleValue(instrumentsLightBlueUnaided.getValue());
		}
	}

	domeLightRed                 = props.globals.getNode('controls/lighting/dome/color/red', 1);
	domeLightRedNvg              = props.globals.getNode('sim/model/ch53e/materials/dome-light-color/nvg/red', 1);
	domeLightRedUnaided          = props.globals.getNode('sim/model/ch53e/materials/dome-light-color/unaided/red', 1);
	domeLightGreen               = props.globals.getNode('controls/lighting/dome/color/green', 1);
	domeLightGreenNvg            = props.globals.getNode('sim/model/ch53e/materials/dome-light-color/nvg/green', 1);
	domeLightGreenUnaided        = props.globals.getNode('sim/model/ch53e/materials/dome-light-color/unaided/green', 1);
	domeLightBlue                = props.globals.getNode('controls/lighting/dome/color/blue', 1);
	domeLightBlueNvg             = props.globals.getNode('sim/model/ch53e/materials/dome-light-color/nvg/blue', 1);
	domeLightBlueUnaided         = props.globals.getNode('sim/model/ch53e/materials/dome-light-color/unaided/blue', 1);

	panelLightRed                = props.globals.getNode('controls/lighting/panel/color/red', 1);
	panelLightRedNvg             = props.globals.getNode('sim/model/ch53e/materials/panel-light-color/nvg/red', 1);
	panelLightRedUnaided         = props.globals.getNode('sim/model/ch53e/materials/panel-light-color/unaided/red', 1);
	panelLightGreen              = props.globals.getNode('controls/lighting/panel/color/green', 1);
	panelLightGreenNvg           = props.globals.getNode('sim/model/ch53e/materials/panel-light-color/nvg/green', 1);
	panelLightGreenUnaided       = props.globals.getNode('sim/model/ch53e/materials/panel-light-color/unaided/green', 1);
	panelLightBlue               = props.globals.getNode('controls/lighting/panel/color/blue', 1);
	panelLightBlueNvg            = props.globals.getNode('sim/model/ch53e/materials/panel-light-color/nvg/blue', 1);
	panelLightBlueUnaided        = props.globals.getNode('sim/model/ch53e/materials/panel-light-color/unaided/blue', 1);

	instrumentsLightRed          = props.globals.getNode('controls/lighting/instruments/color/red', 1);
	instrumentsLightRedNvg       = props.globals.getNode('sim/model/ch53e/materials/instrument-light-color/nvg/red', 1);
	instrumentsLightRedUnaided   = props.globals.getNode('sim/model/ch53e/materials/instrument-light-color/unaided/red', 1);
	instrumentsLightGreen        = props.globals.getNode('controls/lighting/instruments/color/green', 1);
	instrumentsLightGreenNvg     = props.globals.getNode('sim/model/ch53e/materials/instrument-light-color/nvg/green', 1);
	instrumentsLightGreenUnaided = props.globals.getNode('sim/model/ch53e/materials/instrument-light-color/unaided/green', 1);
	instrumentsLightBlue         = props.globals.getNode('controls/lighting/instruments/color/blue', 1);
	instrumentsLightBlueNvg      = props.globals.getNode('sim/model/ch53e/materials/instrument-light-color/nvg/blue', 1);
	instrumentsLightBlueUnaided  = props.globals.getNode('sim/model/ch53e/materials/instrument-light-color/unaided/blue', 1);

	nvgMode = props.globals.getNode('controls/lighting/nvg-mode', 1);

	adjustNvgMode();
	setlistener(nvgMode, adjustNvgMode);
}


################
#
# Rotor Brake
#
################

rotorBrakeSwitch = '';
rotorBrakeIndicatorPos = '';

animateRotorBrakeIndicator = func {
	if (rotorBrakeSwitch.getValue()) {
		interpolate('sim/model/ch53e/instrument-pos/rot-brake-ind-pos-norm', 1, 0.2);
	} else {
		interpolate('sim/model/ch53e/instrument-pos/rot-brake-ind-pos-norm', 0, 0.2);
	}
}
setlistener('controls/rotor/brake', animateRotorBrakeIndicator);

initRotorBrake = func {
	rotorBrakeSwitch = props.globals.getNode('controls/rotor/brake', 1);
	rotorBrakeIndicatorPos = props.globals.getNode('sim/model/ch53e/instrument-pos/rot-brake-ind-pos-norm', 1);
	animateRotorBrakeIndicator();
}
settimer(initRotorBrake, 0);

################
#
# Stick Position
#
# This will figure out where the stick is and convert it into a discrete low-res
# value. It then sets material properties that are used to run the material animation
# for the stick position indicator instrument. There is a private intensity property.
#
################

stickPosIntensity = nil;
stickPosTest = nil;
pollStickPos = func {
	materials = '/sim/model/ch53e/materials/';
	quant_pitch = int(((getprop('/controls/flight/elevator'))+1)/0.0606060606);
	quant_roll = int(((getprop('/controls/flight/aileron'))+1)/0.0606060606);
	if (getprop('controls/lighting/nvg-mode') == 1) {
		led_color = 'green';
		led_intensity = (stickPosIntensity.getValue()*0.5+0.1);
	} else {
		led_color = 'red';
		led_intensity = (stickPosIntensity.getValue()*0.9+0.1);
	}
	# Turn it all off, or on if the test button is pressed
	for (i=1;i<=8;i+=1) {
		foreach (zone; ['HSPLeft.00', 'HSPRight.00', 'VSPFore.00', 'VSPAft.00']) {
			if (stickPosTest.getValue() == 1) {
				setprop(materials~zone~i~'/emission/'~led_color, led_intensity);
			} else {
				foreach (color; ['red','green','blue']) {
					setprop(materials~zone~i~'/emission/'~color, '0'); 
				}
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
	settimer(pollStickPos, 0.1);
}
initStickPos = func {
	# Just to make sure that this property exists and has a sane value.
	stickPosTest = props.globals.getNode('sim/model/ch53e/control-input/stick-pos-test', 1);
	stickPosIntensity = props.globals.getNode('sim/model/ch53e/control-input/stick-pos-bright-norm', 1);
	# We assume that instruments-norm is a proper double. Someday this will cause trouble.
	if (stickPosIntensity.getType() != 'DOUBLE') {
		stickPosIntensity.setDoubleValue(getprop('controls/lighting/instruments-norm'));
	}
	settimer(pollStickPos, 0);
}
settimer(initStickPos, 0);

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
# Hydraulic System
#
################

# TODO switch off based on 2B pri AC bus    26v/QUAD HYDR QTY breaker   set value to -.2
hydVol0 = '';
hydVol1 = '';
hydVol2 = '';
hydVol3 = '';
hydCap0 = '';
hydCap1 = '';
hydCap2 = '';
hydCap3 = '';
initHydVolDisp = func {
	hydVol0 = props.globals.getNode('consumables/hydraulic/tank[0]/volume-gal_us', 1);
	hydVol1 = props.globals.getNode('consumables/hydraulic/tank[1]/volume-gal_us', 1);
	hydVol2 = props.globals.getNode('consumables/hydraulic/tank[2]/volume-gal_us', 1);
	hydVol3 = props.globals.getNode('consumables/hydraulic/tank[3]/volume-gal_us', 1);
	hydCap0 = props.globals.getNode('consumables/hydraulic/tank[0]/capacity-gal_us', 1);
	hydCap1 = props.globals.getNode('consumables/hydraulic/tank[1]/capacity-gal_us', 1);
	hydCap2 = props.globals.getNode('consumables/hydraulic/tank[2]/capacity-gal_us', 1);
	hydCap3 = props.globals.getNode('consumables/hydraulic/tank[3]/capacity-gal_us', 1);
	adjustHydVolDisp0();
	adjustHydVolDisp1();
	adjustHydVolDisp2();
	adjustHydVolDisp3();
}
settimer(initHydVolDisp, 0);

adjustHydVolDisp0 = func {
	reading = hydVol0.getValue() / hydCap0.getValue();
	interpolate('instrumentation/hydraulic-quantity/tank[0]/vol-norm', reading, 0.25);
}
setlistener('consumables/hydraulic/tank[0]/volume-gal_us', adjustHydVolDisp0);

adjustHydVolDisp1 = func {
	reading = hydVol1.getValue()/hydCap1.getValue();
	interpolate('instrumentation/hydraulic-quantity/tank[1]/vol-norm', reading, 0.25);
}
setlistener('consumables/hydraulic/tank[1]/volume-gal_us', adjustHydVolDisp1);

adjustHydVolDisp2 = func {
	reading = hydVol2.getValue()/hydCap2.getValue();
	interpolate('instrumentation/hydraulic-quantity/tank[2]/vol-norm', reading, 0.25);
}
setlistener('consumables/hydraulic/tank[2]/volume-gal_us', adjustHydVolDisp2);

adjustHydVolDisp3 = func {
	reading = hydVol3.getValue()/hydCap3.getValue();
	interpolate('instrumentation/hydraulic-quantity/tank[3]/vol-norm', reading, 0.25);
}
setlistener('consumables/hydraulic/tank[3]/volume-gal_us', adjustHydVolDisp3);

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

init = func {
	debugInit();
	initNvgMode();
	print("ch53e.nas initialized");
}
settimer(init, 0);


