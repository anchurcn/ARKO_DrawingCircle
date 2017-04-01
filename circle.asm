.data
	tekst: .asciiz "Give the radius of the circle: "
	nazwa_pliku: .asciiz "circle.bmp"
	.align 2
	header: .space 56
.text

#$s0 - width/height of image
#$s1 - width of image with excess (multiplies of 4)
#$s2 - address of the image buffer
#$s3 - address to the beginning of the file
#$s4 - the size of the entire image
#$s5 - circle radius

#Message display
	li $v0, 4
	la $a0, tekst
	syscall
	
#Loading the radius of the circle
	li $v0, 5
	syscall
	move $s5, $v0
	
#Calculating image size 
	add $s0, $v0, $v0	#doubling radius and write to $ s0
	addi $s0, $s0, 1	#adding 1 to diameter (middle pixel)
	
#Counting the excess - Rounding up the number of pixels to 4 (up)
	mul $s1, $s0, 3		#number of pixels in image width (3 pixels per bit)
	subi $s1, $s1, 1	#substract 1
	andi $s1, $s1, 0xfffffffc	#bitmask - an integer is formed by dividing $s1 by 4 or in other words AND (* 00) and $s1
	addi $s1, $s1, 4	#Adding 4 to round to 4 
	
#Displaying with excess
	li $v0, 1
	add $a0, $s1, $zero
	syscall
#Preparing header
	la $t0, header		#getting an address to the header buffer, now in t0 is 56 bits
	li $t1, 0x42		#reparing the first character (resulting from the BMP documentation)
	sb $t1, 2($t0)		#write
	li $t1, 0x4D		#secong char
	sb $t1, 3($t0)		
	
#Allocating memory to the image and writing the header
	mul $t1, $s0, $s1	#pixels needed for the entire image - (height) x (width with excess)
	add $s4, $t1, $zero	#remember value for later
	
	li $v0, 9		#allocate byte size (size)
	add $a0, $t1, $zero	
	syscall
	add $s2, $v0, $zero	#remember the address to the allocated memory in $ s2
	
	addi $t1, $t1, 54	#size of the entire file is the size of the image and the headline in $ t1
	sw $t1, 4($t0)		#enter the size of the entire file into the header
	
	li $t1, 54		#54 - data offset (header size)
	sw $t1, 12($t0)		
	li $t1, 40		#40 - length to end of header
	sw $t1, 16($t0)		
	add $t1, $s0, $zero	#copy image width / height
	sw $t1, 20($t0)		#width
	sw $t1, 24($t0)		#height
	li $t1, 1		#1 - number of layers of colors
	sw $t1, 28($t0)		
	li $t1, 24		#24 - number of bits per pixel (3 colors of 8 bits each)
	sb $t1, 30($t0)		
#Opening the file to write
	li $v0, 13		#opening a file
	la $a0, nazwa_pliku	#loading address into file name
	li $a1, 1		#1 - file to read
	li $a2, 0		#0 - flag
	syscall
	add $s3, $v0, $zero	#saving pointer to file in $ s3
#Saving header
	li $v0, 15		
	add $a0, $s3, $zero	#copy pointer to file
	la $a1, header+2	#start of recorded data
	li $a2, 54		#number of bits to save (header size)
	syscall
#Bresenham's algorithm
	add $t0, $s5, $zero 	#coordinate X of circle center (X0) - equal to radius
	move $t1, $t0		#coordinate Y of circle center (Y0) - equal to radius
	li $t2, 5		#5
	mul $t3, $s5, 4		#4*r
	sub $t2, $t2, $t3	#d = 5 - 4*r	
	li $t3, 0		#coordinate X - actual
	move $t4, $t0		#coordinate Y - actual
	mul $t5, $t4, -2 	#deltaA = -2*r
	addi $t5, $t5, 5	#deltaA = 5 + deltaA = (5-2*r)
	mul $t5, $t5, 4		#deltaA = deltaA * r = (5-2*r) * 4
	li $t6, 12		#deltaB = 12

loop:
	bgt $t3, $t4, end	#If X>Y - circle is drawn
	
	#Setting pixel colors:
	#Set the color of 1st pixel
	sub $t7, $t0, $t3	# x0 - x
	sub $t8, $t1, $t4	# y0 - y
	mul $t7, $t7, 3		# *= 3 (3 pixels per point)
	mul $t8, $t8, $s1	# *= size_of_line (moving down)
	add $t7, $t7, $t8	#current pixel position
	add $t7, $t7, $s2	#the position of the pixel relative to the beginning of the file (Adding to the beginning of the file)
	li $v0, 0xff		#black
	sb $v0, ($t7)		#blue
	sb $v0, 1($t7)		#green
	sb $v0, 2($t7)		#red
	#Set the color of 2nd pixel
	sub $t7, $t0, $t3	#x0 - x
	add $t8, $t1, $t4	#y0 + y
	mul $t7, $t7, 3 	# *= 3
	mul $t8, $t8, $s1 	# *= size_of_the_line
	add $t7, $t7, $t8
	add $t7, $t7, $s2
	li $v0, 0xff
	sb $v0, ($t7)
	sb $v0, 1($t7)
	sb $v0, 2($t7)
	#Set the color of 3rd pixel
	add $t7, $t0, $t3	#x0 + x
	sub $t8, $t1, $t4 	#y0 - y
	mul $t7, $t7, 3 	# *= 3
	mul $t8, $t8, $s1 	# *= size_of_the_line
	add $t7, $t7, $t8
	add $t7, $t7, $s2
	li $v0, 0xff
	sb $v0, ($t7)
	sb $v0, 1($t7)
	sb $v0, 2($t7)
	#Set the color of 4th pixel
	add $t7, $t0, $t3 	#x0 + x
	add $t8, $t1, $t4 	#y0 + y
	mul $t7, $t7, 3 	# *= 3
	mul $t8, $t8, $s1 	# *= size_of_the_line
	add $t7, $t7, $t8
	add $t7, $t7, $s2
	li $v0, 0xff
	sb $v0, ($t7)
	sb $v0, 1($t7)
	sb $v0, 2($t7)
	#Set the color of 5th pixel
	sub $t7, $t0, $t4 	#x0 - y
	sub $t8, $t1, $t3 	#y0 - x
	mul $t7, $t7, 3 	# *= 3
	mul $t8, $t8, $s1 	# *= size_of_the_line
	add $t7, $t7, $t8
	add $t7, $t7, $s2
	li $v0, 0xff
	sb $v0, ($t7)
	sb $v0, 1($t7)
	sb $v0, 2($t7)
	#Set the color of 6th pixel
	sub $t7, $t0, $t4 	#x0 - y
	add $t8, $t1, $t3 	#y0 + x
	mul $t7, $t7, 3 	# *= 3
	mul $t8, $t8, $s1 	# *= size_of_the_line
	add $t7, $t7, $t8
	add $t7, $t7, $s2
	li $v0, 0xff
	sb $v0, ($t7)
	sb $v0, 1($t7)
	sb $v0, 2($t7)
	#Set the color of 7th pixel
	add $t7, $t0, $t4 	#x0 + y
	sub $t8, $t1, $t3 	#y0 - x
	mul $t7, $t7, 3 	# *= 3
	mul $t8, $t8, $s1 	# *= size_of_the_line
	add $t7, $t7, $t8
	add $t7, $t7, $s2
	li $v0, 0xff
	sb $v0, ($t7)
	sb $v0, 1($t7)
	sb $v0, 2($t7)
	#Set the color of 8th pixel
	add $t7, $t0, $t4 	#x0 + y
	add $t8, $t1, $t3 	#y0 + x
	mul $t7, $t7, 3 	# *= 3
	mul $t8, $t8, $s1 	# *= size_of_the_line
	add $t7, $t7, $t8
	add $t7, $t7, $s2
	li $v0, 0xff
	sb $v0, ($t7)
	sb $v0, 1($t7)
	sb $v0, 2($t7)
	#Pixel colors set
	
	bgtz $t2, d0		# d > 0   
	# d <= 0
	add $t2, $t2, $t6	# d += deltaB
	addi $t3, $t3, 1	# x += 1
	addi $t5, $t5, 8	# deltaA += 2*4
	addi $t6, $t6, 8	# deltaB += 2*4
	b move		
d0:
	# d > 0
	add $t2, $t2, $t5	#d += deltaA
	subi $t4, $t4, 1	#y -= 1
	addi $t3, $t3, 1	#x += 1
	addi $t5, $t5, 16	#deltaA += 4*4
	addi $t6, $t6, 8	#deltaB += 2*4
move:
	b loop			#jump to the next step
end:
#Saving the rest of the file
	li $v0, 15		#save
	add $a0, $s3, $zero	#copy pointer to file
	add $a1, $s2, $zero	#copy address of buffer
	add $a2, $s4, $zero	#copy number of image pixels
	syscall
#Closing
	li $v0, 16		
	add $a0, $s3, $zero	#copy pointer to file
	syscall
#Finish the program
	li $v0, 10		
	syscall
