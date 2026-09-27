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

; calling a function with arguments
; the caller pushes each argument onto the stack before calling
; call itself pushes the return address (2 bytes in real mode) onto the stack
; the callee is responsible for reading args back off the stack using bp
; after the callee returns, the caller must clean up any pushed args
; by moving sp back up, since the callee doesn't know how many args to remove
; here we do this with "add sp, 2" for each 2-byte arg pushed
call clearscreen

push 0x0000
call movercursor
add sp, 2

push msg 
call print
add sp, 2

; cli disables interrupts (sets IF=0)
; hlt stops the cpu until the next interrupt fires
; with interrupts disabled, no interrupt can ever fire again
; so this permanently halts the cpu - the intended way to stop a bootloader
; once its job is done, rather than falling through into garbage bytes
cli
hlt

; a function's stack frame
; push bp saves the caller's base pointer so we can restore it later
; mov bp, sp fixes bp at the top of our frame, giving us a stable
; reference point to find both our arguments (above bp) and any
; locals we might push (below bp), even as sp itself moves around
; pusha saves all general purpose registers, since int 0x10 clobbers
; ax/bx/cx/dx, and we don't want to corrupt whatever the caller had in them
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

  ; popa restores the general purpose registers we saved
  ; mov sp, bp / pop bp unwinds our stack frame back to how
  ; it looked before we entered this function
  popa
  mov sp, bp
  pop bp
  ret

; reading an argument off the stack
; right after our prologue (push bp; mov bp, sp), the stack above bp looks like:
;   bp + 0 -> old bp (just pushed)
;   bp + 2 -> return address (pushed by call, 2 bytes in real mode)
;   bp + 4 -> the first argument the caller pushed
; so [bp + 4] reads that 2-byte argument back into a register
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

; printing a null terminated string
; the caller pushes a pointer (offset) to the first character of the string
; we read that pointer into si, then walk forward one byte at a time
; each byte is loaded into al and sent to the bios teletype interrupt
; a null byte (0x00) marks the end of the string, so we test for it
; and jump out of the loop once we hit it, instead of printing forever
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

; a label pointing at raw bytes in memory
; db places these bytes directly into the assembled binary
; the trailing 0 is the null terminator print looks for above
msg:
  db "yay asm", 0

; every boot sector must be exactly 512 bytes, ending in the signature 0xAA55
; $ is the address of this line, $$ is the address of the start of the section
; so $-$$ is how many bytes we've assembled so far
; we pad with zeroes until we're 510 bytes in, then append the 2-byte signature
; BIOS checks for 0xAA55 at bytes 510-511 to decide whether this disk is bootable
times 510-($-$$) db 0
dw 0xAA55
