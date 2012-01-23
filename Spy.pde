#define SERVO_PIN  3
#define SENSOR_PIN A0
#define LEFT_MOTOR_PIN1 6
#define LEFT_MOTOR_PIN2 5
#define RIGHT_MOTOR_PIN1 7
#define RIGHT_MOTOR_PIN2 4
#define SPEED 255

#include <LiquidCrystal.h>
#include <Servo.h> 

boolean LCD_ON  = false;

// Инициализируем объект-экран, передаём использованные 
// RS, E, DB5, DB6, DB7, DB8

LiquidCrystal lcd(8, 9, 10, 11, 12, 13);

byte displayLinesCount = 4;
byte displayCurrentLine = 0;
byte dislpayMaxColumns = 20;

Servo servo;
int servoPosition = 90;
boolean servoDirection = true; // false - left | true - righ

void setup() 
{
  lcd.begin(20, 4);

  lcd.home();
  lcd.noAutoscroll();
  lcd.cursor();

  displayMessage("Initialization");

  displayMessage("Prepare serial");
  Serial.begin(9600);
  displayMessage("Serial is ready");

  displayMessage("Initialize servo");
  servo.attach(SERVO_PIN);
  servo.write(0);
  delay(2000);
  servo.write(180);
  delay(2000);
  servo.write(servoPosition);
  displayMessage("Servo is ready");

  displayMessage("Starting");  
  delay(5000);    
}




void loop() 
{

  delay(1000);
  int value = analogRead(SENSOR_PIN);

  int distance = (int)getDistance(value);

  char* temp;

  lcd.print("Distance=");
  lcd.print(distance);
  moveCursorToNextLine();

  Serial.print("Distance=");
  Serial.println(distance);


  int servoPos = getNextServoPosition();

  lcd.print("Servo pos=");
  lcd.print(servoPos);
  moveCursorToNextLine();

  Serial.print("Servo pos =");
  Serial.println(servoPos);

  servo.write(servoPos);
  Serial.println("---------------------");
  Serial.flush();


}





int getNextServoPosition()
{
  if(servoPosition >= 180){
    servoDirection = false;
  }
  else if(servoPosition <= 0){
    servoDirection = true;
  } 

  Serial.print("Servo");
  Serial.println(servoPosition);

  if(servoDirection){
    servoPosition +=30;
  }
  else{
    servoPosition -= 30;
  }

  return servoPosition;
}



void displayMessage(const char* str)
{
  String text;
  text.concat(str);

  displayMessage(text);
}

void displayMessage(String text)
{

  byte symbols = 0;
  byte currentLine = 0;

  for(int i = 0; i < text.length(); i++){
    if(symbols >= dislpayMaxColumns ){
      moveCursorToNextLine();
      symbols = 0;
    }
    lcd.print(text.charAt(i));
    symbols++;

  }

  if(symbols > 0){
    moveCursorToNextLine();
  }
}


byte getCurrentLine()
{
  displayCurrentLine++;
  if(displayCurrentLine >= displayLinesCount){
    displayCurrentLine = 0;
  }
  return displayCurrentLine;
}

void moveCursorToNextLine()
{
  byte nextLine = getCurrentLine();
  if(nextLine == 0){
    lcd.clear();
  }
  lcd.setCursor(0, nextLine);
}

float getDistance(int value)
{
  float vcc = 0.004882812 * value;
  float a = 0.008271;
  float b = 939.6;
  float c = -3.398;
  float d = 17.339;

  float distance =  (a + b*vcc)/(1+c*vcc+d*vcc*vcc);

  return distance;
}






