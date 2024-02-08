@echo off 
if not exist \Emu\FsUae\Programs\Windows\x86\fs-uae.exe goto EmulatorFail

set BuildFile=%1
set BuildPath=%2
if exist \utils\SelectedBuildFile.bat call \utils\SelectedBuildFile.bat 

cd %BuildPath%
if not %BuildPath:~0,1%==%CD:~0,1% goto InvalidPath

\Utils\Vasm\vasmm68k_mot_win32.exe %BuildFile% -chklabels -nocase -kick1hunks -Fhunkexe -Dvasm=1  -L \BldAMI\Listing.txt -DBuildAMI=1 -o "\RelAMI\start"

if not "%errorlevel%"=="0" goto Abandon
copy \RelAMI\start \RelAMI\w
cd \Emu\FsUae

\Emu\FsUae\Programs\Windows\x86\fs-uae.exe \Emu\FsUae\Configurations\Config.fs-uae


goto Abandon


:InvalidPath
echo Error: ASM file must be on same drive as devtools 
echo File: %BuildPath%\%BuildFile% 
echo Devtools Drive: %CD:~0,1% 
goto Abandon


:EmulatorFail
echo Error: Can't find \Emu\FsUae\Programs\Windows\x86\fs-uae.exe
:Abandon
if "%3"=="nopause" exit
pause
