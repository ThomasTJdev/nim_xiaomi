*This README was generated with [Nim to Markdown](https://github.com/ThomasTJdev/nimtomd)*

# XIAOMI

Library for working with Xiaomi IOT devices.

## Requirements

- nim >= 0.19.0
- multicast >= 0.1.1
- nimcrypto >= 0.3.2

## Devices
Xiaomi IOT devices are supported. The following devices has been thoroughly tested:

  - [Gateway](https://www.lightinthebox.com/en/p/xiao-mi-multi-function-gateway-16-million-color-night-light-remote-control-connect-other-intelligent-devices_p5362296.html?prm=1.18.104.0)
  - [Door/window sensor](https://www.lightinthebox.com/en/p/xiao-mi-door-and-window-sensor-millet-intelligent-home-suite-household-door-and-window-alarm-used-with-multi-function-gateway_p5362299.html?prm=1.18.104.0)
  - [PIR sensor](https://www.lightinthebox.com/en/p/xaomi-aqara-human-body-sensor-infrared-detector-platform-infrared-detectorforhome_p6599215.html?prm=1.18.104.0)
  - [Temperature & Humidity sensor](https://www.lightinthebox.com/en/p/original-xiaomi-temperature-and-humidity-sensor-real-time-monitoring-of-temperature-and-humidity-changes_p5376891.html?prm=1.18.104.0)

## Working with Xiaomi
You can interact with the Xiaomi devices in 3 ways:
1) **Read** - Asking for a status, e.g. is the door open (door sensor)
2) **Report** - Awaiting an action, e.g. when the door opens, it sends a notification (door sensor)
3) **Write** - Send a message to the device (only some devices accepted this), e.g. play a sound (gateway)

All you Xiaomi devices are connected to a gateway. It is through this gateway, we are communicating with each of the devices. Each devices is identified with a SID.

# Examples (basic)

## Discover devices
But before we get started, you need to acquire your devices SID.

**Get the gateways SID**
```nim
 import xiaomi
 xiaomiConnect()
 echo xiaomiGatewayGetSid()
```



**Get the devices SID**
```nim
 import xiaomi
 xiaomiConnect()
 echo xiaomiDiscover()
```



## Read
There are numerous ways to read. Some proc's just read the next message, some waits for a specific device, etc.

**Read the next message sent**
```nim
 import xiaomi
 xiaomiConnect()
 echo xiaomiReadMessage()
```



**Request a device status and read the reply**
```nim
 import xiaomi
 xiaomiConnect()
 echo xiaomiReadDevice("device-SID")
```



**Read the next message from custom-x**
This will await that the cmd = "heartbeat" and the model = "gateway".
```nim
 import xiaomi
 xiaomiConnect()
 echo xiaomiReadCustom("heartbeat", "gateway")
```



**Read messages forever**
```nim
 import xiaomi
 xiaomiConnect()
 xiaomiListenForever()
```



## Report

For PIR sensors you will receive a report, when there's motion or there hasn't been motion for 300 seconds.

For magnet sensors you will receive a report when they are connected (`close`) and disconnected (`open`).

**Read next report**
```nim
 import xiaomi
 xiaomiConnect()
 echo xiaomiReportAck()
```



**Read next report for device**
```nim
 import xiaomi
 xiaomiConnect()
 echo xiaomiReadReport("device-SID")
```



# Write to a device
To write to a device, we need to exchange an encrypted key with the gateway based on an ever-changing token. We are utilizing nimcrypto AES CBC 128 to do this.


## Gateway password
But before we can generate the key, you need to gather you gateway password. Follow this guide [Domotics](https://www.domoticz.com/wiki/Xiaomi_Gateway_(Aqara)#Adding_the_Xiaomi_Gateway_to_Domoticz) or the bullets below. Remember to write the key down.

1) Install the Xiaomi app
2) Set the region to Mainland China under Settings->Locale
3) You can set the language to English, even though the region is China
4) Sign in/Make an account
5) Select your Gateway in the app
6) Tap the 3 dots in top right corner
7) Click About
8) Tap on the version repeatedly until a new menu appear
9) Click on Wireless communication protocol
10) Enable the this and write down you password and press Ok

## Setting the password
If you need to write to a device, insert your password in the global variable at the top of your code:

```nim
 xiaomiGatewayPassword = "secretPassword"
```



## Getting the encrypted key
The gateways token is changing all the time. You therefore need to the generate the encrypted key before each writing.

This is done with:
```nim
 xiaomiTokenRefresh()
 xiaomiSecretUpdate()
```



**OR**
```nim
 xiaomiTokenRefresh(true)
```



**OR while writing**
```nim
 xiaomiWrite("device-SID", "message", true)
```



## Gateway writing options
There are 2 main elements you can write to the gateway - the light and sound.

**Light writing**

```nim
 import xiaomi
 xiaomiGatewayPassword = "secretPassword"
 xiaomiTokenRefresh()
 xiaomiWrite(xiaomiGatewaySid, "\"rgb\": 4294914304")
```



**Light options**

To assign a RGB color, you have to use the Android() color format.

You can convert HEX to Android() at this [website](https://convertingcolors.com/android-color-4294914304.html).

- Red = `4294914304`
- Green = `4283359807`
- Purple = `4283637131`
- Yellow = `4292211292`
- Blue = `4283327469`
- Off = `0`


**Sound writing**

```nim
 import xiaomi
 xiaomiGatewayPassword = "secretPassword"
 xiaomiTokenRefresh()
 xiaomiWrite(xiaomiGatewaySid, "\"mid\": 7, \"vol\": 4")
```



**Sound options**

The volume is in percentage, whereas 10 = 100%.

The following sounds are available:

Alarms:
- 0 - Police car 1
- 1 - Police car 2
- 2 - Accident
- 3 - Countdown
- 4 - Ghost
- 5 - Sniper rifle
- 6 - Battle
- 7 - Air raid
- 8 - Bark

Doorbells
- 10 - Doorbell
- 11 - Knock at a door
- 12 - Amuse
- 13 - Alarm clock

Alarm clock
- 20 - MiMix
- 21 - Enthusiastic
- 22 - GuitarClassic
- 23 - IceWorldPiano
- 24 - LeisureTime
- 25 - ChildHood
- 26 - MorningStream
- 27 - MusicBox
- 28 - Orange
- 29 - Thinker
# Types
## Procs
### proc xiaomiSecretUpdate*
```nim
proc xiaomiSecretUpdate*(password = xiaomiGatewayPassword, token = xiaomiGatewayToken) =
```
Update encrypt the secret for writing
### proc xiaomiTokenRefresh*
```nim
proc xiaomiTokenRefresh*(updateKey = false) =
```
Wait for updated Gateway token.
This does also populate the gateway sid.
### proc xiaomiWrite*
```nim
proc xiaomiWrite*(sid, message: string, updateKey = false) =
```
Send a write command to the
specified "sid" with a "message".
### proc xiaomiSendRead*
```nim
proc xiaomiSendRead*(deviceSid: string) =
```
Tell the device to reply with it's status.
This proc does not read the reply, only
ask the device for sending a message with
it's status and the cmd = read_ack.
### proc xiaomiSend*
```nim
proc xiaomiSend*(message: string) =
```
Send a custom message
### proc xiaomiReadMessage*
```nim
proc xiaomiReadMessage*(): string =
```
Read a single Xiaomi message
and return it.
### proc xiaomiReadCustom*
```nim
proc xiaomiReadCustom*(cmd = "", model = "", sid = ""): string =
```
Tell the device to reply with status.
and return the reply if the custom
parameters are fulfilled.
It is optional to specify the parameters.
Example:
  cmd => heartbeat
  model => gateway
### proc xiaomiReadDevice*
```nim
proc xiaomiReadDevice*(deviceSid: string): string =
```
Tell the device to reply with it's status
and return the reply.
### proc xiaomiReadAck*
```nim
proc xiaomiReadAck*(deviceSid = ""): string =
```
Return next message with
cmd = "read_ack". This is useful
after telling a device to reply
with it's status
### proc xiaomiReadReport*
```nim
proc xiaomiReadReport*(deviceSid = ""): string =
```
Return next message with
cmd = "report". This is useful
if you are waiting for a sensor
to reply with a change
### proc xiaomiGatewayGetSid*
```nim
proc xiaomiGatewayGetSid*(): string =
```
Get the gateway's sid
### proc xiaomiGatewayGetToken*
```nim
proc xiaomiGatewayGetToken*(): string =
```
Get the gateway's token
### proc xiaomiDiscover*
```nim
proc xiaomiDiscover*(): string =
```
Discover xiaomi devices
### proc xiaomiUpdateToken*
```nim
proc xiaomiUpdateToken*(message: string): string =
```
Updates the gateway token if
possible and returns the data
### proc xiaomiListenForever*
```nim
proc xiaomiListenForever*() =
```
Listen for Xiaomi mesages
### proc xiaomiDisconnect*
```nim
proc xiaomiDisconnect*() =
```
Close connection to multicast
### proc xiaomiConnect*
```nim
proc xiaomiConnect*() =
```
Initialize socket
