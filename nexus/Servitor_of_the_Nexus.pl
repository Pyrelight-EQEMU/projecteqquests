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

  my $desc = "Pyrelight is a single box server, meant to offer a challenging soloable experience for veteran players and an alternative take on the 'solo progression' mold.
              $red PLEASE READ THIS ENTIRE WINDOW</c>.
              For more detailed information and ongoing discussion, please join the server discord (". plugin::PWHyperLink("https://discord.com/invite/5cFCA7TVgA","5cFCA7TVgA") .").<br><br>";

  my $feature_header = $yellow . "Features</c><br>";

  my $feature_desc = "$green Multiclassing</c> - You may unlock additional classes for your character. The first additional unlock is obtained at level 20. Each alternate 
                      class should be thought of as an alternate character in many respects, each has an independent Levels & Experience, Equipment, and unspent AA. However,
                      your Inventory, Skills, spent AA, and progression achievements are automatically shared between all of your classes. Additionally, your Spells may be 
                      shared with your alternate classes through the Spellshaper in the Bazaar. This system has some ";

  my $text = $desc .
             quest::popupcentermessage($feature_header) .
             $feature_desc ;  

  quest::popup('Welcome to Pyrelight', $text);
}