@echo off

set HOME_ROOT=%~dp0
set FASM_RUTA=%HOME_ROOT%tools\Flat Assembler\FASM.EXE
set SRC_ROOT=%HOME_ROOT%src\
set SRC_APPS=%SRC_ROOT%apps\
set OUT_ROOT=%HOME_ROOT%out\
set IMG_ROOT=%HOME_ROOT%image\
set IMG_PATH=%IMG_ROOT%plewos.img
set BOCHS_SCRIPT=%IMG_ROOT%bochsrc.bxrc
set BOCHS_SCRIPT2=%IMG_ROOT%GUIdebug.bxrc
set OUT_APPS=%OUT_ROOT%bin\
set MTOOL_ROOT=%HOME_ROOT%tools\mtools\

cd /d %HOME_ROOT%

rmdir /s /q %OUT_ROOT%
rmdir /s /q %IMG_ROOT%
rmdir /s /q %OUT_APPS%

if not exist "%OUT_ROOT%" mkdir "%OUT_ROOT%"
if not exist "%OUT_APPS%" mkdir "%OUT_APPS%"
if not exist "%IMG_ROOT%" mkdir "%IMG_ROOT%"

call "%FASM_RUTA%" "%SRC_ROOT%bootloader\bootloader.asm" -s "%OUT_ROOT%bootloader.sym" "%OUT_ROOT%bootloader"
if not %errorlevel% == 0 (
	goto _l_end
)
echo.

call "%FASM_RUTA%" "%SRC_ROOT%kernel\pkernel.asm" -s "%OUT_ROOT%pkernel.sym" "%OUT_ROOT%pkernel.bin"
if not %errorlevel% == 0 (
	goto _l_end
)

call "%FASM_RUTA%" "%SRC_ROOT%shell\shell.asm" -s "%OUT_ROOT%shell.sym" "%OUT_ROOT%shell"
if not %errorlevel% == 0 (
	goto _l_end
)

for /R "%SRC_APPS%" %%i in (*.asm) do (
	call "%FASM_RUTA%" "%%i" -s "%OUT_APPS%%%~ni.sym" "%OUT_APPS%%%~ni"
)

"%MTOOL_ROOT%mformat.exe" -f 1440 -v plewosOSVOL -B "%OUT_ROOT%bootloader" -C -i "%IMG_PATH%" ::
if not %errorlevel% == 0 (
	goto _l_end
)	

"%MTOOL_ROOT%mcopy.exe" -i "%IMG_PATH%" "%OUT_ROOT%pkernel.bin" ::
if not %errorlevel% == 0 (
	goto _l_end
)

"%MTOOL_ROOT%mcopy.exe" -i "%IMG_PATH%" "%OUT_ROOT%shell" ::
if not %errorlevel% == 0 (
	goto _l_end
)

"%MTOOL_ROOT%mmd.exe"   -i "%IMG_PATH%" ::bin
if not %errorlevel% == 0 (
	goto _l_end
)

"%MTOOL_ROOT%mcopy.exe" -i "%IMG_PATH%" "%OUT_ROOT%bin\*" ::bin
if not %errorlevel% == 0 (
	goto _l_end
)

echo floppya: type=1_44, 1_44="%IMG_PATH%", status=inserted, write_protected=1 > %BOCHS_SCRIPT%
echo display_library: win32, options="gui_debug" >> %BOCHS_SCRIPT2%
echo floppya: type=1_44, 1_44="%IMG_PATH%", status=inserted, write_protected=1 >> %BOCHS_SCRIPT2%
echo Completado satisfactoriamente!

exit

:_l_end
echo +OCURRIO UN ERROR
pause