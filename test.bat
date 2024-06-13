@echo off


:: Get the JSON data from GitHub API and save it to a temporary file
curl -s -H "Accept: application/vnd.github.v3.raw" -L https://api.github.com/repos/W1BTR/Programming-Assistant/contents/Bin/Files/Vendors > temp.json

:: Use PowerShell to parse the JSON and output the names
for /f "delims=" %%i in ('powershell -Command "Get-Content temp.json | ConvertFrom-Json | ForEach-Object { $_.name }"') do (
    echo %%i
)

:: Clean up temporary file
del temp.json

pause
