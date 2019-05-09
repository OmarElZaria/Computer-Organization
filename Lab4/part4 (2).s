/* code for Part III (not shown) */

          .text                   // executable code follows
          .global _start     
		  
_start:   MOV	  R5, #0		  // initialize longest 1s to 0
		  MOV	  R6, #0		  // initialize longest 0s 
		  MOV     R7, #0		  // initialize longest alternate
		  
		  MOV	  R8, #0		  // initialize current 1s to 0
		  MOV	  R9, #0		  // initialize current 0s 
		  MOV     R10, #0		  // initialize current alternate
		  
		  MOV     R3, #TEST_NUM   // load the data word ...


MAIN:	  CMP	  R5, R8          // check if last 1s has longer string
		  MOVLE	  R5, R8 		  // 
		  CMP	  R6, R9          // check if last 0s has longer string
		  MOVLE	  R6, R9 		  // 
		  CMP	  R7, R10         // check if last alternate has longer string
		  MOVLE	  R7, R10 		  // 
		   

          LDR     R1, [R3]        // move current word into R1
		  CMP	  R1, #0          // checks if loaded data word was 0, ends program if true
		  BEQ	  DISPLAY
		  MOV     R8, #0		  // reset 1s counter
		  MOV     R9, #0 	      // reset 0s counter
		  MOV     R10,#0          // reset alternate counter
		  B       ONES
		  
ONES:     CMP     R1, #0          // loop until the data contains no more 1's
          BEQ     ZEROPREP             
          LSR     R2, R1, #1      // perform SHIFT, followed by AND
          AND     R1, R1, R2      
          ADD     R8, #1          // count the string length so far
          B       ONES  

ZEROPREP: LDR	  R1, [R3]		  // restore current word
		  MVN     R1, R1		  // invert the word
		  B		  ZEROS
		  
ZEROS:	  CMP     R1, #0          // loop until the data contains no more 1's
          BEQ     ALTERNATEPREP             
          LSR     R2, R1, #1      // perform SHIFT, followed by AND
          AND     R1, R1, R2      
          ADD     R9, #1          // count the string length so far
          B       ZEROS
		  
ALTERNATEPREP:    LDR R1, [R3]	  // restore current word
				  MOV R11, #XOR_CHECK
				  LDR R11, [R11]
				  CMP R1, R11 	  // check MSB of word
				  MOV R11, #XOR_CONSTANT_MSB_ONE     // if MSB is equal to 1 (no z flag)
				  MOVEQ R11, #XOR_CONSTANT_MSB_ONE  // if MSB is 1 but (with z flag) 
				  MOVLT R11, #XOR_CONSTANT_MSB_ZERO // if MSB is equal to 0
 
				  LDR R11, [R11] 
				  EOR R1, R11
				  
ALTERNATE:		  CMP     R1, #0          // loop until the data contains no more 1's
				  ADDEQ	  R3, #4		  // move forward in list
				  BEQ     MAIN             
				  LSR     R2, R1, #1      // perform SHIFT, followed by AND
				  AND     R1, R1, R2      
				  ADD     R10, #1          // count the string length so far
				  B       ALTERNATE


		  
END:      B       END  


/* Display R5 on HEX1-0, R6 on HEX3-2 and R7 on HEX5-4 */
DISPLAY:    LDR     R8, =0xFF200020 // base address of HEX3-HEX0
            MOV     R0, R5          // display R5 on HEX1-0
            BL      DIVIDE          // ones digit will be in R0; tens
                                    // digit in R1
            MOV     R9, R1          // save the tens digit
            BL      SEG7_CODE       
            MOV     R4, R0          // save bit code
            MOV     R0, R9          // retrieve the tens digit, get bit
                                    
            BL      SEG7_CODE       
            LSL     R0, #8			
            ORR     R4, R0
			
			

			
			MOV		R0, R6			//display R6 on HEX3-2
			BL		DIVIDE
            MOV     R9, R1          // save the tens digit
            BL      SEG7_CODE
			LSL		R0, #16			// index proper address
            ORR     R4, R0          // save bit code
            MOV     R0, R9          // retrieve the tens digit, get bit
                                    
            BL      SEG7_CODE       
            LSL     R0, #24			// index proper address
            ORR     R4, R0			 
			
            
            STR     R4, [R8]        // display the numbers from R6 and R5
            LDR     R8, =0xFF200030 // base address of HEX5-HEX4
			
           
			MOV     R4, #0
            MOV     R0, R7          // display R7 on HEX6-5
            BL      DIVIDE          // ones digit will be in R0; tens
                                    // digit in R1
            MOV     R9, R1          // save the tens digit
            BL      SEG7_CODE       
            MOV     R4, R0          // save bit code
            MOV     R0, R9          // retrieve the tens digit, get bit
                                    
            BL      SEG7_CODE       
            LSL     R0, #8			
            ORR     R4, R0			
			
            STR     R4, [R8]        // display the number from R7
			
			B		END
			

			
/* Subroutine to convert the digits from 0 to 9 to be shown on a HEX display.
 *    Parameters: R0 = the decimal value of the digit to be displayed
 *    Returns: R0 = bit patterm to be written to the HEX display
 */

SEG7_CODE:  MOV     R1, #BIT_CODES  
            ADD     R1, R0         // index into the BIT_CODES "array"
            LDRB    R0, [R1]       // load the bit pattern (to be returned)
            MOV     PC, LR              

BIT_CODES:  .byte   0b00111111, 0b00000110, 0b01011011, 0b01001111, 0b01100110
            .byte   0b01101101, 0b01111101, 0b00000111, 0b01111111, 0b01100111
            .skip   2      // pad with 2 bytes to maintain word alignment
			
			
/* Subroutine divide
 *  Parameters: R0 = number to be converted from binary to decimal
 *  Returns: R0 = ones digit, R1 = tens digit
 */
DIVIDE:     SUB	   R13, #4 //saving registers
			STR    R2, [R13]
			SUB	   R13, #4
			STR	   R6, [R13]
			MOV    R2, #0
			MOV	   R6, #10 // pointing to divisor
TEN:		CMP    R0, R6
            BLT    DIV_END // remainder < divisor
            SUB    R0, R6
            ADD    R2, #1
            B      TEN
DIV_END:    MOV    R1, R2     // quotient in R1 (remainder in R0)
			LDR	   R6, [R13] // restoring registers
			ADD	   R13, #4
			LDR	   R2, [R13]
			ADD	   R13, #4
            MOV    PC, LR

			
TEST_NUM: .word   0x85555555, 0xAC000FFF 
		  .word   0x00000000
		  

XOR_CHECK: .word 0x80000000		  
		  
XOR_CONSTANT_MSB_ZERO: .word 0xAAAAAAAA
XOR_CONSTANT_MSB_ONE: .word 0x55555555
