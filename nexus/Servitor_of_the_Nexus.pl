 sub EVENT_SAY {
  my $clientName = $client->GetCleanName();
  if ($text=~/hail/i) {
    POPUP_DISPLAY();

    $client->Message(263, "The golem stares at you, lifelessly. It's voice echos from nowhere.");

    quest::say("Greetings, $clientName. I am at your service.");
  }
 }

sub POPUP_DISPLAY {
  my $yellow = plugin::PWColor("Yellow");
  my $green  = plugin::PWColor("Green"); 
  my $red = plugin::PWColor("Red");
  my $purple = plugin::PWColor("Purple");

  my $desc = "Pyrelight is a single box server, meant to offer a challenging soloable experience for veteran players and an alternative take on the 'solo progression' mold.              
              For more detailed information and ongoing discussion, please join the server 
              discord (". plugin::PWHyperLink("https://discord.com/invite/5cFCA7TVgA","5cFCA7TVgA") .").<br><br>";

  my $feature_header = $yellow . "Server Custom Features</c><br><br>";

  my $feature_desc = "$green Multiclassing</c> - You may unlock additional classes for your character. The first additional unlock is obtained at level 20. Each alternate 
                      class should be thought of as an alternate character in many respects, each has an independent Levels & Experience, Equipment, and unspent AA. However,
                      your Inventory, Skills, spent AA, and progression achievements are automatically shared between all of your classes. Additionally, your Spells may be 
                      shared with your alternate classes through the Spellshaper in the Bazaar. This system has some strange consquences - Look at the Required Level on 
                      spell scrolls, and your Skills window will show any skill you could possibly earn, regardless of your class.<br><br>
                      $green MQ2-Style Quality of Life</c> - While$red MQ2 is not allowed on this server</c>, many of the reasons why you would want it on a single-box server
                      are built-in to the client. You can see mobs on your map (names become visible with Tracking skill or custom Situational Awareness AA), you can see info
                      on spells and the value of items on inspect windows.<br><br>
                      $green Heroic Stats</c> - Most direct increases to character strength are accomplished by way of abdundant Heroic stats on items. Your [$purple Adventurer's Soul</c>]
                      
                      ";

  my $text = quest::popupcentermessage("$red NEW PLAYERS PLEASE READ THIS WINDOW</c><br>") .
             $desc .
             $feature_header .
             $feature_desc ;  

  quest::popup('Welcome to Pyrelight', $text);
}