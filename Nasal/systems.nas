# BOEING 717-200 SYSTEMS FILE
#############################

# NOTE: This file contains a loop for running all update functions, so it should be loaded last

## SYSTEMS LOOP
###############

var systems =
 {
 stopUpdate: 0,
 init: func
  {
  print("B717 aircraft systems ... initialized");
  systems.stop();
  settimer(func
   {
   systems.stopUpdate = 0;
   systems.update();
   }, 0.5);
  },
 stop: func
  {
  systems.stopUpdate = 1;
  },
 update: func
  {
  apu1.update();
  engine1.update();
  engine2.update();
  speedbrakes.update();
  instruments.update();
  update_electrical();

  # stop calling our systems code if the stop() function was called or the aircraft crashes
  if (!systems.stopUpdate and !props.globals.getNode("sim/crashed").getBoolValue())
   {
   settimer(systems.update, 0);
   }
  }
 };

# call init() 2 seconds after the FDM is ready
setlistener("sim/signals/fdm-initialized", func
 {
 var autopilot = gui.Dialog.new("sim/gui/dialogs/autopilot/dialog", "Aircraft/717/Systems/autopilot-dlg.xml");
 itaf.ap_init();
 setprop("/it-autoflight/settings/retard-enable", 1);  # Enable or disable automatic autothrottle retard.
 setprop("/it-autoflight/settings/retard-ft", 35);     # Add this to change the retard altitude, default is 50ft AGL.
 setprop("/it-autoflight/settings/land-flap", 0.7);    # Define the landing flaps here. This is needed for autoland, and retard.
 setprop("/it-autoflight/settings/land-enable", 0);    # Enable or disable automatic landing.
 setprop("/engines/engine[0]/epr-limit", 1.47);
 setprop("/engines/engine[1]/epr-limit", 1.47);
 setprop("/it-autoflight/fd_mastersw", 1);
 setprop("/it-autoflight/fd_mastersw2", 1);
 settimer(systems.init, 2);
 }, 0, 0);
# call init() if the simulator resets
setlistener("sim/signals/reinit", func(reinit)
 {
 if (reinit.getBoolValue())
  {
  systems.init();
  }
 }, 0, 0);

## LIVERY SELECT
################
aircraft.livery.init("Aircraft/717/Models/Liveries");

## LIGHTS
#########

# create all lights
var beacon_switch = props.globals.getNode("controls/switches/beacon", 2);
var beacon = aircraft.light.new("sim/model/lights/beacon", [0.05, 2], "controls/lighting/beacon");

var strobe_switch = props.globals.getNode("controls/switches/strobe", 2);
var strobe = aircraft.light.new("sim/model/lights/strobe", [0.05, 1.3], "controls/lighting/strobe");

## SOUNDS
#########

# seatbelt/no smoking sign triggers
setlistener("controls/switches/seatbelt-sign", func
 {
 props.globals.getNode("sim/sound/seatbelt-sign").setBoolValue(1);

 settimer(func
  {
  props.globals.getNode("sim/sound/seatbelt-sign").setBoolValue(0);
  }, 2);
 });
setlistener("controls/switches/no-smoking-sign", func
 {
 props.globals.getNode("sim/sound/no-smoking-sign").setBoolValue(1);

 settimer(func
  {
  props.globals.getNode("sim/sound/no-smoking-sign").setBoolValue(0);
  }, 2);
 });

## TIRE SMOKE/RAIN
##################

var tiresmoke_system = aircraft.tyresmoke_system.new(0, 1, 2);
aircraft.rain.init();

## GEAR
#######

# prevent retraction of the landing gear when any of the wheels are compressed
setlistener("controls/gear/gear-down", func
 {
 var down = props.globals.getNode("controls/gear/gear-down").getBoolValue();
 if (!down and (getprop("gear/gear[0]/wow") or getprop("gear/gear[1]/wow") or getprop("gear/gear[2]/wow")))
  {
  props.globals.getNode("controls/gear/gear-down").setBoolValue(1);
  }
 });

## INSTRUMENTS
##############

var instruments =
 {
 calcBugDeg: func(bug, limit)
  {
  var heading = getprop("orientation/heading-magnetic-deg");
  var bugDeg = 0;

  while (bug < 0)
   {
   bug += 360;
   }
  while (bug > 360)
   {
   bug -= 360;
   }
  if (bug < limit)
   {
   bug += 360;
   }
  if (heading < limit)
   {
   heading += 360;
   }
  # bug is adjusted normally
  if (math.abs(heading - bug) < limit)
   {
   bugDeg = heading - bug;
   }
  elsif (heading - bug < 0)
   {
   # bug is on the far right
   if (math.abs(heading - bug + 360 >= 180))
    {
    bugDeg = -limit;
    }
   # bug is on the far left
   elsif (math.abs(heading - bug + 360 < 180))
    {
    bugDeg = limit;
    }
   }
  else
   {
   # bug is on the far right
   if (math.abs(heading - bug >= 180))
    {
    bugDeg = -limit;
    }
   # bug is on the far left
   elsif (math.abs(heading - bug < 180))
    {
    bugDeg = limit;
    }
   }

  return bugDeg;
  },
 update: func
  {
  instruments.setHSIBugsDeg();
  instruments.setMPProps();
  instruments.calcTat();
  },
 # set the rotation of the HSI bugs
 setHSIBugsDeg: func
  {
  setprop("sim/model/B717/heading-bug-pfd-deg", instruments.calcBugDeg(getprop("autopilot/settings/heading-bug-deg"), 32));
  setprop("sim/model/B717/heading-bug-deg", instruments.calcBugDeg(getprop("autopilot/settings/heading-bug-deg"), 42));
  setprop("sim/model/B717/nav1-track-deg", instruments.calcBugDeg(getprop("instrumentation/nav[0]/radials/selected-deg"), 42));
  setprop("sim/model/B717/nav1-bug-deg", instruments.calcBugDeg(getprop("instrumentation/nav[0]/heading-deg"), 42));
  setprop("sim/model/B717/nav2-bug-deg", instruments.calcBugDeg(getprop("instrumentation/nav[1]/heading-deg"), 42));
  setprop("sim/model/B717/adf-bug-deg", instruments.calcBugDeg(getprop("instrumentation/adf/indicated-bearing-deg"), 42));
  if (getprop("autopilot/route-manager/route/num") > 0 and getprop("autopilot/route-manager/wp[0]/bearing-deg") != nil)
   {
   setprop("sim/model/B717/wp-bearing-deg", instruments.calcBugDeg(getprop("autopilot/route-manager/wp[0]/bearing-deg"), 45));
   }
  },
 setMPProps: func
  {
  var calcMPDistance = func(tree)
   {
   var x = getprop(tree ~ "position/global-x");
   var y = getprop(tree ~ "position/global-y");
   var z = getprop(tree ~ "position/global-z");
   var coords = geo.Coord.new().set_xyz(x, y, z);

   var distance = nil;
   call(func distance = geo.aircraft_position().distance_to(coords), nil, var err = []);
   if (size(err) or distance == nil)
    {
    return 0;
    }
   else
    {
    return distance;
    }
   };
  var calcMPBearing = func(tree)
   {
   var x = getprop(tree ~ "position/global-x");
   var y = getprop(tree ~ "position/global-y");
   var z = getprop(tree ~ "position/global-z");
   var coords = geo.Coord.new().set_xyz(x, y, z);

   return geo.aircraft_position().course_to(coords);
   };
  if (getprop("ai/models/multiplayer[0]/valid"))
   {
   setprop("sim/model/B717/multiplayer-distance[0]", calcMPDistance("ai/models/multiplayer[0]/"));
   setprop("sim/model/B717/multiplayer-bearing[0]", instruments.calcBugDeg(calcMPBearing("ai/models/multiplayer[0]/"), 45));
   }
  if (getprop("ai/models/multiplayer[1]/valid"))
   {
   setprop("sim/model/B717/multiplayer-distance[1]", calcMPDistance("ai/models/multiplayer[1]/"));
   setprop("sim/model/B717/multiplayer-bearing[1]", instruments.calcBugDeg(calcMPBearing("ai/models/multiplayer[1]/"), 45));
   }
  if (getprop("ai/models/multiplayer[2]/valid"))
   {
   setprop("sim/model/B717/multiplayer-distance[2]", calcMPDistance("ai/models/multiplayer[2]/"));
   setprop("sim/model/B717/multiplayer-bearing[2]", instruments.calcBugDeg(calcMPBearing("ai/models/multiplayer[2]/"), 45));
   }
  if (getprop("ai/models/multiplayer[3]/valid"))
   {
   setprop("sim/model/B717/multiplayer-distance[3]", calcMPDistance("ai/models/multiplayer[3]/"));
   setprop("sim/model/B717/multiplayer-bearing[3]", instruments.calcBugDeg(calcMPBearing("ai/models/multiplayer[3]/"), 45));
   }
  if (getprop("ai/models/multiplayer[4]/valid"))
   {
   setprop("sim/model/B717/multiplayer-distance[4]", calcMPDistance("ai/models/multiplayer[4]/"));
   setprop("sim/model/B717/multiplayer-bearing[4]", instruments.calcBugDeg(calcMPBearing("ai/models/multiplayer[4]/"), 45));
   }
  if (getprop("ai/models/multiplayer[5]/valid"))
   {
   setprop("sim/model/B717/multiplayer-distance[5]", calcMPDistance("ai/models/multiplayer[5]/"));
   setprop("sim/model/B717/multiplayer-bearing[5]", instruments.calcBugDeg(calcMPBearing("ai/models/multiplayer[5]/"), 45));
   }
  },
 # TAT display calculator
 # Formula:
 #  T = S + 0.16SM^2
 #  where T = TAT, S = SAT, and M = Mach number
 calcTat: func
  {
  var sat = getprop("environment/temperature-degc");
  var mach = getprop("velocities/mach");

  setprop("instrumentation/total-air-temperature-degc", sat + 0.195 * sat * (mach * mach));
  }
 };

## AUTOBRAKES/SPEEDBRAKES
#########################

# autobrake setting listener
setlistener("autopilot/autobrake/step", func
 {
 var setting = getprop("autopilot/autobrake/step");
 if (setting == -2)
  {
  gui.popupTip("Autobrakes set to RTO.");
  }
 elsif (setting == -1)
  {
  gui.popupTip("Autobrakes off.");
  }
 elsif (setting == 0)
  {
  gui.popupTip("Autobrakes disarmed.");
  }
 elsif (setting == 1)
  {
  gui.popupTip("Autobrakes set to 1.");
  }
 elsif (setting == 2)
  {
  gui.popupTip("Autobrakes set to 2.");
  }
 elsif (setting == 3)
  {
  gui.popupTip("Autobrakes set to 3.");
  }
 elsif (setting == 4)
  {
  gui.popupTip("Autobrakes set to 4.");
  }
 elsif (setting == 5)
  {
  gui.popupTip("Autobrakes set to maximum power.");
  }
 }, 0, 0);

# function to deploy speedbrakes on touchdown
var speedbrakes =
 {
 inair: "false",
 landed: "false",
 update: func
  {
  # set in air/landed values
  if (speedbrakes.inair == "true" and getprop("gear/gear[1]/wow") == 1)
   {
   speedbrakes.inair = "false";
   speedbrakes.landed = "true";
   }
  if (speedbrakes.inair == "false" and getprop("gear/gear[1]/wow") == 0)
   {
   speedbrakes.inair = "true";
   speedbrakes.landed = "false";
   }

  if (props.globals.getNode("autopilot/autobrake/engaged").getBoolValue() and props.globals.getNode("autopilot/autobrake/rto-selected").getBoolValue())
   {
   setprop("controls/flight/speedbrake-lever", 2);
   }
  if (speedbrakes.landed == "true" and getprop("controls/flight/speedbrake-lever") == 1)
   {
   setprop("controls/flight/speedbrake-lever", 2);

   speedbrakes.landed = "false";
   }
  if (getprop("velocities/groundspeed-kt") < 60)
   {
   speedbrakes.landed = "false";
   }
  }
 };

# speedbrake setting listener
setlistener("controls/flight/speedbrake-lever", func
 {
 var setting = getprop("controls/flight/speedbrake-lever");
 if (setting == 0)
  {
  setprop("controls/flight/speedbrake", 0);
  }
 elsif (setting == 2)
  {
  setprop("controls/flight/speedbrake", 1);
  }
 }, 0, 0);
