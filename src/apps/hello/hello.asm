use32

	org 00h
APP_HEADER:
	db	'PLEWOSAPP000'	;;Signature
	dd	0				;;Reserverd
	dd	APP_START		;;Entry Point
	dd	APP_ARGS		;;Arguments Buffer
	dd	0				;;Reserved

APP_ARGS:
	times (256) db	0 

APP_START:
	mov edi, str_hw
	mov eax, 04h
	int 50h
	
	mov eax, 11h
	int 50h
	
str_hw	db 'Hello, world!', 0