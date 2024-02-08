@echo off 
if not exist  \Emu\Q-emuLator\QemuLator.exe goto EmulatorFail

set BuildFile=%1
set BuildPath=%2
if exist \utils\SelectedBuildFile.bat call \utils\SelectedBuildFile.bat 

cd %BuildPath%
if not %BuildPath:~0,1%==%CD:~0,1% goto InvalidPath



\Utils\Vasm\vasmm68k_mot_win32.exe %BuildFile% -chklabels -nocase -Dvasm=1  -L \BldSQL\Listing.txt -DBuildSQL=1 -Fbin -o "\RelSQL\prog_bin"

rem -no-opt
rem  -gbz80 -Fbin -o "z:\BldMSX\boot.bin" -L Z:\RelGB\Listing.txt
if not "%errorlevel%"=="0" goto Abandon

rem cd \Emu\QLAY2\
rem \Emu\QLAY2\qlay2.exe

cd \Emu\Q-emuLator

QemuLator.exe Untitled.QCF


rem cd \Emu\zesarux
rem zesarux.exe --machine QL --enable-ql-mdv-flp  --ql-mdv1-root-dir \RelSQL\

goto Abandon

:InvalidPath
echo Error: ASM file must be on same drive as devtools 
echo File: %BuildPath%\%BuildFile% 
echo Devtools Drive: %CD:~0,1% 
goto Abandon


:EmulatorFail
echo Error: Can't find \Emu\Q-emuLator\QemuLator.exe
:Abandon
if "%3"=="nopause" exit
pause
