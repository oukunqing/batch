@echo off
%1 mshta vbscript:CreateObject("Shell.Application").ShellExecute("cmd.exe","/c %~s0 ::","","runas",1)(window.close)&&exit
cd /d "%~dp0"

@echo off 

set DB1=MariaDB10.4
set DB2=MariaDB10.5
set DB3=MSSQLSERVER

:flag_loop

cls

echo Database Type
echo 1 - %DB1%
call :flag_state %DB1%
echo 2 - %DB2%
call :flag_state %DB2%
echo 3 - %DB3%
call :flag_state %DB3%
rem echo.

rem echo Action Type
rem echo S - start
rem echo X - stop

:flag_type
echo.
echo Please Input Database Type: R - Loop, Q - Exit

set /p type= 

set return=%type%
call :upper_case %return%
set type=%return%

call :check_exit %type%

if "%type%" == "1" (
	echo %DB1% 
	call :flag_state %DB1% 
	call :flag_action %DB1%
) else if "%type%" == "2" (
	echo %DB2% 
	call :flag_state %DB2% 
	call :flag_action %DB2%
) else if "%type%" == "3" (
	echo %DB3% 
	call :flag_state %DB3% 
	call :flag_action %DB3%
) else if "%type%" == "R" (
	goto flag_loop
) else (
	goto flag_type
)

:flag_action
	rem echo %~1
	echo.
	echo Please Input Action: S - Start, X - Stop, R - SelectType, Q - Exit

	set /p action=
	set return=%action%
	call :upper_case %return%
	set action=%return%

	call :check_exit %type%

	if "%action%" == "S" (
		call :flag_start %~1
	) else if "%action%" == "X" (
		call :flag_stop %~1
	) else if "%action%" == "R" (
		goto flag_type
	) else (
		goto flag_action
	)
goto:eof

:flag_state
	sc query "%~1" |findstr "STATE"
goto:eof

:flag_start
	echo start %~1
	sc start %~1
	timeout 2 
	call :flag_state %~1
	goto flag_type
goto:eof

:flag_stop
	echo stop %~1
	sc stop %~1
	timeout 2
	call :flag_state %~1
	goto flag_type
goto:eof

:check_exit
	if "%~1" == "Q" (
		goto flag_exit
	) else if "%~1" == "EXIT" (
		goto flag_exit
	) else if "%~1" == "QUIT" (
		goto flag_exit
	)
goto:eof

:upper_case
	for %%i in (A B C D E F G H I J K L M N O P Q R S T U V W X Y Z) do call set return=%%return:%%i=%%i%%
goto:eof

:lower_case
	for %%i in (a b c d e f g h i j k l m n o p q r s t u v w x y z) do call set return=%%return:%%i=%%i%%
goto:eof

:flag_exit
exit