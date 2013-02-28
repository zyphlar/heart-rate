/*
THIS PROGRAM WORKS WITH PulseSensorAmped_Arduino_1dot1_button ARDUINO CODE
Will Bradley, 2013
Based on JOEL MURPHY, AUGUST 2012
*/

int screenWidth = 1024;
int screenHeight = 768;

boolean sketchFullScreen() {
  return true;
}

/* Heart Rate & serial stuff */
import processing.serial.*;
PFont font;
Scrollbar scaleBar;
Serial port;    
float zoom;      // USED WHEN SCALING PULSE WAVEFORM TO PULSE WINDOW
float offset;    // USED WHEN SCALING PULSE WAVEFORM TO PULSE WINDOW

int SensorA;      // HOLDS PULSE SENSOR DATA FROM ARDUINO
int IBIa;         // HOLDS TIME BETWEN HEARTBEATS FROM ARDUINO
int BPMa;         // HOLDS HEART RATE VALUE FROM ARDUINO
int[] RawYa;      // HOLDS HEARTBEAT WAVEFORM DATA BEFORE SCALING
int[] ScaledYa;   // USED TO POSITION SCALED HEARTBEAT WAVEFORM
int[] rateA;      // USED TO POSITION BPM DATA WAVEFORM
int heartA = 0;   // This variable times the heart image 'pulse' on screen
boolean beatA = false;

int SensorB;      // HOLDS PULSE SENSOR DATA FROM ARDUINO
int IBIb;         // HOLDS TIME BETWEN HEARTBEATS FROM ARDUINO
int BPMb;         // HOLDS HEART RATE VALUE FROM ARDUINO
int[] RawYb;      // HOLDS HEARTBEAT WAVEFORM DATA BEFORE SCALING
int[] ScaledYb;   // USED TO POSITION SCALED HEARTBEAT WAVEFORM
int[] rateB;      // USED TO POSITION BPM DATA WAVEFORM
int heartB = 0;   // This variable times the heart image 'pulse' on screen
boolean beatB = false;

color eggshell = color(255, 253, 248);

/* button stuff */
int ButtonState = 0;         // HOLDS BUTTON VALUE FROM ARDUINO
int ButtonTime = 0;         // HOLDS BUTTON VALUE FROM ARDUINO
int ButtonDebounce = 800;  // ms between buttonpresses

/* video stuff */
import processing.video.*;
   
Movie theMov; 
boolean isPlaying;
boolean isLooping;

boolean isLoop = false;
boolean isCountdown = false;
boolean isPlane = false;
boolean isBaby = false;

String[] sectionLabels = {"A","B","C","D","E","F","G"};
int[] sectionEndTimes =  { 10, 20, 30, 40, 50, 60, 70};
int[] playerAresults;
int[] playerBresults;

int thisSectionIndex = 0;  // keeping track of which section we're on


void setup() {  
  /* Heart Rate Stuff */
  size(sketchWidth(), sketchHeight());
  //if (frame != null) {
  //  frame.setResizable(true);
  //}
  frameRate(100);  
  font = loadFont("Arial-BoldMT-24.vlw");
  textFont(font);
  textAlign(CENTER);
  rectMode(CENTER);
  ellipseMode(CENTER);  
  // Scrollbar constructor inputs: x,y,width,height,minVal,maxVal
  scaleBar = new Scrollbar (75, sketchHeight()-60, 140, 12, 0.5, 1.0);  // set parameters for the scale bar
  RawYa = new int[PulseWindowWidth()];          // initialize raw pulse waveform array
  ScaledYa = new int[PulseWindowWidth()];       // initialize scaled pulse waveform array
  RawYb = new int[PulseWindowWidth()];          // initialize raw pulse waveform array
  ScaledYb = new int[PulseWindowWidth()];       // initialize scaled pulse waveform array
  rateA = new int [BPMWindowWidth()];           // initialize BPM waveform array
  rateB = new int [BPMWindowWidth()];           // initialize BPM waveform array
  
  playerAresults = new int [sectionEndTimes.length];
  playerBresults = new int [sectionEndTimes.length];
  
  // set the visualizer lines to 0
  for (int i=0; i<rateB.length; i++){
    rateA[i] = BPMWindowHeight();      // Place BPM graph line at bottom of BPM Window 
  }
  for (int i=0; i<RawYb.length; i++){
    RawYa[i] = sketchHeight()/2; // initialize the pulse window data line to V/2
  }
  for (int i=0; i<rateB.length; i++){
    rateB[i] = BPMWindowHeight();      // Place BPM graph line at bottom of BPM Window 
  }
  for (int i=0; i<RawYb.length; i++){
    RawYb[i] = sketchHeight()/2; // initialize the pulse window data line to V/2
  }
  zoom = 0.75;                               // initialize scale of heartbeat window
    
   
  // GO FIND THE ARDUINO
  println("Serial Devices Found: {");
  println(Serial.list());    // print a list of available serial ports
  // choose the number between the [] that is connected to the Arduino
  println("}");
  
  if(Serial.list().length >= 1) {
    int serialPort = -1;
    
    // macs
    for(int i=0;i<Serial.list().length;i++){
      if( Serial.list()[i].indexOf("tty.usb") >= 0 ) {
        serialPort = i;
        break;  // key on the first tty.usb
      }
    }
    // linux
    if(serialPort == -1){
      for(int i=0;i<Serial.list().length;i++){
        if( Serial.list()[i].indexOf("tty") >= 0 ) {
          serialPort = i;
          break;  // key on the first tty
        }
      }
    }
    
    
    if(serialPort > -1) {
      port = new Serial(this, Serial.list()[serialPort], 115200);  // make sure Arduino is talking serial at this baud rate
      port.clear();            // flush buffer
      port.bufferUntil('\n');  // set buffer full flag on receipt of carriage return
      
      println("Using serial port #"+serialPort);
    }
    else {
      println("FAILED to find serial port with 'tty' in the name.");
      println("IS THE ARDUINO PLUGGED IN?");
      exit(); 
    }
  }
  else {
    println("FAILED to find serial port: "+Serial.list().length+" ports available.");
    println("IS THE ARDUINO PLUGGED IN?");
    exit(); 
  }

  /* video stuff */
  theMov = new Movie(this, "loop.mov");
  theMov.loop();  // make sure the loop actually loops
  isPlaying = true;
  isLoop = true;
}

void draw() {
  
  background(0);
  
  /* Video Stuff */
  image(theMov, 0,0);
  
  
  // Automatically advance
  if(isCountdown && theMov.duration()-theMov.time() < 1){ // auto after countdown: play plane
    ButtonState = 1;  //cheap hack
  }
  if(isPlane && theMov.duration()-theMov.time() < 1){ // auto after plane: play baby
    text("GOGOGO",100,100);
    ButtonState = 1;  // cheap hack
  }
  
  // Handle Button Push
  if(ButtonState > 0) {
    if (isLoop) { // loop: play countdown
      theMov.stop();
      theMov = new Movie(this, "countdown.mov");
      isPlane = false;
      isBaby = false;
      isLoop = false;
      isCountdown = true;
      theMov.play();
    } else if(isCountdown) { // countdown: play plane
      theMov.stop();
      theMov = new Movie(this, "baby.mov");
      isPlane = true;
      isBaby = false;
      isLoop = false;
      isCountdown = false;
      theMov.play(); 
    } else if(isPlane){ // plane: play baby
      theMov.stop();
      theMov = new Movie(this, "plane.mp4");
      isPlane = false;
      isBaby = true;
      isLoop = false;
      isCountdown = false;
      theMov.play();
    } else if(isBaby){ // baby: play loop AND CLEAR VALUES
      thisSectionIndex = 0;
      playerAresults = new int [sectionEndTimes.length];
      playerBresults = new int [sectionEndTimes.length];
  
      theMov.stop();
      theMov = new Movie(this, "loop.mov");
      isPlane = false;
      isBaby = false;
      isLoop = true;
      isCountdown = false;
      theMov.play();
      theMov.loop();  // make sure the loop actually loops
    }
    ButtonState = 0;
  } // end of button push
  
  /* Heart Rate Stuff */
  noStroke();
  // DRAW OUT THE PULSE WINDOW AND BPM WINDOW RECTANGLES  
  fill(eggshell);  // color for the window background
  // pulsewindow
  rect(PulseWindowWidth()/2+10,sketchHeight()/2,PulseWindowWidth(),PulseWindowHeight());
  // bpmwindow
  rect(PulseWindowWidth()+BPMWindowWidth()/2+20,sketchHeight()/2,BPMWindowWidth(),BPMWindowHeight());
  
  // DRAW THE PULSE WAVEFORM
  // prepare pulse data points    
  RawYa[RawYa.length-1] = (1023 - SensorA) - 212;   // place the new raw datapoint at the end of the array
  RawYb[RawYb.length-1] = (1023 - SensorB) - 212;   // place the new raw datapoint at the end of the array
  zoom = scaleBar.getPos();                      // get current waveform scale value
  offset = map(zoom,0.5,1,150,0);                // calculate the offset needed at this scale
  for (int i = 0; i < RawYa.length-1; i++) {      // move the pulse waveform by
    RawYa[i] = RawYa[i+1];                         // shifting all raw datapoints one pixel left
    float dummy = RawYa[i] * zoom + offset;       // adjust the raw data to the selected scale
    ScaledYa[i] = constrain(int(dummy),sketchHeight()/2-BPMWindowHeight()/2-10,sketchHeight()/2);   // transfer the raw data array to the scaled array
  }
  for (int i = 0; i < RawYb.length-1; i++) {      // move the pulse waveform by
    RawYb[i] = RawYb[i+1];                         // shifting all raw datapoints one pixel left
    float dummy = RawYb[i] * zoom + offset;       // adjust the raw data to the selected scale
    ScaledYb[i] = constrain(int(dummy)+BPMWindowHeight()/2,sketchHeight()/2+10,sketchHeight()/2+BPMWindowHeight()/2);   // transfer the raw data array to the scaled array
  }
  stroke(250,0,0);                               // red is a good color for the pulse waveform
  noFill();
  beginShape();                                  // using beginShape() renders fast
  for (int x = 1; x < ScaledYa.length-1; x++) {    
    vertex(x+10, ScaledYa[x]);                    //draw a line connecting the data points
  }
  endShape();
  stroke(0,0,250);
  beginShape();                                  // using beginShape() renders fast
  for (int x = 1; x < ScaledYb.length-1; x++) {    
    vertex(x+10, ScaledYb[x]);                    //draw a line connecting the data points
  }
  endShape();
  
  // Advance sections if necessary (right before the BPM measurement below)
  if(isPlane) {
    if(theMov.time() > sectionEndTimes[thisSectionIndex]
      && sectionEndTimes.length-1 > thisSectionIndex)
    {
      thisSectionIndex++;
    }
  }
    
  // DRAW THE BPM WAVE FORM
  // first, shift the BPM waveform over to fit then next data point only when a beat is found
  if (beatA == true){   // move the heart rate line over one pixel every time the heart beats 
    beatA = false;      // clear beat flag (beat flag waset in serialEvent tab)
    for (int i=0; i<rateA.length-1; i++){
      rateA[i] = rateA[i+1];                  // shift the bpm Y coordinates over one pixel to the left
    }
    // then limit and scale the BPM value
    BPMa = min(BPMa,200);                     // limit the highest BPM value to 200
    float dummy = map(BPMa,0,400,200,0);   // map it to the heart rate window Y (inverse)
    rateA[rateA.length-1] = int(dummy);       // set the rightmost pixel to the new data point value
    
    if(isPlane) {
      playerAresults[thisSectionIndex] = (playerAresults[thisSectionIndex]+BPMa)/2;  // store results for this section
    }
  } 
  if (beatB == true){   // move the heart rate line over one pixel every time the heart beats 
    beatB = false;      // clear beat flag (beat flag waset in serialEvent tab)
    for (int i=0; i<rateB.length-1; i++){
      rateB[i] = rateB[i+1];                  // shift the bpm Y coordinates over one pixel to the left
    }
    // then limit and scale the BPM value
    BPMb = min(BPMb,200);                     // limit the highest BPM value to 200
    float dummy = map(BPMb,0,400,200,0);   // map it to the heart rate window Y (inverse)
    rateB[rateB.length-1] = int(dummy);       // set the rightmost pixel to the new data point value
    
    if(isPlane) {
      playerBresults[thisSectionIndex] = (playerBresults[thisSectionIndex]+BPMb)/2;  // store results for this section
    }
  } 
  // GRAPH THE HEART RATE WAVEFORM
  stroke(250,0,0);                          // color of heart rate graph
  strokeWeight(2);                          // thicker line is easier to read
  noFill();
  beginShape();
  for (int i=0; i < rateA.length-1; i++){    // variable 'i' will take the place of pixel x position   
    vertex(i+PulseWindowWidth()+20, rateA[i]/2+sketchHeight()/2-PulseWindowHeight()/4);                 // display history of heart rate datapoints
  }
  endShape();
  stroke(0,0,250);                          // color of heart rate graph
  beginShape();
  for (int i=0; i < rateB.length-1; i++){    // variable 'i' will take the place of pixel x position   
    vertex(i+PulseWindowWidth()+20, rateB[i]/2+sketchHeight()/2);                 // display history of heart rate datapoints
  }
  endShape();
 
  // DRAW THE HEART AND MAYBE MAKE IT BEAT
  fill(250,0,0);
  stroke(250,0,0);
  // the 'heart' variable is set in serialEvent when arduino sees a beat happen
  heartA--;                    // heart is used to time how long the heart graphic swells when your heart beats
  heartA = max(heartA,0);       // don't let the heart variable go into negative numbers
  if (heartA > 0){             // if a beat happened recently, 
    strokeWeight(8);          // make the heart big
  }
  smooth();   // draw the heart with two bezier curves
  bezier(width-300,50, width-220,-20, width-200,140, width-300,150);
  bezier(width-300,50, width-390,-20, width-400,140, width-300,150);
  strokeWeight(1);          // reset the strokeWeight for next time

  fill(0,0,250);
  stroke(0,0,250);
  // the 'heart' variable is set in serialEvent when arduino sees a beat happen
  heartB--;                    // heart is used to time how long the heart graphic swells when your heart beats
  heartB = max(heartB,0);       // don't let the heart variable go into negative numbers
  if (heartB > 0){             // if a beat happened recently, 
    strokeWeight(8);          // make the heart big
  }
  smooth();   // draw the heart with two bezier curves
  bezier(width-100,50, width-20,-20, width,140, width-100,150);
  bezier(width-100,50, width-190,-20, width-200,140, width-100,150);
  strokeWeight(1);          // reset the strokeWeight for next time


  // PRINT THE DATA AND VARIABLE VALUES
  fill(eggshell);                                       // get ready to print text
  text("Are You In Sync?",245,30);     // tell them what you are
  //text("IBI " + IBIa + "mS",600,575);                    // print the time between heartbeats in mS
  text(BPMa + " BPM",sketchWidth()-300,190);                           // print the Beats Per Minute
  //text("IBI " + IBIb + "mS",600,595);                    // print the time between heartbeats in mS
  text(BPMb + " BPM",sketchWidth()-100,190);                           // print the Beats Per Minute
  text("Pulse Window Scale " + nf(zoom,1,2), 300, sketchHeight()-50); // show the current scale of Pulse Window
  
  //  DO THE SCROLLBAR THINGS
  scaleBar.update (mouseX, mouseY);
  scaleBar.display();
  
  
  /* Overlay stuff (corresponds with video) */
  
  if(isPlane) {
    
    text("Section: "+sectionLabels[thisSectionIndex],100,100);
    text("Player A: "+BPMa,100,150); //playerAresults
    text("Player B: "+BPMb,100,200);
  }
  if(isBaby){
    for(int i=0;i<sectionEndTimes.length-1;i++){
      text("Section: "+sectionLabels[i],100,50*i+100);
      text("A: "+playerBresults[i],220,50*i+100);
      text("B: "+playerAresults[i],320,50*i+100);
      
      String syncrating = "NO";
      if(abs(playerAresults[i]-playerBresults[i]) < 10){
        syncrating = "YES";
      }
      text("Sync? "+syncrating,450,50*i+100);
    }
    
    // after 30 secs, timeout
    if(theMov.time() > 30){ 
      ButtonState = 1;  // cheap hack
    }
  }
  
} // end of draw loop



void movieEvent(Movie m) { 
  m.read(); 
} 


void serialEvent(Serial port){ 
   String inData = port.readStringUntil('\n');
   inData = trim(inData);                 // cut off white space (carriage return)
   
   if (inData.charAt(0) == 'S'){          // leading 'S' for sensor data
     inData = inData.substring(1);        // cut off the leading 'S'
     SensorA = int(inData);                // convert the string to usable int
   }
   if (inData.charAt(0) == 'T'){          // leading 'S' for sensor data
     inData = inData.substring(1);        // cut off the leading 'S'
     SensorB = int(inData);                // convert the string to usable int
   }
   if (inData.charAt(0) == 'B'){          // leading 'B' for BPM data
     inData = inData.substring(1);        // cut off the leading 'B'
     BPMa = int(inData);                   // convert the string to usable int
     beatA = true;                         // set beat flag to advance heart rate graph
     heartA = 20;                          // begin heart image 'swell' timer
   }
   if (inData.charAt(0) == 'C'){          // leading 'B' for BPM data
     inData = inData.substring(1);        // cut off the leading 'B'
     BPMb = int(inData);                   // convert the string to usable int
     beatB = true;                         // set beat flag to advance heart rate graph
     heartB = 20;                          // begin heart image 'swell' timer
   }
   if (inData.charAt(0) == 'Q'){            // leading 'Q' means IBI data 
     inData = inData.substring(1);        // cut off the leading 'Q'
     IBIa = int(inData);                   // convert the string to usable int
   }
   if (inData.charAt(0) == 'R'){            // leading 'Q' means IBI data 
     inData = inData.substring(1);        // cut off the leading 'Q'
     IBIb = int(inData);                   // convert the string to usable int
   }
   if (inData.charAt(0) == 'U'){            // leading 'U' means button data 
     inData = inData.substring(1);        // cut off the leading 'U'
     if(millis()-ButtonTime > ButtonDebounce) {
       ButtonTime = millis();
       ButtonState = 1;
     }
   }
}


/*
    THIS SCROLLBAR OBJECT IS BASED ON THE ONE FROM THE BOOK "Processing" by Reas and Fry
*/

class Scrollbar{
 int x,y;               // the x and y coordinates
 float sw, sh;          // width and height of scrollbar
 float pos;             // position of thumb
 float posMin, posMax;  // max and min values of thumb
 boolean rollover;      // true when the mouse is over
 boolean locked;        // true when it's the active scrollbar
 float minVal, maxVal;  // min and max values for the thumb
 
 Scrollbar (int xp, int yp, int w, int h, float miv, float mav){ // values passed from the constructor
  x = xp;
  y = yp;
  sw = w;
  sh = h;
  minVal = miv;
  maxVal = mav;
  pos = x - sh/2;
  posMin = x-sw/2;
  posMax = x + sw/2;  // - sh; 
 }
 
 // updates the 'over' boolean and position of thumb
 void update(int mx, int my) {
   if (over(mx, my) == true){
     rollover = true;            // when the mouse is over the scrollbar, rollover is true
   } else {
     rollover = false;
   }
   if (locked == true){
    pos = constrain (mx, posMin, posMax);
   }
 }

 // locks the thumb so the mouse can move off and still update
 void press(int mx, int my){
   if (rollover == true){
    locked = true;            // when rollover is true, pressing the mouse button will lock the scrollbar on
   }else{
    locked = false;
   }
 }
 
 // resets the scrollbar to neutral
 void release(){
  locked = false; 
 }
 
 // returns true if the cursor is over the scrollbar
 boolean over(int mx, int my){
  if ((mx > x-sw/2) && (mx < x+sw/2) && (my > y-sh/2) && (my < y+sh/2)){
   return true;
  }else{
   return false;
  }
 }
 
 // draws the scrollbar on the screen
 void display (){

  noStroke();
  fill(255);
  rect(x, y, sw, sh);      // create the scrollbar
  fill (250,0,0);
  if ((rollover == true) || (locked == true)){             
   stroke(250,0,0);
   strokeWeight(8);           // make the scale dot bigger if you're on it
  }
  ellipse(pos, y, sh, sh);     // create the scaling dot
  strokeWeight(1);            // reset strokeWeight
 }
 
 // returns the current value of the thumb
 float getPos() {
  float scalar = sw / sw;  // (sw - sh/2);
  float ratio = (pos-(x-sw/2)) * scalar;
  float p = minVal + (ratio/sw * (maxVal - minVal));
  return p;
 } 
 }
 
 
void mousePressed(){
  scaleBar.press(mouseX, mouseY);
}

void mouseReleased(){
  scaleBar.release();
}

void keyPressed(){

 switch(key){
   case ' ':    // pressing space will emulate a button press.
     ButtonTime = millis();
     ButtonState = 1;
   break;
   default:
     break;
 }
}

public int sketchWidth() {
  if(displayWidth > 0) {
    return displayWidth;
  }
  else {
    return screenWidth;
  }
}
public int sketchHeight() {
  if(displayHeight > 0) {
    return displayHeight;
  }
  else {
    return screenHeight;
  }
}

// close serial port before exit
void exit() {
  port.stop();
  super.exit();
}

//  THESE VARIABLES DETERMINE THE SIZE OF THE DATA WINDOWS
public int PulseWindowWidth(){
 return parseInt(sketchWidth()*0.4);
}
public int PulseWindowHeight(){
 return parseInt(sketchHeight()*0.7);
} 
public int BPMWindowWidth(){
 return parseInt(sketchWidth()*0.2);
}
public int BPMWindowHeight(){
 return parseInt(sketchHeight()*0.4);
}
