########
#
# ADI
#
########

adiAttFlagState = props.globals.getNode('sim/model/jrb-usn/ATTFlag-state', 1);
adiAttFlagState.setIntValue(1);

adiServiceable = props.globals.getNode('instrumentation/attitude-indicator/serviceable', 1);
adiServiceable.setBoolValue(1);

adiSpin = props.globals.getNode('instrumentation/attitude-indicator/spin', 1);
adiSpin.setDoubleValue(0);

adiWatchAttFlag = func {
	if (adiServiceable.getValue() and (adiSpin.getValue() > 0.86)) {
		adiAttFlagState.setIntValue(0);
	} else {
		adiAttFlagState.setIntValue(1);
	}
	settimer(adiWatchAttFlag, 1);
}
settimer(adiWatchAttFlag, 0);

# These don't work, not sure why.
# setlistener('instrumentation/attitude-indicator/serviceable', watchATTFlag);
# setlistener('instrumentation/attitude-indicator/spin', watchATTFlag);

adiAnimateAttFlag = func {
	if (adiAttFlagState.getValue() == 1) {
		interpolate('sim/model/jrb-usn/ATTFlag-pos-norm', 1, 0.15);
	} else {
		interpolate('sim/model/jrb-usn/ATTFlag-pos-norm', 0, 0.15);
	}
}
setlistener('sim/model/jrb-usn/ATTFlag-state', adiAnimateAttFlag);

########
#
# Gyro Compass
#
########

gyroNeedle1 = '';
gyroNeedle2 = '';
source1 = '';
source2 = '';

nav1Heading = '';
nav2Heading = '';
adfHeading = '';
tacanHeading = '';
# gpsHeading = '';

updateGyroNeedles = func {
	# TODO
	gyroNeedle1.setDoubleValue(80);
	gyroNeedle2.setDoubleValue(100);
	settimer(updateGyroNeedles, 0.1);
}

initGyroCompass = func {
	gyroNeedle1 = props.globals.getNode('sim/model/jrb-usn/gyro-needle-heading[0]', 1);
	gyroNeedle2 = props.globals.getNode('sim/model/jrb-usn/gyro-needle-heading[1]', 1);
	source1 = props.globals.getNode('sim/model/jrb-usn/gyro-needle-source[0]', 1);
	source2 = props.globals.getNode('sim/model/jrb-usn/gyro-needle-source[1]', 1);

	nav1Heading = props.globals.getNode('instrumentation/nav[0]/heading-deg');
	nav2Heading = props.globals.getNode('instrumentation/nav[1]/heading-deg');
	adfHeading = props.globals.getNode('instrumentation/adf/indicated-bearing-deg');
	tacanHeading = props.globals.getNode('instrumentation/tacan/indicated-bearing-true-deg');
	# TODO
	# gpsHeading = props.globals.getNode('');

	updateGyroNeedles();
}
settimer(initGyroCompass, 0);

print("jrb-usn.nas initialized");

