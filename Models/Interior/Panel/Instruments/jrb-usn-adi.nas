adjustATTFlag = func {
	if (getprop('instrumentation/attitude-indicator/serviceable') and (getprop('instrumentation/attitude-indicator/spin') > 0.99)) {
		interpolate('sim/model/jrb-usn-adi/ATTFlag-pos-norm', 1, 0.25);
	} else {
		interpolate('sim/model/jrb-usn-adi/ATTFlag-pos-norm', 0, 0.25);
	}
}
setlistener('instrumentation/attitude-indicator/serviceable', adjustATTFlag);
setlistener('instrumentation/attitude-indicator/spin', adjustATTFlag);

print("jrb-usn-adi.nas initialized");

