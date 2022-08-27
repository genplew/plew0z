include 'bootloader.h'

use16
    org BOOT_OFFSET

    jmp short Inicio						;jmp to Main code
    nop									;nop
	bsOEMString		db "PLEWOSV2"		; OEM String,8 bytes ASCII code
    bsSectSize		dw 0x0200 		    ; Bytes per sector
    bsClusterSize	db 0x01				; Sectors per cluster
    bsReservedSect	dw 0x0001			; # of reserved sectors
    bsFatCount		db 0x02				; # of fat
    bsRootDirSize	dw 0x00e0 		    ; size of root directory
    bsTotalSect		dw 0x0b40		    ; total # of sectors if < 32 meg
    bsMediaType		db 0xf0				; Media Descriptor
    bsSectPerFat	dw 0x0009			; Sectors per FAT
    bsSectPerTrack	dw 0x0012			; Sectors per track
    bsHeadCount		dw 0x0002			; number of read-write heads
    bsHiddenSect	dd 0x00000000		; number of hidden sectors
    bsHugeSect		dd 0x00000000		; if bsTotalSect is 0 this value is the number of sectors
    bsBootDrv		db 0x00				; holds drive that the bs came from
					db 0x00				; not used for anything
    bsBootSign		db 0x29 		    ; boot signature 29h
    bsVolumeID		dd 0x0214FABE		; Disk volume ID also used for temp sector # / # sectors to load
    bsVolumeLabel	db 'PLEWOS V2.0'	; Volume Label
    bsFSType		db 'FAT12    ' 	  	; File System type <- FAT 12 File system

;code_start
Inicio:
	xor ax, ax
	mov ds, ax						;set data segment register
    mov es, ax						;set extend segment register
	mov ss, ax						;set stack segment register
	
	mov bp, BOOT_OFFSET ;0x7c00
	mov sp, bp 						;set top-pointer of stack[stack size[501h~7bffh]]
	
;======================================================================
;read disk infomation into stack
	movzx dx, byte [bsBootDrv] ; 0
	push dx							;bootDrv
	
	mov esi, [bsHiddenSect] ; 0
	add si, [bsReservedSect] ; 1
	push si							;nStartSectOfFat
	
	xor ax, ax
	mov al, [bsFatCount] ;2
	mul byte [bsSectPerFat] ; al=18       2*9
	add si, ax ; si=19    1+18
	push si							;nStartSectOfRootdir
	
	mov ax, [bsRootDirSize] ;e0
	mov bx, DIRITEM_SIZE ;20
	mul bx ; ax=0x1c00   ax*bx 
	mov bx, [bsSectSize] ;200
	div bx ;ax=14        ax/bx
	cmp dx, 0
	je .noextra
	inc ax
.noextra:
	push ax							;nSectCountOfRootdir
	
	add si, ax ;si=33 19+14
	push si							;nStartSectOfData
	
	mov ax, [bsSectSize] ;ax=512
	movzx bx, byte [bsClusterSize] ;1
	;mul bx creo que sobra
	mov [wClusterBytes], ax
	mov ax, 0002h
	int 10h

	;======================================================================
	;FindKernelImage
	push es
	pusha	
	mov ax, TEMP_BUFFER_BASE ;ax=60h
	mov es, ax
	mov dx, [nSectCountOfRootdir] ;0Eh
	mov ax,	[nStartSectOfRootdir] ;13h
.readrootdir_loop:
	xor bx, bx
	mov cx, 01h
	call LoadnSector
	jnc .readrootdir_ok
	jmp .final_retfind
.readrootdir_ok:
	xor di, di
	mov si, kernelfilename
.search_loop:
	push di
	push si
	mov cx, FULLFILENAME_LEN ;cx=000bh
	cld
	repe cmpsb
	pop si
	pop di
	jz .search_end			;ok find the image file
	add di, 20h
	sub byte [es:di], 0	
	jnz .search_loop		;continue searching next file item
	inc ax
	dec dx
	jnz .readrootdir_loop
	stc						;not find the image file
	jmp .final_retfind
.search_end:
	clc
	mov ax, [es:di+FILEITEM_FIRSTCLUSTER] ;ax=0002h
	mov [wCurClusterNo], ax
.final_retfind:
	jc .error
	
	;LoadFat
	mov ax, FAT_BASE ;ax= 0600h
	mov es, ax
	xor bx, bx
	mov cx, [bsSectPerFat] ;0009h
	mov ax, [nStartSectOfFat] ;0001h
	call LoadnSector
	jc .error
	
	;LoadKernelImage
	mov ax, KERNEL_LOADED ;ax= 1000h
	mov es, ax
	xor bx, bx
	mov dx, bx ;se puede cambiar con xor dx, dx
.readimg_loop:
	mov ax, [wCurClusterNo] ;ax=0002h
	sub ax, 02h ;ax=0000h
	add ax, [nStartSectOfData] ;ax=0021h
	mov bx, dx
	mov cl, [bsClusterSize] ;cl=01h   cx=0001h
	call LoadnSector
	jc .final_retload
	mov ah, 0eh
	mov al, '.' ;ax=0E2Eh
	mov bl, 0fh
	int 10h
	call NextClusterNumber
	cmp [wCurClusterNo], 0ff8h
	jae .final_retload
	add dx, [wClusterBytes]
	jmp .readimg_loop
.final_retload:
	popa
	pop es
	jc .error
	
	mov dx, 03f2h					;Kill floppy motor
	mov al, 0
	out dx, al
	
	;jmp KERNEL_LOADED:KERNEL_OFFSET
	push word KERNEL_LOADED
	push word KERNEL_OFFSET
	retf
	
.error:
	mov si, error_boot
	call PrintStr
    jmp $
Main_end:
;=========================================================
;==========================================================================
;Print a string start from the current 
;position of the beam
PrintStr:
	push ax
	push bx
.next_char:
	lodsb
	cmp al, 0
	je .exit_p
	mov ah, 0eh
	xor bh, bh
	int 10h
	jmp .next_char
.exit_p:
	pop bx
	pop ax
	ret
PrintStr_end:
;==========================================================================
;==========================================================================
;(+)[es:bx = buffer to receive the data]
;(+)[ax = number of the start logical sector]
;(+)[cl = count of the sectors to read]
;(-)[cf = 0:failed 1:success]
ERROR_COUNT equ 5
LoadnSector:
	pusha
	push bx
	push cx
	
	mov bx, [bsSectPerTrack] ;0012h
	div bl ;ax=0101h  al/bl  13h/12h   /LoadFat ax=0100h /LoadKernelImage ax=0f01h
	inc ah ;ax=0201h  /en LoadFat ax=0200h /LoadKernelImage ax=1001
	mov cl, ah				;cl=02h sector number /LoadKernelImage cl=10
	
	xor ah, ah
	mov bx, [bsHeadCount] ;bx= 0002h
	div bl ;ax=0100  al/bl 01/02  /LoadFat ax=0000h /LoadKernelImage ax=0100h
	mov ch, al				;ch=00h cylinder number
	mov dh, ah				;dh=01h head number
	
	mov dl, [bsBootDrv]		;dl=00h driver number
	
	pop bx
	mov al, bl				;al=01h sector count ax=0101
	
	pop bx ; bx=0000h /LoadKernelImage bx=0001h
	mov si, ERROR_COUNT ;si=05h

.error_loop:	
	mov ah, 02h ;ax=0201
	int 13h
	jnc .final_ret ;ax=0001
	dec si
	jnz .error_loop
	stc
	
.final_ret:
	popa
	ret
LoadnSector_end:
;==========================================================================
;(+)[ax = current cluster no]
;(-)[ax = next cluster no]
NextClusterNumber:
	push es
	pusha 
	
	mov ax, FAT_BASE ;ax=0600h
	mov es, ax
	
	xor dx, dx
	mov ax, [wCurClusterNo] ;ax=0002h
	mov bx, 03h
	mul bx					;bx=0006h
	mov bx, 02h
	div bx					;ax:0003h  ax/bx
	
	mov si, ax 
	mov ax, [es:si] ;ax=4003h
	test dx, dx 
	jz .even 
.odd:
	shr ax, 04h
.even:
	and ax, 0fffh ;ax=0003h
	
	mov [wCurClusterNo], ax

	popa
	pop es
	ret 
NextClusterNumber_end:
;==========================================================================
;code_end

;data_start:
wCurClusterNo	dw	00h
wClusterBytes 	dw	00h

error_boot db 'Invalid disk!', 0

kernelfilename db 'PKERNEL BIN'

;data_end:
bootsecsig:
     times 512 - 2 - ($ - $$)  db 0
     db 55h, 0aah

