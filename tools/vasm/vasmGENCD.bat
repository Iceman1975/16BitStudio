@echo off 
if not exist \Emu\Fusion\Fusion.exe goto EmulatorFail

set BuildFile=%1
set BuildPath=%2
if exist \utils\SelectedBuildFile.bat call \utils\SelectedBuildFile.bat 

cd %BuildPath%
if not %BuildPath:~0,1%==%CD:~0,1% goto InvalidPath


\Utils\Vasm\vasmm68k_mot_win32.exe %BuildFile% -chklabels -nocase -Dvasm=1  -L \BldGEN\Listing.txt -DBuildGEN=1  -DBuildGENCD=1 -Fbin -o "\BldGen\Boot.bin"

if not "%errorlevel%"=="0" goto Abandon
cd \BldGEN\CDFiles
dir
\Utils\mkisofs -iso-level 1 -o \RelGen\GenCD.iso -G \BldGen\Boot.bin -pad -V "ChibiAkumas.com" *.*
if not "%errorlevel%"=="0" goto Abandon

\Emu\Fusion\Fusion.exe \RelGEN\GenCD.ISO

goto Abandon

:InvalidPath
echo Error: ASM file must be on same drive as devtools 
echo File: %BuildPath%\%BuildFile% 
echo Devtools Drive: %CD:~0,1% 
goto Abandon


:EmulatorFail
echo Error: Can't find \Emu\Fusion\Fusion.exe
:Abandon
if "%3"=="nopause" exit
pause

