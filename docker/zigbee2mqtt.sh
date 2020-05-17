#!/usr/bin/env bash
[ -z "$DEBUG" ] || set -x
set -eo pipefail
shopt -s nullglob

DEBUG=${DEBUG:-info}
CONFIGDIR="${CONFIGDIR:-/config}"
CONFIGFILE="${CONFIGFILE:-$CONFIGDIR/configuration.yaml}"
SECRETS="${SECRETS:-$CONFIGDIR/secret.yaml}"

# If command starts with an option, prepend npm
if [ "${1:0:1}" = '-' ]
then
    set -- npm start "$@"
fi

# Usage: file_env VAR [DEFAULT]
#    ie: file_env 'XYZ_DB_PASSWORD' 'example'
# (will allow for "$XYZ_DB_PASSWORD.txt" to fill in the value of
#  "$XYZ_DB_PASSWORD" from a file, especially for Docker's secrets feature)
file_env() {
    local var="${1}"
    local def="${2:-}"

    local fvar="${CONFIGDIR}/${var}.txt"
    local val="${def}"

    if [ -n "${!var:-}" ] && [ -r "${fvar}" ]
    then
        echo "* Warning: both ${var} and ${fvar} are set, file '${var}' takes priority"
    fi
    if [ -r "${fvar}" ]
    then
        val=$(< "${fvar}")
    elif [ -n "${!var:-}" ]
    then
        val="${!var}"
    fi
    export "${var}"="${val}"
}


generate_network_key() {
    # The network encryption key size is 128-bit which is essentially 16 decimal
    # values between 0 and 255 or 16 hexadecimal values between 0x00and 0xFF.
    local key=()
    for i in {1..16}
    do
        key+=("$(($RANDOM % 256))")
    done
    echo "[ $(IFS=, ; echo "${key[*]}") ]"
}


# ZigBee network key changing requires repairing of all devices
file_env 'NETWORK_KEY' "$(generate_network_key)"
# ZigBee channel, changing requires re-pairing of all devices.
# (Note: use a ZLL channel: 11, 15, 20, or 25 to avoid interferences with WIFI networks)
file_env 'CHANNEL' "11"

if [ ! -s "${SECRETS}" ]
then
    echo "${NETWORK_KEY}" > "${CONFIGDIR}/NETWORK_KEY.txt"
    echo "${CHANNEL}" > "${CONFIGDIR}/CHANNEL.txt"
fi

# Environment variables
DEVICE="${DEVICE:-/dev/ttyACM0}"
PERMIT_JOIN="${PERMIT_JOIN:-true}"
LOG_LEVEL="${LOG_LEVEL:-$DEBUG}"
MQTT_SERVER="${MQTT_SERVER:-mqtt://localhost}"
MQTT_CLIENT_ID="${MQTT_CLIENT_ID:-ZIGBEE2MQTT}"
MQTT_USER="${MQTT_USER:-}"
MQTT_PASS="${MQTT_PASS:-}"
MQTT_BASE_TOPIC="${MQTT_BASE_TOPIC:-zigbee2mqtt}"
MQTT_PROTO_VERSION="${MQTT_PROTO_VERSION:-4}"

# secrets
cat <<- EOF > "${SECRETS}"
user: ${MQTT_USER}
password: ${MQTT_PASS}
network_key: ${NETWORK_KEY}
EOF

# Make sure those files are there
touch "${CONFIGDIR}/devices.yaml"
touch "${CONFIGDIR}/groups.yaml"

# if configfile is empty, generate one
if [ ! -s "${CONFIGFILE}" ]
then
    echo "* Using env variables to GENERATE NEW configuration ..."
	cat <<- EOF > "${CONFIGFILE}"
	# Optional: advanced settings
	advanced:
	  # Optional: ZigBee pan ID (default: shown below)
	  pan_id: 0x1a62
	  # Optional: Zigbee extended pan ID (default: shown below)
	  ext_pan_id: [0xDD, 0xDD, 0xDD, 0xDD, 0xDD, 0xDD, 0xDD, 0xDD]
	  # Optional: ZigBee channel, changing requires re-pairing of all devices.
	  # (Note: use a ZLL channel: 11, 15, 20, or 25 to avoid Problems)
	  # (default: 11)
	  channel: ${CHANNEL}
	  # Optional: state caching, MQTT message payload will contain all attributes, not only changed ones.
	  # Has to be true when integrating via Home Assistant (default: true)
	  cache_state: true
	  # Optional: Logging level, options: debug, info, warn, error (default: info)
	  log_level: ${LOG_LEVEL}
	  # Optional: Output location of the log (default: shown below), leave empty to supress logging (log_output: [])
	  log_output:
	    - console
	  # Optional: Baudrate for serial port (default: shown below)
	  baudrate: 115200
	  # Optional: RTS / CTS Hardware Flow Control for serial port (default: true)
	  rtscts: true
	  # Optional: soft reset ZNP after timeout (in seconds); 0 is disabled (default: 0)
	  soft_reset_timeout: 0
	  # Optional: network encryption key, will improve security (Note: changing requires repairing of all devices) (default: shown below)
	  network_key: '!secret network_key'
	  # Optional: Add a last_seen attribute to MQTT messages, contains date/time of last Zigbee message
	  # possible values are: disable (default), ISO_8601, ISO_8601_local, epoch (default: disable)
	  last_seen: 'disable'
	  # Optional: Add an elapsed attribute to MQTT messages, contains milliseconds since the previous msg (default: false)
	  elapsed: false
	  # Optional: Availability timeout in seconds, disabled by default (0).
	  # When enabled, devices will be checked if they are still online.
	  # Only AC powered routers are checked for availability. (default: 0)
	  availability_timeout: 0
	  report: true
	  # Optional: Home Assistant discovery topic (default: shown below)
	  homeassistant_discovery_topic: 'homeassistant'
	  # Optional: Home Assistant status topic (default: shown below)
	  homeassistant_status_topic: 'hass/status'
	  # Optional: Home Assistant legacy triggers (default: shown below), when enabled:
	  # - Zigbee2mqt will send an empty 'action' or 'click' after one has been send
	  # - A 'sensor_action' and 'sensor_click' will be discoverd
	  homeassistant_legacy_triggers: false
	  # Optional: log timestamp format (default: shown below)
	  timestamp_format: 'YYYY-MM-DD HH:mm:ss'
	# Optional: experimental options
	experimental:
	  # Optional: MQTT output type: json, attribute or attribute_and_json (default: shown below)
	  # Examples when 'state' of a device is published
	  # json: topic: 'zigbee2mqtt/my_bulb' payload '{"state": "ON"}'
	  # attribute: topic 'zigbee2mqtt/my_bulb/state' payload 'ON"
	  # attribute_and_json: both json and attribute (see above)
	  output: 'json'
	# Serial settings
	serial:
	  # Optional: disable LED of the adapter if supported (default: false)
	  disable_led: false
	  # Location of CC2531 USB sniffer
	  port: ${DEVICE}
	
	# Home Assistant integration (MQTT discovery)
	homeassistant: true
	# allow new devices to join
	permit_join: ${PERMIT_JOIN}
	
	# Devices and groups are in separated files
	devices: devices.yaml
	groups: groups.yaml
	
	# MQTT settings
	mqtt:
	  client_id: ${MQTT_CLIENT_ID}
	  # Optional: disable self-signed SSL certificates (default: false)
	  reject_unauthorized: true
	  # Optional: Include device information to mqtt messages (default: false)
	  include_device_information: true
	  # Optional: MQTT keepalive in seconds (default: 60)
	  keepalive: 60
	  # Optional: MQTT protocol version (default: 4), set this to 5 if you
	  # use the 'retention' device specific configuration
	  version: ${MQTT_PROTO_VERSION}
	  # MQTT base topic for zigbee2mqtt MQTT messages
	  base_topic: ${MQTT_BASE_TOPIC}
	  # MQTT server URL
	  server: ${MQTT_SERVER}
	EOF
else
    echo "* Using env variables to UPDATE configuration ..."
    yq w -i "${CONFIGFILE}" advanced.channel ${CHANNEL}
    yq w -i "${CONFIGFILE}" advanced.log_level ${LOG_LEVEL}
    yq w -i "${CONFIGFILE}" serial.port ${DEVICE}
    yq w -i "${CONFIGFILE}" permit_join ${PERMIT_JOIN}
    yq w -i "${CONFIGFILE}" mqtt.client_id ${MQTT_CLIENT_ID}
    yq w -i "${CONFIGFILE}" mqtt.version ${MQTT_PROTO_VERSION}
    yq w -i "${CONFIGFILE}" mqtt.base_topic ${MQTT_BASE_TOPIC}
    yq w -i "${CONFIGFILE}" mqtt.server ${MQTT_SERVER}
fi
if [ "${MQTT_USER}" ]
then
    yq w -i "${CONFIGFILE}" mqtt.user '!secret user'
    yq w -i "${CONFIGFILE}" mqtt.password '!secret password'
else
    yq d -i "${CONFIGFILE}" mqtt.user
    yq d -i "${CONFIGFILE}" mqtt.password
fi

exec "$@"

