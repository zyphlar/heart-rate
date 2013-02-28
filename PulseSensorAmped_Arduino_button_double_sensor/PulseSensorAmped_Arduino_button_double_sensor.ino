
/*
>> Pulse Sensor Amped 1.1 <<
This code is for Pulse Sensor Amped by Joel Murphy and Yury Gitman
    www.pulsesensor.com 
    >>> Pulse Sensor purple wire goes to Analog Pin 0 <<<
Pulse Sensor sample aquisition and processing happens in the background via Timer 2 interrupt. 2mS sample rate.
PWM on pins 3 and 11 will not work when using this code, because we are using Timer 2!
The following variables are automatically updated:
Signal :    int that holds the analog signal data straight from the sensor. updated every 2mS.
IBI  :      int that holds the time interval between beats. 2mS resolution.
BPM  :      int that holds the heart rate value, derived every beat, from averaging previous 10 IBI values.
QS  :       boolean that is made true whenever Pulse is found and BPM is updated. User must reset.
Pulse :     boolean that is true when a heartbeat is sensed then false in time with pin13 LED going out.

This code is designed with output serial data to Processing sketch "PulseSensorAmped_Processing-xx"
The Processing sketch is a simple data visualizer. 
All the work to find the heartbeat and determine the heartrate happens in the code below.
Pin 13 LED will blink with heartbeat.
If you want to use pin 13 for something else, adjust the interrupt handler
It will also fade an LED on pin fadePin with every beat. Put an LED and series resistor from fadePin to GND.
Check here for detailed code walkthrough:
http://pulsesensor.myshopify.com/pages/pulse-sensor-amped-arduino-v1dot1

Code Version 02 by Joel Murphy & Yury Gitman  Fall 2012
This update changes the HRV variable name to IBI, which stands for Inter-Beat Interval, for clarity.
Switched the interrupt to Timer2.  500Hz sample rate, 2mS resolution IBI value.
Fade LED pin moved to pin 5 (use of Timer2 disables PWM on pins 3 & 11).
Tidied up inefficiencies since the last version. 
*/

/*
  Button
 
 Adds a "skip" button to the circuit
 
 The circuit:
 * pushbutton and 10K resistor from +5V (or buttonPwrPin) attached to buttonPin
 * other leg of pushbutton attached to ground

*/


//  VARIABLES

// button:
const int buttonPin = 10;     // the number of the pushbutton pin
const int buttonPwrPin = 12;     // pin to keep HIGH for power

// heart rate:
int blinkPin = 13;                // pin to blink led at each beat

int pulsePinA = 0;                 // Pulse Sensor purple wire connected to analog pin 0
int fadePinA = 5;                  // pin to do fancy classy fading blink at each beat
int fadeRateA = 0;                 // used to fade LED on with PWM on fadePin

int pulsePinB = 1;                 // Pulse Sensor purple wire connected to analog pin 0
int fadePinB = 6;                  // pin to do fancy classy fading blink at each beat
int fadeRateB = 0;                 // used to fade LED on with PWM on fadePin


/* BUTTON STUFF */
// Variables will change:
int ledState = HIGH;         // the current state of the output pin
int buttonState;             // the current reading from the input pin
int lastButtonState = LOW;   // the previous reading from the input pin

// the following variables are long's because the time, measured in miliseconds,
// will quickly become a bigger number than can be stored in an int.
long lastDebounceTime = 0;  // the last time the output pin was toggled
long debounceDelay = 50;    // the debounce time; increase if the output flickers

/* HEART RATE SENSOR STUFF */
// these variables are volatile because they are used during the interrupt service routine!
volatile int BPMa;                   // used to hold the pulse rate
volatile int SignalA;                // holds the incoming raw data
volatile int IBIa = 600;             // holds the time between beats, the Inter-Beat Interval
volatile boolean PulseA = false;     // true when pulse wave is high, false when it's low
volatile boolean QSa = false;        // becomes true when Arduoino finds a beat.

volatile int BPMb;                   // used to hold the pulse rate
volatile int SignalB;                // holds the incoming raw data
volatile int IBIb = 600;             // holds the time between beats, the Inter-Beat Interval
volatile boolean PulseB = false;     // true when pulse wave is high, false when it's low
volatile boolean QSb = false;        // becomes true when Arduoino finds a beat.


void setup(){
  /* BUTTON STUFF */
  // initialize the pushbutton pin as an input:
  pinMode(buttonPin, INPUT);
  pinMode(buttonPwrPin, OUTPUT);  
  digitalWrite(buttonPwrPin, HIGH);  
  
  /* HEART RATE SENSOR STUFF */
  pinMode(blinkPin,OUTPUT);         // pin that will blink to your heartbeat!
  pinMode(fadePinA,OUTPUT);          // pins that will fade to your heartbeat!
  pinMode(fadePinB,OUTPUT);         
  Serial.begin(115200);             // we agree to talk fast!
  interruptSetup();                 // sets up to read Pulse Sensor signal every 2mS 
   // UN-COMMENT THE NEXT LINE IF YOU ARE POWERING The Pulse Sensor AT LOW VOLTAGE, 
   // AND APPLY THAT VOLTAGE TO THE A-REF PIN
   //analogReference(EXTERNAL);   
   
   
}



void loop(){
  /* BUTTON STUFF */
  
   // read the state of the switch into a local variable:
  int reading = digitalRead(buttonPin);

  // check to see if you just pressed the button 
  // (i.e. the input went from LOW to HIGH),  and you've waited 
  // long enough since the last press to ignore any noise:  

  // If the switch changed, due to noise or pressing:
  if (reading != lastButtonState) {
    // reset the debouncing timer
    lastDebounceTime = millis();
  } 
  
  if ((millis() - lastDebounceTime) > debounceDelay) {
    // whatever the reading is at, it's been there for longer
    // than the debounce delay, so take it as the actual current state:
    buttonState = reading;
  }
  
  if(buttonState == 1){
    sendDataToProcessing('U',1); 
  }

  // save the reading.  Next time through the loop,
  // it'll be the lastButtonState:
  lastButtonState = reading;
  
  
  /* HEART RATE SENSOR STUFF */
  sendDataToProcessing('S', SignalA);     // send Processing the raw Pulse SensorA data
  sendDataToProcessing('T', SignalB);     // send Processing the raw Pulse SensorB data
  if (QSa == true){                       // Quantified Self flag is true when arduino finds a heartbeat
    fadeRateA = 255;                  // Set 'fadeRate' Variable to 255 to fade LED with pulse
    sendDataToProcessing('B',BPMa);   // send heart rate with a 'B' prefix
    sendDataToProcessing('Q',IBIa);   // send time between beats with a 'Q' prefix
    QSa = false;                      // reset the Quantified Self flag for next time    
  }
  if (QSb == true){                       // Quantified Self flag is true when arduino finds a heartbeat
    fadeRateB = 255;                  // Set 'fadeRate' Variable to 255 to fade LED with pulse
    sendDataToProcessing('C',BPMb);   // send heart rate with a 'C' prefix
    sendDataToProcessing('R',IBIb);   // send time between beats with a 'R' prefix
    QSb = false;                      // reset the Quantified Self flag for next time  
  }
  ledFadeToBeat();
  
  delay(20);                             //  take a break
}


void ledFadeToBeat(){
    fadeRateA -= 15;                         //  set LED fade value
    fadeRateA = constrain(fadeRateA,0,255);   //  keep LED fade value from going into negative numbers!
    fadeRateB -= 15;                         //  set LED fade value
    fadeRateB = constrain(fadeRateB,0,255);   //  keep LED fade value from going into negative numbers!
    analogWrite(fadePinA,fadeRateA);          //  fade LED
    analogWrite(fadePinB,fadeRateB);          //  fade LED
  }


void sendDataToProcessing(char symbol, int data ){
    Serial.print(symbol);                // symbol prefix tells Processing what type of data is coming
    Serial.println(data);                // the data to send culminating in a carriage return
  }







