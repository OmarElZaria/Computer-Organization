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
                  .global  _start                          
_start:                                         
/* Set up stack pointers for IRQ and SVC processor modes */

			
				MOV		 R0, #0b10010		
				MSR		 CPSR, R0
				LDR		 SP, =0x3FFFFFFC    //stack pointer for IRQ mode
				MOV		 R0, #0b10011		
				MSR		 CPSR, R0
				LDR		 SP, =0x80000		//stack pointer for SVC mode
                BL       CONFIG_GIC      // configure the ARM generic
                                         // interrupt controller
                  BL       CONFIG_TIMER     // configure the Interval Timer
                  BL       CONFIG_KEYS      // configure the pushbutton
                                            // KEYs port

/* Enable IRQ interrupts in the ARM processor */
				MOV		R0, #0b00010010 		// setting I = 0
                MSR		CPSR, R0
				
                  LDR      R5, =0xFF200000  // LEDR base address
LOOP:                                          
                  LDR      R3, COUNT        // global variable
                  STR      R3, [R5]         // write to the LEDR lights
                  B        LOOP                

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

UNEXPECTED:     BNE      UNEXPECTED      // if not recognized, stop here
		

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
				
KEY_ISR:		LDR      R0, =0xFF200050  // KEY address, don't touch		
				LDRB   		R1, [R0, #0xC] //read edgecap
				STR 	 	R1, [R0, #0xC]		// reset edgecap		
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
                  .global  COUNT                           
COUNT:            .word    0x0              // used by timer
                  .global  RUN              // used by pushbutton KEYs
RUN:              .word    0x1              // initial value to increment
                                            // COUNT
				  .global  RATE
RATE:			  .word	0x17D7840			  
											
                                                          
