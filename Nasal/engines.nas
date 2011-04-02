# BOEING 717-200 ENGINES FILE
#############################

# NOTE: Update functions are called in systems.nas

var apu =
 {
 new: func(no)
  {
  var m =
   {
   parents: [apu]
   };
  m.number = no;

  m.fire_switch = props.globals.getNode("engines/apu[" ~ no ~ "]/fire-switch", 1);
  m.fire_switch.setBoolValue(0);
  m.off_start_run = props.globals.getNode("controls/APU[" ~ no ~ "]/off-start-run", 1);
  m.off_start_run.setValue(0);
  m.on_fire = props.globals.getNode("engines/apu[" ~ no ~ "]/on-fire", 1);
  m.on_fire.setBoolValue(0);
  m.rpm = props.globals.getNode("engines/apu[" ~ no ~ "]/rpm", 1);
  m.rpm.setValue(0);
  m.running = props.globals.getNode("engines/apu[" ~ no ~ "]/running", 1);
  m.running.setBoolValue(0);
  m.serviceable = props.globals.getNode("engines/apu[" ~ no ~ "]/serviceable", 1);
  m.serviceable.setBoolValue(1);

  return m;
  },
 update: func
  {
  if (me.on_fire.getBoolValue())
   {
   me.serviceable.setBoolValue(0);
   }
  if (me.fire_switch.getBoolValue())
   {
   me.on_fire.setBoolValue(0);
   }

  if (me.serviceable.getBoolValue() and me.off_start_run.getValue() != 0)
   {
   if (me.off_start_run.getValue() == 1)
    {
    var rpm = me.rpm.getValue();
    rpm += getprop("sim/time/delta-realtime-sec") * 25;
    if (rpm >= 100)
     {
     rpm = 100;
     }
    me.rpm.setValue(rpm);
    }
   if (me.off_start_run.getValue() == 2 and me.rpm.getValue() == 100)
    {
    me.running.setBoolValue(1);
    }
   }
  else
   {
   me.running.setBoolValue(0);

   var rpm = me.rpm.getValue();
   rpm -= getprop("sim/time/delta-realtime-sec") * 30;
   if (rpm <= 0)
    {
    rpm = 0;
    }
   me.rpm.setValue(rpm);
   }
  }
 };
var engine =
 {
 new: func(no)
  {
  var m =
   {
   parents: [engine]
   };
  m.number = no;
  m.throttle_at_idle = 0.02;

  m.cutoff = props.globals.getNode("controls/engines/engine[" ~ no ~ "]/cutoff", 1);
  m.cutoff.setBoolValue(0);
  m.n1 = props.globals.getNode("engines/engine[" ~ no ~ "]/n1", 1);
  m.n1.setValue(0);
  m.no_fuel = props.globals.getNode("engines/engine[" ~ no ~ "]/out-of-fuel", 1);
  m.no_fuel.setBoolValue(0);
  m.on_fire = props.globals.getNode("engines/engine[" ~ no ~ "]/on-fire", 1);
  m.on_fire.setBoolValue(0);
  m.reverser = props.globals.getNode("controls/engines/engine[" ~ no ~ "]/reverser", 1);
  m.reverser.setBoolValue(0);
  m.reverser_lever = props.globals.getNode("controls/engines/engine[" ~ no ~ "]/reverser-lever", 1);
  m.reverser_lever.setBoolValue(0);
  m.reverser_pos_norm = props.globals.getNode("engines/engine[" ~ no ~ "]/reverser-pos-norm", 1);
  m.reverser_pos_norm.setValue(0);
  m.rpm = props.globals.getNode("engines/engine[" ~ no ~ "]/rpm", 1);
  m.rpm.setValue(0);
  m.running = props.globals.getNode("engines/engine[" ~ no ~ "]/running", 1);
  m.running.setBoolValue(0);
  m.serviceable = props.globals.getNode("sim/failure-manager/engines/engine[" ~ no ~ "]/serviceable", 1);
  m.serviceable.setBoolValue(1);
  m.started = props.globals.getNode("engines/engine[" ~ no ~ "]/started", 1);
  m.started.setBoolValue(0);
  m.starter = props.globals.getNode("controls/engines/engine[" ~ no ~ "]/starter", 1);
  m.starter.setBoolValue(0);
  m.throttle = props.globals.getNode("controls/engines/engine[" ~ no ~ "]/throttle", 1);
  m.throttle.setValue(0);
  m.throttle_lever = props.globals.getNode("controls/engines/engine[" ~ no ~ "]/throttle-lever", 1);
  m.throttle_lever.setValue(0);

  return m;
  },
 update: func
  {
  if (me.running.getBoolValue() and !me.started.getBoolValue())
   {
   me.running.setBoolValue(0);
   }
  if (me.on_fire.getBoolValue())
   {
   me.serviceable.setBoolValue(0);
   }
  if (me.cutoff.getBoolValue() or !me.serviceable.getBoolValue() or me.no_fuel.getBoolValue())
   {
   var rpm = me.rpm.getValue();
   if (rpm > 0)
    {
    rpm -= getprop("sim/time/delta-realtime-sec") * 4;
    }
   else
    {
    rpm = 0;
    }
   me.rpm.setValue(rpm);
   me.running.setBoolValue(0);
   me.started.setBoolValue(0);
   }
  elsif (me.starter.getBoolValue())
   {
   me.cutoff.setBoolValue(0);

   var rpm = me.rpm.getValue();
   rpm += getprop("sim/time/delta-realtime-sec") * 3;
   me.rpm.setValue(rpm);

   if (rpm >= me.n1.getValue())
    {
    me.running.setBoolValue(1);
    me.started.setBoolValue(1);
    me.starter.setBoolValue(0);
    }
   else
    {
    me.running.setBoolValue(0);
    }
   }
  elsif (me.running.getBoolValue())
   {
   if (getprop("autopilot/setting/speed") == "to-ga")
    {
    me.throttle_lever.setValue(1);
    }
   else
    {
    me.throttle_lever.setValue(me.throttle_at_idle + (1 - me.throttle_at_idle) * me.throttle.getValue());
    }

   me.rpm.setValue(me.n1.getValue());
   }
  },
 reverse_thrust: func
  {
  if (me.reverser.getBoolValue())
   {
   me.reverser.setBoolValue(0);
   }
  elsif (me.throttle.getValue() == 0 and props.globals.getNode("gear/gear[1]/wow").getBoolValue())
   {
   me.reverser.setBoolValue(1);
   }
  }
 };
var apu1 = apu.new(0);
var engine1 = engine.new(0);
var engine2 = engine.new(1);

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
