luahue
======

Lua API and command line utility to control your Philips Hue lightbulbs.

### Command Line Utility

The following examples assume your bridge IP is `192.168.1.72` and your authenticated 
username is `abcdeveloper`. Let's start with sample usage:
```
$ huectl -h
Utility to control Philips Hue lights
  -d,--discover                         Discover local bridges
  -r,--register   (optional string)     Register username at bridge
  -u,--username   (default huectladmin) Authenticate using this username
  -l,--list                             Lights to manipulate

  -P,--power      (optional on|off)     Turn lights on or off
  -A,--alert      (optional short|long) Cycle the light brightness
  -E,--effect     (optional none|colorloop) Set an effect
  -T,--transition (optional number)     Set transition time (x100ms)

  -B,--brightness (optional 0..255)     Set brightness
  -H,--hue        (optional 0..65535)   Set hue (0 red, 25500 green, 46920 blue)
  -S,--saturation (optional 0..255)     Set saturation (0 colored, 255 white)
  -C,--temperature (optional 153..500)  Set color temp (153 cooler, 500 warmer)

  <bridge>        (optional string)     IP address of a Philips bridge
  <lights...>     (optional string)     List of lights (id or name)
```

Let's find out what lights are currently registered with your Philips bridge:
```
$ huectl -u abcdeveloper -l 192.168.1.72
1       Pete
2       TV
3       Door
4       Dining Room
```

When specifying lights on the command line, you can either use the index (lefthand 
column) or the more friendly name (righthand column). If using the name, you may
need to quote it appropriately. If you don't specify any lights, then any settings
will be applied to all lights. For example, let's turn some lights on!
```
$ huectl -u abcdeveloper -P on 192.168.1.72           # turns all lights on
$ huectl -u abcdeveloper -P off 192.168.1.72 TV Door  # turns some lights off
$ huectl -u abcdeveloper -P off 192.168.1.72 2 3      # same as previous cmd 
```

More to come ...

### API Documentation

More to come ...
