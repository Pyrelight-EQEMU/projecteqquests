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

  my $desc = "Pyrelight is a solo-balanced server, meant to offer a challenging experience for veteran players and an alternative take on the 'solo progression' mold.
              For more detailed information and ongoing discussion, please join the server discord 
              (". plugin::PWHyperLink("https://discord.com/invite/5cFCA7TVgA","5cFCA7TVgA") .").<br><br>";

  my $feature_header = $yellow . "Features</c><br>";

  my $feature_desc = "Pyrelight has a number of custom features.<br>
  * Item One<br>
  * Item Two<br>";

  my $text = $desc .
             quest::popupcentermessage($feature_header) .
             $feature_desc ;  

  quest::popup('Welcome to Pyrelight', $text);
}