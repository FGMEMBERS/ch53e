
# List of all the caution light object names
lights = [
	"Warn.1antiice",    "Warn.1engbst",   "Warn.1engfltr",  "Warn.1engoph",    "Warn.1engoplow", "Warn.1engqtylow", 
	"Warn.1feullow",    "Warn.1gen",      "Warn.1igvice",   "Warn.1ngbhot",    "Warn.1ngbop",    "Warn.1rec", 
	"Warn.1stgmr",      "Warn.1stgpr",    "Warn.1stgsb",    "Warn.1stqty",     "Warn.2engbst",   "Warn.2engfltr", 
	"Warn.2engoh",      "Warn.2engop",    "Warn.2engoph",   "Warn.2engqtylow", "Warn.2fuellow",  "Warn.2gen", 
	"Warn.2ptflt",      "Warn.2rect",     "Warn.2stgmrsb",  "Warn.2stgoh",     "Warn.2stgpmr",   "Warn.2stgqty", 
	"Warn.2stgtrsb",    "Warn.3antiice",  "Warn.3engbst",   "Warn.3engfltr",   "Warn.3engop",    "Warn.3engoph", 
	"Warn.3engqtylow",  "Warn.3fuellow",  "Warn.3gen",      "Warn.3ngbhot",    "Warn.3ngbop",    "Warn.acchot",
	"Warn.accpres",     "Warn.afcs",      "Warn.afcsdeg",   "Warn.afthook",    "Warn.alt",       "Warn.app",
	"Warn.autorel",     "Warn.bim",       "Warn.blade",     "Warn.blank",      "Warn.blank.001", "Warn.blank.002",
	"Warn.blank.003",   "Warn.blank.004", "Warn.blank.005", "Warn.blank.006",  "Warn.blank.007", "Warn.blank.008",
	"Warn.blank.009",   "Warn.blank.010", "Warn.blank.011", "Warn.blank.012",  "Warn.blank.013", "Warn.blank.014",
	"Warn.cghook",      "Warn.chip",      "Warn.com1",      "Warn.comp",       "Warn.dopp",      "Warn.eaps",
	"Warn.eapshp",      "Warn.engtqe",    "Warn.extpwr",    "Warn.fwdhook",    "Warn.gpwsalert", "Warn.gpwsinop",
	"Warn.gpwstacinhb", "Warn.headpos",   "Warn.ice",       "Warn.iff",        "Warn.igbop",     "Warn.igv2ice",
	"Warn.igv3ice",     "Warn.isol",      "Warn.mgbhot",    "Warn.mgblube",    "Warn.mgbop",     "Warn.park",
	"Warn.purge",       "Warn.radalt1",   "Warn.radalt2",   "Warn.ramp",       "Warn.rotbrk",    "Warn.rotbrkpr",
	"Warn.rotlock",     "Warn.sphook",    "Warn.start",     "Warn.tgbop",      "Warn.u1hot",     "Warn.u1press",
	"Warn.u1qtytr",     "Warn.u2hot",     "Warn.u2press",   "Warn.u2pump",     "Warn.u2qty",     "Warn.utrpres"];

# These will be property nodes, anchor them in this scope
nvgMode = '';
testButton = '';
nvgRed = '';
nvgGreen = '';
nvgBlue = '';
unaidedRed = '';
unaidedGreen = '';
unaidedBlue = '';

init = func {
	nvgMode = props.globals.getNode('controls/lighting/nvg-mode', 1);
	testButton =  props.globals.getNode('sim/model/ch53e/control-input/caution-test', 1);
	nvgRed = props.globals.getNode('sim/model/ch53e/instrument-pos/panel-light-color/nvg/red');
	nvgGreen = props.globals.getNode('sim/model/ch53e/instrument-pos/panel-light-color/nvg/green');
	nvgBlue = props.globals.getNode('sim/model/ch53e/instrument-pos/panel-light-color/nvg/blue');
	unaidedRed = props.globals.getNode('sim/model/ch53e/instrument-pos/panel-light-color/unaided/red');
	unaidedGreen = props.globals.getNode('sim/model/ch53e/instrument-pos/panel-light-color/unaided/green');
	unaidedBlue = props.globals.getNode('sim/model/ch53e/instrument-pos/panel-light-color/unaided/blue');
	foreach(light; lights) {
		setprop('sim/model/ch53e/materials/'~light~'/emission/red', 0);
		setprop('sim/model/ch53e/materials/'~light~'/emission/green', 0);
		setprop('sim/model/ch53e/materials/'~light~'/emission/blue', 0);
	}
}
settimer(init, 0);

# This handles the property that the test button modifies
test = func {
	foreach(light; lights) {
		if(testButton.getValue() == 1) {
			# Button pressed
			if(nvgMode.getValue()) {
				setprop('sim/model/ch53e/materials/'~light~'/emission/red', nvgRed.getValue());
				setprop('sim/model/ch53e/materials/'~light~'/emission/green', nvgGreen.getValue());
				setprop('sim/model/ch53e/materials/'~light~'/emission/blue', nvgBlue.getValue());
			} else {
				setprop('sim/model/ch53e/materials/'~light~'/emission/red', unaidedRed.getValue());
				setprop('sim/model/ch53e/materials/'~light~'/emission/green', unaidedGreen.getValue());
				setprop('sim/model/ch53e/materials/'~light~'/emission/blue', unaidedBlue.getValue());
			}
		} else {
			# Button released
			setprop('sim/model/ch53e/materials/'~light~'/emission/red', 0);
			setprop('sim/model/ch53e/materials/'~light~'/emission/green', 0);
			setprop('sim/model/ch53e/materials/'~light~'/emission/blue', 0);
		}
	}
}
setlistener('sim/model/ch53e/control-input/caution-test', test);

print('ch53e-caution.nas initialized');
