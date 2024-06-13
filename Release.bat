@echo off
if /i "%~1"=="info" goto info
if /i "%~1"=="install" goto install
echo [1.2]
exit /b

:info
echo Version 1.2
echo - Added automatic Update Tool
exit /b

:install
rem add a line for each piece of software to update
call :get "Prog Assist.ba" "Prog Assist.bat"
echo [96mUpdate finished.[0m
pause
del /f /q "%~0" & "Prog Assist.bat"
exit

:Get
rem call :Get File SaveAs
echo [90mUpdating %~2...
curl -# -H "Accept: application/vnd.github.v3.raw" -L https://api.github.com/repos/%OWNER%/%REPO%/contents/%~1 -o "%~2"
exit /b