@echo off
rem Run as administrator
%1 mshta vbscript:CreateObject("Shell.Application").ShellExecute("cmd.exe","/c %~s0 ::","","runas",1)(window.close)&&exit
rem Switch to the file current directory
cd /d "%~dp0"

rem 设置本地为延迟扩展
setlocal enabledelayedexpansion 

:flag_loop

cls
rem echo %0ssss


rem 如果要增加新的服务，只需要增加服务名称，按分号分隔（仅修改这一处地方就可以）
set WS=MariaDB10.4;MariaDB10.5;MSSQLSERVER;aspnet_state;ZyrhDeviceService


rem 数组下标开始，这里特意设计为从1开始
set WS_START=1
rem 数组元素数量，自动增长
set WS_COUNT=1

:flag_split
rem 分割字符串WS，按分号;分隔
rem tokens=1*，tokens表示分段的方式，tokens=1*表示第一个分隔符;之前的作为一部分,剩下的(*表示)作为一部分。这两部分在循环体总可以用%%a表示第一部分，%%b表示第二部分
rem delims=;表示以分号作为分隔符
for /f "tokens=1* delims=;" %%a in ("%WS%") do (
	rem 将分割出来的字符串赋值给数组元素
	set WS[%WS_COUNT%]=%%a
	set /a WS_COUNT+=1
	rem 将截取剩下的部分赋给变量WS
	set WS=%%b
)
rem 如果还有剩余,则继续分割
if defined WS goto :flag_split

set /a WS_COUNT-=1

echo.
echo   [:Loop]  Please select service id:
for /l %%n in (%WS_START%, 1, %WS_COUNT%) do ( 
   rem echo !WS[%%n]! 
   rem 启用了变量延迟，变量需要用!!括起来
   call :flag_state !WS[%%n]! %%n
)

:flag_type
echo.
set /p "type=  [:Type]  Please input service id (%WS_START% - %WS_COUNT%) (R - :Loop, Q - Exit) : "

set return=%type%
call :upper_case %type% return
set type=%return%
set /a num=%type%*1

call :check_exit %type%

if %type%==%num% (
	if %num% gtr %WS_COUNT% (
		echo   Please enter the numbers %WS_START% - %WS_COUNT% .
		goto flag_type
	) else if %num% leq 0 (
		echo   Please enter the numbers %WS_START% - %WS_COUNT% !
		goto flag_type
	) else (
		call :flag_state !WS[%type%]! %type%
		call :flag_action !WS[%type%]! %type%
	)
) else if "%type%" == "R" (
	goto flag_loop
) else (
	goto flag_type
)


goto comments
	函数
	根据用户输入确定不同的操作
	参数1: 要操作的服务名称，字符串
:comments
:flag_action
	echo.
	rem 这里的□ (<0x08>)是一个退格符，是为了显示出后面的两个空格位置
	set /p "action=  Please input action key (S - Start, X - Stop, C - Config, R - :Type, Q - Exit) : "

	set return=%action%
	call :upper_case %action% return
	set action=%return%

	call :check_exit %action%

	if "%action%" == "S" (
		call :flag_start %~1 %~2
	) else if "%action%" == "X" (
		call :flag_stop %~1 %~2
	) else if "%action%" == "C" (
		call :flag_config %~1
	) else if "%action%" == "R" (
		goto flag_type
	) else (
		goto flag_action
	)
goto:eof

goto comments
	函数
	查询服务状态，并返回明确的服务状态，如 RUNNING 或 STOPPED，接受两个参数
	参数1: 要查询的服务名称，字符串
	参数2: 接受返回结果的变量
:comments
:flag_state
	set st=
	call :flag_qc %~1 %~2 st

	set fn=%~1_tmp_123.log
	rem 查询服务状态信息，提取 STATE 内容并写入到文件中
	sc query "%~1" |findstr "STATE" > %fn%

	set value=
	rem 读取文件内容到value变量
	set /p value=<./%fn%

	del %fn%

	set index=2
	rem 按冒号:分割字符串，并提取第2部分的内容（下标是从1开始的）
	for /F "tokens=%index% delims=:" %%a in ("%value%") do set value=%%a

	rem 按空格分割字符串，并提取第2部分的内容（下标是从1开始的）
	for /F "tokens=%index% delims= " %%a in ("%value%") do set value=%%a
	echo   %~2  %~1			----  %value%	----  %st%
goto:eof

:flag_qc
	set fn=%~1_qc_123.log
	rem 查询服务配置信息，提取 START_TYPE 内容并写入到文件中
	sc qc "%~1" |findstr "START_TYPE" > %fn%

	set value=
	rem 读取文件内容到value变量
	set /p value=<./%fn%

	del %fn%

	set index=2
	rem 按冒号:分割字符串，并提取第2部分的内容（下标是从1开始的）
	for /F "tokens=%index% delims=:" %%a in ("%value%") do set value=%%a

	rem 截取字符串，从第5个字符开始（空格也算是字符）
	set value=%value:~5%

	rem 替换双空格为单个空格
	set value=%value:  = %

	rem echo   %~2 	%~1 		--------  %value%

	rem 将返回值赋值给变量3
	set %~3=%value%
goto:eof

:flag_start
	echo   start %~1
	sc start %~1
	timeout 2
	call :flag_state %~1 %~2
	goto flag_type
goto:eof

:flag_stop
	echo   stop %~1
	sc stop %~1
	timeout 2
	call :flag_state %~1 %~2
	goto flag_type
goto:eof

:flag_config
	echo.
	set /p "config=  Please input config key (1 - Automatic, 2 - Manual, 3 - Disabled, 4 - Delayed Auto, R - :Type, Q - Exit) : "

	call :check_exit %config%

	rem 设置服务启动方式 auto - Automatic, demand - Manual, disabled - Disabled, delayed-auto - Automatic (Delayed Start)
	if "%config%" == "1" (
		rem start= 这里需要一个空格
		sc config %~1 start= auto
	) else if "%config%" == "2" (
		sc config %~1 start= demand
	) else if "%config%" == "3" (
		sc config %~1 start= disabled
	) else if "%config%" == "4" (
		sc config %~1 start= delayed-auto
	) else if "%config%" == "R" (
		goto flag_type
	) else (
		goto flag_config
	)
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
	set val=%~1
	for %%i in (A B C D E F G H I J K L M N O P Q R S T U V W X Y Z) do call set val=%%val:%%i=%%i%%
	set %~2=%val%
goto:eof

:lower_case
	set val=%~1
	for %%i in (a b c d e f g h i j k l m n o p q r s t u v w x y z) do call set val=%%val:%%i=%%i%%
	set %~2=%val%
goto:eof

:flag_exit
exit