# Program File: EtchASketch.asm
# Author: Alex Torres
# Date:   04/24/2022
# Purpose: This program will utilize the integrated bitmap display
#				to simulate an Etch-a-Sketch program

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

#define a couple values 
.eqv BASEADDRESS 0x10040000 #start of bitmap display
.eqv BOTTOMLEFT 0x10043f00 #bottom left pixel
.eqv TOPRIGHT 0x100400fc #top right pixel
.eqv CENTERADDRESS 0x10042080 #center of bitmap display
.eqv GRAY 0x00808080 #color Gray
.eqv DARKGRAY 0x00a9a9a9 #color DarkGray
.eqv DARKERGRAY 0x005d5d5d # color darkergray
.eqv WHITE 0x00ffffff #color White

.data
	currentAddress: .word 0x10042080 #starting with the current address in the center
	currentColor: .word 0x00ffffff #current color starting off with white
.text
	.globl main #global scope
main:
	jal drawBorder #start off by drawing the border for the display
	
	#color pixel in the center blue
	li $t3, CENTERADDRESS #grab the constant center sddress
	li $t4, WHITE #load the constant for white to a register
	sw $t4, ($t3) #write the pixel white
	
	gameUpdateLoop: #main loop of program
	
		#get keypress from keyboard input
		jal CheckKeyPad
		move $s0, $v0 #move character to a saved rgister
	
		#load valuse in data to s registers
		lw $s1, currentAddress 
		lw $s2, currentColor
		#send the key to the keyboardAction subroutine
		move $a0, $s0 #key in first argument
		move $a1, $s1 #current location in second argument
		move $a2, $s2 #current color in second argument
		jal keyboardAction #jump to the keyboard action to choose what to do
		move $s1, $v0 #move the current location into an s register
		move $s2, $v1  #move the current color into an s register
		sw $s1, currentAddress #store the address back into the data
		sw $s2, currentColor #store the color back into the data
	j 	gameUpdateLoop		# loop back to beginning
	

#subroutine: CheckKeyPad
#author: Alex Torres
#purpose: listens to keyboard input with the MMIO Simulator and retuns the key.
#input: none
#output: character input in $v0	
.text
CheckKeyPad:
	#read the control register at 0xffff0000
	li $t0, 0xffff0000
	checkLoop:
		lw $t1, 0($t0) #read the value of the control register
		andi $t1, 0x1 #anding the control bits with 0x1
		beqz $t1, checkLoop
			#true block
			#otherwise the ready bit is 1 and there is data in the reciver
			#data register 
			lw $v0, 4($t0) #$v0 has the char read
		jr $ra #return to calle address
	
		
#subroutine: drawBorder
#author: Alex Torres
#purpose: Builds the border for our Etch-A-Sketch
#input: none
#output: none
.text		
drawBorder:
   #prolouge
	addi $sp, $sp, -4 #allocate one word of memory
	sw $ra, 0($sp) #push $ra into stack
	
    li $a0, BASEADDRESS #load top border starting location
	jal drawHorizontalBorder #jump to the horizontal border routine
	li $a0, BOTTOMLEFT #load bottom border starting location
	jal drawHorizontalBorder#jump to the horizontal border routine
	li $a0, BASEADDRESS #load left border starting location
	jal drawVerticalBorder#jump to the vertical border routine
	li $a0, TOPRIGHT #load right border starting location
	jal drawVerticalBorder#jump to the vertical border routine
	
	#epilouge
	lw $ra, 0($sp) #pop $ra from stack
	addi $sp, $sp, 4 #deallocate memory from stack pointer
	
	jr $ra #return to calle
	

#subroutine: keyboardAction
#author: Alex Torres
#purpose: decides what action to perform based on keyboard input
#input: Keyboard input in $a0, current address in $a1, current color in $a2
#output: current address in $v0, current color in $v1
.text
keyboardAction:
	#prolouge
	addi $sp, $sp, -4 #allocate one word of memory
	sw $ra, 0($sp) #push $ra into stack
	
	#move argument values into a temprary register
	move $t5, $a0 #key
	move $t3, $a1 #current address
	move $t4, $a2 #current color
	
	beq $t5, 0x64, moveRight	# if key press = 'd' branch to moveright
	beq $t5, 0x61, moveLeft	# else if key press = 'a' branch to moveLeft
	beq $t5, 0x77, moveUp	# if key press = 'w' branch to moveUp
	beq $t5, 0x73, moveDown	# else if key press = 's' branch to moveDown
	beq $t5, 0x71, moveUpLeft	# if key press = 'q' branch to moveUpLeft
	beq $t5, 0x65, moveUpRight	# if key press = 'e' branch to moveUpRight
	beq $t5, 0x7a, moveDownLeft	# if key press = 'z' branch to moveDownLeft
	beq $t5, 0x63, moveDownRight	# if key press = 'c' branch to moveDownLeft
	beq $t5, 0x72, changeToRed #if key press = 'r' branch to changeToRed
	beq $t5, 0x67, changeToGreen #if key press = 'g' branch to changeToGreen
	beq $t5, 0x62, changeToBlue #if key press = 'b' branch to changeToBlue
	beq $t5 0x78, deleteColor #if key press = 'x' branch to deleteColor
	beq $t5 0x30, exitProgram #if key press = '0' branch to exit program
	b exitAction #if the value not in on listed above exit function
	
	#exit program
	exitProgram:
		li $v0, 10 #code to exit cleanly
		syscall #execute
		
	#delete the color of current pixel
	deleteColor:	
		sw $zero, 0($t3) #store that color into that pixel location
		b exitAction #branch to the exitAction 
	
	#change red hexvalue	
    changeToRed: 	
    		srl $t1, $t4, 16 #logical shift right by 16 bits
    		ifMaxRed: #if the red value is 0xff
    			addi $t1, $t1, 6 #Increase red gradient
    			sle $t0, $t1, 0xff #set to true if the red gradient less than maxx amount
    			beqz $t0, resetRed #if the red is maxxed out go to the reserred routine
    			sll $t1, $t1, 16 #else logical shift left by 16 bits
  	  		or $t4, $t4, $t1 #bitwise or for mixing colors
  	  		b endMaxRed #branch to the end oof if statement
  	  	resetRed: #reset red to 0x10
  	  		li $t1, 0x10ffff#set the value of red to 0x10
  	  		and $t4, $t4, $t1 #this only deals with the red value and keeps the original values of other colors
  	  	endMaxRed: #end the if statment
   	 		sw $t4, 0($t3) #store the current color into the current location
    	    b exitAction#branch to the exitAction 
    	    
    changeToGreen:
    		sll $t1, $t4, 16 #logical shift left by 16 bits
    		srl $t1, $t1, 24 #logical shift right by 24 bits
   	 	ifMaxGreen: #if the green value is 0xff
    			addi $t1, $t1, 6 #Increase green gradient
   	 		sle $t0, $t1, 0xff #set to true if the green gradient less than maxx amount
  	  		beqz $t0, resetGreen #if the green is maxxed out go to the resetGreen routine
  	  		sll $t1, $t1, 8 #else logical shift left by 8 bits
   	 		or $t4, $t4, $t1 #bitwise or for mixing colors
  	  		b endMaxGreen #branch to the endMaxGreen routine
 	   	resetGreen: #reset green to 0x10
 	   		li $t1, 0xff10ff #set the value of green to 0x10
   	 		and $t4, $t4, $t1 #this only deals with the green value and keeps the original values of other colors
   	 	endMaxGreen: #end the if statment
    			sw $t4, 0($t3) #store the current color into the current location
    	    b exitAction#branch to the exitAction 
    	    
    changeToBlue:	
    		sll $t1, $t4, 24 #logical shift left by 24 bits
    		srl $t1, $t1, 24 #logical shift left by 24 bits
   	 	ifMaxBlue: #if the blue value is 0xff
    			addi $t1, $t1, 6 #Increase blue gradient
   	 		sle $t0, $t1, 0xff #set to true if the blue gradient less than maxx amount
   	 		beqz $t0, resetBlue #if the blue is maxxed out go to the resetBlue routine
    			or $t4, $t4, $t1 #bitwise or for mixing colors	
   	 		b endMaxBlue #branch to the endMaxBlue routine
   	 	resetBlue: #reset blue to 0x10
   			li $t1, 0xffff10 #set the value of blue to 0x10
    			and $t4, $t4, $t1 #this only deals with the blue value and keeps the original values of other colors
  	 	endMaxBlue: #end the if statment
    			sw $t4, 0($t3) #store the current color into the current location
    	    b exitAction#branch to the exitAction 

	#move upward
    moveUp:
  	  	li $a2, -256 #load immideite value for distance to next pixel
 	   	b moveFunction#branch to the exit
	
	#move downward
    moveDown:
 	   	li $a2, 256 #load immideite value for distance to next pixel
 	   	b moveFunction#branch to the exit
    
    #move left
    moveLeft:
 	   	li $a2, -4 #load immideite value for distance to next pixel
	    	b moveFunction#branch to the exit
    
    #move right
    moveRight:
  	  	li $a2, 4 #load immideite value for distance to next pixel
 	   	b moveFunction#branch to the exit
	
	#move up then left
	moveUpLeft:
 	   	li $a2, -260 #load immideite value for distance to next pixel
 	   	b moveFunction#branch to the exit
    	
    	#move up then right
    	moveUpRight:
  	  	li $a2, -252 #load immideite value for distance to next pixel
 	   	b moveFunction#branch to the exit
    	
    	#move down then left
    	moveDownLeft:
  	  	li $a2, 252 #load immideite value for distance to next pixel
  	  	b moveFunction#branch to the exit
    	
    	#move down then right
    	moveDownRight:
  	  	li $a2, 260 #load immideite value for distance to next pixel
  	  	b moveFunction#branch to the exit
    	
    	#move function that will call on a subroutine to execute movement
    	moveFunction:
  	  	move $a0, $t3 #send address to argument $a0
 	   	move $a1, $t4 #move the current color into $a1
 	   	jal moveIt #jump and link to the moveIt funtion
  	  	move $t3, $v0 #move the current address back into $t3
  	  	move $t4, $v1 #move the current color back into $t4
 	   	b exitAction
    	
    exitAction:
  		move $v0, $t3 #move the current address into the return register
   		move $v1, $t4 #move the current color into the return register
    
    	#epilouge
    	lw $ra, 0($sp) #pop $ra from stack
    	addi $sp, $sp, 4 #deallocate memory from stack pointer
    
    	jr $ra #return to calle

#subroutine: moveIt
#author: Alex Torres
#purpose: perfoms the movment based on the number given
#input: current address $a0,current color $a1 Movement amount $a2
#output: 
.text
moveIt:
	#prolouge
	addi $sp, $sp, -24 #allocate one word of memory
	sw $ra, 0($sp) #push $ra into stack
	sw $t0, 4($sp) #push temporary register into stack
	sw $t1, 8($sp) #push temporary register into stack
	sw $t2, 12($sp) #push temporary register into stack
	sw $t3, 16($sp) #push temporary register into stack
	sw $t4, 20($sp) #push temporary register into stack
	
	move $t3, $a0 #move the current location to $t3
	move $t4, $a1 #move current color to $t4
	move $t5, $a2 #move movement amount to $t5
	
	#check if $t3 is a border pixel
    	move $a0, $t3 #send address to argument $a0
    	move $a1, $t5 #send the next movement value to $a1
    	jal checkBorder #jump and link to check if next movement touches border
    	move $t2, $v0 #move the return value to $t2
    	bnez $t2, exitMove #branch to the exit if its a border
    	add $t3, $t3, $t5 #add the location to the next address
    	#blend the colors
    	move $a0, $t4 #move the current color value into the $a0 register
    	lw $a1, 0($t3) #grab the color value of the next location
    	jal blendColors
    	move $t6, $v0
    	sw $t6, 0($t3) #store that color into that pixel location
    	
    	b exitMove #branch to the exit
    	
    	#finish the moving subroutine
    	exitMove:
    	move $v0, $t3#move the current address into the return register
    move $v1, $t4 #move the current color into the return register

	#epilouge
	lw $ra, 0($sp) #pop $ra from stack
	lw $t0, 4($sp) #pop temporary register from stack
	lw $t1, 8($sp) #pop temporary register from stack
	lw $t2, 12($sp) #pop temporary register from stack
	lw $t3, 16($sp) #pop temporary register from stack
	lw $t4, 20($sp) #pop temporary register from stack
	addi $sp, $sp, 24 #deallocate memory from stack pointer
	
	jr $ra #return to calle

	
#subroutine: blendColors
#author: Alex Torres
#purpose: Gets the color of next value and blends with the current color
#input: current color $a0, Color of next pixel $a1
#output: blended color $v0
.text
blendColors:
	#prolouge
	addi $sp, $sp, -28 #allocate one word of memory
	sw $ra, 0($sp) #push $ra into stack
	sw $t0, 4($sp) #push temporary register into stack
	sw $t1, 8($sp) #push temporary register into stack
	sw $t2, 12($sp) #push temporary register into stack
	sw $t3, 16($sp) #push temporary register into stack
	sw $t4, 20($sp) #push temporary register into stack
	sw $t5, 24($sp) #push temporary register into stack
	
	move $t4, $a0 #move current color $a0 into $t4
	move $t5, $a1 #move next color $a1 into $t5
	
	#check if the next color is empty to avoid blending
	sne $t2, $t5, $zero #sets $t2 to true if $t5 is not equal to 0x00
	beqz $t2, keepColor #branch if $t2 is false
	
	blendRed: #blend the color red
		srl $t0, $t4, 16 #isolate the color red from the current color
		srl $t1, $t5, 16 #isolate the color red from the next pixel color
		#if current color less than next color
		slt $t2, $t0, $t1 #set $t2 to true if the the current color is less than the next color
		beqz $t2, subRedCurrent #branch to subRedCurrent if current color is larger than the next
		subRedNext: #sub the larger color which is the next pixel color
			sub $t3, $t1, $t0 #sub the current color from the next color and store in $t3
			div $t3, $t3, 2 #divide the subtracted number by two
			sub $t1, $t1, $t3 #sub the divided number by  from the larger color value
			sll $t8, $t1, 16 # logical left shift back to the Red location in hex
			b endRedSub #branch to the endRedSub
		subRedCurrent: #sub the larger color which is the current color pixel
			sub $t3, $t0, $t1 #sub the current color from the next color and store in $t3
			div $t3, $t3, 2 #divide the subtracted number by two
			sub $t0, $t0, $t3 #sub the divided number by  from the larger color value
			sll $t8, $t0, 16 # logical left shift back to the Red location in hex
		endRedSub: 
	
	blendGreen: #blend the color Green
		sll $t0, $t4, 16 #isolate the color Green from the current color
		srl $t0, $t0, 24 #isolate the color Green from the current color
		sll $t1, $t5, 16 #isolate the color Green from the next pixel color
		srl $t1, $t1, 24 #isolate the color Green from the next pixel color
		#if current color less than next color
		slt $t2, $t0, $t1 #set $t2 to true if the the current color is less than the next color
		beqz $t2, subGreenCurrent #branch to subGreenCurrent if current color is larger than the next
		subGreenNext: #sub the larger color which is the next pixel color
			sub $t3, $t1, $t0 #sub the current color from the next color and store in $t3
			div $t3, $t3, 2 #divide the subtracted number by two
			sub $t1, $t1, $t3 #sub the divided number by  from the larger color value
			sll $t7, $t1, 8 # logical left shift back to the Green location in hex
			b endGreenSub #branch to the endGreenSub
		subGreenCurrent: #sub the larger color which is the current color pixel
			sub $t3, $t0, $t1 #sub the current color from the next color and store in $t3
			div $t3, $t3, 2 #divide the subtracted number by two
			sub $t0, $t0, $t3 #sub the divided number by  from the larger color value
			sll $t7, $t0, 8 # logical left shift back to the Green location in hex
		endGreenSub: 
		
	blendBlue: #blend the color Blue
		sll $t0, $t4, 24 #isolate the color Blue from the current color
		srl $t0, $t0, 24 #isolate the color Blue from the current color
		sll $t1, $t5, 24 #isolate the color Blue from the next pixel color
		srl $t1, $t1, 24 #isolate the color Blue from the next pixel color
		#if current color less than next color
		slt $t2, $t0, $t1 #set $t2 to true if the the current color is less than the next color
		beqz $t2, subBlueCurrent #branch to subBlueCurrent if current color is larger than the next
		subBlueNext: #sub the larger color which is the next pixel color
			sub $t3, $t1, $t0 #sub the current color from the next color and store in $t3
			div $t3, $t3, 2 #divide the subtracted number by two
			sub $t1, $t1, $t3 #sub the divided number by  from the larger color value
			move $t6, $t1 # move the blue value into the $t6 register
			b endBlueSub #branch to the endBlueSub
		subBlueCurrent: #sub the larger color which is the current color pixel
			sub $t3, $t0, $t1 #sub the current color from the next color and store in $t3
			div $t3, $t3, 2 #divide the subtracted number by two
			sub $t0, $t0, $t3 #sub the divided number by  from the larger color value
			move $t6, $t0 # move the blue value into the $t6 register
		endBlueSub: 
	
	#combine isolated colors into a single hex value	
	or $t6, $t6, $t7 #bitwise or with the blue and green giving us 0x0000xxxx
	or $t6, $t6, $t8 #bitwise or with previous or, giving us 0x00xxxxxx
	move $v0, $t6 #move blended color value into $t6
	b endColorBlend #branch to epilouge
	
	#keeps the original color cause the next pixel is blank
	keepColor:
	move $v0, $t4 #send the current color back into $v0
	
	#finish exiting subroutine
	endColorBlend:
	#epilouge
	lw $ra, 0($sp) #pop $ra from stack
	lw $t0, 4($sp) #pop temporary register from stack
	lw $t1, 8($sp) #pop temporary register from stack
	lw $t2, 12($sp) #pop temporary register from stack
	lw $t3, 16($sp) #pop temporary register from stack
	lw $t4, 20($sp) #pop temporary register from stack
	lw $t5, 24($sp) #pop temporary register from stack
	addi $sp, $sp, 28 #deallocate memory from stack pointer
	
	jr $ra #return to calle
						
#subroutine: checkBorder
#author: Alex Torres
#purpose: checks if next pixel is on the border
#input: starting address $a0, Movement amount $a1
#output: boolean value $v0
.text
checkBorder:
	#prolouge
	addi $sp, $sp, -28 #allocate one word of memory
	sw $ra, 0($sp) #push $ra into stack
	sw $t0, 4($sp) #push temporary register into stack
	sw $t1, 8($sp) #push temporary register into stack
	sw $t2, 12($sp) #push temporary register into stack
	sw $t3, 16($sp) #push temporary register into stack
	sw $t4, 20($sp) #push temporary register into stack
	sw $t5, 24($sp) #push temporary register into stack
	
	move $t0, $a0 #current location
	move $t1, $a1 #movement amount
	add $t0, $t0, $t1 #get location of next move
	
	li $t4, BASEADDRESS #Base address location
	li $t1, 0 #counter
	li $t2, 252# horizontal limit
	li $t5, 0 #boolean touches border
	#horizontal top border check
	startHTBorderCheck:
		sle $t3, $t1, $t2 #set $t2 to true if the counter is greater than 252
		beqz $t3, endHTBorderCheck #branch if $t3 is false
		#if the next pixel is touch a border pixel
		ifPixelTouching:
			seq $t5, $t0, $t4 #sets to true if next pixel $t0 is equal to border address $t4
			beq $t5, 1, endVRBorderCheck #branch to endVRBorderCheck if $t3 is true
		addi $t4, $t4, 4 #move the location register to the next pixel
		addi $t1, $t1, 4 #increase counter by 4 
		b startHTBorderCheck #branch to the next loop
	endHTBorderCheck:
	
	li $t4, BOTTOMLEFT#bottom left location
	li $t1, 0 #counter
	#horizontal Bottom border check
	startHBBorderCheck:
		sle $t3, $t1, $t2 #set $t2 to true if the counter is greater than 252
		beqz $t3, endHBBorderCheck #branch if $t3 is false
		#if the next pixel is touch a border pixel
		ifPixelTouching2:
			seq $t5, $t0, $t4 #sets to true if next pixel $t0 is equal to border address $t4
			beq $t5, 1, endVRBorderCheck #branch to endVRBorderCheck if $t3 is true
		addi $t4, $t4, 4 #move the location register to the next pixel
		addi $t1, $t1, 4 #increase counter by 4 
		b startHBBorderCheck #branch to the next loop
	endHBBorderCheck:
	
	li $t4, BASEADDRESS #Base address location
	li $t1, 0 #counter
	li $t2, 16128# vertical limit
	#vertical Left border check
	startVLBorderCheck:
		sle $t3, $t1, $t2 #set $t2 to true if the counter is greater than 252
		beqz $t3, endVLBorderCheck #branch if $t3 is false
		#if the next pixel is touch a border pixel
		ifPixelTouching3:
			seq $t5, $t0, $t4 #sets to true if next pixel $t0 is equal to border address $t4
			beq $t5, 1, endVRBorderCheck #branch to endVRBorderCheck if $t3 is true
		addi $t4, $t4, 256 #move the location register to the next pixel
		addi $t1, $t1, 256 #increase counter by 256
		b startVLBorderCheck #branch to the next loop
	endVLBorderCheck:
	
	li $t4, TOPRIGHT #top right location
	li $t1, 0 #counter
	li $t2, 16128# vertical limit
	#vertical right border check
	startVRBorderCheck:
		sle $t3, $t1, $t2 #set $t2 to true if the counter is greater than 252
		beqz $t3, endVRBorderCheck #branch if $t3 is false
		#if the next pixel is touch a border pixel
		ifPixelTouching4:
			seq $t5, $t0, $t4 #sets to true if next pixel $t0 is equal to border address $t4
			beq $t5, 1, endVRBorderCheck #branch to endVRBorderCheck if $t3 is true
		addi $t4, $t4, 256 #move the location register to the next pixel
		addi $t1, $t1, 256 #increase counter by 256
		b startVRBorderCheck #branch to the next loop
	endVRBorderCheck:
	
	move $v0, $t5 #move the boolean value into the return register
	
    #epilouge
	lw $ra, 0($sp) #pop $ra from stack
	lw $t0, 4($sp) #pop temporary register from stack
	lw $t1, 8($sp) #pop temporary register from stack
	lw $t2, 12($sp) #pop temporary register from stack
	lw $t3, 16($sp) #pop temporary register from stack
	lw $t4, 20($sp) #pop temporary register from stack
	lw $t5, 24($sp) #pop temporary register from stack
	addi $sp, $sp, 28 #deallocate memory from stack pointer
	
	jr $ra #return to calle
	
	
#subroutine: drawHorizontalBorder
#author: Alex Torres
#purpose: draws border around horizontally on the bitmap display
#input: starting address $a0
#output: none
.text
drawHorizontalBorder:
	#prolouge
	addi $sp, $sp, -4 #allocate one word of memory
	sw $ra, 0($sp) #push $ra into stack
	
	#draw top border
	li $t0, 0 #initialize counter
	li $t1, 248 #set limit of top border
	move $t3, $a0 #the base memory address is in $t3
	li $t4, GRAY			# Load the Gray color word in $t4
	li $t5, DARKGRAY #load the dark gray color into $t5
	li $t6, DARKERGRAY #load the darker gray color into $t6
	startTopBorderLoop: 
		sle $t2, $t0, $t1 #set $t2 to true if the counter is greater than 252
		beqz $t2, endTopBorderLoop #branch to the end of loop if true
		sw $t4, 0($t3) #draw in the color at the $t3 location
		addi $t3, $t3, 4 #move the location register to the next pixel
		sw $t5, 0($t3) #draw in the color at the $t3 location
		addi $t3, $t3, 4 #move the location register to the next pixel
		sw $t6, 0($t3) #draw in the color at the $t3 location
		addi $t3, $t3, 4 #move the location register to the next pixel
		addi $t0, $t0, 12 #increase counter by 4 
		b startTopBorderLoop #restart loop
	endTopBorderLoop:
	
	#epilouge
	lw $ra, 0($sp) #pop $ra from stack
	addi $sp, $sp, 4 #deallocate memory from stack pointer
	
	jr $ra #return to calle
	
#subroutine: drawVerticalBorder
#author: Alex Torres
#purpose: draws border vertically on the bitmap display
#input: starting address $a0
#output: none
.text
drawVerticalBorder:
	#prolouge
	addi $sp, $sp, -4 #allocate one word of memory
	sw $ra, 0($sp) #push $ra into stack
	
	#draw top border
	li $t0, 0 #initialize counter
	li $t1, 16128 #set limit of border
	move $t3, $a0 #the base memory address is in $t3
	li $t4, GRAY			# Load the Gray color word in $t4
	li $t5, DARKGRAY #load the dark gray color into $t5
	li $t6, DARKERGRAY #load the darker gray color into $t6
	startVerticalBorderLoop: 
		sle $t2, $t0, $t1 #set $t2 to true if the counter is greater than 16128
		beqz $t2, endVerticalBorderLoop #branch to the end of loop if true
		sw $t4, 0($t3) #draw in the color at the $t3 location
		addi $t3, $t3, 256 #move the location register to the next pixel
		sw $t5, 0($t3) #draw in the color at the $t3 location
		addi $t3, $t3, 256 #move the location register to the next pixel
		sw $t6, 0($t3) #draw in the color at the $t3 location
		addi $t3, $t3, 256 #move the location register to the next pixel
		addi $t0, $t0, 768 #increase counter by 256
		b startVerticalBorderLoop #restart loop
	endVerticalBorderLoop:
	
	#epilouge
	lw $ra, 0($sp) #pop $ra from stack
	addi $sp, $sp, 4 #deallocate memory from stack pointer
	
	jr $ra #return to calle
