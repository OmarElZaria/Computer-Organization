					  .section .vectors, "ax"                  
					B        _start              // reset vector
					B        SERVICE_UND         // undefined instruction vector
					B        SERVICE_SVC         // software interrupt vector
					B        SERVICE_ABT_INST    // aborted prefetch vector
					B        SERVICE_ABT_DATA    // aborted data vector
					.word    0                   // unused vector
					B        SERVICE_IRQ         // IRQ interrupt vector
					B        SERVICE_FIQ         // FIQ interrupt vector

                    .text                                       
                    .global _start                              
_start:                                         
/* Set up stack pointers for IRQ and SVC processor modes */

				MOV		 R0, #0b10010		
				MSR		 CPSR, R0
				LDR		 SP, =0x3FFFFFFC    //stack pointer for IRQ mode
				MOV		 R0, #0b10011		
				MSR		 CPSR, R0
				LDR		 SP, =0x80000		//stack pointer for SVC mode

                    BL      CONFIG_GIC          // configure the ARM generic
                                                // interrupt controller
                    BL      CONFIG_PRIV_TIMER   // configure the private timer
                    BL      CONFIG_TIMER        // configure the Interval Timer
                    BL      CONFIG_KEYS         // configure the pushbutton
                                                // KEYs port
												
/* Enable IRQ interrupts in the ARM processor */

				MOV		R0, #0b00010010 		// setting I = 0
                MSR		CPSR, R0
				
                    LDR     R5, =0xFF200000     // LEDR base address
                    LDR     R6, =0xFF200020     // HEX3-0 base address
LOOP:                                           
                    LDR     R4, COUNT           // global variable
                    STR     R4, [R5]            // light up the red lights
                    LDR     R4, HEX_code        // global variable
                    STR     R4, [R6]            // show the time in format
                                                // SS:DD
                    B       LOOP                

/* Configure the MPCore private timer to create interrupts every 1/100 seconds */
CONFIG_PRIV_TIMER:                              
					LDR		R0, =2000000    // timeout = 1/(200 MHz) x 2x10^6 = 0.01 sec
					LDR		R1, =0xFFFEC600
					STR R0, [R1]	//storing counter
					MOV    R0, #0b111       // set bits: interrupts = 1, mode = 1 (auto), enable = 1
					STR    R0, [R1, #0x8]   // write to control register, to start timer     
					
					BX      LR       

		 
/* Configure the Interval Timer to create interrupts at 0.25 second intervals */
CONFIG_TIMER:                             
				  LDR	   R0, =0xFF202000

					LDR	R1, RATE //storing constant for countdown 0.25sec
					STR R1, [R0, #0x8] 
					LSR R1,	#16 
					STR R1, [R0,#0xC]	
				  MOV		R1, #0b0111				  
				  STR	   R1, [R0, #0x4]			//Starting the clock and enabling interrupts

                  BX       LR                  

/* Configure the pushbutton KEYS to generate interrupts */
CONFIG_KEYS:                                    
				MOV		R0, #0b1111 		// setting I = 0 in pushbuttons
				LDR      R1, =0xFF200050  
				STR		R0, [R1, #8]
                  BX       LR       
				  
/* Define the exception service routines */

SERVICE_IRQ:    PUSH     {R0-R7, LR}     
                LDR      R4, =0xFFFEC100 // GIC CPU interface base address
                LDR      R5, [R4, #0x0C] // read the ICCIAR in the CPU
                                         // interface

KEYS_HANDLER:                       
                CMP      R5, #73         // check the interrupt ID
                BEQ       KEY_ISR

TIMER_HANDLER:		                      
                CMP      R5, #72         // check the interrupt ID
                BEQ       TIMER_ISR	

PRIVATE_HANDLER:
				CMP		R5, #29
				BEQ		PRIVATE_ISR

//UNEXPECTED:     BNE      UNEXPECTED       if not recognized, stop here
		

EXIT_IRQ:       STR      R5, [R4, #0x10] // write to the End of Interrupt
                                         // Register (ICCEOIR)
                POP      {R0-R7, LR}     
                SUBS     PC, LR, #4      // return from exception	
				  
				  
TIMER_ISR:		
				LDR		  R1, COUNT		
				LDR		  R2, RUN
				ADD		  R1, R2
			
                STR		  R1, COUNT			
				MOV		  R0, #1
				LDR	   R1, =0xFF202000				
				STR		  R0, [R1] 
				B         EXIT_IRQ
								

PRIVATE_ISR:
				LDR		  R0, =0xFFFEC600
				MOV		  R1, #1
				STR		  R1, [R0, #0xC] //reset interrupt
				B		  INCREMENT
						 
	
	
INCREMENT:		LDR		  R0, =1
				LDR		  R1, HEX_DD
				ADD		  R0, R1
				CMP		  R0, #100 		//if DD is 100
				STRNE	  R0, HEX_DD	//otherwise store
				BLEQ		  INC_SS
				B		  GET_HEX_CODE

				
GET_HEX_CODE:   LDR		  R0, HEX_DD		//get DD in R0
				BL         GET_ONES
				BL			SEG7_CODE
				STR		  R0, HEX_code			
				LDR		  R0, HEX_DD
				BL		  GET_TENS
				BL			SEG7_CODE
				LDR		  R1, HEX_code
				LSL		  R0, #8
				ORR		  R0, R1
				STR		  R0, HEX_code
				LDR		  R0, HEX_SS		//get SS in R0
				BL         GET_ONES
				BL			SEG7_CODE
				LDR		  R1, HEX_code
				LSL		  R0, #16
				ORR		  R0, R1
				STR		  R0, HEX_code
				LDR		  R0, HEX_SS
				BL		  GET_TENS
				BL        SEG7_CODE
				LDR		  R1, HEX_code
				LSL		  R0, #24
				ORR		  R0, R1
				STR		  R0, HEX_code
				B  		  EXIT_IRQ
				
/*Return 10's digit in R0*/
GET_TENS:  						//Returns 10's digit in R0
		  PUSH 	{R4,R6}
		  MOV	 R4, R0
		  MOV	 R6, #0
TEN_LOOP: 
		  CMP	 R4, #10		//make sure value is less than 10
		  BLT	 STORE_TEN
		  SUBS	 R4, #10
		  ADD	 R6, #1			//counts how many times 10 is subtracted
		  B		 TEN_LOOP
		  
STORE_TEN:
		  MOV	 R0, R6
		  POP	 {R4,R6}
		  MOV	 PC, LR		//return out of subroutine   

				
/*Return 1's digit in R0*/          
GET_ONES:  						//Returns 1's digit in R0
		  PUSH 	{R4}
		  MOV	 R4, R0          
ONE_LOOP: 
		  CMP	 R4, #10		//make sure value is less than 10
          BLT	 STORE_ONE
          SUBS	 R4, #10
          B		 ONE_LOOP
          
STORE_ONE:
		  MOV	 R0, R4
          POP	 {R4}
          MOV	 PC, LR		//return out of subroutine


/* Subroutine to convert the digits from 0 to 9 to be shown on a HEX display.
 *    Parameters: R0 = the decimal value of the digit to be displayed
 *    Returns: R0 = bit patterm to be written to the HEX display
 */
			
SEG7_CODE:  LDR     R1, =BIT_CODES  
            ADD     R1, R0         // index into the BIT_CODES "array"
            LDRB    R0, [R1]       // load the bit pattern (to be returned)
            MOV     PC, LR              

BIT_CODES:  .byte   0b00111111, 0b00000110, 0b01011011, 0b01001111, 0b01100110
            .byte   0b01101101, 0b01111101, 0b00000111, 0b01111111, 0b01100111
            .skip   2      // pad with 2 bytes to maintain word alignment
	

				
INC_SS:			LDR	  R0, =0
				LDR		  R1,  HEX_DD
				STR		  R0,  HEX_DD
				LDR		  R1,  =1
				LDR		  R2, HEX_SS
				ADD		  R2, R1
				CMP		  R2, #60 		//if SS is 60
				STREQ	  R0, HEX_SS	//reset to 0				
				STRNE	  R2, HEX_SS	//else
				BX		  LR
				

	
KEY_ISR:		LDR      R0, =0xFF200050  // KEY address, don't touch		
				LDRB   		R1, [R0, #0xC] //read edgecap
				STR 	 	R1, [R0, #0xC]		// reset edgecap					
				AND    		R1, #0b1111   
				CMP	 		R1, #0b1000
				BEQ	 		KEY_3_PRESSED
				CMP	 		R1, #0b0100
				BEQ	 		KEY_2_PRESSED
				CMP	 		R1, #0b0010
				BEQ	 		KEY_1_PRESSED
				CMP	 		R1, #0b0001
				BEQ	 		KEY_0_PRESSED

KEY_3_PRESSED:	
				LDR		R1, =0xFFFEC600
				LDR		R0, =0b001
				LDR	   R2, [R1, #0x8]
				EOR	   R2, R0
				STR    R2, [R1, #0x8]   // write to control register, to start timer     

			
				B			EXIT_IRQ
KEY_2_PRESSED:	
				  LDR	   R0, =0xFF202000
				  MOV		R1, #0b1011				  
				  STR	   R1, [R0, #0x4]			//Stopping the clock and enabling interrupts
				  
					LDR	R1, RATE //get current rate in R1
					
					MOV		R0, #2
					MUL		R1, R0
					
					STR	   R1, RATE
				    LDR	   R0, =0xFF202000			//loading new value into RATE	
					STR R1, [R0, #0x8] 
					LSR	R1, #16
					STR R1, [R0,#0xC]	
	
				  MOV		R1, #0b0111				  
				  STR	   R1, [R0, #0x4]			//Starting the clock and enabling interrupts						
					
					B			EXIT_IRQ
	
KEY_1_PRESSED:

				  LDR	   R0, =0xFF202000
				  MOV		R1, #0b1011				  
				  STR	   R1, [R0, #0x4]			//Stopping the clock and enabling interrupts
				  
					LDR	R1, RATE //get current rate in R1
					
					LSR		R1, #1
					STR  		R1, RATE
				    LDR	   R0, =0xFF202000			//loading new value into RATE	
					STR 	R1, [R0, #0x8] 
					LSR		R1, #16
					STR R1, [R0,#0xC]	
	
				  MOV		R1, #0b0111				  
				  STR	   R1, [R0, #0x4]			//Starting the clock and enabling interrupts	
				
				B   	  EXIT_IRQ
				  

KEY_0_PRESSED:
				MOV		  R0, #0b1
				LDR		  R1, RUN
				EOR		  R0, R1
                STR		  R0, RUN		  //toggle the value of run
						
				B		 EXIT_IRQ
				  
				  
/* Undefined instructions */
SERVICE_UND:                                
                    B   SERVICE_UND         
/* Software interrupts */
SERVICE_SVC:                                
                    B   SERVICE_SVC         
/* Aborted data reads */
SERVICE_ABT_DATA:                           
                    B   SERVICE_ABT_DATA    
/* Aborted instruction fetch */
SERVICE_ABT_INST:                           
                    B   SERVICE_ABT_INST    
SERVICE_FIQ:                                
                    B   SERVICE_FIQ  
				  				  

/* Global variables */
                    .global COUNT                               
COUNT:              .word   0x0       // used by timer
                    .global RUN       // used by pushbutton KEYs
RUN:                .word   0x1       // initial value to increment COUNT
                    .global TIME                                
TIME:               .word   0x0       // used for real-time clock
                    .global HEX_code                            
				  .global  RATE
RATE:			  .word	0x17D7840	
					
HEX_code:           .word   0x0       // used for 7-segment displays
					.global HEX_DD
HEX_DD:				.word	0
					.global HEX_SS
HEX_SS:				.word	0

                                                            
