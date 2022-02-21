@echo off
:: 声明一个用于转换的测试字符串
set SHEET_NAME_LOWER="DirtyConf"
echo.
echo             转化前: %SHEET_NAME_LOWER%
for %%i in (a b c d e f g h i j k l m n o p q r s t u v w x y z) do call set SHEET_NAME_LOWER=%%SHEET_NAME_LOWER:%%i=%%i%%
echo.
echo             转化为小写: %SHEET_NAME_LOWER%
for %%i in (A B C D E F G H I J K L M N O P Q R S T U V W X Y Z) do call set SHEET_NAME_LOWER=%%SHEET_NAME_LOWER:%%i=%%i%%
echo.
echo             转化为大写: %SHEET_NAME_LOWER%
pause