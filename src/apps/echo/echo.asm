use32

	org 00h
APP_HEADER:
	db	'PLEWOSAPP000'	;;00h	Signature
	dd	0				;;0ch	Reserverd		
	dd	APP_START		;;10h	Entry Point
	dd	APP_ARGS		;;14h	Arguments Buffer
	dd	0				;;18h	Reserved

APP_ARGS:
	times (256) db	0 

APP_START:
	mov edi, APP_ARGS
	mov eax, 04h
	int 50h
	
	mov eax, 11h
	int 50h