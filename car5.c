// PWM Ch. 5 = servo control (H1 pin 37)
// PWM Ch. 3 = motor control (H1 pin 39)
// Pulse Accumulator input (Timer 0 Ch. 7) (H1 pin 10)
// VRL H1 pin 31 VRH H1 pin 30
// Steering analog signal H1 Pin 22
// Use fixed 333.33 Hz for servo; vary duty cycle;
// Using uBug12: fbulk, fload ;b to program
// To run use 9600-baud Hyperterminal;

#include <stdio.h>
#define _SCI
#include <hcs12e128.h>
#define DUMMY_ENTRY (void(*)(void))0xFFFF
// (187500 Hz)(0.25s) = 46875 cycles
#define QUARTER_SEC 46875
#define SET_COUNT 20

int i;
int D[10];       	   	 	  		//saved ATD results
int conv, turn;                  	//ATD result from sensors to servo
float P_term, D_term, I_term, PID; 	//PID Terms
signed int error, avg_error;	   	//PID error terms
float Kp = 1;	//0.15			    //PID coefficients
float Td = 0.05; //0.5
float Ti = 20;
int maxServo = 50;					//min/max servo PWM values
int minServo = 25;
int RTI_flag;  	   		 			// RTI occurred
int RTI_count;
int PulseCount;	   		 			// Pulses from Pulse Accumulator
int flag;	   	   		 			// OC4 interrupt occurred

#pragma nonpaged_function _start;
extern void _start(void); 		 /* entry point in crt12.s */

#pragma interrupt_handler OC04_handler
void OC04_handler()
{
  T0C4 = T0C4 + QUARTER_SEC;	// set OC reg for next interval
  T0FLG1 = 0x10;				// clear Ch. 4 int. flag (C4F)
  PulseCount = P0ACNT;			// store PACNT in global
  P0ACNT = 0;					// clear PACNT
  flag = 1;	 
}

#pragma interrupt_handler RTI_handler
void RTI_handler()
{
  CRGFLG = 0x80;  		  		// clear RTI flag
  RTI_flag = 1;					// set program variable flag
  RTI_count++;					// increment counter
}

int putchar(char c){			 //hyperterminal code
	if (c == '\n')
		putchar('\r');
	while ((SCI0SR1 & TDRE) == 0)
		;
	SCI0DRL = c;
	return c;
}
	
int getchar(void){
	while ((SCI0SR1 & RDRF) == 0)
		;
	return SCI0DRL;
}

void Init(void){
  COPCTL = 0x00; 	  		   // disable COP
  
  CLKSEL &= 0x7F;	   		   // make sure PLLSEL bit=0 (default)
  SYNR = 5;					   // set PLLCLK=48 MHz; bus clock=24 MHz
  REFDV = 1;				   // 2*8MHz*(5+1)/(1+1)=48 MHz
  while ((CRGFLG & 0x08)==0x00) ;	// wait for PLL to LOCK
  CLKSEL |= 0x80;   			// PLLSEL=1;			   
 
  DDRP = 0xFF;					// PortP output 
  PWMCNT5 = 0;					// reset PWM counter 5
  PWMCNT3 = 0;					// reset PWM counter 3
  PWMPOL = 0x28;				// PPOL5, PPOL3 = 1
  PWMCLK = 0x28;				// clock SA = source for Ch. 5 and Ch. 3
  PWMPRCLK = 0x02;				// A = E/4 = 24M/4 = 6M clock rate
  PWMCAE = 0;					// Ch. 5,3 Left Aligned Output mode
  PWMCTL = 0;					// 8-bit PWM register
  PWMSCLA = 90;					// SA = E/(2*PWMSCLA) = 6M/60=100K
  PWMPER5 = 100;				// Frequency = SA/150 = 333.33 Hz
  PWMPER3 = 140;				// 
  PWMDTY5 = 33;					// 33% duty cycle at start (center)
  PWMDTY3 = 20;					// 0% duty cycle  15% slow test speed
  PWME = 0x28;					// enable Ch. 5 and Ch. 3

  T0IOS = 0x10;					// IOC04 = output compare; IOC07=input (PA)
  T0CTL1 = 0x00;				// IOC04 output not driven by timer
  P0ACTL = 0x40;				// set PAEN=1 (enable PA in event mode, falling edge. Set to 0x50 for rising.)
  T0SCR2 = 0x07;				// bus clock/128 = 24M/128 = 187,500 Hz
  T0C4 = T0CNT + QUARTER_SEC;	// set for next oc interrupt (.25s)
  T0FLG1 = 0x10;				// clear Ch. 4 int. flag (C4F)
  T0IE = 0x10;					// enable timer int. for Ch. 4
  
  RTICTL = 0x30;				// Divide by 2**12 (24 MHz/4096 = 5895 Hz
  CRGFLG = 0x80;				// clear RTIF flag (msb)
//  CRGINT = 0x80;				// enable RTIE (enable RTI interrupts)
  CRGINT = 0x00;
     
  asm(" cli");					// clear I-bit in CCR
  T0SCR1 = 0x80;				// enable timer (TEN=1)
  P0ACNT = 0;					// clear PA counter 
//  OC7M = 0x00;					// Set IC/OC Ch. 7 as PA pin
}

void Init_AD(void) {
	 ATD0CTL2 = 0xC0; 		   // ADPU = AFFC = 1;
	 ATD0CTL3 = 0x20;		   // 4 conv per seq
	 ATDDIEN0 = 0x00;		   // disable digital input buffers 15-8
	 ATDDIEN1 = 0x00;		   // disable digital input buffers 7-0
	 ATDTEST1 = 0x00;		   // no special conversion
	 ATD0CTL4 = 0x85;		   // 8-bit, ATD clock = 2 MHz	 

} 


void main(void){ 
  Init(); 
  SCI0BD = 156;	 				// 9600 baud
  SCI0CR2 = 0x0C; 				// enable transmitter and receiver
  Init_AD();	 	  			// initialize ATD
  ATD0CTL5 = 0x20;					//one channel, 8 conversions, continuous conversions
					
//  PWMDTY3 = 30;						//starting speed - slow
//  RTI_count=0;
//  RTI_flag=0;								
//  printf ("\n\r");

  while(1) {
 
  conv = ATDDR0H; 
//	   Use printf for debugging 
//  printf("AtD 0: %d PID: %f PWM: %d \n", ATDDR0H, PID, PWMDTY5); //256 steps, 0 to 5V, 19.53mV/step
//	printf("AtD 0: %d, PWM: %d \n", ATDDR0H, PWMDTY5);  
 
  /* ----- PID ----- */
  
  //calculate PID terms	   	   	  
  error = conv - 75;   	   	   	 

  for(i = 9; i >= 1; i--) {				  //recording previous errors
  		D[i] = D[i-1];
  }
  D[0] = error;
  for(i = 0; i >= 9; i++) {				  //calculate average error
  		avg_error += D[i];
  }
  avg_error = avg_error / 10;
    P_term = Kp * (error);	 			  //calculate PID terms
    I_term = (Kp / Ti) * (avg_error); 
	D_term = Kp * Td *(error - avg_error);	  
    PID = (P_term + D_term + I_term);
  
  /* Code For Steering */ 
  
  turn = conv + PID;
  
 // if(((turn)*(-0.186)+(52.24)) > maxServo)
 // 					PWMDTY5 = maxServo;
 //		else if(((turn)*(-0.186)+(52.24)) < minServo)
 //			 		PWMDTY5 = minServo;
 //		else
 //					PWMDTY5 = ((turn) * (-0.186) + (52.24));
					
  
  if((turn) <= 75)	   //right turn
  		   if(((turn)*(-0.197)+(51.77)) > maxServo)
		   			 PWMDTY5 = maxServo;
		   else if(((turn)*(-0.197)+(51.77)) < minServo)
		   			 PWMDTY5 = minServo;
		   else 
		   		PWMDTY5 = ((turn) * (-0.197)+(51.77));
  if((turn) > 75)		//left turn
  		   if(((turn)*(-0.1846)+(50.846)) > maxServo)
		   			 PWMDTY5 = maxServo;  
		   else if(((turn)*(-0.1846)+(50.846)) < minServo)
		   			 PWMDTY5 = minServo;
		   else 
		   		PWMDTY5 = ((turn) * (-0.1846) + (50.846));
  
  
  /* Code For Motor Control */
  
  	 if(flag)
	 	{
		 	 if(PulseCount == 0)
			 			   PWMDTY3 = 20;
			 else if(PulseCount < SET_COUNT)
			 			   PWMDTY3 = PWMDTY3 + 1;
			 else if(PulseCount > SET_COUNT)
			 	  		   PWMDTY3 = PWMDTY3 - 1;
			 flag = 0;
			 PulseCount = 0;
		}	 
  
  
  }	 			// while(1)
}

#pragma abs_address: 0xFFE6
void (*interrupt_vectors[])(void) = 
{
 OC04_handler,	/* Timer 0 Channel 4 */
 DUMMY_ENTRY,	/* Reserved $FFE8 */
 DUMMY_ENTRY,	/* Reserved $FFEA */
 DUMMY_ENTRY,	/* Reserved $FFEC */
 DUMMY_ENTRY,	/* Reserved $FFEE */
 DUMMY_ENTRY,	/* Real Time Interrupt */
 DUMMY_ENTRY,	/* IRQ */
 DUMMY_ENTRY,	/* XIRQ */
 DUMMY_ENTRY,	/* SWI */
 DUMMY_ENTRY,	/* Unimplement Instruction Trap */
 DUMMY_ENTRY,	/* COP failure reset */
 DUMMY_ENTRY,	/* Clock monitor fail reset */
 _start,		/* Reset */
};
#pragma end_abs_address 