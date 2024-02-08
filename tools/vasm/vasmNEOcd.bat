@echo off 
if not exist \Emu\mame0200b_32bit\mame.exe goto EmulatorFail

set BuildFile=%1
set BuildPath=%2
if exist \utils\SelectedBuildFile.bat call \utils\SelectedBuildFile.bat 

cd %BuildPath%
if not %BuildPath:~0,1%==%CD:~0,1% goto InvalidPath


if not exist \RelNEO\roms\neocdz.zip goto MissingRom

\Utils\Vasm\vasmm68k_mot_win32.exe %BuildFile% -chklabels -nocase -Fbin -m68000 -no-opt -Dvasm=1  -L \BldNEO\Listing.txt -DBuildNEO=1  -DBuildNEO_CD=1 -o "\BldNEO\CD\GAME.PRG"

if not "%errorlevel%"=="0" goto Abandon

del "\RelNEO\roms\ChibiAkumasGameCD\ChibiAkumasGameCD.chd"

cd \BldNEO\CD\

rem Build an ISO
\Utils\mkisofs -iso-level 1 -o \RelNEO\roms\ChibiAkumasGameCD\ChibiAkumasGameCD.iso -pad -N -V "ChibiAkumas.com" *.*
if not "%errorlevel%"=="0" goto Abandon

rem Convert the ISO to a CHD
\Emu\mame0200b_32bit\chdman createcd -i "\RelNEO\roms\ChibiAkumasGameCD\ChibiAkumasGameCD.iso" -o "\RelNEO\roms\ChibiAkumasGameCD\ChibiAkumasGameCD.chd"

rem Use CHDMAN to get the hash for the CHD
\Emu\mame0200b_32bit\chdman.exe info -i  "\RelNEO\roms\ChibiAkumasGameCD\ChibiAkumasGameCD.chd" >\RelNEO\hash\hash.txt

rem Patch the hash into the MAME XML
\Utils\MakeNeoGeoHash.exe "\RelNEO\hash\neocd.xml.template" "\RelNEO\hash\neocd.xml" "\RelNEO\roms\ChibiAkumasGameCD" "\RelNEO\hash\hash.txt"


cd \Emu\mame0200b_32bit
mame neocdz ChibiAkumasGameCD -video gdi -skip_gameinfo



rem mame neogeo Grime -video gdi -skip_gameinfo


goto Abandon

:MissingRom
echo No Neogeo Rom found.
echo put a MAME neocdz.zip file in \RelNEO\roms and try again!

:InvalidPath
echo Error: ASM file must be on same drive as devtools 
echo File: %BuildPath%\%BuildFile% 
echo Devtools Drive: %CD:~0,1% 
goto Abandon


:EmulatorFail
echo Error: Can't find \Emu\mame0200b_32bit\mame.exe
:Abandon
if "%3"=="nopause" exit
pause
