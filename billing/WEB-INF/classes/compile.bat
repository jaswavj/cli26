@echo off
setlocal EnableDelayedExpansion
cd /d "%~dp0"

set "CP=."
for %%J in ("..\lib\*.jar") do set "CP=!CP!;%%~fJ"

if "%~1"=="" (
    echo Compiling all Java sources...
    javac -encoding UTF-8 -cp "!CP!" billing\*.java cheque\*.java currency\*.java path\*.java print\*.java product\*.java user\*.java util\*.java
) else (
    echo Compiling %*
    javac -encoding UTF-8 -cp "!CP!" %*
)

if errorlevel 1 (
    echo.
    echo COMPILE FAILED
    exit /b 1
)

echo.
echo COMPILE OK
exit /b 0
