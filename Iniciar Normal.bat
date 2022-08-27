set HOME_ROOT=%~dp0
set IMG_ROOT=%HOME_ROOT%image\
set BOCHS_SCRIPT=%IMG_ROOT%bochsrc.bxrc

cd C:\Program Files\Bochs-2.6.5
bochs -q -f %BOCHS_SCRIPT%