#!/bin/bash

# HDHRRestart
# HDHomeRun Tuner Restart  
# Based on scripts by [jgsouthard](https://forums.sagetv.com/forums/member.php?u=2072)
# at forums.sagetv.com
#
# If you have an older or flakier [SiliconDust HDHomeRun](https://www.silicondust.com/hdhomerun/)
# tuner, this script will check to see if it is on the network, check to see if it's in
# use, and if it's not in use, initiate a soft reboot. If it is not on the network, the
# script can also power cycle the HDHomeRun using either a WeMo or a smart
# outlet/switch running the [Tasmota firmware](https://tasmota.github.io/docs/).
#
#Set the script to run at a regular interval using crontab -e.
#Shortly before the top of the hour tends to work well.
#
# Before running, install hdhomerun_config by running, from the home directory:
# sudo apt update && sudo apt install -y git build-essential
# git clone https://github.com/Silicondust/libhdhomerun.git && cd libhdhomerun && make
# sudo install -m 755 ~/libhdhomerun/hdhomerun_config /usr/local/bin/
#
#If you are using a WeMo device and are not using the Tasmota firmware, you will need
# to use curl. Otherwise, wget is sufficient for controlling Tasmota devices. Your
# smart outlet will need to be assigned a static IP address by your router for the
# script to find it.
#
#If you are using a Tasmota device, you can dim the status LEDs by going to
# http://192.168.1.200/cm?cmnd=Backlog%20LedPwmMode%201%3BLedPwmOff%2031%3BLedPwmOn%2063 
#(replace 192.168.1.200 with the IP of the device).

# Set HDHomeRun Device IDs
HDHR_ONE="10452937"
HDHR_TWO="13277616"

# Set Smart Outlet IPs
WEMO_ONE_IP="192.168.1.203"
WEMO_TWO_IP=""

# Set to true if using Tasmota firmware
TASMOTA=true

# Path to hdhomerun_config
HDHR_CONFIG=hdhomerun_config  # Assuming it's installed system-wide

# Log file location
LOG_FILE="$(dirname "$0")/RestartTuners.log"
echo "..................................................................." >> "$LOG_FILE"

# Get current date and time
echo "$(date +"%Y-%m-%d %H:%M:%S")" >> "$LOG_FILE"

# Function to send WeMo control commands
# Based on WeMo Control Script by rich@netmagi.com
# Usage: wemo_control IP_ADDRESS ON/OFF/GETSTATE/GETSIGNALSTRENGTH/GETFRIENDLYNAME
wemo_control() {
    local IP=$1
    local COMMAND=$2
    local PORT=0

    for PTEST in 49152 49153 49154 49155; do
        if curl -s -m 3 "$IP:$PTEST" | grep -q "404"; then
            PORT=$PTEST
            break
        fi
    done

    if [[ $PORT -eq 0 ]]; then
        echo "Cannot find a port for WeMo at $IP" >> "$LOG_FILE"
        return 1
    fi

    echo "Using port $PORT for WeMo at $IP" >> "$LOG_FILE"

    case "$COMMAND" in
        ON)
            curl -0 -A '' -X POST -H 'Accept: ' -H 'Content-type: text/xml; charset="utf-8"' \
                -H "SOAPACTION: \"urn:Belkin:service:basicevent:1#SetBinaryState\"" \
                --data '<?xml version="1.0" encoding="utf-8"?><s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"><s:Body><u:SetBinaryState xmlns:u="urn:Belkin:service:basicevent:1"><BinaryState>1</BinaryState></u:SetBinaryState></s:Body></s:Envelope>' \
                -s "http://$IP:$PORT/upnp/control/basicevent1" >> "$LOG_FILE"
            ;;
        OFF)
            curl -0 -A '' -X POST -H 'Accept: ' -H 'Content-type: text/xml; charset="utf-8"' \
                -H "SOAPACTION: \"urn:Belkin:service:basicevent:1#SetBinaryState\"" \
                --data '<?xml version="1.0" encoding="utf-8"?><s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"><s:Body><u:SetBinaryState xmlns:u="urn:Belkin:service:basicevent:1"><BinaryState>0</BinaryState></u:SetBinaryState></s:Body></s:Envelope>' \
                -s "http://$IP:$PORT/upnp/control/basicevent1" >> "$LOG_FILE"
            ;;
        *)
            echo "Invalid WeMo command: $COMMAND" >> "$LOG_FILE"
            return 1
            ;;
    esac
}

# Function to restart HDHomeRun device
restart_hdhr() {
    local device_id=$1
    echo "Restarting HDHomeRun $device_id..." >> "$LOG_FILE"
    "$HDHR_CONFIG" "$device_id" set /sys/restart self >> "$LOG_FILE" 2>&1
}

# Function to power cycle a smart outlet
power_cycle() {
    local ip=$1
    if [[ -z "$ip" ]]; then
        echo "Smart outlet control disabled, skipping power cycle" >> "$LOG_FILE"
        return
    fi

    echo "Power Cycling Smart Outlet at $ip" >> "$LOG_FILE"
    if [[ "$TASMOTA" == true ]]; then
        wget -qO- "http://$ip/cm?cmnd=Power%20off" >> "$LOG_FILE"
        sleep 2
        wget -qO- "http://$ip/cm?cmnd=Power%20on" >> "$LOG_FILE"
    else
        wemo_control "$ip" OFF
        sleep 2
        wemo_control "$ip" ON
    fi
    echo "." >> "$LOG_FILE"
}

# Check each HDHomeRun device
for device in "$HDHR_ONE" "$HDHR_TWO"; do
    WEMO_IP=""
    [[ "$device" == "$HDHR_ONE" ]] && WEMO_IP="$WEMO_ONE_IP"
    [[ "$device" == "$HDHR_TWO" ]] && WEMO_IP="$WEMO_TWO_IP"

    # Check if device is on the network
    HDHR_ON_NETWORK=$("$HDHR_CONFIG" "$device" get /sys/hwmodel 2>&1)
    if [[ "$HDHR_ON_NETWORK" != HDHR* ]]; then
        echo "HDHomeRun $device is not seen on the network ($HDHR_ON_NETWORK)" >> "$LOG_FILE"
        power_cycle "$WEMO_IP"
    else
        echo "Found $HDHR_ON_NETWORK $device on network" >> "$LOG_FILE"
        HDHR_IN_USE=""

        # Check each tuner on the HDHomeRun
        for tuner in {0..5}; do
            TUNER_IN_USE=$("$HDHR_CONFIG" "$device" get "/tuner${tuner}/lockkey" 2>/dev/null)
            [[ "$TUNER_IN_USE" != "none" && "$TUNER_IN_USE" != "ERROR: unknown getset variable" ]] && HDHR_IN_USE+="$TUNER_IN_USE;"
        done

        if [[ -z "$HDHR_IN_USE" ]]; then
            echo "$HDHR_ON_NETWORK $device is not being used - Restarting" >> "$LOG_FILE"
            restart_hdhr "$device"
        else
            echo "$HDHR_ON_NETWORK $device is currently in use ($HDHR_IN_USE) and will not be reset" >> "$LOG_FILE"
        fi
    fi
done
