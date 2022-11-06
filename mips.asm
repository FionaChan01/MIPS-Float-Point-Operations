        .data
hello:   .asciiz "Hello\n"   
hh:   .asciiz "\n"
good:   .asciiz "Good:"
total:   .asciiz "Total:"
godie:   .asciiz "Thank you Bye" 
.text
main:
la    	$a0,	hello			
li    	$v0,	4
syscall
li  $v0, 40           #seed
addi $a0, $0, 10  
syscall
move $s1,$0 
move $s0,$0 # for i=0
mainloop:
beq $s0,100,end# i<100
addi $s0,$s0,1 # i++
jal getrandom#a0放第一个浮点数
move $a1,$a0#a1放第二个浮点数
mov.s $f1,$f0
jal getrandom
jal getadd  #######################  四选一： getadd  getsub  getmul getdiv ##############################
move $a3,$t0
jal yourfunc						#浮点数放在$a0,$a1中，请将计算结果放入$a2中，临时寄存器可以随意修改，其他寄存器改了请恢复
bne $a2,$a3,mainloop
addi $s1,$s1,1
j mainloop

yourfunc:

	subi	$sp,	$sp,	-8
	sw  	$s3,	4($sp)
	sw  	$s7,	0($sp)	
	
	
	beqz	$a0,	AEQZ				#若第一个数为0，跳转
					
	beqz	$a1,	BEQZ	            #若第一个数不为0，第二个数为0，跳转
    
	j		NOZERO
AEQZ:
	beqz	$a1,	ABEQZ				#若B也为0，跳转
	addi	$a2,	$a1,	0			#将最终结果B存入s4中
	j		OUTPUTZ

BEQZ:	
	addi	$a2,	$a0,	0			#将最终结果A存入s4中
	j		OUTPUTZ

ABEQZ:	
	addi	$a2,	$zero,	0			#将最终结果0存入s4中
	j		OUTPUTZ


NOZERO:
    andi	$t0,	$a0,	0x80000000		
	srl	    $t0,	$t0,	31 			#取符号位
	andi	$t1,	$a1,	0x80000000
	srl	    $t1,	$t1,	31 			#取符号位
	
	
	andi	$t2,	$a0,	0x7f800000
	srl	    $t2,	$t2,	23
	andi	$t3,	$a1,	0x7f800000
	srl	    $t3,	$t3,	23			#取阶码
	
	
	andi	$t4,	$a0,	0x007fffff
	ori   	$t4,	$t4,	0x00800000
	andi	$t5,	$a1,	0x007fffff
	ori	    $t5,	$t5,	0x00800000		#取尾数

    bne	    $t2,	$t3,	matchExponent
		

matchExponent:
	sltu	$t6,	$t2,	$t3			#比较阶数
	beqz	$t6,	AGTB				#跳到A大于B的情况
	sub	    $t6,	$t3,	$t2			#得到阶数差
	srlv	$t4,	$t4,	$t6			#尾数右移对阶
	add  	$t2,	$t2,	$t6			#对阶
	j	compareSign

AGTB:	
	sub  	$t6,	$t2,	$t3			#得到阶数差
	srlv	$t5,	$t5,	$t6			#尾数右移对阶
	add 	$t3,	$t3,	$t6			#对阶
	j	compareSign

compareSign:
	bne 	$t0,	$t1,	SNE			#比较符号位，若不一样，跳转到符号不同模块
	add 	$t7,	$t4,	$t5  	                #若符号位一样，直接相加尾数
	addi	$s3,	$t0,	0		        #将任意数（这里选择A）的阶码放到s3中
	j       HANDLE

SNE:
	beq	    $t4,	$t5	FRACZERO		#若A尾数等于B则跳转
	slt	    $t7,	$t4,	$t5			#若A尾数小于B则将t7置为1
	beqz	$t7,	AFRACGTB			#A尾数大于B
	sub	    $t7,	$t5,	$t4			#A尾数小于B
	sgt	    $t8,	$t1,	$zero			#若B为负数，则t8=1
	bgt	    $t8,	$zero,	BNEG			#若B为负数，则跳转到BNEG
	addi	$s3,	$zero,	0			#若B不是负数
	j	HANDLE

FRACZERO:
	addi	$t7,	$zero,	0			#尾数置为0
	addi	$s3,	$zero,	0			#符号位为两数中任意数（这里取A）的符号位
	addi	$t2,	$zero,	0			#阶数为A的阶数
	j	OUTPUTADD

AFRACGTB:
	sub   	$t7,	$t4,	$t5			#B尾数小于A
	sgt	    $t8,	$t0,	$zero			#若A为负数，则t8=1
	bgt	    $t8,	$zero,	ANEG			#若A为负数，则跳转到ANEG
	addi	$s3,	$zero,	0			#若A不是负数
	j	HANDLE

BNEG:
	addi	$s3,	$zero,	1			#s0保存绝对值较大数的符号位
	j	HANDLE

ANEG:
	addi	$s3,	$zero,	1			#s0保存绝对值较大数的符号位
	j	HANDLE

HANDLE:
	addi	$t8,	$zero,	0x1000000		#标记位数最大值
	sltu	$t9,	$t8,	$t7	
	bne	    $t9,	$zero,	CARRYIN			#若t7超过了位数，则进位
	j	NORMALIZATION	

CARRYIN:	
	addi	$t2,	$t2,	1			#进一位
	srl	    $t7,	$t7,	1			#尾数差右移
	j	NORMALIZATION

NORMALIZATION:
	addi	$t9,	$zero,	0x00800000		#规格化，消除尾数前导0，以t9为标志
	sgt  	$s7,	$t9,	$t7			#若t7还有前导0
	beq	    $s7,	1,	NORMALCIRCLE		#跳入循环规格化
	sub	    $t7,	$t7,	0x00800000		#若没有前导0,将前导1减去，即隐藏位
	j	OUTPUTADD

NORMALCIRCLE:
	sll	    $t7,	$t7,	1			#左移一位
	subi	$t2,	$t2,	1			#阶数减一
	sgt	    $s2,	$t9,	$t7			#若比标志小，则停止循环
	beq 	$s2,	1,	NORMALCIRCLE 		#否则继续规格化
	sub	    $t7,	$t7,	0x00800000		#减去前导一，隐藏位
	j	OUTPUTADD

OUTPUTADD:
	sll	    $t2,	$t2,	23			#将阶码移到对应位置
	sll	    $s3,	$s3,	31			#将符号位移到对应位置
	add	    $a2,	$s3,	$t2			#将阶码符号位拼接
	add	    $a2,	$a2,	$t7
OUTPUTZ:

	lw	    $s7,	($sp)
    addi	$sp,	$sp,	4
	lw	    $s3,	($sp)
	addi	$sp,	$sp,	4
        
jr $ra



getrandom:
li  $v0, 43           #getrandom
addi $a0, $0, 10  # 
syscall
sub $sp,$sp,4
s.s $f0,($sp)
lw $a0,($sp)
addi $a0,$a0,0x2000000
andi $a0,$a0,0xfffff000
sw $a0,($sp)
l.s $f0,($sp)
addi $sp,$sp,4
jr $ra

getadd:
add.s $f0,$f0,$f1
sub $sp,$sp,4
s.s $f0,($sp)
lw $t0,($sp)
addi $sp,$sp,4
jr $ra
getsub:
sub.s $f0,$f0,$f1
sub $sp,$sp,4
s.s $f0,($sp)
lw $t0,($sp)
addi $sp,$sp,4
jr $ra
getmul:
mul.s $f0,$f0,$f1
sub $sp,$sp,4
s.s $f0,($sp)
lw $t0,($sp)
addi $sp,$sp,4
jr $ra
getdiv:
div.s $f0,$f0,$f1
sub $sp,$sp,4
s.s $f0,($sp)
lw $t0,($sp)
addi $sp,$sp,4
jr $ra
end:
la    	$a0,	good			
li    	$v0,	4
syscall
move $a0,$s1		
li    	$v0,	1
syscall
la    	$a0,	hh			
li    	$v0,	4
syscall
la    	$a0,	total			
li    	$v0,	4
syscall
move $a0,$s0		
li    	$v0,	1
syscall
la    	$a0,	hh			
li    	$v0,	4
syscall
la    	$a0,	godie			
li    	$v0,	4
syscall
