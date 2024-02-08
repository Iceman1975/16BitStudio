
echo File: %BuildFile% 

if not exist ..\emulators\Steem\Steem.exe goto EmulatorFail

set BuildFile=%1
set BuildPath=%2


vasmm68k_mot_win32.exe %BuildFile% -chklabels -nocase -Dvasm=1  -L %BuildPath%\Listing.txt -DBuildAST=1 -Felf -o "%BuildPath%Prog.ELF"

vlink.exe %BuildPath%Prog.ELF -oProg.tos -bataritos


copy Prog.tos \RelAST

rem Restore settings
copy \Emu\Steem\Restore_auto.sts \Emu\Steem\auto.sts
copy \Emu\Steem\Restore_Steem.ini \Emu\Steem\Steem.ini

\Emu\Steem\Steem.exe

goto Abandon


:InvalidPath
echo Error: ASM file must be on same drive as devtools 
echo File: %BuildPath%\%BuildFile% 
echo Devtools Drive: %CD:~0,1% 
goto Abandon


:EmulatorFail
echo Error: Can't find \Emu\Steem\Steem.exe
:Abandon
if "%3"=="nopause" exit
pause
