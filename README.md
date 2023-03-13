# HDHRRestart
HDHomeRun Tuner Restart  
Based on scripts by [jgsouthard](https://forums.sagetv.com/forums/member.php?u=2072) at forums.sagetv.com

If you have an older of flakier [SiliconDust HDHomeRun](https://www.silicondust.com/hdhomerun/) tuner, this script will check to see if it is on the network, check to see if it's in use, and if it's not in use, initiate a soft reboot. If it is not on the network, the script can also power cycle the HDHomeRun using either a WeMo or a smart outlet/switch running the [Tasmota firmware](https://tasmota.github.io/docs/).

Set the script to run at a regular interval using Windows Schedule tasks. Shortly before the top of the hour tends to work well.

If you are using a WeMo device and are not using the Tasmota firmware, you will need to install both [Cygwin](https://www.cygwin.com/install.html) and [Curl](https://curl.se/windows/). Otherwise, the GNU wget.exe included in this repository is sufficient for controlling Tasmota switches.
