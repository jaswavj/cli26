@echo off
setlocal EnableDelayedExpansion

set MYSQL_PATH=C:\Program Files\MySQL\MySQL Server 8.4\bin
set BACKUP_PATH=D:\backup
set DB_NAME=sunmart
set USER=root
set PASS=swift

:: Create date & time safely (YYYY-MM-DD_HH-MM)
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set dt=%%I
set DATESTR=%dt:~0,4%-%dt:~4,2%-%dt:~6,2%
set TIMESTR=%dt:~8,2%-%dt:~10,2%

:: Take backup
"%MYSQL_PATH%\mysqldump.exe" -u%USER% -p%PASS% --column-statistics=0 %DB_NAME% > "%BACKUP_PATH%\backup_%DATESTR%_%TIMESTR%.sql"

:: Keep only last 2 backups
set COUNT=0
for /f "delims=" %%F in ('dir "%BACKUP_PATH%\backup_*.sql" /b /o-d') do (
    set /a COUNT+=1
    if !COUNT! GTR 2 del "%BACKUP_PATH%\%%F"
)

echo Backup completed successfully.
endlocal

