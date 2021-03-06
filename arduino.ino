/*
  Psychic Fortune Teller Arduino board code
  Needed to control physical interaction...
  and relay physical-detection data back to Psychic Brain Processing sketch!
  
  @rosemarybeetle 
  30 June 2013
  http://makingweirdstuff.blogspot.com
 -----------------------
    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
    ----------------------
*/

 

int switchPin = A0; // Analogue in = A0, called switchPin.
int led = 13; // LED pin...
int analogValue = 0; // this is used to determine whether to make a call to Twitter (if high) 
float timerPeriod=5000; //don't send data more often than this 
float timerSend=millis();
float timerCheck=0;

// the setup routine runs once when you press reset:
void setup() {   
  Serial.begin(115200);  
  Serial.write("Serial connection initiated");
  
  // initialize the digital pin as an output.
  pinMode(led, OUTPUT);     
}

// the loop routine runs over and over again forever:
void loop() {
  analogValue = analogRead(switchPin);   
  if (analogValue >=900) {
    timerSend=millis();
  if ((timerSend-timerCheck)>timerPeriod) {
  Serial.write("fireTweet");
  timerCheck=millis();
  analogValue = 0; // reset - this is used to ensure the value is reset after a successful release of the switch
  // ADD ANY OTHER TRIGGERS HERE THAT COME FROM THIS INTERACTION
  }
  }
 
}
