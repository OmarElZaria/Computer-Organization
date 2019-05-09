/* Program that counts consecutive 1's */

          .text                   // executable code follows
          .global _start
                  
_start:   MOV     R5, #0    // initialize longest string to zero                      
          MOV     R0, #0    // initialize current string to zero
          MOV     R3, #TEST_NUM        // into R1

MAIN:     CMP     R5, R0 //checks if last string has a longer string
	  MOVLE   R5, R0 //if last word is longer	

          LDR     R1, [R3]
	  CMP     R1, #0   //checks if the data is 0, ends program if true
	  BEQ     END
	  MOV     R0, #0  //resets counter to 0
	  B       ONES		

ONES:     CMP     R1, #0          // loop until the data contains no more 1's
          ADDEQ   R3, #4
	  BEQ     MAIN             
          LSR     R2, R1, #1      // perform SHIFT, followed by AND
          AND     R1, R1, R2      
          ADD     R0, #1          // count the string length so far
          B       ONES            

END:      B       END             

TEST_NUM: .word   0x103fe00f,0x0009E3FF,0x07FFFFFF,0x03F80FFF,0x000B80FF,0x00FF5507,0x7FFFFFFF,0x00000001,0x00000000  

          .end                            
