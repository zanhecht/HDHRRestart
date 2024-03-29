# HDHRRestart
HDHomeRun Tuner Restart  
Based on scripts by [jgsouthard](https://forums.sagetv.com/forums/member.php?u=2072) at forums.sagetv.com

If you have an older or flakier [SiliconDust HDHomeRun](https://www.silicondust.com/hdhomerun/) tuner, this script will check to see if it is on the network, check to see if it's in use, and if it's not in use, initiate a soft reboot. If it is not on the network, the script can also power cycle the HDHomeRun using either a WeMo or a smart outlet/switch running the [Tasmota firmware](https://tasmota.github.io/docs/).

Set the script to run at a regular interval using Windows Schedule tasks. Shortly before the top of the hour tends to work well.

If you are using a WeMo device and are not using the Tasmota firmware, you will need to install both [Cygwin](https://www.cygwin.com/install.html) and [Curl](https://curl.se/windows/). Otherwise, the GNU wget.exe included in this repository is sufficient for controlling Tasmota devices. Your smart outlet will need to be assigned a static IP address by your router for the script to find it.

If you are using a Tasmota device, you can dim the status LEDs by going to http://192.168.1.200/cm?cmnd=Backlog%20LedPwmMode%201%3BLedPwmOff%2031%3BLedPwmOn%2063 (replace 192.168.1.200 with the IP of the device).
