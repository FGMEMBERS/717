# BOEING 717-200 SYSTEMS FILE
#############################

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

## ENGINES
##########

# explanation of engine properties
# controls/engines/engine[X]/throttle-lever	When the engine isn't running, this value is constantly set to 0; otherwise, we transfer the value of controls/engines/engine[X]/throttle to it
# controls/engines/engine[X]/starter		Triggering it fires up the engine
# engines/engine[X]/running			Set based on the engine state
# engines/engine[X]/rpm				Used in place of the n1 value for the animations and set dynamically based on the engine state
# engines/engine[X]/failed			When triggered the engine is "failed" and cannot be restarted
# engines/engine[X]/on-fire			Self-explanatory

# APU loop function
var apuLoop = func
 {
 if (props.globals.getNode("engines/apu/on-fire").getBoolValue())
  {
  props.globals.getNode("engines/apu/serviceable").setBoolValue(0);
  }
 if (props.globals.getNode("controls/APU/fire-switch").getBoolValue())
  {
  props.globals.getNode("engines/apu/on-fire").setBoolValue(0);
  }

 var setting = getprop("controls/APU/off-start-run");

 if (props.globals.getNode("engines/apu/serviceable").getBoolValue() and setting != 0)
  {
  if (setting == 1)
   {
   var rpm = getprop("engines/apu/rpm");
   rpm += getprop("sim/time/delta-realtime-sec") * 25;
   if (rpm >= 100)
    {
    rpm = 100;
    }
   setprop("engines/apu/rpm", rpm);
   }
  elsif (setting == 2 and getprop("engines/apu/rpm") == 100)
   {
   props.globals.getNode("engines/apu/running").setBoolValue(1);
   }
  }
 else
  {
  props.globals.getNode("engines/apu/running").setBoolValue(0);

  var rpm = getprop("engines/apu/rpm");
  rpm -= getprop("sim/time/delta-realtime-sec") * 30;
  if (rpm < 0)
   {
   rpm = 0;
   }
  setprop("engines/apu/rpm", rpm);
  }

 settimer(apuLoop, 0);
 };
# engine loop function
var engineLoop = func(engine_no)
 {
 # control the throttles and main engine properties
 var engineCtlTree = "controls/engines/engine[" ~ engine_no ~ "]/";
 var engineOutTree = "engines/engine[" ~ engine_no ~ "]/";

 # the FDM switches the running property to true automatically if the cutoff is set to false, this is unwanted
 if (props.globals.getNode(engineOutTree ~ "running").getBoolValue() and !props.globals.getNode(engineOutTree ~ "started").getBoolValue())
  {
  props.globals.getNode(engineOutTree ~ "running").setBoolValue(0);
  }

 if (props.globals.getNode(engineOutTree ~ "on-fire").getBoolValue())
  {
  props.globals.getNode(engineOutTree ~ "failed").setBoolValue(1);
  }
 if (props.globals.getNode(engineCtlTree ~ "cutoff").getBoolValue() or props.globals.getNode(engineOutTree ~ "failed").getBoolValue() or props.globals.getNode(engineOutTree ~ "out-of-fuel").getBoolValue())
  {
  if (getprop(engineOutTree ~ "rpm") > 0)
   {
   var rpm = getprop(engineOutTree ~ "rpm");
   rpm -= getprop("sim/time/delta-realtime-sec") * 2.5;
   setprop(engineOutTree ~ "rpm", rpm);
   }
  else
   {
   setprop(engineOutTree ~ "rpm", 0);
   }

  props.globals.getNode(engineOutTree ~ "running").setBoolValue(0);
  props.globals.getNode(engineOutTree ~ "started").setBoolValue(0);
  setprop(engineCtlTree ~ "throttle-lever", 0);
  }
 elsif (props.globals.getNode(engineCtlTree ~ "starter").getBoolValue() and props.globals.getNode("engines/apu/running").getBoolValue())
  {
  props.globals.getNode(engineCtlTree ~ "cutoff").setBoolValue(0);

  var rpm = getprop(engineOutTree ~ "rpm");
  rpm += getprop("sim/time/delta-realtime-sec") * 3;
  setprop(engineOutTree ~ "rpm", rpm);

  if (rpm >= getprop(engineOutTree ~ "n1"))
   {
   props.globals.getNode(engineCtlTree ~ "starter").setBoolValue(0);
   props.globals.getNode(engineOutTree ~ "started").setBoolValue(1);
   props.globals.getNode(engineOutTree ~ "running").setBoolValue(1);
   }
  else
   {
   props.globals.getNode(engineOutTree ~ "running").setBoolValue(0);
   }
  }
 elsif (props.globals.getNode(engineOutTree ~ "running").getBoolValue())
  {
  if (getprop("autopilot/settings/speed") == "speed-to-ga")
   {
   setprop(engineCtlTree ~ "throttle-lever", 1);
   }
  else
   {
   setprop(engineCtlTree ~ "throttle-lever", getprop(engineCtlTree ~ "throttle"));
   }

  setprop(engineOutTree ~ "rpm", getprop(engineOutTree ~ "n1"));
  }

 settimer(func
  {
  engineLoop(engine_no);
  }, 0);
 };
# start the loops 2 seconds after the FDM initializes
setlistener("sim/signals/fdm-initialized", func
 {
 settimer(func
  {
  engineLoop(0);
  engineLoop(1);
  apuLoop();
  }, 2);
 });

# startup/shutdown functions
var startup = func
 {
 setprop("controls/APU/off-start-run", 1);
 setprop("controls/electric/APU-generator", 1);
 setprop("controls/electric/battery-switch", 1);
 setprop("controls/electric/engine[0]/generator", 1);
 setprop("controls/electric/engine[1]/generator", 1);
 setprop("controls/engines/engine[0]/cutoff", 0);
 setprop("controls/engines/engine[1]/cutoff", 0);
 setprop("controls/engines/engine[0]/starter", 1);
 setprop("controls/engines/engine[1]/starter", 1);

 var listener1 = setlistener("engines/apu/rpm", func
  {
  if (getprop("engines/apu/rpm") >= 100)
   {
   setprop("controls/APU/off-start-run", 2);
   removelistener(listener1);
   }
  }, 0, 0);
 var listener2 = setlistener("engines/engine[0]/rpm", func
  {
  if (getprop("engines/engine[0]/rpm") >= getprop("engines/engine[0]/n1"))
   {
   settimer(func
    {
    setprop("controls/APU/off-start-run", 0);
    setprop("controls/electric/APU-generator", 0);
    setprop("controls/electric/battery-switch", 0);
    }, 2);
   removelistener(listener2);
   }
  }, 0, 0);
 };
var shutdown = func
 {
 setprop("controls/electric/engine[0]/generator", 0);
 setprop("controls/electric/engine[1]/generator", 0);
 setprop("controls/engines/engine[0]/cutoff", 1);
 setprop("controls/engines/engine[1]/cutoff", 1);
 };

# listener to activate these functions accordingly
setlistener("sim/model/start-idling", func(idle)
 {
 var run = idle.getBoolValue();
 if (run)
  {
  startup();
  }
 else
  {
  shutdown();
  }
 }, 0, 0);

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
 loop: func
  {
  instruments.setHSIBugsDeg();
  instruments.setMPProps();
  instruments.calcTat();

  settimer(instruments.loop, 0);
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
# start the loop 2 seconds after the FDM initializes
setlistener("sim/signals/fdm-initialized", func
 {
 settimer(instruments.loop, 2);
 });

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
 loop: func
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

  # rerun after 1/5 of a second
  settimer(speedbrakes.loop, 0.2);
  }
 };
# start the loop 2 seconds after the FDM initializes
setlistener("sim/signals/fdm-initialized", func
 {
 settimer(speedbrakes.loop, 2);
 });

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

## AUTOPILOT
############

# set the vertical speed setting if the altitude setting is higher/lower than the current altitude
var APVertSpeedSet = func
 {
 var altitude = getprop("instrumentation/altimeter/indicated-altitude-ft");
 var altitudeSetting = getprop("autopilot/settings/target-altitude-ft");
 var vertSpeedSetting = getprop("autopilot/settings/vertical-speed-fpm");

 if (altitude and altitudeSetting and vertSpeedSetting and math.abs(altitude - altitudeSetting) > 100)
  {
  if (altitude > altitudeSetting and vertSpeedSetting >= 0)
   {
   setprop("autopilot/settings/vertical-speed-fpm", -1000);
   }
  elsif (altitude < altitudeSetting and vertSpeedSetting <= 0)
   {
   setprop("autopilot/settings/vertical-speed-fpm", 1800);
   }
  }
 };
setlistener("autopilot/settings/target-altitude-ft", APVertSpeedSet, 1, 0);
