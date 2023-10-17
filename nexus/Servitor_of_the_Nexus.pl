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

  my $discord = "Server Discord: "  "<br><br>";

  my $desc = "Pyrelight is a solo-balanced server, meant to offer a challenging experience for veteran players and an alternative take on the 'solo progression' mold.<br><br>
              For more detailed information and ongoing discussion, please join the server discord (". plugin::PWHyperLink("https://discord.com/invite/5cFCA7TVgA","5cFCA7TVgA") ."). The " . $green . "#server-info</c>, 
              " . $green . "#faq</c>, and " . $green . "#changelog</c> channels may be particularly interesting.<br><br>";

  my $feature_header = $yellow . "Features</c><br>";

  my $feature_desc = "";

  my $text = $discord .
             $desc .
             $feature_header .
             $desc ;  

  quest::popup('Welcome to Pyrelight', $text);
}