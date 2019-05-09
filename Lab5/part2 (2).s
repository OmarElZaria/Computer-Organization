.text
.global _start
_start:   
	  MOV	R9, #BIT_CODES        	//initialize R9 as BIT pointer
      LDR   R8, =0xFF20005C         //initialize R8 at Edge
      LDR	R7, =0xFF200050  		//initialize R7 at key register
      LDR	R6, =0xFF200020  		//initialize R6 at HEX3-HEX0   
      MOV	R2, #0                  //R2 will be the counter
      MOV   R3, #1                  //Boolean Variable
      
MAIN:
	LDR	R5, [R8]                    //reads edgecapture resgister
    	CMP R5, #0
    BEQ DO_DELAY			//if edgecapture is 0, a key has been pressed
    
WAIT:
	LDR R5, [R7]		//Poll keys to see if the key has been released
    CMP R5, #0
    BNE WAIT			//wait for the key to be released
    MOV R5, #0xF		//reset edgecapture
    STR R5,[R8]
    MOV R4, #1
    SUB R3, R4, R3		//Subtract R3 from 1 to invert it
    
DO_DELAY: 
	LDR R4, =200000000 // delay counter

SUB_LOOP:
	SUBS	R4, #1
    BNE		SUB_LOOP
    
    CMP		R3, #1          //when R3 = 1, increment counter
    BNE		DISPLAY
    ADD		R2, #1
    CMP     R2, #100		//wrap around to 0 when R2 > 99
    BNE		DISPLAY
    MOV		R2, #0
    
DISPLAY:
	MOV		R0, R2   //Seperate R2 into its digits
    BL		DIVIDE
    
    LDRB	R0, [R9, R0]	//Get pattern for ones digits
    LDRB    R1, [R9, R1]	//Get patter for tens digits
    LSL		R1, #8
    ORR		R0, R1
    STR		R0, [R6]	//Display counter
    B		MAIN
    
DIVIDE:
	PUSH	{R2,LR}
    MOV		R2, #0
CONT:
	CMP    R0, #10
    BLT    DIV_END // remainder < divisor
    SUB    R0, #10
    ADD    R2, #1
    B      CONT
DIV_END:
	MOV	   R1, R2     // quotient in R1 (remainder in R0)
    POP	   {R2,PC}
    
BIT_CODES:  .byte   0b00111111, 0b00000110, 0b01011011, 0b01001111,  0b01100110 
			.byte 	0b01101101, 0b01111101, 0b00000111, 0b01111111, 0b01100111, 0b0000000
            .skip   2      // pad with 2 bytes to maintain word alignment

.end
	