@echo off
rgbasm.exe -L -o cart.obj  HelloTest.asm
if not "%errorlevel%"=="0" goto Abandon
rgblink.exe -o cart.gb cart.obj
if not "%errorlevel%"=="0" goto Abandon
rem rgbfix.exe -v cart.gb
if not "%errorlevel%"=="0" goto Abandon
pause
VisualBoyAdvance.exe cart.gb
exit
:Abandon
pause