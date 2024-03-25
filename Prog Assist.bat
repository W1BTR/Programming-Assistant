@echo off
mode con: cols=49 lines=30
title Programming Assistant
setlocal EnableDelayedExpansion
echo Loading . . .
Set PAVer=0.1.2
set autostart=on
if exist Bin\Settings.cmd call Bin\Settings.cmd
echo here
if %autostart%==on (
	call Bin\CMDS.bat /ts "Prog Assistant COM Companion"
	if !errorlevel!==1 cscript //B //Nologo "Bin\CMS.vbs"
)
REM TODO
rem 3. Add Updates and Update Checking
rem 4. add auto github check on new vendor model
rem 5. Options menu
rem 	- Enable / Disable COM Companion Auto Launch
rem		
set lines=10
goto mainmenu

:titlebar
echo [90;7mF1-Menu F2-Updates F3-New Window F4-COMS F10-Quit[0m
echo =================================================[0m
exit /b

:Menutitlebar
echo [90;7mF1-Menu F2-Updates F3-New Window F4-COMS F10-Quit[0;96m
echo =================================================[0;7m
exit /b

:mainmenu
cls
call :Menutitlebar
if exist Bin\logo.ascii (
    type Bin\logo.ascii
	echo.
)
echo [0;96m=================================================[0m
echo 1] View Radio
echo 2] New Radio
echo 3] COM Ports
echo [90mS] Settings
echo U] Updates
echo X] Exit[0m
"Bin\kbd.exe"
if %errorlevel%==49 goto ViewRadio
if %errorlevel%==50 goto AddRadio
if %errorlevel%==51 goto COMS
if %errorlevel%==51 exit /b
if %errorlevel%==120 exit /b
if %errorlevel%==59 goto mainmenu
if %errorlevel%==60 goto Updates
if %errorlevel%==61 start "" "%~0"
if %errorlevel%==62 goto COMS
if %errorlevel%==115 goto settings
if %errorlevel%==52 goto settings
if %errorlevel%==117 goto updates
if %errorlevel%==68 exit /b
goto mainmenu

:updates
cls
echo Checking for Software Update . . .


:settings
if %autostart%==on (
	set ascolor=[92m
) ELSE (
	set ascolor=[91m
)
cls
echo Settings Menu
echo --------------------
echo 1] COM Assistant Autostart: [%ascolor%%autostart%[0m]
echo X] Exit
choice /c 1x
if %errorlevel%==1 (
	if %autostart%==on (
		set autostart=off
		goto savesettings
	) ELSE (
		set autostart=on
		goto savesettings
	)
)
goto mainmenu

:savesettings
(echo set autostart=%autostart%)>Bin\settings.cmd

goto settings

:COMS
set check=30
set selectedPort=1
if %autostart%==off (
	call Bin\CMDS.bat /ts "Prog Assistant COM Companion"
	if !errorlevel!==1 cscript //B //Nologo "Bin\CMS.vbs"
)
:COMLoop
set num=0
set linecount=0
cls
if not exist "Bin\COMLOG.log" goto :loadCOMLOG
call :menutitlebar
if exist Bin\logo.ascii (
    type Bin\logo.ascii
	echo.
)
echo [0;96m=================================================[0m
echo.
echo COM PORTS:
for /f "tokens=1,2,3 delims=, skip=1" %%A in ('type "Bin\COMLOG.log"') do (
	set /a linecount+=1
	set /a num+=1
	set COMPort!num!=%%~A
	set descrp=%%~B
	if "!num!"=="!SelectedPort!" (
		set comcolor=[7m
	) ELSE (
		set comcolor=
	)
	if "%%~C"=="True" (
		echo !comcolor![92m%%~A [0m!comcolor!!descrp:~0,38! [90mNEW[0m
	) ELSE (
		echo !comcolor![96m%%~A  [0m!comcolor!!descrp:~0,38![0m
	)
)
copy /y "Bin\COMLOG.log" "Bin\COMLog.diff" >nul 2>nul
set check=30
:comKBDLoop
"Bin\Kbd.exe" 1
set /a check-=1
if %check%==0 (
	fc "Bin\COMLOG.diff" "Bin\ComLog.log" >nul 2>nul
	if !errorlevel!==1 goto COMLoop
	set check=30
	goto comKBDLoop
)
if %errorlevel%==0 goto comKBDLoop
if %errorlevel%==110 goto newvendor
if %errorlevel%==27 goto comstomainmenu
if %errorlevel%==120 goto comstomainmenu
if %errorlevel%==59 goto comstomainmenu
if %errorlevel%==60 goto Updates
if %errorlevel%==61 start "" "%~0"
if %errorlevel%==62 goto COMS
if %errorlevel%==68 exit /b
set _errorlevel=%errorlevel%
rem if %_errorlevel%==59 goto options
if %_errorlevel%==80 (
	if not !SelectedPort! GEQ !linecount! (
		set /a SelectedPort+=1
	)
)
if %_errorlevel%==72 (
	if not !SelectedPort! LEQ 1 (
		set /a SelectedPort-=1
	)
)
if %_errorlevel%==13 goto SelectedCOM
goto comloop

:loadCOMLOG
echo Loading . . .
:loadcomlogloop
if not exist "Bin\COMLOG.log"  goto loadcomlogloop
goto comloop

:comstomainmenu
if %autostart%==off (
	call Bin\CMDS.bat /tk "Prog Assistant COM Companion"
)
goto mainmenu

:SelectedCOM
cls
mode !COMPort%SelectedPort%! | more
mode !COMPort%SelectedPort%! | find /i "Not Available" >nul 2>nul
if %errorlevel%==1 (
	echo 1] Change Setting [Baud, Parity, XON, etc]
	echo 2] Enter Text Data into Port
	echo 3] View Text Output
	echo 4] Start a Putty Session
	echo 5] Open Putty
	echo 6] Pipe to Virtual Port [For Hypervisor]
	echo X] Back
) ELSE (
	echo X] Back
)
choice /c 123456X /n

if %errorlevel%==4 (
	putty -serial !COMPort%SelectedPort%!
	goto selectedcom
)
if %errorlevel%==5 (
	putty -serial
	goto selectedcom
)
if %errorlevel%==1 goto comsetting
if %errorlevel%==2 goto DataPort
if %errorlevel%==3 goto TypePort
if %errorlevel%==6 goto passthrough
goto COMS

:passthrough
if "%baudrate%"=="" set baudrate=19200
if "%PipeName%"=="" set PipeName=MyLittlePipe
cls
echo COM PIPE [howardtechnical.com] !COMPort%SelectedPort%!
echo [90mNOTE: This tool cannot create a named pipe,
echo it can only use an existing named pipe otherwise
echo a GLE error will occur.[0m
echo.
echo 1] Change Baud Rate [[96m%baudrate%[0m]
echo 2] Change Pipe Name [[90m\\.\pipe\[96m%PipeName%[0m\]
echo 3] [92mSTART PIPE[0m
echo X] Cancel
choice /c 123x
if %errorlevel%==1 (
	echo.
	echo Enter BAUD RATE:
	set /p baudrate=">"
	goto passthrough
)
if %errorlevel%==2 (
	echo.
	echo Enter Pipe Name:
	set /p PipeName="[90m\\.\pipe\[0m"
	goto passthrough
)
if %errorlevel%==3 (
	echo set cd=%cd% >"%temp%\PASCD.cmd
	echo set Port=!COMPort%SelectedPort%! >>"%temp%\PASCD.cmd
	echo set name=\\.\pipe\%PipeName% >>"%temp%\PASCD.cmd
	echo set baudrate=%baudrate% >>"%temp%\PASCD.cmd
	powershell start -verb runas 'Bin\Piper.bat'
	pause
	goto SelectedCOM
)
goto SelectedCOM

:DataPort
echo Enter data to enter to port
set /p comcommand="!COMPort%SelectedPort%!>"
echo %comcommand%>!COMPort%SelectedPort%!
timeout /t 1 /nobreak >nul
goto selectedcom

:typeport
start "" "Bin\ViewCOM.bat" !COMPort%SelectedPort%!
goto selectedcom

:comsetting
echo Enter setting type followed by and equal
echo sign and it's value for example: BAUD=1200
echo Available Settings are:[90m
echo [BAUD=b] [PARITY=p] [DATA=d] [STOP=s]
echo [to=on|off] [xon=on|off] [odsr=on|off]
echo [octs=on|off] [dtr=on|off|hs]
echo [rts=on|off|hs|tg] [idsr=on|off][0m
echo Or enter X to cancel
set /p modecommand="!COMPort%SelectedPort%!>"
if /i "%modecommand%"=="X" goto SelectedCOM
mode %modecommand%
goto SelectedCOM



:ViewRadio
set Selected=1
set directory=Bin\Files\Radios
:SelectRadio
rem display a list of files in the Files\Vendors folder, allow the user to select one, and set the result to %vendor%
if "!Selected!"=="" set selected=1
set linecount=0
set item=0
set _skip=0
cls
call :titlebar
for /f "tokens=*" %%A in ('dir /b !directory!') do (
	set /a linecount+=1
	set /a item+=1
	set _echo=%%~nA
if exist "!directory!\%%~A\*" set _echo=}%%~A
	set /a _tmpVar=!selected!-!item!
	if !_tmpVar! LSS 35 (
		if "!Selected!"=="!item!" (
			echo [7m!_echo![0m *
			set "_SelectedFile=%%~A"
			set "_SelectedExtension=%%~xA"
			set "_SelectedName=%%~nA"
		) ELSE (
			echo !_echo!
		)
	) ELSE (
		set /a _skip+=1
	)
	set /a _tmpVar=!linecount!-!_skip!
	if !_tmpVar!==%lines% (
		echo | set /p "= . . ."
		goto 1BreakLoop1
	)
)
:1BreakLoop1
"Bin\Kbd.exe"
if %errorlevel%==59 goto mainmenu
if %errorlevel%==60 goto Updates
if %errorlevel%==61 start "" "%~0"
if %errorlevel%==62 goto COMS
if %errorlevel%==68 exit /b
set _errorlevel=%errorlevel%
rem if %_errorlevel%==59 goto options
if %_errorlevel%==80 (
	if not !Selected! GEQ !linecount! (
		set /a Selected+=1
	)
)
if %_errorlevel%==72 (
	if not !Selected! LEQ 1 (
		set /a Selected-=1
	)
)
if %_errorlevel%==77 (
	if exist "%directory%\%_SelectedFile%\*" goto RadioEnterPressed
)
if %_errorlevel%==75 (
	if not "%directory%"=="Bin\Files\Radios" goto :SelectUpOne
)
if %_errorlevel%==8 (
	if not "%directory%"=="Bin\Files\Radios" goto :SelectUpOne
)

if %_errorlevel%==13 goto RadioEnterPressed
goto SelectRadio

:SelectUpOne
Rem Remove trailing backslash if present
if "!directory:~-1!"=="\" set "directory=!directory:~0,-1!"
Rem Find the position of the last backslash
set "lastpos=0"
for /l %%a in (0,1,1000) do (
    set /a "pos=lastpos+1"
    set "char=!directory:~%%a,1!"
    if "!char!"=="" set /a "lastpos-=1" & goto :S1break
    if "!char!"=="\" set "lastpos=%%a"
)
:S1break
Rem Extract the path up to the last backslash
set /a lastpos+=1
set "upOne=!directory:~0,%lastpos%!"
set directory=!upOne!
goto :SelectRadio

:RadioEnterPressed
if exist "%directory%\%_SelectedFile%\*" (
	set directory=%directory%\%_SelectedFile%
	set selected=1
	goto :SelectRadio
)
set Radio="%Directory%\%_SelectedFile%"
:LoadRadio
call "%radio%"
call :SetLC
call :setVC
Rem If path longer than 27 char, trim and append ...
set "len=0"
for /l %%A in (12,-1,0) do (
    set /a "len|=1<<%%A"
    for %%B in (!len!) do if "!SoftwarePath:~%%B,1!"=="" set /a "len&=~1<<%%A"
)
echo !len!
set /a "startPos=!len!-25"
if !len! gtr 27 (
    set "DisplayPath=...!SoftwarePath:~%startPos%,26!"
) else (
    set "DisplayPath=!SoftwarePath!"
)
:DisplayRadio
cls
call :Titlebar
echo [7m%vendor% %model%[0;90m    Press E to Edit [0m
echo -------------------------------------------------
echo Connector:          [95m%jack%[0m
echo TXD to Radio:-------Pin [96m%TXD%[0m
echo RXD From Radio:-----Pin [96m%RXD%[0m
if %RXD%==%TXD% echo                     [93mHALF-DUPLEX[0m
echo Ground Pin:---------Pin [96m%GND%[0m
echo Voltage:            %VC%%Voltage%[0m
echo Compatible Cable:   [96m%cable%[0m
set mismatch=N
if exist "Bin\Files\Cables\Owned\%Cable%.cmd" (
	echo Owned?[32m              Cable Owned[0m
) ELSE (
	echo Owned?[31m              Cable Not Owned[0m
)
echo [90m-------------------------------------------------[0m
echo Software:           [96m%Software%[0m
echo Software Path:      [36m%DisplayPath%[0m
if not "%SoftwarePath:"=%"=="None" (
	if exist "%SoftwarePath:"=%" (
		echo Installed:          [32mSoftware Detected[0m
		echo ---------^>          [90mPress L to launch[0m
	) ELSE (
		echo Installed:          [31mSoftware Not Detected[0m
	)
)
echo License Required:   %LC%%LicenseRequired%[0m
echo -------------------------------------------------
echo Notes: [93m%notes%[0m
echo -------------------------------------------------
echo|set /p="Pins twins: [90m "
for /f "tokens=* delims=" %%A in ('dir /b "Bin\Files\UIDS\%uid%\*.uid1"') do (
	if not exist "Bin\Files\UID2S\%uid2%\%%~nA.uid2" (
		set TwinName=%%~nA
		echo|set /p="!TwinName:.= ! "
	)
)
echo.
echo|set /p="[0mFull twins: [90m "
for /f "tokens=* delims=" %%A in ('dir /b "Bin\Files\UID2S\%uid2%\*.uid2"') do (
	if not "%%~nA"=="%vendor%.%model%" (
		set TwinName=%%~nA
		echo|set /p="!TwinName:.= ! "
	)
)
"Bin\kbd.exe"
if %errorlevel%==27 goto mainmenu
if %errorlevel%==59 goto mainmenu
if %errorlevel%==60 goto Updates
if %errorlevel%==61 start "" "%~0"
if %errorlevel%==62 goto COMS
if %errorlevel%==68 exit /b
if %errorlevel%==101 goto :PreConfigNewMenu
if %errorlevel%==108 (
	pushd "%userprofile%"
	start "" "%SoftwarePath%"
	popd
	goto :ReKBDNew
)
goto loadradio
goto DisplayRadio

:PreConfigNewMenu
Rem If path longer than 27 char, trim and append ...
set "len=0"
for /l %%A in (12,-1,0) do (
    set /a "len|=1<<%%A"
    for %%B in (!len!) do if "!SoftwarePath:~%%B,1!"=="" set /a "len&=~1<<%%A"
)
echo !len!
set /a "startPos=!len!-23"
if !len! gtr 27 (
    set "DisplayPath=...!SoftwarePath:~%startPos%,24!"
) else (
    set "DisplayPath=!SoftwarePath!"
)
goto confignewmenu



REM ==================================
REM START NEW RADIO SECTION
REM  =================================
:AddRadio
set Selected=1
:SelectVendor
rem display a list of files in the Files\Vendors folder, allow the user to select one, and set the result to %vendor%
if "!Selected!"=="" set selected=1
cls
call :titlebar
echo   [96;7mSelect Radio Vendor or Press N for new Vendor[0m
echo =================================================
set linecount=0
set item=0
set _skip=0
for /f "tokens=*" %%A in ('dir /b Bin\Files\Vendors') do (
	set /a linecount+=1
	set /a item+=1
	set _echo=%%~A
if exist "%%~A\*.*" set _echo=}%%~A
	set /a _tmpVar=!selected!-!item!
	if !_tmpVar! LSS 35 (
		if "!Selected!"=="!item!" (
			echo [7m!_echo![0m *
			set "_SelectedFile=%%~A"
			set "_SelectedExtension=%%~xA"
		) ELSE (
			echo !_echo!
		)
	) ELSE (
		set /a _skip+=1
	)
	set /a _tmpVar=!linecount!-!_skip!
	if !_tmpVar!==%lines% (
		echo | set /p "= . . ."
		goto 1BreakLoop1
	)
)
:1BreakLoop1
"Bin\Kbd.exe"
if %errorlevel%==110 goto newvendor
if %errorlevel%==59 goto mainmenu
if %errorlevel%==60 goto Updates
if %errorlevel%==61 start "" "%~0"
if %errorlevel%==62 goto COMS
if %errorlevel%==68 exit /b
set _errorlevel=%errorlevel%
rem if %_errorlevel%==59 goto options
if %_errorlevel%==80 (
	if not !Selected! GEQ !linecount! (
		set /a Selected+=1
	)
)
if %_errorlevel%==72 (
	if not !Selected! LEQ 1 (
		set /a Selected-=1
	)
)
if %_errorlevel%==13 goto SelectedVendor
goto selectvendor

:newvendor
echo Enter vendor name:
echo [90mX to cancel[0m
set /p Vendor=">"
if /i "%vendor%"=="X" goto :SelectVendor
echo.>"Bin\Files\Vendors\%Vendor:"=%"
goto NewModel

:SelectedVendor
set Vendor=%_SelectedFile:"=%
:NewModel
cls
echo Vendor: [7m%Vendor%[0m
echo ===========================
echo Enter new Model Number
set /p Model=">"
goto CONFIGNEW

:CONFIGNEW
rem set some default variables
set jack=RJ45
set voltage=5V
set TXD=
set RXD=
set GND=
set Cable=
set Software=
set Notes=
set VoltageUnset=true
set LicenseRequired=Yes
set SoftwarePath=None
set selected=1
call :SetLC
call :SetVC
:Confignewmenu
call :setcursor
cls
call :titlebar
echo [92mEditing: %Vendor% %Model%[0m
echo [90m== Communication ================================[0m
echo %cur_1%1 Jack:               [92m%jack%[0m 
echo %cur_2%2 TXD (PC to Radio):  [92m%TXD%[0m
echo %cur_3%3 RXD (Radio to PC):  [92m%RXD%[0m
echo %cur_4%4 GND:                [92m%GND%[0m
echo %cur_5%5 Voltage:            %VC%%VOLTAGE%[0m
echo %cur_6%6 Cable Name:         %cable%[0m
set mismatch=N
if exist "Bin\Files\Cables\Owned\%Cable%.cmd" (
	call "Bin\Files\Cables\Owned\%Cable%.cmd"
	if not "%TXD%"=="!CableTXD!" set mismatch=Y
	if not "%RXD%"=="!CableRXD!" set mismatch=Y
	if not "%GND%"=="!CableGND!" set mismatch=Y
	if not "%Voltage%"=="!CableV!" set mismatch=Y
	if "!mismatch!"=="Y" (
		echo C Owned?[33m              Cable mismatch[90m PRESS C
	) ELSE (
		echo C Owned?[32m              Cable Owned[0m
	)
) ELSE (
	echo C[31m Cable Not Owned[90m Press C to add to owned library[0m
)
echo [90m== Software =====================================[0m
echo %cur_7%7 Software:           [97m%Software%[0m
echo %cur_8%8 License Required:   %LC%%LicenseRequired%[0m
echo %cur_9%9 Software Path:      [90m%DisplayPath%[0m
if not "%SoftwarePath:"=%"=="None" (
	if exist "%SoftwarePath:"=%" (
		echo L Detected?[32m       Software Detected[0m
	) ELSE (
		echo L Detected?[31m       Software Not Detected[0m
	)
) ELSE (
	echo [90mEnter software path to detect install[0m
)
echo [90m== Notes ========================================[0m
echo %cur_0%0 Notes: [7m%notes%[0m
echo -------------------------------------------------
echo Press [97mS[0m to save
echo Press [97mI[0m to import from twin radio
echo Press [97mX[0m to close
if not "%SoftwarePath:"=%"=="None" (
	if exist "%SoftwarePath:"=%" echo Press [97mL[0m to Launch %Software%
)
echo -------------------------------------------------
REM TODO
rem navigate creation
rem create uniqueID to find programming cable twins
rem save to file
rem twin importing
:ReKBDNew
"Bin\Kbd.exe"
if %errorlevel%==80 (
	if not !Selected! GEQ 10 (
		set /a Selected+=1
	)
)
if %errorlevel%==72 (
	if not !Selected! LEQ 1 (
		set /a Selected-=1
	)
)
if %errorlevel%==108 (
	pushd "%userprofile%"
	start "" "%SoftwarePath%"
	popd
	goto :ReKBDNew
)
cls
if %errorlevel%==49 (
	call :SetJack
	goto :Confignewmenu
)
if %errorlevel%==50 (
	call :SetTXD
	goto :Confignewmenu
)
if %errorlevel%==51 (
	call :SetRXD
	goto :Confignewmenu
)
if %errorlevel%==52 (
	call :SetGND
	goto :Confignewmenu
)
if %errorlevel%==53 (
	call :SetVLT
	call :SetVC
	goto :Confignewmenu
)
if %errorlevel%==54 (
	call :SetCable
	goto :Confignewmenu
)
if %errorlevel%==55 (
	call :SetSoftware
	goto :Confignewmenu
)
if %errorlevel%==56 (
	call :SetLicense
	call :SetLC
	goto :Confignewmenu
)
if %errorlevel%==57 (
	call :SetSPath
	goto :Confignewmenu
)

if %errorlevel%==48 (
	call :SetNote
	goto :Confignewmenu
)

if %errorlevel%==59 goto mainmenu
if %errorlevel%==60 goto Updates
if %errorlevel%==61 start "" "%~0"
if %errorlevel%==62 goto COMS
if %errorlevel%==68 exit /b

if %errorlevel%==105 goto importRadio
if %errorlevel%==13 goto SelNewMenu
if %errorlevel%==115 goto SaveRadio
if %errorlevel%==120 goto mainmenu
if %errorlevel%==99 (
	call :SaveCable
	goto :Confignewmenu
)
goto Confignewmenu

:importRadio


:SaveCable
if not exist "Bin\Files\Cables\Owned\" md "Bin\Files\Cables\Owned\"
if %mismatch%==Y call :updatecable
if %mismatch%==Y exit /b
echo Ensure the pins are set up properly
echo [97mbefore[0m saving the cable.
echo.
echo TXD to Radio: %TXD%
echo RXD from Radio: %RXD%
echo GND for both: %GND%
echo Data Voltage: %voltage%
echo.
echo Save?
choice
if %errorlevel%==2 exit /b
(echo @echo off)>"Bin\Files\Cables\Owned\%Cable%.cmd"
(Echo set CableTXD=%TXD%)>>"Bin\Files\Cables\Owned\%Cable%.cmd"
(Echo set CableRXD=%RXD%)>>"Bin\Files\Cables\Owned\%Cable%.cmd"
(Echo set CableGND=%GND%)>>"Bin\Files\Cables\Owned\%Cable%.cmd"
(Echo set CableV=%voltage%)>>"Bin\Files\Cables\Owned\%Cable%.cmd"
echo [92mCable Saved.[0m
pause
exit /b

:updatecable
rem color code
if not "%TXD%"=="%CableTXD%" (
	set pTXD=[91m
) ELSE (
	set pTXD=
)
if not "%RXD%"=="%CableRXD%" (
	set pRXD=[91m
) ELSE (
	set pRXD=
)
if not "%GND%"=="%CableGND%" (
	set pGND=[91m
) ELSE (
	set pGND=
)
if not "%voltage%"=="%CableV%" (
	set pV=[91m
) ELSE (
	set pV=
)
echo The current Pin Layout does not
echo match the pins saved for %cable%.
echo [93;7mCurrent Settings:[0m
echo TXD to Radio: !pTXD!%TXD%[0m
echo RXD from Radio: !pRXD!%RXD%[0m
echo GND for both: !pGND!%GND%[0m
echo Data Voltage: !pV!%voltage%[0m
echo [96;7m%cable% Saved Pins:[0m
echo TXD to Radio: !pTXD!%CableTXD%[0m
echo RXD from Radio: !pRXD!%CableRXD%[0m
echo GND for both: !pGND!%CableGND%[0m
echo Data Voltage: !pV!%CableV%[0m
echo.
echo 1] Overwrite saved cable
echo 2] Pull from saved cable
echo 3] Change cable name
echo X] Go back
choice /c 1234x
if %errorlevel%==1 (
	(echo @echo off)>"Bin\Files\Cables\Owned\%Cable%.cmd"
	(Echo set CableTXD=%TXD%)>>"Bin\Files\Cables\Owned\%Cable%.cmd"
	(Echo set CableRXD=%RXD%)>>"Bin\Files\Cables\Owned\%Cable%.cmd"
	(Echo set CableGND=%GND%)>>"Bin\Files\Cables\Owned\%Cable%.cmd"
	(Echo set CableV=%voltage%)>>"Bin\Files\Cables\Owned\%Cable%.cmd"
	echo [92mCable Saved.[0m
	pause
	exit /b
)
if %errorlevel%==2 (
	set TXD=%CableTXD%
	set RXD=%CAbleRXD%
	set GND=%CableGND%
	set Voltage=%CableV%
	echo [96mPulled Settings.[0m
	pause
	exit /b
)
if %errorlevel%==3 (
	call :SetCable
	exit /b
)
exit /b

:SetVC
set VC=[91m
rem set color of voltage text depending on value, and append V if needed
if "!Voltage!"=="5V" set VC=[92m
if "!Voltage!"=="3.3V" set VC=[96m
if "!Voltage!"=="1.8V" set VC=[93m
if "!Voltage!"=="5" set VC=[92m& set Voltage=5V
if "!Voltage!"=="3.3" set VC=[96m& set Voltage=3.3V
if "!Voltage!"=="1.8" set VC=[93m& set Voltage=1.8V
exit /b

:SetLC
rem set color of License Required text
if "!LicenseRequired!"=="Yes" set LC=[91m
if "!LicenseRequired!"=="No" set LC=[92m
exit /b

:SetCable
echo Enter name of a cable (i.e. Kenwood KPG-46X):
set /p cable=">"
if exist "Bin\Files\Cables\Owned\%Cable%.cmd" (
	call "Bin\Files\Cables\Owned\%Cable%.cmd"
	if "%TXD%"=="" set TXD=!CableTXD!
	if "%RXD%"=="" set RXD=!CableRXD!
	if "%GND%"=="" set GND=!CAbleGND!
	if "%VoltageUnset%"=="True" set voltage=!CableV!
)
exit /b

:SetNote
echo Enter a new note:
set /p notes=">"
exit /b

:SelNewMenu
rem enter was pressed, figure out which menu to go to
if %selected%==1 (
	call :SetJack
	goto :Confignewmenu
)
if %selected%==2 (
	call :SetTXD
	goto :Confignewmenu
)
if %selected%==3 (
	call :SetRXD
	goto :Confignewmenu
)
if %selected%==4 (
	call :SetGND
	goto :Confignewmenu
)
if %selected%==5 (
	call :SetVLT
	call :SetVC
	goto :Confignewmenu
)
if %selected%==6 (
	call :SetCable
	goto :Confignewmenu
)
if %selected%==7 (
	call :SetSoftware
	goto :Confignewmenu
)
if %selected%==8 (
	call :SetLicense
	call :SetLC
	goto :Confignewmenu
)
if %selected%==9 (
	call :SetSPath
	goto :Confignewmenu
)
if %selected%==10 (
	call :SetNote
	goto :Confignewmenu
)
goto Confignewmenu

:SetLicense
echo Is a license required to use the
echo %software% software?
choice
if %errorlevel%==1 set LicenseRequired=Yes
if %errorlevel%==2 set LicenseRequired=No
if exist "Bin\Files\Software\!software!.cmd" call "Bin\Files\Software\!software!.cmd"
if exist "Bin\Files\Software\!software!.cmd" (
	if not "!SoftwareLicenseRequired!"=="!LicenseRequired!" (
		echo Save change for %software%?
		choice
		if !errorlevel!==1 (
			echo @echo off >"Bin\Files\Software\!software!.cmd"
			echo set DefaultPath=!DefaultPath!>>"Bin\Files\Software\!software!.cmd"
			echo Set SoftwareLicenseRequired=!LicenseRequired!>>"Bin\Files\Software\!software!.cmd"
		)
	)
) ELSE (
	echo Additionally save License required as %LicenseRequired%
	echo for %Software%?
	choice
	if !errorlevel!==1 (
		echo @echo off >"Bin\Files\Software\!software!.cmd"
		echo set DefaultPath=!DefaultPath!>>"Bin\Files\Software\!software!.cmd"
		echo Set SoftwareLicenseRequired=!LicenseRequired!>>"Bin\Files\Software\!software!.cmd"
	)
)
exit /b

:SetSPath
echo Select the executable file to run the
echo programming software for the %vendor% %model%
set OpenPath=C:\
if not "%SoftwarePath%"=="" for %%i in ("%SoftwarePath%") do set "OpenPath=%%~dpi\"
for /f "tokens=*" %%A in ('call bin\chooser.bat "%OpenPath%"') do (
	set SoftwarePath=%%~A
	set SoftwareTemp=%%~nA
)
if "%softwarePath%"=="" (
	set SoftwarePath=None
	Set DisplayPath=
	exit /b
)
if "%software%"=="" set Software=!SoftwareTemp!
rem check if a file on this software already exists. If it does, check if it's different
if exist "Bin\Files\Software\!software!.cmd" call "Bin\Files\Software\!software!.cmd"
if exist "Bin\Files\Software\!software!.cmd" (
	if not "!DefaultPath:^)=^)!"=="!SoftwarePath:^)=^)!" (
		echo Overwrite !DefaultPath! with
		echo !SoftwarePath! for %Software%?
		choice
		if !errorlevel!==1 (
			echo @echo off >"Bin\Files\Software\!software!.cmd"
			echo set DefaultPath=!SoftwarePath:^)=^)!>>"Bin\Files\Software\!software!.cmd"
			echo Set SoftwareLicenseRequired=!SoftwareLicenseRequired!>>"Bin\Files\Software\!software!.cmd"
		)
	)
) ELSE (
	echo Additionally save: 
	echo !SoftwarePath:^)=^)!
	echo as the default path for %software%?
	choice
	if !errorlevel!==1 (
		echo @echo off >"Bin\Files\Software\!software!.cmd"
		echo set DefaultPath=!SoftwarePath:^)=^)!>>"Bin\Files\Software\!software!.cmd"
		echo Set SoftwareLicenseRequired=!LicenseRequired!>>"Bin\Files\Software\!software!.cmd"
	)
)
Rem If path longer than 27 char, trim and append ...
set "len=0"
for /l %%A in (12,-1,0) do (
    set /a "len|=1<<%%A"
    for %%B in (!len!) do if "!SoftwarePath:~%%B,1!"=="" set /a "len&=~1<<%%A"
)
echo !len!
set /a "startPos=!len!-23"
if !len! gtr 27 (
    set "DisplayPath=...!SoftwarePath:~%startPos%,24!"
) else (
    set "DisplayPath=!SoftwarePath!"
)
exit /b

:SetSoftware
echo Enter the name of the %vendor% or third party
echo software used to program the %model%.
set /p software=">"
if not exist "Bin\Files\Software\!software!.cmd" exit /b
call "Bin\Files\Software\!software!.cmd"
set LicenseRequired=!SoftwareLicenseRequired!
if exist "!DefaultPath!" set SoftwarePath=!DefaultPath!
Rem If path longer than 27 char, trim and append ...
set "len=0"
for /l %%A in (12,-1,0) do (
    set /a "len|=1<<%%A"
    for %%B in (!len!) do if "!SoftwarePath:~%%B,1!"=="" set /a "len&=~1<<%%A"
)
echo !len!
set /a "startPos=!len!-23"
if !len! gtr 27 (
    set "DisplayPath=...!SoftwarePath:~%startPos%,24!"
) else (
    set "DisplayPath=!SoftwarePath!"
)
exit /b

:SetVLT
echo Enter the voltage expected by the radio for serial communication.
echo This will usually be 5V, but may be 3.3, or 1.8v.
set /p voltage=">"
set VoltageUnset=false
exit /b

:SetGND
	echo Enter the pin on the %jack% connector for GROUND.
	set /p GND=">"
exit /b

:SetTXD
	echo Enter the Pin on the %jack% connector for
	echo data going to the radio from the computer.
	echo.
	echo On the radio, this will likely be labeled RXD.
	echo On the cable, it will likely be labeled TXD.
	set /p TXD=">"
exit /b

:SetRXD
	echo Enter the Pin on the %jack% connector for
	echo data going to the computer from the radio.
	echo.
	echo On the radio, this will likely be labeled TXD.
	echo On the cable, it will likely be labeled RXD.
	set /p RXD=">"
exit /b

:SetJack
	echo Suggested Jacks:
	echo RJ45, RJ11
	echo DB9, DB15, DB9, DB25, DB37
	echo 3.5mm TRS, 3.5mm TRRS, 2.5mm TRS, 2.5mm TRRS
	echo.
	set /p jack=">"
exit /b



:setcursor
rem callable section to add a color inverting character to a variable if the selected line matches
if %selected%==1 (
	set cur_1=[7m
) ELSE (
	set cur_1=
)
if %selected%==2 (
	set cur_2=[7m
) ELSE (
	set cur_2=
)
if %selected%==3 (
	set cur_3=[7m
) ELSE (
	set cur_3=
)
if %selected%==4 (
	set cur_4=[7m
) ELSE (
	set cur_4=
)
if %selected%==5 (
	set cur_5=[7m
) ELSE (
	set cur_5=
)
if %selected%==6 (
	set cur_6=[7m
) ELSE (
	set cur_6=
)
if %selected%==7 (
	set cur_7=[7m
) ELSE (
	set cur_7=
)
if %selected%==8 (
	set cur_8=[7m
) ELSE (
	set cur_8=
)
if %selected%==9 (
	set cur_9=[7m
) ELSE (
	set cur_9=
)
if %selected%==10 (
	set cur_0=[7m
) ELSE (
	set cur_0=
)
exit /b
REM ==========================================
REM END ADD RADIO CONFIG
REM ==========================================


:SaveRadio
cls
echo Saving [96m%vendor% %model% . . .
if not exist "Bin\Files\Radios\%vendor%\" md "Bin\Files\Radios\%vendor%\"
if exist "Bin\Files\Radios\%vendor%\%model%.cmd" (
	echo [91mThere is already a save file for:
	echo %vendor% %model%.[0m
	echo Overwrite?
	choice
	if %errorlevel%==2 goto mainmenu
)
rem set unique identifiers of programing cable and software
set uid=%jack%%txd%%rxd%%gnd%%voltage%
set uid2=%jack%%txd%%rxd%%gnd%%voltage%%software%
rem create a callable file with all the variables
echo @echo off >"Bin\Files\Radios\%vendor%\%model%.cmd"
echo rem Last modified %date% %time% >>"Bin\Files\Radios\%vendor%\%model%.cmd"
(echo set vendor=%vendor%)>>"Bin\Files\Radios\%vendor%\%model%.cmd"
(echo set model=%model%)>>"Bin\Files\Radios\%vendor%\%model%.cmd"
(echo set jack=%jack%)>>"Bin\Files\Radios\%vendor%\%model%.cmd"
(echo set txd=%txd%)>>"Bin\Files\Radios\%vendor%\%model%.cmd"
(echo set rxd=%rxd%)>>"Bin\Files\Radios\%vendor%\%model%.cmd"
(echo set gnd=%gnd%)>>"Bin\Files\Radios\%vendor%\%model%.cmd"
(echo set voltage=%voltage%)>>"Bin\Files\Radios\%vendor%\%model%.cmd"
(echo set software=%software%)>>"Bin\Files\Radios\%vendor%\%model%.cmd"
echo set softwarepath=%softwarepath%>>"Bin\Files\Radios\%vendor%\%model%.cmd"
(echo set licenserequired=%licenserequired%)>>"Bin\Files\Radios\%vendor%\%model%.cmd"
(echo set cable=%cable%)>>"Bin\Files\Radios\%vendor%\%model%.cmd"
(echo set notes=%notes%)>>"Bin\Files\Radios\%vendor%\%model%.cmd"
(echo set uid=%uid%)>>"Bin\Files\Radios\%vendor%\%model%.cmd"
(echo set uid2=%uid2%)>>"Bin\Files\Radios\%vendor%\%model%.cmd"
rem save UID and UID2 for looking up compatible radios. If a UID DB doesnt exist matching the uid, creatge one.
for /f "tokens=* delims=*" %%A in ('dir /b /s "%vendor%.%model%.uid1"') do (if exist "%%~A" del /f /q "%%~A")
for /f "tokens=* delims=*" %%A in ('dir /b /s "%vendor%.%model%.uid2"') do (if exist "%%~A" del /f /q "%%~A")
if not exist "Bin\Files\UIDS\%uid%\" md "Bin\Files\UIDS\%uid%\"
if not exist "Bin\Files\UID2S\%uid2%\" md "Bin\Files\UID2S\%uid2%\"
echo [%vendor%\%model%]>"Bin\Files\UIDS\%uid%\%vendor%.%model%.uid1"
echo [%vendor%\%model%]>"Bin\Files\UID2S\%uid2%\%vendor%.%model%.uid2"
echo.
echo [92mDone.[0m
pause
set radio="Bin\Files\Radios\%vendor%\%model%.cmd"
goto loadradio








:menunavscript
echo Navigate
for /f "tokens=*" %%A in ('dir /b Bin\Files\Vendors') do (
	set /a linecount+=1
	set /a item+=1
	set _echo=%%~A
if exist "%%~A\*.*" set _echo=}%%~A
	set /a _tmpVar=!selected!-!item!
	if !_tmpVar! LSS 35 (
		if "!Selected!"=="!item!" (
			echo [7m!_echo![0m *
			set "_SelectedFile=%%~A"
			set "_SelectedExtension=%%~xA"
		) ELSE (
			echo !_echo!
		)
	) ELSE (
		set /a _skip+=1
	)
	set /a _tmpVar=!linecount!-!_skip!
	if !_tmpVar!==%lines% (
		echo | set /p "= . . ."
		goto 1BreakLoop1
	)
)
:1BreakLoop1
"Bin\Kbd.exe"
set _errorlevel=%errorlevel%
rem if %_errorlevel%==59 goto options
if %_errorlevel%==80 set /a Selected+=1
if %_errorlevel%==72 set /a Selected-=1
if %_errorlevel%==13 goto SelectVendor