# Create initial announced variables at startup of the sim
V1 = "";
VR = "";
V2 = "";

# The actual function
var vspeeds = func {

       # Create/populate variables at each function cycle
       # Retrieve total aircraft weight and convert to kg.
	WT = getprop("/yasim/gross-weight-lbs")*0.00045359237;
	flaps = getprop("/instrumentation/fmc/to-flap");

       # Calculate V-speeds with flaps 5
	if (flaps == 5) {
		V1 = (0.8*(WT-20))+110;
		VR = (0.8*(WT-20))+125;
		V2 = (0.8*(WT-20))+145;
	}

       # Calculate V-speeds with flaps 10
	elsif (flaps == 10) {
		V1 = (0.8*(WT-20))+95;
		VR = (0.8*(WT-20))+120;
		V2 = (0.8*(WT-20))+140;
	}

       # Export the calculated V-speeds to the property-tree, for further use
	setprop("/instrumentation/fmc/vspeeds/V1",V1);
	setprop("/instrumentation/fmc/vspeeds/VR",VR);
	setprop("/instrumentation/fmc/vspeeds/V2",V2);

       # Repeat the function each second
	settimer(vspeeds, 1);
}

# Only start the function 2 seconds after the FDM is initialized, to prevent the problem of not-yet-created properties.
_setlistener("/sim/signals/fdm-initialized", func {
	settimer(vspeeds, 2);
});
