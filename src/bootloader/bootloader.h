TEMP_BUFFER_BASE	equ 0060h
FAT_BASE			equ 0600h

KERNEL_LOADED 		equ 1000h
KERNEL_OFFSET		equ 0000h
BOOT_OFFSET 		equ 7c00h


DIRITEM_SIZE			equ 20h
FILEITEM_NAME 			equ 00h
FILEITEM_EXTEND			equ 08h
FILEITEM_ATTR   		equ 0bh
FILEITEM_RESERVED 		equ 10h
FILEITEM_WRITETIME 		equ 16h
FILEITEM_WRITEDATE	 	equ 18h
FILEITEM_FIRSTCLUSTER	equ 1ah
FILEITEM_FILESIZE		equ 1ch
FULLFILENAME_LEN		equ 0bh

nStartSectOfData		equ (bp-0x0a)
nSectCountOfRootdir		equ (bp-0x08)
nStartSectOfRootdir		equ (bp-0x06)
nStartSectOfFat			equ (bp-0x04)
bootdrv					equ (bp-0x02)
;=====================================================================