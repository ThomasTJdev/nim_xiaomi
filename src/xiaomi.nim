import asyncdispatch
import json
import net
import multicast
import nimcrypto
import os
import osproc
import strutils


# Multicast parameters
const xiaomiMulticast = "224.0.0.50"
const xiaomiPort = Port(9898)
const xiaomiMsgLen = 1024


# Var's used in socket
var xiaomiGatewayPassword* = "" # This is required for writing
var xiaomiGatewaySid* = ""
var xiaomiGatewayToken* = ""
var xiaomiGatewaySecret* = ""
var xdata: string = ""
var xaddress: string = ""
var xport: Port
var xiaomiSocket: Socket


template jn(json: JsonNode, data: string): string =
  ## Avoid error in parsing JSON
  try: json[data].getStr() except: ""


proc xiaomiSecretUpdate*(password = xiaomiGatewayPassword, token = xiaomiGatewayToken) =
  ## Update encrypt the secret for writing

  if password.len() == 0 or token.len() == 0:
    xiaomiGatewayPassword = "" 

  var secret = ""
  var key = nimcrypto.fromHex(toHex(password))
  var iv = nimcrypto.fromHex("17996d093d28ddb3ba695a2e6f58562e")
  var ctx1: CBC[aes128]
  ctx1.init(key, iv)
  var plain = nimcrypto.fromHex(toHex(token))
  let length = len(plain)
  var ecrypt = newSeq[uint8](length)
  ctx1.encrypt(addr plain[0], addr ecrypt[0], uint(length))
  secret = nimcrypto.toHex(ecrypt)
  burnMem(ecrypt)
  ctx1.clear()

  xiaomiGatewaySecret = secret


proc xiaomiTokenRefresh*() =
  ## Wait for updated Gateway token.
  ## This does also populate the gateway sid.

  while xiaomiSocket.recvFrom(xdata, xiaomiMsgLen, xaddress, xport) > 0:
    let js = parseJson(xdata)
    if jn(js, "cmd") == "heartbeat" and jn(js, "token") != "":
      xiaomiGatewaySid = jn(js, "sid")
      xiaomiGatewayToken = jn(js, "token")
      break


proc xiaomiSendWriteCmd*(sid, message: string) =
  ## Send a write command to the
  ## specified "sid" with a "message".

  xiaomiSecretUpdate()
  discard xiaomiSocket.sendTo(xiaomiMulticast, xiaomiPort, "{\"cmd\": \"write\", \"sid\": \"" & sid & "\", \"data\": {\"key\": \"" & xiaomiGatewaySecret & "\", " & message & "} }")


proc xiaomiSendReadCmd*(deviceSid: string) =
  ## Tell the device to reply with it's status.
  ## This proc does not read the reply, only
  ## ask the device for sending a message with
  ## it's status and the cmd = read_ack.

  let command = "{\"cmd\":\"read\", \"sid\":\"" & deviceSid & "\"}"
  discard xiaomiSocket.sendTo(xiaomiMulticast, xiaomiPort, command)


proc xiaomiSendCmd*(message: string) =
  ## Send a custom message

  discard xiaomiSocket.sendTo(xiaomiMulticast, xiaomiPort, message)


proc xiaomiReadMessage*(): string =
  ## Read a single Xiaomi message
  ## and return it.

  while xiaomiSocket.recvFrom(xdata, xiaomiMsgLen, xaddress, xport) > 0:
    when defined(dev):
      echo "xiaomiReadMessage(): Message = " & xdata
      
    return xdata


proc xiaomiReadCustom*(cmd = "", model = "", sid = ""): string =
  ## Tell the device to reply with status.
  ## and return the reply if the custom
  ## parameters are fulfilled.
  ##
  ## It is optional to specify the parameters.
  ##
  ## Example:
  ##   cmd => heartbeat
  ##   model => gateway

  while xiaomiSocket.recvFrom(xdata, xiaomiMsgLen, xaddress, xport) > 0:
    if cmd != "":
      if jn(parseJson(xdata), "cmd") != cmd:
        continue

    if model != "":
      if jn(parseJson(xdata), "model") != model:
        continue

    if sid != "":
      if jn(parseJson(xdata), "sid") != sid:
        continue

    when defined(dev):
      echo "xiaomiReadDevice(): Message = " & xdata
    
    return xdata


proc xiaomiReadDevice*(deviceSid: string): string =
  ## Tell the device to reply with it's status
  ## and return the reply.

  let command = "{\"cmd\":\"read\", \"sid\":\"" & deviceSid & "\"}"
  discard xiaomiSocket.sendTo(xiaomiMulticast, xiaomiPort, command)
  while xiaomiSocket.recvFrom(xdata, xiaomiMsgLen, xaddress, xport) > 0:
    if jn(parseJson(xdata), "cmd") == "read_ack" and jn(parseJson(xdata), "sid") == deviceSid:
      
      when defined(dev):
        echo "xiaomiReadDevice(): SID = " & deviceSid & ", Message = " & xdata
      
      return xdata


proc xiaomiReadAck*(deviceSid = ""): string =
  ## Return next message with
  ## cmd = "read_ack". This is useful
  ## after telling a device to reply
  ## with it's status

  while xiaomiSocket.recvFrom(xdata, xiaomiMsgLen, xaddress, xport) > 0:
    if jn(parseJson(xdata), "cmd") == "read_ack":
      if deviceSid != "" and jn(parseJson(xdata), "sid") != deviceSid:
          continue

      when defined(dev):
        echo "xiaomiReadAck(): Message = " & xdata
      
      return xdata


proc xiaomiReportAck*(deviceSid = ""): string =
  ## Return next message with
  ## cmd = "report". This is useful
  ## if you are waiting for a sensor
  ## to reply with a change

  while xiaomiSocket.recvFrom(xdata, xiaomiMsgLen, xaddress, xport) > 0:
    if jn(parseJson(xdata), "cmd") == "report":
      if deviceSid != "" and jn(parseJson(xdata), "sid") != deviceSid:
          continue

      when defined(dev):
        echo "xiaomiReportAck(): Message = " & xdata
      
      return xdata


proc xiaomiGatewayGetSid*(): string =
  ## Get the gateway's sid

  let heartbeat = xiaomiReadCustom("heartbeat", "gateway")
  return parseJson(heartbeat)["sid"].getStr()


proc xiaomiGatewayGetToken*(): string =
  ## Get the gateway's token

  let heartbeat = xiaomiReadCustom("heartbeat", "gateway")
  return parseJson(heartbeat)["token"].getStr()


proc xiaomiDiscover*(): string =
  ## Discover xiaomi devices

  let command = "{\"cmd\":\"get_id_list\"}"
  discard xiaomiSocket.sendTo(xiaomiMulticast, xiaomiPort, command)
  var sids = ""
  while xiaomiSocket.recvFrom(xdata, xiaomiMsgLen, xaddress, xport) > 0:
    if jn(parseJson(xdata), "cmd") != "get_id_list_ack":
      continue

    sids = jn(parseJson(xdata), "data")

    when defined(dev):
      echo "xiaomiDiscover(): SIDS = " & sids

    break
  
  var xiaomi_device = ""
  for sid in split(multiReplace(sids, [("[", ""), ("]", ""), ("\"", "")]), ","):
    when defined(dev):
      echo "xiaomiDiscover(): READ SID = " & sid

    let command = "{\"cmd\":\"read\", \"sid\":\"" & sid & "\"}"
    discard xiaomiSocket.sendTo(xiaomiMulticast, xiaomiPort, command)
    while xiaomiSocket.recvFrom(xdata, xiaomiMsgLen, xaddress, xport) > 0:
      if jn(parseJson(xdata), "cmd") == "read" or xdata.len() == 0:
        continue
      
      let json = parseJson(xdata)

      let data = jn(json, "data")
      
      if "error" in data:
        when defined(dev):
          echo "xiaomiDiscover(): SID = " & sid & ", Error: Not a device"
          echo data
        continue
      
      when defined(dev):
        echo "xiaomiDiscover(): SID = " & sid & ", Success = Device found, Message = " & xdata

      if xiaomi_device != "":
        xiaomi_device.add(",")

      xiaomi_device.add("{\"model\":\"" & jn(json, "model") & "\",")
      xiaomi_device.add("\"sid\":\"" & jn(json, "sid") & "\",")
      xiaomi_device.add("\"short_id\":\"" & jn(json, "short_id") & "\",")
      xiaomi_device.add("\"data\":" & jn(json, "data") & "}")

      break
  
  when defined(dev):
    echo "xiaomiDiscover(): \n" & pretty(parseJson("{\"xiaomi_devices\":[" & xiaomi_device & "]}"))

  return "{\"xiaomi_devices\":[" & xiaomi_device & "]}"  
      

proc xiaomiUpdateToken*(message: string): string =
  ## Updates the gateway token if
  ## possible and returns the data

  let js = parseJson(message)
  if js.hasKey("cmd"):
    if jn(js, "cmd") == "heartbeat" and jn(js, "token") != "":
      xiaomiGatewaySid = jn(js, "sid")
      xiaomiGatewayToken = jn(js, "token")

  return message


proc xiaomiListenForever*() =
  ## Listen for Xiaomi mesages

  while true:
    if xiaomiSocket.recvFrom(xdata, xiaomiMsgLen, xaddress, xport) > 0:
      echo xdata

  
proc xiaomiDisconnect*() =
  ## Close connection to multicast

  discard xiaomiSocket.leaveGroup(xiaomiMulticast) == true


proc xiaomiConnect*() =
  ## Initialize socket
  
  xiaomiSocket = newSocket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)
  xiaomiSocket.setSockOpt(OptReuseAddr, true)
  xiaomiSocket.bindAddr(xiaomiPort)

  if not xiaomiSocket.joinGroup(xiaomiMulticast):
    echo "could not join multicast group"
    quit()

  xiaomiSocket.enableBroadcast true