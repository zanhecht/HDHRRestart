@ECHO OFF >NUL
setlocal ENABLEDELAYEDEXPANSION

::Set to the device ID of your first HDHomeRun Device
set HDHROne=12345678
::Set to the device ID of your second HDHomeRun Device
set HDHRTwo=23456789
::Set to the IP Address of the smart outlet connected to your first HDHomeRun Device. Leave blank to disable.
set WeMoOneIP=192.168.1.200
::Set to the IP Address of the smart outlet connected to your second HDHomeRun Device. Leave blank to disable.
set WeMoTwoIP=192.168.1.201
::Set Tasmota=True if your smart outlets are using the Tasmota firmware. Leave blank if you are using a stock WeMo.
set Tasmota=True
:: You should not have to edit anything below this line

set PATH=C:\cygwin64\bin;%PATH%
CD /d "%~dp0"

echo ................................................................... >> "%~dp0RestartTuners.log"

for /F "tokens=2" %%i in ('date /t') do set mydate=%%i
set mytime=%time%
echo %mydate%:%mytime% >> "%~dp0RestartTuners.log"

set TunerReset=

:: Check each HDHomeRun in turn
for %%a in (%HDHROne%,%HDHRTwo%) do (

	if %%a==%HDHROne% set WeMoIP=%WeMoOneIP%
	if %%a==%HDHRTwo% set WeMoIP=%WeMoTwoIP%
	set HDHROnNetwork=
	"C:\Program Files\Silicondust\HDHomeRun\hdhomerun_config.exe" %%a get /sys/hwmodel 1> "%~dp0TempFile.txt" 2>&1
	set /P HDHROnNetwork= < "%~dp0TempFile.txt"
	del "%~dp0TempFile.txt"

	if not !HDHROnNetwork:~0^,4!==HDHR (
		echo HDHomeRun %%a is not seen on the network ^(!HDHROnNetwork!^)>> "%~dp0RestartTuners.log"
		if not "!WeMoIP!"=="" (
			echo Power Cycling HDHomeRun %%a >> "%~dp0RestartTuners.log"
			if not %Tasmota%==True (
				c:\cygwin64\bin\sh.exe wemo_control.sh !WeMoIP! OFF 1>nul 2>&1
				c:\Windows\System32\timeout.exe /t 2 /NOBREAK >nul
				c:\cygwin64\bin\sh.exe wemo_control.sh !WeMoIP! ON 1>nul 2>&1
			) else (
				%~dp0wget.exe -qO- http://!WeMoIP!/cm?cmnd=Power%%20off >> "%~dp0RestartTuners.log"
				c:\Windows\System32\timeout.exe /t 2 /NOBREAK >nul
				%~dp0wget.exe -qO- http://!WeMoIP!/cm?cmnd=Power%%20on >> "%~dp0RestartTuners.log"
				echo . >> "%~dp0RestartTuners.log"
			)
		) else (
			echo Smart outlet control disabled, skipping power cycle >> "%~dp0RestartTuners.log"
		)
	) else (
		echo Found !HDHROnNetwork! %%a on network >> "%~dp0RestartTuners.log"
		set HDHRInUse=

		:: Check each Tuner on this HDHomeRun in turn
		for %%i in (0,1,2,3,4,5) do (
			set TunerInUse=
			"C:\Program Files\Silicondust\HDHomeRun\hdhomerun_config.exe" %%a get /tuner%%i/lockkey > "%~dp0TempFile.txt"
			set /P TunerInUse= < "%~dp0TempFile.txt"
			del "%~dp0TempFile.txt"
			if not "!TunerInUse!"=="none" (
				if not "!TunerInUse!"=="ERROR: unknown getset variable" (
					set HDHRInUse=!HDHRInUse!!TunerInUse!;
				)
			)
		)
	
		if "!HDHRInUse!"=="" (
			echo !HDHROnNetwork! %%a is not being used - Restarting >> "%~dp0RestartTuners.log"
			"C:\Program Files\Silicondust\HDHomeRun\hdhomerun_config.exe" %%a set /sys/restart self 1>> "%~dp0RestartTuners.log" 2>&1
		) else (
			echo !HDHROnNetwork! %%a is currently in use ^(!HDHRInUse!^) and will not be reset at this time >> "%~dp0RestartTuners.log"
		)	
	)
)

::exit
