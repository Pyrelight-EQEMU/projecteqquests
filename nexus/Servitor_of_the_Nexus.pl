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

  my $break = "<br><br>";
  my $desc = "Pyrelight is a single box server, meant to offer a challenging soloable experience for veteran players and an alternative take on the 'solo progression' mold.
              Zones through $green Luclin</c> are currently available, and the level cap is currently 60. Content through Dragons of Norrath and level 75 is planned.             
              For more detailed information and ongoing discussion, please join the server 
              discord (". plugin::PWHyperLink("https://discord.com/invite/5cFCA7TVgA","5cFCA7TVgA") .").<br><br>";

  my $feature_desc = "$green Multiclassing</c> - You may unlock additional classes for your character. The first additional unlock is obtained at level 20. Each alternate 
                      class should be thought of as an alternate character in many respects, each has an independent Levels & Experience, Equipment, and unspent AA. However,
                      your Inventory, Skills, spent AA, and progression achievements are automatically shared between all of your classes. Additionally, your Spells may be 
                      shared with your alternate classes through the Spellshaper in the Bazaar. This system has some strange consquences - Look at the Required Level on 
                      spell scrolls, and your Skills window will show any skill you could possibly earn, regardless of your class.$break
                      $green MQ2-Style Quality of Life</c> - While$red MQ2 is not allowed on this server</c>, many of the reasons why you would want it on a single-box server
                      are built-in to the client. You can see mobs on your map (names become visible with Tracking skill or custom Situational Awareness AA), you can see info
                      on spells and the value of items on inspect windows.$break
                      $green Heroic Stats</c> - Most direct increases to character strength are accomplished by way of abundant Heroic stats on items. You will recieve extra
                      combat feedback to inform you of how these stats are helping you, which can be disabled with the $green #filterheroic</c> command. All of these stats have 
                      additional, custom effects, such as directly scaling melee and spell damage, or increasing the duration of spells. Your 
                      [$purple Adventurer's Soul</c>] is the best way to grow in power early on, as it will scale with the amount of the world you've visited and become Attuned
                      to.$break
                      $green Item Improvement</c> - Artificer Cedric in the Bazaar will assist you in combining identical items to create improved versions. If you find yourself
                      stuck or otherwise underpowered, this is an excellent way to continue to progress.$break
                      $green Buffs</c> - Buffs work differently on Pyrelight! The intention is for you to have access to the buffs that you or your group mates actually own,
                      either through your class(es), or items can use. Any buff that meets these criteria is PERMANENT until it no longer meets those criteria. Additionally, 
                      $green runes</c> provide additional feedback and will regenerate over time instead of disappearing when they have absorbed all of their damage.$break
                      $green Pets</c> - Pets will recieve a significant benefit from your Heroic stats, as two thirds of their effectiveness is applied to your pets. Additionally,
                      the [$purple Summoner's Synchrosatchel</c>], purchased in the Bazaar, offers a unique experience - it serves as a 'proxy inventory' for your pet. Any
                      equipment placed within it will be equipped by your pet! Finally, pets are able to hold aggro over players in melee range so long as their Taunt avility
                      is activated.$break
                      $green Procs</c> - All procs that could normally trigger on melee hits can also trigger on spell casts. Ranged weapon attacks can also trigger procs in primary
                      and secondary slots. Any procs you might obtain for your Power Source slots also trigger any time another proc could trigger.$break
                      ";

  my $text = quest::popupcentermessage("$red NEW PLAYERS PLEASE READ THIS WINDOW</c><br>") .
             $desc .             
             $feature_desc ;  

  quest::popup('Welcome to Pyrelight', $text);
}