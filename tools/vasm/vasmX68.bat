@echo off 
if not exist \Emu\X68\WinX68kHighSpeed_eng.exe goto EmulatorFail

set BuildFile=%1
set BuildPath=%2
if exist \utils\SelectedBuildFile.bat call \utils\SelectedBuildFile.bat 

cd %BuildPath%
if not %BuildPath:~0,1%==%CD:~0,1% goto InvalidPath

\Utils\Vasm\vasmm68k_mot_win32.exe %BuildFile% -m68000 -chklabels -nocase -Dvasm=1  -L \BldX68\Listing.txt -DBuildX68=1 -Fxfile -o "\BldX68\Prog.x"

rem \Utils\Vasm\vasmm68k_mot_win32.exe %1 -m68000 -chklabels -nocase -Dvasm=1  -L \BldX68\Listing.txt -DBuildX68=1 -Fbin -o "\BldX68\Prog.bin"
rem copy /b \ResX68\template.x+\BldX68\Prog.bin \BldX68\prog.x
rem cd \utils
rem binarytools value32BE length \BldX68\prog.x X:\BldX68\prog.x 12 - 64

if not "%errorlevel%"=="0" goto Abandon
cd \BldX68
cd \utils

NDC.EXE d \RelX68\disk.xdf 0 prog.x
NDC.EXE p \RelX68\disk.xdf 0 \BldX68\prog.x

\Emu\X68\WinX68kHighSpeed_eng.exe

goto Abandon


:InvalidPath
echo Error: ASM file must be on same drive as devtools 
echo File: %BuildPath%\%BuildFile% 
echo Devtools Drive: %CD:~0,1% 
goto Abandon


:EmulatorFail
echo Error: Can't find \Emu\X68\WinX68kHighSpeed_eng.exe 
:Abandon
if "%3"=="nopause" exit
pause
