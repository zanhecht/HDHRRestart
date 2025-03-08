# HDHRRestart
HDHomeRun Tuner Restart  
Based on scripts by [jgsouthard](https://forums.sagetv.com/forums/member.php?u=2072) at [forums.sagetv.com](https://forums.sagetv.com/forums/showthread_t_62840.html?t=62840).

If you have an older or flakier [SiliconDust HDHomeRun](https://www.silicondust.com/hdhomerun/) tuner, this script will check to see if it is on the network, check to see if it's in use, and if it's not in use, initiate a soft reboot. If it is not on the network, the script can also power cycle the HDHomeRun using either a WeMo or a smart outlet/switch running the [Tasmota firmware](https://tasmota.github.io/docs/).

Your smart outlet will need to be assigned a static IP address by your router for the script to find it. If you are using a Tasmota device, you can dim the status LEDs by going to http://192.168.1.###/cm?cmnd=Backlog%20LedPwmMode%201%3BLedPwmOff%2031%3BLedPwmOn%2063 (replace 192.168.1.### with the IP of the device).

## Windows
Use ```RestartTuners.bat```

Requires [hdhomerun_config.exe](https://info.hdhomerun.com/info/hdhomerun_config), which should be at ```C:\Program Files\Silicondust\HDHomeRun``` if you've installed the [HDHomeRun Software for Windows](https://download.silicondust.com/hdhomerun/hdhomerun_windows.exe).

Set the script to run at a regular interval using Windows Schedule tasks. Shortly before the top of the hour tends to work well.

If you are using a WeMo device and are not using the Tasmota firmware, you will need to install both [Cygwin](https://www.cygwin.com/install.html) and [Curl](https://curl.se/windows/). Otherwise, the GNU wget.exe included in this repository is sufficient for controlling Tasmota devices.

## Linux
Use ```RestartTuners.sh```

Before using, install [hdhomerun_config](https://info.hdhomerun.com/info/hdhomerun_config) by running, from the home directory:

```sh
sudo apt update && sudo apt install -y git build-essential
git clone https://github.com/Silicondust/libhdhomerun.git && cd libhdhomerun && make
sudo install -m 755 ~/libhdhomerun/hdhomerun_config /usr/local/bin/
```

Set the script to run at a regular interval using ```crontab -e```. Shortly before the top of the hour tends to work well.
