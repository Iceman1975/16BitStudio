@echo off 
cd %2
\Utils\Vasm\vasmZ80_OldStyle_win32.exe %1  -chklabels -nocase -Dvasm=1  -L \BldGEN\ListingZ80.txt -Fbin -o "\BldGEN\z80prog.bin"
if not "%errorlevel%"=="0" goto Abandon
exit
:Abandon
if "%3"=="nopause" exit
pause
