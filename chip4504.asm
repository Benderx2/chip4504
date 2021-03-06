org 0
; Preset values
%define BYTES_PER_SECTOR 512
%define VERSION_STRING "0.2.1"
;; Memory Map:
;; 0x0000:7C00 - 0x0000:0x7C00 + 512 : Bootloader 
;; 0x2000:0x0 - 0x2000:0xFFFF : Kernel Space
;; 0x3000:0x0 - 0x3000:0xFFFF : CHIP4504 Program Space
;; 0x4000:0x0 - 0x4000:0xFFFF : Kernel Stack Space
[SECTION .text]
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
init:
	mov ax, 0x2000
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	
	mov ax, 0x4000
	mov ss, ax
	mov sp, 0
	
	mov ax, 0x0003
	int 0x10
	
	call os_clear_screen
	
	mov si, intro_string
	call os_print_string
	
	; Get Disk parameters
	cmp dl, 0
	je .no_disk_change
	
	mov byte [disk_id], dl
	push es
	mov ah, 0x08
	int 0x13
	pop es
	and cx, 0x3F
	mov word [disk_sec_per_track], cx
	movzx dx, dh
	add dx, 1
	mov word [disk_sides], dx

.no_disk_change:
	
	xor cx, cx
	xor dx, dx
	
	mov ax, 32
	mul word [no_of_root_entries]
	div word [bytes_per_sector]
	xchg ax, cx
	mov al, byte [number_of_FATs]
	mul word [sectors_per_FAT]
	add ax, word [reserved_sectors]
	mov word [data_sector], ax
	add word [data_sector], cx
	
	call os_floppy_reset
	jnc .disk_ok
	
	call os_floppy_reset
	jnc .disk_ok
	
	mov si, disk_err_string
	call os_halt

.disk_ok:
	
	mov si, disk_ok_string
	call os_print_string

	.complete:
	mov si, console_intro_string
	call os_print_string
	
	mov si, all_ok_string
	call os_print_string
	
	call os_wait_for_key

c4504_ui:
	mov ax, cs
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	
	call os_prepare_UI
	
	call os_gen_file_list
	
	push si
	call os_string_length
	add si, ax
	sub si, 4
	lodsd
	; Check for '.ROM'
	cmp eax, '.ROM'
	jne .not_rom
	pop si
	
	mov ax, 0x3000
	mov bx, 0x0200
	call os_load_file
	
	jmp _chip4504_main
	
.not_rom:
	
	cmp eax, '.TXT'
	jne .not_txt
	pop si
	
	call os_find_file
	
	push bx
	
	mov ax, 0x3000
	mov bx, 0x0000
	call os_load_file
	
	pop bx
	
	jmp view_text_file
	
.not_txt:
	
	pop si
	
	mov dl, 0
	mov dh, 1
	call os_move_cursor
	
	mov si, not_rom_string
	call os_print_string
	
	call os_wait_for_key
	
	jmp c4504_ui
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
os_halt:
	cli
	hlt
	jmp $

%include "ui.asm"
%include "fs.asm"
%include "display.asm"
%include "speaker.asm"
%include "misc.asm"
%include "txtview.asm"
; Generated by SmallerC.
%include "emu.asm"

[SECTION .data]
file_list: times 1024 db 0
intro_string: db '[CHIP4504 Initialised]', 13, 10, 0
disk_ok_string: db '[Disk OK]', 13, 10, 0
disk_err_string: db '[Disk Initialisation Error. Halting]', 13, 10, 0
disk_read_err: db '[Error while reading disk. Halting code :]', 0
console_intro_string: db '[Weclome. CHIP4504 Version: ', VERSION_STRING, ' ]', 13, 10, 0
all_ok_string: db '[Everything OK. Press any key to continue.]', 13, 10, 0
file_convert_err_msg: db '[Unable to convert file name. Error finding file.]', 13, 10, 0
not_rom_string: db '[The file chosen is not a CHIP8 ROM or a TXT file. Press any key to resume.]', 13, 10, 0
