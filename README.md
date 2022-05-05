# Etch_A_Sketch_MIPS_Assembly

This programs uses MIPS assembly language to simulate an Etch A Sketch.

The program has color blend functionality where it isolates the RGB values and computes the average of both colors.

<img src="https://github.com/aimarket/Etch_A_Sketch_MIPS_Assembly/blob/main/bitmap.gif?raw=true" alt="alt text" title="image Title" width="550"/>

```
#DIRECTIONS: 
# Bitmap display settings:
# Unit width in pixels: 8
# Unit Height in pixels: 8
# Display Width in pixels: 512
# Display Height in pixels: 512
# Base address 0x10040000 (heap)
#connect "Bitmap Display" to MIPS
#connect "keyboard and display MMIO Simulator" to MIPS 

#HOW TO USE: 
# w: move up
# a: move left  
# s: move down
# d: move right
# q: move up left
# e: move up right
# z: move down left
# c: move down right
# r: change red gradient
# g: change green gradient
# b: change blue gradient
# x: delete the color 
# 0: Exits program
```
