# Xiaomi
This Nim package includes proc's for working with Xiaomi devices.

# Requirements
**Nim:**
- Nim >= 0.18.1
- Multicast >= 0.1.1 (nimble install multicast)
- Nimcrypto >= 0.3.2 (nimble install nimcrypto)


# Devices
Xiaomi IOT devices are supported. The following devices has been thoroughly tested:

- [Gateway](https://www.lightinthebox.com/en/p/xiao-mi-multi-function-gateway-16-million-color-night-light-remote-control-connect-other-intelligent-devices_p5362296.html?prm=1.18.104.0)
- [Door/window sensor](https://www.lightinthebox.com/en/p/xiao-mi-door-and-window-sensor-millet-intelligent-home-suite-household-door-and-window-alarm-used-with-multi-function-gateway_p5362299.html?prm=1.18.104.0)
- [PIR sensor](https://www.lightinthebox.com/en/p/xaomi-aqara-human-body-sensor-infrared-detector-platform-infrared-detectorforhome_p6599215.html?prm=1.18.104.0)


# Working with Xiaomi
You can interact with the Xiaomi devices in 3 ways:
1) **Read** - Asking for a status, e.g. is the door open (door sensor)
2) **Report** - Awaiting an action, e.g. when the door opens, it sends a notification (door sensor)
3) **Write** - Send a message to the device (only some devices accepted this), e.g. play a sound (gateway)

All you Xiaomi devices are connected to a gateway. It is through this gateway, we are communicating with each of the devices. Each devices is identified with a SID.


# Discover devices
But before we get started, you need to acquire your devices SID.

## Get the gateways SID
```nim
import xiaomi

xiaomiConnect()
echo xiaomiGatewayGetSid()
```

## Get the devices SID
```nim
import xiaomi

xiaomiConnect()
echo xiaomiDiscover()
```


# Read
There are numerous ways to read. Some proc's just read the next message, some waits for a specific device, etc.

## Read the next message sent
```nim
import xiaomi

xiaomiConnect()
echo xiaomiReadMessage()
```

## Request a device status and read the reply
```nim
import xiaomi

xiaomiConnect()
echo xiaomiReadDevice("device-SID")
```

## Read the next message from custom-x
This will await that the cmd = "heartbeat" and the model = "gateway".
```nim
import xiaomi

xiaomiConnect()
echo xiaomiReadCustom("heartbeat", "gateway")
```

## Read messages forever
```nim
import xiaomi

xiaomiConnect()
xiaomiListenForever()
```


# Report
For PIR sensors you will receive a report, when there's motion or there hasn't been motion for 300 seconds.

For magnet sensors you will receive a report when they are connected (`close`) and disconnected (`open`).

## Read next report
```nim
import xiaomi

xiaomiConnect()
echo xiaomiReportAck()
```

## Read next report for device
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

### Light writing
```nim
import xiaomi

xiaomiGatewayPassword = "secretPassword"
xiaomiTokenRefresh()
xiaomiWrite(xiaomiGatewaySid, "\"rgb\": 4294914304")
```

### Light options
To assign a RGB color, you have to use the Android() color format.

You can convert HEX to Android() at this [website](https://convertingcolors.com/android-color-4294914304.html).

- Red = `4294914304`
- Green = `4283359807`
- Purple = `4283637131`
- Yellow = `4292211292`
- Blue = `4283327469`
- Off = `0`

### Sound writing
```nim
import xiaomi

xiaomiGatewayPassword = "secretPassword"
xiaomiTokenRefresh()
xiaomiWrite(xiaomiGatewaySid, "\"mid\": 7, \"vol\": 4")
```

### Sound options
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



# Example
```nim
import json
import xiaomi


# To be able to write to the gateway,
# you need to find your gateway password.
# Follow this guide: https://github.com/ThomasTJdev/nim_homeassistant/wiki/Xiaomi#gateway-password
xiaomiGatewayPassword = "gbbwsi3apkgd1ls2"


proc connectToXiaomi() =
  ## You neeed to connect as the first thing

  xiaomiConnect()


proc getGatewayInfo() =
  ## Get information on the gateway.
  ## This will return a heartbeat from
  ## the gateway.

  echo xiaomiReadCustom("heartbeat", "gateway")


proc getGatewaySid(): string =
  ## Get the gateway SID

  return xiaomiGatewayGetSid()


proc startSound() =
  ## Play sound number 7 with volume level 4

  # Refresh token does also update the gateway sid
  xiaomiTokenRefresh(true)
  xiaomiWrite(xiaomiGatewaySid, "\"mid\": 7, \"vol\": 4")


proc stopSound() =
  ## Stop sound

  # Refresh token does also update the gateway sid
  xiaomiTokenRefresh(true)
  xiaomiWrite(xiaomiGatewaySid, "\"mid\": 10000")


proc lightRed() =
  ## Set red light on gateway

  # Refresh token does also update the gateway sid
  xiaomiTokenRefresh(true)
  xiaomiWrite(xiaomiGatewaySid, "\"rgb\": 4294914304")


proc lightOff() =
  ## Set red light on gateway

  # Refresh token does also update the gateway sid
  xiaomiTokenRefresh(true)
  xiaomiWrite(xiaomiGatewaySid, "\"rgb\": 0")


proc discoverDevices() =
  ## Auto discover all connected devices

  echo xiaomiDiscover()


proc readNextMessage() =
  ## Read the next message

  echo xiaomiReadMessage()


proc askforDeviceStatus() =
  ## Tell the device to reply with it's status.
  ## This proc does not read the reply, only
  ## ask the device for sending a message with
  ## it's status and the cmd = read_ack

  xiaomiSendRead("device-sid")


proc getDeviceStatus() =
  ## Tell the device to reply with status.
  ## and get the reply.

  echo xiaomiReadDevice("device-sid")


proc sendCustomMessage() =
  ## Get information on the gateway

  xiaomiSend("{\"cmd\": \"whois\"}")


proc listenForever() =
  ## Get all Xiaomi messages

  xiaomiListenForever()
  xiaomiDisconnect()


proc listenForeverAndUpdateToken() =
  ## Get all Xiaomi messages and update token

  while true:
    echo xiaomiUpdateToken(xiaomiReadMessage())

  xiaomiDisconnect()



# Connect
connectToXiaomi()

# Discover devices
discoverDevices()

# Close the connection
xiaomiDisconnect()
```
