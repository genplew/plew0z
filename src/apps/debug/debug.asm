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

	mov eax, 0
	mov eax, 1
	
	call func

	jmp $

func:
;;in	al:bcd number
;;		edi:destbuffer to store string
	push ebx
	
	mov ebx, 0
	
	pop ebx
	ret
	