#include "URMSerial.h"
#include <Servo.h>

// The measurement we're taking
#define DISTANCE        1
#define TEMPERATURE     2
#define ERROR           3
#define NOTREADY        4
#define TIMEOUT         5

// Servo
#define SERVO_LEFT_PIN  8
#define SERVO_RIGHT_PIN 9

// URM
#define URM_LEFT_TXD_PIN  10
#define URM_LEFT_RXD_PIN  11
#define URM_RIGHT_TXD_PIN 12
#define URM_RIGHT_RXD_PIN 13

// DC MOTOR

#define MOTOR_LEFT_EN  5
#define MOTOR_LEFT_IN  4
#define MOTOR_RIGHT_EN 6
#define MOTOR_RIGHT_IN 7
#define SPEED           255

Servo servoLeft;
Servo servoRight;
URMSerial urmLeft;
URMSerial urmRight;


int servoLeftPosition;
int servoRightPosition;
int servoParammeter = 90;

void setup()
{
  Serial.begin(9600);
  servoLeft.attach(SERVO_LEFT_PIN);
  servoRight.attach(SERVO_RIGHT_PIN);

  for(int i = 5; i < 8; i++){
    pinMode(i, OUTPUT);
  }

  urmLeft.begin(URM_LEFT_TXD_PIN, URM_LEFT_RXD_PIN, 9600);
  urmRight.begin(URM_RIGHT_TXD_PIN, URM_RIGHT_RXD_PIN, 9600);
}

void loop()
{
  String command;
  // Serial.flush();
  command = getCommand();

  if(command.length()){
    executeCommand(command);
    Serial.flush();
  }
  //
  //Serial.flush();

  delay(100);
}

String getCommand()
{
  String temp;
  String result;
  char symbol;
  boolean isParammeters = false;

  String param;

  while(Serial.available() > 0){
    symbol = (char)Serial.read();

    if((int)symbol == 10){
      break;
    }
    else if((int)symbol == 61){
      isParammeters = true;
    }
    else{
      if(isParammeters == false){
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

    char chr;
    int num;
    servoParammeter = 0;
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



  return temp;
}

void executeCommand(String command)
{
  String result;

  if(command == "getDistanceLeft"){
    result = getMeasurement(urmLeft);
    output(result, false);
  }
  else if(command == "getDistanceRight"){
    result = getMeasurement(urmRight);
    output(result, false);
  }
  else if(command == "turnServoLeft"){
    servoLeftPosition = servoParammeter;
    servoLeft.write(servoLeftPosition);
    output("OK", false);
  }
  else if(command == "turnServoRight"){
    servoRightPosition = servoParammeter;
    servoRight.write(servoRightPosition);
    output("OK", false);
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
  else{
    output("Command not found", true);
  }


  Serial.flush();

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
  int value = 0; // This value will be populated

  // Request a distance reading from the URM37
  switch(urm.requestMeasurementOrTimeout(DISTANCE, value)) // Find out the type of request
  {
  case DISTANCE: // Double check the reading we recieve is of DISTANCE type
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
  if(reverse)
  { 
    digitalWrite(MOTOR_RIGHT_IN,HIGH);    
  }
  else
  {
    digitalWrite(MOTOR_RIGHT_IN,LOW);    
  }
}  



