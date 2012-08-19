#include <SoftwareSerial.h>
#include <URMSerial.h>
#include <Servo.h>

// Servo
#define SERVO_LEFT_PIN  12
#define SERVO_RIGHT_PIN 13

// URM Settings
// LEFT sensor
#define URM_LEFT_TXD_PIN  11
#define URM_LEFT_RXD_PIN  10
// Right sensor
#define URM_RIGHT_TXD_PIN 8
#define URM_RIGHT_RXD_PIN 9


// Line tracker

#define LINE_TRACKER_PIN  0 // pin 2
#define LINE_TRACKER_STEP 6 // while label interruot (in cm)

// DC MOTOR

#define MOTOR_LEFT_EN  5
#define MOTOR_LEFT_IN  4
#define MOTOR_RIGHT_EN 6
#define MOTOR_RIGHT_IN 7
#define SPEED           255

#define MOVE_STOP  0
#define MOVE_LEFT  1
#define MOVE_RIGHT 2
#define MOVE_AHEAD 3
#define MOVE_BACK  4

Servo servoLeft;
Servo servoRight;
URMSerial urmLeft;
URMSerial urmRight;

int servoParammeter = 0;
    
volatile int moveStatus = 0;
volatile int distance   = 0;

void setup()
{
  Serial.begin(9600);
  servoLeft.attach(SERVO_LEFT_PIN);
  servoRight.attach(SERVO_RIGHT_PIN);
  servoLeft.write(90);
  servoRight.write(90);

  pinMode(MOTOR_LEFT_EN, OUTPUT);
  pinMode(MOTOR_LEFT_IN, OUTPUT);
  pinMode(MOTOR_RIGHT_EN, OUTPUT);
  pinMode(MOTOR_RIGHT_EN, OUTPUT);


  urmLeft.begin(8, 9, 9600);
  urmRight.begin(11, 10, 9600);
  attachInterrupt(LINE_TRACKER_PIN, lineTracking, RISING);
}

void loop()
{
  delay(100);
  String command;
  command = getCommand();

  if(command.length()){
    executeCommand(command);
  }
}

void lineTracking()
{
  int step = 0;

  if(moveStatus == MOVE_BACK){
    step = 0 - (int)LINE_TRACKER_STEP;
  }
  else if(moveStatus == MOVE_AHEAD){
    step = (int)LINE_TRACKER_STEP;
  }

  distance = distance + step;
}


String getCommand()
{
  String temp;
  String result;
  char symbol;
  boolean hasParammeters = false;

  String param;

  while(Serial.available() > 0){
    symbol = (char)Serial.read();

    if((int)symbol == 10){
      break;
    }
    else if((int)symbol == 61){
      hasParammeters = true;
    }
    else{
      if(hasParammeters == false){
        temp.concat(symbol);
      }
      else{
        param.concat(symbol);
      }
    }
  }

  //Serial.println(param);
  if(param.length() > 0){
    int capacity = 1;
    servoParammeter = 0;
    char chr;
    int num;
    int index;

    for(int i = 0; i < param.length(); i++){
      chr = param.charAt(i);
      num = (char)chr - 48 ;

      index= param.length() - i;

      for(int j = i; j<param.length(); j++){
        capacity = capacity * 10;
      }

      capacity = capacity/10;
      servoParammeter += num * capacity;
      capacity = 1;
    }

  }

  //Serial.println(temp);
  return temp;
}

void executeCommand(String command)
{
  String result;
  Serial.print(command);
  Serial.println(servoParammeter);
  Serial.flush();
  
  
  if(command == "getDistanceLeft"){
    result.concat(getMeasurement(urmLeft));
    output(result, false);
  }
  else if(command == "getDistanceRight"){
    result.concat(getMeasurement(urmRight));
    output(result, false);
  }
  else if(command == "turnServoLeft"){
    servoLeft.write(servoParammeter);
    output("OK",false);
  }
  else if(command == "turnServoRight"){
    servoRight.write(servoParammeter);
    output("OK",false);
  }
  else if(command == "moveAhead"){
    MotorLeft(SPEED, true);
    MotorRight(SPEED, true);
  }
  else if(command == "moveBack"){
    MotorLeft(SPEED, false);
    MotorRight(SPEED, false);
  }
  else if(command == "turnLeft"){
    MotorLeft(SPEED, false);
    MotorRight(SPEED, true);
  }
  else if(command == "turnRight"){
    MotorLeft(SPEED, true);
    MotorRight(SPEED, false);
  }
  else if(command == "stopMove"){
    MotorLeft(0, false);
    MotorRight(0, false);
  }  
 



}

void output(String result, boolean error)
{
  char delimiter = '|';

  Serial.print("RESULT=");

  if(error != 0){
    Serial.print("ERROR");
    Serial.print(delimiter);
    Serial.print("MESSAGE=");
  }

  Serial.println(result);
}



int getMeasurement(URMSerial urm)
{
    int value = 0;
    // Request a distance reading from the URM37
    switch(urm.requestMeasurementOrTimeout(DISTANCE, value)) // Find out the type of request
    {
        case DISTANCE: // Double check the reading we recieve is of DISTANCE type
            //    Serial.println(value); // Fetch the distance in centimeters from the URM37
            return value;
            break;
        case TEMPERATURE:
            return value;
            break;
        case ERROR:
            Serial.println("Error");
            break;
        case NOTREADY:
            Serial.println("Not Ready");
            break;
        case TIMEOUT:
            Serial.println("Timeout");
            break;
    } 

    return -1;
}


void MotorLeft(int motorSpeed, boolean reverse)
{
  analogWrite(MOTOR_LEFT_EN,motorSpeed); //set pwm control, 0 for stop, and 255 for maximum speed
  if(reverse)
  { 
    digitalWrite(MOTOR_LEFT_IN,HIGH);    
  }
  else
  {
    digitalWrite(MOTOR_LEFT_IN,LOW);    
  }
}  

void MotorRight(int motorSpeed, boolean reverse)
{
  analogWrite(MOTOR_RIGHT_EN,motorSpeed);
  if(!reverse)
  { 
    digitalWrite(MOTOR_RIGHT_IN,HIGH);    
  }
  else
  {
    digitalWrite(MOTOR_RIGHT_IN,LOW);    
  }
}  





