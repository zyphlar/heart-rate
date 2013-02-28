


volatile int rateA[10];                    // used to hold last ten IBI values
volatile unsigned long sampleCounterA = 0;          // used to determine pulse timing
volatile unsigned long lastBeatTimeA = 0;           // used to find the inter beat interval
volatile int Pa =512;                      // used to find peak in pulse wave
volatile int Ta = 512;                     // used to find trough in pulse wave
volatile int threshA = 512;                // used to find instant moment of heart beat
volatile int ampA = 100;                   // used to hold amplitude of pulse waveform
volatile boolean firstBeatA = true;        // used to seed rate array so we startup with reasonable BPM
volatile boolean secondBeatA = true;       // used to seed rate array so we startup with reasonable BPM

volatile int rateB[10];                    // used to hold last ten IBI values
volatile unsigned long sampleCounterB = 0;          // used to determine pulse timing
volatile unsigned long lastBeatTimeB = 0;           // used to find the inter beat interval
volatile int Pb =512;                      // used to find peak in pulse wave
volatile int Tb = 512;                     // used to find trough in pulse wave
volatile int threshB = 512;                // used to find instant moment of heart beat
volatile int ampB = 100;                   // used to hold amplitude of pulse waveform
volatile boolean firstBeatB = true;        // used to seed rate array so we startup with reasonable BPM
volatile boolean secondBeatB = true;       // used to seed rate array so we startup with reasonable BPM


void interruptSetup(){     
  // Initializes Timer2 to throw an interrupt every 2mS.
  TCCR2A = 0x02;     // DISABLE PWM ON DIGITAL PINS 3 AND 11, AND GO INTO CTC MODE
  TCCR2B = 0x06;     // DON'T FORCE COMPARE, 256 PRESCALER 
  OCR2A = 0X7C;      // SET THE TOP OF THE COUNT TO 124 FOR 500Hz SAMPLE RATE
  TIMSK2 = 0x02;     // ENABLE INTERRUPT ON MATCH BETWEEN TIMER2 AND OCR2A
  sei();             // MAKE SURE GLOBAL INTERRUPTS ARE ENABLED      
} 


// THIS IS THE TIMER 2 INTERRUPT SERVICE ROUTINE. 
// Timer 2 makes sure that we take a reading every 2 miliseconds
ISR(TIMER2_COMPA_vect){                         // triggered when Timer2 counts to 124
    cli();                                      // disable interrupts while we do this
    SignalA = analogRead(pulsePinA);              // read the Pulse Sensor 
    SignalB = analogRead(pulsePinB);              // read the Pulse Sensor 
    sampleCounterA += 2;                         // keep track of the time in mS with this variable
    sampleCounterB += 2;                         // keep track of the time in mS with this variable
    int Na = sampleCounterA - lastBeatTimeA;       // monitor the time since the last beat to avoid noise
    int Nb = sampleCounterB - lastBeatTimeB;       // monitor the time since the last beat to avoid noise

//  find the peak and trough of the pulse wave
    if(SignalA < threshA && Na > (IBIa/5)*3){       // avoid dichrotic noise by waiting 3/5 of last IBI
        if (SignalA < Ta){                        // T is the trough
            Ta = SignalA;                         // keep track of lowest point in pulse wave 
         }
       }
      
    if(SignalA > threshA && SignalA > Pa){          // thresh condition helps avoid noise
        Pa = SignalA;                             // P is the peak
       }                                        // keep track of highest point in pulse wave
       
//  find the peak and trough of the pulse wave
    if(SignalB < threshB && Nb > (IBIb/5)*3){       // avoid dichrotic noise by waiting 3/5 of last IBI
        if (SignalB < Tb){                        // T is the trough
            Tb = SignalB;                         // keep track of lowest point in pulse wave 
         }
       }
      
    if(SignalB > threshB && SignalB > Pb){          // thresh condition helps avoid noise
        Pb = SignalB;                             // P is the peak
       }                                        // keep track of highest point in pulse wave
    
  //  NOW IT'S TIME TO LOOK FOR THE HEART BEAT
  // signal surges up in value every time there is a pulse
if (Na > 250){                                   // avoid high frequency noise
  if ( (SignalA > threshA) && (PulseA == false) && (Na > (IBIa/5)*3) ){        
    PulseA = true;                               // set the Pulse flag when we think there is a pulse
    digitalWrite(blinkPin,HIGH);                // turn on pin 13 LED
    IBIa = sampleCounterA - lastBeatTimeA;       // measure time between beats in mS
    lastBeatTimeA = sampleCounterA;               // keep track of time for next pulse
         
         if(firstBeatA){                         // if it's the first time we found a beat, if firstBeat == TRUE
             firstBeatA = false;                 // clear firstBeat flag
             return;                            // IBI value is unreliable so discard it
            }   
         if(secondBeatA){                        // if this is the second beat, if secondBeat == TRUE
            secondBeatA = false;                 // clear secondBeat flag
               for(int i=0; i<=9; i++){         // seed the running total to get a realisitic BPM at startup
                    rateA[i] = IBIa;                      
                    }
            }
          
    // keep a running total of the last 10 IBI values
    word runningTotalA = 0;                   // clear the runningTotal variable    

    for(int i=0; i<=8; i++){                // shift data in the rate array
          rateA[i] = rateA[i+1];              // and drop the oldest IBI value 
          runningTotalA += rateA[i];          // add up the 9 oldest IBI values
        }
        
    rateA[9] = IBIa;                          // add the latest IBI to the rate array
    runningTotalA += rateA[9];                // add the latest IBI to runningTotal
    runningTotalA /= 10;                     // average the last 10 IBI values 
    BPMa = 60000/runningTotalA;               // how many beats can fit into a minute? that's BPM!
    QSa = true;                              // set Quantified Self flag 
    // QS FLAG IS NOT CLEARED INSIDE THIS ISR
    }
}    

  //  NOW IT'S TIME TO LOOK FOR THE HEART BEAT
  // signal surges up in value every time there is a pulse
if (Nb > 250){                                   // avoid high frequency noise
  if ( (SignalB > threshB) && (PulseB == false) && (Nb > (IBIb/5)*3) ){        
    PulseB = true;                               // set the Pulse flag when we think there is a pulse
    digitalWrite(blinkPin,HIGH);                // turn on pin 13 LED
    IBIb = sampleCounterB - lastBeatTimeB;       // measure time between beats in mS
    lastBeatTimeB = sampleCounterB;               // keep track of time for next pulse
         
         if(firstBeatB){                         // if it's the first time we found a beat, if firstBeat == TRUE
             firstBeatB = false;                 // clear firstBeat flag
             return;                            // IBI value is unreliable so discard it
            }   
         if(secondBeatB){                        // if this is the second beat, if secondBeat == TRUE
            secondBeatB = false;                 // clear secondBeat flag
               for(int i=0; i<=9; i++){         // seed the running total to get a realisitic BPM at startup
                    rateB[i] = IBIb;                      
                    }
            }
          
    // keep a running total of the last 10 IBI values
    word runningTotalB = 0;                   // clear the runningTotal variable    

    for(int i=0; i<=8; i++){                // shift data in the rate array
          rateB[i] = rateB[i+1];              // and drop the oldest IBI value 
          runningTotalB += rateB[i];          // add up the 9 oldest IBI values
        }
        
    rateB[9] = IBIb;                          // add the latest IBI to the rate array
    runningTotalB += rateB[9];                // add the latest IBI to runningTotal
    runningTotalB /= 10;                     // average the last 10 IBI values 
    BPMb = 60000/runningTotalB;               // how many beats can fit into a minute? that's BPM!
    QSb = true;                              // set Quantified Self flag 
    // QS FLAG IS NOT CLEARED INSIDE THIS ISR
    }
}    


  if (SignalA < threshA && PulseA == true){     // when the values are going down, the beat is over
      digitalWrite(blinkPin,LOW);            // turn off pin 13 LED
      PulseA = false;                         // reset the Pulse flag so we can do it again
      ampA = Pa - Ta;                           // get amplitude of the pulse wave
      threshA = ampA/2 + Ta;                    // set thresh at 50% of the amplitude
      Pa = threshA;                            // reset these for next time
      Ta = threshA;
     }
  if (SignalB < threshB && PulseB == true){     // when the values are going down, the beat is over
      digitalWrite(blinkPin,LOW);            // turn off pin 13 LED
      PulseB = false;                         // reset the Pulse flag so we can do it again
      ampB = Pb - Tb;                           // get amplitude of the pulse wave
      threshB = ampB/2 + Tb;                    // set thresh at 50% of the amplitude
      Pb = threshB;                            // reset these for next time
      Tb = threshB;
     }
  
  if (Na > 2500){                             // if 2.5 seconds go by without a beat
      threshA = 512;                          // set thresh default
      Pa = 512;                               // set P default
      Ta = 512;                               // set T default
      lastBeatTimeA = sampleCounterA;          // bring the lastBeatTime up to date        
      firstBeatA = true;                      // set these to avoid noise
      secondBeatA = true;                     // when we get the heartbeat back
     }
     
  if (Nb > 2500){                             // if 2.5 seconds go by without a beat
      threshB = 512;                          // set thresh default
      Pb = 512;                               // set P default
      Tb = 512;                               // set T default
      lastBeatTimeB = sampleCounterB;          // bring the lastBeatTime up to date        
      firstBeatB = true;                      // set these to avoid noise
      secondBeatB = true;                     // when we get the heartbeat back
     }
  
  sei();                                     // enable interrupts when youre done!
}// end isr




