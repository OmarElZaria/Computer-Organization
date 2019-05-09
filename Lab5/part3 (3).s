/* Program that counts consecutive 1's */

          .text                   // executable code follows
          .global _start
                  
_start:   MOV     R5, #0    // initialize longest string of 1's to zero
	  MOV     R6, #0    // initialize longest string of 0's to zero 	                      
          MOV     R7, #0    // initialize longest string of alternate to zero
          MOV     R8, #0    // initialize current longest string of 0's to zero 
          MOV     R9, #0    // initialize current longest string of 1's to zero
          MOV     R10, #0    // initialize current longest string of alternate to zero  
	  MOV     R3, #TEST_NUM        // into R3

MAIN:     CMP     R5, R8 //checks if last string has a longer string
	  MOVLE   R5, R8 //if last word is longer
          CMP     R6, R9 //checks if last string has a longer string
	  MOVLE   R6, R9 //if last word is longer
          CMP     R7, R10 //checks if last string has a longer string
	  MOVLE   R7, R10 //if last word is longer

          LDR     R1, [R3]
	  CMP     R1, #0   //checks if the data is 0, ends program if true
	  BEQ     END
	  MOV     R8, #0  //resets counter to 0
	  MOV     R9, #0  //resets counter to 0
	  MOV     R10, #0  //resets counter to 0
	  B       ONES

ONES:     CMP     R1, #0          // loop until the data contains no more 1's
	  BEQ     ZEROPREP             
          LSR     R2, R1, #1      // perform SHIFT, followed by AND
          AND     R1, R1, R2      
          ADD     R8, #1          // count the string length so far
          B       ONES    

ZEROPREP:     LDR     R1, [R3]
              MVN     R1, R1
              B       ZEROS    

ZEROS:     CMP     R1, #0          // loop until the data contains no more 1's
	   BEQ     ALTERNATEPREP             
           LSR     R2, R1, #1      // perform SHIFT, followed by AND
           AND     R1, R1, R2      
           ADD     R9, #1          // count the string length so far
           B       ZEROS   

ALTERNATEPREP:    LDR R1, [R3]	  // restore current word
		  MOV R11, #XOR_CHECK
		  LDR R11, [R11]
		  CMP R1, R11 	      // check MSB of word
		  MOV R11, #XOR_CONSTANT_MSB_ONE       // if MSB is equal to 1 (no z flag)
		  MOVEQ R11, #XOR_CONSTANT_MSB_ONE    // if MSB is 1 but (with z flag) 
		  MOVLT R11, #XOR_CONSTANT_MSB_ZERO    // if MSB is equal to 0
 
		  LDR R11, [R11] 
		  EOR R1, R11

ALTERNATE:     CMP     R1, #0          // loop until the data contains no more 1's
	       ADDEQ   R3, #4
	       BEQ     MAIN             
               LSR     R2, R1, #1      // perform SHIFT, followed by AND
               AND     R1, R1, R2      
               ADD     R10, #1          // count the string length so far
               B       ALTERNATE

END:      B       END             

TEST_NUM: .word   0x103fe00f,0x0009E3FF,0x07FFFFFF
	  .word   0x03F80FFF,0x000B80FF,0x00FF5507
          .word   0x7FFFFFFF,0x00000001,0xAAAAAAA0
          .word   0x00000000
		  

XOR_CHECK: .word 0x80000000		  
		  
XOR_CONSTANT_MSB_ZERO: .word 0xAAAAAAAA
XOR_CONSTANT_MSB_ONE: .word 0x55555555