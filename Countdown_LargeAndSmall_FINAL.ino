//SMALL 3-digit 7-Seg display countodwn timer with Start/Stop and Reset buttons
// Uses shift registers
#include <PinChangeInt.h>

//Timer variables
int Total_Time = 180;

int Time_Remaining;
int Minutes;
int Seconds;
int Seconds_ones;
int Seconds_tens;
byte data_Minutes;
byte data_Seconds_ones; 
byte data_Seconds_tens;
int UpdateTime; //temp
unsigned long currentMillis;
unsigned long previousMillis;
unsigned long pressStartStopTime;
//Pin connected to ST_CP of 74HC595
int latchPin = 5;
int latchPinLarge = 12;
//Pin connected to SH_CP of 74HC595
int clockPin = 7;
int clockPinLarge = 13;
//Pin connected to DS of 74HC595
int dataPin = 6;
int dataPinLarge = 11;
//Pin connected to Relay
int relayPin = 4;
int TapOutPin_1 = 14; //Analog 0 used as Digital 14
int TapOutPin_2 = 15; //Analog 1 used as Digital 15
int TapOutLED_1 = 18; //Analog 4 used as Digital 18
int TapOutLED_2 = 19; //Analog 5 used as Digital 19 

void setup() {
  Serial.begin(9600); //debugging
  UpdateTime = 0; //start //paused = 0

  //setting up ext interrupt pins and pullup resistors
  
  pinMode(2, INPUT);
  //digitalWrite(2, LOW);
  pinMode(3, INPUT);
  //digitalWrite(3, LOW);
  pinMode(TapOutPin_1, INPUT);
  pinMode(TapOutPin_2, INPUT);
  pinMode(TapOutLED_1, OUTPUT);
  pinMode(TapOutLED_2, OUTPUT);
  
  attachInterrupt(0,StartStopISR,FALLING); 
  attachInterrupt(1,ResetISR,FALLING); 
  PCintPort::attachInterrupt(TapOutPin_1, TapOut_1_ISR,RISING); //used to attach an interrupt to a non external interrupt pin
  PCintPort::attachInterrupt(TapOutPin_2, TapOut_2_ISR,RISING);
  
  //set pins to output so you can control the shift register
  pinMode(latchPin, OUTPUT);
  pinMode(clockPin, OUTPUT);
  pinMode(dataPin, OUTPUT);
  
  pinMode(latchPinLarge, OUTPUT);
  pinMode(clockPinLarge, OUTPUT);
  pinMode(dataPinLarge, OUTPUT);
  
  //clear 4015 shift register
  digitalWrite(latchPin, HIGH);  
  digitalWrite(latchPin, LOW);
    //Set up 3:00
  shiftOut(dataPin, clockPin, MSBFIRST, 0x4F);
  shiftOut(dataPin, clockPin, MSBFIRST, 0x3F);
  shiftOut(dataPin, clockPin, MSBFIRST, 0x3F);
  
  shiftOut(dataPinLarge, clockPinLarge, MSBFIRST, 0x4F);
  shiftOut(dataPinLarge, clockPinLarge, MSBFIRST, 0x3F);
  shiftOut(dataPinLarge, clockPinLarge, MSBFIRST, 0x3F); 
  
  digitalWrite(latchPinLarge, HIGH);
  digitalWrite(latchPinLarge, LOW);
  
  digitalWrite(relayPin, LOW);
  digitalWrite(TapOutLED_1, LOW);
  digitalWrite(TapOutLED_2, LOW);  
  
  Time_Remaining = Total_Time;
}

//  Reset button
void ResetISR() {
    static unsigned long last_interrupt_time_2 = 0;
    unsigned long interrupt_time_2;
    unsigned long interrupt_time_3 = millis(); 
   
 if (interrupt_time_3 - pressStartStopTime > 500) {  //debouncing the interrupts - workaround for annoying problem
  if (UpdateTime == 0) {
//    static unsigned long last_interrupt_time_2 = 0;
//    unsigned long interrupt_time_2 = millis();
    interrupt_time_2 = millis();
    if (interrupt_time_2 - last_interrupt_time_2 > 500) {
      Time_Remaining = Total_Time;
      
      digitalWrite(latchPin, HIGH);
      digitalWrite(latchPin, LOW);
      
      shiftOut(dataPin, clockPin, MSBFIRST, 0x4F);
      shiftOut(dataPin, clockPin, MSBFIRST, 0x3F);
      shiftOut(dataPin, clockPin, MSBFIRST, 0x3F);
      
      shiftOut(dataPinLarge, clockPinLarge, MSBFIRST, 0x4F);
      shiftOut(dataPinLarge, clockPinLarge, MSBFIRST, 0x3F);
      shiftOut(dataPinLarge, clockPinLarge, MSBFIRST, 0x3F);
      
      digitalWrite(latchPinLarge, HIGH);
      digitalWrite(latchPinLarge, LOW);
      
      digitalWrite(TapOutLED_1, LOW);
      digitalWrite(TapOutLED_2, LOW);
      
      last_interrupt_time_2 = interrupt_time_2;
      Serial.println("Reset UT0"); //debugging
        //Update digit variables to fix bug (a STOP from tapout, followed by a RESET, followed by another STOP from tapout would cause the old time to display as it had not been updated)
        //Get single digits  
        Minutes = Time_Remaining / 60;
        Seconds = Time_Remaining % 60;
        Seconds_tens = Seconds / 10;
        Seconds_ones = Seconds % 10;
      
        //Get hex values of single digits
        data_Minutes = getDigit(Minutes);
        data_Seconds_tens = getDigit(Seconds_tens);
        data_Seconds_ones = getDigit(Seconds_ones);
    }
  }
//  if (UpdateTime == 1) {          //debug code. If left in w/o debouncing serial.println is called many times and takes too many clock cycles causing the program to freeze
//    Serial.println("Reset UT1");
//  }
 }
}

//  Start/Stop button
void StartStopISR() {

  static unsigned long last_interrupt_time = 0;
  unsigned long interrupt_time = millis();
  
  if (interrupt_time - last_interrupt_time > 500) {
    
    if(UpdateTime == 1) {
      UpdateTime = 0;
      Serial.println("Stop"); //debugging
    }
    else {
      UpdateTime = 1;
      Serial.println("Start"); //debugging
    }
  last_interrupt_time = interrupt_time; //moved into the if-statement.
  pressStartStopTime = millis();
  }
  //last_interrupt_time = interrupt_time;

}

//Tap-Out buttons for each team. Numbered to identify which team taps out.
void TapOut_1_ISR() {
  //Debouncing stuff
  static unsigned long last_interrupt_time_TapOut_1 = 0;
  unsigned long interrupt_time_TapOut_1 = millis();
  
  if (interrupt_time_TapOut_1 - last_interrupt_time_TapOut_1 > 500) {
    
    if(UpdateTime == 1) {
      UpdateTime = 0;
      Serial.println("Stop - TapOut 1"); //debugging
      digitalWrite(TapOutLED_1, HIGH);
      delay(300);                        //delay + segout is a fix for garbage output on the slave displays after hitting the tap-out button
      segout(data_Minutes, data_Seconds_tens, data_Seconds_ones);
    }
    else {
      delay(300);                        //delay + segout is a fix for garbage output on the slave displays after hitting the tap-out button
      segout(data_Minutes, data_Seconds_tens, data_Seconds_ones);
    }
    last_interrupt_time_TapOut_1 = interrupt_time_TapOut_1; 
  }
}

void TapOut_2_ISR() {
  //Debouncing stuff
  static unsigned long last_interrupt_time_TapOut_2 = 0;
  unsigned long interrupt_time_TapOut_2 = millis(); 
 
   if (interrupt_time_TapOut_2 - last_interrupt_time_TapOut_2 > 500) {
    
    if(UpdateTime == 1) {
      UpdateTime = 0;
      Serial.println("Stop - TapOut 2"); //debugging
      digitalWrite(TapOutLED_2, HIGH);
      delay(300);                        //delay + segout is a fix for garbage output on the slave displays after hitting the tap-out button
      segout(data_Minutes, data_Seconds_tens, data_Seconds_ones);
    }
    else {
      delay(300);                        //delay + segout is a fix for garbage output on the slave displays after hitting the tap-out button
      segout(data_Minutes, data_Seconds_tens, data_Seconds_ones);
    }
    last_interrupt_time_TapOut_2 = interrupt_time_TapOut_2; 
  } 
}

void segout(byte data_M, byte data_S_tens, byte data_S_ones) { 
  //clear 4015 shift reg
  digitalWrite(latchPin, HIGH);  
  digitalWrite(latchPin, LOW);

  //Shift data out to shift register
  shiftOut(dataPin, clockPin, MSBFIRST, data_M);
  shiftOut(dataPin, clockPin, MSBFIRST, data_S_tens);
  shiftOut(dataPin, clockPin, MSBFIRST, data_S_ones);
  
  shiftOut(dataPinLarge, clockPinLarge, MSBFIRST, data_M);
  shiftOut(dataPinLarge, clockPinLarge, MSBFIRST, data_S_tens);
  shiftOut(dataPinLarge, clockPinLarge, MSBFIRST, data_S_ones); 
  
  //Pulse the latch clock to load the output
  digitalWrite(latchPinLarge, HIGH);  
  digitalWrite(latchPinLarge, LOW);
  
}

//getDigit converts the single digit int value to the hex code needed to display it on a 7-seg display
byte getDigit(int input_int) {
   byte output_byte;
   
   switch (input_int) {
     case 0:
     output_byte = 0x3F;
     return output_byte;
     
     case 1:
     output_byte = 0x06;
     return output_byte;
     
     case 2:
     output_byte = 0x5B;
     return output_byte;
     
     case 3:
     output_byte = 0x4F;
     return output_byte;
     
     case 4:
     output_byte = 0x66;
     return output_byte;
     
     case 5:
     output_byte = 0x6D;
     return output_byte;
     
     case 6: 
     output_byte = 0x7D;
     return output_byte;
     
     case 7:
     output_byte = 0x07;
     return output_byte;
     
     case 8:
     output_byte = 0x7F;
     return output_byte;
     
     case 9:
     output_byte = 0x6F;
     return output_byte;
   }
}

void loop() {
  
  if (UpdateTime) {
    
    currentMillis = millis();
    
    if ((currentMillis - previousMillis) >= 1000) {  //check to see if a second has passed
      
      previousMillis = currentMillis;
      
      if(Time_Remaining >= 0) {  //check to see if time is over
        if(Time_Remaining > 0)
          Time_Remaining--;
        else
          UpdateTime = 0;
      
        //Get single digits
        Minutes = Time_Remaining / 60;
        Seconds = Time_Remaining % 60;
        Seconds_tens = Seconds / 10;
        Seconds_ones = Seconds % 10;
      
        //Get hex values of single digits
        data_Minutes = getDigit(Minutes);
        data_Seconds_tens = getDigit(Seconds_tens);
        data_Seconds_ones = getDigit(Seconds_ones);
      
        //Display on 7-seg displays
        segout(data_Minutes, data_Seconds_tens, data_Seconds_ones);
        //if(Time_Remaining == 170) {
         // Siren test at 10 seconds in;
        // digitalWrite(relayPin, HIGH);
        //}
      }
    }
  }
}




/*
void Siren() {
  digitalWrite(relayPin, HIGH);
  delay(1000);
  digitalWrite(relayPin, LOW);
  return;
}
*/
