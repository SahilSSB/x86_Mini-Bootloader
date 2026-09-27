; writing a stack

; segment registers that are used to store 64k segment
; in real mode cpu uses 16 bit registers
; but cpu can address 20bit addresses
; since we cant fit 20 bit addresses in 16bit reg, we split them into 2 16bit regs
; physical address = segment * 0x10 + OFFSET (leftshifting 4bits / dividing by 16)
; a 16bit segment left shifted by 4bits gives you up to 20bits
; adding a 16bit offset lets us reach any byte in that 1mb space
bits 16

mov ax, 0x7C0           
mov ds, ax            ; ds is a register for data segment

mov ax, 0x7E0         ; bootloader extends from 0x7C00 for 512bytes to 0x7E00
mov ss, ax            ; ss is stack segment

; stack pointer decreases
; set the init stack pointer to no. of bytes past stack segment
; this should be equal to desired size of stack
; we make 8k stack by setting sp to 0x2000
mov sp, 0x2000

call clearscreen

push 0x0000
call movercursor
add sp, 2

push msg 
call print
add sp, 2

cli
hlt

clearscreen:
  push bp
  mov bp, sp
  pusha 

  mov ah, 0x07        ; tells BIOS to scroll down window
  mov al, 0x00        ; clears entire window
  mov bh, 0x07        ; whitespace on black ; bh is the bios color attribute
  mov cx, 0x00        ; specifies top left of screen as (0,0)
  mov dh, 0x18        ; 18h = 24 rows of chars
  mov dl, 0x4f        ; 4fh = 79 col of chars
  int     0x10        ; calls video interrupt

  popa
  mov sp, bp
  pop bp
  ret

movercursor:
  push bp
  mov bp, sp
  pusha

  mov dx, [bp + 4]    ; get the argument from the stack. |bp| = 2. |arg| = 2
  mov ah, 0x02        ; set cursor positionn
  mov bh, 0x00        ; page 0 - doesn't matter, not using double buffering
  int     0x10

  popa 
  mov sp, bp
  pop bp
  ret

print:
  push bp
  mov bp, sp
  pusha
  mov si, [bp+4]
  mov bh, 0x00
  mov bl, 0x00
  mov ah, 0x0E
.char:
  mov al, [si]
  add si, 1
  or al,  0
  je      .return 
  int     0x10
  jmp     .char
.return:
  popa
  mov sp, bp
  pop bp
  ret

msg:
  db "yay asm", 0

times 510-($-$$) db 0
dw 0xAA55
