# x86 Mini Bootloader

A minimal x86 bootloader written in 16-bit real mode assembly (NASM)

## What it does:

1. Sets up data and stack segments and an 8k stack
2. Clears the screen via `int 0x10`
3. Moves the cursor to the top-left corner
4. Prints `yay asm` to the screen via BIOS teletype output
5. Halts the CPU

## Files

- `boot.asm` — the bootloader source, heavily commented beacuse why not (its tough to understand :sob: )
- `bochsrc.txt` — Bochs emulator configuration used to run it locally

## Dependencies

- [NASM](https://www.nasm.us/)
- [Bochs](https://bochs.sourceforge.io/)
```bash
# macOS (Homebrew)
brew install nasm bochs

# Ubuntu / Debian
sudo apt install nasm bochs bochs-sdl

# Arch
sudo pacman -S nasm bochs
```

## Build & Run

`bochsrc.txt` locates the BIOS/VGA ROM files via `$BXSHARE`, so set that to
wherever Bochs installed its shared files before running:
```bash
# macOS (Homebrew)
export BXSHARE=$(brew --prefix bochs)/share/bochs
# Linux
export BXSHARE=/usr/share/bochs

nasm -f bin boot.asm -o boot.com
bochs -f bochsrc.txt
```

Choose `6` at the Bochs menu to begin simulation. You should see the screen
clear and `yay asm` printed in the top left corner, then the CPU halts.
