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

				LDR      R8, =0xFF200050  // KEY address, don't touch
				LDR      R10, =0xFF200020  // HEX address, don't touch				
				
				
				MOV		 R0, #0b10010		
				MSR		 CPSR, R0
				LDR		 SP, =0x3FFFFFFC    //stack pointer for IRQ mode
				MOV		 R0, #0b10011		
				MSR		 CPSR, R0
				LDR		 SP, =0x80000		//stack pointer for SVC mode
                BL       CONFIG_GIC      // configure the ARM generic
                                         // interrupt controller
										 
/* Configure the KEY pushbuttons port to generate interrupts */
				MOV		R0, #0b1111 		// setting I = 0 in pushbuttons
				STR		R0, [R8, #8]
				
				
/* Enable IRQ interrupts in the ARM processor */
				MOV		R0, #0b00010010 		// setting I = 0
                MSR		CPSR, R0
							
IDLE:                                    
                B        IDLE            // main program simply idles

/* Define the exception service routines */

SERVICE_IRQ:    PUSH     {R0-R7, LR}     
                LDR      R4, =0xFFFEC100 // GIC CPU interface base address
                LDR      R5, [R4, #0x0C] // read the ICCIAR in the CPU
                                         // interface

KEYS_HANDLER:                       
                CMP      R5, #73         // check the interrupt ID

UNEXPECTED:     BNE      UNEXPECTED      // if not recognized, stop here
                BL       KEY_ISR         

EXIT_IRQ:       STR      R5, [R4, #0x10] // write to the End of Interrupt
                                         // Register (ICCEOIR)
                POP      {R0-R7, LR}     
                SUBS     PC, LR, #4      // return from exception
				
KEY_ISR:		
				LDRB   		R1, [R8, #0xC] //read edgecap
				STR 	 	R1, [R8, #0xC]		// reset edgecap					
				AND    		R1, #0b1111   
				CMP	 		R1, #0b1000
				BEQ	 		KEY_3_PRESSED
				CMP	 		R1, #0b0100
				BEQ	 		KEY_2_PRESSED
				CMP	 		R1, #0b0010
				BEQ	 		KEY_1_PRESSED
				CMP	 		R1, #0b0001
				BEQ	 		KEY_0_PRESSED				
				
KEY_3_PRESSED:  LDR		 R1, [R10]
				CMP		 R1, #0
				BNE		 OFF 		//2 means "off", 1 means "on"
				LDR 	 R1, THREE
			    LSL		 R1, #24				
                STR 	 R1, [R10]  // store to FF200038 (HEX3)	
			
				MOV		 PC, LR

KEY_2_PRESSED:  LDR		 R1, [R10] 
				CMP		 R1, #0
				BNE		 OFF 		//2 means "off", 1 means "on"
				LDR 	 R1, TWO
			    LSL		 R1, #16
                STR 	 R1, [R10]  // store to FF200030 (HEX2)
				
				MOV		 PC, LR

KEY_1_PRESSED:  LDR		 R1, [R10]
				CMP		 R1,#0
				BNE		 OFF 		//2 means "off", 1 means "on"
				
				LDR 	 R1, ONE
				LSL		 R1, #8
                STR 	 R1, [R10]  // store to FF200028 (HEX1)
				
				MOV		 PC, LR
      
KEY_0_PRESSED:  LDR		 R1, [R10]
				CMP		 R1, #0
				BNE		 OFF 		//if HEX display is blank
				LDR 	 R1, DATA
                STR 	 R1, [R10]  // store to FF200020 (HEX0)	

				MOV		 PC, LR
				
OFF:
				LDR 	 R1, BLANK    //initializes to clear	  
                STR 	R1, [R10]  // store to FF200020 (HEX0)			 
				 
				MOV		 PC, LR			
				
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
				 

DATA:		.word 0b00111111			// '0'
ONE:			.word 0b00000110			// '1'
TWO:			.word 0b01011011			// '2'
THREE:			.word 0b01001111			// '3'		   
            
BLANK:		.word 0b00000000000000000000000000000000            // clear	
				     


