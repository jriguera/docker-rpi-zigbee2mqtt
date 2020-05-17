# docker-rpi-zigbee2mqtt

Allows you to use your Zigbee devices without the vendors bridge or gateway.

It bridges events and allows you to control your Zigbee devices via MQTT.
In this way you can integrate your Zigbee devices with whatever smart home
infrastructure you are using. 

Have a look: https://www.zigbee2mqtt.io

### Develop and test builds

Just type:

```
# Create new container image
docker build . -t zigbee2mqtt

# Run the docker image
docker run --privileged  -ti --rm -e TZ=Europe/Amsterdam -v /dev/ttyACM0:/dev/ttyACM0 zigbee2mqtt
```

### Create final release and publish to Docker Hub

```
create-release.sh
```


### Run in production

Given the docker image with name `zigbee2mqtt`:

```
docker run --name zigbee -e TZ=Europe/Amsterdam -e -v $(pwd)/config:/config -v /dev/ttyACM0:/dev/ttyACM0 -d jriguera/zigbee2mqtt
```

Variables, they can be updated at any time re-defining env variables (all except `NETWORK_KEY` and `CHANNEL`).

* `TZ` Timezone, defaults to Europe/Amsterdam.
* `NETWORK_KEY` By default is generated automatically and stored in `secret.yaml` and `NETWORK_KEY.txt` files.
  Changing requires repairing of all devices!!. So is not possible to change it once it was generated via
  env var, you will need to delete the previous files.
* `CHANNEL` By default is 11. Changing requires re-pairing of all devices, it  is stored in `secret.yaml` and
  `NETWORK_KEY.txt` files and the same logic as `NETWORK_KEY` applies here. Note: use a ZLL channel: 11, 15,
   20, or 25 to avoid interferences with WIFI networks.
* `DEVICE` Controller device, by default is `/dev/ttyACM0`.
* `PERMIT_JOIN` true by default to allow joining new devices.
* `LOG_LEVEL` default to `info`.
* `MQTT_SERVER` MQTT server, defaults to `mqtt://localhost`.
* `MQTT_CLIENT_ID` MQTT client ID, default is `ZIGBEE2MQTT`.
* `MQTT_USER` MQTT username auth.
* `MQTT_PASS` MQTT Password.
* `MQTT_BASE_TOPIC` MQTT base topic, default is `zigbee2mqtt`.
* `MQTT_PROTO_VERSION` MQTT protocol version, 4 by default.

Files `devices.yaml` and `groups.yaml` are created automatically.


# Author

Jose Riguera `<jriguera@gmail.com>`
