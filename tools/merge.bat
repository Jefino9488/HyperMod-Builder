@echo off
setlocal enabledelayedexpansion

set "outputFile=_fastboot.zip"
set "progress=0"
set "totalFiles=0"

rem Count total number of files
for %%i in (*_fastboot-split.zip*) do (
    set /a totalFiles+=1
)

echo Merging %totalFiles% files into "%outputFile%"

for %%i in (*_fastboot-split.zip*) do (
    set "filename=%%~ni"
    set "filename=!filename:_fastboot-split=!"

    echo Merging "!filename!!outputFile!"
    type "%%i" >> "!filename!!outputFile!"

    set /a progress+=1
    echo Merged !progress! out of %totalFiles% files
)

echo Merging complete! Output file: %outputFile%
endlocal
pause
