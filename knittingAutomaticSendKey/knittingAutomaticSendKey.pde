/*
* send key to kniting machine
*/
import processing.serial.*;

Serial myPort;  // Create object from Serial class

ArrayList keys;

String[] insertPattern = {"CE","INPUT","STEP","X","X","X","STEP","CE","X","X","X","STEP"};

float threshold = 127;
int cols = 60;
int rows = 60;
int[][] pixelArray; 
boolean serialIsConnected = false;

boolean insertingPattern = false;
boolean insertingPixelsPattern = false;
boolean insertingPatternEnd = false;
boolean pressUpkey = false;

float timeForSending = 0;
float timeStartSending = 0;
float timelastKeySend = 0;
float frequencyKeySend = 1500;
int insertPatternPointer = 0;
int rowtPixelPointer = 0;
int columntPixelPointer = 0;

PImage img;
PFont font;

void setup(){
  size(1024,900);
  font = loadFont("Dialog-12.vlw"); 
  setupKnitting();
  fillArrayWithImage("spam.png");
  setupSerialPort();
}

void draw(){
  background(51);
  fill(30);
  rect(690,0,width,height);
  image(img,700,20);
  fill(255);
  text("Press key \'f\': Choose file", 860, 30);
  text("Press key \'i\': Start", 860, 60);
  text("Press key \'s\': Stop", 860, 90);
  
  if(insertingPixelsPattern){
    color(255,0,0);
    //textFont(font, 12); 
    
    text("ROW:"+Integer.toString(rows-rowtPixelPointer), 860, 130);
    text("COLUMN:"+Integer.toString(columntPixelPointer), 860,180);
    int percentage = 100-(int)(((((float)rowtPixelPointer*(float)cols)+(float)columntPixelPointer) / ((float)cols*(float)rows))*100);
    text("PERCENTAGE:"+Integer.toString(percentage)+"%", 860,230);
  }
  
  int cubSize = 3;
  for(int x=0;x<cols;x++){
     for(int y=0;y<rows;y++){
       if(pixelArray[x][y]==1){
         fill(255);
       }else{
         fill(0);
       }
       if(insertingPixelsPattern && rowtPixelPointer==y && columntPixelPointer==x ){
         fill(255,0,0);
       }
       rect(x*cubSize, y*cubSize, cubSize,cubSize);
     }
   }
   
   // Calculating time spend for sending keys
   timeForSending = millis()-timeStartSending;
   // frequencyKeySend
   if(millis()-timelastKeySend> frequencyKeySend){
       timelastKeySend = millis();
       if((insertingPattern || insertingPixelsPattern || insertingPatternEnd)){
         if(pressUpkey){
           pressUpkey = false;
           pressKnittingKey("UP");
           println("Up set");
         }else if(insertingPattern){
           println(insertPattern[insertPatternPointer]);
           pressKnittingKey(insertPattern[insertPatternPointer]);
           insertPatternPointer++;
           
           while( insertPatternPointer<insertPattern.length && insertPattern[insertPatternPointer]=="X"){
             println("inside while");
             insertPatternPointer++;
           }
           //println("end while");
           //println(Integer.toString(insertPatternPointer)+">="+Integer.toString(insertPattern.length));
           if(insertPatternPointer>=insertPattern.length){ 
             insertingPattern = false;
             println("now pixels will come");
           }
         }else if(insertingPixelsPattern ){
           frequencyKeySend = 1000;
           if( isBlackPixel(columntPixelPointer,rowtPixelPointer) ){
             pressKnittingKey("BLACKSQUARE");
             columntPixelPointer++;
             if(columntPixelPointer>=cols){
               columntPixelPointer=0;
               rowtPixelPointer-=1;
              
               if(rowtPixelPointer<0){ 
                 insertingPixelsPattern = false;
               }else{
                 pressUpkey = true;
               }
             }
             println("blackpixel");
         }else if(anyMoreBlackInThisRow(columntPixelPointer,rowtPixelPointer)){
            pressKnittingKey("WHITESQUARE");
            columntPixelPointer++;
            if(columntPixelPointer>=cols){
              columntPixelPointer=0;
              rowtPixelPointer-=1;
              if(rowtPixelPointer<0){ 
                insertingPixelsPattern = false;
              }else{
                pressUpkey = true;
              }
            }
            println("whitepixel set");
         }else{
            columntPixelPointer=0;
            rowtPixelPointer-=1;
            if(rowtPixelPointer<0){ 
              insertingPixelsPattern = false;
              println("Arrive to end pixel");
            }else{
              pressUpkey = true;
            }
            
         }
       }else if(insertingPatternEnd){
         
         pressKnittingKey("INPUT");
         insertingPatternEnd = false;
         println("Press final input");
       }
     }
   }
   
}

void keyPressed(){
 // stop inserting pattern
 if(key=='s'){
   insertingPattern = false;
   insertingPixelsPattern = false;
 } 
 // insert
 if(key=='i'){
    insertingPattern = true;
    insertingPixelsPattern = true;
    insertingPatternEnd = true;
    pressUpkey = false;
    timeForSending = 0;
    rowtPixelPointer = rows-1;
    columntPixelPointer = 0;
    insertPatternPointer = 0;
    timeStartSending = millis();
 }
 if(key=='f'){
    String loadPath = selectInput();  // Opens file chooser
    if (loadPath == null) {
      // If a file was not selected
      println("No file was selected...");
    } else {
      // If a file was selected, print path to file
      fillArrayWithImage(loadPath);
    }
 }
}

void pressKnittingKey(String keyName){
 int keyKnittingCode = 0;
 for(int i=0; i<keys.size();i++){
   KeyKnitting temp =(KeyKnitting) keys.get(i);
   if(temp.keyName.equals(keyName)) keyKnittingCode = temp.code;
 }
 //println(keyKnittingCode);
 //println((char)keyKnittingCode);
 if(serialIsConnected) myPort.write((char)keyKnittingCode);
}

class KeyKnitting{
 String keyName;
 int code;
 KeyKnitting(String _keyName, int _code){
   keyName = _keyName;
   code = _code;
 }
}


