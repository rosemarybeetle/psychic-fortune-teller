// -----------------------
// ----
// PSYCHIC FORTUNE TELLER
// @rosemarybeetle 2013
// http://makingweirdstuff.blogspot.com
// version 9
/* -----------------------
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

// 
// This sketch is the mind control of Psychic Fortune Teller, an automaton that can read the collective mind of twitter
// It has a Processing brain connected to a Twitter app, connecting via OAUTH
// It harvests tweets from predefined searchs 
// Deconstructs the weet content into words, hashtags, usernames and urls
// Then uses these to create fortune readings, which it speaks using text-to-speeach
// it also tweets a summary.

//
// RESPECT to...
//
// JER THORP - Visualisation is based on his code example
// see http://blog.blprnt.com/blog/blprnt/updated-quick-tutorial-processing-twitter
// Awesome!
// 
// The people behind twitter4j 
// see https://github.com/yusuke/twitter4j/network
// using here, version 3.03
// NOTE - you have to have the twitter4j library installed in the libraries folder for this to work!
// You need to register your app to get OAUTH keys for Twitter4j
// You can put them in a separate tab in your sketch
// 
// Andreas Schlegel - controlP5 GUI Library 
// see http://www.sojamo.de/libraries/controlP5/
// For positioning see (also @@@ Andreas Schlegel @@@) - 
// https://code.google.com/p/controlp5/source/browse/trunk/examples/controlP5button/controlP5button.pde?r=6
// ----
// Nikolaus Gradwohl for the GURU text to speech library for Processing
// see http://www.local-guru.net/blog/pages/ttslib
// -----------------------

// -----

// >>>>>>
boolean serialCheckInt=true;
boolean grabtweetCheckInt=true;
boolean loadSettingsFirstLoadFlag=true;
boolean loadstopWordsCheckInt=true;
// <<<<<< end load flags

//  >>>>> fortune variables initialisations
int tweetTextOutro = int (random(99));
String tweetSendTrigger ="fireTweet";
String fortuneGreeting = "I have stared deep into the hive mind. "; 
String fortune = "";
String fortuneSpoken = "";
int widthRandomiser = 120;
// <<<<<<

// >>>>>> gui variables init...
String tfUserCurrent =""; // used to check what is in the username text box
String tfTextCurrent =""; // used to check what is in the free-text text box
int valFocus = 0; // default
color focusBackgroundColor = color (255, 255, 00);
color focusOffBackgroundColor = color (0, 0, 0);
color focusOffColor = focusBackgroundColor ;
color focusColor = focusOffBackgroundColor;
color clPanel = color(70, 130, 180);
// <<<<<<

// >>>>>> ArrayLists to hold all of the words that we get from the imported tweets
ArrayList<String> stopWords = new ArrayList();
ArrayList<String> cleanTweets = new ArrayList();
ArrayList<String> words = new ArrayList(); 
ArrayList<String> hashtags = new ArrayList();
ArrayList<String> usernames = new ArrayList();
ArrayList<String> urls = new ArrayList();
ArrayList tweetster = new ArrayList();
String uberWords [] = new String[0]; //massive array to build up history of words harvested
String uberHashtags [] = new String[0]; //massive array to build up history of hashtags harvested
String uberUsers [] = new String[0]; //massive array to build up history of users harvested
String uberUrls [] = new String[0]; //massive array to build up history of urls harvested
String queryString = ""; // 
String queryType = ""; //
ArrayList<String> fortFrags1 = new ArrayList();
ArrayList<String> fortFrags2 = new ArrayList();
ArrayList<String> fortFrags3 = new ArrayList();
ArrayList<String> fortFrags4 = new ArrayList();

// <<<<<< Variables for admin and tweettexts - e.g Array for containing imported admin settings from Google spreadsheet (init with default settings)
String adminSettings [] = {
  "#hivemind", "@rosemarybeetle", "weird", "100", "50000", "h", "500", "Psychic Hive-Mind Fortune Reader", "Greetings Master. I am a-woken"
}; 

String tweetTextIntro="";
String readingSettingText="";
int panelHeight = 60; 
int border = 40;
int boxY = 515;
int boxWidth = 270;
int boxHeight = 40;
int columnPos2_X = 310;

// >>>>>>  grabTweets Timer settings  >>>>>>>>>>>
float grabTime = millis();
float timeNow = millis();
String stamp = year()+"-"+month()+"-"+day()+"-"+hour()+"-"+minute();// <<<<<<

// >>>>>> GUI library and settings
import controlP5.*; // import the GUI library
ControlP5 cp5; // creates a controller (I think!)
ControlFont font;
controlP5.Button b;
controlP5.Textfield tf;
controlP5.Textlabel lb;
// <<<<<<<

// >>>>>>>  import GURU text-to-speech library
import guru.ttslib.*; // NB this also needs to be loaded (available from http://www.local-guru.net/projects/lib/ttslib-0.3.zip)
TTS tts; // create an instance called 'tts'

// <<<<<<<

// >>>>>>> import standard processing Serial library 
import processing.serial.*;

Serial port; // create an instance called 'port'
// <<<<<<<

//  >>>>>> needed to stop Twitter overpolling from within sendTweet
float tweetTimer = 5000; // wait period (in milliseconds) after sending a tweet, before you can send the next one
float timerT=millis(); // temporary timer for sendTweet
float delayCheck; //delayCheck; // THIS IS IMPORTANT. it i what stops overpollin g of the Twitte API
//  <<<<<<


void setup() {
  tts = new TTS(); // create text to speech instance
  tts.speak(adminSettings[8]);// preloaded, not web
  println (" adminSettings 1 " + adminSettings); // @@ DEBUG STUFF
  for (int i = 0 ; i < adminSettings.length; i++) {
    println("adminSettings["+i+"]= "+adminSettings[i]); // @@ DEBUG STUFF
  }
  updateDisplayVariables();
  try {
    loadRemoteAdminSettings(); // loads Twitter search parameters from remote Google spreadsheet
    println ("adminSettings 2 "+adminSettings);
    tts.speak("I am connected to the web. Master.Your commands have been loaded into my brain"); // @@ DEBUG STUFF - SPOKEN OUT. ONLY WORKS IF CONNECTION WORKS
  }  
  catch (Exception e) {
    tts.speak("I am sorry. I am not able to connect to the web. Your commands have not been loaded into my brain master"); // @@ DEBUG STUFF
  }
  loadRemoteStopWords();// load list of stop words into an array, loaded from a remote spreadsheet
 
  // >>>>>>> screen size and settings....
  size(screen.width-border, screen.height-border);// USE THIS SETTING FOR EXPORTED APPLICATION IN FULLSCREEN (PRESENT) MODE
  background(0); // SET BACKGROUND TO BLACK
  // <<<<<<<

  // >>>>> Make initial serial port connection handshake
  println(Serial.list());// // @@ DEBUG STUFF - display communication ports (use this in test for available ports)
  try { 
    port = new Serial(this, Serial.list()[0], 115200); // OPEN PORT TO ARDUINO
  } 
  catch (ArrayIndexOutOfBoundsException ae) {
    // if errors
    println ("-------------------------");
    println ("STOP - No PORT CONNECTION");
    println ("Exception = "+ae);  // print it
    println ("-------------------------");
    println ("-------------------------");
  }
  // <<<<<<<
  buildAdminPanel();

  smooth();
  
  grabTweets(); // Now call tweeting action functions...

  println ("finished grabbing tweets");
  println ();
  println ();
}  // <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< end of setup()  <<<<<<<<<<<<<<<<<<<<<<<<<<


void draw() {
  int panelTop= height-panelHeight;
  buttonCheck("HELLO"); // on screen check button every loop

  timeNow=millis();

  try {
    println ();
    if ((timeNow-grabTime)>float(adminSettings[4])) {
      grabTweets();
    }

    // >>>>>> Draw a faint black rectangle over what is currently on the stage so it fades over time.
    fill(0, 30); // change the latter number to make the fade deeper (from 1 to 20 is good)
    rect(0, 0, width, height-panelHeight);
    // <<<<<<

    // >>>>>>> WORDS
    // Draw a word from the list of words that we've built
    int i = (int (random (words.size())));
    String word = words.get(i);
    println ("word = "+word+" #"+i);
    // <<<<<<<

    // >>>>>>> HASHTAGS
    //Draw a hashtag from the list of words that we've built
    int j = (int (random (hashtags.size())));
    String hashtag = hashtags.get(j);
    // <<<<<<<

    // >>>>>> USERNAMES
    //Draw a username from the list of words that we've built
    int k = (int (random (usernames.size())));
    String username = usernames.get(k);
    // <<<<<<

    // >>>>>> URLS
    //Draw a url from the list of words that we've built
    int l = (int (random (urls.size())));
    String url = urls.get(l);
    // <<<<<<
  
    //-------------
    // >>>>> Put url somewhere random on the stage, with a random size and colour
    fill(255, 255, 0, 255);
    textSize(random(30, 40)); 
    text(url, random(width)-widthRandomiser, random(panelTop)); // 
    // <<< SEND URL TO THE SCREEN

    // >>> SENDs HASHTAG TO THE SCREEN WITH DIFFERENT SIZE 
    fill(255, 0, 0, 255);
    textSize(random(40, 45));
    text("#"+hashtag, random(width)-widthRandomiser, random (panelTop));
    // <<< END SEND HASHTAG#

    // >>>SEND WORD TO SCREEN ALSO WITH DIFFERENT SETTINGS
    textSize(random(45, 60));
    fill(255, 255);
    text(word, random(width)-widthRandomiser, random (panelTop));
    // <<< END SEND WORD

    // >>> SEND USERNAME TO SCREEN
    fill(0, 255, 22, 255);
    textSize(random(35, 45));
    text("@"+username, random(width)-widthRandomiser, random (panelTop));
    // <<< END SEND USERNAME

    // --------------
    // following is for text boxes background. 
    tfUserCurrent=tf.getText() ; //check the text box content every loop
    println ("tfUserCurrent= "+tfUserCurrent); // @@ DEBUG STUFF
  }
  catch (Exception e) {
  }
  finally 
  {
    println ("inside DRAW()");
  }
  checkSerial() ; // check serial port every loop
}


// >>>>>>>>>>>>>>>>>>>>>>>> SEND THAT TWEET >>>>>>>>>>>>>>>
void sendTweet (String tweetText) {

  if ((tfUserCurrent.equals(""))!=true) { // THE BOX CAN'T BE EMPTY
    updateDisplayVariables(); 
    //@@@
    timerT=millis();  // reset the timer each time


    if (timerT-delayCheck>=tweetTimer)
      // this is needed to prevent sending multiple times rapidly to Twitter 
      // which will be frowned upon!
    {
      delayCheck=millis(); // RESET A TIMER

      println("tweet being sent"); // @@ DEBUG STUFF
      println("tfUserCurrent = "+ tfUserCurrent);  // @@ DEBUG STUFF
      tweetTextIntro = readingSettingText; // INITIALISE THE INTRO TEXT VARIABLE...
      readFortune(tweetText);
      tts.speak(fortuneSpoken);
      println("tweet Send actions complete over"); // @@ DEBUG STUFF
      println();

      //@@@
      ConfigurationBuilder cb2 = new ConfigurationBuilder();
      // ------- NB - the variables twitOAuthConsumerKey, are in a seperate tab
      cb2.setOAuthConsumerKey(twitOAuthConsumerKey);
      cb2.setOAuthConsumerSecret(twitOAuthConsumerSecret);
      cb2.setOAuthAccessToken(twitOAuthAccessToken);
      cb2.setOAuthAccessTokenSecret(twitOAuthAccessTokenSecret);

      Twitter twitter2 = new TwitterFactory(cb2.build()).getInstance();

      try {
        Status status = twitter2.updateStatus(fortune);
        println("Successfully tweeted the message: "+fortune + " to user: [@" + status.getText() + "].");  // @@ DEBUG STUFF
        delayCheck=millis();
      } 
      catch(TwitterException e) { 
        println("Send tweet: " + e + " Status code: " + e.getStatusCode());
      } // end try
      ;
    }
  }
  else {
    tts.speak("You have not entered your Twitter user nayme. Sorry. I cannot reed your fortune. without this") ; // THE BOX WAS EMPTY
  }
}
// <<<<<<<<<<<<<<<<<<<<<<<<< END SEND TWEETS <<<<<<<<<<<<<<<

// >>>>>>>>>>>>>>>>>>>>>>>>> GRAB THOSE TWEETS  >>>>>>>>>>>>>
void grabTweets() {


  color cl3 = color(70, 130, 180);
  fill (cl3);
  rect(0, (height/2)-120, width, 90);

  fill(0, 25, 89, 255);
  textSize(70); 
  text("Reading the collective mind...", (width/8)-120, (height/2)-50); // THE ALERT FOR UPDATE CHECKING PAUSE
  loadRemoteAdminSettings(); // GET THE LATEST ADMIN FROM GOOGLE SPREADSHEET
 
  //Credentials
  ConfigurationBuilder cbTest = new ConfigurationBuilder();
  // ------- NB - the variables twitOAuthConsumerKey, etc. ARE IN A SEPARATE SHEET 
  cbTest.setOAuthConsumerKey(twitOAuthConsumerKey);
  cbTest.setOAuthConsumerSecret(twitOAuthConsumerSecret);
  cbTest.setOAuthAccessToken(twitOAuthAccessToken);
  cbTest.setOAuthAccessTokenSecret(twitOAuthAccessTokenSecret);

  Twitter twitterTest = new TwitterFactory(cbTest.build()).getInstance();

  try { // TRY ALLOWS ERROR HANDLING FOR EXCEPTIONS...
    Query query = new Query(queryString); // this is default you check the first of 4 admin settings, but should be extended to include passing a selctor param
    query.count(int(adminSettings[3])); // count is the number of tweets returned per page
  
    QueryResult result = twitterTest.search(query); // gets the query

      int ll=1; // @@ DEBUG STUFF
    for (Status status : result.getTweets()) { // EXTRACT THE TWEETS
      String user = status.getUser().getScreenName();// GET THE TWITTER USERNAME
      usernames.add(user); // ADD TO THE ARRAYLIST FOR USERNAMES
      String msg = status.getText(); // EXTRACT THE TWEET TEXT
        println ("tweet #"+ll); // @@ DEBUG STUFF
        println("@" + user); // @@ DEBUG STUFF
       println("Text of tweet=" + status.getText()); // @@ DEBUG STUFF
        println ("-----------");
        ll++; // @@ DEBUG STUFF (INCREMENT)
        
      //Break the tweet into words
      String[] input = msg.split(" "); // BREAK DOWN THE TWEET USING SPACES AS A DELIMITER
      for (int j = 0;  j < input.length; j++) {


        cleanTweets.add(input[j]); // CLEANTWEETS IS A STORE FOR TWEET WORDS WITH STOP WORDS REMOVED

        for (int ii = 0 ; ii < stopWords.size(); ii++) {

          if (stopWords.get(ii).equals(input[j])) {
            cleanTweets.remove(input[j]); // THIS WORD IS A STOP WORD - REMOVE IT!
            println("Word removed due to matched stopword: "+input[j]); // @@ DEBUG STUFF
          } // end if
        } //end for (ii++) //stopword c
      }// end clean this msg
    }// end of all tweet cleaning
    println ("cleanTweets = "+cleanTweets);

    for (int k = 0;  k < cleanTweets.size(); k++) {
      if ((cleanTweets.get(k).equals(queryString))!= true)
      { 
        println ("(cleanTweets.get(k) <"+cleanTweets.get(k)+".equals(queryString))"+queryString+"!= true");
        words.add(cleanTweets.get(k));
        if (words.size() >int(adminSettings[6])) 
        {
          words.remove(0);
        } // keeps aray to a finite length by dropping off first element as new one is added 
        

        // >>>>>> make the list of hashtags
        String hashtag= cleanTweets.get(k);

        String hashtagArray[] = hashtag.split("#");
        if (hashtagArray.length>1)
        {
          //println ("inside checker");
          hashtags.add(hashtagArray[1]);
          int v=words.size()-1;
          words.remove(v);
          if (queryType.equals("hashtag"))
          {
            if (hashtagArray[1].equals("#"+queryString)) {
              hashtags.remove(hashtagArray[1]);
            } 
            else if (hashtags.size() >int(adminSettings[6])/10) 
            {
              hashtags.remove(0);
            } // keeps aray to a finite length by dropping off first element as new one is added
          }
          println ("hashtagArray["+k+"]= "+hashtagArray[1]);
        }
        // <<<<<<<


        // >>>>>>> set up list of usernames
        String username= cleanTweets.get(k);
        String usernameArray[] = username.split("@");
        // println ("usernameArray = ");
        //println (usernameArray);
        if (usernameArray.length>1)
        {

          int vv=words.size()-1; // takes out the username by removing last entry in words() 
          words.remove(vv);//
          // println ("usernameArray["+j+"]= "+usernameArray[1]);
        }  
        if (usernames.size() >int(adminSettings[6])/6) 
        {
          usernames.remove(0);
        } // keeps aray to a finite length by dropping off first element as new one is added 

        // <<<<<<<<

        // >>>>>>>> set up urls >>>>>>
        String url = cleanTweets.get(k);
        String urlArray[] = url.split("h");
        if (urlArray.length>1)
        {
          String urlArray2[] = urlArray[1].split("t");
          if (urlArray2.length>2)
          {
            urls.add(url);
            int vvv=words.size()-1;
            words.remove(vvv);
          } 
          else  if (urls.size() >int(adminSettings[6])/6) 
          {
            urls.remove(0);
          } // keeps aray to a finite length by dropping off first element as new one is added 

          // <<<<<<<<<< end

          // >>>>>>>>>>
        }
      };
    }

    println ("WORDS.SIZE () = "+words.size());
    println ("words = "+words);
    println ("@@@@@@@@@@@@@@@@@@@@@@@");
    // >>>>>>> create text log file of words from pyschic scanning >>>>>>>>>
    for (int p =0;p<words.size(); p++)
    {
      uberWords  = append (uberWords, words.get(p).toString());
    }
    uberWords  = append (uberWords, "WORDS UPDATE REFRESH COMPLETED");
    uberWords  = append (uberWords, " ");
    saveStrings ("words-"+stamp+".txt", uberWords);
    // <<<<<< end word text log file
    
    // >>>>>> create log file of users 
    for (int jj =0;jj<usernames.size(); jj++)
    {
      uberUsers  = append (uberUsers, "@"+usernames.get(jj).toString());
      
    }
    saveStrings ("users-"+stamp+".txt", uberUsers);
    // <<<<<<<<< end user text log file
  
// >>>>>> create log file of hashtags 
    for (int jj =0;jj<usernames.size(); jj++)
    {
      uberHashtags  = append (uberHashtags, "#"+hashtags.get(jj).toString());
      
    }
    saveStrings ("hashtags-"+stamp+".txt", uberHashtags);
// <<<<<<<<< end hashtag text log file

// >>>>>> create log file of urls 
    for (int jj =0;jj<urls.size(); jj++)
    {
      uberUrls  = append (uberUrls, urls.get(jj).toString());
      
    }
    saveStrings ("urls-"+stamp+".txt", uberUrls);
// <<<<<<<<< end url text log file
 
} //end try ??

 catch(TwitterException e)    {
      println("TEST query tweet: " + e + " Status code: " + e.getStatusCode());
    } // end try/catch
    
  grabTime=millis(); // reset grabTime
  if (loadSettingsFirstLoadFlag==true)
  { 
    loadSettingsFirstLoadFlag =false; //
    //this is the line that will cause subsequqnt updates to remove the first word(0)
  } 
  cleanTweets.clear();
  tweetster.clear();
} // <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< end grabTweets() <<<<<<<<

// >>>>>>>>>>>>>>>>>>>
void buttonCheck(String tweetTextIntro)
{
  if (b.isPressed()) {
    println("button being pressed");
    sendTweet ("digital (onscreen) Button MOUSE");
    b.setWidth(50);
    // action for onscreen button press
  }
}
// <<<<<<<<<<<<<<<<<<<<<<< end of BUTTONCHECK

// >>>>>>>>>>>>>>> check the open serial port >>>>>>>>>>
void checkSerial() {
  println ();
  //println ("inside checkSerial()");
  try {
    // >>>>>> see if the port is sending you stuff
    while (port.available () > 0) {
      String inByte = port.readString();
      println ("Safe from OUSIDE IF . inByte = "+inByte);
      int w=int(random(150));
      b.setWidth(w);
      println ();
      port.clear();
      sendTweet ("physical Button");
    }
  } // end try
  catch (Exception e) {
    println ("Check serial exception = "+e);
  }
} // <<<<<<<<<<<<<<<<<<<<< end checkSerial <<<<<<<<<<<<<<<<<<<<<


// >>>>>>>>>>>>>>>>>>> load remote  admin settings   >>>>>>>>>>>>>>
void loadRemoteAdminSettings ()
{
  try {
    String checkRandomSpeech = adminSettings[8];
    adminSettings = loadStrings("https://docs.google.com/spreadsheet/pub?key=0AgTXh43j7oFVdFNOcGtMaXZnS3IwdTJacllUT1hLQUE&output=txt");
    if ((checkRandomSpeech.equals(adminSettings[8]))!=true) {
      tts.speak(adminSettings[8]);
    }
    for (int i = 0 ; i < adminSettings.length; i++) {
      println("adminSettings["+i+"]= "+adminSettings[i]);
    } // end for

    if (adminSettings[5].equals("h")) {
      println ("use hashtag for search");
      queryString = adminSettings[0];
      queryType = "hashtag";
    } 
    if (adminSettings[5].equals("u"))
    {
      println ("use username phrase for search");
      queryString = adminSettings[1];
      queryType = "username";
    }
    if (adminSettings[5].equals("s"))
    {
      println ("use search term for search");
      queryString = adminSettings[2];
      queryType = "search term";
    }
    updateDisplayVariables();
    // now load load fortune fragments
    String frag1 []= loadStrings ("https://docs.google.com/spreadsheet/pub?key=0AgTXh43j7oFVdDQ3cUZ5Y2RMTm9RSXNrdElZTjN5R1E&output=txt");
    for (int ff1=0; ff1<frag1.length; ff1++)
    {
      fortFrags1.add(frag1[ff1]);
      println ("Fortune Frag1 = "+fortFrags1.get(ff1));
    }
    String frag2 []= loadStrings ("https://docs.google.com/spreadsheet/pub?key=0AgTXh43j7oFVdGFQLTFhMUVqTTlkTjlRVUN4c3JtOGc&output=txt");
    for (int ff2=0; ff2<frag2.length; ff2++)
    {
      fortFrags2.add(frag2[ff2]);
      println ("Fortune Frag2 = "+frag2[ff2]);
      println ("Fortune Frag1 = "+fortFrags2.get(ff2));
    }
    String frag3 []= loadStrings ("https://docs.google.com/spreadsheet/pub?key=0AgTXh43j7oFVdFE0Qm1yYmhyYWJETVJsSHJIOGFMQ3c&output=txt");
    for (int ff3=0; ff3<frag3.length; ff3++)
    {
      fortFrags3.add(frag3[ff3]);
      println ("Fortune Frag3 = "+frag3[ff3]);
    }
    String frag4 []= loadStrings ("https://docs.google.com/spreadsheet/pub?key=0AgTXh43j7oFVdG9KTnhLS2Zvbk5HNXp2RmRpeUZtTUE&output=txt");
    for (int ff4=0; ff4<frag4.length; ff4++)
    {
      fortFrags4.add(frag4[ff4]);
      println ("Fortune Frag4 = "+frag4[ff4]);
    }
    // end if
  }
  catch (Exception e) {
    println ("no CONNECTION");
  }
}

// >>>>
void loadRemoteStopWords ()
{
  try {
    String stopWordsLoader [] = loadStrings("https://docs.google.com/spreadsheet/pub?key=0AgTXh43j7oFVdFByYk41am9jRnRkeU9LWnhjZFJTOEE&output=txt");

    if (loadstopWordsCheckInt==true)
    {
      for (int i = 0 ; i < stopWordsLoader.length; i++) {
        //stop
        stopWords.add(stopWordsLoader[i]);
        println("stopWords["+i+"]= "+stopWords.get(i)+". Length now: "+stopWords.size());
      }
      loadstopWordsCheckInt=false;
    }
  }
  catch (Exception e)
  {
    println("jjjjjjjjjjjjj");
  }
}
void keyReleased() {
  if (key==TAB) {
    println ("Tab key released");

    //tfToggleFocus(valFocus);
  } 
  else if  ((key==ENTER )|(key == RETURN)) {

    sendTweet("pressed return");
  }
}

void tfToggleFocus (int val)
{
  /*if (val==0)
   {
   tf.setFocus(true);
   tf.setColorBackground(focusBackgroundColor);
   tf.setColor(focusColor);
   valFocus=1;
   }
   else if (val==1) {
   tf.setFocus(false);
   tf.setColorBackground(focusOffBackgroundColor);
   tf.setColor(focusOffColor);
   valFocus=0;
   }*/
  tf.setFocus(true);
  tf.setColorBackground(focusBackgroundColor);
  tf.setColor(focusColor);
}
void updateDisplayVariables() {
  // Reading the mind queryString
  String currentHashtag = adminSettings [0];
  String displayHashtag = "hashtag = "+adminSettings [0]+"   ";
  if (adminSettings[0]=="")
  {
    displayHashtag="";
  }
  String currentUserName = adminSettings [1];
  String displayUserName = "@username = "+adminSettings [1]+"   ";
  if (adminSettings[1]=="")
  {
    displayUserName="";
  }
  String currentSearchTerms = adminSettings [2];
  String displaySearchTerms = "search = "+adminSettings [2];
  if (adminSettings[2]=="")
  {
    displayUserName="";
  }
  readingSettingText = "Reading the hive mind for "+queryType+"= "+ queryString;
  color cl = color(70, 30, 180);// not in use
  color cl2 = color(70, 230, 180);//not in use
  fill (clPanel);
  //rect(30, boxY+15, width, 105);
  fill(0, 0, 0, 255);
  textSize(40);
  //text(readingSettingText, 10, boxY+40);
  //rect(0, boxY+13, width, 1);
  textSize(40);
  text("@", 2, boxY+33);


  fill (clPanel);
  rect(columnPos2_X, boxY-10, width, 50);
  fill(0, 0, 0, 255);
  textSize(35);
  //text(adminSettings[7], columnPos2_X+30, boxY-25);


  text("<enter @username + press my button!", columnPos2_X, boxY+30);


  //displayHashtag+displayUserName+displaySearchTerms;
}

void buildAdminPanel() {
  int  panelTop = height-panelHeight;

  fill (clPanel);
  rect(0, panelTop, width, panelHeight);
  // >>>>>>> set up fonts
  //PFont font = createFont("arial",20);
  font = new ControlFont(createFont("arial", 100), 40);
  // <<<<<<<

  // >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>  set up GUI elements >>>>>>>>>>>>>>>>>>>>
  noStroke();
  cp5 = new ControlP5(this); // adds in a control instance to add buttons and text field to
  noStroke();
  tf = cp5.addTextfield("");
  tf.setPosition(border, boxY);
  tf.setSize(boxWidth, boxHeight);
  tf.setColorBackground(focusBackgroundColor);
  tf.setColor(focusColor);
  tf.setFont(font);
  tf.setFocus(true);
  //tf.setAutoClear(true);
  tf.captionLabel().setControlFont(font);
  // @@@ 



  // create a new button with name 'Tell my Fortune'
  b = cp5.addButton("but", 20, 100, 50, 80, 20);
  b.setId(2);  // id to target this element
  b.setWidth(250); // width
  b.setHeight(25);
  b.setPosition(border, boxY+100);

  b.captionLabel().setControlFont(font);
  b.captionLabel().style().marginLeft = 1;
  b.captionLabel().style().marginTop = 1;
  b.setVisible(true);
  b.isOn();
  b.setColorBackground(focusOffBackgroundColor);


  // @@@



  // <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< end of GUI <<<<<<<<<<


  // >>>>>>>>
}

void readFortune (String tweetText)
{
  int picW1 = int(random (words.size()));
  String fortuneWord1= words.get(picW1);
  int picW2 = int(random (words.size()));
  String fortuneWord2= words.get(picW2);
  int hash = int(random (hashtags.size()));
  String fortuneHash= hashtags.get(hash);
  int urler = int(random (urls.size()));
  String fortuneUrl= urls.get(urler);
  int userer = int(random (usernames.size()));
  String fortuneUser = usernames.get(userer);

  int frag1Int =int (random (fortFrags1.size()));
  String fraglet1 = fortFrags1.get(frag1Int);
  int frag2Int =int (random (fortFrags2.size()));
  String fraglet2 = fortFrags2.get(frag2Int);
  int frag3Int =int (random (fortFrags3.size()));
  String fraglet3 = fortFrags3.get(frag3Int);
  int frag4Int =int (random (fortFrags4.size()));
  String fraglet4 = fortFrags4.get(frag4Int);
  fortune = "Psychic summary for @"+tfUserCurrent + ". for: #"+queryString+". "+ fortuneWord1+", "+ fortuneWord2+", #"+fortuneHash+ ", @"+fortuneUser+", "+fortuneUrl+". Enjoy/RT";
  println ("just before fortune spoken");
  fortuneSpoken = "Hello. "+tfUserCurrent+". "+adminSettings[7]+  ". "+fortuneGreeting +". Here. you are. Your Psychic Hive Mind. Fortune.  based on reading .the collective mind of. "+queryString+". is. "+fraglet1+". "+ fortuneWord1+". "+ fraglet2+". "+fortuneWord2+". "+fraglet3+". hashtag."+fortuneHash+ ". "+fraglet4+". Twitter user."+fortuneUser+". Thank you. I have tweeted a psychic summary of this reading to your twitter account. Moove along now. " ;
  println ("fortuneSpoken= "+fortuneSpoken);
}

/*
void readFortune (String tweetText)
 {
 int picW1 = int(random (words.size()));
 String fortuneWord1= words.get(picW1);
 int picW2 = int(random (words.size()));
 String fortuneWord2= words.get(picW2);
 int hash = int(random (hashtags.size()));
 String fortuneHash= hashtags.get(hash);
 int urler = int(random (urls.size()));
 String fortuneUrl= urls.get(urler);
 int userer = int(random (usernames.size()));
 String fortuneUser = usernames.get(userer);
 
 fortune = "Psychic summary for @"+tfUserCurrent + ". for: "+queryString+". "+ fortuneWord1+", "+ fortuneWord2+", "+fortuneHash+ ", "+fortuneUser+", "+fortuneUrl+". Enjoy/RT";
 fortuneSpoken = "Hello. "+tfUserCurrent+". "+adminSettings[7]+  ". "+fortuneGreeting +". Here. you are. Your Psychic. Hive. Mind. Reading. for. "+queryString+". is. "+ fortuneWord1+". AND. "+ fortuneWord2+", MIGHT. MEAN. you. need. to think. about. "+fortuneHash+ ". Also. SEEK OUT. "+fortuneUser;
 }
 */
 
 
