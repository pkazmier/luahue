luahue
======

Lua API and command line utility to control your Philips Hue lightbulbs.

For those that do not know abouth the Philips Hue light system, it consists of LED 
bulbs that are networked together allowing them to be controlled remotely via an IP
network. One can control settings such as hue, brightness, and saturation. The bulbs
are not wi-fi enabled, but use the zigbee protocol to communicate with each other 
and the Philips bridge. The bridge, included in the 3 bulb starter pack, connects
to your home router via Ethernet making them accessible from your home network. All
communication to/from the IP network and the bulbs is via the bridge.

### Command Line Utility

Let's explore what the Hue bulbs have to offer using `huectl` - a command line
utility written in Lua that utilizes the `hue.lua` library, which is a loose
wrapper around the REST API provided by Philips. So, with that said, let's get
started! First, we need to discover the IP addresses of the Hue bridges
connected to our local network. We can do so with the `-d` or `--discover` 
option:

```
$ huectl -d
192.168.1.72
```

On this local network, one bridge was discovered. The IP address of the bridge
is `192.168.1.72`. We will need to specify this on the command line in our 
subsequent examples.

Before we can issue commands to our Hue bridge, we must register a username 
with the bridge that will be used for authorization. Usernames must be
a minimum of 10 characters but no more than 40. If you do not specify
a username, the default `huectladmin` will be used instead. Let's try
and register our username:

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
1       Pete
2       TV
3       Door
4       Dining Room
```

Four lights have been associated with our bridge. We will be able to
manipulate one or more of these lights using `huectl`. When specifying
lights on the command line, you can either use the index (number in
the lefthand column) or the more user friendly name provided next to
it. If using the name, you may need to quote it appropriately. If you
don't specify any lights on the command line, then any requests will
be set to all lights. For example, to turn on our lights:

```
$ huectl -O true 192.168.1.72           # turns all lights on
$ huectl -O false 192.168.1.72 TV Door  # turns some lights off
$ huectl -O false 192.168.1.72 2 3      # same as previous command 
$ huectl -O true 192.168.1.72 TV Door   # leave them all on
```

Let's turn all the lights a deep rich red color:

```
$ huectl -H 0 -S 255 -B 255 192.168.1.72  # turns all lights red
```

The `-H` or `--hue` adjusts the hue of the bulb color. This can be a 
value between 0 and 65535, where 0 is red, 25500 is green, and 46920
is blue. In this case, `0` sets the hue to red. The `-S` or `--sat`
adjusts the saturation of the color. This can be a value between 0
and 255, where 0 is less saturated (white) and 255 is fully 
saturated (colored). Finally, the `-B` or `--bri` controls how bright
the bulb should illuminate. This can be a value between 0 and 255,
where 0 represents the least amount of illumination (note: this is
not the same as being powered off) and 255 is the maximum brightness.

More to come later ...

### API Documentation

The `hue` Lua library is a thin wrapper around the official Philips
REST API. Following the example from the command line utility, we
can discover bridges on our local network with:

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
and`set_state` methods respectively. The first argument to both 
methods is a list of lights that we wish to interact with. This 
list of lights can be specified using either the light identifier
or the light name. If lights is an empty table, then all lights
will be targeted. Let's turn all of our lights on and change them
to a deep, rich, red color:

```
b:set_state({}, {on=true, hue=0, sat=255, bri=255})
```

If we want to obtain the current state of a light, we can do the
following:

```
require 'pl.pretty'  -- used to pretty print the output
local results = b:get_state({'TV','Door'}, 'state.bri')
pretty.dump(results)

<standard output>
{ TV = 255, Door = 255 }
```
