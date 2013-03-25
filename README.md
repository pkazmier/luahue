luahue
======

A Lua library to control your Philips Hue light bulbs. The library is
a loose wrapper around the REST API provided by Philips. In addition,
two sample command line utilities have been included to demonstrate
the use of the API. The first, `huectl`, is a generic tool that let's
you control the various properties such as on/off, color, and
brightness.  You can use this utility for all sorts of fun stuff. For
example, I have my lights flash briefly on web server hits or ssh
attempts (via iptables and swatch). The second utility, `huebwmon`,
changes the colors of my lights based on the amount of bandwidth
to/from my ISP.

 - <a href="#command-line-utility-huectl">huectl</a> - Hue Control
 - <a href="#command-line-utility-huebwmon">huebwmon</a> - Hue Bandwidth Monitor
 - <a href="#api-documentation">hue.lua</a> - Lua Hue API

For those that do not know abouth the Philips Hue light system, it
consists of LED bulbs that are networked together allowing them to be
controlled remotely via an IP network. One can control settings such
as hue, brightness, and saturation. The bulbs are not wi-fi enabled,
but use the zigbee protocol to communicate with each other and the
Philips bridge. The bridge, included in the 3 bulb starter pack,
connects to your home router via Ethernet making the lights accessible
via IP from your home network. All communication to/from the lights is
done via the bridge.

### Command Line Utility: huectl

Let's explore what the Hue bulbs have to offer using `huectl`, a
command line utility written in Lua that utilizes the `hue.lua`
library. With that said, let's get started! You'll need to make sure
you have a few Lua libraries installed: penlight, lua2json, and
luasocket. This is trivial with `luarocks`:

```
$ sudo luarocks install penlight
$ sudo luarocks install lua2json
$ sudo luarocks install luasocket
```

First, we need to discover the IP addresses of any Hue bridges
connected to our local network. We can do so using the `-d` or
`--discover` option:

```
$ huectl -d
192.168.1.72
```

On my local network, one bridge was discovered. The IP address of the
bridge is `192.168.1.72`. We will need to specify this on the command
line in our subsequent examples.

Before we can issue commands to our Hue bridge, we must register a
username with the bridge that will be used for authorization.
Usernames must be a minimum of 10 characters but no more than 40. If
you do not specify a username, the default `huectladmin` will be used
instead. Let's try and register our username:

```
$ huectl -r 192.168.1.72
link button not pressed
```

The command failed because you must press the link button on your
bridge and then execute this commend within 30 seconds. Let's try that
again after pressing the link button:

```
$ huectl -r 192.168.1.72
Registered username successfully
```

We have now registered our username and can now start examining and
changing the state of our lights. Let's find out what lights are
currently registered with our bridge:

```
$ huectl -l 192.168.1.72
1       Office
2       TV
3       Door
4       Dining Room
```

Four lights have been associated with this bridge. We will be able to
manipulate one or more of these lights using `huectl`. When specifying
lights on the command line, you can either use the index (number in
the lefthand column) or the more user friendly name provided next to
it. If using the name, you may need to quote it appropriately. If you
don't specify any lights on the command line, then any requests will
be sent to all lights. For example, to turn on our lights:

```
$ huectl -O true 192.168.1.72           # turns all lights on
$ huectl -O false 192.168.1.72 TV Door  # turns some lights off
$ huectl -O false 192.168.1.72 2 3      # same as previous command 
$ huectl -O true 192.168.1.72 TV Door   # turn back on the last two
```

Let's turn all the lights a deep rich red color:

```
$ huectl -H 0 -S 255 -B 255 192.168.1.72  # turns all lights red
```

The `-H` or `--hue` adjusts the hue of the bulb color. This can be a
value between 0 and 65535, where 0 is red, 25500 is green, and 46920
is blue. In this case, `0` sets the hue to red. The `-S` or `--sat`
adjusts the saturation of the color. This can be a value between 0 and
255, where 0 is less saturated (white) and 255 is fully saturated
(colored). Finally, the `-B` or `--bri` controls how bright the bulb
should illuminate. This can be a value between 0 and 255, where 0
represents the least amount of illumination (note: this is not the
same as being powered off) and 255 is the maximum brightness.

Here are a few other fun things that we can do with our lights:

```
$ huectl -A select 192.168.1.72     # flash all lights once
$ huectl -A lselect 192.168.1.72    # flash all lights for 30 secs
$ huectl -E colorloop 192.168.1.72  # continously loop colors
$ huectl -T 0 -B 255 192.168.1.72   # raise brightness immediately
$ huectl -T 10 -B 0 192.168.1.72    # drop brightness over 1 sec
$ huectl -T 100 -B 255 192.168.1.72 # raise brightness over 10 secs
```

In addition to setting parameters, you can also inspect the current
settings of the lights. If you do not use a parameter that sets a
parameter, `huectl` will return the state of the specified lights:

```
$ huectl 192.168.1.72 Office
{
  Office = {
    swversion = "65003148",
    pointsymbol = {
      ["4"] = "none",
      ["8"] = "none",
      ["1"] = "none",
      ["5"] = "none",
      ["2"] = "none",
      ["6"] = "none",
      ["7"] = "none",
      ["3"] = "none"
    },
    state = {
      ct = 299,
      reachable = true,
      alert = "none",
      on = false,
      bri = 10,
      colormode = "hs",
      hue = 25109,
      sat = 254,
      effect = "none",
      xy = {
        0.4141,
        0.5142
      }
    },
    type = "Extended color light",
    modelid = "LCT001",
    name = "Office"
  }
}
```

There will be times when you are only interested in a single parameter
for one or more lights. Rather than parse the above output, you can
specify which attribute you want using a dotted notation. For example,
you'll see most of the parameters that we've been setting are part of
the `state` section, so if we want to find the `hue` of a light, we
would use the `-g` or `--get` option and specify `state.hue`. Let's
see what the hue of my office and tv lights are currently set to:

```
$ huectl -g state.hue 192.168.1.72 Office TV
{
  Office = 24559,
  TV = 47986
}
```

Maybe you only want to see the state section of a light, you could
pass `state` as the value for the `-g` option, which will return only
that section of the light's parameters:

```
$ huectl -g state 192.168.1.72 Office
{  
  Office = {
    ct = 299,
    reachable = true,
    alert = "none",
    on = true,
    bri = 54,
    colormode = "hs",
    hue = 30373,
    sat = 158,
    effect = "none",
    xy = {
      0.4141,
      0.5142
    }
  }
}
```

If you don't specify any lights when getting parameters, your
query will return the parameters of a special group that represents
all of the lights. The group parameters do not contain the state of
the lights, but rather the last command that was sent to them (anytime
you set a parameter without specifying specific lights). For example:

```
$ huectl 192.168.1.72
{
  {
    lights = {
      "1",
      "2",
      "3",
      "4"
    },
    action = {
      colormode = "ct",
      ct = 500,
      effect = "none",
      xy = {
        0.2293,
        0.1184
      },
      hue = 47986,
      on = false,
      sat = 203,
      bri = 146
    },
    name = "Lightset 0"
  }
}
```

Finally, when in doubt, the `-h` option will provide you with a handy
reference: 

```
$ huectl -h
Utility to control Philips Hue lights
  -l,--list                             Lights to manipulate
  -d,--discover                         Discover local bridges
  -r,--register                         Register username at bridge
  -u,--username   (default huectladmin) Authenticate using this username
  -g,--get        (optional string)     Get an attribute (state.on, state.bri)

  -O,--on  (optional true|false)        Turn lights on or off
  -A,--alert  (optional select|lselect) Cycle the light brightness
  -E,--effect (optional none|colorloop) Set an effect
  -T,--transitiontime (optional number) Set transition time (x100ms)

  -B,--bri (optional 0..255)     Set brightness (0 low, 255 high)
  -H,--hue (optional 0..65535)   Set hue (0 red, 25500 green, 46920 blue)
  -S,--sat (optional 0..255)     Set saturation (0 white, 255 colored)
  -C,--ct  (optional 153..500)   Set color temp (153 cooler, 500 warmer)

  <bridge>        (optional string)     IP address of a Philips bridge
  <lights...>     (optional string)     List of lights (id or name)
```


### Command Line Utility: huebwmon

This utility monitors the bandwidth of an interface adjusting the
color of one or more lights based on the utilization allowing you to
visually gauge usage of your network. Like the prior tool, you'll need
to make sure you have a few Lua libraries installed: penlight,
lua2json, and luasocket:

```
$ sudo luarocks install penlight
$ sudo luarocks install lua2json
$ sudo luarocks install luasocket
```

With the necessary dependencies out of the way, let's take a look at
the help:

```
$ huebwmon -h
Change color of Hue lights based on bandwidth usage
  -v,--verbose    Print computed kbps to stdout
  -i,--interface  (default eth0) Interface to monitor
  -n,--interval   (default 3) Seconds between measurements
  -u,--username   (default huectladmin) Authenticate using this username
  -L,--low        (default 25) Low water mark in kbps (green)
  -H,--high       (default 500) High water mark in kbps (red)
  <bridge>        (string) IP address of a Philips bridge
  <lights...>     (optional string) List of lights (id or name)
```

Many of the parameters have defaults so it's relatively easy to get
up and running:

```
$ huebwmon 192.168.1.72 Office
```

This will monitor the utilization of the `eth0` interface, taking
samples every three seconds, and updating the color of the light
called Office. If utilization is less than 25Kbps, the light will
remain green. If the utilization is larger than 500Kbps, the light
will remain red. If utilization is between these two values, the color
will be a gradation between green and red depending on the value.

### API Documentation

The `hue` Lua library is a thin wrapper around the official Philips
REST API. Following the example from the command line utility, we can
discover bridges on our local network with:

```
require 'hue'

for _,ip in ipairs(hue.discover()) do
    print(ip)
end
```

Once we have the IP address of our bridge, we now need to obtain a
registered username. Before this call is executed, you MUST press the
link button on the bridge. You'll then have 30 seconds to initiate
this request.

```
hue.register('huectladmin', 'Hue Lua CLI Tool')
```

With both the bridge IP address and a registered username, we can 
now instantiate an instance of our Bridge class:

```
local b = hue.Bridge:new(bridge_ip, username)
```

Now we are ready to rock and roll. If we want to find all the lights
that have been associated with the bridge:

```
for light_id,light_name in b:lights() do
    print(light_id, light_name)
end
```

To get or set the state of our lights, we will use the `get_state`
and `set_state` methods respectively. The first argument to both
methods is a list of lights that we wish to interact with. This list
of lights can be specified using either the light identifier or the
light name. If lights is an empty table, then all lights will be
targeted. Let's turn all of our lights on and change them to a deep,
rich, red color:

```
local pretty = require 'pl.pretty'  -- used to pretty print the output
local errors = b:set_state({}, {on=true, hue=0, sat=255, bri=255})
if errors then
  pretty.dump(errors)
end

<standard output>
{
  Office = {
    "parameter, sat, is not modifiable. Device is set to off.",
    "parameter, bri, is not modifiable. Device is set to off."
  },
  TV = {
    "parameter, sat, is not modifiable. Device is set to off.",
    "parameter, bri, is not modifiable. Device is set to off."
  }
}
```

The return value is nil upon success. If it is non-nil, it will be a
table containing the errors encountered when setting the state. The
table is indexed by the light and the value will be a list of one or
more error messages.

If we want to obtain the current state of a light, we can do the
following:

```
local pretty = require 'pl.pretty'  -- used to pretty print the output
local results = b:get_state({'TV','Door'}, 'state.bri')
pretty.dump(results)

<standard output>
{ TV = 255, Door = 255 }
```
